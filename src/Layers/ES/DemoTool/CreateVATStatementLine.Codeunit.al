codeunit 101256 "Create VAT Statement Line"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            exit;

        InsertData(
          '', '1010', StrSubstNo(XSalesVATPERCENToutgoing, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false);
        InsertData(
          '', '1020', StrSubstNo(XSalesVATPERCENToutgoing, DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false);
        InsertData(
          '', '1050', StrSubstNo(XVATPERCENTonEUPurchasesetc, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 1, false);
        InsertData(
          '', '1060', StrSubstNo(XVATPERCENTonEUPurchasesetc, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 1, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then begin
            InsertData(
              '', '1030', StrSubstNo(XSalesVATPERCENToutgoing, DemoDataSetup.ReducedVATText()), 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 1, false);
            InsertData(
              '', '1070', StrSubstNo(XVATPERCENTonEUPurchasesetc, DemoDataSetup.ReducedVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 1, 1, false, 1, false);
        end;
        InsertData('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '1099', XTotal, 2, '', 0, '', '', '1010..1090', 0, 0, true, 1, false);
        InsertData('', '', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData(
          '', '1110', StrSubstNo(XPurchaseVATPERCENTDomestic, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false);
        InsertData(
          '', '1120', StrSubstNo(XPurchaseVATPERCENTDomestic, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false);
        InsertData(
          '', '1150', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false);
        InsertData(
          '', '1160', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then begin
            InsertData(
              '', '1130', StrSubstNo(XPurchaseVATPERCENTDomestic, DemoDataSetup.ReducedVATText()), 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 0, false);
            InsertData(
              '', '1170', StrSubstNo(XPurchaseVATPERCENTEU, DemoDataSetup.ReducedVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 0, false);
        end;
        InsertData('', '1179', XPurchaseVATingoing, 2, '', 0, '', '', '1110..1170', 0, 0, true, 1, false);
        InsertData('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '1199', XTotalDeductions, 2, '', 0, '', '', '1159|1189', 0, 0, true, 1, false);
        InsertData('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', XVATPayable, 2, '', 0, '', '', '1099|1199', 0, 0, true, 1, false);
        InsertData('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData(
          '', '1210', StrSubstNo(XValueofEUPurchasesPERCENT, DemoDataSetup.GoodsVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
        InsertData(
          '', '1220', StrSubstNo(XValueofEUPurchasesPERCENT, DemoDataSetup.ServicesVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then
            InsertData(
              '', '1230', StrSubstNo(XValueofEUPurchasesPERCENT, DemoDataSetup.ReducedVATText()), 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 0, false);
        InsertData('', '', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData(
          '', '1240', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false);
        InsertData(
          '', '1250', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.ServicesVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then
            InsertData('', '1260', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.ReducedVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 1, false);
        InsertData('', '', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '1310', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false);
        InsertData('', '1320', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false);
        if DemoDataSetup."Reduced VAT Rate" > 0 then
            InsertData('', '1330', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 0, false);
        InsertData('', '', XNonVATliablesalesOverseas, 2, '', 0, '', '', '1310..1330', 0, 0, true, 1, false);
        InsertData('', '1340', XNonVATliablesalesDomestic, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false);
        InsertData('', '', XNonVATliablesalesDomestic, 2, '', 0, '', '', '1340..1348', 0, 0, true, 1, false);
        // ES (320)  - // XMLVATDecl - New parameter XML added for InsertData2 320 and 392
        InsertData2('', '10', XAmtSalesVAT16PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false, false);
        InsertData2('', 'B010', XBaseSalesVAT16PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false, false);
        InsertData2('3', '19', XTAmtSalesVAT16PERCENToutgoing, 2, '', 0, '', '', '10..18', 0, 0, true, 1, false, false);
        InsertData2('1', 'B019', XTBaseSalesVAT16PERCENToutg, 2, '', 0, '', '', 'B010..B018', 0, 0, true, 1, false, false);
        InsertData2('2', '1D', '16', 3, '', 0, '', '', '', 0, 0, true, 0, false, false);
        InsertData2('', '20', XAmtSalesVAT7PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false, false);
        InsertData2('', 'B020', XBaseSalesVAT7PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false, false);
        InsertData2('6', '29', XTAmtSalesVAT7PERCENToutgoing, 2, '', 0, '', '', '20..28', 0, 0, true, 1, false, false);
        InsertData2('4', 'B029', XTBaseSalesVAT7PERCENToutg, 2, '', 0, '', '', 'B020..B028', 0, 0, true, 1, false, false);
        InsertData2('5', '2D', '7', 3, '', 0, '', '', '', 0, 0, true, 0, false, false);
        InsertData2('', '30', XAmtVAT16PERCENTonEUPurchsetc, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 1, false, 1, false, false);
        InsertData2('', 'B030', XBaseVAT16PERCENTonEUPurchsetc, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 1, false, 1, false, false);
        InsertData2('', '39', XTAmtVAT16PERCENTonEUPurchsetc, 2, '', 0, '', '', '30..38', 0, 0, true, 1, false, false);
        InsertData2('', 'B039', XTBaseVAT16PERCENTonEUPurcsetc, 2, '', 0, '', '', 'B030..B038', 0, 0, true, 1, false, false);
        InsertData2('', '40', XAmtVAT7PERCENTonEUPurchsetc, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 1, false, 1, false, false);
        InsertData2('', 'B040', XBaseVAT7PERCENTonEUPurchsetc, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 1, false, 1, false, false);
        InsertData2('', '49', XTAmtVAT7PERCENTonEUPurchsetc, 2, '', 0, '', '', '40..48', 0, 0, true, 1, false, false);
        InsertData2('', 'B049', XBaseAVAT7PERCENTonEUPurcsetc, 2, '', 0, '', '', 'B040..B048', 0, 0, true, 1, false, false);
        InsertData2('20', '50', XTotalAmtVATEUPurchetc, 2, '', 0, '', '', '39|49', 0, 0, true, 1, false, false);
        InsertData2('19', 'B050', XTotalBaseVATEUPurchetc, 2, '', 0, '', '', 'B039|B049', 0, 0, true, 1, false, false);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, false);
        InsertData2('21', '99', XTotalDuedVATAmount, 2, '', 0, '', '', '19|29|50', 0, 0, true, 1, false, false);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, false);
        InsertData2('', '110', XAmountPurchaseVAT16PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false, false);
        InsertData2('', 'B110', XBasePurchaseVAT16PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, false);
        InsertData2('', '119', XTotAmountPurchaseVAT16PERCENT, 2, '', 0, '', '', '110..118', 0, 0, true, 1, false, false);
        InsertData2('', 'B119', XTBaseAmtPurchaseVAT16PERCENT, 2, '', 0, '', '', 'B110..B118', 0, 0, true, 0, false, false);
        InsertData2('', '120', XAmountPurchaseVAT7PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false, false);
        InsertData2('', 'B120', XBasePurchaseVAT7PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, false);
        InsertData2('', '129', XTotAmtPurchaseVAT7PERCENT, 2, '', 0, '', '', '120..128', 0, 0, true, 1, false, false);
        InsertData2('', 'B129', XTotBasePurchaseVAT7PERCENT, 2, '', 0, '', '', 'B120..B128', 0, 0, true, 0, false, false);
        InsertData2('23', '130', XTotalAmountPurchases, 2, '', 0, '', '', '119|129', 0, 0, true, 1, false, false);
        InsertData2('22', 'B130', XTotalBasePurchases, 2, '', 0, '', '', 'B119|B129', 0, 0, true, 0, false, false);
        InsertData2('', '131', XBasePurchaseVAT7PERCENTEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false, false);
        InsertData2('', 'B131', XBasePurchaseVAT16PERCENTEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, false);
        InsertData2('', '139', XTotAmtPurchaseVAT16PERCENTEU, 2, '', 0, '', '', '131..138', 0, 0, true, 1, false, false);
        InsertData2('', 'B139', XTotBasePurchaseVAT16PERCENTEU, 2, '', 0, '', '', 'B131..B138', 0, 0, true, 0, false, false);
        InsertData2('', '140', XAmountPurchaseVAT7PERCENTEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false, false);
        InsertData2('', 'B140', XBasePurchaseVAT7PERCENTEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, false);
        InsertData2('', '149', XTotAmtPurchaseVAT7PERCENTEU, 2, '', 0, '', '', '140..148', 0, 0, true, 1, false, false);
        InsertData2('', 'B149', XTotBasePurchaseVAT7PERCENTEU, 2, '', 0, '', '', 'B140..B148', 0, 0, true, 0, false, false);
        InsertData2('27', '170', XTotalAmountPurchasesEU, 2, '', 0, '', '', '139|149', 0, 0, true, 1, false, false);
        InsertData2('26', 'B170', XTotalBasePurchasesEU, 2, '', 0, '', '', 'B139|B149', 0, 0, true, 0, false, false);
        InsertData2('', '', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, false);
        InsertData2('30', '199', XTotalDeductions, 2, '', 0, '', '', '130|170', 0, 0, true, 1, false, false);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, false);
        InsertData2('31', '', XDifference, 2, '', 0, '', '', '99|199', 0, 0, true, 0, false, false);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, false);
        InsertData2('', '', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, false);
        InsertData2('', '230', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false, false);
        InsertData2('', '240', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.ServicesVATText()), 1, '', 2,
          DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false, false);
        InsertData2('35', '250', XValueofEUSales, 2, '', 0, '', '', '230|240', 0, 0, true, 1, false, false);
        InsertData2('', '310', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, false);
        InsertData2('', '311', XNonVATliablesalesOverseas, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, false);
        InsertData2('36', '319', XNonVATliablesalesOverseas, 2, '', 0, '', '', '310|311', 0, 0, true, 1, false, false);
        InsertData2('', '320', XNonVATliablesalesDomestic, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 0, false, false);
        InsertData2('37', '329', XNonVATliablesalesDomestic, 2, '', 0, '', '', '320..328', 0, 0, true, 1, false, false);
        // FES (320)
        InsertData2('', '10', XAmtSalesVAT16PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false, true);
        InsertData2('', 'B010', XBaseSalesVAT16PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('6', '19', XTAmtSalesVAT16PERCENToutgoing, 2, '', 0, '', '', '10..18', 0, 0, true, 1, false, true);
        InsertData2('5', 'B019', XTBaseSalesVAT16PERCENToutg, 2, '', 0, '', '', 'B010..B018', 0, 0, true, 1, false, true);
        InsertData2('', '1D', '16', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('', '20', XAmtSalesVAT7PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false, true);
        InsertData2('', 'B020', XBaseSalesVAT7PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('4', '29', XTAmtSalesVAT7PERCENToutgoing, 2, '', 0, '', '', '20..28', 0, 0, true, 1, false, true);
        InsertData2('3', 'B029', XTBaseSalesVAT7PERCENToutg, 2, '', 0, '', '', 'B020..B028', 0, 0, true, 1, false, true);
        InsertData2('', '2D', '7', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('', '30', XAmtSalesVAT4PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 1, false, true);
        InsertData2('', 'B030', XBaseSalesVAT4PERCENToutgoing, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('2', '39', XTAmtSalesVAT4PERCENToutgoing, 2, '', 0, '', '', '30..38', 0, 0, true, 1, false, true);
        InsertData2('1', 'B039', XTBaseSalesVAT4PERCENToutg, 2, '', 0, '', '', 'B030..B038', 0, 0, true, 1, false, true);
        InsertData2('', '3D', '4', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('', '4D', XTAmtSalesVAT, 2, '', 0, '', '', '19|29|39', 0, 0, true, 1, false, true);
        InsertData2('', '5D', XTBaseSalesVAT, 2, '', 0, '', '', 'B019|B029|B039', 0, 0, true, 1, false, true);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('', '40', XAmtVAT16PERCENTonEUSalesetc, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 1, false, true);
        InsertData2('', 'B040', XBaseVAT16PERCENTonEUSalesetc, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('26', '49', XTAmtVAT16PERCENTonEUSalesetc, 2, '', 0, '', '', '40..48', 0, 0, true, 1, false, true);
        InsertData2('25', 'B049', XTBaseVAT16PERCENTonEUSalesetc, 2, '', 0, '', '', 'B040..B048', 0, 0, true, 1, false, true);
        InsertData2('', '50', XAmtVAT7PERCENTonEUSalesetc, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 1, false, true);
        InsertData2('', 'B050', XBaseVAT7PERCENTonEUSalesetc, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('24', '59', XTAmtVAT7PERCENTonEUSalesetc, 2, '', 0, '', '', '50..58', 0, 0, true, 1, false, true);
        InsertData2('23', 'B059', XTBaseVAT7PERCENTonEUSalesetc, 2, '', 0, '', '', 'B050..B058', 0, 0, true, 1, false, true);
        InsertData2('', '60', XAmtVAT4PERCENTonEUSalesetc, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 1, false, true);
        InsertData2('', 'B060', XBaseVAT4PERCENTonEUSalesetc, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('22', '69', XTAmtVAT4PERCENTonEUSalesetc, 2, '', 0, '', '', '60..68', 0, 0, true, 1, false, true);
        InsertData2('21', 'B069', XTBaseVAT4PERCENTonEUSalesetc, 2, '', 0, '', '', 'B060..B068', 0, 0, true, 0, false, true);
        InsertData2('', '6D', XTotalAmtVATEUSales, 2, '', 0, '', '', '49|59|69', 0, 0, true, 1, false, true);
        InsertData2('', '7D', XTotalBaseVATEUSales, 2, '', 0, '', '', 'B049|B059|B069', 0, 0, true, 1, false, true);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('34', '1T', XTotalDuedVATAmount, 2, '', 0, '', '', '4D|6D', 0, 0, true, 1, false, true);
        InsertData2('33', '1TB', XTotalDuedBaseVAT, 2, '', 0, '', '', '5D|7D', 0, 0, true, 1, false, true);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('', '110', XAmountPurchaseVAT16PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, true);
        InsertData2('', 'B110', XBasePurchaseVAT16PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, true);
        InsertData2('195', '119', XTotAmountPurchaseVAT16PERCENT, 2, '', 0, '', '', '110..118', 0, 0, true, 0, false, true);
        InsertData2('194', 'B119', XTBaseAmtPurchaseVAT16PERCENT, 2, '', 0, '', '', 'B110..B118', 0, 0, true, 0, false, true);
        InsertData2('', '120', XAmountPurchaseVAT7PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, true);
        InsertData2('', 'B120', XBasePurchaseVAT7PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, true);
        InsertData2('193', '129', XTotAmtPurchaseVAT7PERCENT, 2, '', 0, '', '', '120..128', 0, 0, true, 0, false, true);
        InsertData2('192', 'B129', XTotBasePurchaseVAT7PERCENT, 2, '', 0, '', '', 'B120..B128', 0, 0, true, 0, false, true);
        InsertData2('', '130', XAmountPurchaseVAT4PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 0, false, true);
        InsertData2('', 'B130', XBasePurchaseVAT4PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 0, false, true);
        InsertData2('191', '139', XTotAmtPurchaseVAT4PERCENT, 2, '', 0, '', '', '130..138', 0, 0, true, 0, false, true);
        InsertData2('190', 'B139', XTotBasePurchaseVAT4PERCENT, 2, '', 0, '', '', 'B130..B138', 0, 0, true, 0, false, true);
        InsertData2('49', '8D', XTotalAmountPurchasesVAT, 2, '', 0, '', '', '119|129|139', 0, 0, true, 0, false, true);
        InsertData2('48', '9D', XTotalBasePurchasesVAT, 2, '', 0, '', '', 'B119|B129|B139', 0, 0, true, 0, false, true);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('', '140', XAmountPurchaseVAT16PERCENTEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, false, 0, false, true);
        InsertData2('', 'B140', XBasePurchaseVAT16PERCENTEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 0, false, true);
        InsertData2('219', '149', XTotAmtPurchaseVAT16PERCENTEU, 2, '', 0, '', '', '140..148', 0, 0, true, 0, false, true);
        InsertData2('218', 'B149', XTotBasePurchaseVAT16PERCENTEU, 2, '', 0, '', '', 'B140..B148', 0, 0, true, 0, false, true);
        InsertData2('', '150', XAmountPurchaseVAT7PERCENTEU, 2, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, false, 0, false, true);
        InsertData2('', 'B150', XBasePurchaseVAT7PERCENTEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 0, false, true);
        InsertData2('217', '159', XTotAmtPurchaseVAT7PERCENTEU, 2, '', 0, '', '', '150..158', 0, 0, true, 0, false, true);
        InsertData2('216', 'B159', XTotBasePurchaseVAT7PERCENTEU, 2, '', 0, '', '', 'B150..B158', 0, 0, true, 0, false, true);
        InsertData2('', '160', XAmountPurchaseVAT4PERCENTEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 1, 0, false, 0, false, true);
        InsertData2('', 'B160', XBasePurchaseVAT4PERCENTEU, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 0, false, true);
        InsertData2('215', '169', XTotAmtPurchaseVAT4PERCENTEU, 2, '', 0, '', '', '160..168', 0, 0, true, 0, false, true);
        InsertData2('214', 'B169', XTotBasePurchaseVAT4PERCENTEU, 2, '', 0, '', '', 'B160..B168', 0, 0, true, 0, false, true);
        InsertData2('57', '10D', XTotalAmountPurchasesEU, 2, '', 0, '', '', '149|159|169', 0, 0, true, 0, false, true);
        InsertData2('56', '11D', XTotalBasePurchasesEU, 2, '', 0, '', '', 'B149|B159|B169', 0, 0, true, 0, false, true);
        InsertData2('', '', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('64', '2T', XTotalDeductions, 2, '', 0, '', '', '8D|10D', 0, 0, true, 1, false, true);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('65', '3T', XDifference, 2, '', 0, '', '', '1T|2T', 0, 0, true, 0, false, true);
        InsertData2('', '', '--------------------------------------------------', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('', '', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, true);
        InsertData2('', '230', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.GoodsVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('', '240', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.ServicesVATText()), 1, '', 2,
          DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('', '250', StrSubstNo(XValueofEUSalesPERCENT, DemoDataSetup.ReducedVATText()), 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('', '260', XTotalValueofEUSales, 2, '', 0, '', '', '230|240|250', 0, 0, true, 1, false, true);
        InsertData2('', '310', XNonVATliablesalesOverseas16, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('', '311', XNonVATliablesalesOverseas7, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('', '312', XNonVATliablesalesOverseas4, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ReducedVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('', '319', XTNonVATliablesalesOverseas, 2, '', 0, '', '', '310|311|312', 0, 0, true, 1, false, true);
        InsertData2('', '320', XNonVATliablesalesDomestic, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, false, 1, false, true);
        InsertData2('', '329', XTNonVATliablesalesDomestic, 2, '', 0, '', '', '320..328', 0, 0, true, 1, false, true);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        NextLineNo: Integer;
        XSalesVATPERCENToutgoing: Label 'Sales VAT %1 (outgoing)';
        XVATPERCENTonEUPurchasesetc: Label 'VAT %1 % on EU Purchases etc.';
        XPurchaseVATPERCENTDomestic: Label 'Purchase VAT %1 Domestic';
        XPurchaseVATPERCENTEU: Label 'Purchase VAT %1 EU';
        XValueofEUPurchasesPERCENT: Label 'Value of EU Purchases %1';
        XValueofEUSalesPERCENT: Label 'Value of EU Sales %1';
        XTotal: Label 'Total';
        XPurchaseVATingoing: Label 'Purchase VAT (ingoing)';
        XTotalDeductions: Label 'Total Deductions';
        XVATPayable: Label 'VAT Payable';
        XValueofEUSales: Label 'Value of EU Sales';
        XTotalValueofEUSales: Label 'Total Value of EU Sales ';
        XNonVATliablesalesOverseas: Label 'Non-VAT liable sales, Overseas';
        XNonVATliablesalesDomestic: Label 'Non-VAT liable sales, Domestic';
        XVAT: Label 'VAT';
        XDEFAULT: Label 'DEFAULT';
        XAmtSalesVAT16PERCENToutgoing: Label 'Amount Sales VAT 16 % (outgoing)';
        XAmtSalesVAT7PERCENToutgoing: Label 'Amount Sales VAT 7 % (outgoing)';
        XAmtSalesVAT4PERCENToutgoing: Label 'Amount Sales VAT 4 % (outgoing)';
        XBaseSalesVAT16PERCENToutgoing: Label 'Base Sales VAT 16 % (outgoing)';
        XBaseSalesVAT7PERCENToutgoing: Label 'Base Sales VAT 7 % (outgoing)';
        XBaseSalesVAT4PERCENToutgoing: Label 'Base Sales VAT 4 % (outgoing)';
        XTAmtSalesVAT16PERCENToutgoing: Label 'Total Amount Sales VAT 16 % (outgoing)';
        XTAmtSalesVAT7PERCENToutgoing: Label 'Total Amount Sales VAT 7 % (outgoing)';
        XTAmtSalesVAT4PERCENToutgoing: Label 'Total Amount Sales VAT 4 % (outgoing)';
        XTBaseSalesVAT16PERCENToutg: Label 'Total Base Sales VAT 16 % (outgoing)';
        XTBaseSalesVAT7PERCENToutg: Label 'Total Base Sales VAT 7 % (outgoing)';
        XTBaseSalesVAT4PERCENToutg: Label 'Total Base Sales VAT 4 % (outgoing)';
        XTAmtSalesVAT: Label 'Total Amount Sales VAT';
        XTBaseSalesVAT: Label 'Total Base Sales VAT';
        XAmtVAT16PERCENTonEUPurchsetc: Label 'Amount VAT 16 % on EU Purchases etc.';
        XAmtVAT7PERCENTonEUPurchsetc: Label 'Amount VAT 7 % on EU Purchases etc.';
        XBaseVAT16PERCENTonEUPurchsetc: Label 'Base VAT 16 % on EU Purchases etc.';
        XBaseVAT7PERCENTonEUPurchsetc: Label 'Base VAT 7 % on EU Purchases etc.';
        XTAmtVAT16PERCENTonEUPurchsetc: Label 'Total Amount VAT 16 % on EU Purchases etc.';
        XTAmtVAT7PERCENTonEUPurchsetc: Label 'Total Amount VAT 7 % on EU Purchases etc.';
        XTBaseVAT16PERCENTonEUPurcsetc: Label 'Total Base VAT 16 % on EU Purchases etc.';
        XBaseAVAT7PERCENTonEUPurcsetc: Label 'Base Amount VAT 7 % on EU Purchases etc.';
        XTotalAmtVATEUPurchetc: Label 'Total Amount VAT EU Purchases etc.';
        XTotalBaseVATEUPurchetc: Label 'Total Base VAT EU Purchases etc.';
        XAmtVAT16PERCENTonEUSalesetc: Label 'Amount VAT 16 % on EU Sales etc.';
        XAmtVAT7PERCENTonEUSalesetc: Label 'Amount VAT 7 % on EU Sales etc.';
        XAmtVAT4PERCENTonEUSalesetc: Label 'Amount VAT 4 % on EU Sales etc.';
        XBaseVAT16PERCENTonEUSalesetc: Label 'Base VAT 16 % on EU Sales etc.';
        XBaseVAT7PERCENTonEUSalesetc: Label 'Base VAT 7 % on EU Sales etc.';
        XBaseVAT4PERCENTonEUSalesetc: Label 'Base VAT 4 % on EU Sales etc.';
        XTAmtVAT16PERCENTonEUSalesetc: Label 'Total Amount VAT 16 % on EU Sales etc.';
        XTAmtVAT7PERCENTonEUSalesetc: Label 'Total Amount VAT 7 % on EU Sales etc.';
        XTAmtVAT4PERCENTonEUSalesetc: Label 'Total Amount VAT 4 % on EU Sales etc.';
        XTBaseVAT16PERCENTonEUSalesetc: Label 'Total Base VAT 16 % on EU Sales etc.';
        XTBaseVAT7PERCENTonEUSalesetc: Label 'Total Base VAT 7 % on EU Sales etc.';
        XTBaseVAT4PERCENTonEUSalesetc: Label 'Total Base VAT 4 % on EU Sales etc.';
        XTotalAmtVATEUSales: Label 'Total Amount VAT EU Sales';
        XTotalBaseVATEUSales: Label 'Total Base VAT EU Sales';
        XTotalDuedVATAmount: Label 'Total Dued VAT Amount';
        XTotalDuedBaseVAT: Label 'Total Dued Base VAT';
        XAmountPurchaseVAT16PERCENT: Label 'Amount Purchase VAT 16 %';
        XBasePurchaseVAT16PERCENT: Label 'Base Purchase VAT 16 %';
        XTotAmountPurchaseVAT16PERCENT: Label 'Total Amount Purchase VAT 16 %';
        XTBaseAmtPurchaseVAT16PERCENT: Label 'Total Base Purchase VAT 16 %';
        XAmountPurchaseVAT7PERCENT: Label 'Amount Purchase VAT 7 %';
        XBasePurchaseVAT7PERCENT: Label 'Base Purchase VAT 7 %';
        XTotAmtPurchaseVAT7PERCENT: Label 'Total Amount Purchase VAT 7 %';
        XTotBasePurchaseVAT7PERCENT: Label 'Total Base Purchase VAT 7 %';
        XAmountPurchaseVAT4PERCENT: Label 'Amount Purchase VAT 4 %';
        XBasePurchaseVAT4PERCENT: Label 'Base Purchase VAT 4 %';
        XTotAmtPurchaseVAT4PERCENT: Label 'Total Amount Purchase VAT 4 %';
        XTotBasePurchaseVAT4PERCENT: Label 'Total Base Purchase VAT 4 %';
        XTotalAmountPurchases: Label 'Total Amount Purchases';
        XTotalBasePurchases: Label 'Total Base Purchases';
        XTotalAmountPurchasesVAT: Label 'Total Amount Purchases VAT';
        XTotalBasePurchasesVAT: Label 'Total Base Purchases VAT';
        XAmountPurchaseVAT16PERCENTEU: Label 'Amount Purchase VAT 16 % EU';
        XBasePurchaseVAT16PERCENTEU: Label 'Base Purchase VAT 16 % EU';
        XTotAmtPurchaseVAT16PERCENTEU: Label 'Total Amount Purchase VAT 16 % EU';
        XTotBasePurchaseVAT16PERCENTEU: Label 'Total Base Purchase VAT 16 % EU';
        XAmountPurchaseVAT7PERCENTEU: Label 'Amount Purchase VAT 7 % EU';
        XBasePurchaseVAT7PERCENTEU: Label 'Base Purchase VAT 7 % EU';
        XTotAmtPurchaseVAT7PERCENTEU: Label 'Total Amount Purchase VAT 7 % EU';
        XTotBasePurchaseVAT7PERCENTEU: Label 'Total Base Purchase VAT 7 % EU';
        XAmountPurchaseVAT4PERCENTEU: Label 'Amount Purchase VAT 4 % EU';
        XBasePurchaseVAT4PERCENTEU: Label 'Base Purchase VAT 4 % EU';
        XTotAmtPurchaseVAT4PERCENTEU: Label 'Total Amount Purchase VAT 4 % EU';
        XTotBasePurchaseVAT4PERCENTEU: Label 'Total Base Purchase VAT 4 % EU';
        XTotalAmountPurchasesEU: Label 'Total Amount Purchases EU';
        XTotalBasePurchasesEU: Label 'Total Base Purchases UE';
        XDifference: Label 'Difference';
        XSTMT320: Label 'Stmt. 320';
        XSTMT392: Label 'Stmt. 392';
        XNonVATliablesalesOverseas16: Label 'Non-VAT liable sales, Overseas 16%';
        XNonVATliablesalesOverseas7: Label 'Non-VAT liable sales, Overseas 7%';
        XNonVATliablesalesOverseas4: Label 'Non-VAT liable sales, Overseas 4%';
        XTNonVATliablesalesOverseas: Label 'Total Non-VAT liable sales, Overseas';
        XTNonVATliablesalesDomestic: Label 'Total Non-VAT liable sales, Domestic';

    procedure InsertData(Box: Code[4]; RowNo: Code[10]; Description: Text[50]; Type: Option; AccountTotaling: Text[30]; GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; RowTotaling: Text[30]; AmountType: Option; CalculateWith: Option; Print: Boolean; PrintWith: Option; NewPage: Boolean)
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
        VATStatementLine.Validate(Box, Box);
        VATStatementLine.Insert();
    end;

    procedure InsertData2(Box: Code[4]; "Row No.": Code[10]; Description: Text[50]; Type: Option; "Account Totaling": Text[30]; "Gen. Posting Type": Option; "VAT Bus. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "Row Totaling": Text[30]; "Amount Type": Option; "Calculate with": Option; Print: Boolean; "Print with": Option; "New Page": Boolean; XML: Boolean)
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.Init();
        VATStatementLine.Validate("Statement Template Name", XVAT);
        if XML then
            VATStatementLine.Validate("Statement Name", XSTMT392)
        else
            VATStatementLine.Validate("Statement Name", XSTMT320);
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
        VATStatementLine.Validate(Box, Box);
        VATStatementLine.Insert();
    end;
}

