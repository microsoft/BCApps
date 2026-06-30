Import-Module "$PSScriptRoot/GDLDevelopmentHelpers.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot/../../Shared/Logger.psm1" -DisableNameChecking

<#
.SYNOPSIS
Get the list of file patterns to exclude from the GDL synchronization process.
#>
function GetFilePatternsExcludedFromGDLSync()
{
    return @(GetViewInfoFiles) + @("*.app", "rad.json", "settings.json", "launch.json", "*.lcl", "*.lcg", "view_files.json")
}

<#
.SYNOPSIS
Remove the base folder prefix from the given file path.

.PARAMETER BaseFolder
The base path to remove.

.PARAMETER FileInBaseFolder
The full path of the file in the folder.
#>
function RemoveBasePrefix([string]$BaseFolder, [string]$FileInBaseFolder)
{
    if (!$FileInBaseFolder.StartsWith($BaseFolder))
    {
        throw "$FileInBaseFolder is not a file in the $BaseFolder."
    }

    $relativePath = $FileInBaseFolder.Replace($BaseFolder, "")
    if ($relativePath.StartsWith("\"))
    {
        $relativePath = $relativePath.Substring(1)
    }

    return $relativePath
}

class FileOperationsHelper
{
    hidden $createdDirectories

    FileOperationsHelper()
    {
        $this.createdDirectories = @{}
    }

    CopyFile([string]$SourcePath, [string]$TargetPath)
    {
        $parentDirectory = [System.IO.Path]::GetDirectoryName($TargetPath);
        if((-not $this.createdDirectories.ContainsKey($parentDirectory)) -and (-not (Test-Path $parentDirectory)))
        {
            $null = mkdir $parentDirectory -Force
            $this.createdDirectories.Add($parentDirectory, $parentDirectory);
        }

        $null = Copy-Item -Path $SourcePath -Destination $TargetPath -Force
    }

    CreateSymbolicLink([string]$SourcePath, [string]$TargetPath)
    {
        $parentDirectory = [System.IO.Path]::GetDirectoryName($TargetPath);
        if((-not $this.createdDirectories.ContainsKey($parentDirectory)) -and (-not (Test-Path $parentDirectory)))
        {
            $null = mkdir $parentDirectory -Force
            $this.createdDirectories.Add($parentDirectory, $parentDirectory);
        }

        $null = New-Item -Path $TargetPath -ItemType SymbolicLink -Value $SourcePath -Force
    }


    [bool] TryCopyFile([string] $FilePathPattern, [string] $TargetDirectory)
    {
        Write-Log "Searching for $FilePathPattern"

        if(Test-Path $FilePathPattern)
        {
            $file = Get-ChildItem $FilePathPattern
            Write-Log "Copying $file to $TargetDirectory"
            $this.CopyFile($file.FullName, $TargetDirectory)
            return $true
        }

        return $false
    }
}

class GDLViewConfiguration
{
    [string]$ViewRootFolder
    [string]$LayersRootFolder
    [string]$CountryCode

    hidden [string[]] $layerNames

    GDLViewConfiguration([string]$CountryCode)
    {
        $this.CountryCode = $CountryCode
        $this.ViewRootFolder = GetViewFolder -CountryCode $CountryCode
        $this.LayersRootFolder = (GetLayersRootFolder)
    }

    # Is this the W1 view/layer which is the base for all other layers?
    # We treat this in a special manner because it contains the largest amount of files
    # and we try to avoid copying/creating symbolic links for all of them
    [bool] IsBaseView()
    {
        return $this.CountryCode -eq "W1"
    }

    # Assert that the view does not contain any unsynchronized changes.
    [void] AssertIsClean()
    {
        $viewFolderPath = $this.ViewRootFolder
        $filesInView = Get-ChildItem -Path $viewFolderPath -File -Recurse -Exclude (GetFilePatternsExcludedFromGDLSync)
        if (!$filesInView)
        {
            return
        }

        # If this is the base view, we have created a symbolic link to the whole folder so all the files are real files and there is nothing to check
        if (!$this.IsBaseView())
        {
            $realFilesInView = $filesInView | Where-Object { $_.LinkType -ne "SymbolicLink" }

            if ($realFilesInView.Count -gt 0)
            {
                Write-Log "$($realFilesInView.Count) unsynchronized files exist in $viewFolderPath :"
                $realFilesInView | ForEach-Object { Write-Log $_.FullName }

                throw "The GDL view in $viewFolderPath must be synchronized. Run 'Sync-GDLView -CountryCode $($this.CountryCode)' and resolve any conflicts. Alternatively, use the 'Remove-GDLView -CountryCode $($this.CountryCode) -Force' command to discard all files."
            }
        }

        [System.Collections.IDictionary] $itemsMovedOrRemovedInView = $this.GetItemsInViewMappingWithoutViewRepresentation($filesInView)
        if ($itemsMovedOrRemovedInView.Count -gt 0)
        {
            Write-Log "$($itemsMovedOrRemovedInView.Count) unsynchronized files exist in $viewFolderPath :"
            $itemsMovedOrRemovedInView.Keys | ForEach-Object { Write-Log $_ }
            throw "The GDL view in $viewFolderPath must be synchronized. Run 'Sync-GDLView -CountryCode $($this.CountryCode) -SyncMovesAndDeletes' and resolve any conflicts. Alternatively, use the 'Remove-GDLView -CountryCode $($this.CountryCode) -Force' command to discard all files."
        }
    }

    # Create a view from the underlying layers and optionally materialize it on disk by copying all the files.
    # Exclude can contain the name of the top level folders in the layers that should be excluded from the view.
    [void] CreateViewFromLayers([bool]$MaterializeView, [string[]] $Exclude)
    {
        $newViewMapping = $this.GetNewViewMapping($Exclude)
        if ($this.IsBaseView())
        {
            $this.CreateBaseView($MaterializeView, $Exclude)
        }
        else
        {
            $existingViewMapping = $this.GetExistingViewMapping()
            $this.MergeViewMappings($existingViewMapping, $newViewMapping, $MaterializeView)
        }

        $viewSummaryFilePath = GetViewSummaryFile -CountryCode $this.CountryCode
        $newViewMapping | ConvertTo-Json | Set-Content -Path $viewSummaryFilePath
    }

    # Create the view for the base country, W1.
    # Exclude can contain the name of the top level folders in the layers that should be excluded from the view.
    [void] CreateBaseView([bool] $MaterializeView, [string[]] $Exclude)
    {
        if (!(Test-Path $this.ViewRootFolder))
        {
            $sourceLayerFolder = GetLayerFolder -CountryCode $this.CountryCode
            if ($MaterializeView)
            {
                Write-Log "Creating copy of $sourceLayerFolder to $($this.ViewRootFolder)"
                Invoke-RoboCopy -Source $sourceLayerFolder -Destination ($this.ViewRootFolder) -Recursive -Quiet -Options (@("/XD") + $Exclude)

            }
            else
            {
                Write-Log "Creating link from $sourceLayerFolder to $($this.ViewRootFolder)"
                $null = New-Item -Path ($this.ViewRootFolder) -ItemType Junction -Value $sourceLayerFolder -Force
            }
        }
    }

    # Copy any new files from the view to the layer.
    [void] SynchronizeFromViewToLayers([switch]$SyncMovesAndDeletes)
    {
        $filesInView = Get-ChildItem -Path ($this.ViewRootFolder) -File -Recurse -Exclude (GetFilePatternsExcludedFromGDLSync)

        if ($SyncMovesAndDeletes)
        {
            $this.SynchronizeFilesMovedInView($filesInView);
        }

        # The base view is special because it is not created using symbolic links for each file
        # but with a symbolic link for the entire folder.
        # This means that we do not have to push any changes from the view to the layer.
        if (!$this.IsBaseView())
        {
            $this.RemoveDanglingLinksFromView($filesInView)
        }

        $this.UpdateLayerWithNewFilesFromView($filesInView)
    }

    hidden [void] SynchronizeFilesMovedInView([System.IO.FileInfo[]] $filesInView)
    {
        # Get the list of files that are present in the view mapping, but not present in the view.
        [System.Collections.IDictionary] $itemsMovedOrRemovedInView = $this.GetItemsInViewMappingWithoutViewRepresentation($filesInView)
        if ($itemsMovedOrRemovedInView.Count -eq 0)
        {
            return;
        }

        # A dictionary of <fileName, relativePathInView> items that will be used to detect if a file was moved.
        $fileNameToPathInView = New-Object 'System.Collections.Generic.Dictionary[[string], [string]]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase);
        $filesInView | ForEach-Object {
            $pathInView = RemoveBasePrefix -BaseFolder $this.ViewRootFolder -FileInBaseFolder $_.FullName
            $fileNameToPathInView[$_.Name] = $pathInView
        }

        # Try to remove the files from the layers while making sure to update the view_files.json
        $filesExcludedFromView = $this.GetFilesExcludedFromView($this.CountryCode)

        foreach ($oldPathInView in $itemsMovedOrRemovedInView.Keys)
        {
            $oldPathInLayer = $itemsMovedOrRemovedInView[$oldPathInView]
            $fileName = [System.IO.Path]::GetFileName($oldPathInLayer)
            [string]$newRelativePathInLayer = $null;

            # If the file is still present in the view but under a different path it means it has been moved.
            # We will try to move the file in the layer so that it is under the same location.
            if ($fileNameToPathInView.TryGetValue($fileName, [ref]$newRelativePathInLayer))
            {
                $this.TryMoveFileInLayer($oldPathInLayer, $newRelativePathInLayer)
            }
            else
            {
                $this.TryRemoveFileFromLayer($oldPathInView, $oldPathInLayer, $filesExcludedFromView)
            }
        }

        $this.SetFilesExcludedFromView($this.CountryCode, $filesExcludedFromView)
    }

    # Given the full path of the file in the source layer and the new relative path try to move the file in the layer
    # If the source layer is the same as the top layer for the view, the move is done directly.
    # If the source layer is different from the top layer for the view, the user is prompted for the move.
    hidden [void] TryMoveFileInLayer([string] $OldFullPathInLayer, [string] $NewRelativePathInLayer)
    {
        # If the old path does not exist, the file has already been moved.
        $layersRoot = GetLayersRootFolder
        if ($OldFullPathInLayer.StartsWith($layersRoot))
        {
            $relativeFilePath = RemoveBasePrefix -BaseFolder $layersRoot -FileInBaseFolder $OldFullPathInLayer
        }
        else
        {
            throw "$OldFullPathInLayer is not part of any known GDL layer."
        }

        $sourceLayerOfFile = $relativeFilePath.Substring(0, $relativeFilePath.IndexOf('\'))
        $relativePathInView = RemoveBasePrefix -BaseFolder  (GetLayerFolder -CountryCode $sourceLayerOfFile) $OldFullPathInLayer

        # The file is present in multiple layers and we need to propagate the move to all layers.
        $layers = GetAllLayers
        foreach ($layer in $layers)
        {
            # If the file is present in this layer, we replicate the move.
            $pathInLayer = Join-Path (GetLayerFolder -CountryCode $layer) $relativePathInView
            if (Test-Path $pathInLayer)
            {
                $newFullPathInLayer = Join-Path (GetLayerFolder -CountryCode $layer) $NewRelativePathInLayer
                New-Item -ItemType File -Path $newFullPathInLayer -Force
                Move-Item -Path $pathInLayer -Destination $newFullPathInLayer -Force
            }

            # If the file is excluded from the view made from this layer, we update the path in the exclusion file.
            $filesExcludedFromView = $this.GetFilesExcludedFromView($layer)
            if ($filesExcludedFromView.Contains($relativePathInView))
            {
                $filesExcludedFromView.Remove($relativePathInView)
                $filesExcludedFromView.Add($NewRelativePathInLayer)

                $this.SetFilesExcludedFromView($layer, $filesExcludedFromView)
            }
        }
    }

    # Get the list of items present in the view mapping that do not have a physical representation on disk.
    # The view mapping is the file created when a view is created that contains a dictionary of the type: <pathRelativeToView : absolutePathToLayerFile>
    # If a file is present in the view mapping, but not in the view files, it means that it was deleted or moved.
    hidden [System.Collections.IDictionary] GetItemsInViewMappingWithoutViewRepresentation([System.IO.FileInfo[]] $filesInView)
    {
        # The existing view mapping will give us information about how the last known good view was constructed
        [System.Collections.IDictionary] $existingViewMapping = $this.GetExistingViewMapping()

        # We go through all the files in the view and remove all the ones that are present
        # After this operation, the view mapping will only contain the files that have been deleted from the view or moved within the view.
        $filesInView | ForEach-Object {
            $pathInView = RemoveBasePrefix -BaseFolder $this.ViewRootFolder -FileInBaseFolder $_.FullName
            $existingViewMapping.Remove($pathInView)
        }

        return $existingViewMapping
    }

    hidden [string[]] GetFilesInLayers($RelativePathInView, $OnlyViewLayers)
    {
        # Find all the files in the base layers where this file appears.
        $sourceFiles = @()
        $layers = GetAllLayers
        if ($OnlyViewLayers)
        {
            $layers = $this.GetLayers()
        }

        foreach ($layer in $layers)
        {
            $pathInLayer = Join-Path (GetLayerFolder -CountryCode $layer) $RelativePathInView
            if (Test-Path $pathInLayer)
            {
                $sourceFiles += @($pathInLayer)
            }
        }

        return $sourceFiles
    }

    hidden [void] TryRemoveFileFromLayer($PathInView, $TargetPath, $FilesExcludedFromView)
    {
        $sourceLayerFileForView = $TargetPath
        $filesInLayers = $this.GetFilesInLayers($PathInView, $false)
        # The current layer is the top most layer associated with the view and, by convention, it has the same name as the view.
        $topLayerFolder = GetLayerFolder -CountryCode $this.CountryCode

        # If there is only one layer file and it is in the top layer, we remove it and return.
        $wasPresentInBaseLayer = $this.IsBaseView() -and ($filesInLayers.Length -eq 0)
        $isPresentInNonBaseLayer = !$this.IsBaseView() -and ($filesInLayers.Length -eq 1)
        $isOnlyPresentInCurrentLayer = $sourceLayerFileForView.StartsWith($topLayerFolder) -and ($wasPresentInBaseLayer -or $isPresentInNonBaseLayer)
        if ($isOnlyPresentInCurrentLayer)
        {
            # If the file comes from the base layer, it might already have been deleted.
            if (Test-Path $sourceLayerFileForView)
            {
                Remove-Item $sourceLayerFileForView
            }
        }
        else
        {
            Write-Host "The file '$PathInView' is part of the '$($this.CountryCode)' view, but appears in multiple layers:" -ForegroundColor "Yellow"
            $filesInLayers | ForEach-Object { Write-Host "      $_" -ForegroundColor "Yellow" }

            Write-Host "a: Press 'a' to delete the files from all the layers all views."
            Write-Host "b: Press 'b' to delete the files from only the base layers and all the views built on top of them."

            # We skip the exclusion file in the base view because it is not used at all.
            if (!$this.IsBaseView())
            {
                Write-Host "e: Press 'e' to exclude the file from the view without deleting the file from the base layer."
            }

            if ($sourceLayerFileForView.StartsWith($topLayerFolder))
            {
                Write-Host "t: Press 't' to delete the file from the top layer and remove it from the view while keeping the files in the base layers."
            }

            Write-Host "DEFAULT: Press anything to synchronize this file later. The view will not be synchronized and you will be prompted again."

            $input = Read-Host "Please make a selection"
            switch ($input)
            {
                'a'
                {
                    foreach ($file in $filesInLayers)
                    {
                        Remove-item $file
                    }
                }
                'b'
                {
                    foreach ($file in $this.GetFilesInLayers($PathInView, $true))
                    {
                        Remove-item $file
                    }
                }
                'e'
                {
                    # Always add the file to the exclusion list as the source can come from base layers
                    $FilesExcludedFromView.Add($PathInView)
                }
                't'
                {
                    if (Test-Path $sourceLayerFileForView)
                    {
                        Write-Host "Removing $PathInView from the $($this.CountryCode) view."
                        Remove-Item $sourceLayerFileForView
                    }

                    # Always add the file to the exclusion list as the source can come from base layers
                    $FilesExcludedFromView.Add($PathInView)
                }

                default
                {
                    Write-Host "$PathInView has not been removed from '$($this.CountryCode)' view. You will need to synchronize this change or discard it." -ForegroundColor "Red"
                }
            }
        }
    }

    hidden [void] UpdateLayerWithNewFilesFromView([System.IO.FileInfo[]] $filesInView)
    {
        $fileHelper = [FileOperationsHelper]::new()
        $viewFolderPath = $this.ViewRootFolder
        $topLayer = $this.GetTopLayer()
        $targetLayerFolderPath = GetLayerFolder -CountryCode $topLayer

        Write-Log "Copying new files from $viewFolderPath to $targetLayerFolderPath"
        $newFilesInView = $filesInView | Where-Object { ($_.LinkType -ne "SymbolicLink") -and ($null -ne $_.Target) }

        $copyFileToLayer = !$this.IsBaseView()
        foreach ($newFile in  $newFilesInView )
        {
            $pathRelativeToRoot = RemoveBasePrefix -BaseFolder $viewFolderPath -FileInBaseFolder $newFile.FullName

            $layerFilePath = Join-Path $targetLayerFolderPath $pathRelativeToRoot
            $viewFilePath = Join-Path $viewFolderPath $pathRelativeToRoot

            if ($copyFileToLayer)
            {
                $fileHelper.CopyFile($viewFilePath, $layerFilePath)
            }
        }
    }

    hidden [void] RemoveDanglingLinksFromView([System.IO.FileInfo[]] $filesInView)
    {
        Write-Log "Removing dangling links from $($this.ViewRootFolder)"
        $symbolicLinksInView = $filesInView | Where-Object { $_.LinkType -eq "SymbolicLink" }
        foreach ($existingSymbolicLink in $symbolicLinksInView)
        {
            if (-not (Test-Path $existingSymbolicLink.Target))
            {
                Write-Log "Removing $($existingSymbolicLink.FullName)"
                Remove-Item -Path $existingSymbolicLink.FullName
            }
        }
    }

    # Get the country codes for the layers that make up this view
    hidden [string[]] GetLayers()
    {
        if ($null -eq $this.layerNames)
        {
            $layersFilePath = GetViewConfigurationFile -CountryCode $this.CountryCode
            $layers = Get-Content $layersFilePath | ConvertFrom-Json
            $this.layerNames = GetLayersForView -LayersConfigObject $layers -CountryCode $this.CountryCode
        }

        return $this.layerNames
    }

    # Get the top (last to be applied) layer of this view
    hidden [string] GetTopLayer()
    {
        $layers = $this.GetLayers()
        return $layers[$layers.Length - 1];
    }

    hidden [string[]] GetSummaryForLayer([string] $Layer, [string[]]$Exclude)
    {
        $layerFolder = GetLayerFolder -CountryCode $Layer
        $foldersToExclude = $Exclude | ForEach-Object { "*\$_\*" }
        $summaryForLayer = Get-ChildItem -Path $layerFolder -File -Recurse -Exclude (GetFilePatternsExcludedFromGDLSync) |
        Where-Object {
            $fileName = $_.FullName;
            return ($foldersToExclude | Where-Object { $fileName -like $_ }).Length -eq 0
        } |
        ForEach-Object { RemoveBasePrefix -BaseFolder $layerFolder -FileInBaseFolder $_.FullName }

        return $summaryForLayer
    }

    hidden [System.Collections.Generic.SortedSet[string]] GetFilesExcludedFromView([string]$ViewCountryCode)
    {
        $filesExcludedFromView = New-Object 'System.Collections.Generic.SortedSet[string]' -ArgumentList  ([System.StringComparer]::OrdinalIgnoreCase);
        $viewInfoJSON = Get-Content (GetViewExclusionFile -CountryCode $ViewCountryCode) | ConvertFrom-Json
        $viewInfoJSON | ForEach-Object { $null = $filesExcludedFromView.Add($_) }

        return $filesExcludedFromView
    }

    hidden [void] SetFilesExcludedFromView([string]$ViewCountryCode, [System.Collections.Generic.SortedSet[string]]$FilesExcludedFromView)
    {
        Set-Content (GetViewExclusionFile -CountryCode $ViewCountryCode) -Value ($FilesExcludedFromView | ConvertTo-Json)
    }

    hidden [System.Collections.IDictionary] GetExistingViewMapping()
    {
        $viewSummaryFilePath = GetViewSummaryFile -CountryCode $this.CountryCode
        $existingViewMapping = New-Object 'System.Collections.Generic.Dictionary[[string], [string]]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase);
        if (Test-Path $viewSummaryFilePath)
        {
            (Get-Content $viewSummaryFilePath | ConvertFrom-Json).PSObject.Properties |
            ForEach-Object { $existingViewMapping[$_.Name] = $_.Value }
        }

        return $existingViewMapping
    }

    hidden [System.Collections.IDictionary] GetNewViewMapping([string[]]$Exclude)
    {
        $filesExcludedFromView = $this.GetFilesExcludedFromView($this.CountryCode)
        $newViewMapping = New-Object 'System.Collections.Generic.Dictionary[[string], [string]]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
        $layersComposingView = $this.GetLayers()
        # Go through the layers in the order they will be applied
        foreach ($layer in $layersComposingView)
        {
            $layerFolder = GetLayerFolder -CountryCode $layer
            $summaryForLayer = $this.GetSummaryForLayer($layer, $Exclude)
            foreach ($pathRelativeToLayerRoot in $summaryForLayer)
            {
                # If the file is in the top layer, add it to the view.
                # Otherwise, add it, only if it is in the expected view files.
                $isFileExcludedFromView = $filesExcludedFromView.Contains($pathRelativeToLayerRoot)
                if (!$isFileExcludedFromView)
                {
                    $pathToSourceFile = Join-Path $layerFolder $pathRelativeToLayerRoot
                    $newViewMapping[$pathRelativeToLayerRoot] = $pathToSourceFile
                }
            }
        }

        return $newViewMapping
    }

    hidden [void] MergeViewMappings([System.Collections.IDictionary]$ExistingViewMapping, [System.Collections.IDictionary]$NewViewMapping, [bool]$MaterializeView)
    {
        $fileHelper = [FileOperationsHelper]::new()
        $tarGetViewFolderPath = $this.ViewRootFolder
        foreach ($relativePathOfItem in $NewViewMapping.Keys)
        {
            [bool]$newFile = (-not $ExistingViewMapping.ContainsKey(($relativePathOfItem))) -or ($ExistingViewMapping[$relativePathOfItem] -ne $newViewMapping[$relativePathOfItem]);
            if ($newFile)
            {
                $itemPathInView = Join-Path $tarGetViewFolderPath $relativePathOfItem

                # only create links for real files
                $newFileInfo = Get-Item $NewViewMapping[$relativePathOfItem]
                if (($null -ne $newFileInfo) -and ($newFileInfo.Length -gt 1))
                {
                    if ($MaterializeView)
                    {
                        $fileHelper.CopyFile($NewViewMapping[$relativePathOfItem], $itemPathInView)
                    }
                    else
                    {
                        $fileHelper.CreateSymbolicLink($NewViewMapping[$relativePathOfItem], $itemPathInView)
                    }
                }
            }
        }
    }
}


<#
.SYNOPSIS
Assert that the view for the given country/region does not contain any files that have not been synchronized to the composing layers.

.PARAMETER CountryCode
The country/region whos view we want to verify.
#>
function Assert-GDLViewIsClean(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_ -in (GetAllGDLCountryCodes) })]
    [string]$CountryCode
)
{
    $gdlViewConfiguration = [GDLViewConfiguration]::new($CountryCode)
    $gdlViewConfiguration.AssertIsClean()
}

<#
.SYNOPSIS
Synchronize the files in the view with the files in the layers.
The view will be recomputed at the end of the operation and symbolic links will be created to the appropriate targets.

.DESCRIPTION
Any file that is not a link in the view will be copied over to the layer and a link will be created from the file to the view.
Any file that is present in the layer, but is not present in the view, will have a symbolic link created.

.PARAMETER CountryCode
The country/region code for which to synchronize the view.

.PARAMETER SyncMovesAndDeletes
Specifies whether files deleted from the view should be deleted from the source layer. Files will only be deleted if they originate
from the top-most layer.
#>
function Sync-GDLView(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_ -in (GetAllGDLCountryCodes) })]
    [string]$CountryCode,

    [switch]$SyncMovesAndDeletes
)
{
    $gdlViewConfiguration = [GDLViewConfiguration]::new($CountryCode)
    $gdlViewConfiguration.SynchronizeFromViewToLayers($SyncMovesAndDeletes)
    $gdlViewConfiguration.CreateViewFromLayers($false, @())

    Write-Log "Finished synchronizing $CountryCode view."
}

