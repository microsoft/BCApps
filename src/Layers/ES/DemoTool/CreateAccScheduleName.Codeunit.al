codeunit 101084 "Create Acc. Schedule Name"
{

    trigger OnRun()
    begin
        // InsertData(XANALYSIS,XCapitalStructure,'','');
        // InsertData(XCAMPAIGN,XCampaignAnalysis,XBUDGANALYS,XCAMPAIGN);
        // InsertData(XREVENUE,XRevenues,XBUDGANALYS,XREVENUE);
        InsertData(XCAMPAIGN, XCampaignAnalysis, XBUDGANALYS, XCAMPAIGN, false);
        InsertData(XREVENUE, XRevenues, XBUDGANALYS, XREVENUE, false);
        InsertData(XCASTAFF, XCostAcctPersonnelCosts, XCASTAFF, '', false);
        InsertData(XCATRANSFER, XCostAcctTransfer, XCATRANSFER, '', false);
        InsertData(XCAPROF, XCostAcctSummaryRecordDB, XCAPROF, '', false);

        InsertData(XDEGREE, XCalculationOfCashFlowRatio, XDEGREE, '', false);


        // InsertData(XPYGNOR,XProfitOrLossStandard,XPYG,'',TRUE);
        // InsertData(XPYGABR,XProfitOrLossSummary,XPYG,'',TRUE);
        // InsertData(XBALNOR,XBalanceSheetStandard,XBALANCE,'',TRUE);
        // InsertData(XBALABR,XBalanceSheetSummary,XBALANCE,'',TRUE);
        InsertData(XBAL08NOR, XBalanceSheet2008Standard, XBALANCE, '', true);
        InsertData(XBAL08ABR, XBalanceSheet2008Summary, XBALANCE, '', false);
        InsertData(XBAL08PYME, XBalanceSheet2008Pyme, XBALANCE, '', false);
        InsertData(XPYG08NOR, XProfitOrLoss2008Standard, XPYG, '', true);
        InsertData(XPYG08ABR, XProfitOrLoss2008Summary, XPYG, '', false);
        InsertData(XPYG08PYME, XProfitOrLoss2008Pyme, XPYG, '', false);
        InsertData(XIG08NOR, XIncomeExpensesStatus2008Stand, XPYG, '', true);
        InsertData(XIG08ABR, XIncomeExpensesStatus2008Summ, XPYG, '', false);
        InsertData(XEFE08, XEFE2008, XPYG, '', false);

        // UpdateEvaluationDate();
        InsertData(XANALYSIS, XCapitalStructure, XDEFAULT, '', false);
        InsertData(XCASHFLOW, XCalculationOfCashFlow, XCASHFLOW, '', false);
    end;

    procedure InsertEvaluationData();
    begin
        InsertData(XANALYSIS, XCapitalStructure, XDEFAULT, '', false);
        InsertData(XCASHFLOW, XCalculationOfCashFlow, XCASHFLOW, '', false);
        InsertData(XREVENUE, XRevenues, XBUDGANALYS, XREVENUE, false);
        InsertData(XACCCAT, XAccCatOverview, XPERIODS, '', false);
        InsertData(XBSDETTxt, XBalanceSheetDetailedTxt, CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '', false);
        InsertData(XBSSUMTxt, XBalanceSheetSummarizedTxt, CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '', false);
        InsertData(XISDETTxt, XIncomeStatementDetailedTxt, CreateColumnLayoutName.GetISTrendColumnLayoutName(), '', false);
        InsertData(XISSUMTxt, XIncomeStatementSummarizedTxt, CreateColumnLayoutName.GetISTrendColumnLayoutName(), '', false);
        InsertData(XTBTxt, XTrialBalanceTxt, CreateColumnLayoutName.GetBBDRCREBColumnLayoutName(), '', false);
    end;

    var
        CreateColumnLayoutName: Codeunit "Create Column Layout Name";
        XANALYSIS: Label 'ANALYSIS';
        XCapitalStructure: Label 'Capital Structure';
        XDEFAULT: Label 'DEFAULT';
        XCAMPAIGN: Label 'CAMPAIGN';
        XCampaignAnalysis: Label 'Campaign Analysis';
        XBUDGANALYS: Label 'BUDGANALYS';
        XREVENUE: Label 'REVENUE';
        XRevenues: Label 'Revenues';
        XCASHFLOW: Label 'CASHFLOW', Comment = 'Cashflow is a name of Account Schedule.';
        XDEGREE: Label 'DEGREE', Comment = 'Degree is a name of Account Schedule.';
        XCalculationOfCashFlow: Label 'Calculation Of Cash Flow';
        XCalculationOfCashFlowRatio: Label 'Calculation of Cash Flow Ratio';
        XCASTAFF: Label 'CA-STAFF', Comment = 'Cost Acct. Personnel Costs.';
        XCostAcctPersonnelCosts: Label 'Cost Acct. Personnel Costs';
        XCATRANSFER: Label 'CA-TRANS', Comment = 'Cost Acct. Transfer.';
        XCostAcctTransfer: Label 'Cost Acct. Transfer';
        XCAPROF: Label 'CA-PROF', Comment = 'Cost Acct. Summary Record DB per CC/CO.';
        XCostAcctSummaryRecordDB: Label 'Cost Acct. Summary Record DB per CC/CO', Comment = 'It is description of Account Schedule Name. DB means Database, CC means Cost Center and CO means Cost Object.';
        XProfitOrLoss2008Standard: Label 'Profit or Loss 2008 (Standard)';
        XProfitOrLoss2008Summary: Label 'Profit or Loss 2008 (Summary)';
        XProfitOrLoss2008Pyme: Label 'Profit or Loss 2008 (Small-Mid Companies)';
        XBalanceSheet2008Standard: Label 'Balance Sheet 2008 (Standard)';
        XBalanceSheet2008Summary: Label 'Balance Sheet 2008 (Summary)';
        XBalanceSheet2008Pyme: Label 'Balance Sheet 2008 (Small-Mid Companies)';
        XIncomeExpensesStatus2008Stand: Label 'Income and Expenses Status 2008 (Standard)';
        XIncomeExpensesStatus2008Summ: Label 'Income and Expenses Status 2008 (Summary)';
        XEFE2008: Label 'Cash Flow 2008';
        XPYG: Label 'PYG';
        XBALANCE: Label 'BALANCE';
        XPYG08NOR: Label 'PYG08-NOR';
        XPYG08ABR: Label 'PYG08-ABR';
        XPYG08PYME: Label 'PYG08-PYME';
        XBAL08NOR: Label 'BAL08-NOR';
        XBAL08ABR: Label 'BAL08-ABR';
        XBAL08PYME: Label 'BAL08-PYME';
        XIG08NOR: Label 'IG08-NOR';
        XIG08ABR: Label 'IG08-ABR';
        XEFE08: Label 'EFE08';
        XACCCAT: Label 'ACC-CAT', Comment = 'ACC-CAT is the name of the Account Schedule.';
        XAccCatOverview: Label 'Account Categories overview';
        XPERIODS: Label 'PERIODS';
        XBSDETTxt: Label 'BS DET', Locked = true;
        XBSSUMTxt: Label 'BS SUM', Locked = true;
        XISDETTxt: Label 'IS DET', Locked = true;
        XISSUMTxt: Label 'IS SUM', Locked = true;
        XTBTxt: Label 'TB', Locked = true;
        XBalanceSheetDetailedTxt: Label 'Balance Sheet Detailed';
        XBalanceSheetSummarizedTxt: Label 'Balance Sheet Summarized';
        XIncomeStatementDetailedTxt: Label 'Income Statement Detailed';
        XIncomeStatementSummarizedTxt: Label 'Income Statement Summarized';
        XTrialBalanceTxt: Label 'Trial Balance';

    procedure InsertData(Name: Code[10]; Description: Text[80]; DefaultColumnLayout: Code[10]; AnalysisViewName: Code[10]; Standardized: Boolean)
    var
        FinancialReport: Record "Financial Report";
        "Acc. Schedule Name": Record "Acc. Schedule Name";
    begin
        "Acc. Schedule Name".Init();
        "Acc. Schedule Name".Validate(Name, Name);
        "Acc. Schedule Name".Validate(Description, Description);
        "Acc. Schedule Name".Validate("Analysis View Name", AnalysisViewName);
        "Acc. Schedule Name".Validate(Standardized, Standardized);
        "Acc. Schedule Name".Insert();
        FinancialReport.Init();
        FinancialReport.Name := Name;
        FinancialReport."Financial Report Row Group" := Name;
        FinancialReport.Description := Description;
        FinancialReport."Financial Report Column Group" := DefaultColumnLayout;
        FinancialReport.Insert();
    end;

    internal procedure GetBSDETAccountScheduleName(): Code[10]
    begin
        exit(CopyStr(XBSDETTxt, 1, 10));
    end;

    internal procedure GetBSSUMAccountScheduleName(): Code[10]
    begin
        exit(CopyStr(XBSSUMTxt, 1, 10));
    end;

    internal procedure GetISDETAccountScheduleName(): Code[10]
    begin
        exit(CopyStr(XISDETTxt, 1, 10));
    end;

    internal procedure GetISSUMAccountScheduleName(): Code[10]
    begin
        exit(CopyStr(XISSUMTxt, 1, 10));
    end;

    internal procedure GetTBAccountScheduleName(): Code[10]
    begin
        exit(CopyStr(XTBTxt, 1, 10));
    end;

}
