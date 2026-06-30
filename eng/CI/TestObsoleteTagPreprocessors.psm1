#Requires -Version 5.1

<#
.SYNOPSIS
    Tests if .al files with ObsoleteTag properties are properly surrounded by preprocessor symbols.

.DESCRIPTION
    This module provides functionality to check if any ObsoleteTag properties found in .al files
    (excluding comments and documentation) are properly surrounded by preprocessor symbols (#if...#endif).
#>

function Remove-CommentsAndDocumentation {
    param([string]$Content)

    # Remove single-line comments (// ...)
    $Content = $Content -replace '(?m)//.*$', ''

    # Remove multi-line comments (/* ... */)
    $Content = $Content -replace '(?s)/\*.*?\*/', ''

    # Remove XML documentation comments (/// ...)
    $Content = $Content -replace '(?m)///.*$', ''

    return $Content
}

function Find-PreprocessorBlocks {
    param([string[]]$Lines)

    $blocks = @()
    $stack = @()

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i].Trim()

        if ($line -match '^#if\b') {
            $stack += $i
        }
        elseif ($line -match '^#endif\b') {
            if ($stack.Count -gt 0) {
                $startLine = $stack[-1]
                $stack = $stack[0..($stack.Count - 2)]

                $blocks += [PSCustomObject]@{
                    StartLine = $startLine
                    EndLine = $i
                    Condition = $Lines[$startLine].Trim()
                }
            }
        }
    }

    return $blocks
}

function Test-LineInPreprocessorBlock {
    param(
        [int]$LineNumber,
        [array]$PreprocessorBlocks
    )

    foreach ($block in $PreprocessorBlocks) {
        if ($LineNumber -ge $block.StartLine -and $LineNumber -le $block.EndLine) {
            return $true
        }
    }

    return $false
}

<#
.SYNOPSIS
    Tests if ObsoleteTag properties in an .al file are properly surrounded by preprocessor symbols.

.DESCRIPTION
    Checks a single .al file to ensure that any ObsoleteTag properties are properly surrounded
    by preprocessor symbols. Returns validation results including any issues found.

.PARAMETER filePath
    The path to the .al file to check.

.PARAMETER ExceptionList
    Optional array of file paths (can be relative or absolute) to exclude from checking.

.OUTPUTS
    Returns a PSCustomObject with validation results including any issues found.
#>
function Test-ObsoleteTagPreprocessors {
    param(
        [Parameter(Mandatory = $true)]
        [string]$filePath,

        [Parameter(Mandatory = $false)]
        [string[]]$ExceptionList = @()
    )

    try {
        # Check if this file is in the exception list
        foreach ($exceptionPattern in $ExceptionList) {
            # Support both relative and absolute paths
            if ($filePath -like "*$exceptionPattern*" -or $filePath -eq $exceptionPattern) {
                return $null
            }
        }

        # Check if file exists and has content
        if (-not (Test-Path $filePath)) {
            return $null
        }

        $content = Get-Content -Path $filePath -Raw -Encoding UTF8
        if (-not $content) {
            return $null
        }

        # Remove comments and documentation
        $cleanContent = Remove-CommentsAndDocumentation -Content $content

        # Check if ObsoleteTag exists in clean content
        if ($cleanContent -notmatch '\bObsoleteTag\s*=') {
            return $null
        }

        # Split into lines for analysis
        $lines = $content -split "`r?`n"
        $cleanLines = $cleanContent -split "`r?`n"

        # Find all preprocessor blocks
        $preprocessorBlocks = Find-PreprocessorBlocks -Lines $lines

        # Find all ObsoleteTag occurrences in clean content
        $issues = @()
        $obsoleteTagLines = @()

        for ($i = 0; $i -lt $cleanLines.Count; $i++) {
            if ($cleanLines[$i] -match '\bObsoleteTag\s*=') {
                $obsoleteTagLines += $i
            }
        }

        # Check if each ObsoleteTag is within a preprocessor block
        foreach ($lineNum in $obsoleteTagLines) {
            $isInBlock = Test-LineInPreprocessorBlock -LineNumber $lineNum -PreprocessorBlocks $preprocessorBlocks

            if (-not $isInBlock) {
                $relativePath = $filePath -replace [regex]::Escape($env:INETROOT), '$INETROOT'
                $issues += "$($relativePath):$($lineNum + 1): ObsoleteTag found outside preprocessor block: $($lines[$lineNum].Trim())"
            }
        }

        # Return results if there are issues
        if ($issues.Count -gt 0) {
            return [PSCustomObject]@{
                FilePath = $filePath
                Issues = $issues
            }
        }

        return $null
    }
    catch {
        $relativePath = $filePath -replace [regex]::Escape($env:INETROOT), '$INETROOT'
        $errorIssue = "$($relativePath): Error processing file: $($_.Exception.Message)"
        return [PSCustomObject]@{
            FilePath = $filePath
            Issues = @($errorIssue)
        }
    }
}

Export-ModuleMember -Function Test-ObsoleteTagPreprocessors