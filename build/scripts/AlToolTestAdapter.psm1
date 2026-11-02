$ErrorActionPreference = "Stop"

function Get-BcAppsVerificationPackageId {
    param([Parameter(Mandatory = $true)][string]$Path)

    $reader = [System.IO.BinaryReader]::new([System.IO.File]::OpenRead($Path))
    try {
        # Match BcContainerHelper's Extract-AppFileToFolder NAVX header validation.
        $signature = $reader.ReadUInt32()
        $null = $reader.ReadUInt32()
        $metadataVersion = $reader.ReadUInt32()
        $packageId = [guid]::new($reader.ReadBytes(16))
        $contentLength = $reader.ReadInt64()
        $endSignature = $reader.ReadUInt32()
        if ($signature -ne 0x5856414e -or $endSignature -ne 0x5856414e -or
            $metadataVersion -gt 2 -or $contentLength -lt 0 -or
            $reader.BaseStream.Position + $contentLength -gt $reader.BaseStream.Length -or
            $packageId -eq [guid]::Empty) {
            throw "Unsupported NAVX framework package '$Path'."
        }
        return $packageId
    }
    finally {
        $reader.Dispose()
    }
}

<#
.SYNOPSIS
    Installs current-build framework packages on every verification tenant before native execution.
.PARAMETER Parameters
    Initialized container connection parameters from the separate test action.
.PARAMETER Tenants
    Operational tenants used by the canonical project scheduler.
