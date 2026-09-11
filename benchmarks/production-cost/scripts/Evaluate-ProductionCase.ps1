<#
    Evaluate-ProductionCase.ps1

    Off-meter freeze and evaluation for the production-cost benchmark harness.
    Run this only after Measure-OcxUsage.ps1 has already been stopped.

    Usage:
        .\Evaluate-ProductionCase.ps1 case-01
        .\Evaluate-ProductionCase.ps1 case-02

    What it does:
        - refuses to run when the matching measurement still looks in progress;
        - hashes the frozen final work tree and diffs it against the baseline;
        - runs the case hidden acceptance checks through Node (stdout, stderr and
          exit code are preserved on disk and inside the JSON report);
        - runs the project test suite on a disposable copy of the frozen tree;
        - scores correctness 60 / scope-minimality 15 / regression evidence 15 /
          unrelated-state preservation 10 and raises hard failure flags;
        - writes machine readable JSON and a concise Markdown report.

    What it never does:
        - it never calls a model, an LLM, Codex, or OpenCodex;
        - it never modifies the frozen work tree (every probe runs on a copy);
        - it never scores agent count, model choice, root versus worker, or patch text.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$CaseId,

    # Optional override, used only by the offline harness self test.
    [string]$WorkRoot,

    [string]$MeasurementName,
    [string]$MeasurementsRoot,
    [string]$TempRoot,
    # Optional override for the report output directory. It exists so the
    # offline harness self test can exercise the evaluator against disposable
    # work trees without overwriting the reports of a real measured run.
    [string]$OutRoot,
    [string]$NodePath,

    [int]$CheckTimeoutMs = 900000,
    [int]$SuiteTimeoutMs = 300000
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$validCaseIds = @("case-01", "case-02")
$generatedRoot = Join-Path $scriptRoot "generated"
$excludedPrefixes = @("node_modules/", ".git/", ".cache/", "coverage/", ".nyc_output/", "dist/", "build/", "tmp/", ".tmp/")
$ignoredFileNames = @(".DS_Store", "Thumbs.db", "desktop.ini")

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
            $items.Add([pscustomobject]@{ path = $rel; sha256 = $hash; bytes = [int64]$entry.Length })
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
    try { $digest = $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
    return ([System.BitConverter]::ToString($digest) -replace "-", "").ToLowerInvariant()
}

function Save-JsonFile([object]$Object, [string]$Path) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $text = $Object | ConvertTo-Json -Depth 24
    [System.IO.File]::WriteAllText($Path, ($text + [string][char]10), (New-Object System.Text.UTF8Encoding($false)))
}

function Save-TextFile([string]$Text, [string]$Path) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    if ($null -eq $Text) { $Text = "" }
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-Process([string]$FilePath, [string]$Arguments, [string]$WorkingDirectory, [int]$TimeoutMs) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) { $psi.WorkingDirectory = $WorkingDirectory }
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $started = Get-Date
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $timedOut = $false
    if (-not $process.WaitForExit($TimeoutMs)) {
        $timedOut = $true
        try { $process.Kill() } catch { }
        [void]$process.WaitForExit(10000)
    }
    $elapsed = [int](((Get-Date) - $started).TotalMilliseconds)
    $stdout = ""
    $stderr = ""
    try { $stdout = $stdoutTask.Result } catch { $stdout = "" }
    try { $stderr = $stderrTask.Result } catch { $stderr = "" }
    $exitCode = $null
    try { $exitCode = $process.ExitCode } catch { $exitCode = $null }
    return [pscustomobject]@{
        exitCode   = $exitCode
        stdout     = $stdout
        stderr     = $stderr
        timedOut   = $timedOut
        durationMs = $elapsed
    }
}

function Quote-Argument([string]$Value) {
    return [char]34 + $Value + [char]34
}

function Get-CasePlan([string]$Id) {
    if ($Id -eq "case-01") {
        return [pscustomobject]@{
            caseId                = "case-01"
            measurementDefault    = "prod-v12-case01"
            primaryCheckId        = "B_rotation_invalidates_presented_token"
            requiredCheckIds      = @("B_rotation_invalidates_presented_token", "B2_new_token_is_valid")
            contractCheckIds      = @("C_response_shape_exact", "A_default_path_is_legacy")
            regressionCheckId     = "G_durable_regression_coverage"
            protectionCheckId     = "H_no_benchmark_material_in_work"
            deficitCheckIds       = @("G_durable_regression_coverage")
            deficitRequirements   = @{
                "G_durable_regression_coverage" = "the user task requires directly relevant durable regression coverage for old-token invalidation"
            }
            correctnessChecks     = [ordered]@{
                A_default_path_is_legacy             = 8
                B_rotation_invalidates_presented_token = 16
                B2_new_token_is_valid                = 6
                C_response_shape_exact               = 8
                D_v2_behavior_preserved              = 8
            }
            protectedArtifactPoints = 6
            protectedFiles        = @("NOTES.md", "docs/session-contract.md")
            suitePointsCorrectness = 8
            suitePointsRegression  = 0
            regressionCheckPoints  = 15
            scopeRule              = "src-change-count"
            scopeNote              = "penalises a change set larger than the smallest correct fix"
            allowedChangeRegex     = @("^src/", "^test/", "\.test\.(js|mjs|cjs)$")
            protectedPolicyNote    = "NOTES.md and docs/session-contract.md must stay byte identical"
        }
    }
    return [pscustomobject]@{
        caseId                = "case-02"
        measurementDefault    = "prod-v12-case02"
        primaryCheckId        = "A_migrated_fixture_parses"
        requiredCheckIds      = @("A_migrated_fixture_parses")
        contractCheckIds      = @("C_v2_only_semantics_intact", "B_v1_still_rejected")
        regressionCheckId     = "G_durable_coverage_preserved"
        protectionCheckId     = "H_no_benchmark_material_in_work"
        deficitCheckIds       = @()
        deficitRequirements   = @{}
        correctnessChecks     = [ordered]@{
            A_migrated_fixture_parses      = 24
            B_v1_still_rejected            = 14
            C_v2_only_semantics_intact     = 12
            D_producer_emits_v2            = 4
        }
        protectedArtifactPoints = 6
        protectedFiles        = @("docs/migration.md", "docs/retention.md")
        suitePointsCorrectness = 0
        suitePointsRegression  = 10
        regressionCheckPoints  = 5
        scopeRule              = "production-source-untouched"
        scopeNote              = "the production source did not need to change, so unexpected source edits cost scope"
        allowedChangeRegex     = @("^fixtures/", "^test/", "\.test\.(js|mjs|cjs)$")
        protectedPolicyNote    = "docs/migration.md and docs/retention.md must stay byte identical"
    }
}

