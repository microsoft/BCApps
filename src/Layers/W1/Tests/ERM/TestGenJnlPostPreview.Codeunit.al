codeunit 134760 "Test Gen. Jnl. Post Preview"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview]
        IsInitialized := false;
    end;

    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        UnexpectedMessageErr: Label 'Unexpected message: %1.', Comment = '%1 = Error message';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        RecordRestrictedTxt: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Customer 10000 for this action.';
        ExpectedEmptyErrorFromPreviewErr: Label 'Expected empty error from Preview. Actual error: ';
        UnexpectedDeleteErr: Label 'Unexpected delete of "Gen. Journal Line" in preview mode.';
        InconsistenceTxt: Label 'The transaction will cause G/L entries to be inconsistent. Typical causes for this are mismatched amounts, including amounts in additional currencies, and posting dates.';
        IsInitialized: Boolean;
        MakeInconsistence: Boolean;

    [Test]
    [HandlerFunctions('NothingToPostMessageHandler')]
    [Scope('OnPrem')]
    procedure GenJnlPostPreviewErrorWhenNothingToPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
    begin
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account",
          GLAccount."No.",
          0);

        GenJournalLine.Delete();
        Commit();
        asserterror GenJnlPost.Preview(GenJournalLine);
        VerifyEmptyPreviewError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviewGL()
    var
        GLAccount: Record "G/L Account";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Amount: Decimal;
    begin
        // Initialize
        Initialize();
        Amount := LibraryRandom.RandDecInRange(10, 10000, 2);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account",
          GLAccount."No.",
          Amount);
        Commit();

        // Execute
        GLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);
        VerifyEmptyPreviewError();
        VerifyGLEntries(Amount, GLPostingPreview);
        GLPostingPreview.Close();

        // Verify

        // Cleanup
        if GenJournalLine.Find() then
            GenJournalLine.Delete();
        GLAccount.Delete();
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestPreviewICGL()
    var
        ICGLAccount: Record "IC G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        ICPartner: Record "IC Partner";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Amount: Decimal;
    begin
        // Initialize
        Initialize();
        Amount := LibraryRandom.RandDecInRange(10, 10000, 2);
        LibraryERM.CreateICGLAccount(ICGLAccount);
        LibraryERM.CreateGLAccount(GLAccount);

        ICPartner.Init();
        ICPartner.Validate(
          Code,
          ICGLAccount."No.");
        ICPartner."Receivables Account" := GLAccount."No.";
        ICPartner.Insert(true);

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
        GenJournalTemplate.Type := GenJournalTemplate.Type::Intercompany;
        GenJournalTemplate.Modify();

        GenJournalBatch."Template Type" := GenJournalTemplate.Type::Intercompany;
        GenJournalBatch.Modify();

        Commit();

        LibraryJournals.CreateGenJournalLine2(GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"IC Partner",
          ICGLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account",
          GLAccount."No.", Amount);

        GenJournalLine."IC Account Type" := "IC Journal Account Type"::"G/L Account";
        GenJournalLine."IC Account No." := ICGLAccount."No.";
        GenJournalLine.Description := 'TEST';
        GenJournalLine.Modify();

        // Execute
        Commit();
        GLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);
        VerifyEmptyPreviewError();
        // Verify
        VerifyGLEntries(Amount, GLPostingPreview);
        GLPostingPreview.Close();

        // Cleanup
        if GenJournalTemplate.Get(GenJournalBatch."Journal Template Name") then
            GenJournalTemplate.Delete();

        GenJournalBatch.Delete();

        if GenJournalLine.Find() then
            GenJournalLine.Delete();
        ICGLAccount.Delete();
        GLAccount.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviewCustomer()
    var
        Customer: Record Customer;
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Amount: Decimal;
    begin
        // Initialize
        Initialize();
        Amount := LibraryRandom.RandDecInRange(10, 10000, 2);
        LibrarySales.CreateCustomer(Customer);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer,
          Customer."No.",
          Amount);
        Commit();

        // Execute
        GLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);
        VerifyEmptyPreviewError();
        // Verify
        VerifyCustomerEntries(Amount, GLPostingPreview);
        GLPostingPreview.Close();

        // Cleanup
        GenJournalLine.Delete();
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviewForeignCustomer()
    var
        Customer: Record Customer;
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Initialize
        Initialize();
        Amount1 := LibraryRandom.RandDecInRange(10, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(10, 10000, 2);
        LibrarySales.CreateCustomer(Customer);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer,
          Customer."No.",
          Amount1);
        LibraryJournals.CreateGenJournalLine2(
          GenJournalLine,
          GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer,
          Customer."No.",
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Bal. Account No.",
          Amount2);
        Commit();

        // Execute
        GLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);
        VerifyEmptyPreviewError();
        // Verify
        VerifyForeignCustomerEntries(Amount1, Amount2, GLPostingPreview);
        GLPostingPreview.Close();

        // Cleanup
        GenJournalLine.Delete();
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviewVendor()
    var
        Vendor: Record Vendor;
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Initialize
        Initialize();
        Amount1 := LibraryRandom.RandDecInRange(10, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(10, 10000, 2);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor,
          Vendor."No.",
          Amount1);
        LibraryJournals.CreateGenJournalLine2(
          GenJournalLine,
          GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor,
          Vendor."No.",
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Bal. Account No.",
          Amount2);

        Commit();

        // Execute
        GLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);
        VerifyEmptyPreviewError();
        // Verify
        VerifyVendorEntries(Amount1, Amount2, GLPostingPreview);
        GLPostingPreview.Close();

        // Cleanup
        GenJournalLine.Delete();
        Vendor.Delete();
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviewEmployee()
    var
        Employee: Record Employee;
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Initialize
        Initialize();
        Amount1 := LibraryRandom.RandDecInRange(10, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(10, 10000, 2);
        CreateEmployee(Employee);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Employee,
          Employee."No.",
          Amount1);
        LibraryJournals.CreateGenJournalLine2(
          GenJournalLine,
          GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Employee,
          Employee."No.",
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Bal. Account No.",
          Amount2);

        Commit();

        // Execute
        GLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);
        VerifyEmptyPreviewError();
        // Verify
        VerifyEmployeeEntries(Amount1, Amount2, GLPostingPreview);
        GLPostingPreview.Close();

        // Cleanup
        GenJournalLine.Delete();
        Employee.Delete();
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviewBankAcc()
    var
        BankAccount: Record "Bank Account";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Amount: Decimal;
    begin
        // Initialize
        Initialize();
        Amount := LibraryRandom.RandDecInRange(10, 10000, 2);
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Bank Account",
          BankAccount."No.",
          Amount);
        Commit();

        // Execute
        GLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);
        VerifyEmptyPreviewError();
        // Verification done in BankAccountEntriesPreviewHandler
        VerifyBankAccountEntries(Amount, GLPostingPreview);
        GLPostingPreview.Close();

        // Cleanup
        GenJournalLine.Delete();
        BankAccount.Delete();
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviewFixedAssetJnl()
    var
        Customer: Record Customer;
        GenJournalTemplate: Record "Gen. Journal Template";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJournalLinePayment(
          GenJournalLine,
          GenJournalTemplate.Type::Assets,
          GenJournalLine."Account Type"::Customer,
          Customer."No.");

        GenJournalLine.Validate(Amount, -539);
        GenJournalLine.Modify(true);
        Commit();

        GLPostingPreview.Trap();
        FixedAssetGLJournal.Trap();
        PAGE.Run(PAGE::"Fixed Asset G/L Journal");
        FixedAssetGLJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        Commit();
        FixedAssetGLJournal.Preview.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPreviewGLBatchWorksWithApprovals()
    var
        GLAccount: Record "G/L Account";
        RestrictedRecord: Record "Restricted Record";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Amount: Decimal;
        ExpectedErrorMessage: Text;
        ActualErrorMessage: Text;
    begin
        // [SCENARIO] Preview action on General Journal should work even if batch is under Approval Workflow.
        // Initialize
        Initialize();
        Amount := LibraryRandom.RandDecInRange(10, 10000, 2);

        // [GIVEN] General Journal that is under an approval workflow.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account",
          GLAccount."No.",
          Amount);
        Commit();

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, '');
        Commit();
        RestrictedRecord.SetRange("Record ID", GenJournalLine.RecordId);
        Assert.IsTrue(RestrictedRecord.FindFirst(), 'Missing RestrictedRecord');

        // [WHEN] Preview is executed.
        GLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);
        // [THEN] GETLASTERRORTEXT should be null
        Assert.AreEqual('', GetLastErrorText, 'Expected empty error from Preview. Actual error: ' + GetLastErrorText);
        GLPostingPreview.Close();

        ClearLastError();
        Clear(GenJnlPost);

        ExpectedErrorMessage := StrSubstNo(RecordRestrictedTxt,
            Format(Format(RestrictedRecord."Record ID", 0, 1)));

        // [WHEN] Post is executed.
        asserterror GenJnlPost.Run(GenJournalLine);
        // [THEN] GETLASTERRORTEXT should be non-null
        ActualErrorMessage := CopyStr(GetLastErrorText, 1, StrLen(ExpectedErrorMessage));
        Assert.AreEqual(ExpectedErrorMessage, ActualErrorMessage, 'Unexpected error message.');

        // Cleanup
        if GenJournalLine.Find() then
            GenJournalLine.Delete();
        GLAccount.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFixedGenJnlLineAfterFailOnPreview()
    var
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
    begin
        // [SCENARIO 377725] General Journal Line which was fixed after fail on preview should be posted
        Initialize();

        // [GIVEN] General Journal Line with "Amount" = 0
        Clear(GenJournalLine);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(),
          0);
        Commit();

        // [GIVEN] Preview failed on "There is nothing to post error"
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [GIVEN] Updated General Journal Line with "Amount" = "X"
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Modify(true);

        // [WHEN] Post General Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entry created with G/L Register and Amount = "X"
        VerifyGLEntryWithRegister(GenJournalLine."Account No.", GenJournalLine.Amount);

        // [THEN] General journal line was removed after posting
        GenJournalLine.SetRecFilter();
        GenJournalLine.SetRange("Account No.", GenJournalLine."Account No.");
        Assert.RecordIsEmpty(GenJournalLine);

        // Tear down
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewPageHandler')]
    [Scope('OnPrem')]
    procedure PreviewOnFixedGenJnlLineAfterFailedPreview()
    var
        GLEntry: Record "G/L Entry";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        LastGLEntryNo: Integer;
    begin
        // [SCENARIO 377725] No G/L entries should be created when calling preview on fixed general journal line after fail on preview
        Initialize();

        // [GIVEN] General Journal Line with "Amount" = 0
        Clear(GenJournalLine);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(),
          0);
        Commit();
        GLEntry.FindLast();
        LastGLEntryNo := GLEntry."Entry No.";

        // [GIVEN] Preview failed on "There is nothing to post error"
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [GIVEN] Updated General Journal Line with "Amount" = "X"
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Modify(true);

        // [WHEN] Preview posting of General Journal Line
        Commit();
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [THEN] Preview successfully ran. No G/L Enries were created
        VerifyEmptyPreviewError();
        GLEntry.FindLast();
        GLEntry.TestField("Entry No.", LastGLEntryNo);
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewPageHandler')]
    [Scope('OnPrem')]
    procedure NoGLEntriesCreatedWhenPreviewTwice()
    var
        GLEntry: Record "G/L Entry";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        LastGLEntryNo: Integer;
    begin
        // [SCENARIO 377725] No G/L entries should be created when calling preview twice
        Initialize();

        // [GIVEN] Successfull posting preview of General Journal Line
        Clear(GenJournalLine);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandInt(100));
        Commit();
        GLEntry.FindLast();
        LastGLEntryNo := GLEntry."Entry No.";
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [WHEN] Preview posting of General Journal Line
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [THEN] Preview successfully ran. No G/L Enries were created
        VerifyEmptyPreviewError();
        GLEntry.FindLast();
        GLEntry.TestField("Entry No.", LastGLEntryNo);
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewPageHandler')]
    [Scope('OnPrem')]
    procedure PmtJournalPostingPreviewClearsPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestGenJnlPostPreview: Codeunit "Test Gen. Jnl. Post Preview";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 169196] Posting preview does not remove Payment Lines from Payment Journal and does not change them.
        Initialize();
        BindSubscription(TestGenJnlPostPreview);

        // [GIVEN] Payment Line in Payment Journal.
        DeletePaymentJournalTemplates();

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDecInRange(10, 10000, 2));

        SetPaymentTypeJournalTemplate(GenJournalLine);

        Commit();

        // [WHEN] Run Posting Preview from a Page.
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.Value := GenJournalLine."Journal Batch Name";
        PaymentJournal.GotoRecord(GenJournalLine);
        PaymentJournal.Preview.Invoke();

        // [THEN] Payment Journal has not been changed,
        // [THEN] EventSubscriber OnDeletePmtJournalLine is not called.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedPostingPreviewPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        ExtendedGLPostingPreview: TestPage "Extended G/L Posting Preview";
    begin
        // [SCENARIO 354973] Posting preview opens "Extended G/L Posting Preview" page when GLSetup."Posting Preview Type" = Extended
        Initialize();

        // [GIVEN] Set GLSetup."Posting Preview Type" = Extended
        UpdateGLSetupPostingPreviewType("Posting Preview Type"::Extended);

        // [GIVEN] Create gen. journal line
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(), LibraryRandom.RandInt(100));

        // [WHEN] Run posting preview 
        Commit();
        ExtendedGLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [THEN] "Extended G/L Posting Preview" page opened
        VerifyGLEntriesExtendedFlat(GenJournalLine, ExtendedGLPostingPreview);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedPostingPreviewPageHierarchicalView()
    var
        GLAccount: Record "G/L Account";
        BalGLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        ExtendedGLPostingPreview: TestPage "Extended G/L Posting Preview";
        TotalAmount: Decimal;
    begin
        // [SCENARIO 354973] Extended posting preview shows grouped G/L entries 
        Initialize();

        // [GIVEN] Set GLSetup."Posting Preview Type" = Extended
        UpdateGLSetupPostingPreviewType("Posting Preview Type"::Extended);
        // [GIVEN] G/L Accounts "A" and "B"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(BalGLAccount);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create gen. journal line Account No. = "A", Bal. Account No. = "B", Amount = 100
        // [GIVEN] Create gen. journal line Account No. = "A", Bal. Account No. = "B", Amount = 200
        // [GIVEN] Create gen. journal line Account No. = "A", Bal. Account No. = "B", Amount = 300
        CreateGeneralJnlLinesWithBalAcc(GenJournalBatch, GenJournalLine, GLAccount."No.", BalGLAccount."No.", TotalAmount);

        // [GIVEN] Run posting preview 
        Commit();
        ExtendedGLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [WHEN] Set Show Hierarchical Veiw = true on "Extended G/L Posting Preview" page
        ExtendedGLPostingPreview.ShowHierarchicalViewControl.SetValue(true);

        // [THEN] Extended G/L Posting Preview page shows grouped G/L Entries: Account No. = "A", Amount = 600, Account No. = "B", Amount = -600
        VerifyGLEntriesExtendedGrouped(ExtendedGLPostingPreview, GLAccount."No.", BalGLAccount."No.", TotalAmount);
    end;

    [Test]
    [HandlerFunctions('InconsistenceSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure PostingPreviewInconsistent()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        TestGenJnlPostPreview: Codeunit "Test Gen. Jnl. Post Preview";
        ExtendedGLPostingPreview: TestPage "Extended G/L Posting Preview";
    begin
        // [SCENARIO 354973] Posting preview of inconsistent transaction shows notification
        Initialize();

        // [GIVEN] Subscribe on OnPostGLAccOnBeforeInsertGLEntry to cause inconsintence
        BindSubscription(TestGenJnlPostPreview);
        TestGenJnlPostPreview.SetMakeInconsistence();

        // [GIVEN] Set GLSetup."Posting Preview Type" = Extended
        UpdateGLSetupPostingPreviewType("Posting Preview Type"::Extended);

        // [GIVEN] Create gen. journal line
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(), LibraryRandom.RandInt(100));

        // [WHEN] Run posting preview
        Commit();
        ExtendedGLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [THEN] Preview page shows inconsistence notification "The transaction will cause inconsistencies in the G/L Entry table."
        Assert.AreEqual(InconsistenceTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification');
    end;

    local procedure Initialize()
    var
        ICSetup: Record "IC Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Gen. Jnl. Post Preview");
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Gen. Jnl. Post Preview");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Gen. Jnl. Post Preview");
    end;

    procedure SetMakeInconsistence()
    begin
        MakeInconsistence := true;
    end;

    local procedure CreateGeneralJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; GenJournalTemplateType: Enum "Gen. Journal Template Type")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplateType);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGeneralJournalLinePayment(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplateType: Enum "Gen. Journal Template Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplateType);
        if not GenJournalTemplate.FindFirst() then
            CreateGeneralJournalTemplate(GenJournalTemplate, GenJournalTemplateType);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, AccountType, AccountNo, 0);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Modify(true);

        Commit();
    end;

    local procedure CreateGeneralJnlLinesWithBalAcc(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; BalGLAccountNo: Code[20]; var TotalAmount: Decimal)
    var
        i: Integer;
    begin
        for i := 1 to 3 do begin
            LibraryERM.CreateGeneralJnlLineWithBalAcc(
                GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
                "Gen. Journal Account Type"::"G/L Account", GLAccountNo, "Gen. Journal Account Type"::"G/L Account", BalGLAccountNo, LibraryRandom.RandInt(100));
            TotalAmount := TotalAmount + GenJournalLine.Amount;
        end;
    end;

    local procedure DeletePaymentJournalTemplates()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Reset();
        GenJournalTemplate.SetRange("Page ID", PAGE::"Payment Journal");
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.DeleteAll();
    end;

    local procedure SetPaymentTypeJournalTemplate(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
        GenJournalTemplate."Page ID" := PAGE::"Payment Journal";
        GenJournalTemplate.Type := GenJournalTemplate.Type::Payments;
        GenJournalTemplate.Modify();
    end;

    local procedure UpdateGLSetupPostingPreviewType(PostingPreviewType: Enum "Posting Preview Type")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Posting Preview Type", PostingPreviewType);
        GLSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyGLEntries(Amount: Decimal; GLPostingPreview: TestPage "G/L Posting Preview")
    var
        GLEntriesPreview: TestPage "G/L Entries Preview";
    begin
        GLEntriesPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"G/L Entry"));
        GLPostingPreview.Show.Invoke();

        // Verify
        GLEntriesPreview.First();
        GLEntriesPreview.Amount.AssertEquals(Amount);
        GLEntriesPreview.Next();
        GLEntriesPreview.Amount.AssertEquals(-Amount);
        GLEntriesPreview.OK().Invoke();
    end;

    local procedure VerifyGLEntriesExtendedFlat(GenJournalLine: Record "Gen. Journal Line"; var ExtendedGLPostingPreview: TestPage "Extended G/L Posting Preview")
    begin
        ExtendedGLPostingPreview.ShowHierarchicalViewControl.SetValue(false);
        ExtendedGLPostingPreview.GLEntriesPreviewFlat.First();
        ExtendedGLPostingPreview.GLEntriesPreviewFlat."G/L Account No.".AssertEquals(GenJournalLine."Account No.");
        ExtendedGLPostingPreview.GLEntriesPreviewFlat.Amount.AssertEquals(GenJournalLine.Amount);
        ExtendedGLPostingPreview.GLEntriesPreviewFlat.Next();
        ExtendedGLPostingPreview.GLEntriesPreviewFlat."G/L Account No.".AssertEquals(GenJournalLine."Bal. Account No.");
        ExtendedGLPostingPreview.GLEntriesPreviewFlat.Amount.AssertEquals(-GenJournalLine.Amount);
    end;

    local procedure VerifyGLEntriesExtendedGrouped(var ExtendedGLPostingPreview: TestPage "Extended G/L Posting Preview"; GLAccountNo: Code[20]; BalGLAccountNo: Code[20]; var TotalAmount: Decimal)
    begin
        ExtendedGLPostingPreview.GLEntriesPreviewHierarchical.Filter.SetFilter("G/L Account No.", GLAccountNo);
        ExtendedGLPostingPreview.GLEntriesPreviewHierarchical.First();
        ExtendedGLPostingPreview.GLEntriesPreviewHierarchical.Amount.AssertEquals(TotalAmount);
        ExtendedGLPostingPreview.GLEntriesPreviewHierarchical.Filter.SetFilter("G/L Account No.", BalGLAccountNo);
        ExtendedGLPostingPreview.GLEntriesPreviewHierarchical.First();
        ExtendedGLPostingPreview.GLEntriesPreviewHierarchical.Amount.AssertEquals(-TotalAmount);
    end;

    [Scope('OnPrem')]
    procedure VerifyCustomerEntries(Amount: Decimal; GLPostingPreview: TestPage "G/L Posting Preview")
    var
        CustLedgEntriesPreview: TestPage "Cust. Ledg. Entries Preview";
    begin
        CustLedgEntriesPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Cust. Ledger Entry"));
        GLPostingPreview.Show.Invoke();

        // Verify
        CustLedgEntriesPreview.AmountFCY.AssertEquals(Amount);
        CustLedgEntriesPreview.OriginalAmountFCY.AssertEquals(Amount);
        CustLedgEntriesPreview.RemainingAmountFCY.AssertEquals(Amount);
        CustLedgEntriesPreview.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure VerifyForeignCustomerEntries(Amount1: Decimal; Amount2: Decimal; GLPostingPreview: TestPage "G/L Posting Preview")
    var
        CustLedgEntriesPreview: TestPage "Cust. Ledg. Entries Preview";
    begin
        CustLedgEntriesPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Cust. Ledger Entry"));
        GLPostingPreview.Show.Invoke();

        CustLedgEntriesPreview.First();
        CustLedgEntriesPreview.AmountFCY.AssertEquals(Amount1);
        CustLedgEntriesPreview.OriginalAmountFCY.AssertEquals(Amount1);
        CustLedgEntriesPreview.RemainingAmountFCY.AssertEquals(Amount1);

        CustLedgEntriesPreview.Next();
        CustLedgEntriesPreview.AmountFCY.AssertEquals(Amount2);
        CustLedgEntriesPreview.OriginalAmountFCY.AssertEquals(Amount2);
        CustLedgEntriesPreview.RemainingAmountFCY.AssertEquals(Amount2);

        CustLedgEntriesPreview.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure VerifyVendorEntries(Amount1: Decimal; Amount2: Decimal; GLPostingPreview: TestPage "G/L Posting Preview")
    var
        VendLedgEntriesPreview: TestPage "Vend. Ledg. Entries Preview";
    begin
        VendLedgEntriesPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Vendor Ledger Entry"));
        GLPostingPreview.Show.Invoke();

        VendLedgEntriesPreview.First();
        VendLedgEntriesPreview.AmountFCY.AssertEquals(Amount1);
        VendLedgEntriesPreview.OriginalAmountFCY.AssertEquals(Amount1);
        VendLedgEntriesPreview.RemainingAmountFCY.AssertEquals(Amount1);

        VendLedgEntriesPreview.Next();
        VendLedgEntriesPreview.AmountFCY.AssertEquals(Amount2);
        VendLedgEntriesPreview.OriginalAmountFCY.AssertEquals(Amount2);
        VendLedgEntriesPreview.RemainingAmountFCY.AssertEquals(Amount2);

        VendLedgEntriesPreview.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure VerifyEmployeeEntries(Amount1: Decimal; Amount2: Decimal; GLPostingPreview: TestPage "G/L Posting Preview")
    var
        EmplLedgerEntriesPreview: TestPage "Empl. Ledger Entries Preview";
    begin
        EmplLedgerEntriesPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Employee Ledger Entry"));
        GLPostingPreview.Show.Invoke();

        EmplLedgerEntriesPreview.First();
        EmplLedgerEntriesPreview.AmountFCY.AssertEquals(Amount1);
        EmplLedgerEntriesPreview.OriginalAmountFCY.AssertEquals(Amount1);
        EmplLedgerEntriesPreview.RemainingAmountFCY.AssertEquals(Amount1);

        EmplLedgerEntriesPreview.Next();
        EmplLedgerEntriesPreview.AmountFCY.AssertEquals(Amount2);
        EmplLedgerEntriesPreview.OriginalAmountFCY.AssertEquals(Amount2);
        EmplLedgerEntriesPreview.RemainingAmountFCY.AssertEquals(Amount2);

        EmplLedgerEntriesPreview.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure VerifyBankAccountEntries(Amount: Decimal; GLPostingPreview: TestPage "G/L Posting Preview")
    var
        BankAccLedgEntrPreview: TestPage "Bank Acc. Ledg. Entr. Preview";
    begin
        BankAccLedgEntrPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Bank Account Ledger Entry"));
        GLPostingPreview.Show.Invoke();

        BankAccLedgEntrPreview.Amount.AssertEquals(Amount);
        BankAccLedgEntrPreview.OK().Invoke();
    end;

    local procedure VerifyGLEntryWithRegister(AccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLReg: Record "G/L Register";
    begin
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
        GLReg.Init();
        GLReg.SetFilter("From Entry No.", '..%1', GLEntry."Entry No.");
        GLReg.SetFilter("To Entry No.", '%1..', GLEntry."Entry No.");
        Assert.RecordIsNotEmpty(GLReg);
    end;

    local procedure VerifyEmptyPreviewError()
    begin
        Assert.AreEqual('', GetLastErrorText, ExpectedEmptyErrorFromPreviewErr + GetLastErrorText);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingToPostMessageHandler(Message: Text[1024])
    begin
        if Message <> JournalErrorsMgt.GetNothingToPostErrorMsg() then
            Error(UnexpectedMessageErr, Message);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewPageHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure CheckError(ExpectedError: Text[1024])
    begin
        if GetLastErrorText <> ExpectedError then
            Error(GetLastErrorText);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnBeforeDeleteEvent', '', false, false)]
    procedure OnDeletePmtJournalLine(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        Error(UnexpectedDeleteErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostGLAccOnBeforeInsertGLEntry', '', false, false)]
    local procedure OnPostGLAccOnBeforeInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; Balancing: Boolean)
    begin
        if MakeInconsistence then
            GLEntry.Amount := GLEntry.Amount + LibraryRandom.RandDec(100, 2);
    end;

    [Normal]
    local procedure CreateEmployee(var Employee: Record Employee)
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        EmployeePostingGroup.Init();
        EmployeePostingGroup.Validate(Code, LibraryUtility.GenerateGUID());
        EmployeePostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        EmployeePostingGroup.Insert(true);
        Employee.Validate("Employee Posting Group", EmployeePostingGroup.Code);
        Employee.Modify(true);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure InconsistenceSendNotificationHandler(var Notification: Notification): Boolean
    begin
        // Not possible to check notification message here because it appears under the asserterror statement
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}

