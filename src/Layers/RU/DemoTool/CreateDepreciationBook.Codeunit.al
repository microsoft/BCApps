codeunit 101808 "Create Depreciation Book"
{

    trigger OnRun()
    begin
        "FA Setup".Get();
        InsertData(XRENT, XFALeased, true, true, false, false, false, false, true, false, false, true, 1, 1, false);
        InsertData(XFAOB, XFAOffBalance, true, true, false, false, false, false, true, false, false, false, 0, 1, false);
        InsertData(XQUANTITY, XQuantitativeAccOfFA, false, false, false, false, false, false, false, false, false, false, 1, 3, false);
        InsertData(XCLOSEDOWN, XFAPreservation, true, true, false, false, false, false, false, false, false, false, 0, 1, false);
        InsertData(XTAXACC, XTaxAccounting, false, false, false, false, false, false, false, false, false, true, 0, 2, false);
        InsertData(XOPERATION, XFAInOperation, true, true, true, true, true, true, true, true, false, true, 10, 1, false);
        InsertData(XAQUISITION, XAcqOfFA, true, true, true, true, true, true, true, true, false, false, 10, 1, true);
        InsertData(XFEACC, XDefWithFinIntegr, true, true, true, true, true, true, true, true, false, true, 10, 1, false);
        InsertData(XFETAX, XTaxAccOfDef, false, false, false, false, false, false, false, false, false, true, 10, 2, false);
        InsertData(XUPGRADING, XFAModernization, true, true, true, true, true, true, true, true, false, false, 10, 1, false);
    end;

    var
        "FA Setup": Record "FA Setup";
        "Depreciation Book": Record "Depreciation Book";
        XRENT: Label 'RENT';
        XFAOB: Label 'FAOB';
        XQUANTITY: Label 'QUANTITY';
        XCLOSEDOWN: Label 'CLOSEDOWN';
        XTAXACC: Label 'TAXACC';
        XOPERATION: Label 'OPERATION';
        XFEACC: Label 'FEACC';
        XFETAX: Label 'FETAX';
        XAQUISITION: Label 'AQUISITION';
        XUPGRADING: Label 'UPGRADING';
        XFALeased: Label 'Fixed assets leased';
        XFAOffBalance: Label 'Fixed assets off-balance';
        XQuantitativeAccOfFA: Label 'Quantitative accounting of FA';
        XFAPreservation: Label 'FA preservation';
        XTaxAccounting: Label 'Tax accounting';
        XFAInOperation: Label 'FA in operation';
        XAcqOfFA: Label 'Acquisition of FA';
        XDefWithFinIntegr: Label 'Deferrals with fin. integr.';
        XTaxAccOfDef: Label 'Tax acc. of deferrals';
        XFAModernization: Label 'FA modernization';

    procedure InsertData("Code": Code[10]; Description: Text[30]; "G/L Integration - Acq. Cost": Boolean; "G/L Integration - Depreciation": Boolean; "G/L Integration - Write Down": Boolean; "G/L Integration - Appreciation": Boolean; "G/L Integration - Custom 1": Boolean; "G/L Integration - Custom 2": Boolean; "G/L Integration - Disposal": Boolean; "G/L Integration - Maintenance": Boolean; "Use Rounding in Periodic Depr.": Boolean; "Allow Depreciation": Boolean; "Default Final Rounding Amount": Decimal; "Posting Book Type": Integer; ControlFAAcquisCost: Boolean)
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
        "Depreciation Book"."Allow Changes in Depr. Fields" := true;
        "Depreciation Book"."Use FA Ledger Check" := true;
        "Depreciation Book"."Allow Depreciation" := "Allow Depreciation";
        "Depreciation Book"."Posting Book Type" := "Posting Book Type";
        if "Depreciation Book".Code = "FA Setup"."Release Depr. Book" then
            "Depreciation Book"."Allow Correction of Disposal" := true;
        if "Depreciation Book".Code = XTAXACC then
            "Depreciation Book"."Allow Correction of Disposal" := true;
        "Depreciation Book"."Mark Errors as Corrections" := true;
        "Depreciation Book"."Control FA Acquis. Cost" := ControlFAAcquisCost;
        if "Depreciation Book".Insert(true) then;
    end;
}

