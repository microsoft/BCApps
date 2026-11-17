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

    var
        PermissionsMock: Codeunit "Permissions Mock";
        Assert: Codeunit "Library Assert";

    [Test]
    procedure ClearAssignmentsBeforeInitialization()
    begin
        // [SCENARIO] Test initialization can clear assignments without explicitly starting the mock.
        PermissionsMock.ClearAssignments();

        PermissionsMock.SetExactPermissionSet('All Objects');
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
        PermissionsMock.SetExactPermissionSet('PM TEST RUNNER READ');
        Assert.IsTrue(ALTestSuite.ReadPermission(), 'The explicit assignment must grant read access.');
        Assert.IsFalse(TestMethodLine.ReadPermission(), 'The assignment must not grant unrelated table-data access.');

        PermissionsMock.Start();

        Assert.IsTrue(ALTestSuite.ReadPermission(), 'Repeated Start must preserve the read assignment.');
        Assert.IsFalse(TestMethodLine.ReadPermission(), 'Repeated Start must preserve the permission restriction.');
    end;

    [Test]
    procedure StopAndStartClearAssignments()
    begin
        // [SCENARIO] Ending a mock scope discards its assignments before another scope starts.
        PermissionsMock.SetExactPermissionSet('PM TEST RUNNER READ');
        PermissionsMock.Stop();
        PermissionsMock.Stop();
        PermissionsMock.Start();
        PermissionsMock.Assign('All Objects');

        VerifyReadIsDenied();
    end;

    local procedure VerifyReadIsDenied()
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        Assert.IsFalse(ALTestSuite.ReadPermission(), 'Object execution rights must not grant table-data access.');
    end;
}
