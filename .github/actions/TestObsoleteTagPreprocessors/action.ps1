# Current path is .github/actions/TestObsoleteTagPreprocessors

Import-Module "$PSScriptRoot\..\..\..\build\scripts\TestObsoleteTagPreprocessors.psm1" -Force

# Exception list for testing files (files that are used in testing and should be ignored).
# These are test libraries/fixtures that legitimately contain ObsoleteTag properties
# outside of preprocessor blocks.
$exceptionList = @(
    "src\Layers\W1\Tests\TestLibraries\MergeDuplicateObsolete.Table.al",
    "src\Layers\W1\Tests\TestLibraries\ObsoleteRemovedTable.Table.al",
    "src\Layers\W1\Tests\TestLibraries\TableWithRemovedField.Table.al",
    "src\Layers\W1\Tests\Upgrade\DataSetup\TableStateObsoleteRemoved.Table.al"
)

Write-Host "Checking ObsoleteTag preprocessor compliance in .al files..."
Write-Host "Using $($exceptionList.Count) predefined exception(s) for test files"

# Initialize array to store any invalid ObsoleteTag issues
$obsoleteTagIssues = @()

$alfiles = (Get-ChildItem -Filter '*.al' -Recurse) | Select-Object -ExpandProperty FullName
foreach ($file in $alfiles) {
    # Call the Test-ObsoleteTagPreprocessors function with the file path and exception list
    $result = Test-ObsoleteTagPreprocessors -filePath $file -ExceptionList $exceptionList
    if ($null -ne $result) {
        $obsoleteTagIssues += $result.Issues
    }
}

if ($obsoleteTagIssues.Count -gt 0) {
    throw "ObsoleteTag properties found outside preprocessor blocks:`n$($obsoleteTagIssues -join "`n")"
}

Write-Host "All ObsoleteTag properties are properly surrounded by preprocessor symbols."
