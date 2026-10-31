BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\AppPublicationPolicy.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot 'Contract.psm1') -Force
    function Publish-BcContainerApp {
        param($appFile, $scope, $install, $upgrade, $sync)
        $PSBoundParameters
    }
    $script:fixture = Join-Path $PSScriptRoot ".publication-$([guid]::NewGuid().ToString('N'))"
    $null = New-Item -ItemType Directory -Path $fixture
    $script:names = @('Library - No Transactions', 'Prevent Metadata Updates Library', 'Test Runner', 'Additional Fixture')
    $script:files = @(foreach ($name in $names) {
        $path = Join-Path $fixture "Microsoft_${name}_30.0.1.0.app"
        Set-Content $path 'package fixture'
        @{ path = "Apps\$([IO.Path]::GetFileName($path))"; appId = $name; appName = $name; version = '30.0.1.0' }
    })
}
AfterAll { Remove-Item $fixture -Recurse -Force }

Describe 'One shared publication policy with unchanged hook behavior' {
    It 'retains exactly the two standard library exclusions' {
        (@(Get-StandardAppPublicationExclusion) -join '|') |
            Should -Be 'Library - No Transactions|Prevent Metadata Updates Library'
    }
    It 'preserves standard and caller-specific filtering, publish-only and global scope' {
        $parameters = @{appFile = @(Get-ChildItem $fixture -Filter '*.app' | ForEach-Object FullName)}
        $result = & (Join-Path $PSScriptRoot '..\PublishBcContainerApp.ps1') -parameters $parameters -AdditionalAppsNotToPublish 'Additional Fixture'
        @($result.appFile).Count | Should -Be 1
        [IO.Path]::GetFileName($result.appFile[0]) | Should -Be 'Microsoft_Test Runner_30.0.1.0.app'
        $result.scope | Should -Be Global
        $result.install | Should -BeFalse
        $result.upgrade | Should -BeFalse
        $result.sync | Should -BeTrue
    }
    It 'preserves scalar publication exclusion' {
        $parameters = @{appFile = (Join-Path $fixture 'Microsoft_Library - No Transactions_30.0.1.0.app')}
        $result = & (Join-Path $PSScriptRoot '..\PublishBcContainerApp.ps1') -parameters $parameters
        @($result.appFile).Count | Should -Be 0
    }
    It 'does not promote caller-specific exclusions into the diagnostic required-inventory exception' {
        $installed = @([pscustomobject]@{AppId='Test Runner';Name='Test Runner';Version='30.0.1.0';Publisher='Microsoft'})
        {Assert-ExpandedInstalledInventory -Files $files -Installed $installed} | Should -Throw '*Additional Fixture*'
    }
    It 'rejects installation of a transaction or metadata blocking library' -ForEach @('Library - No Transactions', 'Prevent Metadata Updates Library') {
        $selected = $_
        $installed = @($files | Where-Object { $_.appName -notin $names[0..1] -or $_.appName -eq $selected } |
            ForEach-Object {[pscustomobject]@{AppId=$_.appId;Name=$_.appName;Version=$_.version;Publisher='Microsoft'}})
        {Assert-ExpandedInstalledInventory -Files $files -Installed $installed} | Should -Throw '*excluded library unexpectedly installed*'
    }
}
