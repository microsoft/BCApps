Describe "AppObjectValidation" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\..\..\build\scripts\AppObjectValidation.psm1" -Force

        $script:AllowedRanges = @(
            [PSCustomObject]@{ From = 1;        To = 49999 },
            [PSCustomObject]@{ From = 99000750; To = 99001048 }
        )

        function New-TestAlFile {
            param(
                [Parameter(Mandatory = $true)] [string] $Path,
                [Parameter(Mandatory = $true)] [string] $Declaration
            )

            $directory = Split-Path -Path $Path -Parent
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
            "$Declaration`r`n{`r`n}`r`n" | Set-Content -Path $Path -Encoding UTF8
            return $Path
        }

        function New-ValidationLayout {
            $root = Join-Path $TestDrive ([System.Guid]::NewGuid().ToString('N'))
            $source = Join-Path $root 'src'
            $projects = Join-Path $root 'build\projects\Apps W1\.AL-Go'
            $production = Join-Path $source 'Apps\W1\Example\App'
            $countryProduction = Join-Path $source 'Apps\GB\Example\App'
            $testApp = Join-Path $source 'Apps\W1\Example\Test'

            New-Item -ItemType Directory -Path $production, $countryProduction, $testApp, $projects -Force | Out-Null
            @{
                testFolders = @('../../../src/Apps/W1/Example/Test')
            } | ConvertTo-Json | Set-Content -Path (Join-Path $projects 'settings.json') -Encoding UTF8

            return [PSCustomObject]@{
                Root              = $root
                Source            = $source
                Production        = $production
                CountryProduction = $countryProduction
                TestApp           = $testApp
                Projects          = (Join-Path $root 'build\projects')
            }
        }

        function Invoke-AddedFileValidation {
            param(
                [Parameter(Mandatory = $true)] [object] $Layout,
                [Parameter(Mandatory = $true)] [string[]] $FilePaths
            )

            $testFolders = Get-ALGoTestFolders -ProjectsPath $Layout.Projects
            Test-ObjectIDsInAddedALFilesAreInAllowedRange -FilePaths $FilePaths -SourceCodePaths @($Layout.Source) -TestFolderPaths $testFolders -AllowedRanges $script:AllowedRanges
        }
    }

    Context "Test-IsObjectIdInAllowedRange" {
        It "accepts both boundaries of each allowed range" {
            Test-IsObjectIdInAllowedRange -ObjectId 1 -AllowedRanges $script:AllowedRanges | Should -BeTrue
            Test-IsObjectIdInAllowedRange -ObjectId 49999 -AllowedRanges $script:AllowedRanges | Should -BeTrue
            Test-IsObjectIdInAllowedRange -ObjectId 99000750 -AllowedRanges $script:AllowedRanges | Should -BeTrue
            Test-IsObjectIdInAllowedRange -ObjectId 99001048 -AllowedRanges $script:AllowedRanges | Should -BeTrue
        }

        It "rejects IDs outside the allowed ranges" {
            Test-IsObjectIdInAllowedRange -ObjectId 50000 -AllowedRanges $script:AllowedRanges | Should -BeFalse
            Test-IsObjectIdInAllowedRange -ObjectId 70000000 -AllowedRanges $script:AllowedRanges | Should -BeFalse
            Test-IsObjectIdInAllowedRange -ObjectId 99001049 -AllowedRanges $script:AllowedRanges | Should -BeFalse
        }
    }

    Context "Get-FilesCollection" {
        It "keeps the existing default object type behavior" {
            $layout = New-ValidationLayout
            New-TestAlFile -Path (Join-Path $layout.Production 'Table.al') -Declaration 'table 30000 "Table"'
            New-TestAlFile -Path (Join-Path $layout.Production 'Extension.al') -Declaration 'tableextension 30001 "Extension" extends "Table"'

            $objects = Get-FilesCollection -SourceCodePaths $layout.Production

            $objects.ObjectSignatures.ContainsKey('table 30000') | Should -BeTrue
            $objects.ObjectSignatures.ContainsKey('tableextension 30001') | Should -BeFalse
        }
    }

    Context "Get-ALGoTestFolders" {
        It "resolves configured test folders to absolute paths" {
            $layout = New-ValidationLayout

            $testFolders = Get-ALGoTestFolders -ProjectsPath $layout.Projects

            $testFolders | Should -Contain ([System.IO.Path]::GetFullPath($layout.TestApp))
        }

        It "treats a trailing wildcard as the containing test folder" {
            $layout = New-ValidationLayout
            $settingsPath = Join-Path $layout.Projects 'System\.AL-Go'
            New-Item -ItemType Directory -Path $settingsPath -Force | Out-Null
            @{
                testFolders = @('../../../src/System Application/Test/*')
            } | ConvertTo-Json | Set-Content -Path (Join-Path $settingsPath 'settings.json') -Encoding UTF8

            $testFolders = Get-ALGoTestFolders -ProjectsPath $layout.Projects

            $expected = Join-Path $layout.Source 'System Application\Test'
            $testFolders | Should -Contain ([System.IO.Path]::GetFullPath($expected))
        }
    }

    Context "Test-ObjectIDsInAddedALFilesAreInAllowedRange" {
        It "accepts objects in newly added W1 and country files when their IDs are allowed" {
            $layout = New-ValidationLayout
            $w1File = New-TestAlFile -Path (Join-Path $layout.Production 'W1.al') -Declaration 'table 49999 "W1"'
            $countryFile = New-TestAlFile -Path (Join-Path $layout.CountryProduction 'GB.al') -Declaration 'pageextension 99000750 "GB" extends "Customer Card"'

            { Invoke-AddedFileValidation -Layout $layout -FilePaths @($w1File, $countryFile) } | Should -Not -Throw
        }

        It "rejects an out-of-range object in a newly added W1 file" {
            $layout = New-ValidationLayout
            $file = New-TestAlFile -Path (Join-Path $layout.Production 'Invalid.al') -Declaration 'table 50000 "Invalid"'

            { Invoke-AddedFileValidation -Layout $layout -FilePaths @($file) } | Should -Throw
        }

        It "rejects an out-of-range object in a newly added country file" {
            $layout = New-ValidationLayout
            $file = New-TestAlFile -Path (Join-Path $layout.CountryProduction 'Invalid.al') -Declaration 'pageextension 50000 "Invalid GB" extends "Customer Card"'

            { Invoke-AddedFileValidation -Layout $layout -FilePaths @($file) } | Should -Throw
        }

        It "excludes a table in a test app without relying on Subtype Test" {
            $layout = New-ValidationLayout
            $file = New-TestAlFile -Path (Join-Path $layout.TestApp 'TestTable.al') -Declaration 'table 139560 "Test Table"'

            { Invoke-AddedFileValidation -Layout $layout -FilePaths @($file) } | Should -Not -Throw
        }

        It "excludes an extension in a test app without relying on Subtype Test" {
            $layout = New-ValidationLayout
            $file = New-TestAlFile -Path (Join-Path $layout.TestApp 'TestPageExt.al') -Declaration 'pageextension 139561 "Test Extension" extends "Customer Card"'

            { Invoke-AddedFileValidation -Layout $layout -FilePaths @($file) } | Should -Not -Throw
        }

        It "excludes a non-codeunit object when its owning manifest identifies a test app" {
            $layout = New-ValidationLayout
            $unconfiguredTestApp = Join-Path $layout.Source 'Apps\W1\Example\Unconfigured'
            New-Item -ItemType Directory -Path $unconfiguredTestApp -Force | Out-Null
            @{
                id        = [System.Guid]::NewGuid()
                name      = 'Example Test Library'
                publisher = 'Microsoft'
                version   = '1.0.0.0'
            } | ConvertTo-Json | Set-Content -Path (Join-Path $unconfiguredTestApp 'app.json') -Encoding UTF8
            $file = New-TestAlFile -Path (Join-Path $unconfiguredTestApp 'TestTable.al') -Declaration 'table 139560 "Test Table"'

            { Invoke-AddedFileValidation -Layout $layout -FilePaths @($file) } | Should -Not -Throw
        }

        It "ignores added files outside the configured source roots" {
            $layout = New-ValidationLayout
            $file = New-TestAlFile -Path (Join-Path $layout.Root 'samples\Invalid.al') -Declaration 'table 50000 "Sample"'

            { Invoke-AddedFileValidation -Layout $layout -FilePaths @($file) } | Should -Not -Throw
        }

        It "ignores non-AL files" {
            $layout = New-ValidationLayout
            $file = Join-Path $layout.Production 'README.md'
            'table 50000 "Documentation example"' | Set-Content -Path $file -Encoding UTF8

            { Invoke-AddedFileValidation -Layout $layout -FilePaths @($file) } | Should -Not -Throw
        }

        It "reports every offending object before throwing" {
            $layout = New-ValidationLayout
            $first = New-TestAlFile -Path (Join-Path $layout.Production 'First.al') -Declaration 'table 50000 "First"'
            $second = New-TestAlFile -Path (Join-Path $layout.CountryProduction 'Second.al') -Declaration 'page 60000 "Second"'

            $errorRecord = $null
            try {
                Invoke-AddedFileValidation -Layout $layout -FilePaths @($first, $second)
            }
            catch {
                $errorRecord = $_
            }

            $errorRecord | Should -Not -BeNullOrEmpty
            $errorRecord.Exception.Message | Should -Match '2 object\(s\)'
        }
    }
}
