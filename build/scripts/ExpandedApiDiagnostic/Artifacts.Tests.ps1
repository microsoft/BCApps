BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contract.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1') -Force
    $script:fixture=Join-Path $PSScriptRoot ".artifacts-$([guid]::NewGuid().ToString('N'))"
    $null=New-Item -ItemType Directory -Path $fixture
    $script:saved=@{}
    foreach($key in @('GITHUB_REPOSITORY','GITHUB_REF','GITHUB_EVENT_NAME','GITHUB_RUN_ATTEMPT','GITHUB_RUN_ID','GITHUB_SHA',
        'GITHUB_WORKSPACE','BC_EXPANDED_COUNTRY','BC_EXPANDED_PROJECT','BC_EXPANDED_ARTIFACT_FIXTURE','BcContainerHelperPath')){
        $saved[$key]=[Environment]::GetEnvironmentVariable($key)
    }
    $env:GITHUB_REPOSITORY='microsoft/BCApps';$env:GITHUB_REF='refs/heads/features/653393-expanded-api-diagnostic'
    $env:GITHUB_EVENT_NAME='workflow_dispatch';$env:GITHUB_RUN_ATTEMPT='1';$env:GITHUB_RUN_ID='999';$env:GITHUB_SHA='a'*40
    $env:GITHUB_WORKSPACE=$fixture;$env:BC_EXPANDED_COUNTRY='CA';$env:BC_EXPANDED_PROJECT='build\projects\Expanded Build CA'
    $env:BC_EXPANDED_ARTIFACT_FIXTURE=Join-Path $fixture 'service.json'
}
AfterAll {
    Remove-Module BcContainerHelper -ErrorAction SilentlyContinue
    foreach($key in $saved.Keys){[Environment]::SetEnvironmentVariable($key,$saved[$key])}
    Remove-Item $fixture -Recurse -Force
}

