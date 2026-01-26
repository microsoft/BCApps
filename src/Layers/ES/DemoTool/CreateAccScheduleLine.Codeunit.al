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
        // InsertData(XREVENUE,'15',XSalesofRetailTotal,CA.Convert('996195'),1,'','','','',FALSE,FALSE);
        InsertData(XREVENUE, '15', XSalesofRetailTotal, CA.Convert('996190'), 1, '', '', '', '', false, false);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);
        // InsertData(
        //   XREVENUE,'',XRevenueArea10to30Total,
        //   STRSUBSTNO('%1..%2',CA.Convert('996110'),CA.Convert('996195')),0,'10..30','','','',FALSE,FALSE);
        // InsertData(
        //   XREVENUE,'',XRevenueArea40to85Total,
        //   STRSUBSTNO('%1..%2',CA.Convert('996110'),CA.Convert('996195')),0,'40..85','','','',FALSE,FALSE);
        // InsertData(
        //   XREVENUE,'',XRevenuenoAreacodeTotal,
        //   STRSUBSTNO('%1..%2',CA.Convert('996110'),CA.Convert('996195')),0,'''''','','','',FALSE,FALSE);
        // InsertData(
        //   XREVENUE,'',XRevenueTotal,
        //   STRSUBSTNO('%1..%2',CA.Convert('996110'),CA.Convert('996195')),0,'','','','',FALSE,TRUE);

        InsertData(
          XREVENUE, '', XRevenueArea10to30Total,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996190')), 0, '10..30', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueArea40to85Total,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996190')), 0, '40..85', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenuenoAreacodeTotal,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996190')), 0, '''''', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueTotal,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996190')), 0, '', '', '', '', false, true);

        InsertData(XCASTAFF, '10', XPersonalCosts, '', 6, '', '', '', '', false, false);
        //InsertData(XCASTAFF,'20',XMonthlySalaries,CA.Convert('998710') + '..' + CA.Convert('998720'),6,'','','','',FALSE,FALSE);
        //InsertData(XCASTAFF,'40',XSocialSecurity,CA.Convert('998730') + '..' + CA.Convert('998730'),6,'','','','',FALSE,FALSE);
        InsertData(XCASTAFF, '20', XSocialCosts, CA.Convert('640') + '..' + CA.Convert('641'), 6, '', '', '', '', false, false);
        InsertData(XCASTAFF, '40', XSocialSecurity, CA.Convert('642'), 6, '', '', '', '', false, false);
        InsertData(XCASTAFF, '50', XWagesAndSalaries, CA.Convert('643') + '|' + CA.Convert('649'), 6, '', '', '', '', false, false);

        InsertData(XCATRANSFER, '100', XTransferOverheadCosts, '', 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '200', XInitialCostCenters, '9901', 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '300', XMainCostCenters, '9902', 6, '', '', '', '', false, false);
        InsertData(XCATRANSFER, '500', XTotalTransfers, '200..300', 2, '', '', '', '', false, false);

        InsertData(XCAPROF, '100', XCCCOSummaryReport, '', 6, '', '', '', '', false, false);
        InsertData(XCAPROF, '110', XRevenues, CA.Convert('996110') + '..' + CA.Convert('996955'), 7, '', '', '', '', false, false);
        InsertData(XCAPROF, '120', XRevenueReductions, CA.Convert('708') + '|' + CA.Convert('709'), 7, '', '', '', '', false, false);
        InsertData(XCAPROF, '130', XNetRevenue, '110..120', 2, '', '', '', '', false, false);
        InsertData(XCAPROF, '140', XMaterialCosts, CA.Convert('997995') + '|' + CA.Convert('61'), 7, '', '', '', '', false, false);
        InsertData(XCAPROF, '160', XGrossProfit, '130..150', 2, '', '', '', '', false, false);
        InsertData(XCAPROF, '170', XSalaryDirectCosts, CA.Convert('998790'), 7, '', '', '', '', false, false);
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

        // *********************************************************************************************
        // Inserting PYG08-NOR...

        ID2(XPYG08NOR, '10000', '', XAINCOMEFROMCO, '', 2, false, 0, 2, 0, false, false);
        ID2(XPYG08NOR, '20000', 'A.1', X1BusinessTurnoverNA, 'A.1.a+A.1.b', 2, false, 0, 2, 3, false, false);
        ID2(XPYG08NOR, '30000', 'A.1.a', XaSales, '700|701|702|703|704|706|708|709', 1, false, 0, 2, 5, false, true);
        ID2(XPYG08NOR, '40000', 'A.1.b', XbRenderedServices, '705', 1, false, 0, 2, 5, false, true);
        ID2(XPYG08NOR, '50000', 'A.2', X2IncreaseDecreaseSOFGandMGP, '71|6930|7930', 1, false, 0, 2, 3, false, true);
        ID2(XPYG08NOR, '60000', 'A.3', X3WorkDonebyCompanyonFA, '73', 1, false, 0, 2, 3, false, true);
        ID2(XPYG08NOR, '70000', 'A.4', X4Consumables, 'A.4.a+A.4.b+A.4.c+A.4.d', 2, false, 0, 1, 3, false, false);
        ID2(XPYG08NOR, '80000', 'A.4.a', XaGoodsConsumption, '600|6060|6080|6090|610', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '90000', 'A.4.b', XbConsuptionRMandOtherExpMat, '601|602|6061|6062|6081|6082|6091|6092|611|612',
          1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '100000', 'A.4.c', XcExternalServicesdonebyOthCom, '607', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '110000', 'A.4.d', XdDeteriorationofGoodsRMandOC, '6931|7931|6932|7932|6933|7933', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '120000', 'A.5', X5OtherOperatingIncome, 'A.5.a+A.5.b', 2, false, 0, 2, 3, false, false);
        ID2(XPYG08NOR, '130000', 'A.5.a', XaAccessoryandOtherOperCurrInc, '75', 1, false, 0, 2, 5, false, true);
        ID2(XPYG08NOR, '140000', 'A.5.b', XbCurrentOperIncomeSubFinRes, '740|747', 1, false, 0, 2, 5, false, true);
        ID2(XPYG08NOR, '150000', 'A.6', X6PersonnelExpenses, 'A.6.a+A.6.b+A.6.c', 2, false, 0, 1, 3, false, false);
        ID2(XPYG08NOR, '160000', 'A.6.a', XaWagesandSalaries, '640|641|6450', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '170000', 'A.6.b', XbSocialSecurityContribut, '642|643|649', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '180000', 'A.6.c', XcProvisions, '644|6457|7950|7957', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '190000', 'A.7', X7OtherOperatingExpenses, 'A.7.a+A.7.b+A.7.c+A.7.d', 2, false, 0, 1, 3, false, false);
        ID2(XPYG08NOR, '200000', 'A.7.a', XaForeignServices, '62', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '210000', 'A.7.b', XbTax, '631|634|636|639', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '220000', 'A.7.c', XcLossesdeteriorationandchange, '650|694|695|794|7954', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '230000', 'A.7.d', XdOtherOperatingCurrExpenses, '651|659', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '240000', 'A.8', X8DeprandAmortofFA, '68', 1, false, 0, 1, 3, false, true);
        ID2(XPYG08NOR, '250000', 'A.9', X9CapitalSubventionandothers, '746', 1, false, 0, 2, 3, false, true);
        ID2(XPYG08NOR, '260000', 'A.10', X10ProvisionExcess, '7951|7952|7955|7956', 1, false, 0, 2, 3, false, true);
        ID2(XPYG08NOR, '270000', 'A.11', X11DeteriorationandSalesonFA, 'A.11.a+A.11.b', 2, false, 0, 2, 3, false, false);
        ID2(XPYG08NOR, '280000', 'A.11.a', XaDeteriorationandLosses, '690|691|692|790|791|792', 1, false, 0, 2, 5, false, true);
        ID2(XPYG08NOR, '290000', 'A.11.b', XFASaleandothers, '670|671|672|770|771|772', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '300000', 'A.1.TOT', XA1OPERATINGRESULTS, 'A.1+A.2+A.3+A.4+A.5+A.6+A.7+A.8+A.9+A.10+A.11', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08NOR, '310000', 'A.12', X12FinancialIncome, 'A.12.a+A.12.b', 2, true, 0, 2, 3, false, false);
        ID2(XPYG08NOR, '320000', 'A.12.a', XaIncomefromEquityInvest, 'A.12.a.a1+A.12.a.a2', 2, false, 0, 2, 5, false, false);
        ID2(XPYG08NOR, '330000', 'A.12.a.a1', Xa1InGroupandAssocCompanies, '7600|7601', 1, false, 0, 2, 7, false, true);
        ID2(XPYG08NOR, '340000', 'A.12.a.a2', Xa2InOtherCompanies, '7602|7603', 1, false, 0, 2, 7, false, true);
        ID2(XPYG08NOR, '350000', 'A.12.b', XbIncomefromOthTransfSecFARec, 'A.12.b.b1+A.12.b.b2', 2, false, 0, 2, 5, false, false);
        ID2(XPYG08NOR, '360000', 'A.12.b.b1', Xb1FromGroupandAssocCompanies, '7610|7611|76200|76201|76210|76211', 1, false, 0, 2, 7, false, true);
        ID2(XPYG08NOR, '370000', 'A.12.b.b2', Xb2FromOtherCompanies, '7612|7613|76202|76203|76212|76213|767|769', 1, false, 0, 2, 7, false, true);
        ID2(XPYG08NOR, '380000', 'A.13', X13FinancialExpenses, 'A.13.a+A.13.b+A.13.c', 2, false, 0, 1, 3, false, false);
        ID2(XPYG08NOR, '390000', 'A.13.a', XaDebtstoGroupandAssocComp, '6610|6611|6615|6616|6620|6621|6640|6641|6650|6651|6654|6655',
          1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '400000', 'A.13.b', XbDebtswithThirdParties, '6612|6613|6617|6618|6622|6623|6624|6642|6643|6652|6653|6656|6657|669',
          1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '410000', 'A.13.c', XcProvisionsupdate, '660', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '420000', 'A.14', X14ChangeinfairvalueinFinInst, 'A.14.a+A.14.b', 2, false, 0, 1, 3, false, false);
        ID2(XPYG08NOR, '430000', 'A.14.a', XaPortfolioandothers, '6630|6631|6633|7630|7631|7633', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '440000', 'A.14.b', XbFinancialAssetsforSalepartFR, '6632|7632', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '450000', 'A.15', X15RealizedLossesandGainsExch, '668|768', 1, false, 0, 1, 3, false, true);
        ID2(XPYG08NOR, '460000', 'A.16', X16DeteriorationwritesalesFIns, 'A.16.a+A.16.b', 2, false, 0, 1, 3, false, false);
        ID2(XPYG08NOR, '470000', 'A.16.a', XaDeteriorationandLosses, '696|697|698|699|796|797|798|799', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '480000', 'A.16.b', XbFixedAssetsSaleandothers, '666|667|673|675|766|773|775', 1, false, 0, 1, 5, false, true);
        ID2(XPYG08NOR, '490000', 'A.2.TOT', XA2FINANCIALRESULT, 'A.12+A.13+A.14+A.15+A.16', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08NOR, '500000', 'A.3.TOT', XA3RESULTBEFORETAXES, 'A.1.TOT+A.2.TOT', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08NOR, '510000', 'A.17', X17TaxesonProfit, '6300|6301|633|638', 1, false, 0, 1, 3, false, true);
        ID2(XPYG08NOR, '520000', 'A.4.TOT', XA4FISCALYEARRESULTFROMCO, 'A.3.TOT+A.17', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08NOR, '530000', '', XBINTERRUPTEDOPERATIONS, '', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08NOR, '540000', 'B.18', X18Fiscalyearresultfromintoper, '', 1, false, 0, 1, 3, false, false);
        ID2(XPYG08NOR, '550000', 'B.18.1', X181ExtrIncomeandExpenses, '678|778', 1, false, 0, 2, 3, false, true);
        ID2(XPYG08NOR, '560000', 'A.5.TOT', XA5FISCALYEARRESULT, 'A.4.TOT+B.18+B.18.1', 2, false, 0, 1, 0, false, false);


        // Inserting PYG08-ABR...

        ID2(XPYG08ABR, '10000', 'A.1', X1BusinessTurnoverNetAmount, '700|701|702|703|704|705|706|708|709', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08ABR, '20000', 'A.2', X2IncreaseDecreaseofStockonFG, '71|6930|7930', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08ABR, '30000', 'A.3', X3WorkDonebyCompanyonFA, '73', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08ABR, '40000', 'A.4', X4Consumables, '600|601|602|606|607|608|609|61|6931|6932|6932|6933|7931|7932|7933',
          1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '50000', 'A.5', X5OtherOperatingIncome, '740|747|75', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08ABR, '60000', 'A.6', X6PersonnelExpenses, '64|7950|7957', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '70000', 'A.7', X7OtherOperatingExpenses, '62|631|634|636|639|65|694|695|794|7954', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '80000', 'A.8', X8FixedAssetsDepreciation, '68', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '90000', 'A.9', X9CapitalSubventionsfromnfaoth, '746', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08ABR, '100000', 'A.10', X10ProvisionExcess, '7951|7952|7955|7956', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08ABR, '110000', 'A.11', X11DeteriorationandSalesonFA,
          '670|671|672|770|771|772|690|691|692|790|791|792', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '120000', 'A.TOT', XAOPERATINGRESULTS, 'A.1+A.2+A.3+A.4+A.5+A.6+A.7+A.8+A.9+A.10+A.11', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08ABR, '130000', 'B.12', X12FinancialIncome, '760|761|762|767|769', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08ABR, '140000', 'B.13', X13FinancialExpenses, '660|661|662|664|665|669', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '150000', 'B.14', X14ChangeinfairvalueinFInstr, '663|763', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '160000', 'B.15', X15RealizedLossesandGainsonExc, '668|768', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '170000', 'B.16', X16DeteriorationwriteoffsaleFI,
          '666|667|673|696|697|698|699|766|773|775|796|797|798|799', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '180000', 'B.TOT', XBFINANCIALRESULT, 'B.12+B.13+B.14+B.15+B.16', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08ABR, '190000', 'C.TOT', XCRESULTBEFORETAXES, 'A.TOT+B.TOT', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08ABR, '200000', 'C.17', X17TaxesonProfit, '6300|6301|633|638', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08ABR, '210000', 'C.18', X18ExtrIncomeandExpenses, '678|778', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08ABR, '220000', 'D.TOT', XDFISCALYEARRESULT, 'C.TOT+C.17+C.18', 2, false, 0, 1, 0, false, false);


        // Inserting PYG08-PYME...

        ID2(XPYG08PYME, '10000', 'A.1', X1BusinessTurnoverNetAmount, '700|701|702|703|704|705|706|708|709', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08PYME, '20000', 'A.2', X2IncreaseDecreaseofStockonFG, '71|6930|7930', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08PYME, '30000', 'A.3', X3WorkDonebyCompanyonFA, '73', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08PYME, '40000', 'A.4', X4Consumables, '600|601|602|606|607|608|609|61|6931|6932|6932|6933|7931|7932|7933',
          1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '50000', 'A.5', X5OtherOperatingIncome, '740|747|75', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08PYME, '60000', 'A.6', X6PersonnelExpenses, '64|7950|7957', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '70000', 'A.7', X7OtherOperatingExpenses, '62|631|634|636|639|65|694|695|794|7954', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '80000', 'A.8', X8FixedAssetsDepreciation, '68', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '90000', 'A.9', X9CapitalSubventionsfromnfaoth, '746', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08PYME, '100000', 'A.10', X10ProvisionExcess, '7951|7952|7955|7956', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08PYME, '110000', 'A.11', X11DeteriorationandSalesonFA,
          '670|671|672|770|771|772|690|691|692|790|791|792', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '120000', 'A.TOT', XAOPERATINGRESULTS, 'A.1+A.2+A.3+A.4+A.5+A.6+A.7+A.8+A.9+A.10+A.11', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08PYME, '130000', 'B.12', X12FinancialIncome, '760|761|762|767|769', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08PYME, '140000', 'B.13', X13FinancialExpenses, '660|661|662|664|665|669', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '150000', 'B.14', X14ChangeinfairvalueinFInstr, '663|763', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '160000', 'B.15', X15RealizedLossesandGainsonExc, '668|768', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '170000', 'B.16', X16DeteriorationwriteoffsaleFI,
          '666|667|673|696|697|698|699|766|773|775|796|797|798|799', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '180000', 'B.TOT', XBFINANCIALRESULT, 'B.12+B.13+B.14+B.15+B.16', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08PYME, '190000', 'C.TOT', XCRESULTBEFORETAXES, 'A.TOT+B.TOT', 2, false, 0, 1, 0, false, false);
        ID2(XPYG08PYME, '200000', 'C.17', X17TaxesonProfit, '6300|6301|633|638', 1, false, 0, 1, 0, false, true);
        ID2(XPYG08PYME, '210000', 'C.18', X18ExtrIncomeandExpenses, '678|778', 1, false, 0, 2, 0, false, true);
        ID2(XPYG08PYME, '220000', 'D.TOT', XDFISCALYEARRESULT, 'C.TOT+C.17+C.18', 2, false, 0, 1, 0, false, false);

        // Inserting BALNOR08...

        ID2(XBAL08NOR, '10000', '1', uppercase(XAssets), '', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08NOR, '20000', '1.A', XAFIXEDASSETS, '1.A.I+1.A.II+1.A.III+1.A.IV+1.A.V+1.A.VI', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08NOR, '30000', '1.A.I', XIIntangibleAssets, '1.A.I.1+1.A.I.2+1.A.I.3+1.A.I.4+1.A.I.5+1.A.I.6', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '40000', '1.A.I.1', X1DevelopmentCosts, '201|2801|2901', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '50000', '1.A.I.2', X2Concessions, '202|2802|2902', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '60000', '1.A.I.3', X3PatentsLicenseFeesTMandOth, '203|2803|2903', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '70000', '1.A.I.4', X4Goodwill, '204', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '80000', '1.A.I.5', X5EDPApplications, '206|2806|2906', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '90000', '1.A.I.6', X6Otherintangibleassets, '205|209|2805|2905', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '100000', '1.A.II', XIITangibleAssets, '1.A.II.1+1.A.II.2+1.A.II.3', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '110000', '1.A.II.1', X1LandandBuildings, '210|211|2811|2910|2911', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '120000', '1.A.II.2', X2IndMachineryandFandothta,
          '212|213|214|215|216|217|218|219|2812|2813|2814|2815|2816|2817|2818|2819|2912|2913|2914|2915|2916|2917|2918|2919',
          1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '130000', '1.A.II.3', X3FAinProgressandAdvances, '23', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '140000', '1.A.III', XIIIPropertiesinvestments, '1.A.III.1+1.A.III.2', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '150000', '1.A.III.1', X1Land, '220|2920', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '160000', '1.A.III.2', X2Buildings, '221|282|2921', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '170000', '1.A.IV', XIVGroupandAssocCompLTI, '1.A.IV.1+1.A.IV.2+1.A.IV.3+1.A.IV.4+1.A.IV.5', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '180000', '1.A.IV.1', X1LongTermCapitInstrum, '2403|2404|2493|2494|293', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '190000', '1.A.IV.2', X2LongTermLoansGroupandAC, '2423|2424|2953|2954', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '200000', '1.A.IV.3', X3LongTermDebtValues, '2413|2414|2943|2944', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '210000', '1.A.IV.4', X4Derivatives, '', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '220000', '1.A.IV.5', X5OtherFinancialAssets, '', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '230000', '1.A.V', XVLongTermInvestments, '1.A.V.1+1.A.V.2+1.A.V.3+1.A.V.4+1.A.V.5', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '240000', '1.A.V.1', X1LTCapitalInstruments, '2405|2495|250|259', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '250000', '1.A.V.2', X2LTLoanstoothers, '2425|252|253|254|2955|298', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '260000', '1.A.V.3', X3LTDebtValues, '2415|251|2945|297', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '270000', '1.A.V.4', X4Derivatives, '255', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '280000', '1.A.V.5', X5OtherFinancialAssets, '258|26', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '290000', '1.A.VI', XVIDeferredTaxAssets, '474', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '300000', '1.B', XBWORKINGASSETS, '1.B.I+1.B.II+1.B.III+1.B.IV+1.B.V+1.B.VI+1.B.VII', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08NOR, '310000', '1.B.I', XIFixedAssetsforSale, '580|581|582|583|584|599', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '320000', '1.B.II', XIIInventory, '1.B.II.1+1.B.II.2+1.B.II.3+1.B.II.4+1.B.II.5+1.B.II.6', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '330000', '1.B.II.1', X1StocksofGoodsPurchforResale, '30|390', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '340000', '1.B.II.2', X2RMandSuppliesandOthConsum, '31|32|391|392', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '350000', '1.B.II.3', X3ProductioninProgManufGoods, '33|34|393|394', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '360000', '1.B.II.4', X4FinishedGoods, '35|395', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '370000', '1.B.II.5', X5ByProductsorScrap, '36|396', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '380000', '1.B.II.6', X6AdvancestoVendors, '407', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '390000', '1.B.III', XIIIDebtors, '1.B.III.1+1.B.III.2+1.B.III.3+1.B.III.4+1.B.III.5+1.B.III.6+1.B.III.7',
          2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '400000', '1.B.III.1', X1TradeAccReconSalesandServ, '430|431|432|435|436|4935|437|490', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '410000', '1.B.III.2', X2GroupandAssocCompDebtors, '433|434|4933|4934', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '420000', '1.B.III.3', X3OtherDebtors, '44|5531|5533', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '430000', '1.B.III.4', X4Employees, '460|544', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '440000', '1.B.III.5', X5Assetsforcurrenttax, '4709', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '450000', '1.B.III.6', X6OthercreditswithGenGoverm, '4700|4708|471|472', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '460000', '1.B.III.7', X7ShareholderswithCallDueamts, '5580', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '470000', '1.B.IV', XIVGroupandACompSTInvestmts,
          '1.B.IV.1+1.B.IV.2+1.B.IV.3+1.B.IV.4+1.B.IV.5', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '480000', '1.B.IV.1', XSTCapitalInstruments, '5303|5304|5393|5394|593', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '490000', '1.B.IV.2', X2STLoanstoGroupandACompanies, '5323|5324|5343|5344|5953|5954', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '500000', '1.B.IV.3', X3ShortTermDebtValues, '5313|5314|5333|5334|5943|5944', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '510000', '1.B.IV.4', X4Derivatives, '', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '520000', '1.B.IV.5', X5OtherFinancialAssets, '5353|5354|5523|5524', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '530000', '1.B.V', XVShortTermInvestments, '1.B.V.1+1.B.V.2+1.B.V.3+1.B.V.4+1.B.V.5', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '540000', '1.B.V.1', X1ShortTermCapitalInstrum, '5305|540|5395|549', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '550000', '1.B.V.2', X2ShortTermLoanstoothers, '5325|5345|542|543|547|5955|598', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '560000', '1.B.V.3', X3ShortTermDebtValues, '5315|5335|541|546|5945|597', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '570000', '1.B.V.4', X4Derivatives, '5590|5593', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '580000', '1.B.V.5', X5OtherFinancialAssets, '5355|545|548|551|5525|565|566', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '590000', '1.B.VI', XVIChargestospreadoverperiod, '480|567', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '600000', '1.B.VII', XVIICashandothequivassets, '1.B.VII.1+1.B.VII.2', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08NOR, '610000', '1.B.VII.1', X1CashFlow, '570|571|572|573|574|575', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '620000', '1.B.VII.2', X2OtherEquivalentAssets, '576', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08NOR, '630000', '1.TOT', XTOTALASSETS, '1.A+1.B', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08NOR, '640000', '2', XCAPITALANDLIABILITIES, '', 2, true, 0, 4, 0, false, false);
        ID2(XBAL08NOR, '650000', '2.A', XACAPITAL, '2.A1+2.A2+2.A3', 2, false, 0, 4, 0, false, false);
        ID2(XBAL08NOR, '660000', '2.A1', XA1OWNFUNDS, '2.A1.I+2.A1.II+2.A1.III+2.A1.IV+2.A1.V+2.A1.VI+2.A1.VII+2.A1.VIII+2.A1.IX',
          2, false, 0, 4, 3, false, false);
        ID2(XBAL08NOR, '670000', '2.A1.I', XICapital, '2.A1.I.1+2.A1.I.2', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08NOR, '680000', '2.A1.I.1', X1SubscribedCapital, '100|101|102', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '690000', '2.A1.I.2', X2Capital, '1030|1040', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '700000', '2.A1.II', XIIPremium, '110', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '710000', '2.A1.III', XIIIReserves, '2.A1.III.1+2.A1.III.2', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08NOR, '720000', '2.A1.III.1', X1StatutoryReserves, '112|1141', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '730000', '2.A1.III.2', X2OtherReserves, '113|1140|1142|1143|115|119', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '740000', '2.A1.IV', XIVSharesandTradeinvestonCap, '108|109', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '750000', '2.A1.V', XVResultsfromPrevYear, '2.A1.V.1+2.A1.V.2', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08NOR, '760000', '2.A1.V.1', X1RetainedEarnings, '120', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '770000', '2.A1.V.2', X2AccumulatedLosses, '121', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '780000', '2.A1.VI', XVIOtherPartnerContrib, '118', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '790000', '2.A1.VII', XVIIProfitorLoss, '129|6|7', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '800000', '2.A1.VIII', XVIIIDividendsPaidonAcc, '557', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '810000', '2.A1.IX', XIXOtherCapitalInstruments, '111', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '820000', '2.A2', XA2ChangesinValueAdjustmnt, '2.A2.I+2.A2.II+2.A2.III', 2, false, 0, 4, 3, false, false);
        ID2(XBAL08NOR, '830000', '2.A2.I', XIFinancialinstrumentsonSale, '133', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '840000', '2.A2.II', XIICoverageOperations, '1340', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '850000', '2.A2.III', XIIIOthers, '137', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '860000', '2.A3', XA3Subventiongrantsandlegacies, '130|131|132', 1, false, 0, 4, 3, false, true);
        ID2(XBAL08NOR, '870000', '2.B', XBLIABILITIES, '2.B.I+2.B.II+2.B.III+2.B.IV+2.B.V', 2, false, 0, 4, 0, false, false);
        ID2(XBAL08NOR, '880000', '2.B.I', XILongTermProvisions, '2.B.I.1+2.B.I.2+2.B.I.3+2.B.I.4', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08NOR, '890000', '2.B.I.1', X1LTDebentureswithEmployees, '140', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '900000', '2.B.I.2', X2EnvironmentalActions, '145', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '910000', '2.B.I.3', X3Provforrestructuring, '146', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '920000', '2.B.I.4', X4OtherProvisions, '141|142|143|147', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '930000', '2.B.II', XIILongTermDebts, '2.B.II.1+2.B.II.2+2.B.II.3+2.B.II.4+2.B.II.5', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08NOR, '940000', '2.B.II.1', X1DebenturesandOthMarkSec, '177|178|179', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '950000', '2.B.II.2', X2DebtswithFinancialInstit, '1605|170', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '960000', '2.B.II.3', X3FinancialLeaseCreditors, '1625|174', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '970000', '2.B.II.4', X4Derivatives, '176', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '980000', '2.B.II.5', X5OtherLiabilities, '1615|1635|171|172|173|175|180|185|189', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '990000', '2.B.III', XIIILTDebtstoGroupandAssocComp,
          '1603|1604|1613|1614|1623|1624|1633|1634', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '1000000', '2.B.IV', XIVDeferredTaxLiabilities, '479', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '1010000', '2.B.V', XVLTChargestospreadoverperiods, '181', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '1020000', '2.C', XCCURRENTLIABILITIES, '2.C.I+2.C.II+2.C.III+2.C.IV+2.C.V+2.C.VI', 2, false, 0, 4, 0, false, false);
        ID2(XBAL08NOR, '1030000', '2.C.I', XILiabilitiesrelatedtoassonsal, '585|586|587|588|589', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '1040000', '2.C.II', XIIShortTermProvisions, '499|529', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '1050000', '2.C.III', XIIIShortTermDebts,
          '2.C.III.1+2.C.III.2+2.C.III.3+2.C.III.4+2.C.III.5', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08NOR, '1060000', '2.C.III.1', X1DebentureandOthMarkSecurit, '500|501|505|506', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1070000', '2.C.III.2', X2DebtswithFinancialInstit, '5105|520|527', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1080000', '2.C.III.3', X3FinancialLeaseCreditors, '5125|524', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1090000', '2.C.III.4', X4Derivatives, '5595|5598', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1100000', '2.C.III.5', X5OtherLiabilities,
          '1034|1044|190|192|194|509|5115|5135|5145|521|522|523|525|526|528|551|5525|5530|5532|555|5565|5566|560|561|569',
          1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1110000', '2.C.IV', XIVSTDebtstoGroupandACompanies,
          '5103|5104|5113|5114|5123|5124|5133|5134|5143|5144|5523|5524|5563|5564', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '1120000', '2.C.V', XVTradeCreditors,
          '2.C.V.1+2.C.V.2+2.C.V.3+2.C.V.4+2.C.V.5+2.C.V.6+2.C.V.7', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08NOR, '1130000', '2.C.V.1', X1Vendors, '400|401|405|406', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1140000', '2.C.V.2', X2GroupandAssocCompCreditors, '403|404', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1150000', '2.C.V.3', X3OtherCreditors, '41', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1160000', '2.C.V.4', X4EmployeesRemunerationUnpaid, '465|466', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1170000', '2.C.V.5', X5Liabilitiesoncurrenttax, '4752', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1180000', '2.C.V.6', X6OtherdebtswithGeneralGovern, '4750|4751|4758|476|477', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1190000', '2.C.V.7', X7AdvancesfromCustomers, '438', 1, false, 0, 4, 7, false, true);
        ID2(XBAL08NOR, '1200000', '2.C.VI', XVIChargestospreadoverperiods, '485|568', 1, false, 0, 4, 5, false, true);
        ID2(XBAL08NOR, '1210000', '2.TOT', XTOTALCAPITALANDLIABILITIES, '2.A+2.B+2.C', 2, false, 0, 4, 0, false, false);


        // Inserting BALABR08...

        ID2(XBAL08ABR, '10000', '1', uppercase(XAssets), '', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08ABR, '20000', '1.A', XAFIXEDASSETS, '1.A.I+1.A.II+1.A.III+1.A.IV+1.A.V+1.A.VI', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08ABR, '30000', '1.A.I', XIIntangibleAssets, '20|280|290', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '40000', '1.A.II', XIITangibleAssets, '21|281|291|23', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '50000', '1.A.III', XIIIPropertiesinvestments, '22|282|292', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '60000', '1.A.IV', XIVGroupandAssocCompLTI, '2403|2404|2413|2414|2423|2424|2493|2494|293|2943|2944|2953|2954',
          1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '70000', '1.A.V', XVLongTermInvestments,
          '2405|2415|2425|2495|250|251|252|253|254|255|257|258|259|26|2945|2955|297|298', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '80000', '1.A.VI', XVIDeferredTaxAssets, '474', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '90000', '1.B', XBWORKINGASSETS, '1.B.I+1.B.II+1.B.III+1.B.IV+1.B.V+1.B.VI+1.B.VII', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08ABR, '100000', '1.B.I', XIFixedAssetsforSale, '580|581|582|583|584|599', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '110000', '1.B.II', XIIInventory, '30|31|32|33|34|35|36|39|407', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '120000', '1.B.III', XIIIDebtors, '1.B.III.1+1.B.III.2+1.B.III.3', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '130000', '1.B.III.1', X1TradeAccsReconSalesandServ,
          '430|431|433|434|435|436|437|490|493', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08ABR, '140000', '1.B.III.2', X2ShareholderwithCallDueAmts, '5580', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08ABR, '150000', '1.B.III.3', X3OtherDebtors, '44|460|470|471|472|5531|5533|544', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08ABR, '160000', '1.B.IV', XIVGroupandACompSTInvestmts,
          '5303|5304|5313|5314|5323|5324|5333|5334|5343|5344|5353|5354|5393|5394|5523|5524|593|5943|5944|5953|5954',
          1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '170000', '1.B.V', XVShortTermInvestments,
          '5305|5315|5325|5335|5345|5355|5395|540|541|542|543|545|546|547|548|549|551|5525|5590|5593|565|566|5945|5955|597|598',
          1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '180000', '1.B.VI', XVIChargestospreadoverperiod, '480|567', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '190000', '1.B.VII', XVIICashandothequivassets, '57', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08ABR, '200000', '1.TOT', XTOTALASSETS, '1.A+1.B', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08ABR, '210000', '2', XCAPITALANDLIABILITIES, '', 2, true, 0, 4, 0, false, false);
        ID2(XBAL08ABR, '220000', '2.A', XACAPITAL, '2.A1+2.A2+2.A3', 2, false, 0, 4, 0, false, false);
        ID2(XBAL08ABR, '230000', '2.A1', XA1OWNFUNDS, '2.A1.I+2.A1.II+2.A1.III+2.A1.IV+2.A1.V+2.A1.VI+2.A1.VII+2.A1.VIII+2.A1.IX',
          2, false, 0, 4, 3, false, false);
        ID2(XBAL08ABR, '240000', '2.A1.I', XICapital, '2.A1.I.1+2.A1.I.2', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '250000', '2.A1.I.1', X1SubscribedCapital, '100|101|102', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '260000', '2.A1.I.2', X2Capital, '1030|1040', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '270000', '2.A1.II', XIIPremium, '110', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '280000', '2.A1.III', XIIIReserves, '112|113|114|115|119', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '290000', '2.A1.IV', XIVSharesandTradeinvestonCap, '108|109', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '300000', '2.A1.V', XVResultsfromPrevYear, '120|121', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '310000', '2.A1.VI', XVIOtherPartnerContrib, '118', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '320000', '2.A1.VII', XVIIProfitorLoss, '129|6|7', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '330000', '2.A1.VIII', XVIIIDividendsPaidonAcc, '557', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '340000', '2.A1.IX', XIXOtherCapitalInstruments, '111', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '350000', '2.A2', XA2ChangesinValueAdjustmnt, '133|1340|137', 1, false, 0, 4, 3, false, false);
        ID2(XBAL08ABR, '360000', '2.A3', XA3Subventiongrantsandlegacies, '130|131|132', 1, false, 0, 4, 3, false, false);
        ID2(XBAL08ABR, '370000', '2.B', XBLIABILITIES, '2.B.I+2.B.II+2.B.III+2.B.IV+2.B.V', 2, false, 0, 4, 0, false, false);
        ID2(XBAL08ABR, '380000', '2.B.I', XILongTermProvisions, '14', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '390000', '2.B.II', XIILongTermDebts, '2.B.II.1+2.B.II.2+2.B.II.3', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '400000', '2.B.II.1', X1DebtswithFinancialInstit, '1605|170', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '410000', '2.B.II.2', X2FinancialLeaseCreditors, '1625|174', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '420000', '2.B.II.3', X3OtherLiabilities,
          '1615|1635|171|172|173|175|176|177|178|179|180|185|189', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '430000', '2.B.III', XIIILTDebtstoGroupandAssocComp,
          '1603|1604|1613|1614|1623|1624|1633|1634', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '440000', '2.B.IV', XIVDeferredTaxLiabilities, '479', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '450000', '2.B.V', XVLTChargestospreadoverperiods, '181', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '460000', '2.C', XCCURRENTLIABILITIES, '2.C.I+2.C.II+2.C.III+2.C.IV+2.C.V+2.C.VI', 2, false, 0, 4, 0, false, false);
        ID2(XBAL08ABR, '470000', '2.C.I', XILiabilitiesrelatedtoassonsal, '585|586|587|588|589', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '480000', '2.C.II', XIIShortTermProvisions, '499|529', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '490000', '2.C.III', XIIIShortTermDebts, '2.C.III.1+2.C.III.2+2.C.III.3', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '500000', '2.C.III.1', X1DebtswithFinancialInstit, '5105|520|527', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '510000', '2.C.III.2', X2FinancialLeaseCreditors, '5125|524', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '520000', '2.C.III.3', X3OtherLiabilities,
          '1034|1044|190|192|194|500|501|505|506|509|5115|5135|5145|521|522|523|525|' +
          '526|528|551|5525|5530|5532|555|5565|5566|5595|5598|560|561|569', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '530000', '2.C.IV', XIVSTDebtstoGroupandACompanies,
          '5103|5104|5113|5114|5123|5124|5133|5134|5143|5144|5523|5524|5563|5564', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '540000', '2.C.V', XVTradeCreditors, '2.C.V.1+2.C.V.2', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '550000', '2.C.V.1', X1Vendors, '400|401|403|404|405|406', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '560000', '2.C.V.2', X2OtherCreditors, '41|438|465|466|475|476|477', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08ABR, '570000', '2.C.VI', XVIChargestospreadoverperiods, '485|568', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08ABR, '580000', '2.TOT', XTOTALCAPITALANDLIABILITIES, '2.A+2.B+2.C', 2, false, 0, 4, 0, false, false);


        // Inserting BALPYME08...

        ID2(XBAL08PYME, '10000', '1', uppercase(XAssets), '', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08PYME, '20000', '1.A', XAFIXEDASSETS, '1.A.I+1.A.II+1.A.III+1.A.IV+1.A.V+1.A.VI', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08PYME, '30000', '1.A.I', XIIntangibleAssets, '20|280|290', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '40000', '1.A.II', XIITangibleAssets, '21|281|291|23', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '50000', '1.A.III', XIIIPropertiesinvestments, '22|282|292', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '60000', '1.A.IV', XIVGroupandAssocCompLTI, '2403|2404|2413|2414|2423|2424|2493|2494|293|2943|2944|2953|2954',
          1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '70000', '1.A.V', XVLongTermInvestments,
          '2405|2415|2425|2495|250|251|252|253|254|255|257|258|259|26|2945|2955|297|298', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '80000', '1.A.VI', XVIDeferredTaxAssets, '474', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '90000', '1.B', XBWORKINGASSETS, '1.B.I+1.B.II+1.B.III+1.B.IV+1.B.V+1.B.VI', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08PYME, '100000', '1.B.I', XIInventory, '30|31|32|33|34|35|36|39|407', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '110000', '1.B.II', XIIDebtors, '1.B.II.1+1.B.II.2+1.B.II.3', 2, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '120000', '1.B.II.1', X1TradeAccsReconSalesandServ,
          '430|431|433|434|435|436|437|490|493', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08PYME, '130000', '1.B.II.2', X2ShareholderwithCallDueAmts, '5580', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08PYME, '140000', '1.B.II.3', X3OtherDebtors, '44|460|470|471|472|5531|5533|544', 1, false, 0, 3, 5, false, false);
        ID2(XBAL08PYME, '150000', '1.B.III', XIIIGroupandACompSTInvestmts,
          '5303|5304|5313|5314|5323|5324|5333|5334|5343|5344|5353|5354|5393|5394|5523|5524|593|5943|5944|5953|5954',
          1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '160000', '1.B.IV', XIVShortTermInvestments,
          '5305|5315|5325|5335|5345|5355|5395|540|541|542|543|545|546|547|548|549|551|5525|5590|5593|565|566|5945|5955|597|598',
          1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '170000', '1.B.V', XVChargestospreadoverperiod, '480|567', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '180000', '1.B.VI', XVICashandothequivassets, '57', 1, false, 0, 3, 3, false, false);
        ID2(XBAL08PYME, '190000', '1.TOT', XTOTALASSETS, '1.A+1.B', 2, false, 0, 3, 0, false, false);
        ID2(XBAL08PYME, '200000', '2', XCAPITALANDLIABILITIES, '', 2, true, 0, 4, 0, false, false);
        ID2(XBAL08PYME, '210000', '2.A', XACAPITAL, '2.A1+2.A2', 2, false, 0, 4, 0, false, false);
        ID2(XBAL08PYME, '220000', '2.A1', XA1OWNFUNDS, '2.A1.I+2.A1.II+2.A1.III+2.A1.IV+2.A1.V+2.A1.VI+2.A1.VII+2.A1.VIII',
          2, false, 0, 4, 3, false, false);
        ID2(XBAL08PYME, '230000', '2.A1.I', XICapital, '2.A1.I.1+2.A1.I.2', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '240000', '2.A1.I.1', X1SubscribedCapital, '100|101|102', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '250000', '2.A1.I.2', X2Capital, '1030|1040', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '260000', '2.A1.II', XIIPremium, '110', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '270000', '2.A1.III', XIIIReserves, '112|113|114|115|119', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '280000', '2.A1.IV', XIVSharesandTradeinvestonCap, '108|109', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '290000', '2.A1.V', XVResultsfromPrevYear, '120|121', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '300000', '2.A1.VI', XVIOtherPartnerContrib, '118', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '310000', '2.A1.VII', XVIIProfitorLoss, '129|6|7', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '320000', '2.A1.VIII', XVIIIDividendsPaidonAcc, '557', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '330000', '2.A2', XA2ChangesinValueAdjustmnt, '133|1340|137', 1, false, 0, 4, 3, false, false);
        ID2(XBAL08PYME, '340000', '2.B', XBLIABILITIES, '2.B.I+2.B.II+2.B.III+2.B.IV+2.B.V', 2, false, 0, 4, 0, false, false);
        ID2(XBAL08PYME, '350000', '2.B.I', XILongTermProvisions, '14', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '360000', '2.B.II', XIILongTermDebts, '2.B.II.1+2.B.II.2+2.B.II.3', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '370000', '2.B.II.1', X1DebtswithFinancialInstit, '1605|170', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '380000', '2.B.II.2', X2FinancialLeaseCreditors, '1625|174', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '390000', '2.B.II.3', X3OtherLiabilities,
          '1615|1635|171|172|173|175|176|177|178|179|180|185|189', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '400000', '2.B.III', XIIILTDebtstoGroupandAssocComp,
          '1603|1604|1613|1614|1623|1624|1633|1634', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '410000', '2.B.IV', XIVDeferredTaxLiabilities, '479', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '420000', '2.B.V', XVLTChargestospreadoverperiods, '181', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '430000', '2.C', XCCURRENTLIABILITIES, '2.C.I+2.C.II+2.C.III+2.C.IV+2.C.V', 2, false, 0, 4, 0, false, false);
        ID2(XBAL08PYME, '440000', '2.C.I', XIShortTermProvisions, '499|529', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '450000', '2.C.II', XIIShortTermDebts, '2.C.II.1+2.C.II.2+2.C.II.3', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '460000', '2.C.II.1', X1DebtswithFinancialInstit, '5105|520|527', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '470000', '2.C.II.2', X2FinancialLeaseCreditors, '5125|524', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '480000', '2.C.II.3', X3OtherLiabilities,
          '1034|1044|190|192|194|500|501|505|506|509|5115|5135|5145|521|522|523|525|' +
          '526|528|551|5525|5530|5532|555|5565|5566|5595|5598|560|561|569', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '490000', '2.C.III', XIIISTDebtstoGroupandACompanie,
          '5103|5104|5113|5114|5123|5124|5133|5134|5143|5144|5523|5524|5563|5564', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '500000', '2.C.IV', XIVTradeCreditors, '2.C.IV.1+2.C.IV.2', 2, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '510000', '2.C.IV.1', X1Vendors, '400|401|403|404|405|406', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '520000', '2.C.IV.2', X2OtherCreditors, '41|438|465|466|475|476|477', 1, false, 0, 4, 7, false, false);
        ID2(XBAL08PYME, '530000', '2.C.V', XVChargestospreadoverperiods, '485|568', 1, false, 0, 4, 5, false, false);
        ID2(XBAL08PYME, '540000', '2.TOT', XTOTALCAPITALANDLIABILITIES, '2.A+2.B+2.C', 2, false, 0, 4, 0, false, false);


        // Inserting IG-NOR08...

        ID2(XIG08NOR, '10000', 'A.TOT', XALossesandGainsResult, '', 2, false, 0, 5, 0, false, false);
        ID2(XIG08NOR, '20000', '', XIncomeandExpenseallocasCapit, '', 2, false, 0, 5, 0, false, false);
        ID2(XIG08NOR, '30000', 'I', XIFromAssetsandLiabValuation, 'I.1+I.2', 2, false, 0, 5, 3, false, false);
        ID2(XIG08NOR, '40000', 'I.1', X1IncomeExpensesfromFAavailsol, '800|89|900|991|992', 1, false, 0, 5, 5, false, true);
        ID2(XIG08NOR, '50000', 'I.2', X2OtherIncomeExpenses, '', 1, false, 0, 5, 5, false, false);
        ID2(XIG08NOR, '60000', 'II', XIIFromCashFlowGuarantees, '810|910', 1, false, 0, 5, 3, false, true);
        ID2(XIG08NOR, '70000', 'III', XIIISubvGrantsandandLegacies, '94', 1, false, 0, 5, 3, false, true);
        ID2(XIG08NOR, '80000', 'IV', XIVGainsandLossesandothadjustm, '95|85', 1, false, 0, 5, 3, false, true);
        ID2(XIG08NOR, '90000', 'V', XVTaxeffect, '8300|8301|833|834|835|838', 1, false, 0, 5, 3, false, true);
        ID2(XIG08NOR, '100000', 'B.TOT', XTOTALINCOMEANDEXPENSESAAC, 'I+II+III+IV+V', 2, false, 0, 5, 0, false, false);
        ID2(XIG08NOR, '110000', '', XTransferstoLossesandGainsAcc, '', 1, false, 0, 5, 0, false, false);
        ID2(XIG08NOR, '120000', 'VI', XVIFromAssetsandLiabValuation, 'VI.1+VI.2', 2, false, 0, 5, 3, false, false);
        ID2(XIG08NOR, '130000', 'VI.1', X1IncomeExpensesfromFAavailsol, '802|902|993|994', 1, false, 0, 5, 5, false, true);
        ID2(XIG08NOR, '140000', 'VI.2', X2OtherIncomeExpenses, '', 1, false, 0, 5, 5, false, false);
        ID2(XIG08NOR, '150000', 'VII', XVIIFromCashFlowGuarantees, '812|912', 1, false, 0, 5, 3, false, true);
        ID2(XIG08NOR, '160000', 'VIII', XVIIISubvGrantsandLegacies, '84', 1, false, 0, 5, 3, false, true);
        ID2(XIG08NOR, '170000', 'IX', XIXTaxeffect, '8301|836|837', 1, false, 0, 5, 3, false, true);
        ID2(XIG08NOR, '180000', 'C.TOT', XTOTALTRANSFEREDTOLOSSESGACC, 'VI+VII+VIII+IX', 2, false, 0, 5, 0, false, false);
        ID2(XIG08NOR, '190000', 'TOT', XTOTALRECOGNIZEDINCOMEANDEXPEN, 'A.TOT+B.TOT+C.TOT', 2, false, 0, 5, 0, false, false);


        // Inserting IG-ABR08...

        ID2(XIG08ABR, '10000', 'A.TOT', XALossesandGainsResult, '', 2, false, 0, 5, 0, false, false);
        ID2(XIG08ABR, '20000', '', XIncomeandExpenseallocasCapit, '', 2, false, 0, 5, 0, false, false);
        ID2(XIG08ABR, '30000', 'I', XIFromAssetsandLiabValuation, '800|89|900|991|992', 1, false, 0, 5, 5, false, true);
        ID2(XIG08ABR, '40000', 'II', XIIFromCashFlowGuarantees, '810|910', 1, false, 0, 5, 5, false, true);
        ID2(XIG08ABR, '50000', 'III', XIIISubvGrantsandandLegacies, '94', 1, false, 0, 5, 5, false, true);
        ID2(XIG08ABR, '60000', 'IV', XIVGainsandLossesandothadjustm, '95|85', 1, false, 0, 5, 5, false, true);
        ID2(XIG08ABR, '70000', 'V', XVTaxeffect, '8300|8301|833|834|835|838', 1, false, 0, 5, 5, false, true);
        ID2(XIG08ABR, '80000', 'B.TOT', XTOTALINCOMEANDEXPENSESAAC, 'I+II+III+IV+V', 2, false, 0, 5, 0, false, false);
        ID2(XIG08ABR, '90000', '', XTransferstoLossesandGainsAcc, '', 1, false, 0, 5, 0, false, false);
        ID2(XIG08ABR, '100000', 'VI', XVIFromAssetsandLiabValuation, '802|902|993|994', 1, false, 0, 5, 5, false, true);
        ID2(XIG08ABR, '110000', 'VII', XVIIFromCashFlowGuarantees, '812|912', 1, false, 0, 5, 5, false, true);
        ID2(XIG08ABR, '120000', 'VIII', XVIIISubvGrantsandLegacies, '84', 1, false, 0, 5, 5, false, true);
        ID2(XIG08ABR, '130000', 'IX', XIXTaxeffect, '8301|836|837', 1, false, 0, 5, 5, false, true);
        ID2(XIG08ABR, '140000', 'C.TOT', XTOTALTRANSFEREDTOLOSSESGACC, 'VI+VII+VIII+IX', 2, false, 0, 5, 0, false, false);
        ID2(XIG08ABR, '150000', 'TOT', XTOTALRECOGNIZEDINCOMEANDEXPEN, 'A.TOT+B.TOT+C.TOT', 2, false, 0, 5, 0, false, false);


        // Inserting EFE08...

        ID3(XEFE08, '10000', 'A', XAOPERATINGACTCASHFLOW, '', 2, false, 0, 0, 0, false, false, 0);
        ID3(XEFE08, '20000', 'A1', X1FiscalYearResultBefTaxes, '', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '30000', 'A2', X2ResultAdjustments, 'A2A+A2B+A2C+A2D+A2E+A2F+A2G+A2H+A2I+A2J+A2K', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '40000', 'A2A', XaDepreciationAmortizofFA, '68', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '50000', 'A2B', XbValuecorrectionscausedbydet, '69|79', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '60000', 'A2C', XcChangesinprovisions, '14', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '70000', 'A2D', XdCapitalSubventions, '746|747', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '80000', 'A2E', XeFAsalesandlossesresults, '770|771|772|773|775', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '90000', 'A2F', XfFinInstrumsalesandlossesres, 'A2FAUX1 + A2FAUX2', 2, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '100000', 'A2FAUX1', '', '766', 1, false, 1, 0, 0, false, false, 0);
        ID3(XEFE08, '110000', 'A2FAUX2', '', '666', 1, false, 1, 0, 0, false, false, 0);
        ID3(XEFE08, '120000', 'A2G', XgFinancialIncome, 'A2GAUX1-A2FAUX1-A2IAUX1-A2JAUX1', 2, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '130000', 'A2GAUX1', '', '76', 1, false, 1, 0, 0, false, false, 0);
        ID3(XEFE08, '140000', 'A2H', XhFinancialexpenses, 'A2HAUX1-A2FAUX2-A2IAUX2-A2JAUX2', 2, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '150000', 'A2HAUX1', '', '66', 1, false, 1, 0, 0, false, false, 0);
        ID3(XEFE08, '160000', 'A2I', XiLossesandGainsonExchange, 'A2IAUX1+A2IAUX2', 2, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '170000', 'A2IAUX1', '', '768', 1, false, 1, 0, 0, false, false, 0);
        ID3(XEFE08, '180000', 'A2IAUX2', '', '668', 1, false, 1, 0, 0, false, false, 0);
        ID3(XEFE08, '190000', 'A2J', XjChangesinFairValueinFinInstr, 'A2JAUX1+A2JAUX2', 2, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '200000', 'A2JAUX1', '', '763', 1, false, 1, 0, 0, false, false, 0);
        ID3(XEFE08, '210000', 'A2JAUX2', '', '663', 1, false, 1, 0, 0, false, false, 0);
        ID3(XEFE08, '220000', 'A2K', XkOtherIncomeandexpenses, '', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '230000', 'A3', X3WorkingAssetChanges, 'A3A+A3B+A3C+A3D+A3E+A3F', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '240000', 'A3A', XaInventory, '3', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '250000', 'A3B', XbDebtors, '43|44|470|471|472|473|474', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '260000', 'A3C', XcOtherWorkingAssets, '460|480', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '270000', 'A3D', XdTradeCreditors, '40|41', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '280000', 'A3E', XeWorkingLiabilities, '465|466|475|476|477|479|485', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '290000', 'A3F', XfOtherworkingassetsandliabil, '', 1, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '300000', 'A4', X4OtherOperatingActCashFlow, 'A4A+A4B+A4C+A4D+A4E', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '310000', 'A4A', XaInterestpayments, 'A4AAUX1-A2H', 2, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '320000', 'A4AAUX1', '', '506|527|528', 1, false, 1, 0, 0, false, true, 0);
        ID3(XEFE08, '330000', 'A4B', XbDividendreceivables, '760|545', 1, false, 0, 0, 5, false, true, 0);
        ID3(XEFE08, '340000', 'A4C', XcInterestreceivables, 'A4CAUX1-A2G-A4CAUX2', 2, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '350000', 'A4CAUX1', '', '533|534', 1, false, 1, 0, 0, false, true, 0);
        ID3(XEFE08, '360000', 'A4CAUX2', '', '760', 1, false, 1, 0, 0, false, true, 0);
        ID3(XEFE08, '370000', 'A4D', XdProfitTaxReceivpayments, '630|4752|4709|473', 1, false, 0, 0, 5, false, true, 0);
        ID3(XEFE08, '380000', 'A4E', XeOtherpaymentsreceivables, '', 1, false, 0, 0, 5, false, true, 0);
        ID3(XEFE08, '390000', 'A5', X5OperatingactivitiesCashFlow, 'A1+A2+A3+A4', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '400000', 'B', XBINVESTMENTACTIVITIESCASHFLOW, '', 2, false, 0, 0, 0, false, false, 0);
        ID3(XEFE08, '410000', 'B6', X6Investmentpayments, 'B6A+B6B+B6C+B6D+B6E+B6F+B6G', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '420000', 'B6A', XaGroupandAssociatedCompanies, '24', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '430000', 'B6B', XbIntangibleAssets, '20', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '440000', 'B6C', XcTangibleAssets, '21|660|143', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '450000', 'B6D', XdPropertiesinvestments, '22', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '460000', 'B6E', XeOtherfinancialassets, '25|26', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '470000', 'B6F', XfNoncurrentassetsforsale, '58', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '480000', 'B6G', XgOtherassets, '', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '490000', 'B7', X7Divestmentsreceivables, 'B7A+B7B+B7C+B7D+B7E+B7F+B7G', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '500000', 'B7A', XaGroupandAssociatedCompanies, '24|673|773', 1, false, 0, 2, 5, false, false, 0);
        ID3(XEFE08, '510000', 'B7B', XbIntangibleAssets, '20|670|770|280', 1, false, 0, 2, 5, false, false, 0);
        ID3(XEFE08, '520000', 'B7C', XcTangibleAssets, '21|671|771|281', 1, false, 0, 2, 5, false, false, 0);
        ID3(XEFE08, '530000', 'B7D', XdPropertiesinvestments, '22|672|772|282', 1, false, 0, 2, 5, false, false, 0);
        ID3(XEFE08, '540000', 'B7E', XeOtherfinancialassets, '25|26', 1, false, 0, 2, 5, false, false, 0);
        ID3(XEFE08, '550000', 'B7F', XfNoncurrentassetsforsale, '58', 1, false, 0, 2, 5, false, false, 0);
        ID3(XEFE08, '560000', 'B7G', XgOtherassets, '', 1, false, 0, 2, 5, false, false, 0);
        ID3(XEFE08, '570000', 'B8', X8InvestmentActivitiesCashFlow, 'B7+B6', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '580000', 'C', XCFINANCINGACTIVITIESCASHFLOW, '', 2, false, 0, 0, 0, false, false, 0);
        ID3(XEFE08, '590000', 'C9', X9CapitalFinInstrreceivandpay, 'C9A+C9B+C9C+C9D+C9E', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '600000', 'C9A', XaCapitalFinancialInstrIssue, 'C9AAUX1+C9AAUX2', 2, false, 0, 0, 5, false, true, 0);
        ID3(XEFE08, '610000', 'C9AAUX1', '', '100|102', 1, false, 1, 2, 0, false, false, 0);
        ID3(XEFE08, '620000', 'C9AAUX2', '', '103|104', 1, false, 1, 0, 0, false, true, 0);
        ID3(XEFE08, '630000', 'C9B', XbCapitalFinInstrDepreciation, '100|102', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '640000', 'C9C', XcCapitalFinInstrPurchase, '108|109', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '650000', 'C9D', XdCapitalFinInstrSale, '108|109', 1, false, 0, 2, 5, false, false, 0);
        ID3(XEFE08, '660000', 'C9E', XeReceivedSubvAndGrants, '130|131|132', 1, false, 0, 0, 5, false, true, 0);
        ID3(XEFE08, '670000', 'C10', X10FinLiabInstrReceivandPaymts, 'C10A+C10B', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '680000', 'C10A', XaIssue, 'C10A1+C10A2+C10A3+C10A4', 2, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '690000', 'C10A1', X1ObligandotherMarketableSec, '150|153|154|177|178|179|500|501|502|505', 1, false, 0, 2, 7, false, false, 0);
        ID3(XEFE08, '700000', 'C10A2', X2LoansfromFinInstitutions, '170|520|174|524', 1, false, 0, 2, 7, false, false, 0);
        ID3(XEFE08, '710000', 'C10A3', X3DebtswithGroupandAssocComp, '16|51', 1, false, 0, 2, 7, false, false, 0);
        ID3(XEFE08, '720000', 'C10A4', X4Otherdebts, '171|172|173|175|176|18|521|522|523|525|526|527|528|529|560|561|565|569',
          1, false, 0, 2, 7, false, false, 0);
        ID3(XEFE08, '730000', 'C10B', XbRefundsandDepreciations, 'C10B1+C10B2+C10B3+C10B4', 2, false, 0, 0, 5, false, false, 0);
        ID3(XEFE08, '740000', 'C10B1', X1ObligationsandOthMarkSec, '150|153|154|177|178|179|500|501|502|505', 1, false, 0, 1, 7, false, true, 0);
        ID3(XEFE08, '750000', 'C10B2', X2LoansfromFinInstitutions, '170|520|174|524', 1, false, 0, 1, 7, false, true, 0);
        ID3(XEFE08, '760000', 'C10B3', X3DebtswithGroupandAssocComp, '16|51', 1, false, 0, 1, 7, false, true, 0);
        ID3(XEFE08, '770000', 'C10B4', X4Otherdebts, '171|172|173|175|176|18|521|522|523|525|526|527|528|529|560|561|565|569',
          1, false, 0, 1, 7, false, true, 0);
        ID3(XEFE08, '780000', 'C11', X11OtherCapitalFinInstrDivPRem, 'C11A+C11B', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '790000', 'C11A', XaDividends, '526', 1, false, 0, 1, 5, false, true, 0);
        ID3(XEFE08, '800000', 'C11B', XbOtherCapFinInstrRemuneration, '664', 1, false, 0, 0, 5, false, true, 0);
        ID3(XEFE08, '810000', 'C12', X12FinActivitiesCashFlow, 'C9+C10-C11', 2, false, 0, 0, 3, false, false, 0);
        ID3(XEFE08, '820000', 'D', XDChangesinExchRatesEffects, '82|92', 1, false, 0, 0, 0, false, false, 0);
        ID3(XEFE08, '830000', 'E', XECASHFLOWANDEQUIVNETINCDEC, 'A5+B8+C12+D', 2, false, 0, 0, 0, false, false, 0);
        ID3(XEFE08, '840000', 'E1', XCashandsimilarbeginningFY, '57', 1, false, 0, 0, 2, false, false, 2);
        ID3(XEFE08, '850000', 'E2', XCashandsimilarendFY, '57', 1, false, 0, 0, 0, false, false, 0);
    end;

    var
        "Line No.": Integer;
        "Previous Schedule Name": Code[10];
        CA: Codeunit "Make Adjustments";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        GLAccountCategory: Record "G/L Account Category";
        XANALYSIS: Label 'ANALYSIS';
        XEFE08: Label 'EFE08';
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
        XRevenuenoAreacodeTotal: Label 'Revenue, no Area code, Total';
        XRevenueTotal: Label 'Revenue, Total';
        XCAMPAIGN: Label 'CAMPAIGN';
        XSUMMER: Label 'SUMMER';
        XCASTAFF: Label 'CA-STAFF', Comment = 'Cost Acct. Personnel Costs.';
        XCATRANSFER: Label 'CA-TRANS', Comment = 'Cost Acct. Transfer.';
        XCAPROF: Label 'CA-PROF', Comment = 'Cost Acct. Summary Record DB per CC/CO.';
        XPersonalCosts: Label 'Personnel Costs';
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
        XPYG08NOR: Label 'PYG08-NOR';
        XPYG08ABR: Label 'PYG08-ABR';
        XPYG08PYME: Label 'PYG08-PYME';
        XBAL08NOR: Label 'BAL08-NOR';
        XBAL08ABR: Label 'BAL08-ABR';
        XBAL08PYME: Label 'BAL08-PYME';
        XIG08NOR: Label 'IG08-NOR';
        XIG08ABR: Label 'IG08-ABR';
        XAINCOMEFROMCO: Label 'A) INCOME FROM CONTINUING OPERATIONS';
        X1BusinessTurnoverNA: Label '1. Business Turnover Net Amount';
        XaSales: Label 'a) Sales';
        XbRenderedServices: Label 'b) Rendered Services';
        X2IncreaseDecreaseSOFGandMGP: Label '2. Increase/Decrease of Stocks on Finished Goods and Manufactured Goods-Production in Progress';
        X3WorkDonebyCompanyonFA: Label '3. Work Done by the Company on Fixed Assets';
        X4Consumables: Label '4. Consumables';
        XaGoodsConsumption: Label 'a) Goods Consumption';
        XbConsuptionRMandOtherExpMat: Label 'b) Consumption of Raw Materials and Other Expendable Materials';
        XcExternalServicesdonebyOthCom: Label 'c) External Services done by other Companies';
        XdDeteriorationofGoodsRMandOC: Label 'd) Deterioration of Goods, Raw Materials and Other Consumables';
        X5OtherOperatingIncome: Label '5. Other Operating Income';
        XaAccessoryandOtherOperCurrInc: Label 'a) Accessory and Other Operating Current Income';
        XbCurrentOperIncomeSubFinRes: Label 'b) Current operations income Subv. part of the Financial Result';
        X6PersonnelExpenses: Label '6. Personnel Expenses';
        XaWagesandSalaries: Label 'a) Wages and Salaries';
        XbSocialSecurityContribut: Label 'b) Social Security Contributions';
        XcProvisions: Label 'c) Provisions';
        X7OtherOperatingExpenses: Label '7. Other Operating Expenses';
        XaForeignServices: Label 'a) Foreign Services';
        XbTax: Label 'b) Tax';
        XcLossesdeteriorationandchange: Label 'c) Losses, deterioration and changes in provisions for sales operations';
        XdOtherOperatingCurrExpenses: Label 'd) Other Operating Current Expenses';
        X8DeprandAmortofFA: Label '8. Depreciation and Amortization of Fixed Assets';
        X9CapitalSubventionandothers: Label '9. Capital Subventions and others';
        X10ProvisionExcess: Label '10. Provision Excess';
        X11DeteriorationandSalesonFA: Label '11. Deterioration and Sales on Fixed Assets';
        XaDeteriorationandLosses: Label 'a) Deterioration and Losses';
        XFASaleandothers: Label 'b) Fixed Assets Sale and others';
        XA1OPERATINGRESULTS: Label 'A.1) OPERATING RESULTS';
        X12FinancialIncome: Label '12. Financial Income';
        XaIncomefromEquityInvest: Label 'a) Income from Equity Investment';
        Xa1InGroupandAssocCompanies: Label 'a1) In Group and Associated Companies';
        Xa2InOtherCompanies: Label 'a2) In Other Companies';
        XbIncomefromOthTransfSecFARec: Label 'b) Income from Other Transferable Securities and Fixed Asset Receivables';
        Xb1FromGroupandAssocCompanies: Label 'b1) From Group and Associated Companies';
        Xb2FromOtherCompanies: Label 'b2) From Other Companies';
        X13FinancialExpenses: Label '13. Financial Expenses';
        XaDebtstoGroupandAssocComp: Label 'a) Debts to Group and Associated Companies';
        XbDebtswithThirdParties: Label 'b) Debts with Third Parties';
        XcProvisionsupdate: Label 'c) Provisions update';
        X14ChangeinfairvalueinFinInst: Label '14. Change in fair value in Financial Instruments';
        XaPortfolioandothers: Label 'a) Portfolio and others';
        XbFinancialAssetsforSalepartFR: Label 'b) Financial Assets for Sale part of the Financial Result';
        X15RealizedLossesandGainsExch: Label '15. Realized Losses&Gains on Exchange';
        X16DeteriorationwritesalesFIns: Label '16. Deterioration, write off and sales of Financial Instruments';
        XbFixedAssetsSaleandothers: Label 'b) Fixed Assets Sale and others';
        XA2FINANCIALRESULT: Label 'A.2) FINANCIAL RESULT';
        XA3RESULTBEFORETAXES: Label 'A.3) RESULT BEFORE TAXES';
        X17TaxesonProfit: Label '17. Taxes on Profit';
        XA4FISCALYEARRESULTFROMCO: Label 'A.4) FISCAL YEAR RESULT FROM CONTINUING OPERATIONS';
        XBINTERRUPTEDOPERATIONS: Label 'B) INTERRUPTED OPERATIONS';
        X18Fiscalyearresultfromintoper: Label '18. Fiscal year result from interrupted operations';
        XA5FISCALYEARRESULT: Label 'A.5) FISCAL YEAR RESULT';
        X1BusinessTurnoverNetAmount: Label '1. Business Turnover Net Amount';
        X2IncreaseDecreaseofStockonFG: Label '2. Increase/Decrease of Stocks on Finished Goods and Manufactured Goods-Production in Progress';
        X8FixedAssetsDepreciation: Label '8. Fixed Assets Depreciation';
        X9CapitalSubventionsfromnfaoth: Label '9. Capital Subventions from non financial assets and others';
        XAOPERATINGRESULTS: Label 'A) OPERATING RESULTS';
        X14ChangeinfairvalueinFInstr: Label '14. Change in fair value in Financial Instruments';
        X15RealizedLossesandGainsonExc: Label '15. Realized Losses&Gains on Exchange';
        X16DeteriorationwriteoffsaleFI: Label '16. Deterioration, write off and sales of Financial Instruments';
        XBFINANCIALRESULT: Label 'B) FINANCIAL RESULT';
        XCRESULTBEFORETAXES: Label 'C) RESULT BEFORE TAXES';
        XDFISCALYEARRESULT: Label 'D) FISCAL YEAR RESULT';
        XAFIXEDASSETS: Label 'A) FIXED ASSETS';
        XIIntangibleAssets: Label 'I. Intangible Assets';
        X1DevelopmentCosts: Label '1. Development Costs';
        X2Concessions: Label '2.Concessions';
        X3PatentsLicenseFeesTMandOth: Label '3. Patents, License Fees, Trademarks and Others';
        X4Goodwill: Label '4. Goodwill';
        X5EDPApplications: Label '5. EDP Applications';
        X6Otherintangibleassets: Label '6. Other intangible assets';
        XIITangibleAssets: Label 'II. Tangible Assets';
        X1LandandBuildings: Label '1. Land and Buildings';
        X2IndMachineryandFandothta: Label '2. Industrial Machinery and Facilities and other tangible assets';
        X3FAinProgressandAdvances: Label '3. Fixed Assets in Progress and Advances';
        XIIIPropertiesinvestments: Label 'III. Properties investments';
        X1Land: Label '1. Land  ';
        X2Buildings: Label '2. Buildings';
        XIVGroupandAssocCompLTI: Label 'IV. Group and Assoc. Companies Long Term Investments';
        X1LongTermCapitInstrum: Label '1. Long Term Capital Instruments';
        X2LongTermLoansGroupandAC: Label '2. Long Term Loans to Group and Asoc. Companies';
        X3LongTermDebtValues: Label '3. Long Term Debt Values';
        X4Derivatives: Label '4. Derivatives';
        X5OtherFinancialAssets: Label '5. Other Financial Assets';
        XVLongTermInvestments: Label 'V. Long Term Investments';
        X1LTCapitalInstruments: Label '1. Long Term Capital Instruments';
        X2LTLoanstoothers: Label '2. Long Term Loans to others';
        X3LTDebtValues: Label '3. Long Term Debt Values';
        XVIDeferredTaxAssets: Label 'VI. Deferred Tax Assets';
        XBWORKINGASSETS: Label 'B) WORKING ASSETS';
        XIFixedAssetsforSale: Label 'I. Fixed Assets for Sale';
        XIIInventory: Label 'II. Inventory';
        X1StocksofGoodsPurchforResale: Label '1. Stocks of Goods Purchased for Resale';
        X2RMandSuppliesandOthConsum: Label '2. Raw Materials and Supplies and Other Consumables';
        X3ProductioninProgManufGoods: Label '3. Production in Progress-Manufactured Goods';
        X4FinishedGoods: Label '4. Finished Goods';
        X5ByProductsorScrap: Label '5. By Products or Scrap';
        X6AdvancestoVendors: Label '6. Advances to Vendors';
        XIIIDebtors: Label 'III. Debtors';
        X1TradeAccReconSalesandServ: Label '1. Trade Accounts Receivable on Sales and Services';
        X2GroupandAssocCompDebtors: Label '2. Group and Assoc. Companies, Debtors';
        X3OtherDebtors: Label '3. Other Debtors';
        X4Employees: Label '4. Employees';
        X5Assetsforcurrenttax: Label '5. Assets for current tax';
        X6OthercreditswithGenGoverm: Label '6. Other credits with General Government';
        X7ShareholderswithCallDueamts: Label '7. Shareholders with Callable Due amounts';
        XIVGroupandACompSTInvestmts: Label 'IV. Group and Assoc. Companies Short Term Investments';
        XSTCapitalInstruments: Label '1. Short Term Capital Instruments';
        X2STLoanstoGroupandACompanies: Label '2. Short Term Loans to Group and Asoc. Companies';
        X3ShortTermDebtValues: Label '3. Short Term Debt Values';
        XVShortTermInvestments: Label 'V. Short Term Investments';
        X1ShortTermCapitalInstrum: Label '1. Short Term Capital Instruments';
        X2ShortTermLoanstoothers: Label '2. Short Term Loans to others';
        XVIChargestospreadoverperiod: Label 'VI. Charges to be spread over several periods';
        XVIICashandothequivassets: Label 'VII. Cash and other equivalent assets';
        X1CashFlow: Label '1. Cash Flow';
        X2OtherEquivalentAssets: Label '2. Other Equivalent Assets';
        XTOTALASSETS: Label 'TOTAL ASSETS';
        XCAPITALANDLIABILITIES: Label 'CAPITAL AND LIABILITIES';
        XACAPITAL: Label 'A) CAPITAL';
        XA1OWNFUNDS: Label 'A-1) OWN FUNDS';
        XICapital: Label 'I. Capital';
        X1SubscribedCapital: Label '1. Subscribed Capital';
        X2Capital: Label '2. (Capital)';
        XIIPremium: Label 'II. Premium';
        XIIIReserves: Label 'III. Reserves';
        X1StatutoryReserves: Label '1. Statutory Reserves';
        X2OtherReserves: Label '2. Other Reserves';
        XIVSharesandTradeinvestonCap: Label 'IV. (Shares and Trade Investments on Capital)';
        XVResultsfromPrevYear: Label 'V. Results from Previous Years';
        X1RetainedEarnings: Label '1. Retained Earnings';
        X2AccumulatedLosses: Label '2. (Accumulated Losses)';
        XVIOtherPartnerContrib: Label 'VI. Other Partner Contributions';
        XVIIProfitorLoss: Label 'VII. Profit or Loss';
        XVIIIDividendsPaidonAcc: Label 'VIII. (Dividends Paid on Account)';
        XIXOtherCapitalInstruments: Label 'IX. Other Capital Instruments';
        XA2ChangesinValueAdjustmnt: Label 'A-2) Changes in Value Adjustments';
        XIFinancialinstrumentsonSale: Label 'I. Financial instruments on Sale';
        XIICoverageOperations: Label 'II. Coverage Operations';
        XIIIOthers: Label 'III. Others';
        XA3Subventiongrantsandlegacies: Label 'A-3) Subventions, grants and legacies';
        XBLIABILITIES: Label 'B) LIABILITIES';
        XILongTermProvisions: Label 'I. Long Term Provisions';
        X1LTDebentureswithEmployees: Label '1. Long Term Debentures with Employees';
        X2EnvironmentalActions: Label '2. Environmental Actions';
        X3Provforrestructuring: Label '3. Provisions for restructuring';
        X4OtherProvisions: Label '4. Other Provisions';
        XIILongTermDebts: Label 'II. Long Term Debts';
        X1DebenturesandOthMarkSec: Label '1. Debentures and Other Marketable Securities';
        X2DebtswithFinancialInstit: Label '2. Debts with Financial Institutions';
        X3FinancialLeaseCreditors: Label '3. Financial Lease Creditors';
        X5OtherLiabilities: Label '5. Other Liabilities';
        XIIILTDebtstoGroupandAssocComp: Label 'III. Long Term Debts to Group and Associated Companies';
        XIVDeferredTaxLiabilities: Label 'IV. Deferred Tax Liabilities';
        XVLTChargestospreadoverperiods: Label 'V. Long Term Charges to be spread over several periods';
        XCCURRENTLIABILITIES: Label 'C) CURRENT LIABILITIES';
        XILiabilitiesrelatedtoassonsal: Label 'I. Liabilities related to assets on sale';
        XIIShortTermProvisions: Label 'II. Short Term Provisions';
        XIIIShortTermDebts: Label 'III. Short Term Debts';
        X1DebentureandOthMarkSecurit: Label '1. Debentures and Other Marketable Securities';
        XIVSTDebtstoGroupandACompanies: Label 'IV. Short Term Debts to Group and Associated Companies';
        XVTradeCreditors: Label 'V. Trade Creditors';
        X1Vendors: Label '1. Vendors';
        X2GroupandAssocCompCreditors: Label '2. Group and Assoc. Companies, Creditors';
        X3OtherCreditors: Label '3. Other Creditors';
        X4EmployeesRemunerationUnpaid: Label '4. Employees (Remunerations Unpaid)';
        X5Liabilitiesoncurrenttax: Label '5. Liabilities on current tax';
        X6OtherdebtswithGeneralGovern: Label '6. Other debts with General Government';
        X7AdvancesfromCustomers: Label '7. Advances from Customers';
        XVIChargestospreadoverperiods: Label 'VI. Charges to be Spread over Several Periods';
        XTOTALCAPITALANDLIABILITIES: Label 'TOTAL CAPITAL AND LIABILITIES';
        X1DebtswithFinancialInstit: Label '1. Debts with Financial Institutions';
        X2FinancialLeaseCreditors: Label '2. Financial Lease Creditors';
        X3OtherLiabilities: Label '3. Other Liabilities';
        X2OtherCreditors: Label '2. Other Creditors';
        XLIQUIDITYANALYSIS: Label 'LIQUIDITY ANALYSIS';
        XTATaxAuthority: Label 'T.A.(Tax Authority)';
        XCurrentAssetsminusStLiabilit: Label 'Current Assets minus Short-term Liabilities';
        XIIIGroupandACompSTInvestmts: Label 'III. Group and Assoc. Companies Short Term Investments';
        XIIISTDebtstoGroupandACompanie: Label 'III. Short Term Debts to Group and Associated Companies';
        XIVTradeCreditors: Label 'IV. Trade Creditors';
        XVChargestospreadoverperiods: Label 'V. Charges to be Spread over Several Periods';
        X1TradeAccsReconSalesandServ: Label '1. Trade Accounts Receivable on Sales and Services';
        X2ShareholderwithCallDueAmts: Label '2. Shareholders with Callable Due amounts';
        XIIDebtors: Label 'II. Debtors';
        XIInventory: Label 'I. Inventory';
        XIVShortTermInvestments: Label 'IV. Short Term Investments';
        XVChargestospreadoverperiod: Label 'V. Charges to be spread over several periods';
        XVICashandothequivassets: Label 'VI. Cash and other equivalent assets';
        XIShortTermProvisions: Label 'I. Short Term Provisions';
        XIIShortTermDebts: Label 'II. Short Term Debts';
        XALossesandGainsResult: Label 'A) Losses and Gains Result';
        XIncomeandExpenseallocasCapit: Label 'Income and Expenses allocated as Capital';
        XIFromAssetsandLiabValuation: Label 'I. From Assets and Liabilities Valuation';
        X1IncomeExpensesfromFAavailsol: Label '1. Income/Expenses from Financial Assets available to be sold';
        X2OtherIncomeExpenses: Label '2. Other Income/Expenses';
        XIIFromCashFlowGuarantees: Label 'II. From Cash Flow Guarantees';
        XIIISubvGrantsandandLegacies: Label 'III. Subv., Grants and Legacies';
        XIVGainsandLossesandothadjustm: Label 'IV. Gains and Losses and other adjustments';
        XVTaxeffect: Label 'V. Tax effect';
        XTOTALINCOMEANDEXPENSESAAC: Label 'TOTAL INCOME AND EXPENSES ALLOCATED AS CAPITAL';
        XTransferstoLossesandGainsAcc: Label 'Transfers to Losses and Gains Account';
        XVIFromAssetsandLiabValuation: Label 'VI. From Assets and Liabilities Valuation';
        XVIIFromCashFlowGuarantees: Label 'VII. From Cash Flow Guarantees';
        XVIIISubvGrantsandLegacies: Label 'VIII. Subv., Grants and Legacies';
        XIXTaxeffect: Label 'IX. Tax effect';
        XTOTALTRANSFEREDTOLOSSESGACC: Label 'TOTAL TRANSFERED TO LOSSES AND GAINS ACCOUNT';
        XTOTALRECOGNIZEDINCOMEANDEXPEN: Label 'TOTAL RECOGNIZED INCOME AND EXPENSES';
        XAOPERATINGACTCASHFLOW: Label 'A) OPERATING ACTIVITIES CASH FLOW';
        X1FiscalYearResultBefTaxes: Label '1. Fiscal Year Result before Taxes';
        X2ResultAdjustments: Label '2. Result Adjustments';
        XaDepreciationAmortizofFA: Label 'a) Depreciation and Amortization of Fixed Assets';
        XbValuecorrectionscausedbydet: Label 'b) Value corrections caused by det.';
        XcChangesinprovisions: Label 'c) Changes in provisions';
        XdCapitalSubventions: Label 'd) Capital Subventions';
        XeFAsalesandlossesresults: Label 'e) Fixed Assets sales and losses results';
        XfFinInstrumsalesandlossesres: Label 'f) Financial Instruments sales and losses results';
        XgFinancialIncome: Label 'g) Financial Income';
        XhFinancialexpenses: Label 'h) Financial expenses';
        XiLossesandGainsonExchange: Label 'i) Losses&Gains on Exchange';
        XjChangesinFairValueinFinInstr: Label 'j) Changes in Fair Value in Financial Instruments';
        XkOtherIncomeandexpenses: Label 'k) Other Income and expenses';
        X3WorkingAssetChanges: Label '3. Working Asset Changes';
        XaInventory: Label 'a) Inventory';
        XbDebtors: Label 'b) Debtors';
        XcOtherWorkingAssets: Label 'c) Other Working Assets';
        XdTradeCreditors: Label 'd) Trade Creditors';
        XeWorkingLiabilities: Label 'e) Working Liabilities';
        XfOtherworkingassetsandliabil: Label 'f) Other working assets and liabilities';
        X4OtherOperatingActCashFlow: Label '4. Other Operating Activities Cash Flow';
        XaInterestpayments: Label 'a) Interest payments';
        XbDividendreceivables: Label 'b) Dividend receivables';
        XcInterestreceivables: Label 'c) Interest receivables';
        XdProfitTaxReceivpayments: Label 'd) Profit Tax Receivables (payments)';
        XeOtherpaymentsreceivables: Label 'e) Other payments (receivables)';
        X5OperatingactivitiesCashFlow: Label '5. Operating activities Cash Flow';
        XBINVESTMENTACTIVITIESCASHFLOW: Label 'B) INVESTMENT ACTIVITIES CASH FLOW';
        X6Investmentpayments: Label '6. Investment payments';
        XaGroupandAssociatedCompanies: Label 'a) Group and Associated Companies';
        XbIntangibleAssets: Label 'b) Intangible Assets';
        XcTangibleAssets: Label 'c) Tangible Assets';
        XdPropertiesinvestments: Label 'd) Properties investments';
        XeOtherfinancialassets: Label 'e) Other financial assets';
        XfNoncurrentassetsforsale: Label 'f) Non current assets for sale';
        XgOtherassets: Label 'g) Other assets';
        X7Divestmentsreceivables: Label '7. Divestments receivables';
        X8InvestmentActivitiesCashFlow: Label '8. Investment Activities Cash Flow';
        XCFINANCINGACTIVITIESCASHFLOW: Label 'C) FINANCING ACTIVITIES CASH FLOW';
        X9CapitalFinInstrreceivandpay: Label '9. Capital Financial Instruments receivables and payments';
        XaCapitalFinancialInstrIssue: Label 'a) Capital Financial Instruments Issue';
        XbCapitalFinInstrDepreciation: Label 'b) Capital Fin. Instruments Depreciation';
        XcCapitalFinInstrPurchase: Label 'c) Capital Fin. Instruments Purchase';
        XdCapitalFinInstrSale: Label 'd) Capital Fin. Instruments Sale';
        XeReceivedSubvAndGrants: Label 'e) Received Subv. And Grants';
        X10FinLiabInstrReceivandPaymts: Label '10. Financial Liability Instruments Receivables and Payments';
        XaIssue: Label 'a) Issue';
        X1ObligandotherMarketableSec: Label '1. Obligations and other Marketable Securities';
        X2LoansfromFinInstitutions: Label '2. Loans from Financial Institutions';
        X3DebtswithGroupandAssocComp: Label '3. Debts with Group and Associated Companies';
        X4Otherdebts: Label '4. Other debts';
        XbRefundsandDepreciations: Label 'b) Refunds and Depreciations';
        X1ObligationsandOthMarkSec: Label '1. Obligations and other Marketable Securities';
        X11OtherCapitalFinInstrDivPRem: Label '11. Other Capital Financial Instruments Dividend Payments and Remunerations';
        XaDividends: Label 'a) Dividends';
        XbOtherCapFinInstrRemuneration: Label 'b) Other Capital Financial Instruments Remunerations';
        X12FinActivitiesCashFlow: Label '12. Financing Activities Cash Flow';
        XDChangesinExchRatesEffects: Label 'D) Changes in Exchange Rates Effects';
        XECASHFLOWANDEQUIVNETINCDEC: Label 'E) CASH FLOW AND EQUIVALENTS NET INCREASE/DECREASE';
        XCashandsimilarbeginningFY: Label 'Cash and similar at the beginning of the FY';
        XCashandsimilarendFY: Label 'Cash and similar at the end of the FY';
        X181ExtrIncomeandExpenses: Label '18.1 Extraordinary Income and Expenses';
        X18ExtrIncomeandExpenses: Label '18. Extraordinary Income and Expenses';
        XSocialCosts: Label 'Social Costs';
        XWagesAndSalaries: Label 'Wages and Salaries';
        XACCCAT: Label 'ACC-CAT', Comment = 'ACC-CAT is the name of the Account Schedule.';
        XBALSHEET: Label 'BALANCE SHEET';
        XAssets: Label 'Assets';
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

        InsertData(XANALYSIS, '', XLIQUIDITYANALYSIS, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', XCurrentAssets, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '101', XInventory, CA.Convert('3'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '102', XAccountsReceivable, CA.Convert('43') + '|' + CA.Convert('44'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '103', XSecurities, CA.Convert('50') + '|' + CA.Convert('53') + '|' + CA.Convert('54'), 1
          , '', '', '', '', false, false);
        InsertData(XANALYSIS, '104', XLiquidAssets, CA.Convert('57'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '105', XCurrentAssetsTotal, '101..104', 2, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', XShorttermLiabilities, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '111', XRevolvingCredit, CA.Convert('51') + '|' + CA.Convert('52') + '|' +
        CA.Convert('56') + '|' + CA.Convert('58') + '|' + CA.Convert('59'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '112', XAccountsPayable, CA.Convert('40'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '113', XTATaxAuthority, CA.Convert('47'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '114', XPersonnelrelatedItems, CA.Convert('46'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '115', XOtherLiabilities, CA.Convert('41'), 1, '', '', '', '', false, false);
        InsertData(XANALYSIS, '116', XShorttermLiabilitiesTotal, '111..115', 2, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', XCurrentAssetsminusStLiabilit, '105|116', 2, '', '', '', '', false, false);

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
        // InsertData(XREVENUE,'15',XSalesofRetailTotal,CA.Convert('996195'),1,'','','','',FALSE,FALSE);
        InsertData(XREVENUE, '15', XSalesofRetailTotal, CA.Convert('996190'), 1, '', '', '', '', false, false);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);
        // InsertData(
        //   XREVENUE,'',XRevenueArea10to30Total,
        //   STRSUBSTNO('%1..%2',CA.Convert('996110'),CA.Convert('996195')),0,'10..30','','','',FALSE,FALSE);
        // InsertData(
        //   XREVENUE,'',XRevenueArea40to85Total,
        //   STRSUBSTNO('%1..%2',CA.Convert('996110'),CA.Convert('996195')),0,'40..85','','','',FALSE,FALSE);
        // InsertData(
        //   XREVENUE,'',XRevenuenoAreacodeTotal,
        //   STRSUBSTNO('%1..%2',CA.Convert('996110'),CA.Convert('996195')),0,'''''','','','',FALSE,FALSE);
        // InsertData(
        //   XREVENUE,'',XRevenueTotal,
        //   STRSUBSTNO('%1..%2',CA.Convert('996110'),CA.Convert('996195')),0,'','','','',FALSE,TRUE);

        InsertData(
          XREVENUE, '', XRevenueArea10to30Total,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996190')), 0, '10..30', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueArea40to85Total,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996190')), 0, '40..85', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenuenoAreacodeTotal,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996190')), 0, '''''', '', '', '', false, false);
        InsertData(
          XREVENUE, '', XRevenueTotal,
          StrSubstNo('%1..%2', CA.Convert('996110'), CA.Convert('996190')), 0, '', '', '', '', false, true);

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

    procedure ID2(ScheduleName: Text[30]; LineNo: Text[30]; RowNo: Text[30]; Description: Text[250]; Totaling: Text[250]; TotalingType: Integer; NewPage: Boolean; Show: Integer; Type: Integer; Indentation: Integer; PositiveOnly: Boolean; ReverseSign: Boolean)
    var
        AccSchedLine: Record "Acc. Schedule Line";
    begin

        AccSchedLine.Init();
        AccSchedLine."Schedule Name" := ScheduleName;

        if "Previous Schedule Name" <> ScheduleName then begin
            "Line No." := 10000;
            "Previous Schedule Name" := ScheduleName;
        end else
            "Line No." := "Line No." + 10000;
        AccSchedLine.Validate("Line No.", "Line No.");
        AccSchedLine."Row No." := RowNo;
        AccSchedLine.Description := Description;
        AccSchedLine.Totaling := Totaling;
        AccSchedLine."Totaling Type" := "Acc. Schedule Line Totaling Type".FromInteger(TotalingType);
        AccSchedLine."New Page" := NewPage;
        AccSchedLine.Show := "Acc. Schedule Line Show".FromInteger(Show);
        AccSchedLine.Type := Type;
        AccSchedLine.Indentation := Indentation;
        AccSchedLine."Positive Only" := PositiveOnly;
        AccSchedLine."Reverse Sign" := ReverseSign;
        AccSchedLine.Insert();
    end;

    procedure ID3(ScheduleName: Text[30]; LineNo: Text[30]; RowNo: Text[30]; Description: Text[250]; Totaling: Text[250]; TotalingType: Integer; NewPage: Boolean; Show: Integer; AmountType: Integer; Indentation: Integer; PositiveOnly: Boolean; ReverseSign: Boolean; RowType: Option)
    var
        AccSchedLine: Record "Acc. Schedule Line";
    begin
        AccSchedLine.Init();
        AccSchedLine."Schedule Name" := ScheduleName;

        if "Previous Schedule Name" <> ScheduleName then begin
            "Line No." := 10000;
            "Previous Schedule Name" := ScheduleName;
        end else
            "Line No." := "Line No." + 10000;
        AccSchedLine.Validate("Line No.", "Line No.");
        AccSchedLine."Row No." := RowNo;
        AccSchedLine.Description := Description;
        AccSchedLine.Totaling := Totaling;
        AccSchedLine."Totaling Type" := "Acc. Schedule Line Totaling Type".FromInteger(TotalingType);
        AccSchedLine."New Page" := NewPage;
        AccSchedLine.Show := "Acc. Schedule Line Show".FromInteger(Show);
        AccSchedLine."Amount Type" := "Account Schedule Amount Type".FromInteger(AmountType);
        AccSchedLine.Indentation := Indentation;
        AccSchedLine."Positive Only" := PositiveOnly;
        AccSchedLine."Reverse Sign" := ReverseSign;
        AccSchedLine."Row Type" := RowType;
        AccSchedLine.Insert();
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

