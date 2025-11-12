codeunit 101718 "Create Analysis Column"
{

    trigger OnRun()
    begin
        InsertData(0, XBUDGET, 10000, 'A1', XTurnoverinactual, true, 1, 0, '', false, '', XSALESAMT, 2, 0, 0, '');
        InsertData(0, XBUDGET, 20000, 'A2', XTurnoverinQtyactual, true, 1, 0, '', true, '', XSALESQTY, 1, 0, 0, '');
        InsertData(0, XBUDGET, 30000, 'A3', XTurnoverinbudget, false, 1, 1, '', false, '', XSALESAMT, 2, 0, 0, '');
        InsertData(0, XBUDGET, 40000, 'A4', XTurnoverinQtybudget, false, 1, 1, '', false, '', XSALESQTY, 1, 0, 0, '');
        InsertData(0, XBUDGET, 50000, 'A5', XDeviation, false, 0, 0, '(A3/A1-1)*100', false, '', '', 0, 0, 0, '');
        InsertData(0, XPRICES, 60000, 'A1', XSalesShippednotInvoiced, false, 1, 0, '', false, '', XSALESAMT, 2, 0, 0, '');
        InsertData(0, XPRICES, 70000, 'A2', XSalesInvoiced, true, 1, 0, '', false, '', XSALESAMT, 2, 0, 0, '');
        InsertData(0, XPRICES, 80000, 'A3', XSalesTotal, false, 0, 0, 'A1+A2', false, '', '', 0, 0, 0, '');
        InsertData(0, XPRICES, 90000, 'A4', XSalesQuantity, false, 1, 0, '', true, '', XSALESQTY, 1, 0, 0, '');
        InsertData(0, XPRICES, 100000, 'A5', XAveragePrice, false, 0, 0, 'A3/A4', true, '', '', 0, 0, 0, '');
        InsertData(0, XPRICES, 110000, 'A6', XUnitPrice1, false, 1, 0, '', false, '', XUNITPRICE, 5, 0, 0, '');
        InsertData(0, XPRICES, 120000, 'A7', XDeviation, false, 0, 0, '(A6/A5+1)*100', false, '', '', 0, 0, 0, '');
        InsertData(0, XPROFIT, 130000, 'A1', XSalesTurnover, true, 1, 0, '', false, '', XSALESAMT, 2, 0, 0, '');
        InsertData(0, XPROFIT, 140000, 'A2', XCOGS, true, 1, 0, '', true, '', XCOGS, 3, 0, 0, '');
        InsertData(0, XPROFIT, 150000, 'A3', XGrossProfitMargin, false, 0, 0, 'A1+A2', false, '', '', 0, 0, 0, '');
        InsertData(0, XPROFIT, 160000, 'A4', XGrossProfitpercent, false, 0, 0, 'A3/A1*100', false, '', '', 0, 0, 0, '');
        InsertData(0, XSALES, 170000, 'A1', XSalesShippednotInvoiced, false, 1, 0, '', false, '', XSALESAMT, 2, 0, 0, '');
        InsertData(0, XSALES, 180000, 'A2', XSalesInvoiced, true, 1, 0, '', false, '', XSALESAMT, 2, 0, 0, '');
        InsertData(0, XSALES, 190000, 'B1', XSalescommaQuantity, false, 1, 0, '', true, '', XSALESQTY, 1, 0, 0, '');
        InsertData(0, XSALES, 200000, 'A3', XSalesTotal, false, 0, 0, 'A1+A2', false, '', '', 2, 0, 0, '');
        InsertData(0, XSALES, 210000, 'A4', XSalesLastY, true, 1, 0, '', false, '<-1Y>', XSALESAMT, 2, 0, 0, '');
        InsertData(0, XSALES, 220000, 'B2', XSalesLastYQuantity, false, 1, 0, '', true, '<-1Y>', XSALESQTY, 1, 0, 0, '');
        InsertData(0, XSALES, 230000, 'A5', XChangepercent, false, 0, 0, '100*(A3/A4-1)', false, '', '', 2, 0, 0, '');

        InsertData(2, XINVTTURN, 240000, 'A13', XAverageInventoryin12months, false, 0, 0, '(A1..A12)/12', false, '', '', 0, 0, 0, '');
        InsertData(2, XINVTTURN, 250000, 'A26', XTotalCOGSinlast12months, false, 0, 0, 'A15-A14', true, '', '', 0, 0, 0, '');
        InsertData(2, XINVTTURN, 260000, 'A27', XInventoryTurns, false, 0, 0, 'A26/A13', true, '', '', 0, 0, 0, '');
        InsertData(2, XINVTTURN, 270000, 'A1', X12MonthsAgo, false, 2, 0, '', false, '<CM-12M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 280000, 'A2', X11MonthsAgo, false, 2, 0, '', false, '<CM-11M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 290000, 'A3', X10MonthsAgo, false, 2, 0, '', false, '<CM-10M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 300000, 'A4', X9MonthsAgo, false, 2, 0, '', false, '<CM-9M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 310000, 'A5', X8MonthsAgo, false, 2, 0, '', false, '<CM-8M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 320000, 'A6', X7MonthsAgo, false, 2, 0, '', false, '<CM-7M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 330000, 'A7', X6MonthsAgo, false, 2, 0, '', false, '<CM-6M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 340000, 'A8', X5MonthsAgo, false, 2, 0, '', false, '<CM-5M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 350000, 'A9', X4MonthsAgo, false, 2, 0, '', false, '<CM-4M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 360000, 'A10', X3MonthsAgo, false, 2, 0, '', false, '<CM-3M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 370000, 'A11', X2MonthsAgo, false, 2, 0, '', false, '<CM-2M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 380000, 'A12', X1MonthAgo, false, 2, 0, '', false, '<CM-1M>', XInventory, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 390000, 'A14', XCOGSBalance12MonthsAgo, false, 3, 0, '', true, '<CM-13M>', XCOGS, 3, 1, 0, '');
        InsertData(2, XINVTTURN, 400000, 'A15', XCOGSBalancethisMonth, false, 2, 0, '', true, '<CM-1M>', XCOGS, 3, 1, 0, '');

        InsertData(2, XWIP, 410000, 'A1', XDirectCostCapacity, true, 2, 0, '', false, '', XDIRCOSTCAP, 3, 0, 0, '');
        InsertData(2, XWIP, 420000, 'A3', XConsumption, true, 2, 0, '', true, '', XCONSUMP, 3, 0, 0, '');
        InsertData(2, XWIP, 430000, 'A4', XWIPOutputExpected, false, 2, 0, '', false, '', XOUTPUT, 3, 0, 0, '');
        InsertData(2, XWIP, 440000, 'A5', XWIPOutputInvoiced, true, 2, 0, '', false, '', XOUTPUT, 3, 0, 0, '');
        InsertData(2, XWIP, 450000, 'A6', XWIPOutputTotal, false, 0, 0, 'A4+A5', false, '', '', 0, 0, 0, '');
        InsertData(2, XWIP, 460000, 'A7', XTotalWIP, false, 0, 0, 'A3+A6-A1', true, '', '', 0, 0, 0, '');
    end;

    var
        AnalysisColumn: Record "Analysis Column";
        XBUDGET: Label 'BUDGET';
        XPRICES: Label 'PRICES';
        XPROFIT: Label 'PROFIT';
        XSALES: Label 'SALES';
        XINVTTURN: Label 'INVT-TURN';
        XWIP: Label 'WIP';
        XSALESAMT: Label 'SALES-AMT';
        XSALESQTY: Label 'SALES-QTY';
        XUNITPRICE: Label 'UNIT-PRICE';
        XCOGS: Label 'COGS';
        XDIRCOSTCAP: Label 'DIRCOSTCAP';
        XCONSUMP: Label 'CONSUMP';
        XOUTPUT: Label 'OUTPUT';
        XTurnoverinactual: Label 'Turnover in Amount, actual';
        XTurnoverinQtyactual: Label 'Turnover in Qty, actual';
        XTurnoverinbudget: Label 'Turnover in Amount, budget';
        XTurnoverinQtybudget: Label 'Turnover in Qty, budget';
        XDeviation: Label 'Deviation %';
        XSalesShippednotInvoiced: Label 'Sales, Shipped not Invoiced';
        XSalesInvoiced: Label 'Sales, Invoiced';
        XSalesTotal: Label 'Sales, Total';
        XSalesQuantity: Label 'Sales Quantity';
        XAveragePrice: Label 'Average Price';
        XUnitPrice1: Label 'Unit Price';
        XSalesTurnover: Label 'Sales Turnover';
        XGrossProfitMargin: Label 'Gross Profit Margin';
        XGrossProfitpercent: Label 'Gross Profit %';
        XSalescommaQuantity: Label 'Sales, Quantity';
        XSalesLastY: Label 'Sales Last Y';
        XSalesLastYQuantity: Label 'Sales Last Y, Quantity';
        XChangepercent: Label 'Change %';
        XAverageInventoryin12months: Label 'Average Inventory in 12 months';
        XTotalCOGSinlast12months: Label 'Total COGS in last 12 months';
        XInventoryTurns: Label 'Inventory Turns';
        X12MonthsAgo: Label '12 Months Ago';
        X11MonthsAgo: Label '11 Months Ago';
        X10MonthsAgo: Label '10 Months Ago';
        X9MonthsAgo: Label '9 Months Ago';
        X8MonthsAgo: Label '8 Months Ago';
        X7MonthsAgo: Label '7 Months Ago';
        X6MonthsAgo: Label '6 Months Ago';
        X5MonthsAgo: Label '5 Months Ago';
        X4MonthsAgo: Label '4 Months Ago';
        X3MonthsAgo: Label '3 Months Ago';
        X2MonthsAgo: Label '2 Months Ago';
        X1MonthAgo: Label '1 Month Ago';
        XCOGSBalance12MonthsAgo: Label 'COGS Balance 12 Months Ago';
        XCOGSBalancethisMonth: Label 'COGS Balance this Month';
        XDirectCostCapacity: Label 'Direct Cost - Capacity';
        XConsumption: Label 'Consumption';
        XWIPOutputExpected: Label 'WIP Output - Expected';
        XWIPOutputInvoiced: Label 'WIP Output - Invoiced';
        XWIPOutputTotal: Label 'WIP Output Total';
        XTotalWIP: Label 'Total WIP';
        XInventory: Label 'Inventory';

    procedure InsertData(AnalysisArea: Option Sales,Purchase,Inventory; AnalysisColumnTemplate: Code[10]; LineNo: Integer; ColumnNo: Code[10]; ColumnHeader: Text[30]; Invoiced: Boolean; ColumnType: Option Formula,"Net Change","Balance at Date","Beginning Balance","Year to Date","Rest of Fiscal Year","Entire Fiscal Year"; LedgerEntryType: Option "Item Entries","Item Budget Entries"; Formula: Code[80]; ShowOppositeSign: Boolean; ComparisonDateFormula2: Text[30]; AnalysisTypeCode: Code[10]; ValueType: Option " ",Quantity,"Sales Amount","Cost Amount","Non-Invntble Amount","Unit Price","Standard Cost","Indirect Cost","Unit Cost"; Show: Option Always,Never,"When Positive","When Negative"; RoundingFactor: Option "None","1","1000","1000000"; ComparisonPeriodFormula: Code[20])
    var
        ComparisonDateFormula: DateFormula;
    begin
        Evaluate(ComparisonDateFormula, ComparisonDateFormula2);
        AnalysisColumn.Init();
        AnalysisColumn.Validate("Analysis Area", AnalysisArea);
        AnalysisColumn.Validate("Analysis Column Template", AnalysisColumnTemplate);
        AnalysisColumn.Validate("Line No.", LineNo);
        AnalysisColumn.Validate("Column No.", ColumnNo);
        AnalysisColumn.Validate("Column Header", ColumnHeader);
        AnalysisColumn.Validate("Column Type", ColumnType);
        AnalysisColumn.Validate("Ledger Entry Type", LedgerEntryType);
        AnalysisColumn.Validate(Formula, Formula);
        AnalysisColumn.Validate("Comparison Date Formula", ComparisonDateFormula);
        AnalysisColumn.Validate("Show Opposite Sign", ShowOppositeSign);
        AnalysisColumn.Validate(Show, Show);
        AnalysisColumn.Validate("Rounding Factor", RoundingFactor);
        AnalysisColumn.Validate("Comparison Period Formula", ComparisonPeriodFormula);
        AnalysisColumn.Validate("Analysis Type Code", AnalysisTypeCode);
        AnalysisColumn.Validate("Value Type", ValueType);
        AnalysisColumn.Validate(Invoiced, Invoiced);
        AnalysisColumn.Insert(true);
    end;
}

