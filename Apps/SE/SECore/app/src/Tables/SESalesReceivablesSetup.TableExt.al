tableextension 11291 "SE Sales & Receivables Setup" extends "Sales & Receivables Setup"
{
    var
        CompHasTaxAssessCaptionLbl: Label 'Company has Tax Assessment Note';

    procedure GetLegalStatementLabel(): Text
    begin
        exit(CompHasTaxAssessCaptionLbl);
    end;
}