codeunit 161411 "Create Acc. Sched. Name SKR03"
{

    trigger OnRun()
    begin
        InsertData(XBALANCE, XBalanceHGB, '', '');
        InsertData(XPL, XProfitandLossStatementHGB, '', '');
    end;

    var
        XBALANCE: Label 'BALANCE';
        XBalanceHGB: Label 'Balance Sheet HGB';
        XPL: Label 'P&L';
        XProfitandLossStatementHGB: Label 'Profit and Loss Statement HGB';

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
}

