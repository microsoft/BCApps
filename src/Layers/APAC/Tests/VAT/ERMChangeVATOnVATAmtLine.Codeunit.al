codeunit 134028 "ERM Change VAT On VAT Amt Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Difference]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        IsInitialized: Boolean;
        ErrorWithCurrency: Label '%1 for %2 must not exceed %3 = %4.', Comment = '%1=Field Caption;%2=Field Value;%3=Field Caption;%4=Field Value;';
        ErrorWithoutCurrency: Label '%1 must not exceed %2 = %3.', Comment = '%1=Field Caption;%2=Field Caption;%3=Field Value;';
        DefaultVATAmountLineTxt: Label 'VAT Amount';
        PercentVATAmountTxt: Label '%1% VAT';
        VATDiffErr: Label 'VAT Difference doesn''t match';

    [Test]
    [Scope('OnPrem')]
    procedure TestPositiveManlVATOnSalesOrd()
    begin
        // Covers documents TFS_TC_ID=11190, TFS_TC_ID=11191, TFS_TC_ID=11193, TFS_TC_ID=11194.
        UpdateVATLineOnSalesOrder(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNegativeManlVATOnSalesOrd()
    begin
        // Covers documents TFS_TC_ID=11190, TFS_TC_ID=11191, TFS_TC_ID=11193, TFS_TC_ID=11194.
        UpdateVATLineOnSalesOrder(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPositiveManlVATOnPurchOrd()
    begin
        // Covers documents TFS_TC_ID=11190, TFS_TC_ID=11192, TFS_TC_ID=11193, TFS_TC_ID=11194.
        UpdateVATLineOnPurchaseOrder(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNegativeManlVATOnPurchOrd()
    begin
        // Covers documents TFS_TC_ID=11190, TFS_TC_ID=11192, TFS_TC_ID=11193, TFS_TC_ID=11194.
        UpdateVATLineOnPurchaseOrder(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestManlVATOnSalesOrdWithFCY()
    begin
        // Covers documents TFS_TC_ID=11190, TFS_TC_ID=11191, TFS_TC_ID=11193, TFS_TC_ID=11194.
        UpdateVATLineOnSalesOrder(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestManlVATOnPurchOrdWithFCY()
    begin
        // Covers documents TFS_TC_ID=11190, TFS_TC_ID=11192, TFS_TC_ID=11193, TFS_TC_ID=11194.
        UpdateVATLineOnPurchaseOrder(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountWithVATDiffForSales()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        MaxVATDiffAmt: Decimal;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Verify program allow to changing the VAT Amount when Allow VAT Difference = Yes on the Sales & Receivables Setup.

        // Setup: Update General Ledger Setup and Sales & Receivables Setup for VAT Difference.
        Initialize();
        MaxVATDiffAmt := EnableVATDiffAmount(true);

        // Create Sales Order and update the VAT Difference on Sales Line.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, MaxVATDiffAmt);

        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        SalesLine.CalcVATAmountLines(QtyType::Invoicing, SalesHeader, SalesLine, VATAmountLine);

        // Exercise: Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify G/L Entry for changed VAT Amount.
        VerifyGLEntry(VATPostingSetup."Sales VAT Account", SalesHeader."Last Posting No.", -VATAmountLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountWithVATDiffForPurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        MaxVATDiffAmt: Decimal;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Verify program allow to changing the VAT Amount when Allow VAT Difference = Yes on the Purchase & Payables Setup.

        // Setup: Update General Ledger Setup and Purchase & Payables Setup for VAT Difference.
        Initialize();
        MaxVATDiffAmt := EnableVATDiffAmount(false);

        // Create Purchase Order and update the VAT Difference on Purchase Line.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, MaxVATDiffAmt);

        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);
        UpdateGeneralPostingSetupWithDirectCostAppliedAccount(
          PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // Exercise: Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify G/L Entry for changed VAT Amount.
        VerifyGLEntry(VATPostingSetup."Purchase VAT Account", PurchaseHeader."Last Posting No.", VATAmountLine."VAT Amount");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure StatisticsInvoicingTabVATAmountUpdatesGeneralTabForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        MaxVATDiffAmt: Decimal;
    begin
        // [FEATURE] [Statistics] [Sales]
        // [SCENARIO] Statistics VAT Amount changes in Invoicing tab are also updates General tab for Sales Order.

        // [GIVEN] General Ledger Setup and Sales & Receivables Setup for VAT Difference = 0.05
        Initialize();
        MaxVATDiffAmt := EnableVATDiffAmount(true);
        LibraryVariableStorage.Enqueue(MaxVATDiffAmt);

        // [GIVEN] Sales Order with VAT Amount = 10
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 0);

        // [GIVEN] Open "Sales Order Statistics" and drilldown "No. of VAT Lines" from Invoicing tab
        // [WHEN] Change "VAT Amount" to 10.02 and close "VAT Amount Lines" page
        PAGE.RunModal(PAGE::"Sales Order Statistics", SalesHeader);

        // [THEN] Sales Order Statistics General tab "VAT Amount" = 10.02
        // Verify is done in  SalesOrderStatisticsHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure StatisticsInvoicingTabVATAmountUpdatesGeneralTabForPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        MaxVATDiffAmt: Decimal;
    begin
        // [FEATURE] [Statistics] [Purchase]
        // [SCENARIO] Statistics VAT Amount changes in Invoicing tab are also updates General tab for Purchase Order

        // [GIVEN] General Ledger Setup and Purchases & Payables Setup for VAT Difference = 0.05
        Initialize();
        MaxVATDiffAmt := EnableVATDiffAmount(false);
        LibraryVariableStorage.Enqueue(MaxVATDiffAmt);

        // [GIVEN] Purchase Order with VAT Amount = 10
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, 0);

        // [GIVEN] Open "Purchase Order Statistics" and drilldown "No. of VAT Lines" from Invoicing tab
        // [WHEN] Change "VAT Amount" to 10.02 and close "VAT Amount Lines" page
        PAGE.RunModal(PAGE::"Purchase Order Statistics", PurchaseHeader);

        // [THEN] Purchase Order Statistics General tab "VAT Amount" = 10.02
        // Verify is done in  PurchaseOrderStatisticsHandler
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure StatisticsVATAmountLineUpdatesGeneralTabForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        MaxVATDiffAmt: Decimal;
    begin
        // [FEATURE] [Statistics] [Sales]
        // [SCENARIO 377509] Statistics VAT Amount changes in VAT Amount Lines tab are also updates General tab for Sales Invoice.

        // [GIVEN] General Ledger Setup and Sales & Receivables Setup for VAT Difference = 0.05
        Initialize();
        MaxVATDiffAmt := EnableVATDiffAmount(true);
        LibraryVariableStorage.Enqueue(MaxVATDiffAmt);

        // [GIVEN] Sales Order with VAT Amount = 10
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, 0);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        // [GIVEN] Open "Sales Statistics"
        // [WHEN] Change "VAT Amount" to 10.02 on "VAT Amount Lines" tab and Refresh the page
        PAGE.RunModal(PAGE::"Sales Statistics", SalesHeader);

        // [THEN] Sales Invoice Statistics General tab "VAT Amount" = 10.02
        // Verify is done in  SalesStatisticsHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsHandler')]
    [Scope('OnPrem')]
    procedure StatisticsVATAmountLineUpdatesGeneralTabForPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        MaxVATDiffAmt: Decimal;
    begin
        // [FEATURE] [Statistics] [Purchase]
        // [SCENARIO 377509] Statistics VAT Amount changes in VAT Amount Lines tab are also updates General tab for Sales Invoice.

        // [GIVEN] General Ledger Setup and Purchases & Payables Setup for VAT Difference = 0.05
        Initialize();
        MaxVATDiffAmt := EnableVATDiffAmount(false);
        LibraryVariableStorage.Enqueue(MaxVATDiffAmt);

        // [GIVEN] Purchase Order with VAT Amount = 10
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, 0);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // [GIVEN] Open "Purchase Statistics"
        // [WHEN] Change "VAT Amount" to 10.02 on "VAT Amount Lines" tab and Refresh the page
        PAGE.RunModal(PAGE::"Purchase Statistics", PurchaseHeader);

        // [THEN] Purchase Statistics General tab "VAT Amount" = 10.02
        // Verify is done in  PurchaseStatisticsHandler
    end;

    [Test]
    [HandlerFunctions('ServiceStatisticsHandler')]
    [Scope('OnPrem')]
    procedure StatisticsVATAmountLineUpdatesGeneralTabForServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        MaxVATDiffAmt: Decimal;
    begin
        // [FEATURE] [Statistics] [Service]
        // [SCENARIO 377509] Statistics VAT Amount changes in VAT Amount Lines tab are also updates General tab for Service Invoice.

        // [GIVEN] General Ledger Setup and Sales & Receivables Setup for VAT Difference = 0.05
        Initialize();
        MaxVATDiffAmt := EnableVATDiffAmount(true);
        LibraryVariableStorage.Enqueue(MaxVATDiffAmt);

        // [GIVEN] Service Order with VAT Amount = 10
        CreateServiceInvoice(ServiceHeader);
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");

        // [GIVEN] Open "Service Statistics"
        // [WHEN] Change "VAT Amount" to 10.02 on "VAT Amount Lines" tab and Refresh the page
        PAGE.RunModal(PAGE::"Service Statistics", ServiceHeader);

        // [THEN] Service Invoice Statistics General tab "VAT Amount" = 10.02
        // Verify is done in  ServiceStatisticsHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountLineVATAmountTextUT1()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
    begin
        // [FEATURES] [UT]
        // [SCENARIO 281727] VAT Amount Line.VATAmountText() returns "VAT Amount" for 0 VAT Amount Lines
        Initialize();

        // [THEN] For 0 lines VATAmountText returns default text
        Assert.AreEqual(DefaultVATAmountLineTxt, TempVATAmountLine.VATAmountText(), 'VATAmountText returned wrong text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountLineVATAmountTextUT2()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATPercent: Decimal;
    begin
        // [FEATURES] [UT]
        // [SCENARIO 281727] VAT Amount Line.VATAmountText() returns "VAT X%" for 1 VAT Amount Line with "VAT %" <> 0
        Initialize();

        // [GIVEN] A VAT %
        VATPercent := LibraryRandom.RandDec(10, 2);

        // [GIVEN] One VAT Amount Line is added
        CreateVATAmountLine(TempVATAmountLine, LibraryUtility.GenerateGUID(), VATPercent, true);

        // [THEN] For 1 line VATAmountText returns "VAT X%" text
        Assert.AreEqual(StrSubstNo(PercentVATAmountTxt, VATPercent), TempVATAmountLine.VATAmountText(), 'VATAmountText returned wrong text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountLineVATAmountTextUT3()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATPercent: Decimal;
    begin
        // [FEATURES] [UT]
        // [SCENARIO 281727] VAT Amount Line.VATAmountText() returns "VAT X%" for 2 lines with same "VAT %"
        Initialize();

        // [GIVEN] A VAT %
        VATPercent := LibraryRandom.RandDec(10, 2);

        // [GIVEN] 2 VAT Amount Lines were added with same VAT%
        CreateVATAmountLine(TempVATAmountLine, LibraryUtility.GenerateGUID(), VATPercent, true);
        CreateVATAmountLine(TempVATAmountLine, LibraryUtility.GenerateGUID(), VATPercent, false);

        // [THEN] For 2 lines with same "VAT %" VATAmountText returns "VAT X%" text
        Assert.AreEqual(StrSubstNo(PercentVATAmountTxt, VATPercent), TempVATAmountLine.VATAmountText(), 'VATAmountText returned wrong text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountLineVATAmountTextUT4()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATPercent: array[2] of Decimal;
    begin
        // [FEATURES] [UT]
        // [SCENARIO 281727] VAT Amount Line.VATAmountText() returns "VAT Amount" for 2 lines with different "VAT %"
        Initialize();

        // [GIVEN] 2 different VAT %
        VATPercent[1] := LibraryRandom.RandDec(10, 2);
        VATPercent[2] := VATPercent[1] + 1;

        // [GIVEN] 2 VAT Amount Lines were added with same Positive, but different VAT%
        CreateVATAmountLine(TempVATAmountLine, LibraryUtility.GenerateGUID(), VATPercent[1], true);
        CreateVATAmountLine(TempVATAmountLine, LibraryUtility.GenerateGUID(), VATPercent[2], true);

        // [THEN] For 2 lines with different "VAT %" VATAmount returns default text
        Assert.AreEqual(DefaultVATAmountLineTxt, TempVATAmountLine.VATAmountText(), 'VATAmountText returned wrong text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountLineVATAmountTextUT5()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
    begin
        // [FEATURES] [UT]
        // [SCENARIO 281727] VAT Amount Line.VATAmountText() returns "Amount VAT" for 1 VAT Amount Line with VAT % = 0
        Initialize();

        // [GIVEN] One VAT Amount Line is added with 0 VAT
        CreateVATAmountLine(TempVATAmountLine, LibraryUtility.GenerateGUID(), 0, true);

        // [THEN] For 1 line VATAmountText returns "VAT X%" text
        Assert.AreEqual(DefaultVATAmountLineTxt, TempVATAmountLine.VATAmountText(), 'VATAmountText returned wrong text');
    end;

#if not CLEAN26
    [Test]
    [Scope('OnPrem')]
    procedure VATAmountTextOnNonTempVATAmountLine()
    var
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetupNormalVAT: Record "VAT Posting Setup";
        VATPostingSetupReverseChargeVAT: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetupNormalVAT,
          VATPostingSetupNormalVAT."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetupReverseChargeVAT,
          VATPostingSetupNormalVAT."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 20));

        VATAmountLine.Init();
        VATAmountLine.InsertNewLine(VATPostingSetupNormalVAT."VAT Identifier", VATPostingSetupNormalVAT."VAT Calculation Type", '', false, VATPostingSetupNormalVAT."VAT %", true, false, false, 0);
        VATAmountLine.InsertNewLine(VATPostingSetupReverseChargeVAT."VAT Identifier", VATPostingSetupReverseChargeVAT."VAT Calculation Type", '', false, VATPostingSetupReverseChargeVAT."VAT %", true, false, false, 0);

        Assert.ExpectedMessage(DefaultVATAmountLineTxt, VATAmountLine.VATAmountText());
    end;
#endif

    [Test]
    [HandlerFunctions('ServiceStatisticsHandler2')]
    [Scope('OnPrem')]
    procedure VATAmountLineVATdifferenceUpdatedWhenTwoVATLines()
    var
        ServiceHeader: Record "Service Header";
        MaxVATDiffAmt: Decimal;
    begin
        // [SCENARIO 496157] VAT Difference updated correctly when two different VAT Amount Lines on Service Statistics page
        Initialize();

        // [GIVEN] General Ledger Setup and Sales & Receivables Setup for VAT Difference = 0.05
        MaxVATDiffAmt := EnableVATDiffAmount(true);
        LibraryVariableStorage.Enqueue(MaxVATDiffAmt);

        // [GIVEN] Create Service Invoice with two Items and different VAT Prod. Posting Group
        CreateServiceInvoiceWithServiceLines(ServiceHeader);
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");

        // [GIVEN] Open "Service Statistics"
        // [WHEN] Change "VAT Amount" to 10.02 on "VAT Amount Lines" tab and Refresh the page
        PAGE.RunModal(PAGE::"Service Statistics", ServiceHeader);

        // [THEN] Service Invoice Statistics General tab "VAT Amount" = 10.02
        // Verify is done in  ServiceStatisticsHandler VAT Difference updated correctly
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Change VAT On VAT Amt Line");
        // Lazy Setup.
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Change VAT On VAT Amt Line");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Change VAT On VAT Amt Line");
    end;

    local procedure EnableVATDiffAmount(SalesAndReceivables: Boolean) Result: Decimal
    begin
        Result := LibraryRandom.RandDec(2, 2);  // Use any Random decimal value between 0.01 and 1.99, value is not important.
        LibraryERM.SetMaxVATDifferenceAllowed(Result);
        if SalesAndReceivables then
            LibrarySales.SetAllowVATDifference(true)
        else
            LibraryPurchase.SetAllowVATDifference(true);
    end;

    local procedure UpdateVATLineOnSalesOrder(Positive: Boolean; CurrencyFCY: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        MaxVATDiffAmt: Decimal;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // 1. Find VAT Posting Setup to use it in creating Item and Customer.
        // 2. Update General Ledger Setup and Sales and Receivables Setup.
        // 3. Create a new Item and Customer.
        // 4. Create a Sales Order with the newly created Item and Customer.
        // 5. Update Currency Code on Sales Header if CurrencyFCY Boolean is TRUE.

        // Setup: Update General Ledger Setup, Sales and Receivables Setup, Create a Sales Order with a new Customer, Item and with
        // random Quantity between 11 to 20. Generate the data on VAT Amount Line.
        Initialize();
        MaxVATDiffAmt := LibraryRandom.RandDec(2, 2);  // Use any random decimal value between 0.01 and 1.99, value is not important.
        LibraryERM.SetMaxVATDifferenceAllowed(MaxVATDiffAmt);
        LibrarySales.SetAllowVATDifference(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        if CurrencyFCY then begin
            SalesHeader.Validate("Currency Code", CreateCurrencyWithVATDiffAmt(MaxVATDiffAmt));
            SalesHeader.Modify(true);
        end;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 10 + LibraryRandom.RandInt(10));

        // Using base object helper function for generating data on VAT Amount Lines. Use any of the option value for Qty Type field as
        // these represent tabs in Sales Order Statistics Form.
        SalesLine.CalcVATAmountLines(QtyType::Invoicing, SalesHeader, SalesLine, VATAmountLine);

        // Exercise: Update the VAT Amount with an amount greater than Max. VAT Difference Amount on VAT Amount Line.
        UpdateVATAmount(VATAmountLine, LibraryRandom.RandDec(1, 2) + MaxVATDiffAmt, Positive);

        // Verify: Verify the Error Message after updating VAT Amount on VAT Amount Lines.
        VerifyVATAmountDifference(VATAmountLine, SalesHeader."Currency Code");
    end;

    local procedure UpdateVATLineOnPurchaseOrder(Positive: Boolean; CurrencyFCY: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        MaxVATDiffAmt: Decimal;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // 1. Find VAT Posting Setup to use it in Item and Vendor.
        // 2. Update General Ledger Setup and Purchases and Payables Setup.
        // 3. Create a new Item and Vendor.
        // 4. Create a Purchase Order with the newly created Item and Vendor.
        // 5. Update Currency Code on Purchase Header if CurrencyFCY Boolean is TRUE.

        // Setup: Update General Ledger Setup, Purchase and Payables Setup, Create a Purchase Order with a new Vendor, Item and random
        // Quantity between 11 to 20. Generate the data on VAT Amount Line.
        Initialize();
        MaxVATDiffAmt := LibraryRandom.RandDec(2, 2);  // Use any random decimal value between 0.01 and 1.99, value is not important.
        LibraryERM.SetMaxVATDifferenceAllowed(MaxVATDiffAmt);
        LibraryPurchase.SetAllowVATDifference(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        if CurrencyFCY then begin
            PurchaseHeader.Validate("Currency Code", CreateCurrencyWithVATDiffAmt(MaxVATDiffAmt));
            PurchaseHeader.Modify(true);
        end;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), 10 + LibraryRandom.RandInt(10));

        // Using base object helper function for generating data on VAT Amount Lines. Use any of the option value for Qty Type field as
        // these represent tabs in Purchase Order Statistics Form.
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Exercise: Update the VAT Amount with an amount greater than Max. VAT Difference Amount on VAT Amount Line.
        UpdateVATAmount(VATAmountLine, LibraryRandom.RandDec(1, 2) + MaxVATDiffAmt, Positive);

        // Verify: Verify the Error Message after updating VAT Amount on VAT Amount Lines.
        VerifyVATAmountDifference(VATAmountLine, PurchaseHeader."Currency Code");
    end;

    local procedure UpdateGeneralPostingSetupWithDirectCostAppliedAccount(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        if GeneralPostingSetup."Direct Cost Applied Account" = '' then begin
            GeneralPostingSetup."Direct Cost Applied Account" := LibraryERM.CreateGLAccountNo();
            GeneralPostingSetup.Modify();
        end;
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Create an Item with Unit Price. Create Amount between 101 to 200. Value is not important.
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Unit Price", 100 + LibraryRandom.RandInt(100));
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCurrencyWithVATDiffAmt(MaxVATDiffAmt: Decimal): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Create Currency with Exchange Rate.
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Max. VAT Difference Allowed", MaxVATDiffAmt);
        Currency.Modify(true);

        CreateCurrencyExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate());

        // Create random Exchange Rate Amount and Adjustment Exchange Rate Amount between 11 to 100. Value is not important.
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 10 + LibraryRandom.RandInt(90));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Create random Relational Exchange Rate Amount and Relational Adjustment Exchange Rate Amount between 101 to 500.
        // Value is not important.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100 + LibraryRandom.RandInt(400));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; VATIdentifier: Code[20]; VATPercent: Decimal; Positive: Boolean)
    begin
        VATAmountLine.Init();
        VATAmountLine."VAT %" := VATPercent;
        VATAmountLine."VAT Identifier" := VATIdentifier;
        VATAmountLine.Positive := Positive;
        VATAmountLine."VAT Base" := LibraryRandom.RandDec(100, 2);
        VATAmountLine.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // Create Vendor and update General Business Posting Group.
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Create Customer and update VAT Business Posting Group.
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VATDifference: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Use Random Quantity.
        PurchaseLine.Validate("VAT Difference", VATDifference);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; VATDifference: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Use Random Quantity.
        SalesLine.Validate("VAT Difference", VATDifference);
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceInvoice(var ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomer());
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
    end;

    local procedure UpdateVATAmount(var VATAmountLine: Record "VAT Amount Line"; NewVATAmount: Decimal; Positive: Boolean)
    begin
        // Update VAT Amount on VAT Amount Line.
        VATAmountLine.FindFirst();
        if Positive then
            VATAmountLine.Validate("VAT Amount", VATAmountLine."VAT Amount" + NewVATAmount)
        else
            VATAmountLine.Validate("VAT Amount", VATAmountLine."VAT Amount" - NewVATAmount);
        VATAmountLine.Modify(true);
    end;

    local procedure VerifyVATAmountDifference(VATAmountLine: Record "VAT Amount Line"; CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        // Verify the Error Message after updating VAT Amount on VAT Amount Lines.
        GeneralLedgerSetup.Get();

        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode);

        asserterror VATAmountLine.CheckVATDifference(CurrencyCode, true);
        if CurrencyCode <> '' then
            Assert.ExpectedError(
              StrSubstNo(ErrorWithCurrency, VATAmountLine.FieldCaption("VAT Difference"), Currency.Code,
                Currency.FieldCaption("Max. VAT Difference Allowed"), Currency."Max. VAT Difference Allowed"))
        else
            Assert.ExpectedError(
              StrSubstNo(ErrorWithoutCurrency, VATAmountLine.FieldCaption("VAT Difference"),
                Currency.FieldCaption("Max. VAT Difference Allowed"), GeneralLedgerSetup."Max. VAT Difference Allowed"));
    end;

    local procedure VerifyGLEntry(GLAccount: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccount);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure CreateServiceInvoiceWithServiceLines(var ServiceHeader: Record "Service Header")
    var
        Item: array[2] of Record Item;
        ServiceLine: array[2] of Record "Service Line";
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        CreateTwoItemsWithDiffVATProdPostGroup(Item, Customer."VAT Bus. Posting Group");

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        LibraryService.CreateServiceLineWithQuantity(ServiceLine[1], ServiceHeader, ServiceLine[1].Type::Item, Item[1]."No.", LibraryRandom.RandInt(10));
        LibraryService.CreateServiceLineWithQuantity(ServiceLine[2], ServiceHeader, ServiceLine[2].Type::Item, Item[2]."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateTwoItemsWithDiffVATProdPostGroup(var Item: array[2] of Record Item; VATBusPostingGroup: Code[20])
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup);

        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("VAT Prod. Posting Group", VATPostingSetup[1]."VAT Prod. Posting Group");
        Item[1].Validate("Unit Price", 100 + LibraryRandom.RandInt(100));
        Item[1].Validate("Last Direct Cost", Item[1]."Unit Price");
        Item[1].Modify(true);

        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("VAT Prod. Posting Group", VATPostingSetup[2]."VAT Prod. Posting Group");
        Item[2].Validate("Unit Price", 200 + LibraryRandom.RandInt(100));
        Item[2].Validate("Last Direct Cost", Item[2]."Unit Price");
        Item[2].Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; VATBusPostingGroup: Code[20])
    var
        VATProdPostingGroup: array[2] of Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[2]);

        LibraryERM.CreateVATPostingSetup(VATPostingSetup[1], VATBusPostingGroup, VATProdPostingGroup[1].Code);
        VATPostingSetup[1].Validate("VAT Identifier", VATPostingSetup[1]."VAT Prod. Posting Group");
        VATPostingSetup[1].Validate("VAT %", 10);

        VATPostingSetup[1].Modify();

        LibraryERM.CreateVATPostingSetup(VATPostingSetup[2], VATBusPostingGroup, VATProdPostingGroup[2].Code);
        VATPostingSetup[2].Validate("VAT Identifier", VATPostingSetup[2]."VAT Prod. Posting Group");
        VATPostingSetup[2].Validate("VAT %", 20);
        VATPostingSetup[2].Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        SalesOrderStatistics.VATAmount.AssertEquals(SalesOrderStatistics.VATAmount_Invoicing.AsDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesStatistics.SubForm."VAT Amount".SetValue(
          SalesStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal());
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, LibraryVariableStorage.DequeueText());
        SalesStatistics.GotoRecord(SalesHeader); // Refresh
        SalesStatistics.VATAmount.AssertEquals(SalesStatistics.SubForm."VAT Amount".AsDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        PurchaseOrderStatistics."VATAmount[1]".AssertEquals(PurchaseOrderStatistics.VATAmount_Invoicing.AsDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseStatistics.SubForm."VAT Amount".SetValue(
          PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal());
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, LibraryVariableStorage.DequeueText());
        PurchaseStatistics.GotoRecord(PurchaseHeader); // Refresh
        PurchaseStatistics.VATAmount.AssertEquals(PurchaseStatistics.SubForm."VAT Amount".AsDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    begin
        VATAmountLines."VAT Amount".SetValue(
          VATAmountLines."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal());
        VATAmountLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceStatistics.SubForm."VAT Amount".SetValue(
          ServiceStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal());
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, LibraryVariableStorage.DequeueText());
        ServiceStatistics.GotoRecord(ServiceHeader); // Refresh
        ServiceStatistics."VAT Amount_General".AssertEquals(ServiceStatistics.SubForm."VAT Amount".AsDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsHandler2(var ServiceStatistics: TestPage "Service Statistics")
    var
        ServiceHeader: Record "Service Header";
        VATDiff: Decimal;
        VATAmountBefore: Decimal;
        VATAmountAfter: Decimal;
    begin
        VATDiff := LibraryVariableStorage.DequeueDecimal();
        VATAmountBefore := ServiceStatistics.SubForm."VAT Amount".AsDecimal();
        ServiceStatistics.SubForm."VAT Amount".SetValue(ServiceStatistics.SubForm."VAT Amount".AsDecimal() + VATDiff);
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, LibraryVariableStorage.DequeueText());
        ServiceStatistics.GotoRecord(ServiceHeader);
        VATAmountAfter := ServiceStatistics.SubForm."VAT Amount".AsDecimal();
        Assert.AreEqual(VATDiff, VATAmountAfter - VATAmountBefore, VATDiffErr);
    end;
}

