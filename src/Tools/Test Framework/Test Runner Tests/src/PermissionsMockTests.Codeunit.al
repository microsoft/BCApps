// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 130487 "Permissions Mock Tests"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions Mock]
    end;

    var
        PermissionsMock: Codeunit "Permissions Mock";
        Assert: Codeunit "Library Assert";

    [Test]
    procedure ClearAssignmentsBeforeInitialization()
    begin
        // [SCENARIO] Test initialization can clear assignments without explicitly starting the mock.
        // [WHEN] Initialization clears assignments and sets execution-only permissions.
        PermissionsMock.ClearAssignments();

        PermissionsMock.SetExactPermissionSet('All Objects');
        // [THEN] Mocking is active and table-data access is denied.
        Assert.IsTrue(PermissionsMock.IsStarted(), 'The test handler must start permission mocking.');
        VerifyReadIsDenied();
    end;

    [Test]
    procedure RepeatedStartPreservesAssignments()
    var
        ALTestSuite: Record "AL Test Suite";
        TestMethodLine: Record "Test Method Line";
    begin
        // [SCENARIO] Explicit initialization does not discard permissions already assigned by the test.
        // [GIVEN] An assignment grants read access to one table but not another.
        PermissionsMock.SetExactPermissionSet('PM TEST RUNNER READ');
        Assert.IsTrue(ALTestSuite.ReadPermission(), 'The explicit assignment must grant read access.');
        Assert.IsFalse(TestMethodLine.ReadPermission(), 'The assignment must not grant unrelated table-data access.');

        // [WHEN] Mocking is started again.
        PermissionsMock.Start();

        // [THEN] Both the grant and the restriction remain in effect.
        Assert.IsTrue(ALTestSuite.ReadPermission(), 'Repeated Start must preserve the read assignment.');
        Assert.IsFalse(TestMethodLine.ReadPermission(), 'Repeated Start must preserve the permission restriction.');
    end;

    [Test]
    procedure StopAndStartClearAssignments()
    begin
        // [SCENARIO] Ending a mock scope discards its assignments before another scope starts.
        // [GIVEN] A mock scope grants table-data access.
        PermissionsMock.SetExactPermissionSet('PM TEST RUNNER READ');
        // [WHEN] The scope is stopped twice and restarted with execution-only permissions.
        PermissionsMock.Stop();
        PermissionsMock.Stop();
        PermissionsMock.Start();
        PermissionsMock.Assign('All Objects');

        // [THEN] The earlier table-data grant is gone.
        VerifyReadIsDenied();
    end;

    local procedure VerifyReadIsDenied()
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        Assert.IsFalse(ALTestSuite.ReadPermission(), 'Object execution rights must not grant table-data access.');
    end;
}
