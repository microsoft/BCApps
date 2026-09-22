<#
.SYNOPSIS
    List the fields of an AL table whose declaration does NOT mention a given guard.

.DESCRIPTION
    BC document tables protect themselves against edits to a posted/released document by calling
    a guard - conventionally TestStatusOpen() - from each field's OnValidate trigger. The guard is
    applied field by field, by hand, so coverage is uneven. This script reports which fields do
    not mention the guard, giving you a ranked list of Saboteur probe candidates.

    Use it to answer: "if I release this document, which fields will still let me change it?"

    IMPORTANT - this is a ONE-HOP TEXTUAL scan, so it BOTH over- and under-reports:

      * UNDER-reports guarding (false "unguarded"). The guard is often several hops away:
            Direct Unit Cost -> Validate("Line Discount %") -> ValidateLineDiscountPercent
                             -> TestStatusOpen -> TestField(Status, Status::Open)
        Guards also arrive via table triggers (OnInsert/OnDelete) and via the page rather than
        the table.

      * OVER-reports risk. Many unguarded fields are internal, FlowFields, or not on any page,
        so they are unreachable from the UI.

    Every "unguarded" row is therefore a HYPOTHESIS to test against the running product, never a
    finding. Confirm with a UI probe plus a SQL read-back before recording anything.

    THE 'DELIBERATE' COLUMN - READ THIS BEFORE RECORDING A SABOTEUR FINDING.

    A field can be editable on a released document BY DESIGN. BC's four document frameworks all
    contain fields whose OnValidate explicitly tests for Status::Released and then does extra
    work, e.g. Sales/Purchase/Transfer/Service "External Document No.":

        if (xRec."External Document No." <> "External Document No.") and (Status = Status::Released)
        then
            WhseSalesRelease.UpdateExternalDocNoForReleasedOrder(Rec);

    That field is unguarded on purpose: the author thought about the released case and wrote
    propagation logic for it. Reporting it as "edit accepted on a released order" is a FALSE
    POSITIVE, and this exact mistake produced three withdrawn findings before the check was
    automated here.

    The Deliberate column flags fields whose declaration mentions Status::Released (or a
    Released-aware helper). Treat Deliberate=True as "intended behaviour, do not report" unless
    you can show the propagation itself is wrong.

    Semantics matter too, even when Deliberate is False. "Vendor Invoice No." has no released
    branch, but its tooltip says it is the number of the document you RECEIVED FROM THE VENDOR and
    it is required at POSTING time - it cannot be known before release, so it must stay editable.
    Always read the tooltip before concluding.

.PARAMETER Table
    Path to the *.Table.al file.

