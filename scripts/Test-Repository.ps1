<#
    Test-Repository.ps1

    Read-only validation of this repository as a self-contained release
    candidate. Safe to run locally and in CI.

    Usage:
        .\scripts\Test-Repository.ps1
        .\scripts\Test-Repository.ps1 -RepoRoot <path>

    Checks:
         1. required repository files exist;
         2. VERSION is a three-part version that names the release manifest;
         3. production TOML files are structurally valid;
         4. the five worker TOMLs remain model-neutral;
         5. the orchestrator references named by SKILL.md are present;
         6. every locally resolvable Markdown link resolves;
         7. no personal absolute paths, account identifiers, or email addresses;
         8. no common secret or credential value patterns;
         9. known raw telemetry material is absent;
        10. ignored material is covered by .gitignore;
        11. the release manifest matches the production source set;
        12. every JSON file in the repository parses;
        13. published benchmark results agree with the accepted evidence;
        14. every PowerShell script in the repository parses.
        15. YAML configuration files are structurally valid.

    Exit codes:
        0 - every check passed;
        1 - at least one check failed.

    This script never writes, never deletes, and never makes a model call.
#>

[CmdletBinding()]
param(
    # Repository root. Default: the parent directory of this script.
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
$pathSeparator = [string][char]92

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { $RepoRoot = Split-Path -Parent $scriptDirectory }
$repoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
if ($repoRoot.Length -gt 3) { $repoRoot = $repoRoot.TrimEnd([char]92, [char]47) }

$script:problems = New-Object System.Collections.Generic.List[string]
$script:checkCount = 0
$script:version = ''

# The production source set: what this repository publishes and installs. The
# five role files, the skill entry point, its four references, and the skill
# metadata file.
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

$workerNames = @('code-mapper.toml', 'implementer.toml', 'verifier.toml', 'reviewer.toml', 'debugger.toml')
$referenceNames = @('handoff-contract.md', 'workflow-patterns.md', 'quality-gates.md', 'model-routing.md')

function Fail([string]$Message) {
    $script:problems.Add($Message)
    Write-Host ('         ' + $Message) -ForegroundColor Yellow
}

function Write-Head([string]$Text) {
    Write-Host ''
    Write-Host ('== ' + $Text)
}

function Get-RepoPath([string]$RelativePath) {
    return (Join-Path $repoRoot ($RelativePath -replace '/', $pathSeparator))
}

function Get-RepoRelative([string]$FullPath) {
    $rootFull = $repoRoot + $pathSeparator
    if ($FullPath.StartsWith($rootFull)) {
        return ($FullPath.Substring($rootFull.Length) -replace [regex]::Escape($pathSeparator), '/')
    }
    return $FullPath
}

function Test-Check([string]$Name, [scriptblock]$Body) {
    $script:checkCount = $script:checkCount + 1
    $before = $script:problems.Count
    try {
        & $Body
    } catch {
        Fail ($Name + ': ' + $_.Exception.Message)
    }
    $status = 'PASS'
    $colour = 'Green'
    if ($script:problems.Count -gt $before) { $status = 'FAIL'; $colour = 'Red' }
    Write-Host ('  [' + $status + '] ' + $Name) -ForegroundColor $colour
}

$allFiles = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -File -Force)
$textExtensions = @('.md', '.toml', '.ps1', '.yml', '.yaml', '.json', '.jsonl', '.js', '.mjs', '.txt', '.csv')
$textFileNames = @('VERSION', 'LICENSE', '.gitignore', '.gitattributes')

$textFiles = New-Object System.Collections.Generic.List[object]
foreach ($file in $allFiles) {
    $isText = $textFileNames -contains $file.Name
    if (-not $isText) { $isText = $textExtensions -contains $file.Extension.ToLowerInvariant() }
    if ($isText) { $textFiles.Add($file) }
}

Write-Head 'Test-Repository.ps1'
Write-Host ('repository : ' + $repoRoot)
Write-Host ('host       : Windows PowerShell ' + $PSVersionTable.PSVersion.ToString())
Write-Host ('files      : ' + $allFiles.Count + ' total, ' + $textFiles.Count + ' scanned as text')

