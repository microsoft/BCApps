<#
.SYNOPSIS
    Differential guard scan across two parallel AL tables (e.g. Sales vs Purchase).

.DESCRIPTION
    BC contains near-duplicate subsystems that were written from a shared template and are
    maintained separately, so they drift. This script extracts, for every field in two tables,
    whether the field's declaration mentions a given guard (default: TestStatusOpen), then joins
    the two tables on an explicit list of analogous field pairs and reports the divergences.

    A divergence means parallel code disagrees: at least one side is likely unintended, and you
    do not need a specification to justify investigating it. An AGREEMENT is equally useful - it
    predicts that a finding on one side generalises to the other.

    IMPORTANT - two limits, both learned the hard way:

    1. Join on EXPLICIT pairs, never on a regex rename. 'Purchase Header' contains BOTH
       'Buy-from Vendor No.' (guarded) and 'Sell-to Customer No.' (the drop-shipment customer,
       unguarded). A blanket rename collapsed both to one key and silently reported the guarded
       field as unguarded.

    2. This is a ONE-HOP scan and therefore UNDER-PREDICTS guarding. In AL a guard is often two
       or three hops away:
           Direct Unit Cost -> Validate("Line Discount %") -> ValidateLineDiscountPercent
                            -> TestStatusOpen -> TestField(Status, Status::Open)
       Guards also come from table triggers (OnInsert/OnDelete). Treat every "unguarded" result
       as a hypothesis to test against the running product, never as a conclusion.

.PARAMETER LeftTable
    Path to the first *.Table.al file.

.PARAMETER RightTable
    Path to the second *.Table.al file.

.PARAMETER Pairs
    Ordered hashtable of <left field name> = <right field name>. Omit to use the built-in
    Sales/Purchase document pairs.

.PARAMETER Guard
    Regex identifying the guard to look for. Default 'TestStatusOpen'.

.PARAMETER All
    Also list pairs that agree, not just the divergences.

.EXAMPLE
    .\Find-TourDrift.ps1 -LeftTable ...\SalesLine.Table.al -RightTable ...\PurchaseLine.Table.al
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$LeftTable,
    [Parameter(Mandatory)][string]$RightTable,
    [System.Collections.IDictionary]$Pairs,
    [string]$Guard = 'TestStatusOpen',
    [switch]$All
)

function Get-FieldGuards {
    param([string]$Path, [string]$Guard)
    if (-not (Test-Path $Path)) { throw "Table file not found: $Path" }
    $lines = Get-Content -LiteralPath $Path
    $starts = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s{8}field\((\d+);\s*"?([^";]+)"?;') {
            $starts += , @($i, $Matches[1], $Matches[2])
        }
    }
    $map = [ordered]@{}
    for ($n = 0; $n -lt $starts.Count; $n++) {
        $s = $starts[$n][0]
        $e = if ($n -lt $starts.Count - 1) { $starts[$n + 1][0] - 1 } else { $lines.Count - 1 }
        $map[$starts[$n][2]] = [bool](($lines[$s..$e] -join "`n") -match $Guard)
    }
    $map
}

# Built-in analogue pairs for the Sales <-> Purchase document family.
if (-not $Pairs) {
    $Pairs = [ordered]@{
        'Sell-to Customer No.'      = 'Buy-from Vendor No.'
        'Bill-to Customer No.'      = 'Pay-to Vendor No.'
        'Salesperson Code'          = 'Purchaser Code'
        'External Document No.'     = 'Vendor Invoice No.'
        'Shipment Date'             = 'Expected Receipt Date'
        'Qty. to Ship'              = 'Qty. to Receive'
        'Unit Price'                = 'Direct Unit Cost'
        'Your Reference'            = 'Your Reference'
        'Posting Date'              = 'Posting Date'
        'Due Date'                  = 'Due Date'
        'Order Date'                = 'Order Date'
        'Payment Terms Code'        = 'Payment Terms Code'
        'Payment Method Code'       = 'Payment Method Code'
        'Currency Code'             = 'Currency Code'
        'Location Code'             = 'Location Code'
        'Prices Including VAT'      = 'Prices Including VAT'
        'Assigned User ID'          = 'Assigned User ID'
        'VAT Base Discount %'       = 'VAT Base Discount %'
        'Responsibility Center'     = 'Responsibility Center'
        'Shipment Method Code'      = 'Shipment Method Code'
        'Quantity'                  = 'Quantity'
        'Type'                      = 'Type'
        'No.'                       = 'No.'
        'Description'               = 'Description'
        'Line Discount %'           = 'Line Discount %'
        'Line Discount Amount'      = 'Line Discount Amount'
        'Qty. to Invoice'           = 'Qty. to Invoice'
        'Unit of Measure Code'      = 'Unit of Measure Code'
        'Variant Code'              = 'Variant Code'
        'Bin Code'                  = 'Bin Code'
        'Prepayment %'              = 'Prepayment %'
        'Job No.'                   = 'Job No.'
        'Gen. Bus. Posting Group'   = 'Gen. Bus. Posting Group'
        'VAT Prod. Posting Group'   = 'VAT Prod. Posting Group'
        'Shortcut Dimension 1 Code' = 'Shortcut Dimension 1 Code'
    }
}

$left = Get-FieldGuards -Path $LeftTable  -Guard $Guard
$right = Get-FieldGuards -Path $RightTable -Guard $Guard

$leftName = Split-Path $LeftTable  -Leaf
$rightName = Split-Path $RightTable -Leaf

Write-Host ""
Write-Host "Guard pattern : $Guard"
Write-Host ("{0,-34} {1} of {2} fields" -f $leftName, ($left.Values  | Where-Object { $_ }).Count, $left.Count)
Write-Host ("{0,-34} {1} of {2} fields" -f $rightName, ($right.Values | Where-Object { $_ }).Count, $right.Count)

$rows = foreach ($k in $Pairs.Keys) {
    $v = $Pairs[$k]
    if ($left.Contains($k) -and $right.Contains($v)) {
        [pscustomobject]@{
            Left      = $k
            Right     = $v
            LeftGuard = $left[$k]
            RightGuard = $right[$v]
            Diverges  = ($left[$k] -ne $right[$v])
        }
    }
}

# Surface what the join dropped - an unmatched pair is a silent blind spot.
$dropped = foreach ($k in $Pairs.Keys) {
    $v = $Pairs[$k]
    if (-not ($left.Contains($k) -and $right.Contains($v))) { "$k <-> $v" }
}

$div = @($rows | Where-Object Diverges)
Write-Host ""
Write-Host "--- DIVERGENT ($($div.Count)) - parallel code disagrees, investigate each ---"
if ($div.Count) { $div | Format-Table Left, Right, LeftGuard, RightGuard -AutoSize | Out-Host }
else { Write-Host "  (none)" }

if ($All) {
    $agree = @($rows | Where-Object { -not $_.Diverges })
    Write-Host "--- AGREEING ($($agree.Count)) - a finding on one side should generalise ---"
    $agree | Format-Table Left, Right, LeftGuard, RightGuard -AutoSize | Out-Host
}

if ($dropped) {
    Write-Host "--- NOT MATCHED ($($dropped.Count)) - field missing from one table, join blind spot ---"
    $dropped | ForEach-Object { Write-Host "  $_" }
}

Write-Host ""
Write-Host "Reminder: one-hop scan. 'unguarded' is a hypothesis - confirm against the running product."
