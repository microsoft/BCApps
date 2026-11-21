Describe "AppObjectValidation" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\AppObjectValidation.psm1" -Force

        $script:AllowedRanges = (Get-ObjectIdRangePolicy).AllowedRanges

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
            $baseApp = Join-Path $source 'Layers\W1\BaseApp'
            $countryBaseApp = Join-Path $source 'Layers\GB\BaseApp'
            $businessFoundationApp = Join-Path $source 'Business Foundation\App'
            $systemApplicationApp = Join-Path $source 'System Application\App'

            New-Item -ItemType Directory -Path $production, $countryProduction, $testApp, $baseApp, $countryBaseApp, $businessFoundationApp, $systemApplicationApp, $projects -Force | Out-Null
            @{
                testFolders = @('../../../src/Apps/W1/Example/Test')
            } | ConvertTo-Json | Set-Content -Path (Join-Path $projects 'settings.json') -Encoding UTF8
            @{ projects = @{} } | ConvertTo-Json | Set-Content -Path (Join-Path $root 'build\projects.json') -Encoding UTF8

            return [PSCustomObject]@{
                Root              = $root
                Source            = $source
                Production        = $production
                CountryProduction = $countryProduction
                TestApp           = $testApp
                BaseApp           = $baseApp
                CountryBaseApp    = $countryBaseApp
                BusinessFoundationApp = $businessFoundationApp
                SystemApplicationApp  = $systemApplicationApp
                Projects          = (Join-Path $root 'build\projects')
                ProjectsJson      = (Join-Path $root 'build\projects.json')
                ValidationRoots   = @($baseApp, $countryBaseApp, $businessFoundationApp, $systemApplicationApp, (Join-Path $source 'Apps'))
            }
        }

        function Invoke-AddedFileValidation {
            param(
                [Parameter(Mandatory = $true)] [object] $Layout,
                [Parameter(Mandatory = $true)] [string[]] $FilePaths
            )

            $testFolders = Get-ALGoTestFolders -ProjectsPath $Layout.Projects -ProjectsJsonPath $Layout.ProjectsJson -RepositoryRoot $Layout.Root
            Test-ObjectIDsInALFilesAreInAllowedRange -FilePaths $FilePaths -SourceCodePaths $Layout.ValidationRoots -TestFolderPaths $testFolders -AllowedRanges $script:AllowedRanges
        }

        function New-TestManifest {
            param(
                [string] $Folder,
                [object[]] $Ranges = @(),
                [string] $Name = 'Example'
            )

            New-Item -ItemType Directory -Path $Folder -Force | Out-Null
            $path = Join-Path $Folder 'app.json'
            @{
                id       = [System.Guid]::NewGuid().ToString()
                name     = $Name
                idRanges = @($Ranges)
            } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding UTF8
            return $path
        }

        function Invoke-ManifestRangeValidation {
            param(
                [object] $Layout,
                [object[]] $AllowedRanges = $script:AllowedRanges,
                [object[]] $ManifestRangeExceptions = @(),
                [object[]] $LegacyObjectIdRanges = @()
            )

            $testFolders = @(Get-ALGoTestFolders -ProjectsPath $Layout.Projects -ProjectsJsonPath $Layout.ProjectsJson -RepositoryRoot $Layout.Root)
            Test-ApplicationObjectIdRanges -SourceCodePath $Layout.Source -TestFolderPaths $testFolders -AllowedRanges $AllowedRanges -ManifestRangeExceptions $ManifestRangeExceptions -LegacyObjectIdRanges $LegacyObjectIdRanges
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

        It "includes projects canonically marked as tests even when they are AL-Go app folders" {
            $layout = New-ValidationLayout
            $testUtility = Join-Path $layout.Source 'Apps\W1\LibraryNoTransactions\app'
            New-Item -ItemType Directory -Path $testUtility -Force | Out-Null
            @{
                projects = @{
                    'Library-NoTransactions' = @{
                        projectPath = '$env:INETROOT\App\Apps\W1\LibraryNoTransactions\app'
                        isTest      = $true
                    }
                }
            } | ConvertTo-Json -Depth 5 | Set-Content -Path $layout.ProjectsJson -Encoding UTF8

            $testFolders = Get-ALGoTestFolders -ProjectsPath $layout.Projects -ProjectsJsonPath $layout.ProjectsJson -RepositoryRoot $layout.Root

            $testFolders | Should -Contain ([System.IO.Path]::GetFullPath($testUtility))
        }

        It "resolves test layer sources from canonical appJsonPath metadata" {
            $layout = New-ValidationLayout
            $layerTest = Join-Path $layout.Source 'Layers\W1\Tests\Bank'
            New-Item -ItemType Directory -Path $layerTest -Force | Out-Null
            '{}' | Set-Content -Path (Join-Path $layerTest 'app.json') -Encoding UTF8
            @{
                projects = @{
                    'Tests-Bank' = @{
                        projectPath = '$env:INETROOT\App\Views\$CountryCode\Tests\Bank'
                        appJsonPath = '$env:INETROOT\App\Layers\W1\Tests\Bank\app.json'
                        isTest      = $true
                    }
                }
            } | ConvertTo-Json -Depth 5 | Set-Content -Path $layout.ProjectsJson -Encoding UTF8

            $testFolders = Get-ALGoTestFolders -ProjectsPath $layout.Projects -ProjectsJsonPath $layout.ProjectsJson -RepositoryRoot $layout.Root

            $testFolders | Should -Contain ([System.IO.Path]::GetFullPath($layerTest))
        }
    }

    Context "Test-ObjectIDsInALFilesAreInAllowedRange" {
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

        It "checks newly added objects in all country BaseApps, Business Foundation, and System Application" {
            $layout = New-ValidationLayout
            $baseAppFile = New-TestAlFile -Path (Join-Path $layout.BaseApp 'Invalid.al') -Declaration 'table 50000 "Invalid BaseApp"'
            $countryBaseAppFile = New-TestAlFile -Path (Join-Path $layout.CountryBaseApp 'Invalid.al') -Declaration 'tableextension 50001 "Invalid GB BaseApp" extends "Customer"'
            $businessFoundationFile = New-TestAlFile -Path (Join-Path $layout.BusinessFoundationApp 'Invalid.al') -Declaration 'page 50001 "Invalid Business Foundation"'
            $systemApplicationFile = New-TestAlFile -Path (Join-Path $layout.SystemApplicationApp 'Invalid.al') -Declaration 'codeunit 50002 "Invalid System Application"'

            $errorRecord = $null
            try {
                Invoke-AddedFileValidation -Layout $layout -FilePaths @($baseAppFile, $countryBaseAppFile, $businessFoundationFile, $systemApplicationFile)
            }
            catch {
                $errorRecord = $_
            }

            $errorRecord | Should -Not -BeNullOrEmpty
            $errorRecord.Exception.Message | Should -Match '4 object\(s\)'
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

        It "excludes a test utility whose manifest name does not contain test" {
            $layout = New-ValidationLayout
            $testUtility = Join-Path $layout.Source 'Apps\W1\LibraryNoTransactions\app'
            New-Item -ItemType Directory -Path $testUtility -Force | Out-Null
            @{
                projects = @{
                    'Library-NoTransactions' = @{
                        projectPath = '$env:INETROOT\App\Apps\W1\LibraryNoTransactions\app'
                        isTest      = $true
                    }
                }
            } | ConvertTo-Json -Depth 5 | Set-Content -Path $layout.ProjectsJson -Encoding UTF8
            $file = New-TestAlFile -Path (Join-Path $testUtility 'NoTransactionsSubscriber.Codeunit.al') -Declaration 'codeunit 130630 "No Transactions Subscriber"'

            { Invoke-AddedFileValidation -Layout $layout -FilePaths @($file) } | Should -Not -Throw
        }

        It "ignores added files outside the configured source roots" {
            $layout = New-ValidationLayout
            $files = @(
                (New-TestAlFile -Path (Join-Path $layout.Source 'Layers\W1\DemoTool\Invalid.al') -Declaration 'table 50000 "Demo Tool"')
                (New-TestAlFile -Path (Join-Path $layout.Source 'Business Foundation\Test\Invalid.al') -Declaration 'table 50001 "Business Foundation Test"')
                (New-TestAlFile -Path (Join-Path $layout.Source 'System Application\Test Library\Invalid.al') -Declaration 'table 50002 "System Application Test Library"')
                (New-TestAlFile -Path (Join-Path $layout.Source 'Tools\Invalid.al') -Declaration 'table 50003 "Tool"')
                (New-TestAlFile -Path (Join-Path $layout.Source 'GDL\Invalid.al') -Declaration 'table 50004 "GDL"')
                (New-TestAlFile -Path (Join-Path $layout.Source 'DisabledTests\Invalid.al') -Declaration 'table 50005 "Disabled Test"')
            )

            { Invoke-AddedFileValidation -Layout $layout -FilePaths $files } | Should -Not -Throw
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

    Context "Test-ApplicationObjectIdRanges" {
        It "validates the boundaries of every range in the production policy" {
            $layout = New-ValidationLayout
            $policy = Get-ObjectIdRangePolicy
            $boundaries = @(
                foreach ($range in $policy.AllowedRanges) {
                    @{ from = $range.From; to = $range.From }
                    @{ from = $range.To; to = $range.To }
                }
            )
            New-TestManifest -Folder $layout.Production -Ranges $boundaries | Out-Null

            { Invoke-ManifestRangeValidation -Layout $layout -AllowedRanges $policy.AllowedRanges } | Should -Not -Throw
        }

        It "checks existing manifests across all src folders and aggregates failures" {
            $layout = New-ValidationLayout
            foreach ($folder in @($layout.CountryProduction, $layout.CountryBaseApp, (Join-Path $layout.Source 'Tools\Example'))) {
                New-TestManifest -Folder $folder -Ranges @(@{ from = 50000; to = 50001 }) | Out-Null
            }

            { Invoke-ManifestRangeValidation -Layout $layout } | Should -Throw '*3 violation(s)*'
        }

        It "revalidates existing manifests when only the allowed policy changes" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production -Ranges @(@{ from = 100; to = 200 }) | Out-Null

            { Invoke-ManifestRangeValidation -Layout $layout -AllowedRanges @(@{ From = 1; To = 200 }) } | Should -Not -Throw
            { Invoke-ManifestRangeValidation -Layout $layout -AllowedRanges @(@{ From = 1; To = 199 }) } | Should -Throw '*100..200*'
        }

        It "rejects a range whose endpoints are allowed but which spans a forbidden gap" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production -Ranges @(@{ from = 50; to = 250 }) | Out-Null
            $allowed = @(@{ From = 1; To = 100 }, @{ From = 200; To = 300 })

            { Invoke-ManifestRangeValidation -Layout $layout -AllowedRanges $allowed } | Should -Throw '*50..250*'
        }

        It "accepts a range covered by adjacent or overlapping allowed intervals" -TestCases @(
            @{ SecondFrom = 101 }
            @{ SecondFrom = 90 }
        ) {
            param($SecondFrom)
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production -Ranges @(@{ from = 50; to = 150 }) | Out-Null
            $allowed = @(@{ From = $SecondFrom; To = 200 }, @{ From = 1; To = 100 })

            { Invoke-ManifestRangeValidation -Layout $layout -AllowedRanges $allowed } | Should -Not -Throw
        }

        It "rejects malformed or invalid declared ranges" -TestCases @(
            @{ Range = @{ from = 0; to = 10 } }
            @{ Range = @{ from = 20; to = 10 } }
            @{ Range = @{ from = 1 } }
            @{ Range = @{ from = 'invalid'; to = 10 } }
            @{ Range = @{ from = 1.5; to = 10 } }
            @{ Range = @{ from = 1; to = 2147483648 } }
        ) {
            param($Range)
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production -Ranges @($Range) | Out-Null

            { Invoke-ManifestRangeValidation -Layout $layout } | Should -Throw '*Invalid object ID range*app.json*'
        }

        It "accepts an exact legacy declaration only in its configured manifest" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production -Ranges @(@{ from = 50000; to = 50010 }) | Out-Null
            $exceptions = @(@{
                Path   = 'Apps/W1/Example/App/app.json'
                Ranges = @(@{ From = 50000; To = 50010 })
            })

            { Invoke-ManifestRangeValidation -Layout $layout -ManifestRangeExceptions $exceptions } | Should -Not -Throw
            New-TestManifest -Folder $layout.CountryProduction -Ranges @(@{ from = 50000; to = 50010 }) | Out-Null
            { Invoke-ManifestRangeValidation -Layout $layout -ManifestRangeExceptions $exceptions } | Should -Throw '*Apps/GB/Example/App/app.json*'
        }

        It "does not allow a legacy manifest exception to be widened" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production -Ranges @(@{ from = 50000; to = 50011 }) | Out-Null
            $exceptions = @(@{
                Path   = 'Apps/W1/Example/App/app.json'
                Ranges = @(@{ From = 50000; To = 50010 })
            })

            { Invoke-ManifestRangeValidation -Layout $layout -ManifestRangeExceptions $exceptions } | Should -Throw '*50000..50011*'
        }

        It "excludes test manifests using build metadata even without test in the app name" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.TestApp -Ranges @(@{ from = 139000; to = 139100 }) | Out-Null
            $utility = Join-Path $layout.Source 'Apps\W1\LibraryNoTransactions\app'
            New-TestManifest -Folder $utility -Ranges @(@{ from = 130000; to = 130100 }) -Name 'No Transactions' | Out-Null
            @{
                projects = @{
                    'Library-NoTransactions' = @{
                        projectPath = '$env:INETROOT\App\Apps\W1\LibraryNoTransactions\app'
                        isTest      = $true
                    }
                }
            } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $layout.ProjectsJson -Encoding UTF8

            { Invoke-ManifestRangeValidation -Layout $layout } | Should -Not -Throw
        }

        It "excludes an unconfigured test app identified by its manifest name" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production -Ranges @(@{ from = 139000; to = 139100 }) -Name 'Example Test Library' | Out-Null

            { Invoke-ManifestRangeValidation -Layout $layout } | Should -Not -Throw
        }

        It "checks objects when the manifest has missing or empty idRanges" -TestCases @(
            @{ Manifest = '{"name":"Example"}' }
            @{ Manifest = '{"name":"Example","idRanges":[]}' }
        ) {
            param($Manifest)
            $layout = New-ValidationLayout
            $Manifest | Set-Content -LiteralPath (Join-Path $layout.Production 'app.json') -Encoding UTF8
            New-TestAlFile -Path (Join-Path $layout.Production 'Invalid.al') -Declaration 'tableextension 50000 "Invalid" extends "Customer"' | Out-Null

            { Invoke-ManifestRangeValidation -Layout $layout } | Should -Throw '*50000*'
        }

        It "validates the legacy singular idRange property" {
            $layout = New-ValidationLayout
            '{"name":"Example","idRange":{"from":50000,"to":50010}}' |
                Set-Content -LiteralPath (Join-Path $layout.Production 'app.json') -Encoding UTF8

            { Invoke-ManifestRangeValidation -Layout $layout } | Should -Throw '*50000..50010*'
        }

        It "does not scan AL files when their manifest declares valid ranges" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production -Ranges @(@{ from = 1; to = 10 }) | Out-Null
            Mock GetALObjectInformation -ModuleName AppObjectValidation { throw 'Unexpected AL scan' }

            { Invoke-ManifestRangeValidation -Layout $layout } | Should -Not -Throw
        }

        It "does not attribute nested test-app objects to a parent app without ranges" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production | Out-Null
            $nested = Join-Path $layout.Production 'Nested'
            New-TestManifest -Folder $nested -Name 'Nested Tests' -Ranges @(@{ from = 139000; to = 139100 }) | Out-Null
            New-TestAlFile -Path (Join-Path $nested 'TestTable.al') -Declaration 'table 139000 "Test Table"' | Out-Null
            New-TestAlFile -Path (Join-Path $layout.Production 'Valid.al') -Declaration 'table 100 "Valid"' | Out-Null

            { Invoke-ManifestRangeValidation -Layout $layout } | Should -Not -Throw
        }

        It "scopes fallback legacy object ranges to their owning app" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production | Out-Null
            New-TestAlFile -Path (Join-Path $layout.Production 'Legacy.al') -Declaration 'codeunit 148111 "Legacy"' | Out-Null
            $exceptions = @(@{
                Path   = 'Apps/W1/Example/App/app.json'
                Ranges = @(@{ From = 148111; To = 148111 })
            })

            { Invoke-ManifestRangeValidation -Layout $layout -LegacyObjectIdRanges $exceptions } | Should -Not -Throw
            New-TestManifest -Folder $layout.CountryProduction | Out-Null
            New-TestAlFile -Path (Join-Path $layout.CountryProduction 'Invalid.al') -Declaration 'codeunit 148111 "Not Legacy"' | Out-Null
            { Invoke-ManifestRangeValidation -Layout $layout -LegacyObjectIdRanges $exceptions } | Should -Throw '*148111*'
        }

        It "accepts an app without ID-bearing objects or configured test folders" {
            $layout = New-ValidationLayout
            New-TestManifest -Folder $layout.Production | Out-Null

            { Test-ApplicationObjectIdRanges -SourceCodePath $layout.Source -AllowedRanges $script:AllowedRanges -TestFolderPaths @() } | Should -Not -Throw
        }
    }
}