<#
.SYNOPSIS
Composes the layers that make up a GDL project into a single, unified view that can be opened in VSCode as an AL project.
The resulting project structure is similar to what could be achieve by copy-pasting the contents of the different layers in the order in which they need to be applied.
.DESCRIPTION
A GDL application is composed by overlapping multiple layers of customizations.
Each layer can provide a replacement (customization) of a file present in one of its base layers.
The customization in the highest layer is the one that will be present in the resulting view.

.PARAMETER CountryCode
The country/region code for which to create a view.

.EXAMPLE
The US project is composed of three layers: W1 + NA + US. Each layer either introduces new objects or replaces objects present in a base layer.
#>
function New-GDLView(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_ -in (GetAllGDLCountryCodes) })]
    [string]$CountryCode,
    [switch] $skipSetupDevelopmentSettings
)
{
    Write-Log "Creating GDL view for $CountryCode. This might take a few seconds."
    $gdlViewConfiguration = [GDLViewConfiguration]::new($CountryCode)
    $gdlViewConfiguration.CreateViewFromLayers($false, @())

    if (!$skipSetupDevelopmentSettings)
    {
        SetupDevelopmentSettings $gdlViewConfiguration
    }
}

function SetupDevelopmentSettings
(
    [GDLViewConfiguration] $GdlViewConfiguration
)
{
    # The recursion is needed for the Tests. We should find a better way of setting up the settings for these.
    $vscodeSettingFolders = Get-ChildItem $GdlViewConfiguration.ViewRootFolder -Directory -Recurse -Exclude @(".view", ".layer") |
    Where-Object { Test-Path (Join-Path $_.FullName app.json) } |
    ForEach-Object { return $_.FullName }

    # Reading the server settings is expensive so we do it once and use the value for all projects
    $defaultLaunchSettings = @{
        "serverInstance" = (Get-NavServerInstanceNameForPublishing -CountryCode $GdlViewConfiguration.CountryCode)
    }

    # We load the settings for all projects once. These are used to get the configuration of each project, e.g. analyzers and rulesets used. The same definition is used in ALAppBuild.
    $projectsSettings = (Get-Content -Path "$ENV:INETROOT/eng/AL-Go/projects.json" -Raw | ConvertFrom-Json).projects

    $vscodeSettingFolders | ForEach-Object {
        $ConfigureALProjectParams = @{
            ProjectFolder       = $_
            CountryCode         = $GdlViewConfiguration.CountryCode
            ResetConfiguration  = $true
            LaunchSettings      = $defaultLaunchSettings
        }
        $projectSettings = GetProjectSettings $projectsSettings $(Join-Path $_ app.json)
        if ($projectSettings.Count -ne 0) {
            $ConfigureALProjectParams."ProjectSettings" = $projectSettings
        }
        Configure-ALProject @ConfigureALProjectParams
    }
}

