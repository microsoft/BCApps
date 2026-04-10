codeunit 137287 "SCM Inventory Costing II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Inventory Costing] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        NegativeAmountErr: Label 'Amount must be negative in Gen. Journal Line';
        PositiveAmountErr: Label 'Amount must be positive in Gen. Journal Line';
        UnexpMsg: Label 'Value Mismatch.';
        InvalidatedAssignmentErr: Label 'The order line that the item charge was originally assigned to has been fully posted. You must reassign the item charge to the posted receipt or shipment.';
        PartialAssignmentMsg: Label 'The remaining amount to assign is';
        AssignableAmountErr: Label 'Assignable Amount is not correct.';
        DuplicateJournalQst: Label 'Duplicate Revaluation Journals will be generated';
        ItemJnlLineCountErr: Label 'There should be %1 Item Journal Line(s) for Item %2.';
        CostAmountNonInvtblErr: Label 'Function NonInvtblCostAmt returned wrong value.';
        ActualCostErr: Label 'Incorrect Actual Cost LCY';
        ItemTrackingMode: Option AssignSerialNos,SelectEntries,CreateThreeLots;

    [Test]
    [Scope('OnPrem')]
    procedure ChargeAssignmentUsingPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Item Charge Assignment(Purch.) using Sales Order and Purchase Invoice.
        Initialize();
        ChargeAssignmentUsingPurchaseDocument(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChargeAssignmentUsingPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Item Charge Assignment(Purch.) using Sales Order and Purchase Credit Memo.
        Initialize();
        ChargeAssignmentUsingPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChargeAssignmentUsingPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Item Charge Assignment(Purch.) using Sales Order and Purchase Return Order.
        Initialize();
        ChargeAssignmentUsingPurchaseDocument(PurchaseHeader."Document Type"::"Return Order");
    end;

    local procedure ChargeAssignmentUsingPurchaseDocument(PurchaseDocumentType: Enum "Purchase Document Type")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and post as Sales Order and create Purchase Invoice with Charge Item with Random value.
        CreateAndPostSalesOrder(SalesLine, SalesHeader."Document Type"::Order);
        CreatePurchaseDocumentUsingChargeItem(PurchaseLine, PurchaseDocumentType, LibraryRandom.RandDec(10, 2));

        // Exercise.
        CreateItemChargeAssignmentUsingShipmentLine(ItemChargeAssignmentPurch, PurchaseLine, SalesLine."Document No.", SalesLine."No.");

        // Verify: Verify values on Item Charge Assignment.
        ItemChargeAssignmentPurch.TestField("Amount to Assign", PurchaseLine.Amount);
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", 1);  // Using 1 because only one Quantity of Charge Item is assigned.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithChargeAssignment()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Value Entry for Charge Item with Non Inventoriable for Purchase Invoice.
        Initialize();
        PostPurchaseDocumentWithChargeAssignment(PurchaseHeader."Document Type"::Invoice, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderWithChargeAssignment()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Value Entry for Charge Item with Non Inventoriable for Purchase Return Order.
        Initialize();
        PostPurchaseDocumentWithChargeAssignment(PurchaseHeader."Document Type"::"Return Order", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoWithChargeAssignment()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Value Entry for Charge Item with Non Inventoriable for Purchase Credit Memo.
        Initialize();
        PostPurchaseDocumentWithChargeAssignment(PurchaseHeader."Document Type"::"Credit Memo", 1);
    end;

    local procedure PostPurchaseDocumentWithChargeAssignment(PurchaseDocumentType: Enum "Purchase Document Type"; AmountSignFactor: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post as Sales Order and create Purchase Invoice with Charge Item.
        CreateAndPostSalesOrder(SalesLine, SalesHeader."Document Type"::Order);
        CreatePurchaseDocumentAndAssignCharge(
          PurchaseLine, PurchaseDocumentType, SalesLine."Document No.", SalesLine."No.", SalesLine.Quantity);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Value Entry for Charge Item with Non Inventoriable.
        VerifyValueEntryForChargeItem(DocumentNo, PurchaseLine."No.", -PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost", false);

        // Verify: Verify Value Entry for Charge Item with Non Inventoriable Cost.
        VerifyNonInventoriableCost(
          DocumentNo, PurchaseLine."No.", -PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost",
          AmountSignFactor * PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChargeAssignmentUsingPurchaseInvoiceWithMultipleLines()
    var
        PurchaseLine: Record "Purchase Line";
        GlobalItemNo: Variant;
    begin
        // Verify Item Charge Assignment for both Shipment lines.

        // Setup.
        Initialize();

        // Exercise.
        ChargeAssignmentUsingShipmentLines(PurchaseLine, 1);  // Taking 1 for Charge Item Amount to Assign.
        LibraryVariableStorage.Dequeue(GlobalItemNo);
        LibraryVariableStorage.Dequeue(GlobalItemNo);

        // Verify: Verify Item Charge Assignment for both Shipment lines.
        VerifyChargeItemAssignment(GlobalItemNo, PurchaseLine.Amount);
        VerifyChargeItemAssignment(GlobalItemNo, PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInvoiceWithMultipleLinesChargeAssignmentError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error message while posting Purchase Invoice with Qty. to Assign more than Purchase Invoice Quantity.

        // Setup: Create and post as Sales Order with two line using different Item.
        Initialize();
        ChargeAssignmentUsingShipmentLines(PurchaseLine, 1);  // Taking 1 for Charge Item
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise: Create and post a Purchase Invoice and create Charge Item Assignment for all the Shipment lines.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Error message doesn't appear while posting Purchase Invoice with Qty. to Assign more than Purchase Invoice Quantity.
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithMultipleLinesWithChargeAssignment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify Inventoriable and values in Value Entry.

        // Setup: Create and post as Sales Order with two line using different Items. Create Purchase Invoice and create Charge Item Assignment for all the Shipment lines.
        Initialize();
        LibraryVariableStorage.Enqueue(1);  // Enqueue option value for ItemChargeAssignMenuHandler.
        ItemChargeNo := ChargeAssignmentUsingShipmentLines(PurchaseLine, 1);
        PurchaseLine.ShowItemChargeAssgnt();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Value Entry for Charge Item with Non Inventoriable.
        VerifyValueEntryForChargeItem(DocumentNo, ItemChargeNo, -PurchaseLine.Quantity, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesShipmentWithNegativeAmountUsingChargeAssignment()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        // Verify error message while posting Purchase Invoice with Negative Quantity.

        // Setup: Create Purchase Invoice with negative Direct Unit Cost using Charge Item.
        Initialize();
        PostSalesAndPurchaseDocumentForChargeItem(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, SalesHeader."Document Type"::Order);

        // Exercise.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify error message while posting Purchase Invoice.
        Assert.ExpectedError(StrSubstNo(NegativeAmountErr));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoWithNegativeDirectUnitCost()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        // Verify error message while posting Purchase Credit Memo with Negative Amount.

        // Setup: Create Purchase Credit Memo with Charge Item.
        Initialize();
        PostSalesAndPurchaseDocumentForChargeItem(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::Order);

        // Exercise.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify error message while posting Purchase Credit Memo.
        Assert.ExpectedError(StrSubstNo(PositiveAmountErr));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssgntUsingSalesRetOrderAndPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        // Verify Item Charge Assignment(Purch.) using Sales Return Order and Purchase Invoice.
        Initialize();
        ChgAssgntUsingSalesRetOrder(PurchaseHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssgntUsingSalesRetOrderAndPurchRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        // Verify Item Charge Assignment(Purch.) using Sales Return Order and Purchase Return Order.
        Initialize();
        ChgAssgntUsingSalesRetOrder(PurchaseHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssgntUsingSalesRetOrderAndPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        // Verify Item Charge Assignment(Purch.) using Sales Return Order and Purchase Credit Memo.
        Initialize();
        ChgAssgntUsingSalesRetOrder(PurchaseHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order");
    end;

    local procedure ChgAssgntUsingSalesRetOrder(PurchaseDocumentType: Enum "Purchase Document Type"; SalesDocumentType: Enum "Sales Document Type")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and post as Sales Return Order and create Purchase Document with Charge Item with Random value.
        CreateAndPostSalesOrder(SalesLine, SalesDocumentType);
        CreatePurchaseDocumentUsingChargeItem(PurchaseLine, PurchaseDocumentType, LibraryRandom.RandDec(10, 2));

        // Exercise.
        CreateItemChargeAssignmentUsingReceiptLine(ItemChargeAssignmentPurch, PurchaseLine, SalesLine."Document No.", SalesLine."No.");

        // Verify: Verify values on Item Charge Assignment.
        ItemChargeAssignmentPurch.TestField("Amount to Assign", PurchaseLine.Amount);
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", 1);  // Using 1 because only one Quantity of Charge Item is assigned.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceWithChgItemUsingSalesRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Value Entry for Charge Item with Inventoriable for Purchase Invoice.
        Initialize();
        PostAndVerifyPurchDocWithChgAssignt(PurchaseHeader."Document Type"::Invoice)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchRetOrderWithChgItemUsingSalesRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Value Entry for Charge Item with Inventoriable for Purchase Return Order.
        Initialize();
        PostAndVerifyPurchDocWithChgAssignt(PurchaseHeader."Document Type"::"Return Order")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoWithChgItemUsingSalesRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Value Entry for Charge Item with Inventoriable for Purchase Credit Memo.
        Initialize();
        PostAndVerifyPurchDocWithChgAssignt(PurchaseHeader."Document Type"::"Credit Memo")
    end;

    local procedure PostAndVerifyPurchDocWithChgAssignt(PurchaseDocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post as Sales Return Order and create Purchase Document with Charge Item.
        CreateAndPostSalesOrder(SalesLine, SalesHeader."Document Type"::"Return Order");
        CreatePurchaseDocumentWithChargeAssignment(
          PurchaseLine, PurchaseDocumentType, SalesLine."Document No.", SalesLine."No.", SalesLine.Quantity);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Value Entry for Charge Item with Inventoriable.
        VerifyValueEntryForChargeItem(DocumentNo, PurchaseLine."No.", PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost", true);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure PostChgAssigntWithMultipleLineUsingSalesRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify Inventoriable and values in Value Entry.

        // Setup: Create and post as Sales Return Order with multiple line and create Charge Item Assignment using Receipt Lines.
        Initialize();
        ItemChargeNo := ChargeAssignmentUsingReceiptLines(PurchaseLine, 1);
        LibraryVariableStorage.Enqueue(1);  // Enqueue option value for ItemChargeAssignMenuHandler.
        PurchaseLine.ShowItemChargeAssgnt();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Value Entry for Charge Item with Inventoriable.
        VerifyValueEntryForChargeItem(DocumentNo, ItemChargeNo, PurchaseLine.Quantity, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInvoiceUsingSalesRetOrderError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error message while posting Purchase Invoice using Sales Return Order with Qty. to Assign more than Purchase Invoice Quantity.

        // Setup: Create and post as Sales Return Order with multiple line.
        Initialize();
        ChargeAssignmentUsingReceiptLines(PurchaseLine, 1);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Error message doesn't appear while posting Purchase Invoice with Qty. to Assign more than Purchase Invoice Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeAmountErrorUsingSalesRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        // Verify error message while posting Purchase Invoice with Negative Direct Unit Cost.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Invoice with negative Direct Unit Cost using Charge Item and Post.
        PostPurchaseDocumentUsingSalesReturnOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Return Order");
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify error message while posting Purchase Invoice.
        Assert.ExpectedError(StrSubstNo(NegativeAmountErr));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveAmountErrorUsingSalesRetOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        // Verify error message while posting Purchase Credit Memo with Negative value.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Credit Memo with Charge Item and Post.
        PostPurchaseDocumentUsingSalesReturnOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order");
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify error message while posting Purchase Credit Memo.
        Assert.ExpectedError(StrSubstNo(PositiveAmountErr));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderOrInvoiceWithPositiveChgAssigntToPositivePurchRcpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 330811] When Positive Item Charge is assigned in Purchase Order to Purchase Receipt with positive Qty then Value Entry has positive actual cost
        Initialize();
        PurchDocWithChgAssigntToPurchRcptActualCost(PurchaseHeader."Document Type"::Order, 1, 1, 1, 1);
        PurchDocWithChgAssigntToPurchRcptActualCost(PurchaseHeader."Document Type"::Invoice, 1, 1, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderOrInvoiceWithPositiveChgAssigntToNegativePurchRcpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 330811] When Positive Item Charge is assigned in Purchase Order to Purchase Receipt with negative Qty then Value Entry has positive non-invt cost
        Initialize();
        PurchDocWithChgAssigntToPurchRcptNonInvtCost(PurchaseHeader."Document Type"::Order, -1, 1, 1, 1);
        PurchDocWithChgAssigntToPurchRcptNonInvtCost(PurchaseHeader."Document Type"::Invoice, -1, 1, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderOrInvoiceWithNegativeChgAssigntToPositivePurchRcpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 330811] When Negative Item Charge is assigned in Purchase Order to Purchase Receipt with positive Qty then Value Entry has negative actual cost
        Initialize();
        PurchDocWithChgAssigntToPurchRcptActualCost(PurchaseHeader."Document Type"::Order, 1, -1, 1, -1);
        PurchDocWithChgAssigntToPurchRcptActualCost(PurchaseHeader."Document Type"::Invoice, 1, -1, 1, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderOrInvoiceWithNegativeChgAssigntToNegativePurchRcpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 330811] When Negative Item Charge is assigned in Purchase Order to Purchase Receipt with negative Qty then Value Entry has negative non-invt cost
        Initialize();
        PurchDocWithChgAssigntToPurchRcptNonInvtCost(PurchaseHeader."Document Type"::Order, -1, -1, 1, -1);
        PurchDocWithChgAssigntToPurchRcptNonInvtCost(PurchaseHeader."Document Type"::Invoice, -1, -1, 1, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRetOrderOrCrMemoWithPositiveChgAssigntToPositivePurchRcpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 330811] When Positive Item Charge is assigned in Purchase Return Order to Purchase Receipt with positive Qty then Value Entry has negative actual cost
        Initialize();
        PurchDocWithChgAssigntToPurchRcptActualCost(PurchaseHeader."Document Type"::"Return Order", 1, 1, 1, -1);
        PurchDocWithChgAssigntToPurchRcptActualCost(PurchaseHeader."Document Type"::"Credit Memo", 1, 1, 1, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRetOrderOrCrMemoWithPositiveChgAssigntToNegativePurchRcpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 330811] When Positive Item Charge is assigned in Purchase Return Order to Purchase Receipt with negative Qty then Value Entry has negative non-invt cost
        Initialize();
        PurchDocWithChgAssigntToPurchRcptNonInvtCost(PurchaseHeader."Document Type"::"Return Order", -1, 1, 1, -1);
        PurchDocWithChgAssigntToPurchRcptNonInvtCost(PurchaseHeader."Document Type"::"Credit Memo", -1, 1, 1, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRetOrderOrCrMemoWithNegativeChgAssigntToPositivePurchRcpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 330811] When Negative Item Charge is assigned in Purchase Return Order to Purchase Receipt with positive Qty then Value Entry has positive actual cost
        Initialize();
        PurchDocWithChgAssigntToPurchRcptActualCost(PurchaseHeader."Document Type"::"Return Order", 1, -1, 1, 1);
        PurchDocWithChgAssigntToPurchRcptActualCost(PurchaseHeader."Document Type"::"Credit Memo", 1, -1, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRetOrderOrCrMemoWithNegativeChgAssigntToNegativePurchRcpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 330811] When Negative Item Charge is assigned in Purchase Return Order to Purchase Receipt with negative Qty then Value Entry has positive non-invt cost
        Initialize();
        PurchDocWithChgAssigntToPurchRcptNonInvtCost(PurchaseHeader."Document Type"::"Return Order", -1, -1, 1, 1);
        PurchDocWithChgAssigntToPurchRcptNonInvtCost(PurchaseHeader."Document Type"::"Credit Memo", -1, -1, 1, 1);
    end;

    local procedure PurchDocWithChgAssigntToPurchRcptNonInvtCost(DocumentType: Enum "Purchase Document Type"; PurchDocSign: Integer; QuantitySignFactor: Integer; CostSignFactor: Integer; AmountSignFactor: Integer)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create Purchase Order with negative Quantity.
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, PurchDocSign);
        FindReceiptLine(PurchRcptLine, PurchaseLine."Document No.", PurchaseLine."No.");

        // Create Purchase Document for Charge Item and assign to Receipt.
        CreatePurchaseDocumentWithChargeItemAndItem(
          PurchaseLine2, DocumentType, PurchaseLine."Buy-from Vendor No.", QuantitySignFactor, CostSignFactor);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine2, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
        PurchaseHeader.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");

        // Exercise: Post Purchase Document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Value Entry for Charge Item.
        VerifyNonInventoriableCost(
          DocumentNo, PurchaseLine2."No.", PurchaseLine.Quantity,
          AmountSignFactor * Abs(PurchaseLine2.Quantity * PurchaseLine2."Direct Unit Cost"));
    end;

    local procedure PurchDocWithChgAssigntToPurchRcptActualCost(DocumentType: Enum "Purchase Document Type"; PurchDocSign: Integer; QuantitySignFactor: Integer; CostSignFactor: Integer; AmountSignFactor: Integer)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create Purchase Order with negative Quantity.
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, PurchDocSign);
        FindReceiptLine(PurchRcptLine, PurchaseLine."Document No.", PurchaseLine."No.");

        // Create Purchase Document for Charge Item and assign to Receipt.
        CreatePurchaseDocumentWithChargeItemAndItem(
          PurchaseLine2, DocumentType, PurchaseLine."Buy-from Vendor No.", QuantitySignFactor, CostSignFactor);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine2, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
        PurchaseHeader.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");

        // Exercise: Post Purchase Document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Value Entry for Charge Item.
        VerifyActualCost(
          DocumentNo, PurchaseLine2."No.", PurchaseLine.Quantity,
          AmountSignFactor * Abs(PurchaseLine2.Quantity * PurchaseLine2."Direct Unit Cost"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithChgAssigntToPurchRetShpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Non-inventoriable Cost on Value Entry for Posted Purchase Invoice after assigning Charge to Return Shipment.
        Initialize();
        PurchDocWithChgAssgntToPurchRetShipt(PurchaseHeader."Document Type"::Order, 1, 1, 1);  // Respective SignFactors for Quantity, Cost and Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithNegtiveCostChgAssigntToPurchRetShpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Non-inventoriable Cost on Value Entry for Posted Purchase Invoice after assigning Charge with negative Cost to Return Shipment.
        Initialize();
        PurchDocWithChgAssgntToPurchRetShipt(PurchaseHeader."Document Type"::Order, 1, -1, 1);  // Respective SignFactors for Quantity, Cost and Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRetOrderWithChgAssigntToPurchRetShpt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Non-inventoriable Cost on Value Entry for Posted Purchase Credit Memo after assigning Charge to Purchase Return Shipment.
        Initialize();
        PurchDocWithChgAssgntToPurchRetShipt(PurchaseHeader."Document Type"::"Return Order", 1, 1, -1); // Respective SignFactors for Quantity, Cost and Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithNegQtyAndCostChgAssgntToPurchRetShipt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Non-inventoriable Cost on Value Entry for Posted Purchase Credit Memo after assigning negative Charge with negative Cost to Purchase Return Shipment.
        Initialize();
        PurchDocWithChgAssgntToPurchRetShipt(PurchaseHeader."Document Type"::"Credit Memo", -1, -1, -1); // Respective SignFactors for Quantity, Cost and Amount.
    end;

    local procedure PurchDocWithChgAssgntToPurchRetShipt(DocumentType: Enum "Purchase Document Type"; QuantitySignFactor: Integer; CostSignFactor: Integer; AmountSignFactor: Integer)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create Purchase Return Order.
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Return Order", 1);  // 1 for Quantity SignFactor.
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine."Document No.", PurchaseLine."No.");

        // Create Purchase Document for Charge Item and assign to Return Shipment.
        CreatePurchaseDocumentWithChargeItemAndItem(
          PurchaseLine2, DocumentType, PurchaseLine."Buy-from Vendor No.", QuantitySignFactor, CostSignFactor);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine2, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Shipment",
          ReturnShipmentLine."Document No.", ReturnShipmentLine."Line No.", ReturnShipmentLine."No.");
        PurchaseHeader.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");

        // Exercise: Post Purchase Document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Value Entry for Charge Item.
        VerifyNonInventoriableCost(
          DocumentNo, PurchaseLine2."No.", -PurchaseLine.Quantity,
          AmountSignFactor * PurchaseLine2.Quantity * PurchaseLine2."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentMultipleLinePageHandler,ReturnShipmentLinesPageHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure SplitOfItemCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        DocumentNo: Code[20];
    begin
        // Verify Non-inventoriable Cost on Value Entry for Posted Purchase Invoice after assigning Charge to Purchase Return Shipment and Purchase Line.
        Initialize();

        // Setup: Create Purchase Return Order.
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Return Order", 1);  // 1 for Quantity SignFactor.
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine."Document No.", PurchaseLine."No.");
        LibraryVariableStorage.Enqueue(PurchaseLine."No.");  // Enqueue for ItemChargeAssignmentMultipleLinePageHandler.

        // Create Purchase Document for Charge Item and assign to Return Shipment.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine."Buy-from Vendor No.");
        CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), -2 * PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");
        CreatePurchaseLine(
          PurchaseLine3, PurchaseHeader, PurchaseLine2.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(),
          2 * PurchaseLine.Quantity, 100 + PurchaseLine."Direct Unit Cost");
        LibraryVariableStorage.Enqueue(2);  // Enqueue option value for ItemChargeAssignMenuHandler.
        PurchaseLine3.ShowItemChargeAssgnt();
        PurchaseHeader.Get(PurchaseLine3."Document Type", PurchaseLine3."Document No.");

        // Exercise: Post Purchase Document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Value Entry for Charge Item.
        VerifyNonInventoriableCost(
          DocumentNo, PurchaseLine3."No.", -PurchaseLine.Quantity,
          PurchaseLine.Quantity * PurchaseLine3.Amount / (PurchaseLine.Quantity + -PurchaseLine2.Quantity));
        VerifyNonInventoriableCost(
          DocumentNo, PurchaseLine3."No.", PurchaseLine2.Quantity,
          -PurchaseLine2.Quantity * PurchaseLine3.Amount / (PurchaseLine.Quantity + -PurchaseLine2.Quantity));
    end;

    [Test]
    [HandlerFunctions('ImplementStandardCostChangesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustedProfitOnStandardCost()
    begin
        // Verify Customer Ledger Entry, Customer Statistic and Posted Sales Invoice Statistic post Sales Order with Implement New Stanadard Cost on Items which is less than Unit Price on Sales Order.
        Initialize();

        OriginalAndAdjustedProfitOnStandardCost(
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2) + LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2) + LibraryRandom.RandDec(10, 2) / 2);  // Standard Cost reuired less than Unit Price.
    end;

    [Test]
    [HandlerFunctions('ImplementStandardCostChangesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NegativeAdjustedProfitOnStandardCost()
    begin
        // Verify Customer Ledger Entry, Customer Statistic and Posted Sales Invoice Statistic after post Sales Order with Implement New Stanadard Cost on Items which is more than Unit Price on Sales Order.
        Initialize();

        OriginalAndAdjustedProfitOnStandardCost(
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2) + LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2) + LibraryRandom.RandDec(10, 2) + LibraryRandom.RandDec(10, 2));  // Standard Cost reuired more than Unit Price.
    end;

    local procedure OriginalAndAdjustedProfitOnStandardCost(StandardCost: Decimal; UnitPrice: Decimal; NewStandardCost: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, create Sales Order with Unit Price more than Standard Cost.
        Item.Get(CreateAndModifyItem(StandardCost));
        Quantity := LibraryRandom.RandDec(10, 2);  // Using Random value for Quantity.
        CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", CreateCustomer(), UnitPrice, Quantity);

        // Create Standard Cost Worksheet and Implement New Stanadard Cost on Item, create and post Purchase Order with Direct Unit Cost same as New Standard Cost.
        ImplementStandardCostChanges(Item, NewStandardCost);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity, NewStandardCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Customer Ledger Entry, Customer Statistic and Posted Sales Invoice Statistic after post Sales Order.
        VerifyCustomerLedgerEntry(
          SalesHeader."Last Posting No.", SalesHeader."Sell-to Customer No.", (UnitPrice - Item."Standard Cost") * Quantity);
        VerifyCustomerStatistic(SalesHeader."Sell-to Customer No.", (UnitPrice - NewStandardCost) * Quantity);
        VerifyPostedSalesInvoiceStatistic(SalesHeader."Last Posting No.", (UnitPrice - NewStandardCost) * Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithInvalidatedChgAssignt()
    var
        PurchLine: Record "Purchase Line";
    begin
        // Verify invalidated Item Charge Assignment cannot be posted in Purchase Order
        Initialize();
        PurchDocWithInvalidatedChgAssignt(PurchLine."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderWithInvalidatedChgAssignt()
    var
        PurchLine: Record "Purchase Line";
    begin
        // Verify invalidated Item Charge Assignment cannot be posted in Purchase Return Order
        Initialize();
        PurchDocWithInvalidatedChgAssignt(PurchLine."Document Type"::"Return Order");
    end;

    local procedure PurchDocWithInvalidatedChgAssignt(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Setup: Create Purchase Document with Item Line and Charge Item Line
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CreateVendor());
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));

        case DocumentType of
            PurchaseLine."Document Type"::Order:
                LibraryPurchase.AssignPurchChargeToPurchaseLine(PurchaseHeader, PurchaseLine,
                  LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
            PurchaseLine."Document Type"::"Return Order":
                LibraryPurchase.AssignPurchChargeToPurchReturnLine(PurchaseHeader, PurchaseLine,
                  LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        end;

        // Get the item charge line
        PurchaseLine2.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine2.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine2.FindFirst();

        // Set the "Qty. to Invoice" of Charge Item Line to 0 and Post the document
        // After the post, "Qty. to Invoice" of Charge Item Line will be set to "Qty. Rcd. Not Invoiced" automatically
        if DocumentType = PurchaseLine."Document Type"::"Return Order" then
            PurchaseLine2.Validate("Return Qty. to Ship", 0)
        else
            PurchaseLine2.Validate("Qty. to Invoice", 0);
        PurchaseLine2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // Update Vendor Invoice No. and Vendor Cr. Memo No.
        UpdatePurchaseHeader(PurchaseHeader);

        // Exercise: Post Invoice for the invalidated item charge assignment
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Post failed
        Assert.ExpectedError(StrSubstNo(InvalidatedAssignmentErr));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithInvalidatedChgAssignt()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify invalidated Item Charge Assignment cannot be posted in Sales Order
        Initialize();
        SalesDocWithInvalidatedChgAssignt(SalesLine."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderWithInvalidatedChgAssignt()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify invalidated Item Charge Assignment cannot be posted in Sales Return Order
        Initialize();
        SalesDocWithInvalidatedChgAssignt(SalesLine."Document Type"::"Return Order");
    end;

    local procedure SalesDocWithInvalidatedChgAssignt(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Setup: Create Sales Document with Item Line and Charge Item Line
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));

        // Assign item charge to current document
        case DocumentType of
            SalesLine."Document Type"::Order:
                LibrarySales.AssignSalesChargeToSalesLine(SalesHeader, SalesLine,
                  LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
            SalesLine."Document Type"::"Return Order":
                LibrarySales.AssignSalesChargeToSalesReturnLine(SalesHeader, SalesLine,
                  LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        end;

        // Get the item charge line
        SalesLine2.SetRange("Document No.", SalesHeader."No.");
        SalesLine2.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine2.FindFirst();

        // Set the "Qty. to Invoice" of Charge Item Line to 0 and Post the document
        // After the post, "Qty. to Invoice" of Charge Item Line will be set to "Qty. Rcd. Not Invoiced" automatically
        if DocumentType = SalesLine."Document Type"::Order then
            SalesLine2.Validate("Qty. to Ship", 0)
        else
            SalesLine2.Validate("Qty. to Invoice", 0);
        SalesLine2.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Post Invoice for the invalidated item charge assignment
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Post failed
        Assert.ExpectedError(StrSubstNo(InvalidatedAssignmentErr));
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntPurchHandler,ItemChargeAssignMenuHandler,ReportPurchaseDocumentTestHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithoutInvDiscAndLnDiscAndPricesIncludingVATUnChecked()
    var
        VendInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ExpdAssignableAmount: Variant;
        VendorNo: Code[20];
    begin
        // Verify Assignable Amount & Rem. Amount To Assign is correct without Line Discount & Invoice Discount & Currency
        // and Prices Including VAT is unchecked.

        // Setup: Create Vendor with Invoice Discount.
        // Create purchase invoice with Item and Charge Item without line discount & invoice discount & Currency.
        Initialize();
        VendorNo := CreateVendorWithInvoiceDiscount(VendInvoiceDisc, '', LibraryRandom.RandDec(10, 5));
        CreatePurchaseDocumentWithMultipleLinesWithItemCharge(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, VendorNo, '', false, 0,
          LibraryRandom.RandDec(1000, 5), LibraryRandom.RandDec(2000, 5)); // Prices Including VAT is unchecked.
        ExpdAssignableAmount := PurchaseLine."Line Amount";

        // Exercise: Assign the Item Charge. Running Suggest Item Charge Assignment.
        // Enqueue Assignable Amount and option = Amount for ItemChargeAssignMenuHandler.
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntPurchHandler before running report.

        // Exercise: Run report Purchase Document - Test.
        // No need run Suggest Item Charge Assignment. Just show Item Charge Assignment.
        RunPurchaseReportAndAssignItemChargeWithoutSuggest(ExpdAssignableAmount);
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntPurchHandler after running report.
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntPurchHandler,ItemChargeAssignMenuHandler,ReportPurchaseDocumentTestHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithCurrencyAndPricesIncludingVATChecked()
    var
        VendInvoiceDisc: Record "Vendor Invoice Disc.";
        Currency: Record Currency;
        PurchaseLine: Record "Purchase Line";
        ExpdAssignableAmount: Variant;
        VendorNo: Code[20];
        VATPct: Decimal;
    begin
        // Verify Assignable Amount & Rem. Amount To Assign is correct with Line Discount & Invoice Discount & Currency
        // and Prices Including VAT is checked.

        // Setup: Create Vendor with Invoice Discount.
        // Create Purchase invoice with Item and Charge Item with line discount & invoice discount & Currency.
        Initialize();
        CreateCurrency(Currency);
        VendorNo := CreateVendorWithInvoiceDiscount(VendInvoiceDisc, Currency.Code, LibraryRandom.RandDec(10, 5));
        VATPct :=
          CreatePurchaseDocumentWithItemChargeAndCalcInvDisc(
            PurchaseLine, VendorNo, Currency.Code, true, LibraryRandom.RandDec(100, 5),
            LibraryRandom.RandDec(10000, 5), LibraryRandom.RandDec(20000, 5)); // Prices Including VAT is checked.
        ExpdAssignableAmount := Round((PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount") / (1 + VATPct / 100));

        // Exercise: Assign the Item Charge. Running Suggest Item Charge Assignment.
        // Enqueue Assignable Amount and option = Amount for ItemChargeAssignMenuHandler.
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntPurchHandler before running report.

        // Exercise: Run report Purchase Document - Test.
        // No need run Suggest Item Charge Assignment. Just show Item Charge Assignment.
        RunPurchaseReportAndAssignItemChargeWithoutSuggest(ExpdAssignableAmount);
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntPurchHandler after running report.
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntPurchHandler,ItemChargeAssignMenuHandler,ReportPurchaseDocumentTestHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithoutCurrencyAndPricesIncludingVATUnChecked()
    var
        VendInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseLine: Record "Purchase Line";
        ExpdAssignableAmount: Variant;
        VendorNo: Code[20];
    begin
        // Verify Assignable Amount & Rem. Amount To Assign is correct with Line Discount & Invoice Discount without Currency
        // and Prices Including VAT is unchecked.

        // Setup: Create Vendor with Invoice Discount.
        // Create Purchase invoice with Item and Charge Item with line discount & invoice discount without currency
        Initialize();
        VendorNo := CreateVendorWithInvoiceDiscount(VendInvoiceDisc, '', LibraryRandom.RandDec(10, 5));
        CreatePurchaseDocumentWithItemChargeAndCalcInvDisc(
          PurchaseLine, VendorNo, '', false, LibraryRandom.RandDec(100, 5),
          LibraryRandom.RandDec(3000, 5), LibraryRandom.RandDec(4000, 5)); // Prices Including VAT is unchecked.
        ExpdAssignableAmount := PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount";

        // Exercise: Assign the Item Charge. Running Suggest Item Charge Assignment.
        // Enqueue Assignable Amount and option = Equally for ItemChargeAssignMenuHandler.
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 1);
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntPurchHandler before running report.

        // Exercise: Run report Purchase Document - Test.
        // No need run Suggest Item Charge Assignment. Just show Item Charge Assignment.
        RunPurchaseReportAndAssignItemChargeWithoutSuggest(ExpdAssignableAmount);
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntPurchHandler after running report.
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmMessagePopupWhenPartialAssignItemChargeForPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendInvoiceDisc: Record "Vendor Invoice Disc.";
        VendorNo: Code[20];
    begin
        // Verify the confirm message pops up with assign item charge partially for Purchase.

        // Setup: Create Vendor with Invoice Discount.
        // Create Purchase invoice with Item and Charge Item without line discount & invoice discount without currency
        Initialize();
        VendorNo := CreateVendorWithInvoiceDiscount(VendInvoiceDisc, '', LibraryRandom.RandDec(10, 5));
        CreatePurchaseDocumentWithMultipleLinesWithItemCharge(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, VendorNo, '', false, 0,
          LibraryRandom.RandDec(5000, 5), LibraryRandom.RandDec(6000, 5)); // Prices Including VAT is unchecked.

        // Exercise: Partial Assign the Item Charge in ItemChargeAssignmentPartialPurchHandler.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(5)); // Partial assign quantity.
        LibraryVariableStorage.Enqueue(PartialAssignmentMsg);
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify: Verify the confirm message pops up when Rem Amount To Assign has value after
        // partially assign item charge for Purchase in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntSalesHandler,ItemChargeAssignMenuHandler,ReportSalesDocumentTestHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithoutInvDiscAndLnDiscAndPricesIncludingVATUnChecked()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        ExpdAssignableAmount: Decimal;
        CustomerNo: Code[20];
    begin
        // Verify Assignable Amount & Rem. Amount To Assign is correct without Line Discount & Invoice Discount & Currency
        // and Prices Including VAT is unchecked.

        // Setup: Create Customer with Invoice Discount.
        // Create sales invoice with Item and Charge Item without line discount & invoice discount & currency.
        Initialize();
        CustomerNo := CreateCustomerWithInvoiceDiscount(CustInvoiceDisc, '', LibraryRandom.RandDec(10, 5));
        CreateSalesDocumentWithMultipleLinesWithItemCharge(
          SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo, '', false, 0,
          LibraryRandom.RandDec(7000, 5), LibraryRandom.RandDec(8000, 5)); // Prices Including VAT is unchecked.
        ExpdAssignableAmount := SalesLine."Line Amount";

        // Exercise: Assign the Item Charge. Running Suggest Item Charge Assignment.
        // Enqueue Assignable Amount and option = Equally for ItemChargeAssignMenuHandler.
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 1);
        SalesLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntSalesHandler before running report.

        // Exercise: Run report Sales Document - Test
        // No need run Suggest Item Charge Assignment. Just show Item Charge Assignment.
        RunSalesReportAndAssignItemChargeWithoutSuggest(ExpdAssignableAmount);
        SalesLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntSalesHandler after running report.
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntSalesHandler,ItemChargeAssignMenuHandler,ReportSalesDocumentTestHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithoutCurrencyAndPricesIncludingVATChecked()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesLine: Record "Sales Line";
        ExpdAssignableAmount: Decimal;
        CustomerNo: Code[20];
        VATPct: Decimal;
    begin
        // Verify Assignable Amount & Rem. Amount To Assign is correct with Line Discount & Invoice Discount without Currency
        // and Prices Including VAT is checked.

        // Setup: Create Customer with Invoice Discount.
        // Create sales invoice with Item and Charge Item with line discount & invoice discount without currency.
        Initialize();
        CustomerNo := CreateCustomerWithInvoiceDiscount(CustInvoiceDisc, '', LibraryRandom.RandDec(10, 5));
        VATPct :=
          CreateSalesDocumentWithItemChargeAndCalcInvDisc(
            SalesLine, CustomerNo, '', true, LibraryRandom.RandDec(100, 5),
            LibraryRandom.RandDec(300, 5), LibraryRandom.RandDec(400, 5)); // Prices Including VAT is checked.
        ExpdAssignableAmount := Round((SalesLine."Line Amount" - SalesLine."Inv. Discount Amount") / (1 + VATPct / 100));

        // Exercise: Assign the Item Charge. Running Suggest Item Charge Assignment.
        // Enqueue Assignable Amount and option = Equally for ItemChargeAssignMenuHandler.
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 1);
        SalesLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntSalesHandler before running report.

        // Exercise: Run Report Sales Document - Test.
        // No need run Suggest Item Charge Assignment. Just show Item Charge Assignment.
        RunSalesReportAndAssignItemChargeWithoutSuggest(ExpdAssignableAmount);
        SalesLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntSalesHandler after running report.
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntSalesHandler,ItemChargeAssignMenuHandler,ReportSalesDocumentTestHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithCurrencyAndPricesIncludingVATUnChecked()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Currency: Record Currency;
        SalesLine: Record "Sales Line";
        ExpdAssignableAmount: Decimal;
        CustomerNo: Code[20];
    begin
        // Verify Assignable Amount & Rem. Amount To Assign is correct without Line Discount with Invoice Discount with Currency
        // and Prices Including VAT is unchecked.

        // Setup: Create sales invoice with multilple lines with currency
        Initialize();
        CreateCurrency(Currency);
        CustomerNo := CreateCustomerWithInvoiceDiscount(CustInvoiceDisc, Currency.Code, LibraryRandom.RandDec(10, 5));
        CreateSalesDocumentWithItemChargeAndCalcInvDisc(
          SalesLine, CustomerNo, Currency.Code, false, 0, LibraryRandom.RandDec(500, 5),
          LibraryRandom.RandDec(600, 5)); // Prices Including VAT is unchecked.
        ExpdAssignableAmount := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";

        // Exercise: Assign the Item Charge. Running Suggest Item Charge Assignment.
        // Enqueue Assignable Amount and option = Amount for ItemChargeAssignMenuHandler.
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        SalesLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntSalesHandler before running report.

        // Exercise: Run Report Sales Document - Test.
        // No need run Suggest Item Charge Assignment. Just show Item Charge Assignment.
        RunSalesReportAndAssignItemChargeWithoutSuggest(ExpdAssignableAmount);
        SalesLine.ShowItemChargeAssgnt();

        // Verify: Verify Assignable Amount & Rem. Amount To Assign is correct
        // in SuggstItemChargeAssgntSalesHandler after running report.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ImplementStandardCostChangesHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DuplicateRevaluationJournalConfirmYes()
    begin
        // Verify Confirm message pops up to indcate duplicate Revaluation Jounal generated from Std Cost Worksheet,
        // then click Yes and verify the duplicate journal line generated.
        Initialize();
        DuplicateRevaluationJournalConfirmMessage(2); // 2 revaluation journal lines will be generated
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ImplementStandardCostChangesHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure DuplicateRevaluationJournalConfirmNo()
    begin
        // Verify no duplicate journal line generated after clicking No on confirm message indcating duplicate Revaluation Jounal generated from Std Cost Worksheet.
        Initialize();
        DuplicateRevaluationJournalConfirmMessage(1); // Only 1 revaluation journal line will be generated
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntPurchHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderPartialAssignItemCharge()
    var
        PurchaseLine: Record "Purchase Line";
        ExpdAssignableAmount: Decimal;
    begin
        // Verify that partial assignment of Item Charge is correct.

        // Setup.
        Initialize();
        ExpdAssignableAmount := PurchOrderPartItemCharge(PurchaseLine, 0, 2, 1);
        PreparePartialReceiptInvoice(PurchaseLine, 1, 1);

        // Exercise & Verify: Assignable Amount & Rem. Amount To Assign are verified to be correct
        // in SuggstItemChargeAssgntPurchHandler.
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        PurchaseLine.ShowItemChargeAssgnt();
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntPurchHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderPartialAssignItemChargeTwice()
    var
        PurchaseLine: Record "Purchase Line";
        ExpdAssignableAmount: Decimal;
    begin
        // Verify that partial assignment of Item Charge is correct: first assign, then post, then assign again.

        // Setup.
        Initialize();
        ExpdAssignableAmount := PurchOrderPartItemCharge(PurchaseLine, 0, 2, 1);

        // Exercise & Verify: Assignable Amount & Rem. Amount To Assign are verified to be correct
        // in SuggstItemChargeAssgntPurchHandler.
        PreparePartialReceiptInvoice(PurchaseLine, 1, 1);
        PostPurchasePartialReceiptWithChargeAssignment(PurchaseLine, ExpdAssignableAmount, 2, true, true);

        PreparePartialReceiptInvoice(PurchaseLine, 1, 1);
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        PurchaseLine.ShowItemChargeAssgnt();
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntPurchHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderPartialAssignItemChargeReceiveFirst()
    var
        PurchaseLine: Record "Purchase Line";
        ExpdAssignableAmount: Decimal;
    begin
        // Verify that partial assignment of Item Charge is correct: first assign, then receive, then assign again, then invoice, then assign again.

        // Setup.
        Initialize();
        ExpdAssignableAmount := PurchOrderPartItemCharge(PurchaseLine, 0, 2, 1);

        // Exercise & Verify: Assignable Amount & Rem. Amount To Assign are verified to be correct
        // in SuggstItemChargeAssgntPurchHandler.
        PreparePartialReceiptInvoice(PurchaseLine, 1, 1);
        PostPurchasePartialReceiptWithChargeAssignment(PurchaseLine, ExpdAssignableAmount, 2, true, false);
        PreparePartialReceiptInvoice(PurchaseLine, 1, 1);
        PostPurchasePartialReceiptWithChargeAssignment(PurchaseLine, ExpdAssignableAmount, 2, false, true);
        PurchaseLine.Find();

        PreparePartialReceiptInvoice(PurchaseLine, 1, 1);
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        PurchaseLine.ShowItemChargeAssgnt();
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntPurchHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderPartialAssignItemChargeReceiveInvoiceTwice()
    var
        PurchaseLine: Record "Purchase Line";
        ExpdAssignableAmount: Decimal;
    begin
        // Verify that partial assignment of Item Charge is correct: first assign, then receive full/invoice part, then assign again.

        // Setup.
        Initialize();
        ExpdAssignableAmount := PurchOrderPartItemCharge(PurchaseLine, 0, 2, 1);

        // Exercise & Verify: Assignable Amount & Rem. Amount To Assign are verified to be correct
        // in SuggstItemChargeAssgntPurchHandler.
        PreparePartialReceiptInvoice(PurchaseLine, 2, 1);
        PostPurchasePartialReceiptWithChargeAssignment(PurchaseLine, ExpdAssignableAmount, 2, true, true);

        PreparePartialReceiptInvoice(PurchaseLine, 0, 1);
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        PurchaseLine.ShowItemChargeAssgnt();
    end;

    local procedure PurchOrderPartItemCharge(var PurchaseLine: Record "Purchase Line"; InvoiceDiscount: Decimal; ItemChargeQty: Decimal; QtyToInvoice: Decimal) ExpdAssignableAmount: Decimal
    var
        VendInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // Setup: Create Vendor.
        // Create Purchase Order with two Item lines and one Charge Item line
        VendorNo := CreateVendorWithInvoiceDiscount(VendInvoiceDisc, '', InvoiceDiscount);
        CreatePurchaseDocumentWithMultipleLinesWithItemCharge(
          PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, '', false, 0,
          ItemChargeQty, LibraryRandom.RandDecInDecimalRange(100, 1000, 2));
        ExpdAssignableAmount := PurchaseLine."Line Amount" * (QtyToInvoice / 2);
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntSalesHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialAssignItemCharge()
    var
        SalesLine: Record "Sales Line";
        ExpdAssignableAmount: Decimal;
    begin
        // Sales Side, Verify that partial assignment of Item Charge is correct.

        // Setup.
        Initialize();
        ExpdAssignableAmount := SalesOrderPartItemCharge(SalesLine, 0, 2, 1);
        PreparePartialShipInvoice(SalesLine, 1, 1);

        // Exercise & Verify : Assignable Amount & Rem. Amount To Assign are verified to be
        // correct in SuggstItemChargeAssgntSalesHandler.
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        SalesLine.ShowItemChargeAssgnt();
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntSalesHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialAssignItemChargeTwice()
    var
        SalesLine: Record "Sales Line";
        ExpdAssignableAmount: Decimal;
    begin
        // Sales Side, Verify that partial assignment of Item Charge is correct: first assign, then post, then assign again.

        // Setup.
        Initialize();
        LibrarySales.SetInvoiceRounding(false);
        ExpdAssignableAmount := SalesOrderPartItemCharge(SalesLine, 0, 2, 1);

        // Exercise & Verify : Assignable Amount & Rem. Amount To Assign are verified to be
        // correct in SuggstItemChargeAssgntSalesHandler.
        PreparePartialShipInvoice(SalesLine, 1, 1);
        PostSalesPartialShipmentWithChargeAssignment(SalesLine, ExpdAssignableAmount, 2, true, true);

        PreparePartialShipInvoice(SalesLine, 1, 1);
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        SalesLine.ShowItemChargeAssgnt();
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntSalesHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialAssignItemChargeReceiveFirst()
    var
        SalesLine: Record "Sales Line";
        ExpdAssignableAmount: Decimal;
    begin
        // Sales Side, Verify that partial assignment of Item Charge is correct: first assign, then ship, then assign again, then invoice, then assign again.

        // Setup.
        Initialize();
        LibrarySales.SetInvoiceRounding(false);
        ExpdAssignableAmount := SalesOrderPartItemCharge(SalesLine, 0, 2, 1);

        // Exercise & Verify : Assignable Amount & Rem. Amount To Assign are verified to be
        // correct in SuggstItemChargeAssgntSalesHandler.
        PreparePartialShipInvoice(SalesLine, 1, 1);
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        SalesLine.ShowItemChargeAssgnt();

        PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true, false);
        SalesLine.Find();

        PreparePartialShipInvoice(SalesLine, 1, 1);
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        SalesLine.ShowItemChargeAssgnt();

        PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", false, true);

        SalesLine.Find();
        PreparePartialShipInvoice(SalesLine, 1, 1);
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        SalesLine.ShowItemChargeAssgnt();
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntSalesHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPartialAssignItemChargeReceiveInvoiceTwice()
    var
        SalesLine: Record "Sales Line";
        ExpdAssignableAmount: Variant;
    begin
        // Sales Side, Verify that partial assignment of Item Charge is correct: first assign, then ship full/invoice part, then assign again.

        // Setup.
        Initialize();
        LibrarySales.SetInvoiceRounding(false);
        ExpdAssignableAmount := SalesOrderPartItemCharge(SalesLine, 0, 2, 1);

        // Exercise & Verify : Assignable Amount & Rem. Amount To Assign are verified to be
        // correct in SuggstItemChargeAssgntSalesHandler.
        PreparePartialShipInvoice(SalesLine, 2, 1);
        PostSalesPartialShipmentWithChargeAssignment(SalesLine, ExpdAssignableAmount, 2, true, true);

        PreparePartialShipInvoice(SalesLine, 0, 1);
        AssignItemChargeWithSuggest(ExpdAssignableAmount, 2);
        SalesLine.ShowItemChargeAssgnt();
    end;

    local procedure SalesOrderPartItemCharge(var SalesLine: Record "Sales Line"; InvoiceDiscount: Decimal; ItemChargeQty: Decimal; QtyToInvoice: Decimal) ExpdAssignableAmount: Decimal
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // Setup: Create Customer.
        // Create Purchase Order with two Item lines and one Charge Item line
        CustomerNo := CreateCustomerWithInvoiceDiscount(CustInvoiceDisc, '', InvoiceDiscount);
        CreateSalesDocumentWithMultipleLinesWithItemCharge(
          SalesLine, SalesHeader."Document Type"::Order, CustomerNo, '', false, 0,
          ItemChargeQty, LibraryRandom.RandDecInDecimalRange(100, 1000, 2));
        ExpdAssignableAmount := SalesLine."Line Amount" * (QtyToInvoice / 2);
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithServiceItem()
    begin
        // [FEATURE] [Sales] [Service Item] [Exact Cost Reversing Mandatory]
        // [SCENARIO] Sales Side, verify that credit memo contains correct non-inventoriable cost when exact cost reversing used.

        // [GIVEN] Exact cost reversing mandatory.
        Initialize();
        UpdateExactCostReversingMandatory(true);
        LibrarySales.SetInvoiceRounding(false);

        CreateSalesOrderAndVerifyNonInventoriableCost(true);
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNonStockItem()
    begin
        // [FEATURE] [Sales] [Non-Inventory Item] [Exact Cost Reversing Mandatory]
        // [SCENARIO] Sales Side, verify that credit memo contains correct non-inventoriable cost when exact cost reversing used.

        // [GIVEN] Exact cost reversing mandatory.
        Initialize();
        UpdateExactCostReversingMandatory(true);
        LibrarySales.SetInvoiceRounding(false);

        CreateSalesOrderAndVerifyNonInventoriableCost(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryFilterDimRight()
    var
        Customer: Record Customer;
        CostCalculationManagement: Codeunit "Cost Calculation Management";
        DimValue1: Code[20];
        DimValue2: Code[20];
        ActualResult: Decimal;
        ExpectedResult: Decimal;
    begin
        // [FEATURE] [Cost Calculation] [Dimensions]
        // [SCENARIO 122874] Check correct filtering of Item Ledger Entry by dimensions
        Initialize();

        DimValue1 := LibraryUtility.GenerateGUID();
        DimValue2 := LibraryUtility.GenerateGUID();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        // [GIVEN] Item Ledger Entries: "Cost Amount (Non-Invtbl.)" = 10; Dims = "TOYOTA"
        ExpectedResult := MockItemLedgerEntryWithDim(Customer."No.", DimValue1, DimValue2);
        // [GIVEN] Item Ledger Entries: "Cost Amount (Non-Invtbl.)" = 7; Dims = "MERSEDES"
        MockItemLedgerEntryWithDim(Customer."No.", DimValue2, DimValue1);
        // [WHEN] Call NonInvtblCostAmt of CU 5836 "Cost Calculation Amount" with filter "TOYOTA"
        Customer.SetFilter("Global Dimension 1 Filter", DimValue1);
        Customer.SetFilter("Global Dimension 2 Filter", DimValue2);
        ActualResult := CostCalculationManagement.NonInvtblCostAmt(Customer);
        // [THEN] ActualResult must be equal 10
        Assert.AreEqual(ExpectedResult, ActualResult, CostAmountNonInvtblErr);
    end;

    [Test]
    [HandlerFunctions('CopyPurchaseDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithServiceItem()
    begin
        // [FEATURE] [Purchase] [Service Item] [Exact Cost Reversing Mandatory]
        // [SCENARIO] Service Item can be returned by Purchase Credit Memo without fixed application even though "Exact Cost Reversing Manatory" is on.

        // [GIVEN] Exact cost reversing mandatory.
        Initialize();
        UpdateExactCostReversingMandatory(true);

        CreatePurchaseCrMemoAndVerifyNonInventoriableCost(true);
    end;

    [Test]
    [HandlerFunctions('CopyPurchaseDocumentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithNonStockItem()
    begin
        // [FEATURE] [Purchase] [Non-Inventory Item] [Exact Cost Reversing Mandatory]
        // [SCENARIO] Non-Inventory Item can be returned by Purchase Credit Memo without fixed application even though "Exact Cost Reversing Manatory" is on.

        // [GIVEN] Exact cost reversing mandatory.
        Initialize();
        UpdateExactCostReversingMandatory(false);

        CreatePurchaseCrMemoAndVerifyNonInventoriableCost(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithServiceItemNoFixApplication()
    begin
        // [FEATURE] [Sales] [Service Item] [Exact Cost Reversing Mandatory]
        // [SCENARIO 363246] Sales Side, verify that for service item credit memo can be posted without fixed application when exact cost reversing used.

        // [GIVEN] Exact cost reversing mandatory.
        Initialize();
        UpdateExactCostReversingMandatory(true);
        LibrarySales.SetInvoiceRounding(false);

        // [GIVEN] Create Item of type Service.
        CreateSalesCrMemondVerifyNonInventoriableCost(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNonStockItemNoFixApplication()
    begin
        // [FEATURE] [Sales] [NonStock Item] [Exact Cost Reversing Mandatory]
        // [SCENARIO 363246] Sales Side, verify that for NonStock item credit memo can be posted without fixed application when exact cost reversing used.

        // [GIVEN] Exact cost reversing mandatory.
        Initialize();
        UpdateExactCostReversingMandatory(true);
        LibrarySales.SetInvoiceRounding(false);

        // [GIVEN] Create Item of type Service.
        CreateSalesCrMemondVerifyNonInventoriableCost(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcCustActualCostLCYForResource()
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
        Customer: Record Customer;
        CostCalculationManagement: Codeunit "Cost Calculation Management";
        ActualCostLCY: Decimal;
    begin
        // [FEATURE] [Customer] [Statistics] [Resource]
        // [SCENARIO 378115] Resource Ledger Entries should be included in the Customer Statistics
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Resource Ledger Entry for Customer with "Entry Type" = Usage "Total Cost" = "Y"
        MockResourceLedgerEntry(ResLedgerEntry, ResLedgerEntry."Entry Type"::Usage, Customer."No.");
        // [GIVEN] Resource Ledger Entry for Customer with "Entry Type" = Sales "Total Cost" = "X"
        MockResourceLedgerEntry(ResLedgerEntry, ResLedgerEntry."Entry Type"::Sale, Customer."No.");

        // [WHEN] Calculate Customer Actual Cost LCY
        ActualCostLCY := CostCalculationManagement.CalcCustActualCostLCY(Customer);

        // [THEN] Actual Cost LCY is "X"
        // BUG 369400: CalcCustActualCostLCY function only considers Resource Ledger Entries with Entry Type equals Sale
        Assert.AreEqual(ResLedgerEntry."Total Cost", ActualCostLCY, ActualCostErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ImplementStandardCostChangesHandler')]
    [Scope('OnPrem')]
    procedure UnitAmountIsRoundedOnRevalJnlGeneratedFromStdCostWksht()
    var
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        NewStandardCost: Decimal;
    begin
        // [FEATURE] [Standard Cost Worksheet] [Revaluation Journal] [Rounding]
        // [SCENARIO 381147] When Revaluation Journal Line is generated from Standard Cost Worksheet, Inventory Value (Revalued) should be equal to Quantity multiplied by Unit Amount rounded to Unit-Amount Rounding Precision.
        Initialize();

        // [GIVEN] Unit-Amount Rounded Precision is changed to "P" decimal digits (i.e. "P" = 3, precision = 0.001).
        GLSetup.Get();
        GLSetup.Validate("Unit-Amount Rounding Precision", 0.001);
        GLSetup.Modify(true);

        // [GIVEN] Item with Standard Cost "X" (i.e. 16.28).
        // [GIVEN] Posted Purchase Order with Item. Quantity = "Q" (i.e. 196), Unit Cost = "X".
        Item.Get(CreateAndModifyItem(LibraryRandom.RandDecInRange(20, 50, 3)));
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(300, 500), Item."Standard Cost");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Generate Revaluation Journal Line from Standard Cost Worksheet with new Standard Cost "Y", which has more than "P" decimal digits (i.e. "Y" = 15.1268).
        NewStandardCost := LibraryRandom.RandDecInRange(20, 50, 3) + LibraryRandom.RandInt(9) / 10000; // make sure there is 4 decimal digits
        ImplementStandardCostChanges(Item, NewStandardCost);
        // [THEN] Inventory Value (Revalued) in Revaluation Journal is equal to "Q" * ("Y" rounded to "P" digits) (i.e. 196 * 15.127 = 2964.89).
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(
          "Inventory Value (Revalued)",
          Round(Round(NewStandardCost, GLSetup."Unit-Amount Rounding Precision") * ItemJournalLine.Quantity, GLSetup."Amount Rounding Precision"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceForItemChargeInFCYPreciseDistribution()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ValueEntry: Record "Value Entry";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Item Charge] [Currency] [Rounding]
        // [SCENARIO 259570] When you distribute item charge cost in FCY to several purch. receipts, the sum of posted direct cost in LCY should be precisely equal to the posted invoice amount in LCY.
        Initialize();

        // [GIVEN] Currency "FCY". The exchange rate is 1 "FCY" = 6.67 LCY.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 6.67, 1 / 6.67);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create and post two purchase lines with Item = "I", Quantity = 1.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        for i := 1 to 2 do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindReceiptLine(PurchRcptLine, PurchaseHeader."No.", Item."No.");

        // [GIVEN] Create purchase invoice for an item charge. Quantity = 1, "Unit Cost" = 1 "FCY", which is equal to 6.67 LCY.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 1);
        PurchaseLine.Modify(true);

        // [GIVEN] Distribute the item charge equally to two purchase receipt lines.
        for i := 1 to 2 do begin
            LibraryPurchase.CreateItemChargeAssignment(
              ItemChargeAssignmentPurch, PurchaseLine, ItemCharge, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
              PurchRcptLine."Document No.", PurchRcptLine."Line No.", Item."No.", 0.5, 1);
            ItemChargeAssignmentPurch.Insert(true);
            PurchRcptLine.Next();
        end;

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total posted cost amount for item charge = 6.67 LCY.
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", 6.67);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceForItemChargeInFCYPreciseDistribution()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesShipmentLine: Record "Sales Shipment Line";
        ValueEntry: Record "Value Entry";
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Item Charge] [Currency] [Rounding]
        // [SCENARIO 259570] When you distribute item charge amount in FCY to several sales shipments, the sum of posted item charge amount in LCY should be precisely equal to the posted invoice amount in LCY.
        Initialize();

        // [GIVEN] Currency "FCY". The exchange rate is 1 "FCY" = 6.67 LCY.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1 / 6.67, 1 / 6.67);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Create and post two sales lines with Item = "I", Quantity = 1.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        for i := 1 to 2 do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindShipmentLine(SalesShipmentLine, SalesHeader."No.", Item."No.");

        // [GIVEN] Create sales invoice for an item charge. Quantity = 1, "Unit Cost" = 1 "FCY", which is equal to 6.67 LCY.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        SalesLine.Validate("Unit Price", 1);
        SalesLine.Modify(true);

        // [GIVEN] Distribute the item charge equally to two sales shipment lines.
        for i := 1 to 2 do begin
            LibrarySales.CreateItemChargeAssignment(
              ItemChargeAssignmentSales, SalesLine, ItemCharge, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
              SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", Item."No.", 0.5, 1);
            ItemChargeAssignmentSales.Insert(true);
            SalesShipmentLine.Next();
        end;

        // [WHEN] Post the sales invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Total posted sales amount for item charge = 6.67 LCY.
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        ValueEntry.CalcSums("Sales Amount (Actual)");
        ValueEntry.TestField("Sales Amount (Actual)", 6.67);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeDistributionBySerialNosPurchaseOrder()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        CurrencyCode: Code[10];
        Qty: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Item Charge] [Item Tracking] [Purchase] [Order]
        // [SCENARIO 374436] When item charge is distributed to multiple item entries by serial nos., the total distributed amount is precisely equal to the item charge amount.
        // [SCENARIO 374436] Item charge is distributed to item line in purchase order.
        Initialize();
        Qty := 7;
        Amount := 9.0;

        // [GIVEN] Set additional reporting currency "ACY". The exchange rate is 1 "ACY" = 1 LCY.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        // [GIVEN] Serial no.-tracked item "I".
        // [GIVEN] Item charge "C".
        LibraryItemTracking.CreateSerialItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Purchase order with 2 lines -
        // [GIVEN] 1st line: Type = Item, No. = "I", Quantity = 7. Assign 7 serial nos.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseLineItem, PurchaseHeader, PurchaseLineItem.Type::Item, Item."No.", Qty, LibraryRandom.RandDec(100, 2));
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNos);
        PurchaseLineItem.OpenItemTrackingLines();

        // [GIVEN] 2nd line: Type = Item Charge, No. = "C", Quantity = 1, Line Amount = 9.0.
        // [GIVEN] Assign the item charge to the item line.
        CreatePurchaseLine(PurchaseLineCharge, PurchaseHeader, PurchaseLineCharge.Type::"Charge (Item)", ItemCharge."No.", 1, Amount);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineCharge, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order,
          PurchaseLineItem."Document No.", PurchaseLineItem."Line No.", Item."No.");

        // [WHEN] Ship and invoice the purchase order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The sum of cost amount for item charge in both LCY and ACY currencies is equal to 9.0.
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        ValueEntry.TestField("Cost Amount (Actual)", Amount);
        ValueEntry.TestField("Cost Amount (Actual) (ACY)", Amount);

        // [THEN] For each value entry, the difference between actual cost and the precise cost [9/7 = 1.285714...] is not greater than the rounding precision 0.01.
        ValueEntry.SetRange(
          "Cost Amount (Actual)",
          Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '>'));
        ValueEntry.SetRange(
          "Cost Amount (Actual) (ACY)",
          Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeDistributionBySerialNosPurchaseInvoice()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ValueEntry: Record "Value Entry";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        ReceiptNo: Code[20];
        Qty: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Item Charge] [Item Tracking] [Purchase] [Invoice] [Get Receipt Lines]
        // [SCENARIO 374436] When item charge is distributed to multiple item entries by serial nos., the total distributed amount is precisely equal to the item charge amount.
        // [SCENARIO 374436] Item charge is distributed to purchase invoice line created via "Get Receipt Lines".
        Initialize();
        Qty := 7;
        Amount := 9.0;

        // [GIVEN] Set additional reporting currency "ACY". The exchange rate is 1 "ACY" = 1 LCY.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        // [GIVEN] Serial no.-tracked item "I".
        // [GIVEN] Item charge "C".
        LibraryItemTracking.CreateSerialItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Purchase order for item "I", quantity = 7. Assign 7 serial nos.
        // [GIVEN] Post receipt.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLine(PurchaseLineItem, PurchaseHeader, PurchaseLineItem.Type::Item, Item."No.", Qty, LibraryRandom.RandDec(100, 2));
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNos);
        PurchaseLineItem.OpenItemTrackingLines();
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create purchase invoice using "Get Receipt Lines".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [GIVEN] Add a line for item charge "C". Quantity = 1, Line Amount = 9.0.
        // [GIVEN] Assign the item charge to the item line in the invoice.
        Clear(PurchaseLineItem);
        PurchaseLineItem.SetRange("No.", Item."No.");
        LibraryPurchase.FindFirstPurchLine(PurchaseLineItem, PurchaseHeader);
        CreatePurchaseLine(PurchaseLineCharge, PurchaseHeader, PurchaseLineCharge.Type::"Charge (Item)", ItemCharge."No.", 1, Amount);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineCharge, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Invoice,
          PurchaseLineItem."Document No.", PurchaseLineItem."Line No.", Item."No.");

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The sum of cost amount for item charge in both LCY and ACY currencies is equal to 9.0.
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        ValueEntry.TestField("Cost Amount (Actual)", Amount);
        ValueEntry.TestField("Cost Amount (Actual) (ACY)", Amount);

        // [THEN] For each value entry, the difference between actual cost and the precise cost [9/7 = 1.285714...] is not greater than the rounding precision 0.01.
        ValueEntry.SetRange(
          "Cost Amount (Actual)",
          Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '>'));
        ValueEntry.SetRange(
          "Cost Amount (Actual) (ACY)",
          Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeDistributionBySerialNosSalesOrder()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineCharge: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ValueEntry: Record "Value Entry";
        Qty: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Item Charge] [Item Tracking] [Sales] [Order]
        // [SCENARIO 374436] When item charge is distributed to multiple item entries by serial nos., the total distributed amount is precisely equal to the item charge amount.
        // [SCENARIO 374436] Item charge is distributed to item line in sales order.
        Initialize();
        LibrarySales.SetInvoiceRounding(false);
        Qty := 7;
        Amount := 9.0;

        // [GIVEN] Serial no.-tracked item "I".
        // [GIVEN] Item charge "C".
        LibraryItemTracking.CreateSerialItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Post 7 pcs of item "I" to inventory. Assign 7 serial nos.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNos);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order with 2 lines -
        // [GIVEN] 1st line: Type = Item, No. = "I", Quantity = 7.
        // [GIVEN] Open item tracking lines and select 7 serial nos.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesLineItem, SalesHeader, SalesLineItem.Type::Item, Item."No.", Qty, LibraryRandom.RandDec(100, 2));
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        SalesLineItem.OpenItemTrackingLines();

        // [GIVEN] 2nd line: Type = Item Charge, No. = "C", Quantity = 1, Line Amount = 9.0.
        // [GIVEN] Assign the item charge to the item line.
        CreateSalesLine(SalesLineCharge, SalesHeader, SalesLineCharge.Type::"Charge (Item)", ItemCharge."No.", 1, Amount);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineCharge, ItemChargeAssignmentSales."Applies-to Doc. Type"::Order,
          SalesLineItem."Document No.", SalesLineItem."Line No.", Item."No.");

        // [WHEN] Ship and invoice the sales order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The sum of sales amount for item charge is equal to 9.0.
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        ValueEntry.CalcSums("Sales Amount (Actual)");
        ValueEntry.TestField("Sales Amount (Actual)", Amount);

        // [THEN] For each value entry, the difference between actual sales amount and the precise amount [9/7 = 1.285714...] is not greater than the rounding precision 0.01.
        ValueEntry.SetRange(
          "Sales Amount (Actual)",
          Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeDistributionBySerialNosSalesInvoice()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineCharge: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesShipmentLine: Record "Sales Shipment Line";
        ValueEntry: Record "Value Entry";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        CustomerNo: Code[20];
        ShipmentNo: Code[20];
        Qty: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Item Charge] [Item Tracking] [Sales] [Invoice] [Get Shipment Lines]
        // [SCENARIO 374436] When item charge is distributed to multiple item entries by serial nos., the total distributed amount is precisely equal to the item charge amount.
        // [SCENARIO 374436] Item charge is distributed to sales invoice line created via "Get Shipment Lines".
        Initialize();
        LibrarySales.SetInvoiceRounding(false);
        Qty := 7;
        Amount := 9.0;

        // [GIVEN] Serial no.-tracked item "I".
        // [GIVEN] Item charge "C".
        LibraryItemTracking.CreateSerialItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Post 7 pcs of item "I" to inventory. Assign 7 serial nos.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNos);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order for item "I", quantity = 7. Select 7 serial nos.
        // [GIVEN] Post shipment.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesLineItem, SalesHeader, SalesLineItem.Type::Item, Item."No.", Qty, LibraryRandom.RandDec(100, 2));
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        SalesLineItem.OpenItemTrackingLines();
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create sales invoice using "Get Shipment Lines".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);

        // [GIVEN] Add a line for item charge "C". Quantity = 1, Line Amount = 9.0.
        // [GIVEN] Assign the item charge to the item line in the invoice.
        Clear(SalesLineItem);
        SalesLineItem.SetRange("No.", Item."No.");
        LibrarySales.FindFirstSalesLine(SalesLineItem, SalesHeader);
        CreateSalesLine(SalesLineCharge, SalesHeader, SalesLineCharge.Type::"Charge (Item)", ItemCharge."No.", 1, Amount);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineCharge, ItemChargeAssignmentSales."Applies-to Doc. Type"::Invoice,
          SalesLineItem."Document No.", SalesLineItem."Line No.", Item."No.");

        // [WHEN] Post the sales invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The sum of sales amount for item charge is equal to 9.0.
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        ValueEntry.CalcSums("Sales Amount (Actual)");
        ValueEntry.TestField("Sales Amount (Actual)", Amount);

        // [THEN] For each value entry, the difference between sales amount and the precise amount [9/7 = 1.285714...] is not greater than the rounding precision 0.01.
        ValueEntry.SetRange(
          "Sales Amount (Actual)",
          Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(Amount / Qty, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeDistributionByLotNosPurchaseInvoice_RoundingPrecisionLCY()
    var
        Item: Record Item;
        ItemCharge: array[3] of Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineItemCharge: array[3] of Record "Purchase Line";
        ItemChargeAssignmentPurch: array[3] of Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        ItemQuantity: Decimal;
        ItemUnitCost: Decimal;
        ItemChargeUnitCost: array[3] of Decimal;
    begin
        // [FEATURE] [Item Charge] [Item Tracking] [Purchase] [Invoice]
        // [SCENARIO 447218] When Item Charge is distributed to multiple Item entries by Lots, the total distributed Amount is precisely equal to the Item Charge Amount (rounded).
        // [SCENARIO 447218] Item Charges are distributed to Item line in Purchase Invoice.
        // [SCENARIO 447218] There are three Item Charge lines.
        Initialize();
        ItemQuantity := 3;
        ItemUnitCost := 4.6375;
        ItemChargeUnitCost[1] := 4.6375;
        ItemChargeUnitCost[2] := 9.275;
        ItemChargeUnitCost[3] := 7.374;

        // [GIVEN] Remove Additional Reporting Currency (ACY).
        LibraryERM.SetAddReportingCurrency('');

        // [GIVEN] Create "Item" with Lots as "Item Tracking"
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Create three "Item Charges".
        LibraryInventory.CreateItemCharge(ItemCharge[1]);
        LibraryInventory.CreateItemCharge(ItemCharge[2]);
        LibraryInventory.CreateItemCharge(ItemCharge[3]);

        // [GIVEN] Create Purchase Invoice with 4 lines: 1 Item line and 3 Item Charges lines.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // [GIVEN] 1st line: Type = Item, No. = Item."No.", Quantity = 3, Unit Cost = 4.6375.
        CreatePurchaseLine(PurchaseLineItem, PurchaseHeader, PurchaseLineItem.Type::Item, Item."No.", ItemQuantity, ItemUnitCost);
        // [GIVEN] Split to 3 Lots.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::CreateThreeLots);
        PurchaseLineItem.OpenItemTrackingLines();

        // [GIVEN] 2nd line: Type = Item Charge, No. = ItemCharge[1]."No.", Quantity = 1, Unit Cost = 4.6375.
        CreatePurchaseLine(PurchaseLineItemCharge[1], PurchaseHeader, PurchaseLineItemCharge[1].Type::"Charge (Item)", ItemCharge[1]."No.", 1, ItemChargeUnitCost[1]);
        // [GIVEN] Assign the Item Charge to the Item line.
        LibraryInventory.CreateItemChargeAssignPurchase(
            ItemChargeAssignmentPurch[1], PurchaseLineItemCharge[1], ItemChargeAssignmentPurch[1]."Applies-to Doc. Type"::Invoice,
            PurchaseLineItem."Document No.", PurchaseLineItem."Line No.", Item."No.");

        // [GIVEN] 3rd line: Type = Item Charge, No. = ItemCharge[2]."No.", Quantity = 1, Unit Cost = 9.275.
        CreatePurchaseLine(PurchaseLineItemCharge[2], PurchaseHeader, PurchaseLineItemCharge[2].Type::"Charge (Item)", ItemCharge[2]."No.", 1, ItemChargeUnitCost[2]);
        // [GIVEN] Assign the Item Charge to the Item line.
        LibraryInventory.CreateItemChargeAssignPurchase(
            ItemChargeAssignmentPurch[2], PurchaseLineItemCharge[2], ItemChargeAssignmentPurch[2]."Applies-to Doc. Type"::Invoice,
            PurchaseLineItem."Document No.", PurchaseLineItem."Line No.", Item."No.");

        // [GIVEN] 4th line: Type = Item Charge, No. = ItemCharge[3]."No.", Quantity = 1, Unit Cost = 7.374.
        CreatePurchaseLine(PurchaseLineItemCharge[3], PurchaseHeader, PurchaseLineItemCharge[3].Type::"Charge (Item)", ItemCharge[3]."No.", 1, ItemChargeUnitCost[3]);
        // [GIVEN] Assign the Item Charge to the Item line.
        LibraryInventory.CreateItemChargeAssignPurchase(
            ItemChargeAssignmentPurch[3], PurchaseLineItemCharge[3], ItemChargeAssignmentPurch[3]."Applies-to Doc. Type"::Invoice,
            PurchaseLineItem."Document No.", PurchaseLineItem."Line No.", Item."No.");

        // [WHEN] Receive and Invoice the Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] ItemCharge[1] - The sum of "Cost Amount (Actual)" is equal to 4.64.
        Clear(ValueEntry);
        ValueEntry.SetRange("Item Charge No.", ItemCharge[1]."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", Round(ItemChargeUnitCost[1], LibraryERM.GetAmountRoundingPrecision()));

        // [THEN] ItemCharge[1] - The difference between the sum of "Cost Amount (Actual)" and the precise cost is not greater than the rounding precision 0.01.
        ValueEntry.SetRange("Cost Amount (Actual)",
            Round(ItemChargeUnitCost[1] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(ItemChargeUnitCost[1] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, ItemQuantity);

        // [THEN] ItemCharge[2] - The sum of "Cost Amount (Actual)" is equal to 9.28.
        Clear(ValueEntry);
        ValueEntry.SetRange("Item Charge No.", ItemCharge[2]."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", Round(ItemChargeUnitCost[2], LibraryERM.GetAmountRoundingPrecision()));

        // [THEN] ItemCharge[2] - The difference between the sum of "Cost Amount (Actual)" and the precise cost is not greater than the rounding precision 0.01.
        ValueEntry.SetRange("Cost Amount (Actual)",
            Round(ItemChargeUnitCost[2] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(ItemChargeUnitCost[2] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, ItemQuantity);

        // [THEN] ItemCharge[3] - The sum of "Cost Amount (Actual)" is equal to 7.37.
        Clear(ValueEntry);
        ValueEntry.SetRange("Item Charge No.", ItemCharge[3]."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", Round(ItemChargeUnitCost[3], LibraryERM.GetAmountRoundingPrecision()));

        // [THEN] ItemCharge[3] - The difference between the sum of "Cost Amount (Actual)" and the precise cost is not greater than the rounding precision 0.01.
        ValueEntry.SetRange("Cost Amount (Actual)",
            Round(ItemChargeUnitCost[3] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(ItemChargeUnitCost[3] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, ItemQuantity);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeDistributionByLotNosSalesInvoice_RoundingPrecisionLCY()
    var
        Item: Record Item;
        ItemCharge: array[3] of Record "Item Charge";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineItemCharge: array[3] of Record "Sales Line";
        ItemChargeAssignmentSales: array[3] of Record "Item Charge Assignment (Sales)";
        ValueEntry: Record "Value Entry";
        ItemQuantity: Decimal;
        ItemUnitPrice: Decimal;
        ItemChargeUnitPrice: array[3] of Decimal;
    begin
        // [FEATURE] [Item Charge] [Item Tracking] [Sales] [Invoice]
        // [SCENARIO 447218] When Item Charge is distributed to multiple Item entries by Lots, the total distributed Amount is precisely equal to the Item Charge Amount (rounded).
        // [SCENARIO 447218] Item Charges are distributed to Item line in Sales Invoice.
        // [SCENARIO 447218] There are three Item Charge lines.
        Initialize();
        ItemQuantity := 3;
        ItemUnitPrice := 4.6375;
        ItemChargeUnitPrice[1] := 4.6375;
        ItemChargeUnitPrice[2] := 9.275;
        ItemChargeUnitPrice[3] := 7.374;

        // [GIVEN] Remove Additional Reporting Currency (ACY).
        LibraryERM.SetAddReportingCurrency('');

        // [GIVEN] Disable Invoice Rounding
        LibrarySales.SetInvoiceRounding(false);

        // [GIVEN] Create "Item" with Lots as "Item Tracking"
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Create three "Item Charges".
        LibraryInventory.CreateItemCharge(ItemCharge[1]);
        LibraryInventory.CreateItemCharge(ItemCharge[2]);
        LibraryInventory.CreateItemCharge(ItemCharge[3]);

        // [GIVEN] Post ItemQuantity of Item to inventory. Assign 3 Lots.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', ItemQuantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::CreateThreeLots);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Sales Invoice with 4 lines: 1 Item line and 3 Item Charges lines.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [GIVEN] 1st line: Type = Item, No. = Item."No.", Quantity = 3, Unit Price = 4.6375.
        CreateSalesLine(SalesLineItem, SalesHeader, SalesLineItem.Type::Item, Item."No.", ItemQuantity, ItemUnitPrice);
        // [GIVEN] Select 3 Lots.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        SalesLineItem.OpenItemTrackingLines();

        // [GIVEN] 2nd line: Type = Item Charge, No. = ItemCharge[1]."No.", Quantity = 1, Unit Price = 4.6375.
        CreateSalesLine(SalesLineItemCharge[1], SalesHeader, SalesLineItemCharge[1].Type::"Charge (Item)", ItemCharge[1]."No.", 1, ItemChargeUnitPrice[1]);
        // [GIVEN] Assign the Item Charge to the Item line.
        LibraryInventory.CreateItemChargeAssignment(
            ItemChargeAssignmentSales[1], SalesLineItemCharge[1], ItemChargeAssignmentSales[1]."Applies-to Doc. Type"::Invoice,
            SalesLineItem."Document No.", SalesLineItem."Line No.", Item."No.");

        // [GIVEN] 3rd line: Type = Item Charge, No. = ItemCharge[2]."No.", Quantity = 1, Unit Price = 9.275.
        CreateSalesLine(SalesLineItemCharge[2], SalesHeader, SalesLineItemCharge[1].Type::"Charge (Item)", ItemCharge[2]."No.", 1, ItemChargeUnitPrice[2]);
        // [GIVEN] Assign the Item Charge to the Item line.
        LibraryInventory.CreateItemChargeAssignment(
            ItemChargeAssignmentSales[2], SalesLineItemCharge[2], ItemChargeAssignmentSales[2]."Applies-to Doc. Type"::Invoice,
            SalesLineItem."Document No.", SalesLineItem."Line No.", Item."No.");

        // [GIVEN] 4th line: Type = Item Charge, No. = ItemCharge[3]."No.", Quantity = 1, Unit Price = 7.374.
        CreateSalesLine(SalesLineItemCharge[3], SalesHeader, SalesLineItemCharge[3].Type::"Charge (Item)", ItemCharge[3]."No.", 1, ItemChargeUnitPrice[3]);
        // [GIVEN] Assign the Item Charge to the Item line.
        LibraryInventory.CreateItemChargeAssignment(
            ItemChargeAssignmentSales[3], SalesLineItemCharge[3], ItemChargeAssignmentSales[3]."Applies-to Doc. Type"::Invoice,
            SalesLineItem."Document No.", SalesLineItem."Line No.", Item."No.");

        // [WHEN] Ship and Invoice the Sales Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] ItemCharge[1] - The sum of "Sales Amount (Actual)" is equal to 4.64.
        Clear(ValueEntry);
        ValueEntry.SetRange("Item Charge No.", ItemCharge[1]."No.");
        ValueEntry.CalcSums("Sales Amount (Actual)");
        ValueEntry.TestField("Sales Amount (Actual)", Round(ItemChargeUnitPrice[1], LibraryERM.GetAmountRoundingPrecision()));

        // [THEN] ItemCharge[1] - The difference between the sum of "Sales Amount (Actual)" and the precise Sales Amount is not greater than the rounding precision 0.01.
        ValueEntry.SetRange("Sales Amount (Actual)",
            Round(ItemChargeUnitPrice[1] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(ItemChargeUnitPrice[1] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, ItemQuantity);

        // [THEN] ItemCharge[2] - The sum of "Sales Amount (Actual)" is equal to 9.28.
        Clear(ValueEntry);
        ValueEntry.SetRange("Item Charge No.", ItemCharge[2]."No.");
        ValueEntry.CalcSums("Sales Amount (Actual)");
        ValueEntry.TestField("Sales Amount (Actual)", Round(ItemChargeUnitPrice[2], LibraryERM.GetAmountRoundingPrecision()));

        // [THEN] ItemCharge[2] - The difference between the sum of "Sales Amount (Actual)" and the precise Sales Amount is not greater than the rounding precision 0.01.
        ValueEntry.SetRange("Sales Amount (Actual)",
            Round(ItemChargeUnitPrice[2] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(ItemChargeUnitPrice[2] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, ItemQuantity);

        // [THEN] ItemCharge[3] - The sum of "Sales Amount (Actual)" is equal to 7.37.
        Clear(ValueEntry);
        ValueEntry.SetRange("Item Charge No.", ItemCharge[3]."No.");
        ValueEntry.CalcSums("Sales Amount (Actual)");
        ValueEntry.TestField("Sales Amount (Actual)", Round(ItemChargeUnitPrice[3], LibraryERM.GetAmountRoundingPrecision()));

        // [THEN] ItemCharge[3] - The difference between the sum of "Sales Amount (Actual)" and the precise Sales Amount is not greater than the rounding precision 0.01.
        ValueEntry.SetRange("Sales Amount (Actual)",
            Round(ItemChargeUnitPrice[3] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '<'), Round(ItemChargeUnitPrice[3] / ItemQuantity, LibraryERM.GetAmountRoundingPrecision(), '>'));
        Assert.RecordCount(ValueEntry, ItemQuantity);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure RoundingOfItemChargeAmountDistributedToTwoPurchaseOrderLines()
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineItem1, PurchaseLineItem2, PurchaseLineItemCharge : Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
        InvoiceNo: Code[20];
        ExchangeRate: Decimal;
        Qty: Decimal;
    begin
        // [SCENARIO 550410] Rounding error in Item Charge distribution to multiple Purchase Order lines.
        Initialize();
        Qty := 100;
        ExchangeRate := 1.333333;

        // [GIVEN] Create currency "FCY" with exchange rate 1 "FCY" = 1.333333 LCY.
        CreateCurrencyWithExchangeRate(Currency, ExchangeRate);

        // [GIVEN] Item "I", item charge "C".
        LibraryInventory.CreateItem(Item);
        ItemCharge.FindLast();

        // [GIVEN] Purchase order, set currency code = "FCY".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] Two purchase order lines for item "I", quantity = 1, unit cost = 100.
        CreatePurchaseLine(PurchaseLineItem1, PurchaseHeader, PurchaseLineItem1.Type::Item, Item."No.", 1, Qty);
        CreatePurchaseLine(PurchaseLineItem2, PurchaseHeader, PurchaseLineItem2.Type::Item, Item."No.", 1, Qty);

        // [GIVEN] Add a line for item charge "C", quantity = 1, unit cost = 200.
        // [GIVEN] Assign the item charge evenly to the item lines in the purchase order.
        CreatePurchaseLine(PurchaseLineItemCharge, PurchaseHeader, PurchaseLineItemCharge.Type::"Charge (Item)", ItemCharge."No.", 1, 2 * Qty);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineItemCharge, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order,
          PurchaseLineItem1."Document No.", PurchaseLineItem1."Line No.", Item."No.");
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", 0.5);
        ItemChargeAssignmentPurch.Modify(true);

        Clear(ItemChargeAssignmentPurch);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineItemCharge, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order,
          PurchaseLineItem2."Document No.", PurchaseLineItem2."Line No.", Item."No.");
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", 0.5);
        ItemChargeAssignmentPurch.Modify(true);

        // [WHEN] Post the Purchase Order.
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The cost amount is equal to the document amount.
        ValueEntry.SetRange("Document No.", InvoiceNo);
        ValueEntry.CalcSums("Cost Amount (Actual)");

        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Purchase);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ValueEntry."Cost Amount (Actual)");
    end;

    [Test]
    procedure RoundingOfItemChargeAmountDistributedToTwoSalesOrderLines()
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
        SalesLineItem1, SalesLineItem2, SalesLineItemCharge : Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
        InvoiceNo: Code[20];
        ExchangeRate: Decimal;
        Qty: Decimal;
    begin
        // [SCENARIO 550410] Rounding error in Item Charge distribution to multiple Sales Order lines.
        Initialize();
        Qty := 100;
        ExchangeRate := 1.333333;

        // [GIVEN] Create currency "FCY" with exchange rate 1 "FCY" = 1.333333 LCY.
        CreateCurrencyWithExchangeRate(Currency, ExchangeRate);

        // [GIVEN] Item "I", item charge "C".
        LibraryInventory.CreateItem(Item);
        ItemCharge.FindLast();

        // [GIVEN] Sales order, set currency code = "FCY".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);

        // [GIVEN] Two Sales order lines for item "I", quantity = 1, unit cost = 100.
        CreateSalesLine(SalesLineItem1, SalesHeader, SalesLineItem1.Type::Item, Item."No.", 1, Qty);
        CreateSalesLine(SalesLineItem2, SalesHeader, SalesLineItem2.Type::Item, Item."No.", 1, Qty);

        // [GIVEN] Add a line for item charge "C", quantity = 1, unit cost = 200.
        // [GIVEN] Assign the item charge evenly to the item lines in the Sales order.
        CreateSalesLine(SalesLineItemCharge, SalesHeader, SalesLineItemCharge.Type::"Charge (Item)", ItemCharge."No.", 1, 2 * Qty);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineItemCharge, ItemChargeAssignmentSales."Applies-to Doc. Type"::Order,
          SalesLineItem1."Document No.", SalesLineItem1."Line No.", Item."No.");
        ItemChargeAssignmentSales.Validate("Qty. to Assign", 0.5);
        ItemChargeAssignmentSales.Modify(true);

        Clear(ItemChargeAssignmentSales);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineItemCharge, ItemChargeAssignmentSales."Applies-to Doc. Type"::Order,
          SalesLineItem2."Document No.", SalesLineItem2."Line No.", Item."No.");
        ItemChargeAssignmentSales.Validate("Qty. to Assign", 0.5);
        ItemChargeAssignmentSales.Modify(true);

        // [WHEN] Post the Sales Order.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The sales amount is equal to the document amount.
        ValueEntry.SetRange("Document No.", InvoiceNo);
        ValueEntry.CalcSums("Sales Amount (Actual)");

        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Sale);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -ValueEntry."Sales Amount (Actual)");
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Costing II");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing II");

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing II");
    end;

    local procedure PreparePartialReceiptInvoice(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal; QtyToInvoice: Decimal)
    var
        Math: Codeunit Math;
        QtyToReceiveCoeff: Decimal;
        QtyToInvoiceCoeff: Decimal;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        QtyToReceiveCoeff := QtyToReceive / PurchaseLine.Quantity;
        QtyToInvoiceCoeff := QtyToInvoice / PurchaseLine.Quantity;
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Qty. to Receive", Math.Min(PurchaseLine.Quantity * QtyToReceiveCoeff, PurchaseLine.Quantity - PurchaseLine."Quantity Received"));
            PurchaseLine.Validate("Qty. to Invoice", Math.Min(PurchaseLine.Quantity * QtyToInvoiceCoeff, PurchaseLine.Quantity - PurchaseLine."Quantity Invoiced"));
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure PreparePartialShipInvoice(var SalesLine: Record "Sales Line"; QtyToShip: Decimal; QtyToInvoice: Decimal)
    var
        Math: Codeunit Math;
        QtyToShipCoeff: Decimal;
        QtyToInvoiceCoeff: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        QtyToShipCoeff := QtyToShip / SalesLine.Quantity;
        QtyToInvoiceCoeff := QtyToInvoice / SalesLine.Quantity;
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Qty. to Ship", Math.Min(SalesLine.Quantity * QtyToShipCoeff, SalesLine.Quantity - SalesLine."Quantity Shipped"));
            SalesLine.Validate("Qty. to Invoice", Math.Min(SalesLine.Quantity * QtyToInvoiceCoeff, SalesLine.Quantity - SalesLine."Quantity Invoiced"));
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateSalesOrderAndVerifyNonInventoriableCost(IsService: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        ReasonCode: Record "Reason Code";
        CopySalesDocument: Report "Copy Sales Document";
        PostedDocNo: Code[20];
        Quantity: Decimal;
    begin
        // [GIVEN] Sale Item of type Service.
        Customer.Get(CreateCustomer());

        Item.Get(CreateServiceOrNonStockItem(FindVATProdPostingGroup(Customer."VAT Bus. Posting Group"), IsService));
        Quantity := LibraryRandom.RandDec(10, 2);  // Using Random value for Quantity.
        CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", Customer."No.", Item."Unit Price", Quantity);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Commit();

        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibraryVariableStorage.Enqueue("Sales Document Type From"::"Posted Invoice"); // Used in Copy Sales Document handler
        LibraryVariableStorage.Enqueue(PostedDocNo); // Used in Copy Sales Document handler
        Commit();

        // [WHEN] Copy posted sales invoice line to newly created Sales Credit Memo.
        CopySalesDocument.SetSalesHeader(SalesHeader2);
        CopySalesDocument.RunModal();
        SalesHeader2.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader2.Validate("Reason Code", ReasonCode.Code);

        // [THEN] Verify that non-inventoriable cost amount equals to COGS.
        VerifyNonInventoriableCost(
          LibrarySales.PostSalesDocument(SalesHeader2, true, true), '', Quantity, Item."Unit Cost" * Quantity);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseCrMemoAndVerifyNonInventoriableCost(IsService: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReasonCode: Record "Reason Code";
        Vendor: Record Vendor;
        CopyPurchaseDocument: Report "Copy Purchase Document";
        PostedDocNo: Code[20];
        Quantity: Decimal;
    begin
        // [GIVEN] Purchase Item of type Service.
        Vendor.Get(CreateVendor());
        Item.Get(CreateServiceOrNonStockItem(FindVATProdPostingGroup(Vendor."VAT Bus. Posting Group"), IsService));
        Quantity := LibraryRandom.RandDec(10, 2);  // Using Random value for Quantity.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity, Item."Unit Price");
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        LibraryVariableStorage.Enqueue("Purchase Document Type From"::"Posted Invoice"); // Used in Copy Purchase Document handler
        LibraryVariableStorage.Enqueue(PostedDocNo); // Used in Copy Purhcase Document handler
        Commit();

        // [GIVEN] Copy posted purchase invoice line to newly created Purchase Credit Memo.
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.RunModal();

        LibraryERM.CreateReasonCode(ReasonCode);
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Reason Code", ReasonCode.Code);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase Credit Memo
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify that non-inventoriable cost amount equals to purchased cost amount.
        VerifyNonInventoriableCost(PostedDocNo, '', -Quantity, -Item."Unit Price" * Quantity);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesCrMemondVerifyNonInventoriableCost(IsService: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedCreditMemoNo: Code[20];
        Quantity: Decimal;
    begin
        Customer.Get(CreateCustomer());
        Item.Get(CreateServiceOrNonStockItem(FindVATProdPostingGroup(Customer."VAT Bus. Posting Group"), IsService));

        // [GIVEN] Create Credit Memo.
        Quantity := LibraryRandom.RandDec(10, 2);  // Using Random value for Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);

        // [WHEN] Post Credit Memo.
        PostedCreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify that non-inventoriable cost amount equals to COGS.
        VerifyNonInventoriableCost(PostedCreditMemoNo, '', Quantity, Item."Unit Cost" * Quantity);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; SignFactor: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Use Random value for Quantity and Direct Unit Cost.
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CreateVendor());
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), SignFactor * PurchaseLine.Quantity,
          PurchaseLine."Direct Unit Cost");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndModifyItem(StandardCost: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem());
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", StandardCost);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemChargeAssignmentUsingShipmentLine(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseLine: Record "Purchase Line"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        FindShipmentLine(SalesShipmentLine, PurchaseOrderNo, ItemNo);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Sales Shipment",
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");
    end;

    local procedure CreateItemChargeAssignmentUsingReceiptLine(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseLine: Record "Purchase Line"; OrderNo: Code[20]; ItemNo: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        FindReturnReceiptLine(ReturnReceiptLine, OrderNo, ItemNo);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Receipt",
          ReturnReceiptLine."Document No.", ReturnReceiptLine."Line No.", ReturnReceiptLine."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateServiceOrNonStockItem(VATProdPostingGroup: Code[20]; IsService: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        if IsService then
            Item.Validate(Type, Item.Type::Service)
        else
            Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        // Using Random value for Unit Cost
        Item.Validate("Unit Price", Item."Unit Cost" * 2);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreatePurchaseDocumentWithChargeAssignment(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; OrderNo: Code[20]; ItemNo: Code[20]; DirectUnitCost: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        CreatePurchaseDocumentUsingChargeItem(PurchaseLine, DocumentType, DirectUnitCost);
        CreateItemChargeAssignmentUsingReceiptLine(ItemChargeAssignmentPurch, PurchaseLine, OrderNo, ItemNo);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseDocumentAndAssignCharge(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PurchaseOdrerNo: Code[20]; ItemNo: Code[20]; DirectUnitCost: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        CreatePurchaseDocumentUsingChargeItem(PurchaseLine, DocumentType, DirectUnitCost);
        CreateItemChargeAssignmentUsingShipmentLine(ItemChargeAssignmentPurch, PurchaseLine, PurchaseOdrerNo, ItemNo);
    end;

    local procedure CreatePurchaseDocumentUsingChargeItem(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CreateVendor());
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), 1, DirectUnitCost);  // Taking 1 for Item Charge.
        exit(PurchaseLine."No.");
    end;

    local procedure CreatePurchaseDocumentWithChargeItemAndItem(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; QuantitySignFactor: Integer; CostSignFactor: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Use Random value for Quantity and Direct Unit Cost.
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(),
          QuantitySignFactor * PurchaseLine.Quantity, CostSignFactor * PurchaseLine."Direct Unit Cost");
    end;

    local procedure CreatePurchaseDocumentWithMultipleLinesWithItemCharge(var PurchaseLine2: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; CurrencyCode: Code[10]; PricesIncludingVAT: Boolean; LineDiscountPct: Decimal; Quantity: Decimal; DirectUnitCost: Decimal): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        CreateVATPostingSetup(VATPostingSetup);
        UpdateItem(Item, VATPostingSetup."VAT Prod. Posting Group");
        UpdateItemCharge(ItemCharge, VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Modify(true);

        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandDec(1000, 5), LibraryRandom.RandDec(1000, 5));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDec(100, 5)); // Random discount is not important.
        PurchaseLine.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandDec(2000, 5), LibraryRandom.RandDec(2000, 5));
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"Charge (Item)",
          ItemCharge."No.", Quantity, DirectUnitCost);
        PurchaseLine2.Validate("Line Discount %", LineDiscountPct); // Random discount is not important.
        PurchaseLine2.Validate("Allow Invoice Disc.", true);
        PurchaseLine2.Modify(true);
        exit(VATPostingSetup."VAT %");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; CustomerNo: Code[20]; UnitPrice: Decimal; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalesHeader.Validate("Salesperson Code", SalespersonPurchaser.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo2, LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Document Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithMultipleLinesWithItemCharge(var SalesLine2: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; CurrencyCode: Code[10]; PricesIncludingVAT: Boolean; LineDiscountPct: Decimal; Quantity: Decimal; UnitPrice: Decimal): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        UpdateItem(Item, VATPostingSetup."VAT Prod. Posting Group");
        UpdateItemCharge(ItemCharge, VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Modify(true);
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        GLAccount.Get(CustomerPostingGroup.GetInvRoundingAccount());
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(1000, 5),
          LibraryRandom.RandDec(1000, 5));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(100, 5)); // Random discount is not important.
        SalesLine.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(2000, 5),
          LibraryRandom.RandDec(2000, 5));
        CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::"Charge (Item)", ItemCharge."No.", Quantity, UnitPrice);
        SalesLine2.Validate("Line Discount %", LineDiscountPct); // Random discount is not important.
        SalesLine2.Validate("Allow Invoice Disc.", true);
        SalesLine2.Modify(true);
        exit(VATPostingSetup."VAT %");
    end;

    local procedure CreateStandardCostWorksheet(var StandardCostWorksheet: TestPage "Standard Cost Worksheet"; ItemNo: Code[20]; StandardCost: Decimal; NewStandardCost: Decimal)
    begin
        StandardCostWorksheet."No.".SetValue(ItemNo);
        StandardCostWorksheet."Standard Cost".SetValue(StandardCost);
        StandardCostWorksheet."New Standard Cost".SetValue(NewStandardCost);
        StandardCostWorksheet.Next();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithInvoiceDiscount(var VendInvoiceDisc: Record "Vendor Invoice Disc."; CurrencyCode: Code[10]; InvoiceDiscPct: Decimal): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateInvDiscForVendor(VendInvoiceDisc, Vendor."No.", CurrencyCode, 0);
        VendInvoiceDisc.Validate("Discount %", InvoiceDiscPct);
        VendInvoiceDisc.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerWithInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc."; CurrencyCode: Code[10]; InvoiceDiscPct: Decimal): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", CurrencyCode, 0);
        CustInvoiceDisc.Validate("Discount %", InvoiceDiscPct);
        CustInvoiceDisc.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        // Use Random VAT % because value is not important.
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Sales VAT Account", GLAccount2."No.");
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount2."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateCurrency(var Currency: Record Currency)
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
    end;

    local procedure CreateCurrencyWithExchangeRate(var Currency: Record Currency; ExchangeRate: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", ExchangeRate);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", ExchangeRate);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithItemChargeAndCalcInvDisc(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; CurrencyCode: Code[10]; PricesIncludingVAT: Boolean; LineDiscountPct: Decimal; Quantity: Decimal; DirectUnitCost: Decimal) VATPct: Decimal
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        VATPct :=
          CreatePurchaseDocumentWithMultipleLinesWithItemCharge(
            PurchaseLine, PurchaseHeader."Document Type"::Invoice, VendorNo, CurrencyCode,
            PricesIncludingVAT, LineDiscountPct, Quantity, DirectUnitCost);

        // Calculate Invoice Discount and find Purchase Line with Charge Item.
        CalcInvoiceDiscountAndFindPurchaseLine(PurchaseLine, PurchaseHeader);
    end;

    local procedure CreateSalesDocumentWithItemChargeAndCalcInvDisc(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; CurrencyCode: Code[10]; PricesIncludingVAT: Boolean; LineDiscountPct: Decimal; Quantity: Decimal; UnitPrice: Decimal) VATPct: Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        VATPct :=
          CreateSalesDocumentWithMultipleLinesWithItemCharge(
            SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo, CurrencyCode,
            PricesIncludingVAT, LineDiscountPct, Quantity, UnitPrice); // Prices Including VAT is unchecked.

        // Calculate Invoice Discount and find sales line with Charge Item.
        CalcInvoiceDiscountAndFindSalesLine(SalesLine, SalesHeader);
    end;

    local procedure ChargeAssignmentUsingShipmentLines(var PurchaseLine: Record "Purchase Line"; Quantity: Decimal): Code[20]
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ItemChargeNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        ItemNo := CreateItem();
        ItemNo2 := CreateItem();
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, ItemNo, ItemNo2, Quantity);
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(ItemNo2);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemChargeNo :=
          CreatePurchaseDocumentUsingChargeItem(
            PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        CreateItemChargeAssignmentUsingShipmentLine(ItemChargeAssignmentPurch, PurchaseLine, SalesHeader."No.", ItemNo);
        CreateItemChargeAssignmentUsingShipmentLine(ItemChargeAssignmentPurch, PurchaseLine, SalesHeader."No.", ItemNo2);
        exit(ItemChargeNo);
    end;

    local procedure ChargeAssignmentUsingReceiptLines(var PurchaseLine: Record "Purchase Line"; Quantity: Decimal): Code[20]
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ItemChargeNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        ItemNo := CreateItem();
        ItemNo2 := CreateItem();
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", ItemNo, ItemNo2, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemChargeNo :=
          CreatePurchaseDocumentUsingChargeItem(
            PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        CreateItemChargeAssignmentUsingReceiptLine(ItemChargeAssignmentPurch, PurchaseLine, SalesHeader."No.", ItemNo);
        CreateItemChargeAssignmentUsingReceiptLine(ItemChargeAssignmentPurch, PurchaseLine, SalesHeader."No.", ItemNo2);
        exit(ItemChargeNo);
    end;

    local procedure CalcInvoiceDiscountAndFindPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
    end;

    local procedure CalcInvoiceDiscountAndFindSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();
    end;

    local procedure DuplicateRevaluationJournalConfirmMessage(LineCount: Integer)
    var
        ItemNo: Code[20];
    begin
        // Setup: Create Item, post purchase order for it. Adjust standard cost for the item from standard cost worksheet and implement cost changes.
        // One revaluation journal line will be generated for the item.
        ItemNo := PostPurchOrderAndImplementStdCostChanges();

        // Exercise: Click Implement Standard Cost Changes button from page, a confirm message will pop up to indicate duplicate revaluation journal.
        // Click Yes or No on confirm message
        ImplementStdCostChangesFromPage();

        // Verify: Verify the count of revaluation journal lines generated.
        VerifyItemJnlLineCount(ItemNo, LineCount);
    end;

    local procedure FindReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20]; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20]; No: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.SetRange("No.", No);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; ReturnOrderNo: Code[20]; No: Code[20])
    begin
        ReturnReceiptLine.SetRange("Return Order No.", ReturnOrderNo);
        ReturnReceiptLine.SetRange("No.", No);
        ReturnReceiptLine.FindFirst();
    end;

    local procedure FindReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ReturnOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentLine.SetRange("No.", ItemNo);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; DocumentNo: Code[20]; ItemChargeNo: Code[20]; ValuedQuantity: Decimal)
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        ValueEntry.SetRange("Valued Quantity", ValuedQuantity);
        ValueEntry.FindFirst();
    end;

    local procedure FindVATProdPostingGroup(VATBusPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter(
          "VAT Calculation Type", '<>%1', VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.FindFirst();
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure ImplementStandardCostChanges(Item: Record Item; NewStandardCost: Decimal)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        StandardCostWorksheetPage: TestPage "Standard Cost Worksheet";
    begin
        StandardCostWorksheet.DeleteAll();
        StandardCostWorksheetPage.OpenEdit();
        CreateStandardCostWorksheet(StandardCostWorksheetPage, Item."No.", Item."Standard Cost", NewStandardCost);
        Commit();  // Commit Required due to Run Modal.
        StandardCostWorksheetPage."&Implement Standard Cost Changes".Invoke();
    end;

    local procedure ImplementStdCostChangesFromPage()
    var
        StandardCostWorksheetPage: TestPage "Standard Cost Worksheet";
    begin
        StandardCostWorksheetPage.OpenEdit();
        LibraryVariableStorage.Enqueue(DuplicateJournalQst); // Enqueue message for Confirm Handler
        Commit(); // Commit Required due to Run Modal
        StandardCostWorksheetPage."&Implement Standard Cost Changes".Invoke(); // Click Implement Standard Cost Changes button
    end;

    local procedure PostPurchasePartialReceiptWithChargeAssignment(var PurchaseLine: Record "Purchase Line"; ExpdAssignableAmount: Decimal; MenuOption: Integer; PostReceipt: Boolean; PostInvoice: Boolean)
    begin
        AssignItemChargeWithSuggest(ExpdAssignableAmount, MenuOption);
        PurchaseLine.ShowItemChargeAssgnt();
        PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.", PostReceipt, PostInvoice);
        PurchaseLine.Find();
    end;

    local procedure PostSalesPartialShipmentWithChargeAssignment(var SalesLine: Record "Sales Line"; ExpdAssignableAmount: Decimal; MenuOption: Integer; PostShipment: Boolean; PostInvoice: Boolean)
    begin
        AssignItemChargeWithSuggest(ExpdAssignableAmount, MenuOption);
        SalesLine.ShowItemChargeAssgnt();
        PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", PostShipment, PostInvoice);
        SalesLine.Find();
    end;

    local procedure PostSalesAndPurchaseDocumentForChargeItem(var PurchaseHeader: Record "Purchase Header"; PurchaseDocumentType: Enum "Purchase Document Type"; SalesDocumentType: Enum "Sales Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        CreateAndPostSalesOrder(SalesLine, SalesDocumentType);
        CreatePurchaseDocumentAndAssignCharge(
          PurchaseLine, PurchaseDocumentType, SalesLine."Document No.", SalesLine."No.", -LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure PostPurchaseDocumentUsingSalesReturnOrder(var PurchaseHeader: Record "Purchase Header"; PurchaseDocumentType: Enum "Purchase Document Type"; SalesDocumentType: Enum "Sales Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        CreateAndPostSalesOrder(SalesLine, SalesDocumentType);
        CreatePurchaseDocumentWithChargeAssignment(
          PurchaseLine, PurchaseDocumentType, SalesLine."Document No.", SalesLine."No.", -LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure PostPurchOrderAndImplementStdCostChanges(): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Item.Get(CreateAndModifyItem(LibraryRandom.RandInt(10)));
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        Item.Validate("VAT Prod. Posting Group", FindVATProdPostingGroup(PurchaseHeader."VAT Bus. Posting Group"));
        Item.Modify(true);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ImplementStandardCostChanges(Item, Item."Standard Cost" + LibraryRandom.RandInt(10));
        exit(Item."No.");
    end;

    local procedure PostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ToShipReceive: Boolean; ToInvoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, DocumentNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToShipReceive, ToInvoice);
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; ToShipReceive: Boolean; ToInvoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        LibrarySales.PostSalesDocument(SalesHeader, ToShipReceive, ToInvoice);
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        VendorNo: Code[10];
    begin
        VendorNo := LibraryUtility.GenerateGUID();
        PurchaseHeader.Validate("Vendor Invoice No.", VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", VendorNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateItem(var Item: Record Item; VATProdPostingGroup: Code[20])
    begin
        Item.Get(CreateItem());
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
    end;

    local procedure UpdateItemCharge(var ItemCharge: Record "Item Charge"; VATProdPostingGroup: Code[20])
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemCharge.Modify(true);
    end;

    local procedure UpdateExactCostReversingMandatory(NewValue: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", NewValue);
        SalesReceivablesSetup.Modify();
    end;

    local procedure AssignItemChargeWithSuggest(ExpdAssignableAmount: Decimal; Menu: Integer)
    begin
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpdAssignableAmount);
        LibraryVariableStorage.Enqueue(Menu);
    end;

    local procedure AssignItemChargeWithoutSuggest(ExpdAssignableAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ExpdAssignableAmount);
    end;

    local procedure RunPurchaseReportAndAssignItemChargeWithoutSuggest(ExpdAssignableAmount: Decimal)
    begin
        Commit();
        REPORT.Run(REPORT::"Purchase Document - Test");
        AssignItemChargeWithoutSuggest(ExpdAssignableAmount);
    end;

    local procedure RunSalesReportAndAssignItemChargeWithoutSuggest(ExpdAssignableAmount: Decimal)
    begin
        Commit();
        REPORT.Run(REPORT::"Sales Document - Test");
        AssignItemChargeWithoutSuggest(ExpdAssignableAmount);
    end;

    local procedure MockItemLedgerEntryWithDim(CustomerNo: Code[20]; DimValue1: Code[20]; DimValue2: Code[20]) ExpectedResult: Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RecRef: RecordRef;
        Cnt: Integer;
    begin
        for Cnt := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            ItemLedgerEntry.Init();
            RecRef.GetTable(ItemLedgerEntry);
            ItemLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ItemLedgerEntry.FieldNo("Entry No."));
            ItemLedgerEntry."Source Type" := ItemLedgerEntry."Source Type"::Customer;
            ItemLedgerEntry."Source No." := CustomerNo;
            ItemLedgerEntry."Global Dimension 1 Code" := DimValue1;
            ItemLedgerEntry."Global Dimension 2 Code" := DimValue2;
            ItemLedgerEntry.Insert();
            ExpectedResult := ExpectedResult + MockValueEntries(ItemLedgerEntry."Entry No.", ItemLedgerEntry."Source Type", ItemLedgerEntry."Source No.", DimValue1, DimValue2);
        end;
    end;

    local procedure MockResourceLedgerEntry(var ResLedgerEntry: Record "Res. Ledger Entry"; EntryType: Enum "Res. Journal Line Entry Type"; CustomerNo: Code[20])
    begin
        ResLedgerEntry.Init();
        ResLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ResLedgerEntry, ResLedgerEntry.FieldNo("Entry No."));
        ResLedgerEntry."Entry Type" := EntryType;
        ResLedgerEntry."Source Type" := ResLedgerEntry."Source Type"::Customer;
        ResLedgerEntry."Source No." := CustomerNo;
        ResLedgerEntry."Total Cost" := LibraryRandom.RandDec(10, 2);
        ResLedgerEntry.Insert();
    end;

    local procedure MockValueEntries(ItemLedgerEntryNo: Integer; SourceType: Enum "Analysis Source Type"; SourceNo: Code[20]; DimValue1: Code[20]; DimValue2: Code[20]) ExpectedResult: Decimal
    var
        ValueEntry: Record "Value Entry";
        RecRef: RecordRef;
        Cnt: Integer;
    begin
        for Cnt := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            ValueEntry.Init();
            RecRef.GetTable(ValueEntry);
            ValueEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ValueEntry.FieldNo("Entry No."));
            ValueEntry."Source Type" := SourceType;
            ValueEntry."Source No." := SourceNo;
            ValueEntry."Global Dimension 1 Code" := DimValue1;
            ValueEntry."Global Dimension 2 Code" := DimValue2;
            ValueEntry."Cost Amount (Non-Invtbl.)" := LibraryRandom.RandInt(100);
            ExpectedResult := ExpectedResult + ValueEntry."Cost Amount (Non-Invtbl.)";
            ValueEntry."Item Ledger Entry No." := ItemLedgerEntryNo;
            ValueEntry.Insert();
        end;
    end;

    local procedure VerifyChargeItemAssignment(ItemNo: Code[20]; AmountToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetRange("Item No.", ItemNo);
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.TestField("Amount to Assign", AmountToAssign);
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", 1);  // Using 1 because only one Quantity of Charge Item is assigned.
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; CustomerNo: Code[20]; ProfitLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(ProfitLCY, CustLedgerEntry."Profit (LCY)", GeneralLedgerSetup."Inv. Rounding Precision (LCY)", UnexpMsg);
    end;

    local procedure VerifyCustomerStatistic(No: Code[20]; ExpAdjustedProfit: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustomerStatistics: TestPage "Customer Statistics";
        AdjustedProfit: Decimal;
    begin
        CustomerStatistics.OpenView();
        CustomerStatistics.FILTER.SetFilter("No.", No);
        Evaluate(AdjustedProfit, CustomerStatistics.ThisPeriodAdjustedProfitLCY.Value);
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(ExpAdjustedProfit, AdjustedProfit, GeneralLedgerSetup."Inv. Rounding Precision (LCY)", UnexpMsg);
        CustomerStatistics.OK().Invoke();
    end;

    local procedure VerifyNonInventoriableCost(DocumentNo: Code[20]; ItemChargeNo: Code[20]; ValuedQuantity: Decimal; CostAmountNonInvtbl: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, DocumentNo, ItemChargeNo, ValuedQuantity);
        ValueEntry.TestField("Cost Amount (Non-Invtbl.)", Round(CostAmountNonInvtbl, LibraryERM.GetAmountRoundingPrecision()));
        if ItemChargeNo <> '' then
            ValueEntry.TestField("Cost per Unit", 0)
        else
            ValueEntry.TestField(
              "Cost per Unit",
              Round(ValueEntry."Cost Amount (Non-Invtbl.)" / ValuedQuantity, LibraryERM.GetUnitAmountRoundingPrecision()));
    end;

    local procedure VerifyActualCost(DocumentNo: Code[20]; ItemChargeNo: Code[20]; ValuedQuantity: Decimal; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, DocumentNo, ItemChargeNo, ValuedQuantity);
        ValueEntry.TestField("Cost Amount (Actual)", Round(CostAmountActual, LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure VerifyPostedSalesInvoiceStatistic(No: Code[20]; ExpAdjustedProfit: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesInvoiceStatistics: TestPage "Sales Invoice Statistics";
        AdjustedProfit: Decimal;
    begin
        SalesInvoiceStatistics.OpenView();
        SalesInvoiceStatistics.FILTER.SetFilter("No.", No);
        Evaluate(AdjustedProfit, SalesInvoiceStatistics.AdjustedProfitLCY.Value);
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(ExpAdjustedProfit, AdjustedProfit, GeneralLedgerSetup."Inv. Rounding Precision (LCY)", UnexpMsg);
        SalesInvoiceStatistics.OK().Invoke();
    end;

    local procedure VerifyValueEntryForChargeItem(DocumentNo: Code[20]; ItemChargeNo: Code[20]; ValuedQuantity: Decimal; Inventoriable: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, DocumentNo, ItemChargeNo, ValuedQuantity);
        ValueEntry.TestField(Inventoriable, Inventoriable);
    end;

    local procedure VerifyItemJnlLineCount(ItemNo: Code[20]; ExpectedCount: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        Assert.AreEqual(ExpectedCount, ItemJournalLine.Count, StrSubstNo(ItemJnlLineCountErr, ExpectedCount, ItemNo));
    end;

    local procedure VerifyMsgForHandler(ActualMsg: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMsg);
        Assert.IsTrue(StrPos(ActualMsg, ExpectedMsg) > 0, ActualMsg);
    end;

    local procedure CreateLotsOnItemTrackingLines(var ItemTrackingLines: TestPage "Item Tracking Lines"; LotsCount: Integer);
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        if LotsCount <= 0 then
            exit;

        repeat
            ItemTrackingLines."Lot No.".SetValue(UpperCase(LibraryRandom.RandText(MaxStrLen(TrackingSpecification."Lot No."))));
            ItemTrackingLines."Quantity (Base)".SetValue(1.0);
            ItemTrackingLines.Next();
            LotsCount -= 1;
        until LotsCount = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SuggstItemChargeAssgntPurchHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    var
        Suggest: Variant;
        ExpdAssignableAmount: Decimal;
        ActualAssignableAmount: Decimal;
        RequireSuggest: Boolean;
    begin
        LibraryVariableStorage.Dequeue(Suggest);
        ExpdAssignableAmount := LibraryVariableStorage.DequeueDecimal();
        ActualAssignableAmount := ItemChargeAssignmentPurch.AssgntAmount.AsDecimal();
        RequireSuggest := Suggest;
        if RequireSuggest then
            ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
        Assert.AreEqual(ExpdAssignableAmount, ActualAssignableAmount, AssignableAmountErr);
        ItemChargeAssignmentPurch.RemAmountToAssign.AssertEquals(0);
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    var
        PartialQty: Variant;
    begin
        LibraryVariableStorage.Dequeue(PartialQty);
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(PartialQty);
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SuggstItemChargeAssgntSalesHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    var
        ExpdAssignableAmount: Decimal;
        RequireSuggest: Boolean;
        ActualAssignableAmount: Decimal;
    begin
        RequireSuggest := LibraryVariableStorage.DequeueBoolean();
        ExpdAssignableAmount := LibraryVariableStorage.DequeueDecimal();
        ActualAssignableAmount := ItemChargeAssignmentSales.AssignableAmount.AsDecimal();
        if RequireSuggest then
            ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke();
        Assert.AreEqual(ExpdAssignableAmount, ActualAssignableAmount, AssignableAmountErr);
        ItemChargeAssignmentSales.RemAmountToAssign.AssertEquals(0);
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentMultipleLinePageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetReturnShipmentLines.Invoke();
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        OptionCount: Variant;
    begin
        LibraryVariableStorage.Dequeue(OptionCount);  // Dequeue variable.
        Choice := OptionCount;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReturnShipmentLinesPageHandler(var ReturnShipmentLines: TestPage "Return Shipment Lines")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        ReturnShipmentLines.FILTER.SetFilter("No.", No);
        ReturnShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::AssignSerialNos:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    ItemTrackingLines.OK().Invoke();
                end;
            ItemTrackingMode::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::CreateThreeLots:
                CreateLotsOnItemTrackingLines(ItemTrackingLines, 3);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        VerifyMsgForHandler(ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        VerifyMsgForHandler(ConfirmMessage);
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImplementStandardCostChangesHandler(var ImplementStandardCostChange: TestRequestPage "Implement Standard Cost Change")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalTemplate.SetValue(ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalBatchName.SetValue(ItemJournalBatch.Name);
        ImplementStandardCostChange.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportPurchaseDocumentTestHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportSalesDocumentTestHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopySalesDocumentRequestPageHandler(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    var
        DocumentTypeVar: Variant;
        DocumentNoVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentTypeVar);
        LibraryVariableStorage.Dequeue(DocumentNoVar);

        CopySalesDocument.DocumentType.SetValue(DocumentTypeVar);
        CopySalesDocument.DocumentNo.SetValue(DocumentNoVar);
        CopySalesDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPurchaseDocumentRequestPageHandler(var CopyPurchaseDocument: TestRequestPage "Copy Purchase Document")
    var
        DocumentTypeVar: Variant;
        DocumentNoVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentTypeVar);
        LibraryVariableStorage.Dequeue(DocumentNoVar);

        CopyPurchaseDocument.DocumentType.SetValue(DocumentTypeVar);
        CopyPurchaseDocument.DocumentNo.SetValue(DocumentNoVar);
        CopyPurchaseDocument.OK().Invoke();
    end;
}

