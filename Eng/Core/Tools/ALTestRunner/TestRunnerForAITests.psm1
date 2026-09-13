
# Initialize
function Initialize-Module {
    param (
        [ValidateSet("PROD", "OnPrem")]
        [string] $Environment,
        [ValidateSet("AAD", "Windows", "NavUserPassword")]
        [string] $AuthorizationType,
        [switch] $DisableSSLVerification,
        [pscredential] $Credential,
        [pscredential] $Token,
        [string] $EnvironmentName,
        [string] $ServiceUrl,
        [string] $ClientId,
        [string] $RedirectUri,
        [string] $AadTenantId,
        [string] $APIHost,
        [string] $ServerInstance,
        [Nullable[guid]] $CompanyId,
        [int] $ClientSessionTimeout,
        [int] $TransactionTimeout,
        [string] $Culture = 'en-US'
    )

    $initArguments = @{
        Environment            = $Environment
        AuthorizationType      = $AuthorizationType
        DisableSSLVerification = $DisableSSLVerification
        Credential             = $Credential
        Token                  = $Token
        EnvironmentName        = $EnvironmentName
        ServiceUrl             = $ServiceUrl
        ClientId               = $ClientId
        RedirectUri            = $RedirectUri
        AadTenantId            = $AadTenantId
        APIHost                = $APIHost
        ServerInstance         = $ServerInstance
        CompanyId              = $CompanyId
        Culture                = $Culture
    }
    
    if ($PSBoundParameters.ContainsKey('ClientSessionTimeout')) {
        $initArguments.ClientSessionTimeout = $ClientSessionTimeout
    }
    if ($PSBoundParameters.ContainsKey('TransactionTimeout')) {
        $initArguments.TransactionTimeout = $TransactionTimeout
    }

    TestRunnerInternalForAIT\Initialize-TestRunner @initArguments
}

# Prerequisite: Initialize the Module
# Run the suite test lines and get the test results:
function Invoke-AITTests {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [string] $SuiteLineNo,
        [switch] $ResetTestSuite,
        [string] $AgentTaskLogFolder
    )

    if ($ResetTestSuite) {
        TestRunnerInternalForAIT\Reset-AITTestSuite -SuiteCode $SuiteCode
    }

    $TestRunResult = TestRunnerInternalForAIT\Invoke-AITSuite -SuiteCode $SuiteCode -SuiteLineNo $SuiteLineNo -AgentTaskLogFolder $AgentTaskLogFolder

    return $TestRunResult
}

# Prerequisite: Initialize the Module
# Upload the dataset
function Set-InputDataset {
    param (
        [Parameter(Mandatory = $true)]
        [string] $InputDatasetFilename,
        [Parameter(Mandatory = $true)]
        [string] $InputDatasetPath
    )
    $InputDatasetContent = Get-Content $InputDatasetPath -Raw
    TestRunnerInternalForAIT\Set-InputDatasetInternal -InputDatasetFilename $InputDatasetFilename -InputDataset $InputDatasetContent
}

# Prerequisite: Initialize the Module
# Upload the suite definition
function Set-SuiteDefinition {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteDefinitionPath
    )
    $SuiteDefinition = [xml](Get-Content $SuiteDefinitionPath)
    TestRunnerInternalForAIT\Set-SuiteDefinitionInternal -SuiteDefinition $SuiteDefinition
}

# Prerequisite: Initialize the Module
# Get the test results using the APIs
function Get-AITSuiteTestResult {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Int32] $TestRunVersion,
        [Int32] $CodeunitId,
        [string] $CodeunitName,
        [string] $TestStatus,
        [string] $ProcedureName
    )

    return TestRunnerInternalForAIT\Get-AITSuiteTestResultInternal -SuiteCode $SuiteCode -TestRunVersion $TestRunVersion -CodeunitId $CodeunitId -CodeunitName $CodeunitName -TestStatus $TestStatus -ProcedureName $ProcedureName
}

# Prerequisite: Initialize the Module
# Get the evaluation results using the APIs
function Get-AITSuiteEvaluationResult {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Int32] $SuiteLineNo,
        [Int32] $TestRunVersion,
        [string] $TestState
    )

    return TestRunnerInternalForAIT\Get-AITSuiteEvaluationResultInternal -SuiteCode $SuiteCode -SuiteLineNo $SuiteLineNo -TestRunVersion $TestRunVersion -TestState $TestState
}

# Prerequisite: Initialize the Module
# Get the test method lines using the APIs
function Get-AITSuiteTestMethodLines {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Int32] $TestRunVersion,
        [Int32] $CodeunitId,
        [string] $CodeunitName,
        [string] $TestStatus
    )

    return TestRunnerInternalForAIT\Get-AITSuiteTestMethodLinesInternal -SuiteCode $SuiteCode -TestRunVersion $TestRunVersion -CodeunitId $CodeunitId -CodeunitName $CodeunitName -TestStatus $TestStatus
}

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot 'Internal\TestRunnerInternalForAIT.psm1') -Force -Scope Local

Export-ModuleMember -Function Initialize-Module, Invoke-AITTests, Set-InputDataset, Set-SuiteDefinition, Get-AITSuiteTestResult, Get-AITSuiteEvaluationResult, Get-AITSuiteTestMethodLines