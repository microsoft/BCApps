codeunit 101084 "Create Acc. Schedule Name"
{

    trigger OnRun()
    begin
        UpdateEvaluationDate();
        InsertData(XCAMPAIGN, XCampaignAnalysis, XBUDGANALYS, XCAMPAIGN);
        InsertData(XCASTAFF, XCostAcctPersonnelCosts, '', '');
        InsertData(XCATRANSFER, XCostAcctTransfer, '', '');
        InsertData(XCAPROF, XCostAcctSummaryRecordDB, '', '');
        InsertData(XDEGREE, XCalculationOfCashFlowRatio, XDEGREE, '');

        InsertData(XCASHFLOW, XCalculationOfCashFlow, XCASHFLOW, '');

        InsertData(XANALYSIS, XCapitalStructure, '', '');
        InsertData(XREVENUE, XRevenues, XBUDGANALYS, '');
    end;

    procedure InsertEvaluationData();
    begin
        InsertData(XANALYSIS, XCapitalStructure, XBALONLY, '');
        InsertData(XCASHFLOW, XCalculationOfCashFlow, XCASHFLOW, '');
        InsertData(XREVENUE, XRevenues, XBUDGANALYS, XREVENUE);
        InsertData(XACCCAT, XAccCatOverview, XPERIODS, '');
        InsertData(XBSDETTxt, XBalanceSheetDetailedTxt, CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '');
        InsertData(XBSSUMTxt, XBalanceSheetSummarizedTxt, CreateColumnLayoutName.GetBSTrendColumnLayoutName(), '');
        InsertData(XISDETTxt, XIncomeStatementDetailedTxt, CreateColumnLayoutName.GetISTrendColumnLayoutName(), '');
        InsertData(XISSUMTxt, XIncomeStatementSummarizedTxt, CreateColumnLayoutName.GetISTrendColumnLayoutName(), '');
        InsertData(XTBTxt, XTrialBalanceTxt, CreateColumnLayoutName.GetBBDRCREBColumnLayoutName(), '');
    end;

    local procedure UpdateEvaluationDate();
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if AccScheduleName.get(XREVENUE) then begin
            AccScheduleName.Validate("Analysis View Name", XREVENUE);
            AccScheduleName.Modify()
        end;
    end;

    var
        CreateColumnLayoutName: Codeunit "Create Column Layout Name";
        XANALYSIS: Label 'ANALYSIS';
        XBALONLY: Label 'BAL ONLY';
        XCapitalStructure: Label 'Capital Structure';
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

    procedure InsertData(Name: Code[10]; Description: Text[80]; DefaultColumnLayout: Code[10]; AnalysisViewName: Code[10])
    var
        FinancialReport: Record "Financial Report";
        "Acc. Schedule Name": Record "Acc. Schedule Name";
    begin
        "Acc. Schedule Name".Init();
        "Acc. Schedule Name".Validate(Name, Name);
        "Acc. Schedule Name".Validate(Description, Description);
        "Acc. Schedule Name".Validate("Analysis View Name", AnalysisViewName);
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

