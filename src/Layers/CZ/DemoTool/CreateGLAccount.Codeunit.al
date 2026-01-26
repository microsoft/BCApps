codeunit 101015 "Create G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('001000', XFixedAssets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('010000', XIntangibleFixedAssets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('012100', XIntangibleresultsofresearchanddevelopment, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('013100', XSoftware, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('014100', XValuablerights, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('015100', XGoodwill, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('019100', XOtherintangiblefixedassets, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('019999', XIntangibleFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('020000', XTangibleFixedAssets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('021100', XBuildings, 0, 1, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('022100', XMachinesToolsEquipment, 0, 1, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('022300', XVehicles, 0, 1, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', false);
        InsertData('029990', XTangibleFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('030000', XTangiblefixedassetsnondeductible, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('031100', XLands, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('039999', XTangiblefixedassetsnondeductibletotal, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('041100', XAcquisitionOfIntangibleFixedAssets, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('042000', XAcquisitionOfTangibleFixedAssets, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('042100', XAcquisitionOfBuildings, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('042200', XAcquisitionOfMachinery, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('042300', XAcquisitionOfVehicles, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('042990', XAcquisitionOfTangibleFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('070000', XCorrectionstointangiblefixedassets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('072100', XCorrectionstointangibleresultsofresearchanddevelopment, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('073100', XCorrectionstosoftware, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('074100', XCorrectionstovaluablerights, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('075100', XCorrectionstogoodwill, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('079100', XCorrectionstootherintangiblefixedassets, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('079999', XCorrectionstointangiblefixedassetstotal, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('081000', XAccumulatedDepreciationOfFixedAssets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('081100', XAccumulatedDepreciationOfBuildings, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('082100', XAccumulatedDepreciationOfMachinery, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('082300', XAccumulatedDepreciationOfVehicles, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('089990', XAccumulatedDepreciationOfFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('110000', XFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('111000', XAcquisitionOfMaterial, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('111100', XAcquisitionOfMaterial, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('112050', XMaterialInStockInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('112100', XMaterialInStock, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('119999', XAcquisitionOfMaterialTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('121000', XFinishedProducts, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('121100', XWorkInProgress, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('123050', XFinishedProductsInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('123100', XFinishedProducts, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('129990', XFinishedProductsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('131000', XAcquisitionOfGoods, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('131050', XAcquisitionOfGoods, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('131450', XAcquisitionRetail, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', false);
        InsertData('131455', XAcquisitionRetailInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('131500', XAcquisitionRawMaterialDomestic, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('131600', XAcquisitionRawMaterialEu, 0, 1, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('131700', XAcquisitionRawMaterialExport, 0, 1, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', false);
        InsertData('131950', XAcquisitionRawMaterial, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('131955', XAcquisitionRawMaterialInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('131990', XAcquisitionOfGoodsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('132000', XGoodsInStock, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('132100', XGoodsInRetail, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('132110', XGoodsInRetailInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('139990', XGoodsInStockTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('210000', XCash, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('211100', XCashDeskLm, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('221100', XBankAccountKB, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('221200', XBankAccountEUR, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('231100', XShortTermBankLoans, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('251100', XShortTermSecurities, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('261100', XCashtransfer, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('261900', XUnidentifiedpayments, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('299990', XCashTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('310000', XReceivables, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('311100', XDomesticCustomersReceivables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('311200', XForeignCustomersOutsideEUReceivables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('311300', XEUCustomersReceivables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('311910', XReceivablesFromBusinessRelationFees, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('314100', XPurchaseAdvancesDomestic, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('314200', XPurchaseAdvancesForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('314300', XPurchaseAdvancesEU, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('315100', XOtherReceivables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('319999', XReceivablesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('320000', XPayables, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('321100', XDomesticVendorsPayables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('321200', XForeignVendorsOutsideEUPayables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('321300', XEUVendorsPayables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('324100', XSalesAdvancesDomestic, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('324200', XSalesAdvancesForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('324300', XSalesAdvancesEU, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('325100', XOtherpayables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('329999', XPayablesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('330000', XEmployeesAndInstitutionsSettlement, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('331100', XEmployees, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('333100', XPayablesToEmployees, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('336100', XSocialInstitutionsSettlement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('336200', XHealthInstitutionsSettlement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('339990', XEmployeesAndInstitutionsSettlementTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('341000', XIncomeTax, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('341100', XIncomeTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('341900', XIncomeTaxTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('342100', XIncomeTaxOnEmployment, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('343000', XVAT, 3, 1, 0, '', 0, '', '', '', '', true);

        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::"Sales Tax":
                ;
            DemoDataSetup."Company Type"::VAT:
                begin
                    InsertData('343110', StrSubstNo(XInputVATPERCENT, DemoDataSetup.SecondReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343115', StrSubstNo(XInputVATPERCENT, DemoDataSetup.FirstReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343121', StrSubstNo(XInputVATPERCENT, DemoDataSetup.BaseVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343510', StrSubstNo(XOutputVATPERCENT, DemoDataSetup.SecondReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343515', StrSubstNo(XOutputVATPERCENT, DemoDataSetup.FirstReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343521', StrSubstNo(XOutputVATPERCENT, DemoDataSetup.BaseVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343610', StrSubstNo(XReverseChargeVATPERCENT, DemoDataSetup.SecondReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343615', StrSubstNo(XReverseChargeVATPERCENT, DemoDataSetup.FirstReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343621', StrSubstNo(XReverseChargeVATPERCENT, DemoDataSetup.BaseVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343810', StrSubstNo(XAdvancesVATPERCENT, DemoDataSetup.SecondReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343815', StrSubstNo(XAdvancesVATPERCENT, DemoDataSetup.FirstReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343821', StrSubstNo(XAdvancesVATPERCENT, DemoDataSetup.BaseVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                end;
        end;

        InsertData('343880', XPostponedVATPurchase, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('343900', XVATSettlement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('343990', XVATTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('345100', XOthertaxesandfees, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('371100', XPostponedVat, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('380000', XTemporaryaccountsofassets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('381100', XPrepaidExpenses, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('382100', XComplexPrepaidExpenses, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('383100', XAccruedExpenses, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('384100', XDeferredRevenues, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('385100', XAccruedIncomes, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('388100', XAccruedRevenueItems, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('389100', XAccruals, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('389999', XTemporaryaccountsofassetsandliabilitiestotal, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('395100', XInternalSettlement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('400000', XEquityAndLongTermPayables, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('411100', XRegisteredCapitalAndCapitalFunds, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('421100', XStatutoryreserve, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('428100', XProfitLossPreviousYears, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('431100', XResultofcurrentyear, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('453100', XIncometaxprovisions, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('459100', XOtherprovisions, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('461100', XMediumTermBankLoans, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('461200', XLongTermBankLoans, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('479100', XOtherlongtermpayables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('499990', XEquityAndLongTermPayablesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('500000', XExpenses, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('501000', XConsumptionOfMaterial, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('501100', XConsumableMaterial, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('501200', XFuel, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('501300', XComputersConsumableMaterial, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('501999', XConsumptionOfMaterialTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('502000', XElectricity, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('502100', XElectricity, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('502999', XElectricityTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('503000', XNonstorablesupplies, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('503100', XNonstorablesupplies, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('503999', XNonstorablesuppliesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('504000', XCOGS, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('504110', XCOGSRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('504115', XCOGSRetailInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('504700', XCOGSOthers, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('504710', XCOGSOthersInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('504900', XJobCorrection, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('504999', XCOGSTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('510000', XServices, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('511100', XRepairsandMaintenance, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('512100', XTravelExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('512999', XServicesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('513100', XRepresentationCosts, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.NoVatCode(), true);
        InsertData('518000', XOtherServices, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('518100', XCleaning, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('518210', XPhoneCharge, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('518220', XPostage, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('518300', XAdvertisement, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('518900', XOtherServices, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('518999', XOtherServicesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('520000', XPersonalExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('521100', XSalariesAndWages, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('522100', XIncomefromemploymentcompanions, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('523100', XRemunerationtomembersofcompanymanagement, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('524100', XSocialInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('524200', XHealthInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('525100', XOtherSocialInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('526100', XIndividualsocialcostforbusinessman, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('527100', XStatutorysocialcost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('528100', XOthersocialcosts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('528900', XOthernontaxsocialcosts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('529999', XPersonalExpensesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('530000', XOthertaxesandfees, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('531100', XRoadtax, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('532100', XPropertytax, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('538100', XOthertaxesandfees, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('538900', XOthernotaxtaxesandfees, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('539999', XOthertaxesandfeestotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('540000', XOtherOperatingExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('541100', XNetBookValueOfFixedAssetsSold, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('542050', XCostofmaterialsoldInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('542100', XCostofmaterialsold, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('543100', XPresents, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('544100', XContractualPenaltiesAndInterests, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('544300', XPaymentsTolerance, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('545100', XOtherPenaltiesAndInterests, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('546100', XReceivablewriteoff, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('548100', XOtheroperatingexpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('549999', XOtherOperatingExpensesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('549100', XShortagesanddamagefromoperact, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('550000', XDepreciationandreserves, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551000', XDepreciation, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551100', XDepreciationOfBuildings, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551200', XDepreciationOfMachinesAndTools, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551300', XDepreciationOfVehicles, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551400', XDepreciationofpatents, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551500', XDepreciationofsoftware, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551600', XDepreciationofgoodwill, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551700', XDepreciationofotherintangiblefixedassets, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551900', XNetBookValueOfFixedAssetsDisposed, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('551999', XDepreciationTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('552100', XCreatandsettlofreservesaccordtospecregul, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('554100', XCreationandsettlementofothersreserves, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('558100', XCreationandsettlementlegaladjustments, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('559100', XCreationandsettlementadjustmentstooperactivities, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('559999', XDepreciationandreservestotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('560000', XFinancialExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('562100', XInterest, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('563100', XExchangeLossesRealized, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('563200', XExchangeLossesUnrealized, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('566100', XExpensesrelatedtofinancialassets, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('568100', XOtherfinancialexpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('569999', XFinancialExpensesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('570000', XReservesandadjfromfinactivities, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('574100', XCreationandsettlementoffinancialreserves, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('579100', XCreationandsettlementadjustments, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('579999', XReservesandadjfromfinactivitiestotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('580000', XChangeininventoryofownproductionandactivation, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('581100', XChangeinWIP, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('581300', XVarianceofoverheadcost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('582100', XChangeinsemifinishedproducts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('583100', XChangeinfinishedproducts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('584100', XChangeofanimals, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('585100', XActivationofgoodsandmaterial, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('586100', XActivationofinternalservices, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('587100', XActivationofintangiblefixedassets, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('588100', XActivationoftangiblefixedassets, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('589999', XChangeininventoryofownproductionandactivationtotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('591100', XIncomeTax, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('592100', XIncometaxonordinaryactivitiesdeferred, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('599999', XExpensesTotal, 4, 0, 0, '500000..599999', 0, '', '', '', '', true);
        InsertData('600000', XRevenues, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('601020', XSalesProductsDomestic, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('601030', XSalesProductsEu, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('601040', XSalesProductsExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('602110', XSalesServicesDomestic, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('602120', XSalesServicesEu, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('602130', XSalesServicesExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('602500', XSalesJobs, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('604000', XSalesGoods, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('604110', XSalesGoodsDomestic, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('604120', XSalesGoodsEu, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('604130', XSalesGoodsExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('604900', XSalesGoodsOther, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('604990', XSalesGoodsTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('640000', XOtherOperatingIncome, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('641100', XSalesFixedAssets, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('642100', XSalesmaterial, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('644100', XContractualPenaltiesAndInterests, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('644110', XDiscounts, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('644200', XRounding, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('644300', XPaymentsTolerance, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('648100', XOtherOperatingIncome, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('649999', XOtherOperatingIncomeTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('660000', XFinancialRevenues, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('662100', XInterestReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('663100', XExchangeGainsRealized, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('663200', XExchangeGainsUnrealized, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('665100', XRevenuesfromlongtermfinancialassets, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('666100', XRevenuesfromshorttermfinancialassets, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('668100', XOtherfinancialexpenses, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('669999', XFinancialRevenuesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('690000', XTransferaccounts, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('697100', XTransferofoperatingrevenues, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('698100', XTransferoffinancialrevenues, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('699900', XTransferaccountstotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('699999', XRevenuesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('701000', XOpeningBalanceSheetAccount, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('702000', XClosingBalanceSheetAccount, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('710000', XProfitAndLossAccount, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('750005', XSubBalanceSheetAccounts, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('750010', XRentOfFixedAssets, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('750100', XComputers, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('750995', XRentOfFixedAssetsTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('790000', XBalancingAccount, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('799995', XSubBalanceSheetAccount, 4, 0, 0, '', 0, '', '', '', '', false);
        GLAccIndent.Indent();
        AddCategoriesToGLAccounts();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLAccIndent: Codeunit "G/L Account-Indent";
        XFixedAssets: Label 'Fixed Assets';
        XIntangibleFixedAssets: Label 'Intangible fixed assets';
        XSoftware: Label 'Software';
        XIntangibleFixedAssetsTotal: Label 'Intangible fixed assets total';
        XTangibleFixedAssets: Label 'Tangible fixed assets';
        XBuildings: Label 'Buildings';
        XMachinesToolsEquipment: Label 'Machines, tools, equipment';
        XVehicles: Label 'Vehicles';
        XTangibleFixedAssetsTotal: Label 'Tangible fixed assets total';
        XAcquisitionOfIntangibleFixedAssets: Label 'Acquisition of intangible fixed assets';
        XAcquisitionOfTangibleFixedAssets: Label 'Acquisition of tangible fixed assets';
        XAcquisitionOfBuildings: Label 'Acquisition of buildings';
        XAcquisitionOfMachinery: Label 'Acquisition of machinery';
        XAcquisitionOfVehicles: Label 'Acquisition of vehicles';
        XAcquisitionOfTangibleFixedAssetsTotal: Label 'Acquisition of tangible fixed assets total';
        XAccumulatedDepreciationOfFixedAssets: Label 'Accumulated depreciation of fixed assets';
        XAccumulatedDepreciationOfBuildings: Label 'Accumulated depreciation of buildings';
        XAccumulatedDepreciationOfMachinery: Label 'Accumulated depreciation of machinery';
        XAccumulatedDepreciationOfVehicles: Label 'Accumulated depreciation of vehicles';
        XAccumulatedDepreciationOfFixedAssetsTotal: Label 'Accumulated depreciation of fixed assets total';
        XFixedAssetsTotal: Label 'Fixed assets total';
        XAcquisitionOfMaterial: Label 'Acquisition of material';
        XMaterialInStockInterim: Label 'Material in stock (interim)';
        XMaterialInStock: Label 'Material in stock';
        XAcquisitionOfMaterialTotal: Label 'Acquisition of material total';
        XWorkInProgress: Label 'Work in progress';
        XFinishedProductsInterim: Label 'Finished products (interim)';
        XFinishedProducts: Label 'Finished products';
        XFinishedProductsTotal: Label 'Finished products total';
        XAcquisitionOfGoods: Label 'Acquisition of goods';
        XAcquisitionRetail: Label 'Acquisition - retail';
        XAcquisitionRetailInterim: Label 'Acquisition - retail (interim)';
        XAcquisitionRawMaterialInterim: Label 'Acquisition - raw material (interim)';
        XAcquisitionRawMaterialDomestic: Label 'Acquisition - raw material, domestic';
        XAcquisitionRawMaterialEu: Label 'Acquisition - raw material, EU';
        XAcquisitionRawMaterialExport: Label 'Acquisition - raw material, export';
        XAcquisitionRawMaterial: Label 'Acquisition - raw material';
        XAcquisitionOfGoodsTotal: Label 'Acquisition of goods total';
        XGoodsInStock: Label 'Goods in stock';
        XGoodsInRetail: Label 'Goods in retail';
        XGoodsInRetailInterim: Label 'Goods in retail (interim)';
        XGoodsInStockTotal: Label 'Goods in stock total';
        XCash: Label 'Cash';
        XCashDeskLm: Label 'Cash Desk LM';
        XBankAccountEUR: Label 'Bank Account - EUR';
        XBankAccountKB: Label 'Bank Account - KB';
        XShortTermBankLoans: Label 'Short-term bank loans';
        XShortTermSecurities: Label 'Short-term securities';
        XCashtransfer: Label 'Cash transfer';
        XCashTotal: Label 'Cash total';
        XReceivables: Label 'Receivables';
        XDomesticCustomersReceivables: Label 'Domestic customers (receivables)';
        XForeignCustomersOutsideEUReceivables: Label 'Foreign customers outside EU (receivables)';
        XEUCustomersReceivables: Label 'EU customers (receivables)';
        XReceivablesFromBusinessRelationFees: Label 'Receivables from business relation (fees)';
        XPurchaseAdvancesDomestic: Label 'Purchase Advances - domestic';
        XPurchaseAdvancesForeign: Label 'Purchase Advances - foreign';
        XPurchaseAdvancesEU: Label 'Purchase Advances - EU';
        XOtherReceivables: Label 'Other receivables';
        XReceivablesTotal: Label 'Receivables total';
        XPayables: Label 'Payables';
        XDomesticVendorsPayables: Label 'Domestic vendors (payables)';
        XForeignVendorsOutsideEUPayables: Label 'Foreign vendors outside EU (payables)';
        XEUVendorsPayables: Label 'EU vendors (payables)';
        XSalesAdvancesDomestic: Label 'Sales Advances - domestic';
        XSalesAdvancesForeign: Label 'Sales Advances - foreign';
        XSalesAdvancesEU: Label 'Sales Advances - EU';
        XOtherpayables: Label 'Other payables';
        XPayablesTotal: Label 'Payables total';
        XEmployeesAndInstitutionsSettlement: Label 'Employees and institutions settlement';
        XEmployees: Label 'Employees';
        XPayablesToEmployees: Label 'Payables to employees';
        XSocialInstitutionsSettlement: Label 'Social institutions settlement';
        XHealthInstitutionsSettlement: Label 'Health institutions settlement';
        XEmployeesAndInstitutionsSettlementTotal: Label 'Employees and institutions settlement total';
        XSocialInsurance: Label 'Social insurance';
        XHealthInsurance: Label 'Health insurance';
        XIncomeTax: Label 'Income tax';
        XIncomeTaxTotal: Label 'Income tax total';
        XIncomeTaxOnEmployment: Label 'Income tax on employment';
        XVAT: Label 'VAT';
        XInputVATPERCENT: Label 'Input VAT %1';
        XOutputVATPERCENT: Label 'Output VAT %1';
        XReverseChargeVATPERCENT: Label 'Reverse Charge VAT %1';
        XAdvancesVATPERCENT: Label 'Advances - VAT %1';
        XVATSettlement: Label 'VAT settlement';
        XVATTotal: Label 'VAT total';
        XPostponedVat: Label 'Postponed VAT';
        XAccruedRevenueItems: Label 'Accrued revenue (items)';
        XAccruals: Label 'Accruals';
        XInternalSettlement: Label 'Internal settlement';
        XEquityAndLongTermPayables: Label 'Equity and long-term payables';
        XRegisteredCapitalAndCapitalFunds: Label 'Registered capital and capital funds';
        XStatutoryreserve: Label 'Statutory reserve';
        XProfitLossPreviousYears: Label 'Profit/loss previous years';
        XResultofcurrentyear: Label 'Result of current year';
        XMediumTermBankLoans: Label 'Medium-term bank loans';
        XLongTermBankLoans: Label 'Long-term bank loans';
        XEquityAndLongTermPayablesTotal: Label 'Equity and long-term payables total';
        XExpenses: Label 'Expenses';
        XConsumptionOfMaterial: Label 'Consumption of material';
        XConsumableMaterial: Label 'Consumable material';
        XComputersConsumableMaterial: Label 'Computers - consumable material';
        XConsumptionOfMaterialTotal: Label 'Consumption of material total';
        XElectricity: Label 'Electricity';
        XElectricityTotal: Label 'Electricity total';
        XNonstorablesupplies: Label 'Non-storable supplies';
        XNonstorablesuppliestotal: Label 'Non-storable supplies total';
        XFuel: Label 'Fuel';
        XCOGS: Label 'COGS';
        XCOGSRetail: Label 'COGS - retail';
        XCOGSRetailInterim: Label 'COGS - retail (interim)';
        XCOGSOthers: Label 'COGS - others';
        XCOGSOthersInterim: Label 'COGS - others (interim)';
        XCOGSTotal: Label 'COGS total';
        XJobCorrection: Label 'Job correction';
        XServices: Label 'Services';
        XServicesTotal: Label 'Services total';
        XRepresentationCosts: Label 'Representation costs';
        XCleaning: Label 'Cleaning';
        XPhoneCharge: Label 'Phone charge';
        XPostage: Label 'Postage';
        XAdvertisement: Label 'Advertisement';
        XOtherServices: Label 'Other services';
        XOtherServicesTotal: Label 'Other services total';
        XPersonalExpenses: Label 'Personal expenses';
        XSalariesAndWages: Label 'Salaries and wages';
        XTravelExpenses: Label 'Travel expenses';
        XPersonalExpensesTotal: Label 'Personal expenses total';
        XNetBookValueOfFixedAssetsSold: Label 'Net book value of fixed assets sold';
        XContractualPenaltiesAndInterests: Label 'Contractual penalties and interests';
        XPaymentsTolerance: Label 'Payments tolerance';
        XOtherOperatingExpensesTotal: Label 'Other operating expenses total';
        XDepreciation: Label 'Depreciation';
        XDepreciationOfBuildings: Label 'Depreciation of buildings';
        XDepreciationOfMachinesAndTools: Label 'Depreciation of machines and tools';
        XDepreciationOfVehicles: Label 'Depreciation of vehicles';
        XNetBookValueOfFixedAssetsDisposed: Label 'Net book value of fixed assets disposed';
        XDepreciationtotal: Label 'Depreciation total';
        XInterest: Label 'Interest';
        XExchangeLossesRealized: Label 'Exchange losses - realized';
        XExchangeLossesUnrealized: Label 'Exchange losses - unrealized';
        XExpensesTotal: Label 'EXPENSES - TOTAL';
        XRevenues: Label 'Revenues';
        XSalesProductsDomestic: Label 'Sales products - domestic';
        XSalesProductsEu: Label 'Sales products - EU';
        XSalesProductsExport: Label 'Sales products - export';
        XSalesServicesDomestic: Label 'Sales services - domestic';
        XSalesServicesEu: Label 'Sales services - EU';
        XSalesServicesExport: Label 'Sales services - export';
        XSalesGoods: Label 'Sales goods';
        XSalesGoodsDomestic: Label 'Sales goods - domestic';
        XSalesGoodsEu: Label 'Sales goods - EU';
        XSalesGoodsExport: Label 'Sales goods - export';
        XSalesGoodsOther: Label 'Sales goods - other';
        XSalesGoodsTotal: Label 'Sales goods total';
        XOtherOperatingIncome: Label 'Other operating income';
        XSalesFixedAssets: Label 'Sales fixed assets';
        XDiscounts: Label 'Discounts';
        XRounding: Label 'Rounding';
        XOtherOperatingIncomeTotal: Label 'Other operating income total';
        XFinancialRevenues: Label 'Financial revenues';
        XInterestReceived: Label 'Interest received';
        XExchangeGainsRealized: Label 'Exchange gains - realized';
        XExchangeGainsUnrealized: Label 'Exchange gains - unrealized';
        XRevenuesTotal: Label 'REVENUES TOTAL';
        XSubBalanceSheetAccounts: Label 'Sub-balance sheet accounts';
        XRentOfFixedAssets: Label 'Rent of fixed assets';
        XComputers: Label 'Computers';
        XRentOfFixedAssetsTotal: Label 'Rent of fixed assets total';
        XBalancingAccount: Label 'Balancing Account';
        XRepairsandMaintenance: Label 'Repairs and Maintenance';
        XSubBalanceSheetAccount: Label 'Sub-balance sheet accounts total';
        XIncomefromemploymentcompanions: Label 'Income from employment companions';
        XRemunerationtomembersofcompanymanagement: Label 'Remuneration to members of company management';
        XOtherSocialInsurance: Label 'Other social insurance';
        XIndividualsocialcostforbusinessman: Label 'Individual social cost for businessman';
        XStatutorysocialcost: Label 'Statutory social cost';
        XOthersocialcosts: Label 'Other social costs';
        XOthernontaxsocialcosts: Label 'Other non-tax social costs';
        XOthertaxesandfees: Label 'Other taxes and fees';
        XRoadtax: Label 'Road tax';
        XPropertytax: Label 'Property tax';
        XOthernotaxtaxesandfees: Label 'Other non-tax taxes and fees';
        XOthertaxesandfeestotal: Label 'Other taxes and fees total';
        XCostofmaterialsoldInterim: Label 'Cost of material sold (Interim)';
        XCostofmaterialsold: Label 'Cost of material sold';
        XPresents: Label 'Presents';
        XOtherpenaltiesandinterests: Label 'Other penalties and interests';
        XReceivablewriteoff: Label 'Receivable write-off';
        XOtheroperatingexpenses: Label 'Other operating expenses';
        XShortagesanddamagefromoperact: Label 'Shortages and damage from oper. act.';
        XDepreciationandreserves: Label 'Depreciation and reserves';
        XCreatandsettlofreservesaccordtospecregul: Label 'Creat. and settl. of reserves accord. to spec. regul.';
        XCreationandsettlementofothersreserves: Label 'Creation and settlement of others reserves';
        XCreationandsettlementlegaladjustments: Label 'Creation and settlement legal adjustments';
        XCreationandsettlementadjustmentstooperactivities: Label 'Creation and settlement adjustments to oper. activities';
        XDepreciationandreservestotal: Label 'Depreciation and reserves total';
        XFinancialexpenses: Label 'Financial expenses';
        XExpensesrelatedtofinancialassets: Label 'Expenses related to financial assets';
        XOtherfinancialexpenses: Label 'Other financial expenses';
        XFinancialexpensestotal: Label 'Financial expenses total';
        XReservesandadjfromfinactivities: Label 'Reserves and adj. from fin. activities';
        XCreationandsettlementoffinancialreserves: Label 'Creation and settlement of financial reserves';
        XCreationandsettlementadjustments: Label 'Creation and settlement adjustments';
        XReservesandadjfromfinactivitiestotal: Label 'Reserves and adj. from fin. activities total';
        XChangeininventoryofownproductionandactivation: Label 'Change in inventory of own production and activation';
        XChangeininventoryofownproductionandactivationtotal: Label 'Change in inventory of own production and activation total';
        XChangeinWIP: Label 'Change in WIP';
        XVarianceofoverheadcost: Label 'Variance of overhead cost';
        XChangeinsemifinishedproducts: Label 'Change in semi-finished products';
        XChangeinfinishedproducts: Label 'Change in finished products';
        XChangeofanimals: Label 'Change of animals';
        XActivationofgoodsandmaterial: Label 'Activation of goods and material';
        XActivationofinternalservices: Label 'Activation of internal services';
        XActivationofintangiblefixedassets: Label 'Activation of intangible fixed assets';
        XActivationoftangiblefixedassets: Label 'Activation of tangible fixed assets';
        XIncometaxonordinaryactivitiesdeferred: Label 'Income tax on ordinary activities - deferred';
        XSalesjobs: Label 'Sales jobs';
        XSalesmaterial: Label 'Sales material';
        XRevenuesfromlongtermfinancialassets: Label 'Revenues from long-term financial assets';
        XRevenuesfromshorttermfinancialassets: Label 'Revenues from short-term financial assets';
        XFinancialrevenuestotal: Label 'Financial revenues total';
        XTransferaccounts: Label 'Transfer accounts';
        XTransferofoperatingrevenues: Label 'Transfer of operating revenues';
        XTransferoffinancialrevenues: Label 'Transfer of financial revenues';
        XTransferaccountstotal: Label 'Transfer accounts total';
        XOpeningbalancesheetaccount: Label 'Opening balance sheet account';
        XClosingbalancesheetaccount: Label 'Closing balance sheet account';
        XProfitandlossaccount: Label 'Profit and loss account';
        XPrepaidexpenses: Label 'Prepaid expenses';
        XComplexprepaidexpenses: Label 'Complex prepaid expenses';
        XAccruedexpenses: label 'Accrued expenses';
        XDeferredrevenues: Label 'Deferred revenues';
        XAccruedincomes: Label 'Accrued incomes';
        XIntangibleresultsofresearchanddevelopment: Label 'Intangible results of research and development';
        XValuablerights: Label 'Valuable rights';
        XGoodwill: Label 'Goodwill';
        XOtherintangiblefixedassets: Label 'Other intangible fixed assets';
        XTangiblefixedassetsnondeductible: Label 'Tangible fixed assets non-deductible';
        XLands: Label 'Lands';
        XTangiblefixedassetsnondeductibletotal: Label 'Tangible fixed assets non-deductible total';
        XCorrectionstointangiblefixedassets: Label 'Corrections to intangible fixed assets';
        XCorrectionstointangibleresultsofresearchanddevelopment: Label 'Corrections to intangible results of research and development';
        XCorrectionstosoftware: Label 'Corrections to software';
        XCorrectionstovaluablerights: Label 'Corrections to valuable rights';
        XCorrectionstogoodwill: Label 'Corrections to goodwill';
        XCorrectionstootherintangiblefixedassets: Label 'Corrections to other intangible fixed assets';
        XCorrectionstointangiblefixedassetstotal: Label 'Corrections to intangible fixed assets total';
        XUnidentifiedpayments: Label 'Unidentified payments';
        XTemporaryaccountsofassets: Label 'Temporary accounts of assets';
        XTemporaryaccountsofassetsandliabilitiestotal: Label 'Temporary accounts of assets and liabilities total';
        XIncometaxprovisions: Label 'Income tax provisions';
        XOtherprovisions: Label 'Other provisions';
        XOtherlongtermpayables: Label 'Other long-term payables';
        XDepreciationofpatents: Label 'Deprecation of patents';
        XDepreciationofsoftware: Label 'Deprecation of software';
        XDepreciationofgoodwill: Label 'Deprecation of goodwill';
        XDepreciationofotherintangiblefixedassets: Label 'Deprecation of other intangible fixed assets';
        XPostponedVATPurchase: Label 'Postponed VAT - Purchase';

    procedure InsertMiniAppData()
    begin
        AddIncomeStatementForMini();
        AddBalanceSheetForMini();

        GLAccIndent.Indent();
        AddCategoriesToGLAccounts();
    end;

    local procedure AddIncomeStatementForMini()
    begin
        // Income statement 500000-799999
        DemoDataSetup.Get();
        InsertData('500000', XExpenses, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('501000', XConsumptionOfMaterial, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('501100', XConsumableMaterial, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('501200', XFuel, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('501999', XConsumptionOfMaterialTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('502000', XElectricity, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('502100', XElectricity, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('502999', XElectricityTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('503000', XNonstorablesupplies, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('503100', XNonstorablesupplies, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('503999', XNonstorablesuppliesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('504000', XCOGS, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('504110', XCOGSRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('504115', XCOGSRetailInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('504900', XJobCorrection, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('504999', XCOGSTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('510000', XServices, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('511100', XRepairsandMaintenance, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('512100', XTravelExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('512999', XServicesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('513100', XRepresentationCosts, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('518000', XOtherServices, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('518100', XCleaning, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('518999', XOtherServicesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('520000', XPersonalExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('521100', XSalariesAndWages, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('522100', XIncomefromemploymentcompanions, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('523100', XRemunerationtomembersofcompanymanagement, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('524100', XSocialInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('524200', XHealthInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('525100', XOtherSocialInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('526100', XIndividualsocialcostforbusinessman, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('527100', XStatutorysocialcost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('528100', XOthersocialcosts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('529999', XPersonalExpensesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('530000', XOthertaxesandfees, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('531100', XRoadtax, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('532100', XPropertytax, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('538100', XOthertaxesandfees, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('538900', XOthernotaxtaxesandfees, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('539999', XOthertaxesandfeestotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('540000', XOtherOperatingExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('541100', XNetBookValueOfFixedAssetsSold, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('542100', XCostofmaterialsold, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('543100', XPresents, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('544100', XContractualPenaltiesAndInterests, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('545100', XOtherPenaltiesAndInterests, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('546100', XReceivablewriteoff, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('548100', XOtheroperatingexpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('549999', XOtherOperatingExpensesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('549100', XShortagesanddamagefromoperact, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('550000', XDepreciationandreserves, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551000', XDepreciation, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551100', XDepreciationOfBuildings, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551200', XDepreciationOfMachinesAndTools, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551300', XDepreciationOfVehicles, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('551900', XNetBookValueOfFixedAssetsDisposed, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('551999', XDepreciationTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('552100', XCreatandsettlofreservesaccordtospecregul, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('554100', XCreationandsettlementofothersreserves, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('558100', XCreationandsettlementlegaladjustments, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('559100', XCreationandsettlementadjustmentstooperactivities, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('559999', XDepreciationandreservestotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('560000', XFinancialExpenses, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('562100', XInterest, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('563100', XExchangeLossesRealized, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('563200', XExchangeLossesUnrealized, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('566100', XExpensesrelatedtofinancialassets, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('568100', XOtherfinancialexpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('569999', XFinancialExpensesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('570000', XReservesandadjfromfinactivities, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('574100', XCreationandsettlementoffinancialreserves, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('579100', XCreationandsettlementadjustments, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('579999', XReservesandadjfromfinactivitiestotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('580000', XChangeininventoryofownproductionandactivation, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('581100', XChangeinWIP, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('581300', XVarianceofoverheadcost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('582100', XChangeinsemifinishedproducts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('583100', XChangeinfinishedproducts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('584100', XChangeofanimals, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('585100', XActivationofgoodsandmaterial, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('586100', XActivationofinternalservices, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('587100', XActivationofintangiblefixedassets, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('588100', XActivationoftangiblefixedassets, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('589999', XChangeininventoryofownproductionandactivationtotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('591100', XIncomeTax, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('592100', XIncometaxonordinaryactivitiesdeferred, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('599999', XExpensesTotal, 4, 0, 0, '500000..599999', 0, '', '', '', '', true);
        InsertData('600000', XRevenues, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('601020', XSalesProductsDomestic, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('601030', XSalesProductsEu, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('601040', XSalesProductsExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('602110', XSalesServicesDomestic, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('602120', XSalesServicesEu, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('602130', XSalesServicesExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('602500', XSalesJobs, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('604000', XSalesGoods, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('604210', XSalesGoodsDomestic, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('604220', XSalesGoodsEu, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('604230', XSalesGoodsExport, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('604900', XSalesGoodsOther, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('604990', XSalesGoodsTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('640000', XOtherOperatingIncome, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('641100', XSalesFixedAssets, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('642100', XSalesmaterial, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('644100', XContractualPenaltiesAndInterests, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('648100', XOtherOperatingIncome, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('649999', XOtherOperatingIncomeTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('660000', XFinancialRevenues, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('662100', XInterestReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('663100', XExchangeGainsRealized, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('663200', XExchangeGainsUnrealized, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('665100', XRevenuesfromlongtermfinancialassets, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('666100', XRevenuesfromshorttermfinancialassets, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('668100', XOtherfinancialexpenses, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('669999', XFinancialRevenuesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('690000', XTransferaccounts, 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData('697100', XTransferofoperatingrevenues, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('698100', XTransferoffinancialrevenues, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('699900', XTransferaccountstotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('699999', XRevenuesTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('701000', XOpeningBalanceSheetAccount, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('702000', XClosingBalanceSheetAccount, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('710000', XProfitAndLossAccount, 0, 0, 0, '', 0, '', '', '', '', true);
    end;

    procedure AddBalanceSheetForMini()
    begin
        // Balance sheet 001000-499999
        DemoDataSetup.Get();
        InsertData('001000', XFixedAssets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('010000', XIntangibleFixedAssets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('013100', XSoftware, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('019999', XIntangibleFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', false);
        InsertData('020000', XTangibleFixedAssets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('021100', XBuildings, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('022100', XMachinesToolsEquipment, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('022300', XVehicles, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('029990', XTangibleFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('041100', XAcquisitionOfIntangibleFixedAssets, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('042000', XAcquisitionOfTangibleFixedAssets, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('042100', XAcquisitionOfBuildings, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('042200', XAcquisitionOfMachinery, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('042300', XAcquisitionOfVehicles, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('042990', XAcquisitionOfTangibleFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('081100', XAccumulatedDepreciationOfFixedAssets, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('081110', XAccumulatedDepreciationOfBuildings, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('082100', XAccumulatedDepreciationOfMachinery, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('082300', XAccumulatedDepreciationOfVehicles, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('089990', XAccumulatedDepreciationOfFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('110000', XFixedAssetsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('111000', XAcquisitionOfMaterial, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('111100', XAcquisitionOfMaterial, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('112050', XMaterialInStockInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('112100', XMaterialInStock, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('119999', XAcquisitionOfMaterialTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('121000', XFinishedProducts, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('121100', XWorkInProgress, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('123050', XFinishedProductsInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('123100', XFinishedProducts, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('129990', XFinishedProductsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('131000', XAcquisitionOfGoods, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('131050', XAcquisitionOfGoods, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('131450', XAcquisitionRetail, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('131455', XAcquisitionRetailInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('131500', XAcquisitionRawMaterialDomestic, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('131600', XAcquisitionRawMaterialEu, 0, 1, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('131700', XAcquisitionRawMaterialExport, 0, 1, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('131950', XAcquisitionRawMaterial, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('131955', XAcquisitionRawMaterialInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('131990', XAcquisitionOfGoodsTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('132000', XGoodsInStock, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('132100', XGoodsInRetail, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('132110', XGoodsInRetailInterim, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('139990', XGoodsInStockTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('210000', XCash, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('211100', XCashDeskLm, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('221100', XBankAccountKB, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('221200', XBankAccountEUR, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('231100', XShortTermBankLoans, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('251100', XShortTermSecurities, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('261100', XCashtransfer, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('299990', XCashTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('310000', XReceivables, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('311100', XDomesticCustomersReceivables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('311200', XForeignCustomersOutsideEUReceivables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('311300', XEUCustomersReceivables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('311910', XReceivablesFromBusinessRelationFees, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('314100', XPurchaseAdvancesDomestic, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('314200', XPurchaseAdvancesForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('314300', XPurchaseAdvancesEU, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('315100', XOtherReceivables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('319999', XReceivablesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('320000', XPayables, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('321100', XDomesticVendorsPayables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('321200', XForeignVendorsOutsideEUPayables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('321300', XEUVendorsPayables, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('324100', XSalesAdvancesDomestic, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('324200', XSalesAdvancesForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('324300', XSalesAdvancesEU, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('325100', XOtherpayables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('329999', XPayablesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('330000', XEmployeesAndInstitutionsSettlement, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('331100', XEmployees, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('333100', XPayablesToEmployees, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('336100', XSocialInstitutionsSettlement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('336200', XHealthInstitutionsSettlement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('339990', XEmployeesAndInstitutionsSettlementTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('341000', XIncomeTax, 3, 1, 0, '', 0, '', '', '', '', false);
        InsertData('341100', XIncomeTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('341900', XIncomeTaxTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('342100', XIncomeTaxOnEmployment, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('343000', XVAT, 3, 1, 0, '', 0, '', '', '', '', true);

        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::"Sales Tax":
                ;
            DemoDataSetup."Company Type"::VAT:
                begin
                    InsertData('343110', StrSubstNo(XInputVATPERCENT, DemoDataSetup.SecondReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343115', StrSubstNo(XInputVATPERCENT, DemoDataSetup.FirstReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343121', StrSubstNo(XInputVATPERCENT, DemoDataSetup.BaseVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343510', StrSubstNo(XOutputVATPERCENT, DemoDataSetup.SecondReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343515', StrSubstNo(XOutputVATPERCENT, DemoDataSetup.FirstReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343521', StrSubstNo(XOutputVATPERCENT, DemoDataSetup.BaseVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343610', StrSubstNo(XReverseChargeVATPERCENT, DemoDataSetup.SecondReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343615', StrSubstNo(XReverseChargeVATPERCENT, DemoDataSetup.FirstReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343621', StrSubstNo(XReverseChargeVATPERCENT, DemoDataSetup.BaseVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343810', StrSubstNo(XAdvancesVATPERCENT, DemoDataSetup.SecondReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343815', StrSubstNo(XAdvancesVATPERCENT, DemoDataSetup.FirstReducedVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                    InsertData('343821', StrSubstNo(XAdvancesVATPERCENT, DemoDataSetup.BaseVATText()), 0, 1, 0, '', 0, '', '', '', '', true);
                end;
        end;

        InsertData('343900', XVATSettlement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('343990', XVATTotal, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('345100', XOthertaxesandfees, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('371100', XPostponedVat, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('388100', XAccruedRevenueItems, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('389100', XAccruals, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('395100', XInternalSettlement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('400000', XEquityAndLongTermPayables, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('411100', XRegisteredCapitalAndCapitalFunds, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('421100', XStatutoryreserve, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('428100', XProfitLossPreviousYears, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('431100', XResultofcurrentyear, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('461100', XMediumTermBankLoans, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('461200', XLongTermBankLoans, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('499990', XEquityAndLongTermPayablesTotal, 4, 1, 0, '', 0, '', '', '', '', true);
    end;

    procedure InsertData(AccountNo: Code[20]; AccountName: Text[100]; AccountType: Option; IncomeBalance: Option; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectPosting: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", AccountNo); // NAVCZ
        GLAccount.Validate(Name, AccountName);
        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then
            GLAccount.Validate("Direct Posting", DirectPosting);
        GLAccount."Income/Balance" := "G/L Account Report Type".FromInteger(IncomeBalance);
        case AccountNo of
            '211100', '221100', '221200', '221300', '231100':
                GLAccount."Reconciliation Account" := true;
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
                    UpdateGLAccounts(GLAccountCategory, '001000', '221300');
                    UpdateGLAccounts(GLAccountCategory, '251100', '319999');
                    UpdateGLAccounts(GLAccountCategory, '388100', '388100');
                    UpdateGLAccounts(GLAccountCategory, '395100', '395100');
                end;
            GLAccountCategory."Account Category"::Liabilities:
                begin
                    UpdateGLAccounts(GLAccountCategory, '231100', '231100');
                    UpdateGLAccounts(GLAccountCategory, '320000', '371100');
                    UpdateGLAccounts(GLAccountCategory, '389100', '389100');
                    UpdateGLAccounts(GLAccountCategory, '400000', '499990');
                end;
        end;
    end;

    procedure AssignSubcategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgtCZL: Codeunit "G/L Account Category Mgt. CZL";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgtCZL.GetBI1IntangibleResultsofResearchandDevelopment():
                begin
                    UpdateGLAccounts(GLAccountCategory, '012100', '012100');
                    UpdateGLAccounts(GLAccountCategory, '072100', '072100');
                end;
            GLAccountCategoryMgtCZL.GetBI21Software():
                begin
                    UpdateGLAccounts(GLAccountCategory, '013100', '013100');
                    UpdateGLAccounts(GLAccountCategory, '073100', '073100');
                end;
            GLAccountCategoryMgtCZL.GetBI22OtherValuableRights():
                begin
                    UpdateGLAccounts(GLAccountCategory, '014100', '014100');
                    UpdateGLAccounts(GLAccountCategory, '074100', '074100');
                end;
            GLAccountCategoryMgtCZL.GetBI3Goodwill():
                begin
                    UpdateGLAccounts(GLAccountCategory, '015100', '015100');
                    UpdateGLAccounts(GLAccountCategory, '075100', '075100');
                end;
            GLAccountCategoryMgtCZL.GetBI4OtherIntangibleFixedAssets():
                begin
                    UpdateGLAccounts(GLAccountCategory, '019100', '019100');
                    UpdateGLAccounts(GLAccountCategory, '079100', '079100');
                end;
            GLAccountCategoryMgtCZL.GetBII11Lands():
                UpdateGLAccounts(GLAccountCategory, '031100', '031100');
            GLAccountCategoryMgtCZL.GetBII12Buildings():
                begin
                    UpdateGLAccounts(GLAccountCategory, '021100', '021100');
                    UpdateGLAccounts(GLAccountCategory, '081110', '081110');
                end;
            GLAccountCategoryMgtCZL.GetBII2FixedMovablesAndtheCollectionsOfFixedMovables():
                begin
                    UpdateGLAccounts(GLAccountCategory, '022100', '022300');
                    UpdateGLAccounts(GLAccountCategory, '082100', '082300');
                end;
            GLAccountCategoryMgtCZL.GetBI52IntangibleFixedAssestsInProgress():
                UpdateGLAccounts(GLAccountCategory, '041100', '041100');
            GLAccountCategoryMgtCZL.GetBII52TangibleFixedAssetsInProgress():
                UpdateGLAccounts(GLAccountCategory, '042000', '042990');
            GLAccountCategoryMgtCZL.GetCI1Material():
                UpdateGLAccounts(GLAccountCategory, '111000', '119999');
            GLAccountCategoryMgtCZL.GetCI2WorkinProgressAndSemiFinishedGoods():
                UpdateGLAccounts(GLAccountCategory, '121100', '121100');
            GLAccountCategoryMgtCZL.GetCI31FinishedProducts():
                UpdateGLAccounts(GLAccountCategory, '123050', '123100');
            GLAccountCategoryMgtCZL.GetCI32Goods():
                UpdateGLAccounts(GLAccountCategory, '131000', '139990');
            GLAccountCategoryMgtCZL.GetCIV1Cash():
                begin
                    UpdateGLAccounts(GLAccountCategory, '211100', '211100');
                    UpdateGLAccounts(GLAccountCategory, '261100', '261100');
                end;
            GLAccountCategoryMgtCZL.GetCIV2BankAccounts():
                begin
                    UpdateGLAccounts(GLAccountCategory, '221100', '221300');
                    UpdateGLAccounts(GLAccountCategory, '261900', '261900');
                end;
            GLAccountCategoryMgtCZL.GetCII2PayablesToCreditInstitutions():
                UpdateGLAccounts(GLAccountCategory, '231100', '231100');
            GLAccountCategoryMgtCZL.GetCIII2OtherShorttermFinancialAssets():
                UpdateGLAccounts(GLAccountCategory, '251100', '251100');
            GLAccountCategoryMgtCZL.GetCII21TradeReceivables():
                begin
                    UpdateGLAccounts(GLAccountCategory, '311100', '311910');
                    UpdateGLAccounts(GLAccountCategory, '315100', '315100');
                end;
            GLAccountCategoryMgtCZL.GetCII244ShorttermAdvancedPayments():
                UpdateGLAccounts(GLAccountCategory, '314100', '314300');
            GLAccountCategoryMgtCZL.GetCII4TradePayables():
                begin
                    UpdateGLAccounts(GLAccountCategory, '321100', '321300');
                    UpdateGLAccounts(GLAccountCategory, '325100', '325100');
                end;
            GLAccountCategoryMgtCZL.GetCII3ShorttermAdvancePaymentsReceived():
                UpdateGLAccounts(GLAccountCategory, '324100', '324300');
            GLAccountCategoryMgtCZL.GetCII83PayrollPayables():
                UpdateGLAccounts(GLAccountCategory, '331100', '333100');
            GLAccountCategoryMgtCZL.GetCII84PayablesSocialSecurityAndHealthInsurance():
                UpdateGLAccounts(GLAccountCategory, '336100', '336200');
            GLAccountCategoryMgtCZL.GetCII85StateTaxLiabilitiesAndGrants():
                UpdateGLAccounts(GLAccountCategory, '341100', '371100');
            GLAccountCategoryMgtCZL.GetD1PrepaidExpenses():
                UpdateGLAccounts(GLAccountCategory, '381100', '381100');
            GLAccountCategoryMgtCZL.GetD2ComplexPrepaidExpenses():
                UpdateGLAccounts(GLAccountCategory, '382100', '382100');
            GLAccountCategoryMgtCZL.GetD1AccruedExpenses():
                UpdateGLAccounts(GLAccountCategory, '383100', '383100');
            GLAccountCategoryMgtCZL.GetD2DeferredRevenues():
                UpdateGLAccounts(GLAccountCategory, '384100', '384100');
            GLAccountCategoryMgtCZL.GetD3AccruedIncomes():
                UpdateGLAccounts(GLAccountCategory, '385100', '385100');
            GLAccountCategoryMgtCZL.GetCII245EstimatedReceivables():
                UpdateGLAccounts(GLAccountCategory, '388100', '388100');
            GLAccountCategoryMgtCZL.GetCII86EstimatedPayables():
                UpdateGLAccounts(GLAccountCategory, '389100', '389100');
            GLAccountCategoryMgtCZL.GetCII246OtherReceivables():
                UpdateGLAccounts(GLAccountCategory, '395100', '395100');
            GLAccountCategoryMgtCZL.GetAI1RegisteredCapital():
                UpdateGLAccounts(GLAccountCategory, '411100', '411100');
            GLAccountCategoryMgtCZL.GetAIII1OtherReserveFunds():
                UpdateGLAccounts(GLAccountCategory, '421100', '421100');
            GLAccountCategoryMgtCZL.GetAIV1RetainedEarningsFromPreviousYears():
                UpdateGLAccounts(GLAccountCategory, '428100', '431100');
            GLAccountCategoryMgtCZL.GetCI2PayablesToCreditInstitutions():
                UpdateGLAccounts(GLAccountCategory, '461100', '461200');
            GLAccountCategoryMgtCZL.GetCI3LongtermAdvancePaymentsReceived():
                UpdateGLAccounts(GLAccountCategory, '479100', '479100');
            GLAccountCategoryMgtCZL.GetA2MaterialAndEnergyConsumption():
                UpdateGLAccounts(GLAccountCategory, '501000', '503999');
            GLAccountCategoryMgtCZL.GetA1CostsOfGoodsSold():
                UpdateGLAccounts(GLAccountCategory, '504000', '504999');
            GLAccountCategoryMgtCZL.GetA3Services():
                UpdateGLAccounts(GLAccountCategory, '510000', '518999');
            GLAccountCategoryMgtCZL.GetB2IncomeTaxProvision():
                UpdateGLAccounts(GLAccountCategory, '453100', '453100');
            GLAccountCategoryMgtCZL.GetB4OtherProvisions():
                UpdateGLAccounts(GLAccountCategory, '459100', '459100');
            GLAccountCategoryMgtCZL.GetD1WagesAndSalaries():
                UpdateGLAccounts(GLAccountCategory, '521100', '523999');
            GLAccountCategoryMgtCZL.GetD21SocialSecurityandHealthInsurance():
                UpdateGLAccounts(GLAccountCategory, '524000', '526100');
            GLAccountCategoryMgtCZL.GetD22OtherCosts():
                UpdateGLAccounts(GLAccountCategory, '527100', '528900');
            GLAccountCategoryMgtCZL.GetF3TaxesAndFeesInOperatingPart():
                UpdateGLAccounts(GLAccountCategory, '530000', '539999');
            GLAccountCategoryMgtCZL.GetF1NetBookValueOfFixedAssetsSold():
                UpdateGLAccounts(GLAccountCategory, '541100', '541100');
            GLAccountCategoryMgtCZL.GetF2NetBookValueofMaterialSold():
                UpdateGLAccounts(GLAccountCategory, '542050', '542100');
            GLAccountCategoryMgtCZL.GetF5OtherOperatingCosts():
                begin
                    UpdateGLAccounts(GLAccountCategory, '543100', '548100');
                    UpdateGLAccounts(GLAccountCategory, '549100', '549100');
                end;
            GLAccountCategoryMgtCZL.GetE11IntangibleandTangibleFixedAssetsAdjustmentsPermanent():
                UpdateGLAccounts(GLAccountCategory, '551000', '551999');
            GLAccountCategoryMgtCZL.GetF4ProvisionsinOperatingPartandComplexPrepaidExpenses():
                UpdateGLAccounts(GLAccountCategory, '552100', '554100');
            GLAccountCategoryMgtCZL.GetE3ReceivablesAdjustments():
                UpdateGLAccounts(GLAccountCategory, '558100', '558100');
            GLAccountCategoryMgtCZL.GetE12IntangibleAndTangibleFixedAssetsAdjustmentsTemporary():
                UpdateGLAccounts(GLAccountCategory, '559100', '559100');
            GLAccountCategoryMgtCZL.GetJ2OtherInterestCostsAndSimilarCosts():
                UpdateGLAccounts(GLAccountCategory, '562100', '562100');
            GLAccountCategoryMgtCZL.GetKOtherFinancialCosts():
                UpdateGLAccounts(GLAccountCategory, '563100', '568100');
            GLAccountCategoryMgtCZL.GetIAdjustmentsandProvisionsInFinancialPart():
                UpdateGLAccounts(GLAccountCategory, '570000', '579999');
            GLAccountCategoryMgtCZL.GetBChangesInInventoryOfOwnProducts():
                UpdateGLAccounts(GLAccountCategory, '581100', '584100');
            GLAccountCategoryMgtCZL.GetCCapitalization():
                UpdateGLAccounts(GLAccountCategory, '585100', '588100');
            GLAccountCategoryMgtCZL.GetL1IncomeTaxDue():
                UpdateGLAccounts(GLAccountCategory, '591100', '591100');
            GLAccountCategoryMgtCZL.GetL2IncomeTaxDeferred():
                UpdateGLAccounts(GLAccountCategory, '592100', '592100');
            GLAccountCategoryMgtCZL.GetIRevenuesFromOwnProductsAndServices():
                UpdateGLAccounts(GLAccountCategory, '601020', '602500');
            GLAccountCategoryMgtCZL.GetIIRevenuesFromMerchandise():
                UpdateGLAccounts(GLAccountCategory, '604000', '604990');
            GLAccountCategoryMgtCZL.GetIII1RevenuesFromSalesOfFixedAssets():
                UpdateGLAccounts(GLAccountCategory, '641100', '641100');
            GLAccountCategoryMgtCZL.GetIII2RevenuesOfMaterialSold():
                UpdateGLAccounts(GLAccountCategory, '642100', '642100');
            GLAccountCategoryMgtCZL.GetIII3AnotherOperatingRevenues():
                begin
                    UpdateGLAccounts(GLAccountCategory, '644100', '648100');
                    UpdateGLAccounts(GLAccountCategory, '697100', '697100');
                end;
            GLAccountCategoryMgtCZL.GetVI2OtherInterestRevenuesAndSimilarRevenues():
                UpdateGLAccounts(GLAccountCategory, '662100', '662100');
            GLAccountCategoryMgtCZL.GetVIIOtherFinancialRevenues():
                begin
                    UpdateGLAccounts(GLAccountCategory, '663100', '663200');
                    UpdateGLAccounts(GLAccountCategory, '666100', '668100');
                    UpdateGLAccounts(GLAccountCategory, '698100', '698100');
                end;
            GLAccountCategoryMgtCZL.GetV1RevenuesFromOtherLongtermFinancialAssetsControlledOrControlling():
                UpdateGLAccounts(GLAccountCategory, '665100', '665100');
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

