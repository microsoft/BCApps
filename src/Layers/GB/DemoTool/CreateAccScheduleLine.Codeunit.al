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
        InsertData(XCAPROF, '160', XGROSSPROFIT, '130..150', 2, '', '', '', '', false, false);
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


        // GB
        InsertData(XBALANCESHT, '10', 'XFIXEDASSETS', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '20', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '30', XLandandBuildings, '1110..1130', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '40', XLandandBuildingsDepntoDate, '1140', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '50', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '60', XLandandBuildingsNet, '1190', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '70', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '80', XOperatingEquipment, '1210..1230', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '90', XOperatingEquipmentDepntoDate, '1240', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '100', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '110', XOperatingEquipmentNet, '1290', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '120', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '130', XVehicles, '1310..1330', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '140', XVehiclesDepntoDate, '1340', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '150', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '160', XVehiclesNet, '1390', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '170', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '180', XFIXEDASSETSTOTAL, '30|80|130', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '190', XFIXEDASSETSTOTALDEPNTODATE, '40|90|140', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '200', XFIXEDASSETSTOTALNET, '1999', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '210', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '220', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '230', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '240', XCURRENTASSETS2, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '250', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '260', XStock, '2190', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '270', XWIP, '2290', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '280', XDebtors, '2390', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '290', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '300', '', '260..280', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '310', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '310', XSecurities, '2890', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '320', XBank, '2920|2930|2940', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '330', XCash, '2910', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '340', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '350', '', '310..330', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '360', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '370', XCURRENTASSETSTOTAL2, '300|350', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '380', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '390', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '400', XCURRENTLIABILITIES, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '410', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '420', XCreditors, '5490', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '430', XRevolvingCredit, '5310', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '440', XProposedDividends, '5910', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '450', XCorporateTax, '5920', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '460', XDeferredTax, '4010', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '470', XOtherTaxVAT, '5790', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '480', XOtherTaxes, '5890', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '490', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '500', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '510', XCURRENTLIABILITIESTOTAL, '420..480', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '520', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '530', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '540', XWORKINGCAPITAL, '370|510', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '550', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '560', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '570', XTOTALASSETSLESSCURRLIABILIT, '200|540', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '580', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '590', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '600', XLONGTERMLIABILITIES, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '610', XBankLoans, '5110', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '620', XMortgage, '5120', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '630', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '640', '', '610|620', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '650', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '660', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '670', XNETASSETS, '570|640', 2, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '680', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '690', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '700', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '710', XFINANCEDBY, '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '720', XShareCapital, '3110', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '730', XRetainedEarnings, '3120', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '740', XNetProfit, '3195', 1, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '750', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '760', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '770', '', '', 0, '', '', '', '', false, false);
        InsertData(XBALANCESHT, '780', XSHAREHOLDERSFUNDS, '720..740', 2, '', '', '', '', false, false);

        InsertData('PROFITLOSS', '10', XSALES, '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '20', XSalesofFinalProducts, '6195', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '30', XSalesofRawMaterials, '6295', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '40', 'Sales of Services and Jobs', '6495|6695', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '50', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '60', 'NET SALES TOTAL', '20..40', 2, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '70', '', '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '80', 'COSTS OF GOODS SOLD', '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '90', XCostofSalesofFinalProducts, '7110..7130|7150..7190', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '100', XCostofSalesofRawMaterials, '7210..7230|7250..7290', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '110', XCostofSalesofServicesandJobs, '7480..7620', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '120', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '130', XCOSTSOFGOODSSOLDTOTAL, '90..110', 2, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '140', '', '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '150', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '160', XGROSSPROFIT, '60|130', 2, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '170', '', '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '180', '', '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '190', XOTHERINCOME, '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '200', XConsultingFees, '6710', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '210', XFeesandChargesRec, '6810', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '220', XDiscountReceived, '7140|7240', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '230', XFixedAssetsGainsandLosses, '8840', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '240', XInterest, '9190', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '250', XFXGains, '9310|9330', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '260', XExtraordinaryIncome, '9410', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '270', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '280', XOTHERINCOMETOTAL, '200..260', 2, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '290', '', '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '300', XEXPENSES, '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '310', XBuildingMaintenanceExpenses, '8190', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '320', XAdministrativeExpenses, '8290', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '330', XComputerExpenses, '8390', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '340', XSellingExpenses, '8490', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '350', XDiscountGranted, '6910', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '360', XVehicleExpenses, '8590', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '370', XOtherOperatingExpenses, '8690', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '380', XPersonnelExpenses, '8790', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '390', XDepreciationofFixedAssets, '8890', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '400', XOtherCostsofOperations, '8910', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '410', XInterestExpenses, '9290', 1, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '420', XFXLosses, '9320|9340', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '440', XCorporationTax, '9510', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '450', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '460', XEXPENSESTOTAL, '310..440', 2, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '470', '', '', 0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '480', '------------------------------', '',
                   0, '', '', '', '', false, false);
        InsertData('PROFITLOSS', '490', XNETPROFIT2, '160|280|460', 2, '', '', '', '', false, false);
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
        XJobSalesAdjmtRetail: Label 'Job Sales Adjmt, Retail';
        XSalesofRetailTotal: Label 'Sales of Retail, Total';
        XIncomeServices: Label 'Income, Services';
        XIncomeProductSales: Label 'Income, Product Sales';
        XSalesDiscountReturnsAndAllowances: Label 'Sales Discount, Returns and Allowances';
        XJobSales: Label 'Job Sales';
        XRevenueArea10to30Total: Label 'Revenue Area 10..30, Total';
        XRevenueArea40to85Total: Label 'Revenue Area 40..85, Total';
        XRevenueArea10to55Total: Label 'Revenue Area 10..55, Total';
        XRevenueArea60to85Total: Label 'Revenue Area 60..85, Total';
        XRevenuenoAreacodeTotal: Label 'Revenue, no Area code, Total';
        XRevenueTotal: Label 'Revenue, Total';
        XCAMPAIGN: Label 'CAMPAIGN';
        XBALANCESHT: Label 'BALANCESHT';
        XLandandBuildings: Label 'Land and Buildings';
        XLandandBuildingsDepntoDate: Label 'Land and Buildings Depn to Date';
        XLandandBuildingsNet: Label 'Land and Buildings Net';
        XOperatingEquipment: Label 'Operating Equipment';
        XOperatingEquipmentDepntoDate: Label 'Operating Equipment Depn to Date';
        XOperatingEquipmentNet: Label 'Operating Equipment Net';
        XVehicles: Label 'Vehicles';
        XVehiclesDepntoDate: Label 'Vehicles Depn to Date';
        XVehiclesNet: Label 'Vehicles Net';
        XFIXEDASSETSTOTAL: Label 'FIXED ASSETS TOTAL';
        XFIXEDASSETSTOTALDEPNTODATE: Label 'FIXED ASSETS TOTAL DEPN TO DATE';
        XFIXEDASSETSTOTALNET: Label 'FIXED ASSETS TOTAL NET';
        XCURRENTASSETS2: Label 'CURRENT ASSETS';
        XStock: Label 'Stock';
        XWIP: Label 'WIP';
        XDebtors: Label 'Debtors';
        XBank: Label 'Bank';
        XCash: Label 'Cash';
        XCreditors: Label 'Creditors';
        XProposedDividends: Label 'Proposed Dividends';
        XCorporateTax: Label 'Corporate Tax';
        XDeferredTax: Label 'Deferred Tax';
        XCURRENTASSETSTOTAL2: Label 'CURRENT ASSETS TOTAL';
        XCURRENTLIABILITIES: Label 'CURRENT LIABILITIES';
        XOtherTaxVAT: Label 'Other Tax (VAT)';
        XOtherTaxes: Label 'Other Taxes';
        XCURRENTLIABILITIESTOTAL: Label 'CURRENT LIABILITIES TOTAL';
        XWORKINGCAPITAL: Label 'WORKING CAPITAL';
        XTOTALASSETSLESSCURRLIABILIT: Label 'TOTAL ASSETS LESS CURRENT LIABILITIES';
        XLONGTERMLIABILITIES: Label 'LONG TERM LIABILITIES';
        XBankLoans: Label 'Bank Loans';
        XMortgage: Label 'Mortgage';
        XNETASSETS: Label 'NET ASSETS';
        XFINANCEDBY: Label 'FINANCED BY';
        XShareCapital: Label 'Share Capital';
        XRetainedEarnings: Label 'Retained Earnings';
        XNetProfit: Label 'Net Profit';
        XSHAREHOLDERSFUNDS: Label 'SHAREHOLDERS FUNDS';
        XSALES: Label 'SALES';
        XSalesofFinalProducts: Label 'Sales of Final Products';
        XSalesofRawMaterials: Label 'Sales of Raw Materials';
        XCostofSalesofFinalProducts: Label 'Cost of Sales of Final Products';
        XCostofSalesofRawMaterials: Label 'Cost of Sales of Raw Materials';
        XCostofSalesofServicesandJobs: Label 'Cost of Sales of Services and Jobs';
        XCOSTSOFGOODSSOLDTOTAL: Label 'COSTS OF GOODS SOLD TOTAL';
        XGROSSPROFIT: Label 'GROSS PROFIT';
        XOTHERINCOME: Label 'OTHER INCOME';
        XConsultingFees: Label 'Consulting Fees';
        XFeesandChargesRec: Label 'Fees and Charges Rec.';
        XDiscountReceived: Label 'Discount Received';
        XFixedAssetsGainsandLosses: Label 'Fixed Assets Gains and Losses';
        XInterest: Label 'Interest';
        XFXGains: Label 'FX Gains';
        XExtraordinaryIncome: Label 'Extraordinary Income';
        XOTHERINCOMETOTAL: Label 'OTHER INCOME TOTAL';
        XEXPENSES: Label 'EXPENSES';
        XBuildingMaintenanceExpenses: Label 'Building Maintenance Expenses';
        XAdministrativeExpenses: Label 'Administrative Expenses';
        XComputerExpenses: Label 'Computer Expenses';
        XSellingExpenses: Label 'Selling Expenses';
        XDiscountGranted: Label 'Discount Granted';
        XVehicleExpenses: Label 'Vehicle Expenses';
        XOtherOperatingExpenses: Label 'Other Operating Expenses';
        XPersonnelExpenses: Label 'Personnel Expenses';
        XDepreciationofFixedAssets: Label 'Depreciation of Fixed Assets';
        XOtherCostsofOperations: Label 'Other Costs of Operations';
        XInterestExpenses: Label 'Interest Expenses';
        XFXLosses: Label 'FX Losses';
        XCorporationTax: Label 'Corporation Tax';
        XEXPENSESTOTAL: Label 'EXPENSES TOTAL';
        XNETPROFIT2: Label 'NET PROFIT';
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
        XSalaryDirectCosts: Label 'Salary Direct Costs';
        XMainCostCenters: Label 'Main Cost Centers';
        XACCCAT: Label 'ACC-CAT', Comment = 'ACC-CAT is the name of the Account Schedule.';
        XBALSHEET: Label 'BALANCE SHEET';
        XIncomeThisYear: Label 'Income This Year';
        XIncomeStatement: Label 'INCOME STATEMENT';
        XNetIncome: Label 'NET INCOME';

    procedure InsertEvaluationData();
    var
        CreateGLAccount: Codeunit "Create G/L Account";
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

        InsertData(XANALYSIS, '', XACIDTESTANALYSIS, '', 0, '', '', '', '', false, true);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', XCurrentAssets, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '101', XInventory, CreateGLAccount.FinishedGoods(), 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '102', XAccountsReceivable, CreateGLAccount.AccountReceivableDomestic(), 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '103', XSecurities, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '104', XLiquidAssets, CreateGLAccount.BusinessaccountOperatingDomestic() + '' + CreateGLAccount.PettyCash(), 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '105', XCurrentAssetsTotal, '101..104', 2, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', XShorttermLiabilities, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '111', XRevolvingCredit, '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '112', XAccountsPayable, CreateGLAccount.AccountsPayableDomestic(), 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '113', XVAT, '46200..46330|' + CreateGLAccount.SalesVATNormalPayable() + '..' + CreateGLAccount.MiscVATPayable(), 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '114', XPersonnelrelatedItems, CreateGLAccount.Accruedwages_salaries() + '..' + CreateGLAccount.SalesVATNormalPayable(), 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '115', XOtherLiabilities, CreateGLAccount.PurchaseDiscounts(), 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '116', XShorttermLiabilitiesTotal, '111..115', 2, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XANALYSIS, '', XCurAminusShorttermLiabilities, '105|116', 2, '', '', '', '', false, true);

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

        InsertData(XREVENUE, '', XREVENUE, '', 0, '', '', '', '', true, true);
        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(XREVENUE, '', XSalesofRetail, '', 0, '', '', '', '', true, true);
        InsertData(XREVENUE, '11', XIncomeServices, CreateGLAccount.SaleofResources(), 0, '', '', '', '', true, false);
        InsertData(XREVENUE, '12', XIncomeProductSales, CreateGLAccount.SaleofFinishedGoods(), 0, '', '', '', '', true, false);
        InsertData(XREVENUE, '13', XSalesDiscountReturnsAndAllowances, CreateGLAccount.SalesDiscounts() + '..' + CreateGLAccount.SalesReturns(), 0, '', '', '', '', true, false);
        InsertData(XREVENUE, '14', XJobSales, CreateGLAccount.JobSales(), 0, '', '', '', '', true, false);
        InsertData(XREVENUE, '15', XSalesofRetailTotal, '11..14', 2, '', '', '', '', true, true);

        InsertData(XREVENUE, '', '', '', 0, '', '', '', '', false, false);
        InsertData(
          XREVENUE, '21', XRevenueArea10to55Total, CreateGLAccount.SaleofResources() + '..' + CreateGLAccount.SalesReturns(), 0, '10..55', '', '', '', true, false);
        InsertData(
          XREVENUE, '22', XRevenueArea60to85Total, CreateGLAccount.SaleofResources() + '..' + CreateGLAccount.SalesReturns(), 0, '60..85', '', '', '', true, false);
        InsertData(
          XREVENUE, '23', XRevenuenoAreacodeTotal, CreateGLAccount.SaleofResources() + '..' + CreateGLAccount.SalesReturns(), 0, '''''', '', '', '', true, false);
        InsertData(
          XREVENUE, '24', XRevenueTotal,
          '21..23', 2, '', '', '', '', true, true);

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

