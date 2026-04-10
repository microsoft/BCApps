codeunit 137043 "SCM General Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Standard General Journal] [General Journal]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ErrNoOfLinesMustBeEqual: Label 'No Of Lines Must Be Equal';
        MSGStdGeneralJrnlExists: Label 'Standard General Journal';

    [Test]
    [Scope('OnPrem')]
    procedure SaveStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournalCode: Code[10];
    begin
        // Setup : Create General Journal Template and General Journal Batch.
        // Exercise : Create Multiple General Lines and save Them as standard Journal.
        Initialize();
        CreateGenJournalTemplateBatch(GenJournalBatch);
        CreateGenJournalLines(GenJournalBatch, StandardGeneralJournalCode);

        // Verify : Verify Number Standard General Journal Created.
        VerifyStandardGeneralJournal(GenJournalBatch."Journal Template Name", 3);

        // Tear Down : Delete General Lines Created.
        DeleteGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler')]
    [Scope('OnPrem')]
    procedure GetStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournalCode: Code[10];
    begin
        // Setup : Create General Journal Template and General Journal Batch.
        // Create Multiple General Lines and save Them as standard Journal.
        Initialize();
        CreateGenJournalTemplateBatch(GenJournalBatch);
        CreateGenJournalLines(GenJournalBatch, StandardGeneralJournalCode);

        // Exercise : Get saved standard Journal in General Line.
        DeleteAndGetStandardJournal(GenJournalLine, GenJournalBatch, StandardGeneralJournalCode);

        // Verify : Verify Number Standard General Journal Created.
        // Verify : Verify General Journal Line Inserted through Get STandard Journal.
        VerifyStandardGeneralJournal(GenJournalBatch."Journal Template Name", 3);
        VerifyGenJournalLine(GenJournalBatch);

        // Tear Down : Delete General Lines Created.
        DeleteGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetAndSaveStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournalCode: Code[10];
    begin
        // Setup : Create General Journal Template and General Journal Batch.
        // Create Multiple General Lines and save Them as standard Journal.
        Initialize();
        CreateGenJournalTemplateBatch(GenJournalBatch);
        CreateGenJournalLines(GenJournalBatch, StandardGeneralJournalCode);
        DeleteAndGetStandardJournal(GenJournalLine, GenJournalBatch, StandardGeneralJournalCode);

        // Exercise : Save standard Journal.
        LibraryInventory.SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournalCode, true);

        // Verify : Verify Number Standard General Journal Created.
        // Verify : Verify General Journal Line Inserted through Get STandard Journal.
        VerifyStandardGeneralJournal(GenJournalBatch."Journal Template Name", 3);
        VerifyGenJournalLine(GenJournalBatch);

        // Tear Down : Delete General Lines Created.
        DeleteGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler')]
    [Scope('OnPrem')]
    procedure UpdateAndGetStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournalCode: Code[10];
        AccountNo: Code[20];
    begin
        // Setup : Create General Journal Template and General Journal Batch.
        // Create Multiple General Lines and save Them as standard Journal.
        Initialize();
        CreateGenJournalTemplateBatch(GenJournalBatch);
        CreateGenJournalLines(GenJournalBatch, StandardGeneralJournalCode);
        DeleteGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);

        // Exercise : Update standard General Journal Line adn Get it in Genereal Journal.
        AccountNo := UpdateStandardJournals(GenJournalBatch."Journal Template Name", StandardGeneralJournalCode);
        GetSavedStandardJournal(GenJournalBatch, StandardGeneralJournalCode);

        // Verify : Verify Updated GL Account  No in Gen Journal Line.
        VerifyGLAccountNo(GenJournalBatch, AccountNo);

        // Tear Down : Delete General Lines Created.
        DeleteGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler')]
    [Scope('OnPrem')]
    procedure SaveMultipleStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        StandardGeneralJournalCode: Code[10];
        StandardGeneralJournalCode2: Code[10];
        StandardGeneralJournalCode3: Code[10];
    begin
        // Setup : Create General Journal Template and General Journal Batch.
        // Create Two Standard General Journal.
        Initialize();
        CreateGenJournalTemplateBatch(GenJournalBatch);
        CreateGenJournalLines(GenJournalBatch, StandardGeneralJournalCode);
        CreateGenJournalLines(GenJournalBatch, StandardGeneralJournalCode2);

        // Create New standard Journal using Get saved standard Journal in General Line.
        DeleteAndGetStandardJournal(GenJournalLine, GenJournalBatch, StandardGeneralJournalCode);
        GetSavedStandardJournal(GenJournalBatch, StandardGeneralJournalCode2);

        // Exercise : Save Standard Journal.
        CreateStandardGenlJournalCode(StandardGeneralJournalCode3);
        LibraryInventory.SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournalCode3, true);

        // Verify : Verify Multiply Standard General Journal Created.
        StandardGeneralJournal.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        StandardGeneralJournal.SetFilter(
          Code, '%1|%2|%3', StandardGeneralJournalCode, StandardGeneralJournalCode2, StandardGeneralJournalCode3);
        StandardGeneralJournal.FindFirst();

        // Tear Down : Delete General Lines Created.
        DeleteGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReplaceExistingStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournalCode: Code[10];
    begin
        // Setup : Create General Journal Template and General Journal Batch.
        // Create Two Standard General Journal.
        Initialize();
        CreateGenJournalTemplateBatch(GenJournalBatch);
        CreateGenJournalLines(GenJournalBatch, StandardGeneralJournalCode);
        DeleteAndGetStandardJournal(GenJournalLine, GenJournalBatch, StandardGeneralJournalCode);

        // Exercise : Save existing Standard Journal.
        LibraryInventory.SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournalCode, true);

        // Verify : Verify Number Standard of General Journal Created.
        VerifyStandardGeneralJournal(GenJournalBatch."Journal Template Name", 3);

        // Tear Down : Delete General Lines Created.
        DeleteGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler')]
    [Scope('OnPrem')]
    procedure PostStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        StandardGeneralJournalCode: Code[10];
        Amount: Decimal;
    begin
        // Setup : Create General Journal Template and General Journal Batch.
        // Create Customer and Create General Journal Line.
        Initialize();
        CreateGenJournalTemplateBatch(GenJournalBatch);
        LibrarySales.CreateCustomer(Customer);
        GLAccount.FilterGroup(2);
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.FilterGroup(0);
        LibraryERM.FindGLAccount(GLAccount);
        Amount := LibraryRandom.RandDec(100, 2);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, GenJournalLine."Bal. Account Type"::"G/L Account",
          Customer."No.", GLAccount."No.", Amount);

        // Save as Standard Journal and delete General Journal Line,
        CreateStandardGenlJournalCode(StandardGeneralJournalCode);
        LibraryInventory.SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournalCode, true);

        // Exercise : Get saved standard Journal in General Line and Post it.
        DeleteAndGetStandardJournal(GenJournalLine, GenJournalBatch, StandardGeneralJournalCode);
        FindGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify : verify Customer Ledger Entry.
        VerifyCustLedgerEntry(Customer."No.", Amount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM General Journal");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM General Journal");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM General Journal");
    end;

    local procedure CreateGenJournalTemplateBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; BalAccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify();
    end;

    local procedure CreateStandardGenlJournalCode(var StandardGeneralJournalCode: Code[10])
    var
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        StandardGeneralJournalCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(StandardGeneralJournal.FieldNo(Code), DATABASE::"Standard General Journal"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Standard General Journal", StandardGeneralJournal.FieldNo(Code)));
    end;

    local procedure CreateGenJournalLines(var GenJournalBatch: Record "Gen. Journal Batch"; var StandardGeneralJournalCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Setup : Create General Journal Template and General Journal Batch.
        // Exercise : Create Multiple General Lines and save Them as standard Journal.
        LibraryERM.FindGLAccount(GLAccount);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Bal. Account Type"::"G/L Account",
          GLAccount."No.", '', LibraryRandom.RandDec(100, 2));

        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibrarySales.CreateCustomerNo(), '', LibraryRandom.RandDec(100, 2));

        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, GenJournalLine."Bal. Account Type"::"Bank Account",
          LibraryPurchase.CreateVendorNo(), '', LibraryRandom.RandDec(100, 2));
        CreateStandardGenlJournalCode(StandardGeneralJournalCode);
        LibraryInventory.SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournalCode, true);
    end;

    local procedure DeleteGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        FindGenJournalLine(GenJournalLine, JournalTemplateName, JournalBatchName);
        repeat
            GenJournalLine.Delete(true);
        until GenJournalLine.Next() = 0;
        Commit();
    end;

    [Normal]
    local procedure GetSavedStandardJournal(GenJournalBatch: Record "Gen. Journal Batch"; "Code": Code[10])
    var
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        StandardGeneralJournal.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        StandardGeneralJournal.SetRange(Code, Code);
        StandardGeneralJournal.FindFirst();
        if PAGE.RunModal(PAGE::"Standard General Journals", StandardGeneralJournal) = ACTION::LookupOK then
            StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);
    end;

    local procedure UpdateStandardJournals(JournalTemplateName: Code[10]; StandardGeneralJournalCode: Code[10]): Code[20]
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        StandardGeneralJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardGeneralJournalCode);
        StandardGeneralJournalLine.SetRange("Account Type", StandardGeneralJournalLine."Account Type"::"G/L Account");
        StandardGeneralJournalLine.FindFirst();
        StandardGeneralJournalLine.Validate("Account No.", GLAccount."No.");
        StandardGeneralJournalLine.Modify();
        Commit();
        exit(StandardGeneralJournalLine."Account No.");
    end;

    local procedure DeleteAndGetStandardJournal(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; StandardGeneralJournalCode: Code[10])
    begin
        DeleteGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        GetSavedStandardJournal(GenJournalBatch, StandardGeneralJournalCode);
    end;

    local procedure FindGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.FindSet();
    end;

    local procedure FindStandardGeneralJournalLine(var StandardGeneralJournalLine: Record "Standard General Journal Line"; JournalTemplateName: Code[10])
    begin
        StandardGeneralJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        StandardGeneralJournalLine.FindSet();
    end;

    local procedure VerifyStandardGeneralJournal(JournalTemplateName: Code[10]; NoOfLines: Integer)
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        FindStandardGeneralJournalLine(StandardGeneralJournalLine, JournalTemplateName);
        Assert.AreEqual(StandardGeneralJournalLine.Count, NoOfLines, ErrNoOfLinesMustBeEqual);
    end;

    local procedure VerifyGenJournalLine(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        FindStandardGeneralJournalLine(StandardGeneralJournalLine, GenJournalBatch."Journal Template Name");
        FindGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        Assert.AreEqual(GenJournalLine.Count, StandardGeneralJournalLine.Count, ErrNoOfLinesMustBeEqual);
    end;

    local procedure VerifyGLAccountNo(GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.FindFirst();
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", 'Account No must be the Same');
    end;

    local procedure VerifyCustLedgerEntry(CustomerNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ActualAmount: Decimal;
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields(Amount);
            ActualAmount += CustLedgerEntry.Amount;
        until CustLedgerEntry.Next() = 0;
        Assert.AreEqual(Amount, ActualAmount, 'Amount must be the Same');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandler(var StandardGeneralJournals: Page "Standard General Journals"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreNotEqual(StrPos(Question, MSGStdGeneralJrnlExists), 0, Question);
        Reply := true;
    end;
}

