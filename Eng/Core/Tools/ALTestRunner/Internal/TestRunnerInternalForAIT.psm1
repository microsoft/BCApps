<#
    Function to initialize the test runner with the necessary parameters. The parameters are mainly used to open the connection to the client session. The parameters are saved as script variables for further use.
    This functions needs to be called before any other functions in this module.
#>
function Initialize-TestRunner(
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
    [int] $ClientSessionTimeout = $script:DefaultClientSessionTimeout,
    [int] $TransactionTimeout = $script:DefaultTransactionTimeout.TotalMinutes,
    [string] $Culture = $script:DefaultCulture
) {
    Write-HostWithTimestamp "Initializing the AI Test Runner module..."

    $script:DisableSSLVerification = $DisableSSLVerification

    # Reset the script variables
    $script:Environment = ''
    $script:AuthorizationType = ''
    $script:EnvironmentName = ''
    $script:ClientId = ''
    $script:ServiceUrl = ''
    $script:APIHost = ''

    $script:CompanyId = $CompanyId
    

    # If -Environment is not specified then pick the default
    if ($Environment -eq '') {
        Write-Host "-Environment parameter is not provided. Defaulting to $script:DefaultEnvironment"

        $script:Environment = $script:DefaultEnvironment
    }
    else {
        $script:Environment = $Environment
    }

    # Depending on the Environment make sure necessary parameters are also specified
    switch ($script:Environment) {
        # PROD works only with AAD authorizatin type and OnPrem works on all 3 Authorization types
        'PROD' {
            if ($AuthorizationType -ne 'AAD') {
                throw "Only Authorization type 'AAD' can work in -Environment $Environment."
            }
            else {
                if ($AuthorizationType -eq '') {
                    Write-Host "-AuthorizationType parameter is not provided. Defaulting to $script:DefaultAuthorizationType"
                    $script:AuthorizationType = $script:DefaultAuthorizationType
                }
                else {
                    $script:AuthorizationType = $AuthorizationType
                }
            }

            if ($EnvironmentName -eq '') {
                Write-Host "-EnvironmentName parameter is not provided. Defaulting to $script:DefaultEnvironmentName"
                $script:EnvironmentName = $script:DefaultEnvironmentName
            }
            else {
                $script:EnvironmentName = $EnvironmentName
            }

            if ($ClientId -eq '') {
                Write-Error -Category InvalidArgument -Message 'ClientId is mandatory in the PROD environment'
            }
            else {
                $script:ClientId = $ClientId
            }
            if ($RedirectUri -eq '') {
                Write-Host "-RedirectUri parameter is not provided. Defaulting to $script:DefaultRedirectUri"
                $script:RedirectUri = $script:DefaultRedirectUri
            }
            else {
                $script:RedirectUri = $RedirectUri
            }
            if ($AadTenantId -eq '') {
                Write-Error -Category InvalidArgument -Message 'AadTenantId is mandatory in the PROD environment'
            }
            else {
                $script:AadTenantId = $AadTenantId
            }

            $script:AadTokenProvider = [AadTokenProvider]::new($script:AadTenantId, $script:ClientId, $script:RedirectUri)
            
            if (!$script:AadTokenProvider) {
                $example = @'

    $UserName = 'USERNAME'
    $Password = 'PASSWORD'
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $UserCredential = New-Object System.Management.Automation.PSCredential($UserName, $securePassword)

    $script:AADTenantID = 'Guid like - 212415e1-054e-401b-ad32-3cdfa301b1d2'
    $script:ClientId = 'Guid like 0a576aea-5e61-4153-8639-4c5fd5e7d1f6'
    $script:RedirectUri = 'https://login.microsoftonline.com/common/oauth2/nativeclient'
    $global:AadTokenProvider = [AadTokenProvider]::new($script:AADTenantID, $script:ClientId, $scrit:RedirectUri)
'@
                throw 'You need to initialize and set the $global:AadTokenProvider. Example: ' + $example
            }
            $tenantDomain = ''
            if ($Token -ne $null) {
                $tenantDomain = ($Token.UserName.Substring($Token.UserName.IndexOf('@') + 1))
            }
            else {
                $tenantDomain = ($Credential.UserName.Substring($Credential.UserName.IndexOf('@') + 1))
            }
            $script:discoveryUrl = "https://businesscentral.dynamics.com/$tenantDomain/$EnvironmentName/deployment/url"

            if ($ServiceUrl -eq '') {
                $script:ServiceUrl = Get-SaaSServiceURL
                Write-Host "ServiceUrl is not provided. Defaulting to $script:ServiceUrl"
            }
            else {
                $script:ServiceUrl = $ServiceUrl
            }

            if ($APIHost -eq '') {
                $script:APIHost = $script:DefaultSaaSAPIHost + '/' + $script:EnvironmentName
                Write-Host "APIHost is not provided. Defaulting to $script:APIHost"
            }
            else {
                $script:APIHost = $APIHost
            }
        }
        'OnPrem' {
            if ($AuthorizationType -eq '') {
                Write-Host "-AuthorizationType parameter is not provided. Defaulting to $script:DefaultAuthorizationType"
                $script:AuthorizationType = $script:DefaultAuthorizationType
            }
            else {
                $script:AuthorizationType = $AuthorizationType
            }

            # OnPrem, -ServiceUrl should be provided else default is selected. On other environments, the Service Urls are built
            if ($ServiceUrl -eq '') {
                Write-Host "Valid ServiceUrl is not provided. Defaulting to $script:DefaultServiceUrl"
                $script:ServiceUrl = $script:DefaultServiceUrl
            }
            else {
                $script:ServiceUrl = $ServiceUrl
            }

            if ($ServerInstance -eq '') {
                Write-Host "ServerInstance is not provided. Defaulting to $script:DefaultServerInstance"
                $script:ServerInstance = $script:DefaultServerInstance
            }
            else {
                $script:ServerInstance = $ServerInstance
            }

            if ($APIHost -eq '') {
                $script:APIHost = $script:DefaultOnPremAPIHost + '/' + "Navision_" + $script:ServerInstance
                Write-Host "APIHost is not provided. Defaulting to $script:APIHost"
            }
            else {
                $script:APIHost = $APIHost
            }
            
            $script:Tenant = GetTenantFromServiceUrl -Uri $script:ServiceUrl
        }
    }

    switch ($script:AuthorizationType) {
        # -Credential or -Token should be specified if authorization type is AAD.
        "AAD" {
            if ($null -eq $Credential -and $Token -eq $null) {
                throw "Parameter -Credential or -Token should be defined when selecting 'AAD' authorization type."
            }
            if ($null -ne $Credential -and $Token -ne $null) {
                throw "Specify only one parameter -Credential or -Token when selecting 'AAD' authorization type."
            }
        }
        # -Credential should be specified if authorization type is NavUserPassword.
        "NavUserPassword" {
            if ($null -eq $Credential) {
                throw "Parameter -Credential should be defined when selecting 'NavUserPassword' authorization type."
            }
        }
        "Windows" {
            if ($null -ne $Credential) {
                throw "Parameter -Credential should not be defined when selecting 'Windows' authorization type."
            }
        }
    }
    
    $script:Credential = $Credential
    $script:ClientSessionTimeout = $ClientSessionTimeout
    $script:TransactionTimeout = [timespan]::FromMinutes($TransactionTimeout);
    $script:Culture = $Culture;

    Test-AITestToolkitConnection
}

