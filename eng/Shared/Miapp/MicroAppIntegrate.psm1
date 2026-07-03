Import-Module "$PSScriptRoot/MicroAppConf.psm1"
Import-Module "$PSScriptRoot/MicroAppGitHelper.psm1"

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Get-CanonicalParentPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        $Path,

        [Alias("a")]
        [switch] $RelativeToRepoRoot
    )

    $parentPath = Split-Path -Path $Path -Parent

    if($parentPath) {
        $parentPath = (ConvertTo-GitDirectorySeparator $parentPath)
        if($RelativeToRepoRoot) {
            $parentPath = Get-GitPathRelativeToRepoRoot $parentPath
        }
        if($parentPath) {
            "$parentPath/"
        }
    }
}

function Get-IntegrationBranchName([Parameter(Mandatory=$true)][string]$Path) {
    $parent = Get-CanonicalParentPath $Path -RelativeToRepoRoot
    if($parent) {
        Get-RootIntegrationBranchName $parent
    }
}

function Get-IntegrationFileName([Parameter(Mandatory=$true)][string]$Path) {
    $branch = Get-IntegrationBranchName $Path
    if($branch) {
        $resAbsPath = Resolve-GitPath $Path
        $branchAbsPath = ConvertTo-GitDirectorySeparator (Join-Path (Get-GitRoot) $branch)

        if($resAbsPath.StartsWith($branchAbsPath)) {
            $resAbsPath.Substring($branchAbsPath.Length)
        } else {
            throw "Get-IntegrationFileName error: $resAbsPath not a child of $branchAbsPath"
        }
    }
}

function Get-IntegrationBaseBranchName([Parameter(Mandatory=$true)][string] $Path)
{
    $branch = Get-IntegrationBranchName $Path
    if($branch) {
        $ancestors = $MiappConfig.IntegrationDepsAncestors
        while ($ancestor = $ancestors[$branch]) {
            $branch = $ancestor
        }
        $branch
    }
}

function Get-IntegrationBaseFilePath([Parameter(Mandatory=$true)][string] $Path)
{
    $baseBranch = Get-IntegrationBaseBranchName $Path
    if($baseBranch) {
        $fileName = Get-IntegrationFileName $Path
        $baseBranch+$fileName
    }
}

