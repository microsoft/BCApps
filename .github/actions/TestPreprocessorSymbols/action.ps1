# Current path is .github/actions/VerifyAppChanges

Import-Module "$PSScriptRoot\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\..\..\..\build\scripts\GuardingV2ExtensionsHelper.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\..\..\..\build\scripts\TestPreprocessorSymbols.psm1" -Force

# Get the major build version from the main branch
$mainVersion = Get-MaxAllowedObsoleteVersion

# Get the major build version from the current branch
$currentVersion = (Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go) -split '\.' | Select-Object -First 1

# CLEANSCHEMA is on a 5y cycle starting from 26
if ($CurrentVersion -le 26) {
    $schemaLowerBound = 15
} else {
    $schemaLowerBound = ([math]::Floor(($CurrentVersion - 2) / 5) * 5) - 2 # makes a series: 23, 28, 33, 38, 43 etc. This is the version is which we clean up (26, 31, 36, etc.) - 3.
}

# Define the preprocessor symbols to check for
$symbolConfigs = @(
    @{stem = "CLEAN"; lowerBound = ($CurrentVersion - 4); upperBound = $mainVersion},
    @{stem = "CLEANSCHEMA"; lowerBound = $schemaLowerBound; upperBound = $mainVersion + 3} # next lowerbound, after cleanup should be 25, then
)

Write-Host "Checking preprocessor symbols with $symbolConfigs"

#initialize arrays to store any invalid preprocessor symbols with line numbers
$invalidLowercaseSymbols = @()
$invalidPatternSymbols = @()
$invalidStemSymbols = @()

$alfiles = (Get-ChildItem -Filter '*.al' -Recurse) | Select-Object -ExpandProperty FullName
foreach ($file in $alfiles) {
    # Call the Test-PreprocessorSymbols function with the file path and calculated version bounds
    $result = Test-PreprocessorSymbols -filePath $file -symbolConfigs $symbolConfigs
    if ($null -ne $result) {
        $invalidLowercaseSymbols += $result.invalidLowercaseSymbols
        $invalidPatternSymbols += $result.invalidPatternSymbols
        $invalidStemSymbols += $result.invalidStemSymbols
    }
}

$symbolErrors = $invalidLowercaseSymbols + $invalidPatternSymbols + $invalidStemSymbols
if ($symbolErrors.Count -gt 0) {
    throw "Errors found in preprocessor symbols:`n $symbolErrors"
}