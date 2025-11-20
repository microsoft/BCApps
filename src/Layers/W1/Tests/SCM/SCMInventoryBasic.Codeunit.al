codeunit 137280 "SCM Inventory Basic"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNoSeries: Codeunit "Library - No. Series";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTemplates: Codeunit "Library - Templates";
        isInitialized: Boolean;
        ItemCreatedMsg: Label 'Item %1 is created.';
        ItemChargeErr: Label 'You can not invoice item charge %1 because there is no item ledger entry to assign it to.';
        GlobalSerialNo: Code[50];
        GlobalDocumentNo: Code[20];
        GlobalItemNo: Code[20];
        GlobalLotNo: Code[50];
        GlobalQuantity: Decimal;
        GlobalAmount: Decimal;
        GlobalPurchasedQuantity: Decimal;
        GlobalQtyToAssign: Decimal;
        GlobalApplToItemEntry: Integer;
        GlobalLineOption: Enum "Item Statistics Line Option";
        GlobalItemTracking: Option ,AssignSerialNo,AssignLotNo,SelectEntries,SetValue;
        GlobalItemChargeAssignment: Option AssignmentOnly,GetShipmentLine;
        VariantErr: Label 'Variant  cannot be fully applied.';
        UnitCostErr: Label 'Unit Cost must be same.';
        RemainingQtyErr: Label 'is too low to cover';
        VatProdPostingGrMatchErr: Label '%1 must be that same as in the %2';
        VatProdPostingGrMostNotMatchErr: Label '%1 must not be that same as in the %2';
        ItemUOMErr: Label 'The field %1';
        UOMErr: Label '%1 should be taken from appropriate table';
        ControlVisibilityErr: Label 'Control visibility should be %1';
        UnspecifiedLocationTxt: Label 'UNSPECIFIED';
        IsNotFoundOnThePageTxt: Label 'is not found on the page';
        UnexpectedValueErr: Label 'Unexpected value of field %1 in table %2', Comment = '%1: Field name, %2: Table name';
        CurrentWorkDate: Date;

    [Test]
    [HandlerFunctions('ItemCreationMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateAndReceiveNonStockItem()
    var
        NonstockItem: Record "Nonstock Item";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // Verify creation and receiving of NonStock Item.

        // Setup. Create NonStock Item and Purchase Order.
        Initialize();
        CreateNonStockItem(NonstockItem);
        GlobalItemNo := NonstockItem."Vendor Item No."; // Assign to global variable.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(), PurchaseLine.Type::Item, NonstockItem."Vendor Item No.",
          LibraryRandom.RandInt(100)); // Take Random Quantity

        // Exercise.
        asserterror PostPurchaseOrder(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", false);

        // Verify.
        Assert.ExpectedTestFieldError(Item.FieldCaption("Item Tracking Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndReceiveItemWithLongItemVendorNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        // Verify creation and receiving of Item with long Vendor Item No.

        // Setup. Create Item and Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
#pragma warning disable AA0139 // Length of the text returned by GenerateRandomText is limited by the argument value
        Item."Vendor Item No." := LibraryUtility.GenerateRandomText(MaxStrLen(Item."Vendor Item No."));
#pragma warning restore
        Item.Modify();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", 10, '', 0D);

        // Exercise.
        PostPurchaseOrder(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", false);

        // Receipt is succesfully posted
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.IsTrue(PurchRcptHeader.FindFirst(), 'Receipt not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndShipItemWithLongItemVendorNo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        // Verify creation and receiving of Item with long Vendor Item No.

        // Setup. Create Item and Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
#pragma warning disable AA0139 // Length of the text returned by GenerateRandomText is limited by the argument value
        Item."Vendor Item No." := LibraryUtility.GenerateRandomText(MaxStrLen(Item."Vendor Item No."));
#pragma warning restore
        Item.Modify();

        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 10, '', 0D);

        // Exercise.
        Librarysales.PostSalesDocument(SalesHeader, true, false);

        // Receipt is succesfully posted
        SalesShptHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.IsTrue(SalesShptHeader.FindFirst(), 'Shipment not found');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithLotNo()
    begin
        // Verify Apply To the initial Purchase Item Ledger Entry in Purchase Credit Memo with Lot No.
        PurchaseCreditMemoWithItemTracking(true, false, LibraryRandom.RandInt(100), GlobalItemTracking::AssignLotNo); // Take Random Quantity.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,EnterQuantitytoCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithSerialNo()
    begin
        // Verify Apply To the initial Purchase Item Ledger Entry in Purchase Credit Memo with Serial No.
        PurchaseCreditMemoWithItemTracking(false, true, 1, GlobalItemTracking::AssignSerialNo); // Take Quantity 1 as this is not important.
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplateHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyIndirectCostOnItemCard()
    var
        Item: Record Item;
        ItemTemplate: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        ItemValueLbl: Label 'Item indirect cost % must be same as Item Template';
    begin
        // [SCENARIO 454745] "Indirect Cost %" is not updated for an item when applying an item template with Indirect Code % = 0
        Initialize();

        // [GIVEN] Creation of Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Creation of Item Template with Item category code & Indirect cost% value in the record.
        ItemTemplate.SetRange(Code, SelectItemTemplateCode());
        ItemTemplate.FindFirst();
        ItemTemplate.Validate("Item Category Code", '');
        ItemTemplate.Validate("Indirect Cost %", 0);
        ItemTemplate.Modify();

        // [WHEN] Apply new item template on existing item.
        LibraryVariableStorage.Enqueue(ItemTemplate.Code);
        ItemTemplMgt.UpdateItemFromTemplate(Item);

        // [THEN] The indirect cost% value must be same on Item card as Item template.
        Assert.AreEqual(Item."Indirect Cost %", ItemTemplate."Indirect Cost %", ItemValueLbl);
    end;

    local procedure PurchaseCreditMemoWithItemTracking(LotSpecific: Boolean; SerialSpecific: Boolean; Quantity: Decimal; TrackingOption: Option)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create Item with Item Tracking Code, Create a Purchase Order, Sales Order, Purchase Credit Memo.
        Initialize();
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(LotSpecific, SerialSpecific));

        // Post Purchase Order as Receive.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(), PurchaseLine.Type::Item, Item."No.", Quantity);
        GlobalPurchasedQuantity := PurchaseLine.Quantity; // Assign global variable.
        GlobalItemTracking := TrackingOption;
        PurchaseLine.OpenItemTrackingLines();
        DocumentNo := PostPurchaseOrder(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", false);

        // Post Sales Order.
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateCustomer(), SalesLine.Type::Item, Item."No.", GlobalPurchasedQuantity);
        GlobalItemTracking := GlobalItemTracking::SelectEntries;
        SalesLine.OpenItemTrackingLines();
        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // Post Sales Credit Memo.
        CreateSalesDocument(
          SalesLine2, SalesLine2."Document Type"::"Credit Memo", CreateCustomer(), SalesLine2.Type::Item, Item."No.", GlobalPurchasedQuantity);
        GlobalItemTracking := GlobalItemTracking::SetValue;
        SalesLine2.OpenItemTrackingLines();
        PostSalesOrder(SalesLine2."Document Type", SalesLine2."Document No.", true);

        // Post the initial Purchase Order as Invoice.
        PostPurchaseOrder(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", true);

        // Create Purchase Credit Memo and apply to the initial Purchase Item Ledger Entry.
        CreatePurchaseDocument(
          PurchaseLine2, PurchaseLine2."Document Type"::"Credit Memo", CreateVendor(), PurchaseLine2.Type::Item, Item."No.",
          PurchaseLine.Quantity);
        GlobalApplToItemEntry := FindItemLedgerEntry(DocumentNo); // Assign to global variable.
        GlobalItemTracking := GlobalItemTracking::SelectEntries;
        asserterror PurchaseLine2.OpenItemTrackingLines();

        // Verify.
        Assert.ExpectedError(RemainingQtyErr);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchGetRcptPageHandler,PurchReceiptLinePageHandler,ItemStatisticsPageHandler,ItemStatisticsMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure ItemStatisticsMatrixForPurchaseEntry()
    var
        ItemCharge: Record "Item Charge";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // Test the Item Charge Assignment on Purchase Document and Validate it on Item Statistics Matrix.

        // Setup.
        Initialize();
        VendorNo := CreateVendor();
        GlobalAmount := LibraryRandom.RandDec(1000, 1);  // Using Random value in global variable to verify Total Amount in ItemStatisticsMatrix Page.
        ItemCharge.FindFirst();

        // Create 1st Purchase Order for Item and Post as Receive.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, VendorNo, PurchaseLine.Type::Item, CreateItem(),
          LibraryRandom.RandDec(100, 1));  // Using Random value for Quantity.
        GlobalDocumentNo := PostPurchaseOrder(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", false);

        // Create 2nd Purchase Order for Charge Item, Assign Item Charge.
        CreatePurchaseDocument(
          PurchaseLine2, PurchaseLine2."Document Type"::Order, VendorNo, PurchaseLine2.Type::"Charge (Item)", ItemCharge."No.", 1);  // Added Quantity as 1 for Item Charge.
        PurchaseLine2.Validate("Direct Unit Cost", GlobalAmount);
        PurchaseLine2.Modify(true);
        GlobalLineOption := ItemStatisticsBuffer."Line Option"::"Purch. Item Charge Spec.";  // Using global variable to assing Line Option in Item Statistics Page.
        PurchaseLine2.ShowItemChargeAssgnt();

        // Exercise: Post Order as Receive and Invoice.
        PostPurchaseOrder(PurchaseLine2."Document Type", PurchaseLine2."Document No.", true);

        // Verify: Verify Item Charge Amount on Item Statistics Matrix Page Handler.
        OpenItemStatisticsPage(PurchaseLine."No.");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,SalesShipmentLinePageHandler,ItemStatisticsPageHandler,ItemStatisticsMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure ItemStatisticsMatrixForSalesEntry()
    var
        ItemCharge: Record "Item Charge";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        // Test the Item Charge Assignment on Sales Document and Validate it on Item Statistics Matrix.

        // Setup.
        Initialize();
        CustomerNo := CreateCustomer();
        GlobalAmount := LibraryRandom.RandDec(1000, 1);  // Using Ranom value in global variable to verify Total Amount in ItemStatisticsMatrix Page.
        ItemCharge.FindFirst();

        // Create 1st Sales Order for Item and Post as Ship.
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CustomerNo, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(100, 1));  // Using Random value for Quantity.
        GlobalDocumentNo := PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", false);

        // Create 2nd Sales Order for Charge Item, Assign Item Charge.
        CreateSalesDocument(SalesLine2, SalesLine2."Document Type"::Order, CustomerNo, SalesLine2.Type::"Charge (Item)", ItemCharge."No.", 1);  // Added Quantity as 1 for Item Charge.
        UpdateSalesLineUnitPrice(SalesLine2, GlobalAmount);
        GlobalLineOption := ItemStatisticsBuffer."Line Option"::"Sales Item Charge Spec.";  // Using global variable to assing Line Option in Item Statistics Page.
        GlobalItemChargeAssignment := GlobalItemChargeAssignment::GetShipmentLine;
        SalesLine2.ShowItemChargeAssgnt();

        // Exercise: Post Order as Ship and Invoice.
        PostSalesOrder(SalesLine2."Document Type", SalesLine2."Document No.", true);

        // Verify: Verify Item Charge Amount on Item Statistics Matrix Page Handler.
        OpenItemStatisticsPage(SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPostingErrorWithItemChargeAssignment()
    var
        SalesLine: Record "Sales Line";
        ItemChargeNo: Code[20];
    begin
        // Test Sales Order with Item Charge Assignment, Not allow to Post Sales Order as Ship and Invoice if Qty. to Ship = 0 in Sales Line.

        // Setup: Create Sales Order with Item Charge and Assignment Item Charge.
        ItemChargeNo := CreateSalesOrderAndAssignItemCharge(SalesLine);

        // Exercise.
        asserterror PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // Verify: Verify Error for Item Charge
        Assert.ExpectedError(StrSubstNo(ItemChargeErr, ItemChargeNo));
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,SalesShipmentLinePageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPostingWithItemChargeAssignment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        ItemChargeNo: Code[20];
    begin
        // Test Sales Order with Item Charge Assignment, Not allow to Post Sales Order as Ship and Invoice if Qty. to Ship = 0 in Sales Line.

        // Setup: Create Sales Order with Item Charge and Assignment Item Charge.
        ItemChargeNo := CreateSalesOrderAndAssignItemCharge(SalesLine);
        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", false);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        DeleteSalesLine(SalesLine."Document No.");
        GlobalItemChargeAssignment := GlobalItemChargeAssignment::GetShipmentLine;
        SalesLine.ShowItemChargeAssgnt();

        // Exercise.
        DocumentNo := PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // Verify: Verify Charge Item Entry posted.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"Charge (Item)");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("No.", ItemChargeNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemByLocationMatrixWithoutInTransit()
    begin
        // Verify Item by Location Matrix.
        Initialize();
        ItemByLocationMatrix(false);  // False for non In-Transit Location.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemByLocationMatrixWithInTransit()
    begin
        // Verify Item by Location Matrix with Show In Transit filter as True.
        Initialize();
        ItemByLocationMatrix(true);  // True for In-Transit Location.
    end;

    local procedure ItemByLocationMatrix(InTransit: Boolean)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        ItemsByLocation: TestPage "Items by Location";
        LocationCode: Code[10];
    begin
        // Setup: Create Item and post Item Journal Line with Location.
        GlobalQuantity := LibraryRandom.RandDec(100, 2);  // Use Random value for Quantity and Assign in global variable for verification in handler.
        GlobalItemNo := LibraryInventory.CreateItem(Item);  // Assign in global variable.
        LocationCode := GetFirstLocation(false);
        CreateAndPostItemJournalLine(ItemJournalLine, GlobalItemNo, LocationCode, GlobalQuantity);
        if InTransit then begin
            CreateTransferOrder(TransferHeader, LocationCode, GlobalItemNo, GlobalQuantity);
            LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        end;

        // Exercise: Open Items by Location page to open the Matrix.
        ItemsByLocation.OpenView();
        ItemsByLocation.ShowInTransit.SetValue(InTransit);
        ItemsByLocation.MatrixForm.FILTER.SetFilter("No.", GlobalItemNo);

        // Verify
        if ItemsByLocation.MatrixForm.Field1.Caption <> UnspecifiedLocationTxt then
            ItemsByLocation.MatrixForm.Field1.AssertEquals(GlobalQuantity)
        else
            ItemsByLocation.MatrixForm.Field2.AssertEquals(GlobalQuantity);
    end;

    [Scope('OnPrem')]
    procedure ItemByLocationMatrixAllLocations()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ItemsByLocation: TestPage "Items by Location";
        ItemNo: Code[20];
        ColumnNumber: Integer;
    begin
        // 1. Setup: Create an increasing number of items in each location, starting from the blank location
        Initialize();
        ItemNo := LibraryInventory.CreateItem(Item);
        ColumnNumber := 1;
        CreateAndPostItemJournalLine(ItemJournalLine, ItemNo, '', ColumnNumber);
        Location.SetRange("Use As In-Transit", false);
        if Location.FindSet() then
            repeat
                ColumnNumber += 1;
                if not InventoryPostingSetupExists(Location.Code, Item."Inventory Posting Group") then
                    LibraryInventory.UpdateInventoryPostingSetup(Location);
                CreateAndPostItemJournalLine(ItemJournalLine, ItemNo, Location.Code, ColumnNumber);
            until Location.Next() = 0;

        // Exercise: Open Items by Location page to open the Matrix and filter to the newly created item.
        ItemsByLocation.OpenView();
        ItemsByLocation.ShowInTransit.SetValue(false);
        ItemsByLocation.MatrixForm.FILTER.SetFilter("No.", ItemNo);

        // Verify: Each column caption corresponds to a location code, and each cell contains the correct inventory
        ColumnNumber := 1;
        VerifyMatrixColumn(ItemsByLocation, ColumnNumber, UnspecifiedLocationTxt, ColumnNumber);
        if Location.FindSet() then
            repeat
                ColumnNumber += 1;
                VerifyMatrixColumn(ItemsByLocation, ColumnNumber, Location.Code, ColumnNumber);
            until Location.Next() = 0;
    end;

    local procedure VerifyMatrixColumn(var ItemsbyLocation: TestPage "Items by Location"; ColumnNumber: Integer; ExpectedCaption: Text; ExpectedValue: Variant)
    var
        FieldValue: Variant;
        FieldCaption: Text;
    begin
        case ColumnNumber of
            1:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field1.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field1.Caption;
                end;
            2:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field2.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field2.Caption;
                end;
            3:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field3.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field3.Caption;
                end;
            4:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field4.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field4.Caption;
                end;
            5:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field5.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field5.Caption;
                end;
            6:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field6.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field6.Caption;
                end;
            7:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field7.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field7.Caption;
                end;
            8:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field8.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field8.Caption;
                end;
            9:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field9.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field9.Caption;
                end;
            10:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field10.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field10.Caption;
                end;
            11:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field11.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field11.Caption;
                end;
            12:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field12.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field12.Caption;
                end;
            13:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field13.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field13.Caption;
                end;
            14:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field14.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field14.Caption;
                end;
            15:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field15.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field15.Caption;
                end;
            16:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field16.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field16.Caption;
                end;
            17:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field17.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field17.Caption;
                end;
            18:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field18.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field18.Caption;
                end;
            19:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field19.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field19.Caption;
                end;
            20:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field20.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field20.Caption;
                end;
            21:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field21.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field21.Caption;
                end;
            22:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field22.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field22.Caption;
                end;
            23:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field23.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field23.Caption;
                end;
            24:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field24.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field24.Caption;
                end;
            25:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field25.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field25.Caption;
                end;
            26:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field26.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field26.Caption;
                end;
            27:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field27.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field27.Caption;
                end;
            28:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field28.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field28.Caption;
                end;
            29:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field29.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field29.Caption;
                end;
            30:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field30.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field30.Caption;
                end;
            31:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field31.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field31.Caption;
                end;
            32:
                begin
                    FieldValue := ItemsbyLocation.MatrixForm.Field32.Value();
                    FieldCaption := ItemsbyLocation.MatrixForm.Field32.Caption;
                end;
            else
                Assert.Fail(StrSubstNo('Unsupported column number is provided. ColumnNumber - %1', ColumnNumber));
        end;

        Assert.AreEqual(ExpectedCaption, FieldCaption, 'Wrong matrix caption');
        Assert.AreEqual(Format(ExpectedValue, 0, 9), Format(FieldValue, 0, 9), 'Wrong matrix value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferRoutesMatrixForInTransitCode()
    var
        TransferRoute: Record "Transfer Route";
        ShowOption: Option "In-Transit Code","Shipping Agent Code","Shipping Agent Service Code";
        LocationCode: Code[10];
        MatrixCellValue: Code[10];
    begin
        // Verify Transfer Routes Matrix for In-Transit Code.

        // Setup: Create and modify Transfer Route.
        Initialize();
        CreateAndModifyTransferRoute(TransferRoute);

        // Exercise
        LocationCode := TransferRoute."Transfer-from Code";  // Assign in global variable.
        MatrixCellValue := TransferRoute."In-Transit Code";  // Assign in global variable for verification in handler.

        // Verify
        VerifyTransferRoutesMatrixCellValue(ShowOption::"In-Transit Code", LocationCode, MatrixCellValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferRoutesMatrixForShippingAgentCode()
    var
        TransferRoute: Record "Transfer Route";
        ShowOption: Option "In-Transit Code","Shipping Agent Code","Shipping Agent Service Code";
        LocationCode: Code[10];
        MatrixCellValue: Code[10];
    begin
        // Verify Transfer Routes Matrix for Shipping Agent Code.

        // Setup: Create and modify Transfer Route.
        Initialize();
        CreateAndModifyTransferRoute(TransferRoute);

        // Exercise
        LocationCode := TransferRoute."Transfer-from Code";  // Assign in global variable.
        MatrixCellValue := TransferRoute."Shipping Agent Code";  // Assign in global variable for verification in handler.

        // Verify
        VerifyTransferRoutesMatrixCellValue(ShowOption::"Shipping Agent Code", LocationCode, MatrixCellValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferRoutesMatrixForShippingAgentServiceCode()
    var
        TransferRoute: Record "Transfer Route";
        ShowOption: Option "In-Transit Code","Shipping Agent Code","Shipping Agent Service Code";
        LocationCode: Code[10];
        MatrixCellValue: Code[10];
    begin
        // Verify Transfer Routes Matrix for Shipping Agent Service Code.

        // Setup: Create and modify Transfer Route.
        Initialize();
        CreateAndModifyTransferRoute(TransferRoute);

        // Exercise
        LocationCode := TransferRoute."Transfer-from Code";  // Assign in global variable.
        MatrixCellValue := TransferRoute."Shipping Agent Service Code";  // Assign in global variable for verification in handler.

        // Verify
        VerifyTransferRoutesMatrixCellValue(ShowOption::"Shipping Agent Service Code", LocationCode, MatrixCellValue);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByPeriodsPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByPeriodAfterShipTransferOrder()
    begin
        // Verify Projected Available Balance on Item Availability by Period window after Ship the Transfer Order.
        ItemAvailabilityByPeriodAfterPostingTransferOrder(true, false);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByPeriodsPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByPeriodAfterReceiveTransferOrder()
    begin
        // Verify Projected Available Balance on Item Availability by Period window after Receive the Transfer Order.
        ItemAvailabilityByPeriodAfterPostingTransferOrder(true, true);
    end;

    local procedure ItemAvailabilityByPeriodAfterPostingTransferOrder(Ship: Boolean; Receive: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
        ItemCard: TestPage "Item Card";
    begin
        // Setup: Create and post Item Journal Line, Create and post Transfer Order.
        Initialize();
        GlobalQuantity := LibraryRandom.RandDec(100, 2);  // Use Random value for Quantity.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateAndPostItemJournalLine(ItemJournalLine, CreateItem(), Location.Code, GlobalQuantity);
        CreateTransferOrder(TransferHeader, ItemJournalLine."Location Code", ItemJournalLine."Item No.", ItemJournalLine.Quantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, Ship, Receive);

        // Exercise: Open Availability by Period Page from Item Card.
        ItemCard.OpenView();
        ItemCard.FILTER.SetFilter("No.", ItemJournalLine."Item No.");
        ItemCard.Period.Invoke();

        // Verify: Verify Projected Available Balance on Item Availability by Period window using ItemAvailabilityByPeriodsPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRetOrderWithItemTrackingUsingAdjmt()
    var
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // Verify Unit Cost on Item After Adjustment using Sales Order and Item Journal Line with Item Costing Method Average and Item Tracking.

        // Setup: Create Item Journal Line with Item Tracking Code, Create and post a Sales Order.
        Initialize();
        ItemNo := CreateAndPostItemJnlLineWithtemTracking();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", CreateCustomer(), SalesLine.Type::Item, ItemNo, 1);  // Taken 1 for Quantity.
        UpdateSalesLineUnitPrice(SalesLine, LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        SalesLine.OpenItemTrackingLines();
        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify: Verify Unit Cost on Item After Adjustment using Sales Order and Item Journal Line.
        VerifyUnitCostOnItemAfterAdjustment(ItemNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure UnitCostOnItemWithItemJnlLineUsingAdjmt()
    var
        ItemNo: Code[20];
    begin
        // Verify Unit Cost on Item after Adjustment using Item Journal with Item Costing Method Average and Item Tracking.

        // Setup: Create and post Item Journal Line with Item Tracking.
        Initialize();
        ItemNo := CreateAndPostItemJnlLineWithtemTracking();

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify: Verify Unit Cost on Item after Adjustment using Item Journal With Item Costing Method Average and Item Tracking.
        VerifyUnitCostOnItemAfterAdjustment(ItemNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithSalesOrderPostingUsingItemTracking()
    var
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // Verify error message while posting Sales Order with Item Tracking.

        // Setup: Create and post Item Journal Line and Sales Order with Item Tracking.
        Initialize();
        ItemNo := CreateAndPostItemJnlLineWithtemTracking();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, CreateCustomer(), SalesLine.Type::Item, ItemNo, 1);  // Taken 1 for Quantity.
        SalesLine.OpenItemTrackingLines();

        // Exercise.
        asserterror PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // Verify: Verify error message while posting Sales Order with Item Tracking.
        Assert.ExpectedError(StrSubstNo(VariantErr));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartialNegativeAdjmtUsingFiscalYear()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify Cost Amount Actual after partial Negative Adjustment against one Positive Adjustment.

        // Setup: Create Item, setup create Item Journal Line and run Adjustment.
        Initialize();
        ItemNo := CreateItem();
        Quantity := LibraryRandom.RandInt(100);  // Taking Random value for Quantity.
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        CreateAndModifyItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);

        // Create a new fisacl year and Close the previous fiscal years.
        LibraryFiscalYear.CreateFiscalYear();
        LibraryFiscalYear.CloseFiscalYear();
        CreateAndModifyItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemNo, Quantity / 2);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');  // Blank value for Item Category.

        // Verify: Verify Cost Amount Actual after partial Negative Adjustment against one Positive Adjustment.
        VerifyAdjustmentCostAmount(
          ValueEntry, ItemNo, ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", false,
          ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit");
        VerifyAdjustmentCostAmount(
          ValueEntry, ItemNo, ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", false,
          ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit");
        VerifyAdjustmentCostAmount(
          ValueEntry, ItemNo, ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", true,
          ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBaseUnitOfMeasure_ExistingBUoM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Verify that existing item unit of measure can be used as item's base unit of measure

        // Setup: create item, unit of measure, item unit of measure
        Initialize();

        LibraryInventory.CreateItem(Item);

        CreateUoM_and_ItemUoM(UnitOfMeasure, ItemUnitOfMeasure, Item);

        // Exercise: validate Base Unit of Measure
        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);

        // Verify: Base Unit of Measure is updated
        VerifyBaseUnitOfMeasure(Item, UnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBaseUnitOfMeasure_NonExistingBUoM()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        NewUnitOfMeasureCode: Code[10];
    begin
        // Verify that non existing item unit of measure can be used as item's base unit of measure
        // and this unit of measure is created during the validation

        // Setup: create item, unit of measure, item unit of measure
        Initialize();

        Item.Init();
        Item.Insert(true);

        NewUnitOfMeasureCode := CreateNewUnitOfMeasureCode();
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := NewUnitOfMeasureCode;
        UnitOfMeasure.Insert();

        // Exercise: validate Base Unit of Measure with non-existent item unit of measure
        Item.Validate("Base Unit of Measure", NewUnitOfMeasureCode);

        // Verify: new Item Unit of Measure is created
        ItemUnitOfMeasure.Get(Item."No.", NewUnitOfMeasureCode);
        ItemUnitOfMeasure.TestField("Qty. per Unit of Measure", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectExistingUnitOfMeasureAsBaseUnitOfMeasure()
    var
        Item: Record Item;
        FirstUnitOfMeasure: Record "Unit of Measure";
        SecondUnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        CreateUoM_and_ItemUoM(FirstUnitOfMeasure, ItemUnitOfMeasure, Item);
        CreateUoM_and_ItemUoM(SecondUnitOfMeasure, ItemUnitOfMeasure, Item);

        Item.Validate("Base Unit of Measure", FirstUnitOfMeasure.Code);
        Item.Modify(true);
        VerifyBaseUnitOfMeasureSetAndItemUnitOfMeasureInserted(Item, FirstUnitOfMeasure, 2);

        // Test setting with existing to other
        Item.Validate("Base Unit of Measure", SecondUnitOfMeasure.Code);
        Item.Modify(true);
        VerifyBaseUnitOfMeasureSetAndItemUnitOfMeasureInserted(Item, SecondUnitOfMeasure, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectingBaseUnitOfMeasureInsertsItemUnitOfMeasure()
    var
        Item: Record Item;
        FirstUnitOfMeasure: Record "Unit of Measure";
        SecondUnitOfMeasure: Record "Unit of Measure";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(FirstUnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(SecondUnitOfMeasure);

        Item.Validate("Base Unit of Measure", FirstUnitOfMeasure.Code);
        Item.Modify(true);
        VerifyBaseUnitOfMeasureSetAndItemUnitOfMeasureInserted(Item, FirstUnitOfMeasure, 1);

        Item.Validate("Base Unit of Measure", SecondUnitOfMeasure.Code);
        Item.Modify(true);
        VerifyBaseUnitOfMeasureSetAndItemUnitOfMeasureInserted(Item, SecondUnitOfMeasure, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveBaseUnitOfMeasureFromItem()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        Item.Validate("Base Unit of Measure", '');
        Item.Modify(true);

        Assert.AreEqual('', Item."Base Unit of Measure", 'Base unit of measure was not removed from item');
        Assert.IsTrue(ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasure.Code), 'Item unit of measure is should be present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectingUoMForBaseUoMThatHasQtyGreaterThanOneWillTriggerError()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasureQtyGreaterThanOne: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CreateUoM_and_ItemUoM(UnitOfMeasureQtyGreaterThanOne, ItemUnitOfMeasure, Item);
        ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasureQtyGreaterThanOne.Code);
        ItemUnitOfMeasure."Qty. per Unit of Measure" := LibraryRandom.RandIntInRange(2, 1000);
        ItemUnitOfMeasure.Modify(true);

        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        asserterror Item.Validate("Base Unit of Measure", UnitOfMeasureQtyGreaterThanOne.Code);
        Assert.ExpectedError('The quantity per base unit of measure must be 1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotRenameBaseUnitOfMeasureFromItemsUnitOfMeasuresRecord()
    var
        Item: Record Item;
        FirstUnitOfMeasure: Record "Unit of Measure";
        SecondUnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(FirstUnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(SecondUnitOfMeasure);

        Item.Validate("Base Unit of Measure", FirstUnitOfMeasure.Code);
        Item.Modify(true);

        ItemUnitOfMeasure.Get(Item."No.", FirstUnitOfMeasure.Code);
        asserterror ItemUnitOfMeasure.Rename(Item."No.", SecondUnitOfMeasure.Code);
        Assert.ExpectedError('cannot modify');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotDeleteBaseUnitOfMeasureFromItemsUnitOfMeasuresRecord()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Initialize();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasure.Code);
        asserterror ItemUnitOfMeasure.Delete(true);
        Assert.ExpectedError('modify');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameItemUnitOfMeasure()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        NewUnitOfMeasureCode: Code[10];
    begin
        // Verify that rename of item unit of measure caused update of Item."Base Unit of Measure"
        // because it has ValidateTableRelation=No

        // Setup: create item, unit of measure, item unit of measure
        Initialize();

        Item.Init();
        Item.Insert(true);

        CreateUoM_and_ItemUoM(UnitOfMeasure, ItemUnitOfMeasure, Item);

        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify();

        NewUnitOfMeasureCode := CreateNewUnitOfMeasureCode();
        Commit();

        // Exercise: rename unit of measure assigned to Item (and Item Unit of Measure)
        UnitOfMeasure.Rename(NewUnitOfMeasureCode);

        // Verify: Base Unit of Measure is updated
        Item.Get(Item."No.");
        VerifyBaseUnitOfMeasure(Item, NewUnitOfMeasureCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingBaseUnitOfMeasureWithQtyRoundingPrecision()
    var
        Item: Record Item;
        FirstUnitOfMeasure: Record "Unit of Measure";
        SecondUnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        QtyRoudingPrecisionErr: Label 'Qty. Rounding Precision for Base Unit of Measure is incorrect';
    begin
        //Change Base UoM should reset Qty. Rounding Precision
        Initialize();

        Item.Init();
        Item.Insert(true);

        //Create 2 UoM for an Item
        LibraryInventory.CreateUnitOfMeasureCode(FirstUnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(SecondUnitOfMeasure);

        //Assign Base UoM
        Item.Validate("Base Unit of Measure", FirstUnitOfMeasure.Code);
        Item.Modify(true);

        //Assign Qty. Rounding Precision to Base UoM
        ItemUnitOfMeasure.Get(Item."No.", FirstUnitOfMeasure.Code);
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        ItemUnitOfMeasure.Modify(true);

        //Change Base UoM
        Item.Validate("Base Unit of Measure", SecondUnitOfMeasure.Code);
        Item.Modify(true);

        //Old Base UoM should have the default Qty. Rounding Precision
        ItemUnitOfMeasure.Get(Item."No.", FirstUnitOfMeasure.Code);
        Assert.AreEqual(0, ItemUnitOfMeasure."Qty. Rounding Precision", QtyRoudingPrecisionErr);
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplateHandler,ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure CreateItemFromItemTemplate()
    var
        Item: Record Item;
        ItemTemplate: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // Setup: create item, unit of measure, item unit of measure
        Initialize();

        Item.Init();
        Item.Insert(true);

        ItemTemplate.SetRange(Code, SelectItemTemplateCode());
        ItemTemplate.FindFirst();

        LibraryVariableStorage.Enqueue(ItemTemplate.Code);
        ItemTemplMgt.UpdateItemFromTemplate(Item);

        Assert.AreEqual(
          Item."VAT Prod. Posting Group",
          ItemTemplate."VAT Prod. Posting Group",
          StrSubstNo(VatProdPostingGrMatchErr, Item."VAT Prod. Posting Group", ItemTemplate.Code));

        UpdateVatProdCodeInItemTemplate(ItemTemplate.Code);
        ItemTemplate.Get(ItemTemplate.Code);
        Item.Get(Item."No.");

        Assert.AreNotEqual(
          Item."VAT Prod. Posting Group",
          ItemTemplate."VAT Prod. Posting Group",
          StrSubstNo(VatProdPostingGrMostNotMatchErr, Item."VAT Prod. Posting Group", ItemTemplate.Code));

        // Teardown
        asserterror Error('');
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplateHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateItemsFromItemTemplate()
    var
        Item: Record Item;
        ItemTemplate: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // Arrange: create four items.
        Initialize();

        Item.Init();
        Item.Validate("No.", '1');
        Item.Insert(true);
        Item.Init();
        Item.Validate("No.", '2');
        Item.Insert(true);
        Item.Init();
        Item.Validate("No.", '3');
        Item.Insert(true);
        Item.Init();
        Item.Validate("No.", '4');
        Item.Insert(true);

        // Act: Apply templates only to items 1 and 3.
        Item.SetFilter("No.", '1|3');

        ItemTemplate.SetRange(Code, SelectItemTemplateCode());
        ItemTemplate.FindFirst();

        LibraryVariableStorage.Enqueue(ItemTemplate.Code);
        ItemTemplMgt.UpdateItemsFromTemplate(Item);

        // Assess: Templates are applied only to items 1 and 3
        Item.FindSet();
        repeat
            Assert.AreEqual(
              Item."VAT Prod. Posting Group",
              ItemTemplate."VAT Prod. Posting Group",
              StrSubstNo(VatProdPostingGrMatchErr, Item."VAT Prod. Posting Group", ItemTemplate.Code));
        until Item.Next() = 0;

        // Assess: Templates are not applied to items 2 and 4
        Item.SetFilter("No.", '2|4');
        Item.FindSet();
        repeat
            Assert.AreNotEqual(
              Item."VAT Prod. Posting Group",
              ItemTemplate."VAT Prod. Posting Group",
              StrSubstNo(VatProdPostingGrMostNotMatchErr, Item."VAT Prod. Posting Group", ItemTemplate.Code));
        until Item.Next() = 0;

        UpdateVatProdCodeInItemTemplate(ItemTemplate.Code);
        ItemTemplate.Get(ItemTemplate.Code);

        Item.SetFilter("No.", '1|2|3|4');
        Item.FindSet();
        repeat
            Assert.AreNotEqual(
              Item."VAT Prod. Posting Group",
              ItemTemplate."VAT Prod. Posting Group",
              StrSubstNo(VatProdPostingGrMostNotMatchErr, Item."VAT Prod. Posting Group", ItemTemplate.Code));
        until Item.Next() = 0;

        // Teardown
        asserterror Error('');
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplateHandler')]
    [Scope('OnPrem')]
    procedure InsertItemFromItemTemplate()
    var
        Item: Record Item;
        ItemTemplate: Record "Item Templ.";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [FEATURE] [Item Template] [Unit of Measure]
        // [SCENARIO 203626] Item Unit of Measure should be created for the default Unit of Measure if Item Template has empty Base Unit of Measure
        Initialize();

        // [GIVEN] Item Template with empty Base Unit of Measure
        Item.Init();
        LibraryTemplates.CreateItemTemplateWithData(ItemTemplate);
        ItemTemplate."Base Unit of Measure" := '';
        ItemTemplate.Modify();
        LibraryVariableStorage.Enqueue(ItemTemplate.Code);

        // [WHEN] Create new Item using Item Template
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] Item Unit Of Measure is created for Unit of Measure of the Item
        Assert.IsTrue(ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure"), 'Item Unit of Measure should be created.');
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplateHandler')]
    procedure CreateItemFromItemTemplateWithoutInventoryValueZero()
    var
        Item: Record Item;
        ItemTemplate: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [FEATURE] [Item Template] [Inventory Value Zero]
        // [SCENARIO 80] Item 'Inventory Value Zero' should be empty if created from an item template with empty 'Inventory Value Zero'
        Initialize();

        // [GIVEN] Item Template with empty 'Inventory Value Zero'
        Item.Init();
        LibraryTemplates.CreateItemTemplate(ItemTemplate);
        ItemTemplate."Inventory Value Zero" := false;
        ItemTemplate.Modify();
        LibraryVariableStorage.Enqueue(ItemTemplate.Code);

        // [WHEN] Create new Item using Item Template
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] 'Inventory Value Zero' is empty        
        Assert.AreEqual(ItemTemplate."Inventory Value Zero", Item."Inventory Value Zero", 'Inventory Value Zero must be empty');
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplateHandler')]
    procedure CreateItemFromItemTemplateWithInventoryValueZero()
    var
        Item: Record Item;
        ItemTemplate: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [FEATURE] [Item Template] [Inventory Value Zero]
        // [SCENARIO 80] Item 'Inventory Value Zero' should be set if created from an item template with 'Inventory Value Zero' set 
        Initialize();

        // [GIVEN] Item Template with 'Inventory Value Zero' set
        Item.Init();
        LibraryTemplates.CreateItemTemplate(ItemTemplate);
        ItemTemplate."Inventory Value Zero" := true;
        ItemTemplate.Modify();
        LibraryVariableStorage.Enqueue(ItemTemplate.Code);

        // [WHEN] Create new Item using Item Template
        ItemTemplMgt.InsertItemFromTemplate(Item);

        // [THEN] 'Inventory Value Zero' is set         
        Assert.AreEqual(ItemTemplate."Inventory Value Zero", Item."Inventory Value Zero", 'Inventory Value Zero must be set');
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageHandler,ItemStatisticsPageHandler,ItemStatisticsMatrixPageHandlerForSpecificLine')]
    [Scope('OnPrem')]
    procedure ItemStatisticsMatrixForItemChargePostedAsPurchaseCreditMemo()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Verify Non-Invtbl. Costs and Profit in Item Statistics when item charge is posted as Purchase Credit Memo.

        // Setup: Create Purchase Return Order with 2 Purchase Lines, one for Item, one for Item Charge. Assign Item Charge to the Item.
        Initialize();
        CreatePurchaseDocumentAndAssignItemCharge(PurchaseLine, PurchaseLine2, PurchaseLine."Document Type"::"Return Order");

        // Exercise: Post Purchase Document as Receive and Invoice.
        GlobalDocumentNo := PostPurchaseOrder(PurchaseLine."Document Type", PurchaseLine."Document No.", true);

        // Verify: Verify Non-Invtbl. Costs and Profit Amount on Item Statistics Matrix Page Handler.
        VerifyNonInvtblCostsAndProfitOnItemStatistics(
            PurchaseLine."No.", PurchaseLine2.Quantity * PurchaseLine2."Direct Unit Cost",
            PurchaseLine2.Quantity * PurchaseLine2."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ItemStatisticsPageHandler,ItemStatisticsMatrixPageHandlerForSpecificLine')]
    [Scope('OnPrem')]
    procedure ItemStatisticsMatrixForItemChargePostedAsPurchaseInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Item: Record Item;
    begin
        // Verify Non-Invtbl. Costs and Profit in Item Statistics when item charge is posted as Purchase Invoice.

        // Setup: Create Purchase Return Order with one line and post it. Create Purchase Order with one line for Item Charge.
        // Assign Item Charge to Purchase Return Shipment.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order",
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        CreateItemChargeAndAssignToReturnShipment(PurchaseLine2, PurchaseLine, PurchaseLine2."Document Type"::Order);

        // Exercise: Post Item Charge as Purchase Invoice.
        GlobalDocumentNo := PostPurchaseOrder(PurchaseLine2."Document Type", PurchaseLine2."Document No.", true);

        // Verify: Verify Non-Invtbl. Costs and Profit Amount on ItemStatisticsMatrixPage Handler.
        VerifyNonInvtblCostsAndProfitOnItemStatistics(
          PurchaseLine."No.", -PurchaseLine2."Line Amount", -PurchaseLine2."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUOMForNotBlankItemIsTakenFromItemUnitOfMeasureTable()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Sales] [Unit of Measure]
        // [SCENARIO] "Sales Unit of Measure" of Item with not blank "No." is taken from Item Unit of Measure table

        // [GIVEN] Item with not blank "No."
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();

        // [GIVEN] "Item Unit of Measure" - "X"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);

        // [WHEN] Set "Sales Unit of Measure" on Item to "X"
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);

        // [THEN] "Sales Unit of Measure" is "X"
        Assert.AreEqual(UnitOfMeasure.Code, Item."Sales Unit of Measure", StrSubstNo(UOMErr, Item.FieldName("Sales Unit of Measure")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUOMForNotBlankItemIsTakenFromItemUnitOfMeasureTable()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Purchase] [Unit of Measure]
        // [SCENARIO] "Purch. Unit of Measure" of Item with not blank "No." is taken from Item Unit of Measure table

        // [GIVEN] Item with not blank "No."
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();

        // [GIVEN] "Item Unit of Measure" - "X"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);

        // [WHEN] Set "Purch. Unit of Measure" on Item to "X"
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);

        // [THEN] "Purch. Unit of Measure" is "X"
        Assert.AreEqual(UnitOfMeasure.Code, Item."Purch. Unit of Measure", StrSubstNo(UOMErr, Item.FieldName("Purch. Unit of Measure")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhileSettingSalesUOMOnNotBlankItemByValueFromUnitOfMeasure()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Sales] [Unit of Measure]
        // [SCENARIO] "Sales Unit of Measure" of Item does not accept "Unit of Measure" that is not in "Item Unit of Measure"

        // [GIVEN] Two Unit of Measures: "X" and "Y"
        // [GIVEN] Item with not blank "No." and "Item Unit of Measure" - "X"
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [WHEN] Set "Sales Unit of Measure" on Item to "Y"
        asserterror Item.Validate("Sales Unit of Measure", UnitOfMeasure.Code);

        // [THEN] Error message: "The field Sales Unit of Measure of table Item contains a value that cannot be found in the related table"
        Assert.ExpectedError(StrSubstNo(ItemUOMErr, Item.FieldName("Sales Unit of Measure")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhileSettingPurchUOMOnNotBlankItemByValueFromUnitOfMeasure()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Purchase] [Unit of Measure]
        // [SCENARIO] "Purch. Unit of Measure" of Item does not accept "Unit of Measure" that is not in "Item Unit of Measure"

        // [GIVEN] Two Unit of Measures: "X" and "Y"
        // [GIVEN] Item with not blank "No." and "Item Unit of Measure" - "X"
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [WHEN] Set "Purch. Unit of Measure" on Item to "Y"
        asserterror Item.Validate("Purch. Unit of Measure", UnitOfMeasure.Code);

        // [THEN] Error message: "The field Purch. Unit of Measure of table Item contains a value that cannot be found in the related table"
        Assert.ExpectedError(StrSubstNo(ItemUOMErr, Item.FieldName("Purch. Unit of Measure")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayUOMForBlankItemIsTakenFromUnitOfMeasureTable()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Item] [Unit of Measure]
        // [SCENARIO] "Put-away Unit of Measure Code" of Item with blank "No." is taken from Unit of Measure table

        // [GIVEN] Item with blank "No."
        Item.Init();

        // [GIVEN] "Unit of Measure" - "X"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [WHEN] Set "Put-away Unit of Measure Code" on Item to "X"
        Item.Validate("Put-away Unit of Measure Code", UnitOfMeasure.Code);

        // [THEN] "Put-away Unit of Measure Code" is "X"
        Assert.AreEqual(
          UnitOfMeasure.Code, Item."Put-away Unit of Measure Code", StrSubstNo(UOMErr, Item.FieldName("Put-away Unit of Measure Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayUOMForNotBlankItemIsTakenFromItemUnitOfMeasureTable()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Item] [Unit of Measure]
        // [SCENARIO] "Put-away Unit of Measure Code" of Item with not blank "No." is taken from Item Unit of Measure table

        // [GIVEN] Item with not blank "No."
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();

        // [GIVEN] "Item Unit of Measure" - "X"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);

        // [WHEN] Set "Put-away Unit of Measure Code" on Item to "X"
        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure.Code);

        // [THEN] "Put-away Unit of Measure Code" is "X"
        Assert.AreEqual(
          UnitOfMeasure.Code, Item."Put-away Unit of Measure Code", StrSubstNo(UOMErr, Item.FieldName("Put-away Unit of Measure Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhileSettingPutAwayUOMOnNotBlankItemByValueFromUnitOfMeasure()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Sales] [Unit of Measure]
        // [SCENARIO] "Put-away Unit of Measure Code" of Item does not accept "Unit of Measure" that is not in "Item Unit of Measure"

        // [GIVEN] Two Unit of Measures: "X" and "Y"
        // [GIVEN] Item with not blank "No." and "Item Unit of Measure" - "X"
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [WHEN] Set "Put-away Unit of Measure Code" on Item to "Y"
        asserterror Item.Validate("Put-away Unit of Measure Code", UnitOfMeasure.Code);

        // [THEN] Error message: "The field Put-away Unit of Measure Code of table Item contains a value that cannot be found in the related table"
        Assert.ExpectedError(StrSubstNo(ItemUOMErr, Item.FieldName("Put-away Unit of Measure Code")));
    end;

    [Test]
    [HandlerFunctions('ProductionBOMPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyProductionBOMFromItemCard()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 371645] Action "Production BOM" on Item Card page should open a BOM page with "No." equal to Item's "Production BOM No."

        // [GIVEN] Production BOM "B" for Item
        CreateItemAndProductionBOM(Item, ProductionBOMHeader);

        // [WHEN] Open Production BOM page from Item Card
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard."Production BOM".Invoke();

        // [THEN] Production BOM page opens with "No." = "B"
        // Verify Production BOM through "ProductionBOMPageHandler"
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVariantMandatoryDefaultCaption()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ItemCard: TestPage "Item Card";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] Inga can make variants mandatory for items globally or on certain items

        // [GIVEN] Inventory setup and an item
        // Inventory setup has "Variant mandatory if exists" = TRUE
        Initialize();
        InventorySetup.Get();

        InventorySetup.Validate("Variant Mandatory if Exists", true);
        InventorySetup.Modify();

        LibraryInventory.CreateItem(Item);

        // [WHEN] Edit record page for item is openend
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] Caption of default value reflects that default is TRUE/Yes
        Assert.Equal(ItemCard.VariantMandatoryDefaultYes.Visible(), true);
        Assert.Equal(ItemCard.VariantMandatoryDefaultNo.Visible(), false);

        // [GIVEN] Inventory setup and an item
        // Inventory setup has "Variant mandatory if exists" = FALSE
        InventorySetup.Validate("Variant Mandatory if Exists", false);
        InventorySetup.Modify();

        LibraryInventory.CreateItem(Item);

        // [WHEN] Edit record page for item is openend
        ItemCard.GotoRecord(Item);

        // [THEN] Caption of default value reflects that default is FALSE/No
        Assert.Equal(ItemCard.VariantMandatoryDefaultYes.Visible(), false);
        Assert.Equal(ItemCard.VariantMandatoryDefaultNo.Visible(), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsVariantMandatoryWithVariantsAvailable()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        InventorySetup: Record "Inventory Setup";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings

        // [GIVEN] Inventory setup with "Variant Mandatory is Exists" = yes
        // and an item which has available variants
        Initialize();
        InventorySetup.Get();

        InventorySetup.Validate("Variant Mandatory if Exists", true);
        InventorySetup.Modify();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateVariant(ItemVariant, Item);

        // [THEN] Item.IsVariantMandatory() is calcuated correctly on different values of Item."Variant Mandatory if Exists"
        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes);
        Assert.Equal(Item.IsVariantMandatory(), true);

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Default);
        Assert.Equal(Item.IsVariantMandatory(), true);

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::No);
        Assert.Equal(Item.IsVariantMandatory(), false);

        // [GIVEN] Inventory setup with "Variant Mandatory is Exists" = yes
        // and an item which has available variants
        InventorySetup.Validate("Variant Mandatory if Exists", false);
        InventorySetup.Modify();

        // [THEN] Item.IsVariantMandatory() is calcuated correctly on different values of Item."Variant Mandatory if Exists"
        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes);
        Assert.Equal(Item.IsVariantMandatory(), true);

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Default);
        Assert.Equal(Item.IsVariantMandatory(), false);

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::No);
        Assert.Equal(Item.IsVariantMandatory(), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsVariantMandatoryNoVariantsAvailable()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ItemVariant: Record "Item Variant";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings

        // [GIVEN] Inventory setup and an item which has NO available variants
        Initialize();
        InventorySetup.Get();

        InventorySetup.Validate("Variant Mandatory if Exists", true);
        InventorySetup.Modify();

        LibraryInventory.CreateItem(Item);
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.DeleteAll();

        // [THEN] Item.IsVariantMandatory() always returns "false" no matter the values of Item."VMiE" and InventorySetup."VMiE"
        InventorySetup.Validate("Variant Mandatory if Exists", true);
        InventorySetup.Modify();

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes);
        Assert.Equal(Item.IsVariantMandatory(), false);

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Default);
        Assert.Equal(Item.IsVariantMandatory(), false);

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::No);
        Assert.Equal(Item.IsVariantMandatory(), false);

        InventorySetup.Validate("Variant Mandatory if Exists", false);
        InventorySetup.Modify();

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes);
        Assert.Equal(Item.IsVariantMandatory(), false);

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Default);
        Assert.Equal(Item.IsVariantMandatory(), false);

        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::No);
        Assert.Equal(Item.IsVariantMandatory(), false);
    end;

    [Test]
    [HandlerFunctions('ProductionBOMPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyProductionBOMFromItemList()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemList: TestPage "Item List";
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 371645] Action "Production BOM" on Item List page should open a BOM page with "No." equal to Item's "Production BOM No."

        // [GIVEN] Production BOM "B" for Item
        CreateItemAndProductionBOM(Item, ProductionBOMHeader);

        // [WHEN] Open Production BOM page from Item List
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        ItemList."Production BOM".Invoke();

        // [THEN] Production BOM page opens with "No." = "B"
        // Verify Production BOM through "ProductionBOMPageHandler"
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesOpenPageHandler')]
    [Scope('OnPrem')]
    procedure CheckItemChargeAssigmentSalesPageWhenQtyToInvoiceIsBlank()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Order] [Item Charge Assigment]
        // [SCENARIO 128475] Item Charge Assigment (Sales) Page should have Qty. to Assign = 0 if appropriate Sales Line has Qty. to Invoice = 0
        Initialize();

        // [GIVEN] Sales Order for Charge (Item) With "Qty. to Invoice" = 0
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateCustomer(), SalesLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify();

        // [WHEN] Open Item Charge Assigment
        // [THEN] Item Charge Assigment Page is opened with Qty to Assign = 0
        SalesLine.ShowItemChargeAssgnt();
    end;

    [Test]
    [HandlerFunctions('ItemCreationMessageHandler,ItemSubstitutionPageHandler')]
    [Scope('OnPrem')]
    procedure CreateNonStockItemWithSubstitution()
    var
        NonstockItem: Record "Nonstock Item";
        Item: Record Item;
        ItemSubstitution: Record "Item Substitution";
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Nonstock Items] [Item Substitution]
        // [SCENARIO 173306] Unable to save Item Substitutions for Nonstock Items
        // [GIVEN] User has created a nonstock item and an item to assign to it
        Initialize();
        CreateNonStockItem(NonstockItem);
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(NonstockItem."Entry No.");

        // [WHEN] User opens Item Substitution Entry for nonstock item and add new
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard."Substituti&ons".Invoke();
        ItemCard.Close();

        // [THEN] Item Substitution record is created
        Assert.IsTrue(FindItemSubstitution(ItemSubstitution.Type::Item, Item."No.",
            ItemSubstitution."Substitute Type"::"Nonstock Item", NonstockItem."Entry No."), 'Item Substitution not found.');
    end;

    [Test]
    [HandlerFunctions('ItemCreationMessageHandler,ItemSubstitutionPageHandler')]
    [Scope('OnPrem')]
    procedure CreateItemWithNonstockItemSubstitution()
    var
        NonstockItem: Record "Nonstock Item";
        Item: Record Item;
        ItemSubstitution: Record "Item Substitution";
        NonstockItemCard: TestPage "Catalog Item Card";
    begin
        // [FEATURE] [Nonstock Items] [Item Substitution]
        // [SCENARIO 173306] Verify Item Substitutions save for Items
        // [GIVEN] User has created an item and a nonstock item to assign to it
        Initialize();
        CreateNonStockItem(NonstockItem);
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(Item."No.");

        // [WHEN] User opens Item Substitution Entry for item and add new
        NonstockItemCard.OpenEdit();
        NonstockItemCard.GotoRecord(NonstockItem);
        NonstockItemCard."Substituti&ons".Invoke();
        NonstockItemCard.Close();

        // [THEN] Item Substitution record is created
        Assert.IsTrue(
            FindItemSubstitution(ItemSubstitution.Type::"Nonstock Item", NonstockItem."Entry No.",
            ItemSubstitution."Substitute Type"::Item, Item."No."), 'Item Substitution not found.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceWorksheetControlNotVisibleOnPhone()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ItemList: TestPage "Item List";
    begin
        // [UI]
        // [SCENARIO 178097] Button to view Sales Price Worksheet page is not visible when run on phone
        Initialize();

        // [GIVEN] Windows Client is used
        // [WHEN] Page Item List is opened
        ItemList.OpenView();
        ItemList."Sales Price Worksheet".Invoke();

        // [THEN] Button to view Sales Price Worksheet page is visible
        Assert.IsTrue(
          ItemList."Sales Price Worksheet".Visible(), StrSubstNo(ControlVisibilityErr, true));
        ItemList.Close();

        // [WHEN] Page Item List is opened from Phone
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);
        ItemList.OpenView();
        ItemList."Sales Price Worksheet".Invoke();

        // [THEN] Button to view Sales Price Worksheet page is not visible
        Assert.IsFalse(
          ItemList."Sales Price Worksheet".Visible(), StrSubstNo(ControlVisibilityErr, false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTurnoverPurchaseQtyDrillDown()
    var
        PurchaseLine: Record "Purchase Line";
        ItemTurnover: TestPage "Item Turnover";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [FEATURE] [Item Turnover] [Purchases]
        // [SCENARIO 381630] Item Statistics Turnover page drills down from Purchases (Qty.) to Item ledger entries

        // [GIVEN] Posted Purchase Order Line PL
        CreateAndPostPurchOrderLine(PurchaseLine);

        // [WHEN] Open Item Turnover Page from Item Card of PL."No.", show postings today, and Drill Down Purchases (Qty.)
        InvokeItemTurnoverFromItemCard(ItemTurnover, PurchaseLine."No.");
        ItemTurnover.ItemTurnoverLines.FILTER.SetFilter("Period Start", Format(WorkDate()));
        ItemLedgerEntries.Trap();
        ItemTurnover.ItemTurnoverLines.PurchasesQty.DrillDown();

        // [THEN] Item Ledger Entries Page is open and field Quantity on this Page is equal to PL.Quantity
        PurchaseLine.TestField(Quantity, ItemLedgerEntries.Quantity.AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTurnoverSalseQtyDrillDown()
    var
        SalesLine: Record "Sales Line";
        ItemTurnover: TestPage "Item Turnover";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [FEATURE] [Item Turnover] [Sales]
        // [SCENARIO 381630] Item Statistics Turnover page drills down from Sales (Qty.) to Item ledger entries

        // [GIVEN] Posted Sales Order Line SL
        CreateAndPostSalesOrderLine(SalesLine);

        // [WHEN] Open Item Turnover Page from Item Card of SL."No.", show postings today, and Drill Down Sales (Qty.)
        InvokeItemTurnoverFromItemCard(ItemTurnover, SalesLine."No.");
        ItemTurnover.ItemTurnoverLines.FILTER.SetFilter("Period Start", Format(WorkDate()));
        ItemLedgerEntries.Trap();
        ItemTurnover.ItemTurnoverLines.SalesQty.DrillDown();

        // [THEN] Item Ledger Entries Page is open and the value of the field Quantity is -SL.Quantity
        SalesLine.TestField(Quantity, -ItemLedgerEntries.Quantity.AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTurnoverPurchaseAmntDrillDown()
    var
        PurchaseLine: Record "Purchase Line";
        ItemTurnover: TestPage "Item Turnover";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Item Turnover] [Purchases]
        // [SCENARIO 381630] Item Statistics Turnover page drills down from Purchases (LCY) to Value entries

        // [GIVEN] Posted Purchase Order Line PL
        CreateAndPostPurchOrderLine(PurchaseLine);

        // [WHEN] Open Item Turnover Page from Item Card of PL."No.", show postings today, and Drill Down Purchases (LCY)
        InvokeItemTurnoverFromItemCard(ItemTurnover, PurchaseLine."No.");
        ItemTurnover.ItemTurnoverLines.FILTER.SetFilter("Period Start", Format(WorkDate()));
        ValueEntries.Trap();
        ItemTurnover.ItemTurnoverLines.PurchasesLCY.DrillDown();

        // [THEN] Value Entries Page is open and field Purchases (LCY) on this Page is equal to PL.Amount
        PurchaseLine.TestField(Amount, ValueEntries."Cost Amount (Actual)".AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTurnoverSalseQtyAmntlDown()
    var
        SalesLine: Record "Sales Line";
        ItemTurnover: TestPage "Item Turnover";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Item Turnover] [Sales]
        // [SCENARIO 381630] Item Statistics Turnover page drills down from Sales (LCY) to Value entries

        // [GIVEN] Posted Sales Order Line SL
        CreateAndPostSalesOrderLine(SalesLine);

        // [WHEN] Open Item Turnover Page from Item Card of SL."No.", show postings today, and Drill Down Sales (LCY)
        InvokeItemTurnoverFromItemCard(ItemTurnover, SalesLine."No.");
        ItemTurnover.ItemTurnoverLines.FILTER.SetFilter("Period Start", Format(WorkDate()));
        ValueEntries.Trap();
        ItemTurnover.ItemTurnoverLines.SalesLCY.DrillDown();

        // [THEN] Value Entries Page is open and field Sales (LCY) on this Page is equal to SL.Amount
        SalesLine.TestField(Amount, ValueEntries."Sales Amount (Actual)".AsDecimal());
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultDimHeaderOnSubstitute()
    var
        ItemSubstitution: Record "Item Substitution";
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        ItemSubstMgt: Codeunit "Item Subst.";
    begin
        // [FEATURE] [Item Substitution] [Dimension] [Default Dimension] [Sales]
        // [SCENARIO 231338] Default dimensions from the customer should be set for a sales line when the item is replaced with a substitution

        Initialize();

        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Item "I" with a substitution item "S"
        CreateItemWithSubstitution(ItemSubstitution);

        // [GIVEN] Customer "C" with default dimension
        CreateCustomerWithDefaultDimension(Customer, DimensionValue);

        // [GIVEN] Sales order for the item "I" and customer "C"
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, Customer."No.", SalesLine.Type::Item, ItemSubstitution."No.",
          LibraryRandom.RandInt(50));

        // [WHEN] Select the item substitution in the sales line
        ItemSubstMgt.ItemSubstGet(SalesLine);

        // [THEN] Default dimension value is copied from the customer card
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        DimensionSetEntry.FindFirst();
        SalesLine.TestField("Dimension Set ID", DimensionSetEntry."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultDimLineOnSubstitute()
    var
        ItemSubstitution: Record "Item Substitution";
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: array[3] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesLine: Record "Sales Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        ItemSubstMgt: Codeunit "Item Subst.";
    begin
        // [FEATURE] [Item Substitution] [Dimension] [Default Dimension] [Sales]
        // [SCENARIO 231338] Default dimensions from the substitution item should be set for a sales line when the item is replaced with the substitution

        Initialize();

        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Item "I" with a substitution item "S"
        CreateItemWithSubstitution(ItemSubstitution);

        // [GIVEN] Customer "C" with default dimension "D1", dimension value "V1"
        CreateCustomerWithDefaultDimension(Customer, DimensionValue[1]);

        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[3], Dimension.Code);

        // [GIVEN] Item "I" has a default dimension "D2" with value "V2"
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, ItemSubstitution."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
        // [GIVEN] Substitution item "S" has a default dimension "D2" with value "V3"
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, ItemSubstitution."Substitute No.", Dimension.Code, DimensionValue[3].Code);

        // [GIVEN] Sales order for the item "I" and customer "C"
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, Customer."No.", SalesLine.Type::Item, ItemSubstitution."No.",
          LibraryRandom.RandInt(50));

        // [WHEN] Select the item substitution in the sales line
        ItemSubstMgt.ItemSubstGet(SalesLine);

        // [THEN] Dimension set in the sales line includes dimension "D1" with value "V1" and dimension "D2" with value "V3"
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue[3]."Dimension Code");
        DimensionSetEntry.SetRange("Dimension Value Code", DimensionValue[3].Code);
        DimensionSetEntry.FindFirst();
        SalesLine.TestField("Dimension Set ID", DimensionSetEntry."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATBusPostingGrPriceAvailableOnItemCard()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item Card]
        // [SCENARIO 255987] "VAT Bus. Posting Gr. (Price)" must be available on Item Card
        Initialize();

        // [GIVEN] Item
        LibraryInventory.CreateItem(Item);

        // [WHEN] Item Card is opened for Item
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] "VAT Bus. Posting Gr. (Price)" is available on Item Card
        Assert.IsTrue(ItemCard."VAT Bus. Posting Gr. (Price)".Enabled(), '"VAT Bus. Posting Gr. (Price)" is not enabled.');
        Assert.IsTrue(ItemCard."VAT Bus. Posting Gr. (Price)".Visible(), '"VAT Bus. Posting Gr. (Price)" is not visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATBusPostingGrPriceAvailableOnItemCardWithAdvAppArea()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item Card]
        // [SCENARIO 255987] "VAT Bus. Posting Gr. (Price)" must be available on Item Card with Advanced Application Area
        Initialize();

        // [GIVEN] Advanced Application Area
        LibraryApplicationArea.EnablAdvancedSetupForCurrentCompany();

        // [GIVEN] Item
        LibraryInventory.CreateItem(Item);

        // [WHEN] Item Card is opened for Item
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] "VAT Bus. Posting Gr. (Price)" is available on Item Card
        Assert.IsTrue(ItemCard."VAT Bus. Posting Gr. (Price)".Enabled(), '"VAT Bus. Posting Gr. (Price)" is not enabled.');
        Assert.IsTrue(ItemCard."VAT Bus. Posting Gr. (Price)".Visible(), '"VAT Bus. Posting Gr. (Price)" is not visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATBusPostingGrPriceAvailableOnItemCardWithBasicAppArea()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item Card] [Application Area]
        // [SCENARIO 255987] "VAT Bus. Posting Gr. (Price)" must not be available on Item Card not Advanced Application Area
        Initialize();

        // [GIVEN] Basic Application Area
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Item
        LibraryInventory.CreateItem(Item);

        // [WHEN] Item Card is opened for Item
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] "VAT Bus. Posting Gr. (Price)" is available on Item Card
        asserterror Assert.IsTrue(ItemCard."VAT Bus. Posting Gr. (Price)".Enabled(), '"VAT Bus. Posting Gr. (Price)" is not enabled.');
        Assert.ExpectedError(IsNotFoundOnThePageTxt);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotDeleteItemUnitOfMeasureSetAsPutawayUnitOfMeasureOnItemCard()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Item Unit of Measure] [Item] [UT]
        // [SCENARIO 273614] You cannot delete item unit of measure that is set as "Put-away Unit of Measure Code" on item.
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 5));

        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        asserterror ItemUnitOfMeasure.Delete(true);

        Assert.ExpectedError('You cannot modify item unit of measure');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateItemFromNonStockItemCopiesItemDiscGroupFromTemplate()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        ItemTemplate: Record "Item Templ.";
        NonstockItem: Record "Nonstock Item";
        Item: Record Item;
        CatalogItemManagement: Codeunit "Catalog Item Management";
    begin
        // [FEATURE] [Nonstock Item] [Item Template] [Item]
        // [SCENARIO 312851] "Item Disc. Group", "Include Inventory", and "Critical" fields are copied from Template to Item, when Item is created from Nonstock Item which has that Template specified
        Initialize();

        // [GIVEN] Item Template with Item Disc. Group "A"
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        LibraryTemplates.CreateItemTemplateWithData(ItemTemplate);
        ItemTemplate.Validate("Item Disc. Group", ItemDiscountGroup.Code);

        // [GIVEN] Set the reordering policy in the template and enable "Include Inventory" and "Critical"
        ItemTemplate.Validate("Include Inventory", true);
        ItemTemplate.Validate(Critical, true);
        ItemTemplate.Validate("Indirect Cost %", LibraryRandom.RandIntInRange(10, 20));
        ItemTemplate.Modify(true);

        // [GIVEN] Nonstock Item with Item Template and Vendor Item No. 2100
        LibraryInventory.CreateNonStockItem(NonstockItem);
        Item.Get(NonstockItem."Vendor Item No.");
        Item.Delete();
        NonstockItem.Validate("Item Templ. Code", ItemTemplate.Code);
        NonstockItem.Modify(true);

        // [WHEN] Create Item from Nonstock Item via Catalog Item Management
        CatalogItemManagement.NonstockAutoItem(NonstockItem);

        // [THEN] Item with No 2100 and Item Disc. Group "A" is created
        Item.Get(NonstockItem."Vendor Item No.");
        Assert.AreEqual(ItemTemplate."Item Disc. Group", Item."Item Disc. Group", StrSubstNo(UnexpectedValueErr, Item.FieldName("Item Disc. Group"), Item.TableName));
        Assert.AreEqual(ItemTemplate."Include Inventory", Item."Include Inventory", StrSubstNo(UnexpectedValueErr, Item.FieldName("Include Inventory"), Item.TableName));
        Assert.AreEqual(ItemTemplate.Critical, Item.Critical, StrSubstNo(UnexpectedValueErr, Item.FieldName(Critical), Item.TableName));
        Assert.AreEqual(ItemTemplate."Indirect Cost %", Item."Indirect Cost %", StrSubstNo(UnexpectedValueErr, Item.FieldName("Indirect Cost %"), Item.TableName));
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentNegQtySalesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPostingWithNegativeQtyItemChargeAssignment()
    var
        SalesLine: Record "Sales Line";
        ItemChargeNo: Code[20];
    begin
        // [FEATURE] [Item Charge] [Sales]
        // [SCENARIO 323155] Cannot post a Sales Order with insufficient ledger entries for negative quantity Item Charge
        Initialize();

        // [GIVEN] Created Sales Order with negative quantity Item Charge assigned and two Item lines
        // [GIVEN] Set "Qty. to Ship"=0 on one of them after Charge Assignment
        ItemChargeNo := CreateSalesOrderAndAssignNegativeQtyItemCharge(SalesLine);

        // [WHEN] Post Sales Order
        asserterror PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [THEN] An error is thrown: "You can not invoice item charge .. because there is no item ledger entry to assign it to."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemChargeErr, ItemChargeNo));
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentNegQtyPurchPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPostingWithNegativeQtyItemChargeAssignment()
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeNo: Code[20];
    begin
        // [FEATURE] [Item Charge] [Purchase]
        // [SCENARIO 323155] Cannot post a Purchase Order with insufficient ledger entries for negative quantity Item Charge
        Initialize();

        // [GIVEN] Created Purchase Order with negative quantity Item Charge assigned and two Item lines
        // [GIVEN] Set "Qty. to Ship"=0 on one of them after Charge Assignment
        ItemChargeNo := CreatePurchaseOrderAndAssignNegativeQtyItemCharge(PurchaseLine);

        // [WHEN] Post Purchase Order
        asserterror PostPurchaseOrder(PurchaseLine."Document Type", PurchaseLine."Document No.", true);

        // [THEN] An error is thrown: "You can not invoice item charge .. because there is no item ledger entry to assign it to."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemChargeErr, ItemChargeNo));
    end;

    [Test]
    [HandlerFunctions('CatalogItemListModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SelectingNonstockItemsOnSalesLine()
    var
        NonstockItem: array[2] of Record "Nonstock Item";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Quote] [Nonstock Item] [Item Template]
        // [SCENARIO 337686] Stan can add two nonstock items to sales quote.
        Initialize();

        // [GIVEN] Nonstock items "NI1", "NI2".
        CreateNonStockItem(NonstockItem[1]);
        CreateNonStockItem(NonstockItem[2]);

        // [GIVEN] Create sales quote header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');

        // [GIVEN] Add a line to the sales quote, select nonstock item "NI1".
        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        LibraryVariableStorage.Enqueue(NonstockItem[1]."Vendor Item No.");
        SalesLine.ShowNonstock();

        // [WHEN] Add another line to the sales quote, select nonstock item "NI2".
        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        LibraryVariableStorage.Enqueue(NonstockItem[2]."Vendor Item No.");
        SalesLine.ShowNonstock();

        // [THEN] "NI2" is selected on the sales line.
        SalesLine.TestField("No.", NonstockItem[2]."Vendor Item No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DeleteCatalogItemWithItemCreated()
    var
        NonstockItem: Record "Nonstock Item";
        Item: Record Item;
    begin
        // [FEATURE] [Nonstock Item] [Item Template] [Item]
        // [SCENARIO 386556] Item created from a Catalog Item has flag "Created From Nonstock Item" cleared on Catalog Item deletion
        Initialize();

        // [GIVEN] Nonstock Item with Item Template and Vendor Item No. 2100
        // [GIVEN] Create Item from Nonstock Item via Catalog Item Management
        LibraryInventory.CreateNonStockItem(NonstockItem);
        NonstockItem.Find();
        Item.Get(NonstockItem."Item No.");

        // [WHEN] Delete the catalog item
        NonstockItem.Delete(true);

        // [THEN] Item with No 2100 has flag "Created From Nonstock Item" cleared
        Item.Find();
        Item.TestField("Created From Nonstock Item", false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DeleteItemCreatedFromCatalogItem()
    var
        NonstockItemSetup: Record "Nonstock Item Setup";
        NonstockItem: Record "Nonstock Item";
        Item: Record Item;
    begin
        // [FEATURE] [Nonstock Item] [Item Template] [Item]
        Initialize();

        // [GIVEN] The Item No. Series has been setup in NonStock Item Setup
        // [GIVEN] Nonstock Item with Item Template and Vendor Item No.
        // [GIVEN] Create Item from Nonstock Item via Catalog Item Management
        NonstockItemSetup.Get();
        NonstockItemSetup."No. Format" := NonstockItemSetup."No. Format"::"Item No. Series";
        NonstockItemSetup.Modify();
        LibraryInventory.CreateNonStockItem(NonstockItem);
        NonstockItem.Find();
        Item.Get(NonstockItem."Item No.");

        // [WHEN] Delete the catalog item
        Item.Delete(true);

        // [THEN] Item with No 2100 has flag "Created From Nonstock Item" cleared
        NonstockItem.Find();
        NonstockItem.TestField("Item No.", '');
        NonstockItem.TestField("Item No. Series", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DeleteSalesLineWithItemFromDeletedCatalogItem()
    var
        NonstockItem: Record "Nonstock Item";
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Nonstock Item] [Item Template] [Item] [Sales]
        // [SCENARIO 386556] Deleting a Nonstock Sales Line for an Item created from an afterwards deleted Catalog Item doesn't delete the Item
        Initialize();

        // [GIVEN] Nonstock Item with Item Template and Vendor Item No. 2100
        // [GIVEN] Create Item from Nonstock Item via Catalog Item Management
        LibraryInventory.CreateNonStockItem(NonstockItem);
        NonstockItem.Find();
        Item.Get(NonstockItem."Item No.");

        // [GIVEN] Sales Order created with Sales Line for Item No. 2100
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] The catalog item deleted
        NonstockItem.Delete(true);

        // [WHEN] Delete the Sales Line
        SalesLine.Delete(true);

        // [THEN] Item No 2100 is not deleted
        Item.Find();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure LeadTimeCalculationOnItemFromNonstock()
    var
        Vendor: Record Vendor;
        NonstockItem: Record "Nonstock Item";
        Item: Record Item;
        CatalogItemManagement: Codeunit "Catalog Item Management";
        LeadTimeFormula: DateFormula;
    begin
        // [FEATURE] [Nonstock Items] [Lead Time Calculation]
        // [SCENARIO 416830] Lead Time Calculation in an item created from a nonstock item.
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Evaluate(LeadTimeFormula, '<1M>');
        Vendor.Validate("Lead Time Calculation", LeadTimeFormula);
        Vendor.Modify(true);

        LibraryInventory.CreateNonStock(NonstockItem);
        NonstockItem.Validate("Vendor No.", Vendor."No.");
        NonstockItem.Validate(
          "Vendor Item No.", LibraryUtility.GenerateRandomCode(NonstockItem.FieldNo("Vendor Item No."), DATABASE::"Nonstock Item"));
        NonstockItem.Validate("Item Templ. Code", SelectItemTemplateCode());
        NonstockItem.Modify(true);
        UpdateItemTemplate(NonstockItem."Item Templ. Code");

        CatalogItemManagement.NonstockAutoItem(NonstockItem);

        Item.Get(NonstockItem."Vendor Item No.");
        Item.TestField("Lead Time Calculation", Vendor."Lead Time Calculation");
    end;

    [Test]
    procedure TestSetupItemNoSeriesFormat()
    var
        NonstockItemSetup: Record "Nonstock Item Setup";
    begin
        // [FEATURE] [Nonstock Item Setup] [Setup Item No. Series Format]
        Initialize();

        // [GIVEN] The NonStock Item Setup exist
        NonstockItemSetup.Get();

        // [WHEN] Change No. Format to "Item No. Series"
        NonstockItemSetup.Validate("No. Format", NonstockItemSetup."No. Format"::"Item No. Series");
        NonstockItemSetup.Modify();
        Commit();

        // [THEN] Changing of "No. Format Separator" is not allowed
        asserterror NonstockItemSetup.Validate("No. Format Separator", ';');

        // [WHEN] Change No. Format to "Item No. Series"
        NonstockItemSetup.Validate("No. Format", NonstockItemSetup."No. Format"::"Vendor Item No.");
        NonstockItemSetup.Modify();

        // [THEN] Changing of "No. Format Separator" is allowed
        NonstockItemSetup.TestField("No. Format Separator", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateItemWithItemNoSeriesFormat()
    var
        NonstockItemSetup: Record "Nonstock Item Setup";
        NonstockItem: Record "Nonstock Item";
        Item: Record Item;
    begin
        // [FEATURE] [Nonstock Items] [Item No. Series Format]
        Initialize();

        // [GIVEN] The Item No. Series has been setup in NonStock Item Setup
        NonstockItemSetup.Get();
        NonstockItemSetup."No. Format" := NonstockItemSetup."No. Format"::"Item No. Series";
        NonstockItemSetup.Modify();

        // [WHEN] Create Item from Nonstock Item
        CreateNonStockItem(NonstockItem);

        // [THEN] Item created using Item No Series
        Item.Get(NonstockItem."Item No.");
        Item.TestField("No. Series", NonstockItem."Item No. Series");
    end;

    [Test]
    [HandlerFunctions('CancelItemTemplateHandler,ConfirmHandler,NoSeriesListModalPageHandler')]
    procedure CreateItemFromBlankCardWithRelatedNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        RelatedNoSeriesLine: Record "No. Series Line";
        ItemCard: TestPage "Item Card";
        ExpectedItemNo: Code[20];
    begin
        // [SCENARIO 481615] Create Item from Blank Card with Related No. Series
        Initialize();

        // [GIVEN] No. Series "Y" with "Default Nos" = Yes and no. series line setup
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(RelatedNoSeriesLine, RelatedNoSeries.Code, '', '');
        LibraryVariableStorage.Enqueue(RelatedNoSeries.Code);
        ExpectedItemNo := LibraryUtility.GetNextNoFromNoSeries(RelatedNoSeries.Code, WorkDate());

        // [GIVEN] No. Series "X" with "Default Nos" = Yes and related No. series "Y". Next "No." in no. series is "X1"
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);

        // [GIVEN] Set default No. Series for Item on Inventory Setup
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", NoSeries.Code);
        InventorySetup.Modify(true);

        // [WHEN] Open Item Card in New mode and call Assist Edit on "No." field
        ItemCard.OpenNew();
        ItemCard."No.".AssistEdit();

        // [THEN] Verify results
        Assert.AreEqual(ItemCard."No.".Value, ExpectedItemNo, 'Expected Item No. is not equal to actual.');
    end;

    [Test]
    procedure RunningBalance()
    var
        ItemledgerEntry: Record "Item Ledger Entry";
        Item: Record "Item";
        Location: Record Location;
        CalcRunningInvBalance: Codeunit "Calc. Running Inv. Balance";
        i: Integer;
        TotalQuantity: Decimal;
        TotalQuantityLoc: Decimal;
        TotalQuantityNoLoc: Decimal;
    begin
        // [SCENARIO] Item ledger entries show a running balance
        // [FEATURE] [Item]

        // [GIVEN] Item and some entries - also more on same day.
        LibraryInventory.CreateItem(Item);
        Location.Code := CopyStr(format(CreateGuid()), 1, MaxStrLen(Location.Code));

        if ItemledgerEntry.FindLast() then;
        for i := 1 to 15 do begin
            ItemledgerEntry."Entry No." += 1;
            ItemledgerEntry."Item No." := Item."No.";
            ItemledgerEntry."Posting Date" := DMY2Date(1 + i div 3, 1, 2025);  // should give Januar 1,2,2,3,3,4,4,...
            if i mod 2 = 0 then
                ItemledgerEntry."Location Code" := Location.Code
            else
                ItemledgerEntry."Location Code" := '';
            ItemledgerEntry.Quantity := 1;
            ItemledgerEntry.Insert();
        end;

        // [WHEN] Running balance is calculated per entry
        // [THEN] Inventory and InventoryLoc are the sum of entries up till then.
        Item.CalcFields(Inventory);
        Assert.AreEqual(15, Item.Inventory, 'Quantity out of balance.');
        ItemledgerEntry.SetRange("Item No.", Item."No.");
        ItemledgerEntry.SetCurrentKey("Posting Date", "Entry No.");
        if ItemledgerEntry.FindSet() then
            repeat
                TotalQuantity += ItemledgerEntry.Quantity;
                Assert.AreEqual(TotalQuantity, CalcRunningInvBalance.GetItemBalance(ItemledgerEntry), 'Inventory out of balance');
                if ItemledgerEntry."Location Code" = Location.Code then begin
                    TotalQuantityLoc += ItemledgerEntry.Quantity;
                    Assert.AreEqual(TotalQuantityLoc, CalcRunningInvBalance.GetItemBalanceLoc(ItemledgerEntry), 'InventoryLoc nonblank out of balance');
                end else begin
                    TotalQuantityNoLoc += ItemledgerEntry.Quantity;
                    Assert.AreEqual(TotalQuantityNoLoc, CalcRunningInvBalance.GetItemBalanceLoc(ItemledgerEntry), 'InventoryLoc blank out of balance');
                end;
            until ItemledgerEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CatalogItemListModalPageHandlerForEntryNo')]
    procedure CatalogItemConvertedNonInventoryTypeIntoSalesQuote()
    var
        ItemTemplate: Record "Item Templ.";
        NonstockItem: Record "Nonstock Item";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 539059] Inventory Posting Group can be empty in Item Template when Type is Non-Inventory.
        Initialize();

        // [GIVEN] Create Item Template.
        LibraryTemplates.CreateItemTemplateWithData(ItemTemplate);

        // [GIVEN] Validate Type into Non-Inventory.
        ItemTemplate.Validate(Type, ItemTemplate.Type::"Non-Inventory");
        ItemTemplate.Modify(true);

        // [GIVEN] Create Non Stock Item from Item Template.
        LibraryInventory.CreateNonStockItemWithItemTemplateCode(NonstockItem, ItemTemplate.Code);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Sales Quote.
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, Customer."No.");

        // [GIVEN] Create Sales Line and Validate Type into Item.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine."Document Type"::Quote, '', 0);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Modify(true);

        // [GIVEN] Store Non Stock Item Entry No. to select Non Stock Item.
        LibraryVariableStorage.Enqueue(NonstockItem."Entry No.");

        // [THEN] Run and Select Show Non Stock Item to ensure no error.
        SalesLine.ShowNonstock();
    end;

    [Test]
    procedure ModifyingItemUnitOfMeasureResetsUoMMgtCodeunit()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 2);

        Assert.AreEqual(2, UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, ItemUnitOfMeasure.Code), '');

        ItemUnitOfMeasure."Qty. per Unit of Measure" := 4;
        ItemUnitOfMeasure.Modify();

        Assert.AreEqual(4, UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, ItemUnitOfMeasure.Code), '');
    end;

    [Test]
    procedure ModifyingResourceUnitOfMeasureResetsUoMMgtCodeunit()
    var
        UnitOfMeasure: Record "Unit of Measure";
        Resource: Record Resource;
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        Initialize();

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, Resource."No.", UnitOfMeasure.Code, 2);

        Assert.AreEqual(2, UnitOfMeasureManagement.GetResQtyPerUnitOfMeasure(Resource, ResourceUnitOfMeasure.Code), '');

        ResourceUnitOfMeasure."Qty. per Unit of Measure" := 4;
        ResourceUnitOfMeasure.Modify();

        Assert.AreEqual(4, UnitOfMeasureManagement.GetResQtyPerUnitOfMeasure(Resource, ResourceUnitOfMeasure.Code), '');
    end;

    [Test]
    procedure CheckExternalDocNoInValueEntry()
    var
        ItemPurchaseLine: Record "Purchase Line";
        GLPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 567739] Check the External Document No. in the Value Entry Table.
        Initialize();

        // [GIVEN] Create Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // [GIVEN] Create First Purchase Line.
        LibraryPurchase.CreatePurchaseLine(
            ItemPurchaseLine, PurchaseHeader, ItemPurchaseLine.Type::Item, '', LibraryRandom.RandInt(10));
        ItemPurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(200, 300));
        ItemPurchaseLine.Modify(true);

        // [GIVEN] Create Second Purchase Line.
        LibraryPurchase.CreatePurchaseLine(
            GLPurchaseLine, PurchaseHeader, GLPurchaseLine.Type::"G/L Account", '', LibraryRandom.RandInt(10));
        GLPurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(200, 300));
        GLPurchaseLine.Modify(true);
        UpdateDocAmtInPurchaseOrder(PurchaseHeader);

        // [WHEN] Post Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify that the External Document is not blank in the Value Entry table.
        VerifyExtDocNoInValueEntry(DocumentNo, PurchaseHeader."Vendor Invoice No.");
    end;

    [Test]
    procedure CheckItemStatistics_InventoryValues()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemStatistics2: TestPage "Item Statistics 2";
        QtyInventory, QtyExpiredInventory : Decimal;
        ItemCost: Decimal;
        ItemPrice: Decimal;
        SalesQty: Decimal;
        ExpectedCurrentValue: Decimal;
        ExpectedExpiredValue: Decimal;
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Check 'Current Inventory Value' and 'Expired Stock Value' on Item Statistics page
        // [FEATURE] [Item Statistics]
        Initialize();

        // [GIVEN] Create Item with Cost and Price.
        ItemCost := LibraryRandom.RandIntInRange(200, 300);
        ItemPrice := ItemCost + LibraryRandom.RandIntInRange(200, 300);
        CreateItemWithCostAndPrice(Item, ItemCost, ItemPrice);

        QtyInventory := LibraryRandom.RandIntInRange(100, 200);
        QtyExpiredInventory := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Create inventory
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", QtyInventory, ItemCost);

        // [GIVEN] Add expired inventory
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", QtyExpiredInventory, ItemCost);
        DocumentNo := PurchaseHeader."Last Receiving No.";

        // Find the Item Ledger Entry for the expired inventory and set the Expiration Date to today.
        FindItemLedgEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Receipt", DocumentNo);
        ItemLedgerEntry.Validate("Expiration Date", CalcDate('<-1D>', WorkDate()));
        ItemLedgerEntry.Modify(true);

        // [GIVEN] Create Sales.
        SalesQty := LibraryRandom.RandInt(10);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", SalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [WHEN] Open Item Statistics page for the item.
        ItemStatistics2.OpenView();
        ItemStatistics2.Filter.SetFilter("No.", Item."No.");

        // Expired Inventory Value = Expired Inventory * Item Cost
        ExpectedExpiredValue := QtyExpiredInventory * ItemCost;

        // Current Value = Total available Inventory  * Item Cost
        ExpectedCurrentValue := (QtyInventory - SalesQty) * ItemCost + ExpectedExpiredValue;

        // [THEN] Verify the current inventory value.
        ItemStatistics2."Current Inventory Value".AssertEquals(ExpectedCurrentValue);

        // [THEN] Verify the expired inventory value.
        ItemStatistics2."Expired Stock Value".AssertEquals(ExpectedExpiredValue);

        ItemStatistics2.Close();
    end;

    [Test]
    procedure CheckItemStatistics_NetSales()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemStatistics2: TestPage "Item Statistics 2";
        NewWorkDate: Date;
        QtyInventory: Decimal;
        ItemCost: Decimal;
        ItemPrice: Decimal;
        LastYearSalesQty, LastMonthSalesQty, ThisMonthSalesQty : Decimal;
        ExpectedNetSalesAmtLastMonth, ExpectedNetSalesAmtThisMonth, ExpectedNetSalesAmtLastYear, ExpectedNetSalesAmtThisYear, ExpectedNetSalesAmt : Decimal;
    begin
        // [SCENARIO] Check Net Sales Amount on Item Statistics page
        // [FEATURE] [Item Statistics]
        Initialize();

        // [GIVEN] Move the Work Date back 3 years and add an item with inventory.
        NewWorkDate := CalcDate('<-3Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        // [GIVEN] Create Item with Cost and Price.
        ItemCost := LibraryRandom.RandIntInRange(200, 300);
        ItemPrice := ItemCost + LibraryRandom.RandIntInRange(200, 300);
        CreateItemWithCostAndPrice(Item, ItemCost, ItemPrice);

        QtyInventory := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create inventory
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", QtyInventory, ItemCost);

        // [GIVEN] Move the Work Date to last year, create and post sales orders.
        NewWorkDate := CalcDate('<-1Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastYearSalesQty := LibraryRandom.RandInt(10);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastYearSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to last month, create and post sales orders.
        NewWorkDate := CalcDate('<-1M>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastMonthSalesQty := LibraryRandom.RandInt(10);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastMonthSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to current date, create and post sales orders.
        WorkDate(CurrentWorkDate);
        ThisMonthSalesQty := LibraryRandom.RandInt(10);

        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", ThisMonthSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [WHEN] Open Item Statistics page for the item.
        ItemStatistics2.OpenView();
        ItemStatistics2.Filter.SetFilter("No.", Item."No.");

        // Net Sales Amount last month = Total qty. sold last month * Item Price
        ExpectedNetSalesAmtLastMonth := LastMonthSalesQty * ItemPrice;

        // Net Sales Amount This month = Total qty. sold this month * Item Price
        ExpectedNetSalesAmtThisMonth := ThisMonthSalesQty * ItemPrice;

        // Net Sales Amount last Year = Total qty. sold last year * Item Price
        ExpectedNetSalesAmtLastYear := LastYearSalesQty * ItemPrice;

        // Net Sales Amount This Year = Total qty. sold this year * Item Price 
        // If WorkDate is in January, Last month sales belongs to last year's calculation.
        if Date2DMY(CurrentWorkDate, 2) <> 1 then
            ExpectedNetSalesAmtThisYear := ExpectedNetSalesAmtLastMonth + ExpectedNetSalesAmtThisMonth
        else begin
            // Net Sales Amount This Year = Total qty. sold this year * Item Price
            ExpectedNetSalesAmtThisYear := ExpectedNetSalesAmtThisMonth;

            // Net Sales Amount last Year = Total qty. sold last year * Item Price
            ExpectedNetSalesAmtLastYear += ExpectedNetSalesAmtLastMonth;
        end;

        // Net Sales Amount lifetime = Total qty. sold * Item Price
        ExpectedNetSalesAmt := ExpectedNetSalesAmtThisYear + ExpectedNetSalesAmtLastYear;

        // [THEN] Verify the net sales amount for this month.
        ItemStatistics2."NetSalesLCY[1]".AssertEquals(ExpectedNetSalesAmtThisMonth);

        // [THEN] Verify the net sales amount for this year.
        ItemStatistics2."NetSalesLCY[2]".AssertEquals(ExpectedNetSalesAmtThisYear);

        // [THEN] Verify the net sales amount for last year.
        ItemStatistics2."NetSalesLCY[3]".AssertEquals(ExpectedNetSalesAmtLastYear);

        // [THEN] Verify the net sales amount for lifetime.
        ItemStatistics2."NetSalesLCY[4]".AssertEquals(ExpectedNetSalesAmt);

        ItemStatistics2.Close();
    end;

    [Test]
    procedure CheckItemStatistics_SalesGrowth()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemStatistics2: TestPage "Item Statistics 2";
        NewWorkDate: Date;
        QtyInventory: Decimal;
        ItemCost: Decimal;
        ItemPrice: Decimal;
        LastLastYearSalesQty, LastYearSalesQty, LastMonthSalesQty, ThisMonthSalesQty : Decimal;
        NetSalesAmtLastMonth, NetSalesAmtThisMonth, NetSalesAmtLastYear, NetSalesAmtLastLastYear, NetSalesAmtThisYear : Decimal;
        ExpectedSalesGrowthThisMonth, ExpectedSalesGrowthThisYear, ExpectedSalesGrowthLastYear : Decimal;
    begin
        // [SCENARIO] Check Sales Growth Rate on Item Statistics page
        // [FEATURE] [Item Statistics]
        Initialize();
        CreateAccountingPeriod();

        // [GIVEN] Move the Work Date back 3 years and add an item with inventory.
        NewWorkDate := CalcDate('<-3Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        // [GIVEN] Create Item with Cost and Price.
        ItemCost := LibraryRandom.RandIntInRange(200, 300);
        ItemPrice := ItemCost + LibraryRandom.RandIntInRange(200, 300);
        CreateItemWithCostAndPrice(Item, ItemCost, ItemPrice);

        QtyInventory := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create inventory
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", QtyInventory, ItemCost);

        // [GIVEN] Move the Work Date to 2 years back, create and post sales orders that contribute to MoM sales growth.
        NewWorkDate := CalcDate('<-2Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastLastYearSalesQty := LibraryRandom.RandInt(10);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastLastYearSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to last year, create and post sales orders that contribute to MoM sales growth.
        NewWorkDate := CalcDate('<-1Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastYearSalesQty := LibraryRandom.RandInt(10);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastYearSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to last month, create and post sales orders that contribute to MoM sales growth.
        NewWorkDate := CalcDate('<-1M>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastMonthSalesQty := LibraryRandom.RandInt(10);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastMonthSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to current date, create and post sales orders that contribute to MoM sales growth.
        WorkDate(CurrentWorkDate);
        ThisMonthSalesQty := LibraryRandom.RandInt(10);

        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", ThisMonthSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [WHEN] Open Item Statistics page for the item.
        ItemStatistics2.OpenView();
        ItemStatistics2.Filter.SetFilter("No.", Item."No.");

        NetSalesAmtLastMonth := LastMonthSalesQty * ItemPrice;
        NetSalesAmtThisMonth := ThisMonthSalesQty * ItemPrice;

        // Net Sales Amount This Year = Total qty. sold this year * Item Price
        // If WorkDate is in January, Last month sales belongs to last year's calculation.
        if Date2DMY(CurrentWorkDate, 2) <> 1 then begin
            NetSalesAmtThisYear := NetSalesAmtLastMonth + NetSalesAmtThisMonth;
            NetSalesAmtLastYear := LastYearSalesQty * ItemPrice;
        end else begin
            NetSalesAmtThisYear := NetSalesAmtThisMonth;
            NetSalesAmtLastYear := (LastYearSalesQty + LastMonthSalesQty) * ItemPrice;
        end;

        NetSalesAmtLastLastYear := LastLastYearSalesQty * ItemPrice;

        ExpectedSalesGrowthThisMonth := ((NetSalesAmtThisMonth - NetSalesAmtLastMonth) / NetSalesAmtLastMonth);
        ExpectedSalesGrowthThisYear := ((NetSalesAmtThisYear - NetSalesAmtLastYear) / NetSalesAmtLastYear);
        ExpectedSalesGrowthLastYear := ((NetSalesAmtLastYear - NetSalesAmtLastLastYear) / NetSalesAmtLastLastYear);

        // [THEN] Verify the current inventory value.
        ItemStatistics2."SalesGrowthRate[1]".AssertEquals(ExpectedSalesGrowthThisMonth);

        // [THEN] Verify the expired inventory value.
        ItemStatistics2."SalesGrowthRate[2]".AssertEquals(ExpectedSalesGrowthThisYear);

        // [THEN] Verify the net sales amount for this month.
        ItemStatistics2."SalesGrowthRate[3]".AssertEquals(ExpectedSalesGrowthLastYear);

        ItemStatistics2.Close();
    end;

    [Test]
    procedure CheckItemStatistics_GrossMargin()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemStatistics2: TestPage "Item Statistics 2";
        NewWorkDate: Date;
        QtyInventory: Decimal;
        ItemCost: Decimal;
        ItemPrice: Decimal;
        LastLastYearSalesQty, LastYearSalesQty, LastMonthSalesQty, ThisMonthSalesQty : Decimal;
        NetSalesAmtLastMonth, NetSalesAmtThisMonth, NetSalesAmtLastYear, NetSalesAmtLastLastYear, NetSalesAmtThisYear : Decimal;
        NetCostAmtLastMonth, NetCostAmtThisMonth, NetCostAmtLastYear, NetCostAmtLastLastYear, NetCostAmtThisYear : Decimal;
        ExpectedGrossMarginThisMonth, ExpectedGrossMarginThisYear, ExpectedGrossMarginLastYear, ExpectedGrossMarginLifetime : Decimal;
    begin
        // [SCENARIO] Check Gross Margin on Item Statistics page
        // [FEATURE] [Item Statistics]
        Initialize();
        CreateAccountingPeriod();

        // [GIVEN] Move the Work Date back 3 years and add an item with inventory.
        NewWorkDate := CalcDate('<-3Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        // [GIVEN] Create Item with Cost and Price.
        ItemCost := LibraryRandom.RandIntInRange(200, 300);
        ItemPrice := ItemCost + LibraryRandom.RandIntInRange(200, 300);
        CreateItemWithCostAndPrice(Item, ItemCost, ItemPrice);

        QtyInventory := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create inventory
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", QtyInventory, ItemCost);

        // [GIVEN] Move the Work Date to 2 years back, create and post sales orders that contribute to MoM sales growth.
        NewWorkDate := CalcDate('<-2Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastLastYearSalesQty := LibraryRandom.RandInt(10);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastLastYearSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to last year, create and post sales orders that contribute to MoM sales growth.
        NewWorkDate := CalcDate('<-1Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastYearSalesQty := LibraryRandom.RandInt(10);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastYearSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to last month, create and post sales orders that contribute to MoM sales growth.
        NewWorkDate := CalcDate('<-1M>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastMonthSalesQty := LibraryRandom.RandInt(10);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastMonthSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to current date, create and post sales orders that contribute to MoM sales growth.
        WorkDate(CurrentWorkDate);
        ThisMonthSalesQty := LibraryRandom.RandInt(10);

        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", ThisMonthSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [WHEN] Open Item Statistics page for the item.
        ItemStatistics2.OpenView();
        ItemStatistics2.Filter.SetFilter("No.", Item."No.");

        NetSalesAmtLastMonth := LastMonthSalesQty * ItemPrice;
        NetSalesAmtThisMonth := ThisMonthSalesQty * ItemPrice;
        NetCostAmtLastMonth := LastMonthSalesQty * ItemCost;
        NetCostAmtThisMonth := ThisMonthSalesQty * ItemCost;

        // Net Sales Amount This Year = Total qty. sold this year * Item Price
        // Net Cost Amount This Year = Total qty. sold this year * Item Cost
        // If WorkDate is in January, Last month sales belongs to last year's calculation.
        if Date2DMY(CurrentWorkDate, 2) <> 1 then begin
            NetSalesAmtThisYear := NetSalesAmtLastMonth + NetSalesAmtThisMonth;
            NetSalesAmtLastYear := LastYearSalesQty * ItemPrice;
            NetCostAmtThisYear := NetCostAmtLastMonth + NetCostAmtThisMonth;
            NetCostAmtLastYear := LastYearSalesQty * ItemCost;
        end else begin
            NetSalesAmtThisYear := NetSalesAmtThisMonth;
            NetSalesAmtLastYear := (LastYearSalesQty + LastMonthSalesQty) * ItemPrice;
            NetCostAmtThisYear := NetCostAmtThisMonth;
            NetCostAmtLastYear := (LastYearSalesQty + LastMonthSalesQty) * ItemCost;
        end;

        NetSalesAmtLastLastYear := LastLastYearSalesQty * ItemPrice;
        NetCostAmtLastLastYear := LastLastYearSalesQty * ItemCost;

        ExpectedGrossMarginThisMonth := ((NetSalesAmtThisMonth - NetCostAmtThisMonth) / NetSalesAmtThisMonth);
        ExpectedGrossMarginThisYear := (NetSalesAmtThisYear - NetCostAmtThisYear) / NetSalesAmtThisYear;
        ExpectedGrossMarginLastYear := (NetSalesAmtLastYear - NetCostAmtLastYear) / NetSalesAmtLastYear;
        ExpectedGrossMarginLifetime := (NetSalesAmtThisYear + NetSalesAmtLastYear + NetSalesAmtLastLastYear - NetCostAmtThisYear - NetCostAmtLastYear - NetCostAmtLastLastYear)
                                      / (NetSalesAmtThisYear + NetSalesAmtLastYear + NetSalesAmtLastLastYear);

        // [THEN] Verify the current inventory value.
        ItemStatistics2."GrossMargin[1]".AssertEquals(ExpectedGrossMarginThisMonth);

        // [THEN] Verify the expired inventory value.
        ItemStatistics2."GrossMargin[2]".AssertEquals(ExpectedGrossMarginThisYear);

        // [THEN] Verify the net sales amount for this month.
        ItemStatistics2."GrossMargin[3]".AssertEquals(ExpectedGrossMarginLastYear);

        // [THEN] Verify the net sales amount for lifetime.
        ItemStatistics2."GrossMargin[4]".AssertEquals(ExpectedGrossMarginLifetime);

        ItemStatistics2.Close();
    end;

    [Test]
    procedure CheckItemStatistics_ReturnRate()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemStatistics2: TestPage "Item Statistics 2";
        NewWorkDate: Date;
        QtyInventory: Decimal;
        ItemCost: Decimal;
        ItemPrice: Decimal;
        LastYearSalesQty, LastMonthSalesQty, ThisMonthSalesQty : Decimal;
        LastYearReturnQty, LastMonthReturnQty, ThisMonthReturnQty : Decimal;
        ExpectedReturnRateThisMonth, ExpectedReturnRateThisYear, ExpectedReturnRateLastYear, ExpectedReturnRateLifetime : Decimal;
    begin
        // [SCENARIO] Check Return Rate on Item Statistics page
        // [FEATURE] [Item Statistics]
        Initialize();
        CreateAccountingPeriod();

        // [GIVEN] Move the Work Date back 3 years and add an item with inventory.
        NewWorkDate := CalcDate('<-3Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        // [GIVEN] Create Item with Cost and Price.
        ItemCost := LibraryRandom.RandIntInRange(200, 300);
        ItemPrice := ItemCost + LibraryRandom.RandIntInRange(200, 300);
        CreateItemWithCostAndPrice(Item, ItemCost, ItemPrice);

        QtyInventory := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create inventory
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", QtyInventory, ItemCost);

        // [GIVEN] Move the Work Date to last year, create and post sales orders that contribute to MoM sales growth.
        NewWorkDate := CalcDate('<-1Y>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastYearSalesQty := LibraryRandom.RandInt(10);
        LastYearReturnQty := LibraryRandom.RandInt(LastYearSalesQty);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastYearSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // Return
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastYearReturnQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to last month, create and post sales orders that contribute to MoM sales growth.
        NewWorkDate := CalcDate('<-1M>', CurrentWorkDate);
        WorkDate(NewWorkDate);

        LastMonthSalesQty := LibraryRandom.RandInt(10);
        LastMonthReturnQty := LibraryRandom.RandInt(LastMonthSalesQty);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastMonthSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // Return
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", LastMonthReturnQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [GIVEN] Move the Work Date to current date, create and post sales orders that contribute to MoM sales growth.
        WorkDate(CurrentWorkDate);
        ThisMonthSalesQty := LibraryRandom.RandInt(10);
        ThisMonthReturnQty := LibraryRandom.RandInt(ThisMonthSalesQty); // Return qty should be less than or equal to sales qty

        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", ThisMonthSalesQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // Return
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, Item."No.", ThisMonthReturnQty);

        PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.", true);

        // [WHEN] Open Item Statistics page for the item.
        ItemStatistics2.OpenView();
        ItemStatistics2.Filter.SetFilter("No.", Item."No.");

        ExpectedReturnRateThisMonth := ThisMonthReturnQty / ThisMonthSalesQty;

        // Return Rate This Year = This year return qty / This year sales qty
        // If WorkDate is in January, Last month return belongs to last year's calculation.
        if Date2DMY(CurrentWorkDate, 2) <> 1 then begin
            ExpectedReturnRateThisYear := (ThisMonthReturnQty + LastMonthReturnQty) / (ThisMonthSalesQty + LastMonthSalesQty);
            ExpectedReturnRateLastYear := LastYearReturnQty / LastYearSalesQty;
        end else begin
            ExpectedReturnRateThisYear := ThisMonthReturnQty / ThisMonthSalesQty;
            ExpectedReturnRateLastYear := (LastYearReturnQty + LastMonthReturnQty) / (LastYearSalesQty + LastMonthSalesQty);
        end;
        ExpectedReturnRateLifetime := (ThisMonthReturnQty + LastMonthReturnQty + LastYearReturnQty) / (ThisMonthSalesQty + LastMonthSalesQty + LastYearSalesQty);

        // [THEN] Verify the return rate for this month.
        ItemStatistics2."ReturnRate[1]".AssertEquals(ExpectedReturnRateThisMonth);

        // [THEN] Verify the return rate for this year.
        ItemStatistics2."ReturnRate[2]".AssertEquals(ExpectedReturnRateThisYear);

        // [THEN] Verify the return rate for last year.
        ItemStatistics2."ReturnRate[3]".AssertEquals(ExpectedReturnRateLastYear);

        // [THEN] Verify the return rate for lifetime.
        ItemStatistics2."ReturnRate[4]".AssertEquals(ExpectedReturnRateLifetime);

        ItemStatistics2.Close();
    end;

    local procedure Initialize()
    var
        NonstockItemSetup: Record "Nonstock Item Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Basic");
        ClearGlobals();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if CurrentWorkDate <> 0D then
            WorkDate(CurrentWorkDate);

        // Lazy Setup.
        if isInitialized then
            exit;

        CurrentWorkDate := WorkDate();
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Basic");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryTemplates.EnableTemplatesFeature();
        LibrarySales.SetOrderNoSeriesInSetup();
        LibrarySales.SetReturnOrderNoSeriesInSetup();
        LibrarySales.SetPostedNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetPostedNoSeriesInSetup();
        NonstockItemSetup.DeleteAll();
        NonstockItemSetup.Init();
        NonstockItemSetup.Insert();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Nonstock Item Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Basic");
    end;

    local procedure ClearGlobals()
    begin
        // Clear Global variables.
        GlobalItemNo := '';
        GlobalLotNo := '';
        GlobalSerialNo := '';
        GlobalDocumentNo := '';
        GlobalQuantity := 0;
        GlobalAmount := 0;
        GlobalApplToItemEntry := 0;
        GlobalQtyToAssign := 0;
        Clear(GlobalLineOption);
        Clear(GlobalItemChargeAssignment);
        Clear(GlobalItemTracking);
    end;

    local procedure CreateAccountingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
        NewWorkDate: array[3] of Date;
        NewWorkDateIndex: Integer;
    begin
        NewWorkDate[1] := CalcDate('<-1Y>', WorkDate());
        NewWorkDate[2] := CalcDate('<-2Y>', WorkDate());
        NewWorkDate[3] := CalcDate('<-3Y>', WorkDate());

        for NewWorkDateIndex := 1 to 3 do
            if AccountingPeriod.GetFiscalYearStartDate(NewWorkDate[NewWorkDateIndex]) = 0D then begin
                AccountingPeriod.Init();
                AccountingPeriod."Starting Date" := CalcDate('<-CY>', NewWorkDate[NewWorkDateIndex]);
                AccountingPeriod."New Fiscal Year" := true;
                AccountingPeriod.Insert();
            end;
    end;

    local procedure FindItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; DocType: Enum "Item Ledger Document Type";
                                                                                                                        DocNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Document Type", DocType);
        ItemLedgerEntry.SetRange("Document No.", DocNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure CreateAndModifyItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, JournalTemplateName, JournalBatchName, EntryType, ItemNo, Quantity);
        ModifyItemJnlLine(ItemJournalLine, '', LibraryRandom.RandInt(10));  // Taking Random value for Unit Amount.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndModifyTransferRoute(var TransferRoute: Record "Transfer Route")
    var
        Location: Record Location;
        InTransitLocation: Record Location;
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');  // Use Random value for Shipping Time.
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        LibraryWarehouse.CreateAndUpdateTransferRoute(
          TransferRoute, Location.Code, GetFirstLocation(false), InTransitLocation.Code, ShippingAgent.Code, ShippingAgentServices.Code);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ModifyItemJnlLine(ItemJournalLine, LocationCode, LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Amount.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndModifyTrackedItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false));
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 1));  // Using Random value for Unit Price.
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithCostAndPrice(var Item: Record Item; ItemCost: Decimal; ItemPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Standard Cost", ItemCost);
        Item.Validate("Unit Price", ItemPrice);
        Item.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; ItemCost: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        // Add inventory
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", ItemCost);

        PurchaseLine.Modify(true);

        UpdateDocAmtInPurchaseOrder(PurchaseHeader);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateItemWithSubstitution(var ItemSubstitution: Record "Item Substitution")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateItemSubstitution(ItemSubstitution, Item."No.");
    end;

    local procedure CreateItemAndProductionBOM(var Item: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    begin
        ProductionBOMHeader."No." := LibraryUtility.GenerateGUID();
        ProductionBOMHeader.Insert();

        Item."No." := LibraryUtility.GenerateGUID();
        Item."Production BOM No." := ProductionBOMHeader."No.";
        Item.Insert();
    end;

    local procedure CreateAndPostItemJnlLineWithtemTracking(): Code[20]
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        CreateItemJnlLineWithTrackedItem(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, CreateAndModifyTrackedItem());
        CreateItemJnlLineWithTrackedItem(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Item No.");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        exit(ItemJournalLine."Item No.");
    end;

    local procedure CreateItemJnlLineWithTrackedItem(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, JournalTemplateName, JournalBatchName, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo,
          LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        ModifyItemJnlLine(ItemJournalLine, '', LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Amount.
        GlobalItemTracking := GlobalItemTracking::AssignLotNo;
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure CreateItemTrackingCode(LotSpecific: Boolean; SerialSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SerialSpecific, LotSpecific);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateNonStockItem(var NonstockItem: Record "Nonstock Item")
    var
        Vendor: Record Vendor;
        UnitOfMeasure: Record "Unit of Measure";
        CatalogItemManagement: Codeunit "Catalog Item Management";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateNonStock(NonstockItem);
        NonstockItem.Validate("Vendor No.", Vendor."No.");
        NonstockItem.Validate(
          "Vendor Item No.", LibraryUtility.GenerateRandomCode(NonstockItem.FieldNo("Vendor Item No."), DATABASE::"Nonstock Item"));
        NonstockItem.Validate("Item Templ. Code", SelectItemTemplateCode());
        NonstockItem.Validate("Unit of Measure", UnitOfMeasure.Code);
        NonstockItem.Modify(true);
        UpdateItemTemplate(NonstockItem."Item Templ. Code");
        CatalogItemManagement.NonstockAutoItem(NonstockItem);
        NonstockItem.Get(NonstockItem."Entry No.");
    end;

    local procedure CreateCustomerWithDefaultDimension(var Customer: Record Customer; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithAmount(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Direct Unit Cost", 10);
        PurchaseLine.Validate("Line Amount", -9);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; SellToCustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SellToCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity)
    end;

    local procedure CreateSalesOrderAndAssignItemCharge(var SalesLine2: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeNo: Code[20];
    begin
        // Setup.
        Initialize();

        // Create Sales Order for Charge Item Line.
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        CreateSalesDocument(
          SalesLine2, SalesLine2."Document Type"::Order, CreateCustomer(), SalesLine.Type::"Charge (Item)",
          ItemChargeNo, 1);
        UpdateSalesLineUnitPrice(SalesLine2, LibraryRandom.RandDec(100, 1));  // Using Random value for Unit Price.

        // Create Sales Lines for Item.
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine2."Document No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.

        GlobalItemChargeAssignment := GlobalItemChargeAssignment::AssignmentOnly;
        GlobalQtyToAssign := 0.5;  // Taken Qty. to Assign as 0.5 to assign equal value on both Item Lines.
        SalesLine2.ShowItemChargeAssgnt();
        SalesLine.Validate("Qty. to Ship", 0);  // Set Quantity to Ship 0 for Item Line.
        SalesLine.Modify(true);
        exit(ItemChargeNo);
    end;

    local procedure CreateSalesOrderAndAssignNegativeQtyItemCharge(var SalesLine2: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeNo: Code[20];
    begin
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        CreateSalesDocument(
          SalesLine2, SalesLine2."Document Type"::Order, CreateCustomer(), SalesLine.Type::"Charge (Item)",
          ItemChargeNo, -1);
        UpdateSalesLineUnitPrice(SalesLine2, LibraryRandom.RandDec(100, 1));

        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine2."Document No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.

        GlobalItemChargeAssignment := GlobalItemChargeAssignment::AssignmentOnly;
        SalesLine2.ShowItemChargeAssgnt();
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
        exit(ItemChargeNo);
    end;

    local procedure CreatePurchaseDocumentAndAssignItemCharge(var PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);

        // Create Purchase Order for Item.
        CreatePurchaseDocument(PurchaseLine, DocumentType, CreateVendor(), PurchaseLine.Type::Item, CreateItem(),
            LibraryRandom.RandDec(100, 2)); // Using Random value for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Create 2nd Purchase Line for Charge Item, assign Item Charge.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        PurchaseLine2.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 1));
        PurchaseLine2.Modify(true);
        LibraryVariableStorage.Enqueue(PurchaseLine2.Quantity);
        PurchaseLine2.ShowItemChargeAssgnt();
    end;

    local procedure CreatePurchaseOrderAndAssignNegativeQtyItemCharge(var PurchaseLine2: Record "Purchase Line"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeNo: Code[20];
    begin
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        CreatePurchaseDocumentWithAmount(
          PurchaseLine2, PurchaseLine2."Document Type"::Order, LibraryPurchase.CreateVendorNo(), PurchaseLine.Type::"Charge (Item)",
          ItemChargeNo, -1);
        UpdatePurchaseLineUnitPrice(PurchaseLine2, LibraryRandom.RandDec(100, 1));  // Using Random value for Unit Price.

        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine2."Document No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.

        GlobalItemChargeAssignment := GlobalItemChargeAssignment::AssignmentOnly;
        PurchaseLine2.ShowItemChargeAssgnt();
        PurchaseLine2.Modify();
        PurchaseLine.Validate("Qty. to Receive", 0);  // Set Quantity to Receive 0 for Item Line.
        PurchaseLine.Modify(true);
        exit(ItemChargeNo);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        Location: Record Location;
        Location2: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateInTransitLocation(Location2);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationCode, Location.Code, Location2.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateUoM_and_ItemUoM(var UnitOfMeasure: Record "Unit of Measure"; var ItemUnitOfMeasure: Record "Item Unit of Measure"; Item: Record Item)
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
    end;

    local procedure CreateNewUnitOfMeasureCode(): Code[10]
    var
        RefUnitOfMeasure: Record "Unit of Measure";
    begin
        exit(LibraryUtility.GenerateRandomCode(RefUnitOfMeasure.FieldNo(Code), DATABASE::"Unit of Measure"));
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(PurchaseLine, DocumentType, Vendor."No.", PurchaseLine.Type::Item, ItemNo, Quantity);
        PostPurchaseOrder(PurchaseLine."Document Type", PurchaseLine."Document No.", true);
    end;

    local procedure CreateItemChargeAndAssignToReturnShipment(var PurchaseLine2: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        ItemCharge: Record "Item Charge";
        ReturnShipmentLine: Record "Return Shipment Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine."Document No.", PurchaseLine."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePurchaseDocument(
          PurchaseLine2, DocumentType, PurchaseLine."Buy-from Vendor No.", PurchaseLine2.Type::"Charge (Item)",
          ItemCharge."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine2.Validate("Direct Unit Cost", LibraryRandom.RandDec(20, 2));
        PurchaseLine2.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine2, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Shipment",
          ReturnShipmentLine."Document No.", ReturnShipmentLine."Line No.", ReturnShipmentLine."No.");
    end;

    local procedure DeleteSalesLine(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindLast();
        SalesLine.Delete(true);
    end;

    local procedure FindItemLedgerEntry(DocumentNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure FindReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ReturnOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentLine.SetRange("No.", ItemNo);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure GetFirstLocation(UseAsInTransit: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        // Make sure this location will be the first to be retrieved in a matrix page, alphabetically.
        if not Location.Get('A') then begin
            Location.Init();
            Location.Validate(Code, 'A');
            Location.Validate(Name, 'A');
            Location.Insert(true);
            LibraryInventory.UpdateInventoryPostingSetup(Location);
        end;

        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Modify(true);

        exit(Location.Code);
    end;

    local procedure ModifyItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; UnitAmount: Decimal)
    var
        Location: Record Location;
        Bin: Record Bin;
    begin
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if Location.Get(LocationCode) then
            if Location."Bin Mandatory" then begin
                Bin.SetRange("Location Code", LocationCode);
                Bin.FindFirst();
                ItemJournalLine.Validate("Bin Code", Bin.Code);
            end;
        ItemJournalLine.Modify(true);
    end;

    local procedure OpenItemStatisticsPage(No: Code[20])
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.FILTER.SetFilter("No.", No);
        ItemCard.Statistics.Invoke();
    end;

    local procedure VerifyTransferRoutesMatrixCellValue(Show: Option; LocationCode: Code[10]; MatrixCellValue: Code[10])
    var
        TransferRoutes: TestPage "Transfer Routes";
    begin
        TransferRoutes.OpenView();
        TransferRoutes.Show.SetValue(Show);
        TransferRoutes.MatrixForm.FILTER.SetFilter(Code, LocationCode);
        TransferRoutes.MatrixForm.Field1.AssertEquals(MatrixCellValue);
    end;

    local procedure PostPurchaseOrder(DocumentType: Enum "Purchase Document Type"; No: Code[20]; Invoice: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, No);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));
    end;

    local procedure PostSalesOrder(DocumentType: Enum "Purchase Document Type"; No: Code[20]; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, No);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    local procedure CreateAndPostPurchOrderLine(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100), '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesOrderLine(var SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
    begin
        CreateAndPostPurchOrderLine(PurchaseLine);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          PurchaseLine."No.", LibraryRandom.RandInt(PurchaseLine.Quantity), '', WorkDate());
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(20, 40, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure InvokeItemTurnoverFromItemCard(var ItemTurnover: TestPage "Item Turnover"; ItemNo: Code[20])
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemTurnover.Trap();
        ItemCard.OpenView();
        ItemCard.FILTER.SetFilter("No.", ItemNo);
        ItemCard."T&urnover".Invoke();
        Assert.AreEqual('Day', ItemTurnover.PeriodType.Value, 'View by Day');
    end;

    local procedure SelectItemTemplateCode(): Code[20]
    var
        ItemTemplate: Record "Item Templ.";
    begin
        LibraryTemplates.CreateItemTemplateWithData(ItemTemplate);
        exit(ItemTemplate.Code);
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure UpdateItemTemplate(ItemTemplateCode: Code[20])
    var
        ItemTemplate: Record "Item Templ.";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        ItemTemplate.SetRange(Code, ItemTemplateCode);
        ItemTemplate.FindFirst();
        ItemTemplate.Validate("Costing Method", ItemTemplate."Costing Method"::Specific);
        if ItemTemplate."VAT Prod. Posting Group" = '' then begin
            VATProductPostingGroup.FindFirst();
            ItemTemplate.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);  // Updating Default VAT Prod. Posting Group to fix failure in CA.
        end;
        ItemTemplate.Modify(true);
    end;

    [Normal]
    local procedure UpdateVatProdCodeInItemTemplate(ItemTemplateCode: Code[20])
    var
        ItemTemplate: Record "Item Templ.";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        ItemTemplate.SetRange(Code, ItemTemplateCode);
        ItemTemplate.FindFirst();
        VATProductPostingGroup.SetFilter(Code, '<>%1', ItemTemplate."VAT Prod. Posting Group");
        VATProductPostingGroup.FindFirst();
        ItemTemplate.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        ItemTemplate.Modify();
    end;

    local procedure UpdateSalesLineUnitPrice(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure UpdatePurchaseLineUnitPrice(var PurchaseLine: Record "Purchase Line"; UnitPrice: Decimal)
    begin
        PurchaseLine.Validate("Unit Cost", UnitPrice);
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyUnitCostOnItemAfterAdjustment(ItemNo: Code[20])
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
        TotalCost: Decimal;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            TotalQuantity += ItemLedgerEntry.Quantity;
            TotalCost += ItemLedgerEntry."Cost Amount (Actual)";
        until ItemLedgerEntry.Next() = 0;

        Item.Get(ItemNo);
        Assert.AreNearlyEqual(TotalCost / TotalQuantity, Item."Unit Cost", LibraryERM.GetAmountRoundingPrecision(), UnitCostErr);
    end;

    local procedure VerifyAdjustmentCostAmount(ValueEntry: Record "Value Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; Adjustment: Boolean; CostAmountActual: Decimal)
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", EntryType);
        ValueEntry.SetRange(Adjustment, Adjustment);
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyBaseUnitOfMeasure(Item: Record Item; BaseUnitOfMeasureCode: Code[10])
    begin
        Item.TestField("Base Unit of Measure", BaseUnitOfMeasureCode);
    end;

    local procedure VerifyNonInvtblCostsAndProfitOnItemStatistics(ItemNo: Code[20]; CostAmount: Decimal; ProfitAmount: Decimal)
    var
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
    begin
        GlobalLineOption := ItemStatisticsBuffer."Line Option"::"Profit Calculation"; // Using global variable to assing Line Option in Item Statistics Page.

        // Find the 3rd line (Non-Invtbl. Costs (LCY)) in ItemStatisticsMatrixPage, verify the total amount in ItemStatisticsMatrixPageHandlerForSpecificLine.
        VerifyAmountOnItemStatisticsLine(ItemNo, 3, CostAmount);

        // Find the 4th line (Profit (LCY)) in ItemStatisticsMatrixPage, verify the total amount in ItemStatisticsMatrixPageHandlerForSpecificLine.
        VerifyAmountOnItemStatisticsLine(ItemNo, 4, ProfitAmount);
    end;

    local procedure VerifyAmountOnItemStatisticsLine(ItemNo: Code[20]; LineNo: Integer; Amount: Decimal)
    begin
        GlobalAmount := Amount;
        LibraryVariableStorage.Enqueue(LineNo);
        OpenItemStatisticsPage(ItemNo);
    end;

    local procedure VerifyBaseUnitOfMeasureSetAndItemUnitOfMeasureInserted(Item: Record Item; ExpectedBaseUnitOfMeasure: Record "Unit of Measure"; ExpectedUnitsOfMeasureCount: Integer)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.SetFilter("Item No.", Item."No.");
        Assert.AreEqual(ExpectedUnitsOfMeasureCount, ItemUnitOfMeasure.Count, 'Wrong number of Units of measure was found on the item');
        ItemUnitOfMeasure.SetFilter(Code, ExpectedBaseUnitOfMeasure.Code);

        Assert.IsTrue(ItemUnitOfMeasure.FindFirst(), 'Cannot get Item unit of measure for specified code');
        Assert.AreEqual(1, ItemUnitOfMeasure."Qty. per Unit of Measure", 'Qty. per Unit of Measure should be set to 1');
        Assert.AreEqual(Item."Base Unit of Measure", ItemUnitOfMeasure.Code, 'Base unit of measure was not set by validate');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantitytoCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.OK().Invoke();
    end;

    local procedure InventoryPostingSetupExists(LocationCode: Code[10]; InvPostingGroupCode: Code[20]): Boolean
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.SetRange("Location Code", LocationCode);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", InvPostingGroupCode);
        if not InventoryPostingSetup.FindFirst() then
            exit(false);

        exit(InventoryPostingSetup."Inventory Account" <> '');
    end;

    local procedure UpdateDocAmtInPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseHeader."Amount Including VAT");
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyExtDocNoInValueEntry(DocumentNo: Code[20]; ExternalDocumentNo: Code[35])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("External Document No.", ExternalDocumentNo);
        until ValueEntry.Next() = 0;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByPeriodsPageHandler(var ItemAvailabilityByPeriods: TestPage "Item Availability by Periods")
    begin
        ItemAvailabilityByPeriods.ItemAvailLines.FILTER.SetFilter("Period Start", Format(WorkDate()));
        ItemAvailabilityByPeriods.ItemAvailLines.ProjAvailableBalance.AssertEquals(GlobalQuantity);
        ItemAvailabilityByPeriods.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ItemCreationMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, StrSubstNo(ItemCreatedMsg, GlobalItemNo)) = 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchGetRcptPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetReceiptLines.Invoke();
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(1);  // Added Qty. to Assign as 1 for Item Charge.
        ItemChargeAssignmentPurch.RemAmountToAssign.SetValue(0);
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        case GlobalItemChargeAssignment of
            GlobalItemChargeAssignment::AssignmentOnly:
                begin
                    ItemChargeAssignmentSales.First();
                    repeat
                        ItemChargeAssignmentSales."Qty. to Assign".SetValue(GlobalQtyToAssign);
                    until not ItemChargeAssignmentSales.Next();
                end;
            GlobalItemChargeAssignment::GetShipmentLine:
                begin
                    ItemChargeAssignmentSales.GetShipmentLines.Invoke();
                    ItemChargeAssignmentSales."Qty. to Assign".SetValue(1);  // Added Qty. to Assign as 1 for Item Charge.
                    ItemChargeAssignmentSales.RemAmountToAssign.SetValue(0);
                end;
        end;
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesOpenPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales."Qty. to Assign".AssertEquals(0);
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentNegQtySalesPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.First();
        repeat
            ItemChargeAssignmentSales."Qty. to Assign".SetValue(-0.5);
        until not ItemChargeAssignmentSales.Next();
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentNegQtyPurchPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.First();
        repeat
            ItemChargeAssignmentPurch."Qty. to Assign".SetValue(-0.5);
        until not ItemChargeAssignmentPurch.Next();
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case GlobalItemTracking of
            GlobalItemTracking::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
                    GlobalLotNo := ItemTrackingLines."Lot No.".Value();
                end;
            GlobalItemTracking::AssignSerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();  // Assign Serial No.
                    GlobalSerialNo := ItemTrackingLines."Serial No.".Value();
                end;
            GlobalItemTracking::SelectEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();  // Item Tracking Summary Page is handled in 'ItemTrackingSummaryPageHandler'.
                    ItemTrackingLines."Appl.-to Item Entry".SetValue(GlobalApplToItemEntry);
                end;
            GlobalItemTracking::SetValue:
                begin
                    ItemTrackingLines."Lot No.".SetValue(GlobalLotNo);
                    ItemTrackingLines."Serial No.".SetValue(GlobalSerialNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(GlobalPurchasedQuantity);
                end;
        end;

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatisticsPageHandler(var ItemStatistics: TestPage "Item Statistics")
    var
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        ItemStatistics.ShowAsLines.SetValue(GlobalLineOption);
        ItemStatistics.ViewBy.SetValue(PeriodType::Day);
        ItemStatistics.ShowMatrix.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatisticsMatrixPageHandler(var ItemStatisticsMatrix: TestPage "Item Statistics Matrix")
    begin
        ItemStatisticsMatrix.Amount.AssertEquals(GlobalAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatisticsMatrixPageHandlerForSpecificLine(var ItemStatisticsMatrix: TestPage "Item Statistics Matrix")
    var
        VarCount: Variant;
        "Count": Integer;
    begin
        LibraryVariableStorage.Dequeue(VarCount);
        Count := VarCount;
        while Count > 1 do begin
            ItemStatisticsMatrix.Next();
            Count := Count - 1;
        end;
        ItemStatisticsMatrix.Amount.AssertEquals(GlobalAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchReceiptLinePageHandler(var PurchReceiptLines: TestPage "Purch. Receipt Lines")
    begin
        PurchReceiptLines.FILTER.SetFilter("Document No.", GlobalDocumentNo);
        PurchReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentLinePageHandler(var SalesShipmentLines: TestPage "Sales Shipment Lines")
    begin
        SalesShipmentLines.FILTER.SetFilter("Document No.", GlobalDocumentNo);
        SalesShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelItemTemplateHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.Filter.SetFilter(Code, LibraryVariableStorage.DequeueText());
        NoSeriesList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ProductionBOMPageHandler(var ProductionBOM: TestPage "Production BOM")
    begin
        ProductionBOM."No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplateHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.GotoKey(LibraryVariableStorage.DequeueText());
        SelectItemTemplList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionPageHandler(var ItemSubstitutionEntry: TestPage "Item Substitution Entry")
    begin
        ItemSubstitutionEntry."Substitute Type".SetValue(LibraryVariableStorage.DequeueInteger());
        ItemSubstitutionEntry."Substitute No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemSubstitutionEntry.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionEntriesPageHandler(var ItemSubstitutionEntries: TestPage "Item Substitution Entries")
    begin
        ItemSubstitutionEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CatalogItemListModalPageHandler(var CatalogItemList: TestPage "Catalog Item List")
    begin
        CatalogItemList.FILTER.SetFilter("Vendor Item No.", LibraryVariableStorage.DequeueText());
        CatalogItemList.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure FindItemSubstitution(Type: Enum "Item Substitution Type"; No: Code[20]; SubstituteType: Enum "Item Substitute Type"; SubstituteNo: Code[20]): Boolean
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        exit(ItemSubstitution.Get(Type, No, '', SubstituteType, SubstituteNo));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CatalogItemListModalPageHandlerForEntryNo(var CatalogItemList: TestPage "Catalog Item List")
    begin
        CatalogItemList.FILTER.SetFilter("Entry No.", LibraryVariableStorage.DequeueText());
        CatalogItemList.OK().Invoke();
    end;
}

