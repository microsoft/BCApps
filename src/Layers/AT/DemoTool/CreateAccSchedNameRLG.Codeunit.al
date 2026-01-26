codeunit 161612 "Create Acc. Sched. Name RLG"
{

    trigger OnRun()
    begin
        InsertData(XBALANCE, XBalanceRLG, '', '');
        InsertData(XPL1, XProfitLoss1, '', '');
    end;

    var
        XBALANCE: Label 'BALANCE';
        XBalanceRLG: Label 'Balance Sheet RLG';
        XPL1: Label 'P&L';
        XProfitLoss1: Label 'Profit and Loss Statement RLG';

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

