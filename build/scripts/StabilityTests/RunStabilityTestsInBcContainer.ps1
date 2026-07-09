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
    per base suite in the "Stability Run Configuration" table and the outcome of every test method
    is stored in the "Stability Run Result" table.

    This script drives the Command Line Test Tool page (130455) through BcContainerHelper's client
    context: it sets the base suite, invokes the "Run Stability Tests" action and reads the
    resulting JSON from the StabilityResultsJSONText control. The JSON mirrors the shape of the
    unstable-tests.json artifact so it can be uploaded from CI.

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
$SuiteControl = 'StabilitySuiteName'
$StabilityResultControl = 'StabilityResultsJSONText'
$RunStabilityActionName = 'RunStabilityTests'

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

    $parsed = $resultJson | ConvertFrom-Json
    Write-Host "Total results: $($parsed.total); failures: $($parsed.failures)."

    return $parsed
}
finally {
    if ($null -ne $clientContext) {
        Remove-BcContainerClientContext -clientContext $clientContext
    }
}
