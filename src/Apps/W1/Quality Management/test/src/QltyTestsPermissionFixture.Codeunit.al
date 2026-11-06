// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using System.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 139978 "Qlty. Tests - Perm. Fixture"
{
    Subtype = Test;
    // These lifecycle tests perform the user administration normally done outside test permissions.
    TestPermissions = Disabled;
    TestType = UnitTest;
    TestHandlers = "Qlty. Fixture Cleanup";

    var
        QltyPermissionTestFixture: Codeunit "Qlty. Permission Test Fixture";
        QltyFixtureTestHandler: Codeunit "Qlty. Fixture Test Handler";
        LibraryAssert: Codeunit "Library Assert";
        Context: TestHandlerContext;

    [Test]
    procedure CleanupAfterPartialPreparation()
    var
        InspectorSecurityId: Guid;
        AdminSecurityId: Guid;
    begin
        QltyFixtureTestHandler.FailOnRole('QltyMgmt - Admin');
        BindSubscription(QltyFixtureTestHandler);
        asserterror QltyPermissionTestFixture.OnBeforeTestCodeunitRun(Context);
        LibraryAssert.ExpectedError('Quality fixture assignment failure.');
        UnbindSubscription(QltyFixtureTestHandler);
        InspectorSecurityId := QltyPermissionTestFixture.GetUserSecurityId('QltyMgmt - Inspector');
        AdminSecurityId := QltyPermissionTestFixture.GetUserSecurityId('QltyMgmt - Admin');

        QltyPermissionTestFixture.OnAfterTestCodeunitRun(Context);
        VerifyUserRemoved(InspectorSecurityId);
        VerifyUserRemoved(AdminSecurityId);
        VerifyFixtureCleared();
    end;

    [Test]
    procedure RetryAfterFinalPermissionAssignmentFails()
    var
        FailedSuperSecurityId: Guid;
        SuperSecurityId: Guid;
        AccessControl: Record "Access Control";
    begin
        QltyFixtureTestHandler.FailOnRole('SUPER');
        BindSubscription(QltyFixtureTestHandler);
        asserterror QltyPermissionTestFixture.OnBeforeTestCodeunitRun(Context);
        LibraryAssert.ExpectedError('Quality fixture assignment failure.');
        UnbindSubscription(QltyFixtureTestHandler);
        FailedSuperSecurityId := QltyPermissionTestFixture.GetUserSecurityId('SUPER');

        QltyPermissionTestFixture.OnBeforeTestCodeunitRun(Context);
        SuperSecurityId := QltyPermissionTestFixture.GetUserSecurityId('SUPER');
        LibraryAssert.AreNotEqual(FailedSuperSecurityId, SuperSecurityId, 'A partial three-user dictionary must not be treated as prepared.');
        AccessControl.SetRange("User Security ID", SuperSecurityId);
        AccessControl.SetRange("Role ID", 'SUPER');
        LibraryAssert.IsFalse(AccessControl.IsEmpty(), 'The retried SUPER assignment must complete.');
        VerifyUserRemoved(FailedSuperSecurityId);
        QltyPermissionTestFixture.OnAfterTestCodeunitRun(Context);
        VerifyFixtureCleared();
    end;

    [Test]
    procedure CleanupToleratesMissingUser()
    var
        FixtureUser: Record User;
        AccessControl: Record "Access Control";
        AdminSecurityId: Guid;
    begin
        QltyPermissionTestFixture.OnBeforeTestCodeunitRun(Context);
        AdminSecurityId := QltyPermissionTestFixture.GetUserSecurityId('QltyMgmt - Admin');
        AccessControl.SetRange("User Security ID", AdminSecurityId);
        AccessControl.DeleteAll(true);
        FixtureUser.Get(AdminSecurityId);
        FixtureUser.Delete(true);

        QltyPermissionTestFixture.OnAfterTestCodeunitRun(Context);
        VerifyUserRemoved(AdminSecurityId);
        VerifyFixtureCleared();
    end;

    [Test]
    procedure CleanupIsIdempotentWithoutPreparation()
    begin
        QltyPermissionTestFixture.OnAfterTestCodeunitRun(Context);
        QltyPermissionTestFixture.OnAfterTestCodeunitRun(Context);
        VerifyFixtureCleared();
    end;

    local procedure VerifyUserRemoved(TestUserSecurityId: Guid)
    var
        FixtureUser: Record User;
        AccessControl: Record "Access Control";
    begin
        LibraryAssert.IsFalse(FixtureUser.Get(TestUserSecurityId), 'Cleanup must remove the tracked fixture user.');
        AccessControl.SetRange("User Security ID", TestUserSecurityId);
        LibraryAssert.IsTrue(AccessControl.IsEmpty(), 'Cleanup must remove the tracked permission assignments.');
    end;

    local procedure VerifyFixtureCleared()
    begin
        asserterror QltyPermissionTestFixture.GetUserSecurityId('QltyMgmt - Inspector');
        LibraryAssert.ExpectedError('The given key was not present in the dictionary.');
        asserterror QltyPermissionTestFixture.GetUserSecurityId('QltyMgmt - Admin');
        LibraryAssert.ExpectedError('The given key was not present in the dictionary.');
        asserterror QltyPermissionTestFixture.GetUserSecurityId('SUPER');
        LibraryAssert.ExpectedError('The given key was not present in the dictionary.');
    end;
}
