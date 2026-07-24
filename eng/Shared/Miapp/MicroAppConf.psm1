if (-not $env:MIAPP_DIR) {
    $env:MIAPP_DIR = $env:USERPROFILE
}

$MiappConfig = @{

# IntegrationDeps defines the propagation hierarchy: source path -> list of dependent paths.
# Structure mirrors src/Layers/ in this repository.
# W1 is the base layer; regional groups (APAC/DACH/NA) are intermediate layers
# between W1 and their respective country folders.
# miapp skips missing destination paths automatically.
IntegrationDeps = @{
    'src/Layers/W1/DemoTool/' = @(
        'src/Layers/APAC/DemoTool/',
        'src/Layers/BE/DemoTool/',
        'src/Layers/CZ/DemoTool/',
        'src/Layers/DACH/DemoTool/',
        'src/Layers/DK/DemoTool/',
        'src/Layers/ES/DemoTool/',
        'src/Layers/FI/DemoTool/',
        'src/Layers/FR/DemoTool/',
        'src/Layers/GB/DemoTool/',
        'src/Layers/IN/DemoTool/',
        'src/Layers/IS/DemoTool/',
        'src/Layers/IT/DemoTool/',
        'src/Layers/NA/DemoTool/',
        'src/Layers/NL/DemoTool/',
        'src/Layers/NO/DemoTool/',
        'src/Layers/RU/DemoTool/',
        'src/Layers/SE/DemoTool/');
    'src/Layers/APAC/DemoTool/' = @(
        'src/Layers/AU/DemoTool/',
        'src/Layers/NZ/DemoTool/');
    'src/Layers/DACH/DemoTool/' = @(
        'src/Layers/AT/DemoTool/',
        'src/Layers/DE/DemoTool/',
        'src/Layers/CH/DemoTool/');
    'src/Layers/NA/DemoTool/' = @(
        'src/Layers/CA/DemoTool/',
        'src/Layers/MX/DemoTool/',
        'src/Layers/US/DemoTool/');

    'src/Layers/W1/BaseApp/' = @(
        'src/Layers/APAC/BaseApp/',
        'src/Layers/BE/BaseApp/',
        'src/Layers/CZ/BaseApp/',
        'src/Layers/DACH/BaseApp/',
        'src/Layers/DK/BaseApp/',
        'src/Layers/ES/BaseApp/',
        'src/Layers/FI/BaseApp/',
        'src/Layers/FR/BaseApp/',
        'src/Layers/GB/BaseApp/',
        'src/Layers/IN/BaseApp/',
        'src/Layers/IS/BaseApp/',
        'src/Layers/IT/BaseApp/',
        'src/Layers/NA/BaseApp/',
        'src/Layers/NL/BaseApp/',
        'src/Layers/NO/BaseApp/',
        'src/Layers/RU/BaseApp/',
        'src/Layers/SE/BaseApp/');
    'src/Layers/APAC/BaseApp/' = @(
        'src/Layers/AU/BaseApp/',
        'src/Layers/NZ/BaseApp/');
    'src/Layers/DACH/BaseApp/' = @(
        'src/Layers/AT/BaseApp/',
        'src/Layers/DE/BaseApp/',
        'src/Layers/CH/BaseApp/');
    'src/Layers/NA/BaseApp/' = @(
        'src/Layers/CA/BaseApp/',
        'src/Layers/MX/BaseApp/',
        'src/Layers/US/BaseApp/');

    'src/Layers/W1/Tests/' = @(
        'src/Layers/APAC/Tests/',
        'src/Layers/BE/Tests/',
        'src/Layers/CZ/Tests/',
        'src/Layers/DACH/Tests/',
        'src/Layers/DK/Tests/',
        'src/Layers/ES/Tests/',
        'src/Layers/FI/Tests/',
        'src/Layers/FR/Tests/',
        'src/Layers/GB/Tests/',
        'src/Layers/IN/Tests/',
        'src/Layers/IS/Tests/',
        'src/Layers/IT/Tests/',
        'src/Layers/NA/Tests/',
        'src/Layers/NL/Tests/',
        'src/Layers/NO/Tests/',
        'src/Layers/RU/Tests/',
        'src/Layers/SE/Tests/');
    'src/Layers/APAC/Tests/' = @(
        'src/Layers/AU/Tests/',
        'src/Layers/NZ/Tests/');
    'src/Layers/DACH/Tests/' = @(
        'src/Layers/AT/Tests/',
        'src/Layers/DE/Tests/',
        'src/Layers/CH/Tests/');
    'src/Layers/NA/Tests/' = @(
        'src/Layers/CA/Tests/',
        'src/Layers/MX/Tests/',
        'src/Layers/US/Tests/');
};

IntegrationDepsAncestors = @{}
IntegrationDepsPriority = @{}
IntegrationDepsPrefixTree = @{}
MaxPriority = 0

SyncRoots = @('src/Layers/');

# Regular expression for file names to be excluded from the process
# Pattern matching is case-insensitive
ExclusionPatterns = @("*.docx");

DepotRoot = (git rev-parse --show-toplevel 2>$null);

ExclusionDir = "eng/Shared/Miapp/.miappsnap/";
ExclusionExt = ".json";

NoteLineId = 'miapp: ';

DefaultEditor = "notepad.exe";

MiappRerereDir = 'rerere'

}

