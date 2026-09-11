<#
    New-ReleaseManifest.ps1

    Generates a deterministic SHA-256 manifest for the production source set.

    Usage:
        .\scripts\New-ReleaseManifest.ps1             # write manifests\v<version>.sha256
        .\scripts\New-ReleaseManifest.ps1 -WhatIf     # print the manifest, write nothing
        .\scripts\New-ReleaseManifest.ps1 -OutputPath <path>

    Format: one line per file, '<lowercase sha256>  <repository-relative path>',
    with forward slashes, sorted in ordinal path order, LF line endings, no
    byte-order mark, and a trailing newline. The same source therefore always
    produces the same bytes, and the file can be checked with sha256sum -c.

    Exit codes:
        0 - the manifest was written, or -WhatIf printed it;
        1 - a required source file is missing, so nothing was written.

    This script performs no git operation and makes no model call.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    # Repository root. Default: the parent directory of this script.
    [string]$RepoRoot,

    # Manifest destination. Default: manifests\v<VERSION>.sha256
    [string]$OutputPath,

    # Print the manifest even when writing it.
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
$pathSeparator = [string][char]92
$lineFeed = [string][char]10

# -WhatIf also reaches Test-Path, Get-Item, and Get-FileHash, which would leave
# the reading phase with no file contents at all. The request is captured here
# and reapplied at the write step, so -WhatIf suppresses exactly one thing: the
# manifest file.
$whatIfRequested = $WhatIfPreference
$WhatIfPreference = $false

# The production source set: what this repository publishes and installs.
$productionSource = @(
    'orchestrator/SKILL.md',
    'orchestrator/agents/openai.yaml',
    'orchestrator/references/handoff-contract.md',
    'orchestrator/references/workflow-patterns.md',
    'orchestrator/references/quality-gates.md',
    'orchestrator/references/model-routing.md',
    'agents/code-mapper.toml',
    'agents/implementer.toml',
    'agents/verifier.toml',
    'agents/reviewer.toml',
    'agents/debugger.toml'
)

function Write-Head([string]$Text) {
    Write-Host ''
    Write-Host ('== ' + $Text)
}

function Stop-Refused([string]$Message, [int]$Code) {
    Write-Host ''
    Write-Host ('REFUSED: ' + $Message) -ForegroundColor Red
    exit $Code
}

function Get-RepoPath([string]$RelativePath) {
    return (Join-Path $script:repoRoot ($RelativePath -replace '/', $pathSeparator))
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { $RepoRoot = Split-Path -Parent $scriptDirectory }
$script:repoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
if ($script:repoRoot.Length -gt 3) { $script:repoRoot = $script:repoRoot.TrimEnd([char]92, [char]47) }

Write-Head 'New-ReleaseManifest.ps1'
Write-Host ('repository : ' + $script:repoRoot)

# ---------------------------------------------------------------- version

$versionPath = Get-RepoPath 'VERSION'
if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf)) { Stop-Refused 'VERSION is missing' 1 }
$version = (Get-Content -LiteralPath $versionPath -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { Stop-Refused ('VERSION is not a three-part version: ' + $version) 1 }
Write-Host ('version    : ' + $version)

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path (Join-Path $script:repoRoot 'manifests') ('v' + $version + '.sha256')
}
$outputFull = [System.IO.Path]::GetFullPath($OutputPath)
Write-Host ('manifest   : ' + $outputFull)

# ---------------------------------------------------------------- source

$ordered = New-Object System.Collections.Generic.List[string]
foreach ($relative in $productionSource) { $ordered.Add($relative) }
$ordered.Sort([System.StringComparer]::Ordinal)

Write-Head 'production source set'
$missing = New-Object System.Collections.Generic.List[string]
foreach ($relative in $ordered) {
    if (-not (Test-Path -LiteralPath (Get-RepoPath $relative) -PathType Leaf)) { $missing.Add($relative) }
}
if ($missing.Count -gt 0) {
    foreach ($relative in $missing) { Write-Host ('  missing  ' + $relative) -ForegroundColor Red }
    Stop-Refused ('the repository is missing ' + $missing.Count + ' production source file(s); no manifest was written') 1
}

$builder = New-Object System.Text.StringBuilder
$rows = New-Object System.Collections.Generic.List[object]
foreach ($relative in $ordered) {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Get-RepoPath $relative)).Hash.ToLowerInvariant()
    $null = $builder.Append($hash).Append('  ').Append($relative).Append($lineFeed)
    $rows.Add([pscustomobject]@{ Hash = $hash; Path = $relative })
    Write-Host ('  ' + $hash.Substring(0, 16) + '...  ' + $relative)
}
$manifestText = $builder.ToString()

# ---------------------------------------------------------------- diff

Write-Head 'change against the existing manifest'
$previous = $null
if (Test-Path -LiteralPath $outputFull -PathType Leaf) { $previous = Get-Content -LiteralPath $outputFull -Raw }

if ($null -eq $previous) {
    Write-Host ('  new manifest with ' + $rows.Count + ' entries')
} elseif ($previous -eq $manifestText) {
    Write-Host '  unchanged: the existing manifest already matches the source'
} else {
    $previousLines = @($previous -split $lineFeed | Where-Object { $_.Trim().Length -gt 0 })
    $currentLines = @($manifestText -split $lineFeed | Where-Object { $_.Trim().Length -gt 0 })
    foreach ($line in $currentLines) {
        if ($previousLines -notcontains $line) { Write-Host ('  + ' + $line) -ForegroundColor Yellow }
    }
    foreach ($line in $previousLines) {
        if ($currentLines -notcontains $line) { Write-Host ('  - ' + $line) -ForegroundColor Yellow }
    }
}

# ---------------------------------------------------------------- write

Write-Head 'result'
if ($whatIfRequested -or $PassThru) {
    Write-Host $manifestText
}

$WhatIfPreference = $whatIfRequested

if (-not $PSCmdlet.ShouldProcess($outputFull, 'Write release manifest')) {
    Write-Host 'what-if run: no file was written'
    exit 0
}

$outputDirectory = Split-Path -Parent $outputFull
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outputFull, $manifestText, $utf8NoBom)

$written = (Get-FileHash -Algorithm SHA256 -LiteralPath $outputFull).Hash
Write-Host ('wrote ' + $rows.Count + ' entries to ' + $outputFull)
Write-Host ('manifest sha256 : ' + $written)
Write-Host 'Verify with: .\scripts\Test-Repository.ps1'
exit 0
