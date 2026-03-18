codeunit 132205 "Library - Kitting"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        ITEM_DESC: Label 'Test Calculate Sales Price';
        POSTING_GRP_DESC: Label 'Test Assembly Orders';

    procedure ItemMake(var Item: Record Item; ItemName: Code[20])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        TaxGroup: Record "Tax Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        Clear(Item);
        Item.Validate("No.", ItemName);
        Item.Insert(true);
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure.Validate("Item No.", Item."No.");
        UnitOfMeasure.FindFirst();
        ItemUnitOfMeasure.Validate(Code, UnitOfMeasure.Code);
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", 1);
        ItemUnitOfMeasure.Insert(true);
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        if VATProdPostingGroup.FindLast() then
            Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup.Code);
        InventoryPostingGroup.FindFirst();
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);

        if TaxGroup.FindFirst() then
            Item.Validate("Tax Group Code", TaxGroup.Code);

        Item.Modify(true);
    end;

    procedure ItemCreate(ItemName: Code[20]; Description: Text[30]; BaseUOM: Code[10]; UnitPrice: Decimal; StdCost: Decimal): Code[20]
    var
        ItemUOM: Record "Item Unit of Measure";
        Item: Record Item;
    begin
        ItemMake(Item, ItemName);
        Item.Validate(Description, Description);
        ItemUOM.Get(Item."No.", Item."Base Unit of Measure");
        Item.Validate("Base Unit of Measure", '');
        Item.Modify(true);
        ItemUOM.Delete(true);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM, 1);
        Item.Validate("Base Unit of Measure", BaseUOM);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Standard Cost", StdCost);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", StdCost);
        Item.Validate("Single-Level Material Cost", StdCost);
        Item.Validate("Rolled-up Material Cost", StdCost);
        Item.Modify(true);
        exit(Item."No.");
    end;

    procedure CreateItemWithNewUOM(Cost: Decimal; Price: Decimal): Code[20]
    var
        UOM: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        exit(CreateItem(Cost, Price, UOM.Code));
    end;

    procedure CreateItem(Cost: Decimal; Price: Decimal; UOM: Code[10]): Code[20]
    var
        Item: Record Item;
        InvtPostingGroup: Record "Inventory Posting Group";
        NoSeries: Codeunit "No. Series";
    begin
        Item.Get(ItemCreate(NoSeries.GetNextNo(CreateNoSeries()), ITEM_DESC, UOM, Price, Cost));
        CreateInvPostGroup(InvtPostingGroup);
        Item.Validate("Inventory Posting Group", InvtPostingGroup.Code);
        Item.Modify();
        exit(Item."No.");
    end;

    procedure CreateItemWithNewUOMUsingItemNo(ItemNo: Code[20]; Cost: Decimal; Price: Decimal): Code[20]
    var
        UOM: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        exit(CreateItemNo(ItemNo, Cost, Price, UOM.Code));
    end;

    procedure CreateItemNo(Number: Code[20]; Cost: Decimal; Price: Decimal; UOM: Code[10]): Code[20]
    var
        Item: Record Item;
        InvtPostingGroup: Record "Inventory Posting Group";
        NoSeries: Codeunit "No. Series";
    begin
        if Number = '' then
            Number := NoSeries.GetNextNo(CreateNoSeries());
        Item.Get(ItemCreate(Number, ITEM_DESC, UOM, Price, Cost));
        CreateInvPostGroup(InvtPostingGroup);
        Item.Validate("Inventory Posting Group", InvtPostingGroup.Code);
        Item.Modify();
        exit(Item."No.");
    end;

    procedure CreateItemWithLotAndNewUOM(Cost: Decimal; Price: Decimal; LotSize: Decimal): Code[20]
    var
        UOM: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        exit(CreateItemwithLot(Cost, Price, UOM.Code, LotSize));
    end;

    procedure CreateItemwithLot(Cost: Decimal; Price: Decimal; UOM: Code[10]; Lot: Decimal): Code[20]
    var
        Item: Record Item;
        InvtPostingGroup: Record "Inventory Posting Group";
        NoSeries: Codeunit "No. Series";
    begin
        Item.Get(ItemCreate(NoSeries.GetNextNo(CreateNoSeries()), ITEM_DESC, UOM, Price, Cost));
        Item."Lot Size" := Lot;
        CreateInvPostGroup(InvtPostingGroup);
        Item.Validate("Inventory Posting Group", InvtPostingGroup.Code);
        Item.Modify();
        exit(Item."No.");
    end;

    procedure CreateStdCostItemWithNewUOM(Cost: Decimal; Price: Decimal; LotSize: Decimal): Code[20]
    var
        UOM: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        exit(CreateItemwithStandard(Cost, Price, UOM.Code, LotSize));
    end;

    procedure CreateItemwithStandard(Cost: Decimal; Price: Decimal; UOM: Code[10]; Lot: Decimal): Code[20]
    var
        Item: Record Item;
        InvtPostingGroup: Record "Inventory Posting Group";
        NoSeries: Codeunit "No. Series";
    begin
        Item.Get(ItemCreate(NoSeries.GetNextNo(CreateNoSeries()), ITEM_DESC, UOM, Price, Cost));
        Item."Lot Size" := Lot;
        CreateInvPostGroup(InvtPostingGroup);
        Item.Validate("Inventory Posting Group", InvtPostingGroup.Code);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Modify();
        exit(Item."No.");
    end;

    procedure CreateItemWithLotAndNewUOMUsingItemNo(ItemNo: Code[20]; Cost: Decimal; Price: Decimal; LotSize: Decimal): Code[20]
    var
        UOM: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        exit(CreateItemwithLotNo(ItemNo, Cost, Price, UOM.Code, LotSize));
    end;

    procedure CreateItemwithLotNo(Number: Code[20]; Cost: Decimal; Price: Decimal; UOM: Code[10]; Lot: Decimal): Code[20]
    var
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        NoSeries: Codeunit "No. Series";
    begin
        if Number = '' then
            Number := NoSeries.GetNextNo(CreateNoSeries());
        Item.Get(ItemCreate(Number, ITEM_DESC, UOM, Price, Cost));
        Item."Lot Size" := Lot;
        CreateInvPostGroup(InventoryPostingGroup);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Modify();
        exit(Item."No.");
    end;

    procedure CreateStdCostItemWithNewUOMUsingItemNo(ItemNo: Code[20]; Cost: Decimal; Price: Decimal; LotSize: Decimal): Code[20]
    var
        UOM: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        exit(CreateItemwithStandardNo(ItemNo, Cost, Price, UOM.Code, LotSize));
    end;

    procedure CreateItemwithStandardNo(Number: Code[20]; Cost: Decimal; Price: Decimal; UOM: Code[10]; Lot: Decimal): Code[20]
    var
        Item: Record Item;
        InvtPostingGroup: Record "Inventory Posting Group";
        NoSeries: Codeunit "No. Series";
    begin
        if Number = '' then
            Number := NoSeries.GetNextNo(CreateNoSeries());
        Item.Get(ItemCreate(Number, ITEM_DESC, UOM, Price, Cost));
        Item."Lot Size" := Lot;
        CreateInvPostGroup(InvtPostingGroup);
        Item.Validate("Inventory Posting Group", InvtPostingGroup.Code);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Modify();
        exit(Item."No.");
    end;

    procedure CreateResourceWithNewUOM(Cost: Decimal; Price: Decimal): Code[20]
    var
        UOM: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        exit(CreateResource(Cost, Price, UOM.Code));
    end;

    procedure CreateResource(Cost: Decimal; Price: Decimal; UOM: Code[10]): Code[20]
    var
        Resource: Record Resource;
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        CreateUnitOfMeasure(UOM);
        ResourceMake(Resource, LibraryUtility.GenerateGUID());
        Resource.Validate("Unit Cost", Cost);
        Resource.Validate("Unit Price", Price);
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, Resource."No.", UOM, 1);
        ResourceUnitOfMeasure.Validate("Related to Base Unit of Meas.", true);
        ResourceUnitOfMeasure.Modify(true);
        Resource.Validate("Base Unit of Measure", UOM);
        CreateResourceInvPostGroup(GenProductPostingGroup);
        Resource.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        Resource.Modify();
        exit(Resource."No.");
    end;

    procedure CreateOrder(DueDate: Date; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        CreateAssemblySetup();
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ItemNo, '', Quantity, '');
        exit(AssemblyHeader."No.");
    end;

    procedure CreateOrderNo(DueDate: Date; Number: Code[20]; Item: Code[20]; Quantity: Decimal): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        CreateAssemblySetup();
        Clear(AssemblyHeader);
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader."No." := Number;
        AssemblyHeader.Insert(true);
        AssemblyHeader.Validate("Due Date", DueDate);
        AssemblyHeader.Validate("Item No.", Item);
        AssemblyHeader.Validate(Quantity, Quantity);
        AssemblyHeader.Modify(true);
        exit(AssemblyHeader."No.");
    end;

    procedure CreateInvPostGroup(var InventoryPostingGroup: Record "Inventory Posting Group")
    begin
        if InventoryPostingGroup.FindFirst() then
            exit;
        InventoryPostingGroup.Code := 'A';
        InventoryPostingGroup.Description := POSTING_GRP_DESC;
        InventoryPostingGroup.Insert();
    end;

    procedure CreateResourceInvPostGroup(var GenProductPostingGroup: Record "Gen. Product Posting Group")
    begin
        if GenProductPostingGroup.FindFirst() then
            exit;
        GenProductPostingGroup.Code := 'A';
        GenProductPostingGroup.Description := POSTING_GRP_DESC;
        GenProductPostingGroup.Insert();
    end;

    procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Init();
        NoSeries.Code := CopyStr(CreateGuid(), 1, 10);    // todo: use the last instead of the first charackters
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        if not NoSeries.Insert() then;

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Starting No." := CopyStr(NoSeries.Code, 1, 10) + '0000000001';
        NoSeriesLine."Increment-by No." := 1;
        if not NoSeriesLine.Insert() then;

        exit(NoSeries.Code);
    end;

    procedure CreateAssemblySetup()
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Init();
        AssemblySetup."Primary Key" := '';
        AssemblySetup."Assembly Order Nos." := CreateNoSeries();
        if not AssemblySetup.Insert() then;
    end;

    procedure CreateBOMComponentLine(var ParentItem: Record Item; Type: Enum "BOM Component Type"; No: Code[20]; Quantity: Decimal; UOMCode: Code[10]; "Fixed": Boolean)
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateUnitOfMeasure(UOMCode);
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItem."No.", Type, No, Quantity, UOMCode);
        if (Type = "BOM Component Type"::Resource) and Fixed then begin
            BOMComponent.Validate("Resource Usage Type", BOMComponent."Resource Usage Type"::Fixed);
            BOMComponent.Modify(true);
        end;
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Modify(true);
    end;

    local procedure CreateUnitOfMeasure(UOMCode: Code[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not UnitOfMeasure.Get(UOMCode) then begin
            UnitOfMeasure.Init();
            UnitOfMeasure.Code := UOMCode;
            UnitOfMeasure.Insert(true);
        end;
    end;

    procedure ResourceMake(var Resource: Record Resource; ResourceNo: Code[20])
    var
        ResUnitOfMeasure: Record "Resource Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        Clear(Resource);
        Resource.Validate("No.", ResourceNo);
        Resource.Insert(true);
        UnitOfMeasure.FindFirst();
        LibraryResource.CreateResourceUnitOfMeasure(ResUnitOfMeasure, ResourceNo, UnitOfMeasure.Code, 1);
        Resource.Validate("Base Unit of Measure", ResUnitOfMeasure.Code);
        GenProdPostingGroup.FindLast();
        Resource.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
        if VATProdPostingGroup.FindFirst() then
            Resource.Validate("VAT Prod. Posting Group", VATProdPostingGroup.Code);
        Resource.Modify(true);
    end;

    procedure SetLookahead(LookahedFormula: Text[30])
    var
        CompanyInfo: Record "Company Information";
    begin
        if CompanyInfo.Get() then;
        Evaluate(CompanyInfo."Check-Avail. Period Calc.", LookahedFormula);
        CompanyInfo."Check-Avail. Time Bucket" := CompanyInfo."Check-Avail. Time Bucket"::Day;
        if not CompanyInfo.Insert() then
            CompanyInfo.Modify();
    end;

#if not CLEAN27
#pragma warning disable AL0801
    [Obsolete('Moved to codeunit LibraryManufacturing', '27.0')]
    procedure AddProdBOMItem(var MfgItem: Record Item; SubItemNo: Code[20]; Qty: Decimal)
    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
    begin
        LibraryManufacturing.AddProdBOMItem(MfgItem, SubItemNo, Qty);
    end;
#pragma warning restore AL0801
#endif

    procedure SetCopyFrom(CopyFrom: Option "Order Header","Item/Resource Card")
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup."Copy Component Dimensions from" := CopyFrom;
        AssemblySetup.Modify();
    end;

    procedure AddLine(AsmHeader: Record "Assembly Header"; Type: Enum "BOM Component Type"; No: Code[20]; UOMCode: Code[10]; Quantity: Decimal; QtyPer: Integer; Desc: Text[50])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AssemblyLine, Type, No, UOMCode, Quantity, QtyPer, Desc);
    end;

    procedure TotalQuantity(AssemblyHeader: Record "Assembly Header"): Decimal
    var
        AssemblyLine: Record "Assembly Line";
        LibraryAssembly: Codeunit "Library - Assembly";
        TempCount: Decimal;
    begin
        LibraryAssembly.SetLinkToLines(AssemblyHeader, AssemblyLine);
        TempCount := 0;
        if AssemblyLine.FindSet() then
            repeat
                TempCount += AssemblyLine.Quantity;
            until AssemblyLine.Next() = 0;
        exit(TempCount);
    end;
}