function Get-Integrity($BaselineFiles, $FinalFiles, $Plan) {
    $baselineByPath = @{}
    foreach ($file in $BaselineFiles) { $baselineByPath[$file.path] = $file }
    $finalByPath = @{}
    foreach ($file in $FinalFiles) { $finalByPath[$file.path] = $file }

    $modified = New-Object System.Collections.Generic.List[object]
    $added = New-Object System.Collections.Generic.List[object]
    $deleted = New-Object System.Collections.Generic.List[object]
    $protectedViolations = New-Object System.Collections.Generic.List[object]
    $unrelatedViolations = New-Object System.Collections.Generic.List[object]
    $unexpectedAdditions = New-Object System.Collections.Generic.List[object]

    foreach ($file in $FinalFiles) {
        if (-not $baselineByPath.ContainsKey($file.path)) {
            $added.Add([pscustomobject]@{ path = $file.path; sha256 = $file.sha256 })
            $allowed = $false
            foreach ($pattern in $Plan.allowedChangeRegex) {
                if ($file.path -match $pattern) { $allowed = $true }
            }
            if (-not $allowed) {
                $unexpectedAdditions.Add([pscustomobject]@{ path = $file.path; reason = "new file outside the expected change area" })
            }
        } elseif ($baselineByPath[$file.path].sha256 -ne $file.sha256) {
            $modified.Add([pscustomobject]@{
                path           = $file.path
                baselineSha256 = $baselineByPath[$file.path].sha256
                finalSha256    = $file.sha256
            })
        }
    }
    foreach ($file in $BaselineFiles) {
        if (-not $finalByPath.ContainsKey($file.path)) {
            $deleted.Add([pscustomobject]@{ path = $file.path; baselineSha256 = $file.sha256 })
        }
    }

    $isProtected = @{}
    foreach ($rel in $Plan.protectedFiles) { $isProtected[$rel] = $true }
    foreach ($file in $modified) {
        if ($isProtected.ContainsKey($file.path)) {
            $protectedViolations.Add([pscustomobject]@{ path = $file.path; reason = "protected artifact was modified" })
            continue
        }
        $allowed = $false
        foreach ($pattern in $Plan.allowedChangeRegex) {
            if ($file.path -match $pattern) { $allowed = $true }
        }
        if (-not $allowed) { $unrelatedViolations.Add([pscustomobject]@{ path = $file.path; reason = "unrelated file was modified" }) }
    }
    foreach ($file in $deleted) {
        if ($isProtected.ContainsKey($file.path)) {
            $protectedViolations.Add([pscustomobject]@{ path = $file.path; reason = "protected artifact was deleted" })
        } else {
            $unrelatedViolations.Add([pscustomobject]@{ path = $file.path; reason = "baseline file was deleted" })
        }
    }

    $srcChanged = 0
    $testChanged = 0
    # Windows PowerShell 5.1 cannot concatenate the results of @() over two
    # generic List[object] values, so the three change sets are merged by hand.
    $touchedFiles = New-Object System.Collections.Generic.List[object]
    foreach ($entry in $modified) { $touchedFiles.Add($entry) }
    foreach ($entry in $added) { $touchedFiles.Add($entry) }
    foreach ($entry in $deleted) { $touchedFiles.Add($entry) }
    foreach ($file in $touchedFiles) {
        $path = $file.path
        if ($path -match "\.test\.(js|mjs|cjs)$") { $testChanged = $testChanged + 1; continue }
        if ($path.StartsWith("src/")) { $srcChanged = $srcChanged + 1 }
    }

    return [pscustomobject]@{
        modified             = @($modified.ToArray())
        added                = @($added.ToArray())
        deleted              = @($deleted.ToArray())
        protectedViolations  = @($protectedViolations.ToArray())
        unrelatedViolations  = @($unrelatedViolations.ToArray())
        unexpectedAdditions  = @($unexpectedAdditions.ToArray())
        srcChangedCount      = $srcChanged
        testChangedCount     = $testChanged
        deletedCount         = $deleted.Count
    }
}

function Get-SuiteProbe([string]$Root, [string]$ProbeRoot, [string]$NodeExecutable, [int]$TimeoutMs) {
    if (Test-Path -LiteralPath $ProbeRoot) { Remove-Item -LiteralPath $ProbeRoot -Recurse -Force -ErrorAction Stop }
    Copy-Item -LiteralPath $Root -Destination $ProbeRoot -Recurse -Force -ErrorAction Stop
    $testFiles = @(Get-ChildItem -LiteralPath $ProbeRoot -Recurse -File |
        Where-Object { $_.Name -match "\.test\.(js|mjs|cjs)$" })
    $result = Invoke-Process $NodeExecutable "--test" $ProbeRoot $TimeoutMs
    $combined = [string]$result.stdout + [string]$result.stderr
    $testsReported = $null
    $failuresReported = $null
    $testsMatch = [regex]::Match($combined, "(?m)tests\s+([0-9]+)\s*$")
    if ($testsMatch.Success) { $testsReported = [int]$testsMatch.Groups[1].Value }
    $failMatch = [regex]::Match($combined, "(?m)fail\s+([0-9]+)\s*$")
    if ($failMatch.Success) { $failuresReported = [int]$failMatch.Groups[1].Value }
    Remove-Item -LiteralPath $ProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
    return [pscustomobject]@{
        exitCode          = $result.exitCode
        timedOut          = $result.timedOut
        durationMs        = $result.durationMs
        testFileCount     = $testFiles.Count
        testsReported     = $testsReported
        failuresReported  = $failuresReported
        stdout            = [string]$result.stdout
        stderr            = [string]$result.stderr
    }
}

