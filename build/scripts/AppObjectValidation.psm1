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
    Returns the test application folders configured by the AL-Go projects.
    .DESCRIPTION
    Reads every build project settings.json and resolves its testFolders entries to absolute paths.
    A trailing wildcard is treated as the containing test folder because every application below it is a test app.
    .PARAMETER ProjectsPath
    The directory containing the AL-Go build projects.
#>
function Get-ALGoTestFolders {
    param(
        [Parameter(Mandatory = $true)] [string] $ProjectsPath
    )

    $testFolders = @()
    $settingsFiles = Get-ChildItem -Path $ProjectsPath -File -Recurse -Filter 'settings.json' |
        Where-Object { $_.Directory.Name -eq '.AL-Go' }
    foreach ($settingsFile in $settingsFiles) {
        $settings = Get-Content -Path $settingsFile.FullName -Raw | ConvertFrom-Json
        foreach ($testFolder in @($settings.testFolders)) {
            $testFolderWithoutWildcard = $testFolder -replace '[\\/]\*$', ''
            $projectFolder = $settingsFile.Directory.Parent.FullName
            $testFolders += [System.IO.Path]::GetFullPath((Join-Path -Path $projectFolder -ChildPath $testFolderWithoutWildcard))
        }
    }

    return @($testFolders | Sort-Object -Unique)
}

function Test-IsPathUnderAnyFolder {
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [string[]] $Folders
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    foreach ($folder in $Folders) {
        $folderPrefix = [System.IO.Path]::GetFullPath($folder).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
        if ($fullPath.StartsWith($folderPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Test-IsFileInTestApplication {
    param(
        [Parameter(Mandatory = $true)] [string] $FilePath,
        [Parameter(Mandatory = $true)] [string[]] $TestFolderPaths
    )

    if (Test-IsPathUnderAnyFolder -Path $FilePath -Folders $TestFolderPaths) {
        return $true
    }
    if (IsTestObject -FilePath $FilePath) {
        return $true
    }

    $directory = [System.IO.DirectoryInfo](Split-Path -Path $FilePath -Parent)
    while ($null -ne $directory) {
        $manifestPath = Join-Path -Path $directory.FullName -ChildPath 'app.json'
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            return $manifest.name -match '(?i)\btests?\b|\btest[\s-]*librar(?:y|ies)\b|\btest[\s-]*toolkit\b'
        }
        $directory = $directory.Parent
    }

    return $false
}

<#
    .SYNOPSIS
    Tests object IDs declared in newly added production AL files.
    .DESCRIPTION
    Validates only files supplied by the caller that are under an allowed source root and not under an AL-Go
    test folder. This avoids scanning existing objects and correctly excludes non-codeunit objects in test apps.
    .PARAMETER FilePaths
    Absolute paths to files added by the current change.
    .PARAMETER SourceCodePaths
    Source roots in which production AL files are eligible for validation.
    .PARAMETER TestFolderPaths
    AL-Go test application folders that must not be checked against production ranges.
    .PARAMETER AllowedRanges
    An array of range objects, each exposing integer 'From' and 'To' properties (inclusive bounds).
    .PARAMETER ObjectTypePattern
    A regular expression alternation of the AL object types to recognize.
#>
function Test-ObjectIDsInAddedALFilesAreInAllowedRange {
    param(
        [Parameter(Mandatory = $true)] [string[]] $FilePaths,
        [Parameter(Mandatory = $true)] [string[]] $SourceCodePaths,
        [Parameter(Mandatory = $true)] [string[]] $TestFolderPaths,
        [Parameter(Mandatory = $true)] [object[]] $AllowedRanges,
        [string] $ObjectTypePattern = 'tableextension|pageextension|reportextension|enumextension|permissionsetextension|permissionset|codeunit|page|table|report|xmlport|query|enum'
    )

    $offendingObjects = @()
    foreach ($filePath in $FilePaths) {
        if ([System.IO.Path]::GetExtension($filePath) -ne '.al') {
            continue
        }
        if (-not (Test-IsPathUnderAnyFolder -Path $filePath -Folders $SourceCodePaths)) {
            continue
        }
        if (Test-IsFileInTestApplication -FilePath $filePath -TestFolderPaths $TestFolderPaths) {
            continue
        }
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            throw "Added AL file '$filePath' does not exist."
        }

        $objectInfo = GetALObjectInformation -FilePath $filePath -ObjectTypePattern $ObjectTypePattern
        if (($null -ne $objectInfo) -and (-not (Test-IsObjectIdInAllowedRange -ObjectId ([int64]$objectInfo.ObjectId) -AllowedRanges $AllowedRanges))) {
            $offendingObjects += [PSCustomObject]@{
                ObjectType = $objectInfo.ObjectType
                ObjectId   = $objectInfo.ObjectId
                ObjectName = $objectInfo.ObjectName
                Path       = $filePath
            }
        }
    }

    if ($offendingObjects.Count -gt 0) {
        $rangeText = (($AllowedRanges | ForEach-Object { "$($_.From)..$($_.To)" }) -join ', ')
        foreach ($offendingObject in ($offendingObjects | Sort-Object { [int64]$_.ObjectId })) {
            Write-Host "##[error]Object '$($offendingObject.ObjectType) $($offendingObject.ObjectId) $($offendingObject.ObjectName)' in newly added file '$($offendingObject.Path)' has an ID outside the allowed range(s): $rangeText"
        }
        throw "Object ID validation failed. $($offendingObjects.Count) object(s) in newly added AL file(s) have IDs outside the allowed range(s) ($rangeText)."
    }
}

Export-ModuleMember -Function Test-ObjectIDsAreValid
Export-ModuleMember -Function Test-ApplicationIds
Export-ModuleMember -Function Test-ApplicationTestTypes
Export-ModuleMember -Function Test-ApplicationManifests
Export-ModuleMember -Function Get-FilesCollection
Export-ModuleMember -Function Test-IsObjectIdInAllowedRange
Export-ModuleMember -Function Get-ALGoTestFolders
Export-ModuleMember -Function Test-ObjectIDsInAddedALFilesAreInAllowedRange
