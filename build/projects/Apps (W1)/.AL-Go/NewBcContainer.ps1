Param(
    [Hashtable]$parameters
)

$script = Join-Path $PSScriptRoot "../../../scripts/NewBcContainer.ps1" -Resolve
. $script -parameters $parameters -AppsToUnpublish @("E-Document Connector - Avalara","E-Document Connector - Avalara Tests","Shopify Connector","Shopify Connector Test","Subscription Billing","Subscription Billing Demo Data","Subscription Billing Test")