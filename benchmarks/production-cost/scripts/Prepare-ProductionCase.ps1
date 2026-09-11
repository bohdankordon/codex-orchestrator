<#
    Prepare-ProductionCase.ps1

    Off-meter workspace preparation for the production-cost benchmark harness.

    Usage:
        .\Prepare-ProductionCase.ps1 case-01
        .\Prepare-ProductionCase.ps1 case-02

    What it does, for the selected case only:
        1. refuses an unknown case id;
        2. removes and recreates only that case's generated work directory;
        3. copies pristine -> work;
        4. records a deterministic SHA-256 baseline inventory;
        5. writes benchmark metadata outside the work directory;
        6. records the start-ready state;
        7. verifies that private / oracle / evaluator material was not copied;
        8. prints the exact working directory and the user task path.

    What it never does:
        - it never invokes a model, Codex, or an OpenCodex model request;
        - it never starts Measure-OcxUsage.ps1;
        - it never touches global or provider configuration;
        - it never writes anything inside the measured work tree.

    Safety: this script only ever deletes directories that resolve inside its own
    generated\ subtree, and it explicitly refuses any path that resolves into a
    case pristine directory. The measured work tree therefore always starts as an
    exact copy of pristine and never carries benchmark bookkeeping.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$CaseId,

    # Optional override, used only by the offline harness self test. Relative
    # paths resolve against this script's folder. The target must stay inside
    # generated\.
    [string]$WorkRoot
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$validCaseIds = @("case-01", "case-02")
$generatedRoot = Join-Path $scriptRoot "generated"
$tempRoot = Join-Path $generatedRoot "tmp"

# Generated / dependency directories are excluded from the inventory so that a
# routine "npm install" during the measured window cannot masquerade as a
# source change.
$excludedPrefixes = @("node_modules/", ".git/", ".cache/", "coverage/", ".nyc_output/", "dist/", "build/", "tmp/", ".tmp/")
$ignoredFileNames = @(".DS_Store", "Thumbs.db", "desktop.ini")

# Markers that must never appear in a measured work tree.
$forbiddenPathSegments = @("private", "oracle", "known-good")
$forbiddenNameMarkers = @("user_task.txt", "known-good", "hidden-check", "ocxresult", "ocxcheck", "production-cost", "oracle.json")
$forbiddenContentMarkers = @(
    "production-cost-benchmark",
    "user_task",
    "ocxresult",
    "ocxcheck",
    "hidden-checks.mjs",
    "prepare-productioncase",
    "evaluate-productioncase",
    "known-good",
    "correct_fix",
    "acceptable_corrections"
)
$textExtensions = @(".js", ".mjs", ".cjs", ".json", ".md", ".txt", ".yml", ".yaml", ".toml", ".csv", ".ps1", ".log")

# Words that would turn the user-facing prompt into a benchmark runbook.
$userTaskForbiddenWords = @("benchmark", "oracle", "score", "scoring", "hash", "hashes", "freeze", "measurement", "measure", "rubric", "spawn_log", "telemetry", "evaluator")

function Write-Head([string]$Text) {
    Write-Host ""
    Write-Host ("== " + $Text)
}

function Stop-Refused([string]$Message, [int]$Code) {
    Write-Host ""
    Write-Host ("REFUSED: " + $Message) -ForegroundColor Red
    exit $Code
}

function Get-FullPath([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.Length -gt 3) { $full = $full.TrimEnd([char]92, [char]47) }
    return $full
}

function Test-PathUnder([string]$Candidate, [string]$Parent) {
    $c = $Candidate.ToLowerInvariant()
    $p = $Parent.ToLowerInvariant()
    if ($c -eq $p) { return $false }
    if (-not $p.EndsWith([string][char]92)) { $p = $p + [string][char]92 }
    return $c.StartsWith($p)
}

function Test-Excluded([string]$RelativePath) {
    foreach ($prefix in $excludedPrefixes) {
        if ($RelativePath.ToLowerInvariant().StartsWith($prefix)) { return $true }
    }
    $name = $RelativePath.Substring($RelativePath.LastIndexOf("/") + 1)
    foreach ($ignored in $ignoredFileNames) {
        if ($name -ieq $ignored) { return $true }
    }
    return $false
}

