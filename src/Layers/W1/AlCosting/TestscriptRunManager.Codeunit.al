codeunit 103004 "Testscript Run Manager"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution
    // DK: Skipped for Execution
    // GB: Skipped for Execution
    // FR: Skipped for Execution
    // NL: Skipped for Execution
    // IT: Skipped for Execution
    // AU: Skipped for Execution
    // IN: Skipped for Execution
    // NZ: Skipped for Execution
    // US: Skipped for Execution
    // CA: Skipped for Execution
    // MX: Skipped for Execution


    trigger OnRun()
    begin
    end;

    var
        TestResultRec: Record "Testscript Result";
        CONST_WHITE: Label 'WHITE';
        CONST_SILVER: Label 'SILVER';
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";

    [Scope('OnPrem')]
    procedure ClearTestResultTable()
    begin
        TestResultRec.Reset();
        TestResultRec.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SetGlobalPreconditions()
    var
        Corsica_Resiliency: Codeunit Corsica_Resiliency;
        Corsica_TracingCost_VE_GL: Codeunit Corsica_TracingCost_VE_GL;
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();
        WMSTestscriptManagement.SetGlobalPreconditions();
        Corsica_Resiliency.SetTestResultsPath(CostingTestScriptMgmt.GetTestResultsPath());
        Corsica_TracingCost_VE_GL.SetTestResultsPath(CostingTestScriptMgmt.GetTestResultsPath());
    end;

    [Scope('OnPrem')]
    procedure PrepareCETAF()
    begin
        // Create iterations and TCs
        CODEUNIT.Run(CODEUNIT::TestSetupManagement);

        // Set the whse employees
        SetupWhseEmployee(CONST_WHITE, true);
        SetupWhseEmployee(CONST_SILVER, false);

        // Run global preconditions
        SetGlobalPreconditions();
    end;

    [Scope('OnPrem')]
    procedure PrepareWMSBW()
    begin
        // Create iterations and TCs
        CODEUNIT.Run(CODEUNIT::"WMS TestSetupManagement");

        // Set the whse employees
        SetupWhseEmployee(CONST_WHITE, true);
        SetupWhseEmployee(CONST_SILVER, false);
    end;

    [Scope('OnPrem')]
    procedure PrepareOldSuites("CodeUnit": Integer)
    var
        TestscriptMgt: Codeunit TestscriptManagement;
    begin
        // Set the whse employees
        SetupWhseEmployee(CONST_WHITE, true);
        SetupWhseEmployee(CONST_SILVER, false);

        //Set global preconditions
        TestscriptMgt.InitializeOutput(CodeUnit);
        WMSTestscriptManagement.SetGlobalPreconditions();
    end;

    local procedure SetupWhseEmployee(LocationCode: Text[30]; Default: Boolean)
    var
        WhseEmpRec: Record "Warehouse Employee";
    begin
        if not WhseEmpRec.Get(UserId, LocationCode) then begin
            WhseEmpRec.Validate("User ID", UserId);
            WhseEmpRec.Validate("Location Code", LocationCode);
            WhseEmpRec.Validate(Default, Default);
            WhseEmpRec.Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateRun(CodeUnitName: Text[30]; TestMethodName: Text[30])
    begin
        TestResultRec.SetRange(TestResultRec."Is Equal", false);
        if TestResultRec.FindFirst() then
            Error('Test case: "%1" in codeunit: "%2" failed during execution. %3 mismatches found.',
                              TestMethodName, CodeUnitName, TestResultRec.Count);
    end;

    [Scope('OnPrem')]
    procedure ValidateWMSBWRun(TestCaseRef: Record "Whse. Test Case")
    begin
        TestResultRec.SetRange(TestResultRec."Is Equal", false);
        if TestResultRec.FindFirst() then
            Error('Test case: "%1" in Project code: "%2", Use case: %3, Test Case: %4 failed during execution. ' +
                              '%5 mismatches found.',
                              TestCaseRef.Description, TestCaseRef."Project Code", TestCaseRef."Use Case No.",
                              TestCaseRef."Test Case No.", TestResultRec.Count);
    end;

    [Scope('OnPrem')]
    procedure ValidateCETAFRun(TestCaseRef: Record "Test Case")
    begin
        TestResultRec.SetRange(TestResultRec."Is Equal", false);
        if TestResultRec.FindFirst() then
            Error('Test case: "%1" in Project code: "%2", Use case: %3, Test Case: %4 failed during execution. ' +
                              '%5 mismatches found.',
                              TestCaseRef.Description, TestCaseRef."Project Code", TestCaseRef."Use Case No.",
                              TestCaseRef."Test Case No.", TestResultRec.Count);
    end;
}

