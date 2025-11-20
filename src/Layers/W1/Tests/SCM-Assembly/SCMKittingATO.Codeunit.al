// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using Microsoft.Sales.Setup;
using Microsoft.Assembly.Setup;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Setup;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.BOM;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Assembly.Document;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Costing;
using Microsoft.Foundation.UOM;
using Microsoft.Assembly.History;
using Microsoft.Sales.History;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Inventory.Ledger;
using Microsoft.Warehouse.Activity;
using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Pricing;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Warehouse.Ledger;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Archive;
using Microsoft.Utilities;

codeunit 137096 "SCM Kitting - ATO"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Assemble-to-Order] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        GLSetup: Record "General Ledger Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        GenProdPostingGr: Code[20];
        AsmInvtPostingGr: Code[20];
        CompInvtPostingGr: Code[20];
        isInitialized: Boolean;
        ERR_POST_AOT: Label 'Assemble to Order must be equal to ''No''';
        MSG_UPDATE: Label 'Do you want to update the ';
        ERR_NOT_ENOUGH: Label 'on inventory.';
        DocTypeNotSupportedErr: Label 'Sales document type not supported in ATO relation.';
        WorkDate2: Date;
        CONFIRM_ROLLUP_COST: Label 'Do you want to roll up the cost from the assembly components?';
        ERR_SKU_NOT_CREATED: Label 'SKU not created.';
        WrongWhseQtyErr: Label 'Wrong total quantity in warehouse entries for document %1.';
        ItemMsg: Label 'Item';
        WrongTakeBinErr: Label 'Item is taken from wrong Bin.';
        AssemblyOrderCountErr: Label 'Additional Assembly Orders must not be created';
        ReservationConflictErr: Label 'The change leads to a date conflict with existing reservations';
        TestValidationErrorTok: Label 'TestValidation';
        WrongValueOnAsmOrderLineMsg: Label 'Wrong %1 on Assembly Order Line %2.', Comment = '%1: FieldCaption, %2:GetFilters';
        NoAssemblyInFilterMsg: Label 'There are no %1 %2 within the filter %3. ', Comment = '%1: NoOfLines, %2: TableCaption, %2: GetFilters';
        DiffEntryNoInReservEntriesMsg: Label 'Reservation Entries created for AO and SOL do not have same Entry No.';
        WrongDateOnAssemblyMsg: Label 'Wrong %1 in %2 %3.', Comment = '%1: Field(Date), %2: TableCaption, %3: Field(DocumentNo)';
        OneAsmOrderCreateMsg: Label 'One Assembly Order should be created.';
        TwoAsmOrdersCreateMsg: Label 'Two Assembly Orders should be created.';
        NoAsmOrderCreateMsg: Label 'No new Assembly should be created.';
        NoReservEntryCreateMsg: Label 'No new reservation entries should be created.';
        NoHardLinkCreateMsg: Label 'No new hard link entries should be created.';
        OneAsmOrderDeleteMsg: Label 'One Assembly Order should be deleted.';
        NoQtyPostedMsg: Label 'No Quantity should have been posted from the ATO order.';
        AsmOrderReUsedMsg: Label 'Assembly Orders for first ATO item should have been reused for second ATO item.';
        OneAsmOrderPostedMsg: Label 'One Assembly Order should be posted.';
        BothAsmOrdersPostedMsg: Label 'Both Assembly Orders should be posted.';
        WrongUnitValueMsg: Label 'Wrong %1.', Comment = '%1: Field(Unit Cost) or Field(Unit Price)';
        LowerQtysPropagatedMsg: Label 'Lower quantities are propagated to the lines.';
        GreaterQtysPropagatedMsg: Label 'Greater quantities are propagated to the lines.';
        NumberAsmOrderFromSalesHeaderMsg: Label 'Number of assembly orders when getting assembly orders from a sales header.';
        DifferentNumberAsmLinesInOrderAndQuoteErr: Label 'Number of assembly lines in Sales Order and Sales Quote are different.';
        ItemTrackingAction: Option AssignSerialNo,,SelectEntries;
        AssertOption: Option Orders,Reservation,"Hard link";
        ChangeOption: Option Quantity,"Quantity to Assemble","Location Code","Variant Code",UOM,"Due Date";
        DeleteOption: Option "Zero Quantity on SOL","Delete SOL","Delete SO";
        FieldMustBeEmptyErr: Label '%1 must be empty', Comment = '%1 - Field Caption';
        ATOLinkShouldNotBeFoundErr: Label 'Assemble-to-Order Link should not be found.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - ATO");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - ATO");

        GLSetup.Get();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        GlobalSetup();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");

        isInitialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - ATO");
    end;

    local procedure GlobalSetup()
    begin
        SetupAssembly();
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        SetupInventorySetup();
        SetupSalesAndReceivablesSetup();
        SetupLocation(LocationBlue, false);
        LibraryAssembly.SetupPostingToGL(GenProdPostingGr, AsmInvtPostingGr, CompInvtPostingGr, '');
    end;

    local procedure SetupAssembly()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        UpdateAssemblySetup('');

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Customer Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure UpdateAssemblySetup(DefaultLocationCode: Code[10])
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Posted Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Assembly Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Blanket Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Default Location for Orders", DefaultLocationCode);
        AssemblySetup.Validate("Stockout Warning", true);
        AssemblySetup.Modify(true);
    end;

    local procedure SetupBinLocationInAssemblySetup(): Code[10]
    var
        Location: Record Location;
    begin
        SetupLocation(Location, false);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        UpdateAssemblySetup(Location.Code);
        exit(Location.Code);
    end;

    local procedure SetupLocation(var Location: Record Location; UseAsInTransit: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        if UseAsInTransit then begin
            Location.Validate("Use As In-Transit", true);
            Location.Modify(true);
            exit;
        end;
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateItemWithCategoryAndWarehouseClass(var Item: Record Item)
    var
        WarehouseClass: Record "Warehouse Class";
        ItemCategory: Record "Item Category";
    begin
        LibraryInventory.CreateItemCategory(ItemCategory);
        LibraryWarehouse.CreateWarehouseClass(WarehouseClass);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Validate("Warehouse Class Code", WarehouseClass.Code);
        Item.Modify();
    end;

    local procedure SetupSNTrackingAndDefaultBinContent(LocationCode: Code[10]; Item: Record Item)
    var
        TempItem: Record Item temporary;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        TempItem := Item;
        TempItem.Insert();
        CollectSetupBOMComponent(TempItem, Item."No.");

        LibraryWarehouse.CreateBin(Bin, LocationCode, '', '', '');
        TempItem.FindSet();
        repeat
            LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', Bin.Code, TempItem."No.", '', TempItem."Base Unit of Measure");
            BinContent.Validate(Default, true);
            BinContent.Modify(true);
        until TempItem.Next() = 0;
    end;

    local procedure UpdateAutomaticCostPosting(var OldAutomaticCostPosting: Boolean; NewAutomaticCostPosting: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldAutomaticCostPosting := InventorySetup."Automatic Cost Posting";
        InventorySetup.Validate("Automatic Cost Posting", NewAutomaticCostPosting);
        InventorySetup.Modify(true);
    end;

    local procedure ClearJournal(ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure SetupInventorySetup()
    begin
        LibraryPlanning.SetDefaultSafetyLeadTime('<1D>');
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate(); // to avoid Due Date Before Work Date message.
    end;

    local procedure SetupSalesAndReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateAssemblyList(ParentItem: Record Item; CompCostingMethod: Enum "Costing Method"; NoOfComponents: Integer; NoOfResources: Integer; NoOfTexts: Integer; QtyPer: Integer)
    var
        Item: Record Item;
        Resource: Record Resource;
        BOMComponent: Record "BOM Component";
        VATPostingSetup: Record "VAT Posting Setup";
        CompCount: Integer;
    begin
        // Add components - qty per is increasing same as no of components
        for CompCount := 1 to NoOfComponents do begin
            Clear(Item);
            LibraryInventory.CreateItem(Item);
            Item.Validate("Costing Method", CompCostingMethod);
            Item.Modify();
            AddComponentToAssemblyList(
              BOMComponent, BOMComponent.Type::Item, Item."No.", ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, Item."Base Unit of Measure", QtyPer);
        end;

        // Add resources - qty per is increasing same as no of components
        for CompCount := 1 to NoOfResources do begin
            LibraryAssembly.CreateResource(Resource, true, GenProdPostingGr);
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            Resource.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            Resource.Modify();
            AddComponentToAssemblyList(
              BOMComponent, BOMComponent.Type::Resource, Resource."No.", ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, Resource."Base Unit of Measure", QtyPer);
        end;

        // Add simple text
        for CompCount := 1 to NoOfTexts do
            AddComponentToAssemblyList(BOMComponent, BOMComponent.Type::" ", '', ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, '', QtyPer);
    end;

    local procedure AddItemUOM(var Item: Record Item; QtyPerUOM: Integer; UOMCode: Code[10])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UOMCode, QtyPerUOM);
    end;

    local procedure AddComponentToAssemblyList(var BOMComponent: Record "BOM Component"; ComponentType: Enum "BOM Component Type"; ComponentNo: Code[20]; ParentItemNo: Code[20]; VariantCode: Code[10]; ResourceUsage: Option; UOM: Code[10]; QuantityPer: Decimal)
    begin
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItemNo, ComponentType, ComponentNo, QuantityPer, UOM);
        if ComponentType = BOMComponent.Type::Resource then
            BOMComponent.Validate("Resource Usage Type", ResourceUsage);
        BOMComponent.Validate("Variant Code", VariantCode);
        BOMComponent.Validate("Quantity per", QuantityPer);
        BOMComponent.Validate("Unit of Measure Code", UOM);
        if ComponentNo = '' then
            BOMComponent.Validate(Description,
              LibraryUtility.GenerateRandomCode(BOMComponent.FieldNo(Description), DATABASE::"BOM Component"));
        BOMComponent.Modify(true);
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ParentItem: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; DueDate: Date; Quantity: Decimal)
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ParentItem."No.", LocationCode, Quantity, VariantCode);
    end;

    local procedure CreateAssembledItem(var Item: Record Item; AssemblyPolicy: Enum "Assembly Policy"; NoOfComponents: Integer; NoOfResources: Integer; NoOfTexts: Integer; QtyPer: Integer; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Assembly Policy", AssemblyPolicy);
        Item.Modify(true);
        CreateAssemblyList(Item, CostingMethod, NoOfComponents, NoOfResources, NoOfTexts, QtyPer);
    end;

    local procedure CreateATOItemWithSNTracking(var AssembledItem: Record Item)
    begin
        CreateAssembledItem(
          AssembledItem, "Assembly Policy"::"Assemble-to-Order", 2, 0, 0, 1, AssembledItem."Costing Method"::FIFO);
        AssembledItem.Validate("Item Tracking Code", FindItemTrackingLikeSNALL());
        AssembledItem.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssembledItem.Modify(true);
    end;

    local procedure CreateAssembledItemWithAssemblyPolicy(var AssembledItem: Record Item; AssemblyPolicy: Enum "Assembly Policy")
    begin
        LibraryAssembly.SetupAssemblyItem(
          AssembledItem, AssembledItem."Costing Method"::Standard, AssembledItem."Costing Method"::Standard,
          AssembledItem."Replenishment System"::Assembly, '', false, LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        AssembledItem.Validate("Assembly Policy", AssemblyPolicy);
        AssembledItem.Modify(true);
    end;

    local procedure AddSalesOrderLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; SalesQty: Integer; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate, SalesQty);
        if LocationCode <> '' then
            SalesLine.Validate("Location Code", LocationCode);
        if VariantCode <> '' then
            SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CopyAsmLinesToTemp(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        TempAssemblyLine.DeleteAll(true);
        Clear(AssemblyLine);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        if not AssemblyLine.FindSet() then
            exit;

        repeat
            TempAssemblyLine := AssemblyLine;
            TempAssemblyLine.Insert(true);
        until AssemblyLine.Next() = 0;
    end;

    local procedure SetupInventoryAndTrackingForAssemblyOrder(AssemblyItem: Record Item; LocationCode: Code[10]; OrderQty: Decimal): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        FindAssemblyHeader(
          AssemblyHeader, AssemblyHeader."Document Type"::Order, AssemblyItem, '', LocationCode,
          WorkDate(), AssemblyItem."Base Unit of Measure", OrderQty);

        PostCompInventory(AssemblyHeader, true);
        AssignSNItemTracking(AssemblyHeader, OrderQty);
        exit(AssemblyHeader."No.");
    end;

    local procedure PostCompInventory(AssemblyHeader: Record "Assembly Header"; AssignItemTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        AssemblyLine: Record "Assembly Line";
        QtySupplement: Decimal;
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindSet();
        QtySupplement := LibraryRandom.RandInt(50);
        repeat
            LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
            LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Positive Adjmt.", AssemblyLine."No.", AssemblyLine.Quantity + QtySupplement);
            ItemJournalLine.Validate("Unit of Measure Code", AssemblyLine."Unit of Measure Code");
            ItemJournalLine.Validate("Variant Code", AssemblyLine."Variant Code");
            ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(50, 2));
            ItemJournalLine.Validate("Location Code", AssemblyLine."Location Code");
            ItemJournalLine.Validate("Bin Code", AssemblyLine."Bin Code");
            ItemJournalLine.Modify(true);

            if AssignItemTracking then begin
                LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
                LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)");
                ItemJournalLine.OpenItemTrackingLines(false);
            end;

            LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
        until AssemblyLine.Next() = 0;
    end;

    local procedure CreateSaleLineWithShptDate(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; VariantCode: Code[10]; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate, SalesQty);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; VariantCode: Code[10]; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10])
    begin
        CreateSaleLineWithShptDate(SalesHeader, SalesHeader."Document Type"::Order, ItemNo, VariantCode, SalesQty, ShipmentDate, LocationCode);
    end;

    local procedure CreateSalesOrderWithTwoLines(var SalesHeader: Record "Sales Header"; AssemblyItemNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; SalesQty: Integer; ShipmentDate: Date; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSaleLineWithShptDate(
          SalesHeader, SalesHeader."Document Type"::Order, AssemblyItemNo, VariantCode, SalesQty, ShipmentDate, LocationCode);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, SalesQty);
    end;

    local procedure AssignSNItemTracking(var AssemblyHeader: Record "Assembly Header"; OrderQty: Decimal)
    var
        AssemblyOrderPage: TestPage "Assembly Order";
    begin
        Commit();
        AssemblyOrderPage.OpenEdit();
        AssemblyOrderPage.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrderPage.GotoRecord(AssemblyHeader);

        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        LibraryVariableStorage.Enqueue(OrderQty);
        AssemblyOrderPage."Item Tracking Lines".Invoke();

        repeat
            if AssemblyOrderPage.Lines.Type.Value = ItemMsg then begin
                LibraryVariableStorage.Enqueue(ItemTrackingAction::SelectEntries);
                AssemblyOrderPage.Lines."Item Tracking Lines".Invoke();
            end;
        until not AssemblyOrderPage.Lines.Next();

        AssemblyOrderPage.OK().Invoke();
    end;

    local procedure GetLeadTimesItemOrSKU(var LeadTimeCalculation: DateFormula; var SafetyLeadTime: DateFormula; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    var
        SKU: Record "Stockkeeping Unit";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // IF SKU exist take values from SKU
        if FindSKU(SKU, ItemNo, LocationCode, VariantCode) then begin
            LeadTimeCalculation := SKU."Lead Time Calculation";
            SafetyLeadTime := SKU."Safety Lead Time";
        end else begin // otherwise take values from Item card
            Item.Get(ItemNo);
            LeadTimeCalculation := Item."Lead Time Calculation";
            SafetyLeadTime := Item."Safety Lead Time";
            if Format(SafetyLeadTime) = '' then begin // if safety lead time is empty consider the manuf setup one
                InventorySetup.Get();
                SafetyLeadTime := InventorySetup."Default Safety Lead Time";
            end;
        end;
    end;

    local procedure GetRollupCost(AssemblyHeader: Record "Assembly Header"): Decimal
    var
        AssemblyLine: Record "Assembly Line";
        UnitCost: Decimal;
    begin
        UnitCost := 0;
        Clear(AssemblyLine);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        if not AssemblyLine.FindSet() then
            exit(UnitCost);

        repeat
            UnitCost += AssemblyLine."Cost Amount";
        until AssemblyLine.Next() = 0;

        exit(UnitCost);
    end;

    local procedure GetRollupPrice(AssemblyHeader: Record "Assembly Header") Price: Decimal
    var
        AssemblyLine: Record "Assembly Line";
    begin
        Price := 0;

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindSet();

        repeat
            case AssemblyLine.Type of
                AssemblyLine.Type::Item:
                    Price += AssemblyLine.Quantity * GetSalesPrice(AssemblyLine."No.", AssemblyLine."Variant Code");
                AssemblyLine.Type::Resource:
                    Price += AssemblyLine.Quantity * GetResourcePrice(AssemblyLine."No.");
            end;
        until AssemblyLine.Next() = 0;
    end;

    local procedure FindSOL(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SOLIndex: Integer)
    begin
        Clear(SalesLine);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet(true);

        if SOLIndex > 1 then
            SalesLine.Next(SOLIndex - 1);
    end;

    local procedure FindSKU(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]): Boolean
    begin
        Clear(SKU);
        SKU.SetRange("Item No.", ItemNo);
        if LocationCode <> '' then
            SKU.SetRange("Location Code", LocationCode);
        if VariantCode <> '' then
            SKU.SetRange("Variant Code", VariantCode);

        exit(SKU.FindFirst())
    end;

    local procedure ChangeCostAndPriceOnCompList(ItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        Resource: Record Resource;
    begin
        Clear(BOMComponent);
        BOMComponent.SetRange("Parent Item No.", ItemNo);
        BOMComponent.FindSet();

        // Iterate through components of and update cost and price
        repeat
            case BOMComponent.Type of
                BOMComponent.Type::Item:
                    begin
                        Item.Get(BOMComponent."No.");
                        Item.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
                        Item.Validate("Unit Cost", LibraryRandom.RandDec(1000, 2));
                        Item.Modify(true);
                    end;
                BOMComponent.Type::Resource:
                    begin
                        Resource.Get(BOMComponent."No.");
                        Resource.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
                        Resource.Validate("Unit Cost", LibraryRandom.RandDec(1000, 2));
                        Resource.Validate("Direct Unit Cost", Resource."Unit Cost");
                        Resource.Modify(true);
                    end;
            end;
        until BOMComponent.Next() = 0;
    end;

    local procedure ChangeLeadTimeOffsetOnCompList(ItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        Clear(BOMComponent);
        BOMComponent.SetRange("Parent Item No.", ItemNo);
        if BOMComponent.Count <= 0 then
            exit;

        // Iterate through components of type items and update offset
        repeat
            if BOMComponent.Type = BOMComponent.Type::Item then begin
                Evaluate(BOMComponent."Lead-Time Offset", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
                BOMComponent.Modify(true);
            end;
        until BOMComponent.Next() = 0;
    end;

    local procedure ChangeLeadTimesOnSKU(SKU: Record "Stockkeeping Unit")
    begin
        Evaluate(SKU."Lead Time Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        Evaluate(SKU."Safety Lead Time", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        SKU.Modify(true);
    end;

    local procedure GetAsmTypeForSalesType(SalesDocumentType: Enum "Sales Document Type"): Enum "Assembly Document Type"
    var
        AsmHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
    begin
        case SalesDocumentType of
            SalesHeader."Document Type"::Quote:
                exit(AsmHeader."Document Type"::Quote);
            SalesHeader."Document Type"::Order:
                exit(AsmHeader."Document Type"::Order);
            SalesHeader."Document Type"::"Blanket Order":
                exit(AsmHeader."Document Type"::"Blanket Order");
            else
                Error(DocTypeNotSupportedErr);
        end;
    end;

    local procedure SelectAssemblyLines(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; LineType: Enum "BOM Component Type"; ItemNo: Code[20]; LocationCode: Code[20]; VariantCode: Code[10])
    begin
        Clear(AssemblyLine);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange("No.", ItemNo);
        if LineType = "BOM Component Type"::Item then begin
            AssemblyLine.SetFilter("Variant Code", '%1', VariantCode);
            AssemblyLine.SetFilter("Location Code", '%1', LocationCode);
        end;
    end;

    local procedure AddInventoryNonDirectLocation(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure AddInvNonDirectLocAllComponent(AssemblyHeader: Record "Assembly Header"; QtyPercentage: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        Clear(AssemblyLine);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        if not AssemblyLine.FindSet() then
            exit;

        repeat
            AddInventoryNonDirectLocation(AssemblyLine."No.", AssemblyLine."Location Code", AssemblyLine."Variant Code",
              QtyPercentage / 100 * AssemblyLine."Quantity per" *
              LibraryInventory.GetQtyPerForItemUOM(AssemblyHeader."Item No.", AssemblyHeader."Unit of Measure Code") *
              AssemblyHeader.Quantity);
        until AssemblyLine.Next() = 0;
    end;

    local procedure PostPositiveAdjmtOnBin(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CountAssemblyOrders(DocumentType: Enum "Assembly Document Type"): Integer
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Reset();
        AssemblyHeader.SetRange("Document Type", DocumentType);
        exit(AssemblyHeader.Count);
    end;

    local procedure CountReservationEntries(): Integer
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        Clear(ReservationEntry);
        exit(ReservationEntry.Count);
    end;

    local procedure CountHardLinkEntries(): Integer
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        Clear(ATOLink);
        exit(ATOLink.Count);
    end;

    local procedure FindItemTrackingLikeSNALL(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("SN Specific Tracking", true);
        ItemTrackingCode.SetRange("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; DocumentType: Enum "Assembly Document Type"; Item: Record Item; VariantCode: Code[10]; LocationCode: Code[10]; DueDate: Date; UOM: Code[10]; Qty: Decimal)
    begin
        Clear(AssemblyHeader);
        AssemblyHeader.SetRange("Document Type", DocumentType);
        AssemblyHeader.SetRange("Item No.", Item."No.");
        if VariantCode = '' then
            AssemblyHeader.SetRange(Description, Item.Description)
        else
            AssemblyHeader.SetRange(Description, VariantCode);
        AssemblyHeader.SetFilter("Variant Code", '%1', VariantCode);
        AssemblyHeader.SetFilter("Location Code", '%1', LocationCode);
        AssemblyHeader.SetRange("Due Date", DueDate);
        AssemblyHeader.SetRange("Unit of Measure Code", UOM);
        AssemblyHeader.SetRange(Quantity, Qty);
        AssemblyHeader.SetRange("Quantity (Base)", Qty * LibraryInventory.GetQtyPerForItemUOM(Item."No.", UOM));

        AssemblyHeader.FindSet();
    end;

    local procedure FindItemAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; Index: Integer)
    begin
        AssemblyHeader.Reset();
        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindSet();
        if Index > 1 then
            AssemblyHeader.Next(Index - 1);
    end;

    local procedure FindLinkedAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; SalesDocumentType: Enum "Sales Document Type"; SalesDocumentNo: Code[20])
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        ATOLink.SetRange("Document Type", SalesDocumentType);
        ATOLink.SetRange("Document No.", SalesDocumentNo);
        ATOLink.FindFirst();
        AssemblyHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No.");
    end;

    local procedure FindSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        Clear(SalesLine);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
    end;

    local procedure CollectSetupBOMComponent(var ItemBuf: Record Item; ParentItemNo: Code[20])
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        ItemTrackingCode: Code[10];
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.FindSet();
        ItemTrackingCode := FindItemTrackingLikeSNALL();
        repeat
            Item.Get(BOMComponent."No.");
            Item.Validate("Item Tracking Code", ItemTrackingCode);
            Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
            Item.Modify(true);
            ItemBuf := Item;
            ItemBuf.Insert();
        until BOMComponent.Next() = 0;
    end;

    local procedure AssertAssemblyLinesDefaultBOM(AssemblyHeader: Record "Assembly Header"; BOMComponent: Record "BOM Component"; LocationCode: Code[20]; NoOfLines: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        SelectAssemblyLines(AssemblyHeader, AssemblyLine, BOMComponent.Type, BOMComponent."No.", LocationCode, BOMComponent."Variant Code");

        Assert.AreEqual(
          NoOfLines, AssemblyLine.Count,
          StrSubstNo(NoAssemblyInFilterMsg, NoOfLines, AssemblyLine.TableCaption(), AssemblyLine.GetFilters));

        if NoOfLines > 0 then begin
            AssemblyLine.FindFirst();
            // Assert fields on the Assembly order line (first one of this kind only)
            Assert.AreEqual(
              BOMComponent.Description, AssemblyLine.Description,
              StrSubstNo(WrongValueOnAsmOrderLineMsg, AssemblyLine.FieldCaption(Description), AssemblyLine.GetFilters));
            Assert.AreEqual(
              BOMComponent."Unit of Measure Code", AssemblyLine."Unit of Measure Code",
              StrSubstNo(WrongValueOnAsmOrderLineMsg, AssemblyLine.FieldCaption("Unit of Measure Code"), AssemblyLine.GetFilters));
            Assert.AreEqual(
              BOMComponent."Quantity per", AssemblyLine."Quantity per" / AssemblyHeader."Qty. per Unit of Measure",
              StrSubstNo(WrongValueOnAsmOrderLineMsg, AssemblyLine.FieldCaption("Qty. per Unit of Measure"), AssemblyLine.GetFilters));
            Assert.AreEqual(
              LibraryInventory.GetQtyPerForItemUOM(AssemblyHeader."Item No.", AssemblyHeader."Unit of Measure Code") *
              BOMComponent."Quantity per" * AssemblyHeader.Quantity, AssemblyLine.Quantity,
              StrSubstNo(WrongValueOnAsmOrderLineMsg, AssemblyLine.FieldCaption(Quantity), AssemblyLine.GetFilters));
            if AssemblyLine.Type = AssemblyLine.Type::Item then
                Assert.AreEqual(
                  LibraryInventory.GetQtyPerForItemUOM(AssemblyLine."No.", AssemblyLine."Unit of Measure Code") *
                  BOMComponent."Quantity per" * AssemblyHeader."Quantity (Base)", AssemblyLine."Quantity (Base)",
                  StrSubstNo(WrongValueOnAsmOrderLineMsg, AssemblyLine.FieldCaption("Quantity (Base)"), AssemblyLine.GetFilters));
            Assert.IsTrue(
              BOMComponent."Lead-Time Offset" = AssemblyLine."Lead-Time Offset",
              StrSubstNo(WrongValueOnAsmOrderLineMsg, AssemblyLine.FieldCaption("Lead-Time Offset"), AssemblyLine.GetFilters));
        end;
    end;

    local procedure AssertNumberOfAssemblyLines(AssemblyHeader: Record "Assembly Header"; NoOfLines: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        Clear(AssemblyLine);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");

        Assert.AreEqual(
          NoOfLines, AssemblyLine.Count, StrSubstNo(NoAssemblyInFilterMsg, NoOfLines, AssemblyLine.TableCaption(), AssemblyLine.GetFilters));
    end;

    local procedure AssertAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; DocumentType: Enum "Assembly Document Type"; Item: Record Item; VariantCode: Code[10]; LocationCode: Code[10]; DueDate: Date; UOM: Code[10]; Qty: Decimal; NoOfHeaders: Integer)
    begin
        FindAssemblyHeader(AssemblyHeader, DocumentType, Item, VariantCode, LocationCode, DueDate, UOM, Qty);

        Assert.AreEqual(
          NoOfHeaders, AssemblyHeader.Count,
          StrSubstNo(NoAssemblyInFilterMsg, NoOfHeaders, AssemblyHeader.TableCaption(), AssemblyHeader.GetFilters));
    end;

    local procedure AssertNoAssemblyHeader(DocumentType: Enum "Assembly Document Type"; DocumentNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Clear(AssemblyHeader);
        Commit();
        asserterror AssemblyHeader.Get(DocumentType, DocumentNo);
    end;

    local procedure AssertAsmOrderForDefaultBOM(var AssemblyHeader: Record "Assembly Header"; DocumentType: Enum "Assembly Document Type"; Item: Record Item; VariantCode: Code[10]; LocationCode: Code[10]; DueDate: Date; UOM: Code[10]; Qty: Decimal; NoOfHeaders: Integer)
    var
        BOMComponent: Record "BOM Component";
    begin
        // Verify - assembly header
        AssertAssemblyHeader(AssemblyHeader, DocumentType, Item, VariantCode, LocationCode, DueDate, UOM, Qty, NoOfHeaders);

        // Assert number of AO lines matches BOM list
        Clear(BOMComponent);
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        if BOMComponent.Count <= 0 then
            exit;
        AssertNumberOfAssemblyLines(AssemblyHeader, BOMComponent.Count);

        // Iterate through components
        // Verify - Lines
        repeat
            case BOMComponent.Type of
                // Text only - ignore
                BOMComponent.Type::" ":
                    ;
                else
                    AssertAssemblyLinesDefaultBOM(AssemblyHeader, BOMComponent, LocationCode, 1);
            end;
        until BOMComponent.Next() = 0;
    end;

    local procedure AssertReservationEntries(SalesLine: Record "Sales Line"; AssemblyHeader: Record "Assembly Header"): Integer
    var
        EntryNo: Integer;
    begin
        EntryNo := LibraryAssembly.VerifySaleReservationEntryATO(SalesLine);
        Assert.AreEqual(EntryNo, LibraryAssembly.VerifytAsmReservationEntryATO(AssemblyHeader), DiffEntryNoInReservEntriesMsg);

        exit(EntryNo);
    end;

    local procedure AssertReservationEntryDeleted(EntryNo: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Entry No.", EntryNo);

        Commit();
        asserterror ReservationEntry.FindFirst();
    end;

    local procedure AssertDatesOnAsmOrder(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        LeadTimeCalculation: DateFormula;
        SafetyLeadTime: DateFormula;
        EndingDate: Date;
        StartingDate: Date;
    begin
        // Assert on header
        GetLeadTimesItemOrSKU(
          LeadTimeCalculation, SafetyLeadTime, AssemblyHeader."Item No.", AssemblyHeader."Location Code", AssemblyHeader."Variant Code");
        if Format(SafetyLeadTime) = '' then
            EndingDate := AssemblyHeader."Due Date"
        else
            EndingDate := CalcDate('<-' + Format(SafetyLeadTime) + '>', AssemblyHeader."Due Date");
        if Format(LeadTimeCalculation) = '' then
            StartingDate := EndingDate
        else
            StartingDate := CalcDate('<-' + Format(LeadTimeCalculation) + '>', EndingDate);
        Assert.AreEqual(
          EndingDate, AssemblyHeader."Ending Date",
          StrSubstNo(WrongDateOnAssemblyMsg, AssemblyHeader.FieldCaption("Ending Date"), AssemblyHeader.TableCaption(), AssemblyHeader."No."));
        Assert.AreEqual(
          StartingDate, AssemblyHeader."Starting Date",
          StrSubstNo(WrongDateOnAssemblyMsg,
            AssemblyHeader.FieldCaption("Starting Date"), AssemblyHeader.TableCaption(), AssemblyHeader."No."));

        // Assert on lines
        Clear(AssemblyLine);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        repeat
            if AssemblyLine.Type = AssemblyLine.Type::Item then
                if Format(AssemblyLine."Lead-Time Offset") = '' then
                    Assert.AreEqual(
                      StartingDate, AssemblyLine."Due Date",
                      StrSubstNo(WrongDateOnAssemblyMsg, AssemblyLine.FieldCaption("Due Date"), AssemblyLine.TableCaption(), AssemblyLine."No."))
                else
                    Assert.AreEqual(
                      CalcDate('<-' + Format(AssemblyLine."Lead-Time Offset") + '>', StartingDate), AssemblyLine."Due Date",
                      StrSubstNo(WrongDateOnAssemblyMsg, AssemblyLine.FieldCaption("Due Date"), AssemblyLine.TableCaption(), AssemblyLine."No."));
        until AssemblyLine.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure RollUpCostConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CONFIRM_ROLLUP_COST) > 0, Question);
        Reply := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckAsmOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        TCXATOSunshineCheckAsm(Item, '', '', "Sales Document Type"::Order, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckAsmOrderVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        TCXATOSunshineCheckAsm(Item, ItemVariant.Code, '', "Sales Document Type"::Order, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckAsmOrderReservation()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        TCXATOSunshineCheckAsm(Item, '', '', "Sales Document Type"::Order, AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckHardLinkAsmOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        TCXATOSunshineCheckAsm(Item, '', '', "Sales Document Type"::Order, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckAsmQuote()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        TCXATOSunshineCheckAsm(Item, '', '', "Sales Document Type"::Quote, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckAsmQuoteVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        TCXATOSunshineCheckAsm(Item, ItemVariant.Code, '', "Sales Document Type"::Quote, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckHardLinkAsmQuote()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        TCXATOSunshineCheckAsm(Item, '', '', "Sales Document Type"::Quote, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckAsmBlanketOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        TCXATOSunshineCheckAsm(Item, '', '', "Sales Document Type"::"Blanket Order", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckAsmBlanketOrderVar()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        TCXATOSunshineCheckAsm(Item, ItemVariant.Code, '', "Sales Document Type"::"Blanket Order", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckAsmBlanketOrderHardLnk()
    var
        Item: Record Item;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        TCXATOSunshineCheckAsm(Item, '', '', "Sales Document Type"::"Blanket Order", AssertOption::"Hard link");
    end;

    local procedure TCXATOSunshineCheckAsm(Item: Record Item; VariantCode: Code[10]; LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type"; AssertOption: Option Orders,Reservation,"Hard link")
    var
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        DueDate: Date;
        NoOfAssemblyOrders: Integer;
        AsmDocumentType: Enum "Assembly Document Type";
    begin
        // TC11, TC12, TC115 and TC124 from the TDS - see Documentation

        AsmDocumentType := GetAsmTypeForSalesType(SalesDocumentType);
        NoOfAssemblyOrders := CountAssemblyOrders(AsmDocumentType);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item."No.", VariantCode, OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);

        FindAssemblyHeader(AssemblyHeader, AsmDocumentType, Item, VariantCode, LocationCode, DueDate, Item."Base Unit of Measure", OrderQty);

        case AssertOption of
            // Assert Assembly doc created
            AssertOption::Orders:
                begin
                    // Assert that 1 assembly doc is created for the ATO items placed on sales line
                    Assert.AreEqual(NoOfAssemblyOrders + 1, CountAssemblyOrders(AsmDocumentType), OneAsmOrderCreateMsg);

                    // Verify - assembly doc
                    AssertAsmOrderForDefaultBOM(AssemblyHeader, AsmDocumentType, Item, VariantCode, LocationCode, DueDate,
                      Item."Base Unit of Measure", OrderQty, 1);
                end;
            // Assert reservation entries
            AssertOption::Reservation:
                AssertReservationEntries(SalesLine, AssemblyHeader);
            // Assert hard link entry
            AssertOption::"Hard link":
                LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 1);
        end;
    end;

    [Test]
    [HandlerFunctions('ATOLinesPageHandler')]
    [Scope('OnPrem')]
    procedure TestATOLinesPage()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        OrderQty: Integer;
        DueDate: Date;
    begin
        // Setup. Create ATO Assembly item and Sales Order.
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := WorkDate2 + LibraryRandom.RandInt(30);
        CreateSaleLineWithShptDate(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", '', OrderQty, DueDate, '');
        FindSOL(SalesHeader, SalesLine, 1);
        FindAssemblyHeader(AssemblyHeader, "Assembly Document Type"::Order, Item, '', '', DueDate, Item."Base Unit of Measure", OrderQty);

        // Add enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 100);

        // Personalize ATO Lines.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines.AssembleToOrderLines.Invoke();

        // Add ATO line in page handler.

        // Exercise: Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify - AO is posted
        AssertNoAssemblyHeader(AssemblyHeader."Document Type", AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckDeleteSOLOrder()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Order, DeleteOption::"Delete SOL", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckZeroQtySOLOrder()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Order, DeleteOption::"Zero Quantity on SOL", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOOrder()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Order, DeleteOption::"Delete SO", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOLCheckReserv()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Order, DeleteOption::"Delete SOL", AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOZeroQtySOLChkReserv()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Order, DeleteOption::"Zero Quantity on SOL", AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOCheckReserv()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Order, DeleteOption::"Delete SO", AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOLCheckHardLinkOrder()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Order, DeleteOption::"Delete SOL", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOZeroQtySOLChkHardLinkOrder()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Order, DeleteOption::"Zero Quantity on SOL", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOZeroQtySOLChkHardLinkOrderWithEntries()
    begin
        Initialize();
        TCXATODeleteAOWithEntries('', "Sales Document Type"::Order, DeleteOption::"Zero Quantity on SOL", AssertOption::"Hard link", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOCheckHardLinkOrder()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Order, DeleteOption::"Delete SO", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckDeleteSOLQuote()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Quote, DeleteOption::"Delete SOL", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckZeroQtySOLQuote()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Quote, DeleteOption::"Zero Quantity on SOL", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOQuote()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Quote, DeleteOption::"Delete SO", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOLCheckHardLinkQuote()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Quote, DeleteOption::"Delete SOL", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOZeroQtySOLChkHardLinkQuote()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Quote, DeleteOption::"Zero Quantity on SOL", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOCheckHardLinkQuote()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::Quote, DeleteOption::"Delete SO", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckDeleteSOLBlanket()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::"Blanket Order", DeleteOption::"Delete SOL", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOCheckZeroQtySOLBlanket()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::"Blanket Order", DeleteOption::"Zero Quantity on SOL", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOBlanket()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::"Blanket Order", DeleteOption::"Delete SO", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOLChkHardLinkBlanket()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::"Blanket Order", DeleteOption::"Delete SOL", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOZeroQtySOLChkHardLnkBlanket()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::"Blanket Order", DeleteOption::"Zero Quantity on SOL", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATODeleteSOCheckHardLnkBlanket()
    begin
        Initialize();
        TCXATODeleteAO('', "Sales Document Type"::"Blanket Order", DeleteOption::"Delete SO", AssertOption::"Hard link");
    end;

    local procedure TCXATODeleteAO(LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type"; DeleteOption: Option "Zero Quantity on SOL","Delete SOL","Delete SO"; AssertOption: Option Orders,Reservation,"Hard link")
    begin
        TCXATODeleteAOWithEntries(LocationCode, SalesDocumentType, DeleteOption, AssertOption, false);
    end;

    local procedure TCXATODeleteAOWithEntries(LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type"; DeleteOption: Option "Zero Quantity on SOL","Delete SOL","Delete SO"; AssertOption: Option Orders,Reservation,"Hard link"; WithEntries: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        OrderQty: Integer;
        DueDate: Date;
        EntryNo: Integer;
        NoOfAssemblyOrders: Integer;
    begin
        // TC13, TC14, TC16, TC116, TC117, TC118, TC125, TC126 and TC127 from the TDS - see Documentation
        // Create the "assembled" Item
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        NoOfAssemblyOrders := CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType));

        // Create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item."No.", '', OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);

        FindAssemblyHeader(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate,
          Item."Base Unit of Measure", OrderQty);

        MockInvtAdjmtEntryOrder(AssemblyHeader."No.", WithEntries);

        // Initial assert
        case AssertOption of
            // Verify - assembly order
            AssertOption::Orders:
                begin
                    AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate,
                      Item."Base Unit of Measure", OrderQty, 1);
                    // Assert that 1 assembly orders is created for the ATO items placed on sales order line
                    Assert.AreEqual(NoOfAssemblyOrders + 1, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)),
                      OneAsmOrderCreateMsg);
                end;
            // Assert reservation entries
            AssertOption::Reservation:
                EntryNo := AssertReservationEntries(SalesLine, AssemblyHeader);
            // Assert hard link entry
            AssertOption::"Hard link":
                LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 1);
        end;

        // exercise - delete/set zero qty
        case DeleteOption of
            DeleteOption::"Delete SOL":
                // Exercise - delete SOL
                SalesLine.Delete(true);
            DeleteOption::"Zero Quantity on SOL":
                begin
                    // Exercise - zero SOL
                    SalesLine.Validate(Quantity, 0);
                    SalesLine.Modify(true);
                end;
            DeleteOption::"Delete SO":
                // Exercise - delete SO
                SalesHeader.Delete(true);
        end;

        // Assert
        case AssertOption of
            // Assert asm order deleted
            AssertOption::Orders:
                AssertNoAssemblyHeader(AssemblyHeader."Document Type", AssemblyHeader."No.");
            // Assert reservation entries deleted
            AssertOption::Reservation:
                AssertReservationEntryDeleted(EntryNo);
            // Assert hard link entry
            AssertOption::"Hard link":
                if DeleteOption = DeleteOption::"Zero Quantity on SOL" then
                    if (SalesDocumentType = "Sales Document Type"::Order) and WithEntries then
                        LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 1)
                    else
                        LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 0)
                else
                    // Deleted in all other cases
                    LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 0);
        end;
    end;

    local procedure MockInvtAdjmtEntryOrder(AssemblyOrderNo: Code[20]; WithEntries: Boolean)
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        if WithEntries then begin
            InvtAdjmtEntryOrder.Init();
            InvtAdjmtEntryOrder."Order Type" := InvtAdjmtEntryOrder."Order Type"::Assembly;
            InvtAdjmtEntryOrder."Order No." := AssemblyOrderNo;
            InvtAdjmtEntryOrder.Insert();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMultipleAO()
    begin
        Initialize();
        TCXATOMultipleAO('', "Sales Document Type"::Order, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOATSMixAO()
    begin
        Initialize();
        TCXATOMultipleAO('', "Sales Document Type"::Order, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMultipleQuotes()
    begin
        Initialize();
        TCXATOMultipleAO('', "Sales Document Type"::Quote, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOATSMixQuotes()
    begin
        Initialize();
        TCXATOMultipleAO('', "Sales Document Type"::Quote, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMultipleBlanketOrders()
    begin
        Initialize();
        TCXATOMultipleAO('', "Sales Document Type"::"Blanket Order", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOATSMixBlanketOrders()
    begin
        Initialize();
        TCXATOMultipleAO('', "Sales Document Type"::"Blanket Order", true, false);
    end;

    local procedure TCXATOMultipleAO(LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type"; UseATS: Boolean; GetAsmOrdersFromSalesHeader: Boolean)
    var
        Item1: Record Item;
        Item2: Record Item;
        ItemATS: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty1: Integer;
        DueDate1: Date;
        OrderQty2: Integer;
        DueDate2: Date;
        NoOfAssemblyOrders: Integer;
    begin
        // TC15 and TC17 from the TDS - see Documentation
        // Create the "assembled" Items
        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item1."Costing Method"::FIFO);
        CreateAssembledItem(Item2, Item2."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item2."Costing Method"::FIFO);
        CreateAssembledItem(ItemATS, ItemATS."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          ItemATS."Costing Method"::FIFO);

        NoOfAssemblyOrders := CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType));

        // Exercise - create SOLs with ATO items
        OrderQty1 := LibraryRandom.RandInt(1000);
        DueDate1 := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item1."No.", '', OrderQty1, DueDate1, LocationCode);
        OrderQty2 := LibraryRandom.RandInt(1000);
        DueDate2 := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        AddSalesOrderLine(SalesHeader, SalesLine, Item2."No.", LocationCode, '', OrderQty2, DueDate2);

        // ATS, ATO mix scenario - add ATS SO line
        if UseATS then
            AddSalesOrderLine(SalesHeader, SalesLine, ItemATS."No.", LocationCode, '', LibraryRandom.RandInt(1000),
              CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2));

        // Assert that 2 assembly orders are created for the 2 ATO items placed on sales order lines
        Assert.AreEqual(NoOfAssemblyOrders + 2, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), TwoAsmOrdersCreateMsg);

        if GetAsmOrdersFromSalesHeader then
            CheckGetAsmOrdersFromSalesHeader(SalesHeader, 2);

        // Verify - assembly order 1
        AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item1, '', LocationCode, DueDate1,
          Item1."Base Unit of Measure", OrderQty1, 1);

        // Verify - assembly order 2
        AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item2, '', LocationCode, DueDate2,
          Item2."Base Unit of Measure", OrderQty2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOReadOnlyAO()
    begin
        Initialize();
        TC18ATOReadOnlyAO('', LocationBlue.Code, "Sales Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOReadOnlyQuote()
    begin
        Initialize();
        TC18ATOReadOnlyAO('', LocationBlue.Code, "Sales Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOReadOnlyBlanketOrder()
    begin
        Initialize();
        TC18ATOReadOnlyAO('', LocationBlue.Code, "Sales Document Type"::"Blanket Order");
    end;

    local procedure TC18ATOReadOnlyAO(LocationCode: Code[10]; NewLocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        TestItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        UnitOfMeasure: Record "Unit of Measure";
        ItemVariant: Record "Item Variant";
        NoOfAssemblyOrders: Integer;
        OrderQty: Integer;
        DueDate: Date;
    begin
        // TC18 from the TDS - see Documentation
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItem(TestItem);

        // Create the "assembled" Item
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        AddItemUOM(Item, LibraryRandom.RandInt(1000), UnitOfMeasure.Code);

        NoOfAssemblyOrders := CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType));

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item."No.", '', OrderQty, DueDate, LocationCode);

        // Assert that 1 assembly orders is created for the ATO items placed on sales order line
        Assert.AreEqual(NoOfAssemblyOrders + 1, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), OneAsmOrderCreateMsg);

        // Verify - assembly order
        AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate,
          Item."Base Unit of Measure", OrderQty, 1);

        // commit as there are several consecutive assert errors.
        Commit();

        // Try to change fields on assembly header
        asserterror AssemblyHeader.Validate("Item No.", TestItem."No.");
        asserterror AssemblyHeader.Validate(Quantity, OrderQty + 1);
        asserterror AssemblyHeader.Validate("Due Date", CalcDate('<+1D>', DueDate));
        asserterror AssemblyHeader.Delete(true);
        asserterror AssemblyHeader.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        asserterror AssemblyHeader.Validate("Variant Code", ItemVariant.Code);
        asserterror AssemblyHeader.Validate("Location Code", NewLocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSameItemAO()
    begin
        Initialize();
        TC110ATOMultipleSameItemAO('', "Sales Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSameItemQuote()
    begin
        Initialize();
        TC110ATOMultipleSameItemAO('', "Sales Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSameItemBlanketOrder()
    begin
        Initialize();
        TC110ATOMultipleSameItemAO('', "Sales Document Type"::"Blanket Order");
    end;

    local procedure TC110ATOMultipleSameItemAO(LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty1: Integer;
        DueDate1: Date;
        OrderQty2: Integer;
        DueDate2: Date;
        NoOfAssemblyOrders: Integer;
    begin
        // TC110 from the TDS - see Documentation

        // Create the "assembled" Items
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        NoOfAssemblyOrders := CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType));

        // Exercise - create SOLs with ATO items
        OrderQty1 := LibraryRandom.RandInt(1000);
        DueDate1 := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item."No.", '', OrderQty1, DueDate1, LocationCode);
        OrderQty2 := LibraryRandom.RandInt(1000);
        DueDate2 := CalcDate('<+1D>', DueDate1);
        AddSalesOrderLine(SalesHeader, SalesLine, Item."No.", LocationCode, '', OrderQty2, DueDate2);

        // Assert that 2 assembly orders are created for the 2 ATO item placed on sales order lines
        Assert.AreEqual(NoOfAssemblyOrders + 2, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), TwoAsmOrdersCreateMsg);

        // Verify - assembly order AO1
        AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate1,
          Item."Base Unit of Measure", OrderQty1, 1);

        // Verify - assembly order AO2
        AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate2,
          Item."Base Unit of Measure", OrderQty2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KitInAKitAO()
    begin
        Initialize();
        TC111ATOKitInAKitAO('', "Sales Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KitInAKitQuote()
    begin
        Initialize();
        TC111ATOKitInAKitAO('', "Sales Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KitInAKitBlanketOrder()
    begin
        Initialize();
        TC111ATOKitInAKitAO('', "Sales Document Type"::"Blanket Order");
    end;

    local procedure TC111ATOKitInAKitAO(LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        ChildItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        BOMComponent: Record "BOM Component";
        OrderQty: Integer;
        DueDate: Date;
        NoOfAssemblyOrders: Integer;
    begin
        // TC111 from the TDS - see Documentation

        // Create the "assembled" Items
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        CreateAssembledItem(ChildItem, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Create the kit in a kit
        AddComponentToAssemblyList(BOMComponent, BOMComponent.Type::Item, ChildItem."No.", Item."No.", '',
          BOMComponent."Resource Usage Type"::Direct, ChildItem."Base Unit of Measure", LibraryRandom.RandInt(1000));

        NoOfAssemblyOrders := CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType));

        // Exercise - create SOLs with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item."No.", '', OrderQty, DueDate, LocationCode);

        // Assert that one assembly order is created for the ATO item placed on sales order lines
        Assert.AreEqual(NoOfAssemblyOrders + 1, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), OneAsmOrderCreateMsg);

        // Verify - assembly order including additional comp
        AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate,
          Item."Base Unit of Measure", OrderQty, 1);
        AssertAssemblyLinesDefaultBOM(AssemblyHeader, BOMComponent, LocationCode, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATSOrder()
    begin
        Initialize();
        TCXATOToATSAO('', "Sales Document Type"::Order, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSToATOOrder()
    begin
        Initialize();
        TCXATOToATSAO('', "Sales Document Type"::Order, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATSQuote()
    begin
        Initialize();
        TCXATOToATSAO('', "Sales Document Type"::Quote, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSToATOQuote()
    begin
        Initialize();
        TCXATOToATSAO('', "Sales Document Type"::Quote, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATSBlanketOrder()
    begin
        Initialize();
        TCXATOToATSAO('', "Sales Document Type"::"Blanket Order", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSToATOBlanketOrder()
    begin
        Initialize();
        TCXATOToATSAO('', "Sales Document Type"::"Blanket Order", false);
    end;

    local procedure TCXATOToATSAO(LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type"; StartwithATO: Boolean)
    var
        ItemATO: Record Item;
        ItemATS: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        DueDate: Date;
        ItemNo: Code[20];
        NoOfAssemblyOrders: Integer;
    begin
        // TC113 and TC114 from the TDS - see Documentation

        // Create the "assembled" Items
        CreateAssembledItem(ItemATO, ItemATO."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          ItemATO."Costing Method"::FIFO);
        CreateAssembledItem(ItemATS, ItemATS."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          ItemATS."Costing Method"::FIFO);
        if StartwithATO then
            ItemNo := ItemATO."No."
        else
            ItemNo := ItemATS."No.";

        NoOfAssemblyOrders := CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType));

        // Exercise - create SOL with ATO/ATS item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, ItemNo, '', OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);

        // Assert that one assembly order is created for the ATO item placed on sales order lines
        // And no new one for ATS item
        if StartwithATO then begin
            Assert.AreEqual(NoOfAssemblyOrders + 1, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), OneAsmOrderCreateMsg);
            AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), ItemATO, '', LocationCode,
              DueDate, ItemATO."Base Unit of Measure", OrderQty, 1);
            ItemNo := ItemATS."No.";
        end
        else begin
            Assert.AreEqual(NoOfAssemblyOrders, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), NoAsmOrderCreateMsg);
            ItemNo := ItemATO."No.";
        end;

        if StartwithATO then begin
            // Exercise check item no cannot be switched if Qty to asm <>0
            Commit();
            asserterror SalesLine.Validate("No.", ItemNo);

            // Exercise - Change Qty to asm to 0 and then item no
            SalesLine.Validate("Qty. to Assemble to Order", 0);
            SalesLine.Validate("No.", ItemNo);
            SalesLine.Modify(true);
        end
        else begin
            SalesLine.Validate("No.", ItemNo);
            // Shipment date gets "reseted" when changing item no
            SalesLine.Validate("Shipment Date", DueDate);
            SalesLine.Modify(true);
        end;

        // Assert that after switch assembly order is created when ATS to ATO switch is done
        // And new ATO is deleted from ATO to ATS switch
        if StartwithATO then
            Assert.AreEqual(NoOfAssemblyOrders, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), OneAsmOrderDeleteMsg)
        else begin
            Assert.AreEqual(NoOfAssemblyOrders + 1, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), OneAsmOrderCreateMsg);
            AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), ItemATO, '', LocationCode, DueDate,
              ItemATO."Base Unit of Measure", OrderQty, 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSCheckNoAO()
    begin
        Initialize();
        TCxATSNoATO("Assembly Policy"::"Assemble-to-Stock", '', AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSCheckNoReserv()
    begin
        Initialize();
        TCxATSNoATO("Assembly Policy"::"Assemble-to-Stock", '', AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSCheckNoHardLink()
    begin
        Initialize();
        TCxATSNoATO("Assembly Policy"::"Assemble-to-Stock", '', AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATONegativeNoAO()
    begin
        Initialize();
        TCxATSNoATO("Assembly Policy"::"Assemble-to-Order", '', AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATONegativeNoReserv()
    begin
        Initialize();
        TCxATSNoATO("Assembly Policy"::"Assemble-to-Order", '', AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATONegativeNoHardLink()
    begin
        Initialize();
        TCxATSNoATO("Assembly Policy"::"Assemble-to-Order", '', AssertOption::"Hard link");
    end;

    local procedure TCxATSNoATO(AssemblyPolicy: Enum "Assembly Policy"; LocationCode: Code[10]; AssertOption: Option Orders,Reservation,"Hard link")
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        DueDate: Date;
        NoOfAssemblyOrders: Integer;
        NoOfResEntries: Integer;
        NoOfHardLinkEntries: Integer;
    begin
        // TC128 and TC141 from the TDS - see Documentation

        NoOfAssemblyOrders := CountAssemblyOrders(AssemblyHeader."Document Type"::Order);
        NoOfResEntries := CountReservationEntries();
        NoOfHardLinkEntries := CountHardLinkEntries();

        CreateAssembledItem(Item, AssemblyPolicy, LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATS item or with ATO item and negative qty
        OrderQty := LibraryRandom.RandInt(1000);
        if AssemblyPolicy = "Assembly Policy"::"Assemble-to-Order" then
            OrderQty := -OrderQty;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);

        case AssertOption of
            // Assert Assembly order created
            AssertOption::Orders:
                // Assert that no assembly order is created for the ATO items placed on sales order line
                Assert.AreEqual(NoOfAssemblyOrders, CountAssemblyOrders(AssemblyHeader."Document Type"::Order), NoAsmOrderCreateMsg);
            // Assert no new reservation entries
            AssertOption::Reservation:
                Assert.AreEqual(NoOfResEntries, CountReservationEntries(), NoReservEntryCreateMsg);
            // Assert hard link entry
            AssertOption::"Hard link":
                Assert.AreEqual(NoOfHardLinkEntries, NoOfHardLinkEntries, NoHardLinkCreateMsg);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOCheckAO()
    begin
        Initialize();
        TCXATSInATOCheck('', "Sales Document Type"::Order, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOCheckResEntry()
    begin
        Initialize();
        TCXATSInATOCheck('', "Sales Document Type"::Order, AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOCheckHardLinkOrder()
    begin
        Initialize();
        TCXATSInATOCheck('', "Sales Document Type"::Order, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOCheckQuote()
    begin
        Initialize();
        TCXATSInATOCheck('', "Sales Document Type"::Quote, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOCheckHardLinkQuote()
    begin
        Initialize();
        TCXATSInATOCheck('', "Sales Document Type"::Quote, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOCheckBlanketOrder()
    begin
        Initialize();
        TCXATSInATOCheck('', "Sales Document Type"::"Blanket Order", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOChkHardLinkBlnktOrder()
    begin
        Initialize();
        TCXATSInATOCheck('', "Sales Document Type"::"Blanket Order", AssertOption::"Hard link");
    end;

    local procedure TCXATSInATOCheck(LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type"; AssertOption: Option Orders,Reservation,"Hard link")
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        DueDate: Date;
        NoOfAssemblyOrders: Integer;
    begin
        // TC133, TC134, TC135 from the TDS - see Documentation
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        NoOfAssemblyOrders := CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType));

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item."No.", '', OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);

        // Make ATS as ATO
        SetQtyToAssembleToOrder(SalesLine, OrderQty);

        // Assert
        FindAssemblyHeader(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate,
          Item."Base Unit of Measure", OrderQty);
        case AssertOption of
            // Assert Assembly order created
            AssertOption::Orders:
                begin
                    // Assert that 1 assembly order is created for the ATO items placed on sales order line
                    Assert.AreEqual(
                      NoOfAssemblyOrders + 1, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), OneAsmOrderCreateMsg);

                    // Verify - assembly order
                    AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate,
                      Item."Base Unit of Measure", OrderQty, 1);
                end;
            // Assert reservation entries
            AssertOption::Reservation:
                AssertReservationEntries(SalesLine, AssemblyHeader);
            // Assert hard link entry
            AssertOption::"Hard link":
                LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncQtyCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::Quantity, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncQtyToAsmCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Quantity to Assemble",
          AssertOption::Orders);
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATOSyncLocationCodeCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Location Code", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncVariantCodeCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Variant Code", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncUOMCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::UOM, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncDueDateCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Due Date", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncQtyCheckReservation()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::Quantity, AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncQtyToAsmCheckReserv()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Quantity to Assemble",
          AssertOption::Reservation);
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATOSyncLocationCodeCheckReserv()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Location Code",
          AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncVariantCodeCheckReserv()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Variant Code",
          AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncUOMCheckReservation()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::UOM, AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncDueDateCheckReservation()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Due Date", AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncQtyCheckHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::Quantity, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncQtyToAsmCheckHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Quantity to Assemble",
          AssertOption::"Hard link");
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATOSyncLocationCodeChkHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Location Code",
          AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncVariantCodeChkHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Variant Code",
          AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncUOMCheckHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::UOM, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncDueDateCheckHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Order, ChangeOption::"Due Date", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncQtyCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::Quantity, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncQtyToAsmCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Quantity to Assemble",
          AssertOption::Orders);
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATSInATOSyncLocCodeCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Location Code", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncVariantCodeCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Variant Code", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncUOMCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::UOM, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncDueDateCheckAO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Due Date", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncQtyChkReservation()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::Quantity, AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncQtyToAsmChkReserv()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Quantity to Assemble",
          AssertOption::Reservation);
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATSInATOSyncLocCodeChkReserv()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Location Code",
          AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncVarCodeChkReserv()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Variant Code",
          AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncUOMChkReservation()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::UOM, AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncDueDateChkReserv()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Due Date", AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncQtyCheckHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::Quantity, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncQtyToAsmChkHardLnk()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Quantity to Assemble",
          AssertOption::"Hard link");
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATSInATOSyncLocCodeChkHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Location Code",
          AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncVarCodeChkHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Variant Code",
          AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncUOMCheckHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::UOM, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncDueDateChkHardLink()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Order, ChangeOption::"Due Date", AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncQtyCheckQuote()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Quote, ChangeOption::Quantity, AssertOption::Orders);
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATOSyncLocationCodeCheckQuote()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Quote, ChangeOption::"Location Code", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncVariantCodeCheckQuote()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Quote, ChangeOption::"Variant Code", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncUOMCheckQuote()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Quote, ChangeOption::UOM, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncDueDateCheckQuote()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::Quote, ChangeOption::"Due Date", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncQtyCheckQuote()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Quote, ChangeOption::Quantity, AssertOption::Orders);
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATSInATOSyncLocCodeCheckQuote()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Quote, ChangeOption::"Location Code", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncVariantCodeCheckQ()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Quote, ChangeOption::"Variant Code", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncUOMCheckQuote()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Quote, ChangeOption::UOM, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncDueDateCheckQuote()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::Quote, ChangeOption::"Due Date", AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncQtyCheckBlanketOrder()
    begin
        Initialize();
        TCXATOSync(
          "Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::"Blanket Order", ChangeOption::Quantity, AssertOption::Orders);
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATOSyncLocationCodeCheckBlnktO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::"Blanket Order", ChangeOption::"Location Code",
          AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncVariantCodeCheckBlnktOr()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::"Blanket Order", ChangeOption::"Variant Code",
          AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncUOMCheckBlnktOrdr()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::"Blanket Order", ChangeOption::UOM,
          AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOSyncDueDateCheckBlnktOrdr()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Order", "Sales Document Type"::"Blanket Order", ChangeOption::"Due Date",
          AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemCategoryCodeAfterPostingAssemblyOrder()
    var
        ComponentItem: Record Item;
        ParentItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Location: Record Location;
    begin
        // [FEATURE] [Assembly] [Item Ledger Entry]
        // [SCENARIO 376029] Item Category Code should be replicated on Item Ledger Entry after Posting Assembly Order
        Initialize();

        // [GIVEN] Parent Item with Item Category Code = "X1" and Warehouse Class Code = "Y1"
        CreateItemWithCategoryAndWarehouseClass(ParentItem);

        // [GIVEN] Component Item with Item Category Code = "X2" and Warehouse Class Code = "Y2"
        CreateItemWithCategoryAndWarehouseClass(ComponentItem);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.PostPositiveAdjustment(
          ComponentItem, Location.Code, '', '', LibraryRandom.RandIntInRange(10, 100), WorkDate(), LibraryRandom.RandInt(10));

        // [GIVEN] Assembly Order for Parent Item
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, LibraryPlanning.SetSafetyWorkDate(), ParentItem."No.", Location.Code, LibraryRandom.RandInt(9), '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ComponentItem."No.",
          ComponentItem."Base Unit of Measure", LibraryRandom.RandInt(5), LibraryRandom.RandInt(5), '');

        // [WHEN] Post Assembly Order
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] Item Ledger Entry is created for Parent Item with Item Category Code = "X1"
        VerifyItemLedgerEntryCategory(ParentItem, AssemblyHeader."No.");

        // [THEN] Item Ledger Entry is created for Component Item with Item Category Code = "X2"
        VerifyItemLedgerEntryCategory(ComponentItem, AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncQtyCheckBlnktOrdr()
    begin
        Initialize();
        TCXATOSync(
          "Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::"Blanket Order", ChangeOption::Quantity, AssertOption::Orders);
    end;

    [Test]
    [HandlerFunctions('LocationCodeConfirm')]
    [Scope('OnPrem')]
    procedure ATSInATOSyncLocCodeCheckBlnktO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::"Blanket Order", ChangeOption::"Location Code",
          AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncVariantCodeChkBlnk()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::"Blanket Order", ChangeOption::"Variant Code",
          AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncUOMCheckBlnktOrder()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::"Blanket Order", ChangeOption::UOM, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATSInATOSyncDueDateCheckBlnktO()
    begin
        Initialize();
        TCXATOSync("Assembly Policy"::"Assemble-to-Stock", "Sales Document Type"::"Blanket Order", ChangeOption::"Due Date",
          AssertOption::Orders);
    end;

    local procedure TCXATOSync(AssemblyPolicy: Enum "Assembly Policy"; SalesDocumentType: Enum "Sales Document Type"; ChangeOption: Option Quantity,"Quantity to Assemble","Location Code","Variant Code",UOM,"Due Date"; AssertOption: Option Orders,Reservation,"Hard link")
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemVariant: Record "Item Variant";
        UnitOfMeasure: Record "Unit of Measure";
        OrderQty: Integer;
        DueDate: Date;
        LocationCode: Code[10];
        VariantCode: Code[10];
        UOMCode: Code[10];
        NoOfAssemblyOrders: Integer;
    begin
        // TC21, TC22, TC23, TC24, TC25, TC120, TC121, TC122, TC123, TC130, TC133, TC134 from the TDS - see Documentation

        NoOfAssemblyOrders := CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType));

        // Create the assembled item
        CreateAssembledItem(Item, AssemblyPolicy, LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        UOMCode := Item."Base Unit of Measure";
        LocationCode := '';
        VariantCode := '';

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item."No.", VariantCode, OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);

        // IF ATS then "transform" ATS into ATO item
        if AssemblyPolicy = "Assembly Policy"::"Assemble-to-Stock" then
            SetQtyToAssembleToOrder(SalesLine, OrderQty);

        // exercise - change field
        case ChangeOption of
            ChangeOption::Quantity:
                begin
                    OrderQty := OrderQty - 1;
                    SalesLine.Validate(Quantity, OrderQty);
                    SalesLine.Modify(true);
                end;
            ChangeOption::"Quantity to Assemble":
                begin
                    OrderQty := OrderQty - 1;
                    SetQtyToAssembleToOrder(SalesLine, OrderQty);
                end;
            ChangeOption::"Location Code":
                begin
                    LocationCode := LocationBlue.Code;
                    SalesLine.Validate("Location Code", LocationCode);
                    // When changing location code, the shipment date gets reseted so "redo" the shipment date
                    SalesLine.Validate("Shipment Date", DueDate);
                    SalesLine.Modify(true);
                end;
            ChangeOption::"Variant Code":
                begin
                    LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
                    VariantCode := ItemVariant.Code;
                    SalesLine.Validate("Variant Code", VariantCode);
                    SalesLine.Modify(true);
                end;
            ChangeOption::UOM:
                begin
                    LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
                    AddItemUOM(Item, LibraryRandom.RandInt(1000), UnitOfMeasure.Code);
                    UOMCode := UnitOfMeasure.Code;
                    SalesLine.Validate("Unit of Measure Code", UOMCode);
                    SalesLine.Modify(true);
                end;
            ChangeOption::"Due Date":
                begin
                    DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(3)) + 'D>', DueDate);
                    SalesLine.Validate("Shipment Date", DueDate);
                    SalesLine.Modify(true);
                end;
        end;

        // assert that sync was ok
        FindAssemblyHeader(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, VariantCode, LocationCode, DueDate,
          UOMCode, OrderQty);

        case AssertOption of
            // Assert Assembly order created
            AssertOption::Orders:
                begin
                    // Assert that 1 assembly order is created for the ATO items placed on sales order line
                    Assert.AreEqual(
                      NoOfAssemblyOrders + 1, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), OneAsmOrderCreateMsg);
                    // Verify - assembly order
                    AssertAsmOrderForDefaultBOM(
                      AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, VariantCode, LocationCode, DueDate,
                      UOMCode, OrderQty, 1);
                end;
            // Assert reservation entries
            AssertOption::Reservation:
                AssertReservationEntries(SalesLine, AssemblyHeader);
            // Assert hard link entry
            AssertOption::"Hard link":
                LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATONegativePostAOAlone()
    begin
        Initialize();
        TC136PostAOAlone('');
    end;

    local procedure TC136PostAOAlone(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        OrderQty: Integer;
        DueDate: Date;
    begin
        // TC136 from the TDS - see Documentation

        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);

        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', LocationCode, DueDate,
          Item."Base Unit of Measure", OrderQty);

        // Exercise & verify - try to post AO - error
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ERR_POST_AOT);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure ATOBatchPostAO()
    begin
        Initialize();
        TC137BatchPostAO('');
    end;

    local procedure TC137BatchPostAO(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeaderRegular: Record "Assembly Header";
        AssemblyHeaderATO: Record "Assembly Header";
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        OrderQty: Integer;
        DueDate: Date;
    begin
        // TC137 from the TDS - see Documentation

        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);
        FindAssemblyHeader(AssemblyHeaderATO, AssemblyHeader."Document Type"::Order, Item, '', LocationCode,
          DueDate, Item."Base Unit of Measure", OrderQty);

        // Create manually an AO for ATO item
        CreateAssemblyOrder(AssemblyHeaderRegular, Item, LocationCode, '', DueDate, OrderQty);
        AddInvNonDirectLocAllComponent(AssemblyHeaderRegular, 100);

        // Exercise - batch post AOs - for the ATO item
        Clear(AssemblyHeader);
        AssemblyHeader.SetRange("Item No.", Item."No.");
        LibraryAssembly.BatchPostAssemblyHeaders(AssemblyHeader, 0D, false, '');

        // Verify - only manually created AO is posted
        AssertNoAssemblyHeader(AssemblyHeaderRegular."Document Type", AssemblyHeaderRegular."No.");
        AssemblyHeaderATO.Get(AssemblyHeaderATO."Document Type", AssemblyHeaderATO."No.");
        Assert.AreEqual(0, AssemblyHeaderATO."Assembled Quantity", NoQtyPostedMsg);
        // [THEN] Notification about errors during posting

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeaderATO.RecordId);
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeaderRegular.RecordId);
        Clear(AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOShipSO()
    begin
        Initialize();
        TC145PostSO('');
    end;

    local procedure TC145PostSO(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
        OrderQty: Integer;
        DueDate: Date;
    begin
        // TC145 from the TDS - see Documentation

        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', LocationCode,
          DueDate, Item."Base Unit of Measure", OrderQty);
        CopyAsmLinesToTemp(AssemblyHeader, TempAssemblyLine);

        // Add enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 100);

        AssemblyHeader.UpdateUnitCost();

        // Exercise - post SOs
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify - AO is posted
        AssertNoAssemblyHeader(AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, OrderQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATOOrder()
    begin
        Initialize();
        TC119ATOChangetoATO('', "Sales Document Type"::Order, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATOReservationEntries()
    begin
        Initialize();
        TC119ATOChangetoATO('', "Sales Document Type"::Order, AssertOption::Reservation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATOCheckHardLink()
    begin
        Initialize();
        TC119ATOChangetoATO('', "Sales Document Type"::Order, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATOQuote()
    begin
        Initialize();
        TC119ATOChangetoATO('', "Sales Document Type"::Order, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATOCheckHardLinkQuote()
    begin
        Initialize();
        TC119ATOChangetoATO('', "Sales Document Type"::Order, AssertOption::"Hard link");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATOBlanketOrder()
    begin
        Initialize();
        TC119ATOChangetoATO('', "Sales Document Type"::Order, AssertOption::Orders);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOToATOCheckHardLinkBlanketO()
    begin
        Initialize();
        TC119ATOChangetoATO('', "Sales Document Type"::Order, AssertOption::"Hard link");
    end;

    local procedure TC119ATOChangetoATO(LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type"; AssertOption: Option Orders,Reservation,"Hard link")
    var
        ItemATO1: Record Item;
        ItemATO2: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        DueDate: Date;
        NoOfAssemblyOrders: Integer;
    begin
        // TC119 from the TDS - see Documentation

        // Create the "assembled" Items
        CreateAssembledItem(ItemATO1, ItemATO1."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          ItemATO1."Costing Method"::FIFO);
        CreateAssembledItem(ItemATO2, ItemATO2."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          ItemATO2."Costing Method"::FIFO);

        NoOfAssemblyOrders := CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType));

        // Exercise - create SOL with first ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, ItemATO1."No.", '', OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);

        // Assert that one assembly order is created for the ATO item placed on sales order lines
        Assert.AreEqual(NoOfAssemblyOrders + 1, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)),
          'One new Assembly Order should be created');

        // Exercise - Change item to second ATO item
        SalesLine.Validate("Qty. to Assemble to Order", 0);
        SalesLine.Validate("No.", ItemATO2."No.");
        // Shipment date gets "reseted" when changing item no
        SalesLine.Validate("Shipment Date", DueDate);
        SalesLine.Modify(true);

        // Assert that after switch entries are updated as per second ATO item
        FindAssemblyHeader(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), ItemATO2, '', LocationCode, DueDate,
          ItemATO2."Base Unit of Measure", OrderQty);

        case AssertOption of
            // Assert Assembly order created
            AssertOption::Orders:
                begin
                    // Assert that no new assembly order is created comparing to previous step
                    Assert.AreEqual(NoOfAssemblyOrders + 1, CountAssemblyOrders(GetAsmTypeForSalesType(SalesDocumentType)), AsmOrderReUsedMsg);
                    // Verify - assembly order
                    AssertAsmOrderForDefaultBOM(AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), ItemATO2, '', LocationCode, DueDate,
                      ItemATO2."Base Unit of Measure", OrderQty, 1);
                end;
            // Assert reservation entries
            AssertOption::Reservation:
                AssertReservationEntries(SalesLine, AssemblyHeader);
            // Assert hard link entry
            AssertOption::"Hard link":
                LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 1);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandlerPostedAOs(Msg: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure LocationCodeConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MSG_UPDATE) > 0, Question);

        Reply := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOShipSONotEnoughComp()
    begin
        Initialize();
        TC146PostSONotEnoughComp('');
    end;

    local procedure TC146PostSONotEnoughComp(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        DueDate: Date;
    begin
        // TC146 from the TDS - see Documentation

        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', LocationCode,
          DueDate, Item."Base Unit of Measure", OrderQty);

        // Add not enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 50);

        // Exercise - post SOs and see it doesn't post
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(ERR_NOT_ENOUGH);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOPostFullSO2Steps()
    begin
        Initialize();
        TCPostFullSO2Steps('');
    end;

    local procedure TCPostFullSO2Steps(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', LocationCode, DueDate,
          Item."Base Unit of Measure", OrderQty);
        FindSOL(SalesHeader, SalesLine, 1);

        // Add enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 100);

        // set order to be posted partially
        SalesLine.Validate("Qty. to Ship", OrderQty / 2);
        SalesLine.Modify(true);

        // Exercise - post
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // Refresh lines as posting is changing them
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");

        // Verify - AO is posted partially
        AssemblyHeader.TestField("Assembled Quantity", OrderQty / 2);
        AssemblyHeader.TestField("Remaining Quantity", OrderQty / 2);

        // post rest - before save lines to temp
        SalesLine.Validate("Qty. to Ship", OrderQty / 2);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify - AO is posted fully
        AssertNoAssemblyHeader(AssemblyHeader."Document Type", AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOPost2SOL2Steps()
    begin
        Initialize();
        TCPost2SOL2Steps('');
    end;

    local procedure TCPost2SOL2Steps(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create 2 SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);
        AddSalesOrderLine(SalesHeader, SalesLine, Item."No.", LocationCode, '', OrderQty, DueDate);

        // Verify 2 AOs created
        AssertAssemblyHeader(
          AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', LocationCode, DueDate, Item."Base Unit of Measure", OrderQty, 2);

        // Add enough inventory for comp for both AOs
        AddInvNonDirectLocAllComponent(AssemblyHeader, 200);

        // set order to be posted partially (1 line)
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);

        // Exercise - post SO
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // VERIFY: Exactly one Posted Assembly Headers for Item
        Clear(PostedAssemblyHeader);
        PostedAssemblyHeader.SetRange("Item No.", Item."No.");
        Assert.AreEqual(1, PostedAssemblyHeader.Count, OneAsmOrderPostedMsg);

        // post rest - 2nd line - first refetch sales line from DB as it changed during posting
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Ship", OrderQty);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify - AOs are posted
        Clear(PostedAssemblyHeader);
        PostedAssemblyHeader.SetRange("Item No.", Item."No.");
        Assert.AreEqual(2, PostedAssemblyHeader.Count, BothAsmOrdersPostedMsg);
    end;

    [Test]
    [HandlerFunctions('MsgHandlerPostedAOs')]
    [Scope('OnPrem')]
    procedure ATOBatchPostSO()
    begin
        Initialize();
        TCBatchPostSO('');
    end;

    local procedure TCBatchPostSO(LocationCode: Code[10])
    var
        ItemATO: Record Item;
        ItemATS: Record Item;
        RegularItem: Record Item;
        AssemblyHeader1: Record "Assembly Header";
        AssemblyHeader2: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempAssemblyLine1: Record "Assembly Line" temporary;
        TempAssemblyLine2: Record "Assembly Line" temporary;
        LibraryJobQueue: Codeunit "Library - Job Queue";
        OrderQty: Integer;
        DueDate: Date;
    begin
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreateAssembledItem(ItemATO, ItemATO."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          ItemATO."Costing Method"::FIFO);
        CreateAssembledItem(ItemATS, ItemATS."Assembly Policy"::"Assemble-to-Stock", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          ItemATS."Costing Method"::FIFO);
        LibraryInventory.CreateItem(RegularItem);

        // create SOs with ATO/ATS/Regular item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader1, ItemATS."No.", '', OrderQty, DueDate, LocationCode);
        AddSalesOrderLine(SalesHeader1, SalesLine, ItemATO."No.", LocationCode, '', OrderQty, DueDate);
        AddSalesOrderLine(SalesHeader1, SalesLine, RegularItem."No.", LocationCode, '', OrderQty, DueDate);
        CreateSalesOrder(SalesHeader2, ItemATS."No.", '', OrderQty, DueDate, LocationCode);
        AddSalesOrderLine(SalesHeader2, SalesLine, ItemATO."No.", LocationCode, '', OrderQty + 1, DueDate);
        AddSalesOrderLine(SalesHeader2, SalesLine, RegularItem."No.", LocationCode, '', OrderQty, DueDate);

        // Find created AOs
        FindAssemblyHeader(AssemblyHeader1, AssemblyHeader1."Document Type"::Order, ItemATO, '', LocationCode, DueDate,
          ItemATO."Base Unit of Measure", OrderQty);
        CopyAsmLinesToTemp(AssemblyHeader1, TempAssemblyLine1);
        FindAssemblyHeader(AssemblyHeader2, AssemblyHeader2."Document Type"::Order, ItemATO, '', LocationCode, DueDate,
          ItemATO."Base Unit of Measure", OrderQty + 1);
        CopyAsmLinesToTemp(AssemblyHeader2, TempAssemblyLine2);

        // Add enough inventory for components and regular item
        AddInvNonDirectLocAllComponent(AssemblyHeader1, 100);
        AddInvNonDirectLocAllComponent(AssemblyHeader2, 100);
        AddInventoryNonDirectLocation(RegularItem."No.", LocationCode, '', 3 * OrderQty);
        AddInventoryNonDirectLocation(ItemATS."No.", LocationCode, '', 3 * OrderQty);

        AssemblyHeader1.UpdateUnitCost();
        AssemblyHeader2.UpdateUnitCost();

        // Exercise - batch post SOs
        Clear(SalesHeader);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetFilter("No.", SalesHeader1."No." + '|' + SalesHeader2."No.");
        LibrarySales.BatchPostSalesHeaders(SalesHeader, true, true, 0D, false, false, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // Verify - SOs posted and invoiced - no SOs
        // No ATO headers - posted
        Commit();
        asserterror SalesHeader.Get(SalesHeader1."Document Type", SalesHeader1."No.");
        asserterror SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        AssertNoAssemblyHeader(AssemblyHeader1."Document Type", AssemblyHeader1."No.");
        AssertNoAssemblyHeader(AssemblyHeader2."Document Type", AssemblyHeader2."No.");
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine1, AssemblyHeader1, OrderQty);
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine2, AssemblyHeader2, OrderQty + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOPostSOVerifyEntries()
    begin
        Initialize();
        TCPostSOVerifyEntries('');
    end;

    local procedure TCPostSOVerifyEntries(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
        OrderQty: Integer;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          0, LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, LocationCode);
        FindSOL(SalesHeader, SalesLine, 1);
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', LocationCode,
          DueDate, Item."Base Unit of Measure", OrderQty);
        CopyAsmLinesToTemp(AssemblyHeader, TempAssemblyLine);

        // Add enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 100);

        // Exercise - post SOs
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify - entries
        LibraryAssembly.VerifyILEsForAsmOnATO(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyValueEntriesATO(TempAssemblyLine, SalesHeader, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyResEntriesATO(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyCapEntriesATO(TempAssemblyLine, AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMixVerifyEntries()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
        OrderQty: Integer;
        DueDate: Date;
    begin
        Initialize();

        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, '');
        FindSOL(SalesHeader, SalesLine, 1);
        // Make ATO mix with ATS
        SetQtyToAssembleToOrder(SalesLine, SalesLine.Quantity / 2);

        SalesLine.AsmToOrderExists(AssemblyHeader);
        CopyAsmLinesToTemp(AssemblyHeader, TempAssemblyLine);

        // Add enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 100);

        // Exercise - post SOs
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify - entries
        LibraryAssembly.VerifyILEsForAsmOnATO(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyResEntriesATO(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyCapEntriesATO(TempAssemblyLine, AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AOVerifyDates()
    begin
        Initialize();
        TCVerifyDates('');
    end;

    local procedure TCVerifyDates(LocationCode: Code[10])
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        OrderQty: Integer;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        ChangeLeadTimeOffsetOnCompList(Item."No.");

        // Exercise - create AO
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+100D>', WorkDate());
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, '', DueDate, OrderQty);

        // Verify
        AssertDatesOnAsmOrder(AssemblyHeader);
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOVerifyDates()
    begin
        Initialize();
        TCATOVerifyDates('', "Sales Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOVerifyDatesQuote()
    begin
        Initialize();
        TCATOVerifyDates('', "Sales Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOVerifyDatesBlanketOrder()
    begin
        Initialize();
        TCATOVerifyDates('', "Sales Document Type"::Order);
    end;

    local procedure TCATOVerifyDates(LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        OrderQty: Integer;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        ChangeLeadTimeOffsetOnCompList(Item."No.");

        // Exercise - create ATO
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+100D>', WorkDate());
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item."No.", '', OrderQty, DueDate, LocationCode);
        FindAssemblyHeader(
          AssemblyHeader, GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate, Item."Base Unit of Measure", OrderQty);

        // Verify
        AssertDatesOnAsmOrder(AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AOVerifyDatesWithVariantSKU()
    begin
        Initialize();
        TCVerifyDatesWithSKU('', "SKU Creation Method"::Variant);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AOVerifyDatesWithLocationSKU()
    begin
        Initialize();
        TCVerifyDatesWithSKU(LocationBlue.Code, "SKU Creation Method"::Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AOVerifyDatesWithLocAndVariantSKU()
    begin
        Initialize();
        TCVerifyDatesWithSKU(LocationBlue.Code, "SKU Creation Method"::"Location & Variant");
    end;

    local procedure TCVerifyDatesWithSKU(LocationCode: Code[10]; CreatePerOption: Enum "SKU Creation Method")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SKU: Record "Stockkeeping Unit";
        AssemblyHeader: Record "Assembly Header";
        OrderQty: Integer;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        if CreatePerOption <> CreatePerOption::Location then
            LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateStockKeepingUnit(Item, CreatePerOption, false, true);
        if not FindSKU(SKU, Item."No.", LocationCode, ItemVariant.Code) then
            Error(ERR_SKU_NOT_CREATED);
        ChangeLeadTimesOnSKU(SKU);
        ChangeLeadTimeOffsetOnCompList(Item."No.");

        // Exercise - create AO
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+100D>', WorkDate());
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, ItemVariant.Code, DueDate, OrderQty);

        // Verify
        AssertDatesOnAsmOrder(AssemblyHeader);
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('RollUpCostConfirm')]
    [Scope('OnPrem')]
    procedure ATORollupCost()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        QtyToAssembleToOrder: Integer;
        OrderQty: Integer;
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO 379342] Unit Cost in Sales Order Line after the RollupCost function is run should be calculated on Assembly Lines only.
        Initialize();

        // [GIVEN] Assembled Item with Assembly Policy = Assemble-to-Order.
        // [GIVEN] List of BOM Components with costs.
        // [GIVEN] Sales Order Line with Quantity > "Qty. Assemble to Order".
        QtyToAssembleToOrder := LibraryRandom.RandInt(1000);
        OrderQty := QtyToAssembleToOrder + LibraryRandom.RandInt(1000);
        CreateAssembledItemAndBOMComponentsWithUnitCostAndUnitPrice(Item);
        TCRollupCost(Item, SalesLine, AssemblyHeader, '', "Sales Document Type"::Order, QtyToAssembleToOrder, OrderQty);

        // [WHEN] Run Roll-up Cost function.
        LibraryAssembly.RollUpAsmCost(SalesLine);

        // [THEN] Unit Cost in Sales Line is nearly equal to Unit Cost of Assembled Item.
        Assert.AreNearlyEqual(
          SalesLine."Unit Cost", GetRollupCost(AssemblyHeader) / AssemblyHeader.Quantity, GLSetup."Unit-Amount Rounding Precision",
          StrSubstNo(WrongUnitValueMsg, SalesLine.FieldCaption("Unit Cost")));
    end;

    [Test]
    [HandlerFunctions('RollUpCostConfirm')]
    [Scope('OnPrem')]
    procedure ATORollupQuote()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        QtyToAssembleToOrder: Integer;
        OrderQty: Integer;
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 379342] Unit Cost in Sales Quote Line after the RollupCost function is run should be calculated on Assembly Lines only.
        Initialize();

        // [GIVEN] Assembled Item with Assembly Policy = Assemble-to-Order.
        // [GIVEN] List of BOM Components with costs.
        // [GIVEN] Sales Quote Line with Quantity = "Qty. Assemble to Order". Difference between Quantity and "Qty. Assemble to Order" in Sales Quote is not allowed by design.
        QtyToAssembleToOrder := LibraryRandom.RandInt(1000);
        OrderQty := QtyToAssembleToOrder;
        CreateAssembledItemAndBOMComponentsWithUnitCostAndUnitPrice(Item);
        TCRollupCost(Item, SalesLine, AssemblyHeader, '', "Sales Document Type"::Quote, QtyToAssembleToOrder, OrderQty);

        // [WHEN] Run Roll-up Cost function.
        LibraryAssembly.RollUpAsmCost(SalesLine);

        // [THEN] Unit Cost in Sales Line is nearly equal to Unit Cost of Assembled Item.
        Assert.AreNearlyEqual(
          SalesLine."Unit Cost", GetRollupCost(AssemblyHeader) / AssemblyHeader.Quantity, GLSetup."Unit-Amount Rounding Precision",
          StrSubstNo(WrongUnitValueMsg, SalesLine.FieldCaption("Unit Cost")));
    end;

    [Test]
    [HandlerFunctions('RollUpCostConfirm')]
    [Scope('OnPrem')]
    procedure ATORollupBlanket()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        QtyToAssembleToOrder: Integer;
        OrderQty: Integer;
    begin
        // [FEATURE] [Sales Blanket Order]
        // [SCENARIO 379342] Unit Cost in Sales Blanket Order Line after the RollupCost function is run should be calculated on Assembly Lines only.
        Initialize();

        // [GIVEN] Assembled Item with Assembly Policy = Assemble-to-Order.
        // [GIVEN] List of BOM Components with costs.
        // [GIVEN] Sales Blanket Order Line with Quantity = "Qty. Assemble to Order". Difference between Quantity and "Qty. Assemble to Order" in Sales Blanket Order is not allowed by design.
        QtyToAssembleToOrder := LibraryRandom.RandInt(1000);
        OrderQty := QtyToAssembleToOrder;
        CreateAssembledItemAndBOMComponentsWithUnitCostAndUnitPrice(Item);
        TCRollupCost(Item, SalesLine, AssemblyHeader, '', "Sales Document Type"::"Blanket Order", QtyToAssembleToOrder, OrderQty);

        // [WHEN] Run Roll-up Cost function.
        LibraryAssembly.RollUpAsmCost(SalesLine);

        // [THEN] Unit Cost in Sales Line is nearly equal to Unit Cost of Assembled Item.
        Assert.AreNearlyEqual(
          SalesLine."Unit Cost", GetRollupCost(AssemblyHeader) / AssemblyHeader.Quantity, GLSetup."Unit-Amount Rounding Precision",
          StrSubstNo(WrongUnitValueMsg, SalesLine.FieldCaption("Unit Cost")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ATORollupPrice()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        QtyToAssembleToOrder: Integer;
        OrderQty: Integer;
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO 379342] Unit Price in Sales Order Line after the RollupPrice function is run should be calculated on Assembly Lines only.
        Initialize();

        // [GIVEN] Assembled Item with Assembly Policy = Assemble-to-Order.
        // [GIVEN] List of BOM Components with Sales and Resource prices.
        // [GIVEN] Sales Order Line with Quantity > "Qty. Assemble to Order".
        QtyToAssembleToOrder := LibraryRandom.RandInt(1000);
        OrderQty := QtyToAssembleToOrder + LibraryRandom.RandInt(1000);
        CreateAssembledItemAndBOMComponentsWithUnitCostAndUnitPrice(Item);
        CreateSalesAndResourcePricesOnCompList(Item."No.");
        TCRollupCost(Item, SalesLine, AssemblyHeader, '', "Sales Document Type"::Order, QtyToAssembleToOrder, OrderQty);

        // [WHEN] Run Roll-up Price function.
        LibraryAssembly.RollUpAsmPrice(SalesLine);

        // [THEN] Unit Price in Sales Line is nearly equal to Unit Price of Assembled Item.
        Assert.AreNearlyEqual(
          SalesLine."Unit Price", GetRollupPrice(AssemblyHeader) / AssemblyHeader.Quantity, GLSetup."Unit-Amount Rounding Precision",
          StrSubstNo(WrongUnitValueMsg, SalesLine.FieldCaption("Unit Price")));
    end;

    local procedure TCRollupCost(var Item: Record Item; var SalesLine: Record "Sales Line"; var AssemblyHeader: Record "Assembly Header"; LocationCode: Code[10]; SalesDocumentType: Enum "Sales Document Type"; QtyToAssembleToOrder: Integer; OrderQty: Integer)
    var
        SalesHeader: Record "Sales Header";
        DueDate: Date;
    begin
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesDocumentType, Item."No.", '', OrderQty, DueDate, LocationCode);

        FindSOL(SalesHeader, SalesLine, 1);
        SalesLine.Validate("Qty. to Assemble to Order", QtyToAssembleToOrder);
        SalesLine.Modify(true);

        FindAssemblyHeader(
          AssemblyHeader,
          GetAsmTypeForSalesType(SalesDocumentType), Item, '', LocationCode, DueDate, Item."Base Unit of Measure", QtyToAssembleToOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AsmLinesOnSalesOrderMatchAsmLinesOnQuote()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        TempQuoteAssemblyLine: Record "Assembly Line" temporary;
        SalesOrderNo: Code[20];
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 380918] Modifications on Assembly Lines for Sales Quote on Location with "Require Shipment" = TRUE, are respected when a Sales Order is created from the Quote.
        Initialize();

        // [GIVEN] Location "L" with "Require Shipment" = TRUE.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        // [GIVEN] Sales Quote for Assembled Item on Location "L".
        // [GIVEN] The quantity of a component in the Assembly Line is changed, thus the Assembly does not match BOM.
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::Quote, Item, Location.Code);
        FindLinkedAssemblyOrder(AssemblyHeader, SalesHeader."Document Type", SalesHeader."No.");
        UpdateAssemblyLine(AssemblyHeader);
        CopyAsmLinesToTemp(AssemblyHeader, TempQuoteAssemblyLine);

        // [WHEN] Make Sales Order from the Sales Quote.
        SalesOrderNo := LibrarySales.QuoteMakeOrder(SalesHeader);

        // [THEN] Assembly Lines on the Order and the Quote are identical.
        VerifyAssemblyLinesSalesOrderAgainstQuote(SalesOrderNo, TempQuoteAssemblyLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMakeOrderQuoteCheckOrders()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedOrderNo: Code[20];
    begin
        // [SCENARIO] Correct Assembly Order is created when Sales Order made from Sales Quote
        Initialize();

        // [GIVEN] Create Quote with Assembled Item
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::Quote, Item, '');

        // [WHEN] Make Order from Quote
        ExpectedOrderNo := LibrarySales.QuoteMakeOrder(SalesHeader);

        // [THEN] Verify Assembly Order fields are copied from source Sales Line
        FindAsmHeaderFromSalesOrder(ExpectedOrderNo, Item, SalesLine, AssemblyHeader);
        AssertAsmOrderForDefaultBOM(
          AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', '', SalesLine."Shipment Date",
          Item."Base Unit of Measure", SalesLine.Quantity, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMakeOrderQuoteCheckReservation()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedOrderNo: Code[20];
    begin
        // [SCENARIO] Assembly Order and Sales Order made from Sales Quote share reservation
        Initialize();

        // [GIVEN] Create Quote with Assembled Item
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::Quote, Item, '');

        // [WHEN] Make Order from Quote
        ExpectedOrderNo := LibrarySales.QuoteMakeOrder(SalesHeader);

        // [THEN] Verify reservation entries
        FindAsmHeaderFromSalesOrder(ExpectedOrderNo, Item, SalesLine, AssemblyHeader);
        AssertReservationEntries(SalesLine, AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMakeOrderQuoteCheckHardLink()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedOrderNo: Code[20];
    begin
        // [SCENARIO] Assembly Order and Sales Order made from Sales Quote are linked
        Initialize();

        // [GIVEN] Create Quote with Assembled Item
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::Quote, Item, '');

        // [WHEN] Make Order from Quote
        ExpectedOrderNo := LibrarySales.QuoteMakeOrder(SalesHeader);

        // [THEN] Verify hard link between Sales Order and Assembly Order
        FindAsmHeaderFromSalesOrder(ExpectedOrderNo, Item, SalesLine, AssemblyHeader);
        LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMakeOrderBlanketOrderCheckOrders()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedOrderNo: Code[20];
    begin
        // [SCENARIO] Correct Assembly Order is created when Sales Order made from Blanket Sales Order
        Initialize();

        // [GIVEN] Create Blanket Order with Assembled Item
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Item, '');

        // [WHEN] Make Order from Blanket Order
        ExpectedOrderNo := LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [THEN] Verify Assembly order fields are copied from source Sales Line
        FindAsmHeaderFromSalesOrder(ExpectedOrderNo, Item, SalesLine, AssemblyHeader);
        AssertAsmOrderForDefaultBOM(
          AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', '', SalesLine."Shipment Date",
          Item."Base Unit of Measure", SalesLine.Quantity, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMakeOrderBlanketOrderCheckReservation()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedOrderNo: Code[20];
    begin
        // [SCENARIO] Assembly Order and Sales Order made from Blanket Sales Order share reservation
        Initialize();

        // [GIVEN] Create Blanket Order with Assembled Item
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Item, '');

        // [WHEN] Make Order from Blanket Order
        ExpectedOrderNo := LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [THEN] Verify reservation entries
        FindAsmHeaderFromSalesOrder(ExpectedOrderNo, Item, SalesLine, AssemblyHeader);
        AssertReservationEntries(SalesLine, AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOMakeOrderBlanketOrderCheckHardLink()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedOrderNo: Code[20];
    begin
        // [SCENARIO] Assembly Order and Sales Order made from Blanket Sales Order are linked
        Initialize();

        // [GIVEN] Create Blanket Order with Assembled Item
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Item, '');

        // [WHEN] Make Order from Blanket Order
        ExpectedOrderNo := LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [THEN] Verify hard link between Sales Order and Assembly Order
        FindAsmHeaderFromSalesOrder(ExpectedOrderNo, Item, SalesLine, AssemblyHeader);
        LibraryAssembly.VerifyHardLinkEntry(SalesLine, AssemblyHeader, 1);
    end;

    [Test]
    [HandlerFunctions('ExplodeBOMOptionDialog')]
    [Scope('OnPrem')]
    procedure BlanketAsmOrderUpdatedWhenShippedOrder()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesOrderHeader: Record "Sales Header";
        QtyToShip: Decimal;
    begin
        // [SCENARIO 359881.1] Blanket Assembly Order is updated when shipped Sales Order made from Blanket Sales Order
        Initialize();

        // [GIVEN] Make Order from Blanket Order with Assembled Item
        MakeOrderFromSalesBlanketOrder(Item, SalesOrderHeader);
        // [GIVEN] Decrease 'Quantity to Ship' to make partial shipment
        QtyToShip := DecreaseQtyToShipInAsmOrder(SalesOrderHeader, Item."No.", LibraryRandom.RandInt(5));

        // [WHEN] Partially Ship created Sales Order
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);

        // [THEN] Blanket Assembly Order Header and Lines (Remaining Quantity, Assembled/Consumed Quantity) are updated
        VerifyAssembledQtyOnAsmOrder(AssemblyHeader."Document Type"::"Blanket Order", Item."No.", QtyToShip);
    end;

    [Test]
    [HandlerFunctions('ExplodeBOMOptionDialog,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BlanketAsmOrderUpdatedWhenUndoShippedOrder()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesOrderHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        QtyToShip: Decimal;
    begin
        // [SCENARIO 359881.2] Blanket Assembly Order is updated when Undo the shipped Sales Order made from Blanket Sales Order
        Initialize();

        // [GIVEN] Make Order from Blanket Order with Assembled Item
        MakeOrderFromSalesBlanketOrder(Item, SalesOrderHeader);
        // [GIVEN] Partially Ship created Sales Order
        QtyToShip := DecreaseQtyToShipInAsmOrder(SalesOrderHeader, Item."No.", LibraryRandom.RandInt(5));
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);
        // [GIVEN] Fully Ship created Sales Order
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);

        // [WHEN] Undo the last shipment
        SalesShipmentLine.SetRange("Document No.", SalesOrderHeader."Last Shipping No.");
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] Blanket Assembly Order Header and Lines are in the state as if after first shipment
        VerifyAssembledQtyOnAsmOrder(AssemblyHeader."Document Type"::"Blanket Order", Item."No.", QtyToShip);
    end;

    local procedure DecreaseQtyToShipInAsmOrder(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Divider: Decimal): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity div Divider);
        SalesLine.Modify(true);
        exit(SalesLine."Qty. to Ship");
    end;

    local procedure FindAsmHeaderFromSalesOrder(SalesOrderNo: Code[20]; Item: Record Item; var SalesLine: Record "Sales Line"; var AssemblyHeader: Record "Assembly Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        FindSalesLine(SalesHeader, SalesLine, Item."No.");
        FindAssemblyHeader(
          AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', '',
          SalesLine."Shipment Date", Item."Base Unit of Measure", SalesLine.Quantity);
    end;

    local procedure MakeOrderFromSalesBlanketOrder(var Item: Record Item; var SalesOrderHeader: Record "Sales Header")
    var
        SalesHeader: Record "Sales Header";
        SalesOrderNo: Code[20];
    begin
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Item, '');
        PurchaseAssembledItem(Item, 1000);
        SalesOrderNo := LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);
        SalesOrderHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
    end;

    local procedure CreateSalesDocToMakeOrder(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; var Item: Record Item; LocationCode: Code[10])
    var
        OrderQty: Integer;
        DueDate: Date;
    begin
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        OrderQty := LibraryRandom.RandIntInRange(500, 1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, DocumentType, Item."No.", '', OrderQty, DueDate, LocationCode);
    end;

    local procedure PurchaseAssembledItem(Item: Record Item; Quantity: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJnlLine."Entry Type"::Purchase, Item."No.", Quantity);
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Explode BOM", ItemJnlLine);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure VerifyAssembledQtyOnAsmOrder(DocumentType: Enum "Assembly Document Type"; ItemNo: Code[20]; AssembledQty: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyHeader.SetRange("Document Type", DocumentType);
        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindLast();
        Assert.AreEqual(AssembledQty, AssemblyHeader."Assembled Quantity", AssemblyHeader.FieldName("Assembled Quantity"));
        Assert.AreEqual(
          AssembledQty * AssemblyHeader."Qty. per Unit of Measure",
          AssemblyHeader."Assembled Quantity (Base)", AssemblyHeader.FieldName("Assembled Quantity (Base)"));
        Assert.AreEqual(
          AssemblyHeader.Quantity - AssembledQty, AssemblyHeader."Remaining Quantity", AssemblyHeader.FieldName("Remaining Quantity"));
        Assert.AreEqual(
          AssemblyHeader."Quantity (Base)" - AssemblyHeader."Assembled Quantity (Base)",
          AssemblyHeader."Remaining Quantity (Base)", AssemblyHeader.FieldName("Remaining Quantity (Base)"));

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindSet();
        repeat
            Assert.AreEqual(
              AssembledQty * AssemblyLine."Quantity per", AssemblyLine."Consumed Quantity", AssemblyLine.FieldName("Consumed Quantity"));
            Assert.AreEqual(
              AssemblyLine."Consumed Quantity" * AssemblyLine."Qty. per Unit of Measure",
              AssemblyLine."Consumed Quantity (Base)", AssemblyLine.FieldName("Consumed Quantity (Base)"));
            Assert.AreEqual(
              AssemblyLine.Quantity - AssemblyLine."Quantity per" * AssembledQty, AssemblyLine."Remaining Quantity", AssemblyLine.FieldName("Remaining Quantity"));
            Assert.AreEqual(
              AssemblyLine."Quantity (Base)" - AssemblyLine."Consumed Quantity (Base)",
              AssemblyLine."Remaining Quantity (Base)", AssemblyLine.FieldName("Remaining Quantity (Base)"));
        until AssemblyLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ATOFixedApplication()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
        OrderQty: Integer;
        DueDate: Date;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, '');
        FindSOL(SalesHeader, SalesLine, 1);
        SalesLine.AsmToOrderExists(AssemblyHeader);
        CopyAsmLinesToTemp(AssemblyHeader, TempAssemblyLine);

        // Add enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 100);

        // Exercise - post SOs
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify - fixed application AO and SOL
        LibraryAssembly.VerifyILEATOAndSale(AssemblyHeader, SalesLine, OrderQty, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MixATOFixedApplication()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        DueDate: Date;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          0, LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, '');
        FindSOL(SalesHeader, SalesLine, 1);
        SalesLine.Validate("Qty. to Assemble to Order", OrderQty / 2);
        SalesLine.Validate("Qty. to Ship", OrderQty / 2);
        SalesLine.Modify(true);
        SalesLine.AsmToOrderExists(AssemblyHeader);

        // Add enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 100);

        // Exercise - post SOs - ATO first and ATS after
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify - fixed application AO and SOL
        LibraryAssembly.VerifyILEATOAndSale(AssemblyHeader, SalesLine, OrderQty / 2, false, 1);

        // post the rest - ATS
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        FindSOL(SalesHeader, SalesLine, 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify - ATS sale
        LibraryCosting.CheckAdjustment(Item);
        LibraryAssembly.VerifyILESale(SalesLine, OrderQty / 2, 0, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MixATOPartialShipAndInvoice()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Integer;
        i: Integer;
    begin
        Initialize();
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          0, LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandInt(1000) * 3;
        CreateSalesOrder(
          SalesHeader, Item."No.", '', OrderQty, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2), '');
        FindSOL(SalesHeader, SalesLine, 1);
        SalesLine.AsmToOrderExists(AssemblyHeader);

        // Add enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 100);

        // ATO is 1/2 and post ship in 4 partial posts
        SetQtyToAssembleToOrder(SalesLine, OrderQty / 2);

        for i := 1 to 3 do begin
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
            SalesLine.Validate("Qty. to Ship", OrderQty / 3);
            SalesLine.Modify(true);
            // Exercise - post SOs - ATO first and ATS after
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        // Verify - ATO post separatelly
        LibraryAssembly.VerifyILEATOAndSale(AssemblyHeader, SalesLine, OrderQty / 3, false, 1);
        LibraryAssembly.VerifyILEATOAndSale(AssemblyHeader, SalesLine, OrderQty / 6, false, 1);
        LibraryAssembly.VerifyILESale(SalesLine, OrderQty / 6, 0, false, false);
        LibraryAssembly.VerifyILESale(SalesLine, OrderQty / 3, 0, false, false);

        // Post invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Verify - after invoice
        LibraryCosting.CheckAdjustment(Item);
        LibraryAssembly.VerifyILEATOAndSale(AssemblyHeader, SalesLine, OrderQty / 3, true, 1);
        LibraryAssembly.VerifyILEATOAndSale(AssemblyHeader, SalesLine, OrderQty / 6, true, 1);
        LibraryAssembly.VerifyILESale(SalesLine, OrderQty / 6, 0, false, true);
        LibraryAssembly.VerifyILESale(SalesLine, OrderQty / 3, 0, false, true);
    end;

    local procedure TFS341553(CostingMethod: Enum "Costing Method")
    var
        InventorySetup: Record "Inventory Setup";
        BOMComponent: Record "BOM Component";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        CompItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        OrderQty: Integer;
        DueDate: Date;
    begin
        // TFS: 341553 - [NAV 2013] Item Charge cost not rolling up to Assembly BOM
        Initialize();
        InventorySetup.Get();
        Message(''); // cover for unexpected messages from inventory setup update.
        LibraryInventory.UpdateInventorySetup(InventorySetup,
          InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Setup.
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", 1, 0, 0, 1, CostingMethod);

        // Exercise - create SOL with ATO item
        OrderQty := LibraryRandom.RandIntInRange(5, 100);
        DueDate := WorkDate2 + LibraryRandom.RandIntInRange(1, 30);
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, '');
        FindSOL(SalesHeader, SalesLine, 1);
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', '',
          DueDate, Item."Base Unit of Measure", OrderQty);

        // Add inventory for comp.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        if AssemblyLine.FindSet() then
            repeat
                LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
                  AssemblyLine."No.", 2 * AssemblyLine.Quantity);
                PurchaseLine.Validate("Unit Cost (LCY)", LibraryRandom.RandDec(100, 2));
                PurchaseLine.Modify(true);
            until AssemblyLine.Next() = 0;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchRcptHeader.FindLast();

        // Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Add charge to the purchase.
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        if PurchRcptLine.FindSet() then
            repeat
                LibraryPurchase.AssignPurchChargeToPurchRcptLine(
                    PurchaseHeader, PurchRcptLine, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
            until PurchRcptLine.Next() = 0;

        // Exercise - post the charges.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Adjustment.
        LibraryCosting.CheckAdjustment(Item);
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        if BOMComponent.FindSet() then
            repeat
                CompItem.Get(BOMComponent."No.");
                LibraryCosting.CheckAdjustment(CompItem);
            until BOMComponent.Next() = 0;

        // Appendix: Perform ATS afterwards.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', OrderQty, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        CreateSalesOrder(SalesHeader, Item."No.", '', OrderQty, DueDate, '');
        FindSOL(SalesHeader, SalesLine, 1);
        SetQtyToAssembleToOrder(SalesLine, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Check adjustment.
        LibraryCosting.CheckAdjustment(Item);

        // Teardown.
        LibraryInventory.UpdateInventorySetup(InventorySetup,
          InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TFS341553_FIFO()
    var
        Item: Record Item;
    begin
        TFS341553(Item."Costing Method"::FIFO);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TFS341553_LIFO()
    var
        Item: Record Item;
    begin
        TFS341553(Item."Costing Method"::LIFO);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TFS341553_Average()
    var
        Item: Record Item;
    begin
        TFS341553(Item."Costing Method"::Average);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TFS341553_Std()
    var
        Item: Record Item;
    begin
        TFS341553(Item."Costing Method"::Standard);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure PostShippedSalesOrderAsInvoiceCheckAutomaticCostPosting()
    begin
        // Test shipped Sales Order can be posted as Invoice with Automatic Cost Posting checked.
        Initialize();
        PostShippedSalesOrderAsInvoice(true);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure PostShippedSalesOrderAsInvoiceUncheckAutomaticCostPosting()
    begin
        // Test shipped Sales Order can be posted as Invoice with Automatic Cost Posting unchecked.
        Initialize();
        PostShippedSalesOrderAsInvoice(false);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ItemTrackingLinesHandler,EnterQtyHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure PostSalerOrderAsShipWithSNItemTracking()
    var
        AssembledItem: Record Item;
        SalesHeader: Record "Sales Header";
        LocationCode: Code[10];
        OrderNo: Code[20];
        OrderQty: Decimal;
    begin
        Initialize();
        LocationCode := SetupBinLocationInAssemblySetup();
        CreateATOItemWithSNTracking(AssembledItem);
        SetupSNTrackingAndDefaultBinContent(LocationCode, AssembledItem);

        OrderQty := LibraryRandom.RandIntInRange(5, 10);
        CreateSalesOrder(SalesHeader, AssembledItem."No.", '', OrderQty, WorkDate(), LocationCode);
        OrderNo := SetupInventoryAndTrackingForAssemblyOrder(AssembledItem, LocationCode, OrderQty);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        VerifyWhseEntriesOfAssembly(OrderNo, OrderQty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure VerifyCorrectBinATOSalesOrder()
    var
        AssembledItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        LocationCode: Code[10];
        BinCodes: array[3] of Code[20];
        TakeBinCode: Code[20];
        OrderQty: Decimal;
    begin
        // Verify that Assembly components cannot be Taken twice if Bin is empty after first Take.

        // Setup.
        Initialize();
        LocationCode := SetupBinLocationInAssemblySetup();
        SetupBinsForLocation(LocationCode, BinCodes);
        SetupToAssemblyBin(LocationCode, BinCodes[ArrayLen(BinCodes)]);

        CreateAssembledItem(
          AssembledItem, "Assembly Policy"::"Assemble-to-Order", 1, 0, 0, 1, AssembledItem."Costing Method"::FIFO);

        OrderQty := LibraryRandom.RandIntInRange(5, 10);
        PlaceComponentsToBins(AssembledItem."No.", LocationCode, BinCodes, 1, ArrayLen(BinCodes) - 1, OrderQty);

        // Exercise.
        CreateSalesOrderAndAssemblyAndPick(AssemblyHeader, 1, AssembledItem."No.", OrderQty, LocationCode);
        TakeBinCode := GetPickTakeBinCode(AssemblyHeader."Document Type", AssemblyHeader."No.");
        CreateSalesOrderAndAssemblyAndPick(AssemblyHeader, 2, AssembledItem."No.", OrderQty, LocationCode);

        // Verify.
        Assert.AreNotEqual(
          TakeBinCode, GetPickTakeBinCode(AssemblyHeader."Document Type", AssemblyHeader."No."), WrongTakeBinErr);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrdersFromSalesLineWithChangedLineNo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Assembly] [Assembly to Order] [Sales Order]
        // [SCENARIO 378720] Validating "Sell-to Customer No." in Sales Header should not lead to duplicating Assembly Orders
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // [GIVEN] Assembled Item
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(10),
          Item."Costing Method"::FIFO);

        // [GIVEN] Sales Header for Customer "C1" with two lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line "L1" with "Line No." = "N1" and Assembly Order for that line
        CreateSalesLineWithLineNo(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(5001, 10000));

        // [GIVEN] Sales Line "L2" with "Line No." = "N2", "N2" < "N1" and Assembly Order for that line
        CreateSalesLineWithLineNo(SalesHeader, Item."No.", LibraryRandom.RandInt(5000));

        // [WHEN] Set "Sell-to Customer No." on Sales Header to "C2"
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] No additional Assembly Orders are created
        AssemblyHeader.SetRange("Item No.", Item."No.");
        Assert.AreEqual(2, AssemblyHeader.Count, AssemblyOrderCountErr);
    end;

    local procedure CreateSalesLineWithLineNo(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Insert(true);

        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Validate(Quantity, LibraryRandom.RandInt(10));
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure PostShippedSalesOrderAsInvoice(AutomaticCostPosting: Boolean)
    var
        AssembledItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        OldAutomaticCostPosting: Boolean;
        OrderQty: Decimal;
    begin
        // Setup: Update Automatic Cost Posting in Inventory setup. Create Assembled Item.
        UpdateAutomaticCostPosting(OldAutomaticCostPosting, AutomaticCostPosting);
        CreateAssembledItemWithAssemblyPolicy(AssembledItem, "Assembly Policy"::"Assemble-to-Order");

        // Create Sales Order with two lines for Item and Assembled Item.
        OrderQty := LibraryRandom.RandInt(5);
        LibraryInventory.CreateItem(Item);
        CreateSalesOrderWithTwoLines(SalesHeader, AssembledItem."No.", Item."No.", '', OrderQty, WorkDate(), '');

        // Add inventory for components to allow posting.
        FindAssemblyHeader(
          AssemblyHeader, AssemblyHeader."Document Type"::Order, AssembledItem, '', '',
          WorkDate(), AssembledItem."Base Unit of Measure", OrderQty);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), LibraryRandom.RandDecInRange(5, 10, 2));

        LibrarySales.PostSalesDocument(SalesHeader, true, false); // Post sales order as Ship.

        // Exercise & Verify: Sales order can be posted as invoice after shipped.
        LibrarySales.PostSalesDocument(SalesHeader, false, true); // Post as Invoice.

        // Tear down: Rollback modified Setup.
        UpdateAutomaticCostPosting(OldAutomaticCostPosting, OldAutomaticCostPosting);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ATOLinesPageHandler(var AssembleToOrderLines: TestPage "Assemble-to-Order Lines")
    var
        Item: Record Item;
        AssemblyLine: Record "Assembly Line";
        QtyToConsume: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        QtyToConsume := LibraryRandom.RandInt(100);
        AddInventoryNonDirectLocation(Item."No.", '', '', QtyToConsume);

        AssembleToOrderLines.Last();
        AssembleToOrderLines.Type.SetValue(AssemblyLine.Type::Item);
        AssembleToOrderLines."No.".SetValue(Item."No.");
        AssembleToOrderLines.Quantity.SetValue(QtyToConsume);

        AssembleToOrderLines.ShowWarning.Invoke();
        AssembleToOrderLines.OK().Invoke();
    end;

    local procedure FindAssemblyLine(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    begin
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
    end;

    local procedure FindAssemblyComp(var CompItem: Record Item; AsmItem: Record Item)
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", AsmItem."No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.FindFirst();
        CompItem.Get(BOMComponent."No.");
    end;

    local procedure UpdateAssemblyLine(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        FindAssemblyLine(AssemblyHeader, AssemblyLine);
        AssemblyLine.Validate("Quantity per", AssemblyLine."Quantity per" + LibraryRandom.RandInt(10));
        AssemblyLine.Modify(true);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure UpdatedQtyInAssemblyHeaderPropagatesToLines()
    var
        AssemblyItem: Record Item;
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TotalQty: Decimal;
        PartialQty: Decimal;
    begin
        // Sicily VSTF 1
        Initialize();

        // Setup: Create assembly item (Assembly BOM = 1 child; qty-per = 1) and an assembly order for it
        CreateAssembledItem(AssemblyItem, "Assembly Policy"::"Assemble-to-Order", 1, LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5), 1, AssemblyItem."Costing Method"::FIFO);
        LibraryWarehouse.CreateLocation(Location);

        TotalQty := LibraryRandom.RandDecInRange(5, 10, 2);
        PartialQty := LibraryRandom.RandDecInRange(1, 4, 2);
        CreateAssemblyOrder(AssemblyHeader, AssemblyItem, Location.Code, '', WorkDate(), TotalQty);

        FindItemAssemblyHeader(AssemblyHeader, AssemblyItem."No.", 1);

        // Exercise & verify
        AssemblyHeader.Validate(Quantity, PartialQty);
        AssemblyHeader.Modify(true);
        FindAssemblyLine(AssemblyHeader, AssemblyLine);
        Assert.AreNearlyEqual(
          AssemblyLine."Quantity to Consume", PartialQty, GLSetup."Amount Rounding Precision", LowerQtysPropagatedMsg);

        AssemblyHeader.Validate(Quantity, TotalQty);
        AssemblyHeader.Modify(true);
        FindAssemblyLine(AssemblyHeader, AssemblyLine);
        Assert.AreNearlyEqual(
          AssemblyLine."Quantity to Consume", TotalQty, GLSetup."Amount Rounding Precision", GreaterQtysPropagatedMsg);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesLineSetQtyWithExistingLateShippedATO()
    var
        AssembledItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DueDate: Date;
        DaysBack: Integer;
    begin
        // [FEATURE] [Stockout Warning] [Requested Delivery Date] [Assembly to Order]
        // [SCENARIO] Assembly Order is not shifted after Quantity validation for a Sales Line with an Item being Assembled to a Sales Order with "Shipment Date" > "Promised Delivery Date".

        // [GIVEN] Stockout Warning set to TRUE, Assembled Item.
        Initialize();
        LibrarySales.SetStockoutWarning(true);
        CreateAssembledItemWithAssemblyPolicy(AssembledItem, "Assembly Policy"::"Assemble-to-Stock");

        // [GIVEN] Sales Order with Requested/Promised Delivery Date.
        // [GIVEN] The line with Shipment Date: "SD1" > Requested Delivery Date, set full quantity assemble to order.
        DaysBack := CreateSalesOrderATOWithDeliveryDate(SalesHeader, AssembledItem."No.");
        FindItemAssemblyHeader(AssemblyHeader, AssembledItem."No.", 1);
        DueDate := AssemblyHeader."Due Date";

        // [WHEN] Create second line with Shipment Date "SD2" < Requested Delivery Date.
        AddSalesOrderLineOnPage(SalesHeader, AssembledItem."No.", WorkDate() - DaysBack);

        // [THEN] Created successfully, Assembly Order has "Due Date" = "SD1".
        AssemblyHeader.Find();
        Assert.AreEqual(DueDate, AssemblyHeader."Due Date", AssemblyHeader.FieldCaption("Due Date"));

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ReservationHander')]
    [Scope('OnPrem')]
    procedure AssemblyOrderValidateDueDateFailsOnConflictingReservationDate()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyOrder: TestPage "Assembly Order";
        Qty: Decimal;
    begin
        // [FEATURE] [Assembly] [Reservation]
        // [SCENARIO 376780] Validation of Due Date in assembly order fails if the new date conflicts with existing reservation.

        Initialize();
        // [GIVEN] Item "I" with linked assembly list and "Assemble-to-Stock" replenishment
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Stock", 1, 0, 0, 1, Item."Costing Method"::Standard);

        // [GIVEN] Create sales order and assembly order for item "I", and reserve sales against assembly
        Qty := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', Qty, '');
        SalesLine.ShowReservation();

        // Date must be changed in a page, as validation relies on CurrFieldNo
        AssemblyOrder.OpenEdit();
        AssemblyOrder.GotoRecord(AssemblyHeader);

        // [WHEN] Change "Due Date" in assembly order
        asserterror AssemblyOrder."Due Date".SetValue(AssemblyOrder."Due Date".AsDate() + 1);

        // [THEN] Validation error: "The change leads to a date conflict with existing reservations"
        Assert.ExpectedErrorCode(TestValidationErrorTok);
        Assert.ExpectedError(ReservationConflictErr);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderDueDateNotChangedWhenValidatingUnrelatedSalesOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        SalesOrder: TestPage "Sales Order";
        OrderShipmentDate: Date;
    begin
        // [SCENARIO 376713] Validation of shipment date on sales order does not change due date on assembly orders linked to other sales orders

        Initialize();
        LibrarySales.SetStockoutWarning(true);

        // [GIVEN] Item "I" with assembly BOM
        LibrarySales.CreateCustomer(Customer);
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Stock", 1, 0, 0, 1, Item."Costing Method"::Standard);

        // [GIVEN] Create sales order "SO1" for item "I" and set "Qty. to Assemble to Order" to create a linked assembly order. Set requested delivery date to WorkDate() + 1 week
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Requested Delivery Date", CalcDate('<1W>', WorkDate()));
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SetQtyToAssembleToOrder(SalesLine, SalesLine.Quantity);

        OrderShipmentDate := SalesHeader."Shipment Date";
        FindLinkedAssemblyOrder(AssemblyHeader, SalesHeader."Document Type", SalesHeader."No.");

        // [GIVEN] Create sales order "SO2" with the same item and set requested delivery date = WorkDate() + 4 weeks
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Requested Delivery Date", CalcDate('<4W>', WorkDate()));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SetQtyToAssembleToOrder(SalesLine, SalesLine.Quantity);

        // [WHEN] Change shipment date on order "SO2"
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines."Shipment Date".SetValue(SalesLine."Shipment Date" - 1);

        // [THEN] Due date on the assembly order linked to "SO1" has not changed
        AssemblyHeader.Find();
        AssemblyHeader.TestField("Due Date", OrderShipmentDate);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ExplodeBOMOptionDialog')]
    [Scope('OnPrem')]
    procedure SalesOrderWithATOPreviewPosting()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
        NoOfItems: Integer;
        SalesQty: Decimal;
    begin
        // [FEATURE] [Assembly] [Assembly to Order] [Sales Order] [Preview Posting]
        // [SCENARIO 209211] Preview posting of Sales Order with assembled-to-order item should show a result page after it is completed. Posting No. and Status of the assembly order should not be changed.
        Initialize();

        // [GIVEN] Assembly-to-Order item "I" with "X" components.
        NoOfItems := LibraryRandom.RandIntInRange(2, 5);
        CreateAssembledItem(
          Item, "Assembly Policy"::"Assemble-to-Order", NoOfItems, 0, 0, LibraryRandom.RandInt(10),
          Item."Costing Method"::Standard);
        PurchaseAssembledItem(Item, LibraryRandom.RandIntInRange(20, 40));

        // [GIVEN] Sales order for "I".
        // [GIVEN] Assembly Order "ATO" is automatically created and linked to the sales line.
        SalesQty := LibraryRandom.RandInt(10);
        CreateSalesOrder(SalesHeader, Item."No.", '', SalesQty, WorkDate(), '');

        // [WHEN] Run preview posting of the sales order.
        Commit();
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);

        // [THEN] Empty error is thrown.
        Assert.ExpectedError('');

        // [THEN] Posting preview result page shows ("X" + 2) item ledger entries, these are "X" consumed components, 1 assembled item, 1 sold item.
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Item Ledger Entry"));
        GLPostingPreview."No. of Records".AssertEquals(NoOfItems + 2);

        // [THEN] "ATO"."Posting No." = ''.
        // [THEN] "ATO".Status = "Open".
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, Item, '', '', WorkDate(),
          Item."Base Unit of Measure", SalesQty);
        AssemblyHeader.TestField("Posting No.", '');
        AssemblyHeader.TestField(Status, AssemblyHeader.Status::Open);
    end;

    [Test]
    [HandlerFunctions('MsgHandlerPostedAOs')]
    [Scope('OnPrem')]
    procedure CorrectQtyByGetPostedAsmLinesForDocumentFunc()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: array[2] of Record "Sales Invoice Line";
        PostedAssemblyLine: Record "Posted Assembly Line";
        ValueEntry: Record "Value Entry";
        TempPostedAssemblyLine: Record "Posted Assembly Line" temporary;
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Assemble-to-Order]
        // [SCENARIO 345339] Function "GetAssemblyLinesForDocument" returns correct posted assembly quantity when there are several value entries for an item entry.
        Initialize();

        // [GIVEN] Assemble-to-order item "A" with component "C". Qty. per = 1.
        CreateAssembledItem(AsmItem, "Assembly Policy"::"Assemble-to-Order", 1, 0, 0, 1, AsmItem."Costing Method"::FIFO);
        FindAssemblyComp(CompItem, AsmItem);

        // [GIVEN] Do the following twice.
        for i := 1 to ArrayLen(SalesInvoiceLine) do begin
            Qty := LibraryRandom.RandIntInRange(10, 20);

            // [GIVEN] Post purchase receipt for the component "C".
            LibraryPurchase.CreatePurchaseDocumentWithItem(
              PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', CompItem."No.", Qty, '', WorkDate());
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

            // [GIVEN] Sales order for "A" with linked assembly-to-order.
            // [GIVEN] Ship and invoice the sales order.
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', AsmItem."No.", Qty, '', WorkDate());
            LibrarySales.PostSalesDocument(SalesHeader, true, true);

            // [GIVEN] Find sales invoice line. "SIL1" on the first run, "SIL2" on the second run.
            SalesInvoiceLine[i].SetRange(Type, SalesInvoiceLine[i].Type::Item);
            SalesInvoiceLine[i].SetRange("No.", AsmItem."No.");
            SalesInvoiceLine[i].FindFirst();

            // [GIVEN] Post purchase invoice for the component "C".
            // [GIVEN] This is required so there will be two value entries for the sales invoice after the cost adjustment.
            PurchaseLine.Find();
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
            PurchaseLine.Modify(true);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        end;

        // [GIVEN] Run the cost adjustment for both "A" and "C".
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', AsmItem."No.", CompItem."No."), '');

        for i := 1 to ArrayLen(SalesInvoiceLine) do begin
            // [WHEN] Get posted assembly lines using "GeetAssemblyLinesForDocument" function run for "SIL1" and "SIL2" successively.
            PostedAssemblyLine.GetAssemblyLinesForDocument(
              TempPostedAssemblyLine, ValueEntry."Document Type"::"Sales Invoice",
              SalesInvoiceLine[i]."Document No.", SalesInvoiceLine[i]."Line No.");

            // [THEN] The function returns posted assembly line with quantity matching the correspondent sales invoice line.
            TempPostedAssemblyLine.FindFirst();
            TempPostedAssemblyLine.TestField("No.", CompItem."No.");
            TempPostedAssemblyLine.TestField(Quantity, SalesInvoiceLine[i].Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure UsingSelectItemsCreatesATO()
    var
        ATOItem: Record Item;
        ATSItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Select Items]
        // [SCENARIO 365390] Using "Select Items" on sales order subform page creates a linked assemble-to-order when needed.
        Initialize();

        // [GIVEN] Enable "Default Item Quantity" on the Sales Setup.
        SetItemDefaultQtyOnSalesSetup(true);
        LibraryAssembly.SetStockoutWarning(false);

        // [GIVEN] Assemble-to-order item "ATO" and assemble-to-stock item "ATS".
        CreateAssembledItemWithAssemblyPolicy(ATOItem, ATOItem."Assembly Policy"::"Assemble-to-Order");
        CreateAssembledItemWithAssemblyPolicy(ATSItem, ATSItem."Assembly Policy"::"Assemble-to-Stock");

        // [GIVEN] Sales order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] Consequently create sales lines for "ATO" and "ATS" items using "Select Items".
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        LibraryVariableStorage.Enqueue(ATOItem."No.");
        SalesLine.SelectMultipleItems();
        LibraryVariableStorage.Enqueue(ATSItem."No.");
        SalesLine.SelectMultipleItems();

        // [THEN] A linked assemble-to-order has been created for item "ATO".
        SalesLine.SetAutoCalcFields("Reserved Quantity");
        FindSalesLine(SalesHeader, SalesLine, ATOItem."No.");
        SalesLine.TestField("Qty. to Assemble to Order", 1);
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'Assemble-to-order has not been created.');
        SalesLine.TestField("Reserved Quantity", 1);

        // [THEN] No assemble-to-order has been created for item "ATS".
        FindSalesLine(SalesHeader, SalesLine, ATSItem."No.");
        SalesLine.TestField("Qty. to Assemble to Order", 0);
        Assert.IsFalse(SalesLine.AsmToOrderExists(AssemblyHeader), 'Assemble-to-order has been created.');
        SalesLine.TestField("Reserved Quantity", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure SetQtyToAssembleToOrder(var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        SalesLine.Validate("Qty. to Assemble to Order", Quantity);
        SalesLine.Modify(true);
    end;

    local procedure SetupToAssemblyBin(LocationCode: Code[10]; BinCode: Code[20])
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location."To-Assembly Bin Code" := BinCode;
        Location.Modify();
    end;

    local procedure SetupBinsForLocation(LocationCode: Code[10]; var BinCodes: array[3] of Code[20])
    var
        Bin: Record Bin;
        Counter: Integer;
    begin
        PrepareLocationForBins(LocationCode);
        for Counter := 1 to ArrayLen(BinCodes) do begin
            BinCodes[Counter] := LibraryUtility.GenerateGUID();
            LibraryWarehouse.CreateBin(Bin, LocationCode, BinCodes[Counter], '', '');
        end;
    end;

    local procedure PrepareLocationForBins(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Inventory Put-away");
        Location.Validate("Job Consump. Whse. Handling", Location."Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Validate("Asm. Consump. Whse. Handling", Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Modify();
    end;

    local procedure PlaceComponentsToBins(ParentItemNo: Code[20]; LocationCode: Code[10]; BinCodes: array[3] of Code[20]; FromBinIndex: Integer; ToBinIndex: Integer; Qty: Decimal)
    var
        BOMComponent: Record "BOM Component";
        ItemNo: Code[20];
        Counter: Integer;
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.FindFirst();
        ItemNo := BOMComponent."No.";

        for Counter := FromBinIndex to ToBinIndex do
            PostPositiveAdjmtOnBin(ItemNo, LocationCode, BinCodes[Counter], Qty);
    end;

    local procedure GetPickTakeBinCode(AssemblyType: Enum "Assembly Document Type"; AssemblyNo: Code[20]): Code[20]
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WarehouseActivityLine.SetRange("Source Subtype", AssemblyType);
        WarehouseActivityLine.SetRange("Source No.", AssemblyNo);
        WarehouseActivityLine.FindFirst();
        exit(WarehouseActivityLine."Bin Code");
    end;

    local procedure CreateSalesOrderAndAssemblyAndPick(var AssemblyHeader: Record "Assembly Header"; ExpectedIndex: Integer; AssembledItemNo: Code[20]; OrderQty: Decimal; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, AssembledItemNo, '', OrderQty, WorkDate(), LocationCode);
        FindItemAssemblyHeader(AssemblyHeader, AssembledItemNo, ExpectedIndex);
        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
        AssemblyHeader.CreatePick(false, UserId, 0, false, false, false);
    end;

    local procedure CreateSalesOrderATOWithDeliveryDate(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]) DaysBack: Integer
    var
        SalesLine: Record "Sales Line";
    begin
        DaysBack := LibraryRandom.RandIntInRange(10, 20);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationBlue.Code);
        SalesHeader.Validate("Requested Delivery Date", WorkDate() - DaysBack);
        SalesHeader.Validate("Promised Delivery Date", WorkDate() - DaysBack);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, WorkDate() - (DaysBack - 1),
          LibraryRandom.RandIntInRange(100, 1000));
        SetQtyToAssembleToOrder(SalesLine, SalesLine.Quantity);
        DaysBack += 1;
    end;

    local procedure AddSalesOrderLineOnPage(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
        SalesOrderPage: TestPage "Sales Order";
    begin
        SalesOrderPage.Trap();
        SalesOrderPage.OpenEdit();
        SalesOrderPage.GotoRecord(SalesHeader);
        SalesOrderPage.SalesLines.New();
        SalesOrderPage.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesOrderPage.SalesLines."No.".SetValue(ItemNo);
        SalesOrderPage.SalesLines."Shipment Date".SetValue(ShipmentDate);
        SalesOrderPage.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(100, 1000));
        SalesOrderPage.Close();
    end;

    local procedure CreateAssembledItemAndBOMComponentsWithUnitCostAndUnitPrice(var Item: Record Item)
    begin
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000),
          Item."Costing Method"::FIFO);
        ChangeCostAndPriceOnCompList(Item."No.");
    end;

    local procedure CreateSalesAndResourcePricesOnCompList(ItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
        SalesPrice: Record "Sales Price";
        ResourcePrice: Record "Resource Price";
        PriceListLine: Record "Price List Line";
    begin
        BOMComponent.SetRange("Parent Item No.", ItemNo);
        BOMComponent.FindSet();

        repeat
            case BOMComponent.Type of
                BOMComponent.Type::Item:
                    CreateSalesPrice(BOMComponent."No.");
                BOMComponent.Type::Resource:
                    CreateResourcePrice(BOMComponent."No.");
            end;
        until BOMComponent.Next() = 0;
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(ResourcePrice, PriceListLine);
    end;

    local procedure GetSalesPrice(ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        TempSalesPrice: Record "Sales Price" temporary;
        SalesPriceCalcMgt: Codeunit "Sales Price Calc. Mgt.";
    begin
        SalesPriceCalcMgt.FindSalesPrice(TempSalesPrice, '', '', '', '', ItemNo, VariantCode, '', '', WorkDate(), false);
        exit(TempSalesPrice."Unit Price");
    end;

    local procedure CreateSalesPrice(ItemNo: Code[20])
    var
        SalesPrice: Record "Sales Price";
    begin
        LibraryCosting.CreateSalesPrice(
          SalesPrice, "Sales Price Type"::"All Customers", '', ItemNo, WorkDate(), '', '', '', 0);
        SalesPrice.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesPrice.Modify(true);
    end;

    local procedure GetResourcePrice(ResourceNo: Code[20]): Decimal
    var
        ResourcePrice: Record "Resource Price";
    begin
        ResourcePrice.Code := ResourceNo;
        CODEUNIT.Run(CODEUNIT::"Resource-Find Price", ResourcePrice);
        exit(ResourcePrice."Unit Price");
    end;

    local procedure CreateResourcePrice(ResourceNo: Code[20])
    var
        ResourcePrice: Record "Resource Price";
    begin
        LibraryResource.CreateResourcePrice(ResourcePrice, ResourcePrice.Type::Resource, ResourceNo, '', '');
        ResourcePrice.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ResourcePrice.Modify(true);
    end;

    local procedure CheckGetAsmOrdersFromSalesHeader(SalesHeader: Record "Sales Header"; NoOfAsmOrders: Integer)
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        AssemblyOrders: TestPage "Assembly Orders";
        i: Integer;
    begin
        AssemblyOrders.Trap();
        AssembleToOrderLink.ShowAsmOrders(SalesHeader);
        AssemblyOrders.First();
        i := 1;
        while AssemblyOrders.Next() do
            i += 1;
        Assert.AreEqual(NoOfAsmOrders, i, NumberAsmOrderFromSalesHeaderMsg);
    end;

    local procedure SetItemDefaultQtyOnSalesSetup(ItemDefQty: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Item Quantity", ItemDefQty);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateItemTrackingToExcludeNumberOfSerialNos(SourceType: Integer; SourceID: Code[20]; NoOfSerialNos: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
        i: Integer;
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source ID", SourceID);
        for i := 1 to NoOfSerialNos do begin
            ReservationEntry.Next();
            ReservationEntry."Qty. to Handle (Base)" := 0;
            ReservationEntry.Modify();
        end;
    end;

    local procedure VerifyItemLedgerEntryCategory(Item: Record Item; OrderNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Order No.", OrderNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item Category Code", Item."Item Category Code");
    end;

    local procedure VerifyWhseEntriesOfAssembly(AssemblyOrderNo: Code[20]; OrderQty: Decimal)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        PostedAssemblyHeader.SetRange("Order No.", AssemblyOrderNo);
        PostedAssemblyHeader.FindLast();
        VerifyAssemblyQtyOnWhseEntry(
          PostedAssemblyHeader."Item No.", DATABASE::"Assembly Header",
          WarehouseEntry."Source Document"::"Assembly Order", AssemblyOrderNo, OrderQty);

        PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
        PostedAssemblyLine.SetRange(Type, PostedAssemblyLine.Type::Item);
        PostedAssemblyLine.FindSet();
        repeat
            VerifyAssemblyQtyOnWhseEntry(
              PostedAssemblyLine."No.", DATABASE::"Assembly Line",
              WarehouseEntry."Source Document"::"Assembly Consumption", AssemblyOrderNo, -OrderQty);
        until PostedAssemblyLine.Next() = 0;
    end;

    local procedure VerifyAssemblyQtyOnWhseEntry(ItemNo: Code[20]; SourceType: Integer; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; OrderQty: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
        TotalQty: Decimal;
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Source Type", SourceType);
        WarehouseEntry.SetRange("Source Document", SourceDocument);
        WarehouseEntry.SetRange("Source No.", SourceNo);
        WarehouseEntry.FindSet();
        repeat
            TotalQty += WarehouseEntry.Quantity;
        until WarehouseEntry.Next() = 0;
        Assert.AreEqual(OrderQty, TotalQty, StrSubstNo(WrongWhseQtyErr, SourceNo));
    end;

    local procedure VerifyAssemblyLinesSalesOrderAgainstQuote(SalesOrderNo: Code[20]; var TempQuoteAssemblyLine: Record "Assembly Line" temporary)
    var
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        FindLinkedAssemblyOrder(AssemblyHeader, SalesHeader."Document Type"::Order, SalesOrderNo);
        FindAssemblyLine(AssemblyHeader, AssemblyLine);

        Assert.AreEqual(TempQuoteAssemblyLine.Count, AssemblyLine.Count, DifferentNumberAsmLinesInOrderAndQuoteErr);
        TempQuoteAssemblyLine.FindSet();
        repeat
            AssemblyLine.TestField("Line No.", TempQuoteAssemblyLine."Line No.");
            AssemblyLine.TestField(Type, TempQuoteAssemblyLine.Type);
            AssemblyLine.TestField("No.", TempQuoteAssemblyLine."No.");
            AssemblyLine.TestField("Quantity per", TempQuoteAssemblyLine."Quantity per");
            AssemblyLine.TestField(Quantity, TempQuoteAssemblyLine.Quantity);
            AssemblyLine.TestField("Remaining Quantity", TempQuoteAssemblyLine."Remaining Quantity");
        until (AssemblyLine.Next() = 0) and (TempQuoteAssemblyLine.Next() = 0);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
    end;

    [Test]
    [HandlerFunctions('TFS6766_ATOLinesPageHandlerQuotesNoWarning')]
    [Scope('OnPrem')]
    procedure TFS6766_NoAvailabilityWarningOnQuote()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        OrderQty: Integer;
        DueDate: Date;
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);

        // create sales quote
        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        CreateSaleLineWithShptDate(SalesHeader, SalesHeader."Document Type"::Quote, Item."No.", '', OrderQty, DueDate, '');
        FindSOL(SalesHeader, SalesLine, 1);
        SetQtyToAssembleToOrder(SalesLine, OrderQty);

        // open Sales Quote
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        SalesQuote.SalesLines.Last();
        SalesQuote.SalesLines."Qty. to Assemble to Order".DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TFS6766_ATOLinesPageHandlerQuotesNoWarning(var AssembleToOrderLines: TestPage "Assemble-to-Order Lines")
    var
        Item: Record Item;
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryInventory.CreateItem(Item);

        AssembleToOrderLines.Last();
        AssembleToOrderLines.Type.SetValue(AssemblyLine.Type::Item);
        AssembleToOrderLines."No.".SetValue(Item."No.");
        AssembleToOrderLines."Quantity per".SetValue(LibraryRandom.RandInt(100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyInvoicedUpdatedInSalesShipmentWithAssembleToOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Sales] [Invoice] [Shipment]
        // [SCENARIO 257497] Invoicing a sales order with a linked assembly should update "Quantity Invoiced" in the posted shipment

        Initialize();

        // [GIVEN] Sales order with a linked assembly order, "Quantity" = 16
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::Order, Item, '');
        FindLinkedAssemblyOrder(AssemblyHeader, SalesHeader."Document Type", SalesHeader."No.");
        PostCompInventory(AssemblyHeader, false);

        // [GIVEN] Set "Qty. to Ship" = 8 in the sales order line
        FindSalesLine(SalesHeader, SalesLine, Item."No.");
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);
        SalesLine.Modify(true);

        // [WHEN] Post the sales order as shipped and invoiced
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Quantity Invoiced" in the posted sales shipment is 8
        SalesShipmentLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentLine.SetRange("Order Line No.", SalesLine."Line No.");
        SalesShipmentLine.FindFirst();

        SalesShipmentLine.TestField("Quantity Invoiced", SalesLine."Qty. to Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyInvoicedUpdatedInSalesShipmentPartiallyAssembled()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        AssemblyHeader: Record "Assembly Header";
        InventoryQty: Integer;
    begin
        // [FEATURE] [Sales] [Invoice] [Shipment]
        // [SCENARIO 257497] "Quantity Invoiced" in a posted sales shipment should be equal to the full invoiced quantity when shipment is partially supplied from inventory, and rest is assembled in ATO assembly

        Initialize();

        // [GIVEN] Sales order "SO" for item "I", "Quantity" = 15
        CreateSalesDocToMakeOrder(SalesHeader, SalesHeader."Document Type"::Order, Item, '');
        FindLinkedAssemblyOrder(AssemblyHeader, SalesHeader."Document Type", SalesHeader."No.");
        PostCompInventory(AssemblyHeader, false);

        FindSalesLine(SalesHeader, SalesLine, Item."No.");

        // [GIVEN] 6 pcs of item "I" are available on the inventory
        InventoryQty := LibraryRandom.RandInt(SalesLine.Quantity div 2);
        AddInventoryNonDirectLocation(Item."No.", '', '', InventoryQty);

        // [GIVEN] Set "Qty. to Assembly to Order" in the sales order "SO" to 9
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine.Quantity - InventoryQty);
        SalesLine.Modify(true);

        // [WHEN] Post the sales order as shipped and invoiced
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesShipmentLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentLine.SetRange("Order Line No.", SalesLine."Line No.");
        SalesShipmentLine.FindFirst();

        // [THEN] "Quantity Invoiced" in the posted sales shipment is 15
        SalesShipmentLine.TestField("Quantity Invoiced", SalesLine."Qty. to Invoice");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQtyHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure PartialShippingOfSalesOrderSuppliedByATOWithFullyTrackedItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Sales] [Order] [Shipment] [Item Tracking]
        // [SCENARIO 257670] Serial nos. for those "Qty. to Handle" is set to 0 in item tracking lines on sales line, are not assembled by linked assembly-to-order.
        Initialize();

        // [GIVEN] Assemble-to-order item "I" set up for serial no. tracking.
        CreateATOItemWithSNTracking(Item);

        // [GIVEN] Sales order for 5 pcs of item "I". All sales quantity will be supplied by linked assembly.
        CreateSaleLineWithShptDate(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", '', 5, WorkDate(), '');
        FindLinkedAssemblyOrder(AssemblyHeader, SalesHeader."Document Type", SalesHeader."No.");
        PostCompInventory(AssemblyHeader, false);

        // [GIVEN] Assign 5 serial nos. "S1", "S2", "S3", "S4", "S5" in item tracking for the assembly.
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        LibraryVariableStorage.Enqueue(5);
        AssemblyHeader.OpenItemTrackingLines();

        // [GIVEN] Sales line is automatically reserved from the linked assembly.
        // [GIVEN] Set "Qty. to Handle" = 0 for serial nos. "S1", "S2", "S3" in item tracking for the sales line.
        UpdateItemTrackingToExcludeNumberOfSerialNos(DATABASE::"Sales Line", SalesHeader."No.", 3);

        // [GIVEN] Correspondently update "Qty. to Ship" on the sales line to 2 pcs.
        FindSalesLine(SalesHeader, SalesLine, Item."No.");
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Modify(true);

        // [WHEN] Post the sales order with "Ship" option.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] 2 pcs are shipped.
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", 2);

        // [THEN] 2 pcs are assembled to supply the shipment.
        AssemblyHeader.Find();
        AssemblyHeader.TestField("Assembled Quantity", 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,EnterQtyHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure PostingAssembleWithReservedItemForPartiallyTrackedSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Sales] [Order] [Item Tracking] [Reservation] [Assemble-to-Stock]
        // [SCENARIO 257670] All serial nos. defined in item tracking for Assembly Order are posted, even though "Qty. to Handle" = 0 for several serial nos. in item tracking on sales line, which is reserved from this assembly-to-stock.
        Initialize();

        // [GIVEN] Assemble-to-order item "I" set up for serial no. tracking.
        CreateATOItemWithSNTracking(Item);

        // [GIVEN] Sales order for 5 pcs of item "I". All sales quantity will be supplied from the inventory.
        CreateSaleLineWithShptDate(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", '', 5, WorkDate(), '');
        FindSalesLine(SalesHeader, SalesLine, Item."No.");
        SalesLine.Validate("Qty. to Assemble to Order", 0);
        SalesLine.Modify(true);

        // [GIVEN] Assembly order for 5 pcs of item "I".
        // [GIVEN] Assign 5 serial nos. "S1", "S2", "S3", "S4", "S5" in item tracking for the assembly.
        CreateAssemblyOrder(AssemblyHeader, Item, '', '', WorkDate(), 5);
        PostCompInventory(AssemblyHeader, false);
        LibraryVariableStorage.Enqueue(ItemTrackingAction::AssignSerialNo);
        LibraryVariableStorage.Enqueue(5);
        AssemblyHeader.OpenItemTrackingLines();

        // [GIVEN] Reserve the sales line from the assembly.
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Set "Qty. to Handle" = 0 for serial nos. "S1", "S2", "S3" in item tracking for the sales line.
        UpdateItemTrackingToExcludeNumberOfSerialNos(DATABASE::"Sales Line", SalesHeader."No.", 3);

        // [WHEN] Post the assembly.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] 5 pcs are assembled.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 5);

        LibraryVariableStorage.AssertEmpty();

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure CanCreateBlanketATODespiteDisabledManualSeriesNos()
    var
        AssemblySetup: Record "Assembly Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Sales] [Blanket Order] [No. Series]
        // [SCENARIO 328542] Blocked manual series no. for blanket assembly orders does not prevent from creating a new linked assembly.
        Initialize();

        // [GIVEN] No. Series "B-ASM" for blanket assembly order nos. with disabled "Manual Nos." flag.
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        AssemblySetup.Get();
        AssemblySetup.Validate("Blanket Assembly Order Nos.", NoSeries.Code);
        AssemblySetup.Modify(true);

        // [GIVEN] Assembled item "I".
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", 2, 0, 0, 1, Item."Costing Method"::FIFO);

        // [GIVEN] Create sales blanket order with item "I", set "Qty. to Assemble to Order" = "Quantity".
        // [GIVEN] A linked assembly blanket order is created in the background.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        SetQtyToAssembleToOrder(SalesLine, SalesLine.Quantity);

        // [GIVEN] Clear "Qty. to Assemble to Order".
        // [GIVEN] That deletes the assembly blanket order together the Assemble-to-Order link.
        SetQtyToAssembleToOrder(SalesLine, 0);
        Assert.IsFalse(AssembleToOrderLink.AsmExistsForSalesLine(SalesLine), '');

        // [WHEN] Set "Qty. to Assemble to Order" back to "Quantity".
        SetQtyToAssembleToOrder(SalesLine, SalesLine.Quantity);

        // [THEN] A new linked assembly blanket order is created.
        FindLinkedAssemblyOrder(AssemblyHeader, SalesHeader."Document Type", SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure VerifyVariantCodeClearedWhenSelectingNewItemOnAssemblyOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        AssemblyHeader: Record "Assembly Header";
        AssemblyOrder: TestPage "Assembly Order";
        AssemblyOrderNo: Code[20];
    begin
        // [SCENARIO 479957] When user select item, previously selected variant code is no cleared: assembly header, prod order header
        Initialize();

        // [GIVEN] Create Items I1 with Item Variant and I2
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Stock", 1, 0, 0, 1, Item."Costing Method"::Standard);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [THEN] Create assembly order for item "I1"
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', LibraryRandom.RandDec(100, 2), ItemVariant.Code);

        // [WHEN] Open Assembly Order Page and change Item to I2
        AssemblyOrder.OpenEdit();
        AssemblyOrder.GotoRecord(AssemblyHeader);
        AssemblyOrder."Item No.".SetValue(Item2."No.");
        AssemblyOrderNo := Format(AssemblyOrder."No.");
        AssemblyOrder.Close();

        // [VERIFY] Verify: Changing Item No. on Assembly Order Page cleared the existing Variant Code
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyOrderNo);
        Assert.AreEqual('', AssemblyHeader."Variant Code", StrSubstNo(FieldMustBeEmptyErr, AssemblyHeader.FieldCaption("Variant Code")));

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('ATOLinesPageHandler')]
    [Scope('OnPrem')]
    procedure AssembleToOrderLinesPageShouldOpenForNewlyCopiedSalesQuoteFromArchiveQuote()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        ToSalesHeader: Record "Sales Header";
        OrderQty: Integer;
        DueDate: Date;
    begin
        // [SCENARIO 496851] There are Assemble-to-Order (ATO) Line Items with a non-zero number in the “Qty to Assemble to Order” column
        // but without a linked Assembly Order when using the Copy Document from an Archived Sales Order with the ATO Item.
        Initialize();

        // [GIVEN] Setup. Create Assembly item and Sales Quote.
        CreateAssembledItem(
            Item, "Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(10), LibraryRandom.RandInt(10),
            LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000), Item."Costing Method"::FIFO);

        OrderQty := LibraryRandom.RandInt(1000);
        DueDate := WorkDate2 + LibraryRandom.RandInt(30);
        CreateSaleLineWithShptDate(
            SalesHeader, SalesHeader."Document Type"::Quote,
            Item."No.", '', OrderQty, DueDate, '');

        // [THEN] Find Record Sales Header and Sales Line
        FindSOL(SalesHeader, SalesLine, 1);
        FindAssemblyHeader(
            AssemblyHeader, "Assembly Document Type"::Quote, Item,
            '', '', DueDate, Item."Base Unit of Measure", OrderQty);

        // [THEN] Add enough inventory for comp
        AddInvNonDirectLocAllComponent(AssemblyHeader, 100);

        // [VERIFY] Verify: Assemble to Order Lines page should open for Sales Quote
        VerifyAssembleToOrderLinesPageOpened(SalesHeader, OrderQty);

        // [GIVEN] Archive Sales Quote
        ArchiveSalesDocument(SalesHeader, SalesHeaderArchive);

        // [GIVEN] Prepare New Sales Quote
        ToSalesHeader.Init();
        ToSalesHeader.Validate("Document Type", ToSalesHeader."Document Type"::Quote);
        ToSalesHeader.Insert(true);

        // [WHEN] Copy Sales Archive Quote to Sales Quote
        RunCopySalesDoc(
            SalesHeaderArchive."No.", ToSalesHeader, "Sales Document Type From"::"Arch. Quote",
            SalesHeaderArchive."Doc. No. Occurrence", SalesHeaderArchive."Version No.", true, true);

        // [VERIFY] Verify: Assemble to Order Lines page should open for new Sales Quote
        VerifyAssembleToOrderLinesPageOpened(ToSalesHeader, OrderQty);
    end;

    [Test]
    [HandlerFunctions('MsgHandlerPostedAOs')]
    [Scope('OnPrem')]
    procedure AssembleToOrderLinkIsDeletedWhenQtyToAssembleToOrderIsSetToZeroInSOAfterPartialShipment()
    var
        Item, Item2, Item3 : Record Item;
        Customer: Record Customer;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BOMComponent, BOMComponent2 : Record "BOM Component";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        // [SCENARIO 537255] Assemble-to-Order Link is deleted when Qty. to Assemble to Order is set to 0 in Sales Order after partial shipment.
        Initialize();

        // [GIVEN] Create Item and Validate Replenishment System and Assembly Policy.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        // [GIVEN] Create Item 2.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create Item 3.
        LibraryInventory.CreateItem(Item3);

        // [GIVEN] Create BOM Component.
        LibraryInventory.CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item2."No.", LibraryRandom.RandInt(0), Item."Base Unit of Measure");

        // [GIVEN] Create BOM Component 2.
        LibraryInventory.CreateBOMComponent(BOMComponent2, Item."No.", BOMComponent2.Type::Item, Item3."No.", LibraryRandom.RandIntInRange(2, 2), Item."Base Unit of Measure");

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(ItemJournalLine, Item2, Item3);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create Sales Line and Validate Qty. to Assemble to Order and Qty. to Ship.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(2, 2));
        SalesLine.Validate("Qty. to Assemble to Order", LibraryRandom.RandIntInRange(2, 2));
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandInt(0));
        SalesLine.Modify(true);

        // [GIVEN] Post Sales Shipment.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Validate Qty. to Assemble to Order in Sales Line.
        SalesLine.Validate("Qty. to Assemble to Order", 0);

        // [WHEN] Find Assemble-to-Order Link.
        AssembleToOrderLink.SetRange("Document No.", SalesHeader."No.");

        // [THEN] Assemble-to-Order Link is deleted.
        Assert.IsTrue(AssembleToOrderLink.IsEmpty(), ATOLinkShouldNotBeFoundErr);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure ShowDocumentOnAssemblyLinesForBlanketOrderPageShouldOpenCorrectPage()
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyLines: TestPage "Assembly Lines";
        BlanketAssemblyOrder: TestPage "Blanket Assembly Order";
    begin
        // [SCENARIO 564531] Show document in Assembly order line page opens the wrong page when the Assembly order line belongs a blanket assembly order.
        Initialize();

        // [GIVEN] Assembled item "I".
        CreateAssembledItem(Item, "Assembly Policy"::"Assemble-to-Order", 2, 0, 0, 1, Item."Costing Method"::FIFO);

        // [GIVEN] Create sales blanket order with item "I", set "Qty. to Assemble to Order" = "Quantity".
        // [GIVEN] A linked assembly blanket order is created in the background.
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order",
            '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        SetQtyToAssembleToOrder(SalesLine, SalesLine.Quantity);

        // [GIVEN] Clear "Qty. to Assemble to Order".
        // [GIVEN] That deletes the assembly blanket order together the Assemble-to-Order link.
        SetQtyToAssembleToOrder(SalesLine, 0);
        Assert.IsFalse(AssembleToOrderLink.AsmExistsForSalesLine(SalesLine), '');

        // [WHEN] Set "Qty. to Assemble to Order" back to "Quantity".
        SetQtyToAssembleToOrder(SalesLine, SalesLine.Quantity);

        // [THEN] A new linked assembly blanket order is created.
        FindLinkedAssemblyOrder(AssemblyHeader, SalesHeader."Document Type", SalesHeader."No.");
        FindAssemblyLine(AssemblyHeader, AssemblyLine);

        // [WHEN] Open Assembly Lines Page and invoke show document action
        AssemblyLines.OpenEdit();
        BlanketAssemblyOrder.Trap();
        AssemblyLines.GoToRecord(AssemblyLine);
        AssemblyLines."Show Document".Invoke();

        // [THEN] Verify Blanket Assembly Order Page opened
        BlanketAssemblyOrder."No.".AssertEquals(AssemblyHeader."No.");
    end;

    local procedure VerifyAssembleToOrderLinesPageOpened(SalesHeader: Record "Sales Header"; QtyAssembleToOrder: Decimal)
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.SalesLines."Qty. to Assemble to Order".AssertEquals(QtyAssembleToOrder);
        SalesQuote.SalesLines."Assemble-to-Order Lines".Invoke();
    end;

    local procedure ArchiveSalesDocument(SalesHeader: Record "Sales Header"; var SalesHeaderArchive: Record "Sales Header Archive")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        SalesHeaderArchive.Get(SalesHeader."Document Type", SalesHeader."No.", 1, 1);
    end;

    local procedure RunCopySalesDoc(
        DocumentNo: Code[20]; NewSalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type From";
        FromDocNoOccurrence: Integer; FromDocVersionNo: Integer; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
        RunCopySalesDocWithRequestPage(
            DocumentNo, NewSalesHeader, DocType, FromDocNoOccurrence, FromDocVersionNo, IncludeHeader, RecalculateLines, false);
    end;

    local procedure RunCopySalesDocWithRequestPage(
        DocumentNo: Code[20]; NewSalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type From";
        FromDocNoOccurrence: Integer; FromDocVersionNo: Integer; IncludeHeader: Boolean; RecalculateLines: Boolean; UseRequestPage: Boolean)
    var
        CopySalesDoc: Report "Copy Sales Document";
    begin
        Clear(CopySalesDoc);
        CopySalesDoc.SetParameters(DocType, DocumentNo, FromDocNoOccurrence, FromDocVersionNo, IncludeHeader, RecalculateLines);
        CopySalesDoc.SetSalesHeader(NewSalesHeader);
        CopySalesDoc.UseRequestPage(UseRequestPage);
        CopySalesDoc.RunModal();
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item; var Item2: Record Item)
    begin
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine,
            ItemJournalBatch."Journal Template Name",
            ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Purchase,
            Item."No.",
            LibraryRandom.RandIntInRange(100, 100));

        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine,
            ItemJournalBatch."Journal Template Name",
            ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Purchase,
            Item2."No.",
            LibraryRandom.RandIntInRange(100, 100));

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    [ModalPageHandler]
    [HandlerFunctions('EnterQtyHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQtyHandler(var EnterQuantity: TestPage "Enter Quantity to Create")
    var
        Qty: Variant;
    begin
        LibraryVariableStorage.Dequeue(Qty);
        EnterQuantity.QtyToCreate.Value := Format(Qty);
        EnterQuantity.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemList.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ExplodeBOMOptionDialog(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1;  // Use 1 for Copy Dimensions from BOM.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHander(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

