Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

[char] $DirectorySeparatorChar = [IO.Path]::DirectorySeparatorChar
[char] $GitDirectorySeparatorChar = '/'
[bool] $GitDirectorySeparatorCharIsValid = ($GitDirectorySeparatorChar -notin ([IO.Path]::InvalidPathChars))

if(-not $GitDirectorySeparatorCharIsValid) {
    Throw "GitDirectorySeparatorChar is not a valid path character"
}

$GitFileStatus = [PSCustomObject] @{ Added    = 'A';
                                 Deleted  = 'D';
                                 Modified = 'M';
                                 Unmerged = 'U'}

# ---------------------------------------------------------------------------
# Path utility functions (originally sourced from SourceControl-Common.ps1)
# ---------------------------------------------------------------------------

function Get-TempFileName {
    [System.IO.Path]::GetTempFileName()
}

<#
.SYNOPSIS
Converts Path to an absolute path
#>
function ConvertTo-AbsolutePathSafe
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

<#
.SYNOPSIS
Returns Path relative to Root
#>
function ConvertTo-RelativePathSafe
(
    [string] $Path,
    [string] $Root
)
{
    $Root = ConvertTo-AbsolutePathSafe "$Root\"
    $EscapedRoot = [regex]::Escape($Root)

    $Path = ConvertTo-AbsolutePathSafe $Path

    $relativePath = $Path -replace "^$EscapedRoot",''

    return $relativePath
}

<#
.SYNOPSIS
Returns the portion of Path relative to Root with the correct casing
.DESCRIPTION
Example: Resolve-PathCasing -Root C:\repo -Path .\SRC\APPS\cod1.txt returns src\Apps\Cod1.txt
#>
function Resolve-PathCasing
(
    [string] $Path,
    [string] $Root
)
{
    $RelativePath = ConvertTo-RelativePathSafe -Path $Path -Root $Root
    $resPath = $Root

    $RelativePath -split '\\' | ? { $_ } | foreach {
        $child = Get-ChildItem $resPath -Filter $_
        if (-not $child) {
            throw "File not found: $Path"
        }
        if ($child.GetType() -eq [Object[]]) {
            throw "Path $Path contains a filter returning multiple results"
        }
        $resPath = Join-Path $resPath $child.Name
    }

    $RelativePath = ConvertTo-RelativePathSafe -Path $child.FullName -Root $Root
    return $RelativePath
}

# ---------------------------------------------------------------------------
# Git helper functions
# ---------------------------------------------------------------------------

function ConvertTo-GitDirectorySeparator {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $Path.Replace($DirectorySeparatorChar, $GitDirectorySeparatorChar)
}

function Resolve-PathSafe {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Alias("rlto")]
        [string]
        $RelativeTo,

        [Alias("rl")]
        [switch] $Relative
    )

    $resPath =  ConvertTo-AbsolutePathSafe $Path

    if($Relative -or $RelativeTo) {

        [char] $UriDirectorySeparatorChar = '/'
        if($RelativeTo) {
            $pathBase = ConvertTo-AbsolutePathSafe $RelativeTo
        }
        else {
            $pathBase = (Get-Location).Path
        }

        $resPath = ConvertTo-RelativePathSafe -Path $Path -Root $pathBase
    }

    $resPath
}

function Resolve-GitPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Alias("rlto")]
        [string]
        $RelativeTo,

        [Alias("rl")]
        [switch] $Relative,

        [Alias("rs")]
        [switch] $RemoteStyle
    )

    $resPath =  ConvertTo-GitDirectorySeparator (Resolve-PathSafe $Path -Relative:$Relative -RelativeTo $RelativeTo)
    [string] $resPath
}

function Test-GitFileIsInLocalRepo {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,
        [switch] $MustExist
    )

    $IsInLocalRepo = (Resolve-GitPath $Path) -ilike "$(Get-GitRoot)*"
    if($MustExist) {
        if(!$IsInLocalRepo) {
            throw "File $Path does not exist in local repo"
        }
    }
    else {
        return $IsInLocalRepo
    }
}

