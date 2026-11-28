<#
.SYNOPSIS
    This script checks the preprocessor symbols in an AL file.

.DESCRIPTION
    Uses the native text reader to select lines containing '#', retaining original
    line numbers. All '#' lines, including inline occurrences, use the same checks.
    This script checks the preprocessor symbols in an AL file for the following:
    - Ensures there is no space after the '#' character.
    - Ensures preprocessor symbols have uppercase stems.
    - Ensures preprocessor symbols are within a specified range.
    - Ensures preprocessor symbols are in the correct format.
    - Ensures preprocessor symbols are not in lowercase.

.PARAMETER filePath
    The path to the file to be checked.

.PARAMETER symbolConfigs
    An array of objects where each entry has a stem, an upper, and a lower bound.

.EXAMPLE
    $alfiles = Get-ChildItem -Recurse -Filter *.al -Path .\App\
    foreach ($alfile in $alfiles) {
        $symbolConfigs = @(
            @{stem="CLEAN"; lowerBound=22; upperBound=26},
            @{stem="CLEANSCHEMA"; lowerBound=22; upperBound=26}
        )
        Test-PreprocessorSymbols -filePath $alfile.FullName -symbolConfigs $symbolConfigs
    }

.NOTES
    Author: Gert Robyns
    Date: 2024-09-03

    Updated by: Gert Robyns
    Date: 2024-09-20
#>
function Test-PreprocessorSymbols {
    param (
        [Parameter(Mandatory=$true)]
        [string]$filePath,
        [Parameter(Mandatory=$true)]
        [hashtable[]]$symbolConfigs
    )

    # check if extension is .al, else return $null
    if ('.al' -ne [system.io.path]::GetExtension($filePath)) {
        return $null
    }

    $matchingLines = Select-String -LiteralPath $filePath -Pattern '#' -SimpleMatch -ErrorAction Stop
    if ($null -eq $matchingLines) {
        return $null
    }

    # Define the regex pattern for disallowing a space after #
    $noSpaceAfterHashPattern = "^#\s"
    $lowercasePattern = "^#(if|elseif|else\b|endif)"
    $lowercaseNotPattern = "^#if not "
    $symbolPattern = @()

    foreach ($config in $symbolConfigs) {
        $stem = $config.stem
        $lowerBound = $config.lowerBound
        $upperBound = $config.upperBound

        # Generate the regex pattern for the SymbolStem range
        $rangePattern = "$($lowerBound..$upperBound -join '|')"

        $upperStem = $stem.ToUpper()
        $symbolPattern += "^#if\s${upperStem}($rangePattern)"
        $symbolPattern += "^#if\snot\s${upperStem}($rangePattern)"
        $symbolPattern += "^#elseif\s${upperStem}($rangePattern)"
    }

    # Add #endif to the symbol pattern but not to the strict pattern
    $symbolPattern += "#else\b"
    $symbolPattern += "#endif"

    # Initialize lists to store any invalid preprocessor symbols with line numbers
    $invalidLowercaseSymbols = @()
    $invalidPatternSymbols = @()
    $invalidStemSymbols = @()

    foreach ($match in $matchingLines) {
        $line = $match.Line
        $lineNumber = $match.LineNumber

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
        foreach ($config in $symbolConfigs) {
            $stem = $config.stem
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

Export-ModuleMember -Function Test-PreprocessorSymbols