codeunit 101085 "Create Acc. Schedule Line"
{

    trigger OnRun()
    begin
        InsertData(XCAMPAIGN, '', XCAMPAIGNANALYSIS, '', 0, '', '', '', '', false, true);
        InsertData(XCAMPAIGN, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XCAMPAIGN, '11', XSalesRetailDom, CA.Convert('996110'), 0, XSUMMER, '', '', '', true, false);
        InsertData(XCAMPAIGN, '12', XPurchRetailDom, CA.Convert('997110'), 0, XSUMMER, '', '', '', true, false);
        InsertData(XCAMPAIGN, '1', XTradingMarginDomestic, '-12-11', 2, '', '', '', '', false, true);
        InsertData(XCAMPAIGN, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XCAMPAIGN, '21', XSalesRetailEU, CA.Convert('996120'), 0, XSUMMER, '', '', '', true, false);
        InsertData(XCAMPAIGN, '22', XPurchRetailEU, CA.Convert('997120'), 0, XSUMMER, '', '', '', true, false);
        InsertData(XCAMPAIGN, '2', XTradingMarginEU, '-22-21', 2, '', '', '', '', false, true);
        InsertData(XCAMPAIGN, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XCAMPAIGN, '31', XSalesRetailExport, CA.Convert('996130'), 0, XSUMMER, '', '', '', true, false);
        InsertData(XCAMPAIGN, '32', XPurchRetailExport, CA.Convert('997130'), 0, XSUMMER, '', '', '', true, false);
        InsertData(XCAMPAIGN, '3', XTradingMarginExport, '-32-31', 2, '', '', '', '', false, true);
        InsertData(XCAMPAIGN, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XCAMPAIGN, '', XCampaignResult, '1+2+3', 2, '', '', '', '', false, true);

        InsertData(XREVENUE, '', XREVENUE, '', 0, '', '', '', '', false, true);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '', XSalesofRetail, '', 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '11', XSalesRetailDom, CA.Convert('996110'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '12', XSalesRetailEU, CA.Convert('996120'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '13', XSalesRetailExport, CA.Convert('996130'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '14', XJobSalesAdjmtRetail, CA.Convert('996190'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '15', XSalesofRetailTotal, CA.Convert('996195'), 1, '', '', '', '', false, false);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueArea10to30Total,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996195')), 0, '10..30', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueArea40to85Total,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996195')), 0, '40..85', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenuenoAreacodeTotal,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996195')), 0, '''''', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueTotal,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996195')), 0, '', '', '', '', false, true);

        InsertData(XCASTAFF, '10', XPersonalCosts, '', 6, '', '', '', '', false, false);
        InsertData(XCASTAFF, '20', XMonthlySalaries, CA.Convert('998710') + '..' + CA.Convert('998720'), 6, '', '', '', '', false, false);
        InsertData(XCASTAFF, '40', XSocialSecurity, CA.Convert('998730') + '..' + CA.Convert('998730'), 6, '', '', '', '', false, false);

        InsertData(XCATRANSFER, '100', XTransferOverheadCosts, '', 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '200', XInitialCostCenters, '9901', 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '300', XMainCostCenters, '9902', 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '500', XTotalTransfers, '200..300', 2, '', '', '', '', false, false);

        InsertData(XCAPROF, '100', XCCCOSummaryReport, '', 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '110', XRevenues, CA.Convert('996110') + '..' + CA.Convert('996955'), 7, '', '', '', '', false, false);
        InsertData(XCAPROF, '120', XRevenueReductions, CA.Convert('996710') + '..' + CA.Convert('996910'), 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '130', XNetRevenue, '110..120', 2, '', '', '', '', false, false);
        InsertData(XCAPROF, '140', XMaterialCosts, CA.Convert('997110') + '..' + CA.Convert('997894'), 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '160', XGrossProfit, '130..150', 2, '', '', '', '', false, false);
        InsertData(XCAPROF, '170', XSalaryDirectCosts, CA.Convert('998790'), 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '300', XMainCostCenters, '9902', 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '500', XTotalTransfers, '200..300', 2, '', '', '', '', false, false);

        // NAVCZ
        CreateBalanceSheet();
        CreateIncomeStatement();
        // NAVCZ

        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), '', XCalculationBase, '', false, true, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'R10', XCashFlowFunds, '2100', false, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'R20', XMonetarycurrentAssets, '0010|0030|0040|0060|2100', false, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'R30', XCurrentAssets, '0010..0070|2100', false, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'R40', XShortTermObligations, '1010..1100', false, false, false, false, true);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), '', '', '', false, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'L1', XCashFlow1Degree, 'R10/R40', true, true, false, false, true);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'L2', XCashFlow2Degree, 'R20/R40', true, true, false, false, true);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'L3', XCashFlow3Degree, 'R30/R40', true, true, false, false, true);

        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'R20', XMonetarycurrentAssets, '0010|0030|0040|0060|2100', false, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'R30', XCurrentAssets, '0010..0070|2100', false, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'R40', XShortTermObligations, '1010..1100', false, false, false, false, true);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), '', '', '', false, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'L1', XCashFlow1Degree, 'R10/R40', true, true, false, false, true);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'L2', XCashFlow2Degree, 'R20/R40', true, true, false, false, true);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XDEGREE'), 'L3', XCashFlow3Degree, 'R30/R40', true, true, false, false, true);

        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XReceivables, '0010', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XOpenSalesOrders, '0020', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XOpenServiceOrders, '0080', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XRentals, '0030', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XFinancialAssets, '0040', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XFixedAssetsDisposals, '0050', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XPrivateInvestments, '0060', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XMiscellaneousReceipts, '0070', true, false, false, true, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R20', XTotalofCashReceipts, 'R10', true, true, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XPayables, '1010', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XOpenPurchaseOrders, '1020', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XPersonnelCosts, '1030', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XRunningCosts, '1040', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XFinanceCosts, '1050', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XMiscellaneousCosts, '1060', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XInvestments, '1070', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XEncashmentOfBills, '1080', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XPrivateConsumptions, '1090', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XVATDue, '1100', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XOtherExpenses, '1110', true, false, false, true, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R40', XTotalOfCashDisbursements, 'R30', true, true, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R50', XSurplus, 'R10|R40', true, true, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R60', XCashFlowFunds, '2100', true, false, false, true, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R70', XTotalCashFlow, 'R50|R60', true, true, false, false, false);
    end;

    var
        "Line No.": Integer;
        "Previous Schedule Name": Code[10];
        CA: Codeunit "Make Adjustments";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        CreateColumnLayoutName: Codeunit "Create Column Layout Name";
        GLAccountCategory: Record "G/L Account Category";
        XANALYSIS: Label 'ANALYSIS';
        XACIDTESTANALYSIS: Label 'ACID-TEST ANALYSIS';
        XCurrentAssets: Label 'Current Assets';
        XInventory: Label 'Inventory';
        XAccountsReceivable: Label 'Accounts Receivable';
        XSecurities: Label 'Securities';
        XLiquidAssets: Label 'Liquid Assets';
        XCurrentAssetsTotal: Label 'Current Assets, Total';
        XShorttermLiabilities: Label 'Short-term Liabilities';
        XRevolvingCredit: Label 'Revolving Credit';
        XAccountsPayable: Label 'Accounts Payable';
        XPersonnelrelatedItems: Label 'Personnel-related Items';
        XOtherLiabilities: Label 'Other Liabilities';
        XShorttermLiabilitiesTotal: Label 'Short-term Liabilities, Total';
        XCurAminusShorttermLiabilities: Label 'Current Assets minus Short-term Liabilities';
        XCAMPAIGNANALYSIS: Label 'CAMPAIGN ANALYSIS';
        XSalesRetailDom: Label 'Sales, Retail - Dom.';
        XPurchRetailDom: Label 'Purch, Retail - Dom.';
        XTradingMarginDomestic: Label 'Trading Margin, Domestic';
        XSalesRetailEU: Label 'Sales, Retail - EU';
        XPurchRetailEU: Label 'Purch, Retail - EU';
        XTradingMarginEU: Label 'Trading Margin, EU';
        XSalesRetailExport: Label 'Sales, Retail - Export';
        XPurchRetailExport: Label 'Purch, Retail - Export';
        XTradingMarginExport: Label 'Trading Margin, Export';
        XCampaignResult: Label 'Campaign Result';
        XSurplus: Label 'Surplus';
        XOpenSalesOrders: Label 'Open Sales Orders';
        XRentals: Label 'Rentals';
        XFinancialAssets: Label 'Financial Assets';
        XFixedAssetsDisposals: Label 'Fixed Assets Disposals';
        XPrivateInvestments: Label 'Private Investments';
        XMiscellaneousReceipts: Label 'Miscellaneous receipts';
        XOpenServiceOrders: Label 'Open service orders';
        XPayables: Label 'Payables';
        XPersonnelCosts: Label 'Personnel costs';
        XRunningCosts: Label 'Running costs';
        XFinanceCosts: Label 'Finance Costs';
        XInvestments: Label 'Investments';
        XEncashmentOfBills: Label 'Encashment of Bills';
        XPrivateConsumptions: Label 'Private Consumptions';
        XVATDue: Label 'VAT Due';
        XOtherExpenses: Label 'Other expenses';
        XTotalOfCashDisbursements: Label 'Total of Cash Disbursements';
        XCashFlowFunds: Label 'CashFlow Funds';
        XTotalCashFlow: Label 'Total Cash Flow';
        XReceivables: Label 'Receivables';
        XTotalofCashReceipts: Label 'Total of Cash Receipts';
        XOpenPurchaseOrders: Label 'Open Purchase Orders';
        XMiscellaneousCosts: Label 'Miscellaneous costs';
        XCalculationBase: Label 'Calculation Base';
        XMonetarycurrentAssets: Label 'Monetary current assets';
        XShortTermObligations: Label 'Short-term obligations';
        XCashFlow1Degree: Label 'CashFlow 1. Degree';
        XCashFlow2Degree: Label 'CashFlow 2. Degree';
        XCashFlow3Degree: Label 'CashFlow 3. Degree';
        XREVENUE: Label 'REVENUE';
        XSalesofRetail: Label 'Sales of Retail';
        XJobSalesAdjmtRetail: Label 'Job Sales Adjmt, Retail';
        XSalesofRetailTotal: Label 'Sales of Retail, Total';
        XRevenueArea10to30Total: Label 'Revenue Area 10..30, Total';
        XRevenueArea40to85Total: Label 'Revenue Area 40..85, Total';
        XRevenuenoAreacodeTotal: Label 'Revenue, no Area code, Total';
        XRevenueTotal: Label 'Revenue, Total';
        XCAMPAIGN: Label 'CAMPAIGN';
        XVAT: Label 'VAT';
        XSUMMER: Label 'SUMMER';
        XCASTAFF: Label 'CA-STAFF', Comment = 'Cost Acct. Personnel Costs.';
        XCATRANSFER: Label 'CA-TRANS', Comment = 'Cost Acct. Transfer.';
        XCAPROF: Label 'CA-PROF', Comment = 'Cost Acct. Summary Record DB per CC/CO.';
        XPersonalCosts: Label 'Personnel Costs';
        XMonthlySalaries: Label 'Monthly Salaries';
        XSocialSecurity: Label 'Social Security';
        XTransferOverheadCosts: Label 'Transfer Overhead Costs';
        XInitialCostCenters: Label 'Initial Cost Centers';
        XTotalTransfers: Label 'Total Transfers';
        XCCCOSummaryReport: Label 'CC / CO Summary Report';
        XRevenues: Label 'Revenues';
        XRevenueReductions: Label 'Revenue Reductions';
        XNetRevenue: Label 'Net Revenue';
        XMaterialCosts: Label 'Material Costs';
        XGrossProfit: Label 'Gross Profit';
        XSalaryDirectCosts: Label 'Salary Direct Costs';
        XMainCostCenters: Label 'Main Cost Centers';
        XACCCAT: Label 'ACC-CAT', Comment = 'ACC-CAT is the name of the Account Schedule.';
        XBALSHEET: Label 'BALANCE SHEET';
        XIncomeThisYear: Label 'Income This Year';
        XIncomeStatement: Label 'INCOME STATEMENT';
        XNetIncome: Label 'NET INCOME';

    procedure InsertEvaluationData();
    var
        AssetsTxt: Text[80];
        LiabilitiesTxt: Text[80];
        EquityTxt: Text[80];
        IncomeTxt: Text[80];
        CostOfGoodsSoldTxt: Text[80];
        ExpenseTxt: Text[80];
    begin
        AssetsTxt := Format(GLAccountCategory."Account Category"::Assets, 80);
        LiabilitiesTxt := Format(GLAccountCategory."Account Category"::Liabilities, 80);
        EquityTxt := Format(GLAccountCategory."Account Category"::Equity, 80);
        IncomeTxt := Format(GLAccountCategory."Account Category"::Income, 80);
        CostOfGoodsSoldTxt := Format(GLAccountCategory."Account Category"::"Cost of Goods Sold", 80);
        ExpenseTxt := Format(GLAccountCategory."Account Category"::Expense, 80);

        InsertData(XACCCAT, '1000', XBALSHEET, '', 0, '', '', '', '', false, true);
        InsertData(XACCCAT, '1010', '', '', 0, '', '', '', '', false, false);
        InsertData(XACCCAT, '2000', uppercase(AssetsTxt), GLAccCatTotaling(GLAccountCategory."Account Category"::Assets, AssetsTxt), 10, '', '', '', '', false, true);
        InsertData(XACCCAT, '3000', LiabilitiesTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Liabilities, LiabilitiesTxt), 10, '', '', '', '', false, false);
        InsertData(XACCCAT, '4000', EquityTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Equity, EquityTxt), 10, '', '', '', '', false, false);
        InsertData(XACCCAT, '4010', XIncomeThisYear, CA.Convert('999999'), 1, '', '', '', '', false, false);
        InsertData(XACCCAT, '5000', uppercase(LiabilitiesTxt), '3000..4010', 2, '', '', '', '', false, true);
        InsertData(XACCCAT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XACCCAT, '6000', XIncomeStatement, '', 0, '', '', '', '', false, true);
        InsertData(XACCCAT, '7000', IncomeTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Income, IncomeTxt), 10, '', '', '', '', false, false);
        InsertData(XACCCAT, '8000', CostOfGoodsSoldTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::"Cost of Goods Sold", CostOfGoodsSoldTxt), 10, '', '', '', '', false, false);
        InsertData(XACCCAT, '9000', ExpenseTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Expense, ExpenseTxt), 10, '', '', '', '', false, false);
        InsertData(XACCCAT, '9900', XNetIncome, '7000..9000', 2, '', '', '', '', false, true);

        InsertData(XANALYSIS, '', XACIDTESTANALYSIS, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', XCurrentAssets, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '101', XInventory, CA.Convert('992190'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '102', XAccountsReceivable, CA.Convert('992390'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '103', XSecurities, CA.Convert('992890'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '104', XLiquidAssets, CA.Convert('992990'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '105', XCurrentAssetsTotal, '101..104', 2, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', XShorttermLiabilities, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '111', XRevolvingCredit, CA.Convert('995310'), 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '112', XAccountsPayable, CA.Convert('995490'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '113', XVAT, CA.Convert('995790'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '114', XPersonnelrelatedItems, CA.Convert('995890'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '115', XOtherLiabilities, CA.Convert('995990'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '116', XShorttermLiabilitiesTotal, '111..115', 2, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', XCurAminusShorttermLiabilities, '105|116', 2, '', '', '', '', false, false);

        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XReceivables, '1-RECEIVABLES', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XOpenSalesOrders, '6-SALES ORDERS', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XOpenServiceOrders, '10-SERVICE ORDERS', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XRentals, '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XFinancialAssets, '8-FIXED ASSETS BUDGE', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XFixedAssetsDisposals, '9-FIXED ASSETS DISPO', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XPrivateInvestments, '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R10', XMiscellaneousReceipts, '5-CASH FLOW MANUAL R', true, false, false, true, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R20', XTotalofCashReceipts, 'R10', true, true, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XPayables, '2-PAYABLES', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XOpenPurchaseOrders, '7-PURCHASE ORDERS', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XPersonnelCosts, '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XRunningCosts, '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XFinanceCosts, '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XMiscellaneousCosts, '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XInvestments, '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XEncashmentOfBills, '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XPrivateConsumptions, '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XVATDue, '15-TAX', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R30', XOtherExpenses, '4-CASH FLOW MANUAL E', true, false, false, true, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R40', XTotalOfCashDisbursements, 'R30', true, true, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R50', XSurplus, 'R10|R40', true, true, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R60', XCashFlowFunds, '3-LIQUID FUNDS', true, false, false, true, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          CreateColumnLayoutName.GetColumnLayoutName('XCASHFLOW'), 'R70', XTotalCashFlow, 'R50|R60', true, true, false, false, false);

        InsertData(XREVENUE, '', XREVENUE, '', 0, '', '', '', '', false, true);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '', XSalesofRetail, '', 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '11', XSalesRetailDom, CA.Convert('996110'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '12', XSalesRetailEU, CA.Convert('996120'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '13', XSalesRetailExport, CA.Convert('996130'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '14', XJobSalesAdjmtRetail, CA.Convert('996190'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '15', XSalesofRetailTotal, CA.Convert('996195'), 1, '', '', '', '', false, false);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueArea10to30Total,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996195')), 0, '10..30', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueArea40to85Total,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996195')), 0, '40..85', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenuenoAreacodeTotal,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996195')), 0, '''''', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueTotal,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996195')), 0, '', '', '', '', false, true);
    end;

    local procedure GLAccCatTotaling(Category: Option; Description: Text): Text[80]
    begin
        exit(Format(GLAccountCategoryMgt.GetSubcategoryEntryNo(Category, Description), 80));
    end;

    local procedure InsertDataForCashFlow(ScheduleName: Code[10]; RowNo: Code[10]; Description: Text[80]; Totaling: Text[80]; Show: Boolean; Bold: Boolean; Italic: Boolean; Underline: Boolean; ShowOppositeSign: Boolean)
    var
        CFAccSchedLine: Record "Acc. Schedule Line";
        TotalingType: Integer;
    begin
        if Bold then
            TotalingType := CFAccSchedLine."Totaling Type"::Formula.AsInteger()
        else
            TotalingType := CFAccSchedLine."Totaling Type"::"Cash Flow Entry Accounts".AsInteger();

        InsertData(ScheduleName, RowNo, Description, Totaling, TotalingType, '', '', '', '', ShowOppositeSign, Bold);

        CFAccSchedLine.Get(ScheduleName, "Line No.");
        CFAccSchedLine.Validate(Italic, Italic);
        CFAccSchedLine.Validate(Underline, Underline);
        CFAccSchedLine.Validate("New Page", false);
        if Show then
            CFAccSchedLine.Validate(Show, CFAccSchedLine.Show::Yes)
        else
            CFAccSchedLine.Validate(Show, CFAccSchedLine.Show::No);

        CFAccSchedLine.Modify();
    end;

    procedure InsertData("Schedule Name": Code[10]; "Row No.": Code[10]; Description: Text[80]; Totaling: Text[80]; "Totaling Type": Option; Dim1Totaling: Text[80]; Dim2Totaling: Text[80]; Dim3Totaling: Text[80]; Dim4Totaling: Text[80]; ShowOppositeSign: Boolean; Bold: Boolean)
    var
        "Acc. Schedule Line": Record "Acc. Schedule Line";
    begin
        "Acc. Schedule Line".Init();
        "Acc. Schedule Line".Validate("Schedule Name", "Schedule Name");
        if "Previous Schedule Name" <> "Schedule Name" then begin
            "Line No." := 10000;
            "Previous Schedule Name" := "Schedule Name";
        end else
            "Line No." := "Line No." + 10000;
        "Acc. Schedule Line".Validate("Line No.", "Line No.");
        "Acc. Schedule Line".Validate("Row No.", "Row No.");
        "Acc. Schedule Line".Validate(Description, Description);
        // NAVCZ
        "Acc. Schedule Line".Totaling := Totaling;
        "Acc. Schedule Line"."Totaling Type" := "Acc. Schedule Line Totaling Type".FromInteger("Totaling Type");
        // NAVCZ
        "Acc. Schedule Line".Validate("Dimension 1 Totaling", Dim1Totaling);
        "Acc. Schedule Line".Validate("Dimension 2 Totaling", Dim2Totaling);
        "Acc. Schedule Line".Validate("Dimension 3 Totaling", Dim3Totaling);
        "Acc. Schedule Line".Validate("Dimension 4 Totaling", Dim4Totaling);
        "Acc. Schedule Line"."Show Opposite Sign" := ShowOppositeSign;
        "Acc. Schedule Line".Bold := Bold;

        // NAVCZ
        if "Schedule Name" = CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT') then
            case "Row No." of
                '123', '137':
                    "Acc. Schedule Line".Show := "Acc. Schedule Line".Show::"When Negative Balance";
                '051', '063', '064A', '064B', '064C', '064D':
                    "Acc. Schedule Line"."Calc CZL" := "Acc. Schedule Line"."Calc CZL"::"When Positive";
                '121', '140', '141A', '141B', '141C', '141D':
                    "Acc. Schedule Line"."Calc CZL" := "Acc. Schedule Line"."Calc CZL"::"When Negative";
            end;
        // NAVCZ
        "Acc. Schedule Line".Insert();
    end;

    procedure InsertMiniAppData(ScheduleName: Code[10]; RowNo: Code[10]; Description: Text[80]; Totaling: Text[250]; TotalingType: Enum "Acc. Schedule Line Totaling Type"; RowType: Option; ShowOppositeSign: Boolean)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        LineNo: Integer;
    begin
        AccScheduleLine.SetRange("Schedule Name", ScheduleName);
        if AccScheduleLine.FindLast() then
            LineNo := AccScheduleLine."Line No." + 10000
        else
            LineNo := 10000;

        AccScheduleLine.Init();
        AccScheduleLine.Validate("Schedule Name", ScheduleName);
        AccScheduleLine.Validate("Line No.", LineNo);
        AccScheduleLine.Validate("Row No.", RowNo);
        AccScheduleLine.Validate(Description, Description);
        AccScheduleLine."Totaling Type" := TotalingType;
        AccScheduleLine.Totaling := Totaling;
        AccScheduleLine.Validate("Row Type", RowType);
        AccScheduleLine.Validate("Show Opposite Sign", ShowOppositeSign);
        AccScheduleLine.Insert();

        // Insert "empty" line for applying Acc. Sched. Chart Setup Line throug Rapid Start
        if AccScheduleLine.Get('', LineNo) then
            exit;
        AccScheduleLine.Init();
        AccScheduleLine.Validate("Schedule Name", '');
        AccScheduleLine.Validate("Line No.", LineNo);
        AccScheduleLine.Insert();
    end;

    procedure InsertMiniAppDataFormula(ScheduleName: Code[10]; RowNo: Code[10]; Description: Text[80]; Totaling: Text[250]; TotalingType: Enum "Acc. Schedule Line Totaling Type"; RowType: Option; ShowOppositeSign: Boolean; HideCurrencySymbol: Boolean)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        LineNo: Integer;
    begin
        AccScheduleLine.SetRange("Schedule Name", ScheduleName);
        if AccScheduleLine.FindLast() then
            LineNo := AccScheduleLine."Line No." + 10000
        else
            LineNo := 10000;

        AccScheduleLine.Init();
        AccScheduleLine.Validate("Schedule Name", ScheduleName);
        AccScheduleLine.Validate("Line No.", LineNo);
        AccScheduleLine.Validate("Row No.", RowNo);
        AccScheduleLine.Validate(Description, Description);
        AccScheduleLine."Totaling Type" := TotalingType;
        AccScheduleLine.Totaling := Totaling;
        AccScheduleLine.Validate("Row Type", RowType);
        AccScheduleLine.Validate("Show Opposite Sign", ShowOppositeSign);
        AccScheduleLine.Validate("Hide Currency Symbol", HideCurrencySymbol);
        AccScheduleLine.Insert();

        // Insert "empty" line for applying Acc. Sched. Chart Setup Line throug Rapid Start
        if AccScheduleLine.Get('', LineNo) then
            exit;
        AccScheduleLine.Init();
        AccScheduleLine.Validate("Schedule Name", '');
        AccScheduleLine.Validate("Line No.", LineNo);
        AccScheduleLine.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        // NAVCZ
        CreateBalanceSheet();
        CreateIncomeStatement();
    end;

    local procedure CreateBalanceSheet()
    begin
        // NAVCZ
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '001', 'AKTIVA CELKEM (02 + 03 + 37 + 78)', '002|003|037|078', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '001K', 'Aktiva celkem - korekce', '002K|003K|037K|078K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '001N', 'Aktiva celkem - netto', '002N|003N|037N|078N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '002', 'A. Pohledávky za upsaný základní kapitál', '353*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '002K', 'A. Pohledávky za upsaný základní kapitál - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '002N', 'A. Pohledávky za upsaný základní kapitál - netto', '002|002K', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '003', 'B. Stálá aktiva (04 + 14 + 27)', '004|014|027', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '003K', 'B. Stálá aktiva - korekce', '004K|014K|027K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '003N', 'B. Stálá aktiva - netto', '004N|014N|027N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '004', 'B.I. Dlouhodobý nehmotný majetek (05 + 06 + 09 až 11)', '005|006|009|010|011', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '004K', 'B.I. Dlouhodobý nehmotný majetek - korekce', '005K|006K|009K|010K|011K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '004N', 'B.I. Dlouhodobý nehmotný majetek - netto', '005N|006N|009N|010N|011N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '005', 'B.I.1. Nehmotné výsledky výzkumu a vývoje', '012*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '005K', 'B.I.1. Nehmotné výsledky výzkumu a vývoje - korekce', '072*|091A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '005N', 'B.I.1. Nehmotné výsledky výzkumu a vývoje - netto', '005|005K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '006', 'B.I.2. Ocenitelná práva (07 + 08)', '007|008', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '006K', 'B.I.2. Ocenitelná práva - korekce', '007K|008K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '006N', 'B.I.2. Ocenitelná práva - netto', '007N|008N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '007', 'B.I.2.1. Software', '013*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '007K', 'B.I.2.1. Software - korekce', '073*|091A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '007N', 'B.I.2.1. Software - netto', '007|007K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '008', 'B.I.2.2. Ostatní ocenitelná práva', '014*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '008K', 'B.I.2.2. Ostatní ocenitelná práva - korekce', '074*|091A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '008N', 'B.I.2.2. Ostatní ocenitelná práva - netto', '008|008K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '009', 'B.I.3. Goodwill', '015*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '009K', 'B.I.3. Goodwill - korekce', '075*|091A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '009N', 'B.I.3. Goodwill - netto', '009|009K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '010', 'B.I.4. Ostatní dlouhodobý nehmotný majetek', '019*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '010K', 'B.I.4. Ostatní dlouhodobý nehmotný majetek - korekce', '079*|091A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '010N', 'B.I.4. Ostatní dlouhodobý nehmotný majetek - netto', '010|010K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '011', 'B.I.5. Poskytnuté zálohy na dl.nehm.maj a nedok.dl.nehm.maj. (12 + 13)', '012|013', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '011K', 'B.I.5. Poskytnuté zálohy na dl.nehm.maj a nedok.dl.nehm.maj. - korekce', '012K|013K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '011N', 'B.I.5. Poskytnuté zálohy na dl.nehm.maj a nedok.dl.nehm.maj. - netto', '012N|013N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '012', 'B.I.5.1 Poskytnuté zálohy na dlouhodobý nehmotný majetek', '051*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '012K', 'B.I.5.1. Poskytnuté zálohy na dlouhodobý nehmotný majetek - korekce', '095A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '012N', 'B.I.5.1. Poskytnuté zálohy na dlouhodobý nehmotný majetek - netto', '012|012K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '013', 'B.I.5.2. Nedokončený dlouhodobý nehmotný majetek', '041*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '013K', 'B.I.5.2. Nedokončený dlouhodobý nehmotný majetek - korekce', '093*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '013N', 'B.I.5.2. Nedokončený dlouhodobý nehmotný majetek - netto', '013|013K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '014', 'B.II. Dlouhodobý hmotný majetek (15 + 18 až 20 + 24)', '015|018|019|020|024', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '014K', 'B.II. Dlouhodobý hmotný majetek - korekce', '015K|018K|019K|020K|024K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '014N', 'B.II. Dlouhodobý hmotný majetek - netto', '015N|018N|019N|020N|024N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '015', 'B.II.1. Pozemky a stavby (16 + 17)', '016|017', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '015K', 'B.II.1. Pozemky a stavby - korekce', '016K|017K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '015N', 'B.II.1. Pozemky a stavby - netto', '016N|017N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '016', 'B.II.1.1. Pozemky', '031*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '016K', 'B.II.1.1. Pozemky - korekce', '092A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '016N', 'B.II.1.1. Pozemky - netto', '016|016K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '017', 'B.II.1.2. Stavby', '021*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '017K', 'B.II.1.2. Stavby - korekce', '081*|092A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '017N', 'B.II.1.2. Stavby - netto', '017|017K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '018', 'B.II.2. Hmotné movité věci a jejich soubory', '022*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '018K', 'B.II.2. Hmotné movité věci a jejich soubory - korekce', '082*|092A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '018N', 'B.II.2. Hmotné movité věci a jejich soubory - netto', '018|018K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '019', 'B.II.3. Oceňovací rozdíl k nabytému majetku', '097*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '019K', 'B.II.3. Oceňovací rozdíl k nabytému majetku - korekce', '098*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '019N', 'B.II.3. Oceňovací rozdíl k nabytému majetku - netto', '019|019K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '020', 'B.II.4. Ostatní dlouhodobý hmotný majetek (21 + 22 + 23)', '021|022|023', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '020K', 'B.II.4. Ostatní dlouhodobý hmotný majetek - korekce', '021K|022K|023K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '020N', 'B.II.4. Ostatní dlouhodobý hmotný majetek - netto', '021N|022N|023N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '021', 'B.II.4.1. Pěstitelské celky trvalých porostů', '025*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '021K', 'B.II.4.1. Pěstitelské celky trvalých porostů - korekce', '085*|092A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '021N', 'B.II.4.1. Pěstitelské celky trvalých porostů - netto', '021|021K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '022', 'B.II.4.2. Dospělá zvířata a jejich skupiny', '026*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '022K', 'B.II.4.2. Dospělá zvířata a jejich skupiny - korekce', '086*|092A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '022N', 'B.II.4.2. Dospělá zvířata a jejich skupiny - netto', '022|022K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '023', 'B.II.4.3. Jiný dlouhodobý hmotný majetek', '029*|032*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '023K', 'B.II.4.3. Jiný dlouhodobý hmotný majetek - korekce', '089*|092A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '023N', 'B.II.4.3. Jiný dlouhodobý hmotný majetek - netto', '023|023K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '024', 'B.II.5. Poskytnuté zálohy na dl.hm.maj. a nedok.dl.hm.maj. (25 + 26)', '025|026', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '024K', 'B.II.5. Poskytnuté zálohy na dl.hm.maj. a nedok.dl.hm.maj. - korekce', '025K|026K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '024N', 'B.II.5. Poskytnuté zálohy na dl.hm.maj. a nedok.dl.hm.maj. - netto', '025N|026N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '025', 'B.II.5.1. Poskytnuté zálohy na dlouhodobý hmotný majetek', '052*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '025K', 'B.II.5.1. Poskytnuté zálohy na dlouhodobý hmotný majetek - korekce', '095A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '025N', 'B.II.5.1. Poskytnuté zálohy na dlouhodobý hmotný majetek - netto', '025|025K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '026', 'B.II.5.2. Nedokončený dlouhodobý hmotný majetek', '042*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '026K', 'B.II.5.2. Nedokončený dlouhodobý hmotný majetek - korekce', '094*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '026N', 'B.II.5.2. Nedokončený dlouhodobý hmotný majetek - netto', '026|026K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '027', 'B.III. Dlouhodobý finanční majetek (28 až 34)', '028|029|030|031|032|033|034', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '027K', 'B.III. Dlouhodobý finanční majetek - korekce', '028K|029K|030K|031K|032K|033K|034K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '027N', 'B.III. Dlouhodobý finanční majetek - netto', '028N|029N|030N|031N|032N|033N|034N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '028', 'B.III.1. Podíly - ovládaná osoba nebo ovládající osoba', '061*|043A|064A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '028K', 'B.III.1. Podíly - ovládaná osoba nebo ovládající osoba - korekce', '096A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '028N', 'B.III.1. Podíly - ovládaná osoba nebo ovládající osoba - netto', '028|028K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '029', 'B.III.2. Zápůjčky a úvěry - ovládaná nebo ovládající osoba', '066*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '029K', 'B.III.2. Zápůjčky a úvěry - ovládaná nebo ovládající osoba - korekce', '096A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '029N', 'B.III.2. Zápůjčky a úvěry - ovládaná nebo ovládající osoba - netto', '029|029K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '030', 'B.III.3. Podíly - podstatný vliv', '062*|043A|064A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '030K', 'B.III.3. Podíly - podstatný vliv - korekce', '096A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '030N', 'B.III.3. Podíly - podstatný vliv - netto', '030|030K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '031', 'B.III.4. Zápůjčky a úvěry - podstatný vliv', '067*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '031K', 'B.III.4. Zápůjčky a úvěry - podstatný vliv - korekce', '096A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '031N', 'B.III.4. Zápůjčky a úvěry - podstatný vliv - netto', '031|031K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '032', 'B.III.5. Ostatní dlouhodobé cenné papíry a podíly', '063*|065*|043A|064A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '032K', 'B.III.5. Ostatní dlouhodobé cenné papíry a podíly - korekce', '096A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '032N', 'B.III.5. Ostatní dlouhodobé cenné papíry a podíly - netto', '032|032K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '033', 'B.III.6. Zápůjčky a úvěry - ostatní', '068*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '033K', 'B.III.6. Zápůjčky a úvěry - ostatní - korekce', '096A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '033N', 'B.III.6. Zápůjčky a úvěry - ostatní - netto', '033|033K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '034', 'B.III.7. Ostatní dlouhodobý finanční majetek (35 + 36)', '035|036', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '034K', 'B.III.7. Ostatní dlouhodobý finanční majetek - korekce', '035K|036K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '034N', 'B.III.7. Ostatní dlouhodobý finanční majetek - netto', '035N|036N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '035', 'B.III.7.1. Jiný dlouhodobý finanční majetek', '069*|043A|064A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '035K', 'B.III.7.1. Jiný dlouhodobý finanční majetek - korekce', '096A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '035N', 'B.III.7.1. Jiný dlouhodobý finanční majetek - netto', '035|035K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '036', 'B.III.7.2. Poskytnuté zálohy na dlouhodobý finanční majetek', '053*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '036K', 'B.III.7.2. Poskytnuté zálohy na dlouhodobý finanční majetek - korekce', '095A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '036N', 'B.III.7.2. Poskytnuté zálohy na dlouhodobý finanční majetek - netto', '036|036K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '037', 'C. Oběžná aktiva (38 + 46 + 72 + 75)', '038|046|072|075', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '037K', 'C. Oběžná aktiva - korekce', '038K|046K|072K|075K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '037N', 'C. Oběžná aktiva - netto', '038N|046N|072N|075N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '038', 'C.I. Zásoby (39 + 40 + 41 + 44 +45)', '039|040|041|044|045', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '038K', 'C.I. Zásoby - korekce', '039K|040K|041K|044K|045K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '038N', 'C.I. Zásoby - netto', '039N|040N|041N|044N|045N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '039', 'C.I.1. Materiál', '111*|112*|119*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '039K', 'C.I.1. Materiál - korekce', '191*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '039N', 'C.I.1. Materiál - netto', '039|039K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '040', 'C.I.2. Nedokončená výroba a polotovary', '121*|122*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '040K', 'C.I.2. Nedokončená výroba a polotovary - korekce', '192*|193*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '040N', 'C.I.2. Nedokončená výroba a polotovary - netto', '040|040K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '041', 'C.I.3. Výrobky a zboží (42 + 43)', '042|043', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '041K', 'C.I.3. Výrobky a zboží - korekce', '042K|043K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '041N', 'C.I.3. Výrobky a zboží - netto', '042N|043N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '042', 'C.I.3.1. Výrobky', '123*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '042K', 'C.I.3.1. Výrobky - korekce', '194*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '042N', 'C.I.3.1. Výrobky - netto', '042|042K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '043', 'C.I.3.2. Zboží', '131*|132*|139*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '043K', 'C.I.3.2. Zboží - korekce', '196*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '043N', 'C.I.3.2. Zboží - netto', '043|043K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '044', 'C.I.4. Mladá a ostatní zvířata a jejich skupiny', '124*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '044K', 'C.I.4. Mladá a ostatní zvířata a jejich skupiny - korekce', '195*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '044N', 'C.I.4. Mladá a ostatní zvířata a jejich skupiny - netto', '044|044K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '045', 'C.I.5. Poskytnuté zálohy na zásoby', '151*|152*|153*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '045K', 'C.I.5. Poskytnuté zálohy na zásoby - korekce', '197*|198*|199*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '045N', 'C.I.5. Poskytnuté zálohy na zásoby - netto', '045|045K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '046', 'C.II. Pohledávky (47 + 57 + 68)', '047|057|068', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '046K', 'C.II. Pohledávky - korekce', '047K|057K|068K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '046N', 'C.II. Pohledávky - netto', '047N|057N|068N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '047', 'C.II.1. Dlouhodobé pohledávky (48 až 52)', '048|049|050|051|052', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '047K', 'C.II.1. Dlouhodobé pohledávky - korekce', '048K|049K|050K|051K|052K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '047N', 'C.II.1. Dlouhodobé pohledávky - netto', '048N|049N|050N|051N|052N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '048', 'C.II.1.1. Pohledávky z obchodních vztahů', '311A|313A|315A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '048K', 'C.II.1.1. Pohledávky z obchodních vztahů - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '048N', 'C.II.1.1. Pohledávky z obchodních vztahů - netto', '048|048K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '049', 'C.II.1.2. Pohledávky - ovládaná nebo ovládající osoba', '351A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '049K', 'C.II.1.2. Pohledávky - ovládaná nebo ovládající osoba - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '049N', 'C.II.1.2. Pohledávky - ovládaná nebo ovládající osoba - netto', '049|049K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '050', 'C.II.1.3. Pohledávky - podstatný vliv', '352A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '050K', 'C.II.1.3. Pohledávky - podstatný vliv - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '050N', 'C.II.1.3. Pohledávky - podstatný vliv - netto', '050|050K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '051', 'C.II.1.4. Odložená daňová pohledávka', '481*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '051K', 'C.II.1.4. Odložená daňová pohledávka - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '051N', 'C.II.1.4. Odložená daňová pohledávka - netto', '051|051K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '052', 'C.II.1.5. Pohledávky ostatní (53 až 56)', '053|054|055|056', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '052K', 'C.II.1.5. Pohledávky ostatní - korekce', '053K|054K|055K|056K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '052N', 'C.II.1.5. Pohledávky ostatní - netto', '053N|054N|055N|056N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '053', 'C.II.1.5.1. Pohledávky za společníky', '354A|355A|358A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '053K', 'C.II.1.5.1. Pohledávky za společníky - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '053N', 'C.II.1.5.1. Pohledávky za společníky - netto', '053|053K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '054', 'C.II.1.5.2. Dlouhodobé poskytnuté zálohy', '314A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '054K', 'C.II.1.5.2. Dlouhodobé poskytnuté zálohy - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '054N', 'C.II.1.5.2. Dlouhodobé poskytnuté zálohy - netto', '054|054K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '055', 'C.II.1.5.3. Dohadné účty aktivní', '388A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '055K', 'C.II.1.5.3. Dohadné účty aktivní - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '055N', 'C.II.1.5.3. Dohadné účty aktivní - netto', '055|055K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '056', 'C.II.1.5.4. Jiné pohledávky', '056A|056B', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '056A', 'C.II.1.5.4. Jiné pohledávky - 1.část', '335A|371A|374A|375A|376A|378A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '056B', 'C.II.1.5.4. Jiné pohledávky - 373', '373A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '056K', 'C.II.1.5.4. Jiné pohledávky - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '056N', 'C.II.1.5.4. Jiné pohledávky - netto', '056|056K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '057', 'C.II.2. Krátkodobé pohledávky (58 až 61)', '058|059|060|061', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '057K', 'C.II.2. Krátkodobé pohledávky - korekce', '058K|059K|060K|061K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '057N', 'C.II.2. Krátkodobé pohledávky - netto', '058N|059N|060N|061N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '058', 'C.II.2.1. Pohledávky z obchodních vztahů', '311*|313*|315*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '058K', 'C.II.2.1. Pohledávky z obchodních vztahů - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '058N', 'C.II.2.1. Pohledávky z obchodních vztahů - netto', '058|058K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '059', 'C.II.2.2. Pohledávky - ovládaná nebo ovládající osoba', '351A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '059K', 'C.II.2.2. Pohledávky - ovládaná nebo ovládající osoba - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '059N', 'C.II.2.2. Pohledávky - ovládaná nebo ovládající osoba - netto', '059|059K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '060', 'C.II.2.3. Pohledávky - podstatný vliv', '352A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '060K', 'C.II.2.3. Pohledávky - podstatný vliv - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '060N', 'C.II.2.3. Pohledávky - podstatný vliv - netto', '060|060K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '061', 'C.II.2.4. Pohledávky ostatní (62 až 67)', '062|063|064|065|066|067', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '061K', 'C.II.2.4. Pohledávky ostatní - korekce', '062K|063K|064K|065K|066K|067K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '061N', 'C.II.2.4. Pohledávky ostatní - netto', '062N|063N|064N|065N|066N|067N', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '062', 'C.II.2.4.1. Pohledávky za společníky', '062A|062B', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '062A', 'C.II.2.4.1. Pohledávky za společníky - 1.část', '354A|355A|358A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '062B', 'C.II.2.4.1. Pohledávky za společníky - 398', '398*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '062K', 'C.II.2.4.1. Pohledávky za společníky - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '062N', 'C.II.2.4.1. Pohledávky za společníky - netto', '062|062K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '063', 'C.II.2.4.2. Sociální zabezpečení a zdravotní pojištění', '336*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '063K', 'C.II.2.4.2. Sociální zabezpečení a zdravotní pojištění - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '063N', 'C.II.2.4.2. Sociální zabezpečení a zdravotní pojištění - netto', '063|063K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '064', 'C.II.2.4.3. Stát - daňové pohledávky', '064A|064B|064C|064D', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '064A', 'C.II.2.4.3. Stát - daňové pohledávky - 341', '341*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '064B', 'C.II.2.4.3. Stát - daňové pohledávky - 342', '342*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '064C', 'C.II.2.4.3. Stát - daňové pohledávky - 343', '343*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '064D', 'C.II.2.4.3. Stát - daňové pohledávky - 345', '345*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '064K', 'C.II.2.4.3. Stát - daňové pohledávky - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '064N', 'C.II.2.4.3. Stát - daňové pohledávky - netto', '064|064K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '065', 'C.II.2.4.4. Krátkodobé poskytnuté zálohy', '314A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '065K', 'C.II.2.4.4. Krátkodobé poskytnuté zálohy - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '065N', 'C.II.2.4.4. Krátkodobé poskytnuté zálohy - netto', '065|065K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '066', 'C.II.2.4.5. Dohadné účty aktivní', '388A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '066K', 'C.II.2.4.5. Dohadné účty aktivní - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '066N', 'C.II.2.4.5. Dohadné účty aktivní - netto', '066|066K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '067', 'C.II.2.4.6. Jiné pohledávky', '067A|067B', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '067A', 'C.II.2.4.6. Jiné pohledávky - 1.část', '335A|371A|374A|375A|376A|378A|395', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '067B', 'C.II.2.4.6. Jiné pohledávky - 373', '373A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '067K', 'C.II.2.4.6. Jiné pohledávky - korekce', '391A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '067N', 'C.II.2.4.6. Jiné pohledávky - netto', '067|067K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '068', 'C.II.3. Časové rozlišení aktiv (69 až 71)', '069|070|071', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '068K', 'C.II.3. Časové rozlišení aktiv - korekce', '069K|070K|071K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '068N', 'C.II.3. Časové rozlišení aktiv - netto', '068|0689K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '069', 'C.II.3.1. Náklady příštích období', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '069K', 'C.II.3.1. Náklady příštích období - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '069N', 'C.II.3.1. Náklady příštích období - netto', '069|069K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '070', 'C.II.3.2. Komplexní náklady příštích období', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '070K', 'C.II.3.2. Komplexní náklady příštích období - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '070N', 'C.II.3.2. Komplexní náklady příštích období - netto', '070|070K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '071', 'C.II.3.3. Příjmy příštích období', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '071K', 'C.II.3.3. Příjmy příštích období - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '071N', 'C.II.3.3. Příjmy příštích období - netto', '071|071K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '072', 'C.III. Krátkodobý finanční majetek (73 + 74)', '073|074', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '072K', 'C.III. Krátkodobý finanční majetek - korekce', '073K|074K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '072N', 'C.III. Krátkodobý finanční majetek - netto', '072|072K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '073', 'C.III.1. Podíly - ovládaná nebo ovládající osoba', '254*|259A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '073K', 'C.III.1. Podíly - ovládaná nebo ovládající osoba - korekce', '291A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '073N', 'C.III.1. Podíly - ovládaná nebo ovládající osoba - netto', '073|073K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '074', 'C.III.2. Ostatní krátkodobý finanční majetek', '251*|253*|256*|257*|259A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '074K', 'C.III.2. Ostatní krátkodobý finanční majetek - korekce', '291A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '074N', 'C.III.2. Ostatní krátkodobý finanční majetek - netto', '074|074K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '075', 'C.IV. Peněžní prostředky (76 + 77)', '076|077', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '075K', 'C.IV. Peněžní prostředky - korekce', '076K|077K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '075N', 'C.IV. Peněžní prostředky - netto', '075|075K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '076', 'C.IV.1. Peněžní prostředky v pokladně', '211*|213*|261A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '076K', 'C.IV.1. Peněžní prostředky v pokladně - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '076N', 'C.IV.1. Peněžní prostředky v pokladně - netto', '076|076K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '077', 'C.IV.2. Peněžní prostředky na účtech', '221*|261A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '077K', 'C.IV.2. Peněžní prostředky na účtech - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '077N', 'C.IV.2. Peněžní prostředky na účtech - netto', '077|077K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '078', 'D. Časové rozlišení aktiv (79 až 81)', '079|080|081', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '078K', 'D. Časové rozlišení aktiv - korekce', '079K|080K|081K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '078N', 'D. Časové rozlišení aktiv - netto', '078|078K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '079', 'D.1. Náklady příštích období', '381*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '079K', 'D.1. Náklady příštích období - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '079N', 'D.1. Náklady příštích období - netto', '079|076K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '080', 'D.2. Komplexní náklady příštích období', '382*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '080K', 'D.2. Komplexní náklady příštích období - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '080N', 'D.2. Komplexní náklady příštích období - netto', '080|080K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '081', 'D.3. Příjmy přístích období', '385*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '081K', 'D.3. Příjmy přístích období - korekce', '', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '081N', 'D.3. Příjmy přístích období - netto', '081|081K', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '082', 'PASIVA CELKEM (83 + 104 + 147)', '083+104+147', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '083', 'A. Vlastní kapitál (84 + 88 + 96 + 99 + 102 - 103)', '084+088+096+099+102-103', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '084', 'A.I. Základní kapitál (85 až 87)', '085|086|087', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '085', 'A.I.1. Základní kapitál', '411*|491*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '086', 'A.I.2. Vlastní podíly (-)', '252*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '087', 'A.I.3. Změny základního kapitálu', '419*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '088', 'A.II. Ážio a kapitálové fondy (89 + 90)', '089|090', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '089', 'A.II.1.Ážio', '412*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '090', 'A.II.2. Kapitálové fondy (91 až 95)', '091|092|093|094|095', 2, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '091', 'A.II.2.1. Ostatní kapitálové fondy', '413*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '092', 'A.II.2.2. Oceňovací rozdíly z přecenění majetku a závazků (+/-)', '414*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '093', 'A.II.2.3. Oceňovací rozdíly z přecenění při přeměnách obchodních korporací', '418*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '094', 'A.II.2.4. Rozdíly z přeměn obchodních korporací', '417*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '095', 'A.II.2.5. Rozdíly z ocenění při přeměnách obchodních korporací', '416*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '096', 'A.III. Fondy ze zisku (97 + 98)', '097|098', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '097', 'A.III.1. Ostatní rezervní fondy', '421*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '098', 'A.III.2. Statutární a ostatní fondy', '423*|427*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '099', 'A.IV. Výsledek hospodaření minulých let (100+101)', '100|101', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '100', 'A.IV.1. Nerozdělený zisk minulých let nebo neuhrazená ztráta min. let', '428*|429*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '101', 'A.IV.2. Jiný výsledek hospodaření minulých let', '426*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '102', 'A.V. Výsledek hospodaření běžného účetního období (01 - (84+88+96+99-103+104+144', '500000..699999', 0, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '103', 'A.VI. Rozhodnuto o zálohové výplatě podílu na zisku', '432*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '104', 'B.+C. Cizí zdroje (105 + 110)', '105|110', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '105', 'B. Rezervy (106 až 109)', '106|107|108|109', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '106', 'B.1. Rezerva na důchody a podobné závazky', '459A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '107', 'B.2. Rezerva na daň z příjmů', '453*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '108', 'B.3. Rezervy podle zvláštních právních předpisů', '451*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '109', 'B.4. Ostatní rezervy', '459A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '110', 'C. Závazky (111 + 126 + 144)', '111|126|144', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '111', 'C.I. Dlouhodobé závazky (112 + 115 až 122)', '112|115|116|117|118|119|120|121|122', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '112', 'C.I.1. Vydané dluhopisy (113 + 114)', '113|114', 2, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '113', 'C.I.1.1. Vyměnitelné dluhopisy', '473A|255A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '114', 'C.I.1.2. Ostatní dluhopisy', '473A|255A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '115', 'C.I.2. Závazky k úvěrovým institucím', '461A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '116', 'C.I.3. Dlouhodobé přijaté zálohy', '475A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '117', 'C.I.4. Závazky z obchodních vztahů', '479A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '118', 'C.I.5. Dlouhodobé směnky k úhradě', '478A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '119', 'C.I.6. Závazky - ovládaná nebo ovládající osoba', '471A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '120', 'C.I.7. Závazky - podstatný vliv', '472A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '121', 'C.I.8. Odložený daňový závazek', '481*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '122', 'C.I.9. Závazky - ostatní (123 až 125)', '123|124|125', 2, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '123', 'C.I.9.1. Závazky ke společníkům', '364A|365A|366A|367A|368A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '124', 'C.I.9.2. Dohadné účty pasivní', '389A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '125', 'C.I.9.3. Jiné závazky', '125A|125B', 2, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '125A', 'C.I.9.3. Jiné závazky - 1.část', '372A|377A|379A|474A|479A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '125B', 'C.I.9.3. Jiné závazky - 373', '373A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '126', 'C.II. Krátkodobé závazky (127 + 130 až 136)', '127|130|131|132|133|134|135|136', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '127', 'C.II.1. Vydané dluhopisy (128 + 129)', '128|129', 2, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '128', 'C.II.1.1. Vyměnitelné dluhopisy', '241A|473A|255A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '129', 'C.II.1.2. Ostatní dluhopisy', '241A|473A|255A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '130', 'C.II.2. Závazky k úvěrovým institucím', '231*|232*|461A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '131', 'C.II.3. Krátkodobé přijaté zálohy', '324*|475A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '132', 'C.II.4. Závazky z obchodních vztahů', '321*|325*|479A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '133', 'C.II.5. Krátkodobé směnky k úhradě', '322*|478A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '134', 'C.II.6. Závazky - ovládaná nebo ovládající osoba', '361*|471A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '135', 'C.II.7. Závazky - podstatný vliv', '362*|472A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '136', 'C.II.8. Závazky - ostatní (137 až 143)', '137|138|139|140|141|142|143', 2, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '137', 'C.II.8.1. Závazky ke společníkům', '137A|137B', 2, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '137A', 'C.II.8.1. Závazky ke společníkům - 1.část', '364A|365A|366A|367A|368A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '137B', 'C.II.8.1. Závazky ke společníkům - 398', '398*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '138', 'C.II.8.2. Krátkodobé finanční výpomoci', '249*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '139', 'C.II.8.3. Závazky k zaměstnancům', '331*|333*|479A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '140', 'C.II.8.4. Závazky ze sociálního zabezpečení a zdravotního pojištění', '336*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '141', 'C.II.8.5. Stát - daňové závazky a dotace', '141A|141B|141C|141D|141E|141F', 2, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '141A', 'C.II.8.5. Stát - daňové závazky a dotace - 341', '341*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '141B', 'C.II.8.5. Stát - daňové závazky a dotace - 342', '342*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '141C', 'C.II.8.5. Stát - daňové závazky a dotace - 343', '343*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '141D', 'C.II.8.5. Stát - daňové závazky a dotace - 345', '345*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '141E', 'C.II.8.5. Stát - daňové závazky a dotace - 346', '346*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '141F', 'C.II.8.5. Stát - daňové závazky a dotace - 347', '347*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '142', 'C.II.8.6. Dohadné účty pasivní', '389A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '143', 'C.II.8.7. Jiné závazky', '143A|143B', 2, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '143A', 'C.II.8.7. Jiné závazky - 1.část', '372A|377A|379A|474A|479A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '143B', 'C.II.8.7. Jiné závazky - 373', '373A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '144', 'C.III. Časové rozlišení pasiv (145 + 146)', '145|146', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '145', 'C.III.1. Výdaje příštích období', '383*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '146', 'C.III..2. Výnosy příštích období', '384*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '147', 'D. Časové rozlišení pasiv (148 + 149)', '148|149', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '148', 'D.1. Výdaje příštích období', '', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XBALANCESHT'), '149', 'D.2. Výnosy příštích období', '', 0, '', '', '', '', true, false);
    end;

    local procedure CreateIncomeStatement()
    begin
        // NAVCZ
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '01', 'I. Tržby z prodeje výrobků a služeb', '601*|602*', 0, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '02', 'II. Tržby za prodej zboží', '604*', 0, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '03', 'A. Výkonová spotřeba (04 + 05 + 06)', '04|05|06', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '04', 'A.1. Náklady vynaložené na prodané zboží', '504*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '05', 'A.2. Spotřeba materiálu a energie', '501*|502*|503*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '06', 'A.3. Služby', '511*|512*|513*|518*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '07', 'B. Změna stavu zásob vlastní činnosti', '581*|582*|583*|584*|611*|612*|613*|614*', 0, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '08', 'C. Aktivace', '585*|586*|587*|588*|621*|622*|623*|624*', 0, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '09', 'D. Osobní náklady (10 + 11)', '10|11', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '10', 'D.1. Mzdové náklady', '521*|522*|523*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '11', 'D.2. Náklady na sociální zabezpečení, zdrav. pojištění a ost. náklady (12 +13)', '12|13', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '12', 'D.2.1. Náklady na sociální zabezpečení a zdravotní pojištění', '524*|525*|526*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '13', 'D.2.2. Ostatní náklady', '527*|528*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '14', 'E. Úpravy hodnot v provozní oblasti (15 + 18 + 19)', '15|18|19', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '15', 'E.1. Úpravy hodnot dlouhodobého nehmotného a hmotného majetku (16 + 17)', '16|17', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '16', 'E.1.1. Úpravy hodnot dlouhodobého nehmotného a hmotného majetku - trvalé', '551*|557*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '17', 'E.1.2. Úpravy hodnot dlouhodobého nehmotného a hmotného majetku - dočasné', '559A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '18', 'E.2. Úpravy hodnot zásob', '559A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '19', 'E.3. Úpravy hodnot pohledávek', '558*|559*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '20', 'III. Ostatní provozní výnosy (21 + 22 + 23)', '21|22|23', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '21', 'III.1. Tržby z prodaného dlouhodobého majetku', '641*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '22', 'III.2. Tržby z prodaného materiálu', '642*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '23', 'III.3. Jiné provozní výnosy', '644*|646*|648*|649*|697*|688*', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '24', 'F. Ostatní provozní náklady (25 až 29)', '25|26|27|28|29', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '25', 'F.1. Zůstatková cena prodaného dlouhodobého majetku', '541*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '26', 'F.2. Zůstatková cena prodaného materiálu', '542*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '27', 'F.3. Daně a poplatky', '531*|532*|538*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '28', 'F.4. Rezervy v provozní oblasti a komplexní náklady přístích období', '552*|554*|555*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '29', 'F.5. Jiné provozní náklady', '543A|544*|545*|546*|547*|548*|549*|597*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '30', 'Provozní výsledek hospodaření (01 + 02 - 03 - 07 - 08 - 09 - 14 + 20 - 24)', '01|02|03|07|08|09|14|20|24', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '31', 'IV. Výnosy z dlouhodobého finančního majetku - podíly (32 + 33)', '32|33', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '32', 'IV.1. Výnosy z podílů - ovládaná nebo ovládající osoba', '661A|665A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '33', 'IV.2. Ostatní výnosy z podílů', '661A|665A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '34', 'G. Náklady vynaložené na prodané podíly', '561A', 0, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '35', 'V. Výnosy z ostatního dlouhodobého finančního majetku (36 + 37)', '36|37', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '36', 'V.1. Výnosy z ostatního dlouhodobého fin. maj. - ovládaná nebo ovládající osoba', '661A|665A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '37', 'V.2. Ostatní výnosy z ostatního dlouhodobého finančního majetku', '661A|665A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '38', 'H. Náklady související s ostatním dlouhodobým finančním majetkem', '561A|566A', 0, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '39', 'VI. Výnosové úroky a podobné výnosy (40 + 41)', '40|41', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '40', 'VI.1. Výnosové úroky a podobné výnosy - ovládaná nebo ovládající osoba', '662A|665A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '41', 'VI.2. Ostatní výnosové úroky a podobné výnosy', '662A|665A', 0, '', '', '', '', true, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '42', 'I. Úpravy hodnot a rezervy ve finanční oblasti', '574*|579*', 0, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '43', 'J. Nákladové úroky a podobné náklady (44 + 45)', '44|45', 2, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '44', 'J.1. Nákladové úroky a podobné náklady - ovládaná nebo ovládající osoba', '562A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '45', 'J.2. Ostatní nákladové úroky a podobné náklady', '562A', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '46', 'VII. Ostatní finanční výnosy', '661A|663*|664*|666*|667*|668*|669*|698*', 0, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '47', 'K. Ostatní finanční náklady', '543A|561A|563*|564*|565*|566A|567*|568*|569*|598*', 0, '', '', '', '', false, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '48', 'Finanční výsledek hospodaření (31 - 34 + 35 - 38 + 39 - 42 - 43 + 46 - 47)', '31|34|35|38|39|42|43|46|47', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '49', 'Výsledek hospodaření před zdaněním (30 + 48)', '30|48', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '50', 'L. Daň z příjmů (51 + 52)', '51|52', 2, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '51', 'L.1. Daň z příjmů splatná', '591*|595*|599*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '52', 'L.2. Daň z pířjmů odložená', '592*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '53', 'Výsledek hospodaření po zdanění (49 - 50)', '49|50', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '54', 'M. Převod podílu na výsledku hospodaření společníkům', '596*', 0, '', '', '', '', false, false);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '55', 'Výsledek hospodaření za účetní období (53 - 54)', '53|54', 2, '', '', '', '', true, true);
        InsertData(CreateColumnLayoutName.GetColumnLayoutName('XINCOMESTMT'), '56', 'Čistý obrat za účetní období (I + II + III + IV + V + VI + VII)', '01|02|20|31|35|39|46', 2, '', '', '', '', true, true);
    end;
}
