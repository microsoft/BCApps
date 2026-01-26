// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Receivables;

codeunit 1408 "Sales Credit Memo Hdr. - Edit"
{
    Permissions = TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Copy(Rec);
        SalesCrMemoHeader.ReadIsolation(IsolationLevel::UpdLock);
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader."Shipping Agent Code" := Rec."Shipping Agent Code";
        SalesCrMemoHeader."Shipping Agent Service Code" := Rec."Shipping Agent Service Code";
        SalesCrMemoHeader."Package Tracking No." := Rec."Package Tracking No.";
        SalesCrMemoHeader."Company Bank Account Code" := Rec."Company Bank Account Code";
        SalesCrMemoHeader."Fattura Document Type" := Rec."Fattura Document Type";
        SalesCrMemoHeader."Posting Description" := Rec."Posting Description";
        OnBeforeSalesCrMemoHeaderModify(SalesCrMemoHeader, Rec);
        SalesCrMemoHeader.TestField("No.", Rec."No.");
        SalesCrMemoHeader.Modify();
        Rec.Copy(SalesCrMemoHeader);

        UpdateCustLedgerEntry(Rec);

        OnRunOnAfterSalesCrMemoHeaderEdit(Rec);
    end;

    local procedure UpdateCustLedgerEntry(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if not GetCustLedgerEntry(CustLedgerEntry, SalesCrMemoHeader) then
            exit;
        CustLedgerEntry.Description := SalesCrMemoHeader."Posting Description";
        OnBeforeUpdateCustLedgerEntryAfterSetValues(CustLedgerEntry, SalesCrMemoHeader);
        Codeunit.Run(Codeunit::"Cust. Entry-Edit", CustLedgerEntry);
    end;

    local procedure GetCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    begin
        if SalesCrMemoHeader."Cust. Ledger Entry No." = 0 then
            exit(false);
        CustLedgerEntry.ReadIsolation(IsolationLevel::UpdLock);
        exit(CustLedgerEntry.Get(SalesCrMemoHeader."Cust. Ledger Entry No."));
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesCrMemoHeaderModify(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgerEntryAfterSetValues(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesCrMemoHeaderEdit(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;
}
