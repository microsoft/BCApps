codeunit 144003 "ERM Payment Journal"
{
    // // [FEATURE] [EB Payment Journal] [Vendor]
    //  1. Test case for bug 338685
    //  2. Test case for bug 338683
    //  3. Test case for bug 338679
    //  4. Test case for bug Sicily 50656
    //  5. DimensionPosting_MainLine
    //  6. DimensionPosting_BalanceLine
    //  7. Test to verify that Payment Journal exports lines without errors when Batch name contains digits.
    //  8. Test case for bug 59011.
    //  9. Test case for bug 91144 (External Document No. field length)
    // 
    // BUG_ID = 55765
    // Cover Test cases:
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                       TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // ExportPmntJnlLinesWithBatchContainingDigits                                                              55765
    // 
    // BUG_ID = 59011
    // Cover Test cases:
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                       TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // CheckExportedPaymentJournalLines                                                                         59011
    // SuggestVendorPaymentWithExternalDocumentNo                                                               91144

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        refExportProtocolType: Option Domestic,International;
        IncorrectNumberOfDimErr: Label 'Incorrect number of dimensions.';
        WrongNumberOfLinesErr: Label 'Wrong number of  Payment Journal Lines.';
        WrongStatusOfLineErr: Label 'Wrong status of Payment Journal Line.';
        WrongStatusOfBatchErr: Label 'Wrong status of Payment Journal Batch.';
        LettersTxt: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure VendorInvoiceAndVendorCrMemo()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        CrMemoNo: Code[20];
        ExportProtocolCode: Code[20];
    begin
        // Test case for bug 338685
        // setup
        InitTwoVendorEntriesScenario(GenJnlLine, GenJnlBatch, PaymentJnlLine, CrMemoNo, ExportProtocolCode, false);

        // exercise
        PostPaymentJournal(GenJnlLine, PaymentJnlLine, ExportProtocolCode);

        // verify
        VerifyCrMemoGenJnlLine(GenJnlBatch, CrMemoNo, GenJnlLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustInvoiceAndCustCrMemo()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        ExportProtocolCode: Code[20];
    begin
        // Test case for bug 338683
        // setup
        InitTwoCustomerEntriesScenario(GenJnlLine, GenJnlBatch, PaymentJnlLine, ExportProtocolCode);

        // exercise
        PostPaymentJournal(GenJnlLine, PaymentJnlLine, ExportProtocolCode);

        // verify
        VerifyCrMemoGenJnlLine2(GenJnlBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustCrMemoAndVendInvoice()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        CrMemoNo: Code[20];
        ExportProtocolCode: Code[20];
    begin
        // Test case for bug 338679
        // Updated by TFS ID 221119
        // setup
        InitCustAndVendScenario(GenJnlLine, GenJnlBatch, PaymentJnlLine, CrMemoNo, ExportProtocolCode);

        // exercise
        PostPaymentJournal(GenJnlLine, PaymentJnlLine, ExportProtocolCode);

        // verify
        VerifyCrMemoGenJnlLine(GenJnlBatch, CrMemoNo, GenJnlLine."Document Type"::Refund);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCrMemoAndVendorInvoice()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        CrMemoNo: Code[20];
        ExportProtocolCode: Code[20];
    begin
        // Test case for bug Sicily 50656
        // setup
        InitTwoVendorEntriesScenario(GenJnlLine, GenJnlBatch, PaymentJnlLine, CrMemoNo, ExportProtocolCode, true);

        // exercise
        PostPaymentJournal(GenJnlLine, PaymentJnlLine, ExportProtocolCode);

        // verify
        PaymentJnlLine.Find();
        VerifyGenJnlLineApplyToID(GenJnlBatch, PaymentJnlLine."Account No.", PaymentJnlLine."Applies-to ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionPosting_MainLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        DimValue: Record "Dimension Value";
        ExportProtocolCode: Code[20];
    begin
        // setup
        InitDimPostScenario(GenJnlLine, GenJnlBatch, PaymentJnlLine, ExportProtocolCode, DimValue);

        // exercise
        PostPaymentJournal(GenJnlLine, PaymentJnlLine, ExportProtocolCode);

        // verify
        VerifyGenJnlLineDim(GenJnlBatch, DimValue, PaymentJnlLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionPosting_BalanceLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        PaymentJnlLine: Record "Payment Journal Line";
        DimValue: Record "Dimension Value";
        ExportProtocolCode: Code[20];
    begin
        // setup
        InitDimPostScenario(GenJnlLine, GenJnlBatch, PaymentJnlLine, ExportProtocolCode, DimValue);
        UpdateGLAccountDefaultDim(GenJnlBatch."Bal. Account No.", DimValue);

        // exercise
        PostPaymentJournal(GenJnlLine, PaymentJnlLine, ExportProtocolCode);

        // verify
        VerifyGenJnlLineDim(GenJnlBatch, DimValue, GenJnlBatch."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('ExportPaymentJournalLinesHandler')]
    [Scope('OnPrem')]
    procedure ExportPmntJnlLinesWithBatchContainingDigits()
    var
        TemplateName: Code[10];
        BatchName: Code[10];
        ExpProtCodeDomestic: Code[20];
        ExpProtCodeInternational: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 232996] Information from Bank Account represented in exported "File Domestic Payments" from Payment Journal
        // Test to verify that Payment Journal exports lines without errors when Batch name contains digits
        Initialize();

        // [GIVEN] Bank Account with length of "No." = max length of field.
        BankAccountNo := CreateBankAccountMod97Compliant();

        // [GIVEN] Payment Journal with lines
        InitExportBatchContainingDigitsScenario(
          TemplateName, BatchName, ExpProtCodeDomestic, ExpProtCodeInternational, false, BankAccountNo);

        // [WHEN] Export Payment Journal, include dimensions
        ExportPaymentJournalLinesIncludeDims(TemplateName, BatchName, ExpProtCodeDomestic);

        // [THEN] Exported lines and Journal Batch status set to 'Posted', rest of lines are renamed to next Batch.
        VerifyPaymentJournalLinesStatusChangedAndRenamed(TemplateName, BatchName);

        // [THEN] Exported lines contains "Bank Account No." and "Bank Branch No."
        ValidateDomesticReportXml(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('ExportPaymentJournalLinesHandler,TemplatesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckExportedPaymentJournalLines()
    var
        TemplateName: Code[10];
        BatchNameDigits: Code[10];
        BatchNameNoDigits: Code[10];
        ExpProtCodeDomestic: Code[20];
        ExpProtCodeInternational: Code[20];
        BankAccountNo: Code[20];
    begin
        // Test case for bug 59011.

        // Setup
        Initialize();
        BankAccountNo := CreateBankAccountMod97Compliant();
        InitExportBatchesScenario(
          TemplateName, BatchNameDigits, BatchNameNoDigits, ExpProtCodeDomestic, ExpProtCodeInternational, false, BankAccountNo);

        // Exercise
        ExportPaymentJournalLinesViaPage(BatchNameDigits, ExpProtCodeDomestic);

        // Verify
        VerifyPaymentJournalLinesStatusNotChanged(TemplateName, BatchNameNoDigits);
        ValidateDomesticReportXml(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('ExportPaymentJournalLinesInternationalHandler')]
    [Scope('OnPrem')]
    procedure ExportPmntJnlLinesWithBatchContainingDigitsInternational()
    var
        TemplateName: Code[10];
        BatchName: Code[10];
        ExpProtCodeDomestic: Code[20];
        ExpProtCodeInternational: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 232996] Information from Bank Account represented in exported "File International Payments" from Payment Journal
        // Test to verify that Payment Journal exports lines without errors when Batch name contains digits
        Initialize();

        // [GIVEN] Bank Account with length of "No." = max length of field.
        BankAccountNo := CreateBankAccountMod97Compliant();

        // [GIVEN] Payment Journal with lines
        InitExportBatchContainingDigitsScenario(
          TemplateName, BatchName, ExpProtCodeDomestic, ExpProtCodeInternational, true, BankAccountNo);

        // [WHEN] Export Payment Journal, include dimensions
        ExportPaymentJournalLinesIncludeDims(TemplateName, BatchName, ExpProtCodeInternational);

        // [THEN] Exported lines and Journal Batch status set to 'Posted', rest of lines are renamed to next Batch.
        VerifyPaymentJournalLinesStatusChangedAndRenamed(TemplateName, BatchName);

        // [THEN] Exported lines contains "Bank Account No." and "Bank Branch No."
        ValidateInternationalReportXml(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('ExportPaymentJournalLinesInternationalHandler,TemplatesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckExportedPaymentJournalLinesInternational()
    var
        TemplateName: Code[10];
        BatchNameDigits: Code[10];
        BatchNameNoDigits: Code[10];
        ExpProtCodeDomestic: Code[20];
        ExpProtCodeInternational: Code[20];
        BankAccountNo: Code[20];
    begin
        // Test case for bug 59011.

        // Setup
        Initialize();
        BankAccountNo := CreateBankAccountMod97Compliant();
        InitExportBatchesScenario(TemplateName, BatchNameDigits, BatchNameNoDigits, ExpProtCodeDomestic,
          ExpProtCodeInternational, true, BankAccountNo);

        // Exercise
        ExportPaymentJournalLinesViaPage(BatchNameDigits, ExpProtCodeInternational);

        // Verify
        VerifyPaymentJournalLinesStatusNotChanged(TemplateName, BatchNameNoDigits);
        ValidateInternationalReportXml(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsEBRPH')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithExternalDocumentNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        Initialize();

        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        SuggestVendorPayments(PurchaseHeader."Buy-from Vendor No.");

        VerifyNumberAndStatusOfVendorPaymentJournalLines(
          PurchaseHeader."Buy-from Vendor No.", PaymentJournalLine.Status::Created, 1);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsEBRPH')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithDefaultTableDimension()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentJournalLine: Record "Payment Journal Line";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [FEATURE] [Dimension] [Suggest Vendor Payments EB]
        // [SCENARIO 375587] Default Dimension for Vendor table is used when run "Suggest Vendor Payments EB" report
        Initialize();

        // [GIVEN] Post Purchase Invoice
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create Dimension "X" with value "Y"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Create Default Dimension for "Vendor" table: VendorNo='', DimensionCode = "X", DimensionValue = "Y"
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, '', DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Modify GLSetup."Shortcut Dimension 8 Code" = "X"
        ModifyGLSetupShortcutDimension(DimensionValue."Dimension Code");

        // [WHEN] Run "Suggest Vendor Payments EB" in EB Payment Journal
        SuggestVendorPayments(PurchaseHeader."Buy-from Vendor No.");

        // [THEN] Payment line is created with dimension "Shortcut Dimension 8 Code" value = "Y"
        FilterEBPaymentJournalLine(PaymentJournalLine, PurchaseHeader."Buy-from Vendor No.", PaymentJournalLine.Status::Created);
        PaymentJournalLine.FindFirst();
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PaymentJournalLine."Dimension Set ID");
        Assert.AreEqual(
          DimensionValue.Code, DimensionSetEntry."Dimension Value Code",
          DimensionSetEntry.FieldCaption("Dimension Value Code"));

        // Tear Down
        LibraryDimension.ResetDefaultDimensions(DATABASE::Vendor, '');
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsEBRPH')]
    [Scope('OnPrem')]
    procedure NoMessageWhenNothingSuggestedWithDuplicatedVendLedgEntryDocNo()
    var
        PaymentJournalLine: Record "Payment Journal Line";
        DocumentNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Message]
        // [SCENARIO 259025] When the vendor has positive balance and nothing is suggested, and there are vendor ledger entries with the same DocumentNo and DocumentType,
        // [SCENARIO 259025] there should be no warning message related to already existing open entries in the payment journal.
        Initialize();
        PaymentJournalLine.DeleteAll();

        // [GIVEN] Vendor "V" with overall positive balance and two Vendor Ledger Entries with the same "Document No." and "Document Type".
        VendorNo := LibraryPurchase.CreateVendorNo();
        DocumentNo := LibraryUtility.GenerateGUID();
        MockVendorLedgerEntry(VendorNo, DocumentNo, WorkDate(), LibraryRandom.RandDecInRange(100, 1000, 2));
        MockVendorLedgerEntry(VendorNo, DocumentNo, WorkDate(), LibraryRandom.RandDecInRange(100, 1000, 2));

        // [WHEN] Suggest Vendor Payments for "V".
        SuggestVendorPayments(VendorNo);

        // [THEN] No message was invoked.
        // [THEN] Nothing was suggested.
        Assert.RecordIsEmpty(PaymentJournalLine);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsEBRPH')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithGlobalDimenstion1Filter()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record "Vendor";
        DimensionValue: Record "Dimension Value";
        VendorFilter: Text;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 345305] Check Suggest Vendor Payments report with filter on Vendor."Global Dimension 1 Filter"
        Initialize();

        // [GIVEN] Posted Sales Invoice for Vendor "V1" with Global Dimension 1 = "D".
        // [GIVEN] Posted Sales Invoice for Vendor "V2" with empty Global Dimension 1.
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        CreateVendorWithGlobalDimensions(Vendor, DimensionValue.Code, '');
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] Report Suggest Vendor Payments is run for "V1"|"V2" with Limit Totals on Global Dimension 1 = "D".
        VendorFilter := StrSubstNo('%1|%2', Vendor."No.", PurchaseHeader."Buy-from Vendor No.");
        SuggestVendorPaymentsWithDimFilters(VendorFilter, DimensionValue.Code, '');

        // [THEN] Payment journal line is created only for "V1" with Global Dimension 1 = "D".
        VerifyPaymentJournalLineDimension(VendorFilter, DimensionValue);
    END;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsEBRPH')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithEmptyGlobalDimenstion1Filter()
    var
        PaymentJournalLine: Record "Payment Journal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record "Vendor";
        DimensionValue: Record "Dimension Value";
        VendorFilter: Text;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 345305] Check Suggest Vendor Payments report when filter on Vendor."Global Dimension 1 Filter" is not set.
        Initialize();

        // [GIVEN] Posted Sales Invoice for Vendor "V1" with Global Dimension 1 = "D".
        // [GIVEN] Posted Sales Invoice for Vendor "V2" with empty Global Dimension 1.
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        CreateVendorWithGlobalDimensions(Vendor, DimensionValue.Code, '');
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] Report Suggest Vendor Payments is run for "V1"|"V2" with no filter in Limit Totals on Global Dimension.
        VendorFilter := StrSubstNo('%1|%2', Vendor."No.", PurchaseHeader."Buy-from Vendor No.");
        SuggestVendorPayments(VendorFilter);

        // [THEN] Payment journal lines are created for both "V1" and "V2.
        FilterEBPaymentJournalLine(PaymentJournalLine, VendorFilter, PaymentJournalLine.Status::Created);
        Assert.RecordCount(PaymentJournalLine, 2);
    END;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsEBRPH')]
    [Scope('OnPrem')]
    PROCEDURE SuggestVendorPaymentsWithGlobalDimenstion2Filter()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record "Vendor";
        DimensionValue: Record "Dimension Value";
        VendorFilter: Text;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 345305] Check Suggest Vendor Payments report with filter on Vendor."Global Dimension 2 Filter"
        Initialize();

        // [GIVEN] Posted Sales Invoice for Vendor "V1" with Global Dimension 2 = "D".
        // [GIVEN] Posted Sales Invoice for Vendor "V2" with empty Global Dimension 2.
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        CreateVendorWithGlobalDimensions(Vendor, '', DimensionValue.Code);
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] Report Suggest Vendor Payments is run for "V1"|"V2" with Limit Totals on Global Dimension 2 = "D".
        VendorFilter := StrSubstNo('%1|%2', Vendor."No.", PurchaseHeader."Buy-from Vendor No.");
        SuggestVendorPaymentsWithDimFilters(VendorFilter, '', DimensionValue.Code);

        // [THEN] Payment journal line is created only for "V1" with Global Dimension 2 = "D".
        VerifyPaymentJournalLineDimension(VendorFilter, DimensionValue);
    END;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsEBRPH')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithEmptyGlobalDimenstion2Filter()
    var
        PaymentJournalLine: Record "Payment Journal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record "Vendor";
        DimensionValue: Record "Dimension Value";
        VendorFilter: Text;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 345305] Check Suggest Vendor Payments report when filter on Vendor."Global Dimension 2 Filter" is not set.
        Initialize();

        // [GIVEN] Posted Sales Invoice for Vendor "V1" with Global Dimension 2 = "D".
        // [GIVEN] Posted Sales Invoice for Vendor "V2" with empty Global Dimension 2.
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        CreateVendorWithGlobalDimensions(Vendor, '', DimensionValue.Code);
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] Report Suggest Vendor Payments is run for "V1"|"V2" with no filter in Limit Totals on Global Dimension.
        VendorFilter := StrSubstNo('%1|%2', Vendor."No.", PurchaseHeader."Buy-from Vendor No.");
        SuggestVendorPayments(VendorFilter);

        // [THEN] Payment journal lines are created for both "V1" and "V2.
        FilterEBPaymentJournalLine(PaymentJournalLine, VendorFilter, PaymentJournalLine.Status::Created);
        Assert.RecordCount(PaymentJournalLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyVendInvNoToPaymentMessage()
    var
        Vendor: Record Vendor;
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentJnlLine: Record "Payment Journal Line";
        InvoiceNo: Code[20];
        TemplateName: Code[10];
        BatchName: Code[10];
        InvoiceAmount: Decimal;
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
    begin
        // [FEATURE] [UT] [Payment Reference]
        // [SCENARIO 362612] A "Vendor Invoice No." copies to the "Payment Message" of the "Payment Journal Line"

        Initialize();

        CreateVendorWithBankAccount(Vendor, true);
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);
        BankAccountNo := CreateBankAccountMod97Compliant();

        // [GIVEN] Vendor invoice "X" with "Payment Reference" = "001"
        CreateGenJnlLine(
          GenJnlLine, GenJnlLine."Account Type"::Vendor, Vendor."No.",
          GenJnlLine."Document Type"::Invoice, -InvoiceAmount, InvoiceNo, BankAccountNo);
        GenJnlLine.Validate("Payment Reference", LibraryUtility.GenerateGUID());
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [GIVEN] Payment Journal Line
        PrepareGenJnlBatch(GenJnlLine, GenJnlBatch);
        PreparePaymentJnlBatch(TemplateName, BatchName, ExportProtocolCode, refExportProtocolType::Domestic);

        // [WHEN] Set "Applies-To Doc. No." = "X" in the Payment Journal Line
        CreatePaymentJnlLine(
          TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Vendor, Vendor."No.",
          PaymentJnlLine."Applies-to Doc. Type"::Invoice, InvoiceNo, InvoiceAmount, ExportProtocolCode, BankAccountNo);

        // [THEN] "Payment Message" has value "001" in the Payment Journal Line
        PaymentJnlLine.TestField("Payment Message", GenJnlLine."Payment Reference");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchGeneralJournalLineDescriptionForSeparatePmtLines()
    var
        Vendor: Record Vendor;
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentJnlLine: Record "Payment Journal Line";
        ExportProtocolCode: Code[20];
        TemplateName: Code[10];
        BatchName: Code[10];
        InvoiceNo: Code[20];
        InvoiceAmount: Decimal;
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Message] [Separate Line]
        // [SCENARIO 372196] General journal lines created of out the separate purchase payment journal lines contains payment message

        Initialize();

        // [GIVEN] Posted purchase invoice with "External Document No." = "X"
        CreateVendorWithBankAccount(Vendor, false);
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);
        BankAccountNo := CreateBankAccountMod97Compliant();
        CreateAndPostGenJnlLine(
          GenJnlLine."Account Type"::Vendor, Vendor."No.", GenJnlLine."Document Type"::Invoice, -InvoiceAmount, InvoiceNo, BankAccountNo);

        // [GIVEN] Payment journal line with "Payment Message" = "X" applied to the above invoice
        PrepareGenJnlBatch(GenJnlLine, GenJnlBatch);
        PreparePaymentJnlBatch(TemplateName, BatchName, ExportProtocolCode, refExportProtocolType::International);
        CreatePaymentJnlLine(
          TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Vendor, Vendor."No.",
          PaymentJnlLine."Applies-to Doc. Type"::Invoice, InvoiceNo, Round(InvoiceAmount * 0.8), ExportProtocolCode, BankAccountNo);

        // [WHEN] Post and export payment journal lines to general journal
        PostPaymentJournal(GenJnlLine, PaymentJnlLine, ExportProtocolCode);

        // [THEN] Two general journal lines created, both has Description = "X"
        VerifyGenJnlLinesWithSameDescription(GenJnlBatch, PaymentJnlLine."Payment Message", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesGeneralJournalLineDescriptionForSeparatePmtLines()
    var
        Customer: Record Customer;
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentJnlLine: Record "Payment Journal Line";
        ExportProtocolCode: Code[20];
        TemplateName: Code[10];
        BatchName: Code[10];
        InvoiceNo: Code[20];
        InvoiceAmount: Decimal;
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Sales] [Message] [Separate Line]
        // [SCENARIO 372196] General journal lines created of out the separate sales payment journal lines contains payment message

        Initialize();

        // [GIVEN] Posted sales invoice with "External Document No." = "X"
        CreateCustomerWithBankAccount(Customer);
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);
        BankAccountNo := CreateBankAccountMod97Compliant();
        CreateAndPostGenJnlLine(
          GenJnlLine."Account Type"::Customer, Customer."No.", GenJnlLine."Document Type"::Invoice, InvoiceAmount, InvoiceNo, BankAccountNo);

        // [GIVEN] Payment journal line with "Payment Message" = "X" applied to the above invoice
        PrepareGenJnlBatch(GenJnlLine, GenJnlBatch);
        PreparePaymentJnlBatch(TemplateName, BatchName, ExportProtocolCode, refExportProtocolType::International);
        CreatePaymentJnlLine(
          TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Customer, Customer."No.",
          PaymentJnlLine."Applies-to Doc. Type"::Invoice, InvoiceNo, Round(InvoiceAmount * 0.8), ExportProtocolCode, BankAccountNo);

        // [WHEN] Post and export payment journal lines to general journal
        PostPaymentJournal(GenJnlLine, PaymentJnlLine, ExportProtocolCode);

        // [THEN] Two general journal lines created, both has Description = "X"
        VerifyGenJnlLinesWithSameDescription(GenJnlBatch, PaymentJnlLine."Payment Message", 2);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Journal");
        LibraryReportDataset.Reset();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Payment Journal");

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Payment Journal");
    end;

    local procedure CreatePmntJnlLineWithExportProtocol(Vendor: Record Vendor; TemplateName: Code[10]; BatchName: Code[10]; ExportProtocol: Code[20]; BankAccountNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        PaymentJnlLine: Record "Payment Journal Line";
        InvoiceNo: Code[20];
        PmtAmount: Decimal;
    begin
        PmtAmount := LibraryRandom.RandDecInRange(10, 1000, 2);

        CreateAndPostGenJnlLine(
              GenJnlLine."Account Type"::Vendor, Vendor."No.", GenJnlLine."Document Type"::Invoice,
              -PmtAmount, InvoiceNo, BankAccountNo);

        CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Vendor, Vendor."No.",
              PaymentJnlLine."Applies-to Doc. Type"::Invoice, InvoiceNo, PmtAmount, ExportProtocol, BankAccountNo);
    end;

    local procedure PrepareForInit(var TemplateName: Code[10]; var BatchName: Code[10]; var ExpProtCodeDomestic: Code[20]; var ExpProtCodeInternational: Code[20]; var Vendor: Record Vendor; UseExpProtCodeInternational: Boolean; BankAccountNo: Code[20])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        ExportProtocol: Record "Export Protocol";
        Counter: Integer;
    begin
        FindGenJnlTemplateAndBatch(TemplateName, BatchName);
        GenJnlBatch.Get(TemplateName, BatchName);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."Bal. Account No." := LibraryERM.CreateGLAccountNo();
        GenJnlBatch.Modify();

        if UseExpProtCodeInternational then
            PreparePaymentJnlBatch(TemplateName, BatchName, ExpProtCodeInternational, refExportProtocolType::International)
        else
            PreparePaymentJnlBatch(TemplateName, BatchName, ExpProtCodeDomestic, refExportProtocolType::Domestic);

        CreateExportProtocol(ExportProtocol, refExportProtocolType::International);
        ExpProtCodeInternational := ExportProtocol.Code;
        CreateVendorWithBankAccountMod97Compliant(Vendor);

        for Counter := 1 to 2 do
            CreatePmntJnlLineWithExportProtocol(Vendor, TemplateName, BatchName, ExpProtCodeDomestic, BankAccountNo);

        for Counter := 1 to 2 do
            CreatePmntJnlLineWithExportProtocol(Vendor, TemplateName, BatchName, ExpProtCodeInternational, BankAccountNo);
    end;

    local procedure InitExportBatchContainingDigitsScenario(var TemplateName: Code[10]; var BatchName: Code[10]; var ExpProtCodeDomestic: Code[20]; var ExpProtCodeInternational: Code[20]; UseExpProtCodeInternational: Boolean; BankAccountNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        PrepareForInit(TemplateName, BatchName, ExpProtCodeDomestic, ExpProtCodeInternational,
          Vendor, UseExpProtCodeInternational, BankAccountNo);
    end;

    local procedure InitExportBatchesScenario(var TemplateName: Code[10]; var BatchNameDigits: Code[10]; var BatchNameNoDigits: Code[10]; var ExpProtCodeDomestic: Code[20]; var ExpProtCodeInternational: Code[20]; UseExpProtCodeInternational: Boolean; BankAccountNo: Code[20])
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        Vendor: Record Vendor;
        Counter: Integer;
    begin
        PrepareForInit(TemplateName, BatchNameDigits, ExpProtCodeDomestic, ExpProtCodeInternational,
          Vendor, UseExpProtCodeInternational, BankAccountNo);

        LibraryVariableStorage.Enqueue(TemplateName); // for modal page handler

        PaymentJournalTemplate.Get(TemplateName);
        CreatePaymentBatchWithNoNumbers(PaymentJournalTemplate, PaymJournalBatch);
        BatchNameNoDigits := PaymJournalBatch.Name;

        for Counter := 1 to 2 do
            CreatePmntJnlLineWithExportProtocol(Vendor, TemplateName, BatchNameNoDigits, ExpProtCodeDomestic, BankAccountNo);
    end;

    local procedure InitTwoVendorEntriesScenario(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlBatch: Record "Gen. Journal Batch"; var PaymentJnlLine: Record "Payment Journal Line"; var CrMemoNo: Code[20]; var ExportProtocolCode: Code[20]; ApplToCrMemoLineFirst: Boolean)
    var
        Vendor: Record Vendor;
        InvoiceNo: Code[20];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
        BankAccountNo: Code[20];
    begin
        Initialize();

        CreateVendorWithBankAccount(Vendor, false);

        // invoice amount must be greater then credit memo's one
        CrMemoAmount := LibraryRandom.RandDec(1000, 2);
        InvoiceAmount := CrMemoAmount * 2;

        BankAccountNo := CreateBankAccountMod97Compliant();

        CreateAndPostGenJnlLine(GenJnlLine."Account Type"::Vendor, Vendor."No.",
          GenJnlLine."Document Type"::Invoice, -InvoiceAmount, InvoiceNo, BankAccountNo);
        CreateAndPostGenJnlLine(GenJnlLine."Account Type"::Vendor, Vendor."No.",
          GenJnlLine."Document Type"::"Credit Memo", CrMemoAmount, CrMemoNo, BankAccountNo);

        PrepareGenJnlBatch(GenJnlLine, GenJnlBatch);
        CreateVendPaymentJnlLines(
          PaymentJnlLine, Vendor, CrMemoNo, InvoiceNo, CrMemoAmount, InvoiceAmount, ExportProtocolCode, ApplToCrMemoLineFirst, BankAccountNo);
    end;

    local procedure InitTwoCustomerEntriesScenario(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlBatch: Record "Gen. Journal Batch"; var PaymentJnlLine: Record "Payment Journal Line"; var ExportProtocolCode: Code[20])
    var
        Customer: Record Customer;
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
        TemplateName: Code[10];
        BatchName: Code[10];
        PaymentAmount: Decimal;
        CrMemoAmount: Decimal;
        BankAccountNo: Code[20];
    begin
        Initialize();

        CreateCustomerWithBankAccount(Customer);

        // payment amount must be greater then credit memo's one
        CrMemoAmount := LibraryRandom.RandDec(1000, 2);
        PaymentAmount := CrMemoAmount * 2;

        BankAccountNo := CreateBankAccountMod97Compliant();

        CreateAndPostGenJnlLine(GenJnlLine."Account Type"::Customer, Customer."No.",
          GenJnlLine."Document Type"::Payment, -PaymentAmount, InvoiceNo, BankAccountNo);
        CreateAndPostGenJnlLine(GenJnlLine."Account Type"::Customer, Customer."No.",
          GenJnlLine."Document Type"::"Credit Memo", -CrMemoAmount, CrMemoNo, BankAccountNo);

        PrepareGenJnlBatch(GenJnlLine, GenJnlBatch);
        PreparePaymentJnlBatch(TemplateName, BatchName, ExportProtocolCode, refExportProtocolType::Domestic);

        CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Customer, Customer."No.",
          PaymentJnlLine."Applies-to Doc. Type"::Payment, InvoiceNo, PaymentAmount, ExportProtocolCode, BankAccountNo);
        CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Customer, Customer."No.",
          PaymentJnlLine."Applies-to Doc. Type"::"Credit Memo", CrMemoNo, CrMemoAmount, ExportProtocolCode, BankAccountNo);
    end;

    local procedure InitCustAndVendScenario(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlBatch: Record "Gen. Journal Batch"; var PaymentJnlLine: Record "Payment Journal Line"; var CrMemoNo: Code[20]; var ExportProtocolCode: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        InvoiceNo: Code[20];
        TemplateName: Code[10];
        BatchName: Code[10];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
        BankAccountNo: Code[20];
    begin
        Initialize();

        CreateCustomerWithBankAccount(Customer);
        CreateVendorWithBankAccount(Vendor, true);

        // credit memo amount must be greater then invoice's one
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);
        CrMemoAmount := InvoiceAmount * 2;

        BankAccountNo := CreateBankAccountMod97Compliant();

        CreateAndPostGenJnlLine(GenJnlLine."Account Type"::Vendor, Vendor."No.",
          GenJnlLine."Document Type"::Invoice, -InvoiceAmount, InvoiceNo, BankAccountNo);
        CreateAndPostGenJnlLine(GenJnlLine."Account Type"::Customer, Customer."No.",
          GenJnlLine."Document Type"::"Credit Memo", -CrMemoAmount, CrMemoNo, BankAccountNo);

        PrepareGenJnlBatch(GenJnlLine, GenJnlBatch);
        PreparePaymentJnlBatch(TemplateName, BatchName, ExportProtocolCode, refExportProtocolType::Domestic);

        CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Customer, Customer."No.",
          PaymentJnlLine."Applies-to Doc. Type"::"Credit Memo", CrMemoNo, CrMemoAmount, ExportProtocolCode, BankAccountNo);
        CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Vendor, Vendor."No.",
          PaymentJnlLine."Applies-to Doc. Type"::Invoice, InvoiceNo, InvoiceAmount, ExportProtocolCode, BankAccountNo);
    end;

    local procedure InitDimPostScenario(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlBatch: Record "Gen. Journal Batch"; var PaymentJnlLine: Record "Payment Journal Line"; var ExportProtocolCode: Code[20]; var DimValue: Record "Dimension Value")
    var
        Vendor: Record Vendor;
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        InvoiceNo: Code[20];
        TemplateName: Code[10];
        BatchName: Code[10];
        InvoiceAmount: Decimal;
        BankAccountNo: Code[20];
    begin
        Initialize();

        CreateVendorWithBankAccount(Vendor, true);

        InvoiceAmount := LibraryRandom.RandDec(1000, 2);

        BankAccountNo := CreateBankAccountMod97Compliant();

        CreateAndPostGenJnlLine(GenJnlLine."Account Type"::Vendor, Vendor."No.",
          GenJnlLine."Document Type"::Invoice, -InvoiceAmount, InvoiceNo, BankAccountNo);

        PrepareGenJnlBatch(GenJnlLine, GenJnlBatch);
        PreparePaymentJnlBatch(TemplateName, BatchName, ExportProtocolCode, refExportProtocolType::Domestic);

        CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Vendor, Vendor."No.",
          PaymentJnlLine."Applies-to Doc. Type"::Invoice, InvoiceNo, InvoiceAmount, ExportProtocolCode, BankAccountNo);

        // create dimension set with 2 dimensions and assing it to payment journal
        PaymentJnlLine.Validate("Dimension Set ID", CreateDimSetWithTwoDimensions(Dimension, DimensionValue));
        PaymentJnlLine.Modify(true);

        // add only first dimension to selected dimension
        AddDimToSelectedDim(Dimension[1].Code);

        DimValue.Copy(DimensionValue[1]);
    end;

    local procedure ExportPaymentJournalLinesIncludeDims(TemplateName: Code[10]; BatchName: Code[10]; ExportProtocolCode: Code[20])
    var
        ExportProtocol: Record "Export Protocol";
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        PaymentJournalLine.SetRange("Journal Template Name", TemplateName);
        PaymentJournalLine.SetRange("Journal Batch Name", BatchName);
        PaymentJournalLine.FindFirst();
        Commit();

        ExportProtocol.Get(ExportProtocolCode);
        ExportProtocol.ExportPaymentLines(PaymentJournalLine);
    end;

    local procedure ExportPaymentJournalLinesViaPage(BatchName: Code[10]; ExportProtocolCode: Code[20])
    var
        EBPaymentJournal: TestPage "EB Payment Journal";
    begin
        Commit();

        EBPaymentJournal.OpenEdit();
        EBPaymentJournal.CurrentJnlBatchName.SetValue(BatchName);
        EBPaymentJournal.ExportProtocolCode.SetValue(ExportProtocolCode);
        EBPaymentJournal.ExportPaymentLines.Invoke();
    end;

    local procedure CreateAndPostGenJnlLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; var DocumentNo: Code[20]; BankAccountNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlLine(GenJnlLine, AccountType, AccountNo, DocumentType, Amount, DocumentNo, BankAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; var DocumentNo: Code[20]; BankAccountNo: Code[20])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        FindGenJnlTemplateAndBatch(TemplateName, BatchName);
        GenJnlBatch.Get(TemplateName, BatchName);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine, TemplateName, BatchName,
          DocumentType, AccountType, AccountNo, Amount);

        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", BankAccountNo);
        GenJnlLine.Modify();

        DocumentNo := GenJnlLine."Document No.";
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PadStr(PurchaseHeader."Vendor Invoice No.", MaxStrLen(PurchaseHeader."Vendor Invoice No."), '0'));
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccount.Init();
        BankAccount.Validate("No.", LibraryUtility.GenerateRandomCode20(BankAccount.FieldNo("No."), DATABASE::"Bank Account"));
        BankAccount.Validate(Name, BankAccount."No.");
        BankAccount.Insert(true);
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
    end;

    local procedure CreateBankAccountMod97Compliant(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccount(BankAccount);
        GenerateBankAccNosMod97Compliant(BankAccount."Bank Account No.", BankAccount."Bank Branch No.");
        BankAccount.Modify();
        exit(BankAccount."No.");
    end;

    local procedure GenerateBankAccNosMod97Compliant(var BankAccountNo: Text[30]; var BankBranchNo: Text[20])
    var
        CompliantCodePart: Decimal;
        CompliantCodeBody: Decimal;
    begin
        CompliantCodeBody := LibraryRandom.RandIntInRange(1, 10000);
        BankBranchNo := ConvertStr(Format(CompliantCodeBody, 4, '<Integer>'), ' ', '0');

        BankAccountNo := BankBranchNo;
        CompliantCodePart := LibraryRandom.RandIntInRange(1, 1000000);
        CompliantCodeBody := (CompliantCodeBody * 1000000) + CompliantCodePart;
        BankAccountNo += ' ' + ConvertStr(Format(CompliantCodePart, 6, '<Integer>'), ' ', '0');
        BankAccountNo += ' ' + ConvertStr(Format(CompliantCodeBody mod 97, 2, '<Integer>'), ' ', '0');
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; Domestic: Boolean)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorBankAccount(Vendor, Domestic);
    end;

    local procedure CreateVendorWithBankAccountMod97Compliant(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorBankAccountMod97Compliant(Vendor);
    end;

    local procedure CreateVendorWithGlobalDimensions(var Vendor: Record "Vendor"; GlobalDim1Value: Code[10]; GlobalDim2Value: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Global Dimension 1 Code", GlobalDim1Value);
        Vendor.Validate("Global Dimension 2 Code", GlobalDim2Value);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorBankAccount(Vendor: Record Vendor; Domestic: Boolean)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount."Vendor No." := Vendor."No.";
        VendorBankAccount.Code := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), DATABASE::"Vendor Bank Account");
        VendorBankAccount."Country/Region Code" := Vendor."Country/Region Code";
        FillInBankBranchAndAccount(VendorBankAccount."Bank Branch No.", VendorBankAccount."Bank Account No.", Domestic);
        VendorBankAccount.Insert();
    end;

    local procedure CreateVendorBankAccountMod97Compliant(Vendor: Record Vendor)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount."Vendor No." := Vendor."No.";
        VendorBankAccount.Code := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), DATABASE::"Vendor Bank Account");
        VendorBankAccount."Country/Region Code" := Vendor."Country/Region Code";

        GenerateBankAccNosMod97Compliant(VendorBankAccount."Bank Account No.", VendorBankAccount."Bank Branch No.");
        VendorBankAccount.Insert();
    end;

    local procedure CreateCustomerWithBankAccount(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerBankAccount(Customer, true);
    end;

    local procedure CreateCustomerBankAccount(Customer: Record Customer; Domestic: Boolean)
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount."Customer No." := Customer."No.";
        CustomerBankAccount.Code := LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(Code), DATABASE::"Customer Bank Account");
        CustomerBankAccount."Country/Region Code" := Customer."Country/Region Code";
        FillInBankBranchAndAccount(CustomerBankAccount."Bank Branch No.", CustomerBankAccount."Bank Account No.", Domestic);
        CustomerBankAccount.Insert();
    end;

    local procedure CreatePaymentJournalLine(TemplateName: Code[10]; BatchName: Code[10]; var PaymentJnlLine: Record "Payment Journal Line")
    var
        RecRef: RecordRef;
    begin
        PaymentJnlLine.Init();
        PaymentJnlLine.Validate("Journal Template Name", TemplateName);
        PaymentJnlLine.Validate("Journal Batch Name", BatchName);
        RecRef.GetTable(PaymentJnlLine);
        PaymentJnlLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PaymentJnlLine.FieldNo("Line No.")));
        PaymentJnlLine.Insert(true);
    end;

    local procedure CreatePaymentJnlLine(TemplateName: Code[10]; BatchName: Code[10]; var PaymentJnlLine: Record "Payment Journal Line"; AccountType: Integer; AccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; PaymentAmount: Decimal; ExportProtocolCode: Code[20]; BankAccountNo: Code[20])
    begin
        CreatePaymentJournalLine(TemplateName, BatchName, PaymentJnlLine);
        PaymentJnlLine.Validate("Account Type", AccountType);
        PaymentJnlLine.Validate("Posting Date", WorkDate());
        PaymentJnlLine.Validate("Account No.", AccountNo);
        PaymentJnlLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        PaymentJnlLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        case PaymentJnlLine."Account Type" of
            PaymentJnlLine."Account Type"::Vendor:
                PaymentJnlLine.Validate("Beneficiary Bank Account", FindVendorBankAccountCode(AccountNo));
            PaymentJnlLine."Account Type"::Customer:
                PaymentJnlLine.Validate("Beneficiary Bank Account", FindCustomerBankAccountCode(AccountNo));
        end;
        PaymentJnlLine.Validate("Bank Account", BankAccountNo);
        PaymentJnlLine.Validate(Amount, PaymentAmount);
        PaymentJnlLine.Validate("Export Protocol Code", ExportProtocolCode);
        PaymentJnlLine.Modify(true);
    end;

    local procedure ModifyGLSetupShortcutDimension(NewDimensionCode: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 8 Code", NewDimensionCode);
        GeneralLedgerSetup.Modify();
    end;

    local procedure GetPaymentTemplateAndBatchName(var TemplateName: Code[10]; var BatchName: Code[10])
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
    begin
        CreatePaymentTemplate(PaymentJournalTemplate);
        CreatePaymentBatch(PaymentJournalTemplate, PaymJournalBatch);
        TemplateName := PaymentJournalTemplate.Name;
        BatchName := PaymJournalBatch.Name;
    end;

    local procedure FindGenJnlTemplateAndBatch(var TemplateName: Code[10]; var BatchName: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        TemplateName := GenJournalBatch."Journal Template Name";
        BatchName := GenJournalBatch.Name;
    end;

    local procedure FindVendorBankAccountCode(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        VendorBankAccount.FindFirst();
        exit(VendorBankAccount.Code);
    end;

    local procedure FindCustomerBankAccountCode(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.SetRange("Customer No.", CustomerNo);
        CustomerBankAccount.FindFirst();
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateExportProtocol(var ExportProtocol: Record "Export Protocol"; Type: Integer)
    begin
        ExportProtocol.Code := LibraryUtility.GenerateRandomCode(ExportProtocol.FieldNo(Code), DATABASE::"Export Protocol");
        case Type of
            refExportProtocolType::International:
                begin
                    ExportProtocol."Check Object ID" := CODEUNIT::"Check International Payments";
                    ExportProtocol."Export Object ID" := REPORT::"File International Payments";
                end;
            refExportProtocolType::Domestic:
                begin
                    ExportProtocol."Check Object ID" := CODEUNIT::"Check Domestic Payments";
                    ExportProtocol."Export Object ID" := REPORT::"File Domestic Payments";
                end;
        end;
        ExportProtocol.Insert();
    end;

    local procedure SuggestVendorPayments(VendorNoFilter: Text)
    begin
        SuggestVendorPaymentsWithDimFilters(VendorNoFilter, '', '');
    end;

    local procedure SuggestVendorPaymentsWithDimFilters(VendorNoFilter: Text; GlobalDim1Filter: Text; GlobalDim2Filter: Text)
    var
        Vendor: Record Vendor;
        PaymentJournalLine: Record "Payment Journal Line";
        PaymentJournalTemplate: Record "Payment Journal Template";
        PaymJournalBatch: Record "Paym. Journal Batch";
        SuggestVendorPaymentsEB: Report "Suggest Vendor Payments EB";
    begin
        CreatePaymentTemplate(PaymentJournalTemplate);
        CreatePaymentBatch(PaymentJournalTemplate, PaymJournalBatch);
        CreatePaymentJournalLine(PaymentJournalTemplate.Name, PaymJournalBatch.Name, PaymentJournalLine);
        Commit();
        Vendor.SetFilter("No.", VendorNoFilter);
        Vendor.SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
        Vendor.SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);
        SuggestVendorPaymentsEB.SetTableView(Vendor);
        SuggestVendorPaymentsEB.SetJournal(PaymentJournalLine);
        SuggestVendorPaymentsEB.RunModal();
    end;

    local procedure PostPaymentJournal(GenJnlLine: Record "Gen. Journal Line"; var PaymentJnlLine: Record "Payment Journal Line"; ExportProtocolCode: Code[20])
    var
        ExportProtocol: Record "Export Protocol";
        PaymentJournalPost: Report "Payment Journal Post";
    begin
        ExportProtocol.Get(ExportProtocolCode);
        PaymentJournalPost.SetParameters(GenJnlLine, false, ExportProtocol."Export Object ID", WorkDate());
        PaymentJournalPost.SetTableView(PaymentJnlLine);
        PaymentJournalPost.RunModal();
    end;

    local procedure FindCrMemoGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; CrMemoNo: Code[20])
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJnlLine.SetRange("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::"Credit Memo");
        GenJnlLine.SetRange("Applies-to Doc. No.", CrMemoNo);
        GenJnlLine.FindFirst();
    end;

    local procedure FilterEBPaymentJournalLine(var PaymentJournalLine: Record "Payment Journal Line"; VendorNoFilter: Text; LineStatus: Option)
    begin
        PaymentJournalLine.SetRange("Account Type", PaymentJournalLine."Account Type"::Vendor);
        PaymentJournalLine.SetFilter("Account No.", VendorNoFilter);
        PaymentJournalLine.SetRange(Status, LineStatus);
    end;

    local procedure PrepareGenJnlBatch(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlBatch: Record "Gen. Journal Batch")
    var
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        FindGenJnlTemplateAndBatch(TemplateName, BatchName);
        GenJnlBatch.Get(TemplateName, BatchName);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."Bal. Account No." := LibraryERM.CreateGLAccountNo();
        GenJnlBatch.Modify();
        LibraryERM.ClearGenJournalLines(GenJnlBatch);

        GenJnlLine."Journal Template Name" := TemplateName;
        GenJnlLine."Journal Batch Name" := BatchName;
    end;

    local procedure PreparePaymentJnlBatch(var TemplateName: Code[10]; var BatchName: Code[10]; var ExportProtocolCode: Code[20]; ProtocolType: Integer)
    var
        ExportProtocol: Record "Export Protocol";
    begin
        GetPaymentTemplateAndBatchName(TemplateName, BatchName);
        CreateExportProtocol(ExportProtocol, ProtocolType);
        ExportProtocolCode := ExportProtocol.Code;
    end;

    local procedure FillInBankBranchAndAccount(var BankBranchNo: Text[20]; var BankAccountNo: Text[30]; Domestic: Boolean)
    begin
        if Domestic then begin
            BankBranchNo := '1200';
            BankAccountNo := '450-1157489-44';
        end else begin
            BankBranchNo := '6000';
            BankAccountNo := '6000 600011';
        end;
    end;

    local procedure CreatePaymentTemplate(var PaymentJnlTemplate: Record "Payment Journal Template")
    begin
        PaymentJnlTemplate.Init();
        PaymentJnlTemplate.Validate(Name, LibraryUtility.GenerateRandomCode(PaymentJnlTemplate.FieldNo(Name), DATABASE::"Payment Journal Template"));
        PaymentJnlTemplate.Validate("Page ID", PAGE::"EB Payment Journal");
        PaymentJnlTemplate.Insert(true);
    end;

    local procedure CreatePaymentBatch(PaymentJnlTemplate: Record "Payment Journal Template"; var PaymJnlBatch: Record "Paym. Journal Batch")
    begin
        PaymJnlBatch.Init();
        PaymJnlBatch.Validate("Journal Template Name", PaymentJnlTemplate.Name);
        PaymJnlBatch.Validate(Name, LibraryUtility.GenerateRandomCode(PaymJnlBatch.FieldNo(Name), DATABASE::"Paym. Journal Batch"));
        PaymJnlBatch.Validate("Reason Code", PaymentJnlTemplate."Reason Code");
        PaymJnlBatch.Insert(true);
    end;

    local procedure CreatePaymentBatchWithNoNumbers(PaymentJnlTemplate: Record "Payment Journal Template"; var PaymJnlBatch: Record "Paym. Journal Batch")
    begin
        PaymJnlBatch.Init();
        PaymJnlBatch.Validate("Journal Template Name", PaymentJnlTemplate.Name);
        PaymJnlBatch.Validate(Name, GenerateRandomLetters(10));
        PaymJnlBatch.Validate("Reason Code", PaymentJnlTemplate."Reason Code");
        PaymJnlBatch.Insert(true);
    end;

    local procedure GenerateRandomLetters(Length: Integer) Result: Text
    var
        Counter: Integer;
    begin
        for Counter := 1 to Length do
            Result += CopyStr(LettersTxt, LibraryRandom.RandInt(26), 1);
    end;

    local procedure CreateDimSetWithTwoDimensions(var Dimension: array[2] of Record Dimension; var DimensionValue: array[2] of Record "Dimension Value") DimSetID: Integer
    var
        i: Integer;
    begin
        for i := 1 to 2 do
            DimSetID := CreateDimSet(DimSetID, Dimension[i], DimensionValue[i]);
    end;

    local procedure CreateDimSet(DimSetID: Integer; var Dimension: Record Dimension; var DimValue: Record "Dimension Value"): Integer
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(DimSetID, DimValue."Dimension Code", DimValue.Code));
    end;

    local procedure CreateVendPaymentJnlLines(var PaymentJnlLine: Record "Payment Journal Line"; Vendor: Record Vendor; CrMemoNo: Code[20]; InvoiceNo: Code[20]; CrMemoAmount: Decimal; InvoiceAmount: Decimal; var ExportProtocolCode: Code[20]; ApplToCrMemoLineFirst: Boolean; BankAccountNo: Code[20])
    var
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        PreparePaymentJnlBatch(TemplateName, BatchName, ExportProtocolCode, refExportProtocolType::International);

        if ApplToCrMemoLineFirst then begin
            CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Vendor, Vendor."No.",
              PaymentJnlLine."Applies-to Doc. Type"::"Credit Memo", CrMemoNo, -CrMemoAmount, ExportProtocolCode, BankAccountNo);
            CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Vendor, Vendor."No.",
              PaymentJnlLine."Applies-to Doc. Type"::Invoice, InvoiceNo, Round(InvoiceAmount), ExportProtocolCode, BankAccountNo);
        end else begin
            CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Vendor, Vendor."No.",
              PaymentJnlLine."Applies-to Doc. Type"::Invoice, InvoiceNo, Round(InvoiceAmount * 0.8), ExportProtocolCode, BankAccountNo);
            CreatePaymentJnlLine(TemplateName, BatchName, PaymentJnlLine, PaymentJnlLine."Account Type"::Vendor, Vendor."No.",
              PaymentJnlLine."Applies-to Doc. Type"::"Credit Memo", CrMemoNo, -CrMemoAmount, ExportProtocolCode, BankAccountNo);
        end;
    end;

    local procedure MockVendorLedgerEntry(VendorNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date; EntryAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry.Amount := EntryAmount;
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
        MockDetailedVendorLedgerEntry(VendorNo, DocumentNo, VendorLedgerEntry."Entry No.", EntryAmount, PostingDate);
    end;

    local procedure MockDetailedVendorLedgerEntry(VendorNo: Code[20]; DocumentNo: Code[20]; VendLedgEntryNo: Integer; EntryAmount: Decimal; PostingDate: Date)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry."Document No." := DocumentNo;
        DetailedVendorLedgEntry."Posting Date" := PostingDate;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendLedgEntryNo;
        DetailedVendorLedgEntry.Amount := EntryAmount;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure AddDimToSelectedDim(DimensionCode: Code[20])
    var
        SelectedDim: Record "Selected Dimension";
    begin
        SelectedDim.DeleteAll();
        SelectedDim.Init();
        SelectedDim."User ID" := UserId;
        SelectedDim.Validate("Object Type", 3);
        SelectedDim.Validate("Object ID", REPORT::"File Domestic Payments");
        SelectedDim.Validate("Dimension Code", DimensionCode);
        SelectedDim.Insert(true);
    end;

    local procedure UpdateGLAccountDefaultDim(GLAccountNo: Code[20]; var DimValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DimSetID: Integer;
    begin
        DimSetID := CreateDimSet(DimSetID, Dimension, DimValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"G/L Account", GLAccountNo,
          DimValue."Dimension Code", DimValue.Code)
    end;

    local procedure ValidateDomesticReportXml(BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BankAccName', BankAccount.Name);
        LibraryReportDataset.AssertElementWithValueExists('BankAccBankAccNo', BankAccount."Bank Account No.");
        // Initial TFSID 232996
        LibraryReportDataset.AssertElementWithValueExists('BankAccBankBranchNo', BankAccount."Bank Branch No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoEnterpriseNo', '0058.315.707');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmt1', 1450.81);
    end;

    local procedure ValidateInternationalReportXml(BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BankAcc_Name', BankAccount.Name);
        LibraryReportDataset.AssertElementWithValueExists('BankAcc_BankAccNo', BankAccount."Bank Account No.");
        // Initial TFSID 232996
        LibraryReportDataset.AssertElementWithValueExists('BankAcc_BankBranchNo', BankAccount."Bank Branch No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfo_EnterpriseNo', '0058.315.707');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount1', 1631.46);
    end;

    local procedure VerifyNumberAndStatusOfVendorPaymentJournalLines(VendorNo: Code[20]; LineStatus: Option; ExpectedCount: Integer)
    var
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        FilterEBPaymentJournalLine(PaymentJournalLine, VendorNo, LineStatus);
        Assert.AreEqual(ExpectedCount, PaymentJournalLine.Count, WrongNumberOfLinesErr);
    end;

    local procedure VerifyNumberAndStatusOfPaymentJournalLines(TemplateName: Code[10]; BatchName: Code[10]; NumberOfLines: Integer; Status: Option)
    var
        PmtJnlLine: Record "Payment Journal Line";
        "Count": Integer;
    begin
        PmtJnlLine.SetRange("Journal Template Name", TemplateName);
        PmtJnlLine.SetRange("Journal Batch Name", BatchName);
        if PmtJnlLine.FindSet() then
            repeat
                Count += 1;
                Assert.AreEqual(Status, PmtJnlLine.Status, WrongStatusOfLineErr);
            until PmtJnlLine.Next() = 0;
        Assert.AreEqual(NumberOfLines, Count, WrongNumberOfLinesErr);
    end;

    local procedure VerifyPaymentJournalLineDimension(VendorFilter: Text; DimensionValue: Record "Dimension Value")
    var
        PaymentJournalLine: Record "Payment Journal Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        FilterEBPaymentJournalLine(PaymentJournalLine, VendorFilter, PaymentJournalLine.Status::Created);
        Assert.RecordCount(PaymentJournalLine, 1);
        PaymentJournalLine.FindFirst();
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PaymentJournalLine."Dimension Set ID");
        Assert.AreEqual(
            DimensionValue.Code, DimensionSetEntry."Dimension Value Code",
            DimensionSetEntry.FieldCaption("Dimension Value Code"));
    end;

    local procedure VerifyPaymentJournalLinesStatusChangedAndRenamed(TemplateName: Code[10]; BatchName: Code[10])
    var
        PaymJournalBatch: Record "Paym. Journal Batch";
        PmtJnlLineStatus: Option Created,,Processed,Posted;
    begin
        VerifyNumberAndStatusOfPaymentJournalLines(
          TemplateName, BatchName, 2, PmtJnlLineStatus::Posted);
        PaymJournalBatch.Get(TemplateName, BatchName);
        Assert.AreEqual(PaymJournalBatch.Status::Processed, PaymJournalBatch.Status, WrongStatusOfBatchErr);

        VerifyNumberAndStatusOfPaymentJournalLines(
          TemplateName, IncStr(BatchName), 2, PmtJnlLineStatus::Created);
    end;

    local procedure VerifyPaymentJournalLinesStatusNotChanged(TemplateName: Code[10]; BatchName: Code[10])
    var
        PaymJournalBatch: Record "Paym. Journal Batch";
        PmtJnlLineStatus: Option Created,,Processed,Posted;
    begin
        VerifyNumberAndStatusOfPaymentJournalLines(
          TemplateName, BatchName, 2, PmtJnlLineStatus::Created);
        PaymJournalBatch.Get(TemplateName, BatchName);
        Assert.AreEqual(PaymJournalBatch.Status::" ", PaymJournalBatch.Status, WrongStatusOfBatchErr);
    end;

    local procedure VerifyCrMemoGenJnlLine(GenJournalBatch: Record "Gen. Journal Batch"; CrMemoNo: Code[20]; ExpectedDocType: Enum "Gen. Journal Document Type")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        FindCrMemoGenJnlLine(GenJnlLine, GenJournalBatch, CrMemoNo);
        GenJnlLine.TestField("Document Type", ExpectedDocType);
    end;

    local procedure VerifyCrMemoGenJnlLine2(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJnlLine.SetRange("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.FindFirst();
        GenJnlLine.TestField("Document Type", GenJnlLine."Document Type"::Refund);
    end;

    local procedure VerifyGenJnlLineApplyToID(GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; ApplyToID: Code[50])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJnlLine.SetRange("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.SetRange("Account No.", AccountNo);
        GenJnlLine.FindFirst();
        GenJnlLine.TestField("Applies-to ID", ApplyToID);
    end;

    local procedure VerifyGenJnlLineDim(GenJnlBatch: Record "Gen. Journal Batch"; DimValue: Record "Dimension Value"; AccountNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Account No.", AccountNo);
        GenJnlLine.FindFirst();
        GenJnlLine.TestField("Dimension Set ID");
        DimMgt.GetDimensionSet(TempDimSetEntry, GenJnlLine."Dimension Set ID");
        Assert.AreEqual(1, TempDimSetEntry.Count, IncorrectNumberOfDimErr);
        TempDimSetEntry.TestField("Dimension Code", DimValue."Dimension Code");
        TempDimSetEntry.TestField("Dimension Value Code", DimValue.Code);
    end;

    local procedure VerifyGenJnlLinesWithSameDescription(GenJournalBatch: Record "Gen. Journal Batch"; ExpectedPaymentMessage: Text[100]; ExpectedCount: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange(Description, ExpectedPaymentMessage);
        Assert.RecordCount(GenJournalLine, ExpectedCount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalLinesHandler(var FileDomesticPayments: TestRequestPage "File Domestic Payments")
    var
        FileMgt: Codeunit "File Management";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        FindGenJnlTemplateAndBatch(TemplateName, BatchName);
        FileDomesticPayments."GenJnlLine.""Journal Template Name""".SetValue(TemplateName); // Journal Template Name
        FileDomesticPayments."GenJnlLine.""Journal Batch Name""".SetValue(BatchName); // Journal Batch Name
        FileDomesticPayments.FileName.SetValue(FileMgt.ServerTempFileName('txt'));
        FileDomesticPayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalLinesInternationalHandler(var FileInternationalPayments: TestRequestPage "File International Payments")
    var
        FileMgt: Codeunit "File Management";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        FindGenJnlTemplateAndBatch(TemplateName, BatchName);
        FileInternationalPayments.JournalTemplateName.SetValue(TemplateName); // Journal Template Name
        FileInternationalPayments.JournalBatchName.SetValue(BatchName); // Journal Batch Name
        FileInternationalPayments.FileName.SetValue(FileMgt.ServerTempFileName('txt'));
        FileInternationalPayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsEBRPH(var SuggestVendorPaymentsEB: TestRequestPage "Suggest Vendor Payments EB")
    begin
        SuggestVendorPaymentsEB.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplatesModalPageHandler(var EBPaymentJournalTemplates: TestPage "EB Payment Journal Templates")
    begin
        EBPaymentJournalTemplates.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        EBPaymentJournalTemplates.OK().Invoke();
    end;
}

