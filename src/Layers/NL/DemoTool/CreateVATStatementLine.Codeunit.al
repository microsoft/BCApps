codeunit 101256 "Create VAT Statement Line"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            exit;

        CODEUNIT.Run(CODEUNIT::"Create Demo Data eVAT");

        InsertData('', XSalesDomestic, 3, '', 0, '', '', '', 0, 0, true, 0, false, '');
        InsertData('1A-1', XTaxedWith19PERCENTBaseAmount, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 1, false, '1A-1');
        InsertData('1A-2', XTaxedWith19PERCENTTaxAmount, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 1, false, '1A-2');
        InsertData('1B-1', XTaxedWith6PERCENTBaseAmount, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 1, false, '1B-1');
        InsertData('1B-2', XTaxedWith6PERCENTTaxAmount, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 1, false, '1B-2');
        InsertData('1E', '', 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 0, true, 1, false, '1E');

        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false, '');
        InsertData('', XPurchasesDomestic, 3, '', 0, '', '', '', 0, 0, true, 0, false, '');

        InsertData('2A-1', XTaxedWith19PERCENTBaseAmount, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('2A-1', XTaxedWith6PERCENTBaseAmount, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('', XPurchasesDomesticBaseAmount, 2, '', 0, '', '', '2A-1', 0, 0, true, 0, false, '2A-1');

        InsertData('2A-2', XTaxedWith19PERCENTTaxAmount, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 1, false, '');
        InsertData('2A-2', XTaxedWith6PERCENTTaxAmount, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 1, false, '');
        InsertData('', XPurchasesDomesticTaxAmount, 2, '', 0, '', '', '2A-2', 0, 0, true, 0, false, '2A-2');

        InsertData('', XSalesForeignNonEU, 3, '', 0, '', '', '', 0, 0, true, 1, false, '');
        InsertData('3A', XTaxedWith19PERCENTBaseAmount, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('3A', XTaxedWith6PERCENTBaseAmount, 1, '', 2, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('', XNonEUShipments, 2, '', 0, '', '', '3A', 0, 0, true, 1, false, '3A');

        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 1, false, '');

        InsertData('', XSalesForeignEU, 3, '', 0, '', '', '', 0, 0, true, 1, false, '');
        InsertData('3B', XTaxedWith19PERCENTBaseAmount, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('3B', XTaxedWith6PERCENTBaseAmount, 1, '', 2, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('', XEUShipments, 2, '', 0, '', '', '3B', 0, 0, true, 1, false, '3B');

        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 1, false, '');
        InsertData('', XPurchaseForeign, 0, '', 0, '', '', '', 0, 0, true, 1, false, '');

        InsertData('4A-1', XTaxedWith19PERCENTBaseAmount, 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('4A-1', XTaxedWith6PERCENTBaseAmount, 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('', XPurchasesForeignNonEUBaseAmount, 2, '', 0, '', '', '4A-1', 0, 0, true, 0, false, '4A-1');

        InsertData('4A-2', XTaxedWith19PERCENTTaxAmount, 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 1, false, '');
        InsertData('4A-2', XTaxedWith6PERCENTTaxAmount, 1, '', 1, DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 1, false, '');
        InsertData('', XPurchasesForeignNonEUTaxAmount, 2, '', 0, '', '', '4A-2', 0, 0, true, 0, false, '4A-2');

        InsertData('4B-1', XTaxedWith19PERCENTBaseAmount, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('4B-1', XTaxedWith6PERCENTBaseAmount, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 2, 0, true, 1, false, '');
        InsertData('', XPurchasesForeingEUBaseAmount, 2, '', 0, '', '', '4B-1', 0, 0, true, 0, false, '4B-1');

        InsertData('4B-2', XTaxedWith19PERCENTTaxAmount, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 1, false, '');
        InsertData('4B-2', XTaxedWith6PERCENTTaxAmount, 1, '', 1, DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 1, false, '');
        InsertData('', XPurchasesForeingEUTaxAmount, 2, '', 0, '', '', '4B-2', 0, 0, true, 0, false, '4B-2');

        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 1, false, '');

        InsertData('5A', XSubTotalSalesTax, 2, '', 0, '', '', '1A-2|1B-2', 0, 0, true, 1, false, '5A');

        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false, '');

        InsertData('', XPurchasesDomestic, 3, '', 0, '', '', '', 0, 0, true, 0, false, '');
        InsertData('5B', XTaxedWith19PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), '', 1, 0, true, 0, false, '');
        InsertData('5B', XTaxedWith6PERCENT, 1, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), '', 1, 0, true, 0, false, '');
        InsertData('', XPaidInAdvance, 2, '', 0, '', '', '5B', 0, 0, true, 0, false, '5B');
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, true, 0, false, '');
        InsertData('5C', XSubTotal, 2, '', 0, '', '', '5A|5B', 0, 0, true, 1, false, '');
        InsertData('5D', '', 0, '1580', 0, '', '', '', 0, 0, true, 0, false, '5D');
        InsertData('5D-1', '', 0, '1580', 0, '', '', '', 0, 0, true, 0, false, '');
        InsertData('5G', '', 0, '', 0, '', '', '5C|5D-1', 0, 0, true, 0, false, '5G');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        NextLineNo: Integer;
        XSalesDomestic: Label 'Sales (Domestic)';
        XSalesForeignNonEU: Label 'Sales (Foreign; non-EU)';
        XSalesForeignEU: Label 'Sales (Foreign; EU)';
        XPurchasesDomestic: Label 'Purchases (Domestic)';
        XTaxedWith19PERCENTBaseAmount: Label 'Taxed with 21% (Base Amount)';
        XTaxedWith19PERCENTTaxAmount: Label 'Taxed with 21% (Tax Amount)';
        XTaxedWith6PERCENTBaseAmount: Label 'Taxed with 6% (Base Amount)';
        XTaxedWith6PERCENTTaxAmount: Label 'Taxed with 6% (Tax Amount)';
        XTaxedWith19PERCENT: Label 'Taxed with 21%';
        XTaxedWith6PERCENT: Label 'Taxed with 6%';
        XNonEUShipments: Label 'Non-EU Shipments';
        XEUShipments: Label 'EU Shipments';
        XSubTotalSalesTax: Label 'Subtotal Sales Tax';
        XPaidInAdvance: Label 'Paid in advance';
        XSubTotal: Label 'Subtotal';
        XVAT: Label 'VAT';
        XDEFAULT: Label 'DEFAULT';
        XPurchasesDomesticBaseAmount: Label 'Purchases (Domestic; Base Amount)';
        XPurchasesDomesticTaxAmount: Label 'Purchases (Domestic; Tax Amount)';
        XPurchaseForeign: Label 'Purchases (Foreign)';
        XPurchasesForeignNonEUBaseAmount: Label 'Purchases (Foreign; non-EU;Base Amount)';
        XPurchasesForeignNonEUTaxAmount: Label 'Purchases (Foreign; non-EU;Tax Amount)';
        XPurchasesForeingEUBaseAmount: Label 'Purchases (Foreign; EU; Base Amount)';
        XPurchasesForeingEUTaxAmount: Label 'Purchases (Foreign; EU; Tax Amount)';

    procedure InsertData(RowNo: Code[10]; Description: Text[50]; Type: Option; AccountTotaling: Text[30]; GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; RowTotaling: Text[30]; AmountType: Option; CalculateWith: Option; Print: Boolean; PrintWith: Option; NewPage: Boolean; "Elec. Tax Decl. Category Code": Code[10])
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
        VATStatementLine.Validate("Elec. Tax Decl. Category Code", "Elec. Tax Decl. Category Code");
        VATStatementLine.Validate("Box No.", "Elec. Tax Decl. Category Code");
        VATStatementLine.Insert();
    end;
}