#>
function Install-BcAppsVerificationFramework {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Parameters,
        [Parameter(Mandatory = $true)][string[]]$Tenants
    )

    if (-not $env:BCAPPS_FRAMEWORK_APPS_JSON -or
        -not (Test-Path -LiteralPath $env:BCAPPS_FRAMEWORK_APPS_JSON -PathType Leaf)) {
        throw "W1 verification requires the current Apps W1 dependency package list."
    }
    $requiredApps = [ordered]@{
        "Test Runner" = "23de40a6-dfe8-4f80-80db-d70f83ce8caf"
        "Permissions Mock" = "40860557-a18d-42ad-aecb-22b7dd80dc80"
    }
    $packages = @{}
    foreach ($path in (Get-Content -LiteralPath $env:BCAPPS_FRAMEWORK_APPS_JSON -Raw | ConvertFrom-Json)) {
        $path = "$path".TrimStart("(").TrimEnd(")")
        $manifest = Get-AppJsonFromAppFile -appFile $path
        if ($manifest.name -in $requiredApps.Keys -and $manifest.publisher -eq "Microsoft") {
            if ($packages.ContainsKey($manifest.name)) {
                throw "Duplicate source-built framework package '$($manifest.name)'."
            }
            if ("$($manifest.id)" -ne $requiredApps[$manifest.name]) {
                throw "Unexpected AppId for source-built '$($manifest.name)'."
            }
            $packages[$manifest.name] = @{
                Path = $path
                Version = [version]$manifest.version
                AppId = $requiredApps[$manifest.name]
                PackageId = Get-BcAppsVerificationPackageId -Path $path
            }
        }
    }
    foreach ($name in $requiredApps.Keys) {
        if (-not $packages.ContainsKey($name)) {
            throw "Source-built '$name' is missing from the current Apps W1 dependencies."
        }
    }

    $published = @(Get-BcContainerAppInfo -containerName $Parameters.containerName -publishedOnly)
    $tenantApps = @{}
    foreach ($tenant in ($Tenants | Select-Object -Unique)) {
        $tenantApps[$tenant] = @(Get-BcContainerAppInfo -containerName $Parameters.containerName `
            -tenant $tenant -tenantSpecificProperties)
    }

    # Preflight both packages and all tenants before any publication or upgrade.
    foreach ($name in $requiredApps.Keys) {
        $package = $packages[$name]
        $matching = @($published | Where-Object { "$($_.AppId)" -eq $package.AppId })
        foreach ($app in $matching) {
            if ($app.Scope -ne "Global" -or [version]$app.Version -gt $package.Version -or
                ([version]$app.Version -eq $package.Version -and "$($app.PackageId)" -ne "$($package.PackageId)")) {
                throw "Cannot replace '$name' $($app.Version) ($($app.Scope), PackageId $($app.PackageId)) with source package $($package.Version) ($($package.PackageId)). Rebuild with a higher CI version; same-version package replacement is forbidden."
            }
        }
        $package.Published = @($matching | Where-Object {
            [version]$_.Version -eq $package.Version -and "$($_.PackageId)" -eq "$($package.PackageId)"
        }).Count -eq 1
        foreach ($tenant in $tenantApps.Keys) {
            $installed = @($tenantApps[$tenant] | Where-Object { "$($_.AppId)" -eq $package.AppId -and $_.IsInstalled })
            if ($installed.Count -gt 1) {
                throw "Multiple installed versions of '$name' on tenant '$tenant'."
            }
            if ($installed.Count -eq 1) {
                $app = $installed[0]
                if ($app.Scope -ne "Global" -or [version]$app.Version -gt $package.Version -or
                    ([version]$app.Version -eq $package.Version -and "$($app.PackageId)" -ne "$($package.PackageId)")) {
                    throw "Tenant '$tenant' cannot upgrade '$name' to source package $($package.Version). A Global higher-version package or the exact already-installed PackageId is required."
                }
            }
        }
    }

    foreach ($name in $requiredApps.Keys) {
        $package = $packages[$name]
        Write-Host "Installing source-built '$name' version $($package.Version), PackageId $($package.PackageId), SHA256 $((Get-FileHash -LiteralPath $package.Path -Algorithm SHA256).Hash)."
        if (-not $package.Published) {
            Publish-BcContainerApp -containerName $Parameters.containerName -appFile $package.Path `
                -scope Global -skipVerification | Out-Host
        }
        foreach ($tenant in $tenantApps.Keys) {
            $installed = @($tenantApps[$tenant] | Where-Object { "$($_.AppId)" -eq $package.AppId -and $_.IsInstalled })
            if ($installed.Count -eq 0 -or [version]$installed[0].Version -lt $package.Version -or $installed[0].NeedsUpgrade) {
                Sync-BcContainerApp -containerName $Parameters.containerName -tenant $tenant `
                    -appName $name -appPublisher Microsoft -appVersion "$($package.Version)" -Mode Add | Out-Host
                $retainedData = @($tenantApps[$tenant] | Where-Object {
                    "$($_.AppId)" -eq $package.AppId -and $_.ExtensionDataVersion -and
                    [version]$_.ExtensionDataVersion -lt $package.Version
                })
                if ($installed.Count -eq 0 -and $retainedData.Count -eq 0) {
                    Install-BcContainerApp -containerName $Parameters.containerName -tenant $tenant `
                        -appName $name -appPublisher Microsoft -appVersion "$($package.Version)" | Out-Host
                }
                else {
                    Start-BcContainerAppDataUpgrade -containerName $Parameters.containerName -tenant $tenant `
                        -appName $name -appVersion "$($package.Version)" | Out-Host
                }
            }
            $actual = @(Get-BcContainerAppInfo -containerName $Parameters.containerName `
                -tenant $tenant -tenantSpecificProperties |
                Where-Object { "$($_.AppId)" -eq $package.AppId -and $_.IsInstalled })
            if ($actual.Count -ne 1 -or [version]$actual[0].Version -ne $package.Version -or
                "$($actual[0].PackageId)" -ne "$($package.PackageId)" -or
                $actual[0].Scope -ne "Global" -or $actual[0].NeedsUpgrade) {
                throw "Source-built '$name' package identity was not installed and upgraded on tenant '$tenant'."
            }
        }
    }
    foreach ($tenant in $tenantApps.Keys) {
        $before = @($tenantApps[$tenant] | Where-Object { $_.IsInstalled -and "$($_.AppId)" -notin $requiredApps.Values } |
            ForEach-Object { "$($_.AppId)|$($_.PackageId)|$($_.Version)|$($_.Scope)" } | Sort-Object)
        $after = @(Get-BcContainerAppInfo -containerName $Parameters.containerName -tenant $tenant -tenantSpecificProperties |
            Where-Object { $_.IsInstalled -and "$($_.AppId)" -notin $requiredApps.Values } |
            ForEach-Object { "$($_.AppId)|$($_.PackageId)|$($_.Version)|$($_.Scope)" } | Sort-Object)
        if (($before -join "`n") -cne ($after -join "`n")) {
            throw "Framework initialization changed unrelated installed app identities or scopes on tenant '$tenant'."
        }
    }
}

<#
.SYNOPSIS
    Executes the selected app's enabled methods natively with session renewal and no coverage.
.PARAMETER Parameters
    Canonical scheduler parameters, including the validated executable and action module paths.
