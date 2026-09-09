codeunit 101256 "Create VAT Statement Line"
{

    trigger OnRun()
    begin
        exit;

    end;

    var
        "Demonstration Data Setup": Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        NextLineNo: Integer;
        XSalesVAT25PERCENToutgoing: Label 'Sales VAT 25 % (outgoing)';
        XNATIONAL: Label 'NATIONAL';
        XVAT25: Label 'VAT25';
        XSalesVAT10PERCENToutgoing: Label 'Sales VAT 10 % (outgoing)';
        XVAT10: Label 'VAT10';
        XVAT25PERCENTonEUPurchasesetc: Label 'VAT 25 % on EU Purchases etc.';
        XVAT10PERCENTonEUPurchasesetc: Label 'VAT 10 % on EU Purchases etc.';
        XEU: Label 'EU';
        XTotal: Label 'Total';
        XPurchaseVAT25PERCENTDomestic: Label 'Purchase VAT 25 % Domestic';
        XPurchaseVAT10PERCENTDomestic: Label 'Purchase VAT 10 % Domestic';
        XPurchaseVAT25PERCENTEU: Label 'Purchase VAT 25 % EU';
        XPurchaseVAT10PERCENTEU: Label 'Purchase VAT 10 % EU';
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
        XValueofEUPurchases25PERCENT: Label 'Value of EU Purchases 25 %';
        XValueofEUPurchases10PERCENT: Label 'Value of EU Purchases 10 %';
        XValueofEUSales: Label 'Value of EU Sales';
        XValueofEUSales25PERCENT: Label 'Value of EU Sales25 %';
        XValueofEUSales10PERCENT: Label 'Value of EU Sales 10 %';
        XNonVATliablesalesOverseas: Label 'Non-VAT liable sales, Overseas';
        XNonVATliablesalesDomestic: Label 'Non-VAT liable sales, Domestic';
        XNOVAT: Label 'NO VAT';
        XEXPORT: Label 'EXPORT';
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

