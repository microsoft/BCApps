param([hashtable]$Parameters)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Producer.psm1')
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
$context = Get-ExpandedContext
Start-Transcript -Path (Join-Path $context.output 'lane-original-transcript.log') -Append | Out-Null
try { Invoke-ExpandedLane -Parameters $Parameters } finally { Stop-Transcript | Out-Null }
