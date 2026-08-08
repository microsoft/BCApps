// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.FixedAsset;

using Microsoft.DemoData.Finance;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;

codeunit 13445 "Create FA Posting Grp. FI"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Table, Database::"FA Posting Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertFAPostingGroups(var Rec: Record "FA Posting Group")
    var
        CreateFAPostingGrp: Codeunit "Create FA Posting Group";
        CreateGLAccountFI: Codeunit "Create FI GL Accounts";
    begin
        case Rec.Code of
            CreateFAPostingGrp.Equipment(),
            CreateFAPostingGrp.Goodwill(),
            CreateFAPostingGrp.Plant(),
            CreateFAPostingGrp.Property(),
            CreateFAPostingGrp.Vehicles():
                ValidateRecordFields(Rec, CreateGLAccountFI.Changeindepreciationreserve4(), CreateGLAccountFI.Depreciationdifference3());
        end;
    end;

    local procedure ValidateRecordFields(var FAPostingGroup: Record "FA Posting Group"; DeprDifferenceAcc: Code[20]; DeprDifferenceBalAcc: Code[20])
#if not CLEAN29
    var
        DepreciationDifferencesFIFeature: Codeunit "Depreciation Differences FI Feature";
#endif
    begin
#if not CLEAN29
        if not DepreciationDifferencesFIFeature.IsEnabled() then begin
#pragma warning disable AL0432
            FAPostingGroup.Validate("Depr. Difference Acc.", DeprDifferenceAcc);
            FAPostingGroup.Validate("Depr. Difference Bal. Acc.", DeprDifferenceBalAcc);
#pragma warning restore AL0432
            exit;
        end;
#endif
        FAPostingGroup.Validate("Depreciation Difference Account", DeprDifferenceAcc);
        FAPostingGroup.Validate("Depreciation Difference Bal Acct", DeprDifferenceBalAcc);
    end;
}
