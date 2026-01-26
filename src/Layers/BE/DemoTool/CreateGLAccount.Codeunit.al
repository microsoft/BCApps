codeunit 101015 "Create G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('1', XOWNERSEQUITYANDDEBTSPLUS1YEAR, 2, 1, 1, '10..199999', 0, '', '', '', '');
        InsertData('10', XCapital, 2, 1, 1, '100..109999', 0, '', '', '', '');
        InsertData('100000', XStockCapital, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('101000', XNotcalledupStockCapital, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('110000', XIssuingpremiums, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('120000', XPlusvaluesofreevaluation, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('130000', XReserve, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('140000', XRetainedEarnings, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('150000', XCapitalSubventions, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('160000', XAllowancesforDoubtfulAcc, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('168000', XDeferredTaxes, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('17', XDebtsdueatplus1Year, 2, 1, 0, '170..179999', 0, '', '', '', '');
        InsertData('170000', XLongtermBankLoans, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('174000', XMortgage, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('2', XFIXEDASSANDCREDITSPLUS1YEAR, 2, 1, 1, '20..299999', 0, '', '', '', '');
        InsertData('20', XPreliminaryExpenses, 2, 1, 1, '200..209999', 0, '', '', '', '');
        InsertData('200000', XFormationandincrofcapital, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI0);
        InsertData('200009', XDeprecFormandincrofcap, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('21', XIntangibleAssets, 2, 1, 0, '210..219999', 0, '', '', '', '');
        InsertData('210000', XResearchandDevelopment, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('210009', XDeprResearchandDevelopment, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('22', XLandsandBuildings, 2, 1, 0, '220..229999', 0, '', '', '', '');
        InsertData('220000', XLandsandBuildings, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('220009', XDeprecBuildings, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('23', XEquipment, 2, 1, 0, '230..239999', 0, '', '', '', '');
        InsertData('230000', XEquipment, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('230009', XDeprecEquipment, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('24', XFurnituresandRollingStock, 2, 1, 0, '240..249999', 0, '', '', '', '');
        InsertData('240000', XFurnitures, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('240009', XDeprecFurnitures, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('241000', XOfficeEquipment, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('241009', XDeprecOfficeEquipment, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('242000', XComputerEquipment, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('242009', XDeprecComputerEquipment, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('245000', XRollingStock, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('245009', XDeprecRollingStock, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('25', XFixedAssetsonleasing, 2, 1, 0, '250..259999', 0, '', '', '', '');
        InsertData('250000', XLeasings, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('250009', XDeprecLeasings, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('26', XOthertangibleFA, 2, 1, 0, '260..269999', 0, '', '', '', '');
        InsertData('260000', XOthertangibleFA, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI0);
        InsertData('260009', XDeprecOthertangibleFA, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('3', XINVENTORYANDORDERS, 2, 1, 1, '30..399999', 0, '', '', '', '');
        InsertData('30', XRawMaterials, 2, 1, 1, '300..309999', 0, '', '', '', '');
        InsertData('300000', XRawMaterials, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('300010', XRawMaterialsInterim, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('309000', XPosteddepreciations, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('31', XAuxiliaryMaterials, 2, 1, 0, '310..319999', 0, '', '', '', '');
        InsertData('310000', XAuxiliaryMaterials, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('310010', XAuxiliaryMaterialsInterim, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('319000', XPosteddepreciations, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('32', XGoodsbeingmade, 2, 1, 0, '320..329999', 0, '', '', '', '');
        InsertData('320000', XGoodsbeingmade, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('320010', XGoodsbeingmadeInterim, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('329000', XPosteddepreciations, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('33', XFinishedGoods, 2, 1, 0, '330..339999', 0, '', '', '', '');
        InsertData('330000', XFinishedGoods, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('330010', XFinishedGoodsInterim, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('339000', XPosteddepreciations, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('34', XGoods, 2, 1, 0, '340..349999', 0, '', '', '', '');
        InsertData('340000', XGoods, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('340010', XGoodsInterim, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('349000', XPosteddepreciations, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('36', XPurchasePrepayments, 2, 1, 0, '360..369999', 0, '', '', '', '');
        InsertData('360000', XVendorPrepayments, 0, 1, 0, '', 0, '', DemoDataSetup.MiscCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('4', XDEBTSCREDITSDUEMINUS1YEAR, 2, 1, 1, '40..499999', 0, '', '', '', '');
        InsertData('40', XAccountsReceivable, 2, 1, 1, '400..409999', 0, '', '', '', '');
        InsertData('400000', XCustomersDomestic, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('400010', XCustomersForeign, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('401000', XBillsofExchReceivable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('404000', XCreditsReceivable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('406', XSalesPrepayments, 2, 1, 0, '406..406999', 0, '', '', '', '');
        InsertData('406000', XCustomerPrepayments, 0, 1, 0, '', 0, '', DemoDataSetup.MiscCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('407000', XDoubtfulDebtors, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('41', XOtherReceivables, 2, 1, 0, '410..419999', 0, '', '', '', '');
        InsertData('411000', XVATRecoverable, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XVAT);
        InsertData('417000', XOtherDoubtfulDebtors, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('42', XDebtsduewithinplus1Year, 2, 1, 0, '420..429999', 0, '', '', '', '');
        InsertData('43', XFinancialDebts, 2, 1, 0, '430..439999', 0, '', '', '', '');
        InsertData('433000', XBankAccount, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('44', XAccountsPayable, 2, 1, 0, '440..449999', 0, '', '', '', '');
        InsertData('440000', XVendorsDomestic, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('440010', XVendorsForeign, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('441000', XBillsofExchPayable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('45', XTaxesSalariesandSocCharges, 2, 1, 0, '450..459999', 0, '', '', '', '');
        InsertData('450000', XEstimatedTaxesPayable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('451000', XVATPayable, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XVAT);
        InsertData('452000', XTaxesPayable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('453', XPersonnelrelatedItems, 2, 1, 0, '4530..459999', 0, '', '', '', '');
        InsertData('453000', XRetainedDeductionsatSource, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('454000', XSocialSecurity, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('455000', XWagesandSalaries, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('456000', XVacationCompensationPayable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('457000', XEmployeesPayable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('459000', XOtherSocialCharges, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('47', XDebtsbyResultAllocation, 2, 1, 0, '470..479999', 0, '', '', '', '');
        InsertData('470000', XDividendsFormerFiscalYrs, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('471000', XDividendsFiscalYear, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('48', XMiscellaneousDebts, 2, 1, 0, '480..489999', 0, '', '', '', '');
        InsertData('49', XTransitAccounts, 2, 1, 0, '490..499999', 0, '', '', '', '');
        InsertData('5', XINVESTMENTSANDLIQUIDITIES, 2, 1, 1, '50..599999', 0, '', '', '', '');
        InsertData('500000', XOwnersStockEquity, 0, 1, 1, '', 0, '', '', '', '');
        InsertData('510000', XStocks, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('52', XSecurities, 2, 1, 0, '520..529999', 0, '', '', '', '');
        InsertData('55', XLiquidAssets, 2, 1, 0, '550..559999', 0, '', '', '', '');
        InsertData('550000', XBankLocalCurrency, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('550005', XBankProcessing, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('550010', XBankForeignCurrency, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('560000', XPostAccount, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('570000', XCashAccount, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('580000', XTransfers, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('6', XEXPENSES, 2, 1, 1, '60..699999', 0, '', '', '', '');
        InsertData('60', XGoodsRawandAuxMaterials, 2, 1, 1, '600..609999', 0, '', '', '', '');
        InsertData('600', XPurchasesRawMaterials, 2, 1, 0, '6000..600999', 0, '', '', '', '');
        InsertData('600000', XPurchasesRawMatDom, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', XG1);
        InsertData('600010', XPurchasesRawMatEU, 0, 1, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', XG1);
        InsertData('600020', XPurchasesRawMatExport, 0, 1, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', XG1);
        InsertData('601', XPurchasesAuxiliaryMaterials, 2, 1, 0, '6010..601999', 0, '', '', '', '');
        InsertData('602', XPurchasesServices, 2, 1, 0, '6020..602999', 0, '', '', '', '');
        InsertData('602000', XResourceUsageCosts, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('602010', XJobCosts, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('603', XGeneralSubcontractings, 2, 1, 0, '6030..603999', 0, '', '', '', '');
        InsertData('604', XPurchasesofGoods, 2, 1, 0, '6040..604999', 0, '', '', '', '');
        InsertData('604000', XPurchasesRetailDom, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('604010', XPurchasesRetailEU, 0, 1, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('604020', XPurchasesRetailExport, 0, 1, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('608', XDiscountsReceived, 2, 1, 0, '6080..608999', 0, '', '', '', '');
        InsertData('608000', XDiscReceivedRawMaterials, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('608400', XDiscReceivedRetail, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('609', XInventoryAdjustments, 2, 1, 0, '6090..609999', 0, '', '', '', '');
        InsertData('609170', XInventAdjRetail, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('609171', XInventAdjRetailInt, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('609180', XJobCostAdjustmentRetail, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('609270', XInventAdjRawMat, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('609271', XInventAdjRawMatInt, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('609280', XJobCostAdjustmentRawMat, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('609480', XJobCostAdjustmentResources, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('61', XServicesandInvestmentGoods, 2, 0, 1, '610..619999', 0, '', '', '', '');
        InsertData('610000', XRentBuildingsRSEquipm, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('611000', XRandMBuildingsandEquipm, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('611300', XRandMRollingStock, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('611400', XCleaningProducts, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612000', XElectricityWaterandHeating, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612120', XGasolineandMotorOil, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612200', XPhoneandFax, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612400', XPostage, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('612500', XOfficeSupplies, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612600', XSoftware, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612610', XConsultantServices, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612620', XOtherComputerExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612800', XMailings, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613100', XInsurancesRSFire, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('613230', XLawyersandAccountants, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613310', XLegalContests, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613390', XOtherServiceCharges, 2, 0, 0, '613390..613399', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613392', XPurchaseCostsRawMat, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', XG1);
        InsertData('613395', XPurchaseCostsRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('613399', XPurchaseCostsInterim, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('613900', XTravel, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613930', XTranspCostspurchRawMat, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', XG1);
        InsertData('613935', XTranspCostspurchRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('614000', XAdvertising, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('614500', XEntertainmentandPR, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('62', XSocialSecurity, 2, 0, 1, '620..629999', 0, '', '', '', '');
        InsertData('620200', XSalaries, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('620300', XWages, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('621000', XPayrollTaxes, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('623000', XOtherPersonnelExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('624000', XRetirementPlanContributions, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('63', XDepreciations, 2, 1, 1, '630..639999', 0, '', '', '', '');
        InsertData('630000', XDeprecFormandincrofcap, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('630200', XDeprecLandandBuildings, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('630210', XDeprecEquipment, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('630220', XDeprecRollingStock, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('64', XOtherOperatingExpenses, 2, 0, 1, '640..649999', 0, '', '', '', '');
        InsertData('640100', XVehicleTaxes, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('640200', XFines, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('643000', XMiscCostsofOperations, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('65', XFinancialCharges, 2, 0, 1, '650..659999', 0, '', '', '', '');
        InsertData('650000', XInterestonBankBalances, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('650010', XInterestonBankAccount, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('650020', XMortgage, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('653000', XPaymentDiscountsGranted, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('654000', XUnrealizedExchRateDiff, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('654100', XRealizedExchRateDiff, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('655000', XCashDiscrepancies, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('66', XExtraordinaryExpenses, 2, 0, 1, '660..669999', 0, '', '', '', '');
        InsertData('660000', XExtraordinaryExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('663000', XLossesDisposalFixedAssets, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('67', XCorporateTax, 2, 0, 0, '670..679999', 0, '', '', '', '');
        InsertData('670000', XCorporateTax, 0, 0, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('68', XTransfertodutyfreereserve, 2, 0, 0, '680..689999', 0, '', '', '', '');
        InsertData('69', XProcessingofResult, 2, 1, 0, '690..699999', 0, '', '', '', '');
        InsertData('690000', XLosscarrforwfrPrevFY, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('691000', XAddcapitalandissuingprem, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('692000', XAddreserves, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('693000', XProfittobecarriedforward, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('694000', XReturnonCapital, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('695000', XDirectorsremuneration, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('7', XINCOMESTATEMENT, 2, 0, 1, '70..799999', 0, '', '', '', '');
        InsertData('70', XRevenue, 2, 0, 1, '700..709999', 0, '', '', '', '');
        InsertData('700', XSalesofRetail, 2, 0, 0, '7000..700999', 0, '', '', '', '');
        InsertData('700000', XSalesRetailDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('700010', XSalesRetailEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('700020', XSalesRetailExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('701', XSalesofRawMaterials, 2, 0, 0, '7010..701999', 0, '', '', '', '');
        InsertData('701000', XSalesRawMatDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', XG1);
        InsertData('701010', XSalesRawMatEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', XG1);
        InsertData('701020', XSalesRawMatExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', XG1);
        InsertData('702', XSalesofResources, 2, 0, 0, '7020..702999', 0, '', '', '', '');
        InsertData('702000', XSalesResourcesDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('702010', XSalesResourcesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('702020', XSalesResourcesExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('703', XSalesofJobs, 2, 0, 0, '7030..703999', 0, '', '', '', '');
        InsertData('703000', XSalesJobs, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('703010', XSalesOtherJobExpenses, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('704000', XConsultingFees, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('708000', XPaymentDiscGranted, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('71', XInventoryAdjustments, 2, 0, 1, '710..719999', 0, '', '', '', '');
        InsertData('72', XProducedFixedAssets, 2, 0, 0, '720..729999', 0, '', '', '', '');
        InsertData('74', XOtherOperatingIncome, 2, 0, 0, '740..749999', 0, '', '', '', '');
        InsertData('742000', XJobCostAdjustmentRetail, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('742010', XJobCostAdjustmentRawMat, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('742020', XJobCostAdjustmentResources, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('75', XFinancialIncome, 2, 0, 1, '750..759999', 0, '', '', '', '');
        InsertData('750000', XIncomefromLoans, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('750100', XInterestonBankAccountsRec, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('753000', XPaymentDiscReceived, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('754000', XUnrealizedExchRateDiff, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('754100', XRealizedExchRateDiff, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('754200', XInvoiceRounding, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('755000', XCashDiscrepancies, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('756200', XFinanceChargesfromCustomers, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', XS0);
        InsertData('76', XExtraordinaryIncome, 2, 0, 1, '760..769999', 0, '', '', '', '');
        InsertData('760000', XExtraordinaryIncome, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('763000', XGainsonDisposalFixedAssets, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('77', XTaxesDuePaid, 2, 0, 0, '770..779999', 0, '', '', '', '');
        InsertData('771000', XCorporateTax, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('78', XDeferredfromDutyfreeRes, 2, 0, 0, '780..789999', 0, '', '', '', '');
        InsertData('79', XProcessingofResult, 2, 0, 0, '790..799999', 0, '', '', '', '');
        InsertData('790000', XBenefitcarrfwfrPrevFY, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('793000', XLosstobecarriedforward, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('794000', XAssociateIntervinLoss, 0, 0, 0, '', 0, '', '', '', '');
        GLAccIndent.Indent();
        AddCategoriesToGLAccounts();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLAccIndent: Codeunit "G/L Account-Indent";
        XFinishedGoods: Label 'Finished Goods';
        XFinishedGoodsInterim: Label 'Finished Goods (Interim)';
        XRawMaterials: Label 'Raw Materials';
        XRawMaterialsInterim: Label 'Raw Materials (Interim)';
        XAccountsReceivable: Label 'Accounts Receivable';
        XCustomersDomestic: Label 'Customers Domestic';
        XCustomersForeign: Label 'Customers, Foreign';
        XOtherReceivables: Label 'Other Receivables';
        XSecurities: Label 'Securities';
        XLiquidAssets: Label 'Liquid Assets';
        XRetainedEarnings: Label 'Retained Earnings';
        XDeferredTaxes: Label 'Deferred Taxes';
        XLongtermBankLoans: Label 'Long-term Bank Loans';
        XMortgage: Label 'Mortgage';
        XAccountsPayable: Label 'Accounts Payable';
        XVendorsDomestic: Label 'Vendors, Domestic';
        XVendorsForeign: Label 'Vendors, Foreign';
        XVAT: Label 'VAT';
        XVATPayable: Label 'VAT Payable';
        XPersonnelrelatedItems: Label 'Personnel-related Items';
        XVacationCompensationPayable: Label 'Vacation Compensation Payable';
        XEmployeesPayable: Label 'Employees Payable';
        XINCOMESTATEMENT: Label 'INCOME STATEMENT';
        XRevenue: Label 'Revenue';
        XSalesofRetail: Label 'Sales of Retail';
        XSalesRetailDom: Label 'Sales, Retail - Dom.';
        XSalesRetailEU: Label 'Sales, Retail - EU';
        XSalesRetailExport: Label 'Sales, Retail - Export';
        XSalesofRawMaterials: Label 'Sales of Raw Materials';
        XSalesofResources: Label 'Sales of Resources';
        XSalesResourcesDom: Label 'Sales, Resources - Dom.';
        XSalesResourcesEU: Label 'Sales, Resources - EU';
        XSalesResourcesExport: Label 'Sales, Resources - Export';
        XSalesofJobs: Label 'Sales of Jobs';
        XSalesOtherJobExpenses: Label 'Sales, Other Job Expenses';
        XDiscReceivedRetail: Label 'Disc. Received, Retail';
        XDiscReceivedRawMaterials: Label 'Disc. Received, Raw Materials';
        XJobCosts: Label 'Job Costs';
        XOfficeSupplies: Label 'Office Supplies';
        XPhoneandFax: Label 'Phone and Fax';
        XPostage: Label 'Postage';
        XSoftware: Label 'Software';
        XConsultantServices: Label 'Consultant Services';
        XOtherComputerExpenses: Label 'Other Computer Expenses';
        XAdvertising: Label 'Advertising';
        XEntertainmentandPR: Label 'Entertainment and PR';
        XTravel: Label 'Travel';
        XGasolineandMotorOil: Label 'Gasoline and Motor Oil';
        XOtherOperatingExpenses: Label 'Other Operating Expenses';
        XCashDiscrepancies: Label 'Cash Discrepancies';
        XWages: Label 'Wages';
        XSalaries: Label 'Salaries';
        XRetirementPlanContributions: Label 'Retirement Plan Contributions';
        XPayrollTaxes: Label 'Payroll Taxes';
        XInterestonBankBalances: Label 'Interest on Bank Balances';
        XFinanceChargesfromCustomers: Label 'Finance Charges from Customers';
        XInvoiceRounding: Label 'Invoice Rounding';
        XPaymentDiscountsGranted: Label 'Payment Discounts Granted';
        XExtraordinaryIncome: Label 'Extraordinary Income';
        XExtraordinaryExpenses: Label 'Extraordinary Expenses';
        XCorporateTax: Label 'Corporate Tax';
        XPurchasePrepayments: Label 'Purchase Prepayments';
        XSalesPrepayments: Label 'Sales Prepayments';
        XOWNERSEQUITYANDDEBTSPLUS1YEAR: Label 'OWNER''S EQUITY & DEBTS +1 YEAR';
        XCapital: Label 'Capital';
        XStockCapital: Label 'Stock Capital';
        XNotcalledupStockCapital: Label 'Not called up Stock Capital';
        XIssuingpremiums: Label 'Issuing premiums';
        XPlusvaluesofreevaluation: Label 'Plus values of reevaluation';
        XReserve: Label 'Reserve';
        XCapitalSubventions: Label 'Capital Subventions';
        XAllowancesforDoubtfulAcc: Label 'Allowances for Doubtful Acc.';
        XDebtsdueatplus1Year: Label 'Debts, due at +1 Year';
        XFIXEDASSANDCREDITSPLUS1YEAR: Label 'FIXED ASSETS & CREDITS +1 YEAR';
        XPreliminaryExpenses: Label 'Preliminary Expenses';
        XFormationandincrofcapital: Label 'Formation & incr. of capital';
        XDeprecFormandincrofcap: Label 'Deprec., Form. & incr. of cap.';
        XIntangibleAssets: Label 'Intangible Assets';
        XResearchandDevelopment: Label 'Research & Development';
        XDeprResearchandDevelopment: Label 'Depr., Research & Development';
        XLandsandBuildings: Label 'Lands and Buildings';
        XDeprecBuildings: Label 'Deprec., Buildings';
        XEquipment: Label 'Equipment';
        XDeprecEquipment: Label 'Deprec., Equipment';
        XFurnituresandRollingStock: Label 'Furnitures and Rolling Stock';
        XFurnitures: Label 'Furnitures';
        XDeprecFurnitures: Label 'Deprec., Furnitures';
        XOfficeEquipment: Label 'Office Equipment';
        XDeprecOfficeEquipment: Label 'Deprec., Office Equipment';
        XComputerEquipment: Label 'Computer Equipment';
        XDeprecComputerEquipment: Label 'Deprec., Computer Equipment';
        XRollingStock: Label 'Rolling Stock';
        XDeprecRollingStock: Label 'Deprec., Rolling Stock';
        XFixedAssetsonleasing: Label 'Fixed Assets on leasing';
        XLeasings: Label 'Leasings';
        XDeprecLeasings: Label 'Deprec., Leasings';
        XOthertangibleFA: Label 'Other tangible FA';
        XDeprecOthertangibleFA: Label 'Deprec., Other tangible FA';
        XINVENTORYANDORDERS: Label 'INVENTORY AND ORDERS';
        XPosteddepreciations: Label 'Posted depreciations';
        XAuxiliaryMaterials: Label 'Auxiliary Materials';
        XAuxiliaryMaterialsInterim: Label 'Auxiliary Materials (Interim)';
        XGoodsbeingmade: Label 'Goods being made';
        XGoodsbeingmadeInterim: Label 'Goods being made (Interim)';
        XGoods: Label 'Goods';
        XGoodsInterim: Label 'Goods (Interim)';
        XDEBTSCREDITSDUEMINUS1YEAR: Label 'DEBTS/CREDITS DUE -1 YEAR';
        XBillsofExchReceivable: Label 'Bills of Exch. Receivable';
        XCreditsReceivable: Label 'Credits Receivable';
        XDoubtfulDebtors: Label 'Doubtful Debtors';
        XVATRecoverable: Label 'VAT Recoverable';
        XOtherDoubtfulDebtors: Label 'Other Doubtful Debtors';
        XDebtsduewithinplus1Year: Label 'Debts, due within +1 Year';
        XFinancialDebts: Label 'Financial Debts';
        XBankAccount: Label 'Bank Account';
        XBillsofExchPayable: Label 'Bills of Exch. Payable';
        XTaxesSalariesandSocCharges: Label 'Taxes, Salaries & Soc. Charges';
        XEstimatedTaxesPayable: Label 'Estimated Taxes Payable';
        XTaxesPayable: Label 'Taxes Payable';
        XRetainedDeductionsatSource: Label 'Retained Deductions at Source';
        XSocialSecurity: Label 'Social Security';
        XWagesandSalaries: Label 'Wages and Salaries';
        XOtherSocialCharges: Label 'Other Social Charges';
        XDebtsbyResultAllocation: Label 'Debts by Result Allocation';
        XDividendsFormerFiscalYrs: Label 'Dividends, Former Fiscal Yrs';
        XDividendsFiscalYear: Label 'Dividends, Fiscal Year';
        XMiscellaneousDebts: Label 'Miscellaneous Debts';
        XTransitAccounts: Label 'Transit Accounts';
        XINVESTMENTSANDLIQUIDITIES: Label 'INVESTMENTS & LIQUIDITIES';
        XOwnersStockEquity: Label 'Owner''s Stock Equity';
        XStocks: Label 'Stocks';
        XBankLocalCurrency: Label 'Bank, Local Currency';
        XBankProcessing: Label 'Bank, Processing';
        XBankForeignCurrency: Label 'Bank, Foreign Currency';
        XPostAccount: Label 'Post Account';
        XCashAccount: Label 'Cash Account';
        XTransfers: Label 'Transfers';
        XEXPENSES: Label 'EXPENSES';
        XGoodsRawandAuxMaterials: Label 'Goods, Raw & Aux. Materials';
        XPurchasesRawMaterials: Label 'Purchases, Raw Materials';
        XPurchasesRawMatDom: Label 'Purchases, Raw Mat. - Dom.';
        XPurchasesRawMatEU: Label 'Purchases, Raw Mat. - EU';
        XPurchasesRawMatExport: Label 'Purchases, Raw Mat. - Export';
        XPurchasesAuxiliaryMaterials: Label 'Purchases, Auxiliary Materials';
        XPurchasesServices: Label 'Purchases, Services';
        XResourceUsageCosts: Label 'Resource Usage Costs';
        XGeneralSubcontractings: Label 'General Subcontractings';
        XPurchasesofGoods: Label 'Purchases of Goods';
        XPurchasesRetailDom: Label 'Purchases, Retail - Dom.';
        XPurchasesRetailEU: Label 'Purchases, Retail - EU';
        XPurchasesRetailExport: Label 'Purchases, Retail - Export';
        XDiscountsReceived: Label 'Discounts Received';
        XInventoryAdjustments: Label 'Inventory Adjustments';
        XInventAdjRetail: Label 'Invent. Adj., Retail';
        XInventAdjRetailInt: Label 'Invent. Adj., Retail (Int.)';
        XJobCostAdjustmentRetail: Label 'Job Cost Adjustment, Retail';
        XInventAdjRawMat: Label 'Invent. Adj., Raw Mat.';
        XInventAdjRawMatInt: Label 'Invent. Adj., Raw Mat. (Int.)';
        XJobCostAdjustmentRawMat: Label 'Job Cost Adjustment, Raw Mat.';
        XJobCostAdjustmentResources: Label 'Job Cost Adjustment, Resources';
        XServicesandInvestmentGoods: Label 'Services and Investment Goods';
        XRentBuildingsRSEquipm: Label 'Rent (Buildings, RS, Equipm.)';
        XRandMBuildingsandEquipm: Label 'R & M., Buildings and Equipm.';
        XRandMRollingStock: Label 'R & M., Rolling Stock';
        XCleaningProducts: Label 'Cleaning Products';
        XElectricityWaterandHeating: Label 'Electricity, Water and Heating';
        XMailings: Label 'Mailings';
        XInsurancesRSFire: Label 'Insurances (RS, Fire, ...)';
        XLawyersandAccountants: Label 'Lawyers and Accountants';
        XLegalContests: Label 'Legal Contests';
        XOtherServiceCharges: Label 'Other Service Charges';
        XPurchaseCostsRawMat: Label 'Purchase Costs, Raw Mat.';
        XPurchaseCostsRetail: Label 'Purchase Costs, Retail';
        XPurchaseCostsInterim: Label 'Purchase Costs (Interim)';
        XTranspCostspurchRawMat: Label 'Transp. Costs purch. Raw Mat.';
        XTranspCostspurchRetail: Label 'Transp. Costs purch. Retail';
        XOtherPersonnelExpenses: Label 'Other Personnel Expenses';
        XDepreciations: Label 'Depreciations';
        XDeprecLandandBuildings: Label 'Deprec., Land and Buildings';
        XLossesDisposalFixedAssets: Label 'Losses/Disposal Fixed Assets';
        XVehicleTaxes: Label 'Vehicle Taxes';
        XFines: Label 'Fines';
        XMiscCostsofOperations: Label 'Misc. Costs of Operations';
        XFinancialCharges: Label 'Financial Charges';
        XInterestonBankAccount: Label 'Interest on Bank Account';
        XTransfertodutyfreereserve: Label 'Transfer to duty-free reserve';
        XUnrealizedExchRateDiff: Label 'Unrealized Exch. Rate Diff.';
        XRealizedExchRateDiff: Label 'Realized Exch. Rate Diff.';
        XProcessingofResult: Label 'Processing of Result';
        XLosscarrforwfrPrevFY: Label 'Loss carr. forw. fr. Prev. FY';
        XAddcapitalandissuingprem: Label 'Add. capital & issuing prem.';
        XAddreserves: Label 'Add. reserves';
        XProfittobecarriedforward: Label 'Profit to be carried forward';
        XReturnonCapital: Label 'Return on Capital';
        XDirectorsremuneration: Label 'Director''s remuneration';
        XSalesRawMatDom: Label 'Sales, Raw Mat. - Dom.';
        XSalesRawMatEU: Label 'Sales, Raw Mat. - EU';
        XSalesRawMatExport: Label 'Sales, Raw Mat. - Export';
        XSalesJobs: Label 'Sales, Jobs';
        XConsultingFees: Label 'Consulting Fees';
        XPaymentDiscGranted: Label 'Payment Disc. Granted';
        XProducedFixedAssets: Label 'Produced Fixed Assets';
        XOtherOperatingIncome: Label 'Other Operating Income';
        XFinancialIncome: Label 'Financial Income';
        XIncomefromLoans: Label 'Income from Loans';
        XInterestonBankAccountsRec: Label 'Interest on Bank Accounts Rec.';
        XPaymentDiscReceived: Label 'Payment Disc. Received';
        XGainsonDisposalFixedAssets: Label 'Gains on Disposal Fixed Assets';
        XTaxesDuePaid: Label 'Taxes Due Paid';
        XDeferredfromDutyfreeRes: Label 'Deferred from Duty-free Res.';
        XBenefitcarrfwfrPrevFY: Label 'Benefit, carr. fw fr. Prev. FY';
        XLosstobecarriedforward: Label 'Loss to be carried forward';
        XAssociateIntervinLoss: Label 'Associate Interv. in Loss';
        XI0: Label 'I0';
        XI3: Label 'I3';
        XS0: Label 'S0';
        XG1: Label 'G1';
        XVendorPrepayments: Label 'Vendor Prepayments';
        XCustomerPrepayments: Label 'Customer Prepayments';

    procedure InsertMiniAppData()
    begin
        AddIncomeStatementForMini();
        AddBalanceSheetForMini();

        GLAccIndent.Indent();
    end;

    local procedure AddIncomeStatementForMini()
    begin
        // Income statement 1000-4999
        DemoDataSetup.Get();
        InsertData('7', XINCOMESTATEMENT, 2, 0, 1, '70..799999', 0, '', '', '', '');
        InsertData('70', XRevenue, 2, 0, 1, '700..709999', 0, '', '', '', '');
        InsertData('700', XSalesofRetail, 2, 0, 0, '7000..700999', 0, '', '', '', '');
        InsertData('700000', XSalesRetailDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('700010', XSalesRetailEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('700020', XSalesRetailExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('701', XSalesofRawMaterials, 2, 0, 0, '7010..701999', 0, '', '', '', '');
        InsertData('702', XSalesofResources, 2, 0, 0, '7020..702999', 0, '', '', '', '');
        InsertData('702000', XSalesResourcesDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('702010', XSalesResourcesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('702020', XSalesResourcesExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('703', XSalesofJobs, 2, 0, 0, '7030..703999', 0, '', '', '', '');
        InsertData('703000', XSalesJobs, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('703010', XSalesOtherJobExpenses, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('704000', XConsultingFees, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('708000', XPaymentDiscGranted, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('71', XInventoryAdjustments, 2, 0, 1, '710..719999', 0, '', '', '', '');
        InsertData('72', XProducedFixedAssets, 2, 0, 0, '720..729999', 0, '', '', '', '');
        InsertData('74', XOtherOperatingIncome, 2, 0, 0, '740..749999', 0, '', '', '', '');
        InsertData('742000', XJobCostAdjustmentRetail, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('742010', XJobCostAdjustmentRawMat, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('742020', XJobCostAdjustmentResources, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('75', XFinancialIncome, 2, 0, 1, '750..759999', 0, '', '', '', '');
        InsertData('750000', XIncomefromLoans, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('750100', XInterestonBankAccountsRec, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('753000', XPaymentDiscReceived, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('754000', XUnrealizedExchRateDiff, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('754100', XRealizedExchRateDiff, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('754200', XInvoiceRounding, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('755000', XCashDiscrepancies, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('756200', XFinanceChargesfromCustomers, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', XS0);
        InsertData('76', XExtraordinaryIncome, 2, 0, 1, '760..769999', 0, '', '', '', '');
        InsertData('760000', XExtraordinaryIncome, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('763000', XGainsonDisposalFixedAssets, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('77', XTaxesDuePaid, 2, 0, 0, '770..779999', 0, '', '', '', '');
        InsertData('771000', XCorporateTax, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('78', XDeferredfromDutyfreeRes, 2, 0, 0, '780..789999', 0, '', '', '', '');
        InsertData('79', XProcessingofResult, 2, 0, 0, '790..799999', 0, '', '', '', '');
        InsertData('790000', XBenefitcarrfwfrPrevFY, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('793000', XLosstobecarriedforward, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('794000', XAssociateIntervinLoss, 0, 0, 0, '', 0, '', '', '', '');
        GLAccIndent.Indent();
    end;

    procedure AddBalanceSheetForMini()
    begin
        // Balance sheet 5000-9999
        DemoDataSetup.Get();
        InsertData('1', XOWNERSEQUITYANDDEBTSPLUS1YEAR, 2, 1, 1, '10..199999', 0, '', '', '', '');
        InsertData('10', XCapital, 2, 1, 1, '100..109999', 0, '', '', '', '');
        InsertData('100000', XStockCapital, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('101000', XNotcalledupStockCapital, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('110000', XIssuingpremiums, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('120000', XPlusvaluesofreevaluation, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('130000', XReserve, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('140000', XRetainedEarnings, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('150000', XCapitalSubventions, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('160000', XAllowancesforDoubtfulAcc, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('168000', XDeferredTaxes, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('17', XDebtsdueatplus1Year, 2, 1, 0, '170..179999', 0, '', '', '', '');
        InsertData('170000', XLongtermBankLoans, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('174000', XMortgage, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('2', XFIXEDASSANDCREDITSPLUS1YEAR, 2, 1, 1, '20..299999', 0, '', '', '', '');
        InsertData('20', XPreliminaryExpenses, 2, 1, 1, '200..209999', 0, '', '', '', '');
        InsertData('200000', XFormationandincrofcapital, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI0);
        InsertData('200009', XDeprecFormandincrofcap, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('21', XIntangibleAssets, 2, 1, 0, '210..219999', 0, '', '', '', '');
        InsertData('210000', XResearchandDevelopment, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('210009', XDeprResearchandDevelopment, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('22', XLandsandBuildings, 2, 1, 0, '220..229999', 0, '', '', '', '');
        InsertData('220000', XLandsandBuildings, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('220009', XDeprecBuildings, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('23', XEquipment, 2, 1, 0, '230..239999', 0, '', '', '', '');
        InsertData('230000', XEquipment, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('230009', XDeprecEquipment, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('24', XFurnituresandRollingStock, 2, 1, 0, '240..249999', 0, '', '', '', '');
        InsertData('240000', XFurnitures, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('240009', XDeprecFurnitures, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('241000', XOfficeEquipment, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('241009', XDeprecOfficeEquipment, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('242000', XComputerEquipment, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('242009', XDeprecComputerEquipment, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('245000', XRollingStock, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('245009', XDeprecRollingStock, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('25', XFixedAssetsonleasing, 2, 1, 0, '250..259999', 0, '', '', '', '');
        InsertData('250000', XLeasings, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI3);
        InsertData('250009', XDeprecLeasings, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('26', XOthertangibleFA, 2, 1, 0, '260..269999', 0, '', '', '', '');
        InsertData('260000', XOthertangibleFA, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XI0);
        InsertData('260009', XDeprecOthertangibleFA, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('3', XINVENTORYANDORDERS, 2, 1, 1, '30..399999', 0, '', '', '', '');
        InsertData('31', XAuxiliaryMaterials, 2, 1, 0, '310..319999', 0, '', '', '', '');
        InsertData('310000', XAuxiliaryMaterials, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('310010', XAuxiliaryMaterialsInterim, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('319000', XPosteddepreciations, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('32', XGoodsbeingmade, 2, 1, 0, '320..329999', 0, '', '', '', '');
        InsertData('320000', XGoodsbeingmade, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('320010', XGoodsbeingmadeInterim, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('329000', XPosteddepreciations, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('33', XFinishedGoods, 2, 1, 0, '330..339999', 0, '', '', '', '');
        InsertData('330000', XFinishedGoods, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('330010', XFinishedGoodsInterim, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('339000', XPosteddepreciations, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('34', XGoods, 2, 1, 0, '340..349999', 0, '', '', '', '');
        InsertData('340000', XGoods, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('340010', XGoodsInterim, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('349000', XPosteddepreciations, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('36', XPurchasePrepayments, 2, 1, 0, '360..369999', 0, '', '', '', '');
        InsertData('360000', XVendorPrepayments, 0, 1, 0, '', 0, '', DemoDataSetup.MiscCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('4', XDEBTSCREDITSDUEMINUS1YEAR, 2, 1, 1, '40..499999', 0, '', '', '', '');
        InsertData('40', XAccountsReceivable, 2, 1, 1, '400..409999', 0, '', '', '', '');
        InsertData('400000', XCustomersDomestic, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('400010', XCustomersForeign, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('401000', XBillsofExchReceivable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('404000', XCreditsReceivable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('406', XSalesPrepayments, 2, 1, 0, '406..406999', 0, '', '', '', '');
        InsertData('406000', XCustomerPrepayments, 0, 1, 0, '', 0, '', DemoDataSetup.MiscCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('407000', XDoubtfulDebtors, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('41', XOtherReceivables, 2, 1, 0, '410..419999', 0, '', '', '', '');
        InsertData('411000', XVATRecoverable, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XVAT);
        InsertData('417000', XOtherDoubtfulDebtors, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('42', XDebtsduewithinplus1Year, 2, 1, 0, '420..429999', 0, '', '', '', '');
        InsertData('43', XFinancialDebts, 2, 1, 0, '430..439999', 0, '', '', '', '');
        InsertData('433000', XBankAccount, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('44', XAccountsPayable, 2, 1, 0, '440..449999', 0, '', '', '', '');
        InsertData('440000', XVendorsDomestic, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('440010', XVendorsForeign, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('441000', XBillsofExchPayable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('45', XTaxesSalariesandSocCharges, 2, 1, 0, '450..459999', 0, '', '', '', '');
        InsertData('450000', XEstimatedTaxesPayable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('451000', XVATPayable, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XVAT);
        InsertData('452000', XTaxesPayable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('453', XPersonnelrelatedItems, 2, 1, 0, '4530..459999', 0, '', '', '', '');
        InsertData('453000', XRetainedDeductionsatSource, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('454000', XSocialSecurity, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('455000', XWagesandSalaries, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('456000', XVacationCompensationPayable, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('459000', XOtherSocialCharges, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('47', XDebtsbyResultAllocation, 2, 1, 0, '470..479999', 0, '', '', '', '');
        InsertData('470000', XDividendsFormerFiscalYrs, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('471000', XDividendsFiscalYear, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('48', XMiscellaneousDebts, 2, 1, 0, '480..489999', 0, '', '', '', '');
        InsertData('49', XTransitAccounts, 2, 1, 0, '490..499999', 0, '', '', '', '');
        InsertData('5', XINVESTMENTSANDLIQUIDITIES, 2, 1, 1, '50..599999', 0, '', '', '', '');
        InsertData('500000', XOwnersStockEquity, 0, 1, 1, '', 0, '', '', '', '');
        InsertData('510000', XStocks, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('52', XSecurities, 2, 1, 0, '520..529999', 0, '', '', '', '');
        InsertData('55', XLiquidAssets, 2, 1, 0, '550..559999', 0, '', '', '', '');
        InsertData('550000', XBankLocalCurrency, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('550005', XBankProcessing, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('550010', XBankForeignCurrency, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('560000', XPostAccount, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('570000', XCashAccount, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('580000', XTransfers, 0, 1, 0, '', 0, '', '', '', '');
        InsertData('6', XEXPENSES, 2, 0, 1, '60..699999', 0, '', '', '', '');
        InsertData('60', XGoodsRawandAuxMaterials, 2, 0, 1, '600..609999', 0, '', '', '', '');
        InsertData('600', XPurchasesRawMaterials, 2, 0, 0, '6000..600999', 0, '', '', '', '');
        InsertData('601', XPurchasesAuxiliaryMaterials, 2, 0, 0, '6010..601999', 0, '', '', '', '');
        InsertData('602', XPurchasesServices, 2, 0, 0, '6020..602999', 0, '', '', '', '');
        InsertData('602000', XResourceUsageCosts, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('602010', XJobCosts, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('603', XGeneralSubcontractings, 2, 0, 0, '6030..603999', 0, '', '', '', '');
        InsertData('604', XPurchasesofGoods, 2, 0, 0, '6040..604999', 0, '', '', '', '');
        InsertData('604000', XPurchasesRetailDom, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('604010', XPurchasesRetailEU, 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('604020', XPurchasesRetailExport, 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('608', XDiscountsReceived, 2, 0, 0, '6080..608999', 0, '', '', '', '');
        InsertData('608000', XDiscReceivedRawMaterials, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('608400', XDiscReceivedRetail, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('609', XInventoryAdjustments, 2, 0, 0, '6090..609999', 0, '', '', '', '');
        InsertData('609170', XInventAdjRetail, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('609171', XInventAdjRetailInt, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('609180', XJobCostAdjustmentRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('609270', XInventAdjRawMat, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('609271', XInventAdjRawMatInt, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('609280', XJobCostAdjustmentRawMat, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('609480', XJobCostAdjustmentResources, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('61', XServicesandInvestmentGoods, 2, 0, 1, '610..619999', 0, '', '', '', '');
        InsertData('610000', XRentBuildingsRSEquipm, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('611000', XRandMBuildingsandEquipm, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('611300', XRandMRollingStock, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('611400', XCleaningProducts, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612000', XElectricityWaterandHeating, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612120', XGasolineandMotorOil, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612200', XPhoneandFax, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612400', XPostage, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('612500', XOfficeSupplies, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612600', XSoftware, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612610', XConsultantServices, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612620', XOtherComputerExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('612800', XMailings, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613100', XInsurancesRSFire, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('613230', XLawyersandAccountants, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613310', XLegalContests, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613390', XOtherServiceCharges, 2, 0, 0, '613390..613399', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613395', XPurchaseCostsRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('613399', XPurchaseCostsInterim, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('613900', XTravel, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('613935', XTranspCostspurchRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode());
        InsertData('614000', XAdvertising, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('614500', XEntertainmentandPR, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('62', XSocialSecurity, 2, 0, 1, '620..629999', 0, '', '', '', '');
        InsertData('620200', XSalaries, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('620300', XWages, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('621000', XPayrollTaxes, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('623000', XOtherPersonnelExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('624000', XRetirementPlanContributions, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('63', XDepreciations, 2, 0, 1, '630..639999', 0, '', '', '', '');
        InsertData('630000', XDeprecFormandincrofcap, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('630200', XDeprecLandandBuildings, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('630210', XDeprecEquipment, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('630220', XDeprecRollingStock, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('64', XOtherOperatingExpenses, 2, 0, 1, '640..649999', 0, '', '', '', '');
        InsertData('640100', XVehicleTaxes, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('640200', XFines, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('643000', XMiscCostsofOperations, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.ServicesVATCode());
        InsertData('65', XFinancialCharges, 2, 0, 1, '650..659999', 0, '', '', '', '');
        InsertData('650000', XInterestonBankBalances, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('650010', XInterestonBankAccount, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('650020', XMortgage, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('653000', XPaymentDiscountsGranted, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('654000', XUnrealizedExchRateDiff, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('654100', XRealizedExchRateDiff, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('655000', XCashDiscrepancies, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('66', XExtraordinaryExpenses, 2, 0, 1, '660..669999', 0, '', '', '', '');
        InsertData('660000', XExtraordinaryExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('663000', XLossesDisposalFixedAssets, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('67', XCorporateTax, 2, 0, 0, '670..679999', 0, '', '', '', '');
        InsertData('670000', XCorporateTax, 0, 0, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', XS0);
        InsertData('68', XTransfertodutyfreereserve, 2, 0, 0, '680..689999', 0, '', '', '', '');
        InsertData('69', XProcessingofResult, 2, 0, 0, '690..699999', 0, '', '', '', '');
        InsertData('690000', XLosscarrforwfrPrevFY, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('691000', XAddcapitalandissuingprem, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('692000', XAddreserves, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('693000', XProfittobecarriedforward, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('694000', XReturnonCapital, 0, 0, 0, '', 0, '', '', '', '');
        InsertData('695000', XDirectorsremuneration, 0, 0, 0, '', 0, '', '', '', '');
    end;

    procedure InsertData(AccountNo: Code[20]; AccountName: Text[50]; AccountType: Option; IncomeBalance: Option; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", AccountNo);
        GLAccount.Validate(Name, AccountName);
        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then
            GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Income/Balance", "G/L Account Report Type".FromInteger(IncomeBalance));
        case AccountNo of
            '550000', '550005', '550010', '560000', '570000':
                begin
                    ;
                    GLAccount."Reconciliation Account" := true;
                    GLAccount."Print Details" := false;
                end;
            '400000', '400010', '440000', '440010':
                begin
                    ;
                    GLAccount.Validate("Direct Posting", false);
                    GLAccount."Print Details" := false;
                end;
            '411000', '451000':
                GLAccount."Print Details" := false;
            '612120':
                GLAccount.Validate("% Non deductible VAT", 50);
            '580000', '695000':
                GLAccount."New Page" := true;
        end;
        GLAccount.Validate("No. of Blank Lines", NoOfBlankLines);
        if Totaling <> '' then
            GLAccount.Validate(Totaling, Totaling);
        if GenPostingType > 0 then
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
        if GenBusPostingGroup <> '' then
            GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        if GenProdPostingGroup <> '' then
            GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        if VATGenPostingGroup <> '' then
            GLAccount.Validate("VAT Bus. Posting Group", VATGenPostingGroup);
        if VATProdPostingGroup <> '' then
            GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Insert();
    end;

    procedure AddCategoriesToGLAccounts()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if GLAccountCategory.IsEmpty() then
            exit;

        GLAccountCategory.SetRange("Parent Entry No.", 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignCategoryToChartOfAccounts(GLAccountCategory);
                AssignCategoryToLocalChartOfAccounts(GLAccountCategory);
            until GLAccountCategory.Next() = 0;

        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignSubcategoryToChartOfAccounts(GLAccountCategory);
                AssignSubcategoryToLocalChartOfAccounts(GLAccountCategory);
            until GLAccountCategory.Next() = 0;
    end;

    procedure AssignCategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Assets:
                begin
                    UpdateGLAccounts(GLAccountCategory, '2', '6');
                    UpdateGLAccounts(GLAccountCategory, '20', '43');
                    UpdateGLAccounts(GLAccountCategory, '47', '60');
                    UpdateGLAccounts(GLAccountCategory, '63', '63');
                    UpdateGLAccounts(GLAccountCategory, '406', '406');
                    UpdateGLAccounts(GLAccountCategory, '493', '609');
                    UpdateGLAccounts(GLAccountCategory, '200000', '433000');
                    UpdateGLAccounts(GLAccountCategory, '470000', '609895');
                    // UpdateGLAccounts(GLAccountCategory,'630000','630220');
                end;
            GLAccountCategory."Account Category"::Liabilities:
                begin
                    UpdateGLAccounts(GLAccountCategory, '17', '17');
                    UpdateGLAccounts(GLAccountCategory, '44', '45');
                    UpdateGLAccounts(GLAccountCategory, '453', '453');
                    UpdateGLAccounts(GLAccountCategory, '170000', '174000');
                    UpdateGLAccounts(GLAccountCategory, '440000', '459000');
                end;
            GLAccountCategory."Account Category"::Equity:
                begin
                    UpdateGLAccounts(GLAccountCategory, '1', '1');
                    UpdateGLAccounts(GLAccountCategory, '10', '10');
                    UpdateGLAccounts(GLAccountCategory, '69', '69');
                    UpdateGLAccounts(GLAccountCategory, '100000', '168000');
                    UpdateGLAccounts(GLAccountCategory, '690000', '695010');
                end;
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, '7', '7');
                    UpdateGLAccounts(GLAccountCategory, '70', '70');
                    UpdateGLAccounts(GLAccountCategory, '700', '705');
                    UpdateGLAccounts(GLAccountCategory, '695000', '708000');
                    UpdateGLAccounts(GLAccountCategory, '999410', '999410');
                end;
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                begin
                    UpdateGLAccounts(GLAccountCategory, '997100', '997995');
                    UpdateGLAccounts(GLAccountCategory, '997705', '997795');
                end;
            GLAccountCategory."Account Category"::Expense:
                begin
                    UpdateGLAccounts(GLAccountCategory, '61', '62');
                    UpdateGLAccounts(GLAccountCategory, '64', '68');
                    UpdateGLAccounts(GLAccountCategory, '71', '79');
                    UpdateGLAccounts(GLAccountCategory, '610000', '624000');
                    UpdateGLAccounts(GLAccountCategory, '640100', '670000');
                    UpdateGLAccounts(GLAccountCategory, '742000', '794000');
                end;
        end;
    end;

    procedure AssignSubcategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCurrentAssets(): // 2
                begin
                    UpdateGLAccounts(GLAccountCategory, '5', '5');
                    UpdateGLAccounts(GLAccountCategory, '49', '52');
                    UpdateGLAccounts(GLAccountCategory, '493', '493');
                    UpdateGLAccounts(GLAccountCategory, '493010', '520000');
                end;
            GLAccountCategoryMgt.GetCash(): // 3
                begin
                    UpdateGLAccounts(GLAccountCategory, '55', '55');
                    UpdateGLAccounts(GLAccountCategory, '550000', '580000');
                end;
            GLAccountCategoryMgt.GetAR(): // 4
                begin
                    UpdateGLAccounts(GLAccountCategory, '4', '4');
                    UpdateGLAccounts(GLAccountCategory, '40', '43');
                    UpdateGLAccounts(GLAccountCategory, '47', '48');
                    UpdateGLAccounts(GLAccountCategory, '406', '406');
                    UpdateGLAccounts(GLAccountCategory, '400000', '433000');
                    UpdateGLAccounts(GLAccountCategory, '470000', '471000');
                end;
            GLAccountCategoryMgt.GetInventory(): // 6
                begin
                    UpdateGLAccounts(GLAccountCategory, '3', '3');
                    UpdateGLAccounts(GLAccountCategory, '6', '6');
                    UpdateGLAccounts(GLAccountCategory, '30', '36');
                    UpdateGLAccounts(GLAccountCategory, '60', '60');
                    UpdateGLAccounts(GLAccountCategory, '600', '609');
                    UpdateGLAccounts(GLAccountCategory, '300000', '360000');
                    UpdateGLAccounts(GLAccountCategory, '600000', '609895');
                end;
            GLAccountCategoryMgt.GetFixedAssets(): // 7
                begin
                    UpdateGLAccounts(GLAccountCategory, '2', '2');
                    UpdateGLAccounts(GLAccountCategory, '20', '22');
                    UpdateGLAccounts(GLAccountCategory, '24', '26');
                    UpdateGLAccounts(GLAccountCategory, '200000', '200000');
                    UpdateGLAccounts(GLAccountCategory, '210000', '210000');
                    UpdateGLAccounts(GLAccountCategory, '220000', '220000');
                    UpdateGLAccounts(GLAccountCategory, '240000', '240000');
                    UpdateGLAccounts(GLAccountCategory, '241000', '241000');
                    UpdateGLAccounts(GLAccountCategory, '242000', '242000');
                    UpdateGLAccounts(GLAccountCategory, '245000', '245000');
                    UpdateGLAccounts(GLAccountCategory, '260000', '260000');
                end;
            GLAccountCategoryMgt.GetEquipment(): // 8
                begin
                    UpdateGLAccounts(GLAccountCategory, '23', '23');
                    UpdateGLAccounts(GLAccountCategory, '230000', '230000');
                end;
            GLAccountCategoryMgt.GetAccumDeprec(): // 9
                begin
                    UpdateGLAccounts(GLAccountCategory, '63', '63');
                    UpdateGLAccounts(GLAccountCategory, '200009', '200009');
                    UpdateGLAccounts(GLAccountCategory, '210009', '210009');
                    UpdateGLAccounts(GLAccountCategory, '220009', '220009');
                    UpdateGLAccounts(GLAccountCategory, '230009', '230009');
                    UpdateGLAccounts(GLAccountCategory, '240009', '240009');
                    UpdateGLAccounts(GLAccountCategory, '241009', '241009');
                    UpdateGLAccounts(GLAccountCategory, '242009', '242009');
                    UpdateGLAccounts(GLAccountCategory, '245009', '245009');
                    UpdateGLAccounts(GLAccountCategory, '250009', '250009');
                    UpdateGLAccounts(GLAccountCategory, '260009', '260009');
                    // UpdateGLAccounts(GLAccountCategory,'630000','630220');
                end;
            GLAccountCategoryMgt.GetCurrentLiabilities(): // 11
                begin
                    UpdateGLAccounts(GLAccountCategory, '44', '44');
                    UpdateGLAccounts(GLAccountCategory, '440000', '452000');
                end;
            GLAccountCategoryMgt.GetPayrollLiabilities(): // 12
                begin
                    UpdateGLAccounts(GLAccountCategory, '45', '45');
                    UpdateGLAccounts(GLAccountCategory, '453', '453');
                    UpdateGLAccounts(GLAccountCategory, '453000', '459000');
                end;
            GLAccountCategoryMgt.GetLongTermLiabilities(): // 13
                begin
                    UpdateGLAccounts(GLAccountCategory, '17', '17');
                    UpdateGLAccounts(GLAccountCategory, '170000', '174000');
                end;
            GLAccountCategoryMgt.GetCommonStock(): // 15
                begin
                    UpdateGLAccounts(GLAccountCategory, '1', '1');
                    UpdateGLAccounts(GLAccountCategory, '10', '10');
                    UpdateGLAccounts(GLAccountCategory, '100000', '100000');
                end;
            GLAccountCategoryMgt.GetRetEarnings(): // 16
                UpdateGLAccounts(GLAccountCategory, '101000', '101000');
            GLAccountCategoryMgt.GetDistrToShareholders(): // 17
                ;
            GLAccountCategoryMgt.GetIncomeService(): // 19
                begin
                    UpdateGLAccounts(GLAccountCategory, '702', '705');
                    UpdateGLAccounts(GLAccountCategory, '702000', '708000');
                end;
            GLAccountCategoryMgt.GetIncomeProdSales(): //20
                begin
                    UpdateGLAccounts(GLAccountCategory, '700', '701');
                    UpdateGLAccounts(GLAccountCategory, '700000', '701020');
                end;
            GLAccountCategoryMgt.GetIncomeSalesDiscounts(): // 22
                begin
                    UpdateGLAccounts(GLAccountCategory, '39', '39');
                    UpdateGLAccounts(GLAccountCategory, '3900', '3999');
                end;
            GLAccountCategoryMgt.GetIncomeSalesReturns(): // 23
                ;
            GLAccountCategoryMgt.GetIncomeInterest(): // 24
                begin
                    UpdateGLAccounts(GLAccountCategory, '68', '68');
                    UpdateGLAccounts(GLAccountCategory, '680', '685');
                    UpdateGLAccounts(GLAccountCategory, '6800', '6899');
                end;
            GLAccountCategoryMgt.GetJobSalesContra(): //25
                ;
            GLAccountCategoryMgt.GetCOGSLabor(): // 27
                UpdateGLAccounts(GLAccountCategory, '7705', '7795');
            GLAccountCategoryMgt.GetRentExpense(): // 32
                UpdateGLAccounts(GLAccountCategory, '610000', '610000');
            GLAccountCategoryMgt.GetAdvertisingExpense(): // 33
                UpdateGLAccounts(GLAccountCategory, '614000', '614500');
            GLAccountCategoryMgt.GetInterestExpense(): // 34
                begin
                    UpdateGLAccounts(GLAccountCategory, '65', '65');
                    UpdateGLAccounts(GLAccountCategory, '650000', '656100');
                    UpdateGLAccounts(GLAccountCategory, '656000', '656100');
                end;
            GLAccountCategoryMgt.GetFeesExpense(): // 35
                ;
            GLAccountCategoryMgt.GetInsuranceExpense(): // 36
                ;
            GLAccountCategoryMgt.GetBenefitsExpense(): // 38
                ;
            GLAccountCategoryMgt.GetSalariesExpense(): // 39
                begin
                    UpdateGLAccounts(GLAccountCategory, '62', '62');
                    UpdateGLAccounts(GLAccountCategory, '620200', '624000');
                end;
            GLAccountCategoryMgt.GetOtherIncomeExpense(): // 42
                begin
                    UpdateGLAccounts(GLAccountCategory, '61', '61');
                    UpdateGLAccounts(GLAccountCategory, '64', '64');
                    UpdateGLAccounts(GLAccountCategory, '66', '66');
                    UpdateGLAccounts(GLAccountCategory, '71', '79');
                    UpdateGLAccounts(GLAccountCategory, '611000', '613935');
                    UpdateGLAccounts(GLAccountCategory, '640100', '643000');
                    UpdateGLAccounts(GLAccountCategory, '660000', '663000');
                    UpdateGLAccounts(GLAccountCategory, '742000', '794000');
                end;
            GLAccountCategoryMgt.GetTaxExpense(): // 43
                begin
                    UpdateGLAccounts(GLAccountCategory, '67', '68');
                    UpdateGLAccounts(GLAccountCategory, '670000', '670000');
                end;
        end;
    end;

    local procedure UpdateGLAccounts(GLAccountCategory: Record "G/L Account Category"; FromGLAccountNo: Code[20]; ToGLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if not TryGetGLAccountNoRange(GLAccount, FromGLAccountNo, ToGLAccountNo) then
            exit;

        GLAccount.ModifyAll("Account Category", GLAccountCategory."Account Category", false);
        GLAccount.ModifyAll("Account Subcategory Entry No.", GLAccountCategory."Entry No.", false);
    end;

    [TryFunction]
    local procedure TryGetGLAccountNoRange(var GLAccount: Record "G/L Account"; FromGLAccountNo: Code[20]; ToGLAccountNo: Code[20])
    begin
        GLAccount.SetRange("No.", FromGLAccountNo, ToGLAccountNo);
    end;

    local procedure AssignCategoryToLocalChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccountCategory.Find();
        // Reserved for local chart of accounts
    end;

    local procedure AssignSubcategoryToLocalChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccountCategory.Find();
        // Reserved for local chart of accounts
    end;
}

