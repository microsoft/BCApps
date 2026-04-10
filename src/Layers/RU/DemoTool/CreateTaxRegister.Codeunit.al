codeunit 163410 "Create Tax Register"
{

    trigger OnRun()
    begin
        DemoSetup.Get();
        InitTaxReg();

        TaxRegSection.ImportSettings('LocalFiles\' + DemoSetup."Language Code" + '_TaxRegisters.xml');

        if TaxRegSection.FindFirst() then begin
            TaxRegSection."Starting Date" := MakeAdjustment.AdjustDate(19020101D);
            TaxRegSection."Ending Date" := MakeAdjustment.AdjustDate(19021231D);
            TaxRegSection.Modify();
        end;

        TaxRegTemplate.GenerateProfile();
        NormTemplateLine.GenerateProfile();
        TaxCalcLine.GenerateProfile();

        TaxRegTerm.GenerateProfile();
        NormTerm.GenerateProfile();
        TaxCalcTerm.GenerateProfile();
    end;

    var
        DemoSetup: Record "Demo Data Setup";
        TaxRegSetup: Record "Tax Register Setup";
        TaxRegSection: Record "Tax Register Section";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegTerm: Record "Tax Register Term";
        NormTemplateLine: Record "Tax Reg. Norm Template Line";
        NormTerm: Record "Tax Reg. Norm Term";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcTerm: Record "Tax Calc. Term";
        XTAXACC: Label 'TAXACC';
        XFETAX: Label 'FETAX';
        MakeAdjustment: Codeunit "Make Adjustments";
        XTAXOBJ: Label 'TAXOBJ';
        XTAXKIND: Label 'TAXKIND';
        XEXFA: Label 'EX-FA';
        TranslateAccounting: Codeunit "Translate Accounting";

    procedure InitTaxReg()
    begin
        TaxRegSetup.Validate("Condition Dimension Code", XTAXOBJ);
        TaxRegSetup.Validate("Kind Dimension Code", XTAXKIND);
        TaxRegSetup.Validate("Create Acquis. FA Tax Ledger", true);
        TaxRegSetup.Validate("Create Reclass. FA Tax Ledger", true);
        TaxRegSetup.Validate("Create Disposal FA Tax Ledger", false);
        TaxRegSetup.Validate("Tax Depreciation Book", XTAXACC);
        TaxRegSetup.Validate("Future Exp. Depreciation Book", XFETAX);
        TaxRegSetup.Validate("Create Acquis. FE Tax Ledger", true);
        TaxRegSetup.Validate("Calculate TD for each FA", true);
        TaxRegSetup.Validate("Depr. Bonus Recovery from", MakeAdjustment.AdjustDate(19030101D));
        TaxRegSetup.Validate("Depr. Bonus Recov. Per. (Year)", 5);

        TaxRegSetup."Default FA TD Code" := XEXFA + '1';
        TaxRegSetup."Depr. Bonus TD Code" := XEXFA + '2';
        TaxRegSetup."Depr. Bonus Recovery TD Code" := XEXFA + '5';
        TaxRegSetup."Disposal TD Code" := XEXFA + '6';

        TaxRegSetup."Sales VAT Ledg. Template Code" := CopyStr(TranslateAccounting.ExcelTemplateCode('VATSALLEDG'), 1, 10);
        TaxRegSetup."Sales Add. Sheet Templ. Code" := CopyStr(TranslateAccounting.ExcelTemplateCode('VATSALADDS'), 1, 10);
        TaxRegSetup."Purch. VAT Ledg. Template Code" := CopyStr(TranslateAccounting.ExcelTemplateCode('VATPURLEDG'), 1, 10);
        TaxRegSetup."Purch. Add. Sheet Templ. Code" := CopyStr(TranslateAccounting.ExcelTemplateCode('VATPURADDS'), 1, 10);
        TaxRegSetup."Tax Register Template Code" := CopyStr(TranslateAccounting.ExcelTemplateCode('TAXREG'), 1, 10);
        TaxRegSetup."VAT Iss./Rcvd. Jnl. Templ Code" := CopyStr(TranslateAccounting.ExcelTemplateCode('VATISSJNL'), 1, 10);

        if not TaxRegSetup.Insert() then
            TaxRegSetup.Modify();
    end;

    procedure InsertTaxRegTerm(SectionCode: Code[10]; TermCode: Code[20]; ExpressionType: Integer; Expression: Text[150]; Check: Boolean; ProcessSign: Integer; Description: Text[150]; RoundingPrecision: Decimal)
    var
        TaxRegTerm: Record "Tax Register Term";
    begin
        TaxRegTerm.Init();
        TaxRegTerm.Validate("Section Code", SectionCode);
        TaxRegTerm.Validate("Term Code", TermCode);
        TaxRegTerm.Validate("Expression Type", ExpressionType);
        TaxRegTerm.Validate(Expression, Expression);
        TaxRegTerm.Validate(Check, Check);
        TaxRegTerm.Validate("Process Sign", ProcessSign);
        TaxRegTerm.Validate(Description, Description);
        TaxRegTerm.Validate("Rounding Precision", RoundingPrecision);
        TaxRegTerm.Insert();
    end;

    procedure InsertTaxRegTermLine(SectionCode: Code[10]; TermCode: Code[20]; LineNo: Integer; Operation: Integer; AccountType: Integer; AccountNo: Code[100]; AmountType: Integer; BalAccountNo: Code[100]; ProcessSign: Integer; ProcessDivisionbyZero: Integer)
    var
        TaxRegTermLine: Record "Tax Register Term Formula";
    begin
        TaxRegTermLine.Init();
        TaxRegTermLine.Validate("Section Code", SectionCode);
        TaxRegTermLine.Validate("Term Code", TermCode);
        TaxRegTermLine.Validate("Line No.", LineNo);
        TaxRegTermLine.Validate("Account Type", AccountType);
        TaxRegTermLine.Validate("Account No.", AccountNo);
        TaxRegTermLine.Validate("Bal. Account No.", BalAccountNo);
        TaxRegTermLine."Amount Type" := AmountType;
        TaxRegTermLine.Operation := Operation;
        TaxRegTermLine.Validate("Process Sign", ProcessSign);
        TaxRegTermLine.Validate("Process Division by Zero", ProcessDivisionbyZero);
        // TaxRegTermLine."Expression Type" := ExpressionType;
        // TaxRegTermLine.VALIDATE("Norm Jurisdiction Code", NormJurisdictionCode);

        TaxRegTermLine.Insert();
    end;
}