Write-Head 'checks'

# ------------------------------------------------------- 1. required files

Test-Check 'required repository files exist' {
    $required = @(
        'README.md', 'BASELINE.md', 'CHANGELOG.md', 'CONTRIBUTING.md', 'SECURITY.md',
        'VERSION', 'LICENSE', 'NOTICE.md', '.gitignore',
        'orchestrator/SKILL.md',
        'orchestrator/references/handoff-contract.md',
        'orchestrator/references/workflow-patterns.md',
        'orchestrator/references/quality-gates.md',
        'orchestrator/references/model-routing.md',
        'agents/code-mapper.toml', 'agents/implementer.toml', 'agents/verifier.toml',
        'agents/reviewer.toml', 'agents/debugger.toml',
        'docs/architecture.md', 'docs/installation.md', 'docs/model-routing.md',
        'docs/benchmarking.md', 'docs/git-workflow.md',
        'docs/decisions/0001-five-role-roster.md',
        'docs/decisions/0002-opencodex-v1-runtime.md',
        'docs/decisions/0003-evidence-first-delegation.md',
        'docs/decisions/0004-reuse-before-respawn.md',
        'docs/decisions/0005-thin-root-v12.md',
        'docs/release-checklist.md',
        'benchmarks/README.md',
        'benchmarks/role-selection/README.md',
        'benchmarks/role-selection/results/phase-a.md',
        'benchmarks/integrated-acceptance/README.md',
        'benchmarks/integrated-acceptance/results/integrated-acceptance-v1.md',
        'benchmarks/production-cost/README.md',
        'benchmarks/production-cost/results/case-01.md',
        'benchmarks/production-cost/results/case-02.md',
        'manifests/README.md',
        'scripts/Install-Orchestrator.ps1',
        'scripts/Compare-Installed.ps1',
        'scripts/Test-Repository.ps1',
        'scripts/New-ReleaseManifest.ps1',
        '.github/workflows/validate.yml',
        '.github/pull_request_template.md',
        '.github/ISSUE_TEMPLATE/bug_report.yml',
        '.github/ISSUE_TEMPLATE/improvement.yml'
    )
    $missing = 0
    foreach ($relative in $required) {
        if (-not (Test-Path -LiteralPath (Get-RepoPath $relative) -PathType Leaf)) {
            Fail ('missing required file: ' + $relative)
            $missing = $missing + 1
        }
    }
    if ($missing -gt 0) { Write-Host ('         ' + $missing + ' of ' + $required.Count + ' required files are missing') }
}

# ------------------------------------------------------- 2. VERSION

Test-Check 'VERSION is a three-part version that names a manifest' {
    $versionPath = Get-RepoPath 'VERSION'
    if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf)) { Fail 'VERSION is missing'; return }
    $text = ((Get-Content -LiteralPath $versionPath -Raw) -replace '\s', '')
    if ($text -notmatch '^\d+\.\d+\.\d+$') { Fail ('VERSION is not a three-part version: ' + $text); return }
    $script:version = $text
    $manifestRelative = 'manifests/v' + $text + '.sha256'
    if (-not (Test-Path -LiteralPath (Get-RepoPath $manifestRelative) -PathType Leaf)) {
        Fail ('VERSION is ' + $text + ' but ' + $manifestRelative + ' does not exist')
    }
    foreach ($doc in @('README.md', 'BASELINE.md')) {
        $docPath = Get-RepoPath $doc
        if (Test-Path -LiteralPath $docPath -PathType Leaf) {
            $docText = Get-Content -LiteralPath $docPath -Raw
            if ($docText -notmatch [regex]::Escape('v' + $text)) {
                Fail ($doc + ' does not mention the current version v' + $text)
            }
        }
    }
}

# ------------------------------------------------------- 3. TOML structure

