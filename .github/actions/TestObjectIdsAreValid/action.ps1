Import-Module "$PSScriptRoot\..\..\..\build\scripts\AppObjectValidation.psm1" -Force
Import-Module "$PSScriptRoot\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking

$sourceCodeFolder = Join-Path (Get-BaseFolder) "src" -Resolve

Test-ObjectIDsAreValid -SourceCodePaths $sourceCodeFolder