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
        UserDoesNotHavePermissionToErr: Label 'The user [%1] does not have permission to [%2]. This can be changed by navigating to Quality Management Permissions.', Comment = '%1=User id, %2=permission being attempted';
        ExpectedSupervisorRoleIDTok: Label 'QltyGeneral', Locked = true;

    [Test]
    procedure CanReadInspectionResults()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Verify that the CanReadInspectionResults function correctly checks read permissions for inspection results
        // [GIVEN] The Quality Inspection Header table exists
        // [WHEN] The CanReadInspectionResults function is called
        // [THEN] It returns true if read permission exists, false otherwise

        if QltyInspectionHeader.ReadPermission() then
            LibraryAssert.IsTrue(QltyInspectionUtility.CanReadInspectionResults(), 'Should return read permission = true')
        else
            LibraryAssert.IsFalse(QltyInspectionUtility.CanReadInspectionResults(), 'Should return read permission = false');
    end;

    [Test]
    procedure Express_VerifyCanCreateManualInspection_ShouldError()
    begin
        // [SCENARIO] Verify that creating a manual inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanCreateManualInspection is called
        // [THEN] An error is raised indicating the user lacks permission to create a manual inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanCreateManualInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Create Inspection Manual'));
        end;
    end;

    [Test]
    procedure Express_VerifyCanCreateManualInspection()
    begin
        // [SCENARIO] Verify that creating a manual inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] VerifyCanCreateManualInspection is called
        QltyInspectionUtility.VerifyCanCreateManualInspection();

        // [THEN] The operation succeeds and CanCreateManualInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanCreateManualInspection(), 'should be allowed with insert permission on order table data');
    end;

    [Test]
    procedure Express_VerifyCanCreateAutoInspection()
    begin
        // [SCENARIO] Verify that creating an auto inspection is allowed for all users
        // [GIVEN] No specific permission set is required

        // [WHEN] VerifyCanCreateAutoInspection is called
        QltyInspectionUtility.VerifyCanCreateAutoInspection();

        // [THEN] The operation succeeds and CanCreateAutoInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanCreateAutoInspection(), 'everyone is allowed.');
    end;

    [Test]
    procedure Express_VerifyCanCreateReinspection_ShouldError()
    begin
        // [SCENARIO] Verify that creating a re-inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanCreateReinspection is called
        // [THEN] An error is raised indicating the user lacks permission to create a re-inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanCreateReinspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Create Re-inspection'));
        end;
    end;

    [Test]
    procedure Express_VerifyCanCreateReinspection()
    begin
        // [SCENARIO] Verify that creating a re-inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] VerifyCanCreateReinspection is called
        QltyInspectionUtility.VerifyCanCreateReinspection();

        // [THEN] The operation succeeds and CanCreateReinspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanCreateReinspection(), 'should be allowed with insert permission on order table data');
    end;

    [Test]
    procedure Express_VerifyCanDeleteOpenInspection_ShouldError()
    begin
        // [SCENARIO] Verify that deleting an open inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanDeleteOpenInspection is called
        // [THEN] An error is raised indicating the user lacks permission to delete an open inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanDeleteOpenInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Delete Open Inspection'));
        end;
    end;

    [Test]
    procedure Express_VerifyCanDeleteOpenInspection()
    begin
        // [SCENARIO] Verify that deleting an open inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] VerifyCanDeleteOpenInspection is called
        QltyInspectionUtility.VerifyCanDeleteOpenInspection();

        // [THEN] The operation succeeds and CanDeleteOpenInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanDeleteOpenInspection(), 'allowed with supervisor role');
    end;

    [Test]
    procedure Express_VerifyCanDeleteFinishedInspection_ShouldError()
    begin
        // [SCENARIO] Verify that deleting a finished inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanDeleteFinishedInspection is called
        // [THEN] An error is raised indicating the user lacks permission to delete a finished inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanDeleteFinishedInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Delete Finished Inspection'));
        end;
    end;

    [Test]
    procedure Express_VerifyCanDeleteFinishedInspection()
    begin
        // [SCENARIO] Verify that deleting a finished inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] VerifyCanDeleteFinishedInspection is called        
        QltyInspectionUtility.VerifyCanDeleteFinishedInspection();

        // [THEN] The operation succeeds and CanDeleteFinishedInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanDeleteFinishedInspection(), 'allowed with supervisor role');
    end;

    [Test]
    procedure Express_VerifyCanChangeOtherInspections()
    begin
        // [SCENARIO] Verify that changing other users' inspections succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeOtherInspections is called
        QltyInspectionUtility.VerifyCanChangeOtherInspections();

        // [THEN] The operation succeeds and CanChangeOtherInspections returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeOtherInspections(), 'allowed with supervisor role');
    end;

    [Test]
    procedure Express_VerifyCanReopenInspection_ShouldError()
    begin
        // [SCENARIO] Verify that reopening an inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanReopenInspection is called
        // [THEN] An error is raised indicating the user lacks permission to reopen an inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanReopenInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Reopen Inspection'));
        end;
    end;

    [Test]
    procedure Express_VerifyCanReopenInspection()
    begin
        // [SCENARIO] Verify that reopening an inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] VerifyCanReopenInspection is called
        QltyInspectionUtility.VerifyCanReopenInspection();

        // [THEN] The operation succeeds and CanReopenInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanReopenInspection(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure Express_VerifyCanFinishInspection_ShouldError()
    begin
        // [SCENARIO] Verify that finishing an inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanFinishInspection is called
        // [THEN] An error is raised indicating the user lacks permission to finish an inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanFinishInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Finish Inspection'));
        end;
    end;

    [Test]
    procedure Express_VerifyCanFinishInspection()
    begin
        // [SCENARIO] Verify that finishing an inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] VerifyCanFinishInspection is called
        QltyInspectionUtility.VerifyCanFinishInspection();

        // [THEN] The operation succeeds and CanFinishInspection returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanFinishInspection(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure Express_VerifyCanChangeTrackingNo_ShouldError()
    begin
        // [SCENARIO] Verify that changing tracking number without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanChangeTrackingNo is called
        // [THEN] An error is raised indicating the user lacks permission to change tracking number

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanChangeTrackingNo();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Change Tracking No.'));
        end;
    end;

    [Test]
    procedure Express_VerifyCanChangeTrackingNo()
    begin
        // [SCENARIO] Verify that changing tracking number succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeTrackingNo is called
        QltyInspectionUtility.VerifyCanChangeTrackingNo();

        // [THEN] The operation succeeds and CanChangeTrackingNo returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeTrackingNo(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure Express_VerifyCanChangeSourceQuantity_ShouldError()
    begin
        // [SCENARIO] Verify that changing source quantity without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] VerifyCanChangeSourceQuantity is called
        // [THEN] An error is raised indicating the user lacks permission to change source quantity

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyInspectionUtility.VerifyCanChangeSourceQuantity();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Change Source Quantity'));
        end;
    end;

    [Test]
    procedure Express_VerifyCanChangeSourceQuantity()
    begin
        // [SCENARIO] Verify that changing source quantity succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] VerifyCanChangeSourceQuantity is called
        QltyInspectionUtility.VerifyCanChangeSourceQuantity();

        // [THEN] The operation succeeds and CanChangeSourceQuantity returns true
        LibraryAssert.IsTrue(QltyInspectionUtility.CanChangeSourceQuantity(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure Express_VerifyCanEditLineComments()
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
