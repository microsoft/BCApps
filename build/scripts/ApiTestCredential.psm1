function New-ApiTestPasswordFileStream {
    param([Parameter(Mandatory = $true)][string]$FilePath)

    $ErrorActionPreference = 'Stop'
    $security = [System.Security.AccessControl.FileSecurity]::new()
    $security.SetAccessRuleProtection($true, $false)
    $writerSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $entries = @(
        @{ Sid = 'S-1-5-18'; Rights = [System.Security.AccessControl.FileSystemRights]::FullControl }
        @{ Sid = 'S-1-5-20'; Rights = [System.Security.AccessControl.FileSystemRights]::Read }
        @{ Sid = 'S-1-5-32-544'; Rights = [System.Security.AccessControl.FileSystemRights]::FullControl }
    )
    if ($writerSid -notin @('S-1-5-18', 'S-1-5-32-544')) {
        # The host identity writes the credential and deletes it during cleanup; it needs
        # neither ReadData nor FullControl. Container service identities retain their access.
        $entries += @{
            Sid = $writerSid
            Rights = [System.Security.AccessControl.FileSystemRights]'Write, Delete'
        }
    }
    foreach ($entry in $entries) {
        $security.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new(
            [System.Security.Principal.SecurityIdentifier]::new($entry.Sid),
            $entry.Rights,
            [System.Security.AccessControl.AccessControlType]::Allow))
    }

    # Supply the protected DACL to CreateFile itself, not Set-Acl after creation.
    # CreateNew also refuses to follow or overwrite a pre-existing credential file.
    if ($PSVersionTable.PSEdition -eq 'Core') {
        return [System.IO.FileSystemAclExtensions]::Create(
            [System.IO.FileInfo]::new($FilePath), [System.IO.FileMode]::CreateNew,
            [System.Security.AccessControl.FileSystemRights]::Write, [System.IO.FileShare]::None,
            4096, [System.IO.FileOptions]::None, $security)
    }
    return [System.IO.FileStream]::new(
        $FilePath, [System.IO.FileMode]::CreateNew,
        [System.Security.AccessControl.FileSystemRights]::Write, [System.IO.FileShare]::None,
        4096, [System.IO.FileOptions]::None, $security)
}

<#
.SYNOPSIS
    Creates the API test credential directly in the container's shared my mount.
.DESCRIPTION
    Registers workflow cleanup before atomically creating a new file with a protected
    DACL. No plaintext staging copies are made. SYSTEM and Administrators retain full
    access, NetworkService can read, and the host writer can write and delete.
    An existing file or unresolved mount is an error, including outside CI. Workflow
    cleanup (or local container teardown) must end consumers before removing the file.
#>
function Write-ApiTestPassword {
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_.-]*$')]
        [string]$ContainerName,
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential
    )

    $ErrorActionPreference = 'Stop'
    $myFolders = @((Get-BcContainerSharedFolders -containerName $ContainerName).GetEnumerator() |
        Where-Object { $_.Value.TrimEnd('\') -eq 'C:\Run\my' })
    if ($myFolders.Count -ne 1) {
        throw "Cannot resolve the API test credential's container mount."
    }
    $filePath = Join-Path $myFolders[0].Key 'ApiTestPassword'
    if ($env:GITHUB_ENV) {
        # Persist cleanup before creation, including for setup failure or cancellation.
        Add-Content -LiteralPath $env:GITHUB_ENV -Encoding UTF8 -Value "BCAppsApiTestPasswordPath=$filePath" -ErrorAction Stop
    }

    $created = $false
    $bytes = $null
    try {
        # Write directly to the shared mount. Copy-FileToBcContainer would introduce
        # another host staging copy with inherited permissions.
        $stream = New-ApiTestPasswordFileStream -FilePath $filePath
        $created = $true
        try {
            $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Credential.GetNetworkCredential().Password)
            $stream.Write($bytes, 0, $bytes.Length)
        }
        finally {
            if ($null -ne $bytes) { [Array]::Clear($bytes, 0, $bytes.Length) }
            $stream.Dispose()
        }
    }
    catch {
        $originalError = $_
        if ($created) {
            try {
                & (Join-Path $PSScriptRoot 'Remove-ApiTestPassword.ps1') -ContainerName $ContainerName -FilePath $filePath
            }
            catch {
                Write-Warning 'Could not clean up the API test credential after setup failed; container teardown is still required.'
            }
        }
        throw $originalError
    }
}

Export-ModuleMember -Function Write-ApiTestPassword
