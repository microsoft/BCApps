<#
    .SYNOPSIS
    Tests that all test object IDs are within the specified range and that there are no duplicate object IDs,
    except for those explicitly allowed.
    .DESCRIPTION
    This function scans the specified source code paths for AL files, extracts the object IDs of test objects,
    and checks if they fall within the defined range. It also checks for duplicate object IDs across all objects,
    excluding those listed in the AllowedDuplicateObjects parameter. If any violations are found, an error is thrown.
    .PARAMETER SourceCodePaths
    An array of paths to the source code directories to be scanned for AL files.
    .PARAMETER AllowedDuplicateObjects
    An array of object signatures (in the format "<object type> <object id>") that are allowed to have duplicates.
    .PARAMETER AllowedOutOfRangeTestObjects
    An array of test object IDs that are allowed to be outside the valid range (e.g. country-specific test objects).
    .PARAMETER MinTestObjectId
    The minimum valid object ID for test objects. Default is 130000.
    .PARAMETER MaxTestObjectId
    The maximum valid object ID for test objects. Default is 149999.
    .PARAMETER SkipDuplicateCheck
    If specified, the duplicate object ID check is skipped.
#>
function Test-ObjectIDsAreValid {
    param(
        [string[]] $SourceCodePaths = @(),
        [string[]] $AllowedDuplicateObjects = @(),
        [int[]] $AllowedOutOfRangeTestObjects = @(),
        [int] $MinTestObjectId = 130000,
        [int] $MaxTestObjectId = 149999,
        [switch] $SkipDuplicateCheck
    )

    $ApplicationObjects = Get-FilesCollection -SourceCodePaths $SourceCodePaths

    $IntroducedDuplicates = @()
    if (-not $SkipDuplicateCheck) {
        $IntroducedDuplicates = @($ApplicationObjects.DuplicateObjects | Where-Object { -not ($AllowedDuplicateObjects -contains $_) })
    }

    $offendingObjects = @()
    foreach ($TestObject in $ApplicationObjects.TestObjects) {
        $ObjectID = GetObjectId $TestObject
        if (($ObjectID -lt $MinTestObjectId) -or ($ObjectID -gt $MaxTestObjectId)) {
            if (-not ($AllowedOutOfRangeTestObjects -contains $ObjectID)) {
                $offendingObjects += $ObjectID
            }
        }
    }

    if ($IntroducedDuplicates.Count -gt 0) {
        Write-Host "##[error]Clashing object IDs detected: $($IntroducedDuplicates -join ',')"
    }

    if ($offendingObjects.Count -gt 0) {
        Write-Host "##[error]Test objects out-of-range ($MinTestObjectId..$MaxTestObjectId): $($offendingObjects -join ',')"
    }

    if (($IntroducedDuplicates.Count -gt 0) -or ($offendingObjects.Count -gt 0)) {
        throw "Object ID validation failed. When adding new test objects, ensure that their IDs are within the valid range and do not clash with existing object IDs."
    }
}

<#
    .SYNOPSIS
    Tests that all application IDs are unique across the provided source code paths.
    .DESCRIPTION
    This function scans the specified source code paths for app.json files, extracts the application IDs,
    and checks for duplicates. If any duplicate application IDs are found, an error is thrown.
    .PARAMETER SourceCodePaths
    An array of paths to the source code directories to be scanned for app.json files.
    .PARAMETER Exceptions
    An array of application IDs that are exceptions and should not be considered duplicates.
#>
function Test-ApplicationIds {
    param(
        [string[]] $SourceCodePaths = @(),
        [string[]] $Exceptions = @()
    )
    $appJsons = Get-ChildItem -Path $SourceCodePaths -File -Recurse -Filter 'app.json'
    $appIds = @()
    foreach ($appJson in $appJsons) {
        $appManifest = Get-Content -Path $appJson.FullName | Out-String | ConvertFrom-Json
        $appIds += $appManifest.id
    }
    $duplicateAppIds = $appIds | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name
    $duplicateAppIds = $duplicateAppIds | Where-Object { -not ($Exceptions -contains $_) }
    if ($duplicateAppIds.Count -gt 0) {
        Write-Host "##[error]Duplicate app IDs detected: $($duplicateAppIds -join ',')"
        throw "Duplicate app IDs detected. When adding new apps, ensure that introduced app IDs are unique."
    }
}

