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

        // Modification Demo Finance (CM) : Ajout des lignes de tableaux FR
        InsertData(XSIG, '01', XSalesOfGoods, '>=707000&<708000|>=709700&<709800', 0, '', '', '', '', false, false);
        InsertData(XSIG, '02', XPurchasCostOfSaledGoods, '>=607000&<608000|>=608700&<608800|>=609700&<609800|>=603700&<603800',
          0, '', '', '', '', false, false);
        InsertData(XSIG, '03', XSalesProfit, '01+02', 2, '', '', '', '', false, true);
        InsertData(XSIG, '04', XSaledProduction, '>=700000&<707000|>=708000&<709000|>=709000&<709700|>=709800&<709900',
          0, '', '', '', '', false, false);
        InsertData(XSIG, '05', XProductionVariance, '>=713000&<714000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '06', XProducedFixedAssets, '>=720000&<730000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '07', XLongTermNetIncomes, '>=730000&<740000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '10', XFISCALYEARPRODUCTION, '04+05+06+07', 2, '', '', '', '', false, true);
        InsertData(XSIG, '11', XExternalConsumption1, '>=601&<6033|>=604000&<607000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '12', XExternalConsumption2, '>=608300&<608700|>=609000&<609700', 0, '', '', '', '', false, false);
        InsertData(XSIG, '13', XExternalConsumption3, '>=609800&<629000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '15', XTOTALExternalConsumption, '11+12+13', 2, '', '', '', '', false, true);
        InsertData(XSIG, '20', XADDEDVALUE, '03+10+15', 2, '', '', '', '', false, true);
        InsertData(XSIG, '21', XExploitationSubsidy, '>=740000&<750000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '22', XTaxes, '>=630000&<640000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '23', XPersonnelCosts, '>=640000&<650000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '30', XEBEorDBE, '20+21+22+23', 2, '', '', '', '', false, true);
        InsertData(XSIG, '31', XDiscountOnExploitationCosts, '>=781000&<786000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '32', XOtherIncomes, '>=750000&<755000|>=756000&<760000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '33', XTransfertOfRunningCosts, '>=791000&<792000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '34', XDAP, '>=681000&<686000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '35', XOtherCosts, '>=650000&<655000|>=656000&<660000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '40', XEXPLOITATIONPROFIT, '30+31+32+33+34+35', 2, '', '', '', '', false, true);
        InsertData(XSIG, '41', XFinancialsProducts, '>=760000&<770000|>=786000&<787000|>=796000&<797000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '42', XShareOnOperationCommon, '>=755000&<756000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '43', '   ' + XFinancialsCosts, '>=660000&<670000|>=686000&<687000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '44', '   ' + XShareOnOperationCommon, '>=655000&<656000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '50', XPROFITBEFORETAXEXTRAITEM, '40+41+42+43+44', 2, '', '', '', '', false, true);
        InsertData(XSIG, '51', XExtraordinariesIncomes, '>=770000&<780000|>=787000&<788000|>=797000&<798000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '52', '   ' + XExtraordinariesCosts, '>=670000&<680000|>=687000&<690000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '60', XEXTRAORDINARYPROFIT, '51+52', 2, '', '', '', '', false, true);
        InsertData(XSIG, '61', '   ' + XEmployeesParticipation, '>=691000&<692000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '62', '   ' + XTaxesOnBenefits, '>=695000&<700000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '65', XTOTALMiscTaxes, '61+62', 2, '', '', '', '', false, true);
        InsertData(XSIG, '70', XNETPROFIT, '50+60+65', 2, '', '', '', '', false, true);
        InsertData(XSIG, '71', '', '', 0, '', '', '', '', false, false);
        InsertData(XSIG, '72', XProceedsFromAssetsSold, '775000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '73', '   ' + XBookValueOnDisposalLoss, '675000', 0, '', '', '', '', false, false);
        InsertData(XSIG, '74', XResultOnDisposalLoss, '72-73', 2, '', '', '', '', false, false);
        InsertData(XSIG, '75', '', '', 0, '', '', '', '', false, false);
        InsertData(XSIG, '76', '', '', 0, '', '', '', '', false, false);
        InsertData(XSIG, '80', XEBE, '30', 2, '', '', '', '', false, true);
        InsertData(XSIG, '81', XTransfertOfExploitationCosts, '33', 2, '', '', '', '', false, false);
        InsertData(XSIG, '82', XOtherIncomesFromOperation, '32', 2, '', '', '', '', false, false);
        InsertData(XSIG, '83', XSharesInTheProfit, '42', 2, '', '', '', '', false, false);
        InsertData(XSIG, '84', XFinancialProfitorLoss, '41+43', 2, '', '', '', '', false, false);
        InsertData(XSIG, '85', XEmployeesParticipation, '61', 2, '', '', '', '', false, false);
        InsertData(XSIG, '86', XTaxesOnSocieties, '62', 2, '', '', '', '', false, false);
        InsertData(XSIG, '90', XCBO, '80+81+82+83+84+85+86', 2, '', '', '', '', false, true);
        InsertData(XPROFIT, '', XINCOMESFROMOPERATION, '', 0, '', '', '', '', false, true);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '1', XSalesOfGoods, '707*|709*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '2', XSoldProdAssetsServices, '700000..706999|708000..709699|709800..709999', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '3', '                ' + XNetAmountOfTurnover, '1..2', 2, '', '', '', '', true, false);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '4', 'Production stockée', '713*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '5', XProducedFixedAssets, '72*|73*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '6', XExploitationSubsidy, '74*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '7', XRecoveryOfProvAndDepr, '781*|791*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '8', XOtherIncomes, '750000..754999|756000..759999', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '9', '                    ' + XTotalI, '3..8', 2, '', '', '', '', true, false);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '', XRunningCosts, '', 0, '', '', '', '', false, true);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '10', XPurchasesOfGoods, '607*|6087*|6097*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '11', XInventoryVariation, '6037*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '12', XPurchOfRawAuxMat, '601*|602*|6081*|6082*|6091*|6092*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '13', XInventoryVariationRM, '6031*|6032*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '14', XOthersPurcAndExtCosts, '604*|605*|606*|6084*|6085*|6086*|6094*|6095*|6096*|61*|62*',
          0, '', '', '', '', false, false);
        InsertData(XPROFIT, '16', XTaxesAndAssPmts, '63*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '17', Xsalary, '641*|644*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '18', XSocialSecurityCharges, '645*|646*|647*|648*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '19', XDepreciationProvision + ' :', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '20', XOnFixedAssetsDP, '6811*|6812*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '21', XOnFixedAssetsCTP, '6816*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '22', XOnCurrentAssetsCTP, '6817*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '23', XForRisksAndChargesCTP, '6815*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '24', XOtherCosts, '650000..654999|656000..659999', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '25', '                    ' + XTotalII, '10..24', 2, '', '', '', '', false, false);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '26', '1. ' + XEXPLOITATIONPROFIT + ' (I-II)', '9|25', 2, '', '', '', '', true, true);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '', XProfSharOnCommOps + ' :', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '27', XAssigProfitOrTransLoss + ' (III)', '755*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '28', XLossAttribOrTransBenefit + ' (IV)', '655*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '', XFinancialsIncomes + ' :', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '29', XOfContribution, '761*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '30', XOtherSecurAndFixAsstsRec, '762*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '31', XOtherIntAndAssimInc, '763*|764*|765*|768*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '32', XRecOfProvAndCostsTrans, '786*|796*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '33', XPositiveDifferenceOfChange, '766*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '34', XIncFromDispOfSecur, '767*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '35', '                    ' + XTotalV, '29..34', 2, '', '', '', '', true, false);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '', XFinancialsCosts + ' :', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '36', XDepreciationProvision, '686*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '37', XInterestsAndAssimiledCosts, '661*|664*|665*|668*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '38', XNegativeDiffOfExchange, '666*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '39', XLosFromDispOfSecur, '667*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '40', '                    ' + XTotalVI, '36..39', 2, '', '', '', '', false, false);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '41', '2. ' + XFinancialProfitorLoss + ' (V-VI)', '35|40', 2, '', '', '', '', true, true);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '42', '3. ' + XPROFITBEFORETAXEXTRAITEM, '9|25|27|28|35|40', 2, '', '', '', '', true, true);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '', XExtraordinariesIncomes + ' :', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '43', XOperationalGains, '771*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '44', XOnCapitalTransaction, '775*|777*|778*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '45', XRecOfProvAndCostsTrans, '787*|797*', 0, '', '', '', '', true, false);
        InsertData(XPROFIT, '46', '                    ' + XTotalVII, '43..45', 2, '', '', '', '', true, false);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '', XExtraordinariesCosts + ' :', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '47', XOperationalGains, '671*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '48', XOnCapitalTransaction, '675*|678*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '49', XDepreciationProvision, '687*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '50', '                    ' + XTotalVIII, '47..49', 2, '', '', '', '', false, false);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '51', '4. ' + XEXTRAORDINARYPROFIT + ' (VII - VIII)', '46|50', 2, '', '', '', '', true, true);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '52', XEmpPartOnSocietyProf + '(IX)', '691*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '53', XTaxesOnBenefits + ' (X)', '689*|695*|696*|697*|698*|699*|789*', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XPROFIT, '54', XTotalOfIncomes + ' (I + III + V + VII)', '9|27|35|46', 2, '', '', '', '', true, false);
        InsertData(XPROFIT, '55', XTotalOfCharges + ' ( II + IV + VI + VIII + IX + X )', '25|28|40|50|52|53', 2, '', '', '', '', true, false);
        InsertData(XPROFIT, '56', '                    ' + XBenefitOrLoss, '54|55', 2, '', '', '', '', true, true);

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

        // Ajout démo finance (CM) : insertion des anciens tableaux d'analyse Bilan et résultat
        InsertDataFR(XACTIVE, '', XFIXEDASSET, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '01', XNonCalledSubscribedCapital, '109*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '02', XIntangibleAssets + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '03', XStartupCosts, '201*', 0, false, '', '', "Calculate with"::Sign, '2801*');
        InsertDataFR(XACTIVE, '04', XResearchAndDevelopmentCosts, '203*', 0, false, '', '', "Calculate with"::Sign, '2803*');
        InsertDataFR(XACTIVE, '06', XList1, '205*', 0, false, '', '', "Calculate with"::Sign, '2805*|2905*');
        InsertDataFR(XACTIVE, '07', XSaleFund, '206*|207*', 0, false, '', '', "Calculate with"::Sign, '2807*|2906*|2907*');
        InsertDataFR(XACTIVE, '08', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '09', XOthers, '208*', 0, false, '', '', "Calculate with"::Sign, '2808*|2908*');
        InsertDataFR(XACTIVE, '10', XCurrentIntangibleAssets, '232*', 0, false, '', '', "Calculate with"::Sign, '2932*');
        InsertDataFR(XACTIVE, '11', XAdvancesAndDownPayments, '237*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '12', XTangiblesAssets + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '13', XGround, '211*|212*', 0, false, '', '', "Calculate with"::Sign, '2811*|2812*|2911*');
        InsertDataFR(XACTIVE, '14', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '15', XConstructions, '213*|214*', 0, false, '', '', "Calculate with"::Sign, '2813*|2814*');
        InsertDataFR(XACTIVE, '16', XPlantsAndMachineries, '215*', 0, false, '', '', "Calculate with"::Sign, '2815*');
        InsertDataFR(XACTIVE, '17', XOthers, '218*', 0, false, '', '', "Calculate with"::Sign, '2818*');
        InsertDataFR(XACTIVE, '18', XCurrentTangibleAssets, '231*', 0, false, '', '', "Calculate with"::Sign, '2931*');
        InsertDataFR(XACTIVE, '19', XAdvancesAndDownPayments, '238*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '20', XLongTermInvestments + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '21', XContributions, '261*|266*', 0, false, '', '', "Calculate with"::Sign, '2961*|2966*');
        InsertDataFR(XACTIVE, '22', XDebtsAttachedToContributions, '267*|268*', 0, false, '', '', "Calculate with"::Sign, '2967*|2968*');
        InsertDataFR(XACTIVE, '23', XTIAP, '273*', 0, false, '', '', "Calculate with"::Sign, '2973*');
        InsertDataFR(XACTIVE, '24', XOtherTangibleAssets, '271*|272*|27682*', 0, false, '', '', "Calculate with"::Sign, '2971*|2972*');
        InsertDataFR(XACTIVE, '25', XLoans, '274*|27684*', 0, false, '', '', "Calculate with"::Sign, '2974*');
        InsertDataFR(XACTIVE, '26', XOthers, '275*|2761*|27685*|27688*', 0, false, '', '', "Calculate with"::Sign, '2975*|2976*');
        InsertDataFR(XACTIVE, '27', '                    ' + XTotalI, '01..26', 2, true, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '', XCURRENTASSET, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '28', XStocksAndInProgress + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '29', XRawMaterialsAndOtherStocks, '31*|32*', 0, false, '', '', "Calculate with"::Sign, '391*|392*');
        InsertDataFR(XACTIVE, '30', XProductionInProgress, '33*|34*', 0, false, '', '', "Calculate with"::Sign, '393*|394*');
        InsertDataFR(XACTIVE, '31', XWIPAndFinishGds, '35*', 0, false, '', '', "Calculate with"::Sign, '395*');
        InsertDataFR(XACTIVE, '32', XGoods, '37*', 0, false, '', '', "Calculate with"::Sign, '397*');
        InsertDataFR(XACTIVE, '33', XAdvAndDwnPmtsPaidOnOrder, '4091*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '34', XPASSIVE + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '35', XCltsDbtsAndAttachAcc, '411*|413*|416*|417*|418*', 0, false, '', '', "Calculate with"::Sign, '491*');
        InsertDataFR(XACTIVE, '36', XOthers,
        '4096*|4097*|4098*|425*|4287*|4387*|441*|4456*|44581*|44582*|44583*|44586*|4487*|462*|465*|4687*',
          0, false, '443*|444*|450000..456199|456300..456999|458000..459999|467*|478*', '', "Calculate with"::Sign, '495*|496*');
        InsertDataFR(XACTIVE, '37', XCalledUnpaidStockCapital, '4562*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '38', XAssSecurities + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '39', XOwnersStockEquity, '502*', 0, false, '', '', "Calculate with"::Sign, '5903*');
        InsertDataFR(XACTIVE, '40', XOtherStocks, '500000..501999|503000..508999',
          0, false, '', '', "Calculate with"::Sign, '590000..590299|590400..599999');
        InsertDataFR(XACTIVE, '41', XFundsTools, '52*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '42', XAvailableFunds, '53*|54*', 0, false, '510000..518599|518700..518999', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '43', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '44', XACCRUALSINCOMESACCOUNTS, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '45', XPreCharges, '486*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '46', '                    ' + XTotalII, '28..45', 2, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '47', XCostsToDispatchOnSevEx + ' (III)', '481*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '48', XReimbPremiumForObligations + ' (IV)', '169*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '49', XExchRateDiffAssets + ' (V)', '476*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '', '                    ' + XGENERALTOTAL + ' (I + II + III + IV + V)', '27|46..49',
          2, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XACTIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', XSHAREHOLDERS, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '01', XAssetsIncludingThosePaid, '101*|108*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '02', XIssueFusionContrPremium, '104*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '03', XRevaluationVariance, '105*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '04', XEquivalenceVariance, '107*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '05', XReserves + ' :', '1060*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '06', XLegalReserves, '1061*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '07', XStatutoryOrContractedReserves, '1063*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '08', XByLawReserves, '1062*|1064*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '09', XOthers, '1068*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '10', XCarriedForward, '11*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '11', XStatementOfIncome, '12*|6*|7*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '12', XSubsidyInvestment, '13*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '13', XByLawProvisions, '14*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '14', '                    ' + XTotalI, '01..13', 2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', XSHAREHOLDERSEQUITY, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '15', XEquityInvestIssuesRev, '1671*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '16', XConditionalAdvance, '1674*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '17', XOthers, '', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '18', '                    ' + XTotalIbis, '15..17', 2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', XRISKSANDCHARGESPROVISIONS, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '19', XRisksProvisions, '151*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '20', XChargesProvisions, '150000..150999|152000..159999', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '21', '                    ' + XTotalII, '19..20', 2, true, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', XPASSIVE, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '22', XConvertiblesBoundsIssues, '161*|16881*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '23', XOtherBoundsIssues, '163*|16883*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '24', XLoansAndDebtsWithCredInstit, '164*|16884*|5186*|519*',
          0, false, '', '510000..518599|518700..518999', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '25', XVarFinLoansAndDebts, '165*|166*|168000..168809|168820..168829|168850..168899|17*|426*',
          0, false, '', '450000..456199|456300..456999|458000..459999', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '26', XAdvAndDwnPmRecOnInProgOrders, '4191*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '27', XVdrsDbtsAndAttachAccts, '401*|403*|4081*|408800..408839|408850..408899',
          0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '28', XFiscalsAndSocialsDebts, '421*|422*|424*|427*|4282*|4284*|4286*' +
          '|430000..438699|438800..439999|442*|4452*|4455*|4457*|44584*|44587*|446*|447*|4482*|4486*|457*',
          0, false, '', '443*|444*', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '29', XOnFixAsstsDbtsAndAttachAccts, '269*|279*|404*|405*|4084*|40884*',
          0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '30', XOtherDebts, '4196*|4197*|4198*|464*|4686*|509*',
          0, false, '', '467*|478*', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '31', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '32', XACCRUALSINCOMESACCOUNTS, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '33', XAccrualsIncomes, '487*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '34', '                    ' + XTotalIII, '22..33', 2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '35', XExchRateDiffLiab + ' (IV)', '477*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPASSIVE, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPASSIVE, '', '                    ' + XGENERALTOTAL + ' (I + I bis + II + III + IV)', '14|18|21|34..35',
          2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '', XINCOMESFROMOPERATION, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '01', XSalesOfGoods, '707*|7097*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '02', XSoldProdAssetsServices, '700000..706999|708000..709699|709800..709999',
          0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '03', '                    ' + XNetAmountOfTurnover, '01..02', 2, false, '', '', "Calculate with"::"Opposite Sign", '')
        ;
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '04', XStoredProduction, '713*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '05', XProducedFixedAssets, '72*|73*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '06', XExploitationSubsidy, '74*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '07', XRecOfProvDeprAndCstsTrans, '781*|791*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '08', XOtherIncomes, '750000..754999|756000..759999', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '09', '                    ' + XTotalI, '03..08', 2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', XRunningCosts, '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '10', XPurchasesOfGoods, '607*|6087*|6097*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '11', XInventoryVariation, '6037*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '12', XPurOfRawMatAndOthInvent, '601*|602*|6081*|6082*|6091*|6092*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '13', XInventoryVariationRM, '6031*|6032*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '14', XOthersPurcAndExtCosts, '604*|605*|606*|6084*|6085*|6086*|6094*|6095*|6096*|61*|62*',
          0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '16', XTaxesAndAssPmts, '63*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '17', Xsalary, '641*|644*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '18', XSocialSecurityCharges, '645*|646*|647*|648*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '19', XDepreciationProvision + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '20', XOnFixedAssetsDP, '6811*|6812*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '21', XOnFixedAssetsCTP, '6816*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '22', XOnCurrentAssetsCTP, '6817*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '23', XForRisksAndChargesCTP, '6815*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '24', XOtherCosts, '650000..654999|656000..659999', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '25', '                    ' + XTotalII, '10..24', 2, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '26', '1. ' + XEXPLOITATIONPROFIT + ' (I - II)', '09|25', 2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', XProfSharOnCommOps + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '27', XAssigProfitOrTransLoss + ' (III)', '755*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '28', XLossAttribOrTransBenefit + ' (IV)', '655*', 0, true, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', XFinancialsIncomes + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '29', XOfContribution, '761*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '30', XOtherSecurAndFixedAssetRec, '762*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '31', XOtherIntAndAssimInc, '763*|764*|765*|768*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '32', XRecOfProvAndCostsTrans, '786*|796*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '33', XPositiveDifferenceOfChange, '766*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '34', XIncOnDispOfSecur, '767*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '35', '                    ' + XTotalV, '29..34', 2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', XFinancialsCosts + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '36', XDepreciationProvision, '686*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '37', XInterestsAndAssimiledCosts, '661*|664*|665*|668*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '38', XNegativeDiffOfExchange, '666*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '39', XLossesOnDispOfSecur, '667*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '40', '                    ' + XTotalVI, '36..39', 2, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '41', '2. ' + XFinancialProfitorLoss + ' (V - VI)', '35|40', 2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '42', '3. ' + XPROFITBEFORETAXEXTRAITEM + ' (I - II + III - IV + V - VI)', '09|25|27|28|35|40',
          2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', XExtraordinariesIncomes + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '43', XOperationalGains, '771*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '44', XOnCapitalTransaction, '775*|777*|778*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '45', XRecOfProvAndCostsTrans, '787*|797*', 0, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '46', '                    ' + XTotalVII, '43..45', 2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', XExtraordinariesCosts + ' :', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '47', XOperationalGains, '671*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '48', XOnCapitalTransaction, '675*|678*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '49', XDepreciationProvision, '687*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '50', '                    ' + XTotalVIII, '47..49', 2, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '51', '4. ' + XEXTRAORDINARYPROFIT + ' (VII - VIII)', '46|50', 2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '52', XProfitSharingSchemeIX, '691*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '53', XTaxesOnBenefits + ' (X)', '689*|695*|696*|697*|698*|699*|789*', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '', '', '', 0, false, '', '', "Calculate with"::Sign, '');
        InsertDataFR(XPROFIT, '54', '                    ' + XTotalOfIncomes + ' (I + III + V + VII)', '09|27|35|46',
          2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '55', '                    ' + XTotalOfIncomes + ' (II + IV + VI + VIII + IX + X)', '25|28|40|50|52|53',
          2, false, '', '', "Calculate with"::"Opposite Sign", '');
        InsertDataFR(XPROFIT, '56', '                    ' + XBenefitOrLoss, '54|55', 2, false, '', '', "Calculate with"::"Opposite Sign", '');

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
        XSIG: Label 'SIG';
        XSalesOfGoods: Label 'Sales Of Goods';
        XPurchasCostOfSaledGoods: Label 'Purchase Cost Of Saled Goods';
        XSalesProfit: Label 'Sales Profit';
        XSaledProduction: Label 'Saled Production';
        XProductionVariance: Label 'Production Variance Of Fiscal Year ';
        XFISCALYEARPRODUCTION: Label 'FISCAL YEAR PRODUCTION';
        XExternalConsumption1: Label '   External Consumption 1';
        XExternalConsumption2: Label '   External Consumption 2';
        XExternalConsumption3: Label '   External Consumption 3';
        XTOTALExternalConsumption: Label 'TOTAL External Consumption';
        XADDEDVALUE: Label 'ADDED VALUE';
        XExploitationSubsidy: Label 'Exploitation Subsidy';
        XEBEorDBE: Label 'E.B.E or D.B.E.';
        XDiscountOnExploitationCosts: Label 'Discount On Exploitation Costs';
        XOtherIncomes: Label 'Other Incomes';
        XTransfertOfExploitationCosts: Label '   Transfert Of Exploitation Costs';
        XDAP: Label '   D.A.P.';
        XOtherCosts: Label '   Other Costs';
        XFinancialsIncomes: Label 'Financials Incomes';
        XLongTermNetIncomes: Label 'Long-term Net Incomes';
        XProducedFixedAssets: Label 'Produced Fixed Assets';
        XTaxes: Label '   Taxes';
        XPersonnelCosts: Label '   Personnel Costs';
        XPROFIT: Label 'PROFIT';
        XTransfertOfRunningCosts: Label 'Transfert Of Running Costs';
        XResultOnDisposalLoss: Label 'Results On Disposal (Loss)';
        XBookValueOnDisposalLoss: Label 'Book Value On Disposal (Loss)';
        XNETPROFIT: Label 'NET PROFIT';
        XTOTALMiscTaxes: Label 'TOTAL Misc Taxes';
        XTaxesOnBenefits: Label 'Taxes On Benefits';
        XEmployeesParticipation: Label 'Employees Participation';
        XEXTRAORDINARYPROFIT: Label 'EXTRAORDINARY PROFIT';
        XExtraordinariesCosts: Label 'Extraordinaries Costs';
        XExtraordinariesIncomes: Label 'Extraordinaries Incomes';
        XPROFITBEFORETAXEXTRAITEM: Label 'PROFIT BEFORE TAX & EXTRA ITEM';
        XFinancialsCosts: Label 'Financials Costs';
        XShareOnOperationCommon: Label 'Share On Operation/Common';
        XFinancialsProducts: Label 'Financials Products';
        XEXPLOITATIONPROFIT: Label 'EXPLOITATION PROFIT';
        XCBO: Label 'CBO';
        XRunningCosts: Label 'Costs from operation';
        "Calculate with": Option Sign,"Opposite Sign";
        XProfitSharingSchemeIX: Label 'Profit-Sharing Scheme (IX)';
        XStoredProduction: Label 'Stored Production';
        XNetAmountOfTurnover: Label 'Net Amount of Turnover';
        XSoldProdAssetsServices: Label 'Sold Production (Assets and Services)';
        XINCOMESFROMOPERATION: Label 'INCOMES FROM OPERATION';
        XTaxesOnSocieties: Label 'Taxes On Societies';
        XFinancialProfitorLoss: Label 'Financial Profit or Loss';
        XSharesInTheProfit: Label 'Shares In The Profit';
        XOtherIncomesFromOperation: Label 'Other Incomes From Operation';
        XRecoveryOfProvAndDepr: Label 'Recovery Of Prov. (And Depr.) Costs Transfert';
        XPurchasesOfGoods: Label 'Purchases Of Goods';
        XInventoryVariation: Label 'Inventory Variation';
        XInventoryVariationRM: Label 'Inventory Variation (r. m.)';
        XProceedsFromAssetsSold: Label 'Proceeds from Assets Sold';
        XEBE: Label 'E.B.E.';
        XPurchOfRawAuxMat: Label 'Purchases of Raw. & Aux. Materials';
        XTaxesAndAssPmts: Label 'Taxes and Assimilated Payments';
        XOthersPurcAndExtCosts: Label 'Others Purchases And External Costs';
        Xsalary: Label 'Salary';
        XSocialSecurityCharges: Label 'Social Security Charges';
        XOtherSecurAndFixAsstsRec: Label 'Other Securities and Fixed Assets Receivables';
        XIncFromDispOfSecur: Label 'Income from Disposal of Securities';
        XLosFromDispOfSecur: Label 'Losses from Disposal of Securities';
        XOperationalGains: Label 'Operational Gains';
        XTIAP: Label 'T.I.A.P.';
        XOtherTangibleAssets: Label 'Other Tangible Assets';
        XWIPAndFinishGds: Label 'WIP and Finished Goods';
        XCalledUnpaidStockCapital: Label 'Subscribed Capital - called, non paid';
        XOwnersStockEquity: Label 'Owner''s Stock Equity';
        XOtherStocks: Label 'Other Stocks';
        XPreCharges: Label 'Preliminary Charges';
        XReimbPremiumForObligations: Label 'Reimbursement Premium for Obligations';
        XExchRateDiffAssets: Label 'Exch. Rate Differences Assets';
        XExchRateDiffLiab: Label 'Exch. Rate Differences Liabilities';
        XProfSharOnCommOps: Label 'Profit Sharing on Common Operations';
        XOtherSecurAndFixedAssetRec: Label 'Other Securities and Fixed Asset Receivables';
        XIncOnDispOfSecur: Label 'Income on Disposal of Securities';
        XLossesOnDispOfSecur: Label 'Losses on Disposal of Securities';
        XDepreciationProvision: Label 'Depreciation Provision';
        XOnFixedAssetsDP: Label 'On Fixed Assets : Depreciation Provision';
        XOnFixedAssetsCTP: Label 'On Fixed Assets : Charge To Provisions';
        XOnCurrentAssetsCTP: Label 'On Current Assets : Charge To Provision';
        XForRisksAndChargesCTP: Label 'For Risks And Charges : Charge To Provision';
        XTotalI: Label 'Total I';
        XTotalII: Label 'Total II';
        XTotalIII: Label 'Total III';
        XTotalV: Label 'Total V';
        XTotalVI: Label 'Total VI';
        XTotalVII: Label 'Total VII';
        XTotalVIII: Label 'Total VIII';
        XAssigProfitOrTransLoss: Label 'Assigned Profit Or Transfered Loss';
        XLossAttribOrTransBenefit: Label 'Loss Attributable Or Transfered Benefit';
        XOfContribution: Label 'Of Contribution';
        XOtherIntAndAssimInc: Label 'Other Interests and Assimiled Incomes';
        XRecOfProvAndCostsTrans: Label 'Recovery Of Provision And Costs Transfert';
        XPositiveDifferenceOfChange: Label 'Positive Difference Of Change';
        XInterestsAndAssimiledCosts: Label 'Interests And Assimiled Costs';
        XNegativeDiffOfExchange: Label 'Negative Difference Of Exchange';
        XBenefitOrLoss: Label 'Benefit Or Loss';
        XOnCapitalTransaction: Label 'On Capital Transaction';
        XEmpPartOnSocietyProf: Label 'Employees Participation On Society Profits';
        XTotalOfIncomes: Label 'Total Of Incomes';
        XTotalOfCharges: Label 'Total Of Costs';
        XFIXEDASSET: Label 'FIXED ASSET';
        XNonCalledSubscribedCapital: Label 'Non Called Subscribed Capital';
        XIntangibleAssets: Label 'Intangible Assets';
        XStartupCosts: Label 'Start-up Costs';
        XResearchAndDevelopmentCosts: Label 'Research And Development Costs';
        XList1: Label 'Concessions, Patents, Licences, Brands, Processes, Copyrights And Sim. Val.';
        XSaleFund: Label 'Sale Fund';
        XOthers: Label 'Others';
        XCurrentIntangibleAssets: Label 'Current Intangible Assets';
        XAdvancesAndDownPayments: Label 'Advances And Down Payments';
        XTangiblesAssets: Label 'Tangibles Assets';
        XGround: Label 'Grounds';
        XConstructions: Label 'Constructions';
        XPlantsAndMachineries: Label 'Plants And Machineries, Equipment And Plant';
        XCurrentTangibleAssets: Label 'Current Tangible Assets';
        XLongTermInvestments: Label 'Long-Term Investments';
        XContributions: Label 'Contributions';
        XDebtsAttachedToContributions: Label 'Debts Attached To Contributions';
        XLoans: Label 'Loans';
        XCURRENTASSET: Label 'CURRENT ASSET';
        XStocksAndInProgress: Label 'Stocks And In Progress';
        XRawMaterialsAndOtherStocks: Label 'Raw Materials And Other Stocks';
        XProductionInProgress: Label 'Production In Progress (Assets and Services)';
        XGoods: Label 'Goods';
        XAdvAndDwnPmtsPaidOnOrder: Label 'Advances And Down Payments Paid On Order';
        XCltsDbtsAndAttachAcc: Label 'Clients Debts And Attached Accounts';
        XAssSecurities: Label 'Securities';
        XFundsTools: Label 'Funds Tools';
        XAvailableFunds: Label 'Available Funds';
        XACCRUALSINCOMESACCOUNTS: Label 'ACCRUALS INCOMES ACCOUNTS';
        XCostsToDispatchOnSevEx: Label 'Costs To Dispatch On Several Exercices';
        XGENERALTOTAL: Label 'GENERAL TOTAL';
        XSHAREHOLDERS: Label 'SHARE-HOLDERS';
        XAssetsIncludingThosePaid: Label 'Assets (including those paid)';
        XIssueFusionContrPremium: Label 'Issue, Fusion, Contribution Premium';
        XRevaluationVariance: Label 'Revaluation Variance';
        XEquivalenceVariance: Label 'Equivalence Variance';
        XReserves: Label 'Reserves';
        XLegalReserves: Label 'Legal Reserves';
        XStatutoryOrContractedReserves: Label 'Statutory Or Contracted Reserves';
        XByLawReserves: Label 'By-Law Reserves';
        XCarriedForward: Label 'Carried Forward';
        XStatementOfIncome: Label 'Statement Of Income';
        XSubsidyInvestment: Label 'Subsidy Investment';
        XByLawProvisions: Label 'By-Law Provisions';
        XSHAREHOLDERSEQUITY: Label 'SHARE-HOLDERS EQUITY';
        XEquityInvestIssuesRev: Label 'Equity Investment Issue''s Revenue';
        XConditionalAdvance: Label 'Conditional Advance';
        XTotalIbis: Label 'Total I bis';
        XRISKSANDCHARGESPROVISIONS: Label 'RISKS AND CHARGES PROVISIONS';
        XRisksProvisions: Label 'Risks Provisions';
        XChargesProvisions: Label 'Charges Provisions';
        XConvertiblesBoundsIssues: Label 'Convertibles Bounds Issues';
        XOtherBoundsIssues: Label 'Others Bounds Issues';
        XLoansAndDebtsWithCredInstit: Label 'Loans And Debts With Credit Institutions';
        XVarFinLoansAndDebts: Label 'Various Financials Loans And Debts';
        XAdvAndDwnPmRecOnInProgOrders: Label 'Advances And Down Payments Received On In Progress Orders';
        XVdrsDbtsAndAttachAccts: Label 'Vendors Debts And Attached Accounts';
        XFiscalsAndSocialsDebts: Label 'Fiscals And Socials Debts';
        XOnFixAsstsDbtsAndAttachAccts: Label 'On Fixed Assets Debts And Attached Accounts';
        XOtherDebts: Label 'Other Debts';
        XAccrualsIncomes: Label 'Accruals Incomes';
        XRecOfProvDeprAndCstsTrans: Label 'Recovery Of Provision (And Depreciation), Costs Transfert';
        XPurOfRawMatAndOthInvent: Label 'Purchases Of Raw Materials And Others Inventories';
        XPASSIVE: Label 'PASSIVE';
        XACTIVE: Label 'ACTIVE';
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

    procedure InsertDataFR("Schedule Name": Code[10]; "Row No.": Code[10]; Description: Text[80]; Totaling: Text[250]; "Totaling Type": Option; "New Page": Boolean; "Totaling Debtor": Text[250]; "Totaling Creditor": Text[250]; "Calculate with": Option Normal,Opposite; "Totaling 2": Text[250])
    var
        "Account Schedule Line": Record "FR Acc. Schedule Line";
    begin
        "Account Schedule Line".Init();
        "Account Schedule Line".Validate("Schedule Name", "Schedule Name");
        if "Previous Schedule Name" <> "Schedule Name" then begin
            "Line No." := 10000;
            "Previous Schedule Name" := "Schedule Name";
        end else
            "Line No." := "Line No." + 10000;

        "Account Schedule Line".Validate("Line No.", "Line No.");
        "Account Schedule Line".Validate("Row No.", "Row No.");
        "Account Schedule Line".Validate(Description, Description);
        "Account Schedule Line".Validate(Totaling, Totaling);
        "Account Schedule Line".Validate("Totaling Type", "Totaling Type");
        "Account Schedule Line".Validate("New Page", "New Page");
        "Account Schedule Line".Validate("Totaling Debtor", "Totaling Debtor");
        "Account Schedule Line".Validate("Totaling Creditor", "Totaling Creditor");
        "Account Schedule Line".Validate("Calculate with", "Calculate with");
        "Account Schedule Line".Validate("Totaling 2", "Totaling 2");
        "Account Schedule Line".Insert();
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

