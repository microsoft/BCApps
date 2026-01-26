codeunit 101085 "Create Acc. Schedule Line"
{

    trigger OnRun()
    begin
        InsertData(XCASTAFF, '10', XPersonalCosts, '', 6, '', '', '', '', false, false);
        InsertData(XCASTAFF, '20', XMonthlySalaries, CA.Convert('998710') + '..' + CA.Convert('998720'), 6, '', '', '', '', false, false);
        InsertData(XCASTAFF, '40', XSocialSecurity, CA.Convert('998730') + '..' + CA.Convert('998730'), 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '100', XTransferOverheadCosts, '', 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '200', XInitialCostCenters, '9901', 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '300', XMainCostCenters, '9902', 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '500', XTotalTransfers, '200..300', 2, '', '', '', '', false, false);
        InsertData(XCAPROF, '100', XCCCOSummaryReport, '', 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '110', XRevenues, CA.Convert('996110') + '..' + CA.Convert('996195'), 7, '', '', '', '', false, false);
        InsertData(XCAPROF, '120', XRevenueReductions, CA.Convert('996710') + '..' + CA.Convert('996910'), 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '130', XNetRevenue, '110..120', 2, '', '', '', '', false, false);
        InsertData(XCAPROF, '140', XMaterialCosts, CA.Convert('997110') + '..' + CA.Convert('997195'), 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '160', XGrossProfit, '130..150', 2, '', '', '', '', false, false);
        InsertData(XCAPROF, '170', XSalaryDirectCosts, CA.Convert('998790'), 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '300', XMainCostCenters, '9902', 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '500', XTotalTransfers, '200..300', 2, '', '', '', '', false, false);

        InsertDataForCashFlow(
          XDEGREE, '', XCalculationBase, '', false, true, false, false, false);
        InsertDataForCashFlow(
          XDEGREE, 'R10', XCashFlowFunds, '2100', false, false, false, false, false);
        InsertDataForCashFlow(
          XDEGREE, 'R20', XMonetarycurrentAssets, '0010|0030|0040|0060|2100', false, false, false, false, false);
        InsertDataForCashFlow(
          XDEGREE, 'R30', XCurrentAssets, '0010..0070|2100', false, false, false, false, false);
        InsertDataForCashFlow(
          XDEGREE, 'R40', XShortTermObligations, '1010..1100', false, false, false, false, true);
        InsertDataForCashFlow(
          XDEGREE, '', '', '', false, false, false, false, false);
        InsertDataForCashFlow(
          XDEGREE, 'L1', XCashFlow1Degree, 'R10/R40', true, true, false, false, true);
        InsertDataForCashFlow(
          XDEGREE, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XDEGREE, 'L2', XCashFlow2Degree, 'R20/R40', true, true, false, false, true);
        InsertDataForCashFlow(
          XDEGREE, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XDEGREE, 'L3', XCashFlow3Degree, 'R30/R40', true, true, false, false, true);

        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XReceivables, '0010', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XOpenSalesOrders, '0020', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XOpenServiceOrders, '0080', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XRentals, '0030', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XFinancialAssets, '0040', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XFixedAssetsDisposals, '0050', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XPrivateInvestments, '0060', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XMiscellaneousReceipts, '0070', true, false, false, true, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R20', XTotalofCashReceipts, 'R10', true, true, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XPayables, '1010', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XOpenPurchaseOrders, '1020', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XPersonnelCosts, '1030', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XRunningCosts, '1040', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XFinanceCosts, '1050', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XMiscellaneousCosts, '1060', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XInvestments, '1070', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XEncashmentOfBills, '1080', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XPrivateConsumptions, '1090', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XVATDue, '1100', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XOtherExpenses, '1110', true, false, false, true, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R40', XTotalOfCashDisbursements, 'R30', true, true, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R50', XSurplus, 'R10|R40', true, true, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R60', XCashFlowFunds, '2100', true, false, false, true, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R70', XTotalCashFlow, 'R50|R60', true, true, false, false, false);

        InsertDataNA(XANALYSIS, '', XACIDTESTANALYSIS, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', XCurrentAssets, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '01', XLiquidAssets, '11700', 1, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '02', XSecurities, '12300', 1, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '03', XAccountsReceivable, '13400', 1, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '04', XInventory, '14500', 1, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '05', XWIP, '15300', 1, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '06', XCurrentAssetsTotal, '01..05', 2, false, 2, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', XShorttermLiabilities, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '11', XRevolvingCredit, '22100', 0, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '12', XAccountsPayable, '22500', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '13', SALESTAX, '22790', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '14', XPersonnelrelatedItems, '23900', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '15', XOtherLiabilities, '24400', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '16', XShorttermLiabilitiesTotal, '11..15', 2, false, 2, '', '', '', '', true, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', XCurAminusShorttermLiabilities, '06|16', 2, false, 2, '', '', '', '', true, false, false, false, 0, 0);

        InsertDataNA(XBALANCESH, '', uppercase(XAssets), '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', XCurrentAssets, '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '01', XLiquidAssets, '11700', 1, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '02', XSecurities, '12300', 1, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '03', XAccountsReceivable, '13400', 1, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '04', XInventory, '14500', 1, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '05', Text010, '15300', 1, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, Text011, Text012, '01..05', 2, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', Text013, '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '11', Text014, '16200..16220', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '12', Text015, '17100..17120', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '13', Text016, '18100..18120', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '14', Text017, '16300|17200|18200', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, Text018, Text019, '11..14', 2, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, Text020, Text021, Text022, 2, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 4, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', Text023, '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', Text024, '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '21', Text025, '22100', 0, false, 2, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '22', Text026, '22500', 1, false, 2, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '23', Text027, '22790', 1, false, 2, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '24', Text028, '23900', 1, false, 2, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '25', Text029, '24400', 1, false, 2, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, Text030, Text031, '21..25', 2, false, 0, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, Text032, Text033, '25400', 1, false, 0, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, Text034, Text035, Text036, 2, false, 0, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', Text037, '', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '31', Text038, CreateGLAccount.Non_RestrictedEquity(), 0, false, 2, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '32', Text039, CreateGLAccount.ResultsfortheFinancialyear(), 0, false, 2, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '33', Text040, '30400', 1, false, 0, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, Text041, Text042, '31..33', 2, false, 0, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XBALANCESH, '', Text043, Text044, 2, false, 2, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '', '', '', 4, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(XCAMPAIGN, '', XCAMPAIGNANALYSIS, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '11', XSalesRetailDom, '44100', 0, false, 0, Text045, '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '12', XPurchRetailDom, '54100', 0, false, 0, Text045, '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '1', XTradingMarginDomestic, '-12-11', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '21', XSalesRetailEU, '44200', 0, false, 0, Text045, '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '22', XPurchRetailEU, '54200', 0, false, 0, Text045, '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '2', XTradingMarginEU, '-22-21', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '31', XSalesRetailExport, '44300', 0, false, 0, Text045, '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '32', XPurchRetailExport, '54300', 0, false, 0, Text045, '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '3', XTradingMarginExport, '-32-31', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', XCampaignResult, '1+2+3', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text046, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text047, '44100..44300', 0, false, 0, '', '20..45', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text048, '44100..44300', 0, false, 0, '', '50', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text049, '44100..44300', 0, false, 0, '', '60..85', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text050, '44100..44300', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text051, '44100..44300', 0, false, 0, '', '', '', '', true, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text052, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text053, '44100..44300', 0, false, 0, '', '', '', Text054, false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text055, '44100..44300', 0, false, 0, '', '', '', Text056, false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text057, '44100..44300', 0, false, 0, '', '', '', Text058, false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text059, '44100..44300', 0, false, 0, '', '', '', Text060, false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text061, '44100..44300', 0, false, 0, '', '', '', Text062, false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text050, '44100..44300', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XCAMPAIGN, '', Text051, '44100..44300', 0, false, 0, '', '', '', '', true, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '005', Text129, '080', 5, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '010', Text130, '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '020', Text131, '41300', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '030', Text132, '42500', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '040', Text133, '43500', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '050', Text134, '44500', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '060', Text135, '45000..45200', 0, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '070', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '080', Text136, '010..060', 2, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '090', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '100', Text137, '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '110', Text138, '51000', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '120', Text139, '52300', 1, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '130', Text140, '53900', 1, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '140', Text141, '54900', 1, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '150', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '160', Text142, '100..140', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '170', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '180', Text143, '080|160', 2, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '190', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '200', Text144, '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '210', Text145, CreateGLAccount.LifeInsurance(), 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '220', Text146, CreateGLAccount.RepairsandMaintenanceforRental() + '..' + CreateGLAccount.ElectricityforRental(), 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
        InsertDataNA(uppercase(XIncome), '230', Text147, '62100..62200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '240', Text148, '62300..62950', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '250', Text149, '63500', 1, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '260', Text150, '64100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '270', Text151, '64200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '280', Text152, '64300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '290', Text153, '65100..65200|65700..65800', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '300', Text154, '65300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '310', Text155, '65600', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '320', Text156, '66400', 1, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '330', Text157, '67200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '340', Text158, '67300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '350', Text159, '67100|67400..67500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '360', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '370', Text160, '200..350', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '380', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '390', Text161, '180|370', 2, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '400', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '410', Text162, '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '420', Text163, '79950', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '425', Text164, '80600', 1, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '430', Text165, '80800..81100', 0, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '440', Text166, '81200', 0, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '450', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '460', Text167, '400..450', 2, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '470', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '480', Text168, '390|460', 2, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '490', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '500', Text169, '84300', 1, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '530', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '550', Text170, '480..500', 2, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '560', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '570', Text171, '85300', 1, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '580', '', '', 3, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '600', Text065, '550..570', 2, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(uppercase(XIncome), '610', '', '', 4, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '', XREVENUE, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '', XSalesofRetail, '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '11', XSalesRetailDom, '44100', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '12', XSalesRetailEU, '44200', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '13', XSalesRetailExport, '44300', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '14', XJobSalesAdjmtRetail, '44400', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '15', XSalesofRetailTotal, '44500', 1, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '', XRevenueArea10to30Total, '44100..44400', 0, false, 0, '10..30', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '', XRevenueArea40to85Total, '44100..44400', 0, false, 0, '40..85', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '', XRevenuenoAreacodeTotal, '44100..44400', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '', XRevenueTotal, '44100..44400', 0, false, 0, '', '', '', '', true, false, false, true, 0, 0);
    end;

    var
        CA: Codeunit "Make Adjustments";
        "Line No.": Integer;
        "Previous Schedule Name": Code[10];
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        GLAccountCategory: Record "G/L Account Category";
        CreateGLAccount: Codeunit "Create G/L Account";
        XANALYSIS: Label 'ANALYSIS';
        XACIDTESTANALYSIS: Label 'ACID-TEST ANALYSIS';
        XCurrentAssets: Label 'Current Assets';
        XInventory: Label '  Inventory';
        XAccountsReceivable: Label '  Accounts Receivable';
        XSecurities: Label '  Securities';
        XLiquidAssets: Label '  Liquid Assets';
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
        XIncomeServices: Label 'Income, Services';
        XIncomeProductSales: Label 'Income, Product Sales';
        XJobSales: Label 'Job Sales';
        XSalesRetailExport: Label 'Sales, Retail - Export';
        XPurchRetailExport: Label 'Purch, Retail - Export';
        XTradingMarginExport: Label 'Trading Margin, Export';
        XCampaignResult: Label 'Campaign Result';
        XCASHFLOW: Label 'CASHFLOW', Comment = 'Cashflow is a name of Account Schedule.';
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
        XOtherIncome: Label 'Other Income';
        XTotalOfCashDisbursements: Label 'Total of Cash Disbursements';
        XCashFlowFunds: Label 'CashFlow Funds';
        XTotalCashFlow: Label 'Total Cash Flow';
        XReceivables: Label 'Receivables';
        XTotalofCashReceipts: Label 'Total of Cash Receipts';
        XOpenPurchaseOrders: Label 'Open Purchase Orders';
        XMiscellaneousCosts: Label 'Miscellaneous costs';
        XCalculationBase: Label 'Calculation Base';
        XDEGREE: Label 'DEGREE', Comment = 'Degree is a name of Account Schedule.';
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
        XRevenueArea10to55Total: Label 'Revenue Area 10..55, Total';
        XRevenueArea60to85Total: Label 'Revenue Area 60..85, Total';
        XRevenuenoAreacodeTotal: Label 'Revenue, no Area code, Total';
        XRevenueTotal: Label 'Revenue, Total';
        XCAMPAIGN: Label 'CAMPAIGN';
        XCASTAFF: Label 'CA-STAFF';
        XCATRANSFER: Label 'CA-TRANS';
        XCAPROF: Label 'CA-PROF';
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
        XBALANCESH: Label 'BALANCE SH';
        XWIP: Label '  WIP';
        SALESTAX: Label 'Sales Taxes Payable';
        Text010: Label '  WIP';
        Text011: Label 'A01';
        Text012: Label 'Total Current Assets';
        Text013: Label 'Fixed Assets';
        Text014: Label '  Vehicles';
        Text015: Label '  Operating Equipment';
        Text016: Label '  Land and Buildings';
        Text017: Label '  Accumulated Depreciation';
        Text018: Label 'A02';
        Text019: Label 'Total Fixed Assets';
        Text020: Label 'A03';
        Text021: Label 'TOTAL ASSETS';
        Text022: Label 'A02|A01';
        Text023: Label 'LIABILITIES AND EQUITY';
        Text024: Label 'Current Liabilities';
        Text025: Label '  Revolving Credit';
        Text026: Label '  Accounts Payable';
        Text027: Label '  Sales Taxes Payable';
        Text028: Label '  Personnel-related Items';
        Text029: Label '  Other Liabilities';
        Text030: Label 'L01';
        Text031: Label 'Total Current Liabilities';
        Text032: Label 'L02';
        Text033: Label 'Long-Term Liabilities';
        Text034: Label 'L03';
        Text035: Label 'Total Liabilities';
        Text036: Label 'L01|L02';
        Text037: Label 'Equity';
        Text038: Label '  Capital Stock';
        Text039: Label '  Retained Earnings';
        Text040: Label '  Net Income for the Year';
        Text041: Label 'E01';
        Text042: Label 'Total Equity';
        Text043: Label 'TOTAL LIABILITIES AND EQUITY';
        Text044: Label 'L03|E01';
        Text045: Label 'Summer';
        Text046: Label 'Geographical Distribution';
        Text047: Label 'Northern Europe';
        Text048: Label 'Southern Europe';
        Text049: Label 'America';
        Text050: Label 'Unknown';
        Text051: Label 'Total';
        Text052: Label 'Customer Group Distribution';
        Text053: Label 'Institution';
        Text054: Label 'INSTITUTION';
        Text055: Label 'Large';
        Text056: Label 'LARGE';
        Text057: Label 'Medium';
        Text058: Label 'MEDIUM';
        Text059: Label 'Private';
        Text060: Label 'PRIVATE';
        Text061: Label 'Small';
        Text062: Label 'SMALL';
        Text065: Label 'Net Income';
        Text129: Label 'Percent Calc';
        Text130: Label 'Revenue';
        Text131: Label '  Jobs';
        Text132: Label '  Resources';
        Text133: Label '  Materials';
        Text134: Label '  Retail';
        Text135: Label '  Other';
        Text136: Label 'Total Revenue';
        Text137: Label 'Cost of Goods Sold';
        Text138: Label '  Cost of Jobs';
        Text139: Label '  Cost of Resources';
        Text140: Label '  Cost of Materials';
        Text141: Label '  Cost of Retail Goods';
        Text142: Label 'Total Cost of Goods Sold';
        Text143: Label 'Gross Profit';
        Text144: Label 'Operating Expenses';
        Text145: Label '  Marketing';
        Text146: Label '  Travel & Entertainment';
        Text147: Label '  Salaries & Wages';
        Text148: Label '  Personnel Benefits';
        Text149: Label '  Vehicle Fleet';
        Text150: Label '  Software';
        Text151: Label '  Outside Consultants';
        Text152: Label '  Computer Expenses';
        Text153: Label '  General Administrative';
        Text154: Label '  Repairs & Maintenance';
        Text155: Label '  Office Supplies';
        Text156: Label '  Depreciation';
        Text157: Label '  Bad Debt';
        Text158: Label '  Legal & Accounting';
        Text159: Label '  Other Operating Expenses';
        Text160: Label 'Total Operating Expenses';
        Text161: Label 'Net Operating Income';
        Text162: Label 'Other Income & Expense';
        Text163: Label '  Interest Income';
        Text164: Label '  Interest Expense';
        Text165: Label '  Gains (Losses) on Foreign Exchanges';
        Text166: Label '  Other Gains (Losses)';
        Text167: Label 'Total Other Income & (Expenses)';
        Text168: Label 'Net Income Before Taxes & Extraordinary Items';
        Text169: Label 'Income Taxes';
        Text170: Label 'Net Income Before Extraordinary Items';
        Text171: Label 'Extraordinary Items';
        XACCCAT: Label 'ACC-CAT', Comment = 'ACC-CAT is the name of the Account Schedule.';
        XBALSHEET: Label 'BALANCE SHEET';
        XAssets: Label 'Assets';
        XIncomeThisYear: Label 'Income This Year';
        XIncomeStatement: Label 'INCOME STATEMENT';
        XIncome: Label 'Income';
        XNetIncome: Label 'NET INCOME';

    procedure InsertEvaluationData();
    var
        CreateAccScheduleName: Codeunit "Create Acc. Schedule Name";
        AssetsTxt: Text[80];
        LiabilitiesTxt: Text[80];
        EquityTxt: Text[80];
        IncomeTxt: Text[80];
        CostOfGoodsSoldTxt: Text[80];
        ExpenseTxt: Text[80];
        XBSDETTxt: Code[10];
        XBSSUMTxt: Code[10];
        XISDETTxt: Code[10];
        XISSUMTxt: Code[10];
        XTBTxt: Code[10];
    begin
        AssetsTxt := Format(GLAccountCategory."Account Category"::Assets, 80);
        LiabilitiesTxt := Format(GLAccountCategory."Account Category"::Liabilities, 80);
        EquityTxt := Format(GLAccountCategory."Account Category"::Equity, 80);
        IncomeTxt := Format(GLAccountCategory."Account Category"::Income, 80);
        CostOfGoodsSoldTxt := Format(GLAccountCategory."Account Category"::"Cost of Goods Sold", 80);
        ExpenseTxt := Format(GLAccountCategory."Account Category"::Expense, 80);
        XBSDETTxt := CreateAccScheduleName.GetBSDETAccountScheduleName();
        XISDETTxt := CreateAccScheduleName.GetISDETAccountScheduleName();
        XBSSUMTxt := CreateAccScheduleName.GetBSSUMAccountScheduleName();
        XISSUMTxt := CreateAccScheduleName.GetISSUMAccountScheduleName();
        XTBTxt := CreateAccScheduleName.GetTBAccountScheduleName();

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

        InsertDataNA(XANALYSIS, '', XACIDTESTANALYSIS, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', XCurrentAssets, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '01', XLiquidAssets, CreateGLAccount.BusinessaccountOperatingDomestic() + '..' + CreateGLAccount.PettyCash(), 0, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '02', XSecurities, '', 1, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '03', XAccountsReceivable, CreateGLAccount.AccountReceivableDomestic() + '|' + CreateGLAccount.PrepaidRent() + '|' + CreateGLAccount.Otherprepaidexpensesandaccruedincome(), 0, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '04', XInventory, CreateGLAccount.FinishedGoods(), 0, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '05', XWIP, '10910..10950', 0, false, 2, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '06', XCurrentAssetsTotal, '01..05', 2, false, 2, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', XShorttermLiabilities, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '11', XRevolvingCredit, '20500', 0, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '12', XAccountsPayable, CreateGLAccount.AccountsPayableDomestic(), 0, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '13', SALESTAX, CreateGLAccount.SalesTax_VATLiable(), 0, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '14', XPersonnelrelatedItems, CreateGLAccount.TaxesLiable() + '..' + CreateGLAccount.EmployeesWithholdingTaxes(), 0, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '15', XOtherLiabilities, CreateGLAccount.PurchaseDiscounts() + '..' + CreateGLAccount.DeferredIncome(), 0, false, 2, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '16', XShorttermLiabilitiesTotal, '11..15', 2, false, 2, '', '', '', '', true, false, false, true, 0, 0);
        InsertDataNA(XANALYSIS, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XANALYSIS, '', XCurAminusShorttermLiabilities, '06|16', 2, false, 2, '', '', '', '', true, false, false, false, 0, 0);

        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XReceivables, '1-RECEIVABLES', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XOpenSalesOrders, '6-SALES ORDERS', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XOpenServiceOrders, '10-SERVICE ORDERS', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XRentals, '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XFinancialAssets, '8-FIXED ASSETS BUDGE', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XFixedAssetsDisposals, '9-FIXED ASSETS DISPO', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XPrivateInvestments, '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R10', XMiscellaneousReceipts, '5-CASH FLOW MANUAL R', true, false, false, true, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R20', XTotalofCashReceipts, 'R10', true, true, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XPayables, '2-PAYABLES', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XOpenPurchaseOrders, '7-PURCHASE ORDERS', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XPersonnelCosts, '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XRunningCosts, '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XFinanceCosts, '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XMiscellaneousCosts, '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XInvestments, '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XEncashmentOfBills, '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XPrivateConsumptions, '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XVATDue, '15-TAX', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R30', XOtherExpenses, '4-CASH FLOW MANUAL E', true, false, false, true, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R40', XTotalOfCashDisbursements, 'R30', true, true, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R50', XSurplus, 'R10|R40', true, true, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R60', XCashFlowFunds, '3-LIQUID FUNDS', true, false, false, true, false);
        InsertDataForCashFlow(
          XCASHFLOW, '', '', '', true, false, false, false, false);
        InsertDataForCashFlow(
          XCASHFLOW, 'R70', XTotalCashFlow, 'R50|R60', true, true, false, false, false);

        InsertDataNA(XREVENUE, '', XREVENUE, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '', XSalesofRetail, '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '11', XIncomeServices, CreateGLAccount.SalesofServiceWork(), 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '12', XIncomeProductSales, CreateGLAccount.SalesofGoods(), 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '13', XJobSales, '40250', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '14', XOtherIncome, CreateGLAccount.SalesDiscounts() + '..' + CreateGLAccount.InterestIncome(), 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '15', XSalesofRetailTotal, CreateGLAccount.TOTALINCOME(), 1, true, 0, '', '', '', '', true, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '', XRevenueArea10to55Total, CreateGLAccount.SalesofServiceWork() + '..' + CreateGLAccount.TOTALINCOME(), 0, false, 0, '10..55', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '', XRevenueArea60to85Total, CreateGLAccount.SalesofServiceWork() + '..' + CreateGLAccount.TOTALINCOME(), 0, false, 0, '60..85', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '', XRevenuenoAreacodeTotal, CreateGLAccount.SalesofServiceWork() + '..' + CreateGLAccount.TOTALINCOME(), 0, false, 0, '''''', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '', XRevenueTotal, CreateGLAccount.SalesofServiceWork() + '..' + CreateGLAccount.TOTALINCOME(), 0, false, 0, '', '', '', '', true, false, false, true, 0, 0);

        // balance sheet detailed
        InsertDataNA(XBSDETTxt, '', 'Current Assets', '', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CA', 'Cash', '18000..18999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CA', 'Accounts Receivable', '15000..15999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CA', 'Other Receivables', '13000..13999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CA', 'Inventory', '14000..14999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CA', 'Prepaid Expenses', '16000..16999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CA', 'Other Current Assets', '10000..11999', 0, false, 0, '', '', '', '', false, false, true, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'F1', 'Total Current Assets', 'CA', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', 'Long Term Assets', '', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'LTA', 'Fixed Assets', '12000..12899', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'LTA', 'Accumulated Depreciation', '12900..12999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'LTA', 'Other Long Term Assets', '17000..17999|19000..19999', 0, false, 0, '', '', '', '', false, false, true, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'F2', 'Total Long Term Assets', 'LTA', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'F3', 'Total Assets', 'F1+F2', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        DoubleUnderscoreCurrentLine(XBSDETTxt);
        InsertDataNA(XBSDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', 'Current Liabilities', '', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CL', 'Accounts Payable', '22100..22399', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CL', 'Accrued Payroll', '23500..25399|26100..26399', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CL', 'Accrued Tax', '23100..23499', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CL', 'Accrued Other', '26400..29999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'CL', 'Other Current Liabilities', '22400..23099|25400..26099', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'F4', 'Total Current Liabilities', 'CL', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', 'Long Term Liabilities', '', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'LTL', 'Notes Payable', '20000..21299', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'LTL', 'Other Long Term Liabilities', '21300..22099', 0, false, 0, '', '', '', '', false, false, true, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'F5', 'Total Long Term Liabilities', 'LTL', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'F6', 'Total Liabilities', 'F4+F5', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', 'Equity', '', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'E', 'Common Stock', '30000..30299', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'E', 'Retained Earnings', '30300..39999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'E', 'Current Year Earnings', '40000..99999', 0, false, 0, '', '', '', '', false, false, true, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'F7', 'Total Equity', 'E', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'F8', 'Total Liabilities and Equity', 'F6+F7', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        DoubleUnderscoreCurrentLine(XBSDETTxt);
        InsertDataNA(XBSDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XBSDETTxt, 'F9', 'Check Figure', 'F3+F8', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);

        // balance sheet summarized
        InsertDataNA(XBSSUMTxt, '1', 'Assets', '10000..19999', 0, false, 0, '', '', '', '', false, false, false, false, 1, 0);
        InsertDataNA(XBSSUMTxt, '2', 'Total Assets', '1', 2, false, 0, '', '', '', '', true, false, false, false, 1, 0);
        InsertDataNA(XBSSUMTxt, '3', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 1, 0);
        InsertDataNA(XBSSUMTxt, '4', 'Liabilities', '20000..29999', 0, false, 0, '', '', '', '', false, false, false, false, 1, 0);
        InsertDataNA(XBSSUMTxt, '5', 'Equity', '30000..39999|40000..99999', 0, false, 0, '', '', '', '', false, false, true, false, 1, 0);
        InsertDataNA(XBSSUMTxt, '6', 'Total Liabilities and Equity', '4+5', 2, false, 0, '', '', '', '', true, false, false, false, 1, 0);
        DoubleUnderscoreCurrentLine(XBSSUMTxt);
        InsertDataNA(XBSSUMTxt, '7', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 1, 0);
        InsertDataNA(XBSSUMTxt, '8', 'Check Figure', '2+6', 2, false, 0, '', '', '', '', false, false, false, false, 1, 0);

        // income statement detailed
        InsertDataNA(XISDETTxt, '', 'Revenue', '', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'R', 'Product Revenue', '40000..40209', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'R', 'Job Revenue', '40410..40429', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'R', 'Services Revenue', '40210..40309|40430..40909', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'R', 'Other Revenue', '40310..40409|40920..40939', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'R', 'Discounts and Returns', '40910..40919|40940..49999', 0, false, 0, '', '', '', '', false, false, true, false, 0, 0);
        InsertDataNA(XISDETTxt, 'F1', 'Total Revenue', 'R', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, '', 'Cost of Goods', '', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'C', 'Materials', '50000..50209', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'C', 'Labor', '50210..59999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'C', 'Manufacturing Overhead', '60000..69999', 0, false, 0, '', '', '', '', false, false, true, false, 0, 0);
        InsertDataNA(XISDETTxt, 'F2', 'Total Cost of Goods', 'C', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'F3', 'Gross Margin $', 'F1+F2', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'F4', 'Gross Margin %', 'F3/F1*100', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, '', 'Operating Expense', '', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'OE', 'Salaries and Wages', '70000..72109', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'OE', 'Employee Benefits', '72110..73299', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'OE', 'Employee Insurance', '73300..74109', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'OE', 'Employee Tax', '74110..79999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'OE', 'Depreciation', '80000..89999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'OE', 'Other Expense', '90000..99999', 0, false, 0, '', '', '', '', false, false, true, false, 0, 0);
        InsertDataNA(XISDETTxt, 'F5', 'Total Operating Expense', 'OE', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'F6', 'Net (Income) / Loss', 'F1+F2+F5', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        DoubleUnderscoreCurrentLine(XISDETTxt);
        InsertDataNA(XISDETTxt, '', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'F7', 'Total of Income Statement', '40000..99999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISDETTxt, 'F8', 'Check Figure', 'F6-F7', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);

        // income statement summarized
        InsertDataNA(XISSUMTxt, '1', 'Revenue', '40000..49999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISSUMTxt, '2', 'Cost of Goods', '50000..59999', 0, false, 0, '', '', '', '', false, false, true, false, 0, 0);
        InsertDataNA(XISSUMTxt, '3', 'Gross Margin', '1+2', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISSUMTxt, '4', 'Gross Margin %', '3/1*100', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XISSUMTxt, '5', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISSUMTxt, '6', 'Operating Expense', '60000..99999', 0, false, 0, '', '', '', '', false, false, true, false, 0, 0);
        InsertDataNA(XISSUMTxt, '7', 'Net (Income) / Loss', '1+2+6', 2, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        DoubleUnderscoreCurrentLine(XISSUMTxt);
        InsertDataNA(XISSUMTxt, '8', '', '', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISSUMTxt, '9', 'Total of Income Statement', '40000..99999', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XISSUMTxt, '10', 'Check Figure', '7-9', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);

        // trial balance
        InsertDataNA(XTBTxt, '11100', '11100 Development Expenditure', '11100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '11200', '11200 Tenancy, Site Leasehold and similar rights', '11200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '11300', '11300 Goodwill', '11300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '11400', '11400 Advanced Payments for Intangible Fixed Assets', '11400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '12110', '12110 Building', '12110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '12120', '12120 Cost of Improvements to Leased Property', '12120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '12130', '12130 Land ', '12130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '12210', '12210 Equipments and Tools', '12210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '12220', '12220 Computers', '12220', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '12230', '12230 Cars and other Transport Equipments', '12230', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '12240', '12240 Leased Assets', '12240', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '12900', '12900 Accumulated Depreciation', '12900', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '13100', '13100 Long-term Receivables ', '13100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '13200', '13200 Participation in Group Companies', '13200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '13300', '13300 Loans to Partners or related Parties', '13300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '13400', '13400 Deferred Tax Assets', '13400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '13500', '13500 Other Long-term Receivables', '13500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14100', '14100 Supplies and Consumables', '14100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14110', '14110 Raw Materials', '14110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14120', '14120 Products in Progress', '14120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14130', '14130 Finished Goods', '14130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14140', '14140 Goods for Resale', '14140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14160', '14160 Advanced Payments for goods and services', '14160', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14170', '14170 Other Inventory Items', '14170', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14210', '14210 Work in Progress, Finished Goods', '14210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14220', '14220 WIP Job Sales', '14220', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14230', '14230 WIP Job Costs', '14230', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14240', '14240 WIP, Accrued Costs', '14240', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '14250', '14250 WIP, Invoiced Sales', '14250', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15110', '15110 Account Receivable, Domestic', '15110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15120', '15120 Account Receivable, Foreign', '15120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15130', '15130 Contractual Receivables', '15130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15140', '15140 Consignment Receivables', '15140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15150', '15150 Credit cards and Vouchers Receivables', '15150', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15910', '15910 Current Receivable from Employees', '15910', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15920', '15920 Accrued income not yet invoiced', '15920', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15930', '15930 Clearing Accounts for Taxes and charges', '15930', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15940', '15940 Tax Assets', '15940', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '15950', '15950 Current Receivables from group companies', '15950', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '16100', '16100 Prepaid Rent', '16100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '16200', '16200 Prepaid Interest expense', '16200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '16300', '16300 Accrued Rental Income', '16300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '16400', '16400 Accrued Interest Income', '16400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '16500', '16500 Assets in the form of prepaid expenses', '16500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '16600', '16600 Other prepaid expenses and accrued income', '16600', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '17100', '17100 Bonds', '17100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '17200', '17200 Convertible debt instruments', '17200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '17300', '17300 Other short-term Investments', '17300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '17400', '17400 Write-down of Short-term investments', '17400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '18100', '18100 Petty Cash', '18100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '18200', '18200 Business account, Operating, Domestic', '18200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '18300', '18300 Business account, Operating, Foreign', '18300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '18400', '18400 Other bank accounts ', '18400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '18500', '18500 Certificate of Deposit', '18500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '21100', '21100 Bonds and Debenture Loans', '21100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '21200', '21200 Convertibles Loans', '21200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '21300', '21300 Other Long-term Liabilities', '21300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '21400', '21400 Bank overdraft Facilities', '21400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '22100', '22100 Accounts Payable, Domestic', '22100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '22200', '22200 Accounts Payable, Foreign', '22200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '22300', '22300 Advances from customers', '22300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '22400', '22400 Change in Work in Progress', '22400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '22500', '22500 Bank overdraft short-term', '22500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '22600', '22600 Other Liabilities', '22600', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '23100', '23100 Sales Tax Liable', '23100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '23200', '23200 Taxes Liable', '23200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '23300', '23300 Estimated Income Tax', '23300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '23500', '23500 Estimated Payroll tax on Pension Costs', '23500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '24100', '24100 Employees Withholding Taxes', '24100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '24200', '24200 Statutory Social security Contributions', '24200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '24300', '24300 Contractual Social security Contributions', '24300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '24400', '24400 Attachments of Earning', '24400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '24500', '24500 Holiday Pay fund', '24500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '24600', '24600 Other Salary/wage Deductions', '24600', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '25100', '25100 Clearing Account for Factoring, Current Portion', '25100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '25200', '25200 Current Liabilities to Employees', '25200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '25300', '25300 Clearing Account for third party', '25300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '25400', '25400 Current Loans', '25400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '25500', '25500 Liabilities, Grants Received ', '25500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '26100', '26100 Accrued wages/salaries', '26100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '26200', '26200 Accrued Holiday pay', '26200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '26300', '26300 Accrued Pension costs', '26300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '26400', '26400 Accrued Interest Expense', '26400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '26500', '26500 Deferred Income', '26500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '26600', '26600 Accrued Contractual costs', '26600', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '26700', '26700 Other Accrued Expenses and Deferred Income', '26700', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '30100', '30100 Equity Partner ', '30100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '30110', '30110 Net Results ', '30110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '30111', '30111 Restricted Equity ', '30111', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '30200', '30200 Share Capital ', '30200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '30210', '30210 Non-Restricted Equity', '30210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '30300', '30300 Profit or loss from the previous year', '30300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '30310', '30310 Results for the Financial year', '30310', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '30320', '30320 Distributions to Shareholders', '30320', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40110', '40110 Sale of Raw Materials', '40110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40130', '40130 Sale of Finished Goods', '40130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40140', '40140 Resale of Goods', '40140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40210', '40210 Sale of Resources', '40210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40220', '40220 Sale of Subcontracting', '40220', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40310', '40310 Income from securities', '40310', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40320', '40320 Management Fee Revenue', '40320', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40330', '40330 Interest Income', '40330', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40380', '40380 Currency Gains', '40380', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40390', '40390 Other Incidental Revenue', '40390', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40410', '40410 Job Sales', '40410', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40420', '40420 Job Sales Applied', '40420', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40430', '40430 Sales of Service Contracts', '40430', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40440', '40440 Sales of Service Work', '40440', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40910', '40910 Discounts and Allowances', '40910', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40920', '40920 Invoice Rounding', '40920', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40930', '40930 Payment Tolerance', '40930', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '40940', '40940 Sales Returns', '40940', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '50110', '50110 Cost of Materials', '50110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '50120', '50120 Cost of Materials, Projects', '50120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '50210', '50210 Cost of Labor', '50210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '50220', '50220 Cost of Labor, Projects', '50220', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '50230', '50230 Cost of Labor, Warranty/Contract', '50230', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '50400', '50400 Subcontracted work', '50400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '50500', '50500 Cost of Variances', '50500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60110', '60110 Rent / Leases', '60110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60120', '60120 Electricity for Rental', '60120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60130', '60130 Heating for Rental', '60130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60140', '60140 Water and Sewerage for Rental', '60140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60150', '60150 Cleaning and Waste for Rental', '60150', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60160', '60160 Repairs and Maintenance for Rental', '60160', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60170', '60170 Insurances, Rental', '60170', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60190', '60190 Other Rental Expenses', '60190', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60210', '60210 Site Fees / Leases', '60210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60220', '60220 Electricity for Property', '60220', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60230', '60230 Heating for Property', '60230', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60240', '60240 Water and Sewerage for Property', '60240', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60250', '60250 Cleaning and Waste for Property', '60250', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60260', '60260 Repairs and Maintenance for Property', '60260', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60270', '60270 Insurances, Property', '60270', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '60290', '60290 Other Property Expenses', '60290', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '61100', '61100 Hire of machinery', '61100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '61200', '61200 Hire of computers', '61200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '61300', '61300 Hire of other fixed assets', '61300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62110', '62110 Passenger Car Costs', '62110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62120', '62120 Truck Costs', '62120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62190', '62190 Other vehicle expenses', '62190', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62210', '62210 Freight fees for goods', '62210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62220', '62220 Customs and forwarding', '62220', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62230', '62230 Freight fees, projects', '62230', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62310', '62310 Tickets', '62310', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62320', '62320 Rental vehicles', '62320', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62330', '62330 Board and lodging', '62330', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '62340', '62340 Other travel expenses', '62340', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63110', '63110 Advertisement Development', '63110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63120', '63120 Outdoor and Transportation Ads', '63120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63130', '63130 Ad matter and direct mailings', '63130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63140', '63140 Conference/Exhibition Sponsorship', '63140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63150', '63150 Samples, contests, gifts', '63150', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63160', '63160 Film, TV, radio, internet ads', '63160', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63170', '63170 PR and Agency Fees', '63170', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63190', '63190 Other advertising fees', '63190', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63210', '63210 Catalogs, price lists', '63210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63220', '63220 Trade Publications', '63220', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63410', '63410 Credit Card Charges', '63410', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63420', '63420 Business Entertaining, deductible', '63420', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '63430', '63430 Business Entertaining, nondeductible', '63430', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '64100', '64100 Office Supplies', '64100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '64200', '64200 Phone Services', '64200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '64300', '64300 Data services', '64300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '64400', '64400 Postal fees', '64400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '64500', '64500 Consumable/Expensible hardware', '64500', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '64600', '64600 Software and subscription fees', '64600', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '65100', '65100 Corporate Insurance', '65100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '65200', '65200 Damages Paid', '65200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '65300', '65300 Bad Debt Losses', '65300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '65400', '65400 Security services', '65400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '65900', '65900 Other risk expenses', '65900', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '66110', '66110 Remuneration to Directors', '66110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '66120', '66120 Management Fees', '66120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '66130', '66130 Annual/interrim Reports', '66130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '66140', '66140 Annual/general meeting', '66140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '66150', '66150 Audit and Audit Services', '66150', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '66160', '66160 Tax advisory Services', '66160', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '67100', '67100 Banking fees', '67100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '67200', '67200 Interest Expenses', '67200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '67300', '67300 Payable Invoice Rounding', '67300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68110', '68110 Accounting Services', '68110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68120', '68120 IT Services', '68120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68130', '68130 Media Services', '68130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68140', '68140 Consulting Services', '68140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68150', '68150 Legal Fees and Attorney Services', '68150', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68190', '68190 Other External Services', '68190', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68210', '68210 License Fees/Royalties', '68210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68220', '68220 Trademarks/Patents', '68220', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68230', '68230 Association Fees', '68230', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68280', '68280 Misc. external expenses', '68280', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '68290', '68290 Purchase Discounts', '68290', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '71100', '71100 Salaries', '71100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '71110', '71110 Hourly Wages', '71110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '71120', '71120 Overtime Wages', '71120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '71130', '71130 Bonuses', '71130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '71140', '71140 Commissions Paid', '71140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '71150', '71150 PTO Accrued', '71150', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '72110', '72110 Training Costs', '72110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '72120', '72120 Health Care Contributions', '72120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '72130', '72130 Entertainment of personnel', '72130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '72140', '72140 Allowances', '72140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '72150', '71250 Mandatory clothing expenses', '72150', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '72160', '72160 Other cash/remuneration benefits', '72160', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '72210', '72210 Pension fees and recurring costs', '72210', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '72220', '72220 Employer Contributions', '72220', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '73100', '73100 Health Insurance', '73100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '73200', '73200 Dental Insurance', '73200', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '73300', '73300 Worker''s Compensation', '73300', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '73400', '73400 Life Insurance', '73400', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '74110', '74110 Federal Withholding Expense', '74110', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '74120', '74120 FICA Expense', '74120', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '74130', '74130 FUTA Expense', '74130', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '74140', '74140 Medicare Expense', '74140', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '74190', '74190 Other Federal Expense', '74190', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '74410', '74410 State Withholding Expense', '74410', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '74420', '74420 SUTA Expense', '74420', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '81000', '81000 Depreciation, Land and Property', '81000', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '82000', '82000 Depreciation, Fixed Assets', '82000', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '91000', '91000 Currency Losses', '91000', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XTBTxt, '', 'Check Figure', '10000..99999', 2, false, 0, '', '', '', '', false, false, false, false, 0, 0);
    end;

    local procedure DoubleUnderscoreCurrentLine(AccScheduleNameCode: Code[10])
    var
        CurrentAccScheduleLine: Record "Acc. Schedule Line";
    begin
        CurrentAccScheduleLine.Get(AccScheduleNameCode, "Line No.");
        CurrentAccScheduleLine."Double Underline" := true;
        CurrentAccScheduleLine.Modify();
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
        "Acc. Schedule Line".Validate(Totaling, Totaling);
        "Acc. Schedule Line".Validate("Totaling Type", "Totaling Type");
        "Acc. Schedule Line".Validate("Dimension 1 Totaling", Dim1Totaling);
        "Acc. Schedule Line".Validate("Dimension 2 Totaling", Dim2Totaling);
        "Acc. Schedule Line".Validate("Dimension 3 Totaling", Dim3Totaling);
        "Acc. Schedule Line".Validate("Dimension 4 Totaling", Dim4Totaling);
        "Acc. Schedule Line"."Show Opposite Sign" := ShowOppositeSign;
        "Acc. Schedule Line".Bold := Bold;
        "Acc. Schedule Line".Insert();
    end;

    procedure InsertDataNA(ScheduleName: Code[10]; RowNo: Code[10]; Description: Text[80]; Totaling: Text[80]; TotalingType: Option "Posting Accounts","Total Accounts",Formula,Underline,"Double Underline","Set Base for Percent"; NewPage: Boolean; Show: Option Yes,No,"If Any Column Not Zero"; Dim1Totaling: Text[80]; Dim2Totaling: Text[80]; Dim3Totaling: Text[80]; Dim4Totaling: Text[80]; Bold: Boolean; Italic: Boolean; UnderLine: Boolean; ShowOppositeSign: Boolean; RowType: Option "Net Change","Balance at Date","Beginning Balance"; AmountType: Option "Net Amount","Debit Amount","Credit Amount")
    var
        CFAccSchedLine: Record "Acc. Schedule Line";
    begin
        InsertData(
          ScheduleName, RowNo, Description, Totaling, TotalingType,
          Dim1Totaling, Dim2Totaling, Dim3Totaling, Dim4Totaling, ShowOppositeSign, Bold);
        CFAccSchedLine.Get(ScheduleName, "Line No.");
        CFAccSchedLine.Validate("New Page", NewPage);
        CFAccSchedLine.Validate(Show, Show);
        CFAccSchedLine.Validate(Italic, Italic);
        CFAccSchedLine.Validate(Underline, UnderLine);
        CFAccSchedLine.Validate("Row Type", RowType);
        CFAccSchedLine.Validate("Amount Type", AmountType);
        CFAccSchedLine.Modify();
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
}
