codeunit 163412 "Create Tax Depreciation Book"
{

    trigger OnRun()
    begin
        DepreciationBook.Init();
        DepreciationBook.Code := XTAXACC;
        DepreciationBook.Description := XTaxAccounting;
        DepreciationBook."Allow Correction of Disposal" := true;
        DepreciationBook."Allow Depreciation" := true; // FIX FOR 43205
        if not DepreciationBook.Get(XTAXACC) then
            if DepreciationBook.Insert(true) then;
    end;

    var
        DepreciationBook: Record "Depreciation Book";
        XTAXACC: Label 'TAXACC';
        XTaxAccounting: Label 'Tax Accounting';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
    end;
}

