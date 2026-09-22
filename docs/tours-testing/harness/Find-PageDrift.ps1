<#
.SYNOPSIS
    Differential scan of Editable/Enabled properties across several PAGES that share one table.

.DESCRIPTION
    Find-TourDrift.ps1 compares two parallel TABLES. That assumption breaks for document types:
    Quote, Order, Invoice, Credit Memo, Blanket Order and Return Order all share ONE table
    ("Sales Header" 36), discriminated by a Document Type enum. A table differential across them
    is vacuous by construction, because there is only one set of fields.

    Everything that distinguishes them lives in the pages. This script builds the matrix from
    page field declarations: for each field it records the Editable/Enabled expression per page,
    groups identical expressions under a letter, and prints only the rows where the letters
    disagree.

        FIELD                          Q O I C B R
        Ship-to Address                L L L . L -
        Customer Posting Group         . F F F . F

        .  field is absent from that page
        -  field is present with no Editable/Enabled property
        A..Z  distinct property expressions; the same letter means the identical expression

    Read the SHAPES, not the cells:
      L L L . L -   four agree, one omits, one unguarded  -> 1-vs-5 outlier, the drift signature
      . F F F . F   absent exactly where meaningless      -> a semantic boundary, not drift

    A divergence tells you WHERE to look, never WHO is wrong. Promote it to a finding only when
    you can name the harm. Note that git history cannot settle intent in this repo - BCApps is
    populated by squashed sync commits, so `git log -S` reports the import commit for every page
    identically. See sections 9.11 and 10.2 of exploratory-tours.instructions.md.

.PARAMETER Page
    Page files to compare, in the column order you want. Accepts paths or globs.

.PARAMETER Label
    Optional one-or-two character column labels, in the same order as -Page. Defaults to the
    first letter of each file name.

.PARAMETER All
    Print every field, not only the divergent ones.

.EXAMPLE
    # The six sales document types.
    $d = 'src/Layers/W1/BaseApp/Sales/Document'
    .\Find-PageDrift.ps1 -Label Q,O,I,C,B,R -Page `
        "$d/SalesQuote.Page.al","$d/SalesOrder.Page.al","$d/SalesInvoice.Page.al", `
        "$d/SalesCreditMemo.Page.al","$d/BlanketSalesOrder.Page.al","$d/SalesReturnOrder.Page.al"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Page,
    [string[]]$Label,
    [switch]$All
)

$files = @($Page | ForEach-Object { Get-Item -Path $_ })
if (-not $files) { throw "no page files matched" }

if ($Label -and $Label.Count -ne $files.Count) {
    throw "-Label has $($Label.Count) entries but -Page matched $($files.Count) files"
}
$labels = if ($Label) { $Label } else { $files | ForEach-Object { $_.BaseName.Substring(0, 1) } }

# field("Caption"; Rec."Field Name") - then look ahead inside that field's property block only.
# Stop at the next field(, so a property belonging to the following field is never attributed here.
$map = [ordered]@{}
for ($f = 0; $f -lt $files.Count; $f++) {
    $lines = Get-Content -LiteralPath $files[$f].FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch '^\s*field\("?([^";]+?)"?;\s*Rec\.') { continue }
        $name = $Matches[1]
        $prop = '(none)'
        for ($j = $i + 1; $j -lt [Math]::Min($i + 25, $lines.Count); $j++) {
            if ($lines[$j] -match '^\s*field\(') { break }
            if ($lines[$j] -match '^\s*(Editable|Enabled)\s*=\s*(.+?);') { $prop = $Matches[2].Trim(); break }
        }
        if (-not $map.Contains($name)) { $map[$name] = @{} }
        $map[$name][$labels[$f]] = $prop
    }
}

$legend = [ordered]@{}
$next = 65
$rows = foreach ($name in ($map.Keys | Sort-Object)) {
    $v = $map[$name]
    $cells = foreach ($l in $labels) {
        if (-not $v.ContainsKey($l)) { '.' }
        elseif ($v[$l] -eq '(none)') { '-' }
        else {
            if (-not $legend.Contains($v[$l])) { $legend[$v[$l]] = [string][char]$next; $next++ }
            $legend[$v[$l]]
        }
    }
    if ($All -or @($cells | Select-Object -Unique).Count -gt 1) {
        [pscustomobject]@{ Field = $name; Cells = ($cells -join ' ') }
    }
}

"Pages   : {0}" -f (($files | ForEach-Object { $_.BaseName }) -join ', ')
"Fields  : {0} distinct, {1} shown" -f $map.Count, @($rows).Count
"Key     : '.' absent   '-' no Editable/Enabled property   A..Z distinct expressions"
""
"{0,-32} {1}" -f 'FIELD', ($labels -join ' ')
foreach ($r in $rows) { "{0,-32} {1}" -f $r.Field, $r.Cells }

if ($legend.Count) {
    "`n--- LEGEND ---"
    foreach ($k in $legend.Keys) {
        $short = if ($k.Length -gt 110) { $k.Substring(0, 107) + '...' } else { $k }
        "{0}  {1}" -f $legend[$k], $short
    }
}

"`nA divergence tells you WHERE to look, not WHO is wrong. Confirm in the UI, read back with SQL,"
"and check whether the split follows a business boundary before calling it drift."
