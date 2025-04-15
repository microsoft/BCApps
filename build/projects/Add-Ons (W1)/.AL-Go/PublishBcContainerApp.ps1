Param([Hashtable]$parameters)

# If parameters contains upgrade then remove
if ($parameters.ContainsKey("upgrade")) {
    Write-Host "Do no upgrade"
    $parameters.Remove("upgrade")
}

# if ignoreIfAppExists is there then remove 
if ($parameters.ContainsKey("ignoreIfAppExists")) {
    Write-Host "Do not ignore if app exists"
    $parameters.Remove("ignoreIfAppExists")
}

Publish-BcContainerApp @parameters