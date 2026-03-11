#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates Power BI report pages and their corresponding AL pages in Business Central.

.DESCRIPTION
    This script validates that:
    - All Power BI report pages have corresponding AL pages in Business Central
    - All AL pages for reports under the same app are in the same folder
    - All apps have a page where ReportPageLbl is empty (rendering the full app)
    - No AL page points to an invalid Power BI page ID

.PARAMETER ALFolders
    Array of paths to folders containing AL files to validate.

.PARAMETER PBIPFolders
    Array of paths to folders to search for PBIP files. The script will recursively find all .pbip files within these folders.

.PARAMETER ExceptionsFile
    Optional path to a YAML file containing Power BI page IDs that are exceptions (don't require AL pages).

.EXAMPLE
    .\Validate-PowerBIReportPages.ps1 -ALFolders @("App\Finance", "App\Sales") -PBIPFolders @("Power BI Files")

.EXAMPLE
    .\Validate-PowerBIReportPages.ps1 -ALFolders @("App\Finance") -PBIPFolders @("Power BI Files\Finance app") -ExceptionsFile "Scripts\exceptions-power-bi-pages-validation.yaml"
#>

param(
    [Parameter(Mandatory = $true)]
    [string[]]$ALFolders,
    
    [Parameter(Mandatory = $true)]
    [string[]]$PBIPFolders,
    
    [Parameter(Mandatory = $false)]
    [string]$ExceptionsFile
)

# Function to find all PBIP files recursively in given folders
function Find-PBIPFiles {
    param([string[]]$SearchFolders)
    
    $pbipFiles = @()
    
    foreach ($searchFolder in $SearchFolders) {
        if (-not (Test-Path $searchFolder)) {
            Write-Warning "Search folder not found: $searchFolder"
            continue
        }
        
        $foundPbipFiles = Get-ChildItem -Path $searchFolder -Filter "*.pbip" -Recurse
        
        foreach ($pbipFile in $foundPbipFiles) {
            # The PBIP file's parent directory contains the app structure
            $appFolder = $pbipFile.Directory.FullName
            $pbipFiles += $appFolder
        }
    }
    
    return $pbipFiles | Sort-Object -Unique
}

# Function to load exceptions from YAML file
function Get-ExceptionsFromYaml {
    param([string]$YamlFilePath)
    
    $exceptions = @()
    
    if ([string]::IsNullOrEmpty($YamlFilePath) -or -not (Test-Path $YamlFilePath)) {
        return $exceptions
    }
    
    try {
        $content = Get-Content -Path $YamlFilePath -Raw
        
        # Simple YAML parsing for the exceptions list
        # This handles the specific format: exceptions: followed by list items with - prefix
        if ($content -match 'exceptions:\s*((?:\s*[-#].*\n?)*)') {
            $exceptionBlock = $matches[1]
            $lines = $exceptionBlock -split '\n'
            
            foreach ($line in $lines) {
                # Match lines that start with - followed by page ID (ignoring comments)
                if ($line -match '^\s*-\s*(\S+)') {
                    $pageId = $matches[1].Trim()
                    if ($pageId -and $pageId -notin $exceptions) {
                        $exceptions += $pageId
                    }
                }
            }
        }
        
        Write-Verbose "Loaded $($exceptions.Count) exceptions from $YamlFilePath"
    }
    catch {
        Write-Warning "Failed to parse exceptions file '$YamlFilePath': $($_.Exception.Message)"
    }
    
    return $exceptions
}

# Function to extract ReportPageLbl from AL file
function Get-ReportPageLabelFromALFile {
    param([string]$FilePath)
    
    try {
        $content = Get-Content -Path $FilePath -Raw
        if ($content -match 'ReportPageLbl:\s*Label\s*[''"]([^''"]*)[''"]') {
            return $matches[1]
        }
        return $null
    }
    catch {
        Write-Warning "Failed to read file: $FilePath - $($_.Exception.Message)"
        return $null
    }
}

# Function to get Power BI page IDs and display names from PBIP structure
function Get-PowerBIPageInfo {
    param([string]$PBIPPath)
    
    $pageInfo = @()
    $reportPath = Join-Path $PBIPPath "*.Report"
    $reportFolder = Get-ChildItem -Path $reportPath -Directory | Select-Object -First 1
    
    if (-not $reportFolder) {
        return $pageInfo
    }
    
    $pagesPath = Join-Path $reportFolder.FullName "definition\pages"
    if (-not (Test-Path $pagesPath)) {
        return $pageInfo
    }
    
    $pageDirectories = Get-ChildItem -Path $pagesPath -Directory
    foreach ($pageDir in $pageDirectories) {
        $displayName = $pageDir.Name  # Default to ID if display name not found
        
        # Try to get display name from page.json
        $pageJsonPath = Join-Path $pageDir.FullName "page.json"
        if (Test-Path $pageJsonPath) {
            try {
                $pageJson = Get-Content -Path $pageJsonPath -Raw | ConvertFrom-Json
                if ($pageJson.displayName) {
                    $displayName = $pageJson.displayName
                }
            }
            catch {
                Write-Warning "Failed to parse page.json for page $($pageDir.Name): $($_.Exception.Message)"
            }
        }
        
        $pageInfo += [PSCustomObject]@{
            Id = $pageDir.Name
            DisplayName = $displayName
        }
    }
    
    return $pageInfo
}

# Function to find AL embedded folder for app by searching for AL files containing Power BI page IDs
function Find-ALEmbeddedFolder {
    param([string]$AppName, [string[]]$ALFolders, [string[]]$PowerBIPageIds)
    
    if (-not $PowerBIPageIds -or $PowerBIPageIds.Count -eq 0) {
        Write-Verbose "No Power BI page IDs provided for app '$AppName', cannot determine embedded folder"
        return $null
    }
    
    $allMatches = $ALFolders | ForEach-Object -Parallel {
        $alFolder = $_
        $pageIds = $using:PowerBIPageIds
        $appName = $using:AppName
        
        $folderMatches = @()
        
        if (-not (Test-Path $alFolder)) {
            Write-Verbose "AL folder not found: $alFolder"
            return $folderMatches
        }
        
        $alFiles = Get-ChildItem -Path $alFolder -Filter "*.Page.al" -Recurse
        
        if ($alFiles.Count -eq 0) {
            return $folderMatches
        }
        
        # Create a regex pattern that matches any of the Power BI page IDs
        $pageIdPattern = '(' + ($pageIds -join '|') + ')'
        $regexPattern = "ReportPageLbl:\s*Label\s*[`"']($pageIdPattern)[`"']"
        
        # Search all files in parallel for matching page IDs
        $matchResults = $alFiles | ForEach-Object -Parallel {
            $file = $_
            $pattern = $using:regexPattern
            $pageIdsArray = $using:pageIds
            
            try {
                $searchMatches = Select-String -Path $file.FullName -Pattern $pattern -AllMatches
                
                $fileMatches = @()
                foreach ($match in $searchMatches) {
                    if ($match.Matches.Count -gt 0) {
                        $reportPageId = $match.Matches[0].Groups[1].Value
                        if ($reportPageId -in $pageIdsArray) {
                            $fileMatches += [PSCustomObject]@{
                                FilePath = $file.FullName
                                FileName = $file.Name
                                Directory = $file.Directory.FullName
                                ReportPageId = $reportPageId
                            }
                        }
                    }
                }
                return $fileMatches
            }
            catch {
                Write-Warning "Failed to search file: $($file.FullName) - $($_.Exception.Message)"
                return @()
            }
        }
        
        # Flatten the results and return
        return $matchResults | Where-Object { $_ -ne $null }
    }
    
    # Flatten all matches from all folders
    $allMatches = $allMatches | Where-Object { $_ -ne $null }
    
    if (-not $allMatches -or $allMatches.Count -eq 0) {
        Write-Verbose "No AL files found containing Power BI page IDs for app '$AppName'"
        return $null
    }
    
    # Group matches by directory and count them
    $folderStats = $allMatches | Group-Object -Property Directory | ForEach-Object {
        $folder = $_.Name
        $matchCount = $_.Count
        $uniquePageIds = ($_.Group | Select-Object -ExpandProperty ReportPageId | Sort-Object -Unique).Count
        $isObsolete = $folder -match "(?i)obsolete"  # Case-insensitive check for "obsolete" in path
        
        [PSCustomObject]@{
            Folder = $folder
            MatchCount = $matchCount
            UniquePageIds = $uniquePageIds
            IsObsolete = $isObsolete
            Matches = $_.Group
        }
    } | Sort-Object -Property @{Expression="UniquePageIds"; Descending=$true}, @{Expression="IsObsolete"; Descending=$false}, @{Expression="MatchCount"; Descending=$true}
    
    # Log all candidate folders with their match counts
    Write-Verbose "Found $($folderStats.Count) candidate folders for app '$AppName':"
    foreach ($stat in $folderStats) {
        $obsoleteTag = if ($stat.IsObsolete) { " (obsolete)" } else { "" }
        Write-Verbose "  - $($stat.Folder): $($stat.UniquePageIds) unique page IDs ($($stat.MatchCount) total matches)$obsoleteTag"
        foreach ($match in $stat.Matches) {
            Write-Verbose "    * $($match.FileName): $($match.ReportPageId)"
        }
    }
    
    # Return the folder with the highest number of unique page ID matches
    $bestFolder = $folderStats[0].Folder
    
    # Log selection reasoning if there are multiple candidates
    if ($folderStats.Count -gt 1) {
        $bestStat = $folderStats[0]
        $secondBestStat = $folderStats[1]
        
        if ($bestStat.UniquePageIds -eq $secondBestStat.UniquePageIds) {
            if ($bestStat.IsObsolete -ne $secondBestStat.IsObsolete) {
                Write-Verbose "Selected non-obsolete folder over obsolete alternative with same match count"
            } elseif ($bestStat.MatchCount -ne $secondBestStat.MatchCount) {
                Write-Verbose "Selected folder with higher total match count ($($bestStat.MatchCount) vs $($secondBestStat.MatchCount))"
            }
        } else {
            Write-Verbose "Selected folder with most unique page IDs ($($bestStat.UniquePageIds) vs $($secondBestStat.UniquePageIds))"
        }
    }
    
    return $bestFolder
}

