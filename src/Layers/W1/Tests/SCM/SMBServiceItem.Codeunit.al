codeunit 137510 "SMB Service Item"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Item Type]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_Type()
    var
        Item: Record Item;
    begin
        Initialize();

        // EXERCISE
        CreateInvtItem(Item);

        // Check that the inital value is inventory
        Assert.AreEqual(Item.Type, Item.Type::Inventory, 'The default Type should be Inventory');

        // Check that it is possible change from inventory to service
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);
        Assert.AreEqual(Item.Type, Item.Type::Service, 'It should be possible to change Type to Service');

        // Check that it is possible change from service to inventory
        Item.Validate(Type, Item.Type::Inventory);
        Item.Modify(true);
        Assert.AreEqual(Item.Type, Item.Type::Inventory, 'It should be possible to change Type to Inventory');

        // Check that it is possible change from inventory to Non-Inventory
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);
        Assert.AreEqual(Item.Type, Item.Type::"Non-Inventory", 'It should be possible to change Type to Non-Inventory');

        // Check that it is possible change from Non-Inventory to Inventory
        Item.Validate(Type, Item.Type::Inventory);
        Item.Modify(true);
        Assert.AreEqual(Item.Type, Item.Type::Inventory, 'It should be possible to change Type to Inventory');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_ReplenishmentSystem()
    var
        Item: Record Item;
    begin
        // SETUP
        Initialize();
        CreateInvtItem(Item);

        CreateItemAndTestReplenishmentSystem(Item, true);
        CreateItemAndTestReplenishmentSystem(Item, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_InventoryPostingGroup()
    var
        Item: Record Item;
        InventoryPostingGr: Record "Inventory Posting Group";
    begin
        Initialize();
        CreateInvtItem(Item);
        InventoryPostingGr.FindFirst();
        Item.Validate("Inventory Posting Group", InventoryPostingGr.Code);

        CreateItemAndTestInventoryPostingGroup(Item, InventoryPostingGr, true);
        CreateItemAndTestInventoryPostingGroup(Item, InventoryPostingGr, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_Reserve()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);
        Item.Validate(Reserve, Item.Reserve::Optional);

        // EXERCISE
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);

        // VERIFY
        // Check that the reserve setting is never
        Assert.AreEqual(
          Item.Reserve::Never, Item.Reserve,
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName(Reserve), Item.Reserve::Never, Item.Type::Service));

        // Check that it is not possible change from reserve = never
        asserterror Item.Validate(Reserve, Item.Reserve::Always);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate(Reserve, Item.Reserve::Optional);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        // EXERCISE
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        // VERIFY
        // Check that the reserve setting is never
        Assert.AreEqual(
          Item.Reserve::Never, Item.Reserve,
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName(Reserve), Item.Reserve::Never, Item.Type::"Non-Inventory"));

        // Check that it is not possible change from reserve = never
        asserterror Item.Validate(Reserve, Item.Reserve::Always);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate(Reserve, Item.Reserve::Optional);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_ItemTracking()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Initialize();
        CreateInvtItem(Item);

        ItemTrackingCode.FindFirst();
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);

        // EXERCISE
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);

        // Check that item tracking code
        Assert.AreEqual(
          '', Item."Item Tracking Code",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Item Tracking Code"), '', Item.Type::Service));

        // Check that it is not possible set an item tracking code
        asserterror Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        // EXERCISE
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        // Check that item tracking code
        Assert.AreEqual(
          '', Item."Item Tracking Code",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Item Tracking Code"), '', Item.Type::"Non-Inventory"));

        // Check that it is not possible set an item tracking code
        asserterror Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCanChangeUnitCostForNonInvItemsAndStockkeeping()
    var
        NonInventoryItem: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NonInvStockkeepingUnit: Record "Stockkeeping Unit";
    begin
        Initialize();

        CreateNonInvItem(NonInventoryItem);
        NonInventoryItem.Validate("Unit Cost", 10.0);

        LibrarySales.CreateCustomer(Cust);

        CreateSalesOrder(Cust, SalesHeader, SalesLine, NonInventoryItem);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        NonInventoryItem.Validate("Unit Cost", 5.0);

        CreateStockkeepingUnit(NonInvStockkeepingUnit, NonInventoryItem);
        NonInvStockkeepingUnit.Validate(NonInvStockkeepingUnit."Unit Cost", 5.0);

        CreateSalesOrder(Cust, SalesHeader, SalesLine, NonInventoryItem);
        SalesLine.Validate("Variant Code", NonInvStockkeepingUnit."Variant Code");
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        NonInvStockkeepingUnit.Validate(NonInvStockkeepingUnit."Unit Cost", 1.0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCanChangeUnitCostForServiceItemsAndStockkeeping()
    var
        ServiceItem: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceStockkeepingUnit: Record "Stockkeeping Unit";
    begin
        Initialize();

        CreateServItem(ServiceItem);
        ServiceItem.Validate("Unit Cost", 10.0);

        LibrarySales.CreateCustomer(Cust);

        CreateSalesOrder(Cust, SalesHeader, SalesLine, ServiceItem);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ServiceItem.Validate("Unit Cost", 5.0);

        CreateStockkeepingUnit(ServiceStockkeepingUnit, ServiceItem);
        ServiceStockkeepingUnit.Validate(ServiceStockkeepingUnit."Unit Cost", 5.0);

        CreateSalesOrder(Cust, SalesHeader, SalesLine, ServiceItem);
        SalesLine.Validate("Variant Code", ServiceStockkeepingUnit."Variant Code");
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ServiceStockkeepingUnit.Validate(ServiceStockkeepingUnit."Unit Cost", 1.0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotChangeUnitCostForInvItemsAndStockkeeping()
    var
        InventoryItem: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvStockkeepingUnit: Record "Stockkeeping Unit";
    begin
        Initialize();

        CreateInvtItem(InventoryItem);
        InventoryItem.Validate("Unit Cost", 10.0);

        LibrarySales.CreateCustomer(Cust);

        CreateSalesOrder(Cust, SalesHeader, SalesLine, InventoryItem);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        asserterror InventoryItem.Validate("Unit Cost", 5.0);

        CreateStockkeepingUnit(InvStockkeepingUnit, InventoryItem);
        InvStockkeepingUnit.Validate(InvStockkeepingUnit."Unit Cost", 5.0);

        CreateSalesOrder(Cust, SalesHeader, SalesLine, InventoryItem);
        SalesLine.Validate("Variant Code", InvStockkeepingUnit."Variant Code");
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        asserterror InvStockkeepingUnit.Validate(InvStockkeepingUnit."Unit Cost", 1.0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_CostingMethod()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::LIFO);

        // EXERCISE
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);

        // Check that the reserve setting is never
        Assert.AreEqual(
          Item."Costing Method"::FIFO, Item."Costing Method",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Costing Method"), Item."Costing Method"::Standard, Item.Type::Service));

        // Check that it is not possible change from costing method = FIFO
        asserterror Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate("Costing Method", Item."Costing Method"::Average);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate("Costing Method", Item."Costing Method"::LIFO);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        // EXERCISE
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        // Check that the reserve setting is never
        Assert.AreEqual(
          Item."Costing Method"::FIFO, Item."Costing Method",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Costing Method"), Item."Costing Method"::Standard, Item.Type::"Non-Inventory"));

        // Check that it is not possible change from costing method = FIFO
        asserterror Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate("Costing Method", Item."Costing Method"::Average);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate("Costing Method", Item."Costing Method"::LIFO);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_ProdBOM()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        LibraryMfg: Codeunit "Library - Manufacturing";
    begin
        Initialize();
        CreateInvtItem(Item);
        CreateInvtItem(ChildItem);
        LibraryMfg.CreateCertifiedProductionBOM(ProdBOMHeader, ChildItem."No.", 1);

        Item.Validate("Production BOM No.", ProdBOMHeader."No.");
        Item.Modify(true);
        Commit();

        // EXERCISE
        Item.Validate(Type, Item.Type::Service);

        // Check that the Inventory BOM is blank
        Assert.AreEqual(
          '', Item."Production BOM No.",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Production BOM No."), '', Item.Type::Service));

        // Check that it is not possible to have a Production BOM on a Service Item
        asserterror Item.Validate("Production BOM No.", ProdBOMHeader."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');


        // EXERCISE
        Item.Validate(Type, Item.Type::"Non-Inventory");

        // Check that the Inventory BOM is blank
        Assert.AreEqual(
          '', Item."Production BOM No.",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Production BOM No."), '', Item.Type::"Non-Inventory"));

        // Check that it is not possible to have a Production BOM on a Non-Inventory Item
        asserterror Item.Validate("Production BOM No.", ProdBOMHeader."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_ProdRtng()
    var
        Item: Record Item;
        RtngHeader: Record "Routing Header";
    begin
        Initialize();
        CreateInvtItem(Item);

        RtngHeader.FindFirst();
        Item.Validate("Routing No.", RtngHeader."No.");

        // EXERCISE
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);

        // Check that the Routing No. is empty
        Assert.AreEqual(
          '', Item."Routing No.",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Routing No."), '', Item.Type::Service));

        // Check that it is not possible change from reserve = standard
        asserterror Item.Validate("Routing No.", RtngHeader."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        // EXERCISE
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        // Check that the reserve setting is never
        Assert.AreEqual(
          '', Item."Routing No.",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Routing No."), '', Item.Type::"Non-Inventory"));

        // Check that it is not possible change from reserve = standard
        asserterror Item.Validate("Routing No.", RtngHeader."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_AsmBOM()
    var
        Item: Record Item;
        ChildItem: Record Item;
        BOMComp: Record "BOM Component";
    begin
        Initialize();
        CreateInvtItem(ChildItem);
        CreateInvtItem(Item);

        // EXERCISE
        BOMComp.Init();
        BOMComp.Validate("Parent Item No.", Item."No.");
        BOMComp.Validate(Type, BOMComp.Type::Item);
        BOMComp.Validate("No.", ChildItem."No.");
        BOMComp.Insert(true);
        Commit();

        asserterror Item.Validate(Type, Item.Type::Service);
        Assert.ExpectedTestFieldError(Item.FieldCaption("Assembly BOM"), '');
        asserterror ChildItem.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        Assert.ExpectedTestFieldError(Item.FieldCaption("Assembly BOM"), Format(false));
        asserterror ChildItem.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');

        asserterror ChildItem.Delete(true);
        AssertRunTime('You cannot delete Item', '');

        BOMComp.Delete(true);

        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);

        BOMComp.Init();
        asserterror BOMComp.Validate("Parent Item No.", Item."No.");
        AssertRunTime('The field Parent Item No.', '');

        BOMComp.Delete(true);

        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        BOMComp.Init();
        asserterror BOMComp.Validate("Parent Item No.", Item."No.");
        AssertRunTime('The field Parent Item No.', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_ATO()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);

        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");

        // EXERCISE
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);

        // Check that Assembly policy is Assemble to Stock
        Assert.AreEqual(
          Item."Assembly Policy"::"Assemble-to-Stock", Item."Assembly Policy",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Assembly Policy"), Item."Assembly Policy"::"Assemble-to-Stock", Item.Type::Service));

        // EXERCISE
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        // Check that the reserve setting is never
        Assert.AreEqual(
          Item."Assembly Policy"::"Assemble-to-Stock", Item."Assembly Policy",
          StrSubstNo('%1 must be %2 when Type is %3',
            Item.FieldName("Assembly Policy"), Item."Assembly Policy"::"Assemble-to-Stock", Item.Type::"Non-Inventory"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_Planning()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);

        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);

        CreateItemAndTestPlanning(Item, true);
        CreateItemAndTestPlanning(Item, false);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestItem_OrderTracking()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);

        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");

        CreateItemAndTestOrderTracking(Item, true);
        CreateItemAndTestOrderTracking(Item, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_SKU()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
    begin
        Initialize();
        CreateInvtItem(Item);

        // EXERCISE
        SKU.Init();
        SKU.Validate("Item No.", Item."No.");
        SKU.Validate("Location Code", FindLocation());
        SKU.Insert(true);

        asserterror Item.Validate(Type, Item.Type::Service);
        Assert.ExpectedTestFieldError(Item.FieldCaption("Stockkeeping Unit Exists"), Format(false));

        SKU.Validate("Item No.", Item."No.");
        SKU.Insert(true);

        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        Assert.ExpectedTestFieldError(Item.FieldCaption("Stockkeeping Unit Exists"), Format(false));

        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);

        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        SKU.Init();
        asserterror SKU.Validate("Item No.", Item."No.");
        AssertRunTime('The field Item No.', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemJnlLineServiceItems()
    var
        ItemJnlLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // [Scenario] You should not be able to use service items on any entry type of item journal line.
        Initialize();
        CreateServItem(Item);

        // EXERCISE
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::" ");
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Assembly Consumption");
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Assembly Output");
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Purchase);
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Sale);
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemJnlLineNonInvtItems()
    var
        ItemJnlLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // [Scenario] You should only be able to use non-inventory items in item journal line if the entry type is 
        // consumption or assembly consumption.
        Initialize();
        CreateNonInvItem(Item);

        // EXERCISE
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::" ");
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Assembly Consumption");
        ItemJnlLine.Validate("Item No.", Item."No.");

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Assembly Output");
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.Validate("Item No.", Item."No.");

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Purchase);
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Sale);
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
        asserterror ItemJnlLine.Validate("Item No.", Item."No.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtReqJnlLine()
    var
        Item: Record Item;
        ChildItem: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);
        CreateInvtItem(ChildItem);

        // EXERCISE
        CreateReqLine(Item, ChildItem);

        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');

        asserterror ChildItem.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror ChildItem.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');
        asserterror ChildItem.Delete(true);
        AssertRunTime('You cannot delete Item', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_SalesDoc()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        CreateServItem(Item);
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        LibrarySales.CreateCustomer(Cust);

        // EXERCISE
        CreateSalesOrder(Cust, SalesHeader, SalesLine, Item);

        asserterror Item.Validate(Type, Item.Type::Inventory);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckEntries(Item);

        asserterror Item.Validate(Type, Item.Type::Inventory);
        AssertRunTime('You cannot change the Type field', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtItem_SalesDoc()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        CreateInvtItem(Item);

        LibrarySales.CreateCustomer(Cust);

        // EXERCISE
        CreateSalesOrder(Cust, SalesHeader, SalesLine, Item);

        asserterror Item.Validate(Type, Item.Type::Inventory);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckEntries(Item);

        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');

        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestServItem_LocationSalesDocCust()
    var
        Item: Record Item;
        Cust: Record Customer;
        Cust2: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        Initialize();
        CreateServItem(Item);

        LibrarySales.CreateCustomer(Cust);

        LibrarySales.CreateCustomer(Cust2);
        Cust2.Validate("Location Code", FindLocation());
        Cust2.Modify(true);

        CreateSalesOrder(Cust, SalesHeader, SalesLine, Item);

        // EXERCISE
        SalesHeader.Validate("Sell-to Customer No.", Cust2."No.");
        SalesHeader.Modify(true);
        Assert.AreEqual('', SalesLine."Location Code", '');

        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        CreateInvtItem(Item);

        // Type <> Type::Item
        SalesLine2.Validate(Type, SalesLine.Type::" ");
        SalesLine2.Validate("Location Code", '');
        SalesLine2.Validate("Location Code", Cust2."Location Code");
        Assert.AreEqual(Cust2."Location Code", SalesLine2."Location Code", '');

        // Type = Type::Item, No. = ''
        SalesLine2.Validate(Type, SalesLine2.Type::Item);
        SalesLine2.Validate("No.", '');
        SalesLine2.Validate("Location Code", Cust2."Location Code");
        Assert.AreEqual(Cust2."Location Code", SalesLine2."Location Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_LocationSalesDoc()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        CreateServItem(Item);

        CreateCustWithLocation(Cust);

        // EXERCISE
        CreateSalesOrder(Cust, SalesHeader, SalesLine, Item);

        Assert.AreEqual(Cust."Location Code", SalesLine."Location Code", '');

        LibraryInventory.CreateNonInventoryTypeItem(Item);
        CreateCustWithLocation(Cust);

        // EXERCISE
        CreateSalesOrder(Cust, SalesHeader, SalesLine, Item);

        Assert.AreEqual(Cust."Location Code", SalesLine."Location Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtItem_LocationSalesDoc()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        CreateInvtItem(Item);

        CreateCustWithLocation(Cust);

        // EXERCISE
        CreateSalesOrder(Cust, SalesHeader, SalesLine, Item);

        SalesLine.Validate("Location Code", Cust."Location Code");

        Assert.AreEqual(Cust."Location Code", SalesLine."Location Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_LocationMandatorySalesDoc()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvtSetup: Record "Inventory Setup";
        OldInvtSetup: Record "Inventory Setup";
    begin
        Initialize();
        CreateServItem(Item);

        LibrarySales.CreateCustomer(Cust);

        InvtSetup.Get();
        OldInvtSetup := InvtSetup;
        InvtSetup.Validate("Location Mandatory", true);
        InvtSetup.Modify();

        // EXERCISE
        CreateSalesOrder(Cust, SalesHeader, SalesLine, Item);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckEntries(Item);

        InvtSetup.Validate("Location Mandatory", OldInvtSetup."Location Mandatory");
        InvtSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtItem_LocationMandatorySalesDoc()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvtSetup: Record "Inventory Setup";
        OldInvtSetup: Record "Inventory Setup";
    begin
        Initialize();
        CreateInvtItem(Item);

        LibrarySales.CreateCustomer(Cust);

        InvtSetup.Get();
        OldInvtSetup := InvtSetup;
        InvtSetup.Validate("Location Mandatory", true);
        InvtSetup.Modify();

        CreateSalesOrder(Cust, SalesHeader, SalesLine, Item);

        // EXERCISE
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesLine.Validate("Location Code", FindLocation());
        SalesLine.Modify(true);

        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckEntries(Item);

        InvtSetup.Validate("Location Mandatory", OldInvtSetup."Location Mandatory");
        InvtSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_PurchDoc()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();
        CreateServItem(Item);

        LibraryPurch.CreateVendor(Vend);

        // EXERCISE
        CreatePurchOrder(Vend, PurchHeader, PurchLine, Item);

        asserterror Item.Validate(Type, Item.Type::Inventory);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');

        LibraryPurch.PostPurchaseDocument(PurchHeader, true, true);

        CheckEntries(Item);

        asserterror Item.Validate(Type, Item.Type::Inventory);
        AssertRunTime('You cannot change the Type field', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtItem_PurchDoc()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();
        CreateInvtItem(Item);

        LibraryPurch.CreateVendor(Vend);

        // EXERCISE
        CreatePurchOrder(Vend, PurchHeader, PurchLine, Item);

        asserterror Item.Validate(Type, Item.Type::Inventory);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');

        LibraryPurch.PostPurchaseDocument(PurchHeader, true, true);

        CheckEntries(Item);

        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_LocationPurchDocVend()
    var
        Item: Record Item;
        Vend: Record Vendor;
        Vend2: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();
        PurchHeader.DontNotifyCurrentUserAgain(PurchHeader.GetModifyVendorAddressNotificationId());
        PurchHeader.DontNotifyCurrentUserAgain(PurchHeader.GetModifyPayToVendorAddressNotificationId());
        CreateServItem(Item);

        LibraryPurch.CreateVendor(Vend);
        CreateVendWithLocation(Vend2);

        CreatePurchOrder(Vend, PurchHeader, PurchLine, Item);

        // EXERCISE
        PurchHeader.SetHideValidationDialog(true);
        PurchHeader.Validate("Buy-from Vendor No.", Vend2."No.");
        PurchHeader.Modify(true);

        // Verify
        PurchLine.Find();
        Assert.AreEqual(Vend2."Location Code", PurchLine."Location Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_LocationPurchDoc()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        Initialize();
        CreateServItem(Item);

        CreateVendWithLocation(Vend);

        // EXERCISE
        CreatePurchOrder(Vend, PurchHeader, PurchLine, Item);

        Assert.AreEqual(Vend."Location Code", PurchLine."Location Code", '');

        LibraryInventory.CreateNonInventoryTypeItem(Item);
        // EXERCISE
        CreatePurchOrder(Vend, PurchHeader, PurchLine, Item);

        Assert.AreEqual(Vend."Location Code", PurchLine."Location Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtItem_LocationPurchDoc()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        Initialize();
        CreateInvtItem(Item);

        CreateVendWithLocation(Vend);

        CreatePurchOrder(Vend, PurchHeader, PurchLine, Item);

        // EXERCISE
        PurchLine.Validate("Location Code", Vend."Location Code");

        Assert.AreEqual(Vend."Location Code", PurchLine."Location Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_LocationMandatoryPurchDoc()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        InvtSetup: Record "Inventory Setup";
        OldInvtSetup: Record "Inventory Setup";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();
        CreateServItem(Item);

        LibraryPurch.CreateVendor(Vend);

        InvtSetup.Get();
        OldInvtSetup := InvtSetup;
        InvtSetup.Validate("Location Mandatory", true);
        InvtSetup.Modify();

        CreatePurchOrder(Vend, PurchHeader, PurchLine, Item);

        // EXERCISE
        LibraryPurch.PostPurchaseDocument(PurchHeader, true, true);

        InvtSetup.Validate("Location Mandatory", OldInvtSetup."Location Mandatory");
        InvtSetup.Modify();

        LibraryInventory.CreateNonInventoryTypeItem(Item);
        CreatePurchOrder(Vend, PurchHeader, PurchLine, Item);

        // EXERCISE
        LibraryPurch.PostPurchaseDocument(PurchHeader, true, true);

        CheckEntries(Item);

        InvtSetup.Validate("Location Mandatory", OldInvtSetup."Location Mandatory");
        InvtSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtItem_LocationMandatoryPurchDoc()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        InvtSetup: Record "Inventory Setup";
        OldInvtSetup: Record "Inventory Setup";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();
        CreateInvtItem(Item);

        LibraryPurch.CreateVendor(Vend);

        InvtSetup.Get();
        OldInvtSetup := InvtSetup;
        InvtSetup.Validate("Location Mandatory", true);
        InvtSetup.Modify();

        CreatePurchOrder(Vend, PurchHeader, PurchLine, Item);

        // EXERCISE
        asserterror LibraryPurch.PostPurchaseDocument(PurchHeader, true, true);

        PurchLine.Validate("Location Code", FindLocation());
        PurchLine.Modify(true);

        PurchHeader.Find();
        LibraryPurch.PostPurchaseDocument(PurchHeader, true, true);

        CheckEntries(Item);

        InvtSetup.Validate("Location Mandatory", OldInvtSetup."Location Mandatory");
        InvtSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_AsmDoc()
    var
        Item: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        Initialize();
        CreateServItem(Item);

        // EXERCISE
        AsmHeader.Init();
        asserterror AsmHeader.Validate("Item No.", Item."No.");
        AssertRunTime('The field Item No. of table Assembly Header', '');

        AsmLine.Init();
        AsmLine.Validate(Type, AsmLine.Type::Item);
        asserterror AsmLine.Validate("No.", Item."No.");
        AssertRunTime('The field No. of table Assembly Line', '');

        LibraryInventory.CreateNonInventoryTypeItem(Item);
        // EXERCISE
        AsmHeader.Init();
        asserterror AsmHeader.Validate("Item No.", Item."No.");
        AssertRunTime('The field Item No. of table Assembly Header', '');

        AsmLine.Init();
        AsmLine.Validate(Type, AsmLine.Type::Item);
        asserterror AsmLine.Validate("No.", Item."No.");
        AssertRunTime('The field No. of table Assembly Line', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtItem_AsmDoc()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);

        CreateAsmOrder(Item);

        // EXERCISE
        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');

        // EXERCISE
        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_ServDoc()
    begin
        Initialize();

        CreateItemAndTestServDoc(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonInventoryItem_ServDoc()
    begin
        Initialize();

        CreateItemAndTestServDoc(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_JobDoc()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
    begin
        Initialize();
        CreateServItem(Item);

        // EXERCISE
        Item.Validate(Type, Item.Type::Inventory);
        Item.Modify(true);

        JobPlanningLine.Init();
        JobPlanningLine.Type := JobPlanningLine.Type::Item;
        JobPlanningLine."No." := Item."No.";
        JobPlanningLine.Insert();
        Commit();

        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');

        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_ProdDoc()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        Initialize();
        CreateServItem(Item);

        // EXERCISE
        ProdOrder.Init();
        ProdOrder."Source Type" := ProdOrder."Source Type"::Item;
        asserterror ProdOrder.Validate("Source No.", Item."No.");
        AssertRunTime('The field Source No. of table Production Order', '');

        ProdOrderLine.Init();
        asserterror ProdOrderLine.Validate("Item No.", Item."No.");
        AssertRunTime('The field Item No. of table Prod. Order Line', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtItem_ProdDoc()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);

        // EXERCISE
        CreateProdOrder(Item);

        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvtItem_TransferDoc()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);

        // EXERCISE
        CreateTransOrder(Item);
        Commit();

        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItem_TransferDoc()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateServItem(Item);

        // EXERCISE
        asserterror CreateTransOrder(Item);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), Format(Item.Type::Inventory));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_Type_Invt_With_ILE()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateInvtItem(Item);

        // EXERCISE
        CreateAndPostItemJnlLine(Item, 1);

        // Check that it is not possible change from inventory to service when inventory <> 0
        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');

        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');

        // Make inventory go to zero
        CreateAndPostItemJnlLine(Item, -1);

        // Check that it is not possible change from inventory to service when inventory = 0
        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Validate(Type, Item.Type::"Non-Inventory");
        AssertRunTime('You cannot change the Type field', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItem_Type_Service_Posting()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        Initialize();
        CreateServItem(Item);

        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        Commit();

        // EXERCISE
        // Check that it is not possible to create an an item journal line when type = service
        asserterror
          LibraryInventory.CreateItemJournalLine(
            ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::Purchase, Item."No.", 1);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');

        // Check that it is possible to create an an item journal line when type = inventory
        Item.Validate(Type, Item.Type::Inventory);
        Item.Modify(true);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::Purchase, Item."No.", 1);

        // Check that it is not possible to post an item journal line when type = service
        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingUndoReceiptForItemTypeService()
    begin
        // [FEATURE] [Purchase] [Undo Receipt]
        // [SCENARIO 212144] Undo Receipt of item with Type = Service can be posted. The resulting item ledger entry should be closed.
        Initialize();

        CreateItemAndTestPostingUndoReceipt(true);
        CreateItemAndTestPostingUndoReceipt(false);
    end;

    [Scope('OnPrem')]
    procedure CreateItemAndTestReplenishmentSystem(Item: Record Item; IsService: Boolean)
    begin
        // EXERCISE
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        if IsService then
            Item.Validate(Type, Item.Type::Service)
        else
            Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        // VERIFY
        // Check that the replenishment system is Purchase
        if IsService then
            Assert.AreEqual(
              Item."Replenishment System"::Purchase, Item."Replenishment System",
              StrSubstNo('%1 must be %2 when Type is %3',
                Item.FieldName("Replenishment System"), Item."Replenishment System"::Purchase, Item.Type::Service))
        else
            Assert.AreEqual(
              Item."Replenishment System"::Purchase, Item."Replenishment System",
              StrSubstNo('%1 must be %2 when Type is %3',
                Item.FieldName("Replenishment System"), Item."Replenishment System"::Purchase, Item.Type::"Non-Inventory"));

        // Check that it is not possible change from replenishment system = Purchase
        asserterror Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Scope('OnPrem')]
    procedure CreateItemAndTestInventoryPostingGroup(Item: Record Item; InventoryPostingGr: Record "Inventory Posting Group"; IsService: Boolean)
    begin
        // EXERCISE
        if IsService then
            Item.Validate(Type, Item.Type::Service)
        else
            Item.Validate(Type, Item.Type::"Non-Inventory");

        // VERIFY
        if IsService then
            Assert.AreEqual(
              Item."Inventory Posting Group", '',
              StrSubstNo('%1 must be %2 when Type is %3',
                Item.FieldName("Inventory Posting Group"), '', Item.Type::Service))
        else
            Assert.AreEqual(
              Item."Inventory Posting Group", '',
              StrSubstNo('%1 must be %2 when Type is %3',
                Item.FieldName("Inventory Posting Group"), '', Item.Type::"Non-Inventory"));

        asserterror Item.Validate("Inventory Posting Group", InventoryPostingGr.Code);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Scope('OnPrem')]
    procedure CreateItemAndTestPlanning(Item: Record Item; IsService: Boolean)
    begin
        // EXERCISE
        if IsService then
            Item.Validate(Type, Item.Type::Service)
        else
            Item.Validate(Type, Item.Type::"Non-Inventory");

        Item.Modify(true);

        // Check that the reordering policy is empty
        if IsService then
            Assert.AreEqual(
              Item."Reordering Policy"::" ", Item."Reordering Policy",
              StrSubstNo('%1 must be %2 when Type is %3',
                Item.FieldName("Reordering Policy"), '', Item.Type::Service))
        else
            Assert.AreEqual(
              Item."Reordering Policy"::" ", Item."Reordering Policy",
              StrSubstNo('%1 must be %2 when Type is %3',
                Item.FieldName("Reordering Policy"), '', Item.Type::"Non-Inventory"));

        // Check that it is not possible change from reordering policy = empty
        asserterror Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Scope('OnPrem')]
    procedure CreateItemAndTestOrderTracking(Item: Record Item; IsService: Boolean)
    begin
        // EXERCISE
        if IsService then
            Item.Validate(Type, Item.Type::Service)
        else
            Item.Validate(Type, Item.Type::"Non-Inventory");

        Item.Modify(true);

        // Check that the reserve setting is never
        if IsService then
            Assert.AreEqual(
              Item."Order Tracking Policy"::None, Item."Order Tracking Policy",
              StrSubstNo('%1 must be %2 when Type is %3',
                Item.FieldName("Order Tracking Policy"), Item."Order Tracking Policy"::None, Item.Type::Service))
        else
            Assert.AreEqual(
              Item."Order Tracking Policy"::None, Item."Order Tracking Policy",
              StrSubstNo('%1 must be %2 when Type is %3',
                Item.FieldName("Order Tracking Policy"), Item."Order Tracking Policy"::None, Item.Type::"Non-Inventory"));

        // Check that it is not possible change from reserve = standard
        asserterror Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
        asserterror Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), '');
    end;

    [Scope('OnPrem')]
    procedure CreateItemAndTestServDoc(IsService: Boolean)
    var
        Item: Record Item;
        ServLine: Record "Service Line";
        ServContractLine: Record "Service Contract Line";
    begin
        if IsService then
            CreateServItem(Item)
        else begin
            LibraryInventory.CreateNonInventoryTypeItem(Item);
            Commit();
        end;
        // EXERCISE
        ServLine.Init();
        ServLine.Type := ServLine.Type::Item;
        // ASSERTERROR ServLine.VALIDATE("No.",Item."No.");
        // AssertRunTime('The field No. of table Service Line','');

        ServContractLine.Init();
        asserterror ServContractLine.Validate("Item No.", Item."No.");
        AssertRunTime('The field Item No. of table Service Contract Line', '');

        // Check for Service Line
        Item.Validate(Type, Item.Type::Inventory);
        Item.Modify(true);

        ServLine.Init();
        ServLine.Type := ServLine.Type::Item;
        ServLine."No." := Item."No.";
        ServLine.Insert();
        Commit();

        if IsService then
            asserterror Item.Validate(Type, Item.Type::Service)
        else
            asserterror Item.Validate(Type, Item.Type::"Non-Inventory");

        AssertRunTime('You cannot change the Type field', '');
        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');
        // Check for Service Contract Line
        ServLine.Delete();

        ServContractLine.Init();
        ServContractLine."Item No." := Item."No.";
        ServContractLine.Insert();
        Commit();

        if IsService then
            asserterror Item.Validate(Type, Item.Type::Service)
        else
            asserterror Item.Validate(Type, Item.Type::"Non-Inventory");

        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');

        ServContractLine.Delete();
    end;

    [Scope('OnPrem')]
    procedure CreateItemAndTestPostingUndoReceipt(IsService: Boolean)
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchReceiptNo: Code[20];
    begin
        // [GIVEN] Item with Type = Service.
        if IsService then
            CreateServItem(Item)
        else begin
            LibraryInventory.CreateNonInventoryTypeItem(Item);
            Commit();
        end;

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Posted purchase receipt for the item.
        CreatePurchOrder(Vendor, PurchaseHeader, PurchaseLine, Item);
        PurchReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Undo the receipt.
        FindPurchReceiptLine(PurchRcptLine, PurchReceiptNo, Item."No.");
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] The posted receipt is reversed.
        FindPurchReceiptLine(PurchRcptLine, PurchReceiptNo, Item."No.");
        Assert.RecordCount(PurchRcptLine, 2);
        PurchRcptLine.CalcSums(Quantity);
        PurchRcptLine.TestField(Quantity, 0);

        // [THEN] Reversed item ledger entry is created.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange(Positive, false);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, -1);

        // [THEN] Resulting item ledger entries are closed.
        CheckEntries(Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseShipmentForSalesNotCreatedForItemTypeService()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Item Type Service] [Warehouse Shipment] [Sales] [Order]
        // [SCENARIO 274813] When you run "Create Whse. Shipment" from sales order that contains only items type of "Service", no warehouse shipment lines are created.
        Initialize();

        // [GIVEN] Enable "Require Shipment" on warehouse setup.
        LibraryWarehouse.SetRequireShipmentOnWarehouseSetup(true);

        // [GIVEN] Item "I" with Type = "Service".
        LibraryInventory.CreateServiceTypeItem(Item);

        // [GIVEN] Released sales order for item "I".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create warehouse shipment from the sales order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] No warehouse shipment lines are created.
        WarehouseShipmentLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseShipmentLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseShipmentForSalesCreatedOnlyForItemTypeInventory()
    var
        ItemTypeService: Record Item;
        ItemTypeInventory: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Item Type Service] [Warehouse Shipment] [Sales] [Order]
        // [SCENARIO 274813] When you run "Create Whse. Shipment" from sales order that contains items of both "Service" and "Inventory" types, warehouse shipment lines only for inventory items are created.
        Initialize();

        // [GIVEN] Enable "Require Shipment" on warehouse setup.
        LibraryWarehouse.SetRequireShipmentOnWarehouseSetup(true);

        // [GIVEN] Item "I-Serv" with Type = "Service".
        // [GIVEN] Item "I-Invt" with Type = "Inventory".
        LibraryInventory.CreateServiceTypeItem(ItemTypeService);
        LibraryInventory.CreateItem(ItemTypeInventory);

        // [GIVEN] Released sales order for items "I-Serv", "I-Invt".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemTypeService."No.", LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemTypeInventory."No.", LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create warehouse shipment from the sales order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] No warehouse shipment lines are created for item "I-Serv".
        WarehouseShipmentLine.SetRange("Item No.", ItemTypeService."No.");
        Assert.RecordIsEmpty(WarehouseShipmentLine);

        // [THEN] A warehouse shipment line is created for item "I-Invt".
        WarehouseShipmentLine.SetRange("Item No.", ItemTypeInventory."No.");
        Assert.RecordIsNotEmpty(WarehouseShipmentLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseShipmentForPurchaseNotCreatedForItemTypeService()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Item Type Service] [Warehouse Shipment] [Purchase] [Return Order]
        // [SCENARIO 274813] When you run "Create Whse. Shipment" from purchase return order that contains only items type of "Service", no warehouse shipment lines are created.
        Initialize();

        // [GIVEN] Enable "Require Shipment" on warehouse setup.
        LibraryWarehouse.SetRequireShipmentOnWarehouseSetup(true);

        // [GIVEN] Item "I" with Type = "Service".
        LibraryInventory.CreateServiceTypeItem(Item);

        // [GIVEN] Released purchase return order for item "I".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Create warehouse shipment from the purchase return order.
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);

        // [THEN] No warehouse shipment lines are created.
        WarehouseShipmentLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseShipmentLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseShipmentForPurchaseCreatedOnlyForItemTypeInventory()
    var
        ItemTypeService: Record Item;
        ItemTypeInventory: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Item Type Service] [Warehouse Shipment] [Purchase] [Return Order]
        // [SCENARIO 274813] When you run "Create Whse. Shipment" from purchase return order that contains items of both "Service" and "Inventory" types, warehouse shipment lines only for inventory items are created.
        Initialize();

        // [GIVEN] Enable "Require Shipment" on warehouse setup.
        LibraryWarehouse.SetRequireShipmentOnWarehouseSetup(true);

        // [GIVEN] Item "I-Serv" with Type = "Service".
        // [GIVEN] Item "I-Invt" with Type = "Inventory".
        LibraryInventory.CreateServiceTypeItem(ItemTypeService);
        LibraryInventory.CreateItem(ItemTypeInventory);

        // [GIVEN] Released purchase return order for items "I-Serv", "I-Invt".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemTypeService."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemTypeInventory."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Create warehouse shipment from the purchase return order.
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);

        // [THEN] No warehouse shipment lines are created for item "I-Serv".
        WarehouseShipmentLine.SetRange("Item No.", ItemTypeService."No.");
        Assert.RecordIsEmpty(WarehouseShipmentLine);

        // [THEN] A warehouse shipment line is created for item "I-Invt".
        WarehouseShipmentLine.SetRange("Item No.", ItemTypeInventory."No.");
        Assert.RecordIsNotEmpty(WarehouseShipmentLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseReceiptForPurchaseNotCreatedForItemTypeService()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // [FEATURE] [Item Type Service] [Warehouse Receipt] [Purchase] [Order]
        // [SCENARIO 274813] When you run "Create Whse. Receipt" from purchase order that contains only items type of "Service", no warehouse receipt lines are created.
        Initialize();

        // [GIVEN] Enable "Require Receive" on warehouse setup.
        LibraryWarehouse.SetRequireReceiveOnWarehouseSetup(true);

        // [GIVEN] Item "I" with Type = "Service".
        LibraryInventory.CreateServiceTypeItem(Item);

        // [GIVEN] Released purchase order for item "I".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Create warehouse receipt from the purchase order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] No warehouse receipt lines are created.
        WarehouseReceiptLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseReceiptLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseReceiptForPurchaseCreatedOnlyForItemTypeInventory()
    var
        ItemTypeService: Record Item;
        ItemTypeInventory: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // [FEATURE] [Item Type Service] [Warehouse Receipt] [Purchase] [Order]
        // [SCENARIO 274813] When you run "Create Whse. Receipt" from purchase order that contains items of both "Service" and "Inventory" types, warehouse receipt lines only for inventory items are created.
        Initialize();

        // [GIVEN] Enable "Require Receive" on warehouse setup.
        LibraryWarehouse.SetRequireReceiveOnWarehouseSetup(true);

        // [GIVEN] Item "I-Serv" with Type = "Service".
        // [GIVEN] Item "I-Invt" with Type = "Inventory".
        LibraryInventory.CreateServiceTypeItem(ItemTypeService);
        LibraryInventory.CreateItem(ItemTypeInventory);

        // [GIVEN] Released purchase order for items "I-Serv", "I-Invt".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemTypeService."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemTypeInventory."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Create warehouse receipt from the purchase order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] No warehouse receipt lines are created for item "I-Serv".
        WarehouseReceiptLine.SetRange("Item No.", ItemTypeService."No.");
        Assert.RecordIsEmpty(WarehouseReceiptLine);

        // [THEN] A warehouse receipt line is created for item "I-Invt".
        WarehouseReceiptLine.SetRange("Item No.", ItemTypeInventory."No.");
        Assert.RecordIsNotEmpty(WarehouseReceiptLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseReceiptForSalesNotCreatedForItemTypeService()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // [FEATURE] [Item Type Service] [Warehouse Receipt] [Sales] [Return Order]
        // [SCENARIO 274813] When you run "Create Whse. Receipt" from sales return order that contains only items type of "Service", no warehouse receipt lines are created.
        Initialize();

        // [GIVEN] Enable "Require Receive" on warehouse setup.
        LibraryWarehouse.SetRequireReceiveOnWarehouseSetup(true);

        // [GIVEN] Item "I" with Type = "Service".
        LibraryInventory.CreateServiceTypeItem(Item);

        // [GIVEN] Released sales return order for item "I".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create warehouse receipt from the sales return order.
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);

        // [THEN] No warehouse receipt lines are created.
        WarehouseReceiptLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseReceiptLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseReceiptForSalesCreatedOnlyForItemTypeInventory()
    var
        ItemTypeService: Record Item;
        ItemTypeInventory: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // [FEATURE] [Item Type Service] [Warehouse Receipt] [Sales] [Return Order]
        // [SCENARIO 274813] When you run "Create Whse. Receipt" from sales return order that contains items of both "Service" and "Inventory" types, warehouse receipt lines only for inventory items are created.
        Initialize();

        // [GIVEN] Enable "Require Receive" on warehouse setup.
        LibraryWarehouse.SetRequireReceiveOnWarehouseSetup(true);

        // [GIVEN] Item "I-Serv" with Type = "Service".
        // [GIVEN] Item "I-Invt" with Type = "Inventory".
        LibraryInventory.CreateServiceTypeItem(ItemTypeService);
        LibraryInventory.CreateItem(ItemTypeInventory);

        // [GIVEN] Released sales return order for items "I-Serv", "I-Invt".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemTypeService."No.", LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemTypeInventory."No.", LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create warehouse receipt from the sales return order.
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);

        // [THEN] No warehouse receipt lines are created for item "I-Serv".
        WarehouseReceiptLine.SetRange("Item No.", ItemTypeService."No.");
        Assert.RecordIsEmpty(WarehouseReceiptLine);

        // [THEN] A warehouse receipt line is created for item "I-Invt".
        WarehouseReceiptLine.SetRange("Item No.", ItemTypeInventory."No.");
        Assert.RecordIsNotEmpty(WarehouseReceiptLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndirectCostAndOverheadRateSetToZeroForNonInventoryItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item Type Service] [UT]
        // [SCENARIO 281018] When you set item Type = "Service", this resets "Overhead Rate" and "Indirect Cost %" to 0.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(100, 2));
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        Item.Validate(Type, Item.Type::Service);

        Item.TestField("Overhead Rate", 0);
        Item.TestField("Indirect Cost %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetIndirectCostForNonInventoryItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item Type Service] [UT]
        // [SCENARIO 281018] Setting non-zero indirect cost % on non-inventory item raises an error.
        Initialize();

        LibraryInventory.CreateServiceTypeItem(Item);

        asserterror Item.Validate("Indirect Cost %", LibraryRandom.RandDec(100, 2));
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), Format(Item.Type::Inventory));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetOverheadRateForNonInventoryItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Item Type Service] [UT]
        // [SCENARIO 281018] Setting non-zero overhead rate on non-inventory item raises an error.
        Initialize();

        LibraryInventory.CreateServiceTypeItem(Item);

        asserterror Item.Validate("Overhead Rate", LibraryRandom.RandDec(100, 2));
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), Format(Item.Type::Inventory));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndirectCostAndOverheadRateAreDisabledOnItemTypeServiceCard()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item Type Service] [UI]
        // [SCENARIO 281018] "Indirect Cost %" and "Overhead Rate" fields can be populated on item card only for inventory-typed item.
        Initialize();

        // [GIVEN] Open item card.
        LibraryInventory.CreateItem(Item);
        ItemCard.OpenEdit();
        ItemCard.GotoKey(Item."No.");

        // [WHEN] Set Type = "Service" on the item card.
        ItemCard.Type.SetValue(Item.Type::Service);

        // [THEN] "Indirect Cost %" and "Overhead Rate" fields have become disabled.
        Assert.IsFalse(ItemCard."Indirect Cost %".Enabled(), 'Indirect Cost % must be disabled on non-inventory item card.');
        Assert.IsFalse(ItemCard."Overhead Rate".Enabled(), 'Overhead Rate must be disabled on non-inventory item card.');

        // [WHEN] Set Type = "Inventory".
        ItemCard.Type.SetValue(Item.Type::Inventory);

        // [THEN] "Indirect Cost %" and "Overhead Rate" fields have become enabled.
        Assert.IsTrue(ItemCard."Indirect Cost %".Enabled(), 'Indirect Cost % must be enabled on inventory item card.');
        Assert.IsTrue(ItemCard."Overhead Rate".Enabled(), 'Overhead Rate must be enabled on inventory item card.');

        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetIndirectCostOnPurchaseLineForNonInventoryItem()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Type Service] [Purchase] [UT]
        // [SCENARIO 281018] Setting "Indirect Cost %" on purchase line for non-inventory item raises an error.
        Initialize();

        LibraryInventory.CreateServiceTypeItem(Item);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        asserterror PurchaseLine.Validate("Indirect Cost %", LibraryRandom.RandDec(100, 2));
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), Format(Item.Type::Inventory));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetIndirectCostOnPurchaseLineAnyTypeExceptOfItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Index: Integer;
    begin
        // [FEATURE] [Item Type Service] [Purchase] [UT]
        // [SCENARIO 394798] System restricts setting "Indirect Cost %" on purchase line when Type is not equal to Item
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Insert(true);
        PurchaseLine.Validate("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseLine.Modify(true);
        Commit();

        for Index := 1 to 5 do begin
            PurchaseLine.Type := "Purchase Line Type".FromInteger(Index);
            PurchaseLine."No." := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(PurchaseLine."No."));
            PurchaseLine.Quantity := LibraryRandom.RandDecInRange(100, 200, 2);
            PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDecInRange(100, 200, 2);
            if PurchaseLine.Type <> PurchaseLine.Type::Item then begin
                asserterror PurchaseLine.Validate("Indirect Cost %", 1 + LibraryRandom.RandIntInRange(1, 99));
                Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Indirect Cost %"), Format(0));
                ClearLastError();

                asserterror PurchaseLine.Validate("Unit Cost (LCY)", Round(PurchaseLine."Direct Unit Cost" * 1.1));
                Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Indirect Cost %"), Format(0));
                ClearLastError();
            end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryForOverheadAmountIsNotPostedForNotInventoriableItem()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Item Type Service]
        // [SCENARIO 281018] Posting purchase invoice for a non-inventory item with non-zero "Indirect Cost %" value (somehow assigned with the code) does not produce value entry for indirect cost.
        Initialize();

        // [GIVEN] Item "I" with Type = Service. Assign a non-zero value to "Indirect Cost %" on the item without field validation.
        LibraryInventory.CreateServiceTypeItem(Item);
        Item."Indirect Cost %" := LibraryRandom.RandDec(100, 2);
        Item.Modify();

        // [GIVEN] Purchase invoice for item "I".
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] No indirect cost has been posted for "I".
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Indirect Cost");
        Assert.RecordIsEmpty(ValueEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingNonInventoryItemDoesNotCheckLocationMandatory()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Location Mandatory]
        // [SCENARIO 286165] Location Mandatory setting in Inventory Setup is not checked when posting non-inventory item that always has blank location code.
        Initialize();

        // [GIVEN] Enable "Location Mandatory" setting in Inventory Setup.
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Item with Type = "Non-Inventory".
        LibraryInventory.CreateNonInventoryTypeItem(Item);

        // [GIVEN] Sales order with the non-inventory item and blank location code.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        // [WHEN] Ship the sales order.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] The sales order is shipped.
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyLineForNonInventoryItemSetsLocationCode()
    var
        Location: Record Location;
        AsmItem: Record Item;
        CompNonInvtItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Assembly]
        // [SCENARIO] Assembly line for non-inventory item supports location code.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Assembly item "A" with non-inventory item "C" as a component.
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateNonInventoryTypeItem(CompNonInvtItem);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompNonInvtItem."No.", AsmItem."No.", '', 0, LibraryRandom.RandInt(10), true);

        // [GIVEN] Assembly order for item "A" on location "L".
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, LibraryRandom.RandDate(10), AsmItem."No.", Location.Code, 0, '');

        // [WHEN] Set non-zero quantity to assemble.
        AssemblyHeader.Validate(Quantity, LibraryRandom.RandInt(10));
        AssemblyHeader.Modify(true);

        // [THEN] Location Code is set on the assembly line for non-inventory item "C".
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange("No.", CompNonInvtItem."No.");
        AssemblyLine.FindFirst();
        AssemblyLine.TestField("Location Code", Location.Code);

        // [THEN] No availability warning is shown.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingAssemblyConsumptionForNonInventoryItemSetsLocation()
    var
        Location: Record Location;
        AsmItem: Record Item;
        CompNonInvtItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Assembly]
        // [SCENARIO] When posting assembly consumption of non-inventory item, the location is set.
        Initialize();

        // [GIVEN] Enable "Location Mandatory" setting in Inventory Setup.
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Assembly item "A" with non-inventory item "C" as a component.
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateNonInventoryTypeItem(CompNonInvtItem);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompNonInvtItem."No.", AsmItem."No.", '', 0, LibraryRandom.RandInt(10), true);

        // [GIVEN] Assembly order for item "A" on location "L".
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, LibraryRandom.RandDate(10), AsmItem."No.", Location.Code, LibraryRandom.RandInt(10), '');

        // [WHEN] Post the assembly order.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] The assembly consumption of non-inventory item "C" is successfully posted with location set.
        PostedAssemblyLine.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyLine.SetRange("No.", CompNonInvtItem."No.");
        PostedAssemblyLine.FindFirst();
        PostedAssemblyLine.TestField("Location Code", Location.Code);
    end;

    [Test]
    [HandlerFunctions('AssemblyAvailabilityModalPageHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssemblyAvailabilityPageDoesNotShowShortageOfNonInventoryComponents()
    var
        AsmItem: Record Item;
        CompInvtItem: Record Item;
        CompNonInvtItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Non-Inventory Item] [Assembly] [Availability]
        // [SCENARIO 301348] Assembly availability page does not show non-inventoriable items.
        Initialize();

        // [GIVEN] Assembly item "A" with two components: an inventoriable item "I" and non-inventoriable item "NI".
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateItem(CompInvtItem);
        LibraryInventory.CreateNonInventoryTypeItem(CompNonInvtItem);

        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompInvtItem."No.", AsmItem."No.", '', 0, LibraryRandom.RandInt(10), true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompNonInvtItem."No.", AsmItem."No.", '', 0, LibraryRandom.RandInt(10), true);

        // [GIVEN] Assembly order for item "A".
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, LibraryRandom.RandDate(10), AsmItem."No.", '', 0, '');

        // [WHEN] Set non-zero quantity to assemble.
        LibraryVariableStorage.Enqueue(CompInvtItem."No.");
        LibraryVariableStorage.Enqueue(CompNonInvtItem."No.");
        AssemblyHeader.Validate(Quantity, LibraryRandom.RandInt(10));

        // [THEN] An assembly availability page is raised.
        // [THEN] Inventoriable item "I" is shown on the page.
        // [THEN] Non-inventoriable item "NI" is not shown on the page.
        // The verification is done in AssemblyAvailabilityModalPageHandler.

        LibraryVariableStorage.AssertEmpty();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LocationCodeNotPropagatedToNonInventoriableAssemblyLine()
    var
        Location: Record Location;
        AsmItem: Record Item;
        CompInvtItem: Record Item;
        CompNonInvtItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Assembly]
        // [SCENARIO 309827] When you update location code on assembly header, it propagates to assembly lines for non-inventory items.
        Initialize();

        LibraryAssembly.SetStockoutWarning(false);

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Assembly item "A" with two components: an inventoriable item "I" and non-inventoriable item "NI".
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateItem(CompInvtItem);
        LibraryInventory.CreateNonInventoryTypeItem(CompNonInvtItem);

        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompInvtItem."No.", AsmItem."No.", '', 0, LibraryRandom.RandInt(10), true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompNonInvtItem."No.", AsmItem."No.", '', 0, LibraryRandom.RandInt(10), true);

        // [GIVEN] Assembly order for item "A", location code = blank.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, LibraryRandom.RandDate(10), AsmItem."No.", '', LibraryRandom.RandInt(10), '');

        // [WHEN] Set location code = "L" on the assembly header.
        AssemblyHeader.Validate("Location Code", Location.Code);

        // [THEN] Location code is set on the line for non-inventory item "NI".
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange("No.", CompNonInvtItem."No.");
        AssemblyLine.FindFirst();
        AssemblyLine.TestField("Location Code", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetUnitCostAndUpdateIndirectCostPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExpectedIndirectPercent: Decimal;
        ExpectedUnitCost: Decimal;
    begin
        // [FEATURE] [Item Type Service] [Purchase] [UT]
        // [SCENARIO 394798] Stan can update "Unit Cost (LCY)" on Purchase Line and system updates "Indirect Cost %".
        Initialize();

        GeneralLedgerSetup.GetRecordOnce();
        GeneralLedgerSetup."Unit-Amount Rounding Precision" := 0.0000001;
        GeneralLedgerSetup.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2));

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);

        PurchaseLine.TestField("Indirect Cost %", 0);

        ExpectedIndirectPercent := 10;
        ExpectedUnitCost := Round(PurchaseLine."Direct Unit Cost" * (100 + ExpectedIndirectPercent) / 100);

        PurchaseLine.Validate("Unit Cost (LCY)", ExpectedUnitCost);
        PurchaseLine.Modify(true);

        GeneralLedgerSetup.GetRecordOnce();
        ExpectedIndirectPercent :=
            Round((PurchaseLine."Unit Cost (LCY)" - PurchaseLine."Direct Unit Cost") * 100 / PurchaseLine."Direct Unit Cost", 0.00001);
        // we have fixed rounding precision
        PurchaseLine.TestField("Unit Cost (LCY)", ExpectedUnitCost);
        PurchaseLine.TestField("Indirect Cost %", ExpectedIndirectPercent);
    end;

    [Test]
    procedure ReleasingShipmentForATOItemWithNonInventoryComponent()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
        AsmItem: Record Item;
        CompNonInvtItem: Record Item;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Assembly] [Warehouse Shipment]
        // [SCENARIO 397522] Releasing shipment for assemble-to-order item with non-inventory component does not check bin code.
        Initialize();

        // [GIVEN] Location "L" with required shipment and mandatory bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Assemble-to-order item "A".
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Modify(true);

        // [GIVEN] Non-inventory assembly component "C".
        LibraryInventory.CreateNonInventoryTypeItem(CompNonInvtItem);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompNonInvtItem."No.", AsmItem."No.", '', 0, 1, true);

        // [GIVEN] Sales order for "A" at location "L".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Validate("Shipment Date", LibraryRandom.RandDate(30));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create warehouse shipment from the sales order, populate bin code.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Bin Code", Bin.Code);
        WarehouseShipmentLine.Modify(true);

        // [WHEN] Release the warehouse shipment.
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] The warehouse shipment has been released.
        WarehouseShipmentHeader.TestField(Status, WarehouseShipmentHeader.Status::Released);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PurchLineForNonInventoryItemNotBlankedOutOnPostingWhseReceipt()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        NonInvtItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // [FEATURE] [Non-Inventory Item] [Purchase] [Warehouse Receipt]
        // [SCENARIO 398513] "Qty. to Receive" on purchase line for non-inventory item is not blanked out after posting warehouse receipt for another purchase line.
        Initialize();

        LibraryWarehouse.SetRequireReceiveOnWarehouseSetup(true);

        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, NonInvtItem."No.", LibraryRandom.RandInt(10));

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WarehouseReceiptHeader.SetRange("Location Code", Location.Code);
        WarehouseReceiptHeader.FindFirst();
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        PurchaseLine.Find();
        PurchaseLine.TestField("Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.TestField("Qty. to Invoice", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SalesLineForNonInventoryItemNotBlankedOutOnPostingWhseShipment()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        NonInvtItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Non-Inventory Item] [Sales] [Warehouse Shipment]
        // [SCENARIO 398513] "Qty. to Ship" on sales line for non-inventory item is not blanked out after posting warehouse shipment for another sales line.
        Initialize();

        LibraryWarehouse.SetRequireShipmentOnWarehouseSetup(true);

        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, NonInvtItem."No.", LibraryRandom.RandInt(10));

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        SalesLine.Find();
        SalesLine.TestField("Qty. to Ship", SalesLine.Quantity);
        SalesLine.TestField("Qty. to Invoice", SalesLine.Quantity);
    end;

    local procedure Initialize()
    var
        BOMComponent: Record "BOM Component";
        RequisitionLine: Record "Requisition Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SMB Service Item");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        BOMComponent.DeleteAll();
        RequisitionLine.DeleteAll();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SMB Service Item");
        LibrarySetupStorage.Save(DATABASE::"Warehouse Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        SetGlobalNoSeriesInSetups();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SMB Service Item");
    end;

    local procedure SetGlobalNoSeriesInSetups()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        MarketingSetup: Record "Marketing Setup";
        WarehouseSetup: Record "Warehouse Setup";
        InventorySetup: Record "Inventory Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Customer Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify();

        MarketingSetup.Get();
        MarketingSetup."Contact Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        MarketingSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Vendor Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify();

        WarehouseSetup.Get();
        WarehouseSetup."Whse. Ship Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup.Modify();

        InventorySetup.Get();
        InventorySetup."Transfer Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup.Modify();
    end;

    local procedure CreateInvtItem(var Item: Record Item)
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Commit();
    end;

    local procedure CreateServItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);
        Commit();
    end;

    local procedure CreateNonInvItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);
        Commit();
    end;

    local procedure CreateStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    var
        ItemVariant: Record "Item Variant";
        Variant: Code[10];
        VArCost: Decimal;
    begin
        Variant := '1';
        VArCost := 20;

        ItemVariant.Init();
        ItemVariant."Item No." := Item."No.";
        ItemVariant.Code := Variant;

        if not ItemVariant.Insert() then
            ItemVariant.Modify();

        StockkeepingUnit.Init();
        StockkeepingUnit."Item No." := Item."No.";
        StockkeepingUnit."Variant Code" := Variant;

        if not StockkeepingUnit.Insert() then
            StockkeepingUnit.Modify();
    end;

    local procedure CreateSalesOrder(Cust: Record Customer; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        Commit();
    end;

    local procedure CreatePurchOrder(Vend: Record Vendor; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Item: Record Item)
    var
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        LibraryPurch.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, Vend."No.");
        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        Commit();
    end;

    local procedure CreateAsmOrder(ChildItem: Record Item)
    var
        ParentItem: Record Item;
        BOMComp: Record "BOM Component";
        AsmSetup: Record "Assembly Setup";
        OldAsmSetup: Record "Assembly Setup";
        AsmHeader: Record "Assembly Header";
        LibraryAsm: Codeunit "Library - Assembly";
    begin
        CreateInvtItem(ParentItem);

        BOMComp.Init();
        BOMComp.Validate("Parent Item No.", ParentItem."No.");
        BOMComp.Validate(Type, BOMComp.Type::Item);
        BOMComp.Validate("No.", ChildItem."No.");
        BOMComp.Validate("Quantity per", 3);
        BOMComp.Insert(true);

        AsmSetup.Get();
        OldAsmSetup := AsmSetup;
        AsmSetup."Stockout Warning" := false;
        AsmSetup.Modify();
        Commit();

        LibraryAsm.CreateAssemblyHeader(AsmHeader, CalcDate('<+2D>', WorkDate()), ParentItem."No.", '', 1, '');

        BOMComp.Delete(true);
        Commit();

        ChildItem.Find();
        asserterror ParentItem.Validate(Type, ParentItem.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror ChildItem.Validate(Type, ChildItem.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror ParentItem.Delete(true);
        AssertRunTime('You cannot delete Item', '');
        asserterror ChildItem.Delete(true);
        AssertRunTime('You cannot delete Item', '');

        AsmSetup."Stockout Warning" := OldAsmSetup."Stockout Warning";
        AsmSetup.Modify();
    end;

    local procedure CreateProdOrder(ChildItem: Record Item)
    var
        ParentItem: Record Item;
        ProdOrder: Record "Production Order";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        LibraryMfg: Codeunit "Library - Manufacturing";
    begin
        CreateInvtItem(ParentItem);
        LibraryMfg.CreateCertifiedProductionBOM(ProdBOMHeader, ChildItem."No.", 1);
        ParentItem.Validate("Production BOM No.", ProdBOMHeader."No.");
        ParentItem.Modify(true);
        Commit();

        asserterror ChildItem.Validate(Type, ChildItem.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror ChildItem.Delete(true);
        AssertRunTime('You cannot delete Item', '');

        LibraryMfg.CreateProductionOrder(
          ProdOrder, ProdOrder.Status::Released, ProdOrder."Source Type"::Item, ParentItem."No.", 1);
        LibraryMfg.RefreshProdOrder(ProdOrder, true, true, true, true, false);

        ProdBOMHeader.Get(ParentItem."Production BOM No.");
        ProdBOMLine.SetRange("Production BOM No.", ProdBOMHeader."No.");
        ProdBOMLine.DeleteAll();
        ParentItem.Validate("Production BOM No.", '');
        ParentItem.Modify(true);

        Commit();
        asserterror ParentItem.Validate(Type, ParentItem.Type::Service);
        AssertRunTime('You cannot change the Type field', '');
        asserterror ParentItem.Delete(true);
        AssertRunTime('You cannot delete Item', '');
    end;

    local procedure CreateAndPostItemJnlLine(Item: Record Item; Qty: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::Purchase, Item."No.", Qty);
        Commit();

        // Check that it is not possible to change the Type to Service if an Item Journal exists
        asserterror Item.Validate(Type, Item.Type::Service);
        AssertRunTime('You cannot change the Type field', '');

        asserterror Item.Delete(true);
        AssertRunTime('You cannot delete Item', '');
        LibraryInventory.PostItemJournalLine(ItemJnlTemplate.Name, ItemJnlBatch.Name);
    end;

    local procedure CreateReqLine(ParentItem: Record Item; ChildItem: Record Item)
    var
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
    begin
        ReqWkshName.FindFirst();
        ReqLine.Init();
        ReqLine.Validate("Worksheet Template Name", ReqWkshName."Worksheet Template Name");
        ReqLine.Validate("Journal Batch Name", ReqWkshName.Name);
        ReqLine.Validate(Type, ReqLine.Type::Item);
        ReqLine.Validate("No.", ParentItem."No.");
        ReqLine.Insert(true);

        PlanningComponent.Init();
        PlanningComponent.Validate("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningComponent.Validate("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningComponent.Validate("Worksheet Line No.", ReqLine."Line No.");
        PlanningComponent.Validate("Item No.", ChildItem."No.");
        PlanningComponent.Insert(true);
        Commit();
    end;

    local procedure CreateTransOrder(Item: Record Item)
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        IntransitLocation: Record Location;
        TransRoute: Record "Transfer Route";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(IntransitLocation);

        LibraryWarehouse.CreateAndUpdateTransferRoute(
          TransRoute, FromLocation.Code, ToLocation.Code, IntransitLocation.Code, '', '');
        LibraryWarehouse.CreateTransferHeader(TransHeader, FromLocation.Code, ToLocation.Code, IntransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransHeader, TransLine, Item."No.", 1);
    end;

    local procedure CreateVendWithLocation(var Vend: Record Vendor)
    var
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        LibraryPurch.CreateVendor(Vend);
        Vend.Validate("Location Code", FindLocation());
        Vend.Modify(true);
    end;

    local procedure CreateCustWithLocation(var Cust: Record Customer)
    begin
        LibrarySales.CreateCustomer(Cust);
        Cust.Validate("Location Code", FindLocation());
        Cust.Modify(true);
    end;

    local procedure FindLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetRange("Use As In-Transit", false);
        Location.SetRange("Bin Mandatory", false);
        Location.FindFirst();
        exit(Location.Code);
    end;

    local procedure FindPurchReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchReceiptNo: Code[20]; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("Document No.", PurchReceiptNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindSet();
    end;

    local procedure CheckEntries(Item: Record Item)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
    begin
        Item.Find();
        Assert.AreEqual((Item.Type = Item.Type::Service) or (Item.Type = Item.Type::"Non-Inventory"),
          Item."Cost is Adjusted", 'The Item should be marked always as Cost is Adjusted');

        // Check value entries
        ValueEntry.SetRange("Item No.", Item."No.");
        Assert.IsFalse(ValueEntry.IsEmpty, 'Value Entries should be created if a posting is made');

        ValueEntry.SetRange(Inventoriable, true);
        Assert.AreEqual((Item.Type = Item.Type::Service) or (Item.Type = Item.Type::"Non-Inventory"),
          ValueEntry.IsEmpty, 'All Value Entries should not be marked as Inventoriable');

        // Check item Ledger Entries
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.FindSet();
        repeat
            if Item.Type = Item.Type::Service then begin
                Assert.IsFalse(ItemLedgEntry."Applied Entry to Adjust", '');
                Assert.IsFalse(ItemLedgEntry.Open, '');

                Assert.AreEqual(
                  0, ItemLedgEntry."Remaining Quantity",
                  'Remaining Quantity on Item Ledger Entry should be zero');

                // Check Item Application Entries
                ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                Assert.AreEqual(
                  (Item.Type = Item.Type::Service) or (Item.Type = Item.Type::"Non-Inventory"), ItemApplnEntry.IsEmpty,
                  'There should be no Application Enties');
            end;
        until ItemLedgEntry.Next() = 0;

        if (Item.Type = Item.Type::Service) or (Item.Type = Item.Type::"Non-Inventory") then begin
            PostValueEntryToGL.SetRange("Item No.", Item."No.");
            Assert.AreEqual(
              (Item.Type = Item.Type::Service) or (Item.Type = Item.Type::"Non-Inventory"), PostValueEntryToGL.IsEmpty,
              'The should be no record in Post Value Entry to G/L');
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyAvailabilityModalPageHandler(var AssemblyAvailability: TestPage "Assembly Availability Check")
    begin
        AssemblyAvailability.AssemblyLineAvail.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Assert.IsTrue(AssemblyAvailability.AssemblyLineAvail.First(), '');

        AssemblyAvailability.AssemblyLineAvail.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Assert.IsFalse(AssemblyAvailability.AssemblyLineAvail.First(), '');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAssemblyAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        AssemblyLineManagement: Codeunit "Assembly Line Management";
    begin
        Commit();
        AssemblyLineManagement.ShowNotificationDetails(Notification);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(MsgText: Text)
    begin
        MsgText := MsgText;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure AssertRunTime(ExpectedErrorTextContains: Text; Msg: Text)
    begin
        Assert.IsTrue(StrPos(GetLastErrorText, ExpectedErrorTextContains) > 0, Msg);
        ClearLastError();
    end;
}

