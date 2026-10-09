Import-Module "$PSScriptRoot\MicroAppConf.psm1"
Import-Module "$PSScriptRoot\MicroAppGitHelper.psm1"
Import-Module "$PSScriptRoot\MicroAppIntegrate.psm1"

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Invoke-MiSnapApp
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true,
                   Position=0)]
        [Alias("c")]
        [string[]] $Files
    )
    begin {
        if(-not $Files) {
            # Default: validate all files committed since the base branch (origin/HEAD)
            $Files = Get-MiappCommittedFiles
        }
    }

    process {
        if (-not $Files) {
            Write-Host -ForegroundColor Green "SUCCESS: No files to validate"
            return
        }

        Write-Host "Validating propagation for $($Files.Count) file(s)..."

        [string[]] $actualFiles = $Files `
            | % { Expand-MiappExclusionFile $_ } `
            | ? { $_ } `
            | select -Unique
        [string[]] $expectedFiles = $actualFiles | % { GetBranchedObjectFileNames "$(Get-GitRoot)/$_" } | select -Unique
        [string[]] $missingFiles = $expectedFiles | ? { $actualFiles -inotcontains $_ }

        if($missingFiles) {
            Throw ("The following file(s) aren't in the changelist and still need to be integrated:"`
                + "`n$(($missingFiles | Sort-Object) -join "`n")")`
                + "`nMake sure you have run 'Invoke-Miapp' on your branch"
        }

        Write-Host -ForegroundColor Green "SUCCESS: No missing files"
    }
}

<#
.SYNOPSIS
Expands a committed Miapp exclusion snapshot into the file paths it excludes.

.DESCRIPTION
When a file lives under `MiappConfig.ExclusionDir` (the `.miappsnap` snapshot folder),
it is a JSON list of paths that were explicitly excluded from propagation via
'Invoke-Miapp'. Those paths are returned so they are treated as already integrated and
not reported as missing. Any other file is returned unchanged. This mirrors the original
NAV GitMiapp behavior that was lost when the verification step was ported to git.
#>
function Expand-MiappExclusionFile {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $File
    )

    [string] $parentPath = Get-CanonicalParentPath "$(Get-GitRoot)/$File" -RelativeToRepoRoot
    if ($parentPath -ieq $MiappConfig.ExclusionDir) {
        Get-ExclusionList "$(Get-GitRoot)/$File"
    } else {
        $File
    }
}

<#
.SYNOPSIS
Returns files committed locally since the base branch (origin/HEAD), relative to the repo root.
#>
function Get-MiappCommittedFiles {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    if (-not (Get-MiappBaseBranch)) {
        Write-Host -ForegroundColor Yellow "Could not determine the base branch from origin/HEAD. Cannot determine committed files."
        return
    }

    git diff --name-only "origin/$(Get-MiappBaseBranch)...HEAD" | ? { $_ }
}

function GetBranchedObjectFileNames {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [ValidateNotNullOrEmpty()]
        [string] $BranchPath = (Get-IntegrationBranchName $File)
    )

    if(-not (Test-FileHasToBeIntegrated $File)) {
        return
    }

    [string] $fileName = Get-IntegrationFileName $File
    [HashTable] $integrationDeps = $MiappConfig.IntegrationDeps

    foreach  ($branch in $integrationDeps[$BranchPath]) {
        [string] $branchFile = $integrationDeps[$File]
        if (-not $branchFile) { $branchFile = $branch+$fileName }
        $branchFile = Join-Path (Get-GitRoot) $branchFile
        if (Test-Path $branchFile) {
            GetBranchedObjectFileNames -File $branchFile -BranchPath $branch
            Get-GitPathRelativeToRepoRoot $branchFile
        } else {
            GetBranchedObjectFileNames -File $File -BranchPath $branch
        }
    }
}

Export-ModuleMember *-*

