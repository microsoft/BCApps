codeunit 101085 "Create Acc. Schedule Line"
{

    trigger OnRun()
    begin
        InsertData(XCAMPAIGN, '', XCAMPAIGNANALYSIS, '', 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XCAMPAIGN, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAMPAIGN, '11', XSalesRetailDom, '700000', 0, XSUMMER, '', '', '', true, false, false, 0, false);
        InsertData(XCAMPAIGN, '12', XPurchRetailDom, '604000', 0, XSUMMER, '', '', '', true, false, false, 0, false);
        InsertData(XCAMPAIGN, '1', XTradingMarginDomestic, '-12-11', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XCAMPAIGN, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAMPAIGN, '21', XSalesRetailEU, '700010', 0, XSUMMER, '', '', '', true, false, false, 0, false);
        InsertData(XCAMPAIGN, '22', XPurchRetailEU, '604010', 0, XSUMMER, '', '', '', true, false, false, 0, false);
        InsertData(XCAMPAIGN, '2', XTradingMarginEU, '-22-21', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XCAMPAIGN, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAMPAIGN, '31', XSalesRetailExport, '700020', 0, XSUMMER, '', '', '', true, false, false, 0, false);
        InsertData(XCAMPAIGN, '32', XPurchRetailExport, '604020', 0, XSUMMER, '', '', '', true, false, false, 0, false);
        InsertData(XCAMPAIGN, '3', XTradingMarginExport, '-32-31', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XCAMPAIGN, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAMPAIGN, '', XCampaignResult, '1+2+3', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XREVENUE, '', XREVENUE, '', 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '', XSalesofRetail, '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '11', XSalesRetailDom, '700000', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '12', XSalesRetailEU, '700010', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '13', XSalesRetailExport, '700020', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(
          XREVENUE, '', XRevenueArea10to30Total,
          StrSubstNo('%1..%2', '700000', '700020'), 0, '10..30', '', '', '', false, false, false, 0, false);
        InsertData(
          XREVENUE, '', XRevenueArea40to85Total,
          StrSubstNo('%1..%2', '700000', '700020'), 0, '40..85', '', '', '', false, false, false, 0, false);
        InsertData(
          XREVENUE, '', XRevenuenoAreacodeTotal,
          StrSubstNo('%1..%2', '700000', '700020'), 0, '''''', '', '', '', false, false, false, 0, false);
        InsertData(
          XREVENUE, '', XRevenueTotal,
          StrSubstNo('%1..%2', '700000', '700020'), 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, '', XRATIOS, '', 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', XLIQUIDITY, '', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, '1', XCurrentRatio, '(A29\58 - A29)/(L42\48 + L492\3)', 2, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, '2', XQuickRatio, '(A29\58 - A29 - A3)/(L42\48 + L492\3)', 2, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', XEFFICIENCY, '', 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, '3', XInventoryTurnoverYear, 'R60\61 / A3', 2, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '4', XCustomerCredit, '(A40 * 365) / (R70 + R71\74 + E9146)', 2, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, '5', XVendorCredit, '(L44 * 365) / (R60\61 + E9145)', 2, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', XPROFITABILITY, '', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, '6', XReturnOnEquity, 'R70\67 / L10', 2, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '7', XReturnOnAssets, 'R70\67 / A20\58', 2, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, '8', XDebtRatioLeverage, 'L10\49 / L10', 2, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', XSOLVENCY, '', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, '9', XDegreeOfFinancialIndependence, '(L10\15) / (L10\49 - L10\15)', 2, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '10', XCashFlowInRelationToTotalDebt, 'CF / (L10\49 - L10\15)', 2, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, true, 0, false);
        InsertData(XBALANCE, '', XBALANCESHEET, '', 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', uppercase(XAssets), '', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, 'A20\28', XFixedAssets, 'A20|A21|A22\27|A28', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, 'A20', XFormationExpenses, '200000..209999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A21', XIntangibleAssets, '210000..219999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A22\27', XTangibleAssets, '220000..279999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A28', XFinancialAssets, '280000..289999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A29\58', XCurrentAssets, 'A29|A3|A40\41|A50\53|A54\58|A490\1', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, 'A29', XReceivablesPlus1Year, '290000..299999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A3', XInventory, '300000..399999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A40\41', XReceivablesMinus1Year, 'A40|A41', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, 'A40', XTradeDebtors, '400000..409999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A41', XOtherAmountsReceivable, '410000..419999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A50\53', XInvestments, '500000..539999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A54\58', XLiquidAssets, '540000..589999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A490\1', XAdjustmentAccounts, '490000..491999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'A20\58', XTOTALASSETS, 'A20\28|A29\58', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', uppercase(XLiabilities), '', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, 'L10\15', XCapitalAndReserves, 'L10|L11|L12|L13|L14|L15|L16', 2, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, 'L10', XCapital, '100000..109999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L11', XSharePremiumAccount, '110000..119999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L12', XRevaluationSurpluses, '120000..129999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L13', XReserves, '130000..139999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L14', XAccumulatedProfitsLosses, '140000..149999|600000..799999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L15', XInvestmentGrants, '150000..159999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L16', XProvisionsLiabilitiesCharges, '160000..169999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L17\49', XCreditors, 'L17|L42\48|L492\3', 2, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, 'L17', XPayablesPlus1Year, '170000..179999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L42\48', XPayablesMinus1Year, 'L42|L43|L44|L45|L46|L47\48', 2, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, 'L42', XAmountsPayableAfterPlus1Year, '420000..429999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L43', XFinancialDebts, '430000..439999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L44', XTradeDebts, '440000..449999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L46', XAdvancesRcvdOrdersInProgress, '460000..469999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L45', XTaxesWagesAndSocialSecurity, '450000..459999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L47\48', XOtherAmountsPayable, '470000..489999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L492\3', XAdjustmentAccounts, '492000..499999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'L10\49', XTOTALLIABLITIES, 'L10\15|L17\49', 2, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, true, 0, false);
        InsertData(XBALANCE, '', XRESULTS, '', 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'R70', XTURNOVER, '700000..740999', 0, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, 'R60\61', XRawMatConsumGoodsForRelease, '60|61', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', XServicesAndOtherGoods, '', 0, '', '', '', '', false, false, false, 0, true);
        InsertData(XBALANCE, 'R70\61', XGROSSOPERATINGMARGINPosNeg, 'R70|R60\61', 2, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, 'R62', XRemunSocSecChargesAndPensions, '62', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'R630', XDeprOthAmtsWrittenOffFormExp, '630000..630999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', XIntangAndTangFixedAssets, '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'R631\4', XIncrDecrAmtsWrittOffStocksOrd, '631000..634999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, '', XProgressAndTradeDebtors, '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'R635\7', XProvisionsLiabilitiesCharges, '635000..635999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'R640\8', XOtherOperatingCharges, '640000..648999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'R649', XOperChrgsPstdToAssAsRestrExp, '649000..649999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'R71\74', XOtherOperatingIncome, '710000..749999', 0, '', '', '', '', true, false, false, 0, true);
        InsertData(
          XBALANCE, 'R70\64', XOPERATINGPROFITLOSS,
          'R70\61|R62|R630|R631\4|R635\7|R640\8|R649|R71\74', 2, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, 'R75', XFinancialIncome, '75', 1, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'R65', XFinancialCharges, '65', 1, '', '', '', '', false, false, false, 0, true);
        InsertData(XBALANCE, 'R70\65', XPROFITLOSSONORDINARYACTIV, 'R70\64|R75|R65', 2, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, '', XBEFORETAXES, '', 0, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, 'R76', XExtraordinaryIncome, '76', 1, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'R66', XExtraordinaryCharges, '66', 1, '', '', '', '', false, false, false, 0, true);
        InsertData(XBALANCE, 'R70\66', XPRETAXPROFITLOSSFORTHEPERIOD, 'R70\65|R76|R66', 2, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, 'R780', XTransferFromDeferredTaxes, '780000..780999', 0, '', '', '', '', true, false, false, 0, false);
        InsertData(XBALANCE, 'R680', XTransferToDeferredTaxes, '680000..680999', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XBALANCE, 'R67\77', XIncomeTaxes, '67|77', 1, '', '', '', '', false, false, false, 0, true);
        InsertData(XBALANCE, 'R70\67', XPROFITLOSSFORTHEPERIOD, 'R70\66|R780|R680|R67\77', 2, '', '', '', '', true, true, false, 0, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 1, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false, false, 1, false);
        InsertData(XBALANCE, '', XExtraInfoForCalculatingRatios, '', 0, '', '', '', '', false, false, false, 1, false);
        InsertData(XBALANCE, 'E9145', XVATRecoverable, '411000', 0, '', '', '', '', false, false, false, 1, false);
        InsertData(XBALANCE, 'E9146', XVATPayable, '451000', 0, '', '', '', '', true, false, false, 1, false);
        InsertData(XBALANCE, 'CF', XCASHFLOW, '-R70\67+R630+R631\4+R635\7', 2, '', '', '', '', false, false, false, 1, false);

        InsertData(XCASTAFF, '10', XPersonalCosts, '', 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCASTAFF, '20', XMonthlySalaries, CA.Convert('998710') + '..' + CA.Convert('998720'), 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCASTAFF, '40', XSocialSecurity, CA.Convert('998730') + '..' + CA.Convert('998730'), 6, '', '', '', '', false, false, false, 0, false);

        InsertData(XCATRANSFER, '100', XTransferOverheadCosts, '', 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCATRANSFER, '200', XInitialCostCenters, '9901', 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCATRANSFER, '300', XMainCostCenters, '9902', 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCATRANSFER, '500', XTotalTransfers, '200..300', 2, '', '', '', '', false, false, false, 0, false);

        InsertData(XCAPROF, '100', XCCCOSummaryReport, '', 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAPROF, '110', XRevenues, CA.Convert('996110') + '..' + CA.Convert('996955'), 7, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAPROF, '120', XRevenueReductions, CA.Convert('996710') + '..' + CA.Convert('996910'), 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAPROF, '130', XNetRevenue, '110..120', 2, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAPROF, '140', XMaterialCosts, CA.Convert('997110') + '..' + CA.Convert('997894'), 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAPROF, '160', XGrossProfit, '130..150', 2, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAPROF, '170', XSalaryDirectCosts, CA.Convert('998790'), 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAPROF, '300', XMainCostCenters, '9902', 6, '', '', '', '', false, false, false, 0, false);
        InsertData(XCAPROF, '500', XTotalTransfers, '200..300', 2, '', '', '', '', false, false, false, 0, false);

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
    end;

    var
        "Line No.": Integer;
        "Previous Schedule Name": Code[10];
        CA: Codeunit "Make Adjustments";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
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
        XBALANCE: Label 'BALANCE';
        XRATIOS: Label 'RATIOS';
        XLIQUIDITY: Label 'LIQUIDITY';
        XCurrentRatio: Label 'Current Ratio';
        XQuickRatio: Label 'Quick Ratio';
        XEFFICIENCY: Label 'EFFICIENCY';
        XInventoryTurnoverYear: Label 'Inventory Turnover (year)';
        XCustomerCredit: Label 'Customer Credit';
        XVendorCredit: Label 'Vendor Credit';
        XPROFITABILITY: Label 'PROFITABILITY';
        XReturnOnEquity: Label 'Return on Equity';
        XReturnOnAssets: Label 'Return on Assets';
        XDebtRatioLeverage: Label 'Debt Ratio (leverage)';
        XSOLVENCY: Label 'SOLVENCY';
        XDegreeOfFinancialIndependence: Label 'Degree of financial independence';
        XCashFlowInRelationToTotalDebt: Label 'Cash flow in relation to total debt';
        XBALANCESHEET: Label 'BALANCE SHEET';
        XFixedAssets: Label 'Fixed Assets';
        XFormationExpenses: Label 'Formation Expenses';
        XIntangibleAssets: Label 'Intangible Assets';
        XTangibleAssets: Label 'Tangible Assets';
        XReceivablesPlus1Year: Label 'Receivables +1 year';
        XReceivablesMinus1Year: Label 'Receivables -1 year';
        XTradeDebtors: Label 'Trade debtors';
        XOtherAmountsReceivable: Label 'Other amounts receivable';
        XAdjustmentAccounts: Label 'Adjustment Accounts';
        XTOTALASSETS: Label 'TOTAL ASSETS';
        XCapitalAndReserves: Label 'Capital and reserves';
        XCapital: Label 'Capital';
        XSharePremiumAccount: Label 'Share premium account';
        XRevaluationSurpluses: Label 'Revaluation surpluses';
        XReserves: Label 'Reserves';
        XAccumulatedProfitsLosses: Label 'Accumulated profits (losses)';
        XInvestmentGrants: Label 'Investment grants';
        XProvisionsLiabilitiesCharges: Label 'Provisions for liabilities and charges';
        XCreditors: Label 'Creditors';
        XPayablesPlus1Year: Label 'Payables +1 year';
        XPayablesMinus1Year: Label 'Payables -1 year';
        XAmountsPayableAfterPlus1Year: Label 'Current portion of amounts payable after more than one year';
        XFinancialDebts: Label 'Financial Debts';
        XTradeDebts: Label 'Trade Debts';
        XAdvancesRcvdOrdersInProgress: Label 'Advances received on orders in progress';
        XTaxesWagesAndSocialSecurity: Label 'Taxes, wages and social security';
        XOtherAmountsPayable: Label 'Other amounts payable';
        XTOTALLIABLITIES: Label 'TOTAL LIABLITIES';
        XRESULTS: Label 'RESULTS';
        XTURNOVER: Label 'TURNOVER';
        XRawMatConsumGoodsForRelease: Label 'Raw Materials, Consumables and Goods for Release';
        XServicesAndOtherGoods: Label 'Services and other Goods';
        XGROSSOPERATINGMARGINPosNeg: Label 'GROSS OPERATING MARGIN (positive/negative)';
        XRemunSocSecChargesAndPensions: Label 'Remuneration, social security charges and pensions';
        XDeprOthAmtsWrittenOffFormExp: Label 'Deprec. of and other amounts written off formation exp.';
        XIntangAndTangFixedAssets: Label 'intang. & tang. fixed assets';
        XIncrDecrAmtsWrittOffStocksOrd: Label 'Incr.(+), decr.(-) in amounts written off stocks, orders in';
        XProgressAndTradeDebtors: Label 'progress and trade debtors';
        XOtherOperatingCharges: Label 'Other operating charges';
        XOperChrgsPstdToAssAsRestrExp: Label 'Operating charges posted to assets as restruct. expenses';
        XOtherOperatingIncome: Label 'Other operating income';
        XOPERATINGPROFITLOSS: Label 'OPERATING PROFIT (LOSS)';
        XFinancialIncome: Label 'Financial Income';
        XFinancialCharges: Label 'Financial Charges';
        XPROFITLOSSONORDINARYACTIV: Label 'PROFIT (LOSS) ON ORDINARY ACTIVITIES';
        XBEFORETAXES: Label 'BEFORE TAXES';
        XExtraordinaryIncome: Label 'Extraordinary Income';
        XExtraordinaryCharges: Label 'Extraordinary Charges';
        XPRETAXPROFITLOSSFORTHEPERIOD: Label 'PRE-TAX PROFIT (LOSS) FOR THE PERIOD';
        XTransferFromDeferredTaxes: Label 'Transfer from deferred taxes';
        XTransferToDeferredTaxes: Label 'Transfer to deferred taxes';
        XIncomeTaxes: Label 'Income Taxes';
        XPROFITLOSSFORTHEPERIOD: Label 'PROFIT (LOSS) FOR THE PERIOD';
        XExtraInfoForCalculatingRatios: Label 'Extra information for calculating ratios';
        XVATRecoverable: Label 'VAT Recoverable';
        XVATPayable: Label 'VAT Payable';
        XACCCAT: Label 'ACC-CAT', Comment = 'ACC-CAT is the name of the Account Schedule.';
        XBALSHEET: Label 'BALANCE SHEET';
        XAssets: Label 'Assets';
        XLiabilities: Label 'Liabilities';
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

        InsertData(XACCCAT, '1000', XBALSHEET, '', 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XACCCAT, '1010', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XACCCAT, '2000', uppercase(AssetsTxt), GLAccCatTotaling(GLAccountCategory."Account Category"::Assets, AssetsTxt), 10, '', '', '', '', false, true, false, 0, false);
        InsertData(XACCCAT, '3000', LiabilitiesTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Liabilities, LiabilitiesTxt), 10, '', '', '', '', false, false, false, 0, false);
        InsertData(XACCCAT, '4000', EquityTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Equity, EquityTxt), 10, '', '', '', '', false, false, false, 0, false);
        InsertData(XACCCAT, '4010', XIncomeThisYear, CA.Convert('999999'), 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XACCCAT, '5000', uppercase(LiabilitiesTxt), '3000..4010', 2, '', '', '', '', false, true, false, 0, false);
        InsertData(XACCCAT, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XACCCAT, '6000', XIncomeStatement, '', 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XACCCAT, '7000', IncomeTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Income, IncomeTxt), 10, '', '', '', '', false, false, false, 0, false);
        InsertData(XACCCAT, '8000', CostOfGoodsSoldTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::"Cost of Goods Sold", CostOfGoodsSoldTxt), 10, '', '', '', '', false, false, false, 0, false);
        InsertData(XACCCAT, '9000', ExpenseTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Expense, ExpenseTxt), 10, '', '', '', '', false, false, false, 0, false);
        InsertData(XACCCAT, '9900', XNetIncome, '7000..9000', 2, '', '', '', '', false, true, false, 0, false);

        InsertData(XANALYSIS, '', XACIDTESTANALYSIS, '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '', XCurrentAssets, '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '101', XInventory, '3', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '102', XAccountsReceivable, '40', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '103', XSecurities, '52', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '104', XLiquidAssets, '55', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '105', XCurrentAssetsTotal, '101..104', 2, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '', XShorttermLiabilities, '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '111', XRevolvingCredit, '49', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '112', XAccountsPayable, '44', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '113', XVAT, '45', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '114', XPersonnelrelatedItems, '453', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '115', XOtherLiabilities, '47|48', 1, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '116', XShorttermLiabilitiesTotal, '111..115', 2, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XANALYSIS, '', XCurAminusShorttermLiabilities, '105|116', 2, '', '', '', '', false, false, false, 0, false);

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

        InsertData(XREVENUE, '', XREVENUE, '', 0, '', '', '', '', false, true, false, 0, false);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '', XSalesofRetail, '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '11', XSalesRetailDom, '700000', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '12', XSalesRetailEU, '700010', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '13', XSalesRetailExport, '700020', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false, false, 0, false);
        InsertData(
          XREVENUE, '', XRevenueArea10to30Total,
          StrSubstNo('%1..%2', '700000', '700020'), 0, '10..30', '', '', '', false, false, false, 0, false);
        InsertData(
          XREVENUE, '', XRevenueArea40to85Total,
          StrSubstNo('%1..%2', '700000', '700020'), 0, '40..85', '', '', '', false, false, false, 0, false);
        InsertData(
          XREVENUE, '', XRevenuenoAreacodeTotal,
          StrSubstNo('%1..%2', '700000', '700020'), 0, '''''', '', '', '', false, false, false, 0, false);
        InsertData(
          XREVENUE, '', XRevenueTotal,
          StrSubstNo('%1..%2', '700000', '700020'), 0, '', '', '', '', false, true, false, 0, false);
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

        InsertData(ScheduleName, RowNo, Description, Totaling, TotalingType, '', '', '', '', ShowOppositeSign, Bold, false, 0, false);

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

    procedure InsertData("Schedule Name": Code[10]; "Row No.": Code[10]; Description: Text[80]; Totaling: Text[80]; "Totaling Type": Option; Dim1Totaling: Text[80]; Dim2Totaling: Text[80]; Dim3Totaling: Text[80]; Dim4Totaling: Text[80]; ShowOppositeSign: Boolean; Bold: Boolean; NewPage: Boolean; ShowThisLine: Option; Underline: Boolean)
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
        "Acc. Schedule Line".Totaling := Totaling;
        "Acc. Schedule Line".Validate("Totaling Type", "Totaling Type");
        "Acc. Schedule Line".Validate("Dimension 1 Totaling", Dim1Totaling);
        "Acc. Schedule Line".Validate("Dimension 2 Totaling", Dim2Totaling);
        "Acc. Schedule Line".Validate("Dimension 3 Totaling", Dim3Totaling);
        "Acc. Schedule Line".Validate("Dimension 4 Totaling", Dim4Totaling);
        "Acc. Schedule Line"."Show Opposite Sign" := ShowOppositeSign;
        "Acc. Schedule Line".Bold := Bold;
        "Acc. Schedule Line"."New Page" := NewPage;
        "Acc. Schedule Line".Show := "Acc. Schedule Line Show".FromInteger(ShowThisLine);
        "Acc. Schedule Line".Underline := Underline;
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
}

