<#
  SOAP driver for codeunit 50150 "Tour XL Probe" in the tour container.
  PS7 traps handled: -AllowUnencryptedAuthentication, and the SOAP fault body
  lives in $_.ErrorDetails.Message (HttpResponseMessage has no GetResponseStream).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Method,
    [hashtable] $Params = @{},
    [string] $CredsPath = "$env:USERPROFILE\.bc-tours\BCApps-ExcelRep-credentials.json",
    [string] $Company = 'CRONUS International Ltd.',
    [string] $ServiceName = 'TourXLProbe'
)

$ErrorActionPreference = 'Stop'
$c = Get-Content $CredsPath -Raw | ConvertFrom-Json
$cred = New-Object PSCredential($c.user, (ConvertTo-SecureString $c.password -AsPlainText -Force))

$ns = "urn:microsoft-dynamics-schemas/codeunit/$ServiceName"
$url = "http://$($c.containerName):7047/BC/WS/$([uri]::EscapeDataString($Company))/Codeunit/$ServiceName"

$inner = ($Params.GetEnumerator() | ForEach-Object {
    $v = $_.Value
    if ($v -is [bool]) { $v = $v.ToString().ToLower() }
    "<{0}>{1}</{0}>" -f $_.Key, [System.Security.SecurityElement]::Escape([string]$v)
}) -join ''

$envelope = @"
<Soap:Envelope xmlns:Soap="http://schemas.xmlsoap.org/soap/envelope/">
  <Soap:Body><$Method xmlns="$ns">$inner</$Method></Soap:Body>
</Soap:Envelope>
"@

try {
    $resp = Invoke-WebRequest -Uri $url -Method Post -Body $envelope `
        -ContentType 'text/xml; charset=utf-8' `
        -Headers @{ SOAPAction = "$ns#$Method" } `
        -Credential $cred -AllowUnencryptedAuthentication
    $x = [xml]$resp.Content
    $result = $x.Envelope.Body.ChildNodes[0]
    if ($result -and $result.HasChildNodes) { $result.ChildNodes[0].InnerText } else { '' }
}
catch {
    # The real fault is here, not in $_.Exception.Response.
    $body = $_.ErrorDetails.Message
    if ($body) { Write-Host "SOAP FAULT:`n$body" -ForegroundColor Red }
    throw
}
