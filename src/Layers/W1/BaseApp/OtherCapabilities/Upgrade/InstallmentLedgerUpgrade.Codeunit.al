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
        SalesInstallmentHistory.BackfillInvoiceGroups();
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetInstallmentInvoiceGroupUpgradeTag());
    end;
}
