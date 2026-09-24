#if CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

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
        UpgradeDerogatoryLinkage: Codeunit "Upgrade Derogatory Linkage";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";

    trigger OnUpgradePerCompany()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 33 then
            exit;

        UpgradeAcceleratedDepr();
    end;

    internal procedure UpgradeAcceleratedDepr()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FAPostingGroup: Record "FA Posting Group";
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()) then
            exit;

        TransferFields(Database::"Depreciation Book", 10800, DepreciationBook.FieldNo("Derogatory Calc."));
        TransferFields(Database::"Depreciation Book", 10802, DepreciationBook.FieldNo("Integration G/L - Derogatory"));
        UpgradeDerogatoryLinkage.RunAfterRelationshipTransfer(false); // Link entries after transferring the depreciation book relationship.
        TransferFields(Database::"FA Depreciation Book", 10801, FADepreciationBook.FieldNo("Last Derogatory"));
        TransferFields(Database::"FA Ledger Entry", 10800, FALedgerEntry.FieldNo("Derogatory Excluded"));
        TransferFields(Database::"FA Posting Group", 10800, FAPostingGroup.FieldNo("Derogatory Acc."));
        TransferFields(Database::"FA Posting Group", 10801, FAPostingGroup.FieldNo("Derogatory Account (Decrease)"));
        TransferFields(Database::"FA Posting Group", 10802, FAPostingGroup.FieldNo("Derog. Bal. Account (Decrease)"));
        TransferFields(Database::"FA Posting Group", 10803, FAPostingGroup.FieldNo("Derogatory Expense Acc."));
        TransferFields(Database::"FA Reclass. Journal Line", 10800, FAReclassJournalLine.FieldNo("Reclass. Derogatory"));

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
        TargetFieldRef := RecRef.Field(TargetFieldNo);

        if RecRef.FindSet() then
            repeat
                TargetFieldRef.Value := SourceFieldRef.Value;
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;
}
#endif