function Get-TreeInventory([string]$Root) {
    $rootFull = Get-FullPath $Root
    $items = New-Object System.Collections.Generic.List[object]
    $stack = New-Object System.Collections.Generic.Stack[string]
    $stack.Push($rootFull)
    while ($stack.Count -gt 0) {
        $dir = $stack.Pop()
        foreach ($entry in (Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop)) {
            if ($entry.PSIsContainer) {
                $stack.Push($entry.FullName)
                continue
            }
            $rel = $entry.FullName.Substring($rootFull.Length).TrimStart([char]92, [char]47)
            $rel = $rel.Replace([string][char]92, "/")
            if (Test-Excluded $rel) { continue }
            $hash = (Get-FileHash -LiteralPath $entry.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            $items.Add([pscustomobject]@{
                path   = $rel
                sha256 = $hash
                bytes  = [int64]$entry.Length
            })
        }
    }
    $paths = @($items | ForEach-Object { $_.path })
    [Array]::Sort($paths, [System.StringComparer]::Ordinal)
    $byPath = @{}
    foreach ($item in $items) { $byPath[$item.path] = $item }
    $sorted = New-Object System.Collections.Generic.List[object]
    foreach ($p in $paths) { $sorted.Add($byPath[$p]) }
    return $sorted.ToArray()
}

function Get-TreeHash($Files) {
    $builder = New-Object System.Text.StringBuilder
    foreach ($file in $Files) {
        [void]$builder.Append($file.sha256)
        [void]$builder.Append("  ")
        [void]$builder.Append($file.path)
        [void]$builder.Append([string][char]10)
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($builder.ToString())
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $digest = $sha.ComputeHash($bytes)
    } finally {
        $sha.Dispose()
    }
    return ([System.BitConverter]::ToString($digest) -replace "-", "").ToLowerInvariant()
}

function Get-WorkTreeFindings([string]$Root) {
    $findings = New-Object System.Collections.Generic.List[object]
    foreach ($file in Get-TreeInventory $Root) {
        $segments = $file.path.Split("/")
        foreach ($segment in $segments[0..([Math]::Max(0, $segments.Count - 2))]) {
            foreach ($forbidden in $forbiddenPathSegments) {
                if ($segment -ieq $forbidden) {
                    $findings.Add([pscustomobject]@{ path = $file.path; reason = ("path segment '" + $segment + "'") })
                }
            }
        }
        $name = $segments[$segments.Count - 1]
        foreach ($marker in $forbiddenNameMarkers) {
            if ($name.ToLowerInvariant().Contains($marker)) {
                $findings.Add([pscustomobject]@{ path = $file.path; reason = ("file name marker '" + $marker + "'") })
            }
        }
        $extension = [System.IO.Path]::GetExtension($name).ToLowerInvariant()
        if ($textExtensions -notcontains $extension) { continue }
        $full = [System.IO.Path]::Combine((Get-FullPath $Root), $file.path.Replace("/", [string][char]92))
        if ($file.bytes -gt 1048576) { continue }
        $text = ([System.IO.File]::ReadAllText($full)).ToLowerInvariant()
        foreach ($marker in $forbiddenContentMarkers) {
            if ($text.Contains($marker)) {
                $findings.Add([pscustomobject]@{ path = $file.path; reason = ("content marker '" + $marker + "'") })
            }
        }
    }
    return , $findings.ToArray()
}

function Get-UserTaskFindings([string]$Path) {
    $findings = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path -LiteralPath $Path)) { return , $findings.ToArray() }
    $text = ([System.IO.File]::ReadAllText($Path)).ToLowerInvariant()
    foreach ($word in $userTaskForbiddenWords) {
        if ($text.Contains($word)) { $findings.Add($word) }
    }
    return , $findings.ToArray()
}

function Save-JsonFile([object]$Object, [string]$Path) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $text = $Object | ConvertTo-Json -Depth 24
    [System.IO.File]::WriteAllText($Path, ($text + [string][char]10), (New-Object System.Text.UTF8Encoding($false)))
}

