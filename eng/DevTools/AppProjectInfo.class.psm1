<#
.SYNOPSIS
    This class is used to store information about an AL project.
#>
class AppProjectInfo {
    [string] $AppProjectFolder
    [string] $Id
    [ValidateSet('app', 'test')]
    [string] $Type
    [PSCustomObject] $AppJson


    hidden AppProjectInfo([string] $appProjectFolder, [string] $type = 'app') {

        if(-not [AppProjectInfo]::IsAppProjectFolder($appProjectFolder)) {
            throw "$appProjectFolder is not an app project folder"
        }

        $appJsonFile = Join-Path $appProjectFolder 'app.json' -Resolve
        $_appJson = Get-Content -Path $appJsonFile -Raw | ConvertFrom-Json

        $this.AppProjectFolder = $appProjectFolder
        $this.Type = $type
        $this.Id = $_appJson.id
        $this.AppJson = $_appJson
    }

    static [AppProjectInfo] Get([string] $appProjectFolder) {
        $appInfo = [AppProjectInfo]::new($appProjectFolder, 'app')

        return $appInfo
    }

    static [AppProjectInfo] Get([string] $appProjectFolder, [string] $type) {
        $appInfo = [AppProjectInfo]::new($appProjectFolder, $type)

        return $appInfo
    }

    static [boolean] IsAppProjectFolder([string] $folder) {
        return (Test-Path -Path (Join-Path $folder 'app.json') -PathType Leaf)
    }

    <#
        Gets the app publisher.
    #>
    [string] GetAppPublisher() {
        return $this.AppJson.publisher
    }

    <#
        Gets the app name.
    #>
    [string] GetAppName() {
        return $this.AppJson.name
    }

    <#
        Gets the app version.
    #>
    [string] GetAppVersion() {
        return $this.AppJson.version
    }

    <#
        Gets the app file name.
    #>
    [string] GetAppFileName() {
        $appPublisher = $this.GetAppPublisher()
        $appName = $this.GetAppName()
        $appVersion = $this.GetAppVersion()

        return "$($appPublisher)_$($appName)_$($appVersion).app"
    }
}