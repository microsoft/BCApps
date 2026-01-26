codeunit 134071 "Test Suppress Commit in Post"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Posting] [Suppress Commit]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOneGenJnlLineCommit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        LastGLEntryNo: Integer;
    begin
        // Setup
        Initialize();
        CreateGenJnlBatch(GenJournalBatch);
        CreateGenJnlLine(GenJournalBatch, GenJournalLine);
        LastGLEntryNo := FindLastGLEntryNo();

        // Exercise
        PostGenJnlBatchWithCommit(GenJournalLine);

        // Verify - After Error
        asserterror Error('');
        Assert.AreNotEqual(LastGLEntryNo, FindLastGLEntryNo(), 'G/L Entry was not committed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOneGenJnlLineNoCommit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        LastGLEntryNo: Integer;
    begin
        // Setup
        Initialize();
        CreateGenJnlBatch(GenJournalBatch);
        CreateGenJnlLine(GenJournalBatch, GenJournalLine);
        LastGLEntryNo := FindLastGLEntryNo();

        // Exercise
        PostGenJnlBatchWithoutCommit(GenJournalLine);

        // Verify - After Error
        asserterror Error('');
        Assert.AreEqual(LastGLEntryNo, FindLastGLEntryNo(), 'G/L Entry was committed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostMultipleGenJnlLineCommit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        LastGLEntryNo: Integer;
    begin
        // Setup
        Initialize();
        CreateGenJnlBatch(GenJournalBatch);
        CreateGenJnlLine(GenJournalBatch, GenJournalLine);
        CreateGenJnlLine(GenJournalBatch, GenJournalLine);
        LastGLEntryNo := FindLastGLEntryNo();

        // Exercise
        PostGenJnlBatchWithCommit(GenJournalLine);

        // Verify - After Error
        asserterror Error('');
        Assert.AreNotEqual(LastGLEntryNo, FindLastGLEntryNo(), 'G/L Entry was not committed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostMultipleGenJnlLineNoCommit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        LastGLEntryNo: Integer;
    begin
        // Setup
        Initialize();
        CreateGenJnlBatch(GenJournalBatch);
        CreateGenJnlLine(GenJournalBatch, GenJournalLine);
        CreateGenJnlLine(GenJournalBatch, GenJournalLine);
        LastGLEntryNo := FindLastGLEntryNo();

        // Exercise
        PostGenJnlBatchWithoutCommit(GenJournalLine);

        // Verify - After Error
        asserterror Error('');
        Assert.AreEqual(LastGLEntryNo, FindLastGLEntryNo(), 'G/L Entry was committed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOneItemJnlLineCommit()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LastItemLedgerEntryNo: Integer;
    begin
        // Setup
        Initialize();
        CreateItemJnlBatch(ItemJournalBatch);
        CreateItemJnlLine(ItemJournalBatch, ItemJournalLine);
        LastItemLedgerEntryNo := FindLastItemLedgerEntryNo();

        // Exercise
        PostItemJnlBatchWithCommit(ItemJournalLine);

        // Verify - After Error
        asserterror Error('');
        Assert.AreNotEqual(LastItemLedgerEntryNo, FindLastItemLedgerEntryNo(), 'G/L Entry was committed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOneItemJnlLineNoCommit()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LastItemLedgerEntryNo: Integer;
    begin
        // Setup
        Initialize();
        CreateItemJnlBatch(ItemJournalBatch);
        CreateItemJnlLine(ItemJournalBatch, ItemJournalLine);
        LastItemLedgerEntryNo := FindLastItemLedgerEntryNo();

        // Exercise
        PostItemJnlBatchWithoutCommit(ItemJournalLine);

        // Verify - After Error
        asserterror Error('');
        Assert.AreEqual(LastItemLedgerEntryNo, FindLastItemLedgerEntryNo(), 'G/L Entry was committed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostMultipleItemJnlLineCommit()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LastItemLedgerEntryNo: Integer;
    begin
        // Setup
        Initialize();
        CreateItemJnlBatch(ItemJournalBatch);
        CreateItemJnlLine(ItemJournalBatch, ItemJournalLine);
        CreateItemJnlLine(ItemJournalBatch, ItemJournalLine);
        LastItemLedgerEntryNo := FindLastItemLedgerEntryNo();

        // Exercise
        PostItemJnlBatchWithCommit(ItemJournalLine);

        // Verify - After Error
        asserterror Error('');
        Assert.AreNotEqual(LastItemLedgerEntryNo, FindLastItemLedgerEntryNo(), 'G/L Entry was committed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostMultipleItemJnlLineNoCommit()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LastItemLedgerEntryNo: Integer;
    begin
        // Setup
        Initialize();
        CreateItemJnlBatch(ItemJournalBatch);
        CreateItemJnlLine(ItemJournalBatch, ItemJournalLine);
        CreateItemJnlLine(ItemJournalBatch, ItemJournalLine);
        LastItemLedgerEntryNo := FindLastItemLedgerEntryNo();

        // Exercise
        PostItemJnlBatchWithoutCommit(ItemJournalLine);

        // Verify - After Error
        asserterror Error('');
        Assert.AreEqual(LastItemLedgerEntryNo, FindLastItemLedgerEntryNo(), 'G/L Entry was committed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesDocumentCommitDateOrder()
    var
        NoSeries: Record "No. Series";
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();
        LibrarySales.CreateSalesInvoice(SalesHeader);

        NoSeries.Get(SalesHeader."Posting No. Series");
        NoSeries."Date Order" := true;
        NoSeries.Modify();
        Commit();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify - After Error
        asserterror Error('');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesDocumentNoCommit()
    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
    begin
        // Setup
        Initialize();
        LibrarySales.CreateSalesInvoice(SalesHeader);
        Commit();

        // Exercise
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);

        // Verify - After Error
        asserterror Error('');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesDocumentPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
    begin
        // Setup
        Initialize();
        LibrarySales.CreateSalesInvoice(SalesHeader);
        Commit();

        // Exercise
        SalesPost.SetPreviewMode(true);
        asserterror SalesPost.Run(SalesHeader);

        // Verify - After Error
        Assert.ExpectedError('Preview mode.');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesDocumentTwice()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
    begin
        // [GIVEN] Two different sales orders
        Initialize();
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader.Modify();

        LibrarySales.CreateSalesOrder(SalesHeader2);
        SalesHeader2.Ship := true;
        SalesHeader2.Invoice := true;
        SalesHeader2.Modify();

        // [WHEN] The same Sales-post is called for 2 different sales orders
        SalesPost.Run(SalesHeader);
        SalesPost.SetPreviewMode(false);
        SalesPost.Run(SalesHeader2);

        // [THEN] The posting succeeds for both meaning the codeunit is cleared up correctly inbetween calls
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPurchaseDocumentTwice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchPost: Codeunit "Purch.-Post";
    begin
        // [GIVEN] Two different purchase orders
        Initialize();
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Receive := true;
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader2);
        PurchaseHeader2.Receive := true;
        PurchaseHeader2.Modify();

        // [WHEN] The same Purch-post is called for 2 different purchase orders
        PurchPost.Run(PurchaseHeader);
        PurchPost.SetPreviewMode(false);
        PurchPost.Run(PurchaseHeader2);

        // [THEN] The posting succeeds for both meaning the codeunit is cleared up correctly inbetween calls
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesPrepaymentInvoiceCommit()
    var
        SalesHeader: Record "Sales Header";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        // Setup
        Initialize();
        CreateSalesOrderForPrePayment(SalesHeader);
        Commit();

        // Exercise
        SalesPostPrepayments.SetSuppressCommit(false);
        SalesPostPrepayments.Invoice(SalesHeader);

        // Verify
        VerifyPrePaymentAmounts(SalesHeader, CalcSalesLinePrepaymentAmount(SalesHeader));

        // Verify - After Error
        asserterror Error('');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField("Prepayment No.");
        SalesHeader.TestField("Last Prepayment No.", '');
        VerifyPrePaymentAmountsError(SalesHeader);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesPrepaymentInvoiceNoCommit()
    var
        SalesHeader: Record "Sales Header";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        // Setup
        Initialize();
        CreateSalesOrderForPrePayment(SalesHeader);
        Commit();

        // Exercise
        SalesPostPrepayments.SetSuppressCommit(true);
        SalesPostPrepayments.Invoice(SalesHeader);

        // Verify
        VerifyPrePaymentAmounts(SalesHeader, CalcSalesLinePrepaymentAmount(SalesHeader));

        // Verify - After Error
        asserterror Error('');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField("Prepayment No.", '');
        SalesHeader.TestField("Last Prepayment No.", '');
        VerifyPrePaymentAmountsError(SalesHeader);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCarryOutReqWkshCommit()
    var
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup
        Initialize();
        CreateSalesOrderWithSpecialOrderAndDropShipment(SalesHeader);
        CreateRequisitionLines(RequisitionLine, SalesHeader);
        Commit();

        // Exercise
        CarryOutActionsOnReqWksheetWithCommit(RequisitionLine);

        // Verify
        VerifySpecialOrderPurchaseOrder(SalesHeader);
        VerifyDropShipmentPurchaseOrder(SalesHeader);

        // Verify - After Error
        asserterror Error('');
        VerifySpecialOrderPurchaseOrder(SalesHeader);
        VerifyDropShipmentPurchaseOrder(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCarryOutReqWkshNoCommit()
    var
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup
        Initialize();
        CreateSalesOrderWithSpecialOrderAndDropShipment(SalesHeader);
        CreateRequisitionLines(RequisitionLine, SalesHeader);
        Commit();

        // Exercise
        CarryOutActionsOnReqWksheetWithoutCommit(RequisitionLine);

        // Verify
        VerifySpecialOrderPurchaseOrder(SalesHeader);
        VerifyDropShipmentPurchaseOrder(SalesHeader);

        // Verify - After Error
        asserterror Error('');
        asserterror VerifySpecialOrderPurchaseOrder(SalesHeader);
        Assert.ExpectedError('There is no Purchase Line within the filter.');
        asserterror VerifyDropShipmentPurchaseOrder(SalesHeader);
        Assert.ExpectedError('There is no Purchase Line within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostTransferOrderCommit()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        OriginalQuantity: Decimal;
        TransferQuantity: Decimal;
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
    begin
        // Setup
        Initialize();
        CreateTransferOrder(TransferHeader, Item, OriginalQuantity, TransferQuantity, FromLocationCode, ToLocationCode);
        Commit();

        // Exercise
        PostTransferOrderWithCommit(TransferHeader);

        // Verify
        Assert.AreEqual(OriginalQuantity - TransferQuantity, GetItemInventory(Item, FromLocationCode),
          'The quantity transfered is incorrect');
        Assert.AreEqual(TransferQuantity, GetItemInventory(Item, ToLocationCode), 'The quantity transfered is incorrect');

        // Verify - After Error
        asserterror Error('');
        asserterror TransferHeader.Get(TransferHeader."No.");
        Assert.ExpectedErrorCannotFind(Database::"Transfer Header", TransferHeader."No.");
        Assert.AreEqual(OriginalQuantity - TransferQuantity, GetItemInventory(Item, FromLocationCode),
          'The quantity transfered is incorrect');
        Assert.AreEqual(TransferQuantity, GetItemInventory(Item, ToLocationCode), 'The quantity transfered is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostTransferOrderNoCommit()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        OriginalQuantity: Decimal;
        TransferQuantity: Decimal;
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
    begin
        // Setup
        Initialize();
        CreateTransferOrder(TransferHeader, Item, OriginalQuantity, TransferQuantity, FromLocationCode, ToLocationCode);
        Commit();

        // Exercise
        PostTransferOrderWithoutCommit(TransferHeader);

        // Verify
        Assert.AreEqual(OriginalQuantity - TransferQuantity, GetItemInventory(Item, FromLocationCode),
          'The quantity transfered is incorrect');
        Assert.AreEqual(TransferQuantity, GetItemInventory(Item, ToLocationCode), 'The quantity transfered is incorrect');

        // Verify - After Error
        asserterror Error('');
        TransferHeader.Get(TransferHeader."No.");
        Assert.AreEqual(OriginalQuantity, GetItemInventory(Item, FromLocationCode),
          'The quantity transfered is incorrect');
        Assert.AreEqual(0, GetItemInventory(Item, ToLocationCode), 'The quantity transfered is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOneOfEachCommit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        LastGLEntryNo: Integer;
        LastItemLedgerEntryNo: Integer;
        OriginalQuantity: Decimal;
        TransferQuantity: Decimal;
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
    begin
        // Setup
        Initialize();
        CreateOneOfEachSetup(GenJournalLine, ItemJournalLine, SalesHeader, SalesHeader2, SalesHeader3,
          RequisitionLine, TransferHeader, Item, OriginalQuantity, TransferQuantity, FromLocationCode, ToLocationCode);
        LastGLEntryNo := FindLastGLEntryNo();
        LastItemLedgerEntryNo := FindLastItemLedgerEntryNo();
        Commit();

        // Exercise
        PostOneOfEachWithCommit(GenJournalLine, ItemJournalLine, SalesHeader, RequisitionLine, SalesHeader3, TransferHeader);

        // Verify
        VerifySpecialOrderPurchaseOrder(SalesHeader2);
        VerifyDropShipmentPurchaseOrder(SalesHeader2);
        Assert.AreEqual(OriginalQuantity - TransferQuantity, GetItemInventory(Item, FromLocationCode),
          'The quantity transfered is incorrect');
        Assert.AreEqual(TransferQuantity, GetItemInventory(Item, ToLocationCode), 'The quantity transfered is incorrect');
        VerifyPrePaymentAmounts(SalesHeader3, CalcSalesLinePrepaymentAmount(SalesHeader3));

        // Verify - After Error
        asserterror Error('');
        Assert.AreNotEqual(LastGLEntryNo, FindLastGLEntryNo(), 'G/L Entry was not committed');
        Assert.AreNotEqual(LastItemLedgerEntryNo, FindLastItemLedgerEntryNo(), 'G/L Entry was committed');
        asserterror SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AssertRecordNotFound();
        VerifySpecialOrderPurchaseOrder(SalesHeader2);
        VerifyDropShipmentPurchaseOrder(SalesHeader2);
        asserterror TransferHeader.Get(TransferHeader."No.");
        Assert.ExpectedError('The Transfer Header does not exist.');
        Assert.AreEqual(OriginalQuantity - TransferQuantity, GetItemInventory(Item, FromLocationCode),
          'The quantity transfered is incorrect');
        Assert.AreEqual(TransferQuantity, GetItemInventory(Item, ToLocationCode), 'The quantity transfered is incorrect');
        SalesHeader3.Get(SalesHeader3."Document Type", SalesHeader3."No.");
        SalesHeader3.TestField("Prepayment No.");
        SalesHeader3.TestField("Last Prepayment No.", '');
        VerifyPrePaymentAmountsError(SalesHeader3);

        // Tear down
        TearDownVATPostingSetup(SalesHeader3."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOneOfEachNoCommit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        LastGLEntryNo: Integer;
        LastItemLedgerEntryNo: Integer;
        OriginalQuantity: Decimal;
        TransferQuantity: Decimal;
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
    begin
        // Setup
        Initialize();
        CreateOneOfEachSetup(GenJournalLine, ItemJournalLine, SalesHeader, SalesHeader2, SalesHeader3,
          RequisitionLine, TransferHeader, Item, OriginalQuantity, TransferQuantity, FromLocationCode, ToLocationCode);
        LastGLEntryNo := FindLastGLEntryNo();
        LastItemLedgerEntryNo := FindLastItemLedgerEntryNo();
        Commit();

        // Exercise
        PostOneOfEachWithoutCommit(GenJournalLine, ItemJournalLine, SalesHeader, RequisitionLine, SalesHeader3, TransferHeader);

        // Verify
        VerifySpecialOrderPurchaseOrder(SalesHeader2);
        VerifyDropShipmentPurchaseOrder(SalesHeader2);
        Assert.AreEqual(OriginalQuantity - TransferQuantity, GetItemInventory(Item, FromLocationCode),
          'The quantity transfered is incorrect');
        Assert.AreEqual(TransferQuantity, GetItemInventory(Item, ToLocationCode), 'The quantity transfered is incorrect');
        VerifyPrePaymentAmounts(SalesHeader3, CalcSalesLinePrepaymentAmount(SalesHeader3));

        // Verify - After Error
        asserterror Error('');
        Assert.AreEqual(LastGLEntryNo, FindLastGLEntryNo(), 'G/L Entry was not committed');
        Assert.AreEqual(LastItemLedgerEntryNo, FindLastItemLedgerEntryNo(), 'G/L Entry was committed');
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        asserterror VerifySpecialOrderPurchaseOrder(SalesHeader2);
        Assert.ExpectedError('There is no Purchase Line within the filter.');
        asserterror VerifyDropShipmentPurchaseOrder(SalesHeader2);
        Assert.ExpectedError('There is no Purchase Line within the filter.');
        TransferHeader.Get(TransferHeader."No.");
        Assert.AreEqual(OriginalQuantity, GetItemInventory(Item, FromLocationCode),
          'The quantity transfered is incorrect');
        Assert.AreEqual(0, GetItemInventory(Item, ToLocationCode), 'The quantity transfered is incorrect');
        SalesHeader3.Get(SalesHeader3."Document Type", SalesHeader3."No.");
        SalesHeader3.TestField("Prepayment No.", '');
        SalesHeader3.TestField("Last Prepayment No.", '');
        VerifyPrePaymentAmountsError(SalesHeader3);

        // Tear down
        TearDownVATPostingSetup(SalesHeader3."VAT Bus. Posting Group");
    end;

    [Test]
    procedure TestPostSalesWithATONoCommit()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        SalesPost: Codeunit "Sales-Post";
    begin
        // [FEATURE] [Assembly to Order] [Sales]
        // [SCENARIO 395582] Forward suppress commit from sales order to linked assembly-to-order.

        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Modify(true);
        CreateItemWithInventory(CompItem, LibraryRandom.RandIntInRange(50, 100), '');
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipment Date", LibraryRandom.RandDate(30));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", LibraryRandom.RandInt(10));

        GLEntry.Init();
        GLEntry.Consistent(false);

        SalesHeader.Ship := true;
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);

        GLEntry.Consistent(true);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Suppress Commit in Post");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Test Suppress Commit in Post");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Test Suppress Commit in Post");
    end;


    local procedure CreateGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJnlLine(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
          LibraryRandom.RandDecInRange(1000, 10000, 2));
    end;

    local procedure PostGenJnlBatchWithCommit(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlPostBatch.SetSuppressCommit(false);
        GenJnlPostBatch.Run(GenJournalLine);
    end;

    local procedure PostGenJnlBatchWithoutCommit(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlPostBatch.SetSuppressCommit(true);
        GenJnlPostBatch.Run(GenJournalLine);
    end;

    local procedure FindLastGLEntryNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        exit(GLEntry."Entry No.");
    end;

    local procedure CreateItemJnlBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateItemJnlLine(ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line")
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine.Type::" ",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(1, 10, 2));
    end;

    local procedure PostItemJnlBatchWithCommit(ItemJournalLine: Record "Item Journal Line")
    var
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJnlPostBatch.SetSuppressCommit(false);
        ItemJnlPostBatch.Run(ItemJournalLine);
    end;

    local procedure PostItemJnlBatchWithoutCommit(ItemJournalLine: Record "Item Journal Line")
    var
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJnlPostBatch.SetSuppressCommit(true);
        ItemJnlPostBatch.Run(ItemJournalLine);
    end;

    local procedure FindLastItemLedgerEntryNo(): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.FindLast();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure CreateCustomerWithAddressAndlocation(var Customer: Record Customer)
    var
        Location: Record Location;
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibraryWarehouse.CreateLocation(Location);
        Customer.Validate("Location Code", Location.Code);
        Customer.Modify(true);
    end;

    local procedure CreateSpecialOrderPurchasingCode(): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure CreateDropShipmentPurchasingCode(): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure CreateItemWithVendor(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateSalesLineWithSpecialOrder(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        CreateItemWithVendor(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Purchasing Code", CreateSpecialOrderPurchasingCode());
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithDropShipment(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        CreateItemWithVendor(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Purchasing Code", CreateDropShipmentPurchasingCode());
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithSpecialOrderAndDropShipment(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        CreateCustomerWithAddressAndlocation(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLineWithSpecialOrder(SalesHeader, SalesLine);
        CreateSalesLineWithDropShipment(SalesHeader, SalesLine);
    end;

    local procedure FindSpecialOrderAndDropShipmentSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SpecialOrder: Boolean; DropShipment: Boolean)
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Special Order", SpecialOrder);
        SalesLine.SetRange("Drop Shipment", DropShipment);
        SalesLine.FindFirst();
    end;

    local procedure FindSpecialOrderSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        FindSpecialOrderAndDropShipmentSalesLine(SalesHeader, SalesLine, true, false);
    end;

    local procedure FindDropShipmentSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        FindSpecialOrderAndDropShipmentSalesLine(SalesHeader, SalesLine, false, true);
    end;

    local procedure CreateReqLineForSpecialOrder(RequisitionWkshName: Record "Requisition Wksh. Name"; var RequisitionLine: Record "Requisition Line"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        FindSpecialOrderSalesLine(SalesHeader, SalesLine);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, SalesLine."No.");
    end;

    local procedure CreateReqLineForDropShipment(RequisitionWkshName: Record "Requisition Wksh. Name"; var RequisitionLine: Record "Requisition Line"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        FindDropShipmentSalesLine(SalesHeader, SalesLine);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
    end;

    local procedure CreateRequisitionLines(var RequisitionLine: Record "Requisition Line"; SalesHeader: Record "Sales Header")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, LibraryPlanning.SelectRequisitionTemplateName());
        CreateReqLineForSpecialOrder(RequisitionWkshName, RequisitionLine, SalesHeader);
        CreateReqLineForDropShipment(RequisitionWkshName, RequisitionLine, SalesHeader);
    end;

    local procedure FindPurchaseHeaderFromSalesLine(var PurchaseHeader: Record "Purchase Header"; SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
    end;

    local procedure FindSpecialOrderPurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.SetRange("Special Order Sales No.", SalesLine."Document No.");
        PurchaseLine.FindFirst();
    end;

    local procedure FindDropShipmentPurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.SetRange("Sales Order No.", SalesLine."Document No.");
        PurchaseLine.FindFirst();
    end;

    local procedure VerifySpecialOrderPurchaseOrder(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        FindSpecialOrderSalesLine(SalesHeader, SalesLine);
        FindPurchaseHeaderFromSalesLine(PurchaseHeader, SalesLine);
        FindSpecialOrderPurchaseLine(PurchaseHeader, PurchaseLine, SalesLine);

        PurchaseLine.TestField("Purchasing Code", SalesLine."Purchasing Code");
        PurchaseLine.TestField("Special Order", SalesLine."Special Order");
        Location.Get(SalesHeader."Location Code");
        PurchaseHeader.TestField("Ship-to Name", Location.Name);
        PurchaseHeader.TestField("Ship-to Address", Location.Address);
    end;

    local procedure VerifyDropShipmentPurchaseOrder(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindDropShipmentSalesLine(SalesHeader, SalesLine);
        FindPurchaseHeaderFromSalesLine(PurchaseHeader, SalesLine);
        FindDropShipmentPurchaseLine(PurchaseHeader, PurchaseLine, SalesLine);

        PurchaseLine.TestField("Purchasing Code", SalesLine."Purchasing Code");
        PurchaseLine.TestField("Drop Shipment", SalesLine."Drop Shipment");
        PurchaseHeader.TestField("Ship-to Name", SalesHeader."Ship-to Name");
        PurchaseHeader.TestField("Ship-to Address", SalesHeader."Ship-to Address");
    end;

    local procedure CarryOutActionsOnReqWksheetWithCommit(RequisitionLine: Record "Requisition Line")
    var
        PurchaseHeader: Record "Purchase Header";
        ReqWkshMakeOrder: Codeunit "Req. Wksh.-Make Order";
    begin
        ReqWkshMakeOrder.SetSuppressCommit(false);
        ReqWkshMakeOrder.Set(PurchaseHeader, WorkDate(), false);
        ReqWkshMakeOrder.CarryOutBatchAction(RequisitionLine);
    end;

    local procedure CarryOutActionsOnReqWksheetWithoutCommit(RequisitionLine: Record "Requisition Line")
    var
        PurchaseHeader: Record "Purchase Header";
        ReqWkshMakeOrder: Codeunit "Req. Wksh.-Make Order";
    begin
        ReqWkshMakeOrder.SetSuppressCommit(true);
        ReqWkshMakeOrder.Set(PurchaseHeader, WorkDate(), false);
        ReqWkshMakeOrder.CarryOutBatchAction(RequisitionLine);
    end;

    local procedure CreateInTransitLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Use As In-Transit", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateItemWithInventory(var Item: Record Item; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDecInDecimalRange(1, 10000, 2), 0);
        CreateItemJnlBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; var Item: Record Item; var OriginalQuantity: Decimal; var TransferQuantity: Decimal; var FromLocationCode: Code[10]; var ToLocationCode: Code[10])
    var
        Location: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        OriginalQuantity := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        TransferQuantity := LibraryRandom.RandDecInDecimalRange(1, OriginalQuantity, 2);

        FromLocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ToLocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        CreateItemWithInventory(Item, OriginalQuantity, FromLocationCode);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, CreateInTransitLocation());
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", TransferQuantity);
    end;

    local procedure GetItemInventory(Item: Record Item; LocationCode: Code[10]): Decimal
    begin
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(Inventory);
        exit(Item.Inventory);
    end;

    local procedure PostTransferOrderWithCommit(TransferHeader: Record "Transfer Header")
    var
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
    begin
        TransferOrderPostShipment.SetSuppressCommit(false);
        TransferOrderPostShipment.SetHideValidationDialog(true);
        TransferOrderPostShipment.Run(TransferHeader);

        TransferOrderPostReceipt.SetSuppressCommit(false);
        TransferOrderPostReceipt.SetHideValidationDialog(true);
        TransferOrderPostReceipt.Run(TransferHeader);
    end;

    local procedure PostTransferOrderWithoutCommit(TransferHeader: Record "Transfer Header")
    var
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
    begin
        TransferOrderPostShipment.SetSuppressCommit(true);
        TransferOrderPostShipment.SetHideValidationDialog(true);
        TransferOrderPostShipment.Run(TransferHeader);

        TransferOrderPostReceipt.SetSuppressCommit(true);
        TransferOrderPostReceipt.SetHideValidationDialog(true);
        TransferOrderPostReceipt.Run(TransferHeader);
    end;

    local procedure CreateOneOfEachSetup(var GenJournalLine: Record "Gen. Journal Line"; var ItemJournalLine: Record "Item Journal Line"; var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; var SalesHeader3: Record "Sales Header"; var RequisitionLine: Record "Requisition Line"; var TransferHeader: Record "Transfer Header"; var Item: Record Item; var OriginalQuantity: Decimal; var TransferQuantity: Decimal; var FromLocationCode: Code[10]; var ToLocationCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateGenJnlBatch(GenJournalBatch);
        CreateGenJnlLine(GenJournalBatch, GenJournalLine);
        CreateItemJnlBatch(ItemJournalBatch);
        CreateItemJnlLine(ItemJournalBatch, ItemJournalLine);
        LibrarySales.CreateSalesInvoice(SalesHeader);
        CreateSalesOrderWithSpecialOrderAndDropShipment(SalesHeader2);
        CreateRequisitionLines(RequisitionLine, SalesHeader2);
        CreateSalesOrderForPrePayment(SalesHeader3);
        CreateTransferOrder(TransferHeader, Item, OriginalQuantity, TransferQuantity, FromLocationCode, ToLocationCode);
    end;

    local procedure PostOneOfEachWithCommit(var GenJournalLine: Record "Gen. Journal Line"; var ItemJournalLine: Record "Item Journal Line"; var SalesHeader: Record "Sales Header"; var RequisitionLine: Record "Requisition Line"; var SalesHeader3: Record "Sales Header"; var TransferHeader: Record "Transfer Header")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        PostGenJnlBatchWithCommit(GenJournalLine);
        PostItemJnlBatchWithCommit(ItemJournalLine);
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
        CarryOutActionsOnReqWksheetWithCommit(RequisitionLine);
        SalesPostPrepayments.SetSuppressCommit(false);
        PostTransferOrderWithCommit(TransferHeader);
        SalesPostPrepayments.Invoice(SalesHeader3); // prepayment must be last as it has no true commit at the end
    end;

    local procedure PostOneOfEachWithoutCommit(var GenJournalLine: Record "Gen. Journal Line"; var ItemJournalLine: Record "Item Journal Line"; var SalesHeader: Record "Sales Header"; var RequisitionLine: Record "Requisition Line"; var SalesHeader3: Record "Sales Header"; var TransferHeader: Record "Transfer Header")
    var
        SalesPost: Codeunit "Sales-Post";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        PostGenJnlBatchWithoutCommit(GenJournalLine);
        PostItemJnlBatchWithoutCommit(ItemJournalLine);
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);
        CarryOutActionsOnReqWksheetWithoutCommit(RequisitionLine);
        SalesPostPrepayments.SetSuppressCommit(true);
        PostTransferOrderWithoutCommit(TransferHeader);
        SalesPostPrepayments.Invoice(SalesHeader3);
    end;

    local procedure CreateGLAccountAndSetupForPrePayment(var GLAccount: Record "G/L Account")
    var
        GLAccount2: Record "G/L Account";
    begin
        LibrarySales.CreatePrepaymentVATSetup(GLAccount2, "Tax Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.TransferFields(GLAccount2, false);
        GLAccount.Modify(true);
    end;

    local procedure CreateCustomerForPrePayment(var Customer: Record Customer; var GLAccount: Record "G/L Account")
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Validate("Prepayment %", LibraryRandom.RandDec(100, 5));
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    local procedure CreateSalesOrderForPrePayment(var SalesHeader: Record "Sales Header")
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        NoSeries: Record "No. Series";
    begin
        CreateGLAccountAndSetupForPrePayment(GLAccount);
        CreateCustomerForPrePayment(Customer, GLAccount);
        NoSeries.Get(LibraryERM.CreateNoSeriesCode());
        NoSeries."Date Order" := true;
        NoSeries.Modify();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader."Prepayment No. Series" := NoSeries.Code;
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CopyStr(GLAccount.Name, 1, 20), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CalcSalesLinePrepaymentAmount(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.CalcSums(SalesLine."Prepmt. Amt. Incl. VAT");
        exit(SalesLine."Prepmt. Amt. Incl. VAT");
    end;

    local procedure TearDownVATPostingSetup(VATBusPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.DeleteAll();
    end;

    local procedure VerifyPrePaymentAmounts(SalesHeader: Record "Sales Header"; PrePaymentAmount: Decimal)
    begin
        VerifySalesInvoiceLinePrePaymentAmount(SalesHeader."Last Prepayment No.", PrePaymentAmount);
        VerifyPrePaymentInvoiceCustLedgEntry(SalesHeader."Last Prepayment No.", PrePaymentAmount, SalesHeader."Prepayment Due Date");
    end;

    local procedure VerifyPrePaymentAmountsError(SalesHeader: Record "Sales Header")
    begin
        VerifySalesInvoiceLinePrePaymentAmount(SalesHeader."Last Prepayment No.", 0);
        asserterror VerifyPrePaymentInvoiceCustLedgEntry(SalesHeader."Last Prepayment No.", 0, SalesHeader."Prepayment Due Date");
        Assert.ExpectedError('There is no Cust. Ledger Entry within the filter.');
    end;

    local procedure VerifySalesInvoiceLinePrePaymentAmount(PrePaymentInvoiceNo: Code[20]; PrePaymentAmount: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", PrePaymentInvoiceNo);
        SalesInvoiceLine.CalcSums("Amount Including VAT");
        SalesInvoiceLine.TestField("Amount Including VAT", PrePaymentAmount);
    end;

    local procedure VerifyPrePaymentInvoiceCustLedgEntry(PrePaymentInvoiceNo: Code[20]; PrePaymentAmount: Decimal; PrePaymentDueDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", PrePaymentInvoiceNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, PrePaymentAmount);
        CustLedgerEntry.TestField("Due Date", PrePaymentDueDate);
    end;
}

