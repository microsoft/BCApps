Param(
    [Parameter(Mandatory=$true)]
    [string] $currentProjectFolder,
    [Hashtable] $parameters
)

# $app, $testApp and $bcptTestApp are boolean variables to determine the app type
$appType = switch ($true) {
    $app { "app" }
    $testApp { "testApp" }
    $bcptTestApp { "bcptApp" }
    Default { "app" }
}

. $PSScriptRoot\PreCompileApp.ps1 -parameters ([ref] $parameters) -currentProjectFolder $currentProjectFolder -appType $appType

$appFile = Compile-AppInBcContainer @parameters

# Return the app file path
$appFile