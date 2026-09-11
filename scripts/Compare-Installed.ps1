<#
    Compare-Installed.ps1

    Read-only comparison between this repository and an installed orchestrator
    configuration. Reports identical, modified, missing, and extra files.

    Usage:
        .\scripts\Compare-Installed.ps1
        .\scripts\Compare-Installed.ps1 -SkillsRoot <path> -AgentsRoot <path>

    Exit codes:
        0 - every repository source file is installed and byte identical;
        1 - at least one file is modified or missing, or a source file is absent.

    This script never writes, never deletes, and never makes a model call.
#>

[CmdletBinding()]
param(
    # Skill directory that holds the orchestrator skill folder.
    # Default: %USERPROFILE%\.agents\skills
    [string]$SkillsRoot,

    # Directory that holds the five worker role files.
    # Default: %USERPROFILE%\.codex\agents
    [string]$AgentsRoot
)

$ErrorActionPreference = 'Stop'
$pathSeparator = [string][char]92

function Write-Head([string]$Text) {
    Write-Host ''
    Write-Host ('== ' + $Text)
}

function Get-FullPath([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.Length -gt 3) { $full = $full.TrimEnd([char]92, [char]47) }
    return $full
}

function Get-RelativePath([string]$Root, [string]$Path) {
    $rootFull = $Root
    if (-not $rootFull.EndsWith($pathSeparator)) { $rootFull = $rootFull + $pathSeparator }
    return $Path.Substring($rootFull.Length)
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDirectory

if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    Write-Host 'REFUSED: USERPROFILE is not set, so no default install location can be derived' -ForegroundColor Red
    exit 1
}
if ([string]::IsNullOrWhiteSpace($SkillsRoot)) { $SkillsRoot = Join-Path $env:USERPROFILE ('.agents' + $pathSeparator + 'skills') }
if ([string]::IsNullOrWhiteSpace($AgentsRoot)) { $AgentsRoot = Join-Path $env:USERPROFILE ('.codex' + $pathSeparator + 'agents') }

$skillsFull = Get-FullPath $SkillsRoot
$agentsFull = Get-FullPath $AgentsRoot
$skillTargetRoot = Join-Path $skillsFull 'orchestrator'

$referenceNames = @('handoff-contract.md', 'workflow-patterns.md', 'quality-gates.md', 'model-routing.md')
$workerNames = @('code-mapper.toml', 'implementer.toml', 'verifier.toml', 'reviewer.toml', 'debugger.toml')

$sources = New-Object System.Collections.Generic.List[object]
$sources.Add([pscustomobject]@{ RelativeSource = 'orchestrator/SKILL.md'; TargetPath = (Join-Path $skillTargetRoot 'SKILL.md') })
$sources.Add([pscustomobject]@{ RelativeSource = 'orchestrator/agents/openai.yaml'; TargetPath = (Join-Path (Join-Path $skillTargetRoot 'agents') 'openai.yaml') })
foreach ($name in $referenceNames) {
    $sources.Add([pscustomobject]@{ RelativeSource = ('orchestrator/references/' + $name); TargetPath = (Join-Path (Join-Path $skillTargetRoot 'references') $name) })
}
foreach ($name in $workerNames) {
    $sources.Add([pscustomobject]@{ RelativeSource = ('agents/' + $name); TargetPath = (Join-Path $agentsFull $name) })
}

Write-Head 'Compare-Installed.ps1'
Write-Host ('repository   : ' + $repoRoot)
Write-Host ('skills root  : ' + $skillsFull)
Write-Host ('agents root  : ' + $agentsFull)

$identical = New-Object System.Collections.Generic.List[string]
$modified = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]
$absentFromRepo = New-Object System.Collections.Generic.List[string]

foreach ($entry in $sources) {
    $sourcePath = Join-Path $repoRoot ($entry.RelativeSource -replace '/', $pathSeparator)
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        $absentFromRepo.Add($entry.RelativeSource)
        continue
    }
    if (-not (Test-Path -LiteralPath $entry.TargetPath -PathType Leaf)) {
        $missing.Add($entry.RelativeSource)
        continue
    }
    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
    $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.TargetPath).Hash
    if ($sourceHash -eq $targetHash) {
        $identical.Add($entry.RelativeSource)
    } else {
        $modified.Add($entry.RelativeSource)
    }
}

# Files that live where this repository installs but are not part of its source
# set. Extra files are reported, never modified and never removed. The agents
# directory is shared with other agents, so extras there are normal.
$expectedTargets = @{}
foreach ($entry in $sources) { $expectedTargets[$entry.TargetPath.ToLowerInvariant()] = $true }

$extra = New-Object System.Collections.Generic.List[string]

if (Test-Path -LiteralPath $skillTargetRoot -PathType Container) {
    foreach ($file in (Get-ChildItem -LiteralPath $skillTargetRoot -Recurse -File)) {
        if (-not $expectedTargets.ContainsKey($file.FullName.ToLowerInvariant())) {
            $extra.Add(('skills/orchestrator/' + (Get-RelativePath $skillTargetRoot $file.FullName)))
        }
    }
}
if (Test-Path -LiteralPath $agentsFull -PathType Container) {
    foreach ($file in (Get-ChildItem -LiteralPath $agentsFull -File -Filter '*.toml')) {
        if (-not $expectedTargets.ContainsKey($file.FullName.ToLowerInvariant())) {
            $extra.Add(('agents/' + $file.Name))
        }
    }
}

Write-Head 'comparison'
Write-Host ('  identical  ' + $identical.Count)
Write-Host ('  modified   ' + $modified.Count)
Write-Host ('  missing    ' + $missing.Count)
Write-Host ('  extra      ' + $extra.Count)

if ($identical.Count -gt 0) {
    Write-Host ''
    Write-Host 'identical:'
    foreach ($name in $identical) { Write-Host ('  ' + $name) }
}
if ($modified.Count -gt 0) {
    Write-Host ''
    Write-Host 'modified (installed content differs from this repository):' -ForegroundColor Yellow
    foreach ($name in $modified) { Write-Host ('  ' + $name) }
}
if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host 'missing (present in this repository, not installed):' -ForegroundColor Yellow
    foreach ($name in $missing) { Write-Host ('  ' + $name) }
}
if ($absentFromRepo.Count -gt 0) {
    Write-Host ''
    Write-Host 'absent from this repository:' -ForegroundColor Red
    foreach ($name in $absentFromRepo) { Write-Host ('  ' + $name) }
}
if ($extra.Count -gt 0) {
    Write-Host ''
    Write-Host 'extra (installed here, not part of this repository source set):'
    foreach ($name in $extra) { Write-Host ('  ' + $name) }
}

Write-Head 'result'
if ($absentFromRepo.Count -gt 0) {
    Write-Host 'FAIL: this repository is missing source files it is supposed to contain' -ForegroundColor Red
    exit 1
}
if (($modified.Count -eq 0) -and ($missing.Count -eq 0)) {
    Write-Host 'OK: every repository source file is installed and byte identical'
    exit 0
}
Write-Host 'DIFFERENT: the installed copy is not identical to this repository' -ForegroundColor Yellow
Write-Host 'Run Install-Orchestrator.ps1 to update it, or -WhatIf to preview the change.'
exit 1
