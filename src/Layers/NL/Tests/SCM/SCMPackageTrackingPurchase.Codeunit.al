codeunit 137265 "SCM Package Tracking Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        PackageNoRequiredErr: Label 'You must assign a package number for item %1.', Comment = '%1 - Item No.';
        PackageNoInfoFoundErr: Label '%1  is not found, filters: %2.';
        PackageNoInfoQtyErr: Label 'Incorrect quantity for Package No. Information = %1, filters: %2.';
        ItemTrackingErr: Label 'Item Tracking Serial No.  Lot No.  Package No.';
        IncorrConfirmDialogOpenedErr: Label 'Incorrect confirm dialog opened.';
        DoYouWantToUndoMsg: Label 'Do you really want to undo the selected Receipt lines';
        QtyToInvoiceDoesNotMatchItemTrackingErr: Label 'The quantity to invoice does not match the quantity defined in item tracking.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Package Tracking Purchase");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Purchase");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateLocalData();

        LibraryPurchase.SetReturnOrderNoSeriesInSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Purchase");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder1PackagePO()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ITemTrackingSetup: Record "Item Tracking Setup";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Qty: Decimal;
        PackageNo: array[2, 2] of Code[30];
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order
        // 2 items with 2 different package numbers are purchased

        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        ITemTrackingSetup."Package No. Required" := true;
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, ITemTrackingSetup);

        for i := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
            for j := 1 to 2 do begin
                PackageNo[i, j] := LibraryUtility.GenerateGUID();
                LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item[i]."No.", PackageNo[i, j]);
            end;
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", Location.Code);
        Qty := 40;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[1, 1], Qty);

        Qty := 50;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[1, 2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[2], Vendor."No.", Location.Code);
        Qty := 70;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[2], Item[1]."No.", 20, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[2, 1], Qty);

        Qty := 30;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[2], Item[2]."No.", 15, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[2, 2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1, 1], 40);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[1, 2], 50);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[2, 1], 70);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[2, 2], 30);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderThreePackagesWithSerialLot()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PackageNoInfo: Record "Package No. Information";
        Qty: Decimal;
        PackageNo: array[2, 2] of Code[30];
        LotNo: array[2] of Code[20];
        SerialNo: array[2, 5] of Code[20];
        i: Integer;
    begin
        // scenario for purchase order (1.3 Diff Types of Tracking: (Package-Lot-Serial No.))

        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        ItemTrackingSetup."Serial No. Required" := true;
        ItemTrackingSetup."Lot No. Required" := true;
        ItemTrackingSetup."Package No. Required" := true;
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, ItemTrackingSetup);

        for i := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
            PackageNo[1, i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item[i]."No.", PackageNo[1, i]);
            LotNo[i] := LibraryUtility.GenerateGUID();
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Prices Including VAT", true);
        PurchaseHeader[1].Modify();
        Qty := 3;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        for i := 1 to 3 do begin
            SerialNo[1, i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, SerialNo[1, i], LotNo[1], PackageNo[1, 1], 1);
        end;

        Qty := 5;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        for i := 1 to 5 do begin
            SerialNo[2, i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, SerialNo[2, i], LotNo[2], PackageNo[1, 2], 1);
        end;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);
        for i := 1 to 3 do
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[1, i], LotNo[1], PackageNo[1, 1], 1);
        for i := 1 to 5 do
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[2, i], LotNo[2], PackageNo[1, 2], 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderTwoPackageAutoCr()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
        PackageNo: array[3] of Code[30];
        i: Integer;
    begin
        // scenario for purchase order (1.2 PO > Package)
        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        for i := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
            PackageNo[i] := LibraryUtility.GenerateGUID();
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", Location.Code);
        Qty := 4;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[1], Qty);

        Qty := 5;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1], 4);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[2], 5);

        CheckPackageNoInfoInfo(Item[1]."No.", PackageNo[1], 4, Location.Code);
        CheckPackageNoInfoInfo(Item[2]."No.", PackageNo[2], 5, Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderThreePackagesWithLot()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PackageNoInfo: Record "Package No. Information";
        Qty: Decimal;
        PackageNo: array[2, 2] of Code[30];
        LotNo: array[2, 2] of Code[20];
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order: 1.3 Different Types of Tracking: (Package + Lot No.)
        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);

        for i := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
            PackageNo[1, i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item[i]."No.", PackageNo[1, i]);
            for j := 1 to ArrayLen(Item) do
                LotNo[i, j] := LibraryUtility.GenerateGUID();
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Prices Including VAT", true);
        PurchaseHeader[1].Modify();
        Qty := 3;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo[1, 1], PackageNo[1, 1], 1);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo[1, 2], PackageNo[1, 1], 2);

        Qty := 5;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo[2, 1], PackageNo[1, 2], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo[2, 2], PackageNo[1, 2], 3);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo[1, 1], PackageNo[1, 1], 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo[1, 2], PackageNo[1, 1], 2);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo[2, 1], PackageNo[1, 2], 2);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo[2, 2], PackageNo[1, 2], 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder4PartialPost()
    var
        Location: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
        PackageNoInfo: Record "Package No. Information";
        Qty: Decimal;
        PackageNo: Code[50];
        Qtytorec: Decimal;
    begin
        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify();
        Qty := 5;
        Qtytorec := 3;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", 15, Qty);
        PurchaseLine.Validate("Qty. to Receive", Qtytorec);
        PurchaseLine.Modify();

        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo, Qty);
        ReservationEntry.Validate("Qty. to Handle (Base)", 3);
        ReservationEntry.Validate("Qty. to Invoice (Base)", 3);
        ReservationEntry.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo, 3);

        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder5ComplexUOM()
    var
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: Code[50];
    begin
        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 6);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 4);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo, 24);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo, 24);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder7NoLocation()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Qty: Decimal;
        PackageNo: Code[50];
    begin
        // Purchase item with package without Location

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 6);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", '');
        PurchaseHeader.Validate("Prices Including VAT", true);

        Qty := 4;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", 20, Qty);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        PurchaseLine.Modify(true);

        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo, Qty * 6);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', '', PackageNo, 24);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderCheckerrITL()
    var
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Trying to post purchase order without tracking information in ITL.

        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 6);

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 4);

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(StrSubstNo(PackageNoRequiredErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderCheckerrITLQ()
    var
        Location: Record Location;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: Code[50];
    begin
        // Trying to post purchase order with wrong Qty in ITL.

        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 6);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 20);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo, 20);

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(QtyToInvoiceDoesNotMatchItemTrackingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrder3LOT()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
        LotNo: array[2, 2] of Code[20];
        Qty: Decimal;
        i: Integer;
        j: Integer;
    begin
        // scenario for purchase order: 1.3 Different Types of Tracking: (LOT tracking only)

        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);

        for i := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
            for j := 1 to ArrayLen(Item) do
                LotNo[i, j] := LibraryUtility.GenerateGUID();
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Prices Including VAT", true);
        PurchaseHeader[1].Modify();
        Qty := 3;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo[1, 1], '', 1);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo[1, 2], '', 2);
        Qty := 5;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo[2, 1], '', 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo[2, 2], '', 3);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo[1, 1], '', 1);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo[1, 2], '', 2);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo[2, 1], '', 2);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo[2, 2], '', 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderPackageAutoCreateForm()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PackageNo: array[2] of Code[30];
        Qty: Decimal;
        i: Integer;
    begin
        // Scenario for purchase order 2 PO > Package by "Package Auto-Create Inbound Info" = yes

        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        for i := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
            PackageNo[i] := LibraryUtility.GenerateGUID();
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", Location.Code);
        Qty := 4;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[1], Qty);
        Qty := 5;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1], 4);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[2], 5);

        CheckPackageNoInfoInfo(Item[1]."No.", PackageNo[1], 4, Location.Code);
        CheckPackageNoInfoInfo(Item[2]."No.", PackageNo[2], 5, Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderPackageAutoCreateNoLocation()
    var
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PackageNo: array[2] of Code[30];
        Qty: Decimal;
        i: Integer;
    begin
        // Scenario for purchase order PO > Package by "Package Auto-Create Inbound Info" = yes  without location

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        for i := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
            PackageNo[i] := LibraryUtility.GenerateGUID();
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", '');
        Qty := 4;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[1]."No.", 20, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[1], Qty);

        Qty := 5;
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader[1], Item[2]."No.", 15, Qty);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", '', '', '', PackageNo[1], 4);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", '', '', '', PackageNo[2], 5);

        CheckPackageNoInfoInfo(Item[1]."No.", PackageNo[1], 4, '');
        CheckPackageNoInfoInfo(Item[2]."No.", PackageNo[2], 5, '');
    end;

    [Test]
    [HandlerFunctions('HndlConfirm')]
    [Scope('OnPrem')]
    procedure TestPurchOrderPackageReceipt()
    var
        Location: Record Location;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PackageNoInfo: Record "Package No. Information";
        PurchaseInvLine: Record "Purchase Line";
        PurchaseInvHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        ItemChargeAssgntSCode: Codeunit "Item Charge Assgnt. (Purch.)";
        PurchaseOrderNo: Code[20];
        PackageNo: array[2, 2] of Code[30];
        ItemChargeNo: Code[20];
        i: Integer;
    begin
        // PO -> post as Receipt -> goto Posted Receipt and run function Undo
        // Receipt  -> goto  PO and post it again in Receipt option -> post Invoice ->
        // Apply Item Charges  as a separate invoice-> period activity Adjust Cost-Item Entries.

        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        for i := 1 to ArrayLen(Item) do begin
            LibraryItemTracking.CreateItemWithItemTrackingCode(Item[i], ItemTrackingCode);
            PackageNo[i, 1] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item[i]."No.", PackageNo[i, 1]);
        end;

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[1], PurchaseHeader[1], Item[1]."No.", 20, 70);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[2], PurchaseHeader[1], Item[2]."No.", 30, 40);

        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[1, 1], 70);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', '', PackageNo[2, 1], 40);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1, 1], 70);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[2, 1], 40);

        PurchRcptHeader.Reset();
        PurchRcptHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptLine.Reset();
        PurchRcptLine.SetFilter("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("No.", Item[1]."No.");
        PurchRcptLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Undo Purchase Receipt Line", PurchRcptLine);
        PurchRcptLine.Reset();
        PurchRcptLine.SetFilter("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter("No.", Item[2]."No.");
        PurchRcptLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Undo Purchase Receipt Line", PurchRcptLine);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1, 1], -70);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[2, 1], -40);

        PurchaseHeader[1].Reset();
        PurchaseHeader[1].SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader[1].FindFirst();

        PurchaseLine[1].Validate("Qty. to Receive", 53);
        PurchaseLine[1].Modify();
        PurchaseLine[2].Validate("Qty. to Receive", 0);
        PurchaseLine[2].Modify();

        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[1, 1], 0);
        ReservationEntry.Validate("Qty. to Handle (Base)", 53);
        ReservationEntry.Modify();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', '', PackageNo[2, 1], 0);
        ReservationEntry.Validate("Qty. to Handle (Base)", 0);
        ReservationEntry.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1, 1], 53);

        PurchaseHeader[1].Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader[1].Modify();
        PurchaseOrderNo := PurchaseHeader[1]."No.";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1, 1], 17);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[2, 1], 40);

        PurchaseOrderNo := PurchaseHeader[1]."No.";

        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        CreatePurchInvoice(PurchaseInvHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseInvLine, PurchaseInvHeader, PurchaseInvLine.Type::"Charge (Item)", ItemChargeNo, 1);

        PurchaseInvLine.Validate("Direct Unit Cost", 20);
        PurchaseInvLine.Modify();

        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptLine.FindLast();
        repeat
            CreateItemChargeAssignPurchFromReceipt(
              PurchaseInvLine, ItemChargeNo, Item[1]."No.", PurchRcptLine);
        until PurchRcptLine.Next() = 0;
        ItemChargeAssgntSCode.AssignItemCharges(PurchaseInvLine, 1, 1, ItemChargeAssgntSCode.AssignEquallyMenuText());
        LibraryPurchase.PostPurchaseDocument(PurchaseInvHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchReturnOrder()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Vendor: Record Vendor;
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Location: Record Location;
        Item: Record Item;
        ReasonCode: Record "Reason Code";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        PackageNo: Code[50];
    begin
        // Test Purchase Return Order with CD tracking.

        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);
        LibraryERM.CreateReasonCode(ReasonCode);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 6);

        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 4);
        PurchaseHeader.Validate("Reason Code", ReasonCode.Code);
        PurchaseHeader.Modify();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo, 24);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.Reset();
        PurchRcptHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchRcptHeader.FindFirst();

        LibraryPurchase.CreatePurchaseReturnOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Reason Code", ReasonCode.Code);
        PurchaseHeader.Modify();

        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::"Posted Receipt", PurchRcptHeader."No.", true, true);
        CopyPurchaseDocument.Run();

        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo, -24);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchReturnOrderWrongPackageTracking()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemTrackingCode: Record "Item Tracking Code";
        Vendor: Record Vendor;
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        ReasonCode: Record "Reason Code";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        PackageNoInfo: array[2] of Record "Package No. Information";
        PackageNo: array[2] of Code[30];
        i: Integer;
    begin
        Initialize();
        CreateForeignVendorAndLocation(Vendor, Location);
        LibraryERM.CreateReasonCode(ReasonCode);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 6);

        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[i], Item."No.", PackageNo[i]);
        end;

        CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code, PurchaseLine, Item."No.", UnitOfMeasure.Code, 4);
        PurchaseHeader.Validate("Reason Code", ReasonCode.Code);
        PurchaseHeader.Modify();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[2], 24);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.Reset();
        PurchRcptHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchRcptHeader.FindFirst();

        LibraryPurchase.CreatePurchaseReturnOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Reason Code", ReasonCode.Code);
        PurchaseHeader.Modify();

        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(
            "Purchase Document Type From"::"Posted Receipt", PurchRcptHeader."No.", true, true);
        CopyPurchaseDocument.Run();

        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();

        ReservationEntry.SetRange("Package No.", PackageNo[2]);
        ReservationEntry.FindLast();
        ReservationEntry.Validate("Package No.", PackageNo[1]);
        ReservationEntry.Modify();

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(ItemTrackingErr);
    end;

    local procedure CreateForeignVendorAndLocation(var Vendor: Record Vendor; var Location: Record Location)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency());
        Vendor.Modify(true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[10]; Locationcode: Code[30]; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[10]; UnitOfMeasureCode: Code[10]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, VendorNo, Locationcode);
        PurchaseHeader.Validate("Prices Including VAT", true);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, ItemNo, 20, Qty);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CheckPackageNoInfoInfo(ItemNo: Code[20]; PackageNo: Code[50]; Inventory: Decimal; Locationcode: Code[10]): Boolean
    var
        PackageNoInfo: Record "Package No. Information";
    begin
        PackageNoInfo.SetRange("Item No.", ItemNo);
        PackageNoInfo.SetRange("Package No.", PackageNo);
        PackageNoInfo.SetRange("Location Filter", Locationcode);
        Assert.IsTrue(PackageNoInfo.FindLast(), StrSubstNo(PackageNoInfoFoundErr, PackageNoInfo.TableCaption(), PackageNoInfo.GetFilters));

        PackageNoInfo.CalcFields(Inventory);

        Assert.AreEqual(Inventory, PackageNoInfo.Inventory, StrSubstNo(PackageNoInfoQtyErr, PackageNoInfo."Item No.", PackageNoInfo.GetFilters));
    end;

    local procedure CreatePurchInvoice(var PurchaseInvHeader: Record "Purchase Header"; VendorNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseInvHeader, PurchaseInvHeader."Document Type"::Invoice, VendorNo);
        PurchaseInvHeader.Validate("Vendor Invoice No.", PurchaseInvHeader."No.");
        PurchaseInvHeader.Validate("Location Code", LocationCode);
        PurchaseInvHeader.Modify();
    end;

    local procedure CreateItemChargeAssignPurchFromReceipt(PurchLine: Record "Purchase Line"; ItemChargeNo: Code[20]; ItemNo: Code[20]; PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        LineNo: Integer;
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchLine."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchLine."Document No.");
        ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchLine."Line No.");
        if ItemChargeAssignmentPurch.FindLast() then
            LineNo := ItemChargeAssignmentPurch."Line No."
        else
            LineNo := 0;

        ItemChargeAssignmentPurch.Init();
        ItemChargeAssignmentPurch.Validate("Document Type", PurchLine."Document Type");
        ItemChargeAssignmentPurch.Validate("Document No.", PurchLine."Document No.");
        ItemChargeAssignmentPurch.Validate("Document Line No.", PurchLine."Line No.");
        ItemChargeAssignmentPurch.Validate("Line No.", LineNo);
        ItemChargeAssignmentPurch.Validate("Item Charge No.", ItemChargeNo);
        ItemChargeAssignmentPurch.Validate("Item No.", ItemNo);
        ItemChargeAssignmentPurch.Validate("Applies-to Doc. Type", ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt);
        ItemChargeAssignmentPurch.Validate("Applies-to Doc. No.", PurchRcptLine."Document No.");
        ItemChargeAssignmentPurch.Validate("Applies-to Doc. Line No.", PurchRcptLine."Line No.");
        ItemChargeAssignmentPurch.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        ItemChargeAssignmentPurch.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DoYouWantToUndoMsg) = 0 then
            Error(IncorrConfirmDialogOpenedErr);

        Reply := true;
    end;
}

