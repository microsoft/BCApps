codeunit 101256 "Create VAT Statement Line"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            exit;

        StatementTemplateName := XVAT;
        if (DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation) or (DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Standard) then begin
            // Trial and Evaluation Company
            InsertDataWithBoxNo('001', VATStatLine001Txt, 2, '', 0, '', '', '020|030', 0, 0, true, 0, false, '1');
            InsertDataWithBoxNo('002', VATStatLine002Txt, 2, '', 0, '', '', '090|100', 0, 0, true, 0, false, '2');
            InsertData('', VATStatLine002aTxt, 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertDataWithBoxNo('003', VATStatLine003Txt, 2, '', 0, '', '', '001|002', 0, 0, true, 0, false, '3');
            InsertDataWithBoxNo('004', VATStatLine004Txt, 2, '', 0, '', '', '040|050|070|080', 0, 0, true, 1, false, '4');
            InsertData('', VATStatLine004aTxt, 3, '', 0, '', '', '', 0, 0, true, 1, false);
            InsertDataWithBoxNo('005', VATStatLine005Txt, 2, '', 0, '', '', '020|030|070|080', 0, 0, true, 0, false, '5');
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertDataWithBoxNo('006', VATStatLine006Txt, 2, '', 0, '', '', '110|120|170|180|190|008', 0, 0, true, 1, false, '6');
            InsertData('', VATStatLine006aTxt, 3, '', 0, '', '', '', 0, 0, true, 1, false);
            InsertDataWithBoxNo('007', VATStatLine007Txt, 2, '', 0, '', '', '210|220|270|280|290|009', 0, 0, true, 0, false, '7');
            InsertData('', VATStatLine007aTxt, 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertDataWithBoxNo('008', VATStatLine008Txt, 2, '', 0, '', '', '140|150', 0, 0, true, 1, false, '8');
            InsertData('', VATStatLine008aTxt, 3, '', 0, '', '', '', 0, 0, true, 1, false);
            InsertDataWithBoxNo('009', VATStatLine009Txt, 2, '', 0, '', '', '240|250', 0, 0, true, 0, false, '9');
            InsertData('', VATStatLine009aTxt, 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('', VATStatLine009bTxt, 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('', VATStatLine009cTxt, 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('011', StrSubstNo(SalesTxt, DemoDataSetup.GoodsVATText(), ''), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 0, false);
            InsertData(
              '012', StrSubstNo(SalesTxt, DemoDataSetup.GoodsVATText(), XFullTxt), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.FullGoodsVATCode(), '', 1, 1, false, 0, false);
            InsertData('020', StrSubstNo(SalesTxt, DemoDataSetup.GoodsVATText(), XTotalTxt), 2, '', 0, '', '', '011..019', 0, 0, true, 0, false);
            InsertData('021', StrSubstNo(SalesTxt, DemoDataSetup.ServicesVATText(), ''), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 0, false);
            InsertData(
              '022', StrSubstNo(SalesTxt, DemoDataSetup.ServicesVATText(), XFullTxt), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.FullServicesVATCode(), '', 1, 1, false, 0, false);
            InsertData('030', StrSubstNo(SalesTxt, DemoDataSetup.ServicesVATText(), XTotalTxt), 2, '', 0, '', '', '021..029', 0, 0, true, 0, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('031', StrSubstNo(XOnEUAcqTxt, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 1, false);
            InsertData('040', StrSubstNo(XOnEUAcqTotalTxt, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '031..039', 0, 0, true, 1, false);
            InsertData('041', StrSubstNo(XOnEUAcqTxt, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 1, false);
            InsertData('050', StrSubstNo(XOnEUAcqTotalTxt, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '041..049', 0, 0, true, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData(
              '061', StrSubstNo(PurchaseTxt, XVAT, DemoDataSetup.GoodsVATText(), XDomestic, ''), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 1, false);
            InsertData('062', StrSubstNo(PurchaseTxt, XVAT, DemoDataSetup.GoodsVATText(), XFullTxt, XDomestic),
              1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.FullGoodsVATCode(), '', 1, 1, false, 1, false);
            InsertData('070', StrSubstNo(PurchaseTxt, DemoDataSetup.GoodsVATText(), XDomestic, XTotal, ''), 2, '', 0, '', '', '061..069', 0, 0, true, 1, false);
            InsertData(
              '071', StrSubstNo(PurchaseTxt, XVAT, DemoDataSetup.ServicesVATText(), XDomestic, ''), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 1, false);
            InsertData('072', StrSubstNo(PurchaseTxt, DemoDataSetup.ServicesVATText(), XDomestic, XTotal, XFullTxt), 1, '', 1, DemoDataSetup.DomesticCode(),
              DemoDataSetup.FullServicesVATCode(), '', 1, 1, false, 1, false);
            InsertData('080', StrSubstNo(PurchaseTxt, DemoDataSetup.ServicesVATText(), XDomestic, XTotalTxt, ''), 2, '', 0, '', '', '071..079', 0, 0, true, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('081', StrSubstNo(XOnEUAcqTxt, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false);
            InsertData('090', StrSubstNo(XOnEUAcqTotalTxt, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '081..089', 0, 0, false, 1, false);
            InsertData('091', StrSubstNo(XOnEUAcqTxt, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false);
            InsertData('100', StrSubstNo(XOnEUAcqTotalTxt, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '091..099', 0, 0, false, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('101', StrSubstNo(XValueOfDomesticSalesTxt, DemoDataSetup.GoodsVATText(), ''), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false);
            InsertData('110', StrSubstNo(XValueOfDomesticSalesTxt, DemoDataSetup.GoodsVATText(), XTotalTxt), 2, '', 0, '', '', '101..109', 0, 0, true, 1, false);
            InsertData(
              '111', StrSubstNo(XValueOfDomesticSalesTxt, DemoDataSetup.ServicesVATText(), ''), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false);
            InsertData('120', StrSubstNo(XValueOfDomesticSalesTxt, DemoDataSetup.ServicesVATText(), XTotalTxt), 2, '', 0, '', '', '111..119', 0, 0, true, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('131', StrSubstNo(XValueofEUSuppliesTxt, DemoDataSetup.GoodsVATText(), ''), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false);
            InsertData('140', StrSubstNo(XValueofEUSuppliesTxt, DemoDataSetup.GoodsVATText(), XTotalTxt), 2, '', 0, '', '', '131..139', 0, 0, true, 1, false);
            InsertData('141', StrSubstNo(XValueofEUSuppliesTxt, DemoDataSetup.ServicesVATText(), ''), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false);
            InsertData('150', StrSubstNo(XValueofEUSuppliesTxt, DemoDataSetup.ServicesVATText(), XTotalTxt), 2, '', 0, '', '', '141..149', 0, 0, true, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('161', StrSubstNo(XValueofOverseasSalesTxt, DemoDataSetup.GoodsVATText(), ''), 1, '', 2, XExportTxt, DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false);
            InsertData('170', StrSubstNo(XValueofOverseasSalesTxt, DemoDataSetup.GoodsVATText(), XTotalTxt), 2, '', 0, '', '', '161..169', 0, 0, true, 1, false);
            InsertData(
              '171', StrSubstNo(XValueofOverseasSalesTxt, DemoDataSetup.ServicesVATText(), ''), 1, '', 2, XExportTxt, DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false);
            InsertData(
              '180', StrSubstNo(XValueofOverseasSalesTxt, DemoDataSetup.ServicesVATText(), XTotalTxt), 2, '', 0, '', '', '171..179', 0, 0, true, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('190', VATStatLine190Txt, 1, '', 2, DemoDataSetup.DomesticCode(), '', '', 2, 0, true, 1, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData(
              '201', StrSubstNo(XValueofDomesticPurchasesTxt, DemoDataSetup.GoodsVATText(), ''), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
            InsertData(
              '210', StrSubstNo(XValueofDomesticPurchasesTxt, DemoDataSetup.GoodsVATText(), XTotalTxt), 2, '', 0, '', '', '201..209', 0, 0, true, 0, false);
            InsertData('211', StrSubstNo(XValueofDomesticPurchasesTxt, DemoDataSetup.ServicesVATText(), ''), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(),
              '', 2, 0, false, 0, false);
            InsertData(
              '220', StrSubstNo(XValueofDomesticPurchasesTxt, DemoDataSetup.ServicesVATText(), XTotalTxt), 2, '', 0, '', '', '211..219', 0, 0, true, 0, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('231', StrSubstNo(XValueofEUAcquisitionsTxt, DemoDataSetup.GoodsVATText(), ''), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
            InsertData('240', StrSubstNo(XValueofEUAcquisitionsTxt, DemoDataSetup.GoodsVATText(), XTotal), 2, '', 0, '', '', '231..239', 0, 0, true, 0, false);
            InsertData(
              '241', StrSubstNo(XValueofEUAcquisitionsTxt, DemoDataSetup.ServicesVATText(), ''), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
            InsertData(
              '250', StrSubstNo(XValueofEUAcquisitionsTxt, DemoDataSetup.ServicesVATText(), XTotalTxt), 2, '', 0, '', '', '241..249', 0, 0, true, 0, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData(
              '261', StrSubstNo(XValueofOverseasPurchasesTxt, DemoDataSetup.GoodsVATText(), ''), 1, '', 1, XExportTxt, DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
            InsertData(
              '270', StrSubstNo(XValueofOverseasPurchasesTxt, DemoDataSetup.GoodsVATText(), XTotalTxt), 2, '', 0, '', '', '261..269', 0, 0, true, 0, false);
            InsertData(
              '271', StrSubstNo(XValueofOverseasPurchasesTxt, DemoDataSetup.ServicesVATText(), ''), 1, '', 1, XExportTxt, DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
            InsertData(
              '280', StrSubstNo(XValueofOverseasPurchasesTxt, DemoDataSetup.ServicesVATText(), XTotalTxt), 2, '', 0, '', '', '271..279', 0, 0, true, 0, false);
            InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
            InsertData('290', VATStatLine290Txt, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, true, 0, false);
        end else begin
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
        end;
        StatementTemplateName := XVAT + 'GB';
        InsertDataWithBoxNo('001', XVATdueonsalesandotheroutputs, 2, '', 0, '', '', '020|030', 0, 0, true, 0, false, '1');
        InsertDataWithBoxNo('002', XVATdueonacquisitionEU, 2, '', 0, '', '', '090|100', 0, 0, true, 0, false, '2');
        InsertDataWithBoxNo('003', XTotalVATdue, 2, '', 0, '', '', '001|002', 0, 0, true, 0, false, '3');
        InsertDataWithBoxNo('004', XTotalVATdueinclEU, 2, '', 0, '', '', '040|050|070|080', 0, 0, true, 1, false, '4');
        InsertDataWithBoxNo('005', XNetVATPaidReclaimed, 2, '', 0, '', '', '020|030|070|080', 0, 0, true, 0, false, '5');
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertDataWithBoxNo('006', XTotalValueSalesInclRow8, 2, '', 0, '', '', '110|120|170|180|190|008', 0, 0, true, 1, false, '6');
        InsertDataWithBoxNo('007', XTotalValuePurchInclRow9, 2, '', 0, '', '', '210|220|270|280|290|009', 0, 0, true, 0, false, '7');
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertDataWithBoxNo('008', XTotalValueSuppliesEU, 2, '', 0, '', '', '140|150', 0, 0, true, 1, false, '8');
        InsertDataWithBoxNo('009', XTotalValueAcqEU, 2, '', 0, '', '', '240|250', 0, 0, true, 0, false, '9');
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '==================================================', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('011', StrSubstNo(XSales, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 0, false);
        InsertData(
          '012', StrSubstNo(XSales, StrSubstNo('%1 %2', DemoDataSetup.GoodsVATText(), XFULL)), 1, '', 2, DemoDataSetup.DomesticCode(),
          DemoDataSetup.FullGoodsVATCode(), '', 1, 1, false, 0, false);
        InsertData(
          '020', StrSubstNo(XSales, StrSubstNo('%1 %2', DemoDataSetup.GoodsVATText(), XTotal2)), 2, '', 0, '', '', '011..019', 0, 0, true, 0, false);
        InsertData('021', StrSubstNo(XSales, DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 0, false);
        InsertData(
          '022', StrSubstNo(XSales, StrSubstNo('%1 %2', DemoDataSetup.ServicesVATText(), XFULL)), 1, '', 2, DemoDataSetup.DomesticCode(),
          DemoDataSetup.FullServicesVATCode(), '', 1, 1, false, 0, false);
        InsertData(
          '030', StrSubstNo(XSales, StrSubstNo('%1 %2', DemoDataSetup.ServicesVATText(), XTotal2)), 2, '', 0, '', '', '021..029', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('031', StrSubstNo(XonEUAcquisitionsetc, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 1, false);
        InsertData('040', StrSubstNo(XonEUAcquisitionsetctotal, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '031..039', 0, 0, true, 1, false);
        InsertData('041', StrSubstNo(XonEUAcquisitionsetc, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 1, false);
        InsertData('050', StrSubstNo(XonEUAcquisitionsetctotal, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '041..049', 0, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData(
          '061', StrSubstNo(XPurchaseVATPERCENTDomestic, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 1, false);
        InsertData('062', StrSubstNo(XPurchaseVATPERCENTDomestic, StrSubstNo('%1 %2', DemoDataSetup.GoodsVATText(), XFULL)), 1, '', 1, DemoDataSetup.DomesticCode(),
          DemoDataSetup.FullGoodsVATCode(), '', 1, 1, false, 1, false);
        InsertData('070', StrSubstNo(XPurchaseVATPERCENTDomesticTot, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '061..069', 0, 0, true, 1, false);
        InsertData(
          '071', StrSubstNo(XPurchaseVATPERCENTDomestic, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 1, false);
        InsertData(
          '072', StrSubstNo(XPurchaseVATPERCENTDomesticFUL, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.DomesticCode(),
          DemoDataSetup.FullServicesVATCode(), '', 1, 1, false, 1, false);
        InsertData('080', StrSubstNo(XPurchaseVATPERCENTDomesticTot, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '071..079', 0, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('081', StrSubstNo(XonEUAcquisitionsetc, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false);
        InsertData('090', StrSubstNo(XonEUAcquisitionsetctotal, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '081..089', 0, 0, false, 1, false);
        InsertData('091', StrSubstNo(XonEUAcquisitionsetc, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false);
        InsertData('100', StrSubstNo(XonEUAcquisitionsetctotal, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '091..099', 0, 0, false, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('101', StrSubstNo(XValueofDomesticSales, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false);
        InsertData('110', StrSubstNo(XValueofDomesticSalesTotal, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '101..109', 0, 0, true, 1, false);
        InsertData(
          '111', StrSubstNo(XValueofDomesticSales, DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false);
        InsertData('120', StrSubstNo(XValueofDomesticSalesTotal, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '111..119', 0, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('131', StrSubstNo(XValueofEUSupplies, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false);
        InsertData('140', StrSubstNo(XValueofEUSuppliesTotal, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '131..139', 0, 0, true, 1, false);
        InsertData('141', StrSubstNo(XValueofEUSupplies, DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false);
        InsertData('150', StrSubstNo(XValueofEUSuppliesTotal, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '141..149', 0, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('161', StrSubstNo(XValueofOverseasSales, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false);
        InsertData('170', StrSubstNo(XValueofOverseasSalesTotal, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '161..169', 0, 0, true, 1, false);
        InsertData('171', StrSubstNo(XValueofOverseasSales, DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false);
        InsertData('180', StrSubstNo(XValueofOverseasSalesTotal, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '171..179', 0, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('190', XValueofnonVATliablesales, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('201', StrSubstNo(XValueofDomesticPurchases, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
        InsertData('210', StrSubstNo(XValueofDomesticPurchasesTotal, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '201..209', 0, 0, true, 0, false);
        InsertData(
          '211', StrSubstNo(XValueofDomesticPurchases, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
        InsertData('220', StrSubstNo(XValueofDomesticPurchasesTotal, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '211..219', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('231', StrSubstNo(XValueofEUAcquisitions, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
        InsertData('240', StrSubstNo(XValueofEUAcquisitionsTotal, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '231..239', 0, 0, true, 0, false);
        InsertData('241', StrSubstNo(XValueofEUAcquisitions, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
        InsertData('250', StrSubstNo(XValueofEUAcquisitionsTotal, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '241..249', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('261', StrSubstNo(XValueofOverseasPurchases, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
        InsertData('270', StrSubstNo(XValueofOverseasPurchasesTotal, DemoDataSetup.GoodsVATText()), 2, '', 0, '', '', '261..269', 0, 0, true, 0, false);
        InsertData(
          '271', StrSubstNo(XValueofOverseasPurchases, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
        InsertData('280', StrSubstNo(XValueofOverseasPurchasesTotal, DemoDataSetup.ServicesVATText()), 2, '', 0, '', '', '271..279', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('290', XValueofnonVATliablepurchases, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, true, 0, false);
        // GB End
    end;

    var
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
        StatementTemplateName: Code[10];
        XVATdueonsalesandotheroutputs: Label 'VAT due on sales and other outputs';
        XVATdueonacquisitionEU: Label 'VAT on goods acquired in Northern Ireland from EU';
        XTotalVATdue: Label 'Total VAT due';
        XTotalVATdueinclEU: Label 'Total VAT due (incl. EU acquisitions)';
        XNetVATPaidReclaimed: Label 'Net VAT to be paid (+) or to be reclaimed (-)';
        XTotalValueSalesInclRow8: Label 'Total value of sales excl. VAT, incl. Row 8';
        XTotalValuePurchInclRow9: Label 'Total value of purchases excl. VAT, incl. Row 9';
        XTotalValueSuppliesEU: Label 'Value of goods ex. VAT from Northern Ireland to EU';
        XTotalValueAcqEU: Label 'Goods ex. VAT acquired in Northern Ireland from EU';
        XSales: Label 'Sales %1';
        XFULL: Label 'FULL';
        XTotal2: Label ' total';
        XonEUAcquisitionsetc: Label '%1 on EU Acquisitions etc.';
        XonEUAcquisitionsetctotal: Label '%1 on EU Acquisitions etc. total';
        XPurchaseVATPERCENTDomesticTot: Label 'Purchase %1 Domestic total';
        XPurchaseVATPERCENTDomesticFUL: Label 'Purchase %1 Domestic total FULL';
        XValueofDomesticSales: Label 'Value of Domestic Sales %1';
        XValueofEUSupplies: Label 'Value of EU Supplies %1';
        XValueofDomesticSalesTotal: Label 'Value of Domestic Sales %1 total';
        XValueofEUSuppliesTotal: Label 'Value of EU Supplies %1 total';
        XValueofOverseasSales: Label 'Value of Overseas Sales %1';
        XValueofOverseasSalesTotal: Label 'Value of Overseas Sales %1 total';
        XValueofnonVATliablesales: Label 'Value of non-VAT liable sales';
        XValueofDomesticPurchases: Label 'Value of Domestic Purchases %1';
        XValueofDomesticPurchasesTotal: Label 'Value of Domestic Purchases %1 total';
        XValueofEUAcquisitions: Label 'Value of EU Acquisitions %1';
        XValueofEUAcquisitionsTotal: Label 'Value of EU Acquisitions %1 total';
        XValueofOverseasPurchases: Label 'Value of Overseas Purchases %1';
        XValueofOverseasPurchasesTotal: Label 'Value of Overseas Purchases %1 total';
        XValueofnonVATliablepurchases: Label 'Value of non-VAT liable purchases';
        VATStatLine001Txt: Label 'VAT due in the period on sales and other outputs';
        VATStatLine002Txt: Label 'VAT due in the period on acquisitions from other';
        VATStatLine002aTxt: Label 'member states of the EC';
        VATStatLine003Txt: Label 'Total VAT due';
        VATStatLine004Txt: Label 'VAT reclaimed in the period on purchases and other';
        VATStatLine004aTxt: Label 'inputs (including acquisitions from the EC)';
        VATStatLine005Txt: Label 'Net VAT to be paid (+); or to be reclaimed (-);';
        VATStatLine006Txt: Label 'Total value of sales and all other outputs ';
        VATStatLine006aTxt: Label 'excluding any VAT';
        VATStatLine007Txt: Label 'Total value of purchases and all other inputs ';
        VATStatLine007aTxt: Label 'excluding any VAT';
        VATStatLine008Txt: Label 'Total value of all supplies of goods and related';
        VATStatLine008aTxt: Label 'costs, excluding any VAT to other EC member states';
        VATStatLine009Txt: Label 'total value of all acquisitions of goods and ';
        VATStatLine009aTxt: Label 'related costs, excluding any VAT, from other EC ';
        VATStatLine009bTxt: Label 'member states';
        VATStatLine009cTxt: Label '================================================';
        SalesTxt: Label 'Sales %1 %2', Comment = '%1 = VAT code,%2 = Full or total';
        PurchaseTxt: Label 'Purchase %1 %2 %3 %4', Comment = '%1 = VAT,%2 = VAT Rate,%3 = Total or Full,%4 = Domestic or Foreign';
        VATStatLine190Txt: Label 'Value of non-VAT liable sales';
        VATStatLine290Txt: Label 'Value of non-VAT liable purchases';
        XFullTxt: Label 'FULL', Comment = 'No need to translate';
        XTotalTxt: Label 'total';
        XOnEUAcqTxt: Label '%1 on EU Acquisitions etc.', Comment = '%1 = VAT Rate';
        XOnEUAcqTotalTxt: Label '%1 on EU Acquisitions etc. total', Comment = '%1 = VAT Rate';
        XDomestic: Label 'Domestic';
        XValueOfDomesticSalesTxt: Label 'Value of Domestic Sales %1 %2', Comment = '%1 = VAT Rate,%2 = defines if line shows total amount';
        XValueofEUSuppliesTxt: Label 'Value of EU Supplies %1 %2', Comment = '%1 = VAT Rate,%2 = defines if line shows total amount';
        XValueofOverseasSalesTxt: Label 'Value of Overseas Sales %1 %2', Comment = '%1 = VAT Rate,%2 = defines if line shows total amount';
        XValueofDomesticPurchasesTxt: Label 'Value of Domestic Purchases %1 %2', Comment = '%1 = VAT Rate,%2 = defines if line shows total amount';
        XValueofEUAcquisitionsTxt: Label 'Value of EU Acquisitions %1 %2', Comment = '%1 = VAT Rate,%2 = defines if line shows total amount';
        XValueofOverseasPurchasesTxt: Label 'Value of Overseas Purchases %1 %2', Comment = '%1 = VAT Rate,%2 = defines if line shows total amount';
        XExportTxt: Label 'EXPORT', Comment = 'No need to translate';

    procedure InsertDataWithBoxNo(RowNo: Code[10]; Description: Text[50]; Type: Option; AccountTotaling: Text[30]; GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; RowTotaling: Text[30]; AmountType: Option; CalculateWith: Option; Print: Boolean; PrintWith: Option; NewPage: Boolean; BoxNo: Text[30])
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.Init();
        VATStatementLine.Validate("Statement Template Name", StatementTemplateName);
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
        VATStatementLine.Validate("Box No.", BoxNo);
        VATStatementLine.Insert();
    end;

    procedure InsertData(RowNo: Code[10]; Description: Text[50]; Type: Option; AccountTotaling: Text[30]; GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; RowTotaling: Text[30]; AmountType: Option; CalculateWith: Option; Print: Boolean; PrintWith: Option; NewPage: Boolean)
    begin
        InsertDataWithBoxNo(
          RowNo, Description, Type, AccountTotaling, GenPostingType, VATBusPostingGroup, VATProdPostingGroup, RowTotaling, AmountType,
          CalculateWith, Print, PrintWith, NewPage, '');
    end;
}

