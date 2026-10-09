BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Artifacts.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot 'Reuse.psm1') -Force
    $script:fixture = Join-Path $PSScriptRoot ".reuse-$([guid]::NewGuid().ToString('N'))"
    $null = New-Item -ItemType Directory -Path $fixture
    $script:saved = @{}
    foreach ($key in @('GITHUB_REPOSITORY','GITHUB_REF','GITHUB_EVENT_NAME','GITHUB_RUN_ATTEMPT','GITHUB_RUN_ID','GITHUB_SHA',
        'BC_EXPANDED_REUSE_TEST_MUTATION','GITHUB_WORKSPACE','GITHUB_OUTPUT','BC_EXPANDED_COUNTRY',
        'BC_EXPANDED_CONFIG','BC_EXPANDED_LANE','BC_EXPANDED_REUSE_ARCHIVE_MAP')) { $saved[$key] = [Environment]::GetEnvironmentVariable($key) }
    $env:GITHUB_REPOSITORY = 'microsoft/BCApps'; $env:GITHUB_REF = 'refs/heads/features/653393-expanded-api-reuse-successor'
    $env:GITHUB_EVENT_NAME = 'workflow_dispatch'; $env:GITHUB_RUN_ATTEMPT = '1'
    $env:GITHUB_RUN_ID = '999'; $env:GITHUB_SHA = 'a'*40
    $script:policy = Get-ExpandedReusePolicy
    $script:registryPath = $env:BC_EXPANDED_REUSE_REGISTRY
    if (-not $registryPath -or -not $env:BC_EXPANDED_REUSE_ZIP) {
        throw 'Set BC_EXPANDED_REUSE_REGISTRY and BC_EXPANDED_REUSE_ZIP to the already audited local registry; never download test fixtures.'
    }
    $script:originalHash = (Get-FileHash $registryPath).Hash.ToLowerInvariant()
    $originalHash | Should -BeExactly $policy.registryFileSha256
    (Get-FileHash $env:BC_EXPANDED_REUSE_ZIP).Hash.ToLowerInvariant() | Should -BeExactly $policy.registryDigest
}
AfterAll {
    if ($registryPath) { (Get-FileHash $registryPath).Hash.ToLowerInvariant() | Should -BeExactly $originalHash }
    foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) }
    if (Test-Path $fixture) { Remove-Item $fixture -Recurse -Force }
}
Describe 'Approved producer and independent consumer provenance' {
    BeforeEach {
        $script:registry = Get-Content $registryPath -Raw | ConvertFrom-Json
        $script:source = @{ runId = '999'; sourceHead = ('a'*40); attempt = 1; compiled = $false
            sourceTree = $policy.sourceTree; overlaySha256 = $policy.overlaySha256 }
    }
    It 'accepts the actual five-country registry without changing a manifest or claiming compilation' {
        $before = $registry | ConvertTo-Json -Depth 40 -Compress
        Assert-ExpandedReuseRegistry -Registry $registry -Source $source
        $receipt = New-ExpandedAdoptionReceipt -Source $source
        Assert-ExpandedAdoptionReceipt -Receipt $receipt
        $receipt.compiledThisRun | Should -BeFalse
        $receipt.producer.runId | Should -BeExactly '37896636913'
        $receipt.consumer.runId | Should -BeExactly '999'
        $receipt.producer.sourceHead | Should -Not -Be $receipt.consumer.sourceHead
        @($registry.countries.packageManifest.files).Count | Should -Be 1296
        ($registry | ConvertTo-Json -Depth 40 -Compress) | Should -BeExactly $before
    }
    It 'rejects a consumer source mismatch: <_>' -ForEach @('runId','sourceHead','sourceTree','overlaySha256','attempt','compiled') {
        if ($_ -eq 'attempt') { $source[$_] = 2 }
        elseif ($_ -eq 'compiled') { $source[$_] = $true }
        else { $source[$_] = 'wrong' }
        { Assert-ExpandedReuseRegistry -Registry $registry -Source $source } | Should -Throw
    }
    It 'rejects producer drift: <_>' -ForEach @('runId','sourceHead','attempt','country','sourceTree','overlaySha256','freshCompilation') {
        if ($_ -eq 'attempt') { $registry.countries[0].packageManifest.$_ = 2 }
        elseif ($_ -eq 'freshCompilation') { $registry.countries[0].packageManifest.$_ = $false }
        else { $registry.countries[0].packageManifest.$_ = 'wrong' }
        { Assert-ExpandedReuseRegistry -Registry $registry -Source $source } | Should -Throw
    }
    It 'rejects runtime/package pin drift: <_>' -ForEach @('platform','application','helper','alGo','image','authentication','memoryBytes','stack') {
        if ($_ -eq 'memoryBytes') { $registry.countries[0].packageManifest.pins.$_ = 1 }
        else { $registry.countries[0].packageManifest.pins.$_ = 'wrong' }
        { Assert-ExpandedReuseRegistry -Registry $registry -Source $source } | Should -Throw '*pin drift*'
    }
    It 'rejects mixed manifest IDs, archive digests and duplicate countries' -ForEach @('id','digest','duplicate') {
        if ($_ -eq 'id') { $registry.countries[0].artifactId = '123' }
        elseif ($_ -eq 'digest') { $registry.countries[0].sha256 = 'f'*64 }
        else { $registry.countries[1].country = $registry.countries[0].country }
        { Assert-ExpandedReuseRegistry -Registry $registry -Source $source } | Should -Throw
    }
    It 'rejects relabeled compilation and old-run runtime receipts' -ForEach @('compiled','producer','consumer','attempt') {
        $receipt = New-ExpandedAdoptionReceipt -Source $source
        switch ($_) {
            compiled { $receipt.compiledThisRun = $true }
            producer { $receipt.producer.sourceHead = $env:GITHUB_SHA }
            consumer { $receipt.consumer.runId = $policy.runId }
            attempt { $receipt.consumer.attempt = 2 }
        }
        { Assert-ExpandedAdoptionReceipt -Receipt $receipt } | Should -Throw
    }
}

