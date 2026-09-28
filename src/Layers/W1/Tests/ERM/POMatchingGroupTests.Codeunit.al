namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

codeunit 134469 "PO Matching Group Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [PO Matching]
    end;

    var
        Assert: Codeunit Assert;
        POMatching: Codeunit "PO Matching";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        EmptyGuid: Guid;

    #region Invoice-order edges
    [Test]
    procedure AddInvoiceOrderMatchWithinCapsSucceedsAndPersists()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] An invoice-order edge within caps is accepted and persisted as a (invoice, order, blank) 5817 row.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine);

        // [WHEN] Adding an invoice-order match for 40 and saving
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 40));
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] One invoice-order Matched Order Line row exists with the expected quantities
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        Assert.AreEqual(1, MatchedOrderLine.Count(), 'Should persist exactly one row');
        MatchedOrderLine.SetRange("Matched Order Line SystemId", OrderLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Invoice-order row should exist');
        Assert.AreEqual(40, MatchedOrderLine."Qty. to Invoice", 'Qty. to Invoice');
        Assert.AreEqual(40, MatchedOrderLine."Qty. to Invoice (Base)", 'Qty. to Invoice (Base)');
        Assert.IsFalse(MatchedOrderLine."Receipt on Invoice", 'Receipt on Invoice should be false');
    end;

    [Test]
    procedure AddInvoiceOrderMatchExceedingInvoiceQuantityErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] An invoice-order edge exceeding the invoice line quantity is rejected.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine);

        // [WHEN] Allocating 50 against an invoice line of 40
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 50));

        // [THEN] Rejected: exceeds the invoice line
        Assert.ExpectedError('exceeds the quantity available to invoice on the purchase invoice line');
    end;

    [Test]
    procedure AddInvoiceOrderMatchExceedingOrderRemainingErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] An invoice-order edge exceeding the order line's quantity remaining to invoice is rejected.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine);
        CreateInvoiceLine(Vendor, Item, 150, InvoiceLine);

        // [WHEN] Allocating 150 against an order line of 100 (invoice is large enough, order is not)
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 150));

        // [THEN] Rejected: exceeds the order line's remaining to invoice
        Assert.ExpectedError('exceeds the quantity remaining to invoice on the purchase order line');
    end;

    [Test]
    procedure AddInvoiceOrderMatchRunningTotalPerInvoiceErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine1, OrderLine2, InvoiceLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Two invoice-order edges from the same invoice line cannot together exceed the invoice quantity.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine1);
        CreateOrderLine(Vendor, Item, 100, OrderLine2);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] 60 already allocated from the invoice line to order 1
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine1.SystemId, 60));

        // [WHEN] Allocating 50 more from the same invoice line to order 2 (60 + 50 > 100)
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine2.SystemId, 50));

        // [THEN] Rejected: only 40 of the invoice remains to allocate
        Assert.ExpectedError('exceeds the quantity available to invoice on the purchase invoice line');
    end;

    [Test]
    procedure AddMatchWithDifferentBaseUoMPersistsBase()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        OrderLine, InvoiceLine : Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] When the purchase UoM differs from the base UoM, the derived base quantity is persisted.
        Initialize(Vendor, Item);
        CreatePurchaseUoM(Item, 12, UnitOfMeasure); // 1 purchase UoM = 12 base
        CreateOrderLineWithUoM(Vendor, Item, UnitOfMeasure.Code, 10, OrderLine);       // 10 -> 120 base
        CreateInvoiceLineWithUoM(Vendor, Item, UnitOfMeasure.Code, 10, InvoiceLine);   // 10 -> 120 base

        // [WHEN] Adding an invoice-order edge for the line's quantity, then saving (base is derived from the order UoM)
        POMatchingGroup.AddMatch(
            POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, OrderLine.Quantity));
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The persisted row carries both quantity (10) and base (120)
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Invoice-order row should exist');
        Assert.AreEqual(10, MatchedOrderLine."Qty. to Invoice", 'Qty. to Invoice');
        Assert.AreEqual(120, MatchedOrderLine."Qty. to Invoice (Base)", 'Qty. to Invoice (Base)');
    end;

    [Test]
    procedure AddInvoiceOrderMatchWithNonInvoiceDocumentErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        InvoiceRoleLine, OrderLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 10, InvoiceRoleLine);
        CreateOrderLine(Vendor, Item, 10, OrderLine);

        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceRoleLine.SystemId, OrderLine.SystemId, 10));

        Assert.ExpectedError('must be an invoice line');
    end;

    [Test]
    procedure AddInvoiceOrderMatchWithNonOrderDocumentErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        InvoiceLine, OrderRoleLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        Initialize(Vendor, Item);
        CreateInvoiceLine(Vendor, Item, 10, InvoiceLine);
        CreateInvoiceLine(Vendor, Item, 10, OrderRoleLine);

        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderRoleLine.SystemId, 10));

        Assert.ExpectedError('must be an order line');
    end;

    [Test]
    procedure AddInvoiceOrderMatchWithDifferentUnitOfMeasureErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        InvoiceLine, OrderLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        Initialize(Vendor, Item);
        CreatePurchaseUoM(Item, 12, UnitOfMeasure);
        CreateOrderLineWithUoM(Vendor, Item, UnitOfMeasure.Code, 10, OrderLine);
        CreateInvoiceLineWithUoM(Vendor, Item, Item."Base Unit of Measure", 10, InvoiceLine);

        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 10));

        Assert.ExpectedError('must have the same unit of measure');
    end;

    [Test]
    procedure AddInvoiceOrderMatchNegativeQuantityErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, OrderLine2, InvoiceLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A negative invoice-order edge is rejected: the caps are upper-bound only, so a negative
        // budget would lower the aggregate consumed by the invoice line and free room for a later edge.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine);
        CreateOrderLine(Vendor, Item, 100, OrderLine2);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine);

        // [GIVEN] The whole invoice quantity is already allocated to the first order line
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 40));

        // [WHEN] Adding a negative edge for the same invoice against a second order line
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine2.SystemId, -10));

        // [THEN] Rejected: the allocation cannot be negative
        Assert.ExpectedError('cannot be negative');
    end;
    #endregion

    #region Order-receipt edges
    [Test]
    procedure AddOrderReceiptMatchWithinBudgetSucceedsAndPersists()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] An order-receipt edge within budget is accepted and persisted as a (invoice, order, receipt) 5817 row.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 100);
        FindReceiptLine(OrderLine, '', PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [WHEN] Adding the budget edge and distributing it onto the receipt, then saving
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));
        POMatchingGroup.AddMatch(POMatching.OrderReceiptEdge(OrderLine.SystemId, PurchRcptLine.SystemId, 100));
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] Two rows: one invoice-order (blank receipt) and one invoice-order-receipt
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        Assert.AreEqual(2, MatchedOrderLine.Count(), 'Should persist two rows');

        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Invoice-order row should exist');
        Assert.AreEqual(100, MatchedOrderLine."Qty. to Invoice", 'Order row Qty. to Invoice');

        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Receipt row should exist');
        Assert.AreEqual(100, MatchedOrderLine."Qty. to Invoice", 'Receipt row Qty. to Invoice');
        Assert.IsFalse(MatchedOrderLine."Receipt on Invoice", 'Receipt row Receipt on Invoice should be false');
    end;

    [Test]
    procedure AddOrderReceiptMatchWithNonInvoiceDocumentErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        InvoiceRoleLine, OrderLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        Initialize(Vendor, Item);
        CreateReceivedOrder(Vendor, Item, 10, 10, OrderLine, PurchRcptLine);
        CreateOrderLine(Vendor, Item, 10, InvoiceRoleLine);

        asserterror POMatchingGroup.AddMatch(
            POMatching.InvoiceOrderReceiptEdge(InvoiceRoleLine.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 10));

        Assert.ExpectedError('must be an invoice line');
    end;

    [Test]
    procedure AddOrderReceiptMatchWithDifferentUnitOfMeasureErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        InvoiceLine, OrderLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        Initialize(Vendor, Item);
        CreatePurchaseUoM(Item, 12, UnitOfMeasure);
        CreateReceivedOrder(Vendor, Item, 10, 10, OrderLine, PurchRcptLine);
        CreateInvoiceLineWithUoM(Vendor, Item, Item."Base Unit of Measure", 10, InvoiceLine);

        asserterror POMatchingGroup.AddMatch(
            POMatching.InvoiceOrderReceiptEdge(InvoiceLine.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 10));

        Assert.ExpectedError('must have the same unit of measure');
    end;

    [Test]
    procedure AddOrderReceiptMatchSecondReceiptExceedsBudgetErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine1, PurchRcptLine2 : Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] The sum of order-receipt edges cannot exceed the invoice-order budget (concern c).
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 60);
        FindReceiptLine(OrderLine, '', PurchRcptLine1);
        ReceiveOrder(OrderHeader, OrderLine, 40);
        FindReceiptLine(OrderLine, PurchRcptLine1."Document No.", PurchRcptLine2);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] Budget of 100 and 60 already distributed to receipt 1
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));
        POMatchingGroup.AddMatch(POMatching.OrderReceiptEdge(OrderLine.SystemId, PurchRcptLine1.SystemId, 60));

        // [WHEN] Distributing 60 more to receipt 2 (60 + 60 > 100 budget)
        asserterror POMatchingGroup.AddMatch(POMatching.OrderReceiptEdge(OrderLine.SystemId, PurchRcptLine2.SystemId, 60));

        // [THEN] Rejected: only 40 of the budget remains to distribute
        Assert.ExpectedError('exceeds the quantity remaining to invoice on the purchase order line');
    end;

    [Test]
    procedure AddOrderReceiptMatchExceedingReceiptNotInvoicedErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] An order-receipt edge cannot exceed the receipt's quantity received not invoiced.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 60);
        FindReceiptLine(OrderLine, '', PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] Budget of 100 (order remaining to invoice), but receipt only has 60 received not invoiced
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));

        // [WHEN] Distributing 70 onto a receipt that has only 60 received not invoiced
        asserterror POMatchingGroup.AddMatch(POMatching.OrderReceiptEdge(OrderLine.SystemId, PurchRcptLine.SystemId, 70));

        // [THEN] Rejected: exceeds the receipt's received not invoiced
        Assert.ExpectedError('exceeds the quantity received not invoiced');
    end;

    [Test]
    procedure AddOrderReceiptMatchNegativeQuantityErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine1, PurchRcptLine2 : Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A negative order-receipt edge is rejected: it would reduce the quantity pinned to the
        // invoice-order budget and the quantity consumed on the receipt, freeing room for a later positive edge.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 60);
        FindReceiptLine(OrderLine, '', PurchRcptLine1);
        ReceiveOrder(OrderHeader, OrderLine, 40);
        FindReceiptLine(OrderLine, PurchRcptLine1."Document No.", PurchRcptLine2);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] Budget of 100 fully distributed to receipt 1 and receipt 2
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));
        POMatchingGroup.AddMatch(POMatching.OrderReceiptEdge(OrderLine.SystemId, PurchRcptLine1.SystemId, 60));
        POMatchingGroup.AddMatch(POMatching.OrderReceiptEdge(OrderLine.SystemId, PurchRcptLine2.SystemId, 40));

        // [WHEN] Turning receipt 2's distribution negative to free up budget
        asserterror POMatchingGroup.AddMatch(POMatching.OrderReceiptEdge(OrderLine.SystemId, PurchRcptLine2.SystemId, -40));

        // [THEN] Rejected: the allocation cannot be negative
        Assert.ExpectedError('cannot be negative');
    end;
    #endregion

    #region Invoice-receipt edges
    [Test]
    procedure AddInvoiceReceiptMatchExpandsToBothEdgesAndPersists()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Matching an invoice line directly to a receipt derives the order and creates both edges.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 100);
        FindReceiptLine(OrderLine, '', PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [WHEN] Adding an invoice-receipt match for 100
        POMatchingGroup.AddMatch(POMatching.InvoiceReceiptEdge(InvoiceLine.SystemId, PurchRcptLine.SystemId, 100));

        // [THEN] Saving persists both a (invoice, order, blank) and a (invoice, order, receipt) 5817 row
        POMatchingGroup.SaveMatchingGroups();
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        Assert.AreEqual(2, MatchedOrderLine.Count(), 'Should persist two rows');
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        Assert.IsFalse(MatchedOrderLine.IsEmpty(), 'Invoice-order row should exist');
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        Assert.IsFalse(MatchedOrderLine.IsEmpty(), 'Invoice-order-receipt row should exist');
    end;
    #endregion

    #region Edge dispatch and overwrite
    [Test]
    procedure AddMatchWithSingleDocumentErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        InvoiceLine: Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A match specifying only one document is rejected.
        Initialize(Vendor, Item);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine);

        // [WHEN] Adding a match with only the invoice line set
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, EmptyGuid, 40));

        // [THEN] Rejected: at least two documents are required
        Assert.ExpectedError('at least two of');
    end;

    [Test]
    procedure AddMatchWithAllThreeDocumentsAllocatesReceiptToInvoice()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] An edge specifying all three documents pins a receipt to a specific invoice (many-1 support).
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 100);
        FindReceiptLine(OrderLine, '', PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] An invoice-order budget of 100
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));

        // [WHEN] Adding an explicit invoice-order-receipt edge for 100 and saving
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 100));
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The receipt row is persisted against the given invoice
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        MatchedOrderLine.SetRange("Matched Order Line SystemId", OrderLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Receipt row should exist');
        Assert.AreEqual(100, MatchedOrderLine."Qty. to Invoice", 'Receipt row Qty. to Invoice');
    end;

    [Test]
    procedure AddMatchDuplicateEdgeOverwrites()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Re-adding the same edge overwrites it (delete-and-recreate) instead of erroring.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] An invoice-order edge of 40
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 40));

        // [WHEN] Re-adding the same edge with 70 and saving
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 70));
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] A single row remains, carrying the latest quantity
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        Assert.AreEqual(1, MatchedOrderLine.Count(), 'Should persist exactly one row');
        MatchedOrderLine.FindFirst();
        Assert.AreEqual(70, MatchedOrderLine."Qty. to Invoice", 'Latest quantity should win');
    end;
    #endregion

    #region Many-to-one: receipt split and invoice inference
    [Test]
    procedure ReceiptSplitAcrossTwoInvoicesPersistsPerInvoiceRows()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine1, InvoiceLine2 : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A receipt fulfilling an order invoiced by two invoice lines is split into per-invoice receipt rows.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 100);
        FindReceiptLine(OrderLine, '', PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 60, InvoiceLine1);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine2);

        // [GIVEN] Two invoice-order budgets on the same order line (60 + 40)
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine1.SystemId, OrderLine.SystemId, 60));
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine2.SystemId, OrderLine.SystemId, 40));

        // [WHEN] Splitting the single receipt across both invoices and saving
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine1.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 60));
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine2.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 40));
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The receipt is persisted as two rows, one per invoice, with the matching quantities
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        Assert.AreEqual(2, MatchedOrderLine.Count(), 'Receipt should be split across two invoice rows');
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine1.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Receipt row for invoice 1 should exist');
        Assert.AreEqual(60, MatchedOrderLine."Qty. to Invoice", 'Invoice 1 receipt qty');
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine2.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Receipt row for invoice 2 should exist');
        Assert.AreEqual(40, MatchedOrderLine."Qty. to Invoice", 'Invoice 2 receipt qty');
    end;

    [Test]
    procedure BareOrderReceiptWithTwoInvoicesCannotInferErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine1, InvoiceLine2 : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A bare order-receipt edge is rejected when the order line has more than one invoice edge.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 100);
        FindReceiptLine(OrderLine, '', PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 60, InvoiceLine1);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine2);

        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine1.SystemId, OrderLine.SystemId, 60));
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine2.SystemId, OrderLine.SystemId, 40));

        // [WHEN] Adding a bare order-receipt edge that cannot pick a single invoice
        asserterror POMatchingGroup.AddMatch(POMatching.OrderReceiptEdge(OrderLine.SystemId, PurchRcptLine.SystemId, 50));

        // [THEN] Rejected: the invoice cannot be inferred
        Assert.ExpectedError('determine a single invoice');
    end;

    [Test]
    procedure BareOrderReceiptWithoutInvoiceEdgeCannotInferErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A bare order-receipt edge is rejected when the order line has no invoice edge to infer from.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 100);
        FindReceiptLine(OrderLine, '', PurchRcptLine);

        // [WHEN] Adding a bare order-receipt edge with no invoice-order budget in the group
        asserterror POMatchingGroup.AddMatch(POMatching.OrderReceiptEdge(OrderLine.SystemId, PurchRcptLine.SystemId, 50));

        // [THEN] Rejected: the invoice cannot be inferred
        Assert.ExpectedError('determine a single invoice');
    end;

    [Test]
    procedure ReceiptForInvoiceCannotExceedThatInvoicesBudgetErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine1, InvoiceLine2 : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A receipt row for one invoice cannot exceed that invoice's budget even if the order total would allow it.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 100);
        FindReceiptLine(OrderLine, '', PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 60, InvoiceLine1);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine2);

        // [GIVEN] Budgets 60 and 40 (order total 100), receipt has 100 not invoiced
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine1.SystemId, OrderLine.SystemId, 60));
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine2.SystemId, OrderLine.SystemId, 40));

        // [WHEN] Pinning 70 of the receipt to invoice 1 whose budget is only 60
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine1.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 70));

        // [THEN] Rejected on the invoice-order budget, not the receipt or order total
        Assert.ExpectedError('exceeds the quantity remaining to invoice on the purchase order line');
    end;

    [Test]
    procedure InvoiceCapCountsBudgetLayerOnlyNotReceiptRows()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine1, OrderLine2, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] The invoice cap sums only the budget (blank-receipt) layer, so a pinned receipt row does not double-count.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine1);
        ReceiveOrder(OrderHeader, OrderLine1, 100);
        FindReceiptLine(OrderLine1, '', PurchRcptLine);
        CreateOrderLine(Vendor, Item, 100, OrderLine2);
        CreateInvoiceLine(Vendor, Item, 200, InvoiceLine);

        // [GIVEN] Invoice (cap 200) allocates 100 to order 1 and pins the receipt for 100
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine1.SystemId, 100));
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine.SystemId, OrderLine1.SystemId, PurchRcptLine.SystemId, 100));

        // [WHEN] Allocating the remaining 100 of the invoice to order 2 (would fail if the receipt row were double-counted)
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine2.SystemId, 100));
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] Both invoice-order budgets persist (invoice consumed 100 + 100 = 200, its full quantity)
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        Assert.AreEqual(2, MatchedOrderLine.Count(), 'Both invoice-order budget rows should persist');
    end;
    #endregion

    #region Group reload and merge with persisted matches
    [Test]
    procedure PersistedAllocationsAreMergedAndEnforceCapsOnAdd()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine1, InvoiceLine2 : Record "Purchase Line";
        POMatchingGroup1: Codeunit "PO Matching Group";
        POMatchingGroup2: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Adding an edge reloads persisted allocations on the same order line and counts them toward the order cap.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine1);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine2);

        // [GIVEN] 60 already persisted from invoice 1 to the order line
        POMatchingGroup1.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine1.SystemId, OrderLine.SystemId, 60));
        POMatchingGroup1.SaveMatchingGroups();

        // [WHEN] A fresh group allocates 60 more from invoice 2 to the same order line (60 + 60 > 100)
        asserterror POMatchingGroup2.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine2.SystemId, OrderLine.SystemId, 60));

        // [THEN] Rejected: the reloaded allocation counts toward the order line's remaining to invoice
        Assert.ExpectedError('exceeds the quantity remaining to invoice on the purchase order line');
    end;

    [Test]
    procedure PersistedEdgeIsOverwrittenWhenReAddedInNewGroup()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup1: Codeunit "PO Matching Group";
        POMatchingGroup2: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Re-adding a persisted edge in a new group overwrites it rather than erroring.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        POMatchingGroup1.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 40));
        POMatchingGroup1.SaveMatchingGroups();

        // [WHEN] A fresh group re-adds the same edge with 70 and saves
        POMatchingGroup2.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 70));
        POMatchingGroup2.SaveMatchingGroups();

        // [THEN] One row persists with the updated quantity
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        Assert.AreEqual(1, MatchedOrderLine.Count(), 'Should still be a single row');
        MatchedOrderLine.FindFirst();
        Assert.AreEqual(70, MatchedOrderLine."Qty. to Invoice", 'Quantity should be overwritten');
    end;

    [Test]
    procedure PersistRevalidatesAgainstExternallyChangedDocuments()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A group valid at creation is revalidated at save and rejected if the order was invoiced meanwhile.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 100);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] An invoice-order edge accepted while the order line has 100 remaining to invoice
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));

        // [GIVEN] The order line is partly invoiced by another posting, dropping its remaining to invoice to 40
        PostOrderInvoice(OrderHeader, OrderLine, 60);

        // [WHEN] Saving the group
        asserterror POMatchingGroup.SaveMatchingGroups();

        // [THEN] Rejected at save: the order line no longer has room for the allocation
        Assert.ExpectedError('exceeds the quantity remaining to invoice on the purchase order line');
    end;

    [Test]
    procedure ReloadPullsWholeComponentAndEnforcesReceiptCap()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine1, InvoiceLine2 : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        POMatchingGroup1: Codeunit "PO Matching Group";
        POMatchingGroup2: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Reloading from one leg pulls the whole connected component so the receipt cap sees prior allocations.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 200, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, 100);
        FindReceiptLine(OrderLine, '', PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine1);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine2);

        // [GIVEN] Invoice 1 fully consumes the receipt (100 of 100 received not invoiced), persisted
        POMatchingGroup1.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine1.SystemId, OrderLine.SystemId, 100));
        POMatchingGroup1.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine1.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 100));
        POMatchingGroup1.SaveMatchingGroups();

        // [WHEN] A fresh group budgets invoice 2 on the order, then pins the same (already-exhausted) receipt
        POMatchingGroup2.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine2.SystemId, OrderLine.SystemId, 100));
        asserterror POMatchingGroup2.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine2.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 100));

        // [THEN] Rejected: the reloaded receipt row from invoice 1 leaves nothing not invoiced
        Assert.ExpectedError('exceeds the quantity received not invoiced');
    end;
    #endregion

    #region Non-quantity (parity) validations
    [Test]
    procedure AddMatchMismatchedLinesErrors()
    var
        Vendor: Record Vendor;
        Item1, Item2 : Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Matching an invoice line and order line of different items is rejected.
        Initialize(Vendor, Item1);
        LibraryInventory.CreateItem(Item2);
        CreateOrderLine(Vendor, Item1, 100, OrderLine);
        CreateInvoiceLine(Vendor, Item2, 100, InvoiceLine);

        // [WHEN] Matching lines that do not agree on item
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 40));

        // [THEN] Rejected: lines must have the same type and number
        Assert.ExpectedError('same type and number');
    end;

    [Test]
    procedure AddInvoiceOrderMatchPrepaymentOrderErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Matching to an order line that carries a prepayment is rejected.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine);

        // [GIVEN] The order line has a non-zero prepayment %
        OrderLine."Prepayment %" := 10;
        OrderLine.Modify();

        // [WHEN] Adding an invoice-order match
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 40));

        // [THEN] Rejected: prepayment not supported
        Assert.ExpectedError('prepayment');
    end;

    [Test]
    procedure AddInvoiceOrderMatchItemChargeOrderErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Matching to an item charge order line is rejected.
        Initialize(Vendor, Item);
        CreateOrderLine(Vendor, Item, 100, OrderLine);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine);

        // [GIVEN] The order line is an item charge line
        OrderLine.Type := OrderLine.Type::"Charge (Item)";
        OrderLine.Modify();

        // [WHEN] Adding an invoice-order match
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 40));

        // [THEN] Rejected: item charge not supported
        Assert.ExpectedError('item charge');
    end;

    [Test]
    procedure AddInvoiceOrderMatchDifferentVendorErrors()
    var
        Vendor1, Vendor2 : Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] An invoice line can only match order lines of the same vendor and currency.
        Initialize(Vendor1, Item);
        LibraryPurchase.CreateVendor(Vendor2);
        CreateOrderLine(Vendor1, Item, 100, OrderLine);
        CreateInvoiceLine(Vendor2, Item, 40, InvoiceLine);

        // [WHEN] Matching an invoice of one vendor to an order of another vendor
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 40));

        // [THEN] Rejected: vendor/currency must agree
        Assert.ExpectedError('same buy-from vendor');
    end;

    [Test]
    procedure AddOrderReceiptMatchReceiptOfOtherOrderErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader1, OrderHeader2 : Record "Purchase Header";
        OrderLine1, OrderLine2, InvoiceLine : Record "Purchase Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A receipt line that belongs to a different order line (same item) cannot be pinned to this order line.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader1, OrderLine1);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader2, OrderLine2);
        ReceiveOrder(OrderHeader2, OrderLine2, 100);
        FindReceiptLine(OrderLine2, '', PurchRcptLine2);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [WHEN] Pinning order 2's receipt onto order 1 via an explicit invoice-order-receipt edge
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine.SystemId, OrderLine1.SystemId, PurchRcptLine2.SystemId, 100));

        // [THEN] Rejected: the receipt does not belong to the matched order line
        Assert.ExpectedError('does not belong to the matched order line');
    end;

    [Test]
    procedure AddOrderReceiptMatchTrackedReceiptPartialErrors()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A receipt carrying item tracking must be invoiced in full; a partial receipt edge is rejected.
        CreateLotTrackedReceivedOrder(Vendor, Item, 100, OrderLine, PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] An invoice-order budget of 100
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));

        // [WHEN] Pinning only 40 of the tracked receipt
        asserterror POMatchingGroup.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 40));

        // [THEN] Rejected: tracked receipts are all-or-nothing
        Assert.ExpectedError('must be invoiced in full');
    end;

    [Test]
    procedure AddOrderReceiptMatchTrackedReceiptInFullSucceeds()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A tracked receipt pinned in full is accepted and persisted.
        CreateLotTrackedReceivedOrder(Vendor, Item, 100, OrderLine, PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [WHEN] Budgeting the invoice and pinning the tracked receipt in full, then saving
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 100));
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The full tracked receipt row is persisted
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Full tracked receipt row should persist');
        Assert.AreEqual(100, MatchedOrderLine."Qty. to Invoice", 'Receipt row Qty. to Invoice');
    end;

    [Test]
    procedure ReceiptOnInvoiceComputedFromHeaderAtPersist()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderHeader: Record "Purchase Header";
        OrderLine, InvoiceLine : Record "Purchase Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Receipt on Invoice is computed at persist time from the order line, not while building the buffer.
        Initialize(Vendor, Item);
        CreateOrderLineWithHeader(Vendor, Item, 100, OrderHeader, OrderLine);
        OrderLine."Receipt on Invoice" := true; // enable directly on the line, bypassing setup validations
        OrderLine.Modify();
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine);

        // [WHEN] Adding an invoice-order edge and saving
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 40));
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The persisted budget row's Receipt on Invoice reflects the order line
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", EmptyGuid);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Budget row should exist');
        Assert.IsTrue(MatchedOrderLine."Receipt on Invoice", 'Receipt on Invoice should be computed from the order line at persist');
    end;
    #endregion

    #region Covering receipts
    [Test]
    procedure SuggestCoveringReceiptsFullyCoversBudget()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A budget fully backed by a receipt is covered by a full receipt edge.
        Initialize(Vendor, Item);
        CreateReceivedOrder(Vendor, Item, 100, 100, OrderLine, PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] An invoice-order budget of 100 with no receipt edges
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));

        // [WHEN] Suggesting covering receipts and saving
        POMatching.SuggestCoveringReceipts(POMatchingGroup);
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The receipt is fully covered
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Receipt edge should exist');
        Assert.AreEqual(100, MatchedOrderLine."Qty. to Invoice", 'Receipt edge should cover the full budget');
    end;

    [Test]
    procedure SuggestCoveringReceiptsPartialLeavesRemainder()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] When receipts cover only part of the budget, the rest stays uncovered (receive-on-invoice remainder).
        Initialize(Vendor, Item);
        CreateReceivedOrder(Vendor, Item, 100, 60, OrderLine, PurchRcptLine); // only 60 received
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] A budget of 100 but only 60 received not invoiced
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));

        // [WHEN] Suggesting covering receipts and saving
        POMatching.SuggestCoveringReceipts(POMatchingGroup);
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The receipt edge covers 60; the remaining 40 stays as budget only
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Receipt edge should exist');
        Assert.AreEqual(60, MatchedOrderLine."Qty. to Invoice", 'Receipt edge should cover only the received quantity');
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId");
        MatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<>%1', EmptyGuid);
        Assert.AreEqual(1, MatchedOrderLine.Count(), 'Only one receipt edge should exist');
    end;

    [Test]
    procedure SuggestCoveringReceiptsGrowsExistingEdge()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] An existing partial receipt edge is grown to cover the remaining budget.
        Initialize(Vendor, Item);
        CreateReceivedOrder(Vendor, Item, 100, 100, OrderLine, PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] A budget of 100 and a pre-existing receipt edge of 30
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderReceiptEdge(InvoiceLine.SystemId, OrderLine.SystemId, PurchRcptLine.SystemId, 30));

        // [WHEN] Suggesting covering receipts and saving
        POMatching.SuggestCoveringReceipts(POMatchingGroup);
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The existing edge is grown to the full 100 (30 + 70), not duplicated
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        Assert.AreEqual(1, MatchedOrderLine.Count(), 'Should still be a single receipt edge');
        MatchedOrderLine.FindFirst();
        Assert.AreEqual(100, MatchedOrderLine."Qty. to Invoice", 'Receipt edge should be grown to the full budget');
    end;

    [Test]
    procedure SuggestCoveringReceiptsSplitsSharedReceiptAcrossInvoices()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine1, InvoiceLine2 : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] Two invoices on the same order line share one receipt's capacity without double-booking.
        Initialize(Vendor, Item);
        CreateReceivedOrder(Vendor, Item, 100, 100, OrderLine, PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 60, InvoiceLine1);
        CreateInvoiceLine(Vendor, Item, 40, InvoiceLine2);

        // [GIVEN] Two budgets on the same order line (60 + 40) sharing one receipt of 100
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine1.SystemId, OrderLine.SystemId, 60));
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine2.SystemId, OrderLine.SystemId, 40));

        // [WHEN] Suggesting covering receipts and saving
        POMatching.SuggestCoveringReceipts(POMatchingGroup);
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The receipt is split 60/40 across the two invoices
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine1.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Invoice 1 receipt edge should exist');
        Assert.AreEqual(60, MatchedOrderLine."Qty. to Invoice", 'Invoice 1 receipt qty');
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine2.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Invoice 2 receipt edge should exist');
        Assert.AreEqual(40, MatchedOrderLine."Qty. to Invoice", 'Invoice 2 receipt qty');
    end;

    [Test]
    procedure SuggestCoveringReceiptsTrackedReceiptTakenInFull()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A tracked receipt whose full quantity fits the budget is covered in full.
        CreateLotTrackedReceivedOrder(Vendor, Item, 100, OrderLine, PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 100, InvoiceLine);

        // [GIVEN] A budget of 100 on a lot-tracked receipt of 100
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 100));

        // [WHEN] Suggesting covering receipts and saving
        POMatching.SuggestCoveringReceipts(POMatchingGroup);
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] The tracked receipt is covered in full
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        MatchedOrderLine.SetRange("Matched Rcpt./Shpt. Line SysId", PurchRcptLine.SystemId);
        Assert.IsTrue(MatchedOrderLine.FindFirst(), 'Tracked receipt edge should exist');
        Assert.AreEqual(100, MatchedOrderLine."Qty. to Invoice", 'Tracked receipt covered in full');
    end;

    [Test]
    procedure SuggestCoveringReceiptsTrackedReceiptSkippedWhenDoesntFit()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        OrderLine, InvoiceLine : Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        MatchedOrderLine: Record "Matched Order Line";
        POMatchingGroup: Codeunit "PO Matching Group";
    begin
        // [SCENARIO] A tracked receipt larger than the budget is skipped (all-or-nothing); nothing is covered.
        CreateLotTrackedReceivedOrder(Vendor, Item, 100, OrderLine, PurchRcptLine);
        CreateInvoiceLine(Vendor, Item, 60, InvoiceLine);

        // [GIVEN] A budget of only 60 on a lot-tracked receipt of 100
        POMatchingGroup.AddMatch(POMatching.InvoiceOrderEdge(InvoiceLine.SystemId, OrderLine.SystemId, 60));

        // [WHEN] Suggesting covering receipts and saving
        POMatching.SuggestCoveringReceipts(POMatchingGroup);
        POMatchingGroup.SaveMatchingGroups();

        // [THEN] No receipt edge is added (the tracked receipt could not be taken in full)
        MatchedOrderLine.SetRange("Document Line SystemId", InvoiceLine.SystemId);
        MatchedOrderLine.SetFilter("Matched Rcpt./Shpt. Line SysId", '<>%1', EmptyGuid);
        Assert.AreEqual(0, MatchedOrderLine.Count(), 'No receipt edge should be added for a tracked receipt that does not fit');
    end;
    #endregion

    #region Test helpers
    local procedure Initialize(var Vendor: Record Vendor; var Item: Record Item)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreatePurchaseUoM(var Item: Record Item; QtyPerUoM: Decimal; var UnitOfMeasure: Record "Unit of Measure")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, QtyPerUoM);
        Item.Validate("Purch. Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateOrderLine(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateOrderLineWithHeader(Vendor, Item, Qty, PurchaseHeader, PurchaseLine);
    end;

    local procedure CreateOrderLineWithHeader(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateInvoiceLine(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateOrderLineWithUoM(Vendor: Record Vendor; Item: Record Item; UnitOfMeasureCode: Code[10]; Qty: Decimal; var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateInvoiceLineWithUoM(Vendor: Record Vendor; Item: Record Item; UnitOfMeasureCode: Code[10]; Qty: Decimal; var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure ReceiveOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    local procedure PostOrderInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToInvoice: Decimal)
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    local procedure FindReceiptLine(PurchaseLineOrder: Record "Purchase Line"; ExcludeDocumentNo: Code[20]; var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        PurchRcptLine.Reset();
        PurchRcptLine.SetRange("Order No.", PurchaseLineOrder."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLineOrder."Line No.");
        if ExcludeDocumentNo <> '' then
            PurchRcptLine.SetFilter("Document No.", '<>%1', ExcludeDocumentNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure CreateReceivedOrder(Vendor: Record Vendor; Item: Record Item; OrderQty: Decimal; ReceiveQty: Decimal; var OrderLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        OrderHeader: Record "Purchase Header";
    begin
        CreateOrderLineWithHeader(Vendor, Item, OrderQty, OrderHeader, OrderLine);
        ReceiveOrder(OrderHeader, OrderLine, ReceiveQty);
        FindReceiptLine(OrderLine, '', PurchRcptLine);
    end;

    local procedure CreateLotTrackedReceivedOrder(var Vendor: Record Vendor; var Item: Record Item; Qty: Decimal; var OrderLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line")    var
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        OrderHeader: Record "Purchase Header";
        LotNo: Code[50];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true); // lot-specific
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        LibraryPurchase.CreatePurchHeader(OrderHeader, OrderHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(OrderLine, OrderHeader, OrderLine.Type::Item, Item."No.", Qty);
        OrderLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        OrderLine.Modify(true);

        LotNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, OrderLine, '', LotNo, Qty);
        LibraryPurchase.PostPurchaseDocument(OrderHeader, true, false);
        OrderLine.Get(OrderLine."Document Type", OrderLine."Document No.", OrderLine."Line No.");

        PurchRcptLine.SetRange("Order No.", OrderLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", OrderLine."Line No.");
        PurchRcptLine.FindFirst();
    end;
    #endregion
}