function GetTenantFromServiceUrl([Uri]$Uri)
{
    # Extract the query string part of the URI
    $queryString = [Uri]$Uri -replace '.*\?', ''
    $params = @{}
    
    $queryString -split '&' | ForEach-Object {  
        if ($_ -match '([^=]+)=(.*)') { 
            $params[$matches[1]] = $matches[2] 
        }  
    }

    if($params['tenant'])
    {
        return $params['tenant']
    } 
    
    return 'default'    
}

# Test the connection to the AI Test Toolkit
function Test-AITestToolkitConnection {
    try {
        Write-HostWithTimestamp "Testing the connection to the AI Test Toolkit..."

        $clientContext = Open-ClientSessionWithWait -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -Credential $script:Credential -ServiceUrl $script:ServiceUrl -ClientSessionTimeout $script:ClientSessionTimeout -TransactionTimeout $script:TransactionTimeout -Culture $script:Culture
        
        Write-HostWithTimestamp "Opening the Test Form $script:TestRunnerPage"
        $form = Open-TestForm -TestPage $script:TestRunnerPage -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -ClientContext $clientContext

        # There will be an exception if the form is not opened
        Write-HostWithTimestamp "Successfully opened the Test Form $script:TestRunnerPage" -ForegroundColor Green

        $clientContext.CloseForm($form)

        # Check API connection
        $APIEndpoint = Get-DefaultAPIEndpointForAITLogEntries

        Write-HostWithTimestamp "Testing the connection to the AI Test Toolkit Log Entries API: $APIEndpoint"
        Invoke-BCRestMethod -Uri $APIEndpoint
        Write-HostWithTimestamp "Successfully connected to the AI Test Toolkit Log Entries API" -ForegroundColor Green

        $APIEndpoint = Get-DefaultAPIEndpointForAITTestMethodLines

        Write-HostWithTimestamp "Testing the connection to the AI Test Toolkit Test Method Lines API: $APIEndpoint"
        Invoke-BCRestMethod -Uri $APIEndpoint
        Write-HostWithTimestamp "Successfully connected to the AI Test Toolkit Test Method Lines API" -ForegroundColor Green
    }
    catch {
        $scriptArgs = @{
            AuthorizationType    = $script:AuthorizationType
            ServiceUrl           = $script:ServiceUrl
            APIHost              = $script:APIHost
            ClientSessionTimeout = $script:ClientSessionTimeout
            TransactionTimeout   = $script:TransactionTimeout
            Culture              = $script:Culture
            TestRunnerPage       = $script:TestRunnerPage
            APIEndpoint          = $script:APIEndpoint
        }
        Write-HostWithTimestamp "Exception occurred. Script arguments: $($scriptArgs | Out-String)"
        throw $_.Exception.Message
    }
    finally {
        if ($clientContext) {
            $clientContext.Dispose()
        }
    }     
}

