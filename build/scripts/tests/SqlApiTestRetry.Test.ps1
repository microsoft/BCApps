Describe 'SQL API bounded retry evidence and result validation' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..\SqlApiTestRetry.psm1') -Force
        $script:createdContainerStub = -not (Get-Command Invoke-ScriptInBcContainer -ListImported -ErrorAction SilentlyContinue)
        if ($script:createdContainerStub) {
            function global:Invoke-ScriptInBcContainer {
                param([string]$containerName, [scriptblock]$scriptblock, [object[]]$argumentList)
                $null = $containerName, $scriptblock, $argumentList
                throw 'Container execution must be mocked.'
            }
        }
        function New-FailureMessage {
            param([string]$CorrelationId = $script:requestId)
            "Assert.Fail failed. GET request failed. Response code is 500 (InternalServerError), expected code is 200. Error code: Unknown. Error message: Object reference not set to an instance of an object. CorrelationId: $CorrelationId."
        }
        function New-CaseXml {
            param([string]$Name, [string]$Message, [switch]$Skipped, [string]$Result = 'Pass')
            $body = ''
            if ($Message) {
                $body = '<failure message="' + [System.Security.SecurityElement]::Escape($Message) + '" />'
                $Result = 'Fail'
            }
            if ($Skipped) { $body += '<skipped />' }
            '<testcase name="' + [System.Security.SecurityElement]::Escape($Name) + '" result="' + $Result + '">' + $body + '</testcase>'
        }
        function Write-Suite {
            param([string[]]$Cases = $script:originalCases)
            '<testsuites><testsuite name="70001 Synthetic API Codeunit" tests="' + $Cases.Count + '">' +
                ($Cases -join '') + '</testsuite></testsuites>' |
                Set-Content -LiteralPath $script:context.ResultFiles.JUnitResultFileName -Encoding utf8
        }
        function New-NstEvent {
            param(
                [string]$CorrelationId = $script:requestId,
                [datetime]$Time = $script:eventTime,
                [string]$Provider = 'MicrosoftDynamicsNavServer$BC',
                [string]$EventId = '701',
                [string]$Stack = "RootException: NullReferenceException`nat Microsoft.Dynamics.Nav.Runtime.NavSqlConnectionScope.AcquireSqlConnectionFromPool(...)`nat Microsoft.Dynamics.Nav.XmlMetadata.MetadataProvider.GetRelativeHelpUrl(...)`nat Microsoft.Dynamics.Nav.Service.OData.V4.PageDataProvider.GetNavRecordDataAsync(...)"
            )
            $text = [System.Security.SecurityElement]::Escape("ClientSessionId: $CorrelationId`n$Stack")
            '<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event"><System><Provider Name="' +
                $Provider + '"/><EventID>' + $EventId + '</EventID><TimeCreated SystemTime="' +
                $Time.ToString('o') + '"/></System><EventData><Data>' + $text + '</Data></EventData></Event>'
        }
    }

    AfterAll {
        if ($script:createdContainerStub) { Remove-Item function:global:Invoke-ScriptInBcContainer }
    }

    BeforeEach {
        $script:fixtureRoot = Join-Path $PSScriptRoot ('.sql-api-retry-fixture-' + [guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:fixtureRoot
        $script:requestId = '11111111-2222-4333-8444-555555555555'
        $script:eventTime = [datetime]::UtcNow.AddSeconds(-10)
        $script:context = [pscustomobject]@{
            ContainerName = 'synthetic-container'
            Tenant = 'synthetic-tenant'
            CodeunitId = 70001
            TestCount = 3
            StartedUtc = $script:eventTime.AddSeconds(-10)
            ResultFiles = [pscustomobject]@{ JUnitResultFileName = Join-Path $script:fixtureRoot 'results.xml' }
        }
        $script:expectedTests = @(
            [pscustomobject]@{ Name = 'Synthetic API Codeunit.Read Item'; Skipped = $false }
            [pscustomobject]@{ Name = 'Synthetic API Codeunit.Read Customer'; Skipped = $false }
            [pscustomobject]@{ Name = 'Synthetic API Codeunit.Disabled Case'; Skipped = $true }
        )
        $script:originalCases = @(
            New-CaseXml -Name $script:expectedTests[0].Name -Message (New-FailureMessage)
            New-CaseXml -Name $script:expectedTests[1].Name
            New-CaseXml -Name $script:expectedTests[2].Name -Skipped
        )
        $script:passingCases = @(
            New-CaseXml -Name $script:expectedTests[0].Name
            New-CaseXml -Name $script:expectedTests[1].Name
            New-CaseXml -Name $script:expectedTests[2].Name -Skipped
        )
        Write-Suite
        Mock -ModuleName SqlApiTestRetry Write-Host {}
        Mock -ModuleName SqlApiTestRetry Invoke-ScriptInBcContainer { throw 'Live container execution is forbidden.' }
    }

    AfterEach {
        Remove-Item -LiteralPath $script:fixtureRoot -Recurse -Force
    }

    Context 'Evidence classification and preservation' {
        BeforeEach {
            $script:events = @(New-NstEvent)
            Mock -ModuleName SqlApiTestRetry Get-SqlApiRetryEvents { $script:events }
        }

        It 'recognizes the observed namespaced event and failure attribute shapes without changing results' {
            $before = [System.IO.File]::ReadAllBytes($script:context.ResultFiles.JUnitResultFileName)
            $evidence = Get-SqlApiTestRetryEvidence -Context $script:context
            $evidence | Should -Not -BeNullOrEmpty
            $evidence.RequestIds | Should -Be @($script:requestId)
            $evidence.Events | Should -Be $script:events
            $evidence.TestCases.Name | Should -Be $script:expectedTests.Name
            $evidence.TestCases.Skipped | Should -Be @($false, $false, $true)
            [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($script:context.ResultFiles.JUnitResultFileName)) |
                Should -Be ([Convert]::ToBase64String($before))
            Should -Invoke -ModuleName SqlApiTestRetry Get-SqlApiRetryEvents -Times 1 -Exactly -ParameterFilter {
                $ContainerName -eq 'synthetic-container' -and $StartedUtc -eq $script:context.StartedUtc -and
                $FinishedUtc -ge $script:eventTime -and $FinishedUtc -le [datetime]::UtcNow
            }
            Should -Invoke -ModuleName SqlApiTestRetry Invoke-ScriptInBcContainer -Times 0
        }

        It 'persists the first full suite and events before the result file is replaced by the rerun' {
            $original = ([xml](Get-Content -LiteralPath $script:context.ResultFiles.JUnitResultFileName -Raw)).testsuites.testsuite.OuterXml
            $evidence = Get-SqlApiTestRetryEvidence -Context $script:context
            $files = @(Get-ChildItem -LiteralPath (Join-Path $script:fixtureRoot 'SqlApiRetryEvidence') -Filter '*.json')
            $files.Count | Should -Be 1
            $savedBeforeRerun = Get-Content -LiteralPath $files[0].FullName -Raw
            ($savedBeforeRerun | ConvertFrom-Json).OriginalSuite | Should -Be $original
            Write-Suite -Cases $script:passingCases
            Test-SqlApiRetryResult -Context $script:context -ExpectedTests $evidence.TestCases | Should -BeTrue
            Get-Content -LiteralPath $files[0].FullName -Raw | Should -Be $savedBeforeRerun
            $persisted = $savedBeforeRerun | ConvertFrom-Json
            $persisted.Events | Should -Be $script:events
            $persisted.RequestIds | Should -Be @($script:requestId)
            $persisted.Tenant | Should -Be 'synthetic-tenant'
            $persisted.CodeunitId | Should -Be 70001
            $persisted.TestCases.Name | Should -Be $script:expectedTests.Name
        }

        It 'rejects <Kind> without querying events' -ForEach @(
            @{ Kind = 'generic 500'; Message = 'Assert.Fail failed. GET request failed. Response code is 500 (InternalServerError), expected code is 200.' }
            @{ Kind = 'authentication 401'; Message = 'Assert.Fail failed. GET request failed. Response code is 401 (Unauthorized), expected code is 200.' }
            @{ Kind = 'real assertion'; Message = 'Assert.AreEqual failed. Expected quantity 5, actual quantity 4.' }
        ) {
            $script:originalCases[0] = New-CaseXml -Name $script:expectedTests[0].Name -Message $Message
            Write-Suite
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            Should -Invoke -ModuleName SqlApiTestRetry Get-SqlApiRetryEvents -Times 0
            Test-Path (Join-Path $script:fixtureRoot 'SqlApiRetryEvidence') | Should -BeFalse
        }

        It 'rejects an eligible HTTP failure mixed with a genuine assertion failure' {
            $script:originalCases[1] = New-CaseXml -Name $script:expectedTests[1].Name -Message 'Assert.AreEqual failed. Expected true, actual false.'
            Write-Suite
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            Should -Invoke -ModuleName SqlApiTestRetry Get-SqlApiRetryEvents -Times 0
        }

        It 'rejects 401 even when the null-reference text and correlation match' {
            $message = (New-FailureMessage).Replace('500 (InternalServerError)', '401 (Unauthorized)')
            $script:originalCases[0] = New-CaseXml -Name $script:expectedTests[0].Name -Message $message
            Write-Suite
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            Should -Invoke -ModuleName SqlApiTestRetry Get-SqlApiRetryEvents -Times 0
        }

        It 'requires matching events for every failed request' {
            $secondRequest = '66666666-7777-4888-8999-aaaaaaaaaaaa'
            $script:originalCases[1] = New-CaseXml -Name $script:expectedTests[1].Name -Message (New-FailureMessage -CorrelationId $secondRequest)
            Write-Suite
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            $script:events += New-NstEvent -CorrelationId $secondRequest
            $evidence = Get-SqlApiTestRetryEvidence -Context $script:context
            $evidence.RequestIds | Should -Be @($script:requestId, $secondRequest)
            $evidence.Events.Count | Should -Be 2
        }

        It 'rejects <Kind> correlation in the failure message' -ForEach @(
            @{ Kind = 'missing'; Correlation = '' }
            @{ Kind = 'malformed'; Correlation = 'not-a-guid' }
            @{ Kind = 'overlong'; Correlation = '11111111-2222-4333-8444-5555555555556' }
        ) {
            $script:originalCases[0] = New-CaseXml -Name $script:expectedTests[0].Name -Message (New-FailureMessage -CorrelationId $Correlation)
            Write-Suite
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            Should -Invoke -ModuleName SqlApiTestRetry Get-SqlApiRetryEvents -Times 0
        }

        It 'rejects event evidence with <Kind>' -ForEach @(
            @{ Kind = 'wrong correlation' }
            @{ Kind = 'missing correlation' }
            @{ Kind = 'stale time' }
            @{ Kind = 'future time' }
            @{ Kind = 'wrong provider' }
            @{ Kind = 'wrong event ID' }
            @{ Kind = 'wrong exception' }
            @{ Kind = 'wrong pool frame' }
            @{ Kind = 'wrong metadata frame' }
            @{ Kind = 'wrong OData frame' }
        ) {
            switch ($Kind) {
                'wrong correlation' { $script:events = @(New-NstEvent -CorrelationId '66666666-7777-4888-8999-aaaaaaaaaaaa') }
                'missing correlation' { $script:events = @((New-NstEvent) -replace 'ClientSessionId:', 'OtherSessionId:') }
                'stale time' { $script:events = @(New-NstEvent -Time $script:context.StartedUtc.AddTicks(-1)) }
                'future time' { $script:events = @(New-NstEvent -Time ([datetime]::UtcNow.AddHours(1))) }
                'wrong provider' { $script:events = @(New-NstEvent -Provider 'UnrelatedProvider') }
                'wrong event ID' { $script:events = @(New-NstEvent -EventId '702') }
                'wrong exception' { $script:events = @((New-NstEvent) -replace 'NullReferenceException', 'InvalidOperationException') }
                'wrong pool frame' { $script:events = @((New-NstEvent) -replace 'AcquireSqlConnectionFromPool', 'OpenConnection') }
                'wrong metadata frame' { $script:events = @((New-NstEvent) -replace 'GetRelativeHelpUrl', 'ReadMetadata') }
                'wrong OData frame' { $script:events = @((New-NstEvent) -replace 'GetNavRecordDataAsync', 'ReadSomethingElse') }
            }
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            Test-Path (Join-Path $script:fixtureRoot 'SqlApiRetryEvidence') | Should -BeFalse
        }

        It 'accepts an event exactly at the dispatch start boundary' {
            $script:events = @(New-NstEvent -Time $script:context.StartedUtc)
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -Not -BeNullOrEmpty
        }

        It 'fails closed with a warning for <Kind>' -ForEach @(
            @{ Kind = 'missing result file' }
            @{ Kind = 'malformed result XML' }
            @{ Kind = 'wrong suite' }
            @{ Kind = 'missing test count' }
            @{ Kind = 'partial result count' }
            @{ Kind = 'malformed event XML' }
            @{ Kind = 'missing event system' }
            @{ Kind = 'event collection access error' }
            @{ Kind = 'evidence persistence failure' }
        ) {
            switch ($Kind) {
                'missing result file' { Remove-Item -LiteralPath $script:context.ResultFiles.JUnitResultFileName }
                'malformed result XML' { '<testsuites>' | Set-Content -LiteralPath $script:context.ResultFiles.JUnitResultFileName }
                'wrong suite' {
                    (Get-Content -LiteralPath $script:context.ResultFiles.JUnitResultFileName -Raw).Replace('70001', '70002') |
                        Set-Content -LiteralPath $script:context.ResultFiles.JUnitResultFileName
                }
                'missing test count' { $script:context.PSObject.Properties.Remove('TestCount') }
                'partial result count' { $script:context.TestCount = 4 }
                'malformed event XML' { $script:events = @('<Event>') }
                'missing event system' { $script:events = @('<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event"/>') }
                'event collection access error' { Mock -ModuleName SqlApiTestRetry Get-SqlApiRetryEvents { throw 'Synthetic access denied' } }
                'evidence persistence failure' { Mock -ModuleName SqlApiTestRetry Set-Content { throw 'Synthetic write denied' } }
            }
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            Should -Invoke -ModuleName SqlApiTestRetry Write-Host -Times 1 -Exactly -ParameterFilter {
                $Object -like '::warning::*evidence unavailable*preserving test failure*'
            }
        }

        It 'fails closed with a warning when event collection returns no events' {
            $script:events = @()
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            Should -Invoke -ModuleName SqlApiTestRetry Write-Host -Times 1 -Exactly -ParameterFilter {
                $Object -like '::warning::*no matching NST event*'
            }
        }

        It 'does not retry an error element or an unrepresented failed case' -ForEach @(
            @{ CaseXml = '<testcase name="Synthetic API Codeunit.Read Customer" result="Fail"><error message="Synthetic runner error"/></testcase>' }
            @{ CaseXml = '<testcase name="Synthetic API Codeunit.Read Customer" result="Fail"/>' }
        ) {
            $script:originalCases[1] = $CaseXml
            Write-Suite
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            Should -Invoke -ModuleName SqlApiTestRetry Get-SqlApiRetryEvents -Times 0
        }

        It 'does not retry an already passing suite' {
            Write-Suite -Cases $script:passingCases
            Get-SqlApiTestRetryEvidence -Context $script:context | Should -BeNullOrEmpty
            Should -Invoke -ModuleName SqlApiTestRetry Get-SqlApiRetryEvents -Times 0
        }
    }

    Context 'Rerun result shape' {
        It 'accepts all original full names and skip states in any order without mutating results' {
            Write-Suite -Cases @($script:passingCases[2], $script:passingCases[0], $script:passingCases[1])
            $before = Get-Content -LiteralPath $script:context.ResultFiles.JUnitResultFileName -Raw
            Test-SqlApiRetryResult -Context $script:context -ExpectedTests $script:expectedTests | Should -BeTrue
            Get-Content -LiteralPath $script:context.ResultFiles.JUnitResultFileName -Raw | Should -Be $before
        }

        It 'rejects rerun with <Kind>' -ForEach @(
            @{ Kind = 'new skipped case' }
            @{ Kind = 'removed original skip' }
            @{ Kind = 'empty suite' }
            @{ Kind = 'duplicate testcase' }
            @{ Kind = 'missing testcase' }
            @{ Kind = 'extra testcase' }
            @{ Kind = 'renamed full testcase' }
            @{ Kind = 'empty testcase name' }
            @{ Kind = 'changed case in name' }
            @{ Kind = 'failure element' }
            @{ Kind = 'error element' }
            @{ Kind = 'failed result without failure element' }
            @{ Kind = 'missing result file' }
            @{ Kind = 'malformed result XML' }
        ) {
            switch ($Kind) {
                'new skipped case' { $script:passingCases[0] = New-CaseXml -Name $script:expectedTests[0].Name -Skipped }
                'removed original skip' { $script:passingCases[2] = New-CaseXml -Name $script:expectedTests[2].Name }
                'empty suite' { $script:passingCases = @() }
                'duplicate testcase' { $script:passingCases[1] = $script:passingCases[0] }
                'missing testcase' { $script:passingCases = @($script:passingCases[0], $script:passingCases[2]) }
                'extra testcase' { $script:passingCases += New-CaseXml -Name 'Synthetic API Codeunit.Extra Case' }
                'renamed full testcase' { $script:passingCases[0] = New-CaseXml -Name 'Read Item' }
                'empty testcase name' { $script:passingCases[0] = New-CaseXml -Name '' }
                'changed case in name' { $script:passingCases[0] = New-CaseXml -Name $script:expectedTests[0].Name.ToLowerInvariant() }
                'failure element' { $script:passingCases[0] = $script:originalCases[0] }
                'error element' { $script:passingCases[0] = $script:passingCases[0].Replace('</testcase>', '<error message="Synthetic error"/></testcase>') }
                'failed result without failure element' { $script:passingCases[0] = New-CaseXml -Name $script:expectedTests[0].Name -Result 'Fail' }
            }
            Write-Suite -Cases $script:passingCases
            if ($Kind -eq 'missing result file') { Remove-Item -LiteralPath $script:context.ResultFiles.JUnitResultFileName }
            if ($Kind -eq 'malformed result XML') { '<testsuites>' | Set-Content -LiteralPath $script:context.ResultFiles.JUnitResultFileName }
            Test-SqlApiRetryResult -Context $script:context -ExpectedTests $script:expectedTests | Should -BeFalse
            Should -Invoke -ModuleName SqlApiTestRetry Write-Host -Times 1 -Exactly -ParameterFilter {
                $Object -like '::warning::SQL API retry remains failed:*'
            }
        }
    }

    Context 'Bounded container event collection' {
        BeforeEach {
            Mock -ModuleName SqlApiTestRetry Invoke-ScriptInBcContainer {
                param($containerName, $scriptblock, $argumentList)
                $null = $containerName
                & $scriptblock @argumentList
            }
            Mock -ModuleName SqlApiTestRetry Get-WinEvent { @() }
        }

        It 'bounds the application query by NST provider, event ID, dispatch time and maximum event count' {
            $start = $script:context.StartedUtc
            $end = $script:eventTime
            $null = & (Get-Module SqlApiTestRetry) {
                param($start, $end)
                Get-SqlApiRetryEvents -ContainerName 'synthetic-container' -StartedUtc $start -FinishedUtc $end
            } $start $end
            Should -Invoke -ModuleName SqlApiTestRetry Invoke-ScriptInBcContainer -Times 1 -Exactly -ParameterFilter {
                $containerName -eq 'synthetic-container' -and $argumentList.Count -eq 2 -and
                $argumentList[0] -eq $script:context.StartedUtc.ToString('o') -and $argumentList[1] -eq $script:eventTime.ToString('o')
            }
            Should -Invoke -ModuleName SqlApiTestRetry Get-WinEvent -Times 1 -Exactly -ParameterFilter {
                $FilterHashtable.LogName -eq 'Application' -and
                $FilterHashtable.ProviderName -eq 'MicrosoftDynamicsNavServer*' -and
                $FilterHashtable.Id -eq 701 -and
                $FilterHashtable.StartTime -eq $script:context.StartedUtc -and
                $FilterHashtable.EndTime -eq $script:eventTime -and
                $MaxEvents -eq 1000 -and $ErrorAction -eq 'Stop'
            }
        }

        It 'returns original XML from collected events' {
            $script:collectedXml = New-NstEvent
            Mock -ModuleName SqlApiTestRetry Get-WinEvent {
                $eventRecord = [pscustomobject]@{ Xml = $script:collectedXml }
                $eventRecord | Add-Member ScriptMethod ToXml { $this.Xml }
                $eventRecord
            }
            $actual = & (Get-Module SqlApiTestRetry) {
                param($context)
                Get-SqlApiRetryEvents -ContainerName $context.ContainerName -StartedUtc $context.StartedUtc -FinishedUtc ([datetime]::UtcNow)
            } $script:context
            $actual | Should -Be $script:collectedXml
        }

        It 'treats only NoMatchingEventsFound as an empty collection' {
            Mock -ModuleName SqlApiTestRetry Get-WinEvent {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new('Synthetic no matching events'),
                    'NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound, $null)
                throw $errorRecord
            }
            $actual = & (Get-Module SqlApiTestRetry) {
                param($context)
                Get-SqlApiRetryEvents -ContainerName $context.ContainerName -StartedUtc $context.StartedUtc -FinishedUtc ([datetime]::UtcNow)
            } $script:context
            $actual | Should -BeNullOrEmpty
        }

        It 'propagates event-log access errors instead of reporting no matches' {
            Mock -ModuleName SqlApiTestRetry Get-WinEvent { throw [System.UnauthorizedAccessException]::new('Synthetic event log access denied') }
            {
                & (Get-Module SqlApiTestRetry) {
                    param($context)
                    Get-SqlApiRetryEvents -ContainerName $context.ContainerName -StartedUtc $context.StartedUtc -FinishedUtc ([datetime]::UtcNow)
                } $script:context
            } | Should -Throw '*Synthetic event log access denied*'
        }
    }
}
