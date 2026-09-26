[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $ClusterUri,

    [Parameter(Mandatory = $true)]
    [string] $Database,

    [Parameter(Mandatory = $true)]
    [string] $Table,

    [Parameter(Mandatory = $true)]
    [ValidateSet('IMPLEMENTATION_STARTED', 'PR_CREATED', 'PR_MERGED', 'PR_CLOSED_UNMERGED', 'ERROR')]
    [string] $Tag,

    [Parameter(Mandatory = $true)]
    [string] $RunId,

    [Parameter(Mandatory = $true)]
    [long] $IssueNumber,

    [Parameter(Mandatory = $true)]
    [string] $Repository,

    [Parameter(Mandatory = $true)]
    [string] $IssueUrl,

    [string] $BatchId = '',
    [string] $Model = '',
    [long] $PullRequestNumber = 0,
    [string] $PullRequestUrl = '',
    [string] $PullRequestState = '',
    [string] $HeadBranch = '',
    [bool] $IsDraft = $false,
    [string] $MergeCommitSha = '',
    [long] $CommitCount = 0,
    [string] $FailureMessage = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

function ConvertTo-KustoString {
    param([AllowEmptyString()][string] $Value)

    return $Value.Replace("'", "''").Replace("`r`n", '\n').Replace("`n", '\n').Replace("`r", '\n')
}

function Get-KustoAccessToken {
    param([Parameter(Mandatory = $true)][string] $Resource)

    $token = az account get-access-token `
        --resource $Resource `
        --query accessToken `
        --output tsv 2>&1
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace("$token")) {
        return "$token"
    }

    $requiredValues = @(
        $env:ACTIONS_ID_TOKEN_REQUEST_URL,
        $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN,
        $env:EXT_REQ_AZURE_CLIENT_ID,
        $env:EXT_REQ_AZURE_TENANT_ID,
        $env:EXT_REQ_AZURE_SUBSCRIPTION_ID
    )
    if ($requiredValues | Where-Object { [string]::IsNullOrWhiteSpace($_) }) {
        throw "Unable to acquire a Kusto access token: $token"
    }

    $audience = [Uri]::EscapeDataString('api://AzureADTokenExchange')
    $separator = if ($env:ACTIONS_ID_TOKEN_REQUEST_URL.Contains('?')) { '&' } else { '?' }
    $oidcResponse = Invoke-RestMethod `
        -Method Get `
        -Uri "$($env:ACTIONS_ID_TOKEN_REQUEST_URL)${separator}audience=$audience" `
        -Headers @{ Authorization = "Bearer $($env:ACTIONS_ID_TOKEN_REQUEST_TOKEN)" }

    $loginOutput = az login `
        --service-principal `
        --username $env:EXT_REQ_AZURE_CLIENT_ID `
        --tenant $env:EXT_REQ_AZURE_TENANT_ID `
        --federated-token $oidcResponse.value `
        --allow-no-subscriptions `
        --output none 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to refresh the Azure OIDC login: $loginOutput"
    }

    $accountOutput = az account set `
        --subscription $env:EXT_REQ_AZURE_SUBSCRIPTION_ID 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to select the Azure subscription after refreshing OIDC: $accountOutput"
    }

    $token = az account get-access-token `
        --resource $Resource `
        --query accessToken `
        --output tsv 2>&1
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace("$token")) {
        throw "Unable to acquire a Kusto access token after refreshing OIDC: $token"
    }

    return "$token"
}

try {
    if ($Table -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
        throw "Kusto table name '$Table' is invalid."
    }

    $parsedUri = $null
    if (-not [Uri]::TryCreate($ClusterUri, [UriKind]::Absolute, [ref] $parsedUri) -or
        $parsedUri.Scheme -ne 'https') {
        throw 'Kusto cluster URI must be an absolute HTTPS URI.'
    }

    $cluster = $ClusterUri.TrimEnd('/')
    $token = Get-KustoAccessToken -Resource $cluster

    $timestamp = [DateTime]::UtcNow.ToString('o')
    $csl = ".set-or-append $Table with (extend_schema=true) <| print " +
        "Timestamp=datetime('$timestamp'), " +
        "Tag='$(ConvertTo-KustoString $Tag)', " +
        "RunId='$(ConvertTo-KustoString $RunId)', " +
        "Repository='$(ConvertTo-KustoString $Repository)', " +
        "IssueNumber=long($IssueNumber), " +
        "IssueUrl='$(ConvertTo-KustoString $IssueUrl)', " +
        "Model='$(ConvertTo-KustoString $Model)', " +
        "PullRequestNumber=long($PullRequestNumber), " +
        "PullRequestUrl='$(ConvertTo-KustoString $PullRequestUrl)', " +
        "PullRequestState='$(ConvertTo-KustoString $PullRequestState)', " +
        "HeadBranch='$(ConvertTo-KustoString $HeadBranch)', " +
        "IsDraft=bool($($IsDraft.ToString().ToLowerInvariant())), " +
        "MergeCommitSha='$(ConvertTo-KustoString $MergeCommitSha)', " +
        "CommitCount=long($CommitCount), " +
        "FailureReason='$(ConvertTo-KustoString $FailureMessage)', " +
        "BatchId='$(ConvertTo-KustoString $BatchId)'"

    $body = @{
        db = $Database
        csl = $csl
    } | ConvertTo-Json -Compress

    $headers = @{
        Authorization = "Bearer $token"
        'x-ms-client-request-id' = "bc-extrequest-implement;$([guid]::NewGuid())"
    }

    Invoke-RestMethod `
        -Method Post `
        -Uri "$cluster/v1/rest/mgmt" `
        -Headers $headers `
        -ContentType 'application/json; charset=utf-8' `
        -Body $body | Out-Null

    Write-Host "Telemetry sent: $Tag for issue #$IssueNumber."
} catch {
    Write-Warning "Telemetry was not sent: $($_.Exception.Message)"
} finally {
    $global:LASTEXITCODE = 0
}
