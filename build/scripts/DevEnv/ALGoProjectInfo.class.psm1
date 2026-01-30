using module .\AppProjectInfo.class.psm1

<#
.SYNOPSIS
    This class is used to store information about an AL-Go project.
#>
class ALGoProjectInfo {
    [string] $ProjectFolder
    [PSCustomObject] $Settings


    hidden ALGoProjectInfo([string] $projectFolder) {
        $alGoFolder = Join-Path $projectFolder '.AL-Go'

        if (-not (Test-Path -Path $alGoFolder -PathType Container)) {
            throw "Could not find .AL-Go folder in $projectFolder"
        }

        $settingsJsonFile = Join-Path $alGoFolder 'settings.json'

        if (-not (Test-Path -Path $settingsJsonFile -PathType Leaf)) {
            throw "Could not find settings.json in $alGoFolder"
        }

        $this.ProjectFolder = $projectFolder
        $this.Settings = Get-Content -Path $settingsJsonFile -Raw | ConvertFrom-Json
    }

    <#
        Gets the AL-Go project info from the specified folder.
    #>
    static [ALGoProjectInfo] Get([string] $projectFolder) {
        $alGoProjectInfo = [ALGoProjectInfo]::new($projectFolder)

        return $alGoProjectInfo
    }

    <#
        Finds all AL-Go projects in the specified folder.
    #>
    static [ALGoProjectInfo[]] FindAll([string] $folder) {
        $alGoProjects = @()

        $alGoProjectFolders = Get-ChildItem -Path $folder -Filter '.AL-Go' -Recurse -Directory | Select-Object -ExpandProperty Parent | Select-Object -ExpandProperty FullName

        foreach($alGoProjectFolder in $alGoProjectFolders) {
            $alGoProjects += [ALGoProjectInfo]::Get($alGoProjectFolder)
        }

        return $alGoProjects
    }

    <#
        Gets the app folders.
    #>
    [string[]] GetAppFolders([switch] $Resolve) {
        $appFolders = $this.Settings.appFolders

        if ($Resolve) {
            $appFolders = $appFolders | ForEach-Object { Join-Path $this.ProjectFolder $_ -Resolve -ErrorAction SilentlyContinue } | Where-Object { [AppProjectInfo]::IsAppProjectFolder($_) }| Select-Object -Unique
        }

        return $appFolders
    }

    <#
        Gets the test folders.
    #>
    [string[]] GetTestFolders([switch] $Resolve) {
        $testFolders = $this.Settings.testFolders

        if ($Resolve) {
            $testFolders = $testFolders | ForEach-Object { Join-Path $this.ProjectFolder $_ -Resolve -ErrorAction SilentlyContinue } | Where-Object { [AppProjectInfo]::IsAppProjectFolder($_) }| Select-Object -Unique
        }

        return $testFolders
    }
}