Test-Check 'production TOML files are structurally valid' {
    $tomlFiles = @($allFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq '.toml' })
    if ($tomlFiles.Count -eq 0) { Fail 'no TOML files found'; return }
    foreach ($file in $tomlFiles) {
        $relative = Get-RepoRelative $file.FullName
        $lineNumber = 0
        $openBlock = $false
        foreach ($line in @(Get-Content -LiteralPath $file.FullName)) {
            $lineNumber = $lineNumber + 1
            $quotes = ([regex]::Matches($line, '"""')).Count
            if ($openBlock) {
                if (($quotes % 2) -eq 1) { $openBlock = $false }
                continue
            }
            if (($quotes % 2) -eq 1) { $openBlock = $true; continue }
            $trimmed = $line.Trim()
            if ($trimmed.Length -eq 0) { continue }
            if ($trimmed.StartsWith('#')) { continue }
            if ($trimmed -match '^\[\[?[A-Za-z0-9_.\-]+\]\]?$') { continue }
            if ($trimmed -match '^[A-Za-z0-9_\-\.]+\s*=\s*\S') { continue }
            Fail ($relative + ' line ' + $lineNumber + ': not a TOML key, table, or comment')
        }
        if ($openBlock) { Fail ($relative + ': unterminated multi-line string') }
    }
}

# ------------------------------------------------------- 4. model neutrality

Test-Check 'worker TOMLs remain model-neutral' {
    $pinnedKeys = @(
        'model', 'models', 'model_id', 'model_slug', 'reasoning', 'reasoning_effort',
        'effort', 'provider', 'provider_id', 'providers', 'temperature', 'top_p',
        'verbosity', 'api_base', 'base_url'
    )
    $pinnedValues = @('gpt-5', 'opencode-go/', 'muse-spark', 'deepseek-flash', 'glm-5', 'luna', 'sol')
    foreach ($name in $workerNames) {
        $path = Get-RepoPath ('agents/' + $name)
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Fail ('missing worker file: agents/' + $name); continue }
        $lineNumber = 0
        foreach ($line in @(Get-Content -LiteralPath $path)) {
            $lineNumber = $lineNumber + 1
            $trimmed = $line.Trim()
            if ($trimmed.Length -eq 0) { continue }
            if ($trimmed.StartsWith('#')) { continue }
            foreach ($key in $pinnedKeys) {
                if ($trimmed -match ('^' + [regex]::Escape($key) + '\s*=')) {
                    Fail ('agents/' + $name + ' line ' + $lineNumber + ': worker files must not pin ' + $key)
                }
            }
        }
        $content = Get-Content -LiteralPath $path -Raw
        foreach ($value in $pinnedValues) {
            $pattern = [regex]::Escape($value)
            if (($value -eq 'luna') -or ($value -eq 'sol')) { $pattern = '\b' + $value + '\b' }
            if ($content -match $pattern) { Fail ('agents/' + $name + ' contains a routing token: ' + $value) }
        }
        $nameMatch = [regex]::Match($content, '(?m)^\s*name\s*=\s*"([^"]+)"')
        if (-not $nameMatch.Success) {
            Fail ('agents/' + $name + ': no name field')
        } elseif (($nameMatch.Groups[1].Value + '.toml') -ne $name) {
            Fail ('agents/' + $name + ': name field is "' + $nameMatch.Groups[1].Value + '"')
        }
    }
}

# ------------------------------------------------------- 5. references

Test-Check 'orchestrator references exist and are named by SKILL.md' {
    foreach ($name in $referenceNames) {
        $relative = 'orchestrator/references/' + $name
        if (-not (Test-Path -LiteralPath (Get-RepoPath $relative) -PathType Leaf)) { Fail ('missing reference: ' + $relative) }
    }
    $skillPath = Get-RepoPath 'orchestrator/SKILL.md'
    if (Test-Path -LiteralPath $skillPath -PathType Leaf) {
        $skill = Get-Content -LiteralPath $skillPath -Raw
        foreach ($name in $referenceNames) {
            if ($skill -notmatch [regex]::Escape($name)) {
                Fail ('orchestrator/SKILL.md no longer names the reference ' + $name)
            }
        }
    }
}

# ------------------------------------------------------- 6. local links

