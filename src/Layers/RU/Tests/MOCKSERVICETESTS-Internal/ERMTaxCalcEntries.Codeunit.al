codeunit 144524 "ERM Tax Calc. Entries"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        LibraryDimension: Codeunit "Library - Dimension";
        CreateTaxCalcEntries: Codeunit "Create Tax Calc. Entries";
        EntriesNotCreatedErr: Label '%1 have not been created.';
        WrongCheckResultErr: Label 'Wrong check result.';

    [Test]
    [Scope('OnPrem')]
    procedure TaxCalcEntries()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxCalcGLEntry: Record "Tax Calc. G/L Entry";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
    begin
        Initialize();
        TaxRegSection.FindFirst();
        TaxCalcGLEntry."Section Code" := TaxRegSection.Code;
        TaxCalcGLEntry."Starting Date" := TaxRegSection."Starting Date";
        TaxCalcGLEntry."Ending Date" := TaxRegSection."Ending Date";
        CODEUNIT.Run(CODEUNIT::"Create Tax Calc. Entries", TaxCalcGLEntry);
        TaxCalcAccumulation.SetRange("Section Code", TaxRegSection.Code);
        Assert.IsFalse(TaxCalcAccumulation.IsEmpty, StrSubstNo(EntriesNotCreatedErr, TaxCalcAccumulation.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuildTaxCalcCorresp()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry";
    begin
        Initialize();
        TaxRegSection.FindFirst();
        CreateTaxCalcEntries.BuildTaxCalcCorresp(
          TaxRegSection."Starting Date", TaxRegSection."Ending Date", TaxRegSection.Code);
        TaxCalcCorrespEntry.SetRange("Section Code", TaxRegSection.Code);
        Assert.IsFalse(TaxCalcCorrespEntry.IsEmpty, StrSubstNo(EntriesNotCreatedErr, TaxCalcCorrespEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckWrongDimValueFilter()
    var
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        TaxRegSection: Record "Tax Register Section";
        TaxRegister: Record "Tax Register";
        TaxCalcDimCorrFilter: Record "Tax Calc. Dim. Corr. Filter";
        TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry";
    begin
        Initialize();
        LibraryTaxAcc.CreateTaxRegSection(TaxRegSection);
        LibraryTaxAcc.CreateTaxReg(
          TaxRegister, TaxRegSection.Code, DATABASE::"Tax Register Accumulation", 0);
        LibraryTaxAcc.CreateTaxCalcCorrespEntry(TaxCalcCorrespEntry, TaxRegSection.Code);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
        LibraryTaxAcc.CreateTaxCalcDimCorrFilter(TaxCalcDimCorrFilter, TaxRegSection.Code);
        LibraryTaxAcc.CreateTaxCalcDimFilter(
          TaxRegister."Section Code", TaxRegister."No.", 0, DimValue);
        Assert.AreEqual(
          -1,
          CreateTaxCalcEntries.CheckDimValueFilter(
            TaxCalcDimCorrFilter, TaxCalcCorrespEntry."Entry No.", TaxRegister."No.", 0), WrongCheckResultErr);
    end;

    local procedure Initialize()
    begin
        Clear(CreateTaxCalcEntries);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