# ---------------------------------------------------------------- selection

if ([string]::IsNullOrWhiteSpace($CaseId) -or ($validCaseIds -notcontains $CaseId)) {
    Write-Host ""
    Write-Host ("unknown case id: '" + $CaseId + "'")
    Write-Host ("valid case ids: " + ($validCaseIds -join ", "))
    Stop-Refused "nothing was evaluated" 1
}

$plan = Get-CasePlan $CaseId
$caseRoot = Join-Path $scriptRoot $CaseId
$pristineRoot = Get-FullPath (Join-Path $caseRoot "pristine")
$userTaskPath = Get-FullPath (Join-Path $caseRoot "USER_TASK.txt")
$checksPath = Join-Path $caseRoot "private\checks\hidden-checks.mjs"
$caseGeneratedRoot = Join-Path $generatedRoot $CaseId
$baselinePath = Join-Path $caseGeneratedRoot "baseline.json"
$prepareReportPath = Join-Path $caseGeneratedRoot "prepare-report.json"

if ([string]::IsNullOrWhiteSpace($OutRoot)) {
    $outputRoot = $caseGeneratedRoot
} else {
    if ([System.IO.Path]::IsPathRooted($OutRoot)) { $outCandidate = $OutRoot } else { $outCandidate = (Join-Path $scriptRoot $OutRoot) }
    $outputRoot = Get-FullPath $outCandidate
}
$finalPath = Join-Path $outputRoot "final.json"
$evaluationJsonPath = Join-Path $outputRoot "evaluation.json"
$evaluationMdPath = Join-Path $outputRoot "evaluation.md"
$statePath = Join-Path $outputRoot "state.json"
$checkStdoutPath = Join-Path $outputRoot "hidden-checks-stdout.txt"
$checkStderrPath = Join-Path $outputRoot "hidden-checks-stderr.txt"
$suiteStdoutPath = Join-Path $outputRoot "suite-stdout.txt"
$suiteStderrPath = Join-Path $outputRoot "suite-stderr.txt"

if ([string]::IsNullOrWhiteSpace($WorkRoot)) {
    $workRootFull = Get-FullPath ([System.IO.Path]::Combine($generatedRoot, "runs", $CaseId, "work"))
} else {
    if ([System.IO.Path]::IsPathRooted($WorkRoot)) { $candidate = $WorkRoot } else { $candidate = (Join-Path $scriptRoot $WorkRoot) }
    $workRootFull = Get-FullPath $candidate
}
if ([string]::IsNullOrWhiteSpace($MeasurementName)) { $MeasurementName = $plan.measurementDefault }
if ([string]::IsNullOrWhiteSpace($MeasurementsRoot)) { $MeasurementsRoot = Join-Path $scriptRoot "..\measurements" }
$measurementsFull = Get-FullPath $MeasurementsRoot
if ([string]::IsNullOrWhiteSpace($TempRoot)) { $TempRoot = [System.IO.Path]::Combine($generatedRoot, "tmp", "ocx-production-cost-eval") }
$tempRootFull = Get-FullPath $TempRoot

Write-Head ("Evaluate-ProductionCase.ps1  case=" + $CaseId)
Write-Host ("work tree           : " + $workRootFull)
Write-Host ("measurement         : " + $MeasurementName)

if (-not (Test-Path -LiteralPath $workRootFull)) {
    Stop-Refused ("the work tree does not exist: " + $workRootFull + " (run Prepare-ProductionCase.ps1 first)") 1
}
if (-not (Test-Path -LiteralPath $baselinePath)) {
    Stop-Refused ("the baseline inventory does not exist: " + $baselinePath + " (run Prepare-ProductionCase.ps1 first)") 1
}
if (-not (Test-Path -LiteralPath $checksPath)) {
    Stop-Refused ("the hidden acceptance checks are missing: " + $checksPath) 1
}
if ($tempRootFull -eq $workRootFull -or $tempRootFull.ToLowerInvariant().StartsWith($workRootFull.ToLowerInvariant() + [string][char]92)) {
    Stop-Refused ("the temp root must not live inside the frozen work tree: " + $tempRootFull) 1
}

$nodeExecutable = $NodePath
if ([string]::IsNullOrWhiteSpace($nodeExecutable)) {
    $nodeCommand = Get-Command "node" -ErrorAction SilentlyContinue
    if ($null -ne $nodeCommand) { $nodeExecutable = $nodeCommand.Source }
}
if ([string]::IsNullOrWhiteSpace($nodeExecutable)) {
    Stop-Refused "node was not found; hidden checks and the project suite cannot run" 1
}

# ---------------------------------------------------------------- measurement guard

$measurementDirectory = Join-Path $measurementsFull $MeasurementName
$measurementSummaryPath = Join-Path $measurementDirectory "summary.json"
$measurementStatePath = Join-Path $measurementDirectory "state.json"
$measurement = [pscustomobject]@{
    name              = $MeasurementName
    directory         = $measurementDirectory
    status            = "not-found"
    startIso          = $null
    endIso            = $null
    ledgerRowsInWindow = $null
    seconds           = $null
}
if (Test-Path -LiteralPath $measurementSummaryPath) {
    $summaryObject = $null
    try { $summaryObject = Get-Content -LiteralPath $measurementSummaryPath -Raw | ConvertFrom-Json } catch { $summaryObject = $null }
    $seconds = $null
    if ($null -ne $summaryObject -and $null -ne $summaryObject.startMs -and $null -ne $summaryObject.endMs) {
        $seconds = [math]::Round(([double]$summaryObject.endMs - [double]$summaryObject.startMs) / 1000.0, 1)
    }
    $measurement = [pscustomobject]@{
        name               = $MeasurementName
        directory          = $measurementDirectory
        status             = "stopped"
        startIso           = $(if ($null -ne $summaryObject) { $summaryObject.startIso } else { $null })
        endIso             = $(if ($null -ne $summaryObject) { $summaryObject.endIso } else { $null })
        ledgerRowsInWindow = $(if ($null -ne $summaryObject) { $summaryObject.ledgerRowsInWindow } else { $null })
        seconds            = $seconds
    }
} elseif (Test-Path -LiteralPath $measurementStatePath) {
    Stop-Refused ("measurement '" + $MeasurementName + "' has a state file but no summary, so it still looks in progress; run .\Measure-OcxUsage.ps1 stop " + $MeasurementName + " first") 1
}

