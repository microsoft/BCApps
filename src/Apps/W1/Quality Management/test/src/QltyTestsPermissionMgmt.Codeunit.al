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
        TestUser: Record User;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        LibraryAssert: Codeunit "Library Assert";
        UserDoesNotHavePermissionToErr: Label 'The user [%1] does not have permission to [%2].', Comment = '%1=User id, %2=permission being attempted';
        AdminSupervisorRoleIDTok: Label 'QltyMgmt - Admin', Locked = true;
        InspectorRoleIDTok: Label 'QltyMgmt - Inspector', Locked = true;
        SuperRoleIDTok: Label 'SUPER', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanDeleteFinishedInspection_ShouldError()
    begin
        // [SCENARIO] Verify that deleting a finished inspection without the administrator role raises an error
        // [GIVEN] The inspector role permission set is added
        InitializePermissions(InspectorRoleIDTok);

        // [WHEN] VerifyCanDeleteFinishedInspection is called
        // [THEN] An error is raised indicating the user lacks permission to delete a finished inspection
        asserterror QltyInspectionUtility.VerifyCanDeleteFinishedInspection(TestUser."User Security ID");
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, TestUser."User Name", 'delete finished inspection'));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanDeleteFinishedInspection()
    begin
        // [SCENARIO] Verify that deleting a finished inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        InitializePermissions(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanDeleteFinishedInspection is called        
        QltyInspectionUtility.VerifyCanDeleteFinishedInspection(TestUser."User Security ID");

        // [THEN] The operation succeeds and CanDeleteFinishedInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanDeleteFinishedInspection(TestUser."User Security ID"), 'allowed with supervisor role');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanChangeOtherInspections()
    begin
        // [SCENARIO] Verify that changing other users' inspections succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        InitializePermissions(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeOtherInspections is called
        QltyInspectionUtility.VerifyCanChangeOtherInspections(TestUser."User Security ID");

        // [THEN] The operation succeeds and CanChangeOtherInspections returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeOtherInspections(TestUser."User Security ID"), 'allowed with supervisor role');
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
        asserterror QltyInspectionUtility.VerifyCanChangeOtherInspections(TestUser."User Security ID");
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, TestUser."User Name", 'change others inspection'));
        LibraryAssert.IsFalse(QltyInspectionUtility.CanChangeOtherInspections(TestUser."User Security ID"), 'not allowed without administrator role');
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
        asserterror QltyInspectionUtility.VerifyCanReopenInspection(TestUser."User Security ID");
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, TestUser."User Name", 'reopen inspection'));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanReopenInspection()
    begin
        // [SCENARIO] Verify that reopening an inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        InitializePermissions(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanReopenInspection is called
        QltyInspectionUtility.VerifyCanReopenInspection(TestUser."User Security ID");

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
        asserterror QltyInspectionUtility.VerifyCanChangeSourceQuantity(TestUser."User Security ID");
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, TestUser."User Name", 'change source quantity'));
        LibraryAssert.IsFalse(QltyInspectionUtility.CanChangeSourceQuantity(TestUser."User Security ID"), 'not allowed without administrator role');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyCanChangeSourceQuantity()
    begin
        // [SCENARIO] Verify that changing source quantity succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        InitializePermissions(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeSourceQuantity is called
        QltyInspectionUtility.VerifyCanChangeSourceQuantity(TestUser."User Security ID");

        // [THEN] The operation succeeds and CanChangeSourceQuantity returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeSourceQuantity(TestUser."User Security ID"), 'allowed with administrator role');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VerifyAdministratorCapabilitiesWithSuper()
    begin
        InitializePermissions(SuperRoleIDTok);

        QltyInspectionUtility.VerifyCanDeleteFinishedInspection(TestUser."User Security ID");
        QltyInspectionUtility.VerifyCanChangeOtherInspections(TestUser."User Security ID");
        QltyInspectionUtility.VerifyCanReopenInspection(TestUser."User Security ID");
        QltyInspectionUtility.VerifyCanChangeSourceQuantity(TestUser."User Security ID");

        LibraryAssert.IsTrue(QltyInspectionUtility.CanDeleteFinishedInspection(TestUser."User Security ID"), 'allowed with SUPER');
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeOtherInspections(TestUser."User Security ID"), 'allowed with SUPER');
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeSourceQuantity(TestUser."User Security ID"), 'allowed with SUPER');
    end;

    local procedure InitializePermissions(PermissionSetRoleID: Code[20])
    var
        UserPermissions: Codeunit "User Permissions";
        QltyPermissionTestFixture: Codeunit "Qlty. Permission Test Fixture";
    begin
        TestUser.Get(QltyPermissionTestFixture.GetUserSecurityId(PermissionSetRoleID));

        LibraryLowerPermissions.SetO365Basic();
        LibraryAssert.AreEqual(PermissionSetRoleID = SuperRoleIDTok, UserPermissions.IsSuper(TestUser."User Security ID"), 'Unexpected SUPER status for the test user.');
    end;

}
