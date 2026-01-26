codeunit 101256 "Create VAT Statement Line"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            exit;

        InsertData(
          '1010', StrSubstNo(XSalesVATPERCENToutgoing, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false);
        InsertData(
          '1020', StrSubstNo(XSalesVATPERCENToutgoing, DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false);
        InsertData(
          '1050', StrSubstNo(XVATPERCENTonEUPurchasesetc, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 1, false);
        InsertData(
          '1060', StrSubstNo(XVATPERCENTonEUPurchasesetc, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 1, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then begin
            InsertData(
              '1030', StrSubstNo(XSalesVATPERCENToutgoing, DemoDataSetup.ReducedVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 1, false);
            InsertData(
              '1070', StrSubstNo(XVATPERCENTonEUPurchasesetc, DemoDataSetup.ReducedVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 1, 1, false, 1, false);
        end;
        InsertData('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('1099', XTotal, 2, '', 0, '', '', '1010..1090', 0, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData(
          '1110', StrSubstNo(XPurchaseVATPERCENTDomestic, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false);
        InsertData(
          '1120', StrSubstNo(XPurchaseVATPERCENTDomestic, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false);
        InsertData(
          '1150', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false);
        InsertData(
          '1160', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then begin
            InsertData(
              '1130', StrSubstNo(XPurchaseVATPERCENTDomestic, DemoDataSetup.ReducedVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 0, false);
            InsertData(
              '1170', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.ReducedVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 0, false);
        end;
        InsertData('1179', XPurchaseVATingoing, 2, '', 0, '', '', '1110..1170', 0, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('1180', XFuelTax, 0, CA.Convert('995710'), 0, '', '', '', 0, 0, true, 1, false);
        InsertData('1181', XElectricityTax, 0, CA.Convert('995720'), 0, '', '', '', 0, 0, true, 1, false);
        InsertData('1182', XNaturalGasTax, 0, CA.Convert('995730'), 0, '', '', '', 0, 0, true, 1, false);
        InsertData('1183', XCoalTax, 0, CA.Convert('995740'), 0, '', '', '', 0, 0, true, 1, false);
        InsertData('1184', XCO2Tax, 0, CA.Convert('995750'), 0, '', '', '', 0, 0, true, 1, false);
        InsertData('1185', XWaterTax, 0, CA.Convert('995760'), 0, '', '', '', 0, 0, true, 1, false);
        InsertData('1189', XTotalTaxes, 2, '', 0, '', '', '1180..1188', 0, 0, true, 1, false);
        InsertData('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('1199', XTotalDeductions, 2, '', 0, '', '', '1159|1189', 0, 0, true, 1, false);
        InsertData('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', XVATPayable, 2, '', 0, '', '', '1099|1199', 0, 0, true, 1, false);
        InsertData('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData(
          '1210', StrSubstNo(XValueofEUPurchasesPERCENT, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
        InsertData(
          '1220', StrSubstNo(XValueofEUPurchasesPERCENT, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then
            InsertData(
              '1230', StrSubstNo(XValueofEUPurchasesPERCENT, DemoDataSetup.ReducedVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData(
          '1240', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false);
        InsertData(
          '1250', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then
            InsertData('1260', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.ReducedVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('1310', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
        InsertData('1320', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then
            InsertData('1330', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 0, false);
        InsertData('', XNonVATliablesalesOverseas, 2, '', 0, '', '', '1310..1330', 0, 0, true, 1, false);
        InsertData('1340', XNonVATliablesalesDomestic, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false);
        InsertData('', XNonVATliablesalesDomestic, 2, '', 0, '', '', '1340..1348', 0, 0, true, 1, false);
        // BEGIN IT
        InsertData2('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('', XVATPeriodicalReportingMonth, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('1010', XSalesBase20PERCNational, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 0, false);
        InsertData2('1020', XSalesBase10PERCNational, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 0, false);
        InsertData2('1021', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('1022', XInternalOperations, 2, '', 0, '', '', '1010..1020', 0, 0, true, 0, false);
        InsertData2('1024', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('1030', XSalesBase20PERCEU, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 0, false);
        InsertData2('1040', XSalesBase10PERCEU, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 0, false);
        InsertData2('1049', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('1050', XIntraEUDisposalsVP2, 2, '', 0, '', '', '1030..1049', 0, 0, true, 0, false);
        InsertData2('1051', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('1052', XActiveOperationsVP1, 2, '', 0, '', '', '1022|1050', 0, 0, true, 0, false);
        InsertData2('1053', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData2('1110', XPurchaseBase20PERCNational, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 0, false);
        InsertData2('1120', XPurchaseBase10PERCNational, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 0, false);
        InsertData2('1125', XPurchaseBase2050PERCNondeduct, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 0, false);
        InsertData2('1199', XPassiveOperationsVP3, 2, '', 0, '', '', '1110..1125', 0, 0, true, 0, false);
        InsertData2('1200', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData2('1210', XPurchaseBase20PERCEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 0, false);
        InsertData2('1220', XPurchaseBase10PERCEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 0, false);
        InsertData2('1290', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData2('1299', XReverseChargePurchaseVP4, 2, '', 0, '', '', '1210..1220', 0, 0, true, 0, false);
        InsertData2('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData2('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('5010', XSalesVAT20PERCNational, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData2('5020', XSalesVAT10PERCNational, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData2('5030', XSalesVATfromEUPurchase20PERC, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData2('5040', XSalesVATfromEUPurchase10PERC, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData2('5050', XPriorPeriodOutputVAT, 11, '', 18, '', '', '', 1, 0, true, 0, false);
        InsertData2('5060', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData2('5099', XTotalOutputVATVP5, 2, '', 0, '', '', '5010|5020|5030|5040|5050', 0, 0, true, 0, false);
        InsertData2('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData2('5110', XPurchaseVAT20PERCNational, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData2('5120', XPurchaseVAT10PERCNational, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData2('5130', XPurchaseVAT20PERCEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData2('5140', XPurchaseVAT10PERCEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData2('5150', XPurchaseVAT2050PERCNondeduct, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData2('5160', XInputVATPriorPeriodVP7, 11, '', 19, '', '', '', 1, 0, true, 0, false);
        InsertData2('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('5099', XTotalInputVATVP6, 2, '', 0, '', '', '5110|5120|5130|5140|5150|5160', 0, 0, true, 0, false);
        InsertData2('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData2('5500', XTotalVATtoPayVP10, 2, '', 0, '', '', '5099|5199', 0, 0, true, 0, false);
        InsertData2('5510', XIfVP10isNegativeReportInVP11, 3, '', 0, '', '', '', 0, 0, true, 0, false);

        InsertData3('', XVATSettlementMonth, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5010', XSalesVAT20PERCNational, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData3('5020', XSalesVAT10PERCNational, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData3('5030', XSalesVATfromEUPurchase20PERC, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData3('5040', XSalesVATfromEUPurchase10PERC, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData3('5050', XPayableVATVariation, 11, '', 10, '', '', '', 1, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5099', XTotalPayableVATVP5, 2, '', 0, '', '', '5010..5050', 0, 0, true, 0, false);
        InsertData3('5110', XPurchaseVAT20PERCNational, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData3('5120', XPurchaseVAT10PERCNational, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData3('5130', XPurchaseVAT20PERCEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false);
        InsertData3('5140', XPurchaseVAT10PERCEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false);
        InsertData3('5150', XPurchaseVAT2050PERCNondeduct, 11, '', 11, '', '', '', 1, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5199', XTotalDeductibleVATVP6, 2, '', 0, '', '', '5110..5160', 0, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5200', XVATBalanceForThePeriodVP7, 2, '', 0, '', '', '5099|5199', 0, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5250', XPriorPeriodOutputTaxVariatVP8, 11, '', 12, '', '', '', 1, 0, true, 0, false);
        InsertData3('5250', XPriorPeriodInputTaxVariatVP8, 11, '', 13, '', '', '', 1, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5300', XPriorPeriodsUnpaidVATVP9, 11, '', 14, '', '', '', 1, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5500', XPriorPeriodOutputVATVP10, 11, '', 18, '', '', '', 1, 0, true, 0, false);
        InsertData3('5510', XPriorPeriodInputVATVP10, 11, '', 19, '', '', '', 1, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5600', XCreditVATCompensationVP11, 11, '', 11, '', '', '', 1, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5700', XVATtoPayForThePeriodVP12, 2, '', 0, '', '', '5200..5600', 0, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5800', XDeductedSpecialCreditVP13, 11, '', 17, '', '', '', 1, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('5900', XAmountPaidInAdvVP15, 11, '', 8, '', '', '', 1, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('6000', XAmountToPayVP16InputForPeriod, 2, '', 0, '', '', '5700..5900', 0, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('', XPaymentDate, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('', XBank, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('', XSubsidiary, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('', XAbiCab, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('7000', XPaidAmount, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 11, '', 7, '', '', '', 1, 0, true, 0, false);
        InsertData3('', XInfraannualCredReqAsRefund, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('', XInfraannualCredUseAsCompensat, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData3('', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        // END IT
        // BEGIN IT Annual VAT Declaration
        InsertData4('', XSales, 3, 0, '', '', 0, '', 0, 0, true);
        InsertData4('', '', 3, 0, '', '', 0, '', 0, 0, true);
        InsertData4('1', XVATSales20, 1, 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), 2, '', 1, 0, true);
        InsertData4('2', XVATSales10, 1, 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), 2, '', 1, 0, true);
        InsertData4('CD1.1', XTotalSales, 2, 0, '', '', 0, '1|2', 0, 1, true);
        InsertData4('3', XSalesNonTaxableArt8, 1, 2, '', '', 2, '', 1, 0, true);
        InsertData4('4', XSalesNonTaxableArt15, 1, 2, '', '', 2, '', 1, 0, true);
        InsertData4('CD1.2', XTotalSalesNonTaxable, 2, 0, '', '', 0, '3|4', 0, 2, true);
        InsertData4('5', "XSales ExemptArt13", 1, 2, DemoDataSetup.DomesticCode(), XE13, 2, '', 1, 0, true);
        InsertData4('6', XSalesNoVAT, 1, 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), 2, '', 1, 0, true);
        InsertData4('CD1.3', XTotalExemptSales, 2, 0, '', '', 0, '5|6', 0, 3, true);
        InsertData4('7', XVAT20IntracomGoodSales, 1, 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), 2, '', 1, 0, true);
        InsertData4('8', XVAT10IntracomGoodSales, 1, 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), 2, '', 1, 0, true);
        InsertData4('CD1.3', XTotalEUSales, 2, 0, '', '', 0, '7|8', 0, 4, true);
        InsertData4('', '', 3, 0, '', '', 0, '', 0, 0, true);
        InsertData4('', XPurchase, 3, 0, '', '', 0, '', 0, 0, true);
        InsertData4('', '', 3, 0, '', '', 0, '', 0, 0, true);
        InsertData4('9', XVATPurchases20, 1, 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), 2, '', 1, 0, true);
        InsertData4('10', XVATPurchases10, 1, 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), 2, '', 1, 0, true);
        InsertData4('CD2.1', XTotalPurchases, 2, 0, '', '', 0, '9|10', 0, 5, true);
        InsertData4('11', XPurchaseNonTaxableArt8, 1, 1, '', '', 2, '', 1, 0, true);
        InsertData4('12', XPurchaseNonTaxableArt15, 1, 1, '', '', 2, '', 1, 0, true);
        InsertData4('CD2.2', XTotalPurchases, 2, 0, '', '', 0, '11|12', 0, 6, true);
        InsertData4('13', XPurchasesExemptArt13, 1, 1, DemoDataSetup.DomesticCode(), XE13, 2, '', 1, 0, true);
        InsertData4('14', XPurchasesNonVAT, 1, 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), 2, '', 1, 0, true);
        InsertData4('CD2.3', XTotalExemptPurchases, 2, 0, '', '', 0, '13|14', 0, 7, true);
        InsertData4('15', XVAT20IntracomGoodPurchases, 1, 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), 2, '', 1, 0, true);
        InsertData4('16', XVAT10IntracomGoodPurchases, 1, 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), 2, '', 1, 0, true);
        InsertData4('CD2.4', XTotalEUPurchases, 2, 0, '', '', 0, '15|16', 0, 8, true);
        InsertData4('', '', 3, 0, '', '', 0, '', 0, 0, true);
        InsertData4('', '', 3, 0, '', '', 0, '', 0, 0, true);
        InsertData4('', XTotal, 3, 0, '', '', 0, '', 0, 0, true);
        InsertData4('', '', 3, 0, '', '', 0, '', 0, 0, true);
        InsertData4('CD4', XPayableVAT, 2, 0, '', '', 0, 'CD1*', 0, 13, true);
        InsertData4('CD4', XReceivableVAT, 2, 0, '', '', 0, 'CD2*', 0, 14, true);
        // END IT Annual VAT Declaration
    end;

    var
        XVATPeriodicalReportingMonth: Label 'VAT Periodical Reporting Month .........';
        XSalesBase20PERCNational: Label 'Sales Base 20% - National';
        XSalesBase10PERCNational: Label 'Sales Base 10% - National';
        XInternalOperations: Label 'Internal Operations';
        XSalesBase20PERCEU: Label 'Sales Base 20% - EU';
        XSalesBase10PERCEU: Label 'Sales Base 10% - EU';
        XIntraEUDisposalsVP2: Label 'Intra EU Disposals - VP2';
        XActiveOperationsVP1: Label 'Active Operations - VP1';
        XPurchaseBase20PERCNational: Label 'Purchase Base 20% - National';
        XPurchaseBase10PERCNational: Label 'Purchase Base 10% - National';
        XPurchaseBase2050PERCNondeduct: Label 'Purchase Base 20% - 50% Nondeductible';
        XPassiveOperationsVP3: Label 'Passive Operations - VP3';
        XPurchaseBase20PERCEU: Label 'Purchase Base 20% - EU';
        XPurchaseBase10PERCEU: Label 'Purchase Base 10% - EU';
        XReverseChargePurchaseVP4: Label 'Reverse Charge Purchase - VP4';
        XSalesVAT20PERCNational: Label 'Sales VAT 20% - National';
        XSalesVAT10PERCNational: Label 'Sales VAT 10% - National';
        XSalesVATfromEUPurchase20PERC: Label 'Sales VAT from EU Purchase - 20%';
        XSalesVATfromEUPurchase10PERC: Label 'Sales VAT from EU Purchase - 10%';
        XPriorPeriodOutputVAT: Label 'Prior Period Output VAT';
        XTotalOutputVATVP5: Label 'Total Output VAT - VP5';
        XPurchaseVAT20PERCNational: Label 'Purchase VAT 20% - National';
        XPurchaseVAT10PERCNational: Label 'Purchase VAT 10% - National';
        XPurchaseVAT20PERCEU: Label 'Purchase VAT 20% - EU';
        XPurchaseVAT10PERCEU: Label 'Purchase VAT 10% - EU';
        XPurchaseVAT2050PERCNondeduct: Label 'Purchase VAT 20% - 50% Nondeductible';
        XInputVATPriorPeriodVP7: Label 'Input VAT Prior Period - VP7';
        XTotalInputVATVP6: Label 'Total Input VAT - VP6';
        XTotalVATtoPayVP10: Label 'Total VAT to Pay - VP10';
        XIfVP10isNegativeReportInVP11: Label 'If VP10 is negative, report it in  VP11';
        XVATSettlementMonth: Label 'VAT Settlement Month ________';
        XPayableVATVariation: Label 'Payable VAT Variation';
        XTotalPayableVATVP5: Label 'Total Payable VAT - VP5';
        XTotalDeductibleVATVP6: Label 'Total Deductible VAT - VP6';
        XVATBalanceForThePeriodVP7: Label 'VAT Balance for the Period - VP7';
        XPriorPeriodOutputTaxVariatVP8: Label 'Prior Period Output Tax Variation - VP8';
        XPriorPeriodInputTaxVariatVP8: Label 'Prior Period Input Tax Variation - VP8';
        XPriorPeriodsUnpaidVATVP9: Label 'Prior Periods Unpaid VAT - VP9';
        XPriorPeriodOutputVATVP10: Label 'Prior Period Output VAT - VP10';
        XPriorPeriodInputVATVP10: Label 'Prior Period Input VAT - VP10';
        XCreditVATCompensationVP11: Label 'Credit VAT Compensation - VP11';
        XVATtoPayForThePeriodVP12: Label 'VAT to Pay for the Period - VP12';
        XDeductedSpecialCreditVP13: Label 'Deducted Special Credit - VP13';
        XAmountPaidInAdvVP15: Label 'Amount Paid in Adv. - VP15';
        XAmountToPayVP16InputForPeriod: Label 'Amount to Pay - VP16 / Input for the Period';
        XPaymentDate: Label 'Payment Date :__________________________________';
        XBank: Label 'Bank :___________________________________________';
        XSubsidiary: Label 'Subsidiary :______________________________________';
        XAbiCab: Label 'Abi/Cab :__________________________________';
        XPaidAmount: Label 'Paid Amount :____________________________________';
        XInfraannualCredReqAsRefund: Label 'Infra-annual Cred. requested as refund:';
        XInfraannualCredUseAsCompensat: Label 'Infra-annual Cred. to use as Compensation :';
        XxVATDECL: Label 'VATDECL';
        XxVATSETLPER: Label 'VATSETLPER';
        DemoDataSetup: Record "Demo Data Setup";
        NextLineNo: Integer;
        CA: Codeunit "Make Adjustments";
        XSalesVATPERCENToutgoing: Label 'Sales VAT %1 (outgoing)';
        XVATPERCENTonEUPurchasesetc: Label 'VAT %1 % on EU Purchases etc.';
        XPurchaseVATPERCENTDomestic: Label 'Purchase VAT %1 Domestic';
        XPurchaseVATPERCENTEU: Label 'Purchase VAT %1 EU';
        XValueofEUPurchasesPERCENT: Label 'Value of EU Purchases %1';
        XValueofEUSalesPERCENT: Label 'Value of EU Sales %1';
        XTotal: Label 'Total';
        XPurchaseVATingoing: Label 'Purchase VAT (ingoing)';
        XFuelTax: Label 'Fuel Tax';
        XElectricityTax: Label 'Electricity Tax';
        XNaturalGasTax: Label 'Natural Gas Tax';
        XCoalTax: Label 'Coal Tax';
        XCO2Tax: Label 'CO2 Tax';
        XWaterTax: Label 'Water Tax';
        XTotalTaxes: Label 'Total Taxes';
        XTotalDeductions: Label 'Total Deductions';
        XVATPayable: Label 'VAT Payable';
        XNonVATliablesalesOverseas: Label 'Non-VAT liable sales, Overseas';
        XNonVATliablesalesDomestic: Label 'Non-VAT liable sales, Domestic';
        XVAT: Label 'VAT';
        XDEFAULT: Label 'DEFAULT';
        XVATCOMM: Label 'VAT COMM';
        XSales: Label 'Sales:';
        XVATSales20: Label 'VAT Sales 20 %';
        XVATSales10: Label 'VAT Sales 10 %';
        XTotalSales: Label 'Total Sales';
        XSalesNonTaxableArt8: Label 'Sales Non-Taxable Art 8/1';
        XSalesNonTaxableArt15: Label 'Sales Non-Taxable Art 15';
        XTotalSalesNonTaxable: Label 'Total Sales Non-Taxable';
        "XSales ExemptArt13": Label 'Sales Exempt - Art 13';
        XSalesNoVAT: Label 'Sales No VAT';
        XTotalExemptSales: Label 'Total Exempt Sales';
        XVAT20IntracomGoodSales: Label 'VAT 20% Intracom Good Sales';
        XVAT10IntracomGoodSales: Label 'VAT 10% Intracom Good Sales';
        XTotalEUSales: Label 'Total EU Sales';
        XPurchase: Label 'Purchase:';
        XVATPurchases20: Label 'VAT Purchases 20%';
        XVATPurchases10: Label 'VAT Purchases 10%';
        XTotalPurchases: Label 'Total Purchases';
        XPurchaseNonTaxableArt8: Label 'Purchase Non-Taxable Art 8/1';
        XPurchaseNonTaxableArt15: Label 'Purchase Non-Taxable Art 15';
        XPurchasesExemptArt13: Label 'Purchases Exempt - Art 13';
        XPurchasesNonVAT: Label 'Purchases Non VAT';
        XTotalExemptPurchases: Label 'Total Exempt Purchases';
        XVAT20IntracomGoodPurchases: Label 'VAT 20% Intracom Good Purchases';
        XVAT10IntracomGoodPurchases: Label 'VAT 10% Intracom GoodPurchases';
        XTotalEUPurchases: Label 'Total EU Purchases';
        XPayableVAT: Label 'Payable VAT';
        XReceivableVAT: Label 'Receivable VAT';
        XE13: Label 'E13';

    procedure InsertData(RowNo: Code[10]; Description: Text[50]; Type: Option; AccountTotaling: Text[30]; GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; RowTotaling: Text[30]; AmountType: Option; CalculateWith: Option; Print: Boolean; PrintWith: Option; NewPage: Boolean)
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.Init();
        VATStatementLine.Validate("Statement Template Name", XVAT);
        VATStatementLine.Validate("Statement Name", XDEFAULT);
        NextLineNo := NextLineNo + 10000;
        VATStatementLine.Validate("Line No.", NextLineNo);
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate(Description, Description);
        VATStatementLine.Validate(Type, Type);
        VATStatementLine.Validate("Account Totaling", AccountTotaling);
        VATStatementLine.Validate("Gen. Posting Type", GenPostingType);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        VATStatementLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        VATStatementLine.Validate("Row Totaling", RowTotaling);
        VATStatementLine.Validate("Amount Type", AmountType);
        VATStatementLine.Validate("Calculate with", CalculateWith);
        VATStatementLine.Validate(Print, Print);
        VATStatementLine.Validate("Print with", PrintWith);
        VATStatementLine.Validate("New Page", NewPage);
        VATStatementLine.Insert();
    end;

    procedure InsertData2("Row No.": Code[10]; Description: Text[50]; Type: Option; "Account Totaling": Text[30]; "Gen. Posting Type": Option; "VAT Bus. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "Row Totaling": Text[30]; "Amount Type": Option; "Calculate with": Option; Print: Boolean; "Print with": Option; "New Page": Boolean)
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.Init();
        VATStatementLine.Validate("Statement Template Name", XVAT);
        VATStatementLine.Validate("Statement Name", XxVATDECL);
        NextLineNo := NextLineNo + 10000;
        VATStatementLine.Validate("Line No.", NextLineNo);
        VATStatementLine.Validate("Row No.", "Row No.");
        VATStatementLine.Validate(Description, Description);
        VATStatementLine.Validate(Type, Type);
        VATStatementLine.Validate("Account Totaling", "Account Totaling");
        VATStatementLine.Validate("Gen. Posting Type", "Gen. Posting Type");
        VATStatementLine.Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        VATStatementLine.Validate("Row Totaling", "Row Totaling");
        VATStatementLine.Validate("Amount Type", "Amount Type");
        VATStatementLine.Validate("Calculate with", "Calculate with");
        VATStatementLine.Validate(Print, Print);
        VATStatementLine.Validate("Print with", "Print with");
        VATStatementLine.Validate("New Page", "New Page");
        VATStatementLine.Insert();
    end;

    procedure InsertData3("Row No.": Code[10]; Description: Text[50]; Type: Option; "Account Totaling": Text[30]; "Gen. Posting Type": Option; "VAT Bus. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "Row Totaling": Text[30]; "Amount Type": Option; "Calculate with": Option; Print: Boolean; "Print with": Option; "New Page": Boolean)
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.Init();
        VATStatementLine.Validate("Statement Template Name", XVAT);
        VATStatementLine.Validate("Statement Name", XxVATSETLPER);
        NextLineNo := NextLineNo + 10000;
        VATStatementLine.Validate("Line No.", NextLineNo);
        VATStatementLine.Validate("Row No.", "Row No.");
        VATStatementLine.Validate(Description, Description);
        VATStatementLine.Validate(Type, Type);
        VATStatementLine.Validate("Account Totaling", "Account Totaling");
        VATStatementLine.Validate("Gen. Posting Type", "Gen. Posting Type");
        VATStatementLine.Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        VATStatementLine.Validate("Row Totaling", "Row Totaling");
        VATStatementLine.Validate("Amount Type", "Amount Type");
        VATStatementLine.Validate("Calculate with", "Calculate with");
        VATStatementLine.Validate(Print, Print);
        VATStatementLine.Validate("Print with", "Print with");
        VATStatementLine.Validate("New Page", "New Page");
        VATStatementLine.Insert();
    end;

    procedure InsertData4("Row No.": Code[10]; Description: Text[50]; Type: Option; "Gen. Posting Type": Option; "VAT Bus. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "Amount Type": Option; "Row Totaling": Text[30]; "Calculate with": Option; "Annual VAT Comm. Field": Option; Print: Boolean)
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.Init();
        VATStatementLine.Validate("Statement Template Name", XVATCOMM);
        VATStatementLine.Validate("Statement Name", XDEFAULT);
        NextLineNo := NextLineNo + 10000;
        VATStatementLine.Validate("Line No.", NextLineNo);
        VATStatementLine.Validate("Row No.", "Row No.");
        VATStatementLine.Validate(Description, Description);
        VATStatementLine.Validate(Type, Type);
        VATStatementLine.Validate("Gen. Posting Type", "Gen. Posting Type");
        VATStatementLine.Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATStatementLine."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
        VATStatementLine.Validate("Amount Type", "Amount Type");
        VATStatementLine.Validate("Row Totaling", "Row Totaling");
        VATStatementLine.Validate("Calculate with", "Calculate with");
        VATStatementLine.Validate("Annual VAT Comm. Field", "Annual VAT Comm. Field");
        VATStatementLine.Validate(Print, Print);
        VATStatementLine.Insert();
    end;
}

