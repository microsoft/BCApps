// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.FixedAsset;

using Microsoft.DemoData.Finance;
using Microsoft.FixedAssets.FixedAsset;

codeunit 13487 "Create Depr. Diff. FA Post Grp"
{
    Access = Internal;
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
    var
        CreateGLAccount: Codeunit "Create G/L Account";
    begin
        FAPostingGroup.InitializeDepreciationDifferenceAccounts(DeprDifferenceAcc, DeprDifferenceBalAcc);
        FAPostingGroup.Validate("Derogatory Acc.", CreateGLAccount.DerogatoryAccount());
        FAPostingGroup.Validate("Derogatory Account (Decrease)", CreateGLAccount.DerogatoryAccount());
        FAPostingGroup.Validate("Derog. Bal. Account (Decrease)", CreateGLAccount.DerogExpenseAccForCredit());
        FAPostingGroup.Validate("Derogatory Expense Acc.", CreateGLAccount.DerogExpenseAccForDebit());
    end;
}