#>
function Invoke-BcAppsNativeTestRun {
    param([Parameter(Mandatory = $true)][hashtable]$Parameters)

    foreach ($name in @("_bcAppsAlToolPath", "_bcAppsAlToolModulePath", "containerName",
        "extensionId", "appName", "companyName", "tenant", "JUnitResultFileName", "credential", "disabledTests")) {
        if (-not $Parameters.ContainsKey($name)) {
            throw "Native verification is missing required parameter '$name'."
        }
    }
    if (@($Parameters.Keys | Where-Object { "$_" -like "codeCoverage*" }).Count -gt 0) {
        throw "Native W1 verification must not collect coverage."
    }
    $runnerModule = Import-Module $Parameters["_bcAppsAlToolModulePath"] -PassThru

    # Reuse the pinned action's protocol parser, method-list serializer and JUnit reconciliation.
    # Only native invocation differs: renewal is explicit and coverage is never requested.
    return (& $runnerModule {
        param($parameters)

        $discovery = @{
            containerName = $parameters.containerName
            credential = $parameters.credential
            extensionId = $parameters.extensionId
            tenant = $parameters.tenant
            ignoreGroups = $true
        }
        foreach ($key in @("testType", "requiredTestIsolation", "testCodeunit", "companyName")) {
            if ($parameters.ContainsKey($key)) {
                $discovery[$key] = $parameters[$key]
            }
        }
        $disabledTests = @(
            foreach ($entry in $parameters.disabledTests) {
                if ($entry -is [System.Collections.IDictionary]) {
                    $entry
                }
                else {
                    $item = @{}
                    foreach ($property in $entry.PSObject.Properties) {
                        $item[$property.Name] = $property.Value
                    }
                    $item
                }
            }
        )
        $disabled = Get-DisabledTestKeySet -DisabledTests $disabledTests
        $codeunits = @(
            foreach ($codeunit in (Get-TestsFromBcContainer @discovery)) {
                $name = "$($codeunit.Name)".ToLowerInvariant()
                if ($disabled.Codeunits.ContainsKey($name)) { continue }
                $methods = @($codeunit.Tests | Where-Object {
                    -not $disabled.Methods.ContainsKey("${name}::$("$_".ToLowerInvariant())")
                })
                if ($methods.Count -gt 0) {
                    [PSCustomObject]@{ Id = $codeunit.Id; Name = $codeunit.Name; Tests = $methods }
                }
            }
        )
        $doc = [System.Xml.XmlDocument]::new()
        $resultPath = $parameters.JUnitResultFileName
        if (Test-Path -LiteralPath $resultPath) {
            $doc.Load($resultPath)
            if ($doc.DocumentElement.LocalName -ne "testsuites") {
                throw "Existing native JUnit result '$resultPath' must have a testsuites root."
            }
        }
        else {
            $null = $doc.AppendChild($doc.CreateElement("testsuites"))
        }
        $passed = $true
        if ($codeunits.Count -gt 0) {
            $connection = Get-AlToolConnection -ContainerName $parameters.containerName
            $groupsPath = New-AlTestGroupsFile -Codeunits $codeunits
            $previousUsername = $env:BC_SERVER_USERNAME
            $previousPassword = $env:BC_SERVER_PASSWORD
            try {
                $env:BC_SERVER_USERNAME = $parameters.credential.UserName
                $env:BC_SERVER_PASSWORD = $parameters.credential.GetNetworkCredential().Password
                $arguments = @(
                    "runtests", "--renewsession", "--testgroups", $groupsPath,
                    "--company", $parameters.companyName,
                    "--server", $connection.Server, "--serverinstance", $connection.ServerInstance,
                    "--port", "$($connection.Port)", "--environmenttype", "OnPrem",
                    "--authentication", "UserPassword", "--tenant", $parameters.tenant
                )
                Write-Host "Native ALTool --renewsession: '$($parameters.appName)', tenant '$($parameters.tenant)', $($codeunits.Count) codeunits, $(($codeunits.Tests | Measure-Object).Count) explicit methods."
                $native = Invoke-AlNativeCommand -FilePath $parameters["_bcAppsAlToolPath"] -ArgumentList $arguments
                if ($native.ExitCode -notin @(0, 1)) {
                    throw "Native ALTool exited $($native.ExitCode): $($native.StandardError -join [Environment]::NewLine)"
                }
                $parsed = ConvertFrom-AlTestGroupsOutput -OutputLines @($native.StandardOutput)
                if (-not $parsed.Succeeded -and $parsed.Results.Count -eq 0) {
                    throw "Native ALTool returned no test results: $($parsed.Message) $($native.StandardError -join [Environment]::NewLine)"
                }
                $passed = $parsed.Succeeded -and $native.ExitCode -eq 0
                foreach ($codeunit in $codeunits) {
                    $results = $parsed.Results["$($codeunit.Id)"]
                    if ($null -eq $results) { $results = @() }
                    $failures = Add-JUnitTestSuite -Doc $doc -TestSuitesNode $doc.DocumentElement `
                        -Codeunit $codeunit -RequestedMethods @($codeunit.Tests) -MethodResults $results `
                        -ExtensionId $parameters.extensionId -AppName $parameters.appName `
                        -Hostname ([System.Net.Dns]::GetHostName())
                    if ($failures -gt 0) { $passed = $false }
                }
            }
            finally {
                $env:BC_SERVER_USERNAME = $previousUsername
                $env:BC_SERVER_PASSWORD = $previousPassword
                Remove-Item -LiteralPath $groupsPath -Force
            }
        }
        $directory = Split-Path -Parent $resultPath
        if ($directory -and -not (Test-Path -LiteralPath $directory)) {
            $null = New-Item -ItemType Directory -Path $directory -Force
        }
        $doc.Save($resultPath)
        return [bool]$passed
    } $Parameters)
}

Export-ModuleMember -Function Invoke-BcAppsNativeTestRun, Install-BcAppsVerificationFramework
