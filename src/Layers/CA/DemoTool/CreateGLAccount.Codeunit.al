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
        InsertData('992410', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.NoVATCode()), 0, 1, 0, '', 0, '', DemoDataSetup.NoVATCode(), '', '', false);
        InsertData('992420', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.ServicesCode()), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('992430', StrSubstNo(XVendorPrepaymentsVAT, DemoDataSetup.RetailCode()), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', '', false);
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
        InsertData('995360', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.NoVATCode()), 0, 1, 0, '', 0, '', DemoDataSetup.NoVATCode(), '', '', false);
        InsertData('995370', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.ServicesCode()), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('995380', StrSubstNo(XCustomerPrepaymentsVAT, DemoDataSetup.RetailCode()), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', '', false);
        InsertData('995390', XCustomerPrepaymentsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995400', XAccountsPayable, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995410', XVendorsDomestic, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995420', XVendorsForeign, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995490', XAccountsPayableTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995500', XInvAdjmtInterim, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995510', XInvAdjmtInterimRetail, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995530', XInvAdjmtInterimRawMat, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995590', XInvAdjmtInterimTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995600', XGSTHST, 0, 1, 0, '', 0, '', '', '', '', true);
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::"Sales Tax":
                if DemoDataSetup."Advanced Setup" then begin
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
                end else
                    InsertData('995620', XPurchaseTaxTok, 0, 1, 0, '', 0, '', '', '', '', true);
            DemoDataSetup."Company Type"::VAT:
                begin
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
        InsertData('995710', XPST, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995800', XPersonnelrelatedItems, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995810', XWithholdingTaxesPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995820', XPSTPAYABLE, 0, 1, 0, '', 0, '', '', '', '', true);
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
          '|' + Adjust.Convert('996100') + '..' + Adjust.Convert('999999'), 0, '', '', '', '', true);
        InsertData('996000', XINCOMESTATEMENT, 1, 0, 0, '', 0, '', '', '', '', true);
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
        InsertData('990014', XACCRUEDPAYABLES, 0, 1, 0, '', 0, '', '', '', '', false);
        GLAccIndent.Indent();
        AddCategoriesToGLAccounts();
    end;

    var
        GetGLNoName: Codeunit "Get G/L Account No. and Name";
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
        XTAXABLE: Label 'TAXABLE';
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
        XBonds: Label 'Bonds';
        XSecuritiesTotal: Label 'Securities, Total';
        XCash: Label 'Cash';
        XBankLCY: Label 'Bank, Checking';
        XBankCurrencies: Label 'Bank Currencies';
        XGiroAccount: Label 'Bank Operations Cash';
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
        XPersonnelrelatedItems: Label 'Personnel-related Items';
        XWithholdingTaxesPayable: Label 'Federal Withholding Payable';
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
        XVendorPrepaymentsVAT: Label 'Vendor Prepayments %1';
        XPurchasePrepaymentsTotal: Label 'Purchase Prepayments, Total';
        XSalesPrepayments: Label 'Sales Prepayments';
        XCustomerPrepaymentsVAT: Label 'Customer Prepayments %1';
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
        XGSTHST: Label 'GST/HST - Sales Tax';
        XPST: Label 'Provincial Sales Tax';
        XPSTPAYABLE: Label 'Provincial Withholding Payable';
        XACCRUEDPAYABLES: Label 'Accrued Payables';
        XSecurities: Label 'Securities';
        XLiquidAssets: Label 'Liquid Assets';
        XLiquidAssetsTotal: Label 'Liquid Assets, Total';

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
        InsertData(GetGLNoName.IncomeStatement(), GetGLNoName.IncomeStatementName(), 1, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Revenue(), GetGLNoName.RevenueName(), 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesofJobs(), GetGLNoName.SalesofJobsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesOtherJobExpenses(), GetGLNoName.SalesOtherJobExpensesName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.JobSales(), GetGLNoName.JobSalesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalSalesofJobs(), GetGLNoName.TotalSalesofJobsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesofServiceContracts(), GetGLNoName.SalesofServiceContractsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ServiceContractSale(), GetGLNoName.ServiceContractSaleName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalSaleofServContracts(), GetGLNoName.TotalSaleofServContractsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesofResources(), GetGLNoName.SalesofResourcesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesResourcesDom(), GetGLNoName.SalesResourcesDomName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(GetGLNoName.SalesResourcesExport(), GetGLNoName.SalesResourcesExportName(), 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(GetGLNoName.JobSalesAdjmtResources(), GetGLNoName.JobSalesAdjmtResourcesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalSalesofResources(), GetGLNoName.TotalSalesofResourcesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesofRawMaterials(), GetGLNoName.SalesofRawMaterialsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesRawMaterialsDom(), GetGLNoName.SalesRawMaterialsDomName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData(GetGLNoName.SalesRawMaterialsExport(), GetGLNoName.SalesRawMaterialsExportName(), 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData(GetGLNoName.JobSalesAdjmtRawMat(), GetGLNoName.JobSalesAdjmtRawMatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalSalesofRawMaterials(), GetGLNoName.TotalSalesofRawMaterialsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesofRetail(), GetGLNoName.SalesofRetailName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesRetailDom(), GetGLNoName.SalesRetailDomName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(GetGLNoName.SalesRetailExport(), GetGLNoName.SalesRetailExportName(), 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(GetGLNoName.JobSalesAppliedRetail(), GetGLNoName.JobSalesAppliedRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.JobSalesAdjmtRetail(), GetGLNoName.JobSalesAdjmtRetailName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(GetGLNoName.TotalSalesofRetail(), GetGLNoName.TotalSalesofRetailName(), 4, 0, 0, '', 2, '', '', '', '', true);
        InsertData(GetGLNoName.InterestIncome(), GetGLNoName.InterestIncomeName(), 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InterestonBankBalances(), GetGLNoName.InterestonBankBalancesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.FinanceChargesfromCustomers(), GetGLNoName.FinanceChargesfromCustomersName(), 0, 0, 0, '', 2, '', DemoDataSetup.Zero(), '', '', true);
        InsertData(GetGLNoName.PmtDiscReceivedDecreases(), GetGLNoName.PmtDiscReceivedDecreasesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PaymentDiscountsReceived(), GetGLNoName.PaymentDiscountsReceivedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InvoiceRounding(), GetGLNoName.InvoiceRoundingName(), 0, 0, 0, '', 0, '', DemoDataSetup.Zero(), '', '', true);
        InsertData(GetGLNoName.ApplicationRounding(), GetGLNoName.ApplicationRoundingName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PaymentToleranceReceived(), GetGLNoName.PaymentToleranceReceivedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PmtTolReceivedDecreases(), GetGLNoName.PmtTolReceivedDecreasesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ConsultingFeesDom(), GetGLNoName.ConsultingFeesDomName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.FeesandChargesRecDom(), GetGLNoName.FeesandChargesRecDomName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.DiscountGranted(), GetGLNoName.DiscountGrantedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalInterestIncome(), GetGLNoName.TotalInterestIncomeName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalRevenue(), GetGLNoName.TotalRevenueName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Cost(), GetGLNoName.CostName(), 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.JobCosts(), GetGLNoName.JobCostsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofResources(), GetGLNoName.CostofResourcesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofResourcesUsed(), GetGLNoName.CostofResourcesUsedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.JobCostAdjmtResources(), GetGLNoName.JobCostAdjmtResourcesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.JobCostAppliedResources(), GetGLNoName.JobCostAppliedResourcesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalCostofResources(), GetGLNoName.TotalCostofResourcesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofCapacities(), GetGLNoName.CostofCapacitiesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofCapacitie(), GetGLNoName.CostofCapacitiesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DirectCostAppliedCap(), GetGLNoName.DirectCostAppliedCapName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OverheadAppliedCap(), GetGLNoName.OverheadAppliedCapName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PurchaseVarianceCap(), GetGLNoName.PurchaseVarianceCapName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalCostofCapacities(), GetGLNoName.TotalCostofCapacitiesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofRawMaterials(), GetGLNoName.CostofRawMaterialsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PurchRawMaterialsDom(), GetGLNoName.PurchRawMaterialsDomName(), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData(GetGLNoName.PurchRawMaterialsExport(), GetGLNoName.PurchRawMaterialsExportName(), 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData(GetGLNoName.DiscReceivedRawMaterials(), GetGLNoName.DiscReceivedRawMaterialsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DeliveryExpensesRawMat(), GetGLNoName.DeliveryExpensesRawMatName(), 0, 0, 0, '', 0, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.InventoryAdjmtRawMat(), GetGLNoName.InventoryAdjmtRawMatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DeliveryExpensesRetail(), GetGLNoName.DeliveryExpensesRetailName(), 0, 0, 0, '', 0, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.JobCostAdjmtRawMaterials(), GetGLNoName.JobCostAdjmtRawMaterialsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.JobCostAppliedRawMaterials(), GetGLNoName.JobCostAppliedRawMaterialsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofRawMaterialsSold(), GetGLNoName.CostofRawMaterialsSoldName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalCostofRawMaterials(), GetGLNoName.TotalCostofRawMaterialsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofRetail(), GetGLNoName.CostofRetailName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PurchRetailDom(), GetGLNoName.PurchRetailDomName(), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(GetGLNoName.PurchRetailExport(), GetGLNoName.PurchRetailExportName(), 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(GetGLNoName.DiscReceivedRetail(), GetGLNoName.DiscReceivedRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InventoryAdjmtRetail(), GetGLNoName.InventoryAdjmtRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.JobCostAppliedRetail(), GetGLNoName.JobCostAppliedRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.JobCostAdjmtRetail(), GetGLNoName.JobCostAdjmtRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofRetailSold(), GetGLNoName.CostofRetailSoldName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OverheadAppliedRetail(), GetGLNoName.OverheadAppliedRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PurchaseVarianceRetail(), GetGLNoName.PurchaseVarianceRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PaymentDiscountsGranted(), GetGLNoName.PaymentDiscountsGrantedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalCostofRetail(), GetGLNoName.TotalCostofRetailName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Variance(), GetGLNoName.VarianceName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.MaterialVariance(), GetGLNoName.MaterialVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CapacityVariance(), GetGLNoName.CapacityVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SubcontractedVariance(), GetGLNoName.SubcontractedVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CapOverheadVariance(), GetGLNoName.CapOverheadVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.MfgOverheadVariance(), GetGLNoName.MfgOverheadVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalVariance(), GetGLNoName.TotalVarianceName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalCost(), GetGLNoName.TotalCostName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OperatingExpenses(), GetGLNoName.OperatingExpensesName(), 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SellingExpenses(), GetGLNoName.SellingExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Advertising(), GetGLNoName.AdvertisingName(), 0, 0, 0, '', 0, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.EntertainmentandPR(), GetGLNoName.EntertainmentandPRName(), 0, 0, 0, '', 0, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.Travel(), GetGLNoName.TravelName(), 0, 0, 0, '', 0, '', DemoDataSetup.Zero(), '', '', true);
        InsertData(GetGLNoName.DeliveryExpenses(), GetGLNoName.DeliveryExpensesName(), 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.TotalSellingExpenses(), GetGLNoName.TotalSellingExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PersonnelExpenses(), GetGLNoName.PersonnelExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Wages(), GetGLNoName.WagesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Salaries(), GetGLNoName.SalariesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.RetirementPlanContributions(), GetGLNoName.RetirementPlanContributionsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.VacationCompensation(), GetGLNoName.VacationCompensationName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PayrollTaxes(), GetGLNoName.PayrollTaxesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.HealthInsurance(), GetGLNoName.HealthInsuranceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.GroupLifeInsurance(), GetGLNoName.GroupLifeInsuranceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.WorkersCompensation(), GetGLNoName.WorkersCompensationName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.KContributions(), GetGLNoName.KContributionsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalPersonnelExpenses(), GetGLNoName.TotalPersonnelExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.VehicleExpenses(), GetGLNoName.VehicleExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.GasolineandMotorOil(), GetGLNoName.GasolineandMotorOilName(), 0, 0, 0, '', 0, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.RegistrationFees(), GetGLNoName.RegistrationFeesName(), 0, 0, 0, '', 0, '', DemoDataSetup.Zero(), '', '', true);
        InsertData(GetGLNoName.RepairsandMaintenance(), GetGLNoName.RepairsandMaintenanceName(), 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.Taxes(), GetGLNoName.TaxesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalVehicleExpenses(), GetGLNoName.TotalVehicleExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ComputerExpenses(), GetGLNoName.ComputerExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Software(), GetGLNoName.SoftwareName(), 0, 0, 0, '', 0, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.ConsultantServices(), GetGLNoName.ConsultantServicesName(), 0, 0, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(GetGLNoName.OtherComputerExpenses(), GetGLNoName.OtherComputerExpensesName(), 0, 0, 0, '', 0, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.TotalComputerExpenses(), GetGLNoName.TotalComputerExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.BuildingMaintenanceExpenses(), GetGLNoName.BuildingMaintenanceExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Cleaning(), GetGLNoName.CleaningName(), 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.ElectricityandHeating(), GetGLNoName.ElectricityandHeatingName(), 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.RepairandMaintenance(), GetGLNoName.RepairsandMaintenanceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalBldgMaintExpenses(), GetGLNoName.TotalBldgMaintExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AdministrativeExpenses(), GetGLNoName.AdministrativeExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OfficeSupplies(), GetGLNoName.OfficeSuppliesName(), 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.PhoneandFax(), GetGLNoName.PhoneandFaxName(), 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.Postage(), GetGLNoName.PostageName(), 0, 0, 0, '', 1, '', DemoDataSetup.Zero(), '', '', true);
        InsertData(GetGLNoName.TotalAdministrativeExpenses(), GetGLNoName.TotalAdministrativeExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OtherOperatingExpenses(), GetGLNoName.OtherOperatingExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CashDiscrepancies(), GetGLNoName.CashDiscrepanciesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.BadDebtExpenses(), GetGLNoName.BadDebtExpensesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LegalandAccountingServices(), GetGLNoName.LegalandAccountingServicesName(), 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.Miscellaneous(), GetGLNoName.MiscellaneousName(), 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.OtherCostsofOperations(), GetGLNoName.OtherCostsofOperationsName(), 0, 0, 0, '', 1, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.OtherOperatingExpTotal(), GetGLNoName.OtherOperatingExpTotalName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalOperatingExpenses(), GetGLNoName.TotalOperatingExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.EBITDA(), GetGLNoName.EBITDAName(), 2, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DepreciationofFixedAssets(), GetGLNoName.DepreciationofFixedAssetsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DepreciationBuildings(), GetGLNoName.DepreciationBuildingsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DepreciationEquipment(), GetGLNoName.DepreciationEquipmentName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DepreciationVehicles(), GetGLNoName.DepreciationVehiclesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalFixedAssetDepreciation(), GetGLNoName.TotalFixedAssetDepreciationName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InterestExpenses(), GetGLNoName.InterestExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InterestonRevolvingCredit(), GetGLNoName.InterestonRevolvingCreditName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InterestonBankLoans(), GetGLNoName.InterestonBankLoansName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.MortgageInterest(), GetGLNoName.MortgageInterestName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.FinanceChargestoVendors(), GetGLNoName.FinanceChargestoVendorsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PmtDiscGrantedDecreases(), GetGLNoName.PmtDiscGrantedDecreasesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PaymentToleranceGranted(), GetGLNoName.PaymentToleranceGrantedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PaymentDiscountGranted(), GetGLNoName.PaymentDiscountsGrantedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PmtTolGrantedDecreases(), GetGLNoName.PmtTolGrantedDecreasesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalInterestExpenses(), GetGLNoName.TotalInterestExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.GainsAndLosses(), GetGLNoName.GainsAndLossesName(), 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.UnrealizedFXGains(), GetGLNoName.UnrealizedFXGainsName(), 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.UnrealizedFXLosses(), GetGLNoName.UnrealizedFXLossesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.RealizedFXGains(), GetGLNoName.RealizedFXGainsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.RealizedFXLosses(), GetGLNoName.RealizedFXLossesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.GainsandLosse(), GetGLNoName.GainsAndLossesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalGainsAndLosses(), GetGLNoName.TotalGainsAndLossesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.NetOperatingIncomeBeforeExtraOrdItemsTaxes(), GetGLNoName.NetOperatingIncomeBeforeExtraOrdItemsTaxesName(), 2, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.IncomeTaxes(), GetGLNoName.IncomeTaxesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CorporateTax(), GetGLNoName.CorporateTaxName(), 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.StateIncomeTax(), GetGLNoName.StateIncomeTaxName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalIncomeTaxes(), GetGLNoName.TotalIncomeTaxesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.NetIncomeBeforeExtrItems(), GetGLNoName.NetIncomeBeforeExtrItemsName(), 2, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ExtraordinaryItems(), GetGLNoName.ExtraordinaryItemsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ExtraordinaryIncome(), GetGLNoName.ExtraordinaryIncomeName(), 0, 0, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.RevaluationSurplusadjustments(), GetGLNoName.RevaluationSurplusadjustmentsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ExtraordinaryExpenses(), GetGLNoName.ExtraordinaryExpensesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ExtraordinaryItemsTotal(), GetGLNoName.ExtraordinaryItemsTotalName(), 4, 0, 0, '', 0, '', '', '', '', true);
    end;

    procedure AddBalanceSheetForMini()
    begin
        // Balance sheet 5000-9999
        DemoDataSetup.Get();
        InsertData(GetGLNoName.ASSETS(), GetGLNoName.AssetsName(), 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CurrentAssets(), GetGLNoName.CurrentAssetsName(), 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LiquidAssets(), GetGLNoName.LiquidAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Cash(), GetGLNoName.CashName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.BankChecking(), GetGLNoName.BankCheckingName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.BankCurrenciesLCY(), GetGLNoName.BankCurrenciesLCYName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.BankCurrenciesFCYUSD(), GetGLNoName.BankCurrenciesFCYUSDName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.BankOperationsCash(), GetGLNoName.BankOperationsCashName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LiquidAssetsTotal(), GetGLNoName.LiquidAssetsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Securities(), GetGLNoName.SecuritiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ShortTermInvestments(), GetGLNoName.ShortTermInvestmentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CanadianTermDeposits(), GetGLNoName.CanadianTermDepositsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Bonds(), GetGLNoName.BondsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OtherMarketableSecurities(), GetGLNoName.OtherMarketableSecuritiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InterestAccruedoninvestment(), GetGLNoName.InterestAccruedoninvestmentName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SecuritiesTotal(), GetGLNoName.SecuritiesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccountsReceivable(), GetGLNoName.AccountsReceivableName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CustomersDomesticCAD(), GetGLNoName.CustomersDomesticCADName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CustomersForeignFCY(), GetGLNoName.CustomersForeignFCYName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OtherReceivables(), GetGLNoName.OtherReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccountsReceivableTotal(), GetGLNoName.AccountsReceivableTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PurchasePrepayments(), GetGLNoName.PurchasePrepaymentsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.VendorPrepaymentsSERVICES(), GetGLNoName.VendorPrepaymentsSERVICESName(), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(GetGLNoName.VendorPrepaymentsRETAIL(), GetGLNoName.VendorPrepaymentsRETAILName(), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', '', true);
        InsertData(GetGLNoName.PurchasePrepaymentsTotal(), GetGLNoName.PurchasePrepaymentsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Inventory(), GetGLNoName.InventoryName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ResaleItems(), GetGLNoName.ResaleItemsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ResaleItemsInterim(), GetGLNoName.ResaleItemsInterimName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofResaleSoldInterim(), GetGLNoName.CostofResaleSoldInterimName(), 0, 1, 0, '', 2, '', '', '', '', true);
        InsertData(GetGLNoName.FinishedGoods(), GetGLNoName.FinishedGoodsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.FinishedGoodsInterim(), GetGLNoName.FinishedGoodsInterimName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.RawMaterials(), GetGLNoName.RawMaterialsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.RawMaterialsInterim(), GetGLNoName.RawMaterialsInterimName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CostofRawMatSoldInterim(), GetGLNoName.CostofRawMatSoldInterimName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PrimoInventory(), GetGLNoName.PrimoInventoryName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AllowanceforFinishedGoodsWriteOffs(), GetGLNoName.AllowanceforFinishedGoodsWriteOffsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.WIPAccountFinishedgoods(), GetGLNoName.WIPAccountFinishedgoodsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InventoryTotal(), GetGLNoName.InventoryTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.JobWIP(), GetGLNoName.JobWIPName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.WIPSales(), GetGLNoName.WIPSalesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.WIPJobSales(), GetGLNoName.WIPJobSalesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InvoicedJobSales(), GetGLNoName.InvoicedJobSalesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.WIPSalesTotal(), GetGLNoName.WIPSalesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.WIPCosts(), GetGLNoName.WIPCostsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.WIPJobCosts(), GetGLNoName.WIPJobCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccruedJobCosts(), GetGLNoName.AccruedJobCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.WIPCostsTotal(), GetGLNoName.WIPCostsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.JobWIPTotal(), GetGLNoName.JobWIPTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CurrentAssetsTotal(), GetGLNoName.CurrentAssetsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.FixedAssets(), GetGLNoName.FixedAssetsName(), 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TangibleFixedAssets(), GetGLNoName.TangibleFixedAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Vehicles(), GetGLNoName.VehiclesName(), 3, 1, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.Vehicle(), GetGLNoName.VehiclesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccumDepreciationVehicles(), GetGLNoName.AccumDepreciationVehiclesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.VehiclesTotal(), GetGLNoName.VehiclesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OperatingEquipment(), GetGLNoName.OperatingEquipmentName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OperatEquipment(), GetGLNoName.OperatingEquipmentName(), 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.AccumDeprOperEquip(), GetGLNoName.AccumDeprOperEquipName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OperatingEquipmentTotal(), GetGLNoName.OperatingEquipmentTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LandandBuildings(), GetGLNoName.LandandBuildingsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LandandBuilding(), GetGLNoName.LandandBuildingsName(), 0, 1, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(GetGLNoName.AccumDepreciationBuildings(), GetGLNoName.AccumDepreciationBuildingsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LandandBuildingsTotal(), GetGLNoName.LandandBuildingsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TangibleFixedAssetsTotal(), GetGLNoName.TangibleFixedAssetsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.IntangibleAssets(), GetGLNoName.IntangibleAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.IntangibleAsset(), GetGLNoName.IntangibleAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccAmortnonIntangibles(), GetGLNoName.AccAmortnonIntangiblesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.IntangibleAssetsTotal(), GetGLNoName.IntangibleAssetsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.FixedAssetsTotal(), GetGLNoName.FixedAssetsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TOTALASSETS(), GetGLNoName.TotalAssetsName(), 4, 1, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LIABILITIESANDEQUITY(), GetGLNoName.LiabilitiesAndEquityName(), 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Liabilities(), GetGLNoName.LiabilitiesName(), 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ShorttermLiabilities(), GetGLNoName.ShorttermLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.RevolvingCredit(), GetGLNoName.RevolvingCreditName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DeferredRevenue(), GetGLNoName.DeferredRevenueName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SalesPrepayments(), GetGLNoName.SalesPrepaymentsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CustomerPrepaymentsSERVICES(), GetGLNoName.CustomerPrepaymentsSERVICESName(), 0, 1, 0, '', 0, '', DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(GetGLNoName.CustomerPrepaymentsRETAIL(), GetGLNoName.CustomerPrepaymentsRETAILName(), 0, 1, 0, '', 0, '', DemoDataSetup.RetailCode(), '', '', true);
        InsertData(GetGLNoName.SalesPrepaymentsTotal(), GetGLNoName.SalesPrepaymentsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccountsPayable(), GetGLNoName.AccountsPayableName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.VendorsDomestic(), GetGLNoName.VendorsDomesticName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.VendorsForeign(), GetGLNoName.VendorsForeignName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccountsPayableEmployees(), GetGLNoName.AccountsPayableEmployeesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccruedPayables(), GetGLNoName.AccruedPayablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccountsPayableTotal(), GetGLNoName.AccountsPayableTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InvAdjmtInterim(), GetGLNoName.InvAdjmtInterimName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InvAdjmtInterimRawMat(), GetGLNoName.InvAdjmtInterimRawMatName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InvAdjmtInterimRetail(), GetGLNoName.InvAdjmtInterimRetailName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.InvAdjmtInterimTotal(), GetGLNoName.InvAdjmtInterimTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TaxesPayables(), GetGLNoName.TaxesPayablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.IncomeTaxPayable(), GetGLNoName.IncomeTaxPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ProvincialSalesTax(), GetGLNoName.ProvincialSalesTaxName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.QSTSalesTaxCollected(), GetGLNoName.QSTSalesTaxCollectedName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PurchaseTax(), GetGLNoName.PurchaseTaxName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.GSTHSTSalesTax(), GetGLNoName.GSTHSTSalesTaxName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.GSTHSTInputCredits(), GetGLNoName.GSTHSTInputCreditsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.IncomeTaxAccrued(), GetGLNoName.IncomeTaxAccruedName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.QuebecBeerTaxesAccrued(), GetGLNoName.QuebecBeerTaxesAccruedName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TaxesPayablesTotal(), GetGLNoName.TaxesPayablesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PrepaidServiceContracts(), GetGLNoName.PrepaidServiceContractsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PersonnelrelatedItems(), GetGLNoName.PersonnelrelatedItemsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.AccruedSalariesWages(), GetGLNoName.AccruedSalariesWagesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.FederalIncomeTaxExpense(), GetGLNoName.FederalIncomeTaxExpenseName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ProvincialWithholdingPayable(), GetGLNoName.ProvincialWithholdingPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.PayrollTaxesPayable(), GetGLNoName.PayrollTaxesPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.FICAPayable(), GetGLNoName.FICAPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.MedicarePayable(), GetGLNoName.MedicarePayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.FUTAPayable(), GetGLNoName.FUTAPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.SUTAPayable(), GetGLNoName.SUTAPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.EmployeeBenefitsPayable(), GetGLNoName.EmployeeBenefitsPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.EmploymentInsuranceEmployeeContrib(), GetGLNoName.EmploymentInsuranceEmployeeContribName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.EmploymentInsuranceEmployerContrib(), GetGLNoName.EmploymentInsuranceEmployerContribName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CanadaPensionFundEmployeeContrib(), GetGLNoName.CanadaPensionFundEmployeeContribName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CanadaPensionFundEmployerContrib(), GetGLNoName.CanadaPensionFundEmployerContribName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.QuebecPIPPayableEmployee(), GetGLNoName.QuebecPIPPayableEmployeeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.GarnishmentPayable(), GetGLNoName.GarnishmentPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.VacationCompensationPayable(), GetGLNoName.VacationCompensationPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.EmployeesPayable(), GetGLNoName.EmployeesPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalPersonnelrelatedItems(), GetGLNoName.TotalPersonnelrelatedItemsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OtherLiabilities(), GetGLNoName.OtherLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DividendsfortheFiscalYear(), GetGLNoName.DividendsfortheFiscalYearName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CorporateTaxesPayable(), GetGLNoName.CorporateTaxesPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.OtherLiabilitiesTotal(), GetGLNoName.OtherLiabilitiesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.ShorttermLiabilitiesTotal(), GetGLNoName.ShorttermLiabilitiesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LongtermLiabilities(), GetGLNoName.LongtermLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LongtermBankLoans(), GetGLNoName.LongtermBankLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Mortgage(), GetGLNoName.MortgageName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DeferredTaxes(), GetGLNoName.DeferredTaxesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.DeferralRevenue(), GetGLNoName.DeferralRevenueName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.LongtermLiabilitiesTotal(), GetGLNoName.LongtermLiabilitiesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalLiabilities(), GetGLNoName.TotalLiabilitiesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.Equity(), GetGLNoName.EquityName(), 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.CapitalStock(), GetGLNoName.CapitalStockName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.RetainedEarnings(), GetGLNoName.RetainedEarningsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.NetIncomefortheYear(), GetGLNoName.NetIncomefortheYearName(), 2, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TotalStockholdersEquity(), GetGLNoName.TotalStockholdersEquityName(), 2, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GetGLNoName.TOTALLIABILITIESANDEQUITY(), GetGLNoName.TOTALLIABILITIESANDEQUITYName(), 2, 1, 1, '', 0, '', '', '', '', true);
    end;

    procedure InsertData(AccountNo: Code[20]; AccountName: Text[100]; AccountType: Option; IncomeBalance: Option; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectPosting: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", Adjust.Convert(AccountNo));
        GLAccount.Validate(Name, AccountName);
        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then begin
            GLAccount.Validate("Direct Posting", DirectPosting);
            if GenProdPostingGroup = DemoDataSetup.NoVATCode() then
                GLAccount."Tax Group Code" := XNONTAXABLE
            else
                GLAccount."Tax Group Code" := XTAXABLE;
        end;
        GLAccount.Validate("Income/Balance", "G/L Account Report Type".FromInteger(IncomeBalance));
        case GLAccount."No." of
            Adjust.Convert('11110'), Adjust.Convert('992910'), Adjust.Convert('992920'), Adjust.Convert('992930'), Adjust.Convert('992940'), Adjust.Convert('995310'):
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
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            if VATGenPostingGroup <> '' then
                GLAccount.Validate("VAT Bus. Posting Group", VATGenPostingGroup);
            if VATProdPostingGroup <> '' then
                GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        end;
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
                UpdateGLAccounts(GLAccountCategory, '992300', '992390');
            GLAccountCategoryMgt.GetPrepaidExpenses():
                begin
                    UpdateGLAccounts(GLAccountCategory, '992200', '992200');
                    UpdateGLAccounts(GLAccountCategory, '992400', '992440');
                end;
            GLAccountCategoryMgt.GetInventory():
                UpdateGLAccounts(GLAccountCategory, '992100', '992190');
            GLAccountCategoryMgt.GetEquipment():
                UpdateGLAccounts(GLAccountCategory, '991003', '991290');
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

    procedure AddCategoriesToGLAccountsForMini()
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

    procedure AssignCategoryToChartOfAccountsForMini(GLAccountCategory: Record "G/L Account Category")
    begin
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Assets:
                UpdateGLAccounts(GLAccountCategory, '10000', '19950');
            GLAccountCategory."Account Category"::Liabilities:
                UpdateGLAccounts(GLAccountCategory, '20000', '25995');
            GLAccountCategory."Account Category"::Equity:
                UpdateGLAccounts(GLAccountCategory, '30000', '39950');
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, '40000', '49950');
                    UpdateGLAccounts(GLAccountCategory, '72400', '73000');
                end;
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                UpdateGLAccounts(GLAccountCategory, '50000', '59950');
            GLAccountCategory."Account Category"::Expense:
                begin
                    UpdateGLAccounts(GLAccountCategory, '60000', '69950');
                    UpdateGLAccounts(GLAccountCategory, '70000', '76200');
                    UpdateGLAccounts(GLAccountCategory, '80000', '81400');
                end;
        end;
    end;

    procedure AssignSubcategoryToChartOfAccountsForMini(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCash():
                UpdateGLAccounts(GLAccountCategory, '11200', '11600');
            GLAccountCategoryMgt.GetAR():
                UpdateGLAccounts(GLAccountCategory, '13100', '13350');
            GLAccountCategoryMgt.GetPrepaidExpenses():
                UpdateGLAccounts(GLAccountCategory, '13510', '13530');
            GLAccountCategoryMgt.GetInventory():
                UpdateGLAccounts(GLAccountCategory, '14100', '14300');
            GLAccountCategoryMgt.GetEquipment():
                begin
                    UpdateGLAccounts(GLAccountCategory, '16200', '16220');
                    UpdateGLAccounts(GLAccountCategory, '17100', '17120');
                end;
            GLAccountCategoryMgt.GetAccumDeprec():
                begin
                    UpdateGLAccounts(GLAccountCategory, '16300', '16300');
                    UpdateGLAccounts(GLAccountCategory, '17200', '17200');
                    UpdateGLAccounts(GLAccountCategory, '18200', '18200');
                end;
            GLAccountCategoryMgt.GetCurrentLiabilities():
                begin
                    UpdateGLAccounts(GLAccountCategory, '22100', '22100');
                    UpdateGLAccounts(GLAccountCategory, '22160', '22180');
                    UpdateGLAccounts(GLAccountCategory, '22300', '22450');
                    UpdateGLAccounts(GLAccountCategory, '22700', '22780');
                    UpdateGLAccounts(GLAccountCategory, '24300', '24300');
                end;
            GLAccountCategoryMgt.GetPayrollLiabilities():
                UpdateGLAccounts(GLAccountCategory, '23050', '23300');
            GLAccountCategoryMgt.GetLongTermLiabilities():
                UpdateGLAccounts(GLAccountCategory, '25100', '25300');
            GLAccountCategoryMgt.GetCommonStock():
                UpdateGLAccounts(GLAccountCategory, '30100', '30100');
            GLAccountCategoryMgt.GetRetEarnings():
                UpdateGLAccounts(GLAccountCategory, '30200', '30200');
            GLAccountCategoryMgt.GetIncomeService():
                begin
                    UpdateGLAccounts(GLAccountCategory, '41450', '41450');
                    UpdateGLAccounts(GLAccountCategory, '42100', '42300');
                    UpdateGLAccounts(GLAccountCategory, '43100', '43300');
                    UpdateGLAccounts(GLAccountCategory, '45000', '45100');
                end;
            GLAccountCategoryMgt.GetIncomeProdSales():
                UpdateGLAccounts(GLAccountCategory, '44100', '44300');
            GLAccountCategoryMgt.GetIncomeSalesDiscounts():
                UpdateGLAccounts(GLAccountCategory, '45200', '45200');
            GLAccountCategoryMgt.GetCOGSLabor():
                begin
                    UpdateGLAccounts(GLAccountCategory, '51000', '51000');
                    UpdateGLAccounts(GLAccountCategory, '52200', '52200');
                end;
            GLAccountCategoryMgt.GetCOGSMaterials():
                begin
                    UpdateGLAccounts(GLAccountCategory, '53100', '53200');
                    UpdateGLAccounts(GLAccountCategory, '54100', '54300');
                    UpdateGLAccounts(GLAccountCategory, '54500', '54500');
                end;
            GLAccountCategoryMgt.GetCOGSDiscountsGranted():
                UpdateGLAccounts(GLAccountCategory, '54800', '54800');
            GLAccountCategoryMgt.GetRentExpense():
                UpdateGLAccounts(GLAccountCategory, '64450', '64450');
            GLAccountCategoryMgt.GetAdvertisingExpense():
                UpdateGLAccounts(GLAccountCategory, '61100', '61200');
            GLAccountCategoryMgt.GetTravelExpense():
                UpdateGLAccounts(GLAccountCategory, '61300', '61300');
            GLAccountCategoryMgt.GetInterestExpense():
                UpdateGLAccounts(GLAccountCategory, '68100', '68470');
            GLAccountCategoryMgt.GetFeesExpense():
                UpdateGLAccounts(GLAccountCategory, '63200', '63200');
            GLAccountCategoryMgt.GetPayrollExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '62100', '62100');
                    UpdateGLAccounts(GLAccountCategory, '62300', '62800');
                end;
            GLAccountCategoryMgt.GetSalariesExpense():
                UpdateGLAccounts(GLAccountCategory, '62200', '62200');
            GLAccountCategoryMgt.GetVehicleExpenses():
                UpdateGLAccounts(GLAccountCategory, '63100', '63100');
            GLAccountCategoryMgt.GetRepairsExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '63300', '63300');
                    UpdateGLAccounts(GLAccountCategory, '65300', '65300');
                end;
            GLAccountCategoryMgt.GetUtilitiesExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '65100', '65200');
                    UpdateGLAccounts(GLAccountCategory, '65600', '65800');
                end;
            GLAccountCategoryMgt.GetOtherIncomeExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '48100', '48500');
                    UpdateGLAccounts(GLAccountCategory, '64100', '64300');
                    UpdateGLAccounts(GLAccountCategory, '66100', '66300');
                    UpdateGLAccounts(GLAccountCategory, '67100', '67100');
                    UpdateGLAccounts(GLAccountCategory, '67300', '67500');
                    UpdateGLAccounts(GLAccountCategory, '47400', '47520');
                    UpdateGLAccounts(GLAccountCategory, '85200', '85200');
                end;
            GLAccountCategoryMgt.GetBadDebtExpense():
                UpdateGLAccounts(GLAccountCategory, '67200', '67200');
            GLAccountCategoryMgt.GetTaxExpense():
                UpdateGLAccounts(GLAccountCategory, '84100', '84200');
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
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Liabilities:
                begin
                    UpdateGLAccounts(GLAccountCategory, '993000', '993000');
                    UpdateGLAccounts(GLAccountCategory, '995000', '995000');
                    UpdateGLAccounts(GLAccountCategory, '995997', '995997');
                end;
            GLAccountCategory."Account Category"::Equity:
                begin
                    UpdateGLAccounts(GLAccountCategory, '8030000', '8030000');
                    UpdateGLAccounts(GLAccountCategory, '993195', '993199');
                end;
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, '998995', '998995');
                    UpdateGLAccounts(GLAccountCategory, '999100', '999190');
                    UpdateGLAccounts(GLAccountCategory, '999310', '999310');
                    UpdateGLAccounts(GLAccountCategory, '999330', '999330');
                    UpdateGLAccounts(GLAccountCategory, '999410', '999410');
                    UpdateGLAccounts(GLAccountCategory, '8059999', '8059999');
                    UpdateGLAccounts(GLAccountCategory, '8085000', '8085300');
                    UpdateGLAccounts(GLAccountCategory, '8080700', '8080700');
                end;
            GLAccountCategory."Account Category"::Expense:
                begin
                    UpdateGLAccounts(GLAccountCategory, '998000', '998994');
                    UpdateGLAccounts(GLAccountCategory, '999320', '999320');
                    UpdateGLAccounts(GLAccountCategory, '999340', '999340');
                end;
        end;
    end;

    local procedure AssignSubcategoryToLocalChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        GLAccountCategory.Find();
        // Reserved for local chart of accounts
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetIncomeProdSales():
                UpdateGLAccounts(GLAccountCategory, '996100', '996695');
            GLAccountCategoryMgt.GetIncomeService():
                UpdateGLAccounts(GLAccountCategory, '996950', '996959');
            GLAccountCategoryMgt.GetOtherIncomeExpense():
                UpdateGLAccounts(GLAccountCategory, '998600', '998690');
            GLAccountCategoryMgt.GetTaxExpense():
                UpdateGLAccounts(GLAccountCategory, '8084000', '8084500');
        end;
    end;

    procedure AssignGIFICode(AccountNo: Code[20]; GIFICode: Code[10])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        GLAccount.Validate("GIFI Code", GIFICode);
        GLAccount.Modify();
    end;
}