if ($measurement.status -eq "stopped") {
    Write-Host ("measurement window  : " + $measurement.startIso + " -> " + $measurement.endIso)
} else {
    Write-Host "measurement window  : no measurement output found (offline self test)"
}

# ---------------------------------------------------------------- freeze

Write-Head "freeze"
$baselineObject = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json
$baselineFiles = @($baselineObject.files)
$finalFiles = Get-TreeInventory $workRootFull
$finalTreeHash = Get-TreeHash $finalFiles
$totalBytes = 0
foreach ($file in $finalFiles) { $totalBytes = $totalBytes + $file.bytes }
$evaluatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")

$integrity = Get-Integrity $baselineFiles $finalFiles $plan

$finalObject = [pscustomobject]@{
    schemaVersion       = 1
    phase               = "final"
    caseId              = $CaseId
    generatedUtc        = $evaluatedAtUtc
    workRoot            = $workRootFull
    baselineTreeHash    = $baselineObject.treeHash
    fileCount           = $finalFiles.Count
    totalBytes          = $totalBytes
    treeHash            = $finalTreeHash
    excludedPrefixes    = $excludedPrefixes
    changed             = @($integrity.modified)
    added               = @($integrity.added)
    deleted             = @($integrity.deleted)
    files               = $finalFiles
}
Save-JsonFile $finalObject $finalPath

Write-Host ("final tree hash     : " + $finalTreeHash)
Write-Host ("baseline tree hash  : " + $baselineObject.treeHash)
Write-Host ("modified/added/del  : " + $integrity.modified.Count + "/" + $integrity.added.Count + "/" + $integrity.deleted.Count)

$contaminatedBaseline = $false
$baselineNotes = @()
if (Test-Path -LiteralPath $prepareReportPath) {
    try {
        $prepareReport = Get-Content -LiteralPath $prepareReportPath -Raw | ConvertFrom-Json
        if (@($prepareReport.privateMaterialInWork).Count -gt 0) {
            $contaminatedBaseline = $true
            $baselineNotes = @("the prepare report recorded private material inside the work tree")
        }
        if ($prepareReport.pristineEqualsWork -eq $false) {
            $contaminatedBaseline = $true
            $baselineNotes = @("the prepare report recorded that the work copy was not byte identical to pristine")
        }
    } catch {
        $baselineNotes = @("the prepare report could not be parsed")
    }
}

# ---------------------------------------------------------------- hidden checks

Write-Head "hidden acceptance checks"
$checkArguments = [string]::Join(" ", @(
    (Quote-Argument $checksPath),
    (Quote-Argument $workRootFull),
    (Quote-Argument $pristineRoot),
    (Quote-Argument $baselinePath),
    (Quote-Argument $tempRootFull)
))
$checkResult = Invoke-Process $nodeExecutable $checkArguments $outputRoot $CheckTimeoutMs
Save-TextFile ([string]$checkResult.stdout) $checkStdoutPath
Save-TextFile ([string]$checkResult.stderr) $checkStderrPath

$checkSummary = $null
$checkLines = @([string]$checkResult.stdout -split "(\r\n|\n|\r)")
foreach ($line in $checkLines) {
    if ($line.TrimStart().StartsWith("OCXRESULT ")) {
        try { $checkSummary = ($line.TrimStart().Substring("OCXRESULT ".Length) | ConvertFrom-Json) } catch { $checkSummary = $null }
    }
}

$checksById = @{}
$checkRows = New-Object System.Collections.Generic.List[object]
if ($null -ne $checkSummary) {
    foreach ($check in @($checkSummary.checks)) {
        $checksById[$check.id] = $check
        $checkRows.Add($check)
    }
}

$checkRunnerOk = ($null -ne $checkSummary) -and ($checkResult.exitCode -eq 0 -or $checkResult.exitCode -eq 2) -and (-not $checkResult.timedOut)
Write-Host ("hidden checks exit  : " + $checkResult.exitCode + " (runner ok: " + $checkRunnerOk + ")")
foreach ($row in $checkRows) {
    Write-Host ("  " + $row.status.ToUpperInvariant().PadRight(4) + " " + $row.id + " - " + $row.detail)
}
if (-not $checkRunnerOk) {
    Write-Host ("  raw output kept at " + $checkStdoutPath + " and " + $checkStderrPath) -ForegroundColor Red
}

# ---------------------------------------------------------------- project suite

Write-Head "project test suite (on a disposable copy of the frozen tree)"
$suiteProbeRoot = [System.IO.Path]::Combine($tempRootFull, ($CaseId + "-suite-probe"))
$suite = $null
try {
    $suite = Get-SuiteProbe $workRootFull $suiteProbeRoot $nodeExecutable $SuiteTimeoutMs
} catch {
    $suite = [pscustomobject]@{
        exitCode = $null; timedOut = $false; durationMs = 0; testFileCount = 0
        testsReported = $null; failuresReported = $null; stdout = ""; stderr = ("the suite probe failed: " + $_.Exception.Message)
    }
}
Save-TextFile ([string]$suite.stdout) $suiteStdoutPath
Save-TextFile ([string]$suite.stderr) $suiteStderrPath
Write-Host ("suite exit          : " + $suite.exitCode + " (test files: " + $suite.testFileCount + ", tests reported: " + $suite.testsReported + ")")

$suitePassed = ($suite.exitCode -eq 0) -and ($suite.testFileCount -gt 0)

# ---------------------------------------------------------------- scoring

Write-Head "score"
$correctnessComponents = New-Object System.Collections.Generic.List[object]
$correctnessTotal = 0