# Reset the test suite pending tests
function Reset-AITTestSuite {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [int] $ClientSessionTimeout = $script:ClientSessionTimeout,
        [timespan] $TransactionTimeout = $script:TransactionTimeout
    )

    try {
        Write-HostWithTimestamp "Opening test runner page: $script:TestRunnerPage"

        $clientContext = Open-ClientSessionWithWait -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -Credential $script:Credential -ServiceUrl $script:ServiceUrl -ClientSessionTimeout $ClientSessionTimeout -TransactionTimeout $TransactionTimeout -Culture $script:Culture

        $form = Open-TestForm -TestPage $script:TestRunnerPage -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -ClientContext $clientContext        

        $SelectSuiteControl = $clientContext.GetControlByName($form, "AIT Suite Code")        
        $clientContext.SaveValue($SelectSuiteControl, $SuiteCode);        

        Write-HostWithTimestamp "Resetting the test suite $SuiteCode"

        $ResetAction = $clientContext.GetActionByName($form, "ResetTestSuite")
        $clientContext.InvokeAction($ResetAction)
    }
    finally {
        if ($clientContext) {
            $clientContext.Dispose()
        }
    }
}

# Invoke the AI Test Suite
function Invoke-AITSuite
(
    [Parameter(Mandatory = $true)]
    [string] $SuiteCode,
    [string] $SuiteLineNo,
    [string] $AgentTaskLogFolder,
    [int] $ClientSessionTimeout = $script:ClientSessionTimeout,
    [timespan] $TransactionTimeout = $script:TransactionTimeout
) {
    $NoOfPendingTests = 0
    $TestResult = @()
    do {
        try {
            Write-HostWithTimestamp "Opening test runner page: $script:TestRunnerPage"

            $clientContext = Open-ClientSessionWithWait -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -Credential $script:Credential -ServiceUrl $script:ServiceUrl -ClientSessionTimeout $ClientSessionTimeout -TransactionTimeout $TransactionTimeout -Culture $script:Culture

            $form = Open-TestForm -TestPage $script:TestRunnerPage -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -ClientContext $clientContext            

            $SelectSuiteControl = $clientContext.GetControlByName($form, "AIT Suite Code")            
            $clientContext.SaveValue($SelectSuiteControl, $SuiteCode);            

            $LanguageTagControl = $clientContext.GetControlByName($form, "Language Tag")
            $clientContext.SaveValue($LanguageTagControl, $script:Culture);

            if ($SuiteLineNo -ne '') {
                $SelectSuiteLineControl = $clientContext.GetControlByName($form, "Line No. Filter")
                $clientContext.SaveValue($SelectSuiteLineControl, $SuiteLineNo);
            }

            Invoke-NextTest -SuiteCode $SuiteCode -ClientContext $clientContext -Form $form

            # Get the results for the last run
            $TestResult += Get-AITSuiteTestResultInternal -SuiteCode $SuiteCode -TestRunVersion 0 | ConvertFrom-Json            

            $NoOfPendingTests = $clientContext.GetControlByName($form, "No. of Pending Tests")
            $NoOfPendingTests = [int] $NoOfPendingTests.StringValue

            if ($AgentTaskLogFolder) {
                Export-AgentTaskLogs -SuiteCode $SuiteCode -AgentTaskLogFolder $AgentTaskLogFolder -ClientContext $clientContext -Form $form
            }
        }
        catch {
            $stackTraceText = $_.Exception.StackTrace + "Script stack trace: " + $_.ScriptStackTrace 
            $testResultError = @(
                @{
                    aitCode        = $SuiteCode
                    status         = "Error"
                    message        = $_.Exception.Message
                    errorCallStack = $stackTraceText
                    endTime        = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ")
                }
            )
            $TestResult += $testResultError
        }
        finally {
            if ($clientContext) {
                $clientContext.Dispose()
            }
        }
    }
    until ($NoOfPendingTests -eq 0)
    return $TestResult
}

