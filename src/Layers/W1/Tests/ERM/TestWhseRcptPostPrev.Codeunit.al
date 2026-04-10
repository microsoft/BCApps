codeunit 134783 "Test Whse. Rcpt. Post Prev."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Warehouse Receipt]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        Step: Integer;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PreviewWarehouseyReceiptPost_PurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        WhsePostReceiptYesNo: Codeunit "Whse.-Post Receipt (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Purchase] [Warehouse Receipt] [Preview Posting]
        // [SCENARIO] Preview Warehouse Receipt posting shows the ledger entries that will be grnerated when the Receipt is posted.
        Initialize();

        // [GIVEN] Location for Warehouse Receipt where the 'Require Receipt' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, false, false, false, true, false);

        // [GIVEN] Purchase Order created with Posting Date = WORKDATE
        CreatePurchaseDocumentWithLineLocation(PurchaseHeader, Location.Code, '');

        // [WHEN] Warehouse Receipt created
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhsePostReceiptYesNo.Preview(WarehouseReceiptLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the put away is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PreviewWarehouseReceiptPostWithBin_PurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Location: Record Location;
        Bin: Record Bin;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WarehouseEntry: Record "Warehouse Entry";
        WhsePostReceiptYesNo: Codeunit "Whse.-Post Receipt (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Purchase] [Warehouse Receipt] [Preview Posting]
        // [SCENARIO] Preview Warehouse Receipt posting with Bin set shows the ledger entries that will be grnerated when the Receipt is posted.
        Initialize();

        // [GIVEN] Location for Warehouse Receipt where 'Require Receipt' and 'Bin Mandatory' are true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, true, false, false, true, false);
        LibraryWarehouse.CreateBin(
                  Bin, Location.Code,
                  CopyStr(
                    LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                    LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Purchase Order created
        CreatePurchaseDocumentWithLineLocation(PurchaseHeader, Location.Code, Bin.Code);

        // [WHEN] Warehouse Receipt created
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhsePostReceiptYesNo.Preview(WarehouseReceiptLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the put away is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouseEntry.TableCaption(), 1);

        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreviewWarehouseReceiptPost_TransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WhsePostReceiptYesNo: Codeunit "Whse.-Post Receipt (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Transfer] [Warehouse Receipt] [Preview Posting]
        // [SCENARIO] Preview Warehouse Receipt posting shows the ledger entries that will be generated when the Receipt is posted.
        Initialize();

        // [GIVEN] Location for Warehouse Receipt where 'Require Receipt' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(FromLocation, false, false, false, false, false);
        CreateLocationWMSWithWhseEmployee(ToLocation, false, false, false, true, false);

        // [GIVEN] Create and release a Transfer Order
        CreateTransferOrderWithLineLocation(TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Warehouse Receipt created
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, TransferHeader."No.");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhsePostReceiptYesNo.Preview(WarehouseReceiptLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the Receipt is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SetLotItemWithQtyToHandleTrackingPageHandler')]
    procedure CheckTransferOrderPostingWithLotItemAndUpdatingExpirationDate()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        LotNo: Code[20];
        ExpirationDate: Date;
        NewExpirationDate: Date;
        ItemInventory: Decimal;
        TransferQty: Decimal;
        ErrorMsg: Label 'New Expiration Date must be equal to ''%1''  in Tracking Specification', Comment = '%1 - Expiration Date';
    begin
        // [FEATURE] [Transfer] [Lot Tracking] [New Expiration Date]
        // [SCENARIO] System should not allow to post Transfer Order with Lot Tracking Item if 
        //New Expiration Date is not equal to Expiration Date in Tracking Specification if qty is less then total inventory of specific lot
        Initialize();

        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(FromLocation, false, false, false, false, false);
        CreateLocationWMSWithWhseEmployee(ToLocation, false, false, false, false, false);

        // [GIVEN] Create Item Tracking Code and LOT tracking Item
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode."Use Expiration Dates" := true;
        ItemTrackingCode.Modify();
        Commit();
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [GIVEN] Create and post Item Journal Line with LOT tracking Item
        ItemInventory := LibraryRandom.RandIntInRange(10, 20);
        LotNo := LibraryRandom.RandText(10);
        ExpirationDate := WorkDate() + 10;
        NewExpirationDate := WorkDate() + 20;
        TransferQty := ItemInventory / 2;
        Step := 1;
        PostItemPositiveAdjustmentWithLotTracking(Item, FromLocation, '', LotNo, ExpirationDate, ItemInventory);

        // [GIVEN] Create Transfer Order and post Shipment
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", TransferQty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(TransferQty);
        Step := 2;
        TransferLine.OpenItemTrackingLines(Enum::"Transfer Direction"::Outbound);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Post update of Expiration Date
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Step := 3;
        LibraryVariableStorage.Enqueue(NewExpirationDate);
        TransferLine.OpenItemTrackingLines(Enum::"Transfer Direction"::Inbound);

        // [THEN] System should not allow to post Transfer Order
        asserterror LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrorMsg, ExpirationDate)) > 0, '');
    end;

    local procedure PostItemPositiveAdjustmentWithLotTracking(Item: Record Item; Location: Record Location; BinCode: Code[20]; LotNo: Code[20]; ExpirationDate: Date; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, BinCode, Qty);

        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);

        UpdateReservationEntryWithExpirationDate(Item."No.", LotNo, ExpirationDate);

        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateReservationEntryWithExpirationDate(ItemNo: Code[20]; LotNo: Code[20]; NewExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.ModifyAll("Expiration Date", NewExpirationDate);
    end;

    [ModalPageHandler]
    procedure SetLotItemWithQtyToHandleTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case Step of
            1:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines.OK().Invoke();
                end;

            2:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines.OK().Invoke();
                end;

            3:
                begin
                    ItemTrackingLines."New Expiration Date".SetValue(LibraryVariableStorage.DequeueDate());
                    ItemTrackingLines.OK().Invoke();
                end;
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PreviewWarehouseyReceiptPost_PurchaseOrderWithPutAway()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        WhsePostReceiptYesNo: Codeunit "Whse.-Post Receipt (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Purchase] [Warehouse Receipt] [Preview Posting]
        // [SCENARIO] Preview Warehouse Receipt posting shows the ledger entries that will be generated when the Receipt is posted.
        // Bug https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/457307
        Initialize();

        // [GIVEN] Location for Warehouse Receipt where the 'Require Receipt', 'Require Shipment', 'Require PutAway' and 'Require Pick' are true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, false, true, true, true, true);

        // [GIVEN] Purchase Order created with Posting Date = WORKDATE
        CreatePurchaseDocumentWithLineLocation(PurchaseHeader, Location.Code, '');

        // [WHEN] Warehouse Receipt created
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhsePostReceiptYesNo.Preview(WarehouseReceiptLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the put away is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    procedure PreviewWarehouseReceiptForTwoPurchaseOrders()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WhsePostReceiptYesNo: Codeunit "Whse.-Post Receipt (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Purchase] [Warehouse Receipt] [Preview Posting]
        // [SCENARIO 463437] Preview Warehouse Receipt posting shows the ledger entries for two purchase orders included in the receipt.
        Initialize();

        // [GIVEN] Location set up for required receipt.
        CreateLocationWMSWithWhseEmployee(Location, false, false, false, true, false);

        // [GIVEN] Purchase order "1", release.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Purchase order "2", release.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create warehouse receipt, add two purchase orders.
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", Location.Code);
        WarehouseReceiptHeader.Modify(true);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Inbound);
        WarehouseSourceFilter.Validate("Purchase Orders", true);
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, Location.Code);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindSet();

        Commit();

        // [WHEN] Run posting preview for the warehouse receipt.
        GLPostingPreview.Trap();
        asserterror WhsePostReceiptYesNo.Preview(WarehouseReceiptLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview shows item and value entries for both purchase orders.
        GLPostingPreview.Filter.SetFilter("Table Name", ItemLedgerEntry.TableCaption());
        GLPostingPreview."No. of Records".AssertEquals(2);
        GLPostingPreview.Filter.SetFilter("Table Name", ValueEntry.TableCaption());
        GLPostingPreview."No. of Records".AssertEquals(2);
        GLPostingPreview.OK().Invoke();
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Whse. Rcpt. Post Prev.");
        LibrarySetupStorage.Restore();
        WarehouseEmployee.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Whse. Rcpt. Post Prev.");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Whse. Rcpt. Post Prev.");
    end;

    local procedure CreateLocationWMSWithWhseEmployee(var Location: Record Location; BinMandatory: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreatePurchaseDocumentWithItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchaseDocumentWithLineLocation(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; BinCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);

        CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateTransferOrderWithLineLocation(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        InTransitLocation: Record Location;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", FromLocationCode, '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(5));
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; DocumentNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source No.", DocumentNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(),
          StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