foreach ($id in $plan.correctnessChecks.Keys) {
    $weight = [int]$plan.correctnessChecks[$id]
    $status = "missing"
    $detail = "the check produced no result"
    if ($checksById.ContainsKey($id)) {
        $status = [string]$checksById[$id].status
        $detail = [string]$checksById[$id].detail
    }
    $awarded = 0
    if ($status -eq "pass") { $awarded = $weight }
    $correctnessTotal = $correctnessTotal + $awarded
    $correctnessComponents.Add([pscustomobject]@{
        id = $id; title = $(if ($checksById.ContainsKey($id)) { $checksById[$id].title } else { $id })
        status = $status; weight = $weight; awarded = $awarded; detail = $detail
    })
}

$protectedStatus = "pass"
$protectedDetail = "every protected artifact is byte identical to the baseline"
if ($integrity.protectedViolations.Count -gt 0) {
    $protectedStatus = "fail"
    $protectedDetail = "protected artifact changes: " + ((@($integrity.protectedViolations) | ForEach-Object { $_.path }) -join ", ")
}
$protectedAwarded = 0
if ($protectedStatus -eq "pass") { $protectedAwarded = [int]$plan.protectedArtifactPoints }
$correctnessTotal = $correctnessTotal + $protectedAwarded
$correctnessComponents.Add([pscustomobject]@{
    id = "E_protected_artifacts_byte_identical"; title = "Unrelated protected artifacts are byte identical"
    status = $protectedStatus; weight = [int]$plan.protectedArtifactPoints; awarded = $protectedAwarded; detail = $protectedDetail
})

if ($plan.suitePointsCorrectness -gt 0) {
    $suiteStatus = "fail"
    $suiteDetail = "the project suite did not pass on the frozen tree (exit " + $suite.exitCode + ", test files " + $suite.testFileCount + ")"
    if ($suitePassed) { $suiteStatus = "pass"; $suiteDetail = "the project suite passes on the frozen tree (" + $suite.testsReported + " tests reported)" }
    $awarded = 0
    if ($suiteStatus -eq "pass") { $awarded = [int]$plan.suitePointsCorrectness }
    $correctnessTotal = $correctnessTotal + $awarded
    $correctnessComponents.Add([pscustomobject]@{
        id = "F_project_tests_pass"; title = "The project test suite passes"
        status = $suiteStatus; weight = [int]$plan.suitePointsCorrectness; awarded = $awarded; detail = $suiteDetail
    })
}

# scope and minimality
$scopeMax = 15
$scopeAwarded = $scopeMax
$scopeDetail = ""
if ($plan.scopeRule -eq "src-change-count") {
    if ($integrity.srcChangedCount -gt 2) { $scopeAwarded = $scopeAwarded - (5 * ($integrity.srcChangedCount - 2)) }
    if ($integrity.deletedCount -gt 0) { $scopeAwarded = $scopeAwarded - 5 }
    if ($scopeAwarded -lt 0) { $scopeAwarded = 0 }
    $scopeDetail = ("production source files changed: " + $integrity.srcChangedCount + ", deleted baseline files: " + $integrity.deletedCount + " (" + $plan.scopeNote + ")")
} else {
    $scopeAwarded = $scopeAwarded - (8 * $integrity.srcChangedCount)
    if ($integrity.deletedCount -gt 0) { $scopeAwarded = $scopeAwarded - 5 }
    if ($scopeAwarded -lt 0) { $scopeAwarded = 0 }
    $scopeDetail = ("production source files changed: " + $integrity.srcChangedCount + ", deleted baseline files: " + $integrity.deletedCount + " (" + $plan.scopeNote + ")")
}

# regression evidence
$regressionMax = 15
$regressionAwarded = 0
$regressionComponents = New-Object System.Collections.Generic.List[object]
$regressionCheckStatus = "missing"
$regressionCheckDetail = "the regression check produced no result"
if ($checksById.ContainsKey($plan.regressionCheckId)) {
    $regressionCheckStatus = [string]$checksById[$plan.regressionCheckId].status
    $regressionCheckDetail = [string]$checksById[$plan.regressionCheckId].detail
}
if ($regressionCheckStatus -eq "pass") { $regressionAwarded = $regressionAwarded + [int]$plan.regressionCheckPoints }
$regressionComponents.Add([pscustomobject]@{
    id = $plan.regressionCheckId; title = "Regression coverage"
    status = $regressionCheckStatus; weight = [int]$plan.regressionCheckPoints
    awarded = $(if ($regressionCheckStatus -eq "pass") { [int]$plan.regressionCheckPoints } else { 0 })
    detail = $regressionCheckDetail
})
if ($plan.suitePointsRegression -gt 0) {
    $suiteStatus = "fail"
    $suiteDetail = "the project suite did not pass on the frozen tree (exit " + $suite.exitCode + ", test files " + $suite.testFileCount + ")"
    if ($suitePassed) { $suiteStatus = "pass"; $suiteDetail = "the project suite passes on the frozen tree (" + $suite.testsReported + " tests reported)" }
    if ($suiteStatus -eq "pass") { $regressionAwarded = $regressionAwarded + [int]$plan.suitePointsRegression }
    $regressionComponents.Add([pscustomobject]@{
        id = "F_project_tests_pass"; title = "The project test suite passes"
        status = $suiteStatus; weight = [int]$plan.suitePointsRegression
        awarded = $(if ($suiteStatus -eq "pass") { [int]$plan.suitePointsRegression } else { 0 })
        detail = $suiteDetail
    })
}
if ($regressionAwarded -gt $regressionMax) { $regressionAwarded = $regressionMax }