Test-Check 'locally resolvable Markdown links resolve' {
    $markdownFiles = @($allFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq '.md' })
    $checked = 0
    foreach ($file in $markdownFiles) {
        $directory = Split-Path -Parent $file.FullName
        $relative = Get-RepoRelative $file.FullName
        $text = Get-Content -LiteralPath $file.FullName -Raw
        foreach ($match in [regex]::Matches($text, '\[[^\]]*\]\(([^)\s]+)')) {
            $target = $match.Groups[1].Value
            if ($target -match '^(https?:|mailto:|#|\.\.?$)') { continue }
            if ($target.StartsWith('<')) { $target = $target.Trim('<', '>') }
            $target = ($target -split '#')[0]
            if ($target.Length -eq 0) { continue }
            if ($target -match '^[A-Za-z]:') { Fail ($relative + ': link uses an absolute path: ' + $target); continue }
            if ($target.StartsWith('/')) { Fail ($relative + ': link uses a root-relative path: ' + $target); continue }
            $checked = $checked + 1
            $resolved = Join-Path $directory ($target -replace '/', $pathSeparator)
            if (-not (Test-Path -LiteralPath $resolved)) { Fail ($relative + ': broken link: ' + $target) }
        }
    }
    if ($checked -eq 0) { Fail 'no locally resolvable Markdown links were found' }
    Write-Host ('         ' + $checked + ' local links checked')
}

# ------------------------------------------------------- 7. personal data

Test-Check 'no personal paths, account identifiers, or email addresses' {
    $patterns = @(
        'C:[/\\]Users[/\\]',
        '/mnt/[a-z]/',
        'chatgpt-\d{6,}',
        '\bpf\d{5,}\b',
        'accountLogLabel',
        '[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'
    )
    $scanned = 0
    foreach ($file in $textFiles) {
        $relative = Get-RepoRelative $file.FullName
        # This script is skipped so that its own pattern table is never
        # reported as a hit; it holds no values, only regular expressions.
        if ($relative -eq 'scripts/Test-Repository.ps1') { continue }
        $content = Get-Content -LiteralPath $file.FullName -Raw
        if ([string]::IsNullOrEmpty($content)) { continue }
        $scanned = $scanned + 1
        foreach ($pattern in $patterns) {
            foreach ($match in [regex]::Matches($content, $pattern)) {
                Fail ($relative + ': personal-data pattern "' + $pattern + '" matched "' + $match.Value + '"')
            }
        }
    }
    Write-Host ('         ' + $scanned + ' files scanned')
}

# ------------------------------------------------------- 8. secrets

Test-Check 'no common secret or credential value patterns' {
    $patterns = @(
        'sk-[A-Za-z0-9]{16,}',
        'ghp_[A-Za-z0-9]{20,}',
        'gho_[A-Za-z0-9]{20,}',
        'github_pat_[A-Za-z0-9_]{20,}',
        'xoxb-[A-Za-z0-9\-]{10,}',
        'xoxp-[A-Za-z0-9\-]{10,}',
        'AKIA[0-9A-Z]{16}',
        '-----BEGIN [A-Z ]*PRIVATE KEY-----',
        'Bearer [A-Za-z0-9._\-]{20,}',
        'api[_-]?key\s*[:=]\s*\S',
        'passw(or)?d\s*[:=]\s*\S'
    )
    $scanned = 0
    foreach ($file in $textFiles) {
        $relative = Get-RepoRelative $file.FullName
        if ($relative -eq 'scripts/Test-Repository.ps1') { continue }
        $content = Get-Content -LiteralPath $file.FullName -Raw
        if ([string]::IsNullOrEmpty($content)) { continue }
        $scanned = $scanned + 1
        foreach ($pattern in $patterns) {
            foreach ($match in [regex]::Matches($content, $pattern)) {
                Fail ($relative + ': secret pattern "' + $pattern + '" matched "' + $match.Value + '"')
            }
        }
    }
    Write-Host ('         ' + $scanned + ' files scanned')
}

# ------------------------------------------------------- 9. raw telemetry

