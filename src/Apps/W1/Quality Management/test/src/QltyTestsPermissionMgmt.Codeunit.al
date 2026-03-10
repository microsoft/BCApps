// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.QualityManagement.Document;
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
        SupervisorRoleIDTok: Label 'QltyMngmnt - Edit', Locked = true;

    [Test]
    procedure VerifyCanCreateManualInspection_ShouldError()
    begin
        // [SCENARIO] Verify that creating a manual inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanCreateManualInspection is called
        // [THEN] An error is raised indicating the user lacks permission to create a manual inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanCreateManualInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'create inspection manually'));
        end;
    end;

    [Test]
    procedure VerifyCanCreateManualInspection()
    begin
        // [SCENARIO] Verify that creating a manual inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(SupervisorRoleIDTok);

        // [WHEN] VerifyCanCreateManualInspection is called
        QltyInspectionUtility.VerifyCanCreateManualInspection();

        // [THEN] No errors is raised
    end;

    [Test]
    procedure VerifyCanCreateReinspection_ShouldError()
    begin
        // [SCENARIO] Verify that creating a re-inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanCreateReinspection is called
        // [THEN] An error is raised indicating the user lacks permission to create a re-inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanCreateReinspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'create re-inspection'));
        end;
    end;

    [Test]
    procedure VerifyCanCreateReinspection()
    begin
        // [SCENARIO] Verify that creating a re-inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(SupervisorRoleIDTok);

        // [WHEN] VerifyCanCreateReinspection is called
        QltyInspectionUtility.VerifyCanCreateReinspection();

        // [THEN] No errors is raised
    end;

    [Test]
    procedure VerifyCanDeleteOpenInspection_ShouldError()
    begin
        // [SCENARIO] Verify that deleting an open inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanDeleteOpenInspection is called
        // [THEN] An error is raised indicating the user lacks permission to delete an open inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanDeleteOpenInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'delete open inspection'));
        end;
    end;

    [Test]
    procedure VerifyCanDeleteOpenInspection()
    begin
        // [SCENARIO] Verify that deleting an open inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(SupervisorRoleIDTok);

        // [WHEN] VerifyCanDeleteOpenInspection is called
        QltyInspectionUtility.VerifyCanDeleteOpenInspection();

        // [THEN] No errors is raised
    end;

    [Test]
    procedure VerifyCanDeleteFinishedInspection_ShouldError()
    begin
        // [SCENARIO] Verify that deleting a finished inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanDeleteFinishedInspection is called
        // [THEN] An error is raised indicating the user lacks permission to delete a finished inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanDeleteFinishedInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'delete finished inspection'));
        end;
    end;

    [Test]
    procedure VerifyCanDeleteFinishedInspection()
    begin
        // [SCENARIO] Verify that deleting a finished inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(SupervisorRoleIDTok);

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
        LibraryLowerPermissions.AddPermissionSet(SupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeOtherInspections is called
        QltyInspectionUtility.VerifyCanChangeOtherInspections();

        // [THEN] The operation succeeds and CanChangeOtherInspections returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeOtherInspections(), 'allowed with supervisor role');
    end;

    [Test]
    procedure VerifyCanReopenInspection_ShouldError()
    begin
        // [SCENARIO] Verify that reopening an inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanReopenInspection is called
        // [THEN] An error is raised indicating the user lacks permission to reopen an inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanReopenInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'reopen inspection'));
        end;
    end;

    [Test]
    procedure VerifyCanReopenInspection()
    begin
        // [SCENARIO] Verify that reopening an inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(SupervisorRoleIDTok);

        // [WHEN] VerifyCanReopenInspection is called
        QltyInspectionUtility.VerifyCanReopenInspection();

        // [THEN] No errors is raised
    end;

    [Test]
    procedure VerifyCanFinishInspection_ShouldError()
    begin
        // [SCENARIO] Verify that finishing an inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanFinishInspection is called
        // [THEN] An error is raised indicating the user lacks permission to finish an inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanFinishInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'finish inspection'));
        end;
    end;

    [Test]
    procedure VerifyCanFinishInspection()
    begin
        // [SCENARIO] Verify that finishing an inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(SupervisorRoleIDTok);

        // [WHEN] VerifyCanFinishInspection is called
        QltyInspectionUtility.VerifyCanFinishInspection();

        // [THEN] The operation succeeds and CanFinishInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanFinishInspection(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure VerifyCanChangeItemTracking_ShouldError()
    begin
        // [SCENARIO] Verify that changing item tracking without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanChangeItemTracking is called
        // [THEN] An error is raised indicating the user lacks permission to change item tracking

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanChangeItemTracking();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'change item tracking'));
        end;
    end;

    [Test]
    procedure VerifyCanChangeItemTracking()
    begin
        // [SCENARIO] Verify that changing item tracking succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(SupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeItemTracking is called
        QltyInspectionUtility.VerifyCanChangeItemTracking();

        // [THEN] The operation succeeds and CanChangeItemTracking returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeItemTracking(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure VerifyCanChangeSourceQuantity_ShouldError()
    begin
        // [SCENARIO] Verify that changing source quantity without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanChangeSourceQuantity is called
        // [THEN] An error is raised indicating the user lacks permission to change source quantity

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanChangeSourceQuantity();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'change source quantity'));
        end;
    end;

    [Test]
    procedure VerifyCanChangeSourceQuantity()
    begin
        // [SCENARIO] Verify that changing source quantity succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(SupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeSourceQuantity is called
        QltyInspectionUtility.VerifyCanChangeSourceQuantity();

        // [THEN] The operation succeeds and CanChangeSourceQuantity returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeSourceQuantity(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure VerifyCanEditLineComments()
    begin
        // [SCENARIO] Verify that editing line comments is allowed for users with record link modification permissions
        // [GIVEN] The user has permission to modify record links
        // [WHEN] CanEditLineComments is called
        // [THEN] The function returns true

        LibraryAssert.IsTrue(QltyInspectionUtility.CanEditLineComments(), 'everyone with permission to modify record links is allowed');
    end;

    local procedure CheckQltyInspectionHeaderWritePermission(): Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        exit(QltyInspectionHeader.WritePermission());
    end;
}
