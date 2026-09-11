<#
    Install-Orchestrator.ps1

    Copies the orchestrator source in this repository into a local Codex /
    OpenCodex configuration.

    Usage:
        .\scripts\Install-Orchestrator.ps1 -WhatIf
        .\scripts\Install-Orchestrator.ps1
        .\scripts\Install-Orchestrator.ps1 -SkillsRoot <path> -AgentsRoot <path>

    What it does:
        1. refuses to run when a required source file is missing;
        2. creates the target directories when they do not exist;
        3. backs up every target file it is about to replace, then replaces it;
        4. leaves target files that already match the repository untouched;
        5. prints each installed file with its SHA-256 hash.

    What it never does:
        - it never writes outside the two target directories and the backup
          directory;
        - it never touches routing configuration, provider configuration,
          credentials, or any other Codex/OpenCodex file;
        - it never deletes a target file: a file it replaces is copied into the
          backup directory first, and worker files this repository does not own
          are left alone;
        - it never makes a model call.

    -WhatIf prints the same plan without writing anything.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    # Skill directory that holds the orchestrator skill folder.
    # Default: %USERPROFILE%\.agents\skills
    [string]$SkillsRoot,

    # Directory that holds the five worker role files.
    # Default: %USERPROFILE%\.codex\agents
    [string]$AgentsRoot,

    # Destination for replaced files.
    # Default: %USERPROFILE%\.codex-orchestrator\backup
    [string]$BackupRoot
)

$ErrorActionPreference = 'Stop'
$pathSeparator = [string][char]92

# -WhatIf also reaches Test-Path, Get-Item, and Get-FileHash, which would make
# every comparison read as null and report a difference that is not there. The
# request is captured here and honoured explicitly, so -WhatIf suppresses
# exactly one thing: the write.
$whatIfRequested = $WhatIfPreference
$WhatIfPreference = $false

function Write-Head([string]$Text) {
    Write-Host ''
    Write-Host ('== ' + $Text)
}

function Stop-Refused([string]$Message, [int]$Code) {
    Write-Host ''
    Write-Host ('REFUSED: ' + $Message) -ForegroundColor Red
    exit $Code
}

function Get-FullPath([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.Length -gt 3) { $full = $full.TrimEnd([char]92, [char]47) }
    return $full
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDirectory

if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    Stop-Refused 'USERPROFILE is not set, so no default install location can be derived' 1
}
if ([string]::IsNullOrWhiteSpace($SkillsRoot)) { $SkillsRoot = Join-Path $env:USERPROFILE ('.agents' + $pathSeparator + 'skills') }
if ([string]::IsNullOrWhiteSpace($AgentsRoot)) { $AgentsRoot = Join-Path $env:USERPROFILE ('.codex' + $pathSeparator + 'agents') }
if ([string]::IsNullOrWhiteSpace($BackupRoot)) { $BackupRoot = Join-Path $env:USERPROFILE ('.codex-orchestrator' + $pathSeparator + 'backup') }

$skillsFull = Get-FullPath $SkillsRoot
$agentsFull = Get-FullPath $AgentsRoot
$backupFull = Get-FullPath $BackupRoot

$skillFolderName = 'orchestrator'
$referenceNames = @('handoff-contract.md', 'workflow-patterns.md', 'quality-gates.md', 'model-routing.md')
$workerNames = @('code-mapper.toml', 'implementer.toml', 'verifier.toml', 'reviewer.toml', 'debugger.toml')

function New-PlanEntry([string]$RelativeSource, [string]$TargetPath, [string]$BackupRelative) {
    return [pscustomobject]@{
        RelativeSource = $RelativeSource
        SourcePath     = Join-Path $repoRoot ($RelativeSource -replace '/', $pathSeparator)
        TargetPath     = $TargetPath
        BackupRelative = $BackupRelative
    }
}

$plan = New-Object System.Collections.Generic.List[object]

$skillTargetRoot = Join-Path $skillsFull $skillFolderName
$skillBackupRoot = Join-Path 'skills' $skillFolderName
$plan.Add((New-PlanEntry 'orchestrator/SKILL.md' (Join-Path $skillTargetRoot 'SKILL.md') (Join-Path $skillBackupRoot 'SKILL.md')))
$plan.Add((New-PlanEntry 'orchestrator/agents/openai.yaml' (Join-Path (Join-Path $skillTargetRoot 'agents') 'openai.yaml') (Join-Path (Join-Path $skillBackupRoot 'agents') 'openai.yaml')))
foreach ($name in $referenceNames) {
    $plan.Add((New-PlanEntry ('orchestrator/references/' + $name) (Join-Path (Join-Path $skillTargetRoot 'references') $name) (Join-Path (Join-Path $skillBackupRoot 'references') $name)))
}
foreach ($name in $workerNames) {
    $plan.Add((New-PlanEntry ('agents/' + $name) (Join-Path $agentsFull $name) (Join-Path 'agents' $name)))
}

