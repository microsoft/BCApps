[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'parameters', Justification = 'The parameter is not used, but it''s script needs to match this format')]
Param(
    [hashtable] $parameters
)

# Ordered list of test framework apps to install
$allApps = (Invoke-ScriptInBCContainer -containerName $containerName -scriptblock { Get-ChildItem -Path "C:\Applications\" -Filter "*.app" -Recurse })
$testToolkitApps = @(
    "Any",
    "Library Assert",
    "Library Variable Storage",
    "Permissions Mock",
    #"Test Runner",
    "System Application Test Library", 
    "Business Foundation Test Libraries",
    "Tests-TestLibraries"
)

foreach ($app in $testToolkitApps) {
    $appFile = $allApps | Where-Object { $($_.Name) -eq "Microsoft_$($app).app" }
    Publish-BcContainerApp -containerName $containerName -appFile ":$($appFile.FullName)" -skipVerification -install -sync
    $appFile = $null
} 

$installedApps | ForEach-Object {
    Write-Host "App $($_.Name) is installed"
}