function Test-FileHasToBeIntegrated {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    try {
        [HashTable] $integrationDeps = $MiappConfig.IntegrationDepsPriority
        [string] $fileName = Get-IntegrationFileName (Convert-FromStringToPath $Path)
        if($fileName) {
            -not ($MiappConfig.ExclusionPatterns | ? { $fileName -ilike $_ }) `
            -and $Path -like '*.*'
        }
    } catch {
        Write-Verbose "Test-FileHasToBeIntegrated Exception: $($_.Exception.Message)"
    }
}

function Get-FileIntegrationPriority {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    [HashTable] $integrationDepsPriority = $MiappConfig.IntegrationDepsPriority
    [string] $parentPath = Get-IntegrationBranchName $Path
    if($parentPath) {
        return $integrationDepsPriority[$parentPath]
    }
    $MiappConfig.MaxPriority
}

function Invoke-IntegrateFile {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [ValidateNotNullOrEmpty()]
        [char] $Status = (Get-GitFileStatus $File "origin/$env:RepoBranchName"),

        [ValidateNotNull()]
        [HashTable] $Params = @{}
    )

    if(-not (Test-FileHasToBeIntegrated $File)) {
        return
    }

    [string] $fileName = Get-IntegrationFileName $File
    [string] $branchPath = Get-IntegrationBranchName $File

    if(($Status -ne $GitFileStatus.Deleted) -and -not (Test-GitFileDifferentFromRemote $File "origin/$env:RepoBranchName")) {
        Write-Verbose "Skipping $File`nThe file status is '$Status' but there is no difference from the version on origin/$($env:RepoBranchName)"
        return
    }

    Write-Host "Processing $File"

    IntegrateBranchedObjects -File $File -Status $Status -BranchPath $branchPath -Params $Params

    $true
}

function IntegrateBranchedObjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [ValidateNotNullOrEmpty()]
        [char] $Status = (Get-GitFileStatus $File "origin/$env:RepoBranchName"),

        [ValidateNotNullOrEmpty()]
        [string] $BranchPath = (Get-IntegrationBranchName $File),

        [string] $BaseFile = (Get-BaseFile $File $Status),

        [ValidateNotNull()]
        [HashTable] $Params = @{}
    )


    [string] $fileName = Get-IntegrationFileName $File
    [HashTable] $integrationDeps = $MiappConfig.IntegrationDeps

    foreach  ($branch in $integrationDeps[$BranchPath]) {
        [string] $destFile = $integrationDeps[$File]
        if (-not $destFile) { $destFile = $branch+$fileName }
        $destFile = Join-Path (Get-GitRoot) $destFile
        if (Test-Path $destFile) {
            if($Params.Country)
            {
                # Match country code from paths like src/Layers/CZ/, src/Layers/MX/, etc.
                $Matched = $branch -match 'src/Layers/(?<Country>.+?(?=/)'
                if($Matched)
                {
                    $Matched = $Matches.Country -eq $Params.Country
                }
                if(!$Matched)
                {
                    continue
                }
            }
            #Merge file and go to the next level
            $destFile = Get-GitCanonicalPath $destFile
            IntegrateChangeInFile $destFile $File $BaseFile $Status -Params $Params
            ExcludeOrStageFile $destFile
            IntegrateBranchedObjects -File $destFile -BranchPath $branch -Params $Params
        } else {
            #File not found go to the next level
            Write-Verbose "$destFile not found... moving to next level"
            IntegrateBranchedObjects -File $File -Status $Status -BranchPath $branch -BaseFile $BaseFile -Params $Params
        }
    }

}

function IntegrateChangeInFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OtherFile,

        [string] $BaseFile,

        [char] $Status,

        [ValidateNotNull()]
        [HashTable] $Params = @{}
    )

    [string[]] $ignoreList = $Params['Ignorelist']
    [bool] $interactive = $Params['Interactive']
    if(-not (CheckChangeHasToBeIntegratedInFile $DestFile $OtherFile $ignoreList -Interactive:$interactive)) {
        return
    }

    Write-Host -ForegroundColor Green "Propagating change: $OtherFile --> $DestFile"

    if($Status -eq $GitFileStatus.Deleted) {
        RemoveFile $DestFile $Params
    } else {
        MergeAndResolveConflicts $DestFile $BaseFile $OtherFile $Params
    }
}

function CheckChangeHasToBeIntegratedInFile {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OtherFile,

        [string[]] $IgnoreList,

        [switch] $Interactive
    )

    if($IgnoreList | ? {$DestFile -ilike $_}) {
        Write-Host -ForegroundColor Yellow "Ignoring: $DestFile"
        return $false
    }

    if($Interactive) {
        $skip = PromptForSkipPropagationChoice $DestFile $OtherFile

        if ($skip) {
            $skip = PromptSureToSkipPropagationChoice $DestFile $OtherFile
        }

        if($skip) {
            Write-Host -ForegroundColor Yellow "Skipping: $DestFile"
            return $false
        }
    }
    $true
}

function PromptForSkipPropagationChoice {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OtherFile
    )

        $title = "Next change: $OtherFile --> $DestFile"
        $message = ''
        $continue = New-Object System.Management.Automation.Host.ChoiceDescription "&Continue", `
            "Try to propagate the changes from $OtherFile to $DestFile"
        $skip = New-Object System.Management.Automation.Host.ChoiceDescription "&Skip", `
            "The changes in $OtherFile are not propagated to $DestFile and all the dependent branches"
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($continue, $skip)

        $host.ui.PromptForChoice($title, $message, $options, 0)
}

