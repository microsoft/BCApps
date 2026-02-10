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
/// Permission management methods to help with functional permissions.
/// </summary>
codeunit 20406 "Qlty. Permission Mgmt."
{
    InherentPermissions = X;

    var
        ActionCreateInspectionManuallyLbl: Label 'create inspection manually';
        ActionCreateInspectionAutomaticallyLbl: Label 'create inspection automatically';
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
    /// CanReadInspectionResults returns true if the current user can has permission to read inspection results in general.
    /// </summary>
    /// <returns>Return value of type Boolean, true if the current user can has permission to read inspection results in general</returns>
    internal procedure CanReadInspectionResults(): Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        exit(QltyInspectionHeader.ReadPermission());
    end;

    /// <summary>
    /// CanCreateManualInspection. True if the user can create a manual inspection
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanCreateManualInspection(): Boolean
    begin
        exit(CheckPermissionDetails(ActionCreateInspectionManuallyLbl));
    end;

    /// <summary>
    /// Determines if the current user can create a manual inspection.
    /// </summary>
    internal procedure VerifyCanCreateManualInspection()
    begin
        if not CanCreateManualInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionCreateInspectionManuallyLbl);
    end;

    /// <summary>
    /// CanCreateAutoInspection. True if the user can create an automatic inspection
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanCreateAutoInspection(): Boolean
    begin
        exit(CheckPermissionDetails(ActionCreateInspectionAutomaticallyLbl));
    end;

    /// <summary>
    /// Determines if the current user can create an automatic inspection.
    /// </summary>
    internal procedure VerifyCanCreateAutoInspection()
    begin
        if not CanCreateAutoInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionCreateInspectionAutomaticallyLbl);
    end;

    /// <summary>
    /// CanCreateReinspection. True if the user can create a re-inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanCreateReinspection(): Boolean
    begin
        exit(CheckPermissionDetails(ActionCreateReinspectionLbl));
    end;

    /// <summary>
    /// Determines if the current user can create a re-inspection.
    /// </summary>
    internal procedure VerifyCanCreateReinspection()
    begin
        if not CanCreateReinspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionCreateReinspectionLbl);
    end;

    /// <summary>
    /// CanChangeOtherInspections. True if the user can change someone else's inspections.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanChangeOtherInspections(): Boolean
    begin
        exit(CheckPermissionDetails(ActionChangeOthersInspectionLbl));
    end;

    /// <summary>
    /// Determines if the current user can change someone else's inspections.
    /// </summary>
    internal procedure VerifyCanChangeOtherInspections()
    begin
        if not CanChangeOtherInspections() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionChangeOthersInspectionLbl);
    end;

    /// <summary>
    /// CanFinishInspection. True if the user can can finish an inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanFinishInspection(): Boolean
    begin
        exit(CheckPermissionDetails(ActionFinishInspectionLbl));
    end;

    /// <summary>
    /// Determines if the current user can finish an inspection.
    /// </summary>
    internal procedure VerifyCanFinishInspection()
    begin
        if not CanFinishInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionFinishInspectionLbl);
    end;

    /// <summary>
    /// CanReopenInspection. True if the user can re-open an inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanReopenInspection(): Boolean
    begin
        exit(CheckPermissionDetails(ActionReopenInspectionLbl));
    end;

    /// <summary>
    /// Determines if the current user can re-open an inspection.
    /// </summary>
    internal procedure VerifyCanReopenInspection()
    begin
        if not CanReopenInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionReopenInspectionLbl);
    end;

    /// <summary>
    /// CanDeleteOpenInspection. True if the user  can delete an open inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanDeleteOpenInspection(): Boolean
    begin
        exit(CheckPermissionDetails(ActionDeleteOpenInspectionLbl));
    end;

    /// <summary>
    /// Determines if the current user can delete an open inspection.
    /// </summary>
    internal procedure VerifyCanDeleteOpenInspection()
    begin
        if not CanDeleteOpenInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionDeleteOpenInspectionLbl);
    end;

    /// <summary>
    /// CanDeleteFinishedInspection. True if the user can delete a finished inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanDeleteFinishedInspection(): Boolean
    begin
        exit(CheckPermissionDetails(ActionDeleteFinishedInspectionLbl));
    end;

    /// <summary>
    /// Determines if the current user can delete a finished inspection.
    /// </summary>
    internal procedure VerifyCanDeleteFinishedInspection()
    begin
        if not CanDeleteFinishedInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionDeleteFinishedInspectionLbl);
    end;

    /// <summary>
    /// CanChangeTrackingNo. True if the user can change the tracking on an inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanChangeTrackingNo(): Boolean
    begin
        exit(CheckPermissionDetails(ActionChangeItemTrackingLbl));
    end;

    /// <summary>
    /// Determines if the current user can change the tracking on an inspection.
    /// </summary>
    internal procedure VerifyCanChangeTrackingNo()
    begin
        if not CanChangeTrackingNo() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionChangeItemTrackingLbl);
    end;

    /// <summary>
    /// CanChangeSourceQuantity. True if the user can change source quantities
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanChangeSourceQuantity(): Boolean
    begin
        exit(CheckPermissionDetails(ActionChangeSourceQuantityLbl));
    end;

    /// <summary>
    /// Determines if the current user can change the source quantity.
    /// </summary>
    internal procedure VerifyCanChangeSourceQuantity()
    begin
        if not CanChangeSourceQuantity() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionChangeSourceQuantityLbl);
    end;

    /// <summary>
    /// CanEditLineComments. True if the user can add line notes/comments.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanEditLineComments(): Boolean
    begin
        exit(CheckPermissionDetails(ActionEditLineCommentLbl));
    end;

    /// <summary>
    /// Determines if the current user can edit line comments.
    /// </summary>
    internal procedure VerifyCanEditLineComments()
    begin
        if not CanEditLineComments() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionEditLineCommentLbl);
    end;

    /// <summary>
    /// Returns whether or not auto assignment should occur based on the permissions records.
    /// </summary>
    /// <param name="ShouldPrompt">Only set with interaction ability is available ( GuiAllowed() is true ) and also prompt when possible is chosen.</param>
    /// <returns>Whether or not auto-assignment should occur.</returns>
    internal procedure GetShouldAutoAssign(var ShouldPrompt: Boolean) ShouldAssign: Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        ShouldAssign := QltyInspectionHeader.WritePermission();
        ShouldPrompt := false;
    end;

    /// <summary>
    /// For the given function, this gives the suggested allowed state.
    /// </summary>
    /// <param name="FunctionalPermission"></param>
    /// <returns></returns>
    local procedure CheckPermissionDetails(FunctionalPermission: Text) Result: Boolean
    begin
        case FunctionalPermission of
            ActionCreateInspectionManuallyLbl:
                Result := CanInsertTableData(Database::"Qlty. Inspection Header");
            ActionCreateInspectionAutomaticallyLbl:
                Result := true;
            ActionCreateReinspectionLbl:
                Result := CanInsertTableData(Database::"Qlty. Inspection Header");
            ActionChangeOthersInspectionLbl:
                Result := HasSupervisorRole();
            ActionFinishInspectionLbl:
                Result := CanModifyTableData(Database::"Qlty. Inspection Header");
            ActionReopenInspectionLbl:
                Result := CanModifyTableData(Database::"Qlty. Inspection Header");
            ActionDeleteOpenInspectionLbl:
                Result := CanDeleteTableData(Database::"Qlty. Inspection Header");
            ActionDeleteFinishedInspectionLbl:
                if CanDeleteTableData(Database::"Qlty. Inspection Header") then
                    Result := HasSupervisorRole();
            ActionChangeItemTrackingLbl:
                Result := CanModifyTableData(Database::"Qlty. Inspection Header");
            ActionChangeSourceQuantityLbl:
                if CanModifyTableData(Database::"Qlty. Inspection Header") then
                    Result := HasSupervisorRole();
            ActionEditLineCommentLbl:
                Result := CanModifyTableData(Database::"Record Link");
        end;
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
    /// Check if the role is directly assigned to the user, without considering app and scope filters.
    /// Inspired by HasUserPermissionSetAssigned in codeunit 153 "User Permissions Impl."
    /// </summary>
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
