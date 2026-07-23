#if CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.AuditCodes;
using System.Upgrade;

codeunit 13468 "Upgrade Depr. Difference FI"
{
    Access = Internal;
    Subtype = Upgrade;
    Permissions = tabledata "FA Posting Group" = rimd,
                  tabledata "FA Ledger Entry" = rimd,
                  tabledata "Source Code Setup" = rimd;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagDeprDiffFI: Codeunit "Upg. Tag Depr. Diff. FI";

    trigger OnUpgradePerCompany()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 32 then
            exit;

        UpgradeDeprDifferenceFI();
    end;

    local procedure UpgradeDeprDifferenceFI()
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagDeprDiffFI.GetDeprDifferenceFIUpgradeTag()) then
            exit;

        TransferFields(Database::"FA Posting Group", 13400, 13478);
        TransferFields(Database::"FA Posting Group", 13401, 13479);
        TransferFields(Database::"FA Ledger Entry", 13400, 13480);
        TransferFields(Database::"Source Code Setup", 13400, 13481);

        UpgradeTag.SetUpgradeTag(UpgTagDeprDiffFI.GetDeprDifferenceFIUpgradeTag());
    end;

    local procedure TransferFields(TableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        RecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        RecRef.Open(TableId, false);
        if RecRef.FindSet(true) then
            repeat
                SourceFieldRef := RecRef.Field(SourceFieldNo);
                TargetFieldRef := RecRef.Field(TargetFieldNo);
                TargetFieldRef.Value := SourceFieldRef.Value;
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;
}
#endif
