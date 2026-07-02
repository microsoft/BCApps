$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot '../PlatformHelper.psm1') -Force

Describe "PlatformHelper" {
    BeforeAll {
        $script:testVersions = @(
            '28.0.12345.0',
            '28.0.12346.0',
            '28.1.54321.0',
            '29.0.49913.0',
            '29.0.49914.0',
            '29.1.11111.0',
            '30.0.10000.0'
        )
    }

    BeforeEach {
        Clear-PlatformVersionCache
    }

    Describe "Get-PlatformVersions" {
        It "Should fetch and return platform versions" {
            Mock -ModuleName PlatformHelper -CommandName Invoke-WebRequest -MockWith {
                return @{
                    Content = $script:testVersions | ConvertTo-Json
                }
            }

            $versions = Get-PlatformVersions
            $versions | Should -Not -BeNullOrEmpty
            $versions.Count | Should -Be 7
        }

        It "Should cache versions on subsequent calls" {
            Mock -ModuleName PlatformHelper -CommandName Invoke-WebRequest -MockWith {
                return @{
                    Content = $script:testVersions | ConvertTo-Json
                }
            }

            Get-PlatformVersions | Out-Null
            Get-PlatformVersions | Out-Null

            Should -Invoke -ModuleName PlatformHelper -CommandName Invoke-WebRequest -Times 1 -Exactly
        }

        It "Should refresh cache when Force is specified" {
            Mock -ModuleName PlatformHelper -CommandName Invoke-WebRequest -MockWith {
                return @{
                    Content = $script:testVersions | ConvertTo-Json
                }
            }

            Get-PlatformVersions | Out-Null
            Get-PlatformVersions -Force | Out-Null

            Should -Invoke -ModuleName PlatformHelper -CommandName Invoke-WebRequest -Times 2 -Exactly
        }

        It "Should throw on network error" {
            Mock -ModuleName PlatformHelper -CommandName Invoke-WebRequest -MockWith {
                throw "Network error"
            }

            { Get-PlatformVersions } | Should -Throw "*Failed to fetch platform version index*"
        }
    }

    Describe "Get-PlatformVersionUrl" {
        BeforeEach {
            Mock -ModuleName PlatformHelper -CommandName Invoke-WebRequest -MockWith {
                return @{
                    Content = $script:testVersions | ConvertTo-Json
                }
            }
        }

        It "Should return correct URL for valid version" {
            $url = Get-PlatformVersionUrl -Version '29.0.49913.0'
            $url | Should -Be 'https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/platform/29.0.49913.0'
        }

        It "Should throw for invalid version" {
            { Get-PlatformVersionUrl -Version '99.0.00000.0' } | Should -Throw "*is not available*"
        }
    }

    Describe "Get-LatestPlatformVersion" {
        BeforeEach {
            Mock -ModuleName PlatformHelper -CommandName Invoke-WebRequest -MockWith {
                return @{
                    Content = $script:testVersions | ConvertTo-Json
                }
            }
        }

        It "Should return latest version for major.minor '29.0'" {
            $version = Get-LatestPlatformVersion -MajorMinor '29.0'
            $version | Should -Be '29.0.49914.0'
        }

        It "Should return latest version for major.minor '28.0'" {
            $version = Get-LatestPlatformVersion -MajorMinor '28.0'
            $version | Should -Be '28.0.12346.0'
        }

        It "Should return latest version for major.minor '28.1'" {
            $version = Get-LatestPlatformVersion -MajorMinor '28.1'
            $version | Should -Be '28.1.54321.0'
        }

        It "Should return null for non-existent major.minor" {
            $version = Get-LatestPlatformVersion -MajorMinor '99.0'
            $version | Should -BeNullOrEmpty
        }

        It "Should throw for invalid MajorMinor format" {
            { Get-LatestPlatformVersion -MajorMinor '29' } | Should -Throw "*Invalid MajorMinor format*"
        }
    }

    Describe "Get-BCPlatformArtifactUrl" {
        BeforeEach {
            Mock -ModuleName PlatformHelper -CommandName Invoke-WebRequest -MockWith {
                return @{
                    Content = $script:testVersions | ConvertTo-Json
                }
            }
        }

        It "Should return the platform artifact URL for a full BCPlatform version" {
            Mock -ModuleName PlatformHelper -CommandName Get-ConfigValue -MockWith {
                return [PSCustomObject]@{ Version = '29.0.49913.0' }
            }

            $url = Get-BCPlatformArtifactUrl
            $url | Should -Be 'https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/platform/29.0.49913.0/platform'
        }

        It "Should resolve a major.minor BCPlatform version to the latest full version" {
            Mock -ModuleName PlatformHelper -CommandName Get-ConfigValue -MockWith {
                return [PSCustomObject]@{ Version = '29.0' }
            }

            $url = Get-BCPlatformArtifactUrl
            $url | Should -Be 'https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/platform/29.0.49914.0/platform'
        }

        It "Should return null when no BCPlatform version is configured" {
            Mock -ModuleName PlatformHelper -CommandName Get-ConfigValue -MockWith {
                return [PSCustomObject]@{ Version = $null }
            }

            $url = Get-BCPlatformArtifactUrl
            $url | Should -BeNullOrEmpty
        }
    }

    Describe "Clear-PlatformVersionCache" {
        It "Should clear the cache and force re-fetch" {
            Mock -ModuleName PlatformHelper -CommandName Invoke-WebRequest -MockWith {
                return @{
                    Content = $script:testVersions | ConvertTo-Json
                }
            }

            Get-PlatformVersions | Out-Null
            Clear-PlatformVersionCache
            Get-PlatformVersions | Out-Null

            Should -Invoke -ModuleName PlatformHelper -CommandName Invoke-WebRequest -Times 2 -Exactly
        }
    }
}
