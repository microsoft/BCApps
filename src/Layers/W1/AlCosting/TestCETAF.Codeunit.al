codeunit 103510 "Test - CETAF"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
        Corsica_UpdateSalesStatistics: Codeunit Corsica_UpdateSalesStatistics;
        Corsica_ClosingInventoryPeriod: Codeunit Corsica_ClosingInventoryPeriod;
        Corsica_Resiliency: Codeunit Corsica_Resiliency;
        Corsica_AdjCostOfCOGS: Codeunit Corsica_AdjCostOfCOGS;
        Corsica_TracingCost_VE_GL: Codeunit Corsica_TracingCost_VE_GL;
        Corsica_ValuingInvtAtAvgCost: Codeunit Corsica_ValuingInvtAtAvgCost;
    begin
        TestscriptMgt.InitializeOutput(103510);
        WMSTestscriptManagement.SetGlobalPreconditions();

        TestSetupMgt.CreateUseCases();
        TestSetupMgt.CreateTestCases();
        TestSetupMgt.CreateIterations(TestCase, true, false);

        Testscript.CallTestScript(103001, 1, true);
        Testscript.CallTestScript(103001, 2, true);
        Testscript.CallTestScript(103001, 3, true);
        Testscript.CallTestScript(103001, 4, true);
        Testscript.CallTestScript(103001, 5, true);
        Testscript.CallTestScript(103001, 6, true);
        Testscript.CallTestScript(103001, 7, true);
        Testscript.CallTestScript(103001, 13, true);
        Testscript.CallTestScript(103001, 14, true);
        Testscript.CallTestScript(103001, 15, true);
        Testscript.CallTestScript(103001, 16, true);
        Testscript.CallTestScript(103001, 18, true);
        Testscript.CallTestScript(103001, 19, true);

        Corsica_UpdateSalesStatistics.Run();
        Corsica_ClosingInventoryPeriod.Run();
        Corsica_Resiliency.Run();
        Corsica_AdjCostOfCOGS.Run();
        Corsica_TracingCost_VE_GL.Run();
        Corsica_ValuingInvtAtAvgCost.Run();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestCase: Record "Test Case";
        Testscript: Codeunit Testscript;
        TestSetupMgt: Codeunit TestSetupManagement;
        TestscriptMgt: Codeunit TestscriptManagement;
}

