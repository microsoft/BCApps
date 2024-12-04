[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'parameters', Justification = 'The parameter is not used, but it''s script needs to match this format')]
Param(
    [hashtable] $parameters
)

# Ordered list of test framework apps to install
$allApps = (Invoke-ScriptInBCContainer -containerName $containerName -scriptblock { Get-ChildItem -Path "C:\Applications\" -Filter "*.app" -Recurse })
$testToolkitApps = @(
    "Permissions Mock", 
    "Test Runner", 
    "Any", 
    "Library Assert", 
    "Library Variable Storage", 
    "System Application Test Library", 
    "Business Foundation Test Libraries", 
    "Performance Toolkit", 
    "AI Test Toolkit",
    "Contoso Coffee Demo Dataset" # This is used to generate test data
)

foreach ($app in $testToolkitApps) {
    $appFile = $allApps | Where-Object { $($_.Name) -eq "Microsoft_$($app).app" }
    Publish-BcContainerApp -containerName $containerName -appFile ":$($appFile.FullName)" -skipVerification -scope Tenant -install -sync
    $appFile = $null
} 