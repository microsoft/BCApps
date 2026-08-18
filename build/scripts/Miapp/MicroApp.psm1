Import-Module "$PSScriptRoot\MicroAppConf.psm1"
Import-Module "$PSScriptRoot\MicroAppGitHelper.psm1"
Import-Module "$PSScriptRoot\MicroAppIntegrate.psm1"

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Invoke-Miapp
{
    <#
    .SYNOPSIS
    Propagates changes from the base branch to dependent branches by integrating modified files.

    .DESCRIPTION
    Invoke-Miapp (MicroApp integration) drives the end-to-end propagation process:
      1. Optionally verifies the local repository is not behind the remote.
      2. Optionally checks that affected files are not unresolved or unstaged.
      3. Discovers files that need to be integrated across branches.
      4. Integrates each file using the configured merge/resolve strategy.
      5. Reports any remaining unresolved conflicts.

    .PARAMETER SkipSync
    Skips the check that ensures the local repository is not behind the remote.

    .PARAMETER SkipStage
    Skips automatic staging of unstaged files. If unstaged integration files are
    found and this switch is set, the command will throw instead of staging them.

    .PARAMETER SkipFileStatus
    Skips the entire unresolved/unstaged file status check before integration.

    .PARAMETER NoMergeTool
    Disables launching an external merge tool during conflict resolution.

    .PARAMETER Interactive
    Enables interactive mode, prompting for decisions during integration.

    .PARAMETER AutoResolve
    Automatically resolves merge conflicts using the specified strategy.
    Accepted values:
      ours    - keep the current branch version
      theirs  - keep the incoming branch version
      union   - combine both sides (line-level union merge)
      at      - alias for 'theirs'
      ay      - alias for 'ours'
      af      - reserved (currently throws)

    .PARAMETER SkipResolve
    Skips the conflict resolution step entirely, leaving conflicts unresolved.

    .PARAMETER FileNameFilter
    A regular-expression pattern used to filter which changed files are integrated.
    Defaults to '.*' (all files).

    .PARAMETER Country
    Limits integration to files associated with the specified country/localization.

    .PARAMETER IgnoreList
    An array of file path patterns to exclude from integration.

    .PARAMETER ReuseRecordedResolution
    Enables git rerere (reuse recorded resolution) to automatically apply
    previously recorded conflict resolutions. Implies UseExpandedUnifiedView.

    .PARAMETER UseExpandedUnifiedView
    Uses the expanded unified diff view when presenting merge conflicts.

    .EXAMPLE
    Invoke-Miapp

    Runs a full propagation: syncs, checks file status, integrates all changed files.

    .EXAMPLE
    Invoke-Miapp -SkipSync -AutoResolve theirs

    Skips the remote sync check and automatically resolves all conflicts by
    accepting the incoming (theirs) version.

    .EXAMPLE
    Invoke-Miapp -FileNameFilter 'Sales' -Interactive

    Integrates only files whose names match 'Sales', prompting interactively
    for each conflict.

    .EXAMPLE
    Invoke-Miapp -ReuseRecordedResolution -SkipSync

    Reuses previously recorded conflict resolutions and skips the remote sync check.
    #>
    [CmdletBinding(DefaultParameterSetName='0')]
    param(
        [Alias("nosy")]
        [switch] $SkipSync,
        [Alias("nost")]
        [Parameter(ParameterSetName = '2')]
        [switch] $SkipStage,
        [Alias("nofs")]
        [Parameter(ParameterSetName = '3')]
        [switch] $SkipFileStatus,
        [Alias("nomt")]
        [switch] $NoMergeTool,
        [Alias("i")]
        [switch] $Interactive,
        [Alias("a")]
        [Parameter(ParameterSetName = '0')]
        [ValidateSet('ours','theirs','union','at','ay','af')]
        [string] $AutoResolve,
        [Alias("am")]
        [Parameter(ParameterSetName = '1')]
        [switch] $SkipResolve,
        [Alias("il","ilist")]
        [string] $FileNameFilter = '.*',
        [string] $Country,
        [string[]] $IgnoreList = @(),
        [Alias("rerere")]
        [switch] $ReuseRecordedResolution,
        [Alias("ueuv")]
        [switch] $UseExpandedUnifiedView
    )

    $prevLocation = Get-Location
    Set-Location $MiappConfig.DepotRoot

    try {

    if(-not (Get-MiappBaseBranch)) {
        Throw "Cannot determine the base branch from 'origin/HEAD'. Ensure the repository has an 'origin' remote with a resolvable default branch (for example: git remote set-head origin --auto)."
    }

    $params = @{
        Interactive = $Interactive;
        AutoResolve = (ConvertSDMergeOptionToGit $AutoResolve);
        SkipResolve = $SkipResolve;
        NoMergeTool = $NoMergeTool;
        IgnoreList  = $IgnoreList | % { ConvertTo-GitDirectorySeparator $_ };
        LogFile = Get-TempFileName;
        ReuseRecordedResolution = $ReuseRecordedResolution;
        UseExpandedUnifiedView = ($UseExpandedUnifiedView -or $ReuseRecordedResolution)
        Country = $Country
        }

    Write-Host "Starting propagation process..."

    if(-not $SkipSync) {
        Assert-RepositoryIsNotBehindTheRemote
    }
    if(-not $SkipFileStatus) {
        Assert-FilesAreNotUnresolvedOrUnstaged -SkipStage:$SkipStage
    }

    $changes = Get-IntegrationFiles | Where-Object {$_ -match $FileNameFilter}

    # Integrate changes
    $verbose = [bool] $PSBoundParameters['Verbose']
    $debug = [bool] $PSBoundParameters['Debug']

    Clear-ExclusionList
    $integratedFiles = @{}

    $changes | % {
        $baseFilePath = Get-IntegrationBaseFilePath $_
        if(-not $integratedFiles.Contains($baseFilePath)) {
            if((Invoke-IntegrateFile $_ -Params $params -Verbose:$verbose -Debug:$debug)) {
                $integratedFiles.Add($baseFilePath,$null)
            }
        }
    }

    ReadConflictsFile $params.LogFile

    Write-Host "Propagation process done."

    }
    finally {
        Set-Location $prevLocation
    }
}