function PromptSureToSkipPropagationChoice {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OtherFile
    )

        $title = 'Are you sure you want to skip?'
        $message = "By doing so the changes in $OtherFile will not be propagated to $DestFile"`
            +' and all the dependent branches.'
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
            "The changes in $OtherFile are not propagated to $DestFile and all the dependent branches"
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
            "Try to propagate the changes from $OtherFile to $DestFile"
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($no, $yes)

        $host.ui.PromptForChoice($title, $message, $options, 0)
}

function ExcludeOrStageFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile
    )

    $file = Resolve-GitPath -Relative -RemoteStyle $DestFile

    if ((Test-Path $DestFile) -and -not (Test-GitFileDifferentFromRemote $file "origin/$env:RepoBranchName")) {
        Write-Host "$file does not differ from remote version, adding to ignore list"
        AddFileToExclusionList (Get-GitCanonicalPath $file -Absolute)
    } else {
        Write-Verbose "Done!"
    }
}

function MergeAndResolveConflicts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile,

        [string] $BaseFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OtherFile,

        [ValidateNotNull()]
        [HashTable] $Params = @{}
    )

    $Options = @()
    if(-not $BaseFile) {
        '' | Out-File -Encoding default ($BaseFile = Get-TempFileName)
    } else {
        $Options += '--diff3'
    }

    $outFile = Get-TempFileName
    $preResolutionFile = $outFile + '.back'
    $skipResolve = $Params['SkipResolve']
    $autoResolve = $Params['AutoResolve']
    $ReuseRecordedResolution = $Params['ReuseRecordedResolution']
    [int] $conflictsCount = 0

    do {
        cp -Force $DestFile $outFile
        $conflictsCount = Invoke-GitMergeFile $outFile $DestFile $BaseFile $OtherFile $Options

        if($conflictsCount -eq 0) { continue }

        cp -Force $outFile $preResolutionFile
        if($ReuseRecordedResolution) {
            if(ApplyReReReFile $DestFile $outFile) { continue }
        }

        if($skipResolve) {
            Write-Host -ForegroundColor Yellow "Skipping conflict resolution... Remember to solve the conflict before committing"
            continue
        }

        if($autoResolve) {
            Write-Host -ForegroundColor Yellow "Resolving automatically using $autoResolve"
            $Options += "--$autoResolve"
            continue
        }

        Write-Host -ForegroundColor Yellow "Resolve remaining conflicts before continuing"

        $result = PromptForResolveConflictChoice $DestFile $OtherFile

        switch ($result)
        {
            0 { InvokeMergeTool $outFile $DestFile $BaseFile $OtherFile $Params } #manual
            #Note: during localization yours and theirs are inverted!
            1 { $Options += '--theirs' } #ours
            2 { $Options += '--ours'   } #theirs
            3 { $Options += '--union'  } #union
            4 { $skipResolve = $true   } #skip
        }

    } while (-not $skipResolve -and (Test-GitFileIsUnresolved $outFile))

    if($skipResolve -and $conflictsCount) {
        if($Params['LogFile']) {
            "$DestFile contains conflicts" >> $Params.LogFile
        }
    } elseif (Test-Path $preResolutionFile -PathType Leaf) {
        CreateRerereFile $preResolutionFile $outFile $DestFile
    }

    cp -Force $outFile $DestFile
}

function PromptForResolveConflictChoice {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OtherFile
    )

    $title = "Resolve Conflict"
    $message = "Choose one of the available merge options to solve the conflict between:"`
        + "`n From: $OtherFile `n To: $DestFile"
    $manual = New-Object System.Management.Automation.Host.ChoiceDescription "&Manual", `
        "Merge the file manually"
    $ours = New-Object System.Management.Automation.Host.ChoiceDescription "&Ours", `
        "Resolve conflict by choosing our changes"
    $theirs = New-Object System.Management.Automation.Host.ChoiceDescription "&Theirs", `
        "Resolve conflict by choosing their changes"
    $union = New-Object System.Management.Automation.Host.ChoiceDescription "&Union", `
        "Resolve conflict by choosing both our and their changes"
    $skip = New-Object System.Management.Automation.Host.ChoiceDescription "&Skip", `
        "Leave the file in a conflicted state"
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]($manual, $ours, $theirs, $union, $skip)

    $host.ui.PromptForChoice($title, $message, $choices, 0)

}

function InvokeMergeTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $TempDestFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $BaseFile,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OtherFile,

        [ValidateNotNull()]
        [HashTable] $Params = @{}
    )

    $invoked = $false
    $noMergeTool = $Params['NoMergeTool']
    $useExpandedUnifiedView = $Params['UseExpandedUnifiedView']

    if(-not $noMergeTool) {

        if($useExpandedUnifiedView) {
            $files = UnifiedViewToThreeWay $TempDestFile $DestFile
            $DestFile = $files.current
            $BaseFile = $files.base
            $OtherFile = $files.other
        }
        $base = ($BaseFile,"")[-not (Get-Content $BaseFile)]
        $invoked = Invoke-GitMergeTool -Merged $TempDestFile -Local $DestFile -Base $base -Remote $OtherFile
    }

    if(-not $invoked) {
        Write-Verbose "Start-Process $($MiappConfig.DefaultEditor) $TempDestFile -NoNewWindow -Wait"
        Start-Process $MiappConfig.DefaultEditor $TempDestFile -NoNewWindow -Wait
    }
}

function RemoveFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestFile,

        [ValidateNotNull()]
        [HashTable] $Params = @{}
    )

    Write-Host -ForegroundColor Yellow "Deleting $DestFile"
    Remove-Item $DestFile
}

function Get-BaseFile {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [Parameter()]
        [char] $Status = (Get-GitFileStatus $File "origin/$env:RepoBranchName")
    )

    if($Status -eq $GitFileStatus.Deleted) { return }

    [string] $baseFile = Get-GitRemoteFile $File "origin/$env:RepoBranchName" $Status

    if($baseFile) {
        Write-Verbose "Remote base file found for $File"
    } else {
        $branch = Get-IntegrationBranchName $File
        $fileName = Get-IntegrationFileName $File
        while ($branch -and ($nextBranch = $MiappConfig.IntegrationDepsAncestors[$branch])) {
            $ancestorFile = $nextBranch+$fileName
            $ancestorFile = Join-Path (Get-GitRoot) $ancestorFile
            if(Test-Path $ancestorFile) {
                Write-Verbose "Ancestor file found in $nextBranch for $File"
                cp -Force $ancestorFile ($baseFile = Get-TempFileName)
                break
            }
            $branch = $nextBranch
        }
    }

    if(-not $baseFile) {
        Write-Verbose "No base file found for $File"
    }
    $baseFile
}

function GetExclusionFilePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    "$($MiappConfig.DepotRoot)/$($MiappConfig.ExclusionDir)$(Get-GitLastCommitSHA1)$($MiappConfig.ExclusionExt)"
}

function Clear-ExclusionList {
    [CmdletBinding()]
    param()

    [string] $exclusionFile = GetExclusionFilePath

    if(Test-Path $exclusionFile) {
        Remove-GitFileFromStage $exclusionFile
        Remove-Item $exclusionFile
    }
}

function AddFileToExclusionList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $FilePath
    )

    if(-not (Test-Path $MiappConfig.ExclusionDir)) {
        [void] (mkdir $MiappConfig.ExclusionDir)
    }

    $ExclusionFile = (GetExclusionFilePath)
    [array](Get-ExclusionList) + ,$FilePath | ConvertTo-Json `
        | Out-File -FilePath $ExclusionFile -Encoding default

    Add-GitFileToStage $ExclusionFile
}

