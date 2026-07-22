<#
.Synopsis
    Test Tolerance — core helpers for tolerating unstable test failures during builds.

.Description
    An "unstable test" is a test that is known to fail intermittently. The Test Tolerance
    feature lets the build tolerate failures of such tests so they don't fail the build.
    Unstable tests are tracked in a per-branch artifact maintained by a separate workflow
    that runs after CI/CD. This module provides the building blocks the build uses to:

    - Determine the artifact name for a branch
    - Decide whether the current branch is supported (main, releases/*)
    - Read the unstable tests list
    - Parse the test results (XUnit/JUnit XML produced by AL-Go AnalyzeTests upstream)
    - Cross-reference failures against the unstable list and produce a tolerance result
    - Rewrite the test results XML to reclassify tolerated failures as passes
    - Write a per-build "tolerated tests" artifact for traceability

    This module contains pure-ish functions designed to be unit-tested. The wiring into the
    workflow lives in RunTestsInBcContainer.ps1 and the workflow YAML.
#>

Set-StrictMode -Version 2.0

<#
.Synopsis
    Resolves the tolerance branch for the current build context.
.Description
    For pull_request events, returns GITHUB_BASE_REF if it is a supported branch.
    For push events on a supported branch, returns GITHUB_REF_NAME.
    Defaults to 'main' if neither is supported.
#>
function Get-ToleranceBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    # PR event: target branch is known
    if ($env:GITHUB_BASE_REF -and (Test-IsToleranceSupportedBranch -Branch $env:GITHUB_BASE_REF)) {
        return $env:GITHUB_BASE_REF
    }

    # Push event on a supported branch directly
    if (Test-IsToleranceSupportedBranch -Branch $env:GITHUB_REF_NAME) {
        return $env:GITHUB_REF_NAME
    }

    # Default to main
    return 'main'
}

<#
.Synopsis
    Returns whether the given branch is supported by the test tolerance feature.
.Description
    Only 'main' and 'releases/*' branches are supported. All other branches must
    not produce or consume the unstable tests artifact.
#>
function Test-IsToleranceSupportedBranch {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Branch
    )

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        return $false
    }

    if ($Branch -eq 'main') {
        return $true
    }

    return $Branch -like 'releases/*'
}

<#
.Synopsis
    Returns the unstable tests artifact name for a given branch.
.Description
    The artifact is branch-scoped so different branches can carry different sets of unstable
    tests. The branch is normalized so the resulting name is safe to use as a GitHub
    artifact name (which disallows '/').
#>
function Get-UnstableTestsArtifactName {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Branch
    )

    if (-not (Test-IsToleranceSupportedBranch -Branch $Branch)) {
        throw "Branch '$Branch' is not supported by the test tolerance feature."
    }

    $normalized = $Branch -replace '[^A-Za-z0-9._-]', '-'
    return "unstable-tests-$normalized"
}

<#
.Synopsis
    Splits a codeunit string like '137404 SCM Manufacturing' into its numeric ID and name.
.Description
    BC test results use the format '<id> <name>' in the classname attribute.
    Returns a hashtable with 'Id' ([int]) and 'Name' ([string]).
    When the string does not start with a numeric prefix, Id is 0 and Name is the full string.
#>
function Split-CodeunitString {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Codeunit
    )

    $trimmed = $Codeunit.Trim()
    if ($trimmed -match '^(\d+)\s+(.+)$') {
        return @{ Id = [int]$Matches[1]; Name = $Matches[2].Trim() }
    }
    return @{ Id = 0; Name = $trimmed }
}

<#
.Synopsis
    Builds a normalized identifier for a single test (extensionId + codeunitId + method).
#>
function Get-UnstableTestKey {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [int] $CodeunitId,

        [Parameter(Mandatory = $true)]
        [string] $TestMethod,

        [string] $ExtensionId = ''
    )

    $normalizedExtensionId = if ([string]::IsNullOrWhiteSpace($ExtensionId)) { '' } else { $ExtensionId.Trim().ToLowerInvariant() }
    return "$normalizedExtensionId::$CodeunitId::$($TestMethod.Trim().ToLowerInvariant())"
}

<#
.Synopsis
    Reads the unstable tests list from disk and returns a hashtable keyed by 'extensionId::codeunit::testMethod'.
.Description
    The unstable tests artifact is a JSON file with the following schema:

    {
      "branch": "main",
      "updatedAt": "2026-04-24T00:00:00Z",
      "tests": [
        { "extensionId": "...", "codeunitId": 137404, "codeunitName": "SCM Manufacturing", "testMethod": "TestSomething", "reason": "...", "linkedIssue": "..." }
      ]
    }

    The 'reason' and 'linkedIssue' fields are optional. The function returns an empty
    hashtable when the file does not exist, so callers can treat "no artifact" as
    "no unstable tests yet".
#>
function Read-UnstableTestsList {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $result = @{}

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Verbose "Unstable tests file not found at '$Path'. Treating as empty list."
        return $result
    }

    $raw = Get-Content -Raw -Path $Path
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $result
    }

    $json = $raw | ConvertFrom-Json

    if (-not (Get-Member -InputObject $json -Name 'tests' -MemberType NoteProperty)) {
        return $result
    }

    foreach ($entry in @($json.tests)) {
        if ($null -eq $entry) { continue }
        if (-not (Get-Member -InputObject $entry -Name 'testMethod' -MemberType NoteProperty)) { continue }

        $extensionId = if (Get-Member -InputObject $entry -Name 'extensionId' -MemberType NoteProperty) { $entry.extensionId } else { '' }

        # Support both new (codeunitId/codeunitName) and legacy (codeunit) formats
        $codeunitId = 0
        $codeunitName = ''
        if (Get-Member -InputObject $entry -Name 'codeunitId' -MemberType NoteProperty) {
            $codeunitId = [int]$entry.codeunitId
            $codeunitName = if (Get-Member -InputObject $entry -Name 'codeunitName' -MemberType NoteProperty) { $entry.codeunitName } else { '' }
        } elseif (Get-Member -InputObject $entry -Name 'codeunit' -MemberType NoteProperty) {
            $split = Split-CodeunitString -Codeunit $entry.codeunit
            $codeunitId = $split.Id
            $codeunitName = $split.Name
        } else {
            continue
        }

        $key = Get-UnstableTestKey -CodeunitId $codeunitId -TestMethod $entry.testMethod -ExtensionId $extensionId
        $result[$key] = [pscustomobject]@{
            ExtensionId  = $extensionId
            CodeunitId   = $codeunitId
            CodeunitName = $codeunitName
            TestMethod   = $entry.testMethod
            Reason       = if (Get-Member -InputObject $entry -Name 'reason' -MemberType NoteProperty) { $entry.reason } else { '' }
            LinkedIssue  = if (Get-Member -InputObject $entry -Name 'linkedIssue' -MemberType NoteProperty) { $entry.linkedIssue } else { '' }
        }
    }

    return $result
}

<#
.Synopsis
    Parses a JUnit/XUnit-style test results XML file and returns the failed tests.
.Description
    Returns a list of pscustomobjects with CodeunitId, CodeunitName, TestMethod, FailureMessage.
    The codeunit string is taken from the testcase 'classname' attribute when present,
    otherwise from the parent testsuite 'name' attribute, and then split into ID and name.
#>
function Get-FailedTestsFromResults {
    [CmdletBinding()]
    [OutputType([System.Collections.IList])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $failed = New-Object System.Collections.Generic.List[object]

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Verbose "Test results file not found at '$Path'. Returning no failed tests."
        return
    }

    [xml]$xml = Get-Content -Raw -Path $Path

    # Support both <testsuites><testsuite>... and a single root <testsuite>...
    # Use LocalName because PowerShell's XML adapter shadows .Name with the
    # 'name' attribute when one is present on the element.
    $suites = @()
    if ($xml.DocumentElement.LocalName -eq 'testsuites') {
        $suites = @($xml.DocumentElement.SelectNodes('testsuite'))
    } elseif ($xml.DocumentElement.LocalName -eq 'testsuite') {
        $suites = @($xml.DocumentElement)
    }

    foreach ($suite in $suites) {
        if ($null -eq $suite) { continue }
        $suiteName = if ($suite.HasAttribute('name')) { $suite.GetAttribute('name') } else { '' }

        # Extract extensionid from <properties><property name="extensionid" value="..." />
        $extensionId = ''
        $extProp = $suite.SelectSingleNode("properties/property[@name='extensionid']")
        if ($null -ne $extProp -and $extProp.HasAttribute('value')) {
            $extensionId = $extProp.GetAttribute('value')
        }

        $testCases = @($suite.SelectNodes('testcase'))
        foreach ($tc in $testCases) {
            $failureNode = $tc.SelectSingleNode('failure')
            $errorNode = $tc.SelectSingleNode('error')
            if ($null -eq $failureNode -and $null -eq $errorNode) { continue }

            $codeunit = if ($tc.HasAttribute('classname') -and $tc.GetAttribute('classname')) {
                $tc.GetAttribute('classname')
            } else {
                $suiteName
            }
            $split = Split-CodeunitString -Codeunit $codeunit
            $codeunitId = $split.Id
            $codeunitName = $split.Name
            $testMethod = if ($tc.HasAttribute('name')) { $tc.GetAttribute('name') } else { '' }
            $message = ''
            $failureDetail = ''
            if ($null -ne $failureNode -and $failureNode.HasAttribute('message')) {
                $message = $failureNode.GetAttribute('message')
            } elseif ($null -ne $errorNode -and $errorNode.HasAttribute('message')) {
                $message = $errorNode.GetAttribute('message')
            }
            if ($null -ne $failureNode) {
                $failureDetail = $failureNode.InnerText
            } elseif ($null -ne $errorNode) {
                $failureDetail = $errorNode.InnerText
            }

            $failed.Add([pscustomobject]@{
                ExtensionId    = $extensionId
                CodeunitId     = $codeunitId
                CodeunitName   = $codeunitName
                TestMethod     = $testMethod
                FailureMessage = $message
                FailureDetail  = $failureDetail
                Key            = Get-UnstableTestKey -CodeunitId $codeunitId -TestMethod $testMethod -ExtensionId $extensionId
            }) | Out-Null
        }
    }

    return $failed
}

<#
.Synopsis
    Cross-references failed tests against the unstable list.
.Description
    Returns a pscustomobject with two collections: Tolerated (failures listed in the
    unstable tests artifact) and Unresolved (failures that should still fail the build).
#>
function Resolve-TestTolerance {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IList] $FailedTests,

        [Parameter(Mandatory = $true)]
        [hashtable] $UnstableTests
    )

    $tolerated = New-Object System.Collections.Generic.List[object]
    $unresolved = New-Object System.Collections.Generic.List[object]

    foreach ($failure in $FailedTests) {
        if ($UnstableTests.ContainsKey($failure.Key)) {
            $entry = $UnstableTests[$failure.Key]
            $tolerated.Add([pscustomobject]@{
                ExtensionId    = if ($failure.PSObject.Properties['ExtensionId']) { $failure.ExtensionId } else { '' }
                CodeunitId     = $failure.CodeunitId
                CodeunitName   = $failure.CodeunitName
                TestMethod     = $failure.TestMethod
                FailureMessage = $failure.FailureMessage
                Reason         = $entry.Reason
                LinkedIssue    = $entry.LinkedIssue
            }) | Out-Null
        } else {
            $unresolved.Add($failure) | Out-Null
        }
    }

    return [pscustomobject]@{
        Tolerated  = $tolerated
        Unresolved = $unresolved
    }
}

<#
.Synopsis
    Rewrites the test results XML so tolerated failures are no longer marked as failures.
.Description
    For each tolerated test case, removes <failure> / <error> children and adjusts the
    parent <testsuite> 'failures' / 'errors' counts accordingly. A
    <system-out>TOLERATED: ...</system-out> note is inserted so the reclassification is
    discoverable when reading the XML directly. The file is rewritten in place.
#>
function Update-TestResultsForTolerance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [System.Collections.IList] $ToleratedTests
    )

    if ($ToleratedTests.Count -eq 0) {
        return
    }

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Test results file not found at '$Path'."
    }

    [xml]$xml = Get-Content -Raw -Path $Path

    $toleratedKeys = @{}
    foreach ($t in $ToleratedTests) {
        $extId = if ($t.PSObject.Properties['ExtensionId']) { $t.ExtensionId } else { '' }
        $toleratedKeys[(Get-UnstableTestKey -CodeunitId $t.CodeunitId -TestMethod $t.TestMethod -ExtensionId $extId)] = $t
    }

    $suites = @()
    if ($xml.DocumentElement.LocalName -eq 'testsuites') {
        $suites = @($xml.DocumentElement.SelectNodes('testsuite'))
    } elseif ($xml.DocumentElement.LocalName -eq 'testsuite') {
        $suites = @($xml.DocumentElement)
    }

    foreach ($suite in $suites) {
        if ($null -eq $suite) { continue }
        $suiteName = if ($suite.HasAttribute('name')) { $suite.GetAttribute('name') } else { '' }
        $removedFailures = 0
        $removedErrors = 0

        $extensionId = ''
        $extProp = $suite.SelectSingleNode("properties/property[@name='extensionid']")
        if ($null -ne $extProp -and $extProp.HasAttribute('value')) {
            $extensionId = $extProp.GetAttribute('value')
        }

        foreach ($tc in @($suite.SelectNodes('testcase'))) {
            $codeunit = if ($tc.HasAttribute('classname') -and $tc.GetAttribute('classname')) { $tc.GetAttribute('classname') } else { $suiteName }
            $testMethod = if ($tc.HasAttribute('name')) { $tc.GetAttribute('name') } else { '' }
            $split = Split-CodeunitString -Codeunit $codeunit
            $key = Get-UnstableTestKey -CodeunitId $split.Id -TestMethod $testMethod -ExtensionId $extensionId
            if (-not $toleratedKeys.ContainsKey($key)) { continue }

            $entry = $toleratedKeys[$key]

            $failureNode = $tc.SelectSingleNode('failure')
            if ($null -ne $failureNode) {
                [void]$tc.RemoveChild($failureNode)
                $removedFailures++
            }
            $errorNode = $tc.SelectSingleNode('error')
            if ($null -ne $errorNode) {
                [void]$tc.RemoveChild($errorNode)
                $removedErrors++
            }

            $note = $xml.CreateElement('system-out')
            $reason = if ($entry.Reason) { " ($($entry.Reason))" } else { '' }
            $note.InnerText = "TOLERATED: failure tolerated by Test Tolerance feature$reason"
            [void]$tc.AppendChild($note)
        }

        if ($removedFailures -gt 0 -and $suite.HasAttribute('failures')) {
            $current = [int]$suite.GetAttribute('failures')
            $suite.SetAttribute('failures', [string]([Math]::Max(0, $current - $removedFailures)))
        }
        if ($removedErrors -gt 0 -and $suite.HasAttribute('errors')) {
            $current = [int]$suite.GetAttribute('errors')
            $suite.SetAttribute('errors', [string]([Math]::Max(0, $current - $removedErrors)))
        }
    }

    $xml.Save($Path)
}

<#
.Synopsis
    Evaluates whether all remaining test failures are tolerated (unstable) and can be ignored.
.Description
    Given a test results XML and an unstable tests artifact, checks if all failed tests are
    listed as unstable. If so, rewrites the test results to reclassify them and returns $true.
    Returns $false if any failures are not tolerated, or if inputs are missing/unsupported.
#>
function Test-ShouldTolerateFailures {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TestResultsPath,

        [string] $UnstableTestsPath
    )

    if ([string]::IsNullOrWhiteSpace($UnstableTestsPath) -or -not (Test-Path -Path $UnstableTestsPath -PathType Leaf)) {
        Write-Host "Unstable tests file not found or not provided. Skipping tolerance check."
        return $false
    }

    if (-not (Test-Path -Path $TestResultsPath -PathType Leaf)) {
        Write-Host "Test results file not found at '$TestResultsPath'. Skipping tolerance check."
        return $false
    }

    Write-Host "Reading unstable tests list from '$UnstableTestsPath'..."
    $unstableTests = Read-UnstableTestsList -Path $UnstableTestsPath
    if ($unstableTests.Count -eq 0) {
        Write-Host "Unstable tests list is empty. Skipping tolerance check."
        return $false
    }
    Write-Host "Found $($unstableTests.Count) unstable test(s) in the list."

    Write-Host "Parsing failed tests from '$TestResultsPath'..."
    $failedTests = @(Get-FailedTestsFromResults -Path $TestResultsPath | Where-Object { $_ })
    if ($failedTests.Count -eq 0) {
        Write-Host "No failed tests found in results. Nothing to tolerate."
        return $true
    }
    Write-Host "Found $($failedTests.Count) failed test(s) in results."

    $resolution = Resolve-TestTolerance -FailedTests ([System.Collections.Generic.List[object]]$failedTests) -UnstableTests $unstableTests

    if ($resolution.Unresolved.Count -gt 0) {
        Write-Host "$($resolution.Unresolved.Count) failure(s) are NOT in the unstable tests list and cannot be tolerated."
        return $false
    }

    Write-Host "::group::Tolerated test failures"
    foreach ($t in $resolution.Tolerated) {
        $reason = if ($t.Reason) { " — $($t.Reason)" } else { '' }
        $issue = if ($t.LinkedIssue) { " (issue: $($t.LinkedIssue))" } else { '' }
        Write-Host "TOLERATED: $($t.ExtensionId) :: $($t.CodeunitId) $($t.CodeunitName) :: $($t.TestMethod)$reason$issue"
    }
    Write-Host "::endgroup::"

    Update-TestResultsForTolerance -Path $TestResultsPath -ToleratedTests $resolution.Tolerated
    Write-Host "All $($resolution.Tolerated.Count) failure(s) are tolerated. Treating test run as successful."
    return $true
}

<#
.Synopsis
    Downloads the unstable tests artifact for the given branch from GitHub Actions.
.Description
    Uses the GitHub REST API to find the most recent artifact named 'unstable-tests-<branch>'
    in the current repository, downloads it, and extracts the JSON file to a local directory.
    Returns the path to the extracted unstable-tests.json, or $null if the artifact is not found
    or any step fails.

    Requires the GH_TOKEN, GITHUB_TOKEN, or _token environment variable and GITHUB_REPOSITORY to be set.
    If no token variable is available the function skips the download and returns $null.
#>
function Receive-UnstableTestsArtifact {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Branch,

        [Parameter(Mandatory = $true)]
        [string] $OutputDirectory
    )

    if (-not (Test-IsToleranceSupportedBranch -Branch $Branch)) {
        Write-Verbose "Branch '$Branch' is not supported. Skipping artifact download."
        return $null
    }

    $token = if (-not [string]::IsNullOrEmpty($env:GH_TOKEN)) { $env:GH_TOKEN }
             elseif (-not [string]::IsNullOrEmpty($env:GITHUB_TOKEN)) { $env:GITHUB_TOKEN }
             elseif (-not [string]::IsNullOrEmpty($env:_token)) { $env:_token }
             else { $null }

    if (-not $token) {
        Write-Host "No GitHub token found (checked GH_TOKEN, GITHUB_TOKEN, _token). Skipping unstable tests artifact download."
        return $null
    }

    $artifactName = Get-UnstableTestsArtifactName -Branch $Branch
    $repo = $env:GITHUB_REPOSITORY
    $headers = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' }

    try {
        Write-Host "Looking up unstable tests artifact '$artifactName' ..."
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/actions/artifacts?name=$([uri]::EscapeDataString($artifactName))&per_page=1" `
            -Headers $headers

        if ($response.total_count -eq 0 -or $response.artifacts.Count -eq 0) {
            Write-Host "No unstable tests artifact found for branch '$Branch'."
            return $null
        }

        $artifact = $response.artifacts[0]
        if ($artifact.expired) {
            Write-Host "Unstable tests artifact '$artifactName' has expired. Skipping."
            return $null
        }

        Write-Host "Downloading artifact '$artifactName' (id: $($artifact.id)) ..."

        if (-not (Test-Path $OutputDirectory)) {
            New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        }

        $zipPath = Join-Path $OutputDirectory 'unstable-tests.zip'
        Invoke-WebRequest -Uri "https://api.github.com/repos/$repo/actions/artifacts/$($artifact.id)/zip" `
            -Headers $headers `
            -OutFile $zipPath

        Expand-Archive -Path $zipPath -DestinationPath $OutputDirectory -Force
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue

        $jsonPath = Join-Path $OutputDirectory 'unstable-tests.json'
        if (Test-Path $jsonPath) {
            Write-Host "Unstable tests artifact downloaded to '$jsonPath'."
            return $jsonPath
        }

        # If the JSON isn't at root level, search for it
        $found = Get-ChildItem -Path $OutputDirectory -Filter 'unstable-tests.json' -Recurse | Select-Object -First 1
        if ($found) {
            Write-Host "Unstable tests artifact found at '$($found.FullName)'."
            return $found.FullName
        }

        Write-Host "Downloaded artifact but could not find unstable-tests.json inside."
        return $null
    }
    catch {
        Write-Host "Failed to download unstable tests artifact: $($_.Exception.Message)"
        return $null
    }
}

<#
.Synopsis
    Builds an unstable tests list from the provided failed tests.
.Description
    Given a set of failed tests from the analyzed test result artifacts, produces a new unstable
    tests hashtable by marking every failed test key as unstable.

    Each returned entry is keyed by 'extensionId::codeunit::testMethod' and contains the test
    identity fields plus an auto-detected reason of the form:
      "Auto-detected: failed in at least 1 of the last <RunCount> CI/CD run(s)"

    This function does not inspect passed tests or merge with an existing unstable list; it
    only transforms the supplied failed-test set into the artifact format.

    Returns the updated hashtable keyed by 'extensionId::codeunit::testMethod'.
#>
function Update-UnstableTestsList {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $FailedTests,

        [int] $RunCount = 0
    )

    $result = @{}
    foreach ($key in @($FailedTests.Keys)) {
        $ft = $FailedTests[$key]
        Write-Host "UNSTABLE: $key"
        $result[$key] = [pscustomobject]@{
            ExtensionId    = if ($ft.PSObject.Properties['ExtensionId']) { $ft.ExtensionId } else { '' }
            CodeunitId     = if ($ft.PSObject.Properties['CodeunitId']) { $ft.CodeunitId } else { 0 }
            CodeunitName   = if ($ft.PSObject.Properties['CodeunitName']) { $ft.CodeunitName } else { '' }
            TestMethod     = $ft.TestMethod
            FailureMessage = if ($ft.PSObject.Properties['FailureMessage']) { $ft.FailureMessage } else { '' }
            FailureDetail  = if ($ft.PSObject.Properties['FailureDetail']) { $ft.FailureDetail } else { '' }
            SourceRunId    = if ($ft.PSObject.Properties['SourceRunId']) { $ft.SourceRunId } else { '' }
            Reason         = "Auto-detected: failed in at least 1 of the last $RunCount CI/CD run(s)"
            LinkedIssue    = ''
        }
    }

    return $result
}

<#
.Synopsis
    Finds the most recent completed CI/CD runs on a branch that produced test result artifacts.
.Description
    Used by the scheduled sliding-window updater (the UpdateUnstableTests action) to discover which runs
    to examine. Queries the workflow's completed runs (optionally filtered by trigger event), keeps those
    that actually have test result artifacts, and returns up to RunLimit run ids (most recent first).

    Returns an empty array when no qualifying runs are found.
    Requires the GH_TOKEN (or GITHUB_TOKEN) environment variable for 'gh' authentication.
#>
function Find-UnstableTestRunIds {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Branch,

        [Parameter(Mandatory = $true)]
        [string] $Repository,

        [int] $RunLimit = 3,

        [string] $WorkflowFile = 'CICD.yaml',

        [switch] $FilterPush,
        [switch] $FilterWorkflowDispatch
    )

    $eventTypes = @()
    if ($FilterPush) { $eventTypes += 'push' }
    if ($FilterWorkflowDispatch) { $eventTypes += 'workflow_dispatch' }
    if ($eventTypes.Count -eq 0) { $eventTypes = @('workflow_dispatch') }  # Default to workflow_dispatch if nothing selected
    Write-Host "Finding last $RunLimit completed '$WorkflowFile' runs on '$Branch' (events=$($eventTypes -join ', ')) with test result artifacts ..."

    # Fetch candidate runs across all requested event types.
    $candidateLimit = $RunLimit * 5
    $candidates = @()
    foreach ($eventType in $eventTypes) {
        $candidates += @(gh run list --repo $Repository --workflow $WorkflowFile --branch $Branch --event $eventType --status completed --limit $candidateLimit --json databaseId,conclusion,createdAt | ConvertFrom-Json)
    }
    # Sort by creation date descending and deduplicate (in case of overlap).
    $candidates = @($candidates | Sort-Object -Property createdAt -Descending | Sort-Object -Property databaseId -Unique | Sort-Object -Property createdAt -Descending)

    $runIds = [System.Collections.Generic.List[string]]::new()
    foreach ($run in $candidates) {
        if ($runIds.Count -ge $RunLimit) { break }
        # The API 'name' param requires exact match (no wildcards), so we paginate and filter client-side.
        $testResultNames = @(gh api "/repos/$Repository/actions/runs/$($run.databaseId)/artifacts" --paginate --jq '.artifacts[].name | select(contains("TestResults"))' 2>$null)
        if ($testResultNames.Count -eq 0) { continue }
        $runIds.Add([string]$run.databaseId)
    }

    if ($runIds.Count -eq 0) {
        if ($candidates.Count -eq 0) {
            Write-Host "::warning::No completed '$WorkflowFile' runs found for branch '$Branch' (events=$($eventTypes -join ', '))."
        } else {
            Write-Host "::warning::Found $($candidates.Count) completed '$WorkflowFile' run(s) for branch '$Branch' (events=$($eventTypes -join ', ')), but none contained test result artifacts."
        }
        return @()
    }

    Write-Host "Found $($runIds.Count) run(s) with test results: $($runIds -join ', ')"
    return $runIds.ToArray()
}

<#
.Synopsis
    Downloads the test result artifacts from one or more CI/CD (or PR Build) runs and returns the failed tests.
.Description
    For each run id, uses 'gh run download' to fetch every artifact whose name contains 'TestResult',
    parses each results XML, and merges the failures into a single hashtable of distinct failed tests keyed
    by 'extensionId::codeunit::testMethod'. Non-test artifacts that happen to contain 'TestResult' in their
    name (BcptTestResults, PageScriptingTestResult) are skipped. When a test fails in more than one run, the
    first run that reported it (in the order the run ids are supplied) is kept as its SourceRunId.

    This is the shared "collect failures from a set of runs" step used by the unstable-tests updater
    script for both modes: the sliding-window recompute (which passes the discovered window of runs)
    and the additive merge (which passes a single explicit run).

    Returns an empty hashtable when none of the runs produced failed tests.
    Requires the GH_TOKEN (or GITHUB_TOKEN) environment variable to be set for 'gh' authentication.
#>
function Get-FailedTestsFromRuns {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $RunIds,

        [Parameter(Mandatory = $true)]
        [string] $Repository,

        [Parameter(Mandatory = $true)]
        [string] $WorkDirectory
    )

    $allFailed = @{}
    foreach ($runId in $RunIds) {
        $runDir = Join-Path $WorkDirectory "run-$runId"

        Write-Host "Downloading test result artifacts from run $runId in '$Repository' ..."
        gh run download $runId --repo $Repository --dir $runDir --pattern '*TestResult*' 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) {
            Write-Host "::warning::gh run download failed for run $runId (exit code $LASTEXITCODE)."
            continue
        }

        if (-not (Test-Path $runDir)) {
            Write-Host "::warning::No test result artifacts were downloaded for run $runId."
            continue
        }

        foreach ($artifactDir in @(Get-ChildItem -Path $runDir -Directory)) {
            # Skip known non-test artifacts that may contain 'TestResult' in their name but don't have AL test result XML files.
            if ($artifactDir.Name -match 'BcptTestResults|PageScriptingTestResult') { continue }

            foreach ($xml in @(Get-ChildItem -Path $artifactDir.FullName -Filter '*.xml' -Recurse)) {
                foreach ($ft in @(Get-FailedTestsFromResults -Path $xml.FullName)) {
                    if (-not $allFailed.ContainsKey($ft.Key)) {
                        $allFailed[$ft.Key] = [pscustomobject]@{
                            ExtensionId    = $ft.ExtensionId
                            CodeunitId     = $ft.CodeunitId
                            CodeunitName   = $ft.CodeunitName
                            TestMethod     = $ft.TestMethod
                            FailureMessage = $ft.FailureMessage
                            FailureDetail  = $ft.FailureDetail
                            SourceRunId    = [string]$runId
                        }
                    }
                }
            }
        }
    }

    Write-Host "Found $($allFailed.Count) distinct failed test(s) across $($RunIds.Count) run(s)."
    return $allFailed
}

<#
.Synopsis
    Converts an internal failed/unstable test object into the camelCase artifact entry shape.
.Description
    Both the sliding-window updater and the additive updater serialize tests into the same
    unstable-tests.json entry schema. This helper is the single place that defines that schema so the
    two paths can't drift apart.

    'Test' is a pscustomobject with PascalCase properties (as produced by Get-FailedTestsFromRuns or
    Update-UnstableTestsList). 'Reason' overrides the entry reason; when empty, the test's own Reason
    property (if any) is used. 'Repository' is used to build the sourceRunUrl from the test's SourceRunId.
#>
function ConvertTo-UnstableTestEntry {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Test,

        [string] $Reason = '',

        [string] $Repository = ''
    )

    $sourceRunId = if ($Test.PSObject.Properties['SourceRunId']) { [string]$Test.SourceRunId } else { '' }
    $reasonValue = if ($Reason) { $Reason } elseif ($Test.PSObject.Properties['Reason']) { [string]$Test.Reason } else { '' }
    $linkedIssue = if ($Test.PSObject.Properties['LinkedIssue']) { [string]$Test.LinkedIssue } else { '' }

    return [pscustomobject][ordered]@{
        extensionId    = if ($Test.PSObject.Properties['ExtensionId']) { [string]$Test.ExtensionId } else { '' }
        codeunitId     = if ($Test.PSObject.Properties['CodeunitId']) { [int]$Test.CodeunitId } else { 0 }
        codeunitName   = if ($Test.PSObject.Properties['CodeunitName']) { [string]$Test.CodeunitName } else { '' }
        testMethod     = [string]$Test.TestMethod
        failureMessage = if ($Test.PSObject.Properties['FailureMessage']) { [string]$Test.FailureMessage } else { '' }
        failureDetail  = if ($Test.PSObject.Properties['FailureDetail']) { [string]$Test.FailureDetail } else { '' }
        reason         = $reasonValue
        linkedIssue    = $linkedIssue
        sourceRunUrl   = if ($Repository -and $sourceRunId) { "https://github.com/$Repository/actions/runs/$sourceRunId" } else { '' }
    }
}

<#
.Synopsis
    Writes the per-branch unstable tests artifact JSON to disk.
.Description
    Builds the standard unstable-tests payload (branch, updatedAt, runIds, tests) and writes it as JSON
    to the given path, creating the parent directory when needed. Used by the unstable-tests updater
    script in both modes (sliding-window recompute and additive merge), which differ only in how they
    produce the 'Tests' entries. Centralizing the write keeps the artifact schema identical.

    'Tests' must already be the final list of artifact entries (camelCase), e.g. from
    ConvertTo-UnstableTestEntry or Add-FailedTestsToUnstableTests.
#>
function Save-UnstableTestsArtifact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Branch,

        [Parameter(Mandatory = $true)]
        [string[]] $RunIds,

        [System.Collections.IList] $Tests = @(),

        [Parameter(Mandatory = $true)]
        [string] $OutputPath
    )

    $outputDir = Split-Path -Parent $OutputPath
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Normalize to a plain array. Avoid @($Tests): wrapping a List[object] directly throws
    # "Argument types do not match" on some PowerShell/.NET builds, while [object[]] on an empty
    # collection yields $null. Piping unrolls any list/array shape safely and always into an array.
    $tests = @($Tests | ForEach-Object { $_ })
    $payload = [ordered]@{
        branch    = $Branch
        updatedAt = (Get-Date).ToUniversalTime().ToString('o')
        runIds    = @($RunIds)
        tests     = $tests
    }

    $payload | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Unstable tests list written to '$OutputPath' with $($tests.Count) test(s)."
    Write-Host "::notice::Unstable tests list updated with $($tests.Count) test(s) for branch '$Branch'."
}

<#
.Synopsis
    Merges a set of failed tests into an existing unstable tests list (additive).
.Description
    Unlike the sliding-window heuristic (which fully recomputes the list), this function preserves
    every existing entry verbatim and appends only the failed tests that are not already present.
    Tests are matched by their normalized 'extensionId::codeunit::testMethod' key.

    'ExistingTests' is the raw 'tests' array parsed from an existing unstable-tests.json (an array of
    objects with camelCase properties), or an empty array when no artifact exists yet. 'FailedTests'
    is a hashtable keyed by test key (as produced by Get-FailedTestsFromRuns).

    Returns the merged list ready to be serialized into the artifact: the existing entries unchanged
    (as parsed) followed by the newly added entries produced by ConvertTo-UnstableTestEntry.
#>
function Add-FailedTestsToUnstableTests {
    [CmdletBinding()]
    [OutputType([System.Collections.IList])]
    param(
        [System.Collections.IList] $ExistingTests = @(),

        [Parameter(Mandatory = $true)]
        [hashtable] $FailedTests,

        [string] $Repository = ''
    )

    $merged = New-Object System.Collections.Generic.List[object]
    $seenKeys = @{}

    # Preserve every existing entry verbatim. Track the key of each entry that has one so that newly
    # observed failures already present in the list are not appended again; entries with an
    # unexpected/legacy shape (e.g. missing testMethod) are still kept, just not used for dedup.
    # Enumerate directly rather than via @($ExistingTests): a List[object] passed here would otherwise
    # throw "Argument types do not match" when wrapped in the array-subexpression operator. foreach
    # handles the default empty array, arrays and lists alike.
    foreach ($entry in $ExistingTests) {
        if ($null -eq $entry) { continue }
        $merged.Add($entry) | Out-Null
        $method = if ($entry.PSObject.Properties['testMethod']) { [string]$entry.testMethod } else { '' }
        if ([string]::IsNullOrWhiteSpace($method)) { continue }
        $extId = if ($entry.PSObject.Properties['extensionId']) { [string]$entry.extensionId } else { '' }
        $cuId = if ($entry.PSObject.Properties['codeunitId']) { [int]$entry.codeunitId } else { 0 }
        $key = Get-UnstableTestKey -CodeunitId $cuId -TestMethod $method -ExtensionId $extId
        $seenKeys[$key] = $true
    }

    $added = 0
    foreach ($k in @($FailedTests.Keys)) {
        if ($seenKeys.ContainsKey($k)) {
            Write-Host "ALREADY UNSTABLE: $k"
            continue
        }
        $ft = $FailedTests[$k]
        $sourceRunId = if ($ft.PSObject.Properties['SourceRunId']) { [string]$ft.SourceRunId } else { '' }
        # Prefer a reason the test already carries (e.g. cross-PR detection sets its own). Passing an
        # empty reason lets ConvertTo-UnstableTestEntry fall back to the test's own Reason property.
        # Tests without a Reason (the additive-from-run path) get the default run-based reason.
        $reason = if (($ft.PSObject.Properties['Reason']) -and $ft.Reason) { '' } else { "Manually added from CI/CD run $sourceRunId" }
        $merged.Add((ConvertTo-UnstableTestEntry -Test $ft -Reason $reason -Repository $Repository)) | Out-Null
        $seenKeys[$k] = $true
        Write-Host "ADDED UNSTABLE: $k"
        $added++
    }

    Write-Host "Merged unstable tests list contains $($merged.Count) test(s) ($added newly added)."
    return $merged.ToArray()
}

<#
.Synopsis
    Correlation core: selects tests that failed across multiple distinct PRs.
.Description
    Pure, side-effect-free heuristic behind the cross-PR PR-build detector. Given a set of per-PR-build
    observations (each carrying the PR number and the failing tests parsed from that build), it counts
    how many *distinct* PRs each test failed on and returns the tests that meet the minimum distinct-PR
    threshold.

    The key idea: a test failing on a single PR is ambiguous (it could be that PR's own change), but the
    same test failing across several unrelated PRs in a short window is almost never caused by any one
    PR — it is an instability. Counting *distinct PR numbers* (not raw runs) makes the signal robust
    against the same PR being retried multiple times.

    'Observations' is an array of objects with:
      - PrNumber   : the PR the build belongs to (used for distinct counting; reruns of the same PR count once)
      - RunId      : the source run id (kept on the representative entry for traceability)
      - FailedTests: the list of failing tests for that build (as produced by Get-FailedTestsFromResults)

    Returns a hashtable keyed by the three-part test key, in the same shape Add-FailedTestsToUnstableTests
    consumes, with each entry carrying a Reason describing the distinct-PR count and the target branch.
#>
function Select-CrossPrUnstableTests {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Branch,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [psobject[]] $Observations,

        [int] $MinDistinctPrs = 2,

        [int] $WindowHours = 3
    )

    # For each test key, gather the set of distinct PR numbers it failed on plus a representative
    # test object and source run id (first seen).
    $byKey = @{}
    foreach ($obs in $Observations) {
        if ($null -eq $obs) { continue }
        $pr = if ($obs.PSObject.Properties['PrNumber']) { [string]$obs.PrNumber } else { '' }
        if ([string]::IsNullOrWhiteSpace($pr)) { continue }
        $runId = if ($obs.PSObject.Properties['RunId']) { [string]$obs.RunId } else { '' }

        # Enumerate directly rather than via @(...): wrapping a List[object] in the array-subexpression
        # operator throws "Argument types do not match" on some PowerShell/.NET builds. foreach already
        # handles $null (zero iterations), scalars, arrays and lists safely.
        foreach ($ft in $obs.FailedTests) {
            if ($null -eq $ft) { continue }
            $key = $ft.Key
            if ([string]::IsNullOrWhiteSpace($key)) { continue }
            if (-not $byKey.ContainsKey($key)) {
                $byKey[$key] = [pscustomobject]@{
                    Test  = $ft
                    Prs   = (New-Object 'System.Collections.Generic.HashSet[string]')
                    RunId = $runId
                }
            }
            [void]$byKey[$key].Prs.Add($pr)
            if ([string]::IsNullOrWhiteSpace($byKey[$key].RunId) -and $runId) { $byKey[$key].RunId = $runId }
        }
    }

    $result = @{}
    foreach ($key in @($byKey.Keys)) {
        $entry = $byKey[$key]
        $distinct = $entry.Prs.Count
        if ($distinct -lt $MinDistinctPrs) { continue }

        $ft = $entry.Test
        $result[$key] = [pscustomobject]@{
            ExtensionId    = if ($ft.PSObject.Properties['ExtensionId']) { $ft.ExtensionId } else { '' }
            CodeunitId     = if ($ft.PSObject.Properties['CodeunitId']) { $ft.CodeunitId } else { 0 }
            CodeunitName   = if ($ft.PSObject.Properties['CodeunitName']) { $ft.CodeunitName } else { '' }
            TestMethod     = $ft.TestMethod
            FailureMessage = if ($ft.PSObject.Properties['FailureMessage']) { $ft.FailureMessage } else { '' }
            FailureDetail  = if ($ft.PSObject.Properties['FailureDetail']) { $ft.FailureDetail } else { '' }
            SourceRunId    = $entry.RunId
            Reason         = "Auto-detected: failed on $distinct distinct PRs targeting '$Branch' within the last $WindowHours h"
        }
        Write-Host "CROSS-PR UNSTABLE ($distinct distinct PRs): $key"
    }

    Write-Host "Selected $($result.Count) cross-PR unstable test(s) for branch '$Branch' (threshold: $MinDistinctPrs distinct PRs)."
    return $result
}

<#
.Synopsis
    Downloads a single workflow-run artifact (by id) to a local zip file.
.Description
    Uses Start-Process so the artifact zip is written to disk as raw bytes. Capturing 'gh' stdout through
    the PowerShell pipeline (or a '>' redirect on some hosts) decodes it as text and corrupts the archive.
    Returns $true when a non-empty file was written, $false otherwise (the caller treats a failure as a
    skippable artifact).

    Requires the GH_TOKEN (or GITHUB_TOKEN) environment variable for 'gh' authentication.
#>
function Save-GitHubArtifactZip {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Repository,

        [Parameter(Mandatory = $true)]
        [string] $ArtifactId,

        [Parameter(Mandatory = $true)]
        [string] $OutFile
    )

    $errFile = "$OutFile.stderr"
    $ok = $false
    try {
        $proc = Start-Process -FilePath 'gh' `
            -ArgumentList @('api', "/repos/$Repository/actions/artifacts/$ArtifactId/zip") `
            -RedirectStandardOutput $OutFile -RedirectStandardError $errFile -NoNewWindow -Wait -PassThru
        $ok = ($proc.ExitCode -eq 0) -and (Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)
    }
    catch {
        $ok = $false
    }
    finally {
        Remove-Item $errFile -Force -ErrorAction SilentlyContinue
    }
    return $ok
}

<#
.Synopsis
    Collects the failing tests from every attempt of a single PR-build run.
.Description
    A workflow run can be re-run, producing several attempts. The run-level artifacts endpoint returns the
    artifacts from ALL of a run's attempts (a re-run uploads a fresh artifact with a new id even when the
    name is unchanged), so we enumerate the run's '*TestResult*' artifacts and download each one by id -
    rather than 'gh run download', which only fetches a single artifact per name (the latest attempt). This
    lets an instability that only surfaced in an earlier attempt still be observed.

    Failures are de-duplicated by test key within the run, so the same failure seen in several attempts (or
    in duplicate artifacts) is recorded once per run. Distinct-PR counting happens later, so multiple
    attempts of the same PR never inflate the instability signal.

    Requires the GH_TOKEN (or GITHUB_TOKEN) environment variable for 'gh' authentication.
#>
function Get-RunFailedTestsAllAttempts {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[object]])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Repository,

        [Parameter(Mandatory = $true)]
        [string] $RunId,

        [Parameter(Mandatory = $true)]
        [string] $WorkDirectory
    )

    $failed = New-Object System.Collections.Generic.List[object]

    $artLines = @(gh api "/repos/$Repository/actions/runs/$RunId/artifacts?per_page=100" --paginate `
            --jq '.artifacts[] | select((.name | test("TestResult")) and (.expired | not)) | [(.id | tostring), .name] | @tsv' 2>$null)
    # Tolerated: a still-running (or artifact-less) build lists no artifacts and 'gh' may exit non-zero.
    $global:LASTEXITCODE = 0
    $artLines = @($artLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($artLines.Count -eq 0) { return $failed }

    New-Item -ItemType Directory -Path $WorkDirectory -Force | Out-Null
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($artLine in $artLines) {
        $parts = $artLine -split "`t", 2
        $artId = $parts[0]
        $artName = if ($parts.Count -gt 1) { $parts[1] } else { $artId }
        if ([string]::IsNullOrWhiteSpace($artId)) { continue }
        if ($artName -match 'BcptTestResults|PageScriptingTestResult') { continue }

        $zipPath = Join-Path $WorkDirectory "artifact-$artId.zip"
        $extractDir = Join-Path $WorkDirectory "artifact-$artId"
        if (-not (Save-GitHubArtifactZip -Repository $Repository -ArtifactId $artId -OutFile $zipPath)) {
            Write-Host "::warning::Could not download artifact '$artName' (id $artId) from run $RunId; skipping."
            continue
        }
        try {
            Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force -ErrorAction Stop
        }
        catch {
            Write-Host "::warning::Could not extract artifact '$artName' (id $artId) from run $RunId; skipping."
            continue
        }
        finally {
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        }

        foreach ($xml in @(Get-ChildItem -Path $extractDir -Filter '*.xml' -Recurse -ErrorAction SilentlyContinue)) {
            foreach ($ft in @(Get-FailedTestsFromResults -Path $xml.FullName)) {
                if ($null -eq $ft) { continue }
                $key = $ft.Key
                if ([string]::IsNullOrWhiteSpace($key)) { continue }
                if ($seen.Add($key)) { $failed.Add($ft) | Out-Null }
            }
        }
    }

    return $failed
}

<#
.Synopsis
    Builds a map of PR number -> the sorted, de-duplicated list of test keys that failed on that PR.
.Description
    Aggregates each observation's failing tests (already unioned across the PR build's attempts) into a
    per-PR set, so the result answers "which tests failed on this PR, across some/all of its attempts".
    The map is ordered by PR number and each PR's test-key list is sorted for stable, readable output.
#>
function Get-PrFailingTestsMap {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [psobject[]] $Observations
    )

    $byPr = @{}
    foreach ($obs in $Observations) {
        if ($null -eq $obs) { continue }
        $pr = if ($obs.PSObject.Properties['PrNumber']) { [string]$obs.PrNumber } else { '' }
        if ([string]::IsNullOrWhiteSpace($pr)) { continue }
        if (-not $byPr.ContainsKey($pr)) { $byPr[$pr] = New-Object 'System.Collections.Generic.HashSet[string]' }
        foreach ($ft in $obs.FailedTests) {
            if ($null -eq $ft) { continue }
            $key = $ft.Key
            if (-not [string]::IsNullOrWhiteSpace($key)) { [void]$byPr[$pr].Add($key) }
        }
    }

    $result = [ordered]@{}
    foreach ($pr in ($byPr.Keys | Sort-Object { [int]$_ })) {
        $result[$pr] = @($byPr[$pr] | Sort-Object)
    }
    return $result
}

<#
.Synopsis
    Detects cross-PR unstable tests from recent PR Build runs targeting a branch.
.Description
    The network-facing entry point for the cross-PR detector. It:
    1. Lists 'Pull Request Build' runs that either COMPLETED within the last WindowHours or are still in
       progress. Because a PR build can run for many hours, recency is measured by the run's completion
       time (updated_at), not its start time (created_at) - otherwise a build that failed would always be
       filtered out, since by the time it finishes and has uploaded test results it was created hours ago.
       To find those runs, the server-side listing looks back WindowHours + MaxBuildHours by created_at
       (wide enough to include a long build that just completed) and the completion window is then applied
       client-side. Including in-progress runs lets an instability be caught from a build whose test job
       has already finished (and uploaded results) even before the whole build completes.
    2. Resolves each run's PR number and base branch, keeping only runs that target Branch and either
       failed (completed within the window) or are still running.
    3. For each qualifying run, downloads and parses the test results from ALL of the run's attempts (a
       re-run can surface an instability that only failed in an earlier attempt). Failures are unioned per
       run; a running build that has not uploaded any results yet is simply skipped.
    4. Logs a map of PR number -> failing tests (aggregated across that PR's attempts) for visibility.
    5. Delegates to Select-CrossPrUnstableTests to keep only tests that failed on >= MinDistinctPrs
       distinct PRs. Because counting is per distinct PR, a test failing on several attempts of the SAME
       PR never qualifies on its own.

    Returns a hashtable of failing tests (keyed by the three-part test key) ready to be merged into the
    per-branch unstable-tests artifact via Add-FailedTestsToUnstableTests. Returns an empty hashtable
    when the branch is unsupported or nothing meets the threshold.

    Requires the GH_TOKEN (or GITHUB_TOKEN) environment variable for 'gh' authentication.
#>
function Find-CrossPrUnstableTests {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Branch,

        [Parameter(Mandatory = $true)]
        [string] $Repository,

        [int] $WindowHours = 3,

        # How long a PR build can run, at most. Added to WindowHours to widen the server-side created_at
        # lookback so a long build that only just completed is still listed; the WindowHours completion
        # window is then enforced client-side on updated_at. BC PR builds routinely run 5-10 hours.
        [int] $MaxBuildHours = 12,

        [int] $MinDistinctPrs = 2,

        [string] $WorkflowFile = 'PullRequestHandler.yaml',

        [int] $MaxRuns = 300,

        [Parameter(Mandatory = $true)]
        [string] $WorkDirectory
    )

    if (-not (Test-IsToleranceSupportedBranch -Branch $Branch)) {
        Write-Host "Branch '$Branch' is not supported by the test tolerance feature. Skipping."
        return @{}
    }

    $now = (Get-Date).ToUniversalTime()
    # Completion window: a completed build is only relevant if it finished within the last WindowHours.
    $completedSince = $now.AddHours(-$WindowHours)
    # Server-side created_at lookback is widened by MaxBuildHours so a long build that just completed
    # (created many hours ago) is still returned by the listing; the completion window above is enforced
    # client-side on updated_at.
    $createdSince = $now.AddHours(-($WindowHours + $MaxBuildHours))
    $sinceIso = $createdSince.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $createdFilter = [uri]::EscapeDataString(">=$sinceIso")
    Write-Host "::group::Path B · Scanning recent PR builds (branch '$Branch')"
    Write-Host "Listing '$WorkflowFile' runs targeting '$Branch' (completed within the last $WindowHours h or in progress; scanning builds created since $sinceIso) ..."

    # No status filter: we want completed runs (kept only when they failed and finished within the window)
    # and in-progress runs (kept best-effort in case their test job already uploaded results).
    $jq = '.workflow_runs[] | {id, headSha: .head_sha, status, conclusion, runAttempt: .run_attempt, createdAt: .created_at, updatedAt: .updated_at, prNumbers: [.pull_requests[]?.number], baseRefs: [.pull_requests[]?.base.ref]}'

    # Page manually instead of 'gh api --paginate', which would eagerly fetch every matching page even
    # though we only ever process the first MaxRuns runs. We request only as many pages as are needed to
    # cover MaxRuns and stop early on the last (short) page, keeping API traffic bounded during the
    # hourly schedule. The jq filter emits one compact JSON object per run, so a page yielding fewer than
    # per_page lines is the last page.
    $perPage = [math]::Min(100, [math]::Max(1, $MaxRuns))
    $maxPages = [math]::Max(1, [int][math]::Ceiling($MaxRuns / [double]$perPage))
    $lines = New-Object System.Collections.Generic.List[string]
    for ($page = 1; $page -le $maxPages; $page++) {
        $pageLines = @(gh api "/repos/$Repository/actions/workflows/$WorkflowFile/runs?event=pull_request&per_page=$perPage&page=$page&created=$createdFilter" --jq $jq 2>$null)
        if ($LASTEXITCODE -ne 0) {
            if ($page -eq 1) {
                Write-Host "::endgroup::"
                Write-Host "No PR Build runs found in the window (or the listing failed)."
                return @{}
            }
            Write-Host "::warning::Listing PR Build runs failed on page $page; proceeding with $($lines.Count) run(s) already fetched."
            break
        }
        $pageLines = @($pageLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($pageLines.Count -eq 0) { break }
        $lines.AddRange([string[]]$pageLines)
        if ($pageLines.Count -lt $perPage) { break }  # last page
    }
    if ($lines.Count -eq 0) {
        Write-Host "::endgroup::"
        Write-Host "No PR Build runs found in the window (or the listing failed)."
        return @{}
    }
    Write-Host "Found $($lines.Count) PR build run(s) created since $sinceIso; classifying ..."

    $observations = New-Object System.Collections.Generic.List[object]
    $processed = 0
    # Counters for a visible summary of what was examined vs skipped and why.
    $examinedFailed = 0      # completed + failed + finished within the window, targeting this branch
    $examinedInProgress = 0  # still running, targeting this branch (best-effort)
    $skippedNotFailure = 0   # completed but did not fail
    $skippedStaleFailed = 0  # completed + failed but finished before the window
    $skippedStatus = 0       # queued/waiting/other non-terminal status
    $skippedNotBranch = 0    # did not resolve to a PR targeting this branch
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($processed -ge $MaxRuns) { Write-Host "Reached MaxRuns ($MaxRuns); stopping."; break }

        $run = $null
        try { $run = $line | ConvertFrom-Json } catch { continue }
        if ($null -eq $run) { continue }

        # A completed run only matters if it FAILED and finished within the completion window (updated_at
        # >= now - WindowHours) - a build that completed long ago is stale and its instabilities, if any,
        # would have been picked up by an earlier run. An in-progress run may already have uploaded test
        # results from a finished test job, so include it best-effort. Everything else (completed and not
        # failed, completed but stale, queued/waiting, etc.) is skipped.
        $runType = $null
        $isCompleted = ($run.status -eq 'completed')
        if ($isCompleted) {
            if ($run.conclusion -ne 'failure') { $skippedNotFailure++; continue }
            $completedAt = $null
            if ($run.updatedAt) { try { $completedAt = [datetime]::Parse($run.updatedAt, [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal) } catch { $completedAt = $null } }
            if ($null -eq $completedAt -or $completedAt -lt $completedSince) { $skippedStaleFailed++; continue }
            $runType = 'failed'
        }
        elseif ($run.status -eq 'in_progress') {
            $runType = 'in_progress'
        }
        else {
            $skippedStatus++
            continue
        }

        # Resolve the PR number for this run's base branch. Same-repo PRs are present in pull_requests;
        # fork PRs are not, so fall back to the commit->PRs API.
        $prNumber = ''
        $baseRefs = @($run.baseRefs)
        $prNumbers = @($run.prNumbers)
        for ($i = 0; $i -lt $baseRefs.Count; $i++) {
            if ($baseRefs[$i] -eq $Branch -and $i -lt $prNumbers.Count) { $prNumber = [string]$prNumbers[$i]; break }
        }
        if ([string]::IsNullOrWhiteSpace($prNumber) -and $run.headSha) {
            $prLines = @(gh api "/repos/$Repository/commits/$($run.headSha)/pulls" --jq '.[] | {number, base: .base.ref}' 2>$null)
            foreach ($pl in $prLines) {
                if ([string]::IsNullOrWhiteSpace($pl)) { continue }
                try { $pr = $pl | ConvertFrom-Json } catch { continue }
                if ($pr -and $pr.base -eq $Branch) { $prNumber = [string]$pr.number; break }
            }
        }
        if ([string]::IsNullOrWhiteSpace($prNumber)) { $skippedNotBranch++; continue }  # not targeting this branch

        if ($runType -eq 'failed') { $examinedFailed++ } else { $examinedInProgress++ }
        $processed++
        $runId = [string]$run.id
        $runAttempt = if ($run.PSObject.Properties['runAttempt'] -and $run.runAttempt) { [int]$run.runAttempt } else { 1 }
        $runDir = Join-Path $WorkDirectory "run-$runId"
        $attemptText = if ($runAttempt -gt 1) { "$runAttempt attempts" } else { '1 attempt' }
        $statusText = if ($runType -eq 'failed') { 'completed/failed' } else { 'in progress' }
        Write-Host "Downloading test results from PR #$prNumber build (run $runId, $statusText, $attemptText) ..."
        # Gather failures across every attempt of this run (see Get-RunFailedTestsAllAttempts). Attempts of
        # the same run belong to the same PR, so they never inflate the distinct-PR count below. Wrap in @()
        # so an empty result (e.g. a running build with no uploaded artifacts yet) yields an empty array
        # rather than $null, whose '.Count' would throw under StrictMode.
        $runFailed = @(Get-RunFailedTestsAllAttempts -Repository $Repository -RunId $runId -WorkDirectory $runDir)
        if ($runFailed.Count -eq 0) { continue }

        $observations.Add([pscustomobject]@{
            PrNumber    = $prNumber
            RunId       = $runId
            RunAttempt  = $runAttempt
            FailedTests = $runFailed
        }) | Out-Null
    }

    $examinedTotal = $examinedFailed + $examinedInProgress
    Write-Host "::endgroup::"
    Write-Host "Examined $examinedTotal PR build(s) targeting '$Branch': $examinedFailed completed/failed, $examinedInProgress in progress."
    Write-Host "Skipped $($skippedNotFailure + $skippedStaleFailed + $skippedStatus + $skippedNotBranch) run(s): $skippedNotBranch not targeting '$Branch', $skippedNotFailure completed but not failed, $skippedStaleFailed failed but completed before the window, $skippedStatus queued/other status."
    Write-Host "Collected failing tests from $($observations.Count) PR build(s) targeting '$Branch'."

    # Emit the PR -> failing tests map (aggregated across each PR build's attempts) for visibility.
    $prMap = Get-PrFailingTestsMap -Observations $observations.ToArray()
    Write-Host "::group::PR -> failing tests across attempts (branch '$Branch')"
    if ($prMap.Count -eq 0) {
        Write-Host "No PR builds with failing tests in the window."
    }
    else {
        foreach ($pr in $prMap.Keys) {
            $keys = $prMap[$pr]
            Write-Host "PR #${pr}: $($keys.Count) failing test(s)"
            foreach ($k in $keys) { Write-Host "    $k" }
        }
    }
    Write-Host "::endgroup::"
    return (Select-CrossPrUnstableTests -Branch $Branch -Observations $observations.ToArray() -MinDistinctPrs $MinDistinctPrs -WindowHours $WindowHours)
}

Export-ModuleMember -Function `
    Get-ToleranceBranch, `
    Test-IsToleranceSupportedBranch, `
    Get-UnstableTestsArtifactName, `
    Get-UnstableTestKey, `
    Read-UnstableTestsList, `
    Get-FailedTestsFromResults, `
    Resolve-TestTolerance, `
    Update-TestResultsForTolerance, `
    Test-ShouldTolerateFailures, `
    Receive-UnstableTestsArtifact, `
    Update-UnstableTestsList, `
    Find-UnstableTestRunIds, `
    Get-FailedTestsFromRuns, `
    ConvertTo-UnstableTestEntry, `
    Save-UnstableTestsArtifact, `
    Add-FailedTestsToUnstableTests, `
    Select-CrossPrUnstableTests, `
    Get-PrFailingTestsMap, `
    Find-CrossPrUnstableTests
