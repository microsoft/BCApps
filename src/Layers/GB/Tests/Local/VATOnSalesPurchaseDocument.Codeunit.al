codeunit 144007 "VAT On Sales/Purchase Document"
{
    // Test Cases related to VAT Amount on Statistics for Sales/Purchase Documents:
    // 1. Verify that VAT Amount is edited successfully on Sales Return Order Statistics after partial Receipt and Invoice.
    // 2. Verify that VAT Amount is edited successfully on Sales Order Statistics after partial Shipment and Invoice.
    // 3. Verify that VAT Amount is edited successfully on Purchase Return Order Statistics after partial Shipment and Invoice.
    // 4. Verify that VAT Amount is edited successfully on Purchase Order Statistics after partial Receipt and Invoice.
    // 
    // Covers Test Cases for WI - 340131
    // -------------------------------------------------------------------
    // Test Function Name                                          TFS ID
    // -------------------------------------------------------------------
    // VATAmtOnCrMemoStatsAfterPartialPostSalesRetOrder            207420
    // VATAmtOnInvoiceStatsAfterPartialPostSalesOrder              207421
    // VATAmtOnCrMemoStatsAfterPartialPostPurchRetOrder            207422
    // VATAmtOnInvoiceStatsAfterPartialPostPurchOrder              207423

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
#if not CLEAN27
        LibraryERM: Codeunit "Library - ERM";
#endif
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostSalesRetOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesReturnOrder: TestPage "Sales Return Order";
        SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Sales Return Order Statistics after partial Receipt and Invoice.

        // Setup: Create and partially post Sales Return Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Quantity, Quantity / 2, 0);  // Zero for Quantity to Ship.

        // Open Sales Return Order Statistics Page from Sales Return Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.Statistics.Invoke();  // Invoking Statistics.
        SalesReturnOrder.OK().Invoke();

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify changed VAT Amount on Sales Credit Memo Statistics Page.
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCreditMemoStatistics.OpenEdit();
        SalesCreditMemoStatistics.GotoRecord(SalesCrMemoHeader);
        SalesCreditMemoStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesCreditMemoStatistics.OK().Invoke();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrder: TestPage "Sales Order";
        SalesInvoiceStatistics: TestPage "Sales Invoice Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Sales Order Statistics after partial Shipment and Invoice.

        // Setup: Create and partially post Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Quantity, 0, Quantity / 2);  // Zero for Return Quantity to Receive.

        // Open Sales Order Statistics Page from Sales Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Statistics.Invoke();
        SalesOrder.OK().Invoke();

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify changed VAT Amount on Sales Invoice Statistics Page.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceStatistics.OpenEdit();
        SalesInvoiceStatistics.GotoRecord(SalesInvoiceHeader);
        SalesInvoiceStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesInvoiceStatistics.OK().Invoke();
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostSalesRetOrderNM()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesReturnOrder: TestPage "Sales Return Order";
        SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Sales Return Order Statistics after partial Receipt and Invoice.

        // Setup: Create and partially post Sales Return Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Quantity, Quantity / 2, 0);  // Zero for Quantity to Ship.

        // Open Sales Return Order Statistics Page from Sales Return Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.SalesOrderStatistics.Invoke();  // Invoking Statistics.
        SalesReturnOrder.OK().Invoke();

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify changed VAT Amount on Sales Credit Memo Statistics Page.
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCreditMemoStatistics.OpenEdit();
        SalesCreditMemoStatistics.GotoRecord(SalesCrMemoHeader);
        SalesCreditMemoStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesCreditMemoStatistics.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostSalesOrderNM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrder: TestPage "Sales Order";
        SalesInvoiceStatistics: TestPage "Sales Invoice Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Sales Order Statistics after partial Shipment and Invoice.

        // Setup: Create and partially post Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Quantity, 0, Quantity / 2);  // Zero for Return Quantity to Receive.

        // Open Sales Order Statistics Page from Sales Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesOrderStatistics.Invoke();
        SalesOrder.OK().Invoke();

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify changed VAT Amount on Sales Invoice Statistics Page.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceStatistics.OpenEdit();
        SalesInvoiceStatistics.GotoRecord(SalesInvoiceHeader);
        SalesInvoiceStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesInvoiceStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostPurchRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Purchase Return Order Statistics after partial Shipment and Invoice.

        // Setup: Create and partially post Purchase Return Order.
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Return Shpt. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount :=
          CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Quantity, Quantity / 2, 0);  // Zero for Quantity to Receive.

        // Open Purchase Return Order Statistics Page from Purchase Return Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.Statistics.Invoke();  // Invoking Statistics.
        PurchaseReturnOrder.OK().Invoke();

        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify changed VAT Amount on Purchase Credit Memo Statistics Page.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCreditMemoStatistics.OpenEdit();
        PurchCreditMemoStatistics.GotoRecord(PurchCrMemoHdr);
        PurchCreditMemoStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchCreditMemoStatistics.OK().Invoke();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostPurchReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Purchase Return Order Statistics after partial Shipment and Invoice.

        // Setup: Create and partially post Purchase Return Order.
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Return Shpt. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount :=
          CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Quantity, Quantity / 2, 0);  // Zero for Quantity to Receive.

        // Open Purchase Return Order Statistics Page from Purchase Return Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.PurchaseOrderStatistics.Invoke();  // Invoking Statistics.
        PurchaseReturnOrder.OK().Invoke();

        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify changed VAT Amount on Purchase Credit Memo Statistics Page.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCreditMemoStatistics.OpenEdit();
        PurchCreditMemoStatistics.GotoRecord(PurchCrMemoHdr);
        PurchCreditMemoStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchCreditMemoStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Purchase Order Statistics after partial Receipt and Invoice.

        // Setup: Create and partially post Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Quantity, 0, Quantity / 2);  // Zero for Return Quantity to Ship.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // Open Purchase Order Statistics Page from Purchase Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Statistics.Invoke();
        PurchaseOrder.OK().Invoke();

        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify changed VAT Amount on Purchase Invoice Statistics Page.
        PurchInvHeader.Get(DocumentNo);
        PurchaseInvoiceStatistics.OpenEdit();
        PurchaseInvoiceStatistics.GotoRecord(PurchInvHeader);
        PurchaseInvoiceStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchaseInvoiceStatistics.OK().Invoke();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler,VATAmountLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmtOnStatsAfterPartialPostPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        VATAmount: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify that VAT Amount is edited successfully on Purchase Order Statistics after partial Receipt and Invoice.

        // Setup: Create and partially post Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        VATAmount := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Quantity, 0, Quantity / 2);  // Zero for Return Quantity to Ship.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // Open Purchase Order Statistics Page from Purchase Order to change VAT Amount.
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue value for VATAmountLinesPageHandler.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchaseOrderStatistics.Invoke();
        PurchaseOrder.OK().Invoke();

        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify changed VAT Amount on Purchase Invoice Statistics Page.
        PurchInvHeader.Get(DocumentNo);
        PurchaseInvoiceStatistics.OpenEdit();
        PurchaseInvoiceStatistics.GotoRecord(PurchInvHeader);
        PurchaseInvoiceStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchaseInvoiceStatistics.OK().Invoke();
    end;

