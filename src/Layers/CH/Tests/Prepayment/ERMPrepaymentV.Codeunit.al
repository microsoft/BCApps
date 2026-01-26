codeunit 134106 "ERM Prepayment V"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3.';
        IncorrectPrepmtAmountInvLCYErr: Label 'Incorrect Prepmt. Amount Inv. (LCY) value.';
        CountDimSetEntriesErr: Label 'Count of Dimension Set Entries is wrong.';
        IncorrectVATEntryAmountErr: Label 'Incorrect VAT Entry Amount.';
        SalesInvDiscForPrepmtExceededErr: Label 'You cannot enter an invoice discount for sales document %1.';
        PurchaseInvDiscForPrepmtExceededErr: Label 'You cannot enter an invoice discount for purchase document %1';
        CannotChangeVATGroupWithPrepmInvErr: Label 'You cannot change the VAT product posting group because prepayment invoices have been posted.\\You need to post the prepayment credit memo to be able to change the VAT product posting group.';
        CannotChangePrepmtAmtDiffVAtPctErr: Label 'You cannot change the prepayment amount because the prepayment invoice has been posted with a different VAT percentage. Please check the settings on the prepayment G/L account.';
        GenProdPostingGroupErr: Label '%1 is not set for the %2 G/L account with no. %3.', Comment = '%1 - caption Gen. Prod. Posting Group; %2 - G/L Account Description; %3 - G/L Account No.';
        PrepaymentInvoicesNotPaidErr: Label 'You cannot get lines until you have posted all related prepayment invoices to mark the prepayment as paid.';
        LineAmountMustMatchErr: Label 'Line Amount must match.';
        YourReferenceMustBeTheSameErr: Label 'Your reference must be the same in customer ledger entry as in sales order';

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsWithoutCompressPrepmt()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check VAT Amount on Purchase Order Statistics Page after Create Purchase Order with Prepayment 100% and  Compress Prepayment as FALSE.

        // Setup: Find VAT Posting Setup, create Purchase Order with Prepayment.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseLine, VATPostingSetup, false);

        // Update Prepayment Account and Enqueue VAT Amount and Amount Including VAT.
        UpdatePurchasePrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), PurchaseLine."Gen. Bus. Posting Group",
          PurchaseLine."Gen. Prod. Posting Group");
        LibraryVariableStorage.Enqueue(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(PurchaseLine."Amount Including VAT");

        // Exercise: Open Purchase Order Statistics Page.
        OpenPurchaseOrderStatistics(PurchaseLine."Document No.");

        // Verify:  and Verify VAT Amount field through Page Handler(PurchaseOrderStatisticsHandler).
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsWithoutCompressPrepmt()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check VAT Amount on Purchase Order Statistics Page after Create Purchase Order with Prepayment 100% and  Compress Prepayment as FALSE.

        // Setup: Find VAT Posting Setup, create Purchase Order with Prepayment.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseLine, VATPostingSetup, false);

        // Update Prepayment Account and Enqueue VAT Amount and Amount Including VAT.
        UpdatePurchasePrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), PurchaseLine."Gen. Bus. Posting Group",
          PurchaseLine."Gen. Prod. Posting Group");
        LibraryVariableStorage.Enqueue(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(PurchaseLine."Amount Including VAT");

        // Exercise: Open Purchase Order Statistics Page.
        OpenPurchOrderStatistics(PurchaseLine."Document No.");

        // Verify:  and Verify VAT Amount field through Page Handler(PurchaseOrderStatisticsHandler).
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtPurchCrMemoWithCompressPrepmt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        PurchasePrepaymentsAccount: Code[20];
    begin
        // Check VAT Amount on G/L Entry after Posting Purchase Prepayment Invoice with Prepayment 100% and  Compress Prepayment as TRUE.

        // Setup: Find VAT Posting Setup, create Purchase Order with Prepayment and post Prepayment Invoice and Credit Memo.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseLine, VATPostingSetup, true);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchasePrepaymentsAccount := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group");

        // Update Prepayment Account and Post Purchase Prepayment Invoice.
        UpdatePurchasePrepmtAccount(
          PurchasePrepaymentsAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepmt. Cr. Memo No. Series");

        // Exercise: Post Prepayment Credit Memo.
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        // Verify:
        VerifyGLEntry(-PurchaseLine."Prepmt. Line Amount", DocumentNo, PurchasePrepaymentsAccount);

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          GeneralPostingSetup."Purch. Prepayments Account", PurchaseLine."Gen. Bus. Posting Group",
          PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoStatisticsWithCompressPrepmt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        PurchasePrepaymentsAccount: Code[20];
    begin
        // Check VAT Amount on Posted Purchase Credit Memo Statistics page using Compress Prepayment as TRUE.

        // Setup: Find VAT Posting Setup, create Purchase Order with Prepayment and post Prepayment Invoice and Credit Memo.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseLine, VATPostingSetup, true);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchasePrepaymentsAccount := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group");

        // Update Prepayment Account and Post Purchase Prepayment Invoice.
        UpdatePurchasePrepmtAccount(
          PurchasePrepaymentsAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepmt. Cr. Memo No. Series");
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);

        // Enqueue VAT Amount and Amount Including VAT.
        LibraryVariableStorage.Enqueue(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(PurchaseLine."Amount Including VAT");

        // Exercise: Open Posted Purchase Credit Memo Statistics Page.
        OpenPstdPurchCrMemorStatistics(DocumentNo);

        // Verify:  and Verify VAT Amount field through Page Handler 'PurchaseCreditMemoStatisticsPageHandler'.

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          GeneralPostingSetup."Purch. Prepayments Account", PurchaseLine."Gen. Bus. Posting Group",
          PurchaseLine."Gen. Prod. Posting Group");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsWithoutCompressPrepmt()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check VAT Amount on Sales Order Statistics Page after Create Sales Order with Prepayment 100% and  Compress Prepayment as FALSE.

        // Setup: Find VAT Posting Setup, create Sales Order with Prepayment.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesLine, VATPostingSetup, false);

        // Update Prepayment Account and Enqueue VAT Amount and Amount Including VAT.
        UpdateSalesPrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), SalesLine."Gen. Bus. Posting Group",
          SalesLine."Gen. Prod. Posting Group");
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" * SalesLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount");

        // Exercise: Open Sales Order Statistics Page.
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // Verify:  and Verify VAT Amount field through Page Handler(SalesOrderStatisticsPageHandler).
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsWithoutCompressPrepmtNM()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check VAT Amount on Sales Order Statistics Page after Create Sales Order with Prepayment 100% and  Compress Prepayment as FALSE.

        // Setup: Find VAT Posting Setup, create Sales Order with Prepayment.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesLine, VATPostingSetup, false);

        // Update Prepayment Account and Enqueue VAT Amount and Amount Including VAT.
        UpdateSalesPrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), SalesLine."Gen. Bus. Posting Group",
          SalesLine."Gen. Prod. Posting Group");
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" * SalesLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount");

        // Exercise: Open Sales Order Statistics Page.
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // Verify:  and Verify VAT Amount field through Page Handler(SalesOrderStatisticsPageHandler).
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtSalesCrMemoWithCompressPrepmt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        SalesPrepaymentsAccount: Code[20];
    begin
        // Check VAT Amount on G/L Entry after Posting Sales Prepayment Invoice with Prepayment 100% and  Compress Prepayment as TRUE.

        // Setup: Find VAT Posting Setup, create Sales Order with Prepayment and post Prepayment Invoice and Credit Memo.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesLine, VATPostingSetup, true);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesPrepaymentsAccount := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group");

        // Update Prepayment Account and Post Prepayment Invoice.
        UpdateSalesPrepmtAccount(SalesPrepaymentsAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");

        // Exercise:Post Prepayment Credit Memo.
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // Verify:
        VerifyGLEntry(SalesLine."Prepmt. Line Amount", DocumentNo, SalesPrepaymentsAccount);

        // Tear Down.
        UpdateSalesPrepmtAccount(
          GeneralPostingSetup."Sales Prepayments Account", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoStatisticsWithCompressPrepmt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        SalesPrepaymentsAccount: Code[20];
    begin
        // Check VAT Amount on Posted Sales Credit Memo Statistics page using Compress Prepayment as TRUE.

        // Setup: Find VAT Posting Setup, create Sales Order with Prepayment and post Prepayment Invoice and Credit Memo.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesLine, VATPostingSetup, true);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesPrepaymentsAccount := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group");
        UpdateSalesPrepmtAccount(SalesPrepaymentsAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Post Prepayment Credit Memo. and Enqueue VAT Amount and Amount Including VAT.
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" * SalesLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(SalesLine."Amount Including VAT");

        // Exercise: Open Posted Sales Credit Memo Statistics Page.
        OpenPstdSalesCrMemorStatistics(DocumentNo);

        // Verify:  and Verify VAT Amount field through Page Handler 'SalesCreditMemoStatisticsPageHandler'.

        // Tear Down.
        UpdateSalesPrepmtAccount(
          GeneralPostingSetup."Sales Prepayments Account", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSeveralLinesPartialPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // check "Prepmt. Amount Inv. (LCY)" and "Prepmt. VAT Amount Inv. (LCY)" calculation during the partial posting
        // in case of several document lines

        // Setup: create sales order with 2 lines and post prepayment invoice
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocumentWithTwoLines(SalesHeader, SalesLine, VATPostingSetup);
        UpdateSalesPrepmtAccount(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise: post the half of quantity
        PostSalesDocumentPartially(SalesHeader);

        // Verify: "Prepmt. Amount Inv. (LCY)" and "Prepmt. VAT Amount Inv. (LCY)" of the first line have to be updated
        VerifyFirstSalesLinePrepmtAmountInvLCY(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderSeveralLinesPartialPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // check "Prepmt. Amount Inv. (LCY)" and "Prepmt. VAT Amount Inv. (LCY)" calculation during the partial posting
        // in case of several document lines

        // Setup: create purchase order with 2 lines and post prepayment invoice
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchDocumentWithTwoLines(PurchaseHeader, PurchaseLine, VATPostingSetup);
        UpdatePurchasePrepmtAccount(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Exercise: post the half of quantity
        PostPurchDocumentPartially(PurchaseHeader);

        // Verify: "Prepmt. Amount Inv. (LCY)" and "Prepmt. VAT Amount Inv. (LCY)" of the first line have to be updated
        VerifyFirstPurchLinePrepmtAmountInvLCY(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoInvRoundingOnFullDeductionWhenPostingPartialSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentsAccount: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 362757] Manually settled full prepayment deduction posted for partial sales order

        Initialize();
        // [GIVEN] Sales Order with Prepayment and Qty. to Invoice < Quantity
        SalesPrepaymentsAccount := CreatePartialSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] "Prepmt. Amount to Deduct" = Quantity * "Prepmt. Amount Inv." = X (full prepayment deduction)
        UpdateSalesPrepmtAmtToDeductWithPrepmtAmtInvoiced(SalesLine);

        // [WHEN] Post Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/Entry amount for account "Invoice Rounding Account" = 0
        VerifyGLEntryDoesNotExist(DocNo, GetInvRoundingAccFromCust(SalesHeader."Bill-to Customer No."));
        // [THEN] G/Entry amount for account "Sales Prepayments Account" = "X"
        VerifyGLEntry(SalesLine."Prepmt Amt to Deduct", DocNo, SalesPrepaymentsAccount);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoInvRoundingOnFullDeductionWhenPostingPartialPurchaseOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPrepaymentsAccount: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 362757] Manually settled full prepayment deduction posted for partial purchase order

        Initialize();
        // [GIVEN] Purchase Order with Prepayment and Qty. to Invoice < Quantity
        PurchPrepaymentsAccount := CreatePartialPurchOrder(PurchHeader, PurchLine);

        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [GIVEN] "Prepmt. Amount to Deduct" = Quantity * "Prepmt. Amount Inv." = X (full prepayment deduction)
        UpdatePurchPrepmtAmtToDeductWithPrepmtAmtInvoiced(PurchLine);
        PurchHeader."Vendor Invoice No." := IncStr(PurchHeader."Vendor Invoice No.");
        PurchHeader.Modify();

        // [WHEN] Post Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] G/Entry amount for account "Invoice Rounding Account" = 0
        VerifyGLEntryDoesNotExist(DocNo, GetInvRoundingAccFromVend(PurchHeader."Pay-to Vendor No."));
        // [THEN] G/Entry amount for account "Purchase Prepayments Account" = "X"
        VerifyGLEntry(-PurchLine."Prepmt Amt to Deduct", DocNo, PurchPrepaymentsAccount);

        // Tear down
        TearDownVATPostingSetup(PurchHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimWithDifferentPostingGroupsInPurchLines()
    var
        PurchaseHeader: Record "Purchase Header";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
        TotalCountDimSetEntries: Integer;
    begin
        // [FEATURE] [Sales][Default Dimension]
        // [SCENARIO 363725] Dimension Sets is created for different setups of Purchase line of Posting groups if "Purch. Prepayments Account" of groups have account with default dimension value.

        Initialize();
        // [GIVEN] "G/L Account" = "A1" without default dimension
        // [GIVEN] "G/L Account" = "A2" with Default Dimension = "DD1" and Default Dimension Value = "DDV1"
        // [GIVEN] "G/L Account" = "A3" with Default Dimension = "DD2" and Default Dimension Value = "DDV2"

        // [GIVEN] Purchase order with four purchase lines with posted prepayment invoices and different setup of posting groups
        MockPurchaseHeader(PurchaseHeader);

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET1" with "Purch. Prepayments Account" = "A1"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue1, GenBusPostingGroupCode, GenProdPostingGroupCode, false);
        // [GIVEN] First line has posting groups = "SET1"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET2" with "Purch. Prepayments Account" = "A2"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue1, GenBusPostingGroupCode, GenProdPostingGroupCode, true);
        // [GIVEN] Second line has posting groups = "SET2"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET3" with "Purch. Prepayments Account" = "A3"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue2, GenBusPostingGroupCode, GenProdPostingGroupCode, true);
        // [GIVEN] Third line has posting groups = "SET3"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] Fourth line has posting groups = "SET3"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DD1" and "Dimension Value Code" = "DDV1" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue1."Dimension Code", DimensionValue1.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DD2" and "Dimension Value Code" = "DDV2" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue2."Dimension Code", DimensionValue2.Code);
        // [GIVEN] Total count of Dimension set entries = "X"
        TotalCountDimSetEntries := DimensionSetEntry.Count();

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Purchase Header
        PurchaseHeader.CreateDimSetForPrepmtAccDefaultDim();

        // [THEN] Two new Dimension Set Entries added:
        Assert.AreEqual(TotalCountDimSetEntries + 2, DimensionSetEntry.Count, CountDimSetEntriesErr);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DD1" and "Dimension Value Code" = "DDV1" was created
        VerifyDimensionSetEntryIsExists(DimensionValue1."Dimension Code", DimensionValue1.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DD2" and "Dimension Value Code" = "DDV2" was created
        VerifyDimensionSetEntryIsExists(DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimWithDifferentPostingGroupsInSalesLines()
    var
        SalesHeader: Record "Sales Header";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
        TotalCountDimSetEntries: Integer;
    begin
        // [FEATURE] [Sales][Default Dimension]
        // [SCENARIO 363725] Dimension Sets is created for different setups of Sales line of Posting groups if "Sales Prepayments Account" of groups have account with default dimension value.

        Initialize();
        // [GIVEN] "G/L Account" = "A1" without default dimension
        // [GIVEN] "G/L Account" = "A2" with Default Dimension = "DD1" and Default Dimension Value = "DDV1"
        // [GIVEN] "G/L Account" = "A3" with Default Dimension = "DD2" and Default Dimension Value = "DDV2"

        // [GIVEN] Sales order with four sales lines with posted prepayment invoices and different setup of posting groups
        MockSalesHeader(SalesHeader);

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET1" with "Sales Prepayments Account" = "A1"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue1, GenBusPostingGroupCode, GenProdPostingGroupCode, false);
        // [GIVEN] First line has posting groups = "SET1"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET2" with "Sales Prepayments Account" = "A2"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue1, GenBusPostingGroupCode, GenProdPostingGroupCode, true);
        // [GIVEN] Second line has posting groups = "SET2"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET3" with "Sales Prepayments Account" = "A3"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue2, GenBusPostingGroupCode, GenProdPostingGroupCode, true);
        // [GIVEN] Third line has posting groups = "SET3"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] Fourth line has posting groups = "SET3"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DD1" and "Dimension Value Code" = "DDV1" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue1."Dimension Code", DimensionValue1.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DD2" and "Dimension Value Code" = "DDV2" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue2."Dimension Code", DimensionValue2.Code);
        // [GIVEN] Total count of Dimension set entries = "X"
        TotalCountDimSetEntries := DimensionSetEntry.Count();

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Sales Header
        SalesHeader.CreateDimSetForPrepmtAccDefaultDim();

        // [THEN] Two new Dimension Set Entries added:
        Assert.AreEqual(TotalCountDimSetEntries + 2, DimensionSetEntry.Count, CountDimSetEntriesErr);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DD1" and "Dimension Value Code" = "DDV1" was created
        VerifyDimensionSetEntryIsExists(DimensionValue1."Dimension Code", DimensionValue1.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DD2" and "Dimension Value Code" = "DDV2" was created
        VerifyDimensionSetEntryIsExists(DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimIfPurchPrepmtAccNotSet()
    var
        GenPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Default Dimension]
        // [SCENARIO 363725] Show error when creating dimension set for prepayment invoice for Purchase line and "Purch. Prepayments Account" of posting groups not set.

        Initialize();
        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET" without "Purch. Prepayments Account"
        MockGenBusProdPostingGroups(GenPostingSetup, GenBusPostingGroupCode, GenProdPostingGroupCode);
        // [GIVEN] Purchase order with purchase line with prepayment invoice
        MockPurchaseHeader(PurchaseHeader);
        // [GIVEN] Purchase line has posting groups = "SET"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDime" on Purchase Header
        asserterror PurchaseHeader.CreateDimSetForPrepmtAccDefaultDim();

        // [THEN] Error: "Purch. Prepayments Account" must have a value in General Posting Setup
        Assert.ExpectedError(GenPostingSetup.FieldCaption("Purch. Prepayments Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimIfSalesPrepmtAccNotSet()
    var
        GenPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Sales] [Default Dimension]
        // [SCENARIO 363725] Show error when creating dimension set for prepayment invoice for Sales line and "Sales Prepayments Account" of posting groups not set.

        Initialize();
        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET" without "Sales Prepayments Account"
        MockGenBusProdPostingGroups(GenPostingSetup, GenBusPostingGroupCode, GenProdPostingGroupCode);
        // [GIVEN] Sales order with sales line with prepayment invoice
        MockSalesHeader(SalesHeader);
        // [GIVEN] Sales line has posting groups =  "SET"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Sales Header
        asserterror SalesHeader.CreateDimSetForPrepmtAccDefaultDim();

        // [THEN] Error: "Sales Prepayments Account" must have a value in General Posting Setup
        Assert.ExpectedError(GenPostingSetup.FieldCaption("Sales Prepayments Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimWithDifferentCombinationOfParametersPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        DimensionValueAcc: Record "Dimension Value";
        DimensionValueJob1: Record "Dimension Value";
        DimensionValueJob2: Record "Dimension Value";
        JobNo1: Code[20];
        JobNo2: Code[20];
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Default Dimension]
        // [SCENARIO 363725] Dimension Sets is created for different "Job No." of Purchase Line.

        Initialize();
        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET" with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValueAcc, GenBusPostingGroupCode, GenProdPostingGroupCode, true);

        // [GIVEN] Two jobs with different default dimensions
        // [GIVEN] First job = "J1" has "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1"
        JobNo1 := MockJobWithDfltDimension(DimensionValueJob1);
        // [GIVEN] First job = "J2" has "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2"
        JobNo2 := MockJobWithDfltDimension(DimensionValueJob2);

        // [GIVEN] Purchase order with two purchase line with different "Job No."
        MockPurchaseHeader(PurchaseHeader);
        // [GIVEN] First line has "Job No." = "J1" and posting groups = "SET"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, JobNo1);
        // [GIVEN] Second line has "Job No." = "J2" and posting groups = "SET"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, JobNo2);

        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueAcc."Dimension Code", DimensionValueAcc.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueJob1."Dimension Code", DimensionValueJob1.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueJob2."Dimension Code", DimensionValueJob2.Code);

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Purchase Header
        PurchaseHeader.CreateDimSetForPrepmtAccDefaultDim();

        // [THEN] Dimension Set Entry with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc" was created
        VerifyDimensionSetEntryIsExists(DimensionValueAcc."Dimension Code", DimensionValueAcc.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1" was created
        VerifyDimensionSetEntryIsExists(DimensionValueJob1."Dimension Code", DimensionValueJob1.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2" was created
        VerifyDimensionSetEntryIsExists(DimensionValueJob2."Dimension Code", DimensionValueJob2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimWithDifferentCombinationOfParametersSalesLine()
    var
        SalesHeader: Record "Sales Header";
        DimensionValueAcc: Record "Dimension Value";
        DimensionValueJob1: Record "Dimension Value";
        DimensionValueJob2: Record "Dimension Value";
        JobNo1: Code[20];
        JobNo2: Code[20];
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Sales] [Default Dimension]
        // [SCENARIO 363725] Dimension Sets is created for different "Job No." of Sales Line.

        Initialize();
        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET" with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValueAcc, GenBusPostingGroupCode, GenProdPostingGroupCode, true);

        // [GIVEN] Two jobs with different default dimensions
        // [GIVEN] First job = "J1" has "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1"
        JobNo1 := MockJobWithDfltDimension(DimensionValueJob1);
        // [GIVEN] First job = "J2" has "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2"
        JobNo2 := MockJobWithDfltDimension(DimensionValueJob2);

        // [GIVEN] Sales order with two sales line with different "Job No."
        MockSalesHeader(SalesHeader);
        // [GIVEN] First line has "Job No." = "J1" and posting groups = "SET"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, JobNo1);
        // [GIVEN] Second line has "Job No." = "J2" and posting groups = "SET"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, JobNo2);

        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueAcc."Dimension Code", DimensionValueAcc.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueJob1."Dimension Code", DimensionValueJob1.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueJob2."Dimension Code", DimensionValueJob2.Code);

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Purchase Header
        SalesHeader.CreateDimSetForPrepmtAccDefaultDim();

        // [THEN] Dimension Set Entry with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc" was created
        VerifyDimensionSetEntryIsExists(DimensionValueAcc."Dimension Code", DimensionValueAcc.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1" was created
        VerifyDimensionSetEntryIsExists(DimensionValueJob1."Dimension Code", DimensionValueJob1.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2" was created
        VerifyDimensionSetEntryIsExists(DimensionValueJob2."Dimension Code", DimensionValueJob2.Code);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrdStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreateDfltDimSetForPurchPrepmtWithDfltDimInPurchPrepmtAcc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Sales] [Default Dimension]
        // [SCENARIO 363725] Default Dimension Set is created on open "Purchase Order Statistics" where prepayment account has default dimensions and order has posted prepayment invoice.

        Initialize();
        // [GIVEN] Purchase order with prepayment
        CreatePartialPurchOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] Posting group with G/L Account with default dimension
        CreateDefaultDimensionAndUpdatePostingGroup(DimensionValue, PurchaseHeader."Gen. Bus. Posting Group");

        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Default Dimension set not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Open "Purchase Order Statistic"
        OpenPurchaseOrderStatistics(PurchaseHeader."No.");

        // [THEN] Default Dimension set was created
        VerifyDimensionSetEntryIsExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrdStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreateDfltDimSetForPurchasePrepmtWithDfltDimInPurchPrepmtAcc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Sales] [Default Dimension]
        // [SCENARIO 363725] Default Dimension Set is created on open "Purchase Order Statistics" where prepayment account has default dimensions and order has posted prepayment invoice.

        Initialize();
        // [GIVEN] Purchase order with prepayment
        CreatePartialPurchOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] Posting group with G/L Account with default dimension
        CreateDefaultDimensionAndUpdatePostingGroup(DimensionValue, PurchaseHeader."Gen. Bus. Posting Group");

        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Default Dimension set not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Open "Purchase Order Statistic"
        OpenPurchOrderStatistics(PurchaseHeader."No.");

        // [THEN] Default Dimension set was created
        VerifyDimensionSetEntryIsExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrdStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreateDfltDimSetForSalesPrepmtWithDfltDimInSalesPrepmtAcc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales][Default Dimension]
        // [SCENARIO 363725] Default Dimension Set is created on open "Sales Order Statistics" where prepayment account has default dimensions and order has posted prepayment invoice.
        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] Sales order with prepayment
        CreatePartialSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Posting group with G/L Account with default dimension
        CreateDefaultDimensionAndUpdatePostingGroup(DimensionValue, SalesHeader."Gen. Bus. Posting Group");

        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Default Dimension set not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Open "Sales Order Statistic"
        OpenSalesOrderStatistics(SalesHeader."No.");

        // [THEN] Default Dimension set was created
        VerifyDimensionSetEntryIsExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrdStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure CreateDfltDimSetForSalesPrepmtWithDfltDimInSalesPrepmtAccNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales][Default Dimension]
        // [SCENARIO 363725] Default Dimension Set is created on open "Sales Order Statistics" where prepayment account has default dimensions and order has posted prepayment invoice.
        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] Sales order with prepayment
        CreatePartialSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Posting group with G/L Account with default dimension
        CreateDefaultDimensionAndUpdatePostingGroup(DimensionValue, SalesHeader."Gen. Bus. Posting Group");

        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Default Dimension set not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Open "Sales Order Statistic"
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // [THEN] Default Dimension set was created
        VerifyDimensionSetEntryIsExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderWithTheSameNoAsSalesOrderWithPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnSalesHeader: Record "Sales Header";
        ReturnSalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        VATEntry: Record "VAT Entry";
    begin
        // [SCENARIO 377768] Posting of Return order with the same No. of Sales Order when Prepayment Invoice is posted for Sales Order
        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] "Check Prepmt. when Posting" is Yes in Sales & Receivables Setup
        SetCheckPrepaymentinSalesSetup(true);

        // [GIVEN] Sales Order "X" with Posted Prepayment Invoice
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        CreatePrepmtSalesOrder(SalesHeader, SalesLine);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Sales Return Order with the same No. = "X"
        ReturnSalesHeader."No." := SalesHeader."No.";
        LibrarySales.CreateSalesHeader(
          ReturnSalesHeader, ReturnSalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(ReturnSalesLine, ReturnSalesHeader, SalesLine.Type, SalesLine."No.", SalesLine.Quantity);
        ReturnSalesLine.Validate("Unit Price", SalesLine."Unit Price");
        ReturnSalesLine.Modify(true);

        // [WHEN] Post Sales Return Order using SendToPosting
        ReturnSalesHeader.SendToPosting(CODEUNIT::"Sales-Post (Yes/No)");

        // [THEN] Posted Sales Credit Memo is created with "Return Order No." = "X"
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", ReturnSalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("Return Order No.", ReturnSalesHeader."No.");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPrepaymentCreditMemoFromCopiedSalesOrder()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 377768] Posting of Prepayment Credit Memo from sales order wich was copied from another order
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        VATEntry.DeleteAll();

        // [GIVEN] Sales Order "X" with Posted Prepayment Invoice
        SalesHeader[1]."No." := LibraryUtility.GenerateGUID();
        CreatePrepmtSalesOrder(SalesHeader[1], SalesLine);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader[1]);

        // [GIVEN] Sales Order "Y" created from order "X" by Copy Document function
        LibrarySales.CreateSalesHeader(
          SalesHeader[2], SalesHeader[2]."Document Type"::Order, SalesHeader[1]."Sell-to Customer No.");
        CopySalesOrderFromSalesOrder(SalesHeader[1]."No.", SalesHeader[2]);

        // [GIVEN] Posted Prepayment Invoice for order "Y"
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader[2]);

        // [WHEN] Prepayment Credit Memo is being posted
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader[2]);

        // [THEN] Created VAT Entry has proper value of VAT amount
        VerifySalesPrepaymentCreditMemoVATAmount(SalesHeader[2]);

        // Tear down
        TearDownVATPostingSetup(SalesHeader[1]."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPrepaymentCreditMemoFromCopiedPurchOrder()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 377768] Posting of Prepayment Credit Memo from purchase order wich was copied from another order
        Initialize();

        // [GIVEN] Purchase Order "X" with Posted Prepayment Invoice
        PurchaseHeader[1]."No." := LibraryUtility.GenerateGUID();
        CreatePrepmtPurchOrder(PurchaseHeader[1]);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader[1]);

        // [GIVEN] Purchase Order "Y" created from order "X" by Copy Document function
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Order, PurchaseHeader[1]."Sell-to Customer No.");
        CopyPurchOrderFromPurchOrder(PurchaseHeader[1]."No.", PurchaseHeader[2]);
        PurchaseHeader[2]."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader[2].Modify();

        // [GIVEN] Posted Prepayment Invoice for order "Y"
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader[2]);

        // [WHEN] Prepayment Credit Memo is being posted
        PurchaseHeader[2]."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        PurchaseHeader[2].Modify();
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader[2]);

        // [THEN] Created VAT Entry has proper value of VAT amount
        VerifyPurchPrepaymentCreditMemoVATAmount(PurchaseHeader[2]);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader[1]."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtPurchaseInvoiceHasVendorLedgerEntryNoValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 222891] Posted prepayment purchase invoice has "Vendor Ledger Entry No." value
        Initialize();

        // [GIVEN] Purchase order with prepayment percent
        CreatePrepmtPurchOrder(PurchaseHeader);

        // [WHEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        FindPostedPurchaseInvoice(PurchInvHeader, PurchaseHeader."Buy-from Vendor No.");

        // [THEN] There is a vendor ledger entry for the posted prepayment invoice with "Entry No." = "X", "Amount" = "A"
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvHeader."No.");
        VendorLedgerEntry.CalcFields(Amount);
        // [THEN] Posted prepayment purchase invoice has "Vendor Ledger Entry No." = "X", "Remaining Amount" = "A", "Closed" = "No"
        PurchInvHeader.TestField("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        PurchInvHeader.CalcFields("Remaining Amount", Closed);
        PurchInvHeader.TestField("Remaining Amount", -VendorLedgerEntry.Amount);
        PurchInvHeader.TestField(Closed, false);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtPurchaseCrMemoHasVendorLedgerEntryNoValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 222891] Posted prepayment purchase credit memo has "Vendor Ledger Entry No." value
        Initialize();

        // [GIVEN] Purchase order with prepayment percent
        CreatePrepmtPurchOrder(PurchaseHeader);

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post prepayment credit memo
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        FindPostedPurchaseCrMemo(PurchCrMemoHdr, PurchaseHeader."Buy-from Vendor No.");

        // [THEN] There is a vendor ledger entry for the posted prepayment credit memo with "Entry No." = "X", "Amount" = "A"
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");
        VendorLedgerEntry.CalcFields(Amount);
        // [THEN] Posted prepayment purchase credit memo has "Vendor Ledger Entry No." = "X", "Remaining Amount" = "A", "Paid" = "No"
        PurchCrMemoHdr.TestField("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        PurchCrMemoHdr.CalcFields("Remaining Amount", Paid);
        PurchCrMemoHdr.TestField("Remaining Amount", -VendorLedgerEntry.Amount);
        PurchCrMemoHdr.TestField(Paid, false);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtSalesInvoiceHasVendorLedgerEntryNoValue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 222891] Posted prepayment sales invoice has "Cust. Ledger Entry No." value
        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] Sales order with prepayment percent
        CreatePrepmtSalesOrder(SalesHeader, SalesLine);

        // [WHEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        FindPostedSalesInvoice(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");

        // [THEN] There is a customer ledger entry for the posted prepayment invoice with "Entry No." = "X", "Amount" = "A"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceHeader."No.");
        CustLedgerEntry.CalcFields(Amount);
        // [THEN] Posted prepayment sales invoice has "Vendor Ledger Entry No." = "X", "Remaining Amount" = "A", "Closed" = "No"
        SalesInvoiceHeader.TestField("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        SalesInvoiceHeader.CalcFields("Remaining Amount", Closed);
        SalesInvoiceHeader.TestField("Remaining Amount", CustLedgerEntry.Amount);
        SalesInvoiceHeader.TestField(Closed, false);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtSalesCrMemoHasVendorLedgerEntryNoValue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 222891] Posted prepayment sales credit memo has "Cust. Ledger Entry No." value
        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] Sales order with prepayment percent
        CreatePrepmtSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post prepayment credit memo
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        FindPostedSalesCrMemo(SalesCrMemoHeader, SalesHeader."Sell-to Customer No.");

        // [THEN] There is a customer ledger entry for the posted prepayment credit memo with "Entry No." = "X", "Amount" = "A"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
        CustLedgerEntry.CalcFields(Amount);
        // [THEN] Posted prepayment sales credit memo has "Vendor Ledger Entry No." = "X", "Remaining Amount" = "A", "Paid" = "No"
        SalesCrMemoHeader.TestField("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        SalesCrMemoHeader.CalcFields("Remaining Amount", Paid);
        SalesCrMemoHeader.TestField("Remaining Amount", CustLedgerEntry.Amount);
        SalesCrMemoHeader.TestField(Paid, false);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCustomInvWithIntegerPrecisionAndChangedTotalPrepmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase]
        // [SCENARIO 261533] Posting of partial and final purchase invoice with custom prepayment, amounts, integer precision
        Initialize();
        PrepareVendorAndTwoGLAccWithSetup(VATPostingSetup, VendorNo, GLAccountNo, 10);

        // [GIVEN] GLSetup "Amount Decimal Places" = "0:2", "Unit Amount Decimal Places" = "0:2", "Amount Rounding Precision" = "1", "Unit Amount Rounding Precision" = "1"
        // [GIVEN] VAT Posting Setup "VAT %" = 10
        UpdateGeneralSetup('0:2', '0:2', 1, 1);

        // [GIVEN] Purchase Order with "Prepayment %" = 95, line with Quantity = 48, Unit Cost = 6706996.8
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 95, false);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, GLAccountNo[1], 48, 6706996.8);
        // [GIVEN] Modify total prepayment amount = 305900000
        UpdatePurchTotalPrepmtAmount(PurchaseHeader, 305900000);

        // [GIVEN] Post prepayment invoice
        DocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 30590000);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, -336490000);

        // [GIVEN] Modify Quantity to Receive = 37
        UpdatePurchQtyToReceive(PurchaseLine, 37);
        // [GIVEN] Modify prepayment amount to deduct for Line2 = 248158881
        UpdatePurchPrepmtAmtToDeduct(PurchaseLine, 248158881);

        // [GIVEN] Post invoice
        DocumentNo := PostPurchaseDocument(PurchaseHeader);
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 0);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, 0);

        // [WHEN] Post final invoice
        // The Company should be reopened for the new rounding to be loaded in COD1 ApplicationManagement.ReadRounding()
        // Since we can't reopen Company within test excution, system throws rounding error
        asserterror DocumentNo := PostPurchaseDocument(PurchaseHeader);
        VerifyValueNeedsToBeRounded(-17639431.1);

        // [THEN] The invoice has been posted
        // VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account",DocumentNo,1603585);
        // VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group",DocumentNo,-17639431);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCustomInvWithIntegerPrecisionAndChangedTotalPrepmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales]
        // [SCENARIO 261533] Posting of partial and final sales invoice with custom prepayment, amounts, integer precision
        Initialize();
        PrepareCustomerAndTwoGLAccWithSetup(VATPostingSetup, CustomerNo, GLAccountNo, 10);

        // [GIVEN] GLSetup "Amount Decimal Places" = "0:2", "Unit Amount Decimal Places" = "0:2", "Amount Rounding Precision" = "1", "Unit Amount Rounding Precision" = "1"
        // [GIVEN] VAT Posting Setup "VAT %" = 10
        UpdateGeneralSetup('0:2', '0:2', 1, 1);

        // [GIVEN] Sales Order with "Prepayment %" = 95, line with Quantity = 48, Unit Cost = 6706996.8
        CreateSalesHeader(SalesHeader, CustomerNo, 95, false);
        CreateCustomSalesLine(SalesLine, SalesHeader, GLAccountNo[1], 48, 6706996.8);
        // [GIVEN] Modify total prepayment amount = 305900000
        UpdateSalesTotalPrepmtAmount(SalesHeader, 305900000);

        // [GIVEN] Post prepayment invoice
        DocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, -30590000);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 336490000);

        // [GIVEN] Modify Quantity to Ship = 37
        UpdateSalesQtyToShip(SalesLine, 37);
        // [GIVEN] Modify prepayment amount to deduct for Line2 = 248158881
        UpdateSalesPrepmtAmtToDeduct(SalesLine, 248158881);

        // [GIVEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, 0);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 0);

        // [WHEN] Post final invoice
        // The Company should be reopened for the new rounding to be loaded in COD1 ApplicationManagement.ReadRounding()
        // Since we can't reopen Company within test excution, system throws rounding error
        asserterror DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyValueNeedsToBeRounded(17639431.1);

        // [THEN] The invoice has been posted
        // VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account",DocumentNo,-1603585);
        // VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group",DocumentNo,17639431);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchTwoLinesCustomInvWithIntegerPrecisionAndChangedTotalPrepmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VendorNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase]
        // [SCENARIO 261533] Posting of partial and final purchase invoice with custom prepayment, amounts, two lines, integer precision
        Initialize();
        PrepareVendorAndTwoGLAccWithSetup(VATPostingSetup, VendorNo, GLAccountNo, 10);

        // [GIVEN] GLSetup "Amount Decimal Places" = "0:2", "Unit Amount Decimal Places" = "0:2", "Amount Rounding Precision" = "1", "Unit Amount Rounding Precision" = "1"
        // [GIVEN] VAT Posting Setup "VAT %" = 10
        UpdateGeneralSetup('0:2', '0:2', 1, 1);

        // [GIVEN] Purchase Order with "Prepayment %" = 95 and 2 lines:
        // [GIVEN] Line1: Quantity = 10000, Unit Cost = 11432
        // [GIVEN] Line2: Quantity = 20000, Unit Cost = 11432
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 95, false);
        CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, GLAccountNo[1], 10000, 11432);
        CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, GLAccountNo[2], 20000, 11432);
        // [GIVEN] Modify total prepayment amount = 325900000
        UpdatePurchTotalPrepmtAmount(PurchaseHeader, 325900000);

        // [GIVEN] Post prepayment invoice
        DocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 32590000);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, -358490000);

        // [GIVEN] Modify Quantity to Receive: Line1 = 0, Line2 = 6577
        UpdatePurchQtyToReceive(PurchaseLine[1], 0);
        UpdatePurchQtyToReceive(PurchaseLine[2], 6577);
        // [GIVEN] Modify prepayment amount to deduct for Line2 = 75188264
        UpdatePurchPrepmtAmtToDeduct(PurchaseLine[2], 75188264);

        // [GIVEN] Post invoice
        DocumentNo := PostPurchaseDocument(PurchaseHeader);
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 0);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, 0);

        // [WHEN] Post final invoice
        // The Company should be reopened for the new rounding to be loaded in COD1 ApplicationManagement.ReadRounding()
        // Since we can't reopen Company within test excution, system throws rounding error
        asserterror DocumentNo := PostPurchaseDocument(PurchaseHeader);
        VerifyValueNeedsToBeRounded(-18766000.5); // This is a CH BUG. Should be W1 value.

        // [THEN] The invoice has been posted
        // VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account",DocumentNo,1706000);
        // VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group",DocumentNo,-18766000);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTwoLinesCustomInvWithIntegerPrecisionAndChangedTotalPrepmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales]
        // [SCENARIO 261533] Posting of partial and final sales invoice with custom prepayment, amounts, two lines, integer precision
        Initialize();
        PrepareCustomerAndTwoGLAccWithSetup(VATPostingSetup, CustomerNo, GLAccountNo, 10);

        // [GIVEN] GLSetup "Amount Decimal Places" = "0:2", "Unit Amount Decimal Places" = "0:2", "Amount Rounding Precision" = "1", "Unit Amount Rounding Precision" = "1"
        // [GIVEN] VAT Posting Setup "VAT %" = 10
        UpdateGeneralSetup('0:2', '0:2', 1, 1);

        // [GIVEN] Sales Order with "Prepayment %" = 95 and 2 lines:
        // [GIVEN] Line1: Quantity = 10000, Unit Cost = 11432
        // [GIVEN] Line2: Quantity = 20000, Unit Cost = 11432
        CreateSalesHeader(SalesHeader, CustomerNo, 95, false);
        CreateCustomSalesLine(SalesLine[1], SalesHeader, GLAccountNo[1], 10000, 11432);
        CreateCustomSalesLine(SalesLine[2], SalesHeader, GLAccountNo[2], 20000, 11432);
        // [GIVEN] Modify total prepayment amount = 325900000
        UpdateSalesTotalPrepmtAmount(SalesHeader, 325900000);

        // [GIVEN] Post prepayment invoice
        DocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, -32590000);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 358490000);

        // [GIVEN] Modify Quantity to Ship: Line1 = 0, Line2 = 6577
        UpdateSalesQtyToShip(SalesLine[1], 0);
        UpdateSalesQtyToShip(SalesLine[2], 6577);
        // [GIVEN] Modify prepayment amount to deduct for Line2 = 75188264
        UpdateSalesPrepmtAmtToDeduct(SalesLine[2], 75188264);

        // [GIVEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, 0);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 0);

        // [WHEN] Post final invoice
        // The Company should be reopened for the new rounding to be loaded in COD1 ApplicationManagement.ReadRounding()
        // Since we can't reopen Company within test excution, system throws rounding error
        asserterror DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyValueNeedsToBeRounded(18766001.5);

        // [THEN] The invoice has been posted
        // VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account",DocumentNo,-1706000);
        // VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group",DocumentNo,18766000);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithTwoLinesCustomAmountsAndInvDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 267789] Posting of a purchase order with prepayment, two item lines with custom amounts, invoice discount amount
        Initialize();
        LibraryPurchase.SetInvoiceRounding(false);
        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, 19);

        // [GIVEN] Purchase Order with "VAT %" = 19, "Prepayment %" = 92 and 2 lines:
        // [GIVEN] Line1: Quantity = 1, Unit Cost = 7462.40
        // [GIVEN] Line2: Quantity = 1, Unit Cost = 2727.17
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 92, false);
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[1], 1, 7462.4);
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[2], 1, 2727.17);
        // [GIVEN] Invoice Discount Amount = 815.17
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, 815.17);

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post invoice
        DocumentNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] The document has been poted
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 142.49);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, -892.44);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithTwoLinesCustomAmountsAndInvDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 267789] Posting of a sales order with prepayment, two item lines with custom amounts, invoice discount amount
        Initialize();
        LibrarySales.SetInvoiceRounding(false);
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, 19);

        // [GIVEN] Sales Order with "VAT %" = 19, "Prepayment %" = 92 and 2 lines:
        // [GIVEN] Line1: Quantity = 1, Unit Cost = 7462.40
        // [GIVEN] Line2: Quantity = 1, Unit Cost = 2727.17
        CreateSalesHeader(SalesHeader, CustomerNo, 92, false);
        CreateCustomItemSalesLine(SalesLine, SalesHeader, ItemNo[1], 1, 7462.4);
        CreateCustomItemSalesLine(SalesLine, SalesHeader, ItemNo[2], 1, 2727.17);
        // [GIVEN] Invoice Discount Amount = 815.17
        SetSalesInvoiceDiscountAmount(SalesHeader, 815.17);

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been poted
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, -142.49);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 892.44);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtLineAmountAfterUpdateVATOnLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Purchase] [UT] [Prices Excl. VAT]
        // [SCENARIO 267789] PurchaseLine.UpdateVATOnLines() updates "Prepmt. Line Amount" to be <= "Amount" in case of Prices Excluding VAT
        Initialize();

        // [GIVEN] Purchase Line with "Line Amount" = 1000, "Prepmt. Line Amount" = 500, "Inv. Discount Amount" = 0
        CreatePurchLineAndCalcVATAmountLine(PurchaseHeader, PurchaseLine, VATAmountLine, false, 50, 1000);

        // [GIVEN] Update Purchase Line's "Inv. Discount Amount" = 600
        PurchaseLine."Inv. Discount Amount" := 600;
        PurchaseLine.Modify();

        // [WHEN] Call PurchaseLine.UpdateVATOnLines()
        PurchaseLine.UpdateVATOnLines(0, PurchaseHeader, PurchaseLine, VATAmountLine);

        // [THEN] PurchaseLine."Prepmt. Line Amount" = 200
        PurchaseLine.TestField(Amount, 400);
        PurchaseLine.TestField("Prepmt. Line Amount", 200);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtLineAmountAfterUpdateVATOnLinesPricesInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Purchase] [UT] [Prices Incl. VAT]
        // [SCENARIO 267789] PurchaseLine.UpdateVATOnLines() updates "Prepmt. Line Amount" to be <= "Amount Including VAT" in case of Prices Including VAT
        Initialize();

        // [GIVEN] Purchase Line with "Line Amount" = 1000, "Prepmt. Line Amount" = 500, "Inv. Discount Amount" = 0
        CreatePurchLineAndCalcVATAmountLine(PurchaseHeader, PurchaseLine, VATAmountLine, true, 50, 1000);

        // [GIVEN] Update Purchase Line's "Inv. Discount Amount" = 600
        PurchaseLine."Inv. Discount Amount" := 600;
        PurchaseLine.Modify();

        // [WHEN] Call PurchaseLine.UpdateVATOnLines()
        PurchaseLine.UpdateVATOnLines(0, PurchaseHeader, PurchaseLine, VATAmountLine);

        // [THEN] PurchaseLine."Prepmt. Line Amount" = 200
        PurchaseLine.TestField("Amount Including VAT", 400);
        PurchaseLine.TestField("Prepmt. Line Amount", 200);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtLineAmountAfterUpdateVATOnLinesNegativeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 267789] PurchaseLine."Prepmt. Line Amount" remains zero after UpdateVATOnLines() with negative Amount
        Initialize();

        // [GIVEN] Purchase Line with "Line Amount" = -1000, "Prepmt. Line Amount" = 0, "Inv. Discount Amount" = 0
        CreatePurchLineAndCalcVATAmountLine(PurchaseHeader, PurchaseLine, VATAmountLine, false, 0, -1000);

        // [GIVEN] Update Purchase Line's "Inv. Discount Amount" = -600
        PurchaseLine."Inv. Discount Amount" := -600;
        PurchaseLine.Modify();

        // [WHEN] Call PurchaseLine.UpdateVATOnLines()
        PurchaseLine.UpdateVATOnLines(0, PurchaseHeader, PurchaseLine, VATAmountLine);

        // [THEN] PurchaseLine."Prepmt. Line Amount" = 0
        PurchaseLine.TestField(Amount, -400);
        PurchaseLine.TestField("Prepmt. Line Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtLineAmountAfterUpdateVATOnLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Sales] [UT] [Prices Excl. VAT]
        // [SCENARIO 267789] SalesLine.UpdateVATOnLines() updates "Prepmt. Line Amount" to be <= "Amount" in case of Prices Excluding VAT
        Initialize();

        // [GIVEN] Sales Line with "Line Amount" = 1000, "Prepmt. Line Amount" = 500, "Inv. Discount Amount" = 0
        CreateCustomSalesLineAndCalcVATAmountLine(SalesHeader, SalesLine, VATAmountLine, false, 50, 1000);

        // [GIVEN] Update Sales Line's "Inv. Discount Amount" = 600
        SalesLine."Inv. Discount Amount" := 600;
        SalesLine.Modify();

        // [WHEN] Call SalesLine.UpdateVATOnLines()
        SalesLine.UpdateVATOnLines(0, SalesHeader, SalesLine, VATAmountLine);

        // [THEN] SalesLine."Prepmt. Line Amount" = 200
        SalesLine.TestField(Amount, 400);
        SalesLine.TestField("Prepmt. Line Amount", 200);

        SalesHeader.Delete(true); // avoid breaking further tests
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtLineAmountAfterUpdateVATOnLinesPricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Sales] [UT] [Prices Incl. VAT]
        // [SCENARIO 267789] SalesLine.UpdateVATOnLines() updates "Prepmt. Line Amount" to be <= "Amount Including VAT" in case of Prices Including VAT
        Initialize();

        // [GIVEN] Sales Line with "Line Amount" = 1000, "Prepmt. Line Amount" = 500, "Inv. Discount Amount" = 0
        CreateCustomSalesLineAndCalcVATAmountLine(SalesHeader, SalesLine, VATAmountLine, true, 50, 1000);

        // [GIVEN] Update Sales Line's "Inv. Discount Amount" = 600
        SalesLine."Inv. Discount Amount" := 600;
        SalesLine.Modify();

        // [WHEN] Call SalesLine.UpdateVATOnLines()
        SalesLine.UpdateVATOnLines(0, SalesHeader, SalesLine, VATAmountLine);

        // [THEN] SalesLine."Prepmt. Line Amount" = 200
        SalesLine.TestField("Amount Including VAT", 400);
        SalesLine.TestField("Prepmt. Line Amount", 200);

        SalesHeader.Delete(true); // avoid breaking further tests
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtLineAmountAfterUpdateVATOnLinesNegativeAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 267789] SalesLine."Prepmt. Line Amount" remains zero after UpdateVATOnLines() with negative Amount
        Initialize();

        // [GIVEN] Sales Line with "Line Amount" = -1000, "Prepmt. Line Amount" = 0, "Inv. Discount Amount" = 0
        CreateCustomSalesLineAndCalcVATAmountLine(SalesHeader, SalesLine, VATAmountLine, false, 0, -1000);

        // [GIVEN] Update Sales Line's "Inv. Discount Amount" = -600
        SalesLine."Inv. Discount Amount" := -600;
        SalesLine.Modify();

        // [WHEN] Call SalesLine.UpdateVATOnLines()
        SalesLine.UpdateVATOnLines(0, SalesHeader, SalesLine, VATAmountLine);

        // [THEN] SalesLine."Prepmt. Line Amount" = 0
        SalesLine.TestField(Amount, -400);
        SalesLine.TestField("Prepmt. Line Amount", 0);

        SalesHeader.Delete(true); // avoid breaking further tests
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalSalesInvoiceWithOneHundredPrepmtAndInvDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 273512] Stan can post sales invoice with "Prepayment %" = 100 and non-zero "Invoice Discount %"

        Initialize();
        LibrarySales.SetInvoiceRounding(false);
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, 19);

        // [GIVEN] Sales Order with "Line Amount" = 4000, "Invoice Discount Amount" = 500, "Prepayment %" = 100
        CreateSalesHeader(SalesHeader, CustomerNo, 100, false);
        CreateCustomItemSalesLine(
          SalesLine, SalesHeader, ItemNo[1], LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2));
        SetSalesInvoiceDiscountAmount(SalesHeader, SalesLine.Amount / LibraryRandom.RandIntInRange(3, 10));
        SalesLine.Find();

        // [GIVEN] Posted prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Multiple G/L Entries posted with "G/L Account" = "Sales VAT Account" and total amount equal 0
        VerifyGLEntriesAmount(0, DocumentNo, VATPostingSetup."Sales VAT Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Sales Inv. Discount Account" and Amount = 500
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(SalesLine."Inv. Discount Amount", DocumentNo, GeneralPostingSetup."Sales Inv. Disc. Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Sales Prepayment Account" and Amount = 3500
        VerifyGLEntry(SalesLine."Prepmt. Line Amount", DocumentNo, GeneralPostingSetup."Sales Prepayments Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Sales Account" and Amount = -4000
        VerifyGLEntry(-SalesLine."Line Amount", DocumentNo, GeneralPostingSetup."Sales Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Receivables Account" and Amount = 0
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        VerifyGLEntry(0, DocumentNo, CustomerPostingGroup."Receivables Account");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesOrderStatisticsForInvDiscPageHandler')]
    procedure FinalSalesInvoiceWithOneHundredPrepmtAndInvDiscStatsPage()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 273512] Stan can post sales invoice with "Prepayment %" = 100 and non-zero "Invoice Discount %" open and reopen Statistics Page without issues

        Initialize();
        LibrarySales.SetInvoiceRounding(false);
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, 19);

        // [GIVEN] Sales Order with "Line Amount" = 4000, "Invoice Discount Amount" = 500, "Prepayment %" = 100
        CreateSalesHeader(SalesHeader, CustomerNo, 100, false);
        CreateCustomItemSalesLine(
          SalesLine, SalesHeader, ItemNo[1], LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2));
        SetSalesInvoiceDiscountAmount(SalesHeader, SalesLine.Amount / LibraryRandom.RandIntInRange(3, 10));
        SalesLine.Find();

        // [GIVEN] Posted prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise: Open Sales Order Statistics Page.
        LibraryVariableStorage.Enqueue(SalesLine."Inv. Disc. Amount to Invoice");
        OpenSalesOrderStatistics(SalesHeader."No.");

        // Exercise: Re-Open Sales Order Statistics Page.
        LibraryVariableStorage.Enqueue(SalesLine."Inv. Disc. Amount to Invoice");
        OpenSalesOrderStatistics(SalesHeader."No.");
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesOrderStatisticsForInvDiscPageHandlerNM')]
    procedure FinalSalesInvoiceWithOneHundredPrepmtAndInvDiscStatsPageNM()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 273512] Stan can post sales invoice with "Prepayment %" = 100 and non-zero "Invoice Discount %" open and reopen Statistics Page without issues

        Initialize();
        LibrarySales.SetInvoiceRounding(false);
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, 19);

        // [GIVEN] Sales Order with "Line Amount" = 4000, "Invoice Discount Amount" = 500, "Prepayment %" = 100
        CreateSalesHeader(SalesHeader, CustomerNo, 100, false);
        CreateCustomItemSalesLine(
          SalesLine, SalesHeader, ItemNo[1], LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2));
        SetSalesInvoiceDiscountAmount(SalesHeader, SalesLine.Amount / LibraryRandom.RandIntInRange(3, 10));
        SalesLine.Find();

        // [GIVEN] Posted prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise: Open Sales Order Statistics Page.
        LibraryVariableStorage.Enqueue(SalesLine."Inv. Disc. Amount to Invoice");
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // Exercise: Re-Open Sales Order Statistics Page.
        LibraryVariableStorage.Enqueue(SalesLine."Inv. Disc. Amount to Invoice");
        OpenSalesOrderStatisticsNM(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalPurchInvoiceWithOneHundredPrepmtAndInvDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 273512] Stan can post purchase invoice with "Prepayment %" = 100 and non-zero "Invoice Discount %"

        Initialize();
        LibraryPurchase.SetInvoiceRounding(false);
        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, 19);

        // [GIVEN] Purchase Order with "Line Amount" = 4000, "Invoice Discount Amount" = 500, "Prepayment %" = 100
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 100, false);
        CreateCustomItemPurchaseLine(
          PurchaseLine, PurchaseHeader, ItemNo[1], LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2));
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, PurchaseLine.Amount / LibraryRandom.RandIntInRange(3, 10));
        PurchaseLine.Find();

        // [GIVEN] Posted prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchaseHeader.Find();
        PurchaseHeader."Vendor Invoice No." := IncStr(PurchaseHeader."Vendor Invoice No.");
        PurchaseHeader.Modify();

        // [WHEN] Post final invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Multiple G/L Entries posted with "G/L Account" = "Purchase VAT Account" and total amount equal 0
        VerifyGLEntriesAmount(0, DocumentNo, VATPostingSetup."Purchase VAT Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Purch. Inv. Discount Account" and Amount = -500
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(-PurchaseLine."Inv. Discount Amount", DocumentNo, GeneralPostingSetup."Purch. Inv. Disc. Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Purch. Prepayment Account" and Amount = -3500
        VerifyGLEntry(-PurchaseLine."Prepmt. Line Amount", DocumentNo, GeneralPostingSetup."Purch. Prepayments Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Purch. Account" and Amount = 4000
        VerifyGLEntry(PurchaseLine."Line Amount", DocumentNo, GeneralPostingSetup."Purch. Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Payables Account" and Amount = 0
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        VerifyGLEntry(0, DocumentNo, VendorPostingGroup."Payables Account");

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceAfterGetReceiptLinesWithPrepayments()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 278361] Purchase Invoice posting created with GetReceiptLines from posted receipts linked with prepayment Purchase Order
        Initialize();

        // [GIVEN] VAT Posting Setup with VAT % = 24
        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, 24);

        // [GIVEN] Purchase Order with 30% prepayment, Item with Quantity = 620 and Unit Cost = 26,67
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 30, false);
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[1], 620, 27.67);

        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Posted Receipt with "Qty. to Receive" = 585
        UpdatePurchQtyToReceive(PurchaseLine, 585);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Posted Receipt with "Qty. to Receive" = 30
        PurchaseLine.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] A new Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // [GIVEN] Populate lines using GetReceiptLines, select both receipts
        GetPurchaseReceiptLines(PurchaseHeader);

        // [WHEN] Post the invoice
        // [THEN] The invoice has been posted
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceAfterGetShipmentLinesWithPrepayments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 278361] Sales Invoice posting created with GetShipmentLines from posted shipments linked with prepayment Sales Order
        Initialize();

        // [GIVEN] VAT Posting Setup with VAT % = 24
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, 24);

        // [GIVEN] Sales Order with 30% prepayment, Item with Quantity = 620 and Unit Cost = 26,67
        CreateSalesHeader(SalesHeader, CustomerNo, 30, false);
        CreateCustomItemSalesLine(SalesLine, SalesHeader, ItemNo[1], 620, 27.67);

        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Posted Shipment with "Qty. to Receive" = 585
        UpdateSalesQtyToShip(SalesLine, 585);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Posted Shipment with "Qty. to Receive" = 30
        SalesLine.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] A new Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] Populate lines using GetShipmentLines, select both shipments
        GetSalesShipmentLines(SalesHeader);

        // [WHEN] Post the invoice
        // [THEN] The invoice has been posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    procedure PostPurchInvoiceAfterGetReceiptLinesWithPrepaymentAndFullyInvoicedReceipt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
        PurchReceiptNo: Code[20];
        PrepmtPerc: Decimal;
    begin
        // [FEATURE] [Purchase] [Receipt] [Invoice] [Get Receipt Lines]
        // [SCENARIO 349477] Posting purchase invoice for not invoiced receipt when there has been another fully invoiced receipt in the purchase order with prepayment.
        Initialize();
        PrepmtPerc := LibraryRandom.RandIntInRange(10, 90);

        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, LibraryRandom.RandInt(20));

        // [GIVEN] Purchase order with 30% prepayment.
        // [GIVEN] Purchase line for 10 pcs of an item.
        CreatePurchaseHeader(PurchaseHeader, VendorNo, PrepmtPerc, false);
        CreateCustomItemPurchaseLine(
          PurchaseLine, PurchaseHeader, ItemNo[1], LibraryRandom.RandIntInRange(20, 40), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Post the prepayment invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Set "Qty. to Receive" = "Qty. to Invoice" = 6 pcs and post the purchase.
        UpdatePurchQtyToReceive(PurchaseLine, LibraryRandom.RandInt(10));
        UpdatePurchInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Post the receipt for the remaining 4 pcs.
        PurchaseHeader.Find();
        PurchReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Create purchase invoice for the second receipt using "Get Receipt Lines".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchRcptLine.SetRange("Document No.", PurchReceiptNo);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [THEN] The invoice can be posted.
        PurchaseHeader.CalcFields(Amount);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] The invoiced amount is equal to 4 * "unit cost" - 30% prepayment.
        PurchInvHeader.CalcFields(Amount);
        Assert.AreNearlyEqual(
          PurchaseHeader.Amount * (1 - PrepmtPerc / 100), PurchInvHeader.Amount, LibraryERM.GetAmountRoundingPrecision(), '');

        // Tear down.
        TearDownVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group");
    end;

    [Test]
    procedure PostPurchInvoiceAfterGetReceiptLinesWithPrepaymentAndPartiallyInvoicedReceipt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
        PrepmtPerc: Decimal;
    begin
        // [FEATURE] [Purchase] [Receipt] [Invoice] [Get Receipt Lines]
        // [SCENARIO 349477] Posting purchase invoice for partially invoiced receipt in purchase order with prepayment.
        Initialize();
        PrepmtPerc := 30;

        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, LibraryRandom.RandInt(20));

        // [GIVEN] Purchase order with 30% prepayment.
        // [GIVEN] Purchase line for 10 pcs of an item, unit cost = 100.
        CreatePurchaseHeader(PurchaseHeaderOrder, VendorNo, PrepmtPerc, false);
        CreateCustomItemPurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, ItemNo[1], 10, 100.0);

        // [GIVEN] Post the prepayment invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeaderOrder);

        // [GIVEN] Set "Qty. to Receive" = 6 pcs, "Qty. to Invoice" = 2 pcs and post the purchase.
        PurchaseLineOrder.Find();
        PurchaseLineOrder.Validate("Qty. to Receive", 6);
        PurchaseLineOrder.Validate("Qty. to Invoice", 2);
        PurchaseLineOrder.Modify(true);

        UpdatePurchInvoiceNo(PurchaseHeaderOrder);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, true);

        // [WHEN] Create purchase invoice for another 4 pcs.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");
        GetPurchaseReceiptLines(PurchaseHeaderInvoice);

        // [THEN] "Prepmt Amt to Deduct" on the invoice line is equal to 120, that is 4 (qty. to invoice) * 100 (unit cost) * 30% (prepayment).
        FindPurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineOrder."No.");
        PurchaseLineInvoice.TestField("Prepmt Amt to Deduct", 4 * 100.0 * PrepmtPerc / 100);

        // [THEN] The invoice can be posted.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true));

        // [THEN] The invoiced amount is equal to 280 (4 * 100.0 * 70%).
        PurchInvHeader.CalcFields(Amount);
        PurchInvHeader.TestField(Amount, 4 * 100.0 * (1 - PrepmtPerc / 100));

        // Tear down.
        TearDownVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group");
    end;

    [Test]
    procedure PostSalesInvoiceAfterGetShipmentLinesWithPrepaymentAndFullyInvoicedShipment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        SalesShipmentNo: Code[20];
        PrepmtPerc: Decimal;
    begin
        // [FEATURE] [Sales] [Shipment] [Invoice] [Get Shipment Lines]
        // [SCENARIO 349477] Posting sales invoice for not invoiced shipment when there has been another fully invoiced shipment in the sales order with prepayment.
        Initialize();
        PrepmtPerc := LibraryRandom.RandIntInRange(10, 90);

        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, LibraryRandom.RandInt(20));

        // [GIVEN] Sales order with 30% prepayment.
        // [GIVEN] Sales line for 10 pcs of an item.
        CreateSalesHeader(SalesHeader, CustomerNo, PrepmtPerc, false);
        CreateCustomItemSalesLine(
          SalesLine, SalesHeader, ItemNo[1], LibraryRandom.RandIntInRange(20, 40), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Post the prepayment invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Set "Qty. to Ship" = "Qty. to Invoice" = 6 pcs and post the order.
        UpdateSalesQtyToShip(SalesLine, LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Post the shipment for the remaining 4 pcs.
        SalesHeader.Find();
        SalesShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Create sales invoice for the second shipment using "Get Shipment Lines".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentNo);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);

        // [THEN] The invoice can be posted.
        SalesHeader.CalcFields(Amount);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] The invoiced amount is equal to 4 * "unit cost" - 30% prepayment.
        SalesInvoiceHeader.CalcFields(Amount);
        Assert.AreNearlyEqual(
          SalesHeader.Amount * (1 - PrepmtPerc / 100), SalesInvoiceHeader.Amount, LibraryERM.GetAmountRoundingPrecision(), '');

        // Tear down.
        TearDownVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group");
    end;

    [Test]
    procedure PostSalesInvoiceAfterGetShipmentLinesWithPrepaymentAndPartiallyInvoicedShipment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        SalesLineInvoice: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        PrepmtPerc: Decimal;
    begin
        // [FEATURE] [Sales] [Shipment] [Invoice] [Get Shipment Lines]
        // [SCENARIO 349477] Posting sales invoice for partially invoiced shipment in sales order with prepayment.
        Initialize();
        PrepmtPerc := 30;

        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, LibraryRandom.RandInt(20));

        // [GIVEN] Sales order with 30% prepayment.
        // [GIVEN] Sales line for 10 pcs of an item, unit price = 100.
        CreateSalesHeader(SalesHeaderOrder, CustomerNo, PrepmtPerc, false);
        CreateCustomItemSalesLine(SalesLineOrder, SalesHeaderOrder, ItemNo[1], 10, 100.0);

        // [GIVEN] Post the prepayment invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeaderOrder);

        // [GIVEN] Set "Qty. to Ship" = 6 pcs, "Qty. to Invoice" = 2 pcs and post the order.
        SalesLineOrder.Find();
        SalesLineOrder.Validate("Qty. to Ship", 6);
        SalesLineOrder.Validate("Qty. to Invoice", 2);
        SalesLineOrder.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        // [WHEN] Create sales invoice for another 4 pcs.
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");
        GetSalesShipmentLines(SalesHeaderInvoice);

        // [THEN] "Prepmt Amt to Deduct" on the invoice line is equal to 120, that is 4 (qty. to invoice) * 100 (unit price) * 30% (prepayment).
        FindSalesLine(SalesLineInvoice, SalesHeaderInvoice, SalesLineOrder."No.");
        SalesLineInvoice.TestField("Prepmt Amt to Deduct", 4 * 100.0 * PrepmtPerc / 100);

        // [THEN] The invoice can be posted.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true));

        // [THEN] The invoiced amount is equal to 280 (4 * 100.0 * 70%).
        SalesInvoiceHeader.CalcFields(Amount);
        SalesInvoiceHeader.TestField(Amount, 4 * 100.0 * (1 - PrepmtPerc / 100));

        // Tear down.
        TearDownVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingPrepaymentPctAfterInvoiceDiscountSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Invoice Discount] [Prepayment]
        // [SCENARIO 291647] Prepayment Amount on Sales Order takes Invoice Discount into account when validated second
        Initialize();

        // [GIVEN] Sales Order with one Sales Line
        CreateSalesOrderWithOneLine(SalesHeader);

        // [WHEN] Setting "Invoice Discount Amount" and then 100% Prepayment
        SetSalesInvoiceDiscountAmount(SalesHeader, LibraryRandom.RandDec(10, 2));
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);

        // [THEN] Sales Line's "Prepmt. Line Amount" = "Amount"
        VerifySalesLineFullPrepaymentWithDiscount(SalesHeader."No.", SalesLine."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingInvoiceDiscountAfterPrepaymentPctSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Invoice Discount] [Prepayment]
        // [SCENARIO 291647] Prepayment Amount on Sales Order takes Invoice Discount into account when validated first
        Initialize();

        // [GIVEN] Sales Order with one Sales Line
        CreateSalesOrderWithOneLine(SalesHeader);

        // [WHEN] Setting 100% Prepayment and then Invoice Discount Amount
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);
        SetSalesInvoiceDiscountAmount(SalesHeader, LibraryRandom.RandDec(10, 2));

        // [THEN] Sales Line's "Prepmt. Line Amount" = "Amount"
        VerifySalesLineFullPrepaymentWithDiscount(SalesHeader."No.", SalesLine."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingPrepaymentPctAfterInvoiceDiscountPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Invoice Discount] [Prepayment]
        // [SCENARIO 291647] Prepayment Amount on Purchase Order takes Invoice Discount into account when validated second
        Initialize();

        // [GIVEN] Purchase Order with one Purchase Line
        CreatePurchaseOrderWithOneLine(PurchaseHeader);

        // [WHEN] Setting "Invoice Discount Amount" and then 100% Prepayment
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);

        // [THEN] Purchase Line's "Prepmt. Line Amount" = "Amount"
        VerifyPurchaseLineFullPrepaymentWithDiscount(PurchaseHeader."No.", PurchaseLine."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingInvoiceDiscountAfterPrepaymentPctPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Invoice Discount] [Prepayment]
        // [SCENARIO 291647] Prepayment Amount on Purchase Order takes Invoice Discount into account when validated first
        Initialize();

        // [GIVEN] Purchase Order with one Purchase Line
        CreatePurchaseOrderWithOneLine(PurchaseHeader);

        // [WHEN] Setting "Invoice Discount Amount" and then 100% Prepayment
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, LibraryRandom.RandDec(10, 2));

        // [THEN] Purchase Line's "Prepmt. Line Amount" = "Amount"
        VerifyPurchaseLineFullPrepaymentWithDiscount(PurchaseHeader."No.", PurchaseLine."Document Type"::Order);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrdStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure AmountOnStatisticsPageEqualToSumOfSalesLinesAfterPostingPrepmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Order] [Statistics] [Line Discount]
        // [SCENARIO 335740] Line Amount on Sales Order Statistics page is equal to sum of line amounts in sales order, for which line amount is increased after 100% prepayment is invoiced.
        Initialize();

        // [GIVEN] Sales order set up for 100% prepayment.
        // [GIVEN] Set line discount 10% on the sales line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group");

        // [GIVEN] Post prepayment invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Reopen the sales order and reset line discount to 0%.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Find();
        SalesLine.Validate("Line Discount %", 0);
        SalesLine.Modify(true);

        // [WHEN] Open Sales Order Statistics page.
        OpenSalesOrderStatistics(SalesHeader."No.");

        // [THEN] Line Amount on the statistics page is equal to line amount on the sales line.
        Assert.AreEqual(SalesLine.Amount, LibraryVariableStorage.DequeueDecimal(), '');

        LibraryVariableStorage.AssertEmpty();
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrdStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure AmountOnStatisticsPageEqualToSumOfSalesLinesAfterPostingPrepmtNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Order] [Statistics] [Line Discount]
        // [SCENARIO 335740] Line Amount on Sales Order Statistics page is equal to sum of line amounts in sales order, for which line amount is increased after 100% prepayment is invoiced.
        Initialize();

        // [GIVEN] Sales order set up for 100% prepayment.
        // [GIVEN] Set line discount 10% on the sales line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group");

        // [GIVEN] Post prepayment invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Reopen the sales order and reset line discount to 0%.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Find();
        SalesLine.Validate("Line Discount %", 0);
        SalesLine.Modify(true);

        // [WHEN] Open Sales Order Statistics page.
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // [THEN] Line Amount on the statistics page is equal to line amount on the sales line.
        Assert.AreEqual(SalesLine.Amount, LibraryVariableStorage.DequeueDecimal(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrdStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure AmountOnStatisticsPageEqualToSumOfPurchLinesAfterPostingPrepmt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Order] [Statistics] [Line Discount]
        // [SCENARIO 335740] Line Amount on Purchase Order Statistics page is equal to sum of line amounts in purchase order, for which line amount is increased after 100% prepayment is invoiced.
        Initialize();

        // [GIVEN] Purchase order set up for 100% prepayment.
        // [GIVEN] Set line discount 10% on the purchase line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        LibraryERM.UpdatePurchPrepmtAccountVATGroup(
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");

        // [GIVEN] Post prepayment invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Reopen the purchase order and reset line discount to 0%.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate("Line Discount %", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Open Purchase Order Statistics page.
        OpenPurchaseOrderStatistics(PurchaseHeader."No.");

        // [THEN] Line Amount on the statistics page is equal to line amount on the purchase line.
        Assert.AreEqual(PurchaseLine.Amount, LibraryVariableStorage.DequeueDecimal(), '');

        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrdStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure AmountOnStatisticsPageEqualToSumOfPurchaseLinesAfterPostingPrepmt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Order] [Statistics] [Line Discount]
        // [SCENARIO 335740] Line Amount on Purchase Order Statistics page is equal to sum of line amounts in purchase order, for which line amount is increased after 100% prepayment is invoiced.
        Initialize();

        // [GIVEN] Purchase order set up for 100% prepayment.
        // [GIVEN] Set line discount 10% on the purchase line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        LibraryERM.UpdatePurchPrepmtAccountVATGroup(
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");

        // [GIVEN] Post prepayment invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Reopen the purchase order and reset line discount to 0%.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate("Line Discount %", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Open Purchase Order Statistics page.
        OpenPurchOrderStatistics(PurchaseHeader."No.");

        // [THEN] Line Amount on the statistics page is equal to line amount on the purchase line.
        Assert.AreEqual(PurchaseLine.Amount, LibraryVariableStorage.DequeueDecimal(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReducingSalesInvDiscountUpdatesPrepaymentAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 338021] Reducing sales invoice discount updates prepayment amount.
        Initialize();

        // [GIVEN] Sales order with 100% prepayment.
        CreateSalesHeader(SalesHeader, LibrarySales.CreateCustomerNo(), 100, false);
        CreateCustomItemSalesLine(
          SalesLine, SalesHeader, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Set Invoice Discount = 50%.
        SetSalesInvoiceDiscountAmount(SalesHeader, SalesLine."Line Amount" / 2);

        // [WHEN] Set Invoice Discount back to 0%.
        SetSalesInvoiceDiscountAmount(SalesHeader, 0);

        // [THEN] Prepayment amount is equal to line amount on the sales line.
        SalesLine.Find();
        SalesLine.TestField("Prepmt. Line Amount", SalesLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReducingPurchInvDiscountUpdatesPrepaymentAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 338021] Reducing purchase invoice discount updates prepayment amount.
        Initialize();

        // [GIVEN] Purchase order with 100% prepayment.
        CreatePurchaseHeader(PurchaseHeader, LibraryPurchase.CreateVendorNo(), 100, false);
        CreateCustomItemPurchaseLine(
          PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Set Invoice Discount = 50%.
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, PurchaseLine."Line Amount" / 2);

        // [WHEN] Set Invoice Discount back to 0%.
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, 0);

        // [THEN] Prepayment amount is equal to line amount on the purchase line.
        PurchaseLine.Find();
        PurchaseLine.TestField("Prepmt. Line Amount", PurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderConsequentPrepaymentPostingWithCommentLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCommentLine: Record "Sales Comment Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        ExpectedComment: array[2] of Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 337525] System copies sales order's comments to posted prepayment invoices and credit memos when setup is enabled.
        Initialize();
        LibrarySales.SetCopyCommentsOrderToInvoiceInSetup(true);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreateFullPrepaymentSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", false);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", 0);

        CreateSalesLine(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine[1]."Line No.");
        ExpectedComment[1] := SalesCommentLine.Comment;

        UpdateSalesPrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          SalesLine[1]."Gen. Bus. Posting Group", SalesLine[1]."Gen. Prod. Posting Group");

        PostedInvoiceNo[1] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        LibrarySales.ReopenSalesDocument(SalesHeader);

        CreateSalesLine(SalesLine[2], SalesHeader);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine[2]."Line No.");
        ExpectedComment[2] := SalesCommentLine.Comment;

        PostedInvoiceNo[2] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        PostedCreditMemoNo := LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader);

        VerifyPostedSalesInvoiceCommentLine(PostedInvoiceNo[1], ExpectedComment[1], 2, 1);
        VerifyPostedSalesInvoiceCommentLine(PostedInvoiceNo[2], ExpectedComment[2], 2, 1);
        VerifyPostedSalesCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[1], 10000, 3, 2);
        VerifyPostedSalesCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[2], 20000, 3, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderConsequentPrepaymentPostingWithCommentLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCommentLine: Record "Purch. Comment Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        ExpectedComment: array[2] of Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 337525] System copies purchase order's comments to posted prepayment invoices and credit memos when setup is enabled.
        Initialize();
        LibraryPurchase.SetCopyCommentsOrderToInvoiceInSetup(true);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreateFullPrepaymentPurchHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", false);
        LibraryPurchase.CreatePurchCommentLine(PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", 0);

        CreatePurchLine(PurchaseLine[1], PurchaseHeader);
        LibraryPurchase.CreatePurchCommentLine(
          PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine[1]."Line No.");
        ExpectedComment[1] := PurchCommentLine.Comment;

        UpdatePurchasePrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          PurchaseLine[1]."Gen. Bus. Posting Group", PurchaseLine[1]."Gen. Prod. Posting Group");

        PostedInvoiceNo[1] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        CreatePurchLine(PurchaseLine[2], PurchaseHeader);
        LibraryPurchase.CreatePurchCommentLine(
          PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine[2]."Line No.");
        ExpectedComment[2] := PurchCommentLine.Comment;

        PostedInvoiceNo[2] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PostedCreditMemoNo := LibraryPurchase.PostPurchasePrepaymentCreditMemo(PurchaseHeader);

        VerifyPostedPurchaseInvoiceCommentLine(PostedInvoiceNo[1], ExpectedComment[1], 2, 1);
        VerifyPostedPurchaseInvoiceCommentLine(PostedInvoiceNo[2], ExpectedComment[2], 2, 1);
        VerifyPostedPurchaseCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[1], 10000, 3, 2);
        VerifyPostedPurchaseCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[2], 20000, 3, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderConsequentPrepaymentPostingWithCommentLines_SetupDisabled()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCommentLine: Record "Sales Comment Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        ExpectedComment: array[2] of Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 337525] System does not copy sales order's comments to posted prepayment invoices and credit memos when setup is disabled.
        Initialize();
        LibrarySales.SetCopyCommentsOrderToInvoiceInSetup(false);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreateFullPrepaymentSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", false);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", 0);

        CreateSalesLine(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine[1]."Line No.");
        ExpectedComment[1] := SalesCommentLine.Comment;

        UpdateSalesPrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          SalesLine[1]."Gen. Bus. Posting Group", SalesLine[1]."Gen. Prod. Posting Group");

        PostedInvoiceNo[1] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        LibrarySales.ReopenSalesDocument(SalesHeader);

        CreateSalesLine(SalesLine[2], SalesHeader);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine[2]."Line No.");
        ExpectedComment[2] := SalesCommentLine.Comment;

        PostedInvoiceNo[2] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        PostedCreditMemoNo := LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader);

        VerifyPostedSalesInvoiceCommentLine(PostedInvoiceNo[1], ExpectedComment[1], 0, 0);
        VerifyPostedSalesInvoiceCommentLine(PostedInvoiceNo[2], ExpectedComment[2], 0, 0);
        VerifyPostedSalesCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[1], 10000, 0, 0);
        VerifyPostedSalesCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[2], 30000, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderConsequentPrepaymentPostingWithCommentLines_SetupDisabled()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCommentLine: Record "Purch. Comment Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        ExpectedComment: array[2] of Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 337525] System does not copy purchase order's comments to posted prepayment invoices and credit memos when setup is disabled.
        Initialize();
        LibraryPurchase.SetCopyCommentsOrderToInvoiceInSetup(false);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreateFullPrepaymentPurchHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", false);
        LibraryPurchase.CreatePurchCommentLine(PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", 0);

        CreatePurchLine(PurchaseLine[1], PurchaseHeader);
        LibraryPurchase.CreatePurchCommentLine(
          PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine[1]."Line No.");
        ExpectedComment[1] := PurchCommentLine.Comment;

        UpdatePurchasePrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          PurchaseLine[1]."Gen. Bus. Posting Group", PurchaseLine[1]."Gen. Prod. Posting Group");

        PostedInvoiceNo[1] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        CreatePurchLine(PurchaseLine[2], PurchaseHeader);
        LibraryPurchase.CreatePurchCommentLine(
          PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine[2]."Line No.");
        ExpectedComment[2] := PurchCommentLine.Comment;

        PostedInvoiceNo[2] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PostedCreditMemoNo := LibraryPurchase.PostPurchasePrepaymentCreditMemo(PurchaseHeader);

        VerifyPostedPurchaseInvoiceCommentLine(PostedInvoiceNo[1], ExpectedComment[1], 0, 0);
        VerifyPostedPurchaseInvoiceCommentLine(PostedInvoiceNo[2], ExpectedComment[2], 0, 0);
        VerifyPostedPurchaseCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[1], 10000, 0, 0);
        VerifyPostedPurchaseCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[2], 30000, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderConsequentCompressedPrepaymentPostingWithCommentLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCommentLine: Record "Sales Comment Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        ExpectedComment: array[2] of Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 342788] System copies sales order's comments to posted prepayment invoices and credit memos when setup is enabled.
        Initialize();
        LibrarySales.SetCopyCommentsOrderToInvoiceInSetup(true);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreateFullPrepaymentSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", true);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", 0);

        CreateSalesLine(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine[1]."Line No.");
        ExpectedComment[1] := SalesCommentLine.Comment;

        UpdateSalesPrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          SalesLine[1]."Gen. Bus. Posting Group", SalesLine[1]."Gen. Prod. Posting Group");

        PostedInvoiceNo[1] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        LibrarySales.ReopenSalesDocument(SalesHeader);

        CreateSalesLine(SalesLine[2], SalesHeader);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine[2]."Line No.");
        ExpectedComment[2] := SalesCommentLine.Comment;

        PostedInvoiceNo[2] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        PostedCreditMemoNo := LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader);

        VerifyPostedSalesInvoiceCommentLine(PostedInvoiceNo[1], ExpectedComment[1], 1 + 1, 0);
        VerifyPostedSalesInvoiceCommentLine(PostedInvoiceNo[2], ExpectedComment[2], 1 + 1, 0);
        VerifyPostedSalesCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[1], 10000, 1 + ArrayLen(SalesLine), 0);
        VerifyPostedSalesCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[2], 20000, 1 + ArrayLen(SalesLine), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderConsequentCompressedPrepaymentPostingWithCommentLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCommentLine: Record "Purch. Comment Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        ExpectedComment: array[2] of Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 342788] System copies purchase order's comments to posted prepayment invoices and credit memos when setup is enabled.
        Initialize();
        LibraryPurchase.SetCopyCommentsOrderToInvoiceInSetup(true);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreateFullPrepaymentPurchHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", true);
        LibraryPurchase.CreatePurchCommentLine(PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", 0);

        CreatePurchLine(PurchaseLine[1], PurchaseHeader);
        LibraryPurchase.CreatePurchCommentLine(
          PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine[1]."Line No.");
        ExpectedComment[1] := PurchCommentLine.Comment;

        UpdatePurchasePrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          PurchaseLine[1]."Gen. Bus. Posting Group", PurchaseLine[1]."Gen. Prod. Posting Group");

        PostedInvoiceNo[1] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        CreatePurchLine(PurchaseLine[2], PurchaseHeader);
        LibraryPurchase.CreatePurchCommentLine(
          PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine[2]."Line No.");
        ExpectedComment[2] := PurchCommentLine.Comment;

        PostedInvoiceNo[2] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PostedCreditMemoNo := LibraryPurchase.PostPurchasePrepaymentCreditMemo(PurchaseHeader);

        VerifyPostedPurchaseInvoiceCommentLine(PostedInvoiceNo[1], ExpectedComment[1], 1 + 1, 0);
        VerifyPostedPurchaseInvoiceCommentLine(PostedInvoiceNo[2], ExpectedComment[2], 1 + 1, 0);
        VerifyPostedPurchaseCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[1], 10000, ArrayLen(PurchaseLine) + 1, 0);
        VerifyPostedPurchaseCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[2], 20000, ArrayLen(PurchaseLine) + 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderConsequentCompressedPrepaymentPostingWithCommentLines_SetupDisabled()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCommentLine: Record "Sales Comment Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        ExpectedComment: array[2] of Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 342788] System does not copy sales order's comments to posted prepayment invoices and credit memos when setup is disabled.
        Initialize();
        LibrarySales.SetCopyCommentsOrderToInvoiceInSetup(false);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreateFullPrepaymentSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", true);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", 0);

        CreateSalesLine(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine[1]."Line No.");
        ExpectedComment[1] := SalesCommentLine.Comment;

        UpdateSalesPrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          SalesLine[1]."Gen. Bus. Posting Group", SalesLine[1]."Gen. Prod. Posting Group");

        PostedInvoiceNo[1] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        LibrarySales.ReopenSalesDocument(SalesHeader);

        CreateSalesLine(SalesLine[2], SalesHeader);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine[2]."Line No.");
        ExpectedComment[2] := SalesCommentLine.Comment;

        PostedInvoiceNo[2] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        PostedCreditMemoNo := LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader);

        VerifyPostedSalesInvoiceCommentLine(PostedInvoiceNo[1], ExpectedComment[1], 0, 0);
        VerifyPostedSalesInvoiceCommentLine(PostedInvoiceNo[2], ExpectedComment[2], 0, 0);
        VerifyPostedSalesCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[1], 10000, 0, 0);
        VerifyPostedSalesCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[2], 30000, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderConsequentCompressedPrepaymentPostingWithCommentLines_SetupDisabled()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCommentLine: Record "Purch. Comment Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        ExpectedComment: array[2] of Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 342788] System does not copy purchase order's comments to posted prepayment invoices and credit memos when setup is disabled.
        Initialize();
        LibraryPurchase.SetCopyCommentsOrderToInvoiceInSetup(false);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreateFullPrepaymentPurchHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", true);
        LibraryPurchase.CreatePurchCommentLine(PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", 0);

        CreatePurchLine(PurchaseLine[1], PurchaseHeader);
        LibraryPurchase.CreatePurchCommentLine(
          PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine[1]."Line No.");
        ExpectedComment[1] := PurchCommentLine.Comment;

        UpdatePurchasePrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          PurchaseLine[1]."Gen. Bus. Posting Group", PurchaseLine[1]."Gen. Prod. Posting Group");

        PostedInvoiceNo[1] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        CreatePurchLine(PurchaseLine[2], PurchaseHeader);
        LibraryPurchase.CreatePurchCommentLine(
          PurchCommentLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine[2]."Line No.");
        ExpectedComment[2] := PurchCommentLine.Comment;

        PostedInvoiceNo[2] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PostedCreditMemoNo := LibraryPurchase.PostPurchasePrepaymentCreditMemo(PurchaseHeader);

        VerifyPostedPurchaseInvoiceCommentLine(PostedInvoiceNo[1], ExpectedComment[1], 0, 0);
        VerifyPostedPurchaseInvoiceCommentLine(PostedInvoiceNo[2], ExpectedComment[2], 0, 0);
        VerifyPostedPurchaseCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[1], 10000, 0, 0);
        VerifyPostedPurchaseCreditMemoCommentLine(PostedCreditMemoNo, ExpectedComment[2], 30000, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAfterPostSalesPrepmtInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 288239] User enters invoice discount which is greater than amount left to post after prepayment invoice was posted
        Initialize();

        // [GIVEN] Order with posted prepayment invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(60, 90));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Modify(true);
        UpdateSalesPrepmtAccount(CreateGLAccount(SalesLine."VAT Prod. Posting Group"), SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Enter invoice discount amount greater than amount will be posted including prepayment invoice amount
        asserterror SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesLine.Amount / 100 * SalesHeader."Prepayment %", SalesHeader);

        // [THEN] Error message thrown
        Assert.ExpectedError(StrSubstNo(SalesInvDiscForPrepmtExceededErr, SalesLine."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAfterPostPurchasePrepmtInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 288239] User enters invoice discount which is greater than amount left to post after prepayment invoice was posted
        Initialize();

        // [GIVEN] Order with posted prepayment invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(60, 90));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(50, 100));
        PurchaseLine.Modify(true);
        UpdatePurchasePrepmtAccount(CreateGLAccount(PurchaseLine."VAT Prod. Posting Group"), PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Enter invoice discount amount greater than amount will be posted including prepayment invoice amount
        asserterror PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(PurchaseLine.Amount / 100 * PurchaseHeader."Prepayment %", PurchaseHeader);

        // [THEN] Error message thrown
        Assert.ExpectedError(StrSubstNo(PurchaseInvDiscForPrepmtExceededErr, PurchaseLine."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscCalcInvDiscAfterPostSalesPrepmtInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 288239] User calculates invoice discount which is greater than amount left to post after prepayment invoice was posted
        Initialize();

        // [GIVEN] Order with posted prepayment invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(60, 90));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Modify(true);
        UpdateSalesPrepmtAccount(CreateGLAccount(SalesLine."VAT Prod. Posting Group"), SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Invoice discount for customer
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, SalesHeader."Sell-to Customer No.", '', 0);
        CustInvoiceDisc.Validate("Discount %", SalesHeader."Prepayment %");
        CustInvoiceDisc.Modify(true);

        // [WHEN] Calculate invoice discount
        asserterror Codeunit.Run(Codeunit::"Sales-Calc. Discount", SalesLine);

        // [THEN] Error message thrown
        Assert.ExpectedError(StrSubstNo(SalesInvDiscForPrepmtExceededErr, SalesLine."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscCalcInvDiscAfterPostPurchasePrepmtInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 288239] User calculates invoice discount which is greater than amount left to post after prepayment invoice was posted
        Initialize();

        // [GIVEN] Order with posted prepayment invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(60, 90));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(50, 100));
        PurchaseLine.Modify(true);
        UpdatePurchasePrepmtAccount(CreateGLAccount(PurchaseLine."VAT Prod. Posting Group"), PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Invoice discount for vendor
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, PurchaseHeader."Buy-from Vendor No.", '', 0);
        VendorInvoiceDisc.Validate("Discount %", PurchaseHeader."Prepayment %");
        VendorInvoiceDisc.Modify(true);

        // [WHEN] Calculate invoice discount
        asserterror Codeunit.Run(Codeunit::"Purch.-Calc.Discount", PurchaseLine);

        // [THEN] Error message thrown
        Assert.ExpectedError(StrSubstNo(PurchaseInvDiscForPrepmtExceededErr, PurchaseLine."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVATOnPurchLinesWithPrepaymentAndSetForPartialInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "Vat Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchPost: Codeunit "Purch.-Post";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 351878] UpdateVATOnLines function for purchase lines with prepayment and partial invoice calculates "Prepmt. Line Amount" equal to "Line Amount".
        Initialize();

        // [GIVEN] Purchase order with 100% prepayment.
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseHeader(
          PurchaseHeader,
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"),
          100, false);
        Item.Get(
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandIntInRange(11, 20), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Post prepayment invoice.
        // [GIVEN] Post the receipt.
        UpdatePurchasePrepmtAccount(
            CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Set the purchase line for partial invoice.
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Invoice", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);

        // [GIVEN] Fill a temporary table with purchase lines.
        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, 1);
        TempPurchaseLine.CalcVATAmountLines(0, PurchaseHeader, TempPurchaseLine, VATAmountLine);

        // [WHEN] Invoke "UpdateVATOnLines" function for the temporary purchase line.
        TempPurchaseLine.UpdateVATOnLines(0, PurchaseHeader, TempPurchaseLine, VATAmountLine);

        // [THEN] Prempt. Line Amount on the temporary purchase line is equal to Line Amount.
        TempPurchaseLine.SetRange("Prepayment Line", false);
        TempPurchaseLine.FindFirst();
        TempPurchaseLine.TestField("Prepmt. Line Amount", TempPurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVATOnSalesLinesWithPrepaymentAndSetForPartialInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesPost: Codeunit "Sales-Post";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 351878] UpdateVATOnLines function for sales lines with prepayment and partial invoice calculates "Prepmt. Line Amount" equal to "Line Amount".
        Initialize();

        // [GIVEN] Sales order with 100% prepayment.
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesHeader(
          SalesHeader,
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"),
          100, false);
        Item.Get(
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
        CreateCustomItemSalesLine(SalesLine, SalesHeader, Item."No.", LibraryRandom.RandIntInRange(11, 20), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Post prepayment invoice.
        // [GIVEN] Post the shipment.
        UpdateSalesPrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set the sales line for partial invoice.
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);

        // [GIVEN] Fill a temporary table with sales lines.
        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, 1);
        TempSalesLine.CalcVATAmountLines(0, SalesHeader, TempSalesLine, VATAmountLine);

        // [WHEN] Invoke "UpdateVATOnLines" function for the temporary sales line.
        TempSalesLine.UpdateVATOnLines(0, SalesHeader, TempSalesLine, VATAmountLine);

        // [THEN] Prempt. Line Amount on the temporary sales line is equal to Line Amount.
        TempSalesLine.SetRange("Prepayment Line", false);
        TempSalesLine.FindFirst();
        TempSalesLine.TestField("Prepmt. Line Amount", TempSalesLine."Line Amount");
    end;

    [Test]
    procedure PostSalesOrderWithPrepayment100PctAndInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        ItemNo: array[2] of Code[20];
        CustomerNo: Code[20];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 350540] Post Sales Order in case Prepayment % = 100 and positive Invoice Discount Amount.
        Initialize();

        // [GIVEN] VAT Posting Setup with VAT Rate = 7.7. Sales Order with Prepayment % = 100, "Prices Including VAT" = FALSE.
        // [GIVEN] Sales Line with Item, Quantity = 1, "Unit Price" = 563.85; Invoice Discount Amount = 245.01.
        // [GIVEN] Posted Prepayment Invoice.
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, 7.7);
        CreateSalesHeader(SalesHeader, CustomerNo, 100, true);
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify(true);

        CreateCustomItemSalesLine(SalesLine, SalesHeader, ItemNo[1], 1, 563.85);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(245.01, SalesHeader);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post Sales Order.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Order with two lines and Amount = 0 was posted. 
        // [THEN] First line with Item, "Line Amount" = 563.85, Amount = 563.85 - 245.01 = 318.84.
        // [THEN] Second line with G/L Account, Amount = -(563.85 - 245.01) = -318.84.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyPostedSalesInvoiceWithPrepmt(
            PostedDocNo, SalesLine.Type::Item, ItemNo[1], GeneralPostingSetup."Sales Prepayments Account",
            SalesLine."Line Amount", SalesLine."Inv. Discount Amount");
    end;

    [Test]
    procedure PostPurchaseOrderWithPrepayment100PctAndInvoiceDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        ItemNo: array[2] of Code[20];
        VendorNo: Code[20];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 350540] Post Purchase Order in case Prepayment % = 100 and positive Invoice Discount Amount.
        Initialize();

        // [GIVEN] VAT Posting Setup with VAT Rate = 7.7. Purchase Order with Prepayment % = 100, "Prices Including VAT" = FALSE.
        // [GIVEN] Purchase Line with Item, Quantity = 1, "Unit Price" = 563.85; Invoice Discount Amount = 245.01.
        // [GIVEN] Posted Prepayment Invoice.
        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, 7.7);
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 100, true);
        PurchaseHeader.Validate("Prices Including VAT", false);
        PurchaseHeader.Modify(true);

        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[1], 1, 563.85);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(245.01, PurchaseHeader);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post Purchase Order.
        PostedDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Purchase Order with two lines and Amount = 0 was posted. 
        // [THEN] First line with Item, "Line Amount" = 563.85, Amount = 563.85 - 245.01 = 318.84.
        // [THEN] Second line with G/L Account, Amount = -(563.85 - 245.01) = -318.84.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyPostedPurchaseInvoiceWithPrepmt(
            PostedDocNo, PurchaseLine.Type::Item, ItemNo[1], GeneralPostingSetup."Purch. Prepayments Account",
            PurchaseLine."Line Amount", PurchaseLine."Inv. Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPartialPostWithPrepayment100PctAndInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        PostedDocNo1: Code[20];
        PostedDocNo2: Code[20];
        Quantity: Integer;
        UnitPrice: Decimal;
        UnitInvDiscAmt: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 361949] Post Sales Order partially with Prepayment % = 100 and Invoice Discount Amount.
        Initialize();

        // [GIVEN] VAT Posting Setup with VAT Rate = 10. Sales Order with Prepayment % = 100.
        // [GIVEN] Sales Line with Item, Quantity = 3, "Unit Price" = 1000; Invoice Discount Amount = 300.
        // [GIVEN] Posted Prepayment Invoice.
        Quantity := LibraryRandom.RandIntInRange(3, 5);
        UnitPrice := LibraryRandom.RandDecInRange(1000, 2000, 2);
        UnitInvDiscAmt := LibraryRandom.RandDecInRange(100, 200, 2);

        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesHeader(
          SalesHeader,
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"),
          100, false);
        Item.Get(
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
        CreateCustomItemSalesLine(SalesLine, SalesHeader, Item."No.", Quantity, UnitPrice);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Quantity * UnitInvDiscAmt, SalesHeader);

        // [GIVEN] Prepayment invoice is posted with Amount = 2700 (3000 - 300)
        UpdateSalesPrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Post sales invoice partially with "Qty. to Ship" = 1 as "Inv1"
        // [GIVEN] "Inv. Disc. Amount to Invoice" = 100, "Prepmt Amt to Deduct" = 900
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify(true);
        SalesLine.TestField("Inv. Disc. Amount to Invoice", UnitInvDiscAmt);
        SalesLine.TestField("Prepmt Amt to Deduct", UnitPrice - UnitInvDiscAmt);
        PostedDocNo1 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Post final sales invoice as "Inv2"
        PostedDocNo2 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Sales Invoices have Amount = 0, Amount Including VAT = 0, Remaining Amount = 0
        // [THEN] Deducted prepayment amount = -900 in "Inv1"
        // [THEN] Deducted prepayment amount = -1800 in "Inv2"
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyPostedSalesInvoiceWithPrepmt(
          PostedDocNo1, SalesLine.Type::Item, Item."No.", GeneralPostingSetup."Sales Prepayments Account",
          UnitPrice, UnitInvDiscAmt);
        VerifyGLEntriesAmount(
          UnitPrice - UnitInvDiscAmt, PostedDocNo1, GeneralPostingSetup."Sales Prepayments Account");
        VerifyPostedSalesInvoiceWithPrepmt(
          PostedDocNo2, SalesLine.Type::Item, Item."No.", GeneralPostingSetup."Sales Prepayments Account",
          UnitPrice * (Quantity - 1), UnitInvDiscAmt * (Quantity - 1));
        VerifyGLEntriesAmount(
          (UnitPrice - UnitInvDiscAmt) * (Quantity - 1), PostedDocNo2, GeneralPostingSetup."Sales Prepayments Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialPostWithPrepayment100PctAndInvoiceDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PostedDocNo1: Code[20];
        PostedDocNo2: Code[20];
        Quantity: Integer;
        UnitCost: Decimal;
        UnitInvDiscAmt: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 361949] Post Purchase Order partially with Prepayment % = 100 and Invoice Discount Amount.
        Initialize();

        // [GIVEN] VAT Posting Setup with VAT Rate = 10. Purchase Order with Prepayment % = 100.
        // [GIVEN] Purchase Line with Item, Quantity = 3, "Unit Price" = 1000; Invoice Discount Amount = 300.
        // [GIVEN] Posted Prepayment Invoice.
        Quantity := LibraryRandom.RandIntInRange(3, 5);
        UnitCost := LibraryRandom.RandDecInRange(1000, 2000, 2);
        UnitInvDiscAmt := LibraryRandom.RandDecInRange(100, 200, 2);

        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseHeader(
          PurchaseHeader,
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"),
          100, false);
        Item.Get(
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", Quantity, UnitCost);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(Quantity * UnitInvDiscAmt, PurchaseHeader);

        // [GIVEN] Prepayment invoice is posted with Amount = 2700 (3000 - 300)
        UpdatePurchasePrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Post purchase invoice partially with "Qty. to Receive" = 1 as "Inv1"
        // [GIVEN] "Inv. Disc. Amount to Invoice" = 100, "Prepmt Amt to Deduct" = 900
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", 1);
        PurchaseLine.Modify(true);
        PurchaseLine.TestField("Inv. Disc. Amount to Invoice", UnitInvDiscAmt);
        PurchaseLine.TestField("Prepmt Amt to Deduct", UnitCost - UnitInvDiscAmt);
        PostedDocNo1 := PostPurchaseDocument(PurchaseHeader);

        // [WHEN] Post final purchase invoice as "Inv2"
        PostedDocNo2 := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Posted Purchase Invoices have Amount = 0, Amount Including VAT = 0, Remaining Amount = 0
        // [THEN] Deducted prepayment amount = -900 in "Inv1"
        // [THEN] Deducted prepayment amount = -1800 in "Inv2"
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyPostedPurchaseInvoiceWithPrepmt(
          PostedDocNo1, PurchaseLine.Type::Item, Item."No.", GeneralPostingSetup."Purch. Prepayments Account",
          UnitCost, UnitInvDiscAmt);
        VerifyGLEntriesAmount(
          -(UnitCost - UnitInvDiscAmt), PostedDocNo1, GeneralPostingSetup."Purch. Prepayments Account");
        VerifyPostedPurchaseInvoiceWithPrepmt(
          PostedDocNo2, PurchaseLine.Type::Item, Item."No.", GeneralPostingSetup."Purch. Prepayments Account",
          UnitCost * (Quantity - 1), UnitInvDiscAmt * (Quantity - 1));
        VerifyGLEntriesAmount(
          -(UnitCost - UnitInvDiscAmt) * (Quantity - 1), PostedDocNo2, GeneralPostingSetup."Purch. Prepayments Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangeVATProdPostGroupAfterPostingSalesPrepmtInv()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364426] Stan cannot change the "VAT Product Posting Group" in Sales Order with posted prepayment

        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] Sales Order with "VAT Product Posting Group" = "X"
        CreatePrepmtSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Posted prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] New VAT Product Posting Group "Y"
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Find();

        // [WHEN] Change "VAT Product Posting Group" of sales line to "Y"
        asserterror SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [THEN] An error message "You cannot change the VAT product posting group because prepayment invoices have been posted" shown
        Assert.ExpectedError(CannotChangeVATGroupWithPrepmInvErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangeSalesPrepmtAmountIfPrepmtAmountHasDiffVATGroup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364364] Stan cannot change the prepayment amount if prepayment G/L Account has different VAT Product posting group

        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] Sales Order with sales prepayment account that has "VAT Product Posting Group" with VAT rate = "X"
        CreatePrepmtSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Posted prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] New VAT Product Posting Group with VAT rate "Y"
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);

        // [GIVEN] Change the "VAT Product Posting Group" of G/L account to one with VAT rate "Y"
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Find();
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
        GLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GLAccount.Modify(true);

        // [WHEN] Change prepayment amount in sales line
        asserterror SalesLine.Validate("Prepayment %", SalesLine."Prepayment %" + 1);

        // [THEN] An error message "You cannot change the prepayment amount because the prepayment invoice has been posted with a different VAT percentage" shown
        Assert.ExpectedError(CannotChangePrepmtAmtDiffVAtPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangeVATProdPostGroupAfterPostingPurchPrepmtInv()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 364426] Stan cannot change the "VAT Product Posting Group" in Purchase Order with posted prepayment

        Initialize();
        // [GIVEN] Purchase Order with "VAT Product Posting Group" = "X"
        CreatePrepmtPurchOrder(PurchaseHeader);

        // [GIVEN] Posted prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] New VAT Product Posting Group "Y"
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Change "VAT Product Posting Group" of purchase line to "Y"
        asserterror PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [THEN] An error message "You cannot change the VAT product posting group because prepayment invoices have been posted" shown
        Assert.ExpectedError(CannotChangeVATGroupWithPrepmInvErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToChangePurchPrepmtAmountIfPrepmtAmountHasDiffVATGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 364364] Stan cannot change the prepayment amount if prepayment G/L Account has different VAT Product posting group

        Initialize();
        // [GIVEN] Purchase Order with purchase prepayment account that has "VAT Product Posting Group" with VAT rate = "X"
        CreatePrepmtPurchOrder(PurchaseHeader);

        // [GIVEN] Posted prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] New VAT Product Posting Group with VAT rate "Y"
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);

        // [GIVEN] Change the "VAT Product Posting Group" of G/L account to one with VAT rate "Y"
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
        GLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GLAccount.Modify(true);

        // [WHEN] Change prepayment amount in purchase line
        asserterror PurchaseLine.Validate("Prepayment %", PurchaseLine."Prepayment %" + 1);

        // [THEN] An error message "You cannot change the prepayment amount because the prepayment invoice has been posted with a different VAT percentage" shown
        Assert.ExpectedError(CannotChangePrepmtAmtDiffVAtPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceAfterGetReceiptLinesWithPrepmtAndAdjustedQtyToInvoiceOnOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
        PurchReceiptNo: Code[20];
        PurchInvoiceNo: Code[20];
        PrepmtPerc: Decimal;
        Qty: Decimal;
        QtyToReceive: Decimal;
        UnitCost: Decimal;
        ExpectedPrepmtPerLine: Decimal;
    begin
        // [FEATURE] [Purchase] [Receipt] [Invoice] [Get Receipt Lines]
        // [SCENARIO 372022] Prepayment amount is deducted correctly on posting invoice created via "Get Receipt Lines" when "Qty. to Invoice" = 0 on the purchase order.
        Initialize();
        PrepmtPerc := LibraryRandom.RandIntInRange(10, 90);
        Qty := LibraryRandom.RandIntInRange(11, 20);
        QtyToReceive := Qty / 2;
        UnitCost := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Two items.
        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, LibraryRandom.RandInt(20));

        // [GIVEN] Purchase order with 25% prepayment.
        // [GIVEN] Two purchase lines, one per item. Quantity = 10, "Qty. to Receive" = 5, "Direct Unit Cost" = 200.
        CreatePurchaseHeader(PurchaseHeader, VendorNo, PrepmtPerc, false);
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[1], Qty, UnitCost);
        UpdatePurchQtyToReceive(PurchaseLine, QtyToReceive);
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[2], Qty, UnitCost);
        UpdatePurchQtyToReceive(PurchaseLine, QtyToReceive);

        // [GIVEN] Post the prepayment invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Post the receipt.
        PurchReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Set "Qty. to Invoice" on both lines to 0.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[1]);
        UpdatePurchQtyToInvoice(PurchaseLine, 0);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[2]);
        UpdatePurchQtyToInvoice(PurchaseLine, 0);

        // [WHEN] Create purchase invoice using "Get Receipt Lines".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchRcptLine.SetRange("Document No.", PurchReceiptNo);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        ExpectedPrepmtPerLine := Qty * UnitCost * (PrepmtPerc / 100) * (QtyToReceive / Qty);

        // [THEN] "Prepmt. Amount to Deduct" on each invoice line = 250.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[1]);
        PurchaseLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtPerLine);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[2]);
        PurchaseLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtPerLine);

        // [THEN] The purchase invoice can be posted.
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The amount deducted from the prepayment account = -500 (2 * 250).
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(-ExpectedPrepmtPerLine * 2, PurchInvoiceNo, GeneralPostingSetup."Purch. Prepayments Account");

        // Tear down.
        TearDownVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceAfterGetShipmentLinesWithPrepmtAndAdjustedQtyToInvoiceOnOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        SalesShipmentNo: Code[20];
        SalesInvoiceNo: Code[20];
        PrepmtPerc: Decimal;
        Qty: Decimal;
        QtyToShip: Decimal;
        UnitPrice: Decimal;
        ExpectedPrepmtPerLine: Decimal;
    begin
        // [FEATURE] [Sales] [Shipment] [Invoice] [Get Shipment Lines]
        // [SCENARIO 372022] Prepayment amount is deducted correctly on posting invoice created via "Get Shipment Lines" when "Qty. to Invoice" = 0 on the sales order.
        Initialize();
        PrepmtPerc := LibraryRandom.RandIntInRange(10, 90);
        Qty := LibraryRandom.RandIntInRange(11, 20);
        QtyToShip := Qty / 2;
        UnitPrice := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Two items.
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, LibraryRandom.RandInt(20));

        // [GIVEN] Sales order with 25% prepayment.
        // [GIVEN] Two sales lines, one per item. Quantity = 10, "Qty. to Ship" = 5, "Unit Price" = 200.
        CreateSalesHeader(SalesHeader, CustomerNo, PrepmtPerc, false);
        CreateCustomItemSalesLine(SalesLine, SalesHeader, ItemNo[1], Qty, UnitPrice);
        UpdateSalesQtyToShip(SalesLine, QtyToShip);
        CreateCustomItemSalesLine(SalesLine, SalesHeader, ItemNo[2], Qty, UnitPrice);
        UpdateSalesQtyToShip(SalesLine, QtyToShip);

        // [GIVEN] Post the prepayment invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Post the shipment.
        SalesShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set "Qty. to Invoice" on both lines to 0.
        FindSalesLine(SalesLine, SalesHeader, ItemNo[1]);
        UpdateSalesQtyToInvoice(SalesLine, 0);
        FindSalesLine(SalesLine, SalesHeader, ItemNo[2]);
        UpdateSalesQtyToInvoice(SalesLine, 0);

        // [WHEN] Create sales invoice using "Get Shipment Lines".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentNo);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);

        ExpectedPrepmtPerLine := Qty * UnitPrice * (PrepmtPerc / 100) * (QtyToShip / Qty);

        // [THEN] "Prepmt. Amount to Deduct" on each invoice line = 250.
        FindSalesLine(SalesLine, SalesHeader, ItemNo[1]);
        SalesLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtPerLine);
        FindSalesLine(SalesLine, SalesHeader, ItemNo[2]);
        SalesLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtPerLine);

        // [THEN] The sales invoice can be posted.
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The amount deducted from the prepayment account = 500 (2 * 250).
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(ExpectedPrepmtPerLine * 2, SalesInvoiceNo, GeneralPostingSetup."Sales Prepayments Account");

        // Tear down.
        TearDownVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepaymentLineAmountIsRecalculatedIsSalesOrderWhenPriceIncludingVATIsActivated()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepLineAmountExclVAT: Decimal;
        PrepLineAmountIclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Prices Including VAT]
        // [SCENARIO 390381] Prepayment amount is recalculated after enabling "Prices Including VAT" in Sales Header
        Initialize();

        // [GIVEN] Created Sales Order with "Prepayment %"
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesHeader.Modify(true);

        // [GIVEN] Calculated "Prepmt. Line Amount" and awaiting "Prepmt. Line Amount" including VAT
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        PrepLineAmountExclVAT := SalesLine."Prepmt. Line Amount";
        PrepLineAmountIclVAT := Round(
            SalesLine."Amount Including VAT" * SalesLine."Prepayment %" / 100, LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Unable "Prices Including VAT" in Sales Header
        SalesHeader.Validate("Prices Including VAT", true);

        // [THEN] SalesLine."Prepmt. Line Amount" is recalculated
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        Assert.AreNotEqual(SalesLine."Prepmt. Line Amount", PrepLineAmountExclVAT, '');
        SalesLine.TestField("Prepmt. Line Amount", PrepLineAmountIclVAT);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepaymentLineAmountIsRecalculatedInPurchaseOrderWhenPriceIncludingVATIsActivated()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrepLineAmountExclVAT: Decimal;
        PrepLineAmountIclVAT: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Prices Including VAT]
        // [SCENARIO 390381] Prepayment amount is recalculated after enabling "Prices Including VAT" in Purchasase Header
        Initialize();

        // [GIVEN] Created Purchase Order with "Prepayment %"
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        PurchaseHeader.Modify(true);

        // [GIVEN] Calculated "Prepmt. Line Amount" and awaiting "Prepmt. Line Amount" including VAT
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PrepLineAmountExclVAT := PurchaseLine."Prepmt. Line Amount";
        PrepLineAmountIclVAT := Round(
            PurchaseLine."Amount Including VAT" * PurchaseLine."Prepayment %" / 100, LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Unable "Prices Including VAT" in Purchase Header
        PurchaseHeader.Validate("Prices Including VAT", true);

        // [THEN] Purchase."Prepmt. Line Amount" is recalculated
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        Assert.AreNotEqual(PurchaseLine."Prepmt. Line Amount", PrepLineAmountExclVAT, '');
        PurchaseLine.TestField("Prepmt. Line Amount", PrepLineAmountIclVAT);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure ErrorGLAccountMustHaveAValueIsShownForPurchasePrepaymentInvoiceWithMissingGenBusPostingGroupInGLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        ErrorMessages: TestPage "Error Messages";
        PurchPostYNPrepmt: Codeunit "Purch.-Post Prepmt. (Yes/No)";
    begin
        // [Posting Groups] [Purchase]
        // [SCENARIO 391612] Create Purchase Order with Prepayment and empty "Gen. Prod. Posting Group" for "Purch. Prepayments Account"
        Initialize();

        // [GIVEN] Created G/L Account with missing "Gen. Prod. Posting Group"
        // [GIVEN] Created new General Posting Setup and use created G/L Account for "Purch. Prepayments Account"
        PrepareSetup_391612(GeneralPostingSetup, GLAccount);
        GeneralPostingSetup."Purch. Prepayments Account" := GLAccount."No.";
        GeneralPostingSetup.Modify();

        // [GIVEN] Created Purchase Order with Prepayment
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        PurchaseLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        PurchaseLine.Modify(true);

        // [WHEN] Post Prepayment Invoice
        ErrorMessages.Trap();
        PurchPostYNPrepmt.PostPrepmtInvoiceYN(PurchaseHeader, false);

        // [THEN] Error has been thrown: "Gen. Prod. Posting Group  is not set for the Prepayment G/L account with no. XXXXX."
        VerifyErrorMessage(
            ErrorMessages,
            StrSubstNo(GenProdPostingGroupErr, GLAccount.FieldCaption("Gen. Prod. Posting Group"), GLAccount.Name, GLAccount."No."),
            PurchaseHeader.RecordId,
            '',
            GLAccount.RecordId,
            GLAccount.FieldCaption("Gen. Prod. Posting Group"),
            'https://go.microsoft.com/fwlink/?linkid=2157418');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure ErrorGLAccountMustHaveAValueIsShownForSalesPrepaymentInvoiceWithMissingGenBusPostingGroupInGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        ErrorMessages: TestPage "Error Messages";
        SalesPostPrepaymentYesNo: Codeunit "Sales-Post Prepayment (Yes/No)";
    begin
        // [Posting Groups] [Sales]
        // [SCENARIO 391612] Create Sales Order with Prepayment and empty "Gen. Prod. Posting Group" for "Purch. Prepayments Account"
        Initialize();

        // [GIVEN] Created G/L Account with missing "Gen. Prod. Posting Group"
        // [GIVEN] Created new General Posting Setup and use created G/L Account for "Sales Prepayments Account"
        PrepareSetup_391612(GeneralPostingSetup, GLAccount);
        GeneralPostingSetup."Sales Prepayments Account" := GLAccount."No.";
        GeneralPostingSetup.Modify();

        // [GIVEN] Created Sales Order with Prepayment
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        SalesLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        SalesLine.Modify(true);

        // [WHEN] Post Prepayment Invoice
        ErrorMessages.Trap();
        SalesPostPrepaymentYesNo.PostPrepmtInvoiceYN(SalesHeader, false);

        // [THEN] Error has been thrown: "Gen. Prod. Posting Group  is not set for the Prepayment G/L account with no. XXXXX."
        VerifyErrorMessage(
            ErrorMessages,
            StrSubstNo(GenProdPostingGroupErr, GLAccount.FieldCaption("Gen. Prod. Posting Group"), GLAccount.Name, GLAccount."No."),
            SalesHeader.RecordId,
            '',
            GLAccount.RecordId,
            GLAccount.FieldCaption("Gen. Prod. Posting Group"),
            'https://go.microsoft.com/fwlink/?linkid=2157418');
    end;

    [Test]
    procedure ErrorOnGetShptLinesFromOrderWithUnpaidPrepmt()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Get Shipment Lines]
        // [SCENARIO 400503] An error occurs trying to Get Shipment Lines from an order with unpaid prepayment
        Initialize();

        // [GIVEN] Sales order with 50% prepayment
        CreateSalesOrderWithOneLine(SalesHeader);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 40, 2));
        SalesHeader.Modify(true);
        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Ship the order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        // [GIVEN] Reopen the order and change prepayment to 75%
        SalesHeader.Find();
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Validate("Prepayment %", SalesHeader."Prepayment %" + LibraryRandom.RandDecInRange(10, 40, 2));
        SalesHeader.Modify(true);

        // [GIVEN] Create a new sales invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");

        // [WHEN] Invoke Get Shipment Lines and use posted shipment
        asserterror GetSalesShipmentLines(SalesHeader);

        // [THEN] An error occurs: "You cannot get lines until you have posted all related prepayment invoices to mark the prepayment as paid."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(PrepaymentInvoicesNotPaidErr);
    end;

    [Test]
    procedure ErrorOnGetRcptLinesFromOrderWithUnpaidPrepmt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines]
        // [SCENARIO 400503] An error occurs trying to Get Receipt Lines from an order with unpaid prepayment
        Initialize();

        // [GIVEN] Purchase order with 50% prepayment
        CreatePurchaseOrderWithOneLine(PurchaseHeader);
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 40, 2));
        PurchaseHeader.Modify(true);
        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Receipt the order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [GIVEN] Reopen the order and change prepayment to 75%
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Prepayment %", PurchaseHeader."Prepayment %" + LibraryRandom.RandDecInRange(10, 40, 2));
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a new purchase invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Invoke Get Receipt Lines and use posted shipment
        asserterror GetPurchaseReceiptLines(PurchaseHeader);

        // [THEN] An error occurs: "You cannot get lines until you have posted all related prepayment invoices to mark the prepayment as paid."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(PrepaymentInvoicesNotPaidErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryAfterPostPrepaymentSalesWithUpdateAmount()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        DocumentType: Enum "Gen. Journal Document Type";
    begin
        // [SCENARIO 413667] Post prepayment invoice for modified sales order when previous prepayment has been canceled by prepament credit memo.

        Initialize();

        // [GIVE] Sales order with "Prepayment %" = 100, Amount = 4000 and "VAT % = 10
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        UpdatePrepmtAccInGeneralPostingSetup(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2) * 3);
        SalesLine.Modify(true);

        // [GIVEN] Prepayment Invoice posted and reverted by Prepayment Credit Memo
        PostedInvoiceNo[1] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        VerifyVATEntryBaseAndAmount(
            DocumentType::Invoice,
            PostedInvoiceNo[1],
            -Round(SalesLine.Quantity * SalesLine."Unit Price"),
            -Round(Round(SalesLine.Quantity * SalesLine."Unit Price") * SalesLine."VAT %" / 100));

        PostedCreditMemoNo := LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader);

        VerifyVATEntryBaseAndAmount(
            DocumentType::"Credit Memo",
            PostedCreditMemoNo,
            Round(SalesLine.Quantity * SalesLine."Unit Price"),
            Round(Round(SalesLine.Quantity * SalesLine."Unit Price") * SalesLine."VAT %" / 100));

        // [GIVEN] Order reopened when prepayment invoice is canceled.
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [GIVEN] "Unit Price" decreased from 4000 to 3000 on sales line.
        SalesLine.Find();
        SalesLine.Validate("Unit Price", ROUND(SalesLine."Unit Price" / 3));
        SalesLine.Modify(true);

        // [WHEN] Post new Prepayment Invoice 
        PostedInvoiceNo[2] := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Amount = -300, Base = -3000 on created VAT Entry
        VerifyVATEntryBaseAndAmount(
            DocumentType::Invoice,
            PostedInvoiceNo[2],
            -Round(SalesLine.Quantity * SalesLine."Unit Price"),
            -Round(Round(SalesLine.Quantity * SalesLine."Unit Price") * SalesLine."VAT %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryAfterPostPrepaymentPurchaseWithUpdateAmount()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: Code[20];
        DocumentType: Enum "Gen. Journal Document Type";
    begin
        // [SCENARIO 413667] Post prepayment invoice for modified sales order when previous prepayment has been canceled by prepament credit memo.

        Initialize();

        // [GIVE] Sales order with "Prepayment %" = 100, Amount = 4000 and "VAT % = 10
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        UpdatePrepmtAccInGeneralPostingSetup(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2) * 3);
        PurchaseLine.Modify(true);

        // [GIVEN] Prepayment Invoice posted and reverted by Prepayment Credit Memo
        PostedInvoiceNo[1] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        VerifyVATEntryBaseAndAmount(
            DocumentType::Invoice,
            PostedInvoiceNo[1],
            Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost"),
            Round(Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * PurchaseLine."VAT %" / 100));

        PurchaseHeader.Find();
        PurchaseHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();
        PostedCreditMemoNo := LibraryPurchase.PostPurchasePrepaymentCreditMemo(PurchaseHeader);

        VerifyVATEntryBaseAndAmount(
            DocumentType::"Credit Memo",
            PostedCreditMemoNo,
            -Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost"),
            -Round(Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * PurchaseLine."VAT %" / 100));

        // [GIVEN] Order reopened when prepayment invoice is canceled.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        UpdatePurchInvoiceNo(PurchaseHeader);

        // [GIVEN] "Unit Price" decreased from 4000 to 3000 on sales line.
        PurchaseLine.Find();
        PurchaseLine.Validate("Direct Unit Cost", ROUND(PurchaseLine."Direct Unit Cost" / 3));
        PurchaseLine.TestField("VAT %");
        PurchaseLine.Modify(true);

        // [WHEN] Post new Prepayment Invoice 
        PostedInvoiceNo[2] := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Amount = 300, Base = 3000 on created VAT Entry
        VerifyVATEntryBaseAndAmount(
            DocumentType::Invoice,
            PostedInvoiceNo[2],
            Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost"),
            Round(Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * PurchaseLine."VAT %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvLineVATPctWithDifferentVARates()
    var
        PrepmtVATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        Customer: Record Customer;
        PostedInvNo: Code[20];
    begin
        // [SCENARIO 413665] Wrong VAT % in prepayment invoice line, document statistics and report in the case of different VAT rates in the document line and prepayment account
        Initialize();

        // [GIVEN] Prepayment setup with VAT % = "VAT1"
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(PrepmtVATPostingSetup, 67.89);
        GeneralPostingSetup.Validate("Sales Prepayments Account", CreateGLAccountWithGivenSetup(PrepmtVATPostingSetup, GeneralPostingSetup));
        GeneralPostingSetup.Modify(true);

        // [GIVEN] Order, line with VAT % = "VAT2"
        VATPostingSetup.Get(PrepmtVATPostingSetup."VAT Bus. Posting Group", PrepmtVATPostingSetup."VAT Prod. Posting Group");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup."VAT %" := 23.45;
        VATPostingSetup.Insert();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        CreateSalesHeader(SalesHeader, Customer."No.", 50, false);
        CreateCustomSalesLine(SalesLine, SalesHeader, CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup), 1, 1000);

        // [WHEN] Post prepayment invoice
        PostedInvNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Posted prepayment invoice line "VAT %" = "VAT1"
        SalesInvoiceLine.Get(PostedInvNo, SalesLine."Line No.");
        SalesInvoiceLine.TestField("VAT %", PrepmtVATPostingSetup."VAT %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtInvLineVATPctWithDifferentVARates()
    var
        PrepmtVATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        Vendor: Record Vendor;
        PostedInvNo: Code[20];
    begin
        // [SCENARIO 413665] Wrong VAT % in prepayment invoice line, document statistics and report in the case of different VAT rates in the document line and prepayment account
        Initialize();

        // [GIVEN] Prepayment setup with VAT % = "VAT1"
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(PrepmtVATPostingSetup, 67.89);
        GeneralPostingSetup."Purch. Prepayments Account" := CreateGLAccountWithGivenSetup(PrepmtVATPostingSetup, GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);

        // [GIVEN] Order, line with VAT % = "VAT2"
        VATPostingSetup.Get(PrepmtVATPostingSetup."VAT Bus. Posting Group", PrepmtVATPostingSetup."VAT Prod. Posting Group");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup."VAT %" := 23.45;
        VATPostingSetup.Insert();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        CreatePurchaseHeader(PurchaseHeader, Vendor."No.", 50, false);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Modify(true);

        // [WHEN] Post prepayment invoice
        PostedInvNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Posted prepayment invoice line "VAT %" = "VAT1"
        PurchInvLine.Get(PostedInvNo, PurchaseLine."Line No.");
        PurchInvLine.TestField("VAT %", PrepmtVATPostingSetup."VAT %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPartialPrepaymentAndFinalInvoiceWithDifferentPrpmtGLAccountAndCompressPrpmt()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATPostingSetupGLAccount: Record "VAT Posting Setup";
        GLAccount: array[2] of Record "G/L Account";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Price including VAT] [Partial Prepayment] [Compress Prepayment]
        // [SCENARIO 426793] Rounding reminding amount is not added twice on certain condition.
        Initialize();

        CreateVATPostingSetup(VATPostingSetupGLAccount, 10);

        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);

        CreateTwoGLAccountsWithTwoPrepaymentGenPostingSetups(GLAccount, GenBusinessPostingGroup, VATPostingSetupGLAccount);

        CreateSalesOrder_426793(SalesHeader, true, true, 10, GLAccount, GenBusinessPostingGroup, VATPostingSetupGLAccount);

        PostedDocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        VerifyGLVATEntries(PostedDocumentNo);

        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyGLEntryDoesNotExist(PostedDocumentNo, GetInvRoundingAccFromCust(SalesHeader."Bill-to Customer No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPartialPrepaymentAndFinalInvoiceWithDifferentPrpmtGLAccountAndWithoutCompressPrpmt()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATPostingSetupGLAccount: Record "VAT Posting Setup";
        GLAccount: array[2] of Record "G/L Account";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Price including VAT] [Partial Prepayment]
        // [SCENARIO 426793] Rounding reminding amount is not added twice on certain condition.
        Initialize();

        CreateVATPostingSetup(VATPostingSetupGLAccount, 10);

        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);

        CreateTwoGLAccountsWithTwoPrepaymentGenPostingSetups(GLAccount, GenBusinessPostingGroup, VATPostingSetupGLAccount);

        CreateSalesOrder_426793(SalesHeader, false, true, 10, GLAccount, GenBusinessPostingGroup, VATPostingSetupGLAccount);

        PostedDocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        VerifyGLVATEntries(PostedDocumentNo);

        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyGLEntryDoesNotExist(PostedDocumentNo, GetInvRoundingAccFromCust(SalesHeader."Bill-to Customer No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePartialPrepaymentAndFinalInvoiceWithDifferentPrpmtGLAccountAndCompressPrpmt()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATPostingSetupGLAccount: Record "VAT Posting Setup";
        GLAccount: array[2] of Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Price including VAT] [Partial Prepayment] [Compress Prepayment]
        // [SCENARIO 426793] Rounding reminding amount is not added twice on certain condition.
        Initialize();

        CreateVATPostingSetup(VATPostingSetupGLAccount, 10);

        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);

        CreateTwoGLAccountsWithTwoPrepaymentGenPostingSetups(GLAccount, GenBusinessPostingGroup, VATPostingSetupGLAccount);

        CreatePurchaseOrder_426793(PurchaseHeader, GLAccount, GenBusinessPostingGroup, VATPostingSetupGLAccount);

        PostedDocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        VerifyGLVATEntries(PostedDocumentNo);

        PurchaseHeader.Find();
        UpdatePurchInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifyGLEntryDoesNotExist(PostedDocumentNo, GetInvRoundingAccFromVend(PurchaseHeader."Pay-to Vendor No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePartialPrepaymentAndFinalInvoiceWithDifferentPrpmtGLAccountAndWithoutCompressPrpmt()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATPostingSetupGLAccount: Record "VAT Posting Setup";
        GLAccount: array[2] of Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Price including VAT] [Partial Prepayment]
        // [SCENARIO 426793] Rounding reminding amount is not added twice on certain condition.
        Initialize();

        CreateVATPostingSetup(VATPostingSetupGLAccount, 10);

        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);

        CreateTwoGLAccountsWithTwoPrepaymentGenPostingSetups(GLAccount, GenBusinessPostingGroup, VATPostingSetupGLAccount);

        CreatePurchaseOrder_426793(PurchaseHeader, GLAccount, GenBusinessPostingGroup, VATPostingSetupGLAccount);

        PostedDocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        VerifyGLVATEntries(PostedDocumentNo);

        PurchaseHeader.Find();
        UpdatePurchInvoiceNo(PurchaseHeader);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifyGLEntryDoesNotExist(PostedDocumentNo, GetInvRoundingAccFromVend(PurchaseHeader."Pay-to Vendor No."));
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialConfirmationAfterPaymentAppliedToPrepaymentInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Customer: Record Customer;
        SalesHeaderOrder: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        DocumentPrint: Codeunit "Document-Print";
        ItemNo: Code[20];
        PrepaymentInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 427453] Stan can print "Order Confirmation" for prepaid and released Sales Order with modified "Qty. To Ship"
        Initialize();

        CreateVATPostingSetup(VATPostingSetup, 10);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        Customer.Get(
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Validate("Prepayment %", 100);
        Customer.Modify(true);

        ItemNo :=
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        UpdateSalesPrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Sales order "SO" with partial prepayment.
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLineOrder, SalesHeaderOrder, SalesLineOrder.Type::Item, ItemNo, LibraryRandom.RandIntInRange(2, 5) * 3);
        SalesLineOrder.Validate("Unit Price", LibraryRandom.RandIntInRange(20, 500));
        SalesLineOrder.Modify(true);

        // [GIVEN] Posted the prepayment invoice.
        PrepaymentInvoiceNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeaderOrder);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, SalesHeaderOrder."Sell-to Customer No.", -SalesLineOrder."Amount Including VAT");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PrepaymentInvoiceNo);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        SalesHeaderOrder.Find();
        LibrarySales.ReleaseSalesDocument(SalesHeaderOrder);

        SalesLineOrder.Find();
        SalesLineOrder.Validate("Qty. to Ship", SalesLineOrder."Qty. to Ship" / 3);
        SalesLineOrder.Modify(true);

        SalesHeaderOrder.Find();
        SalesHeaderOrder.SetRecFilter();

        LibraryERM.SetupReportSelection(ReportSelections.Usage::"S.Order", REPORT::"Standard Sales - Order Conf.");
        Commit();
        DocumentPrint.PrintSalesOrder(SalesHeaderOrder, 0); // 0 = Order Confirmation = ReportSelections.Usage::"S.Order"

        SalesHeaderOrder.Find();
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        TearDownVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('OrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPartialConfirmationAfterPaymentAppliedToPrepaymentInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ReportSelections: Record "Report Selections";
        DocumentPrint: Codeunit "Document-Print";
        ItemNo: Code[20];
        PrepaymentInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 427453] Stan can print "Order" for prepaid and released Purchase Order with modified "Qty. To Receive"
        Initialize();

        CreateVATPostingSetup(VATPostingSetup, 10);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        Vendor.Get(
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        Vendor.Validate("Prepayment %", 100);
        Vendor.Modify(true);

        ItemNo :=
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        UpdatePurchasePrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Sales order "SO" with partial prepayment.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, ItemNo, LibraryRandom.RandIntInRange(2, 5) * 3);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(20, 500));
        PurchaseLineOrder.Modify(true);

        // [GIVEN] Posted the prepayment invoice.
        PrepaymentInvoiceNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeaderOrder);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, PurchaseHeaderOrder."Buy-from Vendor No.", PurchaseLineOrder."Amount Including VAT");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PrepaymentInvoiceNo);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        PurchaseHeaderOrder.Find();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeaderOrder);

        PurchaseLineOrder.Find();
        PurchaseLineOrder.Validate("Qty. to Receive", PurchaseLineOrder."Qty. to Receive" / 3);
        PurchaseLineOrder.Modify(true);

        PurchaseHeaderOrder.Find();
        PurchaseHeaderOrder.SetRecFilter();

        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Order", REPORT::Order);
        Commit();
        DocumentPrint.PrintPurchHeader(PurchaseHeaderOrder);

        PurchaseHeaderOrder.Find();
        UpdatePurchInvoiceNo(PurchaseHeaderOrder);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, true);

        TearDownVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesOrderWith100PctPrepmtAndLineDiscAfterPartialPost()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 428300] User can open and close statisctics page for partially posted sales order with 100 % prepayment and line discount
        Initialize();

        // [GIVEN] Partially posted sales order with 100 % prepayment and line discount
        CreateVATPostingSetup(VATPostingSetup, 25);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        UpdateSalesPrepmtAccount(
            CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
            GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Order,
            LibrarySales.CreateCustomerWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item,
            LibraryInventory.CreateItemNoWithPostingSetup(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), 75.088);
        SalesLine.Validate("Unit Price", 44.7);
        SalesLine.Validate("Line Discount %", 10);
        SalesLine.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Ship", 60.3278);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run statistics page
        SalesOrder.OpenView();
        SalesOrder.GoToRecord(SalesHeader);
        SalesOrder.Statistics.Invoke();

        // [THEN] Statistics page can be closed without error (processed in SalesOrderStatisticsHandler)
        // [THEN] Sales order posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsSalesOrderWith100PctPrepmtAndLineDiscAfterPartialPostNM()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 428300] User can open and close statisctics page for partially posted sales order with 100 % prepayment and line discount
        Initialize();

        // [GIVEN] Partially posted sales order with 100 % prepayment and line discount
        CreateVATPostingSetup(VATPostingSetup, 25);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        UpdateSalesPrepmtAccount(
            CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
            GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Order,
            LibrarySales.CreateCustomerWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item,
            LibraryInventory.CreateItemNoWithPostingSetup(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), 75.088);
        SalesLine.Validate("Unit Price", 44.7);
        SalesLine.Validate("Line Discount %", 10);
        SalesLine.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Ship", 60.3278);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run statistics page
        SalesOrder.OpenView();
        SalesOrder.GoToRecord(SalesHeader);
        SalesOrder.SalesOrderStatistics.Invoke();

        // [THEN] Statistics page can be closed without error (processed in SalesOrderStatisticsHandlerNM)
        // [THEN] Sales order posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIfPrpmtCrMemoPostingIsNotUpdatingInvoiceNo()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GLAccount: array[2] of Record "G/L Account";
        ExpectedNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 443795] To ensure that prepayment no. series for invoice is not getting changed when a credit memo is posted.
        Initialize();

        // [GIVEN] Create a prepayment sales document.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        CreateTwoGLAccountsWithTwoPrepaymentGenPostingSetups(GLAccount, GenBusinessPostingGroup, VATPostingSetup);
        CreateSalesOrder_426793(SalesHeader, true, true, 10, GLAccount, GenBusinessPostingGroup, VATPostingSetup);
        DocumentNo := SalesHeader."No.";

        // [GIVEN] Post Prepayment Invoice.
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        ExpectedNo := SalesHeader."Prepayment No. Series";

        // [WHEN] Prepayment Cr. memo is posted.
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);

        // [WHEN] Prepayment No. series of Invoice should not be changed.
        Assert.AreEqual(ExpectedNo, SalesHeader."Prepayment No. Series", ExpectedNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialShipmentWith100PctPrepayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 448221] To ensure that document with 100 prepayment can be partial shipped
        Initialize();

        // [GIVEN] Create a prepayment sales document.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateFullPrepaymentSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", true);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 5);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        SalesLine.Modify(true);

        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group");

        DocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Qty To shp has been lowered
        UpdateSalesQtyToShip(SalesLine, 3);
        // [WHEN] Order gets released
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialRecievementWith100PctPrepayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 448221] To ensure that document with 100 prepayment can be partial shipped
        Initialize();

        // [GIVEN] Create a prepayment Purchase document.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateFullPrepaymentPurchHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", true);

        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 5);

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 1));
        PurchaseLine.Modify(true);


        LibraryERM.UpdatePurchPrepmtAccountVATGroup(
           PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");

        DocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Qty To shp has been lowered
        UpdatePurchQtyToReceive(PurchaseLine, 3);

        // [WHEN] Order gets released
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchPrepAmountToDeductToSmallErrorIfInvoiceMultipleReceipts()
    var
        OrderPurchaseHeader: Record "Purchase Header";
        InvoicePurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PrepmtInvoiceNo: array[3] of Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Get Receipt Lines]
        // [SCENARIO 439684] "The total Prepmt Amt to Deduct Incl. VAT must be at least..." error at an attempt to post the final invoice for a prepayment order
        Initialize();

        // [GIVEN] Purchase order with 41.66667% prepayment
        CreatePurchasePrepmtOrderWithTwoLines(OrderPurchaseHeader, 41.66667);

        // [GIVEN] Post first prepayment invoice and apply payment 
        OrderPurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        OrderPurchaseHeader.Modify();
        PrepmtInvoiceNo[1] := LibraryPurchase.PostPurchasePrepaymentInvoice(OrderPurchaseHeader);
        PostPaymentToInvoice(
            "Gen. Journal Account Type"::Vendor, OrderPurchaseHeader."Buy-from Vendor No.",
            PrepmtInvoiceNo[1], GetPurchaseInvAmount(PrepmtInvoiceNo[1]));

        // [GIVEN] Receipt receipt with 4000 pcs and then 1000 pcs for each line
        PostPurchaseOrderReceipt(OrderPurchaseHeader, 4000);
        PostPurchaseOrderReceipt(OrderPurchaseHeader, 1000);

        // [GIVEN] Invoice two receipts for 5000 pcs for each line and apply payment
        LibraryPurchase.CreatePurchHeader(InvoicePurchaseHeader, "Purchase Document Type"::Invoice, OrderPurchaseHeader."Buy-from Vendor No.");
        InvoicePurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        InvoicePurchaseHeader.Validate("Prices Including VAT", true);
        InvoicePurchaseHeader.Modify();
        GetPurchaseReceiptLines(InvoicePurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(InvoicePurchaseHeader, true, true);

        // [GIVEN] Reopen the order and change prepayment to 74.66667%
        OrderPurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(OrderPurchaseHeader);
        OrderPurchaseHeader.Validate("Prepayment %", 74.66667);
        OrderPurchaseHeader.Modify(true);

        // [GIVEN] Post second prepayment invoice and apply payment 
        OrderPurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        OrderPurchaseHeader.Modify();
        PrepmtInvoiceNo[2] := LibraryPurchase.PostPurchasePrepaymentInvoice(OrderPurchaseHeader);
        PostPaymentToInvoice(
            "Gen. Journal Account Type"::Vendor, OrderPurchaseHeader."Buy-from Vendor No.",
            PrepmtInvoiceNo[2], GetPurchaseInvAmount(PrepmtInvoiceNo[2]));

        // [GIVEN] Receipt and invoice with 4000 pcs for each line
        PostPurchaseOrderReceipt(OrderPurchaseHeader, 4000);
        LibraryPurchase.CreatePurchHeader(InvoicePurchaseHeader, "Purchase Document Type"::Invoice, OrderPurchaseHeader."Buy-from Vendor No.");
        InvoicePurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        InvoicePurchaseHeader.Validate("Prices Including VAT", true);
        InvoicePurchaseHeader.Modify();
        GetPurchaseReceiptLines(InvoicePurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(InvoicePurchaseHeader, true, true);

        // [GIVEN] Final receipt and invoice with 3000 pcs for each line
        PostPurchaseOrderReceipt(OrderPurchaseHeader, 3000);
        LibraryPurchase.CreatePurchHeader(InvoicePurchaseHeader, "Purchase Document Type"::Invoice, InvoicePurchaseHeader."Buy-from Vendor No.");
        InvoicePurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        InvoicePurchaseHeader.Validate("Prices Including VAT", true);
        InvoicePurchaseHeader.Modify();
        GetPurchaseReceiptLines(InvoicePurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(InvoicePurchaseHeader, true, true);

        // [WHEN] Check that all posted succesfully and there are 4 receipts and 5 posted invoices
        PurchRcptHeader.SetRange("Buy-from Vendor No.", OrderPurchaseHeader."Buy-from Vendor No.");
        Assert.RecordCount(PurchRcptHeader, 4);
        PurchInvHeader.SetRange("Buy-from Vendor No.", OrderPurchaseHeader."Buy-from Vendor No.");
        Assert.RecordCount(PurchInvHeader, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesPrepAmountToDeductToSmallErrorIfInvoiceMultipleShipments()
    var
        OrderSalesHeader: Record "Sales Header";
        InvoiceSalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PrepmtInvoiceNo: array[3] of Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Get Receipt Lines]
        // [SCENARIO 439684] "The total Prepmt Amt to Deduct Incl. VAT must be at least..." error at an attempt to post the final invoice for a prepayment order
        Initialize();

        // [GIVEN] Sales order with 41.66667% prepayment
        CreateSalesPrepmtOrderWithTwoLines(OrderSalesHeader, 41.66667);

        // [GIVEN] Post first prepayment invoice and apply payment 
        PrepmtInvoiceNo[1] := LibrarySales.PostSalesPrepaymentInvoice(OrderSalesHeader);
        PostPaymentToInvoice(
            "Gen. Journal Account Type"::Customer, OrderSalesHeader."Sell-to Customer No.",
            PrepmtInvoiceNo[1], GetSalesInvAmount(PrepmtInvoiceNo[1]));

        // [GIVEN] Receipt receipt with 4000 pcs and then 1000 pcs for each line
        PostSalesOrderShipment(OrderSalesHeader, 4000);
        PostSalesOrderShipment(OrderSalesHeader, 1000);

        // [GIVEN] Invoice two receipts for 5000 pcs for each line and apply payment
        LibrarySales.CreateSalesHeader(InvoiceSalesHeader, "Sales Document Type"::Invoice, OrderSalesHeader."Sell-to Customer No.");
        InvoiceSalesHeader.Validate("Prices Including VAT", true);
        InvoiceSalesHeader.Modify();
        GetSalesShipmentLines(InvoiceSalesHeader);
        LibrarySales.PostSalesDocument(InvoiceSalesHeader, true, true);

        // [GIVEN] Reopen the order and change prepayment to 74.66667%
        OrderSalesHeader.Find();
        LibrarySales.ReopenSalesDocument(OrderSalesHeader);
        OrderSalesHeader.Validate("Prepayment %", 74.66667);
        OrderSalesHeader.Modify(true);

        // [GIVEN] Post second prepayment invoice and apply payment 
        PrepmtInvoiceNo[2] := LibrarySales.PostSalesPrepaymentInvoice(OrderSalesHeader);
        PostPaymentToInvoice(
            "Gen. Journal Account Type"::Customer, OrderSalesHeader."Sell-to Customer No.",
            PrepmtInvoiceNo[2], GetSalesInvAmount(PrepmtInvoiceNo[2]));

        // [GIVEN] Receipt and invoice with 4000 pcs for each line
        PostSalesOrderShipment(OrderSalesHeader, 4000);
        LibrarySales.CreateSalesHeader(InvoiceSalesHeader, "Sales Document Type"::Invoice, OrderSalesHeader."Sell-to Customer No.");
        InvoiceSalesHeader.Validate("Prices Including VAT", true);
        InvoiceSalesHeader.Modify();
        GetSalesShipmentLines(InvoiceSalesHeader);
        LibrarySales.PostSalesDocument(InvoiceSalesHeader, true, true);

        // [GIVEN] Final receipt and invoice with 3000 pcs for each line
        PostSalesOrderShipment(OrderSalesHeader, 3000);
        LibrarySales.CreateSalesHeader(InvoiceSalesHeader, "Sales Document Type"::Invoice, InvoiceSalesHeader."Sell-to Customer No.");
        InvoiceSalesHeader.Validate("Prices Including VAT", true);
        InvoiceSalesHeader.Modify();
        GetSalesShipmentLines(InvoiceSalesHeader);
        LibrarySales.PostSalesDocument(InvoiceSalesHeader, true, true);

        // [WHEN] Check that all posted succesfully and there are 4 receipts and 5 posted invoices
        SalesShipmentHeader.SetRange("Sell-to Customer No.", OrderSalesHeader."Sell-to Customer No.");
        Assert.RecordCount(SalesShipmentHeader, 4);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", OrderSalesHeader."Sell-to Customer No.");
        Assert.RecordCount(SalesInvoiceHeader, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPrepmt100PctShouldPostPartialShipmentInvWithCorrectLineAmounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceLine2: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        Quantity: Integer;
        UnitPrice: Decimal;
        InvDiscountAmount: Decimal;
        QtyToShip: Decimal;
        LineAmount: Decimal;
        LineAmount2: Decimal;
    begin
        // [SCENARIO 495275] Line Amount is not correct in Sales Line with Prepayment Invoice
        Initialize();

        // [GIVEN] Set Check Prepmt. when Posting as false in Sales & Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Check Prepmt. when Posting" := false;
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Generate and save Quantity, Unit Price and Invoice Discount Amount in a Variable.
        Quantity := LibraryRandom.RandIntInRange(20, 20);
        UnitPrice := LibraryRandom.RandIntInRange(10, 10);
        InvDiscountAmount := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create VAT Posting Setup.
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Create General Posting Setup.
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            LibrarySales.CreateCustomerWithBusPostingGroups(
                GeneralPostingSetup."Gen. Bus. Posting Group",
                VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Validate Prepayment % in Sales Header.
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(100, 100));
        SalesHeader.Modify(true);

        // [GIVEN] Find Item.
        Item.Get(
            LibraryInventory.CreateItemNoWithPostingSetup(
                GeneralPostingSetup."Gen. Prod. Posting Group",
                VATPostingSetup."VAT Prod. Posting Group"));

        // [GIVEN] Create Custom Item Sales Line.
        CreateCustomItemSalesLine(SalesLine, SalesHeader, Item."No.", Quantity, UnitPrice);

        // [GIVEN] Validate Inv, Discount Amount in Sales Line.
        SalesLine.Validate("Inv. Discount Amount", InvDiscountAmount);
        SalesLine.Modify(true);

        // [GIVEN] Update Sales Prepmt Account.
        UpdateSalesPrepmtAccount(
            CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
            SalesLine."Gen. Bus. Posting Group",
            SalesLine."Gen. Prod. Posting Group");

        // [GIVEN] Post Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Generate and save Qty. to Ship and Line Amount in a Variable.
        QtyToShip := LibraryRandom.RandIntInRange(10, 10);
        LineAmount := QtyToShip * UnitPrice;
        LineAmount2 := (Quantity * UnitPrice - InvDiscountAmount) * QtyToShip / Quantity;

        // [GIVEN] Find and Validate Qty. to Ship in Sales Line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);

        // [GIVEN] Post Sales Shipment.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create Sales Invoice and Get Shipment Lines.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        GetShipmentLines(SalesHeader, SalesHeader2);

        // [GIVEN] Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, false, true);

        // [WHEN] Find Sales Invoice Line of Custom Item.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("No.", Item."No.");
        SalesInvoiceLine.FindFirst();

        // [VERIFY] Verify Line Amount of Sales Invoice Line is equal to LineAmount.
        Assert.AreEqual(LineAmount, SalesInvoiceLine."Line Amount", LineAmountMustMatchErr);

        // [WHEN] Find Sales Invoice Line of GL Account.
        SalesInvoiceLine2.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine2.SetRange(Type, SalesInvoiceLine2.Type::"G/L Account");
        SalesInvoiceLine2.FindFirst();

        // [VERIFY] Verify Line Amount of Sales Invoice Line is equal to LineAmount2.
        Assert.AreEqual(-LineAmount2, SalesInvoiceLine2."Line Amount", LineAmountMustMatchErr);
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    procedure OrderConfirmationPrintsPrepaymentsCorrectly()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AutoFormat: Codeunit "Auto Format";
        AutoFormatType: Enum "Auto Format";
        FormattedAmount: Text;
        SalesHeaderNo: Code[20];
    begin
        // [SCENARIO 542293] Standard Sales Order Report does Print Amount without deducting Prepayment Amount.
        Initialize();

        // [GIVEN] Find VAT Posting Setup.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Create a Customer and Validate VAT Bus. Posting Group.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        // [GIVEN] Create a Sales Header and Validate Prepayment Percentage.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(100, 100));
        SalesHeader.Modify(true);

        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] Create a Sales Line.
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item,
            LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 15));

        //[GIVEN] Validate Unit Price in Sales Line.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        SalesLine.Modify(true);

        // [GIVEN] Update Sales Prepayment Account Vat Group.
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group",
            SalesLine."Gen. Prod. Posting Group",
            SalesLine."VAT Prod. Posting Group");

        //[GIVEN] Post Sales Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        //[GIVEN] Reopen Sales Document and decrease Qty. to Ship.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(5, 7));
        SalesLine.Modify(true);

        // [GIVEN] Calculate Formatted Amount from Line Amount of Sales Line.
        FormattedAmount := Format(
            SalesLine."Line Amount", 0,
            AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, SalesLine."Currency Code"));

        //[WHEN] Run Standard Sales Order Confirmation Report.
        Commit();
        SalesHeader.SetRange("No.", SalesHeaderNo);
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, false, SalesHeader);
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Amount in Report must be equal to Formatted Amount.
        LibraryReportDataset.AssertElementWithValueExists('LineAmount_Line', FormattedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithPrepmt100PctAndWithInvDiscShouldPostPartialReceiptAndInvWithCorrectLineAmounts()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemNo: Code[20];
        Quantity: Decimal;
        DiscountAmount: array[4] of Decimal;
        SumPrePmtAmttoDeducted: Decimal;
        QtytoReceive: Decimal;
        DirectUnitCost: Decimal;
    begin
        // [SCENARIO 52558] Post Purchase Order partially with Prepayment % = 100 and Invoice Discount Amount
        // And Post Purchase Invoice with Prepayment % = 100 and Invoice Discount Amount with GetReceiptLines from posted receipts linked with prepayment Purchase Order.
        Initialize();

        // [GIVEN] Create a VAT Posting Setup.
        CreateVATPostingSetup(VATPostingSetup, 10);

        // [GIVEN] Create a General Posting Setup.
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Create a Vendor and Assign "Prepayment %".
        CreateVendorWithPostingGroup(Vendor, GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create a Invoice Discount for Vendor.
        CreateVendorInvDiscount(VendorInvoiceDisc, Vendor);

        // [GIVEN] Generate Quantity and save it in a Variable.
        Quantity := LibraryRandom.RandIntInRange(12, 12);

        // [GIVEN] Create a Item No with Posting Setup.
        ItemNo := LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Generate Direct Unit Cost and save it in a Variable.
        DirectUnitCost := LibraryRandom.RandIntInRange(1000, 1000);

        // [GIVEN] Update General Posting Setup for Prepayment Account.
        UpdatePurchasePrepmtAccount(
            CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
            GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create a Purchase Line and Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineOrder,
            PurchaseHeaderOrder,
            PurchaseLineOrder.Type::Item,
            ItemNo,
            Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLineOrder.Modify(true);

        // [WHEN] Run Codeunit "Purch.-Calc.Discount".         
        Codeunit.Run(Codeunit::"Purch.-Calc.Discount", PurchaseLineOrder);

        // [THEN] Calculate Discount Amount and save it in a Variable.
        DiscountAmount[1] := (PurchaseLineOrder.Quantity * PurchaseLineOrder."Direct Unit Cost") * VendorInvoiceDisc."Discount %" / 100;

        // [THEN] Verify "Invoice Discount Amount" with Calulated Discount Amount.
        Assert.AreEqual(
            PurchaseLineOrder."Inv. Discount Amount", DiscountAmount[1],
            StrSubstNo(AmountError, PurchaseLineOrder.FieldCaption("Inv. Discount Amount"), DiscountAmount[1], PurchaseLineOrder.TableCaption()));

        // [GIVEN] Update "Vendor Invoice No.".
        UpdatePurchInvoiceNo(PurchaseHeaderOrder);

        // [WHEN] Posted the Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeaderOrder);
        PurchaseLineOrder.Find();

        // [THEN] "Prepmt. Amt. Inv." is equal to Line Amount" - Discount Amount.
        Assert.AreEqual(
            PurchaseLineOrder."Prepmt. Amt. Inv.", (PurchaseLineOrder."Line Amount" - DiscountAmount[1]),
            StrSubstNo(
                AmountError,
                PurchaseLineOrder.FieldCaption("Prepmt. Amt. Inv."),
                (PurchaseLineOrder."Line Amount" - DiscountAmount[1]),
                PurchaseLineOrder.TableCaption()));

        // [GIVEN] Generate Qty to Receive and save it in a Variable.
        QtytoReceive := LibraryRandom.RandIntInRange(5, 5);

        // [WHEN] Partially Receive Purchase Order and Post Invoice.
        PostPurchaseOrderReceivePartiallyAndPostInvoice(
            QtytoReceive,
            PurchaseHeaderOrder,
            VendorInvoiceDisc,
            PurchaseLineOrder,
            PurchInvHeader,
            SumPrePmtAmttoDeducted,
            DiscountAmount[2]);

        // [THEN] Verify "Line Amount" of First "Purch. Invoice Line" is equal to Line Amount
        // And "Line Amount" of Second "Purch. Invoice Line" is equal to -Line Amount.
        VerifyAmounts(
            PurchaseLineOrder,
            PurchInvHeader,
            QtytoReceive,
            DirectUnitCost,
            DiscountAmount[2]);

        // [GIVEN] Generate Qty to Receive and save it in a Variable.
        QtytoReceive := LibraryRandom.RandIntInRange(6, 6);

        // [WHEN] Partially Receive Purchase Order and Post Invoice.
        PostPurchaseOrderReceivePartiallyAndPostInvoice(
            QtytoReceive,
            PurchaseHeaderOrder,
            VendorInvoiceDisc,
            PurchaseLineOrder,
            PurchInvHeader,
            SumPrePmtAmttoDeducted,
            DiscountAmount[3]);

        // [THEN] Verify "Line Amount" of First "Purch. Invoice Line" is equal to LineAmount
        // And "Line Amount" of Second "Purch. Invoice Line" is equal to -LineAmount.
        VerifyAmounts(
            PurchaseLineOrder,
            PurchInvHeader,
            QtytoReceive,
            DirectUnitCost,
            DiscountAmount[3]);

        // [GIVEN] Generate Qty to Receive and save it in a Variable.
        QtytoReceive := LibraryRandom.RandInt(0);

        // [WHEN] Fully Receive Purchase Order and Post Invoice.
        PostPurchaseOrderReceivePartiallyAndPostInvoice(
            QtytoReceive,
            PurchaseHeaderOrder,
            VendorInvoiceDisc,
            PurchaseLineOrder,
            PurchInvHeader,
            SumPrePmtAmttoDeducted,
            DiscountAmount[4]);

        // [THEN] Verify "Line Amount" of First "Purch. Invoice Line" is equal to LineAmount
        // And "Line Amount" of Second "Purch. Invoice Line" is equal to -LineAmount.
        VerifyAmounts(
            PurchaseLineOrder,
            PurchInvHeader,
            QtytoReceive,
            DirectUnitCost,
            DiscountAmount[4]);
    end;

    [Test]
    procedure SalesInvoiceIsPostedWithPrepaymentShipments()
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        Item: array[3] of Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PrepaymentPct: array[3] of Decimal;
        Price: array[3] of Decimal;
        Quantity: array[3] of Decimal;
    begin
        // [SCENARIO 558544] Sales Invoice gets posted when created from multiple shipment in case of prepayment.
        Initialize();

        // [GIVEN] Create a VAT Posting Setup.
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandIntInRange(8, 8));

        // [GIVEN] Create a General Posting Setup and update Sales Prepayment Account.
        CreateGeneralPostingSetupforSalesPrePayment(GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create a Customer and enable Price Including VAT.
        CreateCustomerWithPriceIncludingVAT(GeneralPostingSetup, VATPostingSetup, Customer);

        // [GIVEN] Create a Item No with Posting Setup.
        CreateThreeItems(GeneralPostingSetup, VATPostingSetup, Item);

        // [GIVEN] Generate Quantity.
        GenerateQuantity(Quantity);

        // [GIVEN] Generate Price.
        GeneratePrice(Price);

        // [GIVEN] Generate Prepayment Percentage.
        GeneratePrepaymentPercent(PrepaymentPct);

        // [GIVEN] Create a Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Order, Customer."No.");

        // [GIVEN] Create Sales Lines with three Items.
        CreateThreeSalesLines(SalesLine, SalesHeader[1], Item, Price, Quantity, PrepaymentPct);

        // [GIVEN] Sales Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader[1]);

        // [GIVEN] Create Multiple Shipments step wise.
        CreateMultipleShipments(SalesLine, Item, SalesHeader[1]);

        // [GIVEN] Cretae Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, Customer."No.");

        // [WHEN] Get Shipment Lines for Sales Invoice;
        GetSalesShipmentLines(SalesHeader[2]);

        // [THEN] Verify Sales Invoice gets posted without an error.
        LibrarySales.PostSalesDocument(SalesHeader[2], true, true);
    end;

    [Test]
    procedure PurchaseInvoiceIsPostedWithPrepayment()
    var
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchHeader: array[2] of Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PrepaymentPct: Decimal;
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO 592384] "You cannot post the document of type Order with the number XX before all related prepayment invoices are posted." error if you make a Partial Receipt on Prepaid Invoice and then additional Prepayment Amount prevents the posting of the main P.O.
        Initialize();

        // [GIVEN] Create a VAT Posting Setup.
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandIntInRange(0, 0));

        // [GIVEN] Create a General Posting Setup and update Purchase Prepayment Account.
        CreateGeneralPostingSetupforPurchPrePayment(GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create a Vendor
        Vendor.Get(LibraryPurchase.CreateVendorWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Create a Item No with Posting Setup.
        Item.Get(LibraryInventory.CreateItemNoWithPostingSetup(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchHeader[1], PurchHeader[1]."Document Type"::Order, Vendor."No.");
        PurchHeader[1].Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchHeader[1].Modify();

        // [GIVEN] Create Purchase Lines with four same Items.
        Quantity := 10000;
        DirectUnitCost := 4.11;
        PrepaymentPct := 30;
        CreateFourPurchaseLines(PurchLine, PurchHeader[1], Item, DirectUnitCost, Quantity, PrepaymentPct);

        // [GIVEN] Post Purch Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader[1]);

        // [GIVEN] Update Qty. to Receive on Purchase Line with 7008
        UpdatePurchaseLineQtytoReceive(PurchHeader[1], 7008);

        // [GIVEN] Post Purchase with Receive
        LibraryPurchase.PostPurchaseDocument(PurchHeader[1], true, false);

        // [GIVEN] Cretae Purchase Invoice.
        LibraryPurchase.CreatePurchHeader(PurchHeader[2], PurchHeader[2]."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Get Receipt Lines for Purchase Invoice
        GetPurchaseReceiptLines(PurchHeader[2]);

        // [GIVEN] Post Purchase Invoice.
        PostPurchaseDocument(PurchHeader[2], true, true);

        // [GIVEN] Reopen the Purchase Order Document
        LibraryPurchase.ReopenPurchaseDocument(PurchHeader[1]);

        // [WHEN] Release the Purchase Order Document
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader[1]);

        // [THEN] Verify Purchase Order gets posted without an error.
        PostPurchaseDocument(PurchHeader[1], true, true);
    end;

    [Test]
    procedure CheckYourReferanceforSalesOrderPrepayment()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeaderNo: Code[20];
    begin
        // [SCENARIO 606403] Your Reference field is not transferred from the Prepayment Invoice to the Customer Ledger Entries.
        Initialize();

        // [GIVEN] Find VAT Posting Setup.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Create a Customer and Validate VAT Bus. Posting Group.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        // [GIVEN] Create a Sales Header and Validate Prepayment Percentage.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(30, 30));
        SalesHeader.Validate("Your Reference", LibraryRandom.RandText(10));
        SalesHeader.Modify(true);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] Create a Sales Line.
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item,
            LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 15));

        //[GIVEN] Validate Unit Price in Sales Line.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        SalesLine.Modify(true);

        // [GIVEN] Update Sales Prepayment Account Vat Group.
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group",
            SalesLine."Gen. Prod. Posting Group",
            SalesLine."VAT Prod. Posting Group");

        //[GIVEN] Post Sales Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Verify "Your Reference" in Customer Ledger Entry is equal to "Your Reference" in Sales Header.
        VerifyYourReferenceValue(SalesHeader, SalesHeaderNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        CompanyInformation: Record "Company Information";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prepayment V");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prepayment V");

        CompanyInformation.Get();
        CompanyInformation."SWIFT Code" := 'A';
        CompanyInformation.Modify();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prepayment V");
    end;

    local procedure PrepareSetup_391612(var GeneralPostingSetup: Record "General Posting Setup"; var GLAccount: Record "G/L Account")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount."Gen. Prod. Posting Group" := '';
        GLAccount.Modify();

        // [GIVEN] Created new General Posting Setup and use created G/L Account for "Purch. Prepayments Account"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        GenBusinessPostingGroup."Def. VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        GenBusinessPostingGroup.Modify();
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GenProductPostingGroup.Modify();
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
    end;

    local procedure CreateTwoGLAccountsWithTwoPrepaymentGenPostingSetups(var GLAccount: array[2] of Record "G/L Account"; var GenBusinessPostingGroup: Record "Gen. Business Posting Group"; var VATPostingSetupGLAccount: Record "VAT Posting Setup")
    var
        GenProductPostingGroup: array[2] of Record "Gen. Product Posting Group";
        GeneralPostingSetup: array[2] of Record "General Posting Setup";
        GLAccountPrepayment: array[2] of Record "G/L Account";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(GeneralPostingSetup) do begin
            LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup[Index]);
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup[Index], GenBusinessPostingGroup.Code, GenProductPostingGroup[Index].Code);

            GLAccountPrepayment[Index].Get(LibraryERM.CreateGLAccountWithSalesSetup());
            GLAccountPrepayment[Index].Validate("Gen. Prod. Posting Group", GenProductPostingGroup[Index].Code);
            GLAccountPrepayment[Index].Validate("VAT Prod. Posting Group", VATPostingSetupGLAccount."VAT Prod. Posting Group");
            GLAccountPrepayment[Index].Modify(true);

            GeneralPostingSetup[Index].Validate("Sales Prepayments Account", GLAccountPrepayment[Index]."No.");
            GeneralPostingSetup[Index].Validate("Purch. Prepayments Account", GLAccountPrepayment[Index]."No.");
            GeneralPostingSetup[Index].Modify(true);

            GLAccount[Index].Get(LibraryERM.CreateGLAccountWithSalesSetup());
            GLAccount[Index].Validate("Gen. Prod. Posting Group", GenProductPostingGroup[Index].Code);
            GLAccount[Index].Validate("VAT Prod. Posting Group", VATPostingSetupGLAccount."VAT Prod. Posting Group");
            GLAccount[Index].Modify(true);
        end;
    end;

    local procedure CreateSalesOrder_426793(var SalesHeader: Record "Sales Header"; CompressPrepayment: Boolean; PriceIncludingVAT: Boolean; PrepaymentPercent: Decimal; var GLAccount: array[2] of Record "G/L Account"; var GenBusinessPostingGroup: Record "Gen. Business Posting Group"; var VATPostingSetupGLAccount: Record "VAT Posting Setup")
    var
        Customer: Record Customer;
        SalesLine: array[2] of Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetupGLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", PriceIncludingVAT);
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Validate("Compress Prepayment", CompressPrepayment);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::"G/L Account", GLAccount[1]."No.", 1);
        SalesLine[1].Validate("Unit Price", 6.25);
        SalesLine[1].Modify(true);

        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::"G/L Account", GLAccount[2]."No.", 1);
        SalesLine[2].Validate("Unit Price", 2500);
        SalesLine[2].Modify(true);
    end;

    local procedure CreatePurchaseOrder_426793(var PurchaseHeader: Record "Purchase Header"; var GLAccount: array[2] of Record "G/L Account"; var GenBusinessPostingGroup: Record "Gen. Business Posting Group"; var VATPostingSetupGLAccount: Record "VAT Posting Setup")
    var
        Vendor: Record Vendor;
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetupGLAccount."VAT Bus. Posting Group");
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Validate("Prepayment %", 10);
        PurchaseHeader.Validate("Compress Prepayment", true);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::"G/L Account", GLAccount[1]."No.", 1);
        PurchaseLine[1].Validate("Direct Unit Cost", 6.25);
        PurchaseLine[1].Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::"G/L Account", GLAccount[2]."No.", 1);
        PurchaseLine[2].Validate("Direct Unit Cost", 2500);
        PurchaseLine[2].Modify(true);
    end;

    local procedure PrepareVendorAndTwoGLAccWithSetup(var VATPostingSetup: Record "VAT Posting Setup"; var VendorNo: Code[20]; var GLAccountNo: array[2] of Code[20]; VATRate: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, VATRate);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[i] := CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup);
        UpdateVendorRoundingAccount(VendorNo, CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup));
        UpdatePurchasePrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure PrepareCustomerAndTwoGLAccWithSetup(var VATPostingSetup: Record "VAT Posting Setup"; var CustomerNo: Code[20]; var GLAccountNo: array[2] of Code[20]; VATRate: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, VATRate);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[i] := CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup);

        UpdateCustomerRoundingAccount(CustomerNo, CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup));
        UpdateSalesPrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure PrepareVendorAndTwoItemsWithSetup(var VATPostingSetup: Record "VAT Posting Setup"; var VendorNo: Code[20]; var ItemNo: array[2] of Code[20]; VATRate: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, VATRate);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] :=
              LibraryInventory.CreateItemNoWithPostingSetup(
                GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        UpdatePurchasePrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure PrepareCustomerAndTwoItemsWithSetup(var VATPostingSetup: Record "VAT Posting Setup"; var CustomerNo: Code[20]; var ItemNo: array[2] of Code[20]; VATRate: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, VATRate);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] :=
              LibraryInventory.CreateItemNoWithPostingSetup(
                GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        UpdateSalesPrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure CopySalesOrderFromSalesOrder(DocFromNo: Code[20]; var SalesHeaderTo: Record "Sales Header")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Order, DocFromNo, SalesHeaderTo);
    end;

    local procedure CopyPurchOrderFromPurchOrder(DocFromNo: Code[20]; var PurchaseHeaderTo: Record "Purchase Header")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopyPurchDoc("Purchase Document Type From"::Order, DocFromNo, PurchaseHeaderTo);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATRate: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithGivenSetup(VATPostingSetup: Record "VAT Posting Setup"; GeneralPostingSetup: Record "General Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithPostingGroups(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; CompressPrepayment: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateFullPrepaymentPurchHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", CompressPrepayment);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 1));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchDocumentWithTwoLines(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        CreateFullPrepaymentPurchHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", false);

        CreatePurchLine(PurchaseLine, PurchaseHeader);
        CreatePurchLine(PurchaseLine, PurchaseHeader);
    end;

    local procedure CreateFullPrepaymentPurchHeader(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGroup: Code[20]; CompressPrepayment: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(VATBusPostingGroup));
        PurchaseHeader.Validate("Prepayment %", 100);  // Added 100 for taking 100% prepayment amount.
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Compress Prepayment", CompressPrepayment);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(5) * 2); // to simplify next division by 2
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 1));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineAndCalcVATAmountLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; PricesInclVAT: Boolean; PrepmtPct: Decimal; DirectUnitCost: Decimal)
    begin
        CreatePurchaseHeader(PurchaseHeader, LibraryPurchase.CreateVendorNo(), PrepmtPct, PricesInclVAT);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, LibraryERM.CreateGLAccountWithPurchSetup(), 1, DirectUnitCost);
        PurchaseLine.CalcVATAmountLines(0, PurchaseHeader, PurchaseLine, VATAmountLine);
    end;

    local procedure CreatePartialSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line") SalesPrepmtAccount: Code[20]
    begin
        SalesPrepmtAccount := CreatePrepmtSalesOrder(SalesHeader, SalesLine);
        SalesLine.Validate("Qty. to Invoice", Round(SalesLine.Quantity / 2, 1));
        SalesLine.Modify(true);
    end;

    local procedure CreatePrepmtSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line") SalesPrepmtAccount: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        LineGLAccount: Record "G/L Account";
    begin
        SalesPrepmtAccount :=
          LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandInt(50));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesLine.Modify(true);
    end;

    local procedure CreatePrepmtPurchOrder(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LineGLAccount: Record "G/L Account";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");
        PurchHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchHeader.Modify(true);
        CreatePrepPurhcLine(PurchHeader, PurchLine, LineGLAccount."No.");
    end;

    local procedure CreatePartialPurchOrder(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LineGLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        PurchPrepmtAccount: Code[20];
    begin
        PurchPrepmtAccount :=
          LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");

        CreatePrepPurhcLine(PurchHeader, PurchLine, LineGLAccount."No.");
        PurchLine.Validate("Qty. to Invoice", Round(PurchLine.Quantity / 2, 1));
        PurchLine.Modify(true);

        exit(PurchPrepmtAccount);
    end;

    local procedure CreatePrepPurhcLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; LineGLAccountNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", LineGLAccountNo, LibraryRandom.RandInt(50));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Prepayment %", LibraryRandom.RandInt(50));
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; CompressPrepayment: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateFullPrepaymentSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", CompressPrepayment);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithTwoLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        CreateFullPrepaymentSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", false);

        CreateSalesLine(SalesLine, SalesHeader);
        CreateSalesLine(SalesLine, SalesHeader);
    end;

    local procedure CreateFullPrepaymentSalesHeader(var SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20]; CompressPrepayment: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATBusPostingGroup));
        SalesHeader.Validate("Prepayment %", 100);  // Added 100 for taking 100% prepayment amount.
        SalesHeader.Validate("Compress Prepayment", CompressPrepayment);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(5) * 2); // to simplify next division by 2
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        SalesLine.Modify(true);
    end;

    local procedure CreateDefaultDimensionAndUpdatePostingGroup(var DimensionValue: Record "Dimension Value"; GenBusPostingGroupCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        GenPostingSetup: Record "General Posting Setup";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        GenPostingSetup.SetRange("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        GenPostingSetup.FindFirst();
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GenPostingSetup."Purch. Prepayments Account",
          DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PrepaymentPct: Decimal; PricesInclVAT: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; NewQuantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, NewQuantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCustomItemPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; NewQuantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, NewQuantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PrepaymentPct: Decimal; PricesInclVAT: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
    end;

    local procedure CreateCustomSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; NewQuantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, NewQuantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateCustomItemSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; NewQuantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(
  SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, NewQuantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateCustomSalesLineAndCalcVATAmountLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; PricesInclVAT: Boolean; PrepmtPct: Decimal; UnitPrice: Decimal)
    begin
        CreateSalesHeader(SalesHeader, LibrarySales.CreateCustomerNo(), PrepmtPct, PricesInclVAT);
        CreateCustomSalesLine(SalesLine, SalesHeader, LibraryERM.CreateGLAccountWithPurchSetup(), 1, UnitPrice);
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, VATAmountLine);
    end;

    local procedure CreateSalesOrderWithOneLine(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateCustomItemSalesLine(SalesLine, SalesHeader, LibraryInventory.CreateItemNo(), 1, LibraryRandom.RandDecInRange(10, 100, 2));
    end;

    local procedure CreatePurchaseOrderWithOneLine(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 1, LibraryRandom.RandDecInRange(10, 100, 2));
    end;

    local procedure CreatePurchasePrepmtOrderWithTwoLines(var PurchaseHeader: Record "Purchase Header"; PrepmtPercent: Decimal)
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Validate("Prepayment %", PrepmtPercent);
        PurchaseHeader.Modify();
        LibraryInventory.CreateItem(Item);
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", 12000, 12.995); // first line
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", 12000, 12.995); // second line
    end;

    local procedure CreateSalesPrepmtOrderWithTwoLines(var SalesHeader: Record "Sales Header"; PrepmtPercent: Decimal)
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Validate("Prepayment %", PrepmtPercent);
        SalesHeader.Modify();
        LibraryInventory.CreateItem(Item);
        CreateCustomItemSalesLine(SalesLine, SalesHeader, Item."No.", 12000, 12.995); // first line
        CreateCustomItemSalesLine(SalesLine, SalesHeader, Item."No.", 12000, 12.995); // second line
    end;

    local procedure PostPurchaseOrderReceipt(var PurchaseHeader: Record "Purchase Header"; QtyToReceiveBase: Decimal): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLine.Validate("Qty. to Receive (Base)", QtyToReceiveBase);
                PurchaseLine.Modify();
            until PurchaseLine.Next() = 0;

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure PostSalesOrderShipment(var SalesHeader: Record "Sales Header"; QtyToShipBase: Decimal): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                SalesLine.Validate("Qty. to Ship (Base)", QtyToShipBase);
                SalesLine.Modify();
            until SalesLine.Next() = 0;

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure PostPaymentToInvoice(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetPurchaseInvAmount(DocumentNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        exit(-VendorLedgerEntry."Amount (LCY)");
    end;

    local procedure GetSalesInvAmount(DocumentNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        exit(-CustLedgerEntry."Amount (LCY)");
    end;

    local procedure GetPostedDocumentNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode));
    end;

    local procedure MockPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("No."), DATABASE::"Purchase Header");
        PurchaseHeader.Insert();
    end;

    local procedure MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader: Record "Purchase Header"; GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]; JobNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        RecRef.GetTable(PurchaseLine);
        PurchaseLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, PurchaseLine.FieldNo("Line No."));
        PurchaseLine."No." := LibraryUtility.GenerateRandomCode(PurchaseLine.FieldNo("No."), DATABASE::"Purchase Line");
        PurchaseLine."Prepmt. Amt. Inv." := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Gen. Bus. Posting Group" := GenBusPostingGroupCode;
        PurchaseLine."Gen. Prod. Posting Group" := GenProdPostingGroupCode;
        PurchaseLine."Job No." := JobNo;
        PurchaseLine.Insert();
    end;

    local procedure MockSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        SalesHeader.Insert();
    end;

    local procedure MockSalesLineWithPrepmtAmtInv(SalesHeader: Record "Sales Header"; GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]; JobNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        RecRef.GetTable(SalesLine);
        SalesLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No."));
        SalesLine."No." := LibraryUtility.GenerateRandomCode(SalesLine.FieldNo("No."), DATABASE::"Sales Line");
        SalesLine."Prepmt. Amt. Inv." := LibraryRandom.RandDec(100, 2);
        SalesLine."Gen. Bus. Posting Group" := GenBusPostingGroupCode;
        SalesLine."Gen. Prod. Posting Group" := GenProdPostingGroupCode;
        SalesLine."Job No." := JobNo;
        SalesLine.Insert();
    end;

    local procedure MockGenBusProdPostingGroups(var GenPostingSetup: Record "General Posting Setup"; var GenBusPostingGroupCode: Code[20]; var GenProdPostingGroupCode: Code[20])
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroupCode := GenBusPostingGroup.Code;
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        GenProdPostingGroupCode := GenProdPostingGroup.Code;
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostingGroupCode, GenProdPostingGroupCode);
    end;

    local procedure MockGenBusProdPostingGroupWithPrepmtAcc(var DimensionValue: Record "Dimension Value"; var GenBusPostingGroupCode: Code[20]; var GenProdPostingGroupCode: Code[20]; CreateDfltDimInAcc: Boolean)
    var
        DefaultDimension: Record "Default Dimension";
        GenPostingSetup: Record "General Posting Setup";
        GeneralPostingSetupPrepayment: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        MockGenBusProdPostingGroups(GenPostingSetup, GenBusPostingGroupCode, GenProdPostingGroupCode);

        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetupPrepayment);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetupPrepayment."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetupPrepayment."Gen. Prod. Posting Group");
        GLAccount.Modify(true);

        if CreateDfltDimInAcc then begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.",
              DimensionValue."Dimension Code", DimensionValue.Code);
        end;

        GenPostingSetup."Sales Prepayments Account" := GLAccount."No.";
        GenPostingSetup."Purch. Prepayments Account" := GLAccount."No.";
        GenPostingSetup.Modify();
    end;

    local procedure MockJobWithDfltDimension(var DimensionValue: Record "Dimension Value"): Code[20]
    var
        Job: Record Job;
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryJob.CreateJob(Job);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, Job."No.",
          DimensionValue."Dimension Code", DimensionValue.Code);
        exit(Job."No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenPurchaseOrderStatistics(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.Statistics.Invoke();
    end;
#endif

    local procedure OpenPurchOrderStatistics(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchaseOrderStatistics.Invoke();
    end;

    local procedure OpenPstdPurchCrMemorStatistics(No: Code[20])
    var
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
    begin
        PostedPurchaseCreditMemos.OpenEdit();
        PostedPurchaseCreditMemos.FILTER.SetFilter("No.", No);
        PostedPurchaseCreditMemos.Statistics.Invoke();
    end;

    local procedure OpenPstdSalesCrMemorStatistics(No: Code[20])
    var
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        PostedSalesCreditMemos.OpenEdit();
        PostedSalesCreditMemos.FILTER.SetFilter("No.", No);
        PostedSalesCreditMemos.Statistics.Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenSalesOrderStatistics(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.Statistics.Invoke();
    end;
#endif
    local procedure OpenSalesOrderStatisticsNM(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesOrderStatistics.Invoke();
    end;

    local procedure UpdatePurchasePrepmtAccount(PurchPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup."Purch. Prepayments Account" := PurchPrepaymentsAccount;
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesPrepmtAccount(SalesPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup."Sales Prepayments Account" := SalesPrepaymentsAccount;
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateVendorRoundingAccount(VendorNo: Code[20]; AccountNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorPostingGroup.Validate("Invoice Rounding Account", AccountNo);
        VendorPostingGroup.Modify(true);
    end;

    local procedure UpdateCustomerRoundingAccount(CustomerNo: Code[20]; AccountNo: Code[20])
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Invoice Rounding Account", AccountNo);
        CustomerPostingGroup.Modify(true);
    end;

    local procedure PostSalesDocumentPartially(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);
            SalesLine.Modify();
        until SalesLine.Next() = 0;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostPurchDocumentPartially(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
            PurchaseLine.Modify();
        until PurchaseLine.Next() = 0;
        PurchaseHeader."Vendor Invoice No." := IncStr(PurchaseHeader."Vendor Invoice No.");
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateSalesPrepmtAmtToDeductWithPrepmtAmtInvoiced(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Find();
        SalesLine.Validate("Prepmt Amt to Deduct", SalesLine."Prepmt. Amt. Inv.");
        SalesLine.Modify(true);
    end;

    local procedure UpdatePurchPrepmtAmtToDeductWithPrepmtAmtInvoiced(var PurchLine: Record "Purchase Line")
    begin
        PurchLine.Find();
        PurchLine.Validate("Prepmt Amt to Deduct", PurchLine."Prepmt. Amt. Inv.");
        PurchLine.Modify(true);
    end;

    local procedure UpdateGeneralSetup(AmountDecimalPlaces: Text[5]; UnitAmountDecimalPlaces: Text[5]; AmountRoundingPrecision: Decimal; UnitAmountRoundingPrecision: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Amount Decimal Places" := AmountDecimalPlaces;
        GeneralLedgerSetup."Unit-Amount Decimal Places" := UnitAmountDecimalPlaces;
        GeneralLedgerSetup."Amount Rounding Precision" := AmountRoundingPrecision;
        GeneralLedgerSetup."Unit-Amount Rounding Precision" := UnitAmountRoundingPrecision;
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := AmountRoundingPrecision;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdatePurchTotalPrepmtAmount(PurchaseHeader: Record "Purchase Header"; NewPrepmtTotalAmount: Decimal)
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchasePostPrepayments.UpdatePrepmtAmountOnPurchLines(PurchaseHeader, NewPrepmtTotalAmount);
    end;

    local procedure UpdateSalesTotalPrepmtAmount(SalesHeader: Record "Sales Header"; NewPrepmtTotalAmount: Decimal)
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.UpdatePrepmtAmountOnSaleslines(SalesHeader, NewPrepmtTotalAmount);
    end;

    local procedure UpdatePurchQtyToReceive(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchQtyToInvoice(var PurchaseLine: Record "Purchase Line"; QtyToInvoice: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesQtyToShip(var SalesLine: Record "Sales Line"; QtyToShip: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesQtyToInvoice(var SalesLine: Record "Sales Line"; QtyToInvoice: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure UpdatePurchPrepmtAmtToDeduct(var PurchaseLine: Record "Purchase Line"; PrepmtAmtToDeduct: Decimal)
    begin
        PurchaseLine.Validate("Prepmt Amt to Deduct", PrepmtAmtToDeduct);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesPrepmtAmtToDeduct(var SalesLine: Record "Sales Line"; PrepmtAmtToDeduct: Decimal)
    begin
        SalesLine.Validate("Prepmt Amt to Deduct", PrepmtAmtToDeduct);
        SalesLine.Modify(true);
    end;

    local procedure UpdatePurchInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure GetInvRoundingAccFromCust(CustNo: Code[20]): Code[20]
    var
        Cust: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
    begin
        Cust.Get(CustNo);
        CustPostingGroup.Get(Cust."Customer Posting Group");
        exit(CustPostingGroup."Invoice Rounding Account");
    end;

    local procedure GetInvRoundingAccFromVend(VendNo: Code[20]): Code[20]
    var
        Vend: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
    begin
        Vend.Get(VendNo);
        VendPostingGroup.Get(Vend."Vendor Posting Group");
        exit(VendPostingGroup."Invoice Rounding Account");
    end;

    local procedure GetVATEntryAmount(CustomerNo: Code[20]; DocumentNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", CustomerNo);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        exit(VATEntry.Amount);
    end;

    local procedure GetPurchaseReceiptLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure GetSalesShipmentLines(SalesHeader: Record "Sales Header")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
    end;

    local procedure FindPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; VendorNo: Code[20])
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("Prepayment Invoice", true);
        PurchInvHeader.FindFirst();
    end;

    local procedure FindPostedPurchaseCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; VendorNo: Code[20])
    begin
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", VendorNo);
        PurchCrMemoHdr.SetRange("Prepayment Credit Memo", true);
        PurchCrMemoHdr.FindFirst();
    end;

    local procedure FindPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustomerNo: Code[20])
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.SetRange("Prepayment Invoice", true);
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure FindPostedSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CustomerNo: Code[20])
    begin
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesCrMemoHeader.SetRange("Prepayment Credit Memo", true);
        SalesCrMemoHeader.FindFirst();
    end;

    local procedure SetCheckPrepaymentinSalesSetup(CheckPrepmt: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Check Prepmt. when Posting", CheckPrepmt);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetSalesInvoiceDiscountAmount(var SalesHeader: Record "Sales Header"; InvoiceDiscountAmount: Decimal)
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        SalesHeader.Find();
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
    end;

    local procedure SetPurchaseInvoiceDiscountAmount(var PurchaseHeader: Record "Purchase Header"; InvoiceDiscountAmount: Decimal)
    var
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        PurchaseHeader.Find();
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
    end;

    local procedure UpdatePrepmtAccInGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup."Sales Prepayments Account" := CreateGLAccountWithPostingGroups();
        GeneralPostingSetup."Purch. Prepayments Account" := CreateGLAccountWithPostingGroups();
        GeneralPostingSetup.Modify(true);
    end;

    local procedure TearDownVATPostingSetup(VATBusPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.DeleteAll();
    end;

    local procedure VerifyGLEntry(Amount: Decimal; DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntriesAmount(Amount: Decimal; DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryDoesNotExist(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyFirstSalesLinePrepmtAmountInvLCY(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        Assert.AreEqual(SalesLine."Prepayment Amount" / 2, SalesLine."Prepmt. Amount Inv. (LCY)", IncorrectPrepmtAmountInvLCYErr);
    end;

    local procedure VerifyFirstPurchLinePrepmtAmountInvLCY(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        Assert.AreEqual(PurchaseLine."Prepayment Amount" / 2, PurchaseLine."Prepmt. Amount Inv. (LCY)", IncorrectPrepmtAmountInvLCYErr);
    end;

    local procedure VerifyDimensionSetEntryIsExists(DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DummyDimensionSetEntry: Record "Dimension Set Entry";
    begin
        DummyDimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DummyDimensionSetEntry.SetRange("Dimension Value Code", DimensionValueCode);
        Assert.RecordIsNotEmpty(DummyDimensionSetEntry);
    end;

    local procedure VerifyDimensionSetEntryIsNotExists(DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DummyDimensionSetEntry: Record "Dimension Set Entry";
    begin
        DummyDimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DummyDimensionSetEntry.SetRange("Dimension Value Code", DimensionValueCode);
        Assert.RecordIsEmpty(DummyDimensionSetEntry);
    end;

    local procedure VerifySalesPrepaymentCreditMemoVATAmount(SalesHeader: Record "Sales Header")
    var
        ExpectedVATAmount: Decimal;
    begin
        ExpectedVATAmount := -GetVATEntryAmount(SalesHeader."Sell-to Customer No.", SalesHeader."Last Prepayment No.");
        Assert.AreEqual(
          ExpectedVATAmount,
          GetVATEntryAmount(SalesHeader."Sell-to Customer No.", SalesHeader."Last Prepmt. Cr. Memo No."),
          IncorrectVATEntryAmountErr);
    end;

    local procedure VerifyPurchPrepaymentCreditMemoVATAmount(PurchaseHeader: Record "Purchase Header")
    var
        ExpectedVATAmount: Decimal;
    begin
        ExpectedVATAmount := -GetVATEntryAmount(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Last Prepayment No.");
        Assert.AreEqual(
          ExpectedVATAmount,
          GetVATEntryAmount(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Last Prepmt. Cr. Memo No."),
          IncorrectVATEntryAmountErr);
    end;

    local procedure VerifyGLAccountBalance(GLAccountNo: Code[20]; DocumentNo: Code[20]; ExpectedBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpectedBalance);
    end;

    local procedure VerifyCustomerReceivablesAccountAmount(CustomerPostingGroupCode: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        VerifyGLAccountBalance(CustomerPostingGroup."Receivables Account", DocumentNo, ExpectedAmount);
    end;

    local procedure VerifyVendorPayablesAccountAmount(VendorPostingGroupCode: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        VerifyGLAccountBalance(VendorPostingGroup."Payables Account", DocumentNo, ExpectedAmount);
    end;

    local procedure VerifyValueNeedsToBeRounded(Value: Decimal)
    begin
        Assert.ExpectedErrorCode('TableErrorStr');
        Assert.ExpectedError(
          StrSubstNo('%1 needs to be rounded', Format(Value, 0, '<Sign><Integer Thousand><Decimals,3><Filler Character,0>')));
    end;

    local procedure VerifySalesLineFullPrepaymentWithDiscount(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.FindFirst();
        SalesLine.TestField("Prepmt. Line Amount", SalesLine.Amount);
    end;

    local procedure VerifyPurchaseLineFullPrepaymentWithDiscount(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Prepmt. Line Amount", PurchaseLine.Amount);
    end;

    local procedure VerifyPostedSalesInvoiceCommentLine(PostedDocumentNo: Code[20]; ExpectedLineComment: Text[80]; ExpectedNoOfAllComments: Integer; ExpectedNoOfLineComments: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Posted Invoice");
        SalesCommentLine.SetRange("No.", PostedDocumentNo);
        Assert.RecordCount(SalesCommentLine, ExpectedNoOfAllComments);

        SalesCommentLine.SetRange("Document Line No.", 0);
        Assert.RecordCount(SalesCommentLine, ExpectedNoOfAllComments - ExpectedNoOfLineComments);

        if ExpectedNoOfLineComments > 0 then begin
            SalesCommentLine.SetFilter("Document Line No.", '>0');
            SalesCommentLine.FindLast();
            SalesCommentLine.TestField(Comment, ExpectedLineComment);
        end;
    end;

    local procedure VerifyPostedPurchaseInvoiceCommentLine(PostedDocumentNo: Code[20]; ExpectedLineComment: Text[80]; ExpectedNoOfAllComments: Integer; ExpectedNoOfLineComments: Integer)
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::"Posted Invoice");
        PurchCommentLine.SetRange("No.", PostedDocumentNo);
        Assert.RecordCount(PurchCommentLine, ExpectedNoOfAllComments);

        PurchCommentLine.SetRange("Document Line No.", 0);
        Assert.RecordCount(PurchCommentLine, ExpectedNoOfAllComments - ExpectedNoOfLineComments);

        if ExpectedNoOfLineComments > 0 then begin
            PurchCommentLine.SetFilter("Document Line No.", '>0');
            PurchCommentLine.FindLast();
            PurchCommentLine.TestField(Comment, ExpectedLineComment);
        end;
    end;

    local procedure VerifyPostedSalesCreditMemoCommentLine(PostedDocumentNo: Code[20]; ExpectedLineComment: Text[80]; LineNo: Integer; ExpectedNoOfAllComments: Integer; ExpectedNoOfLineComments: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Posted Credit Memo");
        SalesCommentLine.SetRange("No.", PostedDocumentNo);
        Assert.RecordCount(SalesCommentLine, ExpectedNoOfAllComments);

        SalesCommentLine.SetRange("Document Line No.", 0);
        Assert.RecordCount(SalesCommentLine, ExpectedNoOfAllComments - ExpectedNoOfLineComments);

        if ExpectedNoOfLineComments > 0 then begin
            SalesCommentLine.SetRange("Document Line No.", LineNo);
            SalesCommentLine.FindLast();
            SalesCommentLine.TestField(Comment, ExpectedLineComment);
        end;
    end;

    local procedure VerifyPostedPurchaseCreditMemoCommentLine(PostedDocumentNo: Code[20]; ExpectedLineComment: Text[80]; LineNo: Integer; ExpectedNoOfAllComments: Integer; ExpectedNoOfLineComments: Integer)
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::"Posted Credit Memo");
        PurchCommentLine.SetRange("No.", PostedDocumentNo);
        Assert.RecordCount(PurchCommentLine, ExpectedNoOfAllComments);

        PurchCommentLine.SetRange("Document Line No.", 0);
        Assert.RecordCount(PurchCommentLine, ExpectedNoOfAllComments - ExpectedNoOfLineComments);

        if ExpectedNoOfLineComments > 0 then begin
            PurchCommentLine.SetRange("Document Line No.", LineNo);
            PurchCommentLine.FindLast();
            PurchCommentLine.TestField(Comment, ExpectedLineComment);
        end;
    end;

    local procedure VerifyPostedSalesInvoiceWithPrepmt(PostedSalesInvoiceNo: Code[20]; LineType: Enum "Sales Line Type"; No: Code[20]; SalesPrepmtGLAccountNo: Code[20]; LineAmount: Decimal; InvDiscountAmount: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.Get(PostedSalesInvoiceNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
        SalesInvoiceHeader.TestField(Amount, 0);
        SalesInvoiceHeader.TestField("Amount Including VAT", 0);
        SalesInvoiceHeader.TestField("Remaining Amount", 0);

        SalesInvoiceLine.SetRange("Document No.", PostedSalesInvoiceNo);
        SalesInvoiceLine.SetRange(Type, LineType);
        SalesInvoiceLine.SetRange("No.", No);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Line Amount", LineAmount);
        SalesInvoiceLine.TestField("Inv. Discount Amount", InvDiscountAmount);
        SalesInvoiceLine.TestField(Amount, LineAmount - InvDiscountAmount);

        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        SalesInvoiceLine.SetRange("No.", SalesPrepmtGLAccountNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Amount, -(LineAmount - InvDiscountAmount));
    end;

    local procedure VerifyPostedPurchaseInvoiceWithPrepmt(PostedPurchaseInvoiceNo: Code[20]; LineType: Enum "Purchase Line Type"; No: Code[20]; PurchasePrepmtGLAccountNo: Code[20]; LineAmount: Decimal; InvDiscountAmount: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.Get(PostedPurchaseInvoiceNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
        PurchInvHeader.TestField(Amount, 0);
        PurchInvHeader.TestField("Amount Including VAT", 0);
        PurchInvHeader.TestField("Remaining Amount", 0);

        PurchInvLine.SetRange("Document No.", PostedPurchaseInvoiceNo);
        PurchInvLine.SetRange(Type, LineType);
        PurchInvLine.SetRange("No.", No);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Line Amount", LineAmount);
        PurchInvLine.TestField("Inv. Discount Amount", InvDiscountAmount);
        PurchInvLine.TestField(Amount, LineAmount - InvDiscountAmount);

        PurchInvLine.SetRange(Type, PurchInvLine.Type::"G/L Account");
        PurchInvLine.SetRange("No.", PurchasePrepmtGLAccountNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Amount, -(LineAmount - InvDiscountAmount));
    end;

    local procedure VerifyErrorMessage(var ErrorMessages: TestPage "Error Messages"; ExpectedDescription: Text; ExpectedContextRecordId: RecordId; ExpectedContextFieldName: Text; ExpectedSourceRecordId: RecordId; ExpectedSourceFieldName: Text; ExpectedURL: Text)
    begin
        ErrorMessages.Description.AssertEquals(ExpectedDescription);
        ErrorMessages.Context.AssertEquals(ExpectedContextRecordId);
        ErrorMessages."Context Field Name".AssertEquals(ExpectedContextFieldName);
        ErrorMessages.Source.AssertEquals(ExpectedSourceRecordId);
        ErrorMessages."Field Name".AssertEquals(ExpectedSourceFieldName);
        ErrorMessages."Support Url".AssertEquals(ExpectedURL);
    end;

    local procedure VerifyVATEntryBaseAndAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.FindFirst();
        VATEntry.TestField(Base, ExpectedBase);
        VATEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLVATEntries(PostedDocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", PostedDocumentNo);
        Assert.RecordCount(GLEntry, 5);
    end;

    local procedure GetShipmentLines(SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShpt: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesGetShpt.SetSalesHeader(SalesHeader2);
        SalesGetShpt.CreateInvLines(SalesShipmentLine);
    end;

    local procedure CreateVendorWithPostingGroup(
        var Vendor: Record Vendor;
        var GeneralPostingSetup: Record "General Posting Setup";
        var VATPostingSetup: Record "VAT Posting Setup")
    begin
        Vendor.Get(
            LibraryPurchase.CreateVendorWithBusPostingGroups(
                GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        Vendor.Validate("Prepayment %", 100);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorInvDiscount(var VendorInvoiceDisc: Record "Vendor Invoice Disc."; var Vendor: Record Vendor)
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", '', 0);
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure PostPurchaseOrderReceivePartiallyAndPostInvoice(
        QtytoRecieve: Decimal;
        var PurchaseHeaderOrder: Record "Purchase Header";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        var PurchaseLineOrder: Record "Purchase Line";
        var PurchInvHeader: Record "Purch. Inv. Header";
        var SumPrePmtAmttoDeducted: Decimal;
        var DiscountAmount: Decimal)
    begin
        PostPurchaseOrderReceipt(PurchaseHeaderOrder, QtytoRecieve);
        CreatePurchaseInvoicefromGetReceiptLinesWithPrepayment(
            PurchaseHeaderOrder,
            VendorInvoiceDisc,
            PurchaseLineOrder,
            PurchInvHeader,
            SumPrePmtAmttoDeducted,
            DiscountAmount);
    end;

    local procedure CreatePurchaseInvoicefromGetReceiptLinesWithPrepayment(
        var PurchaseHeaderOrder: Record "Purchase Header";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        var PurchaseLineOrder: Record "Purchase Line";
        var PurchInvHeader: Record "Purch. Inv. Header";
        var SumPrePmtAmttoDeducted: Decimal;
        var DiscountAmount: Decimal)
    var
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeaderInvoice,
            PurchaseHeaderInvoice."Document Type"::Invoice,
            PurchaseHeaderOrder."Buy-from Vendor No.");
        UpdatePurchInvoiceNo(PurchaseHeaderInvoice);
        GetPurchaseReceiptLines(PurchaseHeaderInvoice);
        FindPurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineOrder."No.");

        DiscountAmount := (PurchaseLineInvoice.Quantity * PurchaseLineInvoice."Direct Unit Cost") * VendorInvoiceDisc."Discount %" / 100;
        SumPrePmtAmttoDeducted += PurchaseLineInvoice."Prepmt Amt to Deduct";

        Assert.AreEqual(
            PurchaseLineInvoice."Inv. Discount Amount", DiscountAmount,
            StrSubstNo(
                AmountError, PurchaseLineInvoice.FieldCaption("Inv. Discount Amount"),
                DiscountAmount, PurchaseLineInvoice.TableCaption()));
        Assert.AreEqual(
            PurchaseLineInvoice."Prepmt Amt to Deduct", (PurchaseLineInvoice."Line Amount" - DiscountAmount),
            StrSubstNo(
                AmountError, PurchaseLineInvoice.FieldCaption("Prepmt Amt to Deduct"),
                (PurchaseLineInvoice."Line Amount" - DiscountAmount), PurchaseLineInvoice.TableCaption()));

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true));
        PurchaseLineOrder.Find();

        Assert.AreEqual(
            PurchaseLineOrder."Prepmt Amt Deducted", SumPrePmtAmttoDeducted,
            StrSubstNo(
                AmountError, PurchaseLineOrder.FieldCaption("Prepmt Amt Deducted"),
                SumPrePmtAmttoDeducted, PurchaseLineOrder.TableCaption()));
    end;

    local procedure VerifyAmounts(
        PurchaseLineOrder: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        QtytoReceive: Decimal;
        DirectUnitCost: Decimal;
        DiscountAmount: Decimal)
    var
        PurchInvLine: array[2] of Record "Purch. Inv. Line";
        LineAmount: array[2] of Decimal;
    begin
        LineAmount[1] := QtytoReceive * DirectUnitCost;
        LineAmount[2] := (QtytoReceive * DirectUnitCost - DiscountAmount);

        PurchInvLine[1].SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine[1].SetRange("No.", PurchaseLineOrder."No.");
        PurchInvLine[1].FindFirst();

        Assert.AreEqual(LineAmount[1], PurchInvLine[1]."Line Amount", LineAmountMustMatchErr);

        PurchInvLine[2].SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine[2].SetRange(Type, PurchInvLine[2].Type::"G/L Account");
        PurchInvLine[2].FindFirst();

        Assert.AreEqual(-LineAmount[2], PurchInvLine[2]."Line Amount", LineAmountMustMatchErr);
    end;

    local procedure CreateGeneralPostingSetupforSalesPrePayment(var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
        GenPostingType: Enum "General Posting Type";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);

        GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryERM.UpdateGLAccountWithPostingSetup(GLAccount, GenPostingType::Sale, GeneralPostingSetup, VATPostingSetup);
    end;

    local procedure CreateCustomerWithPriceIncludingVAT(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; var Customer: Record Customer)
    begin
        Customer.Get(LibrarySales.CreateCustomerWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);
    end;

    local procedure CreateThreeItems(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; var Item: array[3] of Record Item)
    var
        i: Integer;
    begin
        for i := 1 to 3 do
            Item[i].Get(LibraryInventory.CreateItemNoWithPostingSetup(
                GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure GenerateQuantity(var Quantity: array[3] of Decimal)
    begin
        Quantity[1] := LibraryRandom.RandIntInRange(66746, 66746);
        Quantity[2] := LibraryRandom.RandIntInRange(34000, 34000);
        Quantity[3] := LibraryRandom.RandIntInRange(1320, 1320);
    end;

    local procedure GeneratePrice(var Price: array[3] of Decimal)
    begin
        Price[1] := LibraryRandom.RandDecInDecimalRange(12.64, 12.64, 2);
        Price[2] := LibraryRandom.RandDecInDecimalRange(13.50, 13.50, 2);
        Price[3] := LibraryRandom.RandDecInDecimalRange(14.04, 14.04, 2);
    end;

    local procedure GeneratePrepaymentPercent(var PrepaymentPct: array[3] of Decimal)
    begin
        PrepaymentPct[1] := LibraryRandom.RandDecInDecimalRange(47.94, 47.94, 2);
        PrepaymentPct[2] := LibraryRandom.RandDecInDecimalRange(47.94, 47.94, 2);
        PrepaymentPct[3] := LibraryRandom.RandDecInDecimalRange(48.6301, 48.6301, 4);
    end;

    local procedure CreateThreeSalesLines(
        var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header";
        Item: array[3] of Record Item; Price: array[3] of Decimal;
        Quantity: array[3] of Decimal; PrepaymentPct: array[3] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to 3 do begin
            LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, Item[i]."No.", Price[i], Quantity[i]);
            SalesLine.Validate("Prepayment %", PrepaymentPct[i]);
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateMultipleShipments(var SalesLine: Record "Sales Line"; Item: array[3] of Record Item; SalesHeader: Record "Sales Header")
    begin
        ResetQtyToShip(SalesLine."Document No.");
        UpdateQtyToShip(SalesLine, Item[1]."No.", LibraryRandom.RandIntInRange(4500, 4500));
        UpdateQtyToShip(SalesLine, Item[3]."No.", LibraryRandom.RandIntInRange(1320, 1320));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[1]."No.", LibraryRandom.RandIntInRange(8640, 8640));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[1]."No.", LibraryRandom.RandIntInRange(8640, 8640));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[1]."No.", LibraryRandom.RandIntInRange(8640, 8640));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[2]."No.", LibraryRandom.RandIntInRange(5760, 5760));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[2]."No.", LibraryRandom.RandIntInRange(5760, 5760));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[1]."No.", LibraryRandom.RandIntInRange(8640, 8640));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[1]."No.", LibraryRandom.RandIntInRange(8640, 8640));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[1]."No.", LibraryRandom.RandIntInRange(8640, 8640));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[1]."No.", LibraryRandom.RandIntInRange(7740, 7740));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[1]."No.", LibraryRandom.RandIntInRange(2666, 2666));
        UpdateQtyToShip(SalesLine, Item[2]."No.", LibraryRandom.RandIntInRange(2640, 2640));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[2]."No.", LibraryRandom.RandIntInRange(5760, 5760));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[2]."No.", LibraryRandom.RandIntInRange(5760, 5760));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[2]."No.", LibraryRandom.RandIntInRange(5760, 5760));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ResetQtyToShip(SalesLine."Document No.");

        UpdateQtyToShip(SalesLine, Item[2]."No.", LibraryRandom.RandIntInRange(2560, 2560));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure ResetQtyToShip(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        if SalesLine.FindSet() then
            repeat
                SalesLine.Validate("Qty. to Ship", 0);
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;
    end;

    local procedure UpdateQtyToShip(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; QtyToShip: Decimal)
    begin
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure CreateGeneralPostingSetupforPurchPrePayment(var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
        GenPostingType: Enum "General Posting Type";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);

        GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
        LibraryERM.UpdatePurchPrepmtAccountVATGroup(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryERM.UpdateGLAccountWithPostingSetup(GLAccount, GenPostingType::Purchase, GeneralPostingSetup, VATPostingSetup);
    end;

    local procedure CreateFourPurchaseLines(
        var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header";
        Item: Record Item; DirectUnitCost: Decimal;
        Quantity: Decimal; PrepaymentPct: Decimal)
    var
        i: Integer;
    begin
        for i := 1 to 4 do begin
            LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", DirectUnitCost, Quantity);
            PurchaseLine.Validate("Prepayment %", PrepaymentPct);
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure UpdatePurchaseLineQtytoReceive(PurchaseHeader: Record "Purchase Header"; QtytoReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLine.Validate("Qty. to Receive", QtytoReceive);
                PurchaseLine.Modify(true);
            until PurchaseLine.Next() = 0;
    end;

    local procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; Receive: Boolean; Invoice: Boolean): Code[20]
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Receive, Invoice));
    end;

    local procedure VerifyYourReferenceValue(var SalesHeader: Record "Sales Header"; SalesHeaderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SalesInvoiceHeader.SetRange("Prepayment Order No.", SalesHeaderNo);
        if SalesInvoiceHeader.FindFirst() then;
        CustomerLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        if CustomerLedgerEntry.FindFirst() then;

        Assert.AreEqual(SalesHeader."Your Reference", CustomerLedgerEntry."Your Reference", YourReferenceMustBeTheSameErr);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoStatisticsPageHandler(var PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        PurchCreditMemoStatistics.VATAmount.AssertEquals(VATAmount);
        PurchCreditMemoStatistics.AmountInclVAT.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        PurchaseOrderStatistics."VATAmount[1]".AssertEquals(VATAmount);
        PurchaseOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        PurchaseOrderStatistics."VATAmount[1]".AssertEquals(VATAmount);
        PurchaseOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        SalesOrderStatistics.VATAmount.AssertEquals(VATAmount);
        SalesOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsForInvDiscPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        InvDiscAmount_Invoicing: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount_Invoicing);
        SalesOrderStatistics.InvDiscountAmount_Invoicing.AssertEquals(InvDiscAmount_Invoicing);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        SalesOrderStatistics.VATAmount.AssertEquals(VATAmount);
        SalesOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsForInvDiscPageHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        InvDiscAmount_Invoicing: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscAmount_Invoicing);
        SalesOrderStatistics.InvDiscountAmount_Invoicing.AssertEquals(InvDiscAmount_Invoicing);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoStatisticsPageHandler(var SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        SalesCreditMemoStatistics.VATAmount.AssertEquals(VATAmount);
        SalesCreditMemoStatistics.AmountInclVAT.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrdStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrderStatistics.LineAmountGeneral.Value);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrdStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrderStatistics.LineAmountGeneral.Value);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrdStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(SalesOrderStatistics.LineAmountGeneral.Value);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrdStatisticsPageHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(SalesOrderStatistics.LineAmountGeneral.Value);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConfRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        StandardSalesOrderConf.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderRequestPageHandler(var "Order": TestRequestPage "Order")
    begin
        Order.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3; // Receive and Invoice
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
    end;
}