$exceptions = Get-ExceptionsFromYaml $ExceptionsFile

$actualPBIPFolders = Find-PBIPFiles $PBIPFolders

if ($actualPBIPFolders.Count -eq 0) {
    Write-Warning "No PBIP files found in the specified folders: $($PBIPFolders -join ', ')"
    return @()
}

Write-Verbose "Found $($actualPBIPFolders.Count) PBIP apps: $($actualPBIPFolders -join ', ')"

# Main validation logic
$validationResults = @()

foreach ($pbipFolder in $actualPBIPFolders) {
    if (-not (Test-Path $pbipFolder)) {
        Write-Warning "PBIP folder not found: $pbipFolder"
        continue
    }
    
    $appName = Split-Path $pbipFolder -Leaf 
    $powerBIPageInfo = Get-PowerBIPageInfo $pbipFolder
    $powerBIPageIds = $powerBIPageInfo | ForEach-Object { $_.Id }
    $alEmbeddedFolder = Find-ALEmbeddedFolder $appName $ALFolders $powerBIPageIds
    
    $result = [PSCustomObject]@{
        AppName = $appName
        PBIPPath = $pbipFolder
        ALEmbeddedFolder = $alEmbeddedFolder
        PowerBIPageInfo = $powerBIPageInfo
        PowerBIPageIds = $powerBIPageIds
        PowerBIPageCount = $powerBIPageIds.Count
        ALPages = @()
        MissingALPages = @()
        ExceptedPages = @()
        InvalidALPageIds = @()
        HasFullAppPage = $false
        ValidationStatus = "Unknown"
        Issues = @()
    }
    
    if ($alEmbeddedFolder -and (Test-Path $alEmbeddedFolder)) {
        $alFiles = Get-ChildItem -Path $alEmbeddedFolder -Filter "*.Page.al"

        foreach ($alFile in $alFiles) {
            $reportPageId = Get-ReportPageLabelFromALFile $alFile.FullName
            $alPageInfo = [PSCustomObject]@{
                FileName = $alFile.Name
                ReportPageId = $reportPageId
                IsFullApp = [string]::IsNullOrEmpty($reportPageId)
            }
            $result.ALPages += $alPageInfo
            
            # Check if this is the full app page
            if ([string]::IsNullOrEmpty($reportPageId)) {
                $result.HasFullAppPage = $true
            }
            # Check if the page ID exists in Power BI
            elseif ($reportPageId -notin $powerBIPageIds) {
                $result.InvalidALPageIds += $reportPageId
            }
        }
        
        # Find missing AL pages (excluding exceptions)
        $alPageIds = $result.ALPages | Where-Object { -not $_.IsFullApp } | ForEach-Object { $_.ReportPageId }
        foreach ($pageInfo in $powerBIPageInfo) {
            if ($pageInfo.Id -notin $alPageIds) {
                if ($pageInfo.Id -in $exceptions) {
                    # This page is in the exceptions list
                    $result.ExceptedPages += [PSCustomObject]@{
                        Id = $pageInfo.Id
                        DisplayName = $pageInfo.DisplayName
                    }
                } else {
                    # This page is missing an AL page and not in exceptions
                    $result.MissingALPages += [PSCustomObject]@{
                        Id = $pageInfo.Id
                        DisplayName = $pageInfo.DisplayName
                    }
                }
            }
        }
        
        $issues = @()
        if ($result.MissingALPages.Count -gt 0) {
            $missingPagesText = $result.MissingALPages | ForEach-Object { "$($_.DisplayName) ($($_.Id))" }
            $issues += "Missing AL pages for Power BI pages: $($missingPagesText -join ', ')"
        }
        if ($result.InvalidALPageIds.Count -gt 0) {
            $issues += "AL pages pointing to invalid Power BI page IDs: $($result.InvalidALPageIds -join ', ')"
        }
        if (-not $result.HasFullAppPage) {
            $issues += "No AL page found for full app (empty ReportPageLbl)"
        }
        
        $result.Issues = $issues
        $result.ValidationStatus = if ($issues.Count -eq 0) { "Valid" } else { "Invalid" }
    }
    else {
        $result.ValidationStatus = "AL Embedded folder not found"
        $result.Issues = @("AL Embedded folder not found for app: $appName")
    }
    
    $validationResults += $result
}

