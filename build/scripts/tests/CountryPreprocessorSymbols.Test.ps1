Describe 'Country preprocessor symbols' {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\CountryPreprocessorSymbols.psm1" -Force
    }

    BeforeEach {
        $script:projects = @'
{
  "Base Application": {
    "countryPreprocessorSymbols": {
      "AU": ["SERVICEMANAGEMENT_APAC"],
      "NZ": ["SERVICEMANAGEMENT_APAC"],
      "NO": ["SERVICEMANAGEMENT_NO"]
    }
  },
  "Other App": {
    "countryPreprocessorSymbols": {
      "AU": ["OTHERAPP_AU", "SERVICEMANAGEMENT_APAC"]
    }
  },
  "Unlocalized App": {}
}
'@ | ConvertFrom-Json
    }

    It 'resolves a shared regional symbol without enabling another application' {
        @(Get-CountryPreprocessorSymbols -ApplicationNames 'Base Application' -CountryCode au -Projects $projects) |
            Should -Be @('SERVICEMANAGEMENT_APAC')
        @(Get-CountryPreprocessorSymbols -ApplicationNames 'Base Application' -CountryCode NZ -Projects $projects) |
            Should -Be @('SERVICEMANAGEMENT_APAC')
    }

    It 'unions and deduplicates selected application symbols for workspace compilation' {
        @(Get-CountryPreprocessorSymbols -ApplicationNames @('Base Application', 'Other App') -CountryCode AU -Projects $projects) |
            Should -Be @('OTHERAPP_AU', 'SERVICEMANAGEMENT_APAC')
    }

    It 'does not enable localization symbols for an unconfigured country or application' {
        @(Get-CountryPreprocessorSymbols -ApplicationNames 'Base Application' -CountryCode GB -Projects $projects).Count |
            Should -Be 0
        @(Get-CountryPreprocessorSymbols -ApplicationNames 'Unlocalized App' -CountryCode AU -Projects $projects).Count |
            Should -Be 0
    }

    It 'normalizes the internal WW alias to W1' {
        $projects.'Base Application'.countryPreprocessorSymbols | Add-Member -NotePropertyName W1 -NotePropertyValue @('SERVICEMANAGEMENT_BASE')
        @(Get-CountryPreprocessorSymbols -ApplicationNames 'Base Application' -CountryCode WW -Projects $projects) |
            Should -Be @('SERVICEMANAGEMENT_BASE')
    }

    It 'returns the exact declared symbol allow-list for source validation' {
        @(Get-CountryPreprocessorSymbols -AllApplications -Projects $projects) |
            Should -Be @('OTHERAPP_AU', 'SERVICEMANAGEMENT_APAC', 'SERVICEMANAGEMENT_NO')
    }

    It 'rejects an unknown application instead of silently omitting its symbols' {
        { Get-CountryPreprocessorSymbols -ApplicationNames Missing -CountryCode AU -Projects $projects } |
            Should -Throw "*Unknown application 'Missing'*"
    }

    It 'rejects an unknown build country' {
        { Get-CountryPreprocessorSymbols -ApplicationNames 'Base Application' -CountryCode ZZ -Projects $projects } |
            Should -Throw "*Unknown build country 'ZZ'*"
    }

    It 'rejects an invalid country declaration even when resolving another country' {
        $projects.'Base Application'.countryPreprocessorSymbols | Add-Member -NotePropertyName ZZ -NotePropertyValue @('SERVICEMANAGEMENT_BAD')
        { Get-CountryPreprocessorSymbols -ApplicationNames 'Base Application' -CountryCode AU -Projects $projects } |
            Should -Throw "*Unknown country 'ZZ'*"
    }

    It 'rejects symbols that are not uppercase feature-qualified names' -TestCases @(
        @{ Symbol = 'servicemanagement_no' }
        @{ Symbol = 'NO' }
        @{ Symbol = 'CLEAN30' }
        @{ Symbol = 'CLEAN_COUNTRY' }
        @{ Symbol = 'SERVICEMANAGEMENT-NO' }
    ) {
        param($Symbol)
        $projects.'Base Application'.countryPreprocessorSymbols.NO = @($Symbol)
        { Get-CountryPreprocessorSymbols -AllApplications -Projects $projects } |
            Should -Throw '*Invalid feature-qualified country symbol*'
    }

    It 'rejects scalar symbol declarations instead of treating strings as arrays' {
        $projects.'Base Application'.countryPreprocessorSymbols.NO = 'SERVICEMANAGEMENT_NO'
        { Get-CountryPreprocessorSymbols -AllApplications -Projects $projects } |
            Should -Throw '*must declare a nonempty symbol array*'
    }

    It 'rejects empty symbol declarations' {
        $projects.'Base Application'.countryPreprocessorSymbols.NO = @()
        { Get-CountryPreprocessorSymbols -AllApplications -Projects $projects } |
            Should -Throw '*must declare a nonempty symbol array*'
    }

    It 'retains localization and unrelated flags when generating the default CLEAN baseline' {
        $symbols = @('CLEAN25', 'CLEAN30', 'CLEANSCHEMA29', 'SERVICEMANAGEMENT_NA', 'OTHERAPP_CLEAN', 'DEBUG', 'SERVICEMANAGEMENT_NA')
        @(Get-DefaultBuildPreprocessorSymbols -PreprocessorSymbols $symbols) |
            Should -Be @('DEBUG', 'OTHERAPP_CLEAN', 'SERVICEMANAGEMENT_NA')
    }

    It 'supports a default baseline with no preprocessor symbols' {
        @(Get-DefaultBuildPreprocessorSymbols -PreprocessorSymbols @()).Count | Should -Be 0
    }

    It 'resolves Service Management localization for <Country>' -TestCases @(
        @{ Country = 'AU'; Expected = 'SERVICEMANAGEMENT_APAC' }
        @{ Country = 'NZ'; Expected = 'SERVICEMANAGEMENT_APAC' }
        @{ Country = 'CA'; Expected = 'SERVICEMANAGEMENT_NA' }
        @{ Country = 'MX'; Expected = 'SERVICEMANAGEMENT_NA' }
        @{ Country = 'US'; Expected = 'SERVICEMANAGEMENT_NA' }
        @{ Country = 'BE'; Expected = 'SERVICEMANAGEMENT_BE' }
        @{ Country = 'CH'; Expected = 'SERVICEMANAGEMENT_CH' }
        @{ Country = 'ES'; Expected = 'SERVICEMANAGEMENT_ES' }
        @{ Country = 'FI'; Expected = 'SERVICEMANAGEMENT_FI' }
        @{ Country = 'IT'; Expected = 'SERVICEMANAGEMENT_IT' }
        @{ Country = 'NL'; Expected = 'SERVICEMANAGEMENT_NL' }
        @{ Country = 'NO'; Expected = 'SERVICEMANAGEMENT_NO' }
        @{ Country = 'W1'; Expected = $null }
        @{ Country = 'AT'; Expected = $null }
        @{ Country = 'CZ'; Expected = $null }
        @{ Country = 'DE'; Expected = $null }
        @{ Country = 'DK'; Expected = $null }
        @{ Country = 'FR'; Expected = $null }
        @{ Country = 'GB'; Expected = $null }
        @{ Country = 'IN'; Expected = $null }
        @{ Country = 'IS'; Expected = $null }
        @{ Country = 'RU'; Expected = $null }
        @{ Country = 'SE'; Expected = $null }
    ) {
        param($Country, $Expected)
        @(Get-CountryPreprocessorSymbols -ApplicationNames 'Base Application' -CountryCode $Country) |
            Should -Be @($Expected | Where-Object { $_ })
    }
}