function Export-AgentTaskLogs {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Parameter(Mandatory = $true)]
        [string] $AgentTaskLogFolder,
        [Parameter(Mandatory = $true)]
        [ClientContext] $ClientContext,
        [Parameter(Mandatory = $true)]
        [ClientLogicalForm] $Form
    )

    Write-HostWithTimestamp "Loading Agent Task logs for suite $SuiteCode"
    $LoadAgentTaskLogsAction = $ClientContext.GetActionByName($Form, "LoadAgentTaskLogs")
    New-Item -ItemType Directory -Force -Path $AgentTaskLogFolder | Out-Null
    while ($true) {
        $ClientContext.InvokeAction($LoadAgentTaskLogsAction)
        $AgentTaskLogText = $ClientContext.GetControlByName($Form, "Agent Task Log").StringValue
        if ($AgentTaskLogText -eq 'No more Agent Task logs.') {
            break
        }
        if ([string]::IsNullOrWhiteSpace($AgentTaskLogText)) {
            throw "The Agent Task Log field is empty."
        }

        $Version = $ClientContext.GetControlByName($Form, "Agent Task Log Version").StringValue
        $TestLogEntryId = $ClientContext.GetControlByName($Form, "Agent Task Log Entry ID").StringValue
        $AgentTaskId = $ClientContext.GetControlByName($Form, "Agent Task ID").StringValue
        $SafeSuiteCode = $SuiteCode -replace '[^a-zA-Z0-9_-]', '_'
        $FileName = '{0}_v{1}_log{2}_task{3}.json' -f $SafeSuiteCode, $Version, $TestLogEntryId, $AgentTaskId
        $FilePath = Join-Path $AgentTaskLogFolder $FileName
        [System.IO.File]::WriteAllText($FilePath, $AgentTaskLogText, [System.Text.UTF8Encoding]::new($false))
        Write-HostWithTimestamp "Exported Agent Task log to $FilePath"
    }
}

# Run the next test in the suite
function Invoke-NextTest {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [string] $SuiteLineNo,
        [Parameter(Mandatory = $true)]
        [ClientContext] $clientContext,
        [Parameter(Mandatory = $true)]
        [ClientLogicalForm] $form
    )
    $NoOfPendingTests = [int] $clientContext.GetControlByName($form, "No. of Pending Tests").StringValue

    if ($NoOfPendingTests -gt 0) {
        $StartNextAction = $clientContext.GetActionByName($form, "RunNextTest")

        $message = "Starting the next test in the suite $SuiteCode, Number of pending tests: $NoOfPendingTests"
        if ($SuiteLineNo -ne '') {
            $message += ", Filtering the suite line number: $SuiteLineNo"
        }
        Write-HostWithTimestamp $message

        $clientContext.InvokeAction($StartNextAction)
    }
    else {
        throw "There are no tests to run. Try resetting the test suite. Number of pending tests: $NoOfPendingTests"
    }

    $NewNoOfPendingTests = [int] $clientContext.GetControlByName($form, "No. of Pending Tests").StringValue
    if ($NewNoOfPendingTests -eq $NoOfPendingTests) {
        throw "There was an error running the test. Number of pending tests: $NewNoOfPendingTests"
    }
}

