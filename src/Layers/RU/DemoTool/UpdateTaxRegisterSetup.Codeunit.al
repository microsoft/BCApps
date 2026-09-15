codeunit 163407 "Update Tax Register Setup"
{

    trigger OnRun()
    var
        ExcelTemplate: Record "Excel Template";
    begin
        TaxRegSetup.Get();
        TaxRegSetup."Condition Dimension Code" := XTAXOBJ;
        TaxRegSetup."Kind Dimension Code" := XTAXKIND;
        TaxRegSetup."Create Acquis. FA Tax Ledger" := true;
        TaxRegSetup."Create Reclass. FA Tax Ledger" := true;
        TaxRegSetup."Create Disposal FA Tax Ledger" := true;
        TaxRegSetup."Tax Depreciation Book" := XTAXACC;
        TaxRegSetup."Future Exp. Depreciation Book" := XFETAX;
        TaxRegSetup."Default FA TD Code" := XEXFA + '1';
        TaxRegSetup."Depr. Bonus TD Code" := XEXFA + '2';
        TaxRegSetup."Depr. Bonus Recovery TD Code" := XEXFA + '5';
        TaxRegSetup."Disposal TD Code" := XEXFA + '6';

        TaxRegSetup."Sales VAT Ledg. Template Code" := TranslateAccounting.ExcelTemplateCode('VATSALLEDG');
        ExcelTemplate.InsertTemplate(TranslateAccounting.ExcelTemplateCode('VATSALLEDG'),
          XVATSalesLedger, 'LocalFiles\Sales VAT Ledger.xlsx');
        TaxRegSetup."Sales Add. Sheet Templ. Code" := TranslateAccounting.ExcelTemplateCode('VATSALADDS');
        ExcelTemplate.InsertTemplate(TranslateAccounting.ExcelTemplateCode('VATSALADDS'),
          XVATSalesLedgerAddSheet, 'LocalFiles\Sales VAT Ledger (Add. Sheet).xlsx');
        TaxRegSetup."Purch. VAT Ledg. Template Code" := TranslateAccounting.ExcelTemplateCode('VATPURLEDG');
        ExcelTemplate.InsertTemplate(TranslateAccounting.ExcelTemplateCode('VATPURLEDG'),
          XVATPurchLedger, 'LocalFiles\Purch VAT Ledger.xlsx');
        TaxRegSetup."Purch. Add. Sheet Templ. Code" := TranslateAccounting.ExcelTemplateCode('VATPURADDS');
        ExcelTemplate.InsertTemplate(TranslateAccounting.ExcelTemplateCode('VATPURADDS'),
          XVATPurchLedgerAddSheet, 'LocalFiles\Purch VAT Ledger (Add. Sheet).xlsx');
        TaxRegSetup."Tax Register Template Code" := TranslateAccounting.ExcelTemplateCode('TAXREG');
        ExcelTemplate.InsertTemplate(TranslateAccounting.ExcelTemplateCode('TAXREG'),
          XTaxRegister, 'LocalFiles\TaxRegister.xlsx');
        TaxRegSetup."VAT Iss./Rcvd. Jnl. Templ Code" := TranslateAccounting.ExcelTemplateCode('VATISSJNL');
        ExcelTemplate.InsertTemplate(TranslateAccounting.ExcelTemplateCode('VATISSJNL'),
          XVATIssuedJnl, 'LocalFiles\VAT Invoice Journal.xlsx');

        TaxRegSetup.Modify();
    end;

    var
        TaxRegSetup: Record "Tax Register Setup";
        XTAXOBJ: Label 'TAXOBJ';
        XTAXKIND: Label 'TAXKIND';
        XTAXACC: Label 'TAXACC';
        XFETAX: Label 'FETAX';
        XEXFA: Label 'EX-FA';
        XVATPurchLedger: Label 'VAT Purchase Ledger';
        XVATSalesLedger: Label 'VAT Sales Ledger';
        XVATPurchLedgerAddSheet: Label 'VAT Purchase Ledger (Add Sheet)';
        XVATSalesLedgerAddSheet: Label 'VAT Sales Ledger (Add Sheet)';
        XTaxRegister: Label 'Tax Register';
        XVATIssuedJnl: Label 'VAT Iss./Rcvd. Journal';
        TranslateAccounting: Codeunit "Translate Accounting";
}