function Get-ExclusionList {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [ValidateNotNullOrEmpty()]
        [string] $File = (GetExclusionFilePath)
    )

    if(Test-Path $File) {
        [string[]] (Get-Content $File -Raw | ConvertFrom-Json)
    }
}

function Clear-FileHashNotes {
    [CmdletBinding()]
    param()

    [string[]] $notes = ([string[]] (Get-GitNotes | ? { $_ })) -inotlike "$($MiappConfig.NoteLineId)*"

    Clear-GitNotes
    $notes | Add-GitNotes
}

function Add-FileToHashNotes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $FilePath
    )

    $file = Get-GitCanonicalPath $FilePath -Absolute

    Add-GitNotes ($MiappConfig.NoteLineId +`
        (@{ type = 'filehash'; file = $file; hash = Get-FileHash $FilePath} | ConvertTo-Json -Compress))
}

function Get-FileHashNotes {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    [string] $lineId = $MiappConfig.NoteLineId

    ([string[]] (Get-GitNotes | ? { $_ }))`
        -ilike "$lineId*"`
        | % { $_.SubString($lineId.Length) | ConvertFrom-Json }`
        | ? { $_.type -eq 'filehash' }
}

function GetMiappTempDir {
    $dir = Get-MiappDir
    if(!(Test-Path $dir -PathType Container)) {
        [void] (New-Item -Path $dir -ItemType Directory -Force)
    }
    $dir
}

