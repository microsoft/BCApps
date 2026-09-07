// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.AccessControl;

using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Provides permission management methods for Quality Management functional permissions.
/// </summary>
codeunit 20406 "Qlty. Permission Mgmt."
{
    InherentPermissions = X;
    Access = Internal;

    var
        ActionChangeOthersInspectionLbl: Label 'change others inspection';
        ActionReopenInspectionLbl: Label 'reopen inspection';
        ActionDeleteFinishedInspectionLbl: Label 'delete finished inspection';
        ActionChangeSourceQuantityLbl: Label 'change source quantity';
        AdminSupervisorRoleIDTxt: Label 'QltyMgmt - Admin', Locked = true;
        UserDoesNotHavePermissionToErr: Label 'The user [%1] does not have permission to [%2].', Comment = '%1=User id, %2=permission being attempted';

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
        exit(HasAdminSupervisorRole());
    end;

    /// <summary>
    /// Verifies the current user can reopen an inspection. Throws an error if not permitted.
    /// </summary>
    internal procedure VerifyCanReopenInspection()
    begin
        if not CanReopenInspection() then
            Error(UserDoesNotHavePermissionToErr, UserId(), ActionReopenInspectionLbl);
    end;

    /// <summary>
    /// Checks if the current user can reopen an inspection.
    /// </summary>
    /// <returns>True if the user can reopen an inspection; otherwise, false.</returns>
    local procedure CanReopenInspection(): Boolean
    begin
        exit(HasAdminSupervisorRole());
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
        exit(HasAdminSupervisorRole());
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
        exit(HasAdminSupervisorRole());
    end;

    #region Verify Permissions
    /// <summary>
    /// Determines whether the current user has the Quality Management administrator role or SUPER permissions.
    /// </summary>
    /// <returns>True if the user has administrator or SUPER permissions; otherwise, false.</returns>
    local procedure HasAdminSupervisorRole() IsAssigned: Boolean
    var
        UserPermissions: Codeunit "User Permissions";
        CurrentExtensionModuleInfo: ModuleInfo;
    begin
        IsAssigned := HasUserPermissionSetDirectlyAssigned(UserSecurityId(), AdminSupervisorRoleIDTxt);
        if not IsAssigned then
            if NavApp.GetCurrentModuleInfo(CurrentExtensionModuleInfo) then
                IsAssigned := UserPermissions.HasUserPermissionSetAssigned(UserSecurityId(), CompanyName(), AdminSupervisorRoleIDTxt, 0, CurrentExtensionModuleInfo.Id());
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

    #endregion Verify Permissions
}
