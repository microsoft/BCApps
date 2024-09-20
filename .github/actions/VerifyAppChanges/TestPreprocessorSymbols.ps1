# Current path is .github/actions/VerifyAppChanges

Import-Module "$PSScriptRoot\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\..\..\..\build\scripts\GuardingV2ExtensionsHelper.psm1" -DisableNameChecking

<#
.SYNOPSIS
    Verifies preprocessor symbols in a given file.

.DESCRIPTION
    This function checks for the following in the specified file:
    - Ensures preprocessor symbols are lowercased.
    - Ensures preprocessor symbols match the specified patterns.
    - Ensures preprocessor symbols have uppercase stems.
    - Ensures there is no space after the '#' character.

.PARAMETER filePath
    The path to the file to be checked.

.PARAMETER symbolStems
    An array of symbol stems to be checked.

.PARAMETER lowerBound
    The lower bound for the CLEANxx pattern.

.PARAMETER upperBound
    The upper bound for the CLEANxx pattern.

.EXAMPLE
    $alfiles = Get-ChildItem -Recurse -Filter *.al -Path .\App\
    foreach ($alfile in $alfiles) {
        Test-PreprocessorSymbols -filePath $alfile.FullName -symbolStems @("CLEAN", "CLEANSCHEMA") -lowerBound 22 -upperBound 26
    }

.NOTES
    Author: Gert Robyns
    Date: 2024-09-03
#>
function Test-PreprocessorSymbols {
    param (
        [Parameter(Mandatory=$true)]
        [string]$filePath,
        [Parameter(Mandatory=$true)]
        [string[]]$symbolStems,
        [Parameter(Mandatory=$true)]
        [int]$lowerBound,
        [Parameter(Mandatory=$true)]
        [int]$upperBound
    )

    # check if extension is .al, else return $null
    if ('.al' -ne [system.io.path]::GetExtension($filePath)) {
        return $null
    }

    # Generate the regex pattern for the CLEANxx range
    $rangePattern = "$($lowerBound..$upperBound -join '|')"

    # Define the regex patterns for the preprocessor symbols and the configurable stems
    # Define the regex pattern for disallowing a space after #
    $noSpaceAfterHashPattern = "^#\s"
    $lowercasePattern = "^#(if|elseif|else\b|endif)"
    $lowercaseNotPattern = "^#if not "
    $symbolPattern = @()

    foreach ($stem in $symbolStems) {
        $upperStem = $stem.ToUpper()
        $symbolPattern += "^#if\s${upperStem}($rangePattern)"
        $symbolPattern += "^#if\snot\s${upperStem}($rangePattern)"
        $symbolPattern += "^#elseif\s${upperStem}($rangePattern)"
    }

    # Add #endif to the symbol pattern but not to the strict pattern
    $symbolPattern += "#else\b"
    $symbolPattern += "#endif"

    # Read the content of the file
    $content = Get-Content -Path $filePath

    # Initialize lists to store any invalid preprocessor symbols with line numbers
    $invalidLowercaseSymbols = @()
    $invalidPatternSymbols = @()
    $invalidStemSymbols = @()

    # Iterate through each line in the file content with line numbers
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]
        $lineNumber = $i + 1

        # Check for space after #
        if ($line -cmatch $noSpaceAfterHashPattern) {
            $invalidPatternSymbols += "${filePath}:${lineNumber}: $line"
        }

        # Check for lowercase
        if (($line -match $lowercasePattern) -and ($line -cnotmatch $lowercasePattern)) {
                $invalidLowercaseSymbols += "${filePath}:${lineNumber}: $line"
        }

        # Check for lowercase not
        if (($line -match $lowercaseNotPattern) -and ($line -cnotmatch $lowercaseNotPattern)) {
            $invalidLowercaseSymbols += "${filePath}:${lineNumber}: $line"
        }

        # Check for strict pattern match
        $isValidPattern = $false
        foreach ($pattern in $symbolPattern) {
            if ($line -match $pattern) {
                $isValidPattern = $true
                break
            }
        }
        if ($line -match $lowercasePattern -and -not $isValidPattern -and $line -notmatch "^#endif") {
            $invalidPatternSymbols += "${filePath}:${lineNumber}: $line"
        }

        # Check for uppercase stem
        foreach ($stem in $symbolStems) {
            $upperStem = $stem.ToUpper()
            if ($line -match "#(if|if not|elseif)\s+${stem}($rangePattern)" -and $line -cnotmatch "#((?i)(if|if not|elseif))\s+${upperStem}($rangePattern)") {
                $invalidStemSymbols += "${filePath}:${lineNumber}: $line"
            }
        }
    }

    if (($invalidLowercaseSymbols.Count -gt 0) -or ($invalidPatternSymbols -gt 0) -or ($invalidStemSymbols -gt 0)) {
        return @{ "invalidLowercaseSymbols" = $invalidLowercaseSymbols; "invalidPatternSymbols" = $invalidPatternSymbols; "invalidStemSymbols" = $invalidStemSymbols }
    } else {
        return $null
    }
}


$symbolStems = @("CLEAN")
# Get the current major version
$currentMajorVerion = (Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go) -split '\.' | Select-Object -First 1 # TODO: do better

$upperBound = Get-MaxAllowedObsoleteVersion
# Set the lower bound to the current version minus 4
$lowerBound = $currentMajorVerion - 4

Write-Host "Checking preprocessor symbols in the range $symbolStems with a lower bound of $lowerBound and an upper bound of $upperBound"

#initialize arrays to store any invalid preprocessor symbols with line numbers
$invalidLowercaseSymbols = @()
$invalidPatternSymbols = @()
$invalidStemSymbols = @()

$alfiles = (Get-ChildItem -Filter '*.al' -Recurse) | Select-Object -ExpandProperty FullName
foreach ($file in $alfiles) {
    # Call the Test-PreprocessorSymbols function with the file path and calculated version bounds
    $result = Test-PreprocessorSymbols -filePath $file -symbolStems $symbolStems -lowerBound $lowerBound -upperBound $upperBound
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