function ConvertTo-RealArray([object]$Value) {
    # Windows PowerShell 5.1 collapses an empty array produced by a function
    # return or a .NET method call into AutomationNull. ConvertTo-Json then
    # writes that as {} instead of []. Rebuilding the collection keeps every
    # empty list well formed in the machine readable reports.
    $items = @()
    if ($null -ne $Value) {
        foreach ($item in $Value) { $items = $items + $item }
    }
    return , $items
}

# ---------------------------------------------------------------- selection

if ([string]::IsNullOrWhiteSpace($CaseId) -or ($validCaseIds -notcontains $CaseId)) {
    Write-Host ""
    Write-Host ("unknown case id: '" + $CaseId + "'")
    Write-Host ("valid case ids: " + ($validCaseIds -join ", "))
    Stop-Refused "no work directory was touched" 1
}

$caseRoot = Join-Path $scriptRoot $CaseId
$pristineRoot = Join-Path $caseRoot "pristine"
$privateRoot = Join-Path $caseRoot "private"
$userTaskPath = Join-Path $caseRoot "USER_TASK.txt"
$checksPath = Join-Path $privateRoot "checks\hidden-checks.mjs"
$caseGeneratedRoot = Join-Path $generatedRoot $CaseId
$defaultWorkRoot = Join-Path (Join-Path $generatedRoot "runs") (Join-Path $CaseId "work")
$defaultWorkRoot = [System.IO.Path]::Combine($generatedRoot, "runs", $CaseId, "work")
$baselinePath = Join-Path $caseGeneratedRoot "baseline.json"
$prepareReportPath = Join-Path $caseGeneratedRoot "prepare-report.json"
$statePath = Join-Path $caseGeneratedRoot "state.json"
$measurementName = "prod-v12-" + $CaseId

if ($CaseId -eq "case-01") { $measurementName = "prod-v12-case01" }
if ($CaseId -eq "case-02") { $measurementName = "prod-v12-case02" }

Write-Head ("Prepare-ProductionCase.ps1  case=" + $CaseId)

# ---------------------------------------------------------------- guards

if (-not (Test-Path -LiteralPath $pristineRoot)) {
    Stop-Refused ("the pristine workspace is missing: " + $pristineRoot) 1
}
if (-not (Test-Path -LiteralPath (Join-Path $pristineRoot "package.json"))) {
    Stop-Refused ("the pristine workspace has no package.json, so it is not a prepared case: " + $pristineRoot) 1
}
if (-not (Test-Path -LiteralPath $userTaskPath)) {
    Stop-Refused ("the user task file is missing: " + $userTaskPath) 1
}
if (-not (Test-Path -LiteralPath $checksPath)) {
    Stop-Refused ("the hidden acceptance checks are missing: " + $checksPath) 1
}

$generatedFull = Get-FullPath $generatedRoot
if ([string]::IsNullOrWhiteSpace($WorkRoot)) {
    $workRootFull = Get-FullPath $defaultWorkRoot
} else {
    if ([System.IO.Path]::IsPathRooted($WorkRoot)) { $candidate = $WorkRoot } else { $candidate = (Join-Path $scriptRoot $WorkRoot) }
    $workRootFull = Get-FullPath $candidate
}

Write-Host ("work directory      : " + $workRootFull)
Write-Host ("pristine source     : " + (Get-FullPath $pristineRoot))

if (-not (Test-PathUnder $workRootFull $generatedFull)) {
    Stop-Refused ("the work directory must stay inside " + $generatedFull + " (received " + $workRootFull + ")") 1
}
if ((Get-FullPath $workRootFull) -eq $generatedFull) {
    Stop-Refused "the work directory may not be the generated/ root itself" 1
}
foreach ($validId in $validCaseIds) {
    $pristineFull = Get-FullPath (Join-Path (Join-Path $scriptRoot $validId) "pristine")
    if (((Get-FullPath $workRootFull) -eq $pristineFull) -or (Test-PathUnder $workRootFull $pristineFull)) {
        Stop-Refused ("the work directory resolves into a pristine workspace: " + $pristineFull) 1
    }
}
if ((Get-FullPath $workRootFull).ToLowerInvariant().Contains("\pristine\")) {
    Stop-Refused "the work directory path contains a pristine segment" 1
}

# ---------------------------------------------------------------- recreate

if (Test-Path -LiteralPath $workRootFull) {
    $attributes = [System.IO.File]::GetAttributes($workRootFull)
    if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        Stop-Refused ("the work directory is a reparse point and will not be deleted: " + $workRootFull) 1
    }
    Write-Host "removing the previous generated work directory"
    Remove-Item -LiteralPath $workRootFull -Recurse -Force -ErrorAction Stop
}
New-Item -ItemType Directory -Path $workRootFull -Force | Out-Null