<#
    .SYNOPSIS
    Tests that all test objects are categorized correctly with allowed test types.
    .DESCRIPTION
    This function scans the specified source code paths for AL files, identifies test objects,
    and checks their TestType property. It ensures that all test objects have a TestType that is
    within the allowed list, except for those listed in the Exceptions parameter.
    .PARAMETER SourceCodePaths
    An array of paths to the source code directories to be scanned for AL files.
    .PARAMETER AllowedTestTypes
    An array of allowed test types. Default is "UnitTest", "IntegrationTest", and "AITest".
    .PARAMETER Exceptions
    An array of object IDs that are exceptions
#>
function Test-ApplicationTestTypes {
    param(
        [string[]] $SourceCodePaths = @(),
        [string[]] $AllowedTestTypes = @("UnitTest", "IntegrationTest", "AITest"),
        [string[]] $Exceptions = @()
    )
    $alFiles = Get-ChildItem -Path $SourceCodePaths -File -Recurse -Filter '*.al'
    $uncategorizedTests = @()
    foreach ($alFile in $alFiles) {
        if (IsTestObject -FilePath $alFile.FullName) {
            $testType = GetTestType -FilePath $alFile.FullName
            $objectId = GetALObjectInformation -FilePath $alFile.FullName | Select-Object -ExpandProperty ObjectId

            if (($null -eq $testType) -or ($null -eq $objectId)) {
                continue
            }

            if ($Exceptions -contains $objectId) {
                Write-Host "Test object ID $objectId in file $($alFile.FullName) is in the list of exceptions."
                continue
            }

            if (-not ($AllowedTestTypes -contains $testType)) {
                $uncategorizedTests += "$objectId"
            }
        }
    }
    if ($uncategorizedTests.Count -gt 0) {
        Write-Host "##[error]Found new added test objects with Uncategorized TestType: $($uncategorizedTests -join ','). Allowed TestTypes are: $($AllowedTestTypes -join ',')"
        throw "Invalid test types detected. When adding new test objects, ensure that their TestType is one of the following: $($AllowedTestTypes -join ', ')."
    }
}

<#
    .SYNOPSIS
    Scans the provided source code paths for AL files and extracts object signatures, test objects, and duplicate objects.
    .DESCRIPTION
    This function recursively scans the specified source code paths for AL files, extracts object signatures (in the format "<object type> <object id>"),
    identifies test objects, and detects duplicate object signatures. It returns a custom object containing three properties:
    - ObjectSignatures: A hash map of all unique object signatures and their corresponding names.
    - TestObjects: An array of object signatures that are identified as test objects.
    - DuplicateObjects: An array of object signatures that are found to be duplicates across the scanned files.
    .PARAMETER SourceCodePaths
    An array of paths to the source code directories to be scanned for AL files.
    .PARAMETER ObjectTypePattern
    A regular expression alternation of the AL object types to recognize. Defaults to the primary six
    ID-bearing types so that existing callers (the duplicate and test object checks) are unaffected.
    .OUTPUTS
    A custom object with the following properties:
    - ObjectSignatures: A hash map of unique object signatures and their names.
    - TestObjects: An array of test object signatures.
    - DuplicateObjects: An array of duplicate object signatures.
#>
function Get-FilesCollection
(
    [string[]] $SourceCodePaths,
    [string] $ObjectTypePattern = 'codeunit|page|table|query|report|xmlport'
) {
    $SourceFiles = @{}
    $ObjectDetails = @{}
    $TestObjectSignatures = @()
    $DuplicateObjectSignatures = @()

    foreach ($Path in $SourceCodePaths) {
        if (-not (Test-Path -Path $Path)) {
            Write-Host "The provided path '$Path' does not exist and will be skipped."
            continue
        }
        $filesInPath = Get-ChildItem -Path $Path -File -Recurse -Filter '*.al'
        foreach ($file in $filesInPath) {
            $objectInfo = GetALObjectInformation -FilePath $file.FullName -ObjectTypePattern $ObjectTypePattern
            if ($null -eq $objectInfo) {
                continue
            }

            if (-not $SourceFiles.ContainsKey($objectInfo.Signature)) {
                if (IsTestObject -FilePath $file.FullName) {
                    $TestObjectSignatures += $objectInfo.Signature
                }
                $SourceFiles.Add($objectInfo.Signature, $objectInfo.ObjectName)
                $ObjectDetails.Add($objectInfo.Signature, [PSCustomObject] @{
                        ObjectType = $objectInfo.ObjectType
                        ObjectId   = $objectInfo.ObjectId
                        ObjectName = $objectInfo.ObjectName
                        Signature  = $objectInfo.Signature
                        Path       = $file.FullName
                    })
            }
            else {
                $DuplicateObjectSignatures += $objectInfo.Signature
                Write-Warning "Object signature $($objectInfo.Signature) is used for multiple objects"
            }
        }
    }

    return [PSCustomObject] @{
        ObjectSignatures = $SourceFiles
        ObjectDetails    = $ObjectDetails
        TestObjects      = $TestObjectSignatures
        DuplicateObjects = $DuplicateObjectSignatures
    }
}