Describe 'Real sealed registry transport with locally simulated GitHub responses' {
    BeforeEach {
        $env:BC_EXPANDED_REUSE_TEST_MUTATION = ''
        $script:source = @{ runId = '999'; sourceHead = ('a'*40); attempt = 1; compiled = $false
            sourceTree = $policy.sourceTree; overlaySha256 = $policy.overlaySha256 }
        $script:destination = Join-Path $fixture ([guid]::NewGuid().ToString('N'))
        Mock Invoke-RestMethod -ModuleName Reuse {
            $p = Get-ExpandedReusePolicy
            @{ id = $p.runId; head_sha = $p.sourceHead
                run_attempt = $(if ($env:BC_EXPANDED_REUSE_TEST_MUTATION -eq 'attempt') { 2 } else { 1 })
                status = 'completed'; conclusion = 'failure'; repository = @{ full_name = 'microsoft/BCApps' } }
        }
        Mock Invoke-RestMethod -ModuleName Artifacts {
            $digest = (Get-FileHash $env:BC_EXPANDED_REUSE_ZIP).Hash.ToLowerInvariant()
            @{ id = '11613371849'; expired = ($env:BC_EXPANDED_REUSE_TEST_MUTATION -eq 'expired')
                digest = "sha256:$digest"
                workflow_run = @{ id = '37896636913'; head_sha = 'bd763f0b489277dc3696bb352396456d625ab63c' } }
        }
        Mock Invoke-WebRequest -ModuleName Artifacts { Copy-Item $env:BC_EXPANDED_REUSE_ZIP $OutFile }
    }
    It 'uses the old producer for artifact transport and the new consumer for adoption' {
        $registry = Get-ExpandedReuseRegistry -Id $policy.registryId -Digest $policy.registryDigest -Directory $destination -Source $source
        $registry.sourceHead | Should -BeExactly $policy.sourceHead
        (Get-FileHash (Join-Path $destination 'registry.json')).Hash.ToLowerInvariant() | Should -BeExactly $policy.registryFileSha256
        $env:GITHUB_RUN_ID | Should -Be '999'
        $env:GITHUB_SHA | Should -Be ('a'*40)
    }
    It 'refuses expired producer artifacts and changed producer attempt before copying bytes' -ForEach @('expired','attempt') {
        $env:BC_EXPANDED_REUSE_TEST_MUTATION = $_
        { Get-ExpandedReuseRegistry -Id $policy.registryId -Digest $policy.registryDigest -Directory $destination -Source $source } |
            Should -Throw
        Should -Invoke Invoke-WebRequest -ModuleName Artifacts -Times 0 -Exactly
    }
    It 'retains current-consumer-only defaults for runtime evidence downloads' {
        { Save-ExpandedArtifact -Id $policy.registryId -Digest $policy.registryDigest -Directory $destination } |
            Should -Throw '*another run/source*'
        Should -Invoke Invoke-WebRequest -ModuleName Artifacts -Times 0 -Exactly
    }
    It 'refuses an unapproved registry even when its supplied archive digest looks valid' {
        { Get-ExpandedReuseRegistry -Id 123 -Digest $policy.registryDigest -Directory $destination -Source $source } |
            Should -Throw '*Only the reviewed registry*'
        Should -Invoke Invoke-RestMethod -ModuleName Reuse -Times 0 -Exactly
    }
    It 'rejects registry JSON alteration independently of transport validation' {
        Mock Save-ExpandedArtifact -ModuleName Reuse {
            $null = New-Item -ItemType Directory -Path $Directory
            Set-Content (Join-Path $Directory 'registry.json') '{"runId":"wrong"}'
        }
        { Get-ExpandedReuseRegistry -Id $policy.registryId -Digest $policy.registryDigest -Directory $destination -Source $source } |
            Should -Throw '*registry file hash*'
    }
}

