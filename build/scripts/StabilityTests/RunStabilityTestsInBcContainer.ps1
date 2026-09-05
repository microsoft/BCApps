# ------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# ------------------------------------------------------------------------------------------------

<#
.SYNOPSIS
    Runs the test stability mode against a suite in a Business Central container and collects the
    results as a JSON artifact.
.DESCRIPTION
    Stability mode re-runs an existing test suite under several preset combinations (different
    random seeds, WorkDate shifted into the future, one-by-one isolation and reverse execution
    order) to surface flaky, order-dependent and data-dependent tests. The presets are configured
    as reusable "Test Configuration" records (each is a list of providers). No extra suites are
    created: the base suite is run in place under every configuration and the aggregated outcome is
    written back onto the base suite's own test method lines (failures concatenated per line).

    This script drives the Command Line Test Tool page (130455) through BcContainerHelper's client
    context: it sets the base suite, invokes the "Run stability tests" action and reads the
    resulting JSON from the TestConfigResultsJSON control. The run stops as soon as a configuration
    fails, so the returned JSON carries a "stoppedEarly" flag and a per-configuration summary. The
    script keeps the parsed results in memory, reports on every configuration that ran and then the
    totals, and writes the raw JSON to the output path so it can be uploaded from CI.

    NOTE: Wiring this into a GitHub workflow is intentionally out of scope for this change and will
    be done in a follow-up PR.
.PARAMETER ContainerName
    The name of the Business Central container.
.PARAMETER SuiteName
    The base test suite to run stability mode against (must already contain the tests to check).
.PARAMETER Credential
    The credentials used to open the client session.
.PARAMETER OutputPath
    File path to write the stability results JSON to.
.EXAMPLE
    .\RunStabilityTestsInBcContainer.ps1 -ContainerName bcserver -SuiteName 'MySuite' -Credential $cred -OutputPath .\stability-results.json
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $ContainerName,

    [Parameter(Mandatory = $true)]
    [string] $SuiteName,

    [Parameter(Mandatory = $true)]
    [pscredential] $Credential,

    [Parameter(Mandatory = $false)]
    [string] $OutputPath = (Join-Path (Get-Location) 'stability-results.json')
)

$ErrorActionPreference = 'Stop'

Import-Module BcContainerHelper -DisableNameChecking

# Page and control identifiers of the Command Line Test Tool + stability extension.
$CommandLineTestToolPageId = 130455
$SuiteControl = 'TestConfigSuiteName'
$StabilityResultControl = 'TestConfigResultsJSON'
$RunStabilityActionName = 'RunTestConfigurations'

Write-Host "Opening client context to container '$ContainerName'..."
$clientContext = $null
try {
    $clientContext = New-BcContainerClientContext -containerName $ContainerName -credential $Credential -culture 'en-US'

    Write-Host "Opening Command Line Test Tool (page $CommandLineTestToolPageId)..."
    $form = $clientContext.OpenForm($CommandLineTestToolPageId)
    if (-not $form) {
        throw "Could not open page $CommandLineTestToolPageId."
    }

    # Select the base suite.
    $suiteControl = $clientContext.GetControlByName($form, $SuiteControl)
    $clientContext.SaveValue($suiteControl, $SuiteName)

    # Invoke the stability run.
    Write-Host "Running stability tests for suite '$SuiteName'..."
    $runAction = $clientContext.GetActionByName($form, $RunStabilityActionName)
    $clientContext.InvokeAction($runAction)

    # Read the resulting JSON.
    $resultControl = $clientContext.GetControlByName($form, $StabilityResultControl)
    $resultJson = $clientContext.GetValue($resultControl)

    $clientContext.CloseForm($form)

    if ([string]::IsNullOrWhiteSpace($resultJson)) {
        throw "Stability run returned no results."
    }

    Set-Content -Path $OutputPath -Value $resultJson -Encoding UTF8
    Write-Host "Stability results written to '$OutputPath'."

    # Keep the parsed results in memory and report on every configuration that ran, then the totals.
    $parsed = $resultJson | ConvertFrom-Json

    Write-Host ''
    Write-Host "Stability run report for suite '$($parsed.baseSuite)':"
    if ($parsed.configurations) {
        foreach ($config in $parsed.configurations) {
            $status = if ($config.failures -gt 0) { 'FAILED' } else { 'passed' }
            Write-Host ("  [{0}] {1} - {2} test(s), {3} failure(s)" -f $status, $config.code, $config.total, $config.failures)
        }
    }

    if ($parsed.stoppedEarly) {
        Write-Host "Run stopped early after the first failing configuration." -ForegroundColor Yellow
    }

    Write-Host "Total results: $($parsed.total); failures: $($parsed.failures)."

    return $parsed
}
finally {
    if ($null -ne $clientContext) {
        Remove-BcContainerClientContext -clientContext $clientContext
    }
}
