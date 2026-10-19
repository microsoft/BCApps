$script:MinimumCoveragePlatformVersion = [version]"30.0.56026.0"
$script:SupportedCoverageTestTypes = @("IntegrationTest", "Uncategorized")
$script:InternalParameterPrefix = "_bcAppsAlToolCoverage"

function ConvertTo-BcAppsCoverageHashtable {
    param($InputObject)

    if ($null -eq $InputObject) {
        return $null
    }
    if ($InputObject -is [string] -or $InputObject.GetType().IsValueType) {
        return $InputObject
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $InputObject.Keys) {
            $result["$key"] = ConvertTo-BcAppsCoverageHashtable -InputObject $InputObject[$key]
        }
        return $result
    }
    if ($InputObject -is [pscustomobject]) {
        $result = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $result[$property.Name] = ConvertTo-BcAppsCoverageHashtable -InputObject $property.Value
        }
        return $result
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object {
                ConvertTo-BcAppsCoverageHashtable -InputObject $_
            })
    }
    return $InputObject
}

function ConvertTo-BcAppsCoveragePathSegment {
    param(
        [AllowEmptyString()]
        [string]$Value,
        [string]$Fallback = "unknown"
    )

    $segment = ($Value -replace "[^a-zA-Z0-9._-]", "-").Trim([char[]]".-_")
    if ([string]::IsNullOrWhiteSpace($segment)) {
        return $Fallback
    }
    return $segment
}

function ConvertTo-BcAppsRepositoryRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot
    )

    $root = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        [System.StringComparison]::OrdinalIgnoreCase
    }
    else {
        [System.StringComparison]::Ordinal
    }

    if ($fullPath.Equals($root, $comparison)) {
        return "."
    }
    $prefix = $root + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($prefix, $comparison)) {
        throw "Code coverage source root '$fullPath' is outside repository '$root'."
    }
    return $fullPath.Substring($prefix.Length).Replace('\', '/')
}

function Get-BcAppsAlToolCoverageCapability {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestType,
        [AllowEmptyString()]
        [string]$PlatformVersion,
        [AllowEmptyString()]
        [string]$PlatformVersionReason,
        [AllowEmptyString()]
        [string]$ActionPath,
        [bool]$CoverageEnabled
    )

    if ($TestType -notin $script:SupportedCoverageTestTypes) {
        return @{
            Supported = $false
            Reason = "BCApps AlTool coverage supports only IntegrationTest and Uncategorized."
        }
    }
    if (-not $CoverageEnabled) {
        return @{
            Supported = $false
            Reason = "Code coverage is not enabled for this test dimension."
        }
    }
    if ([string]::IsNullOrWhiteSpace($PlatformVersion)) {
        return @{
            Supported = $false
            Reason = if ([string]::IsNullOrWhiteSpace($PlatformVersionReason)) {
                "RunPipeline did not provide the build container platform version."
            }
            else {
                $PlatformVersionReason
            }
        }
    }

    $parsedVersion = $null
    if (-not [version]::TryParse($PlatformVersion.Trim(), [ref]$parsedVersion)) {
        return @{
            Supported = $false
            Reason = "RunPipeline provided an invalid build container platform version."
        }
    }
    if ($parsedVersion -lt $script:MinimumCoveragePlatformVersion) {
        return @{
            Supported = $false
            Reason = "Container platform $parsedVersion is older than the required $($script:MinimumCoveragePlatformVersion)."
        }
    }
    if ([string]::IsNullOrWhiteSpace($ActionPath)) {
        return @{
            Supported = $false
            Reason = "GITHUB_ACTION_PATH is unavailable."
        }
    }

    $runnerModulePath = Join-Path $ActionPath "AlToolTestRunner.psm1"
    $coordinatorModulePath = Join-Path $ActionPath "RunTests.psm1"
    if (-not (Test-Path -LiteralPath $runnerModulePath -PathType Leaf)) {
        return @{
            Supported = $false
            Reason = "The running RunTests action does not contain AlToolTestRunner.psm1."
        }
    }
    if (-not (Test-Path -LiteralPath $coordinatorModulePath -PathType Leaf)) {
        return @{
            Supported = $false
            Reason = "The running RunTests action does not contain RunTests.psm1."
        }
    }

    return @{
        Supported = $true
        Reason = "Container platform $parsedVersion and the running RunTests action support BCApps AlTool coverage."
        RunnerModulePath = [System.IO.Path]::GetFullPath($runnerModulePath)
        CoordinatorModulePath = [System.IO.Path]::GetFullPath($coordinatorModulePath)
    }
}

