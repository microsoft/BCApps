<#
.SYNOPSIS
    Correlates clean-codeunit HTTP failures with NST SQL-pool exceptions.
.DESCRIPTION
    This is a manual diagnostic experiment, not a generic HTTP retry or a pool-lifecycle fix.
    Every failed case must have a request CorrelationId matching an NST ClientSessionId,
    a NullReferenceException in AcquireSqlConnectionFromPool, and the observed OData
    metadata stack, within this dispatch's time window. Missing evidence fails closed.
    The scheduler permits only one retry, restores the tenant first, and reruns the entire
    codeunit. Original results and matching events are retained separately from final results.
    The scheduler enables retry only on the exact manual comparison branch, retry arm, attempt one.
    All arms classify and preserve matching first-attempt evidence without authorizing other retries.
    SqlApiRetryEvidence JSON files under the diagnostic output are uploaded with raw outcomes,
    including on successful runs, so recovered failures remain visible without duplicating cases.
#>
function Get-SqlApiRetrySuite {
    param($Context)

    [xml]$document = Get-Content -LiteralPath $Context.ResultFiles.JUnitResultFileName -Raw -ErrorAction Stop
    $suites = @($document.SelectNodes('/testsuites/testsuite') | Where-Object {
        ($_.GetAttribute('name') -split ' ', 2)[0] -eq [string]$Context.CodeunitId
    })
    if ($suites.Count -ne 1) {
        throw "Expected exactly one JUnit suite for codeunit $($Context.CodeunitId), found $($suites.Count)."
    }
    return ,$suites[0]
}

function Get-SqlApiRetryEvents {
    param(
        [string]$ContainerName,
        [datetime]$StartedUtc,
        [datetime]$FinishedUtc
    )

    return @(Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
        param($start, $end)
        try {
            $events = @(Get-WinEvent -FilterHashtable @{
                LogName = 'Application'
                ProviderName = 'MicrosoftDynamicsNavServer*'
                Id = 701
                StartTime = [datetime]::Parse($start).ToUniversalTime()
                EndTime = [datetime]::Parse($end).ToUniversalTime()
            } -MaxEvents 1000 -ErrorAction Stop)
        } catch {
            if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') {
                return
            }
            throw
        }
        foreach ($eventRecord in $events) {
            $eventRecord.ToXml()
        }
    } -argumentList $StartedUtc.ToString('o'), $FinishedUtc.ToString('o'))
}

<#
.SYNOPSIS
    Persists original JUnit and correlated NST events before authorizing one clean-codeunit retry.
