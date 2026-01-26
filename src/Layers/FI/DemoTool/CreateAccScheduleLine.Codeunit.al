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
        InsertData(XBALANCE, '', XBALANCESHEET, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', uppercase(XAssets), '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XFixedAssets, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XIntangibleassets, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XFoundingcosts, '1000..1005', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XResearch, '1010..1015', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XDevelopment, '1020..1025', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XIntangiblerights, '1040..1045', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XGoodwill, '1060..1065', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOthercapitalisedexpenditure, '1050..1055', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAdvancepayments, '1070..1070', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XIntangibleassetstotal, '1089', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XTangibleassets, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XMachineryandequipment, '1200..1291', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOthertangibleassets, '1320..1328', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAdvancepaymentsandco, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XTangibleassetstotal, '1329', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XInvestments, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSharesinGroupcompanies, '1410', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XHoldingsinGroupcompanies, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSharesinassociatedcompanies, '1411', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XHoldingsinassociatedco, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOthersharesandholdings, '1415', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOtherinvestments, '1450..1490', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOwnshares, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XInvestmentstotal, '1499', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XFixedAssetstotal, '1500', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XCurrentAssets, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XInventory, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XItemsandsupplies, '1560', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XWIPAccount, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XFinishedGoods, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOtherinventories, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAdvancepayments, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XInventorytotal, '1590', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAccountsReceivable, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSalesreceivables, '1600', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XReceivablesofGroupcompanies, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XReceivablesofassociatedco, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XLoanes, '1620', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOtherreceivables, '1630', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSharesnotpaid, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAccruedincome, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSecurities, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSharesandparticipationsinGr, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOwnshares, '1884', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOthersharesandparticipation, '1887', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOthersecurities, '1890', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSecuritiestotal, '1891', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XLiquidAssets, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XLiquidassetstotal, '1979', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XCurrentAssetsTotal, '1988', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XASSETSTOTAL, '1989', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', uppercase(XLiabilities), '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XEQUITYCAPITAL, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSharecapitalandotherrest, '2000|2099', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSharepremiumaccount, '2009', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XRevaluationreserve, '2020', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XReserveforownshares, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOtherfunds, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XProfiLossbroughtfo, '2080', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XProfitLossforthefinancialy, '2090', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XEQUITYCAPITALTOTAL, '2100', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAPPROPRIATIONS, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XDepreciationdifference, '2200..2220', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XVoluntaryprovisions, '2240..2264', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAPPROPRIATIONSTOTAL, '2269', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XCOMPULSORYPROVISIONS, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XProvisionsforpensions, '2271', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XProvisionsfortaxation, '2275', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOtherprovisions, '2280..2290', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XCOMPULSORYPROVISIONSTOTAL, '2299', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XCREDITORS, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XDepentures, '2500', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XConvertibledepentures, '2510', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XLoansfromcreditinstitutions, '2530', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XPensionloans, '2570', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAdvancesreceived, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XTradecreditors, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XBillsofexchangepayable, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAmountsowedtogroupu, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAmountsowedtoparticip, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOthercreditors, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAccrualsanddeferredincome, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XCREDITORSTOTAL, '2995', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XLIABILITIESTOTAL, '2996', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XINCOMESTATEMENT, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XNETTURNOVER, '3679', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XVariationinstocksoffinis, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XWorkperformedbytheundert, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOtheroperatingincome, '3949', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XRawmaterialsandservices, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XRawmaterialsandconsumables, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XPurchasesduringthefinancia, '4000..4090', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XVariationinstocks, '4091..4098', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XExternalservices, '4100..4198', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XRawmaterialsandservicestot, '4998', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XStaffexpences, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XWagesandsalaries, '6000..6060', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XSocialsecurityexpenses, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XPensionexpenses, '6102..6108', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOthersocialsecurityexpenses, '6101|6110', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XStaffexpencestotal, '6000..6110', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XDepreciationandreductioni, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XDepreciationaccordingtoplan, '7010..7060', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XReductioninvalueofgoodshels, '7110..7160', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XExceptionalreductioninvalu, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XDepreciationandreductionin, '7499', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOtheroperatingcharges, '6115..6999', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOPERATINGPROFITLOSS, '7500', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XFinancialincomeandexpenses, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XShareofprofitofassociatedco, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XIncomefromgroupundertakings, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XIncomefromparticipatingint, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XIncomefromotherinvestmentsh, '8000', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOtherinterestandfinancialinc, '8200..8400', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XReductioninvalueofinvestmen, '8610', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XReductioninvalueofinvestme, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XInterestandotherfinancial, '8500..8609|8700..8910', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XFinancialincomeandexpense, '8000..8999', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XPROFILOSSBEFOREEXTRA, '9000', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XExtraordinaryitems, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XExtraordinaryincome, '9100..9290', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XExtraordinaryexpenses, '9300..9490', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XExtraordinaryitemstotal, '9499', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XPROFITLOSSBEFOREAPPRO, '9500', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XChangeindepreciationreserve, '9600..9660', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XChangeinuntaxedreserves, '9700..9760', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XAPPROPRIATIONSTOTAL, '9769', 1, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XIncometaxes, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XOtherdirecttaxes, '9880', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', XPROFITLOSSFORTHEFINANC, '3000..9999', 0, '', '', '', '', false, false);
        InsertData(XBALANCE, '', '', '', 0, '', '', '', '', false, false);
        //-JK MSFI NAVISION 4.0 FI

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
        XBALANCESHEET: Label 'BALANCE SHEET';
        XFixedAssets: Label 'Fixed Assets';
        XIntangibleassets: Label 'Intangible assets';
        XFoundingcosts: Label 'Founding costs';
        XResearch: Label 'Research';
        XDevelopment: Label 'Development';
        XIntangiblerights: Label 'Intangible rights';
        XGoodwill: Label 'Goodwill';
        XOthercapitalisedexpenditure: Label 'Other capitalised expenditure';
        XAdvancepayments: Label 'Advance payments';
        XIntangibleassetstotal: Label 'Intangible assets total';
        XTangibleassets: Label 'Tangible assets';
        XMachineryandequipment: Label 'Machinery and equipment';
        XOthertangibleassets: Label 'Other tangible assets';
        XAdvancepaymentsandco: Label 'Advance payments and construction in progress';
        XTangibleassetstotal: Label 'Tangible assets total';
        XInvestments: Label 'Investments';
        XSharesinGroupcompanies: Label 'Shares in Group companies';
        XHoldingsinGroupcompanies: Label 'Holdings in Group companies';
        XSharesinassociatedcompanies: Label 'Shares in associated companies';
        XHoldingsinassociatedco: Label 'Holdings in associated companies';
        XOthersharesandholdings: Label 'Other shares and holdings';
        XOtherinvestments: Label 'Other investments';
        XOwnshares: Label 'Own shares';
        XInvestmentstotal: Label 'Investments total';
        XFixedAssetstotal: Label 'Fixed Assets total';
        XItemsandsupplies: Label 'Items and supplies';
        XWIPAccount: Label 'WIP Account';
        XFinishedGoods: Label 'Finished Goods';
        XOtherinventories: Label 'Other inventories';
        XInventorytotal: Label 'Inventory total';
        XSalesreceivables: Label 'Sales receivables';
        XReceivablesofGroupcompanies: Label 'Receivables of Group companies';
        XReceivablesofassociatedco: Label 'Receivables of associated companies';
        XLoanes: Label 'Loanes';
        XOtherreceivables: Label 'Other receivables';
        XSharesnotpaid: Label 'Shares not paid';
        XAccruedincome: Label 'Accrued income';
        XSharesandparticipationsinGr: Label 'Shares and participations in Group companies';
        XOthersharesandparticipation: Label 'Other shares and participations';
        XOthersecurities: Label 'Other securities';
        XSecuritiestotal: Label 'Securities total';
        XLiquidassetstotal: Label 'Liquid assets total';
        XASSETSTOTAL: Label 'ASSETS TOTAL';
        XEQUITYCAPITAL: Label 'EQUITY CAPITAL';
        XSharecapitalandotherrest: Label 'Share capital and other restricted equity';
        XSharepremiumaccount: Label 'Share premium account';
        XRevaluationreserve: Label 'Revaluation reserve';
        XReserveforownshares: Label 'Reserve for own shares';
        XOtherfunds: Label 'Other funds';
        XProfiLossbroughtfo: Label 'Profit/Loss brought forward';
        XProfitLossforthefinancialy: Label 'Profit/Loss for the financial year';
        XEQUITYCAPITALTOTAL: Label 'EQUITY CAPITAL TOTAL';
        XAPPROPRIATIONS: Label 'APPROPRIATIONS';
        XDepreciationdifference: Label 'Depreciation difference';
        XVoluntaryprovisions: Label 'Voluntary provisions';
        XAPPROPRIATIONSTOTAL: Label 'APPROPRIATIONS TOTAL';
        XCOMPULSORYPROVISIONS: Label 'COMPULSORY PROVISIONS';
        XProvisionsforpensions: Label 'Provisions for pensions';
        XProvisionsfortaxation: Label 'Provisions for taxation';
        XOtherprovisions: Label 'Other provisions';
        XCOMPULSORYPROVISIONSTOTAL: Label 'COMPULSORY PROVISIONS TOTAL';
        XCREDITORS: Label 'CREDITORS';
        XDepentures: Label 'Depentures';
        XConvertibledepentures: Label 'Convertible depentures';
        XLoansfromcreditinstitutions: Label 'Loans from credit institutions';
        XPensionloans: Label 'Pension loans';
        XAdvancesreceived: Label 'Advances received';
        XTradecreditors: Label 'Trade creditors';
        XBillsofexchangepayable: Label 'Bills of exchange payable';
        XAmountsowedtogroupu: Label 'Amounts owed to group undertakings';
        XAmountsowedtoparticip: Label 'Amounts owed to participating interest undertakings';
        XOthercreditors: Label 'Other creditors';
        XAccrualsanddeferredincome: Label 'Accruals and deferred income';
        XCREDITORSTOTAL: Label 'CREDITORS TOTAL';
        XLIABILITIESTOTAL: Label 'LIABILITIES TOTAL';
        XINCOMESTATEMENT: Label 'INCOME STATEMENT';
        XNETTURNOVER: Label 'NET TURNOVER';
        XVariationinstocksoffinis: Label 'Variation in stocks of finished goods';
        XWorkperformedbytheundert: Label 'Work performed by the undertaking for its own purpose and capitalized';
        XOtheroperatingincome: Label 'Other operating income';
        XRawmaterialsandservices: Label 'Raw materials and services';
        XRawmaterialsandconsumables: Label 'Raw materials and consumables';
        XPurchasesduringthefinancia: Label 'Purchases during the financial year';
        XVariationinstocks: Label 'Variation in stocks';
        XExternalservices: Label 'External services';
        XRawmaterialsandservicestot: Label 'Raw materials and services total';
        XStaffexpences: Label 'Staff expences';
        XWagesandsalaries: Label 'Wages and salaries';
        XSocialsecurityexpenses: Label 'Social security expenses';
        XPensionexpenses: Label 'Pension expenses';
        XOthersocialsecurityexpenses: Label 'Other social security expenses';
        XStaffexpencestotal: Label 'Staff expences total';
        XDepreciationandreductioni: Label 'Depreciation and reduction in value';
        XDepreciationaccordingtoplan: Label 'Depreciation according to plan';
        XReductioninvalueofgoodshels: Label 'Reduction in value of goods hels as non-current assets';
        XExceptionalreductioninvalu: Label 'Exceptional reduction in value of current assets';
        XDepreciationandreductionin: Label 'Depreciation and reduction in value total';
        XOtheroperatingcharges: Label 'Other operating charges';
        XOPERATINGPROFITLOSS: Label 'OPERATING PROFIT (LOSS)';
        XFinancialincomeandexpenses: Label 'Financial income and expenses';
        XShareofprofitofassociatedco: Label 'Share of profit (loss) of associated companies';
        XIncomefromgroupundertakings: Label 'Income from group undertakings';
        XIncomefromparticipatingint: Label 'Income from participating interests';
        XIncomefromotherinvestmentsh: Label 'Income from other investments held as non-current assets';
        XOtherinterestandfinancialinc: Label 'Other interest and financial income';
        XReductioninvalueofinvestmen: Label 'Reduction in value of investments held as non-current assets';
        XReductioninvalueofinvestme: Label 'Reduction in value of investments held as current assets';
        XInterestandotherfinancial: Label 'Interest and other financial expenses';
        XFinancialincomeandexpense: Label 'Financial income and expenses total';
        XPROFILOSSBEFOREEXTRA: Label 'PROFIT (LOSS) BEFORE EXTRAORDINARY ITEMS';
        XExtraordinaryitems: Label 'Extraordinary items';
        XExtraordinaryincome: Label 'Extraordinary income';
        XExtraordinaryexpenses: Label 'Extraordinary expenses';
        XExtraordinaryitemstotal: Label 'Extraordinary items total';
        XPROFITLOSSBEFOREAPPRO: Label 'PROFIT (LOSS) BEFORE APPROPRIATIONS AND TAXES';
        XChangeindepreciationreserve: Label 'Change in depreciation reserve';
        XChangeinuntaxedreserves: Label 'Change in untaxed reserves';
        XIncometaxes: Label 'Income taxes';
        XOtherdirecttaxes: Label 'Other direct taxes';
        XPROFITLOSSFORTHEFINANC: Label 'PROFIT (LOSS) FOR THE FINANCIAL YEAR';
        XBALANCE: Label 'BALANCE';
        XACCCAT: Label 'ACC-CAT', Comment = 'ACC-CAT is the name of the Account Schedule.';
        XAssets: Label 'Assets';
        XLiabilities: Label 'Liabilities';
        XIncomeThisYear: Label 'Income This Year';
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

        InsertData(XACCCAT, '1000', XBALANCESHEET, '', 0, '', '', '', '', false, true);
        InsertData(XACCCAT, '1010', '', '', 0, '', '', '', '', false, false);
        InsertData(XACCCAT, '2000', uppercase(AssetsTxt), GLAccCatTotaling(GLAccountCategory."Account Category"::Assets, AssetsTxt), 10, '', '', '', '', false, true);
        InsertData(XACCCAT, '3000', LiabilitiesTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Liabilities, LiabilitiesTxt), 10, '', '', '', '', false, false);
        InsertData(XACCCAT, '4000', EquityTxt, GLAccCatTotaling(GLAccountCategory."Account Category"::Equity, EquityTxt), 10, '', '', '', '', false, false);
        InsertData(XACCCAT, '4010', XIncomeThisYear, CA.Convert('999999'), 1, '', '', '', '', false, false);
        InsertData(XACCCAT, '5000', uppercase(LiabilitiesTxt), '3000..4010', 2, '', '', '', '', false, true);
        InsertData(XACCCAT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XACCCAT, '6000', XINCOMESTATEMENT, '', 0, '', '', '', '', false, true);
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

        InsertData(XREVENUE, '', XREVENUE, '', 0, '', '', '', '', false, true);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '', XSalesofRetail, '', 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '11', XSalesRetailDom, CA.Convert('996110'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '12', XSalesRetailEU, CA.Convert('996120'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '13', XSalesRetailExport, CA.Convert('996130'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '14', XJobSalesAdjmtRetail, CA.Convert('996190'), 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '15', XSalesofRetailTotal, CA.Convert('996195'), 1, '', '', '', '', false, false);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);

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

