Describe 'Application API baseline restoration' {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1"
        Import-Module "$PSScriptRoot\..\GuardingV2ExtensionsHelper.psm1" -Force
    }

    BeforeEach {
        Mock -ModuleName GuardingV2ExtensionsHelper Get-BaseFolder { $TestDrive }
        Mock -ModuleName GuardingV2ExtensionsHelper Import-Module {}
        foreach ($country in @('W1', 'IT')) {
            $extensions = Join-Path $TestDrive "out\baselineartifacts\1.0.0.0\$country\sandbox\1.0.0.0\$country\Extensions"
            $null = New-Item -Path $extensions -ItemType Directory -Force
            $country | Set-Content -LiteralPath (Join-Path $extensions 'Microsoft_Application_1.0.0.0.app')
            $country | Set-Content -LiteralPath (Join-Path $extensions 'Microsoft_Base Application_1.0.0.0.app')
        }
    }

    It 'populates separate AppSourceCop and aggregate caches from an already downloaded artifact' {
        $compilerCache = Join-Path $TestDrive 'compiler'
        $aggregateCache = Join-Path $TestDrive 'aggregate'
        Restore-BaselinesFromArtifacts -AppName Application -TargetFolder $compilerCache -BaselineVersion '1.0.0.0' -CountryCode W1 | Should -Be '1.0.0.0'
        Restore-BaselinesFromArtifacts -AppName Application -TargetFolder $aggregateCache -BaselineVersion '1.0.0.0' -CountryCode W1 | Should -Be '1.0.0.0'
        Get-Content -LiteralPath (Join-Path $compilerCache 'Microsoft_Base Application_1.0.0.0.app') | Should -Be 'W1'
        Get-Content -LiteralPath (Join-Path $aggregateCache 'Microsoft_Base Application_1.0.0.0.app') | Should -Be 'W1'
    }

    It 'does not reuse another country artifact for the same product version' {
        $w1 = Join-Path $TestDrive 'w1-cache'
        $it = Join-Path $TestDrive 'it-cache'
        Restore-BaselinesFromArtifacts -AppName Application -TargetFolder $w1 -BaselineVersion '1.0.0.0' -CountryCode W1 | Out-Null
        Restore-BaselinesFromArtifacts -AppName Application -TargetFolder $it -BaselineVersion '1.0.0.0' -CountryCode IT | Out-Null
        Get-Content -LiteralPath (Join-Path $w1 'Microsoft_Application_1.0.0.0.app') | Should -Be 'W1'
        Get-Content -LiteralPath (Join-Path $it 'Microsoft_Application_1.0.0.0.app') | Should -Be 'IT'
    }
}
