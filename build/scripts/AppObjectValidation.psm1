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

    # (?<!\/\/.*) - negative lookbehind to exclude the comments on top of the file containing object signatures, for example:
    # // These tests rely on codeunit 138704 "Reten. Pol. Test Installer"
    #codeunit 138703 "Reten. Pol. Allowed Tbl. Test"
    $RegexPattern = '(?<!\/\/.*)(codeunit|page|table|query|report|xmlport) (\d+) (.*)'

    foreach ($Path in $SourceCodePaths) {
        if (-not (Test-Path -Path $Path)) {
            Write-Host "The provided path '$Path' does not exist and will be skipped."
            continue
        }
        $filesInPath = Get-ChildItem -Path $Path -File -Recurse -Filter '*.al'
        foreach ($file in $filesInPath) {
            $MatchedString = Select-String -Path $file.FullName -List -Pattern $RegexPattern
            if ($null -eq $MatchedString) {
                continue
            }
            if (-not ($MatchedString.PSObject.Properties.Name -eq "Matches")) {
                Write-Host "No matches found in file: $($file.FullName)"
                continue
            }

            if ($MatchedString.Matches.Success) {
                $objectType = $MatchedString.Matches[0].Groups[1].Value.ToLower()
                $ObjectId = $MatchedString.Matches[0].Groups[2].Value
                $ObjectName = $MatchedString.Matches[0].Groups[3].Value -replace '"', ''
                $ObjectSignature = ($objectType + ' ' + $objectId).ToLower()

                if (-not $SourceFiles.ContainsKey($ObjectSignature)) {
                    if (IsTestObject -FilePath $file.FullName) {
                        $TestObjectSignatures += $ObjectSignature
                    }
                    $SourceFiles.Add($ObjectSignature, $ObjectName)
                }
                else {
                    $DuplicateObjectSignatures += $ObjectSignature
                    Write-Warning "Object signature $ObjectSignature is used for multiple objects"
                }
            }
        }
    }

    return [PSCustomObject] @{
        ObjectSignatures = $SourceFiles
        TestObjects      = $TestObjectSignatures
        DuplicateObjects = $DuplicateObjectSignatures
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
Export-ModuleMember -Function Get-FilesCollection