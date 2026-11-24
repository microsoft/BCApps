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

    [Test]
    procedure UnusedRunScopePreservesPermissions()
    var
        ALTestSuite: Record "AL Test Suite";
        TestMethodLine: Record "Test Method Line";
        PermissionTestHelper: DotNet PermissionTestHelper;
        StartedAfterRun: Boolean;
        StoppedAfterRun: Boolean;
        GrantAfterStart: Boolean;
        RestrictedAfterStart: Boolean;
        GrantAfterStop: Boolean;
        RestrictedAfterStop: Boolean;
    begin
        // [SCENARIO] The legacy Codeunit.Run toggle does not reset permissions when the mock is unused.
        // [GIVEN] Permissions were restricted independently of Permissions Mock.
        PermissionsMock.Stop();
        PermissionTestHelper := PermissionTestHelper.PermissionTestHelper();
        PermissionTestHelper.AddEffectivePermissionSet('PM TEST RUNNER READ');

        // [WHEN] An unused scope is started and stopped through Codeunit.Run.
        Codeunit.Run(Codeunit::"Permissions Mock");
        StartedAfterRun := PermissionsMock.IsStarted();
        GrantAfterStart := ALTestSuite.ReadPermission();
        RestrictedAfterStart := not TestMethodLine.ReadPermission();
        Codeunit.Run(Codeunit::"Permissions Mock");
        StoppedAfterRun := not PermissionsMock.IsStarted();
        GrantAfterStop := ALTestSuite.ReadPermission();
        RestrictedAfterStop := not TestMethodLine.ReadPermission();
        PermissionTestHelper.Dispose();
        PermissionsMock.Start();

        // [THEN] Neither construction nor disposal of an unused helper clears the independent permissions.
        Assert.IsTrue(StartedAfterRun and StoppedAfterRun, 'Codeunit.Run must toggle the mock scope.');
        Assert.IsTrue(GrantAfterStart and RestrictedAfterStart, 'Starting an unused scope must preserve independent permissions.');
        Assert.IsTrue(GrantAfterStop and RestrictedAfterStop, 'Stopping an unused scope must preserve independent permissions.');
    end;

    [Test]
    procedure SetInitializesPermissions()
    var
        ALTestSuite: Record "AL Test Suite";
        TestMethodLine: Record "Test Method Line";
    begin
        // [SCENARIO] Set initializes the helper without requiring an earlier ClearAssignments call.
        // [GIVEN] A fresh permission-mocking scope.
        PermissionsMock.Stop();
        PermissionsMock.Start();

        // [WHEN] The first permission operation assigns table read access.
        PermissionsMock.Set('PM TEST RUNNER READ');

        // [THEN] The explicit grant and unrelated restriction both take effect.
        Assert.IsTrue(ALTestSuite.ReadPermission(), 'Set must initialize the helper and grant the requested read access.');
        Assert.IsFalse(TestMethodLine.ReadPermission(), 'Set must enforce the permission restriction.');
    end;
}
