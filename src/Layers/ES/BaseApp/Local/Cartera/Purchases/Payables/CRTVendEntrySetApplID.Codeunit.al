// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.ReceivablesPayables;

codeunit 7000107 "CRTVendEntrySetApplID"
{
    var
        CannotBeAppliedErr: Label '%1 cannot be applied, since it is included in a bill group.', Comment = '%1 = Description';
        CannotBeAppliedTryAgainErr: Label '%1 cannot be applied, since it is included in a bill group. Remove it from its bill group and try again.', Comment = '%1 = Description';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vend. Entry-SetAppl.ID", 'OnBeforeUpdateVendLedgerEntry', '', false, false)]
    local procedure OnBeforeUpdateVendLedgerEntry(var TempVendLedgEntry: Record "Vendor Ledger Entry" temporary; ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50]; VendEntryApplID: Code[50]; var IsHandled: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CarteraSetup: Record "Cartera Setup";
        CarteraDoc: Record "Cartera Doc.";
    begin
        VendorLedgerEntry.Copy(TempVendLedgEntry);

        if VendorLedgerEntry."Document Situation" = VendorLedgerEntry."Document Situation"::"Posted BG/PO" then
            Error(CannotBeAppliedErr, VendorLedgerEntry.Description);
        if ApplyingVendLedgEntry."Document Situation" = ApplyingVendLedgEntry."Document Situation"::"Posted BG/PO" then
            Error(CannotBeAppliedErr, ApplyingVendLedgEntry.Description);

        if not CarteraSetup.ReadPermission then
            exit;

        if not (VendorLedgerEntry."Document Type" in [VendorLedgerEntry."Document Type"::Bill, VendorLedgerEntry."Document Type"::Invoice]) then
            exit;

        if CarteraDoc.Get(CarteraDoc.Type::Payable, VendorLedgerEntry."Entry No.") then
            if CarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                Error(CannotBeAppliedTryAgainErr, VendorLedgerEntry.Description);
    end;
}
