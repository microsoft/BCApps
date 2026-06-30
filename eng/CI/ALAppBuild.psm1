# Container for build metadata for a project
class BuildMetadata
{
    # The name of the application as stored in the projects.json and in the app.json of the AL project.
    [string] $ApplicationName

    # The path to the project root folder
    [string] $ProjectFolder

    # The path to the app.json file for the project
    [string] $AppJsonPath

    # The path to the cache folder used by this project
    [string] $PackageCacheFolder

    # The path to the output folder used for writing the output app file
    [string] $PackageOutputFolder

    # The list of folders to probe for assemblies when building this project.
    [string[]] $AssemblyProbingPaths

    # The directory in which to output additional build artifacts.
    [string] $BuildArtifactsOutputFolder

    # True if the project is part of a GDL localization.
    [bool] $IsGDLProject

    # Is this a locale independent application?
    # The "System Application" is one example of a multi-country project where one code + multiple translations is used by multiple localizations
    [bool] $IsMultiCountry

    # True if the code analysis should be ran for this project
    [bool] $RunStaticCodeAnalysis

    # The path to the ruleset file to use for this project
    [string] $RuleSetPath

    # The path to the ruleset file to use for this project in minor realease branches
    [string] $RuleSetPathMinorRelease

    # The path to ErrorLog.json file
    [string] $ErrorLog

    # Specify the level of logs written to the log file. Values: verbose, normal, warning, error
    [string] $LogLevel

    # True if translations are available for the given project.
    [bool] $HasTranslations

    # True if the project cannot be uninstalled by users after it is installed.
    [bool] $BlockUninstall

    # The list of countries in which this project is available.
    [string[]] $SupportedCountries

    # The list of countries in which this project is not available.
    # Used for GDL projects which are usually available in all locales, but not in some
    [string[]] $UnsupportedCountries

    # True if this is a test project.
    [bool] $IsTest

    # True if this is an internal project that should not be published
    [bool] $IsInternal

    # True if this project is a language pack for one or more applications.
    [bool] $IsLanguagePack

    # The path relative to the root of the DVD where the artifacts for this project should be placed.
    [string] $DVDFolder

    # The type of updates that can be applied to the project.
    # Valid values are:
    # none - No updates allowed
    # hotfix - Only hotfixes allowed
    # minor - New minor versions allowed
    # all - All types of updates allowed
    [string] $AllowedUpdates

    # True if the application is intended to be installed when updating an environment, false otherwise.
    [bool] $InstallOnEnvironmentUpdate

    # True if this extension should not be installed by default for the given group, false otherwise.
    # This property is dependent on the group, so the value might be different depending on the context.
    [bool] $DoNotInstall

    # The URL to the repository where the source code for this project is stored.
    # This property is used for open-sourced code to allow for easy navigation to the source code from the client.
    [string] $RepositoryUrl

    # True if the app is in private preview and shouldn't be checked for breaking changes, false otherwise.
    # This implies that the preview environments using this app might not be able to upgrade future versions without force-sync.
    [bool] $IsPrivatePreview
}

class ApplicationMetadata
{
    [BuildMetadata] $BuildMetadata

    # True if this extension should not be installed by default for the given group, false otherwise.
    [bool] $DoNotInstall
}

class ApplicationGroupMetadata
{
    [string] $Name
    [ApplicationMetadata[]] $Applications
}

class BuildMetadataProvider
{
    static [PSCustomObject] $ApplicationBuildInfo;
    static [PSCustomObject] $ApplicationGroupInfo;
    static hidden [bool] $IsNAVContext = $false;
    static hidden [bool] $ContextDetected = $false;

    static hidden LoadBuildInfo()
    {
        if (![BuildMetadataProvider]::ApplicationBuildInfo)
        {
            # BCApps uses eng/AL-Go/projects.json and eng/AL-Go/groups.json
            [BuildMetadataProvider]::ApplicationBuildInfo = Get-Content -Path "$ENV:INETROOT\eng/AL-Go/projects.json" -Raw | ConvertFrom-Json
            [BuildMetadataProvider]::ApplicationGroupInfo = Get-Content -Path "$ENV:INETROOT\eng/AL-Go/groups.json" -Raw | ConvertFrom-Json
        }

        if (![BuildMetadataProvider]::ContextDetected)
        {
            # Detect whether we are running in a NAV repo (has App\BCApps) or a
            # standalone BCApps repo (source is directly under src\).
            [BuildMetadataProvider]::IsNAVContext = Test-Path (Join-Path $ENV:INETROOT "App\BCApps") -PathType Container
            [BuildMetadataProvider]::ContextDetected = $true
        }
    }