# Get Suite Test Result for specified version
# If version is not provided then get the latest version
function Get-AITSuiteTestResultInternal {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Int32] $TestRunVersion,
        [Int32] $CodeunitId,
        [string] $CodeunitName,
        [string] $TestStatus,
        [string] $ProcedureName
    )

    if ($TestRunVersion -lt 0) {
        throw "TestRunVersion should be 0 or greater"
    }
    
    $APIEndpoint = Get-DefaultAPIEndpointForAITLogEntries

    # if AIT suite version is not provided then get the latest version
    if ($TestRunVersion -eq 0) {
        # Odata to sort by version and get all the entries with highest version
        $APIQuery = Build-LogEntryAPIFilter -SuiteCode $SuiteCode -TestRunVersion $TestRunVersion -CodeunitId $CodeunitId -CodeunitName $CodeunitName -TestStatus $TestStatus -ProcedureName $ProcedureName
        $AITVersionAPI = $APIEndpoint + $APIQuery + "&`$orderby=version desc&`$top=1&`$select=version"
        
        Write-HostWithTimestamp "Getting the latest version of the AIT Suite from $AITVersionAPI"
        $AITApiResponse = Invoke-BCRestMethod -Uri $AITVersionAPI
        
        $TestRunVersion = $AITApiResponse.value[0].version
    }

    $APIQuery = Build-LogEntryAPIFilter -SuiteCode $SuiteCode -TestRunVersion $TestRunVersion -CodeunitId $CodeunitId -CodeunitName $CodeunitName -TestStatus $TestStatus -ProcedureName $ProcedureName
    $AITLogEntryAPI = $APIEndpoint + $APIQuery

    Write-HostWithTimestamp "Getting the AIT Suite Test Results from $AITLogEntryAPI"
    $AITLogEntries = Invoke-BCRestMethod -Uri $AITLogEntryAPI

    # Convert the response to JSON
    
    $AITLogEntriesJson = $AITLogEntries.value | ConvertTo-Json -Depth 100 -AsArray
    return $AITLogEntriesJson
}


# Get Suite Test Result for specified version
# If version is not provided then get the latest version
function Get-AITSuiteEvaluationResultInternal {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Int32] $SuiteLineNo,
        [Int32] $TestRunVersion,
        [string] $TestState
    )

    if ($TestRunVersion -lt 0) {
        throw "TestRunVersion should be 0 or greater"
    }
    
    $APIEndpoint = Get-DefaultAPIEndpointForAITEvaluationLogEntries

    Write-Host "Getting the AIT Suite Evaluation Results for Suite Code: $SuiteCode, Suite Line No: $SuiteLineNo, Test Run Version: $TestRunVersion, Test State: $TestState"

    # if AIT suite version is not provided then get the latest version
    if ($TestRunVersion -eq 0) {
        # Odata to sort by version and get all the entries with highest version
        $APIQuery = Build-LogEvaluationEntryAPIFilter -SuiteCode $SuiteCode -TestRunVersion $TestRunVersion -SuiteLineNo $SuiteLineNo -TestState $TestState
        $AITVersionAPI = $APIEndpoint + $APIQuery + "&`$orderby=version desc&`$top=1&`$select=version"
        
        Write-HostWithTimestamp "Getting the latest version of the AIT Suite from $AITVersionAPI"
        $AITApiResponse = Invoke-BCRestMethod -Uri $AITVersionAPI
        
        $TestRunVersion = $AITApiResponse.value[0].version
    }

    $APIQuery = Build-LogEvaluationEntryAPIFilter -SuiteCode $SuiteCode -TestRunVersion $TestRunVersion -SuiteLineNo $SuiteLineNo -TestState $TestState
    $AITEvaluationLogEntryAPI = $APIEndpoint + $APIQuery

    Write-HostWithTimestamp "Getting the AIT Suite Evaluation Results from $AITEvaluationLogEntryAPI"
    $AITEvaluationLogEntries = Invoke-BCRestMethod -Uri $AITEvaluationLogEntryAPI

    # Convert the response to JSON
    $AITEvaluationLogEntriesJson = $AITEvaluationLogEntries.value | ConvertTo-Json -Depth 100 -AsArray
    return $AITEvaluationLogEntriesJson
}

