codeunit 134350 "Test Item Charge Extendibility"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Charge]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NewStrMenuTxt: Text;
        NewDefault: Integer;
        NewSelection: Integer;
        NewInstruction: Text;
        EquallyTok: Label 'Equally';
        ByFairyDustTok: Label 'By Fairy Dust';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntSalesZeroOptions()
    var
        SalesLine: Record "Sales Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreateSalesInvoiceWithItemCharge(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuZeroOptions(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentSales(SalesLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesSalesNotAssigned(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntSalesOneOptionEqually()
    var
        SalesLine: Record "Sales Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreateSalesInvoiceWithItemCharge(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuOneOptionEqually(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentSales(SalesLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesSalesAssignedEqually(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntSalesOneOptionByFairyDust()
    var
        SalesLine: Record "Sales Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreateSalesInvoiceWithItemCharge(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuOneOptionByFairyDust(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentSales(SalesLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesSalesAssignedByFairyDust(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntSalesThreeOptionsEqually()
    var
        SalesLine: Record "Sales Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreateSalesInvoiceWithItemCharge(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuThreeOptionsEqually(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentSales(SalesLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesSalesAssignedEqually(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntSalesSixOptionsByFairyDust()
    var
        SalesLine: Record "Sales Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreateSalesInvoiceWithItemCharge(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuSixOptionsByFairyDust(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentSales(SalesLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesSalesAssignedByFairyDust(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntSalesOneLine()
    var
        SalesLine: Record "Sales Line";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreateOneLineSalesInvoiceWithItemCharge(SalesLine, TotalQtyToAssign, TotalAmtToAssign);

        // Exercise
        SuggestItemChargeAssignmentSales(SalesLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesSalesAssignedEqually(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntPurchZeroOptions()
    var
        PurchaseLine: Record "Purchase Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreatePurchaseInvoiceWithItemCharge(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuZeroOptions(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentPurch(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesPurchNotAssigned(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntPurchOneOptionEqually()
    var
        PurchaseLine: Record "Purchase Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreatePurchaseInvoiceWithItemCharge(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuOneOptionEqually(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentPurch(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesPurchAssignedEqually(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntPurchOneOptionByFairyDust()
    var
        PurchaseLine: Record "Purchase Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreatePurchaseInvoiceWithItemCharge(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuOneOptionByFairyDust(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentPurch(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesPurchAssignedByFairyDust(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntPurchThreeOptionsEqually()
    var
        PurchaseLine: Record "Purchase Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreatePurchaseInvoiceWithItemCharge(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuThreeOptionsEqually(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentPurch(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesPurchAssignedEqually(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntPurchSixOptionsByFairyDust()
    var
        PurchaseLine: Record "Purchase Line";
        TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreatePurchaseInvoiceWithItemCharge(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
        SetItemChargeAssignmentStrMenuSixOptionsByFairyDust(TestItemChargeExtendibility);

        // Exercise
        SuggestItemChargeAssignmentPurch(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesPurchAssignedByFairyDust(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemChargeAssgntPurchOneLine()
    var
        PurchaseLine: Record "Purchase Line";
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        Initialize();

        // Setup
        CreateOneLinePurchaseInvoiceWithItemCharge(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);

        // Exercise
        SuggestItemChargeAssignmentPurch(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);

        // Verify
        VerifyItemChargesPurchAssignedEqually(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToHandleItemChargeAssgntSales()
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        Initialize();

        InitItemChargeAssignmentSales(ItemChargeAssignmentSales);
        ItemChargeAssignmentSales.Validate("Qty. to Assign", LibraryRandom.RandInt(50));
        ItemChargeAssignmentSales.TestField("Qty. to Handle", ItemChargeAssignmentSales."Qty. to Assign");
        ItemChargeAssignmentSales.TestField("Amount to Handle", ItemChargeAssignmentSales."Amount to Assign");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroQtyToHandleItemChargeAssgntSales()
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        Initialize();

        InitItemChargeAssignmentSales(ItemChargeAssignmentSales);
        ItemChargeAssignmentSales.Validate("Qty. to Assign", LibraryRandom.RandInt(50));
        ItemChargeAssignmentSales.Validate("Qty. to Handle", 0);
        ItemChargeAssignmentSales.TestField("Amount to Handle", 0);
        // [WHEN] Restore "Qty. to Handle" as "Qty. to Assign"
        ItemChargeAssignmentSales.Validate("Qty. to Handle", ItemChargeAssignmentSales."Qty. to Assign");
        ItemChargeAssignmentSales.TestField("Amount to Handle", ItemChargeAssignmentSales."Amount to Assign");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToHandleMustbeEqualToQtyToAssignItemChargeAssgntSales()
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        Initialize();

        InitItemChargeAssignmentSales(ItemChargeAssignmentSales);
        ItemChargeAssignmentSales.Validate("Qty. to Assign", LibraryRandom.RandInt(50));
        asserterror ItemChargeAssignmentSales.Validate("Qty. to Handle", ItemChargeAssignmentSales."Qty. to Assign" - 1);
        Assert.ExpectedTestFieldError(ItemChargeAssignmentSales.FieldCaption("Qty. to Handle"), Format(ItemChargeAssignmentSales."Qty. to Assign"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToHandleItemChargeAssgntPurch()
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        Initialize();

        InitItemChargeAssignmentPurch(ItemChargeAssignmentPurch);
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", LibraryRandom.RandInt(50));
        ItemChargeAssignmentPurch.TestField("Qty. to Handle", ItemChargeAssignmentPurch."Qty. to Assign");
        ItemChargeAssignmentPurch.TestField("Amount to Handle", ItemChargeAssignmentPurch."Amount to Assign");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroQtyToHandleItemChargeAssgntPurch()
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        Initialize();

        InitItemChargeAssignmentPurch(ItemChargeAssignmentPurch);
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", LibraryRandom.RandInt(50));
        ItemChargeAssignmentPurch.Validate("Qty. to Handle", 0);
        ItemChargeAssignmentPurch.TestField("Amount to Handle", 0);
        // [WHEN] Restore "Qty. to Handle" as "Qty. to Assign"
        ItemChargeAssignmentPurch.Validate("Qty. to Handle", ItemChargeAssignmentPurch."Qty. to Assign");
        ItemChargeAssignmentPurch.TestField("Amount to Handle", ItemChargeAssignmentPurch."Amount to Assign");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToHandleMustbeEqualToQtyToAssignItemChargeAssgntPurch()
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        Initialize();

        InitItemChargeAssignmentPurch(ItemChargeAssignmentPurch);
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", LibraryRandom.RandInt(50));
        asserterror ItemChargeAssignmentPurch.Validate("Qty. to Handle", ItemChargeAssignmentPurch."Qty. to Assign" - 1);
        Assert.ExpectedTestFieldError(ItemChargeAssignmentPurch.FieldCaption("Qty. to Handle"), Format(ItemChargeAssignmentPurch."Qty. to Assign"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Item Charge Extendibility");
        LibraryVariableStorage.AssertEmpty();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Item Charge Extendibility");

        IsInitialized := true;
        LibraryERMCountryData.CreateVATData();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Item Charge Extendibility");
    end;

    local procedure CreateSalesInvoiceWithItemCharge(var SalesLine: Record "Sales Line"; var TotalQtyToAssign: Decimal; var TotalAmtToAssign: Decimal)
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(1, 100, 2));
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(1, 100, 2));

        CreateSalesLineWithItemCharge(SalesHeader, SalesLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    local procedure CreatePurchaseInvoiceWithItemCharge(var PurchaseLine: Record "Purchase Line"; var TotalQtyToAssign: Decimal; var TotalAmtToAssign: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(1, 100, 2));
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(1, 100, 2));

        CreatePurchaseLineWithItemCharge(PurchaseHeader, PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    local procedure CreateOneLineSalesInvoiceWithItemCharge(var SalesLine: Record "Sales Line"; var TotalQtyToAssign: Decimal; var TotalAmtToAssign: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        CreateSalesLineWithItemCharge(SalesHeader, SalesLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    local procedure CreateOneLinePurchaseInvoiceWithItemCharge(var PurchaseLine: Record "Purchase Line"; var TotalQtyToAssign: Decimal; var TotalAmtToAssign: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        CreatePurchaseLineWithItemCharge(PurchaseHeader, PurchaseLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    local procedure CreateSalesLineWithItemCharge(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TotalQtyToAssign: Decimal; var TotalAmtToAssign: Decimal)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", '', LibraryRandom.RandDecInRange(1, 100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(500, 1000, 2));

        ItemChargeAssignmentSales."Document Type" := SalesLine."Document Type";
        ItemChargeAssignmentSales."Document No." := SalesLine."Document No.";
        ItemChargeAssignmentSales."Document Line No." := SalesLine."Line No.";
        ItemChargeAssgntSales.CreateDocChargeAssgn(ItemChargeAssignmentSales, SalesHeader."Shipping No.");
        TotalQtyToAssign := SalesLine.Quantity;
        TotalAmtToAssign := SalesLine."Line Amount";
    end;

    local procedure CreatePurchaseLineWithItemCharge(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TotalQtyToAssign: Decimal; var TotalAmtToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", '', LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(500, 1000, 2));

        ItemChargeAssignmentPurch."Document Type" := PurchaseLine."Document Type";
        ItemChargeAssignmentPurch."Document No." := PurchaseLine."Document No.";
        ItemChargeAssignmentPurch."Document Line No." := PurchaseLine."Line No.";
        ItemChargeAssgntPurch.CreateDocChargeAssgnt(ItemChargeAssignmentPurch, PurchaseHeader."Receiving No.");
        TotalQtyToAssign := PurchaseLine.Quantity;
        TotalAmtToAssign := PurchaseLine."Line Amount";
    end;

    local procedure AssignEquallyMenuText(): Text
    begin
        exit(EquallyTok)
    end;

    local procedure AssignByFairyDustMenuText(): Text
    begin
        exit(ByFairyDustTok);
    end;

    local procedure SetItemChargeAssignmentStrMenuZeroOptions(var TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility")
    begin
        TestItemChargeExtendibility.SetStrMenuGlobalsForSubscriber('', 0, 0, 'Select from zero options');
        BindSubscription(TestItemChargeExtendibility);
    end;

    local procedure SetItemChargeAssignmentStrMenuOneOptionEqually(var TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility")
    begin
        TestItemChargeExtendibility.SetStrMenuGlobalsForSubscriber(AssignEquallyMenuText(), 1, 1, 'Select from one option');
        BindSubscription(TestItemChargeExtendibility);
    end;

    local procedure SetItemChargeAssignmentStrMenuOneOptionByFairyDust(var TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility")
    begin
        TestItemChargeExtendibility.SetStrMenuGlobalsForSubscriber(AssignByFairyDustMenuText(), 1, 1, 'Select from one option');
        BindSubscription(TestItemChargeExtendibility);
    end;

    local procedure SetItemChargeAssignmentStrMenuThreeOptionsEqually(var TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility")
    begin
        SetStrMenuGlobalsForSubscriber(
          StrSubstNo('By Amount,%1,%2', AssignByFairyDustMenuText(), AssignEquallyMenuText()), 1, 3, 'Select from one option');
        TestItemChargeExtendibility.SetStrMenuGlobalsForSubscriber(NewStrMenuTxt, NewDefault, NewSelection, NewInstruction);
        BindSubscription(TestItemChargeExtendibility);
    end;

    local procedure SetItemChargeAssignmentStrMenuSixOptionsByFairyDust(var TestItemChargeExtendibility: Codeunit "Test Item Charge Extendibility")
    begin
        SetStrMenuGlobalsForSubscriber(
          StrSubstNo('By Amount,%1,By Weight,%2,By Volume,Random', AssignByFairyDustMenuText(), AssignEquallyMenuText()),
          1, 2, 'Select from one option');
        TestItemChargeExtendibility.SetStrMenuGlobalsForSubscriber(NewStrMenuTxt, NewDefault, NewSelection, NewInstruction);
        BindSubscription(TestItemChargeExtendibility);
    end;

    local procedure SuggestItemChargeAssignmentSales(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        VerifyItemChargesSalesNotAssigned(SalesLine);
        ItemChargeAssgntSales.SuggestAssignment(SalesLine, TotalQtyToAssign, TotalAmtToAssign);
    end;

    local procedure SuggestItemChargeAssignmentPurch(PurchaseLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        VerifyItemChargesPurchNotAssigned(PurchaseLine);
        ItemChargeAssgntPurch.SuggestAssgnt(PurchaseLine, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToAssign, TotalAmtToAssign);
    end;

    local procedure AssignByFairyDustSales(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        i: Integer;
    begin
        ItemChargeAssignmentSales.FindSet();
        for i := ItemChargeAssignmentSales.Count downto 2 do begin
            ItemChargeAssignmentSales."Qty. to Assign" := Round(TotalQtyToAssign / (i + 1));
            ItemChargeAssignmentSales."Amount to Assign" := Round(TotalAmtToAssign / (i + 1));
            ItemChargeAssignmentSales."Qty. to Handle" := ItemChargeAssignmentSales."Qty. to Assign";
            ItemChargeAssignmentSales."Amount to Handle" := ItemChargeAssignmentSales."Amount to Assign";
            ItemChargeAssignmentSales.Modify();
            TotalQtyToAssign -= ItemChargeAssignmentSales."Qty. to Assign";
            TotalAmtToAssign -= ItemChargeAssignmentSales."Amount to Assign";
            ItemChargeAssignmentSales.Next();
        end;
        ItemChargeAssignmentSales."Qty. to Assign" := TotalQtyToAssign;
        ItemChargeAssignmentSales."Amount to Assign" := TotalAmtToAssign;
        ItemChargeAssignmentSales."Qty. to Handle" := ItemChargeAssignmentSales."Qty. to Assign";
        ItemChargeAssignmentSales."Amount to Handle" := ItemChargeAssignmentSales."Amount to Assign";
        ItemChargeAssignmentSales.Modify();
    end;

    local procedure AssignByFairyDustPurch(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        i: Integer;
    begin
        ItemChargeAssignmentPurch.FindSet();
        for i := ItemChargeAssignmentPurch.Count downto 2 do begin
            ItemChargeAssignmentPurch."Qty. to Assign" := Round(TotalQtyToAssign / (i + 1));
            ItemChargeAssignmentPurch."Amount to Assign" := Round(TotalAmtToAssign / (i + 1));
            ItemChargeAssignmentPurch."Qty. to Handle" := ItemChargeAssignmentPurch."Qty. to Assign";
            ItemChargeAssignmentPurch."Amount to Handle" := ItemChargeAssignmentPurch."Amount to Assign";
            ItemChargeAssignmentPurch.Modify();
            TotalQtyToAssign -= ItemChargeAssignmentPurch."Qty. to Assign";
            TotalAmtToAssign -= ItemChargeAssignmentPurch."Amount to Assign";
            ItemChargeAssignmentPurch.Next();
        end;
        ItemChargeAssignmentPurch."Qty. to Assign" := TotalQtyToAssign;
        ItemChargeAssignmentPurch."Amount to Assign" := TotalAmtToAssign;
        ItemChargeAssignmentPurch."Qty. to Handle" := ItemChargeAssignmentPurch."Qty. to Assign";
        ItemChargeAssignmentPurch."Amount to Handle" := ItemChargeAssignmentPurch."Amount to Assign";
        ItemChargeAssignmentPurch.Modify();
    end;

    local procedure FilterItemChargeAssignmentSales(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line")
    begin
        Assert.AreEqual(SalesLine.Type::"Charge (Item)", SalesLine.Type, 'Sales Line must be of type Charge (Item)');
        SalesLine2.SetRange("Document Type", SalesLine."Document Type");
        SalesLine2.SetRange("Document No.", SalesLine."Document No.");
        SalesLine2.SetRange(Type, SalesLine2.Type::Item);
        Assert.AreNotEqual(0, SalesLine.Quantity, 'Item Charge line must have a quantity');
        Assert.AreNotEqual(0, SalesLine."Line Amount", 'Item Charge line must have an amount');
        ItemChargeAssignmentSales.SetRange("Document Type", SalesLine."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", SalesLine."Document No.");
        Assert.AreEqual(SalesLine2.Count, ItemChargeAssignmentSales.Count, 'wrong number of lines');
    end;

    local procedure FilterItemChargeAssignmentPurch(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line")
    begin
        Assert.AreEqual(PurchaseLine.Type::"Charge (Item)", PurchaseLine.Type, 'Sales Line must be of type Charge (Item)');
        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine2.SetRange(Type, PurchaseLine2.Type::Item);
        Assert.AreNotEqual(0, PurchaseLine.Quantity, 'Item Charge line must have a quantity');
        Assert.AreNotEqual(0, PurchaseLine."Line Amount", 'Item Charge line must have an amount');
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        Assert.AreEqual(PurchaseLine2.Count, ItemChargeAssignmentPurch.Count, 'wrong number of lines');
    end;

    local procedure VerifyItemChargesSalesNotAssigned(SalesLine: Record "Sales Line")
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssignmentSales.SetRange("Document Type", SalesLine."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", SalesLine."Document No.");
        ItemChargeAssignmentSales.SetFilter("Qty. Assigned", '<>%1', 0);
        Assert.RecordIsEmpty(ItemChargeAssignmentSales);
    end;

    local procedure VerifyItemChargesSalesAssignedEqually(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesLine2: Record "Sales Line";
        i: Integer;
    begin
        FilterItemChargeAssignmentSales(ItemChargeAssignmentSales, SalesLine, SalesLine2);
        ItemChargeAssignmentSales.FindSet();
        for i := 0 to ItemChargeAssignmentSales.Count - 2 do begin
            Assert.AreEqual(Round(TotalQtyToAssign / (SalesLine2.Count - i), 0.00001),
              ItemChargeAssignmentSales."Qty. to Assign", 'Wrong Qty. to Assign');
            Assert.AreEqual(Round(ItemChargeAssignmentSales."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign),
              ItemChargeAssignmentSales."Amount to Assign", 'Wrong Amount to Assign');
            TotalQtyToAssign -= ItemChargeAssignmentSales."Qty. to Assign";
            TotalAmtToAssign -= ItemChargeAssignmentSales."Amount to Assign";
            ItemChargeAssignmentSales.Next();
        end;
        Assert.AreEqual(Round(TotalQtyToAssign, 0.00001), ItemChargeAssignmentSales."Qty. to Assign", 'Wrong Qty. to Assign');
        Assert.AreEqual(TotalAmtToAssign, ItemChargeAssignmentSales."Amount to Assign", 'Wrong Amount to Assign');
        Assert.AreEqual(ItemChargeAssignmentSales."Qty. to Assign", ItemChargeAssignmentSales."Qty. to Handle", 'Wrong Qty. to Handle');
        Assert.AreEqual(ItemChargeAssignmentSales."Amount to Assign", ItemChargeAssignmentSales."Amount to Handle", 'Wrong Amount to Handle');
    end;

    local procedure VerifyItemChargesSalesAssignedByFairyDust(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesLine2: Record "Sales Line";
        i: Integer;
        j: Integer;
    begin
        FilterItemChargeAssignmentSales(ItemChargeAssignmentSales, SalesLine, SalesLine2);
        ItemChargeAssignmentSales.FindSet();
        for i := ItemChargeAssignmentSales.Count downto 2 do begin
            j := i + 1;
            Assert.AreEqual(Round(TotalQtyToAssign / j), ItemChargeAssignmentSales."Qty. to Assign", 'Wrong Qty. to Assign');
            Assert.AreEqual(Round(TotalAmtToAssign / j), ItemChargeAssignmentSales."Amount to Assign", 'Wrong Amount to Assign');
            TotalQtyToAssign -= ItemChargeAssignmentSales."Qty. to Assign";
            TotalAmtToAssign -= ItemChargeAssignmentSales."Amount to Assign";
            ItemChargeAssignmentSales.Next();
        end;
        Assert.AreEqual(TotalQtyToAssign, ItemChargeAssignmentSales."Qty. to Assign", 'Wrong Qty. to Assign');
        Assert.AreEqual(TotalAmtToAssign, ItemChargeAssignmentSales."Amount to Assign", 'Wrong Amount to Assign');
        Assert.AreEqual(ItemChargeAssignmentSales."Qty. to Assign", ItemChargeAssignmentSales."Qty. to Handle", 'Wrong Qty. to Handle');
        Assert.AreEqual(ItemChargeAssignmentSales."Amount to Assign", ItemChargeAssignmentSales."Amount to Handle", 'Wrong Amount to Handle');
    end;

    local procedure VerifyItemChargesPurchNotAssigned(PurchaseLine: Record "Purchase Line")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.SetFilter("Qty. Assigned", '<>%1', 0);
        Assert.RecordIsEmpty(ItemChargeAssignmentPurch);
    end;

    local procedure VerifyItemChargesPurchAssignedEqually(PurchaseLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLine2: Record "Purchase Line";
        i: Integer;
    begin
        FilterItemChargeAssignmentPurch(ItemChargeAssignmentPurch, PurchaseLine, PurchaseLine2);
        ItemChargeAssignmentPurch.FindSet();
        for i := 0 to ItemChargeAssignmentPurch.Count - 2 do begin
            Assert.AreEqual(Round(TotalQtyToAssign / (PurchaseLine2.Count - i), 0.00001),
              ItemChargeAssignmentPurch."Qty. to Assign", 'Wrong Qty. to Assign');
            Assert.AreEqual(Round(ItemChargeAssignmentPurch."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign),
              ItemChargeAssignmentPurch."Amount to Assign", 'Wrong Amount to Assign');
            TotalQtyToAssign -= ItemChargeAssignmentPurch."Qty. to Assign";
            TotalAmtToAssign -= ItemChargeAssignmentPurch."Amount to Assign";
            ItemChargeAssignmentPurch.Next();
        end;
        Assert.AreEqual(Round(TotalQtyToAssign, 0.00001), ItemChargeAssignmentPurch."Qty. to Assign", 'Wrong Qty. to Assign');
        Assert.AreEqual(TotalAmtToAssign, ItemChargeAssignmentPurch."Amount to Assign", 'Wrong Amount to Assign');
        Assert.AreEqual(ItemChargeAssignmentPurch."Qty. to Assign", ItemChargeAssignmentPurch."Qty. to Handle", 'Wrong Qty. to Handle');
        Assert.AreEqual(ItemChargeAssignmentPurch."Amount to Assign", ItemChargeAssignmentPurch."Amount to Handle", 'Wrong Amount to Handle');
    end;

    local procedure VerifyItemChargesPurchAssignedByFairyDust(PurchaseLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLine2: Record "Purchase Line";
        i: Integer;
        j: Integer;
    begin
        FilterItemChargeAssignmentPurch(ItemChargeAssignmentPurch, PurchaseLine, PurchaseLine2);
        ItemChargeAssignmentPurch.FindSet();
        for i := ItemChargeAssignmentPurch.Count downto 2 do begin
            j := i + 1;
            Assert.AreEqual(Round(TotalQtyToAssign / j), ItemChargeAssignmentPurch."Qty. to Assign", 'Wrong Qty. to Assign');
            Assert.AreEqual(Round(TotalAmtToAssign / j), ItemChargeAssignmentPurch."Amount to Assign", 'Wrong Amount to Assign');
            TotalQtyToAssign -= ItemChargeAssignmentPurch."Qty. to Assign";
            TotalAmtToAssign -= ItemChargeAssignmentPurch."Amount to Assign";
            ItemChargeAssignmentPurch.Next();
        end;
        Assert.AreEqual(TotalQtyToAssign, ItemChargeAssignmentPurch."Qty. to Assign", 'Wrong Qty. to Assign');
        Assert.AreEqual(TotalAmtToAssign, ItemChargeAssignmentPurch."Amount to Assign", 'Wrong Amount to Assign');
        Assert.AreEqual(ItemChargeAssignmentPurch."Qty. to Assign", ItemChargeAssignmentPurch."Qty. to Handle", 'Wrong Qty. to Handle');
        Assert.AreEqual(ItemChargeAssignmentPurch."Amount to Assign", ItemChargeAssignmentPurch."Amount to Handle", 'Wrong Amount to Handle');
    end;

    local procedure InitItemChargeAssignmentPurch(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargePurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
            ItemChargePurchaseLine, PurchaseHeader, "Sales Line Type"::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(20));
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        ItemChargeAssignmentPurch.Init();
        ItemChargeAssignmentPurch."Document Type" := ItemChargePurchaseLine."Document Type";
        ItemChargeAssignmentPurch."Document No." := ItemChargePurchaseLine."Document No.";
        ItemChargeAssignmentPurch."Document Line No." := ItemChargePurchaseLine."Line No.";
        ItemChargeAssignmentPurch."Applies-to Doc. Type" := PurchaseLine."Document Type";
        ItemChargeAssignmentPurch."Applies-to Doc. No." := PurchaseLine."Document No.";
        ItemChargeAssignmentPurch."Applies-to Doc. Line No." := PurchaseLine."Line No.";
        ItemChargeAssignmentPurch."Unit Cost" := LibraryRandom.RandDec(100, 2);
    end;

    local procedure InitItemChargeAssignmentSales(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeSalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibrarySales.CreateSalesLine(
            ItemChargeSalesLine, SalesHeader, "Sales Line Type"::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(20));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        ItemChargeAssignmentSales.Init();
        ItemChargeAssignmentSales."Document Type" := ItemChargeSalesLine."Document Type";
        ItemChargeAssignmentSales."Document No." := ItemChargeSalesLine."Document No.";
        ItemChargeAssignmentSales."Document Line No." := ItemChargeSalesLine."Line No.";
        ItemChargeAssignmentSales."Applies-to Doc. Type" := SalesLine."Document Type";
        ItemChargeAssignmentSales."Applies-to Doc. No." := SalesLine."Document No.";
        ItemChargeAssignmentSales."Applies-to Doc. Line No." := SalesLine."Line No.";
        ItemChargeAssignmentSales."Unit Cost" := LibraryRandom.RandDec(100, 2);
    end;

    [Scope('OnPrem')]
    procedure SetStrMenuGlobalsForSubscriber(StrMenuTxt: Text; Default: Integer; Selection: Integer; Instruction: Text)
    begin
        NewStrMenuTxt := StrMenuTxt;
        NewDefault := Default;
        NewSelection := Selection;
        NewInstruction := Instruction;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Charge Assgnt. (Sales)", 'OnBeforeShowSuggestItemChargeAssignStrMenu', '', false, false)]
    local procedure ManipulateStrMenuOnBeforeShowSuggestItemChargeAssignSalesStrMenu(SalesLine: Record "Sales Line"; var SuggestItemChargeMenuTxt: Text; var SuggestItemChargeMessageTxt: Text; var Selection: Integer)
    begin
        SuggestItemChargeMenuTxt := NewStrMenuTxt;
        Selection := NewDefault;
        SuggestItemChargeMessageTxt := NewInstruction;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Charge Assgnt. (Sales)", 'OnAssignItemCharges', '', false, false)]
    local procedure AssignByFairyDustOnAssignItemChargesSales(SelectionTxt: Text; var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; SalesHeader: Record "Sales Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var ItemChargesAssigned: Boolean)
    begin
        Assert.AreEqual(SelectStr(NewSelection, NewStrMenuTxt), SelectionTxt, 'Wrong option selected');
        Assert.AreEqual(AssignByFairyDustMenuText(), SelectionTxt, 'Wrong option selected');
        AssignByFairyDustSales(ItemChargeAssignmentSales, TotalQtyToAssign, TotalAmtToAssign);
        ItemChargesAssigned := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Charge Assgnt. (Purch.)", 'OnBeforeShowSuggestItemChargeAssignStrMenu', '', false, false)]
    local procedure ManipulateStrMenuOnBeforeShowSuggestItemChargeAssignPurchStrMenu(PurchLine: Record "Purchase Line"; var SuggestItemChargeMenuTxt: Text; var SuggestItemChargeMessageTxt: Text; var Selection: Integer)
    begin
        SuggestItemChargeMenuTxt := NewStrMenuTxt;
        Selection := NewDefault;
        SuggestItemChargeMessageTxt := NewInstruction;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Charge Assgnt. (Purch.)", 'OnAssignItemCharges', '', false, false)]
    local procedure AssignByFairyDustOnAssignItemChargesPurch(SelectionTxt: Text; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; PurchaseHeader: Record "Purchase Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var ItemChargesAssigned: Boolean)
    begin
        Assert.AreEqual(SelectStr(NewSelection, NewStrMenuTxt), SelectionTxt, 'Wrong option selected');
        Assert.AreEqual(AssignByFairyDustMenuText(), SelectionTxt, 'Wrong option selected');
        AssignByFairyDustPurch(ItemChargeAssignmentPurch, TotalQtyToAssign, TotalAmtToAssign);
        ItemChargesAssigned := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Assert.AreEqual(NewStrMenuTxt, Options, 'StrMenu is incorrect');
        Assert.AreEqual(NewDefault, Choice, 'Default selection is incorrect');
        Assert.AreEqual(NewInstruction, Instruction, 'Instruction is incorrect');
        Choice := NewSelection;
    end;
}

