codeunit 144523 "ERM Tax Register Term Mgt."
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        LibraryDimension: Codeunit "Library - Dimension";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        NoCheckErr: Label '%1 was not checked.';
        WrongFieldValueErr: Label 'Wrong value of field %1 in table %2.';
        WrongDimFilterErr: Label 'Wrong dimension filter on %1.';
        TermExpressionTxt: Label 'Term(%1) %2 DB-CR(%3)', Comment = '%1 = Term code;%2 = expression text';
        TermExpressionCaseTxt: Label 'elseIF TERM(%1) > 0 THEN ';
        WrongExpressionTextErr: Label 'Wrong expression text.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckTaxRegTerm()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegTerm: Record "Tax Register Term";
        TaxRegTermWithCheck: Record "Tax Register Term";
        TaxRegTermFormula: Record "Tax Register Term Formula";
    begin
        Initialize();
        LibraryTaxAcc.CreateTaxRegSection(TaxRegSection);
        // Create complete Tax Register Term with Formula and one incomplete without Formula buth with Check.
        LibraryTaxAcc.CreateTaxRegTerm(TaxRegTermWithCheck, TaxRegSection.Code, TaxRegTerm."Expression Type"::Compare);
        TaxRegTermWithCheck.Check := true;
        TaxRegTermWithCheck.Modify();

        LibraryTaxAcc.CreateTaxRegTerm(TaxRegTerm, TaxRegSection.Code, TaxRegTerm."Expression Type"::Compare);
        LibraryTaxAcc.CreateTaxRegTermFormula(
          TaxRegTermFormula, TaxRegTerm."Section Code",
          TaxRegTerm."Term Code", TaxRegTermFormula.Operation::Positive,
          TaxRegTermFormula."Account Type"::Term, '', TaxRegTermWithCheck."Term Code");

        TaxRegTermMgt.CheckTaxRegTerm(
          false, TaxRegTerm."Section Code", DATABASE::"Tax Register Term", DATABASE::"Tax Register Term Formula");

        // Verify that both terms have no check after running CheckTaxRegTerm.
        TaxRegTerm.SetRange("Section Code", TaxRegTerm."Section Code");
        TaxRegTerm.FindSet();
        repeat
            Assert.IsFalse(TaxRegTerm.Check, StrSubstNo(NoCheckErr, TaxRegTerm.TableCaption()));
        until TaxRegTerm.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckTaxRegLink()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegister: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
    begin
        Initialize();
        LibraryTaxAcc.CreateTaxRegSection(TaxRegSection);
        LibraryTaxAcc.CreateTaxReg(TaxRegister, TaxRegSection.Code, DATABASE::"Tax Register Accumulation", 0);
        LibraryTaxAcc.CreateTaxRegTemplate(TaxRegTemplate, TaxRegister."Section Code", TaxRegister."No.");
        TaxRegTemplate."Expression Type" := TaxRegTemplate."Expression Type"::Link;
        TaxRegTemplate."Link Tax Register No." := TaxRegister."No.";
        TaxRegTemplate.Modify();
        TaxRegTermMgt.CheckTaxRegLink(false, TaxRegSection.Code, DATABASE::"Tax Register Template");

        TaxRegister.Find();
        Assert.IsTrue(TaxRegister.Check, StrSubstNo(NoCheckErr, TaxRegister.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalculateTemplateEntry()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegister: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        EntryValueBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        RecRef: RecordRef;
        LinkRecRef: RecordRef;
        TaxRegNorm: Decimal;
    begin
        Initialize();
        TaxRegNorm :=
          CreateTaxRegWithNormExpressionTemplate(
            TaxRegSection, TaxRegister, TaxRegTemplate);

        TaxRegTemplate.SetFilter("Date Filter", '%1..%2', TaxRegSection."Starting Date", TaxRegSection."Ending Date");
        RecRef.GetTable(TaxRegTemplate);
        LinkRecRef.GetTable(TaxRegister);
        TaxRegTermMgt.CalculateTemplateEntry(RecRef, EntryNoAmountBuffer, LinkRecRef, EntryValueBuffer);
        Assert.AreEqual(
          TaxRegNorm, EntryNoAmountBuffer.Amount,
          StrSubstNo(WrongFieldValueErr, EntryNoAmountBuffer.FieldCaption(Amount), EntryNoAmountBuffer.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShowExpressionValue_Norm()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegister: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TempTaxRegCalcBuffer: Record "Tax Register Calc. Buffer" temporary;
        TaxRegNorm: Decimal;
    begin
        Initialize();
        TaxRegNorm :=
          CreateTaxRegWithNormExpressionTemplate(
            TaxRegSection, TaxRegister, TaxRegTemplate);
        ShowExpressionValue(TempTaxRegCalcBuffer, TaxRegTemplate, TaxRegSection, TaxRegister);
        Assert.AreEqual(
          TaxRegNorm, TempTaxRegCalcBuffer.Amount,
          StrSubstNo(WrongFieldValueErr, TempTaxRegCalcBuffer.FieldCaption(Amount), TempTaxRegCalcBuffer.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShowExpressionValue_TermWithNormFormula()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegister: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegTerm: Record "Tax Register Term";
        TaxRegTermFormula: Record "Tax Register Term Formula";
        TaxRegNormDetail: Record "Tax Register Norm Detail";
        TempTaxRegCalcBuffer: Record "Tax Register Calc. Buffer" temporary;
    begin
        Initialize();
        LibraryTaxAcc.CreateTaxRegSection(TaxRegSection);
        CreateTaxRegNormGroupWithDetail(TaxRegNormDetail, TaxRegSection."Starting Date");
        TaxRegSection."Norm Jurisdiction Code" := TaxRegNormDetail."Norm Jurisdiction Code";
        TaxRegSection.Modify();

        CreateTaxRegTermWithFormula(
          TaxRegister, TaxRegTerm, TaxRegTermFormula, TaxRegSection.Code, TaxRegTermFormula."Account Type"::Norm,
          TaxRegNormDetail."Norm Group Code", TaxRegTerm."Term Code");
        CreateTaxRegTemplateWithTermExpression(
          TaxRegTemplate, TaxRegister, TaxRegTerm."Term Code", TaxRegNormDetail."Norm Jurisdiction Code");
        CreateTaxRegDimFilter(TaxRegTemplate."Section Code", TaxRegTemplate.Code);

        ShowExpressionValue(TempTaxRegCalcBuffer, TaxRegTemplate, TaxRegSection, TaxRegister);
        Assert.AreEqual(
          TaxRegNormDetail.Norm, TempTaxRegCalcBuffer.Amount,
          StrSubstNo(WrongFieldValueErr, TempTaxRegCalcBuffer.FieldCaption(Amount), TempTaxRegCalcBuffer.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShowExpressionValue_TermWithNetChangeFormula()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegister: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegTerm: Record "Tax Register Term";
        TaxRegTermFormula: Record "Tax Register Term Formula";
        TempTaxRegCalcBuffer: Record "Tax Register Calc. Buffer" temporary;
        TotalAmount: Decimal;
    begin
        Initialize();
        LibraryTaxAcc.CreateTaxRegSection(TaxRegSection);

        CreateTaxRegTermWithFormula(
          TaxRegister, TaxRegTerm, TaxRegTermFormula, TaxRegSection.Code, TaxRegTermFormula."Account Type"::"Net Change",
          LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());
        CreateTaxRegTemplateWithTermExpression(
          TaxRegTemplate, TaxRegister, TaxRegTerm."Term Code", '');
        TotalAmount := CreateGLCorrEntries(TaxRegTermFormula, TaxRegSection."Starting Date");

        ShowExpressionValue(TempTaxRegCalcBuffer, TaxRegTemplate, TaxRegSection, TaxRegister);
        Assert.AreEqual(
          TotalAmount, TempTaxRegCalcBuffer.Amount,
          StrSubstNo(WrongFieldValueErr, TempTaxRegCalcBuffer.FieldCaption(Amount), TempTaxRegCalcBuffer.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShowExpressionValue_TermWithGLAccountFormula()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegister: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegTerm: Record "Tax Register Term";
        TaxRegTermFormula: Record "Tax Register Term Formula";
        TempTaxRegCalcBuffer: Record "Tax Register Calc. Buffer" temporary;
        TotalAmount: Decimal;
    begin
        Initialize();
        LibraryTaxAcc.CreateTaxRegSection(TaxRegSection);

        CreateTaxRegTermWithFormula(
          TaxRegister, TaxRegTerm, TaxRegTermFormula, TaxRegSection.Code, TaxRegTermFormula."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());
        CreateTaxRegTemplateWithTermExpression(
          TaxRegTemplate, TaxRegister, TaxRegTerm."Term Code", '');
        TotalAmount := CreateGLEntriesWithDebitAmount(TaxRegTermFormula."Account No.", TaxRegSection."Starting Date");

        ShowExpressionValue(TempTaxRegCalcBuffer, TaxRegTemplate, TaxRegSection, TaxRegister);
        Assert.AreEqual(
          TotalAmount, TempTaxRegCalcBuffer.Amount,
          StrSubstNo(WrongFieldValueErr, TempTaxRegCalcBuffer.FieldCaption(Amount), TempTaxRegCalcBuffer.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MakeTermExpressionText()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegTerm: Record "Tax Register Term";
        TaxRegTermFormula: Record "Tax Register Term Formula";
        TermCode: array[2] of Code[20];
        TermType: Option ,AccountNo,BalAccountNo;
        i: Integer;
    begin
        Initialize();
        LibraryTaxAcc.CreateTaxRegSection(TaxRegSection);
        for i := 1 to ArrayLen(TermCode) do begin
            LibraryTaxAcc.CreateTaxRegTerm(TaxRegTerm, TaxRegSection.Code, TaxRegTerm."Expression Type"::Compare);
            TermCode[i] := TaxRegTerm."Term Code";
        end;

        LibraryTaxAcc.CreateTaxRegTerm(TaxRegTerm, TaxRegSection.Code, TaxRegTerm."Expression Type"::Compare);
        LibraryTaxAcc.CreateTaxRegTermFormula(
          TaxRegTermFormula, TaxRegTerm."Section Code",
          TaxRegTerm."Term Code", TaxRegTermFormula.Operation::Positive,
          TaxRegTermFormula."Account Type"::Term, TermCode[TermType::AccountNo], TermCode[TermType::BalAccountNo]);
        TaxRegTermFormula."Amount Type" := TaxRegTermFormula."Amount Type"::"Net Change";
        TaxRegTermFormula.Modify();

        Assert.AreEqual(
          StrSubstNo(TermExpressionTxt, TermCode[TermType::AccountNo], TermExpressionCaseTxt, TermCode[TermType::BalAccountNo]),
          TaxRegTermMgt.MakeTermExpressionText(
            TaxRegTerm."Term Code", TaxRegTerm."Section Code", DATABASE::"Tax Register Term", DATABASE::"Tax Register Term Formula"),
          WrongExpressionTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDimFiltersForGLEntry()
    var
        GLSetup: Record "General Ledger Setup";
        TempDimBuf: Record "Dimension Buffer" temporary;
        GLEntry: Record "G/L Entry";
    begin
        Initialize();
        GLSetup.Get();
        BuildDimBufWithNewDimValueCode(TempDimBuf, GLSetup."Global Dimension 1 Code");
        BuildDimBufWithNewDimValueCode(TempDimBuf, GLSetup."Global Dimension 2 Code");
        TaxRegTermMgt.SetDimFilters2GLEntry(GLEntry, TempDimBuf);
        VerifyDimValueInBuffer(
          TempDimBuf, GLSetup."Global Dimension 1 Code", GLEntry.GetFilter("Global Dimension 1 Code"));
        VerifyDimValueInBuffer(
          TempDimBuf, GLSetup."Global Dimension 2 Code", GLEntry.GetFilter("Global Dimension 2 Code"));
    end;

    local procedure Initialize()
    begin
        Clear(TaxRegTermMgt);
    end;

    local procedure CreateTaxRegTemplateWithNormExpression(var TaxRegTemplate: Record "Tax Register Template"; TaxRegister: Record "Tax Register"; TaxNormJurisdictionCode: Code[10]; TaxNormGroupCode: Code[10])
    begin
        LibraryTaxAcc.CreateTaxRegTemplate(TaxRegTemplate, TaxRegister."Section Code", TaxRegister."No.");
        TaxRegTemplate."Expression Type" := TaxRegTemplate."Expression Type"::Norm;
        TaxRegTemplate."Norm Jurisdiction Code" := TaxNormJurisdictionCode;
        TaxRegTemplate.Expression := TaxNormGroupCode;
        TaxRegTemplate.Modify();
    end;

    local procedure CreateTaxRegTemplateWithTermExpression(var TaxRegTemplate: Record "Tax Register Template"; TaxRegister: Record "Tax Register"; TermCode: Code[20]; TaxNormJurisdictionCode: Code[10])
    begin
        LibraryTaxAcc.CreateTaxRegTemplate(TaxRegTemplate, TaxRegister."Section Code", TaxRegister."No.");
        TaxRegTemplate."Expression Type" := TaxRegTemplate."Expression Type"::Term;
        TaxRegTemplate."Norm Jurisdiction Code" := TaxNormJurisdictionCode;
        TaxRegTemplate.Expression := TermCode;
        TaxRegTemplate.Modify();
    end;

    local procedure CreateTaxRegNormGroupWithDetail(var TaxRegNormDetail: Record "Tax Register Norm Detail"; EffectiveDate: Date)
    var
        TaxRegNormJurisdiction: Record "Tax Register Norm Jurisdiction";
        TaxRegNormGroup: Record "Tax Register Norm Group";
    begin
        LibraryTaxAcc.CreateTaxRegNormJurisdiction(TaxRegNormJurisdiction);
        LibraryTaxAcc.CreateTaxRegNormGroup(TaxRegNormGroup, TaxRegNormJurisdiction.Code);
        LibraryTaxAcc.CreateTaxRegNormDetail(
          TaxRegNormDetail, TaxRegNormGroup."Norm Jurisdiction Code", TaxRegNormGroup.Code,
          TaxRegNormDetail."Norm Type"::Amount, EffectiveDate);
        TaxRegNormDetail.Validate(Norm, LibraryRandom.RandDec(100, 2));
        TaxRegNormDetail.Modify(true);
    end;

    local procedure CreateTaxRegTermWithFormula(var TaxRegister: Record "Tax Register"; var TaxRegTerm: Record "Tax Register Term"; var TaxRegTermFormula: Record "Tax Register Term Formula"; SectionCode: Code[10]; AccountType: Option; AccountNo: Code[20]; BalAccountNo: Code[20])
    begin
        LibraryTaxAcc.CreateTaxReg(TaxRegister, SectionCode, DATABASE::"Tax Register Accumulation", 0);
        LibraryTaxAcc.CreateTaxRegTerm(TaxRegTerm, TaxRegister."Section Code", TaxRegTerm."Expression Type"::"Plus/Minus");
        LibraryTaxAcc.CreateTaxRegTermFormula(
          TaxRegTermFormula, TaxRegTerm."Section Code",
          TaxRegTerm."Term Code", 0,
          AccountType, AccountNo, BalAccountNo);
    end;

    local procedure CreateTaxRegWithNormExpressionTemplate(var TaxRegSection: Record "Tax Register Section"; var TaxRegister: Record "Tax Register"; var TaxRegTemplate: Record "Tax Register Template"): Decimal
    var
        TaxRegNormDetail: Record "Tax Register Norm Detail";
    begin
        LibraryTaxAcc.CreateTaxRegSection(TaxRegSection);
        LibraryTaxAcc.CreateTaxReg(TaxRegister, TaxRegSection.Code, DATABASE::"Tax Register Accumulation", 0);
        CreateTaxRegNormGroupWithDetail(TaxRegNormDetail, TaxRegSection."Starting Date");
        CreateTaxRegTemplateWithNormExpression(
          TaxRegTemplate, TaxRegister, TaxRegNormDetail."Norm Jurisdiction Code", TaxRegNormDetail."Norm Group Code");
        exit(TaxRegNormDetail.Norm);
    end;

    local procedure CreateTaxRegDimFilter(SectionCode: Code[10]; TaxRegisterNo: Code[20])
    var
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
        LibraryTaxAcc.CreateTaxRegDimFilter(
          TaxRegDimFilter, SectionCode, TaxRegisterNo, TaxRegDimFilter.Define::Template,
          DimValue."Dimension Code", DimValue.Code);
    end;

    local procedure CreateGLCorrEntries(TaxRegTermFormula: Record "Tax Register Term Formula"; PostingDate: Date) TotalAmount: Decimal
    var
        GLCorrespondEntry: Record "G/L Correspondence Entry";
        RecRef: RecordRef;
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do begin
            GLCorrespondEntry.Init();
            RecRef.GetTable(GLCorrespondEntry);
            GLCorrespondEntry."Entry No." :=
              LibraryUtility.GetNewLineNo(RecRef, GLCorrespondEntry.FieldNo("Entry No."));
            GLCorrespondEntry."Posting Date" := PostingDate;
            GLCorrespondEntry."Debit Account No." := TaxRegTermFormula."Account No.";
            GLCorrespondEntry."Credit Account No." := TaxRegTermFormula."Bal. Account No.";
            GLCorrespondEntry.Amount :=
              LibraryRandom.RandDec(100, 2);
            GLCorrespondEntry.Insert();
            TotalAmount += GLCorrespondEntry.Amount;
        end;
        exit(TotalAmount);
    end;

    local procedure CreateGLEntriesWithDebitAmount(AccountNo: Code[20]; PostingDate: Date) TotalAmount: Decimal
    var
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do begin
            GLEntry.Init();
            RecRef.GetTable(GLEntry);
            GLEntry."Entry No." :=
              LibraryUtility.GetNewLineNo(RecRef, GLEntry.FieldNo("Entry No."));
            GLEntry."Posting Date" := PostingDate;
            GLEntry."G/L Account No." := AccountNo;
            GLEntry."Debit Amount" :=
              LibraryRandom.RandDec(100, 2);
            GLEntry.Insert();
            TotalAmount += GLEntry."Debit Amount";
        end;
        exit(TotalAmount);
    end;

    local procedure BuildDimBufWithNewDimValueCode(var TempDimBuf: Record "Dimension Buffer"; DimensionCode: Code[20])
    var
        DimValue: Record "Dimension Value";
    begin
        TempDimBuf.Init();
        TempDimBuf."Dimension Code" := DimensionCode;
        LibraryDimension.CreateDimensionValue(DimValue, DimensionCode);
        TempDimBuf."Dimension Value Code" := DimValue.Code;
        TempDimBuf.Insert();
    end;

    local procedure ShowExpressionValue(var TaxRegCalcBuffer: Record "Tax Register Calc. Buffer" temporary; TaxRegTemplate: Record "Tax Register Template"; TaxRegSection: Record "Tax Register Section"; TaxRegister: Record "Tax Register")
    var
        RecRef: RecordRef;
        LinkRecRef: RecordRef;
    begin
        TaxRegTemplate.SetFilter("Date Filter", '%1..%2', TaxRegSection."Starting Date", TaxRegSection."Ending Date");
        RecRef.GetTable(TaxRegTemplate);
        LinkRecRef.GetTable(TaxRegister);
        TaxRegTermMgt.ShowExpressionValue(RecRef, TaxRegCalcBuffer, LinkRecRef);
    end;

    local procedure VerifyDimValueInBuffer(var TempDimBuf: Record "Dimension Buffer" temporary; DimensionCode: Code[20]; DimFilterCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        TempDimBuf.Get(0, 0, DimensionCode);
        Assert.AreEqual(
          TempDimBuf."Dimension Value Code", DimFilterCode,
          StrSubstNo(WrongDimFilterErr, GLEntry.TableCaption()));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text)
    begin
    end;
}

