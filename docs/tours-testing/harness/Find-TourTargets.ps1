<#
.SYNOPSIS
  Metadata-driven tour target finder.

  BC pages and tables are generated from metadata. The platform enforces some
  constraints for free (MinValue, MaxValue, NotBlank, TableRelation, Editable).
  Anything a ToolTip *claims* that metadata does not declare must be enforced by
  hand in AL - or not at all. Those are the interesting places to tour.

.PARAMETER Path
  Root folder to scan (an app or layer).
#>
param(
    [Parameter(Mandatory)][string]$Path,
    [int]$Top = 40,
    [switch]$PassThru
)

# Words in a ToolTip that assert a constraint the user can try to violate.
$claimWords = 'must |cannot |can not |only |never |always |required|mandatory|not be |no longer|prevent|at least|greater than|less than|positive|negative|before you|read-only|automatically'

$Path = (Resolve-Path $Path).Path

$results = New-Object System.Collections.Generic.List[object]

Get-ChildItem -Path $Path -Recurse -Include *.Table.al, *.TableExt.al -File | ForEach-Object {
    $file = $_
    $text = Get-Content $file.FullName -Raw

    # Split on field declarations so each chunk is one field's metadata block.
    $matches = [regex]::Matches($text, '(?ms)^\s*field\((\d+);\s*(.+?);\s*(.+?)\)\s*\r?\n\s*\{(.*?)^\s{8}\}')
    foreach ($m in $matches) {
        $body = $m.Groups[4].Value
        $tip  = ([regex]::Match($body, "ToolTip\s*=\s*'(.*?)';")).Groups[1].Value

        $o = [pscustomobject]@{
            File          = $file.FullName.Substring($Path.Length).TrimStart('\')
            FieldNo       = [int]$m.Groups[1].Value
            Field         = $m.Groups[2].Value.Trim()
            Type          = $m.Groups[3].Value.Trim()
            MinValue      = ([regex]::Match($body, 'MinValue\s*=\s*([^;]+);')).Groups[1].Value
            MaxValue      = ([regex]::Match($body, 'MaxValue\s*=\s*([^;]+);')).Groups[1].Value
            NotBlank      = $body -match 'NotBlank\s*=\s*true'
            TableRelation = $body -match 'TableRelation\s*='
            Editable      = ([regex]::Match($body, 'Editable\s*=\s*([^;]+);')).Groups[1].Value
            HasOnValidate = $body -match 'trigger OnValidate'
            ToolTip       = $tip
            Claim         = ($tip -match $claimWords)
            Obsolete      = $body -match 'ObsoleteState\s*=\s*Pending'
        }
        $results.Add($o)
    }
}

$all = $results
Write-Host ""
Write-Host "Scanned $($all.Count) fields under $Path" -ForegroundColor Cyan
Write-Host ""

# --- Class 1: ToolTip asserts a constraint, but no metadata declares it. ------
$unbacked = $all | Where-Object {
    $_.Claim -and -not $_.MinValue -and -not $_.MaxValue -and
    -not $_.NotBlank -and -not $_.TableRelation -and -not $_.Obsolete
}
Write-Host "[1] ToolTip claims a rule that metadata does NOT enforce  ($($unbacked.Count))" -ForegroundColor Yellow
Write-Host "    -> tour these: the rule is hand-written in AL, or absent." -ForegroundColor DarkGray
$unbacked | Sort-Object { -not $_.HasOnValidate } |
    Select-Object -First $Top File, Field, Type, HasOnValidate, ToolTip | Format-Table -Wrap | Out-Host

# --- Class 2: numeric fields with no bounds at all. ---------------------------
$unbounded = $all | Where-Object {
    $_.Type -match '^(Decimal|Integer|BigInteger)' -and
    -not $_.MinValue -and -not $_.MaxValue -and -not $_.Obsolete
}
Write-Host "[2] Numeric fields with no MinValue/MaxValue  ($($unbounded.Count))" -ForegroundColor Yellow
Write-Host "    -> negative / huge / zero values reach AL untouched." -ForegroundColor DarkGray
$unbounded | Select-Object -First $Top File, Field, Type, HasOnValidate | Format-Table | Out-Host

# --- Class 3: bounded fields - the platform guarantees these. -----------------
$bounded = $all | Where-Object { $_.MinValue -or $_.MaxValue }
Write-Host "[3] Fields the platform bounds for you  ($($bounded.Count))" -ForegroundColor Green
Write-Host "    -> do NOT spend tour time here; behaviour is generic." -ForegroundColor DarkGray
$bounded | Select-Object -First 15 File, Field, MinValue, MaxValue | Format-Table | Out-Host

if ($PassThru) { return $all }