.PARAMETER Guard
    Regex identifying the guard. Default 'TestStatusOpen'.

    WARNING - the default is only correct for the Sales, Purchase and Transfer frameworks.
    The guard IDIOM is framework-specific, and scanning with the wrong one returns a clean,
    plausible, completely wrong answer. Service Header scanned with the default reports
    0 of 139 fields guarded; the real figure is 6. Service never calls TestStatusOpen() and
    its status field is called "Release Status", not "Status":

        Sales / Purchase / Transfer   TestStatusOpen()
        Service                       TestField("Release Status", "Release Status"::Open)

    Before scanning an unfamiliar table, grep it for TestField(<status-ish field> and pass the
    idiom you find. Treat a 0% or 100% guarded result as a bug in your regex until proven
    otherwise - real tables always land somewhere in between.

    Note also that release status is not the only gate. Service guards its high-consequence
    fields on whether the document already HAS LINES (ServLineExists / ServItemLineExists),
    and often via a Confirm dialog rather than an Error - so the edit succeeds if the user
    answers Yes. This scanner does not see that class of guard at all.

.PARAMETER Guarded
    List the guarded fields instead of the unguarded ones.

.PARAMETER IncludeDeliberate
    Keep fields that explicitly handle Status::Released. They are excluded by default because
    they are intended behaviour and reporting them produces false positives.

.PARAMETER ExcludeFlowFields
    Skip FlowFields and FlowFilters, which are not directly editable and are usually noise.

.EXAMPLE
    .\Find-UnguardedFields.ps1 -Table ...\TransferLine.Table.al -ExcludeFlowFields

.EXAMPLE
    # Service uses a different status field AND a different idiom.
    .\Find-UnguardedFields.ps1 -Table ...\ServiceHeader.Table.al -ExcludeFlowFields -Guarded `
        -Guard 'Release Status"?,\s*"?Release Status"?::Open'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Table,
    [string]$Guard = 'TestStatusOpen',
    [switch]$Guarded,
    [switch]$IncludeDeliberate,
    [switch]$ExcludeFlowFields
)

if (-not (Test-Path $Table)) { throw "Table file not found: $Table" }

$lines = Get-Content -LiteralPath $Table

# Locate every field declaration. AL indents fields 8 spaces inside the fields{} block.
$starts = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s{8}field\((\d+);\s*"?([^";]+)"?;\s*(.*?)\s*\)') {
        $starts += , @($i, [int]$Matches[1], $Matches[2].Trim(), $Matches[3].Trim())
    }
}
if (-not $starts.Count) { throw "No field declarations found in $Table - is this an AL table?" }

$rows = for ($n = 0; $n -lt $starts.Count; $n++) {
    $s = $starts[$n][0]
    $e = if ($n -lt $starts.Count - 1) { $starts[$n + 1][0] - 1 } else { $lines.Count - 1 }
    $body = $lines[$s..$e] -join "`n"

    $isFlow = $body -match '(?m)^\s*(FieldClass\s*=\s*(FlowField|FlowFilter))'
    if ($ExcludeFlowFields -and $isFlow) { continue }

    [pscustomobject]@{
        Id          = $starts[$n][1]
        Field       = $starts[$n][2]
        Type        = $starts[$n][3]
        HasGuard    = [bool]($body -match $Guard)
        # Deliberate released-state handling: the author explicitly considered Status::Released.
        # See the header comment - this is the check that prevents false Saboteur findings.
        Deliberate  = [bool]($body -match 'Status::Released|ForReleasedOrder|Status\s*=\s*Status::Released')
        HasTooltip  = [bool]($body -match '(?m)^\s*ToolTip\s*=')
        HasValidate = [bool]($body -match 'trigger OnValidate')
        FlowField   = $isFlow
        Line        = $s + 1
    }
}

$total = @($rows).Count
$hit = @($rows | Where-Object HasGuard).Count
$deliberate = @($rows | Where-Object { -not $_.HasGuard -and $_.Deliberate })
$want = if ($Guarded) { $rows | Where-Object HasGuard } else { $rows | Where-Object { -not $_.HasGuard } }
if (-not $Guarded -and -not $IncludeDeliberate) { $want = $want | Where-Object { -not $_.Deliberate } }
$want = @($want)

Write-Host ""
Write-Host "Table  : $(Split-Path $Table -Leaf)"
Write-Host "Guard  : $Guard"
Write-Host "Fields : $total scanned, $hit mention the guard, $($total - $hit) do not"
if ($ExcludeFlowFields) { Write-Host "         (FlowFields/FlowFilters excluded)" }
Write-Host ""

if ($deliberate.Count -and -not $Guarded) {
    Write-Host "--- DELIBERATE RELEASED HANDLING ($($deliberate.Count)) - editable when released BY DESIGN, do NOT report ---"
    $deliberate | Sort-Object Id | Format-Table Id, Field, Line -AutoSize | Out-Host
    if (-not $IncludeDeliberate) { Write-Host "  (excluded from the list below; pass -IncludeDeliberate to keep them)`n" }
}

Write-Host "--- $(if ($Guarded) {'GUARDED'} else {'CANDIDATES - no guard, no deliberate released handling'}) ($($want.Count)) ---"

# Fields that have their own OnValidate but no guard are the most interesting: someone wrote
# validation logic for them and did not include the status check.
$want |
    Sort-Object @{ e = 'HasValidate'; Descending = $true }, Id |
    Format-Table Id, Field, Type, HasValidate, HasTooltip, Line -AutoSize | Out-Host

Write-Host "Ranked with HasValidate=True first: those fields have bespoke validation that omits"
Write-Host "the guard, so they are the strongest probe candidates."
Write-Host "One-hop scan - every row is a HYPOTHESIS. Confirm in the UI and read back with SQL,"
Write-Host "and read the field's tooltip: the business meaning may require post-release editing."
