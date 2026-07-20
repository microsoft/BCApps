# Vendor matching by name only with draft-page infotip

**Date:** 2026-07-20
**Area:** E-Document Core (W1) — inbound purchase draft, vendor resolution
**Status:** Approved design

## Problem

When an inbound e-document is prepared into a purchase draft, the framework
resolves the buy-from vendor. The name/address matcher
(`EDocumentImportHelper.FindVendorByNameAndAddressWithNotification`) only
returns a vendor when **both** the name and the address match. If the name
matches but the address does not, the candidate is silently dropped and the
procedure returns an empty vendor number, so the draft is left without a
vendor even though a strong name match existed.

The procedure already contains dormant plumbing for this case: it detects the
name-only candidate, sets a telemetry flag, and can raise an
`E-Document Notification` ("Vendor matched by name but not by address"). But
the notification is never triggered, because the only public entry point
`FindVendorByNameAndAddress` always passes `EDocEntryNoForNotification = 0`.
The name-only candidate is therefore never accepted and never surfaced.

## Goal

On the V2 purchase draft path, **accept a vendor matched by name only** and
**highlight the `Vendor No.` field** on the draft page with an activity-log
infotip explaining that the address did not match — so the user can review and
correct the assignment.

## Scope decisions

- **Decision 1 = A:** Only the V2 draft path (`EDocProviders.GetVendor`)
  accepts name-only matches. The ~9 country format importers (PEPPOL BIS 3.0,
  ZUGFeRD, XRechnung, FacturX, Factura-E, OIOUBL, PINT A-NZ, PEPPOL DED
  pre-mapping) keep today's strict name+address behavior. This avoids a
  cross-country behavior change, and the infotip only exists on the draft page
  anyway.
- **Decision 2 = X:** Replace the dead notification. Remove the never-fired
  notification wiring from the matcher. The infotip supersedes the pop-up
  notification.

## Chosen mechanism: activity-log infotip

The purchase draft page renders `Activity Log Builder` entries as field-level
infotips. The existing precedent is
`EDoc Prepare Purch. Draft.ComputeAndApplyVATAmountDifference`, which logs an
entry on `E-Document Purchase Header` / `FieldNo("Total VAT")` /
`Header.SystemId` and shows an infotip on the **Total VAT** field.

We apply the same pattern to the **Vendor No.** field
(`E-Document Purchase Header."[BC] Vendor No."`).

## Design

### 1. Helper refactor — `EDocumentImportHelper.Codeunit.al`

Extract the matching loop into a private helper:

```al
local procedure FindBestVendorMatchByNameAndAddress(VendorName: Text; VendorAddress: Text; var MatchedByAddress: Boolean): Code[20]
```

Behavior:
- Iterate vendors (existing key/loading). For each, compute `NameNearness`;
  compute `AddressNearness` (an empty `VendorAddress` counts as matched, as
  today).
- If name matches and address matches → return that vendor,
  `MatchedByAddress := true`.
- Else if name matches and no full match is found by end of loop → return the
  **first** name-only candidate, `MatchedByAddress := false`, and keep the
  telemetry `EDocImpSessionTelemetry.SetBool('Vendor Matched By Name Not Address', true)`.
- Else → return `''`, `MatchedByAddress := false`.

Public entry points:
- `FindVendorByNameAndAddress(VendorName: Text; VendorAddress: Text): Code[20]`
  — legacy, unchanged semantics. Calls the internal; returns the vendor only
  if `MatchedByAddress`, otherwise `''`. Used by the country format importers.
- `FindVendorByNameAndAddress(VendorName: Text; VendorAddress: Text; var MatchedByAddress: Boolean): Code[20]`
  — new overload used by the V2 path; returns the best candidate and the flag.

Remove:
- `FindVendorByNameAndAddressWithNotification` and its
  `EDocEntryNoForNotification` parameter.
- The `EDocumentNotification.AddVendorMatchedByNameNotAddressNotification`
  call inside the matcher.

Keep: telemetry, `FindCustomerByNameAndAddress` (untouched).

### 2. V2 draft path — `EDocProviders.GetVendor`

Replace the current call:

```al
if Vendor.Get(EDocumentImportHelper.FindVendorByNameAndAddress(
        EDocumentPurchaseHeader."Vendor Company Name",
        EDocumentPurchaseHeader."Vendor Address",
        MatchedByAddress)) then begin
    if MatchedByAddress then
        EDocImpSessionTelemetry.SetText('Vendor Match Method', 'Name and Address')
    else begin
        LogVendorMatchedByNameOnlyInfotip(EDocumentPurchaseHeader);
        EDocImpSessionTelemetry.SetText('Vendor Match Method', 'Name Only');
    end;
    exit;
end;
```

New local procedure (logs immediately, like the VAT infotip — no activity-log
session needed; the header already exists so its `SystemId` is stable):

```al
local procedure LogVendorMatchedByNameOnlyInfotip(EDocumentPurchaseHeader: Record "E-Document Purchase Header")
var
    ActivityLog: Codeunit "Activity Log Builder";
    VendorMatchedByNameOnlyMsg: Label 'Vendor was matched by name only. The address on the document does not match this vendor.';
begin
    ActivityLog
        .Init(Database::"E-Document Purchase Header",
              EDocumentPurchaseHeader.FieldNo("[BC] Vendor No."),
              EDocumentPurchaseHeader.SystemId)
        .SetExplanation(VendorMatchedByNameOnlyMsg)
        .SetType(Enum::"Activity Log Type"::"AL")
        .Log();
end;
```

Note: `GetVendor` returns the `Vendor` record and `PrepareDraft` assigns
`"[BC] Vendor No."` afterward. The infotip binds to the field by
(table, field no, header SystemId) and is independent of the field value, so
logging before assignment is correct.

### 3. Notification cleanup

- Remove the now-unused
  `E-Document Notification.AddVendorMatchedByNameNotAddressNotification`
  procedure.
- Leave the rest of the `E-Document Notification` codeunit, table, enum type,
  My Notifications registration, and `SendPurchaseDocumentDraftNotifications`
  page call in place (generic plumbing; pruning further is optional and out of
  scope).

## Out of scope / unchanged

- The 9 country format importers and the legacy V1 vendor resolution.
- `FindCustomerByNameAndAddress`.
- `E-Document Notification` table / enum / page wiring (kept).

## Testing

Unit tests for the matcher:
- Full name+address match → returns vendor, `MatchedByAddress = true`.
- Name matches, address differs → returns the name-only candidate,
  `MatchedByAddress = false`.
- No name match → returns `''`.
- Empty document address → treated as address-matched (`MatchedByAddress = true`).
- Legacy `FindVendorByNameAndAddress` (2-arg) still returns `''` on a
  name-only match (no behavior change for importers).

Draft-flow test:
- Prepare a draft where the document vendor name matches an existing vendor but
  the address differs; assert the draft's `"[BC] Vendor No."` is assigned and
  an `Activity Log` entry exists for `E-Document Purchase Header` /
  `FieldNo("[BC] Vendor No.")` / header `SystemId`.