Describe 'Reuse workflow has no compiler or hidden rebuild fallback' {
    It 'uses adoption then bounded trials while preserving the independent group' {
        $workflow = Get-Content (Join-Path $PSScriptRoot '..\..\..\.github\workflows\SqlApiExpandedDiagnostic.yaml') -Raw
        $workflow | Should -Not -Match '(?m)^  Build:|CompileApps@|SealBuild\.ps1|Compiler\.ps1|needs\.Build'
        $workflow | Should -Match 'Adopt\.ps1'
        $workflow | Should -Match 'max-parallel: 2'
        $workflow | Should -Match 'group: sql-api-653393-expanded-api-diagnostic'
        $workflow | Should -Match 'cancel-in-progress: false'
    }

    Describe 'Real ReceivePackages consumer against already audited W1 archives' {
        BeforeAll {
            $script:registry = Get-Content $registryPath -Raw | ConvertFrom-Json
            $script:entry = @($registry.countries | Where-Object country -CEQ 'W1')[0]
            $script:cacheRoot = Split-Path (Split-Path (Split-Path $registryPath -Parent) -Parent) -Parent
            $script:cache = Join-Path $cacheRoot 'build-W1'
            $map = @{}
            $map[$policy.registryId] = $env:BC_EXPANDED_REUSE_ZIP
            $map[[string]$entry.artifactId] = Join-Path $cache "$($entry.artifactId).zip"
            foreach ($artifact in $entry.packageManifest.artifacts) {
                $map[[string]$artifact.id] = Join-Path $cache "$($artifact.id).zip"
            }
            foreach ($path in $map.Values) { if (-not (Test-Path $path)) { throw "Missing already cached archive: $path" } }
            $env:BC_EXPANDED_REUSE_ARCHIVE_MAP = Join-Path $fixture 'archive-map.json'
            $map | ConvertTo-Json | Set-Content $env:BC_EXPANDED_REUSE_ARCHIVE_MAP
            $env:GITHUB_WORKSPACE = Join-Path $fixture 'receive'
            $env:GITHUB_OUTPUT = Join-Path $fixture 'github-output.txt'
            $env:BC_EXPANDED_COUNTRY = 'W1'; $env:BC_EXPANDED_CONFIG = 'm1w1'; $env:BC_EXPANDED_LANE = 'Default'
            $script:output = Join-Path $env:GITHUB_WORKSPACE 'expanded-api-output'
            $null = New-Item -ItemType Directory -Path $output -Force
            @{ runId = '999'; sourceHead = ('a'*40); attempt = 1; compiled = $false
                sourceTree = $policy.sourceTree; overlaySha256 = $policy.overlaySha256 } |
                ConvertTo-Json | Set-Content (Join-Path $output 'source-receipt.json')
            Mock Invoke-RestMethod -ModuleName Reuse {
                $p = Get-ExpandedReusePolicy
                @{ id = $p.runId; head_sha = $p.sourceHead; run_attempt = 1; status = 'completed'
                    conclusion = 'failure'; repository = @{ full_name = 'microsoft/BCApps' } }
            }
            Mock Invoke-RestMethod -ModuleName Artifacts {
                $id = ($Uri -split '/')[-1]
                $map = Get-Content $env:BC_EXPANDED_REUSE_ARCHIVE_MAP -Raw | ConvertFrom-Json -AsHashtable
                if (-not $map.ContainsKey($id)) { throw "Unexpected artifact lookup: $id" }
                @{ id = $id; expired = $false; digest = "sha256:$((Get-FileHash $map[$id]).Hash.ToLowerInvariant())"
                    workflow_run = @{ id = '37896636913'; head_sha = 'bd763f0b489277dc3696bb352396456d625ab63c' } }
            }
            Mock Invoke-WebRequest -ModuleName Artifacts {
                $id = ($Uri -split '/')[-2]
                $map = Get-Content $env:BC_EXPANDED_REUSE_ARCHIVE_MAP -Raw | ConvertFrom-Json -AsHashtable
                Copy-Item $map[$id] $OutFile
            }
            & (Join-Path $PSScriptRoot 'ReceivePackages.ps1') -RegistryId $policy.registryId -RegistryDigest $policy.registryDigest
        }
        It 'consumes all 248 actual package bytes and preserves the producer manifest verbatim' {
            $proof = Get-Content (Join-Path $output 'transport-proof.json') -Raw | ConvertFrom-Json
            $proof.packageFilesVerified | Should -BeTrue
            $proof.adoption.compiledThisRun | Should -BeFalse
            $proof.adoption.producer.sourceHead | Should -BeExactly $policy.sourceHead
            $proof.adoption.consumer.sourceHead | Should -BeExactly $env:GITHUB_SHA
            $country = Join-Path $env:GITHUB_WORKSPACE 'expanded-country-manifest'
            (Get-FileHash (Join-Path $output 'packages.json')).Hash | Should -BeExactly (Get-FileHash (Join-Path $country 'packages.json')).Hash
            $manifest = Get-Content (Join-Path $output 'packages.json') -Raw | ConvertFrom-Json
            $manifest.files.Count | Should -Be 248
            $manifest.files.appName | Should -Contain 'Library - No Transactions'
            $manifest.files.appName | Should -Contain 'Prevent Metadata Updates Library'
            $manifest.sourceHead | Should -BeExactly $policy.sourceHead
            $manifest.freshCompilation | Should -BeTrue
            $proof.adoption.compiledThisRun | Should -BeFalse
        }
        It 'rejects altered real binary bytes, including Source/Build metadata bytes, rather than relabeling them' {
            $manifest = Get-Content (Join-Path $output 'packages.json') -Raw | ConvertFrom-Json
            $root = Join-Path $env:GITHUB_WORKSPACE 'expanded-packages'
            $file = Join-Path $root $manifest.files[0].path
            $original = [IO.File]::ReadAllBytes($file)
            try {
                $changed = [byte[]]$original.Clone()
                $changed[0] = $changed[0] -bxor 1
                [IO.File]::WriteAllBytes($file, $changed)
                { Assert-ExpandedApiPackageManifest -Manifest $manifest -Country W1 -RunId $policy.runId `
                    -SourceHead $policy.sourceHead -SourceTree $policy.sourceTree -PackageDirectory $root } |
                    Should -Throw '*Package bytes differ*'
            } finally { [IO.File]::WriteAllBytes($file, $original) }
        }
        It 'rejects changed sealed metadata, missing cleanup and false compiler absence' -ForEach @('metadata','cleanup','absence') {
            $country = Join-Path $env:GITHUB_WORKSPACE 'expanded-country-manifest'
            $directory = Join-Path $fixture "invalid-country-$_"
            Copy-Item $country $directory -Recurse
            if ($_ -eq 'metadata') {
                $path = Join-Path $directory 'packages.json'
                $manifest = Get-Content $path -Raw | ConvertFrom-Json
                $manifest.files[0].version = '30.0.0.1'
                $manifest | ConvertTo-Json -Depth 40 | Set-Content $path
            } elseif ($_ -eq 'cleanup') { Remove-Item (Join-Path $directory 'compiler-cleanup.json') }
            else {
                $path = Join-Path $directory 'compiler-cleanup.json'
                $cleanup = Get-Content $path -Raw | ConvertFrom-Json
                $cleanup.absenceVerified = $false
                $cleanup | ConvertTo-Json -Depth 10 | Set-Content $path
            }
            { Assert-ExpandedReuseCountry -Entry $entry -Directory $directory } | Should -Throw
        }
    }
}