#if not CLEAN27
    [Test]
    [Scope('OnPrem')]
    procedure AddReverseChargeItemToSalesLine()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] "Reverse Charge Item" is TRUE in Sales Line when set Item with "Reverse Charge Applies" = TRUE
        Initialize();

        // [GIVEN] "Item" with "Reverse Charge Applies"=TRUE
        CreateItemReverseChargeApplies(Item);
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] "Item" is added to "Sales Line" by "No."
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [THEN] "Sales Line"."Reverse charge item"=TRUE
        SalesLine.TestField("Reverse Charge Item", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearReverseChargeItemFromSalesLine()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] "Reverse Charge Item" is FALSE in Sales Line when "No." set to <blank>
        Initialize();

        // [GIVEN] "Item" with "Reverse Charge Applies"=TRUE
        CreateItemReverseChargeApplies(Item);
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] "Item" is added to "Sales Line" by "No." and then removed
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
        SalesLine.Validate("No.", '');

        // [THEN] "Sales Line"."Reverse charge item"=FALSE
        SalesLine.TestField("Reverse Charge Item", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddGLAccountToSalesLine()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] "Reverse Charge Item" is FALSE in Sales Line "Type" <> Item
        Initialize();

        // [GIVEN] "G/L Account"
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        // [WHEN] "G/L Account" is added to "Sales Line" by "No."
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 0);

        // [THEN] "Sales Line"."Reverse charge item"=FALSE
        SalesLine.TestField("Reverse Charge Item", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckInvoiceWithReverseChargeItems()
    var
        Item: Record Item;
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] Reverse Charge VAT Entry created when post Sales Invoice with Reverse Charge Item and amount above threshold amount
        Initialize();

        // [GIVEN] Item "X" with "Reverse Charge Item" option enabled
        CreateItemReverseChargeApplies(Item);
        // [GIVEN] "Threshold Amount" is "N" in General Ledger Setup
        ModifyGLSetupReverseCharge(GLSetup);
        // [GIVEN] VAT Posting Setup with "Reverse Charge VAT" VAT Calculation Type
        CreateVATPostingSetupReverseCharge(Item."VAT Prod. Posting Group", VATPostingSetup);
        // [GIVEN] Customer with "VAT Bus. Posting Group" from VAT Posting Setup
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        // [GIVEN] "Reverse Charge VAT Posting Gr." in Sales Setup from VAT Posting Setup
        ModifySalesSetupReverseCharge(VATPostingSetup."VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        // [GIVEN] Sales Invoice with Item "X" and amount > "N"
        CreateInvoiceWithReverseChargeItem(Item."No.", Customer."No.", GLSetup."Threshold Amount", SalesHeader);

        // [WHEN] Sales Invoice posted
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] VAT Entry created with "Reverse Charge VAT" posting setup
        VerifyVATEntryVATPostingGroupsAndType(VATPostingSetup, InvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddItemToSalesLine()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] "Reverse Charge Item" is FALSE in Sales Line when set Item with "Reverse Charge Applies" = FALSE
        Initialize();

        // [GIVEN] "Item" with "Reverse Charge Applies"=FALSE
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] "Item" is added to "Sales Line" by "No."
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [THEN] "Sales Line"."Reverse charge item"=FALSE
        SalesLine.TestField("Reverse Charge Item", false);
    end;
