// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Test.QualityManagement.TestLibraries;
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
    procedure VerifyCanDeleteFinishedInspection_ShouldError()
    begin
        // [SCENARIO] Verify that deleting a finished inspection without the administrator role raises an error
        // [GIVEN] The inspector role permission set is added
        LibraryLowerPermissions.AddPermissionSet(InspectorRoleIDTok);

        // [WHEN] VerifyCanDeleteFinishedInspection is called
        // [THEN] An error is raised indicating the user lacks permission to delete a finished inspection
        asserterror QltyInspectionUtility.VerifyCanDeleteFinishedInspection();
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'delete finished inspection'));
    end;

    [Test]
    procedure VerifyCanDeleteFinishedInspection()
    begin
        // [SCENARIO] Verify that deleting a finished inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanDeleteFinishedInspection is called        
        QltyInspectionUtility.VerifyCanDeleteFinishedInspection();

        // [THEN] The operation succeeds and CanDeleteFinishedInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanDeleteFinishedInspection(), 'allowed with supervisor role');
    end;

    [Test]
    procedure VerifyCanChangeOtherInspections()
    begin
        // [SCENARIO] Verify that changing other users' inspections succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeOtherInspections is called
        QltyInspectionUtility.VerifyCanChangeOtherInspections();

        // [THEN] The operation succeeds and CanChangeOtherInspections returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeOtherInspections(), 'allowed with supervisor role');
    end;

    [Test]
    procedure VerifyCanChangeOtherInspections_ShouldError()
    begin
        // [SCENARIO] Verify that changing another user's inspection without the administrator role raises an error
        // [GIVEN] The inspector role permission set is added
        LibraryLowerPermissions.AddPermissionSet(InspectorRoleIDTok);

        // [WHEN] VerifyCanChangeOtherInspections is called
        // [THEN] An error is raised indicating the user lacks permission to change other inspections
        asserterror QltyInspectionUtility.VerifyCanChangeOtherInspections();
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'change others inspection'));
        LibraryAssert.IsFalse(QltyInspectionUtility.CanChangeOtherInspections(), 'not allowed without administrator role');
    end;

    [Test]
    procedure VerifyCanReopenInspection_ShouldError()
    begin
        // [SCENARIO] Verify that reopening an inspection without the administrator role raises an error
        // [GIVEN] The inspector role permission set is added
        LibraryLowerPermissions.AddPermissionSet(InspectorRoleIDTok);

        // [WHEN] VerifyCanReopenInspection is called
        // [THEN] An error is raised indicating the user lacks permission to reopen an inspection
        asserterror QltyInspectionUtility.VerifyCanReopenInspection();
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'reopen inspection'));
    end;

    [Test]
    procedure VerifyCanReopenInspection()
    begin
        // [SCENARIO] Verify that reopening an inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanReopenInspection is called
        QltyInspectionUtility.VerifyCanReopenInspection();

        // [THEN] No errors is raised
    end;

    [Test]
    procedure VerifyCanChangeSourceQuantity_ShouldError()
    begin
        // [SCENARIO] Verify that changing source quantity without the administrator role raises an error
        // [GIVEN] The inspector role permission set is added
        LibraryLowerPermissions.AddPermissionSet(InspectorRoleIDTok);

        // [WHEN] VerifyCanChangeSourceQuantity is called
        // [THEN] An error is raised indicating the user lacks permission to change source quantity
        asserterror QltyInspectionUtility.VerifyCanChangeSourceQuantity();
        LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'change source quantity'));
        LibraryAssert.IsFalse(QltyInspectionUtility.CanChangeSourceQuantity(), 'not allowed without administrator role');
    end;

    [Test]
    procedure VerifyCanChangeSourceQuantity()
    begin
        // [SCENARIO] Verify that changing source quantity succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(AdminSupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeSourceQuantity is called
        QltyInspectionUtility.VerifyCanChangeSourceQuantity();

        // [THEN] The operation succeeds and CanChangeSourceQuantity returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeSourceQuantity(), 'allowed with administrator role');
    end;

}
