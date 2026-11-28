$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

Describe 'Ownership classification backport tracker exclusion' {
    BeforeAll {
        $repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        $workflow = Get-Content (Join-Path $repoRoot '.github/workflows/ownership-classification.yml') -Raw
        $stepIndex = $workflow.IndexOf('- name: Check labels and manual override', [StringComparison]::Ordinal)
        if ($stepIndex -lt 0) { throw 'Ownership preflight step was not found.' }
        $scriptMatch = [regex]::Match($workflow.Substring($stepIndex),
            '(?m)^          script: \|\r?\n(?<code>(?: {12}[^\r\n]*(?:\r?\n|$)|\r?\n)+)')
        if (-not $scriptMatch.Success) { throw 'Ownership preflight JavaScript could not be extracted.' }
        $scriptCode = (($scriptMatch.Groups['code'].Value -split '\r?\n') | ForEach-Object {
            if ($_.StartsWith('            ')) { $_.Substring(12) } else { $_ }
        }) -join "`n"
        $preflightPath = Join-Path $TestDrive 'preflight.js'
        Set-Content -LiteralPath $preflightPath -Value $scriptCode -Encoding utf8NoBOM
        $harnessPath = Join-Path $TestDrive 'ownership.cjs'
        @'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const script = fs.readFileSync(process.argv[2], 'utf8');
const scenario = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const labels = scenario.currentLabels.map(name => ({ name }));
const actual = { state: scenario.state, labels };
if (scenario.kind === 'pull_request') actual.pull_request = {};
process.env.SUBJECT_KIND = scenario.kind;
process.env.SUBJECT_NUMBER = '1';
let repositoryLabelReads = 0;
const listLabelsForRepo = () => {};
const listLabelsOnIssue = () => {};
const github = {
  rest: {
    issues: {
      get: async () => ({ data: actual }),
      listLabelsForRepo,
      listLabelsOnIssue,
      addLabels: async () => { throw new Error('Unexpected label mutation'); },
      removeLabel: async () => { throw new Error('Unexpected label mutation'); },
    },
  },
  paginate: async operation => {
    if (operation === listLabelsForRepo) {
      repositoryLabelReads++;
      return ['Team: Finance', 'Team: SCM', 'Team: Integrations', 'Team: Other',
        'Ownership: Manual', 'Ownership: Needs Review'].map(name => ({ name }));
    }
    if (operation === listLabelsOnIssue) return labels;
    throw new Error('Unexpected paginated operation');
  },
};
const context = {
  eventName: scenario.event,
  repo: { owner: 'example', repo: 'repository' },
  payload: { action: 'opened', [scenario.kind]: { labels: scenario.payloadLabels } },
};
const outputs = {};
const core = {
  setOutput: (name, value) => { outputs[name] = value; },
  info: () => {},
};
async function main() {
  const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
  await new AsyncFunction('github', 'context', 'core', script)(github, context, core);
  assert.equal(outputs.dispatch, scenario.expectedDispatch);
  assert.equal(repositoryLabelReads, scenario.expectedRepositoryLabelReads);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
'@ | Set-Content -LiteralPath $harnessPath -Encoding utf8NoBOM
    }

    It 'handles <name> without unintended label writes' -ForEach @(
        @{ name = 'automatic backport tracker'; kind = 'issue'; event = 'issues'; state = 'open'
            currentLabels = @('ext-backporting'); payloadLabels = @('ext-backporting')
            expectedDispatch = 'false'; expectedRepositoryLabelReads = 0 }
        @{ name = 'manually dispatched backport tracker'; kind = 'issue'; event = 'workflow_dispatch'; state = 'open'
            currentLabels = @('ext-backporting'); payloadLabels = @()
            expectedDispatch = 'false'; expectedRepositoryLabelReads = 0 }
        @{ name = 'stale issue event missing the current backport label'; kind = 'issue'; event = 'issues'; state = 'open'
            currentLabels = @('ext-backporting'); payloadLabels = @()
            expectedDispatch = 'false'; expectedRepositoryLabelReads = 0 }
        @{ name = 'case-insensitive backport label on manual dispatch'; kind = 'issue'; event = 'workflow_dispatch'; state = 'open'
            currentLabels = @('Ext-Backporting'); payloadLabels = @()
            expectedDispatch = 'false'; expectedRepositoryLabelReads = 0 }
        @{ name = 'closed backport tracker'; kind = 'issue'; event = 'workflow_dispatch'; state = 'closed'
            currentLabels = @('ext-backporting'); payloadLabels = @()
            expectedDispatch = 'false'; expectedRepositoryLabelReads = 0 }
        @{ name = 'ordinary extensibility issue'; kind = 'issue'; event = 'issues'; state = 'open'
            currentLabels = @('event-request', 'Team: SCM'); payloadLabels = @('event-request', 'Team: SCM')
            expectedDispatch = 'true'; expectedRepositoryLabelReads = 1 }
        @{ name = 'backport PR retaining normal ownership classification'; kind = 'pull_request'; event = 'pull_request_target'; state = 'open'
            currentLabels = @('ext-backporting', 'Team: SCM'); payloadLabels = @('ext-backporting', 'Team: SCM')
            expectedDispatch = 'true'; expectedRepositoryLabelReads = 1 }
    ) {
        $scenarioPath = Join-Path $TestDrive 'scenario.json'
        @{
            kind = $kind; event = $event; state = $state
            currentLabels = $currentLabels; payloadLabels = $payloadLabels
            expectedDispatch = $expectedDispatch; expectedRepositoryLabelReads = $expectedRepositoryLabelReads
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $scenarioPath -Encoding utf8NoBOM
        $output = & node $harnessPath $preflightPath $scenarioPath 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
    }
}
