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
        throw "Clashing object IDs detected: $IntroducedDuplicates. When adding new objects, ensure that introduced object IDs are not currently in use."
    }

    if ($offendingObjects.Count -gt 0) {
        throw "Test objects should be within the $MinTestObjectId..$MaxTestObjectId range. The following test objects are outside the range: $($offendingObjects -join ', ')"
    }
}

# Returns a hash map with all the application objects (entries are <object type><object id>, <object name>, e. g. { 'codeunit 10', 'Type Helper' }).
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
Export-ModuleMember -Function Get-FilesCollection