# Get Test Method Lines for a Suite
function Get-AITSuiteTestMethodLinesInternal {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Int32] $TestRunVersion,
        [Int32] $CodeunitId,
        [string] $CodeunitName,
        [string] $TestStatus,
        [string] $ProcedureName
    )

    if ($TestRunVersion -lt 0) {
        throw "TestRunVersion should be 0 or greater"
    }
    
    $APIEndpoint = Get-DefaultAPIEndpointForAITTestMethodLines

    $APIQuery = Build-TestMethodLineAPIFilter -SuiteCode $SuiteCode -TestRunVersion $TestRunVersion -CodeunitId $CodeunitId -CodeunitName $CodeunitName -TestStatus $TestStatus
    $AITTestMethodLinesAPI = $APIEndpoint + $APIQuery

    Write-HostWithTimestamp "Getting the Test Method Lines from $AITTestMethodLinesAPI"
    $AITTestMethodLines = Invoke-BCRestMethod -Uri $AITTestMethodLinesAPI

    # Convert the response to JSON
    $AITTestMethodLinesJson = $AITTestMethodLines.value | ConvertTo-Json
    return $AITTestMethodLinesJson
}

function Get-DefaultAPIEndpointForAITLogEntries {
    $CompanyPath = ''
    if ($script:CompanyId -ne [guid]::Empty -and $null -ne $script:CompanyId) {
        $CompanyPath = '/companies(' + $script:CompanyId + ')'
    }
    
    $TenantParam = ''
    if($script:Tenant)
    {
        $TenantParam = "tenant=$script:Tenant&"
    }
    $APIEndpoint = "$script:APIHost/api/microsoft/aiTestToolkit/v2.0$CompanyPath/aitTestLogEntries?$TenantParam"
    Write-Host "APIEndpoint: $APIEndpoint"

    return $APIEndpoint
}

function Get-DefaultAPIEndpointForAITTestMethodLines {
    $CompanyPath = ''
    if ($script:CompanyId -ne [guid]::Empty -and $null -ne $script:CompanyId) {
        $CompanyPath = '/companies(' + $script:CompanyId + ')'
    }

    $TenantParam = ''
    if($script:Tenant)
    {
        $TenantParam = "tenant=$script:Tenant&"
    }

    $APIEndpoint = "$script:APIHost/api/microsoft/aiTestToolkit/v2.0$CompanyPath/aitTestMethodLines?$TenantParam"

    return $APIEndpoint
}

function Get-DefaultAPIEndpointForAITEvaluationLogEntries {
    $CompanyPath = ''
    if ($script:CompanyId -ne [guid]::Empty -and $null -ne $script:CompanyId) {
        $CompanyPath = '/companies(' + $script:CompanyId + ')'
    }
    
    $TenantParam = ''
    if($script:Tenant)
    {
        $TenantParam = "tenant=$script:Tenant&"
    }
    $APIEndpoint = "$script:APIHost/api/microsoft/aiTestToolkit/v2.0$CompanyPath/aitEvaluationLogEntries?$TenantParam"
    Write-Host "APIEndpoint: $APIEndpoint"

    return $APIEndpoint
}

function Build-LogEntryAPIFilter() {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Int32] $TestRunVersion,
        [Int32] $CodeunitId,
        [string] $CodeunitName,
        [string] $TestStatus,
        [string] $ProcedureName
    )

    $filter = "`$filter=aitCode eq '" + $SuiteCode + "'"
    if ($TestRunVersion -ne 0) {
        $filter += " and version eq " + $TestRunVersion
    }
    if ($CodeunitId -ne 0) {
        $filter += " and codeunitId eq " + $CodeunitId
    }
    if ($CodeunitName -ne '') {
        $filter += " and codeunitName eq '" + $CodeunitName + "'"
    }
    if ($TestStatus -ne '') {
        $filter += " and status eq '" + $TestStatus + "'"
    }
    if ($ProcedureName -ne '') {
        $filter += " and procedureName eq '" + $ProcedureName + "'"
    }

    return $filter
}

