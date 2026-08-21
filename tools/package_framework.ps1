[CmdletBinding()]
param([string]$OutputDirectory = "")

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$versionConfig = Join-Path $projectRoot "addons\godot_framework\version.cfg"
$versionText = Get-Content -LiteralPath $versionConfig -Raw
$versionMatch = [regex]::Match($versionText, '(?m)^version="([^"]+)"\s*$')
if (-not $versionMatch.Success) {
    throw "Unable to read the Framework version."
}

$version = $versionMatch.Groups[1].Value
$buildRoot = if ($OutputDirectory) {
    [IO.Path]::GetFullPath($OutputDirectory)
} else {
    Join-Path $projectRoot "builds"
}
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null

$stagingRoot = Join-Path $buildRoot ".godot-framework-package-$([guid]::NewGuid().ToString('N'))"
$resolvedBuildRoot = [IO.Path]::GetFullPath($buildRoot).TrimEnd('\') + '\'
$resolvedStagingRoot = [IO.Path]::GetFullPath($stagingRoot)
if (-not $resolvedStagingRoot.StartsWith($resolvedBuildRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe staging path: $resolvedStagingRoot"
}

try {
    $addonTarget = Join-Path $stagingRoot "addons\godot_framework"
    New-Item -ItemType Directory -Path (Split-Path -Parent $addonTarget) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot "addons\godot_framework") -Destination $addonTarget -Recurse

    Get-ChildItem -LiteralPath $addonTarget -Directory -Recurse -Force |
        Where-Object { $_.Name -eq "tests" } |
        Sort-Object FullName -Descending |
        Remove-Item -Recurse -Force

    $requiredFiles = @(
        "AGENTS.md"
        "LICENSE"
        "README.md"
        "version.cfg"
        "docs\update.md"
        "base\gf_application.gd"
    )
    foreach ($required in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $addonTarget $required))) {
            throw "Package is missing required content: $required"
        }
    }
    if (Get-ChildItem -LiteralPath $addonTarget -Directory -Recurse | Where-Object { $_.Name -eq "tests" }) {
        throw "Package contains a tests directory."
    }

    $outputPath = Join-Path $buildRoot "godot-framework-$version.zip"
    if (Test-Path -LiteralPath $outputPath) {
        Remove-Item -LiteralPath $outputPath -Force
    }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipStream = [IO.File]::Open($outputPath, [IO.FileMode]::CreateNew)
    $archive = New-Object IO.Compression.ZipArchive(
        $zipStream,
        [IO.Compression.ZipArchiveMode]::Create,
        $false
    )
    try {
        Get-ChildItem -LiteralPath $stagingRoot -Recurse -File | ForEach-Object {
            $entryName = $_.FullName.Substring($stagingRoot.Length + 1).Replace("\", "/")
            $entry = $archive.CreateEntry($entryName, [IO.Compression.CompressionLevel]::Optimal)
            $entryStream = $entry.Open()
            $sourceStream = [IO.File]::OpenRead($_.FullName)
            try {
                $sourceStream.CopyTo($entryStream)
            } finally {
                $sourceStream.Dispose()
                $entryStream.Dispose()
            }
        }
    } finally {
        $archive.Dispose()
        $zipStream.Dispose()
    }
    $hash = Get-FileHash -LiteralPath $outputPath -Algorithm SHA256
    $hashPath = "$outputPath.sha256"
    Set-Content -LiteralPath $hashPath -Value "$($hash.Hash)  $([IO.Path]::GetFileName($outputPath))" -Encoding ascii
    Write-Host "Package complete: $outputPath"
    Write-Host "Checksum file: $hashPath"
    Write-Host "SHA256: $($hash.Hash)"
} finally {
    if (Test-Path -LiteralPath $resolvedStagingRoot) {
        Remove-Item -LiteralPath $resolvedStagingRoot -Recurse -Force
    }
}