function GetALObjectInformation
(
    [string] $FilePath,
    [string] $ObjectTypePattern = 'codeunit|page|table|query|report|xmlport'
) {
    # (?<!\/\/.*) - negative lookbehind to exclude the comments on top of the file containing object signatures, for example:
    # // These tests rely on codeunit 138704 "Reten. Pol. Test Installer"
    #codeunit 138703 "Reten. Pol. Allowed Tbl. Test"
    $RegexPattern = "(?<!\/\/.*)($ObjectTypePattern) (\d+) (.*)"
    $MatchedString = Select-String -Path $FilePath -List -Pattern $RegexPattern

    if ($null -eq $MatchedString) {
        return $null
    }

    if ($MatchedString.Matches.Success) {
        $objectType = $MatchedString.Matches[0].Groups[1].Value.ToLower()
        $ObjectId = $MatchedString.Matches[0].Groups[2].Value
        $ObjectName = $MatchedString.Matches[0].Groups[3].Value -replace '"', ''
        $ObjectSignature = ($objectType + ' ' + $objectId).ToLower()
        return @{
            ObjectType = $objectType
            ObjectId   = $ObjectId
            ObjectName = $ObjectName
            Signature  = $ObjectSignature
        }
    }

    return $null
}

<#
    .SYNOPSIS
    Tests that all application manifests in the specified path have the expected application versions, platform version and publisher name.
    .DESCRIPTION
    This function scans the specified path for app.json files, extracts the application and platform versions,
    and checks if they match the expected values. If any discrepancies are found, an error is thrown.
    .PARAMETER Path
    An array of paths to the source code directories to be scanned for app.json files.
    .PARAMETER ExpectedAppVersion
    The expected application version that should be present in the app manifests.
    .PARAMETER ExpectedPlatformVersion
    The expected platform version that should be present in the app manifests.
#>
function Test-ApplicationManifests {
    param(
        [string[]] $Path,
        [string] $ExpectedAppVersion,
        [string[]] $ExpectedPlatformVersions
    )
    $appManifests = Get-ChildItem -Path $Path -File -Recurse -Filter 'app.json'
    $errors = @()
    foreach ($appManifestFile in $appManifests) {
        $appManifest = Get-Content -Path $appManifestFile.FullName | ConvertFrom-Json

        # Check App Version
        if ($appManifest.version -ne $ExpectedAppVersion) {
            $errors += "ERROR: Wrong application version in manifest $appManifestFile. Expected: $ExpectedAppVersion. Actual: $($appManifest.version)"
        }

        # Check Platform Version
        if ($ExpectedPlatformVersions -and ($appManifest.platform -notin $ExpectedPlatformVersions)) {
            $errors += "ERROR: Wrong platform version in manifest $appManifestFile. Expected one of: $($ExpectedPlatformVersions -join ', '). Actual: $($appManifest.platform)"
        }

        # Check Dependency Versions
        foreach ($dependency in $appManifest.dependencies) {
            if ($dependency.version -ne $ExpectedAppVersion) {
                $errors += "ERROR: Wrong dependency version for $($dependency.name) in manifest $appManifestFile. Expected: $ExpectedAppVersion. Actual: $($dependency.version)"
            }
        }

        # Check Publisher
        if ($appManifest.publisher -ne "Microsoft") {
            if (($appManifest.name -in @("System Application Partner Test", "AI Partner Test")) -and ($appManifest.publisher -eq "Partner")) {
                Write-Host "Allowing Partner publisher for app $($appManifest.name)"
            } else {
                $errors += "ERROR: Wrong publisher in manifest $appManifestFile. Expected: Microsoft. Actual: $($appManifest.publisher)"
            }
        }
    }

    if ($errors.Count -gt 0) {
        $errors | ForEach-Object { Write-Host "##[error]$_" }
        throw "Application manifest validation failed. Please fix the errors reported."
    }

}

