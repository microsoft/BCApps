Describe "Test-ObsoleteTagPreprocessors" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\..\..\build\scripts\TestObsoleteTagPreprocessors.psm1" -Force
    }

    It 'returns $null when the file does not exist' {
        $result = Test-ObsoleteTagPreprocessors -filePath 'TestDrive:\DoesNotExist.al'
        $result | Should -Be $null
    }

    It 'returns $null when the file contains no ObsoleteTag property' {
        $alcontent = @'
table 50000 "Test Table"
{
    fields
    {
        field(1; "My Field"; Code[10])
        {
            Caption = 'My Field';
        }
    }
}
'@
        Set-Content -Path TestDrive:\NoTag.al -Value $alcontent
        $result = Test-ObsoleteTagPreprocessors -filePath 'TestDrive:\NoTag.al'
        $result | Should -Be $null
    }

    It 'returns $null when the ObsoleteTag is surrounded by preprocessor symbols' {
        $alcontent = @'
table 50000 "Test Table"
{
    fields
    {
#if not CLEANSCHEMA30
        field(1; "My Field"; Code[10])
        {
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
        }
#endif
    }
}
'@
        Set-Content -Path TestDrive:\Wrapped.al -Value $alcontent
        $result = Test-ObsoleteTagPreprocessors -filePath 'TestDrive:\Wrapped.al'
        $result | Should -Be $null
    }

    It 'returns issues when an ObsoleteTag is outside a preprocessor block' {
        $alcontent = @'
table 50000 "Test Table"
{
    fields
    {
        field(1; "My Field"; Code[10])
        {
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
        }
    }
}
'@
        Set-Content -Path TestDrive:\Bare.al -Value $alcontent
        $result = Test-ObsoleteTagPreprocessors -filePath 'TestDrive:\Bare.al'
        $result | Should -Not -Be $null
        $result.Issues.Count | Should -Be 1
        $result.Issues[0] | Should -BeLike '*ObsoleteTag found outside preprocessor block*'
    }

    It 'returns one issue per unwrapped ObsoleteTag' {
        $alcontent = @'
table 50000 "Test Table"
{
    fields
    {
        field(1; "Field One"; Code[10])
        {
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
        }
        field(2; "Field Two"; Code[10])
        {
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
        }
    }
}
'@
        Set-Content -Path TestDrive:\TwoBare.al -Value $alcontent
        $result = Test-ObsoleteTagPreprocessors -filePath 'TestDrive:\TwoBare.al'
        $result.Issues.Count | Should -Be 2
    }

    It 'ignores ObsoleteTag inside a single-line comment' {
        $alcontent = @'
table 50000 "Test Table"
{
    // ObsoleteTag = '30.0';
    fields
    {
        field(1; "My Field"; Code[10])
        {
            Caption = 'My Field';
        }
    }
}
'@
        Set-Content -Path TestDrive:\Commented.al -Value $alcontent
        $result = Test-ObsoleteTagPreprocessors -filePath 'TestDrive:\Commented.al'
        $result | Should -Be $null
    }

    It 'returns $null when the file is in the exception list' {
        $alcontent = @'
table 50000 "Test Table"
{
    fields
    {
        field(1; "My Field"; Code[10])
        {
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
        }
    }
}
'@
        Set-Content -Path TestDrive:\ObsoleteRemovedTable.Table.al -Value $alcontent
        $result = Test-ObsoleteTagPreprocessors -filePath 'TestDrive:\ObsoleteRemovedTable.Table.al' -ExceptionList @('ObsoleteRemovedTable.Table.al')
        $result | Should -Be $null
    }
}
