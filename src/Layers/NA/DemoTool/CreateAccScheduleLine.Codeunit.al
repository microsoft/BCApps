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
        InsertDataNA(XBALANCESH, '31', Text038, '30100', 0, false, 2, '', '', '', '', false, false, false, true, 2, 0);
        InsertDataNA(XBALANCESH, '32', Text039, '30200', 0, false, 2, '', '', '', '', false, false, false, true, 2, 0);
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
        InsertDataNA(uppercase(XIncome), '210', Text145, '61100', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(uppercase(XIncome), '220', Text146, '61200..61300', 0, false, 0, '', '', '', '', false, false, false, false, 2, 0);
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
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        GLAccountCategory: Record "G/L Account Category";
        "Line No.": Integer;
        "Previous Schedule Name": Code[10];
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
        XWIP: Label 'WIP';
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
        InsertDataNA(XREVENUE, '', XSalesofRetail, '', 0, false, 0, '', '', '', '', true, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '11', XSalesRetailDom, '44100', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '12', XSalesRetailEU, '', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '13', XSalesRetailExport, '44300', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '14', XJobSalesAdjmtRetail, '40250|40450', 0, false, 0, '', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '15', XSalesofRetailTotal, '11..14', 2, false, 0, '', '', '', '', true, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '', '', '', 0, false, 0, '', '', '', '', false, false, false, false, 0, 0);
        InsertDataNA(XREVENUE, '21', XRevenueArea10to55Total, '44100|44300|40250|40450', 0, false, 0, '10..55', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '22', XRevenueArea60to85Total, '44100|44300|40250|40450', 0, false, 0, '60..85', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '23', XRevenuenoAreacodeTotal, '44100|44300|40250|40450', 0, false, 0, '''''', '', '', '', false, false, false, true, 0, 0);
        InsertDataNA(XREVENUE, '24', XRevenueTotal, '21..23', 0, false, 0, '', '', '', '', true, false, false, true, 0, 0);

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