function GetReReReDir {
    Join-Path $MiappConfig.MiappRerereDir $(Get-GitCurrentBranch)
}

function CreateRereReFile($ConflictedFile, $ResolvedFile, $OriginalFile) {
    $dir = GetReReReDir
    if (!(Test-Path $dir -PathType Container)) {
        [void] (New-Item -Path $dir -ItemType Directory -Force)
    }
    $prevLocation = Get-Location
    Set-Location $(GetMiappTempDir)

    try {
        $patchFile = (Join-Path $dir $OriginalFile) + '.patch'
        $patchDir = Split-Path -Path $patchFile -Parent
        if ($patchDir -and -not (Test-Path $patchDir -PathType Container)) {
            [void] (New-Item -Path $patchDir -ItemType Directory -Force)
        }
        [void] (New-Item -Path $patchFile -ItemType File -Force)

        GeneratePatch $ConflictedFile $ResolvedFile $patchFile
    } finally {
        Set-Location $prevLocation
    }
}

function FileContainsConflictsMarkers($File) {
    foreach ($line in Get-Content $File) {
        if( $line -match '<<<<' -or`
            $line -match '>>>>' -or`
            $line -match '\|\|\|\|' -or`
            $line -match '====') {

            return $true
        }
    }

    $false
}

function ApplyReReReFile($OriginalFile, $DestFile) {
    $dir = GetReReReDir
    $prevLocation = Get-Location
    $hasConflicts = $true
    Set-Location $(GetMiappTempDir)

    try {
        $tempDestFile = (Join-Path $dir $OriginalFile) + '.after'
        $patchFile = (Join-Path $dir $OriginalFile) + '.patch'

        if(Test-Path $patchFile -PathType Leaf) {
            $tempDestDir = Split-Path -Path $tempDestFile -Parent
            if ($tempDestDir -and -not (Test-Path -Path $tempDestDir -PathType Container)) {
                [void] (New-Item -Path $tempDestDir -ItemType Directory -Force)
            }
            [void] (New-Item -Path $tempDestFile -ItemType File -Force)
            cp -Force $DestFile $tempDestFile

            $appliedCount = ApplyPatch $patchFile $tempDestFile
            cp -Force $tempDestFile $DestFile
            if($appliedCount) {
                Write-Host "Recorded resolution applied."
            } else {
                Write-Host "Recorded resolution does not apply." -ForegroundColor Yellow
            }

            $hasConflicts = FileContainsConflictsMarkers $DestFile
        }
    } finally {
        Set-Location $prevLocation
        !$hasConflicts
    }
}

# Generates a patch from File1 to File2
function GeneratePatch($File1, $File2, $PatchFile) {
    ((git diff --no-index --histogram $File1 $File2) -join "`n") + "`n" | out-file $PatchFile -Encoding utf8 -NoNewline
}

function GetPatchDiffs($File) {
    [string[]] $diff = @()
    [bool] $copy = $false
    [string[]] $lines = get-content $File

    [string] $openMarker = '<<<<'
    [string] $closeMarker = '>>>>'
    [int] $inScopeCounter = 0

    if($lines -and $lines.Count -and ($lines[0] -notmatch 'diff --git .+')) {
        Write-Verbose "Invalid diff file: $File"
        return
    }

    foreach ($line in $lines) {
        if($line -match '^@@ ' -and $inScopeCounter -eq 0) {
            if($diff.Count) { $diff -join "`n" }
            $diff = @()
            $copy = $true
        }
        if($copy) {
            $diff += $line
            if($line -match $openMarker) { $inScopeCounter++ }
            if($line -match $closeMarker) { $inScopeCounter-- }
        }
    }
    if($inScopeCounter -ne 0) {
        Write-Verbose "One or more resolution markers missing in $File"
        return
    }
    if($diff -and $diff.Count) {
        #remove last new line
        ([string[]]($diff[0..($diff.Count-1)] -join "`n"))
    }
}