Write-Head 'Install-Orchestrator.ps1'
Write-Host ('repository   : ' + $repoRoot)
Write-Host ('skills root  : ' + $skillsFull)
Write-Host ('agents root  : ' + $agentsFull)
Write-Host ('backup root  : ' + $backupFull)
if ($whatIfRequested) { Write-Host 'mode         : -WhatIf (nothing will be written)' }

# ---------------------------------------------------------------- source check

Write-Head 'required source files'
$missingSources = New-Object System.Collections.Generic.List[string]
foreach ($entry in $plan) {
    if (-not (Test-Path -LiteralPath $entry.SourcePath -PathType Leaf)) {
        $missingSources.Add($entry.RelativeSource)
    }
}
if ($missingSources.Count -gt 0) {
    foreach ($name in $missingSources) { Write-Host ('  missing  ' + $name) -ForegroundColor Red }
    Stop-Refused ('the repository is missing ' + $missingSources.Count + ' required source file(s); nothing was installed') 1
}
foreach ($entry in $plan) {
    Write-Host ('  found    ' + $entry.RelativeSource)
}

$versionPath = Join-Path $repoRoot 'VERSION'
$versionText = '(unknown)'
if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
    $versionText = (Get-Content -LiteralPath $versionPath -Raw).Trim()
}
Write-Host ('  version  ' + $versionText)

# ---------------------------------------------------------------- install

Write-Head 'install plan'
$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$runBackupRoot = Join-Path $backupFull $stamp

$installedCount = 0
$unchangedCount = 0
$replacedCount = 0
$createdCount = 0
$backupCount = 0

foreach ($entry in $plan) {
    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.SourcePath).Hash
    $exists = Test-Path -LiteralPath $entry.TargetPath -PathType Leaf

    if ($exists) {
        $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.TargetPath).Hash
        if ($targetHash -eq $sourceHash) {
            Write-Host ('  up to date  ' + $entry.TargetPath)
            $unchangedCount = $unchangedCount + 1
            continue
        }
    }

    $state = 'create'
    if ($exists) { $state = 'replace' }

    $backupPath = $null
    if ($exists) { $backupPath = Join-Path $runBackupRoot $entry.BackupRelative }

    if ($whatIfRequested -or (-not $PSCmdlet.ShouldProcess($entry.TargetPath, ('Install ' + $entry.RelativeSource)))) {
        Write-Host ('  ' + $state.PadRight(7) + ' ' + $entry.TargetPath + '  [what if]')
        if ($null -ne $backupPath) { Write-Host ('            backup to ' + $backupPath) }
        continue
    }

    if ($exists) {
        $backupDirectory = Split-Path -Parent $backupPath
        if (-not (Test-Path -LiteralPath $backupDirectory -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $backupDirectory | Out-Null
        }
        Copy-Item -LiteralPath $entry.TargetPath -Destination $backupPath -Force
        $backupCount = $backupCount + 1
    }

    $targetDirectory = Split-Path -Parent $entry.TargetPath
    if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
    }
    Copy-Item -LiteralPath $entry.SourcePath -Destination $entry.TargetPath -Force

    if ($state -eq 'replace') { $replacedCount = $replacedCount + 1 } else { $createdCount = $createdCount + 1 }
    $installedCount = $installedCount + 1

    Write-Host ('  ' + $state.PadRight(7) + ' ' + $entry.TargetPath + '  ' + $sourceHash)
}

# ---------------------------------------------------------------- summary

Write-Head 'result'
if ($whatIfRequested) {
    Write-Host 'what-if run: no file was written'
} else {
    Write-Host ('created          : ' + $createdCount)
    Write-Host ('replaced         : ' + $replacedCount)
    Write-Host ('already matching : ' + $unchangedCount)
    Write-Host ('files written    : ' + $installedCount)
    if ($backupCount -gt 0) { Write-Host ('backed up        : ' + $backupCount + ' -> ' + $runBackupRoot) }
}

Write-Head 'verify'
Write-Host 'Compare the repository against what is installed:'
Write-Host ('  ' + (Join-Path $scriptDirectory 'Compare-Installed.ps1'))
Write-Host 'Uninstall by deleting:'
Write-Host ('  ' + $skillTargetRoot)
foreach ($name in $workerNames) { Write-Host ('  ' + (Join-Path $agentsFull $name)) }

exit 0