Test-Check 'known raw telemetry material is absent' {
    $forbiddenContainers = @(
        'measurements', 'generated', 'runs', 'private', 'worktrees', 'logs', 'backups'
    )
    $forbiddenFiles = @(
        'usage.jsonl', 'requests-window.jsonl', 'INTEGRATED_FROZEN.json', 'state.json',
        'summary.json', 'SPAWN_LOG.jsonl', 'ocx-config-show.txt', 'ocx-inspect-config.txt'
    )
    $forbiddenExtensions = @('.raw.json', '.diag.json')

    $directories = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Directory -Force)
    foreach ($directory in $directories) {
        if ($forbiddenContainers -contains $directory.Name.ToLowerInvariant()) {
            Fail ('raw or generated container directory is present: ' + (Get-RepoRelative $directory.FullName))
        }
    }
    foreach ($file in $allFiles) {
        $relative = Get-RepoRelative $file.FullName
        $lowerName = $file.Name.ToLowerInvariant()
        if ($forbiddenFiles -contains $file.Name) { Fail ('raw telemetry file is present: ' + $relative) }
        if ($lowerName.StartsWith('spawn_log')) { Fail ('spawn log is present: ' + $relative) }
        if ($lowerName.StartsWith('account-attribution')) { Fail ('account attribution file is present: ' + $relative) }
        foreach ($extension in $forbiddenExtensions) {
            if ($lowerName.EndsWith($extension)) { Fail ('raw capture file is present: ' + $relative) }
        }
    }
}

# ------------------------------------------------------- 10. gitignore coverage

Test-Check '.gitignore covers raw telemetry and leaves fixtures publishable' {
    $gitignorePath = Get-RepoPath '.gitignore'
    if (-not (Test-Path -LiteralPath $gitignorePath -PathType Leaf)) { Fail '.gitignore is missing'; return }
    $lines = @(Get-Content -LiteralPath $gitignorePath)
    foreach ($required in @('measurements/', 'usage.jsonl', 'generated/', 'runs/', '.env', '*.key')) {
        $found = $false
        foreach ($line in $lines) { if ($line.Trim() -eq $required) { $found = $true } }
        if (-not $found) { Fail ('.gitignore no longer ignores ' + $required) }
    }
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0) { continue }
        if ($trimmed.StartsWith('#')) { continue }
        if ($trimmed -match 'pristine') { Fail ('.gitignore ignores public benchmark fixtures: ' + $trimmed) }
        if ($trimmed -match 'USER_TASK') { Fail ('.gitignore ignores public benchmark input: ' + $trimmed) }
        if ($trimmed -match '^\*\.json$') { Fail ('.gitignore ignores every JSON file, including benchmark fixtures') }
        if ($trimmed -match '^\.github') { Fail ('.gitignore excludes .github content: ' + $trimmed) }
    }
}

# ------------------------------------------------------- 11. manifest

Test-Check 'release manifest matches the production source set' {
    if ([string]::IsNullOrEmpty($script:version)) { Fail 'VERSION could not be read, so the manifest cannot be checked'; return }
    $manifestRelative = 'manifests/v' + $script:version + '.sha256'
    $manifestPath = Get-RepoPath $manifestRelative
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { Fail (($manifestRelative) + ' is missing'); return }

    $entries = @{}
    $lineNumber = 0
    foreach ($line in @(Get-Content -LiteralPath $manifestPath)) {
        $lineNumber = $lineNumber + 1
        if ($line.Trim().Length -eq 0) { continue }
        $match = [regex]::Match($line, '^([0-9a-fA-F]{64})  (.+)$')
        if (-not $match.Success) {
            Fail ($manifestRelative + ' line ' + $lineNumber + ': expected "<64 hex>  <path>"')
            continue
        }
        $entries[$match.Groups[2].Value] = $match.Groups[1].Value.ToLowerInvariant()
    }

    foreach ($relative in $productionSource) {
        if (-not $entries.ContainsKey($relative)) { Fail ($manifestRelative + ' does not list ' + $relative); continue }
        $path = Get-RepoPath $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Fail ('production source file is missing: ' + $relative); continue }
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
        if ($actual -ne $entries[$relative]) { Fail ($relative + ' does not match the manifest hash') }
    }
    foreach ($key in $entries.Keys) {
        if ($productionSource -notcontains $key) { Fail ($manifestRelative + ' lists an unexpected path: ' + $key) }
    }
    Write-Host ('         ' + $entries.Count + ' manifest entries verified')
}

