codeunit 144518 "ERM Tax Dimension Mgt."
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        TaxDimMgt: Codeunit "Tax Dimension Mgt.";
        DimFiltersAreValidatedErr: Label 'Dimension filters are validated.';
        DimFiltersAreNotValidatedErr: Label 'Dimension filters are not validated.';
        DimRestrictionPassedErr: Label 'Dimension restriction is passed.';
        WrongTaxRegIDTotalingErr: Label 'Wrong Tax Register ID totalling.';
        WrongDimValueCodeErr: Label 'Wrong dimensions value code.';
        WhereUsedFailedErr: Label 'Where-used function failed.';
        ChangeCannotBeCompletedTxt: Label 'Change cannot be completed';
        DeletionCannotBeCompletedTxt: Label 'Deletion cannot be completed';
        WrongFilterValueErr: Label 'Wrong filter on field %1 of table %2.';

    [Test]
    [Scope('OnPrem')]
    procedure SetDimFilters2TaxGLLine()
    var
        DimValue: Record "Dimension Value";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegGLEntry: Record "Tax Register G/L Entry";
    begin
        Initialize();
        InitTaxRegTemplateWithFilter(DimValue, TaxRegTemplate);
        TaxDimMgt.SetDimFilters2TaxGLLine(TaxRegTemplate, TaxRegGLEntry);
        Assert.AreEqual(
          DimValue.Code,
          TaxRegGLEntry.GetFilter("Dimension 1 Value Code"),
          StrSubstNo(WrongFilterValueErr, TaxRegGLEntry.FieldCaption("Dimension 1 Value Code"), TaxRegGLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimFilters2TaxItemLine()
    var
        DimValue: Record "Dimension Value";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegItemEntry: Record "Tax Register Item Entry";
    begin
        Initialize();
        InitTaxRegTemplateWithFilter(DimValue, TaxRegTemplate);
        TaxDimMgt.SetDimFilters2TaxItemLine(TaxRegTemplate, TaxRegItemEntry);
        Assert.AreEqual(
          DimValue.Code,
          TaxRegItemEntry.GetFilter("Dimension 1 Value Code"),
          StrSubstNo(WrongFilterValueErr, TaxRegItemEntry.FieldCaption("Dimension 1 Value Code"), TaxRegItemEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimFilters2TaxGLRecordRef()
    var
        DimValue: Record "Dimension Value";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        TaxRegRecordRef: RecordRef;
        TaxRegFieldRef: FieldRef;
    begin
        Initialize();
        InitTaxRegTemplateWithFilter(DimValue, TaxRegTemplate);
        TaxRegRecordRef.Open(DATABASE::"Tax Register G/L Entry");
        TaxDimMgt.SetDimFilters2TaxGLRecordRef(TaxRegTemplate, TaxRegRecordRef);
        TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegGLEntry.FieldNo("Dimension 1 Value Code"));
        Assert.AreEqual(
          DimValue.Code,
          TaxRegFieldRef.GetFilter,
          StrSubstNo(WrongFilterValueErr, TaxRegFieldRef.Caption, TaxRegRecordRef.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimFilters2TaxItemRecordRef()
    var
        DimValue: Record "Dimension Value";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegRecordRef: RecordRef;
        TaxRegFieldRef: FieldRef;
    begin
        Initialize();
        InitTaxRegTemplateWithFilter(DimValue, TaxRegTemplate);
        TaxRegRecordRef.Open(DATABASE::"Tax Register Item Entry");
        TaxDimMgt.SetDimFilters2TaxItemRecordRef(TaxRegTemplate, TaxRegRecordRef);
        TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegItemEntry.FieldNo("Dimension 1 Value Code"));
        Assert.AreEqual(
          DimValue.Code,
          TaxRegFieldRef.GetFilter,
          StrSubstNo(WrongFilterValueErr, TaxRegFieldRef.Caption, TaxRegRecordRef.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTemplateDimFiltersWithoutSet()
    var
        DimValue: Record "Dimension Value";
        TaxRegTemplate: Record "Tax Register Template";
    begin
        Initialize();
        InitTaxRegTemplateWithFilter(DimValue, TaxRegTemplate);
        Assert.IsFalse(
          TaxDimMgt.ValidateTemplateDimFilters(TaxRegTemplate), DimFiltersAreValidatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTemplateDimFiltersWithSet()
    var
        DimValue: Record "Dimension Value";
        TaxRegTemplate: Record "Tax Register Template";
    begin
        Initialize();
        InitTaxRegTemplateWithFilter(DimValue, TaxRegTemplate);
        TaxDimMgt.SetTaxEntryDim(TaxRegTemplate."Section Code", DimValue.Code, '', '', '');
        Assert.IsTrue(
          TaxDimMgt.ValidateTemplateDimFilters(TaxRegTemplate), DimFiltersAreNotValidatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimRestrictions_BlockedDim()
    begin
        CheckDimRestrictions(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimRestrictions_BlockedDimWithEmptyValue()
    begin
        CheckDimRestrictions(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhereUsedByDimensions()
    var
        DimValue: array[2] of Record "Dimension Value";
        TaxRegister: Record "Tax Register";
        TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter";
        TaxRegGLCorrEntry: Record "Tax Register G/L Corr. Entry";
        TaxRegIDTotaling: Code[250];
        DimValueCode: array[4] of Code[20];
    begin
        Initialize();
        CreateDimValue(DimValue[1]);
        LibraryTaxAcc.CreateTaxReg(
          TaxRegister, CreateTaxRegSection(DimValue),
          DATABASE::"Tax Register G/L Entry", 0);
        CreateTaxRegGLCorrEntry(TaxRegGLCorrEntry, TaxRegister."Section Code");
        CreateTaxRegDimCorrFilter(
          TaxRegDimCorrFilter, TaxRegister."Section Code", TaxRegDimCorrFilter."Connection Type"::Filters);
        CreateTaxRegDimFilter(
          TaxRegister."Section Code", TaxRegister."No.", 0, DimValue[1]);
        TaxDimMgt.SetTaxEntryDim(TaxRegister."Section Code", DimValue[1].Code, '', '', '');
        Assert.IsTrue(
          TaxDimMgt.WhereUsedByDimensions(
            TaxRegGLCorrEntry, TaxRegIDTotaling, DimValueCode[1], DimValueCode[2], DimValueCode[3], DimValueCode[4]), WhereUsedFailedErr);
        Assert.AreEqual('~' + TaxRegister."Register ID" + '~', TaxRegIDTotaling, WrongTaxRegIDTotalingErr);
        Assert.AreEqual(DimValue[1].Code, DimValueCode[1], WrongDimValueCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimCombForChange()
    var
        DimValue: array[4] of Record "Dimension Value";
        DimComb: Record "Dimension Combination";
        TaxRegister: Record "Tax Register";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
        TaxRegDimValueComb: Record "Tax Register Dim. Value Comb.";
    begin
        Initialize();
        CreatePairedDimValue(DimValue);
        LibraryTaxAcc.CreateTaxReg(
          TaxRegister, CreateTaxRegSection(DimValue),
          DATABASE::"Tax Register G/L Entry", 0);
        CreateDimensionCombination(DimComb, DimValue);
        CreateTaxRegDimComb(
          TaxRegDimComb, TaxRegister, DimValue,
          TaxRegDimComb."Combination Restriction"::Limited, 0);
        CreateTaxRegDimValueComb(TaxRegDimValueComb, TaxRegDimComb, DimValue);
        CreateTaxRegDimDefValueFromComb(TaxRegDimValueComb);
        asserterror TaxDimMgt.CheckDimComb(DimComb, TaxRegister."Section Code");
        Assert.ExpectedError(ChangeCannotBeCompletedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimCodeForDeletion()
    var
        DimValue: Record "Dimension Value";
        TaxRegister: Record "Tax Register";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
    begin
        Initialize();
        CreateDimValue(DimValue);
        CreateTaxRegWithDimComb(
          TaxRegister, TaxRegDimComb, DimValue."Dimension Code");
        CheckDimCode(DimValue."Dimension Code", TaxRegister."Section Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimCodeDefForDeletion()
    var
        DimValue: Record "Dimension Value";
        TaxRegister: Record "Tax Register";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
    begin
        Initialize();
        CreateDimValue(DimValue);
        CreateTaxRegWithDimComb(
          TaxRegister, TaxRegDimComb, DimValue."Dimension Code");
        CreateTaxRegDimDefValueFromDim(TaxRegister, DimValue);
        CheckDimCode(DimValue."Dimension Code", TaxRegister."Section Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimValueForDeletion()
    var
        DimValue: array[2] of Record "Dimension Value";
        TaxRegister: Record "Tax Register";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
        TaxRegDimValueComb: Record "Tax Register Dim. Value Comb.";
    begin
        Initialize();
        CreateDimValue(DimValue[1]);
        CreateTaxRegWithDimComb(
          TaxRegister, TaxRegDimComb, DimValue[1]."Dimension Code");
        CreateTaxRegDimValueComb(TaxRegDimValueComb, TaxRegDimComb, DimValue);
        CheckDimValue(DimValue[1], TaxRegister."Section Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimValueDefForDeletion()
    var
        DimValue: array[2] of Record "Dimension Value";
        TaxRegister: Record "Tax Register";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
        TaxRegDimValueComb: Record "Tax Register Dim. Value Comb.";
    begin
        Initialize();
        CreateDimValue(DimValue[1]);
        CreateTaxRegWithDimComb(
          TaxRegister, TaxRegDimComb, DimValue[1]."Dimension Code");
        CreateTaxRegDimValueComb(TaxRegDimValueComb, TaxRegDimComb, DimValue);
        CreateTaxRegDimDefValueFromDim(TaxRegister, DimValue[1]);
        CheckDimValue(DimValue[1], TaxRegister."Section Code");
    end;

    local procedure Initialize()
    begin
        Clear(TaxDimMgt);
    end;

    local procedure CheckDimRestrictions(UseBothValues: Boolean)
    var
        DimValue: array[2] of Record "Dimension Value";
        DimValueForComb: array[2] of Record "Dimension Value";
        TaxRegister: Record "Tax Register";
        TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
        i: Integer;
        Index: Integer;
    begin
        Initialize();
        InitTaxRegisterWithDimCorrFilter(TaxRegister, DimValue, TaxRegDimCorrFilter);

        if UseBothValues then
            Index := ArrayLen(DimValue)
        else
            Index := 1;
        for i := 1 to Index do
            DimValueForComb[i] := DimValue[i];

        CreateTaxRegDimComb(
          TaxRegDimComb, TaxRegister, DimValueForComb,
          TaxRegDimComb."Combination Restriction"::Blocked, TaxRegDimCorrFilter."Connection Entry No.");
        TaxDimMgt.SetTaxEntryDim(TaxRegister."Section Code", DimValueForComb[1].Code, DimValueForComb[2].Code, '', '');
        TaxRegDimCorrFilter.SetRange("Section Code", TaxRegDimCorrFilter."Section Code");
        Assert.IsFalse(
          TaxDimMgt.CheckDimRestrictions(TaxRegDimCorrFilter), DimRestrictionPassedErr);
    end;

    local procedure InitTaxRegisterWithDimCorrFilter(var TaxRegister: Record "Tax Register"; var DimValue: array[2] of Record "Dimension Value"; var TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter")
    begin
        CreatePairedDimValue(DimValue);
        LibraryTaxAcc.CreateTaxReg(
          TaxRegister, CreateTaxRegSection(DimValue),
          DATABASE::"Tax Register G/L Entry", 0);
        CreateTaxRegDimCorrFilter(
          TaxRegDimCorrFilter, TaxRegister."Section Code", TaxRegDimCorrFilter."Connection Type"::Combinations);
    end;

    local procedure InitTaxRegTemplateWithFilter(var DimValue: Record "Dimension Value"; var TaxRegTemplate: Record "Tax Register Template")
    begin
        CreateDimValue(DimValue);
        CreateTaxRegTemplateWithDimension(TaxRegTemplate, DimValue."Dimension Code");
        CreateTaxRegDimFilter(
          TaxRegTemplate."Section Code", TaxRegTemplate.Code, TaxRegTemplate."Line No.", DimValue);
    end;

    local procedure CreateTaxRegSection(DimValue: array[2] of Record "Dimension Value"): Code[10]
    var
        TaxRegSection: Record "Tax Register Section";
    begin
        TaxRegSection.Init();
        TaxRegSection.Code := LibraryUtility.GenerateGUID();
        TaxRegSection."Dimension 1 Code" := DimValue[1]."Dimension Code";
        TaxRegSection."Dimension 2 Code" := DimValue[2]."Dimension Code";
        TaxRegSection.Insert();
        exit(TaxRegSection.Code);
    end;

    local procedure CreateTaxRegTemplateWithDimension(var TaxRegTemplate: Record "Tax Register Template"; DimensionCode: Code[20])
    var
        TaxRegister: Record "Tax Register";
        DimValue: array[2] of Record "Dimension Value";
    begin
        DimValue[1]."Dimension Code" := DimensionCode;
        LibraryTaxAcc.CreateTaxReg(
          TaxRegister, CreateTaxRegSection(DimValue), DATABASE::"Tax Register G/L Entry", 0);
        LibraryTaxAcc.CreateTaxRegTemplate(
          TaxRegTemplate, TaxRegister."Section Code", TaxRegister."No.");
    end;

    local procedure CreateTaxRegDimFilter(SectionCode: Code[10]; TaxRegisterNo: Code[10]; LineNo: Integer; DimValue: Record "Dimension Value")
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        TaxRegDimFilter.Init();
        TaxRegDimFilter."Section Code" := SectionCode;
        TaxRegDimFilter."Tax Register No." := TaxRegisterNo;
        TaxRegDimFilter.Define := TaxRegDimFilter.Define::Template;
        TaxRegDimFilter."Line No." := LineNo;
        TaxRegDimFilter."Dimension Code" := DimValue."Dimension Code";
        TaxRegDimFilter."Dimension Value Filter" := DimValue.Code;
        TaxRegDimFilter."Entry No." := 1;
        TaxRegDimFilter.Insert();
    end;

    local procedure CreateTaxRegGLCorrEntry(var TaxRegGLCorrEntry: Record "Tax Register G/L Corr. Entry"; SectionCode: Code[10])
    begin
        TaxRegGLCorrEntry."Section Code" := SectionCode;
        TaxRegGLCorrEntry."Debit Account No." := LibraryERM.CreateGLAccountNo();
        TaxRegGLCorrEntry."Credit Account No." := LibraryERM.CreateGLAccountNo();
        TaxRegGLCorrEntry."Register Type" := TaxRegGLCorrEntry."Register Type"::Payroll;
        TaxRegGLCorrEntry."Entry No." := 1;
    end;

    local procedure CreateTaxRegDimCorrFilter(var TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter"; SectionCode: Code[10]; ConnectionType: Option)
    begin
        TaxRegDimCorrFilter.Init();
        TaxRegDimCorrFilter."Section Code" := SectionCode;
        TaxRegDimCorrFilter."G/L Corr. Entry No." := 1;
        TaxRegDimCorrFilter."Connection Type" := ConnectionType;
        TaxRegDimCorrFilter."Connection Entry No." := 1;
        TaxRegDimCorrFilter.Insert();
    end;

    local procedure CreateTaxRegDimComb(var TaxRegDimComb: Record "Tax Register Dim. Comb."; TaxRegister: Record "Tax Register"; DimValue: array[2] of Record "Dimension Value"; CombinationRestiction: Option; ConnectionEntryNo: Integer)
    begin
        TaxRegDimComb.Init();
        TaxRegDimComb."Section Code" := TaxRegister."Section Code";
        TaxRegDimComb."Tax Register No." := TaxRegister."No.";
        TaxRegDimComb."Line No." := 10000;
        TaxRegDimComb."Dimension 1 Code" := DimValue[1]."Dimension Code";
        TaxRegDimComb."Dimension 2 Code" := DimValue[2]."Dimension Code";
        TaxRegDimComb."Combination Restriction" := CombinationRestiction;
        TaxRegDimComb."Entry No." := ConnectionEntryNo;
        TaxRegDimComb.Insert();
    end;

    local procedure CreateTaxRegDimValueComb(var TaxRegDimValueComb: Record "Tax Register Dim. Value Comb."; TaxRegDimComb: Record "Tax Register Dim. Comb."; DimValue: array[2] of Record "Dimension Value")
    begin
        TaxRegDimValueComb."Section Code" := TaxRegDimComb."Section Code";
        TaxRegDimValueComb."Tax Register No." := TaxRegDimComb."Tax Register No.";
        TaxRegDimValueComb."Line No." := TaxRegDimComb."Line No.";
        TaxRegDimValueComb."Dimension 1 Code" := TaxRegDimComb."Dimension 1 Code";
        TaxRegDimValueComb."Dimension 2 Code" := TaxRegDimComb."Dimension 2 Code";
        TaxRegDimValueComb."Dimension 1 Value Code" := DimValue[1].Code;
        TaxRegDimValueComb."Dimension 2 Value Code" := DimValue[2].Code;
        TaxRegDimValueComb."Type Limit" := TaxRegDimValueComb."Type Limit"::Blocked;
        TaxRegDimValueComb.Insert();
    end;

    local procedure CreateTaxRegDimDefValueFromComb(TaxRegDimValueComb: Record "Tax Register Dim. Value Comb.")
    var
        TaxRegDimDefValue: Record "Tax Register Dim. Def. Value";
    begin
        TaxRegDimDefValue."Section Code" := TaxRegDimValueComb."Section Code";
        TaxRegDimDefValue."Tax Register No." := TaxRegDimValueComb."Tax Register No.";
        TaxRegDimDefValue."Line No." := TaxRegDimValueComb."Line No.";
        TaxRegDimDefValue."Dimension 1 Code" := TaxRegDimValueComb."Dimension 1 Code";
        TaxRegDimDefValue."Dimension 1 Value Code" := TaxRegDimValueComb."Dimension 1 Value Code";
        TaxRegDimDefValue."Dimension 2 Code" := TaxRegDimValueComb."Dimension 2 Code";
        TaxRegDimDefValue."Dimension 2 Value Code" := TaxRegDimValueComb."Dimension 2 Value Code";
        TaxRegDimDefValue.Insert();
    end;

    local procedure CreateTaxRegDimDefValueFromDim(TaxRegister: Record "Tax Register"; DimValue: Record "Dimension Value")
    var
        TaxRegDimDefValue: Record "Tax Register Dim. Def. Value";
    begin
        TaxRegDimDefValue."Section Code" := TaxRegister."Section Code";
        TaxRegDimDefValue."Tax Register No." := TaxRegister."No.";
        TaxRegDimDefValue."Line No." := 0;
        TaxRegDimDefValue."Dimension Code" := DimValue."Dimension Code";
        TaxRegDimDefValue."Dimension Value" := DimValue.Code;
        TaxRegDimDefValue.Insert();
    end;

    local procedure CreateTaxRegWithDimComb(var TaxRegister: Record "Tax Register"; var TaxRegDimComb: Record "Tax Register Dim. Comb."; DimensionCode: Code[20])
    var
        DimValue: array[2] of Record "Dimension Value";
    begin
        DimValue[1]."Dimension Code" := DimensionCode;
        LibraryTaxAcc.CreateTaxReg(
          TaxRegister, CreateTaxRegSection(DimValue), DATABASE::"Tax Register G/L Entry", 0);
        CreateTaxRegDimComb(
          TaxRegDimComb, TaxRegister, DimValue,
          TaxRegDimComb."Combination Restriction"::Limited, 0);
    end;

    local procedure CreatePairedDimValue(var DimValueArray: array[2] of Record "Dimension Value")
    var
        DimValue: Record "Dimension Value";
        i: Integer;
    begin
        for i := 1 to ArrayLen(DimValueArray) do begin
            CreateDimValue(DimValue);
            DimValueArray[i] := DimValue;
        end;
    end;

    local procedure CreateDimValue(var DimValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
    end;

    local procedure CreateDimensionCombination(var DimComb: Record "Dimension Combination"; DimValue: array[2] of Record "Dimension Value")
    begin
        DimComb.Init();
        DimComb."Dimension 1 Code" := DimValue[1]."Dimension Code";
        DimComb."Dimension 2 Code" := DimValue[2]."Dimension Code";
        DimComb."Combination Restriction" := DimComb."Combination Restriction"::Blocked;
        DimComb.Insert();
    end;

    local procedure CheckDimCode(DimensionCode: Code[20]; SectionCode: Code[10])
    var
        Dimension: Record Dimension;
    begin
        Dimension.Get(DimensionCode);
        asserterror TaxDimMgt.CheckDimCode(Dimension, SectionCode);
        Assert.ExpectedError(DeletionCannotBeCompletedTxt);
    end;

    local procedure CheckDimValue(DimValue: Record "Dimension Value"; SectionCode: Code[10])
    begin
        asserterror TaxDimMgt.CheckDimValue(DimValue, SectionCode);
        Assert.ExpectedError(DeletionCannotBeCompletedTxt);
    end;
}

