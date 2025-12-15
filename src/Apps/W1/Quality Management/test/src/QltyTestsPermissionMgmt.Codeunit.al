// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Document;
using System.TestLibraries.Utilities;

codeunit 139957 "Qlty. Tests - Permission Mgmt."
{
    Subtype = Test;
    TestPermissions = Restrictive;
    TestType = UnitTest;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        LibraryAssert: Codeunit "Library Assert";
        UserDoesNotHavePermissionToErr: Label 'The user [%1] does not have permission to [%2]. This can be changed by navigating to Quality Management Permissions.', Comment = '%1=User id, %2=permission being attempted';
        ExpectedSupervisorRoleIDTok: Label 'QltyGeneral', Locked = true;

    [Test]
    procedure CanReadTestResults()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Verify that the CanReadTestResults function correctly checks read permissions for test results
        // [GIVEN] The Quality Inspection Header table exists
        // [WHEN] The CanReadTestResults function is called
        // [THEN] It returns true if read permission exists, false otherwise

        if QltyInspectionHeader.ReadPermission() then
            LibraryAssert.IsTrue(QltyPermissionMgmt.CanReadInspectionResults(), 'Should return read permission = true')
        else
            LibraryAssert.IsFalse(QltyPermissionMgmt.CanReadInspectionResults(), 'Should return read permission = false');
    end;

    [Test]
    procedure Express_TestCanCreateManualInspection_ShouldError()
    begin
        // [SCENARIO] Verify that creating a manual test without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] TestCanCreateManualInspection is called
        // [THEN] An error is raised indicating the user lacks permission to create a manual test

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyPermissionMgmt.TestCanCreateManualInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Create Inspection Manual'));
        end;
    end;

    [Test]
    procedure Express_TestCanCreateManualInspection()
    begin
        // [SCENARIO] Verify that creating a manual test succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] TestCanCreateManualInspection is called
        QltyPermissionMgmt.TestCanCreateManualInspection();

        // [THEN] The operation succeeds and CanCreateManualInspection returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanCreateManualInspection(), 'should be allowed with insert permission on order table data');
    end;

    [Test]
    procedure Express_TestCanCreateAutoInspection()
    begin
        // [SCENARIO] Verify that creating an auto test is allowed for all users
        // [GIVEN] No specific permission set is required

        // [WHEN] TestCanCreateAutoInspection is called
        QltyPermissionMgmt.TestCanCreateAutoTest();

        // [THEN] The operation succeeds and CanCreateAutoInspection returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanCreateAutoInspection(), 'everyone is allowed.');
    end;

    [Test]
    procedure Express_TestCanCreateReinspection_ShouldError()
    begin
        // [SCENARIO] Verify that creating a reinspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] TestCanCreateReinspection is called
        // [THEN] An error is raised indicating the user lacks permission to create a reinspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyPermissionMgmt.TestCanCreateReinspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Create Reinspection'));
        end;
    end;

    [Test]
    procedure Express_TestCanCreateReinspection()
    begin
        // [SCENARIO] Verify that creating a reinspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] TestCanCreateReinspection is called
        QltyPermissionMgmt.TestCanCreateReinspection();

        // [THEN] The operation succeeds and CanCreateReinspection returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanCreateReinspection(), 'should be allowed with insert permission on order table data');
    end;

    [Test]
    procedure Express_TestCanDeleteOpenTest_ShouldError()
    begin
        // [SCENARIO] Verify that deleting an open inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] TestCanDeleteOpenTest is called
        // [THEN] An error is raised indicating the user lacks permission to delete an open inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyPermissionMgmt.TestCanDeleteOpenTest();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Delete Open Test'));
        end;
    end;

    [Test]
    procedure Express_TestCanDeleteOpenTest()
    begin
        // [SCENARIO] Verify that deleting an open inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] TestCanDeleteOpenTest is called
        QltyPermissionMgmt.TestCanDeleteOpenTest();

        // [THEN] The operation succeeds and CanDeleteOpenTest returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanDeleteOpenTest(), 'allowed with supervisor role');
    end;

    [Test]
    procedure Express_TestCanDeleteFinishedInspection_ShouldError()
    begin
        // [SCENARIO] Verify that deleting a finished test without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] TestCanDeleteFinishedInspection is called
        // [THEN] An error is raised indicating the user lacks permission to delete a finished test

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyPermissionMgmt.TestCanDeleteFinishedInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Delete Finished Test'));
        end;
    end;

    [Test]
    procedure Express_TestCanDeleteFinishedInspection()
    begin
        // [SCENARIO] Verify that deleting a finished test succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] TestCanDeleteFinishedInspection is called        
        QltyPermissionMgmt.TestCanDeleteFinishedInspection();

        // [THEN] The operation succeeds and CanDeleteFinishedTest returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanDeleteFinishedTest(), 'allowed with supervisor role');
    end;

    [Test]
    procedure Express_TestCanChangeOthersTests()
    begin
        // [SCENARIO] Verify that changing other users' tests succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] TestCanChangeOthersTests is called
        QltyPermissionMgmt.TestCanChangeOthersTests();

        // [THEN] The operation succeeds and CanChangeOthersTests returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanChangeOthersTests(), 'allowed with supervisor role');
    end;

    [Test]
    procedure Express_TestCanReopenTest_ShouldError()
    begin
        // [SCENARIO] Verify that reopening an inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] TestCanReopenTest is called
        // [THEN] An error is raised indicating the user lacks permission to reopen an inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyPermissionMgmt.TestCanReopenTest();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Reopen Test'));
        end;
    end;

    [Test]
    procedure Express_TestCanReopenTest()
    begin
        // [SCENARIO] Verify that reopening an inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] TestCanReopenTest is called
        QltyPermissionMgmt.TestCanReopenTest();

        // [THEN] The operation succeeds and CanReopenTest returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanReopenTest(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure Express_TestCanFinishTest_ShouldError()
    begin
        // [SCENARIO] Verify that finishing an inspection without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] TestCanFinishTest is called
        // [THEN] An error is raised indicating the user lacks permission to finish an inspection

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyPermissionMgmt.TestCanFinishInspection();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Finish Test'));
        end;
    end;

    [Test]
    procedure Express_TestCanFinishTest()
    begin
        // [SCENARIO] Verify that finishing an inspection succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] TestCanFinishTest is called
        QltyPermissionMgmt.TestCanFinishInspection();

        // [THEN] The operation succeeds and CanFinishTest returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanFinishTest(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure Express_TestCanChangeTrackingNo_ShouldError()
    begin
        // [SCENARIO] Verify that changing tracking number without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] TestCanChangeTrackingNo is called
        // [THEN] An error is raised indicating the user lacks permission to change tracking number

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyPermissionMgmt.TestCanChangeTrackingNo();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Change Tracking No.'));
        end;
    end;

    [Test]
    procedure Express_TestCanChangeTrackingNo()
    begin
        // [SCENARIO] Verify that changing tracking number succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] TestCanChangeTrackingNo is called
        QltyPermissionMgmt.TestCanChangeTrackingNo();

        // [THEN] The operation succeeds and CanChangeTrackingNo returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanChangeTrackingNo(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure Express_TestCanChangeSourceQuantity_ShouldError()
    begin
        // [SCENARIO] Verify that changing source quantity without proper permissions raises an error
        // [GIVEN] The user does not have write permission on Quality Inspection Header
        // [WHEN] TestCanChangeSourceQuantity is called
        // [THEN] An error is raised indicating the user lacks permission to change source quantity

        if not CheckQltyInspectionHeaderWritePermission() then begin
            asserterror QltyPermissionMgmt.TestCanChangeSourceQuantity();
            LibraryAssert.ExpectedError(StrSubstNo(UserDoesNotHavePermissionToErr, UserId(), 'Change Source Quantity'));
        end;
    end;

    [Test]
    procedure Express_TestCanChangeSourceQuantity()
    begin
        // [SCENARIO] Verify that changing source quantity succeeds with proper supervisor permissions

        // [GIVEN] The supervisor role permission set is added
        LibraryLowerPermissions.AddPermissionSet(ExpectedSupervisorRoleIDTok);

        // [WHEN] TestCanChangeSourceQuantity is called
        QltyPermissionMgmt.TestCanChangeSourceQuantity();

        // [THEN] The operation succeeds and CanChangeSourceQuantity returns true
        LibraryAssert.IsTrue(QltyPermissionMgmt.CanChangeSourceQuantity(), 'should be allowed with modify permission on order table data');
    end;

    [Test]
    procedure Express_TestCanEditLineComments()
    begin
        // [SCENARIO] Verify that editing line comments is allowed for users with record link modification permissions
        // [GIVEN] The user has permission to modify record links
        // [WHEN] CanEditLineComments is called
        // [THEN] The function returns true

        LibraryAssert.IsTrue(QltyPermissionMgmt.CanEditLineComments(), 'everyone with permission to modify record links is allowed');
    end;

    local procedure CheckQltyInspectionHeaderWritePermission(): Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        exit(QltyInspectionHeader.WritePermission());
    end;
}
