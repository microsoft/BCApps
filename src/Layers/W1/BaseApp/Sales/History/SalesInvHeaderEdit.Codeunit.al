// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Receivables;
using Microsoft.Sales.Customer;

codeunit 1409 "Sales Inv. Header - Edit"
{
    Permissions = TableData "Sales Invoice Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Copy(Rec);
        SalesInvoiceHeader.ReadIsolation(IsolationLevel::UpdLock);
        SalesInvoiceHeader.Find();
        OnRunOnBeforeAssignValues(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader."Shipping Agent Code" := Rec."Shipping Agent Code";
        SalesInvoiceHeader."Shipping Agent Service Code" := Rec."Shipping Agent Service Code";
        SalesInvoiceHeader."Package Tracking No." := Rec."Package Tracking No.";
        SalesInvoiceHeader."Payment Method Code" := Rec."Payment Method Code";
        SalesInvoiceHeader."Payment Reference" := Rec."Payment Reference";
        SalesInvoiceHeader."Company Bank Account Code" := Rec."Company Bank Account Code";
        SalesInvoiceHeader."Posting Description" := Rec."Posting Description";
        SalesInvoiceHeader."Dispute Status" := Rec."Dispute Status";
        SalesInvoiceHeader."Promised Pay Date" := Rec."Promised Pay Date";
        SalesInvoiceHeader."Due Date" := Rec."Due Date";
        SalesInvoiceHeader."Your Reference" := Rec."Your Reference";
        OnOnRunOnBeforeTestFieldNo(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader.TestField("No.", Rec."No.");
        SalesInvoiceHeader.Modify();
        Rec.Copy(SalesInvoiceHeader);

        UpdateCustLedgerEntry(Rec);

        OnRunOnAfterSalesInvoiceHeaderEdit(Rec);
    end;

    local procedure UpdateCustLedgerEntry(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DisputeStatus: Record "Dispute Status";
        CustEntryEdit: Codeunit "Cust. Entry-Edit";
        MarkedAsOnHoldLbl: label 'X', Locked = true;
    begin
        if not GetCustLedgerEntry(CustLedgerEntry, SalesInvoiceHeader) then
            exit;

        CustLedgerEntry."Payment Method Code" := SalesInvoiceHeader."Payment Method Code";
        CustLedgerEntry."Payment Reference" := SalesInvoiceHeader."Payment Reference";
        CustLedgerEntry.Description := SalesInvoiceHeader."Posting Description";
        CustLedgerEntry."Promised Pay Date" := SalesInvoiceHeader."Promised Pay Date";
        CustLedgerEntry."Due Date" := SalesInvoiceHeader."Due Date";
        CustLedgerEntry."Your Reference" := SalesInvoiceHeader."Your Reference";
        if CustLedgerEntry."Dispute Status" <> '' then begin
            if DisputeStatus.get(CustLedgerEntry."Dispute Status") then
                if (DisputeStatus."Overwrite on hold") and ClearOnHold(SalesInvoiceHeader) then
                    CustLedgerEntry."On Hold" := ''
        end else
            if SalesInvoiceHeader."Dispute Status" <> '' then
                if DisputeStatus.get(SalesInvoiceHeader."Dispute Status") then
                    if DisputeStatus."Overwrite on hold" then
                        CustLedgerEntry."On Hold" := Copystr(MarkedAsOnHoldLbl, 1, MaxStrLen(CustLedgerEntry."On Hold"));
        CustLedgerEntry."Dispute Status" := SalesInvoiceHeader."Dispute Status";
        OnBeforeUpdateCustLedgerEntryAfterSetValues(CustLedgerEntry, SalesInvoiceHeader);
        CustEntryEdit.SetCalledFromSalesInvoice(true);
        CustEntryEdit.Run(CustLedgerEntry);
    end;

    local procedure ClearOnHold(SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        DisputeStatus: Record "Dispute Status";
    begin
        if SalesInvoiceHeader."Dispute Status" = '' then
            exit(true);
        if DisputeStatus.get(SalesInvoiceHeader."Dispute Status") then
            exit(not DisputeStatus."Overwrite on hold");
    end;

    local procedure GetCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        if SalesInvoiceHeader."Cust. Ledger Entry No." = 0 then
            exit(false);
        CustLedgerEntry.ReadIsolation(IsolationLevel::UpdLock);
        exit(CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnRunOnBeforeTestFieldNo(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeAssignValues(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgerEntryAfterSetValues(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesInvoiceHeaderEdit(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}

