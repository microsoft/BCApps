Describe "Test-PreprocessorSymbols" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\..\..\build\scripts\TestPreprocessorSymbols.psm1" -Force
    }

    It 'returns $null when the filepath extension is not .al' {
        $result = Test-PreprocessorSymbols -filePath 'Dummy.txt' -symbolConfigs @(@{'stem' = "CLEAN"; 'lowerBound' = 1; 'upperBound' = 1})
        $result | Should -Be $null
    }

    It 'returns $null when the file contains lowercase preprocessors with correct symbols and versions' {
        $alcontent = @(
'codeunit 123 TestPreprocessors
{
#if CLEAN1
#endif

#if not CLEAN2
#endif

#if CLEAN3
#else
#endif

#if CLEAN4
#elseif CLEAN5
#endif
}')
        Set-Content -Path TestDrive:\Dummy.al -Value $alcontent
        Mock -CommandName Get-Content  { return Get-Content TestDrive:\dummy.al}

        $result = Test-PreprocessorSymbols -filePath 'TestDrive:\dummy.al' -symbolConfigs @(@{'stem' = "CLEAN"; 'lowerBound' = 1; 'upperBound' = 5})

        $result | Should -Be $null
    }

    It 'returns $null when the file contains lowercase preprocessors with multiple correct symbolstems and versions' {
        $alcontent = @(
'codeunit 123 TestPreprocessors
{
#if CLEAN1
#endif

#if not CLEANSCHEMA2
#endif

#if MYSPECIALCASE3
#else
#endif
}')
        Set-Content -Path TestDrive:\Dummy.al -Value $alcontent
        Mock -CommandName Get-Content  { return Get-Content TestDrive:\dummy.al}

        $symbolConfigs = @(
            @{stem="CLEAN"; lowerBound=1; upperBound=3},
            @{stem="CLEANSCHEMA"; lowerBound=1; upperBound=3},
            @{stem="MYSPECIALCASE"; lowerBound=1; upperBound=3}
        )
        $result = Test-PreprocessorSymbols -filePath 'TestDrive:\dummy.al' -symbolConfigs $symbolConfigs

        $result | Should -Be $null
    }

    It 'returns invalidLowercaseSymbols when the file contains not lowercase preprocessor symbols' {
        $alcontent = @(
'codeunit 123 TestPreprocessors
{
#IF CLEAN1
#endif

#if NOT CLEAN2
#endif

#if CLEAN3
#ELSE
#endif

#if CLEAN4
#elseif CLEAN5
#ENDIF

#If CLEAN6
#EnDiF

#iF CLEAN7
#Else
#EndIf
}')
        Set-Content -Path TestDrive:\Dummy.al -Value $alcontent
        Mock -CommandName Get-Content  { return Get-Content TestDrive:\dummy.al}

        $result = Test-PreprocessorSymbols -filePath 'TestDrive:\dummy.al' -symbolConfigs @(@{'stem' = "CLEAN"; 'lowerBound' = 1; 'upperBound' = 7})

        $result.count | Should -Be 3
        $result.invalidLowercaseSymbols.Count | Should -Be 9
        $result.invalidPatternSymbols.Count | Should -Be 0
        $result.invalidStemSymbols.Count | Should -Be 0

        $result.invalidLowercaseSymbols | Should -Be @('TestDrive:\dummy.al:3: #IF CLEAN1', 'TestDrive:\dummy.al:6: #if NOT CLEAN2', 'TestDrive:\dummy.al:10: #ELSE', 'TestDrive:\dummy.al:15: #ENDIF', 'TestDrive:\dummy.al:17: #If CLEAN6', 'TestDrive:\dummy.al:18: #EnDiF', 'TestDrive:\dummy.al:20: #iF CLEAN7', 'TestDrive:\dummy.al:21: #Else', 'TestDrive:\dummy.al:22: #EndIf').
        $result.invalidPatternSymbols | Should -Be @().
        $result.invalidStemSymbols | Should -Be @().
    }

    It 'returns invalidPatternSymbols when the spacing is not correct' {
        $alcontent = @(
'codeunit 123 TestPreprocessors
{
# if CLEAN1
#endif

#if not  CLEAN2
#endif

#if  not CLEAN3
#endif

#if CLEAN4
# endif

#if CLEAN4
# else
#endif

#if CLEAN5
# elseif CLEAN6
#endif

#if  CLEAN7
#endif
}')
        Set-Content -Path TestDrive:\Dummy.al -Value $alcontent
        Mock -CommandName Get-Content  { return Get-Content TestDrive:\dummy.al}

        $result = Test-PreprocessorSymbols -filePath 'TestDrive:\dummy.al' -symbolConfigs @(@{'stem' = "CLEAN"; 'lowerBound' = 1; 'upperBound' = 7})

        $result.count | Should -Be 3
        $result.invalidLowercaseSymbols.Count | Should -Be 0
        $result.invalidPatternSymbols.Count | Should -Be 7
        $result.invalidStemSymbols.Count | Should -Be 0

        $result.invalidLowercaseSymbols | Should -Be @().
        $result.invalidPatternSymbols | Should -Be @('TestDrive:\dummy.al:3: # if CLEAN1', 'TestDrive:\dummy.al:6: #if not  CLEAN2', 'TestDrive:\dummy.al:9: #if  not CLEAN3', 'TestDrive:\dummy.al:13: # endif', 'TestDrive:\dummy.al:16: # else', 'TestDrive:\dummy.al:20: # elseif CLEAN6', 'TestDrive:\dummy.al:23: #if  CLEAN7').
        $result.invalidStemSymbols | Should -Be @().
    }

    It 'returns invalidPatternSymbols when the version is not correct' {
        $alcontent = @(
'codeunit 123 TestPreprocessors
{
#if CLEAN
#endif

#if CLEAN1
#endif

#if not CLEAN2
#endif

#if CLEAN3
#elseif CLEAN4
#endif

#if CLEAN8
#endif

#if CLEAN12
#endif

#if not CLEAN13
#endif

#if CLEAN14
#elseif CLEAN15
#endif

}')
        Set-Content -Path TestDrive:\Dummy.al -Value $alcontent
        Mock -CommandName Get-Content  { return Get-Content TestDrive:\dummy.al}

        $result = Test-PreprocessorSymbols -filePath 'TestDrive:\dummy.al' -symbolConfigs @(@{'stem' = "CLEAN"; 'lowerBound' = 5; 'upperBound' = 11})

        $result.count | Should -Be 3
        $result.invalidLowercaseSymbols.Count | Should -Be 0
        $result.invalidPatternSymbols.Count | Should -Be 9
        $result.invalidStemSymbols.Count | Should -Be 0

        $result.invalidLowercaseSymbols | Should -Be @().
        $result.invalidPatternSymbols | Should -Be @('TestDrive:\dummy.al:3: #if CLEAN', 'TestDrive:\dummy.al:6: #if CLEAN1', 'TestDrive:\dummy.al:9: #if not CLEAN2', 'TestDrive:\dummy.al:12: #if CLEAN3', 'TestDrive:\dummy.al:13: #elseif CLEAN4', 'TestDrive:\dummy.al:19: #if CLEAN12', 'TestDrive:\dummy.al:22: #if not CLEAN13', 'TestDrive:\dummy.al:25: #if CLEAN14', 'TestDrive:\dummy.al:26: #elseif CLEAN15')
        $result.invalidStemSymbols | Should -Be @().
    }

    It 'returns invalidPatternSymbols when the symbol stem is not correct' {
        $alcontent = @(
'codeunit 123 TestPreprocessors
{
#if CLEANT1
#endif

#if not SCLEAN2
#endif

#if SUPERCLEAN3
#elseif CLEANMORE4
#endif

#if FUBAR
#endif

#if CLEAN7
#endif

#if RELEASE
#endif

#if not RELEASE12
#endif
}')
        Set-Content -Path TestDrive:\Dummy.al -Value $alcontent
        Mock -CommandName Get-Content  { return Get-Content TestDrive:\dummy.al}

        $result = Test-PreprocessorSymbols -filePath 'TestDrive:\dummy.al' -symbolConfigs @(@{'stem' = "CLEAN"; 'lowerBound' = 5; 'upperBound' = 11})

        $result.count | Should -Be 3
        $result.invalidLowercaseSymbols.Count | Should -Be 0
        $result.invalidPatternSymbols.Count | Should -Be 7
        $result.invalidStemSymbols.Count | Should -Be 0

        $result.invalidLowercaseSymbols | Should -Be @().
        $result.invalidPatternSymbols | Should -Be @('TestDrive:\dummy.al:3: #if CLEANT1', 'TestDrive:\dummy.al:6: #if not SCLEAN2', 'TestDrive:\dummy.al:9: #if SUPERCLEAN3', 'TestDrive:\dummy.al:10: #elseif CLEANMORE4', 'TestDrive:\dummy.al:13: #if FUBAR', 'TestDrive:\dummy.al:19: #if RELEASE', 'TestDrive:\dummy.al:22: #if not RELEASE12')
        $result.invalidStemSymbols | Should -Be @().
    }

    It 'returns invalidStemSymbols when the symbol is not all uppercase' {
        $alcontent = @(
'codeunit 123 TestPreprocessors
{
#if clean1
#endif

#if not Clean2
#endif

#if ClEaN3
#else
#endif

#if cleaN4
#elseif CleaN5
#endif
}')
        Set-Content -Path TestDrive:\Dummy.al -Value $alcontent
        Mock -CommandName Get-Content  { return Get-Content TestDrive:\dummy.al}

        $result = Test-PreprocessorSymbols -filePath 'TestDrive:\dummy.al' -symbolConfigs @(@{'stem' = "CLEAN"; 'lowerBound' = 1; 'upperBound' = 5})

        $result.count | Should -Be 3
        $result.invalidLowercaseSymbols.Count | Should -Be 0
        $result.invalidPatternSymbols.Count | Should -Be 0
        $result.invalidStemSymbols.Count | Should -Be 5

        $result.invalidLowercaseSymbols | Should -Be @().
        $result.invalidPatternSymbols | Should -Be @().
        $result.invalidStemSymbols | Should -Be @('TestDrive:\dummy.al:3: #if clean1', 'TestDrive:\dummy.al:6: #if not Clean2', 'TestDrive:\dummy.al:9: #if ClEaN3', 'TestDrive:\dummy.al:13: #if cleaN4', 'TestDrive:\dummy.al:14: #elseif CleaN5').
    }


    It 'returns errors' {
        $alcontent = @(
'codeunit 123 TestPreprocessors
{
#if not CLEAN18
#endif

# if CLEAN25
#ELSE
#endif

#if not CLEANschema22
#endif

#if CLEANUP12
#elseif CLEANSCHEMA34
#endif
}')
        Set-Content -Path TestDrive:\Dummy.al -Value $alcontent
        Mock -CommandName Get-Content  { return Get-Content TestDrive:\dummy.al}

        $symbolConfigs = @(
            @{stem = "CLEAN"; lowerBound = 22; upperBound = 26},
            @{stem = "CLEANSCHEMA"; lowerBound = 15; upperBound = 29}
        )

        $result = Test-PreprocessorSymbols -filePath 'TestDrive:\dummy.al' -symbolConfigs $symbolConfigs

        $result.count | Should -Be 3
        $result.invalidLowercaseSymbols.Count | Should -Be 1
        $result.invalidPatternSymbols.Count | Should -Be 4
        $result.invalidStemSymbols.Count | Should -Be 1

        $result.invalidLowercaseSymbols | Should -Be @('TestDrive:\dummy.al:7: #ELSE').
        $result.invalidPatternSymbols | Should -Be @('TestDrive:\dummy.al:3: #if not CLEAN18', 'TestDrive:\dummy.al:6: # if CLEAN25', 'TestDrive:\dummy.al:13: #if CLEANUP12', 'TestDrive:\dummy.al:14: #elseif CLEANsCHEMA34').
        $result.invalidStemSymbols | Should -Be @('TestDrive:\dummy.al:10: #if not CLEANschema22').
    }
}