function IsTestObject
(
    [string] $FilePath
) {
    $RegexPattern = '(?<!\/\/.*)Subtype\s+=\s+Test\s*;'
    $MatchedString = Select-String -Path $FilePath -List -Pattern $RegexPattern

    if ($null -eq $MatchedString) {
        return $false
    }

    return ($MatchedString.Matches.Success -eq $true)
}

function GetTestType
(
    [string] $FilePath
) {
    $RegexPattern = '(?<!\/\/.*)TestType\s+=\s+(\w+)\s*;'
    $MatchedString = Select-String -Path $FilePath -List -Pattern $RegexPattern

    if ($null -eq $MatchedString) {
        return $null
    }

    if ($MatchedString.Matches.Success) {
        return $MatchedString.Matches[0].Groups[1].Value
    }

    return $null
}

function GetObjectId
(
    [string] $TypeAndIdString
)
{
    $TypeAndId = $TypeAndIdString -split ' '
    $ObjectId = $TypeAndId[1]
    return $ObjectId -as [int]
}

function Get-JsonPropertyValue {
    param(
        [object] $InputObject,
        [string[]] $PropertyPath
    )

    $currentValue = $InputObject
    foreach ($propertyName in $PropertyPath) {
        if ($null -eq $currentValue) {
            return $null
        }
        $property = $currentValue.PSObject.Properties[$propertyName]
        if ($null -eq $property) {
            return $null
        }
        $currentValue = $property.Value
    }

    return $currentValue
}

<#
    .SYNOPSIS
    Determines whether an object ID falls within any of the provided allowed ranges.
    .DESCRIPTION
    Returns $true if the given numeric object ID is contained (inclusively) in at least one of the
    allowed ranges, otherwise $false.
    .PARAMETER ObjectId
    The numeric object ID to validate.
    .PARAMETER AllowedRanges
    An array of range objects, each exposing integer 'From' and 'To' properties (inclusive bounds).
#>
function Test-IsObjectIdInAllowedRange {
    param(
        [Parameter(Mandatory = $true)] [int64] $ObjectId,
        [Parameter(Mandatory = $true)] [object[]] $AllowedRanges
    )

    foreach ($range in $AllowedRanges) {
        if (($ObjectId -ge [int64]$range.From) -and ($ObjectId -le [int64]$range.To)) {
            return $true
        }
    }

    return $false
}

<#
    .SYNOPSIS
    Returns the objects that are newly introduced in the current source compared to a base object collection.
    .DESCRIPTION
    An object is considered "introduced" when its signature ("<object type> <object id>") is present in the
    current collection but absent from the base collection. As a result, brand new objects and renumbered
    objects (which yield a new signature) are returned, while unchanged objects, edited objects that keep the
    same object type and ID, renamed or moved objects that keep the same signature, and deleted objects are
    not returned.
    .PARAMETER CurrentObjects
    The object collection (as returned by Get-FilesCollection) for the current source code.
    .PARAMETER BaseObjects
    The object collection (as returned by Get-FilesCollection) for the base source code.
    .PARAMETER ExcludeTestObjects
    If specified, signatures identified as test objects in the current collection are excluded from the result.
    .OUTPUTS
    An array of object detail records (ObjectType, ObjectId, ObjectName, Signature, Path).
#>
function Get-IntroducedObjects {
    param(
        [Parameter(Mandatory = $true)] [object] $CurrentObjects,
        [Parameter(Mandatory = $true)] [object] $BaseObjects,
        [switch] $ExcludeTestObjects
    )

    $baseSignatures = $BaseObjects.ObjectSignatures
    $testSignatures = @($CurrentObjects.TestObjects)

    $introducedObjects = @()
    foreach ($signature in $CurrentObjects.ObjectSignatures.Keys) {
        if ($baseSignatures.ContainsKey($signature)) {
            continue
        }
        if ($ExcludeTestObjects -and ($testSignatures -contains $signature)) {
            continue
        }
        $introducedObjects += $CurrentObjects.ObjectDetails[$signature]
    }

    return @($introducedObjects)
}

