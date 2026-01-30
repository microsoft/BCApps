Param([Hashtable]$parameters)

# If parameters contains upgrade then remove
if ($parameters.ContainsKey("upgrade")) {
    Write-Host "Do not upgrade. Publishing the new app and keeping the old app published"
    $parameters.Remove("upgrade")
}

# if ignoreIfAppExists is there then remove
if ($parameters.ContainsKey("ignoreIfAppExists")) {
    Write-Host "Do not ignore if app exists. Publishing the new app and keeping the old app published"
    $parameters.Remove("ignoreIfAppExists")
}

Publish-BcContainerApp @parameters