codeunit 101015 "Create G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('991000', XBALANCESHEET, 1, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991002', XASSETS, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('991003', XFixedAssets, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('991005', XTangibleFixedAssets, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991100', XLandandBuildings, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991110', XLandandBuildings, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991120', XIncreasesduringtheYear, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('991130', XDecreasesduringtheYear, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('991140', XAccumDepreciationBuildings, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991190', XLandandBuildingsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991200', XOperatingEquipment, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991210', XOperatingEquipment, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991220', XIncreasesduringtheYear, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991230', XDecreasesduringtheYear, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('991240', XAccumDeprOperEquip, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991290', XOperatingEquipmentTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991300', XVehicles, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991310', XVehicles, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991320', XIncreasesduringtheYear, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991330', XDecreasesduringtheYear, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('991340', XAccumDepreciationVehicles, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991390', XVehiclesTotal, 4, 1, 0,
          Adjust.Convert('991300') + '..' + Adjust.Convert('991390'), 0, '', '', '', '', true);
        InsertData('991395', XTangibleFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991999', XFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992000', XCurrentAssets, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('992100', XInventory, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992110', XResaleItems, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992111', XResaleItemsInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992112', XCostofResaleSoldInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992120', XFinishedGoods, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992121', XFinishedGoodsInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992130', XRawMaterials, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992131', XRawMaterialsInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992132', XCostofRawMatSoldInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992180', XPrimoInventory, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992190', XInventoryTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992200', XJobWIP, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992210', XWIPSales, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992211', XWIPJobSales, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992212', XInvoicedJobSales, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992220', XWIPSalesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992230', XWIPCosts, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992231', XWIPJobCosts, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992232', XAccruedJobCosts, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992240', XWIPCostsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992290', XJobWIPTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992300', XAccountsReceivable, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992310', XCustomersDomestic, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992320', XCustomersForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992330', XAccruedInterest, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992340', XOtherReceivables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992390', XAccountsReceivableTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992400', XPurchasePrepayments, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992410', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.NoVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.NoVATCode(), '', DemoDataSetup.NoVATCode(), false);
        InsertData('992420', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode(), false);
        InsertData('992430', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode(), false);
        InsertData('992440', XPurchasePrepaymentsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992800', XSecurities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992810', XBonds, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992890', XSecuritiesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992900', XLiquidAssets, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992910', XCash, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992920', XBankLCY, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992930', XBankCurrencies, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992940', XGiroAccount, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992990', XLiquidAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992995', XCurrentAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992999', XTOTALASSETS, 4, 1, 1, '', 0, '', '', '', '', true);
        InsertData('993000', XLIABILITIESANDEQUITY, 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData('993100', XStockholdersEquity, 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData('993110', XCapitalStock, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('993120', XRetainedEarnings, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('993195', XNetIncomefortheYear, 2, 1, 0,
          Adjust.Convert('996000') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        InsertData('993199', XTotalStockholdersEquity, 2, 1, 0,
          Adjust.Convert('993100') + '..' + Adjust.Convert('993199') +
          '|' + Adjust.Convert('996000') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        InsertData('994000', XAllowances, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('994010', XDeferredTaxes, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('994999', XAllowancesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995000', XLiabilities, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('995100', XLongtermLiabilities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995110', XLongtermBankLoans, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995120', XMortgage, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995290', XLongtermLiabilitiesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995300', XShorttermLiabilities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995310', XRevolvingCredit, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995350', XSalesPrepayments, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995360', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.NoVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.NoVATCode(), '', DemoDataSetup.NoVATCode(), false);
        InsertData('995370', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode(), false);
        InsertData('995380', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode(), false);
        InsertData('995390', XCustomerPrepaymentsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995400', XAccountsPayable, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995410', XVendorsDomestic, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995420', XVendorsForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995490', XAccountsPayableTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995500', XInvAdjmtInterim, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995510', XInvAdjmtInterimRetail, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995530', XInvAdjmtInterimRawMat, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995590', XInvAdjmtInterimTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995600', XVAT, 3, 1, 0, '', 0, '', '', '', '', true);
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::"Sales Tax":
                if DemoDataSetup."Advanced Setup" then begin
                    InsertData('995610', XSalesTAXGA, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995611', XSalesTAXFL, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995612', XSalesTAXIL, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995620', XUseTAXGAReversing, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995621', XUseTAXFLReversing, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995622', XUseTAXILReversing, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995630', XUseTAXGA, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995631', XUseTAXFL, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995632', XUseTAXIL, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995615', XSalesTAXGAUnrealized, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995625', XUseTAXGAReversingUnrealized, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995635', XUseTAXGAUnrealized, 0, 1, 0, '', 0, '', '', '', '', true);
                end else begin
                    InsertData('995610', XSalesTaxTok, 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('995620', XPurchaseTaxTok, 0, 1, 0, '', 0, '', '', '', '', true);
                end;
            DemoDataSetup."Company Type"::VAT:
                begin
                    InsertData('995610', StrSubstNo(XSalesVATPERCENT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                    InsertData('995611', StrSubstNo(XSalesVATPERCENT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                    InsertData('995620', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                    InsertData('995621', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                    InsertData('995630', StrSubstNo(XPurchaseVATPERCENT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                    InsertData('995631', StrSubstNo(XPurchaseVATPERCENT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                    if DemoDataSetup."Advanced Setup" then begin
                        InsertData('995615', StrSubstNo(XSalesVATPERCENTUnrealized, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995616', StrSubstNo(XSalesVATPERCENTUnrealized, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995625', StrSubstNo(XPurchaseVATPERCENTEUUnreal, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995626', StrSubstNo(XPurchaseVATPERCENTEUUnreal, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995635', StrSubstNo(XPurchaseVATPCTUnrealized, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995636', StrSubstNo(XPurchaseVATPCTUnrealized, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
                    end;
                end;
        end;
        InsertData('995710', XFuelTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995720', XElectricityTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995730', XNaturalGasTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995740', XCoalTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995750', XCO2Tax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995760', XWaterTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995780', XVATPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995790', XVATTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995800', XPersonnelrelatedItems, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995810', XWithholdingTaxesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995820', XSupplementaryTaxesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995830', XPayrollTaxesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995840', XVacationCompensationPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995850', XEmployeesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995890', XTotalPersonnelrelatedItems, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995900', XOtherLiabilities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995910', XDividendsfortheFiscalYear, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995920', XCorporateTaxesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995990', XOtherLiabilitiesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995995', XShorttermLiabilitiesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995997', XTotalLiabilities, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995999', XTOTALLIABILITIESANDEQUITY, 2, 1, 1,
          Adjust.Convert('993000') + '..' + Adjust.Convert('995999') +
          '|' + Adjust.Convert('996000') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        InsertData('996000', XINCOMESTATEMENT, 1, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996100', XRevenue, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('996105', XSalesofRetail, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996110', XSalesRetailDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('996120', XSalesRetailEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996130', XSalesRetailExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('996190', XJobSalesAppRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('996191', XJobSalesAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('996195', XTotalSalesofRetail, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996205', XSalesofRawMaterials, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996210', XSalesRawMaterialsDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('996220', XSalesRawMaterialsEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('996230', XSalesRawMaterialsExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('996290', XJobSalesAppRawMat, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('996291', XJobSalesAdjmtRawMat, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('996295', XTotalSalesofRawMaterials, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996405', XSalesofResources, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996410', XSalesResourcesDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('996420', XSalesResourcesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('996430', XSalesResourcesExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('996490', XJobSalesAppResources, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('996491', XJobSalesAdjmtResources, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('996495', XTotalSalesofResources, 4, 0, 0, '', 0, '', '', '', '', true);

        InsertData('996605', XSalesofJobs, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996610', XSalesOtherJobExpenses, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', DemoDataSetup.GoodsVATCode(), true);
        InsertData('996620', XJobSales, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996695', XTotalSalesofJobs, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996710', XConsultingFeesDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('996810', XFeesandChargesRecDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('996910', XDiscountGranted, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('996995', XTotalRevenue, 4, 0, 0, '', 0, '', '', '', '', true);

        InsertData('997100', XCost, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('997105', XCostofRetail, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997110', XPurchRetailDom, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('997120', XPurchRetailEU, 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('997130', XPurchRetailExport, 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('997140', XDiscReceivedRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997150', XDeliveryExpensesRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('997170', XInventoryAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997180', XJobCostAppRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997181', XJobCostAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997190', XCostofRetailSold, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997195', XTotalCostofRetail, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997205', XCostofRawMaterials, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997210', XPurchRawMaterialsDom, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('997220', XPurchRawMaterialsEU, 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('997230', XPurchRawMaterialsExport, 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('997240', XDiscReceivedRawMaterials, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997250', XDeliveryExpensesRawMat, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('997270', XInventoryAdjmtRawMat, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997280', XJobCostAppRawMaterials, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997281', XJobCostAdjmtRawMaterials, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997290', XCostofRawMaterialsSold, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997295', XTotalCostofRawMaterials, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997405', XCostofResources, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997480', XJobCostAppResources, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997481', XJobCostAdjmtResources, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997490', XCostofResourcesUsed, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997495', XTotalCostofResources, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997620', XJobCosts, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997995', XTotalCost, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998000', XOperatingExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('998100', XBuildingMaintenanceExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998110', XCleaning, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998120', XElectricityandHeating, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998130', XRepairsandMaintenance, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998190', XTotalBldgMaintExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998200', XAdministrativeExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998210', XOfficeSupplies, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998230', XPhoneandFax, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998240', XPostage, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('998290', XTotalAdministrativeExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998300', XComputerExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998310', XSoftware, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998320', XConsultantServices, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('998330', XOtherComputerExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998390', XTotalComputerExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998400', XSellingExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998410', XAdvertising, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998420', XEntertainmentandPR, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998430', XTravel, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('998450', XDeliveryExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998490', XTotalSellingExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998500', XVehicleExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998510', XGasolineandMotorOil, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998520', XRegistrationFees, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('998530', XRepairsandMaintenance, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998590', XTotalVehicleExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998600', XOtherOperatingExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998610', XCashDiscrepancies, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998620', XBadDebtExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998630', XLegalandAccountingServices, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998640', XMiscellaneous, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998690', XOtherOperatingExpTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998695', XTotalOperatingExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998700', XPersonnelExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998710', XWages, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998720', XSalaries, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998730', XRetirementPlanContributions, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998740', XVacationCompensation, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998750', XPayrollTaxes, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998790', XTotalPersonnelExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998800', XDepreciationofFixedAssets, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998810', XDepreciationBuildings, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998820', XDepreciationEquipment, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998830', XDepreciationVehicles, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998840', XGainsandLosses, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('998890', XTotalFixedAssetDepreciation, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998910', XOtherCostsofOperations, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998995', XNetOperatingIncome, 2, 0, 1,
          Adjust.Convert('996000') + '..' + Adjust.Convert('998995'), 0, '', '', '', '', true);
        InsertData('999100', XInterestIncome, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999110', XInterestonBankBalances, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999120', XFinanceChargesfromCustomers, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('999130', XPaymentDiscountsReceived, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999135', XPmtDiscReceivedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999160', XPaymentToleranceReceived, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999170', XPmtTolReceivedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999140', XInvoiceRounding, 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', false);
        InsertData('999150', XApplicationRounding, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999190', XTotalInterestIncome, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999200', XInterestExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999210', XInterestonRevolvingCredit, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999220', XInterestonBankLoans, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999230', XMortgageInterest, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999240', XFinanceChargestoVendors, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999250', XPaymentDiscountsGranted, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999255', XPmtDiscGrantedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999260', XPaymentToleranceGranted, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999270', XPmtTolGrantedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999290', XTotalInterestExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999310', XUnrealizedFXGains, 0, 0, 1, '', 0, '', '', '', '', false);
        InsertData('999320', XUnrealizedFXLosses, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999330', XRealizedFXGains, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999340', XRealizedFXLosses, 0, 0, 0, '', 0, '', '', '', '', false);
        if DemoDataSetup."Additional Currency Code" <> '' then begin
            InsertData('999350', XResidualGains, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('999360', XResidualLosses, 0, 0, 0, '', 0, '', '', '', '', false);
        end;
        InsertData('999395', XNIBEFOREEXTRAITEMSANDTAXES, 2, 0, 1,
          Adjust.Convert('996000') + '..' + Adjust.Convert('999395'), 0, '', '', '', '', true);
        InsertData('999410', XExtraordinaryIncome, 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999420', XExtraordinaryExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999495', XNETINCOMEBEFORETAXES, 2, 0, 0,
          Adjust.Convert('996000') + '..' + Adjust.Convert('999495'), 0, '', '', '', '', true);
        InsertData('999510', XCorporateTax, 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999999', XNETINCOME, 2, 0, 1,
          Adjust.Convert('996000') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        GLAccIndent.Indent();
        // AddCategoriesToGLAccounts();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Adjust: Codeunit "Make Adjustments";
        GLAccIndent: Codeunit "G/L Account-Indent";
        XBALANCESHEET: Label 'BALANCE SHEET';
        XASSETS: Label 'ASSETS';
        XFixedAssets: Label 'Fixed Assets';
        XTangibleFixedAssets: Label 'Tangible Fixed Assets';
        XLandandBuildings: Label 'Land and Buildings';
        XIncreasesduringtheYear: Label 'Increases during the Year';
        XDecreasesduringtheYear: Label 'Decreases during the Year';
        XAccumDepreciationBuildings: Label 'Accum. Depreciation, Buildings';
        XLandandBuildingsTotal: Label 'Land and Buildings, Total';
        XOperatingEquipment: Label 'Operating Equipment';
        XAccumDeprOperEquip: Label 'Accum. Depr., Oper. Equip.';
        XOperatingEquipmentTotal: Label 'Operating Equipment, Total';
        XVehicles: Label 'Vehicles';
        XAccumDepreciationVehicles: Label 'Accum. Depreciation, Vehicles';
        XVehiclesTotal: Label 'Vehicles, Total';
        XTangibleFixedAssetsTotal: Label 'Tangible Fixed Assets, Total';
        XFixedAssetsTotal: Label 'Fixed Assets, Total';
        XCurrentAssets: Label 'Current Assets';
        XInventory: Label 'Inventory';
        XResaleItems: Label 'Resale Items';
        XResaleItemsInterim: Label 'Resale Items (Interim)';
        XCostofResaleSoldInterim: Label 'Cost of Resale Sold (Interim)';
        XFinishedGoods: Label 'Finished Goods';
        XFinishedGoodsInterim: Label 'Finished Goods (Interim)';
        XRawMaterials: Label 'Raw Materials';
        XRawMaterialsInterim: Label 'Raw Materials (Interim)';
        XCostofRawMatSoldInterim: Label 'Cost of Raw Mat.Sold (Interim)';
        XPrimoInventory: Label 'Primo Inventory';
        XInventoryTotal: Label 'Inventory, Total';
        XJobWIP: Label 'Job WIP';
        XWIPSales: Label 'WIP Sales';
        XWIPCosts: Label 'WIP Costs';
        XJobWIPTotal: Label 'Job WIP, Total';
        XAccountsReceivable: Label 'Accounts Receivable';
        XCustomersDomestic: Label 'Customers Domestic';
        XCustomersForeign: Label 'Customers, Foreign';
        XAccruedInterest: Label 'Accrued Interest';
        XOtherReceivables: Label 'Other Receivables';
        XAccountsReceivableTotal: Label 'Accounts Receivable, Total';
        XSecurities: Label 'Securities';
        XBonds: Label 'Bonds';
        XSecuritiesTotal: Label 'Securities, Total';
        XLiquidAssets: Label 'Liquid Assets';
        XCash: Label 'Cash';
        XBankLCY: Label 'Bank, LCY';
        XBankCurrencies: Label 'Bank Currencies';
        XGiroAccount: Label 'Giro Account';
        XLiquidAssetsTotal: Label 'Liquid Assets, Total';
        XCurrentAssetsTotal: Label 'Current Assets, Total';
        XTOTALASSETS: Label 'TOTAL ASSETS';
        XLIABILITIESANDEQUITY: Label 'LIABILITIES AND EQUITY';
        XStockholdersEquity: Label 'Stockholder''s Equity';
        XCapitalStock: Label 'Capital Stock';
        XRetainedEarnings: Label 'Retained Earnings';
        XNetIncomefortheYear: Label 'Net Income for the Year';
        XTotalStockholdersEquity: Label 'Total Stockholder''s Equity';
        XAllowances: Label 'Allowances';
        XDeferredTaxes: Label 'Deferred Taxes';
        XAllowancesTotal: Label 'Allowances, Total';
        XLiabilities: Label 'Liabilities';
        XLongtermLiabilities: Label 'Long-term Liabilities';
        XLongtermBankLoans: Label 'Long-term Bank Loans';
        XMortgage: Label 'Mortgage';
        XLongtermLiabilitiesTotal: Label 'Long-term Liabilities, Total';
        XShorttermLiabilities: Label 'Short-term Liabilities';
        XRevolvingCredit: Label 'Revolving Credit';
        XAccountsPayable: Label 'Accounts Payable';
        XVendorsDomestic: Label 'Vendors, Domestic';
        XVendorsForeign: Label 'Vendors, Foreign';
        XAccountsPayableTotal: Label 'Accounts Payable, Total';
        XInvAdjmtInterim: Label 'Inv. Adjmt. (Interim)';
        XInvAdjmtInterimRetail: Label 'Inv. Adjmt. (Interim), Retail';
        XInvAdjmtInterimRawMat: Label 'Inv. Adjmt. (Interim), Raw Mat';
        XInvAdjmtInterimTotal: Label 'Inv. Adjmt. (Interim), Total';
        XVAT: Label 'VAT';
        XSalesTAXGA: Label 'Sales TAX GA';
        XSalesTAXFL: Label 'Sales TAX FL';
        XSalesTAXIL: Label 'Sales TAX IL';
        XUseTAXGAReversing: Label 'Use TAX GA Reversing';
        XUseTAXFLReversing: Label 'Use TAX FL Reversing';
        XUseTAXILReversing: Label 'Use TAX IL Reversing';
        XUseTAXGA: Label 'Use TAX GA';
        XUseTAXFL: Label 'Use TAX FL';
        XUseTAXIL: Label 'Use TAX IL';
        XSalesTAXGAUnrealized: Label 'Sales TAX GA Unrealized';
        XUseTAXGAReversingUnrealized: Label 'Use TAX GA Reversing Unreal.';
        XUseTAXGAUnrealized: Label 'Use TAX GA Unrealized';
        XSalesVATPERCENT: Label 'Sales VAT %1';
        XSalesVATPERCENTUnrealized: Label 'Sales VAT %1 Unrealized';
        XPurchaseVATPERCENTEU: Label 'Purchase VAT %1 EU';
        XPurchaseVATPERCENTEUUnreal: Label 'Purchase VAT %1 EU Unreal.';
        XPurchaseVATPERCENT: Label 'Purchase VAT %1';
        XPurchaseVATPCTUnrealized: Label 'Purchase VAT %1 Unrealized';
        XPurchaseTaxTok: Label 'Purchase Tax';
        XSalesTaxTok: Label 'Sales Tax';
        XFuelTax: Label 'Fuel Tax';
        XElectricityTax: Label 'Electricity Tax';
        XNaturalGasTax: Label 'Natural Gas Tax';
        XCoalTax: Label 'Coal Tax';
        XCO2Tax: Label 'CO2 Tax';
        XWaterTax: Label 'Water Tax';
        XVATPayable: Label 'VAT Payable';
        XVATTotal: Label 'VAT, Total';
        XPersonnelrelatedItems: Label 'Personnel-related Items';
        XWithholdingTaxesPayable: Label 'Withholding Taxes Payable';
        XSupplementaryTaxesPayable: Label 'Supplementary Taxes Payable';
        XPayrollTaxesPayable: Label 'Payroll Taxes Payable';
        XVacationCompensationPayable: Label 'Vacation Compensation Payable';
        XEmployeesPayable: Label 'Employees Payable';
        XTotalPersonnelrelatedItems: Label 'Total Personnel-related Items';
        XOtherLiabilities: Label 'Other Liabilities';
        XDividendsfortheFiscalYear: Label 'Dividends for the Fiscal Year';
        XCorporateTaxesPayable: Label 'Corporate Taxes Payable';
        XOtherLiabilitiesTotal: Label 'Other Liabilities, Total';
        XShorttermLiabilitiesTotal: Label 'Short-term Liabilities, Total';
        XTotalLiabilities: Label 'Total Liabilities';
        XINCOMESTATEMENT: Label 'INCOME STATEMENT';
        XRevenue: Label 'Revenue';
        XSalesofRetail: Label 'Sales of Retail';
        XSalesRetailDom: Label 'Sales, Retail - Dom.';
        XSalesRetailEU: Label 'Sales, Retail - EU';
        XSalesRetailExport: Label 'Sales, Retail - Export';
        XJobSalesAdjmtRetail: Label 'Job Sales Adjmt., Retail';
        XTotalSalesofRetail: Label 'Total Sales of Retail';
        XSalesofRawMaterials: Label 'Sales of Raw Materials';
        XSalesRawMaterialsDom: Label 'Sales, Raw Materials - Dom.';
        XSalesRawMaterialsEU: Label 'Sales, Raw Materials - EU';
        XSalesRawMaterialsExport: Label 'Sales, Raw Materials - Export';
        XJobSalesAdjmtRawMat: Label 'Job Sales Adjmt., Raw Mat.';
        XTotalSalesofRawMaterials: Label 'Total Sales of Raw Materials';
        XSalesofResources: Label 'Sales of Resources';
        XSalesResourcesDom: Label 'Sales, Resources - Dom.';
        XSalesResourcesEU: Label 'Sales, Resources - EU';
        XSalesResourcesExport: Label 'Sales, Resources - Export';
        XJobSalesAdjmtResources: Label 'Job Sales Adjmt., Resources';
        XTotalSalesofResources: Label 'Total Sales of Resources';
        XSalesofJobs: Label 'Sales of Jobs';
        XSalesOtherJobExpenses: Label 'Sales, Other Job Expenses';
        XJobSales: Label 'Job Sales';
        XTotalSalesofJobs: Label 'Total Sales of Jobs';
        XConsultingFeesDom: Label 'Consulting Fees - Dom.';
        XFeesandChargesRecDom: Label 'Fees and Charges Rec. - Dom.';
        XFeesandChargesRecEUTxt: Label 'Fees and Charges Rec. - EU';
        XDiscountGranted: Label 'Discount Granted';
        XTotalRevenue: Label 'Total Revenue';
        XCost: Label 'Cost';
        XCostofRetail: Label 'Cost of Retail';
        XPurchRetailDom: Label 'Purch., Retail - Dom.';
        XPurchRetailEU: Label 'Purch., Retail - EU';
        XPurchRetailExport: Label 'Purch., Retail - Export';
        XDiscReceivedRetail: Label 'Disc. Received, Retail';
        XDeliveryExpensesRetail: Label 'Delivery Expenses, Retail';
        XInventoryAdjmtRetail: Label 'Inventory Adjmt., Retail';
        XJobCostAdjmtRetail: Label 'Job Cost Adjmt., Retail';
        XCostofRetailSold: Label 'Cost of Retail Sold';
        XTotalCostofRetail: Label 'Total Cost of Retail';
        XCostofRawMaterials: Label 'Cost of Raw Materials';
        XPurchRawMaterialsDom: Label 'Purch., Raw Materials - Dom.';
        XPurchRawMaterialsEU: Label 'Purch., Raw Materials - EU';
        XPurchRawMaterialsExport: Label 'Purch., Raw Materials - Export';
        XDiscReceivedRawMaterials: Label 'Disc. Received, Raw Materials';
        XDeliveryExpensesRawMat: Label 'Delivery Expenses, Raw Mat.';
        XInventoryAdjmtRawMat: Label 'Inventory Adjmt., Raw Mat.';
        XJobCostAdjmtRawMaterials: Label 'Job Cost Adjmt., Raw Materials';
        XCostofRawMaterialsSold: Label 'Cost of Raw Materials Sold';
        XTotalCostofRawMaterials: Label 'Total Cost of Raw Materials';
        XCostofResources: Label 'Cost of Resources';
        XJobCostAdjmtResources: Label 'Job Cost Adjmt., Resources';
        XCostofResourcesUsed: Label 'Cost of Resources Used';
        XTotalCostofResources: Label 'Total Cost of Resources';
        XJobCosts: Label 'Job Costs';
        XTotalCost: Label 'Total Cost';
        XOperatingExpenses: Label 'Operating Expenses';
        XBuildingMaintenanceExpenses: Label 'Building Maintenance Expenses';
        XCleaning: Label 'Cleaning';
        XElectricityandHeating: Label 'Electricity and Heating';
        XRepairsandMaintenance: Label 'Repairs and Maintenance';
        XTotalBldgMaintExpenses: Label 'Total Bldg. Maint. Expenses';
        XAdministrativeExpenses: Label 'Administrative Expenses';
        XOfficeSupplies: Label 'Office Supplies';
        XPhoneandFax: Label 'Phone and Fax';
        XPostage: Label 'Postage';
        XTotalAdministrativeExpenses: Label 'Total Administrative Expenses';
        XComputerExpenses: Label 'Computer Expenses';
        XSoftware: Label 'Software';
        XConsultantServices: Label 'Consultant Services';
        XOtherComputerExpenses: Label 'Other Computer Expenses';
        XTotalComputerExpenses: Label 'Total Computer Expenses';
        XSellingExpenses: Label 'Selling Expenses';
        XAdvertising: Label 'Advertising';
        XEntertainmentandPR: Label 'Entertainment and PR';
        XTravel: Label 'Travel';
        XDeliveryExpenses: Label 'Delivery Expenses';
        XTotalSellingExpenses: Label 'Total Selling Expenses';
        XVehicleExpenses: Label 'Vehicle Expenses';
        XGasolineandMotorOil: Label 'Gasoline and Motor Oil';
        XRegistrationFees: Label 'Registration Fees';
        XTotalVehicleExpenses: Label 'Total Vehicle Expenses';
        XOtherOperatingExpenses: Label 'Other Operating Expenses';
        XCashDiscrepancies: Label 'Cash Discrepancies';
        XBadDebtExpenses: Label 'Bad Debt Expenses';
        XLegalandAccountingServices: Label 'Legal and Accounting Services';
        XMiscellaneous: Label 'Miscellaneous';
        XOtherOperatingExpTotal: Label 'Other Operating Exp., Total';
        XTotalOperatingExpenses: Label 'Total Operating Expenses';
        XPersonnelExpenses: Label 'Personnel Expenses';
        XWages: Label 'Wages';
        XSalaries: Label 'Salaries';
        XRetirementPlanContributions: Label 'Retirement Plan Contributions';
        XVacationCompensation: Label 'Vacation Compensation';
        XPayrollTaxes: Label 'Payroll Taxes';
        XTotalPersonnelExpenses: Label 'Total Personnel Expenses';
        XDepreciationofFixedAssets: Label 'Depreciation of Fixed Assets';
        XDepreciationBuildings: Label 'Depreciation, Buildings';
        XDepreciationEquipment: Label 'Depreciation, Equipment';
        XDepreciationVehicles: Label 'Depreciation, Vehicles';
        XGainsandLosses: Label 'Gains and Losses';
        XTotalFixedAssetDepreciation: Label 'Total Fixed Asset Depreciation';
        XOtherCostsofOperations: Label 'Other Costs of Operations';
        XNetOperatingIncome: Label 'Net Operating Income';
        XInterestIncome: Label 'Interest Income';
        XInterestonBankBalances: Label 'Interest on Bank Balances';
        XFinanceChargesfromCustomers: Label 'Finance Charges from Customers';
        XPaymentDiscountsReceived: Label 'Payment Discounts Received';
        XPmtDiscReceivedDecreases: Label 'PmtDisc. Received - Decreases';
        XPaymentToleranceReceived: Label 'Payment Tolerance Received';
        XPmtTolReceivedDecreases: Label 'Pmt. Tol. Received Decreases';
        XInvoiceRounding: Label 'Invoice Rounding';
        XApplicationRounding: Label 'Application Rounding';
        XTotalInterestIncome: Label 'Total Interest Income';
        XInterestExpenses: Label 'Interest Expenses';
        XInterestonRevolvingCredit: Label 'Interest on Revolving Credit';
        XInterestonBankLoans: Label 'Interest on Bank Loans';
        XMortgageInterest: Label 'Mortgage Interest';
        XFinanceChargestoVendors: Label 'Finance Charges to Vendors';
        XPaymentDiscountsGranted: Label 'Payment Discounts Granted';
        XPmtDiscGrantedDecreases: Label 'PmtDisc. Granted - Decreases';
        XPaymentToleranceGranted: Label 'Payment Tolerance Granted';
        XPmtTolGrantedDecreases: Label 'Pmt. Tol. Granted Decreases';
        XTotalInterestExpenses: Label 'Total Interest Expenses';
        XUnrealizedFXGains: Label 'Unrealized FX Gains';
        XUnrealizedFXLosses: Label 'Unrealized FX Losses';
        XRealizedFXGains: Label 'Realized FX Gains';
        XRealizedFXLosses: Label 'Realized FX Losses';
        XResidualGains: Label 'Residual Gains';
        XResidualLosses: Label 'Residual Losses';
        XExtraordinaryIncome: Label 'Extraordinary Income';
        XExtraordinaryExpenses: Label 'Extraordinary Expenses';
        XNIBEFOREEXTRAITEMSANDTAXES: Label 'NI BEFORE EXTR. ITEMS & TAXES';
        XNETINCOMEBEFORETAXES: Label 'NET INCOME BEFORE TAXES';
        XCorporateTax: Label 'Corporate Tax';
        XNETINCOME: Label 'NET INCOME';
        XTOTALLIABILITIESANDEQUITY: Label 'TOTAL LIABILITIES AND EQUITY';
        XPurchasePrepayments: Label 'Purchase Prepayments';
        XVendorPrepaymentsVAT: Label 'Vendor Prepayments VAT %1';
        XPurchasePrepaymentsTotal: Label 'Purchase Prepayments, Total';
        XSalesPrepayments: Label 'Sales Prepayments';
        XCustomerPrepaymentsVAT: Label 'Customer Prepayments VAT %1';
        XCustomerPrepaymentsTotal: Label 'Sales Prepayments, Total';
        XJobSalesAppRetail: Label 'Job Sales Applied, Retail';
        XJobSalesAppRawMat: Label 'Job Sales Applied, Raw Mat.';
        XJobSalesAppResources: Label 'Job Sales Applied, Resources';
        XWIPJobSales: Label 'WIP Job Sales';
        XWIPJobCosts: Label 'WIP Job Costs';
        XInvoicedJobSales: Label 'Invoiced Job Sales';
        XAccruedJobCosts: Label 'Accrued Job Costs';
        XWIPSalesTotal: Label 'WIP Sales, Total';
        XWIPCostsTotal: Label 'WIP Costs, Total';
        XJobCostAppRetail: Label 'Job Cost Applied, Retail';
        XJobCostAppRawMaterials: Label 'Job Cost Applied, Raw Mat.';
        XJobCostAppResources: Label 'Job Cost Applied, Resources';

    procedure InsertMiniAppData()
    begin
        AddIncomeStatementForMini();
        AddBalanceSheetForMini();

        GLAccIndent.Indent();
        // AddCategoriesToGLAccounts();
    end;

    local procedure AddIncomeStatementForMini()
    begin
        // Income statement 1000-4999
        DemoDataSetup.Get();
        InsertData('996000', XINCOMESTATEMENT, 1, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996100', XRevenue, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('996105', XSalesofRetail, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996110', XSalesRetailDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('996120', XSalesRetailEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996130', XSalesRetailExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('996405', XSalesofResources, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996195', XTotalSalesofRetail, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996410', XSalesResourcesDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('996420', XSalesResourcesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('996430', XSalesResourcesExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('996495', XTotalSalesofResources, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996710', XConsultingFeesDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('996810', XFeesandChargesRecDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('996820', XFeesandChargesRecEUTxt, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.FreightCode(), '', '', true);
        InsertData('996910', XDiscountGranted, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('996995', XTotalRevenue, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997100', XCost, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('997105', XCostofRetail, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997110', XPurchRetailDom, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('997120', XPurchRetailEU, 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('997130', XPurchRetailExport, 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('997140', XDiscReceivedRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997150', XDeliveryExpensesRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('997170', XInventoryAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997190', XCostofRetailSold, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997195', XTotalCostofRetail, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997995', XTotalCost, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998000', XOperatingExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('998100', XBuildingMaintenanceExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998110', XCleaning, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998120', XElectricityandHeating, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998130', XRepairsandMaintenance, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998190', XTotalBldgMaintExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998200', XAdministrativeExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998210', XOfficeSupplies, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998230', XPhoneandFax, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998240', XPostage, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('998290', XTotalAdministrativeExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998300', XComputerExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998310', XSoftware, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998320', XConsultantServices, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('998330', XOtherComputerExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998390', XTotalComputerExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998400', XSellingExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998410', XAdvertising, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998420', XEntertainmentandPR, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998430', XTravel, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('998450', XDeliveryExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998490', XTotalSellingExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998500', XVehicleExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998510', XGasolineandMotorOil, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998520', XRegistrationFees, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('998530', XRepairsandMaintenance, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998590', XTotalVehicleExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998600', XOtherOperatingExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998610', XCashDiscrepancies, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998620', XBadDebtExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998630', XLegalandAccountingServices, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998640', XMiscellaneous, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998690', XOtherOperatingExpTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998695', XTotalOperatingExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998700', XPersonnelExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998710', XWages, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998720', XSalaries, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998730', XRetirementPlanContributions, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998740', XVacationCompensation, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998750', XPayrollTaxes, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998790', XTotalPersonnelExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998800', XDepreciationofFixedAssets, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998810', XDepreciationBuildings, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998820', XDepreciationEquipment, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998830', XDepreciationVehicles, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998840', XGainsandLosses, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('998890', XTotalFixedAssetDepreciation, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998910', XOtherCostsofOperations, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998995', XNetOperatingIncome, 2, 0, 1,
          Adjust.Convert('996000') + '..' + Adjust.Convert('998995'), 0, '', '', '', '', true);
        InsertData('999100', XInterestIncome, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999110', XInterestonBankBalances, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999120', XFinanceChargesfromCustomers, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('999130', XPaymentDiscountsReceived, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999135', XPmtDiscReceivedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999140', XInvoiceRounding, 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', false);
        InsertData('999150', XApplicationRounding, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999160', XPaymentToleranceReceived, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999170', XPmtTolReceivedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999190', XTotalInterestIncome, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999200', XInterestExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999210', XInterestonRevolvingCredit, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999220', XInterestonBankLoans, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999230', XMortgageInterest, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999240', XFinanceChargestoVendors, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999250', XPaymentDiscountsGranted, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999255', XPmtDiscGrantedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999260', XPaymentToleranceGranted, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999270', XPmtTolGrantedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999290', XTotalInterestExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999310', XUnrealizedFXGains, 0, 0, 1, '', 0, '', '', '', '', false);
        InsertData('999320', XUnrealizedFXLosses, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999330', XRealizedFXGains, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999340', XRealizedFXLosses, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('999395', XNIBEFOREEXTRAITEMSANDTAXES, 2, 0, 1,
          Adjust.Convert('996000') + '..' + Adjust.Convert('999395'), 0, '', '', '', '', true);
        InsertData('999410', XExtraordinaryIncome, 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999420', XExtraordinaryExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999495', XNETINCOMEBEFORETAXES, 2, 0, 0,
          Adjust.Convert('996000') + '..' + Adjust.Convert('999495'), 0, '', '', '', '', true);
        InsertData('999510', XCorporateTax, 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999999', XNETINCOME, 2, 0, 1,
          Adjust.Convert('996000') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
    end;

    procedure AddBalanceSheetForMini()
    begin
        // Balance sheet 5000-9999
        DemoDataSetup.Get();
        InsertData('991000', XBALANCESHEET, 1, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991002', XASSETS, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('991003', XFixedAssets, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('991005', XTangibleFixedAssets, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991100', XLandandBuildings, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991110', XLandandBuildings, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991120', XIncreasesduringtheYear, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('991130', XDecreasesduringtheYear, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('991140', XAccumDepreciationBuildings, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991190', XLandandBuildingsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991200', XOperatingEquipment, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991210', XOperatingEquipment, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991220', XIncreasesduringtheYear, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991230', XDecreasesduringtheYear, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('991240', XAccumDeprOperEquip, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991290', XOperatingEquipmentTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991300', XVehicles, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991310', XVehicles, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991320', XIncreasesduringtheYear, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991330', XDecreasesduringtheYear, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('991340', XAccumDepreciationVehicles, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('991390', XVehiclesTotal, 4, 1, 0,
          Adjust.Convert('991300') + '..' + Adjust.Convert('991390'), 0, '', '', '', '', true);
        InsertData('991395', XTangibleFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991999', XFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992000', XCurrentAssets, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('992100', XInventory, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992110', XResaleItems, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992111', XResaleItemsInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992112', XCostofResaleSoldInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992120', XFinishedGoods, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992121', XFinishedGoodsInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992130', XRawMaterials, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992131', XRawMaterialsInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992132', XCostofRawMatSoldInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992180', XPrimoInventory, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992190', XInventoryTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992200', XJobWIP, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992210', XWIPSales, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992211', XWIPJobSales, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992212', XInvoicedJobSales, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992220', XWIPSalesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992230', XWIPCosts, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992231', XWIPJobCosts, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992232', XAccruedJobCosts, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992240', XWIPCostsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992290', XJobWIPTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992300', XAccountsReceivable, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992310', XCustomersDomestic, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992320', XCustomersForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992330', XAccruedInterest, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992340', XOtherReceivables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992390', XAccountsReceivableTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992400', XPurchasePrepayments, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992410', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.NoVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.NoVATCode(), '', DemoDataSetup.NoVATCode(), false);
        InsertData('992420', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode(), false);
        InsertData('992430', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode(), false);
        InsertData('992440', XPurchasePrepaymentsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992800', XSecurities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992810', XBonds, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992890', XSecuritiesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992900', XLiquidAssets, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992910', XCash, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992920', XBankLCY, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992930', XBankCurrencies, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992940', XGiroAccount, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992990', XLiquidAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992995', XCurrentAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992999', XTOTALASSETS, 4, 1, 1, '', 0, '', '', '', '', true);
        InsertData('993000', XLIABILITIESANDEQUITY, 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData('993100', XStockholdersEquity, 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData('993110', XCapitalStock, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('993120', XRetainedEarnings, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('993195', XNetIncomefortheYear, 2, 1, 0,
          Adjust.Convert('996000') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        InsertData('993199', XTotalStockholdersEquity, 2, 1, 0,
          Adjust.Convert('993100') + '..' + Adjust.Convert('993199') +
          '|' + Adjust.Convert('996000') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        InsertData('994000', XAllowances, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('994010', XDeferredTaxes, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('994999', XAllowancesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995000', XLiabilities, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('995100', XLongtermLiabilities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995110', XLongtermBankLoans, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995120', XMortgage, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995290', XLongtermLiabilitiesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995300', XShorttermLiabilities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995310', XRevolvingCredit, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995350', XSalesPrepayments, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995360', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.NoVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.NoVATCode(), '', DemoDataSetup.NoVATCode(), false);
        InsertData('995370', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', DemoDataSetup.ServicesVATCode(), false);
        InsertData('995380', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', DemoDataSetup.GoodsVATCode(), false);
        InsertData('995390', XCustomerPrepaymentsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995400', XAccountsPayable, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995410', XVendorsDomestic, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995420', XVendorsForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995490', XAccountsPayableTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995500', XInvAdjmtInterim, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995510', XInvAdjmtInterimRetail, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995530', XInvAdjmtInterimRawMat, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995590', XInvAdjmtInterimTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995600', XVAT, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995610', StrSubstNo(XSalesVATPERCENT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995611', StrSubstNo(XSalesVATPERCENT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995620', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995621', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995630', StrSubstNo(XPurchaseVATPERCENT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995631', StrSubstNo(XPurchaseVATPERCENT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995710', XFuelTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995720', XElectricityTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995730', XNaturalGasTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995740', XCoalTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995750', XCO2Tax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995760', XWaterTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995780', XVATPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995790', XVATTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995800', XPersonnelrelatedItems, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995810', XWithholdingTaxesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995820', XSupplementaryTaxesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995830', XPayrollTaxesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995840', XVacationCompensationPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995850', XEmployeesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995890', XTotalPersonnelrelatedItems, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995900', XOtherLiabilities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995910', XDividendsfortheFiscalYear, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995920', XCorporateTaxesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995990', XOtherLiabilitiesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995995', XShorttermLiabilitiesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995997', XTotalLiabilities, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995999', XTOTALLIABILITIESANDEQUITY, 2, 1, 1,
          Adjust.Convert('993000') + '..' + Adjust.Convert('995999') +
          '|' + Adjust.Convert('996000') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
    end;

    procedure InsertData(AccountNo: Code[20]; AccountName: Text[50]; AccountType: Option; IncomeBalance: Option; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectPosting: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", Adjust.Convert(AccountNo));
        GLAccount.Validate(Name, AccountName);
        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then
            GLAccount.Validate("Direct Posting", DirectPosting);
        GLAccount.Validate("Income/Balance", "G/L Account Report Type".FromInteger(IncomeBalance));
        case AccountNo of
            '992910', '992920', '992930', '992940', '995310':
                GLAccount."Reconciliation Account" := true;
            '995999':
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
                UpdateGLAccounts(GLAccountCategory, '991002', '992999');
            GLAccountCategory."Account Category"::Liabilities:
                UpdateGLAccounts(GLAccountCategory, '995000', '995997');
            GLAccountCategory."Account Category"::Equity:
                UpdateGLAccounts(GLAccountCategory, '993100', '994999');
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, '996100', '996995');
                    UpdateGLAccounts(GLAccountCategory, '999100', '999190');
                    UpdateGLAccounts(GLAccountCategory, '999310', '999310');
                    UpdateGLAccounts(GLAccountCategory, '999330', '999330');
                    UpdateGLAccounts(GLAccountCategory, '999410', '999410');
                end;
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                begin
                    UpdateGLAccounts(GLAccountCategory, '997100', '997995');
                    UpdateGLAccounts(GLAccountCategory, '997705', '997795');
                end;
            GLAccountCategory."Account Category"::Expense:
                begin
                    UpdateGLAccounts(GLAccountCategory, '998000', '998910');
                    UpdateGLAccounts(GLAccountCategory, '999320', '999320');
                    UpdateGLAccounts(GLAccountCategory, '999340', '999340');
                end;
        end;
    end;

    procedure AssignSubcategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCash():
                UpdateGLAccounts(GLAccountCategory, '992900', '992990');
            GLAccountCategoryMgt.GetAR():
                begin
                    UpdateGLAccounts(GLAccountCategory, '992300', '992390');
                    UpdateGLAccounts(GLAccountCategory, '995620', '995631');
                end;
            GLAccountCategoryMgt.GetPrepaidExpenses():
                begin
                    UpdateGLAccounts(GLAccountCategory, '992200', '992200');
                    UpdateGLAccounts(GLAccountCategory, '992400', '992440');
                end;
            GLAccountCategoryMgt.GetInventory():
                UpdateGLAccounts(GLAccountCategory, '992100', '992190');
            GLAccountCategoryMgt.GetEquipment():
                UpdateGLAccounts(GLAccountCategory, '991003', '991395');
            GLAccountCategoryMgt.GetAccumDeprec():
                UpdateGLAccounts(GLAccountCategory, '991140', '991140');
            GLAccountCategoryMgt.GetCurrentLiabilities():
                begin
                    UpdateGLAccounts(GLAccountCategory, '995300', '995611');
                    UpdateGLAccounts(GLAccountCategory, '995700', '995995');
                    UpdateGLAccounts(GLAccountCategory, '994010', '994010');
                end;
            GLAccountCategoryMgt.GetPayrollLiabilities():
                UpdateGLAccounts(GLAccountCategory, '995830', '995830');
            GLAccountCategoryMgt.GetLongTermLiabilities():
                UpdateGLAccounts(GLAccountCategory, '995100', '995290');
            GLAccountCategoryMgt.GetCommonStock():
                UpdateGLAccounts(GLAccountCategory, '993110', '993110');
            GLAccountCategoryMgt.GetRetEarnings():
                UpdateGLAccounts(GLAccountCategory, '993120', '993120');
            GLAccountCategoryMgt.GetDistrToShareholders():
                UpdateGLAccounts(GLAccountCategory, '993100', '993100');
            GLAccountCategoryMgt.GetIncomeService():
                UpdateGLAccounts(GLAccountCategory, '996410', '996955');
            GLAccountCategoryMgt.GetIncomeProdSales():
                UpdateGLAccounts(GLAccountCategory, '996105', '996295');
            GLAccountCategoryMgt.GetIncomeSalesDiscounts():
                UpdateGLAccounts(GLAccountCategory, '996910', '996910');
            GLAccountCategoryMgt.GetIncomeSalesReturns():
                ;
            GLAccountCategoryMgt.GetCOGSLabor():
                UpdateGLAccounts(GLAccountCategory, '997480', '997793');
            GLAccountCategoryMgt.GetCOGSMaterials():
                UpdateGLAccounts(GLAccountCategory, '997100', '997295');
            GLAccountCategoryMgt.GetRentExpense():
                ;
            GLAccountCategoryMgt.GetAdvertisingExpense():
                UpdateGLAccounts(GLAccountCategory, '998410', '998420');
            GLAccountCategoryMgt.GetInterestExpense():
                UpdateGLAccounts(GLAccountCategory, '999200', '999290');
            GLAccountCategoryMgt.GetFeesExpense():
                ;
            GLAccountCategoryMgt.GetInsuranceExpense():
                ;
            GLAccountCategoryMgt.GetPayrollExpense():
                UpdateGLAccounts(GLAccountCategory, '998700', '998790');
            GLAccountCategoryMgt.GetBenefitsExpense():
                ;
            GLAccountCategoryMgt.GetRepairsExpense():
                UpdateGLAccounts(GLAccountCategory, '998530', '998530');
            GLAccountCategoryMgt.GetUtilitiesExpense():
                UpdateGLAccounts(GLAccountCategory, '998100', '998240');
            GLAccountCategoryMgt.GetOtherIncomeExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '998600', '998690');
                    UpdateGLAccounts(GLAccountCategory, '999420', '999420');
                end;
            GLAccountCategoryMgt.GetTaxExpense():
                UpdateGLAccounts(GLAccountCategory, '999510', '999510');
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
    var
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        GLAccount.SetRange("No.", MakeAdjustments.Convert(FromGLAccountNo), MakeAdjustments.Convert(ToGLAccountNo));
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

