codeunit 101808 "Create Depreciation Book"
{

    trigger OnRun()
    begin
        "FA Setup".Get();
        // NAVCZ
        DemoDataSetup.Get();
        InsertData("FA Setup"."Default Depr. Book", 'Účetní kniha', true, true, true, true, true, true, true, true, 1, false, true, 10, true, true, true);
        InsertData('2-DAŇOVÁ', 'Daňová kniha', false, false, false, false, false, false, false, false, 1, false, true, 10, true, false, false);
        // NAVCZ
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "FA Setup": Record "FA Setup";
        "Depreciation Book": Record "Depreciation Book";

    procedure InsertData("Code": Code[10]; Description: Text[30]; "G/L Integration - Acq. Cost": Boolean; "G/L Integration - Depreciation": Boolean; "G/L Integration - Write Down": Boolean; "G/L Integration - Appreciation": Boolean; "G/L Integration - Custom 1": Boolean; "G/L Integration - Custom 2": Boolean; "G/L Integration - Disposal": Boolean; "G/L Integration - Maintenance": Boolean; "Disposal Calculation Method": Option; "Part of Duplication List": Boolean; "Use Rounding in Periodic Depr.": Boolean; "Default Final Rounding Amount": Decimal; "Mark Errors as Corrections": Boolean; "Corresp. G/L Entries on Disp.": Boolean; "Corresp. FA Entries on Disp.": Boolean)
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
        "Depreciation Book"."Use Rounding in Periodic Depr." := "Use Rounding in Periodic Depr.";
        "Depreciation Book"."Default Final Rounding Amount" := "Default Final Rounding Amount";
        // NAVCZ
        "Depreciation Book"."Disposal Calculation Method" := "Disposal Calculation Method";
        "Depreciation Book"."Part of Duplication List" := "Part of Duplication List";
        "Depreciation Book"."Mark Errors as Corrections" := "Mark Errors as Corrections";
        "Depreciation Book"."Corresp. G/L Entries Disp. CZF" := "Corresp. G/L Entries on Disp.";
        "Depreciation Book"."Corresp. FA Entries Disp. CZF" := "Corresp. FA Entries on Disp.";

        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Extended then begin
            "Depreciation Book"."Allow Changes in Depr. Fields" := true;
            "Depreciation Book"."Allow Correction of Disposal" := true;
            "Depreciation Book"."Allow Identical Document No." := true;
            "Depreciation Book"."All Acquisit. in same Year CZF" := true;
            "Depreciation Book"."Check Deprec. on Disposal CZF" := true;
            if Code = "FA Setup"."Default Depr. Book" then begin
                "Depreciation Book"."VAT on Net Disposal Entries" := true;
                "Depreciation Book"."Deprec. from 1st Month Day CZF" := true;
                "Depreciation Book"."Check Acq. Appr. bef. Dep. CZF" := true;
            end;
        end;
        // NAVCZ
        "Depreciation Book".Insert(true);
    end;

    procedure CreateMiniAppData()
    begin
        // NAVCZ
        "FA Setup".Get();
        DemoDataSetup.Get();
        InsertData("FA Setup"."Default Depr. Book", 'Účetní kniha', true, true, true, true, true, true, true, true, 1, false, true, 0, true, true, true);
        InsertData('2-DAŇOVÁ', 'Daňová kniha', false, false, false, false, false, false, false, false, 1, true, true, 0, true, false, false);
    end;
}

