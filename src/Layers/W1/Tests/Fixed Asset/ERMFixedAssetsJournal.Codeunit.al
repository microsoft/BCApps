codeunit 134450 "ERM Fixed Assets Journal"
{
    Permissions = TableData "G/L Account" = r,
                  TableData "Ins. Coverage Ledger Entry" = rimd,
                  TableData Employee = r;

    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        CopyFixedAssetError: Label '%1 must be equal to %2.';
        FAAllocationError: Label 'Number of FA Allocation must be equal.';
        NoSeriesError: Label 'Only the %1 field can be filled in on recurring journals.';
        FAPostingDateError: Label '%1 is not within your range of allowed posting dates in %2 %3=''%4'',%5=''%6'',%7=''%8''.';
        FADisposalError: Label 'Disposal must not be positive on %1 for Fixed Asset No. = %2 in %3 = %4.';
        FAAcquisitionError: Label '%1 Acquisition Cost must be posted in the FA journal in %2 %3=''%4'',%5=''%6'',Line No.=''%7''.';
        ReversalError: Label 'Maintenance Ledger Entry was not reversed properly.';
        DepreciationMethodError: Label '%1 must not be %2 in %3 %4=''%5'',%6=''%7''.';
        IndexAmountError: Label '%1 must be equal.';
        UnknownError: Label 'Unknown Error.';
        DisposeMainAssetError: Label 'You cannot dispose Main Asset %1 until Components are disposed.';
        TemplateSelectionError: Label 'Template must exits in %1.';
        ExpectedBatchError: Label 'Batch must be same as of %1.';
        FAJnlTemplateNameRecurring: Label 'Recurring';
        FAJnlTemplateDescRecJnl: Label 'Recurring Fixed Asset Journal';
        FAJnlTemplateNameAssets: Label 'ASSETS', Comment = 'ASSETS is the name of FA Journal Template.';
        FAJnlTemplateDescFAJnl: Label 'Fixed Asset Journal';
        CompletionStatsGenJnlQst: Label 'The depreciation has been calculated.\\1 fixed asset G/L journal lines were created.\\Do you want to open the Fixed Asset G/L Journal window?', Comment = 'The depreciation has been calculated.\\2 fixed asset G/L  journal lines were created.\\Do you want to open the Fixed Asset G/L Journal window?';
        ExtDocNoTok: Label 'ExtDocNo';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        AcquisitionOptions: Option "G/L Account",Vendor,"Bank Account";
        isInitialized: Boolean;
        SalvageValueErr: Label 'There is a reclassification salvage amount that must be posted first. Open the FA Journal page, and then post the relevant reclassification entry.';

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AcquireFixedAssetNotification()
    var
        FixedAsset: Record "Fixed Asset";
        DefaultDepreciationBookCode: Code[10];
    begin
        Initialize();
        // SETUP
        DefaultDepreciationBookCode := GetDefaultDepreciationBook();
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryLowerPermissions.AddO365Setup();

        // Exercise
        CreateFAAcquisitionSetupForWizard(FixedAsset, false);

        // Veryfication happens inside the notification handler

        // Teardown
        SetDefaultDepreciationBook(DefaultDepreciationBookCode);

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AcquireFixedAssetUsingAcquisitionWizardAutoPostBankAccount()
    begin
        // [SCENARIO] Go though the acquisiotion wizard, use Bank Account, post without opening G/L Journal Page
        AcquireFixedAssetUsingAcquisitionWizardAutoPost(AcquisitionOptions::"Bank Account", LibraryERM.CreateBankAccountNo());
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AcquireFixedAssetUsingAcquisitionWizardAutoPostGLAccount()
    begin
        // [SCENARIO] Go though the acquisiotion wizard, use G/L Account, post without opening G/L Journal Page
        AcquireFixedAssetUsingAcquisitionWizardAutoPost(AcquisitionOptions::"G/L Account", LibraryERM.CreateGLAccountNo());
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AcquireFixedAssetUsingAcquisitionWizardAutoPostVendorAccount()
    begin
        // [SCENARIO] Go though the acquisiotion wizard, use Vendor, post without opening G/L Journal Page
        AcquireFixedAssetUsingAcquisitionWizardAutoPost(AcquisitionOptions::Vendor, LibraryPurchase.CreateVendorNo());
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure AcquireFixedAssetGenJournalLinesCreation()
    var
        FixedAsset: Record "Fixed Asset";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalLine2: Record "Gen. Journal Line";
        FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
        DefaultDepreciationBookCode: Code[10];
        VendorNo: Code[20];
    begin
        // [SCENARIO] Setup the General G/L Journal lines for acquiring a Fixed Asset, and check that at the end we have 2 lines at FA GL Journal
        Initialize();
        // Setup
        DefaultDepreciationBookCode := GetDefaultDepreciationBook();
        CreateFAAcquisitionSetupForWizard(FixedAsset, false);
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddO365FASetup();
        LibraryLowerPermissions.AddJournalsEdit();
        LibraryLowerPermissions.AddO365Setup();
        VendorNo := LibraryPurchase.CreateVendorNo();
        // Exercise
        CreateGenJournalLineForGenJournalLinesCreation(TempGenJournalLine, VendorNo, FixedAsset."No.");
        // COMMIT is enforced because the Finish action is invoking a codeunit and uses the return value.
        Commit();

        TempGenJournalLine.CreateFAAcquisitionLines(GenJournalLine2);

        // Verify
        GenJournalLine2.Init();
        GenJournalLine2.SetRange("Journal Batch Name", FixedAssetAcquisitionWizard.GetAutogenJournalBatch());
        GenJournalLine2.SetRange("Journal Template Name", FixedAssetAcquisitionWizard.SelectFATemplate());
        Assert.RecordCount(GenJournalLine2, 2);
        GenJournalLine2.FindLast();
        Assert.AreEqual(VendorNo, GenJournalLine2."Account No.", 'Incorrect Account No.');
        Assert.AreEqual(GenJournalLine2."Account Type"::Vendor, GenJournalLine2."Account Type", 'Account type must be Vendor.');

        // Teardown
        SetDefaultDepreciationBook(DefaultDepreciationBookCode);

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AcquireFixedAssetGenJournalLinesAlreadyExist()
    var
        FixedAsset: Record "Fixed Asset";
        Vendor: Record Vendor;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalLine2: Record "Gen. Journal Line";
        FixedAssetAcquisitionWizard: TestPage "Fixed Asset Acquisition Wizard";
        DefaultDepreciationBookCode: Code[10];
    begin
        // [SCENARIO] Setup the General G/L Journal lines for acquiring a Fixed Asset when there are already lines for the given asset
        Initialize();
        // Setup
        DefaultDepreciationBookCode := GetDefaultDepreciationBook();
        CreateFAAcquisitionSetupForWizard(FixedAsset, false);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddO365FASetup();
        LibraryLowerPermissions.AddJournalsEdit();

        // Exercise
        CreateGenJournalLineForGenJournalLinesCreation(TempGenJournalLine, Vendor."No.", FixedAsset."No.");
        // COMMIT is enforced because the Finish action is invoking a codeunit and uses the return value.
        Commit();
        TempGenJournalLine.CreateFAAcquisitionLines(GenJournalLine2);

        // Verify
        TempGenJournalLine.SetRange("Account No.", FixedAsset."No.");
        FixedAssetAcquisitionWizard.Trap();
        PAGE.Run(PAGE::"Fixed Asset Acquisition Wizard", TempGenJournalLine);
        // The finish button enabled is the only differentiating factor between
        // this case and the normal one
        Assert.IsTrue(FixedAssetAcquisitionWizard.Finish.Enabled(), 'Finish button has to be enabled.');

        // Teardown
        SetDefaultDepreciationBook(DefaultDepreciationBookCode);
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine2."Journal Batch Name");
        GenJournalLine2.DeleteAll();

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppreciationFixedAsset()
    var
        DepreciationBook: Record "Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FAGetBalanceAccount: Codeunit "FA Get Balance Account";
    begin
        // Test the Appreciation of Fixed Assets.

        // 1.Setup: Create Fixed Asset, FA Acquisition, FA Journal Line and Insert FA Bal Account.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          GenJournalLine."FA Posting Type"::Appreciation);

        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        UpdateAppreciationAccount(FixedAsset."FA Posting Group");
        GenJournalLine.SetRange("Account No.", GenJournalLine."Account No.");
        FAGetBalanceAccount.InsertAcc(GenJournalLine); // Insert FA Bal Account.

        // 2.Exercise: Post FA G/L Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify Amount on FA Ledger Entry Correctly Populated.
        VerifyAmountInFATransaction(FixedAsset."No.", FAJournalLine."FA Posting Type"::Appreciation);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelFALedgerEntries()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        CancelFALedgEntries: Codeunit "Cancel FA Ledger Entries";
    begin
        // Test the Cancelation of FA Ledger Entries.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Journal line and Create FA Journal Setup.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");

        // 2.Exercise: Cancel FA Ledger Entries.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.FindLast();
        CancelFALedgEntries.TransferLine(FALedgerEntry, false, 0D);

        // 3.Verify: Verify that the Cancel FA Ledger Entries No. exist in Gen Journal Line.
        VerifyCancelFALedgerEntry(FALedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFixedAssets()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        NoOfFixedAssetCopied: Integer;
        FixedAssetCount: Integer;
    begin
        // Test the Copy Fixed Assets functionality.

        // 1.Setup: Create Fixed Asset, FA Posting Group, FA Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        FixedAssetCount := FixedAsset.Count();
        NoOfFixedAssetCopied := LibraryRandom.RandInt(10);  // Using Random Generator to Copy the Number of Fixed Asset.

        // 2.Exercise: Run the Copy Fixed Assets.
        LibraryLowerPermissions.SetO365FAEdit();
        RunCopyFixedAsset(FixedAsset, NoOfFixedAssetCopied);

        // 3.Verify: New count of Fixed Asset should be Equal to total of Previous Fixed Asset count and No of fixed assets copied.
        Assert.AreEqual(FixedAssetCount + NoOfFixedAssetCopied, FixedAsset.Count, CopyFixedAssetError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDepreciationBookEntries()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        Amount: Decimal;
    begin
        // Test Copy FA Ledger Entries from Depreciation Book.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Journal, Create a new Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");
        Amount := FAJournalLine.Amount;

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        CreateJournalSetupDepreciation(DepreciationBook);

        UpdateFAJournalBatchPostingNoSeries(DepreciationBook.Code);

        // 2.Exercise: Run Copy Depreciation Book.
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAEdit();
        RunCopyDepreciationBook(FixedAsset."No.", FADepreciationBook."Depreciation Book Code", DepreciationBook.Code, true);

        // 3.Verify: Verify Amoount in FA Journal Line.
        VerifyAmountInFAJournalLine(FixedAsset."No.", DepreciationBook.Code, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDepreciationBook()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        // Test Copy Depreciation Book.

        // 1.Setup: Create Fixed Asset, FA Posting Group, FA Journal Line, Post the FA Journal, Create a new Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateJournalSetupDepreciation(DepreciationBook);

        // 2.Exercise: Run Copy Depreciation Book.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddO365FASetup();
        RunCopyDepreciationBook(FixedAsset."No.", FADepreciationBook."Depreciation Book Code", DepreciationBook.Code, false);

        // 3. Verify: Verify New Depreciation Book is attached with Fixed Asset.
        VerifyDepreciationBookAttached(FixedAsset."No.", DepreciationBook.Code);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBalanceAccount()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test the Calculate Depreciation with Bal Account.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Journal Line, Create FA Allocation and Create FA Journal Setup.
        Initialize();
        CreateFixedAssetWithAllocationAndJournalSetup(FADepreciationBook);

        // 2.Exercise: Run the Calculate Depreciation.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true);

        // 3.Verify: Verify that the line in FA G/L Journal created for Fixed Asset.
        GenJournalLine.SetRange("Document No.", FADepreciationBook."FA No.");
        GenJournalLine.FindFirst();
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostFAGLJournalNonLinearDepreciationMethod()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
    begin
        Initialize();

        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        UpdateDepreciationMethod(FADepreciationBook);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");

        // 2.Exercise: Run the Calculate Depreciation and post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        DeleteGeneralJournalLine(FADepreciationBook."Depreciation Book Code");
        RunCalculateDepreciation(FixedAsset."No.", FADepreciationBook."Depreciation Book Code", true);
        PostDepreciationWithDocumentNo(FADepreciationBook."Depreciation Book Code");

        // 3.Verify: Verify FA Ledger Entry for Depreciation.
        VerifyDepreciationFALedger(FixedAsset."No.", DepreciationBook.Code);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationWOBalanceAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Test the Calculate Depreciation without Bal Account.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Journal Line, Create FA Allocation and Create FA Journal Setup.
        Initialize();
        CreateFixedAssetWithAllocationAndJournalSetup(FADepreciationBook);

        // 2.Exercise: Run the Calculate Depreciation.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        RunCalculateDepreciation(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", false);

        // 3.Verify: Verify that the line in FA G/L Journal created for Fixed Asset.
        GenJournalLine.SetRange("Document No.", FADepreciationBook."FA No.");
        GenJournalLine.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAAllocation()
    var
        FAPostingGroup: Record "FA Posting Group";
        FAAllocation: Record "FA Allocation";
        FAEntriesCreated: Integer;
    begin
        // Test the FA Allocation.

        // 1.Setup: Create FA Posting Group.
        Initialize();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // 2.Exercise: Create FA Allocation.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365FASetup();
        FAEntriesCreated := CreateFAAllocation(FAAllocation, FAPostingGroup.Code);

        // 3.Verify: Verify the line in FA allocation created for FA Posting Group.
        CountFAAllocationEntries(FAPostingGroup.Code, FAEntriesCreated);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Test the Purchase of Fixed Assets from Invoice ,Test the FA Ledger Entries

        // 1.Setup: Create Fixed Asset, FA Posting Group, Purchase Header and Purchase Line.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // 2.Exercise: Post Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // 3.Verify: Verify that Line Amount and Fixed Asset No. in Purchase Invoice Line.
        VerifyPurchaseInvoiceLine(PurchaseHeader, PurchaseLine."No.", PurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetIndexation()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
    begin
        // Test the Indexation of a Fixed Asset.

        // 1.Setup: Create Fixed Asset, FA Journal line, FA Posting Group, FA Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        AcquisitionCostBalanceAccount(FixedAsset."FA Posting Group");

        // 2.Exercise: Run Index Fixed Assets.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAView();
        RunIndexFixedAssets(FixedAsset."No.", FADepreciationBook."Depreciation Book Code");

        // 3.Verify: Verify the FA G/L Journal entries Created for Fixed asset with index Entry marked as True.
        VerifyIndexationEntry(FixedAsset."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFixedAssetJournal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        TempFAJournalLine: Record "FA Journal Line" temporary;
    begin
        // Test the Posting of FA Journal line.

        // 1.Setup: Create Fixed Asset and FA Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");
        CopyFAJournalLine(TempFAJournalLine, FAJournalLine);

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that Document Type, Fixed Asset No, FA Posting Type and Amount on FA Ledger Entry Correctly Populated.
        VerifyValuesInFALedgerEntry(TempFAJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialDisposalOfFA()
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test the Partial Disposal of an Asset Functionality.

        // 1.Setup: Create Fixed Asset, FA Acquisition, Sales Header and Create Sales Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        AcquisitionCostBalanceAccount(FixedAsset."FA Posting Group");
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateSalesOrder(SalesHeader, SalesLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code");

        // 2.Exercise: Post Sales Order.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // 3.Verify: The amount in FA ledger Entry.
        VerifyDisposalAmount(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFAGLJournal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Test the posting of FA G/L Journal.

        // 1.Setup: Create Fixed Asset, FA Posting Group, FA Depreciation Book and FA G/L Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          GenJournalLine."FA Posting Type"::"Acquisition Cost");

        BalanceAccountFAGLJournalLine(GenJournalLine);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");

        // 2.Exercise: Post FA G/L Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify the Amount on FA Ledger Entry for Fixed Asset.
        VerifyAmountInFAEntry(FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupDepreciationBook()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Test the Creation of New Depreciation Book.

        // 1.Setup:
        Initialize();

        // 2.Exercise: Create Depreciation Book, Create FA Journal Setup.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365FASetup();
        CreateJournalSetupDepreciation(DepreciationBook);

        // 3.Verify: Verify the New depreciation Book Created.
        DepreciationBook.Get(DepreciationBook.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteDownFixedAsset()
    var
        DepreciationBook: Record "Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FAGetBalanceAccount: Codeunit "FA Get Balance Account";
        GenJournalLineAmount: Decimal;
    begin
        // Test the Write-Down of Fixed Assets.

        // 1.Setup: Create Fixed Asset, FA Acquisition, FA Journal, FA G/L Journal and Insert FA Bal Account.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");

        GenJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          GenJournalLine."FA Posting Type"::"Write-Down");

        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        UpdateWriteDownAmount(GenJournalLine, GenJournalLineAmount);
        UpdateWriteDownAccount(FixedAsset."FA Posting Group");
        GenJournalLine.SetRange("Account No.", GenJournalLine."Account No.");
        FAGetBalanceAccount.InsertAcc(GenJournalLine);  // Insert FA Bal Account.

        // 2.Exercise: Post FA G/L Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify that Amount on FA Ledger Entry Correctly Populated.
        VerifyAmountInFATransaction(FixedAsset."No.", FAJournalLine."FA Posting Type"::"Write-Down");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InputBalanceAccount()
    var
        DepreciationBook: Record "Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FAPostingGroup: Record "FA Posting Group";
        FAGetBalanceAccount: Codeunit "FA Get Balance Account";
    begin
        // Test Balance Account Correctly Inserted.

        // 1.Setup: Create Fixed Asset, FA Acquisition, FA Journal, FA G/L Journal.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          GenJournalLine."FA Posting Type"::"Write-Down");
        UpdateWriteDownAccount(FixedAsset."FA Posting Group");

        // 2.Exercise: Insert FA Bal Account
        LibraryLowerPermissions.SetO365FAView();
        LibraryLowerPermissions.AddJournalsPost();
        GenJournalLine.SetRange("Account No.", GenJournalLine."Account No.");
        FAGetBalanceAccount.InsertAcc(GenJournalLine);

        // 3.Verify: Verify that Balance Account Correctly Inserted.
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.FindLast();
        GenJournalLine2.TestField("Account No.", FAPostingGroup."Write-Down Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupInsuranceBook()
    var
        FASetup: Record "FA Setup";
        OldInsuranceDeprBookValue: Code[10];
    begin
        // Test Insurance Depreciation Book updated in Fixed Asset Setup.

        // 1. Setup:
        Initialize();
        FASetup.Get();
        OldInsuranceDeprBookValue := FASetup."Insurance Depr. Book";

        // 2. Exercise: Update Insurance Depreciation Book.
        LibraryLowerPermissions.SetO365FASetup();
        UpdateInsuranceBook(FASetup, '');
        UpdateDefaultDepreciationBook(FASetup);

        // 3. Verify: Check Setup fields are non blank.
        FASetup.TestField("Insurance Depr. Book", FASetup."Default Depr. Book");

        // 4. Tear Down: Assign back Old Value of Insurance Depreciation Book.
        UpdateInsuranceBook(FASetup, OldInsuranceDeprBookValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePostingGroup()
    var
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
    begin
        // Test Fixed Asset Posting Group.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Fixed Asset Posting Group and Sub Class.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365FASetup();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFASubclass(FASubclass);

        // 3. Verify: Check FA Posting Group and Sub Class generated.
        FAPostingGroup.Get(FAPostingGroup.Code);
        FASubclass.Get(FASubclass.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AcquisitionCostAccount()
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Test Error Occurs on updating Acquisition Cost Account in FA Posting Group.

        // 1. Setup: Create FA Posting Group and GL Account.
        Initialize();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GLAccountNo := CreateBlockedGLAccount();

        // 2. Exercise: Update Acquisition Cost Account.
        LibraryLowerPermissions.SetO365FAEdit();
        asserterror FAPostingGroup.Validate("Acquisition Cost Account", GLAccountNo);

        // 3. Verify: Check Application throws an Error while updating Block Account.
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDepreciationAccount()
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Test Error Occurs on updating Accumulated Depreciation Account in FA Posting Group.

        // 1. Setup: Create FA Posting Group and GL Account.
        Initialize();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GLAccountNo := CreateBlockedGLAccount();

        // 2. Exercise: Update Accumulated Depreciation Account.
        LibraryLowerPermissions.SetO365FASetup();
        asserterror FAPostingGroup.Validate("Accum. Depreciation Account", GLAccountNo);

        // 3. Verify: Check Application throws an Error while updating Block Account.
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAcquisitionDisposal()
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Test Error Occurs on updating Acquisition Cost Account on Disposal in FA Posting Group.

        // 1. Setup: Create FA Posting Group and GL Account.
        Initialize();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GLAccountNo := CreateBlockedGLAccount();

        // 2. Exercise: Update Acquisition Cost Account.
        LibraryLowerPermissions.SetO365FASetup();
        asserterror FAPostingGroup.Validate("Acq. Cost Acc. on Disposal", GLAccountNo);

        // 3. Verify: Check Application throws an Error while updating Block Account.
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDisposalAccount()
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Test Error Occurs on updating Accumulated Depreciation Account on Disposal in FA Posting Group.

        // 1. Setup: Create FA Posting Group and GL Account.
        Initialize();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GLAccountNo := CreateBlockedGLAccount();

        // 2. Exercise: Update Accumulated Depreciation Account on Disposal.
        LibraryLowerPermissions.SetO365FASetup();
        asserterror FAPostingGroup.Validate("Accum. Depr. Acc. on Disposal", GLAccountNo);

        // 3. Verify: Check Application throws an Error while updating Block Account.
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GainsDisposalAccount()
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Test Error Occurs on updating Gains Account on Disposal in FA Posting Group.

        // 1. Setup: Create FA Posting Group and GL Account.
        Initialize();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GLAccountNo := CreateBlockedGLAccount();

        // 2. Exercise: Update Gains Account on Disposal.
        LibraryLowerPermissions.SetO365FASetup();
        asserterror FAPostingGroup.Validate("Gains Acc. on Disposal", GLAccountNo);

        // 3. Verify: Check Application throws an Error while updating Block Account.
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LossDisposalAccount()
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Test Error Occurs on updating Losses Account on Disposal in FA Posting Group.

        // 1. Setup: Create FA Posting Group and GL Account.
        Initialize();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GLAccountNo := CreateBlockedGLAccount();

        // 2. Exercise: Update Losses Account on Disposal.
        LibraryLowerPermissions.SetO365FASetup();
        asserterror FAPostingGroup.Validate("Losses Acc. on Disposal", GLAccountNo);

        // 3. Verify: Check Application throws an Error while updating Block Account.
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceExpenseAccount()
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Test Error Occurs on updating Maintenance Expense Account in FA Posting Group.

        // 1. Setup: Create FA Posting Group and GL Account.
        Initialize();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GLAccountNo := CreateBlockedGLAccount();

        // 2. Exercise: Update Maintenance Expense Account.
        LibraryLowerPermissions.SetO365FASetup();
        asserterror FAPostingGroup.Validate("Maintenance Expense Account", GLAccountNo);

        // 3. Verify: Check Application throws an Error while updating Block Account.
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DepreciationExpenseAccount()
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // Test Error Occurs on updating Depreciation Expense Account in FA Posting Group.

        // 1. Setup: Create FA Posting Group and GL Account.
        Initialize();
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GLAccountNo := CreateBlockedGLAccount();

        // 2. Exercise: Update Depreciation Expense Account.
        LibraryLowerPermissions.SetO365FASetup();
        asserterror FAPostingGroup.Validate("Depreciation Expense Acc.", GLAccountNo);

        // 3. Verify: Check Application throws an Error while updating Block Account.
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalSetup()
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
    begin
        // Test Fixed Asset Journal Setup.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Fixed Asset Journal Setup.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365FASetup();
        CreateJournalSetupDepreciation(DepreciationBook);

        // 3. Verify: Check FA Journal Setup generated.
        FAJournalSetup.SetRange("Depreciation Book Code", DepreciationBook.Code);
        FAJournalSetup.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalSetupBatch()
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
    begin
        // Test Check FA Journal Batch Name in Journal Setup.

        // 1. Setup: Create Fixed Asset Journal Setup.
        Initialize();
        CreateJournalSetupDepreciation(DepreciationBook);

        // 2. Exercise: Modify Fixed Asset Journal Setup.
        LibraryLowerPermissions.SetO365FASetup();
        UpdateTemplateOnJournalSetup(FAJournalSetup, DepreciationBook.Code);

        // 3. Verify: Check FA Journal Batch get blank.
        FAJournalSetup.TestField("FA Jnl. Batch Name", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalTemplate()
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        // Test FA Journal Template.

        // 1.Setup:
        Initialize();

        // 2.Exercise: Create FA Journal Template.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365FASetup();
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);

        // 3. Verify: Check FA Journal Template created correctly.
        FAJournalTemplate.Get(FAJournalTemplate.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalTemplateWithRecurring()
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        // Test FA Journal Template with Recurring.

        // 1. Setup: Create and modify FA Journal Template.
        Initialize();
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        ModifyRecurringOnTemplate(FAJournalTemplate);

        // 2. Exercise: Update No Series.
        LibraryLowerPermissions.SetO365Setup();
        asserterror FAJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());

        // 3. Verify: Check Application throws an error while updating No Series with Recurring.
        Assert.AreEqual(StrSubstNo(NoSeriesError, FAJournalTemplate.FieldName("Posting No. Series")), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DepreciationDocument()
    var
        DepreciationTableHeader: Record "Depreciation Table Header";
        DepreciationTableLine: Record "Depreciation Table Line";
    begin
        // Test Depreciation Table and Line Creation.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create FA Depreciation Table Header and Line.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365FASetup();
        LibraryFixedAsset.CreateDepreciationTableHeader(DepreciationTableHeader);
        CreateDepreciationTableLine(DepreciationTableLine, DepreciationTableHeader.Code);

        // 3. Verify: Check FA Depreciation Table created correctly.
        DepreciationTableHeader.Get(DepreciationTableLine."Depreciation Table Code");
        DepreciationTableLine.TestField(
          "No. of Units in Period",
          Round(DepreciationTableHeader."Total No. of Units" * DepreciationTableLine."Period Depreciation %" / 100, 0.00001));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MainAssetComponent()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        MainAssetComponent: Record "Main Asset Component";
    begin
        // Test Main Assets Components.

        // 1. Setup: Create Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset2);

        // 2. Exercise: Create FAs for FA Main Asset and FA No for FA Main Asset Creation.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset."No.", FixedAsset2."No.");

        // 3. Verify: Check FA main Asset Component Created Correctly.
        MainAssetComponent.Get(FixedAsset."No.", FixedAsset2."No.");
        MainAssetComponent.TestField(Description, FixedAsset2.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Maintenance()
    var
        Maintenance: Record Maintenance;
    begin
        // Test New Maintenance Code.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create FA Maintenance.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365FASetup();
        LibraryFixedAsset.CreateMaintenance(Maintenance);

        // 3. Verify: Check FA Maintenance Created Correctly.
        Maintenance.Get(Maintenance.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsuranceType()
    var
        InsuranceType: Record "Insurance Type";
    begin
        // Test New Insurance Types in Insurance Setup.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create FA Insurance Type.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365FASetup();
        LibraryFixedAsset.CreateInsuranceType(InsuranceType);

        // 3. Verify: Check FA Insurance Type Created Correctly.
        InsuranceType.Get(InsuranceType.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFAMaintenance()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Posting of FA Maintenance.

        // 1.Setup: Create Fixed Asset, FA Posting Group, FA Depreciation Book and FA General Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateAndUpdateJournalLine(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Maintenance);

        // 2.Exercise: Post FA G/L Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify the Amount on Maintenance Ledger Entry.
        VerifyMaintenanceEntry(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseFAMaintenance()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Test Reversal of FA Maintenance.

        // 1.Setup: Create Fixed Asset, FA Posting Group, FA Depreciation Book, FA General Journal Line and Post.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateAndUpdateJournalLine(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Maintenance);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindMaintenanceLedgerEntry(MaintenanceLedgerEntry, GenJournalLine."Account No.");

        // 2.Exercise: Reverse Maintenance Ledger Entry.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(MaintenanceLedgerEntry."Transaction No.");

        // 3.Verify: Verify the Amount on Maintenance Ledger Entry.
        VerifyMaintenanceEntryReversal(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAAcquisitionFromFAJournal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        TempFAJournalLine: Record "FA Journal Line" temporary;
    begin
        // Test the Fixed Asset Acquisition with FA Journal.

        // 1.Setup: Create Fixed Asset and FA Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Acquisition Cost");
        CopyFAJournalLine(TempFAJournalLine, FAJournalLine);

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that Document Type, Fixed Asset No, FA Posting Type and Amount on FA Ledger Entry Correctly Populated.
        VerifyValuesInFALedgerEntry(TempFAJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetDepreciation()
    var
        FAJournalLine: Record "FA Journal Line";
        TempFAJournalLine: Record "FA Journal Line" temporary;
    begin
        // Test the Fixed Asset Depreciation with FA Journal.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Acquisition, and Update Amount in FA Journal Line.
        Initialize();
        CreateAndAcquireFixedAssetAndNewJournalLineWithUpdatedAmount(
          FAJournalLine."FA Posting Type"::Depreciation, FAJournalLine."Document Type"::Invoice, FAJournalLine);
        CopyFAJournalLine(TempFAJournalLine, FAJournalLine);

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that Document Type, Fixed Asset No, FA Posting Type and Amount on FA Ledger Entry Correctly Populated.
        VerifyValuesInFALedgerEntry(TempFAJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteDownFixedAssetFAJournal()
    var
        FAJournalLine: Record "FA Journal Line";
        TempFAJournalLine: Record "FA Journal Line" temporary;
    begin
        // Test the Fixed Asset Write Dowm with FA Journal.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Acquisition, and Update Amount in FA Journal Line.
        Initialize();
        CreateAndAcquireFixedAssetAndNewJournalLineWithUpdatedAmount(
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Write-Down", FAJournalLine);
        CopyFAJournalLine(TempFAJournalLine, FAJournalLine);

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that Document Type, Fixed Asset No, FA Posting Type and Amount on FA Ledger Entry Correctly Populated.
        VerifyValuesInFALedgerEntry(TempFAJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppreciationOfFAFromFAJournal()
    var
        FAJournalLine: Record "FA Journal Line";
        TempFAJournalLine: Record "FA Journal Line" temporary;
    begin
        // Test the Fixed Asset Appreciation With FA Journal.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Acquisition, and Update Amount in FA Journal Line.
        Initialize();
        CreateAndAcquireFixedAssetAndNewJournalLineWithUpdatedAmount(
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::Appreciation, FAJournalLine);
        CopyFAJournalLine(TempFAJournalLine, FAJournalLine);

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that Document Type, Fixed Asset No, FA Posting Type and Amount on FA Ledger Entry Correctly Populated.
        VerifyValuesInFALedgerEntry(TempFAJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Custom1FixedAssetFAJournal()
    var
        FAJournalLine: Record "FA Journal Line";
        TempFAJournalLine: Record "FA Journal Line" temporary;
    begin
        // Test the Fixed Asset Posting with FA Posting Type as Custom 1 in FA Journal.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Acquisition, and Update Amount in FA Journal Line.
        Initialize();
        CreateAndAcquireFixedAssetAndNewJournalLineWithUpdatedAmount(
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Custom 1", FAJournalLine);
        CopyFAJournalLine(TempFAJournalLine, FAJournalLine);

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that Document Type, Fixed Asset No, FA Posting Type and Amount on FA Ledger Entry Correctly Populated.
        VerifyValuesInFALedgerEntry(TempFAJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Custom2FixedAssetFAJournal()
    var
        FAJournalLine: Record "FA Journal Line";
        TempFAJournalLine: Record "FA Journal Line" temporary;
    begin
        // Test the Fixed Asset Posting with FA Posting Type as Custom 2 in FA Journal.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Acquisition, and Update Amount in FA Journal Line.
        Initialize();
        CreateAndAcquireFixedAssetAndNewJournalLineWithUpdatedAmount(
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Custom 2", FAJournalLine);
        CopyFAJournalLine(TempFAJournalLine, FAJournalLine);

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that Document Type, Fixed Asset No, FA Posting Type and Amount on FA Ledger Entry Correctly Populated.
        VerifyValuesInFALedgerEntry(TempFAJournalLine);
    end;

    local procedure CreateAndAcquireFixedAssetAndNewJournalLineWithUpdatedAmount(FAPostingType: Enum "FA Journal Line FA Posting Type"; DocumentType: Enum "FA Journal Line Document Type"; var FAJournalLine: Record "FA Journal Line")
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLineAmount: Decimal;
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code", DocumentType, FAPostingType);
        UpdateAmountInFAJournalLine(FAJournalLine, FAJournalLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalvageValueOfFAFromFAJournal()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        DeprBookCode: Code[10];
        FANo: Code[20];
        FAJournalLineAmount: Decimal;
    begin
        // Test the Fixed Asset Posting with FA Posting Type as Salvage Value in FA Journal.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Acquisition and Update the Amount in FA Journal Line.
        Initialize();
        CreateAndAcquireFixedAssetAndNewJournalLineWithUpdatedAmount(
          FAJournalLine."FA Posting Type"::"Salvage Value", FAJournalLine."Document Type"::Invoice, FAJournalLine);
        FAJournalLineAmount := FAJournalLine.Amount;
        DeprBookCode := FAJournalLine."Depreciation Book Code";
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify the Salvage Value in attached Depreciation Book of Fixed Asset.
        FADepreciationBook.Get(FANo, DeprBookCode);
        FADepreciationBook.CalcFields("Salvage Value");
        FADepreciationBook.TestField("Salvage Value", FAJournalLineAmount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostingDateErrorFromFAJournal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
    begin
        // Test the Posting Date Error Message while posting Fixed Asset form FA Journal

        // 1.Setup: Create Fixed Asset, Update the date in FA setup, and FA Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        UpdatePostingDateInFASetup();
        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Acquisition Cost");

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify the Error Message Occured while posting.
        Assert.AreEqual(
          StrSubstNo(FAPostingDateError, FAJournalLine.FieldCaption("FA Posting Date"), FAJournalLine.TableCaption(),
            FAJournalLine.FieldCaption("Journal Template Name"), FAJournalLine."Journal Template Name",
            FAJournalLine.FieldCaption("Journal Batch Name"), FAJournalLine."Journal Batch Name",
            FAJournalLine.FieldCaption("Line No."), FAJournalLine."Line No."), GetLastErrorText, UnknownError);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostingDateErrorFAGLJournal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test the Posting Date Error Message while posting Fixed Asset form FA GL Journal.

        // 1.Setup: Create Fixed Asset, Update the date in FA setup and FA G/L Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        UpdatePostingDateInFASetup();
        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          GenJournalLine."FA Posting Type"::"Acquisition Cost");

        // 2.Exercise: Post FA G/L Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify the Error Message Occured while posting.
        Assert.AreEqual(
          StrSubstNo(FAPostingDateError, GenJournalLine.FieldCaption("FA Posting Date"), GenJournalLine.TableCaption(),
            GenJournalLine.FieldCaption("Journal Template Name"), GenJournalLine."Journal Template Name",
            GenJournalLine.FieldCaption("Journal Batch Name"), GenJournalLine."Journal Batch Name",
            GenJournalLine.FieldCaption("Line No."), GenJournalLine."Line No."), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADisposalErrorFromFAGLJournal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalLine: Record "FA Journal Line";
    begin
        // Test the Fixed Asset Disposal Error Message While Posting From FA G/L Journal.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Journal Line for Acqusition.
        // And Update the Balance Account in FA G/L Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Acquisition Cost");
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          GenJournalLine."FA Posting Type"::Disposal);
        BalanceAccountFAGLJournalLine(GenJournalLine);

        // 2.Exercise: Post FA G/L Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify the Error Message.
        Assert.AreEqual(
          StrSubstNo(FADisposalError, GenJournalLine."Posting Date", GenJournalLine."Account No.",
            FADepreciationBook.FieldCaption("Depreciation Book Code"), FADepreciationBook."Depreciation Book Code"),
          GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADisposalFromFAGLJournal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalLineAmount: Decimal;
    begin
        // Test the Fixed Asset Disposal From FA G/L Journal.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Journal Line for Acqusition,
        // Update the Balance Account in FA G/L Journal Line and Update the Amount in FA G/L Journal Line .
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          GenJournalLine."FA Posting Type"::Disposal);
        BalanceAccountFAGLJournalLine(GenJournalLine);
        UpdateDisposalAmount(GenJournalLine, FAJournalLineAmount);

        // 2.Exercise: Post FA G/L Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify the Disposal Amount in FA Ledger Entry.
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange(Amount, GenJournalLine.Amount);
        FALedgerEntry.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAWithComponentDisposalFromGLJournal_DisposeMainFABeforeComponent_ErrorOnPosting()
    var
        FixedAsset: Record "Fixed Asset";
        ComponentFixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        ComponentFADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        AllowPostingMainAsset: Boolean;
        MainFAAmount: Decimal;
    begin
        // 1.Setup
        Initialize();
        InitSetup(AllowPostingMainAsset);

        CreateFAWithComponent(FixedAsset, ComponentFixedAsset, FADepreciationBook, ComponentFADepreciationBook);

        MainFAAmount := PostFAAcquisition(FixedAsset, FADepreciationBook);
        CreateFADisposalJnlLine(GenJournalLine, FixedAsset, FADepreciationBook, MainFAAmount);
        // 2.Exercise
        LibraryLowerPermissions.SetO365FAEdit();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify
        Assert.ExpectedError(StrSubstNo(DisposeMainAssetError, FixedAsset."No."));

        // 4.Teardown
        LibraryLowerPermissions.SetO365FASetup();
        ResetSetup(AllowPostingMainAsset);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAWithComponentDisposalFromGLJournal_DisposeMainFAAfterComponent_NoErrorsOnPosting()
    var
        FixedAsset: Record "Fixed Asset";
        ComponentFixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        ComponentFADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        AllowPostingMainAsset: Boolean;
        ComponentFAAmount: Decimal;
        MainFAAmount: Decimal;
    begin
        // 1.Setup
        Initialize();
        InitSetup(AllowPostingMainAsset);

        CreateFAWithComponent(FixedAsset, ComponentFixedAsset, FADepreciationBook, ComponentFADepreciationBook);

        ComponentFAAmount := PostFAAcquisition(ComponentFixedAsset, FADepreciationBook);
        MainFAAmount := PostFAAcquisition(FixedAsset, FADepreciationBook);

        CreateFADisposalJnlLine(GenJournalLine, ComponentFixedAsset, ComponentFADepreciationBook, ComponentFAAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateFADisposalJnlLine(GenJournalLine, FixedAsset, FADepreciationBook, MainFAAmount);
        // 2.Exercise
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // 3.Verification - No errors occured.
        // 4.Teardown
        LibraryLowerPermissions.SetO365FASetup();

        ResetSetup(AllowPostingMainAsset);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowCorrectionOfDisposalError()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalLine: Record "FA Journal Line";
        FAJournalLineAmount: Decimal;
    begin
        // Test the Message 'Allow Correction of Disposal must not be No in Depreciation Book Code' from FA G/L Journal.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Journal Line for Acqusition and create FA G/L Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Disposal);
        BalanceAccountFAGLJournalLine(GenJournalLine);
        UpdateDisposalAmount(GenJournalLine, FAJournalLineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Disposal);
        BalanceAccountFAGLJournalLine(GenJournalLine);
        UpdateDisposalAmount(GenJournalLine, FAJournalLineAmount);

        // 2.Exercise: Post FA G/L Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify the Error Mesage.
        Assert.ExpectedTestFieldError(DepreciationBook.FieldCaption("Allow Correction of Disposal"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetCorrectionOfDisposal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalLine: Record "FA Journal Line";
        FAJournalLineAmount: Decimal;
    begin
        // Test the Fixed Asset Disposal with 'Allow correction in Disposal'.

        // 1.Setup: Create Fixed Asset, FA Journal Line, Post FA Journal Line for Acqusition and create FA G/L Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Disposal);
        BalanceAccountFAGLJournalLine(GenJournalLine);
        UpdateDisposalAmount(GenJournalLine, FAJournalLineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code", GenJournalLine."FA Posting Type"::Disposal);
        BalanceAccountFAGLJournalLine(GenJournalLine);
        UpdateDisposalAmount(GenJournalLine, FAJournalLineAmount);

        // Mark Allow Correction of Disposal as True in Depreciation Book Code
        SetAllowCorrectionOfDisposal(FADepreciationBook."Depreciation Book Code");

        // 2.Exercise: Post FA G/L Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify Amount in FA Ledger Entry.
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange(Amount, GenJournalLine.Amount);
        FALedgerEntry.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAAcquisitionCostError()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Test the FA Acquisition Cost Error From FA G/L Journal.

        // 1.Setup: Create Fixed Asset, FA G/L Journal Line and Update the Balance Acccount in FA/GL Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          GenJournalLine."FA Posting Type"::"Acquisition Cost");
        BalanceAccountFAGLJournalLine(GenJournalLine);

        // 2.Exercise: Post FA G/L Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAView();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verify: Verify the Error Message.
        Assert.AreEqual(
          StrSubstNo(FAAcquisitionError, GenJournalLine.FieldCaption("FA Posting Type"), GenJournalLine.TableCaption(),
            GenJournalLine.FieldCaption("Journal Template Name"), GenJournalLine."Journal Template Name",
            GenJournalLine.FieldCaption("Journal Batch Name"), GenJournalLine."Journal Batch Name",
            GenJournalLine."Line No."), GetLastErrorText, UnknownError)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        NoSeries: Codeunit "No. Series";
        NextFANo: Code[20];
    begin
        // Test Create New Fixed Asset.

        // 1. Setup: Get Next Fixed Asset No from No Series.
        Initialize();
        LibraryUtility.UpdateSetupNoSeriesCode(DATABASE::"FA Setup", FASetup.FieldNo("Fixed Asset Nos."));
        FASetup.Get();
        NextFANo := NoSeries.PeekNextNo(FASetup."Fixed Asset Nos.");

        // 2. Exercise: Create new Fixed Asset.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddO365FASetup();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // 3. Verify: Check that the application generates an error if FA No. is not incremented automatically as per the setup.
        FixedAsset.TestField("No.", NextFANo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostAcquisitionWithInsurance()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // Test Post Acquisition with Insurance.

        // 1. Setup: Create Fixed Asset, FA Posting Group, FA Depreciation Book and Purchase Invoice with Insurance.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", FADepreciationBook."Depreciation Book Code");
        ModifyInsuranceNo(PurchaseLine);

        // 2. Exercise: Post Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // 3. Verify: Check that Insurance Coverage Ledger Entry posted correctly.
        VerifyCoverageLedger(FindPostedInvoice(PurchaseHeader."No."), PurchaseLine."No.", PurchaseLine."Insurance No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinearDepreciationMethod()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // Test Linear Depreciation Method.

        // 1. Setup: Create Fixed Asset, FA Posting Group, FA Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");

        // 2. Exercise: Update No of Depreciation Years.
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAEdit();
        UpdateDepreciationYear(FADepreciationBook);

        // 3. Verify: Check that No of Depreciation Months updated correctly.
        FADepreciationBook.TestField("No. of Depreciation Months", Round(FADepreciationBook."No. of Depreciation Years" * 12, 0.00000001));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonLinearDepreciationMethod()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // Test Non Linear Depreciation Method.

        // 1. Setup: Create Fixed Asset, FA Posting Group, FA Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        UpdateDepreciationMethod(FADepreciationBook);

        // 2. Exercise: Update No of Depreciation Years.
        LibraryLowerPermissions.SetO365FASetup();
        asserterror UpdateDepreciationYear(FADepreciationBook);

        // 3. Verify: Check that Application generates an error while updating, No of Depreciation Year, for Non Linear
        // Depreciation Method.
        Assert.AreEqual(
          StrSubstNo(
            DepreciationMethodError, FADepreciationBook.FieldName("Depreciation Method"), FADepreciationBook."Depreciation Method",
            FADepreciationBook.TableName, FADepreciationBook.FieldName("FA No."), FADepreciationBook."FA No.",
            FADepreciationBook.FieldName("Depreciation Book Code"), FADepreciationBook."Depreciation Book Code"),
          GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostFAJournalBatch()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalLineAmount: Decimal;
    begin
        // Test the Post Fixed Asset Journal through FA Journal Batch.

        // 1.Setup: Create Fixed Asset,Depreciation Book,FA Depreciation Book, Create FA Journal Batch and create FA Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::" ", FAJournalLine."FA Posting Type"::"Acquisition Cost");

        Commit(); // Commit is required for Posting
        FAJournalLineAmount := FAJournalLine.Amount;
        FAJournalBatch.Get(FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name");

        // 2.Exercise: Post FA Journal Line through FA Journal Batch.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        FAJournalBatch.SetRange("Journal Template Name", FAJournalLine."Journal Template Name");
        FAJournalBatch.SetRange(Name, FAJournalLine."Journal Batch Name");
        LibraryFixedAsset.PostFAJournalLineBatch(FAJournalBatch);

        // 3.Verify: Verify Amount in FA Ledger Entry.
        VerifyAmountInFAEntry(FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost", FAJournalLineAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostRecurringFAJournalBatch()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalLineAmount: Decimal;
    begin
        // Test the Post Recurring Fixed Asset Journal through FA Journal Batch.

        // 1.Setup: Create Fixed Asset,Depreciation Book,FA Depreciation Book, Create FA Journal Batch For Recurring
        // and create Recurring FA Journal Line.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateFAJournalRecurringBatch(FAJournalBatch);
        CreateRecurringFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code", FAJournalBatch);

        Commit(); // Commit is required for Posting
        FAJournalLineAmount := FAJournalLine.Amount;

        // 2.Exercise: Post Recurring FA Journal Line through Recurring FA Journal Batch.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        FAJournalBatch.SetRange("Journal Template Name", FAJournalLine."Journal Template Name");
        FAJournalBatch.SetRange(Name, FAJournalLine."Journal Batch Name");
        LibraryFixedAsset.PostFAJournalLineBatch(FAJournalBatch);

        // 3.Verify: Verify Amount in FA Ledger Entry.
        VerifyAmountInFAEntry(FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost", FAJournalLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalWithDuplicateBookCode()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        Amount: Decimal;
        GLIntegrationAcqCost: Boolean;
    begin
        // Test Duplicate Entry in General Journal Line after Posting FA Journal with Duplicate in Depreciation Book Code.

        // 1. Setup: Create Depreciation Book, Fixed Asset, FA Depreciation Book with Default Depreciation Book on FA Setup and Created new
        // Depreciation Book, Update G/L Integration - Acq. Cost as false on Default Depreciation Book.
        Initialize();
        CreateJournalSetupDepreciation(DepreciationBook);
        UpdateDepreciationBook(DepreciationBook);
        CreateFAWithFADepreciationBook(FADepreciationBook, DepreciationBook.Code);
        GLIntegrationAcqCost := UpdateAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", false);
        CreateFAJournalBatch(FAJournalBatch);

        // 2. Exercise: Create and Post FA Journal Line with Duplicate in Depreciation Book Code.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        CreateFAJnlLine(
          FAJournalLine, FAJournalBatch, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        UpdateDuplicateBookCode(FAJournalLine, DepreciationBook.Code);
        Amount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3. Verify: Verify Duplicate Entry in General Journal Line.
        VerifyGeneralJournalLine(
          FADepreciationBook."FA No.", DepreciationBook.Code, Round(Amount * 100 / DepreciationBook."Default Exchange Rate"));

        // 4. Teardown: Rollback G/L Integration - Acq. Cost to Default Value for Default Depreciation Book and for new Depreciation Book
        // Part of Duplication List as False.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", GLIntegrationAcqCost);
        UpdatePartOfDuplicationList(DepreciationBook, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalWithUseDuplicateList()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        Amount: Decimal;
        GLIntegrationAcqCost: Boolean;
    begin
        // Test Duplicate Entry in General Journal Line after Posting FA Journal with Use Duplication List as True.

        // 1. Setup: Create Depreciation Book, Fixed Asset, FA Depreciation Book with Default Depreciation Book on FA Setup and Created new
        // Depreciation Book, Update G/L Integration - Acq. Cost as false on Default Depreciation Book.
        Initialize();
        CreateJournalSetupDepreciation(DepreciationBook);
        UpdateDepreciationBook(DepreciationBook);
        CreateFAWithFADepreciationBook(FADepreciationBook, DepreciationBook.Code);
        GLIntegrationAcqCost := UpdateAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", false);
        CreateFAJournalBatch(FAJournalBatch);

        // 2. Exercise: Create and Post FA Journal Line with Use Duplication List as True.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        CreateFAJnlLine(
          FAJournalLine, FAJournalBatch, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        UpdateUseDuplicationList(FAJournalLine);
        Amount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3. Verify: Verify Duplicate Entry in General Journal Line.
        VerifyGeneralJournalLine(
          FADepreciationBook."FA No.", DepreciationBook.Code, Round(Amount * 100 / DepreciationBook."Default Exchange Rate"));

        // 4. Teardown: Rollback G/L Integration - Acq. Cost to Default Value for Default Depreciation Book and for new Depreciation Book
        // Part of Duplication List as False.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateAcquisitionIntegration(FADepreciationBook."Depreciation Book Code", GLIntegrationAcqCost);
        UpdatePartOfDuplicationList(DepreciationBook, false);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure IndexFixedAssets()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        IndexFigure: Integer;
    begin
        // Test the Generates correct entry in FA G/L Journal after executing the Index Fixed Assets.

        // 1.Setup: Create Fixed Asset,FA Posting Group, FA Depreciation Book,Create and Post Purchase Invoice and
        // Calculate Depreciation and post.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        AcquisitionCostBalanceAccount(FixedAsset."FA Posting Group");

        CreateAndPostPurchaseInvoice(FixedAsset."No.", FADepreciationBook."Depreciation Book Code");
        DeleteGeneralJournalLine(FADepreciationBook."Depreciation Book Code");
        RunCalculateDepreciation(FixedAsset."No.", FADepreciationBook."Depreciation Book Code", true);
        PostDepreciationWithDocumentNo(FADepreciationBook."Depreciation Book Code");

        // 2.Exercise: Run Index Fixed Assets.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        IndexFigure := RunIndexFixedAssets(FixedAsset."No.", FADepreciationBook."Depreciation Book Code");

        // 3.Verify: Verify the FA G/L Journal entries Created for Fixed asset with correct Amount.
        VerifyFixedAssetsIndexEntry(FixedAsset."No.", IndexFigure);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DepreciationWithAcqCostTrue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalBatch: Record "FA Journal Batch";
        AcqusitionAmount: Decimal;
        DepreciationAmount: Decimal;
        NewAcqusitionAmount: Decimal;
        Amount: Decimal;
    begin
        // Test FA Ledger Entry after Posting FA Journal Line with "Depr. Acquisition Cost" field as True.

        // 1. Setup: Create Depreciation Book, Fixed Asset, Create and Post FA Journal Lines with FA Posting Type Acquisition Cost and
        // Depreciation.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        UpdateDepreciationCustomField(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        UpdateDepreciationEndingDate(FADepreciationBook);
        CreateAndPostAcqusitionLine(FADepreciationBook, AcqusitionAmount);
        DepreciationAmount := AcqusitionAmount;
        CreateAndPostDepreciationLine(FADepreciationBook, DepreciationAmount);
        CreateFAJournalBatch(FAJournalBatch);

        // 2. Exercise: Create and Post FA Journal Line with Depr. Acquisition Cost as True and Salvage Value.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        CreateFAJnlLine(
          FAJournalLine, FAJournalBatch, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        NewAcqusitionAmount := LibraryRandom.RandDec(100, 2);  // Using LibraryRandom for NewAcqusitionAmount
        Amount := LibraryRandom.RandDec(10, 2);  // Using LibraryRandom for amount
        UpdateAndPostWithSalvageValue(FAJournalLine, NewAcqusitionAmount, Amount);

        // 3. Verify: Verify Depreciation Amount on FA Ledger Entry..
        VerifyAmountInFAEntry(
          FixedAsset."No.", FALedgerEntry."FA Posting Type"::Depreciation,
          Round((NewAcqusitionAmount - Amount) * DepreciationAmount / AcqusitionAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndModifyFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
        TempFixedAsset: Record "Fixed Asset" temporary;
        Employee: Record Employee;
    begin
        // Test Create New Fixed Asset and Update Values on Fixed Asset.

        // 1. Setup: Create New Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // 2. Exercise: Update Responsible Employee, FA Class Code, FA Subclass Code, FA Location Code,
        // Vendor No., Maintenance Vendor No. on Fixed Asset.
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryHumanResource.CreateEmployee(Employee);
        LibraryLowerPermissions.SetO365FAEdit();
        UpdateValuesOnFixedAsset(TempFixedAsset, FixedAsset, Employee);

        // 3. Verify: Varify Values on Fixed Asset.
        VerifyValuesOnFixedAsset(TempFixedAsset);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFirstFAJournalTemplateCreationRecurringTrue()
    begin
        // Unit Test - COD5638: Test if no FA Journal Template exist then a default value is inserted and JnlSelected is TRUE with FA Journal Line remains empty.
        // with Template name as "Recurring" and Description as "Recurring Fixed Asset Journal" and Recurring Journal boolean is TRUE.

        // Setup: Setup Demo Data and make Cost Journal Setup Blank.
        Initialize();

        // Exercise and verify
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAEdit();
        VerifyFirstFAJournalTemplateCreation(true, FAJnlTemplateNameRecurring, FAJnlTemplateDescRecJnl);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFirstFAJournalTemplateCreationRecurringFalse()
    begin
        // Unit Test - COD5638: Test if no FA Journal Template exist then a default value is inserted and JnlSelected is TRUE with FA Journal Line remains empty.
        // with Template name as "ASSETS" and Description as "Fixed Asset Journal" and Recurring Journal boolean is FALSE.

        // Setup: Setup Demo Data and make Cost Journal Setup Blank.
        Initialize();

        // Exercise and verify
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAEdit();
        VerifyFirstFAJournalTemplateCreation(false, FAJnlTemplateNameAssets, FAJnlTemplateDescFAJnl);
    end;

    [Test]
    [HandlerFunctions('FAPageHandler')]
    [Scope('OnPrem')]
    procedure TestFAJournalBatchNameOnFAJournalPage()
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJnlManagement: Codeunit FAJnlManagement;
    begin
        // Unit Test - COD5638: Test FA Journal Batch name on FA Journal Batch Page when opened through batch.

        // Setup: Create a new FA journal template and cost journal batch.
        Initialize();
        CreateFAJournalBatch(FAJournalBatch);

        // Exercise: Execute TemplateSelectionFromBatch function of FAJnlManagement.
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAEdit();
        Commit();       // commit is required here;
        LibraryVariableStorage.Enqueue(FAJournalBatch.Name);
        FAJnlManagement.TemplateSelectionFromBatch(FAJournalBatch);

        // Verify: Verification has been done in FAPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateExistingLineTypeToItemOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        Vendor: Record Vendor;
    begin
        // Setup: Create Vendor, Create and Set up Fixed Asset, Create Purchase Order.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", FADepreciationBook."Depreciation Book Code");

        // Exercise & Verify: Change the Purchase Line Type to Item, the Error Message doesn't pop up.
        LibraryLowerPermissions.SetPurchDocsCreate();
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Modify(true);

        // Verify: Verify the Purchase Line Type is updated.
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunAcquireWizardForBankAccountWhenAcquisitionAllocationExists()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [FA Allocation]
        // [SCENARIO 202335] Acquire Fixed Asset with multiple FA Acquisition Allocations using Bank Account as balance Account
        Initialize();

        // [GIVEN] FA Posting Group "PG" having 3 allocations for Acquisition (20%,20%,60%) with different dimensions
        // [GIVEN] Fixed Asset "FA" with FA Posting Group "PG".
        DeleteFAJournalTemplateWithPageID(PAGE::"Fixed Asset Journal");
        CreateFASetupWithAcquisitionAllocations(FixedAsset);
        CreateFAJnlTemplateForFAAccWizard(FixedAsset."No.");
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();

        // [WHEN] Run Fixed Asset Acquire wizard for Bank Account
        RunFAAcquire(FixedAsset."No.", AcquisitionOptions::"Bank Account", LibraryERM.CreateBankAccountNo());

        // [THEN] 3 GL Entry with total amount 0.0 created after run Fixed Asset Acquire wizard
        VerifyGLEntryForFAAcquisitionWizardAutoPost(FixedAsset."No.");

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunAcquireWizardForVendorWhenAcquisitionAllocationExists()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [FA Allocation]
        // [SCENARIO 202335] Acquire Fixed Asset with multiple FA Acquisition Allocations using Vendor as balance Account
        Initialize();

        // [GIVEN] FA Posting Group "PG" having 3 allocations for Acquisition (20%,20%,60%) with different dimensions
        // [GIVEN] Fixed Asset "FA" with FA Posting Group "PG".
        DeleteFAJournalTemplateWithPageID(PAGE::"Fixed Asset Journal");
        CreateFASetupWithAcquisitionAllocations(FixedAsset);
        CreateFAJnlTemplateForFAAccWizard(FixedAsset."No.");
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();

        // [WHEN] Run Fixed Asset Acquire wizard for Vendor
        RunFAAcquire(FixedAsset."No.", AcquisitionOptions::Vendor, LibraryPurchase.CreateVendorNo());

        // [THEN] 3 GL Entry with total amount 0.0 created after run Fixed Asset Acquire wizard
        VerifyGLEntryForFAAcquisitionWizardAutoPost(FixedAsset."No.");

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunAcquireWizardForGLAccountWhenAcquisitionAllocationExists()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [FA Allocation]
        // [SCENARIO 202335] Acquire Fixed Asset with multiple FA Acquisition Allocations using G/L Account as balance Account
        Initialize();

        // [GIVEN] FA Posting Group "PG" having 3 allocations for Acquisition (20%,20%,60%) with different dimensions
        // [GIVEN] Fixed Asset "FA" with FA Posting Group "PG".
        DeleteFAJournalTemplateWithPageID(PAGE::"Fixed Asset Journal");
        CreateFASetupWithAcquisitionAllocations(FixedAsset);
        CreateFAJnlTemplateForFAAccWizard(FixedAsset."No.");
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();

        // [WHEN] Run Fixed Asset Acquire wizard for GL Account with direct posting
        RunFAAcquire(FixedAsset."No.", AcquisitionOptions::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [THEN] 3 GL Entry with total amount 0.0 created after run Fixed Asset Acquire wizard
        VerifyGLEntryForFAAcquisitionWizardAutoPost(FixedAsset."No.");

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateFAinBalAccountNoGenJournaLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        DefaultDeprBookCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 235899] "Gen. Journal Line"."Posting Group" contains value "FA Posting Group" from "FA Depreciation Book" after validation "Bal. Account No."
        Initialize();

        // [GIVEN] "FA Setup"."Default Depr. Book" = "DDB"
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DefaultDeprBookCode := DepreciationBook.Code;
        LibraryFixedAsset.UpdateFASetupDefaultDeprBook(DefaultDeprBookCode);

        // [GIVEN] "Fixed Asset" - "FA" and "FA Depreciation Book" - "FADB" with "FA Posting Group" = "FAPG"
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        CreateFAWithFADepreciationBook(FADepreciationBook, DepreciationBook.Code);

        // [GIVEN] "Gen. Journal Line" with "Bal. Account Type" = "Fixed Asset"
        GenJournalLine.Init();
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Fixed Asset";

        // [WHEN] Validate "Bal. Account No." with "FA" on Gen. Journal Line
        GenJournalLine.Validate("Bal. Account No.", FADepreciationBook."FA No.");

        // [THEN] "Gen. Journal Line"."Posting Group" = "FAPG"
        GenJournalLine.TestField("Posting Group", FADepreciationBook."FA Posting Group");

        // [THEN] "Gen. Journal Line"."Depreciation Book Code" = "DDB"
        GenJournalLine.TestField("Depreciation Book Code", DefaultDeprBookCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateFAinBalAccountNoGenJournaLineFASetupDefaultDeprBookIsBlank()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 235899] "Gen. Journal Line"."Posting Group" is blank after validation "Bal. Account No." when "FA Setup"."Default Depr. Book" = ''
        Initialize();

        // [GIVEN] "FA Setup"."Default Depr. Book" = ''
        LibraryFixedAsset.UpdateFASetupDefaultDeprBook('');

        // [GIVEN] "Fixed Asset" - "FA" and "FA Depreciation Book" - "FADB"
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        CreateFAWithFADeprBook(FADepreciationBook, DepreciationBook.Code);

        // [GIVEN] "Gen. Journal Line" with "Bal. Account Type" = "Fixed Asset" and "Depreciation Book Code" = ""
        GenJournalLine.Init();
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Fixed Asset";

        // [WHEN] Validate "Bal. Account No." with "FA" on Gen. Journal Line
        GenJournalLine.Validate("Bal. Account No.", FADepreciationBook."FA No.");

        // [THEN] "Gen. Journal Line"."Posting Group" = ""
        GenJournalLine.TestField("Posting Group", FADepreciationBook."FA Posting Group");

        // [THEN] "Gen. Journal Line"."Depreciation Book Code" = ""
        GenJournalLine.TestField("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateFAinBalAccountNoGenJournaLineWithDeprBookFASetupDefaultDeprBookIsBlank()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 235899] "Gen. Journal Line"."Posting Group" contains value "FA Posting Group" from "FA Depreciation Book" after validation "Bal. Account No." when "FA Setup"."Default Depr. Book" = ''
        Initialize();

        // [GIVEN] "FA Setup"."Default Depr. Book" = ''
        LibraryFixedAsset.UpdateFASetupDefaultDeprBook('');

        // [GIVEN] "Fixed Asset" - "FA" and "FA Depreciation Book" - "FADB" with "FA Posting Group" = "FAPG"
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        CreateFAWithFADeprBook(FADepreciationBook, DepreciationBook.Code);

        // [GIVEN] "Gen. Journal Line" with "Bal. Account Type" = "Fixed Asset" and "Depreciation Book Code" = "FADB"
        GenJournalLine.Init();
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Fixed Asset";
        GenJournalLine."Depreciation Book Code" := DepreciationBook.Code;

        // [WHEN] Validate "Bal. Account No." with "FA" on Gen. Journal Line
        GenJournalLine.Validate("Bal. Account No.", FADepreciationBook."FA No.");

        // [THEN] "Gen. Journal Line"."Posting Group" = "FAPG"
        GenJournalLine.TestField("Posting Group", FADepreciationBook."FA Posting Group");

        // [THEN] "Gen. Journal Line"."Depreciation Book Code" = "FADB"
        GenJournalLine.TestField("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFANoSeriesFAJournalSetup()
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FANoSeries: Code[20];
    begin
        // [FEATURE] [UT] [FA Journal Setup]
        // [SCENARIO 262718] Function "FA Journal Setup".GetFANoSeries returns "FA Journal Batch"."Posting No. Series" if "FA Journal Batch"."No. Series" <> "FA Journal Batch"."Posting No. Series"
        Initialize();

        // [GIVEN] FA Journal Batch with "No. Series" = "NoSeries1" and "Posting No. Series" = "NoSeries2"
        CreateFAJournalBatchWithNoSeries(
          FAJournalBatch,
          LibraryUtility.GenerateRandomCode20(FAJournalBatch.FieldNo("No. Series"), DATABASE::"FA Journal Batch"),
          LibraryUtility.GenerateRandomCode20(FAJournalBatch.FieldNo("Posting No. Series"), DATABASE::"FA Journal Batch"));

        // [GIVEN] FA Journal Line related to FA Journal Batch
        CreateFAJournalLineForFAJournalBatch(FAJournalLine, FAJournalBatch);

        // [WHEN] Invoke GetFANoSeries
        FANoSeries := FAJournalSetup.GetFANoSeries(FAJournalLine);

        // [THEN] Result = "NoSeries2"
        Assert.AreEqual(FAJournalBatch."Posting No. Series", FANoSeries, 'Wrong FA No Series');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmptyFANoSeriesFAJournalSetup()
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FANoSeries: Code[20];
    begin
        // [FEATURE] [UT] [FA Journal Setup]
        // [SCENARIO 262718] Function "FA Journal Setup".GetFANoSeries returns Empty value if "FA Journal Batch"."No. Series" = "FA Journal Batch"."Posting No. Series"
        Initialize();

        // [GIVEN] FA Journal Batch with "No. Series" = "Posting No. Series"
        FANoSeries := LibraryUtility.GenerateRandomCode20(FAJournalBatch.FieldNo("No. Series"), DATABASE::"FA Journal Batch");
        CreateFAJournalBatchWithNoSeries(FAJournalBatch, FANoSeries, FANoSeries);

        // [GIVEN] FA Journal Line related to FA Journal Batch
        CreateFAJournalLineForFAJournalBatch(FAJournalLine, FAJournalBatch);

        // [WHEN] Invoke GetFANoSeries
        FANoSeries := FAJournalSetup.GetFANoSeries(FAJournalLine);

        // [THEN] Result = ''
        Assert.AreEqual('', FANoSeries, 'Wrong FA No Series');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetGenNoSeriesFAJournalSetup()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        GenNoSeries: Code[20];
    begin
        // [FEATURE] [UT] [FA Journal Setup]
        // [SCENARIO 262718] Function "FA Journal Setup".GetGenNoSeries returns "Gen. Journal Batch"."Posting No Series" if "Gen. Journal Batch"."No. Series" <> "Gen. Journal Batch"."Posting No. Series"
        Initialize();

        // [GIVEN] Gen. Journal Batch with "No. Series" = "NoSeries1" and "Posting No. Series" = "NoSeries2"
        CreateGenJournalBatchWithNoSeries(
          GenJournalBatch,
          LibraryUtility.GenerateRandomCode20(GenJournalBatch.FieldNo("No. Series"), DATABASE::"Gen. Journal Batch"),
          LibraryUtility.GenerateRandomCode20(GenJournalBatch.FieldNo("Posting No. Series"), DATABASE::"Gen. Journal Batch"));

        // [GIVEN] Gen. Journal Line related to Gen. Journal Batch
        CreateGenJournalLineForGenJournalBatch(GenJournalLine, GenJournalBatch);

        // [WHEN] Invoke GenGenNoSeries
        GenNoSeries := FAJournalSetup.GetGenNoSeries(GenJournalLine);

        // [THEN] Result = "NoSeries2"
        Assert.AreEqual(GenJournalBatch."Posting No. Series", GenNoSeries, 'Wrong Gen. No Series');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmptyGenNoSeriesFAJournalSetup()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        GenNoSeries: Code[20];
    begin
        // [FEATURE] [UT] [FA Journal Setup]
        // [SCENARIO 262718] Function "FA Journal Setup".GetGenNoSeries returns Empty value if "Gen. Journal Batch"."No. Series" = "Gen. Journal Batch"."Posting No. Series"
        Initialize();

        // [GIVEN] Gen. Journal Batch with "No. Series" = "Posting No. Series"
        GenNoSeries := LibraryUtility.GenerateRandomCode20(GenJournalBatch.FieldNo("No. Series"), DATABASE::"Gen. Journal Batch");
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenNoSeries, GenNoSeries);

        // [GIVEN] Gen. Journal Line related to Gen. Journal Batch
        CreateGenJournalLineForGenJournalBatch(GenJournalLine, GenJournalBatch);

        // [WHEN] Invoke GenGenNoSeries
        GenNoSeries := FAJournalSetup.GetGenNoSeries(GenJournalLine);

        // [THEN] Result = ''
        Assert.AreEqual('', GenNoSeries, 'Wrong Gen. No Series');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetInsuranceNoSeriesFAJournalSetup()
    var
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        InsuranceJournalLine: Record "Insurance Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        InsuranceNoSeries: Code[20];
    begin
        // [FEATURE] [UT] [FA Journal Setup]
        // [SCENARIO 262718] Function "FA Journal Setup".GetInsuranceNoSeries returns "Insurance Journal Batch"."Posting No Series" if "Insurance Journal Batch"."No. Series" <> "Insurance Journal Batch"."Posting No. Series"
        Initialize();

        // [GIVEN] Insurance Journal Batch with "No. Series" = "NoSeries1" and "Posting No. Series" = "NoSeries2"
        CreateInsuranceJournalBatchWithNoSeries(
          InsuranceJournalBatch,
          LibraryUtility.GenerateRandomCode20(InsuranceJournalBatch.FieldNo("No. Series"), DATABASE::"Insurance Journal Batch"),
          LibraryUtility.GenerateRandomCode20(InsuranceJournalBatch.FieldNo("Posting No. Series"), DATABASE::"Insurance Journal Batch"));

        // [GIVEN] Insurance Journal Line related to Insurance Journal Batch
        CreateInsuranceJournalLineForInsuranceJournalBatch(InsuranceJournalLine, InsuranceJournalBatch);

        // [WHEN] Invoke GenInsuranceNoSeries
        InsuranceNoSeries := FAJournalSetup.GetInsuranceNoSeries(InsuranceJournalLine);

        // [THEN] Result = "NoSeries2"
        Assert.AreEqual(InsuranceJournalBatch."Posting No. Series", InsuranceNoSeries, 'Wrong Insurance No Series');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmptyInsuranceNoSeriesFAJournalSetup()
    var
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        InsuranceJournalLine: Record "Insurance Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        InsuranceNoSeries: Code[20];
    begin
        // [FEATURE] [UT] [FA Journal Setup]
        // [SCENARIO 262718] Function "FA Journal Setup".GetInsuranceNoSeries returns Empty value if "Insurance Journal Batch"."No. Series" = "Insurance Journal Batch"."Posting No. Series"
        Initialize();

        // [GIVEN] Insurance Journal Batch with "No. Series" = "Posting No. Series"
        InsuranceNoSeries :=
          LibraryUtility.GenerateRandomCode20(InsuranceJournalBatch.FieldNo("No. Series"), DATABASE::"Insurance Journal Batch");
        CreateInsuranceJournalBatchWithNoSeries(InsuranceJournalBatch, InsuranceNoSeries, InsuranceNoSeries);

        // [GIVEN] Insurance Journal Line related to Insurance Journal Batch
        CreateInsuranceJournalLineForInsuranceJournalBatch(InsuranceJournalLine, InsuranceJournalBatch);

        // [WHEN] Invoke GenInsuranceNoSeries
        InsuranceNoSeries := FAJournalSetup.GetInsuranceNoSeries(InsuranceJournalLine);

        // [THEN] Result = ''
        Assert.AreEqual('', InsuranceNoSeries, 'Wrong Insurance No Series');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalLineAmountCanNotHaveMoreDecimalPlacesThanInRoundingPrescision()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FAJournalLineAmount: Decimal;
    begin
        // [SCENARIO] Amount is rounded in FA Journal Line during the validation
        Initialize();

        // [GIVEN] Created FA Journal Line
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::" ", FAJournalLine."FA Posting Type"::"Acquisition Cost");

        // [GIVEN] Generated Amount with 1 decimal place more than in Amount Rounding Precision
        FAJournalLineAmount := LibraryERM.GetAmountRoundingPrecision() * 0.01 + LibraryRandom.RandIntInRange(3, 5);

        // [WHEN] Validate Amount for FAJournalLine
        FAJournalLine.Validate(Amount, FAJournalLineAmount);
        FAJournalLine.Modify(true);

        // [THEN] Generated amount is rounded
        Assert.AreNotEqual(FAJournalLine.Amount, FAJournalLineAmount, '');
        FAJournalLine.TestField(Amount, Round(FAJournalLineAmount, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalLineAmountCanNotHaveMoreDecimalPlacesThanInRoundingPrescisionForFAwithFCYVendor()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        Vendor: Record Vendor;
        FAJournalLineAmount: Decimal;
    begin
        // [SCENARIO] Amount is rounded in FA Journal Line during the validation
        Initialize();

        // [GIVEN] Created FA Journal Line For FA with Vendor with FCY
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateVendorWithCurrencyExchangeRate(Vendor);
        FixedAsset.Validate("Vendor No.", Vendor."No.");
        FixedAsset.Modify(true);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::" ", FAJournalLine."FA Posting Type"::"Acquisition Cost");

        // [GIVEN] Generated Amount with 1 decimal place more than in Amount Rounding Precision
        FAJournalLineAmount := LibraryERM.GetAmountRoundingPrecision() * 0.01 + LibraryRandom.RandIntInRange(3, 5);

        // [WHEN] Validate Amount for FAJournalLine
        FAJournalLine.Validate(Amount, FAJournalLineAmount);
        FAJournalLine.Modify(true);

        // [THEN] Generated amount is rounded
        Assert.AreNotEqual(FAJournalLine.Amount, FAJournalLineAmount, '');
        FAJournalLine.TestField(Amount, Round(FAJournalLineAmount, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [HandlerFunctions('ConfirmHandler')]
    [Test]
    procedure AcquireFixedAssetNoNotificationForBudgeted()
    var
        FixedAsset: Record "Fixed Asset";
        DefaultDepreciationBookCode: Code[10];
    begin
        // [FEATURE] [UI] [Notification]
        // [SCENARIO 389630] The fixed asset acquisition wizard is not shown for budgeted assets
        Initialize();

        // [GIVEN] A depreciation book
        DefaultDepreciationBookCode := GetDefaultDepreciationBook();

        // [WHEN] Create a new budgeted Fixed Asset in the Fixed Asset Card
        CreateFAAcquisitionSetupForWizard(FixedAsset, true);

        // [THEN] No notification pops up

        // Cleanup
        SetDefaultDepreciationBook(DefaultDepreciationBookCode);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler,FixedAssetGLJournalPageHandler')]
    [Scope('OnPrem')]
    procedure FAAcquisitionWizardHandleCurrency()
    var
        FixedAsset: Record "Fixed Asset";
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // [SCENARIO 389714] User can set Currency Code in Fixed Asset Acquision Wizard for Vendor and F/A Gen. Journal Line contains Currency Code
        Initialize();

        // [GIVEN] Vendor
        // [GIVEN] Currency "C" with exchange rate
        LibraryPurchase.CreateVendor(Vendor);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);

        // [GIVEN] Fixed Asset "FA" 
        DeleteFAJournalTemplateWithPageID(PAGE::"Fixed Asset Journal");
        CreateFASetupWithAcquisitionAllocations(FixedAsset);
        CreateFAJnlTemplateForFAAccWizard(FixedAsset."No.");
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Currency Code");

        // [WHEN] Run Fixed Asset Acquire wizard for Vendor
        RunFAAcquire(FixedAsset."No.", AcquisitionOptions::Vendor, Vendor."No.", CurrencyExchangeRate."Currency Code", true);

        // [THEN] There is F/A Gen. Journal Line with "Currency Code" = "C"
        // Verification is in FixedAssetGLJournalPageHandler

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler,FAGLJournalPageHandler')]
    [Scope('OnPrem')]
    procedure FAAcquisitionWizardUseJournalNameFromFAJOurnalNameByDepBookCode()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO 389699] FA Acquisition Wizard uses "FA Journal Setup" by "Depreciation Book Code"
        Initialize();

        // [GIVEN] Fixed Asset "FA" with Depreciation Book "DepBook"
        // [GIVEN] FA Journal Setup with "User ID" = '', "Depreciation Book" = 'DepBook' and "Gen. Journal Batch" = 'GJB'
        DeleteFAJournalTemplateWithPageID(PAGE::"Fixed Asset Journal");
        CreateFASetupWithAcquisitionAllocations(FixedAsset);
        CreateFAJnlTemplateForFAAccWizard(GenJournalBatch, FixedAsset."No.");
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.FindFirst();
        FAJournalSetup.Get(FADepreciationBook."Depreciation Book Code", '');
        FAJournalSetup."Gen. Jnl. Batch Name" := GenJournalBatch.Name;
        FAJournalSetup.Modify(true);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // [WHEN] Run Fixed Asset Acquire wizard for G/L Account
        RunFAAcquire(FADepreciationBook."FA No.", AcquisitionOptions::"G/L Account", LibraryERM.CreateGLAccountNo(),
            '', true);

        // [THEN] FA Acquisition wizard used Gen. Journal Batch from "FA Journal Setup"
        // Verification is in FixedAssetGLJournalPageHandler

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler,FAGLJournalPageHandler')]
    [Scope('OnPrem')]
    procedure FAAcquisitionWizardUseJournalNameFromFAJOurnalNameByDepBookCodeAndUserId()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO 389699] FA Acquisition Wizard uses "FA Journal Setup" by "Depreciation Book Code"
        Initialize();

        // [GIVEN] Fixed Asset "FA" with Depreciation Book "DepBook"
        // [GIVEN] FA Journal Setup with "User ID" = 'User1', "Depreciation Book" = 'DepBook' and "Gen. Journal Batch" = 'GJB'
        DeleteFAJournalTemplateWithPageID(PAGE::"Fixed Asset Journal");
        CreateFASetupWithAcquisitionAllocations(FixedAsset);
        CreateFAJnlTemplateForFAAccWizard(GenJournalBatch, FixedAsset."No.");
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.FindFirst();
        UpdateFAJournalSetupUserIDAndGenJournalBatch(FADepreciationBook."Depreciation Book Code", GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // [WHEN] Run Fixed Asset Acquire wizard for G/L Account
        RunFAAcquire(FADepreciationBook."FA No.", AcquisitionOptions::"G/L Account", LibraryERM.CreateGLAccountNo(),
            '', true);

        // [THEN] FA Acquisition wizard used Gen. Journal Batch from "FA Journal Setup"
        // Verification is in FixedAssetGLJournalPageHandler

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetGenJournalBatchNameReturnsAutogenName()
    var
        FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 389699] "Fixed Asset Acquisition Wizard".GetGenJournalBatchName() returns Gen. Journal Batch Name = 'AUTOMATIC'
        Assert.AreEqual(FixedAssetAcquisitionWizard.GetDefaultGenJournalBatchName(),
            FixedAssetAcquisitionWizard.GetGenJournalBatchName(''),
            'Wrong Gen. Journal Batch Name.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorSalvageValueForReclassificationFALedgerEntry();
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        Amount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 406530] Salvage Value error arrises when post FA Journal Line Acquisition Cost for reclassification and Salvage Value <> 0
        Initialize();

        // [GIVEN] Fixed asset
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(
            FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        // [GIVEN] Posted FA Journal Line with Amount = 100 and Salvage Value = -100
        Amount := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateFAJournalLine(
            FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
            FAJournalLine."Document Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLine.Validate("Salvage Value", -FAJournalLine.Amount);
        Amount := FAJournalLine.Amount;
        FAJournalLine.Modify();

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);


        // [WHEN] Post FA Journal Line with FA Reclassification Entry = true and Salvage Value = 0
        CreateFAJournalLine(
            FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
            FAJournalLine."Document Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLine.Validate(Amount, -Amount / 2);
        FAJournalLine.Validate("FA Reclassification Entry", true);
        FAJournalLine.Modify();
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] Error arrises
        Assert.ExpectedError(SalvageValueErr);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    procedure OpenFAGLJournalOptionWhenNoGenJnlLinesWithSameBatch()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetAcqWizardCod: Codeunit "Fixed Asset Acquisition Wizard";
        FixedAssetAcqWizardPage: TestPage "Fixed Asset Acquisition Wizard";
        GenJnlBatchName: Code[10];
    begin
        // [SCENARIO 414697] "Open the FA G/L journal" option state on FA Acquisition Wizard page when Gen. Journal Line for batch with the same name (as for acquisition) does not exist.
        Initialize();
        DeleteFAJournalTemplateWithPageID(Page::"Fixed Asset Journal");

        // [GIVEN] Fixed Asset "FA" with Depreciation Book "DB".
        // [GIVEN] FA Journal Setup with Depreciation Book = "DB" and Gen. Jnl. Batch Name "B1".
        CreateFAAcquisitionSetupForWizard(FixedAsset, false);
        GenJnlBatchName := FixedAssetAcqWizardCod.GetGenJournalBatchName(FixedAsset."No.");

        // [GIVEN] There are no Gen. Journal Lines for any batch with Name "B1".
        DeleteGenJnlLinesForGenJnlBatch(GenJnlBatchName);

        // [WHEN] Open FA Acquisition Wizard for "FA" and go to the final step with caption "That's it!".
        RunFAAcquisitionWizardToLastStep(FixedAssetAcqWizardPage, FixedAsset."No.", LibraryERM.CreateGLAccountNo());

        // [THEN] Option "Upon Finish, open the FA G/L journal." is enabled.
        Assert.IsTrue(FixedAssetAcqWizardPage.OpenFAGLJournal.Enabled(), '');

        // tear down
        FixedAssetAcqWizardPage.Close();
        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    procedure OpenFAGLJournalOptionWhenGenJnlLineWithSameBatchDifferentTemplate()
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetAcqWizardCod: Codeunit "Fixed Asset Acquisition Wizard";
        FixedAssetAcqWizardPage: TestPage "Fixed Asset Acquisition Wizard";
        GenJnlBatchName: Code[10];
    begin
        // [SCENARIO 414697] "Open the FA G/L journal" option state on FA Acquisition Wizard page when Gen. Journal Line for batch with the same name but different template exists.
        Initialize();
        DeleteFAJournalTemplateWithPageID(Page::"Fixed Asset Journal");

        // [GIVEN] Fixed Asset "FA" with Depreciation Book "DB".
        // [GIVEN] FA Journal Setup with Depreciation Book = "DB" and Gen. Jnl. Batch Name "B1".
        // [GIVEN] General Journal Batch "B1" has Journal Template Name "T1".
        CreateFAAcquisitionSetupForWizard(FixedAsset, false);
        GenJnlBatchName := FixedAssetAcqWizardCod.GetGenJournalBatchName(FixedAsset."No.");

        // [GIVEN] Gen. Journal Batch with Name "B1" and Journal Template Name "T1" does not have any Gen. Journal Lines.
        // [GIVEN] There is Gen. Journal Line for batch with Name "B1" and Journal Template Name "T2".
        DeleteGenJnlLinesForGenJnlBatch(GenJnlBatchName);
        CreateGenJournalBatchWithName(GenJournalBatch, GenJnlBatchName);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::Invoice,
            "Gen. Journal Account Type"::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Open FA Acquisition Wizard for "FA" and go to the final step with caption "That's it!".
        RunFAAcquisitionWizardToLastStep(FixedAssetAcqWizardPage, FixedAsset."No.", LibraryERM.CreateGLAccountNo());

        // [THEN] Option "Upon Finish, open the FA G/L journal." is enabled.
        Assert.IsTrue(FixedAssetAcqWizardPage.OpenFAGLJournal.Enabled(), '');

        // tear down
        FixedAssetAcqWizardPage.Close();
        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,RecallNotificationHandler,ConfirmHandler')]
    procedure OpenFAGLJournalOptionWhenGenJnlLineWithSameBatchAndTemplate()
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetAcqWizardCod: Codeunit "Fixed Asset Acquisition Wizard";
        FixedAssetAcqWizardPage: TestPage "Fixed Asset Acquisition Wizard";
        GenJnlBatchName: Code[10];
        GenJnlTemplateName: Code[10];
    begin
        // [SCENARIO 414697] "Open the FA G/L journal" option state on FA Acquisition Wizard page when Gen. Journal Line for acquisition other FA exists.
        Initialize();
        DeleteFAJournalTemplateWithPageID(Page::"Fixed Asset Journal");

        // [GIVEN] Fixed Asset "FA" with Depreciation Book "DB".
        // [GIVEN] FA Journal Setup with Depreciation Book = "DB" and Gen. Jnl. Batch Name "B1".
        // [GIVEN] General Journal Batch "B1" has Journal Template Name "T1".
        CreateFAAcquisitionSetupForWizard(FixedAsset, false);
        GenJnlBatchName := FixedAssetAcqWizardCod.GetGenJournalBatchName(FixedAsset."No.");
        GenJnlTemplateName := FixedAssetAcqWizardCod.SelectFATemplate();

        // [GIVEN] There is Gen. Journal Line for batch with Name "B1" and Journal Template Name "T1".
        DeleteGenJnlLinesForGenJnlBatch(GenJnlBatchName);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJnlTemplateName, GenJnlBatchName, "Gen. Journal Document Type"::Invoice,
            "Gen. Journal Account Type"::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Open FA Acquisition Wizard for "FA" and go to the final step with caption "That's it!".
        RunFAAcquisitionWizardToLastStep(FixedAssetAcqWizardPage, FixedAsset."No.", LibraryERM.CreateGLAccountNo());

        // [THEN] Option "Upon Finish, open the FA G/L journal." is disabled.
        Assert.IsFalse(FixedAssetAcqWizardPage.OpenFAGLJournal.Enabled(), '');

        // tear down
        FixedAssetAcqWizardPage.Close();
        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Fixed Assets Journal");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets Journal");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateFAPostingGroup();
        LibraryERMCountryData.CreateNewFiscalYear();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();

        LibrarySetupStorage.Save(DATABASE::"FA Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets Journal");
    end;

    local procedure AcquisitionCostBalanceAccount(FAPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        FAPostingGroup: Record "FA Posting Group";
    begin
        GLAccount.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        LibraryERM.FindGLAccount(GLAccount);
        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup.Validate("Acquisition Cost Bal. Acc.", GLAccount."No.");
        FAPostingGroup.Validate("Acq. Cost Acc. on Disposal", GLAccount."No.");
        FAPostingGroup.Modify(true);
    end;

    local procedure BalanceAccountFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CountFAAllocationEntries("Code": Code[20]; FAEntriesCreated: Integer)
    var
        FAAllocation: Record "FA Allocation";
    begin
        FAAllocation.SetRange(Code, Code);
        Assert.AreEqual(FAAllocation.Count, FAEntriesCreated, FAAllocationError);
    end;

    local procedure CopyFAJournalLine(var FAJournalLineOld: Record "FA Journal Line"; var FAJournalLine: Record "FA Journal Line")
    begin
        FAJournalLineOld := FAJournalLine;
        FAJournalLineOld.Insert();
    end;

    local procedure CreateAndPostAcqusitionLine(FADepreciationBook: Record "FA Depreciation Book"; var Amount: Decimal)
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLine(
          FAJournalLine, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        Amount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateAndPostDepreciationLine(FADepreciationBook: Record "FA Depreciation Book"; var Amount: Decimal)
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLine(
          FAJournalLine, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type"::Depreciation);
        UpdateAmountInFAJournalLine(FAJournalLine, Amount);
        Amount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateFAJnlLine(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch"; FANo: Code[20]; DepreciationBookCode: Code[10]; DocumentType: Enum "FA Journal Line Document Type"; FAPostingType: Enum "FA Journal Line FA Posting Type")
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document Type", DocumentType);
        FAJournalLine.Validate("Document No.", GetDocumentNo(FAJournalBatch));
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, LibraryRandom.RandIntInRange(1000, 2000));
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; DocumentType: Enum "FA Journal Line Document Type"; FAPostingType: Enum "FA Journal Line FA Posting Type")
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJnlLine(FAJournalLine, FAJournalBatch, FANo, DepreciationBookCode, DocumentType, FAPostingType);
    end;

    local procedure CreateFAWithComponent(var FixedAsset: Record "Fixed Asset"; var ComponentFixedAsset: Record "Fixed Asset"; var FADepreciationBook: Record "FA Depreciation Book"; var ComponentFADepreciationBook: Record "FA Depreciation Book")
    var
        MainAssetComponent: Record "Main Asset Component";
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateMainOrComponentFAWithEnviroment(FixedAsset, FADepreciationBook, DepreciationBook, '', true);
        CreateMainOrComponentFAWithEnviroment(ComponentFixedAsset, ComponentFADepreciationBook, DepreciationBook, FixedAsset."No.", false);
        LibraryFixedAsset.CreateMainAssetComponent(MainAssetComponent, FixedAsset."No.", ComponentFixedAsset."No.");
    end;

    local procedure CreateMainOrComponentFAWithEnviroment(var FixedAsset: Record "Fixed Asset"; var FADepreciationBook: Record "FA Depreciation Book"; var DepreciationBook: Record "Depreciation Book"; ParentFACode: Code[20]; IsMainAsset: Boolean)
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        FixedAsset.Validate("Component of Main Asset", ParentFACode);
        if IsMainAsset then
            FixedAsset."Main Asset/Component" := FixedAsset."Main Asset/Component"::"Main Asset"
        else
            FixedAsset."Main Asset/Component" := FixedAsset."Main Asset/Component"::Component;

        FixedAsset.Modify();

        if DepreciationBook.Code = '' then
            CreateJournalSetupDepreciation(DepreciationBook);

        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroupCode: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Depreciation Ending Date greater than Depreciation Starting Date, Using the Random Number for the Year.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateJournalSetupDepreciation(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Recurring, false);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalBatchWithName(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalBatchName: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Assets);
        GenJournalTemplate.Modify(true);
        GenJournalBatch.Init();
        GenJournalBatch.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.Validate(Name, GenJournalBatchName);
        GenJournalBatch.Insert(true);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        FAJournalBatch.Modify(true);
    end;

    local procedure CreateFAJnlTemplateForFAAccWizard(FANo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateFAJnlTemplateForFAAccWizard(GenJournalBatch, FANo);
    end;

    local procedure CreateFAJnlTemplateForFAAccWizard(var GenJournalBatch: Record "Gen. Journal Batch"; FANo: Code[20])
    var
        FAJournalTemplate: Record "FA Journal Template";
        GenJournalTemplate: Record "Gen. Journal Template";
        FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        FAJournalTemplate.Init();
        FAJournalTemplate.Validate(Name, GenJournalTemplate.Name);
        FAJournalTemplate.Validate("Page ID");
        FAJournalTemplate.Insert(true);
        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := FixedAssetAcquisitionWizard.GetGenJournalBatchName(FANo);// LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), Database::"Gen. Journal Batch");
        GenJournalBatch.SetupNewBatch();
        GenJournalBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch.Insert();
    end;

    [Normal]
    local procedure CreateFAAllocation(var FAAllocation: Record "FA Allocation"; FAPostingGroup: Code[20]): Integer
    var
        Counter: Integer;
    begin
        // Using Random Number Generator for creating the lines.
        for Counter := 1 to 1 + LibraryRandom.RandInt(3) do begin
            Clear(FAAllocation);
            LibraryFixedAsset.CreateFAAllocation(FAAllocation, FAPostingGroup, FAAllocation."Allocation Type"::Depreciation);
            UpdateFAAllocation(FAAllocation);
        end;
        exit(Counter);
    end;

    local procedure CreateFAGLJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"Fixed Asset",
          AccountNo, LibraryRandom.RandInt(1000));  // Using Random Number Generator for Amount.
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, FixedAssetNo, DepreciationBookCode);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateFAWithFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationBookCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBookCode);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
    end;

    local procedure CreateFAWithFADeprBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationBookCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBookCode);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", FADepreciationBook."Depreciation Book Code");
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetRange("Currency Code", '');
        FindVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // Using Random Code Generator for Vendor Invoice No.
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No."))));
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
        // Using the Random Number Generator for Quantity and Amount.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Depreciation Book Code", DepreciationBookCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
        CreateSalesHeader(SalesHeader);
        CreateSalesLine(SalesHeader, SalesLine, FANo, DepreciationBookCode);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("Currency Code", '');
        FindCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        // Using the Random Number Generator for Quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Depreciation Book Code", DepreciationBookCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using the Random Number Generator for Unit Price.
        SalesLine.Validate("Depr. until FA Posting Date", true);
        SalesLine.Validate("Unit of Measure", UnitOfMeasure.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateBlockedGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateDepreciationTableLine(var DepreciationTableLine: Record "Depreciation Table Line"; DepreciationTableHeaderCode: Code[10])
    begin
        LibraryFixedAsset.CreateDepreciationTableLine(DepreciationTableLine, DepreciationTableHeaderCode);
        // Using RANDOM value for Period Depreciation %.
        DepreciationTableLine.Validate("Period Depreciation %", 10 * LibraryRandom.RandDec(10, 2));
        DepreciationTableLine.Modify(true);
    end;

    local procedure CreateAndUpdateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    begin
        CreateFAGLJournal(GenJournalLine, FixedAssetNo, DepreciationBookCode, FAPostingType);
        UpdatePostingSetupGeneralLine(GenJournalLine);
        BalanceAccountFAGLJournalLine(GenJournalLine);
    end;

    local procedure CreateFAJournalRecurringBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange(Recurring, true);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("Posting No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        FAJournalBatch.Modify(true);
    end;

    local procedure CreateRecurringFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAJournalBatch: Record "FA Journal Batch")
    var
        RecurringFrequency: DateFormula;
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate(
          "Document No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(FAJournalLine.FieldNo("Document No."), DATABASE::"FA Journal Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"FA Journal Line", FAJournalLine.FieldNo("Document No."))));
        FAJournalLine.Validate("Recurring Method", FAJournalLine."Recurring Method"::"F Fixed");
        Evaluate(RecurringFrequency, '<' + Format(LibraryRandom.RandInt(5)) + 'D>'); // Using Random Number Generator for Days.
        FAJournalLine.Validate("Recurring Frequency", RecurringFrequency);
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, LibraryRandom.RandDec(1000, 2));  // Using Random Number Generator for Amount.
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFAJournalBatchWithNoSeries(var FAJournalBatch: Record "FA Journal Batch"; NoSeries: Code[20]; PostingNoSeries: Code[20])
    begin
        FAJournalBatch.Init();
        FAJournalBatch."Journal Template Name" := LibraryUtility.GenerateGUID();
        FAJournalBatch.Name := LibraryUtility.GenerateGUID();
        FAJournalBatch."No. Series" := NoSeries;
        FAJournalBatch."Posting No. Series" := PostingNoSeries;
        FAJournalBatch.Insert();
    end;

    local procedure CreateFAJournalLineForFAJournalBatch(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch")
    begin
        FAJournalLine.Init();
        FAJournalLine."Journal Template Name" := FAJournalBatch."Journal Template Name";
        FAJournalLine."Journal Batch Name" := FAJournalBatch.Name;
        FAJournalLine."Line No." := LibraryUtility.GetNewRecNo(FAJournalLine, FAJournalLine.FieldNo("Line No."));
        FAJournalLine.Insert();
    end;

    local procedure CreateGenJournalBatchWithNoSeries(var GenJournalBatch: Record "Gen. Journal Batch"; NoSeries: Code[20]; PostingNoSeries: Code[20])
    begin
        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := LibraryUtility.GenerateGUID();
        GenJournalBatch.Name := LibraryUtility.GenerateGUID();
        GenJournalBatch."No. Series" := NoSeries;
        GenJournalBatch."Posting No. Series" := PostingNoSeries;
        GenJournalBatch.Insert();
    end;

    local procedure CreateGenJournalLineForGenJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
    end;

    local procedure CreateInsuranceJournalBatchWithNoSeries(var InsuranceJournalBatch: Record "Insurance Journal Batch"; NoSeries: Code[20]; PostingNoSeries: Code[20])
    begin
        InsuranceJournalBatch.Init();
        InsuranceJournalBatch."Journal Template Name" := LibraryUtility.GenerateGUID();
        InsuranceJournalBatch.Name := LibraryUtility.GenerateGUID();
        InsuranceJournalBatch."No. Series" := NoSeries;
        InsuranceJournalBatch."Posting No. Series" := PostingNoSeries;
        InsuranceJournalBatch.Insert();
    end;

    local procedure CreateInsuranceJournalLineForInsuranceJournalBatch(var InsuranceJournalLine: Record "Insurance Journal Line"; InsuranceJournalBatch: Record "Insurance Journal Batch")
    begin
        InsuranceJournalLine.Init();
        InsuranceJournalLine."Journal Template Name" := InsuranceJournalBatch."Journal Template Name";
        InsuranceJournalLine."Journal Batch Name" := InsuranceJournalBatch.Name;
        InsuranceJournalLine."Line No." := LibraryUtility.GetNewRecNo(InsuranceJournalLine, InsuranceJournalLine.FieldNo("Line No."));
        InsuranceJournalLine.Insert();
    end;

    local procedure CreateFixedAssetWithAllocationAndJournalSetup(var FADepreciationBook: Record "FA Depreciation Book")
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FAAllocation: Record "FA Allocation";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        CreateFAAllocation(FAAllocation, FixedAsset."FA Posting Group");
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
    end;

    local procedure DeleteGeneralJournalLine(DepreciationBookCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.DeleteAll(true);
    end;

    local procedure DeleteGenJnlLinesForGenJnlBatch(GenJournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.DeleteAll();
    end;

    local procedure DeleteFAJournalTemplateWithPageID(PageID: Integer)
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange("Page ID", PageID);
        FAJournalTemplate.DeleteAll();
    end;

    local procedure FindFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindFirst();
    end;

    local procedure FindMaintenanceLedgerEntry(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; FANo: Code[20])
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        MaintenanceLedgerEntry.FindFirst();
    end;

    local procedure FindPostedInvoice(PreAssignedNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure FindVATPostingSetupWithZeroVAT(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
    end;

    local procedure GetDocumentNo(FAJournalBatch: Record "FA Journal Batch"): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        NoSeries.Get(FAJournalBatch."No. Series");
        exit(NoSeriesCodeunit.PeekNextNo(FAJournalBatch."No. Series"));
    end;

    local procedure ModifyRecurringOnTemplate(var FAJournalTemplate: Record "FA Journal Template")
    begin
        FAJournalTemplate.Validate(Recurring, true);
        FAJournalTemplate.Modify(true);
    end;

    local procedure ModifyInsuranceNo(var PurchaseLine: Record "Purchase Line")
    var
        Insurance: Record Insurance;
    begin
        LibraryFixedAsset.CreateInsurance(Insurance);
        PurchaseLine.Validate("Insurance No.", Insurance."No.");
        PurchaseLine.Modify(true);
    end;

    local procedure PostDepreciationWithDocumentNo(DepreciationBookCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.FindSet();
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        DocumentNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        repeat
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Validate(Description, FAJournalSetup."Gen. Jnl. Batch Name");
            GenJournalLine.Modify(true);
        until GenJournalLine.Next() = 0;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunCalculateDepreciation(No: Code[20]; DepreciationBookCode: Code[10]; BalAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
        NewPostingDate: Date;
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", No);

        NewPostingDate := WorkDate();
        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, NewPostingDate, false, 0, NewPostingDate, No, FixedAsset.Description, BalAccount);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure RunCopyFixedAsset(var FixedAsset: Record "Fixed Asset"; NoOfFixedAssetCopied: Integer)
    var
        CopyFixedAsset: Report "Copy Fixed Asset";
    begin
        Clear(CopyFixedAsset);
        CopyFixedAsset.SetFANo(FixedAsset."No.");
        CopyFixedAsset.InitializeRequest(FixedAsset."No.", NoOfFixedAssetCopied, '', true);
        CopyFixedAsset.UseRequestPage(false);
        CopyFixedAsset.Run();
    end;

    local procedure RunIndexFixedAssets(No: Code[20]; DepBookCode: Code[10]) IndexFigure: Integer
    var
        FixedAsset: Record "Fixed Asset";
        IndexFixedAssets: Report "Index Fixed Assets";
    begin
        Clear(IndexFixedAssets);
        FixedAsset.SetRange("No.", No);
        IndexFixedAssets.SetTableView(FixedAsset);

        // Using the Random Number Generator for New Index Figure.
        IndexFigure := LibraryRandom.RandInt(200);
        IndexFixedAssets.InitializeRequest(DepBookCode, IndexFigure, WorkDate(), WorkDate(), No, No, true);
        IndexFixedAssets.SetIndexAcquisitionCost(true);
        IndexFixedAssets.SetIndexDepreciation(true);
        IndexFixedAssets.UseRequestPage(false);
        IndexFixedAssets.Run();
    end;

    local procedure RunCopyDepreciationBook(No: Code[20]; DepreciationBookCode: Code[10]; DepreciationBookCode2: Code[10]; CopyAcquisitionCost: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CopyDepreciationBook: Report "Copy Depreciation Book";
    begin
        Clear(CopyDepreciationBook);
        FixedAsset.SetRange("No.", No);
        CopyDepreciationBook.SetTableView(FixedAsset);

        // Using the Random Number Generator for Date.
        CopyDepreciationBook.InitializeRequest(
          DepreciationBookCode, DepreciationBookCode2, WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(100)) + 'Y>', WorkDate()),
          No, FixedAsset.Description, false);
        CopyDepreciationBook.SetCopyAcquisitionCost(CopyAcquisitionCost);
        CopyDepreciationBook.UseRequestPage(false);
        CopyDepreciationBook.Run();
    end;

    local procedure RunFAAcquire(FANo: Code[20]; BalAccountType: Option; BalAccountNo: Code[20])
    begin
        RunFAAcquire(FANo, BalAccountType, BalAccountNo, '', false);
    end;

    local procedure RunFAAcquire(FANo: Code[20]; BalAccountType: Option; BalAccountNo: Code[20]; CurrencyCode: Code[20]; OpenFAGLJournal: Boolean)
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        FixedAssetAcquisitionWizard: TestPage "Fixed Asset Acquisition Wizard";
    begin
        TempGenJournalLine.SetRange("Account No.", FANo);
        FixedAssetAcquisitionWizard.Trap();
        Page.Run(Page::"Fixed Asset Acquisition Wizard", TempGenJournalLine);

        FixedAssetAcquisitionWizard.NextPage.Invoke();
        FixedAssetAcquisitionWizard.TypeOfAcquisitions.SetValue(BalAccountType);
        FixedAssetAcquisitionWizard.BalancingAccountNo.SetValue(BalAccountNo);
        if FixedAssetAcquisitionWizard.ExternalDocNo.Visible() then
            FixedAssetAcquisitionWizard.ExternalDocNo.SetValue(LibraryUtility.GenerateGUID());
        if FixedAssetAcquisitionWizard.AcquisitionCurrencyCode.Visible() and (CurrencyCode <> '') then
            FixedAssetAcquisitionWizard.AcquisitionCurrencyCode.SetValue(CurrencyCode);
        FixedAssetAcquisitionWizard.NextPage.Invoke();
        FixedAssetAcquisitionWizard.AcquisitionCost.SetValue(LibraryRandom.RandDec(1000, 2));
        FixedAssetAcquisitionWizard.AcquisitionDate.SetValue(WorkDate());
        FixedAssetAcquisitionWizard.NextPage.Invoke();
        FixedAssetAcquisitionWizard.PreviousPage.Invoke();
        FixedAssetAcquisitionWizard.NextPage.Invoke();
        FixedAssetAcquisitionWizard.OpenFAGLJournal.SetValue(OpenFAGLJournal);

        // COMMIT is enforced because the Finish action is invoking a codeunit and uses the return value.
        Commit();

        FixedAssetAcquisitionWizard.Finish.Invoke();
    end;

    local procedure RunFAAcquisitionWizardToLastStep(var FixedAssetAcqWizardPage: TestPage "Fixed Asset Acquisition Wizard"; FANo: Code[20]; BalAccountNo: Code[20])
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
    begin
        TempGenJournalLine.SetRange("Account No.", FANo);
        FixedAssetAcqWizardPage.Trap();
        Page.Run(Page::"Fixed Asset Acquisition Wizard", TempGenJournalLine);

        FixedAssetAcqWizardPage.NextPage.Invoke();
        FixedAssetAcqWizardPage.TypeOfAcquisitions.SetValue(AcquisitionOptions::"G/L Account");
        FixedAssetAcqWizardPage.BalancingAccountNo.SetValue(BalAccountNo);
        FixedAssetAcqWizardPage.NextPage.Invoke();
        FixedAssetAcqWizardPage.AcquisitionCost.SetValue(LibraryRandom.RandDecInRange(100, 200, 2));
        FixedAssetAcqWizardPage.AcquisitionDate.SetValue(WorkDate());
        FixedAssetAcqWizardPage.NextPage.Invoke();
    end;

    local procedure SetAllowCorrectionOfDisposal(DepreciationBookCode: Code[10])
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("Allow Correction of Disposal", true);
        DepreciationBook.Modify(true);
    end;

    local procedure SaveValuesOnTempFixedAsset(var FixedAssetOld: Record "Fixed Asset"; FixedAsset: Record "Fixed Asset")
    begin
        FixedAssetOld.Init();
        FixedAssetOld := FixedAsset;
        FixedAssetOld.Insert(true);
    end;

    local procedure IndexationAndIntegrationInBook(DepreciationBookCode: Code[10])
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Write-Down", true);
        DepreciationBook.Validate("G/L Integration - Appreciation", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("Allow Indexation", true);
        DepreciationBook.Validate("G/L Integration - Custom 1", true);
        DepreciationBook.Validate("G/L Integration - Custom 2", true);
        DepreciationBook.Validate("G/L Integration - Maintenance", true);
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", true);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateAcquisitionIntegration(DepreciationBookCode: Code[10]; GLIntegrationAcqCost: Boolean) OldGLIntegrationAcqCost: Boolean
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        OldGLIntegrationAcqCost := DepreciationBook."G/L Integration - Acq. Cost";
        DepreciationBook.Validate("G/L Integration - Acq. Cost", GLIntegrationAcqCost);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateAndPostWithSalvageValue(var FAJournalLine: Record "FA Journal Line"; AcqusitionAmount: Decimal; Amount: Decimal)
    begin
        FAJournalLine.Validate(Amount, AcqusitionAmount);
        FAJournalLine.Validate("Salvage Value", -Amount);
        FAJournalLine.Validate("Depr. Acquisition Cost", true);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure UpdateDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("Use FA Exch. Rate in Duplic.", true);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);

        // Using Random Number Generator for Default Exchange Rate.
        DepreciationBook.Validate("Default Exchange Rate", LibraryRandom.RandDec(10, 2));
        UpdatePartOfDuplicationList(DepreciationBook, true);
    end;

    local procedure UpdateDuplicateBookCode(var FAJournalLine: Record "FA Journal Line"; DepreciationBookCode: Code[10])
    begin
        FAJournalLine.Validate("Duplicate in Depreciation Book", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure UpdateFAAllocation(var FAAllocation: Record "FA Allocation")
    var
        GLAccount: Record "G/L Account";
    begin
        FAAllocation.SetRange(Code, FAAllocation.Code);
        FAAllocation.SetRange("Allocation Type", FAAllocation."Allocation Type");
        FAAllocation.FindSet();

        // Using Random Number Generator for Allocation Percent.
        repeat
            FAAllocation.Validate("Account No.", FindGLAccountWithNormalTypeVATSetup());
            FAAllocation.Validate("Allocation %", LibraryRandom.RandDec(20, 2));
            GLAccount.Next();
        until FAAllocation.Next() = 0;
        FAAllocation.Modify(true);
    end;

    local procedure UpdateFAJournalSetupUserIDAndGenJournalBatch(DepreciationBookCode: Code[10]; GenJournalBatchName: Code[10])
    var
        OldFAJournalSetup: Record "FA Journal Setup";
        NewFAJournalSetup: Record "FA Journal Setup";
    begin
        OldFAJournalSetup.Get(DepreciationBookCode, '');
        NewFAJournalSetup.TransferFields(OldFAJournalSetup);
        NewFAJournalSetup."User ID" := UserId();
        NewFAJournalSetup."Gen. Jnl. Batch Name" := GenJournalBatchName;
        NewFAJournalSetup.Insert();
        OldFAJournalSetup.Delete();
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
    begin
        FAJournalSetup2.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateFAJournalBatchPostingNoSeries(DepreciationBookCode: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        FAJournalBatch.Get(FAJournalSetup."FA Jnl. Template Name", FAJournalSetup."FA Jnl. Batch Name");
        FAJournalBatch."Posting No. Series" :=
          LibraryUtility.GenerateRandomCode20(FAJournalBatch.FieldNo("Posting No. Series"), DATABASE::"FA Journal Batch");
        FAJournalBatch.Modify();
    end;

    local procedure UpdatePartOfDuplicationList(var DepreciationBook: Record "Depreciation Book"; PartOfDuplicationList: Boolean)
    begin
        DepreciationBook.Validate("Part of Duplication List", PartOfDuplicationList);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateUseDuplicationList(var FAJournalLine: Record "FA Journal Line")
    begin
        FAJournalLine.Validate("Use Duplication List", true);
        FAJournalLine.Modify(true);
    end;

    local procedure UpdateWriteDownAmount(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    begin
        // Using the Random Number Generator for Amount.
        GenJournalLine.Validate(Amount, -(Amount - LibraryRandom.RandInt(10)));
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateAmountInFAJournalLine(var FAJournalLine: Record "FA Journal Line"; Amount: Decimal)
    begin
        // Using the Random Number Generator for Amount.
        FAJournalLine.Validate(Amount, -(Amount - LibraryRandom.RandInt(10)));
        FAJournalLine.Modify(true);
    end;

    local procedure UpdatePostingDateInFASetup()
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();

        // Using the Random function for Date.
        FASetup.Validate("Allow FA Posting From", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FASetup.Modify(true);
    end;

    local procedure UpdateWriteDownAccount(FAPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup.Validate("Write-Down Account", GLAccount."No.");
        FAPostingGroup.Validate("Write-Down Acc. on Disposal", GLAccount."No.");
        FAPostingGroup.Validate("Write-Down Bal. Acc. on Disp.", GLAccount."No.");
        FAPostingGroup.Validate("Write-Down Expense Acc.", GLAccount."No.");
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateAppreciationAccount(FAPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup.Validate("Appreciation Account", GLAccount."No.");
        FAPostingGroup.Validate("Appreciation Bal. Account", GLAccount."No.");
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateDepreciationCustomField(DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("Use Custom 1 Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", false);
        DepreciationBook.Validate("G/L Integration - Depreciation", false);
        DepreciationBook.Validate("G/L Integration - Custom 1", false);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateDepreciationEndingDate(var FADepreciationBook: Record "FA Depreciation Book")
    begin
        FADepreciationBook.Validate("Depr. Ending Date (Custom 1)", FADepreciationBook."Depreciation Ending Date");
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateDisposalAmount(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    begin
        // Using the Random Number Generator for Amount.
        GenJournalLine.Validate(Amount, -(Amount - LibraryRandom.RandInt(10)));
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateInsuranceBook(var FASetup: Record "FA Setup"; InsuranceDeprBook: Code[10])
    begin
        FASetup.Validate("Insurance Depr. Book", InsuranceDeprBook);
        FASetup.Modify(true);
    end;

    local procedure UpdateDefaultDepreciationBook(var FASetup: Record "FA Setup")
    begin
        FASetup.Validate("Default Depr. Book");
        FASetup.Modify(true);
    end;

    local procedure UpdateTemplateOnJournalSetup(var FAJournalSetup: Record "FA Journal Setup"; DepreciationBookCode: Code[10])
    begin
        FAJournalSetup.SetRange("Depreciation Book Code", DepreciationBookCode);
        FAJournalSetup.FindFirst();
        FAJournalSetup.Validate("FA Jnl. Template Name");
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdatePostingSetupGeneralLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetupWithZeroVAT(VATPostingSetup);
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateDepreciationYear(var FADepreciationBook: Record "FA Depreciation Book")
    begin
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(10));
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateDepreciationMethod(var FADepreciationBook: Record "FA Depreciation Book")
    begin
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"Declining-Balance 1");
        FADepreciationBook.Validate("Declining-Balance %", LibraryRandom.RandInt(50));
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateValuesOnFixedAsset(var FixedAssetOld: Record "Fixed Asset"; FixedAsset: Record "Fixed Asset"; Employee: Record Employee)
    var
        FASubclass: Record "FA Subclass";
        FALocation: Record "FA Location";
        Vendor: Record Vendor;
    begin
        // Update Responsible Employee, FA Class Code, FA Subclass Code, FA Location Code, Vendor No.,
        // Maintenance Vendor No. on Fixed Asset.
        LibraryFixedAsset.FindFASubclass(FASubclass);
        LibraryFixedAsset.FindFALocation(FALocation);
        FindVendor(Vendor);
        FixedAsset.Validate("Responsible Employee", Employee."No.");
        FixedAsset.Validate("FA Subclass Code", FASubclass.Code);
        FixedAsset.Validate("FA Location Code", FALocation.Code);
        FixedAsset.Validate("Vendor No.", Vendor."No.");
        FixedAsset.Validate("Maintenance Vendor No.", Vendor."No.");
        SaveValuesOnTempFixedAsset(FixedAssetOld, FixedAsset);
        FixedAsset.Modify(true);
    end;

    local procedure VerifyCancelFALedgerEntry(FALedgerEntry: Record "FA Ledger Entry")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", FALedgerEntry."FA No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("FA Error Entry No.", FALedgerEntry."Entry No.");
    end;

    local procedure VerifyValuesInFALedgerEntry(FAJournalLine: Record "FA Journal Line")
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FAJournalLine."FA No.");
        FALedgerEntry.FindLast();
        FALedgerEntry.TestField("Document Type", FAJournalLine."Document Type");
        FALedgerEntry.TestField("FA Posting Type", FAJournalLine."FA Posting Type".AsInteger());
        FALedgerEntry.TestField(Amount, FAJournalLine.Amount);
    end;

    local procedure VerifyPurchaseInvoiceLine(PurchaseHeader: Record "Purchase Header"; No: Code[20]; LineAmount: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("No.", No);
        PurchInvLine.TestField("Line Amount", LineAmount);
    end;

    local procedure VerifyAmountInFATransaction(FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        FindFALedgerEntry(FALedgerEntry, FANo, FAPostingType);
        GLEntry.Get(FALedgerEntry."G/L Entry No.");
        GLEntry.TestField(Amount, FALedgerEntry.Amount);
    end;

    local procedure VerifyAmountInFAEntry(FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FindFALedgerEntry(FALedgerEntry, FANo, FAPostingType);
        FALedgerEntry.FindLast();
        FALedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyAmountInFAJournalLine(FANo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalLine.SetRange("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.SetRange("FA No.", FANo);
        FAJournalLine.FindFirst();
        FAJournalLine.TestField(Amount, Amount);
    end;

    local procedure VerifyFixedAssetsIndexEntry(AccountNo: Code[20]; IndexFigure: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLineAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        FindFALedgerEntry(FALedgerEntry, AccountNo, FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        GenJournalLineAmount := FALedgerEntry.Amount - (FALedgerEntry.Amount * IndexFigure / 100);
        Assert.AreNearlyEqual(
          -GenJournalLineAmount, GenJournalLine.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(IndexAmountError, GenJournalLine.FieldCaption(Amount)));
    end;

    local procedure VerifyIndexationEntry(AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Index Entry", true);
    end;

    local procedure VerifyDisposalAmount(SalesLine: Record "Sales Line")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesLine."Document No.");
        SalesInvoiceHeader.FindFirst();
        FALedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        FALedgerEntry.SetRange(Amount, -SalesLine."Line Amount");
        FALedgerEntry.FindFirst();
    end;

    local procedure VerifyDepreciationBookAttached(FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.SetRange("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.FindFirst();
    end;

    local procedure VerifyDepreciationFALedger(FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField("Depreciation Book Code", DepreciationBookCode)
    end;

    local procedure VerifyMaintenanceEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        FindMaintenanceLedgerEntry(MaintenanceLedgerEntry, GenJournalLine."Account No.");
        MaintenanceLedgerEntry.TestField(Amount, GenJournalLine.Amount);
    end;

    local procedure VerifyMaintenanceEntryReversal(GenJournalLine: Record "Gen. Journal Line")
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        Amount: Decimal;
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", GenJournalLine."Account No.");
        MaintenanceLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        MaintenanceLedgerEntry.FindSet();
        repeat
            Amount += MaintenanceLedgerEntry.Amount;
        until MaintenanceLedgerEntry.Next() = 0;
        Assert.AreEqual(0, Amount, ReversalError);
    end;

    local procedure VerifyCoverageLedger(DocumentNo: Code[20]; FANo: Code[20]; InsuranceNo: Code[20])
    var
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
    begin
        InsCoverageLedgerEntry.SetRange("Document No.", DocumentNo);
        InsCoverageLedgerEntry.SetRange("FA No.", FANo);
        InsCoverageLedgerEntry.SetRange("Insurance No.", InsuranceNo);
        InsCoverageLedgerEntry.FindFirst();
    end;

    local procedure VerifyGeneralJournalLine(AccountNo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"Fixed Asset");
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.TestField(Amount, Amount);
    end;

    local procedure VerifyValuesOnFixedAsset(FixedAsset: Record "Fixed Asset")
    var
        FixedAsset2: Record "Fixed Asset";
    begin
        FixedAsset2.Get(FixedAsset."No.");
        FixedAsset2.TestField(Description, FixedAsset.Description);
        FixedAsset2.TestField("Responsible Employee", FixedAsset."Responsible Employee");
        FixedAsset2.TestField("FA Class Code", FixedAsset."FA Class Code");
        FixedAsset2.TestField("FA Subclass Code", FixedAsset."FA Subclass Code");
        FixedAsset2.TestField("FA Location Code", FixedAsset."FA Location Code");
        FixedAsset2.TestField("Vendor No.", FixedAsset."Vendor No.");
        FixedAsset2.TestField("Maintenance Vendor No.", FixedAsset."Maintenance Vendor No.");
    end;

    local procedure VerifyFAJournalTemplate(JnlSelected: Boolean; FAJnlTemplateName: Text[250]; FAJnlTemplateDescription: Text[250])
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        // Verify that new record has been created or not.
        FAJournalTemplate.FindFirst();
        FAJournalTemplate.TestField(Name, FAJnlTemplateName);
        FAJournalTemplate.TestField(Description, FAJnlTemplateDescription);
        Assert.IsTrue(JnlSelected, StrSubstNo(TemplateSelectionError, FAJournalTemplate.TableCaption()));
    end;

    local procedure VerifyFirstFAJournalTemplateCreation(RecurringJnl: Boolean; FAJnlTemplateName: Text[250]; FAJnlTemplateDescription: Text[250])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalTemplate: Record "FA Journal Template";
        FAJnlManagement: Codeunit FAJnlManagement;
        JnlSelected: Boolean;
    begin
        // Setup: Setup Demo Data and make Cost Journal Setup Blank.
        Initialize();

        // Exercise: Execute TemplateSelection function of FAJnlManagement.
        FAJournalTemplate.DeleteAll();
        FAJournalLine.DeleteAll();
        FAJnlManagement.TemplateSelection(FAJournalTemplate."Page ID", RecurringJnl, FAJournalLine, JnlSelected);

        // Verify: Verify that if no FA Journal Template is present in setup then a default setup will be created
        VerifyFAJournalTemplate(JnlSelected, FAJnlTemplateName, FAJnlTemplateDescription);
        Assert.RecordIsEmpty(FAJournalLine);

        // Tear down.
        FAJournalTemplate.Get(FAJnlTemplateName);
        FAJournalTemplate.Delete();
    end;

    local procedure GetDefaultDepreciationBook() DepreciationBookCode: Code[10]
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        DepreciationBookCode := FASetup."Default Depr. Book";
    end;

    local procedure SetDefaultDepreciationBook(DepreciationBookCode: Code[10])
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBookCode);
        FASetup.Modify(true);
    end;

    local procedure PostFAAcquisition(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book") FAJournalLineAmount: Decimal
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type"::Invoice, FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLineAmount := FAJournalLine.Amount;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateFADisposalJnlLine(var GenJournalLine: Record "Gen. Journal Line"; FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; FAJournalLineAmount: Decimal)
    begin
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateFAGLJournal(
          GenJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          GenJournalLine."FA Posting Type"::Disposal);
        BalanceAccountFAGLJournalLine(GenJournalLine);
        UpdateDisposalAmount(GenJournalLine, FAJournalLineAmount);
    end;

    local procedure InitSetup(var AllowPostingMainAsset: Boolean)
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        AllowPostingMainAsset := FASetup."Allow Posting to Main Assets";
        FASetup."Allow Posting to Main Assets" := true;
        FASetup.Modify();
    end;

    local procedure ResetSetup(AllowPostingMainAsset: Boolean)
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup."Allow Posting to Main Assets" := AllowPostingMainAsset;
        FASetup.Modify();
    end;

    local procedure CreateFAAcquisitionSetupForWizard(var FixedAsset: Record "Fixed Asset"; Budgeted: Boolean)
    var
        FASubclass: Record "FA Subclass";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFASubclass(FASubclass);
        FixedAsset.Validate("Budgeted Asset", Budgeted);
        FixedAsset.Modify(true);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        IndexationAndIntegrationInBook(DepreciationBook.Code);
        SetDefaultDepreciationBook(DepreciationBook.Code);

        FixedAssetCard.OpenEdit();
        FixedAssetCard.Filter.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.FAPostingGroup.SetValue(FixedAsset."FA Posting Group");
        FixedAssetCard.DepreciationBookCode.SetValue(FADepreciationBook."Depreciation Book Code");
        FixedAssetCard.DepreciationBook."No. of Depreciation Years".SetValue(LibraryRandom.RandIntInRange(2, 10));
    end;

    local procedure FindFAPostingGroup(var FAPostingGroup: Record "FA Posting Group"; FANo: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        Clear(FADepreciationBook);
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.FindFirst();
        FAPostingGroup.Get(FADepreciationBook."FA Posting Group");
    end;

    [HandlerFunctions('AcquireFANotificationHandler')]
    local procedure AcquireFixedAssetUsingAcquisitionWizardAutoPost(BalAccountType: Option; BalAccountNo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        DefaultDepreciationBookCode: Code[10];
    begin
        // [SCENARIO]
        // Go though the acquisiotion wizard, use vendor, post without opening G/L Journal Page
        Initialize();
        // Setup
        DefaultDepreciationBookCode := GetDefaultDepreciationBook();
        CreateFAAcquisitionSetupForWizard(FixedAsset, false);

        RunFAAcquire(FixedAsset."No.", BalAccountType, BalAccountNo);

        // Verify: Verify Amount on GLEntry is Correctly Populated.
        VerifyGLEntryForFAAcquisitionWizardAutoPost(FixedAsset."No.");

        // Teardown
        SetDefaultDepreciationBook(DefaultDepreciationBookCode);

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    local procedure VerifyGLEntryForFAAcquisitionWizardAutoPost(FixedAssetNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        GLEntryDocumentNo: Code[20];
    begin
        GLEntry2.SetRange("Source No.", FixedAssetNo);
        GLEntry2.FindFirst();
        GLEntryDocumentNo := GLEntry2."Document No.";

        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Document No.", GLEntryDocumentNo);
        Assert.RecordCount(GLEntry, 3);

        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0.0, GLEntry.Amount, 'The sum of the GLEntry amounts must be 0.');
    end;

    local procedure FindGLAccountWithNormalTypeVATSetup(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure FindCustomer(var Customer: Record Customer)
    begin
        // Filter Customer so that errors are not generated due to mandatory fields.
        Customer.SetFilter("Customer Posting Group", '<>''''');
        Customer.SetFilter("Gen. Bus. Posting Group", '<>''''');
        Customer.SetFilter("Payment Terms Code", '<>''''');
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        // For Complete Shipping Advice, partial shipments are disallowed, hence select Partial.
        Customer.SetRange("Shipping Advice", Customer."Shipping Advice"::Partial);
        Customer.FindFirst();
    end;

    local procedure FindVendor(var Vendor: Record Vendor)
    begin
        // Filter Vendor so that errors are not generated due to mandatory fields.
        Vendor.SetFilter("Vendor Posting Group", '<>''''');
        Vendor.SetFilter("Gen. Bus. Posting Group", '<>''''');
        Vendor.SetRange(Blocked, Vendor.Blocked::" ");
        Vendor.FindFirst();
    end;

    [Normal]
    local procedure CreateGenJournalLineForGenJournalLinesCreation(var TempGenJournalLine: Record "Gen. Journal Line" temporary; BalAccountNo: Code[20]; AccountNo: Code[20])
    var
        FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
        LibraryRandom: Codeunit "Library - Random";
    begin
        TempGenJournalLine.Reset();
        TempGenJournalLine.SetRange("Account No.", AccountNo);
        TempGenJournalLine.Amount := LibraryRandom.RandDec(1000, 2);
        TempGenJournalLine."Posting Date" := WorkDate();
        TempGenJournalLine."Bal. Account Type" := TempGenJournalLine."Bal. Account Type"::Vendor;
        TempGenJournalLine."Bal. Account No." := BalAccountNo;
        TempGenJournalLine."External Document No." := ExtDocNoTok;
        TempGenJournalLine."Journal Template Name" := FixedAssetAcquisitionWizard.SelectFATemplate();
        TempGenJournalLine."Journal Batch Name" := FixedAssetAcquisitionWizard.GetAutogenJournalBatch();
        TempGenJournalLine."Document Type" := TempGenJournalLine."Document Type"::Invoice;
        TempGenJournalLine."Account No." := AccountNo;
        TempGenJournalLine."Account Type" := TempGenJournalLine."Account Type"::"Fixed Asset";
        TempGenJournalLine."FA Posting Type" := TempGenJournalLine."FA Posting Type"::"Acquisition Cost";
    end;

    local procedure CreateFASetupWithAcquisitionAllocations(var FixedAsset: Record "Fixed Asset"): Code[20]
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        CreateFAAcquisitionSetupForWizard(FixedAsset, false);
        FindFAPostingGroup(FAPostingGroup, FixedAsset."No.");
        CreateFAAllocationAcquisitions(FAPostingGroup.Code, FAPostingGroup."Acquisition Cost Account");
        exit(FAPostingGroup."Acquisition Cost Account");
    end;

    local procedure CreateFAAllocationAcquisitions(FAPostingGroup: Code[20]; FAAccount: Code[20])
    var
        AllocPerCent: Integer;
    begin
        AllocPerCent := LibraryRandom.RandIntInRange(10, 40);
        CreateOneFAAllocationAcquisition(FAPostingGroup, FAAccount, AllocPerCent);
        CreateOneFAAllocationAcquisition(FAPostingGroup, FAAccount, AllocPerCent);
        CreateOneFAAllocationAcquisition(FAPostingGroup, FAAccount, 100 - 2 * AllocPerCent);
    end;

    local procedure CreateOneFAAllocationAcquisition(FAPostingGroup: Code[20]; FAAccount: Code[20]; AllocPerCent: Integer)
    var
        FAAllocation: Record "FA Allocation";
    begin
        LibraryFixedAsset.CreateFAAllocation(FAAllocation, FAPostingGroup, FAAllocation."Allocation Type"::Acquisition);
        FAAllocation.Validate("Allocation %", AllocPerCent);
        FAAllocation.Validate("Account No.", FAAccount);
        FAAllocation.Modify(true);
    end;

    local procedure CreateVendorWithCurrencyExchangeRate(var Vendor: Record Vendor): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Vendor.Modify(true);
        exit(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount"); // Value required for calculating Currency factor.
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency."Invoice Rounding Precision" := LibraryERM.GetAmountRoundingPrecision();
        Currency.Modify();

        CreateCurrencyExchangeRate(
          CurrencyExchangeRate, Currency.Code, CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code, WorkDate());
    end;

    local procedure CreateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; StartingDate: Date)
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(50, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(CompletionStatsGenJnlQst, Question);
        Reply := false;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure AcquireFANotificationHandler(var AcquireFANotification: Notification): Boolean
    begin
        exit(true);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var AcquireFANotification: Notification): Boolean
    begin
        exit(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FAPageHandler(var FixedAssetJournal: TestPage "Fixed Asset Journal")
    var
        FAJnlBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(FAJnlBatchName);

        // Verify: FA Journal Page open with the same value of created batch when open through batches.
        Assert.AreEqual(FixedAssetJournal.CurrentJnlBatchName.Value, FAJnlBatchName, StrSubstNo(ExpectedBatchError, FAJnlBatchName));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetGLJournalPageHandler(var FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal")
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Text;
    begin
        CurrencyCode := LibraryVariableStorage.DequeueText();

        GenJournalLine.SetRange("Account Type", FixedAssetGLJournal."Account Type".AsInteger());
        GenJournalLine.SetRange("Account No.", FixedAssetGLJournal."Account No.".Value);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Currency Code", CurrencyCode);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FAGLJournalPageHandler(var FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatchName: Code[10];
    begin
        GenJournalBatchName := LibraryVariableStorage.DequeueText();

        GenJournalLine.SetRange("Account Type", FixedAssetGLJournal."Account Type".AsInteger());
        GenJournalLine.SetRange("Account No.", FixedAssetGLJournal."Account No.".Value);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Journal Batch Name", GenJournalBatchName);
    end;
}

