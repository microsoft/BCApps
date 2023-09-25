Param(
    [Parameter(Mandatory=$true)]
    [string] $currentProjectFolder,
    [Hashtable] $parameters
)

. $PSScriptRoot\PreCompileApp.ps1 -parameters $parameters -currentProjectFolder $currentProjectFolder

$appFile = Compile-AppInBcContainer @parameters

# Return the app file path
$appFile