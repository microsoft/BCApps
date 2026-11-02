Describe "Get-AffectedWorkspaceApps" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\BuildOptimization.psm1" -Force

        function New-WorkspaceApp {
            param(
                [string] $Folder,
                [string] $Id,
                [string[]] $Dependencies = @(),
                [string] $Application
            )

            $path = Join-Path $TestDrive $Folder
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            $manifest = @{
                id = $Id
                name = $Folder
                dependencies = @($Dependencies | ForEach-Object { @{ id = $_ } })
            }
            if ($Application) { $manifest.application = $Application }
            $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $path 'app.json')
            return $path
        }

        function New-TestWorkspace {
            param([string[]] $Folders)

            $path = Join-Path $TestDrive 'apps.code-workspace'
            @{ folders = @($Folders | ForEach-Object { @{ path = $_ } }) } |
                ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path
            return $path
        }
    }

    BeforeEach {
        $script:a = 'aaaaaaaa-0000-0000-0000-000000000001'
        $script:b = 'bbbbbbbb-0000-0000-0000-000000000002'
        $script:c = 'cccccccc-0000-0000-0000-000000000003'
        $script:d = 'dddddddd-0000-0000-0000-000000000004'
        $script:unrelated = 'eeeeeeee-0000-0000-0000-000000000005'
        $script:applicationId = 'c1335042-3002-4257-bf8a-75c898ccb1b8'
    }

    It "returns a sorted changed-app union across a diamond without duplicates or unrelated apps" {
        $paths = @(
            New-WorkspaceApp -Folder 'D' -Id $d -Dependencies $b, $c
            New-WorkspaceApp -Folder 'C' -Id $c -Dependencies $a
            New-WorkspaceApp -Folder 'B' -Id $b -Dependencies $a
            New-WorkspaceApp -Folder 'Unrelated' -Id $unrelated
            New-WorkspaceApp -Folder 'A' -Id $a
        )
        $workspace = New-TestWorkspace -Folders $paths

        $result = @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $c, $a.ToUpperInvariant(), $a)

        $result.Count | Should -Be 4
        ($result.Id -join ',') | Should -Be (@($a, $b, $c, $d) -join ',')
        ($result.Name -join ',') | Should -Be 'A,B,C,D'
        $result[0].Path | Should -Be $paths[4]
        ($result[0].PSObject.Properties.Name -join ',') | Should -Be 'Id,Name,Path'
    }

    It "does not include dependencies of a changed leaf" {
        $paths = @(
            New-WorkspaceApp -Folder 'A' -Id $a
            New-WorkspaceApp -Folder 'B' -Id $b -Dependencies $a
        )
        $workspace = New-TestWorkspace -Folders $paths

        $result = @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $b)

        $result.Count | Should -Be 1
        $result[0].Id | Should -Be $b
    }

    It "terminates on cycles and repeated dependency edges" {
        $paths = @(
            New-WorkspaceApp -Folder 'A' -Id $a -Dependencies $c
            New-WorkspaceApp -Folder 'B' -Id $b -Dependencies $a, $a
            New-WorkspaceApp -Folder 'C' -Id $c -Dependencies $b
        )
        $workspace = New-TestWorkspace -Folders $paths

        $result = @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a)

        ($result.Id -join ',') | Should -Be (@($a, $b, $c) -join ',')
    }

    It "resolves workspace-relative paths and deduplicates references to the same project" {
        $path = New-WorkspaceApp -Folder 'App with spaces' -Id $a
        $workspace = New-TestWorkspace -Folders 'App with spaces', '.\App with spaces\', $path

        $result = @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a)

        $result.Count | Should -Be 1
        $result[0].Path | Should -Be $path
    }

    It "includes application-property edges and their transitive dependents" {
        $paths = @(
            New-WorkspaceApp -Folder 'Base' -Id $a
            New-WorkspaceApp -Folder 'Application' -Id $applicationId -Dependencies $a
            New-WorkspaceApp -Folder 'Consumer' -Id $b -Application '30.0.0.0'
            New-WorkspaceApp -Folder 'Tests' -Id $c -Dependencies $b
        )
        $workspace = New-TestWorkspace -Folders $paths

        $result = @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a)

        $result.Count | Should -Be 4
        $result.Id | Should -Contain $b
        $result.Id | Should -Contain $c
        $result.Id | Should -Contain $applicationId
    }

    It "warns about external dependencies without inventing local nodes or application fallback edges" {
        $paths = @(
            New-WorkspaceApp -Folder 'Base' -Id $a
            New-WorkspaceApp -Folder 'Consumer' -Id $b -Dependencies $unrelated -Application '30.0.0.0'
        )
        $workspace = New-TestWorkspace -Folders $paths

        $result = @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a -WarningVariable warnings -WarningAction SilentlyContinue)

        $result.Count | Should -Be 1
        $result[0].Id | Should -Be $a
        $warnings.Count | Should -Be 1
        $warnings[0].Message | Should -Match $applicationId
        $warnings[0].Message | Should -Match $unrelated
    }

    It "returns no apps for empty changed input" {
        $workspace = New-TestWorkspace -Folders @(New-WorkspaceApp -Folder 'A' -Id $a)

        @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds @()).Count | Should -Be 0
    }

    It "accepts omitted dependencies and does not treat internalsVisibleTo as a dependency" {
        $path = New-WorkspaceApp -Folder 'A' -Id $a
        @{
            id = $a
            name = 'A'
            internalsVisibleTo = @(@{ id = $unrelated })
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $path 'app.json')
        $workspace = New-TestWorkspace -Folders $path

        $result = @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a -WarningAction Stop)

        $result.Count | Should -Be 1
        $result[0].Id | Should -Be $a
    }

    It "accepts an empty workspace when no apps changed" {
        $workspace = New-TestWorkspace -Folders @()

        @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds @()).Count | Should -Be 0
    }

    It "rejects an unknown changed ID before emitting any partial results" {
        $workspace = New-TestWorkspace -Folders @(New-WorkspaceApp -Folder 'A' -Id $a)
        $emitted = [System.Collections.Generic.List[object]]::new()

        {
            Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a, $unrelated |
                ForEach-Object { $emitted.Add($_) }
        } | Should -Throw "*$unrelated*not in workspace*"
        $emitted.Count | Should -Be 0
    }

    It "rejects an invalid changed ID" {
        $workspace = New-TestWorkspace -Folders @(New-WorkspaceApp -Folder 'A' -Id $a)

        { Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds 'not-an-id' } |
            Should -Throw "*not-an-id*not a valid GUID*"
    }

    It "rejects different projects sharing an ID even when its casing differs" {
        $paths = @(
            New-WorkspaceApp -Folder 'W1' -Id $a
            New-WorkspaceApp -Folder 'DK' -Id $a.ToUpperInvariant()
        )
        $workspace = New-TestWorkspace -Folders $paths

        { Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a } |
            Should -Throw "*Duplicate app ID*$a*W1*DK*"
    }

    It "rejects missing and malformed manifests with their path" -TestCases @(
        @{ Content = $null }
        @{ Content = '{invalid json' }
        @{ Content = 'null' }
        @{ Content = '[{"id":"aaaaaaaa-0000-0000-0000-000000000001","name":"A"}]' }
        @{ Content = '{"id":"invalid","name":"A"}' }
        @{ Content = '{"id":"aaaaaaaa-0000-0000-0000-000000000001"}' }
        @{ Content = '{"id":"aaaaaaaa-0000-0000-0000-000000000001","name":" "}' }
    ) {
        param($Content)
        $path = Join-Path $TestDrive 'Invalid'
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        if ($null -ne $Content) { $Content | Set-Content -LiteralPath (Join-Path $path 'app.json') }
        $workspace = New-TestWorkspace -Folders $path

        { Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a } |
            Should -Throw "*app manifest*Invalid*app.json*"
    }

    It "rejects malformed graph declarations" -TestCases @(
        @{ Property = 'dependencies'; Value = @{}; ErrorText = '*dependencies as an array*' }
        @{ Property = 'dependencies'; Value = @(@{ id = 'invalid' }); ErrorText = '*dependency without a valid app ID*' }
        @{ Property = 'application'; Value = 'invalid'; ErrorText = '*invalid application version*' }
    ) {
        param($Property, $Value, $ErrorText)
        $path = New-WorkspaceApp -Folder 'Invalid' -Id $a
        $manifestPath = Join-Path $path 'app.json'
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -AsHashtable
        $manifest[$Property] = $Value
        $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath
        $workspace = New-TestWorkspace -Folders $path

        { Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a } |
            Should -Throw $ErrorText
    }

    It "rejects missing workspace files" {
        { Get-AffectedWorkspaceApps -WorkspaceFile (Join-Path $TestDrive 'missing.code-workspace') -ChangedAppIds $a } |
            Should -Throw '*missing.code-workspace*'
    }

    It "rejects malformed workspace files" -TestCases @(
        @{ Content = '{invalid json'; ErrorText = '*Cannot read workspace*' }
        @{ Content = '{}'; ErrorText = '*must contain a folders array*' }
        @{ Content = '[{"folders":[]}]'; ErrorText = '*must contain a folders array*' }
        @{ Content = '{"folders":{}}'; ErrorText = '*must contain a folders array*' }
        @{ Content = '{"folders":[{}]}'; ErrorText = '*folder without a valid path*' }
    ) {
        param($Content, $ErrorText)
        $workspace = Join-Path $TestDrive 'invalid.code-workspace'
        $Content | Set-Content -LiteralPath $workspace

        { Get-AffectedWorkspaceApps -WorkspaceFile $workspace -ChangedAppIds $a } |
            Should -Throw $ErrorText
    }
}
