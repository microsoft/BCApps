#if CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.AuditCodes;
using System.Upgrade;

codeunit 13475 "Upgrade Depreciation Diff. FI"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        DepreciationDifferencesFIUpgradeTag: Codeunit "Dep Diff FI Upgrade Tag";

    trigger OnUpgradePerCompany()
    begin
        UpgradeDepreciationDifferencesFI();
    end;

    local procedure UpgradeDepreciationDifferencesFI()
    begin
        if UpgradeTag.HasUpgradeTag(DepreciationDifferencesFIUpgradeTag.GetUpgradeTag()) then
            exit;

        TransferFields(Database::"FA Posting Group", 13462, 13400);
        TransferFields(Database::"FA Posting Group", 13463, 13401);
        TransferFields(Database::"FA Ledger Entry", 13464, 13400);
        TransferFields(Database::"Source Code Setup", 13465, 13400);

        UpgradeTag.SetUpgradeTag(DepreciationDifferencesFIUpgradeTag.GetUpgradeTag());
    end;

    local procedure TransferFields(TableId: Integer; TargetFieldNo: Integer; SourceFieldNo: Integer)
    var
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(TableId, TableId);
        DataTransfer.AddFieldValue(SourceFieldNo, TargetFieldNo);
        DataTransfer.UpdateAuditFields := false;
        DataTransfer.CopyFields();
    end;
}
#endif
