codeunit 101808 "Create Depreciation Book"
{

    trigger OnRun()
    begin
        "FA Setup".Get();
        InsertData(
          //"FA Setup"."Default Depr. Book",XCompanyBook,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,10);
          "FA Setup"."Default Depr. Book", XAccountingBook, true, true, true, true, true, true, true, true, false, 0, 1);
    end;

    var
        "FA Setup": Record "FA Setup";
        "Depreciation Book": Record "Depreciation Book";
        XAccountingBook: Label 'Accounting Book';

    procedure InsertData("Code": Code[10]; Description: Text[30]; "G/L Integration - Acq. Cost": Boolean; "G/L Integration - Depreciation": Boolean; "G/L Integration - Write Down": Boolean; "G/L Integration - Appreciation": Boolean; "G/L Integration - Custom 1": Boolean; "G/L Integration - Custom 2": Boolean; "G/L Integration - Disposal": Boolean; "G/L Integration - Maintenance": Boolean; "Use Rounding in Periodic Depr.": Boolean; "Default Final Rounding Amount": Decimal; "Disposal Calculation Method": Option)
    begin
        "Depreciation Book".Code := Code;
        "Depreciation Book".Description := Description;
        "Depreciation Book"."G/L Integration - Acq. Cost" := "G/L Integration - Acq. Cost";
        "Depreciation Book"."G/L Integration - Depreciation" := "G/L Integration - Depreciation";
        "Depreciation Book"."G/L Integration - Write-Down" := "G/L Integration - Write Down";
        "Depreciation Book"."G/L Integration - Appreciation" := "G/L Integration - Appreciation";
        "Depreciation Book"."G/L Integration - Custom 1" := "G/L Integration - Custom 1";
        "Depreciation Book"."G/L Integration - Custom 2" := "G/L Integration - Custom 2";
        "Depreciation Book"."G/L Integration - Disposal" := "G/L Integration - Disposal";
        "Depreciation Book"."G/L Integration - Maintenance" := "G/L Integration - Maintenance";
        "Depreciation Book"."G/L Integration - Derogatory" := true;
        "Depreciation Book"."Use Rounding in Periodic Depr." := "Use Rounding in Periodic Depr.";
        "Depreciation Book"."Default Final Rounding Amount" := "Default Final Rounding Amount";
        // Modif Demo Finance (CM) : initialisation de la loi avec méthode cession Brut.
        "Depreciation Book"."Disposal Calculation Method" := "Disposal Calculation Method";
        "Depreciation Book".Insert(true);
    end;
}

