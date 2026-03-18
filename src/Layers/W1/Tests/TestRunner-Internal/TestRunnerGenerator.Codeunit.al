codeunit 130205 "Test Runner Generator"
{
    Subtype = TestRunner;

    trigger OnRun()
    var
        EnabledTestCodeunit: Record "Enabled Test Codeunit";
        AllObj: Record AllObj;
    begin
        // Clear the neabled test methods table
        Clear(EnabledTestMethod);
        EnabledTestMethod.DeleteAll();

        if EnabledTestCodeunit.FindSet() then
            repeat
                // run enabled test codeunit - to populate the enabled test methods table
                if AllObj.Get(AllObj."Object Type"::Codeunit, EnabledTestCodeunit."Test Codeunit ID") then
                    CODEUNIT.Run(EnabledTestCodeunit."Test Codeunit ID");
            until EnabledTestCodeunit.Next() = 0
    end;

    var
        EnabledTestMethod: Record "Enabled Test Method";

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        if (FunctionName = 'OnRun') or (FunctionName = '') then
            exit(true);

        EnabledTestMethod.InsertEntry(CodeunitID, FunctionName);

        exit(false);
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; Success: Boolean)
    begin
    end;
}