function Get-GitRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Resolve-GitPath (git rev-parse --show-toplevel)
}

function Get-GitPathRelativeToRepoRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    [string] $repoRoot = (Get-GitRoot).ToLower()
    [string] $absPath = Resolve-GitPath $Path

    if($absPath -inotlike "$repoRoot*") {
        throw "$Path is outside repository with root $repoRoot"
    }

    [int] $repoRootLength = $repoRoot.Length
    if($absPath.Length -gt $repoRoot.Length) {
        #Remove the directory separator char
        $repoRootLength += 1
    }
    $absPath.Substring($repoRootLength)
}

function Get-GitCanonicalPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Alias("a")]
        [switch] $Absolute
    )

    [string] $repoRoot = Get-GitRoot
    $Path = Resolve-PathCasing -Path $Path -Root $repoRoot
    $Path = Join-Path $repoRoot $Path

    [string] $absPath = Resolve-GitPath $Path
    if($absPath -inotlike "$repoRoot*") {
        throw "$Path is outside repository with root $repoRoot"
    }
    if($absPath.Length -eq $repoRoot.Length) {
        return
    }

    $resPath = $absPath
    if($Absolute) {
        return Get-GitPathRelativeToRepoRoot $resPath
    }

    Resolve-GitPath -Relative -RemoteStyle $resPath
}

function Get-GitRemoteFile {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $RemoteBranch,

        [Parameter()]
        [char] $Status = (Get-GitFileStatus $File $RemoteBranch),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $BaseFile = (Get-TempFileName)
    )

    if($Status -ne $GitFileStatus.Added) {
        #TODO: use utf8 w/o BOM
        Get-GitRemoteFileContent $File $RemoteBranch | Out-File -Encoding default $BaseFile
    }
    $BaseFile
}

function Invoke-GitMergeFile {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OutFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $BaseFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OtherFile,

        [Parameter()]
        [string[]] $Options
    )

    Write-Verbose "git merge-file $Options -L $DestFile -L 'Base: $OtherFile' -L $OtherFile $OutFile $BaseFile $OtherFile"
    git merge-file $Options -L $DestFile -L "Base: $OtherFile" -L $OtherFile $OutFile $BaseFile $OtherFile 2>&1>$null
    $LASTEXITCODE
}

function Test-GitFileIsUnresolved {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $File
    )
    # Note:
    # Equivalent to: git diff --check
    # that doesn't work outside of the repo dir
    $content = Get-Content $File -Raw
    $content -and $content.Contains((GetGitConflictMarker))
}

function GetGitConflictMarker {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    "<<<< "
}

function Get-GitRemoteFileContent {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $RemoteBranch
    )
    $File = Resolve-GitPath $File -Relative
    git show "$($RemoteBranch):$($File)"
}

function Test-GitFileDifferentFromRemote {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $RemoteBranch
    )

    if (Test-GitFileInRemoteBranch $File $RemoteBranch) {
        return [bool] (git diff --ignore-space-at-eol --unified=0 $RemoteBranch -- $File 2>&1)
    }
    return (Test-Path $File)
}

function Test-GitFileInRemoteBranch {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $RemoteBranch
    )

    #TODO change error action preference?
    try {
        $File = Resolve-GitPath $File -Relative
        Write-Verbose ('git cat-file -e "' + "$($RemoteBranch):$($File)" + '" 2>&1')
        git cat-file -e "$($RemoteBranch):$($File)" 2>$error
    }
    catch {
        $allowedErrors = @('fatal: Not a valid object name *', '*path * exists on disk, but not in *')
        $ex = $_.Exception
        if(-not ($allowedErrors | ? { $ex.Message -ilike $_})) {
            Throw $_
        }
    }
    $LASTEXITCODE -xor $true
}

function Test-GitBranchHasAtLeastOneCommit {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $RemoteBranch
    )

    [bool] (git log "$RemoteBranch..HEAD" --no-merges --oneline -1 --pretty=%H)
}

