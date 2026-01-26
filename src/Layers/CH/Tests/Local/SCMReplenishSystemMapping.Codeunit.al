codeunit 144004 "SCM Replenish. System Mapping"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialzied := false;
    end;

    var
        ItemRef: Record Item;
        RequisitionLineRef: Record "Requisition Line";
        StockkeepingUnitRef: Record "Stockkeeping Unit";
        Assert: Codeunit Assert;
        ReplSysIsIncorrectErr: Label 'Replenishment System value is incorrect.';
        ReqWorksheetCannotUseErr: Label 'Requisition Worksheet cannot be used to create Prod. Order replenishment.';
        IsInitialzied: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialzied then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialzied := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateItemRequisiionLineWithReplenishmentSystem_Purchase()
    begin
        CheckValidateRequsitionLine(
          ItemRef."Replenishment System"::Purchase, RequisitionLineRef."Replenishment System"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateItemRequisiionLineWithReplenishmentSystem_ProductionOrder()
    begin
        asserterror
          CheckValidateRequsitionLine(
            ItemRef."Replenishment System"::"Prod. Order", RequisitionLineRef."Replenishment System"::"Prod. Order");
        Assert.ExpectedError(ReqWorksheetCannotUseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateItemRequisiionLineWithReplenishmentSystem_None()
    begin
        CheckValidateRequsitionLine(
          ItemRef."Replenishment System"::" ", RequisitionLineRef."Replenishment System"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateItemRequisiionLineWithReplenishmentSystem_Assembly()
    begin
        CheckValidateRequsitionLine(
          ItemRef."Replenishment System"::Assembly, RequisitionLineRef."Replenishment System"::Assembly);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateStockkeepingUnitWithReplenishmentSystem_Purchase()
    begin
        CheckValidateStokkeepingUnit(
          ItemRef."Replenishment System"::Purchase, StockkeepingUnitRef."Replenishment System"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateStockkeepingUnitWithReplenishmentSystem_ProductionOrder()
    begin
        CheckValidateStokkeepingUnit(
          ItemRef."Replenishment System"::"Prod. Order", StockkeepingUnitRef."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateStockkeepingUnitWithReplenishmentSystem_None()
    begin
        CheckValidateStokkeepingUnit(
          ItemRef."Replenishment System"::" ", StockkeepingUnitRef."Replenishment System"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateStockkeepingUnitWithReplenishmentSystem_Assembly()
    begin
        CheckValidateStokkeepingUnit(
          ItemRef."Replenishment System"::Assembly, StockkeepingUnitRef."Replenishment System"::Assembly);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStockkeepingUnitWithReplenishmentSystem_Purchase()
    begin
        CheckCreateStokkeepingUnit(
          ItemRef."Replenishment System"::Purchase, StockkeepingUnitRef."Replenishment System"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStockkeepingUnitWithReplenishmentSystem_ProductionOrder()
    begin
        CheckCreateStokkeepingUnit(
          ItemRef."Replenishment System"::"Prod. Order", StockkeepingUnitRef."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStockkeepingUnitWithReplenishmentSystem_None()
    begin
        CheckCreateStokkeepingUnit(
          ItemRef."Replenishment System"::" ", StockkeepingUnitRef."Replenishment System"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStockkeepingUnitWithReplenishmentSystem_Assembly()
    begin
        CheckCreateStokkeepingUnit(
          ItemRef."Replenishment System"::Assembly, StockkeepingUnitRef."Replenishment System"::Assembly);
    end;

    local procedure CheckValidateRequsitionLine(ItemReplenishmentSystem: Enum "Replenishment System"; ExpectedReqLineReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // SETUP
        Initialize();
        CreateItemWithReplenishmentSystem(Item, ItemReplenishmentSystem);

        // EXERCISE
        CreateRequisitionLine(RequisitionLine, Item."No.");

        // VERIFY
        Assert.AreEqual(ExpectedReqLineReplenishmentSystem, RequisitionLine."Replenishment System", ReplSysIsIncorrectErr);
    end;

    local procedure CheckValidateStokkeepingUnit(ItemReplenishmentSystem: Enum "Replenishment System"; ExpectedReqLineReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // SETUP
        Initialize();
        CreateItemWithReplenishmentSystem(Item, ItemReplenishmentSystem);

        // EXERCISE
        StockkeepingUnitValidateItemNo(StockkeepingUnit, Item."No.");

        // VERIFY
        Assert.AreEqual(ExpectedReqLineReplenishmentSystem, StockkeepingUnit."Replenishment System", ReplSysIsIncorrectErr);
    end;

    local procedure CheckCreateStokkeepingUnit(ItemReplenishmentSystem: Enum "Replenishment System"; ExpectedReqLineReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // SETUP
        Initialize();
        CreateItemWithReplenishmentSystem(Item, ItemReplenishmentSystem);

        // EXERCISE
        CreateStockkeepingUnitByReport(StockkeepingUnit, Item);

        // VERIFY
        Assert.AreEqual(ExpectedReqLineReplenishmentSystem, StockkeepingUnit."Replenishment System", ReplSysIsIncorrectErr);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        LibraryPlanning: Codeunit "Library - Planning";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
    end;

    local procedure CreateItemWithReplenishmentSystem(var Item: Record Item; ItemReplenishmentSystem: Enum "Replenishment System")
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ItemReplenishmentSystem);
        Item.Modify();
    end;

    local procedure StockkeepingUnitValidateItemNo(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20])
    begin
        StockkeepingUnit.Init();
        StockkeepingUnit.Validate("Item No.", ItemNo);
        StockkeepingUnit.Validate("Location Code", CreateLocation());
    end;

    local procedure CreateStockkeepingUnitByReport(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    var
        Location: Record Location;
    begin
        Location.Get(CreateLocation());
        Item.SetRange("Location Filter", Location.Code);
        Item.SetRecFilter();
        REPORT.Run(REPORT::"Create Stockkeeping Unit", false, false, Item);
        StockkeepingUnit.SetRange("Location Code", Location.Code);
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindFirst();
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;
}

