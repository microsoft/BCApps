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
.DESCRIPTION
    Uses the pinned action's ToolResponse parser and JUnit writer for actual method outcomes.
    Persists missing outcomes as NativeTestResultUnreported errors, not AL assertion failures
    or skips. Native process/protocol failures also produce a NativeTestInfrastructure case.
    Completed outcomes and the original infrastructure cause are saved before failure propagates;
    merged infrastructure errors must never be accepted by test tolerance.
    Unselected OnRun lifecycle callbacks remain in JUnit system-out, not selected-test counts.
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
        $detail = ""
        if ($codeunits.Count -gt 0) {
            $parsed = $null
            $native = $null
            $nativeErrorDetails = ""
            $groupsPath = $null
            $infrastructureErrors = [System.Collections.Generic.List[string]]::new()
            $previousUsername = $env:BC_SERVER_USERNAME
            $previousPassword = $env:BC_SERVER_PASSWORD
            try {
                $connection = Get-AlToolConnection -ContainerName $parameters.containerName
                $groupsPath = New-AlTestGroupsFile -Codeunits $codeunits
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
                    $infrastructureErrors.Add("Native ALTool exited $($native.ExitCode).")
                }
                $parsed = ConvertFrom-AlTestGroupsOutput -OutputLines @($native.StandardOutput)
                $response = ($native.StandardOutput -join [Environment]::NewLine) | ConvertFrom-Json
                $errorCode = ""
                if ($response.PSObject.Properties["errorDetails"] -and $response.errorDetails) {
                    $nativeErrorDetails = $response.errorDetails | ConvertTo-Json -Depth 20
                    if ($response.errorDetails.PSObject.Properties["code"]) {
                        $errorCode = "$($response.errorDetails.code)"
                    }
                }
                if (-not $parsed.Succeeded -and $errorCode -ne "TestRunFailed") {
                    $infrastructureErrors.Add("Native ALTool failed ($errorCode): $($parsed.Message)")
                }
                elseif ($parsed.Message -and $infrastructureErrors.Count -gt 0) {
                    $infrastructureErrors.Add($parsed.Message)
                }
                if ($parsed.Succeeded -and $native.ExitCode -ne 0) {
                    $infrastructureErrors.Add("Native ALTool reported success but exited $($native.ExitCode).")
                }
                $selectedCodeunits = @{}
                foreach ($codeunit in $codeunits) { $selectedCodeunits["$($codeunit.Id)"] = $codeunit }
                foreach ($key in $parsed.Results.Keys) {
                    if (-not $selectedCodeunits.ContainsKey("$key")) {
                        $infrastructureErrors.Add("Native ALTool returned results for unrequested codeunit '$key'.")
                        continue
                    }
                    $seen = @{}
                    foreach ($result in $parsed.Results[$key]) {
                        $method = "$($result.MethodName)"
                        # The platform can report OnRun before each selected test method.
                        if ($method -eq "OnRun" -and $method -notin $selectedCodeunits[$key].Tests) {
                            if ($result.Outcome -eq "Fail") {
                                $infrastructureErrors.Add("Native lifecycle OnRun failed in codeunit '$key': $($result.Stacktrace)")
                            }
                            continue
                        }
                        if ($seen.ContainsKey($method)) {
                            $infrastructureErrors.Add("Native ALTool returned duplicate outcomes for '$key/$method'.")
                        }
                        $seen[$method] = $true
                        $requestedMethod = $method -replace '\[.+\]$', ''
                        if ($method -notin $selectedCodeunits[$key].Tests -and
                            $requestedMethod -notin $selectedCodeunits[$key].Tests) {
                            $infrastructureErrors.Add("Native ALTool returned an unrequested method '$key/$method' ($($result.Outcome)).")
                        }
                    }
                }
                $passed = $parsed.Succeeded -and $native.ExitCode -eq 0
            }
            catch {
                $infrastructureErrors.Add($_.Exception.Message)
            }
            finally {
                $env:BC_SERVER_USERNAME = $previousUsername
                $env:BC_SERVER_PASSWORD = $previousPassword
                if ($groupsPath) {
                    try { Remove-Item -LiteralPath $groupsPath -Force -ErrorAction Stop }
                    catch { $infrastructureErrors.Add("Native request cleanup failed: $($_.Exception.Message)") }
                }
            }
            $unreported = 0
            foreach ($codeunit in $codeunits) {
                $results = @()
                if ($parsed -and $parsed.Results.ContainsKey("$($codeunit.Id)")) {
                    $results = @($parsed.Results["$($codeunit.Id)"])
                }
                $failures = Add-JUnitTestSuite -Doc $doc -TestSuitesNode $doc.DocumentElement `
                    -Codeunit $codeunit -RequestedMethods @($codeunit.Tests) -MethodResults $results `
                    -ExtensionId $parameters.extensionId -AppName $parameters.appName `
                    -Hostname ([System.Net.Dns]::GetHostName())
                if ($failures -gt 0) { $passed = $false }
                $suite = $doc.DocumentElement.LastChild
                # The pinned writer labels absent outcomes as assertion failures. They are infrastructure
                # errors here: no AL outcome was received, even if the server executed the method.
                $missing = @($suite.SelectNodes("testcase/failure[@message='No result produced by al runtests']"))
                foreach ($failure in $missing) {
                    $errorNode = $doc.CreateElement("error")
                    $errorNode.SetAttribute("type", "NativeTestResultUnreported")
                    $errorNode.SetAttribute("message", "Selected method is unreported; no native outcome was received.")
                    $errorNode.InnerText = $infrastructureErrors -join [Environment]::NewLine
                    $null = $failure.ParentNode.ReplaceChild($errorNode, $failure)
                }
                $unreported += $missing.Count
                $suite.SetAttribute("errors", "$($missing.Count)")
                $suite.SetAttribute("failures", "$(@($suite.SelectNodes('testcase/failure')).Count)")
                $lifecycle = @($results | Where-Object {
                    $_.MethodName -eq "OnRun" -and $_.MethodName -notin $codeunit.Tests
                })
                if ($lifecycle.Count -gt 0) {
                    $output = $doc.CreateElement("system-out")
                    $output.InnerText = @(
                        foreach ($result in $lifecycle) {
                            "Native lifecycle OnRun: $($result.Outcome) ($($result.Ms) ms)"
                            if ($result.Stacktrace) { $result.Stacktrace }
                        }
                    ) -join [Environment]::NewLine
                    $null = $suite.AppendChild($output)
                }
            }
            if ($unreported -gt 0) {
                $infrastructureErrors.Add("$unreported selected native test methods are unreported.")
            }
            if ($infrastructureErrors.Count -gt 0) {
                $parameters["_bcAppsTestInfrastructureBlocksTolerance"] = $true
                $passed = $false
                $detail = $infrastructureErrors -join [Environment]::NewLine
                if ($nativeErrorDetails) {
                    $detail += [Environment]::NewLine + $nativeErrorDetails
                }
                if ($null -ne $native) {
                    $detail += [Environment]::NewLine + ($native.StandardError -join [Environment]::NewLine)
                }
                $suite = $doc.CreateElement("testsuite")
                $suite.SetAttribute("name", "Native ALTool infrastructure: $($parameters.appName) / $($parameters.tenant) / $($codeunits.Id -join ',')")
                foreach ($attribute in @{ tests = "1"; errors = "1"; failures = "0"; skipped = "0"; time = "0" }.GetEnumerator()) {
                    $suite.SetAttribute($attribute.Key, $attribute.Value)
                }
                $properties = $doc.CreateElement("properties")
                foreach ($property in @{ extensionid = $parameters.extensionId; appName = $parameters.appName }.GetEnumerator()) {
                    $node = $doc.CreateElement("property")
                    $node.SetAttribute("name", $property.Key)
                    $node.SetAttribute("value", $property.Value)
                    $null = $properties.AppendChild($node)
                }
                $null = $suite.AppendChild($properties)
                $case = $doc.CreateElement("testcase")
                $case.SetAttribute("classname", "Native ALTool infrastructure")
                $case.SetAttribute("name", "$($parameters.appName) on $($parameters.tenant)")
                $case.SetAttribute("time", "0")
                $errorNode = $doc.CreateElement("error")
                $errorNode.SetAttribute("type", "NativeTestInfrastructure")
                $errorNode.SetAttribute("message", "Native ALTool infrastructure failure")
                $errorNode.InnerText = $detail
                $null = $case.AppendChild($errorNode)
                $null = $suite.AppendChild($case)
                $null = $doc.DocumentElement.AppendChild($suite)
            }
        }
        $temporaryResult = "$resultPath.$([guid]::NewGuid().ToString('N')).tmp"
        try {
            $directory = Split-Path -Parent $resultPath
            if ($directory -and -not (Test-Path -LiteralPath $directory)) {
                $null = New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop
            }
            $doc.Save($temporaryResult)
            Move-Item -LiteralPath $temporaryResult -Destination $resultPath -Force -ErrorAction Stop
        }
        catch {
            throw "Could not publish native JUnit results '$resultPath': $($_.Exception.Message)$([Environment]::NewLine)$detail"
        }
        finally {
            if (Test-Path -LiteralPath $temporaryResult) {
                Remove-Item -LiteralPath $temporaryResult -Force
            }
        }
        if ($codeunits.Count -gt 0 -and $infrastructureErrors.Count -gt 0) {
            throw $detail
        }
        return [bool]$passed
    } $Parameters)
}

<#
.SYNOPSIS
    Reports incomplete native outcomes without counting JUnit errors as passed tests.
.PARAMETER ResultPath
    Canonical merged JUnit result file.
.PARAMETER SummaryPath
    GitHub step summary file to append the incomplete-run accounting to.
.OUTPUTS
    Boolean indicating whether native infrastructure or unreported-method errors were found.
#>
function Write-BcAppsNativeTestSummary {
    param(
        [Parameter(Mandatory = $true)][string]$ResultPath,
        [Parameter(Mandatory = $true)][string]$SummaryPath
    )

    if (-not (Test-Path -LiteralPath $ResultPath -PathType Leaf)) { return $false }
    $doc = [xml](Get-Content -LiteralPath $ResultPath -Raw)
    if (-not $doc.SelectSingleNode("//error[@type='NativeTestInfrastructure' or @type='NativeTestResultUnreported']")) {
        return $false
    }

    # The pinned AL-Go analyzer ignores JUnit error nodes and would count them as passes.
    # Keep the canonical JUnit artifact; replace only that misleading incomplete-run summary.
    $apps = @{}
    foreach ($suite in $doc.SelectNodes("//testsuite")) {
        $property = $suite.SelectSingleNode("properties/property[@name='appName']")
        $appName = if ($property) { $property.GetAttribute("value") } else { $suite.GetAttribute("name") }
        if (-not $apps.ContainsKey($appName)) { $apps[$appName] = @() }
        $apps[$appName] += @($suite.SelectNodes("testcase"))
    }
    $summary = @(
        "## Native ALTool test results (incomplete)"
        ""
        "Infrastructure errors are not AL assertion failures, passes or skips. Download TestResults.xml for the original cause and completed outcomes."
        ""
        "| Test app | Passed | AL failures | Skipped | Unreported | Infrastructure errors |"
        "|---|---:|---:|---:|---:|---:|"
        foreach ($appName in ($apps.Keys | Sort-Object)) {
            $cases = $apps[$appName]
            $passed = @($cases | Where-Object { -not $_.SelectSingleNode("failure|error|skipped") }).Count
            $failed = @($cases | Where-Object { $_.SelectSingleNode("failure") }).Count
            $skipped = @($cases | Where-Object { $_.SelectSingleNode("skipped") }).Count
            $unreported = @($cases | Where-Object { $_.SelectSingleNode("error[@type='NativeTestResultUnreported']") }).Count
            $infrastructure = @($cases | Where-Object { $_.SelectSingleNode("error[@type='NativeTestInfrastructure']") }).Count
            "| $($appName.Replace('|', '\|')) | $passed | $failed | $skipped | $unreported | $infrastructure |"
        }
    )
    $summary | Add-Content -LiteralPath $SummaryPath -Encoding utf8
    Write-Host "::error::Native ALTool results are incomplete or contain infrastructure errors. These errors must not be reported as passed tests."
    return $true
}

Export-ModuleMember -Function Invoke-BcAppsNativeTestRun, Install-BcAppsVerificationFramework, Write-BcAppsNativeTestSummary
