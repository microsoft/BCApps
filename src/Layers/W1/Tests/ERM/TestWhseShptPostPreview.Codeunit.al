codeunit 134782 "Test Whse. Shpt. Post Preview"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Warehouse Shipment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        IsInitialized: Boolean;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PreviewWarehouseShipmentPost_SalesOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        VATEntry: Record "VAT Entry";
        DetailedCustLedgerEntry: Record "Detailed Cust. Ledg. Entry";
        ValueEntry: Record "Value Entry";
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Sales] [Warehouse Shipment] [Preview Posting]
        // [SCENARIO] Preview Warehouse Shipment posting shows the ledger entries that will be grnerated when the shipment is posted.
        Initialize();

        // [GIVEN] Location for Warehouse Shipment where the 'Require Shipment' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, false, false, false, false, true);

        // [GIVEN] Sales Order created with Posting Date = WORKDATE
        CreateSalesDocumentWithLineLocation(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, '');

        // [WHEN] Warehouse Shipment created
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhsePostShipmentYesNo.Preview(WarehouseShipmentLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the Shipment is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, GLEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, CustLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, VATEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, DetailedCustLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PreviewWarehouseShipmentPostWithBin_SalesOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        Bin: Record Bin;
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        VATEntry: Record "VAT Entry";
        DetailedCustLedgerEntry: Record "Detailed Cust. Ledg. Entry";
        ValueEntry: Record "Value Entry";
        WarehouseEntry: Record "Warehouse Entry";
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Sales] [Warehouse Shipment] [Preview Posting]
        // [SCENARIO] Preview Warehouse Shipment posting with Bin set shows the ledger entries that will be grnerated when the Shipment is posted.
        Initialize();

        // [GIVEN] Location for Warehouse Shipment where 'Require Shipment' and 'Bin Mandatory' are true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, true, false, false, false, true);
        LibraryWarehouse.CreateBin(
                  Bin, Location.Code,
                  CopyStr(
                    LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                    LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Sales Order created
        CreateSalesDocumentWithLineLocation(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Bin.Code);

        // [WHEN] Warehouse Shipment created
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        //Commit();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhsePostShipmentYesNo.Preview(WarehouseShipmentLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the Shipment is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, GLEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, CustLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, VATEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, DetailedCustLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouseEntry.TableCaption(), 1);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PreviewMultipleTimesWarehouseShipmentPostWithBin_SalesOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        Bin: Record Bin;
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        VATEntry: Record "VAT Entry";
        DetailedCustLedgerEntry: Record "Detailed Cust. Ledg. Entry";
        ValueEntry: Record "Value Entry";
        WarehouseEntry: Record "Warehouse Entry";
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Sales] [Warehouse Shipment] [Preview Posting]
        // [SCENARIO] Preview Warehouse Shipment posting multiple times with Bin set shows the ledger entries that will be grnerated when the Shipment is posted.
        Initialize();

        // [GIVEN] Location for Warehouse Shipment where 'Require Shipment' and 'Bin Mandatory' are true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(Location, true, false, false, false, true);
        LibraryWarehouse.CreateBin(
                  Bin, Location.Code,
                  CopyStr(
                    LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                    LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Sales Order created
        CreateSalesDocumentWithLineLocation(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Bin.Code, true);

        // [WHEN] Warehouse Shipment created
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        //Commit();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhsePostShipmentYesNo.Preview(WarehouseShipmentLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);
        GLPostingPreview.OK().Invoke();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhsePostShipmentYesNo.Preview(WarehouseShipmentLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the Shipment is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, GLEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, CustLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, VATEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, DetailedCustLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, WarehouseEntry.TableCaption(), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreviewWarehouseShipmentPost_TransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Transfer] [Warehouse Shipment] [Preview Posting]
        // [SCENARIO] Preview Warehouse Shipment posting shows the ledger entries that will be generated when the Shipment is posted.
        Initialize();

        // [GIVEN] Location for Warehouse Shipment where 'Require Shipment' is true
        // [GIVEN] Warehouse Employee setup for User and Location
        CreateLocationWMSWithWhseEmployee(FromLocation, false, false, false, false, true);
        CreateLocationWMSWithWhseEmployee(ToLocation, false, false, false, false, false);

        // [GIVEN] Create and release a Transfer Order
        CreateTransferOrderWithLineLocation(TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Warehouse Shipment created
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, TransferHeader."No.");
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror WhsePostShipmentYesNo.Preview(WarehouseShipmentLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the Shipment is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    procedure PreviewWarehouseShipmentForTwoSalesOrders()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Sales] [Warehouse Shipment] [Preview Posting]
        // [SCENARIO 463437] Preview Warehouse Shipment posting shows the ledger entries for two sales orders included in the shipment.
        Initialize();

        // [GIVEN] Location set up for required shipment.
        CreateLocationWMSWithWhseEmployee(Location, false, false, false, false, true);

        // [GIVEN] Sales order "1", release.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Sales order "2", release.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create warehouse shipment, add two sales orders.
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", Location.Code);
        WarehouseShipmentHeader.Modify(true);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Sales Orders", true);
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, Location.Code);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindSet();

        Commit();

        // [WHEN] Run posting preview for the warehouse shipment.
        GLPostingPreview.Trap();
        asserterror WhsePostShipmentYesNo.Preview(WarehouseShipmentLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview shows item and value entries for both sales orders.
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Whse. Shpt. Post Preview");
        LibrarySetupStorage.Restore();
        WarehouseEmployee.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Whse. Shpt. Post Preview");

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
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Whse. Shpt. Post Preview");
    end;

    local procedure CreateLocationWMSWithWhseEmployee(var Location: Record Location; BinMandatory: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateSalesDocumentWithItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesDocumentWithLineLocation(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10]; BinCode: Code[10])
    begin
        CreateSalesDocumentWithLineLocation(SalesHeader, DocumentType, LocationCode, BinCode, false);
    end;

    local procedure CreateSalesDocumentWithLineLocation(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10]; BinCode: Code[20]; CreateServiceItemGroup: Boolean)
    var
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryInventory.CreateItem(Item);
        if CreateServiceItemGroup then begin
            LibraryService.CreateServiceItemGroup(ServiceItemGroup);
            ServiceItemGroup.Validate("Create Service Item", true);
            ServiceItemGroup.Modify(true);
            Item.Validate("Service Item Group", ServiceItemGroup.Code);
            Item.Modify(true);
        end;

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", LocationCode, BinCode, LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, Item."No.");
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
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

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; DocumentNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source No.", DocumentNo);
        WarehouseShipmentLine.FindFirst();
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