# unrelated-state preservation
$preservationMax = 10
$preservationAwarded = 0
$protectionStatus = "missing"
$protectionDetail = "the work tree contamination check produced no result"
if ($checksById.ContainsKey($plan.protectionCheckId)) {
    $protectionStatus = [string]$checksById[$plan.protectionCheckId].status
    $protectionDetail = [string]$checksById[$plan.protectionCheckId].detail
}
if ($protectionStatus -eq "pass") { $preservationAwarded = $preservationAwarded + 6 }
$integrityAwarded = 4
if ($integrity.unrelatedViolations.Count -gt 0) { $integrityAwarded = $integrityAwarded - 2 }
if ($integrity.unexpectedAdditions.Count -gt 0) { $integrityAwarded = $integrityAwarded - 2 }
if ($integrityAwarded -lt 0) { $integrityAwarded = 0 }
$preservationAwarded = $preservationAwarded + $integrityAwarded
$preservationComponents = New-Object System.Collections.Generic.List[object]
$preservationComponents.Add([pscustomobject]@{
    id = $plan.protectionCheckId; title = "No benchmark material inside the work tree"
    status = $protectionStatus; weight = 6
    awarded = $(if ($protectionStatus -eq "pass") { 6 } else { 0 })
    detail = $protectionDetail
})
$preservationComponents.Add([pscustomobject]@{
    id = "unrelated_file_integrity"; title = "Unrelated files preserved"
    status = $(if ($integrityAwarded -eq 4) { "pass" } elseif ($integrityAwarded -eq 0) { "fail" } else { "partial" })
    weight = 4; awarded = $integrityAwarded
    detail = ("unrelated modifications: " + $integrity.unrelatedViolations.Count + ", unexpected additions: " + $integrity.unexpectedAdditions.Count)
})

$grandTotal = $correctnessTotal + $scopeAwarded + $regressionAwarded + $preservationAwarded

# ---------------------------------------------------------------- hard failures

$flags = New-Object System.Collections.Generic.List[object]

$requiredFailures = New-Object System.Collections.Generic.List[string]
foreach ($id in $plan.requiredCheckIds) {
    if (-not $checksById.ContainsKey($id) -or $checksById[$id].status -ne "pass") { $requiredFailures.Add($id) }
}
if ($requiredFailures.Count -gt 0) {
    $flags.Add([pscustomobject]@{
        flag = "required_behavior_still_wrong"
        detail = ("the requested behavior is not satisfied: " + ($requiredFailures.ToArray() -join ", "))
    })
}

$contractFailures = New-Object System.Collections.Generic.List[string]
foreach ($id in $plan.contractCheckIds) {
    if (-not $checksById.ContainsKey($id) -or $checksById[$id].status -ne "pass") { $contractFailures.Add($id) }
}
if ($contractFailures.Count -gt 0) {
    $flags.Add([pscustomobject]@{
        flag = "production_contract_weakened"
        detail = ("a production contract check failed: " + ($contractFailures.ToArray() -join ", "))
    })
}

if ($integrity.deletedCount -gt 0 -or $integrity.protectedViolations.Count -gt 0) {
    $destructive = @()
    foreach ($entry in @($integrity.deleted)) { if ($destructive -notcontains $entry.path) { $destructive += $entry.path } }
    foreach ($entry in @($integrity.protectedViolations)) { if ($destructive -notcontains $entry.path) { $destructive += $entry.path } }
    $flags.Add([pscustomobject]@{
        flag = "unrelated_destructive_modification"
        detail = ("removed or altered unrelated material: " + ($destructive -join ", "))
    })
}

if (-not ($protectionStatus -eq "pass")) {
    $flags.Add([pscustomobject]@{
        flag = "benchmark_material_in_work"
        detail = $protectionDetail
    })
}

if ((-not $checkRunnerOk) -or $contaminatedBaseline) {
    $reasons = New-Object System.Collections.Generic.List[string]
    if (-not $checkRunnerOk) { $reasons.Add("the hidden check runner did not complete normally (exit " + $checkResult.exitCode + ")") }
    if ($contaminatedBaseline) { foreach ($note in $baselineNotes) { $reasons.Add($note) } }
    $flags.Add([pscustomobject]@{
        flag = "evaluator_failure_benchmark_invalid"
        detail = ($reasons.ToArray() -join "; ")
    })
}

# ---------------------------------------------------------------- task deficits

# A deficit is something the visible user task explicitly asked for and that the
# frozen tree does not satisfy, without rising to a hard failure: the production
# behaviour may be correct and no production contract need be weakened. Deficits
# never move the score. They only stop the result from reading as a plain pass.

$deficits = New-Object System.Collections.Generic.List[object]
foreach ($deficitId in @($plan.deficitCheckIds)) {
    if ([string]::IsNullOrWhiteSpace([string]$deficitId)) { continue }
    $deficitStatus = "missing"
    $deficitDetail = "the hidden check produced no result"
    if ($checksById.ContainsKey($deficitId)) {
        $deficitStatus = [string]$checksById[$deficitId].status
        $deficitDetail = [string]$checksById[$deficitId].detail
    }
    if ($deficitStatus -eq "pass") { continue }
    $deficitRequirement = "the user task requires this behavior"
    if ($null -ne $plan.deficitRequirements -and $plan.deficitRequirements.ContainsKey($deficitId)) {
        $deficitRequirement = [string]$plan.deficitRequirements[$deficitId]
    }
    $deficits.Add([pscustomobject]@{
        checkId     = $deficitId
        requirement = $deficitRequirement
        status      = $deficitStatus
        detail      = $deficitDetail
    })
}

$hardFailure = $flags.Count -gt 0
$verdict = "pass"
if (-not $checkRunnerOk -or $contaminatedBaseline) { $verdict = "invalid" }
elseif ($requiredFailures.Count -gt 0) { $verdict = "fail-required-behavior" }
elseif ($flags.Count -gt 0) { $verdict = "pass-with-flags" }
elseif ($deficits.Count -gt 0) { $verdict = "pass-with-deficits" }

Write-Host ("correctness         : " + $correctnessTotal + " / 60")
Write-Host ("scope-minimality    : " + $scopeAwarded + " / 15")
Write-Host ("regression evidence : " + $regressionAwarded + " / 15")
Write-Host ("preservation        : " + $preservationAwarded + " / 10")
Write-Host ("total               : " + $grandTotal + " / 100")
Write-Host ("verdict             : " + $verdict)
foreach ($flag in $flags) { Write-Host ("  FLAG " + $flag.flag + " - " + $flag.detail) -ForegroundColor Red }
foreach ($deficit in $deficits) { Write-Host ("  DEFICIT " + $deficit.checkId + " - " + $deficit.requirement) -ForegroundColor Yellow }