function GetProjectSettings([PSCustomObject]$projectsSettings, [string] $appJsonPath){
    $projectSettings = @{}
    $applicationName = (Get-Content -Path $appJsonPath -Raw | ConvertFrom-Json).name
    if($null -eq $applicationName){
        return $projectSettings
    }
    $projectSettingsObject = $projectsSettings | Select-Object -ExpandProperty $applicationName -ErrorAction Ignore
    if($null -eq $projectSettingsObject){
        return $projectSettings
    }
    if($null -ne $projectSettingsObject.runStaticCodeAnalysis){
        $projectSettings.'al.enableCodeAnalysis' = $projectSettingsObject.runStaticCodeAnalysis
        if($projectSettingsObject.runStaticCodeAnalysis){
            $projectSettings.'al.enableCodeActions' = $true
            $projectSettings.'al.backgroundCodeAnalysis' = $true
            # We enable the default analyzers run in ALAppBuild. See SetupCodeAnalysisDependencies in ApplicationBuildConfiguration
            $projectSettings.'al.codeAnalyzers' = @("$`{AppSourceCop`}", "$`{CodeCop`}")
        }
    }
    if($null -ne $projectSettingsObject.ruleSetPath){
        $projectSettings.'al.ruleSetPath' = $global:ExecutionContext.InvokeCommand.ExpandString($projectSettingsObject.ruleSetPath)
        $projectSettings.'al.ruleSetPath' = $projectSettings.'al.ruleSetPath' -replace '\\','/'
    }
    return $projectSettings
}

