// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.Consolidation;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 103 "Cust. Entry-Edit"
{
    Permissions = TableData "Cust. Ledger Entry" = m,
                  TableData "Detailed Cust. Ledg. Entry" = m,
                  tabledata "Sales Invoice Header" = m;

    TableNo = "Cust. Ledger Entry";

    var
        CalledFromSalesInvEdit: Boolean;

    trigger OnRun()
    var
        LedgEntryTrackChanges: Codeunit "Ledg. Entry-Track Changes";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, CustLedgEntry, DtldCustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry := Rec;
        CustLedgEntry.LockTable();
        CustLedgEntry.Find();

        if LogFieldChanged(CustLedgEntry, Rec) then
            BindSubscription(LedgEntryTrackChanges);

        CustLedgEntry."On Hold" := Rec."On Hold";
        if CustLedgEntry.Open then begin
            CustLedgEntry."Due Date" := Rec."Due Date";
            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", Rec."Due Date");
            CustLedgEntry."Pmt. Discount Date" := Rec."Pmt. Discount Date";
            CustLedgEntry."Applies-to ID" := Rec."Applies-to ID";
            CustLedgEntry.Validate("Payment Method Code", Rec."Payment Method Code");
            CustLedgEntry.Validate("Payment Reference", Rec."Payment Reference");
            CustLedgEntry.Validate("Your Reference", Rec."Your Reference");
            CustLedgEntry.Validate("Remaining Pmt. Disc. Possible", Rec."Remaining Pmt. Disc. Possible");
            CustLedgEntry."Pmt. Disc. Tolerance Date" := Rec."Pmt. Disc. Tolerance Date";
            CustLedgEntry.Validate("Max. Payment Tolerance", Rec."Max. Payment Tolerance");
            CustLedgEntry.Validate("Accepted Payment Tolerance", Rec."Accepted Payment Tolerance");
            CustLedgEntry.Validate("Accepted Pmt. Disc. Tolerance", Rec."Accepted Pmt. Disc. Tolerance");
            CustLedgEntry.Validate("Amount to Apply", Rec."Amount to Apply");
            CustLedgEntry.Validate("Applying Entry", Rec."Applying Entry");
            CustLedgEntry.Validate("Applies-to Ext. Doc. No.", Rec."Applies-to Ext. Doc. No.");
            CustLedgEntry.Validate("Message to Recipient", Rec."Message to Recipient");
            CustLedgEntry.Validate("Recipient Bank Account", Rec."Recipient Bank Account");
            CustLedgEntry."Direct Debit Mandate ID" := Rec."Direct Debit Mandate ID";
        end;
        CustLedgEntry.Description := Rec.Description;
        CustLedgEntry.Validate("Exported to Payment File", Rec."Exported to Payment File");
        CustLedgEntry.Validate("Promised Pay Date", Rec."Promised Pay Date");
        CustLedgEntry.Validate("Dispute Status", Rec."Dispute Status");
        OnBeforeCustLedgEntryModify(CustLedgEntry, Rec);
        CustLedgEntry.TestField("Entry No.", Rec."Entry No.");
        CustLedgEntry.Modify();
        OnRunOnAfterCustLedgEntryModify(Rec, CustLedgEntry);
        UpdateSalesInvoiceHeader(CustLedgEntry);
        Rec := CustLedgEntry;
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NotIdenticalErr: Label '%1 and %2 must be identical or %1 must be Blank.', Comment = '%1 and %2 = document nos.';
        BASManagement: Codeunit "BAS Management";

    procedure SetOnHold(var OnHoldCustLedgEntry: Record "Cust. Ledger Entry"; NewOnHold: Code[3])
    var
        LedgEntryTrackChanges: Codeunit "Ledg. Entry-Track Changes";
        xOnHold: Code[3];
    begin
        BindSubscription(LedgEntryTrackChanges);

        xOnHold := OnHoldCustLedgEntry."On Hold";
        OnHoldCustLedgEntry."On Hold" := NewOnHold;
        if xOnHold <> OnHoldCustLedgEntry."On Hold" then
            OnHoldCustLedgEntry.Modify();
    end;

    procedure SetCalledFromSalesInvoice(CalledFromSalesInvEditSet: Boolean)
    begin
        CalledFromSalesInvEdit := CalledFromSalesInvEditSet;
    end;

    local procedure UpdateSalesInvoiceHeader(UpdateSalesInvoiceCustLedgEntry: Record "Cust. Ledger Entry")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesInvoiceHeader(UpdateSalesInvoiceCustLedgEntry, CalledFromSalesInvEdit, IsHandled);
        if IsHandled then
            exit;

        if CalledFromSalesInvEdit then
            exit;
        if UpdateSalesInvoiceCustLedgEntry."Document Type" <> UpdateSalesInvoiceCustLedgEntry."Document Type"::Invoice then
            exit;
        if not SalesInvoiceHeader.get(UpdateSalesInvoiceCustLedgEntry."Document No.") then
            exit;

        SalesInvoiceHeader.validate("Payment Method Code", UpdateSalesInvoiceCustLedgEntry."Payment Method Code");
        SalesInvoiceHeader.Validate("Payment Reference", UpdateSalesInvoiceCustLedgEntry."Payment Reference");
        SalesInvoiceHeader.Validate("Posting Description", UpdateSalesInvoiceCustLedgEntry.Description);
        SalesInvoiceHeader.validate("Dispute Status", UpdateSalesInvoiceCustLedgEntry."Dispute Status");
        SalesInvoiceHeader.Validate("Promised Pay Date", UpdateSalesInvoiceCustLedgEntry."Promised Pay Date");
        SalesInvoiceHeader.validate("Due Date", UpdateSalesInvoiceCustLedgEntry."Due Date");
        SalesInvoiceHeader.Modify(true);
    end;


    local procedure LogFieldChanged(CurrCustLedgerEntry: Record "Cust. Ledger Entry"; NewCustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        Changed: Boolean;
    begin
        Changed :=
            (CurrCustLedgerEntry.Description <> NewCustLedgerEntry.Description) or
            (CurrCustLedgerEntry."Due Date" <> NewCustLedgerEntry."Due Date") or
            (CurrCustLedgerEntry."Payment Method Code" <> NewCustLedgerEntry."Payment Method Code") or
            (CurrCustLedgerEntry."Payment Reference" <> NewCustLedgerEntry."Payment Reference") or
            (CurrCustLedgerEntry."Message to Recipient" <> NewCustLedgerEntry."Message to Recipient") or
            (CurrCustLedgerEntry."Recipient Bank Account" <> NewCustLedgerEntry."Recipient Bank Account") or
            (CurrCustLedgerEntry."On Hold" <> NewCustLedgerEntry."On Hold") or
            (CurrCustLedgerEntry."Your Reference" <> NewCustLedgerEntry."Your Reference");
        OnAfterLogFieldChanged(CurrCustLedgerEntry, NewCustLedgerEntry, Changed);
        exit(Changed);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustLedgEntryModify(var CustLedgEntry: Record "Cust. Ledger Entry"; FromCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    procedure LookupAdjmtAppliesTo(var CurrentSalesHeader: Record "Sales Header")
    var
        ApplyCustEntries: Page "Apply Customer Entries";
    begin
        Clear(ApplyCustEntries);
        CurrentSalesHeader.CalcFields(Amount);
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", Positive, "Applies-to Doc. Type", "Applies-to Doc. No.", "Due Date");
        CustLedgEntry.SetRange("Customer No.", CurrentSalesHeader."Bill-to Customer No.");
        if CurrentSalesHeader."Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document Type", CurrentSalesHeader."Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", CurrentSalesHeader."Applies-to Doc. No.");
            if CustLedgEntry.FindFirst() then;
            CustLedgEntry.SetRange("Document Type");
            CustLedgEntry.SetRange("Document No.");
        end else
            if CurrentSalesHeader."Applies-to Doc. Type" <> CurrentSalesHeader."Applies-to Doc. Type"::" " then begin
                CustLedgEntry.SetRange("Document Type", CurrentSalesHeader."Applies-to Doc. Type");
                if CustLedgEntry.FindFirst() then;
                CustLedgEntry.SetRange("Document Type");
            end else
                if CurrentSalesHeader.Amount <> 0 then begin
                    CustLedgEntry.SetRange(Positive, CurrentSalesHeader.Amount < 0);
                    if CustLedgEntry.FindFirst() then;
                    CustLedgEntry.SetRange(Positive);
                    CustLedgEntry.SetFilter("Document Type", '<>%1', CustLedgEntry."Document Type"::Payment);
                end;

        ApplyCustEntries.SetSales(CurrentSalesHeader, CustLedgEntry, CurrentSalesHeader.FieldNo("Applies-to Doc. No."));
        ApplyCustEntries.LookupMode(true);
        if ApplyCustEntries.RunModal() = ACTION::LookupOK then begin
            ApplyCustEntries.GetCustLedgEntry(CustLedgEntry);
            CurrentSalesHeader."Adjustment Applies-to" := CustLedgEntry."Document No.";
            if (CurrentSalesHeader."Applies-to Doc. No." <> CurrentSalesHeader."Adjustment Applies-to") and
               (CurrentSalesHeader."Applies-to Doc. No." <> '')
            then
                Error(
                  NotIdenticalErr,
                  CurrentSalesHeader.FieldName("Applies-to Doc. No."), CurrentSalesHeader.FieldName("Adjustment Applies-to"));
            CurrentSalesHeader."Applies-to Doc. Type" := CustLedgEntry."Document Type";
            CurrentSalesHeader."BAS Adjustment" := BASManagement.CheckBASPeriod(CurrentSalesHeader."Document Date", CustLedgEntry."Document Date");

            if CurrentSalesHeader."Applies-to Doc. No." = '' then
                CustLedgEntry."Amount to Apply" := 0;

            OnBeforeModifyCustLedgEntry(CurrentSalesHeader, CustLedgEntry);    
            CustLedgEntry.Modify();
        end;
        Clear(ApplyCustEntries);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var CustLedgerEntryRec: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCustLedgEntryModify(var CustLedgerEntryRec: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogFieldChanged(CurrCustLedgerEntry: Record "Cust. Ledger Entry"; NewCustLedgerEntry: Record "Cust. Ledger Entry"; var Changed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyCustLedgEntry(var CurrentSalesHeader: Record "Sales Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesInvoiceHeader(var UpdateSalesInvoiceCustLedgerEntry: Record "Cust. Ledger Entry"; CalledFromSalesInvEdit: Boolean; var IsHandled: Boolean)
    begin
    end;    
}

