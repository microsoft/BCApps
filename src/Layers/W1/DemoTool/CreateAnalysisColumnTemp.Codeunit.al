codeunit 101716 "Create Analysis Column Temp"
{

    trigger OnRun()
    begin
        InsertData(0, XBUDGET, XTurnoveractualvsbudget);
        InsertData(0, XPRICES, XPricesAnalysis);
        InsertData(0, XPROFIT, XProfitability);
        InsertData(0, XSALES, XTurnoveractualvslast);
        InsertData(2, XINVTTURN, XInventoryTurnover);
        InsertData(2, XWIP, XWIPInventory);
    end;

    var
        AnalysisColumnTemp: Record "Analysis Column Template";
        XBUDGET: Label 'BUDGET';
        XPRICES: Label 'PRICES';
        XPROFIT: Label 'PROFIT';
        XSALES: Label 'SALES';
        XINVTTURN: Label 'INVT-TURN';
        XWIP: Label 'WIP';
        XTurnoveractualvsbudget: Label 'Turnover, actual vs. budget';
        XPricesAnalysis: Label 'Prices Analysis';
        XProfitability: Label 'Profitability';
        XTurnoveractualvslast: Label 'Turnover, actual vs last';
        XInventoryTurnover: Label 'Inventory Turnover';
        XWIPInventory: Label 'WIP Inventory';

    procedure InsertData(AnalysisArea: Option Sales,Purchase,Inventory; Name: Code[10]; Description: Text[80])
    begin
        AnalysisColumnTemp.Init();
        AnalysisColumnTemp.Validate("Analysis Area", AnalysisArea);
        AnalysisColumnTemp.Validate(Name, Name);
        AnalysisColumnTemp.Validate(Description, Description);
        AnalysisColumnTemp.Insert(true);
    end;
}

