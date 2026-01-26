codeunit 101015 "Create G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('980070', XGoodwill, 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980071', XGoodwill, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980072', XHistoricalCost, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980073', XAccumDeprecAtStartOfFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980076', XInvestmentCurrentFY, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('980078', XDepreciationCurrentFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980079', XTotalGoodwill, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980100', XLand, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('980101', XLand, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980102', XHistoricalCost, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991140', XAccumDeprecAtStartOfFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991120', XInvestmentCurrentFY, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991130', XDepreciationCurrentFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980109', XTotalLand, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980120', XBuildings, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('991110', XBuildings, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980122', XHistoricalCost, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980124', XAccumDeprecAtStartOfFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980126', XInvestmentCurrentFY, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('980128', XDepreciationCurrentFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980129', XTotalBuildings, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980200', XMachinery, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('991210', XMachinery, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980202', XHistoricalCost, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991240', XAccumDeprecAtStartOfFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991220', XInvestmentCurrentFY, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991230', XDepreciationCurrentFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980209', XTotalMachinery, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980250', XInventory, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('980251', XInventory, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980252', XHistoricalCost, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980254', XAccumDeprecAtStartOfFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980256', XInvestmentCurrentFY, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('980258', XDepreciationCurrentFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980259', XTotalInventory, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980300', XVehicles, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('991310', XVehicles, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980302', XHistoricalCost, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991340', XAccumDeprecAtStartOfFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('991320', XInvestmentCurrentFY, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('991330', XDepreciationCurrentFY, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980308', XDisposal, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980309', XTotalVehicles, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980400', XParticipation, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('980402', XParticipation1, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980403', XParticipation2, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980409', XTotalParticipation, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980440', XReceivables, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('980441', XReceivablesParticipation1, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980442', XReceivablesParticipation2, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980487', XReceivablesFromManagement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980490', XOtherReceivables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980499', XTotalReceivables, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('993110', XAuthorizedShareCapital, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992890', XSharesInPortfolio, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980510', XSharePremiumReserve, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980515', XRevaluationReserve, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('993120', XGeneralReserve, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('993195', XNetProfitCurrentFYBV, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980800', XProvisions, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('980801', XPensionProvisions, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980830', XTaxProvisions, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980840', XWarrantyProvision, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992810', XOtherProvisions, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980869', XTotalProvisions, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980900', XLiabilitiesOver1Year, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('980901', XPrivateLoanContracted, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995110', XLoanFromCreditInstitution, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995120', XLongTermMortgage, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995310', XFinancing, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980941', XLeaseCommitment, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980951', XDebtToParticipation1, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980952', XDebtToParticipation2, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980987', XOtherLiabilities, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('980999', XTotalLiabilitiesOver1Year, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992910', XCash, 0, 1, 2, '', 0, '', '', '', '', true);
        InsertData('992920', XABNAMRO, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992930', XABNUSD, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981012', XRabobankUSD, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992940', XINGPostbank, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981015', XGenerale, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981150', XContraBookings, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992990', XTotalFinancialAccounts, 2, 1, 0,
          Adjust.Convert('992910') + '..' + Adjust.Convert('992990'), 0, '', '', '', '', true);
        InsertData('992310', XAccountsReceivableDomestic, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992320', XAccountsReceivableForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('981320', XProvisionForBadDebts, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992330', XInterestOnLoanReceivable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981425', XOtherSubsidiesReceivable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981430', XDividendReceivable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981440', XLoanReceivable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992340', XOtherReceivables, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981475', XAccruedIncome, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981485', XGuaranteeDeposit, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981490', XOtherAdvancePayments, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('992390', XTotalReceivables, 2, 1, 0,
          Adjust.Convert('992310') + '..' + Adjust.Convert('992390'), 0, '', '', '', '', true);
        InsertData('981500', XVAT, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('995511', XSalesVAT6Percent, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995510', XSalesVAT21Percent, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981514', XSalesVAT0PercentEU, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995531', XPurchaseVAT6Percent, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995521', XPurchaseVAT6PercentEU, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995530', XPurchaseVAT21Percent, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995520', XPurchaseVAT0PercentEU, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981560', XGeneralAdvanceTax, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981580', XRegulatnForSmallEntrepren, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995710', XVATPayment, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981591', XAnnualcalculation, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981595', XAdditionVATPayment, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981596', XVATBadDebts, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995790', XTotalVAT, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995410', XAccountsPayableDomestic, 0, 1, 1, '', 0, '', '', '', '', false);
        InsertData('995420', XAccountsPayableForeign, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995490', XTotalAccountsPayable, 2, 1, 0,
          Adjust.Convert('995410') + '..' + Adjust.Convert('995490'), 0, '', '', '', '', true);
        InsertData('981640', XRepaymtOnLiabilitUnder1Year, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('981641', XPrivateLoan, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981643', XLoanFromCreditInstitution, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981647', XFinancing, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981649', XLeaseCommitment, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995910', XDividend, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('994010', XDividendTaxPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995920', XCompanyTaxPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981675', XAuditorCostsDue, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981680', XInterestOnLoansContracted, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981690', XOtherLiabilitiesUnder1Year, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981700', XAccruedLiabilities, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995990', XTotRepOnLiabilitUnderYr, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981750', XCurrentAccount, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('981751', XCurrAccountParticipation1, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981752', XCurrAccountParticipation2, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981790', XCurrentAccountManagement, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981793', XTotalCurrentAccount, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981800', XInvestmentsPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981900', XNetWages, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981920', XDeductionsContributions, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('995830', XSocialSecurityContributions, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995810', XTaxOnWages, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981923', XEarlyPensionContribution, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981924', XPensionContribution, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995820', XContribToOtherSocialFund, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981930', XDeductionForSavingsPlan, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981931', XDeductnPremSavingsScheme, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981932', XDeductnPrivateMedicInsur, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981933', XTotaldeductionsContributions, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981950', XReservedForVacationBonuses, 3, 1, 1, '', 0, '', '', '', '', true);
        InsertData('981955', XVacationVouchers, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('981960', XLoadingForVacationVouchers, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995840', XReservedForVacationBonuses, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('995890', XTotalResForVacatnBonuses, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('982000', XSuspenseAccounts, 3, 1, 2, '', 0, '', '', '', '', true);
        InsertData('982100', XPreliminaryBookings, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('982200', XPeriodicalSuspenseAccount, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('982300', XBookingsToBeQueried, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('982900', XBalanceSheetContribution, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('982999', XTotalSuspenseAccounts, 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData('983000', XPurchaseValueTurnover, 3, 0, 2, '', 0, '', '', '', '', true);
        InsertData('983010', XTradeGoodsPurchase0PercentVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('983020', XTradeGoodsPurchase6PercentVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('997110', XTradeGoodsPurchase21PercVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('983040', XTrGdsPurchRevChrgVAT, 0, 1, 0, '', 1, '', '', '', '', true);
        InsertData('997120', XTradeGoodsPurchaseVATEU, 0, 1, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('997130', XTrGoodsPurchaseOutsideEU, 0, 1, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('983070', XDiscTrGoodsAcctsPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('983110', XSemiFinGoodsPurch0PercentVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('983120', XSemiFinGoodsPurch6PercentVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('983130', XSemiFinGoodsPurch21PercentVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('983140', XSFGdsPrchRevChrgVAT, 0, 1, 0, '', 1, '', '', '', '', true);
        InsertData('983150', XSemiFinGoodsPurchVATEU, 0, 1, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('983160', XSFGoodsPurchaseOutsideEU, 0, 1, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('983170', XDiscSemiFinAcctsPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('983210', XRawMaterialsPurchase0PercVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('983220', XRawMaterialsPurchase6PercVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('997210', XRawMaterialsPurchase21PercVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('983240', XRawMatPurchRevChrgVAT, 0, 1, 0, '', 1, '', '', '', '', true);
        InsertData('997220', XRawMaterialsPurchaseVATEU, 0, 1, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('997230', XRawMatPurchaseOutsideEU, 0, 1, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '', '', true);
        InsertData('997240', XDiscRawMatAcctsPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('983310', XAdditivesPurchase0PercentVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('983320', XAdditivesPurchase6PercentVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('983330', XAdditivesPurchase21PercentVAT, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('983340', XAdditivPurchRevChrgVAT, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('983350', XAdditivesPurchaseVATEU, 0, 1, 0, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('983360', XAdditivesPurchaseOutsideEU, 0, 1, 0, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('997140', XDiscAdditivesAcctsPayable, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('983500', XThirdPartyServicesTrade, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('983600', XFreight, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997150', XFreightTradeGoods, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('983620', XFreightSemiFinishedGoods, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('997250', XFreightRawMaterials, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('983640', XFreightAdditives, 0, 1, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', false);
        InsertData('983690', XTotalFreight, 4, 0, 0, '', 0, '', '', '', '', false);
        InsertData('983850', XDepreciatnObsoleteInventory, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('983900', XVariousPurchaseCosts, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData('983999', XTotalPurchaseValueTurnover, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984000', XPersonnelExpenses, 3, 0, 2, '', 0, '', '', '', '', true);
        InsertData('998710', XWagesAndSalaries, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998720', XManagementSalaries, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998740', XVacationBonuses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984007', XVacationVouchers, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984010', XHiredPersonnel, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984011', XHomeWorkers, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984017', XBonuses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984020', XIncomeTaxOnSavingsPlan, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998750', XSocialSecurities, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984022', XEarlyPensionContribution, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984023', XContributionToPensionFund, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984025', XOtherContribToSocialFunds, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984030', XSickPayDisabilityReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984031', XSickPayDisabilityPaid, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984033', XPaymOfHoldUpsDueToFrost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984039', XLaborCostSubsidiesReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998730', XPensionInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984042', XCreditingOfPensionInsurance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984046', XPrivateUseCompanyCar, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984050', XCanteenCost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984055', XExcursionCost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984060', XStaffAssociation, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984062', XStaffGifts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984064', XDutyFreePayment, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984070', XRecruitmentCost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984075', XWorkWear, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984080', XCommutingAllowance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984082', XCarExpenseAllowance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984084', XCollectiveAllowances, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984086', XStudyCostAllowance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984088', XExpenseAllowance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984090', XTelephoneAllowance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984091', XTravelAndAccommodnExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984095', XOtherPersonnelExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984099', XTotalPersonnelExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998100', XHousingExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('984110', XRentPaid, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984111', XRentReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984120', XBuildingMaintenance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984122', XLandMaintenance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984123', XChangeInCostEqualizatRes, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998110', XCleaningExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('998120', XGasWaterElectricity, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984135', XPrivateUseEnergy, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984140', XInsurances, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984143', XTaxes, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984145', XFixedCharges, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984190', XOtherHousingExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984199', XTotalHousingExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984200', XOperatingExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('998130', XRepairMaintenanceCost, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984213', XCostOfRentLease, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984214', XMinorExpensesInvMach, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984217', XEquipmentExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984230', XContractingExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984237', XConstructionConnections, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984238', XContainerCost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984242', XMusicFees, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984245', XPermits, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998450', XFreight, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984251', XPacking, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984253', XImportDuties, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999250', XPaymentDiscountAR, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999130', XPaymentDiscountAP, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984275', XLaundryCost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984280', XInsurances, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984285', XManagementFees, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998640', XOtherOverheadCosts, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('998910', XOtherOperatingExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('984299', XTotalOperatingExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984400', XAdministrativeExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('998210', XOfficeSupplies, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984410', XPrinting, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998240', XPostalCharges, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998230', XTelephoneCharges, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('984422', XTelexFaxCharges, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984427', XPrivateUseTelephone, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984430', XProfessionalLiterature, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984440', XAccounting, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984450', XCollectingCharges, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998310', XComputerExpensesSoftware, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998330', XComputerExpensesOther, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984490', XOtherAdministrativeExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984499', XAdministrativeExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984500', XCarExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('984501', XGeneralCarExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998510', XFuelExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('998530', XMaintenanceExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984520', XInsurances, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998520', XTaxes, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('984530', XCarLeasing, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984540', XMileageAllowance, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984550', XTrafficFines, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984590', XOtherCarExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984595', XPrivateUseCompanyCar, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984599', XTotalCarExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984600', XSalesExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('998410', XAdvertising, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984615', XPackingMaterial, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998420', XEntertainmentExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984625', XPromotionalGifts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998430', XTravelAndAccommodnExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('984650', XSalesCommission, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984660', XDisplayCost, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984665', XCollectingCharges, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998620', XDepreciationCostBadDebts, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999140', XInvoiceDifferences, 0, 0, 0, '', 0, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('984690', XOtherSalesExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984699', XSalesExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984700', XGeneralExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('984701', XIndemnity, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984705', XGeneralInsurances, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984720', XSubscriptions, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984725', XCashDifferences, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999150', XExchangeDifferences, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984728', XPaymentDifferences, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998630', XAccountancyExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('998320', XConsultancyExpenses, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('984736', XBankingExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984760', XFinesRecoveredTaxesBV, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984765', XAdditionalSalesTax, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984770', XReductOfStandRightDuties, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984775', XLifeAnnuityPayments, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984780', XDonations, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984785', XVATRegulatnSmallEntrepren, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984790', XOtherGeneralExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984799', XTotalGeneralExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984800', XDepreciationExpenses, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('984801', XResearchExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984810', XDevelopmentExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984811', XLicenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984812', XPermits, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984813', XIntellectualProperty, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984815', XGoodwill, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984820', XLand, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998810', XBuildings, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984840', XRenovation, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998820', XMachinery, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984860', XInstallations, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984870', XInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998830', XVehicles, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('998840', XPuttingOutOfService, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('984899', XTotalDepreciationExpenses, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('986000', XCostOfGoodsSold, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('997190', XCOGSTradeGoods, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997189', XCOGSTradeGoodsInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997290', XCOGSRawMaterials, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997289', XCOGSRawMaterialsInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997490', XCOGSAdditives, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997620', XCOGSJobs, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('992220', XCostWIP, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('986099', XTotalCOGS, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('987000', XInventory, 3, 0, 2, '', 0, '', '', '', '', true);
        InsertData('992110', XTradeGoodsInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('992111', XTradeGdsInventoryInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('987200', XSemiFinishedGoodsInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('992130', XRawMaterialsInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('992131', XRawMatInventoryInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('987300', XAdditivesInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('992120', XFinishedGoodsInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('992121', XFinGoodsInventoryInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('992210', XFinishedGoodsInventoryWIP, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('987890', XPackingInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('987900', XEquipmentInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('987910', XPrintingInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('987920', XPostageInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('987930', XAdvertisingMaterialInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('987940', XPackingMaterialInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('987950', XVacationVouchersInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('987960', XVouchersInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('992180', XOtherCostInventory, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('992190', XTotalInventory, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('988000', XSales, 3, 0, 2, '', 0, '', '', '', '', true);
        InsertData('988010', XTradeGoodsSales0Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('988020', XTradeGoodsSales6Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('996110', XTradeGoodsSales21Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996120', XTradeGoodsSalesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996130', XTradeGoodsSalesOutsideEU, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('988110', XSemiFinishedGoodsSales0Perc, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('988120', XSemiFinishedGoodsSales6Perc, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('988130', XSemiFinishedGoodsSales21Perc, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('988140', XSemiFinishedGoodsSalesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('988150', XSFGoodsSalesOutsideEU, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996210', XRawMaterialsSales0Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('988220', XRawMaterialsSales6Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('988230', XRawMaterialsSales21Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996220', XRawMaterialsSalesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996230', XRawMaterialsSalesOutsideEU, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('988310', XAdditivesSales0Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('988320', XAdditivesSales6Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('996410', XAdditivesSales21Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996420', XAdditivesSalesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996430', XAdditivesSalesOutsideEU, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('988410', XFinishedGoodsSales0Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('988420', XFinishedGoodsSales6Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData('988430', XFinishedGoodsSales21Percent, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('988440', XFinishedGoodsSalesEU, 0, 0, 0, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('988450', XFinGoodsSalesOutsideEU, 0, 0, 0, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('988550', XGamblingMachineSales, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('996620', XJobSales, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996610', XOtherJobSales, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '', true);
        InsertData('996190', XCorrProjectFinGoodsSales, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996191', XJobSalesAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('988610', XCorrProjectSFGoodsSales, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996490', XCorrProjectAdditivesSales, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996491', XJobSalesAdjmtResources, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('996290', XCorrProjectRawMatSales, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996291', XJobSalesAdjmtRawMat, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('988700', XStoreSales, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('988710', XCommission, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('996710', XConsultancySales, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('996810', XVariousSales, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData('988790', XIntercompanyTransaction, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('988799', XTotalSales, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('988800', XChange, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('997170', XChangeInTradeGoods, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997171', XChangeInTradeGdsInterim, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('988810', XChangeWIP, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('988820', XChangeInSemiFinGoodsInv, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997270', XChangeInRawMaterialsInv, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997271', XChgInRawMatInvIntrm, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('988840', XChangeInFinishedGoodsInv, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997180', XChangeInTradeGoodsJobs, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997181', XJobCostAdjmtRetail, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997281', XJobCostAdjmtRawMaterials, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('988860', XChgInSemiFinGoodsJobs, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997480', XChangeInAdditivesJobs, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('997481', XJobCostAdjmtResources, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('997280', XChangeInRawMatJobs, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('988899', XTotalChange, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('988990', XOtherRevenues, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989400', XInterestReceived, 3, 0, 2, '', 0, '', '', '', '', true);
        InsertData('999110', XLoansReceivable, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999120', XAccountReceivable, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '', true);
        InsertData('989405', XDepositInterestReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989406', XOtherInterestReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989407', XPaymentToleranceReceived, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989408', XPaymentTolRecvdDecrease, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989409', XTotalInterestReceived, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989410', XInterestPaid, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999220', XPrivateLoans, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999240', XAccountsPayableInterest, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989416', XHandlingFeeBank, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989417', XMortgageDeedFee, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999230', XMortgageInterest, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999210', XFinancingInterest, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989421', XOtherInterestPaid, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989439', XBankingInterestAndExpenses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989440', XPaymentToleranceGranted, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989441', XPaymentTolGrntdDecrease, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989499', XTotalInterestPaid, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989600', XResultParticipations, 3, 0, 1, '', 0, '', '', '', '', true);
        InsertData('999310', XParticipatnUnrealizedProfit, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999320', XParticipationUnrealizedLoss, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999330', XParticipationRealizedProfit, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999340', XParticipationRealizedLoss, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989699', XTotalResultParticipations, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999510', XExtraordinaryPLCompanyTax, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989800', X3rdPartyParticInGrpRes, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989900', XInterestOnEquity, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989901', XWorkCompensationPartners, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999410', XExtraordinaryProfits, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('999420', XExtraordinaryLosses, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('989999', XNetProfitCurrentFY, 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData('995360', XCustomerPrepaymentsVAT0, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995370', XCustomerPrepaymentsVAT10, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('995380', XCustomerPrepaymentsVAT21, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992410', XVendorPrepaymentsVAT0, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992420', XVendorPrepaymentsVAT10, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992430', XVendorPrepaymentsVAT21, 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData('992230', XWIPCosts, 3, 0, 0, '', 0, '', '', '', '', false);
        InsertData('992231', XWIPJobCosts, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('992232', XAccruedJobCosts, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('992240', XWIPCostsTotal, 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData('992211', XWIPJobSales, 0, 0, 0, '', 0, '', '', '', '', false);
        InsertData('992212', XInvoicedJobSales, 0, 0, 0, '', 0, '', '', '', '', false);
        GLAccIndent.Indent();
        AddCategoriesToGLAccounts();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Adjust: Codeunit "Make Adjustments";
        GLAccIndent: Codeunit "G/L Account-Indent";
        XVehicles: Label 'Vehicles';
        XDisposal: Label 'Disposal';
        XTotalVehicles: Label 'Total Vehicles';
        XParticipation: Label 'Participation';
        XParticipation1: Label 'Participation 1';
        XParticipation2: Label 'Participation 2';
        XTotalParticipation: Label 'Total Participation';
        XReceivables: Label 'Receivables';
        XReceivablesParticipation1: Label 'Receivables Participation 1';
        XReceivablesParticipation2: Label 'Receivables Participation 2';
        XReceivablesFromManagement: Label 'Receivables from Management';
        XInventory: Label 'Inventory';
        XTotalInventory: Label 'Total Inventory';
        XWIPCosts: Label 'WIP Costs';
        XOtherReceivables: Label 'Other Receivables';
        XTotalReceivables: Label 'Total Receivables';
        XAuthorizedShareCapital: Label 'Authorized Share Capital';
        XSharesInPortfolio: Label 'Shares in Portfolio';
        XSharePremiumReserve: Label 'Share Premium Reserve';
        XRevaluationReserve: Label 'Revaluation Reserve';
        XGeneralReserve: Label 'General Reserve';
        XNetProfitCurrentFYBV: Label 'Net Profit Current FY (BV)';
        XProvisions: Label 'Provisions';
        XPensionProvisions: Label 'Pension Provisions';
        XTaxProvisions: Label 'Tax Provisions';
        XWarrantyProvision: Label 'Warranty Provision';
        XOtherProvisions: Label 'Other Provisions';
        XTotalProvisions: Label 'Total Provisions';
        XLiabilitiesOver1Year: Label 'Liabilities > 1 Year';
        XPrivateLoanContracted: Label 'Private Loan Contracted';
        XLoanFromCreditInstitution: Label 'Loan from Credit Institution';
        XLongTermMortgage: Label 'Long-term Mortgage';
        XFinancing: Label 'Financing';
        XLeaseCommitment: Label 'Lease Commitment';
        XDebtToParticipation1: Label 'Debt to Participation 1';
        XDebtToParticipation2: Label 'Debt to Participation 2';
        XCash: Label 'Cash';
        XABNAMRO: Label 'ABN/AMRO';
        XABNUSD: Label 'ABN USD';
        XRabobankUSD: Label 'Rabobank USD';
        XINGPostbank: Label 'ING/Postbank';
        XGenerale: Label 'Generale';
        XContraBookings: Label 'ContraBookings';
        XTotalFinancialAccounts: Label 'Total Financial Accounts';
        XAccountsReceivableDomestic: Label 'Accounts Receivable (Domestic)';
        XAccountsReceivableForeign: Label 'Accounts Receivable (Foreign)';
        XProvisionForBadDebts: Label 'Provision for Bad Debts';
        XInterestOnLoanReceivable: Label 'Interest on Loan Receivable';
        XOtherSubsidiesReceivable: Label 'Other Subsidies Receivable';
        XDividendReceivable: Label 'Dividend Receivable';
        XLoanReceivable: Label 'Loan Receivable';
        XAccruedIncome: Label 'Accrued Income';
        XGuaranteeDeposit: Label 'Guarantee Deposit';
        XOtherAdvancePayments: Label 'Other Advance Payments';
        XVAT: Label 'VAT';
        XSalesVAT6Percent: Label 'Sales VAT 6%';
        XSalesVAT21Percent: Label 'Sales VAT 21%';
        XSalesVAT0PercentEU: Label 'Sales VAT 0% EU';
        XPurchaseVAT6Percent: Label 'Purchase VAT 6%';
        XPurchaseVAT6PercentEU: Label 'Purchase VAT 6% EU';
        XPurchaseVAT21Percent: Label 'Purchase VAT 21%';
        XPurchaseVAT0PercentEU: Label 'Purchase VAT 0% EU';
        XGeneralAdvanceTax: Label 'General Advance Tax';
        XRegulatnForSmallEntrepren: Label 'Regulatn. for small entrepren.';
        XVATPayment: Label 'VAT Payment';
        XAnnualcalculation: Label 'Annual Calculation';
        XAdditionVATPayment: Label 'Addition VAT Payment';
        XVATBadDebts: Label 'VAT Bad Debts';
        XTotalVAT: Label 'Total VAT';
        XAccountsPayableDomestic: Label 'Accounts Payable (Domestic)';
        XAccountsPayableForeign: Label 'Accounts Payable (Foreign)';
        XTotalAccountsPayable: Label 'Total Accounts Payable';
        XRepaymtOnLiabilitUnder1Year: Label 'Repaymt. on Liabilit. <1 Year';
        XPrivateLoan: Label 'Private Loan';
        XDividend: Label 'Dividend';
        XDividendTaxPayable: Label 'Dividend Tax Payable';
        XCompanyTaxPayable: Label 'Company Tax Payable';
        XAuditorCostsDue: Label 'Auditor Costs Due';
        XInterestOnLoansContracted: Label 'Interest on Loans Contracted';
        XOtherLiabilitiesUnder1Year: Label 'Other Liabilities < 1 Year ';
        XAccruedLiabilities: Label 'Accrued Liabilities';
        XTotRepOnLiabilitUnderYr: Label 'Tot. Rep. on Liabilit. <1 Yr. ';
        XCurrentAccount: Label 'Current Account';
        XCurrAccountParticipation1: Label 'Curr. Account Participation 1';
        XCurrAccountParticipation2: Label 'Curr. Account Participation 2';
        XCurrentAccountManagement: Label 'Current Account Management';
        XTotalCurrentAccount: Label 'Total Current Account';
        XInvestmentsPayable: Label 'Investments Payable';
        XNetWages: Label 'Net Wages';
        XDeductionsContributions: Label 'Deductions/Contributions';
        XSocialSecurityContributions: Label 'Social Security Contributions';
        XTaxOnWages: Label 'Tax on Wages';
        XEarlyPensionContribution: Label 'Early Pension Contribution';
        XPensionContribution: Label 'Pension Contribution';
        XContribToOtherSocialFund: Label 'Contrib. to Other Social Funds';
        XDeductionForSavingsPlan: Label 'Deduction for Savings Plan';
        XDeductnPremSavingsScheme: Label 'Deductn. Prem. Savings Scheme';
        XDeductnPrivateMedicInsur: Label 'Deductn. Private Medic. Insur.';
        XTotaldeductionsContributions: Label 'Total Deductions/Contributions';
        XReservedForVacationBonuses: Label 'Reserved for Vacation Bonuses';
        XVacationVouchers: Label 'Vacation Vouchers';
        XLoadingForVacationVouchers: Label 'Loading for Vacation Vouchers';
        XTotalResForVacatnBonuses: Label 'Total Res. For Vacatn. Bonuses';
        XSuspenseAccounts: Label 'SuspenseAccounts';
        XPreliminaryBookings: Label 'Preliminary Bookings';
        XPeriodicalSuspenseAccount: Label 'Periodical Suspense Account';
        XBookingsToBeQueried: Label 'Bookings to be Queried';
        XBalanceSheetContribution: Label 'Balance Sheet Contribution';
        XTotalSuspenseAccounts: Label 'Total Suspense Accounts';
        XPurchaseValueTurnover: Label 'Purchase Value Turnover';
        XTradeGoodsPurchase0PercentVAT: Label 'Trade Goods Purchase 0% VAT';
        XTradeGoodsPurchase6PercentVAT: Label 'Trade Goods Purchase 6% VAT';
        XTradeGoodsPurchase21PercVAT: Label 'Trade Goods Purchase 21% VAT';
        XTrGdsPurchRevChrgVAT: Label 'Tr. Gds. Purch. Rev.-Chrg. VAT';
        XTradeGoodsPurchaseVATEU: Label 'Trade Goods Purchase VAT EU';
        XTrGoodsPurchaseOutsideEU: Label 'Tr. Goods Purchase Outside EU';
        XDiscTrGoodsAcctsPayable: Label 'Disc. Tr. Goods Accts. Payable';
        XSemiFinGoodsPurch0PercentVAT: Label 'Semi-Fin. Goods Purch. 0% VAT';
        XSemiFinGoodsPurch6PercentVAT: Label 'Semi-Fin. goods purch. 6% VAT';
        XSemiFinGoodsPurch21PercentVAT: Label 'Semi-Fin. goods purch. 21% VAT';
        XSFGdsPrchRevChrgVAT: Label 'S-F. Gds. Prch. Rev.-Chrg. VAT';
        XSemiFinGoodsPurchVATEU: Label 'Semi-Fin. Goods Purch. VAT EU';
        XSFGoodsPurchaseOutsideEU: Label 'S-F. Goods Purchase Outside EU';
        XDiscSemiFinAcctsPayable: Label 'Disc. Semi-Fin. Accts. Payable';
        XRawMaterialsPurchase0PercVAT: Label 'Raw Materials Purchase 0% VAT';
        XRawMaterialsPurchase6PercVAT: Label 'Raw Materials Purchase 6% VAT';
        XRawMaterialsPurchase21PercVAT: Label 'Raw Materials Purchase 21% VAT';
        XRawMatPurchRevChrgVAT: Label 'Raw Mat. Purch. Rev.-Chrg. VAT';
        XRawMaterialsPurchaseVATEU: Label 'Raw Materials Purchase VAT EU';
        XRawMatPurchaseOutsideEU: Label 'Raw Mat. Purchase Outside EU';
        XDiscRawMatAcctsPayable: Label 'Disc. Raw Mat. Accts. Payable';
        XAdditivesPurchase0PercentVAT: Label 'Additives Purchase 0% VAT';
        XAdditivesPurchase6PercentVAT: Label 'Additives Purchase 6% VAT';
        XAdditivesPurchase21PercentVAT: Label 'Additives Purchase 21% VAT';
        XAdditivPurchRevChrgVAT: Label 'Additiv. Purch. Rev.-Chrg. VAT';
        XAdditivesPurchaseVATEU: Label 'Additives Purchase VAT EU';
        XAdditivesPurchaseOutsideEU: Label 'Additives Purchase Outside EU';
        XDiscAdditivesAcctsPayable: Label 'Disc. Additives Accts. Payable';
        XThirdPartyServicesTrade: Label 'Third Party Services (Trade)';
        XFreight: Label 'Freight';
        XFreightTradeGoods: Label 'Freight Trade Goods';
        XFreightSemiFinishedGoods: Label 'Freight Semi-Finished Goods';
        XFreightRawMaterials: Label 'Freight Raw Materials';
        XFreightAdditives: Label 'Freight Additives';
        XTotalFreight: Label 'Total Freight';
        XDepreciatnObsoleteInventory: Label 'Depreciatn. Obsolete Inventory';
        XVariousPurchaseCosts: Label 'Various Purchase Costs';
        XTotalPurchaseValueTurnover: Label 'Total Purchase Value Turnover';
        XOtherLiabilities: Label 'Other Liabilities';
        XTotalLiabilitiesOver1Year: Label 'Total Liabilities > 1 Year';
        XJobSalesAdjmtRetail: Label 'Job Sales Adjmt., Retail';
        XWIPJobSales: Label 'WIP Job Sales';
        XInvoicedJobSales: Label 'Invoiced Job Sales';
        XJobSalesAdjmtRawMat: Label 'Job Sales Adjmt., Raw Mat.';
        XJobSalesAdjmtResources: Label 'Job Sales Adjmt., Resources';
        XJobSales: Label 'Job Sales';
        XOtherJobSales: Label 'Other Job Sales';
        XCorrProjectFinGoodsSales: Label 'Corr. Project Fin. Goods Sales';
        XCorrProjectSFGoodsSales: Label 'Corr. Project S-F. Goods Sales';
        XCorrProjectAdditivesSales: Label 'Corr. Project Additives Sales';
        XCorrProjectRawMatSales: Label 'Corr. Project Raw Mat. Sales';
        XStoreSales: Label 'Store Sales';
        XCommission: Label 'Commission';
        XConsultancySales: Label 'Consultancy Sales';
        XVariousSales: Label 'Various Sales';
        XIntercompanyTransaction: Label 'Intercompany Transaction';
        XTotalSales: Label 'Total Sales';
        XChange: Label 'Change';
        XChangeInTradeGoods: Label 'Change in Trade Goods';
        XChangeInTradeGdsInterim: Label 'Change in Trade Gds. (Interim)';
        XChangeWIP: Label 'Change WIP';
        XChangeInSemiFinGoodsInv: Label 'Change in Semi-Fin. Goods Inv.';
        XChangeInRawMaterialsInv: Label 'Change in Raw Materials Inv.';
        XChgInRawMatInvIntrm: Label 'Chg. in Raw Mat. Inv. (Intrm.)';
        XChangeInFinishedGoodsInv: Label 'Change in Finished Goods Inv.';
        XChangeInTradeGoodsJobs: Label 'Change in Trade Goods Jobs';
        XChgInSemiFinGoodsJobs: Label 'Chg. in Semi-Fin. Goods Jobs';
        XChangeInAdditivesJobs: Label 'Change in Additives Jobs';
        XChangeInRawMatJobs: Label 'Change in Raw Mat. Jobs';
        XTotalChange: Label 'Total Change';
        XOtherRevenues: Label 'Other Revenues';
        XInterestReceived: Label 'Interest Received';
        XLoansReceivable: Label 'Loans Receivable';
        XAccountReceivable: Label 'Accounts Receivable';
        XDepositInterestReceived: Label 'Deposit Interest Received';
        XOtherInterestReceived: Label 'Other Interest Received';
        XJobCostAdjmtRetail: Label 'Job Cost Adjmt., Retail';
        XJobCostAdjmtRawMaterials: Label 'Job Cost Adjmt., Raw Materials';
        XJobCostAdjmtResources: Label 'Job Cost Adjmt., Resources';
        XOperatingExpenses: Label 'Operating Expenses';
        XRepairMaintenanceCost: Label 'Repair/Maintenance Cost';
        XCostOfRentLease: Label 'Cost of Rent/Lease';
        XMinorExpensesInvMach: Label 'Minor Expenses Inv./Mach.';
        XEquipmentExpenses: Label 'Equipment Expenses';
        XContractingExpenses: Label 'Contracting Expenses';
        XConstructionConnections: Label 'Construction Connections';
        XContainerCost: Label 'Container Cost';
        XMusicFees: Label 'Music Fees';
        XPermits: Label 'Permits';
        XPacking: Label 'Packing';
        XImportDuties: Label 'Import Duties';
        XPaymentDiscountAR: Label 'Payment Discount AR';
        XPaymentDiscountAP: Label 'Payment Discount AP';
        XLaundryCost: Label 'Laundry Cost';
        XManagementFees: Label 'Management Fees';
        XOtherOverheadCosts: Label 'Other Overhead Costs';
        XAdministrativeExpenses: Label 'Administrative Expenses';
        XOfficeSupplies: Label 'Office Supplies';
        XPrinting: Label 'Printing';
        XPostalCharges: Label 'Postal Charges';
        XTelephoneCharges: Label 'Telephone Charges';
        XTelexFaxCharges: Label 'Telex/Fax Charges';
        XPrivateUseTelephone: Label 'Private Use Telephone';
        XProfessionalLiterature: Label 'Professional Literature';
        XAccounting: Label 'Accounting';
        XCollectingCharges: Label 'Collecting Charges';
        XComputerExpensesSoftware: Label 'Computer Expenses, Software';
        XComputerExpensesOther: Label 'Computer Expenses, Other';
        XOtherAdministrativeExpenses: Label 'Other Administrative Expenses';
        XCarExpenses: Label 'Car Expenses';
        XGeneralCarExpenses: Label 'General Car Expenses';
        XFuelExpenses: Label 'Fuel Expenses';
        XMaintenanceExpenses: Label 'Maintenance Expenses';
        XCarLeasing: Label 'Car Leasing';
        XMileageAllowance: Label 'Mileage Allowance';
        XTrafficFines: Label 'Traffic Fines';
        XOtherCarExpenses: Label 'Other Car Expenses';
        XTotalCarExpenses: Label 'Total Car Expenses';
        XSalesExpenses: Label 'Sales Expenses';
        XAdvertising: Label 'Advertising';
        XPackingMaterial: Label 'Packing Material';
        XEntertainmentExpenses: Label 'Entertainment Expenses';
        XPromotionalGifts: Label 'Promotional Gifts';
        XSalesCommission: Label 'Sales Commission';
        XDisplayCost: Label 'Display Cost';
        XDepreciationCostBadDebts: Label 'Depreciation Cost Bad Debts';
        XInvoiceDifferences: Label 'Invoice Differences';
        XOtherSalesExpenses: Label 'Other Sales Expenses';
        XGeneralExpenses: Label 'General Expenses';
        XIndemnity: Label 'Indemnity';
        XGeneralInsurances: Label 'General Insurances';
        XSubscriptions: Label 'Subscriptions';
        XCashDifferences: Label 'Cash Differences';
        XExchangeDifferences: Label 'Exchange Differences';
        XPaymentDifferences: Label 'Payment Differences';
        XAccountancyExpenses: Label 'Accountancy Expenses';
        XConsultancyExpenses: Label 'Consultancy Expenses';
        XBankingExpenses: Label 'Banking Expenses';
        XFinesRecoveredTaxesBV: Label 'Fines/Recovered Taxes/BV';
        XAdditionalSalesTax: Label 'Additional Sales Tax';
        XReductOfStandRightDuties: Label 'Reduct. of Stand. Right Duties';
        XLifeAnnuityPayments: Label 'Life Annuity Payments';
        XDonations: Label 'Donations';
        XVATRegulatnSmallEntrepren: Label 'VAT Regulatn. Small Entrepren.';
        XOtherGeneralExpenses: Label 'Other General Expenses';
        XTotalGeneralExpenses: Label 'Total General Expenses';
        XDepreciationExpenses: Label 'Depreciation Expenses';
        XResearchExpenses: Label 'Research Expenses';
        XDevelopmentExpenses: Label 'Development Expenses';
        XLicenses: Label 'XLicenses';
        XIntellectualProperty: Label 'Intellectual Property';
        XRenovation: Label 'Renovation';
        XInstallations: Label 'Installations';
        XPuttingOutOfService: Label 'Putting Out of Service';
        XTotalDepreciationExpenses: Label 'Total Depreciation Expenses';
        XCostOfGoodsSold: Label 'Cost of Goods Sold';
        XCOGSTradeGoods: Label 'COGS Trade Goods';
        XCOGSTradeGoodsInterim: Label 'COGS Trade Goods (Interim)';
        XCOGSRawMaterials: Label 'COGS Raw Materials';
        XCOGSRawMaterialsInterim: Label 'COGS Raw Materials (Interim)';
        XCOGSAdditives: Label 'COGS Additives';
        XCOGSJobs: Label 'COGS Jobs';
        XCostWIP: Label 'Cost WIP';
        XTotalCOGS: Label 'Total COGS';
        XTradeGoodsInventory: Label 'Trade Goods Inventory';
        XTradeGdsInventoryInterim: Label 'Trade Gds. Inventory (Interim)';
        XSemiFinishedGoodsInventory: Label 'Semi-Finished Goods Inventory';
        XRawMaterialsInventory: Label 'Raw Materials Inventory';
        XRawMatInventoryInterim: Label 'Raw Mat. Inventory (Interim)';
        XAdditivesInventory: Label 'Additives Inventory';
        XFinishedGoodsInventory: Label 'Finished Goods Inventory';
        XFinGoodsInventoryInterim: Label 'Fin. Goods Inventory (Interim)';
        XFinishedGoodsInventoryWIP: Label 'Finished Goods Inventory WIP';
        XPackingInventory: Label 'Packing Inventory';
        XEquipmentInventory: Label 'Equipment Inventory';
        XPrintingInventory: Label 'Printing Inventory';
        XPostageInventory: Label 'Postage Inventory';
        XAdvertisingMaterialInventory: Label 'Advertising Material Inventory';
        XPackingMaterialInventory: Label 'Packing Material Inventory';
        XVacationVouchersInventory: Label 'Vacation Vouchers Inventory';
        XVouchersInventory: Label 'Vouchers Inventory';
        XOtherCostInventory: Label 'Other Cost Inventory';
        XSales: Label 'Sales';
        XTradeGoodsSales0Percent: Label 'Trade Goods Sales 0%';
        XTradeGoodsSales6Percent: Label 'Trade Goods Sales 6%';
        XTradeGoodsSales21Percent: Label 'Trade Goods Sales 21%';
        XTradeGoodsSalesEU: Label 'Trade Goods Sales EU';
        XTradeGoodsSalesOutsideEU: Label 'Trade Goods Sales Outside EU';
        XSemiFinishedGoodsSales0Perc: Label 'Semi-Finished Goods Sales 0%';
        XSemiFinishedGoodsSales6Perc: Label 'Semi-Finished Goods Sales 6%';
        XSemiFinishedGoodsSales21Perc: Label 'Semi-Finished Goods Sales 21%';
        XSemiFinishedGoodsSalesEU: Label 'Semi-Finished Goods Sales EU';
        XSFGoodsSalesOutsideEU: Label 'S-F. Goods Sales Outside EU';
        XRawMaterialsSales0Percent: Label 'Raw Materials Sales 0%';
        XRawMaterialsSales6Percent: Label 'Raw Materials Sales 6%';
        XRawMaterialsSales21Percent: Label 'Raw Materials Sales 21%';
        XRawMaterialsSalesEU: Label 'Raw Materials Sales EU';
        XRawMaterialsSalesOutsideEU: Label 'Raw Materials Sales Outside EU';
        XAdditivesSales0Percent: Label 'Additives Sales 0%';
        XAdditivesSales6Percent: Label 'Additives Sales 6%';
        XAdditivesSales21Percent: Label 'Additives Sales 21%';
        XAdditivesSalesEU: Label 'Additives Sales EU';
        XAdditivesSalesOutsideEU: Label 'Additives Sales Outside EU';
        XFinishedGoodsSales0Percent: Label 'Finished Goods Sales 0%';
        XFinishedGoodsSales6Percent: Label 'Finished Goods Sales 6%';
        XFinishedGoodsSales21Percent: Label 'Finished Goods Sales 21%';
        XFinishedGoodsSalesEU: Label 'Finished Goods Sales EU';
        XFinGoodsSalesOutsideEU: Label 'Fin. Goods Sales Outside EU';
        XGamblingMachineSales: Label 'Gambling Machine Sales';
        XOtherOperatingExpenses: Label 'Other Operating Expenses';
        XTotalOperatingExpenses: Label 'Total Operating Expenses';
        XPersonnelExpenses: Label 'Personnel Expenses';
        XWagesAndSalaries: Label 'Wages and Salaries';
        XManagementSalaries: Label 'Management Salaries';
        XVacationBonuses: Label 'Vacation Bonuses';
        XHiredPersonnel: Label 'Hired Personnel';
        XHomeWorkers: Label 'Home Workers';
        XBonuses: Label 'Bonuses';
        XIncomeTaxOnSavingsPlan: Label 'Income Tax on Savings Plan ';
        XSocialSecurities: Label 'Social Securities';
        XContributionToPensionFund: Label 'Contribution to Pension Fund';
        XOtherContribToSocialFunds: Label 'Other Contrib. to Social Funds';
        XSickPayDisabilityReceived: Label 'Sick Pay/Disability Received';
        XSickPayDisabilityPaid: Label 'Sick Pay/Disability Paid';
        XPaymOfHoldUpsDueToFrost: Label 'Paym. of Hold-Ups Due to Frost';
        XLaborCostSubsidiesReceived: Label 'Labor Cost Subsidies Received';
        XPensionInsurance: Label 'Pension Insurance';
        XCreditingOfPensionInsurance: Label 'Crediting of Pension Insurance';
        XPrivateUseCompanyCar: Label 'Private Use Company Car';
        XCanteenCost: Label 'Canteen Cost';
        XExcursionCost: Label 'Excursion Cost';
        XStaffAssociation: Label 'Staff Association';
        XStaffGifts: Label 'Staff Gifts';
        XDutyFreePayment: Label 'Duty-free Payment';
        XRecruitmentCost: Label 'Recruitment Cost';
        XWorkWear: Label 'Work Wear';
        XCommutingAllowance: Label 'Commuting Allowance';
        XCarExpenseAllowance: Label 'Car Expense Allowance';
        XCollectiveAllowances: Label 'Collective Allowances';
        XStudyCostAllowance: Label 'Study Cost Allowance';
        XExpenseAllowance: Label 'Expense Allowance';
        XTelephoneAllowance: Label 'Telephone Allowance';
        XTravelAndAccommodnExpenses: Label 'Travel and Accommodn. Expenses';
        XOtherPersonnelExpenses: Label 'Other Personnel Expenses';
        XTotalPersonnelExpenses: Label 'Total Personnel Expenses';
        XHousingExpenses: Label 'Housing Expenses';
        XRentPaid: Label 'Rent Paid';
        XRentReceived: Label 'Rent Received';
        XBuildingMaintenance: Label 'Building Maintenance';
        XLandMaintenance: Label 'Land Maintenance';
        XChangeInCostEqualizatRes: Label 'Change in Cost Equalizat. Res.';
        XCleaningExpenses: Label 'Cleaning Expenses';
        XGasWaterElectricity: Label 'Gas/Water/Electricity';
        XPrivateUseEnergy: Label 'Private Use Energy';
        XInsurances: Label 'Insurances';
        XTaxes: Label 'Taxes';
        XFixedCharges: Label 'Fixed Charges';
        XOtherHousingExpenses: Label 'Other Housing Expenses';
        XTotalHousingExpenses: Label 'Total Housing Expenses';
        XPaymentToleranceReceived: Label 'Payment Tolerance Received';
        XPaymentTolRecvdDecrease: Label 'Payment Tol. Recvd. (Decrease)';
        XTotalInterestReceived: Label 'Total Interest Received';
        XInterestPaid: Label 'Interest Paid';
        XPrivateLoans: Label 'Private Loans';
        XAccountsPayableInterest: Label 'Accounts Payable Interest';
        XHandlingFeeBank: Label 'Handling Fee Bank';
        XMortgageDeedFee: Label 'Mortgage Deed Fee';
        XMortgageInterest: Label 'Mortgage Interest';
        XFinancingInterest: Label 'Financing Interest';
        XOtherInterestPaid: Label 'Other Interest Paid';
        XBankingInterestAndExpenses: Label 'Banking Interest and Expenses';
        XPaymentToleranceGranted: Label 'Payment Tolerance Granted';
        XPaymentTolGrntdDecrease: Label 'Payment Tol. Grntd. (Decrease)';
        XTotalInterestPaid: Label 'Total Interest Paid';
        XResultParticipations: Label 'Result Participations';
        XParticipatnUnrealizedProfit: Label 'Participatn. Unrealized Profit';
        XParticipationUnrealizedLoss: Label 'Participation Unrealized Loss';
        XParticipationRealizedProfit: Label 'Participation Realized Profit';
        XParticipationRealizedLoss: Label 'Participation Realized Loss';
        XTotalResultParticipations: Label 'Total Result Participations';
        XExtraordinaryPLCompanyTax: Label 'Extraordinary P/L Company Tax';
        X3rdPartyParticInGrpRes: Label '3rd Party Partic. in Grp. Res.';
        XInterestOnEquity: Label 'Interest on Equity';
        XWorkCompensationPartners: Label 'Work Compensation Partners';
        XExtraordinaryProfits: Label 'Extraordinary Profits';
        XExtraordinaryLosses: Label 'Extraordinary Losses';
        XNetProfitCurrentFY: Label 'Net Profit Current FY';
        XGoodwill: Label 'Goodwill';
        XHistoricalCost: Label 'Historical Cost';
        XAccumDeprecAtStartOfFY: Label 'Accum. Deprec. at Start of FY';
        XInvestmentCurrentFY: Label 'Investment Current FY';
        XDepreciationCurrentFY: Label 'Depreciation Current FY';
        XTotalGoodwill: Label 'Total Goodwill';
        XLand: Label 'Land';
        XTotalLand: Label 'Total Land';
        XBuildings: Label 'Buildings';
        XTotalBuildings: Label 'Total Buildings';
        XMachinery: Label 'Machinery';
        XTotalMachinery: Label 'Total Machinery';
        XVendorPrepaymentsVAT0: Label 'Vendor Prepayments VAT 0%';
        XVendorPrepaymentsVAT10: Label 'Vendor Prepayments VAT 10%';
        XVendorPrepaymentsVAT21: Label 'Vendor Prepayments VAT 21%';
        XCustomerPrepaymentsVAT0: Label 'Customer Prepayments VAT 0%';
        XCustomerPrepaymentsVAT10: Label 'Customer Prepayments VAT 10%';
        XCustomerPrepaymentsVAT21: Label 'Customer Prepayments VAT 21%';
        XWIPJobCosts: Label 'WIP Job Costs';
        XAccruedJobCosts: Label 'Accrued Job Costs';
        XWIPCostsTotal: Label 'WIP Costs, Total';
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
        WIPJobSalesTok: Label 'WIP Job Sales', MaxLength = 100;
        WIPJobCostsTok: Label 'WIP Job Costs', MaxLength = 100;
        WIPAccruedCostsTok: Label 'WIP, Accrued Costs', MaxLength = 100;
        WIPInvoicedSalesTok: Label 'WIP, Invoiced Sales', MaxLength = 100;
        TotalWorkinProgressTok: Label 'Total, Work in Progress', MaxLength = 100;
        TotalInventoryProductsandWorkinProgressTok: Label 'Total, Inventory, Products and Work in Progress', MaxLength = 100;
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
        PurchaseVATReducedTok: Label 'Purchase VAT Reduced', MaxLength = 100;
        PurchaseVATNormalTok: Label 'Purchase VAT Normal', MaxLength = 100;
        MiscVATReceivablesTok: Label 'Misc VAT Receivables', MaxLength = 100;
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
        DeferredRevenueTok: Label 'Deferred Revenue', MaxLength = 100;
        TotalCurrentLiabilitiesTok: Label 'Total, Current Liabilities', MaxLength = 100;
        TaxLiabilitiesTok: Label 'Tax Liabilities', MaxLength = 100;
        SalesTax_VATLiableTok: Label 'Sales Tax / VAT Liable', MaxLength = 100;
        SalesVATReducedTok: Label 'Sales VAT Reduced', MaxLength = 100;
        SalesVATNormalTok: Label 'Sales VAT Normal', MaxLength = 100;
        MiscVATPayablesTok: Label 'Misc VAT Payables', MaxLength = 100;
        TaxesLiableTok: Label 'Taxes Liable', MaxLength = 100;
        EstimatedIncomeTaxTok: Label 'Estimated Income Tax', MaxLength = 100;
        Estimatedreal_estateTax_Real_estatechargeTok: Label 'Estimated real-estate Tax/Real-estate charge ', MaxLength = 100;
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
        TotalEquityTok: Label 'Total, Equity', MaxLength = 100;
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
        SalesDiscountsTok: Label 'Sales Discounts', MaxLength = 100;
        SalesInvoiceRoundingTok: Label 'Sales Invoice Rounding', MaxLength = 100;
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
        CostsofJobsTok: Label 'Costs of Jobs', MaxLength = 100;
        JobCostsTok: Label 'Job Costs', MaxLength = 100;
        JobCostsAppliedTok: Label 'Job Costs, Applied', MaxLength = 100;
        TotalCostsofJobsTok: Label 'Total, Costs of Jobs', MaxLength = 100;
        SubcontractedworkTok: Label 'Subcontracted work', MaxLength = 100;
        ManufVariancesTok: Label 'Manuf. Variances', MaxLength = 100;
        PurchaseVarianceCapTok: Label 'Purchase Variance, Cap.', MaxLength = 100;
        MaterialVarianceTok: Label 'Material Variance', MaxLength = 100;
        CapacityVarianceTok: Label 'Capacity Variance', MaxLength = 100;
        SubcontractedVarianceTok: Label 'Subcontracted Variance', MaxLength = 100;
        CapOverheadVarianceTok: Label 'Cap. Overhead Variance', MaxLength = 100;
        MfgOverheadVarianceTok: Label 'Mfg. Overhead Variance', MaxLength = 100;
        TotalManufVariancesTok: Label 'Total, Manuf. Variances', MaxLength = 100;
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

    procedure InsertMiniAppData()
    begin
        AddBalanceSheetForMini();
        AddIncomeStatementForMini();

        GLAccIndent.Indent();
        AddCategoriesToGLAccountsForMini();
    end;

    local procedure AddBalanceSheetForMini()
    begin
        // Balance sheet 10000-30999
        DemoDataSetup.Get();
        InsertData(BalanceSheet(), BalanceSheetName(), 1, 1, 1, '', 0, '', '', '', '', true);
        InsertData(Assets(), AssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(IntangibleFixedAssets(), IntangibleFixedAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DevelopmentExpenditure(), DevelopmentExpenditureName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TenancySiteLeaseholdandsimilarrights(), TenancySiteLeaseholdandsimilarrightsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Goodwill(), GoodwillName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AdvancedPaymentsforIntangibleFixedAssets(), AdvancedPaymentsforIntangibleFixedAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalIntangibleFixedAssets(), TotalIntangibleFixedAssetsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TangibleFixedAssets(), TangibleFixedAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LandandBuildings(), LandandBuildingsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Building(), BuildingName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CostofImprovementstoLeasedProperty(), CostofImprovementstoLeasedPropertyName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Land(), LandName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalLandandbuilding(), TotalLandandbuildingName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(MachineryandEquipment(), MachineryandEquipmentName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EquipmentsandTools(), EquipmentsandToolsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Computers(), ComputersName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CarsandotherTransportEquipments(), CarsandotherTransportEquipmentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LeasedAssets(), LeasedAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalMachineryandEquipment(), TotalMachineryandEquipmentName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccumulatedDepreciation(), AccumulatedDepreciationName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalTangibleAssets(), TotalTangibleAssetsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(FinancialandFixedAssets(), FinancialandFixedAssetsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Long_termReceivables(), Long_termReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ParticipationinGroupCompanies(), ParticipationinGroupCompaniesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LoanstoPartnersorrelatedParties(), LoanstoPartnersorrelatedPartiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DeferredTaxAssets(), DeferredTaxAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLong_termReceivables(), OtherLong_termReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalFinancialandFixedAssets(), TotalFinancialandFixedAssetsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(InventoriesProductsandworkinProgress(), InventoriesProductsandworkinProgressName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RawMaterials(), RawMaterialsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SuppliesandConsumables(), SuppliesandConsumablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ProductsinProgress(), ProductsinProgressName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(FinishedGoods(), FinishedGoodsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(GoodsforResale(), GoodsforResaleName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AdvancedPaymentsforgoodsandservices(), AdvancedPaymentsforgoodsandservicesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherInventoryItems(), OtherInventoryItemsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WorkinProgress(), WorkinProgressName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPJobSales(), WIPJobSalesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPJobCosts(), WIPJobCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPAccruedCosts(), WIPAccruedCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(WIPInvoicedSales(), WIPInvoicedSalesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalWorkinProgress(), TotalWorkinProgressName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalInventoryProductsandWorkinProgress(), TotalInventoryProductsandWorkinProgressName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Receivables(), ReceivablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsReceivables(), AccountsReceivablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountReceivableDomestic(), AccountReceivableDomesticName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountReceivableForeign(), AccountReceivableForeignName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ContractualReceivables(), ContractualReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ConsignmentReceivables(), ConsignmentReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CreditcardsandVouchersReceivables(), CreditcardsandVouchersReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalAccountReceivables(), TotalAccountReceivablesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherCurrentReceivables(), OtherCurrentReceivablesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentReceivablefromEmployees(), CurrentReceivablefromEmployeesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Accruedincomenotyetinvoiced(), AccruedincomenotyetinvoicedName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ClearingAccountsforTaxesandcharges(), ClearingAccountsforTaxesandchargesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TaxAssets(), TaxAssetsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PurchaseVATReduced(), PurchaseVATReducedName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PurchaseVATNormal(), PurchaseVATNormalName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(MiscVATReceivables(), MiscVATReceivablesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentReceivablesfromgroupcompanies(), CurrentReceivablesfromgroupcompaniesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalOtherCurrentReceivables(), TotalOtherCurrentReceivablesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalReceivables(), TotalReceivablesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PrepaidexpensesandAccruedIncome(), PrepaidexpensesandAccruedIncomeName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PrepaidRent(), PrepaidRentName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PrepaidInterestexpense(), PrepaidInterestexpenseName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedRentalIncome(), AccruedRentalIncomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedInterestIncome(), AccruedInterestIncomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Assetsintheformofprepaidexpenses(), AssetsintheformofprepaidexpensesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Otherprepaidexpensesandaccruedincome(), OtherprepaidexpensesandaccruedincomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalPrepaidexpensesandAccruedIncome(), TotalPrepaidexpensesandAccruedIncomeName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Short_terminvestments(), Short_terminvestmentsName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Bonds(), BondsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Convertibledebtinstruments(), ConvertibledebtinstrumentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Othershort_termInvestments(), Othershort_termInvestmentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Write_downofShort_terminvestments(), Write_downofShort_terminvestmentsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Totalshortterminvestments(), TotalshortterminvestmentsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CashandBank(), CashandBankName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PettyCash(), PettyCashName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BusinessaccountOperatingDomestic(), BusinessaccountOperatingDomesticName(), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData(BusinessaccountOperatingForeign(), BusinessaccountOperatingForeignName(), 0, 1, 0, '', 0, '', '', '', '', false);
        InsertData(Otherbankaccounts(), OtherbankaccountsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CertificateofDeposit(), CertificateofDepositName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCashandBank(), TotalCashandBankName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalAssets(), TotalAssetsName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Liability(), LiabilityName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Long_TermLiabilities(), Long_TermLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BondsandDebentureLoans(), BondsandDebentureLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ConvertiblesLoans(), ConvertiblesLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLong_termLiabilities(), OtherLong_termLiabilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(BankoverdraftFacilities(), BankoverdraftFacilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalLong_termLiabilities(), TotalLong_termLiabilitiesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentLiabilities(), CurrentLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsPayableDomestic(), AccountsPayableDomesticName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccountsPayableForeign(), AccountsPayableForeignName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Advancesfromcustomers(), AdvancesfromcustomersName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ChangeinWorkinProgress(), ChangeinWorkinProgressName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Bankoverdraftshort_term(), Bankoverdraftshort_termName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherLiabilities(), OtherLiabilitiesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DeferredRevenue(), DeferredRevenueName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCurrentLiabilities(), TotalCurrentLiabilitiesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TaxLiabilities(), TaxLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SalesTax_VATLiable(), SalesTax_VATLiableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TaxesLiable(), TaxesLiableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SalesVATReducedPayable(), SalesVATReducedPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(SalesVATNormalPayable(), SalesVATNormalPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(MiscVATPayable(), MiscVATPayableName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EstimatedIncomeTax(), EstimatedIncomeTaxName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Estimatedreal_estateTax_Real_estatecharge(), Estimatedreal_estateTax_Real_estatechargeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EstimatedPayrolltaxonPensionCosts(), EstimatedPayrolltaxonPensionCostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalTaxLiabilities(), TotalTaxLiabilitiesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(PayrollLiabilities(), PayrollLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EmployeesWithholdingTaxes(), EmployeesWithholdingTaxesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(StatutorySocialsecurityContributions(), StatutorySocialsecurityContributionsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ContractualSocialsecurityContributions(), ContractualSocialsecurityContributionsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AttachmentsofEarning(), AttachmentsofEarningName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(HolidayPayfund(), HolidayPayfundName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherSalary_wageDeductions(), OtherSalary_wageDeductionsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalPayrollLiabilities(), TotalPayrollLiabilitiesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherCurrentLiabilities(), OtherCurrentLiabilitiesName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ClearingAccountforFactoringCurrentPortion(), ClearingAccountforFactoringCurrentPortionName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentLiabilitiestoEmployees(), CurrentLiabilitiestoEmployeesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ClearingAccountforthirdparty(), ClearingAccountforthirdpartyName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CurrentLoans(), CurrentLoansName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(LiabilitiesGrantsReceived(), LiabilitiesGrantsReceivedName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalOtherCurrentLiabilities(), TotalOtherCurrentLiabilitiesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedExpensesandDeferredIncome(), AccruedExpensesandDeferredIncomeName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Accruedwages_salaries(), Accruedwages_salariesName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedHolidaypay(), AccruedHolidaypayName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedPensioncosts(), AccruedPensioncostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedInterestExpense(), AccruedInterestExpenseName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DeferredIncome(), DeferredIncomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(AccruedContractualcosts(), AccruedContractualcostsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(OtherAccruedExpensesandDeferredIncome(), OtherAccruedExpensesandDeferredIncomeName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalAccruedExpensesandDeferredIncome(), TotalAccruedExpensesandDeferredIncomeName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalLiabilities(), TotalLiabilitiesName(), 4, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Equity(), EquityName(), 3, 1, 0, '', 0, '', '', '', '', true);
        InsertData(EquityPartner(), EquityPartnerName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(NetResults(), NetResultsName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(RestrictedEquity(), RestrictedEquityName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ShareCapital(), ShareCapitalName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Non_RestrictedEquity(), Non_RestrictedEquityName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(Profitorlossfromthepreviousyear(), ProfitorlossfromthepreviousyearName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(ResultsfortheFinancialyear(), ResultsfortheFinancialyearName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(DistributionstoShareholders(), DistributionstoShareholdersName(), 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(TotalEquity(), TotalEquityName(), 4, 1, 0, '', 0, '', '', '', '', true);
    end;

    local procedure AddIncomeStatementForMini()
    begin
        // Income statement 40000-61999
        DemoDataSetup.Get();
        InsertData(INCOMESTATEMENT(), INCOMESTATEMENTName(), 1, 0, 1, '', 0, '', '', '', '', true);
        InsertData(Income(), IncomeName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesofGoods(), SalesofGoodsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SaleofFinishedGoods(), SaleofFinishedGoodsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(SaleofRawMaterials(), SaleofRawMaterialsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(ResaleofGoods(), ResaleofGoodsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(TotalSalesofGoods(), TotalSalesofGoodsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesofResources(), SalesofResourcesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SaleofResources(), SaleofResourcesName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(SaleofSubcontracting(), SaleofSubcontractingName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(TotalSalesofResources(), TotalSalesofResourcesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(AdditionalRevenue(), AdditionalRevenueName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Incomefromsecurities(), IncomefromsecuritiesName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(ManagementFeeRevenue(), ManagementFeeRevenueName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(InterestIncome(), InterestIncomeName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(CurrencyGains(), CurrencyGainsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(OtherIncidentalRevenue(), OtherIncidentalRevenueName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(TotalAdditionalRevenue(), TotalAdditionalRevenueName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobsandServices(), JobsandServicesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobSales(), JobSalesName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(JobSalesApplied(), JobSalesAppliedName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(SalesofServiceContracts(), SalesofServiceContractsName(), 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '', '', true);
        InsertData(SalesofServiceWork(), SalesofServiceWorkName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(TotalJobsandServices(), TotalJobsandServicesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(RevenueReductions(), RevenueReductionsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SalesDiscounts(), SalesDiscountsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(SalesInvoiceRounding(), SalesInvoiceRoundingName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(SalesReturns(), SalesReturnsName(), 0, 0, 0, '', 2, '', '', '', '', true);
        InsertData(TotalRevenueReductions(), TotalRevenueReductionsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TOTALINCOME(), TOTALINCOMEName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(COSTOFGOODSSOLD(), COSTOFGOODSSOLDName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofGoods(), CostofGoodsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofMaterials(), CostofMaterialsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofMaterialsProjects(), CostofMaterialsProjectsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofGoods(), TotalCostofGoodsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofResourcesandServices(), CostofResourcesandServicesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofLabor(), CostofLaborName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofLaborProjects(), CostofLaborProjectsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofLaborWarranty_Contract(), CostofLaborWarranty_ContractName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostofResources(), TotalCostofResourcesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostsofJobs(), CostsofJobsName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCosts(), JobCostsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(JobCostsApplied(), JobCostsAppliedName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalCostsofJobs(), TotalCostsofJobsName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(Subcontractedwork(), SubcontractedworkName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(ManufVariances(), ManufVariancesName(), 3, 0, 0, '', 0, '', '', '', '', true);
        InsertData(PurchaseVarianceCap(), PurchaseVarianceCapName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(MaterialVariance(), MaterialVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CapacityVariance(), CapacityVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(SubcontractedVariance(), SubcontractedVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CapOverheadVariance(), CapOverheadVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(MfgOverheadVariance(), MfgOverheadVarianceName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalManufVariances(), TotalManufVariancesName(), 4, 0, 0, '', 0, '', '', '', '', true);
        InsertData(CostofVariances(), CostofVariancesName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TOTALCOSTOFGOODSSOLD(), TOTALCOSTOFGOODSSOLDName(), 4, 0, 0, '', 0, '', '', '', '', true);
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
        InsertData(TotalRentalFacilities(), TotalRentalFacilitiesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PropertyExpenses(), PropertyExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(SiteFees_Leases(), SiteFees_LeasesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ElectricityforProperty(), ElectricityforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HeatingforProperty(), HeatingforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(WaterandSewerageforProperty(), WaterandSewerageforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CleaningandWasteforProperty(), CleaningandWasteforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(RepairsandMaintenanceforProperty(), RepairsandMaintenanceforPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(InsurancesProperty(), InsurancesPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherPropertyExpenses(), OtherPropertyExpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalPropertyExpenses(), TotalPropertyExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalFacilityExpenses(), TotalFacilityExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(FixedAssetsLeases(), FixedAssetsLeasesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Hireofmachinery(), HireofmachineryName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Hireofcomputers(), HireofcomputersName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Hireofotherfixedassets(), HireofotherfixedassetsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalFixedAssetLeases(), TotalFixedAssetLeasesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(LogisticsExpenses(), LogisticsExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(VehicleExpenses(), VehicleExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PassengerCarCosts(), PassengerCarCostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TruckCosts(), TruckCostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Othervehicleexpenses(), OthervehicleexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalVehicleExpenses(), TotalVehicleExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(FreightCosts(), FreightCostsName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Freightfeesforgoods(), FreightfeesforgoodsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Customsandforwarding(), CustomsandforwardingName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Freightfeesprojects(), FreightfeesprojectsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalFreightCosts(), TotalFreightCostsName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TravelExpenses(), TravelExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Tickets(), TicketsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Rentalvehicles(), RentalvehiclesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Boardandlodging(), BoardandlodgingName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Othertravelexpenses(), OthertravelexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalTravelExpenses(), TotalTravelExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalLogisticsExpenses(), TotalLogisticsExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
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
        InsertData(TotalAdvertising(), TotalAdvertisingName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherMarketingExpenses(), OtherMarketingExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Catalogspricelists(), CatalogspricelistsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TradePublications(), TradePublicationsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalOtherMarketingExpenses(), TotalOtherMarketingExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(SalesExpenses(), SalesExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CreditCardCharges(), CreditCardChargesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BusinessEntertainingdeductible(), BusinessEntertainingdeductibleName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BusinessEntertainingnondeductible(), BusinessEntertainingnondeductibleName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalSalesExpenses(), TotalSalesExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalMarketingandSales(), TotalMarketingandSalesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OfficeExpenses(), OfficeExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OfficeSupplies(), OfficeSuppliesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PhoneServices(), PhoneServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Dataservices(), DataservicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Postalfees(), PostalfeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Consumable_Expensiblehardware(), Consumable_ExpensiblehardwareName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Softwareandsubscriptionfees(), SoftwareandsubscriptionfeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalOfficeExpenses(), TotalOfficeExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(InsurancesandRisks(), InsurancesandRisksName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CorporateInsurance(), CorporateInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(DamagesPaid(), DamagesPaidName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BadDebtLosses(), BadDebtLossesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Securityservices(), SecurityservicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Otherriskexpenses(), OtherriskexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalInsurancesandRisks(), TotalInsurancesandRisksName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ManagementandAdmin(), ManagementandAdminName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Management(), ManagementName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(RemunerationtoDirectors(), RemunerationtoDirectorsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ManagementFees(), ManagementFeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Annual_interrimReports(), Annual_interrimReportsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Annual_generalmeeting(), Annual_generalmeetingName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(AuditandAuditServices(), AuditandAuditServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TaxadvisoryServices(), TaxadvisoryServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalManagementFees(), TotalManagementFeesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalManagementandAdmin(), TotalManagementandAdminName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(BankingandInterest(), BankingandInterestName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Bankingfees(), BankingfeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(InterestExpenses(), InterestExpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PayableInvoiceRounding(), PayableInvoiceRoundingName(), 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '', '', true);
        InsertData(TotalBankingandInterest(), TotalBankingandInterestName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ExternalServices_Expenses(), ExternalServices_ExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ExternalServices(), ExternalServicesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(AccountingServices(), AccountingServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ITServices(), ITServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(MediaServices(), MediaServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(ConsultingServices(), ConsultingServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(LegalFeesandAttorneyServices(), LegalFeesandAttorneyServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherExternalServices(), OtherExternalServicesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalExternalServices(), TotalExternalServicesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OtherExternalExpenses(), OtherExternalExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(LicenseFees_Royalties(), LicenseFees_RoyaltiesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Trademarks_Patents(), Trademarks_PatentsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(AssociationFees(), AssociationFeesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Miscexternalexpenses(), MiscexternalexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PurchaseDiscounts(), PurchaseDiscountsName(), 0, 0, 0, '', 0, '', '', '', '', true);
        InsertData(TotalOtherExternalExpenses(), TotalOtherExternalExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalExternalServices_Expenses(), TotalExternalServices_ExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Personnel(), PersonnelName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(WagesandSalaries(), WagesandSalariesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Salaries(), SalariesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HourlyWages(), HourlyWagesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(OvertimeWages(), OvertimeWagesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Bonuses(), BonusesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CommissionsPaid(), CommissionsPaidName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(PTOAccrued(), PTOAccruedName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalWagesandSalaries(), TotalWagesandSalariesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Benefits_Pension(), Benefits_PensionName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Benefits(), BenefitsName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TrainingCosts(), TrainingCostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HealthCareContributions(), HealthCareContributionsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Entertainmentofpersonnel(), EntertainmentofpersonnelName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Allowances(), AllowancesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Mandatoryclothingexpenses(), MandatoryclothingexpensesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Othercash_remunerationbenefits(), Othercash_remunerationbenefitsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalBenefits(), TotalBenefitsName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Pension(), PensionName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Pensionfeesandrecurringcosts(), PensionfeesandrecurringcostsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(EmployerContributions(), EmployerContributionsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalPension(), TotalPensionName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalBenefits_Pension(), TotalBenefits_PensionName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(InsurancesPersonnel(), InsurancesPersonnelName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(HealthInsurance(), HealthInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(DentalInsurance(), DentalInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(WorkersCompensation(), WorkersCompensationName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(LifeInsurance(), LifeInsuranceName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalInsurancesPersonnel(), TotalInsurancesPersonnelName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalPersonnel(), TotalPersonnelName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(Depreciation(), DepreciationName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(DepreciationLandandProperty(), DepreciationLandandPropertyName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(DepreciationFixedAssets(), DepreciationFixedAssetsName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalDepreciation(), TotalDepreciationName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(MiscExpenses(), MiscExpensesName(), 3, 0, 0, '', 1, '', '', '', '', true);
        InsertData(CurrencyLosses(), CurrencyLossesName(), 0, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TotalMiscExpenses(), TotalMiscExpensesName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(TOTALEXPENSES(), TOTALEXPENSESName(), 4, 0, 0, '', 1, '', '', '', '', true);
        InsertData(NETINCOME(), NETINCOMEName(), 2, 0, 0, '', 0, '', '', '', '', true);
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
            '992910', '992920', '992930', '992940', '995310', PettyCash():
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
                begin
                    UpdateGLAccounts(GLAccountCategory, '0070', '0499');
                    UpdateGLAccounts(GLAccountCategory, '2910', '2390');
                    UpdateGLAccounts(GLAccountCategory, '3001', '3599');
                    UpdateGLAccounts(GLAccountCategory, '3601', '3689');
                    UpdateGLAccounts(GLAccountCategory, '3691', '3899');
                end;
            GLAccountCategory."Account Category"::Liabilities:
                begin
                    UpdateGLAccounts(GLAccountCategory, '0800', '0999');
                    UpdateGLAccounts(GLAccountCategory, '1500', '2999');
                end;
            GLAccountCategory."Account Category"::Equity:
                UpdateGLAccounts(GLAccountCategory, '0500', '0599');
            GLAccountCategory."Account Category"::Income:
                UpdateGLAccounts(GLAccountCategory, '8000', '9409');
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                UpdateGLAccounts(GLAccountCategory, '6000', '7999');
            GLAccountCategory."Account Category"::Expense:
                begin
                    UpdateGLAccounts(GLAccountCategory, '4000', '5799');
                    UpdateGLAccounts(GLAccountCategory, '9410', '9999');
                end;
        end;
    end;

    procedure AssignSubcategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCash(): // 3
                UpdateGLAccounts(GLAccountCategory, '1000', '1199');
            GLAccountCategoryMgt.GetAR(): // 4
                UpdateGLAccounts(GLAccountCategory, '1300', '1499 ');
            GLAccountCategoryMgt.GetInventory(): // 6
                begin
                    UpdateGLAccounts(GLAccountCategory, '3001', '3599');
                    UpdateGLAccounts(GLAccountCategory, '3601', '3689');
                    UpdateGLAccounts(GLAccountCategory, '3691', '3899');
                end;
            GLAccountCategoryMgt.GetFixedAssets(): // 7
                UpdateGLAccounts(GLAccountCategory, '0070', '0499');
            GLAccountCategoryMgt.GetCurrentLiabilities(): //  11
                UpdateGLAccounts(GLAccountCategory, '1500', '2999');
            GLAccountCategoryMgt.GetLongTermLiabilities(): //  13
                UpdateGLAccounts(GLAccountCategory, '0800', '0999');
            GLAccountCategoryMgt.GetCommonStock(): //  15
                UpdateGLAccounts(GLAccountCategory, '0500', '0599');
            GLAccountCategoryMgt.GetIncomeProdSales(): // 20
                UpdateGLAccounts(GLAccountCategory, '8000', '8799');
            GLAccountCategoryMgt.GetCOGSMaterials(): // 28
                begin
                    UpdateGLAccounts(GLAccountCategory, '6000', '6099');
                    UpdateGLAccounts(GLAccountCategory, '7000', '7999');
                end;
            GLAccountCategoryMgt.GetJobsCost(): // 30
                begin
                    UpdateGLAccounts(GLAccountCategory, '6181', '6959');
                    UpdateGLAccounts(GLAccountCategory, '7181', '6959');
                end;
            GLAccountCategoryMgt.GetRentExpense(): // 32
                UpdateGLAccounts(GLAccountCategory, '4110', '4110');
            GLAccountCategoryMgt.GetAdvertisingExpense(): // 33
                UpdateGLAccounts(GLAccountCategory, '4600', '4699');
            GLAccountCategoryMgt.GetInterestExpense(): // 34
                UpdateGLAccounts(GLAccountCategory, '9410', '9499');
            GLAccountCategoryMgt.GetSalariesExpense(): // 39
                UpdateGLAccounts(GLAccountCategory, '4000', '4099');
            GLAccountCategoryMgt.GetRepairsExpense(): // 40
                UpdateGLAccounts(GLAccountCategory, '4210', '4210');
            GLAccountCategoryMgt.GetUtilitiesExpense(): // 41
                begin
                    UpdateGLAccounts(GLAccountCategory, '4100', '4100');
                    UpdateGLAccounts(GLAccountCategory, '4111', '4200');
                    UpdateGLAccounts(GLAccountCategory, '4213', '4299');
                end;
            GLAccountCategoryMgt.GetOtherIncomeExpense(): // 42
                begin
                    UpdateGLAccounts(GLAccountCategory, '4400', '4499');
                    UpdateGLAccounts(GLAccountCategory, '4700', '5799');
                    UpdateGLAccounts(GLAccountCategory, '9600', '9999');
                end;
            GLAccountCategoryMgt.GetVehicleExpenses(): // 45
                UpdateGLAccounts(GLAccountCategory, '4500', '4599');
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
                UpdateGLAccounts(GLAccountCategory, '0001', '0999');
            GLAccountCategory."Account Category"::Liabilities:
                UpdateGLAccounts(GLAccountCategory, '1000', '1999');
            GLAccountCategory."Account Category"::Equity:
                UpdateGLAccounts(GLAccountCategory, '2000', '2999');
            GLAccountCategory."Account Category"::Income:
                UpdateGLAccounts(GLAccountCategory, '6000', '6999');
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                UpdateGLAccounts(GLAccountCategory, '5000', '5999');
            GLAccountCategory."Account Category"::Expense:
                UpdateGLAccounts(GLAccountCategory, '3000', '4999');
        end;
    end;

    local procedure AssignSubcategoryToChartOfAccountsForMini(GLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetCash():
                UpdateGLAccounts(GLAccountCategory, '0910', '0950');
            GLAccountCategoryMgt.GetPrepaidExpenses():
                UpdateGLAccounts(GLAccountCategory, '0801', '0806');
            GLAccountCategoryMgt.GetInventory():
                UpdateGLAccounts(GLAccountCategory, '0500', '0599');
            GLAccountCategoryMgt.GetEquipment():
                UpdateGLAccounts(GLAccountCategory, '0210', '0299');
            GLAccountCategoryMgt.GetAccumDeprec():
                UpdateGLAccounts(GLAccountCategory, '0300', '0300');
            GLAccountCategoryMgt.GetCurrentLiabilities():
                UpdateGLAccounts(GLAccountCategory, '1210', '1550');
            GLAccountCategoryMgt.GetPayrollLiabilities():
                UpdateGLAccounts(GLAccountCategory, '1410', '1460');
            GLAccountCategoryMgt.GetDistrToShareholders():
                UpdateGLAccounts(GLAccountCategory, '2800', '2800');
            GLAccountCategoryMgt.GetIncomeService():
                UpdateGLAccounts(GLAccountCategory, '6200', '6299');
            GLAccountCategoryMgt.GetIncomeProdSales():
                UpdateGLAccounts(GLAccountCategory, '6100', '6199');
            GLAccountCategoryMgt.GetCOGSLabor():
                UpdateGLAccounts(GLAccountCategory, '5200', '5299');
            GLAccountCategoryMgt.GetCOGSMaterials():
                UpdateGLAccounts(GLAccountCategory, '5100', '5199');
            GLAccountCategoryMgt.GetRentExpense():
                UpdateGLAccounts(GLAccountCategory, '3110', '3110');
            GLAccountCategoryMgt.GetAdvertisingExpense():
                UpdateGLAccounts(GLAccountCategory, '3501', '3559');
            GLAccountCategoryMgt.GetInterestExpense():
                UpdateGLAccounts(GLAccountCategory, '6330', '6330');
            GLAccountCategoryMgt.GetFeesExpense():
                UpdateGLAccounts(GLAccountCategory, '3910', '3920');
            GLAccountCategoryMgt.GetBadDebtExpense():
                UpdateGLAccounts(GLAccountCategory, '3730', '3730');
            GLAccountCategoryMgt.GetInsuranceExpense():
                UpdateGLAccounts(GLAccountCategory, '4500', '4599');
            GLAccountCategoryMgt.GetBenefitsExpense():
                UpdateGLAccounts(GLAccountCategory, '4400', '4499');
            GLAccountCategoryMgt.GetRepairsExpense():
                UpdateGLAccounts(GLAccountCategory, '3160', '3160');
            GLAccountCategoryMgt.GetUtilitiesExpense():
                UpdateGLAccounts(GLAccountCategory, '3120', '3150');
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

    internal procedure BalanceSheet(): Code[20]
    begin
        exit('0000');
    end;

    internal procedure BalanceSheetName(): Text[100]
    begin
        exit(BalanceSheetTok);
    end;


    internal procedure Assets(): Code[20]
    begin
        exit('0001');
    end;

    internal procedure AssetsName(): Text[100]
    begin
        exit(AssetsTok);
    end;


    internal procedure IntangibleFixedAssets(): Code[20]
    begin
        exit('0002');
    end;

    internal procedure IntangibleFixedAssetsName(): Text[100]
    begin
        exit(IntangibleFixedAssetsTok);
    end;


    internal procedure DevelopmentExpenditure(): Code[20]
    begin
        exit('0010');
    end;

    internal procedure DevelopmentExpenditureName(): Text[100]
    begin
        exit(DevelopmentExpenditureTok);
    end;


    internal procedure TenancySiteLeaseholdandsimilarrights(): Code[20]
    begin
        exit('0020');
    end;

    internal procedure TenancySiteLeaseholdandsimilarrightsName(): Text[100]
    begin
        exit(TenancySiteLeaseholdandsimilarrightsTok);
    end;


    internal procedure Goodwill(): Code[20]
    begin
        exit('0030');
    end;

    internal procedure GoodwillName(): Text[100]
    begin
        exit(GoodwillTok);
    end;


    internal procedure AdvancedPaymentsforIntangibleFixedAssets(): Code[20]
    begin
        exit('0040');
    end;

    internal procedure AdvancedPaymentsforIntangibleFixedAssetsName(): Text[100]
    begin
        exit(AdvancedPaymentsforIntangibleFixedAssetsTok);
    end;


    internal procedure TotalIntangibleFixedAssets(): Code[20]
    begin
        exit('0049');
    end;

    internal procedure TotalIntangibleFixedAssetsName(): Text[100]
    begin
        exit(TotalIntangibleFixedAssetsTok);
    end;


    internal procedure TangibleFixedAssets(): Code[20]
    begin
        exit('0100');
    end;

    internal procedure TangibleFixedAssetsName(): Text[100]
    begin
        exit(TangibleFixedAssetsTok);
    end;


    internal procedure LandandBuildings(): Code[20]
    begin
        exit('0101');
    end;

    internal procedure LandandBuildingsName(): Text[100]
    begin
        exit(LandandBuildingsTok);
    end;


    internal procedure Building(): Code[20]
    begin
        exit('0110');
    end;

    internal procedure BuildingName(): Text[100]
    begin
        exit(BuildingTok);
    end;


    internal procedure CostofImprovementstoLeasedProperty(): Code[20]
    begin
        exit('0120');
    end;

    internal procedure CostofImprovementstoLeasedPropertyName(): Text[100]
    begin
        exit(CostofImprovementstoLeasedPropertyTok);
    end;


    internal procedure Land(): Code[20]
    begin
        exit('0130');
    end;

    internal procedure LandName(): Text[100]
    begin
        exit(LandTok);
    end;


    internal procedure TotalLandandbuilding(): Code[20]
    begin
        exit('0199');
    end;

    internal procedure TotalLandandbuildingName(): Text[100]
    begin
        exit(TotalLandandbuildingTok);
    end;


    internal procedure MachineryandEquipment(): Code[20]
    begin
        exit('0200');
    end;

    internal procedure MachineryandEquipmentName(): Text[100]
    begin
        exit(MachineryandEquipmentTok);
    end;


    internal procedure EquipmentsandTools(): Code[20]
    begin
        exit('0210');
    end;

    internal procedure EquipmentsandToolsName(): Text[100]
    begin
        exit(EquipmentsandToolsTok);
    end;


    internal procedure Computers(): Code[20]
    begin
        exit('0220');
    end;

    internal procedure ComputersName(): Text[100]
    begin
        exit(ComputersTok);
    end;


    internal procedure CarsandotherTransportEquipments(): Code[20]
    begin
        exit('0230');
    end;

    internal procedure CarsandotherTransportEquipmentsName(): Text[100]
    begin
        exit(CarsandotherTransportEquipmentsTok);
    end;


    internal procedure LeasedAssets(): Code[20]
    begin
        exit('0240');
    end;

    internal procedure LeasedAssetsName(): Text[100]
    begin
        exit(LeasedAssetsTok);
    end;


    internal procedure TotalMachineryandEquipment(): Code[20]
    begin
        exit('0299');
    end;

    internal procedure TotalMachineryandEquipmentName(): Text[100]
    begin
        exit(TotalMachineryandEquipmentTok);
    end;


    internal procedure AccumulatedDepreciation(): Code[20]
    begin
        exit('0300');
    end;

    internal procedure AccumulatedDepreciationName(): Text[100]
    begin
        exit(AccumulatedDepreciationTok);
    end;


    internal procedure TotalTangibleAssets(): Code[20]
    begin
        exit('0399');
    end;

    internal procedure TotalTangibleAssetsName(): Text[100]
    begin
        exit(TotalTangibleAssetsTok);
    end;


    internal procedure FinancialandFixedAssets(): Code[20]
    begin
        exit('0400');
    end;

    internal procedure FinancialandFixedAssetsName(): Text[100]
    begin
        exit(FinancialandFixedAssetsTok);
    end;


    internal procedure Long_termReceivables(): Code[20]
    begin
        exit('0401');
    end;

    internal procedure Long_termReceivablesName(): Text[100]
    begin
        exit(Long_termReceivablesTok);
    end;


    internal procedure ParticipationinGroupCompanies(): Code[20]
    begin
        exit('0402');
    end;

    internal procedure ParticipationinGroupCompaniesName(): Text[100]
    begin
        exit(ParticipationinGroupCompaniesTok);
    end;


    internal procedure LoanstoPartnersorrelatedParties(): Code[20]
    begin
        exit('0403');
    end;

    internal procedure LoanstoPartnersorrelatedPartiesName(): Text[100]
    begin
        exit(LoanstoPartnersorrelatedPartiesTok);
    end;


    internal procedure DeferredTaxAssets(): Code[20]
    begin
        exit('0404');
    end;

    internal procedure DeferredTaxAssetsName(): Text[100]
    begin
        exit(DeferredTaxAssetsTok);
    end;


    internal procedure OtherLong_termReceivables(): Code[20]
    begin
        exit('0405');
    end;

    internal procedure OtherLong_termReceivablesName(): Text[100]
    begin
        exit(OtherLong_termReceivablesTok);
    end;


    internal procedure TotalFinancialandFixedAssets(): Code[20]
    begin
        exit('0499');
    end;

    internal procedure TotalFinancialandFixedAssetsName(): Text[100]
    begin
        exit(TotalFinancialandFixedAssetsTok);
    end;


    internal procedure InventoriesProductsandworkinProgress(): Code[20]
    begin
        exit('0500');
    end;

    internal procedure InventoriesProductsandworkinProgressName(): Text[100]
    begin
        exit(InventoriesProductsandworkinProgressTok);
    end;


    internal procedure RawMaterials(): Code[20]
    begin
        exit('0501');
    end;

    internal procedure RawMaterialsName(): Text[100]
    begin
        exit(RawMaterialsTok);
    end;


    internal procedure SuppliesandConsumables(): Code[20]
    begin
        exit('0502');
    end;

    internal procedure SuppliesandConsumablesName(): Text[100]
    begin
        exit(SuppliesandConsumablesTok);
    end;


    internal procedure ProductsinProgress(): Code[20]
    begin
        exit('0503');
    end;

    internal procedure ProductsinProgressName(): Text[100]
    begin
        exit(ProductsinProgressTok);
    end;


    internal procedure FinishedGoods(): Code[20]
    begin
        exit('0504');
    end;

    internal procedure FinishedGoodsName(): Text[100]
    begin
        exit(FinishedGoodsTok);
    end;


    internal procedure GoodsforResale(): Code[20]
    begin
        exit('0505');
    end;

    internal procedure GoodsforResaleName(): Text[100]
    begin
        exit(GoodsforResaleTok);
    end;


    internal procedure AdvancedPaymentsforgoodsandservices(): Code[20]
    begin
        exit('0506');
    end;

    internal procedure AdvancedPaymentsforgoodsandservicesName(): Text[100]
    begin
        exit(AdvancedPaymentsforgoodsandservicesTok);
    end;


    internal procedure OtherInventoryItems(): Code[20]
    begin
        exit('0507');
    end;

    internal procedure OtherInventoryItemsName(): Text[100]
    begin
        exit(OtherInventoryItemsTok);
    end;


    internal procedure WorkinProgress(): Code[20]
    begin
        exit('0550');
    end;

    internal procedure WorkinProgressName(): Text[100]
    begin
        exit(WorkinProgressTok);
    end;


    internal procedure WIPJobSales(): Code[20]
    begin
        exit('0551');
    end;

    internal procedure WIPJobSalesName(): Text[100]
    begin
        exit(WIPJobSalesTok);
    end;


    internal procedure WIPJobCosts(): Code[20]
    begin
        exit('0552');
    end;

    internal procedure WIPJobCostsName(): Text[100]
    begin
        exit(WIPJobCostsTok);
    end;


    internal procedure WIPAccruedCosts(): Code[20]
    begin
        exit('0553');
    end;

    internal procedure WIPAccruedCostsName(): Text[100]
    begin
        exit(WIPAccruedCostsTok);
    end;


    internal procedure WIPInvoicedSales(): Code[20]
    begin
        exit('0554');
    end;

    internal procedure WIPInvoicedSalesName(): Text[100]
    begin
        exit(WIPInvoicedSalesTok);
    end;


    internal procedure TotalWorkinProgress(): Code[20]
    begin
        exit('0598');
    end;

    internal procedure TotalWorkinProgressName(): Text[100]
    begin
        exit(TotalWorkinProgressTok);
    end;


    internal procedure TotalInventoryProductsandWorkinProgress(): Code[20]
    begin
        exit('0599');
    end;

    internal procedure TotalInventoryProductsandWorkinProgressName(): Text[100]
    begin
        exit(TotalInventoryProductsandWorkinProgressTok);
    end;


    internal procedure Receivables(): Code[20]
    begin
        exit('0600');
    end;

    internal procedure ReceivablesName(): Text[100]
    begin
        exit(ReceivablesTok);
    end;


    internal procedure AccountsReceivables(): Code[20]
    begin
        exit('0601');
    end;

    internal procedure AccountsReceivablesName(): Text[100]
    begin
        exit(AccountsReceivablesTok);
    end;


    internal procedure AccountReceivableDomestic(): Code[20]
    begin
        exit('0610');
    end;

    internal procedure AccountReceivableDomesticName(): Text[100]
    begin
        exit(AccountReceivableDomesticTok);
    end;


    internal procedure AccountReceivableForeign(): Code[20]
    begin
        exit('0620');
    end;

    internal procedure AccountReceivableForeignName(): Text[100]
    begin
        exit(AccountReceivableForeignTok);
    end;


    internal procedure ContractualReceivables(): Code[20]
    begin
        exit('0630');
    end;

    internal procedure ContractualReceivablesName(): Text[100]
    begin
        exit(ContractualReceivablesTok);
    end;


    internal procedure ConsignmentReceivables(): Code[20]
    begin
        exit('0640');
    end;

    internal procedure ConsignmentReceivablesName(): Text[100]
    begin
        exit(ConsignmentReceivablesTok);
    end;


    internal procedure CreditcardsandVouchersReceivables(): Code[20]
    begin
        exit('0650');
    end;

    internal procedure CreditcardsandVouchersReceivablesName(): Text[100]
    begin
        exit(CreditcardsandVouchersReceivablesTok);
    end;


    internal procedure TotalAccountReceivables(): Code[20]
    begin
        exit('0699');
    end;

    internal procedure TotalAccountReceivablesName(): Text[100]
    begin
        exit(TotalAccountReceivablesTok);
    end;


    internal procedure OtherCurrentReceivables(): Code[20]
    begin
        exit('0700');
    end;

    internal procedure OtherCurrentReceivablesName(): Text[100]
    begin
        exit(OtherCurrentReceivablesTok);
    end;


    internal procedure CurrentReceivablefromEmployees(): Code[20]
    begin
        exit('0710');
    end;

    internal procedure CurrentReceivablefromEmployeesName(): Text[100]
    begin
        exit(CurrentReceivablefromEmployeesTok);
    end;


    internal procedure Accruedincomenotyetinvoiced(): Code[20]
    begin
        exit('0720');
    end;

    internal procedure AccruedincomenotyetinvoicedName(): Text[100]
    begin
        exit(AccruedincomenotyetinvoicedTok);
    end;


    internal procedure ClearingAccountsforTaxesandcharges(): Code[20]
    begin
        exit('0730');
    end;

    internal procedure ClearingAccountsforTaxesandchargesName(): Text[100]
    begin
        exit(ClearingAccountsforTaxesandchargesTok);
    end;


    internal procedure TaxAssets(): Code[20]
    begin
        exit('0740');
    end;

    internal procedure TaxAssetsName(): Text[100]
    begin
        exit(TaxAssetsTok);
    end;


    internal procedure PurchaseVATReduced(): Code[20]
    begin
        exit('0750');
    end;

    internal procedure PurchaseVATReducedName(): Text[100]
    begin
        exit(PurchaseVATReducedTok);
    end;


    internal procedure PurchaseVATNormal(): Code[20]
    begin
        exit('0760');
    end;

    internal procedure PurchaseVATNormalName(): Text[100]
    begin
        exit(PurchaseVATNormalTok);
    end;


    internal procedure MiscVATReceivables(): Code[20]
    begin
        exit('0770');
    end;

    internal procedure MiscVATReceivablesName(): Text[100]
    begin
        exit(MiscVATReceivablesTok);
    end;


    internal procedure CurrentReceivablesfromgroupcompanies(): Code[20]
    begin
        exit('0780');
    end;

    internal procedure CurrentReceivablesfromgroupcompaniesName(): Text[100]
    begin
        exit(CurrentReceivablesfromgroupcompaniesTok);
    end;


    internal procedure TotalOtherCurrentReceivables(): Code[20]
    begin
        exit('0798');
    end;

    internal procedure TotalOtherCurrentReceivablesName(): Text[100]
    begin
        exit(TotalOtherCurrentReceivablesTok);
    end;


    internal procedure TotalReceivables(): Code[20]
    begin
        exit('0799');
    end;

    internal procedure TotalReceivablesName(): Text[100]
    begin
        exit(TotalReceivablesTok);
    end;


    internal procedure PrepaidexpensesandAccruedIncome(): Code[20]
    begin
        exit('0800');
    end;

    internal procedure PrepaidexpensesandAccruedIncomeName(): Text[100]
    begin
        exit(PrepaidexpensesandAccruedIncomeTok);
    end;


    internal procedure PrepaidRent(): Code[20]
    begin
        exit('0801');
    end;

    internal procedure PrepaidRentName(): Text[100]
    begin
        exit(PrepaidRentTok);
    end;


    internal procedure PrepaidInterestexpense(): Code[20]
    begin
        exit('0802');
    end;

    internal procedure PrepaidInterestexpenseName(): Text[100]
    begin
        exit(PrepaidInterestexpenseTok);
    end;


    internal procedure AccruedRentalIncome(): Code[20]
    begin
        exit('0803');
    end;

    internal procedure AccruedRentalIncomeName(): Text[100]
    begin
        exit(AccruedRentalIncomeTok);
    end;


    internal procedure AccruedInterestIncome(): Code[20]
    begin
        exit('0804');
    end;

    internal procedure AccruedInterestIncomeName(): Text[100]
    begin
        exit(AccruedInterestIncomeTok);
    end;


    internal procedure Assetsintheformofprepaidexpenses(): Code[20]
    begin
        exit('0805');
    end;

    internal procedure AssetsintheformofprepaidexpensesName(): Text[100]
    begin
        exit(AssetsintheformofprepaidexpensesTok);
    end;


    internal procedure Otherprepaidexpensesandaccruedincome(): Code[20]
    begin
        exit('0806');
    end;

    internal procedure OtherprepaidexpensesandaccruedincomeName(): Text[100]
    begin
        exit(OtherprepaidexpensesandaccruedincomeTok);
    end;


    internal procedure TotalPrepaidexpensesandAccruedIncome(): Code[20]
    begin
        exit('0849');
    end;

    internal procedure TotalPrepaidexpensesandAccruedIncomeName(): Text[100]
    begin
        exit(TotalPrepaidexpensesandAccruedIncomeTok);
    end;


    internal procedure Short_terminvestments(): Code[20]
    begin
        exit('0850');
    end;

    internal procedure Short_terminvestmentsName(): Text[100]
    begin
        exit(Short_terminvestmentsTok);
    end;


    internal procedure Bonds(): Code[20]
    begin
        exit('0851');
    end;

    internal procedure BondsName(): Text[100]
    begin
        exit(BondsTok);
    end;


    internal procedure Convertibledebtinstruments(): Code[20]
    begin
        exit('0852');
    end;

    internal procedure ConvertibledebtinstrumentsName(): Text[100]
    begin
        exit(ConvertibledebtinstrumentsTok);
    end;


    internal procedure Othershort_termInvestments(): Code[20]
    begin
        exit('0853');
    end;

    internal procedure Othershort_termInvestmentsName(): Text[100]
    begin
        exit(Othershort_termInvestmentsTok);
    end;


    internal procedure Write_downofShort_terminvestments(): Code[20]
    begin
        exit('0854');
    end;

    internal procedure Write_downofShort_terminvestmentsName(): Text[100]
    begin
        exit(Write_downofShort_terminvestmentsTok);
    end;


    internal procedure Totalshortterminvestments(): Code[20]
    begin
        exit('0899');
    end;

    internal procedure TotalshortterminvestmentsName(): Text[100]
    begin
        exit(TotalshortterminvestmentsTok);
    end;


    internal procedure CashandBank(): Code[20]
    begin
        exit('0900');
    end;

    internal procedure CashandBankName(): Text[100]
    begin
        exit(CashandBankTok);
    end;


    internal procedure PettyCash(): Code[20]
    begin
        exit('0910');
    end;

    internal procedure PettyCashName(): Text[100]
    begin
        exit(PettyCashTok);
    end;


    internal procedure BusinessaccountOperatingDomestic(): Code[20]
    begin
        exit('0920');
    end;

    internal procedure BusinessaccountOperatingDomesticName(): Text[100]
    begin
        exit(BusinessaccountOperatingDomesticTok);
    end;


    internal procedure BusinessaccountOperatingForeign(): Code[20]
    begin
        exit('0930');
    end;

    internal procedure BusinessaccountOperatingForeignName(): Text[100]
    begin
        exit(BusinessaccountOperatingForeignTok);
    end;


    internal procedure Otherbankaccounts(): Code[20]
    begin
        exit('0940');
    end;

    internal procedure OtherbankaccountsName(): Text[100]
    begin
        exit(OtherbankaccountsTok);
    end;


    internal procedure CertificateofDeposit(): Code[20]
    begin
        exit('0950');
    end;

    internal procedure CertificateofDepositName(): Text[100]
    begin
        exit(CertificateofDepositTok);
    end;


    internal procedure TotalCashandBank(): Code[20]
    begin
        exit('0998');
    end;

    internal procedure TotalCashandBankName(): Text[100]
    begin
        exit(TotalCashandBankTok);
    end;


    internal procedure TotalAssets(): Code[20]
    begin
        exit('0999');
    end;

    internal procedure TotalAssetsName(): Text[100]
    begin
        exit(TotalAssetsTok);
    end;


    internal procedure Liability(): Code[20]
    begin
        exit('1000');
    end;

    internal procedure LiabilityName(): Text[100]
    begin
        exit(LiabilityTok);
    end;


    internal procedure Long_TermLiabilities(): Code[20]
    begin
        exit('1001');
    end;

    internal procedure Long_TermLiabilitiesName(): Text[100]
    begin
        exit(Long_TermLiabilitiesTok);
    end;


    internal procedure BondsandDebentureLoans(): Code[20]
    begin
        exit('1110');
    end;

    internal procedure BondsandDebentureLoansName(): Text[100]
    begin
        exit(BondsandDebentureLoansTok);
    end;


    internal procedure ConvertiblesLoans(): Code[20]
    begin
        exit('1120');
    end;

    internal procedure ConvertiblesLoansName(): Text[100]
    begin
        exit(ConvertiblesLoansTok);
    end;


    internal procedure OtherLong_termLiabilities(): Code[20]
    begin
        exit('1130');
    end;

    internal procedure OtherLong_termLiabilitiesName(): Text[100]
    begin
        exit(OtherLong_termLiabilitiesTok);
    end;


    internal procedure BankoverdraftFacilities(): Code[20]
    begin
        exit('1140');
    end;

    internal procedure BankoverdraftFacilitiesName(): Text[100]
    begin
        exit(BankoverdraftFacilitiesTok);
    end;


    internal procedure TotalLong_termLiabilities(): Code[20]
    begin
        exit('1199');
    end;

    internal procedure TotalLong_termLiabilitiesName(): Text[100]
    begin
        exit(TotalLong_termLiabilitiesTok);
    end;


    internal procedure CurrentLiabilities(): Code[20]
    begin
        exit('1200');
    end;

    internal procedure CurrentLiabilitiesName(): Text[100]
    begin
        exit(CurrentLiabilitiesTok);
    end;


    internal procedure AccountsPayableDomestic(): Code[20]
    begin
        exit('1210');
    end;

    internal procedure AccountsPayableDomesticName(): Text[100]
    begin
        exit(AccountsPayableDomesticTok);
    end;


    internal procedure AccountsPayableForeign(): Code[20]
    begin
        exit('1220');
    end;

    internal procedure AccountsPayableForeignName(): Text[100]
    begin
        exit(AccountsPayableForeignTok);
    end;


    internal procedure Advancesfromcustomers(): Code[20]
    begin
        exit('1230');
    end;

    internal procedure AdvancesfromcustomersName(): Text[100]
    begin
        exit(AdvancesfromcustomersTok);
    end;


    internal procedure ChangeinWorkinProgress(): Code[20]
    begin
        exit('1240');
    end;

    internal procedure ChangeinWorkinProgressName(): Text[100]
    begin
        exit(ChangeinWorkinProgressTok);
    end;


    internal procedure Bankoverdraftshort_term(): Code[20]
    begin
        exit('1250');
    end;

    internal procedure Bankoverdraftshort_termName(): Text[100]
    begin
        exit(Bankoverdraftshort_termTok);
    end;


    internal procedure OtherLiabilities(): Code[20]
    begin
        exit('1270');
    end;

    internal procedure OtherLiabilitiesName(): Text[100]
    begin
        exit(OtherLiabilitiesTok);
    end;


    internal procedure DeferredRevenue(): Code[20]
    begin
        exit('1260');
    end;

    internal procedure DeferredRevenueName(): Text[100]
    begin
        exit(DeferredRevenueTok);
    end;


    internal procedure TotalCurrentLiabilities(): Code[20]
    begin
        exit('1299');
    end;

    internal procedure TotalCurrentLiabilitiesName(): Text[100]
    begin
        exit(TotalCurrentLiabilitiesTok);
    end;


    internal procedure TaxLiabilities(): Code[20]
    begin
        exit('1300');
    end;

    internal procedure TaxLiabilitiesName(): Text[100]
    begin
        exit(TaxLiabilitiesTok);
    end;


    internal procedure SalesTax_VATLiable(): Code[20]
    begin
        exit('1310');
    end;

    internal procedure SalesTax_VATLiableName(): Text[100]
    begin
        exit(SalesTax_VATLiableTok);
    end;


    internal procedure TaxesLiable(): Code[20]
    begin
        exit('1320');
    end;

    internal procedure TaxesLiableName(): Text[100]
    begin
        exit(TaxesLiableTok);
    end;

    internal procedure SalesVATReducedPayable(): Code[20]
    begin
        exit('1330');
    end;

    internal procedure SalesVATReducedPayableName(): Text[100]
    begin
        exit(SalesVATReducedTok);
    end;


    internal procedure SalesVATNormalPayable(): Code[20]
    begin
        exit('1340');
    end;

    internal procedure SalesVATNormalPayableName(): Text[100]
    begin
        exit(SalesVATNormalTok);
    end;


    internal procedure MiscVATPayable(): Code[20]
    begin
        exit('1350');
    end;

    internal procedure MiscVATPayableName(): Text[100]
    begin
        exit(MiscVATPayablesTok);
    end;

    internal procedure EstimatedIncomeTax(): Code[20]
    begin
        exit('1360');
    end;

    internal procedure EstimatedIncomeTaxName(): Text[100]
    begin
        exit(EstimatedIncomeTaxTok);
    end;


    internal procedure Estimatedreal_estateTax_Real_estatecharge(): Code[20]
    begin
        exit('1370');
    end;

    internal procedure Estimatedreal_estateTax_Real_estatechargeName(): Text[100]
    begin
        exit(Estimatedreal_estateTax_Real_estatechargeTok);
    end;


    internal procedure EstimatedPayrolltaxonPensionCosts(): Code[20]
    begin
        exit('1380');
    end;

    internal procedure EstimatedPayrolltaxonPensionCostsName(): Text[100]
    begin
        exit(EstimatedPayrolltaxonPensionCostsTok);
    end;


    internal procedure TotalTaxLiabilities(): Code[20]
    begin
        exit('1399');
    end;

    internal procedure TotalTaxLiabilitiesName(): Text[100]
    begin
        exit(TotalTaxLiabilitiesTok);
    end;


    internal procedure PayrollLiabilities(): Code[20]
    begin
        exit('1400');
    end;

    internal procedure PayrollLiabilitiesName(): Text[100]
    begin
        exit(PayrollLiabilitiesTok);
    end;


    internal procedure EmployeesWithholdingTaxes(): Code[20]
    begin
        exit('1410');
    end;

    internal procedure EmployeesWithholdingTaxesName(): Text[100]
    begin
        exit(EmployeesWithholdingTaxesTok);
    end;


    internal procedure StatutorySocialsecurityContributions(): Code[20]
    begin
        exit('1420');
    end;

    internal procedure StatutorySocialsecurityContributionsName(): Text[100]
    begin
        exit(StatutorySocialsecurityContributionsTok);
    end;


    internal procedure ContractualSocialsecurityContributions(): Code[20]
    begin
        exit('1430');
    end;

    internal procedure ContractualSocialsecurityContributionsName(): Text[100]
    begin
        exit(ContractualSocialsecurityContributionsTok);
    end;


    internal procedure AttachmentsofEarning(): Code[20]
    begin
        exit('1440');
    end;

    internal procedure AttachmentsofEarningName(): Text[100]
    begin
        exit(AttachmentsofEarningTok);
    end;


    internal procedure HolidayPayfund(): Code[20]
    begin
        exit('1450');
    end;

    internal procedure HolidayPayfundName(): Text[100]
    begin
        exit(HolidayPayfundTok);
    end;


    internal procedure OtherSalary_wageDeductions(): Code[20]
    begin
        exit('1460');
    end;

    internal procedure OtherSalary_wageDeductionsName(): Text[100]
    begin
        exit(OtherSalary_wageDeductionsTok);
    end;


    internal procedure TotalPayrollLiabilities(): Code[20]
    begin
        exit('1499');
    end;

    internal procedure TotalPayrollLiabilitiesName(): Text[100]
    begin
        exit(TotalPayrollLiabilitiesTok);
    end;


    internal procedure OtherCurrentLiabilities(): Code[20]
    begin
        exit('1500');
    end;

    internal procedure OtherCurrentLiabilitiesName(): Text[100]
    begin
        exit(OtherCurrentLiabilitiesTok);
    end;


    internal procedure ClearingAccountforFactoringCurrentPortion(): Code[20]
    begin
        exit('1510');
    end;

    internal procedure ClearingAccountforFactoringCurrentPortionName(): Text[100]
    begin
        exit(ClearingAccountforFactoringCurrentPortionTok);
    end;


    internal procedure CurrentLiabilitiestoEmployees(): Code[20]
    begin
        exit('1520');
    end;

    internal procedure CurrentLiabilitiestoEmployeesName(): Text[100]
    begin
        exit(CurrentLiabilitiestoEmployeesTok);
    end;


    internal procedure ClearingAccountforthirdparty(): Code[20]
    begin
        exit('1530');
    end;

    internal procedure ClearingAccountforthirdpartyName(): Text[100]
    begin
        exit(ClearingAccountforthirdpartyTok);
    end;


    internal procedure CurrentLoans(): Code[20]
    begin
        exit('1540');
    end;

    internal procedure CurrentLoansName(): Text[100]
    begin
        exit(CurrentLoansTok);
    end;


    internal procedure LiabilitiesGrantsReceived(): Code[20]
    begin
        exit('1550');
    end;

    internal procedure LiabilitiesGrantsReceivedName(): Text[100]
    begin
        exit(LiabilitiesGrantsReceivedTok);
    end;


    internal procedure TotalOtherCurrentLiabilities(): Code[20]
    begin
        exit('1599');
    end;

    internal procedure TotalOtherCurrentLiabilitiesName(): Text[100]
    begin
        exit(TotalOtherCurrentLiabilitiesTok);
    end;


    internal procedure AccruedExpensesandDeferredIncome(): Code[20]
    begin
        exit('1600');
    end;

    internal procedure AccruedExpensesandDeferredIncomeName(): Text[100]
    begin
        exit(AccruedExpensesandDeferredIncomeTok);
    end;


    internal procedure Accruedwages_salaries(): Code[20]
    begin
        exit('1610');
    end;

    internal procedure Accruedwages_salariesName(): Text[100]
    begin
        exit(Accruedwages_salariesTok);
    end;


    internal procedure AccruedHolidaypay(): Code[20]
    begin
        exit('1620');
    end;

    internal procedure AccruedHolidaypayName(): Text[100]
    begin
        exit(AccruedHolidaypayTok);
    end;


    internal procedure AccruedPensioncosts(): Code[20]
    begin
        exit('1630');
    end;

    internal procedure AccruedPensioncostsName(): Text[100]
    begin
        exit(AccruedPensioncostsTok);
    end;


    internal procedure AccruedInterestExpense(): Code[20]
    begin
        exit('1640');
    end;

    internal procedure AccruedInterestExpenseName(): Text[100]
    begin
        exit(AccruedInterestExpenseTok);
    end;


    internal procedure DeferredIncome(): Code[20]
    begin
        exit('1650');
    end;

    internal procedure DeferredIncomeName(): Text[100]
    begin
        exit(DeferredIncomeTok);
    end;


    internal procedure AccruedContractualcosts(): Code[20]
    begin
        exit('1660');
    end;

    internal procedure AccruedContractualcostsName(): Text[100]
    begin
        exit(AccruedContractualcostsTok);
    end;


    internal procedure OtherAccruedExpensesandDeferredIncome(): Code[20]
    begin
        exit('1670');
    end;

    internal procedure OtherAccruedExpensesandDeferredIncomeName(): Text[100]
    begin
        exit(OtherAccruedExpensesandDeferredIncomeTok);
    end;


    internal procedure TotalAccruedExpensesandDeferredIncome(): Code[20]
    begin
        exit('1699');
    end;

    internal procedure TotalAccruedExpensesandDeferredIncomeName(): Text[100]
    begin
        exit(TotalAccruedExpensesandDeferredIncomeTok);
    end;


    internal procedure TotalLiabilities(): Code[20]
    begin
        exit('1999');
    end;

    internal procedure TotalLiabilitiesName(): Text[100]
    begin
        exit(TotalLiabilitiesTok);
    end;


    internal procedure Equity(): Code[20]
    begin
        exit('2000');
    end;

    internal procedure EquityName(): Text[100]
    begin
        exit(EquityTok);
    end;


    internal procedure EquityPartner(): Code[20]
    begin
        exit('2100');
    end;

    internal procedure EquityPartnerName(): Text[100]
    begin
        exit(EquityPartnerTok);
    end;


    internal procedure NetResults(): Code[20]
    begin
        exit('2200');
    end;

    internal procedure NetResultsName(): Text[100]
    begin
        exit(NetResultsTok);
    end;


    internal procedure RestrictedEquity(): Code[20]
    begin
        exit('2300');
    end;

    internal procedure RestrictedEquityName(): Text[100]
    begin
        exit(RestrictedEquityTok);
    end;


    internal procedure ShareCapital(): Code[20]
    begin
        exit('2400');
    end;

    internal procedure ShareCapitalName(): Text[100]
    begin
        exit(ShareCapitalTok);
    end;


    internal procedure Non_RestrictedEquity(): Code[20]
    begin
        exit('2500');
    end;

    internal procedure Non_RestrictedEquityName(): Text[100]
    begin
        exit(Non_RestrictedEquityTok);
    end;


    internal procedure Profitorlossfromthepreviousyear(): Code[20]
    begin
        exit('2600');
    end;

    internal procedure ProfitorlossfromthepreviousyearName(): Text[100]
    begin
        exit(ProfitorlossfromthepreviousyearTok);
    end;


    internal procedure ResultsfortheFinancialyear(): Code[20]
    begin
        exit('2700');
    end;

    internal procedure ResultsfortheFinancialyearName(): Text[100]
    begin
        exit(ResultsfortheFinancialyearTok);
    end;


    internal procedure DistributionstoShareholders(): Code[20]
    begin
        exit('2800');
    end;

    internal procedure DistributionstoShareholdersName(): Text[100]
    begin
        exit(DistributionstoShareholdersTok);
    end;


    internal procedure TotalEquity(): Code[20]
    begin
        exit('2999');
    end;

    internal procedure TotalEquityName(): Text[100]
    begin
        exit(TotalEquityTok);
    end;


    internal procedure INCOMESTATEMENT(): Code[20]
    begin
        exit('3000');
    end;

    internal procedure INCOMESTATEMENTName(): Text[100]
    begin
        exit(INCOMESTATEMENTTok);
    end;


    internal procedure Income(): Code[20]
    begin
        exit('6000');
    end;

    internal procedure IncomeName(): Text[100]
    begin
        exit(IncomeTok);
    end;


    internal procedure SalesofGoods(): Code[20]
    begin
        exit('6100');
    end;

    internal procedure SalesofGoodsName(): Text[100]
    begin
        exit(SalesofGoodsTok);
    end;


    internal procedure SaleofFinishedGoods(): Code[20]
    begin
        exit('6110');
    end;

    internal procedure SaleofFinishedGoodsName(): Text[100]
    begin
        exit(SaleofFinishedGoodsTok);
    end;


    internal procedure SaleofRawMaterials(): Code[20]
    begin
        exit('6120');
    end;

    internal procedure SaleofRawMaterialsName(): Text[100]
    begin
        exit(SaleofRawMaterialsTok);
    end;


    internal procedure ResaleofGoods(): Code[20]
    begin
        exit('6130');
    end;

    internal procedure ResaleofGoodsName(): Text[100]
    begin
        exit(ResaleofGoodsTok);
    end;


    internal procedure TotalSalesofGoods(): Code[20]
    begin
        exit('6199');
    end;

    internal procedure TotalSalesofGoodsName(): Text[100]
    begin
        exit(TotalSalesofGoodsTok);
    end;


    internal procedure SalesofResources(): Code[20]
    begin
        exit('6200');
    end;

    internal procedure SalesofResourcesName(): Text[100]
    begin
        exit(SalesofResourcesTok);
    end;


    internal procedure SaleofResources(): Code[20]
    begin
        exit('6210');
    end;

    internal procedure SaleofResourcesName(): Text[100]
    begin
        exit(SaleofResourcesTok);
    end;


    internal procedure SaleofSubcontracting(): Code[20]
    begin
        exit('6220');
    end;

    internal procedure SaleofSubcontractingName(): Text[100]
    begin
        exit(SaleofSubcontractingTok);
    end;


    internal procedure TotalSalesofResources(): Code[20]
    begin
        exit('6299');
    end;

    internal procedure TotalSalesofResourcesName(): Text[100]
    begin
        exit(TotalSalesofResourcesTok);
    end;


    internal procedure AdditionalRevenue(): Code[20]
    begin
        exit('6300');
    end;

    internal procedure AdditionalRevenueName(): Text[100]
    begin
        exit(AdditionalRevenueTok);
    end;


    internal procedure Incomefromsecurities(): Code[20]
    begin
        exit('6310');
    end;

    internal procedure IncomefromsecuritiesName(): Text[100]
    begin
        exit(IncomefromsecuritiesTok);
    end;


    internal procedure ManagementFeeRevenue(): Code[20]
    begin
        exit('6320');
    end;

    internal procedure ManagementFeeRevenueName(): Text[100]
    begin
        exit(ManagementFeeRevenueTok);
    end;


    internal procedure InterestIncome(): Code[20]
    begin
        exit('6330');
    end;

    internal procedure InterestIncomeName(): Text[100]
    begin
        exit(InterestIncomeTok);
    end;


    internal procedure CurrencyGains(): Code[20]
    begin
        exit('6340');
    end;

    internal procedure CurrencyGainsName(): Text[100]
    begin
        exit(CurrencyGainsTok);
    end;


    internal procedure OtherIncidentalRevenue(): Code[20]
    begin
        exit('6350');
    end;

    internal procedure OtherIncidentalRevenueName(): Text[100]
    begin
        exit(OtherIncidentalRevenueTok);
    end;


    internal procedure TotalAdditionalRevenue(): Code[20]
    begin
        exit('6399');
    end;

    internal procedure TotalAdditionalRevenueName(): Text[100]
    begin
        exit(TotalAdditionalRevenueTok);
    end;


    internal procedure JobsandServices(): Code[20]
    begin
        exit('6400');
    end;

    internal procedure JobsandServicesName(): Text[100]
    begin
        exit(JobsandServicesTok);
    end;


    internal procedure JobSales(): Code[20]
    begin
        exit('6410');
    end;

    internal procedure JobSalesName(): Text[100]
    begin
        exit(JobSalesTok);
    end;


    internal procedure JobSalesApplied(): Code[20]
    begin
        exit('6420');
    end;

    internal procedure JobSalesAppliedName(): Text[100]
    begin
        exit(JobSalesAppliedTok);
    end;


    internal procedure SalesofServiceContracts(): Code[20]
    begin
        exit('6430');
    end;

    internal procedure SalesofServiceContractsName(): Text[100]
    begin
        exit(SalesofServiceContractsTok);
    end;


    internal procedure SalesofServiceWork(): Code[20]
    begin
        exit('6440');
    end;

    internal procedure SalesofServiceWorkName(): Text[100]
    begin
        exit(SalesofServiceWorkTok);
    end;


    internal procedure TotalJobsandServices(): Code[20]
    begin
        exit('6499');
    end;

    internal procedure TotalJobsandServicesName(): Text[100]
    begin
        exit(TotalJobsandServicesTok);
    end;


    internal procedure RevenueReductions(): Code[20]
    begin
        exit('6900');
    end;

    internal procedure RevenueReductionsName(): Text[100]
    begin
        exit(RevenueReductionsTok);
    end;


    internal procedure SalesDiscounts(): Code[20]
    begin
        exit('6910');
    end;

    internal procedure SalesDiscountsName(): Text[100]
    begin
        exit(SalesDiscountsTok);
    end;


    internal procedure SalesInvoiceRounding(): Code[20]
    begin
        exit('6920');
    end;

    internal procedure SalesInvoiceRoundingName(): Text[100]
    begin
        exit(SalesInvoiceRoundingTok);
    end;


    internal procedure SalesReturns(): Code[20]
    begin
        exit('6940');
    end;

    internal procedure SalesReturnsName(): Text[100]
    begin
        exit(SalesReturnsTok);
    end;


    internal procedure TotalRevenueReductions(): Code[20]
    begin
        exit('6998');
    end;

    internal procedure TotalRevenueReductionsName(): Text[100]
    begin
        exit(TotalRevenueReductionsTok);
    end;


    internal procedure TOTALINCOME(): Code[20]
    begin
        exit('6999');
    end;

    internal procedure TOTALINCOMEName(): Text[100]
    begin
        exit(TOTALINCOMETok);
    end;


    internal procedure COSTOFGOODSSOLD(): Code[20]
    begin
        exit('5000');
    end;

    internal procedure COSTOFGOODSSOLDName(): Text[100]
    begin
        exit(COSTOFGOODSSOLDTok);
    end;


    internal procedure CostofGoods(): Code[20]
    begin
        exit('5100');
    end;

    internal procedure CostofGoodsName(): Text[100]
    begin
        exit(CostofGoodsTok);
    end;


    internal procedure CostofMaterials(): Code[20]
    begin
        exit('5110');
    end;

    internal procedure CostofMaterialsName(): Text[100]
    begin
        exit(CostofMaterialsTok);
    end;


    internal procedure CostofMaterialsProjects(): Code[20]
    begin
        exit('5120');
    end;

    internal procedure CostofMaterialsProjectsName(): Text[100]
    begin
        exit(CostofMaterialsProjectsTok);
    end;


    internal procedure TotalCostofGoods(): Code[20]
    begin
        exit('5199');
    end;

    internal procedure TotalCostofGoodsName(): Text[100]
    begin
        exit(TotalCostofGoodsTok);
    end;


    internal procedure CostofResourcesandServices(): Code[20]
    begin
        exit('5200');
    end;

    internal procedure CostofResourcesandServicesName(): Text[100]
    begin
        exit(CostofResourcesandServicesTok);
    end;


    internal procedure CostofLabor(): Code[20]
    begin
        exit('5210');
    end;

    internal procedure CostofLaborName(): Text[100]
    begin
        exit(CostofLaborTok);
    end;


    internal procedure CostofLaborProjects(): Code[20]
    begin
        exit('5220');
    end;

    internal procedure CostofLaborProjectsName(): Text[100]
    begin
        exit(CostofLaborProjectsTok);
    end;


    internal procedure CostofLaborWarranty_Contract(): Code[20]
    begin
        exit('5230');
    end;

    internal procedure CostofLaborWarranty_ContractName(): Text[100]
    begin
        exit(CostofLaborWarranty_ContractTok);
    end;


    internal procedure TotalCostofResources(): Code[20]
    begin
        exit('5299');
    end;

    internal procedure TotalCostofResourcesName(): Text[100]
    begin
        exit(TotalCostofResourcesTok);
    end;


    internal procedure CostsofJobs(): Code[20]
    begin
        exit('5500');
    end;

    internal procedure CostsofJobsName(): Text[100]
    begin
        exit(CostsofJobsTok);
    end;


    internal procedure JobCosts(): Code[20]
    begin
        exit('5510');
    end;

    internal procedure JobCostsName(): Text[100]
    begin
        exit(JobCostsTok);
    end;


    internal procedure JobCostsApplied(): Code[20]
    begin
        exit('5520');
    end;

    internal procedure JobCostsAppliedName(): Text[100]
    begin
        exit(JobCostsAppliedTok);
    end;


    internal procedure TotalCostsofJobs(): Code[20]
    begin
        exit('5599');
    end;

    internal procedure TotalCostsofJobsName(): Text[100]
    begin
        exit(TotalCostsofJobsTok);
    end;


    internal procedure Subcontractedwork(): Code[20]
    begin
        exit('5300');
    end;

    internal procedure SubcontractedworkName(): Text[100]
    begin
        exit(SubcontractedworkTok);
    end;


    internal procedure ManufVariances(): Code[20]
    begin
        exit('5310');
    end;

    internal procedure ManufVariancesName(): Text[100]
    begin
        exit(ManufVariancesTok);
    end;


    internal procedure PurchaseVarianceCap(): Code[20]
    begin
        exit('5311');
    end;

    internal procedure PurchaseVarianceCapName(): Text[100]
    begin
        exit(PurchaseVarianceCapTok);
    end;


    internal procedure MaterialVariance(): Code[20]
    begin
        exit('5312');
    end;

    internal procedure MaterialVarianceName(): Text[100]
    begin
        exit(MaterialVarianceTok);
    end;


    internal procedure CapacityVariance(): Code[20]
    begin
        exit('5313');
    end;

    internal procedure CapacityVarianceName(): Text[100]
    begin
        exit(CapacityVarianceTok);
    end;


    internal procedure SubcontractedVariance(): Code[20]
    begin
        exit('5314');
    end;

    internal procedure SubcontractedVarianceName(): Text[100]
    begin
        exit(SubcontractedVarianceTok);
    end;


    internal procedure CapOverheadVariance(): Code[20]
    begin
        exit('5315');
    end;

    internal procedure CapOverheadVarianceName(): Text[100]
    begin
        exit(CapOverheadVarianceTok);
    end;


    internal procedure MfgOverheadVariance(): Code[20]
    begin
        exit('5316');
    end;

    internal procedure MfgOverheadVarianceName(): Text[100]
    begin
        exit(MfgOverheadVarianceTok);
    end;


    internal procedure TotalManufVariances(): Code[20]
    begin
        exit('5390');
    end;

    internal procedure TotalManufVariancesName(): Text[100]
    begin
        exit(TotalManufVariancesTok);
    end;


    internal procedure CostofVariances(): Code[20]
    begin
        exit('5400');
    end;

    internal procedure CostofVariancesName(): Text[100]
    begin
        exit(CostofVariancesTok);
    end;


    internal procedure TOTALCOSTOFGOODSSOLD(): Code[20]
    begin
        exit('5999');
    end;

    internal procedure TOTALCOSTOFGOODSSOLDName(): Text[100]
    begin
        exit(TOTALCOSTOFGOODSSOLDTok);
    end;


    internal procedure EXPENSES(): Code[20]
    begin
        exit('3001');
    end;

    internal procedure EXPENSESName(): Text[100]
    begin
        exit(EXPENSESTok);
    end;


    internal procedure FacilityExpenses(): Code[20]
    begin
        exit('3002');
    end;

    internal procedure FacilityExpensesName(): Text[100]
    begin
        exit(FacilityExpensesTok);
    end;


    internal procedure RentalFacilities(): Code[20]
    begin
        exit('3100');
    end;

    internal procedure RentalFacilitiesName(): Text[100]
    begin
        exit(RentalFacilitiesTok);
    end;


    internal procedure Rent_Leases(): Code[20]
    begin
        exit('3110');
    end;

    internal procedure Rent_LeasesName(): Text[100]
    begin
        exit(Rent_LeasesTok);
    end;


    internal procedure ElectricityforRental(): Code[20]
    begin
        exit('3120');
    end;

    internal procedure ElectricityforRentalName(): Text[100]
    begin
        exit(ElectricityforRentalTok);
    end;


    internal procedure HeatingforRental(): Code[20]
    begin
        exit('3130');
    end;

    internal procedure HeatingforRentalName(): Text[100]
    begin
        exit(HeatingforRentalTok);
    end;


    internal procedure WaterandSewerageforRental(): Code[20]
    begin
        exit('3140');
    end;

    internal procedure WaterandSewerageforRentalName(): Text[100]
    begin
        exit(WaterandSewerageforRentalTok);
    end;


    internal procedure CleaningandWasteforRental(): Code[20]
    begin
        exit('3150');
    end;

    internal procedure CleaningandWasteforRentalName(): Text[100]
    begin
        exit(CleaningandWasteforRentalTok);
    end;


    internal procedure RepairsandMaintenanceforRental(): Code[20]
    begin
        exit('3160');
    end;

    internal procedure RepairsandMaintenanceforRentalName(): Text[100]
    begin
        exit(RepairsandMaintenanceforRentalTok);
    end;


    internal procedure InsurancesRental(): Code[20]
    begin
        exit('3170');
    end;

    internal procedure InsurancesRentalName(): Text[100]
    begin
        exit(InsurancesRentalTok);
    end;


    internal procedure OtherRentalExpenses(): Code[20]
    begin
        exit('3180');
    end;

    internal procedure OtherRentalExpensesName(): Text[100]
    begin
        exit(OtherRentalExpensesTok);
    end;


    internal procedure TotalRentalFacilities(): Code[20]
    begin
        exit('3199');
    end;

    internal procedure TotalRentalFacilitiesName(): Text[100]
    begin
        exit(TotalRentalFacilitiesTok);
    end;


    internal procedure PropertyExpenses(): Code[20]
    begin
        exit('3200');
    end;

    internal procedure PropertyExpensesName(): Text[100]
    begin
        exit(PropertyExpensesTok);
    end;


    internal procedure SiteFees_Leases(): Code[20]
    begin
        exit('3210');
    end;

    internal procedure SiteFees_LeasesName(): Text[100]
    begin
        exit(SiteFees_LeasesTok);
    end;


    internal procedure ElectricityforProperty(): Code[20]
    begin
        exit('3220');
    end;

    internal procedure ElectricityforPropertyName(): Text[100]
    begin
        exit(ElectricityforPropertyTok);
    end;


    internal procedure HeatingforProperty(): Code[20]
    begin
        exit('3230');
    end;

    internal procedure HeatingforPropertyName(): Text[100]
    begin
        exit(HeatingforPropertyTok);
    end;


    internal procedure WaterandSewerageforProperty(): Code[20]
    begin
        exit('3240');
    end;

    internal procedure WaterandSewerageforPropertyName(): Text[100]
    begin
        exit(WaterandSewerageforPropertyTok);
    end;


    internal procedure CleaningandWasteforProperty(): Code[20]
    begin
        exit('3250');
    end;

    internal procedure CleaningandWasteforPropertyName(): Text[100]
    begin
        exit(CleaningandWasteforPropertyTok);
    end;


    internal procedure RepairsandMaintenanceforProperty(): Code[20]
    begin
        exit('3260');
    end;

    internal procedure RepairsandMaintenanceforPropertyName(): Text[100]
    begin
        exit(RepairsandMaintenanceforPropertyTok);
    end;


    internal procedure InsurancesProperty(): Code[20]
    begin
        exit('3270');
    end;

    internal procedure InsurancesPropertyName(): Text[100]
    begin
        exit(InsurancesPropertyTok);
    end;


    internal procedure OtherPropertyExpenses(): Code[20]
    begin
        exit('3280');
    end;

    internal procedure OtherPropertyExpensesName(): Text[100]
    begin
        exit(OtherPropertyExpensesTok);
    end;


    internal procedure TotalPropertyExpenses(): Code[20]
    begin
        exit('3298');
    end;

    internal procedure TotalPropertyExpensesName(): Text[100]
    begin
        exit(TotalPropertyExpensesTok);
    end;


    internal procedure TotalFacilityExpenses(): Code[20]
    begin
        exit('3299');
    end;

    internal procedure TotalFacilityExpensesName(): Text[100]
    begin
        exit(TotalFacilityExpensesTok);
    end;


    internal procedure FixedAssetsLeases(): Code[20]
    begin
        exit('3300');
    end;

    internal procedure FixedAssetsLeasesName(): Text[100]
    begin
        exit(FixedAssetsLeasesTok);
    end;


    internal procedure Hireofmachinery(): Code[20]
    begin
        exit('3310');
    end;

    internal procedure HireofmachineryName(): Text[100]
    begin
        exit(HireofmachineryTok);
    end;


    internal procedure Hireofcomputers(): Code[20]
    begin
        exit('3320');
    end;

    internal procedure HireofcomputersName(): Text[100]
    begin
        exit(HireofcomputersTok);
    end;


    internal procedure Hireofotherfixedassets(): Code[20]
    begin
        exit('3330');
    end;

    internal procedure HireofotherfixedassetsName(): Text[100]
    begin
        exit(HireofotherfixedassetsTok);
    end;


    internal procedure TotalFixedAssetLeases(): Code[20]
    begin
        exit('3399');
    end;

    internal procedure TotalFixedAssetLeasesName(): Text[100]
    begin
        exit(TotalFixedAssetLeasesTok);
    end;


    internal procedure LogisticsExpenses(): Code[20]
    begin
        exit('3400');
    end;

    internal procedure LogisticsExpensesName(): Text[100]
    begin
        exit(LogisticsExpensesTok);
    end;


    internal procedure VehicleExpenses(): Code[20]
    begin
        exit('3401');
    end;

    internal procedure VehicleExpensesName(): Text[100]
    begin
        exit(VehicleExpensesTok);
    end;


    internal procedure PassengerCarCosts(): Code[20]
    begin
        exit('3410');
    end;

    internal procedure PassengerCarCostsName(): Text[100]
    begin
        exit(PassengerCarCostsTok);
    end;


    internal procedure TruckCosts(): Code[20]
    begin
        exit('3420');
    end;

    internal procedure TruckCostsName(): Text[100]
    begin
        exit(TruckCostsTok);
    end;


    internal procedure Othervehicleexpenses(): Code[20]
    begin
        exit('3430');
    end;

    internal procedure OthervehicleexpensesName(): Text[100]
    begin
        exit(OthervehicleexpensesTok);
    end;


    internal procedure TotalVehicleExpenses(): Code[20]
    begin
        exit('3449');
    end;

    internal procedure TotalVehicleExpensesName(): Text[100]
    begin
        exit(TotalVehicleExpensesTok);
    end;


    internal procedure FreightCosts(): Code[20]
    begin
        exit('3450');
    end;

    internal procedure FreightCostsName(): Text[100]
    begin
        exit(FreightCostsTok);
    end;


    internal procedure Freightfeesforgoods(): Code[20]
    begin
        exit('3451');
    end;

    internal procedure FreightfeesforgoodsName(): Text[100]
    begin
        exit(FreightfeesforgoodsTok);
    end;


    internal procedure Customsandforwarding(): Code[20]
    begin
        exit('3452');
    end;

    internal procedure CustomsandforwardingName(): Text[100]
    begin
        exit(CustomsandforwardingTok);
    end;


    internal procedure Freightfeesprojects(): Code[20]
    begin
        exit('3453');
    end;

    internal procedure FreightfeesprojectsName(): Text[100]
    begin
        exit(FreightfeesprojectsTok);
    end;


    internal procedure TotalFreightCosts(): Code[20]
    begin
        exit('3459');
    end;

    internal procedure TotalFreightCostsName(): Text[100]
    begin
        exit(TotalFreightCostsTok);
    end;


    internal procedure TravelExpenses(): Code[20]
    begin
        exit('3460');
    end;

    internal procedure TravelExpensesName(): Text[100]
    begin
        exit(TravelExpensesTok);
    end;


    internal procedure Tickets(): Code[20]
    begin
        exit('3461');
    end;

    internal procedure TicketsName(): Text[100]
    begin
        exit(TicketsTok);
    end;


    internal procedure Rentalvehicles(): Code[20]
    begin
        exit('3462');
    end;

    internal procedure RentalvehiclesName(): Text[100]
    begin
        exit(RentalvehiclesTok);
    end;


    internal procedure Boardandlodging(): Code[20]
    begin
        exit('3463');
    end;

    internal procedure BoardandlodgingName(): Text[100]
    begin
        exit(BoardandlodgingTok);
    end;


    internal procedure Othertravelexpenses(): Code[20]
    begin
        exit('3464');
    end;

    internal procedure OthertravelexpensesName(): Text[100]
    begin
        exit(OthertravelexpensesTok);
    end;


    internal procedure TotalTravelExpenses(): Code[20]
    begin
        exit('3469');
    end;

    internal procedure TotalTravelExpensesName(): Text[100]
    begin
        exit(TotalTravelExpensesTok);
    end;


    internal procedure TotalLogisticsExpenses(): Code[20]
    begin
        exit('3499');
    end;

    internal procedure TotalLogisticsExpensesName(): Text[100]
    begin
        exit(TotalLogisticsExpensesTok);
    end;


    internal procedure MarketingandSales(): Code[20]
    begin
        exit('3500');
    end;

    internal procedure MarketingandSalesName(): Text[100]
    begin
        exit(MarketingandSalesTok);
    end;


    internal procedure Advertising(): Code[20]
    begin
        exit('3501');
    end;

    internal procedure AdvertisingName(): Text[100]
    begin
        exit(AdvertisingTok);
    end;


    internal procedure AdvertisementDevelopment(): Code[20]
    begin
        exit('3502');
    end;

    internal procedure AdvertisementDevelopmentName(): Text[100]
    begin
        exit(AdvertisementDevelopmentTok);
    end;


    internal procedure OutdoorandTransportationAds(): Code[20]
    begin
        exit('3503');
    end;

    internal procedure OutdoorandTransportationAdsName(): Text[100]
    begin
        exit(OutdoorandTransportationAdsTok);
    end;


    internal procedure Admatteranddirectmailings(): Code[20]
    begin
        exit('3504');
    end;

    internal procedure AdmatteranddirectmailingsName(): Text[100]
    begin
        exit(AdmatteranddirectmailingsTok);
    end;


    internal procedure Conference_ExhibitionSponsorship(): Code[20]
    begin
        exit('3505');
    end;

    internal procedure Conference_ExhibitionSponsorshipName(): Text[100]
    begin
        exit(Conference_ExhibitionSponsorshipTok);
    end;


    internal procedure Samplescontestsgifts(): Code[20]
    begin
        exit('3506');
    end;

    internal procedure SamplescontestsgiftsName(): Text[100]
    begin
        exit(SamplescontestsgiftsTok);
    end;


    internal procedure FilmTVradiointernetads(): Code[20]
    begin
        exit('3507');
    end;

    internal procedure FilmTVradiointernetadsName(): Text[100]
    begin
        exit(FilmTVradiointernetadsTok);
    end;


    internal procedure PRandAgencyFees(): Code[20]
    begin
        exit('3508');
    end;

    internal procedure PRandAgencyFeesName(): Text[100]
    begin
        exit(PRandAgencyFeesTok);
    end;


    internal procedure Otheradvertisingfees(): Code[20]
    begin
        exit('3509');
    end;

    internal procedure OtheradvertisingfeesName(): Text[100]
    begin
        exit(OtheradvertisingfeesTok);
    end;


    internal procedure TotalAdvertising(): Code[20]
    begin
        exit('3549');
    end;

    internal procedure TotalAdvertisingName(): Text[100]
    begin
        exit(TotalAdvertisingTok);
    end;


    internal procedure OtherMarketingExpenses(): Code[20]
    begin
        exit('3550');
    end;

    internal procedure OtherMarketingExpensesName(): Text[100]
    begin
        exit(OtherMarketingExpensesTok);
    end;


    internal procedure Catalogspricelists(): Code[20]
    begin
        exit('3551');
    end;

    internal procedure CatalogspricelistsName(): Text[100]
    begin
        exit(CatalogspricelistsTok);
    end;


    internal procedure TradePublications(): Code[20]
    begin
        exit('3552');
    end;

    internal procedure TradePublicationsName(): Text[100]
    begin
        exit(TradePublicationsTok);
    end;


    internal procedure TotalOtherMarketingExpenses(): Code[20]
    begin
        exit('3559');
    end;

    internal procedure TotalOtherMarketingExpensesName(): Text[100]
    begin
        exit(TotalOtherMarketingExpensesTok);
    end;


    internal procedure SalesExpenses(): Code[20]
    begin
        exit('3560');
    end;

    internal procedure SalesExpensesName(): Text[100]
    begin
        exit(SalesExpensesTok);
    end;


    internal procedure CreditCardCharges(): Code[20]
    begin
        exit('3561');
    end;

    internal procedure CreditCardChargesName(): Text[100]
    begin
        exit(CreditCardChargesTok);
    end;


    internal procedure BusinessEntertainingdeductible(): Code[20]
    begin
        exit('3562');
    end;

    internal procedure BusinessEntertainingdeductibleName(): Text[100]
    begin
        exit(BusinessEntertainingdeductibleTok);
    end;


    internal procedure BusinessEntertainingnondeductible(): Code[20]
    begin
        exit('3563');
    end;

    internal procedure BusinessEntertainingnondeductibleName(): Text[100]
    begin
        exit(BusinessEntertainingnondeductibleTok);
    end;


    internal procedure TotalSalesExpenses(): Code[20]
    begin
        exit('3569');
    end;

    internal procedure TotalSalesExpensesName(): Text[100]
    begin
        exit(TotalSalesExpensesTok);
    end;


    internal procedure TotalMarketingandSales(): Code[20]
    begin
        exit('3599');
    end;

    internal procedure TotalMarketingandSalesName(): Text[100]
    begin
        exit(TotalMarketingandSalesTok);
    end;


    internal procedure OfficeExpenses(): Code[20]
    begin
        exit('3600');
    end;

    internal procedure OfficeExpensesName(): Text[100]
    begin
        exit(OfficeExpensesTok);
    end;


    internal procedure OfficeSupplies(): Code[20]
    begin
        exit('3610');
    end;

    internal procedure OfficeSuppliesName(): Text[100]
    begin
        exit(OfficeSuppliesTok);
    end;


    internal procedure PhoneServices(): Code[20]
    begin
        exit('3620');
    end;

    internal procedure PhoneServicesName(): Text[100]
    begin
        exit(PhoneServicesTok);
    end;


    internal procedure Dataservices(): Code[20]
    begin
        exit('3630');
    end;

    internal procedure DataservicesName(): Text[100]
    begin
        exit(DataservicesTok);
    end;


    internal procedure Postalfees(): Code[20]
    begin
        exit('3640');
    end;

    internal procedure PostalfeesName(): Text[100]
    begin
        exit(PostalfeesTok);
    end;


    internal procedure Consumable_Expensiblehardware(): Code[20]
    begin
        exit('3650');
    end;

    internal procedure Consumable_ExpensiblehardwareName(): Text[100]
    begin
        exit(Consumable_ExpensiblehardwareTok);
    end;


    internal procedure Softwareandsubscriptionfees(): Code[20]
    begin
        exit('3660');
    end;

    internal procedure SoftwareandsubscriptionfeesName(): Text[100]
    begin
        exit(SoftwareandsubscriptionfeesTok);
    end;


    internal procedure TotalOfficeExpenses(): Code[20]
    begin
        exit('3699');
    end;

    internal procedure TotalOfficeExpensesName(): Text[100]
    begin
        exit(TotalOfficeExpensesTok);
    end;


    internal procedure InsurancesandRisks(): Code[20]
    begin
        exit('3700');
    end;

    internal procedure InsurancesandRisksName(): Text[100]
    begin
        exit(InsurancesandRisksTok);
    end;


    internal procedure CorporateInsurance(): Code[20]
    begin
        exit('3710');
    end;

    internal procedure CorporateInsuranceName(): Text[100]
    begin
        exit(CorporateInsuranceTok);
    end;


    internal procedure DamagesPaid(): Code[20]
    begin
        exit('3720');
    end;

    internal procedure DamagesPaidName(): Text[100]
    begin
        exit(DamagesPaidTok);
    end;


    internal procedure BadDebtLosses(): Code[20]
    begin
        exit('3730');
    end;

    internal procedure BadDebtLossesName(): Text[100]
    begin
        exit(BadDebtLossesTok);
    end;


    internal procedure Securityservices(): Code[20]
    begin
        exit('3740');
    end;

    internal procedure SecurityservicesName(): Text[100]
    begin
        exit(SecurityservicesTok);
    end;


    internal procedure Otherriskexpenses(): Code[20]
    begin
        exit('3750');
    end;

    internal procedure OtherriskexpensesName(): Text[100]
    begin
        exit(OtherriskexpensesTok);
    end;


    internal procedure TotalInsurancesandRisks(): Code[20]
    begin
        exit('3799');
    end;

    internal procedure TotalInsurancesandRisksName(): Text[100]
    begin
        exit(TotalInsurancesandRisksTok);
    end;


    internal procedure ManagementandAdmin(): Code[20]
    begin
        exit('3800');
    end;

    internal procedure ManagementandAdminName(): Text[100]
    begin
        exit(ManagementandAdminTok);
    end;


    internal procedure Management(): Code[20]
    begin
        exit('3801');
    end;

    internal procedure ManagementName(): Text[100]
    begin
        exit(ManagementTok);
    end;


    internal procedure RemunerationtoDirectors(): Code[20]
    begin
        exit('3810');
    end;

    internal procedure RemunerationtoDirectorsName(): Text[100]
    begin
        exit(RemunerationtoDirectorsTok);
    end;


    internal procedure ManagementFees(): Code[20]
    begin
        exit('3811');
    end;

    internal procedure ManagementFeesName(): Text[100]
    begin
        exit(ManagementFeesTok);
    end;


    internal procedure Annual_interrimReports(): Code[20]
    begin
        exit('3812');
    end;

    internal procedure Annual_interrimReportsName(): Text[100]
    begin
        exit(Annual_interrimReportsTok);
    end;


    internal procedure Annual_generalmeeting(): Code[20]
    begin
        exit('3813');
    end;

    internal procedure Annual_generalmeetingName(): Text[100]
    begin
        exit(Annual_generalmeetingTok);
    end;


    internal procedure AuditandAuditServices(): Code[20]
    begin
        exit('3814');
    end;

    internal procedure AuditandAuditServicesName(): Text[100]
    begin
        exit(AuditandAuditServicesTok);
    end;


    internal procedure TaxadvisoryServices(): Code[20]
    begin
        exit('3815');
    end;

    internal procedure TaxadvisoryServicesName(): Text[100]
    begin
        exit(TaxadvisoryServicesTok);
    end;


    internal procedure TotalManagementFees(): Code[20]
    begin
        exit('3849');
    end;

    internal procedure TotalManagementFeesName(): Text[100]
    begin
        exit(TotalManagementFeesTok);
    end;


    internal procedure TotalManagementandAdmin(): Code[20]
    begin
        exit('3899');
    end;

    internal procedure TotalManagementandAdminName(): Text[100]
    begin
        exit(TotalManagementandAdminTok);
    end;


    internal procedure BankingandInterest(): Code[20]
    begin
        exit('3900');
    end;

    internal procedure BankingandInterestName(): Text[100]
    begin
        exit(BankingandInterestTok);
    end;


    internal procedure Bankingfees(): Code[20]
    begin
        exit('3910');
    end;

    internal procedure BankingfeesName(): Text[100]
    begin
        exit(BankingfeesTok);
    end;


    internal procedure InterestExpenses(): Code[20]
    begin
        exit('3920');
    end;

    internal procedure InterestExpensesName(): Text[100]
    begin
        exit(InterestExpensesTok);
    end;


    internal procedure PayableInvoiceRounding(): Code[20]
    begin
        exit('3930');
    end;

    internal procedure PayableInvoiceRoundingName(): Text[100]
    begin
        exit(PayableInvoiceRoundingTok);
    end;


    internal procedure TotalBankingandInterest(): Code[20]
    begin
        exit('3999');
    end;

    internal procedure TotalBankingandInterestName(): Text[100]
    begin
        exit(TotalBankingandInterestTok);
    end;


    internal procedure ExternalServices_Expenses(): Code[20]
    begin
        exit('4000');
    end;

    internal procedure ExternalServices_ExpensesName(): Text[100]
    begin
        exit(ExternalServices_ExpensesTok);
    end;


    internal procedure ExternalServices(): Code[20]
    begin
        exit('4100');
    end;

    internal procedure ExternalServicesName(): Text[100]
    begin
        exit(ExternalServicesTok);
    end;


    internal procedure AccountingServices(): Code[20]
    begin
        exit('4110');
    end;

    internal procedure AccountingServicesName(): Text[100]
    begin
        exit(AccountingServicesTok);
    end;


    internal procedure ITServices(): Code[20]
    begin
        exit('4120');
    end;

    internal procedure ITServicesName(): Text[100]
    begin
        exit(ITServicesTok);
    end;


    internal procedure MediaServices(): Code[20]
    begin
        exit('4130');
    end;

    internal procedure MediaServicesName(): Text[100]
    begin
        exit(MediaServicesTok);
    end;


    internal procedure ConsultingServices(): Code[20]
    begin
        exit('4140');
    end;

    internal procedure ConsultingServicesName(): Text[100]
    begin
        exit(ConsultingServicesTok);
    end;


    internal procedure LegalFeesandAttorneyServices(): Code[20]
    begin
        exit('4150');
    end;

    internal procedure LegalFeesandAttorneyServicesName(): Text[100]
    begin
        exit(LegalFeesandAttorneyServicesTok);
    end;


    internal procedure OtherExternalServices(): Code[20]
    begin
        exit('4160');
    end;

    internal procedure OtherExternalServicesName(): Text[100]
    begin
        exit(OtherExternalServicesTok);
    end;


    internal procedure TotalExternalServices(): Code[20]
    begin
        exit('4199');
    end;

    internal procedure TotalExternalServicesName(): Text[100]
    begin
        exit(TotalExternalServicesTok);
    end;


    internal procedure OtherExternalExpenses(): Code[20]
    begin
        exit('4200');
    end;

    internal procedure OtherExternalExpensesName(): Text[100]
    begin
        exit(OtherExternalExpensesTok);
    end;


    internal procedure LicenseFees_Royalties(): Code[20]
    begin
        exit('4210');
    end;

    internal procedure LicenseFees_RoyaltiesName(): Text[100]
    begin
        exit(LicenseFees_RoyaltiesTok);
    end;


    internal procedure Trademarks_Patents(): Code[20]
    begin
        exit('4220');
    end;

    internal procedure Trademarks_PatentsName(): Text[100]
    begin
        exit(Trademarks_PatentsTok);
    end;


    internal procedure AssociationFees(): Code[20]
    begin
        exit('4230');
    end;

    internal procedure AssociationFeesName(): Text[100]
    begin
        exit(AssociationFeesTok);
    end;


    internal procedure Miscexternalexpenses(): Code[20]
    begin
        exit('4240');
    end;

    internal procedure MiscexternalexpensesName(): Text[100]
    begin
        exit(MiscexternalexpensesTok);
    end;


    internal procedure PurchaseDiscounts(): Code[20]
    begin
        exit('4250');
    end;

    internal procedure PurchaseDiscountsName(): Text[100]
    begin
        exit(PurchaseDiscountsTok);
    end;


    internal procedure TotalOtherExternalExpenses(): Code[20]
    begin
        exit('4298');
    end;

    internal procedure TotalOtherExternalExpensesName(): Text[100]
    begin
        exit(TotalOtherExternalExpensesTok);
    end;


    internal procedure TotalExternalServices_Expenses(): Code[20]
    begin
        exit('4299');
    end;

    internal procedure TotalExternalServices_ExpensesName(): Text[100]
    begin
        exit(TotalExternalServices_ExpensesTok);
    end;


    internal procedure Personnel(): Code[20]
    begin
        exit('4300');
    end;

    internal procedure PersonnelName(): Text[100]
    begin
        exit(PersonnelTok);
    end;


    internal procedure WagesandSalaries(): Code[20]
    begin
        exit('4301');
    end;

    internal procedure WagesandSalariesName(): Text[100]
    begin
        exit(WagesandSalariesTok);
    end;


    internal procedure Salaries(): Code[20]
    begin
        exit('4310');
    end;

    internal procedure SalariesName(): Text[100]
    begin
        exit(SalariesTok);
    end;


    internal procedure HourlyWages(): Code[20]
    begin
        exit('4320');
    end;

    internal procedure HourlyWagesName(): Text[100]
    begin
        exit(HourlyWagesTok);
    end;


    internal procedure OvertimeWages(): Code[20]
    begin
        exit('4330');
    end;

    internal procedure OvertimeWagesName(): Text[100]
    begin
        exit(OvertimeWagesTok);
    end;


    internal procedure Bonuses(): Code[20]
    begin
        exit('4340');
    end;

    internal procedure BonusesName(): Text[100]
    begin
        exit(BonusesTok);
    end;


    internal procedure CommissionsPaid(): Code[20]
    begin
        exit('4350');
    end;

    internal procedure CommissionsPaidName(): Text[100]
    begin
        exit(CommissionsPaidTok);
    end;


    internal procedure PTOAccrued(): Code[20]
    begin
        exit('4360');
    end;

    internal procedure PTOAccruedName(): Text[100]
    begin
        exit(PTOAccruedTok);
    end;


    internal procedure TotalWagesandSalaries(): Code[20]
    begin
        exit('4399');
    end;

    internal procedure TotalWagesandSalariesName(): Text[100]
    begin
        exit(TotalWagesandSalariesTok);
    end;


    internal procedure Benefits_Pension(): Code[20]
    begin
        exit('4400');
    end;

    internal procedure Benefits_PensionName(): Text[100]
    begin
        exit(Benefits_PensionTok);
    end;


    internal procedure Benefits(): Code[20]
    begin
        exit('4401');
    end;

    internal procedure BenefitsName(): Text[100]
    begin
        exit(BenefitsTok);
    end;


    internal procedure TrainingCosts(): Code[20]
    begin
        exit('4410');
    end;

    internal procedure TrainingCostsName(): Text[100]
    begin
        exit(TrainingCostsTok);
    end;


    internal procedure HealthCareContributions(): Code[20]
    begin
        exit('4411');
    end;

    internal procedure HealthCareContributionsName(): Text[100]
    begin
        exit(HealthCareContributionsTok);
    end;


    internal procedure Entertainmentofpersonnel(): Code[20]
    begin
        exit('4412');
    end;

    internal procedure EntertainmentofpersonnelName(): Text[100]
    begin
        exit(EntertainmentofpersonnelTok);
    end;


    internal procedure Allowances(): Code[20]
    begin
        exit('4413');
    end;

    internal procedure AllowancesName(): Text[100]
    begin
        exit(AllowancesTok);
    end;


    internal procedure Mandatoryclothingexpenses(): Code[20]
    begin
        exit('4414');
    end;

    internal procedure MandatoryclothingexpensesName(): Text[100]
    begin
        exit(MandatoryclothingexpensesTok);
    end;


    internal procedure Othercash_remunerationbenefits(): Code[20]
    begin
        exit('4415');
    end;

    internal procedure Othercash_remunerationbenefitsName(): Text[100]
    begin
        exit(Othercash_remunerationbenefitsTok);
    end;


    internal procedure TotalBenefits(): Code[20]
    begin
        exit('4449');
    end;

    internal procedure TotalBenefitsName(): Text[100]
    begin
        exit(TotalBenefitsTok);
    end;


    internal procedure Pension(): Code[20]
    begin
        exit('4450');
    end;

    internal procedure PensionName(): Text[100]
    begin
        exit(PensionTok);
    end;


    internal procedure Pensionfeesandrecurringcosts(): Code[20]
    begin
        exit('4460');
    end;

    internal procedure PensionfeesandrecurringcostsName(): Text[100]
    begin
        exit(PensionfeesandrecurringcostsTok);
    end;


    internal procedure EmployerContributions(): Code[20]
    begin
        exit('4470');
    end;

    internal procedure EmployerContributionsName(): Text[100]
    begin
        exit(EmployerContributionsTok);
    end;


    internal procedure TotalPension(): Code[20]
    begin
        exit('4498');
    end;

    internal procedure TotalPensionName(): Text[100]
    begin
        exit(TotalPensionTok);
    end;


    internal procedure TotalBenefits_Pension(): Code[20]
    begin
        exit('4499');
    end;

    internal procedure TotalBenefits_PensionName(): Text[100]
    begin
        exit(TotalBenefits_PensionTok);
    end;


    internal procedure InsurancesPersonnel(): Code[20]
    begin
        exit('4500');
    end;

    internal procedure InsurancesPersonnelName(): Text[100]
    begin
        exit(InsurancesPersonnelTok);
    end;


    internal procedure HealthInsurance(): Code[20]
    begin
        exit('4510');
    end;

    internal procedure HealthInsuranceName(): Text[100]
    begin
        exit(HealthInsuranceTok);
    end;


    internal procedure DentalInsurance(): Code[20]
    begin
        exit('4520');
    end;

    internal procedure DentalInsuranceName(): Text[100]
    begin
        exit(DentalInsuranceTok);
    end;


    internal procedure WorkersCompensation(): Code[20]
    begin
        exit('4530');
    end;

    internal procedure WorkersCompensationName(): Text[100]
    begin
        exit(WorkersCompensationTok);
    end;


    internal procedure LifeInsurance(): Code[20]
    begin
        exit('4540');
    end;

    internal procedure LifeInsuranceName(): Text[100]
    begin
        exit(LifeInsuranceTok);
    end;


    internal procedure TotalInsurancesPersonnel(): Code[20]
    begin
        exit('4599');
    end;

    internal procedure TotalInsurancesPersonnelName(): Text[100]
    begin
        exit(TotalInsurancesPersonnelTok);
    end;


    internal procedure TotalPersonnel(): Code[20]
    begin
        exit('4699');
    end;

    internal procedure TotalPersonnelName(): Text[100]
    begin
        exit(TotalPersonnelTok);
    end;


    internal procedure Depreciation(): Code[20]
    begin
        exit('4800');
    end;

    internal procedure DepreciationName(): Text[100]
    begin
        exit(DepreciationTok);
    end;


    internal procedure DepreciationLandandProperty(): Code[20]
    begin
        exit('4810');
    end;

    internal procedure DepreciationLandandPropertyName(): Text[100]
    begin
        exit(DepreciationLandandPropertyTok);
    end;


    internal procedure DepreciationFixedAssets(): Code[20]
    begin
        exit('4820');
    end;

    internal procedure DepreciationFixedAssetsName(): Text[100]
    begin
        exit(DepreciationFixedAssetsTok);
    end;


    internal procedure TotalDepreciation(): Code[20]
    begin
        exit('4899');
    end;

    internal procedure TotalDepreciationName(): Text[100]
    begin
        exit(TotalDepreciationTok);
    end;


    internal procedure MiscExpenses(): Code[20]
    begin
        exit('4900');
    end;

    internal procedure MiscExpensesName(): Text[100]
    begin
        exit(MiscExpensesTok);
    end;


    internal procedure CurrencyLosses(): Code[20]
    begin
        exit('4910');
    end;

    internal procedure CurrencyLossesName(): Text[100]
    begin
        exit(CurrencyLossesTok);
    end;


    internal procedure TotalMiscExpenses(): Code[20]
    begin
        exit('4998');
    end;

    internal procedure TotalMiscExpensesName(): Text[100]
    begin
        exit(TotalMiscExpensesTok);
    end;


    internal procedure TOTALEXPENSES(): Code[20]
    begin
        exit('4999');
    end;

    internal procedure TOTALEXPENSESName(): Text[100]
    begin
        exit(TOTALEXPENSESTok);
    end;


    internal procedure NETINCOME(): Code[20]
    begin
        exit('9999');
    end;

    internal procedure NETINCOMEName(): Text[100]
    begin
        exit(NETINCOMETok);
    end;
}
