Describe 'API test credential materialization' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..\ApiTestCredential.psm1') -Force
        $script:previousGitHubEnv = $env:GITHUB_ENV
        $script:previousExitCode = Get-Variable LASTEXITCODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
        $script:createdMountStub = -not (Get-Command Get-BcContainerSharedFolders -ListImported -ErrorAction SilentlyContinue)
        if ($script:createdMountStub) {
            function global:Get-BcContainerSharedFolders {
                param([string]$containerName)
                $null = $containerName
                throw 'Container mount lookup must be mocked.'
            }
        }
        $script:createdDockerStub = -not (Get-Command docker -ErrorAction SilentlyContinue)
        if ($script:createdDockerStub) {
            function global:docker {
                param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
                $null = $Arguments
                throw 'Docker must be mocked.'
            }
        }
        $script:credential = [PSCredential]::new('unit-test', (ConvertTo-SecureString 'synthetic-fixture-only' -AsPlainText -Force))
        $script:mount = Join-Path $PSScriptRoot 'unused-mount'
    }

    AfterAll {
        $env:GITHUB_ENV = $script:previousGitHubEnv
        $global:LASTEXITCODE = $script:previousExitCode
        if ($script:createdMountStub) { Remove-Item function:global:Get-BcContainerSharedFolders }
        if ($script:createdDockerStub) { Remove-Item function:global:docker }
    }

    BeforeEach {
        $env:GITHUB_ENV = Join-Path $PSScriptRoot 'unused-github-env'
        $script:events = [System.Collections.Generic.List[string]]::new()
        $script:stream = [PSCustomObject]@{
            Events = $script:events
            Buffer = $null
            Written = $null
            FailWrite = $false
            FailDispose = $false
        }
        $script:stream | Add-Member ScriptMethod Write {
            param($buffer, $offset, $count)
            $this.Events.Add('write')
            $this.Buffer = $buffer
            $this.Written = [System.Text.Encoding]::UTF8.GetString($buffer, $offset, $count)
            if ($this.FailWrite) { throw 'Synthetic write failure' }
        }
        $script:stream | Add-Member ScriptMethod Dispose {
            $this.Events.Add('dispose')
            if ($this.FailDispose) { throw 'Synthetic flush failure' }
        }
        Mock -ModuleName ApiTestCredential Get-BcContainerSharedFolders { @{ $script:mount = 'c:\run\my\' } }
        Mock -ModuleName ApiTestCredential Add-Content { $script:events.Add('register') }
        Mock -ModuleName ApiTestCredential New-ApiTestPasswordFileStream {
            $script:events.Add('create')
            $script:stream
        }
        Mock -ModuleName ApiTestCredential Test-Path { $true }
        Mock -ModuleName ApiTestCredential docker {
            $global:LASTEXITCODE = 0
            if ($args[0] -eq 'container') { 'synthetic-container-id' }
            else { $script:events.Add('stop') }
        }
        Mock -ModuleName ApiTestCredential Remove-Item { $script:events.Add('delete') }
    }

    It 'registers cleanup and creates the secured backing file before the first secret write' {
        Write-ApiTestPassword -ContainerName 'unit-test' -Credential $script:credential

        ($script:events -join ',') | Should -Be 'register,create,write,dispose'
        $script:stream.Written | Should -Be 'synthetic-fixture-only'
        @($script:stream.Buffer | Where-Object { $_ -ne 0 }).Count | Should -Be 0
        Should -Invoke -ModuleName ApiTestCredential New-ApiTestPasswordFileStream -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq (Join-Path $script:mount 'ApiTestPassword')
        }
        Should -Invoke -ModuleName ApiTestCredential Add-Content -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq $env:GITHUB_ENV -and $ErrorAction -eq 'Stop' -and
            $Value -eq "BCAppsApiTestPasswordPath=$(Join-Path $script:mount 'ApiTestPassword')"
        }
        Should -Invoke -ModuleName ApiTestCredential docker -Times 0
    }

    It 'uses the same secured mount locally without workflow registration' {
        $env:GITHUB_ENV = ''
        Write-ApiTestPassword -ContainerName 'unit-test' -Credential $script:credential

        ($script:events -join ',') | Should -Be 'create,write,dispose'
        Should -Invoke -ModuleName ApiTestCredential Get-BcContainerSharedFolders -Times 1 -Exactly
        Should -Invoke -ModuleName ApiTestCredential Add-Content -Times 0
    }

    It 'fails closed on an unresolved mount in CI and locally' {
        Mock -ModuleName ApiTestCredential Get-BcContainerSharedFolders { @{} }
        foreach ($environmentPath in @('unused-github-env', '')) {
            $env:GITHUB_ENV = $environmentPath
            { Write-ApiTestPassword -ContainerName 'unit-test' -Credential $script:credential } | Should -Throw '*Cannot resolve*'
        }
        Should -Invoke -ModuleName ApiTestCredential New-ApiTestPasswordFileStream -Times 0
        Should -Invoke -ModuleName ApiTestCredential Add-Content -Times 0
    }

    It 'fails closed on ambiguous mounts' {
        Mock -ModuleName ApiTestCredential Get-BcContainerSharedFolders { @{ 'C:\first' = 'C:\Run\my'; 'C:\second' = 'c:\run\my' } }
        { Write-ApiTestPassword -ContainerName 'unit-test' -Credential $script:credential } | Should -Throw '*Cannot resolve*'
        Should -Invoke -ModuleName ApiTestCredential New-ApiTestPasswordFileStream -Times 0
    }

    It 'does not materialize credentials if workflow cleanup registration fails' {
        Mock -ModuleName ApiTestCredential Add-Content { throw 'Synthetic registration failure' }
        { Write-ApiTestPassword -ContainerName 'unit-test' -Credential $script:credential } | Should -Throw '*Synthetic registration failure*'
        Should -Invoke -ModuleName ApiTestCredential New-ApiTestPasswordFileStream -Times 0
    }

    It 'does not write or delete an existing file when secured creation fails' {
        Mock -ModuleName ApiTestCredential New-ApiTestPasswordFileStream { throw 'Synthetic ACL or create failure' }
        { Write-ApiTestPassword -ContainerName 'unit-test' -Credential $script:credential } | Should -Throw '*Synthetic ACL or create failure*'
        ($script:events -join ',') | Should -Be 'register'
        Should -Invoke -ModuleName ApiTestCredential Remove-Item -Times 0
    }

    It 'closes the failed writer and stops consumers before deleting a partial file' {
        $script:stream.FailWrite = $true
        { Write-ApiTestPassword -ContainerName 'unit-test' -Credential $script:credential } | Should -Throw '*Synthetic write failure*'

        ($script:events -join ',') | Should -Be 'register,create,write,dispose,stop,delete'
        @($script:stream.Buffer | Where-Object { $_ -ne 0 }).Count | Should -Be 0
    }

    It 'also cleans up after a flush failure without reporting success' {
        $script:stream.FailDispose = $true
        { Write-ApiTestPassword -ContainerName 'unit-test' -Credential $script:credential } | Should -Throw '*Synthetic flush failure*'
        ($script:events -join ',') | Should -Be 'register,create,write,dispose,stop,delete'
    }

    It 'preserves the setup error and credential when consumers cannot be stopped' {
        $script:stream.FailWrite = $true
        Mock -ModuleName ApiTestCredential docker { $global:LASTEXITCODE = 1 } -ParameterFilter { $args[0] -eq 'stop' }
        Mock -ModuleName ApiTestCredential Write-Warning {}

        { Write-ApiTestPassword -ContainerName 'unit-test' -Credential $script:credential } | Should -Throw '*Synthetic write failure*'
        Should -Invoke -ModuleName ApiTestCredential Remove-Item -Times 0
        Should -Invoke -ModuleName ApiTestCredential Write-Warning -Times 1 -Exactly
    }
}

