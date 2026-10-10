// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.UseCaseBuilder;

codeunit 20288 "Upgrade Tax Use Case PS"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        RunUpgrade();
    end;

    internal procedure RunUpgrade()
    var
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        MigratePermissionSetAssignments(OldRoleIdLbl, NewRoleIdLbl, ModuleInfo.Id);
    end;

    local procedure MigratePermissionSetAssignments(OldRoleId: Code[20]; NewRoleId: Code[20]; AppId: Guid)
    begin
        if OldRoleId = NewRoleId then
            exit;

        Error(UnexpectedRoleIdChangeErr, OldRoleId, NewRoleId, AppId);
    end;

    var
        OldRoleIdLbl: Label 'TAX ENGINE USE CASE', Locked = true;
        NewRoleIdLbl: Label 'TAX ENGINE USE CASE', Locked = true;
        UnexpectedRoleIdChangeErr: Label 'The stored permission set assignment key unexpectedly changed from %1 to %2 for app %3.', Locked = true;
}
