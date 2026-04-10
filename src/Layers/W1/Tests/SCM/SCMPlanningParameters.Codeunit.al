codeunit 137022 "SCM Planning Parameters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
    end;

    var
        WithDemandItem: Record Item;
        WithDemandSalesLine: Record "Sales Line";
        WithDemandPurchaseLine: Record "Purchase Line";
        NoDemandItem: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        NoDemandIsInitialized: Boolean;
        WithDemandIsInitialized: Boolean;

    local procedure Initialize()
    var
        RequisitionLine: Record "Requisition Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning Parameters");
        RequisitionLine.DeleteAll(true);

        LibraryApplicationArea.EnableEssentialSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning Parameters");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning Parameters");
    end;

    local procedure InitializeNoDemand(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReorderPoint: Integer; ReorderQty: Integer; MaximumInventory: Integer; SafetyStock: Integer)
    begin
        Initialize();

        if not NoDemandIsInitialized then begin
            CreateItem(NoDemandItem);
            NoDemandIsInitialized := true;
        end;

        InitializeItem(NoDemandItem, ReorderingPolicy, ReorderPoint, ReorderQty, MaximumInventory, SafetyStock);
        Item.Get(NoDemandItem."No.");
    end;

    local procedure InitializeWithDemand(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReorderPoint: Integer; ReorderQty: Integer; MaxInventory: Integer; SafetyStock: Integer; DemandQuantity: Integer)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        if not WithDemandIsInitialized then begin
            CreateItem(WithDemandItem);

            // Create demand
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
            LibrarySales.CreateSalesLine(WithDemandSalesLine, SalesHeader, WithDemandSalesLine.Type::Item, WithDemandItem."No.", 1);
            WithDemandSalesLine.Validate("Planned Delivery Date", SSDemandDate());
            WithDemandSalesLine.Modify(true);

            // Initial supply > Safety Stock
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
            LibraryPurchase.CreatePurchaseLine(
              WithDemandPurchaseLine, PurchaseHeader, WithDemandPurchaseLine.Type::Item, WithDemandItem."No.", 1);
            WithDemandPurchaseLine.Validate("Planned Receipt Date", StartingDate() - 2);
            WithDemandPurchaseLine.Modify(true);

            WithDemandIsInitialized := true;
        end;

        InitializeItem(WithDemandItem, ReorderingPolicy, ReorderPoint, ReorderQty, MaxInventory, SafetyStock);

        WithDemandSalesLine.Validate(Quantity, DemandQuantity);
        WithDemandSalesLine.Modify(true);

        WithDemandPurchaseLine.Validate(Quantity, SafetyStock);
        WithDemandPurchaseLine.Modify(true);

        Item.Get(WithDemandItem."No.");
    end;

    local procedure InitializeItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReorderPoint: Integer; ReorderQty: Integer; MaxInventory: Integer; SafetyStock: Integer)
    begin
        Item.Get(Item."No.");
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQty);
        Item.Validate("Maximum Inventory", MaxInventory);
        Item.Validate("Safety Stock Quantity", SafetyStock);
        Item.Modify(true);
    end;

    local procedure InitializeFixedReorderROP(var Item: Record Item; ReorderPoint: Integer; ReorderQty: Integer; SafetyStock: Integer)
    begin
        InitializeNoDemand(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", ReorderPoint, ReorderQty, 0, SafetyStock);
        SetOrderModifiers(Item, 0, 0, 0);
    end;

    local procedure InitializeFixedReorderOM(var Item: Record Item; ReorderPoint: Integer; ReorderQty: Integer; SafetyStock: Integer)
    begin
        InitializeNoDemand(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", ReorderPoint, ReorderQty, 0, SafetyStock);
        SetOrderModifiers(Item, 5, 10, 25);
    end;

    local procedure InitializeMaxInv(var Item: Record Item; ReorderPoint: Integer; MaxInventory: Integer; SafetyStock: Integer)
    begin
        InitializeNoDemand(Item, Item."Reordering Policy"::"Maximum Qty.", ReorderPoint, 0, MaxInventory, SafetyStock);
        SetOrderModifiers(Item, 0, 0, 0);
    end;

    local procedure InitializeMaxInvOM(var Item: Record Item; ReorderPoint: Integer; MaxInventory: Integer; SafetyStock: Integer)
    begin
        InitializeNoDemand(Item, Item."Reordering Policy"::"Maximum Qty.", ReorderPoint, 0, MaxInventory, SafetyStock);
        SetOrderModifiers(Item, 5, 10, 25);
    end;

    local procedure InitializeLotForLotOM(var Item: Record Item; SafetyStock: Integer)
    begin
        InitializeNoDemand(Item, Item."Reordering Policy"::"Lot-for-Lot", 0, 0, 0, SafetyStock);
        SetOrderModifiers(Item, 5, 10, 25);
    end;

    local procedure InitializeFixedReorderROPWithDemand(var Item: Record Item; ReorderPoint: Integer; ReorderQty: Integer; DemandQty: Integer)
    begin
        InitializeWithDemand(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", ReorderPoint, ReorderQty, 0, 6, DemandQty);
        SetOrderModifiers(Item, 0, 0, 0);
    end;

    local procedure InitializeFixedReorderOMWithDemand(var Item: Record Item; ReorderPoint: Integer; ReorderQty: Integer; DemandQty: Integer)
    begin
        InitializeWithDemand(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", ReorderPoint, ReorderQty, 0, 5, DemandQty);
        SetOrderModifiers(Item, 5, 10, 25);
    end;

    local procedure InitializeMaxInvOMWithDemand(var Item: Record Item; ReorderPoint: Integer; MaxInventory: Integer; DemandQty: Integer)
    begin
        InitializeWithDemand(Item, Item."Reordering Policy"::"Maximum Qty.", ReorderPoint, 0, MaxInventory, 5, DemandQty);
        SetOrderModifiers(Item, 5, 10, 25);
    end;

    local procedure InitializeMaxInvWithDemand(var Item: Record Item; ReorderPoint: Integer; MaxInventory: Integer; DemandQty: Integer)
    begin
        InitializeWithDemand(Item, Item."Reordering Policy"::"Maximum Qty.", ReorderPoint, 0, MaxInventory, 5, DemandQty);
        SetOrderModifiers(Item, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_MaxInv_MaximumInventory()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInv(Item, 14, 22, 7);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 22, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_MaxInv_MaximumInventory_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInv(Item, 14, 22, 7);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 7, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_MaximumInventory()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvWithDemand(Item, 14, 22, 18);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 17, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 18, AcceptAction(false), SSDemandDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_MaximumInventory_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvWithDemand(Item, 14, 22, 18);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 17, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 1, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 17, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_MaximumInventory_BelowZero()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvWithDemand(Item, 14, 22, 23);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 17, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 23, AcceptAction(false), SSDemandDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_MaximumInventory_BelowZero_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvWithDemand(Item, 14, 22, 23);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 17, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 6, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 17, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_OM_MaximumInventory_BelowZero()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvWithDemand(Item, 21, 22, 27);
        SetOrderModifiers(Item, 5, 10, 20);

        CalculatePlanFor(Item, RespectParameters(true));

        // There is a by design inconsistency where, when using Maximum Order Quantity in Scenario when you,
        // get a below safety stock exception in the middle of a planning period, planning engine will only
        // order up to safety stock, and not to reorder point/maximum inventory. This test serves as
        // documentation of this decision.

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_OM_MaximumInventory_BelowZero_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvWithDemand(Item, 14, 22, 23);
        SetOrderModifiers(Item, 5, 0, 25);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 3, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQltSS()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 14, 3, 7);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQltSS_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 14, 3, 7);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 9, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 7, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQltROP()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 14, 10, 7);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQltROP_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 14, 10, 7);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 7, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQltROP_2()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 13, 7, 7);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 14, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQltROP_3()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 14, 7, 7);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 21, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQltROP_OrderMultiple()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 13, 7, 6);
        SetOrderModifiers(Item, 10, 0, 0);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQltROP_MinQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 13, 7, 13);
        SetOrderModifiers(Item, 0, 15, 0);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQltROP_MaxQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 14, 10, 6);
        SetOrderModifiers(Item, 0, 0, 7);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 7, AcceptAction(false), StartingDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 7, AcceptAction(false), StartingDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 7, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQeqROP()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 14, 14, 7);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 28, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_ROP_RQgtROP()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROP(Item, 14, 15, 7);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_ROP_RQltSS()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROPWithDemand(Item, 13, 3, 12);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 9, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 3, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 9, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_ROP_RQltSS_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROPWithDemand(Item, 13, 3, 12);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 9, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 3, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 9, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_ROP_RQltSS_BelowZero()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROPWithDemand(Item, 13, 3, 17);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 9, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 8, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 9, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_ROP_RQltSS_BelowZero_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROPWithDemand(Item, 13, 3, 17);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 9, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 8, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 9, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_ROP_RQltROP()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROPWithDemand(Item, 13, 10, 12);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(false), SSDemandDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_ROP_RQltROP_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROPWithDemand(Item, 13, 10, 12);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 2, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_ROP_RQltROP_2()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROPWithDemand(Item, 13, 10, 13);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_ROP_RQltROP_MaxQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderROPWithDemand(Item, 13, 10, 12);
        SetOrderModifiers(Item, 0, 0, 4);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 7);

        ValidateNextPlanningLine(RequisitionLine, Item, 4, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 4, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 2, AcceptAction(true), StartingDate());

        // There is a by design inconsistency where, when using Maximum Order Quantity in Scenario when you,
        // get a below safety stock exception in the middle of a planning period, planning engine will only
        // order up to safety stock, and not to reorder point. This test serves as documentation of this decision.

        ValidateNextPlanningLine(RequisitionLine, Item, 4, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 4, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
        ValidateNextPlanningLine(RequisitionLine, Item, 4, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
        ValidateNextPlanningLine(RequisitionLine, Item, 2, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_LFL_OrderMultiple()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeLotForLotOM(Item, 3);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_LFL_OrderMultiple_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeLotForLotOM(Item, 3);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 3, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_LFL_MinQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeLotForLotOM(Item, 18);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_LFL_MinQty_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeLotForLotOM(Item, 18);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 18, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_LFL_MaxQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeLotForLotOM(Item, 28);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 25, AcceptAction(false), StartingDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_LFL_MaxQty_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeLotForLotOM(Item, 28);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 28, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_MaxInv_OrderMultiple()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOM(Item, 14, 17, 13);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_MaxInv_OrderMultiple_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOM(Item, 19, 27, 18);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 18, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_MaxInv_MinQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOM(Item, 5, 6, 3);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_MaxInv_MinQty_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOM(Item, 10, 17, 3);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 3, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_MaxInv_MaxQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOM(Item, 29, 37, 28);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 25, AcceptAction(false), StartingDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_MaxInv_MaxQty_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOM(Item, 29, 37, 28);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 28, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_MinQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOMWithDemand(Item, 10, 13, 11);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(false), SSDemandDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_MinQty_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOMWithDemand(Item, 10, 17, 16);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 1, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_MaxQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOMWithDemand(Item, 10, 17, 41);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 25, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(false), SSDemandDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_MaxInv_Maximum_Qty_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeMaxInvOMWithDemand(Item, 10, 17, 41);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 4);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 25, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 1, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_OrderMultiple()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        SafetyStock: Integer;
    begin
        SafetyStock := 18;
        InitializeFixedReorderOM(Item, 19, 1, SafetyStock);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);

        ValidateTrackingLineCount(UntrackedPlanningElement, Item, RequisitionLine."Line No.", 3);
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, SafetyStock, SafetyStock, 'Safety Stock Quantity');
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, 0, 0, SSExceptionText(SafetyStock, StartingDate()));
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_OrderMultiple_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        SafetyStock: Integer;
    begin
        SafetyStock := 18;
        InitializeFixedReorderOM(Item, 19, 1, SafetyStock);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);

        ValidateTrackingLineCount(UntrackedPlanningElement, Item, RequisitionLine."Line No.", 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());

        ValidateTrackingLineCount(UntrackedPlanningElement, Item, RequisitionLine."Line No.", 2);
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, SafetyStock, SafetyStock, 'Safety Stock Quantity');
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, 0, 0, SSExceptionText(SafetyStock, StartingDate()));
        ValidateNextPlanningLine(RequisitionLine, Item, SafetyStock, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_MinQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        SafetyStock: Integer;
    begin
        SafetyStock := 5;
        InitializeFixedReorderOM(Item, 9, 1, SafetyStock);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 1);

        ValidateTrackingLineCount(UntrackedPlanningElement, Item, RequisitionLine."Line No.", 3);
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, SafetyStock, SafetyStock, 'Safety Stock Quantity');
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, 0, 0, SSExceptionText(SafetyStock, StartingDate()));
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_MinQty_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        SafetyStock: Integer;
    begin
        SafetyStock := 5;
        InitializeFixedReorderOM(Item, 9, 1, SafetyStock);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);

        ValidateTrackingLineCount(UntrackedPlanningElement, Item, RequisitionLine."Line No.", 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());

        ValidateTrackingLineCount(UntrackedPlanningElement, Item, RequisitionLine."Line No.", 2);
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, SafetyStock, SafetyStock, 'Safety Stock Quantity');
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, 0, 0, SSExceptionText(SafetyStock, StartingDate()));
        ValidateNextPlanningLine(RequisitionLine, Item, 5, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_MaxQty()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        SafetyStock: Integer;
        ReorderQuantity: Integer;
    begin
        SafetyStock := 28;
        ReorderQuantity := 7;
        InitializeFixedReorderOM(Item, 29, ReorderQuantity, SafetyStock);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);

        ValidateTrackingLineCount(UntrackedPlanningElement, Item, RequisitionLine."Line No.", 2);
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, SafetyStock, GLB_MaxQty(), 'Safety Stock Quantity');
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, 0, 0, SSExceptionText(SafetyStock, StartingDate()));
        ValidateNextPlanningLine(RequisitionLine, Item, GLB_MaxQty(), AcceptAction(false), StartingDate() - 1);

        ValidateTrackingLineCount(UntrackedPlanningElement, Item, RequisitionLine."Line No.", 4);
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, SafetyStock, SafetyStock - GLB_MaxQty(), 'Safety Stock Quantity');
        ValidateNextTrackingLine(
          UntrackedPlanningElement, Item, ReorderQuantity, ReorderQuantity - (SafetyStock - GLB_MaxQty()), 'Reorder Quantity');
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, GLB_MinQty(), GLB_MinQty() - ReorderQuantity, 'Minimum Order Quantity');
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, 0, 0, SSExceptionText(SafetyStock, StartingDate()));
        ValidateNextPlanningLine(RequisitionLine, Item, GLB_MinQty(), AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSPlanStart_FixedReorder_MaxQty_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOM(Item, 29, 7, 28);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 28, AcceptAction(false), StartingDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_OrderMultiple()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOMWithDemand(Item, 10, 1, 22);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 15, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_OrderMultiple_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOMWithDemand(Item, 9, 7, 22);

        // When using Fixed Reorder Quantity and there is a demand that projects availability
        // to below zero, the planning parameters are still used, even if flag set to ignore.
        // Known inconsistent behaviour.

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 12, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_MinQty_BelowSS()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOMWithDemand(Item, 5, 7, 12);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(false), SSDemandDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_MinQty_BelowSS_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOMWithDemand(Item, 9, 7, 12);

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 2, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_MinQty_BelowZero()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOMWithDemand(Item, 9, 7, 26);
        // Fixed Reorder will now order up to reorder point also in the
        // middle of planning period. Change in parameters necessary here.
        SetOrderModifiers(Item, 5, 20, 25);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(false), SSDemandDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_MinQty_BelowZero_2()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOMWithDemand(Item, 9, 7, 26);
        // Fixed Reorder will now order up to reorder point also in the
        // middle of planning period. Change in parameters necessary.
        SetOrderModifiers(Item, 5, 20, 25);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 2);
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 20, AcceptAction(false), SSDemandDate() - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_MinQty_BelowZero_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOMWithDemand(Item, 9, 7, 17);

        // When using Fixed Reorder Quantity and there is a demand that projects availability
        // to below zero, the planning parameters are still used, even if flag set to ignore.
        // Known inconsistent behaviour.

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 3);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 7, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_MaxQty_BelowZero()
    var
        Item: Record Item;
        UntrackedPlanningElement: Record "Untracked Planning Element";
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOMWithDemand(Item, 10, 7, 67);

        CalculatePlanFor(Item, RespectParameters(true));

        ValidatePlanningLineCount(RequisitionLine, Item, 5);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 25, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 25, AcceptAction(false), SSDemandDate() - 1);

        ValidateTrackingLineCount(UntrackedPlanningElement, Item, RequisitionLine."Line No.", 3);
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, 5, 5, 'Safety Stock Quantity');
        ValidateNextTrackingLine(UntrackedPlanningElement, Item, 10, 3, 'Minimum Order Quantity');
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Exception_SSDemand_FixedReorder_MaxQty_BelowZero_Ignore()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeFixedReorderOMWithDemand(Item, 10, 7, 67);

        // When using Fixed Reorder Quantity and there is a demand that projects availability
        // to below zero, the planning parameters are still used, even if flag set to ignore.
        // Known inconsistent behaviour.

        CalculatePlanFor(Item, RespectParameters(false));

        ValidatePlanningLineCount(RequisitionLine, Item, 5);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), StartingDate());
        ValidateNextPlanningLine(RequisitionLine, Item, 25, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 25, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 7, AcceptAction(false), SSDemandDate() - 1);
        ValidateNextPlanningLine(RequisitionLine, Item, 10, AcceptAction(true), TimeBucketEnd(Item, StartingDate()));
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        TimeBucket: DateFormula;
    begin
        LibraryInventory.CreateItem(Item);
        Evaluate(TimeBucket, '<1W>');
        Item.Validate("Time Bucket", TimeBucket);
        Item.Modify(true);
    end;

    local procedure CalculatePlanFor(Item: Record Item; RespectParameters: Boolean)
    var
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, StartingDate(), EndingDate(), RespectParameters);
    end;

    local procedure SetOrderModifiers(var Item: Record Item; OrderMultiple: Integer; MinimumQty: Integer; MaximumQty: Integer)
    begin
        Item.Validate("Order Multiple", OrderMultiple);
        Item.Validate("Minimum Order Quantity", MinimumQty);
        Item.Validate("Maximum Order Quantity", MaximumQty);
        Item.Modify(true);
    end;

    local procedure ValidateNextPlanningLine(var RequisitionLine: Record "Requisition Line"; Item: Record Item; Quantity: Integer; AcceptActionMessage: Boolean; StartingDate: Date)
    begin
        Assert.AreEqual(Item."No.", RequisitionLine."No.",
          'Unexpected Item No. on Requisition Line.');
        Assert.AreEqual(RequisitionLine."Action Message"::New, RequisitionLine."Action Message",
          'Unexpected Action Message on Requistion Line');
        Assert.AreEqual(AcceptActionMessage, RequisitionLine."Accept Action Message",
          'Unexpected Accept Action Message on Requistion Line');
        Assert.AreEqual(Quantity, RequisitionLine.Quantity,
          'Unexpected Quantity on Requistion Line');
        Assert.AreEqual(StartingDate, RequisitionLine."Starting Date",
          'Unexpected Starting Date on Requistion Line');
        Assert.AreEqual(StartingDate + 1, RequisitionLine."Due Date",
          'Unexpected Due Date on Requistion Line');

        RequisitionLine.Next();
    end;

    local procedure ValidatePlanningLineCount(var RequisitionLine: Record "Requisition Line"; Item: Record Item; "Count": Integer)
    begin
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindSet();
        Assert.IsTrue(RequisitionLine.Count >= Count,
          StrSubstNo('Missing planning lines. Expected: %1. Actual: %2', Count, RequisitionLine.Count));
        Assert.IsTrue(RequisitionLine.Count <= Count,
          StrSubstNo('Excess planning lines. Expected: %1. Actual: %2', Count, RequisitionLine.Count));
    end;

    local procedure ValidateNextTrackingLine(var UntrackedPlanningElement: Record "Untracked Planning Element"; Item: Record Item; ParameterValue: Integer; UntrackedQuantity: Integer; Source: Text[200])
    begin
        Assert.AreEqual(Item."No.", UntrackedPlanningElement."Item No.",
          'Unexpected Item No. on Tracking Line.');
        if ParameterValue > 0 then
            Assert.AreEqual(ParameterValue, UntrackedPlanningElement."Parameter Value",
              'Unexpected Parameter Value on Tracking Line');
        Assert.AreEqual(UntrackedQuantity, UntrackedPlanningElement."Untracked Quantity",
          'Unexpected Untracked Quantity on Planning Line');
        Assert.AreEqual(Source, UntrackedPlanningElement.Source,
          'Unexpected Source text on Planning Line');

        UntrackedPlanningElement.Next();
    end;

    local procedure ValidateTrackingLineCount(var UntrackedPlanningElement: Record "Untracked Planning Element"; Item: Record Item; RequisitionLineNo: Integer; "Count": Integer)
    begin
        Clear(UntrackedPlanningElement);
        UntrackedPlanningElement.SetRange("Item No.", Item."No.");
        UntrackedPlanningElement.SetRange("Worksheet Line No.", RequisitionLineNo);
        UntrackedPlanningElement.FindSet();
        Assert.IsTrue(Count >= UntrackedPlanningElement.Count,
          StrSubstNo('Missing tracking lines. Expected: %1. Actual: %2', Count, UntrackedPlanningElement.Count));
        Assert.IsTrue(Count <= UntrackedPlanningElement.Count,
          StrSubstNo('Excess tracking lines. Expected: %1. Actual: %2', Count, UntrackedPlanningElement.Count));
    end;

    local procedure StartingDate(): Date
    begin
        exit(WorkDate());
    end;

    local procedure EndingDate(): Date
    begin
        exit(WorkDate() + 10);
    end;

    local procedure SSDemandDate(): Date
    begin
        exit(WorkDate() + 6);
    end;

    local procedure AcceptAction(Accept: Boolean): Boolean
    begin
        exit(Accept);
    end;

    local procedure RespectParameters(Ignore: Boolean): Boolean
    begin
        exit(Ignore);
    end;

    local procedure TimeBucketEnd(Item: Record Item; StartingDate: Date): Date
    var
        TimeBucketEndingDate: Date;
    begin
        TimeBucketEndingDate := CalcDate(Item."Time Bucket", StartingDate);
        exit(TimeBucketEndingDate);
    end;

    local procedure SSExceptionText(SafetyStockQuantity: Integer; StartDate: Date): Text[200]
    begin
        exit(
          StrSubstNo(
            'Exception: The projected available inventory is below Safety Stock Quantity %1 on %2.', SafetyStockQuantity, StartDate));
    end;

    local procedure GLB_MinQty(): Integer
    begin
        exit(10);
    end;

    local procedure GLB_MaxQty(): Integer
    begin
        exit(25);
    end;
}