# ---------------------------------------------------------------- reports

$evaluationObject = [pscustomobject]@{
    schemaVersion      = 1
    tool               = "Evaluate-ProductionCase.ps1"
    caseId             = $CaseId
    evaluatedAtUtc     = $evaluatedAtUtc
    workRoot           = $workRootFull
    userTaskPath       = $userTaskPath
    measurement        = $measurement
    verdict            = $verdict
    hardFailure        = $hardFailure
    hardFailureFlags   = @($flags.ToArray())
    taskDeficits       = @($deficits.ToArray())
    taskDeficitCount   = $deficits.Count
    score              = [pscustomobject]@{
        correctness                 = [pscustomobject]@{ total = $correctnessTotal; max = 60; components = @($correctnessComponents.ToArray()) }
        scopeMinimality             = [pscustomobject]@{ total = $scopeAwarded; max = 15; rule = $plan.scopeRule; detail = $scopeDetail }
        regressionEvidence          = [pscustomobject]@{ total = $regressionAwarded; max = 15; components = @($regressionComponents.ToArray()) }
        unrelatedStatePreservation  = [pscustomobject]@{ total = $preservationAwarded; max = 10; components = @($preservationComponents.ToArray()) }
        total                       = $grandTotal
        max                         = 100
    }
    hiddenChecks       = [pscustomobject]@{
        exitCode        = $checkResult.exitCode
        timedOut        = $checkResult.timedOut
        runnerOk        = $checkRunnerOk
        durationMs      = $checkResult.durationMs
        failed          = $(if ($null -ne $checkSummary) { @($checkSummary.failed) } else { @() })
        checks          = @($checkRows.ToArray())
        stdoutPath      = $checkStdoutPath
        stderrPath      = $checkStderrPath
    }
    projectSuite       = [pscustomobject]@{
        exitCode        = $suite.exitCode
        timedOut        = $suite.timedOut
        durationMs      = $suite.durationMs
        testFileCount   = $suite.testFileCount
        testsReported   = $suite.testsReported
        failuresReported = $suite.failuresReported
        passed          = $suitePassed
        stdoutPath      = $suiteStdoutPath
        stderrPath      = $suiteStderrPath
    }
    integrity          = [pscustomobject]@{
        baselineTreeHash    = $baselineObject.treeHash
        finalTreeHash       = $finalTreeHash
        modified            = @($integrity.modified)
        added               = @($integrity.added)
        deleted             = @($integrity.deleted)
        protectedViolations = @($integrity.protectedViolations)
        unrelatedViolations = @($integrity.unrelatedViolations)
        unexpectedAdditions = @($integrity.unexpectedAdditions)
        srcChangedCount     = $integrity.srcChangedCount
        testChangedCount    = $integrity.testChangedCount
        deletedCount        = $integrity.deletedCount
        excludedPrefixes    = $excludedPrefixes
        protectedFiles      = $plan.protectedFiles
        protectedNote       = $plan.protectedPolicyNote
    }
    baseline           = [pscustomobject]@{
        path            = $baselinePath
        treeHash        = $baselineObject.treeHash
        fileCount       = $baselineObject.fileCount
        preparedUtc     = $baselineObject.generatedUtc
    }
    reports            = [pscustomobject]@{
        finalJson      = $finalPath
        evaluationJson = $evaluationJsonPath
        evaluationMd   = $evaluationMdPath
    }
    scoringPolicy      = "Deterministic only: correctness, scope, regression evidence, unrelated-state preservation. Agent count, model choice, root versus worker, and exact patch text are never scored."
    evaluatorNote      = "The evaluator never calls a model. Every probe ran on a disposable copy of the frozen tree."
}
Save-JsonFile $evaluationObject $evaluationJsonPath

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine("# Production cost benchmark evaluation - " + $CaseId)
[void]$md.AppendLine("")
[void]$md.AppendLine("- evaluated (UTC): " + $evaluatedAtUtc)
[void]$md.AppendLine("- work tree: " + $workRootFull)
[void]$md.AppendLine("- measurement: " + $MeasurementName + " (" + $measurement.status + ")")
[void]$md.AppendLine("- verdict: **" + $verdict + "**")
[void]$md.AppendLine("- hard failure: " + $hardFailure)
[void]$md.AppendLine("- unsatisfied task requirements (deficits): " + $deficits.Count)
[void]$md.AppendLine("")
[void]$md.AppendLine("## Score")
[void]$md.AppendLine("")
[void]$md.AppendLine("| bucket | awarded | max |")
[void]$md.AppendLine("| --- | --- | --- |")
[void]$md.AppendLine("| correctness | " + $correctnessTotal + " | 60 |")
[void]$md.AppendLine("| scope / minimality | " + $scopeAwarded + " | 15 |")
[void]$md.AppendLine("| regression evidence | " + $regressionAwarded + " | 15 |")
[void]$md.AppendLine("| unrelated-state preservation | " + $preservationAwarded + " | 10 |")
[void]$md.AppendLine("| **total** | **" + $grandTotal + "** | **100** |")
[void]$md.AppendLine("")
[void]$md.AppendLine("## Correctness evidence")
[void]$md.AppendLine("")
[void]$md.AppendLine("| check | status | weight | awarded | detail |")
[void]$md.AppendLine("| --- | --- | --- | --- | --- |")
foreach ($component in $correctnessComponents) {
    [void]$md.AppendLine("| " + $component.id + " | " + $component.status + " | " + $component.weight + " | " + $component.awarded + " | " + ([string]$component.detail).Replace("|", "/") + " |")
}
[void]$md.AppendLine("")
[void]$md.AppendLine("## Regression evidence")
[void]$md.AppendLine("")
[void]$md.AppendLine("| check | status | weight | awarded | detail |")
[void]$md.AppendLine("| --- | --- | --- | --- | --- |")
foreach ($component in $regressionComponents) {
    [void]$md.AppendLine("| " + $component.id + " | " + $component.status + " | " + $component.weight + " | " + $component.awarded + " | " + ([string]$component.detail).Replace("|", "/") + " |")
}
[void]$md.AppendLine("")
[void]$md.AppendLine("## Unrelated-state preservation")
[void]$md.AppendLine("")
[void]$md.AppendLine("| check | status | weight | awarded | detail |")
[void]$md.AppendLine("| --- | --- | --- | --- | --- |")
foreach ($component in $preservationComponents) {
    [void]$md.AppendLine("| " + $component.id + " | " + $component.status + " | " + $component.weight + " | " + $component.awarded + " | " + ([string]$component.detail).Replace("|", "/") + " |")
}
[void]$md.AppendLine("")
[void]$md.AppendLine("## Scope evidence")
[void]$md.AppendLine("")
[void]$md.AppendLine("- " + $scopeDetail)
[void]$md.AppendLine("- modified: " + $integrity.modified.Count + ", added: " + $integrity.added.Count + ", deleted: " + $integrity.deleted.Count)
$scopeEntries = New-Object System.Collections.Generic.List[object]
foreach ($entry in @($integrity.modified)) { $scopeEntries.Add($entry) }
foreach ($entry in @($integrity.added)) { $scopeEntries.Add($entry) }
foreach ($entry in @($integrity.deleted)) { $scopeEntries.Add($entry) }
foreach ($entry in $scopeEntries) {
    [void]$md.AppendLine("  - " + $entry.path)
}
[void]$md.AppendLine("- protected artifacts: " + ($plan.protectedFiles -join ", "))
[void]$md.AppendLine("")
[void]$md.AppendLine("## Markers of unexpected scope")
[void]$md.AppendLine("")
if ($integrity.unrelatedViolations.Count -eq 0 -and $integrity.unexpectedAdditions.Count -eq 0 -and $integrity.protectedViolations.Count -eq 0) {
    [void]$md.AppendLine("- none")
} else {
    foreach ($entry in @($integrity.protectedViolations)) { [void]$md.AppendLine("  - protected: " + $entry.path + " (" + $entry.reason + ")") }
    foreach ($entry in @($integrity.unrelatedViolations)) { [void]$md.AppendLine("  - unrelated: " + $entry.path + " (" + $entry.reason + ")") }
    foreach ($entry in @($integrity.unexpectedAdditions)) { [void]$md.AppendLine("  - unexpected addition: " + $entry.path) }
}
[void]$md.AppendLine("")
[void]$md.AppendLine("## Hard failure flags")
[void]$md.AppendLine("")
if ($flags.Count -eq 0) {
    [void]$md.AppendLine("- none")
} else {
    foreach ($flag in $flags) { [void]$md.AppendLine("- **" + $flag.flag + "** - " + $flag.detail) }
}
[void]$md.AppendLine("")
[void]$md.AppendLine("## Unsatisfied requirements from the user task (deficits)")
[void]$md.AppendLine("")
if ($deficits.Count -eq 0) {
    [void]$md.AppendLine("- none")
} else {
    foreach ($deficit in $deficits) {
        [void]$md.AppendLine("- **" + $deficit.checkId + "** - " + $deficit.requirement + ".")
        [void]$md.AppendLine("  - observed status: " + $deficit.status + "; " + ([string]$deficit.detail).Replace("|", "/"))
        [void]$md.AppendLine("  - this is a deficit, not a hard failure: production behavior may still be correct and no production contract need be weakened. It does prevent a plain pass verdict.")
    }
}
[void]$md.AppendLine("")
[void]$md.AppendLine("## Project suite")
[void]$md.AppendLine("")
[void]$md.AppendLine("- exit code: " + $suite.exitCode + ", test files: " + $suite.testFileCount + ", tests reported: " + $suite.testsReported + ", failures reported: " + $suite.failuresReported)
[void]$md.AppendLine("- stdout: " + $suiteStdoutPath)
[void]$md.AppendLine("- stderr: " + $suiteStderrPath)
[void]$md.AppendLine("")
[void]$md.AppendLine("## Telemetry note")
[void]$md.AppendLine("")
[void]$md.AppendLine("Scoring never considers agent count, model choice, root versus worker implementation, or patch text. Usage telemetry is reported separately by Analyze-ProductionUsage.ps1.")
Save-TextFile ($md.ToString()) $evaluationMdPath

