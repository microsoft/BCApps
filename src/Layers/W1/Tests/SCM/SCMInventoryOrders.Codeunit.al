codeunit 137400 "SCM Inventory - Orders"
{
    Permissions = TableData "Sales Shipment Header" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTemplates: Codeunit "Library - Templates";
        VendorNo: Code[20];
        GetShipmentLines: Boolean;
        IsInitialized: Boolean;
        CostError: Label '%1 must be equal to %2 in %3';
        DescriptionErr: Label 'Descriptions must be the same.';
        ExpectedCostPostingEnableDialog: Label 'If you enable the %1, the program must update table %2.';
        ExpectedCostPostingDisableDialog: Label 'If you disable the %1, the program must update table %2.';
        CalculateInvoiceDiscount: Boolean;
        CapableToPromise: Boolean;
        RequestedShipmentDate: Boolean;
        ConfirmMessage: Text[1024];
        InterruptedToRespectError: Label 'The update has been interrupted to respect the warning.';
        UnknownError: Label 'Unknown Error.';
        PostingDateError: Label 'Enter the posting date.';
        DocumentDateError: Label 'Enter the document date.';
        SalesReturnOrderMustBeDeletedError: Label 'Sales %1 must be deleted for %2 : %3', Comment = '%1 = Document Type Value, %2 = Document No. Field, %3 = Document No. Value';
        RequestedDeliveryDate: Date;
        UnavailableQuantity: Decimal;
        Quantity2: Decimal;
        Amount: Decimal;
        ItemRegisterMustBeDeletedError: Label 'Item Register must be deleted.';
        DummyConfirmQst: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        VerificationFailureErr: Label 'Confirmation Message must be similar.';
        OrderPromisingQtyErr: Label 'Incorrect Quantity on Order Promising Line.';
        OrderPromisingUnavailQtyErr: Label 'Incorrect Unavailable Quantity on Order Promising Line';
        AmountToAssignItemChargeErr: Label 'Amount to Assign does not correspond to Qty. to Assign on item charge assignment.';
        QtyToInvoiceMustHaveValueErr: Label 'Qty. to Invoice must have a value';
        DimensionErr: Label 'Dimension Value Code must be %1 in %2.', Comment = '%1 = Dimension Value Code, %2=Table Name';
        DropShipmentDocumentExistsErr: Label 'You cannot use the cancel or correct functionality because the invoice line is associated with purchase order %1 due to Drop Shipment.', Comment = '%1 - Purchase Order No.';

    [Test]
    [Scope('OnPrem')]
    procedure ItemInventoryWithPurchaseOrder()
    var
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Verify that Item Inventory gets increased on posting Purchase Order for that Item.

        // Setup: Create an Item.
        Initialize();
        CreateItem(Item);

        // Exercise: Create a Purchase Order for the new Item and post it.
        Quantity := CreateAndPostPurchaseOrder(Item."No.", false);
        Item.CalcFields(Inventory);

        // Verify: Verify that Item Inventory gets increased with the quantity of the Purchase Order.
        Item.TestField(Inventory, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemInventoryWithSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        InitialInventory: Decimal;
        SalesQuantity: Decimal;
    begin
        // Verify that Item Inventory gets decreased on posting Sales Order after making purchase of that Item.

        // Setup: Create an Item and post a Purchase Order for the same.
        Initialize();
        CreateItem(Item);
        InitialInventory := CreateAndPostPurchaseOrder(Item."No.", false);

        // Exercise: Create and post a Sales Order for the new Item.
        SalesQuantity := CreateAndPostSalesDocument(Item, SalesHeader."Document Type"::Order, InitialInventory);
        Item.CalcFields(Inventory);

        // Verify: Verify that Item Inventory gets decreased with the quantity of the Sales Order.
        Item.TestField(Inventory, InitialInventory - SalesQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemInventoryWithSalesReturnOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        InitialInventory: Decimal;
        SalesQuantity: Decimal;
    begin
        // Verify that Item Inventory gets increased on posting Sales Return Order after making sale of that Item.

        // Setup: Create Item, make Purchase and post Sales Order for the same.
        Initialize();
        CreateItem(Item);
        InitialInventory := CreateAndPostPurchaseOrder(Item."No.", false);
        InitialInventory -= CreateAndPostSalesDocument(Item, SalesHeader."Document Type"::Order, InitialInventory);

        // Exercise: Create and post Sales Return Order for the new Item.
        SalesQuantity := CreateAndPostSalesDocument(Item, SalesHeader."Document Type"::"Return Order", InitialInventory);
        Item.CalcFields(Inventory);

        // Verify: Verify that Item Inventory gets increased with the quantity of the Sales Return Order.
        Item.TestField(Inventory, InitialInventory + SalesQuantity);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListHandler')]
    [Scope('OnPrem')]
    procedure ItemByPage()
    var
        TempItem: Record Item temporary;
    begin
        // Verify creation of Item by page.

        // Setup: Create Item in Temporary record.
        Initialize();
        CreateTempItem(TempItem);

        // Exercise: Create Item by page.
        CreateItemCard(TempItem);

        // Verify: Verify the data of newly created Item.
        VerifyItem(TempItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryAfterPostingPhysicalInventoryJournal()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        UnitAmount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Validate Item Ledger Entry after posting Physical Inventory Journal.

        // Setup : Create and Post Item Journal Lines.
        Initialize();
        CreateItem(Item);
        UnitAmount := LibraryRandom.RandDec(15, 2); // Use random value for UnitAmount.
        Quantity := LibraryRandom.RandDec(10, 2) + 100; // Use random value for Quantity.
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, Quantity, Item."No.", UnitAmount, '');
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::Sale, Quantity - LibraryRandom.RandDec(10, 2), Item."No.", UnitAmount, ''); // Quantity of Sales should be less than quantity of Purchase.

        // Exercise : Calculate Inventory and Post Physical Inventory.
        RunCalculateInventory(Item."No.");
        DocumentNo := PostPhysicalInventoryJournal(Quantity, Item."No.");  // Positive adjustment.
        RunCalculateInventory(Item."No.");
        DocumentNo2 := PostPhysicalInventoryJournal(-Quantity, Item."No.");  // Negative adjustment.

        // Verify : Verify Item Ledger Entry.
        VerifyItemLedgerEntry(DocumentNo, Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity);
        VerifyItemLedgerEntry(DocumentNo2, Item."No.", ItemJournalLine."Entry Type"::"Negative Adjmt.", -Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryAfterPostingPhysicalInventoryJournal()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        UnitAmount: Decimal;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Validate Value Entry after posting Physical Inventory Journal.

        // Setup : Create and Post Item Journal Lines.
        Initialize();
        CreateItem(Item);
        UnitAmount := LibraryRandom.RandDec(15, 2); // Use random value for UnitAmount.
        Quantity := LibraryRandom.RandDec(10, 2) + 100; // Use random value for Quantity.
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, Quantity, Item."No.", UnitAmount, '');
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::Sale, Quantity - LibraryRandom.RandDec(10, 2), Item."No.", UnitAmount, ''); // Quantity of Sales should be less than quantity of Purchase.

        // Exercise : Calculate Inventory and Post Physical Inventory.
        RunCalculateInventory(Item."No.");
        DocumentNo := PostPhysicalInventoryJournal(Quantity, Item."No.");  // Positive adjustment.
        RunCalculateInventory(Item."No.");
        DocumentNo2 := PostPhysicalInventoryJournal(-Quantity, Item."No.");  // Negative adjustment.

        // Verify : Verify Item Value Entry.
        VerifyItemValueEntry(DocumentNo, Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, UnitAmount);
        VerifyItemValueEntry(DocumentNo2, Item."No.", ItemJournalLine."Entry Type"::"Negative Adjmt.", -Quantity, UnitAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExpectedCostPostingToGLTrue()
    begin
        // Set the Expected Cost Posting to G/L TRUE in Inventory Setup and verify the dialog message.
        Initialize();
        SetExpectedCostPostingToGLAndValidateConfirmDialog(false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExpectedCostPostingToGLFalse()
    begin
        // Set the Expected Cost Posting to G/L FALSE in Inventory Setup and verify the dialog message.
        Initialize();
        SetExpectedCostPostingToGLAndValidateConfirmDialog(true, false);
    end;

    local procedure SetExpectedCostPostingToGLAndValidateConfirmDialog(ExpectedCostPostingToGL: Boolean; ExpectedCostPostingToGL2: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
        PostValueEntrytoGL: Record "Post Value Entry to G/L";
    begin
        // Setup : Get Inventory Setup.
        InventorySetup.Get();
        UpdateInventorySetup(ExpectedCostPostingToGL);

        // Exercise : Set Value of Expected Cost Posting to G/L.
        UpdateInventorySetup(ExpectedCostPostingToGL2);

        // Verify : Verify the Confirm message.
        case ExpectedCostPostingToGL2 of
            false:
                if StrPos(
                    ConfirmMessage,
                    StrSubstNo(
                        ExpectedCostPostingDisableDialog,
                        InventorySetup.FieldCaption("Expected Cost Posting to G/L"), PostValueEntrytoGL.TableCaption())) = 0
                then
                    error(UnknownError);
            true:
                if StrPos(
                    ConfirmMessage,
                    StrSubstNo(
                        ExpectedCostPostingEnableDialog,
                        InventorySetup.FieldCaption("Expected Cost Posting to G/L"), PostValueEntrytoGL.TableCaption())) = 0
                then
                    error(UnknownError);
        end;

        // Tear Down : Set Default value of Inventory Setup.
        UpdateInventorySetup(InventorySetup."Expected Cost Posting to G/L");
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderForPostedDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test Get Posted Document Lines To Reverse functionality on Sales Return Order.

        // Setup: Create and post Sales Order.
        Initialize();
        CreateAndPostSalesOrder(SalesHeader, SalesLine);

        // Exercise: Create Sales Return Order and get Posted Document Lines to return.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        GetPostedDocumentLinesToReverseOnSalesReturnOrder(SalesHeader."No.");

        // Verify: Verify Apply from Item Entry must not zero.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item, SalesLine."No.");
        SalesLine.TestField("Appl.-from Item Entry");
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler,ItemChargeAssignmentSalesHandler,SalesShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure NegativeLineOnSalesReturnOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeNo: Code[20];
    begin
        // Test Create Negative lines with Item Charge Assignment on Sales Return Order.

        // Setup: Create and post Sales Order. Create Sales Return Order and get Posted Document Lines to return.
        Initialize();
        CreateAndPostSalesOrder(SalesHeader, SalesLine);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        GetPostedDocumentLinesToReverseOnSalesReturnOrder(SalesHeader."No.");

        // Exercise: Add Negative Line and Item Charge Lines. Apply Item Charges.
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", -SalesLine.Quantity);
        CreateAndAssignItemChargeLine(SalesLine, SalesHeader, -SalesLine.Quantity, true);
        ItemChargeNo := SalesLine."No.";
        CreateAndAssignItemChargeLine(SalesLine, SalesHeader, SalesLine.Quantity, false);

        // Verify: Verify Lines on Sales Return Order.
        VerifySalesLine(SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item, Item."No.", -SalesLine.Quantity, 0); // Use 0 for Quantity To Assign.
        VerifySalesLine(
          SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"Charge (Item)", ItemChargeNo, SalesLine.Quantity,
          SalesLine.Quantity);
        VerifySalesLine(
          SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"Charge (Item)", SalesLine."No.", SalesLine.Quantity,
          SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler,ItemChargeAssignmentSalesHandler,SalesShipmentLinesHandler,MoveNegativeSalesLinesHandler,ConfirmHandler,SalesOrderHandler')]
    [Scope('OnPrem')]
    procedure MoveNegativeLinesFromSalesReturnOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test Move Negative Lines functionality on Sales Return Order.

        // Setup: Update Sales and Receivable Setup. Create and post Sales Order. Create Sales Return Order and get Posted Document Lines to return. Add Negative Line and Item Charge Lines. Apply Item Charges.
        Initialize();
        UpdateSalesReceivableSetup(false, false);
        CreateAndPostSalesOrder(SalesHeader, SalesLine);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        GetPostedDocumentLinesToReverseOnSalesReturnOrder(SalesHeader."No.");
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", -SalesLine.Quantity);
        CreateAndAssignItemChargeLine(SalesLine, SalesHeader, -SalesLine.Quantity, true);
        CreateAndAssignItemChargeLine(SalesLine, SalesHeader, SalesLine.Quantity, false);

        // Exercise: Move Negative Lines.
        MoveNegativeLines(SalesHeader."No.");

        // Verify: Verify Negative Line must be moved in new Sales Order.
        VerifySalesLine(
          SalesHeader."Document Type"::Order, FindDocumentNo(SalesHeader."Sell-to Customer No."), SalesLine.Type::Item, Item."No.",
          SalesLine.Quantity, 0); // Use 0 for Quantity To Assign.
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler,ItemChargeAssignmentSalesHandler,SalesShipmentLinesHandler,MoveNegativeSalesLinesHandler,ConfirmHandler,SalesOrderHandler')]
    [Scope('OnPrem')]
    procedure NavigateSalesReturnOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test Navigate functionality on Sales Return Order.

        // Setup: Update Sales and Receivable Setup. Create and post Sales Order. Create Sales Return Order and get Posted Document Lines to return. Add Negative Line and Item Charge Lines. Apply Item Charges. Move Negative Lines.
        Initialize();
        UpdateSalesReceivableSetup(false, false);
        CreateAndPostSalesOrder(SalesHeader, SalesLine);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        GetPostedDocumentLinesToReverseOnSalesReturnOrder(SalesHeader."No.");
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", -SalesLine.Quantity);
        CreateAndAssignItemChargeLine(SalesLine, SalesHeader, -SalesLine.Quantity, true);
        CreateAndAssignItemChargeLine(SalesLine, SalesHeader, SalesLine.Quantity, false);
        MoveNegativeLines(SalesHeader."No.");

        // Exercise: Post Sales Order and Sales Return Order.
        FindAndPostSalesDocument(SalesHeader."Document Type"::Order, FindDocumentNo(SalesHeader."Sell-to Customer No."));
        FindAndPostSalesDocument(SalesHeader."Document Type", SalesHeader."No.");

        // Verify: Verify Navigate Lines.
        VerifyNavigateLines(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CalculateInventoryValueDimension()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionSetID: Integer;
    begin
        // Verify Dimension on Revaluation Journal after Running Calculate Inventory Value Report.

        // Setup: Create Item with Dimension, Create and post Purchase Order.
        Initialize();
        CreateAndPostPurchaseOrderWithDimension(DefaultDimension);

        // Exercise: Run Calculate Inventory Value Report.
        DimensionSetID := RunCalculateInventoryValueReport(DefaultDimension."No.");

        // Verify: Dimension on Revaluation Journal.
        VerifyDimensionOnRevaluationJournal(DefaultDimension, DimensionSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CalculateInventoryValueWithUpdateItemDimension()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionSetID: Integer;
    begin
        // Update Dimension on Item after Posting Purchase Order and Verify Dimension on Revaluation Journal.

        // Setup: Create Item With Dimension, Create and post Purchase Order.
        Initialize();
        CreateAndPostPurchaseOrderWithDimension(DefaultDimension);

        // Exercise: Run Calculate Inventory Value Report.
        UpdateDefaultDimension(DefaultDimension);  // Update Item Dimension after Posting Purchase Order.
        DimensionSetID := RunCalculateInventoryValueReport(DefaultDimension."No.");

        // Verify: Updated Dimension on Revaluation Journal.
        VerifyDimensionOnRevaluationJournal(DefaultDimension, DimensionSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryAfterPostingPurchaseOrder()
    var
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Verify Item Ledger Entry after posting Purchase Order.

        // Setup: Create Item.
        Initialize();
        CreateItem(Item);

        // Exercise: Create and Post Purchase Order.
        Quantity := CreateAndPostPurchaseOrder(Item."No.", true);

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntryForPurchaseOrder(Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysicalInventoryLedgerEntryAfterPostingPhysicalInventoryJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify Physical Inventory Item Journal after posting Physical Inventory Journal.

        // Setup: Create Item, Item Journal and Post it.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, Quantity, Item."No.", LibraryRandom.RandDec(10, 2), '');  // Taking Random Unit Amount.

        // Exercise: Run Calculate Inventory and Post Physical Inventory Journal.
        RunCalculateInventory(Item."No.");
        DocumentNo := PostPhysicalInventoryJournal(Quantity, Item."No.");

        // Verify: Verify Physical Inventory Item Ledger.
        VerifyPhysicalInventoryItemLedger(DocumentNo, Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Test functionality of Create Sales Order from Sales Blanket Order.

        // Setup: Create Sales Blanket Order.
        Initialize();
        UpdateSalesReceivableSetup(false, false);
        CreateSalesBlanketOrder(SalesHeader, SalesLine);

        // Exercise: Create Sales Order from Blanket Sales Order.
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);

        // Verify: Verify Sales Order Line.
        FindSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        FindSalesLine(SalesLine2, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item, SalesLine."No.");
        SalesLine2.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentBeforePosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test functionality of Drop Shipment before Posting.

        // Setup: Create Sales Order from Sales Blanket Order. Add Drop Shipment Line in Sales Order.
        Initialize();
        UpdateSalesReceivableSetup(false, false);
        CreateSalesOrderForDropShipment(SalesHeader, SalesLine);

        // Exercise: Create Purchase Order and associate with Sales Order.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Drop Shpt.", PurchaseHeader);

        // Verify: Verify Purchase Line for Drop Shipment.
        VerifyPurchaseLine(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.", SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentAfterPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Test functionality of Drop Shipment after Posting.

        // Setup: Create Sales Order from Sales Blanket Order. Add Drop Shipment Line in Sales Order. Create Purchase Order and associate with Sales Order.
        Initialize();
        UpdateSalesReceivableSetup(false, false);
        CreateSalesOrderForDropShipment(SalesHeader, SalesLine);
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Drop Shpt.", PurchaseHeader);

        // Exercise: Post purchase Order as Receive. Post Sales Order as Invoice. Post Purchase Order as Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Verify: Verify Purchase Invoice Line.
        VerifyPurchaseInvoiceLine(DocumentNo, SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentDescriptionfromItem()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Purchase] [Drop Shipment]
        // [SCENARIO 378247] Descriptions should be getting from Item when getting Drop Shipment Lines if Item Variant, Item Translation and Item Cross Reference don't exist, and Descriptions on Sales Line are blank.
        Initialize();

        // [GIVEN] Create Item with "Description" = "D1","Description 2" = "D2".
        // [GIVEN] Sales Order with Drop Shipment Line, Description and "Description 2" fields are blank.
        CreateItemWithVariant(Item, ItemVariant);
        CreateSalesOrderWithItemVariantPurchDesc(SalesHeader, SalesLine, Customer, Item."No.", '', '', '');

        // [GIVEN] Create Purchase Order associated with Sales Order.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [WHEN] Getting Drop Shipment Lines from Sales Lines.
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [THEN] "Description" in purchase line is "D1", "Description 2" in purchase line is "D2".
        VerifyPurchaseLineDescription(PurchaseLine, Item.Description, Item."Description 2");
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentDescriptionfromItemVariant()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Purchase] [Drop Shipment]
        // [SCENARIO 378247] Descriptions should be getting from Item Variant when getting Drop Shipment Lines if Item Translation and Item Cross Reference don't exist, and Descriptions on Sales Line are blank.
        Initialize();

        // [GIVEN] Create Item.
        // [GIVEN] Create Item Variant with "Description" = "D1","Description 2" = "D2".
        // [GIVEN] Create Sales Order with Drop Shipment Line and "Variant Code", Description and "Description 2" fields are blank.
        CreateItemWithVariant(Item, ItemVariant);
        CreateSalesOrderWithItemVariantPurchDesc(SalesHeader, SalesLine, Customer, Item."No.", ItemVariant.Code, '', '');

        // [GIVEN] Create Purchase Order associated with Sales Order.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [WHEN] Getting Drop Shipment Lines from Sales Lines.
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [THEN] "Description" in purchase line is "D1", "Description 2" in purchase line is "D2".
        VerifyPurchaseLineDescription(PurchaseLine, ItemVariant.Description, ItemVariant."Description 2");
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentDescriptionfromSalesLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Purchase] [Drop Shipment]
        // [SCENARIO 381104] Descriptions should be getting from Sales Line when getting Drop Shipment Lines if Item Translation and Item Cross Reference do not exist.
        Initialize();

        // [GIVEN] Create Item and Item Variant.
        // [GIVEN] Sales Order with Drop Shipment Line and "Variant Code", Description = "D1", "Description 2" = "D2".
        CreateItemWithVariant(Item, ItemVariant);
        CreateSalesOrderWithItemVariantPurchDesc(
          SalesHeader, SalesLine, Customer, Item."No.", ItemVariant.Code, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Order associated with Sales Order.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [WHEN] Getting Drop Shipment Lines from Sales Lines.
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [THEN] "Description" in purchase line is "D1", "Description 2" in purchase line is "D2".
        VerifyPurchaseLineDescription(PurchaseLine, SalesLine.Description, SalesLine."Description 2");
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentDescriptionfromItemTranslation()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemTranslation: Record "Item Translation";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Drop Shipment]
        // [SCENARIO 378247] Descriptions should be getting from Item Translation when getting Drop Shipment Lines if Item Translation exists and Item Cross Reference doesn't exist.
        Initialize();

        // [GIVEN] Create Item and Item Variant.
        // [GIVEN] Sales Order with Drop Shipment Line, "Variant Code" and descriptions.
        CreateItemWithVariant(Item, ItemVariant);
        CreateSalesOrderWithItemVariantPurchDesc(
          SalesHeader, SalesLine, Customer, Item."No.", ItemVariant.Code, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Create Purchase Order associated with Sales Order.
        CreatePurchOrder(PurchaseHeader, Vendor, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Create Item Translation with "Description" = "D1","Description 2" = "D2".
        CreateItemTranslation(ItemTranslation, Item."No.", Vendor."Language Code", ItemVariant.Code);

        // [WHEN] Getting Drop Shipment Line from Sales Lines.
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [THEN] "Description" in purchase line is "D1", "Description 2" in purchase line is "D2".
        VerifyPurchaseLineDescription(PurchaseLine, ItemTranslation.Description, ItemTranslation."Description 2")
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentDescriptionfromItemReference()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemVariant: Record "Item Variant";
        ItemVendor: Record "Item Vendor";
        ItemTranslation: Record "Item Translation";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Drop Shipment]
        // [SCENARIO 378247] Descriptions should be getting from Item Reference when getting Drop Shipment Lines if Item Reference exist.
        Initialize();

        // [GIVEN] Create Item and Item Variant.
        // [GIVEN] Sales Order with Drop Shipment Line, "Variant Code" and descriptions.
        CreateItemWithVariant(Item, ItemVariant);
        CreateSalesOrderWithItemVariantPurchDesc(
          SalesHeader, SalesLine, Customer, Item."No.", ItemVariant.Code, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Create Purchase Order associated with Sales Order.
        CreatePurchOrder(PurchaseHeader, Vendor, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Create Item Translation.
        CreateItemTranslation(ItemTranslation, Item."No.", Vendor."Language Code", ItemVariant.Code);

        // [GIVEN] Create Item Vendor and Item Cross Reference with "Description" = "D1".
        CreateItemVendorWithVariantCode(ItemVendor, Vendor."No.", Item."No.", ItemVariant.Code);
        CreateItemReference(
          ItemReference, Item."No.", ItemReference."Reference Type"::Vendor, Vendor."No.", ItemVariant.Code,
          SalesLine."Unit of Measure Code", Item."No.");
        ItemReference.Validate(Description, LibraryUtility.GenerateGUID());
        ItemReference.Modify(true);

        // [WHEN] Getting Drop Shipment Line from Sales Lines.
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [THEN] "Description" in purchase line is "D1", "Description 2" in purchase line is empty.
        VerifyPurchaseLineDescription(PurchaseLine, ItemReference.Description, '');
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShptAfterPostAsShip()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Purchase] [Drop Shipment]
        // [SCENARIO 378140] "Qty. to Receive" in Purchase Line with Drop Shipment should be 0 after receipt and shipment postings full Quantity in Sales Line.
        Initialize();

        // [GIVEN] "Default Quantity to Ship" = Blank on "Sales Receivables Setup" and "Default Qty. to Receive" = Blank on "Purchases & Payables Setup".
        SetDefaultQtyToShipToBlank();
        SetDefaultQtyToReceiveToBlank();
        // [GIVEN] Sales Order with Drop Shipment Line.
        CreateCustomer(Customer, true, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader);
        // [GIVEN] Purch.Order is associated with Sales Order.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        LibraryPurchase.GetDropShipment(PurchaseHeader);
        // [GIVEN] "Qty. to Ship" is equal Quantity from Sales Line.
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity);
        SalesLine.Modify(true);
        // [GIVEN] "Qty. to Receive" is equal Quantity from Sales Line.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Receive", SalesLine.Quantity);
        PurchaseLine.Modify(true);

        // [WHEN] Post Sales Order as Receive.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "Qty To Receive" is equal 0.
        // [THEN] "Quantity Received" and "Qty. to Invoice" are equal Quantity.
        VerifyDropShipment(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler,GetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentPostingSalesInvoiceViaGetShipmentLines()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment] [Get Shipment Lines] [Sales] [Invoice]
        // [SCENARIO 215456] Sales invoice created with Get Shipment Lines function for Drop Shipment order line can be posted.
        Initialize();

        // [GIVEN] Sales Order with Drop Shipment line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader);

        // [GIVEN] Purch. Order is associated with Sales Order and posted with Receive option.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        LibraryPurchase.GetDropShipment(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create Sales Invoice via Get Shipment Lines.
        GetShipmentLineInSalesInvoice(SalesHeaderInvoice, SalesHeader."Sell-to Customer No.");

        // [WHEN] Post the Sales Invoice.
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [THEN] The sales order is successfully invoiced.
        SalesLine.Find();
        SalesLine.TestField("Quantity Invoiced", SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CombineReturnReceiptReportWithoutPostingDate()
    begin
        // Test to verify error message when Combine Return Receipt report is run without Posting Date.

        // Setup: Create and post two Sales Return order for same Customer.
        Initialize();

        // Exercise: Run Combine Return Receipt without Posting Date.
        asserterror RunCombineReturnReceipt(0D, WorkDate(), '');

        // Verify: Verify Error Message.
        Assert.AreEqual(StrSubstNo(PostingDateError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CombineReturnReceiptReportWithoutDocumentDate()
    begin
        // Test to verify error message when Combine Return Receipt report is run without Document Date.

        // Setup: Create and post two Sales Return order for same Customer.
        Initialize();

        // Exercise: Run Combine Return Receipt without Document date.
        asserterror RunCombineReturnReceipt(WorkDate(), 0D, '');

        // Verify: Verify Error Message.
        Assert.AreEqual(StrSubstNo(DocumentDateError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CombineReturnReceiptReport()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Test to check functionality of Combine Return Receipt report .

        // Setup: Create and post two Sales Return order for same Customer.
        Initialize();
        CreateCustomer(Customer, true, '');
        DocumentNo := CreateAndPostSalesReturnOrder(SalesLine, Customer."No.", false);
        DocumentNo2 := CreateAndPostSalesReturnOrder(SalesLine2, SalesLine."Sell-to Customer No.", false);

        // Exercise: Run Combine Return Receipt.
        RunCombineReturnReceipt(WorkDate(), WorkDate(), SalesLine."Sell-to Customer No.");

        // Verify: Verify Posted Sales Credit Memo.
        VerifyPostedSalesCreditMemo(
          SalesLine."Sell-to Customer No.", SalesLine."Bill-to Customer No.", SalesLine.Type::Item, DocumentNo, SalesLine."No.",
          SalesLine.Quantity);
        VerifyPostedSalesCreditMemo(
          SalesLine2."Sell-to Customer No.", SalesLine2."Bill-to Customer No.", SalesLine2.Type::Item, DocumentNo2, SalesLine2."No.",
          SalesLine2.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineReturnReceiptReportWithDifferentBillToCustomerNo()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Test to check functionality of Combine Return Receipt report for different Bill To Customer No.

        // Setup: Create and post two Sales Return order for different Bill To Customer.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        CreateCustomer(Customer, true, '');
        DocumentNo := CreateAndPostSalesReturnOrder(SalesLine, Customer."No.", false);
        DocumentNo2 := CreateAndPostSalesReturnOrder(SalesLine2, SalesLine."Sell-to Customer No.", true);

        // Exercise: Run Combine Return Receipt.
        RunCombineReturnReceipt(WorkDate(), WorkDate(), SalesLine."Sell-to Customer No.");

        // Verify: Verify Posted Sales Credit Memo.
        VerifyPostedSalesCreditMemo(
          SalesLine."Sell-to Customer No.", SalesLine."Bill-to Customer No.", SalesLine.Type::Item, DocumentNo, SalesLine."No.",
          SalesLine.Quantity);
        VerifyPostedSalesCreditMemo(
          SalesLine2."Sell-to Customer No.", SalesLine2."Bill-to Customer No.", SalesLine2.Type::Item, DocumentNo2, SalesLine2."No.",
          SalesLine2.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvoiceSalesReturnOrderReport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Test to check functionality of Delete Invoice Sales Return Order report after Combine Return Receipt Batch report.

        // Setup: Create and post two Sales Return orders and Run Combine Return Receipt report.
        Initialize();
        CreateCustomer(Customer, true, '');
        CreateAndPostSalesReturnOrder(SalesLine, Customer."No.", false);
        CreateAndPostSalesReturnOrder(SalesLine2, SalesLine."Sell-to Customer No.", false);
        RunCombineReturnReceipt(WorkDate(), WorkDate(), SalesLine."Sell-to Customer No.");

        // Exercise: Run Delete Invoice Sales Return Order batch report.
        RunDeleteInvoiceSalesReturnOrder(SalesLine."Sell-to Customer No.");

        // Verify: Sales Return Orders gets deleted.
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::"Return Order", SalesLine."Document No."),
          StrSubstNo(
            SalesReturnOrderMustBeDeletedError, SalesHeader."Document Type"::"Return Order", SalesLine.FieldCaption("Document No."),
            SalesLine."Document No."));
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::"Return Order", SalesLine2."Document No."),
          StrSubstNo(
            SalesReturnOrderMustBeDeletedError, SalesHeader."Document Type"::"Return Order", SalesLine2.FieldCaption("Document No."),
            SalesLine2."Document No."));
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesHandler,SalesShipmentLinesHandler,MessageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CombineReturnReceiptReportForItemCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Test to check functionality of Combine Return Receipt report for Item Charge.

        // Setup: Create and post two Sales Return orders for Item Charge.
        Initialize();
        CreateAndPostSalesOrder(SalesHeader, SalesLine);
        DocumentNo := CreateAndPostSalesReturnOrderForItemCharge(SalesLine, SalesHeader."Sell-to Customer No.");
        DocumentNo2 := CreateAndPostSalesReturnOrderForItemCharge(SalesLine2, SalesHeader."Sell-to Customer No.");

        // Exercise: Run Combine Return Receipt batch job.
        RunCombineReturnReceipt(WorkDate(), WorkDate(), SalesLine."Sell-to Customer No.");

        // Verify: Verify Posted Sales Credit Memo.
        VerifyPostedSalesCreditMemo(
          SalesLine."Sell-to Customer No.", SalesLine."Bill-to Customer No.", SalesLine.Type::"Charge (Item)", DocumentNo, SalesLine."No.",
          SalesLine.Quantity);
        VerifyPostedSalesCreditMemo(
          SalesLine2."Sell-to Customer No.", SalesLine2."Bill-to Customer No.", SalesLine.Type::"Charge (Item)", DocumentNo2,
          SalesLine2."No.", SalesLine2.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesHandler,SalesShipmentLinesHandler,MessageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvoiceSalesReturnOrderReportForItemCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Test to check functionality of Delete Invoice Sales Return Order report for Item Charge after Combine Return Receipt Batch report.

        // Setup: Create and post two Sales Return orders for Item Charge and Run Combine Return Receipt report.
        Initialize();
        CreateAndPostSalesOrder(SalesHeader, SalesLine);
        CreateAndPostSalesReturnOrderForItemCharge(SalesLine, SalesHeader."Sell-to Customer No.");
        CreateAndPostSalesReturnOrderForItemCharge(SalesLine2, SalesHeader."Sell-to Customer No.");
        RunCombineReturnReceipt(WorkDate(), WorkDate(), SalesLine."Sell-to Customer No.");

        // Exercise: Run Delete Invoice Sales Return Order batch report.
        RunDeleteInvoiceSalesReturnOrder(SalesLine."Sell-to Customer No.");

        // Verify: Sales Return Orders gets deleted.
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::"Return Order", SalesLine."Document No."),
          StrSubstNo(
            SalesReturnOrderMustBeDeletedError, SalesHeader."Document Type"::"Return Order", SalesLine.FieldCaption("Document No."),
            SalesLine."Document No."));
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::"Return Order", SalesLine2."Document No."),
          StrSubstNo(
            SalesReturnOrderMustBeDeletedError, SalesHeader."Document Type"::"Return Order", SalesLine2.FieldCaption("Document No."),
            SalesLine2."Document No."));
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchaseHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentInPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // Test to check Item Charge Assignment in Purchase Return Order.

        // Setup: Create Purchase Return Order with Item Charge.
        Initialize();
        ItemNo := CreatePurchaseReturnOrderWithItemCharge(PurchaseHeader, PurchaseLine, LibraryRandom.RandInt(10));  // Taking Random Quantity.

        // Exercise: Suggest Item Charge Assignment.
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify: Verify Item Charge Assignment.
        VerifyItemChargeAssignment(
          PurchaseHeader."Document Type", PurchaseHeader."No.", ItemNo, PurchaseLine.Quantity, PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchaseHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentInPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Test to check Item Charge Assignment in Purchase Credit Memo.

        // Setup: Create and Post Purchase Return Order with Item Charge Assignment and Create Purchase Credit Memo.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Taking Random Quantity.
        ItemNo := CreatePurchaseReturnOrderWithItemCharge(PurchaseHeader, PurchaseLine, Quantity);
        PurchaseLine.ShowItemChargeAssgnt();
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");

        // Exercise: Get Return Shipment Lines.
        GetReturnShipmentLine(PurchaseHeader, DocumentNo);

        // Verify: Verify that Purchase Lines and Item Charge Assignment gets copied in Purchase Credit Memo.
        VerifyPurchaseLine(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."No.", ItemNo, Quantity);  // Verify Purchase Line for Item.
        VerifyPurchaseLine(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."No.", PurchaseLine."No.", PurchaseLine.Quantity);  // Verify Purchase Line for Item Charge.
        VerifyItemChargeAssignment(
          PurchaseHeader."Document Type", PurchaseHeader."No.", ItemNo, PurchaseLine.Quantity, PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesReturnOrderHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrderReportWithErrorDialog()
    var
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Test to Validate error message after Calculate Invoice Discount field is set False on Batch Post Sales Return Order report.

        // Setup: Update Sales & Receivables Setup and Create a Sales Return Order.
        Initialize();
        UpdateSalesReceivableSetup(false, true);
        CreateSalesReturnOrder(SalesLine);
        CalculateInvoiceDiscount := true;  // IsCalculateInvoiceDiscount variable is made Global as it is used in the Handler.

        // Exercise: Run Batch Post Sales Return Order report and set Calculate Invoice Discount field FALSE.
        asserterror RunBatchPostSalesReturnOrders(SalesLine."Document No.");

        // Verify: Validate error message.
        Assert.ExpectedTestFieldError(SalesReceivablesSetup.FieldCaption("Calc. Inv. Discount"), Format(false));
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesReturnOrderHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrderReport()
    var
        SalesLine: Record "Sales Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        SalesHeader: Record "Sales Header";
    begin
        // Test to check functionality of Batch Post Sales Return Order report.

        // Setup: Update Sales & Receivables Setup and Create a Sales Return Order.
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        UpdateSalesReceivableSetup(false, true);
        CreateSalesReturnOrder(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Run Batch Post Sales Return Order report.
        RunBatchPostSalesReturnOrders(SalesLine."Document No.");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify: Verify Posted Return Receipt.
        VerifyPostedReturnReceipt(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnitPriceFromItemUnitPrice()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test and verify Sales Unit Price update from Item Price.

        // Setup: Create Item and Customer with Customer Price Group.
        Initialize();
        CreateItem(Item);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateCustomer(Customer, false, CustomerPriceGroup.Code);
        CreateSalesPrice(
          SalesPrice, Item, "Sales Price Type"::Customer, Customer."No.", Item."Base Unit of Measure",
          LibraryRandom.RandDec(100, 2), WorkDate());  // Use random Quantity.

        // Exercise: Create and release Sales Order.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", SalesPrice."Minimum Quantity" / 2);  // Use SalesPrice."Minimum Quantity" / 2 required for test.

        // Verify: Verify Unit Price on Sales Line.
        VerifyUnitPriceOnSalesLine(SalesLine, Item."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnitPriceFromCustomerSalesPrice()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // Test and verify Sales Unit Price update from Customer Sales Price.

        // Setup: Create Item and Customer with Customer Price Group. Create and release Sales Order.
        Initialize();
        PriceListLine.DeleteAll();
        CreateItem(Item);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateCustomer(Customer, false, CustomerPriceGroup.Code);
        CreateSalesPrice(
          SalesPrice, Item, "Sales Price Type"::Customer, Customer."No.", Item."Base Unit of Measure",
          LibraryRandom.RandDec(100, 2), WorkDate());  // Use random Quantity.
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", SalesPrice."Minimum Quantity" / 2);  // Use SalesPrice."Minimum Quantity" / 2 required for test.

        // Exercise: Reopen Sales Order and update Quantity.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Validate(Quantity, SalesPrice."Minimum Quantity");
        SalesLine.Modify(true);

        // Verify: Verify Unit Price on Sales Line.
        VerifyUnitPriceOnSalesLine(SalesLine, SalesPrice."Unit Price");
    end;

    [Test]
    [HandlerFunctions('GetSalesPriceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesUnitPriceFromCustomerSalesPriceGroup()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // Test and verify Sales Unit Price update from Customer Price Group.
        Initialize();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 15.0)");

        // Setup: Create Item and Customer with Customer Price Group. Create and release Sales Order. Reopen Sales Order and update Order Date.
        PriceListLine.DeleteAll();
        CreateItem(Item);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateCustomer(Customer, false, CustomerPriceGroup.Code);
        CreateSalesPrice(
          SalesPrice, Item, "Sales Price Type"::"Customer Price Group", Customer."Customer Price Group", Item."Base Unit of Measure",
          0, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // Use random Starting Date.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", LibraryRandom.RandDec(100, 2));  // Use random Quantity.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        UpdateOrderDateOnSalesOrder(SalesHeader, SalesPrice."Starting Date");

        // Exercise: Get Sales Price.
        GetSalesPrice(SalesHeader."No.");

        // Verify: Verify Unit Price on Sales Line.
        VerifyUnitPriceOnSalesLine(SalesLine, SalesPrice."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnitPriceWithDifferentUnitOfMeasureCode()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesPrice2: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PriceListLine: Record "Price List Line";
    begin
        // Test and verify Sales Unit Price update from Customer Sales Price for multiple Unit of Measure.

        // Setup: Create Item with two Item Unit of Measure. Create Sales Price for Item with different Unit of Measure Code. Create and release Sales Order.
        Initialize();
        PriceListLine.DeleteAll();
        CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
        CreateSalesPrice(SalesPrice, Item, "Sales Price Type"::"All Customers", '', Item."Base Unit of Measure", 0, WorkDate());
        CreateSalesPrice(SalesPrice2, Item, "Sales Price Type"::"All Customers", '', UnitOfMeasure.Code, 0, WorkDate());
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CreateCustomer(Customer, false, '');
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", LibraryRandom.RandDec(100, 2));  // Use random Quantity.

        // Exercise: Reopen Sales Order and update Unit of Measure Code.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        SalesLine.Modify(true);

        // Verify: Verify Unit Price on Sales Line.
        VerifyUnitPriceOnSalesLine(SalesLine, SalesPrice2."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesShipmentAfterShipment()
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        DocumentNo: Code[20];
    begin
        // Update Shipping Agent Code, Shipping Agent Service Code, Package Tracking Number on Posted Shipment.

        // Setup: Create Sales Order and Ship it.
        DocumentNo := CreateSalesOrderAndPost();

        // Exercise: Update Posted Shipment.
        UpdatePostedShipment(ShippingAgentServices, DocumentNo);

        // Verify: Shipping Agent Code, Shipping Agent Service Code, Package Tracking Number Updated on Posted Shipment .
        VerifyPostedShipment(ShippingAgentServices, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ShippingAdviceError()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Order and after change Shipping Advice validate error message.

        // Setup: Create Sales Order.
        Initialize();
        CreateCustomer(Customer, false, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));  // Use Random Quantity.

        // Exercise: Change Shipping Advice to Complete and decline the confirm message.
        asserterror UpdateShippingAdviceOnSalesOrder(SalesHeader);

        // Verify: Verify error message.
        Assert.ExpectedError(InterruptedToRespectError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShippingAdvice()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Order and after change Shipping Advice validate Shipping Advice.

        // Setup: Create Sales Order.
        Initialize();
        CreateCustomer(Customer, false, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));  // Use Random Quantity.

        // Exercise: Change Shipping Advice to Complete.
        UpdateShippingAdviceOnSalesOrder(SalesHeader);

        // Verify: Verify Shipping Advice must be Complete.
        SalesHeader.Find();
        SalesHeader.TestField("Shipping Advice", SalesHeader."Shipping Advice"::Complete);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingHandler')]
    [Scope('OnPrem')]
    procedure CalculateAvailabilityAndCapability()
    var
        Item: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
    begin
        // Create Order Promising with Capable to Promise. Verify Unavailable Quantity, Planned Delivery Date, Requested Delivery Date.

        // Setup: Create Item and Location. Create Sales Order with Request Delivery Date.
        Initialize();
        CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CapableToPromise := true;  // Global Variable used in OrderPromising Handler.
        CreateSalesOrderWithRequestedDeliveryDate(SalesLine, Item."No.", Location.Code, LibraryRandom.RandDec(10, 2));  // Use Random Quantity.
        UnavailableQuantity := SalesLine.Quantity; // Global Variable used in OrderPromising Handler.

        // Exercise: Open Order Promising Lines Page and Invoke Capable to Promise.
        OpenOrderPromisingPage(SalesLine."Document No.");

        // Verify: Unavailable Quantity, Planned Delivery Date, Requested Delivery Date. Verification done in OrderPromising Handler.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingHandler')]
    [Scope('OnPrem')]
    procedure CalculateAvailabilityAndCapabilityAfterPostingItemJournalLine()
    var
        Item: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Create and Post Item Journal Line. Create Order Promising with Capable to Promise. Verify Unavailable Quantity, Planned Delivery Date, Requested Delivery Date.

        // Setup: Create Item and Location. Create and Post Item Journal Line. Create Sales Order with Request Delivery Date.
        Initialize();
        CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random Quantity.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::Purchase, Quantity, Item."No.", LibraryRandom.RandDec(10, 2), Location.Code);  // Use Random Unit Price.
        CreateSalesOrderWithRequestedDeliveryDate(SalesLine, Item."No.", Location.Code, Quantity);

        // Exercise: Open Order Promising Lines Page and Invoke Available to Promise.
        OpenOrderPromisingPage(SalesLine."Document No.");

        // Verify: Unavailable Quantity, Planned Delivery Date, Requested Delivery Date. Verification done in OrderPromising Handler.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingHandler')]
    [Scope('OnPrem')]
    procedure CalculateAvailabilityAndCapabilityAfterPostingItemJournalLineWithReserveQuantity()
    var
        Item: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Create and Post Item Journal Line. Create Order Promising with Capable to Promise and Item Reserved as Always. Verify Unavailable Quantity, Planned Delivery Date, Requested Delivery Date.

        // Setup: Create Item and Location. Create and Post Item Journal Line. Update Item Reserved as Always. Create Sales Order with Request Delivery Date.
        Initialize();
        CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random Quantity.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::Purchase, Quantity, Item."No.", LibraryRandom.RandDec(10, 2), Location.Code);  // Use Random Unit Price.
        Item.Find();
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
        CreateSalesOrderWithRequestedDeliveryDate(SalesLine, Item."No.", Location.Code, Quantity);

        // Exercise: Open Order Promising Lines Page and Invoke Available to Promise.
        OpenOrderPromisingPage(SalesLine."Document No.");

        // Verify: Unavailable Quantity, Planned Delivery Date, Requested Delivery Date. Verification done in OrderPromising Handler.
    end;

    [Test]
    [HandlerFunctions('OrderPromisingHandler')]
    [Scope('OnPrem')]
    procedure OrderPromisingOnSalesOrderWithRequestedDeliveryDate()
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Test to verify Order Promising Line of Sales Order with Requested Delivery Date.

        // Setup: Create Sales Order with Requested Delivery Date.
        Initialize();
        RequestedShipmentDate := true;  // Global Variable used in OrderPromising Handler.
        CapableToPromise := true;  // Global Variable used in OrderPromising Handler.
        CreateItem(Item);
        CreateSalesOrderWithRequestedDeliveryDate(SalesLine, Item."No.", '', LibraryRandom.RandDec(10, 2));  // Use Random Quantity.

        // Exercise: Open Order Promising Lines Page from Sales Order.
        OpenOrderPromisingPage(SalesLine."Document No.");

        // Verify: Order Promising Line.
        VerifyOrderPromisingLine(SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentInSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // Test to check Item Charge Assignment in Sales Return Order.

        // Setup: Create Sales Return Order with Item Charge.
        Initialize();
        ItemNo := CreateSalesDocumentWithItemCharge(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.

        // Exercise: Suggest Item Charge Assignment.
        SalesLine.ShowItemChargeAssgnt();

        // Verify: Verify Item Charge Assignment.
        VerifyItemChargeAssignmentForSales(
          SalesHeader."Document Type", SalesHeader."No.", ItemNo, SalesLine.Quantity, SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentInSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Test to check Item Charge Assignment in Sales Credit Memo.

        // Setup: Create and Post Sales Return Order with Item Charge Assignment and create Sales Credit Memo.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        ItemNo := CreateSalesDocumentWithItemCharge(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Quantity);
        SalesLine.ShowItemChargeAssgnt();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post the Sales Return Order as Shipment.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");

        // Exercise: Get Return Receipt Lines.
        GetReturnReceiptLLine(SalesHeader, DocumentNo);

        // Verify: Verify that Sales Lines and Item Charge Assignment gets copied in Sales Credit Memo.
        VerifySalesLineForItemCharge(SalesHeader."Document Type", SalesHeader."No.", ItemNo, Quantity);
        VerifySalesLineForItemCharge(SalesHeader."Document Type", SalesHeader."No.", SalesLine."No.", SalesLine.Quantity);
        VerifyItemChargeAssignmentForSales(
          SalesHeader."Document Type", SalesHeader."No.", ItemNo, SalesLine.Quantity, SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('CreateReturnRelatedDocumentsReportHandler')]
    [Scope('OnPrem')]
    procedure CreateReturnRelatedDocumentReport()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
    begin
        // Test to check the functionality of Return Related Documents Report.

        // Setup: Create Sales Return Order and Vendor.
        Initialize();
        CreateSalesReturnOrder(SalesLine);
        CreateVendor(Vendor);
        VendorNo := Vendor."No.";  // VendorNo is made Global as it is used in the Handler.

        // Exercise: Run Create Return Related Documents Report.
        RunCreateReturnRelatedDocumentsReport(SalesLine."Document No.");

        // Verify: Verify Sales, Purchase and Purchase Return Orders are created.
        VerifySalesOrder(SalesLine."Sell-to Customer No.");
        VerifyPurchaseDocument(PurchaseHeader."Document Type"::Order, VendorNo);
        VerifyPurchaseDocument(PurchaseHeader."Document Type"::"Return Order", VendorNo);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisByDimMatrixForSalesAmount()
    var
        ItemAnalysisView: Record "Item Analysis View";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        // Test to verify the Sales Amount and Quantity on Sales Analysis By Dim Matrix page.

        // Setup: Create Item Analysis View. Create and post a Sales Order as Ship and Invoice. Open Analysis View List Sales page, invoke Update Item Analysis View.
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        CreateAndPostSalesOrder(SalesHeader, SalesLine);
        Quantity2 := SalesLine.Quantity;  // Quantity is made Global as it is used in handler for verification.
        Amount := SalesLine."Line Amount";  // Amount is made Global as it is used in handler for verification.
        InvokeUpdateItemAnalysisViewOnAnalysisViewListSales(AnalysisViewListSales, ItemAnalysisView.Code);

        // Exercise: Open Sales Analysis By Dimensions page and invoke Show Matrix to open Sales Analysis By Dim Matrix page.
        InvokeShowMatrixOnSalesAnalysisByDimensions(AnalysisViewListSales, SalesLine."No.");

        // Verify: Quantity and Amount on Sales Analysis by Dim Matrix page.
        // Verification is done in SalesAnalysisbyDimMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('DeleteEmptyItemRegistersReportHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DeleteEmptyItemRegistersReportWithNoOption()
    var
        ItemRegister: Record "Item Register";
    begin
        // Test the functionality of Delete Empty Item Registers report with No option for Confirm dialog.

        // Setup: Create and post Sales Order as Invoice after Shipment.
        Initialize();
        CreateAndPostSalesOrderAsInvoiceAfterShipment();
        ItemRegister.FindLast();

        // Exercise: Run Delete empty Item Registers report with No option for Confirm dialog.
        RunDeleteEmptyItemRegistersReport(ItemRegister."No.");

        // Verify: Item Registers does not gets deleted.
        ItemRegister.Get(ItemRegister."No.");
    end;

    [Test]
    [HandlerFunctions('DeleteEmptyItemRegistersReportHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteEmptyItemRegistersReportWithYesOption()
    var
        ItemRegister: Record "Item Register";
    begin
        // Test the functionality of Delete Empty Item Registers report with Yes option for Confirm dialog.

        // Setup: Create and post Sales Order as Invoice after Shipment.
        Initialize();
        CreateAndPostSalesOrderAsInvoiceAfterShipment();
        ItemRegister.FindLast();

        // Exercise: Run Delete empty Item Registers report with Yes option for Confirm dialog.
        RunDeleteEmptyItemRegistersReport(ItemRegister."No.");

        // Verify: Item Registers gets deleted.
        Assert.IsFalse(ItemRegister.Get(ItemRegister."No."), StrSubstNo(ItemRegisterMustBeDeletedError));
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesHandler')]
    [Scope('OnPrem')]
    procedure ChangeItemChargeQtyInSalesLineWithAssignedCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        ItemChargeQtyDelta: Decimal;
        ItemChargeUnitPrice: Decimal;
    begin
        // [FEATURE] [Sales Order] [Item Charge]
        // [SCENARIO 379725] Quantity on Item Charge line in Sales Order can be altered after the assignment is posted. New quantity of Item Charge can be assigned to and posted correctly with an outstanding quantity on the Item line.
        Initialize();

        // [GIVEN] Sales Line with Item.
        // [GIVEN] Sales Line with Item Charge assigned to the Item. Unit Price of Item Charge = "P".
        ItemChargeUnitPrice := LibraryRandom.RandDec(100, 2);
        CreateSalesDocumentWithItemChargeAndUnitPrice(SalesHeader, SalesLine, ItemNo, ItemChargeUnitPrice);

        // [GIVEN] Set "Qty. Assigned" = "Qty. to Assign" in Item Charge Assignment (mock Item Charge posting).
        SetItemChargeQtyFullyAssigned(SalesLine);
        // [GIVEN] Quantity in Item Charge line is increased by "dQ".
        ItemChargeQtyDelta := LibraryRandom.RandInt(10);
        SalesLine.Validate(Quantity, SalesLine.Quantity + ItemChargeQtyDelta);
        SalesLine.Modify(true);
        SalesLine.ShowItemChargeAssgnt();

        // [WHEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Item Ledger Entry of posted Item contains Value Entry for Item Charge with Sales Amount (Actual) = "P" * "dQ".
        VerifyValueEntryForItemCharge(ItemNo, SalesLine."No.", ItemChargeQtyDelta, ItemChargeUnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantCodeAndUnitPriceAreCopiedFromBlanketSalesOrder()
    var
        BlanketSalesLine: Record "Sales Line";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Blanket Sales Order] [Item Variant]
        // [SCENARIO 380976] Variant Code and Unit Price are copied from Blanket Sales Order to Sales Order.
        Initialize();

        // [GIVEN] Blanket Sales Order Line "BSO" with Variant Code "V" and Unit Price "UP".
        // [GIVEN] Sales Order with same Customer and Item as in "BSO".
        CreateSalesBlanketOrderAndSalesOrderWithVariant(BlanketSalesLine, SalesLine);
        // [WHEN] Select "Blanket Order Line No." = "BSO" on Sales Order Line.
        SalesLine.Validate("Blanket Order No.", BlanketSalesLine."Document No.");
        SalesLine.Validate("Blanket Order Line No.", BlanketSalesLine."Line No.");
        // [THEN] Variant Code on Sales Order Line = "V".
        // [THEN] Unit Price on Sales Order Line = "UP".
        SalesLine.TestField("Variant Code", BlanketSalesLine."Variant Code");
        SalesLine.TestField("Unit Price", BlanketSalesLine."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantCodeAndUnitCostAreCopiedFromBlanketPurchaseOrder()
    var
        BlanketPurchaseLine: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Blanket Purchase Order] [Item Variant]
        // [SCENARIO 380976] Variant Code and Unit Cost are copied from Blanket Purchase Order to Purchase Order.
        Initialize();

        // [GIVEN] Blanket Purchase Order Line "BPO" with Variant Code "V" and Unit Cost "UC".
        // [GIVEN] Purchase Order Line with same Vendor and Item as in "BPO".
        CreatePurchBlanketOrderAndPurchOrderWithVariant(BlanketPurchaseLine, PurchaseLine);
        // [WHEN] Select "Blanket Order Line No." = "BPO" on Purchase Order Line.
        PurchaseLine.Validate("Blanket Order No.", BlanketPurchaseLine."Document No.");
        PurchaseLine.Validate("Blanket Order Line No.", BlanketPurchaseLine."Line No.");
        // [THEN] Variant Code on Purchase Order Line = "V".
        // [THEN] Unit Cost on Purchase Order Line = "UC".
        PurchaseLine.TestField("Variant Code", BlanketPurchaseLine."Variant Code");
        PurchaseLine.TestField("Unit Cost", BlanketPurchaseLine."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemChargeAmountToAssignCorrespondsQtyToAssignInSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        SalesLineCharge: Record "Sales Line";
        SalesLineItem: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Item Charge] [Sales]
        // [SCENARIO 211143] Amount to Assign on item charge assignment should be equal to Qty. to Assign multiplied by Unit Price when the sales order is released.
        Initialize();

        // [GIVEN] Sales order with item line and item charge line.
        // [GIVEN] Quantity on the item charge line = "Q", Unit Price = "X".
        ItemNo := CreateSalesDocumentWithItemCharge(
            SalesHeader, SalesLineCharge, SalesHeader."Document Type"::Order, LibraryRandom.RandInt(100));
        FindSalesLine(SalesLineItem, SalesHeader."Document Type", SalesHeader."No.", SalesLineItem.Type::Item, ItemNo);

        // [GIVEN] Half of the item charge quantity ("q" = "Q" / 2) is assigned to the item line.
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineCharge, ItemChargeAssignmentSales."Applies-to Doc. Type"::Order,
          SalesLineItem."Document No.", SalesLineItem."Line No.", SalesLineItem."No.");
        ItemChargeAssignmentSales.Validate("Qty. to Assign", Round(ItemChargeAssignmentSales."Qty. to Assign" / 2, 0.01));
        ItemChargeAssignmentSales.Modify(true);

        // [GIVEN] Qty. to Ship on the item charge line is set to "q".
        SalesLineCharge.Validate("Qty. to Ship", ItemChargeAssignmentSales."Qty. to Assign");
        SalesLineCharge.Modify(true);

        // [WHEN] Release the sales order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] Amount to Assign on item charge assignment is equal to "q" * "X".
        ItemChargeAssignmentSales.Find();
        Assert.AreNearlyEqual(
          ItemChargeAssignmentSales."Qty. to Assign" * SalesLineCharge."Unit Price",
          ItemChargeAssignmentSales."Amount to Assign", LibraryERM.GetAmountRoundingPrecision(),
          AmountToAssignItemChargeErr);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentPurchaseAndMultilineSalePostShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 256996] Purchase order linked to a multiline sales order via drop shipment link should not be updated when posting the sales order if the drop shipment line is not posted

        Initialize();

        // [GIVEN] Sales order with two lines. The first line has "Drop Shipment" purchasing code, the second does not
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithPurchasingCode(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        // [GIVEN] Create a purchase order associated with the sales order.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [GIVEN] Set "Quantity to Ship" = 0 on the first sales line (drop shipment)
        UpdateQtyToShipOnSalesLine(SalesLine[1], 0);

        // [WHEN] Post shipment from the sales order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Linked purchase order is not updated, since drop shipment line is skipped during posting
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Receive, false);

        // [GIVEN] Set "Quantity to Ship" = "X" > 0 on sales line
        UpdateQtyToShipOnSalesLine(SalesLine[1], SalesLine[1].Quantity);

        // [WHEN] Post receipt from the sales order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Receipt is posted in the linked purchase order
        PurchaseLine.Find();
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentMultilinePurchaseAndSalePostReceipt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 256996] Sales order linked to a multiline purchase order via drop shipment link should not be updated when posting the purchase order if the drop shipment line is not posted

        Initialize();

        // [GIVEN] Sales order with one line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader);

        // [GIVEN] Create a purchase order associated with the sales order via drop shipment.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        GetDropShipmentLine(PurchaseLine[1], PurchaseHeader);

        // [GIVEN] Create another line in the same purchase order without drop shipment link
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        // [GIVEN] Set "Quantity to Receive" = 0 in the purchase line associated with the sales order
        UpdateQtyToReceiveOnPurchaseLine(PurchaseLine[1], 0);

        // [WHEN] Post receipt from the purchase order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Sales order is not updated, since drop shipment line is skipped
        SalesHeader.Find();
        SalesHeader.TestField(Ship, false);

        // [GIVEN] Set "Quantity to Receive" = "X" > 0 on purchase line
        UpdateQtyToReceiveOnPurchaseLine(PurchaseLine[1], PurchaseLine[1].Quantity);

        // [WHEN] Post receipt from the purchase order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Shipment is posted in the linked sales order
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentPurchaseAndMultilineSalePostInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [Invoice]
        // [SCENARIO 256996] Purchase order linked to a multiline sales order via drop shipment link should be updated when invoicing the sales order

        Initialize();

        // [GIVEN] Sales order with two lines. The first line has "Drop Shipment" purchasing code, the second does not
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithPurchasingCode(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        // [GIVEN] Create a purchase order associated with the sales order.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [GIVEN] Post purchase receipt from the purchase order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set "Quantity to Invoice" = 0 on the sales line associated with the drop shipment and post the purchase invoice
        UpdateQtyToInvoiceOnSalesLine(SalesLine[1], 0);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Set "Quantity to Invoice" = "X" > 0 on the sales line associated with the drop shipment
        UpdateQtyToInvoiceOnSalesLine(SalesLine[1], SalesLine[1].Quantity);

        // [GIVEN] Post invoice from the sales order
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Drop shipment link is removed from the associated purchase line
        PurchaseLine.Find();
        PurchaseLine.TestField("Sales Order No.", '');
        PurchaseLine.TestField("Sales Order Line No.", 0);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentMultilinePurchaseAndSalePostInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [Invoice]
        // [SCENARIO 256996] Multiline purchase order linked to a sales order via drop shipment link should be updated when invoicing the sales order

        Initialize();

        // [GIVEN] Sales order with one line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader);

        // [GIVEN] Create a purchase order associated with the sales order via drop shipment.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        GetDropShipmentLine(PurchaseLine[1], PurchaseHeader);

        // [GIVEN] Create another line in the same purchase order without drop shipment link
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        // [GIVEN] Post purchase receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Set "Quantity to Invoice" = 0 on the sales line associated with the drop shipment and post the purchase invoice
        UpdateQtyToInvoiceOnPurchaseLine(PurchaseLine[1], 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Post sales invoice
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Drop shipment link is removed from the associated purchase line
        PurchaseLine[1].Find();
        PurchaseLine[1].TestField("Sales Order No.", '');
        PurchaseLine[1].TestField("Sales Order Line No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemChargeIsSynchronizedWithPurchOrderWhenPostingPurchInvoice()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoiceItem: Record "Purchase Line";
        PurchaseLineInvoiceCharge: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ReceiptNo: Code[20];
    begin
        // [FEATURE] [Item Charge] [Purchase] [Order] [Invoice]
        // [SCENARIO 308577] Item charge assignment is synchronized to purchase order after it has been assigned on purchase invoice line created with "Get Receipt Lines" function.
        Initialize();

        // [GIVEN] Item "I", item charge "C".
        CreateVendor(Vendor);
        CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Purchase order with two lines - for item "I" and charge "C".
        // [GIVEN] Post the purchase order with "Receive" option.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(
          PurchaseHeaderOrder, PurchaseLineOrder, PurchaseLineOrder.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        CreatePurchaseLine(
          PurchaseHeaderOrder, PurchaseLineOrder, PurchaseLineOrder.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Purchase invoice with the same vendor.
        // [GIVEN] Populate the invoice lines using "Get Receipt Lines" function.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        GetReceiptLine(PurchaseHeaderInvoice, ReceiptNo);

        // [GIVEN] Two invoice lines are created.
        FindPurchaseLine(
          PurchaseLineInvoiceItem, PurchaseHeaderInvoice."Document Type", PurchaseHeaderInvoice."No.",
          PurchaseLineInvoiceItem.Type::Item, Item."No.");
        FindPurchaseLine(
          PurchaseLineInvoiceCharge, PurchaseHeaderInvoice."Document Type", PurchaseHeaderInvoice."No.",
          PurchaseLineInvoiceCharge.Type::"Charge (Item)", ItemCharge."No.");

        // [GIVEN] Assign item charge "C" to the invoice line with item "I".
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineInvoiceCharge,
          PurchaseLineInvoiceItem."Document Type", PurchaseLineInvoiceItem."Document No.",
          PurchaseLineInvoiceItem."Line No.", PurchaseLineInvoiceItem."No.");

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [THEN] "Qty. Assigned" is updated on the purchase order line for item charge.
        FindPurchaseLine(
          PurchaseLineOrder, PurchaseHeaderOrder."Document Type", PurchaseHeaderOrder."No.",
          PurchaseLineOrder.Type::"Charge (Item)", ItemCharge."No.");
        PurchaseLineOrder.CalcFields("Qty. Assigned");
        PurchaseLineOrder.TestField("Qty. Assigned", ItemChargeAssignmentPurch."Qty. to Assign");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemChargeInSeparateReceiptSynchronizedWithSourceSalesReturnOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        SalesHeaderReturn: Record "Sales Header";
        SalesLineReturn: array[2] of Record "Sales Line";
        SalesHeaderCrMemo: Record "Sales Header";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
        ReturnReceiptNo: array[2] of Code[20];
    begin
        // [FEATURE] [Item Charge] [Sales] [Return Order] [Credit Memo] [Receipt] [Get Return Receipt Lines]
        // [SCENARIO 311644] Posting the credit memo of item charge received in a separate document from the item, synchronizes the item charge assignment to the source sales return order.
        Initialize();

        // [GIVEN] Item "I", item charge "C".
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Sales return order with two lines - "I" and "C".
        // [GIVEN] Assign item charge to the item line.
        LibrarySales.CreateSalesHeader(SalesHeaderReturn, SalesHeaderReturn."Document Type"::"Return Order", Customer."No.");
        CreateSalesLine(
          SalesLineReturn[1], SalesHeaderReturn, SalesLineReturn[1].Type::Item, Item."No.", LibraryRandom.RandInt(10));
        CreateSalesLine(
          SalesLineReturn[2], SalesHeaderReturn, SalesLineReturn[2].Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineReturn[2], SalesLineReturn[1]."Document Type", SalesLineReturn[1]."Document No.",
          SalesLineReturn[1]."Line No.", Item."No.");

        // [GIVEN] Set "Return Qty. to Receive" = 0 on the item charge line.
        SalesLineReturn[2].Validate("Return Qty. to Receive", 0);
        SalesLineReturn[2].Modify(true);

        // [GIVEN] Receive the item line.
        ReturnReceiptNo[1] := LibrarySales.PostSalesDocument(SalesHeaderReturn, true, false);

        // [GIVEN] Receive the item charge line.
        SalesHeaderReturn.Find();
        ReturnReceiptNo[2] := LibrarySales.PostSalesDocument(SalesHeaderReturn, true, false);

        // [GIVEN] Create sales credit memo for both receipts with the help of "Get Return Receipts lines".
        LibrarySales.CreateSalesHeader(SalesHeaderCrMemo, SalesHeaderCrMemo."Document Type"::"Credit Memo", Customer."No.");
        ReturnReceiptLine.SetFilter("Document No.", '%1|%2', ReturnReceiptNo[1], ReturnReceiptNo[2]);
        SalesGetReturnReceipts.SetSalesHeader(SalesHeaderCrMemo);
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);

        // [WHEN] Post the credit memo.
        SalesHeaderCrMemo.Find();
        LibrarySales.PostSalesDocument(SalesHeaderCrMemo, true, true);

        // [THEN] Item charge on the sales return order is fully assigned.
        SalesLineReturn[2].Find();
        SalesLineReturn[2].CalcFields("Qty. Assigned");
        SalesLineReturn[2].TestField("Qty. Assigned", SalesLineReturn[2].Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemChargeInSeparateShipmentSynchronizedWithSourcePurchReturnOrder()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeaderReturn: Record "Purchase Header";
        PurchaseLineReturn: array[2] of Record "Purchase Line";
        PurchaseHeaderCrMemo: Record "Purchase Header";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
        ReturnShipmentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Item Charge] [Purchase] [Return Order] [Credit Memo] [Shipment] [Get Return Shipment Lines]
        // [SCENARIO 311644] Posting the credit memo of item charge shipped in a separate document from the item, synchronizes the item charge assignment to the source purchase return order.
        Initialize();

        // [GIVEN] Item "I", item charge "C".
        LibraryPurchase.CreateVendor(Vendor);
        CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Purchase return order with two lines - "I" and "C".
        // [GIVEN] Assign item charge to the item line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderReturn, PurchaseHeaderReturn."Document Type"::"Return Order", Vendor."No.");
        CreatePurchaseLine(
          PurchaseHeaderReturn, PurchaseLineReturn[1], PurchaseLineReturn[1].Type::Item, Item."No.", LibraryRandom.RandInt(10));
        CreatePurchaseLine(
          PurchaseHeaderReturn, PurchaseLineReturn[2], PurchaseLineReturn[2].Type::"Charge (Item)", ItemCharge."No.",
          LibraryRandom.RandInt(10));
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineReturn[2], PurchaseLineReturn[1]."Document Type", PurchaseLineReturn[1]."Document No.",
          PurchaseLineReturn[1]."Line No.", Item."No.");

        // [GIVEN] Set "Return Qty. to Ship" = 0 on the item charge line.
        PurchaseLineReturn[2].Validate("Return Qty. to Ship", 0);
        PurchaseLineReturn[2].Modify(true);

        // [GIVEN] Receive the item line.
        ReturnShipmentNo[1] := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderReturn, true, false);

        // [GIVEN] Receive the item charge line.
        PurchaseHeaderReturn.Find();
        ReturnShipmentNo[2] := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderReturn, true, false);

        // [GIVEN] Create purchase credit memo for both shipments with the help of "Get Return Shipment lines".
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderCrMemo, PurchaseHeaderCrMemo."Document Type"::"Credit Memo", Vendor."No.");
        ReturnShipmentLine.SetFilter("Document No.", '%1|%2', ReturnShipmentNo[1], ReturnShipmentNo[2]);
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeaderCrMemo);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);

        // [WHEN] Post the credit memo.
        PurchaseHeaderCrMemo.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, true, false);

        // [THEN] Item charge on the purchase return order is fully assigned.
        PurchaseLineReturn[2].Find();
        PurchaseLineReturn[2].CalcFields("Qty. Assigned");
        PurchaseLineReturn[2].TestField("Qty. Assigned", PurchaseLineReturn[2].Quantity);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    procedure SalesOrderPostingDateAfterDropShipmentPurchaseReceive()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [Receipt] [Posting Date]
        // [SCENARIO 390141] Posting Date on Sales Order is updated after posting receive on Purchase Line linked via Drop Shipment.
        Initialize();
        LinkDocDateToPostingDateSalesSetup(false);

        // [GIVEN] Sales order with Posting Date "28-01-2023" with Drop Shipment sales line
        // [GIVEN] Document Date = "27-01-2023".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Document Date", WorkDate() - 1);
        SalesHeader.Modify(true);
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader);

        // [GIVEN] Create a purchase order associated with the sales order via drop shipment with Posting Date "15-02-2023".
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDate(30));
        PurchaseHeader.Modify(true);
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Post purchase receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Sales Order has Posting Date updated to "15-02-2023".
        // [THEN] The Document Date retains "27-01-2023".
        SalesHeader.Find();
        SalesHeader.TestField("Posting Date", PurchaseHeader."Posting Date");
        SalesHeader.TestField("Document Date", WorkDate() - 1);
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    procedure PurchaseOrderPostingDateAfterDropShipmentSalesShip()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [Shipment] [Posting Date]
        // [SCENARIO 390141] Posting Date on Sales Order is updated after posting receive on Purchase Line linked via Drop Shipment.
        Initialize();
        LinkDocDateToPostingDatePurchSetup(false);

        // [GIVEN] Sales order with Posting Date "15-02-2023" with Drop Shipment sales line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Posting Date", LibraryRandom.RandDate(30));
        SalesHeader.Modify(true);
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader);

        // [GIVEN] Create a purchase order associated with the sales order via drop shipment with Posting Date "28-01-2023".
        // [GIVEN] Document Date = "27-01-2023".
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Validate("Document Date", WorkDate() - 1);
        PurchaseHeader.Modify(true);
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Post sales shipment.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Purchase Order has Posting Date updated to "15-02-2023".
        // [THEN] The Document Date retains "27-01-2023".
        PurchaseHeader.Find();
        PurchaseHeader.TestField("Posting Date", SalesHeader."Posting Date");
        PurchaseHeader.TestField("Document Date", WorkDate() - 1);
    end;

    [Test]
    procedure ItemChargeAssignmentPurchClearQtyAndAmountBeforeDistribution()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // [FEATURE] [Purchase] [Item Charge] [Suggest Assignment]
        // [SCENARIO 400286] "Qty. to Assign" and "Amount to Assign" is cleared on item charge assignment for purchase before new distribution.
        Initialize();

        // [GIVEN] Purchase order with two item lines "1", "2" and an item charge line "3".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine[1], PurchaseLine[1].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine[2], PurchaseLine[2].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine[3], PurchaseLine[3].Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(),
          LibraryRandom.RandInt(10));
        PurchaseLine[3].Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine[3].Modify(true);

        // [GIVEN] Create item charge assignment.
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine[3], PurchaseLine[1]."Document Type", PurchaseLine[1]."Document No.",
          PurchaseLine[1]."Line No.", PurchaseLine[1]."No.");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine[3], PurchaseLine[2]."Document Type", PurchaseLine[2]."Document No.",
          PurchaseLine[2]."Line No.", PurchaseLine[2]."No.");

        // [GIVEN] Distribute item charge equally to item lines "1" and "2" by using "Suggest item charge assignment" function.
        ItemChargeAssgntPurch.AssignItemCharges(
          PurchaseLine[3], PurchaseLine[3].Quantity, PurchaseLine[3].Amount, ItemChargeAssgntPurch.AssignEquallyMenuText());

        // [GIVEN] Receive and invoice item line "1".
        UpdateQtyToReceiveOnPurchaseLine(PurchaseLine[2], 0);
        UpdateQtyToReceiveOnPurchaseLine(PurchaseLine[3], 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run "Suggest item charge assignment" again.
        PurchaseLine[3].Find();
        ItemChargeAssgntPurch.AssignItemCharges(
          PurchaseLine[3], PurchaseLine[3].Quantity, PurchaseLine[3].Amount, ItemChargeAssgntPurch.AssignEquallyMenuText());

        // [THEN] "Qty. to Assign" and "Amount to Assign" for the invoiced line "1" have been reset to 0.
        FindItemChargeAssignmentPurch(ItemChargeAssignmentPurch, PurchaseLine[1]);
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", 0);
        ItemChargeAssignmentPurch.TestField("Amount to Assign", 0);

        // [THEN] Full item charge quantity and amount are assigned to line "2".
        FindItemChargeAssignmentPurch(ItemChargeAssignmentPurch, PurchaseLine[2]);
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", PurchaseLine[3].Quantity);
        ItemChargeAssignmentPurch.TestField("Amount to Assign", PurchaseLine[3].Amount);
    end;

    [Test]
    procedure ItemChargeAssignmentSalesClearQtyAndAmountBeforeDistribution()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        // [FEATURE] [Sales] [Item Charge] [Suggest Assignment]
        // [SCENARIO 400286] "Qty. to Assign" and "Amount to Assign" is cleared on item charge assignment for sales before new distribution.
        Initialize();

        // [GIVEN] Sales order with two item lines "1", "2" and an item charge line "3".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(
          SalesLine[1], SalesHeader, SalesLine[1].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        CreateSalesLine(
          SalesLine[3], SalesHeader, SalesLine[3].Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(),
          LibraryRandom.RandInt(10));
        SalesLine[3].Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine[3].Modify(true);

        // [GIVEN] Create item charge assignment.
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine[3], SalesLine[1]."Document Type", SalesLine[1]."Document No.",
          SalesLine[1]."Line No.", SalesLine[1]."No.");
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine[3], SalesLine[2]."Document Type", SalesLine[2]."Document No.",
          SalesLine[2]."Line No.", SalesLine[2]."No.");

        // [GIVEN] Distribute item charge equally to item lines "1" and "2" by using "Suggest item charge assignment" function.
        ItemChargeAssgntSales.AssignItemCharges(
          SalesLine[3], SalesLine[3].Quantity, SalesLine[3].Amount, ItemChargeAssgntSales.AssignEquallyMenuText());

        // [GIVEN] Ship and invoice item line "1".
        UpdateQtyToShipOnSalesLine(SalesLine[2], 0);
        UpdateQtyToShipOnSalesLine(SalesLine[3], 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run "Suggest item charge assignment" again.
        SalesLine[3].Find();
        ItemChargeAssgntSales.AssignItemCharges(
          SalesLine[3], SalesLine[3].Quantity, SalesLine[3].Amount, ItemChargeAssgntSales.AssignEquallyMenuText());

        // [THEN] "Qty. to Assign" and "Amount to Assign" for the invoiced line "1" have been reset to 0.
        FindItemChargeAssignmentSales(ItemChargeAssignmentSales, SalesLine[1]);
        ItemChargeAssignmentSales.TestField("Qty. to Assign", 0);
        ItemChargeAssignmentSales.TestField("Amount to Assign", 0);

        // [THEN] Full item charge quantity and amount are assigned to line "2".
        FindItemChargeAssignmentSales(ItemChargeAssignmentSales, SalesLine[2]);
        ItemChargeAssignmentSales.TestField("Qty. to Assign", SalesLine[3].Quantity);
        ItemChargeAssignmentSales.TestField("Amount to Assign", SalesLine[3].Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ResetItemChargeAssignmentOnChangeVendor()
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        // [FEATURE] [Item Charge] [Purchase] [Order]
        // [SCENARIO 405932] "Qty. to Assign" and "Amount to Assign" are reset to zero when you change vendor no. in purchase order.
        Initialize();

        // [GIVEN] Item charge.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Purchase order with an item line and an item charge line.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLineItem, PurchaseHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLineCharge, PurchaseLineCharge.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Assign item charge to the item line.
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineCharge, PurchaseLineItem."Document Type", PurchaseLineItem."Document No.",
          PurchaseLineItem."Line No.", PurchaseLineItem."No.");

        // [WHEN] Change vendor no. in the purchase order.
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());

        // [THEN] Quantity and amount to assign are reset to 0.
        ItemChargeAssignmentPurch.Find();
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", 0);
        ItemChargeAssignmentPurch.TestField("Amount to Assign", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ResetItemChargeAssignmentOnChangeCustomer()
    var
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineCharge: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        // [FEATURE] [Item Charge] [Sales] [Order]
        // [SCENARIO 405932] "Qty. to Assign" and "Amount to Assign" are reset to zero when you change customer no. in sales order.
        Initialize();

        // [GIVEN] Item charge.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Sales order with an item line and an item charge line.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLineItem, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        CreateSalesLine(
          SalesLineCharge, SalesHeader, SalesLineCharge.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Assign item charge to the item line.
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineCharge, SalesLineItem."Document Type", SalesLineItem."Document No.",
          SalesLineItem."Line No.", SalesLineItem."No.");

        // [WHEN] Change customer no. in the sales order.
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] Quantity and amount to assign are reset to 0.
        ItemChargeAssignmentSales.Find();
        ItemChargeAssignmentSales.TestField("Qty. to Assign", 0);
        ItemChargeAssignmentSales.TestField("Amount to Assign", 0);
    end;

    [Test]
    procedure CannotDeleteItemChargeAssignmentSalesForInvoicedCharge()
    var
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
        SalesLineItem: array[2] of Record "Sales Line";
        SalesLineCharge: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        i: Integer;
    begin
        // [FEATURE] [Item Charge] [Sales] [Order]
        // [SCENARIO 439173] Stan cannot delete item charge assignment (sales) when the item charge has already been invoiced.
        Initialize();

        // [GIVEN] Item charge.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Sales order with two item lines and an item charge line.
        // [GIVEN] Assign the item charge evenly to the item lines.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(
          SalesLineCharge, SalesHeader, SalesLineCharge.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        for i := 1 to 2 do begin
            CreateSalesLine(
              SalesLineItem[i], SalesHeader, SalesLineItem[i].Type::Item, LibraryInventory.CreateItemNo(),
              LibraryRandom.RandInt(10));
            LibraryInventory.CreateItemChargeAssignment(
              ItemChargeAssignmentSales, SalesLineCharge, SalesLineItem[i]."Document Type", SalesLineItem[i]."Document No.",
              SalesLineItem[i]."Line No.", SalesLineItem[i]."No.");
            ItemChargeAssignmentSales.Validate("Qty. to Assign", SalesLineCharge.Quantity / 2);
            ItemChargeAssignmentSales.Modify(true);
        end;

        // [GIVEN] Set "Qty. to Ship" = 0 on the item charge line and ship the item lines.
        UpdateQtyToShipOnSalesLine(SalesLineCharge, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set "Qty. to Invoice" on the second item line and post the sales order.
        UpdateQtyToInvoiceOnSalesLine(SalesLineItem[2], 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Try to delete the item charge assignment.
        ItemChargeAssignmentSales.Find();
        asserterror ItemChargeAssignmentSales.Delete(true);

        // [THEN] Error. Cannot delete assignment when the item charge is invoiced.
        Assert.ExpectedError(QtyToInvoiceMustHaveValueErr);
    end;

    [Test]
    procedure CannotDeleteItemChargeAssignmentPurchForInvoicedCharge()
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineItem: array[2] of Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        i: Integer;
    begin
        // [FEATURE] [Item Charge] [Purchase] [Order]
        // [SCENARIO 439173] Stan cannot delete item charge assignment (purchase) when the item charge has already been invoiced.
        Initialize();

        // [GIVEN] Item charge.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Purchase order with two item lines and an item charge line.
        // [GIVEN] Assign the item charge evenly to the item lines.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLineCharge, PurchaseLineCharge.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        for i := 1 to 2 do begin
            CreatePurchaseLine(
              PurchaseHeader, PurchaseLineItem[i], PurchaseLineItem[i].Type::Item, LibraryInventory.CreateItemNo(),
              LibraryRandom.RandInt(10));
            LibraryInventory.CreateItemChargeAssignPurchase(
              ItemChargeAssignmentPurch, PurchaseLineCharge, PurchaseLineItem[i]."Document Type", PurchaseLineItem[i]."Document No.",
              PurchaseLineItem[i]."Line No.", PurchaseLineItem[i]."No.");
            ItemChargeAssignmentPurch.Validate("Qty. to Assign", PurchaseLineCharge.Quantity / 2);
            ItemChargeAssignmentPurch.Modify(true);
        end;

        // [GIVEN] Set "Qty. to Receive" = 0 on the item charge line and receive the item lines.
        UpdateQtyToReceiveOnPurchaseLine(PurchaseLineCharge, 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Set "Qty. to Invoice" on the second item line and post the purchase order.
        UpdateQtyToInvoiceOnPurchaseLine(PurchaseLineItem[2], 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Try to delete the item charge assignment.
        ItemChargeAssignmentPurch.Find();
        asserterror ItemChargeAssignmentPurch.Delete(true);

        // [THEN] Error. Cannot delete assignment when the item charge is invoiced.
        Assert.ExpectedError(QtyToInvoiceMustHaveValueErr);
    end;

    [Test]
    [HandlerFunctions('GetLastUnitPriceHandler')]
    [Scope('OnPrem')]
    procedure VerifySelectedUnitPriceFromGetPriceIsUpdatedInSalesOrderLine()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        NewSalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        UpdatedUnitPrice: Decimal;
    begin
        // [SCENARIO 470284] Verify Selected Unit Price From Get Price is Updated in Sales Order Line
        // When the Lines Subform is sorted on Unit Price Excl. Tax
        Initialize();

        // [GIVEN] Create a new Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create an Item with a Unit Price and a Unit Cost.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandInt(200), LibraryRandom.RandInt(200));

        // [GIVEN] Create a Sales Price for an item.
        LibrarySales.CreateSalesPrice(
            SalesPrice,
            Item."No.",
            SalesPrice."Sales Type"::Customer,
            Customer."No.",
            0D,
            '',
            '',
            Item."Base Unit of Measure",
            LibraryRandom.RandInt(0),
            LibraryRandom.RandIntInRange(300, 400));

        // [GIVEN] Create a new Sales Price for an item.
        LibrarySales.CreateSalesPrice(
            NewSalesPrice,
            Item."No.",
            NewSalesPrice."Sales Type"::Customer,
            Customer."No.",
            0D,
            '',
            '',
            Item."Base Unit of Measure",
            LibraryRandom.RandIntInRange(2, 3),
            LibraryRandom.RandIntInRange(400, 500));

        // [GIVEN] Create a Sales Order for the new Customer.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create a sales line for each item.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(4, 10));

        // [WHEN] Update the new sales price of the item.
        LibraryVariableStorage.Enqueue(NewSalesPrice."Minimum Quantity");
        UpdatedUnitPrice := SortUnitPriceInSalesOrderLineAndGetUpdatedUnitPrice(SalesHeader);

        // [VERIFY] Verify Selected Unit Price from Get Price is Updated in Sales Order Line.
        Assert.AreEqual(
            NewSalesPrice."Unit Price",
            UpdatedUnitPrice,
            StrSubstNo(
                CostError,
                SalesLine.FieldCaption("Unit Price"),
                NewSalesPrice."Unit Price",
                SalesLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler')]
    procedure OrderNoIsSetOnSalesInvoiceHeaderIfAllLinesBelongToTheSameSalesOrder()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader, SalesHeaderInvoice : Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Order No. is set on the Sales Invoice Header when all the lines belong to the same Sales Order.
        Initialize();

        // [GIVEN] Create Customer and Item.
        CustomerNo := LibrarySales.CreateCustomerNo();
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Add item to the inventory.
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, 10, ItemNo, 1, '');

        // [GIVEN] Create Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, CustomerNo, ItemNo, 10);

        // [GIVEN] Posting Sales Shipment multiple times creates multiple Sales Shipment Lines.
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create Sales Invoice via Get Shipment Lines.
        GetShipmentLineInSalesInvoice(SalesHeaderInvoice, CustomerNo);

        // [WHEN] Post the Sales Invoice.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true));

        // [THEN] Sales Invoice Header has Order No. set.
        SalesInvoiceHeader.TestField("Order No.", SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentLinesPageHandler,PostedSalesInvoiceLinesPageHandler')]
    procedure DrillDownOnQtyShippedShowsPostedShipmentLines()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] DrillDown on the 'Qty. Shipped' shows the posted shipment lines associated with.
        Initialize();

        // [GIVEN] Create Customer and Item.
        CustomerNo := LibrarySales.CreateCustomerNo();
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Add item to the inventory.
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, 10, ItemNo, 1, '');

        // [GIVEN] Create Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, CustomerNo, ItemNo, 10);

        // [GIVEN] Posting Sales Shipment multiple times creates multiple Sales Shipment Lines.
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Validate("Qty. to Invoice", 2);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Validate("Qty. to Invoice", 2);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Validate("Qty. to Invoice", 2);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Open Sales Order
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        // [WHEN] DrillDown on the 'Qty. Shipped' field.
        SalesOrder.SalesLines."Quantity Shipped".Drilldown();

        // [THEN] Posted Sales Shipment Lines page is opened and related lines are shown.
        Assert.AreEqual(3, LibraryVariableStorage.DequeueInteger(), 'Expected number of lines not found in Posted Sales Shipment Lines page.');

        // [WHEN] DrillDown on the 'Qty. Invoiced' field.
        SalesOrder.SalesLines."Quantity Invoiced".Drilldown();

        // [THEN] Posted Sales Invoice Lines page is opened and related lines are shown.
        Assert.AreEqual(3, LibraryVariableStorage.DequeueInteger(), 'Expected number of lines not found in Posted Sales Invoice Lines page.');
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesHandlerNew')]
    procedure DeleteUnpostedSalesLineifAnotherSalesLineIsLinkedToPostedItemCharge()
    var
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
    begin
        // [SCENARIO 483458] Verify that it is possible to delete the unposted sales line if another sales line is linked to the posted item charge.
        Initialize();

        // [GIVEN] Create a Item Charge.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Create a Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [GIVEN] Create a sales line with type = "Item".
        CreateSalesLine(
            SalesLine[1],
            SalesHeader,
            SalesLine[1].Type::Item,
            LibraryInventory.CreateItemNo(),
            LibraryRandom.RandInt(10));

        // [GIVEN] Create another sales line with type = "Item".
        CreateSalesLine(
            SalesLine[2],
            SalesHeader,
            SalesLine[2].Type::Item,
            LibraryInventory.CreateItemNo(),
            LibraryRandom.RandInt(10));

        // [GIVEN] Create another sales line with type = "Charge Item".
        CreateSalesLine(
            SalesLine[3],
            SalesHeader,
            SalesLine[3].Type::"Charge (Item)",
            ItemCharge."No.",
            SalesLine[2].Quantity);

        // [GIVEN] Create and assign the quanity.
        LibraryVariableStorage.Enqueue(SalesLine[2]);
        LibraryVariableStorage.Enqueue(SalesLine[2].Quantity);
        SalesLine[3].ShowItemChargeAssgnt();

        // [GIVEN] Update the "Qty. to Ship" to 0 in the first sales line.
        UpdateQtyToShipOnSalesLine(SalesLine[1], 0);

        // [GIVEN] Post the sales document.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Reopen the sales document.
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Delete the first sales line.
        SalesLine[1].Find();
        SalesLine[1].Delete(true);

        // [VERIFY] Verify that it is possible to delete the first sales line.
        SalesLine[1].SetRange("Document No.", SalesHeader."No.");
        Assert.RecordCount(SalesLine[1], LibraryRandom.RandIntInRange(2, 2));
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchaseHandlerNew')]
    procedure DeleteUnpostedPurchaseLineifAnotherPurchaseLineIsLinkedToPostedItemCharge()
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
    begin
        // [SCENARIO 483458] Verify that it is possible to delete the unposted Purchase line if another purchase line is linked to the posted item charge.
        Initialize();

        // [GIVEN] Create a Item Charge.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [GIVEN] Create a purchase line with type = "Item".
        CreatePurchaseLine(
            PurchaseHeader,
            PurchaseLine[1],
            PurchaseLine[1].Type::Item,
            LibraryInventory.CreateItemNo(),
            LibraryRandom.RandInt(10));

        // [GIVEN] Create another purchase line with type = "Item".
        CreatePurchaseLine(
            PurchaseHeader,
            PurchaseLine[2],
            PurchaseLine[2].Type::Item,
            LibraryInventory.CreateItemNo(),
            LibraryRandom.RandInt(10));

        // [GIVEN] Create another purchase line with type = "Charge Item".
        CreatePurchaseLine(
            PurchaseHeader,
            PurchaseLine[3],
            PurchaseLine[3].Type::"Charge (Item)",
            ItemCharge."No.",
            PurchaseLine[2].Quantity);

        // [GIVEN] Create and assign the quanity.
        LibraryVariableStorage.Enqueue(PurchaseLine[2]);
        LibraryVariableStorage.Enqueue(PurchaseLine[2].Quantity);
        PurchaseLine[3].ShowItemChargeAssgnt();

        // [GIVEN] Update the "Qty. to Receive" to 0 in the first Purchase line.
        UpdateQtyToReceiveOnPurchaseLine(PurchaseLine[1], 0);

        // [GIVEN] Post the Purchase document.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Reopen the Purchase document.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [WHEN] Delete the first Purchase line.
        PurchaseLine[1].Find();
        PurchaseLine[1].Delete(true);

        // [VERIFY] Verify that it is possible to delete the first purchase line.
        PurchaseLine[1].SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine[1], LibraryRandom.RandIntInRange(2, 2));
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    procedure SalesOrderDocDateAfterDropShipmentPurchaseReceiveWhenLinkDocDateToPostingDateEnabled()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 494663] Receipt Issues when Posting - Doc Date not automatically updated when Post. Date changes due to Drop Shipment
        Initialize();
        LinkDocDateToPostingDateSalesSetup(true);

        // [GIVEN] Sales order with Posting Date including Drop Shipment sales line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Document Date", WorkDate() - 1);
        SalesHeader.Modify(true);
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader);

        // [GIVEN] Create a purchase order associated with the sales order via drop shipment with Posting Date "15-02-2023".
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDate(30));
        PurchaseHeader.Modify(true);
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Post purchase receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [VERIFY] Verify: Sales Order has Posting Date updated to Purchase Order Posting Date and Document Date as Posting Date
        SalesHeader.Find();
        SalesHeader.TestField("Posting Date", PurchaseHeader."Posting Date");
        SalesHeader.TestField("Document Date", SalesHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('SalesListHandler')]
    procedure PurchaseOrderDocDateAfterDropShipmentSalesShipWhenLinkDocDateToPostingDateEnabled()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 494663] Shipment Issues when Posting - Doc Date not automatically updated when Post. Date changes due to Drop Shipment
        Initialize();
        LinkDocDateToPostingDatePurchSetup(true);

        // [GIVEN] Sales order with Posting Date including Drop Shipment sales line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Posting Date", LibraryRandom.RandDate(30));
        SalesHeader.Modify(true);
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader);

        // [GIVEN] Create a purchase order associated with the sales order via drop shipment with Posting Date "28-01-2023".
        CreatePurchaseOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Validate("Document Date", WorkDate() - 1);
        PurchaseHeader.Modify(true);
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Post sales shipment.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [VERIFY] Verify: Purchase Order has Posting Date updated to Sales Order Posting Date and Document Date as Posting Date
        PurchaseHeader.Find();
        PurchaseHeader.TestField("Posting Date", SalesHeader."Posting Date");
        PurchaseHeader.TestField("Document Date", PurchaseHeader."Posting Date");
    end;

    [Test]
    procedure DimensionMustBePulledFromItemAndLocationInPhysicalInventoryJournal()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        DefaultDimension: array[2] of Record "Default Dimension";
        DimensionValue: array[2] of Record "Dimension Value";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [SCENARIO 539893] Default Location Dimensions should be passed to Physical Inventory Journal on Calculate Inventory.
        Initialize();

        // [GIVEN] Create an Item.
        CreateItem(Item);

        // [GIVEN] Create Dimension Value.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);

        // [GIVEN] Create Dimension for Item.
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension[1], Item."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);

        // [GIVEN] Create Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Dimension Value for Location.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDefaultDimension(DefaultDimension[2], Database::Location, Location.Code, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [GIVEN] Post Item in Postive Adjustment in the Location.
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", LibraryRandom.RandDec(15, 2), Item."No.", LibraryRandom.RandDec(100, 2), Location.Code);

        // [GIVEN] Create Item Journal Template for Physical Inventory and Validate No Series.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);

        // [GIVEN] Calculate Inventory For an Item.
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, Item."No.", WorkDate(), false, false);

        // [GIVEN] Find the Item Journal.
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindLast();

        // [GIVEN] Find the Dimension Set Entry from Item Journal Line.
        DimensionSetEntry.SetRange("Dimension Set ID", ItemJournalLine."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue[2]."Dimension Code");
        DimensionSetEntry.FindFirst();

        // [THEN] Dimension Value from Location must be passed into Item Journal Line.
        Assert.AreEqual(
            DimensionValue[2].Code,
            DimensionSetEntry."Dimension Value Code",
            StrSubstNo(
                DimensionErr,
                DimensionValue[2].Code,
                ItemJournalLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('SalesListHandler,GetShipmentLinesPageHandler')]
    procedure VerifyIfCreditMemoPostedInCaseOfDropShipment()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPstdSalesInvYesNo: Codeunit "Correct PstdSalesInv (Yes/No)";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 566857] When creating a Credit Memo for a Sales invoice with Drop Shipment with "correct" the purchase order is not corrected and you cannot post the Sales Order afterwards.
        Initialize();

        // [GIVEN] Create Sales Order with one line has "Drop Shipment" purchasing code.
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Order, '');
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader[1]);

        // [GIVEN] Create a purchase order associated with the sales order.
        CreatePurchaseOrder(PurchaseHeader, SalesHeader[1]."Sell-to Customer No.");
        GetDropShipmentLine(PurchaseLine, PurchaseHeader);

        // [GIVEN] Receive the Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create a Sales Invoice with Get Shipment Line
        GetShipmentLineInSalesInvoice(SalesHeader[2], SalesHeader[1]."Sell-to Customer No.");

        // [GIVEN] Post the Sales Invoice
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader[2], false, true);

        // [WHEN] Open the Posted Sales Invoice
        SalesInvoiceHeader.Get(PostedDocumentNo);

        // [THEN] Create correct Credit Memo
        asserterror CorrectPstdSalesInvYesNo.CorrectInvoice(SalesInvoiceHeader);
        Assert.ExpectedError(StrSubstNo(DropShipmentDocumentExistsErr, PurchaseHeader."No."));
    end;

    [Test]
    [HandlerFunctions('GetPriceLineHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesUnitPriceFromCustomerPriceLineGroup()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // Test and verify Sales Unit Price update from Customer Price Group.
        Initialize();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // Setup: Create Item and Customer with Customer Price Group. Create and release Sales Order. Reopen Sales Order and update Order Date.
        PriceListLine.DeleteAll();
        CreateItem(Item);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateCustomer(Customer, false, CustomerPriceGroup.Code);
        CreateSalesPrice(
          SalesPrice, Item, "Sales Price Type"::"Customer Price Group", Customer."Customer Price Group", Item."Base Unit of Measure",
          0, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // Use random Starting Date.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", LibraryRandom.RandDec(100, 2));  // Use random Quantity.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        UpdateOrderDateOnSalesOrder(SalesHeader, SalesPrice."Starting Date");

        // Exercise: Get Sales Price.
        GetSalesPrice(SalesHeader."No.");

        // Verify: Verify Unit Price on Sales Line.
        VerifyUnitPriceOnSalesLine(SalesLine, SalesPrice."Unit Price");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory - Orders");
        Clear(ConfirmMessage);
        Clear(GetShipmentLines);
        Clear(CalculateInvoiceDiscount);
        Clear(UnavailableQuantity);
        Clear(RequestedDeliveryDate);
        Clear(CapableToPromise);

        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory - Orders");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        NoSeriesSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTemplates.EnableTemplatesFeature();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory - Orders");
    end;

    local procedure CreateAndAssignItemChargeLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Quantity: Decimal; GetShipmentLines2: Boolean)
    begin
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), Quantity);
        GetShipmentLines := GetShipmentLines2; // Use GetShipmentLines as global for handler.
        SalesLine.ShowItemChargeAssgnt();
    end;

    local procedure CreateAndPostItemJournalLine(EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal; ItemNo: Code[20]; UnitAmount: Decimal; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        if LocationCode <> '' then
            ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20]; PostAsInvoice: Boolean): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", Vendor."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(50, 2)); // Taking Random Quantity.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, PostAsInvoice);
        exit(PurchaseLine.Quantity);
    end;

    local procedure CreateAndPostPurchaseOrderWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        UpdateItemDimension(DefaultDimension, Item."No.");
        CreateAndPostPurchaseOrder(Item."No.", true);
    end;

    local procedure CreateAndPostSalesDocument(var Item: Record Item; DocumentType: Enum "Sales Document Type"; PurchaseQuantity: Decimal): Decimal
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateCustomer(Customer, false, '');
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");

        // This is the need of the test as Sales Order Quantity should be less than the Purchase Order Quantity. Also being random at the same time.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", PurchaseQuantity / 2);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine.Quantity);
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        CreateCustomer(Customer, true, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2)); // Use Random Quantity.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesOrderAsInvoiceAfterShipment()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateCustomer(Customer, false, '');
        CreateItem(Item);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);  // Posting it in two times as it is required for the test.
    end;

    local procedure CreateAndPostSalesReturnOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; IsBillToCustomerNo: Boolean): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        if IsBillToCustomerNo then begin
            CreateCustomer(Customer, true, '');
            SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
            SalesHeader.Modify(true);
        end;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndPostSalesReturnOrderForItemCharge(var SalesLine: Record "Sales Line"; SelltoCustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SelltoCustomerNo);
        CreateAndAssignItemChargeLine(SalesLine, SalesHeader, LibraryRandom.RandDec(10, 2), true);  // Take random Quantity.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Post the Sales Order as Ship.
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, SalesLine, CustomerNo, ItemNo, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; CombineShipments: Boolean; CustomerPriceGroupCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Combine Shipments", CombineShipments);
        Customer.Validate("Customer Price Group", CustomerPriceGroupCode);
        Customer.Modify(true);
    end;

    local procedure CreateSalesOrderWithRequestedDeliveryDate(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        RequestedDeliveryDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());  // Global Variable used in OrderPromising Handler. Calculate Random Date.
        CreateCustomer(Customer, false, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        UpdateRequestedDeliveryDateOnSalesOrder(SalesHeader);
    end;

    local procedure CreateItemCard(var Item: Record Item)
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenNew();
        Item."No." := ItemCard."No.".Value();
        ItemCard."Gen. Prod. Posting Group".SetValue(Item."Gen. Prod. Posting Group");
        ItemCard."VAT Prod. Posting Group".SetValue(Item."VAT Prod. Posting Group");
        ItemCard."Inventory Posting Group".SetValue(Item."Inventory Posting Group");
        ItemCard.OK().Invoke();
    end;

    local procedure CreateItemReference(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[30]; VariantCode: Code[10]; UnitofMeasure: Code[10]; ReferenceNo: Code[20])
    begin
        ItemReference.Init();
        ItemReference.Validate("Item No.", ItemNo);
        ItemReference.Validate("Variant Code", VariantCode);
        ItemReference.Validate("Unit of Measure", UnitofMeasure);
        ItemReference.Validate("Reference Type", ReferenceType);
        ItemReference.Validate("Reference Type No.", ReferenceTypeNo);
        ItemReference.Validate("Reference No.", ReferenceNo);
        ItemReference.Validate(Description, LibraryUtility.GenerateGUID());
        ItemReference.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use random Unit Price.
        Item.Modify(true);
    end;

    local procedure CreateItemWithDescription(var Item: Record Item)
    begin
        CreateItem(Item);
        Item."Description 2" := LibraryUtility.GenerateGUID();
        Item.Modify(true);
    end;

    local procedure CreateItemTranslation(var ItemTranslation: Record "Item Translation"; ItemNo: Code[20]; LanguageCode: Code[10]; VariantCode: Code[10])
    begin
        ItemTranslation.Init();
        ItemTranslation.Validate("Item No.", ItemNo);
        ItemTranslation.Validate("Language Code", LanguageCode);
        ItemTranslation.Validate("Variant Code", VariantCode);
        ItemTranslation.Validate(Description, LibraryUtility.GenerateGUID());
        ItemTranslation.Validate("Description 2", LibraryUtility.GenerateGUID());
        ItemTranslation.Insert(true);
    end;

    local procedure CreateItemVariant(var ItemVariant: Record "Item Variant"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        ItemVariant.Validate("Description 2", LibraryUtility.GenerateGUID());
        ItemVariant.Modify(true);
    end;

    local procedure CreateItemVendorWithVariantCode(var ItemVendor: Record "Item Vendor"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        ItemVendor.Init();
        ItemVendor.Validate("Vendor No.", VendorNo);
        ItemVendor.Validate("Item No.", ItemNo);
        ItemVendor.Validate("Variant Code", VariantCode);
        ItemVendor.Validate("Vendor Item No.", ItemNo);
        ItemVendor.Insert(true);
    end;

    local procedure CreateItemWithVariant(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        CreateItemWithDescription(Item);
        CreateItemVariant(ItemVariant, Item."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchaseLineType: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLineType, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(20));  // Take random Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; SellToCustomerNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; var Vendor: Record Vendor; SellToCustomerNo: Code[20])
    begin
        CreateVendor(Vendor);
        Vendor."Language Code" := LibraryERM.GetAnyLanguageDifferentFromCurrent();
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseReturnOrderWithItemCharge(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Quantity: Decimal): Code[20]
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        CreateItem(Item);
        CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, Item."No.", Quantity);
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));  // Take random Quantity.
        exit(Item."No.");
    end;

    local procedure CreatePurchaseBlanketOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePurchBlanketOrderAndPurchOrderWithVariant(var BlanketPurchaseLine: Record "Purchase Line"; var PurchaseLine: Record "Purchase Line")
    var
        ItemVariant: Record "Item Variant";
        BlanketPurchaseHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseBlanketOrder(BlanketPurchaseHeader, BlanketPurchaseLine);
        CreateItemVariant(ItemVariant, BlanketPurchaseLine."No.");
        BlanketPurchaseLine.Validate("Variant Code", ItemVariant.Code);
        BlanketPurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, BlanketPurchaseLine."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, BlanketPurchaseLine."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesBlanketOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        CreateCustomer(Customer, false, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2)); // Use Random Quantity.
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2)); // Use random Unit Price.
        SalesLine.Modify(true);
        exit(SalesLine."No.");
    end;

    local procedure CreateSalesLineWithPurchasingCode(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2)); // Use Random Quantity.
        SalesLine.Validate("Purchasing Code", FindPurchasingCode());
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrderAndPost(): Code[20]
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateCustomer(Customer, false, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2)); // Use Random Quantity.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Post Shipment.
    end;

    local procedure CreateSalesOrderForDropShipment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        CreateSalesBlanketOrder(SalesHeader, SalesLine);
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);
        FindSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader);
    end;

    local procedure CreateSalesOrderWithItemVariantPurchDesc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Customer: Record Customer; ItemNo: Code[20]; ItemVariantCode: Code[10]; Desc: Text; Desc2: Text)
    begin
        CreateCustomer(Customer, true, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Variant Code", ItemVariantCode);
        SalesLine.Validate("Purchasing Code", FindPurchasingCode());
        SalesLine.Validate(Description, CopyStr(Desc, 1, MaxStrLen(SalesLine.Description)));
        SalesLine.Validate("Description 2", CopyStr(Desc2, 1, MaxStrLen(SalesLine."Description 2")));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesPrice(var SalesPrice: Record "Sales Price"; Item: Record Item; SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; UnitOfMeasureCode: Code[10]; MinimumQuantity: Decimal; StartingDate: Date)
    begin
        // Create Sales Price with random Unit Price.
        LibraryCosting.CreateSalesPrice(SalesPrice, SalesType, SalesCode, Item."No.", StartingDate, '', '', UnitOfMeasureCode, MinimumQuantity);
        SalesPrice.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesPrice.Modify(true);
    end;

    local procedure CreateSalesReturnOrder(var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        CreateCustomer(Customer, false, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
    end;

    local procedure CreateSalesDocumentWithItemCharge(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateItem(Item);
        CreateCustomer(Customer, false, '');
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandDecInRange(10, 20, 2));  // Take random Quantity.
        exit(Item."No.");
    end;

    local procedure CreateSalesDocumentWithItemChargeAndUnitPrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ItemNo: Code[20]; UnitPrice: Decimal)
    begin
        ItemNo := CreateSalesDocumentWithItemCharge(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        SalesLine.ShowItemChargeAssgnt();
    end;

    local procedure CreateSalesBlanketOrderAndSalesOrderWithVariant(var BlanketSalesLine: Record "Sales Line"; var SalesLine: Record "Sales Line")
    var
        ItemVariant: Record "Item Variant";
        BlanketSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesBlanketOrder(BlanketSalesHeader, BlanketSalesLine);
        CreateItemVariant(ItemVariant, BlanketSalesLine."No.");
        BlanketSalesLine.Validate("Variant Code", ItemVariant.Code);
        BlanketSalesLine.Modify(true);

        CreateSalesOrder(
          SalesHeader, SalesLine, BlanketSalesLine."Sell-to Customer No.", BlanketSalesLine."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateTempItem(var TempItem: Record Item temporary)
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        InventoryPostingGroup.FindFirst();
        TempItem.Init();
        TempItem.Insert(true);
        TempItem.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        TempItem.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        TempItem.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        TempItem.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Modify(true);
    end;

    local procedure ExecuteUIHandler(): Boolean
    var
        Reply: Boolean;
    begin
        // Needed this UI Handler to use it in Combine Return Receipt for ES.
        Reply := Confirm(DummyConfirmQst);
        exit(Reply);
    end;

    local procedure FindAndPostSalesDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure FindDocumentNo(SellToCustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.FindFirst();
        exit(SalesHeader."No.");
    end;

    local procedure FindPurchasingCode(): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        Purchasing.SetRange("Drop Shipment", true);
        Purchasing.FindFirst();
        exit(Purchasing.Code);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, Type);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SellToCustomerNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, Type);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure FindShippingAgentServices(var ShippingAgentServices: Record "Shipping Agent Services")
    begin
        ShippingAgentServices.SetFilter("Shipping Agent Code", '<>%1', '');
        ShippingAgentServices.FindFirst();
    end;

    local procedure FindItemChargeAssignmentPurch(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseLine: Record "Purchase Line")
    begin
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Line No.", PurchaseLine."Line No.");
        ItemChargeAssignmentPurch.FindFirst();
    end;

    local procedure FindItemChargeAssignmentSales(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; SalesLine: Record "Sales Line")
    begin
        ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", SalesLine."Document Type");
        ItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", SalesLine."Document No.");
        ItemChargeAssignmentSales.SetRange("Applies-to Doc. Line No.", SalesLine."Line No.");
        ItemChargeAssignmentSales.FindFirst();
    end;

    local procedure GetDropShipmentLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.GetDropShipment(PurchaseHeader);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure GetPostedDocumentLinesToReverseOnSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetReceiptLine(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure GetReturnReceiptLLine(SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        ReturnReceiptLine.SetRange("Document No.", DocumentNo);
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
    end;

    local procedure GetReturnShipmentLine(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        ReturnShipmentLine.SetRange("Document No.", DocumentNo);
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeader);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
    end;

    local procedure GetShipmentLineInSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);
    end;

    local procedure GetSalesPrice(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.GetPrice.Invoke();
    end;

    local procedure InvokeShowMatrixOnSalesAnalysisByDimensions(AnalysisViewListSales: TestPage "Analysis View List Sales"; ItemNo: Code[20])
    var
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
    begin
        SalesAnalysisbyDimensions.Trap();
        AnalysisViewListSales.EditAnalysisView.Invoke();
        SalesAnalysisbyDimensions.ItemFilter.SetValue(ItemNo);
        SalesAnalysisbyDimensions.ShowMatrix_Process.Invoke();
    end;

    local procedure InvokeUpdateItemAnalysisViewOnAnalysisViewListSales(var AnalysisViewListSales: TestPage "Analysis View List Sales"; ItemAnalysisViewCode: Code[10])
    begin
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisViewCode);
        AnalysisViewListSales."&Update".Invoke();
    end;

    local procedure MoveNegativeLines(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Commit(); // Commit required before invoke Move Negative Lines.
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.MoveNegativeLines.Invoke();
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure OpenOrderPromisingPage(SalesHeaderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        SalesOrder.SalesLines.OrderPromising.Invoke();
    end;

    local procedure PostPhysicalInventoryJournal(Quantity: Decimal; ItemNo: Code[20]): Code[20]
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Qty. (Phys. Inventory)", ItemJournalLine."Qty. (Calculated)" + Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryUtility.GenerateGUID();  // Generate New Batch.
        exit(ItemJournalLine."Document No.");
    end;

    local procedure RunBatchPostSalesReturnOrders(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        BatchPostSalesReturnOrders: Report "Batch Post Sales Return Orders";
    begin
        SalesHeader.SetRange("No.", SalesHeaderNo);
        Clear(BatchPostSalesReturnOrders);
        Commit();  // Commit is required to run Batch Post Sales Return Order report.
        BatchPostSalesReturnOrders.SetTableView(SalesHeader);
        BatchPostSalesReturnOrders.Run();
    end;

    local procedure RunCalculateInventoryValueReport(ItemNo: Code[20]): Integer
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type", ItemNo, 0);
        Item.SetRange("No.", ItemNo);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate(), ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."),
          "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", false);
        exit(ItemJournalLine."Dimension Set ID");
    end;

    local procedure RunCalculateInventory(ItemNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);

        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate(), false, false);
    end;

    local procedure RunCombineReturnReceipt(NewPostingDate: Date; NewDocumentDate: Date; SelltoCustomerNo: Code[20])
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", SelltoCustomerNo);
        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SelltoCustomerNo);
        LibrarySales.CombineReturnReceipts(SalesHeader, ReturnReceiptHeader, NewPostingDate, NewDocumentDate, false, true);
        ExecuteUIHandler();  // Need to use Execute UI Handler to prevent failure in ES.
    end;

    local procedure RunCreateReturnRelatedDocumentsReport(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        CreateRetRelatedDocuments: Report "Create Ret.-Related Documents";
    begin
        SalesHeader.SetRange("No.", SalesHeaderNo);
        SalesHeader.FindFirst();
        Commit();  // Commit required before running this Report.
        Clear(CreateRetRelatedDocuments);
        CreateRetRelatedDocuments.SetSalesHeader(SalesHeader);
        CreateRetRelatedDocuments.UseRequestPage(true);
        CreateRetRelatedDocuments.Run();
    end;

    local procedure RunDeleteEmptyItemRegistersReport(No: Integer)
    var
        ItemRegister: Record "Item Register";
        DeleteEmptyItemRegisters: Report "Delete Empty Item Registers";
    begin
        Clear(DeleteEmptyItemRegisters);
        ItemRegister.SetRange("No.", No);
        DeleteEmptyItemRegisters.SetTableView(ItemRegister);
        DeleteEmptyItemRegisters.UseRequestPage(true);
        DeleteEmptyItemRegisters.Run();
    end;

    local procedure RunDeleteInvoiceSalesReturnOrder(SelltoCustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", SelltoCustomerNo);
        LibrarySales.DeleteInvoicedSalesReturnOrders(SalesHeader);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetDefaultQtyToShipToBlank()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Quantity to Ship", SalesReceivablesSetup."Default Quantity to Ship"::Blank);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetDefaultQtyToReceiveToBlank()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Qty. to Receive", PurchasesPayablesSetup."Default Qty. to Receive"::Blank);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure SetItemChargeQtyFullyAssigned(SalesLine: Record "Sales Line")
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssignmentSales.SetRange("Document Type", SalesLine."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", SalesLine."Document No.");
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales."Qty. Assigned" := ItemChargeAssignmentSales."Qty. to Assign";
        ItemChargeAssignmentSales."Qty. to Assign" := 0;
        ItemChargeAssignmentSales."Amount to Assign" := 0;
        ItemChargeAssignmentSales.Modify();
    end;

    local procedure UpdateDefaultDimension(var DefaultDimension: Record "Default Dimension")
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DefaultDimension."Dimension Code");
        DefaultDimension.Validate("Dimension Value Code", DimensionValue.Code);
        DefaultDimension.Modify(true);
    end;

    local procedure UpdateItemDimension(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure UpdateInventorySetup(Value: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Expected Cost Posting to G/L", Value);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateOrderDateOnSalesOrder(SalesHeader: Record "Sales Header"; OrderDate: Date)
    begin
        SalesHeader.Validate("Order Date", OrderDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePostedShipment(var ShippingAgentServices: Record "Shipping Agent Services"; DocumentNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.Get(DocumentNo);
        FindShippingAgentServices(ShippingAgentServices);
        SalesShipmentHeader.Validate("Shipping Agent Code", ShippingAgentServices."Shipping Agent Code");
        SalesShipmentHeader.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        SalesShipmentHeader.Validate("Package Tracking No.", DocumentNo);
        SalesShipmentHeader.Modify(true);
    end;

    local procedure UpdateQtyToInvoiceOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToInvoice: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQtyToInvoiceOnSalesLine(var SalesLine: Record "Sales Line"; QtyToInvoice: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyToReceiveOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQtyToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtyToShip: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure UpdateRequestedDeliveryDateOnSalesOrder(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Requested Delivery Date", RequestedDeliveryDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesReceivableSetup(StockoutWarning: Boolean; CalcInvDiscount: Boolean)
    begin
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(StockoutWarning);
        LibrarySales.SetCalcInvDiscount(CalcInvDiscount);
    end;

    local procedure UpdateShippingAdviceOnSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder."Shipping Advice".SetValue(SalesHeader."Shipping Advice"::Complete);
        SalesOrder.OK().Invoke();
    end;

    local procedure VerifyDimensionOnRevaluationJournal(DefaultDimension: Record "Default Dimension"; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.TestField("Dimension Code", DefaultDimension."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyItem(Item: Record Item)
    var
        Item2: Record Item;
    begin
        Item2.Get(Item."No.");
        Item2.TestField("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        Item2.TestField("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        Item2.TestField("Inventory Posting Group", Item."Inventory Posting Group");
    end;

    local procedure VerifyItemChargeAssignment(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; AmountToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", DocumentType);
        ItemChargeAssignmentPurch.SetRange("Document No.", DocumentNo);
        ItemChargeAssignmentPurch.SetRange("Item No.", ItemNo);
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", Quantity);
        ItemChargeAssignmentPurch.TestField("Amount to Assign", AmountToAssign);
    end;

    local procedure VerifyItemChargeAssignmentForSales(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; AmountToAssign: Decimal)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssignmentSales.SetRange("Document Type", DocumentType);
        ItemChargeAssignmentSales.SetRange("Document No.", DocumentNo);
        ItemChargeAssignmentSales.SetRange("Item No.", ItemNo);
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.TestField("Qty. to Assign", Quantity);
        ItemChargeAssignmentSales.TestField("Amount to Assign", AmountToAssign);
    end;

    local procedure VerifyItemLedgerEntry(DocNo: Code[20]; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Document No.", DocNo);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Invoiced Quantity", Quantity);
    end;

    local procedure VerifyItemLedgerEntryForPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Invoiced Quantity", Quantity);
    end;

    local procedure VerifyItemValueEntry(DocumentNo: Code[20]; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal; UnitAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Ledger Entry Type", EntryType);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Item Ledger Entry Quantity", Quantity);
        Assert.AreNearlyEqual(
          ValueEntry."Cost per Unit", UnitAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(CostError, ValueEntry.FieldCaption("Cost per Unit"), UnitAmount, ValueEntry.TableCaption()));
        Assert.AreNearlyEqual(
          ValueEntry."Cost Amount (Actual)", ValueEntry."Cost per Unit" * Quantity, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            CostError, ValueEntry.FieldCaption("Cost Amount (Actual)"), ValueEntry."Cost per Unit" * Quantity, ValueEntry.TableCaption()));
    end;

    local procedure VerifyNavigateLines(SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Navigate: TestPage Navigate;
        PostedSalesShipment: Page "Posted Sales Shipment";
        PostedSalesInvoice: Page "Posted Sales Invoice";
        PostedReturnReceipt: Page "Posted Return Receipt";
        PostedSalesCreditMemo: Page "Posted Sales Credit Memo";
    begin
        Navigate.OpenEdit();
        Navigate.ContactType.SetValue(Customer.TableCaption());
        Navigate.ContactNo.SetValue(SalesHeader."Sell-to Customer No.");
        Navigate.ExtDocNo.SetValue(SalesHeader."External Document No.");
        Navigate.Find.Invoke();
        Navigate.FILTER.SetFilter("Table Name", PostedSalesShipment.Caption);
        Navigate."No. of Records".AssertEquals(1);
        Navigate.FILTER.SetFilter("Table Name", PostedSalesInvoice.Caption);
        Navigate."No. of Records".AssertEquals(1);
        Navigate.FILTER.SetFilter("Table Name", PostedReturnReceipt.Caption);
        Navigate."No. of Records".AssertEquals(1);
        Navigate.FILTER.SetFilter("Table Name", PostedSalesCreditMemo.Caption);
        Navigate."No. of Records".AssertEquals(1);
    end;

    local procedure VerifyOrderPromisingLine(Quantity: Decimal)
    begin
        Assert.AreEqual(Quantity, LibraryVariableStorage.DequeueDecimal(), OrderPromisingQtyErr);
        Assert.AreEqual(Quantity, LibraryVariableStorage.DequeueDecimal(), OrderPromisingUnavailQtyErr);
    end;

    local procedure VerifyPhysicalInventoryItemLedger(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
    begin
        PhysInventoryLedgerEntry.SetRange("Document No.", DocumentNo);
        PhysInventoryLedgerEntry.SetRange("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
        PhysInventoryLedgerEntry.SetRange("Item No.", ItemNo);
        PhysInventoryLedgerEntry.FindFirst();
        PhysInventoryLedgerEntry.TestField("Qty. (Calculated)", Quantity);
        PhysInventoryLedgerEntry.TestField("Qty. (Phys. Inventory)", Quantity + Quantity); // As Qty. (Phys. Inventory) is double of Qty. (Calculated).
    end;

    local procedure VerifyPurchaseInvoiceLine(DocumentNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange("No.", No);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseLineDescription(PurchaseLine: Record "Purchase Line"; Description: Text[100]; Description2: Text[50])
    begin
        Assert.AreEqual(Description, PurchaseLine.Description, DescriptionErr);
        Assert.AreEqual(Description2, PurchaseLine."Description 2", DescriptionErr);
    end;

    local procedure VerifyPurchaseDocument(DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.FindFirst();
    end;

    local procedure VerifyPostedSalesCreditMemo(CustomerNo: Code[20]; BillToCustomerNo: Code[20]; Type: Enum "Sales Line Type"; DocumentNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesCrMemoLine.SetRange(Type, Type);
        SalesCrMemoLine.SetRange("Return Receipt No.", DocumentNo);
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField("No.", No);
        SalesCrMemoLine.TestField(Quantity, Quantity);
        SalesCrMemoLine.TestField("Bill-to Customer No.", BillToCustomerNo);
    end;

    local procedure VerifyPostedShipment(var ShippingAgentServices: Record "Shipping Agent Services"; DocumentNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.Get(DocumentNo);
        SalesShipmentHeader.TestField("Shipping Agent Code", ShippingAgentServices."Shipping Agent Code");
        SalesShipmentHeader.TestField("Shipping Agent Service Code", ShippingAgentServices.Code);
        SalesShipmentHeader.TestField("Package Tracking No.", DocumentNo);
    end;

    local procedure VerifyPostedReturnReceipt(SalesLine: Record "Sales Line")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetRange("Return Order No.", SalesLine."Document No.");
        ReturnReceiptLine.FindFirst();
        ReturnReceiptLine.TestField("No.", SalesLine."No.");
        ReturnReceiptLine.TestField(Quantity, SalesLine.Quantity);
        ReturnReceiptLine.TestField("Quantity Invoiced", SalesLine.Quantity);
    end;

    local procedure VerifySalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; QtyToAssign: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, DocumentNo, Type, No);
        SalesLine.CalcFields("Qty. to Assign");
        SalesLine.TestField(Quantity, Quantity);
        SalesLine.TestField("Qty. to Assign", QtyToAssign);
    end;

    local procedure VerifySalesLineForItemCharge(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
        SalesLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesOrder(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.RecordIsNotEmpty(SalesHeader);
    end;

    local procedure VerifyUnitPriceOnSalesLine(SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Unit Price", UnitPrice);
    end;

    local procedure VerifyValueEntryForItemCharge(ItemNo: Code[20]; ItemChargeNo: Code[20]; Qty: Decimal; UnitPrice: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();

        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Sales Amount (Actual)", Qty * UnitPrice);
    end;

    local procedure VerifyDropShipment(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Find();
        PurchaseLine.TestField("Qty. to Receive", 0);
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
        PurchaseLine.TestField("Qty. to Invoice", PurchaseLine."Quantity Received");
    end;

    local procedure SortUnitPriceInSalesOrderLineAndGetUpdatedUnitPrice(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.Filter.SetCurrentKey("Unit Price");
        SalesOrder.SalesLines.Filter.Ascending(true);
        SalesOrder.SalesLines.GetPrice.Invoke();

        exit(SalesOrder.SalesLines."Unit Price".AsDecimal());
    end;

    local procedure LinkDocDateToPostingDateSalesSetup(EnableLinkDocDate: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", EnableLinkDocDate);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure LinkDocDateToPostingDatePurchSetup(EnableLinkDocDate: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", EnableLinkDocDate);
        PurchasesPayablesSetup.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrderHandler(var BatchPostSalesReturnOrders: TestRequestPage "Batch Post Sales Return Orders")
    begin
        BatchPostSalesReturnOrders.ReceiveReq.SetValue(true);
        BatchPostSalesReturnOrders.InvReq.SetValue(true);
        BatchPostSalesReturnOrders.PostingDateReq.SetValue(WorkDate());
        BatchPostSalesReturnOrders.ReplacePostingDate.SetValue(true);
        BatchPostSalesReturnOrders.ReplaceDocumentDate.SetValue(false);

        if CalculateInvoiceDiscount then
            BatchPostSalesReturnOrders.CalcInvDisc.SetValue(false);

        BatchPostSalesReturnOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteEmptyItemRegistersReportHandler(var DeleteEmptyItemRegisters: TestRequestPage "Delete Empty Item Registers")
    begin
        DeleteEmptyItemRegisters.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateReturnRelatedDocumentsReportHandler(var CreateRetRelatedDocuments: TestRequestPage "Create Ret.-Related Documents")
    begin
        CreateRetRelatedDocuments.VendorNo.SetValue(VendorNo);
        CreateRetRelatedDocuments.CreatePurchRetOrder.SetValue(true);
        CreateRetRelatedDocuments.CreatePurchaseOrder.SetValue(true);
        CreateRetRelatedDocuments.CreateSalesOrder.SetValue(true);
        CreateRetRelatedDocuments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        if GetShipmentLines then begin
            ItemChargeAssignmentSales.GetShipmentLines.Invoke();
            ItemChargeAssignmentSales.Last();
        end;
        ItemChargeAssignmentSales."Qty. to Assign".SetValue(ItemChargeAssignmentSales.AssignableQty.AsDecimal());
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchaseHandler(var ItemChargeAssignmentPurchase: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurchase.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentPurchase.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimMatrixPageHandler(var SalesAnalysisbyDimMatrix: TestPage "Sales Analysis by Dim Matrix")
    begin
        SalesAnalysisbyDimMatrix.TotalQuantity.AssertEquals(-Quantity2);
        SalesAnalysisbyDimMatrix.TotalInvtValue.AssertEquals(Amount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentLinesHandler(var SalesShipmentLines: TestPage "Sales Shipment Lines")
    begin
        SalesShipmentLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MoveNegativeSalesLinesHandler(var MoveNegativeSalesLines: TestRequestPage "Move Negative Sales Lines")
    begin
        MoveNegativeSalesLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        if CapableToPromise then
            OrderPromisingLines.CapableToPromise.Invoke()
        else
            OrderPromisingLines.AvailableToPromise.Invoke();

        if RequestedShipmentDate then begin
            OrderPromisingLines."Requested Shipment Date".AssertEquals(RequestedDeliveryDate);
            OrderPromisingLines."Requested Delivery Date".AssertEquals(RequestedDeliveryDate);
        end else begin
            OrderPromisingLines."Unavailable Quantity".AssertEquals(UnavailableQuantity);
            OrderPromisingLines."Requested Delivery Date".AssertEquals(RequestedDeliveryDate);
            OrderPromisingLines."Planned Delivery Date".AssertEquals(RequestedDeliveryDate);
        end;

        LibraryVariableStorage.Enqueue(OrderPromisingLines.Quantity.AsDecimal());
        LibraryVariableStorage.Enqueue(OrderPromisingLines."Unavailable Quantity".AsDecimal());

        OrderPromisingLines.AcceptButton.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderHandler(var SalesOrder: TestPage "Sales Order")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetSalesPriceHandler(var GetSalesPrice: TestPage "Get Sales Price") // V15
    begin
        GetSalesPrice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPriceLineHandler(var GetPriceLine: TestPage "Get Price Line") // V16
    begin
        GetPriceLine.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentLinesPageHandler(var PostedSalesShipmentLines: TestPage "Posted Sales Shipment Lines")
    var
        NoOfLines: Integer;
    begin
        if PostedSalesShipmentLines.First() then
            NoOfLines := 1;

        while PostedSalesShipmentLines.Next() do
            NoOfLines += 1;

        LibraryVariableStorage.Enqueue(NoOfLines);

        PostedSalesShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceLinesPageHandler(var PostedSalesInvoiceLines: TestPage "Posted Sales Invoice Lines")
    var
        NoOfLines: Integer;
    begin
        if PostedSalesInvoiceLines.First() then
            NoOfLines := 1;

        while PostedSalesInvoiceLines.Next() do
            NoOfLines += 1;

        LibraryVariableStorage.Enqueue(NoOfLines);

        PostedSalesInvoiceLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
        ConfirmMessage := Question;  // The variable ConfirmMessage is made Global as it is used in the handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DummyConfirmQst) > 0 then
            Reply := true
        else
            Error(VerificationFailureErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetLastUnitPriceHandler(var GetSalesPrice: TestPage "Get Sales Price")
    begin
        GetSalesPrice.Last();
        GetSalesPrice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesHandlerNew(var ItemChargeAssignmentSalesPage: TestPage "Item Charge Assignment (Sales)")
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        PurchaseLineVariant: Variant;
        QuantityToAssignVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(PurchaseLineVariant);
        LibraryVariableStorage.Dequeue(QuantityToAssignVariant);

        FindItemChargeAssignmentSales(ItemChargeAssignmentSales, PurchaseLineVariant);
        ItemChargeAssignmentSalesPage.GoToRecord(ItemChargeAssignmentSales);
        ItemChargeAssignmentSalesPage."Qty. to Assign".SetValue(QuantityToAssignVariant);
        ItemChargeAssignmentSalesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchaseHandlerNew(var ItemChargeAssignmentPurchase: TestPage "Item Charge Assignment (Purch)")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLineVariant: Variant;
        QuantityToAssignVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(PurchaseLineVariant);
        LibraryVariableStorage.Dequeue(QuantityToAssignVariant);

        FindItemChargeAssignmentPurch(ItemChargeAssignmentPurch, PurchaseLineVariant);
        ItemChargeAssignmentPurchase.GoToRecord(ItemChargeAssignmentPurch);
        ItemChargeAssignmentPurchase."Qty. to Assign".SetValue(QuantityToAssignVariant);
        ItemChargeAssignmentPurchase.OK().Invoke();
    end;
}
