# Initialize enlistment (sets $repoRoot and loads shared modules)
. "$env:GITHUB_WORKSPACE/init.ps1"

Import-Module "$repoRoot/eng/CI/AppObjectValidation.psm1" -Force

$sourceCodeFolder = Join-Path (Get-BaseFolder) "src" -Resolve

# Base folders (everything except Apps and Layers)
$baseFolders = @(Get-ChildItem -Path $sourceCodeFolder -Directory -Exclude "Apps", "Layers" | Select-Object -ExpandProperty FullName)
# W1 Folders (For Apps and Layers)
$w1Apps = @(Join-Path $sourceCodeFolder "Apps\W1")
$w1Layers = @(Join-Path $sourceCodeFolder "Layers\W1")
# All Folders (For Apps)
$allApps = @(Join-Path $sourceCodeFolder "Apps")

# Build path sets for different validations
# Some folders (e.g. Layers) only exist on main and not on release branches, so filter out
# any paths that do not exist to avoid Get-ChildItem failing on missing directories.
[string[]] $w1OnlyPaths = @($baseFolders + $w1Apps + $w1Layers | Where-Object { Test-Path -Path $_ })
[string[]] $allPaths = @($baseFolders + $allApps + $w1Layers | Where-Object { Test-Path -Path $_ })

# Define exceptions
$AllowedDuplicateObjects = @(
                            "table 230", # Source Code
                            "table 231", # Reason Code
                            "table 242", # Source Code Setup
                            "table 308", # No. Series
                            "table 309", # No. Series Line
                            "table 310", # No. Series Relationship
                            "table 1263", # No. Series Tenant
                            "table 6635", # Return Reason
                            "table 12145", # No. Series Line Sales
                            "table 12146" # No. Series Line Purchase
)

# Test that all application IDs are unique (Base Folders + All Apps and W1 Layer)
$duplicateApplicationIds = @(
                            "bd16d8dd-8faf-45d3-b733-3ddc6b9cfabf", # Bug 592283
                            "f3e4e6f8-2ba7-4202-834d-141ed9b89192"
)

# Exception - Out of range test object IDs
$outOfRangeTestObjects = @(
    13918,13922,13923,13924,13925,13926, # E-Document for Germany Tests
    10505, # Intrastat GB Tests
    18649, # Fixed Asset Depreciation Tests
    18078,18427,18428,18429,18460,18488, # GST Base Tests
    18271,18272,18273, # GST On Payments Tests
    18125,18126,18127,18128,18131,18132, # GST Purchase Automation
    18133,18134,18135,18136,18137,18138,18139, # GST Purchase Automation (cont.)
    18191,18192,18193,18194,18196,18197,18198, # GST Sales Automation
    18479, # GST Subcontracting Automation
    18345,18346,18480,18481, # India GST Tests
    18044,18045,18046,18047, # India Reports Tests
    18990,18991, # India Charge Group Tests
    18628,18629,18630, # India Gate Entry Tests
    18996,18998,18999, # India Voucher Interface Tests
    18912, # TCS Base Test Automation
    18925,18927,18928, # TCS On Receipt Automation
    18914,18916,18917,18918,18919, # TCS on Sales Test Automation
    18921, # TCS Return and Settlement Automation
    18800, # TDS Base Tests
    18682,18683, # TDS On Customer Tests
    18790,18802,18803,18804,18805,18806, # TDS on Payments Tests
    18791,18792,18793,18794, # TDS on Purchase Tests
    18797 # TDS Return and Settlement Tests
)

# Test that object IDs don't clash and test objects are in valid range (W1 only)
Test-ObjectIDsAreValid -SourceCodePaths $w1OnlyPaths -AllowedDuplicateObjects $AllowedDuplicateObjects

# Test that all test object IDs are within the valid range (all apps - country test objects excepted)
Test-ObjectIDsAreValid -SourceCodePaths $allPaths  -AllowedOutOfRangeTestObjects $outOfRangeTestObjects -SkipDuplicateCheck

# Test that all application IDs are unique (all paths)
Test-ApplicationIds -SourceCodePaths $allPaths -Exceptions $duplicateApplicationIds

# Test that all manifests are valid
$currentMajorMinor = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go
$currentMajor = [int]($currentMajorMinor -split '\.')[0]
$expectedPlatformVersionCurrent = "$currentMajor.0.0.0"
$expectedPlatformVersionPrevious = "$($currentMajor - 1).0.0.0"
Test-ApplicationManifests -Path $allPaths -ExpectedAppVersion "$($currentMajorMinor).0.0" -ExpectedPlatformVersions @($expectedPlatformVersionCurrent, $expectedPlatformVersionPrevious)

# Test that we are not adding new uncategorized tests (W1 only) - Disabled for now
# Test-ApplicationTestTypes -SourceCodePaths $w1OnlyPaths -Exceptions $allowedUncategorizedTests