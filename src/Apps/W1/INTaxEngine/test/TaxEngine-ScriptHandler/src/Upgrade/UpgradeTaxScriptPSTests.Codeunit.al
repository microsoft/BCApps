// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.ScriptHandler.Tests;

using Microsoft.Finance.TaxEngine.ScriptHandler;
using System.Security.AccessControl;

codeunit 136757 "Upgrade Tax Script PS Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigratesPermissionSetAssignments()
    var
        UpgradeTaxScriptPS: Codeunit "Upgrade Tax Script PS";
    begin
        CreateOldAssignments();

        UpgradeTaxScriptPS.RunUpgrade();

        VerifyOldAssignmentsDoNotExist();
        VerifyNewAssignmentsExist();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletesOldAssignmentsWhenTargetExists()
    var
        UpgradeTaxScriptPS: Codeunit "Upgrade Tax Script PS";
    begin
        CreateOldAssignments();
        CreateNewAssignments();

        UpgradeTaxScriptPS.RunUpgrade();

        VerifyOldAssignmentsDoNotExist();
        VerifyNewAssignmentsExist();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PermissionSetAssignmentMigrationIsIdempotent()
    var
        UpgradeTaxScriptPS: Codeunit "Upgrade Tax Script PS";
    begin
        CreateOldAssignments();

        UpgradeTaxScriptPS.RunUpgrade();
        UpgradeTaxScriptPS.RunUpgrade();

        VerifyOldAssignmentsDoNotExist();
        VerifyNewAssignmentsExist();
    end;

    local procedure CreateOldAssignments()
    begin
        CreateAssignments(OldRoleIdLbl);
    end;

    local procedure CreateNewAssignments()
    begin
        CreateAssignments(NewRoleIdLbl);
    end;

    local procedure CreateAssignments(RoleId: Code[20])
    var
        AccessControl: Record "Access Control";
        TenantPermissionSetRel: Record "Tenant Permission Set Rel.";
        UserGroupAccessControl: Record "User Group Access Control";
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet."User Group Code" := UserGroupCodeLbl;
        UserGroupPermissionSet."Role ID" := RoleId;
        UserGroupPermissionSet.Scope := UserGroupPermissionSet.Scope::System;
        UserGroupPermissionSet."App ID" := ScriptHandlerAppId();
        UserGroupPermissionSet.Insert();

        UserGroupAccessControl."User Group Code" := UserGroupCodeLbl;
        UserGroupAccessControl."User Security ID" := UserSecurityId();
        UserGroupAccessControl."Role ID" := RoleId;
        UserGroupAccessControl."Company Name" := CompanyNameLbl;
        UserGroupAccessControl.Scope := UserGroupAccessControl.Scope::System;
        UserGroupAccessControl."App ID" := ScriptHandlerAppId();
        UserGroupAccessControl.Insert();

        AccessControl."User Security ID" := UserSecurityId();
        AccessControl."Role ID" := RoleId;
        AccessControl."Company Name" := CompanyNameLbl;
        AccessControl.Scope := AccessControl.Scope::System;
        AccessControl."App ID" := ScriptHandlerAppId();
        AccessControl.Insert();

        TenantPermissionSetRel."App ID" := TenantPermissionSetAppId();
        TenantPermissionSetRel."Role ID" := TenantRoleIdLbl;
        TenantPermissionSetRel."Related App ID" := ScriptHandlerAppId();
        TenantPermissionSetRel."Related Role ID" := RoleId;
        TenantPermissionSetRel."Related Scope" := TenantPermissionSetRel."Related Scope"::System;
        TenantPermissionSetRel.Insert();
    end;

    local procedure VerifyOldAssignmentsDoNotExist()
    begin
        VerifyAssignments(OldRoleIdLbl, false);
    end;

    local procedure VerifyNewAssignmentsExist()
    begin
        VerifyAssignments(NewRoleIdLbl, true);
    end;

    local procedure VerifyAssignments(RoleId: Code[20]; Expected: Boolean)
    var
        AccessControl: Record "Access Control";
        TenantPermissionSetRel: Record "Tenant Permission Set Rel.";
        UserGroupAccessControl: Record "User Group Access Control";
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        Assert.AreEqual(
            Expected,
            UserGroupPermissionSet.Get(UserGroupCodeLbl, RoleId, UserGroupPermissionSet.Scope::System, ScriptHandlerAppId()),
            UserGroupPermissionSetErr);
        Assert.AreEqual(
            Expected,
            UserGroupAccessControl.Get(UserGroupCodeLbl, UserSecurityId(), RoleId, CompanyNameLbl, UserGroupAccessControl.Scope::System, ScriptHandlerAppId()),
            UserGroupAccessControlErr);
        Assert.AreEqual(
            Expected,
            AccessControl.Get(UserSecurityId(), RoleId, CompanyNameLbl, AccessControl.Scope::System, ScriptHandlerAppId()),
            AccessControlErr);
        Assert.AreEqual(
            Expected,
            TenantPermissionSetRel.Get(TenantPermissionSetAppId(), TenantRoleIdLbl, ScriptHandlerAppId(), RoleId),
            TenantPermissionSetRelErr);
    end;

    local procedure ScriptHandlerAppId(): Guid
    var
        UpgradeTaxScriptPS: Codeunit "Upgrade Tax Script PS";
    begin
        exit(UpgradeTaxScriptPS.GetCurrentAppId());
    end;

    local procedure TenantPermissionSetAppId(): Guid
    begin
        exit('{c7b16dff-37f9-4a9c-84c8-90fa50b0fefd}');
    end;

    local procedure UserSecurityId(): Guid
    begin
        exit('{96ca578b-a997-4b93-bff5-86e00905966b}');
    end;

    var
        Assert: Codeunit "Library Assert";
        OldRoleIdLbl: Label 'TAX ENGINE SCRIPT HA', Locked = true;
        NewRoleIdLbl: Label 'TAX ENGINE SCRIPT', Locked = true;
        UserGroupCodeLbl: Label 'PS UPGRADE TEST', Locked = true;
        CompanyNameLbl: Label 'PS Upgrade Company', Locked = true;
        TenantRoleIdLbl: Label 'TENANT TEST', Locked = true;
        UserGroupPermissionSetErr: Label 'The User Group Permission Set assignment was not migrated as expected.';
        UserGroupAccessControlErr: Label 'The User Group Access Control assignment was not migrated as expected.';
        AccessControlErr: Label 'The Access Control assignment was not migrated as expected.';
        TenantPermissionSetRelErr: Label 'The Tenant Permission Set relation was not migrated as expected.';
}
