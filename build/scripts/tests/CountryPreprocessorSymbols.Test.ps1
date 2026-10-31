Describe 'Country preprocessor symbols' {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\CountryPreprocessorSymbols.psm1" -Force
    }

    BeforeEach {
        $script:projects = @'
{
  "Intercompany": {
    "countryPreprocessorSymbols": {
      "AU": ["INTERCOMPANY_APAC"],
      "NZ": ["INTERCOMPANY_APAC"],
      "NO": ["INTERCOMPANY_NO"]
    }
  },
  "Other App": {
    "countryPreprocessorSymbols": {
      "AU": ["OTHERAPP_AU", "INTERCOMPANY_APAC"]
    }
  },
  "Unlocalized App": {}
}
'@ | ConvertFrom-Json
    }

    It 'resolves a shared regional symbol without enabling another application' {
        @(Get-CountryPreprocessorSymbols -ApplicationNames Intercompany -CountryCode au -Projects $projects) |
            Should -Be @('INTERCOMPANY_APAC')
        @(Get-CountryPreprocessorSymbols -ApplicationNames Intercompany -CountryCode NZ -Projects $projects) |
            Should -Be @('INTERCOMPANY_APAC')
    }

    It 'unions and deduplicates selected application symbols for workspace compilation' {
        @(Get-CountryPreprocessorSymbols -ApplicationNames @('Intercompany', 'Other App') -CountryCode AU -Projects $projects) |
            Should -Be @('INTERCOMPANY_APAC', 'OTHERAPP_AU')
    }

    It 'does not enable localization symbols for an unconfigured country or application' {
        @(Get-CountryPreprocessorSymbols -ApplicationNames Intercompany -CountryCode GB -Projects $projects).Count |
            Should -Be 0
        @(Get-CountryPreprocessorSymbols -ApplicationNames 'Unlocalized App' -CountryCode AU -Projects $projects).Count |
            Should -Be 0
    }

    It 'normalizes the internal WW alias to W1' {
        $projects.Intercompany.countryPreprocessorSymbols | Add-Member -NotePropertyName W1 -NotePropertyValue @('INTERCOMPANY_BASE')
        @(Get-CountryPreprocessorSymbols -ApplicationNames Intercompany -CountryCode WW -Projects $projects) |
            Should -Be @('INTERCOMPANY_BASE')
    }

    It 'returns the exact declared symbol allow-list for source validation' {
        @(Get-CountryPreprocessorSymbols -AllApplications -Projects $projects) |
            Should -Be @('INTERCOMPANY_APAC', 'INTERCOMPANY_NO', 'OTHERAPP_AU')
    }

    It 'rejects an unknown application instead of silently omitting its symbols' {
        { Get-CountryPreprocessorSymbols -ApplicationNames Missing -CountryCode AU -Projects $projects } |
            Should -Throw "*Unknown application 'Missing'*"
    }

    It 'rejects an unknown build country' {
        { Get-CountryPreprocessorSymbols -ApplicationNames Intercompany -CountryCode ZZ -Projects $projects } |
            Should -Throw "*Unknown build country 'ZZ'*"
    }

    It 'rejects an invalid country declaration even when resolving another country' {
        $projects.Intercompany.countryPreprocessorSymbols | Add-Member -NotePropertyName ZZ -NotePropertyValue @('INTERCOMPANY_BAD')
        { Get-CountryPreprocessorSymbols -ApplicationNames Intercompany -CountryCode AU -Projects $projects } |
            Should -Throw "*Unknown country 'ZZ'*"
    }

    It 'rejects symbols that are not uppercase feature-qualified names' -TestCases @(
        @{ Symbol = 'intercompany_no' }
        @{ Symbol = 'NO' }
        @{ Symbol = 'CLEAN30' }
        @{ Symbol = 'CLEAN_COUNTRY' }
        @{ Symbol = 'INTERCOMPANY-NO' }
    ) {
        param($Symbol)
        $projects.Intercompany.countryPreprocessorSymbols.NO = @($Symbol)
        { Get-CountryPreprocessorSymbols -AllApplications -Projects $projects } |
            Should -Throw '*Invalid feature-qualified country symbol*'
    }

    It 'rejects scalar symbol declarations instead of treating strings as arrays' {
        $projects.Intercompany.countryPreprocessorSymbols.NO = 'INTERCOMPANY_NO'
        { Get-CountryPreprocessorSymbols -AllApplications -Projects $projects } |
            Should -Throw '*must declare a nonempty symbol array*'
    }

    It 'rejects empty symbol declarations' {
        $projects.Intercompany.countryPreprocessorSymbols.NO = @()
        { Get-CountryPreprocessorSymbols -AllApplications -Projects $projects } |
            Should -Throw '*must declare a nonempty symbol array*'
    }

    It 'retains localization and unrelated flags when generating the default CLEAN baseline' {
        $symbols = @('CLEAN25', 'CLEAN30', 'CLEANSCHEMA29', 'INTERCOMPANY_NA', 'OTHERAPP_CLEAN', 'DEBUG', 'INTERCOMPANY_NA')
        @(Get-DefaultBuildPreprocessorSymbols -PreprocessorSymbols $symbols) |
            Should -Be @('DEBUG', 'INTERCOMPANY_NA', 'OTHERAPP_CLEAN')
    }

    It 'supports a default baseline with no preprocessor symbols' {
        @(Get-DefaultBuildPreprocessorSymbols -PreprocessorSymbols @()).Count | Should -Be 0
    }

    It 'resolves Intercompany localization for <Country>' -TestCases @(
        @{ Country = 'AU'; Expected = 'INTERCOMPANY_APAC' }
        @{ Country = 'NZ'; Expected = 'INTERCOMPANY_APAC' }
        @{ Country = 'CA'; Expected = 'INTERCOMPANY_NA' }
        @{ Country = 'MX'; Expected = 'INTERCOMPANY_NA' }
        @{ Country = 'US'; Expected = 'INTERCOMPANY_NA' }
        @{ Country = 'IT'; Expected = 'INTERCOMPANY_IT' }
        @{ Country = 'NO'; Expected = 'INTERCOMPANY_NO' }
    ) {
        param($Country, $Expected)
        @(Get-CountryPreprocessorSymbols -ApplicationNames Intercompany -CountryCode $Country) |
            Should -Be @($Expected)
    }
}
