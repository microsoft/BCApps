codeunit 103003 "TestscriptManagement for Build"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution
    // 
    // OnRun is used to run as previously in Visual tests framework or manually
    // 
    // RunCodeunits - used to run as part of the CAL framework. It will be called from CAL test methods, either for a group of suites
    // (filter) or for as single one


    trigger OnRun()
    var
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
        TestResultsPath: Text[250];
    begin
        TestResultsPath := CostingTestScriptMgmt.GetTestResultsPath();

        TestscriptMgt.SetPathToWrite(TestResultsPath + 'CostingTestOutput.txt');
        TestscriptMgt.Run();
        TestscriptMgt.WriteTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;

    [Scope('OnPrem')]
    procedure RunCodeunits(CodeunitIDFilter: Text[250])
    var
        TestResultsPath: Text[250];
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
    begin
        TestResultsPath := CostingTestScriptMgmt.GetTestResultsPath();

        TestscriptMgt.SetPathToWrite(TestResultsPath + 'CostingTestOutput.txt');
        TestscriptMgt.RunCodeunits(CodeunitIDFilter, false);
        TestscriptMgt.WriteTestscriptResult();
    end;
}

