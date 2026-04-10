codeunit 144522 "ERM Tax Diff. Jnl. Mgt."
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        TaxDiffJnlMgt: Codeunit TaxDiffJnlManagement;
        LibraryRandom: Codeunit "Library - Random";
        ObjectNotCreatedErr: Label '%1 is not created.';
        WrongValueErr: Label 'Wrong value of %1.';
        RecordNotFoundErr: Label '%1 not found.';

    [Test]
    [Scope('OnPrem')]
    procedure CreateTemplateSelectionOnOpen()
    var
        TempTaxDiffJnlTemplate: Record "Tax Diff. Journal Template" temporary;
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        JnlSelected: Boolean;
        PageID: Integer;
    begin
        Initialize();
        PageID := PAGE::"Tax Difference Journal";
        RemoveTaxDiffJnlTemplates(TempTaxDiffJnlTemplate, PageID);
        TaxDiffJnlMgt.TemplateSelection(
          PageID, TaxDiffJnlTemplate.Type::General, TaxDiffJnlLine, JnlSelected);
        Assert.IsTrue(
          TaxDiffJnlTemplate.Get(Format(TaxDiffJnlTemplate.Type::General, MaxStrLen(TaxDiffJnlTemplate.Name))),
          StrSubstNo(ObjectNotCreatedErr, TaxDiffJnlTemplate.TableCaption()));
        RestoreTaxDiffJnlTemplates(TempTaxDiffJnlTemplate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenJnlWithBatchCreation()
    var
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        JnlBatchName: Code[10];
    begin
        Initialize();
        LibraryTaxAcc.CreateTaxDiffJnlTemplate(TaxDiffJnlTemplate);
        JnlBatchName := LibraryUtility.GenerateGUID();
        TaxDiffJnlLine.SetRange("Journal Template Name", TaxDiffJnlTemplate.Name);
        TaxDiffJnlMgt.OpenJnl(JnlBatchName, TaxDiffJnlLine);
        Assert.IsTrue(
          TaxDiffJnlBatch.Get(TaxDiffJnlTemplate.Name, JnlBatchName),
          StrSubstNo(ObjectNotCreatedErr, TaxDiffJnlBatch.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAccounts()
    var
        FutureExpense: Record "Fixed Asset";
        TaxDifference: Record "Tax Difference";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffName: Text[50];
        SourceName: Text[50];
    begin
        Initialize();
        CreateTaxDifference(TaxDifference);
        CreateFutureExpense(FutureExpense);
        TaxDiffJnlLine."Tax Diff. Code" := TaxDifference.Code;
        TaxDiffJnlLine."Source Type" := TaxDiffJnlLine."Source Type"::"Future Expense";
        TaxDiffJnlLine."Source No." := FutureExpense."No.";
        TaxDiffJnlMgt.GetAccounts(TaxDiffJnlLine, TaxDiffName, SourceName);
        Assert.AreEqual(
          TaxDifference.Description, TaxDiffName, StrSubstNo(WrongValueErr, TaxDifference.FieldCaption(Description)));
        Assert.AreEqual(
          FutureExpense.Description, SourceName, StrSubstNo(WrongValueErr, FutureExpense.FieldCaption(Description)));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JnlBatchPost()
    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        FANo: array[5] of Code[20];
        LineCount: Integer;
        i: Integer;
    begin
        Initialize();
        TaxDiffJnlBatch.FindFirst();
        LineCount := LibraryRandom.RandIntInRange(3, 5);
        for i := 1 to LineCount do begin
            InitTaxDiffJnlLineWithBatch(TaxDiffJnlLine, TaxDiffJnlBatch);
            FANo[i] := TaxDiffJnlLine."Source No.";
        end;
        Commit();
        TaxDiffJnlMgt.JnlBatchPost(TaxDiffJnlBatch);
        for i := 1 to LineCount do
            VerifyTaxDiffEntry(FANo[i]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JnlLinePost()
    var
        FixedAsset: Record "Fixed Asset";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryTaxAcc.CreateTaxDiffJnlLine(
          TaxDiffJnlLine, '', '');
        FillTaxDiffJnlLine(
          TaxDiffJnlLine, FixedAsset."No.");
        Commit();
        TaxDiffJnlMgt.JnlPost(TaxDiffJnlLine);
        VerifyTaxDiffEntry(FixedAsset."No.");
    end;

    local procedure Initialize()
    begin
        Clear(TaxDiffJnlMgt);
    end;

    local procedure CreateTaxDifference(var TaxDifference: Record "Tax Difference")
    begin
        LibraryTaxAcc.CreateTaxDifference(TaxDifference);
        TaxDifference.Description := TaxDifference.Code;
        TaxDifference.Modify(true);
    end;

    local procedure InitTaxDiffJnlLineWithBatch(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; TaxDiffJnlBatch: Record "Tax Diff. Journal Batch")
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        InitDiffJnlLine(TaxDiffJnlLine, TaxDiffJnlBatch, FixedAsset."No.");
    end;

    local procedure InitDiffJnlLine(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; TaxDiffJnlBatch: Record "Tax Diff. Journal Batch"; FANo: Code[20])
    begin
        LibraryTaxAcc.CreateTaxDiffJnlLine(
          TaxDiffJnlLine, TaxDiffJnlBatch."Journal Template Name", TaxDiffJnlBatch.Name);
        FillTaxDiffJnlLine(TaxDiffJnlLine, FANo);
    end;

    local procedure FillTaxDiffJnlLine(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; SourceNo: Code[20])
    begin
        LibraryTaxAcc.FillTaxDiffJnlLine(TaxDiffJnlLine, TaxDiffJnlLine."Source Type"::"Fixed Asset", SourceNo);
        TaxDiffJnlLine."Tax Diff. Type" := TaxDiffJnlLine."Tax Diff. Type"::Constant;
        TaxDiffJnlLine."Asset Tax Amount" := LibraryRandom.RandDec(100, 2);
        TaxDiffJnlLine.Modify(true);
    end;

    local procedure CreateFutureExpense(var FutureExpense: Record "Fixed Asset")
    begin
        LibraryTaxAcc.CreateFutureExpense(FutureExpense);
        FutureExpense.Description := FutureExpense."No.";
        FutureExpense.Modify(true);
    end;

    local procedure RemoveTaxDiffJnlTemplates(var TaxDiffJnlTemplateBuffer: Record "Tax Diff. Journal Template"; PageID: Integer)
    var
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
    begin
        TaxDiffJnlTemplate.SetRange(Type, TaxDiffJnlTemplate.Type::General);
        TaxDiffJnlTemplate.SetRange("Page ID", PageID);
        if TaxDiffJnlTemplate.FindSet() then
            repeat
                TaxDiffJnlTemplateBuffer := TaxDiffJnlTemplate;
                TaxDiffJnlTemplateBuffer.Insert();
                TaxDiffJnlTemplate.Delete();
            until TaxDiffJnlTemplate.Next() = 0;
    end;

    local procedure RestoreTaxDiffJnlTemplates(var TaxDiffJnlTemplateBuffer: Record "Tax Diff. Journal Template")
    var
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
    begin
        if TaxDiffJnlTemplateBuffer.FindSet() then
            repeat
                TaxDiffJnlTemplate := TaxDiffJnlTemplateBuffer;
                if not TaxDiffJnlTemplate.Find() then
                    TaxDiffJnlTemplate.Insert();
            until TaxDiffJnlTemplateBuffer.Next() = 0;
    end;

    local procedure VerifyTaxDiffEntry(FANo: Code[20])
    var
        TaxDiffEntry: Record "Tax Diff. Ledger Entry";
    begin
        TaxDiffEntry.SetRange("Source Type", TaxDiffEntry."Source Type"::"Fixed Asset");
        TaxDiffEntry.SetRange("Source No.", FANo);
        Assert.IsFalse(TaxDiffEntry.IsEmpty, StrSubstNo(RecordNotFoundErr, TaxDiffEntry.TableCaption));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

