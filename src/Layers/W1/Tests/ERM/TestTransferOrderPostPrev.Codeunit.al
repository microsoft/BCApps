codeunit 134784 "Test Transfer Order Post Prev."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Transfer Order]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';

    [Test]
    [HandlerFunctions('TransferOrderPostOptionsHandler')]
    [Scope('OnPrem')]
    procedure PostPreviewTransferOrder_TransferShipment()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Transfer Order] [Preview Posting]
        // [SCENARIO] Transfer Order posting preview shows the ledger entries that will be generated when the transfer order is posted.
        Initialize();

        // [GIVEN] Create FromLocation, ToLocation and IntransitLocation that will be used to create Transfer Order
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);

        // [GIVEN] Create Transfer Order
        CreateTransferOrderWithLocation(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        LibraryVariableStorage.Enqueue(1); // Choice 1 is ship
        asserterror TransferOrderPostYesNo.Preview(TransferHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the pick is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('TransferOrderPostOptionsHandler')]
    [Scope('OnPrem')]
    procedure PostPreviewTransferOrder_TransferReceipt()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Transfer Order] [Preview Posting]
        // [SCENARIO] Transfer Order posting preview shows the ledger entries that will be generated when the transfer order is posted.
        Initialize();

        // [GIVEN] Create FromLocation, ToLocation and IntransitLocation that will be used to create Transfer Order
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);

        // [GIVEN] Create Transfer Order
        CreateTransferOrderWithLocation(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);

        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        LibraryVariableStorage.Enqueue(2); // Choice 1 is receipt
        asserterror TransferOrderPostYesNo.Preview(TransferHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the pick is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPreviewTransferOrder_DirectTransfer_ShipAndReceiptPosting()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        InventorySetup: Record "Inventory Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Transfer Order] [Preview Posting]
        // [SCENARIO] Transfer Order posting preview shows the ledger entries that will be generated when the transfer order  is posted.
        Initialize();

        InventorySetup.Get();
        InventorySetup.Validate("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Receipt and Shipment");
        InventorySetup.Modify(true);

        // [GIVEN] Create FromLocation, ToLocation and IntransitLocation that will be used to create Transfer Order
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);

        // [GIVEN] Create Transfer Order
        CreateTransferOrderWithLocation(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror TransferOrderPostYesNo.Preview(TransferHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the pick is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 4);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 4);
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPreviewTransferOrder_DirectTransfer_DirectTransferPosting()
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        InventorySetup: Record "Inventory Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Transfer Order] [Preview Posting]
        // [SCENARIO] Transfer Order posting preview shows the ledger entries that will be generated when the transfer order  is posted.
        Initialize();

        InventorySetup.Get();
        InventorySetup.Validate("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Direct Transfer");
        InventorySetup.Modify(true);

        // [GIVEN] Create FromLocation, ToLocation and IntransitLocation that will be used to create Transfer Order
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);

        // [GIVEN] Create Transfer Order
        CreateTransferOrderWithLocation(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        Commit();

        // [WHEN] Preview is invoked
        GLPostingPreview.Trap();
        asserterror TransferOrderPostYesNo.Preview(TransferHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview creates the entries that will be created when the pick is posted
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 2);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 2);
        GLPostingPreview.OK().Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Transfer Order Post Prev.");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Test Transfer Order Post Prev.");

        LibrarySetupStorage.Save(Database::"Inventory Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Test Transfer Order Post Prev.");
    end;

    local procedure CreateTransferOrderWithLocation(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; IntransitLocationCode: Code[10])
    var
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", FromLocationCode, '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, IntransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(),
          StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure TransferOrderPostOptionsHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;
}

