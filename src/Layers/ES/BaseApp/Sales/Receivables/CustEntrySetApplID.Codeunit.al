// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.ReceivablesPayables;

codeunit 101 "Cust. Entry-SetAppl.ID"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CannotBeAppliedErr: Label '%1 cannot be applied, since it is included in a bill group.', Comment = '%1 = Description';
        CannotBeAppliedTryAgainErr: Label '%1 cannot be applied, since it is included in a bill group. Remove it from its bill group and try again.', Comment = '%1 = Description';
        CustEntryApplID: Code[50];

    procedure SetApplId(var CustLedgEntry: Record "Cust. Ledger Entry"; ApplyingCustLedgEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50])
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetApplId(CustLedgEntry, ApplyingCustLedgEntry, AppliesToID, CustEntryApplID, IsHandled);
        if IsHandled then
            exit;
        CustLedgEntry.LockTable();
        if CustLedgEntry.FindSet() then begin
            // Make Applies-to ID
            if CustLedgEntry."Applies-to ID" <> '' then
                CustEntryApplID := ''
            else begin
                CustEntryApplID := AppliesToID;
                if CustEntryApplID = '' then begin
                    CustEntryApplID := UserId;
                    if CustEntryApplID = '' then
                        CustEntryApplID := '***';
                end;
            end;
            repeat
                TempCustLedgEntry := CustLedgEntry;
                TempCustLedgEntry.Insert();
            until CustLedgEntry.Next() = 0;
        end;

        if TempCustLedgEntry.FindSet() then
            repeat
                UpdateCustLedgerEntry(TempCustLedgEntry, ApplyingCustLedgEntry, AppliesToID);
            until TempCustLedgEntry.Next() = 0;
    end;

    local procedure UpdateCustLedgerEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CarteraDoc: Record "Cartera Doc.";
        CarteraSetup: Record "Cartera Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustLedgerEntry(TempCustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID, IsHandled, CustEntryApplID);
        if IsHandled then
            exit;

        CustLedgerEntry.Copy(TempCustLedgerEntry);
        CustLedgerEntry.TestField(Open, true);
        if CustLedgerEntry."Document Situation" = CustLedgerEntry."Document Situation"::"Posted BG/PO" then
            Error(CannotBeAppliedErr, CustLedgerEntry.Description);
        if ApplyingCustLedgerEntry."Document Situation" = ApplyingCustLedgerEntry."Document Situation"::"Posted BG/PO" then
            Error(CannotBeAppliedErr, ApplyingCustLedgerEntry.Description);

        if CarteraSetup.ReadPermission then
            if ((CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Bill) or
                (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice))
            then
                if CarteraDoc.Get(CarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.") then
                    if CarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                        Error(CannotBeAppliedTryAgainErr, CustLedgerEntry.Description);

        CustLedgerEntry."Applies-to ID" := CustEntryApplID;
        if CustLedgerEntry."Applies-to ID" = '' then begin
            CustLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
            CustLedgerEntry."Accepted Payment Tolerance" := 0;
        end;
        if ((CustLedgerEntry."Amount to Apply" <> 0) and (CustEntryApplID = '')) or
           (CustEntryApplID = '')
        then
            CustLedgerEntry."Amount to Apply" := 0
        else
            if CustLedgerEntry."Amount to Apply" = 0 then begin
                CustLedgerEntry.CalcFields("Remaining Amount");
                CustLedgerEntry."Amount to Apply" := CustLedgerEntry."Remaining Amount"
            end;

        if CustLedgerEntry."Entry No." = ApplyingCustLedgerEntry."Entry No." then
            CustLedgerEntry."Applying Entry" := ApplyingCustLedgerEntry."Applying Entry";
        OnUpdateCustLedgerEntryOnBeforeCustLedgerEntryModify(CustLedgerEntry, TempCustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID);
        CustLedgerEntry.Modify();

        OnAfterUpdateCustLedgerEntry(CustLedgerEntry, TempCustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID);
    end;

    procedure RemoveApplId(var CustLedgerEntry: Record "Cust. Ledger Entry"; AppliestoID: Code[50])
    begin
        if CustLedgerEntry.FindSet() then
            repeat
                if CustLedgerEntry."Applies-to ID" = AppliestoID then begin
                    CustLedgerEntry."Applies-to ID" := '';
                    CustLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
                    CustLedgerEntry."Accepted Payment Tolerance" := 0;
                    CustLedgerEntry."Amount to Apply" := 0;
                    CustLedgerEntry.Modify();
                end;
            until CustLedgerEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgerEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]; var IsHandled: Boolean; var CustEntryApplID: Code[50]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustLedgerEntryOnBeforeCustLedgerEntryModify(var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetApplId(var CustLedgEntry: Record "Cust. Ledger Entry"; ApplyingCustLedgEntry: Record "Cust. Ledger Entry"; var AppliesToID: Code[50]; var CustEntryApplID: Code[50]; var IsHandled: Boolean);
    begin
    end;
}

