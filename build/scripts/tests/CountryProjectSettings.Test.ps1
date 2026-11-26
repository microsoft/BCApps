Describe 'Country project preprocessor settings' {
    BeforeAll {
        $script:updater = Join-Path $PSScriptRoot '..\Update-CountryProjectSettings.ps1'
        $script:originalWorkspace = $env:GITHUB_WORKSPACE
        $script:originalInetroot = $env:INETROOT
    }

    BeforeEach {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $scripts = Join-Path $root 'build\scripts'
        $app = Join-Path $root 'src\Apps\W1\Intercompany\app'
        $settingsFolder = Join-Path $root 'build\projects\Apps AU\.AL-Go'
        $null = New-Item -Path $scripts, $app, $settingsFolder -ItemType Directory -Force
        $settingsPath = Join-Path $settingsFolder 'settings.json'
        $settings = @{
            appFolders = @('../../../src/Apps/W1/Intercompany/app', '../../../src/Layers/W1/DemoTool')
            testFolders = @()
            preprocessorSymbols = @('DEBUG')
        }
        $settings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $settingsPath
        @'
function Get-ApplicationGroup {
    param($GroupName, $CountryCode, [switch] $SkipLanguagePacks)
    [pscustomobject]@{
        ApplicationName = 'Intercompany'
        ProjectFolder = Join-Path $env:INETROOT 'src\Apps\W1\Intercompany\app'
        IsGDLProject = $false
        IsTest = $false
        CountryPreprocessorSymbols = @('INTERCOMPANY_APAC')
    }
}
'@ | Set-Content -LiteralPath (Join-Path $scripts 'ALAppBuild.psm1')
        $env:GITHUB_WORKSPACE = $root
    }

    AfterEach {
        $env:GITHUB_WORKSPACE = $originalWorkspace
        $env:INETROOT = $originalInetroot
        Remove-Module ALAppBuild -ErrorAction SilentlyContinue
    }

    It 'detects symbol-only drift and preserves unrelated flags when repairing it' {
        (& $updater -CountryCode AU -Validate 6>$null) | Should -BeFalse
        & $updater -CountryCode AU 6>$null

        $updated = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
        $updated.preprocessorSymbols | Should -Be @('DEBUG', 'INTERCOMPANY_APAC')
        (& $updater -CountryCode AU -Validate 6>$null) | Should -BeTrue
    }

    It 'replaces a declared symbol from the wrong country' {
        $settings.preprocessorSymbols = @('DEBUG', 'INTERCOMPANY_NO')
        $settings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $settingsPath

        & $updater -CountryCode AU 6>$null

        $updated = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
        $updated.preprocessorSymbols | Should -Be @('DEBUG', 'INTERCOMPANY_APAC')
    }

    It 'does not modify settings when WhatIf is specified' {
        $originalContent = Get-Content -LiteralPath $settingsPath -Raw

        & $updater -CountryCode AU -WhatIf 6>$null

        Get-Content -LiteralPath $settingsPath -Raw | Should -Be $originalContent
        (& $updater -CountryCode AU -Validate 6>$null) | Should -BeFalse
    }
}
