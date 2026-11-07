codeunit 101256 "Create VAT Statement Line"
{

    trigger OnRun()
    begin
        exit;

    end;

    var
        NextLineNo: Integer;
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

