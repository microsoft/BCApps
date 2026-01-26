codeunit 101015 "Create G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('991002', XASSETS, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('991003', XFixedAssets, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('991100', XLandandBuildings, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991110', XLandandBuildings, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991120', XIncreasesduringtheYear, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991130', XDecreasesduringtheYear, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991140', XAccumDepreciationBuildings, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991190', XLandandBuildingsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991200', XOperatingEquipment, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991210', XOperatingEquipment, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991220', XIncreasesduringtheYear, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991230', XDecreasesduringtheYear, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991240', XAccumDeprOperEquip, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991290', XOperatingEquipmentTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991300', XVehicles, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991310', XVehicles, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991320', XIncreasesduringtheYear, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991330', XDecreasesduringtheYear, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991340', XAccumDepreciationVehicles, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991390', XVehiclesTotal, 4, 1, 0,
          Adjust.Convert('991300') + '..' + Adjust.Convert('991390'), 0, '', '', '', '', true);
        InsertData('991999', XFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992000', XCurrentAssets, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('992100', XInventory, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992110', XResaleItems, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992111', XResaleItemsInterim, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992112', XCostofResaleSoldInterim, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992120', XFinishedGoods, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992121', XFinishedGoodsInterim, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992130', XRawMaterials, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992131', XRawMaterialsInterim, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992132', XCostofRawMatSoldInterim, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992180', XPrimoInventory, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992190', XInventoryTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992200', XJobWIP, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992210', XWIPSales, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992211', XWIPJobSales, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992212', XInvoicedJobSales, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992220', XWIPSalesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992230', XWIPCosts, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992231', XWIPJobCosts, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992232', XAccruedJobCosts, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992240', XWIPCostsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992290', XJobWIPTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992300', XAccountsReceivable, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992310', XCustomersDomestic, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992320', XCustomersForeign, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992330', XAccruedInterest, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992340', XOtherReceivables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992390', XAccountsReceivableTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992400', XPurchasePrepayments, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992410', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.NoVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.NoVATCode(), '', '', false);
        InsertData('992420', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('992430', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', '', false);
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
        InsertData('993110', XCapitalStock, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('993120', XRetainedEarnings, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('993195', XNetIncomefortheYear, 2, 1, 0,
          Adjust.Convert('996100') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        InsertData('993199', XTotalStockholdersEquity, 2, 1, 0,
          Adjust.Convert('8030000') + '..' + Adjust.Convert('993199') +
          '|' + Adjust.Convert('996100') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        InsertData('994010', XDeferredTaxes, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995000', XLiabilities, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('995100', XLongtermLiabilities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995110', XLongtermBankLoans, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995120', XMortgage, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995290', XLongtermLiabilitiesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995300', XShorttermLiabilities, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995310', XRevolvingCredit, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995350', XSalesPrepayments, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995360', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.NoVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.NoVATCode(), '', '', false);
        InsertData('995370', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.ServicesVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('995380', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.GoodsVATText()), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', '', false);
        InsertData('995390', XCustomerPrepaymentsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995400', XAccountsPayable, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995410', XVendorsDomestic, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995420', XVendorsForeign, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995490', XAccountsPayableTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995500', XInvAdjmtInterim, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995510', XInvAdjmtInterimRetail, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995530', XInvAdjmtInterimRawMat, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995590', XInvAdjmtInterimTotal, 4, 1, 0, '', 0, '', '', '', '', true);
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
        InsertData('995650', XTaxes, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('995710', XSalesTaxPayable, 0, 1, 0, '', 0, '', '', '', '', true);
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
        InsertData('996100', XRevenue, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('996105', XSalesofRetail, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996110', XSalesRetailDom, 0, 0, 0, '', 2, '', DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996120', XSalesRetailEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996130', XSalesRetailExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996190', XJobSalesAppRetail, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996191', XJobSalesAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996195', XTotalSalesofRetail, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996205', XSalesofRawMaterials, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996210', XSalesRawMaterialsDom, 0, 0, 0, '', 2, '', DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('996220', XSalesRawMaterialsEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('996230', XSalesRawMaterialsExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('996290', XJobSalesAdjmtRawMat, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996295', XTotalSalesofRawMaterials, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996405', XSalesofResources, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996410', XSalesResourcesDom, 0, 0, 0, '', 2, '', DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('996420', XSalesResourcesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('996430', XSalesResourcesExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('996490', XJobSalesAdjmtResources, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996495', XTotalSalesofResources, 4, 0, 0, '', 0, '', '', '', '', true);

        InsertData('996605', XSalesofJobs, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996610', XSalesOtherJobExpenses, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('996620', XJobSales, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996695', XTotalSalesofJobs, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996710', XConsultingFeesDom, 0, 0, 0, '', 2, '', DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('996810', XFeesandChargesRecDom, 0, 0, 0, '', 2, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('996910', XDiscountGranted, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996995', XTotalRevenue, 4, 0, 0, '', 0, '', '', '', '', true);

        InsertData('997100', XCost, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('997105', XCostofRetail, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997110', XPurchRetailDom, 0, 0, 0, '', 1, '', DemoDataSetup.RetailCode(), '', '', true);
        InsertData('997120', XPurchRetailEU, 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('997130', XPurchRetailExport, 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('997140', XDiscReceivedRetail, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997150', XDeliveryExpensesRetail, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('997170', XInventoryAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997180', XJobCostAppRetail, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997181', XJobCostAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997190', XCostofRetailSold, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997195', XTotalCostofRetail, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997205', XCostofRawMaterials, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997210', XPurchRawMaterialsDom, 0, 0, 0, '', 1, '', DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('997220', XPurchRawMaterialsEU, 0, 0, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('997230', XPurchRawMaterialsExport, 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('997240', XDiscReceivedRawMaterials, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997250', XDeliveryExpensesRawMat, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('997270', XInventoryAdjmtRawMat, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997280', XJobCostAdjmtRawMaterials, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997290', XCostofRawMaterialsSold, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997295', XTotalCostofRawMaterials, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997405', XCostofResources, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997480', XJobCostAppResources, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997481', XJobCostAdjmtResources, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997490', XCostofResourcesUsed, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997495', XTotalCostofResources, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997620', XJobCosts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997995', XTotalCost, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998000', XOperatingExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('998100', XBuildingMaintenanceExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998110', XCleaning, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998120', XElectricityandHeating, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998130', XRepairsandMaintenance, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998190', XTotalBldgMaintExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998200', XAdministrativeExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998210', XOfficeSupplies, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998230', XPhoneandFax, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998240', XPostage, 0, 0, 0, '', 1, '', DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('998290', XTotalAdministrativeExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998300', XComputerExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998310', XSoftware, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998320', XConsultantServices, 0, 0, 0, '', 1, '', DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('998330', XOtherComputerExpenses, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998390', XTotalComputerExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998400', XSellingExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998410', XAdvertising, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998420', XEntertainmentandPR, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998430', XTravel, 0, 0, 0, '', 1, '', DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('998450', XDeliveryExpenses, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998490', XTotalSellingExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998500', XVehicleExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998510', XGasolineandMotorOil, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998520', XRegistrationFees, 0, 0, 0, '', 1, '', DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('998530', XRepairsandMaintenance, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998590', XTotalVehicleExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998600', XOtherOperatingExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998610', XCashDiscrepancies, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998620', XBadDebtExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998630', XLegalandAccountingServices, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998640', XMiscellaneous, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
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
        InsertData('998840', XGainsandLosses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998890', XTotalFixedAssetDepreciation, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998910', XOtherCostsofOperations, 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998995', XNetOperatingIncome, 2, 0, 1,
          Adjust.Convert('996100') + '..' + Adjust.Convert('998995'), 0, '', '', '', '', true);
        InsertData('999100', XInterestIncome, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999110', XInterestonBankBalances, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999120', XFinanceChargesfromCustomers, 0, 0, 0, '', 2, '', DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('999130', XPaymentDiscountsReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999135', XPmtDiscReceivedDecreases, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999160', XPaymentToleranceReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999170', XPmtTolReceivedDecreases, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999140', XInvoiceRounding, 0, 0, 0, '', 0, '', DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('999150', XApplicationRounding, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999190', XTotalInterestIncome, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999200', XInterestExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999210', XInterestonRevolvingCredit, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999220', XInterestonBankLoans, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999230', XMortgageInterest, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999240', XFinanceChargestoVendors, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999250', XPaymentDiscountsGranted, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999255', XPmtDiscGrantedDecreases, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999260', XPaymentToleranceGranted, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999270', XPmtTolGrantedDecreases, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999290', XTotalInterestExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999310', XUnrealizedFXGains, 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999320', XUnrealizedFXLosses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999330', XRealizedFXGains, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999340', XRealizedFXLosses, 0, 0, 0, '', 0, '', '', '', '', true);
        if DemoDataSetup."Additional Currency Code" <> '' then begin
            InsertData('999350', XResidualGains, 0, 0, 0, '', 0, '', '', '', '', true);
            InsertData('999360', XResidualLosses, 0, 0, 0, '', 0, '', '', '', '', false);
        end;
        InsertData('999395', XNIBEFOREEXTRAITEMSANDTAXES, 2, 0, 1,
          Adjust.Convert('996100') + '..' + Adjust.Convert('999395'), 0, '', '', '', '', true);
        InsertData('999410', XExtraordinaryIncome, 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999420', XExtraordinaryExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999495', XNETINCOMEBEFORETAXES, 2, 0, 0,
          Adjust.Convert('996100') + '..' + Adjust.Convert('999495'), 0, '', '', '', '', true);
        InsertData('999510', XCorporateTax, 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999999', XNETINCOME, 2, 0, 1,
          Adjust.Convert('996100') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        // US accounts added
        InsertData('8012200', XOtherMarketableSecurities, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8022600', XTaxesPayables, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8022790', XTaxesPayablesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8023050', XAccruedSalariesWages, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8023400', XFICAPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8023500', XMedicarePayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8023600', XFUTAPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8023700', XSUTAPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8023750', XEmployeeBenefitsPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8023775', XGarnishmentPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('8030000', XEQUITY, 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData('8059999', XGROSSPROFIT, 2, 1, 1,
          Adjust.Convert('996100') + '..' + Adjust.Convert('8059999'), 0, '', '', '', '', true);
        InsertData('8062600', XHealthInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8062700', XGroupLifeInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8062800', XWorkersCompensation, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8062900', X401KContributions, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8080700', XGAINSANDLOSSES2, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('8081300', XTOTALGAINSANDLOSSES, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8084000', XIncomeTaxes, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8084200', XStateIncomeTax, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8084300', XTotalIncomeTaxes, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8084500', XNETINCOMEBEFOREEXTRITEMS, 2, 0, 1,
          Adjust.Convert('996100') + '..' + Adjust.Convert('8084500'), 0, '', '', '', '', true);
        InsertData('8085000', XExtraordinaryItems, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('8085300', XExtraordinaryItemsTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        GLAccIndent.Indent();
        AddCategoriesToGLAccounts();
    end;

    var
        XSalesTaxPayable: Label 'Sales Tax Payable';
        XTaxes: Label 'Taxes';
        XOtherMarketableSecurities: Label 'Other Marketable Securities';
        XTaxesPayables: Label 'Taxes Payables';
        XTaxesPayablesTotal: Label 'Taxes Payables, Total';
        XAccruedSalariesWages: Label 'Accrued Salaries & Wages';
        XFICAPayable: Label 'FICA Payable';
        XMedicarePayable: Label 'Medicare Payable';
        XFUTAPayable: Label 'FUTA Payable';
        XSUTAPayable: Label 'SUTA Payable';
        XEmployeeBenefitsPayable: Label 'Employee Benefits Payable';
        XGarnishmentPayable: Label 'Garnishment Payable';
        XEQUITY: Label 'EQUITY';
        XGROSSPROFIT: Label 'GROSS PROFIT';
        XHealthInsurance: Label 'Health Insurance';
        XGroupLifeInsurance: Label 'Group Life Insurance';
        XWorkersCompensation: Label 'Workers Compensation';
        X401KContributions: Label '401K Contributions';
        XGAINSANDLOSSES2: Label 'GAINS AND LOSSES';
        XTOTALGAINSANDLOSSES: Label 'TOTAL GAINS AND LOSSES';
        XIncomeTaxes: Label 'Income Taxes';
        XStateIncomeTax: Label 'State Income Tax';
        XTotalIncomeTaxes: Label 'Total Income Taxes';
        XNETINCOMEBEFOREEXTRITEMS: Label 'NET INCOME BEFORE EXTR. ITEMS';
        XExtraordinaryItems: Label 'Extraordinary Items';
        XExtraordinaryItemsTotal: Label 'Extraordinary Items, Total';
        XNONTAXABLE: Label 'NONTAXABLE';
        DemoDataSetup: Record "Demo Data Setup";
        Adjust: Codeunit "Make Adjustments";
        GLAccIndent: Codeunit "G/L Account-Indent";
        XASSETS: Label 'ASSETS';
        XFixedAssets: Label 'Fixed Assets';
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
        XBankLCY: Label 'Bank, Checking';
        XBankCurrencies: Label 'Bank Currencies';
        XGiroAccount: Label 'Bank Operations Cash';
        XLiquidAssetsTotal: Label 'Liquid Assets, Total';
        XCurrentAssetsTotal: Label 'Current Assets, Total';
        XTOTALASSETS: Label 'TOTAL ASSETS';
        XLIABILITIESANDEQUITY: Label 'LIABILITIES AND EQUITY';
        XCapitalStock: Label 'Capital Stock';
        XRetainedEarnings: Label 'Retained Earnings';
        XNetIncomefortheYear: Label 'Net Income for the Year';
        XTotalStockholdersEquity: Label 'Total Stockholder''s Equity';
        XDeferredTaxes: Label 'Deferred Taxes';
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
        XPersonnelrelatedItems: Label 'Personnel-related Items';
        XWithholdingTaxesPayable: Label 'Federal Withholding Payable';
        XSupplementaryTaxesPayable: Label 'State Withholding Payable';
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
        XWIPJobSales: Label 'WIP Job Sales';
        XWIPJobCosts: Label 'WIP Job Costs';
        XInvoicedJobSales: Label 'Invoiced Job Sales';
        XAccruedJobCosts: Label 'Accrued Job Costs';
        XWIPSalesTotal: Label 'WIP Sales, Total';
        XWIPCostsTotal: Label 'WIP Costs, Total';
        XJobCostAppRetail: Label 'Job Cost Applied, Retail';
        XJobCostAppResources: Label 'Job Cost Applied, Resources';
        BalanceSheetTok: Label 'Balance Sheet', MaxLength = 100;
        AssetsTok: Label 'Assets', MaxLength = 100;
        IntangibleFixedAssetsTok: Label 'Intangible Fixed Assets', MaxLength = 100;
        DevelopmentExpenditureTok: Label 'Development Expenditure', MaxLength = 100;
        TenancySiteLeaseholdandsimilarrightsTok: Label 'Tenancy, Site Leasehold and similar rights', MaxLength = 100;
        GoodwillTok: Label 'Goodwill', MaxLength = 100;
        AdvancedPaymentsforIntangibleFixedAssetsTok: Label 'Advanced Payments for Intangible Fixed Assets', MaxLength = 100;
        TotalIntangibleFixedAssetsTok: Label 'Total, Intangible Fixed Assets', MaxLength = 100;
        TangibleFixedAssetsTok: Label 'Tangible Fixed Assets', MaxLength = 100;
        LandandBuildingsTok: Label 'Land and Buildings', MaxLength = 100;
        BuildingTok: Label 'Building', MaxLength = 100;
        CostofImprovementstoLeasedPropertyTok: Label 'Cost of Improvements to Leased Property', MaxLength = 100;
        LandTok: Label 'Land ', MaxLength = 100;
        TotalLandandbuildingTok: Label 'Total, Land and building ', MaxLength = 100;
        MachineryandEquipmentTok: Label 'Machinery and Equipment', MaxLength = 100;
        EquipmentsandToolsTok: Label 'Equipments and Tools', MaxLength = 100;
        ComputersTok: Label 'Computers', MaxLength = 100;
        CarsandotherTransportEquipmentsTok: Label 'Cars and other Transport Equipments', MaxLength = 100;
        LeasedAssetsTok: Label 'Leased Assets', MaxLength = 100;
        TotalMachineryandEquipmentTok: Label 'Total, Machinery and Equipment', MaxLength = 100;
        AccumulatedDepreciationTok: Label 'Accumulated Depreciation', MaxLength = 100;
        TotalTangibleAssetsTok: Label 'Total, Tangible Assets', MaxLength = 100;
        FinancialandFixedAssetsTok: Label 'Financial and Fixed Assets', MaxLength = 100;
        Long_termReceivablesTok: Label 'Long-term Receivables ', MaxLength = 100;
        ParticipationinGroupCompaniesTok: Label 'Participation in Group Companies', MaxLength = 100;
        LoanstoPartnersorrelatedPartiesTok: Label 'Loans to Partners or related Parties', MaxLength = 100;
        DeferredTaxAssetsTok: Label 'Deferred Tax Assets', MaxLength = 100;
        OtherLong_termReceivablesTok: Label 'Other Long-term Receivables', MaxLength = 100;
        TotalFinancialandFixedAssetsTok: Label 'Total, Financial and Fixed Assets', MaxLength = 100;
        InventoriesProductsandworkinProgressTok: Label 'Inventories, Products and work in Progress', MaxLength = 100;
        RawMaterialsTok: Label 'Raw Materials', MaxLength = 100;
        SuppliesandConsumablesTok: Label 'Supplies and Consumables', MaxLength = 100;
        ProductsinProgressTok: Label 'Products in Progress', MaxLength = 100;
        FinishedGoodsTok: Label 'Finished Goods', MaxLength = 100;
        GoodsforResaleTok: Label 'Goods for Resale', MaxLength = 100;
        AdvancedPaymentsforgoodsandservicesTok: Label 'Advanced Payments for goods and services', MaxLength = 100;
        OtherInventoryItemsTok: Label 'Other Inventory Items', MaxLength = 100;
        WorkinProgressTok: Label 'Work in Progress', MaxLength = 100;
        WorkinProgressFinishedGoodsTok: Label 'Work in Progress, Finished Goods', MaxLength = 100;
        WIPJobSalesTok: Label 'WIP Job Sales', MaxLength = 100;
        WIPJobCostsTok: Label 'WIP Job Costs', MaxLength = 100;
        WIPAccruedCostsTok: Label 'WIP, Accrued Costs', MaxLength = 100;
        WIPInvoicedSalesTok: Label 'WIP, Invoiced Sales', MaxLength = 100;
        TotalWorkinProgressTok: Label 'Total, Work in Progress', MaxLength = 100;
        ReceivablesTok: Label 'Receivables', MaxLength = 100;
        AccountsReceivablesTok: Label 'Accounts Receivables', MaxLength = 100;
        AccountReceivableDomesticTok: Label 'Account Receivable, Domestic', MaxLength = 100;
        AccountReceivableForeignTok: Label 'Account Receivable, Foreign', MaxLength = 100;
        ContractualReceivablesTok: Label 'Contractual Receivables', MaxLength = 100;
        ConsignmentReceivablesTok: Label 'Consignment Receivables', MaxLength = 100;
        CreditcardsandVouchersReceivablesTok: Label 'Credit cards and Vouchers Receivables', MaxLength = 100;
        TotalAccountReceivablesTok: Label 'Total, Account Receivables', MaxLength = 100;
        OtherCurrentReceivablesTok: Label 'Other Current Receivables', MaxLength = 100;
        CurrentReceivablefromEmployeesTok: Label 'Current Receivable from Employees', MaxLength = 100;
        AccruedincomenotyetinvoicedTok: Label 'Accrued income not yet invoiced', MaxLength = 100;
        ClearingAccountsforTaxesandchargesTok: Label 'Clearing Accounts for Taxes and charges', MaxLength = 100;
        TaxAssetsTok: Label 'Tax Assets', MaxLength = 100;
        CurrentReceivablesfromgroupcompaniesTok: Label 'Current Receivables from group companies', MaxLength = 100;
        TotalOtherCurrentReceivablesTok: Label 'Total, Other Current Receivables', MaxLength = 100;
        TotalReceivablesTok: Label 'Total, Receivables', MaxLength = 100;
        PrepaidexpensesandAccruedIncomeTok: Label 'Prepaid expenses and Accrued Income', MaxLength = 100;
        PrepaidRentTok: Label 'Prepaid Rent', MaxLength = 100;
        PrepaidInterestexpenseTok: Label 'Prepaid Interest expense', MaxLength = 100;
        AccruedRentalIncomeTok: Label 'Accrued Rental Income', MaxLength = 100;
        AccruedInterestIncomeTok: Label 'Accrued Interest Income', MaxLength = 100;
        AssetsintheformofprepaidexpensesTok: Label 'Assets in the form of prepaid expenses', MaxLength = 100;
        OtherprepaidexpensesandaccruedincomeTok: Label 'Other prepaid expenses and accrued income', MaxLength = 100;
        TotalPrepaidexpensesandAccruedIncomeTok: Label 'Total, Prepaid expenses and Accrued Income', MaxLength = 100;
        Short_terminvestmentsTok: Label 'Short-term investments', MaxLength = 100;
        BondsTok: Label 'Bonds', MaxLength = 100;
        ConvertibledebtinstrumentsTok: Label 'Convertible debt instruments', MaxLength = 100;
        Othershort_termInvestmentsTok: Label 'Other short-term Investments', MaxLength = 100;
        Write_downofShort_terminvestmentsTok: Label 'Write-down of Short-term investments', MaxLength = 100;
        TotalshortterminvestmentsTok: Label 'Total, short term investments', MaxLength = 100;
        CashandBankTok: Label 'Cash and Bank', MaxLength = 100;
        PettyCashTok: Label 'Petty Cash', MaxLength = 100;
        BusinessaccountOperatingDomesticTok: Label 'Business account, Operating, Domestic', MaxLength = 100;
        BusinessaccountOperatingForeignTok: Label 'Business account, Operating, Foreign', MaxLength = 100;
        OtherbankaccountsTok: Label 'Other bank accounts ', MaxLength = 100;
        CertificateofDepositTok: Label 'Certificate of Deposit', MaxLength = 100;
        TotalCashandBankTok: Label 'Total, Cash and Bank', MaxLength = 100;
        TotalAssetsTok: Label 'Total Assets', MaxLength = 100;
        LiabilityTok: Label 'Liability', MaxLength = 100;
        Long_TermLiabilitiesTok: Label 'Long-Term Liabilities', MaxLength = 100;
        BondsandDebentureLoansTok: Label 'Bonds and Debenture Loans', MaxLength = 100;
        ConvertiblesLoansTok: Label 'Convertibles Loans', MaxLength = 100;
        OtherLong_termLiabilitiesTok: Label 'Other Long-term Liabilities', MaxLength = 100;
        BankoverdraftFacilitiesTok: Label 'Bank overdraft Facilities', MaxLength = 100;
        TotalLong_termLiabilitiesTok: Label 'Total, Long-term Liabilities', MaxLength = 100;
        CurrentLiabilitiesTok: Label 'Current Liabilities', MaxLength = 100;
        AccountsPayableDomesticTok: Label 'Accounts Payable, Domestic', MaxLength = 100;
        AccountsPayableForeignTok: Label 'Accounts Payable, Foreign', MaxLength = 100;
        AdvancesfromcustomersTok: Label 'Advances from customers', MaxLength = 100;
        ChangeinWorkinProgressTok: Label 'Change in Work in Progress', MaxLength = 100;
        Bankoverdraftshort_termTok: Label 'Bank overdraft short-term', MaxLength = 100;
        OtherLiabilitiesTok: Label 'Other Liabilities', MaxLength = 100;
        TotalCurrentLiabilitiesTok: Label 'Total, Current Liabilities', MaxLength = 100;
        TaxLiabilitiesTok: Label 'Tax Liabilities', MaxLength = 100;
        SalesTaxLiableTok: Label 'Sales Tax Liable', MaxLength = 100;
        TaxesLiableTok: Label 'Taxes Liable', MaxLength = 100;
        EstimatedIncomeTaxTok: Label 'Estimated Income Tax', MaxLength = 100;
        EstimatedPayrolltaxonPensionCostsTok: Label 'Estimated Payroll tax on Pension Costs', MaxLength = 100;
        TotalTaxLiabilitiesTok: Label 'Total, Tax Liabilities', MaxLength = 100;
        PayrollLiabilitiesTok: Label 'Payroll Liabilities', MaxLength = 100;
        EmployeesWithholdingTaxesTok: Label 'Employees Withholding Taxes', MaxLength = 100;
        StatutorySocialsecurityContributionsTok: Label 'Statutory Social security Contributions', MaxLength = 100;
        ContractualSocialsecurityContributionsTok: Label 'Contractual Social security Contributions', MaxLength = 100;
        AttachmentsofEarningTok: Label 'Attachments of Earning', MaxLength = 100;
        HolidayPayfundTok: Label 'Holiday Pay fund', MaxLength = 100;
        OtherSalary_wageDeductionsTok: Label 'Other Salary/wage Deductions', MaxLength = 100;
        TotalPayrollLiabilitiesTok: Label 'Total, Payroll Liabilities', MaxLength = 100;
        OtherCurrentLiabilitiesTok: Label 'Other Current Liabilities', MaxLength = 100;
        ClearingAccountforFactoringCurrentPortionTok: Label 'Clearing Account for Factoring, Current Portion', MaxLength = 100;
        CurrentLiabilitiestoEmployeesTok: Label 'Current Liabilities to Employees', MaxLength = 100;
        ClearingAccountforthirdpartyTok: Label 'Clearing Account for third party', MaxLength = 100;
        CurrentLoansTok: Label 'Current Loans', MaxLength = 100;
        LiabilitiesGrantsReceivedTok: Label 'Liabilities, Grants Received ', MaxLength = 100;
        TotalOtherCurrentLiabilitiesTok: Label 'Total, Other Current Liabilities', MaxLength = 100;
        AccruedExpensesandDeferredIncomeTok: Label 'Accrued Expenses and Deferred Income', MaxLength = 100;
        Accruedwages_salariesTok: Label 'Accrued wages/salaries', MaxLength = 100;
        AccruedHolidaypayTok: Label 'Accrued Holiday pay', MaxLength = 100;
        AccruedPensioncostsTok: Label 'Accrued Pension costs', MaxLength = 100;
        AccruedInterestExpenseTok: Label 'Accrued Interest Expense', MaxLength = 100;
        DeferredIncomeTok: Label 'Deferred Income', MaxLength = 100;
        AccruedContractualcostsTok: Label 'Accrued Contractual costs', MaxLength = 100;
        OtherAccruedExpensesandDeferredIncomeTok: Label 'Other Accrued Expenses and Deferred Income', MaxLength = 100;
        TotalAccruedExpensesandDeferredIncomeTok: Label 'Total, Accrued Expenses and Deferred Income', MaxLength = 100;
        TotalLiabilitiesTok: Label 'Total Liabilities', MaxLength = 100;
        EquityTok: Label 'Equity', MaxLength = 100;
        EquityPartnerTok: Label 'Equity Partner ', MaxLength = 100;
        NetResultsTok: Label 'Net Results ', MaxLength = 100;
        RestrictedEquityTok: Label 'Restricted Equity ', MaxLength = 100;
        ShareCapitalTok: Label 'Share Capital ', MaxLength = 100;
        Non_RestrictedEquityTok: Label 'Non-Restricted Equity', MaxLength = 100;
        ProfitorlossfromthepreviousyearTok: Label 'Profit or loss from the previous year', MaxLength = 100;
        ResultsfortheFinancialyearTok: Label 'Results for the Financial year', MaxLength = 100;
        DistributionstoShareholdersTok: Label 'Distributions to Shareholders', MaxLength = 100;
        TotalEquityTok: Label ' Total, Equity', MaxLength = 100;
        INCOMESTATEMENTTok: Label 'INCOME STATEMENT', MaxLength = 100;
        IncomeTok: Label 'Income', MaxLength = 100;
        SalesofGoodsTok: Label 'Sales of Goods', MaxLength = 100;
        SaleofFinishedGoodsTok: Label 'Sale of Finished Goods', MaxLength = 100;
        SaleofRawMaterialsTok: Label 'Sale of Raw Materials', MaxLength = 100;
        ResaleofGoodsTok: Label 'Resale of Goods', MaxLength = 100;
        TotalSalesofGoodsTok: Label 'Total, Sales of Goods', MaxLength = 100;
        SalesofResourcesTok: Label 'Sales of Resources', MaxLength = 100;
        SaleofResourcesTok: Label 'Sale of Resources', MaxLength = 100;
        SaleofSubcontractingTok: Label 'Sale of Subcontracting', MaxLength = 100;
        TotalSalesofResourcesTok: Label 'Total, Sales of Resources', MaxLength = 100;
        AdditionalRevenueTok: Label 'Additional Revenue', MaxLength = 100;
        IncomefromsecuritiesTok: Label 'Income from securities', MaxLength = 100;
        ManagementFeeRevenueTok: Label 'Management Fee Revenue', MaxLength = 100;
        InterestIncomeTok: Label 'Interest Income', MaxLength = 100;
        CurrencyGainsTok: Label 'Currency Gains', MaxLength = 100;
        OtherIncidentalRevenueTok: Label 'Other Incidental Revenue', MaxLength = 100;
        TotalAdditionalRevenueTok: Label 'Total, Additional Revenue', MaxLength = 100;
        JobsandServicesTok: Label 'Jobs and Services', MaxLength = 100;
        JobSalesTok: Label 'Job Sales', MaxLength = 100;
        JobSalesAppliedTok: Label 'Job Sales Applied', MaxLength = 100;
        SalesofServiceContractsTok: Label 'Sales of Service Contracts', MaxLength = 100;
        SalesofServiceWorkTok: Label 'Sales of Service Work', MaxLength = 100;
        TotalJobsandServicesTok: Label 'Total, Jobs and Services', MaxLength = 100;
        RevenueReductionsTok: Label 'Revenue Reductions', MaxLength = 100;
        DiscountsandAllowancesTok: Label 'Discounts and Allowances', MaxLength = 100;
        InvoiceRoundingTok: Label 'Invoice Rounding', MaxLength = 100;
        PaymentToleranceTok: Label 'Payment Tolerance', MaxLength = 100;
        SalesReturnsTok: Label 'Sales Returns', MaxLength = 100;
        TotalRevenueReductionsTok: Label 'Total, Revenue Reductions', MaxLength = 100;
        TOTALINCOMETok: Label 'TOTAL INCOME', MaxLength = 100;
        COSTOFGOODSSOLDTok: Label 'COST OF GOODS SOLD', MaxLength = 100;
        CostofGoodsTok: Label 'Cost of Goods', MaxLength = 100;
        CostofMaterialsTok: Label 'Cost of Materials', MaxLength = 100;
        CostofMaterialsProjectsTok: Label 'Cost of Materials, Projects', MaxLength = 100;
        TotalCostofGoodsTok: Label 'Total, Cost of Goods', MaxLength = 100;
        CostofResourcesandServicesTok: Label 'Cost of Resources and Services', MaxLength = 100;
        CostofLaborTok: Label 'Cost of Labor', MaxLength = 100;
        CostofLaborProjectsTok: Label 'Cost of Labor, Projects', MaxLength = 100;
        CostofLaborWarranty_ContractTok: Label 'Cost of Labor, Warranty/Contract', MaxLength = 100;
        TotalCostofResourcesTok: Label 'Total, Cost of Resources', MaxLength = 100;
        SubcontractedworkTok: Label 'Subcontracted work', MaxLength = 100;
        CostofVariancesTok: Label 'Cost of Variances', MaxLength = 100;
        TOTALCOSTOFGOODSSOLDTok: Label 'TOTAL COST OF GOODS SOLD', MaxLength = 100;
        EXPENSESTok: Label 'EXPENSES', MaxLength = 100;
        FacilityExpensesTok: Label 'Facility Expenses', MaxLength = 100;
        RentalFacilitiesTok: Label 'Rental Facilities', MaxLength = 100;
        Rent_LeasesTok: Label 'Rent / Leases', MaxLength = 100;
        ElectricityforRentalTok: Label 'Electricity for Rental', MaxLength = 100;
        HeatingforRentalTok: Label 'Heating for Rental', MaxLength = 100;
        WaterandSewerageforRentalTok: Label 'Water and Sewerage for Rental', MaxLength = 100;
        CleaningandWasteforRentalTok: Label 'Cleaning and Waste for Rental', MaxLength = 100;
        RepairsandMaintenanceforRentalTok: Label 'Repairs and Maintenance for Rental', MaxLength = 100;
        InsurancesRentalTok: Label 'Insurances, Rental', MaxLength = 100;
        OtherRentalExpensesTok: Label 'Other Rental Expenses', MaxLength = 100;
        TotalRentalFacilitiesTok: Label 'Total, Rental Facilities', MaxLength = 100;
        PropertyExpensesTok: Label 'Property Expenses', MaxLength = 100;
        SiteFees_LeasesTok: Label 'Site Fees / Leases', MaxLength = 100;
        ElectricityforPropertyTok: Label 'Electricity for Property', MaxLength = 100;
        HeatingforPropertyTok: Label 'Heating for Property', MaxLength = 100;
        WaterandSewerageforPropertyTok: Label 'Water and Sewerage for Property', MaxLength = 100;
        CleaningandWasteforPropertyTok: Label 'Cleaning and Waste for Property', MaxLength = 100;
        RepairsandMaintenanceforPropertyTok: Label 'Repairs and Maintenance for Property', MaxLength = 100;
        InsurancesPropertyTok: Label 'Insurances, Property', MaxLength = 100;
        OtherPropertyExpensesTok: Label 'Other Property Expenses', MaxLength = 100;
        TotalPropertyExpensesTok: Label 'Total, Property Expenses', MaxLength = 100;
        TotalFacilityExpensesTok: Label 'Total, Facility Expenses', MaxLength = 100;
        FixedAssetsLeasesTok: Label 'Fixed Assets Leases', MaxLength = 100;
        HireofmachineryTok: Label 'Hire of machinery', MaxLength = 100;
        HireofcomputersTok: Label 'Hire of computers', MaxLength = 100;
        HireofotherfixedassetsTok: Label 'Hire of other fixed assets', MaxLength = 100;
        TotalFixedAssetLeasesTok: Label 'Total, Fixed Asset Leases', MaxLength = 100;
        LogisticsExpensesTok: Label 'Logistics Expenses', MaxLength = 100;
        VehicleExpensesTok: Label 'Vehicle Expenses', MaxLength = 100;
        PassengerCarCostsTok: Label 'Passenger Car Costs', MaxLength = 100;
        TruckCostsTok: Label 'Truck Costs', MaxLength = 100;
        OthervehicleexpensesTok: Label 'Other vehicle expenses', MaxLength = 100;
        TotalVehicleExpensesTok: Label 'Total, Vehicle Expenses', MaxLength = 100;
        FreightCostsTok: Label 'Freight Costs', MaxLength = 100;
        FreightfeesforgoodsTok: Label 'Freight fees for goods', MaxLength = 100;
        CustomsandforwardingTok: Label 'Customs and forwarding', MaxLength = 100;
        FreightfeesprojectsTok: Label 'Freight fees, projects', MaxLength = 100;
        TotalFreightCostsTok: Label 'Total, Freight Costs', MaxLength = 100;
        TravelExpensesTok: Label 'Travel Expenses', MaxLength = 100;
        TicketsTok: Label 'Tickets', MaxLength = 100;
        RentalvehiclesTok: Label 'Rental vehicles', MaxLength = 100;
        BoardandlodgingTok: Label 'Board and lodging', MaxLength = 100;
        OthertravelexpensesTok: Label 'Other travel expenses', MaxLength = 100;
        TotalTravelExpensesTok: Label 'Total, Travel Expenses', MaxLength = 100;
        TotalLogisticsExpensesTok: Label 'Total, Logistics Expenses', MaxLength = 100;
        MarketingandSalesTok: Label 'Marketing and Sales', MaxLength = 100;
        AdvertisingTok: Label 'Advertising', MaxLength = 100;
        AdvertisementDevelopmentTok: Label 'Advertisement Development', MaxLength = 100;
        OutdoorandTransportationAdsTok: Label 'Outdoor and Transportation Ads', MaxLength = 100;
        AdmatteranddirectmailingsTok: Label 'Ad matter and direct mailings', MaxLength = 100;
        Conference_ExhibitionSponsorshipTok: Label 'Conference/Exhibition Sponsorship', MaxLength = 100;
        SamplescontestsgiftsTok: Label 'Samples, contests, gifts', MaxLength = 100;
        FilmTVradiointernetadsTok: Label 'Film, TV, radio, internet ads', MaxLength = 100;
        PRandAgencyFeesTok: Label 'PR and Agency Fees', MaxLength = 100;
        OtheradvertisingfeesTok: Label 'Other advertising fees', MaxLength = 100;
        TotalAdvertisingTok: Label 'Total, Advertising', MaxLength = 100;
        OtherMarketingExpensesTok: Label 'Other Marketing Expenses', MaxLength = 100;
        CatalogspricelistsTok: Label 'Catalogs, price lists', MaxLength = 100;
        TradePublicationsTok: Label 'Trade Publications', MaxLength = 100;
        TotalOtherMarketingExpensesTok: Label 'Total, Other Marketing Expenses', MaxLength = 100;
        SalesExpensesTok: Label 'Sales Expenses', MaxLength = 100;
        CreditCardChargesTok: Label 'Credit Card Charges', MaxLength = 100;
        BusinessEntertainingdeductibleTok: Label 'Business Entertaining, deductible', MaxLength = 100;
        BusinessEntertainingnondeductibleTok: Label 'Business Entertaining, nondeductible', MaxLength = 100;
        TotalSalesExpensesTok: Label 'Total, Sales Expenses', MaxLength = 100;
        TotalMarketingandSalesTok: Label 'Total, Marketing and Sales', MaxLength = 100;
        OfficeExpensesTok: Label 'Office Expenses', MaxLength = 100;
        OfficeSuppliesTok: Label 'Office Supplies', MaxLength = 100;
        PhoneServicesTok: Label 'Phone Services', MaxLength = 100;
        DataservicesTok: Label 'Data services', MaxLength = 100;
        PostalfeesTok: Label 'Postal fees', MaxLength = 100;
        Consumable_ExpensiblehardwareTok: Label 'Consumable/Expensible hardware', MaxLength = 100;
        SoftwareandsubscriptionfeesTok: Label 'Software and subscription fees', MaxLength = 100;
        TotalOfficeExpensesTok: Label 'Total, Office Expenses', MaxLength = 100;
        InsurancesandRisksTok: Label 'Insurances and Risks', MaxLength = 100;
        CorporateInsuranceTok: Label 'Corporate Insurance', MaxLength = 100;
        DamagesPaidTok: Label 'Damages Paid', MaxLength = 100;
        BadDebtLossesTok: Label 'Bad Debt Losses', MaxLength = 100;
        SecurityservicesTok: Label 'Security services', MaxLength = 100;
        OtherriskexpensesTok: Label 'Other risk expenses', MaxLength = 100;
        TotalInsurancesandRisksTok: Label 'Total, Insurances and Risks', MaxLength = 100;
        ManagementandAdminTok: Label 'Management and Admin', MaxLength = 100;
        ManagementTok: Label 'Management', MaxLength = 100;
        RemunerationtoDirectorsTok: Label 'Remuneration to Directors', MaxLength = 100;
        ManagementFeesTok: Label 'Management Fees', MaxLength = 100;
        Annual_interrimReportsTok: Label 'Annual/interrim Reports', MaxLength = 100;
        Annual_generalmeetingTok: Label 'Annual/general meeting', MaxLength = 100;
        AuditandAuditServicesTok: Label 'Audit and Audit Services', MaxLength = 100;
        TaxadvisoryServicesTok: Label 'Tax advisory Services', MaxLength = 100;
        TotalManagementFeesTok: Label 'Total, Management Fees', MaxLength = 100;
        TotalManagementandAdminTok: Label 'Total, Management and Admin', MaxLength = 100;
        BankingandInterestTok: Label 'Banking and Interest', MaxLength = 100;
        BankingfeesTok: Label 'Banking fees', MaxLength = 100;
        InterestExpensesTok: Label 'Interest Expenses', MaxLength = 100;
        PayableInvoiceRoundingTok: Label 'Payable Invoice Rounding', MaxLength = 100;
        TotalBankingandInterestTok: Label 'Total, Banking and Interest', MaxLength = 100;
        ExternalServices_ExpensesTok: Label 'External Services/Expenses', MaxLength = 100;
        ExternalServicesTok: Label 'External Services', MaxLength = 100;
        AccountingServicesTok: Label 'Accounting Services', MaxLength = 100;
        ITServicesTok: Label 'IT Services', MaxLength = 100;
        MediaServicesTok: Label 'Media Services', MaxLength = 100;
        ConsultingServicesTok: Label 'Consulting Services', MaxLength = 100;
        LegalFeesandAttorneyServicesTok: Label 'Legal Fees and Attorney Services', MaxLength = 100;
        OtherExternalServicesTok: Label 'Other External Services', MaxLength = 100;
        TotalExternalServicesTok: Label 'Total, External Services', MaxLength = 100;
        OtherExternalExpensesTok: Label 'Other External Expenses', MaxLength = 100;
        LicenseFees_RoyaltiesTok: Label 'License Fees/Royalties', MaxLength = 100;
        Trademarks_PatentsTok: Label 'Trademarks/Patents', MaxLength = 100;
        AssociationFeesTok: Label 'Association Fees', MaxLength = 100;
        MiscexternalexpensesTok: Label 'Misc. external expenses', MaxLength = 100;
        PurchaseDiscountsTok: Label 'Purchase Discounts', MaxLength = 100;
        TotalOtherExternalExpensesTok: Label 'Total, Other External Expenses', MaxLength = 100;
        TotalExternalServices_ExpensesTok: Label 'Total, External Services/Expenses', MaxLength = 100;
        PersonnelTok: Label 'Personnel', MaxLength = 100;
        WagesandSalariesTok: Label 'Wages and Salaries', MaxLength = 100;
        SalariesTok: Label 'Salaries', MaxLength = 100;
        HourlyWagesTok: Label 'Hourly Wages', MaxLength = 100;
        OvertimeWagesTok: Label 'Overtime Wages', MaxLength = 100;
        BonusesTok: Label 'Bonuses', MaxLength = 100;
        CommissionsPaidTok: Label 'Commissions Paid', MaxLength = 100;
        PTOAccruedTok: Label 'PTO Accrued', MaxLength = 100;
        TotalWagesandSalariesTok: Label 'Total, Wages and Salaries', MaxLength = 100;
        Benefits_PensionTok: Label 'Benefits/Pension', MaxLength = 100;
        BenefitsTok: Label 'Benefits', MaxLength = 100;
        TrainingCostsTok: Label 'Training Costs', MaxLength = 100;
        HealthCareContributionsTok: Label 'Health Care Contributions', MaxLength = 100;
        EntertainmentofpersonnelTok: Label 'Entertainment of personnel', MaxLength = 100;
        AllowancesTok: Label 'Allowances', MaxLength = 100;
        MandatoryclothingexpensesTok: Label 'Mandatory clothing expenses', MaxLength = 100;
        Othercash_remunerationbenefitsTok: Label 'Other cash/remuneration benefits', MaxLength = 100;
        TotalBenefitsTok: Label 'Total, Benefits', MaxLength = 100;
        PensionTok: Label 'Pension', MaxLength = 100;
        PensionfeesandrecurringcostsTok: Label 'Pension fees and recurring costs', MaxLength = 100;
        EmployerContributionsTok: Label 'Employer Contributions', MaxLength = 100;
        TotalPensionTok: Label 'Total, Pension', MaxLength = 100;
        TotalBenefits_PensionTok: Label 'Total, Benefits/Pension', MaxLength = 100;
        InsurancesPersonnelTok: Label 'Insurances, Personnel', MaxLength = 100;
        HealthInsuranceTok: Label 'Health Insurance', MaxLength = 100;
        DentalInsuranceTok: Label 'Dental Insurance', MaxLength = 100;
        WorkersCompensationTok: Label 'Worker''s Compensation', MaxLength = 100;
        LifeInsuranceTok: Label 'Life Insurance', MaxLength = 100;
        TotalInsurancesPersonnelTok: Label 'Total, Insurances, Personnel', MaxLength = 100;
        PersonnelTaxesTok: Label 'Personnel Taxes', MaxLength = 100;
        FederalPersonnelTaxesTok: Label 'Federal Personnel Taxes', MaxLength = 100;
        FederalWithholdingExpenseTok: Label 'Federal Withholding Expense', MaxLength = 100;
        FICAExpenseTok: Label 'FICA Expense', MaxLength = 100;
        FUTAExpenseTok: Label 'FUTA Expense', MaxLength = 100;
        MedicareExpenseTok: Label 'Medicare Expense', MaxLength = 100;
        OtherFederalExpenseTok: Label 'Other Federal Expense', MaxLength = 100;
        TotalFederalPersonnelTaxesTok: Label 'Total, Federal Personnel Taxes', MaxLength = 100;
        StatePersonnelTaxesTok: Label 'State Personnel Taxes', MaxLength = 100;
        StateWithholdingExpenseTok: Label 'State Withholding Expense', MaxLength = 100;
        SUTAExpenseTok: Label 'SUTA Expense', MaxLength = 100;
        TotalStatePersonnelTaxesTok: Label 'Total, State Personnel Taxes', MaxLength = 100;
        TotalPersonnelTaxesTok: Label 'Total, Personnel Taxes', MaxLength = 100;
        TotalPersonnelTok: Label 'Total, Personnel', MaxLength = 100;
        DepreciationTok: Label 'Depreciation', MaxLength = 100;
        DepreciationLandandPropertyTok: Label 'Depreciation, Land and Property', MaxLength = 100;
        DepreciationFixedAssetsTok: Label 'Depreciation, Fixed Assets', MaxLength = 100;
        TotalDepreciationTok: Label 'Total, Depreciation', MaxLength = 100;
        MiscExpensesTok: Label 'Misc. Expenses', MaxLength = 100;
        CurrencyLossesTok: Label 'Currency Losses', MaxLength = 100;
        TotalMiscExpensesTok: Label 'Total, Misc. Expenses', MaxLength = 100;
        TOTALEXPENSESTok: Label 'TOTAL EXPENSES', MaxLength = 100;
        NETINCOMETok: Label 'NET INCOME', MaxLength = 100;
        DebitCredit: Option;

    procedure InsertMiniAppData()
    begin
        AddIncomeStatementForMini();
        AddBalanceSheetForMini();

        GLAccIndent.Indent();
        AddCategoriesToGLAccountsForMini();
    end;

    local procedure AddIncomeStatementForMini()
    begin
        // Income statement 1000-4999
        DemoDataSetup.Get();
        InsertData(INCOMESTATEMENT(), INCOMESTATEMENTName(), 1, 0, 1, '', 0, '', '', '', '', true);
        InsertData(Income(), IncomeName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesofGoods(), SalesofGoodsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SaleofFinishedGoods(), SaleofFinishedGoodsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(SaleofRawMaterials(), SaleofRawMaterialsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(ResaleofGoods(), ResaleofGoodsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(TotalSalesofGoods(), TotalSalesofGoodsName(), 4, 0, 0, '40100..40199', 0, '', '', '', '', true);
        InsertData(SalesofResources(), SalesofResourcesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SaleofResources(), SaleofResourcesName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(SaleofSubcontracting(), SaleofSubcontractingName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(TotalSalesofResources(), TotalSalesofResourcesName(), 4, 0, 0, '40200..40299', 0, '', '', '', '', true);
        InsertData(AdditionalRevenue(), AdditionalRevenueName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Incomefromsecurities(), IncomefromsecuritiesName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(ManagementFeeRevenue(), ManagementFeeRevenueName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(InterestIncome(), InterestIncomeName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(CurrencyGains(), CurrencyGainsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(OtherIncidentalRevenue(), OtherIncidentalRevenueName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(TotalAdditionalRevenue(), TotalAdditionalRevenueName(), 4, 0, 0, '40300..40399', 0, '', '', '', '', true);
        InsertData(JobsandServices(), JobsandServicesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobSales(), JobSalesName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(JobSalesApplied(), JobSalesAppliedName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(SalesofServiceContracts(), SalesofServiceContractsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(SalesofServiceWork(), SalesofServiceWorkName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(TotalJobsandServices(), TotalJobsandServicesName(), 4, 0, 0, '40400..40499', 0, '', '', '', '', true);
        InsertData(RevenueReductions(), RevenueReductionsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesDiscounts(), SalesDiscountsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(SalesInvoiceRounding(), SalesInvoiceRoundingName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(PaymentToleranceandAllowances(), PaymentToleranceandAllowancesName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(SalesReturns(), SalesReturnsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(TotalRevenueReductions(), TotalRevenueReductionsName(), 4, 0, 0, '40900..40999', 0, '', '', '', '', true);
        InsertData(TOTALINCOME(), TOTALINCOMEName(), 4, 0, 0, '40001..49990', 0, '', '', '', '', true);
        InsertData(COSTOFGOODSSOLD(), COSTOFGOODSSOLDName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofGoods(), CostofGoodsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofMaterials(), CostofMaterialsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofMaterialsProjects(), CostofMaterialsProjectsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofGoods(), TotalCostofGoodsName(), 4, 0, 0, '50100..50199', 0, '', '', '', '', true);
        InsertData(CostofResourcesandServices(), CostofResourcesandServicesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofLabor(), CostofLaborName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofLaborProjects(), CostofLaborProjectsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofLaborWarranty_Contract(), CostofLaborWarranty_ContractName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofResources(), TotalCostofResourcesName(), 4, 0, 0, '50200..50299', 0, '', '', '', '', true);
        InsertData(Subcontractedwork(), SubcontractedworkName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofVariances(), CostofVariancesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TOTALCOSTOFGOODSSOLD(), TOTALCOSTOFGOODSSOLDName(), 4, 0, 0, '50001..59990', 0, '', '', '', '', true);
        InsertData(EXPENSES(), EXPENSESName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(FacilityExpenses(), FacilityExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(RentalFacilities(), RentalFacilitiesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Rent_Leases(), Rent_LeasesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ElectricityforRental(), ElectricityforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HeatingforRental(), HeatingforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(WaterandSewerageforRental(), WaterandSewerageforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CleaningandWasteforRental(), CleaningandWasteforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(RepairsandMaintenanceforRental(), RepairsandMaintenanceforRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(InsurancesRental(), InsurancesRentalName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherRentalExpenses(), OtherRentalExpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalRentalFacilities(), TotalRentalFacilitiesName(), 4, 0, 0, '60100..60199', 1, '', '', '', '', true);
        InsertData(PropertyExpenses(), PropertyExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(SiteFees_Leases(), SiteFees_LeasesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ElectricityforProperty(), ElectricityforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HeatingforProperty(), HeatingforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(WaterandSewerageforProperty(), WaterandSewerageforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CleaningandWasteforProperty(), CleaningandWasteforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(RepairsandMaintenanceforProperty(), RepairsandMaintenanceforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(InsurancesProperty(), InsurancesPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherPropertyExpenses(), OtherPropertyExpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalPropertyExpenses(), TotalPropertyExpensesName(), 4, 0, 0, '60200..60299', 1, '', '', '', '', true);
        InsertData(TotalFacilityExpenses(), TotalFacilityExpensesName(), 4, 0, 0, '60002..60999', 1, '', '', '', '', true);
        InsertData(FixedAssetsLeases(), FixedAssetsLeasesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Hireofmachinery(), HireofmachineryName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Hireofcomputers(), HireofcomputersName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Hireofotherfixedassets(), HireofotherfixedassetsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalFixedAssetLeases(), TotalFixedAssetLeasesName(), 4, 0, 0, '61000..61999', 1, '', '', '', '', true);
        InsertData(LogisticsExpenses(), LogisticsExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(VehicleExpenses(), VehicleExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PassengerCarCosts(), PassengerCarCostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TruckCosts(), TruckCostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Othervehicleexpenses(), OthervehicleexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalVehicleExpenses(), TotalVehicleExpensesName(), 4, 0, 0, '62100..62199', 1, '', '', '', '', true);
        InsertData(FreightCosts(), FreightCostsName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Freightfeesforgoods(), FreightfeesforgoodsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Customsandforwarding(), CustomsandforwardingName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Freightfeesprojects(), FreightfeesprojectsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalFreightCosts(), TotalFreightCostsName(), 4, 0, 0, '62200..62299', 1, '', '', '', '', true);
        InsertData(TravelExpenses(), TravelExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Tickets(), TicketsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Rentalvehicles(), RentalvehiclesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Boardandlodging(), BoardandlodgingName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Othertravelexpenses(), OthertravelexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalTravelExpenses(), TotalTravelExpensesName(), 4, 0, 0, '62300..62399', 1, '', '', '', '', true);
        InsertData(TotalLogisticsExpenses(), TotalLogisticsExpensesName(), 4, 0, 0, '62000..62999', 1, '', '', '', '', true);
        InsertData(MarketingandSales(), MarketingandSalesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Advertising(), AdvertisingName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(AdvertisementDevelopment(), AdvertisementDevelopmentName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OutdoorandTransportationAds(), OutdoorandTransportationAdsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Admatteranddirectmailings(), AdmatteranddirectmailingsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Conference_ExhibitionSponsorship(), Conference_ExhibitionSponsorshipName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Samplescontestsgifts(), SamplescontestsgiftsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(FilmTVradiointernetads(), FilmTVradiointernetadsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PRandAgencyFees(), PRandAgencyFeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Otheradvertisingfees(), OtheradvertisingfeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalAdvertising(), TotalAdvertisingName(), 4, 0, 0, '63100..63199', 1, '', '', '', '', true);
        InsertData(OtherMarketingExpenses(), OtherMarketingExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Catalogspricelists(), CatalogspricelistsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TradePublications(), TradePublicationsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalOtherMarketingExpenses(), TotalOtherMarketingExpensesName(), 4, 0, 0, '63200..63399', 1, '', '', '', '', true);
        InsertData(SalesExpenses(), SalesExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CreditCardCharges(), CreditCardChargesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BusinessEntertainingdeductible(), BusinessEntertainingdeductibleName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BusinessEntertainingnondeductible(), BusinessEntertainingnondeductibleName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalSalesExpenses(), TotalSalesExpensesName(), 4, 0, 0, '63400..63499', 1, '', '', '', '', true);
        InsertData(TotalMarketingandSales(), TotalMarketingandSalesName(), 4, 0, 0, '63000..63999', 1, '', '', '', '', true);
        InsertData(OfficeExpenses(), OfficeExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OfficeSupplies(), OfficeSuppliesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PhoneServices(), PhoneServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Dataservices(), DataservicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Postalfees(), PostalfeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Consumable_Expensiblehardware(), Consumable_ExpensiblehardwareName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Softwareandsubscriptionfees(), SoftwareandsubscriptionfeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalOfficeExpenses(), TotalOfficeExpensesName(), 4, 0, 0, '64000..64999', 1, '', '', '', '', true);
        InsertData(InsurancesandRisks(), InsurancesandRisksName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CorporateInsurance(), CorporateInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(DamagesPaid(), DamagesPaidName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BadDebtLosses(), BadDebtLossesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Securityservices(), SecurityservicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Otherriskexpenses(), OtherriskexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalInsurancesandRisks(), TotalInsurancesandRisksName(), 4, 0, 0, '65000..65999', 1, '', '', '', '', true);
        InsertData(ManagementandAdmin(), ManagementandAdminName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Management(), ManagementName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(RemunerationtoDirectors(), RemunerationtoDirectorsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ManagementFees(), ManagementFeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Annual_interrimReports(), Annual_interrimReportsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Annual_generalmeeting(), Annual_generalmeetingName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(AuditandAuditServices(), AuditandAuditServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TaxadvisoryServices(), TaxadvisoryServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalManagementFees(), TotalManagementFeesName(), 4, 0, 0, '66100..66199', 1, '', '', '', '', true);
        InsertData(TotalManagementandAdmin(), TotalManagementandAdminName(), 4, 0, 0, '66000..66999', 1, '', '', '', '', true);
        InsertData(BankingandInterest(), BankingandInterestName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Bankingfees(), BankingfeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(InterestExpenses(), InterestExpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PayableInvoiceRounding(), PayableInvoiceRoundingName(), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(TotalBankingandInterest(), TotalBankingandInterestName(), 4, 0, 0, '67000..67999', 1, '', '', '', '', true);
        InsertData(ExternalServices_Expenses(), ExternalServices_ExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ExternalServices(), ExternalServicesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(AccountingServices(), AccountingServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ITServices(), ITServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(MediaServices(), MediaServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ConsultingServices(), ConsultingServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(LegalFeesandAttorneyServices(), LegalFeesandAttorneyServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherExternalServices(), OtherExternalServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalExternalServices(), TotalExternalServicesName(), 4, 0, 0, '68100..68199', 1, '', '', '', '', true);
        InsertData(OtherExternalExpenses(), OtherExternalExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(LicenseFees_Royalties(), LicenseFees_RoyaltiesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Trademarks_Patents(), Trademarks_PatentsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(AssociationFees(), AssociationFeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Miscexternalexpenses(), MiscexternalexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PurchaseDiscounts(), PurchaseDiscountsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalOtherExternalExpenses(), TotalOtherExternalExpensesName(), 4, 0, 0, '68200..68299', 1, '', '', '', '', true);
        InsertData(TotalExternalServices_Expenses(), TotalExternalServices_ExpensesName(), 4, 0, 0, '68000..68999', 1, '', '', '', '', true);
        InsertData(Personnel(), PersonnelName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(WagesandSalaries(), WagesandSalariesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Salaries(), SalariesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HourlyWages(), HourlyWagesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OvertimeWages(), OvertimeWagesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Bonuses(), BonusesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CommissionsPaid(), CommissionsPaidName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PTOAccrued(), PTOAccruedName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalWagesandSalaries(), TotalWagesandSalariesName(), 4, 0, 0, '71000..71999', 1, '', '', '', '', true);
        InsertData(Benefits_Pension(), Benefits_PensionName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Benefits(), BenefitsName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TrainingCosts(), TrainingCostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HealthCareContributions(), HealthCareContributionsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Entertainmentofpersonnel(), EntertainmentofpersonnelName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Allowances(), AllowancesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Mandatoryclothingexpenses(), MandatoryclothingexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Othercash_remunerationbenefits(), Othercash_remunerationbenefitsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalBenefits(), TotalBenefitsName(), 4, 0, 0, '72100..72199', 1, '', '', '', '', true);
        InsertData(Pension(), PensionName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Pensionfeesandrecurringcosts(), PensionfeesandrecurringcostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(EmployerContributions(), EmployerContributionsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalPension(), TotalPensionName(), 4, 0, 0, '72200..72299', 1, '', '', '', '', true);
        InsertData(TotalBenefits_Pension(), TotalBenefits_PensionName(), 4, 0, 0, '72000..72999', 1, '', '', '', '', true);
        InsertData(InsurancesPersonnel(), InsurancesPersonnelName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HealthInsurance(), HealthInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(DentalInsurance(), DentalInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(WorkersCompensation(), WorkersCompensationName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(LifeInsurance(), LifeInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalInsurancesPersonnel(), TotalInsurancesPersonnelName(), 4, 0, 0, '73000..73999', 1, '', '', '', '', true);
        InsertData(PersonnelTaxes(), PersonnelTaxesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(FederalPersonnelTaxes(), FederalPersonnelTaxesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(FederalWithholdingExpense(), FederalWithholdingExpenseName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(FICAExpense(), FICAExpenseName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(FUTAExpense(), FUTAExpenseName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(MedicareExpense(), MedicareExpenseName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherFederalExpense(), OtherFederalExpenseName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalFederalPersonnelTaxes(), TotalFederalPersonnelTaxesName(), 4, 0, 0, '74100..74399', 1, '', '', '', '', true);
        InsertData(StatePersonnelTaxes(), StatePersonnelTaxesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(StateWithholdingExpense(), StateWithholdingExpenseName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(SUTAExpense(), SUTAExpenseName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalStatePersonnelTaxes(), TotalStatePersonnelTaxesName(), 4, 0, 0, '74400..74599', 1, '', '', '', '', true);
        InsertData(TotalPersonnelTaxes(), TotalPersonnelTaxesName(), 4, 0, 0, '74000..74999', 1, '', '', '', '', true);
        InsertData(TotalPersonnel(), TotalPersonnelName(), 4, 0, 0, '70000..79999', 1, '', '', '', '', true);
        InsertData(Depreciation(), DepreciationName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(DepreciationLandandProperty(), DepreciationLandandPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(DepreciationFixedAssets(), DepreciationFixedAssetsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalDepreciation(), TotalDepreciationName(), 4, 0, 0, '80000..89999', 1, '', '', '', '', true);
        InsertData(MiscExpenses(), MiscExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CurrencyLosses(), CurrencyLossesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalMiscExpenses(), TotalMiscExpensesName(), 4, 0, 0, '90000..91999', 1, '', '', '', '', true);
        InsertData(TOTALEXPENSES(), TOTALEXPENSESName(), 4, 0, 0, '60001..98990', 1, '', '', '', '', true);
        InsertData(NETINCOME(), NETINCOMEName(), 2, 0, 0, '40000..49999|50000..59999|60000..99999', 0, '', '', '', '', true);
    end;

    procedure AddBalanceSheetForMini()
    begin
        // Balance sheet 5000-9999
        DemoDataSetup.Get();
        InsertData(BalanceSheet(), BalanceSheetName(), 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData(Assets(), AssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(IntangibleFixedAssets(), IntangibleFixedAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DevelopmentExpenditure(), DevelopmentExpenditureName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TenancySiteLeaseholdandsimilarrights(), TenancySiteLeaseholdandsimilarrightsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Goodwill(), GoodwillName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AdvancedPaymentsforIntangibleFixedAssets(), AdvancedPaymentsforIntangibleFixedAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalIntangibleFixedAssets(), TotalIntangibleFixedAssetsName(), 4, 1, 0, '11000..11999', 0, '', '', '', '', true);
        InsertData(TangibleFixedAssets(), TangibleFixedAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LandandBuildings(), LandandBuildingsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Building(), BuildingName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CostofImprovementstoLeasedProperty(), CostofImprovementstoLeasedPropertyName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Land(), LandName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalLandandbuilding(), TotalLandandbuildingName(), 4, 1, 0, '12100..12199', 0, '', '', '', '', true);
        InsertData(MachineryandEquipment(), MachineryandEquipmentName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EquipmentsandTools(), EquipmentsandToolsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Computers(), ComputersName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CarsandotherTransportEquipments(), CarsandotherTransportEquipmentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LeasedAssets(), LeasedAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalMachineryandEquipment(), TotalMachineryandEquipmentName(), 4, 1, 0, '12200..12299', 0, '', '', '', '', true);
        InsertData(AccumulatedDepreciation(), AccumulatedDepreciationName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalTangibleAssets(), TotalTangibleAssetsName(), 4, 1, 0, '12000..12999', 0, '', '', '', '', true);
        InsertData(FinancialandFixedAssets(), FinancialandFixedAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Long_termReceivables(), Long_termReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ParticipationinGroupCompanies(), ParticipationinGroupCompaniesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LoanstoPartnersorrelatedParties(), LoanstoPartnersorrelatedPartiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DeferredTaxAssets(), DeferredTaxAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLong_termReceivables(), OtherLong_termReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalFinancialandFixedAssets(), TotalFinancialandFixedAssetsName(), 4, 1, 0, '13000..13999', 0, '', '', '', '', true);
        InsertData(InventoriesProductsandworkinProgress(), InventoriesProductsandworkinProgressName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RawMaterials(), RawMaterialsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SuppliesandConsumables(), SuppliesandConsumablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ProductsinProgress(), ProductsinProgressName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(FinishedGoods(), FinishedGoodsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GoodsforResale(), GoodsforResaleName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AdvancedPaymentsforgoodsandservices(), AdvancedPaymentsforgoodsandservicesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherInventoryItems(), OtherInventoryItemsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WorkinProgress(), WorkinProgressName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WorkinProgressFinishedGoods(), WorkinProgressFinishedGoodsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPJobSales(), WIPJobSalesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPJobCosts(), WIPJobCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPAccruedCosts(), WIPAccruedCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPInvoicedSales(), WIPInvoicedSalesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalWorkinProgress(), TotalWorkinProgressName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Receivables(), ReceivablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsReceivables(), AccountsReceivablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountReceivableDomestic(), AccountReceivableDomesticName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountReceivableForeign(), AccountReceivableForeignName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ContractualReceivables(), ContractualReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ConsignmentReceivables(), ConsignmentReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CreditcardsandVouchersReceivables(), CreditcardsandVouchersReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalAccountReceivables(), TotalAccountReceivablesName(), 4, 1, 0, '15100..15199', 0, '', '', '', '', true);
        InsertData(OtherCurrentReceivables(), OtherCurrentReceivablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentReceivablefromEmployees(), CurrentReceivablefromEmployeesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Accruedincomenotyetinvoiced(), AccruedincomenotyetinvoicedName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ClearingAccountsforTaxesandcharges(), ClearingAccountsforTaxesandchargesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TaxAssets(), TaxAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentReceivablesfromgroupcompanies(), CurrentReceivablesfromgroupcompaniesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalOtherCurrentReceivables(), TotalOtherCurrentReceivablesName(), 4, 1, 0, '15900..15998', 0, '', '', '', '', true);
        InsertData(TotalReceivables(), TotalReceivablesName(), 4, 1, 0, '15000..15999', 0, '', '', '', '', true);
        InsertData(PrepaidexpensesandAccruedIncome(), PrepaidexpensesandAccruedIncomeName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PrepaidRent(), PrepaidRentName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PrepaidInterestexpense(), PrepaidInterestexpenseName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedRentalIncome(), AccruedRentalIncomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedInterestIncome(), AccruedInterestIncomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Assetsintheformofprepaidexpenses(), AssetsintheformofprepaidexpensesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Otherprepaidexpensesandaccruedincome(), OtherprepaidexpensesandaccruedincomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalPrepaidexpensesandAccruedIncome(), TotalPrepaidexpensesandAccruedIncomeName(), 4, 1, 0, '16000..16999', 0, '', '', '', '', true);
        InsertData(Short_terminvestments(), Short_terminvestmentsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Bonds(), BondsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Convertibledebtinstruments(), ConvertibledebtinstrumentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Othershort_termInvestments(), Othershort_termInvestmentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Write_downofShort_terminvestments(), Write_downofShort_terminvestmentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Totalshortterminvestments(), TotalshortterminvestmentsName(), 4, 1, 0, '17000..17999', 0, '', '', '', '', true);
        InsertData(CashandBank(), CashandBankName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PettyCash(), PettyCashName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BusinessaccountOperatingDomestic(), BusinessaccountOperatingDomesticName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BusinessaccountOperatingForeign(), BusinessaccountOperatingForeignName(), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData(Otherbankaccounts(), OtherbankaccountsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CertificateofDeposit(), CertificateofDepositName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCashandBank(), TotalCashandBankName(), 4, 1, 0, '18000..18999', 0, '', '', '', '', true);
        InsertData(TotalAssets(), TotalAssetsName(), 4, 1, 0, '11000..19999', 0, '', '', '', '', true);
        InsertData(Liability(), LiabilityName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Long_TermLiabilities(), Long_TermLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BondsandDebentureLoans(), BondsandDebentureLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ConvertiblesLoans(), ConvertiblesLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLong_termLiabilities(), OtherLong_termLiabilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BankoverdraftFacilities(), BankoverdraftFacilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalLong_termLiabilities(), TotalLong_termLiabilitiesName(), 4, 1, 0, '21000..21999', 0, '', '', '', '', true);
        InsertData(CurrentLiabilities(), CurrentLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsPayableDomestic(), AccountsPayableDomesticName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsPayableForeign(), AccountsPayableForeignName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Advancesfromcustomers(), AdvancesfromcustomersName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ChangeinWorkinProgress(), ChangeinWorkinProgressName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Bankoverdraftshort_term(), Bankoverdraftshort_termName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLiabilities(), OtherLiabilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCurrentLiabilities(), TotalCurrentLiabilitiesName(), 4, 1, 0, '22000..22999', 0, '', '', '', '', true);
        InsertData(TaxLiabilities(), TaxLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SalesTax_VATLiable(), SalesTax_VATLiableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TaxesLiable(), TaxesLiableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EstimatedIncomeTax(), EstimatedIncomeTaxName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EstimatedPayrolltaxonPensionCosts(), EstimatedPayrolltaxonPensionCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalTaxLiabilities(), TotalTaxLiabilitiesName(), 4, 1, 0, '23000..23999', 0, '', '', '', '', true);
        InsertData(PayrollLiabilities(), PayrollLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EmployeesWithholdingTaxes(), EmployeesWithholdingTaxesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(StatutorySocialsecurityContributions(), StatutorySocialsecurityContributionsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ContractualSocialsecurityContributions(), ContractualSocialsecurityContributionsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AttachmentsofEarning(), AttachmentsofEarningName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(HolidayPayfund(), HolidayPayfundName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherSalary_wageDeductions(), OtherSalary_wageDeductionsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalPayrollLiabilities(), TotalPayrollLiabilitiesName(), 4, 1, 0, '24000..24999', 0, '', '', '', '', true);
        InsertData(OtherCurrentLiabilities(), OtherCurrentLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ClearingAccountforFactoringCurrentPortion(), ClearingAccountforFactoringCurrentPortionName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentLiabilitiestoEmployees(), CurrentLiabilitiestoEmployeesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ClearingAccountforthirdparty(), ClearingAccountforthirdpartyName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentLoans(), CurrentLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LiabilitiesGrantsReceived(), LiabilitiesGrantsReceivedName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalOtherCurrentLiabilities(), TotalOtherCurrentLiabilitiesName(), 4, 1, 0, '25000..25999', 0, '', '', '', '', true);
        InsertData(AccruedExpensesandDeferredIncome(), AccruedExpensesandDeferredIncomeName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Accruedwages_salaries(), Accruedwages_salariesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedHolidaypay(), AccruedHolidaypayName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedPensioncosts(), AccruedPensioncostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedInterestExpense(), AccruedInterestExpenseName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DeferredIncome(), DeferredIncomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedContractualcosts(), AccruedContractualcostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherAccruedExpensesandDeferredIncome(), OtherAccruedExpensesandDeferredIncomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalAccruedExpensesandDeferredIncome(), TotalAccruedExpensesandDeferredIncomeName(), 4, 1, 0, '26000..26999', 0, '', '', '', '', true);
        InsertData(TotalLiabilities(), TotalLiabilitiesName(), 4, 1, 0, '20000..29999', 0, '', '', '', '', true);
        InsertData(Equity(), EquityName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EquityPartner(), EquityPartnerName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(NetResults(), NetResultsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RestrictedEquity(), RestrictedEquityName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ShareCapital(), ShareCapitalName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Non_RestrictedEquity(), Non_RestrictedEquityName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Profitorlossfromthepreviousyear(), ProfitorlossfromthepreviousyearName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ResultsfortheFinancialyear(), ResultsfortheFinancialyearName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DistributionstoShareholders(), DistributionstoShareholdersName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalEquity(), TotalEquityName(), 4, 1, 0, '30000..39999', 0, '', '', '', '', true);
    end;

    procedure InsertData(AccountNo: Code[20]; AccountName: Text[100]; AccountType: Option; IncomeBalance: Option; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectPosting: Boolean)
    var
        GLAccount: Record "G/L Account";
        Char: Char;
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", Adjust.Convert(AccountNo));
        GLAccount.Validate(Name, AccountName);
        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then begin
            Char := GLAccount."No."[1];
            if Char in ['4' .. '6'] then
                DirectPosting := true;
            GLAccount.Validate("Direct Posting", DirectPosting);
            GLAccount."Tax Group Code" := XNONTAXABLE;
        end;
        GLAccount.Validate("Income/Balance", "G/L Account Report Type".FromInteger(IncomeBalance));
        case AccountNo of
            '992910', '992920', '992930', '992940', '995310',
          '10100', '10200', '10300', '10400', '20100', PettyCash():
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
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            if VATGenPostingGroup <> '' then
                GLAccount.Validate("VAT Bus. Posting Group", VATGenPostingGroup);
            if VATProdPostingGroup <> '' then
                GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        end;
        GLAccount.Validate("Debit/Credit", DebitCredit);
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

    local procedure AddCategoriesToGLAccountsForMini()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if GLAccountCategory.IsEmpty() then
            exit;

        GLAccountCategory.SetRange("Parent Entry No.", 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignCategoryToChartOfAccountsForMini(GLAccountCategory);
            until GLAccountCategory.Next() = 0;

        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignSubcategoryToChartOfAccountsForMini(GLAccountCategory);
            until GLAccountCategory.Next() = 0;
    end;

    local procedure AssignCategoryToChartOfAccountsForMini(GLAccountCategory: Record "G/L Account Category")
    begin
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Assets:
                UpdateGLAccounts(GLAccountCategory, '10000', '19999');
            GLAccountCategory."Account Category"::Liabilities:
                UpdateGLAccounts(GLAccountCategory, '20000', '29999');
            GLAccountCategory."Account Category"::Equity:
                UpdateGLAccounts(GLAccountCategory, '30000', '39999');
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, '40000', '49990');
                    UpdateGLAccounts(GLAccountCategory, '99999', '99999');
                end;
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                UpdateGLAccounts(GLAccountCategory, '50001', '59990');
            GLAccountCategory."Account Category"::Expense:
                UpdateGLAccounts(GLAccountCategory, '60001', '98990');
        end;
    end;

    local procedure AssignSubcategoryToChartOfAccountsForMini(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCash():
                UpdateGLAccounts(GLAccountCategory, '18100', '18500');
            GLAccountCategoryMgt.GetPrepaidExpenses():
                UpdateGLAccounts(GLAccountCategory, '16100', '16600');
            GLAccountCategoryMgt.GetInventory():
                UpdateGLAccounts(GLAccountCategory, '14000', '14999');
            GLAccountCategoryMgt.GetAR():
                UpdateGLAccounts(GLAccountCategory, '15000', '15200');
            GLAccountCategoryMgt.GetEquipment():
                UpdateGLAccounts(GLAccountCategory, '12210', '12299');
            GLAccountCategoryMgt.GetAccumDeprec():
                UpdateGLAccounts(GLAccountCategory, '12900', '12900');
            GLAccountCategoryMgt.GetCurrentLiabilities():
                UpdateGLAccounts(GLAccountCategory, '22100', '25500');
            GLAccountCategoryMgt.GetPayrollLiabilities():
                UpdateGLAccounts(GLAccountCategory, '24100', '24600');
            GLAccountCategoryMgt.GetDistrToShareholders():
                UpdateGLAccounts(GLAccountCategory, '30320', '30320');
            GLAccountCategoryMgt.GetIncomeService():
                UpdateGLAccounts(GLAccountCategory, '40200', '40299');
            GLAccountCategoryMgt.GetIncomeProdSales():
                UpdateGLAccounts(GLAccountCategory, '40100', '40199');
            GLAccountCategoryMgt.GetCOGSLabor():
                UpdateGLAccounts(GLAccountCategory, '50200', '50299');
            GLAccountCategoryMgt.GetCOGSMaterials():
                UpdateGLAccounts(GLAccountCategory, '50100', '50199');
            GLAccountCategoryMgt.GetRentExpense():
                UpdateGLAccounts(GLAccountCategory, '60110', '60110');
            GLAccountCategoryMgt.GetAdvertisingExpense():
                UpdateGLAccounts(GLAccountCategory, '63100', '63399');
            GLAccountCategoryMgt.GetInterestExpense():
                UpdateGLAccounts(GLAccountCategory, '40330', '40330');
            GLAccountCategoryMgt.GetFeesExpense():
                UpdateGLAccounts(GLAccountCategory, '67100', '67200');
            GLAccountCategoryMgt.GetBadDebtExpense():
                UpdateGLAccounts(GLAccountCategory, '65300', '65300');
            GLAccountCategoryMgt.GetInsuranceExpense():
                UpdateGLAccounts(GLAccountCategory, '73000', '73999');
            GLAccountCategoryMgt.GetBenefitsExpense():
                UpdateGLAccounts(GLAccountCategory, '72000', '72999');
            GLAccountCategoryMgt.GetRepairsExpense():
                UpdateGLAccounts(GLAccountCategory, '60160', '60160');
            GLAccountCategoryMgt.GetUtilitiesExpense():
                UpdateGLAccounts(GLAccountCategory, '60120', '60150');
            GLAccountCategoryMgt.GetTaxExpense():
                UpdateGLAccounts(GLAccountCategory, '74000', '79999');
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
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Assets:
                UpdateGLAccounts(GLAccountCategory, '10100', '10900');
            GLAccountCategory."Account Category"::Liabilities:
                begin
                    UpdateGLAccounts(GLAccountCategory, '993000', '993000');
                    UpdateGLAccounts(GLAccountCategory, '995000', '995000');
                    UpdateGLAccounts(GLAccountCategory, '995997', '995997');
                    UpdateGLAccounts(GLAccountCategory, '20100', '21900');
                end;
            GLAccountCategory."Account Category"::Equity:
                begin
                    UpdateGLAccounts(GLAccountCategory, '8030000', '8030000');
                    UpdateGLAccounts(GLAccountCategory, '993195', '993199');
                    UpdateGLAccounts(GLAccountCategory, '30100', '30900');
                end;
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, '998995', '998995');
                    UpdateGLAccounts(GLAccountCategory, '999100', '999190');
                    UpdateGLAccounts(GLAccountCategory, '999310', '999310');
                    UpdateGLAccounts(GLAccountCategory, '999330', '999330');
                    UpdateGLAccounts(GLAccountCategory, '998840', '998840');
                    UpdateGLAccounts(GLAccountCategory, '999410', '999410');
                    UpdateGLAccounts(GLAccountCategory, '8059999', '8059999');
                    UpdateGLAccounts(GLAccountCategory, '8085000', '8085300');
                    UpdateGLAccounts(GLAccountCategory, '8080700', '8080700');
                    UpdateGLAccounts(GLAccountCategory, '40100', '40900');
                end;
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                UpdateGLAccounts(GLAccountCategory, '50100', '50900');
            GLAccountCategory."Account Category"::Expense:
                begin
                    UpdateGLAccounts(GLAccountCategory, '998000', '998994');
                    UpdateGLAccounts(GLAccountCategory, '999320', '999320');
                    UpdateGLAccounts(GLAccountCategory, '999340', '999340');
                    UpdateGLAccounts(GLAccountCategory, '60100', '61900');
                end;
        end;
    end;

    local procedure AssignSubcategoryToLocalChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetFixedAssets():
                UpdateGLAccounts(GLAccountCategory, '10800', '10900');
            GLAccountCategoryMgt.GetCurrentAssets():
                UpdateGLAccounts(GLAccountCategory, '10100', '10700');
            GLAccountCategoryMgt.GetCash():
                UpdateGLAccounts(GLAccountCategory, '10100', '10300');
            GLAccountCategoryMgt.GetAR():
                UpdateGLAccounts(GLAccountCategory, '10400', '10400');
            GLAccountCategoryMgt.GetPrepaidExpenses():
                UpdateGLAccounts(GLAccountCategory, '10500', '10600');
            GLAccountCategoryMgt.GetInventory():
                UpdateGLAccounts(GLAccountCategory, '10700', '10700');
            GLAccountCategoryMgt.GetEquipment():
                UpdateGLAccounts(GLAccountCategory, '10800', '10800');
            GLAccountCategoryMgt.GetAccumDeprec():
                UpdateGLAccounts(GLAccountCategory, '10900', '10900');
            GLAccountCategoryMgt.GetCurrentLiabilities():
                UpdateGLAccounts(GLAccountCategory, '20100', '20600');
            GLAccountCategoryMgt.GetPayrollLiabilities():
                UpdateGLAccounts(GLAccountCategory, '20700', '21500');
            GLAccountCategoryMgt.GetLongTermLiabilities():
                UpdateGLAccounts(GLAccountCategory, '21900', '21900');
            GLAccountCategoryMgt.GetCommonStock():
                UpdateGLAccounts(GLAccountCategory, '30100', '30100');
            GLAccountCategoryMgt.GetRetEarnings():
                UpdateGLAccounts(GLAccountCategory, '30200', '30200');
            GLAccountCategoryMgt.GetDistrToShareholders():
                UpdateGLAccounts(GLAccountCategory, '30300', '30300');
            GLAccountCategoryMgt.GetIncomeService():
                if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then
                    UpdateGLAccounts(GLAccountCategory, '996950', '996959')
                else
                    UpdateGLAccounts(GLAccountCategory, '40100', '40100');
            GLAccountCategoryMgt.GetIncomeProdSales():
                if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then
                    UpdateGLAccounts(GLAccountCategory, '996100', '996695')
                else
                    UpdateGLAccounts(GLAccountCategory, '40200', '40200');
            GLAccountCategoryMgt.GetIncomeSalesDiscounts():
                UpdateGLAccounts(GLAccountCategory, '40300', '40300');
            GLAccountCategoryMgt.GetIncomeSalesReturns():
                UpdateGLAccounts(GLAccountCategory, '40400', '40500');
            GLAccountCategoryMgt.GetCOGSLabor():
                ;
            GLAccountCategoryMgt.GetCOGSMaterials():
                UpdateGLAccounts(GLAccountCategory, '50100', '50100');
            GLAccountCategoryMgt.GetRentExpense():
                UpdateGLAccounts(GLAccountCategory, '60100', '60100');
            GLAccountCategoryMgt.GetAdvertisingExpense():
                UpdateGLAccounts(GLAccountCategory, '60200', '60200');
            GLAccountCategoryMgt.GetInterestExpense():
                UpdateGLAccounts(GLAccountCategory, '60300', '60300');
            GLAccountCategoryMgt.GetFeesExpense():
                UpdateGLAccounts(GLAccountCategory, '60400', '60500');
            GLAccountCategoryMgt.GetBadDebtExpense():
                UpdateGLAccounts(GLAccountCategory, '60600', '60600');
            GLAccountCategoryMgt.GetSalariesExpense():
                UpdateGLAccounts(GLAccountCategory, '60700', '60700');
            GLAccountCategoryMgt.GetPayrollExpense():
                UpdateGLAccounts(GLAccountCategory, '60800', '60900');
            GLAccountCategoryMgt.GetBenefitsExpense():
                UpdateGLAccounts(GLAccountCategory, '61000', '61100');
            GLAccountCategoryMgt.GetRepairsExpense():
                UpdateGLAccounts(GLAccountCategory, '61200', '61200');
            GLAccountCategoryMgt.GetUtilitiesExpense():
                UpdateGLAccounts(GLAccountCategory, '61300', '61300');
            GLAccountCategoryMgt.GetOtherIncomeExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '998600', '998690');
                    UpdateGLAccounts(GLAccountCategory, '61400', '61600');
                end;
            GLAccountCategoryMgt.GetTaxExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '8084000', '8084500');
                    UpdateGLAccounts(GLAccountCategory, '61700', '61800');
                end;
        end;
    end;

    internal procedure BalanceSheet(): Code[20]
    begin
        exit('10000');
    end;

    internal procedure BalanceSheetName(): Text[100]
    begin
        exit(BalanceSheetTok);
    end;


    internal procedure Assets(): Code[20]
    begin
        exit('10001');
    end;

    internal procedure AssetsName(): Text[100]
    begin
        exit(AssetsTok);
    end;


    internal procedure IntangibleFixedAssets(): Code[20]
    begin
        exit('11000');
    end;

    internal procedure IntangibleFixedAssetsName(): Text[100]
    begin
        exit(IntangibleFixedAssetsTok);
    end;


    internal procedure DevelopmentExpenditure(): Code[20]
    begin
        exit('11100');
    end;

    internal procedure DevelopmentExpenditureName(): Text[100]
    begin
        exit(DevelopmentExpenditureTok);
    end;


    internal procedure TenancySiteLeaseholdandsimilarrights(): Code[20]
    begin
        exit('11200');
    end;

    internal procedure TenancySiteLeaseholdandsimilarrightsName(): Text[100]
    begin
        exit(TenancySiteLeaseholdandsimilarrightsTok);
    end;


    internal procedure Goodwill(): Code[20]
    begin
        exit('11300');
    end;

    internal procedure GoodwillName(): Text[100]
    begin
        exit(GoodwillTok);
    end;


    internal procedure AdvancedPaymentsforIntangibleFixedAssets(): Code[20]
    begin
        exit('11400');
    end;

    internal procedure AdvancedPaymentsforIntangibleFixedAssetsName(): Text[100]
    begin
        exit(AdvancedPaymentsforIntangibleFixedAssetsTok);
    end;


    internal procedure TotalIntangibleFixedAssets(): Code[20]
    begin
        exit('11999');
    end;

    internal procedure TotalIntangibleFixedAssetsName(): Text[100]
    begin
        exit(TotalIntangibleFixedAssetsTok);
    end;


    internal procedure TangibleFixedAssets(): Code[20]
    begin
        exit('12000');
    end;

    internal procedure TangibleFixedAssetsName(): Text[100]
    begin
        exit(TangibleFixedAssetsTok);
    end;


    internal procedure LandandBuildings(): Code[20]
    begin
        exit('12100');
    end;

    internal procedure LandandBuildingsName(): Text[100]
    begin
        exit(LandandBuildingsTok);
    end;


    internal procedure Building(): Code[20]
    begin
        exit('12110');
    end;

    internal procedure BuildingName(): Text[100]
    begin
        exit(BuildingTok);
    end;


    internal procedure CostofImprovementstoLeasedProperty(): Code[20]
    begin
        exit('12120');
    end;

    internal procedure CostofImprovementstoLeasedPropertyName(): Text[100]
    begin
        exit(CostofImprovementstoLeasedPropertyTok);
    end;


    internal procedure Land(): Code[20]
    begin
        exit('12130');
    end;

    internal procedure LandName(): Text[100]
    begin
        exit(LandTok);
    end;


    internal procedure TotalLandandbuilding(): Code[20]
    begin
        exit('12199');
    end;

    internal procedure TotalLandandbuildingName(): Text[100]
    begin
        exit(TotalLandandbuildingTok);
    end;


    internal procedure MachineryandEquipment(): Code[20]
    begin
        exit('12200');
    end;

    internal procedure MachineryandEquipmentName(): Text[100]
    begin
        exit(MachineryandEquipmentTok);
    end;

    internal procedure EquipmentsandTools(): Code[20]
    begin
        exit('12210');
    end;

    internal procedure EquipmentsandToolsName(): Text[100]
    begin
        exit(EquipmentsandToolsTok);
    end;

    internal procedure Computers(): Code[20]
    begin
        exit('12220');
    end;

    internal procedure ComputersName(): Text[100]
    begin
        exit(ComputersTok);
    end;


    internal procedure CarsandotherTransportEquipments(): Code[20]
    begin
        exit('12230');
    end;

    internal procedure CarsandotherTransportEquipmentsName(): Text[100]
    begin
        exit(CarsandotherTransportEquipmentsTok);
    end;


    internal procedure LeasedAssets(): Code[20]
    begin
        exit('12240');
    end;

    internal procedure LeasedAssetsName(): Text[100]
    begin
        exit(LeasedAssetsTok);
    end;

    internal procedure TotalMachineryandEquipment(): Code[20]
    begin
        exit('12299');
    end;

    internal procedure TotalMachineryandEquipmentName(): Text[100]
    begin
        exit(TotalMachineryandEquipmentTok);
    end;


    internal procedure AccumulatedDepreciation(): Code[20]
    begin
        exit('12900');
    end;

    internal procedure AccumulatedDepreciationName(): Text[100]
    begin
        exit(AccumulatedDepreciationTok);
    end;


    internal procedure TotalTangibleAssets(): Code[20]
    begin
        exit('12999');
    end;

    internal procedure TotalTangibleAssetsName(): Text[100]
    begin
        exit(TotalTangibleAssetsTok);
    end;

    internal procedure FinancialandFixedAssets(): Code[20]
    begin
        exit('13000');
    end;

    internal procedure FinancialandFixedAssetsName(): Text[100]
    begin
        exit(FinancialandFixedAssetsTok);
    end;

    internal procedure Long_termReceivables(): Code[20]
    begin
        exit('13100');
    end;

    internal procedure Long_termReceivablesName(): Text[100]
    begin
        exit(Long_termReceivablesTok);
    end;

    internal procedure ParticipationinGroupCompanies(): Code[20]
    begin
        exit('13200');
    end;

    internal procedure ParticipationinGroupCompaniesName(): Text[100]
    begin
        exit(ParticipationinGroupCompaniesTok);
    end;


    internal procedure LoanstoPartnersorrelatedParties(): Code[20]
    begin
        exit('13300');
    end;

    internal procedure LoanstoPartnersorrelatedPartiesName(): Text[100]
    begin
        exit(LoanstoPartnersorrelatedPartiesTok);
    end;


    internal procedure DeferredTaxAssets(): Code[20]
    begin
        exit('13400');
    end;

    internal procedure DeferredTaxAssetsName(): Text[100]
    begin
        exit(DeferredTaxAssetsTok);
    end;


    internal procedure OtherLong_termReceivables(): Code[20]
    begin
        exit('13500');
    end;

    internal procedure OtherLong_termReceivablesName(): Text[100]
    begin
        exit(OtherLong_termReceivablesTok);
    end;


    internal procedure TotalFinancialandFixedAssets(): Code[20]
    begin
        exit('13999');
    end;

    internal procedure TotalFinancialandFixedAssetsName(): Text[100]
    begin
        exit(TotalFinancialandFixedAssetsTok);
    end;


    internal procedure InventoriesProductsandworkinProgress(): Code[20]
    begin
        exit('14000');
    end;

    internal procedure InventoriesProductsandworkinProgressName(): Text[100]
    begin
        exit(InventoriesProductsandworkinProgressTok);
    end;


    internal procedure RawMaterials(): Code[20]
    begin
        exit('14110');
    end;

    internal procedure RawMaterialsName(): Text[100]
    begin
        exit(RawMaterialsTok);
    end;


    internal procedure SuppliesandConsumables(): Code[20]
    begin
        exit('14100');
    end;

    internal procedure SuppliesandConsumablesName(): Text[100]
    begin
        exit(SuppliesandConsumablesTok);
    end;


    internal procedure ProductsinProgress(): Code[20]
    begin
        exit('14120');
    end;

    internal procedure ProductsinProgressName(): Text[100]
    begin
        exit(ProductsinProgressTok);
    end;


    internal procedure FinishedGoods(): Code[20]
    begin
        exit('14130');
    end;

    internal procedure FinishedGoodsName(): Text[100]
    begin
        exit(FinishedGoodsTok);
    end;


    internal procedure GoodsforResale(): Code[20]
    begin
        exit('14140');
    end;

    internal procedure GoodsforResaleName(): Text[100]
    begin
        exit(GoodsforResaleTok);
    end;

    internal procedure AdvancedPaymentsforgoodsandservices(): Code[20]
    begin
        exit('14160');
    end;

    internal procedure AdvancedPaymentsforgoodsandservicesName(): Text[100]
    begin
        exit(AdvancedPaymentsforgoodsandservicesTok);
    end;


    internal procedure OtherInventoryItems(): Code[20]
    begin
        exit('14170');
    end;

    internal procedure OtherInventoryItemsName(): Text[100]
    begin
        exit(OtherInventoryItemsTok);
    end;

    internal procedure WorkinProgress(): Code[20]
    begin
        exit('14200');
    end;

    internal procedure WorkinProgressName(): Text[100]
    begin
        exit(WorkinProgressTok);
    end;


    internal procedure WorkinProgressFinishedGoods(): Code[20]
    begin
        exit('14210');
    end;

    internal procedure WorkinProgressFinishedGoodsName(): Text[100]
    begin
        exit(WorkinProgressFinishedGoodsTok);
    end;


    internal procedure WIPJobSales(): Code[20]
    begin
        exit('14220');
    end;

    internal procedure WIPJobSalesName(): Text[100]
    begin
        exit(WIPJobSalesTok);
    end;


    internal procedure WIPJobCosts(): Code[20]
    begin
        exit('14230');
    end;

    internal procedure WIPJobCostsName(): Text[100]
    begin
        exit(WIPJobCostsTok);
    end;


    internal procedure WIPAccruedCosts(): Code[20]
    begin
        exit('14240');
    end;

    internal procedure WIPAccruedCostsName(): Text[100]
    begin
        exit(WIPAccruedCostsTok);
    end;


    internal procedure WIPInvoicedSales(): Code[20]
    begin
        exit('14250');
    end;

    internal procedure WIPInvoicedSalesName(): Text[100]
    begin
        exit(WIPInvoicedSalesTok);
    end;


    internal procedure TotalWorkinProgress(): Code[20]
    begin
        exit('14299');
    end;

    internal procedure TotalWorkinProgressName(): Text[100]
    begin
        exit(TotalWorkinProgressTok);
    end;

    internal procedure Receivables(): Code[20]
    begin
        exit('15000');
    end;

    internal procedure ReceivablesName(): Text[100]
    begin
        exit(ReceivablesTok);
    end;


    internal procedure AccountsReceivables(): Code[20]
    begin
        exit('15100');
    end;

    internal procedure AccountsReceivablesName(): Text[100]
    begin
        exit(AccountsReceivablesTok);
    end;


    internal procedure AccountReceivableDomestic(): Code[20]
    begin
        exit('15110');
    end;

    internal procedure AccountReceivableDomesticName(): Text[100]
    begin
        exit(AccountReceivableDomesticTok);
    end;


    internal procedure AccountReceivableForeign(): Code[20]
    begin
        exit('15120');
    end;

    internal procedure AccountReceivableForeignName(): Text[100]
    begin
        exit(AccountReceivableForeignTok);
    end;


    internal procedure ContractualReceivables(): Code[20]
    begin
        exit('15130');
    end;

    internal procedure ContractualReceivablesName(): Text[100]
    begin
        exit(ContractualReceivablesTok);
    end;

    internal procedure ConsignmentReceivables(): Code[20]
    begin
        exit('15140');
    end;

    internal procedure ConsignmentReceivablesName(): Text[100]
    begin
        exit(ConsignmentReceivablesTok);
    end;


    internal procedure CreditcardsandVouchersReceivables(): Code[20]
    begin
        exit('15150');
    end;

    internal procedure CreditcardsandVouchersReceivablesName(): Text[100]
    begin
        exit(CreditcardsandVouchersReceivablesTok);
    end;


    internal procedure TotalAccountReceivables(): Code[20]
    begin
        exit('15199');
    end;

    internal procedure TotalAccountReceivablesName(): Text[100]
    begin
        exit(TotalAccountReceivablesTok);
    end;

    internal procedure OtherCurrentReceivables(): Code[20]
    begin
        exit('15900');
    end;

    internal procedure OtherCurrentReceivablesName(): Text[100]
    begin
        exit(OtherCurrentReceivablesTok);
    end;


    internal procedure CurrentReceivablefromEmployees(): Code[20]
    begin
        exit('15910');
    end;

    internal procedure CurrentReceivablefromEmployeesName(): Text[100]
    begin
        exit(CurrentReceivablefromEmployeesTok);
    end;


    internal procedure Accruedincomenotyetinvoiced(): Code[20]
    begin
        exit('15920');
    end;

    internal procedure AccruedincomenotyetinvoicedName(): Text[100]
    begin
        exit(AccruedincomenotyetinvoicedTok);
    end;


    internal procedure ClearingAccountsforTaxesandcharges(): Code[20]
    begin
        exit('15930');
    end;

    internal procedure ClearingAccountsforTaxesandchargesName(): Text[100]
    begin
        exit(ClearingAccountsforTaxesandchargesTok);
    end;


    internal procedure TaxAssets(): Code[20]
    begin
        exit('15940');
    end;

    internal procedure TaxAssetsName(): Text[100]
    begin
        exit(TaxAssetsTok);
    end;


    internal procedure CurrentReceivablesfromgroupcompanies(): Code[20]
    begin
        exit('15950');
    end;

    internal procedure CurrentReceivablesfromgroupcompaniesName(): Text[100]
    begin
        exit(CurrentReceivablesfromgroupcompaniesTok);
    end;


    internal procedure TotalOtherCurrentReceivables(): Code[20]
    begin
        exit('15998');
    end;

    internal procedure TotalOtherCurrentReceivablesName(): Text[100]
    begin
        exit(TotalOtherCurrentReceivablesTok);
    end;


    internal procedure TotalReceivables(): Code[20]
    begin
        exit('15999');
    end;

    internal procedure TotalReceivablesName(): Text[100]
    begin
        exit(TotalReceivablesTok);
    end;


    internal procedure PrepaidexpensesandAccruedIncome(): Code[20]
    begin
        exit('16000');
    end;

    internal procedure PrepaidexpensesandAccruedIncomeName(): Text[100]
    begin
        exit(PrepaidexpensesandAccruedIncomeTok);
    end;


    internal procedure PrepaidRent(): Code[20]
    begin
        exit('16100');
    end;

    internal procedure PrepaidRentName(): Text[100]
    begin
        exit(PrepaidRentTok);
    end;


    internal procedure PrepaidInterestexpense(): Code[20]
    begin
        exit('16200');
    end;

    internal procedure PrepaidInterestexpenseName(): Text[100]
    begin
        exit(PrepaidInterestexpenseTok);
    end;


    internal procedure AccruedRentalIncome(): Code[20]
    begin
        exit('16300');
    end;

    internal procedure AccruedRentalIncomeName(): Text[100]
    begin
        exit(AccruedRentalIncomeTok);
    end;


    internal procedure AccruedInterestIncome(): Code[20]
    begin
        exit('16400');
    end;

    internal procedure AccruedInterestIncomeName(): Text[100]
    begin
        exit(AccruedInterestIncomeTok);
    end;


    internal procedure Assetsintheformofprepaidexpenses(): Code[20]
    begin
        exit('16500');
    end;

    internal procedure AssetsintheformofprepaidexpensesName(): Text[100]
    begin
        exit(AssetsintheformofprepaidexpensesTok);
    end;


    internal procedure Otherprepaidexpensesandaccruedincome(): Code[20]
    begin
        exit('16600');
    end;

    internal procedure OtherprepaidexpensesandaccruedincomeName(): Text[100]
    begin
        exit(OtherprepaidexpensesandaccruedincomeTok);
    end;


    internal procedure TotalPrepaidexpensesandAccruedIncome(): Code[20]
    begin
        exit('16999');
    end;

    internal procedure TotalPrepaidexpensesandAccruedIncomeName(): Text[100]
    begin
        exit(TotalPrepaidexpensesandAccruedIncomeTok);
    end;


    internal procedure Short_terminvestments(): Code[20]
    begin
        exit('17000');
    end;

    internal procedure Short_terminvestmentsName(): Text[100]
    begin
        exit(Short_terminvestmentsTok);
    end;


    internal procedure Bonds(): Code[20]
    begin
        exit('17100');
    end;

    internal procedure BondsName(): Text[100]
    begin
        exit(BondsTok);
    end;


    internal procedure Convertibledebtinstruments(): Code[20]
    begin
        exit('17200');
    end;

    internal procedure ConvertibledebtinstrumentsName(): Text[100]
    begin
        exit(ConvertibledebtinstrumentsTok);
    end;


    internal procedure Othershort_termInvestments(): Code[20]
    begin
        exit('17300');
    end;

    internal procedure Othershort_termInvestmentsName(): Text[100]
    begin
        exit(Othershort_termInvestmentsTok);
    end;


    internal procedure Write_downofShort_terminvestments(): Code[20]
    begin
        exit('17400');
    end;

    internal procedure Write_downofShort_terminvestmentsName(): Text[100]
    begin
        exit(Write_downofShort_terminvestmentsTok);
    end;


    internal procedure Totalshortterminvestments(): Code[20]
    begin
        exit('17999');
    end;

    internal procedure TotalshortterminvestmentsName(): Text[100]
    begin
        exit(TotalshortterminvestmentsTok);
    end;


    internal procedure CashandBank(): Code[20]
    begin
        exit('18000');
    end;

    internal procedure CashandBankName(): Text[100]
    begin
        exit(CashandBankTok);
    end;


    internal procedure PettyCash(): Code[20]
    begin
        exit('18100');
    end;

    internal procedure PettyCashName(): Text[100]
    begin
        exit(PettyCashTok);
    end;


    internal procedure BusinessaccountOperatingDomestic(): Code[20]
    begin
        exit('18200');
    end;

    internal procedure BusinessaccountOperatingDomesticName(): Text[100]
    begin
        exit(BusinessaccountOperatingDomesticTok);
    end;


    internal procedure BusinessaccountOperatingForeign(): Code[20]
    begin
        exit('18300');
    end;

    internal procedure BusinessaccountOperatingForeignName(): Text[100]
    begin
        exit(BusinessaccountOperatingForeignTok);
    end;


    internal procedure Otherbankaccounts(): Code[20]
    begin
        exit('18400');
    end;

    internal procedure OtherbankaccountsName(): Text[100]
    begin
        exit(OtherbankaccountsTok);
    end;


    internal procedure CertificateofDeposit(): Code[20]
    begin
        exit('18500');
    end;

    internal procedure CertificateofDepositName(): Text[100]
    begin
        exit(CertificateofDepositTok);
    end;


    internal procedure TotalCashandBank(): Code[20]
    begin
        exit('18999');
    end;

    internal procedure TotalCashandBankName(): Text[100]
    begin
        exit(TotalCashandBankTok);
    end;


    internal procedure TotalAssets(): Code[20]
    begin
        exit('19999');
    end;

    internal procedure TotalAssetsName(): Text[100]
    begin
        exit(TotalAssetsTok);
    end;


    internal procedure Liability(): Code[20]
    begin
        exit('20000');
    end;

    internal procedure LiabilityName(): Text[100]
    begin
        exit(LiabilityTok);
    end;


    internal procedure Long_TermLiabilities(): Code[20]
    begin
        exit('21000');
    end;

    internal procedure Long_TermLiabilitiesName(): Text[100]
    begin
        exit(Long_TermLiabilitiesTok);
    end;


    internal procedure BondsandDebentureLoans(): Code[20]
    begin
        exit('21100');
    end;

    internal procedure BondsandDebentureLoansName(): Text[100]
    begin
        exit(BondsandDebentureLoansTok);
    end;


    internal procedure ConvertiblesLoans(): Code[20]
    begin
        exit('21200');
    end;

    internal procedure ConvertiblesLoansName(): Text[100]
    begin
        exit(ConvertiblesLoansTok);
    end;


    internal procedure OtherLong_termLiabilities(): Code[20]
    begin
        exit('21300');
    end;

    internal procedure OtherLong_termLiabilitiesName(): Text[100]
    begin
        exit(OtherLong_termLiabilitiesTok);
    end;


    internal procedure BankoverdraftFacilities(): Code[20]
    begin
        exit('21400');
    end;

    internal procedure BankoverdraftFacilitiesName(): Text[100]
    begin
        exit(BankoverdraftFacilitiesTok);
    end;


    internal procedure TotalLong_termLiabilities(): Code[20]
    begin
        exit('21999');
    end;

    internal procedure TotalLong_termLiabilitiesName(): Text[100]
    begin
        exit(TotalLong_termLiabilitiesTok);
    end;


    internal procedure CurrentLiabilities(): Code[20]
    begin
        exit('22000');
    end;

    internal procedure CurrentLiabilitiesName(): Text[100]
    begin
        exit(CurrentLiabilitiesTok);
    end;


    internal procedure AccountsPayableDomestic(): Code[20]
    begin
        exit('22100');
    end;

    internal procedure AccountsPayableDomesticName(): Text[100]
    begin
        exit(AccountsPayableDomesticTok);
    end;


    internal procedure AccountsPayableForeign(): Code[20]
    begin
        exit('22200');
    end;

    internal procedure AccountsPayableForeignName(): Text[100]
    begin
        exit(AccountsPayableForeignTok);
    end;


    internal procedure Advancesfromcustomers(): Code[20]
    begin
        exit('22300');
    end;

    internal procedure AdvancesfromcustomersName(): Text[100]
    begin
        exit(AdvancesfromcustomersTok);
    end;


    internal procedure ChangeinWorkinProgress(): Code[20]
    begin
        exit('22400');
    end;

    internal procedure ChangeinWorkinProgressName(): Text[100]
    begin
        exit(ChangeinWorkinProgressTok);
    end;


    internal procedure Bankoverdraftshort_term(): Code[20]
    begin
        exit('22500');
    end;

    internal procedure Bankoverdraftshort_termName(): Text[100]
    begin
        exit(Bankoverdraftshort_termTok);
    end;


    internal procedure OtherLiabilities(): Code[20]
    begin
        exit('22600');
    end;

    internal procedure OtherLiabilitiesName(): Text[100]
    begin
        exit(OtherLiabilitiesTok);
    end;


    internal procedure TotalCurrentLiabilities(): Code[20]
    begin
        exit('22999');
    end;

    internal procedure TotalCurrentLiabilitiesName(): Text[100]
    begin
        exit(TotalCurrentLiabilitiesTok);
    end;


    internal procedure TaxLiabilities(): Code[20]
    begin
        exit('23000');
    end;

    internal procedure TaxLiabilitiesName(): Text[100]
    begin
        exit(TaxLiabilitiesTok);
    end;


    internal procedure SalesTax_VATLiable(): Code[20]
    begin
        exit('23100');
    end;

    internal procedure SalesTax_VATLiableName(): Text[100]
    begin
        exit(SalesTaxLiableTok);
    end;


    internal procedure TaxesLiable(): Code[20]
    begin
        exit('23200');
    end;

    internal procedure TaxesLiableName(): Text[100]
    begin
        exit(TaxesLiableTok);
    end;

    internal procedure EstimatedIncomeTax(): Code[20]
    begin
        exit('23300');
    end;

    internal procedure EstimatedIncomeTaxName(): Text[100]
    begin
        exit(EstimatedIncomeTaxTok);
    end;

    internal procedure EstimatedPayrolltaxonPensionCosts(): Code[20]
    begin
        exit('23500');
    end;

    internal procedure EstimatedPayrolltaxonPensionCostsName(): Text[100]
    begin
        exit(EstimatedPayrolltaxonPensionCostsTok);
    end;

    internal procedure TotalTaxLiabilities(): Code[20]
    begin
        exit('23999');
    end;

    internal procedure TotalTaxLiabilitiesName(): Text[100]
    begin
        exit(TotalTaxLiabilitiesTok);
    end;

    internal procedure PayrollLiabilities(): Code[20]
    begin
        exit('24000');
    end;

    internal procedure PayrollLiabilitiesName(): Text[100]
    begin
        exit(PayrollLiabilitiesTok);
    end;


    internal procedure EmployeesWithholdingTaxes(): Code[20]
    begin
        exit('24100');
    end;

    internal procedure EmployeesWithholdingTaxesName(): Text[100]
    begin
        exit(EmployeesWithholdingTaxesTok);
    end;


    internal procedure StatutorySocialsecurityContributions(): Code[20]
    begin
        exit('24200');
    end;

    internal procedure StatutorySocialsecurityContributionsName(): Text[100]
    begin
        exit(StatutorySocialsecurityContributionsTok);
    end;


    internal procedure ContractualSocialsecurityContributions(): Code[20]
    begin
        exit('24300');
    end;

    internal procedure ContractualSocialsecurityContributionsName(): Text[100]
    begin
        exit(ContractualSocialsecurityContributionsTok);
    end;


    internal procedure AttachmentsofEarning(): Code[20]
    begin
        exit('24400');
    end;

    internal procedure AttachmentsofEarningName(): Text[100]
    begin
        exit(AttachmentsofEarningTok);
    end;


    internal procedure HolidayPayfund(): Code[20]
    begin
        exit('24500');
    end;

    internal procedure HolidayPayfundName(): Text[100]
    begin
        exit(HolidayPayfundTok);
    end;


    internal procedure OtherSalary_wageDeductions(): Code[20]
    begin
        exit('24600');
    end;

    internal procedure OtherSalary_wageDeductionsName(): Text[100]
    begin
        exit(OtherSalary_wageDeductionsTok);
    end;


    internal procedure TotalPayrollLiabilities(): Code[20]
    begin
        exit('24999');
    end;

    internal procedure TotalPayrollLiabilitiesName(): Text[100]
    begin
        exit(TotalPayrollLiabilitiesTok);
    end;


    internal procedure OtherCurrentLiabilities(): Code[20]
    begin
        exit('25000');
    end;

    internal procedure OtherCurrentLiabilitiesName(): Text[100]
    begin
        exit(OtherCurrentLiabilitiesTok);
    end;


    internal procedure ClearingAccountforFactoringCurrentPortion(): Code[20]
    begin
        exit('25100');
    end;

    internal procedure ClearingAccountforFactoringCurrentPortionName(): Text[100]
    begin
        exit(ClearingAccountforFactoringCurrentPortionTok);
    end;


    internal procedure CurrentLiabilitiestoEmployees(): Code[20]
    begin
        exit('25200');
    end;

    internal procedure CurrentLiabilitiestoEmployeesName(): Text[100]
    begin
        exit(CurrentLiabilitiestoEmployeesTok);
    end;


    internal procedure ClearingAccountforthirdparty(): Code[20]
    begin
        exit('25300');
    end;

    internal procedure ClearingAccountforthirdpartyName(): Text[100]
    begin
        exit(ClearingAccountforthirdpartyTok);
    end;


    internal procedure CurrentLoans(): Code[20]
    begin
        exit('25400');
    end;

    internal procedure CurrentLoansName(): Text[100]
    begin
        exit(CurrentLoansTok);
    end;


    internal procedure LiabilitiesGrantsReceived(): Code[20]
    begin
        exit('25500');
    end;

    internal procedure LiabilitiesGrantsReceivedName(): Text[100]
    begin
        exit(LiabilitiesGrantsReceivedTok);
    end;


    internal procedure TotalOtherCurrentLiabilities(): Code[20]
    begin
        exit('25999');
    end;

    internal procedure TotalOtherCurrentLiabilitiesName(): Text[100]
    begin
        exit(TotalOtherCurrentLiabilitiesTok);
    end;


    internal procedure AccruedExpensesandDeferredIncome(): Code[20]
    begin
        exit('26000');
    end;

    internal procedure AccruedExpensesandDeferredIncomeName(): Text[100]
    begin
        exit(AccruedExpensesandDeferredIncomeTok);
    end;


    internal procedure Accruedwages_salaries(): Code[20]
    begin
        exit('26100');
    end;

    internal procedure Accruedwages_salariesName(): Text[100]
    begin
        exit(Accruedwages_salariesTok);
    end;


    internal procedure AccruedHolidaypay(): Code[20]
    begin
        exit('26200');
    end;

    internal procedure AccruedHolidaypayName(): Text[100]
    begin
        exit(AccruedHolidaypayTok);
    end;


    internal procedure AccruedPensioncosts(): Code[20]
    begin
        exit('26300');
    end;

    internal procedure AccruedPensioncostsName(): Text[100]
    begin
        exit(AccruedPensioncostsTok);
    end;


    internal procedure AccruedInterestExpense(): Code[20]
    begin
        exit('26400');
    end;

    internal procedure AccruedInterestExpenseName(): Text[100]
    begin
        exit(AccruedInterestExpenseTok);
    end;


    internal procedure DeferredIncome(): Code[20]
    begin
        exit('26500');
    end;

    internal procedure DeferredIncomeName(): Text[100]
    begin
        exit(DeferredIncomeTok);
    end;


    internal procedure AccruedContractualcosts(): Code[20]
    begin
        exit('26600');
    end;

    internal procedure AccruedContractualcostsName(): Text[100]
    begin
        exit(AccruedContractualcostsTok);
    end;


    internal procedure OtherAccruedExpensesandDeferredIncome(): Code[20]
    begin
        exit('26700');
    end;

    internal procedure OtherAccruedExpensesandDeferredIncomeName(): Text[100]
    begin
        exit(OtherAccruedExpensesandDeferredIncomeTok);
    end;


    internal procedure TotalAccruedExpensesandDeferredIncome(): Code[20]
    begin
        exit('26999');
    end;

    internal procedure TotalAccruedExpensesandDeferredIncomeName(): Text[100]
    begin
        exit(TotalAccruedExpensesandDeferredIncomeTok);
    end;


    internal procedure TotalLiabilities(): Code[20]
    begin
        exit('29999');
    end;

    internal procedure TotalLiabilitiesName(): Text[100]
    begin
        exit(TotalLiabilitiesTok);
    end;


    internal procedure Equity(): Code[20]
    begin
        exit('30000');
    end;

    internal procedure EquityName(): Text[100]
    begin
        exit(EquityTok);
    end;


    internal procedure EquityPartner(): Code[20]
    begin
        exit('30100');
    end;

    internal procedure EquityPartnerName(): Text[100]
    begin
        exit(EquityPartnerTok);
    end;


    internal procedure NetResults(): Code[20]
    begin
        exit('30110');
    end;

    internal procedure NetResultsName(): Text[100]
    begin
        exit(NetResultsTok);
    end;


    internal procedure RestrictedEquity(): Code[20]
    begin
        exit('30111');
    end;

    internal procedure RestrictedEquityName(): Text[100]
    begin
        exit(RestrictedEquityTok);
    end;


    internal procedure ShareCapital(): Code[20]
    begin
        exit('30200');
    end;

    internal procedure ShareCapitalName(): Text[100]
    begin
        exit(ShareCapitalTok);
    end;


    internal procedure Non_RestrictedEquity(): Code[20]
    begin
        exit('30210');
    end;

    internal procedure Non_RestrictedEquityName(): Text[100]
    begin
        exit(Non_RestrictedEquityTok);
    end;


    internal procedure Profitorlossfromthepreviousyear(): Code[20]
    begin
        exit('30300');
    end;

    internal procedure ProfitorlossfromthepreviousyearName(): Text[100]
    begin
        exit(ProfitorlossfromthepreviousyearTok);
    end;


    internal procedure ResultsfortheFinancialyear(): Code[20]
    begin
        exit('30310');
    end;

    internal procedure ResultsfortheFinancialyearName(): Text[100]
    begin
        exit(ResultsfortheFinancialyearTok);
    end;


    internal procedure DistributionstoShareholders(): Code[20]
    begin
        exit('30320');
    end;

    internal procedure DistributionstoShareholdersName(): Text[100]
    begin
        exit(DistributionstoShareholdersTok);
    end;


    internal procedure TotalEquity(): Code[20]
    begin
        exit('39999');
    end;

    internal procedure TotalEquityName(): Text[100]
    begin
        exit(TotalEquityTok);
    end;


    internal procedure INCOMESTATEMENT(): Code[20]
    begin
        exit('40000');
    end;

    internal procedure INCOMESTATEMENTName(): Text[100]
    begin
        exit(INCOMESTATEMENTTok);
    end;


    internal procedure Income(): Code[20]
    begin
        exit('40001');
    end;

    internal procedure IncomeName(): Text[100]
    begin
        exit(IncomeTok);
    end;


    internal procedure SalesofGoods(): Code[20]
    begin
        exit('40100');
    end;

    internal procedure SalesofGoodsName(): Text[100]
    begin
        exit(SalesofGoodsTok);
    end;


    internal procedure SaleofFinishedGoods(): Code[20]
    begin
        exit('40130');
    end;

    internal procedure SaleofFinishedGoodsName(): Text[100]
    begin
        exit(SaleofFinishedGoodsTok);
    end;


    internal procedure SaleofRawMaterials(): Code[20]
    begin
        exit('40110');
    end;

    internal procedure SaleofRawMaterialsName(): Text[100]
    begin
        exit(SaleofRawMaterialsTok);
    end;


    internal procedure ResaleofGoods(): Code[20]
    begin
        exit('40140');
    end;

    internal procedure ResaleofGoodsName(): Text[100]
    begin
        exit(ResaleofGoodsTok);
    end;

    internal procedure TotalSalesofGoods(): Code[20]
    begin
        exit('40199');
    end;

    internal procedure TotalSalesofGoodsName(): Text[100]
    begin
        exit(TotalSalesofGoodsTok);
    end;


    internal procedure SalesofResources(): Code[20]
    begin
        exit('40200');
    end;

    internal procedure SalesofResourcesName(): Text[100]
    begin
        exit(SalesofResourcesTok);
    end;


    internal procedure SaleofResources(): Code[20]
    begin
        exit('40210');
    end;

    internal procedure SaleofResourcesName(): Text[100]
    begin
        exit(SaleofResourcesTok);
    end;


    internal procedure SaleofSubcontracting(): Code[20]
    begin
        exit('40220');
    end;

    internal procedure SaleofSubcontractingName(): Text[100]
    begin
        exit(SaleofSubcontractingTok);
    end;


    internal procedure TotalSalesofResources(): Code[20]
    begin
        exit('40299');
    end;

    internal procedure TotalSalesofResourcesName(): Text[100]
    begin
        exit(TotalSalesofResourcesTok);
    end;


    internal procedure AdditionalRevenue(): Code[20]
    begin
        exit('40300');
    end;

    internal procedure AdditionalRevenueName(): Text[100]
    begin
        exit(AdditionalRevenueTok);
    end;


    internal procedure Incomefromsecurities(): Code[20]
    begin
        exit('40310');
    end;

    internal procedure IncomefromsecuritiesName(): Text[100]
    begin
        exit(IncomefromsecuritiesTok);
    end;


    internal procedure ManagementFeeRevenue(): Code[20]
    begin
        exit('40320');
    end;

    internal procedure ManagementFeeRevenueName(): Text[100]
    begin
        exit(ManagementFeeRevenueTok);
    end;


    internal procedure InterestIncome(): Code[20]
    begin
        exit('40330');
    end;

    internal procedure InterestIncomeName(): Text[100]
    begin
        exit(InterestIncomeTok);
    end;


    internal procedure CurrencyGains(): Code[20]
    begin
        exit('40380');
    end;

    internal procedure CurrencyGainsName(): Text[100]
    begin
        exit(CurrencyGainsTok);
    end;


    internal procedure OtherIncidentalRevenue(): Code[20]
    begin
        exit('40390');
    end;

    internal procedure OtherIncidentalRevenueName(): Text[100]
    begin
        exit(OtherIncidentalRevenueTok);
    end;


    internal procedure TotalAdditionalRevenue(): Code[20]
    begin
        exit('40399');
    end;

    internal procedure TotalAdditionalRevenueName(): Text[100]
    begin
        exit(TotalAdditionalRevenueTok);
    end;


    internal procedure JobsandServices(): Code[20]
    begin
        exit('40400');
    end;

    internal procedure JobsandServicesName(): Text[100]
    begin
        exit(JobsandServicesTok);
    end;


    internal procedure JobSales(): Code[20]
    begin
        exit('40410');
    end;

    internal procedure JobSalesName(): Text[100]
    begin
        exit(JobSalesTok);
    end;


    internal procedure JobSalesApplied(): Code[20]
    begin
        exit('40420');
    end;

    internal procedure JobSalesAppliedName(): Text[100]
    begin
        exit(JobSalesAppliedTok);
    end;


    internal procedure SalesofServiceContracts(): Code[20]
    begin
        exit('40430');
    end;

    internal procedure SalesofServiceContractsName(): Text[100]
    begin
        exit(SalesofServiceContractsTok);
    end;


    internal procedure SalesofServiceWork(): Code[20]
    begin
        exit('40440');
    end;

    internal procedure SalesofServiceWorkName(): Text[100]
    begin
        exit(SalesofServiceWorkTok);
    end;


    internal procedure TotalJobsandServices(): Code[20]
    begin
        exit('40499');
    end;

    internal procedure TotalJobsandServicesName(): Text[100]
    begin
        exit(TotalJobsandServicesTok);
    end;


    internal procedure RevenueReductions(): Code[20]
    begin
        exit('40900');
    end;

    internal procedure RevenueReductionsName(): Text[100]
    begin
        exit(RevenueReductionsTok);
    end;


    internal procedure SalesDiscounts(): Code[20]
    begin
        exit('40910');
    end;

    internal procedure SalesDiscountsName(): Text[100]
    begin
        exit(DiscountsandAllowancesTok);
    end;


    internal procedure SalesInvoiceRounding(): Code[20]
    begin
        exit('40920');
    end;

    internal procedure SalesInvoiceRoundingName(): Text[100]
    begin
        exit(InvoiceRoundingTok);
    end;


    internal procedure PaymentToleranceandAllowances(): Code[20]
    begin
        exit('40930');
    end;

    internal procedure PaymentToleranceandAllowancesName(): Text[100]
    begin
        exit(PaymentToleranceTok);
    end;


    internal procedure SalesReturns(): Code[20]
    begin
        exit('40940');
    end;

    internal procedure SalesReturnsName(): Text[100]
    begin
        exit(SalesReturnsTok);
    end;


    internal procedure TotalRevenueReductions(): Code[20]
    begin
        exit('40999');
    end;

    internal procedure TotalRevenueReductionsName(): Text[100]
    begin
        exit(TotalRevenueReductionsTok);
    end;


    internal procedure TOTALINCOME(): Code[20]
    begin
        exit('49990');
    end;

    internal procedure TOTALINCOMEName(): Text[100]
    begin
        exit(TOTALINCOMETok);
    end;


    internal procedure COSTOFGOODSSOLD(): Code[20]
    begin
        exit('50001');
    end;

    internal procedure COSTOFGOODSSOLDName(): Text[100]
    begin
        exit(COSTOFGOODSSOLDTok);
    end;


    internal procedure CostofGoods(): Code[20]
    begin
        exit('50100');
    end;

    internal procedure CostofGoodsName(): Text[100]
    begin
        exit(CostofGoodsTok);
    end;


    internal procedure CostofMaterials(): Code[20]
    begin
        exit('50110');
    end;

    internal procedure CostofMaterialsName(): Text[100]
    begin
        exit(CostofMaterialsTok);
    end;


    internal procedure CostofMaterialsProjects(): Code[20]
    begin
        exit('50120');
    end;

    internal procedure CostofMaterialsProjectsName(): Text[100]
    begin
        exit(CostofMaterialsProjectsTok);
    end;


    internal procedure TotalCostofGoods(): Code[20]
    begin
        exit('50199');
    end;

    internal procedure TotalCostofGoodsName(): Text[100]
    begin
        exit(TotalCostofGoodsTok);
    end;


    internal procedure CostofResourcesandServices(): Code[20]
    begin
        exit('50200');
    end;

    internal procedure CostofResourcesandServicesName(): Text[100]
    begin
        exit(CostofResourcesandServicesTok);
    end;


    internal procedure CostofLabor(): Code[20]
    begin
        exit('50210');
    end;

    internal procedure CostofLaborName(): Text[100]
    begin
        exit(CostofLaborTok);
    end;


    internal procedure CostofLaborProjects(): Code[20]
    begin
        exit('50220');
    end;

    internal procedure CostofLaborProjectsName(): Text[100]
    begin
        exit(CostofLaborProjectsTok);
    end;


    internal procedure CostofLaborWarranty_Contract(): Code[20]
    begin
        exit('50230');
    end;

    internal procedure CostofLaborWarranty_ContractName(): Text[100]
    begin
        exit(CostofLaborWarranty_ContractTok);
    end;


    internal procedure TotalCostofResources(): Code[20]
    begin
        exit('50299');
    end;

    internal procedure TotalCostofResourcesName(): Text[100]
    begin
        exit(TotalCostofResourcesTok);
    end;


    internal procedure Subcontractedwork(): Code[20]
    begin
        exit('50400');
    end;

    internal procedure SubcontractedworkName(): Text[100]
    begin
        exit(SubcontractedworkTok);
    end;


    internal procedure CostofVariances(): Code[20]
    begin
        exit('50500');
    end;

    internal procedure CostofVariancesName(): Text[100]
    begin
        exit(CostofVariancesTok);
    end;


    internal procedure TOTALCOSTOFGOODSSOLD(): Code[20]
    begin
        exit('59990');
    end;

    internal procedure TOTALCOSTOFGOODSSOLDName(): Text[100]
    begin
        exit(TOTALCOSTOFGOODSSOLDTok);
    end;


    internal procedure EXPENSES(): Code[20]
    begin
        exit('60001');
    end;

    internal procedure EXPENSESName(): Text[100]
    begin
        exit(EXPENSESTok);
    end;


    internal procedure FacilityExpenses(): Code[20]
    begin
        exit('60002');
    end;

    internal procedure FacilityExpensesName(): Text[100]
    begin
        exit(FacilityExpensesTok);
    end;


    internal procedure RentalFacilities(): Code[20]
    begin
        exit('60100');
    end;

    internal procedure RentalFacilitiesName(): Text[100]
    begin
        exit(RentalFacilitiesTok);
    end;


    internal procedure Rent_Leases(): Code[20]
    begin
        exit('60110');
    end;

    internal procedure Rent_LeasesName(): Text[100]
    begin
        exit(Rent_LeasesTok);
    end;


    internal procedure ElectricityforRental(): Code[20]
    begin
        exit('60120');
    end;

    internal procedure ElectricityforRentalName(): Text[100]
    begin
        exit(ElectricityforRentalTok);
    end;


    internal procedure HeatingforRental(): Code[20]
    begin
        exit('60130');
    end;

    internal procedure HeatingforRentalName(): Text[100]
    begin
        exit(HeatingforRentalTok);
    end;


    internal procedure WaterandSewerageforRental(): Code[20]
    begin
        exit('60140');
    end;

    internal procedure WaterandSewerageforRentalName(): Text[100]
    begin
        exit(WaterandSewerageforRentalTok);
    end;


    internal procedure CleaningandWasteforRental(): Code[20]
    begin
        exit('60150');
    end;

    internal procedure CleaningandWasteforRentalName(): Text[100]
    begin
        exit(CleaningandWasteforRentalTok);
    end;


    internal procedure RepairsandMaintenanceforRental(): Code[20]
    begin
        exit('60160');
    end;

    internal procedure RepairsandMaintenanceforRentalName(): Text[100]
    begin
        exit(RepairsandMaintenanceforRentalTok);
    end;


    internal procedure InsurancesRental(): Code[20]
    begin
        exit('60170');
    end;

    internal procedure InsurancesRentalName(): Text[100]
    begin
        exit(InsurancesRentalTok);
    end;


    internal procedure OtherRentalExpenses(): Code[20]
    begin
        exit('60190');
    end;

    internal procedure OtherRentalExpensesName(): Text[100]
    begin
        exit(OtherRentalExpensesTok);
    end;


    internal procedure TotalRentalFacilities(): Code[20]
    begin
        exit('60199');
    end;

    internal procedure TotalRentalFacilitiesName(): Text[100]
    begin
        exit(TotalRentalFacilitiesTok);
    end;


    internal procedure PropertyExpenses(): Code[20]
    begin
        exit('60200');
    end;

    internal procedure PropertyExpensesName(): Text[100]
    begin
        exit(PropertyExpensesTok);
    end;


    internal procedure SiteFees_Leases(): Code[20]
    begin
        exit('60210');
    end;

    internal procedure SiteFees_LeasesName(): Text[100]
    begin
        exit(SiteFees_LeasesTok);
    end;


    internal procedure ElectricityforProperty(): Code[20]
    begin
        exit('60220');
    end;

    internal procedure ElectricityforPropertyName(): Text[100]
    begin
        exit(ElectricityforPropertyTok);
    end;


    internal procedure HeatingforProperty(): Code[20]
    begin
        exit('60230');
    end;

    internal procedure HeatingforPropertyName(): Text[100]
    begin
        exit(HeatingforPropertyTok);
    end;


    internal procedure WaterandSewerageforProperty(): Code[20]
    begin
        exit('60240');
    end;

    internal procedure WaterandSewerageforPropertyName(): Text[100]
    begin
        exit(WaterandSewerageforPropertyTok);
    end;


    internal procedure CleaningandWasteforProperty(): Code[20]
    begin
        exit('60250');
    end;

    internal procedure CleaningandWasteforPropertyName(): Text[100]
    begin
        exit(CleaningandWasteforPropertyTok);
    end;


    internal procedure RepairsandMaintenanceforProperty(): Code[20]
    begin
        exit('60260');
    end;

    internal procedure RepairsandMaintenanceforPropertyName(): Text[100]
    begin
        exit(RepairsandMaintenanceforPropertyTok);
    end;


    internal procedure InsurancesProperty(): Code[20]
    begin
        exit('60270');
    end;

    internal procedure InsurancesPropertyName(): Text[100]
    begin
        exit(InsurancesPropertyTok);
    end;


    internal procedure OtherPropertyExpenses(): Code[20]
    begin
        exit('60290');
    end;

    internal procedure OtherPropertyExpensesName(): Text[100]
    begin
        exit(OtherPropertyExpensesTok);
    end;


    internal procedure TotalPropertyExpenses(): Code[20]
    begin
        exit('60299');
    end;

    internal procedure TotalPropertyExpensesName(): Text[100]
    begin
        exit(TotalPropertyExpensesTok);
    end;


    internal procedure TotalFacilityExpenses(): Code[20]
    begin
        exit('60999');
    end;

    internal procedure TotalFacilityExpensesName(): Text[100]
    begin
        exit(TotalFacilityExpensesTok);
    end;


    internal procedure FixedAssetsLeases(): Code[20]
    begin
        exit('61000');
    end;

    internal procedure FixedAssetsLeasesName(): Text[100]
    begin
        exit(FixedAssetsLeasesTok);
    end;


    internal procedure Hireofmachinery(): Code[20]
    begin
        exit('61100');
    end;

    internal procedure HireofmachineryName(): Text[100]
    begin
        exit(HireofmachineryTok);
    end;


    internal procedure Hireofcomputers(): Code[20]
    begin
        exit('61200');
    end;

    internal procedure HireofcomputersName(): Text[100]
    begin
        exit(HireofcomputersTok);
    end;


    internal procedure Hireofotherfixedassets(): Code[20]
    begin
        exit('61300');
    end;

    internal procedure HireofotherfixedassetsName(): Text[100]
    begin
        exit(HireofotherfixedassetsTok);
    end;


    internal procedure TotalFixedAssetLeases(): Code[20]
    begin
        exit('61999');
    end;

    internal procedure TotalFixedAssetLeasesName(): Text[100]
    begin
        exit(TotalFixedAssetLeasesTok);
    end;


    internal procedure LogisticsExpenses(): Code[20]
    begin
        exit('62000');
    end;

    internal procedure LogisticsExpensesName(): Text[100]
    begin
        exit(LogisticsExpensesTok);
    end;


    internal procedure VehicleExpenses(): Code[20]
    begin
        exit('62100');
    end;

    internal procedure VehicleExpensesName(): Text[100]
    begin
        exit(VehicleExpensesTok);
    end;


    internal procedure PassengerCarCosts(): Code[20]
    begin
        exit('62110');
    end;

    internal procedure PassengerCarCostsName(): Text[100]
    begin
        exit(PassengerCarCostsTok);
    end;


    internal procedure TruckCosts(): Code[20]
    begin
        exit('62120');
    end;

    internal procedure TruckCostsName(): Text[100]
    begin
        exit(TruckCostsTok);
    end;


    internal procedure Othervehicleexpenses(): Code[20]
    begin
        exit('62190');
    end;

    internal procedure OthervehicleexpensesName(): Text[100]
    begin
        exit(OthervehicleexpensesTok);
    end;


    internal procedure TotalVehicleExpenses(): Code[20]
    begin
        exit('62199');
    end;

    internal procedure TotalVehicleExpensesName(): Text[100]
    begin
        exit(TotalVehicleExpensesTok);
    end;


    internal procedure FreightCosts(): Code[20]
    begin
        exit('62200');
    end;

    internal procedure FreightCostsName(): Text[100]
    begin
        exit(FreightCostsTok);
    end;


    internal procedure Freightfeesforgoods(): Code[20]
    begin
        exit('62210');
    end;

    internal procedure FreightfeesforgoodsName(): Text[100]
    begin
        exit(FreightfeesforgoodsTok);
    end;


    internal procedure Customsandforwarding(): Code[20]
    begin
        exit('62220');
    end;

    internal procedure CustomsandforwardingName(): Text[100]
    begin
        exit(CustomsandforwardingTok);
    end;


    internal procedure Freightfeesprojects(): Code[20]
    begin
        exit('62230');
    end;

    internal procedure FreightfeesprojectsName(): Text[100]
    begin
        exit(FreightfeesprojectsTok);
    end;


    internal procedure TotalFreightCosts(): Code[20]
    begin
        exit('62299');
    end;

    internal procedure TotalFreightCostsName(): Text[100]
    begin
        exit(TotalFreightCostsTok);
    end;


    internal procedure TravelExpenses(): Code[20]
    begin
        exit('62300');
    end;

    internal procedure TravelExpensesName(): Text[100]
    begin
        exit(TravelExpensesTok);
    end;


    internal procedure Tickets(): Code[20]
    begin
        exit('62310');
    end;

    internal procedure TicketsName(): Text[100]
    begin
        exit(TicketsTok);
    end;


    internal procedure Rentalvehicles(): Code[20]
    begin
        exit('62320');
    end;

    internal procedure RentalvehiclesName(): Text[100]
    begin
        exit(RentalvehiclesTok);
    end;


    internal procedure Boardandlodging(): Code[20]
    begin
        exit('62330');
    end;

    internal procedure BoardandlodgingName(): Text[100]
    begin
        exit(BoardandlodgingTok);
    end;


    internal procedure Othertravelexpenses(): Code[20]
    begin
        exit('62340');
    end;

    internal procedure OthertravelexpensesName(): Text[100]
    begin
        exit(OthertravelexpensesTok);
    end;


    internal procedure TotalTravelExpenses(): Code[20]
    begin
        exit('62399');
    end;

    internal procedure TotalTravelExpensesName(): Text[100]
    begin
        exit(TotalTravelExpensesTok);
    end;


    internal procedure TotalLogisticsExpenses(): Code[20]
    begin
        exit('62999');
    end;

    internal procedure TotalLogisticsExpensesName(): Text[100]
    begin
        exit(TotalLogisticsExpensesTok);
    end;


    internal procedure MarketingandSales(): Code[20]
    begin
        exit('63000');
    end;

    internal procedure MarketingandSalesName(): Text[100]
    begin
        exit(MarketingandSalesTok);
    end;


    internal procedure Advertising(): Code[20]
    begin
        exit('63100');
    end;

    internal procedure AdvertisingName(): Text[100]
    begin
        exit(AdvertisingTok);
    end;


    internal procedure AdvertisementDevelopment(): Code[20]
    begin
        exit('63110');
    end;

    internal procedure AdvertisementDevelopmentName(): Text[100]
    begin
        exit(AdvertisementDevelopmentTok);
    end;


    internal procedure OutdoorandTransportationAds(): Code[20]
    begin
        exit('63120');
    end;

    internal procedure OutdoorandTransportationAdsName(): Text[100]
    begin
        exit(OutdoorandTransportationAdsTok);
    end;


    internal procedure Admatteranddirectmailings(): Code[20]
    begin
        exit('63130');
    end;

    internal procedure AdmatteranddirectmailingsName(): Text[100]
    begin
        exit(AdmatteranddirectmailingsTok);
    end;


    internal procedure Conference_ExhibitionSponsorship(): Code[20]
    begin
        exit('63140');
    end;

    internal procedure Conference_ExhibitionSponsorshipName(): Text[100]
    begin
        exit(Conference_ExhibitionSponsorshipTok);
    end;


    internal procedure Samplescontestsgifts(): Code[20]
    begin
        exit('63150');
    end;

    internal procedure SamplescontestsgiftsName(): Text[100]
    begin
        exit(SamplescontestsgiftsTok);
    end;


    internal procedure FilmTVradiointernetads(): Code[20]
    begin
        exit('63160');
    end;

    internal procedure FilmTVradiointernetadsName(): Text[100]
    begin
        exit(FilmTVradiointernetadsTok);
    end;


    internal procedure PRandAgencyFees(): Code[20]
    begin
        exit('63170');
    end;

    internal procedure PRandAgencyFeesName(): Text[100]
    begin
        exit(PRandAgencyFeesTok);
    end;


    internal procedure Otheradvertisingfees(): Code[20]
    begin
        exit('63190');
    end;

    internal procedure OtheradvertisingfeesName(): Text[100]
    begin
        exit(OtheradvertisingfeesTok);
    end;


    internal procedure TotalAdvertising(): Code[20]
    begin
        exit('63199');
    end;

    internal procedure TotalAdvertisingName(): Text[100]
    begin
        exit(TotalAdvertisingTok);
    end;


    internal procedure OtherMarketingExpenses(): Code[20]
    begin
        exit('63200');
    end;

    internal procedure OtherMarketingExpensesName(): Text[100]
    begin
        exit(OtherMarketingExpensesTok);
    end;


    internal procedure Catalogspricelists(): Code[20]
    begin
        exit('63210');
    end;

    internal procedure CatalogspricelistsName(): Text[100]
    begin
        exit(CatalogspricelistsTok);
    end;


    internal procedure TradePublications(): Code[20]
    begin
        exit('63220');
    end;

    internal procedure TradePublicationsName(): Text[100]
    begin
        exit(TradePublicationsTok);
    end;


    internal procedure TotalOtherMarketingExpenses(): Code[20]
    begin
        exit('63399');
    end;

    internal procedure TotalOtherMarketingExpensesName(): Text[100]
    begin
        exit(TotalOtherMarketingExpensesTok);
    end;


    internal procedure SalesExpenses(): Code[20]
    begin
        exit('63400');
    end;

    internal procedure SalesExpensesName(): Text[100]
    begin
        exit(SalesExpensesTok);
    end;


    internal procedure CreditCardCharges(): Code[20]
    begin
        exit('63410');
    end;

    internal procedure CreditCardChargesName(): Text[100]
    begin
        exit(CreditCardChargesTok);
    end;


    internal procedure BusinessEntertainingdeductible(): Code[20]
    begin
        exit('63420');
    end;

    internal procedure BusinessEntertainingdeductibleName(): Text[100]
    begin
        exit(BusinessEntertainingdeductibleTok);
    end;


    internal procedure BusinessEntertainingnondeductible(): Code[20]
    begin
        exit('63430');
    end;

    internal procedure BusinessEntertainingnondeductibleName(): Text[100]
    begin
        exit(BusinessEntertainingnondeductibleTok);
    end;


    internal procedure TotalSalesExpenses(): Code[20]
    begin
        exit('63499');
    end;

    internal procedure TotalSalesExpensesName(): Text[100]
    begin
        exit(TotalSalesExpensesTok);
    end;


    internal procedure TotalMarketingandSales(): Code[20]
    begin
        exit('63999');
    end;

    internal procedure TotalMarketingandSalesName(): Text[100]
    begin
        exit(TotalMarketingandSalesTok);
    end;


    internal procedure OfficeExpenses(): Code[20]
    begin
        exit('64000');
    end;

    internal procedure OfficeExpensesName(): Text[100]
    begin
        exit(OfficeExpensesTok);
    end;


    internal procedure OfficeSupplies(): Code[20]
    begin
        exit('64100');
    end;

    internal procedure OfficeSuppliesName(): Text[100]
    begin
        exit(OfficeSuppliesTok);
    end;


    internal procedure PhoneServices(): Code[20]
    begin
        exit('64200');
    end;

    internal procedure PhoneServicesName(): Text[100]
    begin
        exit(PhoneServicesTok);
    end;


    internal procedure Dataservices(): Code[20]
    begin
        exit('64300');
    end;

    internal procedure DataservicesName(): Text[100]
    begin
        exit(DataservicesTok);
    end;


    internal procedure Postalfees(): Code[20]
    begin
        exit('64400');
    end;

    internal procedure PostalfeesName(): Text[100]
    begin
        exit(PostalfeesTok);
    end;


    internal procedure Consumable_Expensiblehardware(): Code[20]
    begin
        exit('64500');
    end;

    internal procedure Consumable_ExpensiblehardwareName(): Text[100]
    begin
        exit(Consumable_ExpensiblehardwareTok);
    end;


    internal procedure Softwareandsubscriptionfees(): Code[20]
    begin
        exit('64600');
    end;

    internal procedure SoftwareandsubscriptionfeesName(): Text[100]
    begin
        exit(SoftwareandsubscriptionfeesTok);
    end;


    internal procedure TotalOfficeExpenses(): Code[20]
    begin
        exit('64999');
    end;

    internal procedure TotalOfficeExpensesName(): Text[100]
    begin
        exit(TotalOfficeExpensesTok);
    end;


    internal procedure InsurancesandRisks(): Code[20]
    begin
        exit('65000');
    end;

    internal procedure InsurancesandRisksName(): Text[100]
    begin
        exit(InsurancesandRisksTok);
    end;


    internal procedure CorporateInsurance(): Code[20]
    begin
        exit('65100');
    end;

    internal procedure CorporateInsuranceName(): Text[100]
    begin
        exit(CorporateInsuranceTok);
    end;


    internal procedure DamagesPaid(): Code[20]
    begin
        exit('65200');
    end;

    internal procedure DamagesPaidName(): Text[100]
    begin
        exit(DamagesPaidTok);
    end;


    internal procedure BadDebtLosses(): Code[20]
    begin
        exit('65300');
    end;

    internal procedure BadDebtLossesName(): Text[100]
    begin
        exit(BadDebtLossesTok);
    end;


    internal procedure Securityservices(): Code[20]
    begin
        exit('65400');
    end;

    internal procedure SecurityservicesName(): Text[100]
    begin
        exit(SecurityservicesTok);
    end;


    internal procedure Otherriskexpenses(): Code[20]
    begin
        exit('65900');
    end;

    internal procedure OtherriskexpensesName(): Text[100]
    begin
        exit(OtherriskexpensesTok);
    end;


    internal procedure TotalInsurancesandRisks(): Code[20]
    begin
        exit('65999');
    end;

    internal procedure TotalInsurancesandRisksName(): Text[100]
    begin
        exit(TotalInsurancesandRisksTok);
    end;


    internal procedure ManagementandAdmin(): Code[20]
    begin
        exit('66000');
    end;

    internal procedure ManagementandAdminName(): Text[100]
    begin
        exit(ManagementandAdminTok);
    end;


    internal procedure Management(): Code[20]
    begin
        exit('66100');
    end;

    internal procedure ManagementName(): Text[100]
    begin
        exit(ManagementTok);
    end;


    internal procedure RemunerationtoDirectors(): Code[20]
    begin
        exit('66110');
    end;

    internal procedure RemunerationtoDirectorsName(): Text[100]
    begin
        exit(RemunerationtoDirectorsTok);
    end;


    internal procedure ManagementFees(): Code[20]
    begin
        exit('66120');
    end;

    internal procedure ManagementFeesName(): Text[100]
    begin
        exit(ManagementFeesTok);
    end;


    internal procedure Annual_interrimReports(): Code[20]
    begin
        exit('66130');
    end;

    internal procedure Annual_interrimReportsName(): Text[100]
    begin
        exit(Annual_interrimReportsTok);
    end;


    internal procedure Annual_generalmeeting(): Code[20]
    begin
        exit('66140');
    end;

    internal procedure Annual_generalmeetingName(): Text[100]
    begin
        exit(Annual_generalmeetingTok);
    end;


    internal procedure AuditandAuditServices(): Code[20]
    begin
        exit('66150');
    end;

    internal procedure AuditandAuditServicesName(): Text[100]
    begin
        exit(AuditandAuditServicesTok);
    end;


    internal procedure TaxadvisoryServices(): Code[20]
    begin
        exit('66160');
    end;

    internal procedure TaxadvisoryServicesName(): Text[100]
    begin
        exit(TaxadvisoryServicesTok);
    end;


    internal procedure TotalManagementFees(): Code[20]
    begin
        exit('66199');
    end;

    internal procedure TotalManagementFeesName(): Text[100]
    begin
        exit(TotalManagementFeesTok);
    end;


    internal procedure TotalManagementandAdmin(): Code[20]
    begin
        exit('66999');
    end;

    internal procedure TotalManagementandAdminName(): Text[100]
    begin
        exit(TotalManagementandAdminTok);
    end;


    internal procedure BankingandInterest(): Code[20]
    begin
        exit('67000');
    end;

    internal procedure BankingandInterestName(): Text[100]
    begin
        exit(BankingandInterestTok);
    end;


    internal procedure Bankingfees(): Code[20]
    begin
        exit('67100');
    end;

    internal procedure BankingfeesName(): Text[100]
    begin
        exit(BankingfeesTok);
    end;


    internal procedure InterestExpenses(): Code[20]
    begin
        exit('67200');
    end;

    internal procedure InterestExpensesName(): Text[100]
    begin
        exit(InterestExpensesTok);
    end;


    internal procedure PayableInvoiceRounding(): Code[20]
    begin
        exit('67300');
    end;

    internal procedure PayableInvoiceRoundingName(): Text[100]
    begin
        exit(PayableInvoiceRoundingTok);
    end;


    internal procedure TotalBankingandInterest(): Code[20]
    begin
        exit('67999');
    end;

    internal procedure TotalBankingandInterestName(): Text[100]
    begin
        exit(TotalBankingandInterestTok);
    end;


    internal procedure ExternalServices_Expenses(): Code[20]
    begin
        exit('68000');
    end;

    internal procedure ExternalServices_ExpensesName(): Text[100]
    begin
        exit(ExternalServices_ExpensesTok);
    end;


    internal procedure ExternalServices(): Code[20]
    begin
        exit('68100');
    end;

    internal procedure ExternalServicesName(): Text[100]
    begin
        exit(ExternalServicesTok);
    end;


    internal procedure AccountingServices(): Code[20]
    begin
        exit('68110');
    end;

    internal procedure AccountingServicesName(): Text[100]
    begin
        exit(AccountingServicesTok);
    end;


    internal procedure ITServices(): Code[20]
    begin
        exit('68120');
    end;

    internal procedure ITServicesName(): Text[100]
    begin
        exit(ITServicesTok);
    end;


    internal procedure MediaServices(): Code[20]
    begin
        exit('68130');
    end;

    internal procedure MediaServicesName(): Text[100]
    begin
        exit(MediaServicesTok);
    end;


    internal procedure ConsultingServices(): Code[20]
    begin
        exit('68140');
    end;

    internal procedure ConsultingServicesName(): Text[100]
    begin
        exit(ConsultingServicesTok);
    end;


    internal procedure LegalFeesandAttorneyServices(): Code[20]
    begin
        exit('68150');
    end;

    internal procedure LegalFeesandAttorneyServicesName(): Text[100]
    begin
        exit(LegalFeesandAttorneyServicesTok);
    end;


    internal procedure OtherExternalServices(): Code[20]
    begin
        exit('68190');
    end;

    internal procedure OtherExternalServicesName(): Text[100]
    begin
        exit(OtherExternalServicesTok);
    end;


    internal procedure TotalExternalServices(): Code[20]
    begin
        exit('68199');
    end;

    internal procedure TotalExternalServicesName(): Text[100]
    begin
        exit(TotalExternalServicesTok);
    end;


    internal procedure OtherExternalExpenses(): Code[20]
    begin
        exit('68200');
    end;

    internal procedure OtherExternalExpensesName(): Text[100]
    begin
        exit(OtherExternalExpensesTok);
    end;


    internal procedure LicenseFees_Royalties(): Code[20]
    begin
        exit('68210');
    end;

    internal procedure LicenseFees_RoyaltiesName(): Text[100]
    begin
        exit(LicenseFees_RoyaltiesTok);
    end;


    internal procedure Trademarks_Patents(): Code[20]
    begin
        exit('68220');
    end;

    internal procedure Trademarks_PatentsName(): Text[100]
    begin
        exit(Trademarks_PatentsTok);
    end;


    internal procedure AssociationFees(): Code[20]
    begin
        exit('68230');
    end;

    internal procedure AssociationFeesName(): Text[100]
    begin
        exit(AssociationFeesTok);
    end;


    internal procedure Miscexternalexpenses(): Code[20]
    begin
        exit('68280');
    end;

    internal procedure MiscexternalexpensesName(): Text[100]
    begin
        exit(MiscexternalexpensesTok);
    end;


    internal procedure PurchaseDiscounts(): Code[20]
    begin
        exit('68290');
    end;

    internal procedure PurchaseDiscountsName(): Text[100]
    begin
        exit(PurchaseDiscountsTok);
    end;


    internal procedure TotalOtherExternalExpenses(): Code[20]
    begin
        exit('68299');
    end;

    internal procedure TotalOtherExternalExpensesName(): Text[100]
    begin
        exit(TotalOtherExternalExpensesTok);
    end;


    internal procedure TotalExternalServices_Expenses(): Code[20]
    begin
        exit('68999');
    end;

    internal procedure TotalExternalServices_ExpensesName(): Text[100]
    begin
        exit(TotalExternalServices_ExpensesTok);
    end;


    internal procedure Personnel(): Code[20]
    begin
        exit('70000');
    end;

    internal procedure PersonnelName(): Text[100]
    begin
        exit(PersonnelTok);
    end;


    internal procedure WagesandSalaries(): Code[20]
    begin
        exit('71000');
    end;

    internal procedure WagesandSalariesName(): Text[100]
    begin
        exit(WagesandSalariesTok);
    end;


    internal procedure Salaries(): Code[20]
    begin
        exit('71100');
    end;

    internal procedure SalariesName(): Text[100]
    begin
        exit(SalariesTok);
    end;


    internal procedure HourlyWages(): Code[20]
    begin
        exit('71110');
    end;

    internal procedure HourlyWagesName(): Text[100]
    begin
        exit(HourlyWagesTok);
    end;


    internal procedure OvertimeWages(): Code[20]
    begin
        exit('71120');
    end;

    internal procedure OvertimeWagesName(): Text[100]
    begin
        exit(OvertimeWagesTok);
    end;


    internal procedure Bonuses(): Code[20]
    begin
        exit('71130');
    end;

    internal procedure BonusesName(): Text[100]
    begin
        exit(BonusesTok);
    end;


    internal procedure CommissionsPaid(): Code[20]
    begin
        exit('71140');
    end;

    internal procedure CommissionsPaidName(): Text[100]
    begin
        exit(CommissionsPaidTok);
    end;


    internal procedure PTOAccrued(): Code[20]
    begin
        exit('71150');
    end;

    internal procedure PTOAccruedName(): Text[100]
    begin
        exit(PTOAccruedTok);
    end;


    internal procedure TotalWagesandSalaries(): Code[20]
    begin
        exit('71999');
    end;

    internal procedure TotalWagesandSalariesName(): Text[100]
    begin
        exit(TotalWagesandSalariesTok);
    end;


    internal procedure Benefits_Pension(): Code[20]
    begin
        exit('72000');
    end;

    internal procedure Benefits_PensionName(): Text[100]
    begin
        exit(Benefits_PensionTok);
    end;


    internal procedure Benefits(): Code[20]
    begin
        exit('72100');
    end;

    internal procedure BenefitsName(): Text[100]
    begin
        exit(BenefitsTok);
    end;


    internal procedure TrainingCosts(): Code[20]
    begin
        exit('72110');
    end;

    internal procedure TrainingCostsName(): Text[100]
    begin
        exit(TrainingCostsTok);
    end;


    internal procedure HealthCareContributions(): Code[20]
    begin
        exit('72120');
    end;

    internal procedure HealthCareContributionsName(): Text[100]
    begin
        exit(HealthCareContributionsTok);
    end;


    internal procedure Entertainmentofpersonnel(): Code[20]
    begin
        exit('72130');
    end;

    internal procedure EntertainmentofpersonnelName(): Text[100]
    begin
        exit(EntertainmentofpersonnelTok);
    end;


    internal procedure Allowances(): Code[20]
    begin
        exit('72140');
    end;

    internal procedure AllowancesName(): Text[100]
    begin
        exit(AllowancesTok);
    end;


    internal procedure Mandatoryclothingexpenses(): Code[20]
    begin
        exit('72150');
    end;

    internal procedure MandatoryclothingexpensesName(): Text[100]
    begin
        exit(MandatoryclothingexpensesTok);
    end;


    internal procedure Othercash_remunerationbenefits(): Code[20]
    begin
        exit('72160');
    end;

    internal procedure Othercash_remunerationbenefitsName(): Text[100]
    begin
        exit(Othercash_remunerationbenefitsTok);
    end;


    internal procedure TotalBenefits(): Code[20]
    begin
        exit('72199');
    end;

    internal procedure TotalBenefitsName(): Text[100]
    begin
        exit(TotalBenefitsTok);
    end;


    internal procedure Pension(): Code[20]
    begin
        exit('72200');
    end;

    internal procedure PensionName(): Text[100]
    begin
        exit(PensionTok);
    end;


    internal procedure Pensionfeesandrecurringcosts(): Code[20]
    begin
        exit('72210');
    end;

    internal procedure PensionfeesandrecurringcostsName(): Text[100]
    begin
        exit(PensionfeesandrecurringcostsTok);
    end;


    internal procedure EmployerContributions(): Code[20]
    begin
        exit('72220');
    end;

    internal procedure EmployerContributionsName(): Text[100]
    begin
        exit(EmployerContributionsTok);
    end;


    internal procedure TotalPension(): Code[20]
    begin
        exit('72299');
    end;

    internal procedure TotalPensionName(): Text[100]
    begin
        exit(TotalPensionTok);
    end;


    internal procedure TotalBenefits_Pension(): Code[20]
    begin
        exit('72999');
    end;

    internal procedure TotalBenefits_PensionName(): Text[100]
    begin
        exit(TotalBenefits_PensionTok);
    end;


    internal procedure InsurancesPersonnel(): Code[20]
    begin
        exit('73000');
    end;

    internal procedure InsurancesPersonnelName(): Text[100]
    begin
        exit(InsurancesPersonnelTok);
    end;


    internal procedure HealthInsurance(): Code[20]
    begin
        exit('73100');
    end;

    internal procedure HealthInsuranceName(): Text[100]
    begin
        exit(HealthInsuranceTok);
    end;


    internal procedure DentalInsurance(): Code[20]
    begin
        exit('73200');
    end;

    internal procedure DentalInsuranceName(): Text[100]
    begin
        exit(DentalInsuranceTok);
    end;


    internal procedure WorkersCompensation(): Code[20]
    begin
        exit('73300');
    end;

    internal procedure WorkersCompensationName(): Text[100]
    begin
        exit(WorkersCompensationTok);
    end;


    internal procedure LifeInsurance(): Code[20]
    begin
        exit('73400');
    end;

    internal procedure LifeInsuranceName(): Text[100]
    begin
        exit(LifeInsuranceTok);
    end;


    internal procedure TotalInsurancesPersonnel(): Code[20]
    begin
        exit('73999');
    end;

    internal procedure TotalInsurancesPersonnelName(): Text[100]
    begin
        exit(TotalInsurancesPersonnelTok);
    end;


    internal procedure PersonnelTaxes(): Code[20]
    begin
        exit('74000');
    end;

    internal procedure PersonnelTaxesName(): Text[100]
    begin
        exit(PersonnelTaxesTok);
    end;


    internal procedure FederalPersonnelTaxes(): Code[20]
    begin
        exit('74100');
    end;

    internal procedure FederalPersonnelTaxesName(): Text[100]
    begin
        exit(FederalPersonnelTaxesTok);
    end;

    internal procedure FederalWithholdingExpense(): Code[20]
    begin
        exit('74110');
    end;

    internal procedure FederalWithholdingExpenseName(): Text[100]
    begin
        exit(FederalWithholdingExpenseTok);
    end;


    internal procedure FICAExpense(): Code[20]
    begin
        exit('74120');
    end;

    internal procedure FICAExpenseName(): Text[100]
    begin
        exit(FICAExpenseTok);
    end;


    internal procedure FUTAExpense(): Code[20]
    begin
        exit('74130');
    end;

    internal procedure FUTAExpenseName(): Text[100]
    begin
        exit(FUTAExpenseTok);
    end;


    internal procedure MedicareExpense(): Code[20]
    begin
        exit('74140');
    end;

    internal procedure MedicareExpenseName(): Text[100]
    begin
        exit(MedicareExpenseTok);
    end;


    internal procedure OtherFederalExpense(): Code[20]
    begin
        exit('74190');
    end;

    internal procedure OtherFederalExpenseName(): Text[100]
    begin
        exit(OtherFederalExpenseTok);
    end;


    internal procedure TotalFederalPersonnelTaxes(): Code[20]
    begin
        exit('74399');
    end;

    internal procedure TotalFederalPersonnelTaxesName(): Text[100]
    begin
        exit(TotalFederalPersonnelTaxesTok);
    end;


    internal procedure StatePersonnelTaxes(): Code[20]
    begin
        exit('74400');
    end;

    internal procedure StatePersonnelTaxesName(): Text[100]
    begin
        exit(StatePersonnelTaxesTok);
    end;


    internal procedure StateWithholdingExpense(): Code[20]
    begin
        exit('74410');
    end;

    internal procedure StateWithholdingExpenseName(): Text[100]
    begin
        exit(StateWithholdingExpenseTok);
    end;


    internal procedure SUTAExpense(): Code[20]
    begin
        exit('74420');
    end;

    internal procedure SUTAExpenseName(): Text[100]
    begin
        exit(SUTAExpenseTok);
    end;


    internal procedure TotalStatePersonnelTaxes(): Code[20]
    begin
        exit('74599');
    end;

    internal procedure TotalStatePersonnelTaxesName(): Text[100]
    begin
        exit(TotalStatePersonnelTaxesTok);
    end;


    internal procedure TotalPersonnelTaxes(): Code[20]
    begin
        exit('74999');
    end;

    internal procedure TotalPersonnelTaxesName(): Text[100]
    begin
        exit(TotalPersonnelTaxesTok);
    end;


    internal procedure TotalPersonnel(): Code[20]
    begin
        exit('79999');
    end;

    internal procedure TotalPersonnelName(): Text[100]
    begin
        exit(TotalPersonnelTok);
    end;


    internal procedure Depreciation(): Code[20]
    begin
        exit('80000');
    end;

    internal procedure DepreciationName(): Text[100]
    begin
        exit(DepreciationTok);
    end;


    internal procedure DepreciationLandandProperty(): Code[20]
    begin
        exit('81000');
    end;

    internal procedure DepreciationLandandPropertyName(): Text[100]
    begin
        exit(DepreciationLandandPropertyTok);
    end;


    internal procedure DepreciationFixedAssets(): Code[20]
    begin
        exit('82000');
    end;

    internal procedure DepreciationFixedAssetsName(): Text[100]
    begin
        exit(DepreciationFixedAssetsTok);
    end;


    internal procedure TotalDepreciation(): Code[20]
    begin
        exit('89999');
    end;

    internal procedure TotalDepreciationName(): Text[100]
    begin
        exit(TotalDepreciationTok);
    end;


    internal procedure MiscExpenses(): Code[20]
    begin
        exit('90000');
    end;

    internal procedure MiscExpensesName(): Text[100]
    begin
        exit(MiscExpensesTok);
    end;


    internal procedure CurrencyLosses(): Code[20]
    begin
        exit('91000');
    end;

    internal procedure CurrencyLossesName(): Text[100]
    begin
        exit(CurrencyLossesTok);
    end;


    internal procedure TotalMiscExpenses(): Code[20]
    begin
        exit('91999');
    end;

    internal procedure TotalMiscExpensesName(): Text[100]
    begin
        exit(TotalMiscExpensesTok);
    end;


    internal procedure TOTALEXPENSES(): Code[20]
    begin
        exit('98990');
    end;

    internal procedure TOTALEXPENSESName(): Text[100]
    begin
        exit(TOTALEXPENSESTok);
    end;


    internal procedure NETINCOME(): Code[20]
    begin
        exit('99999');
    end;

    internal procedure NETINCOMEName(): Text[100]
    begin
        exit(NETINCOMETok);
    end;
}