function Get-BcAppsAlToolSourceRootData {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot,
        [Parameter(Mandatory = $true)]
        [string]$CoordinatorModulePath
    )

    $coordinatorModule = @(
        Get-Module | Where-Object {
            $_.Path -and
            [System.IO.Path]::GetFullPath($_.Path) -eq [System.IO.Path]::GetFullPath($CoordinatorModulePath)
        }
    ) | Select-Object -First 1
    if (-not $coordinatorModule) {
        $coordinatorModule = Import-Module -Name $CoordinatorModulePath -DisableNameChecking -PassThru
    }

    $analyzeRepo = {
        param($settings, $baseFolder, $project)
        AnalyzeRepo -settings $settings -baseFolder $baseFolder -project $project -doNotCheckArtifactSetting
    }

    return @(
        & $coordinatorModule {
            param($settings, $projectPath, $repositoryRoot, $analyzeRepo)
            Resolve-CodeCoverageSourceRootData -settings $settings -projectPath $projectPath `
                -baseFolder $repositoryRoot -analyzeRepo $analyzeRepo
        } $Settings $ProjectPath $RepositoryRoot $analyzeRepo
    )
}

function New-BcAppsAlToolCoverageContext {
    param(
        [Parameter(Mandatory = $true)]
        [Hashtable]$Parameters,
        [Parameter(Mandatory = $true)]
        [string]$TestType,
        [AllowNull()]
        [hashtable]$Settings,
        [AllowEmptyString()]
        [string]$ActionPath = $env:GITHUB_ACTION_PATH,
        [AllowEmptyString()]
        [string]$ContainerPlatformVersion = $env:containerPlatformVersion,
        [AllowEmptyString()]
        [string]$ContainerPlatformVersionReason = $env:containerPlatformVersionReason,
        [AllowNull()]
        [object[]]$SourceRootData
    )

    $null = $Parameters
    if (-not $Settings) {
        if ([string]::IsNullOrWhiteSpace($env:Settings)) {
            return @{
                Enabled = $false
                Reason = "The merged AL-Go settings are unavailable."
            }
        }
        try {
            $Settings = ConvertTo-BcAppsCoverageHashtable -InputObject (
                $env:Settings | ConvertFrom-Json
            )
        }
        catch {
            return @{
                Enabled = $false
                Reason = "The merged AL-Go settings could not be parsed."
            }
        }
    }

    $separateTestSettings = if ($Settings.ContainsKey("useSeparateTestAction")) {
        ConvertTo-BcAppsCoverageHashtable -InputObject $Settings.useSeparateTestAction
    }
    else {
        @{}
    }
    $coverageEnabled = $separateTestSettings.ContainsKey("enabled") -and
        [bool]$separateTestSettings.enabled -and
        $separateTestSettings.ContainsKey("codeCoverageEnabled") -and
        [bool]$separateTestSettings.codeCoverageEnabled
    $capability = Get-BcAppsAlToolCoverageCapability -TestType $TestType `
        -PlatformVersion $ContainerPlatformVersion `
        -PlatformVersionReason $ContainerPlatformVersionReason `
        -ActionPath $ActionPath -CoverageEnabled $coverageEnabled
    if (-not $capability.Supported) {
        return @{
            Enabled = $false
            Reason = $capability.Reason
        }
    }

    $coverageFormats = if ($separateTestSettings.ContainsKey("codeCoverageFormats")) {
        @($separateTestSettings.codeCoverageFormats | ForEach-Object { "$_".ToLowerInvariant() })
    }
    else {
        @("bc-json", "cobertura")
    }
    if ("bc-json" -notin $coverageFormats) {
        return @{
            Enabled = $false
            Reason = "BCApps coverage requires the authoritative bc-json format."
        }
    }

    $repositoryRoot = if ([string]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE)) {
        if (Get-Command Get-BaseFolder -ErrorAction SilentlyContinue) {
            Get-BaseFolder
        }
        else {
            (Get-Location).Path
        }
    }
    else {
        $env:GITHUB_WORKSPACE
    }
    $repositoryRoot = [System.IO.Path]::GetFullPath($repositoryRoot)
    $project = if ([string]::IsNullOrWhiteSpace($env:_project)) { "." } else { $env:_project }
    $projectPath = if ($project -eq ".") {
        $repositoryRoot
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $project))
    }
    if (-not (Test-Path -LiteralPath $projectPath -PathType Container)) {
        return @{
            Enabled = $false
            Reason = "The AL-Go project path '$projectPath' does not exist."
        }
    }

    if ($null -eq $SourceRootData) {
        try {
            $SourceRootData = @(
                Get-BcAppsAlToolSourceRootData -Settings $Settings -ProjectPath $projectPath `
                    -RepositoryRoot $repositoryRoot -CoordinatorModulePath $capability.CoordinatorModulePath
            )
        }
        catch {
            return @{
                Enabled = $false
                Reason = "Coverage source roots could not be resolved from the running action. $($_.Exception.Message)"
            }
        }
    }

    $sourceRoots = @()
    $sourceRootDetails = @()
    foreach ($rootData in @($SourceRootData)) {
        $root = ConvertTo-BcAppsCoverageHashtable -InputObject $rootData
        if (-not $root.ContainsKey("Path") -or [string]::IsNullOrWhiteSpace("$($root.Path)")) {
            continue
        }
        $fullRoot = [System.IO.Path]::GetFullPath("$($root.Path)")
        $relativeRoot = ConvertTo-BcAppsRepositoryRelativePath -Path $fullRoot -RepositoryRoot $repositoryRoot
        $sourceRoots += $fullRoot
        $sourceRootDetails += [ordered]@{
            path = $relativeRoot
            kind = if ($root.ContainsKey("Kind")) { "$($root.Kind)" } else { "unknown" }
            appId = if ($root.ContainsKey("AppId")) { "$($root.AppId)" } else { "" }
            appName = if ($root.ContainsKey("AppName")) { "$($root.AppName)" } else { "" }
        }
    }
    if ($sourceRoots.Count -eq 0 -or
        @($sourceRootDetails | Where-Object { $_.kind -eq "app" }).Count -eq 0) {
        return @{
            Enabled = $false
            Reason = "Coverage source roots do not identify any regular application roots."
        }
    }

    $coverageRoot = Join-Path (Join-Path $projectPath ".buildartifacts") "CodeCoverage"
    return @{
        Enabled = $true
        Reason = $capability.Reason
        TestType = $TestType
        Project = if ($project -eq ".") { "." } else { $project.Replace('\', '/') }
        ProjectName = if ([string]::IsNullOrWhiteSpace($env:_projectName)) {
            if ($Settings.ContainsKey("projectName")) { "$($Settings.projectName)" } else { "" }
        }
        else {
            $env:_projectName
        }
        BuildMode = if ([string]::IsNullOrWhiteSpace($env:_buildMode)) { "Default" } else { $env:_buildMode }
        Mode = "line"
        Formats = @($coverageFormats)
        RepositoryRoot = $repositoryRoot
        ProjectPath = $projectPath
        CoverageRoot = $coverageRoot
        StatusPath = Join-Path $coverageRoot "coverage-status.json"
        SidecarRoot = Join-Path $coverageRoot ".bcapps-runs"
        RunnerModulePath = $capability.RunnerModulePath
        SourceRoots = @($sourceRoots)
        SourceRootDetails = @($sourceRootDetails)
        ExpectedShards = @()
    }
}

function Disable-BcAppsAlToolCoverageContext {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context,
        [Parameter(Mandatory = $true)]
        [string]$Reason
    )

    $Context.Enabled = $false
    $Context.Reason = $Reason
}

function Register-BcAppsAlToolCoverageShard {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context,
        [Parameter(Mandatory = $true)]
        [string]$AppId,
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [Parameter(Mandatory = $true)]
        [string]$LogicalShard
    )

    if (-not $Context.Enabled) {
        return
    }
    $key = "$AppId::$LogicalShard"
    if (@($Context.ExpectedShards | Where-Object { "$($_.key)" -eq $key }).Count -gt 0) {
        return
    }
    $Context.ExpectedShards = @($Context.ExpectedShards) + @([ordered]@{
            key = $key
            appId = $AppId
            appName = $AppName
            logicalShard = $LogicalShard
        })
}

function New-BcAppsAlToolShardPlan {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$CodeunitsByApp,
        [AllowEmptyCollection()]
        [array]$RequiredDisabledWorkItems = @()
    )

    $requiredByApp = @{}
    foreach ($workItem in @($RequiredDisabledWorkItems)) {
        if (-not $requiredByApp.ContainsKey("$($workItem.AppName)")) {
            $requiredByApp["$($workItem.AppName)"] = @()
        }
        $requiredByApp["$($workItem.AppName)"] = @($requiredByApp["$($workItem.AppName)"]) + @($workItem)
    }

    $normalDisabledByApp = @{}
    $normalTestCountByApp = @{}
    $cleanWorkItems = @()
    foreach ($appName in $CodeunitsByApp.Keys) {
        $codeunits = @($CodeunitsByApp[$appName])
        $required = if ($requiredByApp.ContainsKey($appName)) { @($requiredByApp[$appName]) } else { @() }
        $requiredIds = @($required | ForEach-Object { "$($_.CodeunitId)" })
        $normalDisabledByApp[$appName] = @(
            $required | ForEach-Object {
                @{
                    codeunitName = "$($_.CodeunitName)"
                    method = @("*")
                }
            }
        )
        $normalTestCountByApp[$appName] = [int]((
                $codeunits |
                    Where-Object { "$($_.Id)" -notin $requiredIds } |
                    ForEach-Object { @($_.Tests).Count } |
                    Measure-Object -Sum
            ).Sum)

        foreach ($workItem in $required) {
            $selectedCodeunit = @($codeunits | Where-Object { "$($_.Id)" -eq "$($workItem.CodeunitId)" })
            if ($selectedCodeunit.Count -ne 1) {
                throw "Could not resolve clean codeunit '$($workItem.Key)' in the AlTool test catalog."
            }
            $copy = ConvertTo-BcAppsCoverageHashtable -InputObject $workItem
            $copy.CoverageLogicalShard = "clean-$($workItem.CodeunitId)"
            $copy.CoverageDisabledTests = @(
                $codeunits |
                    Where-Object { "$($_.Id)" -ne "$($workItem.CodeunitId)" } |
                    ForEach-Object {
                        @{
                            codeunitName = "$($_.Name)"
                            method = @("*")
                        }
                    }
            )
            $cleanWorkItems += [pscustomobject]$copy
        }
    }

    return @{
        NormalDisabledByApp = $normalDisabledByApp
        NormalTestCountByApp = $normalTestCountByApp
        CleanWorkItems = @($cleanWorkItems)
    }
}

function Set-BcAppsAlToolCoverageAttempt {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,
        [Parameter(Mandatory = $true)]
        $State,
        [Parameter(Mandatory = $true)]
        [string]$AppId,
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [Parameter(Mandatory = $true)]
        [string]$LogicalShard,
        [AllowEmptyCollection()]
        [array]$AdditionalDisabledTests = @(),
        [bool]$TrackCoverage = $true
    )

    if (-not $Parameters.ContainsKey("${script:InternalParameterPrefix}Context")) {
        return
    }
    $context = $Parameters["${script:InternalParameterPrefix}Context"]
    if (-not $context.Enabled) {
        return
    }
    $key = "$AppId::$LogicalShard"
    $attempt = if ($State.coverageAttempts.ContainsKey($key)) {
        [int]$State.coverageAttempts[$key] + 1
    }
    else {
        1
    }
    $State.coverageAttempts[$key] = $attempt
    $Parameters["${script:InternalParameterPrefix}AppId"] = $AppId
    $Parameters["${script:InternalParameterPrefix}AppName"] = $AppName
    $Parameters["${script:InternalParameterPrefix}LogicalShard"] = $LogicalShard
    $Parameters["${script:InternalParameterPrefix}Attempt"] = $attempt
    $Parameters["${script:InternalParameterPrefix}Track"] = $TrackCoverage
    $Parameters["${script:InternalParameterPrefix}DisabledTests"] = @($AdditionalDisabledTests)
}

function Get-BcAppsAlToolCoverageOutput {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context,
        [Parameter(Mandatory = $true)]
        [string]$AppId,
        [Parameter(Mandatory = $true)]
        [string]$LogicalShard,
        [Parameter(Mandatory = $true)]
        [int]$Attempt
    )

    $appSegment = ConvertTo-BcAppsCoveragePathSegment -Value $AppId -Fallback "unknown-app"
    $shardSegment = ConvertTo-BcAppsCoveragePathSegment -Value $LogicalShard -Fallback "default"
    $relativePath = "CodeCoverage/$appSegment/$shardSegment/$Attempt"
    return @{
        FullPath = Join-Path (Join-Path (Join-Path $Context.CoverageRoot $appSegment) $shardSegment) "$Attempt"
        RelativePath = $relativePath
    }
}

function Write-BcAppsCoverageJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        $Value
    )

    $parent = Split-Path -Path $Path -Parent
    New-Item -Path $parent -ItemType Directory -Force | Out-Null
    $Value | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Invoke-BcAppsAlToolCoverageLeaf {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,
        [Parameter(Mandatory = $true)]
        [string]$TestType
    )

    $contextKey = "${script:InternalParameterPrefix}Context"
    if (-not $Parameters.ContainsKey($contextKey)) {
        return [pscustomobject]@{ Handled = $false; Passed = $false }
    }
    $context = ConvertTo-BcAppsCoverageHashtable -InputObject $Parameters[$contextKey]
    if (-not $context.Enabled -or $TestType -notin $script:SupportedCoverageTestTypes) {
        return [pscustomobject]@{ Handled = $false; Passed = $false }
    }

    $appId = "$($Parameters["${script:InternalParameterPrefix}AppId"])"
    $appName = "$($Parameters["${script:InternalParameterPrefix}AppName"])"
    $logicalShard = "$($Parameters["${script:InternalParameterPrefix}LogicalShard"])"
    $attempt = [int]$Parameters["${script:InternalParameterPrefix}Attempt"]
    $trackCoverage = [bool]$Parameters["${script:InternalParameterPrefix}Track"]
    $output = Get-BcAppsAlToolCoverageOutput -Context $context -AppId $appId `
        -LogicalShard $logicalShard -Attempt $attempt
    $coverageComplete = $null
    $passed = $false
    $state = "failed"
    $errorMessage = ""

    try {
        if (Test-Path -LiteralPath $output.FullPath) {
            throw "Coverage output path '$($output.FullPath)' already exists."
        }
        New-Item -Path $output.FullPath -ItemType Directory -Force | Out-Null
        $runnerModule = Import-Module -Name $context.RunnerModulePath -DisableNameChecking -Force -PassThru
        $disabledTests = @(
            @($Parameters.disabledTests) + @($Parameters["${script:InternalParameterPrefix}DisabledTests"]) |
                ForEach-Object { ConvertTo-BcAppsCoverageHashtable -InputObject $_ }
        )
        $invokeParameters = @{
            ContainerName = "$($Parameters.containerName)"
            Credential = $Parameters.credential
            ExtensionId = $appId
            AppName = $appName
            CompanyName = "$($Parameters.companyName)"
            Tenant = "$($Parameters.tenant)"
            TestType = $TestType
            DisabledTests = @($disabledTests)
            JUnitResultFileName = "$($Parameters.JUnitResultFileName)"
            CoverageMode = "$($context.Mode)"
            CoverageOutputPath = $output.FullPath
            CoverageFormats = @($context.Formats)
            CoverageSourceRoots = @($context.SourceRoots)
            CoverageIsComplete = [ref]$coverageComplete
        }
        $passed = [bool](& $runnerModule {
                param($invokeParameters)
                Invoke-AlToolTestRun @invokeParameters
            } $invokeParameters)
        $state = if ($null -eq $coverageComplete) {
            "unsupported"
        }
        elseif ([bool]$coverageComplete) {
            "complete"
        }
        else {
            "incomplete"
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Exception occurred while running AlTool tests: $errorMessage / $($_.Exception.StackTrace)"
        $passed = $false
        $state = "failed"
    }
    finally {
        try {
            $sidecar = [ordered]@{
                key = "$appId::$logicalShard"
                appId = $appId
                appName = $appName
                logicalShard = $logicalShard
                attempt = $attempt
                outputDirectory = $output.RelativePath
                state = $state
                testsPassed = $passed
                tracked = $trackCoverage
                error = $errorMessage
            }
            $sidecarName = "$(
                ConvertTo-BcAppsCoveragePathSegment -Value $appId -Fallback 'unknown-app'
            )-$(
                ConvertTo-BcAppsCoveragePathSegment -Value $logicalShard -Fallback 'default'
            )-$attempt-$([guid]::NewGuid().ToString('N')).json"
            Write-BcAppsCoverageJson -Path (Join-Path $context.SidecarRoot $sidecarName) -Value $sidecar
        }
        catch {
            Write-Host "::warning::Could not write BCApps coverage sidecar. $($_.Exception.Message)"
            $passed = $false
        }
    }

    return [pscustomobject]@{ Handled = $true; Passed = $passed }
}

function Remove-BcAppsAlToolCoverageParameters {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )

    foreach ($key in @($Parameters.Keys)) {
        if ("$key".StartsWith($script:InternalParameterPrefix, [System.StringComparison]::Ordinal)) {
            $Parameters.Remove($key)
        }
    }
}

function Complete-BcAppsAlToolCoverage {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    if (-not $Context.Enabled) {
        return
    }

    $sidecars = @()
    if (Test-Path -LiteralPath $Context.SidecarRoot -PathType Container) {
        foreach ($sidecarFile in @(Get-ChildItem -LiteralPath $Context.SidecarRoot -Filter "*.json" -File)) {
            try {
                $sidecars += ConvertTo-BcAppsCoverageHashtable -InputObject (
                    Get-Content -LiteralPath $sidecarFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                )
            }
            catch {
                Write-Host "::warning::Ignoring invalid BCApps coverage sidecar '$($sidecarFile.FullName)'. $($_.Exception.Message)"
            }
        }
    }

    $runs = @()
    foreach ($expected in @($Context.ExpectedShards)) {
        $matchingAttempts = @(
            $sidecars |
                Where-Object { [bool]$_.tracked -and "$($_.key)" -eq "$($expected.key)" } |
                Sort-Object { [int]$_.attempt }
        )
        if ($matchingAttempts.Count -gt 0) {
            $finalAttempt = $matchingAttempts[-1]
            $runs += [ordered]@{
                appId = "$($finalAttempt.appId)"
                appName = "$($finalAttempt.appName)"
                outputDirectory = "$($finalAttempt.outputDirectory)"
                state = "$($finalAttempt.state)"
            }
        }
        else {
            $missingOutput = Get-BcAppsAlToolCoverageOutput -Context $Context `
                -AppId "$($expected.appId)" -LogicalShard "$($expected.logicalShard)" -Attempt 1
            $runs += [ordered]@{
                appId = "$($expected.appId)"
                appName = "$($expected.appName)"
                outputDirectory = $missingOutput.RelativePath
                state = "failed"
            }
        }
    }

    $status = [ordered]@{
        project = "$($Context.Project)"
        projectName = "$($Context.ProjectName)"
        buildMode = "$($Context.BuildMode)"
        mode = "$($Context.Mode)"
        formats = @($Context.Formats)
        sourceRoots = @($Context.SourceRootDetails | ForEach-Object { "$($_.path)" })
        sourceRootDetails = @($Context.SourceRootDetails)
        runs = @($runs)
    }
    $statusParent = Split-Path -Path $Context.StatusPath -Parent
    New-Item -Path $statusParent -ItemType Directory -Force | Out-Null
    $temporaryStatusPath = Join-Path $statusParent "coverage-status-$([guid]::NewGuid().ToString('N')).tmp"
    try {
        Write-BcAppsCoverageJson -Path $temporaryStatusPath -Value $status
        Move-Item -LiteralPath $temporaryStatusPath -Destination $Context.StatusPath -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryStatusPath) {
            Remove-Item -LiteralPath $temporaryStatusPath -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "::notice::BCApps coverage-aware RunTestsInBcContainer override owns the final code coverage status for this test dimension."
}

Export-ModuleMember -Function New-BcAppsAlToolCoverageContext, Disable-BcAppsAlToolCoverageContext,
    Register-BcAppsAlToolCoverageShard, New-BcAppsAlToolShardPlan,
    Set-BcAppsAlToolCoverageAttempt, Get-BcAppsAlToolCoverageOutput,
    Invoke-BcAppsAlToolCoverageLeaf, Remove-BcAppsAlToolCoverageParameters,
    Complete-BcAppsAlToolCoverage, Get-BcAppsAlToolCoverageCapability
