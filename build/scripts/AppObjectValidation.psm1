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
    .PARAMETER MinTestObjectId
    The minimum valid object ID for test objects. Default is 130000.
    .PARAMETER MaxTestObjectId
    The maximum valid object ID for test objects. Default is 149999.
#>
function Test-ObjectIDsAreValid {
    param(
        [string[]] $SourceCodePaths = @(),
        [string[]] $AllowedDuplicateObjects = @(),
        [int] $MinTestObjectId = 130000,
        [int] $MaxTestObjectId = 149999
    )

    $ApplicationObjects = Get-FilesCollection -SourceCodePaths $SourceCodePaths
    $IntroducedDuplicates = @($ApplicationObjects.DuplicateObjects | Where-Object { -not ($AllowedDuplicateObjects -contains $_) })

    $offendingObjects = @()
    foreach ($TestObject in $ApplicationObjects.TestObjects) {
        $ObjectID = GetObjectId $TestObject
        if (($ObjectID -lt $MinTestObjectId) -or ($ObjectID -gt $MaxTestObjectId)) {
            $offendingObjects += $ObjectID
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
    .OUTPUTS
    A custom object with the following properties:
    - ObjectSignatures: A hash map of unique object signatures and their names.
    - TestObjects: An array of test object signatures.
    - DuplicateObjects: An array of duplicate object signatures.
#>
function Get-FilesCollection
(
    [string[]] $SourceCodePaths
) {
    $SourceFiles = @{}
    $TestObjectSignatures = @()
    $DuplicateObjectSignatures = @()

    foreach ($Path in $SourceCodePaths) {
        if (-not (Test-Path -Path $Path)) {
            Write-Host "The provided path '$Path' does not exist and will be skipped."
            continue
        }
        $filesInPath = Get-ChildItem -Path $Path -File -Recurse -Filter '*.al'
        foreach ($file in $filesInPath) {
            $objectInfo = GetALObjectInformation -FilePath $file.FullName
            if ($null -eq $objectInfo) {
                continue
            }

            if (-not $SourceFiles.ContainsKey($objectInfo.Signature)) {
                if (IsTestObject -FilePath $file.FullName) {
                    $TestObjectSignatures += $objectInfo.Signature
                }
                $SourceFiles.Add($objectInfo.Signature, $objectInfo.ObjectName)
            }
            else {
                $DuplicateObjectSignatures += $objectInfo.Signature
                Write-Warning "Object signature $($objectInfo.Signature) is used for multiple objects"
            }
        }
    }

    return [PSCustomObject] @{
        ObjectSignatures = $SourceFiles
        TestObjects      = $TestObjectSignatures
        DuplicateObjects = $DuplicateObjectSignatures
    }
}

function GetALObjectInformation
(
    [string] $FilePath
) {
    # (?<!\/\/.*) - negative lookbehind to exclude the comments on top of the file containing object signatures, for example:
    # // These tests rely on codeunit 138704 "Reten. Pol. Test Installer"
    #codeunit 138703 "Reten. Pol. Allowed Tbl. Test"
    $RegexPattern = '(?<!\/\/.*)(codeunit|page|table|query|report|xmlport) (\d+) (.*)'
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
    The path to the source code directory to be scanned for app.json files.
    .PARAMETER ExpectedAppVersion
    The expected application version that should be present in the app manifests.
    .PARAMETER ExpectedPlatformVersion
    The expected platform version that should be present in the app manifests.
#>
function Test-ApplicationManifests {
    param(
        [string] $Path,
        [string] $ExpectedAppVersion,
        [string] $ExpectedPlatformVersion
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
        if ($ExpectedPlatformVersion -and ($appManifest.platform -ne $ExpectedPlatformVersion)) {
            $errors += "ERROR: Wrong platform version in manifest $appManifestFile. Expected: $ExpectedPlatformVersion. Actual: $($appManifest.platform)"
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

Export-ModuleMember -Function Test-ObjectIDsAreValid
Export-ModuleMember -Function Test-ApplicationIds
Export-ModuleMember -Function Test-ApplicationTestTypes
Export-ModuleMember -Function Test-ApplicationManifests
Export-ModuleMember -Function Get-FilesCollection