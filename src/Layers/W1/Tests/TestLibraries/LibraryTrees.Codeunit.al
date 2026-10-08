codeunit 132208 "Library - Trees"
{
    Subtype = Normal;

    trigger OnRun()
    begin
    end;

    var
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        SupplyType: Option Inventory,Purchase,"Prod. Order";

    [Normal]
    procedure AddOverhead(var TempItem: Record Item temporary; var TempResource: Record Resource temporary; var TempWorkCenter: Record "Work Center" temporary; var TempMachineCenter: Record "Machine Center" temporary)
    var
        Resource: Record Resource;
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        if TempItem.FindSet() then
            repeat
                LibraryAssembly.ModifyItem(TempItem."No.", true, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
            until TempItem.Next() = 0;

        if TempResource.FindSet() then
            repeat
                Resource.Get(TempResource."No.");
                Resource.Validate("Indirect Cost %", LibraryRandom.RandInt(5));
                Resource.Modify(true);
            until TempResource.Next() = 0;

        if TempWorkCenter.FindSet() then
            repeat
                WorkCenter.Get(TempWorkCenter."No.");
                WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandInt(5));
                WorkCenter.Validate("Overhead Rate", LibraryRandom.RandInt(5));
                WorkCenter.Modify(true);
            until TempWorkCenter.Next() = 0;

        if TempMachineCenter.FindSet() then
            repeat
                MachineCenter.Get(TempMachineCenter."No.");
                MachineCenter.Validate("Indirect Cost %", LibraryRandom.RandInt(5));
                MachineCenter.Validate("Overhead Rate", LibraryRandom.RandInt(5));
                MachineCenter.Modify(true);
            until TempMachineCenter.Next() = 0;
    end;

    [Normal]
    procedure AddCostToRouting(var TempWorkCenter: Record "Work Center" temporary; var TempMachineCenter: Record "Machine Center" temporary)
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        if TempWorkCenter.FindSet() then
            repeat
                WorkCenter.Get(TempWorkCenter."No.");
                WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandInt(5));
                WorkCenter.Modify(true);
            until TempWorkCenter.Next() = 0;

        if TempMachineCenter.FindSet() then
            repeat
                MachineCenter.Get(TempMachineCenter."No.");
                MachineCenter.Validate("Direct Unit Cost", LibraryRandom.RandInt(5));
                MachineCenter.Modify(true);
            until TempMachineCenter.Next() = 0;
    end;

    [Normal]
    procedure AddSubcontracting(var TempWorkCenter: Record "Work Center" temporary)
    var
        WorkCenter: Record "Work Center";
        Vendor: Record Vendor;
    begin
        if TempWorkCenter.FindSet() then begin
            TempWorkCenter.Next(LibraryRandom.RandInt(TempWorkCenter.Count));
            WorkCenter.Get(TempWorkCenter."No.");
            LibraryPurchase.CreateSubcontractor(Vendor);
            WorkCenter.Validate("Subcontractor No.", Vendor."No.");
            WorkCenter.Modify(true);
        end;
    end;

    [Normal]
    procedure AddScrapForItems(var TempItem: Record Item temporary)
    var
        Item: Record Item;
    begin
        if TempItem.FindSet() then
            repeat
                Item.Get(TempItem."No.");
                Item.Validate("Scrap %", LibraryRandom.RandInt(10));
                Item.Modify(true);
            until TempItem.Next() = 0;
    end;

    [Normal]
    procedure AddScrapForRoutings(var TempItem: Record Item temporary)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        if TempItem.FindSet() then
            repeat
                if RoutingHeader.Get(TempItem."Routing No.") then begin
                    RoutingHeader.Validate(Status, RoutingHeader.Status::"Under Development");
                    RoutingHeader.Modify(true);
                    RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
                    if RoutingLine.FindSet() then
                        repeat
                            RoutingLine.Validate("Scrap Factor %", LibraryRandom.RandInt(10));
                            RoutingLine.Modify(true);
                        until RoutingLine.Next() = 0;
                    RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
                    RoutingHeader.Modify(true);
                end;
            until TempItem.Next() = 0;
    end;

    [Normal]
    procedure AddScrapForProdBOM(var TempItem: Record Item temporary)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        if TempItem.FindSet() then
            repeat
                if ProdBOMHeader.Get(TempItem."Production BOM No.") then begin
                    ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::"Under Development");
                    ProdBOMHeader.Modify(true);
                    ProdBOMLine.SetRange("Production BOM No.", ProdBOMHeader."No.");
                    ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
                    if ProdBOMLine.FindSet() then
                        repeat
                            ProdBOMLine.Validate("Scrap %", LibraryRandom.RandInt(10));
                            ProdBOMLine.Modify(true);
                        until ProdBOMLine.Next() = 0;
                    ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
                    ProdBOMHeader.Modify(true);
                end;
            until TempItem.Next() = 0;
    end;

    [Normal]
    procedure AddScrapForMachineCenters(var TempMachineCenter: Record "Machine Center" temporary)
    var
        MachineCenter: Record "Machine Center";
    begin
        if TempMachineCenter.FindSet() then
            repeat
                MachineCenter.Get(TempMachineCenter."No.");
                MachineCenter.Validate("Scrap %", LibraryRandom.RandInt(10));
                MachineCenter.Validate("Fixed Scrap Quantity", LibraryRandom.RandInt(10));
                MachineCenter.Modify(true);
            until TempMachineCenter.Next() = 0;
    end;

    [Normal]
    procedure AddTreeVariants(ParentItemNo: Code[20])
    var
        Item: Record Item;
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHeader: Record "Production BOM Header";
        BOMComponent: Record "BOM Component";
        ItemVariant: Record "Item Variant";
    begin
        Item.Get(ParentItemNo);
        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    BOMComponent.SetRange("Parent Item No.", Item."No.");
                    BOMComponent.SetRange(Type, BOMComponent.Type::Item);
                    if BOMComponent.FindSet() then
                        repeat
                            LibraryInventory.CreateItemVariant(ItemVariant, BOMComponent."No.");
                            BOMComponent.Validate("Variant Code", ItemVariant.Code);
                            BOMComponent.Modify();
                            AddTreeVariants(BOMComponent."No.");
                        until BOMComponent.Next() = 0;
                end;
            Item."Replenishment System"::"Prod. Order":
                begin
                    ProdBOMHeader.Get(Item."Production BOM No.");
                    ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::New);
                    ProdBOMHeader.Modify();
                    ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
                    ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
                    if ProdBOMLine.FindSet() then
                        repeat
                            LibraryInventory.CreateItemVariant(ItemVariant, ProdBOMLine."No.");
                            ProdBOMLine.Validate("Variant Code", ItemVariant.Code);
                            ProdBOMLine.Modify(true);
                            AddTreeVariants(ProdBOMLine."No.");
                        until ProdBOMLine.Next() = 0;
                    ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
                    ProdBOMHeader.Modify();
                end;
        end;
    end;

    procedure CreateMixedTree(var Item: Record Item; TopItemReplSystem: Enum "Replenishment System"; CostingMethod: Enum "Costing Method"; TreeDepth: Integer; NoOfComps: Integer; NoOfRoutingLines: Integer)
    var
        BOMComponent: Record "BOM Component";
        Item1: Record Item;
        Item2: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHeaderChild: Record "Production BOM Header";
    begin
        // Create top item and its assembly / prod BOM.
        LibraryAssembly.CreateItem(Item, CostingMethod, TopItemReplSystem, '', '');
        Item.Validate("Lot Size", LibraryRandom.RandInt(10));
        Item.Modify(true);

        if TopItemReplSystem = Item."Replenishment System"::"Prod. Order" then begin
            LibraryManufacturing.CreateProductionRouting(Item, NoOfRoutingLines);
            LibraryManufacturing.CreateProductionBOM(Item, NoOfComps);
        end else
            LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, NoOfComps, NoOfComps, NoOfComps, 1, '', '');

        // Recurrence exit condition.
        if TreeDepth = 0 then
            exit;

        // Create left branch of sub tree.
        CreateMixedTree(Item1, Item."Replenishment System"::"Prod. Order", CostingMethod, TreeDepth - 1, NoOfComps, NoOfRoutingLines);
        Item1.Find();

        // Create right branch of sub tree.
        CreateMixedTree(Item2, Item."Replenishment System"::Assembly, CostingMethod, TreeDepth - 1, NoOfComps, NoOfRoutingLines);
        Item2.Find();

        // Connect the 2 sub trees to the parent item.
        case Item."Replenishment System" of
            Item."Replenishment System"::"Prod. Order":
                begin
                    ProdBOMHeader.Get(Item."Production BOM No.");
                    ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::"Under Development");
                    ProdBOMHeader.Modify(true);
                    LibraryManufacturing.CreateProductionBOMLine(
                      ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, Item1."No.", LibraryRandom.RandInt(5));
                    LibraryManufacturing.CreateProductionBOMLine(
                      ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, Item2."No.", LibraryRandom.RandInt(5));

                    LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
                      ProdBOMHeaderChild, LibraryInventory.CreateItemNo(), LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(5));
                    LibraryManufacturing.CreateProductionBOMLine(
                      ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::"Production BOM", ProdBOMHeaderChild."No.", LibraryRandom.RandInt(5));

                    ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
                    ProdBOMHeader.Modify(true);
                end;
            Item."Replenishment System"::Assembly:
                begin
                    LibraryAssembly.CreateAssemblyListComponent(
                      BOMComponent.Type::Item, Item1."No.", Item."No.", '', BOMComponent."Resource Usage Type"::Direct,
                      LibraryRandom.RandInt(5), true);
                    LibraryAssembly.CreateAssemblyListComponent(
                      BOMComponent.Type::Item, Item2."No.", Item."No.", '', BOMComponent."Resource Usage Type"::Direct,
                      LibraryRandom.RandInt(5), true);
                end;
        end;
    end;

    [Normal]
    procedure CreateNodeSupply(ParentItemNo: Code[20]; LocationCode: Code[10]; DueDate: Date; SourceType: Option; Qty: Decimal; BottleneckFactor: Decimal; DirectAvailFactor: Decimal)
    var
        InventorySetup: Record "Inventory Setup";
        BOMComponent: Record "BOM Component";
        DirectAvailability: Decimal;
    begin
        InventorySetup.Get();
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);

        if BOMComponent.FindSet() then
            repeat
                BOMComponent.CalcFields("Assembly BOM");
                if BOMComponent."Assembly BOM" then begin
                    DirectAvailability := Qty * BottleneckFactor * DirectAvailFactor;
                    CreateNodeSupply(
                      BOMComponent."No.", LocationCode, CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time") + '>', DueDate), SourceType,
                      (Qty * BottleneckFactor - DirectAvailability) * BOMComponent."Quantity per", 1, DirectAvailFactor);

                    if DirectAvailability > 0 then begin
                        CreateSupply(
                          BOMComponent."No.", BOMComponent."Variant Code", LocationCode,
                          CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time") + '>', DueDate), SourceType,
                          DirectAvailability * BOMComponent."Quantity per");
                        // Create un-available supply: by variant, location.
                        CreateSupply(
                          BOMComponent."No.", '', LocationCode, CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time") + '>', DueDate),
                          SourceType, (DirectAvailability + 1) * BOMComponent."Quantity per");
                        CreateSupply(
                          BOMComponent."No.", BOMComponent."Variant Code", '',
                          CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time") + '>', DueDate), SourceType,
                          (DirectAvailability + 1) * BOMComponent."Quantity per");
                    end;
                end else begin
                    CreateSupply(
                      BOMComponent."No.", BOMComponent."Variant Code", LocationCode,
                      CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time") + '>', DueDate), SourceType, Qty * BOMComponent."Quantity per");
                    // Create  un-available supply: by variant, location.
                    CreateSupply(
                      BOMComponent."No.", '', LocationCode, CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time") + '>', DueDate),
                      SourceType, (Qty + 1) * BOMComponent."Quantity per");
                    CreateSupply(
                      BOMComponent."No.", BOMComponent."Variant Code", '',
                      CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time") + '>', DueDate), SourceType,
                      (Qty + 1) * BOMComponent."Quantity per");
                end;

            until BOMComponent.Next() = 0;
    end;

    [Normal]
    procedure CreateSupply(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; DueDate: Date; ItemSupplyType: Option; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case ItemSupplyType of
            SupplyType::Inventory:
                begin
                    LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
                    LibraryInventory.SelectItemJournalBatchName(
                      ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
                    LibraryInventory.CreateItemJournalLine(
                      ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
                      ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);

                    ItemJournalLine.Validate("Location Code", LocationCode);
                    ItemJournalLine.Validate("Variant Code", VariantCode);
                    ItemJournalLine.Validate("Posting Date", DueDate);
                    ItemJournalLine.Modify(true);

                    LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
                end;
            SupplyType::Purchase:
                begin
                    LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
                    LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
                    PurchaseLine.Validate("Location Code", LocationCode);
                    PurchaseLine.Validate("Variant Code", VariantCode);
                    PurchaseLine.Validate("Expected Receipt Date", DueDate);
                    PurchaseLine.Modify(true);
                end;
            SupplyType::"Prod. Order":
                begin
                    LibraryManufacturing.CreateProductionOrder(
                      ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Qty);
                    ProductionOrder.Validate("Due Date", DueDate);
                    ProductionOrder.Validate("Location Code", LocationCode);
                    ProductionOrder.Modify(true);

                    LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, false, false);
                    ProdOrderLine.SetRange(Status, ProductionOrder.Status);
                    ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
                    if ProdOrderLine.FindFirst() then begin
                        ProdOrderLine.Validate("Variant Code", VariantCode);
                        ProdOrderLine.Modify(true);
                    end;
                end;
        end;
    end;

    [Normal]
    procedure GetTreeCost(var RolledUpMaterialCost: Decimal; var RolledUpCapacityCost: Decimal; var RolledUpCapOvhd: Decimal; var RolledUpMfgOvhd: Decimal; var SglLevelMaterialCost: Decimal; var SglLevelCapCost: Decimal; var SglLevelCapOvhd: Decimal; var SglLevelMfgOvhd: Decimal; Item: Record Item): Decimal
    var
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        BOMComponent: Record "BOM Component";
        ProdBOMLine: Record "Production BOM Line";
        Item1: Record Item;
        Resource: Record Resource;
        LotSize: Decimal;
        ResLotSize: Decimal;
        Overhead: Decimal;
        IndirectCost: Decimal;
        TreeCost: Decimal;
        UnitCost: Decimal;
        LocalRolledUpMaterialCost: Decimal;
        LocalRolledUpCapCost: Decimal;
        LocalRolledUpCapOvhd: Decimal;
        LocalRolledUpMfgOvhd: Decimal;
        LocalCost: Decimal;
        RoundingPrecision: Decimal;
    begin
        if Item."Lot Size" = 0 then
            LotSize := 1
        else
            LotSize := Item."Lot Size";

        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    BOMComponent.SetRange("Parent Item No.", Item."No.");
                    BOMComponent.SetRange(Type, BOMComponent.Type::Item);
                    if BOMComponent.FindSet() then
                        repeat
                            Item1.Get(BOMComponent."No.");
                            LocalRolledUpMaterialCost := 0;
                            LocalRolledUpCapCost := 0;
                            LocalRolledUpCapOvhd := 0;
                            LocalRolledUpMfgOvhd := 0;
                            LocalCost := 0;
                            TreeCost +=
                              BOMComponent."Quantity per" *
                              GetTreeCost(
                                LocalRolledUpMaterialCost, LocalRolledUpCapCost, LocalRolledUpCapOvhd, LocalRolledUpMfgOvhd, LocalCost, LocalCost,
                                LocalCost, LocalCost, Item1);
                            SglLevelMaterialCost += BOMComponent."Quantity per" * Item1."Unit Cost";
                            RolledUpMaterialCost += BOMComponent."Quantity per" * LocalRolledUpMaterialCost;
                            RolledUpCapacityCost += BOMComponent."Quantity per" * LocalRolledUpCapCost;
                            RolledUpCapOvhd += BOMComponent."Quantity per" * LocalRolledUpCapOvhd;
                            RolledUpMfgOvhd += BOMComponent."Quantity per" * LocalRolledUpMfgOvhd;
                        until BOMComponent.Next() = 0;

                    BOMComponent.SetRange(Type, BOMComponent.Type::Resource);
                    if BOMComponent.FindSet() then
                        repeat
                            Resource.Get(BOMComponent."No.");

                            if (BOMComponent."Resource Usage Type" = BOMComponent."Resource Usage Type"::Fixed) and (Item."Lot Size" <> 0) then
                                ResLotSize := Item."Lot Size"
                            else
                                ResLotSize := 1;

                            LibraryAssembly.GetCostInformation(
                              UnitCost, Overhead, IndirectCost, BOMComponent.Type::Resource, BOMComponent."No.", '', '');
                            TreeCost += BOMComponent."Quantity per" * UnitCost / ResLotSize;
                            SglLevelCapCost += BOMComponent."Quantity per" * (UnitCost - Overhead) / ResLotSize;
                            SglLevelCapOvhd += BOMComponent."Quantity per" * Overhead / ResLotSize;
                            RolledUpCapacityCost += BOMComponent."Quantity per" * (UnitCost - Overhead) / ResLotSize;
                            RolledUpCapOvhd += BOMComponent."Quantity per" * Overhead / ResLotSize;
                        until BOMComponent.Next() = 0;

                    RolledUpMfgOvhd +=
                      (RolledUpMaterialCost + RolledUpCapacityCost + RolledUpCapOvhd + RolledUpMfgOvhd) *
                      Item."Indirect Cost %" / 100 + Item."Overhead Rate";
                    SglLevelMfgOvhd += Item."Single-Level Mfg. Ovhd Cost";
                    RolledUpCapacityCost -= Item."Single-Level Subcontrd. Cost";
                end;
            Item."Replenishment System"::"Prod. Order":
                begin
                    ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
                    ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
                    if ProdBOMLine.FindSet() then
                        repeat
                            Item1.Get(ProdBOMLine."No.");
                            LocalRolledUpMaterialCost := 0;
                            LocalRolledUpCapCost := 0;
                            LocalRolledUpCapOvhd := 0;
                            LocalRolledUpMfgOvhd := 0;
                            LocalCost := 0;
                            TreeCost +=
                              ProdBOMLine."Quantity per" *
                              GetTreeCost(
                                LocalRolledUpMaterialCost, LocalRolledUpCapCost, LocalRolledUpCapOvhd, LocalRolledUpMfgOvhd, LocalCost, LocalCost,
                                LocalCost, LocalCost, Item1);
                            SglLevelMaterialCost += ProdBOMLine."Quantity per" * Item1."Unit Cost";
                            RolledUpMaterialCost += ProdBOMLine."Quantity per" * LocalRolledUpMaterialCost;
                            RolledUpCapacityCost += ProdBOMLine."Quantity per" * LocalRolledUpCapCost;
                            RolledUpCapOvhd += ProdBOMLine."Quantity per" * LocalRolledUpCapOvhd;
                            RolledUpMfgOvhd += ProdBOMLine."Quantity per" * LocalRolledUpMfgOvhd;
                        until ProdBOMLine.Next() = 0;

                    RoutingLine.SetRange("Routing No.", Item."Routing No.");
                    RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
                    if RoutingLine.FindSet() then
                        repeat
                            WorkCenter.Get(RoutingLine."No.");
                            RolledUpCapacityCost += (RoutingLine."Run Time" + RoutingLine."Setup Time" / LotSize) * WorkCenter."Direct Unit Cost";
                            RolledUpCapOvhd +=
                              (RoutingLine."Run Time" + RoutingLine."Setup Time" / LotSize) *
                              (WorkCenter."Unit Cost" - WorkCenter."Direct Unit Cost");
                            SglLevelCapCost += (RoutingLine."Run Time" + RoutingLine."Setup Time" / LotSize) * WorkCenter."Direct Unit Cost";
                            SglLevelCapOvhd +=
                              (RoutingLine."Run Time" + RoutingLine."Setup Time" / LotSize) *
                              (WorkCenter."Unit Cost" - WorkCenter."Direct Unit Cost");
                        until RoutingLine.Next() = 0;

                    RoutingLine.SetRange(Type, RoutingLine.Type::"Machine Center");
                    if RoutingLine.FindSet() then
                        repeat
                            MachineCenter.Get(RoutingLine."No.");
                            RolledUpCapacityCost +=
                              (RoutingLine."Run Time" + RoutingLine."Setup Time" / LotSize) * MachineCenter."Direct Unit Cost";
                            RolledUpCapOvhd +=
                              (RoutingLine."Run Time" + RoutingLine."Setup Time" / LotSize) *
                              (MachineCenter."Unit Cost" - MachineCenter."Direct Unit Cost");
                            SglLevelCapCost += (RoutingLine."Run Time" + RoutingLine."Setup Time" / LotSize) * MachineCenter."Direct Unit Cost";
                            SglLevelCapOvhd +=
                              (RoutingLine."Run Time" + RoutingLine."Setup Time" / LotSize) *
                              (MachineCenter."Unit Cost" - MachineCenter."Direct Unit Cost");
                        until RoutingLine.Next() = 0;

                    RolledUpMfgOvhd +=
                      (RolledUpMaterialCost + RolledUpCapacityCost + RolledUpCapOvhd + RolledUpMfgOvhd) *
                      Item."Indirect Cost %" / 100 + Item."Overhead Rate";
                    SglLevelMfgOvhd += Item."Single-Level Mfg. Ovhd Cost";
                    RolledUpCapacityCost -= Item."Single-Level Subcontrd. Cost";
                end;
            Item."Replenishment System"::Purchase:
                begin
                    LibraryAssembly.GetCostInformation(UnitCost, Overhead, IndirectCost, BOMComponent.Type::Item, Item."No.", '', '');
                    SglLevelMaterialCost := UnitCost;
                    RolledUpMaterialCost := UnitCost;
                    exit(UnitCost);
                end;
        end;

        RoundingPrecision := LibraryERM.GetUnitAmountRoundingPrecision();
        RolledUpMaterialCost := Round(RolledUpMaterialCost, RoundingPrecision);
        RolledUpCapacityCost := Round(RolledUpCapacityCost, RoundingPrecision);
        RolledUpCapOvhd := Round(RolledUpCapOvhd, RoundingPrecision);
        RolledUpMfgOvhd := Round(RolledUpMfgOvhd, RoundingPrecision);
        SglLevelMaterialCost := Round(SglLevelMaterialCost, RoundingPrecision);
        SglLevelCapCost := Round(SglLevelCapCost, RoundingPrecision);
        SglLevelCapOvhd := Round(SglLevelCapOvhd, RoundingPrecision);
        SglLevelMfgOvhd := Round(SglLevelMfgOvhd, RoundingPrecision);

        exit(Round(TreeCost * (1 + Item."Indirect Cost %" / 100) + Item."Overhead Rate", RoundingPrecision));
    end;

    [Normal]
    procedure GetTree(var TempItem: Record Item temporary; var TempResource: Record Resource temporary; var TempWorkCenter: Record "Work Center" temporary; var TempMachineCenter: Record "Machine Center" temporary; Item: Record Item)
    var
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        BOMComponent: Record "BOM Component";
        ProdBOMLine: Record "Production BOM Line";
        Item1: Record Item;
        Resource: Record Resource;
    begin
        TempItem := Item;
        TempItem.Insert();

        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    BOMComponent.SetRange("Parent Item No.", Item."No.");
                    BOMComponent.SetRange(Type, BOMComponent.Type::Item);
                    if BOMComponent.FindSet() then
                        repeat
                            Item1.Get(BOMComponent."No.");
                            GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item1);
                        until BOMComponent.Next() = 0;

                    BOMComponent.SetRange(Type, BOMComponent.Type::Resource);
                    if BOMComponent.FindSet() then
                        repeat
                            Resource.Get(BOMComponent."No.");
                            TempResource := Resource;
                            TempResource.Insert();
                        until BOMComponent.Next() = 0;
                end;
            Item."Replenishment System"::"Prod. Order":
                begin
                    ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
                    ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
                    if ProdBOMLine.FindSet() then
                        repeat
                            Item1.Get(ProdBOMLine."No.");
                            GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item1);
                        until ProdBOMLine.Next() = 0;

                    RoutingLine.SetRange("Routing No.", Item."Routing No.");
                    RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
                    if RoutingLine.FindSet() then
                        repeat
                            WorkCenter.Get(RoutingLine."No.");
                            TempWorkCenter := WorkCenter;
                            TempWorkCenter.Insert();
                        until RoutingLine.Next() = 0;

                    RoutingLine.SetRange(Type, RoutingLine.Type::"Machine Center");
                    if RoutingLine.FindSet() then
                        repeat
                            MachineCenter.Get(RoutingLine."No.");
                            TempMachineCenter := MachineCenter;
                            TempMachineCenter.Insert();
                        until RoutingLine.Next() = 0;
                end;
        end;
    end;

    [Normal]
    procedure GetTreeCostWithScrap(var RolledUpScrapAmount: Decimal; var SingleLevelScrapAmount: Decimal; Item: Record Item)
    var
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        BOMComponent: Record "BOM Component";
        ProdBOMLine: Record "Production BOM Line";
        Item1: Record Item;
        Resource: Record Resource;
        LotSize: Decimal;
        Overhead: Decimal;
        IndirectCost: Decimal;
        UnitCost: Decimal;
        LocalRolledUpScrapAmount: Decimal;
        RoutingScrapPercentage: Decimal;
        ProcessedScrapPercentage: Decimal;
        LocalCost: Decimal;
    begin
        LocalCost := 0;
        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    BOMComponent.SetRange("Parent Item No.", Item."No.");
                    BOMComponent.SetRange(Type, BOMComponent.Type::Item);
                    if BOMComponent.FindSet() then
                        repeat
                            Item1.Get(BOMComponent."No.");
                            LocalRolledUpScrapAmount := 0;
                            GetTreeCostWithScrap(LocalRolledUpScrapAmount, LocalCost, Item1);
                            RolledUpScrapAmount += BOMComponent."Quantity per" * LocalRolledUpScrapAmount;
                        until BOMComponent.Next() = 0;

                    BOMComponent.SetRange(Type, BOMComponent.Type::Resource);
                    if BOMComponent.FindSet() then
                        repeat
                            Resource.Get(BOMComponent."No.");

                            if (BOMComponent."Resource Usage Type" = BOMComponent."Resource Usage Type"::Fixed) and (Item."Lot Size" <> 0) then
                                LotSize := Item."Lot Size"
                            else
                                LotSize := 1;

                            LibraryAssembly.GetCostInformation(
                              UnitCost, Overhead, IndirectCost, BOMComponent.Type::Resource, BOMComponent."No.", '', '');
                            RolledUpScrapAmount += BOMComponent."Quantity per" * UnitCost / LotSize;
                        until BOMComponent.Next() = 0;
                end;
            Item."Replenishment System"::"Prod. Order":
                begin
                    RoutingLine.SetRange("Routing No.", Item."Routing No.");
                    RoutingScrapPercentage := GetCombinedScrapPercentage(RoutingLine);

                    ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
                    ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
                    if ProdBOMLine.FindSet() then
                        repeat
                            Item1.Get(ProdBOMLine."No.");
                            LocalRolledUpScrapAmount := 0;
                            GetTreeCostWithScrap(LocalRolledUpScrapAmount, LocalCost, Item1);
                            RolledUpScrapAmount +=
                                ProdBOMLine."Quantity per" * LocalRolledUpScrapAmount *
                                (1 + CombineMultilevelScrapFactors(RoutingScrapPercentage, CombineMultilevelScrapFactors(ProdBOMLine."Scrap %", Item."Scrap %")) / 100);

                            if Item1."Replenishment System" = Item1."Replenishment System"::Purchase then
                                SingleLevelScrapAmount +=
                                    ProdBOMLine."Quantity per" * Item1."Unit Cost" *
                                    CombineMultilevelScrapFactors(RoutingScrapPercentage, CombineMultilevelScrapFactors(ProdBOMLine."Scrap %", Item."Scrap %")) / 100;
                        until ProdBOMLine.Next() = 0;

                    ProcessedScrapPercentage := 1;
                    if RoutingLine.FindSet() then
                        repeat
                            if RoutingLine.Type = RoutingLine.Type::"Work Center" then begin
                                WorkCenter.Get(RoutingLine."No.");
                                RolledUpScrapAmount +=
                                  (RoutingLine."Run Time" *
                                   (1 + RoutingScrapPercentage / 100) / ProcessedScrapPercentage + RoutingLine."Setup Time" / Item."Lot Size") *
                                  WorkCenter."Unit Cost" * (1 + Item."Scrap %" / 100);
                            end else begin
                                MachineCenter.Get(RoutingLine."No.");
                                RolledUpScrapAmount +=
                                  (RoutingLine."Run Time" *
                                   (1 + RoutingScrapPercentage / 100) / ProcessedScrapPercentage + RoutingLine."Setup Time" / Item."Lot Size") *
                                  MachineCenter."Unit Cost" * (1 + Item."Scrap %" / 100);
                            end;
                            ProcessedScrapPercentage *= 1 + RoutingLine."Scrap Factor %" / 100;
                        until RoutingLine.Next() = 0;
                end;
            Item."Replenishment System"::Purchase:
                RolledUpScrapAmount := Item."Unit Cost";
        end;

        RolledUpScrapAmount := Round(RolledUpScrapAmount, LibraryERM.GetUnitAmountRoundingPrecision());
    end;

    local procedure CombineMultilevelScrapFactors(LowLevelScrapPct: Decimal; HighLevelScrapPct: Decimal): Decimal
    begin
        exit(LowLevelScrapPct + HighLevelScrapPct + LowLevelScrapPct * HighLevelScrapPct / 100);
    end;

    local procedure GetCombinedScrapPercentage(var RoutingLine: Record "Routing Line"): Decimal
    var
        ScrapPercentage: Decimal;
    begin
        ScrapPercentage := 0;
        if RoutingLine.FindSet() then
            repeat
                ScrapPercentage := CombineMultilevelScrapFactors(RoutingLine."Scrap Factor %", ScrapPercentage);
            until RoutingLine.Next() = 0;

        exit(ScrapPercentage);
    end;

    procedure GetQtyPerInTree(var QtyPerParent: Decimal; var QtyPerTopItem: Decimal; ParentItemNo: Code[20]; CompItemNo: Code[20])
    var
        Stop: Boolean;
        Type: Enum "Production BOM Line Type";
    begin
        Stop := false;
        QtyPerParent := 1;
        QtyPerTopItem := 1;
        GetQtyPerInSubTree(QtyPerParent, QtyPerTopItem, Type::Item, ParentItemNo, CompItemNo, Stop);
    end;

    local procedure GetQtyPerInSubTree(var QtyPerParent: Decimal; var QtyPerTopItem: Decimal; Type: Enum "Production BOM Line Type"; No: Code[20]; LeafItemNo: Code[20]; var Stop: Boolean)
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        ProdBOMLine: Record "Production BOM Line";
        BOMNo: Code[20];
        RecQtyPerTopItem: Decimal;
    begin
        if Stop then
            exit;

        if Type = Type::Item then begin
            Item.Get(No);
            BOMNo := Item."Production BOM No.";
        end else
            if Type = Type::"Production BOM" then
                BOMNo := No;

        if (Item."No." <> '') and (Item."Replenishment System" = Item."Replenishment System"::Assembly) then begin
            BOMComponent.SetRange("Parent Item No.", No);
            BOMComponent.SetRange(Type, BOMComponent.Type::Item);
            if BOMComponent.FindSet() then
                repeat
                    if BOMComponent."No." = LeafItemNo then begin
                        QtyPerParent := BOMComponent."Quantity per";
                        QtyPerTopItem *= BOMComponent."Quantity per";
                        Stop := true;
                        exit;
                    end;

                    RecQtyPerTopItem := BOMComponent."Quantity per" * QtyPerTopItem;
                    GetQtyPerInSubTree(QtyPerParent, QtyPerTopItem, Type::Item, BOMComponent."No.", LeafItemNo, Stop);
                until (BOMComponent.Next() = 0) or Stop;
        end;

        if (Item."No." <> '') and (Item."Replenishment System" = Item."Replenishment System"::Purchase) then
            if Item."No." = LeafItemNo then begin
                Stop := true;
                exit;
            end;

        if (Type = Type::"Production BOM") or
           (Item."No." <> '') and (Item."Replenishment System" = Item."Replenishment System"::"Prod. Order")
        then begin
            ProdBOMLine.SetRange("Production BOM No.", BOMNo);
            if ProdBOMLine.FindSet() then
                repeat
                    if ProdBOMLine.Type = ProdBOMLine.Type::"Production BOM" then
                        QtyPerParent := ProdBOMLine."Quantity per"
                    else
                        if Type = Type::Item then
                            QtyPerParent := 1;

                    if (ProdBOMLine.Type = ProdBOMLine.Type::Item) and (ProdBOMLine."No." = LeafItemNo) then begin
                        QtyPerParent *= ProdBOMLine."Quantity per";
                        QtyPerTopItem *= ProdBOMLine."Quantity per";
                        Stop := true;
                        exit;
                    end;

                    RecQtyPerTopItem := ProdBOMLine."Quantity per" * QtyPerTopItem;
                    GetQtyPerInSubTree(QtyPerParent, RecQtyPerTopItem, ProdBOMLine.Type, ProdBOMLine."No.", LeafItemNo, Stop);
                until (ProdBOMLine.Next() = 0) or Stop;
        end;
    end;
}