Describe 'Exact shared build archives and consumer transport' {
    BeforeEach {
        $folder=Join-Path $fixture 'archive-source'
        if(Test-Path $folder){Remove-Item $folder -Recurse -Force}
        $null=New-Item -ItemType Directory -Path $folder
        Set-Content (Join-Path $folder 'one.app') 'compiled-byte-fixture'
        $archive=Join-Path $fixture 'source.zip'
        Compress-Archive -Path (Join-Path $folder '*') -DestinationPath $archive -Force
        $script:digest=(Get-FileHash $archive).Hash.ToLowerInvariant()
        @{archive=$archive;id='111';expired=$false;digest="sha256:$digest";name='fixture'
            workflow_run=@{id='999';head_sha=('a'*40)}}|ConvertTo-Json -Depth 5|Set-Content $env:BC_EXPANDED_ARTIFACT_FIXTURE
        Mock Invoke-RestMethod -ModuleName Artifacts {Get-Content $env:BC_EXPANDED_ARTIFACT_FIXTURE -Raw|ConvertFrom-Json}
        Mock Invoke-WebRequest -ModuleName Artifacts {
            $service=Get-Content $env:BC_EXPANDED_ARTIFACT_FIXTURE -Raw|ConvertFrom-Json
            Copy-Item $service.archive $OutFile
        }
        $script:destination=Join-Path $fixture ([guid]::NewGuid().ToString('N'))
    }
    It 'downloads the exact ID, verifies transport SHA and extracts only then' {
        $metadata=Save-ExpandedArtifact -Id 111 -Digest $digest -Directory $destination
        $metadata.id|Should -Be 111
        Test-Path (Join-Path $destination 'one.app')|Should -BeTrue
        Should -Invoke Invoke-WebRequest -ModuleName Artifacts -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://api.github.com/repos/microsoft/BCApps/actions/artifacts/111/zip'
        }
    }
    It 'refuses changed source or expired packages before downloading bytes' -ForEach @('source','expired') {
        $service=Get-Content $env:BC_EXPANDED_ARTIFACT_FIXTURE -Raw|ConvertFrom-Json
        if($_ -eq 'source'){$service.workflow_run.head_sha='b'*40}else{$service.expired=$true}
        $service|ConvertTo-Json -Depth 5|Set-Content $env:BC_EXPANDED_ARTIFACT_FIXTURE
        {Save-ExpandedArtifact -Id 111 -Digest $digest -Directory $destination}|Should -Throw
        Should -Invoke Invoke-WebRequest -ModuleName Artifacts -Times 0 -Exactly
    }
    It 'rejects corrupt downloaded archive bytes' {
        $service=Get-Content $env:BC_EXPANDED_ARTIFACT_FIXTURE -Raw|ConvertFrom-Json
        $service.digest='sha256:'+('c'*64)
        $service|ConvertTo-Json -Depth 5|Set-Content $env:BC_EXPANDED_ARTIFACT_FIXTURE
        {Save-ExpandedArtifact -Id 111 -Digest ('c'*64) -Directory $destination}|Should -Throw '*hash mismatch*'
    }
    It 'rejects traversal even when archive transport SHA is valid' {
        $archive=Join-Path $fixture 'traversal.zip'
        if(Test-Path $archive){Remove-Item $archive}
        $zip=[IO.Compression.ZipFile]::Open($archive,[IO.Compression.ZipArchiveMode]::Create)
        try {$entry=$zip.CreateEntry('../escaped.app');$writer=[IO.StreamWriter]::new($entry.Open());$writer.Write('bad');$writer.Dispose()}finally{$zip.Dispose()}
        $digest=(Get-FileHash $archive).Hash.ToLowerInvariant()
        $service=Get-Content $env:BC_EXPANDED_ARTIFACT_FIXTURE -Raw|ConvertFrom-Json
        $service.archive=$archive;$service.digest="sha256:$digest"
        $service|ConvertTo-Json -Depth 5|Set-Content $env:BC_EXPANDED_ARTIFACT_FIXTURE
        {Save-ExpandedArtifact -Id 111 -Digest $digest -Directory $destination}|Should -Throw '*Unsafe archive path*'
        Test-Path (Join-Path $fixture 'escaped.app')|Should -BeFalse
    }
}

