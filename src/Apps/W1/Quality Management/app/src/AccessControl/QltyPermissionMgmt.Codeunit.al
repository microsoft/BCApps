// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.AccessControl;

using Microsoft.QualityManagement.Document;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Provides permission management methods for Quality Management functional permissions.
/// </summary>
codeunit 20406 "Qlty. Permission Mgmt."
{
    InherentPermissions = X;

    var
        ActionCreateInspectionManuallyLbl: Label 'create inspection manually';
        ActionCreateReinspectionLbl: Label 'create re-inspection';
        ActionChangeOthersInspectionLbl: Label 'change others inspection';
        ActionFinishInspectionLbl: Label 'finish inspection';
        ActionReopenInspectionLbl: Label 'reopen inspection';
        ActionDeleteOpenInspectionLbl: Label 'delete open inspection';
        ActionDeleteFinishedInspectionLbl: Label 'delete finished inspection';
        ActionChangeItemTrackingLbl: Label 'change item tracking';
        ActionChangeSourceQuantityLbl: Label 'change source quantity';
        ActionEditLineCommentLbl: Label 'edit line note/comment';
        SupervisorRoleIDTxt: Label 'QltyMngmnt - Edit', Locked = true;
        UserDoesNotHavePermissionToErr: Label 'The user [%1] does not have permission to [%2].', Comment = '%1=User id, %2=permission being attempted';

    /// <summary>
    /// Verifies the current user can create a manual inspection. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanCreateManualInspection()
    begin
        if not CanInsertTableData(Database::"Qlty. Inspection Header") then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionCreateInspectionManuallyLbl);
    end;

    /// <summary>
    /// Verifies the current user can create a re-inspection. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanCreateReinspection()
    begin
        if not CanInsertTableData(Database::"Qlty. Inspection Header") then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionCreateReinspectionLbl);
    end;

    /// <summary>
    /// Verifies the current user can change other users' inspections. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanChangeOtherInspections()
    begin
        if not CanChangeOtherInspections() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionChangeOthersInspectionLbl);
    end;

    /// <summary>
    /// Checks if the current user can change other users' inspections.
    /// </summary>
    /// <returns>True if the user can change other users' inspections; otherwise, false.</returns>
    internal procedure CanChangeOtherInspections(): Boolean
    begin
        exit(HasSupervisorRole());
    end;

    /// <summary>
    /// Verifies the current user can finish an inspection. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanFinishInspection()
    begin
        if not CanFinishInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionFinishInspectionLbl);
    end;

    /// <summary>
    /// Checks if the current user can finish an inspection.
    /// </summary>
    /// <returns>True if the user can finish an inspection; otherwise, false.</returns>
    internal procedure CanFinishInspection(): Boolean
    begin
        exit(CanModifyTableData(Database::"Qlty. Inspection Header"));
    end;

    /// <summary>
    /// Verifies the current user can reopen an inspection. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanReopenInspection()
    begin
        if not CanModifyTableData(Database::"Qlty. Inspection Header") then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionReopenInspectionLbl);
    end;

    /// <summary>
    /// Verifies the current user can delete an open inspection. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanDeleteOpenInspection()
    begin
        if not CanDeleteTableData(Database::"Qlty. Inspection Header") then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionDeleteOpenInspectionLbl);
    end;

    /// <summary>
    /// Verifies the current user can delete a finished inspection. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanDeleteFinishedInspection()
    begin
        if not CanDeleteFinishedInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionDeleteFinishedInspectionLbl);
    end;

    /// <summary>
    /// Checks if the current user can delete a finished inspection.
    /// </summary>
    /// <returns>True if the user can delete a finished inspection; otherwise, false.</returns>
    internal procedure CanDeleteFinishedInspection(): Boolean
    begin
        if not CanDeleteTableData(Database::"Qlty. Inspection Header") then
            exit(false);

        exit(HasSupervisorRole());
    end;

    /// <summary>
    /// Verifies the current user can change item tracking on an inspection. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanChangeItemTracking()
    begin
        if not CanChangeItemTracking() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionChangeItemTrackingLbl);
    end;

    /// <summary>
    /// Checks if the current user can change the item tracking on an inspection.
    /// </summary>
    /// <returns>True if the user can change item tracking; otherwise, false.</returns>
    internal procedure CanChangeItemTracking(): Boolean
    begin
        exit(CanModifyTableData(Database::"Qlty. Inspection Header"));
    end;

    /// <summary>
    /// Verifies the current user can change the source quantity. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanChangeSourceQuantity()
    begin
        if not CanChangeSourceQuantity() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionChangeSourceQuantityLbl);
    end;

    /// <summary>
    /// Checks if the current user can change the source quantity on an inspection.
    /// </summary>
    /// <returns>True if the user can change the source quantity; otherwise, false.</returns>
    internal procedure CanChangeSourceQuantity(): Boolean
    begin
        if not CanModifyTableData(Database::"Qlty. Inspection Header") then
            exit(false);

        exit(HasSupervisorRole());
    end;

    /// <summary>
    /// Verifies the current user can edit line comments. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanEditLineComments()
    begin
        if not CanEditLineComments() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionEditLineCommentLbl);
    end;

    /// <summary>
    /// Checks if the current user can edit line notes and comments.
    /// </summary>
    /// <returns>True if the user can edit line comments; otherwise, false.</returns>
    internal procedure CanEditLineComments(): Boolean
    begin
        exit(CanModifyTableData(Database::"Record Link"));
    end;

    /// <summary>
    /// Determines whether auto-assignment should occur based on user permissions.
    /// </summary>
    /// <param name="ShouldPrompt">Set to true when GUI is available and prompting is enabled.</param>
    /// <returns>True if auto-assignment should occur; otherwise, false.</returns>
    internal procedure GetShouldAutoAssign(var ShouldPrompt: Boolean) ShouldAssign: Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        ShouldAssign := QltyInspectionHeader.WritePermission();
        ShouldPrompt := false;
    end;

    #region Verify Permissions
    local procedure HasSupervisorRole() IsAssigned: Boolean
    var
        UserPermissions: Codeunit "User Permissions";
        CurrentExtensionModuleInfo: ModuleInfo;
    begin
        IsAssigned := HasUserPermissionSetDirectlyAssigned(UserSecurityId(), SupervisorRoleIDTxt);
        if not IsAssigned then
            if NavApp.GetCurrentModuleInfo(CurrentExtensionModuleInfo) then
                IsAssigned := UserPermissions.HasUserPermissionSetAssigned(UserSecurityId(), CompanyName(), SupervisorRoleIDTxt, 0, CurrentExtensionModuleInfo.Id());
        if not IsAssigned then
            IsAssigned := UserPermissions.IsSuper(UserSecurityId());
    end;

    /// <summary>
    /// Checks if a permission set is directly assigned to a user, ignoring app and scope filters.
    /// Based on HasUserPermissionSetAssigned in codeunit 153 "User Permissions Impl."
    /// </summary>
    /// <param name="UserSecurityId">The security ID of the user to check.</param>
    /// <param name="RoleId">The role ID to look for.</param>
    /// <returns>True if the role is directly assigned to the user; otherwise, false.</returns>
    local procedure HasUserPermissionSetDirectlyAssigned(UserSecurityId: Guid; RoleId: Code[20]): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId);
        AccessControl.SetRange("Role ID", RoleId);
        AccessControl.SetFilter("Company Name", '%1|%2', '', CompanyName());
        exit(not AccessControl.IsEmpty());
    end;

    local procedure CanInsertTableData(TableId: Integer): Boolean
    var
        TempExpandedPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        TempExpandedPermission := UserPermissions.GetEffectivePermission(TempExpandedPermission."Object Type"::"Table Data", TableId);
        exit(TempExpandedPermission."Insert Permission" in [TempExpandedPermission."Insert Permission"::Yes, TempExpandedPermission."Insert Permission"::Indirect]);
    end;

    local procedure CanModifyTableData(TableId: Integer): Boolean
    var
        TempExpandedPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        TempExpandedPermission := UserPermissions.GetEffectivePermission(TempExpandedPermission."Object Type"::"Table Data", TableId);
        exit(TempExpandedPermission."Modify Permission" in [TempExpandedPermission."Modify Permission"::Yes, TempExpandedPermission."Modify Permission"::Indirect]);
    end;

    local procedure CanDeleteTableData(TableId: Integer): Boolean
    var
        TempExpandedPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        TempExpandedPermission := UserPermissions.GetEffectivePermission(TempExpandedPermission."Object Type"::"Table Data", TableId);
        exit(TempExpandedPermission."Delete Permission" in [TempExpandedPermission."Delete Permission"::Yes, TempExpandedPermission."Delete Permission"::Indirect]);
    end;
    #endregion Verify Permissions
}
