codeunit 144018 "Test Telebank Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalTemplateOnInsert()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // Setup
        SourceCodeSetup.Init();
        if not SourceCodeSetup.Get() then
            SourceCodeSetup.Insert();
        SourceCodeSetup."Payment Journal" := CopyStr(CreateGuid(), 1, MaxStrLen(SourceCodeSetup."Payment Journal"));
        SourceCodeSetup.Modify();

        PaymentJournalTemplate.Init();
        PaymentJournalTemplate.Name := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJournalTemplate.Name));
        // Exercise
        PaymentJournalTemplate.Insert(true);
        // Validate
        PaymentJournalTemplate.TestField("Source Code", SourceCodeSetup."Payment Journal");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalTemplateOnDelete()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);

        // Validate setup
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
        Assert.AreEqual(1, PaymJnlBatch.Count, '');

        // Exercise
        PaymentJournalTemplate.Delete(true);

        // Verify
        Assert.AreEqual(0, PaymentJnlLine.Count, '');
        Assert.AreEqual(0, PaymJnlBatch.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalTemplateSourceCode()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        SourceCode: Record "Source Code";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);
        LibraryERM.CreateSourceCode(SourceCode);
        // Exercise
        PaymentJournalTemplate.Validate("Source Code", SourceCode.Code);

        // Verify
        PaymentJnlLine.SetRange("Source Code", PaymentJournalTemplate."Source Code");
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalBatchOnInsert()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);

        // Exercise
        PaymJnlBatch.Init();
        PaymJnlBatch."Journal Template Name" := PaymentJournalTemplate.Name;
        PaymJnlBatch.SetRange("Journal Template Name", PaymJnlBatch."Journal Template Name");
        PaymJnlBatch.Name := CopyStr(CreateGuid(), 1, MaxStrLen(PaymJnlBatch.Name));
        PaymJnlBatch.Insert(true);

        // Verify
        Assert.AreEqual(PaymentJournalTemplate."Reason Code", PaymJnlBatch."Reason Code", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalBatchOnDelete()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);

        // Validate setup
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
        Assert.AreEqual(1, PaymJnlBatch.Count, '');

        // Exercise
        PaymJnlBatch.Delete(true);

        // Verify
        Assert.AreEqual(0, PaymentJnlLine.Count, '');
        Assert.AreEqual(0, PaymJnlBatch.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalBatchOnRename()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);

        // Validate setup
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
        Assert.AreEqual(1, PaymJnlBatch.Count, '');

        // Exercise
        PaymJnlBatch.Rename('', PaymJnlBatch.Name);

        // Verify
        Assert.AreEqual(0, PaymentJnlLine.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TablePaymentJournalLineDim()
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        DimValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // Setup
        CreatePaymentJournalTemplate(PaymentJournalTemplate);
        CreatePaymentJournalBatch(PaymentJournalTemplate, PaymJnlBatch);
        CreatePaymentJournalLine(PaymJnlBatch, PaymentJnlLine);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateBankAccount(BankAccount);
        DimValue.FindFirst();
        DefaultDimension.Init();
        DefaultDimension."Table ID" := DATABASE::Vendor;
        DefaultDimension."No." := Vendor."No.";
        DefaultDimension."Dimension Code" := DimValue."Dimension Code";
        DefaultDimension."Dimension Value Code" := DimValue.Code;
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Insert(true);

        // Validate setup
        Assert.AreEqual(1, PaymentJnlLine.Count, '');
        Assert.AreEqual(1, PaymJnlBatch.Count, '');

        // Exercise
        PaymentJnlLine."Account Type" := PaymentJnlLine."Account Type"::Vendor;
        PaymentJnlLine.Validate("Account No.", Vendor."No.");

        // intermediate result
        ValidateJournalLineDim(PaymentJnlLine, DefaultDimension);

        // Exercise, continued
        PaymentJnlLine.Validate("Bank Account", BankAccount."No.");

        // Verify
        ValidateJournalLineDim(PaymentJnlLine, DefaultDimension);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalTemplateOnInsert()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        // Setup
        SourceCodeSetup.Init();
        if not SourceCodeSetup.Get() then
            SourceCodeSetup.Insert();
        SourceCodeSetup."Domiciliation Journal" := CopyStr(CreateGuid(), 1, MaxStrLen(SourceCodeSetup."Domiciliation Journal"));
        SourceCodeSetup.Modify();

        DomiciliationJournalTemplate.Init();
        DomiciliationJournalTemplate.Name := CopyStr(CreateGuid(), 1, MaxStrLen(DomiciliationJournalTemplate.Name));
        // Exercise
        DomiciliationJournalTemplate.Insert(true);
        // Validate
        DomiciliationJournalTemplate.TestField("Source Code", SourceCodeSetup."Domiciliation Journal");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalTemplateOnDelete()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLine(DomiciliationJournalBatch, DomiciliationJournalLine);

        // Validate setup
        Assert.AreEqual(1, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(1, DomiciliationJournalBatch.Count, '');

        // Exercise
        DomiciliationJournalTemplate.Delete(true);

        // Verify
        Assert.AreEqual(0, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(0, DomiciliationJournalBatch.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalTemplateSourceCode()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        SourceCode: Record "Source Code";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLine(DomiciliationJournalBatch, DomiciliationJournalLine);
        LibraryERM.CreateSourceCode(SourceCode);
        // Exercise
        DomiciliationJournalTemplate.Validate("Source Code", SourceCode.Code);

        // Verify
        DomiciliationJournalLine.SetRange("Source Code", DomiciliationJournalTemplate."Source Code");
        Assert.AreEqual(1, DomiciliationJournalLine.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalBatchOnInsert()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);

        // Exercise
        DomiciliationJournalBatch.Init();
        DomiciliationJournalBatch."Journal Template Name" := DomiciliationJournalTemplate.Name;
        DomiciliationJournalBatch.SetRange("Journal Template Name", DomiciliationJournalBatch."Journal Template Name");
        DomiciliationJournalBatch.Name := CopyStr(CreateGuid(), 1, MaxStrLen(DomiciliationJournalBatch.Name));
        DomiciliationJournalBatch.Insert(true);

        // Verify
        Assert.AreEqual(DomiciliationJournalTemplate."Reason Code", DomiciliationJournalBatch."Reason Code", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalBatchOnDelete()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLine(DomiciliationJournalBatch, DomiciliationJournalLine);

        // Validate setup
        Assert.AreEqual(1, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(1, DomiciliationJournalBatch.Count, '');

        // Exercise
        DomiciliationJournalBatch.Delete(true);

        // Verify
        Assert.AreEqual(0, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(0, DomiciliationJournalBatch.Count, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableDomiciliationJournalBatchOnRename()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // Setup
        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLine(DomiciliationJournalBatch, DomiciliationJournalLine);

        // Validate setup
        Assert.AreEqual(1, DomiciliationJournalLine.Count, '');
        Assert.AreEqual(1, DomiciliationJournalBatch.Count, '');

        // Exercise
        DomiciliationJournalBatch.Rename('', DomiciliationJournalBatch.Name);

        // Verify
        Assert.AreEqual(0, DomiciliationJournalLine.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableCODAStatementLineApplicationStatus()
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        // Init
        CODAStatementLine.Init();
        CODAStatementLine."Account No." := 'X';
        CODAStatementLine."Application Status" := CODAStatementLine."Application Status"::"Partly applied";
        CODAStatementLine.Validate("Account No.", '');

        // Validation
        CODAStatementLine.TestField("Application Status", CODAStatementLine."Application Status"::" ");
    end;

    local procedure CreatePaymentJournalTemplate(var PaymentJournalTemplate: Record "Payment Journal Template")
    begin
        PaymentJournalTemplate.Init();
        PaymentJournalTemplate.Name := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJournalTemplate.Name));
        PaymentJournalTemplate.Insert();
    end;

    local procedure CreatePaymentJournalBatch(PaymentJournalTemplate: Record "Payment Journal Template"; var PaymJnlBatch: Record "Paym. Journal Batch")
    begin
        PaymJnlBatch.Init();
        PaymJnlBatch."Journal Template Name" := PaymentJournalTemplate.Name;
        PaymJnlBatch.SetRange("Journal Template Name", PaymJnlBatch."Journal Template Name");
        PaymJnlBatch.Name := CopyStr(CreateGuid(), 1, MaxStrLen(PaymJnlBatch.Name));
        PaymJnlBatch.Insert();
    end;

    local procedure CreatePaymentJournalLine(PaymJnlBatch: Record "Paym. Journal Batch"; var PaymentJnlLine: Record "Payment Journal Line")
    begin
        PaymentJnlLine."Journal Template Name" := PaymJnlBatch."Journal Template Name";
        PaymentJnlLine."Journal Batch Name" := PaymJnlBatch.Name;
        PaymentJnlLine.SetRange("Journal Template Name", PaymentJnlLine."Journal Template Name");
        PaymentJnlLine.SetRange("Journal Batch Name", PaymentJnlLine."Journal Batch Name");
        if PaymentJnlLine.FindLast() then;
        PaymentJnlLine."Line No." += 10000;
        PaymentJnlLine.Init();
        PaymentJnlLine.Insert();
    end;

    local procedure CreateDomiciliationJournalTemplate(var DomiciliationJournalTemplate: Record "Domiciliation Journal Template")
    begin
        DomiciliationJournalTemplate.Init();
        DomiciliationJournalTemplate.Name := CopyStr(CreateGuid(), 1, MaxStrLen(DomiciliationJournalTemplate.Name));
        DomiciliationJournalTemplate.Insert();
    end;

    local procedure CreateDomiciliationJournalBatch(DomiciliationJournalTemplate: Record "Domiciliation Journal Template"; var DomiciliationJournalBatch: Record "Domiciliation Journal Batch")
    begin
        DomiciliationJournalBatch.Init();
        DomiciliationJournalBatch."Journal Template Name" := DomiciliationJournalTemplate.Name;
        DomiciliationJournalBatch.SetRange("Journal Template Name", DomiciliationJournalBatch."Journal Template Name");
        DomiciliationJournalBatch.Name := CopyStr(CreateGuid(), 1, MaxStrLen(DomiciliationJournalBatch.Name));
        DomiciliationJournalBatch.Insert();
    end;

    local procedure CreateDomiciliationJournalLine(DomiciliationJournalBatch: Record "Domiciliation Journal Batch"; var DomiciliationJournalLine: Record "Domiciliation Journal Line")
    begin
        DomiciliationJournalLine."Journal Template Name" := DomiciliationJournalBatch."Journal Template Name";
        DomiciliationJournalLine."Journal Batch Name" := DomiciliationJournalBatch.Name;
        DomiciliationJournalLine.SetRange("Journal Template Name", DomiciliationJournalLine."Journal Template Name");
        DomiciliationJournalLine.SetRange("Journal Batch Name", DomiciliationJournalLine."Journal Batch Name");
        if DomiciliationJournalLine.FindLast() then;
        DomiciliationJournalLine."Line No." += 10000;
        DomiciliationJournalLine.Init();
        DomiciliationJournalLine.Insert();
    end;

    local procedure ValidateJournalLineDim(var PaymentJnlLine: Record "Payment Journal Line"; var DefaultDimension: Record "Default Dimension")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        PaymentJnlLine.TestField("Dimension Set ID");
        DimensionManagement.GetDimensionSet(TempDimSetEntry, PaymentJnlLine."Dimension Set ID");
        Assert.AreEqual(1, TempDimSetEntry.Count, '');
        TempDimSetEntry.FindFirst();
        Assert.AreEqual(DefaultDimension."Dimension Code", TempDimSetEntry."Dimension Code", '');
        Assert.AreEqual(DefaultDimension."Dimension Value Code", TempDimSetEntry."Dimension Value Code", '');
    end;
}