Write-Host "copying pristine -> work"
foreach ($entry in (Get-ChildItem -LiteralPath $pristineRoot -Force)) {
    Copy-Item -LiteralPath $entry.FullName -Destination $workRootFull -Recurse -Force -ErrorAction Stop
}

# ---------------------------------------------------------------- inventory

Write-Host "hashing the prepared work tree"
$workFiles = Get-TreeInventory $workRootFull
$pristineFiles = Get-TreeInventory $pristineRoot
$workTreeHash = Get-TreeHash $workFiles
$pristineTreeHash = Get-TreeHash $pristineFiles

$totalBytes = 0
foreach ($file in $workFiles) { $totalBytes = $totalBytes + $file.bytes }

# ---------------------------------------------------------------- verify

Write-Host "verifying copy fidelity and private material absence"
$mismatches = New-Object System.Collections.Generic.List[object]
$pristineByPath = @{}
foreach ($file in $pristineFiles) { $pristineByPath[$file.path] = $file.sha256 }
foreach ($file in $workFiles) {
    if (-not $pristineByPath.ContainsKey($file.path)) {
        $mismatches.Add([pscustomobject]@{ path = $file.path; reason = "not present in pristine" })
    } elseif ($pristineByPath[$file.path] -ne $file.sha256) {
        $mismatches.Add([pscustomobject]@{ path = $file.path; reason = "sha256 differs from pristine" })
    }
}
foreach ($file in $pristineFiles) {
    $found = $false
    foreach ($workFile in $workFiles) {
        if ($workFile.path -eq $file.path) { $found = $true; break }
    }
    if (-not $found) { $mismatches.Add([pscustomobject]@{ path = $file.path; reason = "missing from the work copy" }) }
}

# Assigning through ConvertTo-RealArray (instead of wrapping with @()) keeps an
# empty finding list at Count 0 under Windows PowerShell 5.1. Wrapping a
# function that returns , $emptyArray with @() would produce a one element
# array whose only element is the empty array.
$workFindings = ConvertTo-RealArray (Get-WorkTreeFindings $workRootFull)
$pristineFindings = ConvertTo-RealArray (Get-WorkTreeFindings $pristineRoot)
$userTaskFindings = ConvertTo-RealArray (Get-UserTaskFindings $userTaskPath)

$verificationFailures = New-Object System.Collections.Generic.List[string]
if ($mismatches.Count -gt 0) { $verificationFailures.Add("the work copy is not byte identical to pristine") }
if ($workFindings.Count -gt 0) { $verificationFailures.Add("private or benchmark material was found inside the work tree") }
if ($pristineFindings.Count -gt 0) { $verificationFailures.Add("private or benchmark material was found inside the pristine tree") }

if ($verificationFailures.Count -gt 0) {
    Save-JsonFile ([pscustomobject]@{
        schemaVersion = 1
        tool          = "Prepare-ProductionCase.ps1"
        caseId        = $CaseId
        status        = "verification-failed"
        workRoot      = $workRootFull
        failures      = ConvertTo-RealArray $verificationFailures
        mismatches    = ConvertTo-RealArray $mismatches
        workFindings  = ConvertTo-RealArray $workFindings
    }) $prepareReportPath
    foreach ($failure in $verificationFailures) { Write-Host ("  failure: " + $failure) -ForegroundColor Red }
    Stop-Refused ("preparation verification failed; see " + $prepareReportPath) 2
}

# ---------------------------------------------------------------- metadata

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")

Save-JsonFile ([pscustomobject]@{
    schemaVersion     = 1
    phase             = "baseline"
    caseId            = $CaseId
    generatedUtc      = $nowUtc
    workRoot          = $workRootFull
    pristineRoot      = (Get-FullPath $pristineRoot)
    fileCount         = $workFiles.Count
    totalBytes        = $totalBytes
    treeHash          = $workTreeHash
    excludedPrefixes  = $excludedPrefixes
    ignoredFileNames  = $ignoredFileNames
    files             = $workFiles
}) $baselinePath

