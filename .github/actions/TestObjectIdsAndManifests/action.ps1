Import-Module "$PSScriptRoot\..\..\..\build\scripts\AppObjectValidation.psm1" -Force
Import-Module "$PSScriptRoot\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking

$sourceCodeFolder = Join-Path (Get-BaseFolder) "src" -Resolve

# Test that all test object IDs are within the valid range
Test-ObjectIDsAreValid -SourceCodePaths $sourceCodeFolder

# Test that all application IDs are unique
Test-ApplicationIds -SourceCodePaths $sourceCodeFolder

# Test that all manifests are valid
$currentMajorMinor = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go
Test-ApplicationManifests -Path $sourceCodeFolder -ExpectedAppVersion "$($currentMajorMinor).0.0"
