codeunit 137029 "SCM Warehouse Orange Location"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        OrangeLocation: Code[10];
        isInitialized: Boolean;
        BinError: Label 'Bin Code must be %1 in %2.';
        BinError2: Label 'Bin Code must not be %1 in %2.';
        TextREC: Label 'REC';
        TextSHIP: Label 'SHIP';
        TextBIN1: Label 'BIN1';
        TextBIN2: Label 'BIN2';
        Question1: Label 'Do you want to post the receipt?';
        Question2: Label 'Do you want to register the %1 Document?';
        UnexpectedError: Label 'An unexpected unhandled UI occurred: %1.';

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure PutAwayBinCodeWithOnlyReceiveBin()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // setup
        Initialize();
        // execute
        CreateAndPostWhseReceipt(PurchaseHeader, PostedWhseReceiptLine, 1);
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Take, 0);
        WhseActivityLine.FindFirst();
        // validate: check that bin code on put-away/take line is same as posted warehouse receipt line line.
        Assert.AreEqual(PostedWhseReceiptLine."Bin Code", WhseActivityLine."Bin Code",
          StrSubstNo(BinError, PostedWhseReceiptLine."Bin Code", WhseActivityLine.TableCaption()));
        // validate: check that bin code on put-away/place line is blank.
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Place, 0);
        WhseActivityLine.FindFirst();
        Assert.AreEqual('', WhseActivityLine."Bin Code", StrSubstNo(BinError, '', WhseActivityLine.TableCaption()));
        // validate: registering put-away should throw error
        WhseActivityLine.Reset();
        asserterror CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Register (Yes/No)", WhseActivityLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayBinCodeWithOnlyReceiveShip()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
        Location: Record Location;
    begin
        // setup
        Initialize();
        Location.Get(OrangeLocation);
        CreateBin(Bin, Location.Code, TextSHIP);
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Modify(true);
        // execute
        CreateAndPostWhseReceipt(PurchaseHeader, PostedWhseReceiptLine, 1);
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Take, 0);
        WhseActivityLine.FindFirst();
        // validate: check that bin code on put-away/take line is same as posted warehouse receipt line line.
        Assert.AreEqual(PostedWhseReceiptLine."Bin Code", WhseActivityLine."Bin Code",
          StrSubstNo(BinError, PostedWhseReceiptLine."Bin Code", WhseActivityLine.TableCaption()));
        // validate: check that bin code on put-away/place line is blank.
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Place, 0);
        WhseActivityLine.FindFirst();
        Assert.AreEqual('', WhseActivityLine."Bin Code", StrSubstNo(BinError, '', WhseActivityLine.TableCaption()));
        // Validate: Assign the Place bin code to SHIP on put-away/Place and validate that it throws an error
        // that bin code can not be one of SHIP or REC.
        asserterror WhseActivityLine.Validate("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure PutAwayBinCodeWithOnlyReceiveShipAndBin2()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        // setup
        Initialize();
        CreateAndPostWhseReceipt(PurchaseHeader, PostedWhseReceiptLine, 1);
        CreateBin(Bin, OrangeLocation, TextBIN2);
        // execute
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Place, 0);
        WhseActivityLine.FindFirst();
        // Validate: Place line bin code should be blank.
        Assert.AreEqual('', WhseActivityLine."Bin Code", StrSubstNo(BinError, '', WhseActivityLine.TableCaption()));
        // execute
        WhseActivityLine.Validate("Bin Code", Bin.Code);
        WhseActivityLine.Modify(true);
        // Validate : BIN1 should be assigned to Put-away/Place line
        Assert.AreEqual(Bin.Code, WhseActivityLine."Bin Code", StrSubstNo(BinError, Bin.Code, WhseActivityLine.TableCaption()));
        // validate : Registering put-away should not throw any error
        WhseActivityLine.Reset();
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Register (Yes/No)", WhseActivityLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayBinCodeWithMultipleLines()
    var
        Location: Record Location;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // setup
        Initialize();
        Location.Get(OrangeLocation);
        CreateBin(Bin, OrangeLocation, TextBIN2);
        // execute
        CreateAndModifyLineBinAndPostWhseReceipt(PurchaseHeader, PostedWhseReceiptLine, 2, 1, TextBIN2);
        // validate : bin code on 1st take line is BIN2.
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Take, 0);
        WhseActivityLine.FindFirst();
        Assert.AreEqual(Bin.Code, WhseActivityLine."Bin Code", StrSubstNo(BinError, TextBIN2, WhseActivityLine.TableCaption()));
        // validate : bin code on 1st place line is blank
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Place, 0);
        WhseActivityLine.FindFirst();
        Assert.AreEqual('', WhseActivityLine."Bin Code", StrSubstNo(BinError, '', WhseActivityLine.TableCaption()));
        // validate : bin code on 2nd take line is REC.
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Take, 0);
        WhseActivityLine.Next(2);
        Assert.AreEqual(
          Location."Receipt Bin Code", WhseActivityLine."Bin Code", StrSubstNo(BinError, TextREC, WhseActivityLine.TableCaption()));
        // validate : bin code on 2nd place line is BIN2
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Place, 0);
        WhseActivityLine.Next(2);
        Assert.AreEqual(Bin.Code, WhseActivityLine."Bin Code", StrSubstNo(BinError, TextBIN2, WhseActivityLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure PutAwayBinCodeWithReceiveShipBin1AndBin2()
    var
        Location: Record Location;
        BinRec1: Record Bin;
        BinRec2: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // setup
        Initialize();
        Location.Get(OrangeLocation);
        CreateBin(BinRec1, OrangeLocation, TextBIN1);
        CreateBin(BinRec2, OrangeLocation, TextBIN2);
        // execute
        CreateAndModifyLineBinAndPostWhseReceipt(PurchaseHeader, PostedWhseReceiptLine, 2, 1, TextBIN2);
        // validate : bin code on 1st take line is BIN2.
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Take, 0);
        WhseActivityLine.FindFirst();
        Assert.AreEqual(BinRec2.Code, WhseActivityLine."Bin Code", StrSubstNo(BinError, BinRec2.Code, WhseActivityLine.TableCaption()));
        // validate : bin code on 1st place line is bin1
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Place, 0);
        WhseActivityLine.FindFirst();
        Assert.AreEqual(BinRec1.Code, WhseActivityLine."Bin Code", StrSubstNo(BinError, BinRec1.Code, WhseActivityLine.TableCaption()));
        // validate : bin code on 2nd take line is REC.
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Take, 0);
        WhseActivityLine.Next(2);
        Assert.AreEqual(Location."Receipt Bin Code", WhseActivityLine."Bin Code", StrSubstNo(BinError, Location."Receipt Bin Code",
            WhseActivityLine.TableCaption()));
        // validate : bin code on 2nd place line is neither REC or SHIP bin code
        FilterWhseActivityLine(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away",
          WhseActivityLine."Action Type"::Place, 0);
        WhseActivityLine.Next(2);
        Assert.AreNotEqual(Location."Receipt Bin Code", WhseActivityLine."Bin Code", StrSubstNo(BinError2,
            Location."Receipt Bin Code", WhseActivityLine.TableCaption()));
        Assert.AreNotEqual(Location."Shipment Bin Code", WhseActivityLine."Bin Code", StrSubstNo(BinError2,
            Location."Shipment Bin Code", WhseActivityLine.TableCaption()));
        // validate : Registering put-away should not throw any error
        WhseActivityLine.Reset();
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Register (Yes/No)", WhseActivityLine);
    end;

    [Normal]
    local procedure CreateBin(var Bin: Record Bin; Locationcode: Code[10]; "Code": Code[10])
    begin
        if Bin.Get(Locationcode, Code) then
            exit;

        Clear(Bin);
        Bin.Init();
        Bin.Validate("Location Code", Locationcode);
        Bin.Validate(Code, Code);
        Bin.Validate(Empty, true);
        Bin.Insert(true);
    end;

    local procedure CreateOrangeLocation(): Code[10]
    var
        Location: Record Location;
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        Location.Validate("Use Put-away Worksheet", false);
        Location.Validate("Directed Put-away and Pick", false);
        Location.Validate("Use ADCS", false);
        Location.Validate("Default Bin Selection", Location."Default Bin Selection"::"Fixed Bin");

        CreateBin(Bin, Location.Code, TextREC);
        Location.Validate("Receipt Bin Code", Bin.Code);
        Location.Modify(true);

        exit(Location.Code);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; NoOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        Linecount: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        for Linecount := 1 to NoOfLines do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
            PurchaseLine.Validate("Location Code", OrangeLocation);
            PurchaseLine.Modify(true);
        end;
    end;

    [Normal]
    local procedure CreateAndModifyLineBinAndPostWhseReceipt(var PurchaseHeader: Record "Purchase Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; NoOfLines: Integer; ReceiptLineIndexToModify: Integer; BinCode: Code[10])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, NoOfLines);
        CreateWarehouseReceipt(PurchaseHeader, WarehouseReceiptHeader);
        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.Next(ReceiptLineIndexToModify);
        WhseReceiptLine.Validate("Bin Code", BinCode);
        WhseReceiptLine.Modify(true);
        PostWarehouseReceipt(PostedWhseReceiptLine, PurchaseHeader, WarehouseReceiptHeader);
    end;

    local procedure CreateAndPostWhseReceipt(var PurchaseHeader: Record "Purchase Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; NoOfLines: Integer)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, NoOfLines);
        CreateWarehouseReceipt(PurchaseHeader, WarehouseReceiptHeader);
        PostWarehouseReceipt(PostedWhseReceiptLine, PurchaseHeader, WarehouseReceiptHeader);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; NoOfLines: Integer)
    begin
        CreatePurchaseOrder(PurchaseHeader, NoOfLines);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    [Normal]
    local procedure CreateWarehouseReceipt(PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
              DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
    end;

    [Normal]
    local procedure FilterWhseActivityLine(var WhseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LineNo: Integer)
    begin
        WhseActivityLine.Reset();
        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Activity Type", ActivityType);
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.SetRange("Action Type", ActionType);
        if LineNo <> 0 then
            WhseActivityLine.SetRange("Whse. Document Line No.", LineNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        case true of
            StrPos(Question, Question1) > 0,
          // Question1 = text000 in COD5761
          StrPos(Question, Question2) > 0:
                // Question2 = text001 in COD7306
                Reply := true;
            true:
                Error(UnexpectedError, Question);
        end;
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse Orange Location");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse Orange Location");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryService.SetupServiceMgtNoSeries();
        OrangeLocation := CreateOrangeLocation();
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.SetRange(Default, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, OrangeLocation, (not WarehouseEmployee.FindFirst()));
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse Orange Location");
    end;

    [Normal]
    local procedure PostWarehouseReceipt(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PurchaseHeader: Record "Purchase Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        PostedWhseReceiptLine.SetRange("Source Document", PostedWhseReceiptLine."Source Document"::"Purchase Order");
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        PostedWhseReceiptLine.FindFirst();
    end;
}

