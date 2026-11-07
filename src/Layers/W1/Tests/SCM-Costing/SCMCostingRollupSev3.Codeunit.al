codeunit 137614 "SCM Costing Rollup Sev 3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ValueMismatchErr: Label '%1 in the Revaluation Journal line does not match the Item Ledger Entry applied to.';
        CostMismatchErr: Label 'Incorrect %1 in %2 %3', Comment = '%1=Field Caption,%2=Table Caption,%3=Record Key';
        EntryforJobMismatchErr: Label 'Incorrect no. of %1 records for %2 %3', Comment = '%1=Table Caption,%2=Field Caption,%3=Field Value';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Rollup Sev 3");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Rollup Sev 3");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Rollup Sev 3");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure B256325_PostOutputJournalFromRelProdOrder()
    var
        InventorySetup2: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // Verify Value Entry after post Output Journal which is created from Production Order.

        // Setup.
        Initialize();
        InventorySetup.Get();
        ExecuteUIHandlers();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Create Item.
        ItemNo := CreateAndModifyItem('', Item."Costing Method"::FIFO, Item."Flushing Method"::Backward,
            Item."Replenishment System"::Purchase, 0);

        // Excercise.
        SetupForPostOutputJournal(ProductionOrder, ItemNo);

        // Verify: Verify Value Entry after post Output Journal.
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Consumption, ProductionOrder."No.", ItemNo);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Output, ProductionOrder."No.", ProductionOrder."Source No.");

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure B256325_PostOutputJournalWithAppliesToEntry()
    var
        InventorySetup: Record "Inventory Setup";
        InventorySetup2: Record "Inventory Setup";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // Verify Value Entry and Application Worksheet after post Output Journal with 'Apply to Entry' which is created from Production Order.

        // Setup.
        Initialize();
        InventorySetup.Get();
        ExecuteUIHandlers();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Create Item, Post Purchase Order, create Released Production Order.
        ItemNo := CreateAndModifyItem('', Item."Costing Method"::FIFO,
            Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase, 0);
        SetupForPostOutputJournal(ProductionOrder, ItemNo);

        // Create Output Journal with Applies to Entry and Post.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, ProductionOrder."No.");
        CreateOutputJournal(
          ItemJournalLine, ProductionOrder."Source No.", ProductionOrder."No.", GetOperationNo(ProductionOrder."No."),
          -ProductionOrder.Quantity, ItemLedgerEntry."Entry No.");

        // Excercise.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Item Ledger Entry (Application Worksheet) and Value Entry after post Output Journal.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Consumption, ProductionOrder."No.");
        ItemLedgerEntry.TestField("Item No.", ItemNo);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Consumption, ProductionOrder."No.", ItemNo);

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure B256325_ExpCostAmountInValueEntry()
    var
        InventorySetup2: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        PurchaseLine: Record "Purchase Line";
        PostedReceiptNo: Code[20];
    begin
        // Verify Value Entry after receive Purchase Order.

        // Setup: Update Inventory Setup, create Purchase Order,
        Initialize();
        InventorySetup.Get();
        ExecuteUIHandlers();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order,
          CreateAndModifyItem('', Item."Costing Method"::FIFO, Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase, 0),
          '', CreateVendor(), LibraryRandom.RandInt(10), WorkDate());

        // Exercise
        PostedReceiptNo := PostPurchaseDocument(PurchaseLine, false);

        // Verify: Verify; Value Entry after post Purchase Order.
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Purchase, PostedReceiptNo, PurchaseLine."No.");

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure B256325_GLEntryAfterPostSalesOrder()
    var
        InventorySetup2: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        PostedInvoiceNo: Code[20];
    begin
        // Verify GL Entry after post Salse Order.

        // Setup: Update Inventory Setup, create and post Purchase Order, create Sales Order.
        Initialize();
        InventorySetup.Get();
        ExecuteUIHandlers();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        CreateAndPostPurchaseOrder(
          PurchaseLine,
          CreateAndModifyItem('', Item."Costing Method"::FIFO, Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase, 0),
          LibraryRandom.RandDec(100, 2), 0, false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesLine."Document Type"::Order, SalesLine.Type::Item, PurchaseLine."No.", '',
          LibraryRandom.RandInt(10));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL Entry after post Salse Order.
        VerifyGLEntry(GLEntry."Document Type"::Invoice, PostedInvoiceNo, -SalesLine."Line Amount", GLEntry."Gen. Posting Type"::Sale);
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PostedInvoiceNo, SalesLine."Amount Including VAT", GLEntry."Gen. Posting Type"::" ");

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure B256325_GLEntryAfterPostCreditMemo()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        InventorySetup2: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ReasonCode: Record "Reason Code";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        PostedCreditMemoNo: Code[20];
        PostedInvoiceNo: Code[20];
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        // Verify GL Entry after post Credit Memo.

        // Setup: Update Inventory Setup, create and receive Purchase Order.
        Initialize();
        LibraryERM.CreateReasonCode(ReasonCode);  // Added for G1 Country Fix.
        InventorySetup.Get();
        ExecuteUIHandlers();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        CreateAndPostPurchaseOrder(
          PurchaseLine,
          CreateAndModifyItem('', Item."Costing Method"::FIFO, Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase, 0),
          LibraryRandom.RandDec(100, 2), 0, false);

        // Reopen Purchase Order and update Direct Unit Cost on Purchase Line.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Direct Unit Cost", (PurchaseLine."Direct Unit Cost" + LibraryRandom.RandInt(10)));
        PurchaseLine.Modify(true);

        // Create Sales Order and post.
        CreateSalesDocument(SalesHeader, SalesLine, SalesLine."Document Type"::Order, SalesLine.Type::Item, PurchaseLine."No.", '',
          PurchaseLine.Quantity);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create Sales Credit Memo, Get Posted Invoice to Reverse and Post.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        SalesInvoiceLine.SetRange("Document No.", PostedInvoiceNo);
        SalesInvoiceLine.FindFirst();
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.CopySalesInvLinesToDoc(SalesHeader2, SalesInvoiceLine, LinesNotCopied, MissingExCostRevLink);
        SalesHeader2.Validate("Reason Code", ReasonCode.Code);
        SalesHeader2.Modify(true);
        FindSalesLine(SalesLine, SalesHeader2."Document Type"::"Credit Memo", SalesHeader2."No.");
        PostedCreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Exercise: Post Purhcase received Purchase Order with updated 'Direct Unit Cost'.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry after post Salse Credit Memo.
        VerifyGLEntry(
          GLEntry."Document Type"::"Credit Memo", PostedCreditMemoNo, SalesLine."Line Amount", GLEntry."Gen. Posting Type"::Sale);
        VerifyGLEntry(
          GLEntry."Document Type"::"Credit Memo", PostedCreditMemoNo, -SalesLine."Amount Including VAT", GLEntry."Gen. Posting Type"::" ");

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure B266892_AdjustForDiffCurrExchgRate()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // Verify Value Entries in 'Cost Amount (Expected)(ACY)' of Item Ledger Entry when transactions posted with different Currency Exchange Rates.

        // Setup: Create Currency, add Additional Reporting Currency and update Inventory Setup.
        Initialize();
        InventorySetup.Get();
        ExecuteUIHandlers();
        CreateCurrencyWithExchangeRate(Currency);
        ItemNo := CreateAndModifyItem('', Item."Costing Method"::Average, Item."Flushing Method"::"Pick + Manual",
            Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10));
        SetupForAdjustCostOnACY(SalesHeader, ItemNo, Currency.Code);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify:
        FindValueEntry(ValueEntry, SalesHeader."Last Posting No.", '', '', true, ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.TestField("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.TestField(
          "Cost Amount (Actual) (ACY)",
          Round(ValueEntry."Cost per Unit (ACY)" * ValueEntry."Valued Quantity", LibraryERM.GetAmountRoundingPrecision(), '='));

        // Tear down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        UpdateGeneralLedgerSetupForACY('');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure B266892_PurchOrderWithDiffCurrExchgRate()
    var
        Item: Record Item;
        Currency: Record Currency;
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
        UnitPrice: Decimal;
    begin
        // Verify Value Entries with ACY transactions on different Posting Dates after run Adjust Cost Item batch job.

        // Setup: Create Currency, add Additional Reporting Currency and update Inventory Setup.
        Initialize();
        InventorySetup.Get();
        ExecuteUIHandlers();
        CreateCurrencyWithExchangeRate(Currency);
        ItemNo := CreateAndModifyItem('', Item."Costing Method"::Average, Item."Flushing Method"::"Pick + Manual",
            Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10));
        SetupForAdjustCostOnACY(SalesHeader, ItemNo, Currency.Code);

        // Create Sales Document and Post, create Purchase Document and Receive.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, '', LibraryRandom.RandInt(20));
        UnitPrice := PurchaseLine."Direct Unit Cost" + LibraryRandom.RandInt(20); // Required Unit Price more than Direct Unit Cost.

        UpdateSalesDocument(SalesLine, SalesHeader, SalesHeader."Posting Date", Currency.Code, UnitPrice);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreatePurchaseOrderWithCurrency(
          PurchaseLine, ItemNo, Currency.Code, SalesHeader."Posting Date", LibraryRandom.RandInt(50),
          SalesLine.Quantity + LibraryRandom.RandInt(40));
        PostPurchaseDocument(PurchaseLine, false);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify:
        FindValueEntry(ValueEntry, SalesHeader."Last Posting No.", '', '', true, ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.TestField("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.TestField(
          "Cost Amount (Actual) (ACY)",
          Round(ValueEntry."Cost per Unit (ACY)" * ValueEntry."Valued Quantity", LibraryERM.GetAmountRoundingPrecision(), '='));

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        UpdateGeneralLedgerSetupForACY('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B290899_CostAmountOnItemLedgerEntry()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        PosAdjItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Item Ledger Entry after posting Item Journal Line for Item having costing method Average.
        // Using hardcoded quantity and cost since this was a rounding error
        Initialize();

        // Setup: Create Item and post Positive Adj Item Journal Line.
        Item.Get(
          CreateAndModifyItem('', Item."Costing Method"::Average, Item."Flushing Method"::"Pick + Manual", Item."Replenishment System"::Purchase, 0));
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 2388, WorkDate(), 63.3152);
        PosAdjItemLedgerEntry.SetRange("Item No.", Item."No.");
        PosAdjItemLedgerEntry.FindFirst();

        // Exercise: Post Neg Adj. Item Journal Lines with Fixed Application.
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);

        LibraryInventory.CreateItemJournalLineWithApplication(ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::"Negative Adjmt.", 597, 63.3152, PosAdjItemLedgerEntry."Entry No.");
        LibraryInventory.CreateItemJournalLineWithApplication(ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::"Negative Adjmt.", 597, 63.3152, PosAdjItemLedgerEntry."Entry No.");
        LibraryInventory.CreateItemJournalLineWithApplication(ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::"Negative Adjmt.", 597, 63.3152, PosAdjItemLedgerEntry."Entry No.");
        LibraryInventory.CreateItemJournalLineWithApplication(ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::"Negative Adjmt.", 597, 63.3152, PosAdjItemLedgerEntry."Entry No.");

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // verify: Verify Cost Amount (Actual) on Item Ledger Entry
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure B292993_GLEntriesAfterPostToGL()
    var
        InventorySetup2: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        JobJournalLine: Record "Job Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        // Verify G/L Entries after running Adjust Cost Item Entries and post Inventory to G/L batch job for an Item.

        // Setup: Create and post Job Journal Line and run Adjust Cost Item Entries.
        Initialize();
        InventorySetup.Get();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        CreateAndPostJobJournalLine(JobJournalLine);
        LibraryCosting.AdjustCostItemEntries(JobJournalLine."No.", '');

        // Exercise: Post Inventory to G/L batch job.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Verify Amount on G/L Entries.
        GLEntry.SetRange("Job No.", JobJournalLine."Job No.");
        Assert.AreEqual(2, GLEntry.Count,
          StrSubstNo(EntryforJobMismatchErr, GLEntry.TableCaption(), GLEntry.FieldCaption("Job No."), JobJournalLine."Job No."));

        // Tear down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure B292993_PostInvCostToGLPerEntry()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        InventorySetup2: Record "Inventory Setup";
        JobJournalLine: Record "Job Journal Line";
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
    begin
        // Verify Value Entry after running Post Inventory Cost To G/L batch job using Post Method 'Per Entry'.

        // Setup: Create and post Job Journal Line, create and post Item Journal Line, run Adjust Cost Item Entries.
        Initialize();
        InventorySetup.Get();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        CreateAndPostJobJournalLine(JobJournalLine);
        Item.Get(JobJournalLine."No.");
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '',
          LibraryRandom.RandDec(100, 2), WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryCosting.AdjustCostItemEntries(JobJournalLine."No.", '');

        // Exercise: Post Inventory to G/L batch job.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Verify Value Entry after running Post Inventory Cost To G/L batch job.
        ValueEntry.SetRange("Job No.", JobJournalLine."Job No.");
        Assert.AreEqual(2, ValueEntry.Count,
          StrSubstNo(EntryforJobMismatchErr, ValueEntry.TableCaption(), ValueEntry.FieldCaption("Job No."), JobJournalLine."Job No."));
        ValueEntry.SetRange("Job Task No.", JobJournalLine."Job Task No.");
        Assert.AreEqual(2, ValueEntry.Count,
          StrSubstNo(
            EntryforJobMismatchErr, ValueEntry.TableCaption(), ValueEntry.FieldCaption("Job Task No."), JobJournalLine."Job Task No."));
        GLEntry.SetRange("Job No.", JobJournalLine."Job No.");
        Assert.AreEqual(4, GLEntry.Count,
          StrSubstNo(EntryforJobMismatchErr, GLEntry.TableCaption(), GLEntry.FieldCaption("Job No."), JobJournalLine."Job No."));

        // Tear down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure B296703_FinishedProdOrderWithNewUOM()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        InventorySetup: Record "Inventory Setup";
        InventorySetup2: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
        CostAmount: Decimal;
        QtyPer: Decimal;
        ProdQty: Decimal;
        QtyPerBaseUOM: Decimal;
    begin
        // Setup: Create parent and child Items in a Production BOM and certify it. Update Overhead rate, Unit of measure and Quantity per unit of measure on Parent Item. Create and Post Purchase Order as Receive.
        Initialize();
        InventorySetup.Get();
        ExecuteUIHandlers();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, true, true, InventorySetup2."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        ProdQty := LibraryRandom.RandIntInRange(10, 20);
        QtyPer := LibraryRandom.RandInt(5);
        QtyPerBaseUOM := LibraryRandom.RandIntInRange(2, 10);
        CreateItemsSetup(ParentItem, ChildItem, QtyPer);
        UpdateItemOverheadRate(ParentItem);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, ParentItem."No.", QtyPerBaseUOM);
        CreateAndPostPurchaseOrder(PurchaseLine, ChildItem."No.", ProdQty * QtyPer * QtyPerBaseUOM,
          LibraryRandom.RandDec(100, 2), false);

        // Create and refresh Released Production Order and change Unit of Measure on Production Order Line.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", ProdQty, '', '');
        UpdateProdOrderLineUnitOfMeasureCode(ProdOrderLine, ParentItem."No.", ItemUnitOfMeasure.Code);

        // Open Production Journal and Post.
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ChildItem, '', '', ProdQty * QtyPer * QtyPerBaseUOM, WorkDate(), 0);
        LibraryManufacturing.POSTOutput(ProdOrderLine, ProdQty, WorkDate(), 0);

        // Exercise: Change Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify Value Entries for Finished Production Order With Entry Type Direct Cost and Indirect Cost.
        // Verify the Cost Amount, Cost Per Unit and Invoiced Quantity as Zero.
        ParentItem.Find('=');
        FilterValueEntry(ValueEntry, ProductionOrder."No.", ValueEntry."Item Ledger Entry Type"::Output);

        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.FindFirst();
        VerifyValueEntryQtyAmt(
          ValueEntry, ProductionOrder.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", 0, 0, 0, 0);

        ValueEntry.Next();
        CostAmount := ParentItem."Last Direct Cost" * ItemUnitOfMeasure."Qty. per Unit of Measure" * ProductionOrder.Quantity;
        VerifyValueEntryQtyAmt(
          ValueEntry, 0, CostAmount, ProductionOrder.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
          ParentItem."Last Direct Cost", CostAmount);

        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Indirect Cost");
        ValueEntry.FindFirst();
        CostAmount := ProdOrderLine."Overhead Rate" * ItemUnitOfMeasure."Qty. per Unit of Measure" * ProductionOrder.Quantity;
        VerifyValueEntryQtyAmt(
          ValueEntry, 0, CostAmount, 0, ProdOrderLine."Overhead Rate", CostAmount);

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PS33217()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        InventorySetup: Record "Inventory Setup";
        InventorySetup2: Record "Inventory Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        UnitCost: Decimal;
    begin
        // Using hardcoded quantity and cost since this was a rounding error
        // Setup
        Initialize();
        InventorySetup.Get();
        ExecuteUIHandlers();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup2."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type"::Item,
          InventorySetup."Average Cost Period"::Day);

        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        // Exercise
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::"Positive Adjmt.", 15, 200.5807);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::"Positive Adjmt.", 5, 200.58);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::"Negative Adjmt.", 0.8, 0);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::"Negative Adjmt.", 0.4, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.Find('-');
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(-160.46, ItemLedgerEntry."Cost Amount (Actual)",
          StrSubstNo(CostMismatchErr,
            ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), ItemLedgerEntry.TableCaption(), ItemLedgerEntry."Entry No."));
        ItemLedgerEntry.Next();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(-80.23, ItemLedgerEntry."Cost Amount (Actual)",
          StrSubstNo(CostMismatchErr,
            ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), ItemLedgerEntry.TableCaption(), ItemLedgerEntry."Entry No."));
        Item.Find('=');
        UnitCost := Round(200.58085, LibraryERM.GetUnitAmountRoundingPrecision());
        Item."Unit Cost" := Round(Item."Unit Cost", LibraryERM.GetUnitAmountRoundingPrecision());
        Assert.AreEqual(UnitCost, Item."Unit Cost",
          StrSubstNo(CostMismatchErr, Item.FieldCaption("Unit Cost"), Item.TableCaption(), Item."No."));

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B262357_B319186_DimensionInRevalManual()
    begin
        DimensionInReval(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B262357_B319186_DimensionInRevalCalcInvValue()
    begin
        DimensionInReval(false);
    end;

    local procedure DimensionInReval(ManualRevaluation: Boolean)
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, 0);

        CreateItemJournalLineWithGlobalDim(ItemJournalBatch, ItemJournalLine, Item);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();

        // Exercise: Create a revaluation journal line to apply to the posted purchase
        if ManualRevaluation then begin
            LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
              ItemJournalLine."Entry Type"::Purchase, ItemLedgerEntry.Quantity, 0);
            ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
            ItemJournalLine.Modify(true);
        end else begin
            LibraryInventory.CreateRevaluationJournalLine(ItemJournalBatch, Item, WorkDate(),
              "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ");
            ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
            ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
            ItemJournalLine.SetRange("Applies-to Entry", ItemLedgerEntry."Entry No.");
            ItemJournalLine.FindFirst();
        end;

        // Verify
        Assert.AreEqual(ItemLedgerEntry."Dimension Set ID", ItemJournalLine."Dimension Set ID",
          StrSubstNo(ValueMismatchErr, ItemJournalLine.FieldCaption("Dimension Set ID")));
        Assert.AreEqual(ItemLedgerEntry."Global Dimension 1 Code", ItemJournalLine."Shortcut Dimension 1 Code",
          StrSubstNo(ValueMismatchErr, ItemJournalLine.FieldCaption("Shortcut Dimension 1 Code")));
        Assert.AreEqual(ItemLedgerEntry."Global Dimension 2 Code", ItemJournalLine."Shortcut Dimension 2 Code",
          StrSubstNo(ValueMismatchErr, ItemJournalLine.FieldCaption("Shortcut Dimension 2 Code")));
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; No: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, No, 1);  // Use blank value for Version Code and 1 for Quantity per.
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndModifyItem(VendorNo: Code[20]; CostingMethod: Enum "Costing Method"; FlushingMethod: Enum "Flushing Method"; ReplenishmentSystem: Enum "Replenishment System"; IndCostPercentage: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(10));
        Item.Validate("Unit Cost", LibraryRandom.RandInt(10));
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Validate("Indirect Cost %", IndCostPercentage);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostJobJournalLine(var JobJournalLine: Record "Job Journal Line")
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        Item.Get(CreateAndModifyItem('', Item."Costing Method"::Average, Item."Flushing Method"::"Pick + Manual",
            Item."Replenishment System"::Purchase, 0));
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        JobJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Qty: Decimal; DirectUnitCost: Decimal; Invoice: Boolean): Code[20]
    begin
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, ItemNo, '', CreateVendor(), Qty, WorkDate());
        if DirectUnitCost <> 0 then begin
            PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
            PurchaseLine.Modify(true);
        end;
        exit(PostPurchaseDocument(PurchaseLine, Invoice));
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item; QuantityPer: Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        LibraryInventory.CreateItem(Item2);
        Item2.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item2.Modify(true);

        // Create Production BOM, Parent Item and attach Production BOM.
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; QuantityPer: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(var Currency: Record Currency)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
    end;

    local procedure CreateItemJournalLineWithGlobalDim(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; Item: Record Item)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimVal: Record "Dimension Value";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::Purchase, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        GeneralLedgerSetup.Get();

        DimVal.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        DimVal.SetRange("Dimension Value Type", DimVal."Dimension Value Type"::Standard);
        DimVal.FindFirst();
        ItemJournalLine.Validate("Shortcut Dimension 1 Code", DimVal.Code);

        DimVal.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 2 Code");
        DimVal.SetRange("Dimension Value Type", DimVal."Dimension Value Type"::Standard);
        DimVal.FindFirst();
        ItemJournalLine.Validate("Shortcut Dimension 2 Code", DimVal.Code);

        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; QtyPerUnitOfMeasure: Integer)
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, QtyPerUnitOfMeasure);
    end;

    local procedure CreateOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ProductionOrderNo: Code[20]; OperationNo: Code[10]; OutputQuantity: Decimal; AppliesToEntry: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Output);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; VariantCode: Code[10]; VendorNo: Code[20]; Quantity: Decimal; OrderDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Order Date", OrderDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);

        // Update 'Invt. Accrual Acc. (Interim)' in General Posting Setup.
        LibraryERM.FindGLAccount(GLAccount);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithCurrency(var PurchaseLine: Record "Purchase Line"; No: Code[20]; CurrencyCode: Code[10]; PostingDate: Date; DirectUnitCost: Decimal; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateRoutingSetup(WorkCenterNo: Code[20]; RoutingLinkCode: Code[10]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        ReasonCode: Record "Reason Code";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        if SalesHeader."Document Type" in [SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"]
        then begin
            LibraryERM.CreateReasonCode(ReasonCode);
            SalesHeader.Validate("Reason Code", ReasonCode.Code);
            SalesHeader.Modify();
        end;

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure ExecuteUIHandlers()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        Message('');
        if Confirm('') then;
    end;

    local procedure FindCapacityLedgerEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; OrderNo: Code[20])
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", OrderNo);
        CapacityLedgerEntry.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; OrderNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", OrderNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure FindReleasedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure FindShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; No: Code[20])
    begin
        SalesShipmentLine.SetRange("No.", No);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; DocumentNo: Code[20]; ItemChargeNo: Code[20]; LocationCode: Code[10]; Adjustment: Boolean; ItemLedgerEntryType: Enum "Item Ledger Document Type")
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange(Adjustment, Adjustment);
        ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        ValueEntry.SetRange("Location Code", LocationCode);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
    end;

    local procedure FilterValueEntry(var ValueEntry: Record "Value Entry"; DocumentNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type")
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document No.", DocumentNo);
    end;

    local procedure GetOperationNo(OrderNo: Code[20]): Code[10]
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        FindCapacityLedgerEntry(CapacityLedgerEntry, OrderNo);
        exit(CapacityLedgerEntry."Operation No.");
    end;

    local procedure PostPurchaseDocument(PurchaseLine: Record "Purchase Line"; Invoice: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetupForAdjustCostOnACY(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        UnitPrice: Decimal;
        PosAdjQty: Decimal;
    begin
        // Create Item Journal and Post, create Purchase Order and Receive.
        UpdateGeneralLedgerSetupForACY(CurrencyCode);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, false, InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        Item.Get(ItemNo);
        PosAdjQty := LibraryRandom.RandDec(100, 2);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', LibraryRandom.RandInt(10) + 10, WorkDate(), PosAdjQty);
        CreatePurchaseOrderWithCurrency(
          PurchaseLine, ItemNo, CurrencyCode, CalcDate('<1M + ' + Format(LibraryRandom.RandInt(3)) + 'D>', WorkDate()),
          LibraryRandom.RandInt(50), PosAdjQty + LibraryRandom.RandInt(40));
        // Use random value for Direct Unit Cost.
        PostPurchaseDocument(PurchaseLine, true);

        // Create Sales Order and Ship, Purchase Order Invoiced.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, '', PurchaseLine.Quantity);
        UnitPrice := PurchaseLine."Direct Unit Cost" + LibraryRandom.RandInt(50); // Required Unit Price more than Direct Unti Cost.
        UpdateSalesDocument(
          SalesLine, SalesHeader, CalcDate('<1M + ' + Format(LibraryRandom.RandInt(3)) + 'D>', WorkDate()), CurrencyCode, UnitPrice);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Undo Sale Shipment, update blank Currency in Sales Order and Post.
        UndoSalesShipment(SalesLine);
        UpdateSalesDocument(SalesLine, SalesHeader, CalcDate('<1D>', SalesHeader."Posting Date"), '', UnitPrice);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create Credit Memo without Currency Code and Post.
        CreateSalesDocument(
          SalesHeader2, SalesLine, SalesHeader2."Document Type"::"Credit Memo", SalesLine.Type::Item, ItemNo, '', SalesLine.Quantity);
        UpdateSalesDocument(SalesLine, SalesHeader2, CalcDate('<1D>', SalesHeader."Posting Date"), '', UnitPrice);
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);
    end;

    local procedure SetupForPostOutputJournal(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Create Finished Item.
        Item.Get(CreateAndModifyItem('', Item."Costing Method"::FIFO, Item."Flushing Method"::Backward,
            Item."Replenishment System"::"Prod. Order", 0)); // Finished Item.

        // Update BOM and Routing on Item, create and post two Purchase Order with different 'Unit Cost'.
        UpdateItemWithCertifiedBOMAndRouting(Item, ItemNo);
        CreateAndPostPurchaseOrder(PurchaseLine, ItemNo, LibraryRandom.RandDec(100, 2), 0, true);

        CreatePurchaseDocument(
          PurchaseLine2, PurchaseLine2."Document Type"::Order, PurchaseLine."No.", '', CreateVendor(), LibraryRandom.RandInt(10),
          WorkDate());  // Used Random for Quantity.
        PurchaseLine2.Validate("Direct Unit Cost", (PurchaseLine2."Direct Unit Cost" + LibraryRandom.RandInt(10)));  // 'Direct Unit Cost' required more than previous Purchase Order.
        PurchaseLine2.Modify(true);
        PostPurchaseDocument(PurchaseLine2, true);

        // Create Released Production Order and create Output Journal, Explode Routing and Post.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(10));   // Used Random Int for Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        CreateOutputJournal(ItemJournalLine, Item."No.", ProductionOrder."No.", '', 0, 0);  // 0s are used for 'Output Quantity' and 'Apply to Entry'.
        CODEUNIT.Run(CODEUNIT::"Output Jnl.-Expl. Route", ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UndoSalesShipment(SalesLine: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        FindShipmentLine(SalesShipmentLine, SalesLine."No.");
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateItemWithCertifiedBOMAndRouting(var Item: Record Item; ItemNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
    begin
        RoutingLink.FindFirst();
        WorkCenter.FindFirst();

        // Create Production BOM with Raouting Link Code.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."Base Unit of Measure", ItemNo, RoutingLink.Code);

        // Update Item with Prodouction BOM No. and Routing No.
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Routing No.", CreateRoutingSetup(WorkCenter."No.", RoutingLink.Code));
        Item.Modify(true);
    end;

    local procedure UpdateItemOverheadRate(var Item: Record Item)
    begin
        Item.Validate("Overhead Rate", LibraryRandom.RandInt(5));
        Item.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetupForACY(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateProdOrderLineUnitOfMeasureCode(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateSalesDocument(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; PostingDate: Date; CurrencyCode: Code[10]; UnitPrice: Decimal)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; GenPostingType: Enum "General Posting Type")
    var
        GLEntry: Record "G/L Entry";
        ActualAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.FindSet();
        repeat
            ActualAmount := GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(Amount, ActualAmount, LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount in GL entry.');
    end;

    local procedure VerifyValueEntry(ItemLedgerEntryType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, DocumentNo, '', '', false, ItemLedgerEntryType);
        ValueEntry.TestField("Item No.", ItemNo);
    end;

    local procedure VerifyValueEntryQtyAmt(var ValueEntry: Record "Value Entry"; ItemLedgerEntryQuantity: Decimal; CostPostedToGL: Decimal; InvoicedQuantity: Decimal; CostPerUnit: Decimal; CostAmountActual: Decimal)
    begin
        ValueEntry.TestField("Item Ledger Entry Quantity", ItemLedgerEntryQuantity);
        ValueEntry.TestField("Cost Posted to G/L", CostPostedToGL);
        ValueEntry.TestField("Invoiced Quantity", InvoicedQuantity);
        ValueEntry.TestField("Cost per Unit", CostPerUnit);
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

