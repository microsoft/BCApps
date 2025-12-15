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
        CurrentUserId: Text;
        ExpressOnlyCaptionEditLineCommentsLbl: Label 'Edit Line Note/Comment';
        ExpressOnlyCaptionCreateTestManualLbl: Label 'Create Test Manual';
        ExpressOnlyCaptionCreateTestAutoLbl: Label 'Create Test Auto';
        ExpressOnlyCaptionCreateRetestLbl: Label 'Create Retest';
        ExpressOnlyCaptionDeleteOpenTestLbl: Label 'Delete Open Test';
        ExpressOnlyCaptionDeleteFinishedTestLbl: Label 'Delete Finished Test';
        ExpressOnlyCaptionChangeOthersTestsLbl: Label 'Change Others Tests';
        ExpressOnlyCaptionReopenTestLbl: Label 'Reopen Test';
        ExpressOnlyCaptionFinishTestLbl: Label 'Finish Test';
        ExpressOnlyCaptionChangeTrackingNoLbl: Label 'Change Tracking No.';
        ExpressOnlyCaptionChangeSourceQuantityLbl: Label 'Change Source Quantity';
        ExpectedSupervisorRoleIDTxt: Label 'QltyGeneral', Locked = true;
        UserDoesNotHavePermissionToErr: Label 'The user [%1] does not have permission to [%2]. This can be changed by navigating to Quality Management Permissions.', Comment = '%1=User id, %2=permission being attempted';

    /// <summary>
    /// CanReadTestResults returns true if the current user can has permission to read test results in general.
    /// </summary>
    /// <returns>Return value of type Boolean, true if the current user can has permission to read test results in general</returns>
    procedure CanReadTestResults(): Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        exit(QltyInspectionHeader.ReadPermission());
    end;

    /// <summary>
    /// TestCanCreateManualTest will determine if the current user can create a manual test.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanCreateManualTest()
    begin
        if not CanCreateManualTest() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionCreateTestManual());
    end;

    /// <summary>
    /// CanCreateManualTest. True if the user can create a manual test
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanCreateManualTest(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionCreateTestManual()));
    end;

    /// <summary>
    /// TestCanCreateAutoTest will determine if the current user can create an automatic test.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanCreateAutoTest()
    begin
        if not CanCreateAutoTest() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionCreateTestAuto());
    end;

    /// <summary>
    /// CanCreateAutoTest. True if the user can create a manual test
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanCreateAutoTest(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionCreateTestAuto()));
    end;

    /// <summary>
    /// TestCanCreateReTest will determine if the current user can create a retest.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanCreateReTest()
    begin
        if not CanCreateReTest() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionCreateReTest());
    end;

    /// <summary>
    /// CanCreateReTest. True if the user can create a retest.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanCreateReTest(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionCreateReTest()));
    end;

    /// <summary>
    /// TestCanDeleteOpenTest will determine if the current user can delete an open inspection.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanDeleteOpenTest()
    begin
        if not CanDeleteOpenTest() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionDeleteOpenTest());
    end;

    /// <summary>
    /// CanDeleteOpenTest. True if the user  can delete an open inspection.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanDeleteOpenTest(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionDeleteOpenTest()));
    end;

    /// <summary>
    /// TestCanDeleteFinishedInspection will determine if the current user can delete a finished test.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanDeleteFinishedInspection()
    begin
        if not CanDeleteFinishedTest() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionDeleteFinishedTest());
    end;

    /// <summary>
    /// CanDeleteFinishedTest. True if the user can delete a finished test.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanDeleteFinishedTest(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionDeleteFinishedTest()));
    end;

    /// <summary>
    /// TestCanChangeOthersTests will determine if the current user can change someone else's tests.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanChangeOthersTests()
    begin
        if not CanChangeOthersTests() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionChangeOthersTests());
    end;

    /// <summary>
    /// CanChangeOthersTests. True if the user can change someone else's tests.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanChangeOthersTests(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionChangeOthersTests()));
    end;

    /// <summary>
    /// TestCanReopenTest will determine if the current user can re-open a test.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanReopenTest()
    begin
        if not CanReopenTest() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionReopenTest());
    end;

    /// <summary>
    /// CanReopenTest. True if the user can re-open a test.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanReopenTest(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionReopenTest()));
    end;

    /// <summary>
    /// TestCanFinishTest will determine if the current user can finish a test.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanFinishTest()
    begin
        if not CanFinishTest() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionFinishTest());
    end;

    /// <summary>
    /// CanFinishTest. True if the user can can finish a test.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanFinishTest(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionFinishTest()));
    end;

    /// <summary>
    /// TestCanChangeTrackingNo will determine if the current user can change the tracking on a test.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanChangeTrackingNo()
    begin
        if not CanChangeTrackingNo() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionChangeTrackingNo());
    end;

    /// <summary>
    /// CanChangeTrackingNo. True if the user can change the tracking on a test.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanChangeTrackingNo(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionChangeTrackingNo()));
    end;

    /// <summary>
    /// Returns whether or not auto assignment should occur based on the permissions records.
    /// </summary>
    /// <param name="ShouldPrompt">Only set with interaction ability is available ( GuiAllowed() is true ) and also prompt when possible is chosen.</param>
    /// <returns>Whether or not auto-assignment should occur.</returns>
    procedure GetShouldAutoAssign(var ShouldPrompt: Boolean) ShouldAssign: Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        ShouldAssign := QltyInspectionHeader.WritePermission();
        ShouldPrompt := false;
    end;

    local procedure LoadPermissionDetails(FunctionalPermission: Text): Boolean
    begin
        CurrentUserId := UserId();

        exit(GetSuggestedAllowedValueForFunction(FunctionalPermission));
    end;

    /// <summary>
    /// For the given function, this gives the suggested allowed state.
    /// </summary>
    /// <param name="FunctionalPermission"></param>
    /// <returns></returns>
    procedure GetSuggestedAllowedValueForFunction(FunctionalPermission: Text) Result: Boolean
    begin
        case FunctionalPermission of
            GetCaptionCreateTestAuto():
                Result := true;
            GetCaptionCreateTestManual():
                Result := GetCanInsertTableData(Database::"Qlty. Inspection Header");
            GetCaptionCreateReTest():
                Result := GetCanInsertTableData(Database::"Qlty. Inspection Header");
            GetCaptionChangeOthersTests():
                Result := GetIsSuperVisorRoleAssigned();
            GetCaptionDeleteFinishedTest():
                Result := GetCanDeleteTableData(Database::"Qlty. Inspection Header") and GetIsSuperVisorRoleAssigned();
            GetCaptionDeleteOpenTest():
                Result := GetCanDeleteTableData(Database::"Qlty. Inspection Header");
            GetCaptionChangeTrackingNo():
                Result := GetCanModifyTableData(Database::"Qlty. Inspection Header");
            GetCaptionFinishTest():
                Result := GetCanModifyTableData(Database::"Qlty. Inspection Header");
            GetCaptionReopenTest():
                Result := GetCanModifyTableData(Database::"Qlty. Inspection Header");
            GetCaptionChangeSourceQuantity():
                Result := GetCanModifyTableData(Database::"Qlty. Inspection Header") and GetIsSuperVisorRoleAssigned();
            GetCaptionEditLineComments():
                Result := GetCanModifyTableData(Database::"Record Link");
        end;
    end;

    local procedure GetCanDeleteTableData(TableId: Integer): Boolean
    var
        TempExpandedPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        TempExpandedPermission := UserPermissions.GetEffectivePermission(TempExpandedPermission."Object Type"::"Table Data", TableId);
        exit(TempExpandedPermission."Delete Permission" in [TempExpandedPermission."Delete Permission"::Yes, TempExpandedPermission."Delete Permission"::Indirect]);
    end;

    local procedure GetCanInsertTableData(TableId: Integer): Boolean
    var
        TempExpandedPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        TempExpandedPermission := UserPermissions.GetEffectivePermission(TempExpandedPermission."Object Type"::"Table Data", TableId);
        exit(TempExpandedPermission."Insert Permission" in [TempExpandedPermission."Insert Permission"::Yes, TempExpandedPermission."Insert Permission"::Indirect]);
    end;

    local procedure GetCanModifyTableData(TableId: Integer): Boolean
    var
        TempExpandedPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        TempExpandedPermission := UserPermissions.GetEffectivePermission(TempExpandedPermission."Object Type"::"Table Data", TableId);
        exit(TempExpandedPermission."Modify Permission" in [TempExpandedPermission."Modify Permission"::Yes, TempExpandedPermission."Modify Permission"::Indirect]);
    end;

    local procedure GetIsSuperVisorRoleAssigned() IsAssigned: Boolean
    var
        UserPermissions: Codeunit "User Permissions";
        CurrentExtensionModuleInfo: ModuleInfo;
    begin
        IsAssigned := HasUserPermissionSetDirectlyAssigned(UserSecurityId(), ExpectedSupervisorRoleIDTxt);
        if not IsAssigned then
            if NavApp.GetCurrentModuleInfo(CurrentExtensionModuleInfo) then
                IsAssigned := UserPermissions.HasUserPermissionSetAssigned(UserSecurityId(), CompanyName(), ExpectedSupervisorRoleIDTxt, 0, CurrentExtensionModuleInfo.Id);
        if not IsAssigned then
            IsAssigned := UserPermissions.IsSuper(UserSecurityId());
    end;

    /// <summary>
    /// This is based on HasUserPermissionSetAssigned in codeunit 153 "User Permissions Impl.", but unfortunately 
    /// that method will force check the app and scope, which won't always be correct.  We just want if the role is assigned
    /// to the user.
    /// </summary>
    /// <param name="UserSecurityId"></param>
    /// <param name="RoleId"></param>
    /// <returns></returns>
    local procedure HasUserPermissionSetDirectlyAssigned(UserSecurityId: Guid; RoleId: Code[20]): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId);
        AccessControl.SetRange("Role ID", RoleId);
        AccessControl.SetFilter("Company Name", '%1|%2', '', CompanyName());
        exit(not AccessControl.IsEmpty());
    end;

    /// <summary>
    /// TestCanChangeQuantity will determine if the current user can change the source quantity.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanChangeSourceQuantity()
    begin
        if not CanChangeSourceQuantity() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionChangeSourceQuantity());
    end;

    /// <summary>
    /// CanChangeSourceQuantity. True if the user can change source quantities
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanChangeSourceQuantity(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionChangeSourceQuantity()));
    end;

    /// <summary>
    /// TestCanEditLineComments will determine if the current user can edit line comments.
    /// If they can, nothing happens.
    /// If they cannot then an error will be thrown.
    /// </summary>
    procedure TestCanEditLineComments()
    begin
        if not CanEditLineComments() then
            Error(UserDoesNotHavePermissionToErr, CurrentUserId, GetCaptionEditLineComments());
    end;

    /// <summary>
    /// CanChangeTestLineComments. True if the user can add line notes/comments.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanEditLineComments(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionEditLineComments()));
    end;

    /// <summary>
    /// CanReadLineComments. True if the user can read or write line comments.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanReadLineComments(): Boolean
    begin
        exit(LoadPermissionDetails(GetCaptionEditLineComments()));
    end;

    local procedure GetCaptionCreateTestManual(): Text
    begin
        exit(ExpressOnlyCaptionCreateTestManualLbl);
    end;

    local procedure GetCaptionCreateTestAuto(): Text
    begin
        exit(ExpressOnlyCaptionCreateTestAutoLbl);
    end;

    local procedure GetCaptionCreateReTest(): Text
    begin
        exit(ExpressOnlyCaptionCreateRetestLbl);
    end;

    local procedure GetCaptionDeleteOpenTest(): Text
    begin
        exit(ExpressOnlyCaptionDeleteOpenTestLbl);
    end;

    local procedure GetCaptionDeleteFinishedTest(): Text
    begin
        exit(ExpressOnlyCaptionDeleteFinishedTestLbl);
    end;

    local procedure GetCaptionChangeOthersTests(): Text
    begin
        exit(ExpressOnlyCaptionChangeOthersTestsLbl);
    end;

    local procedure GetCaptionReopenTest(): Text
    begin
        exit(ExpressOnlyCaptionReopenTestLbl);
    end;

    local procedure GetCaptionFinishTest(): Text
    begin
        exit(ExpressOnlyCaptionFinishTestLbl);
    end;

    local procedure GetCaptionChangeTrackingNo(): Text
    begin
        exit(ExpressOnlyCaptionChangeTrackingNoLbl);
    end;

    local procedure GetCaptionChangeSourceQuantity(): Text
    begin
        exit(ExpressOnlyCaptionChangeSourceQuantityLbl);
    end;

    local procedure GetCaptionEditLineComments(): Text
    begin
        exit(ExpressOnlyCaptionEditLineCommentsLbl);
    end;
}
