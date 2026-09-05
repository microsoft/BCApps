Describe "AppObjectValidation" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\..\..\build\scripts\AppObjectValidation.psm1" -Force

        # The allowed object ID ranges that first-party apps must stay within (see bug 646360).
        $script:AllowedRanges = @(
            [PSCustomObject]@{ From = 1;         To = 49999 },
            [PSCustomObject]@{ From = 99000750;  To = 99001048 }
        )

        # All AL object types that carry a numeric object ID (mirrors the pattern used by the action).
        $script:BroadObjectTypePattern = 'tableextension|pageextension|reportextension|enumextension|permissionsetextension|permissionset|codeunit|page|table|report|xmlport|query|enum'

        # Creates an AL file that declares a single object so that Get-FilesCollection can pick it up.
        function New-TestAlFile {
            param(
                [Parameter(Mandatory = $true)] [string] $Directory,
                [Parameter(Mandatory = $true)] [string] $FileName,
                [Parameter(Mandatory = $true)] [string] $Declaration,
                [switch] $IsTest,
                [string] $ExtraContent = ""
            )

            if (-not (Test-Path -Path $Directory)) {
                New-Item -ItemType Directory -Path $Directory -Force | Out-Null
            }

            $content = "$Declaration`r`n{`r`n"
            if ($IsTest) {
                $content += "    Subtype = Test;`r`n"
            }
            if ($ExtraContent -ne "") {
                $content += "    // $ExtraContent`r`n"
            }
            $content += "}`r`n"

            Set-Content -Path (Join-Path $Directory $FileName) -Value $content -Encoding UTF8
        }

        # Returns a fresh, unique folder path under the Pester test drive.
        function New-UniqueFolder {
            $path = Join-Path $TestDrive ([System.Guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            return $path
        }
    }

    Context "Test-IsObjectIdInAllowedRange" {
        It "accepts the lower boundary of the standard range (1)" {
            Test-IsObjectIdInAllowedRange -ObjectId 1 -AllowedRanges $script:AllowedRanges | Should -Be $true
        }

        It "accepts the upper boundary of the standard range (49999)" {
            Test-IsObjectIdInAllowedRange -ObjectId 49999 -AllowedRanges $script:AllowedRanges | Should -Be $true
        }

        It "rejects the value just above the standard range (50000)" {
            Test-IsObjectIdInAllowedRange -ObjectId 50000 -AllowedRanges $script:AllowedRanges | Should -Be $false
        }

        It "rejects the value just below the reserved range (99000749)" {
            Test-IsObjectIdInAllowedRange -ObjectId 99000749 -AllowedRanges $script:AllowedRanges | Should -Be $false
        }

        It "accepts the lower boundary of the reserved range (99000750)" {
            Test-IsObjectIdInAllowedRange -ObjectId 99000750 -AllowedRanges $script:AllowedRanges | Should -Be $true
        }

        It "accepts the upper boundary of the reserved range (99001048)" {
            Test-IsObjectIdInAllowedRange -ObjectId 99001048 -AllowedRanges $script:AllowedRanges | Should -Be $true
        }

        It "rejects the value just above the reserved range (99001049)" {
            Test-IsObjectIdInAllowedRange -ObjectId 99001049 -AllowedRanges $script:AllowedRanges | Should -Be $false
        }

        It "rejects a partner/ISV style object ID (70000000)" {
            Test-IsObjectIdInAllowedRange -ObjectId 70000000 -AllowedRanges $script:AllowedRanges | Should -Be $false
        }
    }

    Context "Get-IntroducedObjects" {
        It "returns brand new object signatures" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "existing.al" -Declaration 'table 30000 "Existing"'
            New-TestAlFile -Directory $current -FileName "existing.al" -Declaration 'table 30000 "Existing"'
            New-TestAlFile -Directory $current -FileName "new.al" -Declaration 'page 45000 "New Page"'

            $introduced = Get-IntroducedObjects -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base)

            @($introduced).Count | Should -Be 1
            $introduced[0].Signature | Should -Be 'page 45000'
        }

        It "ignores objects that are unchanged" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 30000 "A"'
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 30000 "A"'

            $introduced = Get-IntroducedObjects -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base)

            @($introduced).Count | Should -Be 0
        }

        It "ignores objects that are edited but keep the same type and ID" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 30000 "A"'
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 30000 "A"' -ExtraContent "a newly added field"

            $introduced = Get-IntroducedObjects -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base)

            @($introduced).Count | Should -Be 0
        }

        It "treats a renumbered object as introduced (new signature)" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 30000 "A"'
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 31000 "A"'

            $introduced = Get-IntroducedObjects -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base)

            @($introduced | ForEach-Object { $_.Signature }) | Should -Contain 'table 31000'
            @($introduced | ForEach-Object { $_.Signature }) | Should -Not -Contain 'table 30000'
        }

        It "ignores a renamed and moved object that keeps the same signature" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 30000 "Old Name"'
            New-TestAlFile -Directory (Join-Path $current "SubFolder") -FileName "renamed.al" -Declaration 'table 30000 "New Name"'

            $introduced = Get-IntroducedObjects -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base)

            @($introduced).Count | Should -Be 0
        }

        It "ignores deleted objects" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 30000 "A"'
            New-TestAlFile -Directory $base -FileName "b.al" -Declaration 'table 31000 "B"'
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 30000 "A"'

            $introduced = Get-IntroducedObjects -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base)

            @($introduced).Count | Should -Be 0
        }

        It "excludes test objects when -ExcludeTestObjects is specified" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $current -FileName "prod.al" -Declaration 'table 30000 "Prod"'
            New-TestAlFile -Directory $current -FileName "test.al" -Declaration 'codeunit 135000 "Some Test"' -IsTest

            $introduced = Get-IntroducedObjects -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -ExcludeTestObjects

            @($introduced | ForEach-Object { $_.Signature }) | Should -Contain 'table 30000'
            @($introduced | ForEach-Object { $_.Signature }) | Should -Not -Contain 'codeunit 135000'
        }
    }

    Context "Test-IntroducedObjectIDsAreInAllowedRange" {
        It "does not throw for introduced objects on the range boundaries" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $current -FileName "b1.al" -Declaration 'table 1 "Lowest"'
            New-TestAlFile -Directory $current -FileName "b2.al" -Declaration 'table 49999 "Standard Top"'
            New-TestAlFile -Directory $current -FileName "b3.al" -Declaration 'table 99000750 "Reserved Bottom"'
            New-TestAlFile -Directory $current -FileName "b4.al" -Declaration 'table 99001048 "Reserved Top"'

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges } | Should -Not -Throw
        }

        It "throws for an introduced out-of-range object" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 50000 "Out"'

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges } | Should -Throw
        }

        It "does not flag an existing out-of-range object that is unchanged" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 60000 "Legacy"'
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 60000 "Legacy"'

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges } | Should -Not -Throw
        }

        It "does not flag an existing out-of-range object that is edited" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 60000 "Legacy"'
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 60000 "Legacy"' -ExtraContent "edited"

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges } | Should -Not -Throw
        }

        It "throws when an object is renumbered into an out-of-range value" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 40000 "A"'
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 60000 "A"'

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges } | Should -Throw
        }

        It "does not throw when an out-of-range object is renumbered into an allowed value" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 60000 "A"'
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 40000 "A"'

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges } | Should -Not -Throw
        }

        It "does not flag a renamed or moved out-of-range object (unchanged signature)" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 60000 "Old"'
            New-TestAlFile -Directory (Join-Path $current "Moved") -FileName "renamed.al" -Declaration 'table 60000 "New"'

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges } | Should -Not -Throw
        }

        It "does not flag a deleted out-of-range object" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "a.al" -Declaration 'table 60000 "Gone"'
            New-TestAlFile -Directory $current -FileName "b.al" -Declaration 'table 30000 "Kept"'

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges } | Should -Not -Throw
        }

        It "aggregates and reports all offending introduced objects before failing" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 50000 "Out A"'
            New-TestAlFile -Directory $current -FileName "b.al" -Declaration 'page 60000 "Out B"'
            New-TestAlFile -Directory $current -FileName "c.al" -Declaration 'codeunit 70000000 "Out C"'
            New-TestAlFile -Directory $current -FileName "ok.al" -Declaration 'table 30000 "In Range"'

            $thrownError = $null
            try {
                Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges
            }
            catch {
                $thrownError = $_
            }

            $thrownError | Should -Not -BeNullOrEmpty
            ($thrownError.Exception.Message -match '3 newly introduced') | Should -Be $true
        }

        It "respects the AllowedOutOfRangeObjects exception list" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $current -FileName "a.al" -Declaration 'table 60000 "Allowed Exception"'

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges -AllowedOutOfRangeObjects @('table 60000') } | Should -Not -Throw
        }

        It "excludes introduced test objects even when their IDs are out of range" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $current -FileName "test.al" -Declaration 'codeunit 135000 "Some Test"' -IsTest

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects (Get-FilesCollection -SourceCodePaths $current) -BaseObjects (Get-FilesCollection -SourceCodePaths $base) -AllowedRanges $script:AllowedRanges } | Should -Not -Throw
        }
    }

    Context "Object type coverage" {
        It "keeps the default six object types and drops extension/enum objects by default" {
            $folder = New-UniqueFolder
            New-TestAlFile -Directory $folder -FileName "t.al" -Declaration 'table 30000 "T"'
            New-TestAlFile -Directory $folder -FileName "cu.al" -Declaration 'codeunit 30001 "C"'
            New-TestAlFile -Directory $folder -FileName "te.al" -Declaration 'tableextension 30002 "TE" extends "T"'
            New-TestAlFile -Directory $folder -FileName "en.al" -Declaration 'enum 30003 "E"'

            $signatures = @((Get-FilesCollection -SourceCodePaths $folder).ObjectSignatures.Keys)

            $signatures | Should -Contain 'table 30000'
            $signatures | Should -Contain 'codeunit 30001'
            $signatures | Should -Not -Contain 'tableextension 30002'
            $signatures | Should -Not -Contain 'enum 30003'
        }

        It "includes extension, enum and permission set objects with the broader pattern" {
            $folder = New-UniqueFolder
            New-TestAlFile -Directory $folder -FileName "te.al" -Declaration 'tableextension 30002 "TE" extends "T"'
            New-TestAlFile -Directory $folder -FileName "pe.al" -Declaration 'pageextension 30003 "PE" extends "P"'
            New-TestAlFile -Directory $folder -FileName "en.al" -Declaration 'enum 30004 "E"'
            New-TestAlFile -Directory $folder -FileName "ps.al" -Declaration 'permissionset 30005 "PS"'

            $signatures = @((Get-FilesCollection -SourceCodePaths $folder -ObjectTypePattern $script:BroadObjectTypePattern).ObjectSignatures.Keys)

            $signatures | Should -Contain 'tableextension 30002'
            $signatures | Should -Contain 'pageextension 30003'
            $signatures | Should -Contain 'enum 30004'
            $signatures | Should -Contain 'permissionset 30005'
        }

        It "flags an introduced out-of-range tableextension when using the broader pattern" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $current -FileName "te.al" -Declaration 'tableextension 60000 "TE" extends "Base"'

            $currentObjects = Get-FilesCollection -SourceCodePaths $current -ObjectTypePattern $script:BroadObjectTypePattern
            $baseObjects = Get-FilesCollection -SourceCodePaths $base -ObjectTypePattern $script:BroadObjectTypePattern

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects $currentObjects -BaseObjects $baseObjects -AllowedRanges $script:AllowedRanges } | Should -Throw
        }

        It "does not flag an in-range introduced pageextension" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $current -FileName "pe.al" -Declaration 'pageextension 30000 "PE" extends "Base"'

            $currentObjects = Get-FilesCollection -SourceCodePaths $current -ObjectTypePattern $script:BroadObjectTypePattern
            $baseObjects = Get-FilesCollection -SourceCodePaths $base -ObjectTypePattern $script:BroadObjectTypePattern

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects $currentObjects -BaseObjects $baseObjects -AllowedRanges $script:AllowedRanges } | Should -Not -Throw
        }

        It "does not flag an existing out-of-range extension that is unchanged" {
            $base = New-UniqueFolder
            $current = New-UniqueFolder
            New-TestAlFile -Directory $base -FileName "te.al" -Declaration 'tableextension 60000 "TE" extends "Base"'
            New-TestAlFile -Directory $current -FileName "te.al" -Declaration 'tableextension 60000 "TE" extends "Base"'

            $currentObjects = Get-FilesCollection -SourceCodePaths $current -ObjectTypePattern $script:BroadObjectTypePattern
            $baseObjects = Get-FilesCollection -SourceCodePaths $base -ObjectTypePattern $script:BroadObjectTypePattern

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects $currentObjects -BaseObjects $baseObjects -AllowedRanges $script:AllowedRanges } | Should -Not -Throw
        }
    }

    Context "Get-PullRequestBaseSha" {
        It "resolves the base SHA for a pull_request event" {
            $eventFile = Join-Path $TestDrive "pr.json"
            '{ "pull_request": { "base": { "sha": "prbasesha" } } }' | Set-Content -Path $eventFile -Encoding UTF8

            Get-PullRequestBaseSha -EventName 'pull_request' -EventPath $eventFile -BaseRef '' | Should -Be 'prbasesha'
        }

        It "resolves the base SHA for a pull_request_target event" {
            $eventFile = Join-Path $TestDrive "prt.json"
            '{ "pull_request": { "base": { "sha": "prtbasesha" } } }' | Set-Content -Path $eventFile -Encoding UTF8

            Get-PullRequestBaseSha -EventName 'pull_request_target' -EventPath $eventFile -BaseRef '' | Should -Be 'prtbasesha'
        }

        It "resolves the base SHA for a merge_group event" {
            $eventFile = Join-Path $TestDrive "mg.json"
            '{ "merge_group": { "base_sha": "mergebasesha" } }' | Set-Content -Path $eventFile -Encoding UTF8

            Get-PullRequestBaseSha -EventName 'merge_group' -EventPath $eventFile -BaseRef '' | Should -Be 'mergebasesha'
        }

        It "falls back to the origin base ref when the payload has no base SHA" {
            $eventFile = Join-Path $TestDrive "empty.json"
            '{ "some": "data" }' | Set-Content -Path $eventFile -Encoding UTF8

            Get-PullRequestBaseSha -EventName 'pull_request' -EventPath $eventFile -BaseRef 'main' | Should -Be 'origin/main'
        }

        It "falls back to the origin base ref when the event payload file does not exist" {
            Get-PullRequestBaseSha -EventName 'pull_request' -EventPath (Join-Path $TestDrive "missing.json") -BaseRef 'releases/26.x' | Should -Be 'origin/releases/26.x'
        }

        It "returns null when neither an event payload nor a base ref is available" {
            $eventFile = Join-Path $TestDrive "empty2.json"
            '{ "some": "data" }' | Set-Content -Path $eventFile -Encoding UTF8

            Get-PullRequestBaseSha -EventName 'pull_request' -EventPath $eventFile -BaseRef '' | Should -BeNullOrEmpty
        }
    }

    Context "Get-ObjectCollectionAtCommit" {
        It "fetches a missing origin tracking ref before building the base object collection" -Skip:(-not [bool](Get-Command git -ErrorAction SilentlyContinue)) {
            $sourceRepo = New-UniqueFolder
            $sourceFolder = Join-Path $sourceRepo "src"
            $remoteRepo = New-UniqueFolder
            $clientRepo = New-UniqueFolder
            New-TestAlFile -Directory $sourceFolder -FileName "base.al" -Declaration 'table 40000 "Base"'

            & git -C $sourceRepo init --quiet --initial-branch=main
            & git -C $sourceRepo -c user.email="test@example.com" -c user.name="Test" add -A
            & git -C $sourceRepo -c user.email="test@example.com" -c user.name="Test" commit --quiet -m "base"
            & git clone --quiet --bare $sourceRepo $remoteRepo

            & git -C $clientRepo init --quiet
            "client" | Set-Content -Path (Join-Path $clientRepo "README.md") -Encoding UTF8
            & git -C $clientRepo -c user.email="test@example.com" -c user.name="Test" add -A
            & git -C $clientRepo -c user.email="test@example.com" -c user.name="Test" commit --quiet -m "client"
            & git -C $clientRepo remote add origin $remoteRepo

            & git -C $clientRepo show-ref --verify --quiet refs/remotes/origin/main
            $LASTEXITCODE | Should -Not -Be 0

            $baseObjects = Get-ObjectCollectionAtCommit -Commitish 'origin/main' -RepositoryRoot $clientRepo -RelativeSourcePaths @('src')

            $baseObjects.ObjectSignatures.ContainsKey('table 40000') | Should -Be $true
            & git -C $clientRepo show-ref --verify --quiet refs/remotes/origin/main
            $LASTEXITCODE | Should -Be 0
        }

        It "builds the base object collection from a commit and detects renumbering" -Skip:(-not [bool](Get-Command git -ErrorAction SilentlyContinue)) {
            $repo = New-UniqueFolder
            $sourceFolder = Join-Path $repo "src"
            New-TestAlFile -Directory $sourceFolder -FileName "a.al" -Declaration 'table 40000 "A"'
            New-TestAlFile -Directory $sourceFolder -FileName "b.al" -Declaration 'table 60000 "Legacy Out Of Range"'

            Push-Location -Path $repo
            try {
                & git init --quiet
                & git -c user.email="test@example.com" -c user.name="Test" add -A
                & git -c user.email="test@example.com" -c user.name="Test" commit --quiet -m "base"
                $baseSha = (& git rev-parse HEAD).Trim()
            }
            finally {
                Pop-Location
            }

            # Renumber 40000 -> 50000 (out of range) and keep the legacy 60000 object unchanged.
            New-TestAlFile -Directory $sourceFolder -FileName "a.al" -Declaration 'table 50000 "A"'

            $baseObjects = Get-ObjectCollectionAtCommit -Commitish $baseSha -RepositoryRoot $repo -RelativeSourcePaths @('src')
            $currentObjects = Get-FilesCollection -SourceCodePaths $sourceFolder

            $baseObjects.ObjectSignatures.ContainsKey('table 40000') | Should -Be $true
            $baseObjects.ObjectSignatures.ContainsKey('table 50000') | Should -Be $false

            $introduced = Get-IntroducedObjects -CurrentObjects $currentObjects -BaseObjects $baseObjects -ExcludeTestObjects
            @($introduced | ForEach-Object { $_.Signature }) | Should -Contain 'table 50000'
            @($introduced | ForEach-Object { $_.Signature }) | Should -Not -Contain 'table 60000'

            { Test-IntroducedObjectIDsAreInAllowedRange -CurrentObjects $currentObjects -BaseObjects $baseObjects -AllowedRanges $script:AllowedRanges } | Should -Throw
        }
    }
}