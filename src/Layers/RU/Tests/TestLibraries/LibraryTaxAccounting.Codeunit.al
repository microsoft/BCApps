codeunit 143015 "Library - Tax Accounting"
{
    Permissions = tabledata "FA Ledger Entry" = imd;

    var
        FASetup: Record "FA Setup";
        TaxRegSetup: Record "Tax Register Setup";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure GenerateRandomCode(TableID: Integer; FieldID: Integer): Code[10]
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(FieldID, TableID),
            1, LibraryUtility.GetFieldLength(TableID, FieldID)));
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffJnlTemplate(var TaxDiffJnlTemplate: Record "Tax Diff. Journal Template")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        TaxDiffJnlTemplate.Init();
        TaxDiffJnlTemplate.Validate(Name, GenJnlTemplate.Name);
        TaxDiffJnlTemplate.Validate(Description, TaxDiffJnlTemplate.Name);
        TaxDiffJnlTemplate.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffJnlBatch(var TaxDiffJnlBatch: Record "Tax Diff. Journal Batch"; TaxDiffJnlTemplateName: Code[10])
    begin
        TaxDiffJnlBatch.Init();
        TaxDiffJnlBatch.Validate("Journal Template Name", TaxDiffJnlTemplateName);
        TaxDiffJnlBatch.Validate(Name, GenerateRandomCode(DATABASE::"Tax Diff. Journal Batch", TaxDiffJnlBatch.FieldNo(Name)));
        TaxDiffJnlBatch.Validate(Description, TaxDiffJnlBatch.Name);
        TaxDiffJnlBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        TaxDiffJnlBatch.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffJnlSetup(var TaxDiffJnlTemplateName: Code[10]; var TaxDiffJnlBatchName: Code[10])
    var
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
    begin
        CreateTaxDiffJnlTemplate(TaxDiffJnlTemplate);
        CreateTaxDiffJnlBatch(TaxDiffJnlBatch, TaxDiffJnlTemplate.Name);
        TaxDiffJnlTemplateName := TaxDiffJnlTemplate.Name;
        TaxDiffJnlBatchName := TaxDiffJnlBatch.Name;
    end;

    [Scope('OnPrem')]
    procedure CreateAccDeprBook(var DepreciationBook: Record "Depreciation Book")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Posting Book Type", DepreciationBook."Posting Book Type"::Accounting);
        DepreciationBook.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxAccDeprBook(var DepreciationBook: Record "Depreciation Book")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Posting Book Type", DepreciationBook."Posting Book Type"::"Tax Accounting");
        DepreciationBook.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDifference(var TaxDifference: Record "Tax Difference")
    begin
        TaxDifference.Init();
        TaxDifference.Validate(Code, GenerateRandomCode(DATABASE::"Tax Difference", TaxDifference.FieldNo(Code)));
        TaxDifference.Validate("Source Code Mandatory", true);
        TaxDifference.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffPostingGroup(var TaxDiffPostingGroup: Record "Tax Diff. Posting Group")
    begin
        TaxDiffPostingGroup.Init();
        TaxDiffPostingGroup.Validate(Code, GenerateRandomCode(DATABASE::"Tax Diff. Posting Group", TaxDiffPostingGroup.FieldNo(Code)));
        TaxDiffPostingGroup.Validate("CTA Tax Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("CTL Tax Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("DTA Tax Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("DTL Tax Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("CTA Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("CTL Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("DTA Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("DTL Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("DTA Disposal Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("DTL Disposal Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("DTA Transfer Bal. Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("DTL Transfer Bal. Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("CTA Transfer Tax Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Validate("CTL Transfer Tax Account", LibraryERM.CreateGLAccountNo());
        TaxDiffPostingGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateDeprBonusTaxDifference(var TaxDifference: Record "Tax Difference")
    begin
        CreateTaxDifference(TaxDifference);
        TaxDifference.Validate(Type, TaxDifference.Type::"Temporary");
        TaxDifference.Validate("Depreciation Bonus", true);
        TaxDifference.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PrepareTaxDiffDeprBonusSetup()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDifference: Record "Tax Difference";
    begin
        CreateAccDeprBook(DepreciationBook);
        FASetup.Get();
        FASetup.Validate("Fixed Asset Nos.", LibraryERM.CreateNoSeriesCode());
        FASetup.Validate("Release Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);

        CreateTaxAccDeprBook(DepreciationBook);
        CreateDeprBonusTaxDifference(TaxDifference);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Tax Depreciation Book", DepreciationBook.Code);
        TaxRegSetup.Validate("Calculate TD for each FA", true);
        TaxRegSetup.Validate("Depr. Bonus TD Code", TaxDifference.Code);
        TaxRegSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PrepareTaxDiffFASetup()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDifference: Record "Tax Difference";
    begin
        CreateAccDeprBook(DepreciationBook);
        DepreciationBook.Validate("Control FA Acquis. Cost", true);
        DepreciationBook.Modify(true);
        FASetup.Get();
        FASetup.Validate("Release Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);

        CreateTaxAccDeprBook(DepreciationBook);
        CreateTaxDifference(TaxDifference);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Use Group Depr. Method from", 0D);
        TaxRegSetup.Validate("Tax Depreciation Book", DepreciationBook.Code);
        TaxRegSetup.Validate("Calculate TD for each FA", true);
        TaxRegSetup.Validate("Default FA TD Code", TaxDifference.Code);
        TaxRegSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PrepareTaxDiffDisposalSetup()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDifference: Record "Tax Difference";
    begin
        CreateAccDeprBook(DepreciationBook);
        FASetup.Get();
        FASetup.Validate("Release Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);

        CreateTaxAccDeprBook(DepreciationBook);
        CreateTaxDifference(TaxDifference);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Use Group Depr. Method from", 0D);
        TaxRegSetup.Validate("Tax Depreciation Book", DepreciationBook.Code);
        TaxRegSetup.Validate("Calculate TD for each FA", true);
        TaxRegSetup.Validate("Disposal TD Code", TaxDifference.Code);
        TaxRegSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PrepareTaxDiffDeprFESetup()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDifference: Record "Tax Difference";
    begin
        CreateAccDeprBook(DepreciationBook);
        FASetup.Get();
        FASetup.Validate("Future Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);

        CreateTaxAccDeprBook(DepreciationBook);
        CreateTaxDifference(TaxDifference);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Future Exp. Depreciation Book", DepreciationBook.Code);
        TaxRegSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        TaxDifference: Record "Tax Difference";
        FADeprBook: Record "FA Depreciation Book";
    begin
        CreateTaxDifference(TaxDifference);
        TaxDifference.Validate(Type, TaxDifference.Type::"Temporary");
        TaxDifference.Modify(true);

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("Tax Difference Code", TaxDifference.Code);
        FixedAsset.Modify(true);

        FADeprBook.SetRange("FA No.", FixedAsset."No.");
        FADeprBook.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateFutureExpense(var FutureExpense: Record "Fixed Asset")
    var
        TaxDifference: Record "Tax Difference";
        FADeprBook: Record "FA Depreciation Book";
    begin
        CreateTaxDifference(TaxDifference);
        TaxDifference.Validate(Type, TaxDifference.Type::"Temporary");
        TaxDifference.Modify(true);

        LibraryFixedAsset.CreateFixedAsset(FutureExpense);
        FutureExpense.Validate("FA Type", FutureExpense."FA Type"::"Future Expense");
        FutureExpense.Validate("Tax Difference Code", TaxDifference.Code);
        FutureExpense.Modify(true);

        FADeprBook.SetRange("FA No.", FutureExpense."No.");
        FADeprBook.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcSection(var TaxCalcSection: Record "Tax Calc. Section"; StartingDate: Date; EndingDate: Date)
    begin
        TaxCalcSection.Init();
        TaxCalcSection.Validate(Code, GenerateRandomCode(DATABASE::"Tax Calc. Section", TaxCalcSection.FieldNo(Code)));
        TaxCalcSection.Validate(Description, TaxCalcSection.Code);
        TaxCalcSection.Validate(Status, TaxCalcSection.Status::Blocked);
        TaxCalcSection.Validate("Starting Date", StartingDate);
        TaxCalcSection.Validate("Ending Date", EndingDate);
        TaxCalcSection.Validate(Status, TaxCalcSection.Status::Open);
        TaxCalcSection.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcHeader(var TaxCalcHeader: Record "Tax Calc. Header"; TaxCalcSectionCode: Code[10]; TableID: Integer)
    begin
        TaxCalcHeader.Init();
        TaxCalcHeader.Validate("Section Code", TaxCalcSectionCode);
        TaxCalcHeader.Validate("No.", GenerateRandomCode(DATABASE::"Tax Calc. Header", TaxCalcHeader.FieldNo("No.")));
        TaxCalcHeader.Validate(Description, TaxCalcHeader."No.");
        TaxCalcHeader.Validate("Table ID", TableID);
        TaxCalcHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure GetLastTaxCalcLineNo(TaxCalcSectionCode: Code[10]; TaxCalcHeaderNo: Code[10]): Integer
    var
        TaxCalcLine: Record "Tax Calc. Line";
    begin
        TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcLine.SetRange(Code, TaxCalcHeaderNo);
        if TaxCalcLine.FindLast() then
            exit(TaxCalcLine."Line No.");
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcLine(var TaxCalcLine: Record "Tax Calc. Line"; ExpressionType: Option; TaxCalcSectionCode: Code[10]; TaxCalcHeaderNo: Code[10])
    begin
        TaxCalcLine.Init();
        TaxCalcLine.Validate("Section Code", TaxCalcSectionCode);
        TaxCalcLine.Validate(Code, TaxCalcHeaderNo);
        TaxCalcLine.Validate("Line No.", GetLastTaxCalcLineNo(TaxCalcSectionCode, TaxCalcHeaderNo) + 10000);
        TaxCalcLine.Validate("Line Code", GenerateRandomCode(DATABASE::"Tax Calc. Line", TaxCalcLine.FieldNo("Line Code")));
        TaxCalcLine.Validate("Expression Type", ExpressionType);
        TaxCalcLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure GetLastTaxCalcSelectionSetupLineNo(TaxCalcSectionCode: Code[10]; TaxCalcHeaderNo: Code[10]): Integer
    var
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
    begin
        TaxCalcSelectionSetup.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcSelectionSetup.SetRange("Register No.", TaxCalcHeaderNo);
        if TaxCalcSelectionSetup.FindLast() then
            exit(TaxCalcSelectionSetup."Line No.");
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcSelectionSetup(var TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup"; TaxCalcSectionCode: Code[10]; TaxCalcHeaderNo: Code[10])
    begin
        TaxCalcSelectionSetup.Init();
        TaxCalcSelectionSetup.Validate("Section Code", TaxCalcSectionCode);
        TaxCalcSelectionSetup.Validate("Register No.", TaxCalcHeaderNo);
        TaxCalcSelectionSetup.Validate("Line No.", GetLastTaxCalcSelectionSetupLineNo(TaxCalcSectionCode, TaxCalcHeaderNo) + 10000);
        TaxCalcSelectionSetup.Validate("Line Code", GenerateRandomCode(DATABASE::"Tax Calc. Selection Setup", TaxCalcSelectionSetup.FieldNo("Line Code")));
        TaxCalcSelectionSetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegSection(var TaxRegSection: Record "Tax Register Section")
    begin
        TaxRegSection.Init();
        TaxRegSection.Validate(Code, LibraryUtility.GenerateRandomCode(TaxRegSection.FieldNo(Code), DATABASE::"Tax Register Section"));
        TaxRegSection.Validate(Description, TaxRegSection.Code);
        TaxRegSection.Insert(true);
        TaxRegSection.Validate("Starting Date", CalcDate('<-CM>', WorkDate()));
        TaxRegSection.Validate("Ending Date", CalcDate('<CM>', WorkDate()));
        TaxRegSection.Validate(Status, TaxRegSection.Status::Open);
        TaxRegSection.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxReg(var TaxReg: Record "Tax Register"; TaxRegSectionCode: Code[10]; TableId: Integer; StoringMethod: Option)
    begin
        TaxReg.Init();
        TaxReg.Validate("Section Code", TaxRegSectionCode);
        TaxReg.Validate("No.", LibraryUtility.GenerateRandomCode(TaxReg.FieldNo("No."), DATABASE::"Tax Register"));
        TaxReg.Validate(Description, TaxReg."No.");
        TaxReg.Validate("Table ID", TableId);
        TaxReg.Validate("Storing Method", StoringMethod);
        TaxReg.Validate("Register ID", LibraryUtility.GenerateGUID());
        TaxReg.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegTemplate(var TaxRegTemplate: Record "Tax Register Template"; TaxRegSectionCode: Code[10]; TaxRegNo: Code[10])
    var
        RecRef: RecordRef;
    begin
        TaxRegTemplate.Init();
        TaxRegTemplate.Validate("Section Code", TaxRegSectionCode);
        TaxRegTemplate.Validate(Code, TaxRegNo);
        RecRef.GetTable(TaxRegTemplate);
        TaxRegTemplate.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, TaxRegTemplate.FieldNo("Line No.")));
        TaxRegTemplate.Validate(
          "Line Code",
          LibraryUtility.GenerateRandomCode(TaxRegTemplate.FieldNo("Line Code"), DATABASE::"Tax Register Template"));
        TaxRegTemplate.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegTerm(var TaxRegTerm: Record "Tax Register Term"; SectionCode: Code[10]; ExpressionType: Option)
    begin
        TaxRegTerm.Init();
        TaxRegTerm.Validate("Section Code", SectionCode);
        TaxRegTerm.Validate("Term Code",
          LibraryUtility.GenerateRandomCode(TaxRegTerm.FieldNo("Term Code"), DATABASE::"Tax Register Term"));
        TaxRegTerm.Validate("Expression Type", ExpressionType);
        TaxRegTerm.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegTermFormula(var TaxRegTermFormula: Record "Tax Register Term Formula"; SectionCode: Code[10]; TermCode: Code[20]; OperationType: Option; AccountType: Option; AccountNo: Code[20]; BalAccountNo: Code[20])
    var
        RecRef: RecordRef;
    begin
        TaxRegTermFormula.Init();
        TaxRegTermFormula.Validate("Section Code", SectionCode);
        TaxRegTermFormula.Validate("Term Code", TermCode);
        RecRef.GetTable(TaxRegTermFormula);
        TaxRegTermFormula.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, TaxRegTermFormula.FieldNo("Line No.")));
        TaxRegTermFormula.Validate(Operation, OperationType);
        TaxRegTermFormula.Validate("Account Type", AccountType);
        TaxRegTermFormula.Validate("Account No.", AccountNo);
        if BalAccountNo <> '' then
            TaxRegTermFormula.Validate("Bal. Account No.", BalAccountNo);
        TaxRegTermFormula.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DeprBookCode: Code[10]; PostingDate: Date)
    var
        RecRef: RecordRef;
    begin
        FALedgerEntry.Init();
        RecRef.GetTable(FALedgerEntry);
        FALedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, FALedgerEntry.FieldNo("Entry No."));
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."Depreciation Book Code" := DeprBookCode;
        FALedgerEntry."Posting Date" := PostingDate;
        FALedgerEntry."FA Posting Date" := PostingDate;
        FALedgerEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateFAWithTaxFADeprBook(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        TaxRegSetup: Record "Tax Register Setup";
    begin
        TaxRegSetup.Get();

        CreateSimpleFA(FixedAsset);
        FADeprBook.Init();
        FADeprBook."FA No." := FixedAsset."No.";
        FADeprBook."Depreciation Book Code" := TaxRegSetup."Tax Depreciation Book";
        FADeprBook.Insert();
        exit(FixedAsset."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateFEWithTaxFADeprBook(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        TaxRegSetup: Record "Tax Register Setup";
    begin
        TaxRegSetup.Get();

        CreateSimpleFA(FixedAsset);
        FADeprBook.Init();
        FADeprBook."FA No." := FixedAsset."No.";
        FADeprBook."Depreciation Book Code" := TaxRegSetup."Future Exp. Depreciation Book";
        FADeprBook.Insert();
        exit(FixedAsset."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateSimpleFA(var FixedAsset: Record "Fixed Asset")
    begin
        FixedAsset.Init();
        FixedAsset."No." := LibraryUtility.GenerateRandomCode(FixedAsset.FieldNo("No."), DATABASE::"Fixed Asset");
        FixedAsset.Insert();
    end;

    [Scope('OnPrem')]
    procedure FindCalendarPeriod(var CalendarPeriod: Record Date; StartDate: Date)
    begin
        CalendarPeriod.Reset();
        CalendarPeriod.SetRange("Period Type", CalendarPeriod."Period Type"::Month);
        CalendarPeriod.SetFilter("Period Start", '..%1', StartDate);
        CalendarPeriod.SetFilter("Period End", '%1..', StartDate);
        CalendarPeriod.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure CreateEntryNoAmountBuffer(var EntryNoAmountBuffer: Record "Entry No. Amount Buffer"; LineNo: Integer)
    begin
        EntryNoAmountBuffer."Entry No." := LineNo;
        EntryNoAmountBuffer.Amount := LibraryRandom.RandDec(100, 2);
        EntryNoAmountBuffer.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffJnlLine(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; JnlTemplateName: Code[10]; JnlBatchName: Code[10])
    var
        RecordRef: RecordRef;
    begin
        TaxDiffJnlLine.Init();
        TaxDiffJnlLine."Journal Template Name" := JnlTemplateName;
        TaxDiffJnlLine."Journal Batch Name" := JnlBatchName;
        RecordRef.GetTable(TaxDiffJnlLine);
        TaxDiffJnlLine."Line No." :=
          LibraryUtility.GetNewLineNo(RecordRef, TaxDiffJnlLine.FieldNo("Line No."));
        TaxDiffJnlLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure FillTaxDiffJnlLine(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; SourceType: Option; SourceNo: Code[10])
    var
        TaxDifference: Record "Tax Difference";
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
    begin
        TaxDiffJnlLine.Init();
        TaxDiffJnlLine."Posting Date" := WorkDate();
        TaxDiffJnlLine."Document No." := LibraryUtility.GenerateGUID();
        CreateTaxDifference(TaxDifference);
        TaxDiffJnlLine."Tax Diff. Code" := TaxDifference.Code;
        CreateTaxDiffPostingGroup(TaxDiffPostingGroup);
        TaxDiffJnlLine."Tax Diff. Posting Group" := TaxDiffPostingGroup.Code;
        TaxDiffJnlLine."Tax Factor" := LibraryRandom.RandDec(50, 2);
        TaxDiffJnlLine."Source Type" := SourceType;
        TaxDiffJnlLine."Source No." := SourceNo;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegDimFilter(var TaxRegDimFilter: Record "Tax Register Dim. Filter"; SectionCode: Code[10]; TaxRegisterNo: Code[20]; DefineType: Option; DimensionCode: Code[20]; DimValueCode: Code[20])
    var
        RecRef: RecordRef;
    begin
        TaxRegDimFilter.Init();
        TaxRegDimFilter."Section Code" := SectionCode;
        TaxRegDimFilter."Tax Register No." := TaxRegisterNo;
        TaxRegDimFilter.Define := DefineType;
        RecRef.GetTable(TaxRegDimFilter);
        TaxRegDimFilter."Line No." :=
          LibraryUtility.GetNewLineNo(RecRef, TaxRegDimFilter.FieldNo("Line No."));
        TaxRegDimFilter."Dimension Code" := DimensionCode;
        TaxRegDimFilter."Dimension Value Filter" := DimValueCode;
        TaxRegDimFilter.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcDimFilter(SectionCode: Code[10]; TaxRegisterNo: Code[10]; LineNo: Integer; DimValue: Record "Dimension Value")
    var
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        TaxCalcDimFilter.Init();
        TaxCalcDimFilter."Section Code" := SectionCode;
        TaxCalcDimFilter."Register No." := TaxRegisterNo;
        TaxCalcDimFilter.Define := TaxCalcDimFilter.Define::Template;
        TaxCalcDimFilter."Line No." := LineNo;
        TaxCalcDimFilter."Dimension Code" := DimValue."Dimension Code";
        TaxCalcDimFilter."Dimension Value Filter" := DimValue.Code;
        TaxCalcDimFilter."Entry No." := 1;
        TaxCalcDimFilter.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcCorrespEntry(var TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry"; SectionCode: Code[10])
    begin
        TaxCalcCorrespEntry."Section Code" := SectionCode;
        TaxCalcCorrespEntry."Debit Account No." := LibraryERM.CreateGLAccountNo();
        TaxCalcCorrespEntry."Credit Account No." := LibraryERM.CreateGLAccountNo();
        TaxCalcCorrespEntry."Register Type" := TaxCalcCorrespEntry."Register Type"::Item;
        TaxCalcCorrespEntry."Entry No." := 1;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcDimCorrFilter(var TaxCalcDimCorrFilter: Record "Tax Calc. Dim. Corr. Filter"; SectionCode: Code[10])
    begin
        TaxCalcDimCorrFilter.Init();
        TaxCalcDimCorrFilter."Section Code" := SectionCode;
        TaxCalcDimCorrFilter."Corresp. Entry No." := 1;
        TaxCalcDimCorrFilter."Connection Entry No." := 1;
        TaxCalcDimCorrFilter.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegNormJurisdiction(var TaxRegNormJurisdiction: Record "Tax Register Norm Jurisdiction")
    begin
        TaxRegNormJurisdiction.Init();
        TaxRegNormJurisdiction.Validate(Code,
          GenerateRandomCode(DATABASE::"Tax Register Norm Jurisdiction", TaxRegNormJurisdiction.FieldNo(Code)));
        TaxRegNormJurisdiction.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegNormGroup(var TaxRegNormGroup: Record "Tax Register Norm Group"; TaxNormJurisdictionCode: Code[10])
    begin
        TaxRegNormGroup.Init();
        TaxRegNormGroup.Validate("Norm Jurisdiction Code", TaxNormJurisdictionCode);
        TaxRegNormGroup.Validate(Code,
          GenerateRandomCode(DATABASE::"Tax Register Norm Group", TaxRegNormGroup.FieldNo(Code)));
        TaxRegNormGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegNormDetail(var TaxRegNormDetail: Record "Tax Register Norm Detail"; TaxNormJurisdictionCode: Code[10]; TaxNormGroupCode: Code[10]; NormType: Option; EffectiveDate: Date)
    begin
        TaxRegNormDetail.Init();
        TaxRegNormDetail.Validate("Norm Jurisdiction Code", TaxNormJurisdictionCode);
        TaxRegNormDetail.Validate("Norm Group Code", TaxNormGroupCode);
        TaxRegNormDetail.Validate("Norm Type", NormType);
        TaxRegNormDetail.Validate("Effective Date", EffectiveDate);
        TaxRegNormDetail.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcAccumulation(var TaxCalcAccum: Record "Tax Calc. Accumulation"; SectionCode: Code[10]; StartingDate: Date)
    var
        RecRef: RecordRef;
    begin
        TaxCalcAccum.Init();
        RecRef.GetTable(TaxCalcAccum);
        TaxCalcAccum."Entry No." := LibraryUtility.GetNewLineNo(RecRef, TaxCalcAccum.FieldNo("Entry No."));
        TaxCalcAccum."Section Code" := SectionCode;
        TaxCalcAccum."Starting Date" := StartingDate;
        TaxCalcAccum.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateFAWithAccFADeprBook(): Code[20]
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();

        CreateSimpleFA(FixedAsset);
        FADeprBook.Init();
        FADeprBook."FA No." := FixedAsset."No.";
        FADeprBook."Depreciation Book Code" := FASetup."Release Depr. Book";
        FADeprBook.Insert();
        exit(FixedAsset."No.");
    end;
}

