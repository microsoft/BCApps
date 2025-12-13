Import-Module "$PSScriptRoot\..\..\..\build\scripts\AppObjectValidation.psm1" -Force
Import-Module "$PSScriptRoot\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking

$sourceCodeFolder = Join-Path (Get-BaseFolder) "src" -Resolve

# Test that all test object IDs are within the valid range
Test-ObjectIDsAreValid -SourceCodePaths $sourceCodeFolder

# Test that all application IDs are unique
Test-ApplicationIds -SourceCodePaths $sourceCodeFolder

# That that test objects are categorized correctly
$allowedUncategorizedTests = @(
    139504, # Data Archive Tests
    133502,139624,139628, # E-Document Core Tests"
    148191, # E-Document Connector - Avalara Tests
    139621,139622, # Error Messages with Recommendations Tests
    139600, # Essential Business Headlines Test
    139876,139877,139878,139879,139880,139881,139875, # PowerBI Reports Tests
    139636,139568,139695,139608,139609,139611,139648,139567,139546,139551, # Shopify Connector Test
    139686,139687,139688,139689,139690,139691,139692,139693,148155,148152,139912,139913,139914,139915,139916,148160,148156,139884,139885,148157,139887,139888,139889,148158,148153,148159,139694,139895,148154, # Subscription Billing
    139610 # Send remittance advice by email Tests
)
Test-ApplicationTestTypes -SourceCodePaths $sourceCodeFolder -Exceptions $allowedUncategorizedTests

# Test that all manifests are valid
$currentMajorMinor = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go
$expectedPlatformVersion = "$($currentMajorMinor).0.0" # This can be hardcoded to a specific platform version if needed during version updates
Test-ApplicationManifests -Path $sourceCodeFolder -ExpectedAppVersion "$($currentMajorMinor).0.0" -ExpectedPlatformVersion $expectedPlatformVersion