Describe 'Compiler output feeds the real sealed manifest producer' {
    BeforeAll {
        $helper=Join-Path $fixture 'BcContainerHelper.psm1'
        Set-Content $helper @'
$bcContainerHelperVersion='6.1.19-preview2811389'
function Get-AppJsonFromAppFile {param([string]$appFile) Get-Content $appFile -Raw|ConvertFrom-Json}
Export-ModuleMember -Function Get-AppJsonFromAppFile
'@
        Import-Module $helper -Force
        $env:BcContainerHelperPath=$helper
        $script:output=Join-Path $fixture 'expanded-api-output'
        $null=New-Item -ItemType Directory -Path $output
        $overlay=Get-Content (Join-Path $PSScriptRoot 'source-overlay.json') -Raw|ConvertFrom-Json
        @{sourceHead=('a'*40);runId='999';attempt=1;sourceTree=$overlay.sourceTree;overlaySha256=$overlay.overlaySha256}|
            ConvertTo-Json|Set-Content (Join-Path $output 'source-receipt.json')
        @{country='ca'}|ConvertTo-Json|Set-Content (Join-Path $output 'project-settings.json')
        @{runner='fake-compiler-runner'}|ConvertTo-Json|Set-Content (Join-Path $output 'clock.json')
        $root=Join-Path $fixture "$($env:BC_EXPANDED_PROJECT)\.buildartifacts"
        $null=New-Item -ItemType Directory -Path (Join-Path $root 'Apps'),(Join-Path $root 'TestApps')
        @{id='23de40a6-dfe8-4f80-80db-d70f83ce8caf';name='Test Runner';version='30.0.1.0';dependencies=@()} |
            ConvertTo-Json|Set-Content (Join-Path $root 'Apps\runner.app')
        @{id='8d52df0b-add3-4e9b-aac5-f11107cba919';name='IRS Forms Tests';version='30.0.1.0';dependencies=@()} |
            ConvertTo-Json|Set-Content (Join-Path $root 'TestApps\irs.app')
        @{id='fixture-no-transactions';name='Library - No Transactions';version='30.0.1.0';dependencies=@()} |
            ConvertTo-Json|Set-Content (Join-Path $root 'Apps\Microsoft_Library - No Transactions_30.0.1.0.app')
        @{id='fixture-prevent-metadata';name='Prevent Metadata Updates Library';version='30.0.1.0';dependencies=@()} |
            ConvertTo-Json|Set-Content (Join-Path $root 'Apps\Microsoft_Prevent Metadata Updates Library_30.0.1.0.app')
    }
    BeforeEach {
        Mock Invoke-RestMethod -ModuleName Artifacts {
            $id=($Uri -split '/')[-1]
            $kind=if($id -eq '111'){'Apps'}else{'TestApps'}
            $digest=if($id -eq '111'){'c'*64}else{'d'*64}
            [pscustomobject]@{id=$id;expired=$false;name="expanded-$kind-CA-999";digest="sha256:$digest"
                workflow_run=[pscustomobject]@{id='999';head_sha=('a'*40)}}
        }
    }
    It 'seals actual artifact IDs, package hashes, metadata and reviewed source without rebuilding per arm' {
        & (Join-Path $PSScriptRoot 'SealBuild.ps1') -AppsId 111 -AppsDigest ('c'*64) -TestsId 112 -TestsDigest ('d'*64)
        $manifest=Get-Content (Join-Path $output 'packages.json') -Raw|ConvertFrom-Json
        $manifest.artifacts.id -join ','|Should -Be '111,112'
        $manifest.files.Count|Should -Be 4
        @($manifest.files|Where-Object appName -EQ 'IRS Forms Tests').Count|Should -Be 1
        $manifest.freshCompilation|Should -BeTrue
        {Assert-ExpandedApiPackageManifest -Manifest $manifest -Country CA -RunId 999 -SourceHead ('a'*40) `
            -SourceTree $manifest.sourceTree -PackageDirectory (Join-Path $fixture "$($env:BC_EXPANDED_PROJECT)\.buildartifacts")} |
            Should -Not -Throw
        $installed=@($manifest.files|Where-Object appName -NotIn @('Library - No Transactions','Prevent Metadata Updates Library')|
            ForEach-Object {[pscustomobject]@{AppId=$_.appId;Name=$_.appName;Version=$_.version;Publisher='Microsoft'}})
        $sealedBefore=$manifest|ConvertTo-Json -Depth 30 -Compress
        $inventory=Assert-ExpandedInstalledInventory -Files $manifest.files -Installed $installed
        $inventory.excluded.Count|Should -Be 2
        $inventory.required.Count|Should -Be 2
        ($manifest|ConvertTo-Json -Depth 30 -Compress)|Should -Be $sealedBefore
    }
    It 'still rejects changed bytes in a deliberately unpublished library' {
        & (Join-Path $PSScriptRoot 'SealBuild.ps1') -AppsId 111 -AppsDigest ('c'*64) -TestsId 112 -TestsDigest ('d'*64)
        $manifest=Get-Content (Join-Path $output 'packages.json') -Raw|ConvertFrom-Json
        ($manifest.files|Where-Object appName -EQ 'Library - No Transactions').sha256='e'*64
        {Assert-ExpandedApiPackageManifest -Manifest $manifest -Country CA -RunId 999 -SourceHead ('a'*40) `
            -SourceTree $manifest.sourceTree -PackageDirectory (Join-Path $fixture "$($env:BC_EXPANDED_PROJECT)\.buildartifacts")} |
            Should -Throw '*Package bytes differ*'
    }
}
