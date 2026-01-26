codeunit 101256 "Create VAT Statement Line"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            exit;

        InsertData('0010', xRevenueTitle, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0020', xSalesTitle, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0022', xNormalVatRate, 1, '', 2, DemoDataSetup.DomesticCode(), XVATNormal, '', 2, 1, true, 0, false);
        InsertData('0026', xReducedVatRate, 1, '', 2, DemoDataSetup.DomesticCode(), xVATRed, '', 2, 1, true, 0, false);
        InsertData('0032', xExportNormalVatRate, 1, '', 2, DemoDataSetup.ExportCode(), XVATNormal, '', 2, 1, false, 0, false);
        InsertData('0036', xExportRedVatRate, 1, '', 2, DemoDataSetup.ExportCode(), xVATRed, '', 2, 1, false, 0, false);
        InsertData('0040', xExportRevenue, 2, '', 0, '', '', '0030..0039', 0, 0, true, 0, false);
        InsertData('0048', xTotalRevenue, 2, '', 0, '', '', '0020..0039', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0060', xDeductions, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0062', xExportNormalVatRate, 1, '', 2, DemoDataSetup.ExportCode(), XVATNormal, '', 2, 0, true, 0, false);
        InsertData('0064', xExportRedVatRate, 1, '', 2, DemoDataSetup.ExportCode(), xVATRed, '', 2, 0, true, 0, false);
        InsertData('0098', xTotalOfDeductions, 2, '', 0, '', '', '0060..0097', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0099', xTaxableRevenue, 2, '', 0, '', '', '0048|0098', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0100', xVATStatement, 2, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0124', xNormalVatRate, 1, '', 2, DemoDataSetup.DomesticCode(), XVATNormal, '', 1, 0, true, 0, false);
        InsertData('0126', xReducedVatRate, 1, '', 2, DemoDataSetup.DomesticCode(), xVATRed, '', 1, 0, true, 0, false);
        InsertData('0199', xTotalVAT, 2, '', 0, '', '', '0101..0198', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0200', xAccountablePurchaseVAT, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0222', xNormalVatRate, 1, '', 1, DemoDataSetup.DomesticCode(), XVATNormal, '', 1, 0, true, 0, false);
        InsertData('0224', xReducedVatRate, 1, '', 1, DemoDataSetup.DomesticCode(), xVATRed, '', 1, 0, true, 0, false);
        InsertData('0262', xImportNormalVatRate, 1, '', 1, DemoDataSetup.ExportCode(), XVATNormal, '', 1, 0, true, 0, false);
        InsertData('0264', xImportRedVatRate, 1, '', 1, DemoDataSetup.ExportCode(), xVATRed, '', 1, 0, true, 0, false);
        InsertData('0280', xFullImportTax, 1, '', 1, DemoDataSetup.DomesticCode(), xVATImport, '', 1, 0, true, 0, false);
        InsertData('0299', xTotalPurchMatServ, 2, '', 0, '', '', '0200..0298', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0300', xInvesBusExp, 1, '', 1, DemoDataSetup.DomesticCode(), xVATOpexp, '', 1, 0, true, 0, false);
        InsertData('0310', xBusExpHalf, 1, '', 1, DemoDataSetup.DomesticCode(), xVATHalfNor, '', 1, 0, true, 0, false);
        InsertData('0320', xBusExpHotel, 1, '', 1, DemoDataSetup.DomesticCode(), XVATHOTEL, '', 1, 0, true, 0, false);
        InsertData('0399', xTotalPurchBusExp, 2, '', 0, '', '', '0300..0398', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0400', xTotalPurchVAT, 2, '', 0, '', '', '0299|0399', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0500', xAmountPayable, 2, '', 0, '', '', '0199|0400', 0, 0, true, 1, false);
        InsertData('1230', xValueofEUExports, 1, '', 2, DemoDataSetup.ExportCode(), XVATNormal, '', 2, 0, false, 1, false);
        InsertData('', xValueofEUExports16, 2, '', 0, '', '', '1230..1238', 0, 0, true, 1, false);
        InsertData('1240', xValueofEUExports, 1, '', 2, DemoDataSetup.ExportCode(), XVATHOTEL, '', 2, 1, false, 1, false);
        InsertData('', xValueofEUExports7, 2, '', 0, '', '', '1240..1248', 0, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('1310', xCountryExport, 1, '', 2, DemoDataSetup.ExportCode(), XVATNormal, '', 2, 0, false, 0, false);
        InsertData('1312', xCountryExport, 1, '', 2, DemoDataSetup.ExportCode(), XVATHOTEL, '', 2, 1, false, 0, false);
        InsertData('', xCountryExport, 2, '', 0, '', '', '1310..1318', 0, 0, true, 1, false);
        InsertData('1320', xTaxFreeSalesDomestic, 1, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', 2, 1, false, 0, false);
        InsertData('', xTaxFreeSalesDomestic, 2, '', 0, '', '', '1320..1328', 0, 0, true, 1, false);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        NextLineNo: Integer;
        XVAT: Label 'VAT';
        XDEFAULT: Label 'DEFAULT';
        XVATHOTEL: Label 'Hotel';
        XVATNormal: Label 'NORMAL';
        xRevenueTitle: Label 'I. REVENUE';
        xSalesTitle: Label '1. Sales';
        xNormalVatRate: Label 'Normal VAT rate';
        xReducedVatRate: Label 'Reduced VAT rate';
        xVATRed: Label 'RED';
        xExportNormalVatRate: Label 'Export at normal VAT rate';
        xExportRedVatRate: Label 'Export at red. VAT rate';
        xExportRevenue: Label 'Export Revenue';
        xTotalRevenue: Label '3. Total Revenue';
        xDeductions: Label '4. Deductions';
        xTotalOfDeductions: Label '5. Total Deductions';
        xTaxableRevenue: Label '6. TAXABLE REVENUE';
        xVATStatement: Label 'II. VAT STATEMENT';
        xTotalVAT: Label '10. TOTAL VAT';
        xAccountablePurchaseVAT: Label '11. Accountable purchase VAT';
        xImportNormalVatRate: Label 'Import normal VAT rate';
        xImportRedVatRate: Label 'Import red. VAT rate';
        xFullImportTax: Label 'Full import Tax (to shipping agent)';
        xTotalPurchMatServ: Label '11a Total purchase VAT mat. & services';
        xVATImport: Label 'IMPORT';
        xInvesBusExp: Label 'Investment and business expenses';
        xVATOpexp: Label 'OPEXP';
        xVATHalfNor: Label 'Half Norm';
        xBusExpHalf: Label 'Business expenses with1/2 purch. VAT';
        xBusExpHotel: Label 'Business exp. Hotel';
        xTotalPurchBusExp: Label '11b Total purch. VAT business expenses';
        xTotalPurchVAT: Label '12. Total purch. VAT';
        xAmountPayable: Label '15. Amount Payable';
        xValueofEUExports: Label 'Value of EU exports';
        xValueofEUExports16: Label 'Value of EU exports 16%';
        xValueofEUExports7: Label 'Value of EU exports 7%';
        xCountryExport: Label '3rd Country Export, overseas';
        xTaxFreeSalesDomestic: Label 'Tax-Free sales, domestic';

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