<#
    .SYNOPSIS
    Tests that object IDs introduced by the current changes fall within the allowed object ID ranges.
    .DESCRIPTION
    This function compares the current object collection against a base object collection and validates that
    every newly introduced object (present now but absent in the base) has a numeric ID within one of the
    allowed ranges. Objects that already existed in the base are never flagged, even when their IDs are
    outside the allowed ranges. Test objects are excluded, because their IDs are validated separately.
    All offending introduced objects are reported (object type, ID, name and path) before an error is thrown.
    .PARAMETER CurrentObjects
    The object collection (as returned by Get-FilesCollection) for the current source code.
    .PARAMETER BaseObjects
    The object collection (as returned by Get-FilesCollection) for the base source code.
    .PARAMETER AllowedRanges
    An array of range objects, each exposing integer 'From' and 'To' properties (inclusive bounds).
    .PARAMETER AllowedOutOfRangeObjects
    An array of object signatures ("<object type> <object id>") that are explicitly allowed to be out of range.
#>
function Test-IntroducedObjectIDsAreInAllowedRange {
    param(
        [Parameter(Mandatory = $true)] [object] $CurrentObjects,
        [Parameter(Mandatory = $true)] [object] $BaseObjects,
        [Parameter(Mandatory = $true)] [object[]] $AllowedRanges,
        [string[]] $AllowedOutOfRangeObjects = @()
    )

    $introducedObjects = Get-IntroducedObjects -CurrentObjects $CurrentObjects -BaseObjects $BaseObjects -ExcludeTestObjects

    $offendingObjects = @()
    foreach ($object in $introducedObjects) {
        if ($AllowedOutOfRangeObjects -contains $object.Signature) {
            continue
        }

        $objectId = $object.ObjectId -as [int64]
        if ($null -eq $objectId) {
            continue
        }

        if (-not (Test-IsObjectIdInAllowedRange -ObjectId $objectId -AllowedRanges $AllowedRanges)) {
            $offendingObjects += $object
        }
    }

    if ($offendingObjects.Count -gt 0) {
        $rangeText = (($AllowedRanges | ForEach-Object { "$($_.From)..$($_.To)" }) -join ', ')
        foreach ($offendingObject in ($offendingObjects | Sort-Object { [int64]$_.ObjectId })) {
            Write-Host "##[error]Introduced object '$($offendingObject.ObjectType) $($offendingObject.ObjectId) $($offendingObject.ObjectName)' in file '$($offendingObject.Path)' has an ID outside the allowed range(s): $rangeText"
        }
        throw "Introduced object ID validation failed. $($offendingObjects.Count) newly introduced object(s) have IDs outside the allowed range(s) ($rangeText). Object ID ranges reserved for partners/ISVs must not be used by first-party apps. When adding new objects, ensure that their IDs are within the allowed ranges."
    }
}

<#
    .SYNOPSIS
    Resolves the base commit SHA for the current GitHub Actions workflow run.
    .DESCRIPTION
    Determines the base commit that the current changes should be compared against. For 'pull_request' (and
    'pull_request_target') events the base is read from '.pull_request.base.sha' in the event payload. For
    'merge_group' events the base is read from '.merge_group.base_sha'. When the payload cannot be read or does
    not contain the base SHA, the function falls back to 'origin/<GITHUB_BASE_REF>'. Returns $null when no base
    can be determined.
    .PARAMETER EventName
    The GitHub event name. Defaults to the GITHUB_EVENT_NAME environment variable.
    .PARAMETER EventPath
    The path to the GitHub event payload JSON file. Defaults to the GITHUB_EVENT_PATH environment variable.
    .PARAMETER BaseRef
    The base ref (target branch) name. Defaults to the GITHUB_BASE_REF environment variable.
