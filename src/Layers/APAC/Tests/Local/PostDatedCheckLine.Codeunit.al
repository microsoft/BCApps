codeunit 145300 "Post Dated Check Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Dated Check]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        BalAccMustBeBankErr: Label 'Bal. Account Type must be equal to ''Bank Account''';
        CashReceiptJnlLineNotCreatedErr: Label 'Cash receipt journal line has not been created.';
        WrongBatchNameInDatedCheckLineErr: Label 'Batch name in the Post Dated Check Line must be populated with the default value from the Sales & Receivables Setup.';

    [Test]
    [Scope('OnPrem')]
    procedure CreateDatedChecskLine_SetDefaultBatch()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        SetupAndCreateDatedCheckLine(GenJnlBatch, PostDatedCheckLine);
        Assert.AreEqual(GenJnlBatch.Name, PostDatedCheckLine."Batch Name", WrongBatchNameInDatedCheckLineErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostDatedChecksLineWithDefaultBatch()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        PostDatedCheckLine: Record "Post Dated Check Line";
        PostDatedCheckMgt: Codeunit PostDatedCheckMgt;
    begin
        SetupAndCreateDatedCheckLine(GenJnlBatch, PostDatedCheckLine);

        PostDatedCheckLine.SetRange("Batch Name", GenJnlBatch.Name);
        PostDatedCheckMgt.Post(PostDatedCheckLine);

        VerifyCashReceiptJournalLineCreated(GenJnlBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateDatedChecksLine_GLAccountBatchValidationError()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        SetupAndCreateDatedCheckLine(GenJnlBatch, PostDatedCheckLine);

        CreateGenJnlBatchWithGLAcc(GenJnlBatch);

        asserterror PostDatedCheckLine.Validate("Batch Name", GenJnlBatch.Name);
        Assert.ExpectedError(BalAccMustBeBankErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateDatedChecksLine_ValidateBankAccountBatch()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        SetupAndCreateDatedCheckLine(GenJnlBatch, PostDatedCheckLine);

        CreateGenJnlBatchWithBankAcc(GenJnlBatch);
        PostDatedCheckLine.Validate("Batch Name", GenJnlBatch.Name);

        Assert.AreEqual(GenJnlBatch.Name, PostDatedCheckLine."Batch Name", WrongBatchNameInDatedCheckLineErr);
    end;

    local procedure SetupAndCreateDatedCheckLine(var GenJnlBatch: Record "Gen. Journal Batch"; var PostDatedCheckLine: Record "Post Dated Check Line")
    begin
        CreateGenJnlBatchWithBankAcc(GenJnlBatch);
        SetDefaultSalesCheckBatch(GenJnlBatch);
        CreatePostDatedCheckLine(PostDatedCheckLine);
    end;

    local procedure SelectGenJnlTemplate(PageID: Integer; PageTemplate: Option General,Sales,Purchases,"Cash Receipts",Payments,Assets,Intercompany,Jobs): Code[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.SetRange("Page ID", PageID);
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.SetRange(Type, PageTemplate);
        GenJnlTemplate.FindFirst();

        exit(GenJnlTemplate.Name);
    end;

    local procedure CreateGenJnlBatchWithBankAcc(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        BankAcc: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        CreateGenJnlBatchSetBalAcc(GenJnlBatch, GenJnlBatch."Bal. Account Type"::"Bank Account", BankAcc."No.");
    end;

    local procedure CreateGenJnlBatchWithGLAcc(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GLAcc: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        CreateGenJnlBatchSetBalAcc(GenJnlBatch, GenJnlBatch."Bal. Account Type"::"G/L Account", GLAcc."No.");
    end;

    local procedure CreateGenJnlBatchSetBalAcc(var GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountCode: Code[20])
    var
        PageTemplate: Option General,Sales,Purchases,"Cash Receipts",Payments,Assets,Intercompany,Jobs;
    begin
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, SelectGenJnlTemplate(PAGE::"Cash Receipt Journal", PageTemplate::"Cash Receipts"));

        GenJnlBatch.Validate("Bal. Account Type", AccountType);
        GenJnlBatch.Validate("Bal. Account No.", AccountCode);
        GenJnlBatch.Modify(true);
    end;

    local procedure SetDefaultSalesCheckBatch(GenJnlBatch: Record "Gen. Journal Batch")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Post Dated Check Template", GenJnlBatch."Journal Template Name");
        SalesSetup.Validate("Post Dated Check Batch", GenJnlBatch.Name);
        SalesSetup.Modify(true);
    end;

    local procedure CreatePostDatedCheckLine(var PostDatedCheckLine: Record "Post Dated Check Line")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);

        PostDatedCheckLine.Init();
        PostDatedCheckLine.Validate("Account Type", PostDatedCheckLine."Account Type"::Customer);
        PostDatedCheckLine.Validate("Account No.", Customer."No.");
        PostDatedCheckLine."Check Date" := WorkDate();
        PostDatedCheckLine.Insert(true);
    end;

    local procedure VerifyCashReceiptJournalLineCreated(GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        Assert.IsFalse(GenJnlLine.IsEmpty, CashReceiptJnlLineNotCreatedErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

