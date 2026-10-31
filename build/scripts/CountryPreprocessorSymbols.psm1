$script:BuildCountryCodes = @(
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '..\projects') -Directory |
        Where-Object Name -Match '^Apps (W1|[A-Z]{2})$' |
        ForEach-Object { $_.Name.Substring(5) }
)

<#
.SYNOPSIS
    Gets the country preprocessor symbols declared for selected applications.
.DESCRIPTION
    Validates country-to-symbol mappings and returns sorted, unique symbols.
    Country codes are case-insensitive; WW is normalized to W1. AllApplications
    returns the complete declared symbol allow-list without filtering by country.
.PARAMETER ApplicationNames
    Application names whose country-specific symbols should be returned.
.PARAMETER CountryCode
    Build country for which to resolve the selected applications' symbols.
.PARAMETER AllApplications
    Returns symbols declared by every application for every configured country.
.PARAMETER Projects
    Optional projects metadata object. Defaults to the projects property in build\projects.json.
.OUTPUTS
    System.String
.EXAMPLE
    Get-CountryPreprocessorSymbols -ApplicationNames Intercompany -CountryCode AU
    Returns the Intercompany symbols configured for Australia.
.EXAMPLE
    Get-CountryPreprocessorSymbols -AllApplications
    Returns all declared country symbols for source validation.
#>
function Get-CountryPreprocessorSymbols {
    [CmdletBinding(DefaultParameterSetName = 'Application')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Application')]
        [string[]] $ApplicationNames,
        [Parameter(Mandatory, ParameterSetName = 'Application')]
        [string] $CountryCode,
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $AllApplications,
        [psobject] $Projects
    )

    if ($null -eq $Projects) {
        $Projects = (Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\projects.json') -Raw | ConvertFrom-Json).projects
    }

    if (-not $AllApplications) {
        $CountryCode = $CountryCode.ToUpperInvariant()
        if ($CountryCode -eq 'WW') { $CountryCode = 'W1' }
        if ($CountryCode -notin $script:BuildCountryCodes) {
            throw "Unknown build country '$CountryCode'."
        }
    } else {
        $ApplicationNames = @($Projects.PSObject.Properties.Name)
    }

    $symbols = @(
        foreach ($applicationName in $ApplicationNames) {
            $project = $Projects.PSObject.Properties[$applicationName]
            if ($null -eq $project) {
                throw "Unknown application '$applicationName' in country preprocessor symbol configuration."
            }
            $configuration = $project.Value.PSObject.Properties['countryPreprocessorSymbols']
            if ($null -eq $configuration) { continue }
            if ($configuration.Value -isnot [pscustomobject]) {
                throw "countryPreprocessorSymbols for '$applicationName' must be a country-to-symbol-array mapping."
            }

            foreach ($country in $configuration.Value.PSObject.Properties) {
                if ($country.Name -cnotmatch '^(W1|[A-Z]{2})$' -or $country.Name -notin $script:BuildCountryCodes) {
                    throw "Unknown country '$($country.Name)' in countryPreprocessorSymbols for '$applicationName'."
                }
                if ($country.Value -isnot [array] -or $country.Value.Count -eq 0) {
                    throw "Country '$($country.Name)' for '$applicationName' must declare a nonempty symbol array."
                }
                foreach ($symbol in $country.Value) {
                    if ($symbol -isnot [string] -or $symbol -cnotmatch '^[A-Z][A-Z0-9]*_[A-Z0-9_]+$' -or $symbol -match '^CLEAN') {
                        throw "Invalid feature-qualified country symbol '$symbol' for '$applicationName'."
                    }
                    if ($AllApplications -or $country.Name -eq $CountryCode) {
                        $symbol
                    }
                }
            }
        }
    )
    $symbols | Sort-Object -Unique
}

<#
.SYNOPSIS
    Gets preprocessor symbols for the default build baseline.
.DESCRIPTION
    Removes numbered CLEAN and CLEANSCHEMA symbols while retaining localization
    and unrelated feature flags. Returns sorted, unique symbols.
.PARAMETER PreprocessorSymbols
    Symbols from the current build configuration. An empty collection is allowed.
.OUTPUTS
    System.String
.EXAMPLE
    Get-DefaultBuildPreprocessorSymbols -PreprocessorSymbols CLEAN30, INTERCOMPANY_NO, DEBUG
    Returns DEBUG and INTERCOMPANY_NO.
#>
function Get-DefaultBuildPreprocessorSymbols {
    param(
        [AllowEmptyCollection()]
        [string[]] $PreprocessorSymbols = @()
    )

    $PreprocessorSymbols |
        Where-Object { $_ -notmatch '^CLEAN(?:SCHEMA)?[0-9]+$' } |
        Sort-Object -Unique
}

Export-ModuleMember -Function Get-CountryPreprocessorSymbols, Get-DefaultBuildPreprocessorSymbols
