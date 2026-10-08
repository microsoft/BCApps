codeunit 101086 "Create PowerBI Data"
{

    trigger OnRun()
    begin
        CreateAccSchedKpiSetup();
    end;

    local procedure CreateAccSchedKpiSetup()
    var
        AccSchedKPIWebSrvSetup: Record "Acc. Sched. KPI Web Srv. Setup";
        GLBudgetName: Record "G/L Budget Name";
        MiniCreateChartDefinitions: Codeunit "Create Chart Definitions";
    begin
        if GLBudgetName.FindLast() then;
        AccSchedKPIWebSrvSetup.Init();
        AccSchedKPIWebSrvSetup."G/L Budget Name" := GLBudgetName.Name;
        AccSchedKPIWebSrvSetup.Period := AccSchedKPIWebSrvSetup.Period::"Current Fiscal Year + 3 Previous Years";
        AccSchedKPIWebSrvSetup."View By" := AccSchedKPIWebSrvSetup."View By"::Month;
        AccSchedKPIWebSrvSetup."Web Service Name" := 'powerbifinance';
        AccSchedKPIWebSrvSetup.Insert();

        CreateAccSchedKpiSetupLine(MiniCreateChartDefinitions.GetCashCycleAccSchedName());
        CreateAccSchedKpiSetupLine(MiniCreateChartDefinitions.GetIncAndExpAccSchedName());
        CreateAccSchedKpiSetupLine(MiniCreateChartDefinitions.GetReducedTrialBalanceAccSchedName());
    end;

    local procedure CreateAccSchedKpiSetupLine(AccSchedName: Code[10])
    var
        AccSchedKPIWebSrvLine: Record "Acc. Sched. KPI Web Srv. Line";
    begin
        AccSchedKPIWebSrvLine.Init();
        AccSchedKPIWebSrvLine."Acc. Schedule Name" := AccSchedName;
        AccSchedKPIWebSrvLine.Insert();
    end;
}