    <#
    .SYNOPSIS
        Remaps a build-system path for the current repo layout.
    .DESCRIPTION
        In NAV, projects.json paths like $env:INETROOT\App\BCApps\src\... resolve
        directly. In the standalone BCApps repo the App\ layer does not exist;
        source lives under src\, src\Apps\, and src\Layers\ instead.
        This method remaps expanded paths so they resolve in either context.
    #>
    static hidden [string] RemapPath([string] $ExpandedPath)
    {
        if ([BuildMetadataProvider]::IsNAVContext)
        {
            return $ExpandedPath
        }

        $inetroot = $ENV:INETROOT
        $result = $ExpandedPath

        # App\BCApps\src\X  →  src\X   (BCApps submodule content)
        $result = $result -replace [regex]::Escape("$inetroot\App\BCApps\"), "$inetroot\"

        # App\Apps\X  →  src\Apps\X
        $result = $result -replace [regex]::Escape("$inetroot\App\Apps"), "$inetroot\src\Apps"

        # App\Layers\X  →  src\Layers\X
        $result = $result -replace [regex]::Escape("$inetroot\App\Layers"), "$inetroot\src\Layers"

        # App\Rulesets\X  →  src\rulesets\X
        $result = $result -replace [regex]::Escape("$inetroot\App\Rulesets"), "$inetroot\src\rulesets"

        return $result
    }

    hidden static [PSCustomObject[]] GetApplicationsInGroup([string]$GroupName, [string] $CountryCode)
    {
        $result = @()

        $applicationsInGroups = [BuildMetadataProvider]::ApplicationGroupInfo
        $applicationsInGroups | ForEach-Object {
            $app = $_

            if ($GroupName -eq 'All') { # every app is in the 'All' group
                $appIsInGroup = $true
            } else {
                $matchingGroup = $app.groups | Where-Object { $_.name -eq $GroupName }
                if ($matchingGroup) {
                    $countries = $matchingGroup.countries
                    if ($countries) {
                        $appIsInGroup = $countries -contains $CountryCode
                    } else {
                        $appIsInGroup = $true
                    }

                    $exclude = $matchingGroup.exclude_countries
                    $appIsInGroup = $appIsInGroup -and $exclude -notcontains $CountryCode
                } else {
                    $appIsInGroup = $false
                }
            }

            if ($appIsInGroup)
            {
                $doNotInstall = $false
                if ($matchingGroup.doNotInstall) {
                    $doNotInstall = $matchingGroup.doNotInstall
                } elseif ($matchingGroup.installInCountries) {
                    $doNotInstall = ($matchingGroup.installInCountries -notcontains $CountryCode)
                }

                $result += @{
                    "name"         = $app.name
                    "group"        = $GroupName
                    "doNotInstall" = $doNotInstall
                }
            }
        }

        if ($result.Length -eq 0)
        {
            throw "The group '$GroupName' could not be found. Have you updated eng/AL-Go/groups.json ?"
        }

        return $result
    }

    static [ApplicationGroupMetadata] GetApplicationGroup([string] $CountryCode, [string] $GroupName, [switch] $SkipTests, [switch] $SkipLanguagePacks, [switch] $SkipCountryCheck)
    {
        [BuildMetadataProvider]::LoadBuildInfo()

        $indent = "   "
        Write-Log "Determining composition of group $GroupName for $CountryCode (SkipTests: $SkipTests, SkipLanguagePacks: $SkipLanguagePacks, SkipCountryCheck: $SkipCountryCheck)" -ForegroundColor Magenta
        $result = [ApplicationGroupMetadata]::new()
        $result.Name = $GroupName
        $result.Applications = @()

        $baseGroup = $GroupName
        $testGroup = $false
        if ($GroupName -like '*-App') {
            $baseGroup = $GroupName -replace '-App',''
            $SkipTests = $true
        }
        if ($GroupName -like '*-Test') {
            $baseGroup = $GroupName -replace '-Test',''
            $testGroup = $true
        }

        [PSCustomObject[]] $applications = [BuildMetadataProvider]::GetApplicationsInGroup($baseGroup, $CountryCode)
        foreach ($application in $applications)
        {
            $applicationName = $application.name

            [ApplicationMetadata] $appMetadata = [ApplicationMetadata]::new()
            try
            {
                $appMetadata.BuildMetadata = [BuildMetadataProvider]::GetProject($CountryCode, $applicationName, $false)
            }
            catch
            {
                # In standalone BCApps repos some apps (Internal, LanguagePacks, etc.)
                # don't have source on disk. Skip them gracefully.
                if (![BuildMetadataProvider]::IsNAVContext)
                {
                    Write-Verbose "$indent Skipping $applicationName because its source was not found."
                    Continue
                }
                throw
            }
            $appMetadata.DoNotInstall = $application.doNotInstall
            $appMetadata.BuildMetadata.DoNotInstall = $appMetadata.DoNotInstall

            if ($SkipTests -and $appMetadata.BuildMetadata.IsTest)
            {
                Write-Verbose "$indent Skipping $applicationName because it is a test project."
                Continue
            }
            if ($testGroup -and -not $appMetadata.BuildMetadata.IsTest)
            {
                Write-Verbose "$indent Skipping $applicationName because it is not a test project."
                Continue
            }

            if ($SkipLanguagePacks -and $appMetadata.BuildMetadata.IsLanguagePack)
            {
                Write-Verbose "$indent Skipping $applicationName because it is a language pack."
                Continue
            }

            if ($appMetadata.BuildMetadata.UnsupportedCountries -and $appMetadata.BuildMetadata.UnsupportedCountries -contains $CountryCode)
            {
                Write-Verbose "$indent Skipping $applicationName because $CountryCode is not supported."
                Continue
            }

            if($SkipCountryCheck)
            {
                Write-Verbose "$indent Adding $applicationName because country check is skipped."
                $result.Applications += $appMetadata
            }
            elseif (!$appMetadata.BuildMetadata.SupportedCountries)
            {
                Write-Verbose "$indent Adding $applicationName because it is supported in all countries."
                $result.Applications += $appMetadata
            }
            elseif ($appMetadata.BuildMetadata.SupportedCountries -contains "All")
            {
                Write-Verbose "$indent Adding $applicationName because it is supported in all countries."
                $result.Applications += $appMetadata
            }
            elseif ($appMetadata.BuildMetadata.SupportedCountries -contains $CountryCode)
            {
                Write-Verbose "$indent Adding $applicationName because it is supported in $CountryCode"
                $result.Applications += $appMetadata
            }
        }

        Write-Log "Group $GroupName for $CountryCode contains $($result.Applications.Count) applications: $(($result.Applications | ForEach-Object { $_.BuildMetadata.ApplicationName }) -join ', ')" -ForegroundColor Magenta

        return $result
    }

    static hidden [String] GetCountryRuleSetPath([string]$RuleSetPath, [string]$CountryCode)
    {
        if([string]::IsNullOrEmpty($RuleSetPath))
        {
            return $RuleSetPath
        }
        if(!(Test-Path $RuleSetPath))
        {
            if ([BuildMetadataProvider]::IsNAVContext)
            {
                Write-Log "RuleSetPath is not of a legal form: $RuleSetPath"
            }
            return $RuleSetPath
        }
        $CountryRuleSetPath = [System.IO.FileInfo]$RuleSetPath
        $CountryRuleSetPath = $global:ExecutionContext.InvokeCommand.ExpandString("$($CountryRuleSetPath.DirectoryName)\Layers\$CountryCode\$($CountryRuleSetPath.Name)")
        if(Test-Path $CountryRuleSetPath)
        {
            Write-Log "RuleSetPath has been replaced from $RuleSetPath to $CountryRuleSetPath" -ForegroundColor Green
            return $CountryRuleSetPath
        }
        else
        {
            return $RuleSetPath
        }
    }

    static [BuildMetadata] GetProject([string]$CountryCode, [string]$ApplicationName, [switch] $StrictMode)
    {
        [BuildMetadataProvider]::LoadBuildInfo()

        $projectInfo = [BuildMetadataProvider]::ApplicationBuildInfo.projects.($ApplicationName)
        if (!$projectInfo)
        {
            throw "$ApplicationName is not part of the known set of applications. Have you updated the projects.json file with information about the new application?"
        }

        # Initialize the package cache folder with the default value if it has not been set.
        if (!$projectInfo.packageCacheFolder)
        {
            Add-Member -InputObject $projectInfo -Name "packageCacheFolder" -value "" -MemberType NoteProperty

            if ($projectInfo.isMultiCountry)
            {
                $projectInfo.packageCacheFolder = [BuildMetadataProvider]::ApplicationBuildInfo.defaults.multiCountryPackageCacheFolder
            }
            else
            {
                $projectInfo.packageCacheFolder = [BuildMetadataProvider]::ApplicationBuildInfo.defaults.packageCacheFolder
            }
        }

        # Initialize the package output folder with the default value if it has not been set.
        if (!$projectInfo.packageOutputFolder)
        {
            Add-Member -InputObject $projectInfo -Name "packageOutputFolder" -value "" -MemberType NoteProperty

            if ($projectInfo.isMultiCountry)
            {
                $projectInfo.packageOutputFolder = [BuildMetadataProvider]::ApplicationBuildInfo.defaults.multiCountrypackageOutputFolder
            }
            else
            {
                $projectInfo.packageOutputFolder = [BuildMetadataProvider]::ApplicationBuildInfo.defaults.packageOutputFolder
            }
        }

        # Initialize the build artifacts output folder with the default value if it has not been set.
        if (!$projectInfo.buildArtifactsOutputFolder)
        {
            Add-Member -InputObject $projectInfo -Name "buildArtifactsOutputFolder" -value "" -MemberType NoteProperty

            if ($projectInfo.isMultiCountry)
            {
                $projectInfo.buildArtifactsOutputFolder = [BuildMetadataProvider]::ApplicationBuildInfo.defaults.multiCountryBuildArtifactsOutputFolder
            }
            else
            {
                $projectInfo.buildArtifactsOutputFolder = [BuildMetadataProvider]::ApplicationBuildInfo.defaults.buildArtifactsOutputFolder
            }
        }

        if (!$projectInfo.assemblyProbingFolders)
        {
            Add-Member -InputObject $projectInfo -Name "assemblyProbingFolders" -value ([BuildMetadataProvider]::ApplicationBuildInfo.defaults.assemblyProbingFolders) -MemberType NoteProperty
        }

        if (!$projectInfo.allowedUpdates -or [string]::IsNullOrEmpty($projectInfo.allowedUpdates))
        {
            Add-Member -InputObject $projectInfo -Name "allowedUpdates" -value ([BuildMetadataProvider]::ApplicationBuildInfo.defaults.allowedUpdates) -MemberType NoteProperty
        }

        $buildMetadata = [BuildMetadata]::new()
        $buildMetadata.ApplicationName = $ApplicationName
        $buildMetadata.ProjectFolder = [BuildMetadataProvider]::RemapPath($global:ExecutionContext.InvokeCommand.ExpandString($projectInfo.projectPath))
        $buildMetadata.AppJsonPath = Join-Path $buildMetadata.ProjectFolder "app.json"
        if($projectInfo.appJsonPath) {
            $buildMetadata.AppJsonPath = [BuildMetadataProvider]::RemapPath($global:ExecutionContext.InvokeCommand.ExpandString($projectInfo.appJsonPath))
        }
        if(-not (Test-Path $buildMetadata.AppJsonPath -PathType Leaf))
        {
            throw "The app.json file $($buildMetadata.AppJsonPath) does not exist."
        }
        $buildMetadata.PackageCacheFolder = [BuildMetadataProvider]::RemapPath($global:ExecutionContext.InvokeCommand.ExpandString($projectInfo.packageCacheFolder))
        $buildMetadata.PackageOutputFolder = [BuildMetadataProvider]::RemapPath($global:ExecutionContext.InvokeCommand.ExpandString($projectInfo.packageOutputFolder))
        $buildMetadata.BuildArtifactsOutputFolder = [BuildMetadataProvider]::RemapPath($global:ExecutionContext.InvokeCommand.ExpandString($projectInfo.buildArtifactsOutputFolder))
        $buildMetadata.IsMultiCountry = $projectInfo.isMultiCountry
        $buildMetadata.IsGDLProject = $projectInfo.isGDLProject
        $buildMetadata.SupportedCountries = $projectInfo.supportedCountries
        $buildMetadata.UnsupportedCountries = $projectInfo.unsupportedCountries
        $buildMetadata.IsTest = $projectInfo.isTest
        $buildMetadata.IsInternal = $projectInfo.isInternal
        $buildMetadata.BlockUninstall = $projectInfo.blockUninstall
        $buildMetadata.RunStaticCodeAnalysis = $projectInfo.runStaticCodeAnalysis
        $buildMetadata.IsPrivatePreview = $projectInfo.isPrivatePreview
        $buildMetadata.AllowedUpdates = $projectInfo.allowedUpdates
        $buildMetadata.InstallOnEnvironmentUpdate = $projectInfo.installOnEnvironmentUpdate
        $buildMetadata.RepositoryUrl = $projectInfo.repositoryUrl

        if ($buildMetadata.IsPrivatePreview -and !$buildMetadata.IsInternal)
        {
            throw "Application $ApplicationName is marked as private preview, but not as internal. Private preview apps must be marked as internal."
        }

        if ($buildMetadata.RunStaticCodeAnalysis)
        {
            $buildMetadata.ErrorLog = Join-Path $buildMetadata.PackageOutputFolder ("$($ApplicationName)_ErrorLog_$CountryCode.json")
            $buildMetadata.LogLevel = $projectInfo.logLevel
        }

        if ($StrictMode)
        {
            $buildMetadata.RuleSetPath = [BuildMetadataProvider]::RemapPath($global:ExecutionContext.InvokeCommand.ExpandString($projectInfo.ruleSetPathMinorRelease))
        }
        else
        {
            $buildMetadata.RuleSetPath = [BuildMetadataProvider]::RemapPath($global:ExecutionContext.InvokeCommand.ExpandString($projectInfo.ruleSetPath))
            $buildMetadata.RuleSetPath = [BuildMetadataProvider]::GetCountryRuleSetPath($($buildMetadata.RuleSetPath), $CountryCode)
        }

        $buildMetadata.IsLanguagePack = $projectInfo.isLanguagePack
        $buildMetadata.DVDFolder = $projectInfo.dvdFolder

        # All GDL projects that are not tests have translations
        $buildMetadata.HasTranslations = $projectInfo.hasTranslations -or `
            $projectInfo.isLanguagePack -or `
        ($projectInfo.isGDLProject -and !$projectInfo.isTest) -or `
        ($projectInfo.isMultiCountry -and !$projectInfo.isTest)

        $buildMetadata.AssemblyProbingPaths = @($projectInfo.assemblyProbingFolders | ForEach-Object {
            [BuildMetadataProvider]::RemapPath($global:ExecutionContext.InvokeCommand.ExpandString($_))
        })

        return $buildMetadata
    }
}

class ApplicationBuildConfiguration
{
    [string] $CountryCode
    [string] $ApplicationName
    [BuildMetadata] $BuildMetadata
    [string] $ErrorLog
    [string] $LogLevel

    ApplicationBuildConfiguration([string] $CountryCode, [string] $ApplicationName)
    {
        $this.CountryCode = $CountryCode
        $this.ApplicationName = $ApplicationName
        $this.BuildMetadata = [BuildMetadataProvider]::GetProject($this.CountryCode, $this.ApplicationName, $false)
    }

    ApplicationBuildConfiguration([string] $CountryCode, [string] $ApplicationName, [switch] $StrictMode)
    {
        $this.CountryCode = $CountryCode
        $this.ApplicationName = $ApplicationName
        $this.BuildMetadata = [BuildMetadataProvider]::GetProject($this.CountryCode, $this.ApplicationName, $StrictMode)
    }

    ApplicationBuildConfiguration([string] $CountryCode, [string] $ApplicationName, [string] $ErrorLog, [string] $LogLevel)
    {
        $this.ApplicationBuildConfiguration($CountryCode, $ApplicationName)
        $this.ErrorLog = $ErrorLog
        $this.LogLevel = $LogLevel
    }

    # Get the path to the folder containing the source code for the project.
    [string] GetProjectFolder()
    {
        return $this.BuildMetadata.ProjectFolder
    }

    # Get the path to the folder containing reference packages needed to compile the project
    [string] GetPackageCacheFolder()
    {
        Initialize-Directory ($this.BuildMetadata.PackageCacheFolder)
        return $this.BuildMetadata.PackageCacheFolder
    }

    # Check if the package has already been built
    [bool] IsBuilt()
    {
        # Use fuzzy matching to allow for incremental build, this might cause problems locally if not run on a clean enlistment.
        $package = GetApplicationPackageImpl -ApplicationName $this.ApplicationName -CountryCode $this.CountryCode
        if ($package)
        {
            return $true;
        }

        return $false;
    }

    # Get the path to the .app file that should be created as a result of compiling this package.
    [string] GetPackageOutputPath()
    {
        return Join-Path $this.GetPackageOutputFolder() $this.GetPackageName()
    }

    # Get the name of the file that should be created as a result of compiling this package.
    [string] GetPackageName()
    {
        return ("Microsoft_$($this.ApplicationName)_$($this.GetApplicationVersion()).app")
    }

    [string] GetApplicationVersion()
    {
        return (Get-NavBuildFileVersion)
    }

    [string] GetProjectManifestPath()
    {
        return Join-Path $this.GetProjectFolder() "app.json"
    }

    # Get the path to the folder containing the created package.
    [string] GetPackageOutputFolder()
    {
        Initialize-Directory $this.BuildMetadata.PackageOutputFolder
        return $this.BuildMetadata.PackageOutputFolder
    }

    # Get the path to the folder that will contain artifacts created by building this project.
    # Artifacts include .lcg translation file, archive of the source code etc.
    [string] GetBuildArtifactsFolder()
    {
        Initialize-Directory $this.BuildMetadata.BuildArtifactsOutputFolder
        return $this.BuildMetadata.BuildArtifactsOutputFolder
    }

    [void] BuildProject([switch] $Translated, [switch] $DiscardTranslationFiles, [switch] $DiscardSourceArchive, [string] $TranslationFileFormat, [switch] $RunStaticCodeAnalysis, [switch] $StrictMode, [switch] $EnableCLEANPreProcessorSymbols)
    {
        $this.ImportTranslationResources($Translated)
        $originalProjectFolder = $this.GetProjectFolder()

        # If the project is not a GDL project we have to copy the whole build folder to a location
        # that is not under version control so that we can stamp in the version numbers for the application
        if (!$this.BuildMetadata.IsGDLProject)
        {
            $tempBuildFolder = Get-ALProjectTempBuildFolder -ProjectFolder $originalProjectFolder
            Invoke-RoboCopy $originalProjectFolder $tempBuildFolder -Recursive -Quiet -Options '/zb'
            $this.BuildMetadata.ProjectFolder = $tempBuildFolder
        }

        try
        {
            ReplaceALNavBuildMacrosInApp -ApplicationName $this.ApplicationName -CountryCode $this.CountryCode -SourceFolder $this.GetProjectFolder()
            $this.SetupApplicationDependencies()

            $features = @()
            if ($TranslationFileFormat -eq "XLIFF")
            {
                $features += "translationfile"
            }
            else
            {
                $features += "lcgtranslationfile"
            }

            $features += "generateCaptions" # use object's name as caption if the caption property is missing
            $features += "GenerateReportLayout-" # use object's name as caption if the caption property is missing

            $analyzers = $this.SetupCodeAnalysisDependencies($RunStaticCodeAnalysis, $StrictMode, $EnableCLEANPreProcessorSymbols)

            $errorLogPath = $this.BuildMetadata.ErrorLog
            if ($errorLogPath) {
                # Save ErrorLog to Logs folder, so it is exported on failure
                $errorLogPath = Join-Path (Get-LogRootPath) (Split-Path $errorLogPath -Leaf)
            }

            $compilationParams = @{
                ProjectDirectory = $this.GetProjectFolder();
                OutputPackage = $this.GetPackageOutputPath();
                PackageCacheDirectory = $this.GetPackageCacheFolder();
                AssemblyProbingPaths = $this.GetAssemblyProbingFolders();
                Parallel = $true;
                Features = $features;
                GenerateReportLayout = $false;
                ErrorLog = $errorLogPath;
                LogLevel = $this.BuildMetadata.LogLevel;
                Analyzers = $analyzers;
                RuleSetFile = $this.BuildMetadata.RuleSetPath
            }

            if ($this.BuildMetadata.RepositoryUrl)
            {
                # If the project is part of the BCApps repository, we can stamp in the commit hash for the bcapps submodule
                if ($this.BuildMetadata.RepositoryUrl -match "github.com/microsoft/BCApps") {
                    . "$($ENV:INETROOT)\eng/Core\Helpers\SourceControl-GIT.ps1"
                    $compilationParams += @{
                        SourceRepositoryUrl = $this.BuildMetadata.RepositoryUrl
                        SourceCommit = (Get-BCAppsReference)
                    }
                }
            }

            if ($EnableCLEANPreProcessorSymbols)
            {
                # set as internal to avoid accidentally copying to DVD
                $this.BuildMetadata.IsInternal = $true
                # defined preprocessorsmbols
                $compilationParams += @{PreProcessorSymbols = Get-CLEANPreprocessorSymbols}
                # edit ruleset
                if ($compilationParams.RuleSetFile -ne '')
                {
                    $compilationParams.RuleSetFile = "$(Get-RulesetsforCLEANsymbolstest -path $compilationParams.RuleSetFile)"
                }
            }

            Compile-ALProject @compilationParams

            $this.SaveBuildArtifacts($DiscardTranslationFiles, $DiscardSourceArchive)
            if ($errorLogPath) {
                Copy-Item $errorLogPath $this.BuildMetadata.ErrorLog
            }
        }
        finally
        {
            $this.TearDownCodeAnalysis($RunStaticCodeAnalysis)
            if (!$this.BuildMetadata.IsGDLProject)
            {
                Remove-Item $this.BuildMetadata.ProjectFolder -Recurse -Force
                $this.BuildMetadata.ProjectFolder = $originalProjectFolder
            }
        }
    }

    hidden [void] ImportTranslationResources([switch] $Translated)
    {
        if (!$Translated -or !$this.BuildMetadata.HasTranslations)
        {
            Write-Log "Skipping importing translations.."
            return
        }

        $appNamesForWhichToImportTranslations = @()

        if ($this.BuildMetadata.IsLanguagePack)
        {
            Write-Log "Importing Base Application translations for language pack."

            $appNamesForWhichToImportTranslations += "Base Application"

            # We make a strong assumption here that all projects are under $env:INETROOT\App\LanguagePacks\${languageCode}
            $languageCodeForPack = Split-Path (Split-Path $this.GetProjectFolder() -Parent) -Leaf
            $matchingCultures = @([System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures) | Where-Object {
                    $_.Name -eq $languageCodeForPack
                })

            if ($matchingCultures.count -eq 0)
            {
                throw "The culture $languageCodeForPack is not a known culture."
            }

            $languageCodes = @($languageCodeForPack)
        }
        elseif ($this.BuildMetadata.IsGDLProject)
        {
            Write-Log "Importing translations for GDL project."

            $appNamesForWhichToImportTranslations += $this.ApplicationName
            $countryCodesForTranslation = Get-CountryCodeForTranslation -CodeBaseCountryCode $this.CountryCode
            Write-Log "The applications using code base $($this.CountryCode) will incorporate translations for the following country codes: $countryCodesForTranslation"

            $languageCodes = @($countryCodesForTranslation | ForEach-Object {
                    $countryCodeForTranslation = $_
                    $navLanguageCodes = Get-CountryCultureCodesForTranslation -CountryCode $countryCodeForTranslation
                    Write-Log "For country code $countryCodeForTranslation we will incorporate the translations for the following NAV language codes $navLanguageCodes"

                    return $navLanguageCodes | Foreach-Object { Get-CountryCulture -CountryCode $_ }
                })
        }
        else
        {
            Write-Log "Importing translations for multi-country project."
            $appNamesForWhichToImportTranslations += $this.ApplicationName
            $translationsNugetLocation = Get-TranslationsLocationFromNuGet
            $languageCodes = @(Get-ChildItem -Path $translationsNugetLocation -Directory -Filter "*-*" | Foreach-Object { $_.Name })
        }

        foreach ($name in $appNamesForWhichToImportTranslations)
        {
            $this.ImportTranslationResourcesForApplication($languageCodes, $name)
        }
    }

    hidden [void] ImportTranslationResourcesForApplication([string[]]$LanguageCodes, [string]$NameOfApplicationForWhichToImportTranslations)
    {
        Write-Log "Importing translation for the following language codes: $LanguageCodes, app: $NameOfApplicationForWhichToImportTranslations"

        # TODO: Modify the Nuget to have a single folder for all the applications
        if ($this.BuildMetadata.IsLanguagePack)
        {
            $translationFolder = $NameOfApplicationForWhichToImportTranslations
        }
        elseif ($this.BuildMetadata.IsGDLProject)
        {
            $translationFolder = $this.BuildMetadata.ApplicationName
        }
        else
        {
            $translationFolder = "ExtensionsV2"
        }

        $applicationTranslationFolder = Join-Path $this.GetProjectFolder() "Translations"
        Initialize-Directory $applicationTranslationFolder -EnforceEmpty $true

        $translationsNugetLocation = Get-TranslationsLocationFromNuGet
        foreach ($languageFolder in @(Get-ChildItem -Path $translationsNugetLocation -Directory -Filter "*-*"))
        {
            $languageCode = $languageFolder.Name
            if ($languageCode -in $languageCodes)
            {
                $folderToSearchForTranslations = Join-Path $languageFolder.FullName "\$translationFolder\*"
                if (!(Test-Path $folderToSearchForTranslations))
                {
                    Write-Log "Failed to find $folderToSearchForTranslations, skipping $languageCode"
                    # Skip this language
                    continue
                }
                Write-Log "Searching for translations in $folderToSearchForTranslations"

                $xliffFileForExtension = Get-ChildItem -Path $folderToSearchForTranslations -Include "$NameOfApplicationForWhichToImportTranslations.$languageCode.xlf"
                Write-Log "Found: $($xliffFileForExtension | % {$_.FullName})"
                foreach ($xliffFile in $xliffFileForExtension)
                {
                    Copy-Item $xliffFile.FullName -Destination $applicationTranslationFolder
                }
            }
        }
    }

    hidden [string[]] SetupCodeAnalysisDependencies([switch] $RunStaticCodeAnalysis, [switch] $StrictMode, [switch] $EnableCLEANPreProcessorSymbols)
    {
        Write-Log "Configuring dependencies for static code analysis"
        if (!$RunStaticCodeAnalysis -or !$this.BuildMetadata.RunStaticCodeAnalysis)
        {
            return @()
        }

        if ($this.BuildMetadata.IsPrivatePreview)
        {
            Write-Log "Breaking Change Validation is disabled for private preview apps."
            return ("AppSourceCop", "CodeCop", "UICop", "PTECop")
        }

        # Should we restore this package outside this?
        Import-Module "$($ENV:INETROOT)\eng/Core\Helpers\ExtensionsV2\GuardingV2ExtensionsHelper.psm1"

        $analyzerList = @("AppSourceCop", "CodeCop", "UICop", "PTECop")
        if ($EnableCLEANPreProcessorSymbols)
        {
            if ($this.BuildMetadata.IsTest) {
                Write-Log "Breaking change validation is disabled for test projects"
                # Not executed in non-clean task because there is no baseline for test projects
                return $analyzerList
            }

            # for clean tasks, point to same version .app file built without preprocessor symbols

            # appversion
            $appManifestFilePath = $this.GetProjectManifestPath();
            $manifest = Get-Content $appManifestFilePath -Raw | ConvertFrom-Json
            $manifest.version = ($this.GetApplicationVersion())

            # Update AppSourceCop.json file in the source folder of the extension $tmpSourceFolder
            Write-Log "Updating AppSourceCop version to $($manifest.version) (app folder: $($this.GetProjectFolder())"

            # Match version from the file name of the baseline .app file
            $package = GetApplicationPackageImpl -ApplicationName $this.ApplicationName -CountryCode $this.CountryCode
            if ($package.Name -match "Microsoft_$([regex]::Escape($this.ApplicationName))_(.*).app") {
                $version = $Matches[1]
            } else {
                $version = $manifest.version
            }

            Write-Log "Updating AppSourceCop version to $version (Expected version: $($manifest.version))"

            # check if this versions of the app exists. If not, update manifest version to be the version that does exist
            Update-AppSourceCopVersion -ExtensionFolder $this.GetProjectFolder() -Version $version -EnableCLEANPreProcessorSymbols:$EnableCLEANPreProcessorSymbols
            return $analyzerList
        }

        $referenceAppsDir = Restore-LazyExtensionsPackage -StrictMode:$StrictMode
        $referenceApplicationPaths = $this.GetReferenceApplicationPathsForCodeAnalysis($referenceAppsDir)
        foreach ($path in $referenceApplicationPaths)
        {
            $appPackageFileName = (Get-Item $path).BaseName
            # Find the version of the reference extension that was restored from NuGet Package
            $referenceAppInfoObj = Get-CompatibleExtensionInfoObj -ExtensionsRefFolder $referenceAppsDir -ExtensionName $appPackageFileName -CountryCode $this.CountryCode

            $referencedVersion = "$($referenceAppInfoObj.Version.Major).$($referenceAppInfoObj.Version.Minor).$($referenceAppInfoObj.Version.Build).$($referenceAppInfoObj.Version.Revision)"

            # Copy Reference extension to Package Cache Folder to be used by the analyzer
            Write-Log "Copying $($appPackageFileName) to $($this.GetPackageCacheFolder())"
            Copy-ReferenceExtensionToPackageCacheFolder -ReferenceAppsDir $referenceAppsDir -ExtensionName $appPackageFileName -CountryCode $this.CountryCode -PackageCacheFolder $this.GetPackageCacheFolder()

            # Update AppSourceCop.json file in the source folder of the extension $tmpSourceFolder
            Write-Log "Updating AppSourceCop version to $($referencedVersion) (app folder: $($this.GetProjectFolder())"
            Update-AppSourceCopVersion -ExtensionFolder $this.GetProjectFolder() -Version $referencedVersion -EnableCLEANPreProcessorSymbols:$EnableCLEANPreProcessorSymbols
        }

        return ("AppSourceCop", "CodeCop", "UICop", "PTECop")
    }

    hidden [void] TearDownCodeAnalysis([switch] $RunStaticCodeAnalysis)
    {
        if (!$RunStaticCodeAnalysis -or !$this.BuildMetadata.RunStaticCodeAnalysis)
        {
            return
        }

        # Should we restore this package outside this?
        Import-Module "$($ENV:INETROOT)\eng/Core\Helpers\ExtensionsV2\GuardingV2ExtensionsHelper.psm1"
        $referenceAppsDir = Get-LazyExtensionsPackagePath

        $referenceApplicationPaths = $this.GetReferenceApplicationPathsForCodeAnalysis($referenceAppsDir)
        foreach ($path in $referenceApplicationPaths)
        {
            $appPackageFileName = (Get-Item $path).Name

            $filePathInSymbolCache = Join-Path $this.GetPackageCacheFolder() $appPackageFileName

            Write-Log "Attempting to remove $filePathInSymbolCache"
            if (Test-Path $filePathInSymbolCache)
            {
                Remove-Item $filePathInSymbolCache
                Write-Log "Removed $filePathInSymbolCache"
            }
        }
    }

    hidden [string[]] GetReferenceApplicationPathsForCodeAnalysis($ReferenceAppsDir)
    {
        # For different reasons, the .app files can be found on the reference package under different names
        # To ensure that we find the reference package, we search for the different potential names
        if (!($this.BuildMetadata.DVDFolder))
        {
            $potentialAppNames = @($this.ApplicationName, "Microsoft_$($this.ApplicationName)_*")
        }
        else
        {
            $potentialAppNames = @((Split-Path $this.BuildMetadata.DVDFolder -Leaf), $this.ApplicationName, "Microsoft_$($this.ApplicationName)_*")
        }

        foreach ($potentialAppName in $potentialAppNames)
        {
            $potentialAppPath = "$ReferenceAppsDir\Extensions\$($this.CountryCode)\$potentialAppName.app"
            Write-Log "Searching for dependency package at location $potentialAppPath" -ForegroundColor Gray

            if (Test-Path -Path $potentialAppPath)
            {
                $potentialAppPath = (Get-Item $potentialAppPath).FullName
                Write-Log "Located reference package: $potentialAppPath"
                return $($potentialAppPath)
                break
            }
        }

        if((-not $this.BuildMetadata.IsTest) -and (-not $this.BuildMetadata.IsLanguagePack)) {
            Write-Log "Failed to locate reference package for app: $($this.ApplicationName)" -ForegroundColor Yellow
        }

        return @()
    }

    hidden [void] SaveLCGTranslationFiles([string] $TranslationsFolder) {
        Write-Log "Save generated translation file to build artifacts folder."

        $translationFiles = Get-ChildItem -Recurse -Filter "$($this.ApplicationName).g.lcg" -Path $TranslationsFolder
        $countOfFiles = ($translationFiles | Measure-Object).Count
        if ($countOfFiles -ne 1)
        {
            Write-Log $translationFiles
            Write-Log "There should be exactly 1 LCG file in Translations folder ""$TranslationsFolder"" but found $countOfFiles. This is expected if it is a new extension." -ForegroundColor Yellow
        }
        else
        {
            Copy-Item $translationFiles[0].FullName -Destination ($this.GetBuildArtifactsFolder())

            # This is a V2 extension so we copy the files directly to the drop
            if (!$this.BuildMetadata.IsMultiCountry -and !$this.BuildMetadata.IsGDLProject)
            {
                CopyLcgTranslationFileToDrop $this.GetProjectFolder() $this.ApplicationName
            }
        }
    }

    hidden [void] SaveBuildArtifacts([switch]$DiscardTranslationFiles, [switch]$DiscardSourceArchive)
    {
        if (!$DiscardTranslationFiles)
        {
            $translationsSourceFolder = Join-Path $this.GetProjectFolder() "Translations"
            $this.SaveLCGTranslationFiles($translationsSourceFolder)
        }

        if (!$DiscardSourceArchive)
        {
            Write-Log "Save archive of source files to build artifacts folder."
            $sourceZipOutputFile = Join-Path $this.GetBuildArtifactsFolder() "$($this.ApplicationName).Source.zip"
            New-AppSourceFileArchive -SourcePath $this.GetProjectFolder() -OutputFile $sourceZipOutputFile
        }
    }

    [string[]] GetAssemblyProbingFolders()
    {
        return $this.BuildMetadata.AssemblyProbingPaths
    }

    [void] SetupApplicationDependencies()
    {
        Write-Log "Copying System packages to the working folder."
        Invoke-RoboCopy (Get-DeveloperToolsFolder) ($this.GetPackageCacheFolder()) -Files *.app -Quiet

        # Stamp the current version into the application's manifest and into the dependencies
        $appManifestFilePath = $this.GetProjectManifestPath();
        $manifest = Get-Content $appManifestFilePath -Raw | ConvertFrom-Json
        if ($manifest.version -ne '$(app_currentVersion)') {
            # Temporary for BCApps
            $manifest.version = ($this.GetApplicationVersion())
        }

        # Add additional information to GDL projects to be able to distinguish two packages
        # with the same name but with different localizations without looking at the source code
        if ($this.BuildMetadata.IsGDLProject)
        {
            if (!$manifest.brief)
            {
                Add-Member -InputObject $manifest -Name "brief" -value "" -MemberType NoteProperty
            }

            $manifest.brief = "$($this.ApplicationName) ($($this.CountryCode))"
        }

        Set-Content -Path $appManifestFilePath -Value (ConvertTo-Json $manifest)

        if ($manifest.application)
        {
            $dependencyPackage = Get-ApplicationPackage -ApplicationName "Application" -CountryCode $this.CountryCode
            $this.CopyDependencyPackageToCache($dependencyPackage)
        }

        # Go through the dependencies of the project that is being built and copy them to the package cache path of the current project.
        foreach ($dependency in $manifest.dependencies)
        {
            # We assume that the dependency name in the manifest will match the name of the project as registered in the projects.json
            $dependencyPackage = Get-ApplicationPackage -ApplicationName $dependency.name -CountryCode $this.CountryCode
            $this.CopyDependencyPackageToCache($dependencyPackage)
        }
    }

    [void] CopyDependencyPackageToCache([string]$PackagePath)
    {
        $targetCache = $this.GetPackageCacheFolder()
        Write-Log "Copying $PackagePath to $targetCache"

        $pathToPackageInCacheFolder = Join-Path $targetCache (Split-Path $PackagePath -Leaf)
        if (!(Test-Path $pathToPackageInCacheFolder))
        {
            Copy-Item $PackagePath $pathToPackageInCacheFolder
        }

        $propagatedDependencies = Get-PropagatedDependenciesFromPackage -PackagePath $PackagePath
        foreach ($propagatedDependency in $propagatedDependencies)
        {
            $appPackage = Get-ApplicationPackage -ApplicationName $propagatedDependency -CountryCode $this.CountryCode
            $this.CopyDependencyPackageToCache($appPackage)
        }
    }

    [void] CopyPrecompiledAppToOutFolders([switch]$EnableCLEANPreProcessorSymbols, [switch]$Translated, [switch]$DiscardTranslationFiles, [switch]$DiscardSourceArchive)
    {
        if ($EnableCLEANPreProcessorSymbols -and $Translated)
        {
            throw "Cannot enable both Translated mode CLEAN mode when using precompiled app."
        }

        $projectFolder = $this.GetProjectFolder()
        Write-Log "Using precompiled app for $($this.ApplicationName) from $projectFolder" -ForegroundColor Magenta

        if ($EnableCLEANPreProcessorSymbols) {
            $buildModeFolder = Join-Path $projectFolder "Clean"
        } elseif ($Translated) {
            $buildModeFolder = Join-Path $projectFolder "Translated"
        } else {
            $buildModeFolder = Join-Path $projectFolder "Default"
        }

        Invoke-RoboCopy ($buildModeFolder) ($this.GetPackageOutputFolder()) -Quiet -Options '/zb' -Files "*$($this.ApplicationName)*.app"

        if (!$DiscardTranslationFiles) {
            $this.SaveLCGTranslationFiles($buildModeFolder)
        }

        if (!$DiscardSourceArchive)
        {
            $sourceCode = Get-ChildItem -Recurse -Filter "SourceCode" -Path $buildModeFolder -Directory
            $sourceZipOutputFile = Join-Path $this.GetBuildArtifactsFolder() "$($this.ApplicationName).Source.zip"
            New-AppSourceFileArchive -SourcePath $sourceCode.FullName -OutputFile $sourceZipOutputFile
        }
    }
}

function CopyLcgTranslationFileToDrop
(
    [Parameter(Mandatory = $true)] [string] $ProjectFolder,
    [Parameter(Mandatory = $true)] [string] $ExtensionName
)
{
    $extensionsTranslationsFolder = Get-ExtensionTranslationArtifactsFolder
    Initialize-Directory $extensionsTranslationsFolder

    $translationsSourceFolder = Join-Path $ProjectFolder Translations

    $countOfFiles = ( Get-ChildItem -Filter *.lcg -Path $translationsSourceFolder | Measure-Object ).Count

    if ($countOfFiles -ne 1)
    {
        throw "There should be exactly 1 LCG file in Translations folder ""$translationsSourceFolder"" but found $countOfFiles"
    }

    Write-Log "Files in $translationsSourceFolder : $(ls $translationsSourceFolder)"

    Get-ChildItem $translationsSourceFolder -Filter *.lcg |
    Foreach-Object {
        $sourceFile = $_.FullName;
        $destinationFile = Join-Path $extensionsTranslationsFolder "$($ExtensionName)$($_.Extension)"

        Write-Log "Source: '$sourceFile', Destination: '$destinationFile'"
        Invoke-RoboCopy $translationsSourceFolder $extensionsTranslationsFolder $_.Name -Options '/zb'

        $fileExistsInTargetLocation = Test-Path $destinationFile

        Write-Log "Does $destinationFile exist: $fileExistsInTargetLocation"
        Write-Log "Files in $extensionsTranslationsFolder : $(ls $extensionsTranslationsFolder)"
    }
}

function Get-AppPropsFile
{
    return "$env:INETROOT\Directory.App.Props.json"
}

function New-AppSourceFileArchive
(
    [string] $SourcePath,
    [string] $OutputFile
)
{
    Write-Log "Create source files archive $OutputFile"
    $propsFile = Get-AppPropsFile
    $tempProps = Join-Path $SourcePath (Split-Path $propsFile -Leaf)
    try {
        Copy-Item $propsFile $tempProps
        Invoke-Zip -OutputFile $OutputFile -Directory $SourcePath
    } finally {
        Remove-Item $tempProps
    }
}

<#
.SYNOPSIS
Build the given application for the given country code.

.PARAMETER CountryCode
The country for which to build the application.

.PARAMETER ApplicationName
The name of the application to build.

.PARAMETER Translated
True if the build process should include translation files into the built application, otherwise false.

.PARAMETER DiscardTranslationFiles
True if the generated translation files should be discarded.

.PARAMETER DiscardSourceArchive
True if the source should not be zipped.

.PARAMETER RunStaticCodeAnalysis
True if code analysis should be ran for the project

.PARAMETER StrictMode
True for HF branches. It changes the baseline for the StaticCodeAnalysis to the last build of the current branch.

.PARAMETER EnableCLEANPreProcessorSymbols
True if the compiler should enable the 'CLEANxx' preprocessorsymbols

.PARAMETER ErrorLog

.PARAMETER LogLevel

#>
function Build-Application(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName,

    [switch] $Translated,

    [switch] $DiscardTranslationFiles,

    [switch] $DiscardSourceArchive,

    [switch] $RunStaticCodeAnalysis,

    [switch] $StrictMode,

    [switch] $EnableCLEANPreProcessorSymbols,

    [string] $ErrorLog,

    [string] $LogLevel,

    [bool] $ForceRebuild = $true
)
{
    Write-Log "Building application $ApplicationName for $CountryCode" -ForegroundColor Magenta

    $configuration = [ApplicationBuildConfiguration]::new($CountryCode, $ApplicationName, $StrictMode)

    if (![string]::IsNullOrEmpty($ErrorLog) -and ![string]::IsNullOrEmpty($LogLevel))
    {
        $configuration.ErrorLog = $ErrorLog
        $configuration.LogLevel = $LogLevel
    }

    if ((-not $ForceRebuild) -and $configuration.IsBuilt())
    {
        return;
    }

    if ($Translated)
    {
        # To build a translated application, the LCL files for this application must be copied in the Translations folder
        # Always discard the produced translation files when building the translated application
        $configuration.BuildProject($configuration.BuildMetadata.HasTranslations, $true, $DiscardSourceArchive, "XLIFF", $RunStaticCodeAnalysis, $false, $EnableCLEANPreProcessorSymbols)
    } else
    {
        # If a project does not have translations, we discard the translation files as they do not provide any value.
        $configuration.BuildProject($false, $DiscardTranslationFiles -or (-not $configuration.BuildMetadata.HasTranslations), $DiscardSourceArchive, "LCG", $RunStaticCodeAnalysis, $StrictMode, $EnableCLEANPreProcessorSymbols)
    }
}

<#
.SYNOPSIS
Get the AL project folder for the given application and country.

.PARAMETER CountryCode
The country code for which to get the project folder

.PARAMETER ApplicationName
The name of the application for which to retrieve the project folder.
#>
function Get-ProjectFolder(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName
)
{
    $configuration = [ApplicationBuildConfiguration]::new($CountryCode, $ApplicationName)
    return ($configuration.GetProjectFolder())
}

<#
.SYNOPSIS
Get the ErrorLog.json path for the given application and country.

.PARAMETER CountryCode
The country code for which to get the path.

.PARAMETER ApplicationName
The name of the application for which to retrieve the path.
#>
function Get-ErrorLogPath(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName
)
{
    $configuration = [ApplicationBuildConfiguration]::new($CountryCode, $ApplicationName)
    return ($configuration.BuildMetadata.ErrorLog)
}

<#
.SYNOPSIS
Get the ErrorLog.json paths for given group and country.

.PARAMETER CountryCode
The country code for which to get the path.

.PARAMETER GroupName
The name of the group as specified in the projects.json.

.PARAMETER SkipTests
Set if the tests in the group should be skipped.
#>
function Get-ErrorLogPathForGroup(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $GroupName,

    [switch] $SkipTests
)
{
    return Get-ApplicationGroup -CountryCode $CountryCode -GroupName $GroupName -SkipTests:$SkipTests | ForEach-Object {
        Get-ErrorLogPath -CountryCode $CountryCode -ApplicationName $_.ApplicationName
    }
}

function Publish-Application
(
    [Parameter(Mandatory = $true)]
    [string] $CountryCode,
    [Parameter(Mandatory = $true)]
    [string] $ApplicationName,
    [Parameter(Mandatory = $true)]
    [string] $ServerInstance
)
{
    $appPackage = Get-ApplicationPackage -CountryCode $CountryCode -ApplicationName $ApplicationName
    Write-Log "Publishing $ApplicationName-$CountryCode app package: $appPackage" -ForegroundColor Magenta
    Publish-NavAppExtensionPackage -Package $appPackage -Server $ServerInstance
}

<#
.SYNOPSIS
Publish, install, and sync the given application to the given server.

.PARAMETER CountryCode
The country code of the localization for which we are installing the application.

.PARAMETER ApplicationName
The name of the application that we are installing.

.PARAMETER ServerInstance
The name of server instance to which we will publish the project.

.PARAMETER Tenant
The tenant to which the projects will be installed. If this is not set, it will be installed for the default tenant.
#>
function Install-Application(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName,

    [Parameter(Mandatory = $true)]
    [string] $ServerInstance,

    [string] $Tenant
)
{
    $appPackage = Get-ApplicationPackage -CountryCode $CountryCode -ApplicationName $ApplicationName

    Write-Log "Installing $ApplicationName-$CountryCode app package: $appPackage" -ForegroundColor Magenta
    Install-AppExtension -AppPackagePath $appPackage -ServerInstance $ServerInstance -Tenant $Tenant
}

<#
.SYNOPSIS
    Uninstall, unpublish and clean the given application from the given server instance.

.PARAMETER CountryCode
The country code of the localization for which we are uninstalling the application.

.PARAMETER ApplicationName
The name of the application that we are uninstalling.

.PARAMETER ServerInstance
The name of server instance to which we will publish the project.

.PARAMETER Tenant
The tenant to which the projects will be uninstalled. If this is not set, it will be uninstalled from the default tenant.
#>
function Uninstall-Application(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName,

    [Parameter(Mandatory = $true)]
    [string] $ServerInstance,

    [string] $Tenant
)
{
    Write-Log "Uninstall $ApplicationName-$CountryCode" -ForegroundColor Magenta
    Uninstall-AppExtension -ApplicationName $ApplicationName -ServerInstance $ServerInstance -Tenant $Tenant
}


<#
.SYNOPSIS
Get the LCG file path generated by the compiler during the build process for the given application and localization.

.DESCRIPTION
When building the application, the compiler generates LCG files for consumption by the translation process. These files
are generated in the Translation subfolder of the project and need to be copied out to the build output so that they can
be passed to the translation pipeline.

.PARAMETER CountryCode
The country code for which to retrieve the LCG file.

.PARAMETER ApplicationName
The application name for which to retrieve the LCG file
#>
function Get-LCGFile(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName
)
{
    $configuration = [ApplicationBuildConfiguration]::new($CountryCode, $ApplicationName)
    $buildArtifacts = $configuration.GetBuildArtifactsFolder()
    if (!(Test-Path $buildArtifacts))
    {
        throw "The build artifacts for $ApplicationName have not been found. Does the current task depend on a task that builds the $ApplicationName"
    }

    $translationFiles = Get-ChildItem -Recurse -Filter *.lcg -Path $buildArtifacts
    $countOfFiles = ($translationFiles | Measure-Object).Count
    if ($countOfFiles -ne 1)
    {
        throw "There should be exactly 1 LCG file in Translations folder ""$buildArtifacts"" but found $countOfFiles"
    }

    return $translationFiles[0].FullName
}

<#
.SYNOPSIS
Get the path to the application package generated during a successful build

.PARAMETER CountryCode
The country code for which to retrieve the application package.

.PARAMETER ApplicationName
The specific application for which to retrieve the package.
#>
function Get-ApplicationPackage(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName,
    [switch] $DoNotThrow
)
{
    $package = GetApplicationPackageImpl -CountryCode $CountryCode -ApplicationName $ApplicationName

    if (!$package)
    {
        if($DoNotThrow)
        {
            Write-Log "Could not find the application package for $ApplicationName" -ForegroundColor Yellow
            return $null
        }
        throw "Could not find the application package for $ApplicationName"
    }

    return $package.FullName
}

function GetApplicationPackageImpl(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName)
{
    $configuration = [ApplicationBuildConfiguration]::new($CountryCode, $ApplicationName)

    # Only get the latest package so that this can be used when setting up the application developer database.
    $package = Get-ChildItem ($configuration.GetPackageOutputFolder()) -Recurse -Filter "Microsoft_$ApplicationName*" |
    Where-Object { $_.Name -match "$([regex]::Escape($ApplicationName))`_\d+\.\d+\.\d+\.\d+" } |
    Sort-Object LastWriteTime |
    Select-Object -Last 1

    return $package
}

function Get-ApplicationIdOfApplicationContainingUserGroupPermissionSet()
{
    return "437dbf0e-84ff-417a-965d-ed2bb9650972"
}

<#
.SYNOPSIS
Test if the given application is installed on the given server instance.
#>
function Test-ApplicationInstalled(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName,

    [Parameter(Mandatory = $true)]
    [string] $ServerInstance)
{
    $numberOfMatchingInstalledApps = (Get-NAVAppExtensionInfo -Server $ServerInstance | Where-Object { $_.Name -eq $ApplicationName } | Measure-Object).Count
    return ($numberOfMatchingInstalledApps -eq 1)
}

<#
.SYNOPSIS
Replaces build version and number and release version macros in codeunit 9015 and 110500.
If onlyDemotool switch is applied it wil only touch codeunit 110500.
.DESCRIPTION
Replaces build version and number and release version macros in codeunit 9015 and 110500.
If onlyDemotool switch is applied it wil only touch codeunit 110500.
The codeunit is compiled after macros expansion.
#>
function ReplaceALNavBuildMacrosInApp
(
    [string] $ApplicationName,
    [string] $CountryCode,
    [string] $SourceFolder
)
{
    if ($ApplicationName -notin @("DemoTool", "Base Application"))
    {
        return;
    }

    Write-Log "Replacing build macros in $SourceFolder for application $ApplicationName"
    Get-ChildItem $SourceFolder -Recurse -Include "DemotoolSystemConstants.Codeunit.al", "ApplicationSystemConstants.Codeunit*.al" |
    ForEach-Object {
        $temporaryCopy = (Get-TempFileName)
        Copy-Item $_.FullName -Destination $temporaryCopy
        Expand-NavBuildMacros -inputFile $temporaryCopy -outputFile $_.FullName -countryCode $CountryCode
    }
}

<#
.SYNOPSIS
Get the path to the zip file containing the application source tree.

.PARAMETER CountryCode
The country code for which to retrieve the path to the zip file.

.PARAMETER ApplicationName
The application name for which to retrieve the path to the zip file.
#>
function Get-SourceArchive(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $ApplicationName
)
{
    $configuration = [ApplicationBuildConfiguration]::new($CountryCode, $ApplicationName)
    $buildArtifacts = $configuration.GetBuildArtifactsFolder()
    if (!(Test-Path $buildArtifacts))
    {
        throw "The build artifacts for $ApplicationName have not been found. Does the current task depend on a task that builds the $ApplicationName"
    }

    $sourceZipFiles = Get-ChildItem -Recurse -Filter "$($configuration.ApplicationName).Source.zip" -Path $buildArtifacts
    $countOfFiles = ($sourceZipFiles | Measure-Object).Count
    if ($countOfFiles -ne 1)
    {
        throw "There should be exactly 1 Source.zip file in the folder ""$buildArtifacts"" but found $countOfFiles"
    }

    return $sourceZipFiles[0].FullName
}

function Test-IsMultiCountryApplication(
    [Parameter(Mandatory = $true)]
    [string] $ApplicationName
)
{
    $configuration = [ApplicationBuildConfiguration]::new("W1", $ApplicationName)
    return $configuration.BuildMetadata.IsMultiCountry
}

<#
.SYNOPSIS
Build the projects in the group with the given name.

.PARAMETER CountryCode
The country code for which to build the given group. This can affect the projects that are included as part of the group.

.PARAMETER GroupName
The name of the group as specified in the projects.json

.PARAMETER Translated
Set if the projects in the group should be translated for the given locale.

.PARAMETER DiscardTranslationFiles
Set if the generated translation files should be discarded after the build is completed.

.PARAMETER DiscardSourceArchive
Set if the source archives for the individual projects should be discarded.

.PARAMETER RunStaticCodeAnalysis
Set if static code analysis should be run in addition to the standard compiler.

.PARAMETER SkipTests
Set if the tests in the group should be skipped.

.PARAMETER StrictMode
True for HF branches. It changes the baseline for the StaticCodeAnalysis to the last build of the current branch.

.PARAMETER EnableCLEANPreProcessorSymbols
True if the compiler should enable the 'CLEANxx' preprocessorsymbols

#>
function Build-ApplicationGroup(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $GroupName,

    [switch] $Translated,

    [switch] $DiscardTranslationFiles,

    [switch] $DiscardSourceArchive,

    [switch] $RunStaticCodeAnalysis,

    [switch] $SkipTests,

    [switch] $StrictMode,

    [switch] $EnableCLEANPreProcessorSymbols,

    [switch] $ForceRebuild
)
{
    if ($Translated)
    {
        Restore-TranslationsNuGet
    }

    [BuildMetadataProvider]::GetApplicationGroup($CountryCode, $GroupName, $SkipTests, $false, $false).Applications | ForEach-Object {
        [BuildMetadata] $project = $_.BuildMetadata

        $projectConfiguration = [ApplicationBuildConfiguration]::new($CountryCode, $project.ApplicationName, $StrictMode)
        if (!$projectConfiguration.IsBuilt() -or $ForceRebuild)
        {
            Write-Host "Building application $($project.ApplicationName). CountryCode: $CountryCode, ForceRebuild: $ForceRebuild"
            Build-Application -CountryCode $CountryCode -ApplicationName $project.ApplicationName -Translated:$Translated -DiscardTranslationFiles:$DiscardTranslationFiles -DiscardSourceArchive:$DiscardSourceArchive -RunStaticCodeAnalysis:$RunStaticCodeAnalysis -StrictMode:$StrictMode -EnableCLEANPreProcessorSymbols:$EnableCLEANPreProcessorSymbols -ForceRebuild:$ForceRebuild
        }
        else
        {
            Write-Log "Application $($project.ApplicationName) is already built, skipping build. CountryCode: $CountryCode, ForceRebuild: $ForceRebuild"
        }
    }
}

<#
.SYNOPSIS
Publish, sync, and install all the applications in the given group for the given country code

.PARAMETER CountryCode
The country code for which to build the given group. This can affect the projects that are included as part of the group.

.PARAMETER GroupName
The name of the group as specified in the projects.json

.PARAMETER ServerInstance
The name of the server instance to which to publish the given packages.

.PARAMETER Language
The language to use for installing the given packages.

.PARAMETER Tenant
The tenant for which to install the packages.

.PARAMETER SkipTests
Set if the tests in the group should be skipped.

.PARAMETER ForceInstall
Set if all applications should be installed
#>
function Install-ApplicationGroup(
    [string] $CountryCode = "WW",

    [Parameter(Mandatory = $true)]
    [string] $GroupName,

    [Parameter(Mandatory = $true)]
    [string] $ServerInstance,

    [string] $Language,

    [string] $Tenant,

    [switch] $SkipTests,

    [switch] $ForceInstall,

    [switch] $SkipLanguagePacks,

    [string[]] $SkipApplications = @()
)
{
    PublishInstallInternal -CountryCode $CountryCode -GroupName $GroupName -ServerInstance $ServerInstance `
            -Language $Language -Tenant $Tenant -ForceInstall:$ForceInstall `
            -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks -SkipApplications $SkipApplications
}

function Publish-ApplicationGroup(
    [string] $CountryCode = "WW",
    [Parameter(Mandatory = $true)]
    [string] $GroupName,
    [Parameter(Mandatory = $true)]
    [string] $ServerInstance,
    [switch] $SkipTests,
    [switch] $SkipLanguagePacks
)
{
    PublishInstallInternal -CountryCode $CountryCode -GroupName $GroupName -ServerInstance $ServerInstance `
            -PublishOnly -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks
}

function PublishInstallInternal
(
    [Parameter(Mandatory = $true)]
    [string] $CountryCode,
    [Parameter(Mandatory = $true)]
    [string] $GroupName,
    [Parameter(Mandatory = $true)]
    [string] $ServerInstance,
    [Parameter(Mandatory=$true,ParameterSetName='PublishOnly')]
    [switch] $PublishOnly,
    [Parameter(ParameterSetName='PublishAndInstall')]
    [string] $Language,
    [Parameter(ParameterSetName='PublishAndInstall')]
    [string] $Tenant,
    [Parameter(ParameterSetName='PublishAndInstall')]
    [switch] $ForceInstall,

    [switch] $SkipTests,
    [switch] $SkipLanguagePacks,
    [string[]] $SkipApplications = @()
)
{
    $action = if ($PublishOnly) { "Publishing" } else { "Installing" }
    Write-Log "$action application group $GroupName for country $CountryCode"

    # Get the name of all the apps that are already published to the server so that we can skip publishing them.
    $publishedAppsNames = Get-NAVAppExtensionInfo -Server $ServerInstance | ForEach-Object { $_.Name }
    [BuildMetadataProvider]::GetApplicationGroup($CountryCode, $GroupName, $SkipTests, $SkipLanguagePacks, $false).Applications | ForEach-Object {
        [BuildMetadata] $project = $_.BuildMetadata

        Write-Log "Evaluating $($project.ApplicationName) for publishing"
        
        # Check if this application should be skipped
        if($SkipApplications.Count -gt 0)
        {
            if ($project.ApplicationName -in $SkipApplications)
            {
                Write-Log "$($project.ApplicationName) is in the skip list. Skipping publish" -ForegroundColor Yellow
                return
            }
        }

        $configuration = [ApplicationBuildConfiguration]::new($CountryCode, $project.ApplicationName)

        # If the application is published, we assume it is also synchronized and installed.
        if ($configuration.ApplicationName -in $publishedAppsNames)
        {
            Write-Log "$($configuration.ApplicationName) is already published. Skipping.." -ForegroundColor Yellow
            return
        }

        if (!$configuration.IsBuilt())
        {
            throw "The package for $($project.ApplicationName) was not found. Has it been built?"
        }

        $appPackage = Get-ApplicationPackage -CountryCode $configuration.CountryCode -ApplicationName $configuration.ApplicationName

        Publish-NavAppExtensionPackage -Package $appPackage -Server $ServerInstance

        if ($PublishOnly)
        {
            return;
        }

        if ($project.DoNotInstall -and !$ForceInstall)
        {
            Write-Log "$($project.ApplicationName) is not marked for install. Skiping installation.." -ForegroundColor Yellow
            return;
        }

        Sync-NavAppExtensionPackage -Package $appPackage -Server $ServerInstance -Tenant $Tenant
        Install-NavAppExtensionPackage -Package $appPackage -Server $ServerInstance -Language $Language -Tenant $Tenant
    }
}

function Get-PropagatedDependenciesFromPackage([string] $PackagePath)
{
    $binFolder = "$env:INET_ALDEVENV\bin\win32"
    $altoolPath = Join-Path $binFolder "altool.exe"

    $manifestFile = & $altoolPath GetPackageManifest "$PackagePath" | ConvertFrom-Json
    $dependencies = @()
    if ($manifestFile.propagateDependencies)
    {
        foreach ($dependency in $manifestFile.Dependencies)
        {
            $dependencies += $dependency.Name;
        }
    }

    return $dependencies
}

<#
.SYNOPSIS
Read the id, name, publisher, and version of the given package from the package and return it as a PSObject.

.PARAMETER PackagePath
The path to the .app file representing the package to read.

#>
function Get-ApplicationMetadataFromPackage([string]$PackagePath)
{
    Write-Log "Getting Application Metadata from: $($PackagePath)"

    $binFolder = "$env:INET_ALDEVENV\bin\win32"
    Write-Log "Using altool from $binFolder"
    $altoolPath = Join-Path $binFolder "altool.exe"

    $manifestFile = & $altoolPath GetPackageManifest "$($PackagePath)" | ConvertFrom-Json

    # Read information of Extension from Manifest.xml
    $appId = $manifestFile.id
    $appName = $manifestFile.name
    $appPublisher = $manifestFile.publisher
    $appVersion = [version]$manifestFile.version

    Write-Log "AppID: $($appID), App Name: $($appName), app publisher: $($appPublisher), app version: $($appVersion)"
    $ReturnedExtInfo = New-Object PSObject -Property @{id = $appId; name = $appName ; publisher = $appPublisher ; version = $appVersion }
    return $ReturnedExtInfo
}

<#
.SYNOPSIS
Get the build metadata for the projects that are part of the given group.
This is a low-level method for working with individual projects.

.PARAMETER CountryCode
The country code for which to retrieve the group.

.PARAMETER GroupName
The name of the group as specified in the projects.json

.PARAMETER SkipTests
Set if the tests in the group should be skipped.

.PARAMETER SkipLanguagePacks
Set if the language packs in the group should be skipped.

.PARAMETER SkipCountryCheck
Set if the country check should be skipped.
#>
function Get-ApplicationGroup
(
    [Parameter(Mandatory = $true)]
    [string] $GroupName,
    [Parameter(ParameterSetName = 'CountryCode')]
    [string] $CountryCode = "WW",
    [switch] $SkipTests,
    [switch] $SkipLanguagePacks,
    [Parameter(ParameterSetName = 'NoCountryCode')]
    [switch] $SkipCountryCheck
)
{
    return [BuildMetadataProvider]::GetApplicationGroup($CountryCode, $GroupName, $SkipTests, $SkipLanguagePacks, $SkipCountryCheck).Applications | ForEach-Object {
        $_.BuildMetadata
    }
}

<#
.SYNOPSIS
Gets the applications for the SaaS solution.

.DESCRIPTION
This function gets the applications for the SaaS solution.
It gets the applications in the group "Financials" and adds the applications in the group "LocalBaseExtensions" just after the "Application" application.

.PARAMETER CountryCode
The country code for which to retrieve the applications.

.PARAMETER SkipTests
Set if the tests in the group should be skipped.

.PARAMETER SkipLanguagePacks
Set if the language packs in the group should be skipped.

.PARAMETER SkipCountryCheck
Set if the country check should be skipped. This is useful when getting all the applications for a SaaS solution.
#>
function Get-SaaSApplications
(
    [Parameter(ParameterSetName = 'CountryCode')]
    [string] $CountryCode = "WW",
    [switch] $SkipTests,
    [switch] $SkipLanguagePacks,
    [Parameter(ParameterSetName = 'NoCountryCode')]
    [switch] $SkipCountryCheck
)
{
    if($PSCmdlet.ParameterSetName -eq 'CountryCode')
    {
        Write-Log "Getting SaaS applications for country code $CountryCode"
        $saasApps = Get-ApplicationGroup -CountryCode $CountryCode -GroupName "Financials" -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks
    }
    else
    {
        Write-Log "Getting SaaS applications for all countries"
        $saasApps = Get-ApplicationGroup -GroupName "Financials" -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks -SkipCountryCheck
    }

    $application = $saasApps | Where-Object ApplicationName -eq "Application"
    if ($application)
    {
        # Application is in the group. Add all the apps for LocalBaseExtensions just after Application.
        # It's important that apps from LocalBaseExtensions are just after Application, because other 1st party apps may depend on them.

        $appIndex = $saasApps.IndexOf($application)

        $applicationsBefore = $saasApps | Select-Object -First $($appIndex + 1) # include Application
        $applicationsAfter = $saasApps | Select-Object -Skip $($appIndex + 1) # exclude Application

        if($PSCmdlet.ParameterSetName -eq 'CountryCode')
        {
            $localBaseExtensions = Get-ApplicationGroup -CountryCode $CountryCode -GroupName "LocalBaseExtensions" -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks
        }
        else
        {
            $localBaseExtensions = Get-ApplicationGroup -GroupName "LocalBaseExtensions" -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks -SkipCountryCheck
        }

        # Order the apps so that LocalBaseExtensions are just after Application
        $saasApps = $applicationsBefore + $localBaseExtensions + $applicationsAfter
    }

    return $saasApps
}

<#
.SYNOPSIS
Get the name of the solution matching the legacy extension group name.
#>
function Get-GroupNameForDacpacType([string] $ApplicationType)
{
    switch ($ApplicationType)
    {
        "financials" { return "Financials" }
        "onprem" { return "OnPrem" }
        "system" { return "System Solution" }
        default { throw "Unknown application type $ApplicationType" }
    }
}

function CopyArtifactsToFolder([string]$CountryCode, [string]$ApplicationName, [string] $TargetFolder)
{
    if (!(Test-Path $TargetFolder))
    {
        Initialize-Directory $TargetFolder
    }

    Write-Log "Copying artifacts for '$ApplicationName' to $TargetFolder"

    $appPackagePath = Get-ApplicationPackage -CountryCode $CountryCode -ApplicationName $ApplicationName
    $appFileName = (Get-Item $appPackagePath).Name -replace "_\d+\.\d+\.\d+\.\d+", ""
    Copy-Item $appPackagePath "$folder\$appFileName"

    $sourceArchivePath = Get-SourceArchive -CountryCode $CountryCode -ApplicationName $ApplicationName
    Copy-Item $sourceArchivePath $folder
}

<#
.SYNOPSIS
Get the OnPrem applications for the given country code or all countries if no country code is specified.
.DESCRIPTION
This function retrieves the OnPrem applications for the specified country code or all countries if no country code is provided.
.PARAMETER CountryCode
The country code for which to retrieve the OnPrem applications. Default is "WW" (all countries).
.PARAMETER SkipTests
Set if the tests in the group should be skipped.
.PARAMETER SkipLanguagePacks
Set if the language packs in the group should be skipped.
.PARAMETER SkipCountryCheck
Set if the country check should be skipped. This is useful when getting all the applications for a SaaS solution.
#>
function Get-OnPremApplications
(
    [Parameter(ParameterSetName = 'CountryCode')]
    [string] $CountryCode = "WW",
    [switch] $SkipTests,
    [switch] $SkipLanguagePacks,
    [Parameter(ParameterSetName = 'NoCountryCode')]
    [switch] $SkipCountryCheck
)
{
    if ($PSCmdlet.ParameterSetName -eq 'CountryCode')
    {
        Write-Log "Getting OnPrem applications for country code $CountryCode"
        $onpremApps = (Get-ApplicationGroup -CountryCode $countryCode -GroupName "OnPrem" -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks)
        $onpremApps += (Get-ApplicationGroup -CountryCode $countryCode -GroupName "LocalBaseExtensions" -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks)
    }
    else
    {
        Write-Log "Getting OnPrem applications for all countries"
        $onpremApps = (Get-ApplicationGroup -GroupName "OnPrem" -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks -SkipCountryCheck)
        $onpremApps += (Get-ApplicationGroup -GroupName "LocalBaseExtensions" -SkipTests:$SkipTests -SkipLanguagePacks:$SkipLanguagePacks -SkipCountryCheck)
    }
    return $onpremApps
}

function Copy-ApplicationsToDVD
(
    [string] $DVDPath,
    [string] $CountryCode
)
{
    $applicationsFolder = Join-Path $DVDPath "Applications"
    Initialize-Directory $applicationsFolder

    # Copy all the tests for the Base Application to the same folder.
    $applicationsOnTheDVD = @()

    $allApplicationsToCopy = Get-OnPremApplications -CountryCode $countryCode

    Write-Log "Copying non-test applications to the DVD"

    # Copy all the non-test applications to the DVD from the OnPrem group
    $allApplicationsToCopy |
    Where-Object { !$_.IsInternal -and !$_.IsTest } |
    ForEach-Object {
        $folder = $null
        $applicationName = $_.ApplicationName
        Write-Log $_
        if ($_.DVDFolder)
        {
            $folder = (Join-Path $DVDPath $_.DVDFolder)
        }
        else
        {
            $folder = (Join-Path $applicationsFolder "$applicationName\Source")
        }

        CopyArtifactsToFolder -CountryCode $countryCode -ApplicationName $applicationName -TargetFolder $folder
        $applicationsOnTheDVD += $applicationName
    }

    Write-Log "Copying test applications to the DVD"
    $allApplicationsToCopy |
    Where-Object { !$_.IsInternal -and ($_.ApplicationName -notin $applicationsOnTheDVD) } |
    ForEach-Object {
        Write-Log $_
        $folder = $null
        $testApplicationName = $_.ApplicationName
        if ($_.DVDFolder)
        {
            $folder = (Join-Path $DVDPath $_.DVDFolder)
        }
        else
        {
            $sourceApplicationName = $applicationsOnTheDVD | Where-Object {
                $testApplicationName.StartsWith($_) -and (($testApplicationName -like "*Test") -or ($testApplicationName -like "*Tests"))
            }

            if ($sourceApplicationName)
            {
                # If we find a matching application, we put the artifacts in the Test folder of the application
                $folder = (Join-Path $applicationsFolder "$sourceApplicationName\Test")
            }
            else
            {
                $folder = (Join-Path $applicationsFolder "$testApplicationName\Source")
            }
        }

        CopyArtifactsToFolder -CountryCode $countryCode -ApplicationName $testApplicationName -TargetFolder $folder
        $applicationsOnTheDVD += $testApplicationName
    }
}

<#
.SYNOPSIS
Builds a string of CLEANxx preprocessor symbols from v15 to current to be passed to the .al compiler.
#>
function Get-CLEANPreprocessorSymbols()
{
    $stem = 'CLEAN'
    $version = 15

    $preprocessorsymbols = $stem + $version.ToString()
    for ($version++ ;$version -le [int]$(Get-CurrentBuildVersionFromMaster); $version++)
    {
        $preprocessorsymbols += ';' + $stem + $version.ToString()
    }
    return $preprocessorsymbols
}

<#
.SYNOPSIS
Copies a ruleset and all includes ruleset files.
.DESCRIPTION
Copies a ruleset and all includes ruleset files to a destination folder.
The paths to included rulesets are updated to the new location.
#>
function CopyRulesetWithIncludedRulesets([string] $SourcePath, [string] $DestinationFolder)
{
    # mkdir
    if (!(test-path $DestinationFolder -PathType Container))
    {
        mkdir $DestinationFolder
    }

    $CurrRuleset = "$([system.io.path]::GetFullPath("$DestinationFolder\$([system.io.path]::GetFileName($SourcePath))"))"
    Copy-Item -Path $SourcePath -Destination $CurrRuleset -Force

    # handle included ruleset(s)
    $json = ConvertFrom-Json -InputObject (get-content -Path $CurrRuleset -Raw)
    foreach ($rs in $json.includedRuleSets)
    {
        $includedRsSourcePath = $([system.io.path]::GetFullPath("$([system.io.path]::GetDirectoryName($SourcePath))/$($rs.path)"))
        $rulesetName = $([system.io.path]::GetFileName($includedRsSourcePath))

        # Update the path to the included ruleset
        $rs.path = "./$rulesetName"

        CopyRulesetWithIncludedRulesets -SourcePath $includedRsSourcePath -DestinationFolder $DestinationFolder
    }
    Set-Content -Value (ConvertTo-Json -InputObject $json) -Path $CurrRuleset -Force
}

<#
.SYNOPSIS
Copies a ruleset file and creates a temp copy to enable breaking changes rules when testing with 'CLEANxx' preprocessor symbols
#>
function Get-RulesetsforCLEANsymbolstest
{
    param
    (
        [parameter(Mandatory=$true)] [string] $path
    )

    if (!(test-path $path -PathType Leaf))
    {
        Write-Error "$path must be a file"
    }

    if (!([system.io.path]::IsPathRooted($path)))
    {
        $path = "$env:INETROOT\$path"
    }
    $ruleset = "$env:INETROOT\Logs\$([system.io.path]::GetFileName($path))"

    # handle included ruleset(s)
    CopyRulesetWithIncludedRulesets -SourcePath $([system.io.path]::GetFullPath($path)) -DestinationFolder "$env:INETROOT\Logs\"

    $rulesToEnforce = @(
        'AS0105', # Object pending obsoletion contains an expired ObsoleteTag

        # 2022 release wave 2
        'AL0660', # Property cannot be customized.
        'AL0677', # Member cannot be declared as protected.
        'AL0697', # Argument should be a valid field type.
        'AL0715',  # Some names like Promoted are reserved for future AL language features.

        # 2023 release wave 1
        'AL0711' # Prevent duplicate cue actions.
    )

    $json = ConvertFrom-Json -InputObject (get-content -Path $ruleset -Raw)
    $rules = @()

    foreach ($rule in $json.rules)
    {
        $rules += ,$rule
    }

    foreach($ruleToEnforce in $rulesToEnforce)
    {
        $index = $rules.id.IndexOf($ruleToEnforce)

        if ($index -ne -1)
        {
            $rules[$index].action = 'Error'
        }
        else
        {
            $rules +=,@{'id' = $ruleToEnforce; 'action' = 'Error'; 'justification' = 'Enforced for CLEANxx test run'}
        }
    }

    $json.rules = $rules
    Set-Content -Value (ConvertTo-Json -InputObject $json) -Path $ruleset -Force

    Write-Log "CLEAN ruleset: $ruleset"
    return $ruleset
}

Export-ModuleMember -Function "Build-Application"
Export-ModuleMember -Function "Build-ApplicationGroup"
Export-ModuleMember -Function "Get-ApplicationIdOfApplicationContainingUserGroupPermissionSet"
Export-ModuleMember -Function "Get-ApplicationMetadataFromPackage"
Export-ModuleMember -Function "Get-AppPropsFile"
Export-ModuleMember -Function "Get-PropagatedDependenciesFromPackage"
Export-ModuleMember -Function "Get-ApplicationPackage"
Export-ModuleMember -Function "Get-LCGFile"
Export-ModuleMember -Function "Get-ProjectFolder"
Export-ModuleMember -Function "Get-ApplicationGroup"
Export-ModuleMember -Function "Get-SaaSApplications"
Export-ModuleMember -Function "Get-OnPremApplications"
Export-ModuleMember -Function "Get-GroupNameForDacpacType"
Export-ModuleMember -Function "Get-SourceArchive"
Export-ModuleMember -Function "Install-Application"
Export-ModuleMember -Function "Install-ApplicationGroup"
Export-ModuleMember -Function "Publish-Application"
Export-ModuleMember -Function "Publish-ApplicationGroup"
Export-ModuleMember -Function "Test-ApplicationInstalled"
Export-ModuleMember -Function "Test-IsMultiCountryApplication"
Export-ModuleMember -Function "Uninstall-Application"
Export-ModuleMember -Function "Copy-ApplicationsToDVD"
Export-ModuleMember -Function "Get-ErrorLogPath"
Export-ModuleMember -Function "Get-ErrorLogPathForGroup"
Export-ModuleMember -Function "Get-CLEANPreprocessorSymbols"
Export-ModuleMember -Function "Get-RulesetsforCLEANsymbolstest"