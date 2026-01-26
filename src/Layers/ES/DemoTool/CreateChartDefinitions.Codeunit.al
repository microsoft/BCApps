codeunit 119100 "Create Chart Definitions"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        CreateFinancePerformanceCharts();
        ChartManagement.PopulateChartDefinitionTable();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        ChartManagement: Codeunit "Chart Management";
        MakeAdjustments: Codeunit "Make Adjustments";
        XCashCycleChartDescriptionTxt: Label 'Shows how many days money is tied up from the day you purchase inventory to the day you receive payment from customers.\\A cash cycle is calculated as: Days Sales in Inventory (DSI) + Days Sales Outstanding (DSO) - Days Payable Outstanding (DPO). ';
        XCashFlowChartDescriptionTxt: Label 'Shows the movement of money into or out of your company. You can select to view both future revenue and expenses not yet registered.\\Cash flow is calculated as follows: Receivables + Liquid Funds - Payables.';
        XIncomeAndExpenseChartDescriptionTxt: Label 'Shows the company''s trends in income over expenses. By comparing figures for different periods, you can detect periods that need further investigation.  ';
        XCashCycleAccSchedNameTxt: Label 'I_CACYCLE', Comment = 'Data for Cash Cycle chart abrivated. Starting with I beacuse of sorting. Maximum lenght 10 characters';
        XCashFlowAccSchedNameTxt: Label 'I_CASHFLOW', Comment = 'Data for Cash Flow chart abrivated. Starting with I beacuse of sorting. Maximum lenght 10 characters';
        XIncAndExpAccSchedNameTxt: Label 'I_INCEXP', Comment = 'Data for Income and Expense chart abrivated. Starting with I beacuse of sorting. Maximum lenght 10 characters';
        XReducedTrialBalanceAccSchedNameTxt: Label 'I_MINTRIAL', Comment = 'Data for Mini Trial Balance chart abrivated. Starting with I beacuse of sorting. Maximum lenght 10 characters';
        XAccSchedDescrTxt: Label 'Data for %1 Chart';
        XReducedTrialBalanceAccSchedDescriptionTxt: Label 'Data for Reduced Trial Balance Info Part';
        XPeriodsColumnLayoutNameTxt: Label 'PERIODS', Comment = 'Data for Mini Trial Balance chart abrivated. Starting with I beacuse of sorting. Maximum lenght 10 characters';
        XPeriodsColumnLayoutNameDescriptionTxt: Label 'Periods Definition for Mini Charts';
        XCurrentPeriodTxt: Label 'Current Period';
        XPeriodMinus1Txt: Label 'Current Period - 1';
        XPeriodMinus2Txt: Label 'Current Period - 2';
        XTotalReceivablesTxt: Label 'Total Receivables';
        XTotalPayablesTxt: Label 'Total Payables';
        XTotalCashFlowTxt: Label 'Total Cash Flow';
        XTotalLiquidFundsTxt: Label 'Total Liquid Funds';
        XTotalRevenueCreditTxt: Label 'Total Revenue (Credit)';
        XTotalRevenueTxt: Label 'Total Revenue';
        XTotalGoodsSoldTxt: Label 'Total Goods Sold';
        XTotalExternalCostsTxt: Label 'Total External Costs ';
        XTotalPersonnelCostsTxt: Label 'Total Personnel Costs';
        XTotalFADepricationTxt: Label 'Total Depr. on Fixed Assets';
        XOtherExpensesTxt: Label 'Other Expenses';
        XTotalExpenditureTxt: Label 'Total Expenditure';
        XEarningsBeforeInterestTxt: Label 'Earnings Before Interest';
        XTotalInventoryTxt: Label 'Total Inventory';
        XDaysOfSalesOutstandingTxt: Label 'Days of Sales Outstanding';
        XDaysOfPaymentOutstandingTxt: Label 'Days of Payment Outstanding';
        XDaysSalesOfInventoryTxt: Label 'Days Sales of Inventory';
        XCashCycleDaysTxt: Label 'Cash Cycle (Days)';
        XBussTurnoverNetAmount: Label '1. Business Turnover Net Amount';
        XIncDecOfStocksOnFinGoods: Label '2. Increase/Decrease of Stocks on Finished Goods and Manufactured Goods-Prod.';
        XWorkDoneByCompanyFA: Label '3. Work Done by the Company on Fixed Assets';
        XConsumables: Label '4. Consumables';
        XOtherOperatingIncome: Label '5. Other Operating Income';
        XPersonnelExpenses: Label '6. Personnel Expenses';
        XOtherOperatingExpenses: Label '7. Other Operating Expenses';
        XFixedAssetsDepreciation: Label '8. Fixed Assets Depreciation and Expenses';
        XOperatingResults: Label 'A) OPERATING RESULTS';

    local procedure CreateFinancePerformanceCharts()
    begin
        case DemoDataSetup."Data Type" of
            DemoDataSetup."Data Type"::Extended:
                SetupAccountSchedules();
            DemoDataSetup."Data Type"::Standard,
          DemoDataSetup."Data Type"::Evaluation:
                SetupAccountSchedules();
        end;
        CreateColumnLayout();
        InsertFinancialChartDefinitions();
    end;

    local procedure SetupAccountSchedules()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        BalanceAtDate: Option;
        NetChange: Option;
        TotalAccounts: Enum "Acc. Schedule Line Totaling Type";
        PostingAccounts: Enum "Acc. Schedule Line Totaling Type";
        Formula: Enum "Acc. Schedule Line Totaling Type";
    begin
        BalanceAtDate := AccScheduleLine."Row Type"::"Balance at Date";
        NetChange := AccScheduleLine."Row Type"::"Net Change";
        TotalAccounts := AccScheduleLine."Totaling Type"::"Total Accounts";
        PostingAccounts := AccScheduleLine."Totaling Type"::"Posting Accounts";
        Formula := AccScheduleLine."Totaling Type"::Formula;

        // Account Schedule for Cash Flow Chart
        CreateAccScheduleName(
          XCashFlowAccSchedNameTxt, StrSubstNo(XAccSchedDescrTxt, ChartManagement.CashFlowChartName()), XPeriodsColumnLayoutNameTxt);
        CreateAccScheduleLine(
          XCashFlowAccSchedNameTxt, '10', XTotalReceivablesTxt,
          StrSubstNo('%1|%2', MakeAdjustments.Convert('43'), MakeAdjustments.Convert('44')),
          TotalAccounts, BalanceAtDate);
        CreateAccScheduleLine(
          XCashFlowAccSchedNameTxt, '20', XTotalPayablesTxt, MakeAdjustments.Convert('40'), TotalAccounts, BalanceAtDate);
        CreateAccScheduleLine(
          XCashFlowAccSchedNameTxt, '30', XTotalLiquidFundsTxt,
          CreateTotalAccountLine_TotalLiquidFunds(), TotalAccounts,
          BalanceAtDate);
        CreateAccScheduleLine(XCashFlowAccSchedNameTxt, '40', XTotalCashFlowTxt, '10..30', Formula, BalanceAtDate);

        // Account Schedule for Income and Expense Chart
        CreateAccScheduleName(
          XIncAndExpAccSchedNameTxt,
          StrSubstNo(XAccSchedDescrTxt, ChartManagement.IncomeAndExpenseChartName()), XPeriodsColumnLayoutNameTxt);
        CreateAccScheduleLine(
          XIncAndExpAccSchedNameTxt, '10', XTotalRevenueCreditTxt, CreateTotalAccountLine_TotalRevenue(), TotalAccounts, NetChange);
        CreateAccScheduleLine(XIncAndExpAccSchedNameTxt, '11', XTotalRevenueTxt, '-10', Formula, NetChange);
        CreateAccScheduleLine(
          XIncAndExpAccSchedNameTxt, '20', XTotalGoodsSoldTxt, CreateTotalAccountLine_TotalCost(), TotalAccounts, NetChange);
        CreateAccScheduleLine(
          XIncAndExpAccSchedNameTxt, '30', XTotalExternalCostsTxt, CreateTotalAccountLine_TotalOperatingExpenses(), TotalAccounts, NetChange);
        CreateAccScheduleLine(
          XIncAndExpAccSchedNameTxt, '40', XTotalPersonnelCostsTxt, CreateTotalAccountLine_TotalPersonnelExpenses(), TotalAccounts, NetChange);
        CreateAccScheduleLine(
          XIncAndExpAccSchedNameTxt, '50', XTotalFADepricationTxt, MakeAdjustments.Convert('68'), TotalAccounts, NetChange);
        CreateAccScheduleLine(
          XIncAndExpAccSchedNameTxt, '60', XOtherExpensesTxt, CreateTotalAccountLine_OtherCostsOfOperations(), PostingAccounts, NetChange);
        CreateAccScheduleLine(XIncAndExpAccSchedNameTxt, '70', XTotalExpenditureTxt, '-20..60', Formula, NetChange);
        CreateAccScheduleLine(XIncAndExpAccSchedNameTxt, '80', XEarningsBeforeInterestTxt, '11+70', Formula, NetChange);

        // Account Schedule for Cash Cycle Chart
        CreateAccScheduleName(
          XCashCycleAccSchedNameTxt, StrSubstNo(XAccSchedDescrTxt, ChartManagement.CashCycleChartName()), XPeriodsColumnLayoutNameTxt);
        CreateAccScheduleLine(
          XCashCycleAccSchedNameTxt, '10', XTotalRevenueTxt, CreateTotalAccountLine_TotalRevenue(), TotalAccounts, BalanceAtDate);
        CreateAccScheduleLine(
          XCashCycleAccSchedNameTxt, '20', XTotalReceivablesTxt,
          StrSubstNo('%1|%2', MakeAdjustments.Convert('43'), MakeAdjustments.Convert('44')),
          TotalAccounts, BalanceAtDate);
        CreateAccScheduleLine(
          XCashCycleAccSchedNameTxt, '30', XTotalPayablesTxt, MakeAdjustments.Convert('40'), TotalAccounts, NetChange);
        CreateAccScheduleLine(
          XCashCycleAccSchedNameTxt, '40', XTotalInventoryTxt, MakeAdjustments.Convert('3'), TotalAccounts, NetChange);
        CreateAccScheduleLineFormula(XCashCycleAccSchedNameTxt, '100', XDaysOfSalesOutstandingTxt, '-360*''20''/''10''', Formula, BalanceAtDate);
        CreateAccScheduleLineFormula(XCashCycleAccSchedNameTxt, '110', XDaysOfPaymentOutstandingTxt, '360*''30''/''10''', Formula, BalanceAtDate);
        CreateAccScheduleLineFormula(XCashCycleAccSchedNameTxt, '120', XDaysSalesOfInventoryTxt, '-360*''40''/''10''', Formula, BalanceAtDate);
        CreateAccScheduleLineFormula(XCashCycleAccSchedNameTxt, '200', XCashCycleDaysTxt, '100+110-120', Formula, BalanceAtDate);

        // Account Schedule for Reduced Trial Balance
        CreateAccScheduleName(
          XReducedTrialBalanceAccSchedNameTxt, XReducedTrialBalanceAccSchedDescriptionTxt, XPeriodsColumnLayoutNameTxt);
        CreateAccScheduleLine(XReducedTrialBalanceAccSchedNameTxt, 'A.1', XBussTurnoverNetAmount, CreateTotalAccountLine_TotalRevenue(), TotalAccounts, NetChange);
        CreateAccScheduleLine(XReducedTrialBalanceAccSchedNameTxt, 'A.2', XIncDecOfStocksOnFinGoods,
          StrSubstNo('%1|%2|%3',
            MakeAdjustments.Convert('71'),
            MakeAdjustments.Convert('6930'),
            MakeAdjustments.Convert('7930')),
          TotalAccounts, NetChange);
        CreateAccScheduleLine(XReducedTrialBalanceAccSchedNameTxt, 'A.3', XWorkDoneByCompanyFA, MakeAdjustments.Convert('73'), TotalAccounts, NetChange);
        CreateAccScheduleLine(XReducedTrialBalanceAccSchedNameTxt, 'A.4', XConsumables, CreateTotalAccountLine_TotalCost(), TotalAccounts, NetChange);
        CreateAccScheduleLine(XReducedTrialBalanceAccSchedNameTxt, 'A.5', XOtherOperatingIncome,
          StrSubstNo('%1|%2|%3',
            MakeAdjustments.Convert('740'),
            MakeAdjustments.Convert('747'),
            MakeAdjustments.Convert('75')),
          TotalAccounts, NetChange);
        CreateAccScheduleLine(XReducedTrialBalanceAccSchedNameTxt, 'A.6', XPersonnelExpenses,
          StrSubstNo('%1|%2|%3',
            MakeAdjustments.Convert('64'),
            MakeAdjustments.Convert('7950'),
            MakeAdjustments.Convert('7957')),
          TotalAccounts, NetChange);
        CreateAccScheduleLine(XReducedTrialBalanceAccSchedNameTxt, 'A.7', XOtherOperatingExpenses, CreateTotalAccountLine_OtherCostsOfOperations(), TotalAccounts, NetChange);
        CreateAccScheduleLine(XReducedTrialBalanceAccSchedNameTxt, 'A.8', XFixedAssetsDepreciation, CreateTotalAccountLIne_FixedAssDeprecAndExpenses(), TotalAccounts, NetChange);
        CreateAccScheduleLine(XReducedTrialBalanceAccSchedNameTxt, 'A.TOT', XOperatingResults, 'A.1+A.2+A.3+A.4+A.5+A.6+A.7+A.8', Formula, NetChange);
    end;

    local procedure CreateColumnLayout()
    var
        CreateColumnLayoutName: Codeunit "Create Column Layout Name";
        CreateColumnLayout: Codeunit "Create Column Layout";
    begin
        CreateColumnLayoutName.InsertData(XPeriodsColumnLayoutNameTxt, XPeriodsColumnLayoutNameDescriptionTxt);
        CreateColumnLayout.InsertMiniAppData(XPeriodsColumnLayoutNameTxt, '10', XCurrentPeriodTxt, 10000, '');
        CreateColumnLayout.InsertMiniAppData(XPeriodsColumnLayoutNameTxt, '10', XPeriodMinus1Txt, 20000, InsertPeriodFormula(-1));
        CreateColumnLayout.InsertMiniAppData(XPeriodsColumnLayoutNameTxt, '10', XPeriodMinus2Txt, 30000, InsertPeriodFormula(-2));
    end;

    local procedure InsertFinancialChartDefinitions()
    var
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
        TrialBalanceSetup: Record "Trial Balance Setup";
        Line: Enum "Account Schedule Chart Type";
        StepLine: Enum "Account Schedule Chart Type";
        Column: Enum "Account Schedule Chart Type";
    begin
        Line := AccSchedChartSetupLine."Chart Type"::Line;
        Column := AccSchedChartSetupLine."Chart Type"::Column;
        StepLine := AccSchedChartSetupLine."Chart Type"::StepLine;

        // Cash Flow Chart
        InsertFinancialChartDefinition(
          ChartManagement.CashFlowChartName(), XCashFlowChartDescriptionTxt,
          XCashFlowAccSchedNameTxt, XPeriodsColumnLayoutNameTxt, 3, true);
        InsertFinancialChartSetupLine(ChartManagement.CashFlowChartName(), XTotalReceivablesTxt, Column, 10000, 10000);
        InsertFinancialChartSetupLine(ChartManagement.CashFlowChartName(), XTotalPayablesTxt, Column, 20000, 10000);
        InsertFinancialChartSetupLine(ChartManagement.CashFlowChartName(), XTotalLiquidFundsTxt, Column, 30000, 10000);
        InsertFinancialChartSetupLine(ChartManagement.CashFlowChartName(), XTotalCashFlowTxt, StepLine, 40000, 10000);

        // Income and Expense Chart
        InsertFinancialChartDefinition(
          ChartManagement.IncomeAndExpenseChartName(),
          XIncomeAndExpenseChartDescriptionTxt, XIncAndExpAccSchedNameTxt, XPeriodsColumnLayoutNameTxt, 3, false);
        InsertFinancialChartSetupLine(ChartManagement.IncomeAndExpenseChartName(), XTotalRevenueTxt, Column, 20000, 10000);
        InsertFinancialChartSetupLine(ChartManagement.IncomeAndExpenseChartName(), XTotalExpenditureTxt, Column, 80000, 10000);
        InsertFinancialChartSetupLine(ChartManagement.IncomeAndExpenseChartName(), XEarningsBeforeInterestTxt, Column, 90000, 10000);

        // Cash Cycle Chart
        InsertFinancialChartDefinition(
          ChartManagement.CashCycleChartName(),
          XCashCycleChartDescriptionTxt, XCashCycleAccSchedNameTxt, XPeriodsColumnLayoutNameTxt, 12, false);
        InsertFinancialChartSetupLine(ChartManagement.CashCycleChartName(), XDaysOfSalesOutstandingTxt, Line, 50000, 10000);
        InsertFinancialChartSetupLine(ChartManagement.CashCycleChartName(), XDaysOfPaymentOutstandingTxt, Line, 60000, 10000);
        InsertFinancialChartSetupLine(ChartManagement.CashCycleChartName(), XDaysSalesOfInventoryTxt, Line, 70000, 10000);
        InsertFinancialChartSetupLine(ChartManagement.CashCycleChartName(), XCashCycleDaysTxt, Line, 80000, 10000);

        // Insert Mini Trial balance
        TrialBalanceSetup.Get();
        TrialBalanceSetup."Account Schedule Name" := XReducedTrialBalanceAccSchedNameTxt;
        TrialBalanceSetup."Column Layout Name" := XPeriodsColumnLayoutNameTxt;
        TrialBalanceSetup.Modify();
    end;

    local procedure InsertFinancialChartDefinition(ChartName: Text[30]; ChartDescription: Text[250]; AccSchedName: Code[10]; ColumnLayoutName: Code[10]; NoOfPeriods: Integer; LookAhead: Boolean)
    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        AccountSchedulesChartSetup.Init();
        AccountSchedulesChartSetup."User ID" := '';
        AccountSchedulesChartSetup.Name := ChartName;
        AccountSchedulesChartSetup.Description := ChartDescription;
        AccountSchedulesChartSetup."Start Date" := GetCurrentDay();
        AccountSchedulesChartSetup."Account Schedule Name" := AccSchedName;
        AccountSchedulesChartSetup."Column Layout Name" := ColumnLayoutName;
        AccountSchedulesChartSetup."Period Length" := AccountSchedulesChartSetup."Period Length"::Month;
        AccountSchedulesChartSetup."No. of Periods" := NoOfPeriods;
        AccountSchedulesChartSetup."Look Ahead" := LookAhead;
        AccountSchedulesChartSetup.Insert(true);
    end;

    local procedure InsertFinancialChartSetupLine(ChartName: Text[30]; MeasureName: Text[111]; ChartType: Enum "Account Schedule Chart Type"; AccountScheduleLineNo: Integer; ColumnLayoutLineNo: Integer)
    var
        AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
    begin
        AccountSchedulesChartSetup.Get('', ChartName);

        AccSchedChartSetupLine.Init();
        AccSchedChartSetupLine."User ID" := '';
        AccSchedChartSetupLine.Name := AccountSchedulesChartSetup.Name;
        AccSchedChartSetupLine."Account Schedule Name" := AccountSchedulesChartSetup."Account Schedule Name";
        AccSchedChartSetupLine."Column Layout Name" := AccountSchedulesChartSetup."Column Layout Name";
        AccSchedChartSetupLine."Account Schedule Line No." := AccountScheduleLineNo;
        AccSchedChartSetupLine."Column Layout Line No." := ColumnLayoutLineNo;
        AccSchedChartSetupLine."Measure Name" := MeasureName;
        AccSchedChartSetupLine."Measure Value" := StrSubstNo('%1 %2', AccountScheduleLineNo, ColumnLayoutLineNo);
        AccSchedChartSetupLine."Chart Type" := ChartType;
        AccSchedChartSetupLine.Insert(true);
    end;

    local procedure CreateAccScheduleName(Name: Code[10]; Description: Text[80]; DefaultColumnLayout: Code[10])
    var
        CreateAccScheduleName: Codeunit "Create Acc. Schedule Name";
    begin
        CreateAccScheduleName.InsertData(Name, Description, DefaultColumnLayout, '', false);
    end;

    local procedure CreateAccScheduleLine(ScheduleName: Code[10]; RowNo: Code[10]; Description: Text[80]; Totaling: Text[250]; TotalingType: Enum "Acc. Schedule Line Totaling Type"; RowType: Option)
    var
        CreateAccScheduleLine: Codeunit "Create Acc. Schedule Line";
    begin
        CreateAccScheduleLine.InsertMiniAppData(ScheduleName, RowNo, Description, Totaling, TotalingType, RowType, false);
    end;

    local procedure CreateAccScheduleLineFormula(ScheduleName: Code[10]; RowNo: Code[10]; Description: Text[80]; Totaling: Text[250]; TotalingType: Enum "Acc. Schedule Line Totaling Type"; RowType: Option)
    var
        CreateAccScheduleLine: Codeunit "Create Acc. Schedule Line";
    begin
        CreateAccScheduleLine.InsertMiniAppDataFormula(ScheduleName, RowNo, Description, Totaling, TotalingType, RowType, false, true);
    end;

    local procedure CreateTotalAccountLine_TotalLiquidFunds(): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6',
              MakeAdjustments.Convert('57'),
              MakeAdjustments.Convert('51'),
              MakeAdjustments.Convert('52'),
              MakeAdjustments.Convert('56'),
              MakeAdjustments.Convert('58'),
              MakeAdjustments.Convert('59')));
    end;

    local procedure CreateTotalAccountLine_TotalRevenue(): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8|%9',
              MakeAdjustments.Convert('700'),
              MakeAdjustments.Convert('701'),
              MakeAdjustments.Convert('702'),
              MakeAdjustments.Convert('703'),
              MakeAdjustments.Convert('704'),
              MakeAdjustments.Convert('705'),
              MakeAdjustments.Convert('706'),
              MakeAdjustments.Convert('708'),
              MakeAdjustments.Convert('709')));
    end;

    local procedure CreateTotalAccountLine_TotalCost(): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11|%12|%13|%14|%15',
              MakeAdjustments.Convert('600'),
              MakeAdjustments.Convert('601'),
              MakeAdjustments.Convert('602'),
              MakeAdjustments.Convert('606'),
              MakeAdjustments.Convert('607'),
              MakeAdjustments.Convert('608'),
              MakeAdjustments.Convert('609'),
              MakeAdjustments.Convert('61'),
              MakeAdjustments.Convert('6931'),
              MakeAdjustments.Convert('6932'),
              MakeAdjustments.Convert('6932'),
              MakeAdjustments.Convert('6933'),
              MakeAdjustments.Convert('7931'),
              MakeAdjustments.Convert('7932'),
              MakeAdjustments.Convert('7933')));
    end;

    local procedure CreateTotalAccountLine_TotalOperatingExpenses(): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11|%12|%13',
              MakeAdjustments.Convert('64'),
              MakeAdjustments.Convert('7950'),
              MakeAdjustments.Convert('7957'),
              MakeAdjustments.Convert('62'),
              MakeAdjustments.Convert('631'),
              MakeAdjustments.Convert('634'),
              MakeAdjustments.Convert('636'),
              MakeAdjustments.Convert('639'),
              MakeAdjustments.Convert('65'),
              MakeAdjustments.Convert('694'),
              MakeAdjustments.Convert('695'),
              MakeAdjustments.Convert('794'),
              MakeAdjustments.Convert('7954')));
    end;

    local procedure CreateTotalAccountLine_TotalPersonnelExpenses(): Text
    begin
        exit(StrSubstNo('%1|%2|%3',
              MakeAdjustments.Convert('64'),
              MakeAdjustments.Convert('7950'),
              MakeAdjustments.Convert('7957')));
    end;

    local procedure CreateTotalAccountLine_OtherCostsOfOperations(): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8|%9|%10',
              MakeAdjustments.Convert('62'),
              MakeAdjustments.Convert('631'),
              MakeAdjustments.Convert('634'),
              MakeAdjustments.Convert('636'),
              MakeAdjustments.Convert('639'),
              MakeAdjustments.Convert('65'),
              MakeAdjustments.Convert('694'),
              MakeAdjustments.Convert('695'),
              MakeAdjustments.Convert('794'),
              MakeAdjustments.Convert('7954')));
    end;

    local procedure CreateTotalAccountLIne_FixedAssDeprecAndExpenses(): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|11|%12|%13|%14|%15|%16|%17|%18',
              MakeAdjustments.Convert('68'),
              MakeAdjustments.Convert('746'),
              MakeAdjustments.Convert('7951'),
              MakeAdjustments.Convert('7952'),
              MakeAdjustments.Convert('7955'),
              MakeAdjustments.Convert('7956'),
              MakeAdjustments.Convert('670'),
              MakeAdjustments.Convert('671'),
              MakeAdjustments.Convert('672'),
              MakeAdjustments.Convert('770'),
              MakeAdjustments.Convert('771'),
              MakeAdjustments.Convert('772'),
              MakeAdjustments.Convert('690'),
              MakeAdjustments.Convert('691'),
              MakeAdjustments.Convert('692'),
              MakeAdjustments.Convert('790'),
              MakeAdjustments.Convert('791'),
              MakeAdjustments.Convert('792')));
    end;

    local procedure InsertPeriodFormula(Period: Integer): Text[10]
    var
        PeriodFormulaParser: Codeunit "Period Formula Parser";
    begin
        exit(StrSubstNo('%1%2', Period, PeriodFormulaParser.GetPeriodName()));
    end;

    procedure GetCashCycleAccSchedName(): Code[10]
    begin
        exit(CopyStr(XCashCycleAccSchedNameTxt, 1, 10));
    end;

    procedure GetIncAndExpAccSchedName(): Code[10]
    begin
        exit(CopyStr(XIncAndExpAccSchedNameTxt, 1, 10));
    end;

    procedure GetReducedTrialBalanceAccSchedName(): Code[10]
    begin
        exit(CopyStr(XReducedTrialBalanceAccSchedNameTxt, 1, 10));
    end;

    local procedure GetCurrentDay(): Date
    var
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        exit(MakeAdjustments.AdjustDate(19030401D));
    end;
}
