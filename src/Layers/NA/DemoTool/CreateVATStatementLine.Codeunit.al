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
}

