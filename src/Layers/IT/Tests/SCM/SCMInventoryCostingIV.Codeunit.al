codeunit 137289 "SCM Inventory Costing IV"
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
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        ValueEntryNotMatched: Label '%1 must be %2 in %3.';
        UndoReceiptMessage: Label 'Do you really want to undo the selected Receipt lines?';
        PutAwayCreatedUndoError: Label 'You cannot undo line 10000 because warehouse put-away lines have already been created.';
        UndoInvoicedReceiptError: Label 'You cannot undo line 10000 because an item charge has already been invoiced.';
        UndoPurchRetOrderMessage: Label 'Do you really want to undo the selected Return Shipment lines?';
        UndoPickedLineMessage: Label 'The items have been picked.';
        UndoSalesShipmentMsg: Label 'Do you really want to undo the selected Shipment lines?';
        ChangeLocationMessage: Label 'You have changed Location Code on the sales header, but it has not been changed on the existing sales lines.';
        UndoSalesRetReceiptMsg: Label 'Do you really want to undo the selected Return Receipt lines?';
        ChangeCurrCodeMessage: Label 'If you change';
        ChangePostingDateMessage: Label 'You have changed the Posting Date on the sales header, which might affect the prices and discounts on the sales lines. You should review the lines and manually update prices and discounts if needed.';
        BeforeWorkDateErr: Label 'is before work date %1 in one or more of the assembly lines';
        AdjustCostErr: Label 'Cost Amount (Actual) for Assembled Item in Sale type item ledger entry should equal the negative of the sum of components''s cost after running adjust cost';
        ExpandBOMErr: Label 'BOM component should not exist for Item %1';
        CostAmountNonInvtblErr: Label 'Cost Amount (Non-Invtbl.) is not negative';
        CostAmountActualACYErr: Label 'Cost Amount (Actual) (ACY) on Item Ledger Entry is incorrect.';
        CostAmountExpectedACYErr: Label 'Cost Amount (Expected) (ACY) on Item Ledger Entry is incorrect.';
        CostPerUnitACYErr: Label 'Cost per Unit (ACY) on Value Entry is incorrect.';
        CostPostedToGLACYErr: Label 'Cost Posted to G/L (ACY) on Value Entry is incorrect.';
        ItemNoIsUnexpectedErr: Label 'Value of  Item."No." is unexpected.';

    [Test]
    [Scope('OnPrem')]
    procedure AdjustSalesOrderChangeOfUnitCost()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        CostPerUnit: Decimal;
        Amount: Decimal;
        Quantity: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Value Entry for Sales Document after change of Unit Cost.

        // Setup.
        Initialize();
        Quantity := 10 + LibraryRandom.RandDec(100, 1);  // Taking 10 + Random to make sure Quantity not less than 10.
        CreateAndUpdatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, LibraryRandom.RandDec(100, 1), Quantity,
          Quantity / 2, CreateItem(0, Item."Costing Method"::FIFO), PurchaseLine."Location Code");
        Amount := PurchaseLine."Direct Unit Cost" * PurchaseLine."Qty. to Receive";
        PostPurchaseDocument(PurchaseLine, true);
        DocumentNo := CreateAndPostSalesDocument(CreateCustomer(), PurchaseLine."No.", Quantity, true, true);

        // Update Purchase Line and Post as Invoice.
        UpdatePurchaseLine(
          PurchaseLine, PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(100, 1), PurchaseLine."Qty. to Receive",
          PurchaseLine."Location Code");
        CostPerUnit := (PurchaseLine."Direct Unit Cost" * PurchaseLine."Qty. to Receive" - Amount) / Quantity;
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdatePurchaseHeader(PurchaseHeader);  // Update Vendor Invoice and Vendor Credit Memo No.
        PostPurchaseDocument(PurchaseLine, true);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // Verify: Verify Adjustment Entry in Value Entry table.
        FindValueEntry(ValueEntry, DocumentNo, '', '', true);
        ValueEntry.TestField("Valued Quantity", -Quantity);
        Assert.AreNearlyEqual(
          CostPerUnit, ValueEntry."Cost per Unit", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValueEntryNotMatched, ValueEntry.FieldCaption("Cost per Unit"), CostPerUnit, ValueEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustSalesOrderChangeOfIndirectCost()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        Quantity: Decimal;
        PstdPurchaseDocumentNo: Code[20];
        PstdSalesDocumentNo: Code[20];
    begin
        // Verify Value Entry for Sales Document after change of Indirect Cost.

        // Setup.
        Initialize();
        Quantity := 10 + LibraryRandom.RandDec(100, 1);  // Taking 10 + Random to make sure Quantity not less than 10.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, CreateVendor(),
          CreateItem(LibraryRandom.RandDec(100, 1), Item."Costing Method"::FIFO), Quantity);
        PostPurchaseDocument(PurchaseLine, true);
        PstdSalesDocumentNo := CreateAndPostSalesDocument(CreateCustomer(), PurchaseLine."No.", Quantity, true, true);

        Item.Get(PurchaseLine."No.");
        Item.Validate("Indirect Cost %", Item."Indirect Cost %" + LibraryRandom.RandDec(100, 1));
        Item.Modify(true);

        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, PurchaseLine."Buy-from Vendor No.",
          PurchaseLine."No.", Quantity);
        PstdPurchaseDocumentNo := PostPurchaseDocument(PurchaseLine, false);

        // Find Item Leger Entry for Posted Purchase Order and Update Entry No. in Purchase Credit Memo.
        FindItemLedgerEntry(ItemLedgerEntry, PstdPurchaseDocumentNo, ItemLedgerEntry."Entry Type"::Purchase);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", PurchaseLine.Type::Item, PurchaseLine."Buy-from Vendor No.",
          Item."No.", Quantity);
        PurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        PurchaseLine.Modify(true);
        PostPurchaseDocument(PurchaseLine, true);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // Verify: Verify Adjustment Entry in Value Entry table.
        FindValueEntry(ValueEntry, PstdSalesDocumentNo, '', '', true);
        ValueEntry.TestField("Valued Quantity", -Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustTransferOrderChangeOfUnitCost()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        CostAmountActual: Decimal;
        CostPerUnit: Decimal;
        Quantity: Decimal;
        PstdSalesDocumentNo: Code[20];
        PstdTransferReceiptDocumentNo: Code[20];
        PstdTransferShipmentDocumentNo: Code[20];
    begin
        // Verify Value Entry for Transfer Order after change of Unit Cost.

        // Setup: Create and Post Purchase as Receive and Post Transfer Order.
        Initialize();
        Quantity := 10 + LibraryRandom.RandDec(100, 1);  // Taking 10 + Random to make sure Quantity not less than 10.
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        Item.Get(CreateItem(0, Item."Costing Method"::FIFO));
        CreateAndUpdatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, 0, Quantity, Quantity, Item."No.", Location.Code);  // Using 0 for Direct Unit Cost.
        PostPurchaseDocument(PurchaseLine, false);
        CreateTransferOrder(TransferHeader, Location.Code, PurchaseLine."No.", Quantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        PstdTransferReceiptDocumentNo :=
          FindTransferReceiptHeader(TransferHeader."Transfer-from Code", TransferHeader."Transfer-to Code");
        PstdTransferShipmentDocumentNo :=
          FindTransferShipmentHeader(TransferHeader."Transfer-from Code", TransferHeader."Transfer-to Code");

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CreateCustomer(), Item."No.", Quantity);
        UpdateLocationCodeOnSalesLine(SalesHeader, TransferHeader."Transfer-to Code");
        PstdSalesDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Update Direct Unit Cost on Purchase Order and Post as Invoice.
        UpdatePurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 1), 0, PurchaseLine."Location Code");
        PostPurchaseDocument(PurchaseLine, true);
        CostPerUnit := PurchaseLine."Direct Unit Cost" - Item."Unit Cost";
        CostAmountActual := Quantity * CostPerUnit;

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // Verify: Verify Adjustment Entry for Transfer and Sales Entry in Value Entry table.
        VerifyValueEntry(PstdSalesDocumentNo, TransferHeader."Transfer-to Code", -CostAmountActual, CostPerUnit, -Quantity);
        VerifyValueEntry(
          PstdTransferShipmentDocumentNo, TransferHeader."Transfer-from Code", -PurchaseLine.Amount, PurchaseLine."Direct Unit Cost",
          -Quantity);
        VerifyValueEntry(
          PstdTransferReceiptDocumentNo, TransferHeader."Transfer-to Code", PurchaseLine.Amount, PurchaseLine."Direct Unit Cost", Quantity);
        VerifyValueEntry(
          PstdTransferReceiptDocumentNo, TransferHeader."In-Transit Code", -PurchaseLine.Amount, PurchaseLine."Direct Unit Cost", -Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustUnitCostForZeroQuantityWithNonZeroCost()
    var
        Item: Record Item;
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify Item Ledger Entry for Sales Document with Non Zero Cost.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 1);

        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, CreateCustomer(), LibraryInventory.CreateItem(Item),
          Quantity);
        DocumentNo := NoSeries.PeekNextNo(SalesHeader."Shipping No. Series");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Find Item Leger Entry for Posted Sales Invoice and Update Entry No. in Sales Credit Memo.
        FindItemLedgerEntry(ItemLedgerEntry, DocumentNo, ItemLedgerEntry."Entry Type"::Sale);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, SalesHeader."Sell-to Customer No.", Item."No.",
          Quantity);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Find Return Receipt Line and Create Purchase Order for Charge Item.
        ReturnReceiptLine.SetRange("No.", Item."No.");
        ReturnReceiptLine.FindFirst();
        CreateAndUpdatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchaseLine.Type::"Charge (Item)", LibraryRandom.RandInt(100), 1, 1,
          LibraryInventory.CreateItemChargeNo(), '');  // Using 1 for Charge Item and blank value for Location.
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Receipt",
          ReturnReceiptLine."Document No.", ReturnReceiptLine."Line No.", Item."No.");
        PostPurchaseDocument(PurchaseLine, true);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Verify Item Ledger Entry for Sales Shipment and Return Receipt Lines.
        VerifyItemLedgerEntry(DocumentNo, -Quantity, 0);
        VerifyItemLedgerEntry(ReturnReceiptLine."Document No.", Quantity, PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevalueFIFOItemByItemLedgerEntry()
    var
        Item: Record Item;
    begin
        // Verify sum of Invoiced Quantity and Cost Amount (Actual) of all Value Entries after Inventory Revaluation per Item Ledger Entry and Adjust Cost - Item Entries for FIFO Item.

        // Setup and Exercise.
        Initialize();
        Item.Get(CreateItem(0, Item."Costing Method"::FIFO));  // 0 for Indirect Cost Pct.
        RevaluateInventoryAndRunAdjustCostItemEntries(Item."No.", "Inventory Value Calc. Per"::"Item Ledger Entry");

        // Verify: Verify sum of Invoiced Quantity and Cost Amount (Actual) for Value Entries.
        VerifyValueEntryAfterAdjustCostItemEntries(Item."No.", 0);  // Sum of Cost Amount (Actual) must be zero.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevalueFIFOItemByItem()
    var
        Item: Record Item;
    begin
        // Verify sum of Invoiced Quantity and Cost Amount (Actual) of all Value Entries after Inventory Revaluation per Item and Adjust Cost - Item Entries for FIFO Item.

        // Setup and Exercise.
        Initialize();
        Item.Get(CreateItem(0, Item."Costing Method"::FIFO));  // 0 for Indirect Cost Pct.
        RevaluateInventoryAndRunAdjustCostItemEntries(Item."No.", "Inventory Value Calc. Per"::Item);

        // Verify: Verify sum of Invoiced Quantity and Cost Amount (Actual) for Value Entries.
        VerifyValueEntryAfterAdjustCostItemEntries(Item."No.", 0);  // Sum of Cost Amount (Actual) must be zero.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevalueAverageItemByItem()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        CostAmountActual: Decimal;
    begin
        // Verify sum of Invoiced Quantity and Cost Amount (Actual) of all Value Entries after Inventory Revaluation per Item and Adjust Cost - Item Entries for an Average Item.

        // Setup and Exercise.
        Initialize();

        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        Item.Get(CreateItem(0, Item."Costing Method"::Average));  // 0 for Indirect Cost Pct.
        CostAmountActual := RevaluateInventoryAndRunAdjustCostItemEntries(Item."No.", "Inventory Value Calc. Per"::Item);

        // Verify: Verify sum of Invoiced Quantity and Cost Amount (Actual) for Value Entries.
        VerifyValueEntryAfterAdjustCostItemEntries(Item."No.", CostAmountActual);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchChrgInvWithACY()
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        CostAmountActualACY: Decimal;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify Value Entry for Cost Amount (Actual) (ACY) and Cost per Unit (ACY) when post Purchase Invoice for Charge Item with Additional Reporting Currency.

        // Setup: Create Currency with Exchange Rate. Update General Ledger Setup for Additional Reporting Currency. Post Purchase Invoice without Currency with Random Direct Unit Cost.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value.
        GeneralLedgerSetup.Get();
        CreateCurrencyWithExchangeRate(Currency);
        UpdateGeneralLedgerSetupForACY(Currency.Code);
        CreateAndUpdatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchaseLine.Type::Item, LibraryRandom.RandDec(10, 2), Quantity,
          Quantity, CreateItem(0, Item."Costing Method"::FIFO), '');  // Use 0 for Indirect Cost Pct.
        PostPurchaseDocument(PurchaseLine, true);
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");

        // Create Purchase Invoice for Item Charge with Currency and assign to previous posted Receipt.
        PurchaseInvoiceItemChargeAssign(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.",
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt, PurchRcptLine."Document No.", PurchRcptLine."No.", Currency.Code);
        CostAmountActualACY := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost";

        // Exercise: Post Purchase Invoice.
        DocumentNo := PostPurchaseDocument(PurchaseLine, true);

        // Verify: Verify Value Entry for Cost Amount (Actual) (ACY) and Cost per Unit (ACY).
        VerifyValueEntryAmountsInACY(
          DocumentNo, PurchaseLine."No.", Currency."Unit-Amount Rounding Precision", CostAmountActualACY,
          CostAmountActualACY / PurchRcptLine.Quantity, 0);  // Zero value for Cost Amount Expected.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchChrgInvWithoutACY()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify Value Entry for Cost Amount (Actual) (ACY) and Cost per Unit (ACY) when post Purchase Invoice for Charge Item without Additional Reporting Currency.

        // Setup: Create And Post Purchase Invoice without Currency and Random Direct Unit Cost.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value.
        CreateAndUpdatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchaseLine.Type::Item, LibraryRandom.RandDec(10, 2), Quantity,
          Quantity, CreateItem(0, Item."Costing Method"::FIFO), '');  // Use 0 for Indirect Cost Pct.
        PostPurchaseDocument(PurchaseLine, true);
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");

        // Create Purchase Invoice for Item Charge without Currency and assign to previous posted Receipt.
        PurchaseInvoiceItemChargeAssign(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.",
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt, PurchRcptLine."Document No.", PurchRcptLine."No.", '');

        // Exercise: Post Purchase Invoice.
        DocumentNo := PostPurchaseDocument(PurchaseLine, true);

        // Verify: Verify Value Entry for Cost Amount (Actual) (ACY) and Cost per Unit (ACY).
        VerifyValueEntryAmountsInACY(DocumentNo, PurchaseLine."No.", LibraryERM.GetAmountRoundingPrecision(), 0, 0, 0);  // Cost Amount Actual (ACY), Cost per Unit (ACY), Cost Amount Expected and Cost Amount Expected (ACY) must be zero.
    end;

    // [Test]
    // [HandlerFunctions('PurchItemChargeAssignmentHandler,SalesShipmentLinePageHandler')]
    // [Scope('OnPrem')]
    procedure PostPurchChrgInvToSalesOrderWithACY()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Value Entry for Cost Amount (Non-Invtbl.)(ACY) when post Purchase Order for Charge Item with Additional Reporting Currency.
        Initialize();
        PostPurchDocumentToSalesOrderWithACY(PurchaseLine."Document Type"::Order);
    end;

    // [Test]
    // [HandlerFunctions('PurchItemChargeAssignmentHandler,SalesShipmentLinePageHandler')]
    // [Scope('OnPrem')]
    procedure PostPurchChrgOrderToSalesOrderWithACY()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Value Entry for Cost Amount (Non-Invtbl.)(ACY) when post Purchase Invoice for Charge Item with Additional Reporting Currency.
        Initialize();
        PostPurchDocumentToSalesOrderWithACY(PurchaseLine."Document Type"::Invoice);
    end;

    local procedure PostPurchDocumentToSalesOrderWithACY(DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        DocumentNo: Code[20];
        CostAmountNonInvtblACY: Decimal;
    begin
        // Setup: Create Currency with Exchange Rate. Update General Ledger Setup for Additional Reporting Currency.
        // Create and post Sales Order as Ship.
        GeneralLedgerSetup.Get();
        CreateCurrencyWithExchangeRate1(Currency, CurrencyExchangeRate);
        UpdateGeneralLedgerSetupForACY(Currency.Code);
        DocumentNo := CreateAndPostSalesDocument(
            CreateCustomer(), CreateItem(0, Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2), true, false);

        // Exercise: Create Purchase Document for Item Charge and assign to previous posted Shipment.
        AssignItemChargeToSalesShptLines(PurchaseLine, DocumentType, DocumentNo);

        // Post Purchase Document.
        DocumentNo := PostPurchaseDocument(PurchaseLine, true);
        // Verify: Verify Value Entry for Cost Amount (Non-Invtbl.)(ACY).
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Charge No.", PurchaseLine."No.");
        ValueEntry.FindFirst();
        CostAmountNonInvtblACY := Round(ValueEntry."Cost Amount (Non-Invtbl.)" * CurrencyExchangeRate."Exchange Rate Amount" /
            CurrencyExchangeRate."Relational Exch. Rate Amount", LibraryERM.GetAmountRoundingPrecision());
        ValueEntry.TestField("Cost Amount (Non-Invtbl.)(ACY)", CostAmountNonInvtblACY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostManufacturingOutputWithACY()
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        CostAmountExpectedACY: Decimal;
    begin
        // Verify Value Entry for Cost Amount (Expected) (ACY) when post Output Journal with Additional Reporting Currency.

        // Setup: Create Currency with Exchange Rate. Update General Ledger Setup for Additional Reporting Currency.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateCurrencyWithExchangeRate(Currency);
        UpdateGeneralLedgerSetupForACY(Currency.Code);
        Item.Get(CreateItem(0, Item."Costing Method"::FIFO));  // Use 0 for Indirect Cost Pct.

        // Create Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.");
        CostAmountExpectedACY := LibraryERM.ConvertCurrency(Item."Unit Cost" * ProductionOrder.Quantity, '', Currency.Code, WorkDate());

        // Exercise: Post Output Journal.
        CreateAndPostOutputJournal(ItemJournalLine, Item."No.", ProductionOrder."No.");

        // Verify: Verify Value Entry for Cost Amount (Expected) (ACY).
        VerifyValueEntryAmountsInACY(ProductionOrder."No.", '', LibraryERM.GetAmountRoundingPrecision(), 0, 0, CostAmountExpectedACY);  // Zero value for Cost Amount Actual (ACY) and Cost per Unit (ACY).
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnUndoPurchRcptWithReservation()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify Error while Undo Receipt after reservation of the Item from Sales Order.

        // Setup: Create Purchase Order and Post, create Sale Order and reserve the Item.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, LibraryRandom.RandDec(50, 1), false);  // Use Random value.
        CreateSalesDocumentAndReserve(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue ConfirmMessageHandler.

        // Exercise.
        asserterror UndoPurchaseReceiptLines(PurchaseLine);

        // Verify. Verify Error while Undo Receipt of reserved Item.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Reserved Quantity"), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,GetReceiptLinesHandler')]
    [Scope('OnPrem')]
    procedure GetReceiptLineFromPurchInvAfterUndoReceipt()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Verify Get Receipt Line page, not find any Receipt Line from Purchase Invoice.

        // Setup: Create Purchase Order, Post and undo Receipt.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, LibraryRandom.RandDec(50, 1), false);  // Use Random value.
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue ConfirmMessageHandler.
        UndoPurchaseReceiptLines(PurchaseLine);

        // Create Purchase Invoice and Get Receipt Line.
        CreatePurchaseDocument(
          PurchaseLine2, PurchaseLine2."Document Type"::Invoice, PurchaseLine2.Type::Item, PurchaseLine."Buy-from Vendor No.",
          PurchaseLine."No.", PurchaseLine.Quantity);

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Receipt", PurchaseLine2);

        // Verify: Verify Get Receipt Line page, done by GetReceiptLinesHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchRcptWithAppliedQuantity()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error when undo a Purchase Receipt Line with applied Quantity.

        // Setup: Create Purchase Order and Receive Purchase Order.
        Initialize();
        PurchaseApplication(PurchaseLine, PurchaseLine."Document Type"::Order, LibraryRandom.RandDec(50, 1));  // Use Random value.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseHeader."Last Receiving No.", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Receipt Line.
        asserterror UndoPurchaseReceiptLines(PurchaseLine);

        // Verify: Verify error after undo Receipt with applied Quantity.
        Assert.ExpectedTestFieldError(ItemLedgerEntry.FieldCaption("Remaining Quantity"), Format(PurchaseLine.Quantity));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchRcptWithPutAway()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error after undo Receipt with Put Away created after post Warehouse Receipt.

        // Setup: Create Purchase Order with Warehouse Location and create Whse. Receipt and Post.
        Initialize();
        CreatePurchaseDocumentWithWhseLocation(PurchaseLine, PurchaseLine."Document Type"::Order);  // Use Random value.
        CreateAndPostWarehouseReceiptFromPO(PurchaseLine);
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Receipt Line.
        asserterror UndoPurchaseReceiptLines(PurchaseLine);

        // Verify: Verify error after undo Receipt with Whse. Receipt.
        Assert.ExpectedError(PutAwayCreatedUndoError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchRcptAfterCreateItemChargeInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Verify undo Purchase Receipt for that Invoice created with Item Charge Assignment.

        // Setup: Create Purchase Order, Post, create Purchase Invoice with Item Charge Assignment.
        Initialize();
        PurchaseDocumentWithItemChargeAssignment(PurchaseLine, false);

        // Exercise: Undo Purchase Receipt Line.
        UndoPurchaseReceiptLines(PurchaseLine);

        // Verify: Verify Error while Undo Invoiced Purchase Receipt.
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");
        PurchRcptLine.TestField(Correction, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchRcptAfterPostItemChargeInvoice()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Error while undo Purchase Receipt which Invoiced with Item Charge Assignment.

        // Setup: Create Purchase Order, Post, create Purchase Invoice with Item Charge Assignment and Post.
        Initialize();
        PurchaseDocumentWithItemChargeAssignment(PurchaseLine, true);

        // Exercise: Undo Purchase Receipt Line.
        asserterror UndoPurchaseReceiptLines(PurchaseLine);

        // Verify: Verify Error while Undo Invoiced Purchase Receipt.
        Assert.ExpectedError(UndoInvoicedReceiptError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoRetShptAfterCreateWhsePick()
    var
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Verify Corrective Line on Return Shipment after create Pick, Register and post Whse. Shipment.

        // Setup: Create Purchase Return Order, create and post Item Journal Line, create Whse. Shipment, Register and Post.
        Initialize();
        CreatePurchaseDocumentWithWhseLocation(PurchaseLine, PurchaseLine."Document Type"::"Return Order");
        CreateAndPostItemJournalLine(ItemJournalLine, PurchaseLine."No.", PurchaseLine.Quantity, PurchaseLine."Location Code");
        CreatePickAndRegisterWhseShipment(WarehouseShipmentHeader, PurchaseLine."Document No.", PurchaseLine."Location Code", false);
        LibraryVariableStorage.Enqueue(UndoPurchRetOrderMessage);  // Enqueue value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(UndoPickedLineMessage);  // Enqueue value for ConfirmHandler.

        // Exercise.
        UndoReturnShipment(PurchaseLine);

        // Verify: Verify Corrective Line on Return Shipment after create Pick, Register and post Whse. Shipment.
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine);
        ReturnShipmentLine.TestField(Correction, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchRetShptAfterCreateItemChargeCrMemo()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Verify undo Purchase Return Shipment for that Invoice created with Item Charge Assignment.

        // Setup: Create Purchase Return Order, Post, create Purchase Invoice with Item Charge Assignment.
        Initialize();
        PurchaseReturnWithItemChargeAssignment(PurchaseLine, false);

        // Exercise: Undo Purchase Return Shipment Line.
        UndoReturnShipment(PurchaseLine);

        // Verify: Verify Corrective Purchase Return Shipment Lines.
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine);
        ReturnShipmentLine.TestField(Correction, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnUndoPurchRetShptWithAppliedNegQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Corrective Line after undo Purchase Return Shipment Line with applied Quantity.

        // Setup: Create Purchase Return Order and Ship, create Sales Order for same Item and Post.
        Initialize();
        PurchaseApplication(PurchaseLine, PurchaseLine."Document Type"::"Return Order", -LibraryRandom.RandDec(50, 1));
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseHeader."Last Return Shipment No.", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryVariableStorage.Enqueue(UndoPurchRetOrderMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Receipt Line.
        asserterror UndoReturnShipment(PurchaseLine);

        // Verify: Verify error after undo Receipt with applied negative Quantity.
        Assert.ExpectedTestFieldError(ItemLedgerEntry.FieldCaption("Remaining Quantity"), Format(Abs(PurchaseLine.Quantity)));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,GetReturnShipmentHandler')]
    [Scope('OnPrem')]
    procedure GetRetShptLineFromPurchCrMemoAfterUndoRetShpt()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Verify Get Return Shipment Line page, not find any Return Shipment Line from Purchase Credit Memo.

        // Setup: Create Purchase Order, Post and undo Receipt.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", PurchaseLine.Type::Item, LibraryRandom.RandDec(50, 1), false);  // Use Random value.
        LibraryVariableStorage.Enqueue(UndoPurchRetOrderMessage);  // Enqueue value for ConfirmHandler.
        UndoReturnShipment(PurchaseLine);

        // Create Purchase Invoice and Get Receipt Line.
        CreatePurchaseDocument(
          PurchaseLine2, PurchaseLine2."Document Type"::"Credit Memo", PurchaseLine2.Type::Item, PurchaseLine."Buy-from Vendor No.",
          PurchaseLine."No.", PurchaseLine.Quantity);

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Return Shipments", PurchaseLine2);

        // Verify: Verify Get Return Shipment Line page, done by GetReturnShipmentLinesHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoRetShptOfReservedNegQuantity()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify Corrective Lines  Undo Purchase Return Shipment after reservation of the Item from Sales Order.

        // Setup: Create Purchase Return Order and Post, create Sale Order and reserve the Item.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", PurchaseLine.Type::Item, -LibraryRandom.RandDec(50, 1), false);  // Use Random value.
        CreateSalesDocumentAndReserve(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(UndoPurchRetOrderMessage);  // Enqueue value for ConfirmHandler.

        // Exercise.
        UndoReturnShipment(PurchaseLine);

        // Verify: Verify Corrective Purchase Return Shipment Lines.
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine);
        ReturnShipmentLine.TestField(Correction, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnUndoReservedSalesShipment()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Verify Error while Undo Reserved Sales Shipment.

        // Setup: Create and post Sales Order, Create another Sales Order and Reserved.
        Initialize();
        CreateAndShipSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, SalesLine.Type::Item, CreateItem(0, Item."Costing Method"::FIFO), -1);  // 1 used as Quantity Factor.
        CreateSalesDocumentAndReserve(SalesLine2, SalesLine."No.", Abs(SalesLine.Quantity));
        LibraryVariableStorage.Enqueue(UndoSalesShipmentMsg);  // Enqueue value for ConfirmHandler.

        // Exercise.
        asserterror UndoSalesShipment(SalesLine);

        // Verify: Verify Error while Undo Reserved Shipment.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Reserved Quantity"), '');
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnUndoShipmentOfDropShipment()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Error while Undo Sales Shipment which have Drop Shipment.

        // Setup: Create Sales Order with Drop Shipment and create Purchase Order, Get Drop Shipment and Receive.
        Initialize();
        SalesOrderUpdatedWithDropShipment(SalesLine);
        GetDropShptFromPurchaseOrder(SalesLine."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(UndoSalesShipmentMsg);

        // Exercise.
        asserterror UndoSalesShipment(SalesLine);

        // Verify: Verify Error while Undo Sales Shipment which have Drop Shipment.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Drop Shipment"), Format(false));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoShptWithWhseActivityLines()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PurchaseLine: Record "Purchase Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Verify Undo Sales Shipment Line after Warehouse Shipment, create Pick and Register.

        // Setup: Create Purhcase Warehouse Receipt and Register, create Sales Order, Warehouse Shipment, Pick and Register.
        Initialize();
        PurchaseWhseRcptAndRegister(PurchaseLine);
        CreateSalesDocumentWithLocation(
          SalesHeader, SalesHeader."Document Type"::Order, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        CreatePickAndRegisterWhseShipment(WarehouseShipmentHeader, SalesHeader."No.", SalesHeader."Location Code", true);
        FindSalesLine(SalesLine, SalesHeader);
        LibraryVariableStorage.Enqueue(UndoSalesShipmentMsg);  // Enqueue value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(UndoPickedLineMessage);  // Enqueue value for ConfirmHandler.

        // Exercise.
        UndoSalesShipment(SalesLine);

        // Verify: Verify Corrective Sales Shipment Lines.
        FindShipmentLine(SalesShipmentLine, SalesLine."No.");
        SalesShipmentLine.TestField(Correction, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure CorrectionLinesUnavailableForGetShipmentLines()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // Verify Get Shipment Lines after undo Shipment Lines.

        // Setup: Create Sales Order, Ship and undo Shipment, create Sales Invoice.
        Initialize();
        CreateAndShipSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, SalesLine.Type::Item, CreateItem(0, Item."Costing Method"::FIFO), 1);  // 1 used as Quantity Factor.
        LibraryVariableStorage.Enqueue(UndoSalesShipmentMsg);  // Enqueue value for ConfirmHandler.
        UndoSalesShipment(SalesLine);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, CreateCustomer(), SalesLine."No.", SalesLine.Quantity);  // Use Random Quantity.
        FindSalesLine(SalesLine, SalesHeader);

        // Exercise. Get Shipment Lines.
        CODEUNIT.Run(CODEUNIT::"Sales-Get Shipment", SalesLine);

        // Verify: Verify Get Shipment Lines after undo Shipment Lines, done by GetShipmentLinesHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnUndoReservedSalesRetReceipt()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Verify Error while Undo Reserved Sales Return Receipt.

        // Setup: Create and post Sales Order, Create another Sales Order and Reserved.
        Initialize();
        CreateAndShipSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", SalesLine.Type::Item, CreateItem(0, Item."Costing Method"::FIFO), 1);  // 1 used as Quantity Factor.
        CreateSalesDocumentAndReserve(SalesLine2, SalesLine."No.", Abs(SalesLine.Quantity));
        LibraryVariableStorage.Enqueue(UndoSalesRetReceiptMsg);  // Enqueue value for ConfirmHandler.

        // Exercise.
        asserterror UndoReturnReceipt(SalesLine);

        // Verify: Verify Error while Undo Reserved Shipment.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Reserved Quantity"), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,GetReturnReceiptHandler')]
    [Scope('OnPrem')]
    procedure CorrectionLinesUnavailableForGetRetRcptLines()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // Verify Get Sales Return Receipt Lines after undo Return Receipt Line.

        // Setup: Create Return Sales Order, Post and undo Return Receipt, create Sales Credit Memo.
        Initialize();
        CreateAndShipSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", SalesLine.Type::Item, CreateItem(0, Item."Costing Method"::FIFO), 1);  // 1 used as Quantity Factor.
        LibraryVariableStorage.Enqueue(UndoSalesRetReceiptMsg);  // Enqueue value for ConfirmHandler.
        UndoReturnReceipt(SalesLine);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, CreateCustomer(), SalesLine."No.", SalesLine.Quantity);  // Use Random Quantity.
        FindSalesLine(SalesLine, SalesHeader);

        // Exercise. Get Return Receipt Line.
        CODEUNIT.Run(CODEUNIT::"Sales-Get Return Receipts", SalesLine);

        // Verify: Verify Get Return Receipt Line after undo Return Receipt Line, done by GetReturnReceiptHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnReceiptWithWhseActivityLines()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify error while undo Sales Return Receipt Line after Warehouse Receipt and create Put-away.

        // Setup: Create Sales Return Order with Location, create Warehouse Receipt and Post.
        Initialize();
        CreateLocation(Location);
        CreateSalesDocumentWithLocation(
          SalesHeader, SalesHeader."Document Type"::"Return Order", CreateItem(0, Item."Costing Method"::FIFO), Location.Code,
          LibraryRandom.RandDec(50, 1));  // Use Random value.
        FindSalesLine(SalesLine, SalesHeader);
        CreateAndPostWhseRcptFromSalesReturn(SalesLine);
        LibraryVariableStorage.Enqueue(UndoSalesRetReceiptMsg);  // Enqueue value for ConfirmHandler.

        // Exercise.
        asserterror UndoReturnReceipt(SalesLine);

        // Verify: Verify error while undo Sales Return Receipt after create Put-away.
        Assert.ExpectedError(PutAwayCreatedUndoError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostForDifferentCurrencyExchangeRate()
    var
        Item: Record Item;
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // Verify Value Entries in 'Cost Amount (Expected)(ACY)' of Item Ledger Entry when transactions posted with different Currency Exchange Rates.

        // Setup: Create Currency, add Additional Reporting Currency and update Inventory Setup.
        Initialize();
        CreateCurrencyWithExchangeRate(Currency);
        ItemNo := CreateItem(LibraryRandom.RandInt(10), Item."Costing Method"::Average);  // Take random for Indirect Cost Percent.
        SetupForAdjustCostOnACY(SalesHeader, ItemNo, Currency.Code);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify:
        FindValueEntry(ValueEntry, SalesHeader."Last Posting No.", '', '', true);
        ValueEntry.TestField("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.TestField(
          "Cost Amount (Actual) (ACY)",
          Round(ValueEntry."Cost per Unit (ACY)" * ValueEntry."Valued Quantity", LibraryERM.GetAmountRoundingPrecision(), '='));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderWithDiffCurrencyExchangeRate()
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
        CreateCurrencyWithExchangeRate(Currency);
        ItemNo := CreateItem(LibraryRandom.RandInt(10), Item."Costing Method"::Average);  // Take random for Indirect Cost Percent.
        SetupForAdjustCostOnACY(SalesHeader, ItemNo, Currency.Code);

        // Create Sales Document and Post, create Purchase Document and Receive.
        LibraryVariableStorage.Enqueue(ChangeCurrCodeMessage);  // Enqueue value for ConfirmHandler.
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CreateCustomer(), ItemNo, LibraryRandom.RandInt(20));  // Use Random Quantity.
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
        FindValueEntry(ValueEntry, SalesHeader."Last Posting No.", '', '', true);
        ValueEntry.TestField("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.TestField(
          "Cost Amount (Actual) (ACY)",
          Round(ValueEntry."Cost per Unit (ACY)" * ValueEntry."Valued Quantity", LibraryERM.GetAmountRoundingPrecision(), '='));
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRatePageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAfterUpdateExchangeRate()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Item: Record Item;
    begin
        // Verify Sales Amount on Item Ledger Entry after updating Currency Exchange Rate on Sales Order.

        // Setup: Create Currency, create Sales Order and update Currency Exchange.
        Initialize();
        CreateCurrencyWithExchangeRate(Currency);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CreateAndUpdateCustomer(Currency.Code),
          CreateItem(0, Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2));
        UpdateSalesDocument(SalesLine, SalesHeader, WorkDate(), Currency.Code, LibraryRandom.RandDec(10, 2));  // Random value for Unit Price.
        UpdateCurrencyExchangeRateOnSalesOrder(CurrencyExchangeRate, Currency.Code, SalesLine."Document No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Sales Amount on Item Ledger Entry.
        VerifySalesAmountOnItemLedgerEntry(
          SalesLine."No.",
          (SalesLine."Line Amount" * CurrencyExchangeRate."Relational Exch. Rate Amount") / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRatePageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderAfterUpdateExchangeRate()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PstdPurchaseDocumentNo: Code[20];
    begin
        // Verify Cost Amount on Item Ledger Entry after updating Currency Exchange Rate on Purchase Order.

        // Setup: Create Currency, create Purchase Order and update Currency Exchange.
        Initialize();
        LibraryERM.SetWorkDate();
        CreateCurrencyWithExchangeRate(Currency);
        CreatePurchaseOrderWithCurrency(
          PurchaseLine, CreateItem(0, Item."Costing Method"::FIFO), Currency.Code, WorkDate(), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));  // Use random value for Direct Unit Cost and Quantity.
        UpdateCurrencyExchangeRateOnPurchOrder(CurrencyExchangeRate, Currency.Code, PurchaseLine."Document No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise: Post Purchase Order.
        PstdPurchaseDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Cost Amount on Item Ledger Entry.
        FindItemLedgerEntry(ItemLedgerEntry, PstdPurchaseDocumentNo, ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField(
          "Cost Amount (Actual)",
          (PurchaseLine."Line Amount" * CurrencyExchangeRate."Relational Exch. Rate Amount") /
          CurrencyExchangeRate."Exchange Rate Amount");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesForAssembledItemWithFilter()
    var
        Item: Record Item;
        Item2: Record Item;
        AssemblyItem: Record Item;
        BomComponent: Record "BOM Component";
        BomComponent2: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        // Verify Cost Amount (Actual) on Item Ledger Entry after running Adjust Cost item entries with filtering on Assembled item

        // Setup: Create Assembly Item with 2 BOM components
        Initialize();
        CreateAssemblyItemWithBOM(AssemblyItem, BomComponent, BomComponent2, AssemblyItem."Assembly Policy"::"Assemble-to-Order");

        Quantity := LibraryRandom.RandDec(10, 2); // Generate the Quantity to sell for Assembly Item
        CreateAndPostItemJournalLine(ItemJournalLine, BomComponent."No.", Quantity * BomComponent."Quantity per", ''); // Increase inventory for components
        CreateAndPostItemJournalLine(ItemJournalLine, BomComponent2."No.", Quantity * BomComponent2."Quantity per", ''); // Increase inventory for components

        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateErr, WorkDate())); // Enqueue variable for Message handler

        // Post Sales Order for Assembly Item
        CreateAndPostSalesDocument(CreateCustomer(), AssemblyItem."No.", Quantity, true, true);

        // Excercise: Adjust Cost Item Entries with filtering on the Assembly Item No.
        LibraryCosting.AdjustCostItemEntries(AssemblyItem."No.", '');

        // Verify: Verify "Cost Amount (Actual)" on Sale Entry Type Line in Item Ledger Entry
        Item.Get(BomComponent."No.");
        Item2.Get(BomComponent2."No.");

        ItemLedgerEntry.SetRange("Item No.", AssemblyItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)"); // CALCFIELDS because "Cost Amount (Actual)" is a flow field

        Assert.AreNearlyEqual(
          -Quantity * (BomComponent."Quantity per" * Item."Unit Cost" + BomComponent2."Quantity per" * Item2."Unit Cost"),
          ItemLedgerEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(), AdjustCostErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyBOMConsumeExistingInventory()
    begin
        // Verify Assembly BOM Item consume existing Inventory for Planning.
        CalcRegenPlanForPlanWksh(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReCalcRegenPlanForPlanWksh()
    begin
        // Verify Planning Worksheeet after Re-Calculate Regenerate Plan.
        CalcRegenPlanForPlanWksh(true);
    end;

    local procedure CalcRegenPlanForPlanWksh(ReCalcRegenPlan: Boolean)
    var
        AssemblyItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create Assembly BOM with Component. Create Item Journal for Assembly BOM.
        Initialize();
        CreateAssemblyItemWithBOMForPlanning(AssemblyItem, LibraryRandom.RandInt(10));
        Quantity := LibraryRandom.RandDecInRange(2, 10, 2);
        CreateAndPostItemJournalLine(ItemJournalLine, AssemblyItem."No.", Quantity, '');

        // Create Sales Order for Assembly BOM.
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateErr, WorkDate())); // Enqueue variable for Message handler.
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CreateCustomer(), AssemblyItem."No.", 3 * Quantity);

        // Update "Qty. to Assemble to Order" on Sales Line.
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateErr, WorkDate())); // Enqueue variable for Message handler.
        UpdateQtyToAssembleForSalesDocument(SalesHeader, Quantity);

        // Exercise: Calculate Regenerative Plan for Assembly BOM.
        LibraryPlanning.CalcRegenPlanForPlanWksh(AssemblyItem, WorkDate(), CalcDate('<CY>', WorkDate()));

        if ReCalcRegenPlan then begin
            FindRequisitionLine(RequisitionLine, AssemblyItem."No.");
            RequisitionLine.Delete(true);
            LibraryPlanning.CalcRegenPlanForPlanWksh(AssemblyItem, WorkDate(), CalcDate('<CY>', WorkDate()));
        end;

        // Verify: Verify Calculated Planning Lines.
        // There are 1 Quantity on Inventory, and 1 Quantity to assemble,
        // 3 Quantity demand on sales line, so there should be 3-1-1=1 Quantity for planning.
        FindRequisitionLine(RequisitionLine, AssemblyItem."No.");
        RequisitionLine.TestField(Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('BOMCostSharesPageHandler')]
    [Scope('OnPrem')]
    procedure BOMCostSharesWithMultipleAssemblyBOMLevels()
    var
        TopAssemblyItem: Record Item;
        AssemblyItem: Record Item;
        ItemNo: Code[20];
        QtyPer: Decimal;
    begin
        // Setup: Create Top Assembly BOM with Assembly Item as Component. Create Component Item for Assembly Item.
        Initialize();
        QtyPer := LibraryRandom.RandInt(10);
        ItemNo := CreateAssemblyItemWithBOMForPlanning(TopAssemblyItem, QtyPer);
        CreateBOMComponentItem(ItemNo, LibraryRandom.RandInt(10));
        AssemblyItem.Get(ItemNo);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Purchase);
        AssemblyItem.Modify(true);

        // Exercise: Run BOM Cost Shares Page for Top Assembly Item.
        // Verify: Verify Rolled-up Material Cost of the 2nd BOM which is a Purchase Item and it does not account cost from its component.
        LibraryVariableStorage.Enqueue(AssemblyItem."Unit Cost" * QtyPer);
        LibraryVariableStorage.Enqueue(AssemblyItem."No.");
        RunBOMCostSharesPage(TopAssemblyItem);
    end;

    [Test]
    [HandlerFunctions('StatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatementReportWithMultiCurrency()
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
        CustomerNo: Code[20];
    begin
        // Verify that it shows the right balance amount for multiple Currency code when date range is outside of transaction date on Customer Statement Report.

        // Setup: Create and post sales order with currency.
        CustomerNo := CreateCustomer();
        CurrencyCode := CreateAndPostSalesOrderWithCurrency(SalesLine, CustomerNo);
        CurrencyCode2 := CreateAndPostSalesOrderWithCurrency(SalesLine2, CustomerNo);
        LibraryVariableStorage.Enqueue(CustomerNo); // Enqueue value for StatementRequestPageHandler.

        // Exercise: Run Customer Statement report.
        REPORT.Run(REPORT::Statement);

        // Verify: Verify the total currency balance on the report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCustomerStatementReport(CurrencyCode, SalesLine."Amount Including VAT");
        VerifyCustomerStatementReport(CurrencyCode2, SalesLine2."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('PurchItemChargeAssignmentHandler,SalesShipmentLinePageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCostAmountForItemChargeAssignedFromPurchInv()
    var
        DocumentNo: Code[20];
    begin
        // Verify that 'Cost Amount (Non-Invtbl)' in Value Entry is negative, if cost is assigned to Sales Shipment Line from Purchase Invoice.

        // Setup
        Initialize();

        // Exercise
        DocumentNo := SalesDocumentWithItemChargeAssignment();

        // Verify
        CheckValueEntryCostAmountNonInvtblNegSign(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateAddReportingCurrBeforeRevaluation()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        RevaluedFactor: Integer;
    begin
        // Verify Cost Amount (Actual) (ACY) on Item Ledger Entry with updating Additional Reporting Currency before revaluation.

        // Setup: Create Currency with multiple Exchange Rates. Update Additional Reporting Currency on General Ledger Setup.
        Initialize();
        CreateCurrencyWithMultipleExchangeRates(Currency, CurrencyExchangeRate);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetupForACY(Currency.Code);
        RevaluedFactor := LibraryRandom.RandIntInRange(2, 5);

        // Exercise: Create and post Purchase Order as Receive and Invoice.
        // Create and post Revaluation Journal with new Unit Cost (Revalued).
        PostPurchaseOrderAndRevaluationJournal(PurchaseLine, true, RevaluedFactor, Currency.Code);

        // Verify: Verify Cost Amount (Actual) (ACY) on Item Ledger Entry with updating Additional Reporting Currency before revaluation.
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");
        VerifyCostAmountActualACYOnItemLedgerEntry(
          PurchRcptLine."Document No.", CalculateRevaluedCostAmount(PurchaseLine, CurrencyExchangeRate, RevaluedFactor),
          Currency."Amount Rounding Precision");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateAddReportingCurrAfterRevaluation()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        UnitCostRevaluated: Decimal;
        RevaluedFactor: Integer;
    begin
        // Verify Cost Amount (Actual) (ACY) on Item Ledger Entry, Cost per Unit (ACY) and Cost Posted to G/L (ACY) on Value Entry
        // with updating Additional Reporting Currency after revaluation.

        // Setup: Update Automatic Cost Posting on Inventory Setup. Create Currency with multiple Exchange Rates.
        // Create and post Purchase Order as Receive and Invoice. Run Adjust Cost Item Entries.
        // Create and post Revaluation Journal with new Unit Cost (Revalued).
        Initialize();

        LibraryInventory.SetAutomaticCostPosting(true);

        CreateCurrencyWithMultipleExchangeRates(Currency, CurrencyExchangeRate);
        RevaluedFactor := LibraryRandom.RandIntInRange(2, 5);
        UnitCostRevaluated :=
          PostPurchaseOrderAndRevaluationJournal(PurchaseLine, true, RevaluedFactor, Currency.Code);

        // Exercise: Run Adjust Add. Reporting Currency.
        LibraryERM.RunAddnlReportingCurrency(Currency.Code, Currency.Code, Currency."Residual Gains Account");

        // Verify: Verify Cost Amount (Actual) (ACY) on Item Ledger Entry. Verify Cost per Unit (ACY) and Cost Posted to G/L (ACY) on Value Entry.
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");
        VerifyCostAmountActualACYOnItemLedgerEntry(
          PurchRcptLine."Document No.", CalculateRevaluedCostAmount(PurchaseLine, CurrencyExchangeRate, RevaluedFactor),
          Currency."Amount Rounding Precision");
        VerifyAmountsInACYOnValueEntry(
          PurchaseLine."No.", UnitCostRevaluated * CurrencyExchangeRate."Exchange Rate Amount" /
          CurrencyExchangeRate."Relational Exch. Rate Amount", Currency."Amount Rounding Precision",
          UnitCostRevaluated * PurchaseLine.Quantity * CurrencyExchangeRate."Exchange Rate Amount" /
          CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateAddReportingCurrAfterRevaluationWithPostReceiveOnPurchOrd()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        RevaluedFactor: Integer;
    begin
        // Verify Cost Amount (Expected) (ACY) on Item Ledger Entry with updating Additional Reporting Currency after revaluation.

        // Setup: Create Currency with multiple Exchange Rates. Create and post Purchase Order as Receive.
        // Run Adjust Cost Item Entries. Create and post Revaluation Journal with new Unit Cost (Revalued).
        Initialize();
        CreateCurrencyWithMultipleExchangeRates(Currency, CurrencyExchangeRate);
        RevaluedFactor := LibraryRandom.RandIntInRange(2, 5);
        PostPurchaseOrderAndRevaluationJournal(PurchaseLine, false, RevaluedFactor, Currency.Code);

        // Exercise: Run Adjust Add. Reporting Currency.
        LibraryERM.RunAddnlReportingCurrency(Currency.Code, Currency.Code, Currency."Residual Gains Account");

        // Verify: Verify Cost Amount (Actual) (ACY) on Item Ledger Entry with updating Additional Reporting Currency before revaluation.
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");
        VerifyCostAmountExpectedACYOnItemLedgerEntry(
          PurchRcptLine."Document No.", CalculateRevaluedCostAmount(PurchaseLine, CurrencyExchangeRate, RevaluedFactor),
          Currency."Amount Rounding Precision");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenBOMCostSharesPageWhenFirstInFilterItemHasNoBOMButOthersHave()
    var
        NoBOMItem: Record Item;
        BOMItem: Record Item;
        BOMCostShares: TestPage "BOM Cost Shares";
        ItemFilter: Text;
        ItemFilterHead: Code[10];
        NoBOMItemNo: Code[20];
        BOMItemNo: Code[20];
        ReadItemNo: Code[20];
    begin
        // [FEATURE] [BOM Cost Shares]
        // [SCENARIO 380466] If first Item in filter doesn't contain BOM the ERROR "None of the items in the filter have a BOM" must not occur.
        Initialize();

        // [GIVEN] Two Items, First without BOM, second with BOM. Their primary key values: First - ABCDE, Second - ABC.
        ItemFilterHead := LibraryUtility.GenerateRandomCode(BOMItem.FieldNo("No."), DATABASE::Item);
        NoBOMItemNo := ItemFilterHead;
        BOMItemNo := ItemFilterHead + LibraryUtility.GenerateRandomCode(BOMItem.FieldNo("No."), DATABASE::Item);

        // [GIVEN] Item Filter in BOM Cost Shares Page is ABC*
        ItemFilter := ItemFilterHead + '*';

        CreateNamedItem(NoBOMItem, NoBOMItemNo);
        CreateNamedProductionBOMItem(BOMItem, BOMItemNo);

        BOMCostShares.OpenView();

        // [WHEN] Set Value of Item Filter in BOM Cost Shares Page
        BOMCostShares.ItemFilter.SetValue(ItemFilter);

        // [THEN] No ERROR occurs.

        ReadItemNo := BOMCostShares."No.".Value();
        BOMCostShares.Close();

        // [THEN] Read Item."No." from BOM Cost Shares Page is equal to Second Item."No."
        Assert.AreEqual(BOMItemNo, ReadItemNo, ItemNoIsUnexpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMCostSharesDoesNotIncludeOverdueComponents()
    var
        ParentItem: Record Item;
        ComponentItem: array[3] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        ReportDate: Date;
    begin
        // [FEATURE] [Cost Shares] [Production] [Production BOM]
        // [SCENARIO 219053] Overdue BOM components should not be included in the "BOM Cost Shares" report

        Initialize();

        // [GIVEN] Manufactured item "P" and 3 components: "C1", "C2", "C3"
        LibraryInventory.CreateItem(ComponentItem[1]);
        LibraryInventory.CreateItem(ComponentItem[2]);
        LibraryInventory.CreateItem(ComponentItem[3]);
        LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Modify(true);

        // [GIVEN] Production BOM with 3 lines.
        // [GIVEN] Line 1 for component item "C1" has no ending date
        // [GIVEN] Line 2 for component item "C2", ending date is 24.01.2019
        // [GIVEN] Line 3 for component item "C3", ending date is 23.01.2019
        ReportDate := LibraryRandom.RandDate(10);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        CreateProdBOMLineWithStartingEndingDates(ProductionBOMHeader, ComponentItem[1]."No.", LibraryRandom.RandInt(100), 0D, 0D);
        CreateProdBOMLineWithStartingEndingDates(ProductionBOMHeader, ComponentItem[2]."No.", LibraryRandom.RandInt(100), 0D, ReportDate);
        CreateProdBOMLineWithStartingEndingDates(
          ProductionBOMHeader, ComponentItem[3]."No.", LibraryRandom.RandInt(100), 0D, ReportDate - 1);

        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Assign the production BOM to the parent item "P"
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);

        // [WHEN] Calculate BOM cost shares for item "P" on 24.01.2019
        CalculateBOMTree.GenerateTreeForOneItem(ParentItem, TempBOMBuffer, ReportDate, "BOM Tree Type"::Availability);

        // [THEN] Component "C1" is included in the report
        TempBOMBuffer.SetRange(Type, TempBOMBuffer.Type::Item);
        TempBOMBuffer.SetRange("No.", ComponentItem[1]."No.");
        Assert.RecordIsNotEmpty(TempBOMBuffer);

        // [THEN] Component "C2" is included in the report
        TempBOMBuffer.SetRange("No.", ComponentItem[2]."No.");
        Assert.RecordIsNotEmpty(TempBOMBuffer);

        // [THEN] Component "C3" is not included in the report
        TempBOMBuffer.SetRange("No.", ComponentItem[3]."No.");
        Assert.RecordIsEmpty(TempBOMBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMCostSharesPageConsidersStartingEndingDatesOfComponent()
    var
        Item: array[5] of Record Item;
        BOMCostShares: TestPage "BOM Cost Shares";
    begin
        // [FEATURE] [Cost Shares] [Production] [Production BOM]
        // [SCENARIO 225032] Page "BOM Cost Shares" should consider starting and ending dates of production BOM components

        Initialize();

        // [GIVEN] Workdate is 24.01.2019
        // [GIVEN] Manufactured item "P" and 4 components: "C1", "C2", "C3", "C4"
        // [GIVEN] Production BOM with 4 lines.
        // [GIVEN] Line 1 for component item "C1" has neither starting, nor ending date
        // [GIVEN] Line 2 for component item "C2", starting date is undefined,  ending date is 23.01.2019
        // [GIVEN] Line 3 for component item "C3", starting date is 25.01.2019, ending date is undefined
        // [GIVEN] Line 4 for component item "C4", starting date is 23.01.2019, ending date is 25.01.2019
        // [GIVEN] Assign the production BOM to the parent item "P"
        CreateProdItemWithComponents(Item);

        // [GIVEN] Open "BOM Cost Shares" page for the top-level item "P"
        BOMCostShares.OpenEdit();
        BOMCostShares.ItemFilter.SetValue(Item[5]."No.");

        // [THEN] Items "C1" and "C4" are in the report, items "C2" and "C3" are not shown in the report
        BOMCostShares.First();
        BOMCostShares.Expand(true);
        BOMCostShares.Next();
        BOMCostShares."No.".AssertEquals(Item[1]."No.");
        BOMCostShares.Next();
        BOMCostShares."No.".AssertEquals(Item[4]."No.");
        Assert.IsFalse(BOMCostShares.Next(), ItemNoIsUnexpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMStructurePageConsidersStartingEndingDatesOfComponent()
    var
        Item: array[5] of Record Item;
        BOMStructure: TestPage "BOM Structure";
    begin
        // [FEATURE] [BOM Structure] [Production] [Production BOM]
        // [SCENARIO 225032] Page "BOM Structure" should consider starting and ending dates of production BOM components

        Initialize();

        // [GIVEN] Workdate is 24.01.2019
        // [GIVEN] Manufactured item "P" and 4 components: "C1", "C2", "C3", "C4"
        // [GIVEN] Production BOM with 3 lines.
        // [GIVEN] Line 1 for component item "C1" has neither starting, nor ending date
        // [GIVEN] Line 2 for component item "C2", starting date is undefined,  ending date is 23.01.2019
        // [GIVEN] Line 3 for component item "C3", starting date is 25.01.2019, ending date is undefined
        // [GIVEN] Line 4 for component item "C4", starting date is 23.01.2019, ending date is 25.01.2019
        // [GIVEN] Assign the production BOM to the parent item "P"
        CreateProdItemWithComponents(Item);

        // [GIVEN] Open "BOM Structure" page for the top-level item "P"
        BOMStructure.OpenEdit();
        BOMStructure.ItemFilter.SetValue(Item[5]."No.");

        // [THEN] Items "C1" and "C4" are in the report, items "C2" and "C3" are not shown in the report
        BOMStructure.First();
        BOMStructure.Expand(true);
        BOMStructure.Next();
        BOMStructure."No.".AssertEquals(Item[1]."No.");
        BOMStructure.Next();
        BOMStructure."No.".AssertEquals(Item[4]."No.");
        Assert.IsFalse(BOMStructure.Next(), ItemNoIsUnexpectedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchRcptWithServiceItem()
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Adjust Cost] [Service] [Undo Receipt]
        // [SCENARIO 316002] Undo Receipt for a Service Item doesn't populate "Avg. Cost Adjmt. Entry Point"
        Initialize();

        // [GIVEN] Created and posted Purchase Order with Service Item
        CreateServiceItem(Item, LibraryRandom.RandDec(10, 1), Item."Costing Method"::FIFO);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, CreateVendor(), Item."No.", LibraryRandom.RandInt(10));
        PostPurchaseDocument(PurchaseLine, false);

        // [WHEN] Undo Purchase Receipt
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue for ConfirmMessageHandler
        UndoPurchaseReceiptLines(PurchaseLine);

        // [THEN] Table "Avg. Cost Adjmt. Entry Point" is empty
        AvgCostAdjmtEntryPoint.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(AvgCostAdjmtEntryPoint);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Costing IV");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing IV");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SavePurchasesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing IV");
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ProductionOrderNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProductionOrderNo);
        CODEUNIT.Run(CODEUNIT::"Output Jnl.-Expl. Route", ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; Quantity: Decimal; Invoice: Boolean)
    var
        Item: Record Item;
    begin
        CreatePurchaseDocument(
          PurchaseLine, DocumentType, Type, CreateVendor(), CreateItem(LibraryRandom.RandDec(10, 1), Item."Costing Method"::FIFO),
          Quantity);
        PostPurchaseDocument(PurchaseLine, Invoice);
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

    local procedure CreateAndPostSalesOrderWithCurrency(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]): Code[10]
    var
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
    begin
        // Create Sales Header with currency.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateCurrencyWithExchangeRate(Currency);
        UpdateSalesHeader(SalesHeader, Currency.Code);

        // Create Sales Line with G/L Account and random quantity and unit price.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(), LibraryRandom.RandInt(100));
        UpdateSalesLine(SalesLine, LibraryRandom.RandInt(100));

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(Currency.Code);
    end;

    local procedure CreateAndPostSalesDocument(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Ship: Boolean; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CustomerNo, ItemNo, Quantity);
        exit(LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice));
    end;

    local procedure CreateAndPostRevaluationJournal(ItemNo: Code[20]; NewPostingDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; RevalueFactor: Integer): Decimal
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        Item.SetRange("No.", ItemNo);
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, NewPostingDate, LibraryUtility.GenerateGUID(), CalculatePer, false, false, false, "Inventory Value Calc. Base"::" ", false);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", RevalueFactor * ItemJournalLine."Unit Cost (Calculated)");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        exit(ItemJournalLine."Unit Cost (Revalued)" - ItemJournalLine."Unit Cost (Calculated)");
    end;

    local procedure CreateAndPostWarehouseReceiptFromPO(PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateAndPostWhseRcptFromSalesReturn(SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, SalesHeader."No.", WarehouseReceiptLine."Source Document"::"Sales Return Order");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, SourceNo,
          LibraryRandom.RandDec(10, 2));  // Use Random Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndShipSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; QuantityFactor: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesHeader, DocumentType, Type, CreateCustomer(), ItemNo, (LibraryRandom.RandDec(10, 2) * QuantityFactor));  // Use Random Quantity.
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndUpdatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; DirectUnitCost: Decimal; Quantity: Decimal; QtyToReceive: Decimal; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        CreatePurchaseDocument(PurchaseLine, DocumentType, Type, CreateVendor(), ItemNo, Quantity);
        UpdatePurchaseLine(PurchaseLine, DirectUnitCost, QtyToReceive, LocationCode);
    end;

    local procedure CreateAndUpdateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
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

    local procedure CreateCurrencyWithExchangeRate1(var Currency: Record Currency; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandInt(100));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCurrencyWithMultipleExchangeRates(var Currency: Record Currency; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        CreateCurrencyWithExchangeRate1(Currency, CurrencyExchangeRate);

        // Make sure report Adjust Add. Reporting Currency can be run successfully. Since there're some demo entries posted in earlier years.
        CreateExchangeRateForCurrency(
          Currency.Code, CalcDate('<-' + Format(LibraryRandom.RandIntInRange(20, 25)) + 'Y>', WorkDate()));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(IndirectCostPct: Decimal; CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Validate("Unit Cost", Item."Unit Price");
        Item.Validate("Indirect Cost %", IndirectCostPct);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateServiceItem(var Item: Record Item; IndirectCostPct: Decimal; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Validate("Unit Cost", Item."Unit Price");
        Item.Validate("Indirect Cost %", IndirectCostPct);
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
        CreateWarehouseEmployee(Location.Code);
    end;

    local procedure CreatePickAndRegisterWhseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; DocumentNo: Code[20]; LocationCode: Code[10]; Sales: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        if Sales then
            CreateWarehouseShipmentFromSO(DocumentNo)
        else
            CreateWarehouseShipment(DocumentNo);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(DocumentNo, WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreateProdItemWithComponents(var Item: array[5] of Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        I: Integer;
    begin
        for I := 1 to 5 do
            LibraryInventory.CreateItem(Item[I]);

        Item[5].Validate("Replenishment System", Item[4]."Replenishment System"::"Prod. Order");
        Item[5].Modify(true);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[5]."Base Unit of Measure");
        CreateProdBOMLineWithStartingEndingDates(ProductionBOMHeader, Item[1]."No.", LibraryRandom.RandInt(100), 0D, 0D);
        CreateProdBOMLineWithStartingEndingDates(ProductionBOMHeader, Item[2]."No.", LibraryRandom.RandInt(100), 0D, WorkDate() - 1);
        CreateProdBOMLineWithStartingEndingDates(ProductionBOMHeader, Item[3]."No.", LibraryRandom.RandInt(100), WorkDate() + 1, 0D);
        CreateProdBOMLineWithStartingEndingDates(
          ProductionBOMHeader, Item[4]."No.", LibraryRandom.RandInt(100), WorkDate() - 1, WorkDate() + 1);

        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        Item[5].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[5].Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; BuyFromVendorNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        UpdatePurchaseHeader(PurchaseHeader);  // Update Vendor Invoice and Vendor Credit Memo No.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
    end;

    local procedure CreatePurchaseDocumentWithWhseLocation(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        Location: Record Location;
    begin
        CreateLocation(Location);
        CreatePurchaseDocument(
          PurchaseLine, DocumentType, PurchaseLine.Type::Item, CreateVendor(),
          CreateItem(LibraryRandom.RandDec(100, 1), Item."Costing Method"::FIFO), LibraryRandom.RandDec(50, 1));  // Use Random value.
        UpdatePurchaseLine(PurchaseLine, 0, 0, Location.Code);  // Used 0 for Direct Unit Cost and Quantity to Receive.
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; SellToCustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SellToCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
    end;

    local procedure CreateSalesDocumentAndReserve(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CreateCustomer(), ItemNo, Quantity);
        FindSalesLine(SalesLine, SalesHeader);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure CreateSalesDocumentWithLocation(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryVariableStorage.Enqueue(ChangeLocationMessage);  // Enqueue ConfirmHandler.
        CreateSalesDocument(SalesHeader, DocumentType, SalesLine.Type::Item, CreateCustomer(), ItemNo, Quantity);  // Use Random value.
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        UpdateLocationCodeOnSalesLine(SalesHeader, LocationCode);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        InTransitLocation: Record Location;
        ToLocation: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity)
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
    end;

    local procedure CreateWarehouseEmployee(LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, true);
    end;

    local procedure CreateWarehouseLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Location.Validate("Always Create Pick Line", true);
        Location.Modify(true);
        CreateWarehouseEmployee(Location.Code)
    end;

    local procedure CreateWarehouseShipment(DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", DocumentNo);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
    end;

    local procedure CreateWarehouseShipmentFromSO(DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateAssemblyBomComponent(var BomComponent: Record "BOM Component"; ParentItemNo: Code[20])
    var
        Item: Record Item;
        RecRef: RecordRef;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        BomComponent.Init();
        BomComponent.Validate("Parent Item No.", ParentItemNo);
        RecRef.GetTable(BomComponent);
        BomComponent.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, BomComponent.FieldNo("Line No.")));
        BomComponent.Validate(Type, BomComponent.Type::Item);
        BomComponent.Validate("No.", Item."No.");
        BomComponent.Validate("Quantity per", LibraryRandom.RandInt(10));
        BomComponent.Insert(true);
    end;

    local procedure CreateAssemblyItemWithBOM(var AssemblyItem: Record Item; var BomComponent: Record "BOM Component"; var BomComponent2: Record "BOM Component"; AssemblyPolicy: Enum "Assembly Policy")
    begin
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Assembly Policy", AssemblyPolicy);
        AssemblyItem.Modify(true);

        // Create Component Item and set as Assembly BOM
        CreateAssemblyBomComponent(BomComponent, AssemblyItem."No.");
        CreateAssemblyBomComponent(BomComponent2, AssemblyItem."No.");
        Commit(); // Save the BOM Component record created above
    end;

    local procedure CreateAssemblyItemWithBOMForPlanning(var AssemblyItem: Record Item; QtyPer: Decimal) ItemNo: Code[20]
    begin
        LibraryInventory.CreateItem(AssemblyItem);
        UpdateItemParametersForPlanning(
          AssemblyItem, AssemblyItem."Replenishment System"::Assembly, AssemblyItem."Reordering Policy"::"Lot-for-Lot", true);
        ItemNo := CreateBOMComponentItem(AssemblyItem."No.", QtyPer);
    end;

    local procedure CreateBOMComponentItem(AssemblyItemNo: Code[20]; QtyPer: Decimal): Code[20]
    var
        ComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(ComponentItem);
        UpdateItemParametersForPlanning(
          ComponentItem, ComponentItem."Replenishment System"::Purchase, ComponentItem."Reordering Policy"::"Lot-for-Lot", false);
        LibraryInventory.CreateBOMComponent(BOMComponent, AssemblyItemNo, BOMComponent.Type::Item, ComponentItem."No.", QtyPer, '');
        exit(ComponentItem."No.");
    end;

    local procedure CreateExchangeRateForCurrency(CurrencyCode: Code[10]; StartingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateProdBOMLineWithStartingEndingDates(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; Qty: Decimal; StartingDate: Date; EndingDate: Date)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, Qty);
        ProductionBOMLine.Validate("Starting Date", StartingDate);
        ProductionBOMLine.Validate("Ending Date", EndingDate);
        ProductionBOMLine.Modify(true);
    end;

    local procedure CalculateRevaluedCostAmount(var PurchaseLine: Record "Purchase Line"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; RevaluedFactor: Integer): Decimal
    begin
        exit(PurchaseLine."Direct Unit Cost" * RevaluedFactor * PurchaseLine.Quantity *
          CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure AssignItemChargeToSalesShptLines(var PurchaseLine: Record "Purchase Line"; PurchaseDocumentType: Enum "Purchase Document Type"; SalesDocumentNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(SalesDocumentNo); // Enqueue value for SalesShipmentLinePageHandler.
        LibraryVariableStorage.Enqueue(2); // Select Amount when suggest item charge.

        PurchaseDocumentItemChargeAssignByGetSalesShipmentLines(PurchaseLine, PurchaseDocumentType, CreateVendor());
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; DocumentNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindPurchasingCode(): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        Purchasing.SetRange("Drop Shipment", true);
        Purchasing.FindFirst();
        exit(Purchasing.Code);
    end;

    local procedure FindReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; No: Code[20])
    begin
        PurchRcptLine.SetRange("No.", No);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line")
    begin
        ReturnReceiptLine.SetRange("Return Order No.", SalesLine."Document No.");
        ReturnReceiptLine.SetRange("No.", SalesLine."No.");
        ReturnReceiptLine.FindFirst();
    end;

    local procedure FindReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line")
    begin
        ReturnShipmentLine.SetRange("No.", PurchaseLine."No.");
        ReturnShipmentLine.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; No: Code[20])
    begin
        SalesShipmentLine.SetRange("No.", No);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindTransferReceiptHeader(TransferFromCode: Code[10]; TransferToCode: Code[10]): Code[20]
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        TransferReceiptHeader.SetRange("Transfer-from Code", TransferFromCode);
        TransferReceiptHeader.SetRange("Transfer-to Code", TransferToCode);
        TransferReceiptHeader.FindFirst();
        exit(TransferReceiptHeader."No.");
    end;

    local procedure FindTransferShipmentHeader(TransferFromCode: Code[10]; TransferToCode: Code[10]): Code[20]
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        TransferShipmentHeader.SetRange("Transfer-from Code", TransferFromCode);
        TransferShipmentHeader.SetRange("Transfer-to Code", TransferToCode);
        TransferShipmentHeader.FindFirst();
        exit(TransferShipmentHeader."No.");
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; DocumentNo: Code[20]; ItemChargeNo: Code[20]; LocationCode: Code[10]; Adjustment: Boolean)
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        ValueEntry.SetRange(Adjustment, Adjustment);
        ValueEntry.SetRange("Location Code", LocationCode);
        ValueEntry.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
    end;

    local procedure GetDropShptFromPurchaseOrder(SelltoCustomerNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        PurchaseHeader.Validate("Sell-to Customer No.", SelltoCustomerNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.GetDropShipment(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure ModifyQtyToInvoiceOnSalesLine(SalesHeader: Record "Sales Header"; QtyToInvoice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure PostPurchaseDocument(PurchaseLine: Record "Purchase Line"; Invoice: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));
    end;

    local procedure PostPurchaseOrderAndRevaluationJournal(var PurchaseLine: Record "Purchase Line"; Invoice: Boolean; RevaluedFactor: Integer; CurrencyCode: Code[10]) UnitCostRevaluated: Decimal
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Create and post Purchase Order.
        Item.Get(CreateItem(0, Item."Costing Method"::Standard)); // Use 0 for Indirect Cost Pct.
        Quantity := LibraryRandom.RandInt(10);
        CreateAndUpdatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, Item."Unit Cost", Quantity, Quantity, Item."No.", '');
        PostPurchDocWithUpdatePostingDate(PurchaseHeader, PurchaseLine, true, Invoice);
        CreateExchangeRateForCurrency(
          CurrencyCode, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', PurchaseHeader."Posting Date"));

        // Run Adjust Cost Item Entries. Create and post Revaluation Journal with new Unit Cost (Revalued).
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');
        UnitCostRevaluated := CreateAndPostRevaluationJournal(
            PurchaseLine."No.", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', PurchaseHeader."Posting Date"),
            "Inventory Value Calc. Per"::Item, RevaluedFactor);
    end;

    local procedure PurchaseApplication(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Purchase Document and Post.
        CreateAndPostPurchaseDocument(PurchaseLine, DocumentType, PurchaseLine.Type::Item, Quantity, false);

        // Create Sales Order and Ship and Invoice Sales Order.
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, PurchaseLine.Type::Item, CreateCustomer(), PurchaseLine."No.",
          Abs(PurchaseLine.Quantity));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PurchaseDocumentWithItemChargeAssignment(var PurchaseLine: Record "Purchase Line"; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Create Purchase Order, Post.
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, LibraryRandom.RandDec(50, 1), false);  // Use Random value.

        // Create Purchase Invoice for Item Charge without Currency and assign to previous posted Receipt.
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");
        PurchaseInvoiceItemChargeAssign(
          PurchaseLine2, PurchaseLine."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.",
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt, PurchRcptLine."Document No.", PurchRcptLine."No.", '');  // Use blank for Currency Code.
        if Invoice then begin
            PurchaseHeader.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        end;
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue value for ConfirmHandler.
    end;

    local procedure PurchaseInvoiceItemChargeAssign(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; AppliestoDocType: Enum "Purchase Applies-to Document Type"; DocumentNo: Code[20]; ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);  // 1 for Charge Item Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random value.
        PurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, AppliestoDocType, DocumentNo, PurchaseLine."Line No.", ItemNo);
    end;

    local procedure PurchaseDocumentItemChargeAssignByGetSalesShipmentLines(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2)); // Use Random value.
        PurchaseLine.Modify(true);
        PurchaseLine.ShowItemChargeAssgnt(); // Trigger the PurchItemChargeAssignmentHandler.
    end;

    local procedure PurchaseReturnWithItemChargeAssignment(var PurchaseLine: Record "Purchase Line"; CrMemo: Boolean)
    var
        PurchaseLine2: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Create Purchase Return Order and Post.
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", PurchaseLine.Type::Item, LibraryRandom.RandDec(50, 1), false);  // Use Random value.

        // Create Purchase Credit Memo for Item Charge without Currency and assign to previous posted Receipt.
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine);
        PurchaseInvoiceItemChargeAssign(
          PurchaseLine2, PurchaseLine."Document Type"::"Credit Memo", ReturnShipmentLine."Buy-from Vendor No.",
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Shipment", ReturnShipmentLine."Document No.",
          ReturnShipmentLine."No.", '');
        if CrMemo then begin
            PurchaseHeader.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");
            UpdatePurchaseHeader(PurchaseHeader);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        end;
        LibraryVariableStorage.Enqueue(UndoPurchRetOrderMessage);  // Enqueue value for ConfirmHandler.
    end;

    local procedure PurchaseWhseRcptAndRegister(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Create Purchase Order with Warehouse Location.
        CreateWarehouseLocation(Location);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, CreateVendor(),
          CreateItem(LibraryRandom.RandDec(100, 1), Item."Costing Method"::FIFO), LibraryRandom.RandDec(50, 1));  // Use Random value.
        UpdatePurchaseLine(PurchaseLine, 0, 0, Location.Code);

        // Create Warehouse Receipt and Register.
        CreateAndPostWarehouseReceiptFromPO(PurchaseLine);
        RegisterWarehouseActivity(PurchaseLine."Document No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RevaluateInventoryAndRunAdjustCostItemEntries(ItemNo: Code[20]; CalculatePer: Enum "Inventory Value Calc. Per") CostAmountActual: Decimal
    var
        Customer: Record Customer;
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        UnitCostRevaluated: Decimal;
        Quantity: Decimal;
    begin
        // Create Item and Post Purchase Order.
        Quantity := LibraryRandom.RandDec(100, 2);  // Use Random value.
        CreateAndUpdatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item, LibraryRandom.RandDec(100, 2), Quantity,
          Quantity, ItemNo, '');  // Blank value for Location and Random for Direct Unit Cost.
        PostPurchaseDocument(PurchaseLine, true);

        // Invoice partial Sales Order.
        Customer.Get(CreateCustomer());
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, PurchaseLine.Type::Item, Customer."No.", ItemNo, PurchaseLine.Quantity / 2);
        ModifyQtyToInvoiceOnSalesLine(SalesHeader, PurchaseLine.Quantity / 3);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Calculate Inventory and post Revaluation Journal.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        UnitCostRevaluated := CreateAndPostRevaluationJournal(ItemNo, WorkDate(), CalculatePer, LibraryRandom.RandIntInRange(2, 5));
        CostAmountActual := Round((PurchaseLine.Quantity / 2) * UnitCostRevaluated);

        // Create and Post another Sales Order. Invoice the remaining Quantity of first Sales Order.
        CreateAndPostSalesDocument(Customer."No.", ItemNo, PurchaseLine.Quantity / 2, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Run Adjust Cost - Item Entries.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
    end;

    local procedure RunBOMCostSharesPage(var Item: Record Item)
    var
        BOMCostShares: Page "BOM Cost Shares";
    begin
        BOMCostShares.InitItem(Item);
        BOMCostShares.Run();
    end;

    local procedure SalesOrderUpdatedWithDropShipment(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CreateCustomer(), CreateItem(0, Item."Costing Method"::FIFO),
          LibraryRandom.RandDec(50, 1));
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Validate("Purchasing Code", FindPurchasingCode());
        SalesLine.Modify(true);
    end;

    local procedure SalesDocumentWithItemChargeAssignment(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        DocumentNo := CreateAndPostSalesDocument(
            CreateCustomer(), CreateItem(0, Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2), true, false);

        AssignItemChargeToSalesShptLines(PurchaseLine, PurchaseLine."Document Type"::Invoice, DocumentNo);
        exit(PostPurchDocWithUpdatePostingDate(PurchaseHeader, PurchaseLine, false, true));
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetupForAdjustCostOnACY(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        UnitPrice: Decimal;
    begin
        // Create Item Journal and Post, create Purchase Order and Receive.
        UpdateGeneralLedgerSetupForACY(CurrencyCode);
        LibraryInventory.SetAutomaticCostPosting(true);
        CreateAndPostItemJournalLine(ItemJournalLine, ItemNo, LibraryRandom.RandInt(10) + 10, '');
        CreatePurchaseOrderWithCurrency(
          PurchaseLine, ItemNo, CurrencyCode, CalcDate('<1M + ' + Format(LibraryRandom.RandInt(3)) + 'D>', WorkDate()),
          LibraryRandom.RandInt(50), ItemJournalLine.Quantity + LibraryRandom.RandInt(40));
        // Use random value for Direct Unit Cost.
        PostPurchaseDocument(PurchaseLine, true);

        // Create Sales Order and Ship, Purchase Order Invoiced.
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CreateCustomer(), ItemNo, PurchaseLine.Quantity);  // Use Random Quantity.
        UnitPrice := PurchaseLine."Direct Unit Cost" + LibraryRandom.RandInt(50); // Required Unit Price more than Direct Unti Cost.
        LibraryVariableStorage.Enqueue(ChangeCurrCodeMessage);
        UpdateSalesDocument(
          SalesLine, SalesHeader, CalcDate('<1M + ' + Format(LibraryRandom.RandInt(3)) + 'D>', WorkDate()), CurrencyCode, UnitPrice);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Undo Sale Shipment, update blank Currency in Sales Order and Post.
        LibraryVariableStorage.Enqueue(UndoSalesShipmentMsg);  // Enqueue value for ConfirmHandler.
        UndoSalesShipment(SalesLine);
        UpdateSalesDocument(SalesLine, SalesHeader, CalcDate('<1D>', SalesHeader."Posting Date"), '', UnitPrice);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create Credit Memo without Currency Code and Post.
        LibraryVariableStorage.Enqueue(ChangePostingDateMessage);
        CreateSalesDocument(
          SalesHeader2, SalesHeader2."Document Type"::"Credit Memo", SalesLine.Type::Item, CreateCustomer(), ItemNo, SalesLine.Quantity);  // Use Random Quantity.
        UpdateSalesDocument(SalesLine, SalesHeader2, CalcDate('<1D>', SalesHeader."Posting Date"), '', UnitPrice);
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);
    end;

    local procedure UndoPurchaseReceiptLines(PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure UndoReturnShipment(PurchaseLine: Record "Purchase Line")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine);
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);
    end;

    local procedure UndoReturnReceipt(SalesLine: Record "Sales Line")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine);
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);
    end;

    local procedure UndoSalesShipment(SalesLine: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        FindShipmentLine(SalesShipmentLine, SalesLine."No.");
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateGeneralLedgerSetupForACY(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate."Relational Exch. Rate Amount" :=
          CurrencyExchangeRate."Exchange Rate Amount" * LibraryRandom.RandInt(10);  // Use random value for update Relational Exchange Rate Amount.
        LibraryVariableStorage.Enqueue(CurrencyExchangeRate."Relational Exch. Rate Amount");  // Enqueue for ChangeExchangeRatePageHandler.
    end;

    local procedure UpdateCurrencyExchangeRateOnSalesOrder(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        UpdateCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode);
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder."Currency Code".AssistEdit();
    end;

    local procedure UpdateCurrencyExchangeRateOnPurchOrder(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        UpdateCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder."Currency Code".AssistEdit();
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal; QtyToReceive: Decimal; LocationCode: Code[10])
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateLocationCodeOnSalesLine(SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyToAssembleForSalesDocument(SalesHeader: Record "Sales Header"; QtyToAssemble: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Qty. to Assemble to Order", QtyToAssemble);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesDocument(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; PostingDate: Date; CurrencyCode: Code[10]; UnitPrice: Decimal)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure UpdateItemParametersForPlanning(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; IncludeInventory: Boolean)
    begin
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(10));
        Item.Modify(true);
    end;

    local procedure UpdateSalesHeader(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10])
    begin
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesLine(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateNamedItem(var Item: Record Item; ItemNo: Code[20])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Item."No." := ItemNo;
        Item.Insert(true);

        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", '', 1);
        Item.Validate(Description, Item."No.");  // Validation Description as No. because value is not important.
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);

        Item.Modify(true);
    end;

    local procedure CreateNamedProductionBOMItem(var Item: Record Item; ItemNo: Code[20])
    var
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateNamedItem(Item, ItemNo);
        LibraryInventory.CreateItem(ChildItem);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", 1);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure PostPurchDocWithUpdatePostingDate(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; ToShipReceive: Boolean; ToInvoice: Boolean): Code[20]
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        if LibraryUtility.GetNextNoSeriesPurchaseDate(PurchaseHeader."Posting No. Series") > WorkDate() then begin
            PurchaseHeader.Validate("Posting Date", CalcDate('<-1D>', LibraryUtility.GetNextNoSeriesPurchaseDate(PurchaseHeader."Posting No. Series")));
            PurchaseHeader.Modify(true);
        end;
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToShipReceive, ToInvoice));
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; Quantity: Decimal; CostAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, DocumentNo, ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifySalesAmountOnItemLedgerEntry(ItemNo: Code[20]; SalesAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)");
        ItemLedgerEntry.TestField("Sales Amount (Actual)", SalesAmount);
    end;

    local procedure VerifyCostAmountActualACYOnItemLedgerEntry(DocumentNo: Code[20]; CostAmountActualACY: Decimal; Delta: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, DocumentNo, ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual) (ACY)");
        Assert.AreNearlyEqual(
          CostAmountActualACY, ItemLedgerEntry."Cost Amount (Actual) (ACY)", Delta, CostAmountActualACYErr);
    end;

    local procedure VerifyCostAmountExpectedACYOnItemLedgerEntry(DocumentNo: Code[20]; CostAmountExpectedACY: Decimal; Delta: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, DocumentNo, ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.CalcFields("Cost Amount (Expected) (ACY)");
        Assert.AreNearlyEqual(
          CostAmountExpectedACY, ItemLedgerEntry."Cost Amount (Expected) (ACY)", Delta, CostAmountExpectedACYErr);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; LocationCode: Code[10]; CostAmountActual: Decimal; CostPerUnit: Decimal; Quantity: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, DocumentNo, '', LocationCode, true);
        ValueEntry.TestField("Valued Quantity", Quantity);
        Assert.AreNearlyEqual(
          CostPerUnit, ValueEntry."Cost per Unit", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValueEntryNotMatched, ValueEntry.FieldCaption("Cost per Unit"), CostPerUnit, ValueEntry.TableCaption()));
        Assert.AreNearlyEqual(
          CostAmountActual, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValueEntryNotMatched, ValueEntry.FieldCaption("Cost Amount (Actual)"), CostPerUnit, ValueEntry.TableCaption()));
    end;

    local procedure VerifyValueEntryAfterAdjustCostItemEntries(ItemNo: Code[20]; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
        AccumulatedInvdQty: Decimal;
        AccumulatedCostAmtActual: Decimal;
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        repeat
            AccumulatedInvdQty := AccumulatedInvdQty + ValueEntry."Invoiced Quantity";
            AccumulatedCostAmtActual := AccumulatedCostAmtActual + ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreEqual(
          0, AccumulatedInvdQty, StrSubstNo(ValueEntryNotMatched, ValueEntry.FieldCaption("Invoiced Quantity"), 0, ValueEntry.TableCaption()));  // Sum of Invoiced Quantity must be zero.
        Assert.AreNearlyEqual(
          CostAmountActual, AccumulatedCostAmtActual, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValueEntryNotMatched, ValueEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual, ValueEntry.TableCaption()));
    end;

    local procedure VerifyValueEntryAmountsInACY(DocumentNo: Code[20]; ItemChargeNo: Code[20]; Delta: Decimal; CostAmountActualACY: Decimal; CostPerUnitACY: Decimal; CostAmountExpectedACY: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, DocumentNo, ItemChargeNo, '', false);
        Assert.AreNearlyEqual(
          CostPerUnitACY, ValueEntry."Cost per Unit (ACY)", Delta,
          StrSubstNo(ValueEntryNotMatched, ValueEntry.FieldCaption("Cost per Unit (ACY)"), CostPerUnitACY, ValueEntry.TableCaption()));
        Assert.AreNearlyEqual(
          CostAmountExpectedACY, ValueEntry."Cost Amount (Expected) (ACY)", Delta,
          StrSubstNo(
            ValueEntryNotMatched, ValueEntry.FieldCaption("Cost Amount (Expected) (ACY)"), CostAmountExpectedACY, ValueEntry.TableCaption()));
        Assert.AreNearlyEqual(
          CostAmountActualACY, ValueEntry."Cost Amount (Actual) (ACY)", Delta,
          StrSubstNo(
            ValueEntryNotMatched, ValueEntry.FieldCaption("Cost Amount (Actual) (ACY)"), CostAmountActualACY, ValueEntry.TableCaption()));
    end;

    local procedure VerifyCustomerStatementReport(CurrencyCode: Code[10]; AmountIncludingVAT: Decimal)
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        LibraryReportDataset.AssertElementWithValueExists('Total_Caption2', 'Total'); // need to verify the label 'Total'.
        LibraryReportDataset.AssertElementWithValueExists('CurrencyCode3', CurrencyCode);
        LibraryReportDataset.AssertElementWithValueExists('CustBalance_CustLedgEntryHdr',
          Round(AmountIncludingVAT, Currency."Invoice Rounding Precision"));
    end;

    local procedure CheckValueEntryCostAmountNonInvtblNegSign(DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
        Assert.IsTrue(ValueEntry."Cost Amount (Non-Invtbl.)" < 0, CostAmountNonInvtblErr);
    end;

    local procedure VerifyAmountsInACYOnValueEntry(ItemNo: Code[20]; CostPerUnitACY: Decimal; Delta: Decimal; CostPostedToGLACY: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.FindFirst();
        Assert.AreNearlyEqual(CostPerUnitACY, ValueEntry."Cost per Unit (ACY)", Delta, CostPerUnitACYErr);
        Assert.AreNearlyEqual(CostPostedToGLACY, ValueEntry."Cost Posted to G/L (ACY)", Delta, CostPostedToGLACYErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeExchangeRatePageHandler(var ChangeExchangeRate: TestPage "Change Exchange Rate")
    var
        RefExchRate: Variant;
    begin
        LibraryVariableStorage.Dequeue(RefExchRate);
        ChangeExchangeRate.RefExchRate.SetValue(RefExchRate);
        ChangeExchangeRate.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.First();
        GetReceiptLines."Document No.".AssertEquals('');
        GetReceiptLines.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnReceiptHandler(var GetReturnReceiptLines: TestPage "Get Return Receipt Lines")
    begin
        GetReturnReceiptLines.First();
        GetReturnReceiptLines."Document No.".AssertEquals('');
        GetReturnReceiptLines.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentHandler(var GetReturnShipmentLines: TestPage "Get Return Shipment Lines")
    begin
        GetReturnShipmentLines.First();
        GetReturnShipmentLines."Document No.".AssertEquals('');
        GetReturnShipmentLines.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.First();
        GetShipmentLines."Document No.".AssertEquals('');
        GetShipmentLines.Cancel().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler2(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchItemChargeAssignmentHandler(var PurchItemChargeAssignment: TestPage "Item Charge Assignment (Purch)")
    begin
        PurchItemChargeAssignment.GetSalesShipmentLines.Invoke();
        PurchItemChargeAssignment.SuggestItemChargeAssignment.Invoke();
        PurchItemChargeAssignment.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentLinePageHandler(var SalesShipmentLines: TestPage "Sales Shipment Lines")
    var
        PostedDocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostedDocumentNo);
        SalesShipmentLines.FILTER.SetFilter("Document No.", PostedDocumentNo);
        SalesShipmentLines.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesPageHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        RolledupMaterialCost: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(RolledupMaterialCost);
        LibraryVariableStorage.Dequeue(ItemNo);
        BOMCostShares.Expand(true);
        BOMCostShares.Next();
        BOMCostShares."No.".AssertEquals(ItemNo);
        BOMCostShares.HasWarning.AssertEquals(true);
        BOMCostShares."Rolled-up Material Cost".AssertEquals(RolledupMaterialCost);

        // Verify no component item expanded.
        BOMCostShares.Expand(true);
        Assert.IsFalse(BOMCostShares.Next(), StrSubstNo(ExpandBOMErr, ItemNo));
        BOMCostShares.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementRequestPageHandler(var Statement: TestRequestPage Statement)
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        Statement.Customer.SetFilter("No.", CustomerNo);
        Statement."Start Date".SetValue(Format(CalcDate('<+1Y>', WorkDate())));
        Statement."End Date".SetValue(Format(CalcDate('<+2Y>', WorkDate())));
        Statement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

