codeunit 137264 "SCM Package Tracking Sales"
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
        LibraryReservation: Codeunit "Create Reserv. Entry";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        EntryType: Option " ",Sales,Purchase,Receipt;
        DocType: Option " ","Order","Credit Memo";
        isInitialized: Boolean;
        PackageNumberNotDefinedErr: Label 'You must assign a package number for';
        IncorrectConfirmDialogErr: Label 'Incorrect confirm dialog opened: %1', Comment = '%1 - Error message';
        FunctionCreateSpecMsg: Label 'This function create tracking specification from';
        DoYouWantToUndoMsg: Label 'Do you really want to undo';
        TestSerialTxt: Label 'TestSerialNo0';
        WrongQtyForItemErr: Label '%1 in the item tracking assigned to the document line for item %2 is currently %3. It must be %4.\\Check the assignment for serial number %5, lot number %6, package number %7.', Comment = '%1 - Qty. to Handle or Qty. to Invoice, %2 - Item No., %3 - actual value, %4 - expected value, %5 - Serial No., %6 - Lot No., %7 - Package No.';

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemPackage_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[3] of Code[50];
        SerialNo: array[10] of Code[50];
        Qty: Decimal;
    begin
        Initialize();
        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        Qty := LibraryRandom.RandInt(100);
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", Qty, 20);
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty, SerialNo, '', PackageNo);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate(), Location.Code, Item."No.", Qty);
        CreateSalesLineTracking(SalesLine, ReservationEntry, false, Qty, SerialNo, '', PackageNo);
        CreatePOSOReservation(SalesHeader, PurchaseHeader, Location.Code, Item."No.", Qty, '', PackageNo);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine, '', '', PackageNo[1], Qty, ReservationEntry."Reservation Status"::Reservation);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, '', PackageNo[1], Qty);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', PackageNo[1], -Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure Res1ItemPackage_POIR()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        PackageNo: array[3] of Code[50];
        SerialNo: array[10] of Code[50];
        Qty: array[3] of Decimal;
        QtyToReserve: Decimal;
        i: Integer;
    begin
        Initialize();
        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        QtyToReserve := 0;

        for i := 1 to ArrayLen(Qty) do begin
            Qty[i] := LibraryRandom.RandInt(10);
            if (Qty[i] < QtyToReserve) or (QtyToReserve = 0) then
                QtyToReserve := Qty[i]
        end;

        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.",
          Qty[EntryType::Purchase], LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty[EntryType::Purchase], SerialNo, '', PackageNo);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[EntryType::Receipt]);
        CreateItemReceiptLineTracking(InvtDocumentLine, ReservationEntry, false, Qty[EntryType::Receipt], SerialNo, '', PackageNo);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate(), Location.Code, Item."No.", Qty[EntryType::Sales]);
        CreateSalesLineTracking(SalesLine, ReservationEntry, false, Qty[EntryType::Sales], SerialNo, '', PackageNo);

        CreatePOSOReservation(SalesHeader, PurchaseHeader, Location.Code, Item."No.", QtyToReserve, '', PackageNo);
        CreateIRSOReservation(SalesHeader, InvtDocumentHeader, Location.Code, Item."No.", QtyToReserve, '', PackageNo);

        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine, SerialNo[1], '', PackageNo[1], QtyToReserve,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckInvtDocReservationEntry(InvtDocumentLine, SerialNo[1], '', PackageNo[1], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        SalesLine.Find();
        LibraryVariableStorage.Enqueue(PackageNo[1]);
        LibraryVariableStorage.Enqueue(SalesLine."Quantity (Base)");
        LibraryVariableStorage.Enqueue(SalesLine."Qty. to Ship (Base)");
        LibraryVariableStorage.Enqueue(SalesLine."Qty. to Invoice (Base)");
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, '', PackageNo[1], Qty[EntryType::Purchase]);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', PackageNo[1], -Qty[EntryType::Sales]);
        CheckILEs(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, '', PackageNo[1], Qty[EntryType::Receipt]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemPackageLot_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        SerialNo: array[10] of Code[50];
        LotNo: Code[50];
        Qty: Decimal;
    begin
        Initialize();

        InitScenario(Vendor, Customer, Item, Location, false, true, true);
        Qty := LibraryRandom.RandInt(100);
        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", Qty, 20);
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty, SerialNo, LotNo, PackageNo);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate(), Location.Code, Item."No.", Qty);
        CreateSalesLineTracking(SalesLine, ReservationEntry, false, Qty, SerialNo, LotNo, PackageNo);
        CreatePOSOReservation(SalesHeader, PurchaseHeader, Location.Code, Item."No.", 4, LotNo, PackageNo);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine, SerialNo[1], LotNo, PackageNo[1], 4,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, LotNo, PackageNo[1], Qty);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, LotNo, PackageNo[1], -Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemPackageLot_POIR()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        SerialNo: array[10] of Code[50];
        LotNo: Code[50];
        Qty: array[3] of Decimal;
        QtyToReserve: Decimal;
        i: Integer;
    begin
        Initialize();
        InitScenario(Vendor, Customer, Item, Location, false, true, true);
        QtyToReserve := 0;

        for i := 1 to ArrayLen(Qty) do begin
            Qty[i] := LibraryRandom.RandInt(100);
            if (Qty[i] < QtyToReserve) or (QtyToReserve = 0) then
                QtyToReserve := Qty[i];
        end;

        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", Qty[EntryType::Purchase], 20);
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty[EntryType::Purchase], SerialNo, LotNo, PackageNo);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[EntryType::Receipt]);
        CreateItemReceiptLineTracking(InvtDocumentLine, ReservationEntry, false, Qty[EntryType::Receipt], SerialNo, LotNo, PackageNo);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate(), Location.Code, Item."No.", Qty[EntryType::Sales]);
        CreateSalesLineTracking(SalesLine, ReservationEntry, false, Qty[EntryType::Sales], SerialNo, LotNo, PackageNo);

        CreatePOSOReservation(SalesHeader, PurchaseHeader, Location.Code, Item."No.", QtyToReserve, LotNo, PackageNo);
        CreateIRSOReservation(SalesHeader, InvtDocumentHeader, Location.Code, Item."No.", QtyToReserve, LotNo, PackageNo);

        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine, SerialNo[1], LotNo, PackageNo[1], QtyToReserve,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckInvtDocReservationEntry(InvtDocumentLine, SerialNo[1], LotNo, PackageNo[1], QtyToReserve,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, LotNo, PackageNo[1], Qty[EntryType::Purchase]);
        CheckILEs(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, LotNo, PackageNo[1], -Qty[EntryType::Sales]);
        CheckILEs(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, LotNo, PackageNo[1], Qty[EntryType::Receipt]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemPackageLotSerial_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        SerialNo: array[10] of Code[50];
        LotNo: Code[50];
        PurchaseQty: Decimal;
        SalesQty: Decimal;
        i: Integer;
    begin
        Initialize();

        InitScenario(Vendor, Customer, Item, Location, true, true, true);

        PurchaseQty := 7;
        SalesQty := 1;

        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", PurchaseQty, 20);
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, true, PurchaseQty, SerialNo, LotNo, PackageNo);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate(), Location.Code, Item."No.", SalesQty);
        CreateSalesLineTracking(SalesLine, ReservationEntry, true, SalesQty, SerialNo, LotNo, PackageNo);

        SalesLine.AutoReserve();

        for i := 1 to SalesQty do
            LibraryItemTracking.CheckPurchReservationEntry(
                PurchaseLine, SerialNo[i], LotNo, PackageNo[1], 1, "Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEsWithSerial(
            ItemLedgerEntry, "Item Ledger Entry Type"::Sale, Item."No.", Location.Code, SerialNo, LotNo, PackageNo[1], -SalesQty);
        CheckILEsWithSerial(
            ItemLedgerEntry, "Item Ledger Entry Type"::Purchase, Item."No.", Location.Code, SerialNo, LotNo, PackageNo[1], PurchaseQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemPackageLotSerial_POIR()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        PackageNo: array[3] of Code[50];
        SerialNo: array[20] of Code[20];
        LotNo: Code[50];
        Qty: array[3] of Decimal;
        i: Integer;
    begin
        Initialize();
        InitScenario(Vendor, Customer, Item, Location, true, true, true);
        AllowInvtDocReservation(true);

        Qty[EntryType::Sales] := 8;
        Qty[EntryType::Purchase] := 4;
        Qty[EntryType::Receipt] := 6;

        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", Qty[EntryType::Purchase], 20);
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, true, Qty[EntryType::Purchase], SerialNo, LotNo, PackageNo);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[EntryType::Receipt]);
        for i := 1 to Qty[EntryType::Receipt] do begin
            SerialNo[i + 4] := LibraryUtility.GenerateGUID();
            ItemTrackingSetup."Serial No." := SerialNo[i + 4];
            ItemTrackingSetup."Lot No." := LotNo;
            ItemTrackingSetup."Package No." := PackageNo[1];
            LibraryItemTracking.CreateItemReceiptItemTracking(ReservationEntry, InvtDocumentLine, ItemTrackingSetup, 1);
        end;

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate(), Location.Code, Item."No.", Qty[EntryType::Sales]);
        CreateSalesLineTracking(SalesLine, ReservationEntry, true, Qty[EntryType::Sales], SerialNo, LotNo, PackageNo);

        SalesLine.AutoReserve();

        for i := 1 to Qty[EntryType::Purchase] do
            LibraryItemTracking.CheckPurchReservationEntry(
              PurchaseLine, SerialNo[i], LotNo, PackageNo[1], 1, ReservationEntry."Reservation Status"::Reservation);
        for i := 1 to Qty[EntryType::Purchase] do
            LibraryItemTracking.CheckInvtDocReservationEntry(
              InvtDocumentLine, SerialNo[i + 4], LotNo, PackageNo[1], 1, ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        AllowInvtDocReservation(false);

        for i := 1 to Qty[EntryType::Sales] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[i], LotNo, PackageNo[1], -1);
        end;

        for i := 1 to Qty[EntryType::Purchase] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[i], LotNo, PackageNo[1], 1);
        end;

        for i := 1 to Qty[EntryType::Receipt] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[i + 4], LotNo, PackageNo[1], 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res1Item2Package_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        SerialNo: array[10] of Code[50];
        PurchaseQty: Decimal;
        SalesQty: Decimal;
    begin
        Initialize();
        InitScenario(Vendor, Customer, Item, Location, false, false, true);

        SalesQty := 2 * LibraryRandom.RandInt(5);
        PurchaseQty := SalesQty;

        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);
        PackageNo[2] := LibraryUtility.GenerateGUID();
        LibraryitemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[2]);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", PurchaseQty, LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking2(PurchaseLine, ReservationEntry, false, PurchaseQty, SerialNo, '', PackageNo);

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate(), Location.Code, Item."No.", SalesQty);
        CreateSalesLineTracking2(SalesLine, ReservationEntry, false, SalesQty, SerialNo, '', PackageNo);

        SalesLine.AutoReserve();

        LibraryItemTracking.CheckPurchReservationEntry(
            PurchaseLine, '', '', PackageNo[1], SalesQty / 2, ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(
            PurchaseLine, '', '', PackageNo[2], PurchaseQty / 2, ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify package 1
        CheckILEs(
            ItemLedgerEntry, "Item Ledger Entry Type"::Purchase, Item."No.", Location.Code, '', PackageNo[1], PurchaseQty / 2);
        CheckILEs(
            ItemLedgerEntry, "Item Ledger Entry Type"::Sale, Item."No.", Location.Code, '', PackageNo[1], -SalesQty / 2);
        // Verify package 2
        CheckILEs(
            ItemLedgerEntry, "Item Ledger Entry Type"::Purchase, Item."No.", Location.Code, '', PackageNo[2], PurchaseQty / 2);
        CheckILEs(
            ItemLedgerEntry, "Item Ledger Entry Type"::Sale, Item."No.", Location.Code, '', PackageNo[2], -SalesQty / 2);
    end;

    [Test]
    [HandlerFunctions('HndlConfirmTracking')]
    [Scope('OnPrem')]
    procedure Res1Item2Package_POIR()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ITemTrackingSetup: Record "Item Tracking Setup";
        PackageNo: array[3] of Code[50];
        Qty: array[3] of Decimal;
        i: Integer;
    begin
        Initialize();
        InitScenario(Vendor, Customer, Item, Location, false, false, true);

        AllowInvtDocReservation(true);

        for i := EntryType::Purchase to EntryType::Receipt do
            Qty[i] := LibraryRandom.RandInt(100);
        Qty[EntryType::Sales] := Qty[EntryType::Purchase] + Qty[EntryType::Receipt];

        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.",
          Qty[EntryType::Purchase], LibraryRandom.RandDec(100, 2));
        for i := 1 to 2 do
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[i], Qty[EntryType::Purchase] / 2);

        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
          InvtDocumentHeader, InvtDocumentLine, Item."No.", LibraryRandom.RandDec(100, 2), Qty[EntryType::Receipt]);
        for i := 1 to 2 do begin
            ITemTrackingSetup."Package No." := PackageNo[i];
            LibraryItemTracking.CreateItemReceiptItemTracking(ReservationEntry, InvtDocumentLine, ITemTrackingSetup, Qty[EntryType::Receipt] / 2);
        end;

        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate(), Location.Code, Item."No.", Qty[EntryType::Sales]);
        SalesLine.AutoReserve();
        LibraryItemTracking.CreateSalesTrackingFromReservation(SalesHeader, false);

        for i := 1 to 2 do begin
            LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine, '', '', PackageNo[i], Qty[EntryType::Purchase] / 2,
              ReservationEntry."Reservation Status"::Reservation);
            LibraryItemTracking.CheckInvtDocReservationEntry(InvtDocumentLine, '', '', PackageNo[i], Qty[EntryType::Receipt] / 2,
              ReservationEntry."Reservation Status"::Reservation);
        end;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        AllowInvtDocReservation(false);

        for i := 1 to 2 do begin
            CheckILEs(
              ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Location.Code, '', PackageNo[i], Qty[EntryType::Purchase] / 2);
            CheckILEs(
              ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, '', PackageNo[i], Qty[EntryType::Receipt] / 2);
            CheckILEs(
              ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item."No.", Location.Code, '', PackageNo[1], -Qty[EntryType::Sales] / 2);
        end;
    end;


    [Test]
    [Scope('OnPrem')]
    procedure Res1ItemLot_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        Qty: array[2] of Decimal;
    begin
        Initialize();

        InitScenario(Vendor, Customer, Item, Location, false, true, true);

        Qty[EntryType::Purchase] := LibraryRandom.RandInt(10);
        Qty[EntryType::Sales] := Qty[EntryType::Purchase];
        LotNo := LibraryUtility.GenerateGUID();

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", Qty[EntryType::Purchase], 20);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo, '', Qty[EntryType::Purchase]);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", WorkDate(), Location.Code, Item."No.", Qty[EntryType::Sales]);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo, '', Qty[EntryType::Sales]);
        SalesLine.AutoReserve();

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(PackageNumberNotDefinedErr);

        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(PackageNumberNotDefinedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemPackage_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[3] of Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        PostingDate: Date;
    begin
        Initialize();
        InitComplexScenario(Vendor, Customer, Item, Location, false, false, true);

        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[2]."No.", PackageNo[1]);
        PackageNo[2] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[2], Item[1]."No.", PackageNo[2]);
        PackageNo[3] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[3], Item[2]."No.", PackageNo[3]);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[2], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', '', PackageNo[3], 3);

        PostingDate := CalcDate('<+5D>', WorkDate());
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', '', PackageNo[2], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', '', PackageNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', PackageNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', PackageNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', PackageNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', PackageNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[1]."No.", Location.Code, '', PackageNo[1], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[1]."No.", Location.Code, '', PackageNo[2], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", Location.Code, '', PackageNo[1], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", Location.Code, '', PackageNo[3], 3);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[1]."No.", Location.Code, '', PackageNo[1], -2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[1]."No.", Location.Code, '', PackageNo[2], -1);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[2]."No.", Location.Code, '', PackageNo[1], -2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[2]."No.", Location.Code, '', PackageNo[3], -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemPackageLot_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[3] of Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        LotNo: Code[50];
        PostingDate: Date;
    begin
        Initialize();

        InitComplexScenario(Vendor, Customer, Item, Location, true, false, true);
        LotNo := LibraryUtility.GenerateGUID();

        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[1]."No.", PackageNo[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[2]."No.", PackageNo[1]);
        PackageNo[2] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[2], Item[1]."No.", PackageNo[2]);
        PackageNo[3] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[3], Item[2]."No.", PackageNo[3]);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', LotNo, PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', LotNo, PackageNo[2], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', LotNo, PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', LotNo, PackageNo[3], 3);

        PostingDate := CalcDate('<+5D>', WorkDate());
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', LotNo, PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', LotNo, PackageNo[2], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', LotNo, PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', LotNo, PackageNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', LotNo, PackageNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', LotNo, PackageNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], '', LotNo, PackageNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], '', LotNo, PackageNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[1]."No.", Location.Code, LotNo, PackageNo[1], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[1]."No.", Location.Code, LotNo, PackageNo[2], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", Location.Code, LotNo, PackageNo[1], 2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", Location.Code, LotNo, PackageNo[3], 3);

        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[1]."No.", Location.Code, LotNo, PackageNo[1], -2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[1]."No.", Location.Code, LotNo, PackageNo[2], -1);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[2]."No.", Location.Code, LotNo, PackageNo[1], -2);
        CheckILEs(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, Item[2]."No.", Location.Code, LotNo, PackageNo[3], -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemPackageLotSerial_PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[3] of Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        SerialNo: array[10] of Code[50];
        LotNo: Code[50];
        PostingDate: Date;
        j: Integer;
    begin
        Initialize();

        InitComplexScenario(Vendor, Customer, Item, Location, true, true, true);

        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[1]."No.", PackageNo[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[2]."No.", PackageNo[1]);
        PackageNo[2] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[2], Item[1]."No.", PackageNo[2]);
        PackageNo[3] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[3], Item[2]."No.", PackageNo[3]);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);

        for j := 1 to 2 do begin
            SerialNo[j] := LibraryUtility.GenerateGUID() + Format(j);
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], SerialNo[j],
              LotNo, PackageNo[1], 1);
        end;
        for j := 1 to 2 do begin
            SerialNo[j + 2] := LibraryUtility.GenerateGUID() + Format(j + 2);
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], SerialNo[j + 2],
              LotNo, PackageNo[2], 1);
        end;
        for j := 1 to 2 do begin
            SerialNo[j + 4] := LibraryUtility.GenerateGUID() + Format(j + 4);
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], SerialNo[j + 4],
              LotNo, PackageNo[1], 1);
        end;
        for j := 1 to 3 do begin
            SerialNo[j + 6] := LibraryUtility.GenerateGUID() + Format(j + 6);
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], SerialNo[j + 6],
              LotNo, PackageNo[3], 1);
        end;

        PostingDate := CalcDate('<+5D>', WorkDate());
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        for j := 1 to 2 do
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], SerialNo[j],
              LotNo, PackageNo[1], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], SerialNo[3],
          LotNo, PackageNo[2], 1);
        for j := 1 to 2 do
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], SerialNo[j + 4],
              LotNo, PackageNo[1], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], SerialNo[7],
          LotNo, PackageNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        for j := 1 to 2 do
            LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], SerialNo[j], LotNo, PackageNo[1], 1,
              ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], SerialNo[3], LotNo, PackageNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        for j := 1 to 2 do
            LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], SerialNo[j + 4], LotNo, PackageNo[1], 1,
              ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], SerialNo[7], LotNo, PackageNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j], LotNo, PackageNo[1], -1);
        end;
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[3], LotNo, PackageNo[2], -1);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 4], LotNo, PackageNo[1], -1);
        end;
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[7], LotNo, PackageNo[3], -1);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j], LotNo, PackageNo[1], 1);
        end;
        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j + 2], LotNo, PackageNo[2], 1);
        end;
        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 4], LotNo, PackageNo[1], 1);
        end;
        for j := 1 to 3 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 6], LotNo, PackageNo[3], 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemPackage_2PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[3] of Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        PostingDate: Date;
    begin
        Initialize();

        InitComplexScenario(Vendor, Customer, Item, Location, false, false, true);

        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[1]."No.", PackageNo[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[2]."No.", PackageNo[1]);
        PackageNo[2] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[2], Item[1]."No.", PackageNo[2]);
        PackageNo[3] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[3], Item[2]."No.", PackageNo[3]);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[2], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', '', PackageNo[3], 3);

        PostingDate := CalcDate('<+5D>', WorkDate());
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', '', PackageNo[2], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', '', PackageNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', PackageNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', PackageNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', PackageNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', PackageNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[2], -1);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[3], -1);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[2], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[1], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[3], 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemPackageLot_2PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[3] of Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        LotNo: Code[50];
        PostingDate: Date;
    begin
        Initialize();

        InitComplexScenario(
          Vendor, Customer, Item, Location, true, false, true);

        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[1]."No.", PackageNo[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[2]."No.", PackageNo[1]);
        PackageNo[2] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[2], Item[1]."No.", PackageNo[2]);
        PackageNo[3] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[3], Item[2]."No.", PackageNo[3]);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Posting Date", WorkDate());
        PurchaseHeader[1].Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[1], PurchaseHeader[1], Item[1]."No.", 20, 4);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[2], Vendor."No.", Location.Code);
        PurchaseHeader[2].Validate("Posting Date", WorkDate());
        PurchaseHeader[2].Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[2], PurchaseHeader[2], Item[2]."No.", 30, 5);

        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', LotNo, PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', LotNo, PackageNo[2], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', LotNo, PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', LotNo, PackageNo[3], 3);

        PostingDate := CalcDate('<+5D>', WorkDate());
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', LotNo, PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', LotNo, PackageNo[2], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', LotNo, PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', LotNo, PackageNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', LotNo, PackageNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', LotNo, PackageNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], '', LotNo, PackageNo[1], 2,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], '', LotNo, PackageNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo, PackageNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo, PackageNo[2], -1);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo, PackageNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo, PackageNo[3], -1);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo, PackageNo[1], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', LotNo, PackageNo[2], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo, PackageNo[1], 2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', LotNo, PackageNo[3], 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Res2ItemPackageLotSerial_2PO()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[3] of Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        SerialNo: array[10] of Code[50];
        LotNo: Code[50];
        PostingDate: Date;
        j: Integer;
    begin

        Initialize();

        InitComplexScenario(Vendor, Customer, Item, Location, true, true, true);
        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[1]."No.", PackageNo[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[2]."No.", PackageNo[1]);
        PackageNo[2] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[2], Item[1]."No.", PackageNo[2]);
        PackageNo[3] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[3], Item[2]."No.", PackageNo[3]);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[1], Vendor."No.", Location.Code);
        PurchaseHeader[1].Validate("Posting Date", WorkDate());
        PurchaseHeader[1].Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[1], PurchaseHeader[1], Item[1]."No.", 20, 4);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader[2], Vendor."No.", Location.Code);
        PurchaseHeader[2].Validate("Posting Date", WorkDate());
        PurchaseHeader[2].Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[2], PurchaseHeader[2], Item[2]."No.", 30, 5);

        for j := 1 to 2 do begin
            SerialNo[j] := LibraryUtility.GenerateGUID() + Format(j);
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], SerialNo[j], LotNo, PackageNo[1], 1);
        end;
        for j := 1 to 2 do begin
            SerialNo[j + 2] := LibraryUtility.GenerateGUID() + Format(j + 2);
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], SerialNo[j + 2], LotNo, PackageNo[2], 1);
        end;
        for j := 1 to 2 do begin
            SerialNo[j + 4] := LibraryUtility.GenerateGUID() + Format(j + 4);
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], SerialNo[j + 4], LotNo, PackageNo[1], 1);
        end;
        for j := 1 to 3 do begin
            SerialNo[j + 6] := LibraryUtility.GenerateGUID() + Format(j + 6);
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], SerialNo[j + 6], LotNo, PackageNo[3], 1);
        end;

        PostingDate := CalcDate('<+5D>', WorkDate());
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        for j := 1 to 2 do
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], SerialNo[j],
              LotNo, PackageNo[1], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], SerialNo[3],
          LotNo, PackageNo[2], 1);
        for j := 1 to 2 do
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], SerialNo[j + 4],
              LotNo, PackageNo[1], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], SerialNo[7],
          LotNo, PackageNo[3], 1);

        SalesLine[1].AutoReserve();
        SalesLine[2].AutoReserve();

        for j := 1 to 2 do
            LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], SerialNo[j], LotNo, PackageNo[1], 1,
              ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], SerialNo[3], LotNo, PackageNo[2], 1,
          ReservationEntry."Reservation Status"::Reservation);
        for j := 1 to 2 do
            LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], SerialNo[j + 4], LotNo, PackageNo[1], 1,
              ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], SerialNo[7], LotNo, PackageNo[3], 1,
          ReservationEntry."Reservation Status"::Reservation);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j], LotNo, PackageNo[1], -1);
        end;
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[3], LotNo, PackageNo[2], -1);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 4], LotNo, PackageNo[1], -1);
        end;
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[7], LotNo, PackageNo[3], -1);

        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j], LotNo, PackageNo[1], 1);
        end;
        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, SerialNo[j + 2], LotNo, PackageNo[2], 1);
        end;
        for j := 1 to 2 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 4], LotNo, PackageNo[1], 1);
        end;
        for j := 1 to 3 do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, SerialNo[j + 6], LotNo, PackageNo[3], 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPackage_POCM()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SerialNo: array[10] of Code[50];
        PackageNo: array[3] of Code[50];
        Qty: array[2] of Decimal;
    begin
        Initialize();

        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        Qty[DocType::Order] := 3 * LibraryRandom.RandInt(10);
        Qty[DocType::"Credit Memo"] := Round(LibraryRandom.RandInt(10) / 3, 1);

        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.",
          Qty[DocType::Order], LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty[DocType::Order], SerialNo, '', PackageNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryPurchase.CreatePurchaseCreditMemoWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
          PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty[DocType::"Credit Memo"]);
        CreateCreditMemoTracking(PurchaseLine, ReservationEntry, false, Qty[DocType::"Credit Memo"], SerialNo, '', PackageNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
        LibraryItemTracking.CheckLastItemLedgerEntry(
          ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[1], -Qty[DocType::"Credit Memo"]);

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[1], Qty[DocType::Order]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPackageLot_POCM()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        SerialNo: array[10] of Code[50];
        LotNo: Code[50];
        PackageNo: array[3] of Code[50];
        Qty: array[2] of Decimal;
    begin
        Initialize();

        InitScenario(Vendor, Customer, Item, Location, false, true, true);

        Qty[DocType::Order] := 4;
        Qty[DocType::"Credit Memo"] := 2;

        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.",
          Qty[DocType::Order], LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty[DocType::Order], SerialNo, LotNo, PackageNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryPurchase.CreatePurchaseCreditMemoWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
          PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty[DocType::"Credit Memo"]);
        CreateCreditMemoTracking(PurchaseLine, ReservationEntry, false, Qty[DocType::"Credit Memo"], SerialNo, LotNo, PackageNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
        LibraryItemTracking.CheckLastItemLedgerEntry(
          ItemLedgerEntry, Item."No.", Location.Code, SerialNo[1], LotNo, PackageNo[1], -Qty[DocType::"Credit Memo"]);

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryItemTracking.CheckLastItemLedgerEntry(
          ItemLedgerEntry, Item."No.", Location.Code, SerialNo[1], LotNo, PackageNo[1], Qty[DocType::Order]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPackageLotSerial_POCM()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        SerialNo: array[10] of Code[50];
        LotNo: Code[50];
        PackageNo: array[3] of Code[50];
        Qty: array[2] of Decimal;
        j: Integer;
    begin
        Initialize();

        InitScenario(Vendor, Customer, Item, Location, true, true, true);
        Qty[DocType::Order] := 3 * LibraryRandom.RandInt(10);
        Qty[DocType::"Credit Memo"] := Round(LibraryRandom.RandInt(10) / 3, 1);

        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.",
          Qty[DocType::Order], LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, true, Qty[DocType::Order], SerialNo, LotNo, PackageNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryPurchase.CreatePurchaseCreditMemoWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
          PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty[DocType::"Credit Memo"]);
        CreateCreditMemoTracking(PurchaseLine, ReservationEntry, true, Qty[DocType::"Credit Memo"], SerialNo, LotNo, PackageNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        for j := 1 to Qty[DocType::"Credit Memo"] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, PackageNo[1], -1);
        end;

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        for j := 1 to Qty[DocType::Order] do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, PackageNo[1], 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPackage_POCMCopy()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PurchInvHeader: Record "Purch. Inv. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        SerialNo: array[10] of Code[50];
        PackageNo: array[3] of Code[50];
        Qty: Decimal;
    begin
        Initialize();

        InitScenario(Vendor, Customer, Item, Location, false, false, true);
        Qty := 4;

        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", Qty, LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty, SerialNo, '', PackageNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Copying
        PurchInvHeader.SetCurrentKey("Buy-from Vendor No.");
        PurchInvHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst();

        LibraryPurchase.CreatePurchaseCreditMemoWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::"Posted Invoice", PurchInvHeader."No.", true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();

        PurchaseHeader.Find();
        PurchaseHeader.Validate(Correction, true);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();

        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty, SerialNo, '', PackageNo);
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[1], -Qty);

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[1], Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPackageLot_POCMCopy()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PurchInvHeader: Record "Purch. Inv. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        SerialNo: array[10] of Code[50];
        LotNo: Code[50];
        PackageNo: array[3] of Code[50];
        Qty: Decimal;
    begin
        Initialize();

        InitScenario(Vendor, Customer, Item, Location, false, true, true);

        Qty := 4;
        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", Qty, LibraryRandom.RandDec(100, 2));
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty, SerialNo, LotNo, PackageNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetCurrentKey("Buy-from Vendor No.");
        PurchInvHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst();

        LibraryPurchase.CreatePurchaseCreditMemoWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::"Posted Invoice", PurchInvHeader."No.", true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();

        PurchaseHeader.Find();
        PurchaseHeader.Validate(Correction, true);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, false, Qty, SerialNo, LotNo, PackageNo);
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', LotNo, PackageNo[1], -Qty);

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', LotNo, PackageNo[1], Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneItemPackageLotSerialPurchOrderCrMemoCopy()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        SerialNo: array[10] of Code[50];
        LotNo: Code[50];
        PackageNo: array[3] of Code[50];
        QtyPO: Decimal;
        j: Integer;
    begin
        Initialize();
        InitScenario(Vendor, Customer, Item, Location, true, true, true);

        QtyPO := 4;
        LotNo := LibraryUtility.GenerateGUID();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", WorkDate(), Location.Code, Item."No.", QtyPO, 20);
        CreatePurchLineTracking(PurchaseLine, ReservationEntry, true, QtyPO, SerialNo, LotNo, PackageNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetCurrentKey("Buy-from Vendor No.");
        PurchInvHeader.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst();

        LibraryPurchase.CreatePurchaseCreditMemoWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::"Posted Invoice", PurchInvHeader."No.", true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();

        PurchaseHeader.Find();
        PurchaseHeader.Validate(Correction, true);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        FindLastReturnShipment(ReturnShipmentHeader, Vendor."No.");
        for j := 1 to QtyPO do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            ItemLedgerEntry.SetRange("Document No.", ReturnShipmentHeader."No.");
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, PackageNo[1], -1);
        end;

        FindLastPurchReceipt(PurchRcptHeader, Vendor."No.");
        for j := 1 to QtyPO do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            ItemLedgerEntry.SetRange("Document No.", PurchRcptHeader."No.");
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, SerialNo[j], LotNo, PackageNo[1], 1);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,HndlConfirmTracking')]
    [Scope('OnPrem')]
    procedure Res1ItemPackage_PartShip()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[3] of Record "Package No. Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[3] of Code[50];
        PostingDate: Date;
        i: Integer;
    begin
        Initialize();

        InitScenario(Vendor, Customer, Item, Location, false, false, true);

        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item."No.", PackageNo[1]);
        PackageNo[2] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[2], Item."No.", PackageNo[2]);
        PackageNo[3] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[3], Item."No.", PackageNo[3]);

        CreatePurchaseOrder(PurchaseHeader[1], PurchaseLine[1], Vendor."No.", WorkDate(), Location.Code, Item."No.", 6, 20);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[1], 3);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[2], 3);

        CreatePurchaseOrder(PurchaseHeader[2], PurchaseLine[2], Vendor."No.", WorkDate(), Location.Code, Item."No.", 4, 20);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', '', PackageNo[3], 4);

        PostingDate := CalcDate('<+5D>', WorkDate());
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, Item."No.", 30, 10);
        SalesLine.Validate("Planned Delivery Date", PostingDate);
        SalesLine.Validate("Qty. to Ship", 7);
        SalesLine.Modify();
        SalesLine.AutoReserve();

        LibraryItemTracking.CreateSalesTrackingFromReservation(SalesHeader, false);

        LibraryVariableStorage.Enqueue(PackageNo[1]);
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(0);
        SalesLine.Find();
        SalesLine.OpenItemTrackingLines();

        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', PackageNo[1], 3,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[1], '', '', PackageNo[2], 3,
          ReservationEntry."Reservation Status"::Reservation);
        LibraryItemTracking.CheckPurchReservationEntry(PurchaseLine[2], '', '', PackageNo[3], 4,
          ReservationEntry."Reservation Status"::Reservation);

        for i := 1 to ArrayLen(PurchaseHeader) do
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader[i], true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[3], -4);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[2], -3);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[1], 3);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[2], 3);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[3], 4);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "2ItemSO_UndoShip"()
    var
        ItemChargeAssgntSales: array[2] of Record "Item Charge Assignment (Sales)";
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: array[2] of Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: array[3] of Record "Package No. Information";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemChargeAssgntSCode: Codeunit "Item Charge Assgnt. (Sales)";
        PackageNo: array[3] of Code[50];
        SalesOrderNo: Code[20];
        ItemChargeNo: Code[20];
        PostingDate: Date;
    begin
        if true then
            exit;

        Initialize();

        InitComplexScenario(Vendor, Customer, Item, Location, false, false, true);

        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[1]."No.", PackageNo[1]);
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[1], Item[2]."No.", PackageNo[1]);
        PackageNo[2] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[2], Item[1]."No.", PackageNo[2]);
        PackageNo[3] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo[3], Item[2]."No.", PackageNo[3]);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[1], PurchaseHeader, Item[1]."No.", 20, 4);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine[2], PurchaseHeader, Item[2]."No.", 30, 5);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[1], '', '', PackageNo[2], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine[2], '', '', PackageNo[3], 3);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PostingDate := CalcDate('<+5D>', WorkDate());
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[1], SalesHeader, Item[1]."No.", 30, 3);
        SalesLine[1].Validate("Planned Delivery Date", PostingDate);
        SalesLine[1].Modify();
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine[2], SalesHeader, Item[2]."No.", 40, 3);
        SalesLine[2].Validate("Planned Delivery Date", PostingDate);
        SalesLine[2].Modify();

        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[1], '', '', PackageNo[2], 1);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', '', PackageNo[1], 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine[2], '', '', PackageNo[3], 1);

        SalesOrderNo := SalesHeader."No.";

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[1]."No.", Location.Code, '', '', PackageNo[2], -1);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[1], -2);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item[2]."No.", Location.Code, '', '', PackageNo[3], -1);

        SalesShipmentHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
