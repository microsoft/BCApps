codeunit 130201 "CLI Test Runner"
{
    // This is the test runner used from the command-line.

    Subtype = TestRunner;
    TestIsolation = Codeunit;

    trigger OnRun()
    begin
        SnapTestRunner.RunTests(false, false)
    end;

    var
        SnapTestRunner: Codeunit "Snap Test Runner";

    trigger OnBeforeTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions): Boolean
    begin
        exit(SnapTestRunner.OnBeforeTestRunImpl(CUId, CUName, FName, FTestPermissions))
    end;

    trigger OnAfterTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions; Success: Boolean)
    begin
        SnapTestRunner.OnAfterTestRunImpl(CUId, CUName, FName, FTestPermissions, Success)
    end;
}

