codeunit 160200 "Create FA Derog. Depr. Book"
{

    trigger OnRun()
    begin
        InsertData(XTAX, XDerogatoryBook, 1, XCOMPANY);
    end;

    var
        "Depreciation Book": Record "Depreciation Book";
        XTAX: Label 'TAX';
        XDerogatoryBook: Label 'Derogatory Book';
        XCOMPANY: Label 'COMPANY';

    procedure InsertData("Code": Code[10]; Description: Text[30]; "Disposal Calculation Method": Option; "Derogatory Calculation": Code[10])
    begin
        "Depreciation Book".Code := Code;
        "Depreciation Book".Description := Description;
        "Depreciation Book"."Disposal Calculation Method" := "Disposal Calculation Method";
#if not CLEAN28
        "Depreciation Book"."Derogatory Calculation" := "Derogatory Calculation";
#else
        "Depreciation Book"."Derogatory Calc." := "Derogatory Calculation";
#endif
        "Depreciation Book".Insert(true);
    end;
}

