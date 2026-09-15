codeunit 130215 "Not Isolated Test Runner"
{
    // This is the not isolated Test Runner for the Test Tool

    Subtype = TestRunner;
    TableNo = "Test Line";

    trigger OnRun()
    begin
        TestRunner.RunTestsOnLines(Rec);
    end;

    var
        TestRunner: Codeunit "Test Runner";

    trigger OnBeforeTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions): Boolean
    begin
        exit(TestRunner.HandleOnOnBeforeTestRun(CUId, CUName, FName, FTestPermissions));
    end;

    trigger OnAfterTestRun(CUId: Integer; CUName: Text; FName: Text; FTestPermissions: TestPermissions; Success: Boolean)
    begin
        TestRunner.HandleOnAfterTestRun(CUId, CUName, FName, FTestPermissions, Success)
    end;
}