Write-Host "`nPower BI Report Pages Validation Results`n" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

foreach ($result in $validationResults) {
    Write-Host "`nApp Name: " -NoNewline -ForegroundColor Yellow
    Write-Host $result.AppName -ForegroundColor White
    
    Write-Host "PBIP Path: " -NoNewline -ForegroundColor Yellow
    Write-Host $result.PBIPPath -ForegroundColor Gray
    
    Write-Host "AL Embedded Folder: " -NoNewline -ForegroundColor Yellow
    Write-Host ($result.ALEmbeddedFolder ?? "Not Found") -ForegroundColor Gray
    
    Write-Host "Power BI Pages: " -NoNewline -ForegroundColor Yellow
    Write-Host $result.PowerBIPageCount -ForegroundColor White
    
    Write-Host "AL Pages: " -NoNewline -ForegroundColor Yellow
    Write-Host $result.ALPages.Count -ForegroundColor White
    
    if ($result.ExceptedPages.Count -gt 0) {
        Write-Host "Excepted Pages: " -NoNewline -ForegroundColor Yellow
        Write-Host $result.ExceptedPages.Count -ForegroundColor Cyan
    }
    
    Write-Host "Has Full App Page: " -NoNewline -ForegroundColor Yellow
    $color = if ($result.HasFullAppPage) { "Green" } else { "Red" }
    Write-Host $result.HasFullAppPage -ForegroundColor $color
    
    Write-Host "Validation Status: " -NoNewline -ForegroundColor Yellow
    $statusColor = switch ($result.ValidationStatus) {
        "Valid" { "Green" }
        "Invalid" { "Red" }
        default { "Yellow" }
    }
    Write-Host $result.ValidationStatus -ForegroundColor $statusColor
    
    if ($result.MissingALPages.Count -gt 0) {
        Write-Host "Missing AL Pages: " -NoNewline -ForegroundColor Red
        $missingPagesDisplay = $result.MissingALPages | ForEach-Object { "$($_.DisplayName) ($($_.Id))" }
        Write-Host ($missingPagesDisplay -join ', ') -ForegroundColor Gray
    }
    
    if ($result.ExceptedPages.Count -gt 0) {
        if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
            Write-Host "Excepted Pages: " -NoNewline -ForegroundColor Cyan
            $exceptedPagesDisplay = $result.ExceptedPages | ForEach-Object { "$($_.DisplayName) ($($_.Id))" }
            Write-Host ($exceptedPagesDisplay -join ', ') -ForegroundColor Gray
        }
    }
    
    if ($result.InvalidALPageIds.Count -gt 0) {
        Write-Host "Invalid AL Page IDs: " -NoNewline -ForegroundColor Red
        Write-Host ($result.InvalidALPageIds -join ', ') -ForegroundColor Gray
    }
    
    if ($result.Issues.Count -gt 0) {
        Write-Host "Issues:" -ForegroundColor Red
        foreach ($issue in $result.Issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
    
    Write-Host ("-" * 60) -ForegroundColor Gray
}

$totalApps = $validationResults.Count
$validApps = ($validationResults | Where-Object { $_.ValidationStatus -eq "Valid" }).Count
$invalidApps = $totalApps - $validApps

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Total Apps: $totalApps" -ForegroundColor White
Write-Host "Valid Apps: $validApps" -ForegroundColor Green
Write-Host "Invalid Apps: $invalidApps" -ForegroundColor Red

if ($invalidApps -eq 0) {
    Write-Host "`nAll apps meet the validation guidelines!" -ForegroundColor Green
}

return $validationResults