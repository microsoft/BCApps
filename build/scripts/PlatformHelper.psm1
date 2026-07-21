$script:PlatformCdnUrl = 'https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net'
$script:PlatformIndexUrl = "$script:PlatformCdnUrl/platform/indexes/platform.json"
$script:PlatformVersionsCache = $null

<#
.SYNOPSIS
    Downloads and caches the platform version index.
.DESCRIPTION
    Fetches the platform.json index file from the CDN and caches it
    for subsequent calls within the same session.
.PARAMETER Force
    When specified, forces a refresh of the cached version index.
.OUTPUTS
    Array of version strings available in the platform index.
#>
function Get-PlatformVersions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch] $Force,
        [Parameter(Mandatory = $false)]
        [int] $RetryCount = 3,
        [Parameter(Mandatory = $false)]
        [int] $RetryDelaySeconds = 30
    )

    if ($null -eq $script:PlatformVersionsCache -or $Force) {
        $lastException = $null
        for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
            try {
                Write-Host "Fetching platform version index from $script:PlatformIndexUrl (attempt $attempt of $RetryCount)"
                $response = Invoke-WebRequest -Uri $script:PlatformIndexUrl -ErrorAction Stop
                $index = @($response.Content | ConvertFrom-Json)
                if ($index.Count -gt 0 -and $index[0].PSObject.Properties['Version']) {
                    $script:PlatformVersionsCache = @($index | ForEach-Object { $_.Version })
                } else {
                    $script:PlatformVersionsCache = $index
                }
                $lastException = $null
                break
            }
            catch {
                $lastException = $_
                if ($attempt -lt $RetryCount) {
                    Write-Warning "Attempt $attempt failed: $($_.Exception.Message). Retrying in $RetryDelaySeconds seconds..."
                    Start-Sleep -Seconds $RetryDelaySeconds
                }
            }
        }
        if ($null -ne $lastException) {
            throw "Failed to fetch platform version index from '$script:PlatformIndexUrl': $($lastException.Exception.Message)"
        }
    }

    return $script:PlatformVersionsCache
}

<#
.SYNOPSIS
    Gets the full CDN URL for a specific platform version.
.DESCRIPTION
    Constructs and returns the full CDN URL for downloading a specific platform version.
    Validates that the version exists in the platform index.
.PARAMETER Version
    The full platform version string (e.g., '29.0.49913.0').
.OUTPUTS
    The full CDN URL for the specified platform version.
.EXAMPLE
    Get-PlatformVersionUrl -Version '29.0.49913.0'
    Returns: https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/platform/29.0.49913.0
#>
function Get-PlatformVersionUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Version
    )

    $availableVersions = Get-PlatformVersions
    if ($availableVersions -notcontains $Version) {
        throw "Platform version '$Version' is not available. Use Get-PlatformVersions to see available versions."
    }

    return "$script:PlatformCdnUrl/platform/$Version"
}

<#
.SYNOPSIS
    Finds the latest platform version matching a major.minor pattern.
.DESCRIPTION
    Searches the platform version index for versions matching the specified
    major and minor version numbers, and returns the latest (highest) matching version.
.PARAMETER MajorMinor
    The major.minor version pattern to match (e.g., '29.0').
.OUTPUTS
    The latest version string matching the major.minor pattern, or $null if no match found.
.EXAMPLE
    Get-LatestPlatformVersion -MajorMinor '29.0'
    Returns: '29.0.49913.0' (or whatever the latest 29.0.x.x version is)
#>
function Get-LatestPlatformVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $MajorMinor
    )

    $availableVersions = Get-PlatformVersions

    # Parse the major.minor input
    $parts = $MajorMinor.Split('.')
    if ($parts.Count -lt 2) {
        throw "Invalid MajorMinor format '$MajorMinor'. Expected format: 'major.minor' (e.g., '29.0')."
    }

    $major = [int]$parts[0]
    $minor = [int]$parts[1]

    # Filter versions matching major.minor and sort to find the latest
    $matchingVersions = @($availableVersions | Where-Object {
        try {
            $ver = [System.Version]$_
            $ver.Major -eq $major -and $ver.Minor -eq $minor
        }
        catch {
            $false
        }
    } | Sort-Object { [System.Version]$_ })

    if ($matchingVersions.Count -eq 0) {
        return $null
    }

    return $matchingVersions[$matchingVersions.Count - 1]
}

<#
.SYNOPSIS
    Resolves a platform version setting to a full platform version.
.DESCRIPTION
    Accepts either a full platform version (e.g. '29.0.49913.0') or a
    major.minor pattern (e.g. '29.0'). When a major.minor pattern is given,
    the highest available version matching that pattern is returned.
.PARAMETER Version
    The platform version setting to resolve. Either a full version or a
    major.minor pattern.
.OUTPUTS
    The resolved full platform version string.
.EXAMPLE
    Resolve-PlatformVersion -Version '29.0'
    Returns: '29.0.49913.0' (the highest available 29.0.x.x version)
.EXAMPLE
    Resolve-PlatformVersion -Version '29.0.49913.0'
    Returns: '29.0.49913.0'
#>
function Resolve-PlatformVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Version
    )

    # A full version has 4 parts (major.minor.build.revision); a pattern has only major.minor
    if ($Version.Split('.').Count -eq 2) {
        $resolvedVersion = Get-LatestPlatformVersion -MajorMinor $Version
        if ($null -eq $resolvedVersion) {
            throw "No platform version found matching major.minor '$Version'."
        }
        return $resolvedVersion
    }

    return $Version
}

<#
.SYNOPSIS
    Clears the cached platform version index.
.DESCRIPTION
    Clears the in-memory cache of the platform version index, forcing a
    fresh download on the next call to Get-PlatformVersions.
#>
function Clear-PlatformVersionCache {
    [CmdletBinding()]
    param()

    $script:PlatformVersionsCache = $null
}

Export-ModuleMember -Function @(
    'Get-PlatformVersions',
    'Get-PlatformVersionUrl',
    'Get-LatestPlatformVersion',
    'Resolve-PlatformVersion',
    'Clear-PlatformVersionCache'
)
