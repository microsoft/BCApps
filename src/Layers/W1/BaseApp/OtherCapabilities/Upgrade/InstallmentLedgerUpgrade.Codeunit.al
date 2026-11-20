// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Upgrade;

codeunit 8844 "Installment Ledger Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "Cust. Ledger Entry" = rm,
                  tabledata "Detailed Cust. Ledg. Entry" = rm,
                  tabledata "Vendor Ledger Entry" = rm,
                  tabledata "Detailed Vendor Ledg. Entry" = rm;

    trigger OnUpgradePerCompany()
    begin
        UpgradeInvoiceGroups();
    end;

    internal procedure UpgradeInvoiceGroups()
    var
        SalesInstallmentHistory: Codeunit "Sales Installment History";
        PurchaseInstallmentHistory: Codeunit "Purchase Installment History";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetInstallmentInvoiceGroupUpgradeTag()) then begin
            InitializeCustomerInvoiceGroups();
            if SalesInstallmentHistory.BackfillInvoiceGroups() then
                UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetInstallmentInvoiceGroupUpgradeTag());
        end;
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchaseInstallmentInvoiceGroupUpgradeTag()) then begin
            InitializeVendorInvoiceGroups();
            if PurchaseInstallmentHistory.BackfillInvoiceGroups() then
                UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPurchaseInstallmentInvoiceGroupUpgradeTag());
        end;
    end;

    local procedure InitializeCustomerInvoiceGroups()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedEntryDataTransfer: DataTransfer;
        CustomerEntryDataTransfer: DataTransfer;
    begin
        DetailedEntryDataTransfer.SetTables(Database::"Detailed Cust. Ledg. Entry", Database::"Detailed Cust. Ledg. Entry");
        DetailedEntryDataTransfer.AddSourceFilter(DetailedCustLedgEntry.FieldNo("Invoice Entry No."), '=%1', 0);
        DetailedEntryDataTransfer.AddFieldValue(DetailedCustLedgEntry.FieldNo("Cust. Ledger Entry No."), DetailedCustLedgEntry.FieldNo("Invoice Entry No."));
        DetailedEntryDataTransfer.UpdateAuditFields := false;
        DetailedEntryDataTransfer.CopyFields();

        CustomerEntryDataTransfer.SetTables(Database::"Cust. Ledger Entry", Database::"Cust. Ledger Entry");
        CustomerEntryDataTransfer.AddSourceFilter(CustLedgerEntry.FieldNo("Invoice Entry No."), '=%1', 0);
        CustomerEntryDataTransfer.AddFieldValue(CustLedgerEntry.FieldNo("Entry No."), CustLedgerEntry.FieldNo("Invoice Entry No."));
        CustomerEntryDataTransfer.UpdateAuditFields := false;
        CustomerEntryDataTransfer.CopyFields();
    end;

    local procedure InitializeVendorInvoiceGroups()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedEntryDataTransfer: DataTransfer;
        VendorEntryDataTransfer: DataTransfer;
    begin
        DetailedEntryDataTransfer.SetTables(Database::"Detailed Vendor Ledg. Entry", Database::"Detailed Vendor Ledg. Entry");
        DetailedEntryDataTransfer.AddSourceFilter(DetailedVendorLedgEntry.FieldNo("Invoice Entry No."), '=%1', 0);
        DetailedEntryDataTransfer.AddFieldValue(DetailedVendorLedgEntry.FieldNo("Vendor Ledger Entry No."), DetailedVendorLedgEntry.FieldNo("Invoice Entry No."));
        DetailedEntryDataTransfer.UpdateAuditFields := false;
        DetailedEntryDataTransfer.CopyFields();

        VendorEntryDataTransfer.SetTables(Database::"Vendor Ledger Entry", Database::"Vendor Ledger Entry");
        VendorEntryDataTransfer.AddSourceFilter(VendorLedgerEntry.FieldNo("Invoice Entry No."), '=%1', 0);
        VendorEntryDataTransfer.AddFieldValue(VendorLedgerEntry.FieldNo("Entry No."), VendorLedgerEntry.FieldNo("Invoice Entry No."));
        VendorEntryDataTransfer.UpdateAuditFields := false;
        VendorEntryDataTransfer.CopyFields();
    end;
}
