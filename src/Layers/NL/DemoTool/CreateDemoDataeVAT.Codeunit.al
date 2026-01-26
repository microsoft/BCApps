codeunit 160001 "Create Demo Data eVAT"
{

    trigger OnRun()
    begin
        InsertSetup();

        InsertVATCategory(X1A1, 3, 3, 0, 0, 0, 0, true);
        InsertVATCategory(X1A2, 3, 6, 0, 0, 0, 0, true);
        InsertVATCategory(X1B1, 3, 9, 0, 0, 0, 0, true);
        InsertVATCategory(X1B2, 3, 12, 0, 0, 0, 0, true);
        InsertVATCategory(X1C1, 3, 15, 0, 0, 0, 0, true);
        InsertVATCategory(X1C2, 3, 18, 0, 0, 0, 0, true);
        InsertVATCategory(X1D1, 3, 21, 0, 0, 0, 0, true);
        InsertVATCategory(X1D2, 3, 24, 0, 0, 0, 0, true);
        InsertVATCategory(X1E, 3, 27, 0, 0, 0, 0, true);
        InsertVATCategory(X2A1, 6, 0, 3, 0, 0, 0, true);
        InsertVATCategory(X2A2, 6, 0, 6, 0, 0, 0, true);
        InsertVATCategory(X3A, 9, 0, 0, 3, 0, 0, true);
        InsertVATCategory(X3B, 9, 0, 0, 6, 0, 0, true);
        InsertVATCategory(X3C, 9, 0, 0, 9, 0, 0, true);
        InsertVATCategory(X4A1, 12, 0, 0, 0, 3, 0, true);
        InsertVATCategory(X4A2, 12, 0, 0, 0, 6, 0, true);
        InsertVATCategory(X4B1, 12, 0, 0, 0, 9, 0, true);
        InsertVATCategory(X4B2, 12, 0, 0, 0, 12, 0, true);
        InsertVATCategory(X5A, 18, 0, 0, 0, 0, 3, false);
        InsertVATCategory(X5B, 18, 0, 0, 0, 0, 6, false);
        InsertVATCategory(X5D, 18, 0, 0, 0, 0, 9, true);
        InsertVATCategory(X5E, 18, 0, 0, 0, 0, 12, true);
        InsertVATCategory(X5F, 18, 0, 0, 0, 0, 15, true);
        InsertVATCategory(X5G, 18, 0, 0, 0, 0, 18, false);
    end;

    var
        X1A1: Label '1A-1';
        X1A2: Label '1A-2';
        X1B1: Label '1B-1';
        X1B2: Label '1B-2';
        X1C1: Label '1C-1';
        X1C2: Label '1C-2';
        X1D1: Label '1D-1';
        X1D2: Label '1D-2';
        X1E: Label '1E';
        X2A1: Label '2A-1';
        X2A2: Label '2A-2';
        X3A: Label '3A';
        X3B: Label '3B';
        X3C: Label '3C';
        X4A1: Label '4A-1';
        X4A2: Label '4A-2';
        X4B1: Label '4B-1';
        X4B2: Label '4B-2';
        X5A: Label '5A';
        X5B: Label '5B';
        X5D: Label '5D';
        X5E: Label '5E';
        X5F: Label '5F';
        X5G: Label '5G';
        XELVATDECL: Label 'ELVATDECL';
        XElecVATDeclarations: Label 'Elec. VAT Declarations';
        XELICLDECL: Label 'ELICLDECL';
        XElecICLDeclarations: Label 'Elec. ICL Declarations';
        XOtisFalls: Label 'Otis Falls';
        X654932167415: Label '6549-3216-7415';

    procedure InsertSetup()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        ElecTaxDeclarationSetup.Get();
        InsertNoSeries(
          ElecTaxDeclarationSetup."VAT Declaration Nos.", XELVATDECL, XElecVATDeclarations, 'VAT00001', 'VAT99999', '', '', 1, true);
        InsertNoSeries(
          ElecTaxDeclarationSetup."ICP Declaration Nos.", XELICLDECL, XElecICLDeclarations, 'ICP00001', 'ICP99999', '', '', 1, true);
        ElecTaxDeclarationSetup.Validate("VAT Contact Type", ElecTaxDeclarationSetup."VAT Contact Type"::"Tax Payer");
        ElecTaxDeclarationSetup.Validate("Tax Payer Contact Name", XOtisFalls);
        ElecTaxDeclarationSetup.Validate("Tax Payer Contact Phone No.", X654932167415);

        ElecTaxDeclarationSetup.Modify(true);
    end;

    procedure InsertNoSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[30]; StartingNo: Code[20]; EndingNo: Code[20]; LastNoUsed: Code[20]; WarningNo: Code[20]; IncrementBy: Integer; ManualNos: Boolean)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Init();
        NoSeries.Code := Code;
        NoSeries.Description := Description;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := ManualNos;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine.Validate("Last No. Used", LastNoUsed);
        if WarningNo <> '' then
            NoSeriesLine.Validate("Warning No.", WarningNo);
        NoSeriesLine.Validate("Increment-by No.", IncrementBy);
        NoSeriesLine.Insert(true);

        SeriesCode := Code;
    end;

    procedure InsertVATCategory("Code": Code[10]; Category: Option " ",,,"1. By Us (Domestic)",,,"2. To Us (Domestic)",,,"3. By Us (Foreign)",,,"4. To Us (Foreign)",,,,,,"5. Calculation"; ByUsDomestic: Option " ",,,"1a. Sales Amount (High Rate)",,,"1a. Tax Amount (High Rate)",,,"1b. Sales Amount (Low Rate)",,,"1b. Tax Amount (Low Rate)",,,"1c. Sales Amount (Other Non-Zero Rates)",,,"1c. Tax Amount (Other Non-Zero Rates)",,,"1d. Sales Amount (Private Use)",,,"1d. Tax Amount (Private Use)",,,"1e. Sales Amount (Non-Taxed)"; ToUsDomestic: Option; ByUsForeign: Option; ToUsForeign: Option; Calculation: Option; Optional: Boolean)
    var
        ElecTaxDeclVATCategory: Record "Elec. Tax Decl. VAT Category";
    begin
        ElecTaxDeclVATCategory.Init();
        ElecTaxDeclVATCategory.Validate(Code, Code);
        ElecTaxDeclVATCategory.Validate(Category, Category);
        ElecTaxDeclVATCategory.Validate("By Us (Domestic)", ByUsDomestic);
        ElecTaxDeclVATCategory.Validate("To Us (Domestic)", ToUsDomestic);
        ElecTaxDeclVATCategory.Validate("By Us (Foreign)", ByUsForeign);
        ElecTaxDeclVATCategory.Validate("To Us (Foreign)", ToUsForeign);
        ElecTaxDeclVATCategory.Validate(Calculation, Calculation);
        ElecTaxDeclVATCategory.Validate(Optional, Optional);
        ElecTaxDeclVATCategory.Insert(true);
    end;
}

