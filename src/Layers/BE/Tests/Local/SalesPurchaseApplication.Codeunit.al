codeunit 144002 "Sales/Purchase Application"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJob: Codeunit "Library - Job";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        WrongApplDateErr: Label 'When using workdate for applying/unapplying, the workdate must not be before the latest posting date';
        EmptyJnlTemplateErr: Label 'Journal Template Name must have a value';
        InvalidErr: Label 'Invalid error: ''''%1''''.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales/Purchase Application");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales/Purchase Application");

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales/Purchase Application");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesApplyWithUseWorkDate()
    var
        DocNo: Code[20];
    begin
        DocNo := SalesApplicationWithDefApplicationDate(true);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesApplyWithoutUseWorkDate()
    var
        DocNo: Code[20];
    begin
        DocNo := SalesApplicationWithDefApplicationDate(false);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, GetDefPostingDate());
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesApplyWhenApplicationDateBeforeWorkdateWithUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := SalesApplication(true, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesApplyWhenApplicationDateBeforeWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := SalesApplication(false, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler')]
    [Scope('OnPrem')]
    procedure SalesApplyWhenApplicationDateAfterWorkdateWithUseWorkdate()
    begin
        asserterror SalesApplication(true, CalcDate('<1D>', WorkDate()));
        Assert.ExpectedError(WrongApplDateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesApplyWhenApplicationDateAfterWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<1D>', WorkDate());
        DocNo := SalesApplication(false, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesApplyWhenApplicationDateEqualWorkdateWithUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := SalesApplication(false, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesApplyWhenApplicationDateEqualWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := SalesApplication(false, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationWithJnlTemplBatchSettingsHandler')]
    [Scope('OnPrem')]
    procedure SalesApplyWithEmptyJnlTemplateName()
    begin
        asserterror SalesApplicationWithJnlTemplateBatchSettings('', '');
        Assert.ExpectedError(EmptyJnlTemplateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchApplyWithUseWorkDate()
    var
        DocNo: Code[20];
    begin
        DocNo := PurchApplicationWithDefApplicationDate(true);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchApplyWithoutUseWorkDate()
    var
        DocNo: Code[20];
    begin
        DocNo := PurchApplicationWithDefApplicationDate(false);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, GetDefPostingDate());
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchApplyWhenApplicationDateBeforeWorkdateWithUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := PurchApplication(true, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchApplyWhenApplicationDateBeforeWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := PurchApplication(false, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler')]
    [Scope('OnPrem')]
    procedure PurchApplyWhenApplicationDateAfterWorkdateWithUseWorkdate()
    begin
        asserterror PurchApplication(true, CalcDate('<1D>', WorkDate()));
        Assert.ExpectedError(WrongApplDateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchApplyWhenApplicationDateAfterWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<1D>', WorkDate());
        DocNo := PurchApplication(false, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchApplyWhenApplicationDateEqualWorkdateWithUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := PurchApplication(false, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchApplyWhenApplicationDateEqualWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := PurchApplication(false, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationWithJnlTemplBatchSettingsHandler')]
    [Scope('OnPrem')]
    procedure PurchApplyWithEmptyJnlTemplateName()
    begin
        asserterror PurchApplicationWithJnlTemplateBatchSettings('', '');
        Assert.ExpectedError(EmptyJnlTemplateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,UnapplyCustomerEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesUnapplyWhenApplicationDateBeforeWorkdateWithUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := SalesApplicationUnapply(true, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,UnapplyCustomerEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesUnapplyWhenApplicationDateBeforeWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := SalesApplicationUnapply(false, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,UnapplyCustomerEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesUnapplyWhenApplicationDateAfterWorkdateWithUseWorkdate()
    var
        ApplicationDate: Date;
    begin
        ApplicationDate := CalcDate('<1D>', WorkDate());
        asserterror SalesApplicationUnapply(true, ApplicationDate);
        Assert.ExpectedError(WrongApplDateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,UnapplyCustomerEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesUnapplyWhenApplicationDateAfterWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<1D>', WorkDate());
        DocNo := SalesApplicationUnapply(false, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,UnapplyCustomerEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesUnapplyWhenApplicationDateEqualWorkdateWithUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := SalesApplicationUnapply(false, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,UnapplyCustomerEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesUnapplyWhenApplicationDateEqualWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := SalesApplicationUnapply(false, ApplicationDate);
        VerifyApplicationDateOnDtldCustLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,UnapplyVendorEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchUnapplyWhenApplicationDateBeforeWorkdateWithUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := PurchApplicationUnapply(true, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,UnapplyVendorEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchUnapplyWhenApplicationDateBeforeWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := PurchApplicationUnapply(false, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,UnapplyVendorEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchUnapplyWhenApplicationDateAfterWorkdateWithUseWorkdate()
    begin
        asserterror PurchApplicationUnapply(true, CalcDate('<1D>', WorkDate()));
        Assert.ExpectedError(WrongApplDateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,UnapplyVendorEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchUnapplyWhenApplicationDateAfterWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<1D>', WorkDate());
        DocNo := PurchApplicationUnapply(false, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,UnapplyVendorEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchUnapplyWhenApplicationDateEqualWorkdateWithUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := PurchApplicationUnapply(false, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,UnapplyVendorEntriesHandler,ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchUnapplyWhenApplicationDateEqualWorkdateWithoutUseWorkdate()
    var
        ApplicationDate: Date;
        DocNo: Code[20];
    begin
        ApplicationDate := CalcDate('<-1D>', WorkDate());
        DocNo := PurchApplicationUnapply(false, ApplicationDate);
        VerifyApplicationDateOnDtldVendLedgEntry(DocNo, ApplicationDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringJournalsMayNotHaveNoSeries()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        ErrorText: Text;
    begin
        NoSeries.FindFirst();
        GenJournalTemplate.Init();
        GenJournalTemplate.Validate(Name, 'NewName');
        GenJournalTemplate.Validate(Recurring, true);

        asserterror GenJournalTemplate.Validate("No. Series", NoSeries.Code);
        Assert.AreEqual(GetLastErrorCode, 'Dialog', 'Wrong error code');
        ErrorText := GetLastErrorText;
        if StrPos(ErrorText, 'can be filled in on recurring') = 0 then
            Error(InvalidErr, ErrorText);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure JobLedgerEntryIsCreatedWhenPostingPreviewIsRunWithCopyLineDescrToGLEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        GLAccount: Record "G/L Account";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 386102] Job Ledger Entries are created, when Posting Preview are run with enabled "Copy Line Descr. to G/L Entry" in PurchSetup
        Initialize();

        // [GIVEN] Edited "Purchases & Payables Setup". Set "Copy Line Descr. to G/L Entry" to True
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Copy Line Descr. to G/L Entry", true);
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Created Purchase Order for G/L Account, Job and Job Task No.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate(
          "No.", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        PurchaseLine.Validate(Quantity, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
        Commit();

        // [WHEN] Run "Preview Posing" for created order
        GLPostingPreview.Trap();
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);

        // [THEN] No errors occured - preview mode error only
        // [THEN] Number of created "Job Ledger Entry" is equal to 1
        Assert.ExpectedError('');
        GLPostingPreview.FILTER.SetFilter("Table Name", 'Job Ledger Entry');
        GLPostingPreview.First();
        GLPostingPreview."No. of Records".AssertEquals(Format(1));
        GLPostingPreview.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure JobLedgerEntryIsCreatedWhenPostingPreviewIsRunWithoutCopyLineDescrToGLEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        JobTask: Record "Job Task";
        GLAccount: Record "G/L Account";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 386102] Job Ledger Entries are created, when Posting Preview are run with disabled "Copy Line Descr. to G/L Entry" in PurchSetup
        Initialize();

        // [GIVEN] Edited "Purchases & Payables Setup". Set "Copy Line Descr. to G/L Entry" to False
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Copy Line Descr. to G/L Entry", false);
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Created Purchase Order for G/L Account, Job and Job Task No.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate(
          "No.", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        PurchaseLine.Validate(Quantity, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
        Commit();

        // [WHEN] Run "Preview Posing" for created order
        GLPostingPreview.Trap();
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);

        // [THEN] No errors occured - preview mode error only
        // [THEN] Number of created "Job Ledger Entry" is equal to 1
        Assert.ExpectedError('');
        GLPostingPreview.FILTER.SetFilter("Table Name", 'Job Ledger Entry');
        GLPostingPreview.First();
        GLPostingPreview."No. of Records".AssertEquals(Format(1));
        GLPostingPreview.Close();
    end;

    local procedure SalesApplication(UseWorkDate: Boolean; ApplicationDate: Date): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        UpdateUseWorkdateInGLSetup(UseWorkDate);
        PostTwoSalesGenJnlLines(GenJnlLine);
        LibraryVariableStorage.Enqueue(ApplicationDate);
        ApplyCustomerLedgerEntries(GenJnlLine."Account No.", GenJnlLine."Document Type", GenJnlLine."Document No.");
        exit(GenJnlLine."Document No.");
    end;

    local procedure SalesApplicationWithDefApplicationDate(UseWorkDate: Boolean): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        UpdateUseWorkdateInGLSetup(UseWorkDate);
        PostTwoSalesGenJnlLines(GenJnlLine);
        ApplyAndPostCustomerEntry(GenJnlLine."Document Type", GenJnlLine."Document No.");
        exit(GenJnlLine."Document No.");
    end;

    local procedure SalesApplicationWithJnlTemplateBatchSettings(JnlTemplateName: Code[10]; JnlBatchName: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        LibraryVariableStorage.Enqueue(JnlTemplateName);
        LibraryVariableStorage.Enqueue(JnlBatchName);
        PostTwoSalesGenJnlLines(GenJnlLine);
        ApplyCustomerLedgerEntries(GenJnlLine."Account No.", GenJnlLine."Document Type", GenJnlLine."Document No.");
    end;

    local procedure SalesApplicationUnapply(UseWorkDate: Boolean; ApplicationDate: Date): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        // Post and apply
        UpdateUseWorkdateInGLSetup(false);
        PostTwoSalesGenJnlLines(GenJnlLine);
        LibraryVariableStorage.Enqueue(ApplicationDate);
        ApplyCustomerLedgerEntries(GenJnlLine."Account No.", GenJnlLine."Document Type", GenJnlLine."Document No.");
        // Unapply
        UpdateUseWorkdateInGLSetup(UseWorkDate);
        LibraryVariableStorage.Enqueue(ApplicationDate);
        UnapplyCustomerLedgerEntries(GenJnlLine."Account No.", GenJnlLine."Document Type", GenJnlLine."Document No.");
        exit(GenJnlLine."Document No.");
    end;

    local procedure PurchApplication(UseWorkDate: Boolean; ApplicationDate: Date): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        UpdateUseWorkdateInGLSetup(UseWorkDate);
        PostTwoPurchGenJnlLines(GenJnlLine);
        LibraryVariableStorage.Enqueue(ApplicationDate);
        ApplyVendorLedgerEntries(GenJnlLine."Account No.", GenJnlLine."Document Type", GenJnlLine."Document No.");
        exit(GenJnlLine."Document No.");
    end;

    local procedure PurchApplicationWithDefApplicationDate(UseWorkDate: Boolean): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        UpdateUseWorkdateInGLSetup(UseWorkDate);
        PostTwoPurchGenJnlLines(GenJnlLine);
        ApplyAndPostVendorEntry(GenJnlLine."Document Type", GenJnlLine."Document No.");
        exit(GenJnlLine."Document No.");
    end;

    local procedure PurchApplicationWithJnlTemplateBatchSettings(JnlTemplateName: Code[10]; JnlBatchName: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        LibraryVariableStorage.Enqueue(JnlTemplateName);
        LibraryVariableStorage.Enqueue(JnlBatchName);
        PostTwoPurchGenJnlLines(GenJnlLine);
        ApplyVendorLedgerEntries(GenJnlLine."Account No.", GenJnlLine."Document Type", GenJnlLine."Document No.");
    end;

    local procedure PurchApplicationUnapply(UseWorkDate: Boolean; ApplicationDate: Date): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Apply
        UpdateUseWorkdateInGLSetup(false);
        PostTwoPurchGenJnlLines(GenJnlLine);
        LibraryVariableStorage.Enqueue(ApplicationDate);
        ApplyVendorLedgerEntries(GenJnlLine."Account No.", GenJnlLine."Document Type", GenJnlLine."Document No.");

        // Unapply
        UpdateUseWorkdateInGLSetup(UseWorkDate);
        LibraryVariableStorage.Enqueue(ApplicationDate);
        UnapplyVendorLedgerEntries(GenJnlLine."Account No.", GenJnlLine."Document Type", GenJnlLine."Document No.");

        exit(GenJnlLine."Document No.");
    end;

    local procedure UpdateUseWorkdateInGLSetup(NewUserWorkDate: Boolean) OldUserWorkDate: Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        OldUserWorkDate := GLSetup."Use Workdate for Appl./Unappl.";
        GLSetup.Validate("Use Workdate for Appl./Unappl.", NewUserWorkDate);
        GLSetup.Modify(true);
    end;

    local procedure CreateCust(): Code[20]
    var
        Cust: Record Customer;
    begin
        LibrarySales.CreateCustomer(Cust);
        exit(Cust."No.");
    end;

    local procedure CreateVend(): Code[20]
    var
        Vend: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vend);
        exit(Vend."No.");
    end;

    local procedure CreateGLAcc(): Code[20]
    var
        GLAcc: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        exit(GLAcc."No.");
    end;

    local procedure PostTwoSalesGenJnlLines(var GenJnlLine: Record "Gen. Journal Line"): Code[20]
    begin
        PostTwoGenJnlLines(GenJnlLine, GenJnlLine."Account Type"::Customer, CreateCust());
    end;

    local procedure PostTwoPurchGenJnlLines(var GenJnlLine: Record "Gen. Journal Line"): Code[20]
    begin
        PostTwoGenJnlLines(GenJnlLine, GenJnlLine."Account Type"::Vendor, CreateVend());
    end;

    local procedure PostTwoGenJnlLines(var GenJnlLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    begin
        CreateGenJnlLineWithBalAcc(GenJnlLine, GenJnlLine."Document Type"::Invoice, AccType, AccNo, GetEntryAmount(AccType));
        CreateGenJnlLineWithBalAcc(GenJnlLine, GenJnlLine."Document Type"::Payment, AccType, GenJnlLine."Account No.", -GenJnlLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreateGenJnlLineWithBalAcc(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; EntryAmount: Decimal)
    begin
        InitGenJnlLineWithBatch(GenJnlLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", DocType, AccType, AccNo, EntryAmount);
        GenJnlLine.Validate("Posting Date", GetDefPostingDate());
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", CreateGLAcc());
        GenJnlLine.Modify(true);
    end;

    local procedure InitGenJnlLineWithBatch(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    local procedure ApplyCustomerLedgerEntries(CustNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustNo);
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(DocType));
        CustomerLedgerEntries.FILTER.SetFilter("Document No.", DocNo);
        CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    local procedure ApplyVendorLedgerEntries(VendNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendNo);
        VendorLedgerEntries.FILTER.SetFilter("Document No.", DocNo);
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(DocType));
        VendorLedgerEntries.ActionApplyEntries.Invoke();
    end;

    local procedure ApplyAndPostCustomerEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, DocType, DocNo);
        CustLedgEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgEntry, CustLedgEntry."Remaining Amount");
        CustLedgEntry2.SetFilter("Entry No.", '<>%1', CustLedgEntry."Entry No.");
        CustLedgEntry2.SetRange("Customer No.", CustLedgEntry."Customer No.");
        CustLedgEntry2.FindSet();
        repeat
            CustLedgEntry2.CalcFields("Remaining Amount");
            CustLedgEntry2.Validate("Amount to Apply", CustLedgEntry2."Remaining Amount");
            CustLedgEntry2.Modify(true);
        until CustLedgEntry2.Next() = 0;
        LibraryERM.SetAppliestoIdCustomer(CustLedgEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, DocType, DocNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendLedgEntry, VendLedgEntry."Remaining Amount");
        VendLedgEntry2.SetFilter("Entry No.", '<>%1', VendLedgEntry."Entry No.");
        VendLedgEntry2.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
        VendLedgEntry2.FindSet();
        repeat
            VendLedgEntry2.CalcFields("Remaining Amount");
            VendLedgEntry2.Validate("Amount to Apply", VendLedgEntry2."Remaining Amount");
            VendLedgEntry2.Modify(true);
        until VendLedgEntry2.Next() = 0;
        LibraryERM.SetAppliestoIdVendor(VendLedgEntry2);
        LibraryERM.PostVendLedgerApplication(VendLedgEntry);
    end;

    local procedure UnapplyCustomerLedgerEntries(CustNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustNo);
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(DocType));
        CustomerLedgerEntries.FILTER.SetFilter("Document No.", DocNo);
        CustomerLedgerEntries.UnapplyEntries.Invoke();
    end;

    local procedure UnapplyVendorLedgerEntries(VendNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendNo);
        VendorLedgerEntries.FILTER.SetFilter("Document No.", DocNo);
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(DocType));
        VendorLedgerEntries.UnapplyEntries.Invoke();
    end;

    local procedure GetDefPostingDate(): Date
    begin
        exit(CalcDate('<-1M>', WorkDate()));
    end;

    local procedure GetEntryAmount(AccType: Enum "Gen. Journal Account Type") Amount: Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Amount := LibraryRandom.RandDec(100, 2);
        if AccType = GenJnlLine."Account Type"::Vendor then
            Amount := -Amount;
    end;

    local procedure VerifyApplicationDateOnDtldCustLedgEntry(DocNo: Code[20]; ApplicationDate: Date)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange("Document No.", DocNo);
        DtldCustLedgEntry.FindLast();
        DtldCustLedgEntry.TestField("Posting Date", ApplicationDate);
    end;

    local procedure VerifyApplicationDateOnDtldVendLedgEntry(DocNo: Code[20]; ApplicationDate: Date)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange("Document No.", DocNo);
        DtldVendLedgEntry.FindLast();
        DtldVendLedgEntry.TestField("Posting Date", ApplicationDate);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationHandler(var PostApplication: TestPage "Post Application")
    var
        ApplicationDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ApplicationDate);
        PostApplication.PostingDate.SetValue(ApplicationDate);
        PostApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationWithJnlTemplBatchSettingsHandler(var PostApplication: TestPage "Post Application")
    var
        TemplateName: Variant;
        BatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        LibraryVariableStorage.Dequeue(BatchName);
        PostApplication.JnlTemplateName.SetValue(TemplateName);
        PostApplication.JnlBatchName.SetValue(BatchName);
        PostApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntriesHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