function ApplyPatch($patchFile,$destFile) {
    $escapedDestPath = $destFile -replace '\\', '\\'
    $header = "diff --git `"a/$escapedDestPath`" `"b/$escapedDestPath`"`n--- `"a/$escapedDestPath`"`n+++ `"b/$escapedDestPath`""
    $tempPatchFile = Get-TempFileName
    $diffs = GetPatchDiffs $patchFile

    [int] $totalDiffs = 0
    [int] $successCount = 0

    $diffs | % {
        $totalDiffs++
        $header + "`n" + $_ + "`n" | out-file -Encoding utf8 $tempPatchFile -Force -NoNewline
        try {
            git apply --ignore-space-change $tempPatchFile 2>&1
            $successCount++
        }
        catch {
        }
    }

    Write-Verbose "$successCount out of $totalDiffs applied"

    $successCount
}

function ExpandUnifiedView($file, [ValidateSet('current','base','other')] $selection) {
    switch ($selection)
    {
        'current' { $start = '^<<<<';     $end = '^(\|\|\|\||====)' }
        'base'    { $start = '^\|\|\|\|'; $end = '^====' }
        'other'   { $start = '^====';     $end = '^>>>>' }
    }
    $hunkStart = '^<<<<'
    $hunkEnd = '^>>>>'


    [int] $scopeCounter = 0
    [int] $insideDiff = 0
    foreach ($line in (get-content $file)) {
        if($line -match $hunkStart) { $scopeCounter++ }
        if($scopeCounter -eq 0) { $line }
        if($scopeCounter -eq 1) {
            if($line -match $end) { $insideDiff = $false }
            if($insideDiff) { $line }
            if($line -match $start) { $insideDiff = $true }
        }
        if($line -match $hunkEnd) { $scopeCounter-- }
    }

    if($scopeCounter -ne 0) {
        Write-Error "$file is not a valid unified view or the markers are not the expected ones."
    }
}

function UnifiedViewToThreeWay($file,$original) {
    $tempFile = Join-Path $env:TEMP $original
    $currFile = $tempFile + '.current'
    [void] (New-Item -Path $currFile -ItemType File -Force)
    $baseFile = $tempFile + '.base'
    [void] (New-Item -Path $baseFile -ItemType File -Force)
    $otherFile = $tempFile + '.other'
    [void] (New-Item -Path $otherFile -ItemType File -Force)

    [System.IO.File]::WriteAllLines($currFile , $(ExpandUnifiedView $file -selection current ), [System.Text.UTF8Encoding]($False))
    [System.IO.File]::WriteAllLines($baseFile , $(ExpandUnifiedView $file -selection base    ), [System.Text.UTF8Encoding]($False))
    [System.IO.File]::WriteAllLines($otherFile, $(ExpandUnifiedView $file -selection other   ), [System.Text.UTF8Encoding]($False))

    @{ current = $currFile; base = $baseFile; other = $otherFile }
}

Export-ModuleMember *-*

