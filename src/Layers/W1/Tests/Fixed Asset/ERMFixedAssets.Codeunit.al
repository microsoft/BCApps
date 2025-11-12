codeunit 134451 "ERM Fixed Assets"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        isInitialized: Boolean;
        UnknownError: Label 'Unknown error.';
        DateConfirmMessage: Label 'Posting Date %1 is different from Work Date %2.Do you want to continue?';
        NoOfYears: Integer;
        DepreciationBookCode2: Code[10];
        FixedAssetNo2: Code[20];
        GenJournalTemplateName: Code[10];
        GenJournalBatchName: Code[10];
        FAJournalTemplateName: Code[10];
        FAJournalBatchName: Code[10];
        FADepreciationMethod: Enum "FA Depreciation Method";
        FADepreciationCreateError: Label 'FA Depreciation Book must be created for Fixed Asset No. %1';
        FADepreciationNotCreateError: Label 'FA Depreciation Book must not be created for Fixed Asset No. %1';
        NoOfYearsError: Label 'Total Number of Period No.must be equal to %1. Current value is %2.';
        ErrorText: Label 'Error Message Must be same.';
        MinNoOfYearError: Label 'You must specify No. of Years.';
        MaxNoOfYearError: Label 'No. of Years must be less than 200.';
        BlankCopyFromFANoError: Label 'You must specify a number in the Copy from %1 %2 field.', Comment = '%1: TABLECAPTION(Fixed Asset); %2: Field(No.)';
        BlankFirstFANoError: Label 'You must specify a number in First FA No. field or use the FA No. Series.';
        CopyFixedAssetError: Label '%1 must be equal to %2.';
        WrongDeprDaysErr: Label 'Wrong number of depreciation days.';
        CompletionStatsMsg: Label 'The depreciation has been calculated.\\No journal lines were created.';
        CompletionStatsFAJnlQst: Label 'The depreciation has been calculated.\\1 fixed asset journal lines were created.\\Do you want to open the Fixed Asset Journal window?', Comment = 'The depreciation has been calculated.\\5 fixed asset journal lines were created.\\Do you want to open the Fixed Asset Journal window?';
        CompletionStatsTok: Label 'The depreciation has been calculated.';
        MixedDerpFAUntilPostingDateErr: Label 'The value in the Depr. Until FA Posting Date field must be the same on lines for the same fixed asset %1.';
        CannotPostSameMultipleFAWhenDeprBookValueZeroErr: Label 'You cannot select the Depr. Until FA Posting Date check box because there is no previous acquisition entry for fixed asset %1.', Comment = '%1 - Fixed Asset No.';
        FirstMustBeAcquisitionCostErr: Label 'The first entry must be an Acquisition Cost';
        OnlyOneDefaultDeprBookErr: Label 'Only one fixed asset depreciation book can be marked as the default book';
        AcquireNotificationMsg: Label 'You are ready to acquire the fixed asset.';
        DepreciationBookCodeMustMatchErr: Label 'Depreciation Book Code must match.';
        FixedAssetCountError: Label 'New fixed assets were not created.';
        DimValueError: Label 'Dimension values are not equal on the copied Fixed Asset.';

    [Test]
    [Scope('OnPrem')]
    procedure PostFAJournalWithMultipleLine()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
    begin
        // Test the Posting of Fixed Asset Journal with multiple lines.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group and Create multiple FA Journal Line for
        // Acquisition Cost,Write-Down,Custom 1,Custom 2.
        Initialize();
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);
        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify FA Ledger Entry exist.
        VerifyFALedgerEntry(FixedAsset."No.", DepreciationBook.Code);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostCalculateDepreciation()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
    begin
        // Test the Posting of Calculated Depreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group, Create and Post multiple FA Journal Line for Acquisition Cost,
        // Write-Down,Custom 1,Custom 2 .
        Initialize();
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 2.Exercise: Calculate Depreciation and Change "Document No." in FA Journal line and Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, false);

        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        // 3.Verify: Verify FA Ledger Entry for Depreciation.
        VerifyDepreciationFALedger(FixedAsset."No.", DepreciationBook.Code);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcMessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateDepreciationWithNoJournalOutput()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Test Calculating Depreciation without generating any journal lines.

        // 1.Setup: Create Depreciation Book and FA Posting Group
        Initialize();
        CreateFixedAssetSetup(DepreciationBook);

        // 2.Exercise: Calculate Depreciation with a non-existent fixed asset number to ensure no journal output
        LibraryLowerPermissions.SetO365FAView();
        RunCalculateDepreciation('DUMMY', DepreciationBook.Code, false);

        // 3.Verify: In DepreciationCalcMessageHandler, verify that no journal output is generated and that correct message is shown.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvIntegrationError()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test the Posting of Sales Invoice without Integration- Disposal on Depreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group. Create Customer, Create Sales Invoice with dimension.
        Initialize();
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, FixedAsset."No.", DepreciationBook.Code);

        // 2.Exercise: Post Sales Invoice.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3.Verify: Verify "Depreciation Book" Integration- Disposal Error.
        Assert.ExpectedTestFieldError(DepreciationBook.FieldCaption("G/L Integration - Disposal"), Format(true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvWithUseDuplicationList()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        DepreciationBook2: Record "Depreciation Book";
    begin
        // Test the Posting of Sales Invoice with two lines Fixed Assets with "Use Duplication List".

        // 1.Setup: Create Fixed Asset,2 Depreciation Books, FA Posting Group, Create Customer, Create Sales Invoice with 2 lines.
        Initialize();

        CreateDeprBookPartOfDuplicationList(DepreciationBook);
        CreateDeprBookPartOfDuplicationList(DepreciationBook2);

        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook2.Code, FixedAsset."FA Posting Group");

        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        CreatePurchLine(PurchLine2, PurchHeader, FixedAsset."No.", DepreciationBook2.Code);

        // 2.Exercise: Post Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // 3.Verify: Verify FA Ledger Entry.
        VerifyFALedgerEntry(FixedAsset."No.", DepreciationBook2.Code);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvFixedAssetAppreciationAsFirstEntry()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Appreciation]
        Initialize();

        // [GIVEN] Fixed Asset, where FA posting group has "Appreciation Account" = 'AA'
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook."G/L Integration - Appreciation" := true;
        DepreciationBook.Modify();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");

        // [GIVEN] Purchase invoice, where Vendor has non zero VAT group
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        // [GIVEN] Purchase line, where Type = "Fixed Asset", "FA Posting Type"=Appreciation, "Direct Unit Cost"= 100
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);
        PurchLine.Modify();

        // [WHEN] Post the document
        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        // [THEN] Error message: "The first entry must be an Acquisition Cost"
        Assert.ExpectedError(FirstMustBeAcquisitionCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvFixedAssetAppreciationAsSecondEntry()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GLEntry: Record "G/L Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FAPostingGroup: Record "FA Posting Group";
        VATEntry: Record "VAT Entry";
        PurchInvLine: Record "Purch. Inv. Line";
        AppreciationAmount: Decimal;
        InvoiceDocNo: Code[20];
    begin
        // [FEATURE] [Appreciation]
        Initialize();

        // [GIVEN] Fixed Asset, where FA posting group has "Appreciation Account" = 'AA'
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook."G/L Integration - Appreciation" := true;
        DepreciationBook.Modify();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");

        // [GIVEN] Posted Purchase invoice, where Fixed Asset is acquired
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::"Acquisition Cost");
        PurchLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Purchase Invoice for Appreciation
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        // [GIVEN] Purchase line, where Type = "Fixed Asset", "FA Posting Type"=Appreciation, "Direct Unit Cost"= 100
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);
        PurchLine.Modify();
        AppreciationAmount := Round(PurchLine."Direct Unit Cost" * PurchLine.Quantity, 0.01);

        // [WHEN] Post the document
        InvoiceDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Document is posted, VAT Entry is posted, Base = 100.
        VATEntry.FindLast();
        VATEntry.TestField(Base, AppreciationAmount);
        // [THEN] FA Ledger Entry, where "FA Posting Type"=Appreciation, Amount = 100.
        FALedgerEntry.FindLast();
        FALedgerEntry.TestField("FA Posting Type", FALedgerEntry."FA Posting Type"::Appreciation);
        FALedgerEntry.TestField(Amount, AppreciationAmount);
        // [THEN] G/L Entry, where G/L Account = 'AA', Amount = 100.
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        GLEntry.SetRange("G/L Account No.", FAPostingGroup.GetAppreciationAccount());
        GLEntry.FindLast();
        GLEntry.TestField(Amount, AppreciationAmount);
        // [THEN] Posted Invoice Line, where "FA Posting Type" = Appreciation
        PurchInvLine.SetRange("Document No.", InvoiceDocNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("FA Posting Type", PurchInvLine."FA Posting Type"::Appreciation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoFixedAssetAppreciation()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GLEntry: Record "G/L Entry";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FAPostingGroup: Record "FA Posting Group";
        AppreciationAmount: Decimal;
        CrMemoDocNo: Code[20];
    begin
        // [FEATURE] [Appreciation] [Credit Memo]
        Initialize();

        // [GIVEN] Fixed Asset, where FA posting group has "Appreciation Account" = 'AA'
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook."G/L Integration - Appreciation" := true;
        DepreciationBook.Modify();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");

        // [GIVEN] Posted Purchase invoice, where Fixed Asset is acquired
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::"Acquisition Cost");
        PurchLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Purchase Invoice for Appreciation
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        // [GIVEN] Purchase line, where Type = "Fixed Asset", "FA Posting Type"=Appreciation, "Direct Unit Cost"= 100
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);
        PurchLine.Modify();
        AppreciationAmount := Round(PurchLine."Direct Unit Cost" * PurchLine.Quantity, 0.01);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Purchase Credit Memo for Appreciation
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", PurchHeader."Buy-from Vendor No.");
        // [GIVEN] Purchase line, where Type = "Fixed Asset", "FA Posting Type"=Appreciation, "Direct Unit Cost"= 100
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Direct Unit Cost", AppreciationAmount);
        PurchLine.Modify();

        // [WHEN] Post the document
        CrMemoDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Document is posted, VAT Entry is posted, Base = 100.
        // [THEN] FA Ledger Entry, where "FA Posting Type"=Appreciation, Amount = -100.
        FALedgerEntry.FindLast();
        FALedgerEntry.TestField("FA Posting Type", FALedgerEntry."FA Posting Type"::Appreciation);
        FALedgerEntry.TestField(Amount, -AppreciationAmount);
        // [THEN] G/L Entry, where G/L Account = 'AA', Amount = -100.
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        GLEntry.SetRange("G/L Account No.", FAPostingGroup.GetAppreciationAccount());
        GLEntry.FindLast();
        GLEntry.TestField(Amount, -AppreciationAmount);
        // [THEN] Posted Credit memo line, where "FA Posting Type" is 'Appreciation'
        PurchCrMemoLine.SetRange("Document No.", CrMemoDocNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField("FA Posting Type", PurchCrMemoLine."FA Posting Type"::Appreciation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchLineFAPostingTypeAppreciation()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Appreciation] [UT]
        Initialize();
        // [GIVEN] Purchase line with Fixed Asset
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        // [GIVEN] FA Posting Group has "Appreciation Account", where "VAT Prod. Posting Group" = 'V' and "Gen. Prod. Posting Group" = 'G'
        CreateAppreciationAccount(PurchHeader, FixedAsset."FA Posting Group", GLAccount);

        // [WHEN] validate "FA Posting Type" as 'Appreciation'
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);

        // [THEN] Purchase lines, where "VAT Prod. Posting Group" = 'V' and "Gen. Prod. Posting Group" = 'G'
        PurchLine.TestField("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        PurchLine.TestField("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithFixedAsset()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        SalesHeader: Record "Sales Header";
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
        DocumentNo: Code[20];
    begin
        // Test the Posting of Sales Invoice with Fixed Asset.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group, Create and Post multiple FA Journal Line for
        // Acquisition Cost,Write-Down,Custom 1,Custom 2. Create Customer, Create Sales Invoice with dimension.
        Initialize();
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.CalcFields("Acquisition Cost");

        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, false);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Invoice, FixedAsset."No.", DepreciationBook.Code);
        ModifyIntegrationInBook(DepreciationBook);

        // 2.Exercise: Post Sales Invoice.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ExecuteUIHandler();

        // 3.Verify: Verify FA Ledger Entry for Sales Invoice.
        VerifySalesFALedgerEntry(
          DocumentNo, FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost",
          -FADepreciationBook."Acquisition Cost", 0, FADepreciationBook."Acquisition Cost");
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAllowCorrError()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        SalesHeader: Record "Sales Header";
    begin
        // Test the Posting of Sales Order without Allow Correction of Disposal on Depreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group, Create and Post multiple FA Journal Line for Acquisition Cost,
        // Write-Down,Custom 1,Custom 2. Create Customer, Create and post Sales Invoice with dimension and create Sales Order.
        Initialize();
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, false);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);
        ModifyIntegrationInBook(DepreciationBook);

        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Invoice, FixedAsset."No.", DepreciationBook.Code);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ExecuteUIHandler();

        Clear(SalesHeader);
        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Order, FixedAsset."No.", DepreciationBook.Code);

        // 2.Exercise: Post Sales Order.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3.Verify: Verify "Depreciation Book" Allow Correction of Disposal Error.
        Assert.ExpectedTestFieldError(DepreciationBook.FieldCaption("Allow Correction of Disposal"), '');
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProceedsOnDisposalAndGainLoss()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        SalesHeader: Record "Sales Header";
        FALedgerEntry: Record "FA Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Test the Posting of Sales Order with Fixed Asset.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group, Create and Post multiple FA Journal Line for Acquisition Cost,
        // Write-Down,Custom 1,Custom 2. Create Customer, Create and post Sales Invoice with dimension.
        Initialize();
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);
        UpdateAllowCorrectionInBook(DepreciationBook);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, false);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);
        ModifyIntegrationInBook(DepreciationBook);

        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Invoice, FixedAsset."No.", DepreciationBook.Code);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2.Exercise: Create and Post Sales Order.
        Clear(SalesHeader);
        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Order, FixedAsset."No.", DepreciationBook.Code);
        SalesHeader.CalcFields(Amount);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ExecuteUIHandler();

        // 3.Verify: Verify "Proceeds on Disposal" and "Gain/Loss" FA Ledger Entry for Sales Order.
        VerifySalesFALedgerEntry(
          DocumentNo, FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal",
          -SalesHeader.Amount, 0, SalesHeader.Amount);
        VerifySalesFALedgerEntry(
          DocumentNo, FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Gain/Loss",
          -SalesHeader.Amount, 0, SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AcquisitionCostNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Acquisition Cost.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFixedAssetSetup(DepreciationBook);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateFAJournalBatch(FAJournalBatch);

        // Random Number Generator for Amount.
        Amount := LibraryRandom.RandDec(10000, 2);

        // 2.Exercise: Post a Line in FA Journal with FA Posting Type Acquisition Cost.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.",
          DepreciationBook.Code, Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAcquisitionFALedgerEntry(FixedAsset."No.", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DepreciationNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Depreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize();

        // Post a Line in FA Journal with FA Posting Type Depreciation.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::Depreciation, -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::Depreciation, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteDownNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Write-Down.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize();

        // Post a Line in FA Journal with FA Posting Type Write-Down.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::"Write-Down", -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::"Write-Down", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppreciationNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Appreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize();

        // Post a Line in FA Journal with FA Posting Type Appreciation.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::Appreciation, 1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::Appreciation, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Custom1NoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Custom 1.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize();

        // Post a Line in FA Journal with FA Posting Type Custom 1.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::"Custom 1", -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::"Custom 1", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Custom2NoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Custom 2.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize();

        // Post a Line in FA Journal with FA Posting Type Custom 2.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::"Custom 2", -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::"Custom 2", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalvageValueNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Salvage Value.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize();

        // Post a Line in FA Journal with FA Posting Type Salvage Value.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::"Salvage Value", -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::"Salvage Value", Amount);
    end;

    local procedure CreateFixedAssetWithoutIntegration(FAJnlLineFAPostingType: Enum "FA Journal Line FA Posting Type"; AmountSign: Integer; var FAJournalLine: Record "FA Journal Line") Amount: Decimal
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalBatch: Record "FA Journal Batch";
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFixedAssetSetup(DepreciationBook);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateFAJournalBatch(FAJournalBatch);

        // Random Number Generator for Amount.
        Amount := LibraryRandom.RandDec(10000, 2);

        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.",
          DepreciationBook.Code, Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        Amount := Round(Amount / 4) * AmountSign;  // Division by 4 is required to calculate Amount less than the original Amount."

        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJnlLineFAPostingType, FixedAsset."No.", DepreciationBook.Code, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize();
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::Maintenance, -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal with FA Posting Type Maintenance.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in Maintenance Ledger Entry correctly.
        VerifyMaintenanceLedgerEntry(FANo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalDisposal()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFixedAssetSetup(DepreciationBook);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        SetupPartialIntegrationInBook(DepreciationBook);

        CreateFAJournalBatch(FAJournalBatch);
        Amount := LibraryRandom.RandDec(10000, 2);

        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.",
          DepreciationBook.Code, Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 2.Exercise: Post a Line in FA Journal with FA Posting Type Disposal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::Disposal, FixedAsset."No.",
          DepreciationBook.Code, -Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal", -Amount);
    end;

    [Test]
    [HandlerFunctions('FADepreciationBooksHandler')]
    [Scope('OnPrem')]
    procedure CreateFADepreciationBooksError()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        // Test error occurs on running Create FA Depreciation Books report without Depreciation Book Code and Copy From FA No.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Create FA Depreciation Books Report with Depreciation Book Code as blank and Copy From FA No as blank.
        // Set Depreciation Book and Copy From FA No. into FA Depreciation Books Handler.
        LibraryLowerPermissions.SetO365FAView();
        asserterror RunCreateFADepreciationBooks(FixedAsset, '', '');

        // 3. Verify: Verify error occurs on running Create FA Depreciation Books Report without Depreciation Book Code and Copy From FA No.
        Assert.ExpectedErrorCannotFind(Database::"Depreciation Book");
    end;

    [Test]
    [HandlerFunctions('FADepreciationBooksHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetInactiveTrue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Test FA Depreciation Book must not be created for Inactive Fixed Asset.

        // 1. Setup: Create Fixed Asset with Inactive as True. Create Depreciation Book.
        Initialize();
        CreateInactiveFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        Commit();  // COMMIT needs before running batch report.

        // 2. Exercise: Run Create FA Depreciation Books Report with Copy From FA No as blank.
        // Set Depreciation Book and Copy From FA No. into FA Depreciation Books Handler.
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAView();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        RunCreateFADepreciationBooks(FixedAsset, DepreciationBook.Code, '');

        // 3. Verify: Verify FA Depreciation Book must not be created for Inactive Fixed Asset.
        Assert.IsFalse(
          FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code), StrSubstNo(FADepreciationNotCreateError, FixedAsset."No."));
    end;

    [Test]
    [HandlerFunctions('FADepreciationBooksHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetInactiveFalse()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Test FA Depreciation Book must be created for active Fixed Asset.

        // 1. Setup: Create Fixed Asset with Inactive as False. Create Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        Commit();  // COMMIT needs before running batch report.

        // 2. Exercise: Run Create FA Depreciation Books Report with Copy From FA No as blank.
        // Set Depreciation Book and Copy From FA No. into FA Depreciation Books Handler.
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAView();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        RunCreateFADepreciationBooks(FixedAsset, DepreciationBook.Code, '');

        // 3. Verify: Verify FA Depreciation Book must be created for active Fixed Asset.
        Assert.IsTrue(
          FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code), StrSubstNo(FADepreciationCreateError, FixedAsset."No."));
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure MinNoOfYearInDepreciationTable()
    var
        DepreciationTableHeader: Record "Depreciation Table Header";
        DepreciationTableCard: TestPage "Depreciation Table Card";
    begin
        // Create Depreciation Table with Period Length, Run create Sum of Digits Table Report with
        // No. of Years is equal to 0 and check Error for Minimum No. of Year.

        // 1.Setup: Create Depreciation Table with Period Length.
        Initialize();
        CreateDepreciationTable(DepreciationTableHeader);
        NoOfYears := 0;

        // 2.Exercise: Run Create Sum of Digits Table Report.
        LibraryLowerPermissions.SetO365FASetup();
        Commit();  // COMMIT is important here before use Depreciation Table Card Page.
        DepreciationTableCard.OpenView();
        DepreciationTableCard.FILTER.SetFilter(Code, DepreciationTableHeader.Code);
        asserterror DepreciationTableCard.CreateSumOfDigitsTable.Invoke();

        // 3.Verify: Check Error for Minimum No. of Year.
        Assert.IsTrue(StrPos(GetLastErrorText, MinNoOfYearError) > 0, ErrorText);
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfYearInDepreciationTable()
    var
        DepreciationTableHeader: Record "Depreciation Table Header";
        DepreciationTableLine: Record "Depreciation Table Line";
        DepreciationTableCard: TestPage "Depreciation Table Card";
    begin
        // Create Depreciation Table with Period Length, Run create Sum of Digits Table Report with
        // No. of Years and Verify Depreciation Table Line.

        // 1.Setup: Create Depreciation Table with Period Length.
        Initialize();
        CreateDepreciationTable(DepreciationTableHeader);
        NoOfYears := LibraryRandom.RandInt(200);

        // 2.Exercise: Run Create Sum of Digits Table Report.
        LibraryLowerPermissions.SetO365FASetup();
        Commit();  // COMMIT is important here before use Depreciation Table Card Page.
        DepreciationTableCard.OpenView();
        DepreciationTableCard.FILTER.SetFilter(Code, DepreciationTableHeader.Code);
        DepreciationTableCard.CreateSumOfDigitsTable.Invoke();

        // 3.Verify: Check total number of Period No. for Depreciation Table.
        DepreciationTableLine.SetRange("Depreciation Table Code", DepreciationTableCard.Code.Value);
        Assert.AreEqual(DepreciationTableLine.Count, NoOfYears, StrSubstNo(NoOfYearsError, NoOfYears, DepreciationTableLine.Count));
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure MaxNoOfYearInDepreciationTable()
    var
        DepreciationTableHeader: Record "Depreciation Table Header";
        DepreciationTableCard: TestPage "Depreciation Table Card";
    begin
        // Create Depreciation Table with Period Length, Run create Sum of Digits Table Report with
        // No. of Years is equal to 201 and check Error for maximum No. of Year.

        // 1.Setup: Create Depreciation Table with Period Length.
        Initialize();
        CreateDepreciationTable(DepreciationTableHeader);
        NoOfYears := LibraryRandom.RandInt(10) + 200;  // 200 maximum No. of Year.

        // 2.Exercise: Run Create Sum of Digits Table Report.
        LibraryLowerPermissions.SetO365FASetup();
        Commit();  // COMMIT is important here before use Depreciation Table Card Page.
        DepreciationTableCard.OpenView();
        DepreciationTableCard.FILTER.SetFilter(Code, DepreciationTableHeader.Code);
        asserterror DepreciationTableCard.CreateSumOfDigitsTable.Invoke();

        // 3.Verify: Check Error for Maximum No. of Year.
        Assert.IsTrue(StrPos(GetLastErrorText, MaxNoOfYearError) > 0, ErrorText);
    end;

    [HandlerFunctions('GenJournalBatchesHandler,FAJournalSetupGenBatchHandler')]
    [Scope('OnPrem')]
    procedure GenBatchNameOnFAJnlSetupLookUp()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        DepreciationBook: Record "Depreciation Book";
    begin
        // Verify program opens General Journal batch on clicking lookup on 'Gen. Jnl. Batch Name' on FA Journal Setup.

        // 1.Setup: Find Depreciation Book,FA Journal Template and FA Journal Batch.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // Variables 'GenJournalTemplateName' and 'GenJournalBatchName' are declared Global as they are used in Handler method.
        GenJournalTemplateName := GenJournalTemplate.Name;
        GenJournalBatchName := GenJournalBatch.Name;

        // 2.Exercise: From Depreciation Book open FA Journal Setup page.
        // LibraryLowerPermissions.SetO365FAView(); TODO: Remove the comment when you fix the test
        OpenFAJnlSetupFromDepBook(DepreciationBook.Code);

        // 3.Verify: Verification is done in 'GenJournalBatchesHandler' handler method.
    end;

    [HandlerFunctions('FAJournalSetupFABatchHandler,FAJournalBatchesHandler')]
    [Scope('OnPrem')]
    procedure FABatchNameOnFAJnlSetupLookUp()
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        DepreciationBook: Record "Depreciation Book";
    begin
        // Verify program populates FA Journal Batch Name list when lookup is invoked on 'FA Journal Batch Name' field on FA Journal Setup.

        // 1.Setup: Find Depreciation Book,FA Journal Template and FA Journal Batch.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.FindFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);

        // Variables 'FAJournalTemplateName' and 'FAJournalBatchName' are declared Global as they are used in Handler method.
        FAJournalTemplateName := FAJournalTemplate.Name;
        FAJournalBatchName := FAJournalBatch.Name;

        // 2.Exercise: From Depreciation Book open FA Journal Setup page.
        // LibraryLowerPermissions.SetO365FAView(); TODO: Remove the comment when you fix the test
        OpenFAJnlSetupFromDepBook(DepreciationBook.Code);

        // 3.Verify: Verification is done in 'FAJournalBatchesHandler' handler method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFixedAssetsWithCopyFromFANoBlankError()
    var
        FixedAsset: Record "Fixed Asset";
        NoOfFixedAssetCopied: Integer;
    begin
        // Test error occurs on running Copy Fixed Asset Report with Copy From FA No. as blank.

        // 1. Setup: Create New Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        NoOfFixedAssetCopied := LibraryRandom.RandInt(10);  // Using Random Generator to Copy the Number of Fixed Asset.

        // 2. Exercise:  Run Copy Fixed Asset Report with Copy From FA No. as blank.
        LibraryLowerPermissions.SetO365FAView();
        asserterror RunCopyFixedAsset(FixedAsset."No.", '', NoOfFixedAssetCopied, '', false);

        // 3. Verify: Verify error occurs on running Copy Fixed Asset Report with Copy From FA No. as blank.
        Assert.AreEqual(StrSubstNo(BlankCopyFromFANoError, FixedAsset.TableCaption(), FixedAsset.FieldCaption("No.")), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFixedAssetsWithFirstFANoBlankError()
    var
        FixedAsset: Record "Fixed Asset";
        NoOfFixedAssetCopied: Integer;
    begin
        // Test error occurs on running Copy Fixed Asset Report with First FA No. as blank and FA No. Series as false.

        // 1. Setup: Create New Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        NoOfFixedAssetCopied := LibraryRandom.RandInt(10);  // Using Random Generator to Copy the Number of Fixed Asset.

        // 2. Exercise: Run Copy Fixed Asset Report with First FA No. as blank and FA No. Series as false.
        LibraryLowerPermissions.SetO365FAView();
        asserterror RunCopyFixedAsset(FixedAsset."No.", FixedAsset."No.", NoOfFixedAssetCopied, '', false);

        // 3. Verify: Verify error occurs on running Copy Fixed Asset Report with First FA No. as blank and FA No. Series as false.
        Assert.AreEqual(StrSubstNo(BlankFirstFANoError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFixedAssetsWithFANoSeriesFalse()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetCount: Integer;
        NoOfFixedAssetCopied: Integer;
    begin
        // Test the Copy Fixed Assets functionality with Use FA No. Series as false.

        // 1.Setup: Create Fixed Asset
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAssetCount := FixedAsset.Count();
        NoOfFixedAssetCopied := LibraryRandom.RandInt(10);  // Using Random Generator to Copy the Number of Fixed Asset.

        // 2.Exercise: Run the Copy Fixed Assets with Use FA No. Series as false.
        LibraryLowerPermissions.SetO365FAEdit();
        RunCopyFixedAsset(FixedAsset."No.", FixedAsset."No.", NoOfFixedAssetCopied, GenerateFixedAssetNo(), false);

        // 3.Verify: New count of Fixed Asset should be Equal to total of Previous Fixed Asset count and No of fixed assets copied.
        Assert.AreEqual(FixedAssetCount + NoOfFixedAssetCopied, FixedAsset.Count, CopyFixedAssetError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntriesUsingStatistics()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FixedAssetStatistics: TestPage "Fixed Asset Statistics";
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        // Test to verify that FA Ledger entries page gets opened by invoking drill down on Fixed Asset Statistics page.

        // 1.Setup: Create Fixed Asset and Depreciation Book and set newly created Depreciation Book Code on Fixed Asset Card.
        // Open Fixed Asset Statistics page from Fixed Asset card.
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard.DepreciationBook."Depreciation Book Code".SetValue(DepreciationBook.Code);
        FixedAssetStatistics.Trap();
        FixedAssetCard.Statistics.Invoke();

        // 2.Exercise: Invoke drill down on Book Value field of Fixed Asset Statistics page.
        LibraryLowerPermissions.SetO365FAView();
        FALedgerEntries.Trap();
        FixedAssetStatistics."Book Value".DrillDown();

        // 3.Verify: Verify that FA Ledger Entries page gets opened.
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure WriteDownDepreciationTypeEnabled()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [SCENARIO 361344] Depreciation started from the next day of the last operation with "Depreciation Type" = TRUE.
        Initialize();

        // [GIVEN] Posted Acq. Cost and Write-Down operations with "FA Posting Date" = WORKDATE.
        CreateFixedAssetWithSetup(FixedAsset, DepreciationBook);
        CreateAndPostAcqCostAndWriteDownFAJnlLines(FixedAsset."No.", DepreciationBook.Code);
        // [GIVEN] Set "Depreciation Type" TRUE in FA Posting Type Setup for Write-Down
        SetDeprTypeFAPostingTypeSetupWriteDown(DepreciationBook.Code);

        // [WHEN] Calculate depreciation with "FA Posting Date" = WorkDate() + 1. Post FA Journal.
        LibraryLowerPermissions.SetO365FAEdit();
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, false);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        // [THEN] Number of depreciation days in FA Ledger Entry equals 1
        VerifyFALedgEntryDeprDays(FixedAsset."No.", DepreciationBook.Code, 1);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure WriteDownDepreciationTypeDisabled()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [SCENARIO 361344] Depreciation started from the same day of the last operation with "Depreciation Type" = FALSE.
        Initialize();

        // [GIVEN] Posted Acq. Cost and Write-Down operations with "FA Posting Date" = WORKDATE.
        CreateFixedAssetWithSetup(FixedAsset, DepreciationBook);
        CreateAndPostAcqCostAndWriteDownFAJnlLines(FixedAsset."No.", DepreciationBook.Code);
        // [GIVEN] Set "Depreciation Type" FALSE in FA Posting Type Setup for Write-Down
        ResetDeprTypeFAPostingTypeSetupWriteDown(DepreciationBook.Code);

        // [WHEN] Calculate depreciation with "FA Posting Date" = WorkDate() + 1. Post FA Journal.
        LibraryLowerPermissions.SetO365FAEdit();
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, false);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        // [THEN] Number of depreciation days in FA Ledger Entry equals 2
        VerifyFALedgEntryDeprDays(FixedAsset."No.", DepreciationBook.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJnlLineDimDuplicationListNoGLIntegration()
    var
        FAJnlLine: Record "FA Journal Line";
        ShortcutDimValueCode: array[2] of Code[20];
        FANo: Code[20];
        DeprBookCode: Code[10];
        DuplListDeprBookCode: Code[10];
    begin
        // [SCENARIO 363280] Post FA Jnl. Line with dimensions and "Use Duplication List"
        Initialize();
        // [GIVEN] Fixed Asset with two Depreciation Books "DB1", "DB2"
        // [GIVEN] "DB1" and "DB2": "G/L Integration - Acq. Cost" = FALSE, "DB2": "Part of Duplication List" = TRUE
        CreateFAAndDuplListSetup(FANo, DeprBookCode, DuplListDeprBookCode, false);
        // [GIVEN] FA Jnl. Line for "DB1", "Use Duplication List" = TRUE, Shortcut Dimension Codes = "DimVal1" and "DimVal2"
        CreateFAJnlLineWithDimensionsAndUseDuplicationList(FAJnlLine, ShortcutDimValueCode, FANo, DeprBookCode);
        // [WHEN] Post FA Jnl. Line
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryFixedAsset.PostFAJournalLine(FAJnlLine);
        // [THEN] FA Jnl. Line for "DB2" created: "Shortcut Dimension 1 Code" = "DimVal1", "Shortcut Dimension 2 Code" = "DimVal2"
        VerifyFAJnlLineDimUseDuplicationList(DuplListDeprBookCode, ShortcutDimValueCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineDimDuplicationListGLIntegration()
    var
        GenJnlLine: Record "Gen. Journal Line";
        ShortcutDimValueCode: array[2] of Code[20];
        FANo: Code[20];
        DeprBookCode: Code[10];
        DuplListDeprBookCode: Code[10];
    begin
        // [SCENARIO 363280] Post Gen. Jnl. Line with dimensions and "Use Duplication List"
        Initialize();
        // [GIVEN] Fixed Asset with two Depreciation Books "DB1", "DB2"
        // [GIVEN] "DB1" and "DB2": "G/L Integration - Acq. Cost" = TRUE, "DB2": "Part of Duplication List" = TRUE
        CreateFAAndDuplListSetup(FANo, DeprBookCode, DuplListDeprBookCode, true);
        // [GIVEN] Gen. Jnl. Line for "DB1", "Use Duplication List" = TRUE, Shortcut Dimension Codes = "DimVal1" and "DimVal2"
        CreateGenJnlLineWithDimensionsAndUseDuplicationList(GenJnlLine, ShortcutDimValueCode, FANo, DeprBookCode);
        // [WHEN] Post Gen. Jnl. Line
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        // [THEN] Gen. Jnl. Line for "DB2" created: "Shortcut Dimension 1 Code" = "DimVal1", "Shortcut Dimension 2 Code" = "DimVal2"
        VerifyGenJnlLineDimUseDuplicationList(DuplListDeprBookCode, ShortcutDimValueCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADepreciationBookAfterPostFAJournal()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        DocumentNo: Code[20];
    begin
        // Test to validate Amount on FA Depreciation Book After Post FA Journal Line.

        // Setup: Create FA Depreciation Book, Fixed Asset, FA Journal Line and post FA Journal Line.
        Initialize();
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);

        // Exercise: Create and Post FA Journal Line.
        LibraryLowerPermissions.SetO365FAEdit();
        DocumentNo := CreateAndPostFAJournalLine(FixedAsset."No.", DepreciationBook.Code);

        // Verify: Verify FA Depreciation Book.
        VerifyFADepreciationBook(FixedAsset."No.", DocumentNo, DepreciationBook.Code);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLEntryVATEntryLinkForVATNetDisposal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DummyGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [G/L Entry - VAT Entry Link] [VAT on Net Disposal Entries]
        // [SCENARIO 376686] System creates "G/L Entry - VAT Entry Link" for GLEntry with VAT Amount <> 0 in case of posting Fixed Asset with "VAT on Net Disposal Entries" = TRUE.
        Initialize();
        CreateFixedAssetSetup(DepreciationBook);
        UpdateDeprBookVATNetDisposal(DepreciationBook);
        ModifyIntegrationInBook(DepreciationBook);

        // [GIVEN] Fixed Asset, where Depreciation Book has "VAT on Net Disposal Entries" = TRUE.
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");

        // [GIVEN] Post Fixed Asset Acquisition Cost.
        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] Post Fixed Asset Depreciation.
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, false);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        // [WHEN] Sell Fixed Asset. System creates: GLEntry "A" with VAT Amount <> 0; VATEntry "B".
        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Invoice, FixedAsset."No.", DepreciationBook.Code);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "G/L Entry - VAT Entry Link" has record with "G/L Entry No." = A, "VAT Entry No." = B
        FindSalesInvoiceVATEntry(VATEntry, DocumentNo);
        FindSalesInvoiceGLEntryWithVATAmount(GLEntry, DocumentNo, GetVATEntryAmount(VATEntry));
        DummyGLEntryVATEntryLink.SetRange("G/L Entry No.", GLEntry."Entry No.");
        DummyGLEntryVATEntryLink.SetRange("VAT Entry No.", VATEntry."Entry No.");
        Assert.RecordIsNotEmpty(DummyGLEntryVATEntryLink);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceVendorNoIsPreserved()
    var
        FixedAsset: Record "Fixed Asset";
        Vendor: Record Vendor;
        MaintenanceRegistration: TestPage "Maintenance Registration";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        Initialize();
        // [GIVEN] Fixed Asset, with a Vendor as 'Maintenance Vendor'
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryPurchase.CreateVendor(Vendor);

        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."Maintenance Vendor No.".SetValue(Vendor."No.");

        // [WHEN] Open Maintenance Registration Page and add a Service Date and a random Comment
        LibraryLowerPermissions.SetO365FAEdit();
        MaintenanceRegistration.Trap();
        FixedAssetCard."Maintenance &Registration".Invoke();
        MaintenanceRegistration."Service Date".SetValue(WorkDate());
        MaintenanceRegistration.Comment.SetValue(CopyStr(LibraryUtility.GenerateRandomText(5), 1, 5));

        // [THEN] The Maintenance Vendor should be preserved from Fixed Asset's Card
        MaintenanceRegistration."Maintenance Vendor No.".AssertEquals(FixedAssetCard."Maintenance Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingFAClassChangesSubclass()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclassWithNoClass: Record "FA Subclass";
        FAClass1: Record "FA Class";
        FASubclassWithFAClass1Parrent: Record "FA Subclass";
        FAClass2: Record "FA Class";
        FASubclassWithFAClass2Parrent: Record "FA Subclass";
    begin
        // Setup Subclasses with different classes
        FASetupClassesAndSubclasses(FAClass1, FASubclassWithFAClass1Parrent, FAClass2, FASubclassWithFAClass2Parrent, FASubclassWithNoClass);

        LibraryLowerPermissions.SetO365FAEdit();

        // [GIVEN] Blank Subclass
        // [WHEN] Setting a Class
        FixedAsset.Validate("FA Class Code", FAClass1.Code);
        // [THEN] Subclass remains blank
        Assert.AreEqual('', FixedAsset."FA Subclass Code", 'Subclass remains blank');

        // [GIVEN] Subclass belonging to a differant class
        FixedAsset."FA Subclass Code" := FASubclassWithFAClass2Parrent.Code;
        // [WHEN] Setting Class
        FixedAsset.Validate("FA Class Code", FAClass1.Code);
        // [THEN] Subclass gets cleared
        Assert.AreEqual('', FixedAsset."FA Subclass Code", 'Subclass gets cleared');

        // [GIVEN] Subclass belonging to the same class
        FixedAsset."FA Subclass Code" := FASubclassWithFAClass1Parrent.Code;
        // [WHEN] Setting Class
        FixedAsset.Validate("FA Class Code", FAClass1.Code);
        // [THEN] Subclass remaines unchanged
        Assert.AreEqual(FASubclassWithFAClass1Parrent.Code, FixedAsset."FA Subclass Code", 'Subclass remaines unchanged 1');

        // [GIVEN] Subclass belonging to all classes
        FixedAsset."FA Subclass Code" := FASubclassWithNoClass.Code;
        // [WHEN] Setting Class
        FixedAsset.Validate("FA Class Code", FAClass1.Code);
        // [THEN] Subclass remaines unchanged
        Assert.AreEqual(FASubclassWithNoClass.Code, FixedAsset."FA Subclass Code", 'Subclass remaines unchanged 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingFASubclassChangesClass()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclassWithNoClass: Record "FA Subclass";
        FAClass1: Record "FA Class";
        FASubclassWithFAClass1Parrent: Record "FA Subclass";
        FAClass2: Record "FA Class";
        FASubclassWithFAClass2Parrent: Record "FA Subclass";
    begin
        // Setup Subclasses with different classes
        FASetupClassesAndSubclasses(FAClass1, FASubclassWithFAClass1Parrent, FAClass2, FASubclassWithFAClass2Parrent, FASubclassWithNoClass);

        LibraryLowerPermissions.SetO365FAEdit();

        // [GIVEN] Blank Class and a Subclass with class
        // [WHEN] Setting a Subclass
        FixedAsset.Validate("FA Subclass Code", FASubclassWithFAClass1Parrent.Code);
        // [THEN] Class get the value of belonging Subclass
        Assert.AreEqual(FAClass1.Code, FixedAsset."FA Class Code", 'Class get the value of belonging Subclass');

        // [GIVEN] Existing Class and a Subclass with blank
        Assert.AreEqual(FAClass1.Code, FixedAsset."FA Class Code", 'Still the same class');
        // [WHEN] Setting a Subclass
        FixedAsset.Validate("FA Subclass Code", FASubclassWithNoClass.Code);
        // [THEN] Class remaine unchanged
        Assert.AreEqual(FAClass1.Code, FixedAsset."FA Class Code", 'Class remaine unchanged');

        // [GIVEN] Existing Class and a Subclass with blank
        Assert.AreEqual(FAClass1.Code, FixedAsset."FA Class Code", 'Still the same class');
        // [WHEN] Setting a Subclass with a differerent class
        asserterror FixedAsset.Validate("FA Subclass Code", FASubclassWithFAClass2Parrent.Code);
        // [THEN] Error telling the user that this is invalid
        Assert.ExpectedError('This fixed asset subclass belongs to a different fixed asset class.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryVATEntryLinkForFASalesAccOnDispLoss()
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        FANo: Code[20];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [G/L Entry - VAT Entry Link] [VAT] [Sales]
        // [SCENARIO 202344] VATEntry is linked to "VAT" GLEntry with "G/L Account No." = FAPostingGroup."Sales Acc. on Disp. (Loss)" when sale fixed asset with "Depr. until FA Posting Date" = TRUE
        Initialize();

        // [GIVEN] Fixed Asset with "Sales Acc. on Disp. (Loss)" = "DispLossGLAcc", "Disposal Calculation Method" = "Gross", "VAT on Net Disposal Entries" = TRUE
        FANo := CreateFAWithBookGrossAndNetDisposal();

        // [GIVEN] Acquisistion cost on "Posting Date" = 01-01-2019
        CreateAndPostFAJournalLine(FANo, GetFADeprBookCode(FANo));

        // [WHEN] Sale fixed asset (sales invoice "SI") on "Posting Date" = 01-02-2019 with "Depr. until FA Posting Date" = TRUE
        DocumentNo := CreatePostFixedAssetSalesInvoice(CalcDate('<1M>', WorkDate()), FANo, LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] There is a GLEntry "X" with "Document Type" = "Invoice", "Document No." = "SI", "Gen. Posting Type" = "Sale", "G/L Account No." = "DispLossGLAcc"
        GLAccountNo := GetFASalesAccOnDispLoss(FANo);
        FindGLEntry(GLEntry, GLEntry."Document Type"::Invoice, DocumentNo, GLEntry."Gen. Posting Type"::Sale, GLAccountNo);

        // [THEN] There is a VATEntry "Y" with "Document Type" = "Invoice", "Document No." = "SI", Type = "Sale"
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo, VATEntry.Type::Sale);

        // [THEN] There is a "G/L Entry - VAT Entry Link" record with "G/L Entry No." = "X", "VAT Entry No." = "Y"
        GLEntryVATEntryLink.Get(GLEntry."Entry No.", VATEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithDifferentDeprUntilFAPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Acquisition Cost] [Depr. Until FA Posting Date]
        // [SCENARIO 201778] Stans gets error when he posts purchase invoice with two lines for the same fixed asset and mixed "Depr. until FA Posting Date" attribute
        Initialize();

        // [GIVEN] Purchase invoice with two lines for the same fixed asset
        // [GIVEN] Line[1] Type = Fixed Asset, "No." = "FA" and "Depr. until FA Posting Date" = TRUE
        // [GIVEN] Line[2] Type = Fixed Asset, "No." = "FA" and "Depr. until FA Posting Date" = FALSE
        CreatePurchInvoiceWithTwoFixedAsset(PurchaseHeader, FixedAsset, true, false);

        // [WHEN] Post invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Error "The value in the Depr. Until FA Posting Date field must be the same on lines for the same fixed asset."
        Assert.ExpectedError(StrSubstNo(MixedDerpFAUntilPostingDateErr, FixedAsset."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithSameDeprUntilFAPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Acquisition Cost] [Depr. Until FA Posting Date]
        // [SCENARIO 201778] Stans gets error when he posts purchase invoice with two lines for the same fixed asset where "Depr. until FA Posting Date" = TRUE and there is no acqusition cost registered
        Initialize();

        // [GIVEN] Purchase invoice with two lines for the same fixed asset
        // [GIVEN] Line[1] Type = Fixed Asset, "No." = "FA" and "Depr. until FA Posting Date" = TRUE
        // [GIVEN] Line[2] Type = Fixed Asset, "No." = "FA" and "Depr. until FA Posting Date" = TRUE
        // [GIVEN] There is no any acqusition cost registered for the fixed asset
        CreatePurchInvoiceWithTwoFixedAsset(PurchaseHeader, FixedAsset, true, true);

        // [WHEN] Post invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Error "You cannot post multiple purchase lines for the same fixed asset FA when Depr. Until FA Posting Date is TRUE and you've already registered depreciation."
        Assert.ExpectedError(StrSubstNo(CannotPostSameMultipleFAWhenDeprBookValueZeroErr, FixedAsset."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FASubclassCanBeBlankInFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266004] The field "FA Subclass Code" can be blank
        Initialize();

        // [GIVEN] Fixed Asset with assgned FA Subclass
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFASubclass(FASubclass);
        FixedAsset.Validate("FA Subclass Code", FASubclass.Code);
        FixedAsset.Modify(true);

        // [WHEN] Validate "FA Subclass Code" with blank value
        FixedAsset.Validate("FA Subclass Code", '');

        // [THEN] Fixed Asset has blank value in "FA Subclass Code"
        FixedAsset.TestField("FA Subclass Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroupGetWriteDownAccountUT1()
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 281710] Fixed Asset Posting Group GetWriteDownAccount returns Write-Down Account
        Initialize();

        // [GIVEN] A Fixed Asset Posting Group with a Write-Down Account not empty
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // [THEN] GetWriteDownAccount returns Write-Down Account
        Assert.AreEqual(FAPostingGroup."Write-Down Account", FAPostingGroup.GetWriteDownAccount(), 'Accounts must be equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroupGetWriteDownAccountUT2()
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 281710] Fixed Asset Posting Group GetWriteDownAccount throws Testfield error when Write-Down Account is empty
        Initialize();

        // [GIVEN] A Fixed Asset Posting Group with a Write-Down Account empty
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup."Write-Down Account" := '';

        // [THEN] GetWriteDownAccount throws TestField error
        asserterror FAPostingGroup.GetWriteDownAccount();
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
            LibraryErrorMessage.GetMissingAccountErrorMessage(FAPostingGroup.FieldCaption("Write-Down Account"), FAPostingGroup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DefaultFADepreciationBook_Set()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        Index: Integer;
    begin
        // [FEATURE] [UT] [Depreciation Book]
        // [SCENARIO 295642] Stan can set "Default FA Depreciation Book" on FA Depreciation Book when no default book is set before for given Fixed Asset
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        for Index := 1 to ArrayLen(FADepreciationBook) do begin
            LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
            LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook[Index], FixedAsset."No.", DepreciationBook.Code);
        end;

        FADepreciationBook[1].Validate("Default FA Depreciation Book", true);

        FADepreciationBook[1].TestField("Default FA Depreciation Book");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DefaultFADepreciationBook_UnSet()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        Index: Integer;
    begin
        // [FEATURE] [UT] [Depreciation Book]
        // [SCENARIO 295642] Stan can unset "Default FA Depreciation Book" on FA Depreciation Book
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        for Index := 1 to ArrayLen(FADepreciationBook) do begin
            LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
            LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook[Index], FixedAsset."No.", DepreciationBook.Code);
        end;

        FADepreciationBook[1].Validate("Default FA Depreciation Book", true);
        FADepreciationBook[1].Modify(true);

        FADepreciationBook[1].Validate("Default FA Depreciation Book", false);
        FADepreciationBook[1].TestField("Default FA Depreciation Book", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DefaultFADepreciationBook_Negative()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        Index: Integer;
    begin
        // [FEATURE] [UT] [Depreciation Book]
        // [SCENARIO 295642] Stan can't set "Default FA Depreciation Book" on FA Depreciation Book
        // [SCENARIO 295642] when another book is already defined as default for given Fixed Asset
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        for Index := 1 to ArrayLen(FADepreciationBook) do begin
            LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
            LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook[Index], FixedAsset."No.", DepreciationBook.Code);
        end;

        FADepreciationBook[1].Validate("Default FA Depreciation Book", true);
        FADepreciationBook[1].Modify(true);

        asserterror FADepreciationBook[2].Validate("Default FA Depreciation Book", true);
        Assert.ExpectedError(OnlyOneDefaultDeprBookErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankDepreciationBookCodeOnPurchDocOpen()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Depreciation] [Purchase] [Invoice Discount]
        // [SCENARIO 312521] Purchase Order page can be opened with Fixed Asset line with blank Depreciation Book Code and "Calc Inv. and Pmt. Discount" = TRUE in "Purchases & Payables Setup"
        Initialize();

        // [GIVEN] Set "Calc Inv. and Pmt. Discount" = TRUE in "Purchases & Payables Setup"
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Fixed Asset without a Depreciation Book
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.DeleteAll(true);

        // [GIVEN] Purchase Order "PO01" with the Fixed Asset line and non-zero amount
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        CreatePurchLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", '');

        // [WHEN] Open Purchase Order page on "PO01"
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] Page opens without error
        PurchaseOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankDepreciationBookCodeOnPurchDocPostErr()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Depreciation] [Purchase] [Invoice Discount] [Post]
        // [SCENARIO 312521] Purchase Order with Fixed Asset line with blank Depreciation Book Code can't be posted
        Initialize();

        // [GIVEN] Fixed Asset without a Depreciation Book
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.DeleteAll(true);

        // [GIVEN] Purchase Order with the Fixed Asset line and non-zero amount
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        CreatePurchLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", '');

        // [WHEN] Post Purchase Order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posting fails on "Depreciation Book Code" check
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Depreciation Book Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB1RecIsReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"Declining-Balance 1");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB2RecIsReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"Declining-Balance 2");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualRecIsReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::Manual);

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UDRecIsReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"User-Defined");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SLRecIsReadyForAcquisitionWithNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"Straight-Line");

        // [WHEN] "No. of Depreciation Years" is set to >0
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(10));
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB1SLRecIsReadyForAcquisitionWithNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"DB1/SL");

        // [WHEN] "No. of Depreciation Years" is set to >0
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(10));
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB2SLRecIsReadyForAcquisitionWithNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"DB2/SL");

        // [WHEN] "No. of Depreciation Years" is set to >0
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(10));
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SLRecIsNotReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"Straight-Line");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns FALSE
        Assert.IsFalse(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB1SLRecIsNotReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"DB1/SL");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns FALSE
        Assert.IsFalse(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB2SLRecIsNotReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize();

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get();

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"DB2/SL");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns FALSE
        Assert.IsFalse(FADepreciationBook.RecIsReadyForAcquisition(), '');
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineFixedAsset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Undo shipment]
        // [SCENARIO 289385] Stan is able to undo shipment for sales shipment line of Fixed Asset type
        Initialize();

        // [GIVEN] Create and post shipment of sales order with Fixed Asset type line
        PrepareFAForSalesDocument(FixedAsset, DepreciationBook);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", CalcDate('<1D>', WorkDate()));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, FixedAsset."No.", DepreciationBook.Code);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");

        // [WHEN] Undo sales shipment.
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] Verify Quantity after Undo Shipment
        VerifyUndoShipmentLineOnPostedShipment(SalesLine);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesReturnReceiptLineFixedAsset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Undo shipment]
        // [SCENARIO 289385] Stan is able to undo return receipt line
        Initialize();

        // [GIVEN] Create and post receipt of sales return order with Fixed Asset type line
        PrepareFAForSalesDocument(FixedAsset, DepreciationBook);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", CalcDate('<1D>', WorkDate()));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, FixedAsset."No.", DepreciationBook.Code);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindReturnReceiptLine(ReturnReceiptLine, SalesHeader."No.");

        // [WHEN] Undo return receipt
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);

        // [THEN] Verify Quantity after Undo Receipt
        VerifyUndoReceiptLineOnPostedReturnReceipt(SalesLine);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptLineFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Undo shipment]
        // [SCENARIO 289385] Stan is able to undo receipt for Purchase receipt line of Fixed Asset type
        Initialize();

        // [GIVEN] Create and post receipt of Purchase order with Fixed Asset type line
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", DepreciationBook.Code);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindPurchReceiptLine(PurchRcptLine, PurchaseHeader."No.");

        // [WHEN] Undo Purchase receipt.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] Verify Quantity after Undo Receipt
        VerifyUndoReceiptLine(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReturnShipmentLineFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Undo shipment]
        // [SCENARIO 289385] Stan is able to undo return shipment line of Fixed Asset type
        Initialize();

        // [GIVEN] Create and post receipt of purchase return order with Fixed Asset type line
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        CreatePurchLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", DepreciationBook.Code);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindPurchReturnShipmentLine(ReturnShipmentLine, PurchaseHeader."No.");

        // [WHEN] Undo return shipment
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);

        // [THEN] Verify Quantity after Undo shipment
        VerifyUndoShipmentLine(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADefaultEndingBookValue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 335456] "Ending Book Value" for FA Depreciation Book is defaulted by the "Default Ending Book Value" of the Depreciation Book
        Initialize();

        // [GIVEN] Created Depreciation Book with specified "Default Ending Book Value", Fixed Asset
        CreateFixedAssetSetupWDefaultEndingBookValue(DepreciationBook, LibraryRandom.RandDec(100, 2));
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [WHEN] Create FA Depreciation Book
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);

        // [THEN] "Ending Book Value" on FA Depreciation Book is set to be equal to "Default Ending Book Value" from Depreciation Book
        Assert.AreEqual(DepreciationBook."Default Ending Book Value", FADepreciationBook."Ending Book Value", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FANonDefaultEndingBookValue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        EndingBookValue: Decimal;
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 335456] "Ending Book Value" for FA Depreciation Book is not defaulted by the "Default Ending Book Value" of the Depreciation Book
        Initialize();

        // [GIVEN] Created Depreciation Book without specified "Default Ending Book Value" (=0), Fixed Asset
        CreateFixedAssetSetupWDefaultEndingBookValue(DepreciationBook, 0);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [WHEN] Create FA Depreciation Book, assign "Ending Book Value"
        EndingBookValue := LibraryRandom.RandDec(100, 2);
        CreateFADepreciationBookWEndingBookValue(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, EndingBookValue);

        // [THEN] "Ending Book Value" on FA Depreciation Book is correct
        Assert.AreEqual(EndingBookValue, FADepreciationBook."Ending Book Value", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADefaultFinalRoundingAmount()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 335456] "Final Rounding Amount" for FA Depreciation Book is defaulted by the "Default Final Rounding Amount" of the Depreciation Book
        Initialize();

        // [GIVEN] Created Depreciation Book with specified "Default Final Rounding Amount", Fixed Asset
        CreateFixedAssetSetupWDefaultFinalRoundingAmount(DepreciationBook, LibraryRandom.RandDec(100, 2));
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [WHEN] Create FA Depreciation Book
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);

        // [THEN] "Final Rounding Amount" on FA Depreciation Book is set to be equal to "Default Final Rounding Amount" from Depreciation Book
        Assert.AreEqual(DepreciationBook."Default Final Rounding Amount", FADepreciationBook."Final Rounding Amount", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FANonDefaultFinalRoundingAmount()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FinalRoundingAmount: Decimal;
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 335456] "Final Rounding Amount" for FA Depreciation Book is not defaulted by the "Default Final Rounding Amount" of the Depreciation Book
        Initialize();

        // [GIVEN] Created Depreciation Book without specified "Default Final Rounding Amount" (=0), Fixed Asset
        CreateFixedAssetSetupWDefaultFinalRoundingAmount(DepreciationBook, 0);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [WHEN] Create FA Depreciation Book, assign "Final Rounding Amount"
        FinalRoundingAmount := LibraryRandom.RandDec(100, 2);
        CreateFADepreciationBookWFinalRoundingAmount(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, FinalRoundingAmount);

        // [THEN] "Final Rounding Amount" on FA Depreciation Book is correct
        Assert.AreEqual(FinalRoundingAmount, FADepreciationBook."Final Rounding Amount", '');
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProceedsOnDisposalWithGainLossAfterDepreciation()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        SalesHeader: Record "Sales Header";
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
        DocumentNo: Code[20];
        GainLossAmount: Decimal;
    begin
        // [FEATURE] [Proceeds on Disposal]
        // [SCENARIO 352540] Posting Sales Order with disposal and gain/loss entries for fixed asset
        Initialize();

        // [GIVEN] Fixed Asset has aquisition cost of 1000
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);
        UpdateAllowCorrectionInBook(DepreciationBook);
        ModifyIntegrationInBook(DepreciationBook);
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.",
          DepreciationBook.Code, LibraryRandom.RandDecInRange(1000, 2000, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] Depreciation is posted for the fixed asset with amount = 100
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, false);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.CalcFields("Acquisition Cost", Depreciation);

        // [WHEN] Post Sales Order for the fixed asset with amount = 300
        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Order, FixedAsset."No.", DepreciationBook.Code);
        SalesHeader.CalcFields(Amount);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ExecuteUIHandler();

        // [THEN] 'Proceeds on Disposal' FA Legger Entry has amount = 300
        // [THEN] 'Gain/Loss' FA Legger Entry has amount = 600 (1000 - 100 - 300)
        VerifySalesFALedgerEntry(
          DocumentNo, FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal", -SalesHeader.Amount, 0, SalesHeader.Amount);
        GainLossAmount := FADepreciationBook."Acquisition Cost" + FADepreciationBook.Depreciation - SalesHeader.Amount;
        VerifySalesFALedgerEntry(
          DocumentNo, FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Gain/Loss", GainLossAmount, GainLossAmount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateDepreciationWithErrorMessages()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FAPostingGroup: Record "FA Posting Group";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 391482] Error messages page opened while calculating depreciation if posting setup has empty accounts
        Initialize();

        // [GIVEN] Fixed Asset with posted Acquisition Cost.
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, true, false, false);
        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] FA Posting Setup has empty Depreciation Expense Acc.
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        FAPostingGroup."Depreciation Expense Acc." := '';
        FAPostingGroup.Modify();

        // [WHEN] Run Calculate Depreciation
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryErrorMessage.TrapErrorMessages();
        asserterror RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, true);

        // [THEN] Error messages page opened with error "Depreciation Expense Acc. is missing in FA Posting Setup."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField(
            "Message",
            LibraryErrorMessage.GetMissingAccountErrorMessage(
                FAPostingGroup.FieldCaption("Depreciation Expense Acc."),
                FAPostingGroup));
    end;

    [Test]
    procedure AcquireActionWhenEmptyDeprStartingEndingDate()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 396281] Acquire action state on Fixed Asset card when Fixed Asset has FA Depreciation Book with empty "Depreciation Starting Date" and "Depreciation Ending Date" fields.
        Initialize();

        // [GIVEN] Fixed Asset with Subclass that has FA Depreciation Book with empty "Depreciation Starting Date", "Depreciation Ending Date" fields.
        CreateFixedAssetWithSubclass(FixedAsset, FADepreciationBook);
        FADepreciationBook.Validate("Depreciation Starting Date", 0D);
        FADepreciationBook.Modify(true);
        FADepreciationBook.TestField("Depreciation Ending Date", 0D);   // Ending Date cannot be set with empty Starting Date

        // [WHEN] Open Fixed Asset card.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.Filter.SetFilter("No.", FixedAsset."No.");

        // [THEN] Acquire action is disabled.
        Assert.IsFalse(FixedAssetCard.Acquire.Enabled(), '');
    end;

    [Test]
    procedure AcquireActionWhenFilledDeprStartingDateEmptyEndingDate()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 396281] Acquire action state on Fixed Asset card when Fixed Asset has FA Depreciation Book with filled "Depreciation Starting Date" and empty "Depreciation Ending Date" fields.
        Initialize();

        // [GIVEN] Fixed Asset with Subclass that has FA Depreciation Book with filled "Depreciation Starting Date" and empty "Depreciation Ending Date" fields.
        CreateFixedAssetWithSubclass(FixedAsset, FADepreciationBook);
        UpdateStartingDateOnFADepreciationBook(FADepreciationBook, WorkDate());
        UpdateEndingDateOnFADepreciationBook(FADepreciationBook, 0D);

        // [WHEN] Open Fixed Asset card.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.Filter.SetFilter("No.", FixedAsset."No.");

        // [THEN] Acquire action is disabled.
        Assert.IsFalse(FixedAssetCard.Acquire.Enabled(), '');
    end;

    [Test]
    [HandlerFunctions('EnqueueMessageSendNotificationHandler')]
    procedure AcquireActionWhenFilledDeprStartingEndingDateFiscalYear365False()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        NotificationText: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 396281] Acquire action state on Fixed Asset card when Fixed Asset has FA Depreciation Book with filled "Depreciation Starting Date" and "Depreciation Ending Date" fields. Fiscal Year 365 Days = False.
        Initialize();

        // [GIVEN] Fixed Asset with Subclass that has FA Depreciation Book with filled "Depreciation Starting Date" and "Depreciation Ending Date" fields.
        // [GIVEN] Depreciation Book has "Fiscal Year 365 Days" not set.
        CreateFixedAssetWithSubclass(FixedAsset, FADepreciationBook);
        LibraryFixedAsset.UpdateFASetupDefaultDeprBook(FADepreciationBook."Depreciation Book Code");
        UpdateFiscalYear365DaysOnDepreciationBook(FADepreciationBook."Depreciation Book Code", false);
        UpdateStartingDateOnFADepreciationBook(FADepreciationBook, WorkDate());
        UpdateEndingDateOnFADepreciationBook(FADepreciationBook, CalcDate('<1Y>', WorkDate()));

        // [WHEN] Open Fixed Asset card.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.Filter.SetFilter("No.", FixedAsset."No.");

        // [THEN] Acquire action is enabled. Notification with text "You are ready to acquire the fixed asset" is shown.
        Assert.IsTrue(FixedAssetCard.Acquire.Enabled(), '');
        NotificationText := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(AcquireNotificationMsg, NotificationText, '');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EnqueueMessageSendNotificationHandler')]
    procedure AcquireActionWhenStraightLineFilledDeprStartingEndingDateFiscalYear365True()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        NotificationText: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 396281] Acquire action state on Fixed Asset card when Fixed Asset has FA Depreciation Book with filled Depreciation Starting/Ending Date fields; Depreciation Method is "Straight-Line". Fiscal Year 365 Days = True.
        Initialize();

        // [GIVEN] Fixed Asset with Subclass that has FA Depreciation Book with filled "Depreciation Starting Date" and "Depreciation Ending Date" fields. Depreciation Method is "Straight-Line".
        // [GIVEN] Depreciation Book has "Fiscal Year 365 Days" set.
        CreateFixedAssetWithSubclass(FixedAsset, FADepreciationBook);
        LibraryFixedAsset.UpdateFASetupDefaultDeprBook(FADepreciationBook."Depreciation Book Code");
        UpdateFiscalYear365DaysOnDepreciationBook(FADepreciationBook."Depreciation Book Code", true);
        UpdateDepreciationMethodOnFADepreciationBook(FADepreciationBook, FADepreciationMethod::"Straight-Line");
        UpdateStartingDateOnFADepreciationBook(FADepreciationBook, WorkDate());
        UpdateEndingDateOnFADepreciationBook(FADepreciationBook, CalcDate('<1Y>', WorkDate()));

        // [WHEN] Open Fixed Asset card.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.Filter.SetFilter("No.", FixedAsset."No.");

        // [THEN] Acquire action is enabled. Notification with text "You are ready to acquire the fixed asset" is shown.
        Assert.IsTrue(FixedAssetCard.Acquire.Enabled(), '');
        NotificationText := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(AcquireNotificationMsg, NotificationText, '');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EnqueueMessageSendNotificationHandler')]
    procedure AcquireActionWhenDB1FilledDeprStartingEndingDateFiscalYear365True()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        NotificationText: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 396281] Acquire action state on Fixed Asset card when Fixed Asset has FA Depreciation Book with filled Depreciation Starting Date; Depreciation Method is "Declining-Balance 1". Fiscal Year 365 Days = True.
        Initialize();

        // [GIVEN] Fixed Asset with Subclass that has FA Depreciation Book with filled "Depreciation Starting Date" field. Depreciation Method is "Declining-Balance 1".
        // [GIVEN] Depreciation Book has "Fiscal Year 365 Days" set.
        CreateFixedAssetWithSubclass(FixedAsset, FADepreciationBook);
        LibraryFixedAsset.UpdateFASetupDefaultDeprBook(FADepreciationBook."Depreciation Book Code");
        UpdateFiscalYear365DaysOnDepreciationBook(FADepreciationBook."Depreciation Book Code", true);
        UpdateDepreciationMethodOnFADepreciationBook(FADepreciationBook, FADepreciationMethod::"Declining-Balance 1");
        UpdateStartingDateOnFADepreciationBook(FADepreciationBook, WorkDate());

        // [WHEN] Open Fixed Asset card.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.Filter.SetFilter("No.", FixedAsset."No.");

        // [THEN] Acquire action is enabled. Notification with text "You are ready to acquire the fixed asset" is shown.
        Assert.IsTrue(FixedAssetCard.Acquire.Enabled(), '');
        NotificationText := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(AcquireNotificationMsg, NotificationText, '');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EnqueueMessageSendNotificationHandler')]
    procedure AcquireActionWhenDB2SLFilledDeprStartingEndingDateFiscalYear365True()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        NotificationText: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 396281] Acquire action state on Fixed Asset card when Fixed Asset has FA Depreciation Book with filled Depreciation Starting/Ending Date fields; Depreciation Method is "DB2/SL". Fiscal Year 365 Days = True.
        Initialize();

        // [GIVEN] Fixed Asset with Subclass that has FA Depreciation Book with filled "Depreciation Starting Date" and "Depreciation Ending Date" fields. Depreciation Method is "DB2/SL".
        // [GIVEN] Depreciation Book has "Fiscal Year 365 Days" set.
        CreateFixedAssetWithSubclass(FixedAsset, FADepreciationBook);
        LibraryFixedAsset.UpdateFASetupDefaultDeprBook(FADepreciationBook."Depreciation Book Code");
        UpdateFiscalYear365DaysOnDepreciationBook(FADepreciationBook."Depreciation Book Code", true);
        UpdateDepreciationMethodOnFADepreciationBook(FADepreciationBook, FADepreciationMethod::"DB2/SL");
        UpdateStartingDateOnFADepreciationBook(FADepreciationBook, WorkDate());
        UpdateEndingDateOnFADepreciationBook(FADepreciationBook, CalcDate('<1Y>', WorkDate()));

        // [WHEN] Open Fixed Asset card.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.Filter.SetFilter("No.", FixedAsset."No.");

        // [THEN] Acquire action is enabled. Notification with text "You are ready to acquire the fixed asset" is shown.
        Assert.IsTrue(FixedAssetCard.Acquire.Enabled(), '');
        NotificationText := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(AcquireNotificationMsg, NotificationText, '');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EnqueueMessageSendNotificationHandler')]
    procedure AcquireActionWhenManualFilledDeprStartingEndingDateFiscalYear365True()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        NotificationText: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 396281] Acquire action state on Fixed Asset card when Fixed Asset has FA Depreciation Book with filled Depreciation Starting Date fields; Depreciation Method is "Manual". Fiscal Year 365 Days = True.
        Initialize();

        // [GIVEN] Fixed Asset with Subclass that has FA Depreciation Book with filled "Depreciation Starting Date" field. Depreciation Method is "Manual".
        // [GIVEN] Depreciation Book has "Fiscal Year 365 Days" set.
        CreateFixedAssetWithSubclass(FixedAsset, FADepreciationBook);
        LibraryFixedAsset.UpdateFASetupDefaultDeprBook(FADepreciationBook."Depreciation Book Code");
        UpdateFiscalYear365DaysOnDepreciationBook(FADepreciationBook."Depreciation Book Code", true);
        UpdateDepreciationMethodOnFADepreciationBook(FADepreciationBook, FADepreciationMethod::Manual);
        UpdateStartingDateOnFADepreciationBook(FADepreciationBook, WorkDate());

        // [WHEN] Open Fixed Asset card.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.Filter.SetFilter("No.", FixedAsset."No.");

        // [THEN] Acquire action is enabled. Notification with text "You are ready to acquire the fixed asset" is shown.
        Assert.IsTrue(FixedAssetCard.Acquire.Enabled(), '');
        NotificationText := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(AcquireNotificationMsg, NotificationText, '');

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure InPurchaseLineValidateDepreciationBookCodeIfOnlyOne()
    var
        Vendor: Record Vendor;
        FASetup: Record "FA Setup";
        DepreciationBook1: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
        DepreciationBook4: Record "Depreciation Book";
        DepreciationBook5: Record "Depreciation Book";
        FixedAsset1: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FixedAsset3: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubClass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook1: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        FADepreciationBook3: Record "FA Depreciation Book";
        FADepreciationBook4: Record "FA Depreciation Book";
        FADepreciationBook5: Record "FA Depreciation Book";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseHeader3: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        PurchInvLine1: Record "Purch. Inv. Line";
        PurchInvLine2: Record "Purch. Inv. Line";
        PurchInvLine3: Record "Purch. Inv. Line";
    begin
        // [SCENARIO 475619] "Depreciation Book Code must have a value in Purchase Line" error message appears if "Default Depr. Book" is blank in Fixed Asset Setup
        Initialize();

        // [GIVEN] Create Depreciation Book 1.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook1, true);

        // [GIVEN] Create Depreciation Book 2.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook2, true);

        // [GIVEN] Create Depreciation Book 3.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook3, true);

        // [GIVEN] Create Depreciation Book 4.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook4, true);

        // [GIVEN] Create Depreciation Book 5.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook5, true);

        // [GIVEN] Validate Default Depr. Book as Blank in Fixed Asset Setup.
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", '');
        FASetup.Modify(true);

        // [GIVEN] Create a FA Class.
        LibraryFixedAsset.CreateFAClass(FAClass);

        // [GIVEN] Create a FA Subclass.
        LibraryFixedAsset.CreateFASubclass(FASubClass);

        // [GIVEN] Create a FA Posting Group.
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // [GIVEN] Create Fixed Asset 1 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset1, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 1 for Depreciation Book 1.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook1,
            FixedAsset1,
            DepreciationBook1,
            FixedAsset1."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Purchase Header 1 with Vendor Invoice No. & Posting Date.
        CreatePurchHeaderWithVendorInvNoAndPostingDate(PurchaseHeader1, Vendor."No.", Format(LibraryRandom.RandInt(50)), WorkDate());

        // [GIVEN] Create Purchase Line 1 with Direct Unit Cost.
        CreatePurchLineWithDirectUnitCost(
            PurchaseHeader1,
            PurchaseLine1,
            "Purchase Line Type"::"Fixed Asset",
            FixedAsset1."No.",
            LibraryRandom.RandInt(0),
            LibraryRandom.RandDec(1000, 0));

        // [GIVEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);

        // [WHEN] Find Posted Purchase Invoice Line 1.
        PurchInvLine1.SetRange("Order No.", PurchaseHeader1."No.");
        PurchInvLine1.SetRange("Line No.", PurchaseLine1."Line No.");
        PurchInvLine1.FindFirst();

        // [VERIFY] Verify Purchase Order Depreciation Book Code & Posted Purchase Inv Depreciation Book Code are same.
        Assert.AreEqual(PurchaseLine1."Depreciation Book Code", PurchInvLine1."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Create Fixed Asset 2 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset2, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 2 for Depreciation Book 2.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook2,
            FixedAsset2,
            DepreciationBook2,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Default FA Depreciation Book for Depreciation Book 3.
        CreateDefaultFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook3,
            FixedAsset2,
            DepreciationBook3,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Purchase Header 2 with Vendor Invoice No. & Posting Date.
        CreatePurchHeaderWithVendorInvNoAndPostingDate(PurchaseHeader2, Vendor."No.", Format(LibraryRandom.RandInt(50)), WorkDate());

        // [GIVEN] Create Purchase Line 2 with Direct Unit Cost.
        CreatePurchLineWithDirectUnitCost(
            PurchaseHeader2,
            PurchaseLine2,
            "Purchase Line Type"::"Fixed Asset",
            FixedAsset2."No.",
            LibraryRandom.RandInt(0),
            LibraryRandom.RandDec(1000, 0));

        // [GIVEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // [WHEN] Find Posted Purchase Invoice Line 2.
        PurchInvLine2.SetRange("Order No.", PurchaseHeader2."No.");
        PurchInvLine2.SetRange("Line No.", PurchaseLine2."Line No.");
        PurchInvLine2.FindFirst();

        // [VERIFY] Verify Purchase Order Depreciation Book Code & Posted Purchase Inv Depreciation Book Code are same.
        Assert.AreEqual(PurchaseLine2."Depreciation Book Code", PurchInvLine2."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Validate Default Depr. Book in Fixed Asset Setup.
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook5.Code);
        FASetup.Modify(true);

        // [GIVEN] Create Fixed Asset 3 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset3, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 4 for Depreciation Book 4.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook4,
            FixedAsset3,
            DepreciationBook4,
            FixedAsset3."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Depreciation Book 5 for Depreciation Book 5.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook5,
            FixedAsset3,
            DepreciationBook5,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Purchase Header 3 with Vendor Invoice No. & Posting Date.
        CreatePurchHeaderWithVendorInvNoAndPostingDate(PurchaseHeader3, Vendor."No.", Format(LibraryRandom.RandInt(50)), WorkDate());

        // [GIVEN] Create Purchase Line 3 with Direct Unit Cost.
        CreatePurchLineWithDirectUnitCost(
            PurchaseHeader3,
            PurchaseLine3,
            "Purchase Line Type"::"Fixed Asset",
            FixedAsset3."No.",
            LibraryRandom.RandInt(0),
            LibraryRandom.RandDec(1000, 0));

        // [GIVEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader3, true, true);

        // [WHEN] Find Posted Purchase Invoice Line 3.
        PurchInvLine3.SetRange("Order No.", PurchaseHeader3."No.");
        PurchInvLine3.SetRange("Line No.", PurchaseLine3."Line No.");
        PurchInvLine3.FindFirst();

        // [VERIFY] Verify Purchase Order Depreciation Book Code & FA Setup Default Depreciation Book Code are same.
        Assert.AreEqual(PurchInvLine3."Depreciation Book Code", FASetup."Default Depr. Book", DepreciationBookCodeMustMatchErr);
    end;

    [Test]
    procedure InSalesLineValidateDepreciationBookCodeIfOnlyOne()
    var
        Customer: Record Customer;
        FASetup: Record "FA Setup";
        DepreciationBook1: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
        DepreciationBook4: Record "Depreciation Book";
        DepreciationBook5: Record "Depreciation Book";
        FixedAsset1: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FixedAsset3: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubClass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook1: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        FADepreciationBook3: Record "FA Depreciation Book";
        FADepreciationBook4: Record "FA Depreciation Book";
        FADepreciationBook5: Record "FA Depreciation Book";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        SalesInvoiceLine1: Record "Sales Invoice Line";
        SalesInvoiceLine2: Record "Sales Invoice Line";
        SalesInvoiceLine3: Record "Sales Invoice Line";
    begin
        // [SCENARIO 475619] "Depreciation Book Code must have a value in Purchase Line" error message appears if "Default Depr. Book" is blank in Fixed Asset Setup
        Initialize();

        // [GIVEN] Create Depreciation Book 1 & Validate GL Integration - Disposal.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook1, true);
        DepreciationBook1.Validate("G/L Integration - Disposal", true);
        DepreciationBook1.Modify(true);

        // [GIVEN] Create Depreciation Book 2 & Validate GL Integration - Disposal.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook2, true);
        DepreciationBook2.Validate("G/L Integration - Disposal", true);
        DepreciationBook2.Modify(true);

        // [GIVEN] Create Depreciation Book 3 & Validate GL Integration - Disposal.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook3, true);
        DepreciationBook3.Validate("G/L Integration - Disposal", true);
        DepreciationBook3.Modify(true);

        // [GIVEN] Create Depreciation Book 4 & Validate GL Integration - Disposal.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook4, true);
        DepreciationBook4.Validate("G/L Integration - Disposal", true);
        DepreciationBook4.Modify(true);

        // [GIVEN] Create Depreciation Book 5 & Validate GL Integration - Disposal.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook5, true);
        DepreciationBook5.Validate("G/L Integration - Disposal", true);
        DepreciationBook5.Modify(true);

        // [GIVEN] Validate Default Depr. Book as Blank in Fixed Asset Setup.
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook5.Code);
        FASetup.Modify(true);

        // [GIVEN] Create a FA Class.
        LibraryFixedAsset.CreateFAClass(FAClass);

        // [GIVEN] Create a FA Subclass.
        LibraryFixedAsset.CreateFASubclass(FASubClass);

        // [GIVEN] Create a FA Posting Group.
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // [GIVEN] Create Fixed Asset 1 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset1, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 1 for Depreciation Book 1.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook1,
            FixedAsset1,
            DepreciationBook1,
            FixedAsset1."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Sales Header 1 with Customer No. & Posting Date.
        CreateSalesHeaderWithCustomerNoAndPostingDate(SalesHeader1, Customer."No.", WorkDate());

        // [GIVEN] Create Sales Line 1 with Direct Unit Cost.
        CreateSalesLineWithDirectUnitCost(
            SalesHeader1,
            SalesLine1,
            "Sales Line Type"::"Fixed Asset",
            FixedAsset1."No.",
            LibraryRandom.RandInt(0),
            LibraryRandom.RandDec(1000, 0));

        // [GIVEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader1, true, true);

        // [WHEN] Find Posted Sales Invoice Line 1.
        SalesInvoiceLine1.SetRange("Order No.", SalesHeader1."No.");
        SalesInvoiceLine1.SetRange("Line No.", SalesLine1."Line No.");
        SalesInvoiceLine1.FindFirst();

        // [VERIFY] Verify Sales Order Depreciation Book Code & Posted Sales Inv Depreciation Book Code are same.
        Assert.AreEqual(SalesLine1."Depreciation Book Code", SalesInvoiceLine1."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Create Fixed Asset 2 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset2, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 2 for Depreciation Book 2.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook2,
            FixedAsset2,
            DepreciationBook2,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Default FA Depreciation Book for Depreciation Book 3.
        CreateDefaultFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook3,
            FixedAsset2,
            DepreciationBook3,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Sales Header 2 with Customer No. & Posting Date.
        CreateSalesHeaderWithCustomerNoAndPostingDate(SalesHeader2, Customer."No.", WorkDate());

        // [GIVEN] Create Sales Line 2 with Direct Unit Cost.
        CreateSalesLineWithDirectUnitCost(
            SalesHeader2,
            SalesLine2,
            "Sales Line Type"::"Fixed Asset",
            FixedAsset2."No.",
            LibraryRandom.RandInt(0),
            LibraryRandom.RandDec(1000, 0));

        // [GIVEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // [WHEN] Find Posted Sales Invoice Line 2.
        SalesInvoiceLine2.SetRange("Order No.", SalesHeader2."No.");
        SalesInvoiceLine2.SetRange("Line No.", SalesLine2."Line No.");
        SalesInvoiceLine2.FindFirst();

        // [VERIFY] Verify Sales Order Depreciation Book Code & Posted Sales Inv Depreciation Book Code are same.
        Assert.AreEqual(SalesLine2."Depreciation Book Code", SalesInvoiceLine2."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Create Fixed Asset 3 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset3, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 4 for Depreciation Book 4.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook4,
            FixedAsset3,
            DepreciationBook4,
            FixedAsset3."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Depreciation Book 5 for Depreciation Book 5.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook5,
            FixedAsset3,
            DepreciationBook5,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Sales Header 3 with Customer No. & Posting Date.
        CreateSalesHeaderWithCustomerNoAndPostingDate(SalesHeader3, Customer."No.", WorkDate());

        // [GIVEN] Create Sales Line 3 with Direct Unit Cost.
        CreateSalesLineWithDirectUnitCost(
            SalesHeader3,
            SalesLine3,
            "Sales Line Type"::"Fixed Asset",
            FixedAsset3."No.",
            LibraryRandom.RandInt(0),
            LibraryRandom.RandDec(1000, 0));

        // [GIVEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader3, true, true);

        // [WHEN] Find Posted Sales Invoice Line 3.
        SalesInvoiceLine3.SetRange("Order No.", SalesHeader3."No.");
        SalesInvoiceLine3.SetRange("Line No.", SalesLine3."Line No.");
        SalesInvoiceLine3.FindFirst();

        // [VERIFY] Verify Sales Order Depreciation Book Code & FA Setup Default Depreciation Book Code are same.
        Assert.AreEqual(SalesInvoiceLine3."Depreciation Book Code", FASetup."Default Depr. Book", DepreciationBookCodeMustMatchErr);
    end;

    [Test]
    procedure InGenJnlLineValidateDepreciationBookCodeIfOnlyOne()
    var
        FASetup: Record "FA Setup";
        DepreciationBook1: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
        DepreciationBook4: Record "Depreciation Book";
        DepreciationBook5: Record "Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
        FixedAsset1: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FixedAsset3: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubClass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook1: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        FADepreciationBook3: Record "FA Depreciation Book";
        FADepreciationBook4: Record "FA Depreciation Book";
        FADepreciationBook5: Record "FA Depreciation Book";
        FALedgerEntry1: Record "FA Ledger Entry";
        FALedgerEntry2: Record "FA Ledger Entry";
        FALedgerEntry3: Record "FA Ledger Entry";
    begin
        // [SCENARIO 475619] "Depreciation Book Code must have a value in Purchase Line" error message appears if "Default Depr. Book" is blank in Fixed Asset Setup
        Initialize();

        // [GIVEN] Create Depreciation Book 1.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook1, true);

        // [GIVEN] Create Depreciation Book 2.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook2, true);

        // [GIVEN] Create Depreciation Book 3.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook3, true);

        // [GIVEN] Create Depreciation Book 4.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook4, true);

        // [GIVEN] Create Depreciation Book 5.
        CreateDepreciationBookwithGLIntegrationAcqCost(DepreciationBook5, true);

        // [GIVEN] Validate Default Depr. Book as Blank in Fixed Asset Setup.
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook5.Code);
        FASetup.Modify(true);

        // [GIVEN] Create a FA Class.
        LibraryFixedAsset.CreateFAClass(FAClass);

        // [GIVEN] Create a FA Subclass.
        LibraryFixedAsset.CreateFASubclass(FASubClass);

        // [GIVEN] Create a FA Posting Group.
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // [GIVEN] Create Fixed Asset 1 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset1, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 1 for Depreciation Book 1.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook1,
            FixedAsset1,
            DepreciationBook1,
            FixedAsset1."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Gen Journal Batch.
        CreateGeneralJournalBatch(GenJournalBatch);

        // [GIVEN] Create Gen Journal Line 1.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine1,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine1."Document Type"::Payment,
            GenJournalLine1."Account Type"::"Fixed Asset",
            FixedAsset1."No.",
            LibraryRandom.RandInt(20));

        // [GIVEN] Validate FA Posting Type.
        GenJournalLine1.Validate("FA Posting Type", GenJournalLine1."FA Posting Type"::"Acquisition Cost");
        GenJournalLine1.Modify(true);

        // [GIVEN] Post Gen Journal Line 1.
        LibraryERM.PostGeneralJnlLine(GenJournalLine1);

        // [WHEN] Find FA Ledger Entry 1.
        FALedgerEntry1.SetRange("FA No.", GenJournalLine1."Account No.");
        FALedgerEntry1.FindFirst();

        // [VERIFY] Verify Gen Jorunal Line 1 Depreciation Book Code & FA ledger Entry 1 Depreciation Book Code are same.
        Assert.AreEqual(GenJournalLine1."Depreciation Book Code", FALedgerEntry1."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Create Fixed Asset 2 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset2, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 2 for Depreciation Book 2.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook2,
            FixedAsset2,
            DepreciationBook2,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Default FA Depreciation Book for Depreciation Book 3.
        CreateDefaultFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook3,
            FixedAsset2,
            DepreciationBook3,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Gen Journal Line 2.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine2,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine2."Document Type"::Payment,
            GenJournalLine2."Account Type"::"Fixed Asset",
            FixedAsset2."No.",
            LibraryRandom.RandInt(20));

        // [GIVEN] Validate FA Posting Type.
        GenJournalLine2.Validate("FA Posting Type", GenJournalLine2."FA Posting Type"::"Acquisition Cost");
        GenJournalLine2.Modify(true);

        // [GIVEN] Post Gen Journal Line 2.
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // [WHEN] Find FA Ledger Entry 2.
        FALedgerEntry2.SetRange("FA No.", GenJournalLine2."Account No.");
        FALedgerEntry2.FindFirst();

        // [VERIFY] Verify Gen Jorunal Line 2 Depreciation Book Code & FA ledger Entry 2 Depreciation Book Code are same.
        Assert.AreEqual(GenJournalLine2."Depreciation Book Code", FALedgerEntry2."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Create Fixed Asset 3 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset3, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 4 for Depreciation Book 4.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook4,
            FixedAsset3,
            DepreciationBook4,
            FixedAsset3."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Depreciation Book 5 for Depreciation Book 5.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook5,
            FixedAsset3,
            DepreciationBook5,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Gen Journal Line 3.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine3,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine3."Document Type"::Payment,
            GenJournalLine3."Account Type"::"Fixed Asset",
            FixedAsset3."No.",
            LibraryRandom.RandInt(20));

        // [GIVEN] Validate FA Posting Type.
        GenJournalLine3.Validate("FA Posting Type", GenJournalLine3."FA Posting Type"::"Acquisition Cost");
        GenJournalLine3.Modify(true);

        // [GIVEN] Post Gen Journal Line 3.
        LibraryERM.PostGeneralJnlLine(GenJournalLine3);

        // [WHEN] Find FA Ledger Entry 3.
        FALedgerEntry3.SetRange("FA No.", GenJournalLine3."Account No.");
        FALedgerEntry3.FindFirst();

        // [VERIFY] Verify Gen Jorunal Line 3 Depreciation Book Code & FA Setup Default Depreciation Book Code are same.
        Assert.AreEqual(FALedgerEntry3."Depreciation Book Code", FASetup."Default Depr. Book", DepreciationBookCodeMustMatchErr);
    end;

    [Test]
    procedure InFAJournalLineValidateDepreciationBookCodeIfOnlyOne()
    var
        Vendor: Record Vendor;
        FASetup: Record "FA Setup";
        DepreciationBook1: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
        DepreciationBook4: Record "Depreciation Book";
        DepreciationBook5: Record "Depreciation Book";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine1: Record "FA Journal Line";
        FAJournalLine2: Record "FA Journal Line";
        FAJournalLine3: Record "FA Journal Line";
        FixedAsset1: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FixedAsset3: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubClass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook1: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        FADepreciationBook3: Record "FA Depreciation Book";
        FADepreciationBook4: Record "FA Depreciation Book";
        FADepreciationBook5: Record "FA Depreciation Book";
        FALedgerEntry1: Record "FA Ledger Entry";
        FALedgerEntry2: Record "FA Ledger Entry";
        FALedgerEntry3: Record "FA Ledger Entry";
    begin
        // [SCENARIO 475619] "Depreciation Book Code must have a value in Purchase Line" error message appears if "Default Depr. Book" is blank in Fixed Asset Setup
        Initialize();

        // [GIVEN] Create Depreciation Book 1.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook1);

        // [GIVEN] Create Depreciation Book 2.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook2);

        // [GIVEN] Create Depreciation Book 3.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook3);

        // [GIVEN] Create Depreciation Book 4.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook4);

        // [GIVEN] Create Depreciation Book 5.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook5);

        // [GIVEN] Validate Default Depr. Book as Blank in Fixed Asset Setup.
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook5.Code);
        FASetup.Modify(true);

        // [GIVEN] Create a FA Class.
        LibraryFixedAsset.CreateFAClass(FAClass);

        // [GIVEN] Create a FA Subclass.
        LibraryFixedAsset.CreateFASubclass(FASubClass);

        // [GIVEN] Create a FA Posting Group.
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // [GIVEN] Create Fixed Asset 1 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset1, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 1 for Depreciation Book 1.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook1,
            FixedAsset1,
            DepreciationBook1,
            FixedAsset1."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Gen Journal Batch.
        CreateFAJournalBatch(FAJournalBatch);

        // [GIVEN] Create FA Journal Line 1.
        CreateFAJournalLineWithoutDepreciationBook(
            FAJournalLine1,
            FAJournalBatch,
            FAJournalLine1."FA Posting Type"::"Acquisition Cost",
            FixedAsset1."No.",
            LibraryRandom.RandDec(10, 0));

        // [GIVEN] Post FA Journal Line 1.
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine1);

        // [WHEN] Find FA Ledger Entry 1.
        FALedgerEntry1.SetRange("FA No.", FixedAsset1."No.");
        FALedgerEntry1.FindFirst();

        // [VERIFY] Verify Depreciation Book Code 1 & FA ledger Entry 1 Depreciation Book Code are same.
        Assert.AreEqual(DepreciationBook1.Code, FALedgerEntry1."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Create Fixed Asset 2 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset2, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 2 for Depreciation Book 2.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook2,
            FixedAsset2,
            DepreciationBook2,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Default FA Depreciation Book for Depreciation Book 3.
        CreateDefaultFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook3,
            FixedAsset2,
            DepreciationBook3,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Journal Line 2.
        CreateFAJournalLineWithoutDepreciationBook(
            FAJournalLine2,
            FAJournalBatch,
            FAJournalLine2."FA Posting Type"::"Acquisition Cost",
            FixedAsset2."No.",
            LibraryRandom.RandDec(10, 0));

        // [GIVEN] Post FA Journal Line 2.
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine2);

        // [WHEN] Find FA Ledger Entry 2.
        FALedgerEntry2.SetRange("FA No.", FixedAsset2."No.");
        FALedgerEntry2.FindFirst();

        // [VERIFY] Verify Depreciation Book Code 3 & FA ledger Entry 2 Depreciation Book Code are same.
        Assert.AreEqual(DepreciationBook3.Code, FALedgerEntry2."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Create Fixed Asset 3 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset3, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 4 for Depreciation Book 4.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook4,
            FixedAsset3,
            DepreciationBook4,
            FixedAsset3."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Depreciation Book 5 for Depreciation Book 5.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook5,
            FixedAsset3,
            DepreciationBook5,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Journal Line 3.
        CreateFAJournalLineWithoutDepreciationBook(
            FAJournalLine3,
            FAJournalBatch,
            FAJournalLine3."FA Posting Type"::"Acquisition Cost",
            FixedAsset3."No.",
            LibraryRandom.RandDec(10, 0));

        // [GIVEN] Post FA Journal Line 3.
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine3);

        // [WHEN] Find FA Ledger Entry 3.
        FALedgerEntry3.SetRange("FA No.", FixedAsset3."No.");
        FALedgerEntry3.FindFirst();

        // [VERIFY] Verify FA Setup Default Depreciation Book Code & FA ledger Entry 3 Depreciation Book Code are same.
        Assert.AreEqual(FASetup."Default Depr. Book", FALedgerEntry3."Depreciation Book Code", DepreciationBookCodeMustMatchErr);
    end;

    [Test]
    procedure InFAReclassJournalLineValidateDepreciationBookCodeIfOnlyOne()
    var
        FASetup: Record "FA Setup";
        DepreciationBook1: Record "Depreciation Book";
        DepreciationBook2: Record "Depreciation Book";
        DepreciationBook3: Record "Depreciation Book";
        DepreciationBook4: Record "Depreciation Book";
        DepreciationBook5: Record "Depreciation Book";
        NewDepreciationBook: Record "Depreciation Book";
        FAReclassJournalLine1: Record "FA Reclass. Journal Line";
        FAReclassJournalLine2: Record "FA Reclass. Journal Line";
        FAReclassJournalLine3: Record "FA Reclass. Journal Line";
        FixedAsset1: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FixedAsset3: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubClass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook1: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        FADepreciationBook3: Record "FA Depreciation Book";
        FADepreciationBook4: Record "FA Depreciation Book";
        FADepreciationBook5: Record "FA Depreciation Book";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
        FAReclassJournalTemplate: Record "FA Reclass. Journal Template";
    begin
        // [SCENARIO 475619] "Depreciation Book Code must have a value in Purchase Line" error message appears if "Default Depr. Book" is blank in Fixed Asset Setup
        Initialize();

        // [GIVEN] Create Depreciation Book 1.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook1);

        // [GIVEN] Create Depreciation Book 2.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook2);

        // [GIVEN] Create Depreciation Book 3.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook3);

        // [GIVEN] Create Depreciation Book 4.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook4);

        // [GIVEN] Create Depreciation Book 5.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook5);

        // [GIVEN] Create New Depreciation Book.
        LibraryFixedAsset.CreateDepreciationBook(NewDepreciationBook);

        // [GIVEN] Validate Default Depr. Book as Blank in Fixed Asset Setup.
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook5.Code);
        FASetup.Modify(true);

        // [GIVEN] Create a FA Class.
        LibraryFixedAsset.CreateFAClass(FAClass);

        // [GIVEN] Create a FA Subclass.
        LibraryFixedAsset.CreateFASubclass(FASubClass);

        // [GIVEN] Create a FA Posting Group.
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // [GIVEN] Create Fixed Asset 1 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset1, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 1 for Depreciation Book 1.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook1,
            FixedAsset1,
            DepreciationBook1,
            FixedAsset1."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Reclass Journal Template.
        LibraryFixedAsset.CreateFAReclassJournalTemplate(FAReclassJournalTemplate);

        // [GIVEN] Create FA Reclass Journal Batch.
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate.Name);

        // [GIVEn] Create FA Reclass Journal Line 1.
        LibraryFixedAsset.CreateFAReclassJournal(
            FAReclassJournalLine1,
            FAReclassJournalBatch."Journal Template Name",
            FAReclassJournalBatch.Name);

        // [WHEN] Validate FA No.
        FAReclassJournalLine1.Validate("FA No.", FixedAsset1."No.");
        FAReclassJournalLine1.Modify(true);

        // [VERIFY] Verify Depreciation Book Code 1 & FA Reclass Journal Line 1 Depreciation Book Code are same.
        Assert.AreEqual(DepreciationBook1.Code, FAReclassJournalLine1."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Create Fixed Asset 2 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset2, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 2 for Depreciation Book 2.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook2,
            FixedAsset2,
            DepreciationBook2,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create Default FA Depreciation Book for Depreciation Book 3.
        CreateDefaultFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook3,
            FixedAsset2,
            DepreciationBook3,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Reclass Journal Line 2.
        LibraryFixedAsset.CreateFAReclassJournal(
            FAReclassJournalLine2,
            FAReclassJournalBatch."Journal Template Name",
            FAReclassJournalBatch.Name);

        // [WHEN] Validate FA No.
        FAReclassJournalLine2.Validate("FA No.", FixedAsset2."No.");
        FAReclassJournalLine2.Modify(true);

        // [VERIFY] Verify Depreciation Book Code 3 & FA Reclass Journal Line 2 Depreciation Book Code are same.
        Assert.AreEqual(DepreciationBook3.Code, FAReclassJournalLine2."Depreciation Book Code", DepreciationBookCodeMustMatchErr);

        // [GIVEN] Create Fixed Asset 3 with FA Class Code, FA Subclass Code & FA Posting Group.
        CreateFixedAssetWithFAClassFASubclassFAPostingGroup(FixedAsset3, FAClass.Code, FASubClass.Code, FAPostingGroup.Code);

        // [GIVEN] Create FA Depreciation Book 4 for Depreciation Book 4.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook4,
            FixedAsset3,
            DepreciationBook4,
            FixedAsset3."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Depreciation Book 5 for Depreciation Book 5.
        CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(
            FADepreciationBook5,
            FixedAsset3,
            DepreciationBook5,
            FixedAsset2."FA Posting Group",
            "FA Depreciation Method"::"Straight-Line",
            WorkDate(),
            LibraryRandom.RandInt(3));

        // [GIVEN] Create FA Reclass Journal Line 3.
        LibraryFixedAsset.CreateFAReclassJournal(
            FAReclassJournalLine3,
            FAReclassJournalBatch."Journal Template Name",
            FAReclassJournalBatch.Name);

        // [WHEN] Validate FA No.
        FAReclassJournalLine3.Validate("FA No.", FixedAsset3."No.");
        FAReclassJournalLine3.Modify(true);

        // [VERIFY] Verify FA Setup Default Depreciation Book Code & FA Reclass Journal Line 3 Depreciation Book Code are same.
        Assert.AreEqual(FASetup."Default Depr. Book", FAReclassJournalLine3."Depreciation Book Code", DepreciationBookCodeMustMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateMultipleFACards()
    var
        PurchaseLine: Record "Purchase Line";
        FixedAssetCount: Integer;
    begin
        // [SCENARIO] Test Posting Purchase Invoice when No. of Fixed Asset Cards is greater than 1.

        // [GIVEN] Count number of existing Fixed Assets.
        Initialize();
        FixedAssetCount := GetFACount();

        // [WHEN] Create Fixed Asset
        CreatePostPurchInvoice(PurchaseLine, LibraryRandom.RandInt(5) + 1); // Quantity should be greater than 1.

        // [THEN] Verify that Multiple Fixed Assets were created
        Assert.AreEqual(FixedAssetCount + PurchaseLine."No. of Fixed Asset Cards", GetFACount(), FixedAssetCountError);
        VerifyNewFixedAssets(PurchaseLine."No.", PurchaseLine."No. of Fixed Asset Cards");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSingleFACard()
    var
        PurchaseLine: Record "Purchase Line";
        FixedAssetCount: Integer;
    begin
        // [SCENARIO] Test Posting Purchase Invoice when No. of Fixed Asset Cards is 1.

        // [GIVEN] Count number of existing Fixed Assets.
        Initialize();
        FixedAssetCount := GetFACount();

        // [WHEN] Create Purchase Invoice with "No. of Fixed Asset Cards" is 1
        CreatePostPurchInvoice(PurchaseLine, 1);

        // [THEN] Verify that Additonal Fixed Assets were not created.
        Assert.AreEqual(FixedAssetCount + PurchaseLine."No. of Fixed Asset Cards", GetFACount(), FixedAssetCountError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateZeroFACard()
    var
        PurchaseLine: Record "Purchase Line";
        FixedAssetCount: Integer;
    begin
        // [SCENARIO] Posting Purchase Invoice when No. of Fixed Asset Cards is 0.

        // [GIVEN] Count number of existing Fixed Assets.
        Initialize();
        FixedAssetCount := GetFACount();

        // [WHEN] Create Purchase Invoice with "No. of Fixed Asset Cards" is 0
        CreatePostPurchInvoice(PurchaseLine, 0);

        // [THEN] Verify that Additonal Fixed Assets were not created.
        Assert.AreEqual(FixedAssetCount + PurchaseLine.Quantity, GetFACount(), FixedAssetCountError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateMultipleFACardsWithDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
    begin
        // [SCENARIO] Test Copy of dimensions on FA when No. of Fixed Asset Cards is greater than 1.
        Initialize();

        // [GIVEN] Create Purchase Line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());

        // [GIVEN] Create Purchase Line with default dimensions
        CreatePurchLineWithDefaultDimensions(PurchaseLine, PurchaseHeader, GetDefaultDepreciationBook(), CreateFAPostingGroup(), 2);

        // [WHEN] Post Purchase Header
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        //CreatePostPurchInvoice(PurchaseLine, LibraryRandom.RandInt(5) + 1); // Quantity should be greater than 1.

        // [THEN] Count dimension on initial Fixed Asset
        FixedAsset.Get(PurchaseLine."No.");
        DefaultDimension.SetRange("Table ID", DATABASE::"Fixed Asset");
        DefaultDimension.SetRange("No.", FixedAsset."No.");

        // [THEN] Count dimension on copied Fixed Asset
        FixedAsset2.SetRange(Description, FixedAsset."No.");
        FixedAsset2.FindFirst();
        DefaultDimension2.SetRange("Table ID", DATABASE::"Fixed Asset");
        DefaultDimension2.SetRange("No.", FixedAsset2."No.");

        // [VERIFY] Verify that dimensions are created
        Assert.AreEqual(DefaultDimension.Count, DefaultDimension2.Count, DimValueError);
    end;

    local procedure Initialize()
    var
        DimValue: Record "Dimension Value";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Fixed Assets");
        // Use global variables for Test Request Page Handler.
        NoOfYears := 0;
        Clear(DepreciationBookCode2);
        Clear(FixedAssetNo2);
        Clear(GenJournalTemplateName);
        Clear(GenJournalBatchName);
        Clear(FAJournalTemplateName);
        Clear(FAJournalBatchName);
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets");

        // Trigger update of global dimension setup in general ledger
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue);

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateFAJnlTemplateName(); // Bug #328391
        LibraryERMCountryData.UpdateFAPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"FA Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets");
    end;

    [Normal]
    local procedure FADepreciationBookSetMethod(var FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Record "FA Posting Group"; FADepreciationMethod: Enum "FA Depreciation Method")
    begin
        FADepreciationBook.Validate("Depreciation Method", FADepreciationMethod);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Modify(true);
    end;

    local procedure SellFixedAsset(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", CalcDate('<1D>', WorkDate()));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, FANo, DepreciationBookCode);
    end;

    local procedure CreateAppreciationAccount(PurchHeader: Record "Purchase Header"; FAPostingGroupCode: Code[20]; var GLAccount: Record "G/L Account")
    var
        FAPostingGroup: Record "FA Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, PurchHeader."Gen. Bus. Posting Group", GenProductPostingGroup.Code);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);

        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        GLAccount.Modify();

        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup."Appreciation Account" := GLAccount."No.";
        FAPostingGroup.Modify();
    end;

    local procedure CreateAndPostFAJournalLine(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]) DocumentNo: Code[20]
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAssetNo, DepreciationBookCode,
          LibraryRandom.RandDecInRange(10000, 20000, 2));  // Use random value for Amount.
        DocumentNo := FAJournalLine."Document No.";
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateDepreciationTable(var DepreciationTableHeader: Record "Depreciation Table Header")
    begin
        LibraryFixedAsset.CreateDepreciationTableHeader(DepreciationTableHeader);
        DepreciationTableHeader.Validate("Period Length", DepreciationTableHeader."Period Length"::Year);
        DepreciationTableHeader.Modify(true);
    end;

    local procedure CreateDeprBookPartOfDuplicationList(var DepreciationBook: Record "Depreciation Book")
    begin
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("Part of Duplication List", true);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBook(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Random Number Generator for Ending date.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFixedAssetSetup(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
        UpdateFAPostingTypeSetup(DepreciationBook.Code);
    end;

    local procedure CreateFixedAssetSetupWDefaultEndingBookValue(var DepreciationBook: Record "Depreciation Book"; DefaultValue: Decimal)
    begin
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook.Validate("Default Ending Book Value", DefaultValue);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateFixedAssetSetupWDefaultFinalRoundingAmount(var DepreciationBook: Record "Depreciation Book"; DefaultValue: Decimal)
    begin
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook.Validate("Default Final Rounding Amount", DefaultValue);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBookWEndingBookValue(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; Value: Decimal)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Ending Book Value", Value);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBookWFinalRoundingAmount(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; Value: Decimal)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Final Rounding Amount", Value);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAAndDuplListSetup(var FANo: Code[20]; var DeprBookCode: Code[10]; var DuplListDeprBookCode: Code[10]; AcqCostGLIntegration: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        DuplListDeprBook: Record "Depreciation Book";
    begin
        CreateFixedAssetWithSetup(FixedAsset, DeprBook);
        CreateDeprBookPartOfDuplicationList(DuplListDeprBook);
        CreateFADepreciationBook(FixedAsset."No.", DuplListDeprBook.Code, FixedAsset."FA Posting Group");
        SetupAcqCostGLIntegration(DeprBook, AcqCostGLIntegration);
        SetupAcqCostGLIntegration(DuplListDeprBook, AcqCostGLIntegration);
        FANo := FixedAsset."No.";
        DeprBookCode := DeprBook.Code;
        DuplListDeprBookCode := DuplListDeprBook.Code;
    end;

    local procedure CreateInactiveFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate(Inactive, true);
        FixedAsset.Modify(true);
    end;

    local procedure CreateMultipleFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        // Using Random Number Generator for Amount.
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          FANo, DepreciationBookCode, LibraryRandom.RandIntInRange(1000, 2000));
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Write-Down",
          FANo, DepreciationBookCode, -LibraryRandom.RandDec(100, 2));
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Custom 1",
          FANo, DepreciationBookCode, -LibraryRandom.RandDec(100, 2));
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Custom 2",
          FANo, DepreciationBookCode, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch"; FAPostingType: Enum "FA Journal Line FA Posting Type"; FANo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document Type", FAJournalLine."Document Type"::" ");
        FAJournalLine.Validate("Document No.", FAJournalLine."Journal Batch Name" + Format(FAJournalLine."Line No."));
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", '');
        FAJournalBatch.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
        // Using Random Number Generator for Amount and Quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Depreciation Book Code", DepreciationBookCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
        // Using Random Number Generator for Amount and Quantity.
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Depreciation Book Code", DepreciationBookCode);
        PurchLine.Validate("Use Duplication List", true);
        PurchLine.Modify(true);
    end;

    local procedure CreateFixedAssetWithSetup(var FixedAsset: Record "Fixed Asset"; var DepreciationBook: Record "Depreciation Book")
    begin
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);
    end;

    local procedure CreateFixedAssetWithSubclass(var FixedAsset: Record "Fixed Asset"; var FADepreciationBook: Record "FA Depreciation Book")
    var
        DepreciationBook: Record "Depreciation Book";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FixedAsset."FA Posting Group");
        FixedAsset.Validate("FA Subclass Code", FASubclass.Code);
        FixedAsset.Modify(true);

        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAWithBookGrossAndNetDisposal(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Disposal Calculation Method", DepreciationBook."Disposal Calculation Method"::Gross);
        DepreciationBook.Modify(true);
        UpdateIntegrationInBook(DepreciationBook, true, true, true);
        UpdateFAPostingTypeSetup(DepreciationBook.Code);

        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(5));
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreateAndPostAcqCostAndWriteDownFAJnlLines(FANo: Code[20]; DeprBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalBatch(FAJournalBatch);

        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          DeprBookCode, LibraryRandom.RandDec(1000, 2));
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Write-Down", FANo,
          DeprBookCode, -LibraryRandom.RandDec(100, 2));

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateFAJnlLineWithDimensionsAndUseDuplicationList(var FAJnlLine: Record "FA Journal Line"; var ShortcutDimValueCode: array[2] of Code[20]; FANo: Code[20]; DeprBookCode: Code[10])
    var
        FAJnlBatch: Record "FA Journal Batch";
        DimValue: Record "Dimension Value";
    begin
        CreateFAJournalBatch(FAJnlBatch);
        CreateFAJournalLine(
          FAJnlLine, FAJnlBatch, FAJnlLine."FA Posting Type"::"Acquisition Cost", FANo, DeprBookCode, LibraryRandom.RandInt(100));
        FAJnlLine.Validate("Use Duplication List", true);
        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(1));
        FAJnlLine.Validate("Shortcut Dimension 1 Code", DimValue.Code);
        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(2));
        FAJnlLine.Validate("Shortcut Dimension 2 Code", DimValue.Code);
        FAJnlLine.Modify(true);
        ShortcutDimValueCode[1] := FAJnlLine."Shortcut Dimension 1 Code";
        ShortcutDimValueCode[2] := FAJnlLine."Shortcut Dimension 2 Code";
    end;

    local procedure CreateGenJnlLineWithDimensionsAndUseDuplicationList(var GenJnlLine: Record "Gen. Journal Line"; var ShortcutDimValueCode: array[2] of Code[20]; FANo: Code[20]; DeprBookCode: Code[10])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        DimValue: Record "Dimension Value";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::" ",
          GenJnlLine."Account Type"::"Fixed Asset", FANo, GenJnlLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandInt(100));
        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::"Acquisition Cost");
        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
        GenJnlLine.Validate("Use Duplication List", true);
        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(1));
        GenJnlLine.Validate("Shortcut Dimension 1 Code", DimValue.Code);
        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(2));
        GenJnlLine.Validate("Shortcut Dimension 2 Code", DimValue.Code);
        GenJnlLine.Modify(true);
        ShortcutDimValueCode[1] := GenJnlLine."Shortcut Dimension 1 Code";
        ShortcutDimValueCode[2] := GenJnlLine."Shortcut Dimension 2 Code";
    end;

    local procedure CreatePostFixedAssetSalesInvoice(PostingDate: Date; FANo: Code[20]; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, 1);
        SalesLine.Validate("Depreciation Book Code", GetFADeprBookCode(FANo));
        SalesLine.Validate("Depr. until FA Posting Date", true);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePurchInvoiceWithTwoFixedAsset(var PurchaseHeader: Record "Purchase Header"; var FixedAsset: Record "Fixed Asset"; DeprUntilPostingDate1: Boolean; DeprUntilPostingDate2: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateFixedAssetSetup(DepreciationBook);
        CreateFixedAssetWithSetup(FixedAsset, DepreciationBook);
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Depr. until FA Posting Date", DeprUntilPostingDate1);
        PurchaseLine.Modify(true);

        Clear(PurchaseLine);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Depr. until FA Posting Date", DeprUntilPostingDate2);
        PurchaseLine.Modify(true);
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; OrderNo: Code[20])
    begin
        ReturnReceiptLine.SetRange("Return Order No.", OrderNo);
        ReturnReceiptLine.FindFirst();
    end;

    local procedure FindPurchReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindPurchReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ReturnOrderNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure GenerateFixedAssetNo(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(FixedAsset.FieldNo("No."), DATABASE::"Fixed Asset"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Fixed Asset", FixedAsset.FieldNo("No."))));
    end;

    local procedure GetFALedgerEntryAmount(DocumentNo: Code[20]; FANo: Code[20]): Decimal
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
        exit(FALedgerEntry.Amount);
    end;

    local procedure GetVATEntryAmount(VATEntry: Record "VAT Entry"): Decimal
    begin
        if VATEntry.Amount <> 0 then
            exit(VATEntry.Amount);
        exit(VATEntry."Unrealized Amount");
    end;

    local procedure GetFASalesAccOnDispLoss(FANo: Code[20]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FixedAsset.Get(FANo);
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        exit(FAPostingGroup."Sales Acc. on Disp. (Loss)");
    end;

    local procedure GetFADeprBookCode(FANo: Code[20]): Code[10]
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.FindFirst();
        exit(FADepreciationBook."Depreciation Book Code");
    end;

    local procedure ModifyIntegrationInBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Modify(true);
    end;

    local procedure FindSalesInvoiceGLEntryWithVATAmount(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; VATAmount: Decimal)
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Sale);
        GLEntry.SetRange("VAT Amount", VATAmount);
        GLEntry.FindFirst();
    end;

    local procedure FindSalesInvoiceVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GenPostingType: Enum "General Posting Type"; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GenPostingType: Enum "General Posting Type")
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, GenPostingType);
        VATEntry.FindFirst();
    end;

    local procedure OpenFAJnlSetupFromDepBook(DepreciationBookCode: Code[10])
    var
        DepreciationBookCard: TestPage "Depreciation Book Card";
    begin
        DepreciationBookCard.OpenView();
        DepreciationBookCard.FILTER.SetFilter(Code, DepreciationBookCode);
        DepreciationBookCard."FA &Journal Setup".Invoke();
    end;

    local procedure PostDepreciationWithDocumentNo(DepreciationBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        FAJournalLine.SetRange("Journal Template Name", FAJournalSetup."FA Jnl. Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalSetup."FA Jnl. Batch Name");
        FAJournalLine.FindFirst();

        FAJournalBatch.Get(FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name");
        FAJournalBatch.Validate("No. Series", '');
        FAJournalBatch.Modify(true);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure PrepareFAForSalesDocument(var FixedAsset: Record "Fixed Asset"; var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code, false);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);
        ModifyIntegrationInBook(DepreciationBook);
    end;

    local procedure RunCalculateDepreciation(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; BalAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", FixedAssetNo);

        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, CalcDate('<1D>', WorkDate()), false, 0, CalcDate('<1D>', WorkDate()), FixedAssetNo, FixedAsset.Description, BalAccount);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure RunCopyFixedAsset(FANo: Code[20]; CopyFromFANo: Code[20]; NoOfFixedAssetCopied: Integer; FirstFANo: Code[20]; UseFANoSeries: Boolean)
    var
        CopyFixedAsset: Report "Copy Fixed Asset";
    begin
        Clear(CopyFixedAsset);
        CopyFixedAsset.SetFANo(FANo);
        CopyFixedAsset.InitializeRequest(CopyFromFANo, NoOfFixedAssetCopied, FirstFANo, UseFANoSeries);
        CopyFixedAsset.UseRequestPage(false);
        CopyFixedAsset.Run();
    end;

    local procedure RunCreateFADepreciationBooks(var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; FixedAssetNo: Code[20])
    var
        CreateFADepreciationBooks: Report "Create FA Depreciation Books";
    begin
        DepreciationBookCode2 := DepreciationBookCode;
        FixedAssetNo2 := FixedAssetNo;
        Clear(CreateFADepreciationBooks);
        CreateFADepreciationBooks.SetTableView(FixedAsset);
        Commit();
        CreateFADepreciationBooks.Run();
    end;

    local procedure SetupPartialIntegrationInBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("Allow Correction of Disposal", true);
        DepreciationBook.Validate("G/L Integration - Disposal", false);
        DepreciationBook.Modify(true);
    end;

    local procedure SetDeprTypeFAPostingTypeSetupWriteDown(DeprBookCode: Code[10])
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
        FAPostingTypeSetup.Validate("Depreciation Type", true);
        FAPostingTypeSetup.Modify(true);
    end;

    local procedure SetupAcqCostGLIntegration(var DeprBook: Record "Depreciation Book"; AcqCostGLIntegration: Boolean)
    begin
        DeprBook.Validate("G/L Integration - Acq. Cost", AcqCostGLIntegration);
        DeprBook.Modify(true);
    end;

    local procedure ResetDeprTypeFAPostingTypeSetupWriteDown(DeprBookCode: Code[10])
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
        FAPostingTypeSetup.Validate("Depreciation Type", false);
        FAPostingTypeSetup.Modify(true);
    end;

    local procedure UpdateIntegrationInBook(var DepreciationBook: Record "Depreciation Book"; Depreciation: Boolean; Disposal: Boolean; VATOnNetDisposalEntries: Boolean)
    begin
        DepreciationBook.Validate("G/L Integration - Acq. Cost", false);
        DepreciationBook.Validate("G/L Integration - Depreciation", Depreciation);
        DepreciationBook.Validate("G/L Integration - Write-Down", false);
        DepreciationBook.Validate("G/L Integration - Appreciation", false);
        DepreciationBook.Validate("G/L Integration - Disposal", Disposal);
        DepreciationBook.Validate("G/L Integration - Custom 1", false);
        DepreciationBook.Validate("G/L Integration - Custom 2", false);
        DepreciationBook.Validate("G/L Integration - Maintenance", false);
        DepreciationBook.Validate("VAT on Net Disposal Entries", VATOnNetDisposalEntries);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateAllowCorrectionInBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("Allow Correction of Disposal", true);
        DepreciationBook.Modify(true);
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

    local procedure UpdateDeprBookVATNetDisposal(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("VAT on Net Disposal Entries", true);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateFAPostingTypeSetup(DepreciationBookCode: Code[10])
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        FAPostingTypeSetup.SetRange("Depreciation Book Code", DepreciationBookCode);
        FAPostingTypeSetup.ModifyAll("Include in Gain/Loss Calc.", true);
    end;

    local procedure UpdateFiscalYear365DaysOnDepreciationBook(DepreciationBookCode: Code[10]; FiscalYear365Days: Boolean)
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("Fiscal Year 365 Days", FiscalYear365Days);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateStartingDateOnFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationStartingDate: Date)
    begin
        FADepreciationBook.Validate("Depreciation Starting Date", DepreciationStartingDate);
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateEndingDateOnFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationEndingDate: Date)
    begin
        FADepreciationBook.Validate("Depreciation Ending Date", DepreciationEndingDate);
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateDepreciationMethodOnFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationMethod: Enum "FA Depreciation Method")
    begin
        FADepreciationBook.Validate("Depreciation Method", DepreciationMethod);
        FADepreciationBook.Modify(true);
    end;

    local procedure VerifyAcquisitionFALedgerEntry(FANo: Code[20]; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyFALedgerEntry(FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField("Depreciation Book Code", DepreciationBookCode)
    end;

    local procedure VerifySalesFALedgerEntry(DocumentNo: Code[20]; FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; ExpectedAmount: Decimal; Debit: Decimal; Credit: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("Document Type", FALedgerEntry."Document Type"::Invoice);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField("FA No.", FANo);
        FALedgerEntry.TestField(Amount, ExpectedAmount);
        FALedgerEntry.TestField("Debit Amount", Debit);
        FALedgerEntry.TestField("Credit Amount", Credit);
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

    local procedure VerifyAmountInFALedgerEntry(FANo: Code[20]; FALedgerEntryFAPostingType: Enum "FA Ledger Entry FA Posting Type"; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntryFAPostingType);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyFADepreciationBook(FANo: Code[20]; DocumentNo: Code[20]; DepreciationBookCode: Code[10])
    var
        FADepreciationBook: Record "FA Depreciation Book";
        Amount: Decimal;
    begin
        Amount := GetFALedgerEntryAmount(DocumentNo, FANo);
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.SetRange("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.FindFirst();
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook.CalcFields("Acquisition Cost");
        FADepreciationBook.TestField("Book Value", Amount);
        FADepreciationBook.TestField("Acquisition Cost", Amount);
    end;

    local procedure VerifyMaintenanceLedgerEntry(FANo: Code[20]; Amount: Decimal)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        MaintenanceLedgerEntry.FindFirst();
        MaintenanceLedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyFALedgEntryDeprDays(FANo: Code[20]; DeprBookCode: Code[10]; ExpectedDeprDays: Integer)
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
        FALedgEntry.FindFirst();
        Assert.AreEqual(ExpectedDeprDays, FALedgEntry."No. of Depreciation Days", WrongDeprDaysErr);
    end;

    local procedure VerifyFAJnlLineDimUseDuplicationList(DuplicatedDeprBookCode: Code[10]; ShortcutDimValueCode: array[2] of Code[20])
    var
        DuplicatedFAJnlLine: Record "FA Journal Line";
    begin
        DuplicatedFAJnlLine.SetRange("Depreciation Book Code", DuplicatedDeprBookCode);
        DuplicatedFAJnlLine.FindFirst();
        Assert.AreEqual(
          ShortcutDimValueCode[1], DuplicatedFAJnlLine."Shortcut Dimension 1 Code",
          DuplicatedFAJnlLine.FieldCaption("Shortcut Dimension 1 Code"));
        Assert.AreEqual(
          ShortcutDimValueCode[2], DuplicatedFAJnlLine."Shortcut Dimension 2 Code",
          DuplicatedFAJnlLine.FieldCaption("Shortcut Dimension 2 Code"));
    end;

    local procedure VerifyGenJnlLineDimUseDuplicationList(DuplicatedDeprBookCode: Code[10]; ShortcutDimValueCode: array[2] of Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Depreciation Book Code", DuplicatedDeprBookCode);
        GenJnlLine.FindFirst();
        Assert.AreEqual(
          ShortcutDimValueCode[1], GenJnlLine."Shortcut Dimension 1 Code",
          GenJnlLine.FieldCaption("Shortcut Dimension 1 Code"));
        Assert.AreEqual(
          ShortcutDimValueCode[2], GenJnlLine."Shortcut Dimension 2 Code",
          GenJnlLine.FieldCaption("Shortcut Dimension 2 Code"));
    end;

    local procedure VerifyUndoShipmentLineOnPostedShipment(SalesLine: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentLine.SetRange(Type, SalesLine.Type);
        SalesShipmentLine.SetRange("No.", SalesLine."No.");
        SalesShipmentLine.FindLast();
        SalesShipmentLine.TestField(Quantity, -1 * SalesLine."Qty. to Ship");
    end;

    local procedure VerifyUndoReceiptLineOnPostedReturnReceipt(SalesLine: Record "Sales Line")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetRange("Return Order No.", SalesLine."Document No.");
        ReturnReceiptLine.SetRange(Type, SalesLine.Type);
        ReturnReceiptLine.SetRange("No.", SalesLine."No.");
        ReturnReceiptLine.FindLast();
        ReturnReceiptLine.TestField(Quantity, -1 * SalesLine."Return Qty. to Receive");
    end;

    local procedure VerifyUndoReceiptLine(PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange(Type, PurchaseLine.Type);
        PurchRcptLine.SetRange("No.", PurchaseLine."No.");
        PurchRcptLine.FindLast();
        PurchRcptLine.TestField(Quantity, -1 * PurchaseLine."Qty. to Receive");
    end;

    local procedure VerifyUndoShipmentLine(PurchaseLine: Record "Purchase Line")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Return Order No.", PurchaseLine."Document No.");
        ReturnShipmentLine.SetRange(Type, PurchaseLine.Type);
        ReturnShipmentLine.SetRange("No.", PurchaseLine."No.");
        ReturnShipmentLine.FindLast();
        ReturnShipmentLine.TestField(Quantity, -1 * PurchaseLine."Return Qty. to Ship");
    end;

    local procedure FASetupClassesAndSubclasses(var FAClass1: Record "FA Class"; var FASubclass1: Record "FA Subclass"; var FAClass2: Record "FA Class"; var FASubclass2: Record "FA Subclass"; var FASubclass: Record "FA Subclass")
    begin
        FAClass1.DeleteAll();
        FASubclass1.DeleteAll();
        LibraryFixedAsset.CreateFASubclass(FASubclass);
        LibraryFixedAsset.CreateFAClass(FAClass1);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass1, FAClass1.Code, '');
        LibraryFixedAsset.CreateFAClass(FAClass2);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass2, FAClass2.Code, '');
    end;

    local procedure CreateFixedAssetWithFAClassFASubclassFAPostingGroup(var FixedAsset: Record "Fixed Asset"; FAClass: Code[10]; FASubclass: Code[10]; FAPostingGroup: Code[20])
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Class Code", FAClass);
        FixedAsset.Validate("FA Subclass Code", FASubClass);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(var FADepreciationBook: Record "FA Depreciation Book"; var FixedAsset: Record "Fixed Asset"; var DepreciationBook: Record "Depreciation Book"; FAPostingGroup: Code[20]; DepreciationMethod: Enum "FA Depreciation Method"; DepreciationStartingDate: Date; NoOfDepreciationyears: Decimal)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Validate("Acquisition Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Method", DepreciationMethod);
        FADepreciationBook.Validate("Depreciation Starting Date", DepreciationStartingDate);
        FADepreciationBook.Validate("No. of Depreciation Years", NoOfDepreciationyears);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateDepreciationBookwithGLIntegrationAcqCost(var DepreciationBook: Record "Depreciation Book"; GLIntegrationAcqCost: Boolean)
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", GLIntegrationAcqCost);
        DepreciationBook.Modify(true);
    end;

    local procedure CreatePurchHeaderWithVendorInvNoAndPostingDate(var PurchaseHeader: Record "Purchase Header"; BuyfromVendorNo: Code[20]; VendorInvNo: Code[35]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, BuyfromVendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchLineWithDirectUnitCost(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchaseLineType: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLineType, No, Qty);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateDefaultFADepreciationBookWithFAPostingGroupDeprMethodStartDateNoOfYears(var FADepreciationBook: Record "FA Depreciation Book"; var FixedAsset: Record "Fixed Asset"; var DepreciationBook: Record "Depreciation Book"; FAPostingGroup: Code[20]; DepreciationMethod: Enum "FA Depreciation Method"; DepreciationStartingDate: Date; NoOfDepreciationyears: Decimal)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Validate("Acquisition Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Method", DepreciationMethod);
        FADepreciationBook.Validate("Depreciation Starting Date", DepreciationStartingDate);
        FADepreciationBook.Validate("No. of Depreciation Years", NoOfDepreciationyears);
        FADepreciationBook.Validate("Default FA Depreciation Book", true);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateSalesHeaderWithCustomerNoAndPostingDate(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineWithDirectUnitCost(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineType: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, No, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount.Modify(true);
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateFAJournalLineWithoutDepreciationBook(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch"; FAPostingType: Enum "FA Journal Line FA Posting Type"; FANo: Code[20]; Amount: Decimal)
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document Type", FAJournalLine."Document Type"::" ");
        FAJournalLine.Validate("Document No.", FAJournalLine."Journal Batch Name" + Format(FAJournalLine."Line No."));
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Modify(true);
    end;

    local procedure GetFACount(): Integer
    var
        FixedAsset: Record "Fixed Asset";
    begin
        exit(FixedAsset.Count);
    end;

    local procedure CreatePostPurchInvoice(var PurchaseLine: Record "Purchase Line"; NoOfFACards: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        CreatePurchLine(PurchaseLine, PurchaseHeader, GetDefaultDepreciationBook(), CreateFAPostingGroup(), NoOfFACards);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure GetDefaultDepreciationBook(): Code[10]
    var
        FASetup: Record "FA Setup";
        DepreciationBook: Record "Depreciation Book";
    begin
        FASetup.Get();
        DepreciationBook.Get(FASetup."Default Depr. Book");
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);
        exit(FASetup."Default Depr. Book");
    end;

    local procedure CreateFAPostingGroup(): Code[20]
    var
        FAPostingGroup: Record "FA Posting Group";
        FAPostingGroup2: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GetFAPostingGroup(FAPostingGroup2);
        FAPostingGroup.Validate("Acquisition Cost Account", FAPostingGroup2."Acquisition Cost Account");
        FAPostingGroup.Validate("Accum. Depreciation Account", FAPostingGroup2."Accum. Depreciation Account");
        FAPostingGroup.Validate("Depreciation Expense Acc.", FAPostingGroup2."Depreciation Expense Acc.");
        FAPostingGroup.Validate("Custom 1 Account", CreateGLAccount());
        FAPostingGroup.Validate("Custom 1 Expense Acc.", CreateGLAccount());
        FAPostingGroup.Validate("Custom 2 Account", CreateGLAccount());
        FAPostingGroup.Validate("Custom 2 Expense Acc.", CreateGLAccount());
        FAPostingGroup.Modify(true);
        exit(FAPostingGroup.Code);
    end;

    local procedure GetFAPostingGroup(var FAPostingGroup: Record "FA Posting Group"): Boolean
    begin
        FAPostingGroup.SetFilter("Acquisition Cost Account", '<>''''');
        FAPostingGroup.SetFilter("Accum. Depreciation Account", '<>''''');
        FAPostingGroup.SetFilter("Depreciation Expense Acc.", '<>''''');
        exit(FAPostingGroup.FindFirst())
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; DepreciationBook: Code[10]; FAPostingGroup: Code[20]; NoOfFACards: Integer): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateFA(FixedAsset, DepreciationBook, FAPostingGroup);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", 1);
        UpdatePurchaseLine(PurchaseLine, DepreciationBook, NoOfFACards);
        exit(FixedAsset."No.");
    end;

    local procedure CreatePurchLineWithDefaultDimensions(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; DepreciationBook: Code[10]; FAPostingGroup: Code[20]; NoOfFACards: Integer): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateFAWithDefaultDimensions(FixedAsset, DepreciationBook, FAPostingGroup);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", 1);
        UpdatePurchaseLine(PurchaseLine, DepreciationBook, NoOfFACards);
        exit(FixedAsset."No.");
    end;

    local procedure CreateFA(var FixedAsset: Record "Fixed Asset"; DepreciationBook: Code[10]; FAPostingGroup: Code[20])
    var
        DimValue: Record "Dimension Value";
    begin
        Clear(FixedAsset);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook, FAPostingGroup);

        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(1));
        FixedAsset.Validate("Global Dimension 1 Code", DimValue.Code);
        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(2));
        FixedAsset.Validate("Global Dimension 2 Code", DimValue.Code);
    end;

    local procedure CreateFAWithDefaultDimensions(var FixedAsset: Record "Fixed Asset"; DepreciationBook: Code[10]; FAPostingGroup: Code[20])
    var
        DimValue: Record "Dimension Value";
    begin
        CreateFA(FixedAsset, DepreciationBook, FAPostingGroup);

        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(1));
        FixedAsset.Validate("Global Dimension 1 Code", DimValue.Code);
        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(2));
        FixedAsset.Validate("Global Dimension 2 Code", DimValue.Code);
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; DepreciationBook: Code[10]; NoOfFixedAssetCards: Integer)
    begin
        PurchaseLine.Validate("Depreciation Book Code", DepreciationBook);
        PurchaseLine.Validate("No. of Fixed Asset Cards", NoOfFixedAssetCards);
        if NoOfFixedAssetCards > PurchaseLine.Quantity then
            PurchaseLine.Validate("Direct Unit Cost", NoOfFixedAssetCards * LibraryRandom.RandInt(10) * 10000) // Cost is not important.
        else
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10) * 10000); // Cost is not important.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure VerifyNewFixedAssets(FixedAssetNo: Code[20]; Quantity: Integer)
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
    begin
        // Find Initial Fixed Asset.
        FixedAsset.Get(FixedAssetNo);
        FixedAsset.SetFilter(Description, FixedAsset.Description);

        // Verify that Description field was copied for new Fixed Assets.
        Assert.AreEqual(Quantity, FixedAsset.Count, FixedAssetCountError);
        FixedAsset.FindSet();

        // Find FA Deprecition Book for the initial Fixed Asset.
        FADepreciationBook2.SetFilter("FA No.", FixedAssetNo);
        FADepreciationBook2.FindFirst();
        FADepreciationBook2.CalcFields("Acquisition Cost");

        // Verify Depreciation Method, FA Posting Group, Acquisition Cost.
        repeat
            FADepreciationBook.Get(FixedAsset."No.", FADepreciationBook2."Depreciation Book Code");
            FADepreciationBook.CalcFields("Acquisition Cost");
            FADepreciationBook.TestField("FA Posting Group", FADepreciationBook2."FA Posting Group");
            FADepreciationBook.TestField("Depreciation Method", FADepreciationBook2."Depreciation Method");
            FADepreciationBook.TestField("Depreciation Starting Date", FADepreciationBook2."Depreciation Starting Date");
            FADepreciationBook.TestField("Depreciation Ending Date", FADepreciationBook2."Depreciation Ending Date");
            FADepreciationBook.TestField("Acquisition Cost", FADepreciationBook2."Acquisition Cost");
        until FixedAsset.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FADepreciationBooksHandler(var CreateFADepreciationBooks: TestRequestPage "Create FA Depreciation Books")
    begin
        CreateFADepreciationBooks.DepreciationBook.SetValue(DepreciationBookCode2);
        CreateFADepreciationBooks.CopyFromFANo.SetValue(FixedAssetNo2);
        CreateFADepreciationBooks.OK().Invoke();
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy Messages.
        if Confirm(StrSubstNo(DateConfirmMessage, CalcDate('<1D>', WorkDate()), WorkDate())) then;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandler(var CreateSumOfDigitsTable: TestRequestPage "Create Sum of Digits Table")
    begin
        CreateSumOfDigitsTable.NoOfYears.SetValue(NoOfYears); // Value is important here, No. of Years can not be greater then 200.
        CreateSumOfDigitsTable.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FAJournalSetupGenBatchHandler(var FAJournalSetup: TestPage "FA Journal Setup")
    begin
        FAJournalSetup."Gen. Jnl. Template Name".SetValue(GenJournalTemplateName);
        FAJournalSetup."Gen. Jnl. Batch Name".SetValue(GenJournalBatchName);
        FAJournalSetup."Gen. Jnl. Batch Name".Lookup();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FAJournalSetupFABatchHandler(var FAJournalSetup: TestPage "FA Journal Setup")
    begin
        // Set values on FA Journal Setup page and invoke Lookup on it to open FA Journal Batches page.
        FAJournalSetup."FA Jnl. Template Name".SetValue(FAJournalTemplateName);
        FAJournalSetup."FA Jnl. Batch Name".SetValue(FAJournalBatchName);
        FAJournalSetup."FA Jnl. Batch Name".Lookup();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalBatchesHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.Name.AssertEquals(GenJournalBatchName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FAJournalBatchesHandler(var FAJournalBatches: TestPage "FA Journal Batches")
    begin
        FAJournalBatches.Name.AssertEquals(FAJournalBatchName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if 0 <> StrPos(Question, CompletionStatsTok) then begin
            Assert.ExpectedMessage(CompletionStatsFAJnlQst, Question);
            Reply := false;
        end else
            Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(CompletionStatsMsg, Message);
    end;

    [SendNotificationHandler]
    procedure EnqueueMessageSendNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}
