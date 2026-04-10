codeunit 137266 "SCM Package Tracking Transfer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        isInitialized: Boolean;
        IsNotOnvInventoryErr: Label 'You have insufficient quantity of Item %1 on inventory.', Comment = '%1 - Item No.';
        WrongQtyForItemErr: Label '%1 in the item tracking assigned to the document line for item %2 is currently %3. It must be %4.\\Check the assignment for serial number %5, lot number %6, package number %7.', Comment = '%1 - Qty. to Handle or Qty. to Invoice, %2 - Item No., %3 - actual value, %4 - expected value, %5 - Serial No., %6 - Lot No., %7 - Package No.';
        PackageNoRequiredErr: Label 'You must assign a package number for item %1.', Comment = '%1 - Item No.';
        TearDownErr: Label 'Error in TearDown';
        WrongInventoryErr: Label 'Wrong inventory.';
        SerTxt: Label 'SER';
        DoYouWantPostDirectTransferMsg: Label 'Do you want to post the Direct Transfer?';
        IncorrectConfirmDialogOpenedMsg: Label 'Incorrect confirm dialog opened: %1', Comment = '%1 - Error message';
        HasBeenDeletedMsg: Label 'is now deleted';
        UnexpectedMsg: Label 'Unexpected message: %1', Comment = '%1 - Error message';

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Package Tracking Transfer");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Transfer");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateLocalData();

        InventorySetup.Get();
        InventorySetup.Validate("Posted Direct Trans. Nos.", CreateNoSeries());
        InventorySetup.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Transfer");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferOrder()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[1], 6);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[2], 4);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[1], 6);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[2], 4);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[1], 6);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[2], 4);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDirectTransferWithPackageAndSerialNo()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[2] of Record "Package No. Information";
        PackageNo: Code[50];
        NewPackageNo: array[2] of Code[50];
        Serial: Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);

        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        PackageNo := LibraryUtility.GenerateGUID();

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 5, LocationFrom.Code);
        for i := 1 to 5 do begin
            Serial := 'SN0' + Format(i);
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, Serial, '', PackageNo, 1);
        end;
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        for i := 1 to ArrayLen(NewPackageNo) do begin
            NewPackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[i], Item."No.", NewPackageNo[i]);
        end;

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 3);
        for i := 1 to 3 do begin
            Serial := 'SN0' + Format(i);
            CreateDirectTracking(ReservationEntry, TransferLine, Serial, '', PackageNo, NewPackageNo[1], Serial, '', 1);
        end;

        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        for i := 4 to 5 do begin
            Serial := 'SN0' + Format(i);
            CreateDirectTracking(ReservationEntry, TransferLine, Serial, '', PackageNo, NewPackageNo[2], Serial + '/01', '', 1);
        end;
        PostTransferDocument(TransferHeader);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'SN02', '', NewPackageNo[1], 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'SN05/01', '', NewPackageNo[2], 1);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDTwithBin()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[2] of Record "Package No. Information";
        PackageNo: Code[50];
        NewPackageNo: array[2] of Code[10];
        BinCode: array[2] of Code[20];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LocationTo.Validate("Bin Mandatory", true);
        LocationTo.Modify();

        PackageNo := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(BinCode) do begin
            BinCode[i] := LibraryUtility.GenerateGUID();
            CreateBin(LocationTo, BinCode[i]);
        end;

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo, 10);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        for i := 1 to ArrayLen(NewPackageNo) do begin
            NewPackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[i], Item."No.", NewPackageNo[i]);
        end;

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 3);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', PackageNo, NewPackageNo[1], '', '', 3);
        TransferLine.Validate("Transfer-To Bin Code", BinCode[1]);
        TransferLine.Modify();

        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 7);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', PackageNo, NewPackageNo[2], '', '', 7);
        TransferLine.Validate("Transfer-To Bin Code", BinCode[2]);
        TransferLine.Modify();
        PostTransferDocument(TransferHeader);

        CheckBinContent(LocationTo.Code, BinCode[1], Item."No.", 3);
        CheckBinContent(LocationTo.Code, BinCode[2], Item."No.", 7);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDirectTransferWithPackage()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[2] of Record "Package No. Information";
        PackageNo: Code[50];
        NewPackageNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        PackageNo := LibraryUtility.GenerateGUID();

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo, 10);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        for i := 1 to ArrayLen(NewPackageNo) do begin
            NewPackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[i], Item."No.", NewPackageNo[i]);
        end;

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 3);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', PackageNo, NewPackageNo[1], '', '', 3);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 7);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', PackageNo, NewPackageNo[2], '', '', 7);
        PostTransferDocument(TransferHeader);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', NewPackageNo[1], 3);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', NewPackageNo[2], 7);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDirectTransferWithPackageAndLotNo()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[2] of Record "Package No. Information";
        PackageNo: Code[50];
        LotNo: array[2] of Code[50];
        NewPackageNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        PackageNo := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(NewPackageNo) do begin
            NewPackageNo[i] := LibraryUtility.GenerateGUID();
            LotNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[i], Item."No.", NewPackageNo[i]);
        end;

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        for i := 1 to ArrayLen(LotNo) do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[i], PackageNo, 5);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 6);
        for i := 1 to ArrayLen(LotNo) do
            CreateDirectTracking(ReservationEntry, TransferLine, '', LotNo[i], PackageNo, NewPackageNo[1], '', LotNo[i], 3);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 4);
        CreateDirectTracking(ReservationEntry, TransferLine, '', LotNo[1], PackageNo, NewPackageNo[2], '', LotNo[1], 2);
        CreateDirectTracking(ReservationEntry, TransferLine, '', LotNo[2], PackageNo, NewPackageNo[1], '', LotNo[2], 2);
        PostTransferDocument(TransferHeader);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[2], NewPackageNo[1], 2);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[1], NewPackageNo[2], 2);

        Item.SetFilter("Location Filter", LocationTo.Code);
        Item.SetFilter("Package No. Filter", NewPackageNo[1]);
        Item.SetFilter("Lot No. Filter", LotNo[2]);
        Item.CalcFields(Inventory);

        Assert.AreEqual(5, Item.Inventory, WrongInventoryErr);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckManualPackageinDirectTransfer()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: Code[50];
        NewPackageNo: Code[50];
    begin
        Initialize();
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        PackageNo := LibraryUtility.GenerateGUID();
        NewPackageNo := LibraryUtility.GenerateGUID();

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo, 10);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', PackageNo, NewPackageNo, '', '', 10);
        PostTransferDocument(TransferHeader);
        PackageNoInfo.SetRange("Item No.", Item."No.");
        PackageNoInfo.SetRange("Package No.", NewPackageNo);
        PackageNoInfo.FindFirst();

        CheckPackageInventoryLocation(PackageNoInfo, LocationTo.Code, 10);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTransferOrderWithPackage()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PackageNo: Code[50];
        Qty: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryPurchase.CreateVendor(Vendor);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", LocationFrom.Code);
        Qty := 20;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", 200, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo, Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo, 10);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationFrom.Code, '', '', PackageNo, -10);

        LibraryInventory.PostTransferHeader(TransferHeader, false, true);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTransit.Code, '', '', PackageNo, -10);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo, 10);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTransferOrderWithPackageAndSerialNo()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[3] of Code[50];
        SerialNo: array[3] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            SerialNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 3, LocationFrom.Code);
        for i := 1 to ArrayLen(SerialNo) do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, SerialNo[i], '', PackageNo[i], 1);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 3);
        for i := 1 to ArrayLen(SerialNo) do
            LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, SerialNo[i], '', PackageNo[i], 1);

        TransferLine.Validate("Qty. to Ship", 2);
        TransferLine.Modify();
        Commit();

        // [WHEN 449039] Post the transfer order with package number and quantity to ship greater than the quantity to handle
        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [THEN 449039] Cannot post the transfer order with package number and quantity to ship greater than the quantity to handle
        Assert.ExpectedError(StrSubstNo(WrongQtyForItemErr,
            ReservationEntry.FieldCaption("Qty. to Handle (Base)"), Item."No.", 3, 2, SerialNo[3], '', PackageNo[3]));

        // [WHEN 449039] Remove latest item tracking line
        ReservationEntry.Delete(true);

        // [WHEN 449039] Post the transfer order with package number and quantity to ship equal than the quantity to handle
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [THEN 449039] Valiate the quantity in the locations
        for i := 1 to (ArrayLen(SerialNo) - 1) do
            LibraryItemTracking.CheckLastItemLedgerEntry(
              ItemLedgerEntry, Item."No.", LocationTransit.Code, SerialNo[i], '', PackageNo[i], 1);
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        for i := 1 to (ArrayLen(SerialNo) - 1) do
            LibraryItemTracking.CheckLastItemLedgerEntry(
              ItemLedgerEntry, Item."No.", LocationTo.Code, SerialNo[i], '', PackageNo[i], 1);
        CheckQuantityLocation(Item, LocationTransit.Code, 0);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTransferOrderWithPackageAndLot()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[2] of Code[50];
        LotNo: array[3] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;
        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID();

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[1], PackageNo[1], 5);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[2], PackageNo[2], 3);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[3], PackageNo[2], 2);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', LotNo[1], PackageNo[1], 5);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', LotNo[2], PackageNo[2], 3);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', LotNo[3], PackageNo[2], 2);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTransit.Code, '', LotNo[1], PackageNo[1], 5);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTransit.Code, '', LotNo[2], PackageNo[2], 3);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTransit.Code, '', LotNo[3], PackageNo[2], 2);

        CheckQuantityLocation(Item, LocationFrom.Code, 0);
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[1], PackageNo[1], 5);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[2], PackageNo[2], 3);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[3], PackageNo[2], 2);

        CheckQuantityLocation(Item, LocationTransit.Code, 0);
        CheckQuantityLocation(Item, LocationTo.Code, 10);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithBin()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[2] of Record "Package No. Information";
        PackageNo: array[2] of Code[50];
        BinCode: array[2] of Code[20];
        i: Integer;
    begin
        Initialize();

        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LocationTo.Validate("Bin Mandatory", true);
        LocationTo.Modify();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            BinCode[i] := LibraryUtility.GenerateGUID();
            CreateBin(LocationTo, BinCode[i]);
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[i], Item."No.", PackageNo[i]);
        end;

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[1], 3);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[2], 7);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 3);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[1], 3);
        TransferLine.Validate("Transfer-To Bin Code", BinCode[1]);
        TransferLine.Modify();

        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 7);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[2], 7);
        TransferLine.Validate("Transfer-To Bin Code", BinCode[2]);
        TransferLine.Modify();
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        CheckBinContent(LocationTo.Code, BinCode[1], Item."No.", 3);
        CheckBinContent(LocationTo.Code, BinCode[2], Item."No.", 7);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPartialTransferOrderWithPackage()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PackageNo: array[2] of Code[50];
        Qty: Integer;
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", LocationFrom.Code);
        Qty := 20;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", 200, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[1], 10);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[2], 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 20);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[1], 10);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[2], 10);
        TransferLine.Validate("Qty. to Ship", 15);
        TransferLine.Modify();
        Commit();

        // [WHEN 449039] Post the transfer order with package number and quantity to ship greater than the quantity to handle
        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN 449039] Cannot post the transfer order with package number and quantity to ship greater than the quantity to handle
        Assert.ExpectedError(StrSubstNo(WrongQtyForItemErr,
            ReservationEntry.FieldCaption("Qty. to Handle (Base)"), Item."No.", 20, 15, '', '', PackageNo[2]));

        // [WHEN 449039] Modify the quantity to handle of Package[2] to 5
        ReservationEntry.Validate("Qty. to Handle (Base)", 5);
        ReservationEntry.Modify(true);

        // [THEN 449039] Post the transfer order with package number and quantity to ship equal than the quantity to handle. Valiate the quantity in the locations
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);
        CheckQuantityLocation(Item, LocationFrom.Code, 5);
        CheckQuantityLocation(Item, LocationTo.Code, 15);

        // [WHEN 449039] Post the remaining quantity
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN 449039] Validate the quantity in the locations
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[1], 10);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[2], 5);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPartialTransferOrderWithPackageAndLot()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: Code[50];
        LotNo: array[3] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);
        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID();

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[1], PackageNo, 4);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[2], PackageNo, 3);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[3], PackageNo, 3);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', LotNo[1], PackageNo, 4);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', LotNo[2], PackageNo, 3);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', LotNo[3], PackageNo, 3);
        TransferLine.Validate("Qty. to Ship", 9);
        TransferLine.Modify();
        Commit();

        // [WHEN 449039] Post the transfer order with package number and quantity to ship greater than the quantity to handle
        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN 449039] Cannot post the transfer order with package number and quantity to ship greater than the quantity to handle
        Assert.ExpectedError(StrSubstNo(WrongQtyForItemErr,
            ReservationEntry.FieldCaption("Qty. to Handle (Base)"), Item."No.", 10, 9, '', LotNo[3], PackageNo));

        // [WHEN 449039] Modify the quantity to handle of Package[2] to 2
        ReservationEntry.Validate("Qty. to Handle (Base)", 2);
        ReservationEntry.Modify(true);

        // [THEN 449039] Post the transfer order with package number and quantity to ship equal than the quantity to handle. Valiate the quantity in the locations
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);
        CheckQuantityLocation(Item, LocationFrom.Code, 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[1], PackageNo, 4);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[2], PackageNo, 3);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[3], PackageNo, 2);

        // [WHEN 449039] Post the remaining quantity
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN 449039] Validate the quantity in the locations
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', LotNo[3], PackageNo, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTransferOrderWithPackageUOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PackageNo: array[2] of Code[50];
        Qty: Integer;
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 12);

        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", LocationFrom.Code);
        Qty := 100;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", 200, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[1], 70);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[2], 30);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 8);
        TransferLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        TransferLine.Modify(true);

        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[1], 70);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[2], 26);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[1], 70);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[2], 26);

        CheckQuantityLocation(Item, LocationTo.Code, 96);
        CheckQuantityLocation(Item, LocationFrom.Code, 4);
        CheckQuantityLocation(Item, LocationTransit.Code, 0);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTransferOrderWithPackageAndSerialUOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: Code[50];
        SerialNo: array[7] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 3);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 7, LocationFrom.Code);
        for i := 1 to ArrayLen(SerialNo) do begin
            SerialNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, SerialNo[i], '', PackageNo, 1);
        end;
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        TransferLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        TransferLine.Modify(true);

        for i := 1 to 5 do
            LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, SerialNo[i], '', PackageNo, 1);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, SerialNo[7], '', PackageNo, 1);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        for i := 1 to 5 do
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, SerialNo[i], '', PackageNo, 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, SerialNo[7], '', PackageNo, 1);

        CheckQuantityLocation(Item, LocationTransit.Code, 0);
        CheckQuantityLocation(Item, LocationFrom.Code, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithManyLines()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: array[2] of Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: array[2] of Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode[1], false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item[1], ItemTrackingCode[1]);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item[1]."No.", PackageNo);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode[2], false, false, false);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item[2], ItemTrackingCode[2]);

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item[1]."No.", 60, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo, 60);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item[2]."No.", 60, LocationFrom.Code);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        i := 1;
        while i < 101 do begin
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[2]."No.", 1);
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[1]."No.", 1);
            LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo, 1);
            i := i + 2;
        end;
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[1]."No.", 1);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo, 1);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", LocationTo.Code, '', '', PackageNo, 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", LocationTo.Code, '', '', '', 1);

        CheckQuantityLocation(Item[1], LocationTo.Code, 51);
        CheckQuantityLocation(Item[2], LocationTo.Code, 50);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckITLinesSN()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: Code[50];
        SerialNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);
        for i := 1 to ArrayLen(SerialNo) do
            SerialNo[i] := LibraryUtility.GenerateGUID();

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 1, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, SerialNo[1], '', PackageNo, 1);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, SerialNo[2], '', PackageNo, 1);
        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTracking()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[2] of Code[50];
        SerialNo: array[4] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 4, LocationFrom.Code);
        for i := 1 to ArrayLen(SerialNo) do begin
            SerialNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, SerialNo[i], '', PackageNo[1], 1);
        end;
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 4);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, SerialNo[1], '', PackageNo[1], 1);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, SerialNo[2], '', PackageNo[2], 1);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, SerialNo[3], '', PackageNo[1], 1);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(WrongQtyForItemErr,
            ReservationEntry.FieldCaption("Qty. to Handle (Base)"), Item."No.", 3, 4, SerialNo[1], '', PackageNo[1]));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckInventoryTO()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 4, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[1], 4);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 4);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[2], 4);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItReclJnlOneLoc()
    var
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        LibraryInventory.CreateItemJnlLine(
            ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 20, LocationTo.Code);
        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[1], 20);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        CreateItemReclassJnlLine(ItemJnlLine, "Item Ledger Entry Type"::Transfer, WorkDate(), Item."No.", 15, LocationTo.Code, LocationTo.Code);
        LibraryItemTracking.CreateItemReclassJnLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[1], 15);
        ReservationEntry.Validate("New Package No.", PackageNo[2]);
        ReservationEntry.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[2], 15);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItemReclassJnlLocationsPackage()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PackageNo: array[3] of Code[50];
        SerialNo: array[4] of Code[50];
        NewSerialNo: array[4] of Code[50];
        Qty: Integer;
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryPurchase.CreateVendor(Vendor);

        for i := 1 to ArrayLen(PackageNo) do
            PackageNo[i] := LibraryUtility.GenerateGUID();
        for i := 1 to 2 do
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", LocationFrom.Code);
        Qty := 4;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", 200, Qty);

        for i := 1 to Qty do begin
            SerialNo[i] := LibraryUtility.GenerateGUID();
            NewSerialNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, SerialNo[i], '', PackageNo[Round(i / 2, 1)], 1);
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[3]);

        CreateItemReclassJnlLine(ItemJnlLine, "Item Ledger Entry Type"::Transfer, WorkDate(), Item."No.", 4, LocationFrom.Code, LocationTo.Code);

        LibraryItemTracking.CreateItemReclassJnLineItemTracking(ReservationEntry, ItemJnlLine, SerialNo[1], '', PackageNo[1], 1);
        ReservationEntry.Validate("New Package No.", PackageNo[1]);
        ReservationEntry.Validate("New Serial No.", NewSerialNo[1]);
        ReservationEntry.Modify();
        LibraryItemTracking.CreateItemReclassJnLineItemTracking(ReservationEntry, ItemJnlLine, SerialNo[2], '', PackageNo[1], 1);
        ReservationEntry.Validate("New Package No.", PackageNo[2]);
        ReservationEntry.Validate("New Serial No.", NewSerialNo[2]);
        ReservationEntry.Modify();
        LibraryItemTracking.CreateItemReclassJnLineItemTracking(ReservationEntry, ItemJnlLine, SerialNo[3], '', PackageNo[2], 1);
        ReservationEntry.Validate("New Package No.", PackageNo[1]);
        ReservationEntry.Validate("New Serial No.", NewSerialNo[3]);
        ReservationEntry.Modify();
        LibraryItemTracking.CreateItemReclassJnLineItemTracking(ReservationEntry, ItemJnlLine, SerialNo[4], '', PackageNo[2], 1);
        ReservationEntry.Validate("New Package No.", PackageNo[3]);
        ReservationEntry.Validate("New Serial No.", NewSerialNo[4]);
        ReservationEntry.Modify();
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        CheckQuantityLocation(Item, LocationTo.Code, 4);
        CheckQuantityLocation(Item, LocationFrom.Code, 0);
        CheckQuantityLocationPackage(Item, LocationFrom.Code, PackageNo[1], 0);
        CheckQuantityLocationPackage(Item, LocationFrom.Code, PackageNo[2], 0);
        CheckQuantityLocationPackage(Item, LocationTo.Code, PackageNo[1], 2);
        CheckQuantityLocationPackage(Item, LocationTo.Code, PackageNo[2], 1);
        CheckQuantityLocationPackage(Item, LocationTo.Code, PackageNo[3], 1);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, NewSerialNo[1], '', PackageNo[1], 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, NewSerialNo[3], '', PackageNo[1], 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, NewSerialNo[4], '', PackageNo[3], 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, NewSerialNo[2], '', PackageNo[2], 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckManualPackageInTransferOrder()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();

        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        for i := 1 to ArrayLen(PackageNo) do
            PackageNo[i] := LibraryUtility.GenerateGUID();

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 5, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[1], 2);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[2], 3);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 5);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[1], 2);
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', '', PackageNo[2], 3);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[1], 2);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, '', '', PackageNo[2], 3);

        PackageNoInfo.SetRange("Item No.", Item."No.");
        PackageNoInfo.SetRange("Package No.", PackageNo[1]);
        PackageNoInfo.FindFirst();

        CheckPackageInventoryLocation(PackageNoInfo, LocationTo.Code, 2);
        PackageNoInfo.Reset();
        PackageNoInfo.SetRange("Item No.", Item."No.");
        PackageNoInfo.SetRange("Package No.", PackageNo[2]);
        PackageNoInfo.FindFirst();

        CheckPackageInventoryLocation(PackageNoInfo, LocationTo.Code, 3);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckManualPackageInItemReclassJnl()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[3] of Code[50];
        i: Integer;
    begin
        Initialize();

        CreateDTLocations(LocationFrom, LocationTo);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(PackageNo) do
            PackageNo[i] := LibraryUtility.GenerateGUID();

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 5, LocationFrom.Code);
        for i := 1 to 5 do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, 'S' + Format(i), '', PackageNo[1], 1);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        CreateItemReclassJnlLine(ItemJnlLine, "Item Ledger Entry Type"::Transfer, WorkDate(), Item."No.", 5, LocationFrom.Code, LocationTo.Code);
        for i := 1 to 4 do begin
            LibraryItemTracking.CreateItemReclassJnLineItemTracking(ReservationEntry, ItemJnlLine, 'S' + Format(i), '', PackageNo[1], 1);
            ReservationEntry.Validate("New Serial No.", 'S00' + Format(i));
            ReservationEntry.Validate("New Package No.", PackageNo[2]);
            ReservationEntry.Modify();
        end;

        LibraryItemTracking.CreateItemReclassJnLineItemTracking(ReservationEntry, ItemJnlLine, 'S5', '', PackageNo[1], 1);
        ReservationEntry.Validate("New Serial No.", 'S005');
        ReservationEntry.Validate("New Package No.", PackageNo[3]);
        ReservationEntry.Modify();

        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        PackageNoInfo.Reset();
        PackageNoInfo.SetRange("Item No.", Item."No.");
        PackageNoInfo.SetRange("Package No.", PackageNo[2]);
        PackageNoInfo.FindFirst();
        CheckPackageInventoryLocation(PackageNoInfo, LocationTo.Code, 4);

        PackageNoInfo.Reset();
        PackageNoInfo.SetRange("Item No.", Item."No.");
        PackageNoInfo.SetRange("Package No.", PackageNo[3]);
        PackageNoInfo.FindFirst();
        CheckPackageInventoryLocation(PackageNoInfo, LocationTo.Code, 1);

        PackageNoInfo.Reset();
        PackageNoInfo.SetRange("Item No.", Item."No.");
        PackageNoInfo.SetRange("Package No.", PackageNo[1]);
        PackageNoInfo.FindFirst();
        CheckPackageInventoryLocation(PackageNoInfo, LocationFrom.Code, 0);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItReclJnlErrorInv()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: Code[50];
        NewPackageNo: Code[50];
    begin
        Initialize();

        CreateDTLocations(LocationFrom, LocationTo);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        PackageNo := LibraryUtility.GenerateGUID();
        NewPackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);
        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 5, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo, 5);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        CreateItemReclassJnlLine(ItemJnlLine, "Item Ledger Entry Type"::Transfer, WorkDate(), Item."No.", 5, LocationFrom.Code, LocationTo.Code);
        LibraryItemTracking.CreateItemReclassJnLineItemTracking(ReservationEntry, ItemJnlLine, '', '', NewPackageNo, 5);

        ReservationEntry.Validate("New Package No.", NewPackageNo);
        ReservationEntry.Modify();

        asserterror LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTOwithSNandLot()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();

        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, false);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID();
        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, 'S0', LotNo[1], 5);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, 'S1', LotNo[2], 5);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 6);
        CreateTransferSNTracking(ReservationEntry, TransferLine, 'S0', LotNo[1], 4);
        CreateTransferSNTracking(ReservationEntry, TransferLine, 'S1', LotNo[2], 2);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S001', LotNo[1], '', 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S002', LotNo[1], '', 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S003', LotNo[1], '', 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S004', LotNo[1], '', 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S101', LotNo[2], '', 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationTo.Code, 'S102', LotNo[2], '', 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationFrom.Code, 'S005', LotNo[1], '', 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationFrom.Code, 'S104', LotNo[2], '', 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSNLotError()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, false);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID();
        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, 'S0', LotNo[1], 5);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, 'S1', LotNo[2], 5);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 6);
        CreateTransferSNTracking(ReservationEntry, TransferLine, 'S1', LotNo[1], 4);
        CreateTransferSNTracking(ReservationEntry, TransferLine, 'S0', LotNo[2], 2);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMultiTrackingTO()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        Item: array[2] of Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        ItemTrackingCode: array[2] of Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNo: Code[50];
        i: Integer;
    begin
        Initialize();
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationTransit);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode[1], false, false, true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode[2], true, false, false);

        for i := 1 to ArrayLen(Item) do
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode[i]);
        PackageNo := LibraryUtility.GenerateGUID();

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item[1]."No.", 5, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo, 5);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item[2]."No.", 5, LocationFrom.Code);
        CreateJnlLineSNTracking(ReservationEntry, ItemJnlLine, SerTxt, '', 5);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[1], Item[2]."No.", 4);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[2], Item[1]."No.", 2);
        CreateTransferSNTracking(ReservationEntry, TransferLine[1], SerTxt, '', 4);

        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        Assert.ExpectedError(StrSubstNo(PackageNoRequiredErr, Item[1]."No."));

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDirectTransferWithPackageSerialAndUOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[2] of Record "Package No. Information";
        PackageNo: Code[50];
        NewPackageNo: array[2] of Code[50];
        SerialNo: array[20] of Code[50];
        i: Integer;
    begin
        Initialize();
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 9);

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 20, LocationFrom.Code);
        PackageNo := LibraryUtility.GenerateGUID();
        for i := 1 to 20 do begin
            SerialNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, SerialNo[i], '', PackageNo, 1);
        end;
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        for i := 1 to ArrayLen(NewPackageNo) do begin
            NewPackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[i], Item."No.", NewPackageNo[i]);
        end;

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 2);
        TransferLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        TransferLine.Modify(true);

        for i := 1 to 18 do
            CreateDirectTracking(ReservationEntry, TransferLine, SerialNo[i], '', PackageNo, NewPackageNo[1], SerialNo[i], '', 1);

        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        CreateDirectTracking(ReservationEntry, TransferLine, SerialNo[19], '', PackageNo, NewPackageNo[2], SerialNo[19], '', 1);
        PostTransferDocument(TransferHeader);

        CheckQuantityLocationPackage(Item, LocationTo.Code, NewPackageNo[1], 18);
        CheckQuantityLocationPackage(Item, LocationTo.Code, NewPackageNo[2], 1);
        CheckQuantityLocationPackage(Item, LocationFrom.Code, PackageNo, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDTInventoryErrMsg()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[2] of Record "Package No. Information";
        PackageNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();
        CreateDTLocations(LocationFrom, LocationTo);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[i], Item."No.", PackageNo[i]);
        end;

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[1], 10);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 2, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo[2], 2);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 12);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', PackageNo[1], PackageNo[1], '', '', 8);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', PackageNo[2], PackageNo[2], '', '', 4);
        asserterror PostTransferDocument(TransferHeader);
        Assert.ExpectedError(StrSubstNo(IsNotOnvInventoryErr, Item."No."));

        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckDTwithManyLines()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: array[2] of Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode1: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[2] of Record "Package No. Information";
        PackageNo: Code[50];
        NewPackageNo: array[2] of Code[50];
        i: Integer;
    begin
        Initialize();

        CreateDTLocations(LocationFrom, LocationTo);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode1, true, false, true);

        for i := 1 to ArrayLen(Item) do
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
        PackageNo := LibraryUtility.GenerateGUID();
        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item[1]."No.", 51, LocationFrom.Code);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', '', PackageNo, 51);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);
        for i := 1 to ArrayLen(NewPackageNo) do begin
            NewPackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[i], Item[i]."No.", NewPackageNo[i]);
        end;

        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item[2]."No.", 51, LocationFrom.Code);
        i := 1;
        while i < 52 do begin
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, 'SN' + Format(i), '', NewPackageNo[2], 1);
            i += 1;
        end;
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        CreateDirectTrHeader(TransferHeader, LocationTo.Code, LocationFrom.Code);
        i := 1;
        while i < 101 do begin
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[1]."No.", 1);
            CreateDirectTracking(ReservationEntry, TransferLine, '', '', PackageNo, NewPackageNo[1], '', '', 1);

            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[2]."No.", 1);
            CreateDirectTracking(ReservationEntry, TransferLine, 'SN' + Format((i + 1) / 2), '', NewPackageNo[2], NewPackageNo[2], 'SN_' + Format((i + 1) / 2), '', 1);
            i := i + 2;
        end;
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item[1]."No.", 1);
        CreateDirectTracking(ReservationEntry, TransferLine, '', '', PackageNo, NewPackageNo[2], '', '', 1);
        PostTransferDocument(TransferHeader);

        CheckQuantityLocationPackage(Item[1], LocationTo.Code, NewPackageNo[1], 50);
        CheckQuantityLocationPackage(Item[1], LocationTo.Code, NewPackageNo[2], 1);
        CheckQuantityLocationPackage(Item[2], LocationTo.Code, NewPackageNo[2], 50);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure InTransitCodeUpdatedWhenChangingTransferFromTransOrderNoDirectTransfer()
    var
        LocationFrom: Record Location;
        LocationFromNew: Record Location;
        LocationTo: Record Location;
        LocationTransit: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Transfer Order] [In-Transit Location]
        // [SCENARIO 371940] Transfer Order should allow changing "Transfer-From Code" resulting in empty transit code if "Direct Transfer" is not allowed

        // [GIVEN] Transfer order with "Direct Transfer" = FALSE and "In-Transit Code" filled
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationTransit);

        CreateTransferOrder(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationTransit.Code, false);

        // [WHEN] Change "Transfer-From Code" in the transfer order
        LibraryWarehouse.CreateLocation(LocationFromNew);
        TransferHeader.Validate("Transfer-from Code", LocationFromNew.Code);

        // [THEN] "In-Transit Code" is set to an empty string
        TransferHeader.TestField("In-Transit Code", '');
    end;

    [Test]
    procedure NewPackageNoInItemTrackingLinesForItemReclass()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Package Tracking] [Item Reclassification] [Warehouse]
        // [SCENARIO 414234] "Get Bin Content" function in Item Reclassification Journal fills in "New Package No.".
        Initialize();
        PackageNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with mandatory bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');

        // [GIVEN] Package-tracked item; "Package Warehouse Tracking" is enabled.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        ItemTrackingCode.Validate("Package Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [GIVEN] Post 1 pc to inventory, assign Package No. = "X".
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, 1);
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, '', '', PackageNo, ItemJournalLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Run "Get Bin Content" for item reclassification.
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        GetBinContentFromItemJournalLine(ItemJournalBatch, Location.Code, Bin.Code, Item."No.");

        // [THEN] "Package No." = "New Package No." = "X" in item tracking for the reclassification journal line.
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Package No.", PackageNo);
        ReservationEntry.TestField("New Package No.", PackageNo);
    end;

    local procedure CheckQuantityLocation(var Item: Record Item; LocationCode: Code[10]; Qty: Decimal): Boolean
    begin
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(Inventory);
        Assert.AreEqual(Qty, Item.Inventory, WrongInventoryErr);
    end;

    local procedure CheckQuantityLocationPackage(var Item: Record Item; LocationCode: Code[10]; PackageNo: Code[50]; Qty: Decimal): Boolean
    begin
        Item.SetRange("Location Filter", LocationCode);
        Item.SetRange("Package No. Filter", PackageNo);
        Item.CalcFields(Inventory);
        Assert.AreEqual(Qty, Item.Inventory, WrongInventoryErr);
    end;

    local procedure CreateTransferSNTracking(var ReservationEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line"; SerialNo: Code[10]; LotNo: Code[50]; Quantity: Integer)
    var
        i: Integer;
        Serial: Code[50];
    begin
        for i := 1 to Quantity do begin
            Serial := SerialNo + '0' + Format(i);
            LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, Serial, LotNo, 1);
        end;
    end;

    local procedure CreateJnlLineSNTracking(var ReservationEntry: Record "Reservation Entry"; ItemJnlLine: Record "Item Journal Line"; SerialNo: Code[10]; LotNo: Code[50]; Quantity: Decimal)
    var
        i: Integer;
        Serial: Code[50];
    begin
        for i := 1 to Quantity do begin
            Serial := SerialNo + '0' + Format(i);
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, Serial, LotNo, 1);
        end;
    end;

    local procedure CreateDirectTrHeader(var TransferHeader: Record "Transfer Header"; LocationTo: Text[10]; LocationFrom: Text[10])
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom, LocationTo, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify();
    end;

    local procedure CreateDirectTracking(var ReservationEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line"; SerialNo: Code[50]; LotNo: Code[50]; PackageNo: Code[50]; NewPackageNo: Code[50]; NewSN: Code[50]; NewLot: Code[50]; QtyBase: Integer)
    begin
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, SerialNo, LotNo, QtyBase);
        ReservationEntry.Validate("Package No.", PackageNo);
        ReservationEntry.Validate("New Package No.", NewPackageNo);
        ReservationEntry.Validate("New Serial No.", NewSN);
        ReservationEntry.Validate("New Lot No.", NewLot);
        ReservationEntry.Modify(true);
    end;

    local procedure CreateBin(var Location: Record Location; BinCode: Code[20])
    var
        BinLine: Record Bin;
    begin
        BinLine.Init();
        BinLine.Validate("Location Code", Location.Code);
        BinLine.Validate(Code, BinCode);
        BinLine.Insert(true);
    end;

    local procedure CreateItemReclassJnlLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; PostingDate: Date; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; NewLocationCode: Code[10])
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        NoSeries: Codeunit "No. Series";
        LineNo: Integer;
    begin
        FindItemJournalTemplateTransfer(ItemJnlTemplate);
        LibraryInventory.FindItemJournalBatch(ItemJnlBatch, ItemJnlTemplate);

        ItemJournalLine.SetRange("Journal Template Name", ItemJnlTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        if ItemJournalLine.FindLast() then;
        LineNo := ItemJournalLine."Line No." + 10000;

        ItemJournalLine.Init();
        ItemJournalLine."Journal Template Name" := ItemJnlTemplate.Name;
        ItemJournalLine."Journal Batch Name" := ItemJnlBatch.Name;
        ItemJournalLine."Line No." := LineNo;
        ItemJournalLine.Insert(true);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine."Document No." := NoSeries.GetNextNo(ItemJnlBatch."No. Series", ItemJournalLine."Posting Date");
        ItemJournalLine.Validate("Entry Type", EntryType);
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("New Location Code", NewLocationCode);
        ItemJournalLine.Modify();
    end;

    local procedure FindItemJournalTemplateTransfer(var ItemJournalTemplate: Record "Item Journal Template")
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Transfer);
        ItemJournalTemplate.SetRange(Recurring, false);
        if not ItemJournalTemplate.FindFirst() then begin
            LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
            ItemJournalTemplate.Validate(Type, ItemJournalTemplate.Type::Transfer);
            ItemJournalTemplate.Modify(true);
        end;
    end;

    local procedure CreateDTLocations(var LocationFrom: Record Location; var LocationTo: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        exit(NoSeries.Code);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; FromCode: Code[10]; ToCode: Code[10]; InTransitCode: Code[10]; DirectTransfer: Boolean)
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, FromCode, ToCode, InTransitCode);
        TransferHeader.Validate("Direct Transfer", DirectTransfer);
        TransferHeader.Modify(true);

        // Create a dummy item
        Item.Init();
        Item.Insert(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
    end;

    local procedure CheckPackageInventoryLocation(var PackageNoInfo: Record "Package No. Information"; LocationCode: Code[10]; Qty: Decimal): Boolean
    begin
        PackageNoInfo.SetRange("Location Filter", LocationCode);
        PackageNoInfo.CalcFields(Inventory);
        Assert.AreEqual(Qty, PackageNoInfo.Inventory, WrongInventoryErr);
    end;

    local procedure CheckBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Qty: Integer)
    var
        BinCon: Record "Bin Content";
    begin
        BinCon.SetFilter("Location Code", LocationCode);
        BinCon.SetFilter("Bin Code", BinCode);
        BinCon.SetFilter("Item No.", ItemNo);
        BinCon.FindFirst();
        BinCon.CalcFields(Quantity);
        Assert.AreEqual(Qty, BinCon.Quantity, WrongInventoryErr);
    end;

    local procedure GetBinContentFromItemJournalLine(ItemJournalBatch: Record "Item Journal Batch"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseGetBinContentFromItemJournalLine(BinContent, ItemJournalLine);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure PostTransferDocument(var TransferHeader: Record "Transfer Header")
    var
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
    begin
        TransferPostTransfer.Run(TransferHeader);
    end;

    local procedure TearDown()
    begin
        asserterror Error(TearDownErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DoYouWantPostDirectTransferMsg) <> 0 then
            Reply := true
        else
            Error(IncorrectConfirmDialogOpenedMsg, Question);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(msg: Text[1024])
    var
        temp: Text[1024];
    begin
        if StrPos(msg, HasBeenDeletedMsg) <> 0 then
            temp := msg;
        case msg of
            temp:
                ;
            else
                Error(UnexpectedMsg, msg);
        end;
    end;
}

