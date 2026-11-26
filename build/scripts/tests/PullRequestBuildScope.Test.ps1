Describe "PullRequestBuildScope" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\PullRequestBuildScope.psm1" -Force
        $countries = @('AT', 'AU', 'CA', 'CH', 'CZ', 'DE', 'FR', 'MX', 'NZ', 'US')
    }

    Context "Get-PullRequestCountries" {
        It "builds no extra country for W1, System Application and disabled-test changes" {
            $files = @('src/Apps/W1/Shopify/App/src/Foo.al', 'src/Layers/W1/BaseApp/Bar.al', 'src/System Application/App/x.al', 'src/DisabledTests/Foo/x.json')
            (Get-PullRequestCountries -ChangedFiles $files -Countries $countries).Countries | Should -BeNullOrEmpty
        }

        It "maps country and region folders to their countries" {
            $files = @('src/Layers/CZ/BaseApp/x.al', 'src/Apps/NA/Foo/app/x.al', 'build/projects/Test Apps FR/.AL-Go/settings.json')
            (Get-PullRequestCountries -ChangedFiles $files -Countries $countries).Countries | Should -Be @('CA', 'CZ', 'FR', 'MX', 'US')
        }

        It "builds sentinel countries for build infrastructure changes" {
            (Get-PullRequestCountries -ChangedFiles @('build/scripts/RunTestsInBcContainer.ps1') -Countries $countries).Countries | Should -Be @('DE', 'US')
        }
    }

    Context "Get-PullRequestTestBuildModes" {
        BeforeAll {
            $modes = @('IntegrationTests', 'UncategorizedTests', 'LegacyTestsBucket1', 'LegacyTestsBucket2')
        }

        It "drops legacy buckets when no legacy test app is affected" {
            $affected = [PSCustomObject]@{ RunAll = $false; AppNames = @('Shopify', 'Shopify Connector Test') }
            Get-PullRequestTestBuildModes -BuildModes $modes -Affected $affected -LegacyTestAppNames @('Tests-ERM') | Should -Be @('IntegrationTests', 'UncategorizedTests')
        }

        It "keeps legacy buckets when a legacy test app is affected or everything must run" {
            $affected = [PSCustomObject]@{ RunAll = $false; AppNames = @('Tests-ERM') }
            Get-PullRequestTestBuildModes -BuildModes $modes -Affected $affected -LegacyTestAppNames @('Tests-ERM') | Should -Be $modes
            Get-PullRequestTestBuildModes -BuildModes $modes -Affected ([PSCustomObject]@{ RunAll = $true; AppNames = @() }) -LegacyTestAppNames @('Tests-ERM') | Should -Be $modes
        }
    }

    Context "Remove-PullRequestCleanBuildMode" {
        It "removes Clean only from app projects while preserving other modes" {
            $root = Join-Path ([System.IO.Path]::GetTempPath()) "PullRequestBuildModes_$([System.Guid]::NewGuid())"
            $appSettingsPath = Join-Path $root 'build/projects/Apps W1/.AL-Go/settings.json'
            $testSettingsPath = Join-Path $root 'build/projects/Test Apps W1/.AL-Go/settings.json'
            New-Item -ItemType Directory -Path (Split-Path $appSettingsPath) -Force | Out-Null
            New-Item -ItemType Directory -Path (Split-Path $testSettingsPath) -Force | Out-Null
            @{
                ConditionalSettings = @(
                    @{ branches = @('main'); settings = @{ buildModes = @('Clean'); preprocessorSymbols = @('CLEAN30') } },
                    @{ branches = @('releases/0.*'); settings = @{ buildModes = @('Strict') } },
                    @{ branches = @('main'); settings = @{ buildModes = @('Default', 'Clean'); customSetting = 'preserved' } }
                )
            } | ConvertTo-Json -Depth 10 | Set-Content $appSettingsPath
            @{
                ConditionalSettings = @(
                    @{ branches = @('main'); settings = @{ buildModes = @('Clean') } }
                )
            } | ConvertTo-Json -Depth 10 | Set-Content $testSettingsPath

            try {
                Remove-PullRequestCleanBuildMode -BaseFolder $root

                $appSettings = Get-Content $appSettingsPath -Raw | ConvertFrom-Json
                @($appSettings.ConditionalSettings).Count | Should -Be 2
                @($appSettings.ConditionalSettings | Where-Object { $_.settings.buildModes -contains 'Clean' }).Count | Should -Be 0
                $appSettings.ConditionalSettings[0].settings.buildModes | Should -Be @('Strict')
                $appSettings.ConditionalSettings[1].settings.buildModes | Should -Be @('Default')
                $appSettings.ConditionalSettings[1].settings.customSetting | Should -Be 'preserved'

                $testSettings = Get-Content $testSettingsPath -Raw | ConvertFrom-Json
                $testSettings.ConditionalSettings[0].settings.buildModes | Should -Be @('Clean')
            } finally {
                Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "Set-PullRequestBuildScope" {
        BeforeEach {
            $root = Join-Path ([System.IO.Path]::GetTempPath()) "PullRequestBuildScope_$([System.Guid]::NewGuid())"
            foreach ($project in @('Apps W1', 'Test Apps W1', 'Apps CZ', 'Test Apps CZ', 'Apps DE', 'Test Apps DE', 'System Application Modules')) {
                $folder = Join-Path $root "build/projects/$project/.AL-Go"
                New-Item -ItemType Directory -Path $folder -Force | Out-Null
                $projectSettings = @{ projectName = $project }
                if ($project -like 'Test Apps *') { $projectSettings.buildModes = @('IntegrationTests', 'LegacyTestsBucket1') }
                $projectSettings | ConvertTo-Json | Set-Content (Join-Path $folder 'settings.json')
            }
            New-Item -ItemType Directory -Path (Join-Path $root '.github') -Force | Out-Null
            '{ "conditionalSettings": [ { "triggers": [ "merge_group" ], "settings": { "projects": [ "build/projects/Apps W1" ] } } ] }' | Set-Content (Join-Path $root '.github/Pull Request Build.settings.json')
            New-Item -ItemType Directory -Path (Join-Path $root 'build/scripts') -Force | Out-Null
            '{ "LegacyTests-Bucket1": [ "Tests-ERM" ] }' | Set-Content (Join-Path $root 'build/scripts/TestConfiguration.json')

            $eventFile = Join-Path $root 'event.json'
            $saved = @($env:GITHUB_EVENT_NAME, $env:GITHUB_EVENT_PATH, $env:GITHUB_STEP_SUMMARY)
            $env:GITHUB_EVENT_NAME = 'pull_request'
            $env:GITHUB_EVENT_PATH = $eventFile
            $env:GITHUB_STEP_SUMMARY = $null
            Mock -ModuleName PullRequestBuildScope Get-PullRequestMergeChangedFiles { return @('src/Apps/CZ/Foo/app/x.al') }
            Mock -ModuleName PullRequestBuildScope Get-AffectedAppNames { return [PSCustomObject]@{ RunAll = $false; AppNames = @('Foo CZ') } }
        }
        AfterEach {
            $env:GITHUB_EVENT_NAME, $env:GITHUB_EVENT_PATH, $env:GITHUB_STEP_SUMMARY = $saved
            Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "limits pull request projects to W1 and touched countries and drops unaffected legacy modes" {
            @{ pull_request = @{ labels = @() } } | ConvertTo-Json -Depth 4 | Set-Content $eventFile
            Set-PullRequestBuildScope -BaseFolder $root

            $settings = Get-Content (Join-Path $root '.github/Pull Request Build.settings.json') -Raw | ConvertFrom-Json
            ($settings.conditionalSettings | Where-Object { $_.triggers -contains 'merge_group' }).settings.projects | Should -Be @('build/projects/Apps W1')
            $projects = @(($settings.conditionalSettings | Where-Object { $_.triggers -contains 'pull_request' }).settings.projects | ForEach-Object { $_.Replace('\', '/') })
            $projects | Sort-Object | Should -Be @('build/projects/Apps CZ', 'build/projects/Apps W1', 'build/projects/System Application Modules', 'build/projects/Test Apps CZ', 'build/projects/Test Apps W1')
            (Get-Content (Join-Path $root 'build/projects/Test Apps CZ/.AL-Go/settings.json') -Raw | ConvertFrom-Json).buildModes | Should -Be @('IntegrationTests')
        }

        It "leaves settings untouched when the full-country-matrix label is present" {
            @{ pull_request = @{ labels = @(@{ name = 'full-country-matrix' }) } } | ConvertTo-Json -Depth 4 | Set-Content $eventFile
            $before = Get-Content (Join-Path $root '.github/Pull Request Build.settings.json') -Raw
            Set-PullRequestBuildScope -BaseFolder $root
            Get-Content (Join-Path $root '.github/Pull Request Build.settings.json') -Raw | Should -Be $before
        }
    }
}