#>
function Get-PullRequestBaseSha {
    param(
        [string] $EventName = $env:GITHUB_EVENT_NAME,
        [string] $EventPath = $env:GITHUB_EVENT_PATH,
        [string] $BaseRef = $env:GITHUB_BASE_REF
    )

    $baseSha = $null

    if (-not [string]::IsNullOrWhiteSpace($EventPath) -and (Test-Path -Path $EventPath)) {
        $eventPayload = $null
        try {
            $eventPayload = Get-Content -Path $EventPath -Raw | ConvertFrom-Json
        }
        catch {
            Write-Host "Unable to parse the GitHub event payload at '$EventPath': $($_.Exception.Message)"
        }

        if ($null -ne $eventPayload) {
            switch ($EventName) {
                'pull_request' { $baseSha = Get-JsonPropertyValue -InputObject $eventPayload -PropertyPath @('pull_request', 'base', 'sha') }
                'pull_request_target' { $baseSha = Get-JsonPropertyValue -InputObject $eventPayload -PropertyPath @('pull_request', 'base', 'sha') }
                'merge_group' { $baseSha = Get-JsonPropertyValue -InputObject $eventPayload -PropertyPath @('merge_group', 'base_sha') }
                default { $baseSha = $null }
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($baseSha) -and -not [string]::IsNullOrWhiteSpace($BaseRef)) {
        $baseSha = "origin/$BaseRef"
    }

    if ([string]::IsNullOrWhiteSpace($baseSha)) {
        return $null
    }

    return $baseSha
}

<#
    .SYNOPSIS
    Returns the object collection (as returned by Get-FilesCollection) for the given commit.
    .DESCRIPTION
    Checks out the requested commit into a temporary, detached worktree, scans the specified source paths
    (relative to the repository root) for AL objects, and returns the resulting object collection. The
    temporary worktree is always removed afterwards. When the commit is not available locally an attempt is
    made to fetch it from origin.
    .PARAMETER Commitish
    The commit SHA (or ref such as 'origin/main') to inspect.
    .PARAMETER RepositoryRoot
    The absolute path to the repository root.
    .PARAMETER RelativeSourcePaths
    The source paths to scan, relative to the repository root.
    .PARAMETER ObjectTypePattern
    A regular expression alternation of the AL object types to recognize (passed through to Get-FilesCollection).
#>
function Get-ObjectCollectionAtCommit {
    param(
        [Parameter(Mandatory = $true)] [string] $Commitish,
        [Parameter(Mandatory = $true)] [string] $RepositoryRoot,
        [Parameter(Mandatory = $true)] [string[]] $RelativeSourcePaths,
        [string] $ObjectTypePattern = 'codeunit|page|table|query|report|xmlport'
    )

    Push-Location -Path $RepositoryRoot
    try {
        & git cat-file -e "$Commitish^{commit}" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Base commit '$Commitish' is not available locally. Attempting to fetch it from origin."
            $fetchRef = $Commitish
            if ($Commitish -match '^origin/(?<BranchName>.+)$') {
                $branchName = $Matches['BranchName']
                $fetchRef = "+refs/heads/$branchName`:refs/remotes/origin/$branchName"
            }

            & git fetch --no-tags --quiet origin $fetchRef 2>$null
        }

        $resolvedCommit = (& git rev-parse --verify --quiet "$Commitish^{commit}")
        if ([string]::IsNullOrWhiteSpace($resolvedCommit)) {
            throw "Unable to resolve base commit '$Commitish'. Cannot determine introduced objects."
        }

        $worktreePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("BCApps-base-" + [System.Guid]::NewGuid().ToString('N'))
        & git worktree add --quiet --detach --force $worktreePath $resolvedCommit 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to create a temporary worktree for base commit '$resolvedCommit'."
        }

        try {
            $baseSourcePaths = @(
                $RelativeSourcePaths |
                    ForEach-Object { Join-Path -Path $worktreePath -ChildPath $_ } |
                    Where-Object { Test-Path -Path $_ }
            )
            return Get-FilesCollection -SourceCodePaths $baseSourcePaths -ObjectTypePattern $ObjectTypePattern
        }
        finally {
            & git worktree remove --force $worktreePath 2>$null
        }
    }
    finally {
        Pop-Location
    }
}

Export-ModuleMember -Function Test-ObjectIDsAreValid
Export-ModuleMember -Function Test-ApplicationIds
Export-ModuleMember -Function Test-ApplicationTestTypes
Export-ModuleMember -Function Test-ApplicationManifests
Export-ModuleMember -Function Get-FilesCollection
Export-ModuleMember -Function Get-IntroducedObjects
Export-ModuleMember -Function Test-IntroducedObjectIDsAreInAllowedRange
Export-ModuleMember -Function Test-IsObjectIdInAllowedRange
Export-ModuleMember -Function Get-PullRequestBaseSha
Export-ModuleMember -Function Get-ObjectCollectionAtCommit
