BeforeAll {
    $script:root = $PSScriptRoot
    $script:fixture = Join-Path $root ".helper-scope-$([guid]::NewGuid().ToString('N'))"
    $null = New-Item -ItemType Directory -Path $fixture
    $script:helper = Join-Path $fixture 'BcContainerHelper.psm1'
    Set-Content $helper @'
$bcContainerHelperVersion = if($env:BC_SCOPE_WRONG_VERSION){'6.1.7'}else{'6.1.19-preview2811389'}
$bcContainerHelperConfig = @{hostHelperFolder=(Join-Path $env:GITHUB_WORKSPACE 'host')}
function Get-AppJsonFromAppFile {param($appFile) @{id='synthetic-loader-only';path=$appFile}}
function New-BcCompilerFolder {param($containerName,$platformArtifactUrl) throw "No compiler invocation authorized: $containerName $platformArtifactUrl"}
function Remove-BcCompilerFolder {
    param($compilerFolder)
    if($env:BC_SCOPE_REMOVE_FAIL){throw 'original cleanup failure'}
    Remove-Item -LiteralPath $compilerFolder -Recurse -Force
}
Export-ModuleMember -Function Get-AppJsonFromAppFile,New-BcCompilerFolder,Remove-BcCompilerFolder
'@
    $script:saved = @{}
    foreach($key in @('BcContainerHelperPath','GITHUB_WORKSPACE','GITHUB_REPOSITORY','GITHUB_REF','GITHUB_EVENT_NAME',
        'GITHUB_RUN_ATTEMPT','GITHUB_RUN_ID','BC_EXPANDED_COUNTRY','BC_SCOPE_REMOVE_FAIL','BC_SCOPE_WRONG_VERSION')){
        $saved[$key]=[Environment]::GetEnvironmentVariable($key)
    }
    $env:BcContainerHelperPath=$helper
    $env:GITHUB_WORKSPACE=$fixture
    $env:GITHUB_REPOSITORY='microsoft/BCApps'
    $env:GITHUB_REF='refs/heads/features/653393-expanded-api-helper-scope'
    $env:GITHUB_EVENT_NAME='workflow_dispatch'
    $env:GITHUB_RUN_ATTEMPT='1'
    $env:GITHUB_RUN_ID='999'
    $env:BC_EXPANDED_COUNTRY='W1'
}
AfterAll {
    Remove-Module BcContainerHelper -ErrorAction SilentlyContinue
    foreach($key in $saved.Keys){[Environment]::SetEnvironmentVariable($key,$saved[$key])}
    Remove-Item $fixture -Recurse -Force
}

Describe 'Cold and warm helper scope boundaries' {
    BeforeEach {
        Remove-Module BcContainerHelper,Context -ErrorAction SilentlyContinue
        Import-Module (Join-Path $root 'Context.psm1') -Force
        $env:BC_SCOPE_WRONG_VERSION=''
    }
    It 'loads the module inside Context but exports the API to its caller' {
        Get-Module BcContainerHelper | Should -BeNullOrEmpty
        Import-ExpandedHelper -RequiredCommands @{'Get-AppJsonFromAppFile'=@('appFile')}
        (Get-AppJsonFromAppFile -appFile 'fixture.app').id | Should -Be 'synthetic-loader-only'
        (Get-Command Get-AppJsonFromAppFile).Module.Path | Should -Be $helper
    }
    It 'retains the same warm instance and in-memory configuration without Force' {
        Import-ExpandedHelper
        $module=Get-Module BcContainerHelper
        $configuration=& $module {$bcContainerHelperConfig}
        $configuration.warmSentinel='keep'
        Import-ExpandedHelper
        [object]::ReferenceEquals($module,(Get-Module BcContainerHelper)) | Should -BeTrue
        (& $module {$bcContainerHelperConfig.warmSentinel}) | Should -Be keep
    }
    It 'fails when the exact required export or parameter does not exist' {
        {Import-ExpandedHelper -RequiredCommands @{'Not-ARealHelperCommand'=@()}} | Should -Throw
        {Import-ExpandedHelper -RequiredCommands @{'Get-AppJsonFromAppFile'=@('NotARealParameter')}} | Should -Throw '*Missing helper parameter*'
    }
    It 'rejects the wrong version rather than silently replacing a warm provider' {
        $env:BC_SCOPE_WRONG_VERSION='1'
        {Import-ExpandedHelper} | Should -Throw '*not the pinned*'
        $module=Get-Module BcContainerHelper
        {Import-ExpandedHelper} | Should -Throw '*not the pinned*'
        [object]::ReferenceEquals($module,(Get-Module BcContainerHelper)) | Should -BeTrue
    }
    It 'resolves the command from a genuinely fresh pwsh process without global fake preloading' {
        $scriptPath=Join-Path $fixture 'cold-child.ps1'
        @'
param($ContextPath)
$ErrorActionPreference='Stop'
if(Get-Module BcContainerHelper -All){throw 'Child was preloaded'}
Import-Module $ContextPath
Import-ExpandedHelper -RequiredCommands @{'Get-AppJsonFromAppFile'=@('appFile')}
(Get-AppJsonFromAppFile -appFile 'child.app').id
'@ | Set-Content $scriptPath
        $text = & (Get-Process -Id $PID).Path -NoProfile -File $scriptPath -ContextPath (Join-Path $root 'Context.psm1')
        $LASTEXITCODE | Should -Be 0
        $text | Should -Contain 'synthetic-loader-only'
    }
}

