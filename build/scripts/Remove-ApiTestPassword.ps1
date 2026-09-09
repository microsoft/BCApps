Param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_.-]*$')]
    [string]$ContainerName,
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

$ErrorActionPreference = 'Stop'

if ((Split-Path -Path $FilePath -Leaf) -ne 'ApiTestPassword') {
    throw 'API test credential cleanup requires the exact ApiTestPassword file.'
}
if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
    return
}

# Workflow cancellation can leave server-side test workers alive. End all consumers
# before deleting their shared credential, including when the build step was killed.
$containerIds = @(docker container ls --all --filter "name=^/$([regex]::Escape($ContainerName))$" --format '{{.ID}}')
if ($LASTEXITCODE -ne 0) {
    throw 'Could not determine whether the API test container still exists.'
}
if ($containerIds.Count -gt 1) {
    throw 'API test credential cleanup matched more than one container.'
}
if ($containerIds.Count -eq 1) {
    docker stop --time 30 $containerIds[0] | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not stop API test consumers; leaving credential removal to container teardown.'
    }
}

# The recorded mount path remains usable for stopped or already-removed containers.
Remove-Item -LiteralPath $FilePath -Force -ErrorAction Stop
