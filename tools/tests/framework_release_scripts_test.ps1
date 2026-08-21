$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. (Join-Path (Split-Path -Parent $PSScriptRoot) "framework_release_common.ps1")

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)
    $threw = $false
    try {
        & $Action | Out-Null
    } catch {
        $threw = $true
    }
    if (-not $threw) {
        throw $Message
    }
}

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) "gf-release-tests-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
try {
    Assert-True (Test-GFStableVersion -Version "0.1.1") "A stable semantic version was rejected."
    Assert-True (-not (Test-GFStableVersion -Version "01.1.1")) "A version with a leading zero was accepted."
    Assert-True (-not (Test-GFStableVersion -Version "0.1.1-rc.1")) "A prerelease version was accepted."
    Assert-True (Test-GFReleaseUpgrade -CurrentVersion "0.1.1" -TargetVersion "0.1.2") `
        "A valid release upgrade was rejected."
    Assert-True (-not (Test-GFReleaseUpgrade -CurrentVersion "0.1.1" -TargetVersion "0.1.1")) `
        "An unchanged release version was treated as an upgrade."
    Assert-Throws {
        Test-GFReleaseUpgrade -CurrentVersion "0.1.1" -TargetVersion "0.1.0"
    } "A release downgrade was accepted."
    Assert-Throws {
        Test-GFReleaseUpgrade -CurrentVersion "0.1.1" -TargetVersion "0.1.2-rc.1"
    } "A prerelease target was accepted."

    $configPath = Join-Path $temporaryRoot "version.cfg"
    Set-Content -LiteralPath $configPath -Encoding ascii -Value @(
        "[package]"
        ""
        'name="Godot Framework"'
        'version="0.1.1"'
        'godot_version="4.7.1"'
        'source="https://github.com/ZhaoMCX/godot-framework"'
    )
    $metadata = Get-GFMetadata -Path $configPath
    Assert-True ($metadata.Version -eq "0.1.1") "The Framework version was parsed incorrectly."
    Assert-True ($metadata.GodotVersion -eq "4.7.1") "The Godot version was parsed incorrectly."

    Set-GFMetadataVersion -Path $configPath -Version "0.1.2"
    $metadata = Get-GFMetadata -Path $configPath
    Assert-True ($metadata.Version -eq "0.1.2") "The Framework version was not updated."

    Add-Content -LiteralPath $configPath -Encoding ascii -Value 'version="0.1.3"'
    Assert-Throws { Get-GFMetadata -Path $configPath } "Duplicate version metadata was accepted."

    $checksumPath = Join-Path $temporaryRoot "package.zip.sha256"
    $hash = "A" * 64
    Set-Content -LiteralPath $checksumPath -Encoding ascii -Value "$hash  package.zip"
    Assert-True ((Read-GFChecksum -Path $checksumPath -ExpectedFileName "package.zip") -eq $hash) `
        "A valid checksum file was rejected."
    Add-Content -LiteralPath $checksumPath -Encoding ascii -Value "unexpected"
    Assert-Throws {
        Read-GFChecksum -Path $checksumPath -ExpectedFileName "package.zip"
    } "A checksum file with extra content was accepted."

    Assert-True (Test-GFOfficialRemote -RemoteUrl "https://github.com/ZhaoMCX/godot-framework.git") `
        "The official HTTPS remote was rejected."
    Assert-True (Test-GFOfficialRemote -RemoteUrl "git@github.com:ZhaoMCX/godot-framework.git") `
        "The official SSH remote was rejected."
    Assert-True (-not (Test-GFOfficialRemote -RemoteUrl "https://github.com/example/godot-framework.git")) `
        "An unofficial remote was accepted."

    $validPublishState = @{
        TagName = "v0.1.2"
        WorktreeClean = $true
        RemoteIsOfficial = $true
        CurrentBranch = "master"
        HeadCommit = "abc123"
        RemoteMasterCommit = "abc123"
        LocalTagCommit = "abc123"
        RemoteTagCommit = "abc123"
        LocalTagAnnotated = $true
        RemoteTagAnnotated = $true
        ReleaseState = "missing"
    }
    Assert-GFPublishState @validPublishState

    $draftPublishState = $validPublishState.Clone()
    $draftPublishState.ReleaseState = "draft"
    Assert-GFPublishState @draftPublishState

    $invalidPublishStates = @(
        @{ Name = "dirty worktree"; Key = "WorktreeClean"; Value = $false }
        @{ Name = "unofficial remote"; Key = "RemoteIsOfficial"; Value = $false }
        @{ Name = "non-master branch"; Key = "CurrentBranch"; Value = "feature" }
        @{ Name = "stale master"; Key = "RemoteMasterCommit"; Value = "def456" }
        @{ Name = "missing local tag"; Key = "LocalTagCommit"; Value = "" }
        @{ Name = "missing remote tag"; Key = "RemoteTagCommit"; Value = "" }
        @{ Name = "lightweight local tag"; Key = "LocalTagAnnotated"; Value = $false }
        @{ Name = "lightweight remote tag"; Key = "RemoteTagAnnotated"; Value = $false }
        @{ Name = "misdirected tag"; Key = "RemoteTagCommit"; Value = "def456" }
        @{ Name = "published release"; Key = "ReleaseState"; Value = "published" }
    )
    foreach ($invalidCase in $invalidPublishStates) {
        $state = $validPublishState.Clone()
        $state[$invalidCase.Key] = $invalidCase.Value
        Assert-Throws { Assert-GFPublishState @state } "Publish state accepted: $($invalidCase.Name)."
    }
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}

Write-Host "Framework release script tests passed."
