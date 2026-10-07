Describe "Baseline artifact paths" {
    BeforeAll {
        Import-Module "$PSScriptRoot/../EnlistmentHelperFunctions.psm1" -Force
        Import-Module "$PSScriptRoot/../GuardingV2ExtensionsHelper.psm1" -Force
        InModuleScope GuardingV2ExtensionsHelper {
            function script:Get-BCArtifactUrl {
                param($type, $country, $version, $storageAccount, [switch] $accept_insiderEula)
            }
            function script:Download-Artifacts {
                param($artifactUrl, $basePath)
            }
        }
    }

    AfterAll {
        Remove-Module GuardingV2ExtensionsHelper
    }

    It "uses the returned artifact folder with <extensionsName> rather than reconstructing W1" -ForEach @(
        @{ extensionsName = "Extensions" }
        @{ extensionsName = "extensions" }
    ) {
        $root = Join-Path $TestDrive ([Guid]::NewGuid().ToString())
        $downloaded = Join-Path $root "downloaded/sandbox/29.1.54685.0/w1"
        $extensions = Join-Path $downloaded $extensionsName
        $target = Join-Path $root "symbols"
        New-Item -ItemType Directory -Path $extensions -Force | Out-Null
        Set-Content -Path (Join-Path $extensions "Microsoft_Example_29.1.54685.0.app") -Value "baseline"

        Mock Import-Module -ModuleName GuardingV2ExtensionsHelper {}
        Mock Get-BaseFolder -ModuleName GuardingV2ExtensionsHelper { $root }
        Mock Get-BCArtifactUrl -ModuleName GuardingV2ExtensionsHelper { "https://example.invalid/sandbox/29.1.54685.0/w1" }
        Mock Download-Artifacts -ModuleName GuardingV2ExtensionsHelper { $downloaded }

        $version = Restore-BaselinesFromArtifacts -AppName "Example" -TargetFolder $target -BaselineVersion "29.1.54685.0" -CountryCode "W1"

        $version | Should -Be "29.1.54685.0"
        Get-Content (Join-Path $target "Microsoft_Example_29.1.54685.0.app") | Should -Be "baseline"
        Should -Invoke Download-Artifacts -ModuleName GuardingV2ExtensionsHelper -Times 1 -Exactly
    }
}
