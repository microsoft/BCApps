// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Upgrade;

codeunit 8844 "Installment Ledger Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "Cust. Ledger Entry" = rm,
                  tabledata "Detailed Cust. Ledg. Entry" = rm;

    trigger OnUpgradePerCompany()
    begin
        UpgradeInvoiceGroups();
    end;

    internal procedure UpgradeInvoiceGroups()
    var
        SalesInstallmentHistory: Codeunit "Sales Installment History";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetInstallmentInvoiceGroupUpgradeTag()) then
            exit;
        InitializeInvoiceGroups();
        if SalesInstallmentHistory.BackfillInvoiceGroups() then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetInstallmentInvoiceGroupUpgradeTag());
    end;

    local procedure InitializeInvoiceGroups()
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
}
