// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Reconciliation;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

codeunit 137083 "SCM Production Orders IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        ShowLevelAs: Option "First BOM Level","BOM Leaves";
        ShowCostShareAs: Option "Single-level","Rolled-up";
        IsInitialized: Boolean;
        ItemNoLbl: Label 'ItemNo';
        TotalCostLbl: Label 'TotalCost';
        CapOvhdCostLbl: Label 'CapOvhdCost';
        MfgOvhdCostLbl: Label 'MfgOvhdCost';
        MaterialCostLbl: Label 'MaterialCost';
        CapacityCostLbl: Label 'CapacityCost';
        SubcontrdCostLbl: Label 'SubcontrdCost';
        NonInventoryMaterialCostLbl: Label 'NonInventoryMaterialCost';
        MissingAccountTxt: Label '%1 is missing in %2.', Comment = '%1 = Field caption, %2 = Table Caption';
        FieldMustBeEditableErr: Label '%1 must be editable in %2', Comment = ' %1 = Field Name , %2 = Page Name';
        FieldMustNotBeEditableErr: Label '%1 must not be editable in %2', Comment = ' %1 = Field Name , %2 = Page Name';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        EntryMustBeEqualErr: Label '%1 must be equal to %2 for Entry No. %3 in the %4.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Entry No., %4 = Table Caption';
        CannotFinishProductionLineErr: Label 'You cannot finish line %1 on %2 %3. It has consumption or capacity posted with no output.', Comment = '%1 = Production Order Line No. , %2 = Table Caption , %3 = Production Order No.';
        MaterialCostMustBeEqualErr: Label 'Material Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        CapacityCostMustBeEqualErr: Label 'Capacity Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        SubcontractedCostMustBeEqualErr: Label 'Subcontracted Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        MfgOverheadCostMustBeEqualErr: Label 'Mfg. Overhead Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        CapacityOverheadCostMustBeEqualErr: Label 'Capacity Overhead Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        NonInvMaterialCostMustBeEqualErr: Label 'Non Inventory Material Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        TotalCostMustBeEqualErr: Label 'Total Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst: Label '%1 is greater or equal to %2 in %3 Status=%4,Prod. Order No.=%5, Line No.=%6. Do you want to continue?\\ If yes, %7 will be changed to %8.',
                                                                Comment = '%1 = Field Caption , %2 = Field Caption, %3 = Table Caption, %4 = Status , %5 = Production Order No., %6 = Production Order Line No., %7= Field Caption, %8 = New Date';
        ManualSchedulingMustBeTrueErr: Label 'Manual Scheduling must be true in %1.', Comment = '%1 = Table Caption';
        DateConflictErr: Label 'The change leads to a date conflict with existing reservations.\Reserved quantity (Base): %1, Date %2\Cancel or change reservations and try again', Comment = '%1 - reserved quantity, %2 - date';
        FieldMustBeVisibleErr: Label '%1 must be visible in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        FieldMustBeEnabledErr: Label '%1 must be enabled in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        ItemMustBeEqualErr: Label '%1 must be equal to %2 for Item No. %3 in the %4.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Item No., %4 = Table Caption';

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyUndoProductionOrderWithConsumptionWithoutAutomaticCostPosting()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order with no output, and the cost impact should also be posted to the inventory adjustment account.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [THEN] Verify "Cost Posted to G/L" must be zero in Value Entry for Capacity and consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [WHEN] Run "Post Inventory Cost to G/L".
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "G/L Entries" for both value entries and cost impact should also be posted to the inventory adjustment account.
        VerifyGLEntriesForConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntry(ProductionOrder, RunTime * RoutingUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure VerifyUndoProductionOrderWithConsumptionWithAutomaticCostPosting()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order with no output, and the cost impact should also be posted to the inventory adjustment account with Automatic Cost Posting.
        Initialize();

        // [GIVEN] Update "Finish Order without Output"in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "G/L Entries" for both value entries and cost impact should also be posted to the inventory adjustment account.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status::Finished, ProductionOrder."No.");
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        VerifyGLEntriesForConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntry(ProductionOrder, RunTime * RoutingUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyUndoProductionOrderWithConsumptionAndPostInventoryCostToGLIsExecutedForFinishedProdOrder()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order with no output.
        // The cost impact should also be posted to the inventory adjustment account When "Post Inventory Cost to G/L" is executed for Finished Production Order.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "Cost Posted to G/L" must be zero in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [WHEN] Run "Post Inventory Cost to G/L".
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption. "G/L Entries" for both value entries and cost impact should also be posted to the inventory adjustment account.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        VerifyGLEntriesForConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntry(ProductionOrder, RunTime * RoutingUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure VerifyProductionOrderPostedWithConsumptionAndOutputWhenFinishOrderWithoutOutputIsEnabled()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order with output.
        // If "Finish Order without Output" is enabled on Change Status page then the cost impact should not be posted to the inventory adjustment account with Automatic Cost Posting.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, RunTime, RoutingUnitCost);

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "G/L Entries" for both value entries and cost impact should not be posted to the inventory adjustment account.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status::Finished, ProductionOrder."No.");
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        VerifyGLEntriesForConsumptionEntryWithOutput(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntryWithOutput(ProductionOrder, RunTime * RoutingUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyAdjustmentEntryShouldAlsoBeCreatedForItemCharge()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseHeader: Record "Purchase Header";
        ChargeItemPurchaseHeader: Record "Purchase Header";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
        ItemChargeUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order without output.
        // If "Finish Order without Output" is enabled while changing the status then the cost impact should also be posted to the inventory adjustment account for Item Charge.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        ItemChargeUnitCost := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Purchase Document with Unit Cost.
        CreateAndPostPurchaseOrderWithDirectUnitCost(PurchaseHeader, CompItem."No.", Quantity, CompUnitCost);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "G/L Entries" for both value entries and cost impact should also be posted to the inventory adjustment account.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status::Finished, ProductionOrder."No.");
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        VerifyGLEntriesForConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntry(ProductionOrder, RunTime * RoutingUnitCost);

        // [GIVEN] Create And Post Item Charge Purchase Order.
        CreateAndPostChargeItemPO(ChargeItemPurchaseHeader, PurchaseHeader."No.", CompItem."No.", WorkDate(), Quantity, ItemChargeUnitCost);

        // [GIVEN] Adust Cost-Item Entries.
        LibraryCosting.AdjustCostItemEntries(CompItem."No.", '');

        // [WHEN] Run "Post Inventory Cost to G/L".
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify cost impact should also be posted to the inventory adjustment account for Item Charge.
        VerifyGLEntriesForAdjustmentConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * ItemChargeUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure VerifyInventoryAdjustAccountIsMissingWhenStatusIsChanged()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        GeneralPostingSetup: Record "General Posting Setup";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the user should not be able to change the status When "Inventory Adjmt. Account" is missing in General Posting Setup.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Find Value Entry for "Item Ledger Entry Type" Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");

        // [GIVEN] Update "Inventory Adjmt. Account" in General Posting Setup.
        GeneralPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", '');
        GeneralPostingSetup.Modify();

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        asserterror ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify that the user should not be able to change the status When "Inventory Adjmt. Account" is missing in General Posting Setup.
        GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", ValueEntry."Gen. Bus. Posting Group");
        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        GeneralPostingSetup.FindFirst();
        Assert.ExpectedError(
            StrSubstNo(MissingAccountTxt, GeneralPostingSetup.FieldCaption("Inventory Adjmt. Account"), GeneralPostingSetup.TableCaption() + ' ' + GeneralPostingSetup.GetFilters()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,VerifyFinishOrderWithoutOutputNotEditableInChangeStatusOnProdOrder')]
    procedure VerifyFinishOrderWithoutOutputMustNotBeEditableInChangeStatusOnProdOrderPage()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ReleasedProductionOrder: TestPage "Released Production Order";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the "Finish Order without Output" must not be editable in "Change Status on Prod. Order" page When "Finish Order Without Output" is false in Manufacturing Setup.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(false);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Find Value Entry for "Item Ledger Entry Type" Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");

        // [WHEN] Invoke "Change Status" action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [THEN] Verify that the "Finish Order without Output" must not be editable in "Change Status on Prod. Order" page through Handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,VerifyFinishOrderWithoutOutputEditableInChangeStatusOnProdOrder')]
    procedure VerifyFinishOrderWithoutOutputMustBeEditableInChangeStatusOnProdOrderPage()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ReleasedProductionOrder: TestPage "Released Production Order";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the "Finish Order without Output" must be editable in "Change Status on Prod. Order" page When "Finish Order without Output" is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Find Value Entry for "Item Ledger Entry Type" Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");

        // [WHEN] Invoke "Change Status" action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [THEN] Verify that the "Finish Order Without Output" must be editable in "Change Status on Prod. Order" page through Handler.
    end;

    [Test]
    [HandlerFunctions('ChangeStatusOnProdOrderOk,ConfirmHandlerTrue')]
    procedure VerifyReleasedProdOrderCannotBeFinishedWithoutOutputWhenScrapPostingIsNotEnabled()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ReleasedProductionOrder: TestPage "Released Production Order";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order cannot be Finished without output When "Finish Order without Output" is false in Manufacturing Setup.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(false);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Find Value Entry for "Item Ledger Entry Type" Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");

        // [GIVEN] Find Prod order Line.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [WHEN] Invoke "Change Status" action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        asserterror ReleasedProductionOrder."Change &Status".Invoke();

        // [THEN] Verify that the Released Production Order cannot be Finished without output.
        Assert.ExpectedError(StrSubstNo(CannotFinishProductionLineErr, ProdOrderLine."Line No.", ProductionOrder.TableCaption(), ProdOrderLine."Prod. Order No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyMaterialCostNonInventoryValueMustBeShownInBOMCostSharesForProductionItem()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        BOMCostShares: TestPage "BOM Cost Shares";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Set Value of Item Filter in BOM Cost Shares Page.
        BOMCostShares.OpenView();
        BOMCostShares.ItemFilter.SetValue(OutputItem."No.");

        // [THEN] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page.
        BOMCostShares."Rolled-up Mat. Non-Invt. Cost".AssertEquals(NonInvUnitCost);
        BOMCostShares."Total Cost".AssertEquals(NonInvUnitCost);

        // [THEN] Verify Material Costs fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, NonInvUnitCost, 0, 0, NonInvUnitCost, NonInvUnitCost, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyMaterialCostNonInventoryValueMustBeShownInBOMCostSharesForProductionItemWithTwoComponents()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        BOMCostShares: TestPage "BOM Cost Shares";
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
    begin
        // [SCENARIO 457878] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory and production item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(SemiOutputItem, NonInvItem1, ProductionBOMHeader);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(20, 20);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(30, 30);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);

        // [GIVEN] Update "Costing Method" Standard in Semi-Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(OutputItem, NonInvItem2, SemiOutputItem);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Set Value of Item Filter in BOM Cost Shares Page.
        BOMCostShares.OpenView();
        BOMCostShares.ItemFilter.SetValue(OutputItem."No.");

        // [THEN] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory and production item exist in Production BOM.
        BOMCostShares."Rolled-up Mat. Non-Invt. Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2);
        BOMCostShares."Total Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2);

        // [THEN] Verify Material Costs fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, NonInvUnitCost1 + NonInvUnitCost2, NonInvUnitCost1, 0, NonInvUnitCost2, NonInvUnitCost1 + NonInvUnitCost2, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyMaterialCostNonInventoryValueMustBeShownInBOMCostSharesForProductionItemWithThreeComponents()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        CompItem: array[2] of Record Item;
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        BOMCostShares: TestPage "BOM Cost Shares";
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
        CompUnitCost1: Decimal;
        CompUnitCost2: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedSLMatCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory, component and production item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create component items.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(SemiOutputItem, NonInvItem1, CompItem[1]);

        // [GIVEN] Save Quantity, Component and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(50, 50);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(20, 20);
        CompUnitCost1 := LibraryRandom.RandIntInRange(30, 30);
        CompUnitCost2 := LibraryRandom.RandIntInRange(40, 40);
        ExpectedStandardCost := NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2;
        ExpectedSLMatCost := NonInvUnitCost1 + CompUnitCost1 + CompUnitCost2;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[1], Quantity, CompUnitCost1);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(OutputItem, NonInvItem2, SemiOutputItem, CompItem[2]);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[2], Quantity, CompUnitCost2);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Set Value of Item Filter in BOM Cost Shares Page.
        BOMCostShares.OpenView();
        BOMCostShares.ItemFilter.SetValue(OutputItem."No.");

        // [THEN] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory, component and production item exist in Production BOM.
        BOMCostShares."Rolled-up Mat. Non-Invt. Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2);
        BOMCostShares."Total Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2);

        // [THEN] Verify Material Costs fields in Semi-Output item.
        SemiOutputItem.Get(SemiOutputItem."No.");
        VerifyCostFieldsInItem(SemiOutputItem, NonInvUnitCost1 + CompUnitCost1, CompUnitCost1, CompUnitCost1, NonInvUnitCost1, NonInvUnitCost1, 0, 0);

        // [THEN] Verify Material Costs fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, ExpectedStandardCost, ExpectedSLMatCost, CompUnitCost1 + CompUnitCost2, NonInvUnitCost2, NonInvUnitCost1 + NonInvUnitCost2, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifySingleAndRolledCostFieldsWithIndirectPercentageForProductionItem()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        CompItem: array[2] of Record Item;
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        BOMCostShares: TestPage "BOM Cost Shares";
        ExpectedOvhdCost: Decimal;
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
        CompUnitCost1: Decimal;
        CompUnitCost2: Decimal;
        IndirectCostPer: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedSLMatCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Single-Level" and "Rolled-up" fields with "Indirect Cost %" for production item.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create component items.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(SemiOutputItem, NonInvItem1, CompItem[1]);

        // [GIVEN] Save Quantity, Component, Indirect% and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(50, 50);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(20, 20);
        CompUnitCost1 := LibraryRandom.RandIntInRange(30, 30);
        CompUnitCost2 := LibraryRandom.RandIntInRange(40, 40);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2) * IndirectCostPer / 100;
        ExpectedStandardCost := NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2 + ExpectedOvhdCost;
        ExpectedSLMatCost := NonInvUnitCost1 + CompUnitCost1 + CompUnitCost2;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[1], Quantity, CompUnitCost1);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(OutputItem, NonInvItem2, SemiOutputItem, CompItem[2]);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[2], Quantity, CompUnitCost2);

        // [GIVEN] Update "Costing Method" Standard and "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Set Value of Item Filter in BOM Cost Shares Page.
        BOMCostShares.OpenView();
        BOMCostShares.ItemFilter.SetValue(OutputItem."No.");

        // [THEN] Verify "Total Cost" must be shown in "BOM Cost Shares" page for production item.
        BOMCostShares."Total Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2 + ExpectedOvhdCost);

        // [THEN] Verify Costs fields in Semi-Output item.
        SemiOutputItem.Get(SemiOutputItem."No.");
        VerifyCostFieldsInItem(SemiOutputItem, NonInvUnitCost1 + CompUnitCost1, CompUnitCost1, CompUnitCost1, NonInvUnitCost1, NonInvUnitCost1, 0, 0);

        // [THEN] Verify Costs fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(
            OutputItem,
            ExpectedStandardCost,
            ExpectedSLMatCost,
            CompUnitCost1 + CompUnitCost2,
            NonInvUnitCost2,
            NonInvUnitCost1 + NonInvUnitCost2,
            ExpectedOvhdCost,
            ExpectedOvhdCost);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifySingleLevelAndRolledUpCostFieldsWithIndirectPercentageForStockKeepingUnit()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        Location: Record Location;
        CompItem: array[2] of Record Item;
        SemiStockkeepingUnit: Record "Stockkeeping Unit";
        OutputStockkeepingUnit: Record "Stockkeeping Unit";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ExpectedOvhdCost: Decimal;
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
        CompUnitCost1: Decimal;
        CompUnitCost2: Decimal;
        IndirectCostPer: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedSLMatCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Single-Level" and "Rolled-up" fields with "Indirect Cost %" for "StockKeeping Unit".
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create component items.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(SemiOutputItem, NonInvItem1, CompItem[1]);

        // [GIVEN] Update "Costing Method" Standard in Semi-Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Save Quantity, Component, Indirect% and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(50, 50);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(20, 20);
        CompUnitCost1 := LibraryRandom.RandIntInRange(30, 30);
        CompUnitCost2 := LibraryRandom.RandIntInRange(40, 40);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2) * IndirectCostPer / 100;
        ExpectedStandardCost := NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2 + ExpectedOvhdCost;
        ExpectedSLMatCost := NonInvUnitCost1 + CompUnitCost1 + CompUnitCost2;

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Semi-Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(SemiOutputItem, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Semi-Stockkeeping Unit.
        SemiStockkeepingUnit.SetRange("Item No.", SemiOutputItem."No.");
        SemiStockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        SemiStockkeepingUnit.Validate("Location Code", Location.Code);
        SemiStockkeepingUnit.Validate("Routing No.", '');
        SemiStockkeepingUnit.Validate("Production BOM No.", SemiOutputItem."Production BOM No.");
        SemiStockkeepingUnit.Modify(true);

        // [GIVEN] Update "Production BOM No." in Semi-Production item.
        SemiOutputItem.Validate("Production BOM No.", '');
        SemiOutputItem.Modify();

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[1], Quantity, CompUnitCost1);

        // [WHEN] Calculate Standard Cost for Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(SemiStockkeepingUnit."Item No.", SemiStockkeepingUnit."Location Code", SemiStockkeepingUnit."Variant Code");

        // [THEN] Verify Costs fields in Semi StockKeeping Unit and Output item.
        SemiStockkeepingUnit.Get(SemiStockkeepingUnit."Location Code", SemiStockkeepingUnit."Item No.", SemiStockkeepingUnit."Variant Code");
        VerifyCostFieldsInItem(SemiOutputItem, 0, 0, 0, 0, 0, 0, 0);
        VerifyCostFieldsInSKU(SemiStockkeepingUnit, NonInvUnitCost1 + CompUnitCost1, CompUnitCost1, CompUnitCost1, NonInvUnitCost1, NonInvUnitCost1, 0, 0);

        // [GIVEN] Update "Production BOM No." in Semi-Production item.
        SemiOutputItem.Validate("Production BOM No.", SemiStockkeepingUnit."Production BOM No.");
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(OutputItem, NonInvItem2, SemiOutputItem, CompItem[2]);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[2], Quantity, CompUnitCost2);

        // [GIVEN] Update "Costing Method" Standard and "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [GIVEN] Create Production Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(OutputItem, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Production Stockkeeping Unit.
        OutputStockkeepingUnit.SetRange("Item No.", OutputItem."No.");
        OutputStockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        OutputStockkeepingUnit.Validate("Location Code", Location.Code);
        OutputStockkeepingUnit.Validate("Routing No.", '');
        OutputStockkeepingUnit.Validate("Production BOM No.", OutputItem."Production BOM No.");
        OutputStockkeepingUnit.Modify(true);

        // [GIVEN] Update "Production BOM No." in Production item.
        OutputItem.Validate("Production BOM No.", '');
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Calculate Standard Cost for Production Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(OutputStockkeepingUnit."Item No.", OutputStockkeepingUnit."Location Code", OutputStockkeepingUnit."Variant Code");

        // [THEN] Verify Costs fields in Output StockKeeping Unit and item.
        OutputStockkeepingUnit.Get(OutputStockkeepingUnit."Location Code", OutputStockkeepingUnit."Item No.", OutputStockkeepingUnit."Variant Code");
        VerifyCostFieldsInItem(OutputItem, 0, 0, 0, 0, 0, 0, 0);
        VerifyCostFieldsInSKU(
            OutputStockkeepingUnit,
            ExpectedStandardCost,
            ExpectedSLMatCost,
            CompUnitCost1 + CompUnitCost2,
            NonInvUnitCost2,
            NonInvUnitCost1 + NonInvUnitCost2,
            ExpectedOvhdCost,
            ExpectedOvhdCost);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,BOMCostSharesDistributionReportHandler')]
    procedure VerifyCostAmountInBOMCostSharesDistributionReportForProductionItem()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        CompItem: array[2] of Record Item;
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        ExpectedOvhdCost: Decimal;
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
        CompUnitCost1: Decimal;
        CompUnitCost2: Decimal;
        IndirectCostPer: Decimal;
        ExpectedSLMatCost: Decimal;
        ExpectedTotalCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Cost Amount fields in "BOM Cost Share Distribution" report for production item.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create component items.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(SemiOutputItem, NonInvItem1, CompItem[1]);

        // [GIVEN] Save Quantity, Component, Indirect% and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(50, 50);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(20, 20);
        CompUnitCost1 := LibraryRandom.RandIntInRange(30, 30);
        CompUnitCost2 := LibraryRandom.RandIntInRange(40, 40);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2) * IndirectCostPer / 100;
        ExpectedSLMatCost := CompUnitCost1 + CompUnitCost2 + NonInvUnitCost1;
        ExpectedTotalCost := NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2 + ExpectedOvhdCost;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[1], Quantity, CompUnitCost1);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(OutputItem, NonInvItem2, SemiOutputItem, CompItem[2]);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[2], Quantity, CompUnitCost2);

        // [GIVEN] Update "Costing Method" Standard and "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Run "BOM Cost Share Distribution" with ShowLevelAs "First BOM Level" and ShowCostShareAs "Single-level".
        RunBOMCostSharesReport(OutputItem, ShowLevelAs::"First BOM Level", true, ShowCostShareAs::"Single-level");

        // [THEN] Verify Cost Amount in "BOM Cost Share Distribution" report.
        VerifyBOMCostSharesReport(OutputItem."No.", ExpectedSLMatCost, 0, ExpectedOvhdCost, 0, 0, NonInvUnitCost2, ExpectedTotalCost);

        // [WHEN] Run "BOM Cost Share Distribution" with ShowLevelAs "BOM Leaves" and ShowCostShareAs "Single-level".
        RunBOMCostSharesReport(OutputItem, ShowLevelAs::"BOM Leaves", true, ShowCostShareAs::"Single-level");

        // [THEN] Verify Cost Amount in "BOM Cost Share Distribution" report.
        VerifyBOMCostSharesReport(OutputItem."No.", ExpectedSLMatCost, 0, ExpectedOvhdCost, 0, 0, NonInvUnitCost2, ExpectedTotalCost);

        // [WHEN] Run "BOM Cost Share Distribution" with ShowLevelAs "First BOM Level" and ShowCostShareAs "Rolled-up".
        RunBOMCostSharesReport(OutputItem, ShowLevelAs::"First BOM Level", true, ShowCostShareAs::"Rolled-up");

        // [THEN] Verify Cost Amount in "BOM Cost Share Distribution" report.
        VerifyBOMCostSharesReport(OutputItem."No.", CompUnitCost1 + CompUnitCost2, 0, ExpectedOvhdCost, 0, 0, NonInvUnitCost1 + NonInvUnitCost2, ExpectedTotalCost);

        // [WHEN] Run "BOM Cost Share Distribution" with ShowLevelAs "BOM Leaves" and ShowCostShareAs "Rolled-up".
        RunBOMCostSharesReport(OutputItem, ShowLevelAs::"BOM Leaves", true, ShowCostShareAs::"Rolled-up");

        // [THEN] Verify Cost Amount in "BOM Cost Share Distribution" report.
        VerifyBOMCostSharesReport(OutputItem."No.", CompUnitCost1 + CompUnitCost2, 0, ExpectedOvhdCost, 0, 0, NonInvUnitCost1 + NonInvUnitCost2, ExpectedTotalCost);
    end;

    [Test]
    procedure ManualSchedulingAndSafetyLeadTimeForManSchAreVisibleAndEnabledOnManufacturingSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ManufacturingSetupPage: TestPage "Manufacturing Setup";
    begin
        // [SCENARIO 317246] Verify "Manual Scheduling" and "Safety Lead Time for Man. Sch." must be visible in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [WHEN] Open Manufacturing Setup page.
        ManufacturingSetupPage.OpenEdit();
        ManufacturingSetupPage.GoToRecord(ManufacturingSetup);

        // [THEN] Manual Scheduling is Visible on Manufacturing Setup page.
        Assert.IsTrue(
            ManufacturingSetupPage."Manual Scheduling".Visible(),
            StrSubstNo(
                FieldMustBeVisibleErr,
                ManufacturingSetupPage."Manual Scheduling".Caption(),
                ManufacturingSetupPage.Caption()));

        // [THEN] Manual Scheduling is Enabled on Manufacturing Setup page.
        Assert.IsTrue(
            ManufacturingSetupPage."Manual Scheduling".Enabled(),
            StrSubstNo(
                FieldMustBeEnabledErr,
                ManufacturingSetupPage."Manual Scheduling".Caption(),
                ManufacturingSetupPage.Caption()));

        // [THEN] Safety Lead Time for man. Sch. is Visible on Manufacturing Setup page.
        Assert.IsTrue(
            ManufacturingSetupPage."Safety Lead Time for Man. Sch.".Visible(),
            StrSubstNo(
                FieldMustBeVisibleErr,
                ManufacturingSetupPage."Safety Lead Time for Man. Sch.".Caption(),
                ManufacturingSetupPage.Caption()));

        // [THEN] Safety Lead Time for man. Sch. is Enabled on Manufacturing Setup page.
        Assert.IsTrue(
            ManufacturingSetupPage."Safety Lead Time for Man. Sch.".Enabled(),
            StrSubstNo(
                FieldMustBeEnabledErr,
                ManufacturingSetupPage."Safety Lead Time for Man. Sch.".Caption(),
                ManufacturingSetupPage.Caption()));
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfEndDateGreatThanDueDateIsEnteredOnProdOrderLineThanDueDateIsCalcBySafetyLeadTimeForManSchIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date greater than Due Date is entered on Released Prod. Order Lines page then
        // Due Date is equal to Safety Lead Time for Man. Sch. added to Ending Date if 
        // Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", ReleasedProdOrderLines."Due Date".AsDate());

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate);

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Prod. Order Lines page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ReleasedProdOrderLines."Ending Date".Caption(),
                ReleasedProdOrderLines."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Due Date"),
                DueDate));
        ReleasedProdOrderLines."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);

        // [WHEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");

        // [THEN] Manual Scheduling is true in Production Order.
        Assert.IsTrue(ProductionOrder."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProductionOrder.TableCaption()));

        // [WHEN] Find Prod. Order Line.
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] Manual Scheduling is true in Prod. Order Line.
        Assert.IsTrue(ProdOrderLine."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProdOrderLine.TableCaption()));
        ReleasedProdOrderLines.Close();
    end;

    [Test]
    procedure IfEndDateLessThanDueDateIsEnteredOnProdOrderLineThanDueDateRemainsSameIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date less than Due Date is entered on Released Prod. Order Lines page then
        // Due Date remains same if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<-2D>', ReleasedProdOrderLines."Due Date".AsDate());

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := ReleasedProdOrderLines."Due Date".AsDate();

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Prod. Order Lines page.
        ReleasedProdOrderLines."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);
        ReleasedProdOrderLines.Close();
    end;

    [Test]
    procedure IfEndDateLessThanOldEndDateIsEnteredOnProdOrderLineThanDueDateRemainsSameIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date less than the old Ending Date is entered on Released Prod. Order Lines page then
        // Due Date remains same if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<-1D>', ReleasedProdOrderLines."Ending Date".AsDate());

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := ReleasedProdOrderLines."Due Date".AsDate();

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Prod. Order Lines page.
        ReleasedProdOrderLines."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);
        ReleasedProdOrderLines.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfEndDateSameAsDueDateIsEnteredOnProdOrderLineThanDueDateIsCalcBySafetyLeadTimeForManSchIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date same as Due Date is entered on Released Prod. Order Lines page then
        // Due Date is equal to Safety Lead Time for Man. Sch. added to Ending Date if 
        // Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := ReleasedProdOrderLines."Due Date".AsDate();

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate);

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Prod. Order Lines page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ReleasedProdOrderLines."Ending Date".Caption(),
                ReleasedProdOrderLines."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Due Date"),
                DueDate));
        ReleasedProdOrderLines."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);

        // [WHEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");

        // [THEN] Manual Scheduling is true in Production Order.
        Assert.IsTrue(ProductionOrder."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProductionOrder.TableCaption()));

        // [WHEN] Find Prod. Order Line.
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] Manual Scheduling is true in Prod. Order Line.
        Assert.IsTrue(ProdOrderLine."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProdOrderLine.TableCaption()));
        ReleasedProdOrderLines.Close();
    end;

    [Test]
    procedure IfDueDateGreatThanEndDateIsEnteredOnProdOrderThanEndDateRemainsSameIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Due Date greater than Ending Date is entered on Released Production Order page then
        // Ending Date remains same if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := ProductionOrder."Ending Date";

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate('<3D>', EndingDate);

        // [WHEN] Set DueDate value in Due Date field of Released Production Order page.
        ReleasedProductionOrder."Due Date".SetValue(DueDate);

        // [THEN] Ending Date in Production Order is equal to EndingDate.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            EndingDate,
            ProductionOrder."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Ending Date"), EndingDate, ProductionOrder.TableCaption()));
        ReleasedProductionOrder.Close();

        // [WHEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [THEN] Ending Date in Prod. Order Line is equal to EndingDate.
        Assert.AreEqual(
            EndingDate,
            ProdOrderLine."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProdOrderLine.FieldCaption("Ending Date"), EndingDate, ProdOrderLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfDueDateLessThanEndDateIsEnteredOnProdOrderThanEndDateIsCalcBySafetyLeadTimeForManSchIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Due Date less than Ending Date is entered on Released Production Order page then
        // Ending Date is equal to Safety Lead Time for Man. Sch. reduced from Due Date if 
        // Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate('<-3D>', ProductionOrder."Ending Date");

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate(Format('-') + Format(ManufacturingSetup."Safety Lead Time for Man. Sch."), DueDate);

        // [WHEN] Set DueDate value in Due Date field of Released Production Order page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProductionOrder.FieldCaption("Ending Date"),
                ReleasedProductionOrder."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Ending Date"),
                EndingDate));
        ReleasedProductionOrder."Due Date".SetValue(DueDate);

        // [THEN] Ending Date in Production Order is equal to EndingDate.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            EndingDate,
            ProductionOrder."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Ending Date"), EndingDate, ProductionOrder.TableCaption()));

        // [THEN] Ending Date in Prod. Order Line is equal to EndingDate.
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            EndingDate,
            ProdOrderLine."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProdOrderLine.FieldCaption("Ending Date"), EndingDate, ProdOrderLine.TableCaption()));

        // [THEN] Manual Scheduling is true in Production Order.
        Assert.IsTrue(ProductionOrder."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProductionOrder.TableCaption()));

        // [THEN] Manual Scheduling is true in Prod. Order Line.
        Assert.IsTrue(ProdOrderLine."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProdOrderLine.TableCaption()));
        ReleasedProductionOrder.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfDueDateSameAsEndDateIsEnteredOnProdOrderThanEndDateIsCalcBySafetyLeadTimeForManSchIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Due Date same as Ending Date is entered on Released Production Order page then
        // Ending Date is equal to Safety Lead Time for Man. Sch. reduced from Due Date if 
        // Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := ProductionOrder."Ending Date";

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate(Format('-') + Format(ManufacturingSetup."Safety Lead Time for Man. Sch."), DueDate);

        // [WHEN] Set DueDate value in Due Date field of Released Production Order page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProductionOrder.FieldCaption("Ending Date"),
                ReleasedProductionOrder."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Ending Date"),
                EndingDate));
        ReleasedProductionOrder."Due Date".SetValue(DueDate);

        // [THEN] Ending Date in Production Order is equal to EndingDate.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            EndingDate,
            ProductionOrder."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Ending Date"), EndingDate, ProductionOrder.TableCaption()));

        // [THEN] Ending Date in Prod. Order Line is equal to EndingDate.
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            EndingDate,
            ProdOrderLine."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProdOrderLine.FieldCaption("Ending Date"), EndingDate, ProdOrderLine.TableCaption()));

        // [THEN] Manual Scheduling is true in Production Order.
        Assert.IsTrue(ProductionOrder."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProductionOrder.TableCaption()));

        // [THEN] Manual Scheduling is true in Prod. Order Line.
        Assert.IsTrue(ProdOrderLine."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProdOrderLine.TableCaption()));
        ReleasedProductionOrder.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfEndDateGreatThanDueDateIsEnteredOnProdOrderLineSrcTypeSalesThanEndDateIsCalcBySafetyLeadTimeForManSchIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        EndingDate: Date;
        DueDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date greater than Due Date is entered on Released Prod. Order Lines page then
        // System should not allow to change the Due Date greater than previous due date
        // if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<5D>', ProdOrderLine."Due Date");

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate);

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Prod. Order Lines page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProductionOrder.FieldCaption("Ending Date"),
                ReleasedProdOrderLines."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Due Date"),
                DueDate));
        asserterror ReleasedProdOrderLines."Ending Date-Time".SetValue(EndingDate);

        // [THEN] System should throw Date conflict error.
        Assert.ExpectedError(
            StrSubstNo(
                DateConflictErr,
                LibraryRandom.RandInt(0),
                CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate)));
        ReleasedProdOrderLines.Close();
    end;

    [Test]
    procedure IfEndDateLessThanDueDateIsEnteredOnProdOrderLineSrcTypeSalesThanDueDateRemainsSameIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date less than Due Date is entered on Released Prod. Order Lines page then
        // Due Date remains same if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<-3D>', ProdOrderLine."Due Date");

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := ReleasedProdOrderLines."Due Date".AsDate();

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Prod. Order Lines page.
        ReleasedProdOrderLines."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);
        ReleasedProdOrderLines.Close();
    end;

    [Test]
    procedure IfEndDateLessThanOldEndDateIsEnteredOnProdOrderLineSrcTypeSalesThanDueDateRemainsSameIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date less than Due Date is entered on Released Prod. Order Lines page then
        // Due Date remains same if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line and Validate Status.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<-3D>', ProdOrderLine."Ending Date");

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := ReleasedProdOrderLines."Due Date".AsDate();

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Prod. Order Lines page.
        ReleasedProdOrderLines."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);
        ReleasedProdOrderLines.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfEndDateSameAsDueDateIsEnteredOnProdOrderLineSrcTypeSalesThanDueDateIsCalcBySafetyLeadTimeForManSchIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date same as Due Date is entered on Released Prod. Order Lines page then
        // System should not allow to change the Due Date greater than previous due date
        // if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line. and Validate Status.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := ProductionOrder."Due Date";

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate);

        // [WHEN] Set EndingDate value in Ending Date - Time Date field of Released Prod. Order Lines page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProdOrderLine.FieldCaption("Ending Date"),
                ReleasedProdOrderLines."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Due Date"),
                DueDate));
        asserterror ReleasedProdOrderLines."Ending Date-Time".SetValue(EndingDate);

        // [THEN] System should throw Date conflict error.
        Assert.ExpectedError(
            StrSubstNo(
                DateConflictErr,
                LibraryRandom.RandInt(0),
                CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate)));
        ReleasedProdOrderLines.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfDueDateLessThanEndDateIsEnteredOnProdOrderSrcTypeSalesThanEndDateIsCalcBySafetyLeadTimeForManSchIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProdOrder: TestPage "Released Production Order";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Due Date less than Ending Date is entered on Released Production Order page then
        // Ending Date is equal to Safety Lead Time for Man. Sch. reduced from Due Date if 
        // Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order page.
        ReleasedProdOrder.OpenEdit();
        ReleasedProdOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate('<-3D>', ProdOrderLine."Ending Date");

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<-2D>', DueDate);

        // [WHEN] Change Due Date in Production Order.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProductionOrder.FieldCaption("Ending Date"),
                ProductionOrder.FieldCaption("Due Date"),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Ending Date"),
                EndingDate));
        ReleasedProdOrder."Due Date".SetValue(DueDate);

        // [THEN] Ending Date in Production Order is equal to EndingDate.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            EndingDate,
            ProductionOrder."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Ending Date"), EndingDate, ProductionOrder.TableCaption()));

        // [THEN] Due Date in Released Prod. Order page is equal to DueDate.
        ReleasedProdOrder."Due Date".AssertEquals(DueDate);
        ReleasedProdOrder.Close();

        // [THEN] Ending Date in Prod. Order Line is equal to EndingDate.
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            EndingDate,
            ProdOrderLine."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProdOrderLine.FieldCaption("Ending Date"), EndingDate, ProdOrderLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfDueDateSameAsEndDateIsEnteredOnProdOrderSrcTypeSalesThanEndDateIsCalcBySafetyLeadTimeForManSchIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Due Date is same as Ending Date is entered on Released Production Order page then
        // Ending Date is equal to Safety Lead Time for Man. Sch. reduced from Due Date if 
        // Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        LibraryPlanning.SetDefaultSafetyLeadTime('<5D>');

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Due Date in a Variable.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        DueDate := ProductionOrder."Ending Date";

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate(Format('-') + Format(ManufacturingSetup."Safety Lead Time for Man. Sch."), DueDate);

        // [WHEN] Set DueDate value in Due Date field of Released Production Order page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProductionOrder.FieldCaption("Ending Date"),
                ProductionOrder.FieldCaption("Due Date"),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Ending Date"),
                EndingDate));
        ReleasedProductionOrder."Due Date".SetValue(DueDate);

        // [THEN] Ending Date in Production Order is equal to EndingDate.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            EndingDate,
            ProductionOrder."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Ending Date"), EndingDate, ProductionOrder.TableCaption()));

        // [THEN] Ending Date in Prod. Order Line is equal to EndingDate.
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            EndingDate,
            ProdOrderLine."Ending Date",
            StrSubstNo(ValueMustBeEqualErr, ProdOrderLine.FieldCaption("Ending Date"), EndingDate, ProdOrderLine.TableCaption()));

        // [THEN] Manual Scheduling is true in Production Order.
        Assert.IsTrue(ProductionOrder."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProductionOrder.TableCaption()));

        // [THEN] Manual Scheduling is true in Prod. Order Line.
        Assert.IsTrue(ProdOrderLine."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProdOrderLine.TableCaption()));
        ReleasedProductionOrder.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfEndDateGreatThanDueDateIsEnteredOnProdOrderThanDueDateIsCalcBySafetyLeadTimeForManSchIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date greater than Due Date is entered on Released Production Order page then
        // Due Date is equal to Safety Lead Time for Man. Sch. added to Ending Date if 
        // Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", ReleasedProductionOrder."Due Date".AsDate());

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate);

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Production Order page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProductionOrder.FieldCaption("Ending Date"),
                ReleasedProductionOrder."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Due Date"),
                DueDate));
        ReleasedProductionOrder."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Production Order page is equal to DueDate.
        ReleasedProductionOrder."Due Date".AssertEquals(DueDate);

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [WHEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [THEN] Due Date of Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);

        // [WHEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");

        // [THEN] Manual Scheduling is true in Production Order.
        Assert.IsTrue(ProductionOrder."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProductionOrder.TableCaption()));

        // [WHEN] Find Prod. Order Line.
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] Manual Scheduling is true in Prod. Order Line.
        Assert.IsTrue(ProdOrderLine."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProdOrderLine.TableCaption()));
        ReleasedProductionOrder.Close();
    end;

    [Test]
    procedure IfEndDateLessThanDueDateIsEnteredOnProdOrderThanDueDateRemainsSameIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date less than Due Date is entered on Released Production Order page then
        // Due Date remains same if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<-2D>', ReleasedProductionOrder."Due Date".AsDate());

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := ReleasedProductionOrder."Due Date".AsDate();

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Production Order page.
        ReleasedProductionOrder."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Production Order page is equal to DueDate.
        ReleasedProductionOrder."Due Date".AssertEquals(DueDate);
        ReleasedProductionOrder.Close();

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [WHEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [THEN] Due Date of Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);
    end;

    [Test]
    procedure IfEndDateLessThanOldEndDateIsEnteredOnProdOrderThanDueDateRemainsSameIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date less than the old Ending Date is entered on Released Production Order page then
        // Due Date remains same if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<-1D>', DT2Date(ReleasedProductionOrder."Ending Date-Time".AsDateTime()));

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := ReleasedProductionOrder."Due Date".AsDate();

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Production Order page.
        ReleasedProductionOrder."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Production Order page is equal to DueDate.
        ReleasedProductionOrder."Due Date".AssertEquals(DueDate);
        ReleasedProductionOrder.Close();

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [WHEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [THEN] Due Date of Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfEndDateSameAsDueDateIsEnteredOnProdOrderThanDueDateIsCalcBySafetyLeadTimeForManSchIfManualSchedulingIsTrue()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date same as Due Date is entered on Released Production Order page then
        // Due Date is equal to Safety Lead Time for Man. Sch. added to Ending Date if 
        // Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := ReleasedProductionOrder."Due Date".AsDate();

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate);

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Production Order page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProductionOrder.FieldCaption("Ending Date"),
                ReleasedProductionOrder."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Due Date"),
                DueDate));
        ReleasedProductionOrder."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Production Order page is equal to DueDate.
        ReleasedProductionOrder."Due Date".AssertEquals(DueDate);

        // [WHEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [THEN] Due Date of Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);

        // [WHEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");

        // [THEN] Manual Scheduling is true in Production Order.
        Assert.IsTrue(ProductionOrder."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProductionOrder.TableCaption()));

        // [WHEN] Find Prod. Order Line.
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] Manual Scheduling is true in Prod. Order Line.
        Assert.IsTrue(ProdOrderLine."Manual Scheduling", StrSubstNo(ManualSchedulingMustBeTrueErr, ProdOrderLine.TableCaption()));
        ReleasedProductionOrder.Close();
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfEndDateGreatThanDueDateIsEnteredOnProdOrderSrcTypeSalesThanEndDateIsCalcBySafetyLeadTimeForManSchIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        EndingDate: Date;
        DueDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date greater than Due Date is entered on Released Production Order page then
        // System should not allow to change the Due Date greater than previous due date
        // if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<5D>', ProductionOrder."Due Date");

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate);

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Production Order page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProductionOrder.FieldCaption("Ending Date"),
                ReleasedProductionOrder."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Due Date"),
                DueDate));
        asserterror ReleasedProductionOrder."Ending Date-Time".SetValue(EndingDate);

        // [THEN] System should throw Date conflict error.
        Assert.ExpectedError(
            StrSubstNo(
                DateConflictErr,
                LibraryRandom.RandInt(0),
                CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate)));
        ReleasedProductionOrder.Close();
    end;

    [Test]
    procedure IfEndDateLessThanDueDateIsEnteredOnProdOrderSrcTypeSalesThanDueDateRemainsSameIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date less than Due Date is entered on Released Production Order page then
        // Due Date remains same if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<-3D>', ProductionOrder."Due Date");

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := ReleasedProductionOrder."Due Date".AsDate();

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Production Order page.
        ReleasedProductionOrder."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Production Order page is equal to DueDate.
        ReleasedProductionOrder."Due Date".AssertEquals(DueDate);
        ReleasedProductionOrder.Close();

        // [WHEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [THEN] Due Date of Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);
    end;

    [Test]
    procedure IfEndDateLessThanOldEndDateIsEnteredOnProdOrderSrcTypeSalesThanDueDateRemainsSameIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ReleasedProdOrderLines: TestPage "Released Prod. Order Lines";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date less than Due Date is entered on Released Production Order page then
        // Due Date remains same if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line and Validate Status.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Prod. Order Lines page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := CalcDate('<-3D>', ProductionOrder."Ending Date");

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := ReleasedProductionOrder."Due Date".AsDate();

        // [WHEN] Set EndingDate value in Ending Date - Time field of Released Production Order page.
        ReleasedProductionOrder."Ending Date-Time".SetValue(EndingDate);

        // [THEN] Due Date in Released Production Order page is equal to DueDate.
        ReleasedProductionOrder."Due Date".AssertEquals(DueDate);
        ReleasedProductionOrder.Close();

        // [WHEN] Open Released Prod. Order Lines page.
        ReleasedProdOrderLines.OpenEdit();
        ReleasedProdOrderLines.GoToRecord(ProdOrderLine);

        // [THEN] Due Date of Released Prod. Order Lines page is equal to DueDate.
        ReleasedProdOrderLines."Due Date".AssertEquals(DueDate);
    end;

    [Test]
    [HandlerFunctions('VerifyMessageFromConfirmHandlerTrue')]
    procedure IfEndDateSameAsDueDateIsEnteredOnProdOrderSrcTypeSalesThanDueDateIsCalcBySafetyLeadTimeForManSchIfManualSchIsTrue()
    var
        Item: array[2] of Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        DueDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 317246] If Ending Date same as Due Date is entered on Released Production Order page then
        // System should not allow to change the Due Date greater than previous due date
        // if Manual Scheduling is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Find Manufacturing Setup.
        ManufacturingSetup.Get();

        // [GIVEN] Validate Manual Scheduling and Safety Lead Time for Man. Sch. in Manufacturing Setup.
        ManufacturingSetup.Validate("Manual Scheduling", true);
        Evaluate(ManufacturingSetup."Safety Lead Time for Man. Sch.", '<2D>');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item [1] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', '');

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line. and Validate Status.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create an Item and Validate Replenishment System, Manufacturing Policy and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(0), '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrderWithSalesSourceType(ProductionOrder, ProductionOrder.Status::Released, SalesHeader."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Released Production Order page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Generate and save Ending Date in a Variable.
        EndingDate := ReleasedProductionOrder."Due Date".AsDate();

        // [GIVEN] Generate and save Due Date in a Variable.
        DueDate := CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate);

        // [WHEN] Set EndingDate value in Ending Date - Time Date field of Released Production Order page.
        LibraryVariableStorage.Enqueue(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst,
                ProductionOrder.FieldCaption("Ending Date"),
                ReleasedProductionOrder."Due Date".Caption(),
                ProdOrderLine.TableCaption(),
                ProdOrderLine.Status,
                ProdOrderLine."Prod. Order No.",
                ProdOrderLine."Line No.",
                ProdOrderLine.FieldCaption("Due Date"),
                DueDate));
        asserterror ReleasedProductionOrder."Ending Date-Time".SetValue(EndingDate);

        // [THEN] System should throw Date conflict error.
        Assert.ExpectedError(
            StrSubstNo(
                DateConflictErr,
                LibraryRandom.RandInt(0),
                CalcDate(ManufacturingSetup."Safety Lead Time for Man. Sch.", EndingDate)));
        ReleasedProductionOrder.Close();
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandlerTrue,MessageHandler,ReleasedProdOrderPageHandler')]
    procedure VerifyCostIsAdjustedMustBeFalseInInventoryAdjmtEntryOrderWhenReopenProductionOrder()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        FinishedProductionOrder: TestPage "Finished Production Order";
    begin
        // [SCENARIO 563303] Verify "Cost is Adjusted" must be false after reopen production order in "Inventory Adjmt. Entry (Order)".
        Initialize();

        // [GIVEN] Set location code in Manufacturing Setup.
        LibraryManufacturing.SetComponentsAtLocation('');

        // [GIVEN] Create an Item with BOM and Routing.
        CreateItemWithBOMAndRouting(Item, ChildItem, LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, ChildItem."No.", LibraryRandom.RandIntInRange(10, 50), '', '', LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Find Released Production Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");

        // [GIVEN] Open and Post Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] "Is Finished" must be true when status is changed to Finished.
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            true,
            InventoryAdjmtEntryOrder."Is Finished",
            StrSubstNo(ValueMustBeEqualErr, InventoryAdjmtEntryOrder.FieldCaption("Is Finished"), true, InventoryAdjmtEntryOrder.TableCaption()));

        // [THEN] "Cost is Adjusted" must be false when status is changed to Finished.
        Assert.AreEqual(
            false,
            InventoryAdjmtEntryOrder."Cost is Adjusted",
            StrSubstNo(ValueMustBeEqualErr, InventoryAdjmtEntryOrder.FieldCaption("Cost is Adjusted"), false, InventoryAdjmtEntryOrder.TableCaption()));

        // [WHEN] Run Adjust Cost Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] "Cost is Adjusted" must be true when Adjust Cost Item Entries is executed.
        Item.Get(Item."No.");
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            true,
            InventoryAdjmtEntryOrder."Cost is Adjusted",
            StrSubstNo(ValueMustBeEqualErr, InventoryAdjmtEntryOrder.FieldCaption("Cost is Adjusted"), true, InventoryAdjmtEntryOrder.TableCaption()));
        Assert.AreEqual(
            true,
            Item."Cost is Adjusted",
            StrSubstNo(ValueMustBeEqualErr, Item.FieldCaption("Cost is Adjusted"), true, Item.TableCaption()));

        // [GIVEN] Get Finished Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [WHEN] Execute "ReopenFinishProdOrder" action.
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.GoToRecord(ProductionOrder);
        FinishedProductionOrder.ReopenFinishedProdOrder.Invoke();

        // [THEN] "Is Finished" and "Cost is Adjusted" must be false when reopen the production order in Item and "Inventory Adjmt. Entry (Order)".
        Item.Get(Item."No.");
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            false,
            InventoryAdjmtEntryOrder."Is Finished",
            StrSubstNo(ValueMustBeEqualErr, InventoryAdjmtEntryOrder.FieldCaption("Is Finished"), false, InventoryAdjmtEntryOrder.TableCaption()));
        Assert.AreEqual(
            false,
            InventoryAdjmtEntryOrder."Cost is Adjusted",
            StrSubstNo(ValueMustBeEqualErr, InventoryAdjmtEntryOrder.FieldCaption("Cost is Adjusted"), false, InventoryAdjmtEntryOrder.TableCaption()));
        Assert.AreEqual(
            false,
            Item."Cost is Adjusted",
            StrSubstNo(ValueMustBeEqualErr, Item.FieldCaption("Cost is Adjusted"), false, Item.TableCaption()));

        // [GIVEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run Adjust Cost Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] "Cost is Adjusted" must be true when Adjust Cost Item Entries is executed.
        Item.Get(Item."No.");
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            true,
            InventoryAdjmtEntryOrder."Cost is Adjusted",
            StrSubstNo(ValueMustBeEqualErr, InventoryAdjmtEntryOrder.FieldCaption("Cost is Adjusted"), true, InventoryAdjmtEntryOrder.TableCaption()));
        Assert.AreEqual(
            true,
            Item."Cost is Adjusted",
            StrSubstNo(ValueMustBeEqualErr, Item.FieldCaption("Cost is Adjusted"), true, Item.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyCostFieldsMustBePopulatedInSKUFromProductionItem()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        CompItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
        CompUnitCost: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedOvhdCost: Decimal;
        IndirectCostPer: Decimal;
    begin
        // [SCENARIO 565590] Verify Cost Fields must be populated in SKU from production item.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Component item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create Production Item, Non-Inventory, Component Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(OutputItem, NonInvItem, CompItem);

        // [GIVEN] Save Quantity, Indirect%, Non-Inventory and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := LibraryRandom.RandIntInRange(20, 20);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (NonInvUnitCost + CompUnitCost) * IndirectCostPer / 100;
        ExpectedStandardCost := NonInvUnitCost + CompUnitCost + ExpectedOvhdCost;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and Component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem, Quantity, CompUnitCost);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [WHEN] Calculate Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [THEN] Verify Cost fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(
            OutputItem,
            ExpectedStandardCost,
            CompUnitCost,
            CompUnitCost,
            NonInvUnitCost,
            NonInvUnitCost,
            ExpectedOvhdCost,
            ExpectedOvhdCost);

        // [GIVEN] Create Semi-Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(OutputItem, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [WHEN] Find Semi-Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", OutputItem."No.");
        StockkeepingUnit.FindFirst();

        // [THEN] Verify Cost Fields must be populated to SKU from production item.
        VerifyCostFieldsInSKU(
            StockkeepingUnit,
            ExpectedStandardCost,
            CompUnitCost,
            CompUnitCost,
            NonInvUnitCost,
            NonInvUnitCost,
            ExpectedOvhdCost,
            ExpectedOvhdCost);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyCostFieldsMustBeUpdatedInSKUWhenRevaluationJournalIsPosted()
    var
        OutputItem: Record Item;
        CompItem: Record Item;
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        RevaluationItemJournalBatch: Record "Item Journal Batch";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        CompUnitCost: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedOvhdCost: Decimal;
        IndirectCostPer: Decimal;
        RevaluedUnitCost: Decimal;
    begin
        // [SCENARIO 565590] Verify Cost Fields must be updated in SKU When Revaluation Journal is posted.
        Initialize();

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Production Item, Component Item with Production BOM.
        CreateProductionItemWithInvItemAndProductionBOM(OutputItem, CompItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity, Indirect%, Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := LibraryRandom.RandIntInRange(20, 20);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (CompUnitCost * IndirectCostPer) / 100;
        ExpectedStandardCost := CompUnitCost + ExpectedOvhdCost;
        RevaluedUnitCost := ExpectedStandardCost + CompUnitCost;

        // [GIVEN] Create and Post Purchase Document for Component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem, Quantity, CompUnitCost);

        // [GIVEN] Update "Costing Method", "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [GIVEN] Calculate Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [GIVEN] Create Semi-Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(OutputItem, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Semi-Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", OutputItem."No.");
        StockkeepingUnit.SetRange("Location Code", Location.Code);
        StockkeepingUnit.FindFirst();

        // [GIVEN] Create and Post Item Journal with Location Code.
        CreateAndPostItemJournalLine(OutputItem."No.", Quantity, '', '');
        CreateAndPostItemJournalLine(OutputItem."No.", Quantity, '', Location.Code);

        // [GIVEN] Revaluation Journal Setup.
        RevaluationJournalSetup(RevaluationItemJournalBatch);

        // [GIVEN] Calculate Inventory Value.
        CalculateInventoryValue(RevaluationItemJournalBatch, OutputItem);

        // [GIVEN] Update Revaluation Item Journal.
        UpdateRevaluationJournalLine(OutputItem."No.", '', RevaluedUnitCost);
        UpdateRevaluationJournalLine(OutputItem."No.", Location.Code, RevaluedUnitCost);

        // [WHEN] Post Revaluation Item Journal.
        LibraryInventory.PostItemJournalLine(RevaluationItemJournalBatch."Journal Template Name", RevaluationItemJournalBatch.Name);

        // [THEN] Verify Cost fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, RevaluedUnitCost, RevaluedUnitCost, RevaluedUnitCost, 0, 0, 0, 0);

        // [THEN] Verify Cost Fields must be updated in SKU When Revaluation Journal is posted.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");
        VerifyCostFieldsInSKU(StockkeepingUnit, RevaluedUnitCost, RevaluedUnitCost, RevaluedUnitCost, 0, 0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyStandardCostMustBeUpdatedInSKUIfNonInventoryExistInProductionBOM()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        CompItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
        CompUnitCost: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedOvhdCost: Decimal;
        IndirectCostPer: Decimal;
    begin
        // [SCENARIO 565590] Verify "Standard Cost" must be updated in SKU if Non-Inventory item must be exist in "Production BOM".
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Component item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create Production Item, Non-Inventory, Component Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(OutputItem, NonInvItem, CompItem);

        // [GIVEN] Save Quantity, Indirect%, Non-Inventory and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := LibraryRandom.RandIntInRange(20, 20);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (NonInvUnitCost + CompUnitCost) * IndirectCostPer / 100;
        ExpectedStandardCost := NonInvUnitCost + CompUnitCost + ExpectedOvhdCost;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and Component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem, Quantity, CompUnitCost);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [WHEN] Calculate Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [THEN] Verify Cost fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(
            OutputItem,
            ExpectedStandardCost,
            CompUnitCost,
            CompUnitCost,
            NonInvUnitCost,
            NonInvUnitCost,
            ExpectedOvhdCost,
            ExpectedOvhdCost);

        // [GIVEN] Create Semi-Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(OutputItem, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Semi-Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", OutputItem."No.");
        StockkeepingUnit.FindFirst();

        // [WHEN] Update "Standard Cost" in SKU.
        StockkeepingUnit.Validate("Standard Cost", ExpectedStandardCost + NonInvUnitCost);

        // [THEN] Verify "Standard Cost" must be updated in SKU.
        VerifyCostFieldsInSKU(StockkeepingUnit, ExpectedStandardCost + NonInvUnitCost, ExpectedStandardCost + NonInvUnitCost, ExpectedStandardCost + NonInvUnitCost, 0, 0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyNonInventoryMaterialCostValueMustBeShownInProductionOrderStatistics()
    var
        OutputItem: Record Item;
        CompItem: Record Item;
        NonInvItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
        Quantity: Decimal;
        CompUnitCost: Decimal;
        NonInvUnitCost: Decimal;
        BOMCompQuantityPer: Decimal;
        BOMNonInvQuantityPer: Decimal;
        ExpectedCompQuantityPer: Decimal;
        ExpectedNonInvQuantityPer: Decimal;
        ActualCompQuantityPer: Decimal;
        ActualNonInvQuantityPer: Decimal;
    begin
        // [SCENARIO 565137] Verify "Non Inventory-Material Cost" must be shown in "Production Order Statistics" page for production item When Non-Inventory and Component item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Save Quantity, Quantity Per, Component and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CompUnitCost := LibraryRandom.RandIntInRange(100, 200);
        NonInvUnitCost := LibraryRandom.RandIntInRange(100, 200);
        BOMCompQuantityPer := LibraryRandom.RandIntInRange(1, 5);
        BOMNonInvQuantityPer := LibraryRandom.RandIntInRange(5, 10);
        ExpectedCompQuantityPer := LibraryRandom.RandIntInRange(10, 20);
        ExpectedNonInvQuantityPer := LibraryRandom.RandIntInRange(10, 20);
        ActualCompQuantityPer := LibraryRandom.RandIntInRange(20, 30);
        ActualNonInvQuantityPer := LibraryRandom.RandIntInRange(20, 30);

        // [GIVEN] Create Component item with Unit Cost.
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Unit Cost", CompUnitCost);
        CompItem.Modify();

        // [GIVEN] Create Non-Inventory item with Unit Cost.
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);
        NonInvItem.Validate("Unit Cost", NonInvUnitCost);
        NonInvItem.Modify();

        // [GIVEN] Create Output item.
        LibraryInventory.CreateItem(OutputItem);

        // [GIVEN] Create Production BOM with component and non-inventory item.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, OutputItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, NonInvItem."No.", BOMNonInvQuantityPer);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", BOMCompQuantityPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Update "Production BOM No." in Output item.
        OutputItem.Validate("Replenishment System", OutputItem."Replenishment System"::"Prod. Order");
        OutputItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        OutputItem.Modify();

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Create and Post Purchase Document for Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem, Quantity, CompUnitCost);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Output Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", LibraryRandom.RandIntInRange(1, 1), '', '');

        // [GIVEN] Update "Quantity Per" in Production Component for Non-inventory item.
        UpdateQuantityPerInProductionOrderComponent(ProdOrderComponent, ProductionOrder, NonInvItem."No.", ExpectedNonInvQuantityPer);

        // [GIVEN] Create and Post Consumption Journal for Non-inventory item.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ActualNonInvQuantityPer);

        // [GIVEN] Update "Quantity Per" in Production Component for Inventory item.
        UpdateQuantityPerInProductionOrderComponent(ProdOrderComponent, ProductionOrder, CompItem."No.", ExpectedCompQuantityPer);

        // [GIVEN] Create and Post Consumption Journal for Inventory item.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ActualCompQuantityPer);

        // [WHEN] Open Production Order Statistics.
        ProductionOrderStatistics.OpenView();
        ProductionOrderStatistics.GoToRecord(ProductionOrder);

        // [THEN] Verify "Non Inventory-Material Cost" in "Production Order Statistics" page.
        ProductionOrderStatistics.NonInventoryMaterialCost_StandardCost.AssertEquals(NonInvUnitCost * BOMNonInvQuantityPer);
        ProductionOrderStatistics.NonInventoryMaterialCost_ExpectedCost.AssertEquals(NonInvUnitCost * ExpectedNonInvQuantityPer);
        ProductionOrderStatistics.NonInventoryMaterialCost_ActualCost.AssertEquals(NonInvUnitCost * ActualNonInvQuantityPer);
        ProductionOrderStatistics."NonInventoryVarPct".AssertEquals(CalcIndicatorPct(NonInvUnitCost * BOMNonInvQuantityPer, NonInvUnitCost * ActualNonInvQuantityPer));
        ProductionOrderStatistics."NonInventoryVarAmt".AssertEquals((NonInvUnitCost * ActualNonInvQuantityPer) - (NonInvUnitCost * BOMNonInvQuantityPer));

        // [THEN] Verify "Total Cost" in "Production Order Statistics" page.
        ProductionOrderStatistics.TotalCost_StandardCost.AssertEquals((NonInvUnitCost * BOMNonInvQuantityPer) + (CompUnitCost * BOMCompQuantityPer));
        ProductionOrderStatistics.TotalCost_ExpectedCost.AssertEquals((NonInvUnitCost * ExpectedNonInvQuantityPer) + (CompUnitCost * ExpectedCompQuantityPer));
        ProductionOrderStatistics.TotalCost_ActualCost.AssertEquals((NonInvUnitCost * ActualNonInvQuantityPer) + (CompUnitCost * ActualCompQuantityPer));
        ProductionOrderStatistics."VarPct[6]".AssertEquals(CalcIndicatorPct((NonInvUnitCost * BOMNonInvQuantityPer) + (CompUnitCost * BOMCompQuantityPer), (NonInvUnitCost * ActualNonInvQuantityPer) + (CompUnitCost * ActualCompQuantityPer)));
        ProductionOrderStatistics."VarAmt[6]".AssertEquals(((NonInvUnitCost * ActualNonInvQuantityPer) + (CompUnitCost * ActualCompQuantityPer)) - ((NonInvUnitCost * BOMNonInvQuantityPer) + (CompUnitCost * BOMCompQuantityPer)));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyCostAmountFieldsInProductionOrderStatistics()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        CompItem: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
        MfgStandardOvhdCost: Decimal;
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
        CompUnitCost1: Decimal;
        CompUnitCost2: Decimal;
        IndirectCostPer: Decimal;
        SLMatStandardCost: Decimal;
        StandardTotalCost: Decimal;
        ExpectedCompQuantityPer: Decimal;
        ExpectedNonInvQuantityPer: Decimal;
        ActualCompQuantityPer: Decimal;
        ActualNonInvQuantityPer: Decimal;
        ExpectedSemiOutputItemQuantityPer: Decimal;
        ActualSemiOutputItemQuantityPer: Decimal;
        MaterialExpectedCost: Decimal;
        MaterialActualCost: Decimal;
        VarianceMaterialAmt: Decimal;
        MfgOverheadExpectedCost: Decimal;
        MfgOverheadActualCost: Decimal;
        VarianceMfgOverheadAmt: Decimal;
    begin
        // [SCENARIO 565137] Verify "Non-Inventory Material Cost", "Material Cost","Total Cost" in "Production Order Statistics" page for production item 
        // When Semi-Output, Non-Inventory and Component item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create component items.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(SemiOutputItem, NonInvItem1, CompItem[1]);

        // [GIVEN] Save Quantity, Quantity Per, Component, Indirect% and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(100, 200);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(100, 200);
        CompUnitCost1 := LibraryRandom.RandIntInRange(100, 200);
        CompUnitCost2 := LibraryRandom.RandIntInRange(100, 200);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 20);
        MfgStandardOvhdCost := (NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2) * IndirectCostPer / 100;
        SLMatStandardCost := CompUnitCost1 + CompUnitCost2 + NonInvUnitCost1;
        StandardTotalCost := NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2 + MfgStandardOvhdCost;
        ExpectedCompQuantityPer := LibraryRandom.RandIntInRange(10, 20);
        ExpectedNonInvQuantityPer := LibraryRandom.RandIntInRange(10, 20);
        ExpectedSemiOutputItemQuantityPer := LibraryRandom.RandIntInRange(10, 20);
        ActualCompQuantityPer := LibraryRandom.RandIntInRange(20, 30);
        ActualNonInvQuantityPer := LibraryRandom.RandIntInRange(20, 30);
        ActualSemiOutputItemQuantityPer := LibraryRandom.RandIntInRange(20, 30);
        MaterialExpectedCost := CompUnitCost2 * ExpectedCompQuantityPer + (CompUnitCost1 + NonInvUnitCost1) * ExpectedSemiOutputItemQuantityPer;
        MaterialActualCost := CompUnitCost2 * ActualCompQuantityPer + (CompUnitCost1 + NonInvUnitCost1) * ActualSemiOutputItemQuantityPer;
        VarianceMaterialAmt := MaterialActualCost - SLMatStandardCost;
        MfgOverheadExpectedCost := (MaterialExpectedCost + (NonInvUnitCost2 * ExpectedNonInvQuantityPer)) * IndirectCostPer / 100;
        MfgOverheadActualCost := ((MaterialActualCost + (NonInvUnitCost2 * ActualNonInvQuantityPer)) * IndirectCostPer / 100);
        VarianceMfgOverheadAmt := MfgOverheadActualCost - MfgStandardOvhdCost;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[1], Quantity, CompUnitCost1);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);
        SemiOutputItem.Get(SemiOutputItem."No.");

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(OutputItem, NonInvItem2, SemiOutputItem, CompItem[2]);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory, component and Semi-Output item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[2], Quantity, CompUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(SemiOutputItem, Quantity, SemiOutputItem."Standard Cost");

        // [GIVEN] Update "Costing Method" Standard and "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", LibraryRandom.RandIntInRange(1, 1), '', '');

        // [GIVEN] Update "Quantity Per" in Production Component for Non-inventory item.
        UpdateQuantityPerInProductionOrderComponent(ProdOrderComponent, ProductionOrder, NonInvItem2."No.", ExpectedNonInvQuantityPer);

        // [GIVEN] Create and Post Consumption Journal for Non-inventory item.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ActualNonInvQuantityPer);

        // [GIVEN] Update "Quantity Per" in Production Component for Inventory item.
        UpdateQuantityPerInProductionOrderComponent(ProdOrderComponent, ProductionOrder, CompItem[2]."No.", ExpectedCompQuantityPer);

        // [GIVEN] Create and Post Consumption Journal for Inventory item.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ActualCompQuantityPer);

        // [GIVEN] Update "Quantity Per" in Production Component for Semi-Output item.
        UpdateQuantityPerInProductionOrderComponent(ProdOrderComponent, ProductionOrder, SemiOutputItem."No.", ExpectedSemiOutputItemQuantityPer);

        // [GIVEN] Create and Post Consumption Journal for Semi-Output item.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ActualSemiOutputItemQuantityPer);

        // [WHEN] Open Production Order Statistics.
        ProductionOrderStatistics.OpenView();
        ProductionOrderStatistics.GoToRecord(ProductionOrder);

        // [THEN] Verify "Material Cost" in "Production Order Statistics" page.
        ProductionOrderStatistics.MaterialCost_StandardCost.AssertEquals(SLMatStandardCost);
        ProductionOrderStatistics.MaterialCost_ExpectedCost.AssertEquals(MaterialExpectedCost);
        ProductionOrderStatistics.MaterialCost_ActualCost.AssertEquals(MaterialActualCost);
        ProductionOrderStatistics."VarPct[1]".AssertEquals(CalcIndicatorPct(SLMatStandardCost, MaterialActualCost));
        ProductionOrderStatistics."VarAmt[1]".AssertEquals(VarianceMaterialAmt);

        // [THEN] Verify "Non Inventory-Material Cost" in "Production Order Statistics" page.
        ProductionOrderStatistics.NonInventoryMaterialCost_StandardCost.AssertEquals(NonInvUnitCost2);
        ProductionOrderStatistics.NonInventoryMaterialCost_ExpectedCost.AssertEquals(NonInvUnitCost2 * ExpectedNonInvQuantityPer);
        ProductionOrderStatistics.NonInventoryMaterialCost_ActualCost.AssertEquals(NonInvUnitCost2 * ActualNonInvQuantityPer);
        ProductionOrderStatistics."NonInventoryVarPct".AssertEquals(CalcIndicatorPct(NonInvUnitCost2, NonInvUnitCost2 * ActualNonInvQuantityPer));
        ProductionOrderStatistics."NonInventoryVarAmt".AssertEquals((NonInvUnitCost2 * ActualNonInvQuantityPer) - (NonInvUnitCost2));

        // [THEN] Verify "Mfg Overhead Cost" in "Production Order Statistics" page.
        ProductionOrderStatistics."StdCost[5]".AssertEquals(MfgStandardOvhdCost);
        ProductionOrderStatistics.MfgOverhead_ExpectedCost.AssertEquals(MfgOverheadExpectedCost);
        ProductionOrderStatistics."ActCost[5]".AssertEquals(MfgOverheadActualCost);
        ProductionOrderStatistics."VarPct[5]".AssertEquals(CalcIndicatorPct(MfgStandardOvhdCost, MfgOverheadActualCost));
        ProductionOrderStatistics."VarAmt[5]".AssertEquals(VarianceMfgOverheadAmt);

        // [THEN] Verify "Total Cost" in "Production Order Statistics" page.
        ProductionOrderStatistics.TotalCost_StandardCost.AssertEquals(StandardTotalCost);
        ProductionOrderStatistics.TotalCost_ExpectedCost.AssertEquals(MaterialExpectedCost + (NonInvUnitCost2 * ExpectedNonInvQuantityPer) + MfgOverheadExpectedCost);
        ProductionOrderStatistics.TotalCost_ActualCost.AssertEquals(MaterialActualCost + (NonInvUnitCost2 * ActualNonInvQuantityPer) + MfgOverheadActualCost);
        ProductionOrderStatistics."VarPct[6]".AssertEquals(CalcIndicatorPct(StandardTotalCost, MaterialActualCost + (NonInvUnitCost2 * ActualNonInvQuantityPer) + MfgOverheadActualCost));
        ProductionOrderStatistics."VarAmt[6]".AssertEquals((MaterialActualCost + (NonInvUnitCost2 * ActualNonInvQuantityPer) + MfgOverheadActualCost) - StandardTotalCost);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyCostFieldsMustBeUpdatedInSKUWhenStockKeepingUnitIsManuallyCreated()
    var
        OutputItem: Record Item;
        CompItem: Record Item;
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        CompUnitCost: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedOvhdCost: Decimal;
        IndirectCostPer: Decimal;
    begin
        // [SCENARIO 567055] Verify Cost Fields must be updated in "Stockkeeping Unit" When "Stockkeeping Unit" is manually created.
        Initialize();

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Production Item, Component Item with Production BOM.
        CreateProductionItemWithInvItemAndProductionBOM(OutputItem, CompItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity, Indirect%, Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := LibraryRandom.RandIntInRange(20, 20);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (CompUnitCost * IndirectCostPer) / 100;
        ExpectedStandardCost := CompUnitCost + ExpectedOvhdCost;

        // [GIVEN] Create and Post Purchase Document for Component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem, Quantity, CompUnitCost);

        // [GIVEN] Update "Costing Method", "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [GIVEN] Calculate Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Create Semi-Stockkeeping Unit.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, OutputItem."No.", '');

        // [THEN] Verify Cost fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, ExpectedStandardCost, CompUnitCost, CompUnitCost, 0, 0, ExpectedOvhdCost, ExpectedOvhdCost);

        // [THEN] Verify Cost Fields must be updated in SKU.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");
        VerifyCostFieldsInSKU(StockkeepingUnit, ExpectedStandardCost, CompUnitCost, CompUnitCost, 0, 0, ExpectedOvhdCost, ExpectedOvhdCost);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyValueEntryShouldBeCreatedWithVarianceTypeMaterialNonInventoryForItemAndSKU()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        CompItem: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
        CompUnitCost: Decimal;
        ExpectedStandardCost: Decimal;
    begin
        // [SCENARIO 569037] Verify Value Entry should be created with "Variance Type" - "Material - Non Inventory" for Output item and StockKeeping Unit.
        Initialize();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Component item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create Production Item, Non-Inventory, Component Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(OutputItem, NonInvItem, CompItem);

        // [GIVEN] Save Quantity, Non-Inventory and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 100);
        CompUnitCost := LibraryRandom.RandIntInRange(20, 200);
        ExpectedStandardCost := NonInvUnitCost + CompUnitCost;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and Component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, LibraryRandom.RandIntInRange(100, 200), NonInvUnitCost);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem, LibraryRandom.RandIntInRange(100, 200), CompUnitCost);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [GIVEN] Calculate Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [GIVEN] Create Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(OutputItem, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Stockkeeping Unit.
        StockkeepingUnit.Get(Location.Code, OutputItem."No.", '');

        // [GIVEN] Create Released Production Order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);

        // [GIVEN] Create Prod Order Line with blank Location.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", OutputItem."No.", '', '', Quantity);

        // [GIVEN] Create Prod Order Line with Location.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", OutputItem."No.", '', Location.Code, Quantity);

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [GIVEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [WHEN] Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(OutputItem."No.", '');

        // [THEN] Verify Value Entry should be created with "Variance Type" - "Material - Non Inventory" for Output item.
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::Variance, OutputItem, '', 0, 0, (NonInvUnitCost * Quantity));
        VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder, "Item Ledger Entry Type"::Output, OutputItem, '', 0, ExpectedStandardCost * Quantity);

        // [THEN] Verify Value Entry should be created with "Variance Type" - "Material - Non Inventory" for SKU.
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::Variance, OutputItem, Location.Code, 0, 0, (NonInvUnitCost * Quantity));
        VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder, "Item Ledger Entry Type"::Output, OutputItem, Location.Code, 0, ExpectedStandardCost * Quantity);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyCostFieldsMustBeUpdatedInSKUIfNonInventoryItemExistInProdBOMWhenRevaluationJournalIsPosted()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        RevaluationItemJournalBatch: Record "Item Journal Batch";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedOvhdCost: Decimal;
        IndirectCostPer: Decimal;
        RevaluedUnitCost: Decimal;
    begin
        // [SCENARIO 567056] Verify Cost Fields must be updated in SKU If Non-Inventory item exist in Production BOM.
        // When Revaluation Journal is posted.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity, Indirect%, Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(20, 20);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (NonInvUnitCost * IndirectCostPer) / 100;
        ExpectedStandardCost := NonInvUnitCost + ExpectedOvhdCost;
        RevaluedUnitCost := ExpectedStandardCost + NonInvUnitCost;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Update "Costing Method", "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [WHEN] Calculate Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [THEN] Verify Cost fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, ExpectedStandardCost, 0, 0, NonInvUnitCost, NonInvUnitCost, ExpectedOvhdCost, ExpectedOvhdCost);

        // [GIVEN] Create Semi-Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(OutputItem, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [WHEN] Find Semi-Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", OutputItem."No.");
        StockkeepingUnit.SetRange("Location Code", Location.Code);
        StockkeepingUnit.FindFirst();

        // [THEN] Verify Cost fields in SKU.
        VerifyCostFieldsInSKU(StockkeepingUnit, ExpectedStandardCost, 0, 0, NonInvUnitCost, NonInvUnitCost, ExpectedOvhdCost, ExpectedOvhdCost);

        // [GIVEN] Create and Post Item Journal with Location Code.
        CreateAndPostItemJournalLine(OutputItem."No.", Quantity, '', '');
        CreateAndPostItemJournalLine(OutputItem."No.", Quantity, '', Location.Code);

        // [GIVEN] Revaluation Journal Setup.
        RevaluationJournalSetup(RevaluationItemJournalBatch);

        // [GIVEN] Calculate Inventory Value.
        CalculateInventoryValue(RevaluationItemJournalBatch, OutputItem);

        // [GIVEN] Update Revaluation Item Journal.
        UpdateRevaluationJournalLine(OutputItem."No.", '', RevaluedUnitCost);
        UpdateRevaluationJournalLine(OutputItem."No.", Location.Code, RevaluedUnitCost);

        // [WHEN] Post Revaluation Item Journal.
        LibraryInventory.PostItemJournalLine(RevaluationItemJournalBatch."Journal Template Name", RevaluationItemJournalBatch.Name);

        // [THEN] Verify Cost fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, RevaluedUnitCost, RevaluedUnitCost, RevaluedUnitCost, 0, 0, 0, 0);

        // [THEN] Verify Cost Fields must be updated in SKU When Revaluation Journal is posted.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");
        VerifyCostFieldsInSKU(StockkeepingUnit, RevaluedUnitCost, RevaluedUnitCost, RevaluedUnitCost, 0, 0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ReleasedProdOrderPageHandler')]
    procedure VerifyConsumptionMustNotBePostedIfComponentHaveBackwardFlushingWhenReopenProductionOrder()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        FinishedProductionOrder: TestPage "Finished Production Order";
        QuantityPer: Decimal;
        Quantity: Decimal;
        PartialQuantity: Decimal;
    begin
        // [SCENARIO 574905] Verify consumption must not be posted if the component has a backward flushing method When Status is changed from Released to Finished after Reopen the production Order.
        Initialize();

        // [GIVEN] Set location code in Manufacturing Setup.
        LibraryManufacturing.SetComponentsAtLocation('');

        // [GIVEN] Generate "Quantity Per", Quantity and Partial Quantity.
        QuantityPer := LibraryRandom.RandIntInRange(2, 5);
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        PartialQuantity := LibraryRandom.RandIntInRange(1, 5);

        // [GIVEN] Create an Item with BOM and Routing.
        CreateItemWithBOMAndRouting(Item, ChildItem, QuantityPer);

        // [GIVEN] Update Routing Link Code in Prod BOM Line and Routing Line.
        UpdateRoutingLinkCodeInProdBOMAndRouting(Item, ChildItem, '');

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, ChildItem."No.", LibraryRandom.RandIntInRange(100, 200), '', '', LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, '', '');

        // [GIVEN] Find Released Production Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", PartialQuantity, 0, 0);

        // [WHEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Verify Consumption Entry must be created with Output Quantity as Component has backward flushing Method.
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Item No.", ChildItem."No.");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.RecordCount(ItemLedgerEntry, 1);
        Assert.AreEqual(
            -PartialQuantity * QuantityPer,
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -PartialQuantity * QuantityPer, ItemLedgerEntry.TableCaption()));

        // [GIVEN] Get Finished Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [GIVEN] Execute "ReopenFinishProdOrder" action.
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.GoToRecord(ProductionOrder);
        FinishedProductionOrder.ReopenFinishedProdOrder.Invoke();

        // [WHEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Verify Consumption Entry must not be created with Output Quantity again as consumption is already posted.
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Item No.", ChildItem."No.");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.RecordCount(ItemLedgerEntry, 1);
        Assert.AreEqual(
            -PartialQuantity * QuantityPer,
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -PartialQuantity * QuantityPer, ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ReleasedProdOrderPageHandler')]
    procedure VerifyConsumptionMustBePostedIfComponentHaveBackwardFlushingWhenReopenProductionOrder()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        FinishedProductionOrder: TestPage "Finished Production Order";
        QuantityPer: Decimal;
        Quantity: Decimal;
        PartialQuantity: Decimal;
    begin
        // [SCENARIO 574905] Verify consumption must be posted if the component has a backward flushing method for remaining Finished Quantity When Status is changed from Released to Finished after Reopen the production Order.
        Initialize();

        // [GIVEN] Set location code in Manufacturing Setup.
        LibraryManufacturing.SetComponentsAtLocation('');

        // [GIVEN] Generate "Quantity Per", Quantity and Partial Quantity.
        QuantityPer := LibraryRandom.RandIntInRange(2, 5);
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        PartialQuantity := LibraryRandom.RandIntInRange(1, 5);

        // [GIVEN] Create an Item with BOM and Routing.
        CreateItemWithBOMAndRouting(Item, ChildItem, QuantityPer);

        // [GIVEN] Update Routing Link Code in Prod BOM Line and Routing Line.
        UpdateRoutingLinkCodeInProdBOMAndRouting(Item, ChildItem, '');

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, ChildItem."No.", LibraryRandom.RandIntInRange(100, 200), '', '', LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, '', '');

        // [GIVEN] Find Released Production Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", PartialQuantity, 0, 0);

        // [WHEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Verify Consumption Entry must be created with Output Quantity as Component has backward flushing Method.
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Item No.", ChildItem."No.");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.RecordCount(ItemLedgerEntry, 1);
        Assert.AreEqual(
            -PartialQuantity * QuantityPer,
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -PartialQuantity * QuantityPer, ItemLedgerEntry.TableCaption()));

        // [GIVEN] Get Finished Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [GIVEN] Execute "ReopenFinishProdOrder" action.
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.GoToRecord(ProductionOrder);
        FinishedProductionOrder.ReopenFinishedProdOrder.Invoke();

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity - PartialQuantity, 0, 0);

        // [WHEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Verify Consumption Entry must be created with remaining Output Quantity.
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Item No.", ChildItem."No.");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.RecordCount(ItemLedgerEntry, 2);
        Assert.AreEqual(
            -Quantity * QuantityPer,
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -Quantity * QuantityPer, ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandlerTrue')]
    procedure VerifyActualCostFieldsMustBeUpdatedInItemLedgerEntryWhenLoadSKUCostOnManufacturingIsEnabledIfSKUNotExist()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        QuantityPer: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO 582096] Verify Actual Cost must be non-zero in Item Ledger Entry if "Load SKU Cost on Manufacturing" is enabled in Manufacturing Setup but there is no SKU.
        Initialize();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Load SKU Cost on Manufacturing" in Manufacturing Setup.
        LibraryManufacturing.UpdateLoadSKUCostOnManufacturingInManufacturingSetup(true);

        // [GIVEN] Generate "Quantity Per" and Quantity.
        QuantityPer := LibraryRandom.RandIntInRange(2, 5);
        Quantity := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Create an Item with BOM and Routing.
        CreateItemWithBOMAndRouting(Item, ChildItem, QuantityPer);

        // [GIVEN] Update Routing Link Code in Prod BOM Line and Routing Line.
        UpdateRoutingLinkCodeInProdBOMAndRouting(Item, ChildItem, '');

        // [GIVEN] Update "Flushing Method" and "Costing Method" in Production item.
        Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Manual");
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Modify();

        // [GIVEN] Update "Flushing Method" in Child item.
        ChildItem.Validate("Flushing Method", Item."Flushing Method"::"Pick + Manual");
        ChildItem.Modify();

        // [GIVEN] Calculate Cost of Production Item.
        CalculateStdCost.CalcItem(Item."No.", false);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, '', '');

        // [GIVEN] Find Released Production Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [WHEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Verify Item Ledger Entry should be created with Actual Cost is zero for Output Item.
        Item.Get(Item."No.");
        VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder, "Item Ledger Entry Type"::Output, Item, '', Quantity * Item."Standard Cost", 0);

        // [GIVEN] Get Finished Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [WHEN] Adust Cost-Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Verify Item Ledger Entry should be created with Actual Cost for Output Item.
        VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder, "Item Ledger Entry Type"::Output, Item, '', 0, Quantity * Item."Standard Cost");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,InvtGLReconciliationHandler')]
    procedure VerifyVarianceTypeMaterialNonInventoryValueInPageInventoryGLReconciliation()
    var
        CompItem: Record Item;
        OutputItem: Record Item;
        NonInvItem: Record Item;
        Location: Record Location;
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        InventoryGLReconciliation: TestPage "Inventory - G/L Reconciliation";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 582101] Verify "Variance Type" - "Material - Non Inventory" value for Output item in Page "Inventory - G/L Reconciliation".
        Initialize();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Component item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create Production Item, Non-Inventory, Component Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(OutputItem, NonInvItem, CompItem);

        // [GIVEN] Save Quantity, Non-Inventory and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 100);
        CompUnitCost := LibraryRandom.RandIntInRange(20, 200);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and Component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, LibraryRandom.RandIntInRange(100, 200), NonInvUnitCost);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem, LibraryRandom.RandIntInRange(100, 200), CompUnitCost);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [GIVEN] Update "Mat. Non-Inv. Variance Acc." in Inventory Posting Setup.
        InventoryPostingSetup.Get('', OutputItem."Inventory Posting Group");
        LibraryInventory.UpdateMaterialNonInvVarianceAccountInInventoryPostingSetup(InventoryPostingSetup);

        // [GIVEN] Calculate Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [GIVEN] Create Released Production Order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);

        // [GIVEN] Create Prod Order Line with blank Location.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", OutputItem."No.", '', '', Quantity);

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [GIVEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [GIVEN] Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(OutputItem."No.", '');

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Run "Inventory - G/L Reconciliation"
        RunGetInventoryReport(TempInventoryReportEntry, OutputItem."No.", '');

        // [THEN] Verify "Variance Type" - "Material - Non Inventory" and "Material" for Output item in Inventory Report Entry.
        TempInventoryReportEntry.SetRange(Type, TempInventoryReportEntry.Type::Item);
        TempInventoryReportEntry.SetRange("No.", OutputItem."No.");
        TempInventoryReportEntry.CalcSums("Material Variance", "Mat. Non-Inventory Variance");
        Assert.AreEqual(
            -NonInvUnitCost * Quantity,
            TempInventoryReportEntry."Mat. Non-Inventory Variance",
            StrSubstNo(ValueMustBeEqualErr, TempInventoryReportEntry.FieldCaption("Mat. Non-Inventory Variance"), -NonInvUnitCost * Quantity, TempInventoryReportEntry.TableCaption()));
        Assert.AreEqual(
            -CompUnitCost * Quantity,
            TempInventoryReportEntry."Material Variance",
            StrSubstNo(ValueMustBeEqualErr, TempInventoryReportEntry.FieldCaption("Material Variance"), -CompUnitCost * Quantity, TempInventoryReportEntry.TableCaption()));

        // [GIVEN] Enqueue Inventory and Non-Inventory Amount.
        LibraryVariableStorage.Enqueue(CompUnitCost * Quantity);
        LibraryVariableStorage.Enqueue(NonInvUnitCost * Quantity);

        // [WHEN] Invoke "&Show Matrix" in Page "Inventory - G/L Reconciliation".
        InventoryGLReconciliation.OpenEdit();
        InventoryGLReconciliation.ItemFilter.SetValue(OutputItem."No.");
        InventoryGLReconciliation."&Show Matrix".Invoke();
        InventoryGLReconciliation.OK().Invoke();

        // [THEN] Verify "Variance Type" - "Material - Non Inventory" value for Output item in Page "Inventory - G/L Reconciliation" through InvtGLReconciliationHandler.
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Production Orders IV");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Production Orders IV");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SaveInventorySetup();
        LibrarySetupStorage.SaveManufacturingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Production Orders IV");
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithUnitCost(Item2);

        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        CreateItemWithUnitCost(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure ItemJournalSetup(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateItemWithUnitCost(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateRoutingAndUpdateItem(var Item: Record Item; var WorkCenter: Record "Work Center"): Code[10]
    begin
        exit(CreateRoutingAndUpdateItemSubcontracted(Item, WorkCenter, false));
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

    local procedure CreateAndPostConsumptionJournal(ProductionOrder: Record "Production Order"; ProdOrderComponent: Record "Prod. Order Component"; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Consumption, ProdOrderComponent."Item No.", Quantity);

        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Validate("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrderNo: Code[20]; OutputQuantity: Decimal; RunTime: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
    begin
        OutputJournalSetup(OutputItemJournalTemplate, OutputItemJournalBatch);
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithExplodeRouting(
        var ItemJournalLine: Record "Item Journal Line";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
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

    local procedure OutputJournalSetup(var OutputItemJournalTemplate: Record "Item Journal Template"; var OutputItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure FilterValueEntryWithItemLedgerEntryType(var ValueEntry: Record "Value Entry"; ProdOrderNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Document No.", ProdOrderNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
    end;

    local procedure GetRelatedGLEntriesFromValueEntry(var TempGLEntry: Record "G/L Entry" temporary; ValueEntry: Record "Value Entry")
    var
        GLEntry: Record "G/L Entry";
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
    begin
        GLItemLedgRelation.SetCurrentKey("Value Entry No.");
        GLItemLedgRelation.SetRange("Value Entry No.", ValueEntry."Entry No.");
        if GLItemLedgRelation.FindSet() then
            repeat
                GLEntry.Get(GLItemLedgRelation."G/L Entry No.");
                TempGLEntry.Init();
                TempGLEntry := GLEntry;
                TempGLEntry.Insert();
            until GLItemLedgRelation.Next() = 0;
    end;

    local procedure VerifyGLEntriesWithAccountNoAndExpectedAmount(var TempGLEntry: Record "G/L Entry" temporary; AccountNo: Code[20]; ExpectedAmount: Decimal)
    begin
        TempGLEntry.Reset();
        TempGLEntry.SetLoadFields("G/L Account No.", Amount);
        TempGLEntry.SetRange("G/L Account No.", AccountNo);
        TempGLEntry.FindFirst();
        TempGLEntry.CalcSums(Amount);

        Assert.AreEqual(
            AccountNo,
            TempGLEntry."G/L Account No.",
            StrSubstNo(ValueMustBeEqualErr, TempGLEntry.FieldCaption("G/L Account No."), AccountNo, TempGLEntry.TableCaption()));
        Assert.AreEqual(
            ExpectedAmount,
            TempGLEntry.Amount,
            StrSubstNo(EntryMustBeEqualErr, TempGLEntry.FieldCaption(Amount), ExpectedAmount, TempGLEntry."Entry No.", TempGLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntriesForConsumptionEntry(ProductionOrder: Record "Production Order"; ProdItem: Record Item; CompItem: Record Item; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ProductionOrder."Location Code", ProdItem."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."Inventory Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", 0);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Inventory Adjmt. Account", ExpectedValue);
    end;

    local procedure VerifyGLEntriesForCapacityEntry(ProductionOrder: Record "Production Order"; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);
        Assert.RecordCount(TempGLEntry, 4);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ValueEntry."Location Code", ValueEntry."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Direct Cost Applied Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", 0);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Inventory Adjmt. Account", ExpectedValue);
    end;

    local procedure VerifyGLEntriesForConsumptionEntryWithOutput(ProductionOrder: Record "Production Order"; ProdItem: Record Item; CompItem: Record Item; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ProductionOrder."Location Code", ProdItem."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."Inventory Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", ExpectedValue);
    end;

    local procedure VerifyGLEntriesForCapacityEntryWithOutput(ProductionOrder: Record "Production Order"; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);
        Assert.RecordCount(TempGLEntry, 2);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ValueEntry."Location Code", ValueEntry."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Direct Cost Applied Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", ExpectedValue);
    end;

    local procedure VerifyGLEntriesForAdjustmentConsumptionEntry(ProductionOrder: Record "Production Order"; ProdItem: Record Item; CompItem: Record Item; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange(Adjustment, true);
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ProductionOrder."Location Code", ProdItem."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."Inventory Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", 0);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Inventory Adjmt. Account", ExpectedValue);
    end;

    local procedure CreateAndPostPurchaseOrderWithDirectUnitCost(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostChargeItemPO(var PurchaseHeader: Record "Purchase Header"; PurchaseOrderNo: Code[20]; ItemNo: Code[20]; DocumentDate: Date; Quantity: Decimal; ItemChargeUnitCost: Decimal) PostedPurchInvoiceNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentDate);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", ItemChargeUnitCost);
        PurchaseLine.Modify(true);

        CreateItemChargeAssignment(PurchaseLine, PurchaseOrderNo, ItemNo);
        PostedPurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentDate: Date)
    begin
        Clear(PurchaseHeader);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), Database::"Purchase Header"));
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Validate("Posting Date", DocumentDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateItemChargeAssignment(var PurchaseLine: Record "Purchase Line"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FindPurchaseReceiptLine(PurchRcptLine, PurchaseOrderNo, ItemNo);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt, PurchRcptLine."Document No.",
          PurchRcptLine."Line No.", PurchRcptLine."No.");
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure CreateProductionItemWithNonInvItemAndProductionBOM(var ProdItem: Record Item; var NonInvItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();
    end;

    local procedure CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(var ProdItem: Record Item; var NonInvItem: Record Item; SemiProdItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, NonInvItem."No.", SemiProdItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();
    end;

    local procedure CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(var ProdItem: Record Item; var NonInvItem: Record Item; Item1: Record Item; Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item1."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item2."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();
    end;

    local procedure CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem: Record Item; Quantity: Decimal; UnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorNo(), NonInvItem."No.", Quantity, '', WorkDate());

        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify();

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure VerifyCostFieldsInItem(Item: Record Item; StandardCost: Decimal; SLMatCost: Decimal; RUMatCost: Decimal; SLNonInvMatCost: Decimal; RUNonInvMatCost: Decimal; SLMfgOvhdCost: Decimal; RUMfgOvhdCost: Decimal)
    begin
        Assert.AreEqual(
            StandardCost,
            Item."Standard Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Standard Cost"), StandardCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            SLNonInvMatCost,
            Item."Single-Lvl Mat. Non-Invt. Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Single-Lvl Mat. Non-Invt. Cost"), SLNonInvMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            RUNonInvMatCost,
            Item."Rolled-up Mat. Non-Invt. Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Rolled-up Mat. Non-Invt. Cost"), RUNonInvMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            SLMatCost,
            Item."Single-Level Material Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Single-Level Material Cost"), SLMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            RUMatCost,
            Item."Rolled-up Material Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Rolled-up Material Cost"), RUMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            SLMfgOvhdCost,
            Item."Single-Level Mfg. Ovhd Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Single-Level Mfg. Ovhd Cost"), SLMfgOvhdCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            RUMfgOvhdCost,
            Item."Rolled-up Mfg. Ovhd Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Rolled-up Mfg. Ovhd Cost"), RUMfgOvhdCost, Item."No.", Item.TableCaption()));
    end;

    local procedure VerifyCostFieldsInSKU(SKU: Record "Stockkeeping Unit"; StandardCost: Decimal; SLMatCost: Decimal; RUMatCost: Decimal; SLNonInvMatCost: Decimal; RUNonInvMatCost: Decimal; SLMfgOvhdCost: Decimal; RUMfgOvhdCost: Decimal)
    begin
        Assert.AreEqual(
            StandardCost,
            SKU."Standard Cost",
            StrSubstNo(ItemMustBeEqualErr, SKU.FieldCaption("Standard Cost"), StandardCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            SLNonInvMatCost,
            SKU."Single-Lvl Mat. Non-Invt. Cost",
            StrSubstNo(ItemMustBeEqualErr, SKU.FieldCaption("Single-Lvl Mat. Non-Invt. Cost"), SLNonInvMatCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            RUNonInvMatCost,
            SKU."Rolled-up Mat. Non-Invt. Cost",
            StrSubstNo(ItemMustBeEqualErr, SKU.FieldCaption("Rolled-up Mat. Non-Invt. Cost"), RUNonInvMatCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            SLMatCost,
            SKU."Single-Level Material Cost",
            StrSubstNo(ItemMustBeEqualErr, SKU.FieldCaption("Single-Level Material Cost"), SLMatCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            RUMatCost,
            SKU."Rolled-up Material Cost",
            StrSubstNo(ItemMustBeEqualErr, SKU.FieldCaption("Rolled-up Material Cost"), RUMatCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            SLMfgOvhdCost,
            SKU."Single-Level Mfg. Ovhd Cost",
            StrSubstNo(ItemMustBeEqualErr, SKU.FieldCaption("Single-Level Mfg. Ovhd Cost"), SLMfgOvhdCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            RUMfgOvhdCost,
            SKU."Rolled-up Mfg. Ovhd Cost",
            StrSubstNo(ItemMustBeEqualErr, SKU.FieldCaption("Rolled-up Mfg. Ovhd Cost"), RUMfgOvhdCost, SKU."Item No.", SKU.TableCaption()));
    end;

    local procedure RunBOMCostSharesReport(Item: Record Item; ShowLevel: Option; ShowDetails: Boolean; ShowCostShare: Option)
    var
        Item1: Record Item;
    begin
        Item1.SetRange("No.", Item."No.");
        Commit();

        LibraryVariableStorage.Enqueue(ShowCostShare);
        LibraryVariableStorage.Enqueue(ShowLevel);
        LibraryVariableStorage.Enqueue(ShowDetails);
        Report.Run(Report::"BOM Cost Share Distribution", true, false, Item1);
    end;

    local procedure VerifyBOMCostSharesReport(ItemNo: Code[20]; ExpMaterialCost: Decimal; ExpCapacityCost: Decimal; ExpMfgOvhdCost: Decimal; ExpCapOvhdCost: Decimal; ExpSubcontractedCost: Decimal; ExpNonInvMaterialCost: Decimal; ExpTotalCost: Decimal)
    var
        CostAmount: Decimal;
        RoundingFactor: Decimal;
    begin
        RoundingFactor := 100 * LibraryERM.GetUnitAmountRoundingPrecision();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ItemNoLbl, ItemNo);

        CostAmount := LibraryReportDataset.Sum(MaterialCostLbl);
        Assert.AreNearlyEqual(ExpMaterialCost, CostAmount, RoundingFactor, StrSubstNo(MaterialCostMustBeEqualErr, ExpMaterialCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(CapacityCostLbl);
        Assert.AreNearlyEqual(ExpCapacityCost, CostAmount, RoundingFactor, StrSubstNo(CapacityCostMustBeEqualErr, ExpCapacityCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(MfgOvhdCostLbl);
        Assert.AreNearlyEqual(ExpMfgOvhdCost, CostAmount, RoundingFactor, StrSubstNo(MfgOverheadCostMustBeEqualErr, ExpMfgOvhdCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(CapOvhdCostLbl);
        Assert.AreNearlyEqual(ExpCapOvhdCost, CostAmount, RoundingFactor, StrSubstNo(CapacityOverheadCostMustBeEqualErr, ExpCapOvhdCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(SubcontrdCostLbl);
        Assert.AreNearlyEqual(ExpSubcontractedCost, CostAmount, RoundingFactor, StrSubstNo(SubcontractedCostMustBeEqualErr, ExpSubcontractedCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(NonInventoryMaterialCostLbl);
        Assert.AreNearlyEqual(ExpNonInvMaterialCost, CostAmount, RoundingFactor, StrSubstNo(NonInvMaterialCostMustBeEqualErr, ExpNonInvMaterialCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(TotalCostLbl);
        Assert.AreNearlyEqual(ExpTotalCost, CostAmount, RoundingFactor, StrSubstNo(TotalCostMustBeEqualErr, ExpTotalCost, ItemNo));
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndRefreshProdOrderWithSalesSourceType(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::"Sales Header", SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateItemWithBOMAndRouting(var Item: Record Item; var ChildItem: Record Item; QuantityPer: Decimal)
    var
        WorkCenter: Record "Work Center";
    begin
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::"Pick + Backward");
        UpdateBOMHeader(Item."Production BOM No.", ChildItem."No.", CreateRoutingAndUpdateItem(Item, WorkCenter));
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify();
    end;

    local procedure UpdateBOMHeader(ProductionBOMNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.SetRange("No.", ProductionBOMNo);
        ProductionBOMHeader.FindFirst();
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Modify(true);

        UpdateBOMLineRoutingLinkCode(ProductionBOMNo, ItemNo, RoutingLinkCode);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateBOMLineRoutingLinkCode(ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        FindProdBOMLine(ProductionBOMLine, ProductionBOMHeaderNo, ItemNo);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure UpdateFlushingMethodOnItem(var Item: Record Item; FlushingMethod: Enum "Flushing Method")
    begin
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure FindProdBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeaderNo);
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ItemNo);
        ProductionBOMLine.FindFirst();
    end;

    local procedure CreateProductionItemWithInvItemAndProductionBOM(var ProdItem: Record Item; var InvItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItem(InvItem);

        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, InvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();
    end;

    local procedure CalculateInventoryValue(var RevaluationItemJournalBatch: Record "Item Journal Batch"; Item: Record Item)
    var
        RevaluationItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        NoSeries: Codeunit "No. Series";
    begin
        Item.SetRange("No.", Item."No.");
        RevaluationItemJournalTemplate.Get(RevaluationItemJournalBatch."Journal Template Name");

        LibraryInventory.ClearItemJournal(RevaluationItemJournalTemplate, RevaluationItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", RevaluationItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", RevaluationItemJournalBatch.Name);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate(), NoSeries.PeekNextNo(RevaluationItemJournalBatch."No. Series"),
          "Inventory Value Calc. Per"::Item, true, false, true, "Inventory Value Calc. Base"::" ", false);
    end;

    local procedure RevaluationJournalSetup(var RevaluationItemJournalBatch: Record "Item Journal Batch")
    var
        RevaluationItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(RevaluationItemJournalTemplate, RevaluationItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(RevaluationItemJournalBatch, RevaluationItemJournalTemplate.Type, RevaluationItemJournalTemplate.Name);
    end;

    local procedure UpdateRevaluationJournalLine(ItemNo: Code[20]; LocationCode: Code[20]; UnitCostRevalued: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        RevaluationJournal: TestPage "Revaluation Journal";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();

        RevaluationJournal.OpenEdit();
        RevaluationJournal.GoToRecord(ItemJournalLine);
        RevaluationJournal."Unit Cost (Revalued)".SetValue(UnitCostRevalued);
        RevaluationJournal.Close();
    end;

    local procedure UpdateQuantityPerInProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; ItemNo: Code[20]; QtyPer: Decimal)
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();

        ProdOrderComponent.Validate("Quantity per", QtyPer);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CalcIndicatorPct(Value: Decimal; "Sum": Decimal): Decimal
    begin
        if Value = 0 then
            exit(0);

        exit(Round((Sum - Value) / Value * 100, 1));
    end;

    local procedure VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder: Record "Production Order"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; CostEntryType: Enum "Cost Entry Type"; Item: Record Item; LocationCode: Code[10]; Quantity: Decimal; CostAmountExpected: Decimal; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        if CostEntryType = CostEntryType::Variance then
            ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type"::"Material - Non Inventory");

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", ItemLedgerEntryType, CostEntryType, Item."No.", LocationCode, Quantity);
        Assert.AreEqual(
            CostAmountExpected,
            ValueEntry."Cost Amount (Expected)",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Amount (Expected)"), CostAmountExpected, ValueEntry."Entry No.", ValueEntry.TableCaption()));
        Assert.AreEqual(
            CostAmountActual,
            ValueEntry."Cost Amount (Actual)",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual, ValueEntry."Entry No.", ValueEntry.TableCaption()));
    end;

    local procedure VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder: Record "Production Order"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; Item: Record Item; LocationCode: Code[10]; CostAmountExpected: Decimal; CostAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FilterItemLedgerEntryWithItemLedgerEntryType(ItemLedgerEntry, ProductionOrder."No.", ItemLedgerEntryType, Item."No.", LocationCode);
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        Assert.AreEqual(
            CostAmountExpected,
            ItemLedgerEntry."Cost Amount (Expected)",
            StrSubstNo(EntryMustBeEqualErr, ItemLedgerEntry.FieldCaption("Cost Amount (Expected)"), CostAmountExpected, ItemLedgerEntry."Entry No.", ItemLedgerEntry.TableCaption()));
        Assert.AreEqual(
            CostAmountActual,
            ItemLedgerEntry."Cost Amount (Actual)",
            StrSubstNo(EntryMustBeEqualErr, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual, ItemLedgerEntry."Entry No.", ItemLedgerEntry.TableCaption()));
    end;

    local procedure FilterValueEntryWithItemLedgerEntryType(var ValueEntry: Record "Value Entry"; ProdOrderNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; EntryType: Enum "Cost Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; ItemLedgerEntryQuantity: Decimal)
    begin
        ValueEntry.SetRange("Document No.", ProdOrderNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Location Code", LocationCode);
        ValueEntry.SetRange("Item Ledger Entry Quantity", ItemLedgerEntryQuantity);
        ValueEntry.FindFirst();
    end;

    local procedure FilterItemLedgerEntryWithItemLedgerEntryType(var ItemLedgerEntry: Record "Item Ledger Entry"; ProdOrderNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        ItemLedgerEntry.SetRange("Document No.", ProdOrderNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure UpdateRoutingLinkCodeInProdBOMAndRouting(Item: Record Item; ChildItem: Record Item; RoutingLinkCode: Code[10])
    var
        RoutingLine: Record "Routing Line";
        ProdBOMLine: Record "Production BOM Line";
    begin
        FindProdBOMLine(ProdBOMLine, Item."Production BOM No.", ChildItem."No.");
        FindRoutingLine(RoutingLine, Item."Routing No.", ProdBOMLine."Routing Link Code");
        RoutingLine."Routing Link Code" := RoutingLinkCode;
        RoutingLine.Modify();

        ProdBOMLine."Routing Link Code" := RoutingLinkCode;
        ProdBOMLine.Modify();
    end;

    local procedure FindRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; RoutingLinkCode: Code[10]);
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Routing Link Code", RoutingLinkCode);
        RoutingLine.FindFirst();
    end;

    local procedure RunGetInventoryReport(var InventoryReportEntry: Record "Inventory Report Entry"; ItemNo: Code[20]; DateFilter: Text)
    var
        InventoryReportHeader: Record "Inventory Report Header";
        GetInventoryReport: Codeunit "Get Inventory Report";
    begin
        InventoryReportHeader.SetRange("Item Filter", ItemNo);
        InventoryReportHeader.SetFilter("Posting Date Filter", DateFilter);
        InventoryReportHeader."Show Warning" := true;
        GetInventoryReport.SetReportHeader(InventoryReportHeader);
        GetInventoryReport.Run(InventoryReportEntry);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure VerifyMessageFromConfirmHandlerTrue(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), ConfirmMessage);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure VerifyFinishOrderWithoutOutputNotEditableInChangeStatusOnProdOrder(var ChangeStatusOnProductionOrder: TestPage "Change Status on Prod. Order")
    begin
        Assert.AreEqual(
            false,
            ChangeStatusOnProductionOrder."Finish Order Without Output".Editable(),
            StrSubstNo(FieldMustNotBeEditableErr, ChangeStatusOnProductionOrder."Finish Order Without Output".Caption(), ChangeStatusOnProductionOrder.Caption()));
    end;

    [ModalPageHandler]
    procedure VerifyFinishOrderWithoutOutputEditableInChangeStatusOnProdOrder(var ChangeStatusOnProductionOrder: TestPage "Change Status on Prod. Order")
    begin
        Assert.AreEqual(
            true,
            ChangeStatusOnProductionOrder."Finish Order Without Output".Editable(),
            StrSubstNo(FieldMustBeEditableErr, ChangeStatusOnProductionOrder."Finish Order Without Output".Caption(), ChangeStatusOnProductionOrder.Caption()));
    end;

    [ModalPageHandler]
    procedure ChangeStatusOnProdOrderOk(var ChangeStatusOnProductionOrder: TestPage "Change Status on Prod. Order")
    begin
        ChangeStatusOnProductionOrder.Yes().Invoke();
    end;

    [ModalPageHandler]
    procedure PostProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesDistributionReportHandler(var BOMCostShareDistribution: TestRequestPage "BOM Cost Share Distribution")
    var
        ShowCostShareAsLcl: Variant;
        ShowLevelAsLcl: Variant;
        ShowDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowCostShareAsLcl);
        LibraryVariableStorage.Dequeue(ShowLevelAsLcl);
        LibraryVariableStorage.Dequeue(ShowDetails);

        BOMCostShareDistribution.ShowCostShareAs.SetValue(ShowCostShareAsLcl);
        BOMCostShareDistribution.ShowLevelAs.SetValue(ShowLevelAsLcl);
        BOMCostShareDistribution.ShowDetails.SetValue(ShowDetails);
        BOMCostShareDistribution.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    procedure ReleasedProdOrderPageHandler(var ReleasedProductionOrder: TestPage "Released Production Order")
    begin
    end;

    [ModalPageHandler]
    procedure InvtGLReconciliationHandler(var InventoryGLReconMatrix: TestPage "Inventory - G/L Recon Matrix")
    var
        InventoryReportEntry: Record "Inventory Report Entry";
        InventoryReportEntryPage: TestPage "Inventory Report Entry";
        MaterialVariance: Decimal;
        MaterialNonInventoryVariance: Decimal;
    begin
        MaterialVariance := LibraryVariableStorage.DequeueDecimal();
        MaterialNonInventoryVariance := LibraryVariableStorage.DequeueDecimal();
        InventoryGLReconMatrix.First();
        repeat
            if (InventoryGLReconMatrix.Name.Value = InventoryReportEntry.FieldCaption("Material Variance")) then begin
                Assert.AreEqual(
                    -MaterialVariance,
                    InventoryGLReconMatrix.Field1.AsDecimal(),
                    StrSubstNo(ValueMustBeEqualErr, InventoryGLReconMatrix.Field1.Caption(), -MaterialVariance, InventoryGLReconMatrix.Caption));

                InventoryReportEntryPage.Trap();
                InventoryGLReconMatrix.Field1.Drilldown();
                Assert.AreEqual(
                    -MaterialVariance,
                    InventoryReportEntryPage."Material Variance".AsDecimal(),
                    StrSubstNo(ValueMustBeEqualErr, InventoryReportEntryPage."Material Variance", -MaterialVariance, InventoryReportEntryPage.Caption));
            end;

            if (InventoryGLReconMatrix.Name.Value = InventoryReportEntry.FieldCaption("Mat. Non-Inventory Variance")) then begin
                Assert.AreEqual(
                    -MaterialNonInventoryVariance,
                    InventoryGLReconMatrix.Field1.AsDecimal(),
                    StrSubstNo(ValueMustBeEqualErr, InventoryGLReconMatrix.Field1.Caption(), -MaterialNonInventoryVariance, InventoryGLReconMatrix.Caption));

                InventoryReportEntryPage.Trap();
                InventoryGLReconMatrix.Field1.Drilldown();
                Assert.AreEqual(
                    -MaterialNonInventoryVariance,
                    InventoryReportEntryPage."Mat. Non-Inventory Variance".AsDecimal(),
                    StrSubstNo(ValueMustBeEqualErr, InventoryReportEntryPage."Mat. Non-Inventory Variance", -MaterialNonInventoryVariance, InventoryReportEntryPage.Caption));
            end;

            if (InventoryGLReconMatrix.Name.Value = InventoryReportEntry.FieldCaption(Total)) then
                Assert.AreEqual(
                    MaterialNonInventoryVariance + MaterialVariance,
                    InventoryGLReconMatrix.Field1.AsDecimal(),
                    StrSubstNo(ValueMustBeEqualErr, InventoryGLReconMatrix.Field1.Caption(), MaterialVariance + MaterialNonInventoryVariance, InventoryGLReconMatrix.Caption));
        until not InventoryGLReconMatrix.Next();
    end;
}
