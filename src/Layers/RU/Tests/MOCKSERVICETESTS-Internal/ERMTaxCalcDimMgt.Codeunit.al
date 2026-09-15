codeunit 144520 "ERM Tax Calc. Dim. Mgt."
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        TaxCalcDimMgt: Codeunit "Tax Calc. Dim. Mgt.";
        DimFiltersAreValidatedErr: Label 'Dimension filters are validated.';
        DimFiltersAreNotValidatedErr: Label 'Dimension filters are not validated.';
        WrongTaxRegIDTotalingErr: Label 'Wrong Tax Register ID totalling.';
        WrongDimValueCodeErr: Label 'Wrong dimensions value code.';
        WhereUsedFailedErr: Label 'Where-used function failed.';
        WrongFilterValueErr: Label 'Wrong filter on field %1 of table %2.';

    [Test]
    [Scope('OnPrem')]
    procedure SetDimFilters2TaxGLLine()
    var
        DimValue: Record "Dimension Value";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcGLEntry: Record "Tax Calc. G/L Entry";
    begin
        Initialize();
        InitTaxCalcLineWithFilter(DimValue, TaxCalcLine);
        TaxCalcDimMgt.SetDimFilters2TaxGLLine(TaxCalcLine, TaxCalcGLEntry);
        Assert.AreEqual(
          DimValue.Code,
          TaxCalcGLEntry.GetFilter("Dimension 1 Value Code"),
          StrSubstNo(WrongFilterValueErr, TaxCalcGLEntry.FieldCaption("Dimension 1 Value Code"), TaxCalcGLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimFilters2TaxItemLine()
    var
        DimValue: Record "Dimension Value";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
    begin
        Initialize();
        InitTaxCalcLineWithFilter(DimValue, TaxCalcLine);
        TaxCalcDimMgt.SetDimFilters2TaxCalcItemLine(TaxCalcLine, TaxCalcItemEntry);
        Assert.AreEqual(
          DimValue.Code,
          TaxCalcItemEntry.GetFilter("Dimension 1 Value Code"),
          StrSubstNo(WrongFilterValueErr, TaxCalcItemEntry.FieldCaption("Dimension 1 Value Code"), TaxCalcItemEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTemplateDimFiltersWithoutSet()
    var
        DimValue: Record "Dimension Value";
        TaxCalcLine: Record "Tax Calc. Line";
    begin
        Initialize();
        InitTaxCalcLineWithFilter(DimValue, TaxCalcLine);
        Assert.IsFalse(
          TaxCalcDimMgt.ValidateTaxCalcDimFilters(TaxCalcLine), DimFiltersAreValidatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTemplateDimFiltersWithSet()
    var
        DimValue: Record "Dimension Value";
        TaxCalcLine: Record "Tax Calc. Line";
    begin
        Initialize();
        InitTaxCalcLineWithFilter(DimValue, TaxCalcLine);
        TaxCalcDimMgt.SetTaxCalcEntryDim(TaxCalcLine."Section Code", DimValue.Code, '', '', '');
        Assert.IsTrue(
          TaxCalcDimMgt.ValidateTaxCalcDimFilters(TaxCalcLine), DimFiltersAreNotValidatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhereUsedByDimensions()
    var
        DimValue: array[2] of Record "Dimension Value";
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcDimCorrFilter: Record "Tax Calc. Dim. Corr. Filter";
        TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry";
        TaxRegIDTotaling: Code[250];
        DimValueCode: array[4] of Code[20];
    begin
        Initialize();
        CreateDimValue(DimValue[1]);
        LibraryTaxAcc.CreateTaxCalcHeader(
          TaxCalcHeader, CreateTaxCalcSection(DimValue[1]."Dimension Code", ''),
          DATABASE::"Tax Calc. G/L Entry");
        LibraryTaxAcc.CreateTaxCalcCorrespEntry(TaxCalcCorrespEntry, TaxCalcHeader."Section Code");
        LibraryTaxAcc.CreateTaxCalcDimCorrFilter(
          TaxCalcDimCorrFilter, TaxCalcHeader."Section Code");
        LibraryTaxAcc.CreateTaxCalcDimFilter(
          TaxCalcHeader."Section Code", TaxCalcHeader."No.", 0, DimValue[1]);
        TaxCalcDimMgt.SetTaxCalcEntryDim(TaxCalcHeader."Section Code", DimValue[1].Code, '', '', '');
        Assert.IsTrue(
          TaxCalcDimMgt.WhereUsedByDimensions(
            TaxCalcCorrespEntry, TaxRegIDTotaling, DimValueCode[1], DimValueCode[2], DimValueCode[3], DimValueCode[4]), WhereUsedFailedErr);
        Assert.AreEqual('~' + TaxCalcHeader."Register ID" + '~', TaxRegIDTotaling, WrongTaxRegIDTotalingErr);
        Assert.AreEqual(DimValue[1].Code, DimValueCode[1], WrongDimValueCodeErr);
    end;

    local procedure Initialize()
    begin
        Clear(TaxCalcDimMgt);
    end;

    local procedure InitTaxCalcLineWithFilter(var DimValue: Record "Dimension Value"; var TaxCalcLine: Record "Tax Calc. Line")
    begin
        CreateDimValue(DimValue);
        CreateTaxCalcLineWithDimension(TaxCalcLine, DimValue."Dimension Code");
        LibraryTaxAcc.CreateTaxCalcDimFilter(
          TaxCalcLine."Section Code", TaxCalcLine.Code, TaxCalcLine."Line No.", DimValue);
    end;

    local procedure CreateTaxCalcSection(Dimension1Code: Code[20]; Dimension2Code: Code[20]): Code[10]
    var
        TaxCalcSection: Record "Tax Calc. Section";
    begin
        TaxCalcSection.Init();
        TaxCalcSection.Code := LibraryUtility.GenerateGUID();
        TaxCalcSection."Dimension 1 Code" := Dimension1Code;
        TaxCalcSection."Dimension 2 Code" := Dimension2Code;
        TaxCalcSection.Insert();
        exit(TaxCalcSection.Code);
    end;

    local procedure CreateTaxCalcLineWithDimension(var TaxCalcLine: Record "Tax Calc. Line"; DimensionCode: Code[20])
    var
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        LibraryTaxAcc.CreateTaxCalcHeader(
          TaxCalcHeader, CreateTaxCalcSection(DimensionCode, ''), DATABASE::"Tax Register G/L Entry");
        LibraryTaxAcc.CreateTaxCalcLine(
          TaxCalcLine, 0, TaxCalcHeader."Section Code", TaxCalcHeader."No.");
    end;

    local procedure CreateDimValue(var DimValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
    end;
}