function InitIntegrationDepsPriority {
    $MiappConfig.IntegrationDeps.Keys | SetIntegrationDepsPriority
}

function InitIntegrationDepsAncestors {
    $MiappConfig.IntegrationDeps.GetEnumerator() | % {
        $key = $_.Key;
        $_.Value | % { $MiappConfig.IntegrationDepsAncestors[$_] = $key }
    }
}

function InitIntegrationDepsPrefixTree {
    $preTree = $Miappconfig.IntegrationDepsPrefixTree
    $Miappconfig.IntegrationDeps.Keys | % {
        $hash = $preTree
        $_ -split '/' | % {
            if(-not ($tempHash = $hash[$_])) {
                $tempHash = $hash[$_] = @{}
            }
            $hash = $tempHash
        }
    }
}

function SetIntegrationDepsPriority
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true,
                   Position=0)]
        [Object[]] $Node = $MiappConfig.IntegrationDeps.Keys,
        [Parameter(Position=1)]
        [int] $Priority = 0
    )

    process {
        $Node | ? { $_ } | % {
            $prevPriority = $MiappConfig.IntegrationDepsPriority[$_]
            if($Priority -gt $prevPriority) {
                $MiappConfig.IntegrationDepsPriority[$_] = $Priority;
                $MiappConfig.MaxPriority = @($MiappConfig.MaxPriority, $Priority)[($MiappConfig.MaxPriority -lt $Priority)]
            }
            $Miappconfig.IntegrationDeps[$_] | % { SetIntegrationDepsPriority $_ ($Priority+1) }
        }
    }
}

function Get-RootIntegrationBranchName([Parameter(Mandatory=$true)][string] $Path)
{
    $hash = $Miappconfig.IntegrationDepsPrefixTree
    $resHash = $null
    $res = ''
    foreach ($entry in $path.Split('/')) {
        if(-not $entry -or -not ($hash = $hash[$entry])) {
            break
        }

        $resHash = $hash
        $res += "$entry/"
    }
    [bool] $isLeaf = $resHash -and $resHash['']
    if($res -and $isLeaf) {
        $res
    }
}

function Initialize-IntegrationDeps {
    $Miappconfig.IntegrationDepsAncestors = @{}
    $Miappconfig.IntegrationDepsPriority = @{}
    $Miappconfig.IntegrationDepsPrefixTree = @{}

    InitIntegrationDepsPriority
    InitIntegrationDepsAncestors
    InitIntegrationDepsPrefixTree
}

function Get-MiappDir {
    $path = '.miapp'
    if($env:MIAPP_DIR) {
        $path = Join-Path $env:MIAPP_DIR $path
    }
    $path
}

Initialize-IntegrationDeps


Export-ModuleMember -Variable MiappConfig
Export-ModuleMember *-*