# ------------------------------------------------------- 12. JSON

Test-Check 'every JSON file parses' {
    $jsonFiles = @($allFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq '.json' })
    if ($jsonFiles.Count -eq 0) { Fail 'no JSON files found'; return }
    foreach ($file in $jsonFiles) {
        $relative = Get-RepoRelative $file.FullName
        try {
            $null = (Get-Content -LiteralPath $file.FullName -Raw) | ConvertFrom-Json
        } catch {
            Fail ($relative + ': ' + $_.Exception.Message)
        }
    }
    Write-Host ('         ' + $jsonFiles.Count + ' JSON files parsed')
}

# ------------------------------------------------------- 13. benchmark evidence

Test-Check 'published benchmark results agree with the accepted evidence' {
    $expected = New-Object 'System.Collections.Generic.Dictionary[string,object]'
    $expected['benchmarks/production-cost/results/case-01.md'] = @(
        '100 / 100', '| 20 | 883,237 |', '803,968', '79,269', '91.03', '6,397', '1,845',
        '| 13 | 370,321 |', '+5 pp', '| no |'
    )
    $expected['benchmarks/production-cost/results/case-02.md'] = @(
        '100 / 100', '| 8 | 261,065 |', '244,352', '16,713', '93.6', '2,328', '876',
        '| 0 | 0 | 0 | 0 |', '+2 pp'
    )
    $expected['benchmarks/integrated-acceptance/results/integrated-acceptance-v1.md'] = @(
        'RUNTIME ACCEPTED WITH MINOR ISSUES', '97.2 / 100'
    )
    $expected['benchmarks/role-selection/results/phase-a.md'] = @(
        'code-mapper', 'implementer', 'verifier', 'reviewer', 'debugger',
        '98.0', '100.0', '98.5', '96.0', '99.0'
    )
    foreach ($relative in $expected.Keys) {
        $path = Get-RepoPath $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Fail ('benchmark result is missing: ' + $relative); continue }
        $content = Get-Content -LiteralPath $path -Raw
        foreach ($token in $expected[$relative]) {
            if ($content -notmatch [regex]::Escape($token)) {
                Fail ($relative + ' no longer records the accepted value "' + $token + '"')
            }
        }
    }
}

# ------------------------------------------------------- 14. PowerShell parse

Test-Check 'every PowerShell script parses' {
    $scripts = @($allFiles | Where-Object { $_.Extension.ToLowerInvariant() -eq '.ps1' })
    if ($scripts.Count -eq 0) { Fail 'no PowerShell scripts found'; return }
    foreach ($file in $scripts) {
        $relative = Get-RepoRelative $file.FullName
        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
        if ($null -ne $errors -and $errors.Count -gt 0) {
            foreach ($error in $errors) {
                Fail ($relative + ' line ' + $error.Extent.StartLineNumber + ': ' + $error.Message)
            }
        }
    }
    Write-Host ('         ' + $scripts.Count + ' scripts parsed')
}

# ------------------------------------------------------- 15. YAML structure

