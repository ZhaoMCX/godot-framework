[CmdletBinding()]
param(
    [string]$ExpectedVersion = "",
    [string]$GodotExecutable = "",
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot "framework_release_common.ps1")

function Resolve-GodotExecutable {
    param(
        [string]$RequestedExecutable,
        [string]$ExpectedGodotVersion
    )

    $candidates = if ($RequestedExecutable) {
        @($RequestedExecutable)
    } else {
        @(
            "godot"
            "godot4"
            "Godot_v$ExpectedGodotVersion-stable_win64_console.exe"
            "Godot_v$ExpectedGodotVersion-stable_win64.exe"
        )
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return [IO.Path]::GetFullPath($candidate)
        }
        $command = Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($command) {
            return $command.Source
        }
    }
    throw "Unable to find Godot $ExpectedGodotVersion. Pass -GodotExecutable explicitly."
}

function Get-StreamSha256 {
    param([Parameter(Mandatory = $true)][IO.Stream]$Stream)

    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($Stream))).Replace("-", "")
    } finally {
        $algorithm.Dispose()
    }
}

function Assert-FrameworkArchive {
    param(
        [Parameter(Mandatory = $true)][string]$ArchivePath,
        [Parameter(Mandatory = $true)][string]$AddonPath
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $entriesByName = [Collections.Generic.Dictionary[string, IO.Compression.ZipArchiveEntry]]::new(
            [StringComparer]::Ordinal
        )
        foreach ($entry in $archive.Entries) {
            $name = $entry.FullName
            if (-not $name.StartsWith("addons/godot_framework/", [StringComparison]::Ordinal)) {
                throw "Archive entry is outside addons/godot_framework: $name"
            }
            if ($name.Contains("\") -or $name.Contains("//") -or $name.EndsWith("/")) {
                throw "Archive contains a malformed file path: $name"
            }
            $segments = $name.Split('/')
            if ($segments -contains "." -or $segments -contains "..") {
                throw "Archive contains an unsafe file path: $name"
            }
            if ($segments -contains "tests") {
                throw "Archive contains a tests directory: $name"
            }
            if ($entriesByName.ContainsKey($name)) {
                throw "Archive contains a duplicate path: $name"
            }
            $entriesByName.Add($name, $entry)
        }

        $addonRoot = [IO.Path]::GetFullPath($AddonPath).TrimEnd('\', '/')
        $addonPrefixLength = $addonRoot.Length + 1
        $expectedFiles = Get-ChildItem -LiteralPath $addonRoot -File -Recurse -Force |
            Where-Object {
                $relativeSegments = $_.FullName.Substring($addonPrefixLength).Split(
                    [char[]]@('\', '/'),
                    [StringSplitOptions]::None
                )
                -not ($relativeSegments -contains "tests")
            }

        $expectedNames = @($expectedFiles | ForEach-Object {
            "addons/godot_framework/$($_.FullName.Substring($addonPrefixLength).Replace('\', '/'))"
        })
        $actualNames = @($entriesByName.Keys)
        $differences = Compare-Object -ReferenceObject $expectedNames -DifferenceObject $actualNames -CaseSensitive
        if ($differences) {
            $details = ($differences | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" }) -join "; "
            throw "Archive file list does not match the source addon: $details"
        }

        $requiredFiles = @(
            "addons/godot_framework/AGENTS.md"
            "addons/godot_framework/LICENSE"
            "addons/godot_framework/README.md"
            "addons/godot_framework/version.cfg"
            "addons/godot_framework/docs/update.md"
            "addons/godot_framework/base/gf_application.gd"
        )
        foreach ($requiredFile in $requiredFiles) {
            if (-not $entriesByName.ContainsKey($requiredFile)) {
                throw "Archive is missing required content: $requiredFile"
            }
        }

        foreach ($sourceFile in $expectedFiles) {
            $entryName = "addons/godot_framework/$($sourceFile.FullName.Substring($addonPrefixLength).Replace('\', '/'))"
            $sourceStream = [IO.File]::OpenRead($sourceFile.FullName)
            $entryStream = $entriesByName[$entryName].Open()
            try {
                $sourceHash = Get-StreamSha256 -Stream $sourceStream
                $entryHash = Get-StreamSha256 -Stream $entryStream
                if ($sourceHash -ne $entryHash) {
                    throw "Archive content differs from source: $entryName"
                }
            } finally {
                $entryStream.Dispose()
                $sourceStream.Dispose()
            }
        }
    } finally {
        $archive.Dispose()
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$versionConfig = Join-Path $projectRoot "addons\godot_framework\version.cfg"
$metadata = Get-GFMetadata -Path $versionConfig
if ($ExpectedVersion -and $metadata.Version -ne $ExpectedVersion) {
    throw "Framework version '$($metadata.Version)' does not match expected version '$ExpectedVersion'."
}

$godotPath = Resolve-GodotExecutable -RequestedExecutable $GodotExecutable -ExpectedGodotVersion $metadata.GodotVersion
$versionOutput = @(& $godotPath --version 2>&1)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to read the Godot version from $godotPath."
}
$actualGodotVersion = ($versionOutput -join "`n").Trim()
if (-not $actualGodotVersion.StartsWith("$($metadata.GodotVersion).stable", [StringComparison]::Ordinal)) {
    throw "Expected Godot $($metadata.GodotVersion).stable, got '$actualGodotVersion'."
}

Write-Host "Importing the project with Godot $($metadata.GodotVersion)..."
& $godotPath --headless --editor --path $projectRoot --quit
if ($LASTEXITCODE -ne 0) {
    throw "Godot project import failed with exit code $LASTEXITCODE."
}

Write-Host "Running Framework and game tests..."
& $godotPath --headless --path $projectRoot -s addons/gdUnit4/bin/GdUnitCmdTool.gd `
    --ignoreHeadlessMode -a addons/godot_framework -a game
if ($LASTEXITCODE -ne 0) {
    throw "GDUnit4 tests failed with exit code $LASTEXITCODE."
}

$buildRoot = if ($OutputDirectory) {
    [IO.Path]::GetFullPath($OutputDirectory)
} else {
    Join-Path $projectRoot "builds"
}
& (Join-Path $PSScriptRoot "package_framework.ps1") -OutputDirectory $buildRoot

$zipName = "godot-framework-$($metadata.Version).zip"
$zipPath = Join-Path $buildRoot $zipName
$checksumPath = "$zipPath.sha256"
if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
    throw "Package was not created: $zipPath"
}

$declaredHash = Read-GFChecksum -Path $checksumPath -ExpectedFileName $zipName
$actualHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToUpperInvariant()
if ($declaredHash -ne $actualHash) {
    throw "Package checksum does not match the ZIP."
}
Assert-FrameworkArchive -ArchivePath $zipPath -AddonPath (Join-Path $projectRoot "addons\godot_framework")

Write-Host "Framework release validation passed."
Write-Host "Version: $($metadata.Version)"
Write-Host "Package: $zipPath"
Write-Host "SHA256: $actualHash"
