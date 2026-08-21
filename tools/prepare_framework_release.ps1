[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$GodotExecutable = "",
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot "framework_release_common.ps1")

$projectRoot = Split-Path -Parent $PSScriptRoot
$versionConfig = Join-Path $projectRoot "addons\godot_framework\version.cfg"
$metadata = Get-GFMetadata -Path $versionConfig
$changed = Test-GFReleaseUpgrade -CurrentVersion $metadata.Version -TargetVersion $Version

$status = @(& git -C $projectRoot status --porcelain --untracked-files=all 2>&1)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect the Git worktree."
}
if ($status.Count -gt 0) {
    throw "Release preparation requires a clean worktree.`n$($status -join "`n")"
}

$originalBytes = [IO.File]::ReadAllBytes($versionConfig)
try {
    if ($changed) {
        Set-GFMetadataVersion -Path $versionConfig -Version $Version
        Write-Host "Framework version updated: $($metadata.Version) -> $Version"
    } else {
        Write-Host "Framework version is already $Version; running validation only."
    }

    $validationArguments = @{
        ExpectedVersion = $Version
        GodotExecutable = $GodotExecutable
        OutputDirectory = $OutputDirectory
    }
    & (Join-Path $PSScriptRoot "validate_framework_release.ps1") @validationArguments

    $changedFiles = @(& git -C $projectRoot diff --name-only)
    $untrackedFiles = @(& git -C $projectRoot ls-files --others --exclude-standard)
    $unexpectedFiles = @($changedFiles + $untrackedFiles | Where-Object {
        $_ -and $_ -ne "addons/godot_framework/version.cfg"
    })
    if ($unexpectedFiles.Count -gt 0) {
        throw "Release preparation changed unexpected files: $($unexpectedFiles -join ', ')"
    }
} catch {
    if ($changed) {
        [IO.File]::WriteAllBytes($versionConfig, $originalBytes)
    }
    throw
}

Write-Host "Release preparation complete. Review and commit addons/godot_framework/version.cfg."