Describe 'Owned compiler cleanup evidence even on failure' {
    BeforeEach {
        Remove-Module BcContainerHelper,Context -ErrorAction SilentlyContinue
        $env:BC_SCOPE_REMOVE_FAIL=''
        $env:BC_SCOPE_WRONG_VERSION=''
        $script:output=Join-Path $fixture 'expanded-api-output'
        $null=New-Item -ItemType Directory $output -Force
        $script:owned=Join-Path $fixture 'host\compiler\bcbuildprojectsExpandedBuildW1999compiler'
        $null=New-Item -ItemType Directory $owned -Force
        @{run='999';name='bcbuildprojectsExpandedBuildW1999compiler';folder=$owned} |
            ConvertTo-Json | Set-Content (Join-Path $output 'compiler-ownership.json')
    }
    It 'preserves the original removal error and records unknown absence' {
        $env:BC_SCOPE_REMOVE_FAIL='1'
        {& (Join-Path $root 'Compiler.ps1') -Phase Cleanup} | Should -Throw '*original cleanup failure*'
        $status=Get-Content (Join-Path $output 'compiler-cleanup.json') -Raw|ConvertFrom-Json
        $status.ownershipValidated | Should -BeTrue
        $status.removalAttempted | Should -BeTrue
        $status.absenceVerified | Should -BeFalse
        $status.compilerRemaining | Should -BeNullOrEmpty
        Test-Path $owned | Should -BeTrue
    }
    It 'records a cold load failure without deleting or claiming absence' {
        $env:BC_SCOPE_WRONG_VERSION='1'
        {& (Join-Path $root 'Compiler.ps1') -Phase Cleanup} | Should -Throw '*not the pinned*'
        $status=Get-Content (Join-Path $output 'compiler-cleanup.json') -Raw|ConvertFrom-Json
        $status.removalAttempted | Should -BeFalse
        $status.absenceVerified | Should -BeFalse
        Test-Path $owned | Should -BeTrue
    }
    It 'does not authorize a matching basename outside the helper compiler root' {
        $foreign=Join-Path $fixture 'foreign\bcbuildprojectsExpandedBuildW1999compiler'
        $null=New-Item -ItemType Directory $foreign -Force
        @{run='999';name='bcbuildprojectsExpandedBuildW1999compiler';folder=$foreign} |
            ConvertTo-Json | Set-Content (Join-Path $output 'compiler-ownership.json')
        {& (Join-Path $root 'Compiler.ps1') -Phase Cleanup} | Should -Throw '*ownership path differs*'
        Test-Path $foreign | Should -BeTrue
    }
    It 'only reports successful absence after checking the owned destination' {
        & (Join-Path $root 'Compiler.ps1') -Phase Cleanup
        $status=Get-Content (Join-Path $output 'compiler-cleanup.json') -Raw|ConvertFrom-Json
        $status.absenceVerified | Should -BeTrue
        $status.compilerRemaining | Should -BeFalse
        $status.failureType | Should -BeNullOrEmpty
    }
}
