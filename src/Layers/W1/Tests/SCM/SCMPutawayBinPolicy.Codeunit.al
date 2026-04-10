codeunit 137291 "SCM Put-away Bin Policy"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM] [Inventory Put-away] [Put-away Bin Policy]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_PutawayLinesNotCreatedIfDefaultNotSet_PO()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin, no put-away lines are created if no Bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := false;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // [THEN] No Put-Away lines are created
        Assert.IsFalse(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_PutawayLinesCreatedIfDefaultNotSetAndAlwaysCreatePutawayLinesIsON_PO()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and 'Always Create Put-away Line' is ON, put-away line is create with empty Bin if no Bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // [THEN] Put-Away line is created with empty Bin Code
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, '', 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_DefaultBinNotUsedIfBinIsSetOnLine_PO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and a different Bin is used on the purchase line, put-away line uses the one set on the purchase line.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set a Bin as Default
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Default := true;
        BinContent.Modify(true);

        // [GIVEN] A non default Bin
        Bin.Next();

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, Bin.Code, Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // [THEN] Put-Away line is created with Bin Code as the one defined on the Purchase Line
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, Bin.Code, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_DefaultBinSelectedEvenIfMaxQtyIsSmall_PO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and a Bin is marked as Default, put-away line holds complete quantity even if the max. qty. on the bin is lower.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set 'Max. Qty.' on the 'Default Bin'
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Default := true;
        BinContent."Max. Qty." := 20;
        BinContent.Modify(true);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // [THEN] Put-Away line is created with Default Bin Code with Quaitity more than the Max. Qty.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, Bin.Code, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_CreatesPutawayLinesForSerialTrackedItem_PO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Default', put-away lines are created based on the put-away template when item is serially tracked.
        Initialize();


        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway, Require Receive and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Set 'Max. Qty.' on the 'Default Bin'
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Default := true;
        BinContent."Max. Qty." := 20;
        BinContent.Modify(true);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 5, false);

        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        Commit();

        // [THEN] Put-Away line is created and correct qty. is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 5);
        WarehouseActivityLine.SetRange("Qty. (Base)", 1);
        Assert.RecordCount(WarehouseActivityLine, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyPutawayTemplate_PutawayLinesCreated_PO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created based on the put-away template.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Always Create Put-away Line" := false;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 2);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[1], 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyPutawayTemplate_EmptyPutawayLineCreatedIfAlwaysCreatePutawayLineIsON_PO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created based on the put-away template and if there are remaining qty. an line with empty Bin Code is created if 'Always Create Put-away Line' is ON.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 3);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[1], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, '', 10);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyPutawayTemplate_CreatesPutawayLinesForSerialTrackedItem_PO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created based on the put-away template and if there are remaining qty. an line with empty Bin Code is created if 'Always Create Put-away Line' is ON.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, false, false, false, false, true);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway, Require Receive and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 5, false);

        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        Commit();

        // [THEN] Put-Away line is created and correct qty. is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 5);
        WarehouseActivityLine.SetRange("Qty. (Base)", 1);
        Assert.RecordCount(WarehouseActivityLine, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure PutawayLineCreatedWhenBinMandatoryIsOFF_PO()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Put-away Bin Policy is ignored and put-away lines with empty 'Bin Code' are created when 'Bin Mandatory' is OFF.
        Initialize();

        // [GIVEN] Create Location with 'Bin Mandatory' OFF.
        CreateLocationSetupWithBins(Location, true, false, false, false, false, 0);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        Commit();

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::" "), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, '', 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyPutawayTemplate_PutawayLinesCreatedForPurchRtnOrdWithNegativeQty()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created for purchase return order.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Location.Code, '', Item."No.", -50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Return Order", PurchaseHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 3);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[1], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, '', 10);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_PutawayLinesNotCreatedIfDefaultNotSet_SalesReturnOrder()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin, no put-away lines are created if no Bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := false;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Return Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Return Order", SalesHeader."No.", true, false, false);

        // [THEN] No Put-Away lines are created
        Assert.IsFalse(FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_PutawayLinesCreatedIfDefaultNotSetAndAlwaysCreatePutawayLinesIsON_SalesReturnOrder()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and 'Always Create Put-away Line' is ON, put-away line is create with empty Bin if no Bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Return Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Return Order", SalesHeader."No.", true, false, false);

        // [THEN] Put-Away line is created with empty Bin Code
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, '', 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_DefaultBinNotUsedIfBinIsSetOnPurchaseLine_SalesReturnOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and a different Bin is used on the purchase line, put-away line uses the one set on the Sales line.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set a Bin as Default
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Default := true;
        BinContent.Modify(true);

        // [GIVEN] A non default Bin
        Bin.Next();

        // [GIVEN] Create Sales Return Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Location.Code, Bin.Code, Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Return Order", SalesHeader."No.", true, false, false);

        // [THEN] Put-Away line is created with Bin Code as the one defined on the Purchase Line
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, Bin.Code, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_DefaultBinSelectedEvenIfMaxQtyIsSmall_SalesReturnOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and a Bin is marked as Default, put-away line holds complete quantity even if the max. qty. on the bin is lower.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set 'Max. Qty.' on the 'Default Bin'
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Default := true;
        BinContent."Max. Qty." := 20;
        BinContent.Modify(true);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Return Order", SalesHeader."No.", true, false, false);

        // [THEN] Put-Away line is created with Default Bin Code with Quaitity more than the Max. Qty.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, Bin.Code, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyPutawayTemplate_PutawayLinesCreated_SalesReturnOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created based on the put-away template.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Always Create Put-away Line" := false;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Return Order", SalesHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 2);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[1], 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyPutawayTemplate_EmptyPutawayLineCreatedIfAlwaysCreatePutawayLineIsON_SalesReturnOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created based on the put-away template and if there are remaining qty. an line with empty Bin Code is created if 'Always Create Put-away Line' is ON.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Location.Code, '', Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Return Order", SalesHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 3);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[1], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, '', 10);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyPutawayTemplate_PutawayLinesCreatedForPurchRtnOrdWithNegativeQty_SalesReturnOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created for purchase return order.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template'.
        CreateLocationSetupWithBins(Location, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, '', Item."No.", -50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 3);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[1], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, '', 10);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure PutawayLineCreatedWhenBinMandatoryIsOFF_SalesReturnOrder()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Put-away Bin Policy is ignored and put-away lines with empty 'Bin Code' are created when 'Bin Mandatory' is OFF.
        Initialize();

        // [GIVEN] Create Location with 'Bin Mandatory' OFF.
        CreateLocationSetupWithBins(Location, true, false, false, false, false, 5);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, '', Item."No.", -50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::" "), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, '', 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_PutawayLinesNotCreatedIfDefaultNotSet_TO()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin, no put-away lines are created if no Bin is marked as default.
        Initialize();

        // [GIVEN] Create To Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(FromLocation, false, false, false, false, false, 0);
        CreateLocationSetupWithBins(ToLocation, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        ToLocation."Put-away Bin Policy" := ToLocation."Put-away Bin Policy"::"Default Bin";
        ToLocation."Always Create Put-away Line" := false;
        ToLocation.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Updte stock in FromLocation
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 100, FromLocation.Code, '', false);

        // [GIVEN] Create Transfer Order for 50 quantity of the created item.
        CreateAndShipTransferOrder(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item."No.", 50);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Inbound Transfer", TransferHeader."No.", true, false, false);

        // [THEN] No Put-Away lines are created
        Assert.IsFalse(FindWarehouseActivityLine(
          WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          ToLocation.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_PutawayLinesCreatedIfDefaultNotSetAndAlwaysCreatePutawayLinesIsON_TO()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and 'Always Create Put-away Line' is ON, put-away line is create with empty Bin if no Bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(FromLocation, false, false, false, false, false, 0); // Create Location with Require Putaway and Bin Mandatory.
        CreateLocationSetupWithBins(ToLocation, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        ToLocation."Put-away Bin Policy" := ToLocation."Put-away Bin Policy"::"Default Bin";
        ToLocation."Always Create Put-away Line" := true;
        ToLocation.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Updte stock in FromLocation
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 100, FromLocation.Code, '', false);

        // [GIVEN] Create Transfer Order for 50 quantity of the created item.
        CreateAndShipTransferOrder(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item."No.", 50);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Inbound Transfer", TransferHeader."No.", true, false, false);

        // [THEN] Put-Away line is created with empty Bin Code
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          ToLocation.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, ToLocation.Code, '', 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_DefaultBinNotUsedIfBinIsSetOnLine_TO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and a different Bin is used on the purchase line, put-away line uses the one set on the purchase line.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(FromLocation, false, false, false, false, false, 0);
        CreateLocationSetupWithBins(ToLocation, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        ToLocation."Put-away Bin Policy" := ToLocation."Put-away Bin Policy"::"Default Bin";
        ToLocation."Always Create Put-away Line" := true;
        ToLocation.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set a Bin as Default
        Bin.SetRange("Location Code", ToLocation.Code);
        Bin.FindFirst();
        LibraryWarehouse.CreateBinContent(BinContent, ToLocation.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Default := true;
        BinContent.Modify(true);

        // [GIVEN] A non default Bin
        Bin.Next();

        // [GIVEN] Updte stock in FromLocation
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 100, FromLocation.Code, '', false);

        // [GIVEN] Create Transfer Order for 50 quantity of the created item.
        CreateAndShipTransferOrder(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Bin.Code, Item."No.", 50);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Inbound Transfer", TransferHeader."No.", true, false, false);

        // [THEN] Put-Away line is created with Bin Code as the one defined on the Purchase Line
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          ToLocation.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, ToLocation.Code, Bin.Code, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyDefault_DefaultBinSelectedEvenIfMaxQtyIsSmall_TO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and a Bin is marked as Default, put-away line holds complete quantity even if the max. qty. on the bin is lower.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(FromLocation, false, false, false, false, false, 0);
        CreateLocationSetupWithBins(ToLocation, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        ToLocation."Put-away Bin Policy" := ToLocation."Put-away Bin Policy"::"Default Bin";
        ToLocation."Always Create Put-away Line" := true;
        ToLocation.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set 'Max. Qty.' on the 'Default Bin'
        Bin.SetRange("Location Code", ToLocation.Code);
        Bin.FindFirst();

        LibraryWarehouse.CreateBinContent(BinContent, ToLocation.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Default := true;
        BinContent."Max. Qty." := 20;
        BinContent.Modify(true);

        // [GIVEN] Updte stock in FromLocation
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 100, FromLocation.Code, '', false);

        // [GIVEN] Create Transfer Order for 50 quantity of the created item.
        CreateAndShipTransferOrder(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item."No.", 50);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Inbound Transfer", TransferHeader."No.", true, false, false);

        // [THEN] Put-Away line is created with Default Bin Code with Quaitity more than the Max. Qty.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          ToLocation.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, ToLocation.Code, Bin.Code, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyPutawayTemplate_PutawayLinesCreated_TO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created based on the put-away template.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(FromLocation, false, false, false, false, false, 0);
        CreateLocationSetupWithBins(ToLocation, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        ToLocation."Put-away Bin Policy" := ToLocation."Put-away Bin Policy"::"Put-away Template";
        ToLocation."Put-away Template Code" := PutAwayTemplateHeader.Code;
        ToLocation."Always Create Put-away Line" := false;
        ToLocation.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", ToLocation.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, ToLocation.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Updte stock in FromLocation
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 100, FromLocation.Code, '', false);

        // [GIVEN] Create Transfer Order for 50 quantity of the created item.
        CreateAndShipTransferOrder(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item."No.", 50);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Inbound Transfer", TransferHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          ToLocation.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 2);
        VerifyPutawayLine(WarehouseActivityLine, ToLocation.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, ToLocation.Code, BinCode[1], 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryBinPolicyPutawayTemplate_EmptyPutawayLineCreatedIfAlwaysCreatePutawayLineIsON_TO()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created based on the put-away template and if there are remaining qty. an line with empty Bin Code is created if 'Always Create Put-away Line' is ON.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(FromLocation, false, false, false, false, false, 0);
        CreateLocationSetupWithBins(ToLocation, true, false, false, false, true, 5); // Create Location with Require Putaway and Bin Mandatory.
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        ToLocation."Put-away Bin Policy" := ToLocation."Put-away Bin Policy"::"Put-away Template";
        ToLocation."Put-away Template Code" := PutAwayTemplateHeader.Code;
        ToLocation."Always Create Put-away Line" := true;
        ToLocation.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", ToLocation.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, ToLocation.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Updte stock in FromLocation
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 100, FromLocation.Code, '', false);

        // [GIVEN] Create Transfer Order for 50 quantity of the created item.
        CreateAndShipTransferOrder(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item."No.", 50);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Inbound Transfer", TransferHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          ToLocation.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 3);
        VerifyPutawayLine(WarehouseActivityLine, ToLocation.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, ToLocation.Code, BinCode[1], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, ToLocation.Code, '', 10);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure PutawayLineCreatedWhenBinMandatoryIsOFF_TO()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Put-away Bin Policy is ignored and put-away lines with empty 'Bin Code' are created when 'Bin Mandatory' is OFF.
        Initialize();

        // [GIVEN] Create from and to Locations
        CreateLocationSetupWithBins(FromLocation, false, false, false, false, false, 0);
        CreateLocationSetupWithBins(ToLocation, true, false, false, false, false, 0); // Create Location with Require Putaway ON and Bin Mandatory OFF.
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Update stock in FromLocation
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 100, FromLocation.Code, '', false);

        // [GIVEN] Create Transfer Order for 50 quantity of the created item.
        CreateAndShipTransferOrder(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item."No.", 50);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Inbound Transfer", TransferHeader."No.", true, false, false);

        // [THEN] Put-Away line is created and correct qty., Action Type and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          ToLocation.Code, WarehouseActivityLine."Action Type"::" "), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, ToLocation.Code, '', 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePutawayBinPolicyDefault_PutawayLinesCreatedEvenWhenDefaultNotSet()
    var
        Item: Record Item;
        Bin: Record Bin;
        ReceiveBin: Record Bin;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin, put-away lines are created with the first bin found if no Bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, true, false, true, 5); // Create Location with Require Putaway, Require Receive and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := false;
        Location.Modify(true);

        // [GIVEN] Create ReceiveBin to be the source bin for the put-away
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        // [GIVEN] Create and Post Warehouse Receipt.
        CreateAndPostWhseReceiptFromPO(PurchaseHeader, ReceiveBin.Code);

        Commit();

        // [THEN] Put-Away lines are created
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Take), 'Expecting empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Bin Code", ReceiveBin.Code);

        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);

        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure WarehousePutawayBinPolicyDefault_DefaultBinUsedWhenSet()
    var
        Item: Record Item;
        ReceiveBin: Record Bin;
        DefaultBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and a non-default Bin is used on the purchase line, put-away line uses the one set on the purchase line.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, true, false, true, 5); // Create Location with Require Putaway, Require Receive and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create ReceiveBin to be the source bin for the put-away and a bin that will marked as default
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(DefaultBin, Location.Code, '', '', '');

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set a Bin as Default
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', DefaultBin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Default := true;
        BinContent.Modify(true);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, ReceiveBin.Code, Item."No.", 50, false);

        // [GIVEN] Create and Post Warehouse Receipt.
        CreateAndPostWhseReceiptFromPO(PurchaseHeader, ReceiveBin.Code);

        Commit();

        // [THEN] Put-Away line is created with Bin Code as the one defined on the Purchase Line
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, DefaultBin.Code, 50);

        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Take), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, ReceiveBin.Code, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePutawayBinPolicyDefault_DefaultBinSelectedEvenIfMaxQtyIsSmall()
    var
        Item: Record Item;
        ReceiveBin: Record Bin;
        DefaultBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] When Put-away Bin Policy is Default Bin and a Bin is marked as Default, put-away line holds complete quantity even if the max. qty. on the bin is lower.
        Initialize();

        // [GIVEN] Create Location with 5 bins with no bin marked as default and the 'Putaway Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, true, false, true, false, true, 5); // Create Location with Require Putaway, Require Receive and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Default Bin";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create ReceiveBin to be the source bin for the put-away and a bin that will be set as default
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(DefaultBin, Location.Code, '', '', '');

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set 'Max. Qty.' on the 'Default Bin'
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', DefaultBin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Default := true;
        BinContent."Max. Qty." := 20;
        BinContent.Modify(true);

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        // [GIVEN] Create and Post Warehouse Receipt.
        CreateAndPostWhseReceiptFromPO(PurchaseHeader, ReceiveBin.Code);

        Commit();

        // [THEN] Put-Away line is created with Default Bin Code with Quaitity more than the Max. Qty.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, DefaultBin.Code, 50);

        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Take), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, ReceiveBin.Code, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePutawayBinPolicyPutawayTemplate_PutawayLinesCreated()
    var
        Item: Record Item;
        Bin: Record Bin;
        ReceiveBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created based on the put-away template.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(Location, true, false, true, false, true, 5); // Create Location with Require Putaway, Require Receive and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Always Create Put-away Line" := false;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Create ReceiveBin to be the source bin for the put-away
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        // [GIVEN] Create and Post Warehouse Receipt.
        CreateAndPostWhseReceiptFromPO(PurchaseHeader, ReceiveBin.Code);

        Commit();

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 2);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[1], 20);

        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Take), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, ReceiveBin.Code, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePutawayBinPolicyPutawayTemplate_EmptyPutawayLineCreatedIfAlwaysCreatePutawayLineIsON()
    var
        Item: Record Item;
        Bin: Record Bin;
        ReceiveBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Index: Integer;
        BinCode: array[5] of Code[20];
    begin
        // [SCENARIO] When Put-away Bin Policy is 'Put-away Template', put-away lines are created based on the put-away template and if there are remaining qty. an line with empty Bin Code is created if 'Always Create Put-away Line' is ON.
        Initialize();

        // [GIVEN] Create put-away template, set "Fixed Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);

        // [GIVEN] Create Location with 5 bins with 'Putaway Bin Policy' set to 'Put-away Template' and a template code is set.
        CreateLocationSetupWithBins(Location, true, false, true, false, true, 5); // Create Location with Require Putaway, Require Receive and Bin Mandatory.
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mark 2 Bins as Fixed and set the 'Max. Qty.' on them.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet();

        Index := 1;
        repeat
            if Index in [1, 5] then begin
                LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
                BinContent."Max. Qty." := 20;
                BinContent.Fixed := true;
                BinContent.Modify(true);
            end;
            BinCode[Index] := Bin.Code;
            Index := Index + 1;
        until Bin.Next() = 0;

        // [GIVEN] Create ReceiveBin to be the source bin for the put-away
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');

        // [GIVEN] Create Purchase Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, '', Item."No.", 50, false);

        // [GIVEN] Create and Post Warehouse Receipt.
        CreateAndPostWhseReceiptFromPO(PurchaseHeader, ReceiveBin.Code);

        Commit();

        // [THEN] Put-Away line is created and correct qty. and Bin code is set.
        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 3);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[5], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, BinCode[1], 20);
        WarehouseActivityLine.Next();
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, '', 10);

        Assert.IsTrue(FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Take), 'Expecting non empty recordset');

        Assert.RecordCount(WarehouseActivityLine, 1);
        VerifyPutawayLine(WarehouseActivityLine, Location.Code, ReceiveBin.Code, 50);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Put-away Bin Policy");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Put-away Bin Policy");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SavePurchasesSetup();

        NoSeriesSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Put-away Bin Policy");
    end;

    local procedure VerifyPutawayLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        WarehouseActivityLine.TestField("Location Code", LocationCode);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type"): Boolean
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        exit(WarehouseActivityLine.FindFirst());
    end;

    local procedure CreateLocationSetupWithBins(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean; NoOfBins: Integer)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NoOfBins, false); // Value required.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibrarySales.SetOrderNoSeriesInSetup();
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate1: Record "Item Journal Template"; var ItemJournalBatch1: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate1, ItemJournalTemplateType);
        ItemJournalTemplate1.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate1.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch1, ItemJournalTemplate1.Type, ItemJournalTemplate1.Name);
        ItemJournalBatch1.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch1.Modify(true);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch1: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch1.Validate("No. Series", NoSeries);
        ItemJournalBatch1.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal;
                                                                                  LocationCode: Code[10];
                                                                                  BinCode: Code[20];
                                                                                  UseTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if UseTracking then
            ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        if VariantCode <> '' then
            PurchaseLine.Validate("Variant Code", VariantCode);
        if BinCode <> '' then
            PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        if VariantCode <> '' then
            SalesLine.Validate("Variant Code", VariantCode);
        if BinCode <> '' then
            SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; LocationCode: Code[10];
                                                                                                            BinCode: Code[20];
                                                                                                            ItemNo: Code[20];
                                                                                                            Quantity: Decimal;
                                                                                                            UseTraking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LocationCode, BinCode, ItemNo, '', Quantity);
        if UseTraking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
            PurchaseLine.OpenItemTrackingLines();
        end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndShipTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10];
                                                                                             ToLocationCode: Code[10];
                                                                                             InTransitLocationCode: Code[10];
                                                                                             ItemNo: Code[20];
                                                                                             Quantity: Decimal)
    begin
        CreateAndShipTransferOrder(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode, '', ItemNo, Quantity);
    end;

    local procedure CreateAndShipTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10];
                                                                                             ToLocationCode: Code[10];
                                                                                             InTransitLocationCode: Code[10];
                                                                                             ToBinCode: Code[20];
                                                                                             ItemNo: Code[20];
                                                                                             Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);

        if ToBinCode = '' then
            exit;

        TransferLine.Validate("Transfer-To Bin Code", ToBinCode);
        TransferLine.Modify(true);
    end;

    local procedure CreateAndReleaseSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10];
                                                                                                            BinCode: Code[20];
                                                                                                            ItemNo: Code[20];
                                                                                                            Quantity: Decimal;
                                                                                                            UseTraking: Boolean)
    var
        SalesLine: Record "Sales Line";
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, BinCode, ItemNo, '', Quantity);
        if UseTraking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
            SalesLine.OpenItemTrackingLines();
        end;
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndPostWhseReceiptFromPO(var PurchaseHeader: Record "Purchase Header"; ReceiveBinCode: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", ReceiveBinCode);
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ReceiveBinCode: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(SourceDocument, SourceNo));
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.ModifyAll("Bin Code", ReceiveBinCode, true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure FindWarehouseReceiptNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
        exit(WarehouseReceiptLine."No.");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
    end;
}

