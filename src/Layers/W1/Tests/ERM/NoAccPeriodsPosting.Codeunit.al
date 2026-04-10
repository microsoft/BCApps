codeunit 134361 "No Acc. Periods: Posting"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [No Accounting Periods] [Post]
    end;

    var
        Assert: Codeunit Assert;
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        DuplicateRecordErr: Label 'Document No. %1 already exists. It is not possible to calculate new deferrals for a Document No. that already exists.', Comment = '%1=Document No.';
        SourceCurrAmtErr: Label '%1 must be %2 in %3', Comment = '%1 = Source Currency Amount, %2 = Amount, %3 = G/L Entry';

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] 'Prior-Year Entry' is false on posting of Gen. Journal Line
        Initialize();
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst();
        GLEntry.TestField("Prior-Year Entry", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] Posting of purchase document is available
        Initialize();
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GLEntry.SetRange("Source No.", PurchaseHeader."Buy-from Vendor No.");
        GLEntry.SetRange("Posting Date", PurchaseHeader."Posting Date");
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] Posting of sales document is available
        Initialize();
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
          LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        GLEntry.SetRange("Source No.", SalesHeader."Sell-to Customer No.");
        GLEntry.SetRange("Posting Date", SalesHeader."Posting Date");
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceDocument()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222561] Posting of service document is available
        Initialize();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        GLEntry.SetRange("Source No.", ServiceHeader."Customer No.");
        GLEntry.SetRange("Posting Date", ServiceHeader."Posting Date");
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure DepreciationOfFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StartingDate: Date;
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 222561] Post acquision and depreciation of foxed asset without accounting periods
        Initialize();

        // [GIVEN] Fixed Asset with acquisition and appreciation at the beginnig of month
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        StartingDate := CalcDate('<-CM>', WorkDate());
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateFADepreciationBook(FADepreciationBook, GenJournalBatch, FixedAsset."No.", FixedAsset."FA Posting Group", StartingDate);
        CreateFAGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDecInRange(1000, 2000, 2), StartingDate);
        CreateFAGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::Appreciation,
          LibraryRandom.RandDecInRange(1000, 2000, 2), StartingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FADepreciationBook.CalcFields("Book Value");

        // [WHEN] Run Calculate Depreciation at the end of month
        RunCalculateDepreciation(FixedAsset."No.", FADepreciationBook."Depreciation Book Code", CalcDate('<CM>', WorkDate()));

        // [THEN] Depreciation amount is calculated for one month
        // cod134027.DepreciationAmountWithAppreciationEntry
        VerifyDepreciationAmount(
          FixedAsset."No.", -1 * Round(FADepreciationBook."Book Value" / (FADepreciationBook."No. of Depreciation Years" * 12), 1));
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralsGenJournalPostingEqualsPerPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Deferrals] [General Journal]
        // [SCENARIO 222561] Post general journal line with 'equal per period' deferral
        Initialize();

        // [GIVEN] General Journal Line with 'equal per period' Deferral Template
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountWithEqualPerPeriodDeferral(), LibraryRandom.RandDec(1000, 2));

        // [WHEN] Post General Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries created for deferral account for each period
        VerifyDeferralPosting(GenJournalLine."Deferral Code", GenJournalLine."Posting Date", -GenJournalLine."VAT Base Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralsPurchaseInvoiceStraightLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Deferrals] [Purchase]
        // [SCENARIO 222561] Post purchase document with 'straight line' deferral
        Initialize();

        // [GIVEN] Purchase Invoice with 'straight line' Deferral Template
        CreatePurchaseInvoiceWithDeferral(
          PurchaseHeader, PurchaseLine, CreateGLAccountWithStraightLineDeferral(), LibraryRandom.RandDateFrom(CalcDate('<-CM>', WorkDate()), 10));

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entries created for deferral account for each period
        VerifyDeferralPosting(PurchaseLine."Deferral Code", PurchaseHeader."Posting Date", -PurchaseHeader.Amount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralsPurchaseInvoiceDaysPerPeriod()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Deferrals] [Purchase]
        // [SCENARIO 222561] Post purchase document with 'days per period' deferral
        Initialize();

        // [GIVEN] Purchase Invoice with 'days per period' Deferral Template
        CreatePurchaseInvoiceWithDeferral(
          PurchaseHeader, PurchaseLine, CreateGLAccountWithDaysPerPeriodDeferral(), LibraryRandom.RandDateFrom(CalcDate('<-CM>', WorkDate()), 10));

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entries created for deferral account for each period
        VerifyDeferralPosting(PurchaseLine."Deferral Code", CalcDate('<-CM>', PurchaseHeader."Posting Date"), -PurchaseHeader.Amount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralsSalesInvoiceStraightLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Deferrals] [Sales]
        // [SCENARIO 222561] Post sales document with 'straight line' deferral
        Initialize();

        // [GIVEN] Sales Invoice with 'straight line' Deferral Template
        CreateSalesInvoiceWithDeferral(
          SalesHeader, SalesLine, CreateGLAccountWithStraightLineDeferral(), LibraryRandom.RandDateFrom(CalcDate('<-CM>', WorkDate()), 10));

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries created for deferral account for each period
        VerifyDeferralPosting(SalesLine."Deferral Code", SalesHeader."Posting Date", SalesHeader.Amount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralsSalesInvoiceDaysPerPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Deferrals] [Sales]
        // [SCENARIO 222561] Post sales document with 'days per period' deferral
        Initialize();

        // [GIVEN] Sales Invoice with 'days per period' Deferral Template
        CreateSalesInvoiceWithDeferral(
          SalesHeader, SalesLine, CreateGLAccountWithDaysPerPeriodDeferral(), LibraryRandom.RandDateFrom(CalcDate('<-CM>', WorkDate()), 10));

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries created for deferral account for each period
        VerifyDeferralPosting(SalesLine."Deferral Code", CalcDate('<-CM>', SalesHeader."Posting Date"), SalesLine.Amount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgCostAdjustedWithAccPeriodMethodNoPeriods()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        InventorySetup: Record "Inventory Setup";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        UnitCost: Decimal;
    begin
        // [FEATURE] [Adjust Cost - Item Entries]
        // [SCENARIO 273515] Cost is adjusted for an item with "Average" costing method when no accounting period exists and "Average Cost Period" is set to "Accounting Period"
        Initialize();

        // [GIVEN] "Inventory Setup" is updated: "Average Cost Period" is set to "Accounting Period"
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::"Accounting Period");

        // [GIVEN] Item with "Average" costing method
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // [GIVEN] Purchase 50 pcs of the item for 10 EUR per piece on 15.01.2020 and sell the stock. Both entries posted on 15.01.2020
        UnitCost := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(50, 100));
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(50));
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Item is valued at the end of the month ("Valuation Date" is 31.01.2020), cost amount on the outbound entry is updated to 10 EUR
        VerifyAvgCostAdjmtEntryPoint(Item."No.", AccountingPeriodMgt.GetDefaultPeriodEndingDate(WorkDate()));
        VerifyItemLedgEntryCostAmount(Item."No.", -UnitCost * ItemJournalLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreviewPostGenJournalWithDeferralTemplateWithError()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 470572] Not possible to post a Deferral when the Document No exist, an error message occurs when trying to post, 
        // however, this error message does not appear when doing the Preview Posting.
        Initialize();

        // [GIVEN] Create G/L Account with Deferral template code
        GLAccountNo := CreateGLAccountWithStraightLineDeferral();

        // [GIVEN] Create Gen. Journal Batch
        CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create Gen. Journal Line 
        CreateGenJournalLineForDeferralEntry(GenJournalLine, GenJournalBatch, GLAccountNo);

        // [WHEN] Save Document no. when Gen. Journal Line has Document No.
        DocumentNo := GenJournalLine."Document No.";

        // [THEN] Post Gen. Journal Line 
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create Gen. Journal Line with same Document  No. 
        CreateGenJournalLineForDeferralEntry(GenJournalLine, GenJournalBatch, GLAccountNo);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);

        // [VERIFY] Verify Error will come during Posting Preview.
        asserterror GenJnlPost.Preview(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySameDocumentNoErrWithDeferralTemplate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalBatch1: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine1: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 470170] When posting Deferrals for a Document No that already exist the error message is not intuitive to the user
        Initialize();

        // [GIVEN] Create G/L Account with Deferral template code
        GLAccountNo := CreateGLAccountWithStraightLineDeferral();

        // [GIVEN] Create Gen. Journal Batch
        CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create Gen. Journal Line 
        CreateGenJournalLineForDeferralEntry(GenJournalLine, GenJournalBatch, GLAccountNo);

        // [WHEN] Save Document no. when Gen. Journal Line has Document No.
        DocumentNo := GenJournalLine."Document No.";

        // [THEN] Post Gen. Journal Line 
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create Gen. Journal Line with same Document  No.
        CreateGenJournalBatch(GenJournalBatch1);

        // [GIVEN] Create Gen. Journal Batch
        CreateGenJournalLineForDeferralEntry(GenJournalLine1, GenJournalBatch1, GLAccountNo);

        // [GIVEN] Update the same Document No. and Line No.
        GenJournalLine1.Validate("Document No.", DocumentNo);
        GenJournalLine1."Line No." := GenJournalLine."Line No.";
        GenJournalLine1.Modify(true);

        // [WHEN] Expected Error will come during Posting Preview.
        asserterror GenJnlPostLine.RunWithCheck(GenJournalLine1);

        // [VERIFY] Verify the error message will be Duplicate Record Error
        Assert.ExpectedError(StrSubstNo(DuplicateRecordErr, DocumentNo));
    end;

    [Test]
    procedure VerifySourceCurrencyAmountWithDeferralCode()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        CurrencyCode: Code[10];
        GLAccountNo: Code[20];
        CurrencyStartingDate: Date;
    begin
        // [SCENARIO 563229] Verify Source Currency Amount on Posting of PurchaseInvoice using Deferral Code.
        Initialize();

        // [GIVEN] Create Currency with Currency Exchange Rate with Exchange Rate Amount,Adjustment Rate Amount,
        //Relational Exch. Rate Amount and Relational Ajmt Exch Rate Amt.
        CurrencyStartingDate := CalcDate('<-1D>', WorkDate());
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(CurrencyStartingDate, 1.0, 1.0);
        CurrencyExchangeRate.Get(CurrencyCode, CurrencyStartingDate);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 11.472);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 114.472);
        CurrencyExchangeRate.Modify(true);

        // [GIVEN] Create Deferral Template with "Calc. Method" = "Equal per Period" and "Period No." = 12.
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period",
          DeferralTemplate."Start Date"::"Beginning of Next Period", 12);

        // [GIVEN] Create G/L Account with Purchase Setup.
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();

        // [GIVEN] Create Purchase Invoice with Currency Code and Deferral Codeand Direct Unit cost as 4435.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendor(Vendor));
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        PurchaseLine.Validate("Direct Unit Cost", 4435);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice with Deferral.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Source Currency Amount of G/L Entries for Deferral Account.
        VerifyDeferralPostingSourceCurrencyAmount(PurchaseLine."Deferral Code", CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure Initialize()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"No Acc. Periods: Posting");
        AccountingPeriod.DeleteAll();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"No Acc. Periods: Posting");
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"No Acc. Periods: Posting");
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; GenJournalBatch: Record "Gen. Journal Batch"; FixedAssetNo: Code[20]; FAPostingGroup: Code[20]; StartingDate: Date)
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Appreciation", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", true);
        DepreciationBook.Modify(true);

        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAssetNo, DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Validate("Depreciation Starting Date", StartingDate);
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandDecInRange(2, 5, 2));
        FADepreciationBook.Modify(true);

        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        FAJournalSetup.Validate("Gen. Jnl. Template Name", GenJournalBatch."Journal Template Name");
        FAJournalSetup.Validate("Gen. Jnl. Batch Name", GenJournalBatch.Name);
        FAJournalSetup.Modify(true);
    end;

    local procedure CreateFAGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FADepreciationBook: Record "FA Depreciation Book"; GenJournalBatch: Record "Gen. Journal Batch"; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; Amount: Decimal; PostingDate: Date)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FADepreciationBook."FA No.", Amount);
        GenJournalLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Document No.", FADepreciationBook."FA No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateGLAccountWithStraightLineDeferral(): Code[20]
    var
        GLAccount: Record "G/L Account";
        DeferralTemplate: Record "Deferral Template";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate(
          "Default Deferral Template Code",
          CreateDeferralTemplate(
            DeferralTemplate."Calc. Method"::"Straight-Line",
            DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(2, 5), LibraryUtility.GenerateGUID(), 100));
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateGLAccountWithEqualPerPeriodDeferral(): Code[20]
    var
        GLAccount: Record "G/L Account";
        DeferralTemplate: Record "Deferral Template";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate(
          "Default Deferral Template Code",
          CreateDeferralTemplate(
            DeferralTemplate."Calc. Method"::"Equal per Period",
            DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(2, 5), LibraryUtility.GenerateGUID(), 100));
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateGLAccountWithDaysPerPeriodDeferral(): Code[20]
    var
        GLAccount: Record "G/L Account";
        DeferralTemplate: Record "Deferral Template";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate(
          "Default Deferral Template Code",
          CreateDeferralTemplate(
            DeferralTemplate."Calc. Method"::"Days per Period",
            DeferralTemplate."Start Date"::"Beginning of Period", LibraryRandom.RandIntInRange(2, 5), LibraryUtility.GenerateGUID(), 100));
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateDeferralTemplate(CalcMethod: Enum "Deferral Calculation Method"; StartDate: Enum "Deferral Calculation Start Date"; NumOfPeriods: Integer; PeriodDescription: Text[50]; DeferralPct: Decimal): Code[10]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        LibraryERM.CreateDeferralTemplate(DeferralTemplate, CalcMethod, StartDate, NumOfPeriods);
        DeferralTemplate.Validate("Period Description", PeriodDescription);
        DeferralTemplate.Validate("Deferral %", DeferralPct);
        DeferralTemplate.Modify(true);
        exit(DeferralTemplate."Deferral Code");
    end;

    local procedure CreateSalesInvoiceWithDeferral(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; AccountNo: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", AccountNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        SalesHeader.CalcFields(Amount);
    end;

    local procedure CreatePurchaseInvoiceWithDeferral(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; AccountNo: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", AccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        PurchaseHeader.CalcFields(Amount);
    end;

    local procedure RunCalculateDepreciation(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; EndingDate: Date)
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", FixedAssetNo);
        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, EndingDate, false, 0, EndingDate, FixedAssetNo, FixedAsset.Description, false);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure VerifyAvgCostAdjmtEntryPoint(ItemNo: Code[20]; ValuationDate: Date)
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.SetRange("Item No.", ItemNo);
        AvgCostAdjmtEntryPoint.SetRange("Valuation Date", ValuationDate);
        AvgCostAdjmtEntryPoint.FindFirst();
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);
    end;

    local procedure VerifyDeferralPosting(DeferralTemplateCode: Code[10]; FirstEntryPostingDate: Date; AmountToDefer: Decimal; AdditionalRecord: Integer)
    var
        DeferralTemplate: Record "Deferral Template";
        GLEntry: Record "G/L Entry";
        PostingDate: Date;
    begin
        DeferralTemplate.Get(DeferralTemplateCode);
        GLEntry.SetRange("G/L Account No.", DeferralTemplate."Deferral Account");
        Assert.RecordCount(GLEntry, DeferralTemplate."No. of Periods" + 1 + AdditionalRecord);
        GLEntry.SetRange(Description, DeferralTemplate."Period Description");
        PostingDate := FirstEntryPostingDate;
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Posting Date", PostingDate);
            PostingDate := CalcDate('<-CM + 1M>', PostingDate);
        until GLEntry.Next() = 0;
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, AmountToDefer);
    end;

    local procedure VerifyDepreciationAmount(AccountNo: Code[20]; DepreciationAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"Fixed Asset");
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField(Amount, DepreciationAmount);
    end;

    local procedure VerifyItemLedgEntryCostAmount(ItemNo: Code[20]; CostAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmount);
    end;

    local procedure CreateGenJournalLineForDeferralEntry(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GLAccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure VerifyDeferralPostingSourceCurrencyAmount(DeferralTemplateCode: Code[10]; ExchnageRate: Decimal)
    var
        DeferralTemplate: Record "Deferral Template";
        GLEntry: Record "G/L Entry";
        ExpectedAmount: Decimal;
    begin
        DeferralTemplate.Get(DeferralTemplateCode);
        GLEntry.SetRange("G/L Account No.", DeferralTemplate."Deferral Account");
        GLEntry.SetRange(Description, DeferralTemplate."Period Description");
        GLEntry.FindSet();
        repeat
            ExpectedAmount := Round(GLEntry.Amount / ExchnageRate, 0.01);
            Assert.AreEqual(
                ExpectedAmount,
                GLEntry."Source Currency Amount",
                StrSubstNo(
                    SourceCurrAmtErr,
                    GLEntry.FieldCaption("Source Currency Amount"),
                    ExpectedAmount,
                    GLEntry.TableCaption()));
        until GLEntry.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

