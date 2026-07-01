codeunit 134468 "ERM Matched Order Line Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Matched Order Lines]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        EmptyGuid: Guid;

    // ============================================================================
    // REGION: E2E-1 Standard Invoice Matching Flow (No Receipt on Invoice)
    // ============================================================================

    [Test]
    [Scope('OnPrem')]
    procedure E2E_SingleOrderSingleReceiptFullInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-1.1] Single Order, Single Receipt, Full Invoice
        // [GIVEN] Create Purchase Order for Vendor V, Item I, Qty = 100
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // [GIVEN] Post Purchase Order (Receive only) - Receipt R created
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // Refresh order line and find receipt line
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // Verify receipt created correctly
        Assert.AreEqual(Quantity, PurchRcptLine.Quantity, 'Receipt quantity should match order quantity');
        Assert.AreEqual(Quantity, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Qty. Rcd. Not Invoiced should equal quantity');

        // [GIVEN] Create Purchase Invoice for Vendor V with line: Item I, Qty = 100
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [WHEN] Match invoice line to order by creating matched order lines
        // Create order-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Verify match created
        PurchaseLineInvoice.CalcFields("Matched Order Lines");
        Assert.AreEqual(1, PurchaseLineInvoice."Matched Order Lines", 'Invoice line should have 1 matched order line');

        // Post Invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Posted Matched Order Line created with Document Line SystemId = Posted Invoice Line
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();

        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.RecordIsNotEmpty(PostedMatchedOrderLine);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Should create 2 Posted Matched Order Line records (1 order-level + 1 receipt-level)');
        PostedMatchedOrderLine.FindFirst();
        Assert.AreEqual(PurchaseLineOrder.SystemId, PostedMatchedOrderLine."Matched Order Line SystemId", 'Posted match should reference order line');
        Assert.AreEqual(Quantity, PostedMatchedOrderLine."Qty. Invoiced", 'Posted match should have correct invoiced quantity');

        // [THEN] Matched Order Line deleted from Matched Order Lines 
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);

        // [THEN] Order Line Quantity Invoiced = 100, Qty. to Invoice = 0
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Quantity, PurchaseLineOrder."Quantity Invoiced", 'Order line Quantity Invoiced should be updated');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order line Qty. to Invoice should be 0');

        // [THEN] Receipt Line Qty. Rcd. Not Invoiced = 0
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt line Qty. Rcd. Not Invoiced should be 0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_SingleOrderSingleReceiptPartialInvoiceMultipleInvoices()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice1: Record "Purchase Header";
        PurchaseLineInvoice1: Record "Purchase Line";
        PurchaseHeaderInvoice2: Record "Purchase Header";
        PurchaseLineInvoice2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo1: Code[20];
        PostedInvoiceNo2: Code[20];
        TotalQuantity: Decimal;
        Invoice1Quantity: Decimal;
        Invoice2Quantity: Decimal;
    begin
        // [SCENARIO E2E-1.2] Single Order, Single Receipt, Partial Invoice (Multiple Invoices)
        // [GIVEN] Create Purchase Order: Item I, Qty = 100 and Post (Receive)
        Initialize();
        TotalQuantity := 100;
        Invoice1Quantity := 40;
        Invoice2Quantity := 60;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // Post Purchase Order (Receive only) - Receipt R created
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // Refresh order line and find receipt line
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Purchase Invoice #1: Item I, Qty = 40, Match with Qty. to Invoice = 40
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice1, PurchaseHeaderInvoice1."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice1, PurchaseHeaderInvoice1, PurchaseLineInvoice1.Type::Item, Item."No.", Invoice1Quantity);
        PurchaseLineInvoice1.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice1.Modify(true);

        // Create order-level match for Invoice #1
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice1.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Invoice1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice1Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match for Invoice #1
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice1.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Invoice1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice1Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [WHEN] Post Invoice #1
        PostedInvoiceNo1 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice1, false, true);

        // [THEN] Order Line Quantity Invoiced = 40, Receipt Line Qty. Rcd. Not Invoiced = 60
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Invoice1Quantity, PurchaseLineOrder."Quantity Invoiced", 'Order line Quantity Invoiced should be 40 after first invoice');
        Assert.AreEqual(Invoice2Quantity, PurchaseLineOrder."Qty. to Invoice", 'Order line Qty. to Invoice should be 60 after first invoice');

        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(Invoice2Quantity, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt line Qty. Rcd. Not Invoiced should be 60 after first invoice');

        // Verify Posted Matched Order Line for Invoice #1
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo1);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.RecordIsNotEmpty(PostedMatchedOrderLine);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #1 should create 2 Posted Matched Order Line records (1 order-level + 1 receipt-level)');
        PostedMatchedOrderLine.FindFirst();
        Assert.AreEqual(Invoice1Quantity, PostedMatchedOrderLine."Qty. Invoiced", 'Posted match #1 should have qty invoiced = 40');

        // [GIVEN] Create Purchase Invoice #2: Item I, Qty = 60, Match to same order/receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice2, PurchaseHeaderInvoice2."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice2, PurchaseHeaderInvoice2, PurchaseLineInvoice2.Type::Item, Item."No.", Invoice2Quantity);
        PurchaseLineInvoice2.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice2.Modify(true);

        // Create order-level match for Invoice #2
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice2.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Invoice2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice2Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match for Invoice #2
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice2.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Invoice2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice2Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [WHEN] Post Invoice #2
        PostedInvoiceNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice2, false, true);

        // [THEN] Order Line Quantity Invoiced = 100, Outstanding Quantity = 0
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Invoiced", 'Order line Quantity Invoiced should be 100 after second invoice');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order line Qty. to Invoice should be 0 after second invoice');
        Assert.AreEqual(0, PurchaseLineOrder."Outstanding Quantity", 'Order line Outstanding Quantity should be 0');

        // [THEN] Receipt Line Qty. Rcd. Not Invoiced = 0
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt line Qty. Rcd. Not Invoiced should be 0 after full invoicing');

        // [THEN] Posted Invoice #1 shows 40 qty, Posted Invoice #2 shows 60 qty
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo1);
        PurchInvLine.FindFirst();
        Assert.AreEqual(Invoice1Quantity, PurchInvLine.Quantity, 'Posted Invoice #1 should have qty = 40');

        PurchInvLine.SetRange("Document No.", PostedInvoiceNo2);
        PurchInvLine.FindFirst();
        Assert.AreEqual(Invoice2Quantity, PurchInvLine.Quantity, 'Posted Invoice #2 should have qty = 60');

        // Verify Posted Matched Order Line for Invoice #2
        PostedMatchedOrderLine.Reset();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.RecordIsNotEmpty(PostedMatchedOrderLine);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #2 should create 2 Posted Matched Order Line records (1 order-level + 1 receipt-level)');
        PostedMatchedOrderLine.FindFirst();
        Assert.AreEqual(Invoice2Quantity, PostedMatchedOrderLine."Qty. Invoiced", 'Posted match #2 should have qty invoiced = 60');

        // Verify all Matched Order Lines deleted
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_SingleOrderMultipleReceiptsSingleInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine1: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        TotalQuantity: Decimal;
        Receipt1Quantity: Decimal;
        Receipt2Quantity: Decimal;
    begin
        // [SCENARIO E2E-1.3] Single Order, Multiple Receipts, Single Invoice
        // [GIVEN] Create Purchase Order: Item I, Qty = 100
        Initialize();
        TotalQuantity := 100;
        Receipt1Quantity := 30;
        Receipt2Quantity := 70;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // [GIVEN] Post Receive with Qty = 30 (Receipt R1)
        PurchaseLineOrder.Validate("Qty. to Receive", Receipt1Quantity);
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // Find first receipt line
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine1.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine1.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine1.FindFirst();
        Assert.AreEqual(Receipt1Quantity, PurchRcptLine1.Quantity, 'Receipt #1 quantity should be 30');

        // [GIVEN] Post Receive with Qty = 70 (Receipt R2)
        PurchaseHeaderOrder.Get(PurchaseHeaderOrder."Document Type", PurchaseHeaderOrder."No.");
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchaseLineOrder.Validate("Qty. to Receive", Receipt2Quantity);
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // Find second receipt line
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine2.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine2.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine2.SetFilter("Document No.", '<>%1', PurchRcptLine1."Document No.");
        PurchRcptLine2.FindFirst();
        Assert.AreEqual(Receipt2Quantity, PurchRcptLine2.Quantity, 'Receipt #2 quantity should be 70');

        // [GIVEN] Create Purchase Invoice: Item I, Qty = 100
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [WHEN] Match to order (creates matches for both receipts) and Post Invoice
        // Create order-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := TotalQuantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := TotalQuantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match for Receipt #1
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine1.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Receipt1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Receipt1Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match for Receipt #2
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine2.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Receipt2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Receipt2Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Post Invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] 3 Posted Matched Order Lines created (1 order-level + 2 receipt-level)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.RecordIsNotEmpty(PostedMatchedOrderLine);
        Assert.AreEqual(3, PostedMatchedOrderLine.Count(), 'Should create 3 Posted Matched Order Line records (1 order-level + 2 receipt-level)');

        // [THEN] Both receipt lines fully invoiced (Qty. Rcd. Not Invoiced = 0 each)
        PurchRcptLine1.Get(PurchRcptLine1."Document No.", PurchRcptLine1."Line No.");
        Assert.AreEqual(0, PurchRcptLine1."Qty. Rcd. Not Invoiced", 'Receipt #1 Qty. Rcd. Not Invoiced should be 0');

        PurchRcptLine2.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No.");
        Assert.AreEqual(0, PurchRcptLine2."Qty. Rcd. Not Invoiced", 'Receipt #2 Qty. Rcd. Not Invoiced should be 0');

        // Verify order line fully invoiced
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Invoiced", 'Order line Quantity Invoiced should be 100');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order line Qty. to Invoice should be 0');

        // Verify all Matched Order Lines deleted
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_MultipleOrdersSingleInvoice()
    var
        PurchaseHeaderOrder1: Record "Purchase Header";
        PurchaseLineOrder1: Record "Purchase Line";
        PurchaseHeaderOrder2: Record "Purchase Header";
        PurchaseLineOrder2: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine1: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        Order1Quantity: Decimal;
        Order2Quantity: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO E2E-1.4] Multiple Orders, Single Invoice
        // [GIVEN] Create Purchase Order #1: Item I, Qty = 50 and Post (Receive)
        Initialize();
        Order1Quantity := 50;
        Order2Quantity := 50;
        TotalQuantity := Order1Quantity + Order2Quantity;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // Create and receive Order #1
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder1, PurchaseHeaderOrder1."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder1, PurchaseHeaderOrder1, PurchaseLineOrder1.Type::Item, Item."No.", Order1Quantity);
        PurchaseLineOrder1.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder1.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder1, true, false);

        // Find receipt line for Order #1
        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine1.SetRange("Order No.", PurchaseLineOrder1."Document No.");
        PurchRcptLine1.SetRange("Order Line No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine1.FindFirst();

        // [GIVEN] Create Purchase Order #2: Item I, Qty = 50 and Post (Receive)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder2, PurchaseHeaderOrder2."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder2, PurchaseHeaderOrder2, PurchaseLineOrder2.Type::Item, Item."No.", Order2Quantity);
        PurchaseLineOrder2.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineOrder2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder2, true, false);

        // Find receipt line for Order #2
        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.SetRange("Order No.", PurchaseLineOrder2."Document No.");
        PurchRcptLine2.SetRange("Order Line No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.FindFirst();

        // [GIVEN] Create Purchase Invoice: Item I, Qty = 100
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [WHEN] Match to both orders and Post Invoice
        // Create order-level match for Order #1
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder1.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Order1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Order1Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match for Order #1
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder1.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine1.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Order1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Order1Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create order-level match for Order #2
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder2.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Order2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Order2Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match for Order #2
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder2.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine2.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Order2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Order2Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Post Invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Order #1 Quantity Invoiced = 50, Order #2 Quantity Invoiced = 50
        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        Assert.AreEqual(Order1Quantity, PurchaseLineOrder1."Quantity Invoiced", 'Order #1 Quantity Invoiced should be 50');
        Assert.AreEqual(0, PurchaseLineOrder1."Qty. to Invoice", 'Order #1 Qty. to Invoice should be 0');

        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        Assert.AreEqual(Order2Quantity, PurchaseLineOrder2."Quantity Invoiced", 'Order #2 Quantity Invoiced should be 50');
        Assert.AreEqual(0, PurchaseLineOrder2."Qty. to Invoice", 'Order #2 Qty. to Invoice should be 0');

        // [THEN] 4 Posted Matched Order Lines (2 orders + 2 receipts)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.RecordIsNotEmpty(PostedMatchedOrderLine);
        Assert.AreEqual(4, PostedMatchedOrderLine.Count(), 'Should create 4 Posted Matched Order Line records (2 order-level + 2 receipt-level)');

        // Verify receipt lines fully invoiced
        PurchRcptLine1.Get(PurchRcptLine1."Document No.", PurchRcptLine1."Line No.");
        Assert.AreEqual(0, PurchRcptLine1."Qty. Rcd. Not Invoiced", 'Receipt #1 Qty. Rcd. Not Invoiced should be 0');

        PurchRcptLine2.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No.");
        Assert.AreEqual(0, PurchRcptLine2."Qty. Rcd. Not Invoiced", 'Receipt #2 Qty. Rcd. Not Invoiced should be 0');

        // Verify all Matched Order Lines deleted
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    // ============================================================================
    // REGION: E2E-2 Receipt on Invoice Flow (Auto-Receipt)
    // ============================================================================

    [Test]
    [Scope('OnPrem')]
    procedure E2E_ReceiptOnInvoiceBasicFullQuantity()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-2.1] Basic Receipt on Invoice - Full Quantity
        // [GIVEN] Create Purchase Order with Receipt on Invoice = TRUE, Qty = 100
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // Enable Receipt on Invoice on the order
        PurchaseHeaderOrder.Validate("Receipt on Invoice", true);
        PurchaseHeaderOrder.Modify(true);

        // [GIVEN] NO receipt posted yet (Quantity Received = 0)
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(0, PurchaseLineOrder."Quantity Received", 'No receipt should be posted yet');

        // [GIVEN] Create Purchase Invoice: Item I, Qty = 100 and Match to order
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Create order-level match only (receipt-level match is auto-created)
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := true;
        MatchedOrderLine.Insert();

        // [WHEN] Post Purchase Invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Receipt auto-posted (Receipt document created)
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();
        Assert.AreEqual(Quantity, PurchRcptLine.Quantity, 'Auto-posted receipt should have full quantity');

        // [THEN] Order Quantity Received = 100, Quantity Invoiced = 100
        Assert.AreEqual(Quantity, PurchaseLineOrder."Quantity Received", 'Order line should be fully received');
        Assert.AreEqual(Quantity, PurchaseLineOrder."Quantity Invoiced", 'Order line should be fully invoiced');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order line Qty. to Invoice should be 0');
        Assert.AreEqual(0, PurchaseLineOrder."Outstanding Quantity", 'Order line Outstanding Quantity should be 0');

        // [THEN] Receipt line fully invoiced
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt line Qty. Rcd. Not Invoiced should be 0');

        // [THEN] Posted Matched Order Line has Receipt on Invoice = TRUE
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.RecordIsNotEmpty(PostedMatchedOrderLine);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Should create 2 Posted Matched Order Line records (1 order-level + 1 receipt-level)');

        // Verify order-level posted match has Receipt on Invoice = TRUE
        PostedMatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        PostedMatchedOrderLine.FindFirst();
        Assert.IsTrue(PostedMatchedOrderLine."Receipt on Invoice", 'Order-level posted match should have Receipt on Invoice = TRUE');

        // [THEN] Receipt-level posted match has correct receipt SystemId
        PostedMatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<>%1', EmptyGuid);
        PostedMatchedOrderLine.FindFirst();
        Assert.AreEqual(PurchRcptLine.SystemId, PostedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId", 'Receipt-level match should reference auto-created receipt');
        Assert.IsTrue(PostedMatchedOrderLine."Receipt on Invoice", 'Receipt-level posted match should have Receipt on Invoice = TRUE');
        Assert.AreEqual(Quantity, PostedMatchedOrderLine."Qty. Invoiced", 'Posted match should have correct invoiced quantity');

        // Verify all Matched Order Lines deleted
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_ReceiptOnInvoicePartialQuantity()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice1: Record "Purchase Header";
        PurchaseLineInvoice1: Record "Purchase Line";
        PurchaseHeaderInvoice2: Record "Purchase Header";
        PurchaseLineInvoice2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo1: Code[20];
        PostedInvoiceNo2: Code[20];
        TotalQuantity: Decimal;
        Invoice1Quantity: Decimal;
        Invoice2Quantity: Decimal;
    begin
        // [SCENARIO E2E-2.2] Receipt on Invoice - Partial Quantity
        // [GIVEN] Create Purchase Order with Receipt on Invoice = TRUE, Qty = 100
        Initialize();
        TotalQuantity := 100;
        Invoice1Quantity := 40;
        Invoice2Quantity := 60;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // Enable Receipt on Invoice on the order
        PurchaseHeaderOrder.Validate("Receipt on Invoice", true);
        PurchaseHeaderOrder.Modify(true);

        // [GIVEN] Create Purchase Invoice #1: Qty = 40, Match with Qty. to Invoice = 40
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice1, PurchaseHeaderInvoice1."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice1, PurchaseHeaderInvoice1, PurchaseLineInvoice1.Type::Item, Item."No.", Invoice1Quantity);
        PurchaseLineInvoice1.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice1.Modify(true);

        // Create order-level match for Invoice #1 (receipt auto-created)
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice1.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Invoice1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice1Quantity;
        MatchedOrderLine."Receipt on Invoice" := true;
        MatchedOrderLine.Insert();

        // [WHEN] Post Invoice #1
        PostedInvoiceNo1 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice1, false, true);

        // [THEN] Receipt posted for Qty = 40 (partial receipt)
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Invoice1Quantity, PurchaseLineOrder."Quantity Received", 'Order should have partial receipt of 40');
        Assert.AreEqual(Invoice1Quantity, PurchaseLineOrder."Quantity Invoiced", 'Order Quantity Invoiced should be 40');
        Assert.AreEqual(Invoice2Quantity, PurchaseLineOrder."Qty. to Invoice", 'Order Qty. to Invoice should be 60');

        // Verify first receipt line
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();
        Assert.AreEqual(Invoice1Quantity, PurchRcptLine.Quantity, 'First receipt should have qty = 40');
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'First receipt should be fully invoiced');

        // Verify Posted Matched Order Line for Invoice #1
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo1);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #1 should create 2 Posted Matched Order Line records');

        // [GIVEN] Create Purchase Invoice #2: Qty = 60, Match remaining
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice2, PurchaseHeaderInvoice2."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice2, PurchaseHeaderInvoice2, PurchaseLineInvoice2.Type::Item, Item."No.", Invoice2Quantity);
        PurchaseLineInvoice2.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice2.Modify(true);

        // Create order-level match for Invoice #2 (receipt auto-created)
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice2.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Invoice2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice2Quantity;
        MatchedOrderLine."Receipt on Invoice" := true;
        MatchedOrderLine.Insert();

        // [WHEN] Post Invoice #2
        PostedInvoiceNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice2, false, true);

        // [THEN] Order fully received and invoiced
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Received", 'Order should be fully received');
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Invoiced", 'Order should be fully invoiced');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order Qty. to Invoice should be 0');
        Assert.AreEqual(0, PurchaseLineOrder."Outstanding Quantity", 'Order Outstanding Quantity should be 0');

        // Verify 2 receipt lines exist (one per invoice)
        PurchRcptLine.Reset();
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(2, PurchRcptLine.Count(), 'Should have 2 receipt lines (one per invoice)');

        // Verify Posted Matched Order Line for Invoice #2
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo2);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.Reset();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #2 should create 2 Posted Matched Order Line records');

        // Verify all Matched Order Lines deleted
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_ReceiptOnInvoiceMultipleOrdersSingleInvoice()
    var
        PurchaseHeaderOrder1: Record "Purchase Header";
        PurchaseLineOrder1: Record "Purchase Line";
        PurchaseHeaderOrder2: Record "Purchase Header";
        PurchaseLineOrder2: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        Order1Quantity: Decimal;
        Order2Quantity: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO E2E-2.3] Receipt on Invoice - Multiple Orders, Single Invoice
        Initialize();
        Order1Quantity := 50;
        Order2Quantity := 50;
        TotalQuantity := Order1Quantity + Order2Quantity;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order #1: Qty = 50, Receipt on Invoice = TRUE
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder1, PurchaseHeaderOrder1."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder1, PurchaseHeaderOrder1, PurchaseLineOrder1.Type::Item, Item."No.", Order1Quantity);
        PurchaseLineOrder1.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder1.Modify(true);
        PurchaseHeaderOrder1.Validate("Receipt on Invoice", true);
        PurchaseHeaderOrder1.Modify(true);

        // [GIVEN] Create Purchase Order #2: Qty = 50, Receipt on Invoice = TRUE
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder2, PurchaseHeaderOrder2."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder2, PurchaseHeaderOrder2, PurchaseLineOrder2.Type::Item, Item."No.", Order2Quantity);
        PurchaseLineOrder2.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineOrder2.Modify(true);
        PurchaseHeaderOrder2.Validate("Receipt on Invoice", true);
        PurchaseHeaderOrder2.Modify(true);

        // Refresh order line SystemIds
        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");

        // [GIVEN] Create Purchase Invoice: Qty = 100 and Match to both orders
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Create order-level match for Order #1 (receipt auto-created)
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder1.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Order1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Order1Quantity;
        MatchedOrderLine."Receipt on Invoice" := true;
        MatchedOrderLine.Insert();

        // Create order-level match for Order #2 (receipt auto-created)
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder2.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Order2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Order2Quantity;
        MatchedOrderLine."Receipt on Invoice" := true;
        MatchedOrderLine.Insert();

        // [WHEN] Post Invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Both orders received and invoiced
        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        Assert.AreEqual(Order1Quantity, PurchaseLineOrder1."Quantity Received", 'Order #1 should be fully received');
        Assert.AreEqual(Order1Quantity, PurchaseLineOrder1."Quantity Invoiced", 'Order #1 should be fully invoiced');
        Assert.AreEqual(0, PurchaseLineOrder1."Qty. to Invoice", 'Order #1 Qty. to Invoice should be 0');

        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        Assert.AreEqual(Order2Quantity, PurchaseLineOrder2."Quantity Received", 'Order #2 should be fully received');
        Assert.AreEqual(Order2Quantity, PurchaseLineOrder2."Quantity Invoiced", 'Order #2 should be fully invoiced');
        Assert.AreEqual(0, PurchaseLineOrder2."Qty. to Invoice", 'Order #2 Qty. to Invoice should be 0');

        // [THEN] 2 Receipts auto-posted (one per order)
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder1."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine.FindFirst();
        Assert.AreEqual(Order1Quantity, PurchRcptLine.Quantity, 'Receipt for Order #1 should have qty = 50');
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt for Order #1 should be fully invoiced');

        PurchRcptLine.Reset();
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder2."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine.FindFirst();
        Assert.AreEqual(Order2Quantity, PurchRcptLine.Quantity, 'Receipt for Order #2 should have qty = 50');
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt for Order #2 should be fully invoiced');

        // [THEN] 4 Posted Matched Order Lines (2 order-level + 2 receipt-level)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.RecordIsNotEmpty(PostedMatchedOrderLine);
        Assert.AreEqual(4, PostedMatchedOrderLine.Count(), 'Should create 4 Posted Matched Order Line records (2 order-level + 2 receipt-level)');

        // Verify all posted matches have Receipt on Invoice = TRUE
        PostedMatchedOrderLine.SetRange("Receipt on Invoice", true);
        Assert.AreEqual(4, PostedMatchedOrderLine.Count(), 'All posted matches should have Receipt on Invoice = TRUE');

        // Verify all Matched Order Lines deleted
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_MixedOrdersSomeWithReceiptOnInvoice()
    var
        PurchaseHeaderOrder1: Record "Purchase Header";
        PurchaseLineOrder1: Record "Purchase Line";
        PurchaseHeaderOrder2: Record "Purchase Header";
        PurchaseLineOrder2: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine1: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        Order1Quantity: Decimal;
        Order2Quantity: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO E2E-2.4] Mixed Orders - Some with Receipt on Invoice
        Initialize();
        Order1Quantity := 50;
        Order2Quantity := 50;
        TotalQuantity := Order1Quantity + Order2Quantity;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order #1: Qty = 50, Receipt on Invoice = TRUE (no manual receipt)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder1, PurchaseHeaderOrder1."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder1, PurchaseHeaderOrder1, PurchaseLineOrder1.Type::Item, Item."No.", Order1Quantity);
        PurchaseLineOrder1.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder1.Modify(true);
        PurchaseHeaderOrder1.Validate("Receipt on Invoice", true);
        PurchaseHeaderOrder1.Modify(true);

        // [GIVEN] Create Order #2: Qty = 50, Receipt on Invoice = FALSE and Post (Receive)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder2, PurchaseHeaderOrder2."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder2, PurchaseHeaderOrder2, PurchaseLineOrder2.Type::Item, Item."No.", Order2Quantity);
        PurchaseLineOrder2.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineOrder2.Modify(true);
        // Receipt on Invoice stays FALSE (default)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder2, true, false);

        // Find receipt line for Order #2 (manually posted)
        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.SetRange("Order No.", PurchaseLineOrder2."Document No.");
        PurchRcptLine2.SetRange("Order Line No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.FindFirst();
        Assert.AreEqual(Order2Quantity, PurchRcptLine2.Quantity, 'Order #2 receipt quantity should be 50');

        // Refresh Order #1 line
        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");

        // [GIVEN] Create Purchase Invoice: Qty = 100
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [GIVEN] Match to Order #1 (will auto-receive) - order-level match only
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder1.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Order1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Order1Quantity;
        MatchedOrderLine."Receipt on Invoice" := true;
        MatchedOrderLine.Insert();

        // [GIVEN] Match to Order #2 (already received) - order-level + receipt-level matches
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder2.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Order2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Order2Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder2.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine2.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Order2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Order2Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [WHEN] Post Invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Receipt auto-posted for Order #1 only
        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        Assert.AreEqual(Order1Quantity, PurchaseLineOrder1."Quantity Received", 'Order #1 should be auto-received = 50');
        Assert.AreEqual(Order1Quantity, PurchaseLineOrder1."Quantity Invoiced", 'Order #1 should be fully invoiced');
        Assert.AreEqual(0, PurchaseLineOrder1."Qty. to Invoice", 'Order #1 Qty. to Invoice should be 0');

        // Verify auto-created receipt for Order #1
        PurchRcptLine1.SetRange("Order No.", PurchaseLineOrder1."Document No.");
        PurchRcptLine1.SetRange("Order Line No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine1.FindFirst();
        Assert.AreEqual(Order1Quantity, PurchRcptLine1.Quantity, 'Auto-receipt for Order #1 should have qty = 50');
        Assert.AreEqual(0, PurchRcptLine1."Qty. Rcd. Not Invoiced", 'Auto-receipt for Order #1 should be fully invoiced');

        // [THEN] Order #2 receipt unchanged, fully invoiced
        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        Assert.AreEqual(Order2Quantity, PurchaseLineOrder2."Quantity Received", 'Order #2 receipt should be unchanged = 50');
        Assert.AreEqual(Order2Quantity, PurchaseLineOrder2."Quantity Invoiced", 'Order #2 should be fully invoiced');
        Assert.AreEqual(0, PurchaseLineOrder2."Qty. to Invoice", 'Order #2 Qty. to Invoice should be 0');

        PurchRcptLine2.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No.");
        Assert.AreEqual(0, PurchRcptLine2."Qty. Rcd. Not Invoiced", 'Order #2 receipt should be fully invoiced');

        // [THEN] Posted Matched Order Lines created
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.RecordIsNotEmpty(PostedMatchedOrderLine);
        Assert.AreEqual(4, PostedMatchedOrderLine.Count(), 'Should create 4 Posted Matched Order Line records (2 order-level + 2 receipt-level)');

        // Verify Order #1 matches have Receipt on Invoice = TRUE
        PostedMatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder1.SystemId);
        PostedMatchedOrderLine.SetRange("Receipt on Invoice", true);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Order #1 matches should have Receipt on Invoice = TRUE');

        // Verify Order #2 matches have Receipt on Invoice = FALSE
        PostedMatchedOrderLine.Reset();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        PostedMatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder2.SystemId);
        PostedMatchedOrderLine.SetRange("Receipt on Invoice", false);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Order #2 matches should have Receipt on Invoice = FALSE');

        // Verify all Matched Order Lines deleted
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    // ============================================================================
    // REGION: E2E-3 Negative/Error Scenarios with Posting
    // ============================================================================

    [Test]
    [Scope('OnPrem')]
    procedure E2E_QuantityMismatchPreventsPosting()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-3.1] Quantity Mismatch Prevents Posting
        Initialize();
        Quantity := 100;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order, Receive Qty = 100
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice: Qty = 100, Match with receipt Qty. to Invoice = 80 (mismatch)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Create order-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match with mismatched qty = 80
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := 80;
        MatchedOrderLine."Qty. to Invoice (Base)" := 80;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [WHEN] Attempt to Post Invoice
        // [THEN] Error: Quantity mismatch (receipt sum 80 <> invoice line 100)
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);
        Assert.ExpectedError('does not match the total quantity to invoice');

        // [WHEN] Correct Qty. to Invoice to 100 and Post
        MatchedOrderLine.Get(PurchaseLineInvoice.SystemId, PurchaseLineOrder.SystemId, PurchRcptLine.SystemId);
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine.Modify();

        // Re-get header after asserterror rollback to avoid stale record error
        PurchaseHeaderInvoice.Get(PurchaseHeaderInvoice."Document Type", PurchaseHeaderInvoice."No.");

        // [THEN] Posts successfully
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_InvoiceMoreThanReceived()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        TotalQuantity: Decimal;
        ReceivedQuantity: Decimal;
        InvoiceQuantity: Decimal;
    begin
        // [SCENARIO E2E-3.2] Invoice More Than Received
        Initialize();
        TotalQuantity := 100;
        ReceivedQuantity := 60;
        InvoiceQuantity := 80;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order Qty = 100, Receive Qty = 60 (partial)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        PurchaseLineOrder.Validate("Qty. to Receive", ReceivedQuantity);
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();
        Assert.AreEqual(ReceivedQuantity, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt should have 60 not invoiced');

        // [GIVEN] Create Invoice: Qty = 80 (exceeds received), Match with Qty. to Invoice = 80
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", InvoiceQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Create order-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQuantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQuantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match with qty = 80 (exceeds Qty. Rcd. Not Invoiced = 60)
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQuantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQuantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [WHEN] Attempt to Post Invoice
        // [THEN] Error: quantity to invoice exceeds quantity received not invoiced
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);
        Assert.ExpectedError('quantity to invoice for a matched receipt line exceeds the quantity received not invoiced');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_InvoiceDeletionCleansUpMatchedOrderLines()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        Quantity: Decimal;
        InvoiceLineSystemId: Guid;
    begin
        // [SCENARIO E2E-3.3] Deleting Invoice Cleans Up Matched Order Lines
        // A received-but-not-invoiced order cannot be deleted, so this tests
        // the invoice-side cleanup path: deleting the invoice removes all matches.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order, Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice with Match
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);
        InvoiceLineSystemId := PurchaseLineInvoice.SystemId;

        // Create order-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := InvoiceLineSystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := InvoiceLineSystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Verify matches exist before deletion
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLineSystemId);
        Assert.AreEqual(2, MatchedOrderLine.Count(), 'Should have 2 matched order lines before invoice deletion');

        // [WHEN] Delete the Purchase Invoice
        PurchaseHeaderInvoice.Get(PurchaseHeaderInvoice."Document Type", PurchaseHeaderInvoice."No.");
        PurchaseHeaderInvoice.Delete(true);

        // [THEN] All Matched Order Lines for this invoice should be cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLineSystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);

        // [THEN] Order line should no longer show as matched
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchaseLineOrder.CalcFields("Matched Order Lines");
        Assert.AreEqual(0, PurchaseLineOrder."Matched Order Lines", 'Order line should no longer be matched after invoice deletion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_OrderInvoicedAndDeletedCleansUpMatches()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        Quantity: Decimal;
        InvoiceLineSystemId: Guid;
        OrderLineSystemId: Guid;
    begin
        // [SCENARIO E2E-3.3b] Order Received, Invoice Matched, Then Order Invoiced Directly and Auto-Deleted
        // When the order is fully invoiced it auto-deletes; this must clean up
        // the Matched Order Lines that the separate invoice created.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order, Receive fully
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        OrderLineSystemId := PurchaseLineOrder.SystemId;
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create a separate Invoice and match it to the order/receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);
        InvoiceLineSystemId := PurchaseLineInvoice.SystemId;

        // Create order-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := InvoiceLineSystemId;
        MatchedOrderLine."Matched Order Line SystemId" := OrderLineSystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := InvoiceLineSystemId;
        MatchedOrderLine."Matched Order Line SystemId" := OrderLineSystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Verify matches exist
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Matched Order Line SystemId", OrderLineSystemId);
        Assert.AreEqual(2, MatchedOrderLine.Count(), 'Should have 2 matched order lines before order invoicing');

        // [WHEN] Invoice the order directly (fully received + fully invoiced = auto-delete)
        PurchaseHeaderOrder.Get(PurchaseHeaderOrder."Document Type", PurchaseHeaderOrder."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, false, true);

        // [THEN] Order should be auto-deleted (fully received and invoiced)
        Assert.IsFalse(
            PurchaseHeaderOrder.Get(PurchaseHeaderOrder."Document Type"::Order, PurchaseHeaderOrder."No."),
            'Order should be auto-deleted after full receipt and invoicing');

        // [THEN] Matched Order Lines for this order should be cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Matched Order Line SystemId", OrderLineSystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);

        // [THEN] The separate invoice line should no longer show as matched
        PurchaseLineInvoice.Get(PurchaseLineInvoice."Document Type", PurchaseLineInvoice."Document No.", PurchaseLineInvoice."Line No.");
        PurchaseLineInvoice.CalcFields("Matched Order Lines");
        Assert.AreEqual(0, PurchaseLineInvoice."Matched Order Lines", 'Invoice line should no longer be matched after order auto-deletion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_ReceiptOnInvoiceWithBlockedItemTracking()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Vendor: Record Vendor;
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-3.4] Receipt on Invoice with Blocked Item Tracking
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Create Item with Lot Tracking (Lot Specific = TRUE)
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Order with Receipt on Invoice = TRUE
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        PurchaseHeaderOrder.Validate("Receipt on Invoice", true);
        PurchaseHeaderOrder.Modify(true);

        // [WHEN] Add line with tracked item
        // [THEN] Error: Item tracking not supported with Receipt on Invoice
        asserterror LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        Assert.ExpectedError('specific tracking');
    end;


    [Test]
    [Scope('OnPrem')]
    procedure E2E_ReceiptOnInvoiceWithBlockedItemTrackingValidateHeader()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Vendor: Record Vendor;
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-3.4b] Receipt on Invoice with Blocked Item Tracking
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Create Item with Lot Tracking (Lot Specific = TRUE)
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Order with Receipt on Invoice = FALSE
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");

        // [THEN] Line added successfully
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // [WHEN] Attempt to enable Receipt on Invoice (line with tracked item exists)
        // [THEN] Error: Item tracking exists on line
        asserterror PurchaseHeaderOrder.Validate("Receipt on Invoice", true);
        Assert.ExpectedError('requires item tracking');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_ReceiptOnInvoiceWithWMSLocation()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        WMSLocation: Record Location;
        NormalLocation: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-3.5] Receipt on Invoice with WMS Location
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Create Location with Directed Put-away and Pick = TRUE
        LibraryWarehouse.CreateLocation(WMSLocation);
        WMSLocation."Directed Put-away and Pick" := true;
        WMSLocation.Modify();

        // [GIVEN] Create non-WMS location
        LibraryWarehouse.CreateLocation(NormalLocation);

        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Order with Receipt on Invoice = TRUE
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        PurchaseHeaderOrder.Validate("Receipt on Invoice", true);
        PurchaseHeaderOrder.Modify(true);

        // [WHEN] Add line with non-WMS Location
        // [THEN] Line validated successfully        
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Location Code", NormalLocation.Code);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // [WHEN] Use WMS location
        // [THEN] Error: Directed Put-away and Pick not supported
        asserterror PurchaseLineOrder.Validate("Location Code", WMSLocation.Code);
        Assert.ExpectedError('Directed Put-away and Pick');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_ConcurrentInvoicePostingSameOrder()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice1: Record "Purchase Header";
        PurchaseLineInvoice1: Record "Purchase Line";
        PurchaseHeaderInvoice2: Record "Purchase Header";
        PurchaseLineInvoice2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        TotalQuantity: Decimal;
        Invoice1Quantity: Decimal;
        Invoice2Quantity: Decimal;
    begin
        // [SCENARIO E2E-3.6] Concurrent Invoice Posting (Same Order)
        Initialize();
        TotalQuantity := 100;
        Invoice1Quantity := 60;
        Invoice2Quantity := 60;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order Qty = 100, Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice #1: Qty = 60, Match
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice1, PurchaseHeaderInvoice1."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice1, PurchaseHeaderInvoice1, PurchaseLineInvoice1.Type::Item, Item."No.", Invoice1Quantity);
        PurchaseLineInvoice1.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice1.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice1.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Invoice1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice1Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice1.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Invoice1Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice1Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [GIVEN] Create Invoice #2: Qty = 60, Match (overlap!)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice2, PurchaseHeaderInvoice2."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice2, PurchaseHeaderInvoice2, PurchaseLineInvoice2.Type::Item, Item."No.", Invoice2Quantity);
        PurchaseLineInvoice2.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice2.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice2.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Invoice2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice2Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice2.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Invoice2Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Invoice2Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [WHEN] Post Invoice #1
        // [THEN] Posts successfully, invoiced = 60
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice1, false, true);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Invoice1Quantity, PurchaseLineOrder."Quantity Invoiced", 'Order should have 60 invoiced after first invoice');

        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(TotalQuantity - Invoice1Quantity, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt should have 40 not invoiced');

        // [WHEN] Post Invoice #2 (tries to invoice 60, but only 40 remains)
        // [THEN] Error: Exceeds remaining qty (qty to invoice exceeds qty received not invoiced)
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice2, false, true);
        Assert.ExpectedError('quantity to invoice for a matched receipt line exceeds the quantity received not invoiced');
    end;

    // ============================================================================
    // REGION: E2E-4 Item Tracking Integration
    // ============================================================================

    [Test]
    [Scope('OnPrem')]
    procedure E2E_InvoiceWithLotTrackedReceipt()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        Vendor: Record Vendor;
        LotNo1: Code[50];
        LotNo2: Code[50];
        Qty1: Decimal;
        Qty2: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO E2E-4.1] Invoice with Lot-Tracked Receipt
        // Matched invoice posting correctly handles lot-tracked receipts.
        // Lots are assigned on order -> received -> matched invoice posted -> ILEs verified.
        Initialize();
        Qty1 := 60;
        Qty2 := 40;
        TotalQuantity := Qty1 + Qty2;
        LotNo1 := LibraryUtility.GenerateGUID();
        LotNo2 := LibraryUtility.GenerateGUID();

        // [GIVEN] Create Item with Lot Specific Tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Order Qty = 100, Assign Lot L1 = 60, Lot L2 = 40
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineOrder, '', LotNo1, Qty1);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineOrder, '', LotNo2, Qty2);

        // [GIVEN] Post Receive (Receipt with lots)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // Verify receipt ILEs have correct lots
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Lot No.", LotNo1);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Qty1, ItemLedgerEntry.Quantity, 'ILE for Lot 1 should have qty 60');
        Assert.AreEqual(0, ItemLedgerEntry."Invoiced Quantity", 'Lot 1 should not be invoiced yet');

        ItemLedgerEntry.SetRange("Lot No.", LotNo2);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Qty2, ItemLedgerEntry.Quantity, 'ILE for Lot 2 should have qty 40');
        Assert.AreEqual(0, ItemLedgerEntry."Invoiced Quantity", 'Lot 2 should not be invoiced yet');

        // Get order line and receipt line
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice Qty = 100 and Match to order/receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Create order-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := TotalQuantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := TotalQuantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := TotalQuantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := TotalQuantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create item tracking on invoice line (replicates CopyMatchedItemTrkgToPurchLine from UI matching flow)
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);

        ItemLedgerEntry.SetRange("Lot No.", LotNo1);
        ItemLedgerEntry.FindFirst();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineInvoice, '', LotNo1, Qty1);
        ReservationEntry.Validate("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify(true);

        ItemLedgerEntry.SetRange("Lot No.", LotNo2);
        ItemLedgerEntry.FindFirst();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineInvoice, '', LotNo2, Qty2);
        ReservationEntry.Validate("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify(true);

        // [WHEN] Post Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Item Ledger Entries have correct lots invoiced: L1 = 60, L2 = 40
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);

        ItemLedgerEntry.SetRange("Lot No.", LotNo1);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Qty1, ItemLedgerEntry."Invoiced Quantity", 'Lot 1 should be fully invoiced (60)');

        ItemLedgerEntry.SetRange("Lot No.", LotNo2);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Qty2, ItemLedgerEntry."Invoiced Quantity", 'Lot 2 should be fully invoiced (40)');

        // [THEN] Posted Matched Order Lines created
        PostedMatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder.SystemId);
        PostedMatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<>%1', EmptyGuid);
        Assert.AreEqual(1, PostedMatchedOrderLine.Count(), 'Should have 1 posted receipt-level match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_PartialInvoiceWithItemTracking()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice1: Record "Purchase Header";
        PurchaseLineInvoice1: Record "Purchase Line";
        PurchaseHeaderInvoice2: Record "Purchase Header";
        PurchaseLineInvoice2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        Vendor: Record Vendor;
        LotNo: Code[50];
        TotalQuantity: Decimal;
        InvoiceQty1: Decimal;
        InvoiceQty2: Decimal;
    begin
        // [SCENARIO E2E-4.2] Partial Invoice with Item Tracking
        // Two partial matched invoices against a single lot-tracked receipt.
        Initialize();
        TotalQuantity := 100;
        InvoiceQty1 := 40;
        InvoiceQty2 := 60;
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create Item with Lot Specific Tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Order Qty = 100, Assign Lot, Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineOrder, '', LotNo, TotalQuantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice #1 Qty = 40, Match
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice1, PurchaseHeaderInvoice1."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice1, PurchaseHeaderInvoice1, PurchaseLineInvoice1.Type::Item, Item."No.", InvoiceQty1);
        PurchaseLineInvoice1.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice1.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice1.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQty1;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQty1;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice1.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQty1;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQty1;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create item tracking on invoice line
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.FindFirst();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineInvoice1, '', LotNo, InvoiceQty1);
        ReservationEntry.Validate("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify(true);

        // [WHEN] Post Invoice #1
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice1, false, true);

        // [THEN] ILE: Lot invoiced qty = 40 (partial)
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(TotalQuantity, ItemLedgerEntry.Quantity, 'ILE quantity should be full 100');
        Assert.AreEqual(InvoiceQty1, ItemLedgerEntry."Invoiced Quantity", 'After first invoice, 40 should be invoiced');

        // Verify Receipt Qty. Rcd. Not Invoiced
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(InvoiceQty2, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt should have 60 not invoiced after first invoice');

        // [GIVEN] Create Invoice #2 Qty = 60, Match
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice2, PurchaseHeaderInvoice2."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice2, PurchaseHeaderInvoice2, PurchaseLineInvoice2.Type::Item, Item."No.", InvoiceQty2);
        PurchaseLineInvoice2.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice2.Modify(true);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice2.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQty2;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQty2;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice2.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQty2;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQty2;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create item tracking on invoice line
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.FindFirst();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineInvoice2, '', LotNo, InvoiceQty2);
        ReservationEntry.Validate("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify(true);

        // [WHEN] Post Invoice #2
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice2, false, true);

        // [THEN] ILE: Lot fully invoiced (100)
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(TotalQuantity, ItemLedgerEntry.Quantity, 'ILE quantity should be 100');
        Assert.AreEqual(TotalQuantity, ItemLedgerEntry."Invoiced Quantity", 'After second invoice, all 100 should be invoiced');

        // [THEN] Receipt should be fully invoiced
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt should be fully invoiced');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_InvoiceWithSerialTrackedReceipt()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        Vendor: Record Vendor;
        SerialNo: array[3] of Code[50];
        TotalQuantity: Decimal;
        i: Integer;
    begin
        // [SCENARIO E2E-4.3] Invoice with Serial-Tracked Receipt
        // Matched invoice posting correctly handles serial-tracked receipts.
        // Serial numbers assigned on order -> received -> matched invoice posted -> ILEs verified.
        Initialize();
        TotalQuantity := 3;
        for i := 1 to 3 do
            SerialNo[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Create Item with SN Specific Tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Order Qty = 3, Assign SN1, SN2, SN3 (each qty = 1)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        for i := 1 to 3 do
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineOrder, SerialNo[i], '', 1);

        // [GIVEN] Post Receive
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // Verify receipt ILEs: 3 entries, one per serial, each qty = 1, not invoiced
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        Assert.AreEqual(3, ItemLedgerEntry.Count(), 'Should have 3 ILEs (one per SN)');
        for i := 1 to 3 do begin
            ItemLedgerEntry.SetRange("Serial No.", SerialNo[i]);
            ItemLedgerEntry.FindFirst();
            Assert.AreEqual(1, ItemLedgerEntry.Quantity, StrSubstNo('ILE for SN%1 should have qty 1', i));
            Assert.AreEqual(0, ItemLedgerEntry."Invoiced Quantity", StrSubstNo('SN%1 should not be invoiced yet', i));
        end;

        // Get order line and receipt line
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice Qty = 3 and Match to order/receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Create order-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := TotalQuantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := TotalQuantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create receipt-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := TotalQuantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := TotalQuantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create item tracking on invoice line
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        for i := 1 to 3 do begin
            ItemLedgerEntry.SetRange("Serial No.", SerialNo[i]);
            ItemLedgerEntry.FindFirst();
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineInvoice, SerialNo[i], '', 1);
            ReservationEntry.Validate("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
            ReservationEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
            ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
            ReservationEntry.Modify(true);
        end;

        // [WHEN] Post Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] All 3 ILEs fully invoiced with correct serial numbers
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        for i := 1 to 3 do begin
            ItemLedgerEntry.SetRange("Serial No.", SerialNo[i]);
            ItemLedgerEntry.FindFirst();
            Assert.AreEqual(1, ItemLedgerEntry."Invoiced Quantity", StrSubstNo('SN%1 should be fully invoiced', i));
        end;

        // [THEN] Posted Matched Order Lines created
        PostedMatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder.SystemId);
        PostedMatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<>%1', EmptyGuid);
        Assert.AreEqual(1, PostedMatchedOrderLine.Count(), 'Should have 1 posted receipt-level match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_PartialInvoiceWithSerialTracking()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice1: Record "Purchase Header";
        PurchaseLineInvoice1: Record "Purchase Line";
        PurchaseHeaderInvoice2: Record "Purchase Header";
        PurchaseLineInvoice2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        Vendor: Record Vendor;
        SerialNo: array[4] of Code[50];
        TotalQuantity: Decimal;
        InvoiceQty1: Decimal;
        InvoiceQty2: Decimal;
        i: Integer;
    begin
        // [SCENARIO E2E-4.4] Partial Invoice with Serial Tracking
        // Two partial matched invoices against serial-tracked receipts.
        // 4 serial units: Invoice #1 covers 2, Invoice #2 covers remaining 2.
        Initialize();
        TotalQuantity := 4;
        InvoiceQty1 := 2;
        InvoiceQty2 := 2;
        for i := 1 to 4 do
            SerialNo[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Create Item with SN Specific Tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Order Qty = 4, Assign 4 serial numbers, Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        for i := 1 to 4 do
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineOrder, SerialNo[i], '', 1);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice #1 Qty = 2, Match
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice1, PurchaseHeaderInvoice1."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice1, PurchaseHeaderInvoice1, PurchaseLineInvoice1.Type::Item, Item."No.", InvoiceQty1);
        PurchaseLineInvoice1.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice1.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice1.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQty1;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQty1;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice1.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQty1;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQty1;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create item tracking on invoice line (SN1, SN2 -> Invoice #1)
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        for i := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Serial No.", SerialNo[i]);
            ItemLedgerEntry.FindFirst();
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineInvoice1, SerialNo[i], '', 1);
            ReservationEntry.Validate("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
            ReservationEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
            ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
            ReservationEntry.Modify(true);
        end;

        // [WHEN] Post Invoice #1
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice1, false, true);

        // [THEN] 2 of 4 ILEs should be invoiced
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Invoiced Quantity", 1);
        Assert.AreEqual(2, ItemLedgerEntry.Count(), 'After first invoice, 2 ILEs should be invoiced');

        ItemLedgerEntry.SetRange("Invoiced Quantity", 0);
        Assert.AreEqual(2, ItemLedgerEntry.Count(), 'After first invoice, 2 ILEs should remain uninvoiced');

        // Verify Receipt Qty. Rcd. Not Invoiced
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(InvoiceQty2, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt should have 2 not invoiced after first invoice');

        // [GIVEN] Create Invoice #2 Qty = 2, Match
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice2, PurchaseHeaderInvoice2."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice2, PurchaseHeaderInvoice2, PurchaseLineInvoice2.Type::Item, Item."No.", InvoiceQty2);
        PurchaseLineInvoice2.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice2.Modify(true);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice2.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQty2;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQty2;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice2.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQty2;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQty2;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Create item tracking on invoice line (SN3, SN4 -> Invoice #2)
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        for i := 3 to 4 do begin
            ItemLedgerEntry.SetRange("Serial No.", SerialNo[i]);
            ItemLedgerEntry.FindFirst();
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLineInvoice2, SerialNo[i], '', 1);
            ReservationEntry.Validate("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
            ReservationEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
            ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
            ReservationEntry.Modify(true);
        end;

        // [WHEN] Post Invoice #2
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice2, false, true);

        // [THEN] All 4 ILEs fully invoiced
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        Assert.AreEqual(4, ItemLedgerEntry.Count(), 'Should have 4 ILEs total');
        for i := 1 to 4 do begin
            ItemLedgerEntry.SetRange("Serial No.", SerialNo[i]);
            ItemLedgerEntry.FindFirst();
            Assert.AreEqual(1, ItemLedgerEntry."Invoiced Quantity", StrSubstNo('SN%1 should be fully invoiced', i));
        end;

        // [THEN] Receipt should be fully invoiced
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt should be fully invoiced');
    end;

    // ============================================================================
    // REGION: E2E-5 Financial Verification
    // ============================================================================

    [Test]
    [Scope('OnPrem')]
    procedure E2E_VerifyGLEntriesForMatchedInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        MatchedOrderLine: Record "Matched Order Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
        UnitCost: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
    begin
        // [SCENARIO E2E-5.1] Verify G/L Entries for Matched Invoice
        // Receive-first flow: verify GL entries, Value Entries, and Vendor Ledger Entry.
        Initialize();
        Quantity := 10;
        UnitCost := 100;
        TotalAmount := Quantity * UnitCost;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order: Qty = 10, Unit Cost = 100
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", UnitCost);
        PurchaseLineOrder.Modify(true);

        // [GIVEN] Post Receive
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // Verify: Value Entry with Expected Cost created on receipt
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.FindFirst();
        Assert.AreEqual(TotalAmount, ValueEntry."Cost Amount (Expected)", 'Receipt Value Entry should have Expected Cost = 1,000');
        Assert.AreEqual(0, ValueEntry."Cost Amount (Actual)", 'Receipt Value Entry should have no Actual Cost yet');

        // [GIVEN] Create Invoice, Match, and Post
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", UnitCost);
        PurchaseLineInvoice.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [WHEN] Post Invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // Get posted invoice amounts (includes VAT)
        PurchInvHeader.Get(PostedInvoiceNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        TotalAmountInclVAT := PurchInvHeader."Amount Including VAT";

        // [THEN] Vendor Ledger Entry created with correct amount (incl. VAT)
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostedInvoiceNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreEqual(-TotalAmountInclVAT, VendorLedgerEntry."Amount (LCY)", 'Vendor Ledger Entry should equal Amount Including VAT');

        // [THEN] GL Entry on Payables Account = -TotalAmountInclVAT (credit = payable incl. VAT)
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLEntry.SetRange("Document No.", PostedInvoiceNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Payables Account");
        GLEntry.FindFirst();
        Assert.AreEqual(-TotalAmountInclVAT, GLEntry.Amount, 'Payables Account GL Entry should equal Amount Including VAT');

        // [THEN] GL Entry on Purchase Account = +TotalAmount (debit = cost recorded)
        GeneralPostingSetup.Get(PurchaseLineOrder."Gen. Bus. Posting Group", PurchaseLineOrder."Gen. Prod. Posting Group");
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Purch. Account");
        GLEntry.FindFirst();
        Assert.AreEqual(TotalAmount, GLEntry.Amount, 'Purchase Account GL Entry should be +1,000');

        // [THEN] Value Entry updated: Expected Cost reversed, Actual Cost recorded
        ValueEntry.Reset();
        ValueEntry.SetRange("Document No.", PostedInvoiceNo);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.FindFirst();
        Assert.AreEqual(TotalAmount, ValueEntry."Cost Amount (Actual)", 'Invoice Value Entry should have Actual Cost = 1,000');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_VerifyGLForReceiptOnInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        MatchedOrderLine: Record "Matched Order Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        GLEntry: Record "G/L Entry";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
        UnitCost: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalExpectedCost: Decimal;
        TotalActualCost: Decimal;
    begin
        // [SCENARIO E2E-5.2] Verify G/L for Receipt on Invoice
        // Auto-receipt flow: single posting creates receipt + invoice. Verify financial equivalence.
        Initialize();
        Quantity := 10;
        UnitCost := 100;
        TotalAmount := Quantity * UnitCost;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order with Receipt on Invoice: Qty = 10, Unit Cost = 100
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", UnitCost);
        PurchaseLineOrder.Modify(true);

        PurchaseHeaderOrder.Validate("Receipt on Invoice", true);
        PurchaseHeaderOrder.Modify(true);

        // [GIVEN] Create Invoice, Match (Receipt on Invoice = TRUE)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", UnitCost);
        PurchaseLineInvoice.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := true;
        MatchedOrderLine.Insert();

        // [WHEN] Post Invoice (auto-receipt + invoice)
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // Get posted invoice amounts (includes VAT)
        PurchInvHeader.Get(PostedInvoiceNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        TotalAmountInclVAT := PurchInvHeader."Amount Including VAT";

        // [THEN] Item Ledger Entry created (Positive - Inventory received)
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'ILE should have received quantity = 10');
        Assert.AreEqual(Quantity, ItemLedgerEntry."Invoiced Quantity", 'ILE should be fully invoiced = 10');

        // [THEN] Value Entries: both Expected and Actual cost entries
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.FindSet();
        repeat
            TotalExpectedCost += ValueEntry."Cost Amount (Expected)";
            TotalActualCost += ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;
        // Expected cost is posted then reversed (net = 0), Actual cost = TotalAmount
        Assert.AreEqual(0, TotalExpectedCost, 'Net Expected Cost should be 0 (posted and reversed in same transaction)');
        Assert.AreEqual(TotalAmount, TotalActualCost, 'Total Actual Cost should be 1,000');

        // [THEN] Vendor Ledger Entry created with correct payable amount (incl. VAT)
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostedInvoiceNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreEqual(-TotalAmountInclVAT, VendorLedgerEntry."Amount (LCY)", 'Vendor Ledger Entry should equal Amount Including VAT');

        // [THEN] GL Entry on Payables Account = -TotalAmountInclVAT
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLEntry.SetRange("Document No.", PostedInvoiceNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Payables Account");
        GLEntry.FindFirst();
        Assert.AreEqual(-TotalAmountInclVAT, GLEntry.Amount, 'Payables Account GL Entry should equal Amount Including VAT');

        // [THEN] GL Entry on Purchase Account = +TotalAmount
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        GeneralPostingSetup.Get(PurchaseLineOrder."Gen. Bus. Posting Group", PurchaseLineOrder."Gen. Prod. Posting Group");
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Purch. Account");
        GLEntry.FindFirst();
        Assert.AreEqual(TotalAmount, GLEntry.Amount, 'Purchase Account GL Entry should be +1,000');

        // [THEN] Receipt was auto-created
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();
        Assert.AreEqual(Quantity, PurchRcptLine.Quantity, 'Auto-created receipt should have qty = 10');
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt should be fully invoiced');
    end;

    // ============================================================================
    // REGION: E2E-6 Document Modifications During Matching
    // ============================================================================

    [Test]
    [Scope('OnPrem')]
    procedure E2E_ModifyInvoiceLineAfterMatching()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        Vendor: Record Vendor;
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-6.1] Modify Invoice Line After Matching
        // Matched invoice line cannot be modified (No., Variant Code).
        // After deleting match, modifications are allowed and re-matching succeeds.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 50);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Order, Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice, Match to Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        Commit();

        // [WHEN] Try to change No. on matched invoice line
        // [THEN] Error: Line is matched to an order line
        PurchaseLineInvoice.Get(PurchaseLineInvoice."Document Type", PurchaseLineInvoice."Document No.", PurchaseLineInvoice."Line No.");
        asserterror PurchaseLineInvoice.Validate("No.", Item2."No.");
        Assert.ExpectedError('matched to an order line and cannot be modified');

        // [WHEN] Try to change Variant Code on matched invoice line
        // [THEN] Error: Line is matched to an order line
        PurchaseLineInvoice.Get(PurchaseLineInvoice."Document Type", PurchaseLineInvoice."Document No.", PurchaseLineInvoice."Line No.");
        asserterror PurchaseLineInvoice.Validate("Variant Code", ItemVariant.Code);
        Assert.ExpectedError('matched to an order line and cannot be modified');

        // [WHEN] Delete match records
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        MatchedOrderLine.DeleteAll();

        // [THEN] Modification allowed - changing No. succeeds
        PurchaseLineInvoice.Get(PurchaseLineInvoice."Document Type", PurchaseLineInvoice."Document No.", PurchaseLineInvoice."Line No.");
        PurchaseLineInvoice.Validate("No.", Item2."No.");
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Validate(Quantity, Quantity);
        PurchaseLineInvoice.Modify(true);

        // [WHEN] Re-match to order
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [THEN] New match created
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.AreEqual(1, MatchedOrderLine.Count(), 'New match should be created after re-matching');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_ModifyOrderLineAfterBeingMatched()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Vendor: Record Vendor;
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-6.2] Modify Order Line After Being Matched
        // Matched order line cannot be modified (Variant Code).
        // After deleting match, modifications are allowed.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 50);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Order (no receipt - so Qty. Rcd. Not Invoiced = 0)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // [GIVEN] Create Invoice, Match to Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // [THEN] Matched Inv./Cr. Memo Lines = 1 on order line
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchaseLineOrder.CalcFields("Matched Inv./Cr. Memo Lines");
        Assert.AreEqual(1, PurchaseLineOrder."Matched Inv./Cr. Memo Lines", 'Order line should show 1 matched invoice line');

        Commit();

        // [WHEN] Try to change Variant Code on matched order line
        // [THEN] Error: Line is matched to an invoice line
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        asserterror PurchaseLineOrder.Validate("Variant Code", ItemVariant.Code);
        Assert.ExpectedError('matched to an invoice line and cannot be modified');

        // [WHEN] Delete match records
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder.SystemId);
        MatchedOrderLine.DeleteAll();

        // [THEN] Matched Inv./Cr. Memo Lines = 0 after deletion
        PurchaseLineOrder.CalcFields("Matched Inv./Cr. Memo Lines");
        Assert.AreEqual(0, PurchaseLineOrder."Matched Inv./Cr. Memo Lines", 'Order line should show 0 matched invoice lines after deletion');

        // [THEN] Order line is editable - validate Unit of Measure Code succeeds without error
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchaseLineOrder.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost" + 1);
        PurchaseLineOrder.Modify(true);
    end;

    // ============================================================================
    // REGION: E2E-7 Report and Inquiry Verification
    // ============================================================================

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure E2E_PurchaseDocumentTestReportWithMatchedLines()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        RequestPageXML: Text;
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-7.1] Purchase Document - Test Report with matched lines
        // Report runs without errors for matched invoice and treats matched line as having receipt coverage.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 50);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order, Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice, Match to Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        Commit();

        // [WHEN] Run Purchase Document - Test report
        RequestPageXML := Report.RunRequestPage(Report::"Purchase Document - Test", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Purchase Document - Test", PurchaseHeaderInvoice, RequestPageXML);

        // [THEN] Report shows the invoice line without errors
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line___No__', Item."No.");
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line__Quantity', Quantity);
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line___Qty__to_Invoice_', Quantity);

        // [THEN] No error lines in the report (matched line passes validation - no "Qty. to Receive" error)
        LibraryReportDataset.AssertElementWithValueNotExist('ErrorText_Number__Control103', 'Qty. to Receive');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_NavigateFromPostedInvoiceToSourceDocuments()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-7.2] Navigate from Posted Invoice to Source Documents
        // After posting matched invoice, Posted Matched Order Lines contain correct
        // references to order and receipt, enabling navigation from posted invoice.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 50);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Order, Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice, Match to Order, Post
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Posted Purch. Invoice Line has Matched Order Lines = 1 (order-level match, receipt-level match)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();
        PurchInvLine.CalcFields("Matched Order Lines");
        Assert.AreEqual(1, PurchInvLine."Matched Order Lines", 'Posted invoice line should show 1 matched order line');

        // [THEN] Posted Matched Order Line records created with correct references
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Should have 2 Posted Matched Order Lines (1 order-level + 1 receipt-level)');

        // [THEN] Order-level match: points to order line, no receipt reference
        PostedMatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        PostedMatchedOrderLine.FindFirst();
        Assert.AreEqual(PurchaseLineOrder.SystemId, PostedMatchedOrderLine."Matched Order Line SystemId",
            'Order-level posted match should reference the original order line');
        Assert.AreEqual(Quantity, PostedMatchedOrderLine."Qty. Invoiced", 'Order-level posted match should have correct invoiced qty');

        // [THEN] Receipt-level match: points to order line and receipt line
        PostedMatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<>%1', EmptyGuid);
        PostedMatchedOrderLine.FindFirst();
        Assert.AreEqual(PurchaseLineOrder.SystemId, PostedMatchedOrderLine."Matched Order Line SystemId",
            'Receipt-level posted match should reference the original order line');
        Assert.AreEqual(PurchRcptLine.SystemId, PostedMatchedOrderLine."Matched Rcpt./Shpt. Line SysId",
            'Receipt-level posted match should reference the receipt line');
        Assert.AreEqual(Quantity, PostedMatchedOrderLine."Qty. Invoiced", 'Receipt-level posted match should have correct invoiced qty');

        // [THEN] Original Matched Order Lines cleaned up (moved to Posted)
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    // ============================================================================
    // REGION: E2E-8 Undo and Correction Scenarios
    // ============================================================================

    [Test]
    [Scope('OnPrem')]
    procedure E2E_UndoReceiptAfterPartialInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        UndoPurchRcptLine: Codeunit "Undo Purchase Receipt Line";
        OrderQuantity: Decimal;
        InvoiceQuantity: Decimal;
    begin
        // [SCENARIO E2E-8.1] Undo Receipt After Partial Invoice Through Matched Lines
        // When an order has been partially invoiced through a matched invoice,
        // the receipt line cannot be undone because some quantity has been invoiced.
        Initialize();
        OrderQuantity := 10;
        InvoiceQuantity := 4;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order Qty = 10 and Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", OrderQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // Refresh order line and find receipt
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice Qty = 4, Match to Order, Post (Partial invoice)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", InvoiceQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Match invoice to order (order-level)
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQuantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQuantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Match invoice to order (receipt-level)
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := InvoiceQuantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := InvoiceQuantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Receipt Qty. Rcd. Not Invoiced = 6 (OrderQuantity - InvoiceQuantity)
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(
            OrderQuantity - InvoiceQuantity, PurchRcptLine."Qty. Rcd. Not Invoiced",
            'Receipt Qty. Rcd. Not Invoiced should be reduced by invoiced quantity');

        // [WHEN] Attempt Undo Receipt for full qty
        Commit();
        PurchRcptLine.SetRecFilter();
        UndoPurchRcptLine.SetHideDialog(true);
        asserterror UndoPurchRcptLine.Run(PurchRcptLine);

        // [THEN] Error: receipt has already been invoiced
        Assert.ExpectedError('This receipt has already been invoiced');

        // [THEN] Receipt line is unchanged after failed undo
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(OrderQuantity, PurchRcptLine.Quantity, 'Receipt Quantity should be unchanged');
        Assert.AreEqual(
            OrderQuantity - InvoiceQuantity, PurchRcptLine."Qty. Rcd. Not Invoiced",
            'Receipt Qty. Rcd. Not Invoiced should be unchanged after failed undo');
        Assert.IsFalse(PurchRcptLine.Correction, 'Receipt should not be marked as Correction');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure E2E_CreditMemoAgainstMatchedInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Item: Record Item;
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-8.2] Credit Memo Against Matched Invoice
        // After posting a matched invoice, creating a credit memo by copying from
        // the posted invoice and posting it should create the credit memo while
        // the posted matched order line records persist as historical data.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 50);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Complete E2E-1.1: Order → Receive → Invoice → Match → Post
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Order-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := EmptyGuid;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        // Receipt-level match
        MatchedOrderLine.Init();
        MatchedOrderLine."Document Line SystemId" := PurchaseLineInvoice.SystemId;
        MatchedOrderLine."Matched Order Line SystemId" := PurchaseLineOrder.SystemId;
        MatchedOrderLine."Matched Rcpt./Shpt. Line SysId" := PurchRcptLine.SystemId;
        MatchedOrderLine."Qty. to Invoice" := Quantity;
        MatchedOrderLine."Qty. to Invoice (Base)" := Quantity;
        MatchedOrderLine."Receipt on Invoice" := false;
        MatchedOrderLine.Insert();

        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // Verify posted invoice and posted matched order lines
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Should have 2 posted matched order line records after posting');

        // [GIVEN] Create Purchase Credit Memo and copy lines from Posted Invoice
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeaderCrMemo, PurchaseHeaderCrMemo."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeaderCrMemo.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeaderCrMemo.Modify(true);

        LibraryPurchase.CopyPurchaseDocument(
            PurchaseHeaderCrMemo,
            "Purchase Document Type From"::"Posted Invoice",
            PostedInvoiceNo,
            false,
            false);

        // [WHEN] Post the Credit Memo
        PostedCrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, false, true);

        // [THEN] Posted Credit Memo exists with correct item and quantity
        PurchCrMemoHdr.Get(PostedCrMemoNo);
        Assert.AreEqual(Vendor."No.", PurchCrMemoHdr."Buy-from Vendor No.", 'Credit memo vendor should match');

        PurchCrMemoLine.SetRange("Document No.", PostedCrMemoNo);
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::Item);
        PurchCrMemoLine.FindFirst();
        Assert.AreEqual(Item."No.", PurchCrMemoLine."No.", 'Credit memo line item should match');
        Assert.AreEqual(Quantity, PurchCrMemoLine.Quantity, 'Credit memo quantity should match invoice quantity');

        // [THEN] Vendor Ledger Entry for credit memo exists
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.SetRange("Document No.", PostedCrMemoNo);
        Assert.RecordIsNotEmpty(VendorLedgerEntry);

        // [THEN] Posted Matched Order Line records persist (historical data, not deleted by credit memo)
        PostedMatchedOrderLine.Reset();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Posted matched order line records should persist after credit memo');
    end;

    // ============================================================================
    // REGION: E2E-9 UI (TestPage) Scenarios
    // Replicates E2E-1 scenarios with matching done through Purchase Invoice UI
    // ============================================================================

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_E2E_SingleOrderSingleReceiptFullInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-9.1] Single Order, Single Receipt, Full Invoice - matched through UI
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order and Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [WHEN] Open Purchase Invoice, navigate to line, invoke Matched Order Lines and select order
        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(0); // No qty adjustment needed - full invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [THEN] Matched Order Lines count = 1 on the invoice line
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Posted Matched Order Lines created
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.RecordIsNotEmpty(PostedMatchedOrderLine);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Should have 2 posted matched order line records (1 order-level + 1 receipt-level)');

        // [THEN] Matched Order Lines cleaned up from Matched Order Lines 
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);

        // [THEN] Order line fully invoiced
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Quantity, PurchaseLineOrder."Quantity Invoiced", 'Order line Quantity Invoiced should match');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order line Qty. to Invoice should be 0');

        // [THEN] Receipt line fully invoiced
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt Qty. Rcd. Not Invoiced should be 0');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_E2E_SingleOrderPartialInvoiceMultipleInvoices()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice1: Record "Purchase Header";
        PurchaseLineInvoice1: Record "Purchase Line";
        PurchaseHeaderInvoice2: Record "Purchase Header";
        PurchaseLineInvoice2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo1: Code[20];
        PostedInvoiceNo2: Code[20];
        TotalQuantity: Decimal;
        Invoice1Quantity: Decimal;
        Invoice2Quantity: Decimal;
    begin
        // [SCENARIO E2E-9.2] Single Order, Partial Invoice (Multiple Invoices) - matched through UI
        Initialize();
        TotalQuantity := 100;
        Invoice1Quantity := 40;
        Invoice2Quantity := 60;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order and Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice #1 (Qty = 40), match through UI, post
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice1, PurchaseHeaderInvoice1."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice1, PurchaseHeaderInvoice1, PurchaseLineInvoice1.Type::Item, Item."No.", Invoice1Quantity);
        PurchaseLineInvoice1.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice1.Modify(true);

        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(Invoice1Quantity); // Adjust receipt-level Qty. to Invoice to partial qty (40)
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice1);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        PostedInvoiceNo1 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice1, false, true);

        // [THEN] After Invoice #1: Order Qty Invoiced = 40, Receipt Qty Rcd Not Invoiced = 60
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Invoice1Quantity, PurchaseLineOrder."Quantity Invoiced", 'After Invoice #1: Quantity Invoiced should be 40');
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(Invoice2Quantity, PurchRcptLine."Qty. Rcd. Not Invoiced", 'After Invoice #1: Qty. Rcd. Not Invoiced should be 60');

        // [GIVEN] Create Invoice #2 (Qty = 60), match through UI, post
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice2, PurchaseHeaderInvoice2."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice2, PurchaseHeaderInvoice2, PurchaseLineInvoice2.Type::Item, Item."No.", Invoice2Quantity);
        PurchaseLineInvoice2.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice2.Modify(true);

        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(0); // No adjustment - remaining receipt qty (60) matches invoice qty
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice2);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        PostedInvoiceNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice2, false, true);

        // [THEN] Order fully invoiced
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Invoiced", 'Order Quantity Invoiced should be 100');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order Qty. to Invoice should be 0');

        // [THEN] Receipt fully invoiced
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt Qty. Rcd. Not Invoiced should be 0');

        // [THEN] Both posted invoices have posted matched order lines
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo1);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #1 should have 2 posted matched order line records');

        PurchInvLine.SetRange("Document No.", PostedInvoiceNo2);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #2 should have 2 posted matched order line records');

        // [THEN] All pre-posting matched order lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_E2E_SingleOrderMultipleReceiptsSingleInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine1: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo: Code[20];
        TotalQuantity: Decimal;
        Receipt1Quantity: Decimal;
        Receipt2Quantity: Decimal;
    begin
        // [SCENARIO E2E-9.3] Single Order, Multiple Receipts, Single Invoice - matched through UI
        Initialize();
        TotalQuantity := 100;
        Receipt1Quantity := 30;
        Receipt2Quantity := 70;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // [GIVEN] Receive Qty = 30 (Receipt #1)
        PurchaseLineOrder.Validate("Qty. to Receive", Receipt1Quantity);
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine1.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine1.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine1.FindFirst();

        // [GIVEN] Receive Qty = 70 (Receipt #2)
        PurchaseHeaderOrder.Get(PurchaseHeaderOrder."Document Type", PurchaseHeaderOrder."No.");
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchaseLineOrder.Validate("Qty. to Receive", Receipt2Quantity);
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine2.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine2.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine2.SetFilter("Document No.", '<>%1', PurchRcptLine1."Document No.");
        PurchRcptLine2.FindFirst();

        // [GIVEN] Create Purchase Invoice (Qty = 100)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [WHEN] Match through UI (GetOrderLines selects the single order, auto-creates matches for both receipts)
        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(0); // No qty adjustment - total receipt qty (30+70) matches invoice qty
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [THEN] Matched Order Lines = 1 on the invoice line
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] 3 Posted Matched Order Lines (1 order-level + 2 receipt-level)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(3, PostedMatchedOrderLine.Count(), 'Should have 3 posted matched order line records (1 order + 2 receipts)');

        // [THEN] Both receipt lines fully invoiced
        PurchRcptLine1.Get(PurchRcptLine1."Document No.", PurchRcptLine1."Line No.");
        Assert.AreEqual(0, PurchRcptLine1."Qty. Rcd. Not Invoiced", 'Receipt #1 Qty. Rcd. Not Invoiced should be 0');
        PurchRcptLine2.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No.");
        Assert.AreEqual(0, PurchRcptLine2."Qty. Rcd. Not Invoiced", 'Receipt #2 Qty. Rcd. Not Invoiced should be 0');

        // [THEN] Order line fully invoiced
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Invoiced", 'Order Quantity Invoiced should be 100');

        // [THEN] All matched order lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_E2E_MultipleOrdersSingleInvoice()
    var
        PurchaseHeaderOrder1: Record "Purchase Header";
        PurchaseLineOrder1: Record "Purchase Line";
        PurchaseHeaderOrder2: Record "Purchase Header";
        PurchaseLineOrder2: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine1: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo: Code[20];
        Order1Quantity: Decimal;
        Order2Quantity: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO E2E-9.4] Multiple Orders, Single Invoice - matched through UI
        Initialize();
        Order1Quantity := 50;
        Order2Quantity := 50;
        TotalQuantity := Order1Quantity + Order2Quantity;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Receive Order #1
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder1, PurchaseHeaderOrder1."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder1, PurchaseHeaderOrder1, PurchaseLineOrder1.Type::Item, Item."No.", Order1Quantity);
        PurchaseLineOrder1.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder1.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder1, true, false);

        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine1.SetRange("Order No.", PurchaseLineOrder1."Document No.");
        PurchRcptLine1.SetRange("Order Line No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine1.FindFirst();

        // [GIVEN] Create and Receive Order #2
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder2, PurchaseHeaderOrder2."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder2, PurchaseHeaderOrder2, PurchaseLineOrder2.Type::Item, Item."No.", Order2Quantity);
        PurchaseLineOrder2.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineOrder2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder2, true, false);

        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.SetRange("Order No.", PurchaseLineOrder2."Document No.");
        PurchRcptLine2.SetRange("Order Line No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.FindFirst();

        // [GIVEN] Create Purchase Invoice (Qty = 100)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [WHEN] Match through UI - first invocation selects Order #1
        LibraryVariableStorage.Enqueue(PurchaseLineOrder1."Document No.");
        LibraryVariableStorage.Enqueue(0); // No qty adjustment - Order #1 receipt qty (50) fits within invoice qty (100)
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [WHEN] Match through UI - second invocation selects Order #2
        LibraryVariableStorage.Enqueue(PurchaseLineOrder2."Document No.");
        LibraryVariableStorage.Enqueue(0); // No qty adjustment - Order #2 receipt qty (50) fills remaining
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [THEN] Matched Order Lines = 2 on the invoice line (2 separate orders)
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(2);
        PurchaseInvoice.Close();

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] 4 Posted Matched Order Lines (2 order-level + 2 receipt-level)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(4, PostedMatchedOrderLine.Count(), 'Should have 4 posted matched order line records (2 orders + 2 receipts)');

        // [THEN] Both orders fully invoiced
        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        Assert.AreEqual(Order1Quantity, PurchaseLineOrder1."Quantity Invoiced", 'Order #1 Quantity Invoiced should be 50');
        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        Assert.AreEqual(Order2Quantity, PurchaseLineOrder2."Quantity Invoiced", 'Order #2 Quantity Invoiced should be 50');

        // [THEN] Both receipt lines fully invoiced
        PurchRcptLine1.Get(PurchRcptLine1."Document No.", PurchRcptLine1."Line No.");
        Assert.AreEqual(0, PurchRcptLine1."Qty. Rcd. Not Invoiced", 'Receipt #1 Qty. Rcd. Not Invoiced should be 0');
        PurchRcptLine2.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No.");
        Assert.AreEqual(0, PurchRcptLine2."Qty. Rcd. Not Invoiced", 'Receipt #2 Qty. Rcd. Not Invoiced should be 0');

        // [THEN] All matched order lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_E2E_SingleOrderDifferentPurchUoM()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
        QtyPerUoM: Decimal;
    begin
        // [SCENARIO E2E-9.5] Single Order, Single Receipt, Full Invoice - item base UoM differs from purchase UoM
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 20);
        QtyPerUoM := LibraryRandom.RandIntInRange(2, 10);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a purchase UoM different from the base UoM (e.g. BOX = 6 PCS)
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, QtyPerUoM);
        Item.Validate("Purch. Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Create Purchase Order using purchase UoM and Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // Verify purchase line uses the purchase UoM
        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineOrder."Unit of Measure Code", 'Purchase line should use Purch. Unit of Measure');
        Assert.AreEqual(Quantity * QtyPerUoM, PurchaseLineOrder."Quantity (Base)", 'Quantity (Base) should be Qty * Qty per UoM');

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Purchase Invoice with same purchase UoM and quantity
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Verify invoice line also uses purchase UoM
        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineInvoice."Unit of Measure Code", 'Invoice line should use Purch. Unit of Measure');
        Assert.AreEqual(Quantity * QtyPerUoM, PurchaseLineInvoice."Quantity (Base)", 'Invoice Quantity (Base) should be Qty * Qty per UoM');

        // [WHEN] Match through UI
        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(0);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [THEN] Matched Order Lines = 1
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Posted Matched Order Lines created
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Should have 2 posted matched order lines (1 order + 1 receipt)');

        // [THEN] Matched Order Lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);

        // [THEN] Order line fully invoiced (in purchase UoM)
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Quantity, PurchaseLineOrder."Quantity Invoiced", 'Order Quantity Invoiced should match (in purchase UoM)');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order Qty. to Invoice should be 0');
        Assert.AreEqual(Quantity * QtyPerUoM, PurchaseLineOrder."Qty. Invoiced (Base)", 'Order Qty. Invoiced (Base) should be Qty * Qty per UoM');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice (Base)", 'Order Qty. to Invoice (Base) should be 0');

        // [THEN] Receipt line fully invoiced with correct base quantities
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt Qty. Rcd. Not Invoiced should be 0');
        Assert.AreEqual(Quantity * QtyPerUoM, PurchRcptLine."Quantity (Base)", 'Receipt Quantity (Base) should be Qty * Qty per UoM');
        Assert.AreEqual(Quantity * QtyPerUoM, PurchRcptLine."Qty. Invoiced (Base)", 'Receipt Qty. Invoiced (Base) should be Qty * Qty per UoM');

        // [THEN] Posted invoice line has correct base quantity
        Assert.AreEqual(Quantity * QtyPerUoM, PurchInvLine."Quantity (Base)", 'Posted invoice Quantity (Base) should be Qty * Qty per UoM');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_E2E_PartialInvoiceDifferentPurchUoM()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice1: Record "Purchase Header";
        PurchaseLineInvoice1: Record "Purchase Line";
        PurchaseHeaderInvoice2: Record "Purchase Header";
        PurchaseLineInvoice2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo1: Code[20];
        PostedInvoiceNo2: Code[20];
        TotalQuantity: Decimal;
        Invoice1Quantity: Decimal;
        Invoice2Quantity: Decimal;
        QtyPerUoM: Decimal;
    begin
        // [SCENARIO E2E-9.6] Single Order, Partial Invoice (Multiple Invoices) - item base UoM differs from purchase UoM
        Initialize();
        TotalQuantity := 100;
        Invoice1Quantity := 40;
        Invoice2Quantity := 60;
        QtyPerUoM := LibraryRandom.RandIntInRange(2, 10);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a purchase UoM different from the base UoM (e.g. BOX = N PCS)
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, QtyPerUoM);
        Item.Validate("Purch. Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Create Purchase Order using purchase UoM and Receive
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // Verify purchase line uses the purchase UoM
        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineOrder."Unit of Measure Code", 'Purchase line should use Purch. Unit of Measure');
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchaseLineOrder."Quantity (Base)", 'Quantity (Base) should be Qty * Qty per UoM');

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice #1 (Qty = 40 in purchase UoM), match through UI, post
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice1, PurchaseHeaderInvoice1."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice1, PurchaseHeaderInvoice1, PurchaseLineInvoice1.Type::Item, Item."No.", Invoice1Quantity);
        PurchaseLineInvoice1.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice1.Modify(true);

        // Verify invoice line uses purchase UoM
        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineInvoice1."Unit of Measure Code", 'Invoice #1 should use Purch. Unit of Measure');
        Assert.AreEqual(Invoice1Quantity * QtyPerUoM, PurchaseLineInvoice1."Quantity (Base)", 'Invoice #1 Quantity (Base) should be 40 * Qty per UoM');

        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(Invoice1Quantity); // Adjust receipt-level Qty. to Invoice to partial qty (40)
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice1);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        PostedInvoiceNo1 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice1, false, true);

        // [THEN] After Invoice #1: Order Qty Invoiced = 40 (in purchase UoM), Receipt Qty Rcd Not Invoiced = 60
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Invoice1Quantity, PurchaseLineOrder."Quantity Invoiced", 'After Invoice #1: Quantity Invoiced should be 40');
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(Invoice2Quantity, PurchRcptLine."Qty. Rcd. Not Invoiced", 'After Invoice #1: Qty. Rcd. Not Invoiced should be 60');

        // [THEN] Posted invoice #1 has correct base quantity
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo1);
        PurchInvLine.FindFirst();
        Assert.AreEqual(Invoice1Quantity * QtyPerUoM, PurchInvLine."Quantity (Base)", 'Posted Invoice #1 Quantity (Base) should be 40 * Qty per UoM');

        // [GIVEN] Create Invoice #2 (Qty = 60 in purchase UoM), match through UI, post
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice2, PurchaseHeaderInvoice2."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice2, PurchaseHeaderInvoice2, PurchaseLineInvoice2.Type::Item, Item."No.", Invoice2Quantity);
        PurchaseLineInvoice2.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice2.Modify(true);

        // Verify invoice #2 uses purchase UoM
        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineInvoice2."Unit of Measure Code", 'Invoice #2 should use Purch. Unit of Measure');
        Assert.AreEqual(Invoice2Quantity * QtyPerUoM, PurchaseLineInvoice2."Quantity (Base)", 'Invoice #2 Quantity (Base) should be 60 * Qty per UoM');

        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(0); // No adjustment - remaining receipt qty (60) matches invoice qty
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice2);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        PostedInvoiceNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice2, false, true);

        // [THEN] Order fully invoiced
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Invoiced", 'Order Quantity Invoiced should be 100');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order Qty. to Invoice should be 0');
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchaseLineOrder."Qty. Invoiced (Base)", 'Order Qty. Invoiced (Base) should be 100 * Qty per UoM');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice (Base)", 'Order Qty. to Invoice (Base) should be 0');

        // [THEN] Receipt fully invoiced with correct base quantities
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt Qty. Rcd. Not Invoiced should be 0');
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchRcptLine."Quantity (Base)", 'Receipt Quantity (Base) should be 100 * Qty per UoM');
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchRcptLine."Qty. Invoiced (Base)", 'Receipt Qty. Invoiced (Base) should be 100 * Qty per UoM');

        // [THEN] Both posted invoices have posted matched order lines
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo1);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #1 should have 2 posted matched order line records');

        PurchInvLine.SetRange("Document No.", PostedInvoiceNo2);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #2 should have 2 posted matched order line records');

        // [THEN] Posted invoice #2 has correct base quantity
        Assert.AreEqual(Invoice2Quantity * QtyPerUoM, PurchInvLine."Quantity (Base)", 'Posted Invoice #2 Quantity (Base) should be 60 * Qty per UoM');

        // [THEN] All pre-posting matched order lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_E2E_MultipleReceiptsDifferentPurchUoM()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine1: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo: Code[20];
        TotalQuantity: Decimal;
        Receipt1Quantity: Decimal;
        Receipt2Quantity: Decimal;
        QtyPerUoM: Decimal;
    begin
        // [SCENARIO E2E-9.7] Single Order, Multiple Receipts, Single Invoice - item base UoM differs from purchase UoM
        Initialize();
        TotalQuantity := 100;
        Receipt1Quantity := 30;
        Receipt2Quantity := 70;
        QtyPerUoM := LibraryRandom.RandIntInRange(2, 10);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a purchase UoM different from the base UoM
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, QtyPerUoM);
        Item.Validate("Purch. Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Create Purchase Order using purchase UoM
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // Verify purchase line uses the purchase UoM
        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineOrder."Unit of Measure Code", 'Purchase line should use Purch. Unit of Measure');
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchaseLineOrder."Quantity (Base)", 'Quantity (Base) should be Qty * Qty per UoM');

        // [GIVEN] Receive Qty = 30 (Receipt #1)
        PurchaseLineOrder.Validate("Qty. to Receive", Receipt1Quantity);
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine1.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine1.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine1.FindFirst();

        // [GIVEN] Receive Qty = 70 (Receipt #2)
        PurchaseHeaderOrder.Get(PurchaseHeaderOrder."Document Type", PurchaseHeaderOrder."No.");
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchaseLineOrder.Validate("Qty. to Receive", Receipt2Quantity);
        PurchaseLineOrder.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine2.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine2.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine2.SetFilter("Document No.", '<>%1', PurchRcptLine1."Document No.");
        PurchRcptLine2.FindFirst();

        // [GIVEN] Create Purchase Invoice (Qty = 100 in purchase UoM)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // Verify invoice line uses purchase UoM
        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineInvoice."Unit of Measure Code", 'Invoice line should use Purch. Unit of Measure');
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchaseLineInvoice."Quantity (Base)", 'Invoice Quantity (Base) should be 100 * Qty per UoM');

        // [WHEN] Match through UI
        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(0); // No qty adjustment - total receipt qty (30+70) matches invoice qty
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [THEN] Matched Order Lines = 1
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] 3 Posted Matched Order Lines (1 order-level + 2 receipt-level)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(3, PostedMatchedOrderLine.Count(), 'Should have 3 posted matched order line records (1 order + 2 receipts)');

        // [THEN] Both receipt lines fully invoiced with correct base quantities
        PurchRcptLine1.Get(PurchRcptLine1."Document No.", PurchRcptLine1."Line No.");
        Assert.AreEqual(0, PurchRcptLine1."Qty. Rcd. Not Invoiced", 'Receipt #1 Qty. Rcd. Not Invoiced should be 0');
        Assert.AreEqual(Receipt1Quantity * QtyPerUoM, PurchRcptLine1."Quantity (Base)", 'Receipt #1 Quantity (Base) should be 30 * Qty per UoM');
        Assert.AreEqual(Receipt1Quantity * QtyPerUoM, PurchRcptLine1."Qty. Invoiced (Base)", 'Receipt #1 Qty. Invoiced (Base) should be 30 * Qty per UoM');
        PurchRcptLine2.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No.");
        Assert.AreEqual(0, PurchRcptLine2."Qty. Rcd. Not Invoiced", 'Receipt #2 Qty. Rcd. Not Invoiced should be 0');
        Assert.AreEqual(Receipt2Quantity * QtyPerUoM, PurchRcptLine2."Quantity (Base)", 'Receipt #2 Quantity (Base) should be 70 * Qty per UoM');
        Assert.AreEqual(Receipt2Quantity * QtyPerUoM, PurchRcptLine2."Qty. Invoiced (Base)", 'Receipt #2 Qty. Invoiced (Base) should be 70 * Qty per UoM');

        // [THEN] Order line fully invoiced with correct base quantities
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Invoiced", 'Order Quantity Invoiced should be 100');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order Qty. to Invoice should be 0');
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchaseLineOrder."Qty. Invoiced (Base)", 'Order Qty. Invoiced (Base) should be 100 * Qty per UoM');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice (Base)", 'Order Qty. to Invoice (Base) should be 0');

        // [THEN] Posted invoice line has correct base quantity
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchInvLine."Quantity (Base)", 'Posted invoice Quantity (Base) should be 100 * Qty per UoM');

        // [THEN] All matched order lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_E2E_MultipleOrdersDifferentPurchUoM()
    var
        PurchaseHeaderOrder1: Record "Purchase Header";
        PurchaseLineOrder1: Record "Purchase Line";
        PurchaseHeaderOrder2: Record "Purchase Header";
        PurchaseLineOrder2: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine1: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo: Code[20];
        Order1Quantity: Decimal;
        Order2Quantity: Decimal;
        TotalQuantity: Decimal;
        QtyPerUoM: Decimal;
    begin
        // [SCENARIO E2E-9.8] Multiple Orders, Single Invoice - item base UoM differs from purchase UoM
        Initialize();
        Order1Quantity := 50;
        Order2Quantity := 50;
        TotalQuantity := Order1Quantity + Order2Quantity;
        QtyPerUoM := LibraryRandom.RandIntInRange(2, 10);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a purchase UoM different from the base UoM
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, QtyPerUoM);
        Item.Validate("Purch. Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Create and Receive Order #1
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder1, PurchaseHeaderOrder1."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder1, PurchaseHeaderOrder1, PurchaseLineOrder1.Type::Item, Item."No.", Order1Quantity);
        PurchaseLineOrder1.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder1.Modify(true);

        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineOrder1."Unit of Measure Code", 'Order #1 should use Purch. Unit of Measure');
        Assert.AreEqual(Order1Quantity * QtyPerUoM, PurchaseLineOrder1."Quantity (Base)", 'Order #1 Quantity (Base) should be 50 * Qty per UoM');

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder1, true, false);

        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine1.SetRange("Order No.", PurchaseLineOrder1."Document No.");
        PurchRcptLine1.SetRange("Order Line No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine1.FindFirst();

        // [GIVEN] Create and Receive Order #2
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder2, PurchaseHeaderOrder2."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder2, PurchaseHeaderOrder2, PurchaseLineOrder2.Type::Item, Item."No.", Order2Quantity);
        PurchaseLineOrder2.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineOrder2.Modify(true);

        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineOrder2."Unit of Measure Code", 'Order #2 should use Purch. Unit of Measure');
        Assert.AreEqual(Order2Quantity * QtyPerUoM, PurchaseLineOrder2."Quantity (Base)", 'Order #2 Quantity (Base) should be 50 * Qty per UoM');

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder2, true, false);

        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.SetRange("Order No.", PurchaseLineOrder2."Document No.");
        PurchRcptLine2.SetRange("Order Line No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.FindFirst();

        // [GIVEN] Create Purchase Invoice (Qty = 100 in purchase UoM)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        Assert.AreEqual(UnitOfMeasure.Code, PurchaseLineInvoice."Unit of Measure Code", 'Invoice should use Purch. Unit of Measure');
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchaseLineInvoice."Quantity (Base)", 'Invoice Quantity (Base) should be 100 * Qty per UoM');

        // [WHEN] Match through UI - first invocation selects Order #1
        LibraryVariableStorage.Enqueue(PurchaseLineOrder1."Document No.");
        LibraryVariableStorage.Enqueue(0);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [WHEN] Match through UI - second invocation selects Order #2
        LibraryVariableStorage.Enqueue(PurchaseLineOrder2."Document No.");
        LibraryVariableStorage.Enqueue(0);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [THEN] Matched Order Lines = 2 on the invoice line
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(2);
        PurchaseInvoice.Close();

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] 4 Posted Matched Order Lines (2 order-level + 2 receipt-level)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(4, PostedMatchedOrderLine.Count(), 'Should have 4 posted matched order line records (2 orders + 2 receipts)');

        // [THEN] Both orders fully invoiced with correct base quantities
        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        Assert.AreEqual(Order1Quantity, PurchaseLineOrder1."Quantity Invoiced", 'Order #1 Quantity Invoiced should be 50');
        Assert.AreEqual(0, PurchaseLineOrder1."Qty. to Invoice", 'Order #1 Qty. to Invoice should be 0');
        Assert.AreEqual(Order1Quantity * QtyPerUoM, PurchaseLineOrder1."Qty. Invoiced (Base)", 'Order #1 Qty. Invoiced (Base) should be 50 * Qty per UoM');
        Assert.AreEqual(0, PurchaseLineOrder1."Qty. to Invoice (Base)", 'Order #1 Qty. to Invoice (Base) should be 0');

        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        Assert.AreEqual(Order2Quantity, PurchaseLineOrder2."Quantity Invoiced", 'Order #2 Quantity Invoiced should be 50');
        Assert.AreEqual(0, PurchaseLineOrder2."Qty. to Invoice", 'Order #2 Qty. to Invoice should be 0');
        Assert.AreEqual(Order2Quantity * QtyPerUoM, PurchaseLineOrder2."Qty. Invoiced (Base)", 'Order #2 Qty. Invoiced (Base) should be 50 * Qty per UoM');
        Assert.AreEqual(0, PurchaseLineOrder2."Qty. to Invoice (Base)", 'Order #2 Qty. to Invoice (Base) should be 0');

        // [THEN] Both receipt lines fully invoiced with correct base quantities
        PurchRcptLine1.Get(PurchRcptLine1."Document No.", PurchRcptLine1."Line No.");
        Assert.AreEqual(0, PurchRcptLine1."Qty. Rcd. Not Invoiced", 'Receipt #1 Qty. Rcd. Not Invoiced should be 0');
        Assert.AreEqual(Order1Quantity * QtyPerUoM, PurchRcptLine1."Quantity (Base)", 'Receipt #1 Quantity (Base) should be 50 * Qty per UoM');
        Assert.AreEqual(Order1Quantity * QtyPerUoM, PurchRcptLine1."Qty. Invoiced (Base)", 'Receipt #1 Qty. Invoiced (Base) should be 50 * Qty per UoM');
        PurchRcptLine2.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No.");
        Assert.AreEqual(0, PurchRcptLine2."Qty. Rcd. Not Invoiced", 'Receipt #2 Qty. Rcd. Not Invoiced should be 0');
        Assert.AreEqual(Order2Quantity * QtyPerUoM, PurchRcptLine2."Quantity (Base)", 'Receipt #2 Quantity (Base) should be 50 * Qty per UoM');
        Assert.AreEqual(Order2Quantity * QtyPerUoM, PurchRcptLine2."Qty. Invoiced (Base)", 'Receipt #2 Qty. Invoiced (Base) should be 50 * Qty per UoM');

        // [THEN] Posted invoice line has correct base quantity
        Assert.AreEqual(TotalQuantity * QtyPerUoM, PurchInvLine."Quantity (Base)", 'Posted invoice Quantity (Base) should be 100 * Qty per UoM');

        // [THEN] All matched order lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    // ============================================================================
    // REGION: E2E-10 UI (TestPage) Scenarios with WMS Location
    // Replicates E2E-9 scenarios using a Directed Put-away and Pick location
    // ============================================================================

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_WMS_SingleOrderSingleReceiptFullInvoice()
    var
        Location: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO E2E-10.1] Single Order, Single WMS Receipt, Full Invoice - matched through UI
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] WMS Location with Directed Put-away and Pick
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order on WMS Location and receive via Warehouse Receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", Quantity);
        PurchaseLineOrder.Validate("Location Code", Location.Code);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeaderOrder);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeaderOrder);
        WarehouseReceiptHeader.Get(
            LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
                Database::"Purchase Line",
                PurchaseHeaderOrder."Document Type".AsInteger(),
                PurchaseHeaderOrder."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Register put-away (auto-created by posting warehouse receipt at directed location)
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Purchase Order");
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeaderOrder."No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", Quantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [THEN] Setting Location Code when Quantity is set (before matching) should error
        Commit();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        asserterror PurchaseInvoice.PurchLines."Location Code".SetValue(Location.Code);
        Assert.ExpectedError('Warehouse Receive is required for Line No. = 10000.');
        PurchaseInvoice.Close();

        // [GIVEN] Clear Quantity, set Location Code, match through UI, then set Quantity (no error)
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(0);
        PurchaseInvoice.PurchLines."Location Code".SetValue(Location.Code);

        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(0);
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(Quantity);

        // [THEN] Matched Order Lines = 1
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Posted Matched Order Lines created
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Should have 2 posted matched order lines (1 order + 1 receipt)');

        // [THEN] Matched Order Lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);

        // [THEN] Order line fully invoiced
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Quantity, PurchaseLineOrder."Quantity Invoiced", 'Order Quantity Invoiced should match');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order Qty. to Invoice should be 0');

        // [THEN] Receipt line fully invoiced
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt Qty. Rcd. Not Invoiced should be 0');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_WMS_SingleOrderPartialInvoiceMultipleInvoices()
    var
        Location: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice1: Record "Purchase Header";
        PurchaseLineInvoice1: Record "Purchase Line";
        PurchaseHeaderInvoice2: Record "Purchase Header";
        PurchaseLineInvoice2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo1: Code[20];
        PostedInvoiceNo2: Code[20];
        TotalQuantity: Decimal;
        Invoice1Quantity: Decimal;
        Invoice2Quantity: Decimal;
    begin
        // [SCENARIO E2E-10.2] Single Order, Partial Invoice (Multiple Invoices) with WMS Location
        Initialize();
        TotalQuantity := 100;
        Invoice1Quantity := 40;
        Invoice2Quantity := 60;

        // [GIVEN] WMS Location with Directed Put-away and Pick
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order on WMS Location and receive via Warehouse Receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Location Code", Location.Code);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeaderOrder);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeaderOrder);
        WarehouseReceiptHeader.Get(
            LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
                Database::"Purchase Line",
                PurchaseHeaderOrder."Document Type".AsInteger(),
                PurchaseHeaderOrder."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Register put-away
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Purchase Order");
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeaderOrder."No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create Invoice #1 (Qty = 40)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice1, PurchaseHeaderInvoice1."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice1, PurchaseHeaderInvoice1, PurchaseLineInvoice1.Type::Item, Item."No.", Invoice1Quantity);
        PurchaseLineInvoice1.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice1.Modify(true);

        // [THEN] Setting Location Code when Quantity is set (before matching) should error
        Commit();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice1);
        PurchaseInvoice.PurchLines.First();
        asserterror PurchaseInvoice.PurchLines."Location Code".SetValue(Location.Code);
        Assert.ExpectedError('Warehouse Receive is required for Line No. = 10000.');
        PurchaseInvoice.Close();

        // [GIVEN] Clear Quantity, set Location Code, match, then set Quantity (no error)
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice1);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(0);
        PurchaseInvoice.PurchLines."Location Code".SetValue(Location.Code);

        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(Invoice1Quantity);
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(Invoice1Quantity);
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        PostedInvoiceNo1 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice1, false, true);

        // [THEN] After Invoice #1
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(Invoice1Quantity, PurchaseLineOrder."Quantity Invoiced", 'After Invoice #1: Quantity Invoiced should be 40');
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(Invoice2Quantity, PurchRcptLine."Qty. Rcd. Not Invoiced", 'After Invoice #1: Qty. Rcd. Not Invoiced should be 60');

        // [GIVEN] Create Invoice #2 (Qty = 60), clear Qty, set Location Code, match, set Qty
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice2, PurchaseHeaderInvoice2."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice2, PurchaseHeaderInvoice2, PurchaseLineInvoice2.Type::Item, Item."No.", Invoice2Quantity);
        PurchaseLineInvoice2.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice2.Modify(true);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice2);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(0);
        PurchaseInvoice.PurchLines."Location Code".SetValue(Location.Code);

        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(0);
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(Invoice2Quantity);
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        PostedInvoiceNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice2, false, true);

        // [THEN] Order fully invoiced
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Invoiced", 'Order Quantity Invoiced should be 100');
        Assert.AreEqual(0, PurchaseLineOrder."Qty. to Invoice", 'Order Qty. to Invoice should be 0');

        // [THEN] Receipt fully invoiced
        PurchRcptLine.Get(PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        Assert.AreEqual(0, PurchRcptLine."Qty. Rcd. Not Invoiced", 'Receipt Qty. Rcd. Not Invoiced should be 0');

        // [THEN] Both posted invoices have posted matched order lines
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo1);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #1 should have 2 posted matched order line records');

        PurchInvLine.SetRange("Document No.", PostedInvoiceNo2);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(2, PostedMatchedOrderLine.Count(), 'Invoice #2 should have 2 posted matched order line records');

        // [THEN] All pre-posting matched order lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Matched Order Line SystemId", PurchaseLineOrder.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_WMS_SingleOrderMultipleReceiptsSingleInvoice()
    var
        Location: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine1: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo: Code[20];
        TotalQuantity: Decimal;
        Receipt1Quantity: Decimal;
    begin
        // [SCENARIO E2E-10.3] Single Order, Multiple WMS Receipts, Single Invoice
        Initialize();
        TotalQuantity := 100;
        Receipt1Quantity := 30;

        // [GIVEN] WMS Location with Directed Put-away and Pick
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order on WMS Location
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineOrder.Validate("Location Code", Location.Code);
        PurchaseLineOrder.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder.Modify(true);

        // [GIVEN] Receive Qty = 30 (Warehouse Receipt #1 - partial)
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeaderOrder);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeaderOrder);
        WarehouseReceiptHeader.Get(
            LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
                Database::"Purchase Line",
                PurchaseHeaderOrder."Document Type".AsInteger(),
                PurchaseHeaderOrder."No."));
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Qty. to Receive", Receipt1Quantity);
        WarehouseReceiptLine.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Register put-away for receipt #1
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Purchase Order");
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeaderOrder."No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine1.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine1.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine1.FindFirst();

        // [GIVEN] Receive Qty = 70 (Warehouse Receipt #2 - remaining)
        PurchaseHeaderOrder.Get(PurchaseHeaderOrder."Document Type", PurchaseHeaderOrder."No.");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeaderOrder);
        WarehouseReceiptHeader.Get(
            LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
                Database::"Purchase Line",
                PurchaseHeaderOrder."Document Type".AsInteger(),
                PurchaseHeaderOrder."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Register put-away for receipt #2
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Purchase Order");
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeaderOrder."No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        PurchRcptLine2.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine2.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        PurchRcptLine2.SetFilter("Document No.", '<>%1', PurchRcptLine1."Document No.");
        PurchRcptLine2.FindFirst();

        // [GIVEN] Create Purchase Invoice (Qty = 100)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [THEN] Setting Location Code when Quantity is set (before matching) should error
        Commit();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        asserterror PurchaseInvoice.PurchLines."Location Code".SetValue(Location.Code);
        Assert.ExpectedError('Warehouse Receive is required for Line No. = 10000.');
        PurchaseInvoice.Close();

        // [GIVEN] Clear Quantity, set Location Code, match through UI, then set Quantity (no error)
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(0);
        PurchaseInvoice.PurchLines."Location Code".SetValue(Location.Code);

        LibraryVariableStorage.Enqueue(PurchaseLineOrder."Document No.");
        LibraryVariableStorage.Enqueue(0);
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(TotalQuantity);

        // [THEN] Matched Order Lines = 1
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(1);
        PurchaseInvoice.Close();

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] 3 Posted Matched Order Lines (1 order + 2 receipts)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(3, PostedMatchedOrderLine.Count(), 'Should have 3 posted matched order lines (1 order + 2 receipts)');

        // [THEN] Both receipt lines fully invoiced
        PurchRcptLine1.Get(PurchRcptLine1."Document No.", PurchRcptLine1."Line No.");
        Assert.AreEqual(0, PurchRcptLine1."Qty. Rcd. Not Invoiced", 'Receipt #1 Qty. Rcd. Not Invoiced should be 0');
        PurchRcptLine2.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No.");
        Assert.AreEqual(0, PurchRcptLine2."Qty. Rcd. Not Invoiced", 'Receipt #2 Qty. Rcd. Not Invoiced should be 0');

        // [THEN] Order line fully invoiced
        PurchaseLineOrder.Get(PurchaseLineOrder."Document Type", PurchaseLineOrder."Document No.", PurchaseLineOrder."Line No.");
        Assert.AreEqual(TotalQuantity, PurchaseLineOrder."Quantity Invoiced", 'Order Quantity Invoiced should be 100');

        // [THEN] All matched order lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MatchedOrderLinesModalHandler,PurchaseOrderLinesLookupHandler')]
    procedure UI_WMS_MultipleOrdersSingleInvoice()
    var
        Location: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeaderOrder1: Record "Purchase Header";
        PurchaseLineOrder1: Record "Purchase Line";
        PurchaseHeaderOrder2: Record "Purchase Header";
        PurchaseLineOrder2: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine1: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchInvLine: Record "Purch. Inv. Line";
        MatchedOrderLine: Record "Matched Order Line";
        PostedMatchedOrderLine: Record "Posted Matched Order Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedInvoiceNo: Code[20];
        Order1Quantity: Decimal;
        Order2Quantity: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO E2E-10.4] Multiple Orders on WMS Location, Single Invoice
        Initialize();
        Order1Quantity := 50;
        Order2Quantity := 50;
        TotalQuantity := Order1Quantity + Order2Quantity;

        // [GIVEN] WMS Location with Directed Put-away and Pick
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Receive Order #1 via Warehouse Receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder1, PurchaseHeaderOrder1."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder1, PurchaseHeaderOrder1, PurchaseLineOrder1.Type::Item, Item."No.", Order1Quantity);
        PurchaseLineOrder1.Validate("Location Code", Location.Code);
        PurchaseLineOrder1.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLineOrder1.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeaderOrder1);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeaderOrder1);
        WarehouseReceiptHeader.Get(
            LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
                Database::"Purchase Line",
                PurchaseHeaderOrder1."Document Type".AsInteger(),
                PurchaseHeaderOrder1."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Register put-away for Order #1
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Purchase Order");
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeaderOrder1."No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine1.SetRange("Order No.", PurchaseLineOrder1."Document No.");
        PurchRcptLine1.SetRange("Order Line No.", PurchaseLineOrder1."Line No.");
        PurchRcptLine1.FindFirst();

        // [GIVEN] Create and Receive Order #2 via Warehouse Receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder2, PurchaseHeaderOrder2."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder2, PurchaseHeaderOrder2, PurchaseLineOrder2.Type::Item, Item."No.", Order2Quantity);
        PurchaseLineOrder2.Validate("Location Code", Location.Code);
        PurchaseLineOrder2.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineOrder2.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeaderOrder2);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeaderOrder2);
        WarehouseReceiptHeader.Get(
            LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
                Database::"Purchase Line",
                PurchaseHeaderOrder2."Document Type".AsInteger(),
                PurchaseHeaderOrder2."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Register put-away for Order #2
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Purchase Order");
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeaderOrder2."No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.SetRange("Order No.", PurchaseLineOrder2."Document No.");
        PurchRcptLine2.SetRange("Order Line No.", PurchaseLineOrder2."Line No.");
        PurchRcptLine2.FindFirst();

        // [GIVEN] Create Purchase Invoice (Qty = 100)
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::Item, Item."No.", TotalQuantity);
        PurchaseLineInvoice.Validate("Direct Unit Cost", PurchaseLineOrder1."Direct Unit Cost");
        PurchaseLineInvoice.Modify(true);

        // [THEN] Setting Location Code when Quantity is set (before matching) should error
        Commit();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        asserterror PurchaseInvoice.PurchLines."Location Code".SetValue(Location.Code);
        Assert.ExpectedError('Warehouse Receive is required for Line No. = 10000.');
        PurchaseInvoice.Close();

        // [GIVEN] Clear Quantity, set Location Code, match through UI, then set Quantity (no error)
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeaderInvoice);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(0);
        PurchaseInvoice.PurchLines."Location Code".SetValue(Location.Code);

        // [WHEN] Match through UI - first invocation selects Order #1
        LibraryVariableStorage.Enqueue(PurchaseLineOrder1."Document No.");
        LibraryVariableStorage.Enqueue(0);
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [WHEN] Match through UI - second invocation selects Order #2
        LibraryVariableStorage.Enqueue(PurchaseLineOrder2."Document No.");
        LibraryVariableStorage.Enqueue(0);
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.MatchedOrdLines.Invoke();

        // [THEN] After matching, setting Quantity does not error
        PurchaseInvoice.PurchLines.First();
        PurchaseInvoice.PurchLines.Quantity.SetValue(TotalQuantity);

        // [THEN] Matched Order Lines = 2
        PurchaseInvoice.PurchLines."Matched Order Lines".AssertEquals(2);
        PurchaseInvoice.Close();

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] 4 Posted Matched Order Lines (2 order-level + 2 receipt-level)
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        PostedMatchedOrderLine.SetRange("Document Line SystemId", PurchInvLine.SystemId);
        Assert.AreEqual(4, PostedMatchedOrderLine.Count(), 'Should have 4 posted matched order lines (2 orders + 2 receipts)');

        // [THEN] Both orders fully invoiced
        PurchaseLineOrder1.Get(PurchaseLineOrder1."Document Type", PurchaseLineOrder1."Document No.", PurchaseLineOrder1."Line No.");
        Assert.AreEqual(Order1Quantity, PurchaseLineOrder1."Quantity Invoiced", 'Order #1 Quantity Invoiced should be 50');
        PurchaseLineOrder2.Get(PurchaseLineOrder2."Document Type", PurchaseLineOrder2."Document No.", PurchaseLineOrder2."Line No.");
        Assert.AreEqual(Order2Quantity, PurchaseLineOrder2."Quantity Invoiced", 'Order #2 Quantity Invoiced should be 50');

        // [THEN] Both receipt lines fully invoiced
        PurchRcptLine1.Get(PurchRcptLine1."Document No.", PurchRcptLine1."Line No.");
        Assert.AreEqual(0, PurchRcptLine1."Qty. Rcd. Not Invoiced", 'Receipt #1 Qty. Rcd. Not Invoiced should be 0');
        PurchRcptLine2.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No.");
        Assert.AreEqual(0, PurchRcptLine2."Qty. Rcd. Not Invoiced", 'Receipt #2 Qty. Rcd. Not Invoiced should be 0');

        // [THEN] All matched order lines cleaned up
        MatchedOrderLine.Reset();
        MatchedOrderLine.SetRange("Document Line SystemId", PurchaseLineInvoice.SystemId);
        Assert.RecordIsEmpty(MatchedOrderLine);
    end;

    // ============================================================================
    // REGION: Local Helper Functions
    // ============================================================================

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Matched Order Line Tests");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Matched Order Line Tests");

        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(Database::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Matched Order Line Tests");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
        // Close handler - accept defaults
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MatchedOrderLinesModalHandler(var MatchedOrderLines: TestPage "Matched Order Lines")
    var
        QtyToInvoiceVar: Variant;
        QtyToInvoice: Decimal;
    begin
        MatchedOrderLines.GetOrderLines.Invoke();
        LibraryVariableStorage.Dequeue(QtyToInvoiceVar);
        QtyToInvoice := QtyToInvoiceVar;
        if QtyToInvoice > 0 then begin
            // Tree: Invoice (ind 0) → Order (ind 1) → Receipt (ind 2)
            // Must expand parent nodes to make children visible for Next()
            MatchedOrderLines.First();
            MatchedOrderLines.Expand(true);
            MatchedOrderLines.Next();
            MatchedOrderLines.Expand(true);
            MatchedOrderLines.Next();
            MatchedOrderLines."Qty. to Invoice".SetValue(QtyToInvoice);
        end;
        MatchedOrderLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderLinesLookupHandler(var PurchaseLines: TestPage "Purchase Lines")
    var
        OrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(OrderNo);
        PurchaseLines.Filter.SetFilter("Document No.", OrderNo);
        PurchaseLines.First();
        PurchaseLines.OK().Invoke();
    end;
}