Test-Check 'YAML files are structurally valid' {
    # GitHub ignores a workflow or an issue form whose YAML is malformed, and
    # neither Windows PowerShell 5.1 nor PowerShell 7 ships a YAML parser that
    # can be relied on here. This check walks block-style YAML itself: entry
    # shape, indentation, duplicate keys within one block, scalar quoting, and
    # the keys each file needs in order to work at all. Block scalars are
    # skipped as content. Flow collections spanning lines are not modelled.
    $yamlFiles = @($allFiles | Where-Object { @('.yml', '.yaml') -contains $_.Extension.ToLowerInvariant() })
    if ($yamlFiles.Count -eq 0) { Fail 'no YAML files found'; return }

    $requiredStructure = @{
        '.github/workflows/validate.yml' = @(
            '(?m)^on:\s*$',
            '(?m)^\s+pull_request:\s*$',
            '(?m)^\s+push:\s*$',
            '(?m)^\s+branches:\s*$',
            '(?m)^jobs:\s*$',
            '(?m)^\s+runs-on:\s+\S',
            '(?m)^\s+steps:\s*$',
            '(?m)^\s+uses:\s+actions/checkout@',
            '(?m)^\s+shell:\s+\S',
            'windows-latest',
            'Test-Repository\.ps1'
        )
        '.github/ISSUE_TEMPLATE/bug_report.yml' = @(
            '(?m)^name:\s+\S', '(?m)^description:\s+\S', '(?m)^body:\s*$'
        )
        '.github/ISSUE_TEMPLATE/improvement.yml' = @(
            '(?m)^name:\s+\S', '(?m)^description:\s+\S', '(?m)^body:\s*$'
        )
        'orchestrator/agents/openai.yaml' = @(
            '(?m)^interface:\s*$', '(?m)^\s+display_name:\s*\S', '(?m)^policy:\s*$', 'allow_implicit_invocation:'
        )
    }

    $lineBreak = [string][char]10
    $tabCharacter = [string][char]9
    $totalKeys = 0

    foreach ($file in $yamlFiles) {
        $relative = Get-RepoRelative $file.FullName
        $lines = @(Get-Content -LiteralPath $file.FullName)
        $raw = ($lines -join $lineBreak)

        if ($raw.Contains($tabCharacter)) {
            Fail ($relative + ': contains a tab character; YAML indentation must use spaces')
        }

        # One frame per open block: its indentation, and the mapping keys seen
        # in it so far. A deeper line may only follow a line that opens a
        # block, and a shallower line must return to an enclosing block.
        $frameIndents = New-Object System.Collections.Generic.List[int]
        $frameKeys = New-Object System.Collections.Generic.List[object]
        $frameIndents.Add(0)
        $frameKeys.Add((New-Object 'System.Collections.Generic.HashSet[string]'))
        $literalBlockUntil = -1
        $previousOpens = $true
        $firstContentLine = $true
        $lineNumber = 0

        foreach ($line in $lines) {
            $lineNumber = $lineNumber + 1
            $trimmed = $line.Trim()
            if ($trimmed.Length -eq 0) { continue }
            if ($trimmed.StartsWith('#')) { continue }

            $indent = $line.Length - $line.TrimStart(' ').Length
            if ($literalBlockUntil -ge 0) {
                if ($indent -gt $literalBlockUntil) { continue }
                $literalBlockUntil = -1
            }

            if ($firstContentLine) {
                if ($indent -ne 0) { Fail ($relative + ' line ' + $lineNumber + ': the first content line is indented by ' + $indent + ' spaces') }
                $firstContentLine = $false
            }

            $topIndex = $frameIndents.Count - 1
            if ($indent -gt $frameIndents[$topIndex]) {
                if (-not $previousOpens) {
                    Fail ($relative + ' line ' + $lineNumber + ': indented deeper than a line that opens no block')
                }
                $frameIndents.Add($indent)
                $frameKeys.Add((New-Object 'System.Collections.Generic.HashSet[string]'))
            } elseif ($indent -lt $frameIndents[$topIndex]) {
                while (($frameIndents.Count -gt 1) -and ($frameIndents[$frameIndents.Count - 1] -gt $indent)) {
                    $frameIndents.RemoveAt($frameIndents.Count - 1)
                    $frameKeys.RemoveAt($frameKeys.Count - 1)
                }
                if ($frameIndents[$frameIndents.Count - 1] -ne $indent) {
                    Fail ($relative + ' line ' + $lineNumber + ': indented by ' + $indent + ' spaces, which matches no enclosing block')
                }
            }

            $previousOpens = $false
            $body = $trimmed
            $entryIndent = $indent

            if ($body.StartsWith('- ') -or ($body -eq '-')) {
                if ($body -eq '-') { $previousOpens = $true; continue }
                $inline = $body.Substring(1).Trim()
                if ($inline -notmatch '^[^:\s][^:]*:(\s|$)') {
                    # A scalar sequence item; a deeper line would continue it.
                    $previousOpens = $true
                    continue
                }
                # An item that starts an inline mapping: its keys belong to a
                # block one step inside the item, and each item gets its own.
                $entryIndent = $indent + 2
                $frameIndents.Add($entryIndent)
                $frameKeys.Add((New-Object 'System.Collections.Generic.HashSet[string]'))
                $body = $inline
            } elseif ($body -notmatch '^[^:\s][^:]*:(\s|$)') {
                Fail ($relative + ' line ' + $lineNumber + ': not a block-style mapping entry or sequence item: ' + $body)
                continue
            }

            $colonIndex = $body.IndexOf(':')
            $key = $body.Substring(0, $colonIndex).Trim()
            $value = $body.Substring($colonIndex + 1).Trim()
            if ($value.StartsWith('#')) { $value = '' }

            $topIndex = $frameKeys.Count - 1
            if ($frameKeys[$topIndex].Contains($key)) {
                Fail ($relative + ' line ' + $lineNumber + ': duplicate key "' + $key + '" in one block')
            } else {
                $null = $frameKeys[$topIndex].Add($key)
            }
            $totalKeys = $totalKeys + 1

            if ($value.Length -eq 0) {
                $previousOpens = $true
            } elseif ($value.StartsWith('|') -or $value.StartsWith('>')) {
                $literalBlockUntil = $entryIndent
            } elseif ($value.StartsWith('"')) {
                if (($value.Length -lt 2) -or (-not $value.EndsWith('"'))) {
                    Fail ($relative + ' line ' + $lineNumber + ': unbalanced double quote in ' + $value)
                }
            } elseif ($value.StartsWith("'")) {
                if (($value.Length -lt 2) -or (-not $value.EndsWith("'"))) {
                    Fail ($relative + ' line ' + $lineNumber + ': unbalanced single quote in ' + $value)
                }
            } else {
                if ($value -match ':\s') {
                    Fail ($relative + ' line ' + $lineNumber + ': unquoted value contains a colon followed by a space, which YAML reads as a nested mapping')
                }
                if ($value -match '^[*&!%@]') {
                    Fail ($relative + ' line ' + $lineNumber + ': unquoted value starts with a YAML indicator this check does not model: ' + $value.Substring(0, 1))
                }
            }
        }
    }

    foreach ($relative in $requiredStructure.Keys) {
        $path = Get-RepoPath $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Fail ('required YAML file is missing: ' + $relative); continue }
        $content = Get-Content -LiteralPath $path -Raw
        foreach ($pattern in $requiredStructure[$relative]) {
            if ($content -notmatch $pattern) {
                Fail ($relative + ' no longer matches the required structure "' + $pattern + '"')
            }
        }
    }

    foreach ($file in $yamlFiles) {
        $relative = Get-RepoRelative $file.FullName
        if ($relative -notlike '.github/ISSUE_TEMPLATE/*') { continue }
        $content = Get-Content -LiteralPath $file.FullName -Raw
        $typeCount = ([regex]::Matches($content, '(?m)^\s+- type:')).Count
        $idCount = ([regex]::Matches($content, '(?m)^\s+id:')).Count
        $attributesCount = ([regex]::Matches($content, '(?m)^\s+attributes:')).Count
        $validationsCount = ([regex]::Matches($content, '(?m)^\s+validations:')).Count
        if ($typeCount -eq 0) {
            Fail ($relative + ': no issue-form fields found')
        } elseif (($typeCount -ne $idCount) -or ($typeCount -ne $attributesCount) -or ($typeCount -ne $validationsCount)) {
            Fail ($relative + ': ' + $typeCount + ' fields, ' + $idCount + ' ids, ' + $attributesCount + ' attribute blocks, ' + $validationsCount + ' validation blocks')
        }
    }

    Write-Host ('         ' + $yamlFiles.Count + ' YAML files, ' + $totalKeys + ' mapping keys checked')
}

# ------------------------------------------------------- summary

Write-Head 'summary'
Write-Host ('checks     : ' + $script:checkCount)
Write-Host ('problems   : ' + $script:problems.Count)
Write-Host ('version    : ' + $script:version)

if ($script:problems.Count -gt 0) {
    Write-Host ''
    Write-Host 'FAIL: repository validation found problems' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'PASS: repository validation succeeded' -ForegroundColor Green
exit 0
