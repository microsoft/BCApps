// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 149910 "Subc SCM Costing Rollup Sev"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        SubcManagementLibrary: Codeunit "Subc. Management Library";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        UnexpectedValueMsg: Label 'Unexpected %1 value in %2.', Comment = '%1 = Field Caption, %2 = Table Caption';
        ReverseCapacityLedgerEntryForSubContractingErr: Label 'Entry cannot be reversed as it is linked to the subcontracting work center.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        isInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Subc SCM Costing Rollup Sev");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Subc SCM Costing Rollup Sev");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Subc SCM Costing Rollup Sev");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrderWithNonBaseUOM()
    var
        WorkCenter: Record "Work Center";
        ParentItem: Record Item;
        ChildItem: Record Item;
        NonBaseItemUOM: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingLine: Record "Routing Line";
        Location: Record Location;
        RoutingLink: Record "Routing Link";
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test: PS 49588 (Vedbaek SE)  -  VSTF HF 211299
        Initialize();
        CustomizeSetupsAndLocation(Location);
        CreateManufacturingItems(ParentItem, NonBaseItemUOM, ChildItem);
        CreateRoutingSetup(WorkCenter, RoutingLine, RoutingLink);
        CreateProductionBOM(
          ProductionBOMHeader, ParentItem, ChildItem, NonBaseItemUOM.Code, RoutingLink.Code, LibraryRandom.RandDec(20, 2), 0);
        UpdateItemRoutingNo(ParentItem, RoutingLine."Routing No.");

        // Supply child item
        LibraryInventory.PostPositiveAdjustment(ChildItem, Location.Code, '', '',
          LibraryRandom.RandDec(125, 2), WorkDate(), LibraryRandom.RandDec(225, 2));

        // Create and refresh Released Production Order. Update new Unit Of Measure on Production Order Line.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ParentItem."No.", Location.Code);
        UpdateProdOrderLineUnitOfMeasureCode(ParentItem."No.", NonBaseItemUOM.Code);

        // Calculate subcontracts from subcontracting worksheet and create subcontracted purchase order
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(ParentItem."No.");

        SelectPurchaseOrderLine(PurchaseLine, ParentItem."No.");
        VerifyPurchaseOrderLine(PurchaseLine, NonBaseItemUOM, ParentItem."No.", Location.Code,
          ProductionOrder.Quantity, RoutingLine."Unit Cost per");

        // Post purchase header (only receipt)
        PurchaseHeader.SetCurrentKey("Document Type", "No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // Now post invoice
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        VerifyCapacityLedgerEntries(WorkCenter."No.", ParentItem."No.", ProductionOrder.Quantity,
          NonBaseItemUOM."Qty. per Unit of Measure", RoutingLine."Unit Cost per");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure VerifyCapacityLedgerEntryMustNotBeReversedWhenSubcontractingIsTrue()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 562491] Verify Capacity Ledger Entry must not be reversed When "Subcontracting" is true on Capacity Ledger Entry.
        Initialize();

        // [GIVEN] Create an item.
        CreateItem(Item);

        // [GIVEN] Create Routing with Subcontracting.
        CreateRoutingAndUpdateItemSubcontracted(Item, WorkCenter, true);

        // [GIVEN] Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // [GIVEN] Calculate Subcontracting
        CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Accept and Carry Out Action Message on Subcontracting Worksheet.
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // [GIVEN] Post Purchase Order.
        PostPurchaseOrder(Item."No.", true, true);

        // [GIVEN] Find Capacity Ledger Entry.
        FindCapacityLedgerEntry(CapacityLedgerEntry, ProductionOrder."No.", WorkCenter."No.");

        // [WHEN] Reverse Capacity Ledger Entry.
        CapacityLedgerEntries.OpenEdit();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        asserterror CapacityLedgerEntries.Reverse.Invoke();

        // [THEN] Capacity Ledger Entry must not be reversed When "Subcontracting" is true on Capacity Ledger Entry.
        Assert.ExpectedError(ReverseCapacityLedgerEntryForSubContractingErr);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,MsgHandler,YesConfirmHandler')]
    procedure VerifyReverseItemLedgerEntryShouldBeCreatedForConsumptionWhenReverseIsExecuted()
    var
        MfgSetup: Record "Manufacturing Setup";
        OutputItem: Record Item;
        CompItem: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 567053] Verify Reverse Entry should be created of Item Ledger Entry for Entry Type "Consumption" when Reverse action is executed.
        // if there is production order with Routing with subcontracting.
        Initialize();

        // [GIVEN] Get "Manufacturing Setup".
        MfgSetup.Get();

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(OutputItem, CompItem, LibraryRandom.RandIntInRange(1, 10));

        // [GIVEN] Create and Post Item Journal Line for Component item.
        CreateAndPostItemJournalLine(CompItem."No.", LibraryRandom.RandIntInRange(100, 200), '', MfgSetup."Components at Location");

        // [GIVEN] Create Routing with Subcontracting.
        CreateRoutingAndUpdateItemSubcontracted(OutputItem, WorkCenter, true);

        // [GIVEN] Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", LibraryRandom.RandIntInRange(1, 10), '', '');

        // [GIVEN] Find Released Production Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");

        // [GIVEN] Open and Post Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] OpenEdit Item Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Document No.", ProductionOrder."No.");
        ItemLedgerEntries.Filter.SetFilter("Entry Type", Format(ItemLedgerEntry."Entry Type"::Consumption));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse Entry should be created of Item Ledger Entry for Entry Type "Consumption".
        ItemLedgerEntry.Get(ItemLedgerEntries."Entry No.".AsInteger());
        FindLastItemLedgerEntry(ItemLedgerEntry, "Inventory Order Type"::Production, ProductionOrder."No.", ItemLedgerEntry."Order Line No.", "Item Ledger Entry Type"::Consumption);
        Assert.AreEqual(
            -ItemLedgerEntries.Quantity.AsInteger(),
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -ItemLedgerEntries.Quantity.AsInteger(), ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConsumptionNotFinishedConfirmHandler')]
    [Scope('OnPrem')]
    procedure PS49498()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Create a subcontract Purch. Order (PO) for a production item. Post receipt (PO), finish the Prod. Order,
        // revaluate the item, post invoice (PO) and validate 'Cost Amount (Actual)' in the Output Item Ledger Entry
        // for the production order

        Initialize();

        // Setup: Preparation for subcontracting orders: location, production item & routing setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItemSimple(ChildItem, ChildItem."Costing Method"::Standard, LibraryRandom.RandDec(10, 2));
        LibraryInventory.CreateItemSimple(ParentItem, ParentItem."Costing Method"::Standard, LibraryRandom.RandDec(10, 2));
        CreateRoutingSetupForPS49498(WorkCenter, RoutingLine, RoutingLink);
        CreateProductionBOMForPS49498(ProductionBOMHeader, ParentItem, ChildItem, RoutingLink.Code, LibraryRandom.RandDec(20, 2));
        ParentItem.Validate("Routing No.", RoutingLine."Routing No.");
        ParentItem.Modify(true);

        RunAdjustCostItemEntries('', '');  // Any item & item category

        // Supply child item
        LibraryInventory.PostPositiveAdjustment(ChildItem, Location.Code, '', '',
          LibraryRandom.RandDec(50, 2), WorkDate(), 0);

        // Create a released production order for parent item, calculate subcontracts and create subcontract Purch. Order
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ParentItem."No.", Location.Code);
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(ParentItem."No.");

        // Post receipt of this purchase order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ParentItem."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.SetCurrentKey("Document Type", "No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Change the status of the production order to finished. Ignore the warning (consumption is not finished yet)
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        RunAdjustCostItemEntries('', '');

        // Revaluate the parent item and run the Adjust Cost - Item entries job
        LibraryInventory.CreateRevaluationJournalLine(ItemJournalBatch, ParentItem,
          WorkDate(), "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::" ");
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", LibraryRandom.RandDec(200, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        RunAdjustCostItemEntries('', '');

        // Post invoice for the subcontract Purch. Order
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        RunAdjustCostItemEntries('', '');

        // Verify 'Unit cost (Actual)' in the Output Item Ledger Entry
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", ParentItem."No.");
        ItemLedgerEntry.FindFirst();

        GeneralLedgerSetup.Get();
        ParentItem.Get(ParentItem."No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreNearlyEqual(ParentItem."Unit Cost" * ItemLedgerEntry.Quantity,
          ItemLedgerEntry."Cost Amount (Actual)",
          GeneralLedgerSetup."Amount Rounding Precision",
          'Cost amount (Actual) matches Standard cost');
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    [Normal]
    local procedure CustomizeSetupsAndLocation(var Location: Record Location)
    var
        InvtSetup: Record "Inventory Setup";
        MfgSetup: Record "Manufacturing Setup";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        UpdateInventorySetup(InvtSetup, true, true, InvtSetup."Automatic Cost Adjustment"::Always,
          InvtSetup."Average Cost Calc. Type"::Item,
          InvtSetup."Average Cost Period"::Day);
        LibraryManufacturing.UpdateManufacturingSetup(MfgSetup, '', Location.Code, true, true, true);
    end;

    [Normal]
    local procedure CreateManufacturingItems(var ParentItem: Record Item; var NonBaseItemUOM: Record "Item Unit of Measure"; var ChildItem: Record Item)
    begin
        CreateItemWithAdditionalUOM(ParentItem, NonBaseItemUOM);
        ParentItem.Validate("Costing Method", ParentItem."Costing Method"::Average);
        ParentItem.Modify(true);

        LibraryInventory.CreateItem(ChildItem);
        ChildItem.Validate("Costing Method", ChildItem."Costing Method"::Average);
        ChildItem.Validate("Replenishment System", ChildItem."Replenishment System"::Purchase);
        ChildItem.Validate("Flushing Method", ChildItem."Flushing Method"::Backward);
        ChildItem.Modify(true);
    end;

    local procedure CreateSubcontractedWorkCenter(var WorkCenter: Record "Work Center")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        WorkCenter.Validate("Direct Unit Cost", 0);
        WorkCenter.Validate("Specific Unit Cost", true);
        SubcManagementLibrary.CreateSubcontractor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);

        // Calculate calendar
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()),
          CalcDate('<1M>', WorkDate()));
    end;

    [Normal]
    local procedure CreateItemWithAdditionalUOM(var Item: Record Item; var NewItemUOM: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(NewItemUOM, Item."No.", LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20]; RoutingLinkCode: Code[10])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, CenterNo,
          OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        RoutingLine.Validate("Unit Cost per", LibraryRandom.RandDec(10, 2));
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
    end;

    local procedure CreateRoutingSetup(var WorkCenter: Record "Work Center"; var RoutingLine: Record "Routing Line"; var RoutingLink: Record "Routing Link")
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateSubcontractedWorkCenter(WorkCenter);

        // Setup routing (and its cost) for parent item
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", RoutingLink.Code);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure SelectPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    local procedure UpdateItemRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateProdOrderLineUnitOfMeasureCode(ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    [Normal]
    local procedure VerifyPurchaseOrderLine(PurchaseLine: Record "Purchase Line"; ItemUOM: Record "Item Unit of Measure"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; DirectUnitCost: Decimal)
    begin
        Assert.AreEqual(PurchaseLine."Unit of Measure Code", ItemUOM.Code,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("Unit of Measure Code"), PurchaseLine.TableCaption()));
        Assert.AreEqual(PurchaseLine.Type, PurchaseLine.Type::Item,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption(Type), PurchaseLine.TableCaption()));
        Assert.AreEqual(PurchaseLine."No.", ItemNo,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("No."), PurchaseLine.TableCaption()));
        Assert.AreEqual(PurchaseLine."Location Code", LocationCode,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("Location Code"), PurchaseLine.TableCaption()));
        Assert.AreEqual(PurchaseLine.Quantity, Qty,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption(Quantity), PurchaseLine.TableCaption()));

        Assert.AreNearlyEqual(PurchaseLine."Line Amount",
          DirectUnitCost * Qty * ItemUOM."Qty. per Unit of Measure",
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("Line Amount"), PurchaseLine.TableCaption()));
        Assert.AreNearlyEqual(PurchaseLine."Direct Unit Cost",
          DirectUnitCost * ItemUOM."Qty. per Unit of Measure",
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("Direct Unit Cost"), PurchaseLine.TableCaption()));
    end;

    [Normal]
    local procedure VerifyCapacityLedgerEntries(WorkCenterNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; QtyPerBaseUOM: Decimal; DirectUnitCost: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Item No.", ItemNo);
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenterNo);
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.FindLast();

        Assert.AreNearlyEqual(CapacityLedgerEntry."Output Quantity",
          Qty * QtyPerBaseUOM,
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(UnexpectedValueMsg, CapacityLedgerEntry.FieldCaption("Output Quantity"), CapacityLedgerEntry.TableCaption()));

        CapacityLedgerEntry.CalcFields("Direct Cost");
        Assert.AreNearlyEqual(CapacityLedgerEntry."Direct Cost",
          Qty * QtyPerBaseUOM * DirectUnitCost,
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(UnexpectedValueMsg, CapacityLedgerEntry.FieldCaption("Direct Cost"), CapacityLedgerEntry.TableCaption()));
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.SetRange("No.", WorkCenter."No.");
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);
    end;

    local procedure CarryOutActionMessageSubcontractWksh(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure CreateRoutingAndUpdateItemSubcontracted(var Item: Record Item; var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean): Code[10]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        CreateWorkCenter(WorkCenter, IsSubcontracted);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLink.FindFirst();
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        exit(RoutingLink.Code);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        if IsSubcontracted then
            WorkCenter.Validate("Subcontractor No.", LibraryPurchase.CreateVendorNo());

        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        OperationNo := LibraryManufacturing.FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo, Quantity, LocationCode, BinCode);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure PostPurchaseOrder(ItemNo: Code[20]; ShipReceive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        if Invoice and (PurchaseHeader."Vendor Invoice No." = '') then
            PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ShipReceive, Invoice);
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure FindCapacityLedgerEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; ProductionOrderNo: Code[20]; WorkCenterNo: Code[20])
    begin
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrderNo);
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenterNo);
        CapacityLedgerEntry.FindFirst();
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(Item2);

        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindLastItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; InventoryOrderType: Enum "Inventory Order Type"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ItemLedgerEntryType: Enum "Item Ledger Entry Type")
    begin
        ItemLedgerEntry.SetRange("Order Type", InventoryOrderType);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgerEntry.SetRange("Order Line No.", ProdOrderLineNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        ItemLedgerEntry.FindLast();
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournalLineWithUnitCost(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; UnitCost: Decimal)
    begin
        ItemJournalSetup(ItemJournalBatch);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure ItemJournalSetup(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    [Normal]
    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProducedItem: Record Item; ComponentItem: Record Item; UOMCode: Code[10]; RoutingLinkCode: Code[10]; CompQty: Decimal; ScrapPercent: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UOMCode);

        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '',
          ProductionBOMLine.Type::Item, ComponentItem."No.", CompQty);
        ProductionBOMLine.Validate("Unit of Measure Code", ComponentItem."Base Unit of Measure");
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Validate("Scrap %", ScrapPercent);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        ProducedItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProducedItem.Modify(true);
    end;

    local procedure UpdateInventorySetup(var InventorySetup: Record "Inventory Setup"; AutomaticCostPosting: Boolean; ExpectedCostPostingtoGL: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type"; AverageCostCalcType: Enum "Average Cost Calculation Type"; AverageCostPeriod: Enum "Average Cost Period Type")
    begin
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, AutomaticCostPosting, ExpectedCostPostingtoGL, AutomaticCostAdjustment, AverageCostCalcType, AverageCostPeriod);
        // Dummy Message and Confirm to avoid dependency on previous state of Inventory Setup
        Message('');
        if Confirm('') then;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Msg: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure PostProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;

    [Normal]
    local procedure CreateRoutingSetupForPS49498(var WorkCenter: Record "Work Center"; var RoutingLine: Record "Routing Line"; var RoutingLink: Record "Routing Link")
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateSubcontractWorkcenter(WorkCenter);

        // Setup routing (and its cost) for parent item
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateRoutingLineForPS49498(RoutingLine, RoutingHeader, WorkCenter."No.", RoutingLink.Code);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    [Normal]
    local procedure CreateSubcontractWorkcenter(var WorkCenter: Record "Work Center")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        SubcManagementLibrary.CreateSubcontractor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
    end;

    [Normal]
    local procedure CreateRoutingLineForPS49498(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20]; RoutingLinkCode: Code[10])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, CenterNo,
          OperationNo, 0, LibraryRandom.RandDec(5, 2));    // Random run-time cost
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
    end;

    [Normal]
    local procedure CreateProductionBOMForPS49498(var ProductionBOMHeader: Record "Production BOM Header"; var ProducedItem: Record Item; ComponentItem: Record Item; RoutingLinkCode: Code[10]; CompQty: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProducedItem."Base Unit of Measure");

        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine,
          '', ProductionBOMLine.Type::Item, ComponentItem."No.", CompQty);
        ProductionBOMLine.Validate("Unit of Measure Code", ComponentItem."Base Unit of Measure");
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        ProducedItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProducedItem.Modify(true);
    end;

    [Normal]
    local procedure RunAdjustCostItemEntries(ItemFilter: Text[250]; ItemCategoryFilter: Text[250])
    var
        AdjustCostItemEntries: Report "Adjust Cost - Item Entries";
    begin
        Clear(AdjustCostItemEntries);
        AdjustCostItemEntries.InitializeRequest(ItemFilter, ItemCategoryFilter);
        AdjustCostItemEntries.UseRequestPage(false);
        AdjustCostItemEntries.RunModal();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConsumptionNotFinishedConfirmHandler(ConfirmMsg: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;   // Finish the order even if consumption is not finished
    end;
}