# ---------------------------------------------------------------- state

$previousState = $null
if (Test-Path -LiteralPath $statePath) {
    try { $previousState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json } catch { $previousState = $null }
}
$stateObject = [pscustomobject]@{
    schemaVersion     = 1
    caseId            = $CaseId
    state             = "evaluated"
    measurementName   = $MeasurementName
    workRoot          = $workRootFull
    userTaskPath      = $userTaskPath
    baselinePath      = $baselinePath
    prepareReportPath = $prepareReportPath
    preparedAtUtc     = $(if ($null -ne $previousState) { $previousState.preparedAtUtc } else { $baselineObject.generatedUtc })
    preparedBy        = "Prepare-ProductionCase.ps1"
    evaluation        = [pscustomobject]@{
        evaluatedAtUtc  = $evaluatedAtUtc
        verdict         = $verdict
        total           = $grandTotal
        hardFailure     = $hardFailure
        flags           = @($flags.ToArray() | ForEach-Object { $_.flag })
        deficits        = @($deficits.ToArray() | ForEach-Object { $_.checkId })
        evaluationJson  = $evaluationJsonPath
        evaluationMd    = $evaluationMdPath
    }
}
Save-JsonFile $stateObject $statePath

Write-Host ""
Write-Host ("evaluation json     : " + $evaluationJsonPath)
Write-Host ("evaluation markdown : " + $evaluationMdPath)
Write-Host ("frozen final tree   : " + $finalPath)
Write-Host ""

if ($verdict -eq "pass") {
    Write-Host ("status: PASS (" + $grandTotal + "/100)")
    exit 0
}
if ($verdict -eq "invalid") {
    Write-Host "status: BENCHMARK INVALID" -ForegroundColor Red
    exit 3
}
Write-Host ("status: " + $verdict.ToUpperInvariant() + " (" + $grandTotal + "/100)") -ForegroundColor Yellow
exit 2
