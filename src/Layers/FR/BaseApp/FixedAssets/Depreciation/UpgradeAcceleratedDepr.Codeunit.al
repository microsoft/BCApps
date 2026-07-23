#if CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using System.Upgrade;

codeunit 5868 "Upgrade Accelerated Depr."
{
    Access = Internal;
    Subtype = Upgrade;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";

    trigger OnUpgradePerCompany()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 31 then
            exit;

        UpgradeAcceleratedDepr();
    end;

    local procedure UpgradeAcceleratedDepr()
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()) then
            exit;

        TransferFields(Database::"Gen. Journal Line", 10861, 5865); //  10861 - the existing field "Derogatory Line", 5865 - the new field "Is Derogatory";
        TransferFields(Database::"Posted Gen. Journal Line", 10861, 5865); //  10861 - the existing field "Derogatory Line", 5865 - the new field "Is Derogatory";
        TransferFields(Database::"Depreciation Book", 10800, 5865); //  10800 - the existing field "Derogatory Calculation", 5865 - the new field "Derogatory Calc.";
        TransferFields(Database::"Depreciation Book", 10802, 5867); //  10802 - the existing field "G/L Integration - Derogatory", 5867 - the new field "Integration G/L - Derogatory";
        TransferFields(Database::"FA Depreciation Book", 10801, 5865); //  10801 - the existing field "Last Derogatory Date", 5865 - the new field "Derogatory Amount";
        TransferFields(Database::"FA Ledger Entry", 10800, 5865); //  10800 - the existing field "Derogatory Excluded", 5865 - the new field "Exclude Derogatory";
        TransferFields(Database::"FA Posting Group", 10800, 5865); //  10800 - the existing field "Derogatory Account", 5865 - the new field "Derogatory Acc.";
        TransferFields(Database::"FA Posting Group", 10801, 5866); //  10801 - the existing field "Derogatory Acc. (Decrease)", 5866 - the new field "Derogatory Account (Decrease)";
        TransferFields(Database::"FA Posting Group", 10802, 5867); //  10802 - the existing field "Derog. Bal. Acc. (Decrease)", 5867 - the new field  "Derog. Bal. Account (Decrease)";
        TransferFields(Database::"FA Posting Group", 10803, 5868); //  10803 - the existing field "Derogatory Expense Account", 5868 - the new field "Derogatory Expense Acc.";
        TransferFields(Database::"FA Reclass. Journal Line", 10800, 5865); //  10800 - the existing field "Reclassify Derogatory", 5865 - the new field "Reclass. Derogatory";

        UpgradeTag.SetUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag());
    end;

    local procedure TransferFields(TableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        RecRef: RecordRef;
        TargetFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
    begin
        RecRef.Open(TableId, false);
        SourceFieldRef := RecRef.Field(SourceFieldNo);
        SourceFieldRef.SetFilter('<>%1', '');

        if RecRef.FindSet() then
            repeat
                TargetFieldRef := RecRef.Field(TargetFieldNo);
                TargetFieldRef.VALUE := SourceFieldRef.VALUE;
                RecRef.Modify(false);
            until RecRef.Next() = 0;
    end;
}
#endif