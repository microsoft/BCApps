$ErrorActionPreference = 'Stop'
$c = Get-Content "$env:USERPROFILE\.bc-tours\BCApps-DropTrack-credentials.json" -Raw | ConvertFrom-Json
Import-Module BcContainerHelper -DisableNameChecking -WarningAction SilentlyContinue | Out-Null
$cred = New-Object PSCredential($c.user, (ConvertTo-SecureString $c.password -AsPlainText -Force))
$proj = 'C:\ProgramData\BcContainerHelper\Extensions\BCApps-DropTrack\dsprobe'

# Publishing the SAME version is a silent no-op: the old code stays installed and the
# probe reports stale behaviour as product behaviour. Always bump the revision.
$j = Get-Content "$proj\app.json" -Raw | ConvertFrom-Json
$v = [version]$j.version
$j.version = "{0}.{1}.{2}.{3}" -f $v.Major, $v.Minor, $v.Build, ($v.Revision + 1)
$j | ConvertTo-Json -Depth 10 | Set-Content "$proj\app.json"
Write-Host "version -> $($j.version)" -ForegroundColor Cyan

$app = Compile-AppInBcContainer -containerName BCApps-DropTrack -credential $cred -appProjectFolder $proj -appOutputFolder "$proj\out"
Publish-BcContainerApp -containerName BCApps-DropTrack -credential $cred -appFile $app -skipVerification -sync -install -upgrade
Write-Host "redeployed $($j.version)" -ForegroundColor Green