Describe 'API test credential atomic Windows ACL' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..\ApiTestCredential.psm1') -Force
        $script:aclRoot = Join-Path $PSScriptRoot ("acl-fixture-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:aclRoot | Out-Null
    }

    AfterAll {
        Remove-Item -LiteralPath $script:aclRoot -Recurse -Force
    }

    It 'has only required explicit SIDs on an empty file before writing synthetic bytes' {
        $path = Join-Path $script:aclRoot 'ApiTestPassword'
        $stream = $null
        try {
            $stream = & (Get-Module ApiTestCredential) { param($path) New-ApiTestPasswordFileStream -FilePath $path } $path
            $stream.Length | Should -Be 0
            $acl = Get-Acl -LiteralPath $path
            $acl.AreAccessRulesProtected | Should -BeTrue
            $rules = @($acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier]))
            @($rules | Where-Object IsInherited).Count | Should -Be 0
            $writerSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $expectedSids = @('S-1-5-18', 'S-1-5-20', 'S-1-5-32-544', $writerSid) | Select-Object -Unique
            ($rules.IdentityReference.Value | Sort-Object) | Should -Be ($expectedSids | Sort-Object)
            foreach ($sid in @('S-1-5-18', 'S-1-5-32-544')) {
                ($rules | Where-Object { $_.IdentityReference.Value -eq $sid }).FileSystemRights |
                    Should -Be ([System.Security.AccessControl.FileSystemRights]::FullControl)
            }
            $networkServiceRights = [System.Security.AccessControl.FileSystemRights]'Read, Synchronize'
            if ($writerSid -eq 'S-1-5-20') {
                $networkServiceRights = $networkServiceRights -bor [System.Security.AccessControl.FileSystemRights]'Write, Delete'
            }
            ($rules | Where-Object { $_.IdentityReference.Value -eq 'S-1-5-20' }).FileSystemRights |
                Should -Be $networkServiceRights
            if ($writerSid -notin @('S-1-5-18', 'S-1-5-20', 'S-1-5-32-544')) {
                ($rules | Where-Object { $_.IdentityReference.Value -eq $writerSid }).FileSystemRights |
                    Should -Be ([System.Security.AccessControl.FileSystemRights]'Write, Delete, Synchronize')
            }
            $stream.WriteByte(65)
            $stream.Length | Should -Be 1
        }
        finally {
            if ($stream) { $stream.Dispose() }
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }

    It 'refuses to overwrite an existing file or change its ACL' {
        $path = Join-Path $script:aclRoot 'ApiTestPassword'
        [System.IO.File]::WriteAllText($path, 'synthetic-existing-fixture')
        $before = (Get-Acl -LiteralPath $path).Sddl
        try {
            { & (Get-Module ApiTestCredential) { param($path) New-ApiTestPasswordFileStream -FilePath $path } $path } | Should -Throw
            [System.IO.File]::ReadAllText($path) | Should -Be 'synthetic-existing-fixture'
            (Get-Acl -LiteralPath $path).Sddl | Should -Be $before
        }
        finally {
            Remove-Item -LiteralPath $path -Force
        }
    }
}