#endif

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        isInitialized := true;

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Return Receipt on Credit Memo", true);
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal; ReturnQtyToShip: Decimal; QtyToReceive: Decimal) VATAmount: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // Update General Ledger Setup and Purchases Payables Setup for VAT Difference. Create and post Purchase Document.
        UpdateGeneralLedgerSetupForMaxVATDiffAllowed(GeneralLedgerSetup);
        UpdatePurchasesPayablesSetup();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), Quantity);
        PurchaseLine.Validate("Return Qty. to Ship", ReturnQtyToShip);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
        VATAmount :=
          PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %" / 100 +
          LibraryRandom.RandDec(GeneralLedgerSetup."Max. VAT Difference Allowed", 2);  // Increase VAT Amount with Random value.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal; ReturnQtyToReceive: Decimal; QtyToShip: Decimal) VATAmount: Decimal
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Update General Ledger Setup and Sales Receivables Setup for VAT Difference. Create and post Sales Document.
        UpdateGeneralLedgerSetupForMaxVATDiffAllowed(GeneralLedgerSetup);
        UpdateSalesReceivablesSetupForAllowVATDifference();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), Quantity);
        SalesLine.Validate("Return Qty. to Receive", ReturnQtyToReceive);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Price.
        SalesLine.Modify(true);
        VATAmount :=
          SalesLine."Qty. to Invoice" * SalesLine."Unit Price" * SalesLine."VAT %" / 100 +
          LibraryRandom.RandDec(GeneralLedgerSetup."Max. VAT Difference Allowed", 2);  // Increase VAT Amount with Random value.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure UpdateGeneralLedgerSetupForMaxVATDiffAllowed(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", LibraryRandom.RandInt(5));  // Use Random value.
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Allow VAT Difference", true);
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetupForAllowVATDifference()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Allow VAT Difference", true);
        SalesReceivablesSetup.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        PurchaseOrderStatistics.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        PurchaseOrderStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        SalesOrderStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        SalesOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesPageHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        VATAmountLines."VAT Amount".SetValue(VATAmount);
        VATAmountLines.OK().Invoke();
    end;

#if not CLEAN27
    local procedure CreateItemReverseChargeApplies(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reverse Charge Applies", true);
        Item.Modify(true);
    end;

    local procedure CreateInvoiceWithReverseChargeItem(ItemNo: Code[20]; CustomerNo: Code[20]; GLThresholdAmount: Decimal; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));

        SalesLine.Validate("Unit Price", GLThresholdAmount + LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVATPostingSetupReverseCharge(ItemVATProdPostingGroup: Code[20]; var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, ItemVATProdPostingGroup);

        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Modify(true);
    end;

    local procedure ModifySalesSetupReverseCharge(RevChVATBusPostingGroupCode: Code[20]; DomesticVATBusPostingGroupCode: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Reverse Charge VAT Posting Gr.", RevChVATBusPostingGroupCode);
        SalesSetup.Validate("Domestic Customers", DomesticVATBusPostingGroupCode);
        SalesSetup.Modify(true);
    end;

    local procedure ModifyGLSetupReverseCharge(var GLSetup: Record "General Ledger Setup")
    begin
        GLSetup.Get();
        GLSetup.Validate("Threshold applies", true);
        GLSetup.Validate("Threshold Amount", LibraryRandom.RandDec(100, 2));
        GLSetup.Modify(true);
    end;

    local procedure VerifyVATEntryVATPostingGroupsAndType(VATPostingSetup: Record "VAT Posting Setup"; InvoiceNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", InvoiceNo);
        VATEntry.FindFirst();
        VATEntry.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type");
        VATEntry.TestField("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.TestField("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;
#endif
}

