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

Export-ModuleMember -Function `
    Get-ToleranceBranch, `
    Test-IsToleranceSupportedBranch, `
    Get-UnstableTestsArtifactName, `
    Split-CodeunitString, `
    Get-UnstableTestKey, `
    Read-UnstableTestsList, `
    Get-FailedTestsFromResults, `
    Resolve-TestTolerance, `
    Update-TestResultsForTolerance, `
    Test-ShouldTolerateFailures, `
    Receive-UnstableTestsArtifact, `
    Update-UnstableTestsList