function Build-TestMethodLineAPIFilter() {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Int32] $TestRunVersion,
        [Int32] $CodeunitId,
        [string] $CodeunitName,
        [string] $TestStatus,
        [string] $ProcedureName
    )

    $filter = "`$filter=aitCode eq '" + $SuiteCode + "'"
    if ($TestRunVersion -ne 0) {
        $filter += " and version eq " + $TestRunVersion
    }
    if ($CodeunitId -ne 0) {
        $filter += " and codeunitId eq " + $CodeunitId
    }
    if ($CodeunitName -ne '') {
        $filter += " and codeunitName eq '" + $CodeunitName + "'"
    }
    if ($TestStatus -ne '') {
        $filter += " and status eq '" + $TestStatus + "'"
    }

    return $filter
}

function Build-LogEvaluationEntryAPIFilter() {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SuiteCode,
        [Int32] $SuiteLineNo,
        [Int32] $TestRunVersion,
        [string] $TestState
    )

    $filter = "`$filter=aitCode eq '" + $SuiteCode + "'"
    if ($TestRunVersion -ne 0) {
        $filter += " and version eq " + $TestRunVersion
    }
    if ($SuiteLineNo -ne 0) {
        $filter += " and aitTestMethodLineNo eq " + $SuiteLineNo
    }
    if ($TestState -ne '') {
        $filter += " and state eq '" + $TestState + "'"
    }

    return $filter
}

# Upload the input dataset needed to run the AI Test Suite
function Set-InputDatasetInternal {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InputDatasetFilename,
        [Parameter(Mandatory = $true)]
        [string] $InputDataset,
        [int] $ClientSessionTimeout = $script:ClientSessionTimeout,
        [timespan] $TransactionTimeout = $script:TransactionTimeout
    )
    try {
        $clientContext = Open-ClientSessionWithWait -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -Credential $script:Credential -ServiceUrl $script:ServiceUrl -ClientSessionTimeout $ClientSessionTimeout -TransactionTimeout $TransactionTimeout -Culture $script:Culture

        $form = Open-TestForm -TestPage $script:TestRunnerPage -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -ClientContext $clientContext

        $SelectSuiteControl = $clientContext.GetControlByName($form, "Input Dataset Filename")
        $clientContext.SaveValue($SelectSuiteControl, $InputDatasetFilename);
        
        Write-HostWithTimestamp "Uploading the Input Dataset $InputDatasetFilename"

        $SelectSuiteControl = $clientContext.GetControlByName($form, "Input Dataset")
        $clientContext.SaveValue($SelectSuiteControl, $InputDataset);

        $validationResultsError = Get-FormError($form)
        if ($validationResultsError.Count -gt 0) {
            Write-HostWithTimestamp "There is an error uploading the Input Dataset: $InputDatasetFilename" -ForegroundColor Red
            Write-HostWithTimestamp $validationResultsError -ForegroundColor Red
        }

        $clientContext.CloseForm($form)
    }
    finally {
        if ($clientContext) {
            $clientContext.Dispose()
        }
    }     
}

#Upload the XML test suite definition needed to setup the AI Test Suite
function  Set-SuiteDefinitionInternal {
    param (
        [Parameter(Mandatory = $true)]
        [xml] $SuiteDefinition,
        [int] $ClientSessionTimeout = $script:ClientSessionTimeout,
        [timespan] $TransactionTimeout = $script:TransactionTimeout
    )
    try {
        $clientContext = Open-ClientSessionWithWait -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -Credential $script:Credential -ServiceUrl $script:ServiceUrl -ClientSessionTimeout $ClientSessionTimeout -TransactionTimeout $TransactionTimeout -Culture $script:Culture

        $form = Open-TestForm -TestPage $script:TestRunnerPage -DisableSSLVerification:$script:DisableSSLVerification -AuthorizationType $script:AuthorizationType -ClientContext $clientContext

        Write-HostWithTimestamp "Uploading the Suite Definition"
        $SelectSuiteControl = $clientContext.GetControlByName($form, "Suite Definition")
        $clientContext.SaveValue($SelectSuiteControl, $SuiteDefinition.OuterXml);
        
        # Check if the suite definition is set correctly
        $validationResultsError = Get-FormError($form)
        if ($validationResultsError.Count -gt 0) {
            throw $validationResultsError
        }
        $clientContext.CloseForm($form)
    }
    catch {
        Write-HostWithTimestamp "`There is an error uploading the Suite Definition. Please check the Suite Definition XML:`n $($SuiteDefinition.OuterXml)" -ForegroundColor Red
        if ($validationResultsError.Count -gt 0) {
            throw $_.Exception.Message
        }
        else {
            throw $_.Exception
        }
    }
    finally {
        if ($clientContext) {
            $clientContext.Dispose()
        }
    }
}

