codeunit 101015 "Create G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            InsertData('991000', XSTMTOFFINANCIALPOSITION, 1, 1, 0, '', 0, '', '', '', '', true);
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
            InsertData('992940', XBankOther, 0, 1, 0, '', 0, '', '', '', '', false);
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
            InsertData('995491', XWHT, 3, 1, 0, '', 0, '', '', '', '', true);
            InsertData('995492', XWHTPrepaid, 0, 1, 0, '', 0, '', '', '', '', true);
            InsertData('995493', XWHTPayable, 0, 1, 0, '', 0, '', '', '', '', true);
            InsertData('995494', XWHTSettlement, 0, 1, 0, '', 0, '', '', '', '', true);
            InsertData('995495', XWHTRounding, 0, 1, 0, '', 0, '', '', '', '', true);
            InsertData('995499', XWHTTotal, 4, 1, 0, '', 0, '', '', '', '', true);
            InsertData('995500', XInvAdjmtInterim, 3, 1, 0, '', 0, '', '', '', '', true);
            InsertData('995510', XInvAdjmtInterimRetail, 0, 1, 0, '', 0, '', '', '', '', false);
            InsertData('995530', XInvAdjmtInterimRawMat, 0, 1, 0, '', 0, '', '', '', '', false);
            InsertData('995590', XInvAdjmtInterimTotal, 4, 1, 0, '', 0, '', '', '', '', true);
            InsertData('995600', XVAT, 3, 1, 0, '', 0, '', '', '', '', true);
            case DemoDataSetup."Company Type" of
                DemoDataSetup."Company Type"::"Sales Tax":
                    begin
                        InsertData('995610', XUSSalesTAXGA, 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995611', XusSalesTAXFL, 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995612', XUSSalesTAXIL, 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995620', XUseUSTAXGAReverse, 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995621', XUseUSTAXFLReverse, 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995622', XUseUSTAXILReverse, 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995630', XUseUSTAXGA, 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995631', XUseUSTAXFL, 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995632', XUseUSTAXIL, 0, 1, 0, '', 0, '', '', '', '', false);
                        if DemoDataSetup."Advanced Setup" then begin
                            InsertData('995615', XUSSalesTAXGAUnrealized, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995625', XUseUSTAXGAReverseUnrealized, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995635', XUseUSTAXGAUnrealized, 0, 1, 0, '', 0, '', '', '', '', false);
                        end;
                    end;
                DemoDataSetup."Company Type"::VAT:
                    begin
                        InsertData('995610', XSalesVAT25PERCENT, 0, 1, 0, '', 0, '', '', '', '', false);
                        InsertData('995611', XSalesVAT10PERCENT, 0, 1, 0, '', 0, '', '', '', '', false);
                        if DemoDataSetup."Advanced Setup" then begin
                            InsertData('995620', XInputTaxCredit25MISC, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995621', XInputTaxCredit10MISC, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995615', XSalesVAT25PERCENTUnrealized, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995616', XSalesVAT10PERCENTUnrealized, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995625', XInputTaxCredit25MISCUnreal, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995626', XInputTaxCredit10MISCUnreal, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995630', XInputTaxCredit25, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995631', XInputTaxCredit10, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995635', XInputTaxCredit25Unrealized, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995636', XInputTaxCredit10Unrealized, 0, 1, 0, '', 0, '', '', '', '', false);
                        end else begin
                            InsertData('995620', XInputTaxCredit25, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995621', XInputTaxCredit10, 0, 1, 0, '', 0, '', '', '', '', false);
                            InsertData('995630', XPurchaseVAT25PERCENT, 0, 1, 0, '', 0, '', '', '', '', false);
                        end;

                    end;
            end;
            InsertData('995640', XVAT, 0, 1, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', false);
            InsertData('995650', XInputTaxedCredit, 0, 1, 0, '', 0, '', '', '', '', false);
            InsertData('995660', XReverseChargeAccount, 0, 1, 0, '', 0, '', '', '', '', false);
            InsertData('995670', XAmountsWithheldNoABN, 0, 1, 0, '', 0, '', '', '', '', false);
            InsertData('995780', XTAXPayable, 0, 1, 0, '', 0, '', '', '', '', true);
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
            InsertData('996111', XStockSales, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
            InsertData('996112', XHireIncome, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
            InsertData('996113', XRentalIncome, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
            InsertData('996130', XSalesRetailExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
            InsertData('996190', XJobSalesAppRetail, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('996191', XJobSalesAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('996195', XTotalSalesofRetail, 4, 0, 0, '', 0, '', '', '', '', true);
            InsertData('996205', XSalesofRawMaterials, 3, 0, 0, '', 0, '', '', '', '', true);
            InsertData('996210', XSalesRawMaterialsDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', false);
            InsertData('996230', XSalesRawMaterialsExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
            InsertData('996290', XJobSalesAppRawMat, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('996291', XJobSalesAdjmtRawMat, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('996295', XTotalSalesofRawMaterials, 4, 0, 0, '', 0, '', '', '', '', true);
            InsertData('996405', XSalesofResources, 3, 0, 0, '', 0, '', '', '', '', true);
            InsertData('996410', XSalesResourcesDom, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', false);
            InsertData('996430', XSalesResourcesExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '', '', true);
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
            InsertData('997130', XPurchRetailExport, 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
            InsertData('997140', XDiscReceivedRetail, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('997150', XFreightExpensesRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('997170', XInventoryAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('997180', XJobCostAppRetail, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('997181', XJobCostAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('997190', XCostofRetailSold, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('997195', XTotalCostofRetail, 4, 0, 0, '', 0, '', '', '', '', true);
            InsertData('997205', XCostofRawMaterials, 3, 0, 0, '', 0, '', '', '', '', true);
            InsertData('997210', XPurchRawMaterialsDom, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', false);
            InsertData('997230', XPurchRawMaterialsExport, 0, 0, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', false);
            InsertData('997240', XDiscReceivedRawMaterials, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('997250', XFreightExpensesRawMat, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
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
            InsertData('998240', XPostage, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('998290', XTotalAdministrativeExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998300', XComputerExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998310', XSoftware, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('998320', XConsultantServices, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
            InsertData('998330', XOtherComputerExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('998390', XTotalComputerExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998400', XSellingExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998410', XAdvertising, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('998420', XEntertainmentandPR, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('998430', XTravel, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('998450', XFreightExpensesRawMat, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('998490', XTotalSellingExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998500', XVehicleExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998510', XGasolineandMotorOil, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('998520', XRegistrationFees, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
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
            InsertData('998740', XAnnualLeaveExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998750', XPayrollTaxes, 0, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998790', XTotalPersonnelExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998800', XDepreciationofFixedAssets, 3, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998810', XDepreciationBuildings, 0, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998820', XDepreciationEquipment, 0, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998830', XDepreciationVehicles, 0, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998840', XGainsandLosses, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('998890', XTotalFixedAssetDepreciation, 4, 0, 0, '', 0, '', '', '', '', true);
            InsertData('998910', XOtherCostsofOperations, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('998920', XPURCHWHTAdjustments, 0, 0, 0, '', 1, '', '', '', '', true);
            InsertData('998930', XSalesWHTAdjustments, 0, 0, 0, '', 2, '', '', '', '', true);
            InsertData('998995', XNetOperatingIncome, 2, 0, 1,
              Adjust.Convert('996000') + '..' + Adjust.Convert('998995'), 0, '', '', '', '', true);
            InsertData('999100', XInterestIncome, 3, 0, 1, '', 0, '', '', '', '', true);
            InsertData('999110', XInterestonBankBalances, 0, 0, 0, '', 0, '', '', '', '', true);
            InsertData('999120', XFinanceChargesfromCustomers, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
            InsertData('999130', XPaymentDiscountsReceived, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('999135', XPmtDiscReceivedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('999160', XPaymentToleranceReceived, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('999170', XPmtTolReceivedDecreases, 0, 0, 0, '', 0, '', '', '', '', false);
            InsertData('999140', XInvoiceRounding, 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
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
            AddCategoriesToGLAccounts();
        end
        else
            InsertMiniAppData();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Adjust: Codeunit "Make Adjustments";
        GLAccIndent: Codeunit "G/L Account-Indent";
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
        XSalesVAT25PERCENT: Label 'Sales VAT 25 %';
        XSalesVAT10PERCENT: Label 'Sales VAT 10 %';
        XSalesVAT25PERCENTUnrealized: Label 'Sales VAT 25 % Unrealized';
        XSalesVAT10PERCENTUnrealized: Label 'Sales VAT 10 % Unrealized';
        XPurchaseVAT25PERCENT: Label 'Purchase VAT 25 %';
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
        XSalesRetailExport: Label 'Sales, Retail - Export';
        XJobSalesAdjmtRetail: Label 'Job Sales Adjmt., Retail';
        XTotalSalesofRetail: Label 'Total Sales of Retail';
        XSalesofRawMaterials: Label 'Sales of Raw Materials';
        XSalesRawMaterialsDom: Label 'Sales, Raw Materials - Dom.';
        XSalesRawMaterialsExport: Label 'Sales, Raw Materials - Export';
        XJobSalesAdjmtRawMat: Label 'Job Sales Adjmt., Raw Mat.';
        XTotalSalesofRawMaterials: Label 'Total Sales of Raw Materials';
        XSalesofResources: Label 'Sales of Resources';
        XSalesResourcesDom: Label 'Sales, Resources - Dom.';
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
        XPurchRetailExport: Label 'Purch., Retail - Export';
        XDiscReceivedRetail: Label 'Disc. Received, Retail';
        XInventoryAdjmtRetail: Label 'Inventory Adjmt., Retail';
        XJobCostAdjmtRetail: Label 'Job Cost Adjmt., Retail';
        XCostofRetailSold: Label 'Cost of Retail Sold';
        XTotalCostofRetail: Label 'Total Cost of Retail';
        XCostofRawMaterials: Label 'Cost of Raw Materials';
        XPurchRawMaterialsDom: Label 'Purch., Raw Materials - Dom.';
        XPurchRawMaterialsExport: Label 'Purch., Raw Materials - Export';
        XDiscReceivedRawMaterials: Label 'Disc. Received, Raw Materials';
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
        XSTMTOFFINANCIALPOSITION: Label 'STMT. OF FINANCIAL POSITION';
        XBankOther: Label 'Bank, Other';
        XUSSalesTAXGA: Label 'US Sales TAX GA';
        XusSalesTAXFL: Label 'US Sales TAX FL';
        XUSSalesTAXIL: Label 'US Sales TAX IL';
        XUseUSTAXGAReverse: Label 'Use US TAX GA Reverse';
        XUseUSTAXFLReverse: Label 'Use US TAX FL Reverse';
        XUseUSTAXILReverse: Label 'Use US TAX IL Reverse';
        XUseUSTAXFL: Label 'Use US TAX FL';
        XUseUSTAXIL: Label 'Use US TAX IL';
        XUseUSTAXGA: Label 'Use US TAX GA';
        XUseUSTAXGAUnrealized: Label 'Use US TAX GA Unrealized';
        XUSSalesTAXGAUnrealized: Label 'US Sales TAX GA Unrealized';
        XUseUSTAXGAReverseUnrealized: Label 'Use US TAX GA Reverse Unreal.';
        XInputTaxCredit25: Label 'Input Tax Cr. 25';
        XInputTaxCredit10: Label 'Input Tax Cr. 10 ';
        XInputTaxCredit25MISC: Label 'Input Tax Cr. 25 MISC';
        XInputTaxCredit10MISC: Label 'Input Tax Cr. 10 MISC';
        XInputTaxCredit25MISCUnreal: Label 'Input Tax Cr. 25% MISC Unreal.';
        XInputTaxCredit10MISCUnreal: Label 'Input Tax Cr. 10% MISC Unreal.';
        XInputTaxCredit25Unrealized: Label 'Input Tax Cr. 25% Unrealized';
        XInputTaxCredit10Unrealized: Label 'Input Tax Cr. 10% Unrealized';
        XTAXPayable: Label 'TAX Payable';
        XStockSales: Label 'Stock Sales';
        XHireIncome: Label 'Hire Income';
        XRentalIncome: Label 'Rental Income';
        XFreightExpensesRawMat: Label 'Freight Expenses, Raw Mat.';
        XFreightExpensesRetail: Label 'Freight Expenses, Retail';
        XAnnualLeaveExpenses: Label 'Annual Leave Expenses';
        XInputTaxedCredit: Label 'Input Taxed Credit';
        XReverseChargeAccount: Label 'Reverse Charge Account';
        XAmountsWithheldNoABN: Label 'Amounts Withheld - No ABN';
        XWHT: Label 'WHT';
        XWHTPrepaid: Label 'WHT Prepaid';
        XWHTPayable: Label 'WHT Payable';
        XWHTSettlement: Label 'WHT Settlement';
        XWHTTotal: Label 'WHT, Total';
        XPURCHWHTAdjustments: Label 'Purchase WHT Adjustments';
        XSalesWHTAdjustments: Label 'Sales WHT Adjustments';
        XWHTRounding: Label 'WHT Rounding';
        STMTOFFINANCIALPOSITIONTOK: Label 'STMT. OF FINANCIAL POSITION', MaxLength = 100;
        ASSETSTOK: Label 'ASSETS', MaxLength = 100;
        CurrentAssetsTOK: Label 'Current Assets', MaxLength = 100;
        LiquidAssetsTOK: Label 'Liquid Assets', MaxLength = 100;
        CashTOK: Label 'Cash', MaxLength = 100;
        BankLCYTOK: Label 'Bank, LCY', MaxLength = 100;
        BankCurrenciesTOK: Label 'Bank Currencies', MaxLength = 100;
        BankOtherTOK: Label 'Bank, Other', MaxLength = 100;
        LiquidAssetsTotalTOK: Label 'Liquid Assets, Total', MaxLength = 100;
        AccountsReceivableTOK: Label 'Accounts Receivable', MaxLength = 100;
        CustomersDomesticTOK: Label 'Customers Domestic', MaxLength = 100;
        CustomersForeignTOK: Label 'Customers, Foreign', MaxLength = 100;
        CustomersIntercompanyTOK: Label 'Customers, Intercompany', MaxLength = 100;
        AccruedInterestTOK: Label 'Accrued Interest', MaxLength = 100;
        OtherReceivablesTOK: Label 'Other Receivables', MaxLength = 100;
        AccountsReceivableTotalTOK: Label 'Accounts Receivable, Total', MaxLength = 100;
        InventoryTOK: Label 'Inventory', MaxLength = 100;
        ResaleItemsTOK: Label 'Resale Items', MaxLength = 100;
        ResaleItemsInterimTOK: Label 'Resale Items (Interim)', MaxLength = 100;
        CostofResaleSoldInterimTOK: Label 'Cost of Resale Sold (Interim)', MaxLength = 100;
        FinishedGoodsTOK: Label 'Finished Goods', MaxLength = 100;
        FinishedGoodsInterimTOK: Label 'Finished Goods (Interim)', MaxLength = 100;
        RawMaterialsTOK: Label 'Raw Materials', MaxLength = 100;
        RawMaterialsInterimTOK: Label 'Raw Materials (Interim)', MaxLength = 100;
        CostofRawMatSoldInterimTOK: Label 'Cost of Raw Mat.Sold (Interim)', MaxLength = 100;
        WIPAccountFinishedgoodsTOK: Label 'WIP Account, Finished goods', MaxLength = 100;
        PrimoInventoryTOK: Label 'Primo Inventory', MaxLength = 100;
        InventoryTotalTOK: Label 'Inventory, Total', MaxLength = 100;
        JobWIPTOK: Label 'Job WIP', MaxLength = 100;
        WIPSalesTOK: Label 'WIP Sales', MaxLength = 100;
        WIPJobSalesTOK: Label 'WIP Job Sales', MaxLength = 100;
        InvoicedJobSalesTOK: Label 'Invoiced Job Sales', MaxLength = 100;
        WIPSalesTotalTOK: Label 'WIP Sales, Total', MaxLength = 100;
        WIPCostsTOK: Label 'WIP Costs', MaxLength = 100;
        WIPJobCostsTOK: Label 'WIP Job Costs', MaxLength = 100;
        AccruedJobCostsTOK: Label 'Accrued Job Costs', MaxLength = 100;
        WIPCostsTotalTOK: Label 'WIP Costs, Total', MaxLength = 100;
        JobWIPTotalTOK: Label 'Job WIP, Total', MaxLength = 100;
        TotalCurrentAssetsTOK: Label 'Total Current Assets', MaxLength = 100;
        NonCurrentAssetsTOK: Label 'Non-Current Assets', MaxLength = 100;
        FinancialAssetsTOK: Label 'Financial Assets', MaxLength = 100;
        InvestmentsTOK: Label 'Investments', MaxLength = 100;
        OtherFinancialassetsTOK: Label 'Other Financial assets', MaxLength = 100;
        PurchasePrepaymentsTOK: Label 'Purchase Prepayments', MaxLength = 100;
        TotalFinancialAssetsTOK: Label 'Total Financial Assets', MaxLength = 100;
        TangibleFixedAssetsTOK: Label 'Tangible Fixed Assets', MaxLength = 100;
        LandandBuildingsTOK: Label 'Land and Buildings', MaxLength = 100;
        AccumDepreciationBuildingsTOK: Label 'Accum. Depreciation, Buildings', MaxLength = 100;
        LandandBuildingsTotalTOK: Label 'Land and Buildings, Total', MaxLength = 100;
        OfficeEquipmentTOK: Label 'Office Equipment', MaxLength = 100;
        AccumDeprOperEquipTOK: Label 'Accum. Depr., Oper. Equip.', MaxLength = 100;
        OfficeEquipmentTotalTOK: Label 'Office Equipment, Total', MaxLength = 100;
        VehiclesTOK: Label 'Vehicles', MaxLength = 100;
        AccumDepreciationVehiclesTOK: Label 'Accum. Depreciation, Vehicles', MaxLength = 100;
        VehiclesTotalTOK: Label 'Vehicles, Total', MaxLength = 100;
        TangibleFixedAssetsTotalTOK: Label 'Tangible Fixed Assets, Total', MaxLength = 100;
        IntangibleAssetsTOK: Label 'Intangible Assets', MaxLength = 100;
        AccAmortnonIntangiblesTOK: Label 'Acc. Amortn on Intangibles', MaxLength = 100;
        IntangibleAssetsTotalTOK: Label 'Intangible Assets, Total', MaxLength = 100;
        RighttouseassetsTOK: Label 'Right to use assets', MaxLength = 100;
        RighttouseleasesTOK: Label 'Right to use leases', MaxLength = 100;
        AccAmortnonRightofuseLeasesTOK: Label 'Acc. Amortn on Right of use  Leases', MaxLength = 100;
        RighttouseassetsTotalTOK: Label 'Right to use assets, Total', MaxLength = 100;
        TotalNonCurrentAssetsTOK: Label 'Total Non Current Assets', MaxLength = 100;
        TotalAssetsTOK: Label 'Total Assets', MaxLength = 100;
        LiabilitiesTOK: Label 'Liabilities', MaxLength = 100;
        LongtermLiabilitiesTOK: Label 'Long-term Liabilities', MaxLength = 100;
        LongtermBankLoansTOK: Label 'Long-term Bank Loans', MaxLength = 100;
        MortgageTOK: Label 'Mortgage', MaxLength = 100;
        LongtermLiabilitiesTotalTOK: Label 'Long-term Liabilities, Total', MaxLength = 100;
        ShorttermLiabilitiesTOK: Label 'Short-term Liabilities', MaxLength = 100;
        RevolvingCreditTOK: Label 'Revolving Credit', MaxLength = 100;
        SalesPrepaymentsTOK: Label 'Sales Prepayments', MaxLength = 100;
        PrepaidServiceContractsTOK: Label 'Prepaid Service Contracts', MaxLength = 100;
        DeferredRevenueTOK: Label 'Deferred Revenue', MaxLength = 100;
        DeferredTaxesTOK: Label 'Deferred Taxes', MaxLength = 100;
        TradeandOtherPayablesTOK: Label 'Trade and Other Payables', MaxLength = 100;
        AccountspayableTOK: Label 'Accounts payable', MaxLength = 100;
        VendorsDomesticTOK: Label 'Vendors, Domestic', MaxLength = 100;
        VendorsForeignTOK: Label 'Vendors, Foreign', MaxLength = 100;
        VendorsIntercompanyTOK: Label 'Vendors, Intercompany', MaxLength = 100;
        AccruedExpensesTOK: Label 'Accrued Expenses', MaxLength = 100;
        ProvisionforIncomeTaxTOK: Label 'Provision for Income Tax', MaxLength = 100;
        ProvisionforAnnualLeaveTOK: Label 'Provision for Annual Leave', MaxLength = 100;
        SuperannuationclearingTOK: Label 'Superannuation clearing', MaxLength = 100;
        PayrollclearingTOK: Label 'Payroll clearing', MaxLength = 100;
        PayrollDeductionsTOK: Label 'Payroll Deductions', MaxLength = 100;
        InvAdjmtInterimTOK: Label 'Inv. Adjmt. (Interim)', MaxLength = 100;
        InvAdjmtInterimRawMatTOK: Label 'Inv. Adjmt. (Interim), Raw Mat', MaxLength = 100;
        InvAdjmtInterimRetailTOK: Label 'Inv. Adjmt. (Interim), Retail', MaxLength = 100;
        InvAdjmtInterimTotalTOK: Label 'Inv. Adjmt. (Interim), Total', MaxLength = 100;
        TaxesPayablesTOK: Label 'Taxes Payables', MaxLength = 100;
        GSTPayableTOK: Label 'GST Payable', MaxLength = 100;
        GSTReceivableTOK: Label 'GST Receivable', MaxLength = 100;
        GSTClearingTOK: Label 'GST Clearing', MaxLength = 100;
        GSTReconTOK: Label 'GST Recon', MaxLength = 100;
        WHTTaxPayableTOK: Label 'WHT Tax Payable', MaxLength = 100;
        WHTPrepaidTOK: Label 'WHT Prepaid', MaxLength = 100;
        TaxesPayablesTotalTOK: Label 'Taxes Payables, Total', MaxLength = 100;
        PersonnelrelatedItemsTOK: Label 'Personnel-related Items', MaxLength = 100;
        WithholdingTaxesPayableTOK: Label 'Withholding Taxes Payable', MaxLength = 100;
        SupplementaryTaxesPayableTOK: Label 'Supplementary Taxes Payable', MaxLength = 100;
        PayrollTaxesPayableTOK: Label 'Payroll Taxes Payable', MaxLength = 100;
        VacationCompensationPayableTOK: Label 'Vacation Compensation Payable', MaxLength = 100;
        EmployeesPayableTOK: Label 'Employees Payable', MaxLength = 100;
        TotalPersonnelrelatedItemsTOK: Label 'Total Personnel-related Items', MaxLength = 100;
        UnearnedRevenueOtherTOK: Label 'Unearned Revenue & Other', MaxLength = 100;
        FundsreceivedinadvanceTOK: Label 'Funds received in advance', MaxLength = 100;
        OthercurrentliabilitiesTOK: Label 'Other current liabilities', MaxLength = 100;
        TotalUnearnedRevenueOtherTOK: Label 'Total Unearned Revenue & Other', MaxLength = 100;
        ShorttermLiabilitiesTotalTOK: Label 'Short-term Liabilities, Total', MaxLength = 100;
        NonCurrentLiabilitiesTOK: Label 'Non Current Liabilities', MaxLength = 100;
        EmployeeProvisionsTOK: Label 'Employee Provisions', MaxLength = 100;
        LongserviceleaveTOK: Label 'Long service leave', MaxLength = 100;
        TotalEmployeeProvisionsTOK: Label 'Total Employee Provisions ', MaxLength = 100;
        OtherLiabilitiesTOK: Label 'Other Liabilities', MaxLength = 100;
        DividendsfortheFiscalYearTOK: Label 'Dividends for the Fiscal Year', MaxLength = 100;
        CorporateTaxesPayableTOK: Label 'Corporate Taxes Payable', MaxLength = 100;
        OtherLiabilitiesTotalTOK: Label 'Other Liabilities, Total', MaxLength = 100;
        TotalNonCurrentLiabilitiesTOK: Label 'Total Non Current Liabilities', MaxLength = 100;
        TotalLiabilitiesTOK: Label 'Total Liabilities', MaxLength = 100;
        LIABILITIESANDEQUITYTOK: Label 'LIABILITIES AND EQUITY', MaxLength = 100;
        StockholdersEquityTOK: Label 'Stockholder''s Equity', MaxLength = 100;
        CapitalStockTOK: Label 'Capital Stock', MaxLength = 100;
        RetainedEarningsTOK: Label 'Retained Earnings', MaxLength = 100;
        AllowancesTOK: Label 'Allowances', MaxLength = 100;
        NetIncomefortheYearTOK: Label 'Net Income for the Year', MaxLength = 100;
        TotalStockholdersEquityTOK: Label 'Total Stockholder''s Equity', MaxLength = 100;
        TOTALLIABILITIESANDEQUITYTOK: Label 'TOTAL LIABILITIES AND EQUITY', MaxLength = 100;
        INCOMESTATEMENTTOK: Label 'INCOME STATEMENT', MaxLength = 100;
        RevenueTOK: Label 'Revenue', MaxLength = 100;
        SalesofRetailTOK: Label 'Sales of Retail', MaxLength = 100;
        SalesRetailDomTOK: Label 'Sales, Retail - Dom.', MaxLength = 100;
        StockSalesTOK: Label 'Stock Sales', MaxLength = 100;
        HireIncomeTOK: Label 'Hire Income', MaxLength = 100;
        RentalIncomeTOK: Label 'Rental Income', MaxLength = 100;
        SalesRetailExportTOK: Label 'Sales, Retail - Export', MaxLength = 100;
        JobSalesAppliedRetailTOK: Label 'Job Sales Applied, Retail', MaxLength = 100;
        JobSalesAdjmtRetailTOK: Label 'Job Sales Adjmt., Retail', MaxLength = 100;
        TotalSalesofRetailTOK: Label 'Total Sales of Retail', MaxLength = 100;
        SalesofRawMaterialsTOK: Label 'Sales of Raw Materials', MaxLength = 100;
        SalesRawMaterialsDomTOK: Label 'Sales, Raw Materials - Dom.', MaxLength = 100;
        SalesRawMaterialsExportTOK: Label 'Sales, Raw Materials - Export', MaxLength = 100;
        JobSalesAppliedRawMatTOK: Label 'Job Sales Applied, Raw Mat.', MaxLength = 100;
        JobSalesAdjmtRawMatTOK: Label 'Job Sales Adjmt., Raw Mat.', MaxLength = 100;
        TotalSalesofRawMaterialsTOK: Label 'Total Sales of Raw Materials', MaxLength = 100;
        SalesofResourcesTOK: Label 'Sales of Resources', MaxLength = 100;
        SalesResourcesDomTOK: Label 'Sales, Resources - Dom.', MaxLength = 100;
        SalesResourcesExportTOK: Label 'Sales, Resources - Export', MaxLength = 100;
        JobSalesAppliedResourcesTOK: Label 'Job Sales Applied, Resources', MaxLength = 100;
        JobSalesAdjmtResourcesTOK: Label 'Job Sales Adjmt., Resources', MaxLength = 100;
        TotalSalesofResourcesTOK: Label 'Total Sales of Resources', MaxLength = 100;
        SalesofJobsTOK: Label 'Sales of Jobs', MaxLength = 100;
        SalesOtherJobExpensesTOK: Label 'Sales, Other Job Expenses', MaxLength = 100;
        JobSalesTOK: Label 'Job Sales', MaxLength = 100;
        TotalSalesofJobsTOK: Label 'Total Sales of Jobs', MaxLength = 100;
        SalesofServiceContractsTOK: Label 'Sales of Service Contracts', MaxLength = 100;
        ServiceContractSaleTOK: Label 'Service Contract Sale', MaxLength = 100;
        TotalSaleofServContractsTOK: Label 'Total Sale of Serv. Contracts', MaxLength = 100;
        InterestIncomeTOK: Label 'Interest Income', MaxLength = 100;
        InterestonBankBalancesTOK: Label 'Interest on Bank Balances', MaxLength = 100;
        FinanceChargesfromCustomersTOK: Label 'Finance Charges from Customers', MaxLength = 100;
        PaymentDiscountsReceivedTOK: Label 'Payment Discounts Received', MaxLength = 100;
        PmtDiscReceivedDecreasesTOK: Label 'PmtDisc. Received - Decreases', MaxLength = 100;
        InvoiceRoundingTOK: Label 'Invoice Rounding', MaxLength = 100;
        ApplicationRoundingTOK: Label 'Application Rounding', MaxLength = 100;
        PaymentToleranceReceivedTOK: Label 'Payment Tolerance Received', MaxLength = 100;
        PmtTolReceivedDecreasesTOK: Label 'Pmt. Tol. Received Decreases', MaxLength = 100;
        ConsultingFeesDomTOK: Label 'Consulting Fees - Dom.', MaxLength = 100;
        FeesandChargesRecDomTOK: Label 'Fees and Charges Rec. - Dom.', MaxLength = 100;
        DiscountGrantedTOK: Label 'Discount Granted', MaxLength = 100;
        TotalInterestIncomeTOK: Label 'Total Interest Income', MaxLength = 100;
        TotalRevenueTOK: Label 'Total Revenue', MaxLength = 100;
        CostTOK: Label 'Cost', MaxLength = 100;
        CostofRetailTOK: Label 'Cost of Retail', MaxLength = 100;
        PurchRetailDomTOK: Label 'Purch., Retail - Dom.', MaxLength = 100;
        PurchRetailExportTOK: Label 'Purch., Retail - Export', MaxLength = 100;
        DiscReceivedRetailTOK: Label 'Disc. Received, Retail', MaxLength = 100;
        FreightExpensesRetailTOK: Label 'Freight Expenses, Retail', MaxLength = 100;
        InventoryAdjmtRetailTOK: Label 'Inventory Adjmt., Retail', MaxLength = 100;
        JobCostAppliedRetailTOK: Label 'Job Cost Applied, Retail', MaxLength = 100;
        JobCostAdjmtRetailTOK: Label 'Job Cost Adjmt., Retail', MaxLength = 100;
        CostofRetailSoldTOK: Label 'Cost of Retail Sold', MaxLength = 100;
        DirectCostAppliedRetailTOK: Label 'Direct Cost Applied, Retail', MaxLength = 100;
        OverheadAppliedRetailTOK: Label 'Overhead Applied, Retail', MaxLength = 100;
        PurchaseVarianceRetailTOK: Label 'Purchase Variance, Retail', MaxLength = 100;
        TotalCostofRetailTOK: Label 'Total Cost of Retail', MaxLength = 100;
        CostofRawMaterialsTOK: Label 'Cost of Raw Materials', MaxLength = 100;
        PurchRawMaterialsDomTOK: Label 'Purch., Raw Materials - Dom.', MaxLength = 100;
        PurchRawMaterialsExportTOK: Label 'Purch., Raw Materials - Export', MaxLength = 100;
        DiscReceivedRawMaterialsTOK: Label 'Disc. Received, Raw Materials', MaxLength = 100;
        InventoryAdjmtRawMatTOK: Label 'Inventory Adjmt., Raw Mat.', MaxLength = 100;
        JobCostAppliedRawMatTOK: Label 'Job Cost Applied, Raw Mat.', MaxLength = 100;
        JobCostAdjmtRawMaterialsTOK: Label 'Job Cost Adjmt., Raw Materials', MaxLength = 100;
        CostofRawMaterialsSoldTOK: Label 'Cost of Raw Materials Sold', MaxLength = 100;
        DirectCostAppliedRawmatTOK: Label 'Direct Cost Applied, Rawmat.', MaxLength = 100;
        OverheadAppliedRawmatTOK: Label 'Overhead Applied, Rawmat.', MaxLength = 100;
        PurchaseVarianceRawmatTOK: Label 'Purchase Variance, Rawmat.', MaxLength = 100;
        TotalCostofRawMaterialsTOK: Label 'Total Cost of Raw Materials', MaxLength = 100;
        CostofResourcesTOK: Label 'Cost of Resources', MaxLength = 100;
        JobCostAppliedResourcesTOK: Label 'Job Cost Applied, Resources', MaxLength = 100;
        JobCostAdjmtResourcesTOK: Label 'Job Cost Adjmt., Resources', MaxLength = 100;
        CostofResourcesUsedTOK: Label 'Cost of Resources Used', MaxLength = 100;
        TotalCostofResourcesTOK: Label 'Total Cost of Resources', MaxLength = 100;
        JobCostsTOK: Label 'Job Costs', MaxLength = 100;
        CostofCapacitiesTOK: Label 'Cost of Capacities', MaxLength = 100;
        DirectCostAppliedCapTOK: Label 'Direct Cost Applied, Cap.', MaxLength = 100;
        OverheadAppliedCapTOK: Label 'Overhead Applied, Cap.', MaxLength = 100;
        PurchaseVarianceCapTOK: Label 'Purchase Variance, Cap.', MaxLength = 100;
        TotalCostofCapacitiesTOK: Label 'Total Cost of Capacities', MaxLength = 100;
        VarianceTOK: Label 'Variance', MaxLength = 100;
        MaterialVarianceTOK: Label 'Material Variance', MaxLength = 100;
        CapacityVarianceTOK: Label 'Capacity Variance', MaxLength = 100;
        SubcontractedVarianceTOK: Label 'Subcontracted Variance', MaxLength = 100;
        CapOverheadVarianceTOK: Label 'Cap. Overhead Variance', MaxLength = 100;
        MfgOverheadVarianceTOK: Label 'Mfg. Overhead Variance', MaxLength = 100;
        TotalVarianceTOK: Label 'Total Variance', MaxLength = 100;
        TotalCostTOK: Label 'Total Cost', MaxLength = 100;
        OperatingExpensesTOK: Label 'Operating Expenses', MaxLength = 100;
        BuildingMaintenanceExpensesTOK: Label 'Building Maintenance Expenses', MaxLength = 100;
        CleaningTOK: Label 'Cleaning', MaxLength = 100;
        ElectricityandHeatingTOK: Label 'Electricity and Heating', MaxLength = 100;
        TotalBldgMaintExpensesTOK: Label 'Total Bldg. Maint. Expenses', MaxLength = 100;
        AdministrativeExpensesTOK: Label 'Administrative Expenses', MaxLength = 100;
        OfficeSuppliesTOK: Label 'Office Supplies', MaxLength = 100;
        PhoneandFaxTOK: Label 'Phone and Fax', MaxLength = 100;
        PostageTOK: Label 'Postage', MaxLength = 100;
        TotalAdministrativeExpensesTOK: Label 'Total Administrative Expenses', MaxLength = 100;
        ComputerExpensesTOK: Label 'Computer Expenses', MaxLength = 100;
        SoftwareTOK: Label 'Software', MaxLength = 100;
        ConsultantServicesTOK: Label 'Consultant Services', MaxLength = 100;
        OtherComputerExpensesTOK: Label 'Other Computer Expenses', MaxLength = 100;
        TotalComputerExpensesTOK: Label 'Total Computer Expenses', MaxLength = 100;
        SellingExpensesTOK: Label 'Selling Expenses', MaxLength = 100;
        AdvertisingTOK: Label 'Advertising', MaxLength = 100;
        EntertainmentandPRTOK: Label 'Entertainment and PR', MaxLength = 100;
        TravelTOK: Label 'Travel', MaxLength = 100;
        FreightExpensesRawMatTOK: Label 'Freight Expenses, Raw Mat.', MaxLength = 100;
        TotalSellingExpensesTOK: Label 'Total Selling Expenses', MaxLength = 100;
        VehicleExpensesTOK: Label 'Vehicle Expenses', MaxLength = 100;
        GasolineandMotorOilTOK: Label 'Gasoline and Motor Oil', MaxLength = 100;
        RegistrationFeesTOK: Label 'Registration Fees', MaxLength = 100;
        RepairsandMaintenanceTOK: Label 'Repairs and Maintenance', MaxLength = 100;
        TotalVehicleExpensesTOK: Label 'Total Vehicle Expenses', MaxLength = 100;
        OtherOperatingExpensesTOK: Label 'Other Operating Expenses', MaxLength = 100;
        CashDiscrepanciesTOK: Label 'Cash Discrepancies', MaxLength = 100;
        BadDebtExpensesTOK: Label 'Bad Debt Expenses', MaxLength = 100;
        LegalandAccountingServicesTOK: Label 'Legal and Accounting Services', MaxLength = 100;
        MiscellaneousTOK: Label 'Miscellaneous', MaxLength = 100;
        OtherOperatingExpTotalTOK: Label 'Other Operating Exp., Total', MaxLength = 100;
        TotalOperatingExpensesTOK: Label 'Total Operating Expenses', MaxLength = 100;
        PersonnelExpensesTOK: Label 'Personnel Expenses', MaxLength = 100;
        WagesTOK: Label 'Wages', MaxLength = 100;
        SalariesTOK: Label 'Salaries', MaxLength = 100;
        RetirementPlanContributionsTOK: Label 'Retirement Plan Contributions', MaxLength = 100;
        AnnualLeaveExpensesTOK: Label 'Annual Leave Expenses', MaxLength = 100;
        PayrollTaxesTOK: Label 'Payroll Taxes', MaxLength = 100;
        TotalPersonnelExpensesTOK: Label 'Total Personnel Expenses', MaxLength = 100;
        EBITDATOK: Label 'EBITDA', MaxLength = 100;
        DepreciationofFixedAssetsTOK: Label 'Depreciation of Fixed Assets', MaxLength = 100;
        DepreciationBuildingsTOK: Label 'Depreciation, Buildings', MaxLength = 100;
        DepreciationEquipmentTOK: Label 'Depreciation, Equipment', MaxLength = 100;
        DepreciationVehiclesTOK: Label 'Depreciation, Vehicles', MaxLength = 100;
        TotalFixedAssetDepreciationTOK: Label 'Total Fixed Asset Depreciation', MaxLength = 100;
        OtherCostsofOperationsTOK: Label 'Other Costs of Operations', MaxLength = 100;
        PurchaseWHTAdjustmentsTOK: Label 'Purchase WHT Adjustments', MaxLength = 100;
        SalesWHTAdjustmentsTOK: Label 'Sales WHT Adjustments', MaxLength = 100;
        InterestExpensesTOK: Label 'Interest Expenses', MaxLength = 100;
        InterestonRevolvingCreditTOK: Label 'Interest on Revolving Credit', MaxLength = 100;
        InterestonBankLoansTOK: Label 'Interest on Bank Loans', MaxLength = 100;
        MortgageInterestTOK: Label 'Mortgage Interest', MaxLength = 100;
        FinanceChargestoVendorsTOK: Label 'Finance Charges to Vendors', MaxLength = 100;
        PmtDiscGrantedDecreasesTOK: Label 'PmtDisc. Granted - Decreases', MaxLength = 100;
        PaymentDiscountsGrantedTOK: Label 'Payment Discounts Granted', MaxLength = 100;
        PaymentToleranceGrantedTOK: Label 'Payment Tolerance Granted', MaxLength = 100;
        PmtTolGrantedDecreasesTOK: Label 'Pmt. Tol. Granted Decreases', MaxLength = 100;
        TotalInterestExpensesTOK: Label 'Total Interest Expenses', MaxLength = 100;
        GAINSANDLOSSESTOK: Label 'GAINS AND LOSSES', MaxLength = 100;
        UnrealizedFXGainsTOK: Label 'Unrealized FX Gains', MaxLength = 100;
        UnrealizedFXLossesTOK: Label 'Unrealized FX Losses', MaxLength = 100;
        RealizedFXGainsTOK: Label 'Realized FX Gains', MaxLength = 100;
        RealizedFXLossesTOK: Label 'Realized FX Losses', MaxLength = 100;
        TOTALGAINSANDLOSSESTOK: Label 'TOTAL GAINS AND LOSSES', MaxLength = 100;
        NIBEFOREEXTRAITEMSANDTAXESTOK: Label 'NI BEF. EXTR. ITEMS & TAXES', MaxLength = 100;
        IncomeTaxesTOK: Label 'Income Taxes', MaxLength = 100;
        CorporateTaxTOK: Label 'Corporate Tax', MaxLength = 100;
        ExtraordinaryExpensesTOK: Label 'Extraordinary Expenses', MaxLength = 100;
        TotalIncomeTaxesTOK: Label 'Total Income Taxes', MaxLength = 100;
        NETINCOMEBEFOREEXTRITEMSTOK: Label 'NET INCOME BEFORE EXTR. ITEMS', MaxLength = 100;
        OthercomincomefortheperiodnetofinctaxTOK: Label 'Other comprehensive net income tax for the period', MaxLength = 100;
        TotalcomprehensiveincomefortheperiodTOK: Label 'Total comprehensive income for the period', MaxLength = 100;

    procedure InsertMiniAppData()
    begin
        AddIncomeStatementForMini();
        AddBalanceSheetForMini();

        GLAccIndent.Indent();
        AddCategoriesToMiniGLAccounts();
    end;

    local procedure AddIncomeStatementForMini()
    begin
        // Income statement 1000-4999
        DemoDataSetup.Get();
        InsertData(INCOMESTATEMENT(), INCOMESTATEMENTName(), 1, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Revenue(), RevenueName(), 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData(SalesofRetail(), SalesofRetailName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesRetailDom(), SalesRetailDomName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(StockSales(), StockSalesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(HireIncome(), HireIncomeName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(RentalIncome(), RentalIncomeName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesRetailExport(), SalesRetailExportName(), 0, 0, 0, '', 0, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(JobSalesAppliedRetail(), JobSalesAppliedRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobSalesAdjmtRetail(), JobSalesAdjmtRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalSalesofRetail(), TotalSalesofRetailName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesofRawMaterials(), SalesofRawMaterialsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesRawMaterialsDom(), SalesRawMaterialsDomName(), 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData(SalesRawMaterialsExport(), SalesRawMaterialsExportName(), 0, 0, 0, '', 0, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData(JobSalesAppliedRawMat(), JobSalesAppliedRawMatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobSalesAdjmtRawMat(), JobSalesAdjmtRawMatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalSalesofRawMaterials(), TotalSalesofRawMaterialsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesofResources(), SalesofResourcesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesResourcesDom(), SalesResourcesDomName(), 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(SalesResourcesExport(), SalesResourcesExportName(), 0, 0, 0, '', 0, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(JobSalesAppliedResources(), JobSalesAppliedResourcesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobSalesAdjmtResources(), JobSalesAdjmtResourcesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalSalesofResources(), TotalSalesofResourcesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesofJobs(), SalesofJobsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesOtherJobExpenses(), SalesOtherJobExpensesName(), 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(JobSales(), JobSalesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalSalesofJobs(), TotalSalesofJobsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesofServiceContracts(), SalesofServiceContractsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(ServiceContractSale(), ServiceContractSaleName(), 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(TotalSaleofServContracts(), TotalSaleofServContractsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(InterestIncome(), InterestIncomeName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(InterestonBankBalances(), InterestonBankBalancesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(FinanceChargesfromCustomers(), FinanceChargesfromCustomersName(), 0, 0, 0, '', 2, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(PaymentDiscountsReceived(), PaymentDiscountsReceivedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PmtDiscReceivedDecreases(), PmtDiscReceivedDecreasesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(InvoiceRounding(), InvoiceRoundingName(), 0, 0, 0, '', 0, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(ApplicationRounding(), ApplicationRoundingName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PaymentToleranceReceived(), PaymentToleranceReceivedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PmtTolReceivedDecreases(), PmtTolReceivedDecreasesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(ConsultingFeesDom(), ConsultingFeesDomName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(FeesandChargesRecDom(), FeesandChargesRecDomName(), 0, 0, 0, '', 0, '', DemoDataSetup.MiscCode(), '', '', true);
        InsertData(DiscountGranted(), DiscountGrantedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalInterestIncome(), TotalInterestIncomeName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalRevenue(), TotalRevenueName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Cost(), CostName(), 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData(CostofRetail(), CostofRetailName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PurchRetailDom(), PurchRetailDomName(), 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(PurchRetailExport(), PurchRetailExportName(), 0, 0, 0, '', 0, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(DiscReceivedRetail(), DiscReceivedRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(FreightExpensesRetail(), FreightExpensesRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(InventoryAdjmtRetail(), InventoryAdjmtRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCostAppliedRetail(), JobCostAppliedRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCostAdjmtRetail(), JobCostAdjmtRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofRetailSold(), CostofRetailSoldName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(DirectCostAppliedRetail(), DirectCostAppliedRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(OverheadAppliedRetail(), OverheadAppliedRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PurchaseVarianceRetail(), PurchaseVarianceRetailName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofRetail(), TotalCostofRetailName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofRawMaterials(), CostofRawMaterialsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PurchRawMaterialsDom(), PurchRawMaterialsDomName(), 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData(PurchRawMaterialsExport(), PurchRawMaterialsExportName(), 0, 0, 0, '', 0, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData(DiscReceivedRawMaterials(), DiscReceivedRawMaterialsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(FreightExpensesRawMat(), FreightExpensesRawMatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(InventoryAdjmtRawMat(), InventoryAdjmtRawMatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCostAppliedRawMat(), JobCostAppliedRawMatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCostAdjmtRawMaterials(), JobCostAdjmtRawMaterialsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofRawMaterialsSold(), CostofRawMaterialsSoldName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(DirectCostAppliedRawmat(), DirectCostAppliedRawmatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(OverheadAppliedRawmat(), OverheadAppliedRawmatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PurchaseVarianceRawmat(), PurchaseVarianceRawmatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofRawMaterials(), TotalCostofRawMaterialsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofResources(), CostofResourcesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCostAppliedResources(), JobCostAppliedResourcesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCostAdjmtResources(), JobCostAdjmtResourcesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofResourcesUsed(), CostofResourcesUsedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofResources(), TotalCostofResourcesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCosts(), JobCostsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofCapacities(), CostofCapacitiesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofCapacitie(), CostofCapacitiesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(DirectCostAppliedCap(), DirectCostAppliedCapName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(OverheadAppliedCap(), OverheadAppliedCapName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PurchaseVarianceCap(), PurchaseVarianceCapName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofCapacities(), TotalCostofCapacitiesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Variance(), VarianceName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(MaterialVariance(), MaterialVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CapacityVariance(), CapacityVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SubcontractedVariance(), SubcontractedVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CapOverheadVariance(), CapOverheadVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(MfgOverheadVariance(), MfgOverheadVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalVariance(), TotalVarianceName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCost(), TotalCostName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(OperatingExpenses(), OperatingExpensesName(), 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData(BuildingMaintenanceExpenses(), BuildingMaintenanceExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Cleaning(), CleaningName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(ElectricityandHeating(), ElectricityandHeatingName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(RepairsandMaintenance(), RepairsandMaintenanceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalBldgMaintExpenses(), TotalBldgMaintExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(AdministrativeExpenses(), AdministrativeExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(OfficeSupplies(), OfficeSuppliesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PhoneandFax(), PhoneandFaxName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Postage(), PostageName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalAdministrativeExpenses(), TotalAdministrativeExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(ComputerExpenses(), ComputerExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Software(), SoftwareName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(ConsultantServices(), ConsultantServicesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(OtherComputerExpenses(), OtherComputerExpensesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalComputerExpenses(), TotalComputerExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SellingExpenses(), SellingExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Advertising(), AdvertisingName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(EntertainmentandPR(), EntertainmentandPRName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Travel(), TravelName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(FreightExpenseRawMat(), FreightExpensesRawMatName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalSellingExpenses(), TotalSellingExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(VehicleExpenses(), VehicleExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GasolineandMotorOil(), GasolineandMotorOilName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(RegistrationFees(), RegistrationFeesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(RepairandMaintenance(), RepairsandMaintenanceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalVehicleExpenses(), TotalVehicleExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(OtherOperatingExpenses(), OtherOperatingExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CashDiscrepancies(), CashDiscrepanciesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(BadDebtExpenses(), BadDebtExpensesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(LegalandAccountingServices(), LegalandAccountingServicesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Miscellaneous(), MiscellaneousName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(OtherOperatingExpTotal(), OtherOperatingExpTotalName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalOperatingExpenses(), TotalOperatingExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PersonnelExpenses(), PersonnelExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Wages(), WagesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Salaries(), SalariesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(RetirementPlanContributions(), RetirementPlanContributionsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(AnnualLeaveExpenses(), AnnualLeaveExpensesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PayrollTaxes(), PayrollTaxesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalPersonnelExpenses(), TotalPersonnelExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(EBITDA(), EBITDAName(), 2, 0, 0, '', 0, '', '', '', '', true);
        InsertData(DepreciationofFixedAssets(), DepreciationofFixedAssetsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(DepreciationBuildings(), DepreciationBuildingsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(DepreciationEquipment(), DepreciationEquipmentName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(DepreciationVehicles(), DepreciationVehiclesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalFixedAssetDepreciation(), TotalFixedAssetDepreciationName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(OtherCostsofOperations(), OtherCostsofOperationsName(), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(PurchaseWHTAdjustments(), PurchaseWHTAdjustmentsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(SalesWHTAdjustments(), SalesWHTAdjustmentsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(InterestExpenses(), InterestExpensesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(InterestonRevolvingCredit(), InterestonRevolvingCreditName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(InterestonBankLoans(), InterestonBankLoansName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(MortgageInterest(), MortgageInterestName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(FinanceChargestoVendors(), FinanceChargestoVendorsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PmtDiscGrantedDecreases(), PmtDiscGrantedDecreasesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PaymentDiscountsGranted(), PaymentDiscountsGrantedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PaymentToleranceGranted(), PaymentToleranceGrantedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PmtTolGrantedDecreases(), PmtTolGrantedDecreasesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalInterestExpenses(), TotalInterestExpensesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GAINSANDLOSSES(), GAINSANDLOSSESName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(UnrealizedFXGains(), UnrealizedFXGainsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(UnrealizedFXLosses(), UnrealizedFXLossesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(RealizedFXGains(), RealizedFXGainsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(RealizedFXLosses(), RealizedFXLossesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(GainsandLosse(), GainsandLossesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TOTALGAINSANDLOSSES(), TOTALGAINSANDLOSSESName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(NIBEFOREEXTRAITEMSANDTAXES(), NIBEFOREEXTRAITEMSANDTAXESName(), 2, 0, 1, '', 0, '', '', '', '', true);
        InsertData(IncomeTaxes(), IncomeTaxesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CorporateTax(), CorporateTaxName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(ExtraordinaryExpenses(), ExtraordinaryExpensesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalIncomeTaxes(), TotalIncomeTaxesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Othercomincomefortheperiodnetofinctax(), OthercomincomefortheperiodnetofinctaxName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Othercomincomeperiodnetofinctax(), OthercomincomefortheperiodnetofinctaxName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Totalcomprehensiveincomefortheperiod(), TotalcomprehensiveincomefortheperiodName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(NETINCOMEBEFOREEXTRITEMS(), NETINCOMEBEFOREEXTRITEMSName(), 2, 0, 1, '', 0, '', '', '', '', true);
    end;

    procedure AddBalanceSheetForMini()
    begin
        // Balance sheet 5000-9999
        DemoDataSetup.Get();
        InsertData(STMTOFFINANCIALPOSITION(), STMTOFFINANCIALPOSITIONName(), 1, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ASSETS(), ASSETSName(), 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData(CurrentAssets(), CurrentAssetsName(), 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData(LiquidAssets(), LiquidAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Cash(), CashName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BankLCY(), BankLCYName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BankCurrencies(), BankCurrenciesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BankOther(), BankOtherName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LiquidAssetsTotal(), LiquidAssetsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsReceivable(), AccountsReceivableName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CustomersDomestic(), CustomersDomesticName(), 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(CustomersForeign(), CustomersForeignName(), 0, 1, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(CustomersIntercompany(), CustomersIntercompanyName(), 0, 1, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(AccruedInterest(), AccruedInterestName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherReceivables(), OtherReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsReceivableTotal(), AccountsReceivableTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Inventory(), InventoryName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ResaleItems(), ResaleItemsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ResaleItemsInterim(), ResaleItemsInterimName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CostofResaleSoldInterim(), CostofResaleSoldInterimName(), 0, 1, 0, '', 2, '', '', '', '', true);
        InsertData(FinishedGoods(), FinishedGoodsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(FinishedGoodsInterim(), FinishedGoodsInterimName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RawMaterials(), RawMaterialsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RawMaterialsInterim(), RawMaterialsInterimName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CostofRawMatSoldInterim(), CostofRawMatSoldInterimName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPAccountFinishedgoods(), WIPAccountFinishedgoodsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PrimoInventory(), PrimoInventoryName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(InventoryTotal(), InventoryTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(JobWIP(), JobWIPName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPSales(), WIPSalesName(), 3, 1, 0, '', 2, '', '', '', '', true);
        InsertData(WIPJobSales(), WIPJobSalesName(), 0, 1, 0, '', 2, '', '', '', '', true);
        InsertData(InvoicedJobSales(), InvoicedJobSalesName(), 0, 1, 0, '', 2, '', '', '', '', true);
        InsertData(WIPSalesTotal(), WIPSalesTotalName(), 4, 1, 0, '', 2, '', '', '', '', true);
        InsertData(WIPCosts(), WIPCostsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPJobCosts(), WIPJobCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedJobCosts(), AccruedJobCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPCostsTotal(), WIPCostsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(JobWIPTotal(), JobWIPTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCurrentAssets(), TotalCurrentAssetsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(NonCurrentAssets(), NonCurrentAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(FinancialAssets(), FinancialAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Investments(), InvestmentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherFinancialassets(), OtherFinancialassetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PurchasePrepayments(), PurchasePrepaymentsName(), 0, 1, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(TotalFinancialAssets(), TotalFinancialAssetsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TangibleFixedAssets(), TangibleFixedAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LandandBuildings(), LandandBuildingsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LandandBuilding(), LandandBuildingsName(), 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(AccumDepreciationBuildings(), AccumDepreciationBuildingsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LandandBuildingsTotal(), LandandBuildingsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OfficeEquipment(), OfficeEquipmentName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OfficeEquip(), OfficeEquipmentName(), 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(AccumDeprOperEquip(), AccumDeprOperEquipName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OfficeEquipmentTotal(), OfficeEquipmentTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Vehicles(), VehiclesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Vehicle(), VehiclesName(), 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData(AccumDepreciationVehicles(), AccumDepreciationVehiclesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(VehiclesTotal(), VehiclesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TangibleFixedAssetsTotal(), TangibleFixedAssetsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(IntangibleAssets(), IntangibleAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(IntangibleAsset(), IntangibleAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccAmortnonIntangibles(), AccAmortnonIntangiblesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(IntangibleAssetsTotal(), IntangibleAssetsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Righttouseassets(), RighttouseassetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Righttouseleases(), RighttouseleasesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccAmortnonRightofuseLeases(), AccAmortnonRightofuseLeasesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RighttouseassetsTotal(), RighttouseassetsTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalNonCurrentAssets(), TotalNonCurrentAssetsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalAssets(), TotalAssetsName(), 4, 1, 1, '', 0, '', '', '', '', true);
        InsertData(Liabilities(), LiabilitiesName(), 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData(LongtermLiabilities(), LongtermLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LongtermBankLoans(), LongtermBankLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Mortgage(), MortgageName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LongtermLiabilitiesTotal(), LongtermLiabilitiesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ShorttermLiabilities(), ShorttermLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RevolvingCredit(), RevolvingCreditName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SalesPrepayments(), SalesPrepaymentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PrepaidServiceContracts(), PrepaidServiceContractsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DeferredRevenue(), DeferredRevenueName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DeferredTaxes(), DeferredTaxesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TradeandOtherPayables(), TradeandOtherPayablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Accountspayable(), AccountspayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(VendorsDomestic(), VendorsDomesticName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(VendorsForeign(), VendorsForeignName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(VendorsIntercompany(), VendorsIntercompanyName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedExpenses(), AccruedExpensesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ProvisionforIncomeTax(), ProvisionforIncomeTaxName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ProvisionforAnnualLeave(), ProvisionforAnnualLeaveName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Superannuationclearing(), SuperannuationclearingName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Payrollclearing(), PayrollclearingName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PayrollDeductions(), PayrollDeductionsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TradeandOtherPayable(), TradeandOtherPayablesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(InvAdjmtInterim(), InvAdjmtInterimName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(InvAdjmtInterimRawMat(), InvAdjmtInterimRawMatName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(InvAdjmtInterimRetail(), InvAdjmtInterimRetailName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(InvAdjmtInterimTotal(), InvAdjmtInterimTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TaxesPayables(), TaxesPayablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GSTPayable(), GSTPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GSTReceivable(), GSTReceivableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GSTClearing(), GSTClearingName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GSTRecon(), GSTReconName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WHTTaxPayable(), WHTTaxPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WHTPrepaid(), WHTPrepaidName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TaxesPayablesTotal(), TaxesPayablesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PersonnelrelatedItems(), PersonnelrelatedItemsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WithholdingTaxesPayable(), WithholdingTaxesPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SupplementaryTaxesPayable(), SupplementaryTaxesPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PayrollTaxesPayable(), PayrollTaxesPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(VacationCompensationPayable(), VacationCompensationPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EmployeesPayable(), EmployeesPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalPersonnelrelatedItems(), TotalPersonnelrelatedItemsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(UnearnedRevenueOther(), UnearnedRevenueOtherName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Fundsreceivedinadvance(), FundsreceivedinadvanceName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Othercurrentliabilities(), OthercurrentliabilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalUnearnedRevenueOther(), TotalUnearnedRevenueOtherName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ShorttermLiabilitiesTotal(), ShorttermLiabilitiesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(NonCurrentLiabilities(), NonCurrentLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EmployeeProvisions(), EmployeeProvisionsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Longserviceleave(), LongserviceleaveName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalEmployeeProvisions(), TotalEmployeeProvisionsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLiabilities(), OtherLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DividendsfortheFiscalYear(), DividendsfortheFiscalYearName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CorporateTaxesPayable(), CorporateTaxesPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLiabilitiesTotal(), OtherLiabilitiesTotalName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalNonCurrentLiabilities(), TotalNonCurrentLiabilitiesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalLiabilities(), TotalLiabilitiesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LIABILITIESANDEQUITY(), LIABILITIESANDEQUITYName(), 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData(StockholdersEquity(), StockholdersEquityName(), 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData(CapitalStock(), CapitalStockName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RetainedEarnings(), RetainedEarningsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Allowances(), AllowancesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(NetIncomefortheYear(), NetIncomefortheYearName(), 2, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalStockholdersEquity(), TotalStockholdersEquityName(), 2, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TOTALLIABILITIESANDEQUITY(), TOTALLIABILITIESANDEQUITYName(), 2, 1, 1, '', 0, '', '', '', '', true);
    end;

    procedure InsertData(AccountNo: Code[20]; AccountName: Text[100]; AccountType: Option; IncomeBalance: Option; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectPosting: Boolean)
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
            '992910', '992920', '992930', '992940', '995310', '1005':
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

    procedure AddCategoriesToMiniGLAccounts()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if GLAccountCategory.IsEmpty() then
            exit;

        GLAccountCategory.SetRange("Parent Entry No.", 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignCategoryToMiniChartOfAccounts(GLAccountCategory);
                AssignCategoryToLocalChartOfAccounts(GLAccountCategory);
            until GLAccountCategory.Next() = 0;

        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignSubcategoryToMiniChartOfAccounts(GLAccountCategory);
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
                    UpdateGLAccounts(GLAccountCategory, '998000', '998930');
                    UpdateGLAccounts(GLAccountCategory, '999320', '999320');
                    UpdateGLAccounts(GLAccountCategory, '999340', '999340');
                end;
        end;
    end;

    procedure AssignCategoryToMiniChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Assets:
                UpdateGLAccounts(GLAccountCategory, '1001', '1699');
            GLAccountCategory."Account Category"::Liabilities:
                UpdateGLAccounts(GLAccountCategory, '2000', '2999');
            GLAccountCategory."Account Category"::Equity:
                UpdateGLAccounts(GLAccountCategory, '3000', '3999');
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, '4000', '4900');
                    UpdateGLAccounts(GLAccountCategory, '7300', '7999');
                    //UpdateGLAccounts(GLAccountCategory, '999310', '999310');
                    //UpdateGLAccounts(GLAccountCategory, '999330', '999330');
                    //UpdateGLAccounts(GLAccountCategory, '999410', '999410');
                end;
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                UpdateGLAccounts(GLAccountCategory, '5000', '5799');
            //UpdateGLAccounts(GLAccountCategory, '997705', '997795');
            GLAccountCategory."Account Category"::Expense:
                begin
                    UpdateGLAccounts(GLAccountCategory, '6000', '7290');
                    UpdateGLAccounts(GLAccountCategory, '7500', '7500');
                    UpdateGLAccounts(GLAccountCategory, '7610', '7610');
                    UpdateGLAccounts(GLAccountCategory, '8005', '8199');
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

    procedure AssignSubcategoryToMiniChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCash():
                UpdateGLAccounts(GLAccountCategory, '1003', '1099');
            GLAccountCategoryMgt.GetAR():
                UpdateGLAccounts(GLAccountCategory, '1200', '1290');
            //UpdateGLAccounts(GLAccountCategory, '995620', '995631');
            GLAccountCategoryMgt.GetPrepaidExpenses():
                begin
                    UpdateGLAccounts(GLAccountCategory, '1400', '1400');
                    UpdateGLAccounts(GLAccountCategory, '1511', '1511');
                end;
            GLAccountCategoryMgt.GetInventory():
                UpdateGLAccounts(GLAccountCategory, '1300', '1399');
            GLAccountCategoryMgt.GetEquipment():
                UpdateGLAccounts(GLAccountCategory, '1541', '1555');
            GLAccountCategoryMgt.GetAccumDeprec():
                UpdateGLAccounts(GLAccountCategory, '1530', '1530');
            GLAccountCategoryMgt.GetCurrentLiabilities():
                begin
                    UpdateGLAccounts(GLAccountCategory, '2240', '2350');
                    UpdateGLAccounts(GLAccountCategory, '2400', '2400');
                    //UpdateGLAccounts(GLAccountCategory, '994010', '994010');
                end;
            GLAccountCategoryMgt.GetPayrollLiabilities():
                UpdateGLAccounts(GLAccountCategory, '6500', '6599');
            GLAccountCategoryMgt.GetLongTermLiabilities():
                begin
                    UpdateGLAccounts(GLAccountCategory, '2020', '2100');
                    UpdateGLAccounts(GLAccountCategory, '2105', '2106');
                end;
            GLAccountCategoryMgt.GetCommonStock():
                UpdateGLAccounts(GLAccountCategory, '3010', '3010');
            GLAccountCategoryMgt.GetRetEarnings():
                UpdateGLAccounts(GLAccountCategory, '3020', '3020');
            GLAccountCategoryMgt.GetDistrToShareholders():
                UpdateGLAccounts(GLAccountCategory, '3050', '3050');
            GLAccountCategoryMgt.GetIncomeService():
                begin
                    UpdateGLAccounts(GLAccountCategory, '4350', '4740');
                    UpdateGLAccounts(GLAccountCategory, '4780', '4790');
                end;
            GLAccountCategoryMgt.GetIncomeProdSales():
                begin
                    UpdateGLAccounts(GLAccountCategory, '4100', '4110');
                    UpdateGLAccounts(GLAccountCategory, '4145', '4145');
                end;
            GLAccountCategoryMgt.GetIncomeSalesDiscounts():
                UpdateGLAccounts(GLAccountCategory, '4795', '4795');
            GLAccountCategoryMgt.GetIncomeSalesReturns():
                ;
            GLAccountCategoryMgt.GetCOGSLabor():
                UpdateGLAccounts(GLAccountCategory, '5400', '5479');
            GLAccountCategoryMgt.GetCOGSMaterials():
                UpdateGLAccounts(GLAccountCategory, '5100', '5390');
            GLAccountCategoryMgt.GetRentExpense():
                ;
            GLAccountCategoryMgt.GetAdvertisingExpense():
                UpdateGLAccounts(GLAccountCategory, '6225', '6235');
            GLAccountCategoryMgt.GetInterestExpense():
                UpdateGLAccounts(GLAccountCategory, '7200', '7290');
            GLAccountCategoryMgt.GetFeesExpense():
                ;
            GLAccountCategoryMgt.GetInsuranceExpense():
                ;
            GLAccountCategoryMgt.GetPayrollExpense():
                UpdateGLAccounts(GLAccountCategory, '6500', '6599');
            GLAccountCategoryMgt.GetBenefitsExpense():
                ;
            GLAccountCategoryMgt.GetRepairsExpense():
                UpdateGLAccounts(GLAccountCategory, '6398', '6398');
            GLAccountCategoryMgt.GetUtilitiesExpense():
                UpdateGLAccounts(GLAccountCategory, '6005', '6055');
            GLAccountCategoryMgt.GetOtherIncomeExpense():
                begin
                    UpdateGLAccounts(GLAccountCategory, '6400', '6499');
                    UpdateGLAccounts(GLAccountCategory, '7150', '7150');
                    UpdateGLAccounts(GLAccountCategory, '8030', '8030');
                end;
            GLAccountCategoryMgt.GetTaxExpense():
                UpdateGLAccounts(GLAccountCategory, '8010', '8199');
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

    internal procedure STMTOFFINANCIALPOSITION(): Code[20]
    begin
        exit('1000');
    end;

    internal procedure ASSETS(): Code[20]
    begin
        exit('1001');
    end;

    internal procedure CurrentAssets(): Code[20]
    begin
        exit('1002');
    end;

    internal procedure LiquidAssets(): Code[20]
    begin
        exit('1003');
    end;

    internal procedure Cash(): Code[20]
    begin
        exit('1005');
    end;

    internal procedure BankLCY(): Code[20]
    begin
        exit('1010');
    end;

    internal procedure BankCurrencies(): Code[20]
    begin
        exit('1015');
    end;

    internal procedure BankOther(): Code[20]
    begin
        exit('1020');
    end;

    internal procedure LiquidAssetsTotal(): Code[20]
    begin
        exit('1099');
    end;

    internal procedure AccountsReceivable(): Code[20]
    begin
        exit('1200');
    end;

    internal procedure CustomersDomestic(): Code[20]
    begin
        exit('1210');
    end;

    internal procedure CustomersForeign(): Code[20]
    begin
        exit('1220');
    end;

    internal procedure CustomersIntercompany(): Code[20]
    begin
        exit('1225');
    end;

    internal procedure AccruedInterest(): Code[20]
    begin
        exit('1230');
    end;

    internal procedure OtherReceivables(): Code[20]
    begin
        exit('1240');
    end;

    internal procedure AccountsReceivableTotal(): Code[20]
    begin
        exit('1290');
    end;

    internal procedure Inventory(): Code[20]
    begin
        exit('1300');
    end;

    internal procedure ResaleItems(): Code[20]
    begin
        exit('1310');
    end;

    internal procedure ResaleItemsInterim(): Code[20]
    begin
        exit('1311');
    end;

    internal procedure CostofResaleSoldInterim(): Code[20]
    begin
        exit('1312');
    end;

    internal procedure FinishedGoods(): Code[20]
    begin
        exit('1320');
    end;

    internal procedure FinishedGoodsInterim(): Code[20]
    begin
        exit('1321');
    end;

    internal procedure RawMaterials(): Code[20]
    begin
        exit('1330');
    end;

    internal procedure RawMaterialsInterim(): Code[20]
    begin
        exit('1331');
    end;

    internal procedure CostofRawMatSoldInterim(): Code[20]
    begin
        exit('1332');
    end;

    internal procedure WIPAccountFinishedgoods(): Code[20]
    begin
        exit('1340');
    end;

    internal procedure PrimoInventory(): Code[20]
    begin
        exit('1380');
    end;

    internal procedure InventoryTotal(): Code[20]
    begin
        exit('1399');
    end;

    internal procedure JobWIP(): Code[20]
    begin
        exit('1400');
    end;

    internal procedure WIPSales(): Code[20]
    begin
        exit('1410');
    end;

    internal procedure WIPJobSales(): Code[20]
    begin
        exit('1411');
    end;

    internal procedure InvoicedJobSales(): Code[20]
    begin
        exit('1412');
    end;

    internal procedure WIPSalesTotal(): Code[20]
    begin
        exit('1420');
    end;

    internal procedure WIPCosts(): Code[20]
    begin
        exit('1430');
    end;

    internal procedure WIPJobCosts(): Code[20]
    begin
        exit('1431');
    end;

    internal procedure AccruedJobCosts(): Code[20]
    begin
        exit('1432');
    end;

    internal procedure WIPCostsTotal(): Code[20]
    begin
        exit('1433');
    end;

    internal procedure JobWIPTotal(): Code[20]
    begin
        exit('1440');
    end;

    internal procedure TotalCurrentAssets(): Code[20]
    begin
        exit('1499');
    end;

    internal procedure NonCurrentAssets(): Code[20]
    begin
        exit('1500');
    end;

    internal procedure FinancialAssets(): Code[20]
    begin
        exit('1504');
    end;

    internal procedure Investments(): Code[20]
    begin
        exit('1505');
    end;

    internal procedure OtherFinancialassets(): Code[20]
    begin
        exit('1510');
    end;

    internal procedure PurchasePrepayments(): Code[20]
    begin
        exit('1511');
    end;

    internal procedure TotalFinancialAssets(): Code[20]
    begin
        exit('1514');
    end;

    internal procedure TangibleFixedAssets(): Code[20]
    begin
        exit('1515');
    end;

    internal procedure LandandBuildings(): Code[20]
    begin
        exit('1520');
    end;

    internal procedure LandandBuilding(): Code[20]
    begin
        exit('1521');
    end;

    internal procedure AccumDepreciationBuildings(): Code[20]
    begin
        exit('1530');
    end;

    internal procedure LandandBuildingsTotal(): Code[20]
    begin
        exit('1531');
    end;

    internal procedure OfficeEquipment(): Code[20]
    begin
        exit('1541');
    end;

    internal procedure OfficeEquip(): Code[20]
    begin
        exit('1542');
    end;

    internal procedure AccumDeprOperEquip(): Code[20]
    begin
        exit('1543');
    end;

    internal procedure OfficeEquipmentTotal(): Code[20]
    begin
        exit('1549');
    end;

    internal procedure Vehicles(): Code[20]
    begin
        exit('1550');
    end;

    internal procedure Vehicle(): Code[20]
    begin
        exit('1551');
    end;

    internal procedure AccumDepreciationVehicles(): Code[20]
    begin
        exit('1554');
    end;

    internal procedure VehiclesTotal(): Code[20]
    begin
        exit('1555');
    end;

    internal procedure TangibleFixedAssetsTotal(): Code[20]
    begin
        exit('1599');
    end;

    internal procedure IntangibleAssets(): Code[20]
    begin
        exit('1600');
    end;

    internal procedure IntangibleAsset(): Code[20]
    begin
        exit('1605');
    end;

    internal procedure AccAmortnonIntangibles(): Code[20]
    begin
        exit('1610');
    end;

    internal procedure IntangibleAssetsTotal(): Code[20]
    begin
        exit('1650');
    end;

    internal procedure Righttouseassets(): Code[20]
    begin
        exit('1670');
    end;

    internal procedure Righttouseleases(): Code[20]
    begin
        exit('1671');
    end;

    internal procedure AccAmortnonRightofuseLeases(): Code[20]
    begin
        exit('1672');
    end;

    internal procedure RighttouseassetsTotal(): Code[20]
    begin
        exit('1673');
    end;

    internal procedure TotalNonCurrentAssets(): Code[20]
    begin
        exit('1698');
    end;

    internal procedure TotalAssets(): Code[20]
    begin
        exit('1699');
    end;

    internal procedure Liabilities(): Code[20]
    begin
        exit('2010');
    end;

    internal procedure LongtermLiabilities(): Code[20]
    begin
        exit('2020');
    end;

    internal procedure LongtermBankLoans(): Code[20]
    begin
        exit('2030');
    end;

    internal procedure Mortgage(): Code[20]
    begin
        exit('2040');
    end;

    internal procedure LongtermLiabilitiesTotal(): Code[20]
    begin
        exit('2100');
    end;

    internal procedure ShorttermLiabilities(): Code[20]
    begin
        exit('2101');
    end;

    internal procedure RevolvingCredit(): Code[20]
    begin
        exit('2102');
    end;

    internal procedure SalesPrepayments(): Code[20]
    begin
        exit('2103');
    end;

    internal procedure PrepaidServiceContracts(): Code[20]
    begin
        exit('2104');
    end;

    internal procedure DeferredRevenue(): Code[20]
    begin
        exit('2105');
    end;

    internal procedure DeferredTaxes(): Code[20]
    begin
        exit('2106');
    end;

    internal procedure TradeandOtherPayables(): Code[20]
    begin
        exit('2240');
    end;

    internal procedure Accountspayable(): Code[20]
    begin
        exit('2242');
    end;

    internal procedure VendorsDomestic(): Code[20]
    begin
        exit('2245');
    end;

    internal procedure VendorsForeign(): Code[20]
    begin
        exit('2250');
    end;

    internal procedure VendorsIntercompany(): Code[20]
    begin
        exit('2251');
    end;

    internal procedure AccruedExpenses(): Code[20]
    begin
        exit('2253');
    end;

    internal procedure ProvisionforIncomeTax(): Code[20]
    begin
        exit('2255');
    end;

    internal procedure ProvisionforAnnualLeave(): Code[20]
    begin
        exit('2259');
    end;

    internal procedure Superannuationclearing(): Code[20]
    begin
        exit('2260');
    end;

    internal procedure Payrollclearing(): Code[20]
    begin
        exit('2261');
    end;

    internal procedure PayrollDeductions(): Code[20]
    begin
        exit('2270');
    end;

    internal procedure TradeandOtherPayable(): Code[20]
    begin
        exit('2274');
    end;

    internal procedure InvAdjmtInterim(): Code[20]
    begin
        exit('2275');
    end;

    internal procedure InvAdjmtInterimRawMat(): Code[20]
    begin
        exit('2279');
    end;

    internal procedure InvAdjmtInterimRetail(): Code[20]
    begin
        exit('2280');
    end;

    internal procedure InvAdjmtInterimTotal(): Code[20]
    begin
        exit('2281');
    end;

    internal procedure TaxesPayables(): Code[20]
    begin
        exit('2300');
    end;

    internal procedure GSTPayable(): Code[20]
    begin
        exit('2305');
    end;

    internal procedure GSTReceivable(): Code[20]
    begin
        exit('2310');
    end;

    internal procedure GSTClearing(): Code[20]
    begin
        exit('2320');
    end;

    internal procedure GSTRecon(): Code[20]
    begin
        exit('2330');
    end;

    internal procedure WHTTaxPayable(): Code[20]
    begin
        exit('2340');
    end;

    internal procedure WHTPrepaid(): Code[20]
    begin
        exit('2341');
    end;

    internal procedure TaxesPayablesTotal(): Code[20]
    begin
        exit('2350');
    end;

    internal procedure PersonnelrelatedItems(): Code[20]
    begin
        exit('2360');
    end;

    internal procedure WithholdingTaxesPayable(): Code[20]
    begin
        exit('2370');
    end;

    internal procedure SupplementaryTaxesPayable(): Code[20]
    begin
        exit('2375');
    end;

    internal procedure PayrollTaxesPayable(): Code[20]
    begin
        exit('2376');
    end;

    internal procedure VacationCompensationPayable(): Code[20]
    begin
        exit('2377');
    end;

    internal procedure EmployeesPayable(): Code[20]
    begin
        exit('2378');
    end;

    internal procedure TotalPersonnelrelatedItems(): Code[20]
    begin
        exit('2379');
    end;

    internal procedure UnearnedRevenueOther(): Code[20]
    begin
        exit('2380');
    end;

    internal procedure Fundsreceivedinadvance(): Code[20]
    begin
        exit('2381');
    end;

    internal procedure Othercurrentliabilities(): Code[20]
    begin
        exit('2382');
    end;

    internal procedure TotalUnearnedRevenueOther(): Code[20]
    begin
        exit('2390');
    end;

    internal procedure ShorttermLiabilitiesTotal(): Code[20]
    begin
        exit('2399');
    end;

    internal procedure NonCurrentLiabilities(): Code[20]
    begin
        exit('2400');
    end;

    internal procedure EmployeeProvisions(): Code[20]
    begin
        exit('2410');
    end;

    internal procedure Longserviceleave(): Code[20]
    begin
        exit('2420');
    end;

    internal procedure TotalEmployeeProvisions(): Code[20]
    begin
        exit('2450');
    end;

    internal procedure OtherLiabilities(): Code[20]
    begin
        exit('2500');
    end;

    internal procedure DividendsfortheFiscalYear(): Code[20]
    begin
        exit('2510');
    end;

    internal procedure CorporateTaxesPayable(): Code[20]
    begin
        exit('2520');
    end;

    internal procedure OtherLiabilitiesTotal(): Code[20]
    begin
        exit('2530');
    end;

    internal procedure TotalNonCurrentLiabilities(): Code[20]
    begin
        exit('2540');
    end;

    internal procedure TotalLiabilities(): Code[20]
    begin
        exit('2999');
    end;

    internal procedure LIABILITIESANDEQUITY(): Code[20]
    begin
        exit('2000');
    end;

    internal procedure StockholdersEquity(): Code[20]
    begin
        exit('3000');
    end;

    internal procedure CapitalStock(): Code[20]
    begin
        exit('3010');
    end;

    internal procedure RetainedEarnings(): Code[20]
    begin
        exit('3020');
    end;

    internal procedure Allowances(): Code[20]
    begin
        exit('3040');
    end;

    internal procedure NetIncomefortheYear(): Code[20]
    begin
        exit('3045');
    end;

    internal procedure TotalStockholdersEquity(): Code[20]
    begin
        exit('3050');
    end;

    internal procedure TOTALLIABILITIESANDEQUITY(): Code[20]
    begin
        exit('3999');
    end;

    internal procedure INCOMESTATEMENT(): Code[20]
    begin
        exit('4000');
    end;

    internal procedure Revenue(): Code[20]
    begin
        exit('4010');
    end;

    internal procedure SalesofRetail(): Code[20]
    begin
        exit('4100');
    end;

    internal procedure SalesRetailDom(): Code[20]
    begin
        exit('4110');
    end;

    internal procedure StockSales(): Code[20]
    begin
        exit('4120');
    end;

    internal procedure HireIncome(): Code[20]
    begin
        exit('4130');
    end;

    internal procedure RentalIncome(): Code[20]
    begin
        exit('4140');
    end;

    internal procedure SalesRetailExport(): Code[20]
    begin
        exit('4145');
    end;

    internal procedure JobSalesAppliedRetail(): Code[20]
    begin
        exit('4150');
    end;

    internal procedure JobSalesAdjmtRetail(): Code[20]
    begin
        exit('4200');
    end;

    internal procedure TotalSalesofRetail(): Code[20]
    begin
        exit('4210');
    end;

    internal procedure SalesofRawMaterials(): Code[20]
    begin
        exit('4230');
    end;

    internal procedure SalesRawMaterialsDom(): Code[20]
    begin
        exit('4240');
    end;

    internal procedure SalesRawMaterialsExport(): Code[20]
    begin
        exit('4250');
    end;

    internal procedure JobSalesAppliedRawMat(): Code[20]
    begin
        exit('4300');
    end;

    internal procedure JobSalesAdjmtRawMat(): Code[20]
    begin
        exit('4310');
    end;

    internal procedure TotalSalesofRawMaterials(): Code[20]
    begin
        exit('4330');
    end;

    internal procedure SalesofResources(): Code[20]
    begin
        exit('4340');
    end;

    internal procedure SalesResourcesDom(): Code[20]
    begin
        exit('4350');
    end;

    internal procedure SalesResourcesExport(): Code[20]
    begin
        exit('4400');
    end;

    internal procedure JobSalesAppliedResources(): Code[20]
    begin
        exit('4410');
    end;

    internal procedure JobSalesAdjmtResources(): Code[20]
    begin
        exit('4430');
    end;

    internal procedure TotalSalesofResources(): Code[20]
    begin
        exit('4439');
    end;

    internal procedure SalesofJobs(): Code[20]
    begin
        exit('4440');
    end;

    internal procedure SalesOtherJobExpenses(): Code[20]
    begin
        exit('4450');
    end;

    internal procedure JobSales(): Code[20]
    begin
        exit('4500');
    end;

    internal procedure TotalSalesofJobs(): Code[20]
    begin
        exit('4510');
    end;

    internal procedure SalesofServiceContracts(): Code[20]
    begin
        exit('4726');
    end;

    internal procedure ServiceContractSale(): Code[20]
    begin
        exit('4730');
    end;

    internal procedure TotalSaleofServContracts(): Code[20]
    begin
        exit('4740');
    end;

    internal procedure InterestIncome(): Code[20]
    begin
        exit('4751');
    end;

    internal procedure InterestonBankBalances(): Code[20]
    begin
        exit('4752');
    end;

    internal procedure FinanceChargesfromCustomers(): Code[20]
    begin
        exit('4753');
    end;

    internal procedure PaymentDiscountsReceived(): Code[20]
    begin
        exit('4754');
    end;

    internal procedure PmtDiscReceivedDecreases(): Code[20]
    begin
        exit('4755');
    end;

    internal procedure InvoiceRounding(): Code[20]
    begin
        exit('4756');
    end;

    internal procedure ApplicationRounding(): Code[20]
    begin
        exit('4757');
    end;

    internal procedure PaymentToleranceReceived(): Code[20]
    begin
        exit('4758');
    end;

    internal procedure PmtTolReceivedDecreases(): Code[20]
    begin
        exit('4759');
    end;

    internal procedure ConsultingFeesDom(): Code[20]
    begin
        exit('4780');
    end;

    internal procedure FeesandChargesRecDom(): Code[20]
    begin
        exit('4790');
    end;

    internal procedure DiscountGranted(): Code[20]
    begin
        exit('4795');
    end;

    internal procedure TotalInterestIncome(): Code[20]
    begin
        exit('4899');
    end;

    internal procedure TotalRevenue(): Code[20]
    begin
        exit('4900');
    end;

    internal procedure Cost(): Code[20]
    begin
        exit('5000');
    end;

    internal procedure CostofRetail(): Code[20]
    begin
        exit('5100');
    end;

    internal procedure PurchRetailDom(): Code[20]
    begin
        exit('5101');
    end;

    internal procedure PurchRetailExport(): Code[20]
    begin
        exit('5102');
    end;

    internal procedure DiscReceivedRetail(): Code[20]
    begin
        exit('5103');
    end;

    internal procedure FreightExpensesRetail(): Code[20]
    begin
        exit('5104');
    end;

    internal procedure InventoryAdjmtRetail(): Code[20]
    begin
        exit('5105');
    end;

    internal procedure JobCostAppliedRetail(): Code[20]
    begin
        exit('5106');
    end;

    internal procedure JobCostAdjmtRetail(): Code[20]
    begin
        exit('5107');
    end;

    internal procedure CostofRetailSold(): Code[20]
    begin
        exit('5108');
    end;

    internal procedure DirectCostAppliedRetail(): Code[20]
    begin
        exit('5109');
    end;

    internal procedure OverheadAppliedRetail(): Code[20]
    begin
        exit('5110');
    end;

    internal procedure PurchaseVarianceRetail(): Code[20]
    begin
        exit('5111');
    end;

    internal procedure TotalCostofRetail(): Code[20]
    begin
        exit('5299');
    end;

    internal procedure CostofRawMaterials(): Code[20]
    begin
        exit('5300');
    end;

    internal procedure PurchRawMaterialsDom(): Code[20]
    begin
        exit('5315');
    end;

    internal procedure PurchRawMaterialsExport(): Code[20]
    begin
        exit('5320');
    end;

    internal procedure DiscReceivedRawMaterials(): Code[20]
    begin
        exit('5330');
    end;

    internal procedure FreightExpensesRawMat(): Code[20]
    begin
        exit('5335');
    end;

    internal procedure InventoryAdjmtRawMat(): Code[20]
    begin
        exit('5340');
    end;

    internal procedure JobCostAppliedRawMat(): Code[20]
    begin
        exit('5345');
    end;

    internal procedure JobCostAdjmtRawMaterials(): Code[20]
    begin
        exit('5349');
    end;

    internal procedure CostofRawMaterialsSold(): Code[20]
    begin
        exit('5360');
    end;

    internal procedure DirectCostAppliedRawmat(): Code[20]
    begin
        exit('5370');
    end;

    internal procedure OverheadAppliedRawmat(): Code[20]
    begin
        exit('5380');
    end;

    internal procedure PurchaseVarianceRawmat(): Code[20]
    begin
        exit('5385');
    end;

    internal procedure TotalCostofRawMaterials(): Code[20]
    begin
        exit('5390');
    end;

    internal procedure CostofResources(): Code[20]
    begin
        exit('5400');
    end;

    internal procedure JobCostAppliedResources(): Code[20]
    begin
        exit('5420');
    end;

    internal procedure JobCostAdjmtResources(): Code[20]
    begin
        exit('5430');
    end;

    internal procedure CostofResourcesUsed(): Code[20]
    begin
        exit('5410');
    end;

    internal procedure TotalCostofResources(): Code[20]
    begin
        exit('5450');
    end;

    internal procedure JobCosts(): Code[20]
    begin
        exit('5459');
    end;

    internal procedure CostofCapacities(): Code[20]
    begin
        exit('5460');
    end;

    internal procedure CostofCapacitie(): Code[20]
    begin
        exit('5470');
    end;

    internal procedure DirectCostAppliedCap(): Code[20]
    begin
        exit('5471');
    end;

    internal procedure OverheadAppliedCap(): Code[20]
    begin
        exit('5472');
    end;

    internal procedure PurchaseVarianceCap(): Code[20]
    begin
        exit('5479');
    end;

    internal procedure TotalCostofCapacities(): Code[20]
    begin
        exit('5480');
    end;

    internal procedure Variance(): Code[20]
    begin
        exit('5490');
    end;

    internal procedure MaterialVariance(): Code[20]
    begin
        exit('5695');
    end;

    internal procedure CapacityVariance(): Code[20]
    begin
        exit('5700');
    end;

    internal procedure SubcontractedVariance(): Code[20]
    begin
        exit('5710');
    end;

    internal procedure CapOverheadVariance(): Code[20]
    begin
        exit('5720');
    end;

    internal procedure MfgOverheadVariance(): Code[20]
    begin
        exit('5730');
    end;

    internal procedure TotalVariance(): Code[20]
    begin
        exit('5731');
    end;

    internal procedure TotalCost(): Code[20]
    begin
        exit('5799');
    end;

    internal procedure OperatingExpenses(): Code[20]
    begin
        exit('6000');
    end;

    internal procedure BuildingMaintenanceExpenses(): Code[20]
    begin
        exit('6005');
    end;

    internal procedure Cleaning(): Code[20]
    begin
        exit('6010');
    end;

    internal procedure ElectricityandHeating(): Code[20]
    begin
        exit('6015');
    end;

    internal procedure RepairsandMaintenance(): Code[20]
    begin
        exit('6020');
    end;

    internal procedure TotalBldgMaintExpenses(): Code[20]
    begin
        exit('6025');
    end;

    internal procedure AdministrativeExpenses(): Code[20]
    begin
        exit('6035');
    end;

    internal procedure OfficeSupplies(): Code[20]
    begin
        exit('6040');
    end;

    internal procedure PhoneandFax(): Code[20]
    begin
        exit('6045');
    end;

    internal procedure Postage(): Code[20]
    begin
        exit('6050');
    end;

    internal procedure TotalAdministrativeExpenses(): Code[20]
    begin
        exit('6055');
    end;

    internal procedure ComputerExpenses(): Code[20]
    begin
        exit('6065');
    end;

    internal procedure Software(): Code[20]
    begin
        exit('6070');
    end;

    internal procedure ConsultantServices(): Code[20]
    begin
        exit('6080');
    end;

    internal procedure OtherComputerExpenses(): Code[20]
    begin
        exit('6190');
    end;

    internal procedure TotalComputerExpenses(): Code[20]
    begin
        exit('6199');
    end;

    internal procedure SellingExpenses(): Code[20]
    begin
        exit('6200');
    end;

    internal procedure Advertising(): Code[20]
    begin
        exit('6225');
    end;

    internal procedure EntertainmentandPR(): Code[20]
    begin
        exit('6235');
    end;

    internal procedure Travel(): Code[20]
    begin
        exit('6245');
    end;

    internal procedure FreightExpenseRawMat(): Code[20]
    begin
        exit('6255');
    end;

    internal procedure TotalSellingExpenses(): Code[20]
    begin
        exit('6299');
    end;

    internal procedure VehicleExpenses(): Code[20]
    begin
        exit('6300');
    end;

    internal procedure GasolineandMotorOil(): Code[20]
    begin
        exit('6325');
    end;

    internal procedure RegistrationFees(): Code[20]
    begin
        exit('6330');
    end;

    internal procedure RepairandMaintenance(): Code[20]
    begin
        exit('6398');
    end;

    internal procedure TotalVehicleExpenses(): Code[20]
    begin
        exit('6399');
    end;

    internal procedure OtherOperatingExpenses(): Code[20]
    begin
        exit('6400');
    end;

    internal procedure CashDiscrepancies(): Code[20]
    begin
        exit('6411');
    end;

    internal procedure BadDebtExpenses(): Code[20]
    begin
        exit('6412');
    end;

    internal procedure LegalandAccountingServices(): Code[20]
    begin
        exit('6413');
    end;

    internal procedure Miscellaneous(): Code[20]
    begin
        exit('6414');
    end;

    internal procedure OtherOperatingExpTotal(): Code[20]
    begin
        exit('6430');
    end;

    internal procedure TotalOperatingExpenses(): Code[20]
    begin
        exit('6499');
    end;

    internal procedure PersonnelExpenses(): Code[20]
    begin
        exit('6500');
    end;

    internal procedure Wages(): Code[20]
    begin
        exit('6520');
    end;

    internal procedure Salaries(): Code[20]
    begin
        exit('6530');
    end;

    internal procedure RetirementPlanContributions(): Code[20]
    begin
        exit('6540');
    end;

    internal procedure AnnualLeaveExpenses(): Code[20]
    begin
        exit('6560');
    end;

    internal procedure PayrollTaxes(): Code[20]
    begin
        exit('6570');
    end;

    internal procedure TotalPersonnelExpenses(): Code[20]
    begin
        exit('6599');
    end;

    internal procedure EBITDA(): Code[20]
    begin
        exit('7000');
    end;

    internal procedure DepreciationofFixedAssets(): Code[20]
    begin
        exit('7100');
    end;

    internal procedure DepreciationBuildings(): Code[20]
    begin
        exit('7110');
    end;

    internal procedure DepreciationEquipment(): Code[20]
    begin
        exit('7120');
    end;

    internal procedure DepreciationVehicles(): Code[20]
    begin
        exit('7130');
    end;

    internal procedure TotalFixedAssetDepreciation(): Code[20]
    begin
        exit('7140');
    end;

    internal procedure OtherCostsofOperations(): Code[20]
    begin
        exit('7150');
    end;

    internal procedure PurchaseWHTAdjustments(): Code[20]
    begin
        exit('7160');
    end;

    internal procedure SalesWHTAdjustments(): Code[20]
    begin
        exit('7170');
    end;

    internal procedure InterestExpenses(): Code[20]
    begin
        exit('7200');
    end;

    internal procedure InterestonRevolvingCredit(): Code[20]
    begin
        exit('7210');
    end;

    internal procedure InterestonBankLoans(): Code[20]
    begin
        exit('7220');
    end;

    internal procedure MortgageInterest(): Code[20]
    begin
        exit('7230');
    end;

    internal procedure FinanceChargestoVendors(): Code[20]
    begin
        exit('7240');
    end;

    internal procedure PmtDiscGrantedDecreases(): Code[20]
    begin
        exit('7250');
    end;

    internal procedure PaymentDiscountsGranted(): Code[20]
    begin
        exit('7260');
    end;

    internal procedure PaymentToleranceGranted(): Code[20]
    begin
        exit('7270');
    end;

    internal procedure PmtTolGrantedDecreases(): Code[20]
    begin
        exit('7280');
    end;

    internal procedure TotalInterestExpenses(): Code[20]
    begin
        exit('7290');
    end;

    internal procedure GAINSANDLOSSES(): Code[20]
    begin
        exit('7300');
    end;

    internal procedure UnrealizedFXGains(): Code[20]
    begin
        exit('7400');
    end;

    internal procedure UnrealizedFXLosses(): Code[20]
    begin
        exit('7500');
    end;

    internal procedure RealizedFXGains(): Code[20]
    begin
        exit('7600');
    end;

    internal procedure RealizedFXLosses(): Code[20]
    begin
        exit('7610');
    end;

    internal procedure GainsandLosse(): Code[20]
    begin
        exit('7620');
    end;

    internal procedure TOTALGAINSANDLOSSES(): Code[20]
    begin
        exit('7999');
    end;

    internal procedure NIBEFOREEXTRAITEMSANDTAXES(): Code[20]
    begin
        exit('8005');
    end;

    internal procedure IncomeTaxes(): Code[20]
    begin
        exit('8010');
    end;

    internal procedure CorporateTax(): Code[20]
    begin
        exit('8020');
    end;

    internal procedure ExtraordinaryExpenses(): Code[20]
    begin
        exit('8030');
    end;

    internal procedure TotalIncomeTaxes(): Code[20]
    begin
        exit('8049');
    end;

    internal procedure NETINCOMEBEFOREEXTRITEMS(): Code[20]
    begin
        exit('8099');
    end;

    internal procedure Othercomincomefortheperiodnetofinctax(): Code[20]
    begin
        exit('8060');
    end;

    internal procedure Othercomincomeperiodnetofinctax(): Code[20]
    begin
        exit('8070');
    end;

    internal procedure Totalcomprehensiveincomefortheperiod(): Code[20]
    begin
        exit('8199');
    end;

    internal procedure STMTOFFINANCIALPOSITIONName(): Text[100]
    begin
        exit(STMTOFFINANCIALPOSITIONTOK);
    end;

    internal procedure ASSETSName(): Text[100]
    begin
        exit(ASSETSTOK);
    end;

    internal procedure CurrentAssetsName(): Text[100]
    begin
        exit(CurrentAssetsTOK);
    end;

    internal procedure LiquidAssetsName(): Text[100]
    begin
        exit(LiquidAssetsTOK);
    end;

    internal procedure CashName(): Text[100]
    begin
        exit(CashTOK);
    end;

    internal procedure BankLCYName(): Text[100]
    begin
        exit(BankLCYTOK);
    end;

    internal procedure BankCurrenciesName(): Text[100]
    begin
        exit(BankCurrenciesTOK);
    end;

    internal procedure BankOtherName(): Text[100]
    begin
        exit(BankOtherTOK);
    end;

    internal procedure LiquidAssetsTotalName(): Text[100]
    begin
        exit(LiquidAssetsTotalTOK);
    end;

    internal procedure AccountsReceivableName(): Text[100]
    begin
        exit(AccountsReceivableTOK);
    end;

    internal procedure CustomersDomesticName(): Text[100]
    begin
        exit(CustomersDomesticTOK);
    end;

    internal procedure CustomersForeignName(): Text[100]
    begin
        exit(CustomersForeignTOK);
    end;

    internal procedure CustomersIntercompanyName(): Text[100]
    begin
        exit(CustomersIntercompanyTOK);
    end;

    internal procedure AccruedInterestName(): Text[100]
    begin
        exit(AccruedInterestTOK);
    end;

    internal procedure OtherReceivablesName(): Text[100]
    begin
        exit(OtherReceivablesTOK);
    end;

    internal procedure AccountsReceivableTotalName(): Text[100]
    begin
        exit(AccountsReceivableTotalTOK);
    end;

    internal procedure InventoryName(): Text[100]
    begin
        exit(InventoryTOK);
    end;

    internal procedure ResaleItemsName(): Text[100]
    begin
        exit(ResaleItemsTOK);
    end;

    internal procedure ResaleItemsInterimName(): Text[100]
    begin
        exit(ResaleItemsInterimTOK);
    end;

    internal procedure CostofResaleSoldInterimName(): Text[100]
    begin
        exit(CostofResaleSoldInterimTOK);
    end;

    internal procedure FinishedGoodsName(): Text[100]
    begin
        exit(FinishedGoodsTOK);
    end;

    internal procedure FinishedGoodsInterimName(): Text[100]
    begin
        exit(FinishedGoodsInterimTOK);
    end;

    internal procedure RawMaterialsName(): Text[100]
    begin
        exit(RawMaterialsTOK);
    end;

    internal procedure RawMaterialsInterimName(): Text[100]
    begin
        exit(RawMaterialsInterimTOK);
    end;

    internal procedure CostofRawMatSoldInterimName(): Text[100]
    begin
        exit(CostofRawMatSoldInterimTOK);
    end;

    internal procedure WIPAccountFinishedgoodsName(): Text[100]
    begin
        exit(WIPAccountFinishedgoodsTOK);
    end;

    internal procedure PrimoInventoryName(): Text[100]
    begin
        exit(PrimoInventoryTOK);
    end;

    internal procedure InventoryTotalName(): Text[100]
    begin
        exit(InventoryTotalTOK);
    end;

    internal procedure JobWIPName(): Text[100]
    begin
        exit(JobWIPTOK);
    end;

    internal procedure WIPSalesName(): Text[100]
    begin
        exit(WIPSalesTOK);
    end;

    internal procedure WIPJobSalesName(): Text[100]
    begin
        exit(WIPJobSalesTOK);
    end;

    internal procedure InvoicedJobSalesName(): Text[100]
    begin
        exit(InvoicedJobSalesTOK);
    end;

    internal procedure WIPSalesTotalName(): Text[100]
    begin
        exit(WIPSalesTotalTOK);
    end;

    internal procedure WIPCostsName(): Text[100]
    begin
        exit(WIPCostsTOK);
    end;

    internal procedure WIPJobCostsName(): Text[100]
    begin
        exit(WIPJobCostsTOK);
    end;

    internal procedure AccruedJobCostsName(): Text[100]
    begin
        exit(AccruedJobCostsTOK);
    end;

    internal procedure WIPCostsTotalName(): Text[100]
    begin
        exit(WIPCostsTotalTOK);
    end;

    internal procedure JobWIPTotalName(): Text[100]
    begin
        exit(JobWIPTotalTOK);
    end;

    internal procedure TotalCurrentAssetsName(): Text[100]
    begin
        exit(TotalCurrentAssetsTOK);
    end;

    internal procedure NonCurrentAssetsName(): Text[100]
    begin
        exit(NonCurrentAssetsTOK);
    end;

    internal procedure FinancialAssetsName(): Text[100]
    begin
        exit(FinancialAssetsTOK);
    end;

    internal procedure InvestmentsName(): Text[100]
    begin
        exit(InvestmentsTOK);
    end;

    internal procedure OtherFinancialassetsName(): Text[100]
    begin
        exit(OtherFinancialassetsTOK);
    end;

    internal procedure PurchasePrepaymentsName(): Text[100]
    begin
        exit(PurchasePrepaymentsTOK);
    end;

    internal procedure TotalFinancialAssetsName(): Text[100]
    begin
        exit(TotalFinancialAssetsTOK);
    end;

    internal procedure TangibleFixedAssetsName(): Text[100]
    begin
        exit(TangibleFixedAssetsTOK);
    end;

    internal procedure LandandBuildingsName(): Text[100]
    begin
        exit(LandandBuildingsTOK);
    end;

    internal procedure AccumDepreciationBuildingsName(): Text[100]
    begin
        exit(AccumDepreciationBuildingsTOK);
    end;

    internal procedure LandandBuildingsTotalName(): Text[100]
    begin
        exit(LandandBuildingsTotalTOK);
    end;

    internal procedure OfficeEquipmentName(): Text[100]
    begin
        exit(OfficeEquipmentTOK);
    end;

    internal procedure AccumDeprOperEquipName(): Text[100]
    begin
        exit(AccumDeprOperEquipTOK);
    end;

    internal procedure OfficeEquipmentTotalName(): Text[100]
    begin
        exit(OfficeEquipmentTotalTOK);
    end;

    internal procedure VehiclesName(): Text[100]
    begin
        exit(VehiclesTOK);
    end;

    internal procedure AccumDepreciationVehiclesName(): Text[100]
    begin
        exit(AccumDepreciationVehiclesTOK);
    end;

    internal procedure VehiclesTotalName(): Text[100]
    begin
        exit(VehiclesTotalTOK);
    end;

    internal procedure TangibleFixedAssetsTotalName(): Text[100]
    begin
        exit(TangibleFixedAssetsTotalTOK);
    end;

    internal procedure IntangibleAssetsName(): Text[100]
    begin
        exit(IntangibleAssetsTOK);
    end;

    internal procedure AccAmortnonIntangiblesName(): Text[100]
    begin
        exit(AccAmortnonIntangiblesTOK);
    end;

    internal procedure IntangibleAssetsTotalName(): Text[100]
    begin
        exit(IntangibleAssetsTotalTOK);
    end;

    internal procedure RighttouseassetsName(): Text[100]
    begin
        exit(RighttouseassetsTOK);
    end;

    internal procedure RighttouseleasesName(): Text[100]
    begin
        exit(RighttouseleasesTOK);
    end;

    internal procedure AccAmortnonRightofuseLeasesName(): Text[100]
    begin
        exit(AccAmortnonRightofuseLeasesTOK);
    end;

    internal procedure RighttouseassetsTotalName(): Text[100]
    begin
        exit(RighttouseassetsTotalTOK);
    end;

    internal procedure TotalNonCurrentAssetsName(): Text[100]
    begin
        exit(TotalNonCurrentAssetsTOK);
    end;

    internal procedure TotalAssetsName(): Text[100]
    begin
        exit(TotalAssetsTOK);
    end;

    internal procedure LiabilitiesName(): Text[100]
    begin
        exit(LiabilitiesTOK);
    end;

    internal procedure LongtermLiabilitiesName(): Text[100]
    begin
        exit(LongtermLiabilitiesTOK);
    end;

    internal procedure LongtermBankLoansName(): Text[100]
    begin
        exit(LongtermBankLoansTOK);
    end;

    internal procedure MortgageName(): Text[100]
    begin
        exit(MortgageTOK);
    end;

    internal procedure LongtermLiabilitiesTotalName(): Text[100]
    begin
        exit(LongtermLiabilitiesTotalTOK);
    end;

    internal procedure ShorttermLiabilitiesName(): Text[100]
    begin
        exit(ShorttermLiabilitiesTOK);
    end;

    internal procedure RevolvingCreditName(): Text[100]
    begin
        exit(RevolvingCreditTOK);
    end;

    internal procedure SalesPrepaymentsName(): Text[100]
    begin
        exit(SalesPrepaymentsTOK);
    end;

    internal procedure PrepaidServiceContractsName(): Text[100]
    begin
        exit(PrepaidServiceContractsTOK);
    end;

    internal procedure DeferredRevenueName(): Text[100]
    begin
        exit(DeferredRevenueTOK);
    end;

    internal procedure DeferredTaxesName(): Text[100]
    begin
        exit(DeferredTaxesTOK);
    end;

    internal procedure TradeandOtherPayablesName(): Text[100]
    begin
        exit(TradeandOtherPayablesTOK);
    end;

    internal procedure AccountspayableName(): Text[100]
    begin
        exit(AccountspayableTOK);
    end;

    internal procedure VendorsDomesticName(): Text[100]
    begin
        exit(VendorsDomesticTOK);
    end;

    internal procedure VendorsForeignName(): Text[100]
    begin
        exit(VendorsForeignTOK);
    end;

    internal procedure VendorsIntercompanyName(): Text[100]
    begin
        exit(VendorsIntercompanyTOK);
    end;

    internal procedure AccruedExpensesName(): Text[100]
    begin
        exit(AccruedExpensesTOK);
    end;

    internal procedure ProvisionforIncomeTaxName(): Text[100]
    begin
        exit(ProvisionforIncomeTaxTOK);
    end;

    internal procedure ProvisionforAnnualLeaveName(): Text[100]
    begin
        exit(ProvisionforAnnualLeaveTOK);
    end;

    internal procedure SuperannuationclearingName(): Text[100]
    begin
        exit(SuperannuationclearingTOK);
    end;

    internal procedure PayrollclearingName(): Text[100]
    begin
        exit(PayrollclearingTOK);
    end;

    internal procedure PayrollDeductionsName(): Text[100]
    begin
        exit(PayrollDeductionsTOK);
    end;

    internal procedure InvAdjmtInterimName(): Text[100]
    begin
        exit(InvAdjmtInterimTOK);
    end;

    internal procedure InvAdjmtInterimRawMatName(): Text[100]
    begin
        exit(InvAdjmtInterimRawMatTOK);
    end;

    internal procedure InvAdjmtInterimRetailName(): Text[100]
    begin
        exit(InvAdjmtInterimRetailTOK);
    end;

    internal procedure InvAdjmtInterimTotalName(): Text[100]
    begin
        exit(InvAdjmtInterimTotalTOK);
    end;

    internal procedure TaxesPayablesName(): Text[100]
    begin
        exit(TaxesPayablesTOK);
    end;

    internal procedure GSTPayableName(): Text[100]
    begin
        exit(GSTPayableTOK);
    end;

    internal procedure GSTReceivableName(): Text[100]
    begin
        exit(GSTReceivableTOK);
    end;

    internal procedure GSTClearingName(): Text[100]
    begin
        exit(GSTClearingTOK);
    end;

    internal procedure GSTReconName(): Text[100]
    begin
        exit(GSTReconTOK);
    end;

    internal procedure WHTTaxPayableName(): Text[100]
    begin
        exit(WHTTaxPayableTOK);
    end;

    internal procedure WHTPrepaidName(): Text[100]
    begin
        exit(WHTPrepaidTOK);
    end;

    internal procedure TaxesPayablesTotalName(): Text[100]
    begin
        exit(TaxesPayablesTotalTOK);
    end;

    internal procedure PersonnelrelatedItemsName(): Text[100]
    begin
        exit(PersonnelrelatedItemsTOK);
    end;

    internal procedure WithholdingTaxesPayableName(): Text[100]
    begin
        exit(WithholdingTaxesPayableTOK);
    end;

    internal procedure SupplementaryTaxesPayableName(): Text[100]
    begin
        exit(SupplementaryTaxesPayableTOK);
    end;

    internal procedure PayrollTaxesPayableName(): Text[100]
    begin
        exit(PayrollTaxesPayableTOK);
    end;

    internal procedure VacationCompensationPayableName(): Text[100]
    begin
        exit(VacationCompensationPayableTOK);
    end;

    internal procedure EmployeesPayableName(): Text[100]
    begin
        exit(EmployeesPayableTOK);
    end;

    internal procedure TotalPersonnelrelatedItemsName(): Text[100]
    begin
        exit(TotalPersonnelrelatedItemsTOK);
    end;

    internal procedure UnearnedRevenueOtherName(): Text[100]
    begin
        exit(UnearnedRevenueOtherTOK);
    end;

    internal procedure FundsreceivedinadvanceName(): Text[100]
    begin
        exit(FundsreceivedinadvanceTOK);
    end;

    internal procedure OthercurrentliabilitiesName(): Text[100]
    begin
        exit(OthercurrentliabilitiesTOK);
    end;

    internal procedure TotalUnearnedRevenueOtherName(): Text[100]
    begin
        exit(TotalUnearnedRevenueOtherTOK);
    end;

    internal procedure ShorttermLiabilitiesTotalName(): Text[100]
    begin
        exit(ShorttermLiabilitiesTotalTOK);
    end;

    internal procedure NonCurrentLiabilitiesName(): Text[100]
    begin
        exit(NonCurrentLiabilitiesTOK);
    end;

    internal procedure EmployeeProvisionsName(): Text[100]
    begin
        exit(EmployeeProvisionsTOK);
    end;

    internal procedure LongserviceleaveName(): Text[100]
    begin
        exit(LongserviceleaveTOK);
    end;

    internal procedure TotalEmployeeProvisionsName(): Text[100]
    begin
        exit(TotalEmployeeProvisionsTOK);
    end;

    internal procedure OtherLiabilitiesName(): Text[100]
    begin
        exit(OtherLiabilitiesTOK);
    end;

    internal procedure DividendsfortheFiscalYearName(): Text[100]
    begin
        exit(DividendsfortheFiscalYearTOK);
    end;

    internal procedure CorporateTaxesPayableName(): Text[100]
    begin
        exit(CorporateTaxesPayableTOK);
    end;

    internal procedure OtherLiabilitiesTotalName(): Text[100]
    begin
        exit(OtherLiabilitiesTotalTOK);
    end;

    internal procedure TotalNonCurrentLiabilitiesName(): Text[100]
    begin
        exit(TotalNonCurrentLiabilitiesTOK);
    end;

    internal procedure TotalLiabilitiesName(): Text[100]
    begin
        exit(TotalLiabilitiesTOK);
    end;

    internal procedure LIABILITIESANDEQUITYName(): Text[100]
    begin
        exit(LIABILITIESANDEQUITYTOK);
    end;

    internal procedure StockholdersEquityName(): Text[100]
    begin
        exit(StockholdersEquityTOK);
    end;

    internal procedure CapitalStockName(): Text[100]
    begin
        exit(CapitalStockTOK);
    end;

    internal procedure RetainedEarningsName(): Text[100]
    begin
        exit(RetainedEarningsTOK);
    end;

    internal procedure AllowancesName(): Text[100]
    begin
        exit(AllowancesTOK);
    end;

    internal procedure NetIncomefortheYearName(): Text[100]
    begin
        exit(NetIncomefortheYearTOK);
    end;

    internal procedure TotalStockholdersEquityName(): Text[100]
    begin
        exit(TotalStockholdersEquityTOK);
    end;

    internal procedure TOTALLIABILITIESANDEQUITYName(): Text[100]
    begin
        exit(TOTALLIABILITIESANDEQUITYTOK);
    end;

    internal procedure INCOMESTATEMENTName(): Text[100]
    begin
        exit(INCOMESTATEMENTTOK);
    end;

    internal procedure RevenueName(): Text[100]
    begin
        exit(RevenueTOK);
    end;

    internal procedure SalesofRetailName(): Text[100]
    begin
        exit(SalesofRetailTOK);
    end;

    internal procedure SalesRetailDomName(): Text[100]
    begin
        exit(SalesRetailDomTOK);
    end;

    internal procedure StockSalesName(): Text[100]
    begin
        exit(StockSalesTOK);
    end;

    internal procedure HireIncomeName(): Text[100]
    begin
        exit(HireIncomeTOK);
    end;

    internal procedure RentalIncomeName(): Text[100]
    begin
        exit(RentalIncomeTOK);
    end;

    internal procedure SalesRetailExportName(): Text[100]
    begin
        exit(SalesRetailExportTOK);
    end;

    internal procedure JobSalesAppliedRetailName(): Text[100]
    begin
        exit(JobSalesAppliedRetailTOK);
    end;

    internal procedure JobSalesAdjmtRetailName(): Text[100]
    begin
        exit(JobSalesAdjmtRetailTOK);
    end;

    internal procedure TotalSalesofRetailName(): Text[100]
    begin
        exit(TotalSalesofRetailTOK);
    end;

    internal procedure SalesofRawMaterialsName(): Text[100]
    begin
        exit(SalesofRawMaterialsTOK);
    end;

    internal procedure SalesRawMaterialsDomName(): Text[100]
    begin
        exit(SalesRawMaterialsDomTOK);
    end;

    internal procedure SalesRawMaterialsExportName(): Text[100]
    begin
        exit(SalesRawMaterialsExportTOK);
    end;

    internal procedure JobSalesAppliedRawMatName(): Text[100]
    begin
        exit(JobSalesAppliedRawMatTOK);
    end;

    internal procedure JobSalesAdjmtRawMatName(): Text[100]
    begin
        exit(JobSalesAdjmtRawMatTOK);
    end;

    internal procedure TotalSalesofRawMaterialsName(): Text[100]
    begin
        exit(TotalSalesofRawMaterialsTOK);
    end;

    internal procedure SalesofResourcesName(): Text[100]
    begin
        exit(SalesofResourcesTOK);
    end;

    internal procedure SalesResourcesDomName(): Text[100]
    begin
        exit(SalesResourcesDomTOK);
    end;

    internal procedure SalesResourcesExportName(): Text[100]
    begin
        exit(SalesResourcesExportTOK);
    end;

    internal procedure JobSalesAppliedResourcesName(): Text[100]
    begin
        exit(JobSalesAppliedResourcesTOK);
    end;

    internal procedure JobSalesAdjmtResourcesName(): Text[100]
    begin
        exit(JobSalesAdjmtResourcesTOK);
    end;

    internal procedure TotalSalesofResourcesName(): Text[100]
    begin
        exit(TotalSalesofResourcesTOK);
    end;

    internal procedure SalesofJobsName(): Text[100]
    begin
        exit(SalesofJobsTOK);
    end;

    internal procedure SalesOtherJobExpensesName(): Text[100]
    begin
        exit(SalesOtherJobExpensesTOK);
    end;

    internal procedure JobSalesName(): Text[100]
    begin
        exit(JobSalesTOK);
    end;

    internal procedure TotalSalesofJobsName(): Text[100]
    begin
        exit(TotalSalesofJobsTOK);
    end;

    internal procedure SalesofServiceContractsName(): Text[100]
    begin
        exit(SalesofServiceContractsTOK);
    end;

    internal procedure ServiceContractSaleName(): Text[100]
    begin
        exit(ServiceContractSaleTOK);
    end;

    internal procedure TotalSaleofServContractsName(): Text[100]
    begin
        exit(TotalSaleofServContractsTOK);
    end;

    internal procedure InterestIncomeName(): Text[100]
    begin
        exit(InterestIncomeTOK);
    end;

    internal procedure InterestonBankBalancesName(): Text[100]
    begin
        exit(InterestonBankBalancesTOK);
    end;

    internal procedure FinanceChargesfromCustomersName(): Text[100]
    begin
        exit(FinanceChargesfromCustomersTOK);
    end;

    internal procedure PaymentDiscountsReceivedName(): Text[100]
    begin
        exit(PaymentDiscountsReceivedTOK);
    end;

    internal procedure PmtDiscReceivedDecreasesName(): Text[100]
    begin
        exit(PmtDiscReceivedDecreasesTOK);
    end;

    internal procedure InvoiceRoundingName(): Text[100]
    begin
        exit(InvoiceRoundingTOK);
    end;

    internal procedure ApplicationRoundingName(): Text[100]
    begin
        exit(ApplicationRoundingTOK);
    end;

    internal procedure PaymentToleranceReceivedName(): Text[100]
    begin
        exit(PaymentToleranceReceivedTOK);
    end;

    internal procedure PmtTolReceivedDecreasesName(): Text[100]
    begin
        exit(PmtTolReceivedDecreasesTOK);
    end;

    internal procedure ConsultingFeesDomName(): Text[100]
    begin
        exit(ConsultingFeesDomTOK);
    end;

    internal procedure FeesandChargesRecDomName(): Text[100]
    begin
        exit(FeesandChargesRecDomTOK);
    end;

    internal procedure DiscountGrantedName(): Text[100]
    begin
        exit(DiscountGrantedTOK);
    end;

    internal procedure TotalInterestIncomeName(): Text[100]
    begin
        exit(TotalInterestIncomeTOK);
    end;

    internal procedure TotalRevenueName(): Text[100]
    begin
        exit(TotalRevenueTOK);
    end;

    internal procedure CostName(): Text[100]
    begin
        exit(CostTOK);
    end;

    internal procedure CostofRetailName(): Text[100]
    begin
        exit(CostofRetailTOK);
    end;

    internal procedure PurchRetailDomName(): Text[100]
    begin
        exit(PurchRetailDomTOK);
    end;

    internal procedure PurchRetailExportName(): Text[100]
    begin
        exit(PurchRetailExportTOK);
    end;

    internal procedure DiscReceivedRetailName(): Text[100]
    begin
        exit(DiscReceivedRetailTOK);
    end;

    internal procedure FreightExpensesRetailName(): Text[100]
    begin
        exit(FreightExpensesRetailTOK);
    end;

    internal procedure InventoryAdjmtRetailName(): Text[100]
    begin
        exit(InventoryAdjmtRetailTOK);
    end;

    internal procedure JobCostAppliedRetailName(): Text[100]
    begin
        exit(JobCostAppliedRetailTOK);
    end;

    internal procedure JobCostAdjmtRetailName(): Text[100]
    begin
        exit(JobCostAdjmtRetailTOK);
    end;

    internal procedure CostofRetailSoldName(): Text[100]
    begin
        exit(CostofRetailSoldTOK);
    end;

    internal procedure DirectCostAppliedRetailName(): Text[100]
    begin
        exit(DirectCostAppliedRetailTOK);
    end;

    internal procedure OverheadAppliedRetailName(): Text[100]
    begin
        exit(OverheadAppliedRetailTOK);
    end;

    internal procedure PurchaseVarianceRetailName(): Text[100]
    begin
        exit(PurchaseVarianceRetailTOK);
    end;

    internal procedure TotalCostofRetailName(): Text[100]
    begin
        exit(TotalCostofRetailTOK);
    end;

    internal procedure CostofRawMaterialsName(): Text[100]
    begin
        exit(CostofRawMaterialsTOK);
    end;

    internal procedure PurchRawMaterialsDomName(): Text[100]
    begin
        exit(PurchRawMaterialsDomTOK);
    end;

    internal procedure PurchRawMaterialsExportName(): Text[100]
    begin
        exit(PurchRawMaterialsExportTOK);
    end;

    internal procedure DiscReceivedRawMaterialsName(): Text[100]
    begin
        exit(DiscReceivedRawMaterialsTOK);
    end;

    internal procedure FreightExpensesRawMatName(): Text[100]
    begin
        exit(FreightExpensesRawMatTOK);
    end;

    internal procedure InventoryAdjmtRawMatName(): Text[100]
    begin
        exit(InventoryAdjmtRawMatTOK);
    end;

    internal procedure JobCostAppliedRawMatName(): Text[100]
    begin
        exit(JobCostAppliedRawMatTOK);
    end;

    internal procedure JobCostAdjmtRawMaterialsName(): Text[100]
    begin
        exit(JobCostAdjmtRawMaterialsTOK);
    end;

    internal procedure CostofRawMaterialsSoldName(): Text[100]
    begin
        exit(CostofRawMaterialsSoldTOK);
    end;

    internal procedure DirectCostAppliedRawmatName(): Text[100]
    begin
        exit(DirectCostAppliedRawmatTOK);
    end;

    internal procedure OverheadAppliedRawmatName(): Text[100]
    begin
        exit(OverheadAppliedRawmatTOK);
    end;

    internal procedure PurchaseVarianceRawmatName(): Text[100]
    begin
        exit(PurchaseVarianceRawmatTOK);
    end;

    internal procedure TotalCostofRawMaterialsName(): Text[100]
    begin
        exit(TotalCostofRawMaterialsTOK);
    end;

    internal procedure CostofResourcesName(): Text[100]
    begin
        exit(CostofResourcesTOK);
    end;

    internal procedure JobCostAppliedResourcesName(): Text[100]
    begin
        exit(JobCostAppliedResourcesTOK);
    end;

    internal procedure JobCostAdjmtResourcesName(): Text[100]
    begin
        exit(JobCostAdjmtResourcesTOK);
    end;

    internal procedure CostofResourcesUsedName(): Text[100]
    begin
        exit(CostofResourcesUsedTOK);
    end;

    internal procedure TotalCostofResourcesName(): Text[100]
    begin
        exit(TotalCostofResourcesTOK);
    end;

    internal procedure JobCostsName(): Text[100]
    begin
        exit(JobCostsTOK);
    end;

    internal procedure CostofCapacitiesName(): Text[100]
    begin
        exit(CostofCapacitiesTOK);
    end;

    internal procedure DirectCostAppliedCapName(): Text[100]
    begin
        exit(DirectCostAppliedCapTOK);
    end;

    internal procedure OverheadAppliedCapName(): Text[100]
    begin
        exit(OverheadAppliedCapTOK);
    end;

    internal procedure PurchaseVarianceCapName(): Text[100]
    begin
        exit(PurchaseVarianceCapTOK);
    end;

    internal procedure TotalCostofCapacitiesName(): Text[100]
    begin
        exit(TotalCostofCapacitiesTOK);
    end;

    internal procedure VarianceName(): Text[100]
    begin
        exit(VarianceTOK);
    end;

    internal procedure MaterialVarianceName(): Text[100]
    begin
        exit(MaterialVarianceTOK);
    end;

    internal procedure CapacityVarianceName(): Text[100]
    begin
        exit(CapacityVarianceTOK);
    end;

    internal procedure SubcontractedVarianceName(): Text[100]
    begin
        exit(SubcontractedVarianceTOK);
    end;

    internal procedure CapOverheadVarianceName(): Text[100]
    begin
        exit(CapOverheadVarianceTOK);
    end;

    internal procedure MfgOverheadVarianceName(): Text[100]
    begin
        exit(MfgOverheadVarianceTOK);
    end;

    internal procedure TotalVarianceName(): Text[100]
    begin
        exit(TotalVarianceTOK);
    end;

    internal procedure TotalCostName(): Text[100]
    begin
        exit(TotalCostTOK);
    end;

    internal procedure OperatingExpensesName(): Text[100]
    begin
        exit(OperatingExpensesTOK);
    end;

    internal procedure BuildingMaintenanceExpensesName(): Text[100]
    begin
        exit(BuildingMaintenanceExpensesTOK);
    end;

    internal procedure CleaningName(): Text[100]
    begin
        exit(CleaningTOK);
    end;

    internal procedure ElectricityandHeatingName(): Text[100]
    begin
        exit(ElectricityandHeatingTOK);
    end;

    internal procedure RepairsandMaintenanceName(): Text[100]
    begin
        exit(RepairsandMaintenanceTOK);
    end;

    internal procedure TotalBldgMaintExpensesName(): Text[100]
    begin
        exit(TotalBldgMaintExpensesTOK);
    end;

    internal procedure AdministrativeExpensesName(): Text[100]
    begin
        exit(AdministrativeExpensesTOK);
    end;

    internal procedure OfficeSuppliesName(): Text[100]
    begin
        exit(OfficeSuppliesTOK);
    end;

    internal procedure PhoneandFaxName(): Text[100]
    begin
        exit(PhoneandFaxTOK);
    end;

    internal procedure PostageName(): Text[100]
    begin
        exit(PostageTOK);
    end;

    internal procedure TotalAdministrativeExpensesName(): Text[100]
    begin
        exit(TotalAdministrativeExpensesTOK);
    end;

    internal procedure ComputerExpensesName(): Text[100]
    begin
        exit(ComputerExpensesTOK);
    end;

    internal procedure SoftwareName(): Text[100]
    begin
        exit(SoftwareTOK);
    end;

    internal procedure ConsultantServicesName(): Text[100]
    begin
        exit(ConsultantServicesTOK);
    end;

    internal procedure OtherComputerExpensesName(): Text[100]
    begin
        exit(OtherComputerExpensesTOK);
    end;

    internal procedure TotalComputerExpensesName(): Text[100]
    begin
        exit(TotalComputerExpensesTOK);
    end;

    internal procedure SellingExpensesName(): Text[100]
    begin
        exit(SellingExpensesTOK);
    end;

    internal procedure AdvertisingName(): Text[100]
    begin
        exit(AdvertisingTOK);
    end;

    internal procedure EntertainmentandPRName(): Text[100]
    begin
        exit(EntertainmentandPRTOK);
    end;

    internal procedure TravelName(): Text[100]
    begin
        exit(TravelTOK);
    end;

    internal procedure TotalSellingExpensesName(): Text[100]
    begin
        exit(TotalSellingExpensesTOK);
    end;

    internal procedure VehicleExpensesName(): Text[100]
    begin
        exit(VehicleExpensesTOK);
    end;

    internal procedure GasolineandMotorOilName(): Text[100]
    begin
        exit(GasolineandMotorOilTOK);
    end;

    internal procedure RegistrationFeesName(): Text[100]
    begin
        exit(RegistrationFeesTOK);
    end;

    internal procedure TotalVehicleExpensesName(): Text[100]
    begin
        exit(TotalVehicleExpensesTOK);
    end;

    internal procedure OtherOperatingExpensesName(): Text[100]
    begin
        exit(OtherOperatingExpensesTOK);
    end;

    internal procedure CashDiscrepanciesName(): Text[100]
    begin
        exit(CashDiscrepanciesTOK);
    end;

    internal procedure BadDebtExpensesName(): Text[100]
    begin
        exit(BadDebtExpensesTOK);
    end;

    internal procedure LegalandAccountingServicesName(): Text[100]
    begin
        exit(LegalandAccountingServicesTOK);
    end;

    internal procedure MiscellaneousName(): Text[100]
    begin
        exit(MiscellaneousTOK);
    end;

    internal procedure OtherOperatingExpTotalName(): Text[100]
    begin
        exit(OtherOperatingExpTotalTOK);
    end;

    internal procedure TotalOperatingExpensesName(): Text[100]
    begin
        exit(TotalOperatingExpensesTOK);
    end;

    internal procedure PersonnelExpensesName(): Text[100]
    begin
        exit(PersonnelExpensesTOK);
    end;

    internal procedure WagesName(): Text[100]
    begin
        exit(WagesTOK);
    end;

    internal procedure SalariesName(): Text[100]
    begin
        exit(SalariesTOK);
    end;

    internal procedure RetirementPlanContributionsName(): Text[100]
    begin
        exit(RetirementPlanContributionsTOK);
    end;

    internal procedure AnnualLeaveExpensesName(): Text[100]
    begin
        exit(AnnualLeaveExpensesTOK);
    end;

    internal procedure PayrollTaxesName(): Text[100]
    begin
        exit(PayrollTaxesTOK);
    end;

    internal procedure TotalPersonnelExpensesName(): Text[100]
    begin
        exit(TotalPersonnelExpensesTOK);
    end;

    internal procedure EBITDAName(): Text[100]
    begin
        exit(EBITDATOK);
    end;

    internal procedure DepreciationofFixedAssetsName(): Text[100]
    begin
        exit(DepreciationofFixedAssetsTOK);
    end;

    internal procedure DepreciationBuildingsName(): Text[100]
    begin
        exit(DepreciationBuildingsTOK);
    end;

    internal procedure DepreciationEquipmentName(): Text[100]
    begin
        exit(DepreciationEquipmentTOK);
    end;

    internal procedure DepreciationVehiclesName(): Text[100]
    begin
        exit(DepreciationVehiclesTOK);
    end;

    internal procedure TotalFixedAssetDepreciationName(): Text[100]
    begin
        exit(TotalFixedAssetDepreciationTOK);
    end;

    internal procedure OtherCostsofOperationsName(): Text[100]
    begin
        exit(OtherCostsofOperationsTOK);
    end;

    internal procedure PurchaseWHTAdjustmentsName(): Text[100]
    begin
        exit(PurchaseWHTAdjustmentsTOK);
    end;

    internal procedure SalesWHTAdjustmentsName(): Text[100]
    begin
        exit(SalesWHTAdjustmentsTOK);
    end;

    internal procedure InterestExpensesName(): Text[100]
    begin
        exit(InterestExpensesTOK);
    end;

    internal procedure InterestonRevolvingCreditName(): Text[100]
    begin
        exit(InterestonRevolvingCreditTOK);
    end;

    internal procedure InterestonBankLoansName(): Text[100]
    begin
        exit(InterestonBankLoansTOK);
    end;

    internal procedure MortgageInterestName(): Text[100]
    begin
        exit(MortgageInterestTOK);
    end;

    internal procedure FinanceChargestoVendorsName(): Text[100]
    begin
        exit(FinanceChargestoVendorsTOK);
    end;

    internal procedure PmtDiscGrantedDecreasesName(): Text[100]
    begin
        exit(PmtDiscGrantedDecreasesTOK);
    end;

    internal procedure PaymentDiscountsGrantedName(): Text[100]
    begin
        exit(PaymentDiscountsGrantedTOK);
    end;

    internal procedure PaymentToleranceGrantedName(): Text[100]
    begin
        exit(PaymentToleranceGrantedTOK);
    end;

    internal procedure PmtTolGrantedDecreasesName(): Text[100]
    begin
        exit(PmtTolGrantedDecreasesTOK);
    end;

    internal procedure TotalInterestExpensesName(): Text[100]
    begin
        exit(TotalInterestExpensesTOK);
    end;

    internal procedure GAINSANDLOSSESName(): Text[100]
    begin
        exit(GAINSANDLOSSESTOK);
    end;

    internal procedure UnrealizedFXGainsName(): Text[100]
    begin
        exit(UnrealizedFXGainsTOK);
    end;

    internal procedure UnrealizedFXLossesName(): Text[100]
    begin
        exit(UnrealizedFXLossesTOK);
    end;

    internal procedure RealizedFXGainsName(): Text[100]
    begin
        exit(RealizedFXGainsTOK);
    end;

    internal procedure RealizedFXLossesName(): Text[100]
    begin
        exit(RealizedFXLossesTOK);
    end;

    internal procedure TOTALGAINSANDLOSSESName(): Text[100]
    begin
        exit(TOTALGAINSANDLOSSESTOK);
    end;

    internal procedure NIBEFOREEXTRAITEMSANDTAXESName(): Text[100]
    begin
        exit(NIBEFOREEXTRAITEMSANDTAXESTOK);
    end;

    internal procedure IncomeTaxesName(): Text[100]
    begin
        exit(IncomeTaxesTOK);
    end;

    internal procedure CorporateTaxName(): Text[100]
    begin
        exit(CorporateTaxTOK);
    end;

    internal procedure ExtraordinaryExpensesName(): Text[100]
    begin
        exit(ExtraordinaryExpensesTOK);
    end;

    internal procedure TotalIncomeTaxesName(): Text[100]
    begin
        exit(TotalIncomeTaxesTOK);
    end;

    internal procedure OthercomincomefortheperiodnetofinctaxName(): Text[100]
    begin
        exit(OthercomincomefortheperiodnetofinctaxTOK);
    end;

    internal procedure TotalcomprehensiveincomefortheperiodName(): Text[100]
    begin
        exit(TotalcomprehensiveincomefortheperiodTOK);
    end;

    internal procedure NETINCOMEBEFOREEXTRITEMSName(): Text[100]
    begin
        exit(NETINCOMEBEFOREEXTRITEMSTOK);
    end;

}