#>
function Get-SqlApiTestRetryEvidence {
    param($Context)

    try {
        $suite = Get-SqlApiRetrySuite -Context $Context
        $cases = @($suite.SelectNodes('testcase'))
        if ($cases.Count -ne $Context.TestCount -or $cases.Count -eq 0) {
            throw "Incomplete JUnit codeunit: expected $($Context.TestCount) cases, found $($cases.Count)."
        }
        $failures = @($suite.SelectNodes('testcase/failure'))
        if ($failures.Count -eq 0 -or $suite.SelectNodes('.//error').Count -gt 0) {
            return
        }
        $requestIds = @()
        foreach ($failure in $failures) {
            $message = $failure.GetAttribute('message')
            if ($message -notmatch 'GET request failed\. Response code is 500 \(InternalServerError\)' -or
                $message -notmatch 'Object reference not set to an instance of an object\.' -or
                $message -notmatch 'CorrelationId:\s*([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})(?![0-9a-f-])') {
                return
            }
            $requestIds += $Matches[1]
        }
        # Refuse malformed/partial results rather than overlooking an unrepresented failure.
        foreach ($case in $cases) {
            if ($case.GetAttribute('result') -eq 'Fail' -and $case.SelectNodes('failure').Count -ne 1) {
                return
            }
        }

        $finishedUtc = [datetime]::UtcNow
        $events = @(Get-SqlApiRetryEvents -ContainerName $Context.ContainerName `
            -StartedUtc $Context.StartedUtc -FinishedUtc $finishedUtc)
        $matchedEvents = @()
        foreach ($requestId in $requestIds) {
            $matchesForRequest = @()
            foreach ($eventText in $events) {
                [xml]$eventXml = $eventText
                $ns = [System.Xml.XmlNamespaceManager]::new($eventXml.NameTable)
                $ns.AddNamespace('e', 'http://schemas.microsoft.com/win/2004/08/events/event')
                $system = $eventXml.SelectSingleNode('/e:Event/e:System', $ns)
                $provider = $system.SelectSingleNode('e:Provider', $ns).GetAttribute('Name')
                $eventId = $system.SelectSingleNode('e:EventID', $ns).InnerText
                $time = [datetime]::Parse($system.SelectSingleNode('e:TimeCreated', $ns).GetAttribute('SystemTime')).ToUniversalTime()
                $text = ($eventXml.SelectNodes('/e:Event/e:EventData/e:Data', $ns) |
                    ForEach-Object { $_.InnerText }) -join "`n"
                if ($provider -match '^MicrosoftDynamicsNavServer\$' -and $eventId -eq '701' -and
                    $time -ge $Context.StartedUtc -and $time -le $finishedUtc -and
                    $text -match "(?m)^ClientSessionId:\s*$([regex]::Escape($requestId))\s*$" -and
                    $text -match 'RootException: NullReferenceException' -and
                    $text -match 'at Microsoft\.Dynamics\.Nav\.Runtime\.NavSqlConnectionScope\.AcquireSqlConnectionFromPool\(' -and
                    $text -match 'at Microsoft\.Dynamics\.Nav\.XmlMetadata\.MetadataProvider\.GetRelativeHelpUrl\(' -and
                    $text -match 'at Microsoft\.Dynamics\.Nav\.Service\.OData\.V4\.PageDataProvider\.GetNavRecordDataAsync\(') {
                    $matchesForRequest += [string]$eventText
                }
            }
            if ($matchesForRequest.Count -eq 0) {
                Write-Host "::warning::SQL API retry not eligible: no matching NST event for request '$requestId'."
                return
            }
            $matchedEvents += $matchesForRequest
        }
        $evidence = [PSCustomObject]@{
            ContainerName = $Context.ContainerName
            Tenant = $Context.Tenant
            CodeunitId = $Context.CodeunitId
            StartedUtc = $Context.StartedUtc.ToString('o')
            FinishedUtc = $finishedUtc.ToString('o')
            RequestIds = @($requestIds | Select-Object -Unique)
            OriginalSuite = $suite.OuterXml
            Events = @($matchedEvents | Select-Object -Unique)
            TestCases = @($cases | ForEach-Object {
                [PSCustomObject]@{ Name = $_.GetAttribute('name'); Skipped = ($null -ne $_.SelectSingleNode('skipped')) }
            })
        }
        $folder = Join-Path ([System.IO.Path]::GetDirectoryName($Context.ResultFiles.JUnitResultFileName)) 'SqlApiRetryEvidence'
        if ($Context.PSObject.Properties['OutputDirectory'] -and $Context.OutputDirectory) {
            $folder = Join-Path $Context.OutputDirectory 'SqlApiRetryEvidence'
        }
        $null = New-Item -ItemType Directory -Path $folder -Force -ErrorAction Stop
        $evidenceFile = Join-Path $folder "$($Context.Tenant)-$($Context.CodeunitId)-$([guid]::NewGuid().ToString('N')).json"
        $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $evidenceFile -Encoding utf8 -ErrorAction Stop
        Write-Host "::warning::SQL API pool failure confirmed for codeunit $($Context.CodeunitId) on '$($Context.Tenant)'; requests: $($evidence.RequestIds -join ', '). Original evidence: $evidenceFile. Only the retry arm may authorize a single clean retry."
        return $evidence
    } catch {
        Write-Host "::warning::SQL API retry evidence unavailable; preserving test failure: $($_.Exception.Message)"
        return
    }
}

<#
.SYNOPSIS
    Requires a SQL retry to preserve the original test names and skip status without failures.
#>
function Test-SqlApiRetryResult {
    param(
        $Context,
        [array]$ExpectedTests
    )

    try {
        $suite = Get-SqlApiRetrySuite -Context $Context
        $cases = @($suite.SelectNodes('testcase'))
        if ($cases.Count -ne $ExpectedTests.Count -or $suite.SelectNodes('.//failure | .//error').Count -gt 0) {
            throw 'The retry did not produce a complete, passing codeunit.'
        }
        foreach ($expected in $ExpectedTests) {
            $actual = @($cases | Where-Object { $_.GetAttribute('name') -ceq $expected.Name })
            if ($actual.Count -ne 1 -or
                ($null -ne $actual[0].SelectSingleNode('skipped')) -ne $expected.Skipped -or
                $actual[0].GetAttribute('result') -eq 'Fail') {
                throw "Retry result missing, duplicated, failed or changed skip status for '$($expected.Name)'."
            }
        }
        return $true
    } catch {
        Write-Host "::warning::SQL API retry remains failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-SqlApiExperimentSelection {
    param($Context, [ValidateSet('control', 'warmup', 'retry')][string]$Experiment)
    if ([string]$Context.CodeunitId -ne '148318') { return $true }
    try {
        $suite = Get-SqlApiRetrySuite -Context $Context
        $target = @($suite.SelectNodes('testcase') | Where-Object {
            ($_.GetAttribute('name') -split '\.')[-1] -ceq 'CapabilitiesProjectsEnabledViaAPI'
        })
        if ($target.Count -ne 1) { throw 'Expected exactly one target method in Capabilities results.' }
        if ($null -ne $target[0].SelectSingleNode('skipped')) {
            throw "Target method must remain enabled in $Experiment."
        }
        return $true
    } catch {
        Write-Host "::warning::Experiment selection verification failed: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Get-SqlApiTestRetryEvidence, Test-SqlApiRetryResult, Test-SqlApiExperimentSelection
