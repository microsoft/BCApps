// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;


codeunit 7000111 "CRT Copy Document Mgt."
{
    var
        SettlementErr: Label 'At least one document of %1 No. %2 is closed or in a Bill Group. This will avoid the document to be settled. The posting process of %3 No. %4 wont settle any document', Comment = '%1 - Document Type, %2 - Document No., %3 - Document Type, %4 - Document No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnUpdateCustLedgEntryOnAfterSetFilters', '', true, false)]
    local procedure OnUpdateCustLedgEntryOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ToSalesHeader: Record "Sales Header"; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document Situation", CustLedgerEntry."Document Situation"::" ");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnUpdateVendLedgEntryOnAfterSetFilters', '', true, false)]
    local procedure OnUpdateVendLedgEntryOnAfterSetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var ToPurchHeader: Record "Purchase Header"; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document Situation", VendorLedgerEntry."Document Situation"::" ");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnUpdateVendLedgEntryOnNoOpenEntries', '', true, false)]
    local procedure OnUpdateVendLedgEntryOnNoOpenEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var ToPurchHeader: Record "Purchase Header"; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    var
        FromPurchInvHeader: Record "Purch. Inv. Header";
    begin
        if FromDocType = "Purchase Document Type From"::"Posted Invoice" then begin
            FromPurchInvHeader.Get(FromDocNo);
            TestPurchEfecs(FromDocType, ToPurchHeader, FromPurchInvHeader, VendorLedgerEntry);
        end;
    end;

    local procedure TestPurchEfecs(FromDocType: Enum "Gen. Journal Document Type"; var ToPurchHeader: Record "Purchase Header"; var FromPurchInvHeader: Record "Purch. Inv. Header"; var VendorLedgEntry: Record "Vendor Ledger Entry")
    var
        ApplyVendorEntries: Page "Apply Vendor Entries";
        ErrorCount: Integer;
    begin
        ErrorCount := 0;
        VendorLedgEntry.SetFilter(
          "Document Type", '%1|%2', VendorLedgEntry."Document Type"::Invoice, VendorLedgEntry."Document Type"::Bill);
        VendorLedgEntry.SetFilter("Document Situation", '<>%1', VendorLedgEntry."Document Situation"::" ");
        if not VendorLedgEntry.Find('-') then
            exit;

        repeat
            if VendorLedgEntry."Document Situation" <> VendorLedgEntry."Document Situation"::Cartera then
                if not ((VendorLedgEntry."Document Situation" in
                         [VendorLedgEntry."Document Situation"::"Closed Documents",
                          VendorLedgEntry."Document Situation"::"Closed BG/PO"]) and
                        (VendorLedgEntry."Document Status" = VendorLedgEntry."Document Status"::Rejected))
                then
                    ErrorCount := ErrorCount + 1;
        until VendorLedgEntry.Next() = 0;
        if ErrorCount = 0 then
            if VendorLedgEntry.Find('-') then
                repeat
                    if VendorLedgEntry."Document Type" = VendorLedgEntry."Document Type"::Bill then begin
                        ToPurchHeader."Applies-to ID" := FromPurchInvHeader."No.";
                        ApplyVendorEntries.SetPurch(ToPurchHeader, VendorLedgEntry, ToPurchHeader.FieldNo("Applies-to ID"));
                        ApplyVendorEntries.SetRecord(VendorLedgEntry);
                        ApplyVendorEntries.SetTableView(VendorLedgEntry);
                        ApplyVendorEntries.SetVendApplId(false);
                    end else begin
                        ToPurchHeader."Applies-to Doc. Type" := ToPurchHeader."Applies-to Doc. Type"::Invoice;
                        ToPurchHeader."Applies-to Doc. No." := FromPurchInvHeader."No.";
                    end
                until VendorLedgEntry.Next() = 0
            else
                Message(
                    SettlementErr,
                    Format(FromDocType), Format(FromPurchInvHeader."No."),
                    Format(ToPurchHeader."Document Type"), Format(ToPurchHeader."No."));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnUpdateCustLedgEntryOnNoOpenEntries', '', true, false)]
    local procedure OnUpdateCustLedgEntryOnNoOpenEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ToSalesHeader: Record "Sales Header"; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    var
        FromSalesInvHeader: Record "Sales Invoice Header";
    begin
        if FromDocType = "Sales Document Type From"::"Posted Invoice" then begin
            FromSalesInvHeader.Get(FromDocNo);
            TestSalesEfecs(FromDocType, ToSalesHeader, FromSalesInvHeader, CustLedgerEntry);
        end;
    end;

    local procedure TestSalesEfecs(FromDocType: Enum "Gen. Journal Document Type"; var ToSalesHeader: Record "Sales Header"; var FromSalesInvHeader: Record "Sales Invoice Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        ApplyCustEntries: Page "Apply Customer Entries";
        ErrorCount: Integer;
    begin
        ErrorCount := 0;
        CustLedgerEntry.SetFilter(
          "Document Type", '%1|%2', CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.SetFilter("Document Situation", '<>%1', CustLedgerEntry."Document Situation"::" ");
        if not CustLedgerEntry.Find('-') then
            exit;

        repeat
            if CustLedgerEntry."Document Situation" <> CustLedgerEntry."Document Situation"::Cartera then
                if not ((CustLedgerEntry."Document Situation" in
                         [CustLedgerEntry."Document Situation"::"Closed Documents",
                          CustLedgerEntry."Document Situation"::"Closed BG/PO"]) and
                        (CustLedgerEntry."Document Status" = CustLedgerEntry."Document Status"::Rejected))
                then
                    ErrorCount := ErrorCount + 1;

        until CustLedgerEntry.Next() = 0;
        if ErrorCount = 0 then
            if CustLedgerEntry.Find('-') then
                repeat
                    if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Bill then begin
                        ToSalesHeader."Applies-to ID" := FromSalesInvHeader."No.";
                        ApplyCustEntries.SetSales(ToSalesHeader, CustLedgerEntry, ToSalesHeader.FieldNo("Applies-to ID"));
                        ApplyCustEntries.SetRecord(CustLedgerEntry);
                        ApplyCustEntries.SetTableView(CustLedgerEntry);
                        ApplyCustEntries.SetCustApplId(false);
                    end else begin
                        ToSalesHeader."Applies-to Doc. Type" := ToSalesHeader."Applies-to Doc. Type"::Invoice;
                        ToSalesHeader."Applies-to Doc. No." := FromSalesInvHeader."No.";
                    end
                until CustLedgerEntry.Next() = 0
            else
                Message(
                    SettlementErr,
                    Format(FromDocType), Format(FromSalesInvHeader."No."),
                    Format(ToSalesHeader."Document Type"), Format(ToSalesHeader."No."));
    end;
}