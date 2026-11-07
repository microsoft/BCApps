codeunit 101711 "Create Analysis Report Name"
{

    trigger OnRun()
    begin
        InsertData(0, XCUST1BUDG, XActualvsbudgetCustGroups, XCUSTGROUPS, XBUDGET);
        InsertData(0, XCUSTSALES, XAnalyzingcustomers, XCUSTALL, XSALES);
        InsertData(0, XITEM1PRC, XPriceanalysisformyitems, XMYITEMS, XPRICES);
        InsertData(0, XITEMPROF, XProfitabilityAnalysis, XFURNITALL, XPROFIT);
        InsertData(0, XITEMSALE, XFurnitureSales, XFURNITALL, XSALES);
        InsertData(0, XKASALES, XKeyAccountsSales, XMYCUST, XSALES);
        InsertData(2, XFURNTURN, XFurnitureInventoryTurnover, XFURNITALL, XINVTTURN);
        InsertData(2, XFURNWIP, XFurnitureWIPInventory, XFURNITALL, XWIP);
        InsertData(2, XITEMTURN, XItemsInventoryTurnover, XMYITEMS, XINVTTURN);
        InsertData(2, XITEMWIP, XItemsWIPInventory, XMYITEMS, XWIP);
    end;

    var
        AnalysisReportName: Record "Analysis Report Name";
        XCUST1BUDG: Label 'CUST1-BUDG';
        XCUSTSALES: Label 'CUST-SALES';
        XITEM1PRC: Label 'ITEM1-PRC';
        XITEMPROF: Label 'ITEM-PROF';
        XITEMSALE: Label 'ITEM-SALE';
        XKASALES: Label 'KA-SALES';
        XFURNTURN: Label 'FURN-TURN';
        XFURNWIP: Label 'FURN-WIP';
        XITEMTURN: Label 'ITEM-TURN';
        XITEMWIP: Label 'ITEM-WIP';
        XActualvsbudgetCustGroups: Label 'Actual vs. budget, CustGroups';
        XAnalyzingcustomers: Label 'Analyzing customers';
        XPriceanalysisformyitems: Label 'Price analysis for my items';
        XProfitabilityAnalysis: Label 'Profitability Analysis';
        XFurnitureSales: Label 'Furniture Sales';
        XKeyAccountsSales: Label 'Key Accounts Sales';
        XFurnitureInventoryTurnover: Label 'Furniture - Inventory Turnover';
        XFurnitureWIPInventory: Label 'Furniture - WIP Inventory';
        XItemsInventoryTurnover: Label 'Items - Inventory Turnover';
        XItemsWIPInventory: Label 'Items - WIP Inventory';
        XCUSTGROUPS: Label 'CUSTGROUPS';
        XCUSTALL: Label 'CUST-ALL';
        XMYITEMS: Label 'MY-ITEMS';
        XFURNITALL: Label 'FURNIT-ALL';
        XMYCUST: Label 'MY-CUST';
        XBUDGET: Label 'BUDGET';
        XSALES: Label 'SALES';
        XPRICES: Label 'PRICES';
        XPROFIT: Label 'PROFIT';
        XINVTTURN: Label 'INVT-TURN';
        XWIP: Label 'WIP';

    procedure InsertData(AnalysisArea: Option Sales,Purchase,Inventory; Name: Code[10]; Description: Text[30]; AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    begin
        AnalysisReportName.Init();
        AnalysisReportName.Validate("Analysis Area", AnalysisArea);
        AnalysisReportName.Validate(Name, Name);
        AnalysisReportName.Validate(Description, Description);
        AnalysisReportName.Validate("Analysis Line Template Name", AnalysisLineTemplateName);
        AnalysisReportName.Validate("Analysis Column Template Name", AnalysisColumnTemplateName);
        AnalysisReportName.Insert(true);
    end;
}

