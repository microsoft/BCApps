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
        ActionCreateInspectionManuallyLbl: Label 'Create Inspection manually';
        ActionEditLineCommentsLbl: Label 'Edit Line Note/Comment';
        ActionCreateInspectionAutoLbl: Label 'Create Inspection Auto';
        ActionCreateReinspectionLbl: Label 'Create Re-inspection';
        ActionDeleteOpenInspectionLbl: Label 'Delete Open Inspection';
        ActionDeleteFinishedInspectionLbl: Label 'Delete Finished Inspection';
        ActionChangeOthersInspectionsLbl: Label 'Change Others Inspections';
        ActionReopenInspectionLbl: Label 'Reopen Inspection';
        ActionFinishInspectionLbl: Label 'Finish Inspection';
        ActionChangeTrackingNoLbl: Label 'Change Tracking No.';
        ActionChangeSourceQuantityLbl: Label 'Change Source Quantity';
        SupervisorRoleIDTxt: Label 'QltyMngmnt - Edit', Locked = true;
        UserDoesNotHavePermissionToErr: Label 'The user [%1] does not have permission to [%2]. This can be changed by navigating to Quality Management Permissions.', Comment = '%1=User id, %2=permission being attempted';

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
    /// Determines if the current user can create a manual inspection.
    /// </summary>
    internal procedure VerifyCanCreateManualInspection()
    begin
        if not CanCreateManualInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionCreateInspectionManuallyLbl);
    end;

    /// <summary>
    /// CanCreateManualInspection. True if the user can create a manual inspection
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanCreateManualInspection(): Boolean
    begin
        exit(LoadPermissionDetails(ActionCreateInspectionManuallyLbl));
    end;

    /// <summary>
    /// Determines if the current user can create an automatic inspection.
    /// </summary>
    internal procedure VerifyCanCreateAutoInspection()
    begin
        if not CanCreateAutoInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionCreateInspectionAutoLbl);
    end;

    /// <summary>
    /// CanCreateAutoInspection. True if the user can create an automatic inspection
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanCreateAutoInspection(): Boolean
    begin
        exit(LoadPermissionDetails(ActionCreateInspectionAutoLbl));
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
    /// CanCreateReinspection. True if the user can create a re-inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanCreateReinspection(): Boolean
    begin
        exit(LoadPermissionDetails(ActionCreateReinspectionLbl));
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
    /// CanDeleteOpenInspection. True if the user  can delete an open inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanDeleteOpenInspection(): Boolean
    begin
        exit(LoadPermissionDetails(ActionDeleteOpenInspectionLbl));
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
    /// CanDeleteFinishedInspection. True if the user can delete a finished inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanDeleteFinishedInspection(): Boolean
    begin
        exit(LoadPermissionDetails(ActionDeleteFinishedInspectionLbl));
    end;

    /// <summary>
    /// Determines if the current user can change someone else's inspections.
    /// </summary>
    internal procedure VerifyCanChangeOtherInspections()
    begin
        if not CanChangeOtherInspections() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionChangeOthersInspectionsLbl);
    end;

    /// <summary>
    /// CanChangeOtherInspections. True if the user can change someone else's inspections.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanChangeOtherInspections(): Boolean
    begin
        exit(LoadPermissionDetails(ActionChangeOthersInspectionsLbl));
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
    /// CanReopenInspection. True if the user can re-open an inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanReopenInspection(): Boolean
    begin
        exit(LoadPermissionDetails(ActionReopenInspectionLbl));
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
    /// CanFinishInspection. True if the user can can finish an inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanFinishInspection(): Boolean
    begin
        exit(LoadPermissionDetails(ActionFinishInspectionLbl));
    end;

    /// <summary>
    /// Determines if the current user can change the tracking on an inspection.
    /// </summary>
    internal procedure VerifyCanChangeTrackingNo()
    begin
        if not CanChangeTrackingNo() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionChangeTrackingNoLbl);
    end;

    /// <summary>
    /// CanChangeTrackingNo. True if the user can change the tracking on an inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanChangeTrackingNo(): Boolean
    begin
        exit(LoadPermissionDetails(ActionChangeTrackingNoLbl));
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

    local procedure LoadPermissionDetails(FunctionalPermission: Text): Boolean
    begin
        exit(GetSuggestedAllowedValueForFunction(FunctionalPermission));
    end;

    /// <summary>
    /// Determines if the current user can edit line comments.
    /// </summary>
    internal procedure VerifyCanEditLineComments()
    begin
        if not CanEditLineComments() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionEditLineCommentsLbl);
    end;

    /// <summary>
    /// CanEditLineComments. True if the user can add line notes/comments.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanEditLineComments(): Boolean
    begin
        exit(LoadPermissionDetails(ActionEditLineCommentsLbl));
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
    /// CanChangeSourceQuantity. True if the user can change source quantities
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanChangeSourceQuantity(): Boolean
    begin
        exit(LoadPermissionDetails(ActionChangeSourceQuantityLbl));
    end;

    /// <summary>
    /// CanReadLineComments. True if the user can read or write line comments.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    internal procedure CanReadLineComments(): Boolean
    begin
        exit(LoadPermissionDetails(ActionEditLineCommentsLbl));
    end;

    /// <summary>
    /// For the given function, this gives the suggested allowed state.
    /// </summary>
    /// <param name="FunctionalPermission"></param>
    /// <returns></returns>
    local procedure GetSuggestedAllowedValueForFunction(FunctionalPermission: Text) Result: Boolean
    begin
        case FunctionalPermission of
            ActionCreateInspectionAutoLbl:
                Result := true;
            ActionCreateInspectionManuallyLbl:
                Result := CanInsertTableData(Database::"Qlty. Inspection Header");
            ActionCreateReinspectionLbl:
                Result := CanInsertTableData(Database::"Qlty. Inspection Header");
            ActionChangeOthersInspectionsLbl:
                Result := HasSupervisorRole();
            ActionDeleteFinishedInspectionLbl:
                Result := CanDeleteTableData(Database::"Qlty. Inspection Header") and HasSupervisorRole();
            ActionDeleteOpenInspectionLbl:
                Result := CanDeleteTableData(Database::"Qlty. Inspection Header");
            ActionChangeTrackingNoLbl:
                Result := CanModifyTableData(Database::"Qlty. Inspection Header");
            ActionFinishInspectionLbl:
                Result := CanModifyTableData(Database::"Qlty. Inspection Header");
            ActionReopenInspectionLbl:
                Result := CanModifyTableData(Database::"Qlty. Inspection Header");
            ActionChangeSourceQuantityLbl:
                Result := CanModifyTableData(Database::"Qlty. Inspection Header") and HasSupervisorRole();
            ActionEditLineCommentsLbl:
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