#pragma warning disable AA0210
        SalesShipmentLine.SetRange("No.", Item[1]."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
#pragma warning restore AA0210
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.SetRecFilter();
        CODEUNIT.Run(CODEUNIT::"Undo Sales Shipment Line", SalesShipmentLine);
        SalesShipmentLine.Reset();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
#pragma warning disable AA0210        
        SalesShipmentLine.SetRange("No.", Item[2]."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
#pragma warning restore AA0210        
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.SetRecFilter();
        CODEUNIT.Run(CODEUNIT::"Undo Sales Shipment Line", SalesShipmentLine);

        SalesHeader.SetRange("No.", SalesOrderNo);
        SalesHeader.FindFirst();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        SalesHeader.Reset();
        SalesShipmentLine.Reset();
        SalesShipmentHeader.Reset();

        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::"Charge (Item)", ItemChargeNo, 1);
        SalesLine[1].Validate("Unit Price", 100);
        SalesLine[1].Modify();

        SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
        SalesShipmentHeader.FindFirst();

        ItemChargeAssgntSales[1].Init();
        ItemChargeAssgntSales[1].Validate("Document Type", ItemChargeAssgntSales[1]."Document Type"::Order);
        ItemChargeAssgntSales[1].Validate("Document No.", SalesOrderNo);
        ItemChargeAssgntSales[1].Validate("Document Line No.", 10000);
        ItemChargeAssgntSales[1].Validate("Line No.", 10000);
        ItemChargeAssgntSales[1].Insert(true);
        ItemChargeAssgntSales[1].Validate("Item Charge No.", ItemChargeNo);
        ItemChargeAssgntSales[1].Validate("Item No.", Item[1]."No.");
        ItemChargeAssgntSales[1].Validate("Applies-to Doc. Type", ItemChargeAssgntSales[1]."Applies-to Doc. Type"::Shipment);
        ItemChargeAssgntSales[1].Validate("Applies-to Doc. No.", SalesShipmentHeader."No.");
        ItemChargeAssgntSales[1].Validate("Applies-to Doc. Line No.", 10000);
        ItemChargeAssgntSales[1].Validate("Unit Cost", 100);
        ItemChargeAssgntSales[1].Modify();

        ItemChargeAssgntSales[2].Init();
        ItemChargeAssgntSales[2].Validate("Document Type", ItemChargeAssgntSales[1]."Document Type"::Order);
        ItemChargeAssgntSales[2].Validate("Document No.", SalesOrderNo);
        ItemChargeAssgntSales[2].Validate("Document Line No.", 10000);
        ItemChargeAssgntSales[2].Validate("Line No.", 20000);
        ItemChargeAssgntSales[2].Insert(true);
        ItemChargeAssgntSales[2].Validate("Item Charge No.", ItemChargeNo);
        ItemChargeAssgntSales[2].Validate("Item No.", Item[2]."No.");
        ItemChargeAssgntSales[2].Validate("Applies-to Doc. Type",
          ItemChargeAssgntSales[2]."Applies-to Doc. Type"::Shipment);
        ItemChargeAssgntSales[2].Validate("Applies-to Doc. No.", SalesShipmentHeader."No.");
        ItemChargeAssgntSales[2].Validate("Applies-to Doc. Line No.", 20000);
        ItemChargeAssgntSales[2].Validate("Unit Cost", 100);
        ItemChargeAssgntSales[2].Modify();

        ItemChargeAssgntSCode.AssignItemCharges(SalesLine[1], 1, 1, ItemChargeAssgntSCode.AssignEquallyMenuText());

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPartialSalesOrderShippingWithPackage()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        NoSeries: Codeunit "No. Series";
        PackageNo: array[2] of Code[50];
        i: Integer;
    begin
        // [SCENARIO 449039] Check partial sales order shipping with package number.
        Initialize();

        // [GIVEN] Create an item with item tracking code with package number tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        // [GIVEN] Add two packages to inventory
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 20, '');
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', '', PackageNo[1], 10);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', '', PackageNo[2], 10);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJournalLine);

        // [GIVEN] Create a sales order with item tracking
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 15);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', '', PackageNo[1], 8);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', '', PackageNo[2], 7);

        // [GIVEN] Decrease Qty. to Ship to 10
        SalesLine.Validate("Qty. to Ship", 10);
        SalesLine.Modify();
        Commit();

        // [WHEN] Post the sales order with package number and quantity to ship greater than the quantity to handle
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Cannot post the sales order with package number and quantity to ship greater than the quantity to handle
        Assert.ExpectedError(StrSubstNo(WrongQtyForItemErr,
            ReservationEntry.FieldCaption("Qty. to Handle (Base)"), Item."No.", 15, 10, '', '', PackageNo[2]));

        // [GIVEN] Modify the quantity to handle of Package[2] to 2
        ReservationEntry.Validate("Qty. to Handle (Base)", 2);
        ReservationEntry.Modify(true);

        // [WHEN] Post the sales order with package number and quantity to ship equal than the quantity to handle
        SalesHeader.Find('='); // Refresh the record
        SalesHeader."Shipping No." := NoSeries.GetNextNo(SalesHeader."Shipping No. Series", SalesHeader."Posting Date");
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Validate the quantity posted
        SalesLine.Find('='); // Refresh the record
        SalesLine.TestField("Qty. Shipped (Base)", 10);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', '', PackageNo[1], -8);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', '', PackageNo[2], -2);

        // [WHEN] Post the remaining quantity
        SalesHeader.Find('='); // Refresh the record
        SalesHeader."Shipping No." := NoSeries.GetNextNo(SalesHeader."Shipping No. Series", SalesHeader."Posting Date");
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Validate the quantity posted
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', '', PackageNo[1], -8);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', '', PackageNo[2], -5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPartialSalesOrderShippingWithPackageAndLot()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        NoSeries: Codeunit "No. Series";
        PackageNo: Code[50];
        LotNo: array[3] of Code[50];
        i: Integer;
    begin
        // [SCENARIO 449039] Check partial sales order shipping with package number and lot number.
        Initialize();

        // [GIVEN] Create an item with item tracking code with package number and lot number tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        PackageNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo);
        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Add three lots with package to inventory
        LibraryInventory.CreateItemJnlLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, '');
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[1], PackageNo, 4);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[2], PackageNo, 3);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJnlLine, '', LotNo[3], PackageNo, 3);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        // [GIVEN] Create a sales order with item tracking
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo[1], PackageNo, 4);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo[2], PackageNo, 3);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo[3], PackageNo, 3);

        // [GIVEN] Decrease Qty. to Ship to 9
        SalesLine.Validate("Qty. to Ship", 9);
        SalesLine.Modify();
        Commit();

        // [WHEN] Post the sales order with package number and quantity to ship greater than the quantity to handle
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Cannot post the sales order with package number and quantity to ship greater than the quantity to handle
        Assert.ExpectedError(StrSubstNo(WrongQtyForItemErr,
            ReservationEntry.FieldCaption("Qty. to Handle (Base)"), Item."No.", 10, 9, '', LotNo[3], PackageNo));

        // [GIVEN] Modify the quantity to handle of Package[2] to 2
        ReservationEntry.Validate("Qty. to Handle (Base)", 2);
        ReservationEntry.Modify(true);

        // [WHEN] Post the sales order with package number and quantity to ship equal than the quantity to handle
        SalesHeader.Find('='); // Refresh the record
        SalesHeader."Shipping No." := NoSeries.GetNextNo(SalesHeader."Shipping No. Series", SalesHeader."Posting Date");
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Validate the quantity posted
        SalesLine.Find('='); // Refresh the record
        SalesLine.TestField("Qty. Shipped (Base)", 9);

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', LotNo[1], PackageNo, -4);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', LotNo[2], PackageNo, -3);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', LotNo[3], PackageNo, -2);

        // [WHEN] Post the remaining quantity
        SalesHeader.Find('='); // Refresh the record
        SalesHeader."Shipping No." := NoSeries.GetNextNo(SalesHeader."Shipping No. Series", SalesHeader."Posting Date");
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Validate the quantity posted
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', '', LotNo[3], PackageNo, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPartialSalesOrderShippingWithPackageAndSerialNo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        NoSeries: Codeunit "No. Series";
        PackageNo: array[3] of Code[50];
        SerialNo: array[3] of Code[50];
        i: Integer;
    begin
        // [SCENARIO 449039] Check partial sales order shipping with package number and serial number.
        Initialize();

        // [GIVEN] Create an item with item tracking code with package number and serial number tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            SerialNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[i]);
        end;

        // [GIVEN] Add three serial number with different packages to inventory
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, "Item Ledger Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 3, '');
        for i := 1 to ArrayLen(SerialNo) do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, SerialNo[i], '', PackageNo[i], 1);
        LibraryInventory.PostItemJnlLineWithCheck(ItemJournalLine);

        // [GIVEN] Create a sales order with item tracking
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 3);
        for i := 1 to ArrayLen(SerialNo) do
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, SerialNo[i], '', PackageNo[i], 1);

        // [GIVEN] Decrease Qty. to Ship to 2
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Modify();
        Commit();

        // [WHEN] Post the sales order with package number and quantity to ship greater than the quantity to handle
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Cannot post the sales order with package number and quantity to ship greater than the quantity to handle
        Assert.ExpectedError(StrSubstNo(WrongQtyForItemErr,
            ReservationEntry.FieldCaption("Qty. to Handle (Base)"), Item."No.", 3, 2, SerialNo[3], '', PackageNo[3]));

        // [WHEN] Remove latest item tracking line
        ReservationEntry.Delete(true);

        // [WHEN] Post the sales order with package number and quantity to ship equal than the quantity to handle
        SalesHeader.Find('='); // Refresh the record
        SalesHeader."Shipping No." := NoSeries.GetNextNo(SalesHeader."Shipping No. Series", SalesHeader."Posting Date");
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Valiate the quantity in the locations
        for i := 1 to (ArrayLen(SerialNo) - 1) do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', SerialNo[i], '', PackageNo[i], -1);
        end;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Package Tracking Sales");

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Sales");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateLocalData();

        LibraryPurchase.SetReturnOrderNoSeriesInSetup();
        SetupInvtDocNosInInvSetup();
        SetReturnShipmentOnCreditMemo();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Sales");
    end;

    local procedure SetupInvtDocNosInInvSetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Invt. Receipt Nos.", CreateNoSeries());
        if InventorySetup."Posted Invt. Receipt Nos." = '' then
            InventorySetup.Validate("Posted Invt. Receipt Nos.", CreateNoSeries());
        if InventorySetup."Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Invt. Shipment Nos.", CreateNoSeries());
        if InventorySetup."Posted Invt. Shipment Nos." = '' then
            InventorySetup.Validate("Posted Invt. Shipment Nos.", CreateNoSeries());
        InventorySetup.Modify(true);
    end;

    local procedure SetReturnShipmentOnCreditMemo()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        if not PurchSetup."Return Shipment on Credit Memo" then begin
            PurchSetup."Return Shipment on Credit Memo" := true;
            PurchSetup.Modify();
        end;
    end;

    local procedure InitScenario(var Vendor: Record Vendor; var Customer: Record Customer; var Item: Record Item; var Location: Record Location; NewSerialTracking: Boolean; NewLotTracking: Boolean; NewPackageTracking: Boolean)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ItemTrackingSetup."Serial No. Required" := NewSerialTracking;
        ItemTrackingSetup."Lot No. Required" := NewLotTracking;
        ItemTrackingSetup."Package No. Required" := NewPackageTracking;
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, ItemTrackingSetup);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 20);
    end;

    local procedure InitComplexScenario(var Vendor: Record Vendor; var Customer: Record Customer; var Item: array[2] of Record Item; var Location: Record Location; NewLotTracking: Boolean; NewSerialTracking: Boolean; NewPackageTracking: Boolean)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ItemTrackingSetup."Serial No. Required" := NewSerialTracking;
        ItemTrackingSetup."Lot No. Required" := NewLotTracking;
        ItemTrackingSetup."Package No. Required" := NewPackageTracking;
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, ItemTrackingSetup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item[1], ItemTrackingCode);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item[1]."No.", UnitOfMeasure.Code, 20);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item[2], ItemTrackingCode);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item[2]."No.", UnitOfMeasure.Code, 20);
    end;

    local procedure UpdateSerialNos(var SerialNo: array[10] of Code[50]; i: Integer)
    begin
        if i = 1 then
            SerialNo[i] := TestSerialTxt
        else
            SerialNo[i] := IncStr(SerialNo[i - 1]);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; PostingDate: Date; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ReasonCode: Record "Reason Code";
    begin
        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, VendorNo, LocationCode);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        LibraryERM.CreateReasonCode(ReasonCode);
        PurchaseHeader.Validate("Reason Code", ReasonCode.Code);
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, ItemNo, UnitCost, Qty);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; PostingDate: Date; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        NewDate: Date;
    begin
        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, CustomerNo, LocationCode);
        NewDate := CalcDate('<+5D>', PostingDate);
        SalesHeader.Validate("Posting Date", NewDate);
        SalesHeader.Validate("Order Date", NewDate);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, ItemNo, 30, Qty);
        SalesLine.Validate("Planned Delivery Date", NewDate);
        SalesLine.Modify();
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

    local procedure CreatePurchLineTracking(var PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[50]; LotNo: Code[50]; PackageNo: array[3] of Code[50])
    var
        j: Integer;
    begin
        if not NewSerialTracking then
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo, PackageNo[1], Qty)
        else
            for j := 1 to Qty do begin
                UpdateSerialNos(SerialNo, j);
                LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, PackageNo[1], 1);
            end;
    end;

    local procedure CreatePurchLineTracking2(var PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[50]; LotNo: Code[50]; PackageNo: array[3] of Code[50])
    var
        j: Integer;
    begin
        if not NewSerialTracking then begin
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo, PackageNo[1],
                Round(Qty / 2, 1));
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo, PackageNo[2], Qty - Round(Qty / 2, 1));
        end else
            for j := 1 to Qty do begin
                UpdateSerialNos(SerialNo, j);
                case j of
                    1 .. Round(Qty / 2, 1):
                        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, PackageNo[1], 1);
                    (Round(Qty / 2, 1) + 1) .. Qty:
                        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, PackageNo[2], 1);
                end;
            end;
    end;

    local procedure CreateItemReceiptLineTracking(var InvtDocumentLine: Record "Invt. Document Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[50]; LotNo: Code[50]; PackageNo: array[3] of Code[50])
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        j: Integer;
    begin
        if not NewSerialTracking then begin
            ItemTrackingSetup."Serial No." := '';
            ItemTrackingSetup."Lot No." := LotNo;
            ItemTrackingSetup."Package No." := PackageNo[1];
            LibraryItemTracking.CreateItemReceiptItemTracking(ReservationEntry, InvtDocumentLine, ItemTrackingSetup, Qty);
        end else
            for j := 1 to Qty do begin
                UpdateSerialNos(SerialNo, j);
                ItemTrackingSetup."Serial No." := SerialNo[j];
                ItemTrackingSetup."Lot No." := LotNo;
                ItemTrackingSetup."Package No." := PackageNo[1];
                LibraryItemTracking.CreateItemReceiptItemTracking(ReservationEntry, InvtDocumentLine, ItemTrackingSetup, 1);
            end;
    end;

    local procedure CreateSalesLineTracking(var SalesLine: Record "Sales Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[50]; LotNo: Code[50]; PackageNo: array[3] of Code[50])
    var
        j: Integer;
    begin
        if not NewSerialTracking then
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo, PackageNo[1], Qty)
        else
            for j := 1 to Qty do
                LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, SerialNo[j], LotNo, PackageNo[1], 1);
    end;

    local procedure CreateSalesLineTracking2(var SalesLine: Record "Sales Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[50]; LotNo: Code[50]; PackageNo: array[3] of Code[50])
    var
        j: Integer;
    begin
        if not NewSerialTracking then begin
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo, PackageNo[1], Round(Qty / 2, 1));
            LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo, PackageNo[2], Qty - Round(Qty / 2, 1));
        end else
            for j := 1 to Qty do
                case j of
                    1 .. Round(Qty / 2, 1):
                        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, SerialNo[j], LotNo, PackageNo[1], 1);
                    Round(Qty / 2, 1) + 1 .. Qty:
                        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, SerialNo[j], LotNo, PackageNo[2], 1);
                end;
    end;

    local procedure CreateCreditMemoTracking(var PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry"; NewSerialTracking: Boolean; Qty: Decimal; var SerialNo: array[10] of Code[50]; LotNo: Code[50]; PackageNo: array[3] of Code[50])
    var
        j: Integer;
    begin
        if not NewSerialTracking then
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo, PackageNo[1], Qty)
        else
            for j := 1 to Qty do
                LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, SerialNo[j], LotNo, PackageNo[1], 1);
    end;

    local procedure CreatePOSOReservation(SalesHeader: Record "Sales Header"; PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; QtyRPO: Decimal; LotNo: Code[50]; PackageNo: array[3] of Code[50])
    var
        ReservEntryFor: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetSource(Database::"Sales Line", "Sales Document Type"::Order.AsInteger(), SalesHeader."No.", 10000, '', 0);
        TrackingSpecification."Qty. per Unit of Measure" := 1;
        TrackingSpecification."Lot No." := LotNo;
        TrackingSpecification."Package No." := PackageNo[1];
        LibraryReservation.CreateReservEntryFrom(TrackingSpecification);
        LibraryReservation.CreateEntry(
            ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate()), CalcDate('<+5D>', WorkDate()), 0, "Reservation Status"::Reservation);
        ReservEntryFor."Lot No." := LotNo;
        ReservEntryFor."Package No." := PackageNo[1];
        LibraryReservation.CreateReservEntryFor(
            Database::"Purchase Line", "Purchase Document Type"::Order.AsInteger(), PurchaseHeader."No.", '', 0, 10000, 1, QtyRPO, QtyRPO, ReservEntryFor);
        LibraryReservation.CreateEntry(
            ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate()), CalcDate('<+5D>', WorkDate()), 0, "Reservation Status"::Reservation);
    end;

    local procedure CreateIRSOReservation(SalesHeader: Record "Sales Header"; InvtDocumentHeader: Record "Invt. Document Header"; LocationCode: Code[10]; ItemNo: Code[20]; QtyRIR: Integer; LotNo: Code[50]; PackageNo: array[3] of Code[50])
    var
        ReservEntryFor: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetSource(Database::"Sales Line", "Sales Document Type"::Order.AsInteger(), SalesHeader."No.", 10000, '', 0);
        TrackingSpecification."Qty. per Unit of Measure" := 1;
        TrackingSpecification."Lot No." := LotNo;
        TrackingSpecification."Package No." := PackageNo[1];
        LibraryReservation.CreateReservEntryFrom(TrackingSpecification);
        LibraryReservation.CreateEntry(
            ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate()), CalcDate('<+5D>', WorkDate()), 0, "Reservation Status"::Reservation);
        ReservEntryFor."Lot No." := LotNo;
        ReservEntryFor."Package No." := PackageNo[1];
        LibraryReservation.CreateReservEntryFor(
            Database::"Invt. Document Line", 0, InvtDocumentHeader."No.", '', 0, 10000, 1, QtyRIR, QtyRIR, ReservEntryFor);
        LibraryReservation.CreateEntry(
            ItemNo, '', LocationCode, '', CalcDate('<+1D>', WorkDate()), CalcDate('<+5D>', WorkDate()), 0, "Reservation Status"::Reservation);
    end;

    local procedure CheckILEs(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[50]; PackageNo: Code[50]; Qty: Decimal)
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, ItemNo, LocationCode, '', LotNo, PackageNo, Qty);
    end;

    local procedure CheckILEsWithSerial(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; SerialNo: array[10] of Code[50]; LotNo: Code[50]; PackageNo: Code[50]; Qty: Decimal)
    var
        j: Integer;
        Sign: Integer;
    begin
        if Qty > 0 then
            sign := 1
        else
            Sign := -1;

        for j := 1 to Abs(Qty) do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
            LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, ItemNo, LocationCode, SerialNo[j], LotNo, PackageNo, Sign * 1);
        end;
    end;

    local procedure FindLastReturnShipment(var ReturnShipmentHeader: Record "Return Shipment Header"; VendNo: Code[20])
    begin
        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", VendNo);
        ReturnShipmentHeader.FindLast();
    end;

    local procedure FindLastPurchReceipt(var PurchRcptHeader: Record "Purch. Rcpt. Header"; VendNo: Code[20])
    begin
        PurchRcptHeader.SetRange("Buy-from Vendor No.", VendNo);
        PurchRcptHeader.FindLast();
    end;

    local procedure AllowInvtDocReservation(Allow: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Allow Invt. Doc. Reservation" <> Allow then begin
            InventorySetup."Allow Invt. Doc. Reservation" := Allow;
            InventorySetup.Modify();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.FILTER.SetFilter("Package No.", LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines."Qty. to Invoice (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirmUndo(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DoYouWantToUndoMsg) = 0 then
            Error(IncorrectConfirmDialogErr, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirmTracking(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, FunctionCreateSpecMsg) = 0 then
            Error(IncorrectConfirmDialogErr, Question);
        Reply := true;
    end;
}

