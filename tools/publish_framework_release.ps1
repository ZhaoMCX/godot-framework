[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$GodotExecutable = "",
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot "framework_release_common.ps1")

$repository = "ZhaoMCX/godot-framework"
$projectRoot = Split-Path -Parent $PSScriptRoot
$versionConfig = Join-Path $projectRoot "addons\godot_framework\version.cfg"
$metadata = Get-GFMetadata -Path $versionConfig
ConvertTo-GFVersion -Version $Version | Out-Null
if ($metadata.Version -ne $Version) {
    throw "Framework version '$($metadata.Version)' does not match requested version '$Version'."
}
$tagName = "v$Version"
$buildRoot = if ($OutputDirectory) {
    [IO.Path]::GetFullPath($OutputDirectory)
} else {
    Join-Path $projectRoot "builds"
}

function Invoke-GFLocalGit {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $output = @(& git -C $projectRoot @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return ($output -join "`n").Trim()
}

function Get-GFReleaseState {
    $releaseJson = @(& gh release list --repo $repository --limit 100 --json tagName,isDraft 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect GitHub Releases.`n$($releaseJson -join "`n")"
    }
    $releases = @(($releaseJson -join "`n") | ConvertFrom-Json)
    $matchingReleases = @($releases | Where-Object { $_.tagName -eq $tagName })
    if ($matchingReleases.Count -gt 1) {
        throw "GitHub returned multiple Releases for $tagName."
    }
    if ($matchingReleases.Count -eq 0) {
        return "missing"
    }
    return $(if ($matchingReleases[0].isDraft) { "draft" } else { "published" })
}

function Get-GFLocalPublishState {
    $status = Invoke-GFLocalGit -Arguments @("status", "--porcelain", "--untracked-files=all")
    $originUrl = Invoke-GFLocalGit -Arguments @("remote", "get-url", "origin")
    $currentBranch = Invoke-GFLocalGit -Arguments @("branch", "--show-current")
    $headCommit = Invoke-GFLocalGit -Arguments @("rev-parse", "HEAD")
    $remoteMasterCommit = Invoke-GFLocalGit -Arguments @("rev-parse", "refs/remotes/origin/master")

    $localTagNames = @(
        @(Invoke-GFLocalGit -Arguments @("tag", "--list", $tagName)) |
            Where-Object { $_ }
    )
    $localTagCommit = ""
    $localTagAnnotated = $false
    if ($localTagNames.Count -eq 1) {
        $localTagType = Invoke-GFLocalGit -Arguments @("cat-file", "-t", "refs/tags/$tagName")
        $localTagAnnotated = $localTagType -eq "tag"
        $localTagCommit = Invoke-GFLocalGit -Arguments @("rev-list", "-n", "1", $tagName)
    }

    $remoteTagOutput = Invoke-GFLocalGit -Arguments @(
        "ls-remote",
        "--tags",
        "origin",
        "refs/tags/$tagName",
        "refs/tags/$tagName^{}"
    )
    $remoteTagLines = @($remoteTagOutput.Split(@("`r`n", "`n"), [StringSplitOptions]::RemoveEmptyEntries))
    $remoteTagCommit = ""
    $remoteTagAnnotated = $false
    foreach ($line in $remoteTagLines) {
        $parts = $line -split "\s+", 2
        if ($parts.Count -ne 2) {
            throw "Unable to parse remote tag data: $line"
        }
        if ($parts[1] -eq "refs/tags/$tagName^{}") {
            $remoteTagCommit = $parts[0]
            $remoteTagAnnotated = $true
        } elseif (-not $remoteTagCommit) {
            $remoteTagCommit = $parts[0]
        }
    }

    return @{
        TagName = $tagName
        WorktreeClean = -not [bool]$status
        RemoteIsOfficial = Test-GFOfficialRemote -RemoteUrl $originUrl
        CurrentBranch = $currentBranch
        HeadCommit = $headCommit
        RemoteMasterCommit = $remoteMasterCommit
        LocalTagCommit = $localTagCommit
        RemoteTagCommit = $remoteTagCommit
        LocalTagAnnotated = $localTagAnnotated
        RemoteTagAnnotated = $remoteTagAnnotated
        ReleaseState = Get-GFReleaseState
    }
}

& gh auth status --hostname github.com *> $null
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI must be authenticated before publishing."
}

& git -C $projectRoot fetch origin master --tags
if ($LASTEXITCODE -ne 0) {
    throw "Unable to refresh origin/master and release tags."
}
$publishState = Get-GFLocalPublishState
Assert-GFPublishState @publishState

& (Join-Path $PSScriptRoot "validate_framework_release.ps1") `
    -ExpectedVersion $Version `
    -GodotExecutable $GodotExecutable `
    -OutputDirectory $buildRoot

& git -C $projectRoot fetch origin master --tags
if ($LASTEXITCODE -ne 0) {
    throw "Unable to refresh origin after release validation."
}
$publishState = Get-GFLocalPublishState
Assert-GFPublishState @publishState

$zipName = "godot-framework-$Version.zip"
$zipPath = Join-Path $buildRoot $zipName
$checksumPath = "$zipPath.sha256"
foreach ($path in @($zipPath, $checksumPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Validated release asset is missing: $path"
    }
}

if ($publishState.ReleaseState -eq "draft") {
    & gh release upload $tagName $zipPath $checksumPath --clobber --repo $repository
} else {
    & gh release create $tagName $zipPath $checksumPath --draft --verify-tag `
        --title "Godot Framework $tagName" --generate-notes --repo $repository
}
if ($LASTEXITCODE -ne 0) {
    throw "Unable to create or update the draft release."
}

$releaseJson = @(& gh release view $tagName --repo $repository --json isDraft,isPrerelease,assets,url 2>&1)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to verify the draft release.`n$($releaseJson -join "`n")"
}
$release = ($releaseJson -join "`n") | ConvertFrom-Json
if (-not $release.isDraft -or $release.isPrerelease) {
    throw "The release must remain a stable draft until asset verification finishes."
}

$expectedAssetNames = @($zipName, "$zipName.sha256")
$actualAssetNames = @($release.assets | ForEach-Object { $_.name })
if (Compare-Object $expectedAssetNames $actualAssetNames -CaseSensitive) {
    throw "The draft release does not contain exactly the two expected assets."
}
foreach ($asset in $release.assets) {
    $localPath = Join-Path $buildRoot $asset.name
    $localDigest = (Get-FileHash -LiteralPath $localPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($asset.digest -ne "sha256:$localDigest") {
        throw "GitHub asset digest does not match the local file: $($asset.name)"
    }
}

& gh release edit $tagName --draft=false --prerelease=false --latest --repo $repository
if ($LASTEXITCODE -ne 0) {
    throw "Asset verification passed, but publishing the Release failed."
}

Write-Host "Framework Release published: $($release.url)"