function Get-GitCurrentRemoteBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    [string] $output = (git rev-parse --symbolic-full-name '@{u}' 2>&1)

    if ($LASTEXITCODE -eq 0) {
        return $output
    }

    $allowedErrors = @('fatal: no upstream configured for branch *')
    if(-not ($allowedErrors | ? { $output -ilike $_})) {
        Throw $output
    }
}

function Get-GitCurrentBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    git rev-parse --abbrev-ref HEAD
}

function Initialize-MiappRepoBranchName {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($env:RepoBranchName) {
        return $env:RepoBranchName
    }

    [string] $originHeadRef = (git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>$null)
    if ($originHeadRef -imatch '^origin/(.+)$') {
        $env:RepoBranchName = $Matches[1]
    }

    if (-not $env:RepoBranchName) {
        [string] $originHeadBranch = (git remote show origin 2>$null | Select-String 'HEAD branch:' | Select-Object -First 1)
        if ($originHeadBranch -imatch 'HEAD branch:\s*(.+)$') {
            $env:RepoBranchName = $Matches[1].Trim()
        }
    }

    $env:RepoBranchName
}

function Get-GitLastCommitSHA1 {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    git rev-parse HEAD
}

function Test-PendingChangeFromBranch {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [ValidateNotNullOrEmpty()]
        [string] $Branch = (Get-GitCurrentRemoteBranch)
    )

    [bool] (git log "HEAD..$Branch" --oneline -1)
}

function Get-GitChangedFiles {
    [CmdletBinding(DefaultParameterSetName="2")]
    [OutputType([string[]])]
    param(
        [Parameter(ParameterSetName = "0")]
        [switch] $All,
        [Parameter(ParameterSetName = "1")]
        [switch] $UnCommitted = $All,
        [Parameter(ParameterSetName = "2")]
        [switch] $Untracked = $UnCommitted,
        [Parameter(ParameterSetName = "2")]
        [switch] $Unstaged = $UnCommitted,
        [Parameter(ParameterSetName = "2")]
        [switch] $Staged =$UnCommitted,
        [Parameter(ParameterSetName = "1")]
        [Parameter(ParameterSetName = "2")]
        [switch] $Committed = $All
    )

    {
        if ($Untracked) { GetGitUntrackedFiles }
        if ($Unstaged) { GetGitUnstagedFiles }
        if ($Staged) { GetGitStagedFiles }
        if ($Committed) { GetGitCommittedFiles }
    }.Invoke() | ? { $_ } | select -Unique
}

function GetGitUntrackedFiles {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    git status -s | ? { $_.StartsWith('?') } | % { $_.ToString() }
}

function GetGitCommittedFiles {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    # Returns files committed locally since origin/RepoBranchName
    if (-not (Initialize-MiappRepoBranchName)) { return }
    git diff --name-only "origin/$env:RepoBranchName...HEAD" | ? { $_ }
}


function GetGitUnstagedFiles {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    (git diff --name-only) | ? { $_ }
}

function GetGitStagedFiles {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $repoRoot = Get-GitRoot
    git diff --name-only --cached | % {
        Resolve-GitPath -Relative -RemoteStyle (Join-Path $repoRoot $_)
    }
}

function Get-GitFileStatus {
    [CmdletBinding()]
    [OutputType([char])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $RemoteBranch
    )
    [char] $status = $GitFileStatus.Deleted
    if(Test-Path $File) {
        Write-Verbose "Test-GitFileInRemoteBranch $File $RemoteBranch"
        $status = ($GitFileStatus.Added, $GitFileStatus.Modified)[(Test-GitFileInRemoteBranch $File $RemoteBranch )]
    }
    $status
}

function Add-GitFileToStage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    [void] (git add $Path)
}

function Remove-GitFileFromStage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    [void] (git reset $Path)
}

function Clear-GitNotes {
    [CmdletBinding()]
    param(
        [ValidateLength(40,40)]
        [AllowEmptyString()]
        [string] $CommitSHA1
    )

    try {
        git notes remove --ignore-missing $CommitSHA1
    }
    catch {
        $allowedErrors = @('Removing note for object *','Object * has no note')
        $ex = $_.Exception
        if(-not ($allowedErrors | ? { $ex.Message -ilike $_})) {
            Throw $_
        }
    }
}

