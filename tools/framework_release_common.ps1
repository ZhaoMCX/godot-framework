Set-StrictMode -Version Latest

function Test-GFStableVersion {
    param([Parameter(Mandatory = $true)][string]$Version)

    return [regex]::IsMatch($Version, '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$')
}

function ConvertTo-GFVersion {
    param([Parameter(Mandatory = $true)][string]$Version)

    if (-not (Test-GFStableVersion -Version $Version)) {
        throw "Framework version must be a stable semantic version: $Version"
    }
    return [version]$Version
}

function Test-GFReleaseUpgrade {
    param(
        [Parameter(Mandatory = $true)][string]$CurrentVersion,
        [Parameter(Mandatory = $true)][string]$TargetVersion
    )

    $current = ConvertTo-GFVersion -Version $CurrentVersion
    $target = ConvertTo-GFVersion -Version $TargetVersion
    if ($target -lt $current) {
        throw "Framework releases cannot be downgraded from $current to $target."
    }
    return $target -gt $current
}

function Get-GFConfigValue {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $pattern = '(?m)^' + [regex]::Escape($Name) + '="([^"\r\n]+)"\s*$'
    $matches = [regex]::Matches($Text, $pattern)
    if ($matches.Count -ne 1) {
        throw "Framework metadata must contain exactly one '$Name' value."
    }
    return $matches[0].Groups[1].Value
}

function Get-GFMetadata {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Framework metadata file does not exist: $Path"
    }

    $text = Get-Content -LiteralPath $Path -Raw
    $metadata = [pscustomobject]@{
        Name = Get-GFConfigValue -Text $text -Name "name"
        Version = Get-GFConfigValue -Text $text -Name "version"
        GodotVersion = Get-GFConfigValue -Text $text -Name "godot_version"
        Source = Get-GFConfigValue -Text $text -Name "source"
    }

    if ($metadata.Name -ne "Godot Framework") {
        throw "Unexpected Framework package name: $($metadata.Name)"
    }
    ConvertTo-GFVersion -Version $metadata.Version | Out-Null
    if (-not (Test-GFStableVersion -Version $metadata.GodotVersion)) {
        throw "Godot compatibility version must use x.y.z: $($metadata.GodotVersion)"
    }
    if ($metadata.Source -ne "https://github.com/ZhaoMCX/godot-framework") {
        throw "Unexpected Framework source: $($metadata.Source)"
    }
    return $metadata
}

function Set-GFMetadataVersion {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Version
    )

    ConvertTo-GFVersion -Version $Version | Out-Null
    $text = [IO.File]::ReadAllText($Path)
    Get-GFConfigValue -Text $text -Name "version" | Out-Null
    $updatedText = [regex]::Replace(
        $text,
        '(?m)^version="[^"\r\n]+"\s*$',
        "version=`"$Version`""
    )
    [IO.File]::WriteAllText($Path, $updatedText, [Text.UTF8Encoding]::new($false))
}

function Read-GFChecksum {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedFileName
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Checksum file does not exist: $Path"
    }
    $text = Get-Content -LiteralPath $Path -Raw
    $pattern = '^([0-9A-Fa-f]{64})  ' + [regex]::Escape($ExpectedFileName) + '\r?\n?$'
    $match = [regex]::Match($text, $pattern)
    if (-not $match.Success) {
        throw "Checksum file must contain exactly one hash for $ExpectedFileName."
    }
    return $match.Groups[1].Value.ToUpperInvariant()
}

function Test-GFOfficialRemote {
    param([Parameter(Mandatory = $true)][string]$RemoteUrl)

    $pattern = '^(?:https://github\.com/ZhaoMCX/godot-framework(?:\.git)?|' +
        'git@github\.com:ZhaoMCX/godot-framework(?:\.git)?|' +
        'ssh://git@ssh\.github\.com(?::443)?/ZhaoMCX/godot-framework(?:\.git)?)$'
    return [regex]::IsMatch($RemoteUrl, $pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

function Assert-GFPublishState {
    param(
        [Parameter(Mandatory = $true)][string]$TagName,
        [Parameter(Mandatory = $true)][bool]$WorktreeClean,
        [Parameter(Mandatory = $true)][bool]$RemoteIsOfficial,
        [Parameter(Mandatory = $true)][string]$CurrentBranch,
        [Parameter(Mandatory = $true)][string]$HeadCommit,
        [Parameter(Mandatory = $true)][string]$RemoteMasterCommit,
        [string]$LocalTagCommit = "",
        [string]$RemoteTagCommit = "",
        [bool]$LocalTagAnnotated = $false,
        [bool]$RemoteTagAnnotated = $false,
        [ValidateSet("missing", "draft", "published")][string]$ReleaseState = "missing"
    )

    if (-not $WorktreeClean) {
        throw "Framework publishing requires a clean worktree."
    }
    if (-not $RemoteIsOfficial) {
        throw "The origin remote is not the official Framework repository."
    }
    if ($CurrentBranch -ne "master") {
        throw "Framework publishing must run from master, not '$CurrentBranch'."
    }
    if (-not $HeadCommit.Equals($RemoteMasterCommit, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Local master must exactly match origin/master."
    }
    if (-not $LocalTagCommit -or -not $RemoteTagCommit) {
        throw "Tag $TagName must exist both locally and on origin."
    }
    if (-not $LocalTagAnnotated -or -not $RemoteTagAnnotated) {
        throw "Tag $TagName must be an annotated tag locally and on origin."
    }
    if (-not $HeadCommit.Equals($LocalTagCommit, [StringComparison]::OrdinalIgnoreCase) -or
        -not $HeadCommit.Equals($RemoteTagCommit, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Tag $TagName must point to the current master commit."
    }
    if ($ReleaseState -eq "published") {
        throw "Published release $TagName already exists and cannot be overwritten."
    }
}
