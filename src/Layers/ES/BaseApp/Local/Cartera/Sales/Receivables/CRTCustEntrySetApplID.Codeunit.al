// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.ReceivablesPayables;

codeunit 7000113 "CRTCustEntrySetApplID"
{
    var
        CannotBeAppliedErr: Label '%1 cannot be applied, since it is included in a bill group.', Comment = '%1 = Description';
        CannotBeAppliedTryAgainErr: Label '%1 cannot be applied, since it is included in a bill group. Remove it from its bill group and try again.', Comment = '%1 = Description';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cust. Entry-SetAppl.ID", 'OnBeforeUpdateCustLedgerEntry', '', false, false)]
    local procedure OnBeforeUpdateCustLedgerEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]; var IsHandled: Boolean; var CustEntryApplID: Code[50])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CarteraDoc: Record "Cartera Doc.";
        CarteraSetup: Record "Cartera Setup";
    begin
        CustLedgerEntry.Copy(TempCustLedgerEntry);

        if CustLedgerEntry."Document Situation" = CustLedgerEntry."Document Situation"::"Posted BG/PO" then
            Error(CannotBeAppliedErr, CustLedgerEntry.Description);
        if ApplyingCustLedgerEntry."Document Situation" = ApplyingCustLedgerEntry."Document Situation"::"Posted BG/PO" then
            Error(CannotBeAppliedErr, ApplyingCustLedgerEntry.Description);

        if not CarteraSetup.ReadPermission then
            exit;

        if not (CustLedgerEntry."Document Type" in [CustLedgerEntry."Document Type"::Bill, CustLedgerEntry."Document Type"::Invoice]) then
            exit;

        if CarteraDoc.Get(CarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.") then
            if CarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                Error(CannotBeAppliedTryAgainErr, CustLedgerEntry.Description);
    end;
}