<#
.SYNOPSIS
Materialize a GDL view by creating a hard copy of all the files that compose the view.

.DESCRIPTION
In the official build, we stamp the build number into the app.json of the applications and
into several codeunits.
To prevent modifications to the files that are part of the change set, we create a hard copy.

.PARAMETER CountryCode
The country code for which to materialize a view.

.PARAMETER Exclude
Name of top level folders in the layers that should be excluded from the view.
#>
function New-MaterializedGDLView(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_ -in (GetAllGDLCountryCodes) })]
    [string]$CountryCode,
    [string[]]$Exclude
)
{
    Write-Log "Materializing views should only be used in the build system." -Warning
    Write-Log "Materializing GDL view for $CountryCode. This will take a few minutes."
    $gdlViewConfiguration = [GDLViewConfiguration]::new($CountryCode)
    $gdlViewConfiguration.CreateViewFromLayers($true, $Exclude)
}

<#
.SYNOPSIS
Remove the GDL view created for the given country code.
This will verify that the view does not contain any files that were not commited and proceed to remove the symbolic links
#>
function Remove-GDLView(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_ -in (GetAllGDLCountryCodes) })]
    [string]$CountryCode,

    [switch]$Force
)
{
    if (!$Force)
    {
        Assert-GDLViewIsClean -CountryCode $CountryCode
    }

    $gdlViewConfiguration = [GDLViewConfiguration]::new($CountryCode)

    if (!(Test-Path ($gdlViewConfiguration.ViewRootFolder)))
    {
        return;
    }

    if ($gdlViewConfiguration.IsBaseView())
    {
        if (Test-Path $gdlViewConfiguration.ViewRootFolder)
        {
            Write-Log "Removing $CountryCode view folder"
            $w1ViewFolder = Get-Item $gdlViewConfiguration.ViewRootFolder
            if (($w1ViewFolder.LinkType -eq 'Junction') -or ($w1ViewFolder.LinkType -eq 'SymbolicLink'))
            {
                $w1ViewFolder.Delete()
            }
            else
            {
                Remove-Item $w1ViewFolder -Recurse -Force:$Force
            }
        }
    }
    else
    {
        Remove-Item -Path ($gdlViewConfiguration.ViewRootFolder) -Recurse -Force:$Force
    }
}

<#
.SYNOPSIS
Remove all the created GDL views.

.PARAMETER Force
Use force to discard any unsynchronized files and wipe them from disk.
#>
function Remove-AllGDLViews([switch]$Force)
{
    Write-Log "Removing all GDL views."
    GetAllGDLCountryCodes | ForEach-Object { Remove-GDLView -CountryCode $_ -Force:$Force }
}

<#
.SYNOPSIS
Create a materialized GDL view and execute the given actions within its lifetime.

.PARAMETER CountryCode
The country code for which to generate the view.

.PARAMETER Actions
The actions to execute on the view.

.PARAMETER SkipCleanup
True if cleanup should be skipped, false otherwise.

.PARAMETER Exclude
Set of top level folder names in the layer to exclude when creating the view.
#>
function Invoke-OnMaterializedGDLView
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $CountryCode,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $Actions,

        [switch] $SkipCleanup,
        [string[]] $Exclude
    )

    New-MaterializedGDLView -CountryCode $CountryCode -Exclude $Exclude
    try
    {
        . $Actions
    }
    finally
    {
        if (!$SkipCleanup)
        {
            Remove-GDLView -CountryCode $CountryCode -Force
        }
    }
}

Export-ModuleMember -Function *-*