function Get-IntegrationFiles {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    Write-Host "Checking if there are changes that need to be propagated to the dependent branches..."

    [string[]] $exclusionPatterns = $MiappConfig.ExclusionPatterns
    Get-GitChangedFiles -All `
        | ? { $fs = $_; $exclusionPatterns | ? { $fs -inotlike $_ } } `
        | ? { Test-FileHasToBeIntegrated $_ } `
        | Sort-Object { Get-FileIntegrationPriority $_ }
}

function Assert-RepositoryIsNotBehindTheRemote {
    [CmdletBinding()]
    param()

    Write-Host "Making sure your repository is not behind..."

    if(Test-PendingChangeFromBranch) {
        Throw "Your branch is behind, pull before continuing."
    }

    if(Test-PendingChangeFromBranch "origin/$(Get-MiappBaseBranch)") {
        Throw "Your branch is behind origin/$(Get-MiappBaseBranch), merge or rebase before continuing."
    }

    if(-not (Test-GitBranchHasAtLeastOneCommit "origin/$(Get-MiappBaseBranch)")) {
        Throw "You need to commit at least once before continuing."
    }
}

function Assert-FilesAreNotUnresolvedOrUnstaged {
    [CmdletBinding()]
    param(
        [Alias("stno")]
        [switch] $SkipStage
    )

    Write-Host "Checking if any of the affected files is unresolved or unstaged..."

    [HashTable] $integrationDeps = $MiappConfig.IntegrationDeps
    $unstagedFiles = Get-GitChangedFiles -Untracked -Unstaged | ? { Test-FileHasToBeIntegrated $_ }
    $stagedFiles = Get-GitChangedFiles -Staged | ? { Test-FileHasToBeIntegrated $_ }
    [string[]] $unresolvedFiles = @() + $stagedFiles + $unstagedFiles | ? { $_ } | ? { Test-Path (Convert-FromStringToPath $_) } | select -Unique | ? { Test-GitFileIsUnresolved (Convert-FromStringToPath $_) }

    if ($unresolvedFiles) {
        Write-Host -ForegroundColor Red "There are $($unresolvedFiles.Count) unresolved files:"
        Write-Host -ForegroundColor Red ($unresolvedFiles -join "`n")
        Throw "Resolve all the conflicts before continuing."
    }

    if($unstagedFiles) {
        if($SkipStage) {
            Write-Host -ForegroundColor Red "The following files are not staged:"
            Write-Host -ForegroundColor Red ($unstagedFiles -join "`n")
            Throw "Stage all the files before continuing"
        }
        $unstagedFiles | % {
            Write-Host "Staging $_"
            Add-GitFileToStage $_
        }
    }
}

function ConvertSDMergeOptionToGit {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string] $AutoResolve
    )

    $errorMessage = "'-AutoResolve $AutoResolve' option not supported";

    switch ($AutoResolve)
    {
        'am' { Throw "$errorMessage. Use '-SkipMerge or' '-am' instead" }
        'ay' { 'ours'              }
        'at' { 'theirs'            }
        'an' { Throw $errorMessage }
        'af' { Throw $errorMessage }
        default { $AutoResolve }
    }
}

function ReadConflictsFile {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    $conflicts = Get-Content $Path
    if($conflicts) {
        Write-Host -ForegroundColor Yellow "The following files are still in an unresolved state:`n"
        Write-Host -ForegroundColor Yellow ($conflicts -join "`n")
    }
}

Export-ModuleMember *-*

