// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Test.QualityManagement.TestLibraries;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 139957 "Qlty. Tests - Permission Mgmt."
{
    Subtype = Test;
    TestPermissions = Restrictive;
    TestType = UnitTest;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        LibraryAssert: Codeunit "Library Assert";
        UserDoesNotHavePermissionToErr: Label 'The user [%1] does not have permission to [%2].', Comment = '%1=User id, %2=permission being attempted';
        AdminSupervisorRoleIDTok: Label 'QltyMgmt - Admin', Locked = true;
        InspectorRoleIDTok: Label 'QltyMgmt - Inspector', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanDeleteFinishedInspection_ShouldError()
    begin
        // [SCENARIO] Verify that deleting a finished inspection without the administrator role raises an error
        // [GIVEN] The inspector role permission set is added
        InitializePermissions(InspectorRoleIDTok);

        // [WHEN] VerifyCanDeleteFinishedInspection is called
        // [THEN] An error is raised indicating the user lacks permission to delete a finished inspection
        asserterror QltyInspectionUtility.VerifyCanDeleteFinishedInspection();
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'delete finished inspection'));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanDeleteFinishedInspection()
    begin
        // [SCENARIO] Verify that deleting a finished inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        InitializePermissions(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanDeleteFinishedInspection is called        
        QltyInspectionUtility.VerifyCanDeleteFinishedInspection();

        // [THEN] The operation succeeds and CanDeleteFinishedInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanDeleteFinishedInspection(), 'allowed with supervisor role');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanChangeOtherInspections()
    begin
        // [SCENARIO] Verify that changing other users' inspections succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        InitializePermissions(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeOtherInspections is called
        QltyInspectionUtility.VerifyCanChangeOtherInspections();

        // [THEN] The operation succeeds and CanChangeOtherInspections returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeOtherInspections(), 'allowed with supervisor role');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanChangeOtherInspections_ShouldError()
    begin
        // [SCENARIO] Verify that changing another user's inspection without the administrator role raises an error
        // [GIVEN] The inspector role permission set is added
        InitializePermissions(InspectorRoleIDTok);

        // [WHEN] VerifyCanChangeOtherInspections is called
        // [THEN] An error is raised indicating the user lacks permission to change other inspections
        asserterror QltyInspectionUtility.VerifyCanChangeOtherInspections();
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'change others inspection'));
        LibraryAssert.IsFalse(QltyInspectionUtility.CanChangeOtherInspections(), 'not allowed without administrator role');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanReopenInspection_ShouldError()
    begin
        // [SCENARIO] Verify that reopening an inspection without the administrator role raises an error
        // [GIVEN] The inspector role permission set is added
        InitializePermissions(InspectorRoleIDTok);

        // [WHEN] VerifyCanReopenInspection is called
        // [THEN] An error is raised indicating the user lacks permission to reopen an inspection
        asserterror QltyInspectionUtility.VerifyCanReopenInspection();
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'reopen inspection'));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanReopenInspection()
    begin
        // [SCENARIO] Verify that reopening an inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        InitializePermissions(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanReopenInspection is called
        QltyInspectionUtility.VerifyCanReopenInspection();

        // [THEN] No errors is raised
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanChangeSourceQuantity_ShouldError()
    begin
        // [SCENARIO] Verify that changing source quantity without the administrator role raises an error
        // [GIVEN] The inspector role permission set is added
        InitializePermissions(InspectorRoleIDTok);

        // [WHEN] VerifyCanChangeSourceQuantity is called
        // [THEN] An error is raised indicating the user lacks permission to change source quantity
        asserterror QltyInspectionUtility.VerifyCanChangeSourceQuantity();
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'change source quantity'));
        LibraryAssert.IsFalse(QltyInspectionUtility.CanChangeSourceQuantity(), 'not allowed without administrator role');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanChangeSourceQuantity()
    begin
        // [SCENARIO] Verify that changing source quantity succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        InitializePermissions(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeSourceQuantity is called
        QltyInspectionUtility.VerifyCanChangeSourceQuantity();

        // [THEN] The operation succeeds and CanChangeSourceQuantity returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeSourceQuantity(), 'allowed with administrator role');
    end;

    local procedure InitializePermissions(PermissionSetRoleID: Code[20])
    var
        AccessControl: Record "Access Control";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        User: Record User;
        UserPermissions: Codeunit "User Permissions";
    begin
        LibraryLowerPermissions.PushPermissionSet('SUPER');

        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.DeleteAll();
        if User.Get(UserSecurityId()) then
            User.Delete();
        if User.IsEmpty() then begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := CopyStr(Format(User."User Security ID"), 1, MaxStrLen(User."User Name"));
            User.Insert();
        end;

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
        AggregatePermissionSet.SetRange("Role ID", PermissionSetRoleID);
        AggregatePermissionSet.FindFirst();

        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId();
        AccessControl."Role ID" := AggregatePermissionSet."Role ID";
        AccessControl.Scope := AggregatePermissionSet.Scope;
        AccessControl."App ID" := AggregatePermissionSet."App ID";
        AccessControl."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(AccessControl."Company Name"));
        AccessControl.Insert();

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.AddPermissionSet(PermissionSetRoleID);
        LibraryAssert.IsFalse(UserPermissions.IsSuper(UserSecurityId()), 'The test user must not have SUPER permissions.');
    end;

}
