#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.Upgrade;

codeunit 10554 "Upgrade Reverse Charge VAT"
{
    Access = Internal;
    Subtype = Upgrade;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagReverseChargeVAT: Codeunit "Upg. Tag Reverse Charge VAT";

    trigger OnUpgradePerCompany()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 30 then
            exit;

        UpgradeReverseChargeVAT();
    end;

    local procedure UpgradeReverseChargeVAT()
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagReverseChargeVAT.GetReverseChargeVATUpgradeTag()) then
            exit;

        TransferFields(Database::"General Ledger Setup", 10500, 10507); // Threshold applies
        TransferFields(Database::"General Ledger Setup", 10501, 10508); // Threshold Amount
        TransferFields(Database::Item, 10500, 10507); // Reverse Charge Applies
        TransferFields(Database::"Item Templ.", 10500, 10507); // Reverse Charge Applies
        TransferFields(Database::"Purchase Line", 10500, 10507); // Reverse Charge Item
        TransferFields(Database::"Purchases & Payables Setup", 10501, 10507); // Reverse Charge VAT Posting Gr.
        TransferFields(Database::"Purchases & Payables Setup", 10502, 10508); // Domestic Vendors
        TransferFields(Database::"Purch. Cr. Memo Line", 10500, 10507); // Reverse Charge Item
        TransferFields(Database::"Purch. Cr. Memo Line", 10501, 10508); // Reverse Charge
        TransferFields(Database::"Purch. Inv. Line", 10500, 10507); // Reverse Charge Item
        TransferFields(Database::"Purch. Inv. Line", 10501, 10508); // Reverse Charge
        TransferFields(Database::"Sales Cr.Memo Line", 10500, 10507); // Reverse Charge Item
        TransferFields(Database::"Sales Cr.Memo Line", 10501, 10508); // Reverse Charge
        TransferFields(Database::"Sales Invoice Line", 10500, 10507); // Reverse Charge Item
        TransferFields(Database::"Sales Invoice Line", 10501, 10508); // Reverse Charge
        TransferFields(Database::"Sales Line", 10500, 10507); // Reverse Charge Item
        TransferFields(Database::"Sales Line", 10501, 10508); // Reverse Charge
        TransferFields(Database::"Sales & Receivables Setup", 10501, 10507); // Reverse Charge VAT Posting Gr.
        TransferFields(Database::"Sales & Receivables Setup", 10502, 10508); // Domestic Customers
        TransferFields(Database::"Sales & Receivables Setup", 10503, 10509); // Invoice Wording

        UpgradeTag.SetUpgradeTag(UpgTagReverseChargeVAT.GetReverseChargeVATUpgradeTag());
    end;

    local procedure TransferFields(TableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        RecRef: RecordRef;
        TargetFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
    begin
        RecRef.Open(TableId, false);
        RecRef.Init();
        SourceFieldRef := RecRef.Field(SourceFieldNo);
        // Use the field's typed default rather than blank text for Boolean and Decimal filters.
        SourceFieldRef.SetFilter('<>%1', SourceFieldRef.Value);

        if RecRef.FindSet() then
            repeat
                TargetFieldRef := RecRef.Field(TargetFieldNo);
                if Format(TargetFieldRef.Value, 0, 9) <> Format(SourceFieldRef.Value, 0, 9) then begin
                    TargetFieldRef.Value := SourceFieldRef.Value;
                    RecRef.Modify(false);
                end;
            until RecRef.Next() = 0;

        RecRef.Close();
    end;
}
#endif