function Get-FormError {
    param (
        [ClientLogicalForm]
        $form
    )
    if ($form.HasValidatonResults -eq $true) {
        $validationResults = $form.ValidationResults
        $validationResultsError = @()
        foreach ($validationResult in $validationResults | Where-Object { $_.Severity -eq "Error" }) {
            $validationResultsError += "TestPage: $script:TestRunnerPage, Status: Error, Message: $($validationResult.Description), ErrorCallStack: $(Get-PSCallStack)"
        }
        return ($validationResultsError -join "`n")
    }  
}

function Invoke-BCRestMethod {
    param (
        [string]$Uri
    )
    switch ($script:AuthorizationType) {
        "Windows" {
            Invoke-RestMethod -Uri $Uri -Method Get -ContentType "application/json" -UseDefaultCredentials -AllowUnencryptedAuthentication
        }
        "NavUserPassword" {
            Invoke-RestMethod -Uri $Uri -Method Get -ContentType "application/json" -Credential $script:Credential -AllowUnencryptedAuthentication
        }
        "AAD" {
            $script:AadTokenProvider
            if ($null -ne $script:AadTokenProvider) {
                throw "You need to specify the AadTokenProvider for obtaining the token if using AAD authentication"
            }

            $token = $AadTokenProvider.GetToken($Credential)
            $headers = @{
                Authorization = "Bearer $token"
                Accept        = "application/json"
            }
            return Invoke-RestMethod -Uri $Uri -Method Get -Headers $headers
        }
        default {
            Write-Error "Invalid authentication type specified. Use 'Windows', 'UserPassword', or 'AAD'."
        }
    }
}

function Write-HostWithTimestamp {
    param (
        [string] $Message
    )
    Write-Host "[$($script:Tenant) $(Get-Date)] $Message"
}

$script:DefaultEnvironment = "OnPrem"
$script:DefaultAuthorizationType = 'Windows'
$script:DefaultEnvironmentName = "sandbox"
$script:DefaultServiceUrl = 'http://localhost:48900'
$script:DefaultRedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
$script:DefaultOnPremAPIHost = "http://localhost:7047"
$script:DefaultSaaSAPIHost = "https://api.businesscentral.dynamics.com/v2.0"
$script:DefaultServerInstance = "NAV"
$script:DefaultClientSessionTimeout = 60;
$script:DefaultTransactionTimeout = [timespan]::FromMinutes(60);
$script:DefaultCulture = "en-US";

$script:TestRunnerPage = '149042'
$script:ClientAssembly1 = "Microsoft.Dynamics.Framework.UI.Client.dll"
$script:ClientAssembly2 = "NewtonSoft.Json.dll"
$script:ClientAssembly3 = "Microsoft.Internal.AntiSSRF.dll"

if (!$script:TypesLoaded) {
    Add-type -Path "$PSScriptRoot\Microsoft.Dynamics.Framework.UI.Client.dll"
    Add-type -Path "$PSScriptRoot\NewtonSoft.Json.dll"
    Add-type -Path "$PSScriptRoot\Microsoft.Internal.AntiSSRF.dll"

    $alTestRunnerInternalPath = Join-Path $PSScriptRoot "ALTestRunnerInternal.psm1"
    Import-Module "$alTestRunnerInternalPath"

    $clientContextScriptPath = Join-Path $PSScriptRoot "ClientContext.ps1"
    . "$clientContextScriptPath"
    
    $aadTokenProviderScriptPath = Join-Path $PSScriptRoot "AadTokenProvider.ps1"
    . "$aadTokenProviderScriptPath"
}
$script:TypesLoaded = $true;

$ErrorActionPreference = "Stop"
$script:AadTokenProvider = $null
$script:Credential = $null

Export-ModuleMember -Function Initialize-TestRunner, Reset-AITTestSuite, Invoke-AITSuite, Set-InputDatasetInternal, Set-SuiteDefinitionInternal, Get-AITSuiteTestResultInternal, Get-AITSuiteEvaluationResultInternal, Get-AITSuiteTestMethodLinesInternal