$userTaskStatus = "clean"
if ($userTaskFindings.Count -gt 0) { $userTaskStatus = "warning" }

Save-JsonFile ([pscustomobject]@{
    schemaVersion          = 1
    tool                   = "Prepare-ProductionCase.ps1"
    caseId                 = $CaseId
    status                 = "ready"
    preparedAtUtc          = $nowUtc
    workRoot               = $workRootFull
    pristineRoot           = (Get-FullPath $pristineRoot)
    userTaskPath           = (Get-FullPath $userTaskPath)
    baselinePath           = $baselinePath
    statePath              = $statePath
    measurementName        = $measurementName
    workFileCount          = $workFiles.Count
    workTotalBytes         = $totalBytes
    workTreeHash           = $workTreeHash
    pristineFileCount      = $pristineFiles.Count
    pristineTreeHash       = $pristineTreeHash
    pristineEqualsWork     = ($pristineTreeHash -eq $workTreeHash)
    copyMismatches         = ConvertTo-RealArray $mismatches
    privateMaterialInWork  = ConvertTo-RealArray $workFindings
    privateMaterialInPristine = ConvertTo-RealArray $pristineFindings
    userTaskPurity         = [pscustomobject]@{ status = $userTaskStatus; findings = ConvertTo-RealArray $userTaskFindings }
    excludedPrefixes       = $excludedPrefixes
}) $prepareReportPath

Save-JsonFile ([pscustomobject]@{
    schemaVersion      = 1
    caseId             = $CaseId
    state              = "ready"
    measurementName    = $measurementName
    workRoot           = $workRootFull
    userTaskPath       = (Get-FullPath $userTaskPath)
    baselinePath       = $baselinePath
    prepareReportPath  = $prepareReportPath
    preparedAtUtc      = $nowUtc
    preparedBy         = "Prepare-ProductionCase.ps1"
    evaluation         = $null
}) $statePath

# ---------------------------------------------------------------- report

Write-Head "prepared"
Write-Host ("case id             : " + $CaseId)
Write-Host ("work file count     : " + $workFiles.Count)
Write-Host ("work tree hash      : " + $workTreeHash)
Write-Host ("pristine equals work: " + ($pristineTreeHash -eq $workTreeHash))
Write-Host ("baseline            : " + $baselinePath)
Write-Host ("prepare report      : " + $prepareReportPath)
Write-Host ("state               : " + $statePath)
Write-Host ""
Write-Host "WORKING DIRECTORY FOR THE MEASURED THREAD:" -ForegroundColor Yellow
Write-Host ("  " + $workRootFull) -ForegroundColor Yellow
Write-Host "USER TASK TO SEND (contents only):" -ForegroundColor Yellow
Write-Host ("  " + (Get-FullPath $userTaskPath)) -ForegroundColor Yellow
Write-Host ""
Write-Host "next steps (see RUN_INSTRUCTIONS.md):"
Write-Host ("  1. .\Measure-OcxUsage.ps1 start " + $measurementName)
Write-Host ("  2. open a fresh GPT-5.6 Sol High thread with working directory " + $workRootFull)
Write-Host ("  3. send only the contents of " + (Get-FullPath $userTaskPath))
Write-Host ("  4. .\Measure-OcxUsage.ps1 stop " + $measurementName)
Write-Host ("  5. .\Evaluate-ProductionCase.ps1 " + $CaseId)
Write-Host ("  6. .\Analyze-ProductionUsage.ps1 " + $measurementName + " " + $CaseId)

if ($userTaskFindings.Count -gt 0) {
    Write-Host ""
    Write-Host ("WARNING: USER_TASK.txt contains benchmark-flavoured words: " + ($userTaskFindings -join ", ")) -ForegroundColor Red
    Write-Host "WARNING: the measured prompt must read like an ordinary engineering request." -ForegroundColor Red
}

Write-Host ""
Write-Host "status: ready (no model, Codex, or OpenCodex call was made)"

exit 0
