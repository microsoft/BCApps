codeunit 101081 "Create Gen. Journal Line"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        "Entry Balance" := 0;
        "Exactly Balanced" := false;

        LastYear := Date2DMY(CA.AdjustDate(19020101D), 3);
        LY := CopyStr(Format(DemoDataSetup."Starting Year"), 3, 2);
        CurrYear := Date2DMY(CA.AdjustDate(19030101D), 3);
        CY := IncStr(LY);

        // OPENING SALDO

        // Customer opening entries
        InsertCustLine('10000', '26', 19011231D, 0, 1017266.89, '00-1');
        InsertCustLine('30000', '27', 19011231D, 0, 3051800.67, '00-10');
        InsertCustLine('10000', '28', 19011231D, 0, 2543167.22, '00-11');
        InsertCustLine('20000', '29', 19011231D, 0, 2204078.26, '00-12');
        InsertCustLine('30000', '30', 19011231D, 0, 3221345.15, '00-13');
        InsertCustLine('20000', '31', 19011231D, 0, 1525900.33, '00-14');
        InsertCustLine('30000', '32', 19011231D, 0, 3051800.67, '00-15');
        InsertCustLine('10000', XMO + '25', 19011231D, 0, 1356355.84, '00-16');
        InsertCustLine('01454545', '33', 19011231D, 0, 127914.42, '00-17');
        InsertCustLine('20000', '34', 19011231D, 0, 1695444.82, '00-2');
        InsertCustLine('10000', '35', 19011231D, 0, 2034533.78, '00-3');
        InsertCustLine('30000', XMO + '34', 19011231D, 0, 1356355.85, '00-4');
        InsertCustLine('20000', '36', 19011231D, 0, 1017266.89, '00-5');
        InsertCustLine('10000', '37', 19011231D, 0, 2712711.7, '00-6');
        InsertCustLine('30000', '38', 19011231D, 0, 3051800.67, '00-7');
        InsertCustLine('20000', '39', 19011231D, 0, 2034533.78, '00-8');
        InsertCustLine('10000', '40', 19011231D, 0, 2034533.78, '00-9');

        // Vendor opening entries
        InsertVendLine('01254796', '17', 19011231D, 0, -100083.52, '2344');
        InsertVendLine('20000', '18', 19011231D, 0, -3439325.12, '4362');
        InsertVendLine('20000', '19', 19011231D, 0, -3439325.12, '4511');
        InsertVendLine('10000', '20', 19011231D, 0, -3224367.3, '5437');
        InsertVendLine('10000', '21', 19011231D, 0, -2982689.1, '5578');
        InsertVendLine('10000', XMO + '15', 19011231D, 0, -2579493.84, '5672');
        InsertVendLine('30000', '22', 19011231D, 0, -3009409.48, '12345');
        InsertVendLine('30000', '23', 19011231D, 0, -4729072.04, '12388');
        InsertVendLine('30000', '24', 19011231D, 0, -58870732.51, '12389');
        InsertVendLine('30000', '25', 19011231D, 0, -6975936.65, '12390');

        // Bank account opening entries
        InsertBankAccEntry(XCASH + '2', 'BANK2', 0, 25000, '42');
        InsertBankAccEntry(XWWBRUR, XBANK1, 0, 16975936.65, '43');
        InsertDailyEntry(
          XSTART, XBANKOPEN, 0, '80-1000', 19011231D, 0, '41', StrSubstNo(XOpeningSaldoEquityCapital, 19011231D),
          0, '99-1001', -10000, '', '', 0, '', 19011231D, false);

        // REGULAR OPERATIONS
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVSH + '001', 19021001D, 0, XG + '-' + LY + '-0001',
          XIvanovCCGeneration30000, 0, '80-1000',
          3000000, '', '', 0, '', 19021001D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVSH + '002', 19021001D, 0, XG + '-' + LY + '-0001',
          XNordeTradersCCGeneration40000,
          0, '80-1000', 4000000, '', '', 0, '', 19021001D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVSH + '003', 19021001D, 0, XG + '-' + LY + '-0001',
          XContosoFarmCCGeneration266941,
          0, '80-1000', 26694100, '', '', 0, '', 19021001D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVSH + '004', 19021001D, 0, XG + '-' + LY + '-0002',
          XGraphicDesignCCGeneration8259,
          0, '80-1000', 825900, '', '', 0, '', 19021001D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVSH + '005', 19021001D, 0, XG + '-' + LY + '-0002',
          XTeilspinToysCCGeneraion4800,
          0, '80-1000', 480000, '', '', 0, '', 19021001D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '57-1000', 19021016D, 0, XG + '-' + LY + '-0003',
          XCurrPurchGainCalulated,
          0, '91-2312', -3080, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVFI + '002', 19021206D, 0, XG + '-' + LY + '-0004',
          XAcqOfSharesOfSouthRidgeCC100,
          0, '58-1220', -1500000, '', '6101030', 0, '', 19021206D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVFI + '001', 19021103D, 0, XG + '-' + LY + '-0005',
          XEarningsOfFirstBillOfSohoVineri,
          0, '58-2100', -4000000, '', '6101030', 0, '', 19021103D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '58-2100', 19021215D, 0, XG + '-' + LY + '-0006',
          XWriteOffBalanceValueOfSohoVineriBill,
          0, '91-2303', -4000000, '', '2200100', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVFI + '001', 19021215D, 0, XG + '-' + LY + '-0007',
          XSohoVineriBillPresented,
          0, '91-1303', 5000000, '', '1201000', 0, '', 19021215D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '98-2000', 19021130D, 0, XG + '-' + LY + '-0008',
          XWriteOffProportionallyChargedDepr,
          0, '91-1315', 9817, '', '1201000', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVFI + '004', 19021228D, 0, XG + '-' + LY + '-0010',
          XGainOnDisposalOfFAContribToAlpineCC,
          0, '91-1390', 114583.3, '', '6101030', 0, '', 19021228D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '58-1120', 19021228D, 0, XG + '-' + LY + '-0011',
          XContribToCCOFAlpineSkyHousePlus,
          2, XVFI + '004', 135208.3, '', '6101030', 0, '', 19021228D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '98-2000', 19021231D, 0, XG + '-' + LY + '-0012',
          XWriteOffProportionallyChargedDepr0711,
          0, '91-1315', 9817, '', '1201000', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '19-1000', 19021231D, 0, XG + '-' + LY + '-0013',
          XVATReinstOnContribToCC,
          0, '68-4600', 20625, '', '6101030', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVFI + '004', 19021231D, 0, XG + '-' + LY + '-0014',
          XWriteOffVATOnCotribToCC,
          0, '19-1000', 29625, '', '6101030', 0, '', 19021231D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '19-1000', 19021231D, 0, XG + '-' + LY + '-0015',
          XVATReinstOnGratuitousPassOfFA,
          0, '68-4600', 4125, '', '2200100', 0, '', 19021231D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-2390', 19021231D, 0, XG + '-' + LY + '-0016',
          XWriteOffVATOnGratuitousPassOfFA,
          0, '19-1000', 4125, '', '2200100', 0, '', 19021231D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVEM + '002', 19021231D, 0, XG + '-' + LY + '-0017',
          XWriteOffShortagesOnGuilty,
          0, '94-1000', 24000, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XTAX + '010', 19021231D, 0, XG + '-' + LY + '-0018',
          StrSubstNo(XChargingOfTransportTaxForYear, LastYear),
          0, '26-6000', -31671, '', '2102190', 0, '', 19021231D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '84-1000', 19021231D, 0, XG + '-' + LY + '-0019',
          StrSubstNo(XCapitalReservesOfFivePctFromNetProfitWasFormed, LastYear),
          0, '82-1200', 54788, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVOB + '003', 19021015D, 0, XG + '-' + LY + '-0020',
          XTreatmentOBuildingfHypotecationValue,
          0, '99-1090', -15000000, '', '', 0, '', 19021015D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVOB + '003', 19031015D, 0, XG + '-' + LY + '-0021',
          XReturnFromPledgeCreditAgrStop,
          0, '99-1090', 15000000, '', '', 0, '', 19021015D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '57-2000', 19030119D, 0, XG + '-' + LY + '-0002',
          XReceiptOfLossFromPurch,
          0, '91-2312', -32427.89, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '57-2000', 19030119D, 0, XG + '-' + LY + '-0002',
          XReceiptOfIncomeFromPurch,
          0, '91-1312', 15967.53, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVSH + '005', 19021205D, 0, XG + '6-' + LY + '-001',
          XIncreaseOfCCAtFollowonOffering,
          0, '80-1000', 14000000, '', '', 0, '', 19021205D, false);

        // BANK ADN CASH OPERATIONS
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 2, XVSH + '001', 19021002D, 0, XICO + '-' + LY + '-001',
          XIvanovII,
          3, XCASH + '1', -3000000, '', '', 0, '', 19021002D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 3, XNBL, 19021002D, 0, XOCO + '-' + LY + '-001',
          XNewBankOfMoscow,
          3, XCASH + '1', 2900000, '', '', 0, '', 19021002D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 2, '71-001', 19021002D, 1, XOCO + '-' + LY + '-002',
          XPetrovPP,
          3, XCASH + '1', 100000, '', '', 0, '', 19021002D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 2, '71-001', 19021004D, 0, XICO + '-' + LY + '-002',
          XPetrovPP,
          3, XCASH + '1', -12322.24, '', '', 0, '', 19021004D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 3, XNBL, 19021015D, 1, XICO + '-' + LY + '-003',
          XNewBankOfMoscow,
          3, XCASH + '1', -75000, '', '', 0, '', 19021015D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1000', 19021015D, 1, XOCO + '-' + LY + '-003',
          StrSubstNo(XSalaryAdvancePaidForMonth, XOctober),
          3, XCASH + '1', 75000, '', '', 0, '', 19021015D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 3, XNBL, 19021031D, 1, XICO + '-' + LY + '-004',
          XNewBankOfMoscow,
          3, XCASH + '1', -145000, '', '', 0, '', 19021031D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1000', 19021031D, 1, XOCO + '-' + LY + '-004',
          StrSubstNo(XSalaryAdvancePaidForMonth, XOctober),
          3, XCASH + '1', 112920, '', '', 0, '', 19021031D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1100', 19021031D, 1, XOCO + '-' + LY + '-005',
          StrSubstNo(XSalaryAdvancePaidForMonth, XOctober),
          3, XCASH + '1', 41760, '', '', 0, '', 19021031D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 1, XCLE + '001', 19021106D, 1, XICO + '-' + LY + '-005',
          XAdventureWorks,
          3, XCASH + '1', -6745.24, '', '', 0, '', 19021106D, true);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 3, XNBL, 19021115D, 1, XICO + '-' + LY + '-006',
          XNewBankOfMoscow,
          3, XCASH + '1', -75000, '', '', 0, '', 19021115D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1000', 19021115D, 1, XOCO + '-' + LY + '-006',
          StrSubstNo(XSalaryAdvancePaidForMonth, XNovember),
          3, XCASH + '1', 75000, '', '', 0, '', 19021115D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 2, '71-001', 19021122D, 0, XICO + '-' + LY + '-007',
          XPetrovPP,
          3, XCASH + '1', -6393.4, '', '', 0, '', 19021122D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 3, XNBL, 19021130D, 1, XICO + '-' + LY + '-008',
          XNewBankOfMoscow,
          3, XCASH + '1', -150000, '', '', 0, '', 19021130D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1000', 19021130D, 1, XOCO + '-' + LY + '-007',
          StrSubstNo(XSalaryAdvancePaidForMonth, XNovember),
          3, XCASH + '1', 112920, '', '', 0, '', 19021130D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1100', 19021130D, 1, XOCO + '-' + LY + '-008',
          StrSubstNo(XSalaryAdvancePaidForMonth, XNovember),
          3, XCASH + '1', 41760, '', '', 0, '', 19021130D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 3, XNBL, 19021215D, 1, XICO + '-' + LY + '-009',
          XNewBankOfMoscow,
          3, XCASH + '1', -75000, '', '', 0, '', 19021215D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1000', 19021215D, 1, XOCO + '-' + LY + '-009',
          StrSubstNo(XSalaryAdvancePaidForMonth, XDecember),
          3, XCASH + '1', 75000, '', '', 0, '', 19021215D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 3, XNBL, 19030110D, 1, XICO + '-' + LY + '-010',
          XNewBankOfMoscow,
          3, XCASH + '1', -115000, '', '', 0, '', 19030110D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1000', 19030110D, 1, XOCO + '-' + LY + '-010',
          StrSubstNo(XSalaryAdvancePaidForMonth, XDecember),
          3, XCASH + '1', 112920, '', '', 0, '', 19030110D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 3, XNBL, 19030115D, 1, XICO + '-' + LY + '-011',
          XNewBankOfMoscow,
          3, XCASH + '1', -75000, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1000', 19030115D, 1, XOCO + '-' + LY + '-011',
          StrSubstNo(XSalaryAdvancePaidForMonth, XJanuary),
          3, XCASH + '1', 75000, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 3, XNBL, 19030131D, 1, XICO + '-' + LY + '-012',
          XNewBankOfMoscow,
          3, XCASH + '1', -115000, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 0, '70-1000', 19030131D, 1, XOCO + '-' + LY + '-012',
          StrSubstNo(XSalaryAdvancePaidForMonth, XJanuary),
          3, XCASH + '1', 112920, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '1', 2, XVSH + '011', 19030131D, 1, XOCO + '-' + LY + '-013',
          XCronusIP,
          3, XCASH + '1', 136, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '2', 2, XLT, 19030101D, 0, XOCO + '2' + '-' + CY + '-001',
          StrSubstNo(XSergienkoSergienko, XAccountability),
          3, XCASH + '2', -2000, '', '', 0, '', 19030101D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '2', 2, XLT, 19030106D, 0, XOCO + '2' + '-' + CY + '-002',
          StrSubstNo(XSergienkoSergienko, XAccountability),
          3, XCASH + '2', -5000, '', '', 0, '', 19030106D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '2', 2, XEH, 19030116D, 0, XOCO + '2' + '-' + CY + '-003',
          StrSubstNo(XPopkovaPopkova, XAccountability),
          3, XCASH + '2', -12000, '', '', 0, '', 19030116D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '2', 2, XEH, 19030121D, 0, XOCO + '2' + '-' + CY + '-004',
          StrSubstNo(XPopkovaPopkova, XAccountability),
          3, XCASH + '2', -7089.12, '', '', 0, '', 19030121D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '2', 2, XKH, 19030106D, 0, XOCO + '2' + '-' + CY + '-001',
          StrSubstNo(XMarkovaMarkova, XAccountability),
          3, XCASH + '2', 25000, '', '', 0, '', 19030106D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '2', 2, XKH, 19030111D, 0, XOCO + '2' + '-' + CY + '-002',
          StrSubstNo(XMarkovaMarkova, XAccountability),
          3, XCASH + '2', 5000, '', '', 0, '', 19030111D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '2', 2, XMH, 19030113D, 0, XOCO + '2' + '-' + CY + '-003',
          StrSubstNo(XHolodovHolodov, XAccountability),
          3, XCASH + '2', 1200, '', '', 0, '', 19030113D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '2', 2, XMH, 19030121D, 0, XOCO + '2' + '-' + CY + '-004',
          StrSubstNo(XHolodovHolodov, XAccountability),
          3, XCASH + '2', 200.33, '', '', 0, '', 19030121D, false);
        InsertDailyEntry(
          XCASHORDER, XCASHRUR + '2', 3, XWWBRUR, 19020630D, 0, XOCO + '2' + '-' + CY + '-005',
          XInternationalBank,
          3, XCASH + '2', 128.98, '', '', 0, '', 19020630D, false);
        InsertDailyEntry(
          XPayment, XWWBUSD, 0, '57-1000', 19021016D, 1, XB1JUSD + '-' + LY + '-001',
          XCurrencyDepositedOnCurrencyAccount,
          3, XWWBUSD, -40000, '', '', 0, '', 19021016D, false);
        InsertDailyEntry(
          XPayment, XWWBUSD, 2, '01863656', 19021016D, 1, XB1JUSD + '-' + LY + '-002',
          XContractualPayment011007,
          3, XWWBUSD, 38235.48, '', '', 0, '', 19021016D, true);
        InsertDailyEntry(
          XPayment, XWWBUSD, 0, '57-2000', 19030119D, 0, XB1JUSD + '-' + CY + '-001',
          StrSubstNo(XPurchOfCurrencyDepositedOnCurrAccount, '113 647.90', XDollars),
          3, XWWBUSD, -113647.9, '', '', 0, '', 19030119D, false);
        InsertDailyEntry(
          XPayment, XWWBEUR, 1, '49633663', 19030123D, 1, XB1JEUR + '-' + CY + '-002',
          XPaymentReceivedFromCustomer,
          3, XWWBEUR, -878.85, '', '', 0, '', 19030123D, false);
        InsertDailyEntry(
          XPayment, XWWBEUR, 0, '57-2000', 19030119D, 0, XB1JEUR + '-' + CY + '-001',
          StrSubstNo(XPurchOfCurrencyDepositedOnCurrAccount, '188 534.25', XEuro),
          3, XWWBEUR, -188534.25, '', '', 0, '', 19030119D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, XVSH + '002', 19021002D, 0, XB2JRUR + '-' + LY + '-001',
          XReceiptOfDepositFromShareholder,
          3, XWWBRUR, -4000000, '', '', 0, '', 19021002D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, XVLE + '012', 19021008D, 1, XB2RUR + '-' + LY + '-001',
          XContractPaymentCMP,
          3, XWWBRUR, 3540000, '', '', 0, '', 19021008D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, XVBL + '005', 19021118D, 0, XB2JRUR + '-' + LY + '-002',
          StrSubstNo(XLoanReceivedByAgreement, '12', '11.17.07'),
          3, XWWBRUR, -20000000, '', '', 0, '', 19021118D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, XVLE + '012', 19021225D, 1, XB2RUR + '-' + LY + '-002',
          XContractPaymentCMP,
          3, XWWBRUR, 8260000, '', '', 2, XPI + '-' + LY + '-00047', 19021225D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, XVSH + '005', 19030125D, 0, XB2JRUR + '-' + LY + '-003',
          XPaymentByTreasurySharesFollowÚnOffering,
          3, XWWBRUR, -14000000, '', '', 0, '', 19030125D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, XVLE + '013', 19021025D, 1, XB2RUR + '-' + LY + '-003',
          XAdvPaymentForCustoms,
          3, XWWBRUR, 600000, '', '', 0, '', 19020125D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, XCLE + '004', 19021025D, 1, XB2JRUR + '-' + LY + '-004',
          XAdvPaymentForInvoice,
          3, XWWBRUR, -600000, '', '', 0, '', 19020125D, true);
        InsertDailyEntry(
          XPayment, XWWBRUR, 0, '57-2000', 19030119D, 0, XBANK2,
          StrSubstNo(XCurrencyPurchase, '-$113647,9'),
          3, XWWBRUR, 2769269.74, '', '', 0, '', 19030119D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 0, '57-2000', 19030119D, 0, XBANK1,
          StrSubstNo(XCurrencyPurchase, XEuro + ' 188534,25'),
          3, XWWBRUR, 6794566.98, '', '', 0, '', 19030119D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, '20000', 19030112D, 1, '2594', XPaymentOfAccountsReceivable,
          3, XWWBRUR, -1695444.82, '', '', 0, '', 19030112D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, '20000', 19030112D, 1, '2594', XPaymentOfAccountsReceivable,
          3, XWWBRUR, -1017266.89, '', '', 0, '', 19030112D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, '20000', 19030112D, 1, '2594', XPaymentOfAccountsReceivable,
          3, XWWBRUR, -2204078.26, '', '', 0, '', 19030112D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, '10000', 19030115D, 1, '2596', XPaymentOfAccountsReceivable,
          3, XWWBRUR, -1017266.89, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, '10000', 19030115D, 1, '2596', XPaymentOfAccountsReceivable,
          3, XWWBRUR, -2034533.78, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, '10000', 19030115D, 1, '2596', XPaymentOfAccountsReceivable,
          3, XWWBRUR, -2712711.7, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, '10000', 19030106D, 1, XPREP + '001', XAdvanceReceivedFromCust,
          3, XWWBRUR, -13050.0, '', '', 0, '', 19030106D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, '10000', 19030116D, 1, XPREP + '002', XAdvanceReceivedFromCust,
          3, XWWBRUR, -1020.1, '', '', 0, '', 19030116D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 1, '20000', 19030104D, 1, XPREP + '003', XAdvanceReceivedFromCust,
          3, XWWBRUR, -500, '', '', 0, '', 19030104D, false);

        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127914', 19020101D, 1, '108009', StrSubstNo(XPaymentOrderFromDate, '108009', CA.AdjustDate(19020101D)),
          3, XWWBRUR, 1506379.1, '', '', 2, XPI + '-' + LY + '-00001', 19020101D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020101D, 1, '108010', StrSubstNo(XPaymentOrderFromDate, '108010', CA.AdjustDate(19020101D)),
          3, XWWBRUR, 331403.4, '', '', 2, XPI + '-' + LY + '-00002', 19020101D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020131D, 1, '108001', StrSubstNo(XPaymentOrderFromDate, '108001', CA.AdjustDate(19020130D)),
          3, XWWBRUR, 122938.06, '', '', 2, XPI + '-' + LY + '-00003', 19020131D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020201D, 1, '108011', StrSubstNo(XPaymentOrderFromDate, '108011', CA.AdjustDate(19020201D)),
          3, XWWBRUR, 277183.22, '', '', 2, XPI + '-' + LY + '-00004', 19020201D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020201D, 1, '108012', StrSubstNo(XPaymentOrderFromDate, '108012', CA.AdjustDate(19020201D)),
          3, XWWBRUR, 438627.71, '', '', 2, XPI + '-' + LY + '-00005', 19020201D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020228D, 1, '108002', StrSubstNo(XPaymentOrderFromDate, '108002', CA.AdjustDate(19020228D)),
          3, XWWBRUR, 36334.91, '', '', 2, XPI + '-' + LY + '-00006', 19020228D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020228D, 1, '108005', StrSubstNo(XPaymentOrderFromDate, '108005', CA.AdjustDate(19020228D)),
          3, XWWBRUR, 121116.38, '', '', 2, XPI + '-' + LY + '-00007', 19020228D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127914', 19020228D, 1, '108006', StrSubstNo(XPaymentOrderFromDate, '20053', CA.AdjustDate(19020228D)),
          3, XWWBRUR, 121116.38, '', '', 2, XPI + '-' + LY + '-00008', 19020228D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020301D, 1, '108013', StrSubstNo(XPaymentOrderFromDate, '108013', CA.AdjustDate(19020301D)),
          3, XWWBRUR, 182765.43, '', '', 2, XPI + '-' + LY + '-00009', 19020301D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020401D, 1, '108014', StrSubstNo(XPaymentOrderFromDate, '108014', CA.AdjustDate(19020401D)),
          3, XWWBRUR, 231340.42, '', '', 2, XPI + '-' + LY + '-00010', 19020401D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020430D, 1, '108003', StrSubstNo(XPaymentOrderFromDate, '108003', CA.AdjustDate(19020430D)),
          3, XWWBRUR, 24226.11, '', '', 2, XPI + '-' + LY + '-00011', 19020430D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127914', 19020501D, 1, '108015', StrSubstNo(XPaymentOrderFromDate, '108015', CA.AdjustDate(19020501D)),
          3, XWWBRUR, 2543741.34, '', '', 2, XPI + '-' + LY + '-00012', 19020501D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127904', 19020531D, 1, '108004', StrSubstNo(XPaymentOrderFromDate, '108004', CA.AdjustDate(19020531D)),
          3, XWWBRUR, 72646.04, '', '', 2, XPI + '-' + LY + '-00013', 19020531D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127914', 19020531D, 1, '108007', StrSubstNo(XPaymentOrderFromDate, '108007', CA.AdjustDate(19020531D)),
          3, XWWBRUR, 36323.02, '', '', 2, XPI + '-' + LY + '-00014', 19020531D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127914', 19020601D, 1, '108016', StrSubstNo(XPaymentOrderFromDate, '108016', CA.AdjustDate(19020601D)),
          3, XWWBRUR, 905503.68, '', '', 2, XPI + '-' + LY + '-00015', 19020601D, '');
        InsertDailyEntry2(
          XPayment, XWWBRUR, 2, '44127914', 19020630D, 1, '108008', StrSubstNo(XPaymentOrderFromDate, '108008', CA.AdjustDate(19020630D)),
          3, XWWBRUR, 24420.43, '', '', 2, XPI + '-' + LY + '-00016', 19020630D, '');

        InsertDailyEntry(
          XPayment, XWWBRUR, 2, '10000', 19030111D, 1, '2593', XPaymentOfAccountsPayable,
          3, XWWBRUR, 3224367.3, '', '', 0, '', 19030111D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, '20000', 19030115D, 1, '2597', XPaymentOfAccountsPayable,
          3, XWWBRUR, 3439325.12, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, '20000', 19030125D, 1, '2603', XPaymentOfAccountsPayable,
          3, XWWBRUR, 3439325.12, '', '', 0, '', 19030125D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, '30000', 19030125D, 1, '2604', XPaymentOfAccountsPayable,
          3, XWWBRUR, 3009409.48, '', '', 0, '', 19030125D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, '10000', 19030103D, 1, '6P-001', XAdvanceTransferedToVendor,
          3, XWWBRUR, 12000, '', '', 0, '', 19030103D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, '10000', 19030106D, 1, '6P-002', XAdvanceTransferedToVendor,
          3, XWWBRUR, 2050, '', '', 0, '', 19030106D, false);
        InsertDailyEntry(
          XPayment, XWWBRUR, 2, '10000', 19030116D, 1, '6P-003', XAdvanceTransferedToVendor,
          3, XWWBRUR, 9870, '', '', 0, '', 19030116D, false);

        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19021002D, 1, XB1JRUR + '-' + LY + '-001',
          XCommissionWrittenOffByBank,
          3, XNBL, 8700, '', '', 0, '', 19021002D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '001', 19021005D, 1, XB1RUR + '-' + LY + '-001',
          StrSubstNo(XPaymentInvoiceFromDate, '328', CA.AdjustDate(19031005D), XPODomino),
          3, XNBL, 76700, '', '', 0, '', 19021005D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '002', 19021006D, 1, XB1RUR + '-' + LY + '-002',
          StrSubstNo(XPaymentInvoiceFromDate, '862', CA.AdjustDate(19021006D), XCashRegister),
          3, XNBL, 11800, '', '', 0, '', 19021006D, false);
        InsertDailyEntry(
          XPayment, XNBL, 1, XCLE + '001', 19021110D, 1, XB1JRUR + '-' + LY + '-002',
          XAdvanceForSouvenirs,
          3, XNBL, -118000, '', '', 2, XSI + '-' + LY + '-00002', 19021110D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '001', 19021015D, 0, XB1JRUR + '-' + LY + '-003',
          StrSubstNo(XShortTermCreditReceivedUntilDate, CA.AdjustDate(19030115D)),
          3, XNBL, -15000000, '', '', 0, '', 19021015D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '002', 19021015D, 1, XB1RUR + '-' + LY + '-003',
          StrSubstNo(XMoneyTransferOnDepositByAgreement, '51', CA.AdjustDate(19021015D)),
          3, XNBL, 2000000, '', '', 0, '', 19021015D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '004', 19021015D, 1, XB1RUR + '-' + LY + '-004',
          StrSubstNo(XPaymentInvoiceFromDate, '50', CA.AdjustDate(19021015D), XWorkingClothes),
          3, XNBL, 15450, '', '', 0, '', 19021015D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19021015D, 1, XB1JRUR + '-' + LY + '-004',
          XCommissionWrittenOffByBank,
          3, XNBL, 225, '', '', 0, '', 19021015D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '57-1000', 19021016D, 1, XB1JRUR + '-' + LY + '-005',
          XMoneyTransferForCurrencyPurchase,
          3, XNBL, 1000000, '', '', 0, '', 19021016D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '003', 19021016D, 1, XB1RUR + '-' + LY + '-005',
          StrSubstNo(XPrepaymentForLeaseByAgreement, '315', CA.AdjustDate(19021015D)),
          3, XNBL, 375000, '', '', 0, '', 19021016D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19021016D, 1, XB1JRUR + '-' + LY + '-006',
          XComissionWrittenOffForCurrencyPurchase,
          3, XNBL, 5000, '', '', 0, '', 19021016D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '005', 19021021D, 1, XB1RUR + '-' + LY + '-006',
          StrSubstNo(XPaymentForInstallationWorkByActFromDate, CA.AdjustDate(19021020D)),
          3, XNBL, 60000, '', '', 2, XPI + '-' + LY + '-00027', 19021021D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '006', 19021022D, 1, XB1RUR + '-' + LY + '-007',
          StrSubstNo(XPrepaymentInvoiceFromDate, '731', CA.AdjustDate(19021022D)),
          3, XNBL, 590000, '', '', 0, '', 19021022D, true);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '002%', 19021031D, 0, XB1JRUR + '-' + LY + '-007',
          StrSubstNo(XPercentageFeeFromBankDeposit, XOctober, LastYear),
          3, XNBL, -1875, '', '', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '001%', 19021031D, 1, XB1RUR + '-' + LY + '-008',
          StrSubstNo(XPaymentOfInterestForCredit, XOctober, LastYear),
          3, XNBL, 98630.14, '', '', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '001', 19021031D, 1, XB1RUR + '-' + LY + '-009',
          StrSubstNo(XPaymentOfPIT, XOctober, LastYear),
          3, XNBL, 34320, '', '', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '002', 19021031D, 1, XB1RUR + '-' + LY + '-010',
          StrSubstNo(XPaymentOfSIC, '2,9%', XOctober, LastYear),
          3, XNBL, 6264, '', '9122000', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '003', 19021031D, 1, XB1RUR + '-' + LY + '-011',
          StrSubstNo(XPaymentOfSIC, '0,2%', XOctober, LastYear),
          3, XNBL, 432, '', '9122000', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '005', 19021031D, 1, XB1RUR + '-' + LY + '-013',
          StrSubstNo(XPaymentOfPFInsuransePensionPart, XOctober, LastYear),
          3, XNBL, 33180, '', '9122000', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '006', 19021031D, 1, XB1RUR + '-' + LY + '-014',
          StrSubstNo(XPaymentOfPFAccumulatedPensionPart, XOctober, LastYear),
          3, XNBL, 3780, '', '9122000', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '007', 19021031D, 1, XB1RUR + '-' + LY + '-015',
          StrSubstNo(XPaymentForFederalFOMI, '1,1%', XOctober, LastYear),
          3, XNBL, 2904, '', '9122000', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '008', 19021031D, 1, XB1RUR + '-' + LY + '-016',
          StrSubstNo(XPaymentForLocalFOMI, '2,9%', XOctober, LastYear),
          3, XNBL, 5280, '', '9122000', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19021031D, 1, XB1JRUR + '-' + LY + '-008',
          XCommissionWrittenOffByBank,
          3, XNBL, 435, '', '', 0, '', 19021031D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '007', 19021101D, 1, XB1RUR + '-' + LY + '-017',
          StrSubstNo(XPaymentOfInsurancePremium12MonthCTP, CA.AdjustDate(19021101D)),
          3, XNBL, 300000, '', '', 0, '', 19021001D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, '71-001', 19021102D, 1, XB1RUR + '-' + LY + '-018',
          XMoneyTransferForTravelAllowance,
          3, XNBL, 50000, '', '', 0, '', 19021002D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '008', 19021103D, 1, XB1RUR + '-' + LY + '-019/1',
          StrSubstNo(XPaymentInvoiceFromDate, '461,462', CA.AdjustDate(19021015D), XEquipment),
          3, XNBL, 440621.63, '', '', 2, XPI + '-' + LY + '-00022', 19021103D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '008', 19021103D, 1, XB1RUR + '-' + LY + '-019/2',
          StrSubstNo(XPaymentInvoiceFromDate, '461,462', CA.AdjustDate(19021015D), XEquipment),
          3, XNBL, 17467.75, '', '', 2, XPI + '-' + LY + '-00023', 19021103D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVFI + '001', 19021103D, 1, XB1RUR + '-' + LY + '-020',
          StrSubstNo(XPaymentOfSohoVineriBillByAgreement, '03', CA.AdjustDate(19021103D)),
          3, XNBL, 4000000, '', '', 0, '', 19021103D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVFI + '003', 19021110D, 1, XB1RUR + '-' + LY + '-021',
          StrSubstNo(XGrantingOfLoandByAgreement, '1/08', CA.AdjustDate(19021110D)),
          3, XNBL, 6000000, '', '', 0, '', 19021110D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19021115D, 1, XB1JRUR + '-' + LY + '-009',
          XCommissionWrittenOffByBank,
          3, XNBL, 225, '', '', 0, '', 19021115D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '008', 19021121D, 1, XB1RUR + '-' + LY + '-022',
          StrSubstNo(XPaymentInvoiceFromDate, '588', CA.AdjustDate(19021116D), XEquipment),
          3, XNBL, 65364.84, '', '', 2, XPI + '-' + LY + '-00038', 19021121D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVEM + '001', 19021127D, 1, XB1RUR + '-' + LY + '-023',
          StrSubstNo(XGrantingOfLoandByAgreement, '2/07', CA.AdjustDate(19021127D)),
          3, XNBL, 435000, '', '', 0, '', 19021127D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '002%', 19021130D, 0, XB1JRUR + '-' + LY + '-010',
          StrSubstNo(XPercentageFeeFromBankDeposit, XNovember, LastYear),
          3, XNBL, -3750, '', '', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '001%', 19021130D, 1, XB1RUR + '-' + LY + '-024',
          StrSubstNo(XPaymentOfInterestForCredit, XNovember, LastYear),
          3, XNBL, 184931.51, '', '', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '001', 19021130D, 1, XB1RUR + '-' + LY + '-025',
          StrSubstNo(XPaymentOfPIT, XNovember, LastYear),
          3, XNBL, 34320, '', '', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '002', 19021130D, 1, XB1RUR + '-' + LY + '-026',
          StrSubstNo(XPaymentOfSIC, '2,9%', XNovember, LastYear),
          3, XNBL, 6264, '', '9122000', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '003', 19021130D, 1, XB1RUR + '-' + LY + '-027',
          StrSubstNo(XPaymentOfSIC, '0,2%', XNovember, LastYear),
          3, XNBL, 432, '', '9122000', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '005', 19021130D, 1, XB1RUR + '-' + LY + '-029',
          StrSubstNo(XPaymentOfPFInsuransePensionPart, XNovember, LastYear),
          3, XNBL, 33180, '', '9122000', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '006', 19021130D, 1, XB1RUR + '-' + LY + '-030',
          StrSubstNo(XPaymentOfPFAccumulatedPensionPart, XNovember, LastYear),
          3, XNBL, 3780, '', '9122000', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '007', 19021130D, 1, XB1RUR + '-' + LY + '-031',
          StrSubstNo(XPaymentForFederalFOMI, '1,1%', XNovember, LastYear),
          3, XNBL, 2904, '', '9122000', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '008', 19021130D, 1, XB1RUR + '-' + LY + '-032',
          StrSubstNo(XPaymentForLocalFOMI, '2,9%', XNovember, LastYear),
          3, XNBL, 5280, '', '9122000', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19021130D, 1, XB1JRUR + '-' + LY + '-011',
          XComissionWrittenOffForCurrencyPurchase,
          3, XNBL, 420, '', '', 0, '', 19021130D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '009', 19021202D, 1, XB1RUR + '-' + LY + '-033',
          StrSubstNo(XPaymentOfServiceSoftwareReg, '189/08', CA.AdjustDate(19021202D)),
          3, XNBL, 10000, '', '', 0, '', 19021202D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVFI + '002', 19021206D, 1, XB1RUR + '-' + LY + '-034',
          XSouthRidgeShareCapitalPayment,
          3, XNBL, 1500000, '', '', 0, '', 19021206D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '010', 19021213D, 1, XB1RUR + '-' + LY + '-035',
          StrSubstNo(XPaymentOfServiceBuildingRevaluation, CA.AdjustDate(19021213D)),
          3, XNBL, 53100, '', '', 2, XPI + '-' + LY + '-00044', 19021213D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '002', 19021213D, 0, XB1JRUR + '-' + LY + '-011',
          XReceiptOfFundsFromBankDeposit,
          3, XNBL, -2000000, '', '', 0, '', 19021213D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVFI + '001%', 19021215D, 0, XB1JRUR + '-' + LY + '-012',
          XReceiptOfInterestOnSohoVineriBill,
          3, XNBL, -57534.24, '', '', 0, '', 19021215D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVFI + '001', 19021215D, 0, XB1JRUR + '-' + LY + '-013',
          XReceiptOfPaymentOnSohoVineriBill,
          3, XNBL, -5000000, '', '', 0, '', 19021215D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '002%', 19021215D, 0, XB1JRUR + '-' + LY + '-014',
          StrSubstNo(XReceiptOfInterestOnBankDeposit, XNovember, LastYear),
          3, XNBL, -1875, '', '', 0, '', 19021215D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19021215D, 1, XB1JRUR + '-' + LY + '-015',
          XCommissionWrittenOffByBank,
          3, XNBL, 225, '', '', 0, '', 19021215D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '011', 19021228D, 1, XB1RUR + '-' + LY + '-036',
          StrSubstNo(XPaymentInvoiceFromDate, '119', CA.AdjustDate(19021007D)),
          3, XNBL, 1284552.72, '', '', 2, XPI + '-' + LY + '-00022', 19021228D, false);
        InsertDailyEntry(
          XPayment, XNBL, 1, XCLE + '001', 19021228D, 1, XB1JRUR + '-' + LY + '-016',
          StrSubstNo(XAdvanceOnInvoiceForSouvenirs, '07/008', CA.AdjustDate(19021228D)),
          3, XNBL, -236000, '', '', 0, '', 19021228D, true);
        InsertDailyEntry(
          XPayment, XNBL, 1, XCLE + '003', 19021229D, 1, XB1JRUR + '-' + LY + '-017',
          StrSubstNo(XPaymentInvoiceFromDate, '12', XComputers, CA.AdjustDate(19021228D)),
          3, XNBL, -122720, '', '', 2, XSI + '-' + LY + '-00006', 19021229D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '001%', 19021231D, 1, XB1RUR + '-' + LY + '-037',
          StrSubstNo(XPaymentOfInterestForCredit, XDecember, LastYear),
          3, XNBL, 191095.89, '', '', 0, '', 19021231D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '001', 19021231D, 1, XB1RUR + '-' + LY + '-038',
          StrSubstNo(XPaymentOfPIT, XDecember, LastYear),
          3, XNBL, 28080, '', '', 0, '', 19021231D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '002', 19021231D, 1, XB1RUR + '-' + LY + '-039',
          StrSubstNo(XPaymentOfSIC, '2,9%', XDecember, LastYear),
          3, XNBL, 6264, '', '9122000', 0, '', 19021231D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '003', 19021231D, 1, XB1RUR + '-' + LY + '-040',
          StrSubstNo(XPaymentOfSIC, '0,2%', XDecember, LastYear),
          3, XNBL, 432, '', '9122000', 0, '', 19021231D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '005', 19021231D, 1, XB1RUR + '-' + LY + '-042',
          StrSubstNo(XPaymentOfPFInsuransePensionPart, XDecember, LastYear),
          3, XNBL, 29340, '', '9122000', 0, '', 19021231D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '006', 19021231D, 1, XB1RUR + '-' + LY + '-043',
          StrSubstNo(XPaymentOfPFAccumulatedPensionPart, XDecember, LastYear),
          3, XNBL, 900, '', '9122000', 0, '', 19021231D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '007', 19021231D, 1, XB1RUR + '-' + LY + '-044',
          StrSubstNo(XPaymentForFederalFOMI, XDecember, LastYear),
          3, XNBL, 2376, '', '9122000', 0, '', 19021231D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '008', 19021231D, 1, XB1RUR + '-' + LY + '-045',
          StrSubstNo(XPaymentForLocalFOMI, XDecember, LastYear),
          3, XNBL, 4320, '', '9122000', 0, '', 19021231D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19030110D, 1, XB1JRUR + '-' + LY + '-018',
          XComissionWrittenOffForCurrencyPurchase,
          3, XNBL, 345, '', '', 0, '', 19030110D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '004', 19030112D, 0, XB1JRUR + '-' + LY + '-019',
          StrSubstNo(XLoanReceivedByAgreement, '9/01', CA.AdjustDate(19030111D), XNordeTraders),
          3, XNBL, -1000000, '', '', 0, '', 19030112D, false);
        InsertDailyEntry(
          XPayment, XNBL, 3, XWWBRUR, 19030112D, 1, XB1JRUR + '-' + LY + '-020',
          XReplenishmentOfAccount,
          3, XNBL, -10000000, '', '', 0, '', 19030112D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '012', 19030115D, 1, XB1RUR + '-' + CY + '-001',
          StrSubstNo(XPaymentForBuildingRenovationByAgr, '324', CA.AdjustDate(19021201D)),
          3, XNBL, 377600, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '001', 19030115D, 1, XB1RUR + '-' + CY + '-002',
          XSohoVineriCreditRepaid,
          3, XNBL, 15000000, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVBL + '001%', 19030115D, 1, XB1RUR + '-' + CY + '-003',
          StrSubstNo(XPaymentOfInterestForCredit, XJanuary, LastYear),
          3, XNBL, 92465.75, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19030115D, 1, XB1JRUR + '-' + LY + '-021',
          XCommissionWrittenOffByBank,
          3, XNBL, 225, '', '', 0, '', 19030115D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVLE + '013', 19030120D, 1, XB1RUR + '-' + CY + '-004',
          XAdvPaymentForCustoms,
          3, XNBL, 570000, '', '', 0, '', 19030120D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '001', 19030131D, 1, XB1RUR + '-' + CY + '-005',
          StrSubstNo(XPaymentOfPIT, XJanuary, CurrYear),
          3, XNBL, 28080, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '002', 19030131D, 1, XB1RUR + '-' + CY + '-006',
          StrSubstNo(XPaymentOfSIC, '2,9%', XJanuary, CurrYear),
          3, XNBL, 6264, '', '9122000', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '003', 19030131D, 1, XB1RUR + '-' + CY + '-007',
          StrSubstNo(XPaymentOfSIC, '0,2%', XJanuary, CurrYear),
          3, XNBL, 432, '', '9122000', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '005', 19030131D, 1, XB1RUR + '-' + CY + '-009',
          StrSubstNo(XPaymentOfPFInsuransePensionPart, XJanuary, CurrYear),
          3, XNBL, 29340, '', '9122000', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '006', 19030131D, 1, XB1RUR + '-' + CY + '-010',
          StrSubstNo(XPaymentOfPFAccumulatedPensionPart, XJanuary, CurrYear),
          3, XNBL, 900, '', '9122000', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '007', 19030131D, 1, XB1RUR + '-' + CY + '-011',
          StrSubstNo(XPaymentForFederalFOMI, '1,1%', CurrYear),
          3, XNBL, 2376, '', '9122000', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '008', 19030131D, 1, XB1RUR + '-' + CY + '-012',
          StrSubstNo(XPaymentForLocalFOMI, '2,9%', XJanuary, CurrYear),
          3, XNBL, 4320, '', '9122000', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 0, '91-2317', 19030131D, 1, XB1JRUR + '-' + LY + '-022',
          XCommissionWrittenOffByBank,
          3, XNBL, 345, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '001', 19030131D, 1, XB1RUR + '-' + CY + '-013',
          StrSubstNo(XPaymentOfPITFromDividends, '9%'),
          3, XNBL, 4028, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '011', 19030131D, 1, XB1RUR + '-' + CY + '-014',
          StrSubstNo(XPaymentOfDividentTaxRusLegalEntity, '9%'),
          3, XNBL, 42816, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '011', 19030131D, 1, XB1RUR + '-' + CY + '-015',
          StrSubstNo(XPaymentOfIncomeTax4Quarter, LastYear),
          3, XNBL, 148095, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XTAX + '012', 19030131D, 1, XB1RUR + '-' + CY + '-016',
          StrSubstNo(XPaymentOfIncomeTax4Quarter, LastYear),
          3, XNBL, 398718, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVSH + '007', 19030131D, 1, XB1RUR + '-' + CY + '-017',
          StrSubstNo(XDividendPaymentForYear, LastYear),
          3, XNBL, 54115, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVSH + '008', 19030131D, 1, XB1RUR + '-' + CY + '-018',
          StrSubstNo(XDividendPaymentForYear, LastYear),
          3, XNBL, 361137, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVSH + '009', 19030131D, 1, XB1RUR + '-' + CY + '-019',
          StrSubstNo(XDividendPaymentForYear, LastYear),
          3, XNBL, 11173, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVSH + '010', 19030131D, 1, XB1RUR + '-' + CY + '-020',
          StrSubstNo(XDividendPaymentForYear, LastYear),
          3, XNBL, 6494, '', '', 0, '', 19030131D, false);
        InsertDailyEntry(
          XPayment, XNBL, 2, XVSH + '006', 19030131D, 1, XB1RUR + '-' + CY + '-021',
          StrSubstNo(XDividendPaymentForYear, LastYear),
          3, XNBL, 40585, '', '', 0, '', 19030131D, false);

        // FA journal entries
        InsertFAEntry(
          XASSETS, XDEFAULT, 4, XFA + '027', 19021007D, 0, XFA + '-027', XConveyer, 0, '08-3300', 1088604, '', '', 1, XAQUISITION);
        InsertFAEntry(
          XASSETS, XDEFAULT, 4, XFA + '028', 19021031D, 0, XACT + '-' + CY + '-10',
          XObtainedFreeOfChargeAutoGazelle, 0, '98-2000', 589000,
          '', '', 1, XAQUISITION);
        InsertFAEntry(
          XASSETS, XDEFAULT, 4, XFA + '016', 19021230D, 0, XFA + '-016', XValueFormationOfManufBuilding, 0, '08-3300', 10241095.89,
          '', '', 1, XAQUISITION);
        InsertFAEntry(
          XASSETS, XDEFAULT, 4, XIA + '003', 19021220D, 0, XIA + '-003', XValueFormationOfManagementAccounting, 0, '08-3300', 128176, '', '',
          1, XAQUISITION);
        InsertFAEntry(
          XASSETS, XDEFAULT, 4, XFA + '029', 19021231D, 0, XINVACT + '-07', StrSubstNo(XCapitalizedOnFactorOfInventory, XAirConditioner),
          0, '91-1315', 21750,
          '', '', 1, XOPERATION);
        InsertFAEntry(
          XASSETS, XDEFAULT, 4, XFA + '030', 19021231D, 0, XINVACT + '-07', StrSubstNo(XCapitalizedOnFactorOfInventory, XAirConditioner),
          0, '91-1315', 21750, '',
          '', 1, XOPERATION);
        InsertFAEntry(
          XASSETS, XDEFAULT, 4, XFA + '031', 19021231D, 0, XINVACT + '-07', StrSubstNo(XCapitalizedOnFactorOfInventory, XCurtains), 0,
          '91-1315', 42000,
          '', '', 1, XOPERATION);
        InsertFAEntry(
          XASSETS, XDEFAULT, 4, XFA + '032', 19021231D, 0, XINVACT + '-07', StrSubstNo(XCapitalizedOnFactorOfInventory, XCurtains), 0,
          '91-1315', 42000,
          '', '', 1, XOPERATION);

        // Monthly closing operations
        // LOANS
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVFI + '001%', 19021130D, 0, XVEKSPR + '_' + LY + '11', XInterestChargedOnSohoVineriBill,
          0, '91-1102', 38356.16, '', '1201000', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVFI + '003%', 19021130D, 0, XLOANPR + '_' + LY + '11',
          StrSubstNo(XInterestChargedOnLoan, '11', LastYear),
          0, '91-1103', 55890.41, '', '1201000', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVFI + '001%', 19021231D, 0, XVEKSPR + '_' + LY + '12', XInterestChargedOnSohoVineriBill,
          0, '91-1102', 19178.08, '', '1201000', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVFI + '003%', 19021231D, 0, XLOANPR + '_' + LY + '12',
          StrSubstNo(XInterestChargedOnLoan, '11', LastYear),
          0, '91-1103', 86630.14, '', '1201000', 0, '', 0D, false);

        // INSURANCE
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVLE + '007', 19021130D, 0, XINSUR + '_' + LY + '11',
          StrSubstNo(XChargingOfPaymentForBuildingInsurance, '11', LastYear),
          0, '26-9510', -25000, '', '2102200', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVLE + '007', 19021231D, 0, XINSUR + '_' + LY + '12',
          StrSubstNo(XChargingOfPaymentForBuildingInsurance, '12', LastYear),
          0, '26-9510', -25000, '', '2102200', 0, '', 0D, false);

        // CREDPR
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '001%', 19021031D, 0, XLOANPR + '-' + LY + '10',
          StrSubstNo(XInterestChargedOnCreditSohoVineri, '10', LastYear),
          0, '91-2103', -72328.77, '', '2200100', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '001%', 19021031D, 0, XLOANPR + '-0710',
          StrSubstNo(XInterestChargedOnCreditSohoVineri, '10', LastYear),
          0, '91-2104', -26301.37, '', '2200100', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '001%', 19021130D, 0, XCREDPR + '_' + LY + '11',
          StrSubstNo(XInterestChargedOnCreditSohoVineri, '11', LastYear),
          0, '91-2103', -135616.44, '', '2200100', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '001%', 19021130D, 0, XCREDPR + '_' + LY + '11',
          StrSubstNo(XInterestChargedOnCreditSohoVineri, '11', LastYear),
          0, '91-2104', -49315.07, '', '2200100', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '001%', 19021231D, 0, XCREDPR + '_' + LY + '12',
          StrSubstNo(XInterestChargedOnCreditSohoVineri, '12', LastYear),
          0, '91-2103', -140136.99, '', '2200100', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '001%', 19021231D, 0, XCREDPR + '_' + LY + '12',
          StrSubstNo(XInterestChargedOnCreditSohoVineri, '12', LastYear),
          0, '91-2104', -50958.9, '', '2200100', 0, '', 0D, false);

        // DEPOSITPR
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '002%', 19021031D, 0, XDEPOSITPR + '_' + LY + '10',
          StrSubstNo(XInterestChargedOnBankDeposit, '10', LastYear),
          0, '91-1101', 1875, '', '1201000', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '002%', 19021130D, 0, XDEPOSITPR + '_' + LY + '11',
          StrSubstNo(XInterestChargedOnBankDeposit, '11', LastYear),
          0, '91-1101', 3750, '', '1201000', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '002%', 19021231D, 0, XDEPOSITPR + '_' + LY + '12',
          StrSubstNo(XInterestChargedOnBankDeposit, '12', LastYear),
          0, '91-1101', 1875, '', '1201000', 0, '', 0D, false);

        // LOANPR
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '004%', 19030131D, 0, XLOANPR + '_' + CY + '01',
          XNordeTraders,
          0, '91-2103', -57260.27, '', '2200100', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '005%', 19021130D, 0, XLOANPR + '_' + LY + '11',
          StrSubstNo(XInterestChargedOnLongTermLoan, '11', LastYear),
          0, '08-3300', -71232.88, '', '2200100', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 2, XVBL + '005%', 19021230D, 0, XLOANPR + '_' + LY + '12',
          StrSubstNo(XInterestChargedOnLongTermLoan, '12', LastYear),
          0, '08-3300', -169863.01, '', '2200100', 0, '', 0D, false);

        // tax differences
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '09-1000', 19021031D, 0, XTAXDIF + '-0710', XDTAOnDeferredRevenueFreeObtaining,
          0, '68-3130', 141360, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '09-1000', 19021130D, 0, XTAXDIF + '-0711', XDTAOnDefRevenueFreeObtWriteOff,
          0, '68-3130', -2356, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '09-1000', 19021231D, 0, XTAXDIF + '-0712-1', XDTAOnDefRevenueFreeObtWriteOff,
          0, '68-3130', -2356, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '09-1000', 19021231D, 0, XTAXDIF + '-0712-2',
          StrSubstNo(XChargedDTAOnDeprFAFor4Quarter, LastYear),
          0, '68-3130', 68753, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '09-1010', 19030131D, 0, XTAXDIF + '-0801', XDTAFormedForSaleWithLossFA12,
          0, '68-3130', 1170, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0425', 19021231D, 0, XTAXDIF + '-0712-3',
          StrSubstNo(XChargedCTLByAccMemFor4Quarter, LastYear),
          0, '68-3120', 67968, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0420', 19021231D, 0, XTAXDIF + '-0712-4',
          StrSubstNo(XChargedCTAByAccMemFor4Quarter, LastYear),
          0, '68-3120', -27500, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '68-3140', 19021231D, 0, XTAXDIF + '-0712-5',
          StrSubstNo(XChargedDTLOnInterestByCreditFor4Quarter, LastYear),
          0, '77-1000', 57863, '', '', 0, '', 0D, false);

        // Assessed Tax
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-2318', 19020331D, 0, XATAX + '-0703',
          StrSubstNo(XChargedEstateTaxForQuarter, '1', LastYear),
          2, XTAXVEND + '009', 6110, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-2318', 19020630D, 0, XATAX + '-0706',
          StrSubstNo(XChargedEstateTaxForQuarter, '2', LastYear),
          2, XTAXVEND + '009', 13226, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-2318', 19020930D, 0, XATAX + '-0709',
          StrSubstNo(XChargedEstateTaxForQuarter, '3', LastYear),
          2, XTAXVEND + '009', 19689, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-2318', 19021231D, 0, XATAX + '-0712',
          StrSubstNo(XChargedEstateTaxForQuarter, '4', LastYear),
          2, XTAXVEND + '009', 217834, '', '', 0, '', 0D, false);

        // CLOSE MONTHLY OPERATION
        // January
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020131D, 0, XCLOSE + '_26-0901',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '01', LastYear),
          0, '26-3000', 11777.77, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020131D, 0, XCLOSE + '_26-0901',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '01', LastYear),
          0, '26-4000', 2379.13, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020131D, 0, XCLOSE + '_26-0901',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '01', LastYear),
          0, '44-2200', 18888.89, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020131D, 0, XCLOSE + '_26-0901',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '01', LastYear),
          0, '44-2300', 4193.34, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19020131D, 0, XCLOSE + '_90-0901',
          StrSubstNo(XFinancialResult, '01', LastYear),
          0, '90-9000', 37239.13, '', '', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19020131D, 0, XCLOSE + '_91-0901',
          StrSubstNo(XFinancialResult, '01', LastYear),
          0, '99-0200', 5621.85, '', '', 0, '', 0D, false);

        // Feb
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020228D, 0, XCLOSE + '_26-0902',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '02', LastYear),
          0, '26-3000', 72390.98, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020228D, 0, XCLOSE + '_26-0902',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '02', LastYear),
          0, '26-4000', 15030.8, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020228D, 0, XCLOSE + '_26-0902',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '02', LastYear),
          0, '44-2200', 35000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020228D, 0, XCLOSE + '_26-0902',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '02', LastYear),
          0, '44-2300', 7770, '', '2999999', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020228D, 0, XCLOSE + '_26-0902',
          StrSubstNo(XWriteOffTotalExpForMaterialExp, '02', LastYear),
          0, '26-9100', 121116.38, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020228D, 0, XCLOSE + '_26-0902',
          StrSubstNo(XWriteOffTotalExpForDepr, '02', LastYear),
          0, '26-5000', 30548.73, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19020228D, 0, XCLOSE + '_90-0902',
          StrSubstNo(XFinancialResult, '02', LastYear),
          0, '90-9000', 308776.29 - 2479.4, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19020228D, 0, XCLOSE + '_91-0902',
          StrSubstNo(XFinancialResult, '02', LastYear),
          0, '99-0200', -10386.49, '', '', 0, '', 0D, false);

        // March
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020331D, 0, XCLOSE + '_26-0903',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '03', LastYear),
          0, '26-3000', 68700, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020331D, 0, XCLOSE + '_26-0903',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '03', LastYear),
          0, '26-4000', 13805.4, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020228D, 0, XCLOSE + '_26-0903',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '03', LastYear),
          0, '44-2200', 20000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020228D, 0, XCLOSE + '_26-0903',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '03', LastYear),
          0, '44-2300', 4440, '', '2999999', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020331D, 0, XCLOSE + '_26-0903',
          StrSubstNo(XWriteOffTotalExpForDepr, '03', LastYear),
          0, '26-5000', 30548.72, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19020331D, 0, XCLOSE + '_90-0903',
          StrSubstNo(XFinancialResult, '03', LastYear),
          0, '90-9000', 113054.12, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19020331D, 0, XCLOSE + '_91-0903',
          StrSubstNo(XFinancialResult, '03', LastYear),
          0, '99-0200', -10245.68, '', '', 0, '', 0D, false);

        // April
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020430D, 0, XCLOSE + '_26-0904',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '04', LastYear),
          0, '26-3000', 95000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020430D, 0, XCLOSE + '_26-0904',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '04', LastYear),
          0, '26-4000', 18922, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020430D, 0, XCLOSE + '_26-0904',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '04', LastYear),
          0, '44-2200', 40000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020430D, 0, XCLOSE + '_26-0904',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '04', LastYear),
          0, '44-2300', 8880, '', '2999999', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020430D, 0, XCLOSE + '_26-0904',
          StrSubstNo(XWriteOffTotalExpForDepr, '04', LastYear),
          0, '26-5000', 30548.73, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19020430D, 0, XCLOSE + '_90-0904',
          StrSubstNo(XFinancialResult, '04', LastYear),
          0, '90-9000', 193350.73, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19020430D, 0, XCLOSE + '_91-0904',
          StrSubstNo(XFinancialResult, '04', LastYear),
          0, '99-0200', -9078.44, '', '', 0, '', 0D, false);

        // May
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020531D, 0, XCLOSE + '_26-0905',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '05', LastYear),
          0, '26-3000', 26000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020531D, 0, XCLOSE + '_26-0905',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '05', LastYear),
          0, '26-4000', 5432, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020531D, 0, XCLOSE + '_26-0905',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '05', LastYear),
          0, '44-2200', 20000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020531D, 0, XCLOSE + '_26-0905',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '05', LastYear),
          0, '44-2300', 4440, '', '2999999', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-2210', 19020531D, 0, XCLOSE + '_20-0905',
          StrSubstNo(XWriteOffExpOnMaintFA, '05', LastYear),
          0, '20-2910', 72646.04, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-2210', 19020531D, 0, XCLOSE + '_20-0905',
          StrSubstNo(XWriteOffDepr, '05', LastYear),
          0, '20-1400', 2754.05, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020531D, 0, XCLOSE + '_26-0905',
          StrSubstNo(XWriteOffTotalExpForMaterialExp, '05', LastYear),
          0, '26-9100', 36323.02, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020531D, 0, XCLOSE + '_26-0905',
          StrSubstNo(XWriteOffTotalExpForDepr, '05', LastYear),
          0, '26-5000', 30548.72, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19020531D, 0, XCLOSE + '_90-0905',
          StrSubstNo(XFinancialResult, '05', LastYear),
          0, '90-9000', 198143.83, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19020531D, 0, XCLOSE + '_91-0905',
          StrSubstNo(XFinancialResult, '05', LastYear),
          0, '99-0200', 6067.13, '', '', 0, '', 0D, false);

        // June
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020630D, 0, XCLOSE + '_26-0906',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '06', LastYear),
          0, '26-3000', 29848.45, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020630D, 0, XCLOSE + '_26-0906',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '06', LastYear),
          0, '26-4000', 6111.21, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020630D, 0, XCLOSE + '_26-0906',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '06', LastYear),
          0, '44-2200', 20000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020630D, 0, XCLOSE + '_26-0906',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '06', LastYear),
          0, '44-2300', 4440, '', '2999999', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-2210', 19020630D, 0, XCLOSE + '_20-0906',
          StrSubstNo(XWriteOffExpOnMaintFA, '06', LastYear),
          0, '20-2910', 24420.43, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-2210', 19020630D, 0, XCLOSE + '_20-0906',
          StrSubstNo(XWriteOffDepr, '06', LastYear),
          0, '20-1400', 2754.05, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020630D, 0, XCLOSE + '_26-0906',
          StrSubstNo(XWriteOffTotalExpForDepr, '06', LastYear),
          0, '26-5000', 72944.42, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19020630D, 0, XCLOSE + '_90-0906',
          StrSubstNo(XFinancialResult, '06', LastYear),
          0, '90-9000', 160518.56, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19020630D, 0, XCLOSE + '_91-0906',
          StrSubstNo(XFinancialResult, '06', LastYear),
          0, '99-0200', -15644.5, '', '', 0, '', 0D, false);

        // July
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020731D, 0, XCLOSE + '_26-0907',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '07', LastYear),
          0, '26-3000', 61180.08, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020731D, 0, XCLOSE + '_26-0907',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '07', LastYear),
          0, '26-4000', 12702.99, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020731D, 0, XCLOSE + '_26-0907',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '07', LastYear),
          0, '44-2200', 36000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020731D, 0, XCLOSE + '_26-0907',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '07', LastYear),
          0, '44-2300', 7992, '', '2999999', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-2210', 19020731D, 0, XCLOSE + '_20-0907',
          StrSubstNo(XWriteOffDepr, '07', LastYear),
          0, '20-1400', 45722.28, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020731D, 0, XCLOSE + '_26-0907',
          StrSubstNo(XWriteOffTotalExpForDepr, '07', LastYear),
          0, '26-5000', 72944.41, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19020731D, 0, XCLOSE + '_90-0907',
          StrSubstNo(XFinancialResult, '07', LastYear),
          0, '90-9000', 236541.76, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19020731D, 0, XCLOSE + '_91-0907',
          StrSubstNo(XFinancialResult, '07', LastYear),
          0, '99-0200', -6019.82, '', '', 0, '', 0D, false);

        // August
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020831D, 0, XCLOSE + '_26-0908',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '08', LastYear),
          0, '26-3000', 12666.67, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020831D, 0, XCLOSE + '_26-0908',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '08', LastYear),
          0, '26-4000', 2662.5, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020831D, 0, XCLOSE + '_26-0908',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '08', LastYear),
          0, '44-2200', 25333.33, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020831D, 0, XCLOSE + '_26-0908',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '08', LastYear),
          0, '44-2300', 5624.01, '', '2999999', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-2210', 19020831D, 0, XCLOSE + '_20-0908',
          StrSubstNo(XWriteOffDepr, '08', LastYear),
          0, '20-1400', 45722.27, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020831D, 0, XCLOSE + '_26-0908',
          StrSubstNo(XWriteOffTotalExpForDepr, '08', LastYear),
          0, '26-5000', 72944.42, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19020831D, 0, XCLOSE + '_90-0908',
          StrSubstNo(XFinancialResult, '08', LastYear),
          0, '90-9000', 164953.2, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19020831D, 0, XCLOSE + '_91-0908',
          StrSubstNo(XFinancialResult, '08', LastYear),
          0, '99-0200', 1377.62, '', '', 0, '', 0D, false);

        // September
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020930D, 0, XCLOSE + '_26-0909',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '09', LastYear),
          0, '26-3000', 40421.68, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020930D, 0, XCLOSE + '_26-0909',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '09', LastYear),
          0, '26-4000', 8633.61, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020930D, 0, XCLOSE + '_26-0908',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '09', LastYear),
          0, '44-2200', 39076.32, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19020930D, 0, XCLOSE + '_26-0908',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '09', LastYear),
          0, '44-2300', 8674.93, '', '2999999', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-2210', 19020930D, 0, XCLOSE + '_20-0909',
          StrSubstNo(XWriteOffDepr, '09', LastYear),
          0, '20-1400', 45722.28, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19020930D, 0, XCLOSE + '_26-0909',
          StrSubstNo(XWriteOffTotalExpForDepr, '09', LastYear),
          0, '26-5000', 72944.41, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19020930D, 0, XCLOSE + '_90-0909',
          StrSubstNo(XFinancialResult, '09', LastYear),
          0, '90-9000', 215473.23, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19020930D, 0, XCLOSE + '_91-0909',
          StrSubstNo(XFinancialResult, '09', LastYear),
          0, '99-0200', -39173.41, '', '', 0, '', 0D, false);

        // October
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-1210', 19021031D, 0, XCLOSE + '_20-1100',
          StrSubstNo(XWriteoffOperExpForMatExp, '10', LastYear),
          0, '20-1100', 560, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-1210', 19021031D, 0, XCLOSE + '_20-1200',
          StrSubstNo(XWriteoffOperExpForLabourCosts, '10', LastYear),
          0, '20-1200', 151900.34, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-1210', 19021031D, 0, XCLOSE + '_20-1300',
          StrSubstNo(XWriteoffOperExpForLabourCostsForSocialAccess, '10', LastYear),
          0, '20-1300', 15299.09, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021031D, 0, XCLOSE + '_26-0910',
          StrSubstNo(XWriteOffTotalExpForMaterialExp, '10', LastYear),
          0, '26-1000', 22702.97, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021031D, 0, XCLOSE + '_26-0910',
          StrSubstNo(XWriteOffTotalExpForRawMaterials, '10', LastYear),
          0, '26-2000', 4514.27, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021031D, 0, XCLOSE + '_26-0910',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '10', LastYear),
          0, '26-3000', 117454.55, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021031D, 0, XCLOSE + '_26-0910',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '10', LastYear),
          0, '26-4000', 22758.9, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021031D, 0, XCLOSE + '_26-0910',
          StrSubstNo(XWriteOffTotalExpForDepr, '10', LastYear),
          0, '26-5000', 72944.42, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021031D, 0, XCLOSE + '_26-0910',
          StrSubstNo(XWriteOffTotalExpForOtherCosts, '10', LastYear),
          0, '26-9900', 54674.69, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021031D, 0, XCLOSE + '_44-0910',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '10', LastYear),
          0, '44-2200', 22454.55, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021031D, 0, XCLOSE + '_44-0910',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '10', LastYear),
          0, '44-2300', 4984.93, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021031D, 0, XCLOSE + '_44-0910',
          StrSubstNo(XWriteOffDeferrals, '10', LastYear),
          0, '44-2980', 4630.14, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-9000', 19021031D, 0, XCLOSE + '_90-0710',
          StrSubstNo(XFinancialResult, '10', LastYear),
          0, '99-0100', 75260.58 - 2380, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19021031D, 0, XCLOSE + '_91-0910',
          StrSubstNo(XFinancialResult, '10', LastYear),
          0, '99-0200', -120822.5, '', '', 0, '', 0D, false);

        // November
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-1210', 19021130D, 0, XCLOSE + '_20-1200',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '11', LastYear),
          0, '20-1200', 135000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-1210', 19021130D, 0, XCLOSE + '_20-1300',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '11', LastYear),
          0, '20-1300', 17175.1, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021130D, 0, XCLOSE + '_26-0911',
          StrSubstNo(XWriteOffTotalExpForMaterialExp, '11', LastYear),
          0, '26-1000', 24973.27, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021130D, 0, XCLOSE + '_26-0911',
          StrSubstNo(XWriteOffTotalExpForRawMaterials, '11', LastYear),
          0, '26-2000', 40255.45, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021130D, 0, XCLOSE + '_26-0911',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '11', LastYear),
          0, '26-3000', 74000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021130D, 0, XCLOSE + '_26-0911',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '11', LastYear),
          0, '26-4000', 14600, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021130D, 0, XCLOSE + '_26-0911',
          StrSubstNo(XWriteOffTotalExpForDepr, '11', LastYear),
          0, '26-5000', 120471.21, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021130D, 0, XCLOSE + '_26-0911',
          StrSubstNo(XWriteOffTotalExpForTravelAllowance, '11', LastYear),
          0, '26-9200', 38806.6, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021130D, 0, XCLOSE + '_26-0911',
          StrSubstNo(XWriteOffTotalExpNotIntendToTaxPurp, '11', LastYear),
          0, '26-9995', 1500, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021130D, 0, XCLOSE + '_26-0911',
          StrSubstNo(XWriteOffTotalExpForPropertyInsurance, '11', LastYear),
          0, '26-9510', 25000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021130D, 0, XCLOSE + '_26-0911',
          StrSubstNo(XWriteOffTotalExpForOtherCosts, '11', LastYear),
          0, '26-9900', 105932.2, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021130D, 0, XCLOSE + '_44-0911',
          StrSubstNo(XWriteoffCommExpForMatExp, '11', LastYear),
          0, '44-2100', 10000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021130D, 0, XCLOSE + '_44-0911',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '11', LastYear),
          0, '44-2200', 27000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021130D, 0, XCLOSE + '_44-0911',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '11', LastYear),
          0, '44-2300', 5994, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021130D, 0, XCLOSE + '_44-0911',
          StrSubstNo(XWriteOffCommExpensesForDepr, '11', LastYear),
          0, '44-2400', 73944.88, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021130D, 0, XCLOSE + '_44-0911',
          StrSubstNo(XWriteOffDeferrals, '11', LastYear),
          0, '44-2980', 5342.47, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-9000', 19021130D, 0, XCLOSE + '_90-0911',
          StrSubstNo(XFinancialResult, '11', LastYear),
          0, '99-0100', 2284615.79 - 2380, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19021130D, 0, XCLOSE + '_91-0911',
          StrSubstNo(XFinancialResult, '11', LastYear),
          0, '99-0200', -88114.95 - 693, '', '', 0, '', 0D, false);

        // December
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-1210', 19021231D, 0, XCLOSE + '_20-1200',
          StrSubstNo(XWriteoffOperExpForLabourCosts, '12', LastYear),
          0, '20-1200', 135000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-1210', 19021231D, 0, XCLOSE + '_20-1300',
          StrSubstNo(XWriteoffOperExpForLabourCostsForSocialAccess, '12', LastYear),
          0, '20-1300', 15742, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021231D, 0, XCLOSE + '_26-0912',
          StrSubstNo(XWriteOffTotalExpForMaterialExp, '12', LastYear),
          0, '26-1000', 32465.25, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021231D, 0, XCLOSE + '_26-0912',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '12', LastYear),
          0, '26-3000', 26000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021231D, 0, XCLOSE + '_26-0912',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '12', LastYear),
          0, '26-4000', 5432, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021231D, 0, XCLOSE + '_26-0912',
          StrSubstNo(XWriteOffTotalExpForDepr, '12', LastYear),
          0, '26-5000', 124986.46, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021231D, 0, XCLOSE + '_26-0912',
          StrSubstNo(XWriteOffTotalExpForTransportTax, '12', LastYear),
          0, '26-6000', 31671.0, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021231D, 0, XCLOSE + '_26-0912',
          StrSubstNo(XWriteOffTotalExpForPropertyInsurance, '12', LastYear),
          0, '26-9510', 25000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021231D, 0, XCLOSE + '_26-0912',
          StrSubstNo(XWriteOffTotalExpForOtherCosts, '12', LastYear),
          0, '26-9900', 105932.2, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021231D, 0, XCLOSE + '_44-0912',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '12', LastYear),
          0, '44-2200', 27000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021231D, 0, XCLOSE + '_44-0912',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '12', LastYear),
          0, '44-2300', 3624.9, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021231D, 0, XCLOSE + '_44-0912',
          StrSubstNo(XWriteOffCommExpensesForDepr, '12', LastYear),
          0, '44-2400', 73944.88, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021231D, 0, XCLOSE + '_44-0912',
          StrSubstNo(XWriteOffCommExpForRepairAndMaintOfFA, '12', LastYear),
          0, '44-2910', 320000, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021231D, 0, XCLOSE + '_44-0912',
          StrSubstNo(XWriteOffDeferrals, '12', LastYear),
          0, '44-2980', 5520.55, '', '2999999', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '90-9000', 19021231D, 0, XCLOSE + '_90-0912',
          StrSubstNo(XFinancialResult, '12', LastYear),
          0, '99-0100', 98432.76 - 2380, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19021231D, 0, XCLOSE + '_91-0912',
          StrSubstNo(XFinancialResult, '12', LastYear),
          0, '99-0200', 781685.89, '', '', 0, '', 0D, false);

        InsertDailyEntry(
          XGENERAL, XDEFAULT, 0, '68-3110', 19021231D, 0, XCLOSE + '_99-0912',
          StrSubstNo(XChargedProvProfitsTaxExpenseFor4Quarter, LastYear),
          0, '99-0410', -358807, '', '', 0, '', 0D, false);

        // Close Annual operation
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '90-9000', 19021231D, 0, XCLOSE + '-' + LY + '/1',
          StrSubstNo(XReformationBalance, LastYear), -865282.86 + 39685.18, '', '');

        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '90-1110', 19021231D, 0, XCLOSE + '-' + LY + '/1',
          StrSubstNo(XReformationBalance, LastYear), 3362952.67, '', '');

        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '90-1210', 19021231D, 0, XCLOSE + '-' + LY + '/1',
          StrSubstNo(XReformationBalance, LastYear), 2387140, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '90-2110', 19021231D, 0, XCLOSE + '-' + LY + '/1',
          StrSubstNo(XReformationBalance, LastYear), -745274.02, '', '');

        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '90-2210', 19021231D, 0, XCLOSE + '-' + LY + '/1',
          StrSubstNo(XReformationBalance, LastYear), -239741.4, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '90-3110', 19021231D, 0, XCLOSE + '-' + LY + '/1',
          StrSubstNo(XReformationBalance, LastYear), -512992.78, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '90-3210', 19021231D, 0, XCLOSE + '-' + LY + '/1',
          StrSubstNo(XReformationBalance, LastYear), -364140, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '90-6000', 19021231D, 0, XCLOSE + '-' + LY + '/1',
          StrSubstNo(XReformationBalance, LastYear), -895194.12, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '90-7000', 19021231D, 0, XCLOSE + '-' + LY + '/1',
          StrSubstNo(XReformationBalance, LastYear), -2127467.49 - 39685.18, '', '');

        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-9000', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -494573.7, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-1101', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), 7500, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-1102', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), 57534.24, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-1103', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), 142520.55, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-1302', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), 122720, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-1303', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), 5000000, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-1305', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), 5616.8, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-1310', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), 305260.45 + 25365.2, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-1315', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), 19634 + 127500, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-1390', 19021231D, 0, XCLOSE + '_' + LY + '/3'
          , StrSubstNo(XReformationBalance, LastYear), 114583.3, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2103', 19021231D, 0, XCLOSE + '_' + LY + '/3'
          , StrSubstNo(XReformationBalance, LastYear), -348082.2, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2104', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -126575.34, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2302', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -91666.64, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2303', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -4000000, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2305', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -5000, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2310', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -361389.55 - 19576.34, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2312', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -3080, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2317', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -15230, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2318', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -256859, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2330', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -45000.01, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2390', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -4125 - 137499.96, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2410', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -18720, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '91-2420', 19021231D, 0, XCLOSE + '_' + LY + '/3',
          StrSubstNo(XReformationBalance, LastYear), -856.8, '', '');

        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '99-0530', 19021231D, 0, XCLOSE + '_' + LY + '/4',
          StrSubstNo(XReformationBalance, LastYear), -920896.38, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '99-0100', 19021231D, 0, XCLOSE + '_' + LY + '/4',
          StrSubstNo(XReformationBalance, LastYear), 865282.86 - 39685.18, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '99-0200', 19021231D, 0, XCLOSE + '_' + LY + '/4',
          StrSubstNo(XReformationBalance, LastYear), 498789.8 - 5 - 4211.1, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '99-0410', 19021231D, 0, XCLOSE + '_' + LY + '/4',
          StrSubstNo(XReformationBalance, LastYear), -358807, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '99-0425', 19021231D, 0, XCLOSE + '_' + LY + '/4',
          StrSubstNo(XReformationBalance, LastYear), -67968, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '99-0420', 19021231D, 0, XCLOSE + '_' + LY + '/4',
          StrSubstNo(XReformationBalance, LastYear), 27500, '', '');

        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '99-0530', 19021231D, 0, XCLOSE + '_' + LY + '/5',
          StrSubstNo(XReformationBalance, LastYear), 960581.56 - 39685.18, '', '');
        InsertClosingEntry(
          XGENERAL, XDEFAULT, 0, '84-1000', 19021231D, 0, XCLOSE + '_' + LY + '/5',
          StrSubstNo(XReformationBalance, LastYear), -960581.56 + 39685.18, '', '');

        // RECURRING OPERATIONS
        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '006', 19030131D, 0, XDIV + '-' + LY + '-001', StrSubstNo(XChargedDividends, LastYear, XIvanovII), -44600,
          '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '84-1000', '', '7101010', 44600, 0, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '007', 19030131D, 0, XDIV + '-' + LY + '-002', StrSubstNo(XChargedDividends, LastYear, XNordeTraders),
          -59467, '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '84-1000', '', '7101010', 59467, 0, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '008', 19030131D, 0, XDIV + '-' + LY + '-003', StrSubstNo(XChargedDividends, LastYear, XContosoFarm),
          -396854, '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '84-1000', '', '7101010', 396854, 0, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '009', 19030131D, 0, XDIV + '-' + LY + '-004', StrSubstNo(XChargedDividends, LastYear, XGraphicDesign),
          -12278, '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '84-1000', '', '7101010', 12278, 0, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '010', 19030131D, 0, XDIV + '-' + LY + '-005', StrSubstNo(XChargedDividends, LastYear, XTeilspinToys),
          -7136, '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '84-1000', '', '7101010', 7136, 0, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '011', 19030131D, 0, XDIV + '-' + LY + '-006', StrSubstNo(XChargedDividends, LastYear, XCronusIP), -149,
          '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '84-1000', '', '7101010', 149, 0, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '007', 19030131D, 0, XDIV + '-' + LY + '-008', StrSubstNo(XTaxDeductedOnDividends, XNordeTraders), 5352,
          '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3110', '', '7101010', 0, 100, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '008', 19030131D, 0, XDIV + '-' + LY + '-001', StrSubstNo(XTaxDeductedOnDividends, XContosoFarm), 35717,
          '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3110', '', '7101010', 0, 100, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '009', 19030131D, 0, XDIV + '-' + LY + '-001', StrSubstNo(XTaxDeductedOnDividends, XGraphicDesign), 1105,
          '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3110', '', '7101010', 0, 100, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '010', 19030131D, 0, XDIV + '-' + LY + '-001', StrSubstNo(XTaxDeductedOnDividends, XTeilspinToys), 642,
          '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3110', '', '7101010', 0, 100, 0);

        InsertRecurringEntry(
          XDIVIDENDS, 2, XVSH + '011', 19030131D, 0, XDIV + '-' + LY + '-001', StrSubstNo(XTaxDeductedOnDividends, XCronusIP), 13,
          '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-5100', '', '7101010', 0, 100, 0);

        InsertRecurringEntry(
          XCLOSE + '_20', 0, '20-1100', 19021031D, 0, XCLOSE + '_20_07',
          StrSubstNo(XWriteOffRawMaterialsOnCostPrice, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-2210', '', '', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_20', 0, '20-1200', 19021031D, 0, XCLOSE + '_20_07',
          StrSubstNo(XWriteOffExpensesForLabourCosts, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-2110', '', '', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_20', 0, '20-1300', 19021031D, 0, XCLOSE + '_20_07',
          StrSubstNo(XWriteOffSocialAssessmentsToBudget, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-2210', '', '', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_20', 0, '20-1400', 19021031D, 0, XCLOSE + '_20_07',
          StrSubstNo(XWriteOffDepr, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-2210', '', '', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_20', 0, '20-1500', 19021031D, 0, XCLOSE + '_20_07',
          StrSubstNo(XWriteOffOtherCosts, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-2210', '', '', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_20', 0, '20-2100', 19021031D, 0, XCLOSE + '_20_07',
          StrSubstNo(XWriteoffMaterialExpenses, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-2210', '', '', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_20', 0, '20-2100', 19021031D, 0, XCLOSE + '_20_07',
          StrSubstNo(XWriteOffOtherCostsIndirectly, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-2210', '', '', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_26', 0, '26-1000', 19021031D, 0, XCLOSE + '_26_07',
          StrSubstNo(XWriteOffTotalExpForMaterialExp, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-7000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_26', 0, '26-2000', 19021031D, 0, XCLOSE + '_26_07',
          StrSubstNo(XWriteOffTotalExpForRawMaterials, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-7000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_26', 0, '26-3000', 19021031D, 0, XCLOSE + '_26_07',
          StrSubstNo(XWriteOffTotalExpForLabourCosts, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-7000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_26', 0, '26-4000', 19021031D, 0, XCLOSE + '_26_07',
          StrSubstNo(XWriteOffTotalExpForSocialAssess, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-7000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_26', 0, '26-5000', 19021031D, 0, XCLOSE + '_26_07',
          StrSubstNo(XWriteOffTotalExpForDepr, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-7000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_26', 0, '26-6000', 19021031D, 0, XCLOSE + '_26_07',
          StrSubstNo(XWriteOffTotalExpForOtherCosts, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-7000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_44', 0, '44-1100', 19021030D, 0, XCLOSE + '_44_07',
          StrSubstNo(XWriteOffCommExpensesForTransportTax, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-6000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_44', 0, '44-1200', 19021030D, 0, XCLOSE + '_44_07',
          StrSubstNo(XWriteOffCommExpensesForOtherDirectExp, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-6000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_44', 0, '44-2100', 19021030D, 0, XCLOSE + '_44_07',
          StrSubstNo(XWriteoffCommExpForMatExp, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-6000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_44', 0, '44-2200', 19021030D, 0, XCLOSE + '_44_07',
          StrSubstNo(XWriteOffCommExpensesForLabourCosts, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-6000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_44', 0, '44-2300', 19021030D, 0, XCLOSE + '_44_07',
          StrSubstNo(XWriteOffCommExpensesForSocialAssess, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-6000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_44', 0, '44-2400', 19021030D, 0, XCLOSE + '_44_07',
          StrSubstNo(XWriteOffCommExpensesForDepr, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-6000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_44', 0, '44-2980', 19021030D, 0, XCLOSE + '_44_07',
          StrSubstNo(XWriteOffDeferrals, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '90-6000', '', '2999999', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_9091', 0, '90-9000', 19021031D, 0, XCLOSE + '_90_07',
          StrSubstNo(XFinancialResult, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '99-0100', '', '', 1, 0, 0);

        InsertRecurringEntry(
          XCLOSE + '_9091', 0, '91-9000', 19021031D, 0, XCLOSE + '_91_07',
          StrSubstNo(XFinancialResult, '10', LastYear), 0, '', '', 3, '<1M+CM>');
        InsertRecurringAllocation(10000, '99-0200', '', '', 1, 0, 0);

        InsertRecurringEntry(
          XTAXDIFF, 0, '09-1000', 19021231D, 0, XONA + '_' + LY + '04', StrSubstNo(XChargedDTAOnDeferredRevenue, LastYear), 141360, '', '',
          1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3130', '', '2300900', 0, 0, -141360);

        InsertRecurringEntry(
          XTAXDIFF, 0, '09-1000', 19021231D, 0, XONA + '_' + LY + '04', StrSubstNo(XChargedDTAOnDeferredRevenue, LastYear), -4712, '', '',
          1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3130', '', '2300900', 0, 0, 4712);

        InsertRecurringEntry(
          XTAXDIFF, 0, '09-1000', 19021231D, 0, XONA + '_' + LY + '04', StrSubstNo(XChargedDTAOnDepr, LastYear), 68753, '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3130', '', '2300900', 0, 0, -68753);

        InsertRecurringEntry(
          XTAXDIFF, 0, '09-1000', 19021231D, 0, XONA + '_' + LY + '04', StrSubstNo(XChargedDTAOnDepr, LastYear), 0, '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3130', '', '2300900', 1, 0, 0);

        InsertRecurringEntry(
          XTAXDIFF, 0, '77-1000', 19021231D, 0, XONO + '_' + LY + '04', StrSubstNo(XChargedDTLOnInterestByCreditFor4Quarter, LastYear),
          -57863, '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3140', '', '2300900', 0, 0, 57863);

        InsertRecurringEntry(
          XTAXDIFF, 0, '77-1000', 19021231D, 0, XONO + '_' + LY + '04', StrSubstNo(XChargedDTLOnInterestByCreditFor4Quarter, LastYear),
          0, '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3140', '', '2300900', 1, 0, 0);

        InsertRecurringEntry(
          XTAXDIFF, 0, '99-0420', 19021231D, 0, XPNO + '_' + LY + '04', StrSubstNo(XChargedCTLByAccMemFor4Quarter, LastYear), 67968, '',
          '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3120', '', '2300900', 0, 0, -67968);

        InsertRecurringEntry(
          XTAXDIFF, 0, '99-0420', 19021231D, 0, XPNA + '_' + LY + '04', StrSubstNo(XChargedCTLByAccMemFor4Quarter, LastYear), -27500, '',
          '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3120', '', '2300900', 0, 0, 27500);

        InsertRecurringEntry(
          XTAXDIFF, 0, '99-0410', 19021231D, 0, XUN + '_' + LY + '04', StrSubstNo(XChargedProvProfitsTaxExpenseFor4Quarter, LastYear),
          358807, '', '', 1, '<1M+CM>');
        InsertRecurringAllocation(10000, '68-3110', '', '2300900', 0, 0, -358807);
    end;

    procedure InsertEvaluationData()
    var
        CreateBankAccount: Codeunit "Create Bank Account";
        CreateGenJournalBatch: Codeunit "Create Gen. Journal Batch";
    begin
        DemoDataSetup.Get();
        "Entry Balance" := 0;
        "Exactly Balanced" := false;
        InsertDailyEntry(
          XGENERAL, CreateGenJournalBatch.GetDailyJournalBatchName(), 3, CreateBankAccount.GetSavingsBankAccountCode(), 19030119D, 1, 'BANK1', XPaymentDescription1,
          3, CreateBankAccount.GetCheckingBankAccountCode(), -2000.0, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, CreateGenJournalBatch.GetDailyJournalBatchName(), 3, CreateBankAccount.GetSavingsBankAccountCode(), 19030119D, 1, 'BANK2', XPaymentDescription2,
          3, CreateBankAccount.GetCheckingBankAccountCode(), -3000.0, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, CreateGenJournalBatch.GetDailyJournalBatchName(), 3, CreateBankAccount.GetSavingsBankAccountCode(), 19030119D, 1, 'DEPOSIT3', XPaymentDescription3,
          3, CreateBankAccount.GetCheckingBankAccountCode(), -4000.0, '', '', 0, '', 0D, false);
        InsertDailyEntry(
          XGENERAL, CreateGenJournalBatch.GetDailyJournalBatchName(), 3, CreateBankAccount.GetSavingsBankAccountCode(), 19030119D, 1, 'DEPOSIT4', XPaymentDescription4,
          3, CreateBankAccount.GetCheckingBankAccountCode(), -4000.0, '', '', 0, '', 0D, false);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "Gen. Journal Batch": Record "Gen. Journal Batch";
        "FA Setup": Record "FA Setup";
        "General Ledger Setup": Record "General Ledger Setup";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimVal: Record "Dimension Value";
        CA: Codeunit "Make Adjustments";
        DimMgt: Codeunit DimensionManagement;
        "Entry Balance": Decimal;
        "Exactly Balanced": Boolean;
        "Line No.": Integer;
        TaxRegisterSetup: Record "Tax Register Setup";
        XGENERAL: Label 'GENERAL';
        XPayment: Label 'Payment';
        XWWBEUR: Label 'WWB-EUR';
        XBANK1: Label 'BANK1';
        XFA000010: Label 'FA000010';
        XFA000020: Label 'FA000020';
        XFA000030: Label 'FA000030';
        XFA000040: Label 'FA000040';
        XFA000050: Label 'FA000050';
        XFA000060: Label 'FA000060';
        XFA000070: Label 'FA000070';
        XFA000080: Label 'FA000080';
        XFA000090: Label 'FA000090';
        XSTART: Label 'START';
        XDEPR: Label 'DEPR';
        XDEFAULT: Label 'DEFAULT';
        XSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XAREA: Label 'AREA';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XPERIODIC: Label 'PERIODIC';
        XBANKOPEN: Label 'BANK OPEN';
        XVENDOPEN: Label 'VEND OPEN';
        XCUSTOPEN: Label 'CUST OPEN';
        XNBL: Label 'NBL';
        XWWBUSD: Label 'WWB-USD';
        XOpeningEntriesBankAccounts: Label 'Opening Entries, Bank Accounts';
        XOpeningEntry: Label 'Opening Entry';
        XEntries12: Label 'Entries, %1 %2';
        GenJnlEntryDesc: Label '%1 %2';
        XJOBS: Label 'JOB';
        XOpeningSaldoCustomers: Label 'Opening Saldo as of %1, Customers';
        XOpeningSaldoVendors: Label 'Opening Saldo as of %1, Vendors';
        XOpeningSaldoEquityCapital: Label 'Opening Saldo as of %1, Eqt. Capital';
        XMO: Label 'MO';
        XVSH: Label 'VSH';
        XVLE: Label 'VLE';
        XVFI: Label 'VFI';
        XG: Label 'G';
        XVEM: Label 'VEM';
        XTAX: Label 'TAX';
        XVOB: Label 'VOB';
        XCASH: Label 'CASH';
        XCASHRUR: Label 'CASHRUR';
        XCASHORDER: Label 'CASHORDER';
        XICO: Label 'ICO';
        XOCO: Label 'OCO';
        XLT: Label 'LT';
        XEH: Label 'EH';
        XKH: Label 'KH';
        XMH: Label 'MH';
        XB1JUSD: Label 'B1JUSD';
        XB1JEUR: Label 'B1JEUR';
        XB2RUR: Label 'B2RUR';
        XWWBRUR: Label 'WWB-RUR';
        XB2JRUR: Label 'B2JRUR';
        XBANK2: Label 'BANK2';
        XPREP: Label 'PREP';
        XB1JRUR: Label 'B1JRUR';
        XB1RUR: Label 'B1RUR';
        XRECURRING: Label 'RECURRING';
        XDIVIDENDS: Label 'DIVIDENDS';
        XCLOSE: Label 'CLOSE';
        XVEKSPR: Label 'VEKSPR';
        XLOANPR: Label 'LOANPR';
        XTAXDIFF: Label 'TAXDIFF';
        XONA: Label 'ONA';
        XONO: Label 'ONO';
        XPNO: Label 'PNO';
        XPNA: Label 'PNA';
        XUN: Label 'UN';
        XBALREFORM: Label 'BALREFORM';
        XCREDPR: Label 'CREDPR';
        XDEPOSITPR: Label 'DEPOSITPR';
        XINSUR: Label 'INSUR';
        XVBL: Label 'VBL';
        XCLE: Label 'CLE';
        BatchName: Code[10];
        XASSETS: Label 'ASSETS';
        XFA: Label 'FA';
        XIA: Label 'IA';
        XAQUISITION: Label 'AQUISITION';
        XOPERATION: Label 'OPERATION';
        XACT: Label 'ACT';
        XINVACT: Label 'INVACT';
        XDIV: Label 'DIV';
        XSI: Label 'SI';
        XPI: Label 'PI';
        XATAX: Label 'ATAX';
        XTAXDIF: Label 'TAXDIF';
        XTAXVEND: Label 'TAX';
        XUSI: Label 'USI';
        LastYear: Integer;
        CurrYear: Integer;
        LY: Code[2];
        CY: Code[2];
        XIvanovCCGeneration30000: Label 'Ivanov I.I. - CC generation (30000 shares)';
        XNordeTradersCCGeneration40000: Label 'Norde Traders - CC generation (40000 shares)';
        XContosoFarmCCGeneration266941: Label 'Contoso Farm - CC generation (266941 shares)';
        XGraphicDesignCCGeneration8259: Label 'Graphic Design - CC generation (8259 shares)';
        XTeilspinToysCCGeneraion4800: Label 'Teilspin Toys - CC generation (4800 shares)';
        XCurrPurchGainCalulated: Label 'Currency purchase gain has been calculated';
        XAcqOfSharesOfSouthRidgeCC100: Label 'Acquisition of shares of the South Ridge CC - 100%';
        XEarningsOfFirstBillOfSohoVineri: Label 'Earnings of first bill of Soho Vineri';
        XWriteOffBalanceValueOfSohoVineriBill: Label 'Write-off of balance value of Soho Vineri''s bill';
        XSohoVineriBillPresented: Label 'Soho Vineri''s bill has been presented';
        XWriteOffProportionallyChargedDepr: Label 'Write-off of proportionally charged depreciation';
        XGainOnDisposalOfFAContribToAlpineCC: Label 'Gain on disposal of FA - contrib. to CC of Alpine';
        XContribToCCOFAlpineSkyHousePlus: Label 'Contribution to CC of Alpine Sky House+';
        XWriteOffProportionallyChargedDepr0711: Label 'Write-off of prop-ly charged depr.  07.11';
        XVATReinstOnContribToCC: Label 'VAT reinstatement on contribution to CC';
        XWriteOffVATOnCotribToCC: Label 'Write-off of VAT on contribution to CC';
        XVATReinstOnGratuitousPassOfFA: Label 'VAT reinst. of VAT on gratuitous pass of FA';
        XWriteOffVATOnGratuitousPassOfFA: Label 'Write-off of VAT on gratuitous pass of FA';
        XWriteOffShortagesOnGuilty: Label 'Write-off of shortages on guilty';
        XChargingOfTransportTaxForYear: Label 'Charging of transport tax for year %1';
        XCapitalReservesOfFivePctFromNetProfitWasFormed: Label 'Cap. reserv. of 5% from net prof. year %1 formed';
        XTreatmentOBuildingfHypotecationValue: Label 'Treatment of building hypothecation value';
        XReturnFromPledgeCreditAgrStop: Label 'Return from pledge - credit agreement stop';
        XReceiptOfLossFromPurch: Label 'Receipt of loss from purchase of 188534.25 euro';
        XReceiptOfIncomeFromPurch: Label 'Rcpt. of income from purchase of  113647.9 dollars';
        XIncreaseOfCCAtFollowonOffering: Label 'Increase of CC at follow-on offering';
        XIvanovII: Label 'Ivanov I.I.';
        XNewBankOfMoscow: Label 'New bank of Moscow';
        XPetrovPP: Label 'Petrov P.P.';
        XSalaryAdvancePaidForMonth: Label 'Salary advance paid for %1';
        XAdventureWorks: Label 'Adventure Works';
        XOctober: Label 'Oct.';
        XNovember: Label 'Nov.';
        XDecember: Label 'Dec.';
        XJanuary: Label 'Jan.';
        XCronusIP: Label 'Cronus I.P.';
        XSergienkoSergienko: Label 'Sergienko SERGIENKO %1';
        XPopkovaPopkova: Label 'Popkova POPKOVA %1';
        XMarkovaMarkova: Label 'Markova MARKOVA %1';
        XHolodovHolodov: Label 'Holodov HOLODOV %1';
        XAccountability: Label 'XAccountability';
        XInternationalBank: Label 'International bank';
        XCurrencyDepositedOnCurrencyAccount: Label 'Currency is deposited on currency account';
        XContractualPayment011007: Label 'Contractual payment 30_01.10.07';
        XPurchOfCurrencyDepositedOnCurrAccount: Label 'Purch. of curr. is depos. on acc. %1 %2';
        XPaymentReceivedFromCustomer: Label 'Payment is received from customer';
        XDollars: Label 'USD';
        XEuro: Label 'euro';
        XReceiptOfDepositFromShareholder: Label 'Receipt of deposit from shareholder';
        XContractPaymentCMP: Label 'Contractual payment 17-10 from 10.07.07 for CMP';
        XLoanReceivedByAgreement: Label 'Loan is rcvd. by agr. %1, %2 %3';
        "XPaymentByTreasurySharesFollowÚnOffering": Label 'Payment by treasure shares (follow-on offering)';
        XAdvPaymentForCustoms: Label 'Prepayment for customs';
        XAdvPaymentForInvoice: Label 'Prepayment for invoice 08/01/T_10.24.07';
        XCurrencyPurchase: Label 'Currency purchase %1';
        XPaymentOfAccountsReceivable: Label 'Payment of accounts receivable';
        XAdvanceReceivedFromCust: Label 'Advance received from customer';
        XPaymentOrderFromDate: Label 'Payment of order %1 from date %2';
        XPaymentOfAccountsPayable: Label 'Payment of accounts payable';
        XAdvanceTransferedToVendor: Label 'Advance transfered to vendor';
        XCommissionWrittenOffByBank: Label 'Commision written-off by bank';
        XPaymentInvoiceFromDate: Label 'Inv.pmt.%1 ,date %2 for %3';
        XPODomino: Label 'PO Domino agr.32/08';
        XCashRegister: Label 'Cash register';
        XAdvanceForSouvenirs: Label 'Advance for souvenirs';
        XShortTermCreditReceivedUntilDate: Label 'Short-term cred. rcvd. until %1 (15% year)';
        XMoneyTransferOnDepositByAgreement: Label 'Money trans. on deposit,agr. %1,date %2';
        XWorkingClothes: Label 'working clothes';
        XMoneyTransferForCurrencyPurchase: Label 'Money transfer for currency purchase';
        XPrepaymentForLeaseByAgreement: Label 'Prepmt. for lease by agr. %1 from date %2';
        XComissionWrittenOffForCurrencyPurchase: Label 'Comission written-off for currency purchase';
        XPaymentForInstallationWorkByActFromDate: Label 'Pmt. for instal. work by act %1 from date %2';
        XPrepaymentInvoiceFromDate: Label 'Prepmt. inv. %1 from %2 for computers';
        XPercentageFeeFromBankDeposit: Label 'Rcpt. of bank deposit inter.,%1 year %2';
        XPaymentOfInterestForCredit: Label 'Perc. fee for credit for %1 year %2';
        XPaymentOfPIT: Label 'Payment of PIT for %1 year %2';
        XPaymentOfSIC: Label 'Payment of SIC %1 for %2 year %3';
        XPaymentOfPFInsuransePensionPart: Label 'Pmt. of PF insur. pens. part,%1 year %2';
        XPaymentOfPFAccumulatedPensionPart: Label 'Pmt. of PF accum. pens. part,%1 year %2';
        XPaymentForFederalFOMI: Label 'Pmt. for federal FOMI %1 year %2';
        XPaymentForLocalFOMI: Label 'Payment for local FOMI %1 year %2';
        XPaymentOfInsurancePremium12MonthCTP: Label 'Pmt.of insur. prem.,12 m.,agr.CTP-005,%1';
        XMoneyTransferForTravelAllowance: Label 'Money transfer for travel allowance';
        XEquipment: Label 'equipment';
        XPaymentOfSohoVineriBillByAgreement: Label 'Pmt.of SohoVineri''s bill, agr. %1 from %2';
        XGrantingOfLoandByAgreement: Label 'Granting of loan by agr. %1 from date %2';
        XPaymentOfServiceSoftwareReg: Label 'Pmt. of serv. soft. reg.,agr.%1 date %2';
        XSouthRidgeShareCapitalPayment: Label 'South Ridge share capital payment';
        XPaymentOfServiceBuildingRevaluation: Label 'Pmt. of serv. build. reval. agr.,date %1';
        XReceiptOfFundsFromBankDeposit: Label 'Receipt of funds from bank deposit';
        XReceiptOfInterestOnSohoVineriBill: Label 'Receipt of interest on Soho Vineri''s bill';
        XReceiptOfPaymentOnSohoVineriBill: Label 'Receipt of payment on Soho Vineri''s bill';
        XReceiptOfInterestOnBankDeposit: Label 'Rcpt. of inter. on bank dep. for %1 year %2';
        XAdvanceOnInvoiceForSouvenirs: Label 'Advance on invoice %1 from date for souvenirs';
        XComputers: Label 'computers';
        XNordeTraders: Label 'Norde Traders';
        XReplenishmentOfAccount: Label 'Replenishment of account';
        XPaymentForBuildingRenovationByAgr: Label 'Pmt. for build. renov. by agr. %1, date %2';
        XSohoVineriCreditRepaid: Label 'Soho Vineri''s credit repaid';
        XPaymentOfPITFromDividends: Label 'Payment of PIT %1 from dividends';
        XPaymentOfDividentTaxRusLegalEntity: Label 'Pmt. of divident tax Russia, legal entity %1';
        XPaymentOfIncomeTax4Quarter: Label 'Pmt. of income tax for 4 quarter year %1';
        XDividendPaymentForYear: Label 'Dividend payment for year %1';
        XConveyer: Label 'Conveyer';
        XObtainedFreeOfChargeAutoGazelle: Label 'Obraint free of charge - auto Gazelle';
        XValueFormationOfManufBuilding: Label 'Value formation of manufactury building';
        XValueFormationOfManagementAccounting: Label 'Value formation of management accounting';
        XCapitalizedOnFactorOfInventory: Label 'Capitalized on the fact of invent. - %1';
        XAirConditioner: Label 'air conditioner';
        XCurtains: Label 'curtains';
        XInterestChargedOnSohoVineriBill: Label 'Interest charged on Soho Vineri''s bill';
        XInterestChargedOnLoan: Label 'Interest charged for %1. year %2';
        XChargingOfPaymentForBuildingInsurance: Label 'Charg-g of pmt. for buil. insur. %1. year %2';
        XInterestChargedOnCreditSohoVineri: Label 'Inter. chrge. for cred.%1. year%2 Soho Vineri';
        XInterestChargedOnBankDeposit: Label 'Inter. chrge. on bank deposit %1. year %2';
        XInterestChargedOnLongTermLoan: Label 'Inter. chrge. on long-term loan %1. year %2';
        XDTAOnDeferredRevenueFreeObtaining: Label 'Deff. TA on def. revenue. Free obt-g', Comment = 'DTA=Deferred tax assets';
        XDTAOnDefRevenueFreeObtWriteOff: Label 'Deff. TA on def. revenue. Free obt-g. Write-off.', Comment = 'DTA=Deferred tax assets';
        XChargedDTAOnDeprFAFor4Quarter: Label 'Chrge. deff. TA on depr. FA,4 quart., y. %1', Comment = 'DTA=Deferred tax assets';
        XDTAFormedForSaleWithLossFA12: Label 'Deff. TA formed for sale with loss. FA-012', Comment = 'DTA=Deferred tax assets';
        XChargedCTLByAccMemFor4Quarter: Label 'Chrge. CTL by acc. mem.,4 quart., y. %1', Comment = 'CTL = Constant tax liabilities';
        XChargedCTAByAccMemFor4Quarter: Label 'Chrge. CTL by acc. mem. for 4 quart., y. %1', Comment = 'CTA=constant tax assets';
        XChargedDTLOnInterestByCreditFor4Quarter: Label 'Chrge. DTL on inter. by cred.,4 quart., y. %1';
        XChargedEstateTaxForQuarter: Label 'Charged estate tax for quarter %1, year %2';
        XWriteOffTotalExpForLabourCosts: Label 'Write-off tot. expend-s for labor costs %1.%2 y.';
        XWriteOffTotalExpForSocialAssess: Label 'Write-off tot. expend-s for soc.assess. %1.%2 y.';
        XWriteOffCommExpensesForLabourCosts: Label 'Write-off comm. exp-s for labor costs %1.%2 y.';
        XWriteOffCommExpensesForSocialAssess: Label 'Write-off comm. exp-s for soc.assess. %1.%2 y.';
        XFinancialResult: Label 'Financial result %1.%2 year';
        XWriteOffTotalExpForMaterialExp: Label 'Write-off tot. expend-s for mat. exp-s %1.%2 y.';
        XWriteOffTotalExpForDepr: Label 'Write-off tot. expend-s for depr. %1.%2 y.';
        XWriteOffExpOnMaintFA: Label 'Write-off expenses on FA maint. %1.%2 y.';
        XWriteOffDepr: Label 'Write-off depreciation %1.%2 y.';
        XWriteoffOperExpForMatExp: Label 'Write-off oper. exp-s for mat. exp-s %1.%2 y.';
        XWriteoffOperExpForLabourCosts: Label 'Write-off oper. exp-s for labor costs %1.%2 y.';
        XWriteoffOperExpForLabourCostsForSocialAccess: Label 'Write-off oper. exp-s for labor assess. %1.%2 y.';
        XWriteOffTotalExpForRawMaterials: Label 'Write-off tot. expend-s for raw mat-s %1.%2 y.';
        XWriteOffTotalExpForOtherCosts: Label 'Write-off tot. expend-s for other costs %1.%2 y.';
        XWriteOffDeferrals: Label 'Write-off deferrals %1.%2 year ';
        XWriteOffTotalExpForTravelAllowance: Label 'Write-off tot. exp-s for trav. allow. %1.%2 y.';
        XWriteOffTotalExpNotIntendToTaxPurp: Label 'W.-off tot. exp. not int. for tax purp. %1.%2 y.';
        XWriteOffTotalExpForPropertyInsurance: Label 'Write-off tot. exp-s for prop. ins. %1.%2 y.';
        XWriteoffCommExpForMatExp: Label 'Write-off comm. exp-s for mat. exp-s %1.%2 y.';
        XWriteOffCommExpensesForDepr: Label 'Write-off comm. exp-s for depr. %1.%2 y.';
        XWriteOffTotalExpForTransportTax: Label 'W.-off tot. exp. for trav. transp. tax %1.%2 y.';
        XWriteOffCommExpForRepairAndMaintOfFA: Label 'Write-off comm. exp-s for rep. and maint. of FA';
        XChargedProvProfitsTaxExpenseFor4Quarter: Label 'Charged prov. profits tax expense,4 quart. y. %1';
        XReformationBalance: Label 'Reformation balance year %1';
        XChargedDividends: Label 'Charged dividens year %1 %2';
        XContosoFarm: Label 'Contoso Farm';
        XGraphicDesign: Label 'Graphic Design';
        XTeilspinToys: Label 'Teilspin Toys';
        XTaxDeductedOnDividends: Label 'Tax 9% deducted on dividends %1';
        XWriteOffRawMaterialsOnCostPrice: Label 'Write-off raw mat-s on cost price %1.%2 y.';
        XWriteOffExpensesForLabourCosts: Label 'Write-off exp-s for labour costs %1.%2 y.';
        XWriteOffSocialAssessmentsToBudget: Label 'Write-off soc. assess. to budget %1.%2 y.';
        XWriteOffOtherCosts: Label 'Write-off other costs %1.%2 y.';
        XWriteoffMaterialExpenses: Label 'Write-off mat. exp-s %1.%2 y.';
        XWriteOffOtherCostsIndirectly: Label 'Write-off other costs indir-ly %1.%2 y.';
        XWriteOffCommExpensesForTransportTax: Label 'Write-off comm. exp-s for transp. tax %1.%2 y.';
        XWriteOffCommExpensesForOtherDirectExp: Label 'Write-off comm. exp-s for other dir. exp-s';
        XChargedDTAOnDeferredRevenue: Label 'Chrge. DTA on def. revenue,4 quart. y. %1';
        XChargedDTAOnDepr: Label 'Chrge. DTA on depr.,4 quart. y. %1';
        XPaymentDescription1: Label 'Transfer, January';
        XPaymentDescription2: Label 'Transfer of funds for Spring ';
        XPaymentDescription3: Label 'Deposit 3, ';
        XPaymentDescription4: Label 'Deposit 4, ';

    procedure InsertDailyEntry(CurrentJnlTemplateName: Code[10]; CurrentJnlBatchName: Code[10]; "Account Type": Option; "Account No.": Code[20]; Date: Date; "Document Type": Option; "Document No.": Code[20]; Description: Text[100]; "Bal. Account Type": Option; "Bal. Account No.": Code[20]; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20]; "Shortcut Dimension 2 Code": Code[20]; "Applies-to Doc. Type": Option; "Applies-to Doc. No.": Code[20]; "Due Date": Date; Prepayment: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        Date := CA.AdjustDate(Date);
        "Due Date" := CA.AdjustDate("Due Date");
        "General Ledger Setup".Get();

        InitGenJnlLine(GenJournalLine, CurrentJnlTemplateName, CurrentJnlBatchName);
        GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", "Document Type");
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Prepayment, Prepayment);
        if Prepayment then
            if "Account No." = XCLE + '004' then begin
                GenJournalLine.Validate("External Document No.", '12345');
                SalesHeader.Get(SalesHeader."Document Type"::Invoice, XUSI + '-' + LY + '-00002');
                ReleaseSalesDocument.Run(SalesHeader);
                GenJournalLine.Validate("Prepayment Document No.", XUSI + '-' + LY + '-00002');
            end;
        GenJournalLine.Validate("Bal. Account Type", "Bal. Account Type");
        if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"G/L Account" then
            "Bal. Account No." := CA.Convert("Bal. Account No.");
        GenJournalLine.Validate("Bal. Account No.", "Bal. Account No.");

        if "Bal. Account No." = '' then
            if "Exactly Balanced" then begin
                if Abs(("Entry Balance" / Amount + 1) * 100) > 1 then
                    if not
                       Confirm(
                         StrSubstNo(
                           'Difference on Daily entries: %1 on %2\\' +
                           'Do you want to continue?', "Entry Balance" + Amount, Date),
                         true)
                    then
                        Error('Program terminated by the user');
                Amount := -"Entry Balance";
                "Entry Balance" := 0;
                "Exactly Balanced" := false;
            end else
                "Entry Balance" := "Entry Balance" + Amount;
        GenJournalLine.Validate(Amount, Amount);

        GenJournalLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        GenJournalLine.Validate("Applies-to Doc. Type", "Applies-to Doc. Type");
        GenJournalLine.Validate("Applies-to Doc. No.", "Applies-to Doc. No.");
        GenJournalLine.Validate("Due Date", "Due Date");

        GenJournalLine.Description := CopyStr(Description, 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine.Validate(Amount, Amount);

        GenJournalLine.Insert();
    end;

    procedure InsertCustLine("Account No.": Code[20]; "Document No.": Code[20]; "Due Date": Date; Quantity: Decimal; Amount: Decimal; "External Document No.": Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        "Due Date" := CA.AdjustDate("Due Date");

        InitGenJnlLine(GenJournalLine, XSTART, XCUSTOPEN);
        GenJournalLine.Validate("Posting Date", CA.AdjustDate(19011231D));
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, StrSubstNo(XOpeningSaldoCustomers, GenJournalLine."Posting Date"));
        GenJournalLine.Validate("Due Date", "Due Date");
        if Quantity <> 0 then
            GenJournalLine.Validate(Quantity, Quantity);
        GenJournalLine.Validate("External Document No.", "External Document No.");
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", '99-1001');
        GenJournalLine.Insert();
    end;

    procedure InsertVendLine("Account No.": Code[20]; "Document No.": Code[20]; "Due Date": Date; Quantity: Decimal; Amount: Decimal; "External Document No.": Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        "Due Date" := CA.AdjustDate("Due Date");
        InitGenJnlLine(GenJournalLine, XSTART, XVENDOPEN);
        GenJournalLine.Validate("Posting Date", CA.AdjustDate(19021231D));
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, StrSubstNo(XOpeningSaldoVendors, GenJournalLine."Posting Date"));
        GenJournalLine.Validate("Due Date", "Due Date");
        if Quantity <> 0 then
            GenJournalLine.Validate(Quantity, Quantity);
        GenJournalLine.Validate("External Document No.", "External Document No.");
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", '99-1001');
        GenJournalLine.Insert();
    end;

    procedure InsertBankAccEntry("Account No.": Code[20]; "Document No.": Code[20]; Quantity: Decimal; Amount: Decimal; "External Document No.": Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InitGenJnlLine(GenJournalLine, XSTART, XBANKOPEN);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Posting Date", CA.AdjustDate(19011231D));
        GenJournalLine.Validate("Document Type", 0);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, XOpeningEntriesBankAccounts);
        if Quantity <> 0 then
            GenJournalLine.Validate(Quantity, Quantity);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", '99-1001');
        GenJournalLine.Insert();
    end;

    procedure InsertOpeningEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; Amount: Decimal)
    begin
        Error('InsertOpeningEntry should not be used for PCP');
    end;

    procedure InsertPeriodicEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20]; "Dimension 2 Value Code": Code[20]; "Dimension 3 Value Code": Code[20]; "Dimension 4 Value Code": Code[20]; "Dimension 5 Value Code": Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Amount := Amount * 100 / 13.12;
        Date := CA.AdjustDate(Date);
        "General Ledger Setup".Get();
        if DemoDataSetup."Local Precision Factor" >= 1 then
            Amount := Round(
                Amount * DemoDataSetup."Local Currency Factor",
                "General Ledger Setup"."Amount Rounding Precision" * DemoDataSetup."Local Precision Factor")
        else // To avoid errors when posting the lines
            Amount := Round(Amount * DemoDataSetup."Local Currency Factor");

        InitGenJnlLine(GenJournalLine, XSTART, XPERIODIC);
        GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", 0);
        GenJournalLine.Validate("Document No.", Format(Date2DMY(Date, 3)) + '-' + Format(Date2DMY(Date, 2)));
        GenJournalLine.Validate(Description, StrSubstNo(XEntries12, MonthName(Date), Date2DMY(Date, 3)));

        if "Exactly Balanced" then begin
            if Abs(("Entry Balance" / Amount + 1) * 100) > 1 then
                if not
                   Confirm(
                     StrSubstNo(
                       'Difference on Periodic entries: %1 on %2\\' +
                       'Do you want to continue?', "Entry Balance" + Amount, Date),
                     true)
                then
                    Error('Program terminated by the user');
            Amount := -"Entry Balance";
            "Entry Balance" := 0;
            "Exactly Balanced" := false;
        end else
            "Entry Balance" := "Entry Balance" + Amount;
        GenJournalLine.Validate(Amount, Amount);
        InsertTempDimSetEntry("General Ledger Setup"."Global Dimension 1 Code", "Shortcut Dimension 1 Code");
        InsertTempDimSetEntry(XCUSTOMERGROUP, "Dimension 2 Value Code");
        InsertTempDimSetEntry(XAREA, "Dimension 3 Value Code");
        InsertTempDimSetEntry(XBUSINESSGROUP, "Dimension 4 Value Code");
        InsertTempDimSetEntry(XSALESCAMPAIGN, "Dimension 5 Value Code");
        GenJournalLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        TempDimSetEntry.DeleteAll();
        DimMgt.UpdateGlobalDimFromDimSetID(
          GenJournalLine."Dimension Set ID",
          GenJournalLine."Shortcut Dimension 1 Code",
          GenJournalLine."Shortcut Dimension 2 Code");
        GenJournalLine.Insert();
    end;

    procedure InsertOtherEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; "Document No.": Code[20]; Description: Text[50]; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Amount := Amount * 100 / 13.12;
        Date := CA.AdjustDate(Date);
        "General Ledger Setup".Get();
        if DemoDataSetup."Local Precision Factor" >= 1 then
            Amount := Round(
                Amount * DemoDataSetup."Local Currency Factor",
                "General Ledger Setup"."Amount Rounding Precision" * DemoDataSetup."Local Precision Factor")
        else // To avoid errors when posting the lines
            Amount := Round(Amount * DemoDataSetup."Local Currency Factor");

        InitGenJnlLine(GenJournalLine, XSTART, XDEFAULT);
        GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", 0);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, StrSubstNo(GenJnlEntryDesc, Description, Date2DMY(Date, 3)));

        if "Exactly Balanced" then begin
            if Abs(("Entry Balance" / Amount + 1) * 100) > 1 then
                if not
                   Confirm(
                     StrSubstNo(
                       'Difference on Other entries: %1 on %2\\' +
                       'Do you want to continue?', "Entry Balance" + Amount, Date),
                     true)
                then
                    Error('Program terminated by the user');
            Amount := -"Entry Balance";
            "Entry Balance" := 0;
            "Exactly Balanced" := false;
        end else
            "Entry Balance" := "Entry Balance" + Amount;
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        GenJournalLine.Insert();
    end;

    procedure InsertRecurringEntry(CurrentJnlBatchName: Code[10]; "Account Type": Option; "Account No.": Code[20]; Date: Date; "Document Type": Option; "Document No.": Code[20]; Description: Text[100]; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20]; "Shortcut Dimension 2 Code": Code[20]; RecurringMethod: Integer; RecurringPeriod: Text[30])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Date := CA.AdjustDate(Date);
        InitGenJnlLine(GenJournalLine, XRECURRING, CurrentJnlBatchName);
        if CurrentJnlBatchName = XBALREFORM then
            GenJournalLine.Validate("Posting Date", ClosingDate(Date))
        else
            GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", "Document Type");
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, CopyStr(Description, 1, MaxStrLen(GenJournalLine.Description)));
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        GenJournalLine.Validate("Recurring Method", RecurringMethod);
        Evaluate(GenJournalLine."Recurring Frequency", RecurringPeriod);

        BatchName := GenJournalLine."Journal Batch Name";
        "Line No." := GenJournalLine."Line No.";
        GenJournalLine.Insert();
    end;

    procedure SetExactlyBalanced()
    begin
        "Exactly Balanced" := true;
    end;

    procedure InsertEvaluationEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; Amount: Decimal; DocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        OpeningEntryDate: Date;
    begin
        DemoDataSetup.Get();
        Amount := Round(Amount * DemoDataSetup."Local Currency Factor", 0.01);

        OpeningEntryDate := CA.AdjustDate(19011231D);
        InitGenJnlLine(GenJournalLine, XGENERAL, XDEFAULT);
        if Date = OpeningEntryDate then
            GenJournalLine.Validate("Posting Date", ClosingDate(Date))
        else
            GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", 0);
        if DocumentNo <> '' then begin
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Validate(Description, DocumentNo);
        end else
            if Date = OpeningEntryDate then begin
                GenJournalLine.Validate("Document No.", XSTART);
                GenJournalLine.Validate(Description, XOpeningEntry);
            end else begin
                GenJournalLine.Validate("Document No.", Format(GenJournalLine."Posting Date", 0, '<Month,2>-<Year4>'));
                GenJournalLine.Validate(Description, Format(GenJournalLine."Posting Date", 0, '<Month Text> <Year4>'));
            end;

        if "Exactly Balanced" then begin
            Amount := -"Entry Balance";
            "Exactly Balanced" := false;
        end;
        "Entry Balance" := "Entry Balance" + Amount;

        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Insert();
    end;

    procedure InsertRecurringAllocation(LineNo: Integer; "Account No.": Code[20]; "Shortcut Dimension 1 Code": Code[10]; "Shortcut Dimension 2 Code": Code[10]; "Allocation Quantity": Decimal; "Allocation %": Decimal; Amount: Decimal)
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        GenJnlAllocation.Init();
        GenJnlAllocation."Journal Template Name" := XRECURRING;
        GenJnlAllocation."Journal Batch Name" := BatchName;
        GenJnlAllocation."Journal Line No." := "Line No.";
        GenJnlAllocation."Line No." := LineNo;
        GenJnlAllocation."Account No." := "Account No.";
        GenJnlAllocation."VAT Calculation Type" := GenJnlAllocation."VAT Calculation Type"::"Normal VAT";
        GenJnlAllocation.Insert();

        GenJnlAllocation.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        GenJnlAllocation.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        if Amount <> 0 then
            GenJnlAllocation.Validate(Amount, Amount)
        else
            if "Allocation Quantity" <> 0 then
                GenJnlAllocation.Validate("Allocation Quantity", "Allocation Quantity")
            else
                GenJnlAllocation.Validate("Allocation %", "Allocation %");
        GenJnlAllocation.Modify();
    end;

    procedure InsertFAEntry(CurrentJnlTemplateName: Code[10]; CurrentJnlBatchName: Code[10]; "Account Type": Option; "Account No.": Code[20]; Date: Date; "Document Type": Option; "Document No.": Code[20]; Description: Text[100]; "Bal. Account Type": Option; "Bal. Account No.": Code[20]; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20]; "Shortcut Dimension 2 Code": Code[20]; "FA Posting Type": Integer; "Depreciation Book Code": Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Date := CA.AdjustDate(Date);
        "General Ledger Setup".Get();

        InitGenJnlLine(GenJournalLine, CurrentJnlTemplateName, CurrentJnlBatchName);
        GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", "Document Type");
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, CopyStr(Description, 1, StrLen(GenJournalLine.Description)));
        GenJournalLine.Validate("Bal. Account Type", "Bal. Account Type");
        if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"G/L Account" then
            "Bal. Account No." := CA.Convert("Bal. Account No.");
        GenJournalLine.Validate("Bal. Account No.", "Bal. Account No.");
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        GenJournalLine.Validate("FA Posting Type", "FA Posting Type");
        GenJournalLine.Validate("Depreciation Book Code", "Depreciation Book Code");

        if DemoDataSetup."Tax Accounting" then
            if GenJournalLine."FA Posting Type" in [GenJournalLine."FA Posting Type"::"Acquisition Cost",
                                                    GenJournalLine."FA Posting Type"::Appreciation,
                                                    GenJournalLine."FA Posting Type"::"Write-Down"]
            then begin
                TaxRegisterSetup.Get();
                GenJournalLine."Tax Difference Code" := TaxRegisterSetup."Default FA TD Code";
            end;
        GenJournalLine.Insert();
    end;

    procedure InitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; "Journal Template Name": Code[10]; "Journal Batch Name": Code[10])
    begin
        if ("Journal Template Name" <> "Gen. Journal Batch"."Journal Template Name") or
           ("Journal Batch Name" <> "Gen. Journal Batch".Name)
        then begin
            "Gen. Journal Batch".Get("Journal Template Name", "Journal Batch Name");
            if ("Gen. Journal Batch"."No. Series" <> '') or
               ("Gen. Journal Batch"."Posting No. Series" <> '')
            then begin
                "Gen. Journal Batch"."No. Series" := '';
                "Gen. Journal Batch"."Posting No. Series" := '';
                "Gen. Journal Batch".Modify();
            end;
            GenJournalLine.Reset();
            GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
            GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
            if GenJournalLine.Find('+') then
                "Line No." := GenJournalLine."Line No."
            else
                "Line No." := 0;
        end;
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", "Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", "Journal Batch Name");
        "Line No." := "Line No." + 10000;
        GenJournalLine.Validate("Line No.", "Line No.");
        GenJournalLine."System-Created Entry" := true;
        GenJournalLine."Copy VAT Setup to Jnl. Lines" := "Gen. Journal Batch"."Copy VAT Setup to Jnl. Lines";
    end;

    procedure MonthName(Date: Date) Name: Text[30]
    begin
        Name := Format(CA.AdjustDate(Date), 0, '<Month Text>');
    end;

    procedure CreatePeriodicDepr()
    var
        I: Integer;
        J: Integer;
        Description: Text[50];
    begin
        "FA Setup".Get();
        for I := 1 to 12 do
            for J := 1 to 9 do begin
                Description := CreateDescription(CalcDeprDate(I));
                InsertPeriodicDepr(GetFANo(J), CalcDeprDate(I), Description, I);
            end;
    end;

    procedure InsertPeriodicDepr("FA No.": Code[20]; "Posting Date": Date; Description: Text[50]; I: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempText: Text[10];
    begin
        InitGenJnlLine(GenJournalLine, XSTART, XDEPR);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Fixed Asset");
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::Depreciation);
        GenJournalLine.Validate("Account No.", "FA No.");
        GenJournalLine.Validate("Depreciation Book Code", "FA Setup"."Release Depr. Book");
        GenJournalLine.Validate("Posting Date", CA.AdjustDate("Posting Date"));
        if Date2DMY(GenJournalLine."Posting Date" + 1, 1) <> 1 then
            GenJournalLine.Validate("Posting Date", GenJournalLine."Posting Date" + 1);
        GenJournalLine."Depr. until FA Posting Date" := true;
        if I >= 10 then
            TempText := ''
        else
            TempText := '0';
        GenJournalLine.Validate(
          "Document No.",
          'D' + Format(Date2DMY(GenJournalLine."Posting Date", 3)) + TempText +
          Format(Date2DMY(GenJournalLine."Posting Date", 2)) + '0001');
        GenJournalLine.Description := Description;
        GenJournalLine.Insert();
    end;

    procedure GetFANo(J: Integer): Code[20]
    begin
        case J of
            1:
                exit(XFA000010);
            2:
                exit(XFA000020);
            3:
                exit(XFA000030);
            4:
                exit(XFA000040);
            5:
                exit(XFA000050);
            6:
                exit(XFA000060);
            7:
                exit(XFA000070);
            8:
                exit(XFA000080);
            9:
                exit(XFA000090);
        end;
    end;

    procedure CreateDescription(DeprDate: Date): Text[50]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Depreciation;
        exit(StrSubstNo(
            '%1 %2 %3',
            GenJnlLine."FA Posting Type",
            MonthName(DeprDate),
            Date2DMY(CA.AdjustDate(DeprDate), 3)));
    end;

    procedure CalcDeprDate(J: Integer): Date
    var
        DeprDate: Date;
    begin
        case J of
            1:
                DeprDate := 19020131D;
            2:
                DeprDate := 19020228D;
            3:
                DeprDate := 19020331D;
            4:
                DeprDate := 19020430D;
            5:
                DeprDate := 19020531D;
            6:
                DeprDate := 19020630D;
            7:
                DeprDate := 19020731D;
            8:
                DeprDate := 19020831D;
            9:
                DeprDate := 19020930D;
            10:
                DeprDate := 19021031D;
            11:
                DeprDate := 19021130D;
            12:
                DeprDate := 19021231D;
        end;
        exit(DeprDate);
    end;

    procedure InsertJobLine("Account No.": Code[20]; "Bal. Account No.": Code[20]; "Posting Date": Date; "Document No.": Code[20]; Description: Text[50]; Amount: Decimal; "Job No.": Code[20]; "Job Task No.": Code[20]; Amount2: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Amount := Amount * 100 / 13.12; // ECU -> DKK
        Amount2 := Amount2 * 100 / 13.12; // ECU -> DKK

        InitGenJnlLine(GenJournalLine, XJOBS, XDEFAULT);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", CA.Convert("Account No."));
        GenJournalLine.Validate("Posting Date", CA.AdjustDate("Posting Date"));
        GenJournalLine.Validate("Document Type", 0);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, CopyStr(Description, 1, MaxStrLen(GenJournalLine.Description)));
        Amount := Round(
            Amount * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor");
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Bal. Account No.", CA.Convert("Bal. Account No."));
        GenJournalLine.Validate("Job No.", "Job No.");
        GenJournalLine.Validate("Job Task No.", "Job Task No.");
        GenJournalLine.Validate("Job Line Type", GenJournalLine."Job Line Type"::"Both Budget and Billable");
        GenJournalLine.Validate("Job Quantity", 1);

        if Amount2 <> 0 then begin
            Amount2 := Round(
                Amount2 * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor");
            GenJournalLine.Validate("Job Unit Price", Amount2);
        end;
        GenJournalLine.Validate("System-Created Entry", false);
        GenJournalLine.Insert();
    end;

    local procedure InsertTempDimSetEntry(DimCode: Code[20]; DimValCode: Code[20])
    begin
        if DimCode = '' then
            exit;
        if DimValCode = '' then
            exit;
        DimVal.Get(DimCode, DimValCode);
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
        TempDimSetEntry.Insert();
    end;

    procedure InsertDailyEntry2(CurrentJnlTemplateName: Code[10]; CurrentJnlBatchName: Code[10]; "Account Type": Option; "Account No.": Code[20]; Date: Date; "Document Type": Option; "Document No.": Code[20]; Description: Text[50]; "Bal. Account Type": Option; "Bal. Account No.": Code[20]; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20]; "Shortcut Dimension 2 Code": Code[20]; "Applies-to Doc. Type": Option; "Applies-to Doc. No.": Code[20]; "Due Date": Date; CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Date := CA.AdjustDate(Date);
        "Due Date" := CA.AdjustDate("Due Date");
        "General Ledger Setup".Get();

        InitGenJnlLine(GenJournalLine, CurrentJnlTemplateName, CurrentJnlBatchName);
        GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", "Document Type");
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, CopyStr(Description, 1, StrLen(GenJournalLine.Description)));
        GenJournalLine.Validate("Bal. Account Type", "Bal. Account Type");
        if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"G/L Account" then
            "Bal. Account No." := CA.Convert("Bal. Account No.");
        GenJournalLine.Validate("Bal. Account No.", "Bal. Account No.");

        if "Bal. Account No." = '' then
            if "Exactly Balanced" then begin
                if Abs(("Entry Balance" / Amount + 1) * 100) > 1 then
                    if not
                       Confirm(
                         StrSubstNo(
                           'Difference on Daily entries: %1 on %2\\' +
                           'Do you want to continue?', "Entry Balance" + Amount, Date),
                         true)
                    then
                        Error('Program terminated by the user');
                Amount := -"Entry Balance";
                "Entry Balance" := 0;
                "Exactly Balanced" := false;
            end else
                "Entry Balance" := "Entry Balance" + Amount;
        GenJournalLine.Validate(Amount, Amount);

        GenJournalLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        GenJournalLine.Validate("Applies-to Doc. Type", "Applies-to Doc. Type");
        GenJournalLine.Validate("Applies-to Doc. No.", "Applies-to Doc. No.");
        GenJournalLine.Validate("Due Date", "Due Date");

        GenJournalLine.Validate("Currency Code", CurrencyCode);

        GenJournalLine.Insert();
    end;

    procedure InsertClosingEntry(CurrentJnlTemplateName: Code[10]; CurrentJnlBatchName: Code[10]; "Account Type": Option; "Account No.": Code[20]; Date: Date; "Document Type": Option; "Document No.": Code[20]; Description: Text[50]; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20]; "Shortcut Dimension 2 Code": Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        "General Ledger Setup".Get();
        Date := ClosingDate(CA.AdjustDate(Date));
        InitGenJnlLine(GenJournalLine, CurrentJnlTemplateName, CurrentJnlBatchName);
        GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", "Document Type");
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Description := Description;
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        GenJournalLine.Insert();
    end;

    procedure CreateGenJnlLine(Description: Text[50]; PostingDate: Date; CustomerNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Init();
        InitGenJnlLine(GenJournalLine, XGENERAL, XDEFAULT);

        GenJournalLine.Validate("Posting Date", NormalDate(PostingDate));
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", CustomerNo);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate(Description, Description);
        GenJournalLine.Validate("Document No.", CustomerNo);

        DemoDataSetup.Get();
        GenJournalLine.Insert();
    end;
}