function Add-GitNotes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Notes,

        [ValidateLength(40,40)]
        [AllowEmptyString()]
        [string] $CommitSHA1
    )

    process {
        $Notes | % { git notes append -m $_.Replace('"','\"') $CommitSHA1 }
    }
}

function Get-GitNotes {
    [CmdletBinding()]
    param(
        [ValidateLength(40,40)]
        [AllowEmptyString()]
        [string] $CommitSHA1
    )

    try {
        [string[]] (git notes show $CommitSHA1)
    }
    catch {
        $allowedErrors = @('error: no note found for object *')
        $ex = $_.Exception
        if(-not ($allowedErrors | ? { $ex.Message -ilike $_})) {
            Throw $_
        }
    }
}

function Get-GitMergeToolConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    [string] $mergeToolName = (git config merge.tool 2>$null)
    [string] $mergeToolCmd  = (git config mergetool.$mergeToolName.cmd 2>$null)
    [string] $mergeToolPath = $mergeToolCmd
    [string] $mergeToolArgs = ''

    if($mergeToolCmd -imatch '\s*(".*?"|.*?)\s+(.+)') {
        $mergeToolPath = $Matches[1]
        $mergeToolArgs = $Matches[2].TrimEnd()
    }

    [PSCustomObject] @{
        Tool = $mergeToolName
        Cmd  = $mergeToolCmd
        Path = $mergeToolPath
        Args = $mergeToolArgs
    }
}

function Invoke-GitMergeTool {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Merged,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Local,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string] $Base,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Remote
    )

    $mergeToolConf = Get-GitMergeToolConfig

    if($mergeToolConf.Path -and $mergeToolConf.Args) {

        $toolPath = $mergeToolConf.Path

        $parameters = $mergeToolConf.Args `
            -replace '\$LOCAL', $Local `
            -replace '\$REMOTE', $Remote `
            -replace '\$BASE', $Base `
            -replace '\$MERGED', $Merged

        Write-Verbose "Start-Process $toolPath $parameters -NoNewWindow -Wait"
        Start-Process $toolPath $parameters -NoNewWindow -Wait
        return $true
    }

    $false
}

function Convert-FromStringToPath([string]$Path)
{
    return $Path.Trim('"')
}


Export-ModuleMember Add-GitFileToStage
Export-ModuleMember Add-GitNotes
Export-ModuleMember Clear-GitNotes
Export-ModuleMember Convert-FromStringToPath
Export-ModuleMember ConvertTo-GitDirectorySeparator
Export-ModuleMember Get-GitCanonicalPath
Export-ModuleMember Get-GitChangedFiles
Export-ModuleMember Get-GitCurrentBranch
Export-ModuleMember Get-GitCurrentRemoteBranch
Export-ModuleMember Initialize-MiappRepoBranchName
Export-ModuleMember Get-GitFileStatus
Export-ModuleMember Get-GitLastCommitSHA1
Export-ModuleMember Get-GitMergeToolConfig
Export-ModuleMember Get-GitNotes
Export-ModuleMember Get-GitPathRelativeToRepoRoot
Export-ModuleMember Get-GitRemoteFile
Export-ModuleMember Get-GitRemoteFileContent
Export-ModuleMember Get-GitRoot
Export-ModuleMember Get-TempFileName
Export-ModuleMember Invoke-GitMergeFile
Export-ModuleMember Invoke-GitMergeTool
Export-ModuleMember Remove-GitFileFromStage
Export-ModuleMember Resolve-GitPath
Export-ModuleMember Resolve-PathSafe
Export-ModuleMember Test-GitBranchHasAtLeastOneCommit
Export-ModuleMember Test-GitFileDifferentFromRemote
Export-ModuleMember Test-GitFileInRemoteBranch
Export-ModuleMember Test-GitFileIsInLocalRepo
Export-ModuleMember Test-GitFileIsUnresolved
Export-ModuleMember Test-PendingChangeFromBranch
Export-ModuleMember -Variable GitFileStatus
