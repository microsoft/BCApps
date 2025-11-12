codeunit 103509 "Test - Warehousing"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        TestscriptMgt.InitializeOutput(103509);

        WMSTestSetupMgt.CreateUseCases();
        WMSTestSetupMgt.CreateTestCases();
        WMSTestSetupMgt.CreateIterations(WMSTestCase, true, false);

        BWTestSetupMgt.CreateUseCases();
        BWTestSetupMgt.CreateTestCases();
        BWTestSetupMgt.CreateIterations(WMSTestCase, true, false);

        WhseTestscript.CallTestScriptWMS(103310, 2, true);
        WhseTestscript.CallTestScriptWMS(103310, 3, true);
        WhseTestscript.CallTestScriptWMS(103310, 4, true);
        WhseTestscript.CallTestScriptWMS(103310, 5, true);
        WhseTestscript.CallTestScriptWMS(103310, 6, true);
        WhseTestscript.CallTestScriptWMS(103310, 7, true);
        WhseTestscript.CallTestScriptWMS(103310, 8, true);
        WhseTestscript.CallTestScriptWMS(103310, 9, true);
        WhseTestscript.CallTestScriptWMS(103310, 10, true);
        WhseTestscript.CallTestScriptWMS(103310, 11, true);
        WhseTestscript.CallTestScriptWMS(103310, 15, true);
        WhseTestscript.CallTestScriptWMS(103310, 16, true);
        WhseTestscript.CallTestScriptWMS(103310, 17, true);
        WhseTestscript.CallTestScriptWMS(103310, 18, true);
        WhseTestscript.CallTestScriptWMS(103310, 19, true);
        WhseTestscript.CallTestScriptWMS(103310, 20, true);
        WhseTestscript.CallTestScriptWMS(103310, 21, true);
        WhseTestscript.CallTestScriptWMS(103310, 22, true);
        WhseTestscript.CallTestScriptWMS(103310, 23, true);
        // Bug 37027 - only 25
        // WhseTestscript.CallTestScriptWMS(103310,25,TRUE);
        // WhseTestscript.CallTestScriptWMS(103310,26,TRUE);
        WhseTestscript.CallTestScriptWMS(103310, 27, true);
        // Bug 37027
        // WhseTestscript.CallTestScriptWMS(103310,28,TRUE);
        WhseTestscript.CallTestScriptBW(103350, 1, true);
        WhseTestscript.CallTestScriptBW(103350, 2, true);
        WhseTestscript.CallTestScriptBW(103350, 3, true);
        WhseTestscript.CallTestScriptBW(103350, 5, true);
        WhseTestscript.CallTestScriptBW(103350, 6, true);
        WhseTestscript.CallTestScriptBW(103350, 7, true);
        WhseTestscript.CallTestScriptBW(103350, 8, true);
        WhseTestscript.CallTestScriptBW(103350, 9, true);
        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        WMSTestCase: Record "Whse. Test Case";
        WhseTestscript: Codeunit "Whse. Testscript";
        BWTestSetupMgt: Codeunit "BW TestSetupManagement";
        WMSTestSetupMgt: Codeunit "WMS TestSetupManagement";
        TestscriptMgt: Codeunit TestscriptManagement;
}

