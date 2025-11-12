// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.History;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Journal;
using Microsoft.Sales.Document;
using Microsoft.Foundation.Period;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Foundation.NoSeries;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.Currency;
using Microsoft.Purchases.Vendor;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Posting;

codeunit 137003 "SCM WIP Costing Production-I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        SumMustBeZeroErr: Label 'The sum of amounts must be zero.';
        AmountsDoNotMatchErr: Label 'The amount totals must be equal.';
        GLEntryNoRowExistErr: Label 'G/L Entry for the particular Document No and Account must not exist.';
        ExpectedMsg: Label 'Expected Cost Posting to G/L has been changed.';
        WrongFieldValueErr: Label '%1 is incorrect.', Comment = '%1: Field name';
        ExpectedCostPostingQst: Label 'Do you really want to change the Expected Cost Posting to G/L?';
        ExpectedMaterialCostErr: Label 'Standart Material Cost should match Item Single-Level Material Cost';

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardManProduction()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Standard]
        // [SCENARIO] Standard Costing with Flushing method - Manual and Finish Production Order, verify values in GL entries.

        // Covers TFS_TC_ID = 32227, 32232, 12617 and 12622.
        StandardProduction(false, "Flushing Method"::Manual, "Costing Method"::Standard);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardBackwardProduction()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Standard]
        // [SCENARIO] Standard Costing with Flushing method - Backward and Finish Production Order, verify values in GL entries.

        // Covers TFS_TC_ID = 32227, 32232, 12617 and 12622.
        StandardProduction(false, "Flushing Method"::Backward, "Costing Method"::Standard);
    end;

    local procedure StandardProduction(AutoCostPosting: Boolean; FlushingMethod: Enum "Flushing Method"; CostingMethod: Enum "Costing Method")
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // 1. Setup: Required Costing Setups.
        // Create, Calculate and Post Consumption Journal and Explode Routing and Post Output Journal.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, AutoCostPosting, FlushingMethod, CostingMethod,
          true, true, false, false, false, false, false);
        if FlushingMethod = "Flushing Method"::Manual then begin
            LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
            LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        end;
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);

        // 2. Exercise: Change Status of Production Order to Finished.
        // Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify WIP Account General Ledger Entries for Total amount and Positive amount entries.
        VerifyWIPAmountGLEntry(ProductionOrder, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardFwdAutoInvoiceProd()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Standard]
        // [SCENARIO] Standard Costing with Flushing method - Forward and Finish Production Order, verify values in GL entries. Also verify Inventory Account on G/L Entry after Purchase Order has been posted as Receive only.

        // Covers TFS_TC_ID = 32227, 32232, 12617 and 12622.
        // 1. Setup: Required Costing Setups.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Forward, "Costing Method"::Standard,
          true, false, false, false, false, false, false);

        // 2.1 Exercise: Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3.1 Verify: Verify Inventory Account General Ledger Entries do not exist.
        VerifyInvtAccountNotInGLEntry(ItemNo2, ProductionOrderNo);

        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);

        // 2.2 Exercise: Post Purchase Order as Invoice, Update Status of Production Order to Finished.
        // Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3.2 Verify: Verify WIP Account General Ledger Entries for Total amount and Positive amount entries.
        VerifyWIPAmountGLEntry(ProductionOrder, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardManAutoFullPurchase()
    begin
        // Covers TFS_TC_ID = 32233 and 12623.
        // Auto Cost Posting - True, Purchase Posting with Full Qty to Receive.
        StandardManPurchase(true, false, "Flushing Method"::Manual, "Costing Method"::Standard);  // Boolean-Auto Cost Posting and Partial Posting.
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardManAutoPartPurchase()
    begin
        // Covers TFS_TC_ID = 32233 and 12623.
        // Auto Cost Posting - True, Purchase Posting with Partial Qty to Receive.
        StandardManPurchase(true, true, "Flushing Method"::Manual, "Costing Method"::Standard);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardManFullPurchase()
    begin
        // Covers TFS_TC_ID = 32233 and 12623.
        // Auto Cost Posting - False, Purchase Posting with Full Qty to Receive.
        StandardManPurchase(false, false, "Flushing Method"::Manual, "Costing Method"::Standard);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardManPartPurchase()
    begin
        // Covers TFS_TC_ID = 32233 and 12623.
        // Auto Cost Posting - False, Purchase Posting with Partial Qty to Receive.
        StandardManPurchase(false, true, "Flushing Method"::Manual, "Costing Method"::Standard);
    end;

    local procedure StandardManPurchase(AutoCostPosting: Boolean; PartialPurchasePosting: Boolean; FlushingMethod: Enum "Flushing Method"; CostingMethod: Enum "Costing Method")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // 1. Setup: Required Costing Setups.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, AutoCostPosting, FlushingMethod, CostingMethod,
          true, false, false, true, PartialPurchasePosting, false, false);
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseHeader);

        // 2. Exercise: Post Purchase Order with Required Quantity to Invoice and Post Inventory Cost to G/L if required.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.

        if not AutoCostPosting then
            LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify General Ledger Entries that WIP Account does not exist and Total Inventory amount equals Calculated amount.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        VerifyInvtAmountGLEntry(TempPurchaseLine, PurchInvHeader."No.", ItemNo, '', false);  // Boolean for Additional Currency.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoFxdCostFullPurchase()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 32231 and 12621.
        // Flushing Method - Manual, Auto Cost Posting - True, Direct Unit Cost as expected.
        // Purchase Posting with Full Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgPurchase(true, false, Qty, Qty, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManFxdCostFullPurchase()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 32231 and 12621.
        // Flushing Method - Manual, Auto Cost Posting - False, Direct Unit Cost as expected.
        // Purchase Posting with Full Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgPurchase(false, false, Qty, Qty, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoRndCostFullPurchase()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 32231 and 12621.
        // Flushing Method - Manual, Auto Cost Posting - True, Direct Unit Cost different from expected.
        // Purchase Posting with Full Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgPurchase(true, true, Qty, Qty, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManRndCostFullPurchase()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 32231 and 12621.
        // Flushing Method - Manual, Auto Cost Posting - False, Direct Unit Cost different from expected.
        // Purchase Posting with Full Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgPurchase(false, true, Qty, Qty, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoFxdCostPartPurchase()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 32231 and 12621.
        // Flushing Method - Manual, Auto Cost Posting - True, Direct Unit Cost as expected.
        // Purchase Posting with Partial Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgPurchase(true, false, Qty, Qty - 1, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManFxdCostPartPurchase()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 32231 and 12621.
        // Flushing Method - Manual, Auto Cost Posting - False, Direct Unit Cost as expected.
        // Purchase Posting with Partial Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgPurchase(false, false, Qty, Qty - 1, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoRndCostPartPurchase()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 32231 and 12621.
        // Flushing Method - Manual, Auto Cost Posting - True, Direct Unit Cost different from expected.
        // Purchase Posting with Partial Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgPurchase(true, true, Qty, Qty - 1, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManRndCostPartPurchase()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 32231 and 12621.
        // Flushing Method - Manual, Auto Cost Posting - False, Direct Unit Cost different from expected.
        // Purchase Posting with Partial Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgPurchase(false, true, Qty, Qty - 1, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgBackwardRndCostFullPurchase()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 32235 and 12625.
        // Flushing Method - Backward, Auto Cost Posting - False, Direct Unit Cost different from expected.
        // Purchase Posting with Full Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgPurchase(false, true, Qty, Qty, "Flushing Method"::Backward);
    end;

    local procedure AvgPurchase(AutoCostPosting: Boolean; DirectUnitCost: Boolean; Qty: Decimal; QtyToReceive: Decimal; FlushingMethod: Enum "Flushing Method")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        InventorySetup: Record "Inventory Setup";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // 1. Setup: Update Inventory Setup, Create Items with Flushing method - Manual.
        Initialize();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, AutoCostPosting, false, "Automatic Cost Adjustment Type"::Never, "Average Cost Calculation Type"::Item, "Average Cost Period Type"::Day);
        CreateComponentItems(ItemNo, ItemNo2, "Costing Method"::Average, FlushingMethod, false);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, Qty, QtyToReceive, DirectUnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Receive.
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseHeader);

        // 2. Exercise: Post Purchase Order with required Quantity and Post Inventory Cost to G/L if required.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.

        if not AutoCostPosting then
            LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify General Ledger Entries that WIP Account does not exist and Total Inventory amount equals Calculated amount.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        VerifyInvtAmountGLEntry(TempPurchaseLine, PurchInvHeader."No.", ItemNo, '', false);  // Boolean for Additional Currency.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManConsumption()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Average Costing with Flushing Method Manual, Automatic Cost Posting disabled and Post consumption.

        // Covers TFS_TC_ID = 32235 and 12625.
        // 1. Setup: Required Costing Setups.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          true, true, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);

        // 2. Exercise: Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report after Consumption.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify General Ledger Entries that Total WIP Amount equals Calculated amount.
        VerifyWIPAmountConsumpOutput(ProductionOrder, ItemNo, false);  // False signifies verification for Consumption Amount.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManConsumptionAndOutput()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Average Costing with Flushing Method Manual, Automatic Cost Posting disabled and Post consumption and output.

        // Covers TFS_TC_ID = 32235 and 12625.
        // 1. Setup: Required Costing Setups.
        // Create and Post Consumption, Run Adjust Cost Item Entries report, Create Output.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          true, true, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);

        // 2. Exercise: Post Output and Post Inventory Cost to G/L.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify G/L Entries that WIP Amount equals Calculated amount.
        VerifyWIPAmountConsumpOutput(ProductionOrder, ItemNo, true);  // True signifies verification for Output Amount.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManProduction()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Average Costing with Flushing Method Manual, Automatic Cost Posting disabled and Post consumption and output, finish Production Order.

        // Covers TFS_TC_ID = 32235 and 12625.
        // 1. Setup: Required Costing Setups.
        // Create and Post Consumption, Run Adjust Cost Item Entries report, Post Output, and Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          true, true, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // 2. Exercise: Run Adjust Cost Item Entries and Post Inventory Cost to G/L report.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify G/L Entries that WIP Amount equals Calculated amount.
        VerifyWIPAmountFinishProd(ProductionOrder, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgBackwardProduction()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Test Average Costing with Flushing Method Backward, Automatic Cost Posting disabled and posting Purchase Order.

        // Covers TFS_TC_ID = 32235 and 12625.
        // 1. Setup: Required Costing Setups.
        // Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Backward, "Costing Method"::Average,
          true, true, false, false, false, false, false);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // 2. Exercise: Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify G/L Entries that WIP Amount equals Calculated amount.
        VerifyWIPAmountFinishProd(ProductionOrder, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManOutputAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Average Costing with Flushing Method Manual, Automatic Cost Posting disabled, Post Output and Post Purchase Invoice.

        // Covers TFS_TC_ID = 32235 and 12625.
        // 1. Setup: Required Costing Setups.
        // Create and Post Consumption & Output.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          true, false, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseHeader);

        // 2. Exercise: Invoice Purchase Order, Run Adjust Cost Item Entries and Post Inventory Cost to G/L reports.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        VerifyPurchaseAccountGLEntry(TempPurchaseLine, PurchaseHeader."Buy-from Vendor No.", PurchInvHeader."No.", ItemNo);
        VerifyWIPAmountConsumpOutput(ProductionOrder, ItemNo, true);  // True signifies verification for Output Amount.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManCostRndOutputInvoiceProd()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Test Average Costing with Flushing Method Manual, Automatic Cost Posting disabled, Post Output, Post Purchase Invoice and Finish Production Order.

        // Covers TFS_TC_ID = 32235 and 12625.
        // 1. Setup: Required Costing Setups.
        // Create and Post Consumption & Output, Invoice Purchase Order, Run Adjust Cost Item Entries & Post Inventory  Cost to G/L.
        // Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          true, false, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // 2. Exercise: Run Adjust Cost Item Entries and Post Inventory Cost to G/L reports.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify G/L Entries that WIP Amount equals Calculated amount.
        VerifyWIPAmountFinishProd(ProductionOrder, ItemNo, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgFwdAutoOutputAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ProductionOrder: Record "Production Order";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Test Average Costing with Flushing Method Forward, Automatic Cost Posting enabled, Refresh Released Production Order and Post Purchase Invoice.

        // Covers TFS_TC_ID = 32235 and 12625.
        // 1. Setup: Required Costing Setups.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Forward, "Costing Method"::Average,
          true, false, false, false, false, false, false);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseHeader);

        // 2. Exercise: Invoice Purchase Order, Run Adjust Cost Item Entries and Post Inventory Cost to G/L reports.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        VerifyPurchaseAccountGLEntry(TempPurchaseLine, PurchaseHeader."Buy-from Vendor No.", PurchInvHeader."No.", ItemNo);
        VerifyWIPAmountConsumpOutput(ProductionOrder, ItemNo, true);  // True signifies verification for Output Amount.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgFwdAutoOutputInvoiceProd()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Test Average Costing with Flushing Method Forward, Automatic Cost Posting enabled, Refresh Released Production Order and Post Purchase Invoice & Finish Production Order.

        // Covers TFS_TC_ID = 32235 and 12625.
        // 1. Setup: Required Costing Setups.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Forward, "Costing Method"::Average,
          true, false, false, false, false, false, false);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);

        // 2. Exercise: Invoice Purchase Order, Finish Production Order, Run Adjust Cost Item Entries & Post Inventory Cost to G/L reports.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify G/L Entries that WIP Amount equals Calculated amount.
        VerifyWIPAmountFinishProd(ProductionOrder, ItemNo, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManProductionInvoiceNoAdj()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO] Verify G/L Entries contain correct Amounts without Adjustment when Consumption & Output posted, Production Order finished, Purchase Order for components invoiced.

        // [GIVEN] Required Costing Setups. Create and Post Consumption & Output. Finish Production Order, Invoice Purchase Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          false, false, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseHeader);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.

        // [WHEN] Run Post Inventory Cost to G/L report.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount without Adjust Cost.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        VerifyPurchaseAccountGLEntry(TempPurchaseLine, PurchaseHeader."Buy-from Vendor No.", PurchInvHeader."No.", ItemNo);
        VerifyWIPAmountExclCostFinish(ProductionOrder, ItemNo, ItemNo2, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManProductionAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Verify that G/L Entries contain correct Amounts when Consumption & Output posted, Production Order finished, Purchase Order for components invoiced.

        // [GIVEN] Required Costing Setups. Create and Post Consumption & Output. Finish Production Order, Invoice Purchase Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          false, false, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.

        // [WHEN] Run Adjust Cost Item Entries & Post Inventory Cost to G/L reports.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries - WIP Account Amount equal Calculated amount.
        VerifyWIPAmountFinishProd(ProductionOrder, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgFwdAutoProductionAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Finished production order with invoiced purchase order for components. Verify correct WIP Amount after running Adjust Cost Item Entries and posting to GL.

        // [GIVEN] Required Costing Setups. Finish Production Order, Invoice Purchase Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Forward, "Costing Method"::Average,
          true, false, false, false, false, false, false);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.

        // [WHEN] Run Adjust Cost Item Entries & Post Inventory Cost to G/L reports.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries that WIP Amount equals Calculated amount.
        VerifyWIPAmountFinishProd(ProductionOrder, ItemNo, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManLessProdInvoiceNoAdj()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO] Verify G/L Entries have correct Amounts without Adjustment when Consumption & Output with Reduced Output Qty. posted, Production Order finished, Purchase Order for components finished.

        // [GIVEN] Required Costing Setups. Create and Post Consumption & Output with Reduced Output Qty. Finish Production Order, Invoice Purchase Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          false, false, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        UpdateLessQtyOutputJournal(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseHeader);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.

        // [WHEN] Run Post Inventory Cost to G/L report.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount without Adjust Cost.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        VerifyPurchaseAccountGLEntry(TempPurchaseLine, PurchaseHeader."Buy-from Vendor No.", PurchInvHeader."No.", ItemNo);
        VerifyWIPAmountExclCostFinish(ProductionOrder, ItemNo, ItemNo2, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManLessProdAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Verify G/L Entries - WIP Account Amount is correct when Consumption & Output with Reduced Output Qty. posted, Production Order finished, Purchase Order for components invoiced.

        // [GIVEN] Required Costing Setups. Create and Post Consumption & Output with Reduced Output Qty. Finish Production Order, Invoice Purchase Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          false, false, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        UpdateLessQtyOutputJournal(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.

        // [WHEN] Run Adjust Cost Item Entries & Post Inventory Cost to G/L reports.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries - WIP Account Amount equal Calculated amount.
        VerifyWIPAmountFinishProd(ProductionOrder, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManFxdCostOutputInvoiceProd()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Verify G/L Entries have correct Amounts when Consumption & Output posted, Purchase Order for components invoiced, Production Order finished.

        // [GIVEN] Required Costing Setups. Create and Post Consumption & Output. Invoice Purchase Order, Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Manual, "Costing Method"::Average,
          false, false, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Adjust Cost Item Entries & Post Inventory Cost to G/L reports.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries - WIP Account Amount equal Calculated amount.
        VerifyWIPAmountFinishProd(ProductionOrder, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgFwdInvoiceAndProduction()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Verify that WIP Amount equals Calculated amount with Adjust Cost when purchase order for components invoiced and then production order finished.

        // [GIVEN] Required Costing Setups. Invoice Purchase Order, Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, false, "Flushing Method"::Forward, "Costing Method"::Average,
          true, false, false, false, false, false, false);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Adjust Cost Item Entries & Post Inventory Cost to G/L reports.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries that WIP Amount equals Calculated amount with Adjust Cost.
        VerifyWIPAmountExclCostFinish(ProductionOrder, ItemNo, ItemNo2, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgFwdAutoProduction()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Average]
        // [SCENARIO] Finished produciton order. Verify correct WIP Amount after running Adjust Cost Item Entries and posting to GL.

        // [GIVEN] Required Costing Setups. Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Forward, "Costing Method"::Average,
          true, true, false, false, false, false, false);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);

        // [WHEN] Run Adjust Cost Item Entries & Post Inventory Cost to G/L reports.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries that WIP Amount equals Calculated amount.
        VerifyWIPAmountFinishProd(ProductionOrder, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoProductionNoAdj()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO] Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount without Adjust Cost when Consumption & Output posted and Production Order finished.

        // [GIVEN] Required Costing Setups. Create and Post Consumption & Output. Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Manual, "Costing Method"::Average,
          true, true, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Post Inventory Cost to G/L report.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount without Adjust Cost.
        VerifyWIPAmountExclCostFinish(ProductionOrder, ItemNo, ItemNo2, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoLessOutputProduction()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO] Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount without Adjust Cost, when Consumption & Output posted with Reduced Output Qty and Production Order finished.

        // [GIVEN] Required Costing Setups. Create and Post Consumption & Output with Reduced Output Qty. Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Manual, "Costing Method"::Average,
          true, true, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        UpdateLessQtyOutputJournal(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Post Inventory Cost to G/L report.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount without Adjust Cost.
        VerifyWIPAmountExclCostFinish(ProductionOrder, ItemNo, ItemNo2, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoDiffConsmpOutputProd()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO] Verify Amounts in G/L entries when Consumption & Output with different Quantities posted and then Production Order finished.

        // [GIVEN] Required Costing Setups. Create and Post Consumption & Output with different Consumption and Output Qty. Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Manual, "Costing Method"::Average,
          true, true, false, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        UpdateDiffQtyConsmpJournal(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        UpdateLessQtyOutputJournal(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Post Inventory Cost to G/L report.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount without Adjust Cost.
        VerifyWIPAmountDiffConsmpNoAdj(ProductionOrder, ItemNo, ItemNo2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgFwdAutoUseNewComponentProd()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO] Verify that WIP Amount equals Calculated amount without Adjust Cost after posting cost to GL for finished production order.

        // [GIVEN] Required Costing Setups.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Forward, "Costing Method"::Average,
          true, true, true, false, false, false, false);
        ProductionOrder.Get(ProductionOrder.Status::Planned, ProductionOrderNo);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("Source No.", ProductionOrder."Source No.");
        ProductionOrder.FindFirst();

        // [WHEN] Finish Production Order & run Post Inventory Cost to G/L report.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries that WIP Amount equals Calculated amount without Adjust Cost.
        VerifyWIPAmountExclCostFinish(ProductionOrder, ItemNo, ItemNo2, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoUseNewRoutingProd()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO] Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount without Adjust Cost when Consumption and Output posted, then Production Order finished.

        // [GIVEN] Required Costing Setups. Post Consumption and Output. Finish Production Order.
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Manual, "Costing Method"::Average,
          true, true, false, false, false, true, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Post Inventory Cost to G/L report.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entries - Purchase Account Amount and WIP Account Amount equal Calculated amount without Adjust Cost.
        VerifyWIPAmountExclCostFinish(ProductionOrder, ItemNo, ItemNo2, false);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdFwdAutoAddlCurrProduction()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Cost Standard]
        // [SCENARIO] Verify that Amounts are correct in GL entries when run "Adjust Cost" - "Post to GL", then Production Order finished, then again run "Adjust Cost" - "Post to GL".

        // [GIVEN] Required Costing Setups. Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report. Update Status of Production Order to Finished.
        CreateCostingSetupAddnlCurr(
          PurchaseHeader, CurrencyCode, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Forward, "Costing Method"::Standard,
          true, true, false, false, false, false);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify WIP Account General Ledger Entries that Actual Positive amount equals calculated amount.
        VerifyWIPAddnlCurrGLEntry(ProductionOrder, CurrencyCode, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdManAutoAddlCurrProduction()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        CurrencyCode: Code[10];
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [ACY] [Production] [Cost Standard]
        // [SCENARIO] Verify correct Amounts in GL entries when Consumption posted, run "Adjust Cost" - "Post to GL", Output posted, Production Order finished, then again run "Adjust Cost" - "Post to GL".

        // [GIVEN] Required Costing Setups. Create and Post Consumption Journal and Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        // [GIVEN] Create and Post Output Journal. Change Status of Production Order to Finished.
        CreateCostingSetupAddnlCurr(
          PurchaseHeader, CurrencyCode, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Manual, "Costing Method"::Standard,
          true, true, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify WIP Account General Ledger Entries that Actual Positive amount equals calculated amount.
        VerifyWIPAddnlCurrGLEntry(ProductionOrder, CurrencyCode, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdManAutoAddlCurrDiffConsmp()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        CurrencyCode: Code[10];
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [ACY] [Production] [Cost Standard]
        // [SCENARIO] Verify that GL entries have correct Amounts when Consumption posted with different Quantity, run "Adjust Cost" - "Post to GL", Output posted, Production Order finished, then again run "Adjust Cost" - "Post to GL".

        // [GIVEN] Required Costing Setups. Create Consumption Journal, Post with Different Qty, Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        // [GIVEN] Create and Post Output Journal. Change Status of Production Order to Finished.
        CreateCostingSetupAddnlCurr(
          PurchaseHeader, CurrencyCode, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Manual, "Costing Method"::Standard,
          true, true, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        UpdateDiffQtyConsmpJournal(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify WIP Account General Ledger Entries that Actual Positive amount equals calculated amount.
        VerifyWIPAddnlCurrGLEntry(ProductionOrder, CurrencyCode, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdManAutoAddlCurrDiffOutput()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        CurrencyCode: Code[10];
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [ACY] [Production] [Cost Standard]
        // [SCENARIO] Verify that GL entries have correct Amounts when Consumption posted, run "Adjust Cost" - "Post to GL", Output posted with less Quantity, Production Order finished, then again run "Adjust Cost" - "Post to GL".

        // [GIVEN] Required Costing Setups. Create Consumption Journal, Post with Different Qty, Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        // [GIVEN] Create and Post Output Journal with Less Output Quantity. Change Status of Production Order to Finished.
        CreateCostingSetupAddnlCurr(
          PurchaseHeader, CurrencyCode, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Manual, "Costing Method"::Standard,
          true, true, false, false, false, false);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        UpdateDiffQtyConsmpJournal(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        UpdateLessQtyOutputJournal(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify WIP Account General Ledger Entries that Actual Positive amount equals calculated amount.
        VerifyWIPAddnlCurrGLEntry(ProductionOrder, CurrencyCode, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdFwdAutoAddlCurrNewComponent()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        CurrencyCode: Code[10];
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [ACY] [Production] [Cost Standard]
        // [SCENARIO] Verify that G/L entries contain correct Amounts when run "Adjust Cost" - "Post to GL", Production Order finished and again run "Adjust Cost" - "Post to GL".

        // [GIVEN] Required Costing Setups. Run Adjust Cost Item entries and Post Inventory Cost to G/L report. Change Status of Production Order from Planned to Finished.
        CreateCostingSetupAddnlCurr(
          PurchaseHeader, CurrencyCode, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Forward, "Costing Method"::Standard,
          true, true, true, false, false, false);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        ProductionOrder.Get(ProductionOrder.Status::Planned, ProductionOrderNo);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("Source No.", ProductionOrder."Source No.");
        ProductionOrder.FindFirst();
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify WIP Account General Ledger Entries that Actual amount equals calculated amount.
        VerifyWIPAddnlCurrGLEntry(ProductionOrder, CurrencyCode, ItemNo, true);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdManAutoAddlCurrNewRouting()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        CurrencyCode: Code[10];
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [ACY] [Production] [Cost Standard]
        // [SCENARIO] Verify correct amounts in GL entries when Consumption posted, run "Adjust Cost" - "Post to GL", then Output posted, then Production Order finished (with routing line), then again run "Adjust Cost" - "Post to GL".

        // [GIVEN] Required Costing Setups. Finish Production Order.
        CreateCostingSetupAddnlCurr(
          PurchaseHeader, CurrencyCode, ProductionOrderNo, ItemNo, ItemNo2, true, "Flushing Method"::Manual, "Costing Method"::Standard,
          true, true, false, false, false, true);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo2, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [WHEN] Run Adjust Cost Item Entries and Post Inventory Cost to G/L report.
        LibraryCosting.AdjustCostItemEntries(ItemNo + '..' + ItemNo2, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify WIP Account General Ledger Entries that Actual amount equals calculated amount.
        VerifyWIPAddnlCurrGLEntry(ProductionOrder, CurrencyCode, ItemNo, false);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdManAutoAddlCurrFullPurchase()
    begin
        // Covers TFS_TC_ID = 11734
        // Auto Cost Posting - True, Purchase Posting with Full Qty to Receive.
        StdManAddlCurrPurchase(
          true, false, "Flushing Method"::Manual, "Costing Method"::Standard);  // Boolean-Auto Cost Posting and Partial Posting.
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdManAutoAddlCurrPartPurchase()
    begin
        // Covers TFS_TC_ID = 11736
        // Auto Cost Posting - True, Purchase Posting with Partial Qty to Receive.
        StdManAddlCurrPurchase(
          true, true, "Flushing Method"::Manual, "Costing Method"::Standard);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdManAddlCurrFullPurchase()
    begin
        // Covers TFS_TC_ID = 11735
        // Auto Cost Posting - False, Purchase Posting with Full Qty to Receive.
        StdManAddlCurrPurchase(
          false, false, "Flushing Method"::Manual, "Costing Method"::Standard);
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdManAddlCurrPartPurchase()
    begin
        // Covers TFS_TC_ID = 11737
        // Auto Cost Posting - False, Purchase Posting with Partial Qty to Receive.
        StdManAddlCurrPurchase(
          false, true, "Flushing Method"::Manual, "Costing Method"::Standard);
    end;

    local procedure StdManAddlCurrPurchase(AutoCostPosting: Boolean; PartialPurchasePosting: Boolean; FlushingMethod: Enum "Flushing Method"; CostingMethod: Enum "Costing Method")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        ItemNo2: Code[20];
        CurrencyCode: Code[10];
    begin
        // 1. Setup: Required Costing Setups.
        CreateCostingSetupAddnlCurr(
          PurchaseHeader, CurrencyCode, ProductionOrderNo, ItemNo, ItemNo2, AutoCostPosting, FlushingMethod, CostingMethod,
          true, false, false, true, PartialPurchasePosting, false);
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseHeader);

        // 2. Exercise: Post Purchase Order with Required Quantity to Invoice and Post Inventory Cost to G/L if required.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.
        if not AutoCostPosting then
            LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify General Ledger Entries that WIP Account does not exist and Total Inventory amount equals Calculated amount.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        VerifyInvtAmountGLEntry(
          TempPurchaseLine, PurchInvHeader."No.", ItemNo, CurrencyCode, true);  // Booelan - True signifies Additional Currency.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoFxdCostAddlCurrFull()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 3651.
        // Flushing Method - Manual, Auto Cost Posting - True, Direct Unit Cost as expected.
        // Purchase Posting with Full Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgAddlCurrPurchase(true, false, Qty, Qty, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManFxdCostAddlCurrFull()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 3652.
        // Flushing Method - Manual, Auto Cost Posting - False, Direct Unit Cost as expected.
        // Purchase Posting with Full Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgAddlCurrPurchase(false, false, Qty, Qty, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoRndCostAddlCurrFull()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 3653.
        // Flushing Method - Manual, Auto Cost Posting - True, Direct Unit Cost different from expected.
        // Purchase Posting with Full Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgAddlCurrPurchase(true, true, Qty, Qty, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManRndCostAddlCurrFull()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 3654.
        // Flushing Method - Manual, Auto Cost Posting - False, Direct Unit Cost different from expected.
        // Purchase Posting with Full Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgAddlCurrPurchase(false, true, Qty, Qty, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoFxdCostAddlCurrPart()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 3655.
        // Flushing Method - Manual, Auto Cost Posting - True, Direct Unit Cost as expected.
        // Purchase Posting with Partial Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgAddlCurrPurchase(true, false, Qty, Qty - 1, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManFxdCostAddlCurrPart()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 3656.
        // Flushing Method - Manual, Auto Cost Posting - False, Direct Unit Cost as expected.
        // Purchase Posting with Partial Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgAddlCurrPurchase(false, false, Qty, Qty - 1, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManAutoRndCostAddlCurrPart()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 3657.
        // Flushing Method - Manual, Auto Cost Posting - True, Direct Unit Cost different from expected.
        // Purchase Posting with Partial Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgAddlCurrPurchase(true, true, Qty, Qty - 1, "Flushing Method"::Manual);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManRndCostAddlCurrPart()
    var
        Qty: Decimal;
    begin
        // Covers TFS_TC_ID = 3658.
        // Flushing Method - Manual, Auto Cost Posting - False, Direct Unit Cost different from expected.
        // Purchase Posting with Partial Qty to Receive.
        Qty := LibraryRandom.RandInt(10) + 50;
        AvgAddlCurrPurchase(false, true, Qty, Qty - 1, "Flushing Method"::Manual);
    end;

    local procedure AvgAddlCurrPurchase(AutoCostPosting: Boolean; DirectUnitCost: Boolean; Qty: Decimal; QtyToReceive: Decimal; FlushingMethod: Enum "Flushing Method")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        InventorySetup: Record "Inventory Setup";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ItemNo: Code[20];
        ItemNo2: Code[20];
        CurrencyCode: Code[10];
    begin
        // 1. Setup: Update Inventory Setup, Create Items with Flushing method - Manual.
        Initialize();
        LibraryERM.SetAddReportingCurrency('');
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, AutoCostPosting, false, "Automatic Cost Adjustment Type"::Never, "Average Cost Calculation Type"::Item, "Average Cost Period Type"::Day);
        CreateComponentItems(ItemNo, ItemNo2, "Costing Method"::Average, FlushingMethod, false);
        CreatePurchaseOrderAddnlCurr(PurchaseHeader, PurchaseLine, '', ItemNo, ItemNo2, Qty, QtyToReceive, DirectUnitCost);
        CurrencyCode := UpdateAddnlReportingCurrency();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Receive.
        CopyPurchaseLinesToTemp(TempPurchaseLine, PurchaseHeader);

        // 2. Exercise: Update Additional Reporting Currency with on GL Setup.
        // Post Purchase Order with required Quantity and Post Inventory Cost to G/L if required.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Invoice.
        if not AutoCostPosting then
            LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // 3. Verify: Verify General Ledger Entries that WIP Account does not exist and Total Inventory amount equals Calculated amount.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        VerifyInvtAmountGLEntry(TempPurchaseLine, PurchInvHeader."No.", ItemNo, CurrencyCode, true);  // Boolean for Additional Currency.
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckRoundedMaterialCostAfterAdjustCostItemEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        ProductionOrderNo: Code[20];
        CompItemNo: Code[20];
        ParentItemNo: Code[20];
        MaterialCost: Decimal;
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Production] [Cost Standard]
        // [SCENARIO 359997] The Material and Capacity Costs fields of the Standard Cost column, within the Statistics of a Finished Production Order is rounded after Adjust Cost

        // [GIVEN] Create Finished Production Order and post Production Journal Lines with 2 Component Items with Unit Cost Precision equal to to GLSetup."Unit-Amount Rounding Precision"
        CreateCostingSetup(
          PurchaseHeader, ProductionOrderNo, CompItemNo, ParentItemNo, true, "Flushing Method"::Manual, "Costing Method"::Standard,
          true, false, false, false, false, false, true);
        MaterialCost := GetMaterialCostFromBOMLine(ParentItemNo);
        PostProdOrderJournalLinesAndFinishProdOrder(ProductionOrderNo, ParentItemNo);

        // [WHEN] Run Adjust Cost - Item Entries
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1..%2', CompItemNo, ParentItemNo), '');

        // [THEN] Verify Material and Capacity Costs
        VerifyMaterialCost(ProductionOrderNo, MaterialCost);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler,ProdJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ComplexProdOrderTopItemLastDirectCostUpdate()
    var
        SalesHeader: Record "Sales Header";
        ProdOrder: Record "Production Order";
        ReqLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ReleasedProdOrderNo: Code[20];
        ItemNo: array[5] of Code[20];
    begin
        // [FEATURE] [Manufacturing] [Planning] [Adjust Cost - Item Entries]
        // [SCENARIO 376035] "Last Direct Cost" is updated for Top Item in complex Production Order after running "Adjust Cost - Item Entries".

        // [GIVEN] Production Item "T", with Production BOM which includes production Items "C1" (Production BOM with component "CC1") and "C2" (Production BOM with component "CC2").
        Initialize();
        PrepareItemsOfComplexProdBOM(ItemNo);

        // [GIVEN] Purchase "CC1" and "CC2".
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo[1], ItemNo[2], 1, 1, false); // specific values needed for test
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Sales Order for Item "T", run planning calculation, make supply Production Order and release it.
        CreateSalesOrder(SalesHeader, ItemNo[5], 1); // specific value needed for test
        LibraryPlanning.CalculateOrderPlanSales(ReqLine);
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");
        FindProdOrder(ProdOrder, ProdOrder.Status::"Firm Planned", ItemNo[5]);
        ReleasedProdOrderNo := LibraryManufacturing.ChangeProuctionOrderStatus(ProdOrder."No.", ProdOrder.Status, ProdOrder.Status::Released);

        // [GIVEN] Post Production Journal for Production Order Lines: "C2", "C1" and "T" in that sequence, then finish Production Order.
        FindProdOrder(ProdOrder, ProdOrder.Status::Released, ItemNo[5]);
        PostProdJournal(ProdOrder, ItemNo[3]);
        PostProdJournal(ProdOrder, ItemNo[4]);
        PostProdJournal(ProdOrder, ItemNo[5]);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ReleasedProdOrderNo);

        // [GIVEN] Add Item Charge to received components "CC1" and "CC2".
        AddItemCharge(ItemNo[1], LibraryRandom.RandDecInRange(5, 10, 2));
        AddItemCharge(ItemNo[2], LibraryRandom.RandDecInRange(5, 10, 2));

        // [GIVEN] Cost of components "CC1", "CC2" and production Items "C1", "C2" is adjusted.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3|%4', ItemNo[1], ItemNo[2], ItemNo[3], ItemNo[4]), '');

        // [WHEN] Run "Adjust Cost - Item Entries" for the production Item "T".
        LibraryCosting.AdjustCostItemEntries(ItemNo[5], '');

        // [THEN] For Item "T": "Last Direct Cost" is updated and equals to "Unit Cost".
        Item.Get(ItemNo[5]);
        Item.TestField("Last Direct Cost", Item."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ProdJournalPageHandler')]
    [Scope('OnPrem')]
    procedure LastDirectCostUpdatedOnOutputInvoiceWhenCompRevldAfterCostAdjmt()
    var
        ProdItem: Record Item;
        CompItemNo: Code[20];
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        ItemChargeAmt: Decimal;
    begin
        // [FEATURE] [Manufacturing] [Adjust Cost - Item Entries] [Last Direct Cost]
        // [SCENARIO 380782] When a BOM Component of a production Item is revalued after the Production Order is finished and the output is invoiced, the revaluation is not included in Direct Unit Cost of the Item.
        Initialize();

        // [GIVEN] Production Item "I" with a BOM component "C".
        CreateManufacturingItem(ProdItem, CompItemNo);

        // [GIVEN] The component "C" is purchased with Direct Unit Cost = "X".
        CreateAndPostPurchaseOrder(Quantity, DirectUnitCost, CompItemNo);

        // [GIVEN] Released Production Order for "I".
        // [GIVEN] The output of Item "I" and the consumption of "C" are posted.
        // [GIVEN] The Production Order is finished.
        PostProductionJournalAndFinishProdOrder(ProdItem."No.", Quantity);

        // [GIVEN] The Output is invoiced.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ProdItem."No.", CompItemNo), '');

        // [GIVEN] Item Charge is assigned to the Purchase of "C" and posted. New cost of the Component = "X + dX".
        ItemChargeAmt := LibraryRandom.RandDecInRange(5, 10, 2);
        AddItemCharge(CompItemNo, ItemChargeAmt);

        // [WHEN] Run "Adjust Cost - Item Entries" batch job.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ProdItem."No.", CompItemNo), '');

        // [THEN] Last Direct Cost of "I" = "X".
        // [THEN] Unit Cost of "I" = "X + dX".
        VerifyAvgItemCost(
          ProdItem, DirectUnitCost, DirectUnitCost + ItemChargeAmt / Quantity);
    end;

    [Test]
    [HandlerFunctions('ProdJournalPageHandler')]
    [Scope('OnPrem')]
    procedure LastDirectCostUpdatedOnOutputInvoiceWhenCompRevldBeforeCostAdjmt()
    var
        ProdItem: Record Item;
        GLSetup: Record "General Ledger Setup";
        CompItemNo: Code[20];
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        ItemChargeAmt: Decimal;
    begin
        // [FEATURE] [Manufacturing] [Adjust Cost - Item Entries] [Last Direct Cost]
        // [SCENARIO 380782] When a BOM Component of a production Item is revalued before the Production Order is finished and the output is invoiced, the revaluation is included in Direct Unit Cost of the Item.
        Initialize();
        GLSetup.Get();

        // [GIVEN] Production Item "I" with a BOM component "C".
        CreateManufacturingItem(ProdItem, CompItemNo);

        // [GIVEN] The component "C" is purchased with Direct Unit Cost = "X".
        CreateAndPostPurchaseOrder(Quantity, DirectUnitCost, CompItemNo);

        // [GIVEN] Item Charge is assigned to the Purchase of "C" and posted. New cost of the Component = "X + dX".
        ItemChargeAmt := LibraryRandom.RandDecInRange(5, 10, 2);
        AddItemCharge(CompItemNo, ItemChargeAmt);
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] Released Production Order for "I".
        // [GIVEN] The output of Item "I" and the consumption of "C" are posted.
        // [GIVEN] The Production Order is finished.
        PostProductionJournalAndFinishProdOrder(ProdItem."No.", Quantity);

        // [WHEN] Run "Adjust Cost - Item Entries" batch job.
        LibraryCosting.AdjustCostItemEntries('', '');

        // [THEN] Last Direct Cost of "I" = "X + dX".
        ProdItem.Find();
        Assert.AreNearlyEqual(
          ProdItem."Last Direct Cost", DirectUnitCost + ItemChargeAmt / Quantity, GLSetup."Unit-Amount Rounding Precision",
          StrSubstNo(WrongFieldValueErr, ProdItem.FieldName("Last Direct Cost")));

        // [THEN] Unit Cost of "I" = "X + dX".
        ProdItem.TestField("Unit Cost", ProdItem."Last Direct Cost");
    end;

    [Test]
    [HandlerFunctions('ProdJournalPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LastDirectCostAutomaticallyUpdatedWhenAvgCompRevldAndNoAccountingPeriods()
    var
        ProdItem: Record Item;
        InventorySetup: Record "Inventory Setup";
        AccountingPeriod: Record "Accounting Period";
        CompItemNo: Code[20];
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        ItemChargeAmt: Decimal;
    begin
        // [FEATURE] [Manufacturing] [Adjust Cost - Item Entries] [Last Direct Cost] [No Accounting Periods]
        // [SCENARIO 222561] Calculate average cost automatically for production item when no accounting periods
        Initialize();

        // [GIVEN] No Accounting periods
        // [GIVEN] "Automatic Cost Adjustment" is turned on in Inventory Setup
        AccountingPeriod.DeleteAll();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, false, "Automatic Cost Adjustment Type"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // [GIVEN] Production Item "I" with a BOM component "C".
        CreateManufacturingItem(ProdItem, CompItemNo);

        // [GIVEN] The component "C" is purchased with Direct Unit Cost = "X".
        CreateAndPostPurchaseOrder(Quantity, DirectUnitCost, CompItemNo);

        // [GIVEN] Released Production Order for "I".
        // [GIVEN] The output of Item "I" and the consumption of "C" are posted.
        // [GIVEN] The Production Order is finished.
        PostProductionJournalAndFinishProdOrder(ProdItem."No.", Quantity);

        // [WHEN] Item Charge is assigned to the Purchase of "C" and posted. New cost of the Component = "X + dX".
        ItemChargeAmt := LibraryRandom.RandDecInRange(5, 10, 2);
        AddItemCharge(CompItemNo, ItemChargeAmt);

        LibraryCosting.AdjustCostItemEntries(ProdItem."No.", '');

        // [THEN] Last Direct Cost of "I" = "X".
        // [THEN] Unit Cost of "I" = "X + dX".
        VerifyAvgItemCost(
          ProdItem, DirectUnitCost, DirectUnitCost + ItemChargeAmt / Quantity);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM WIP Costing Production-I");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM WIP Costing Production-I");

        GeneralLedgerSetup.Get();

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateInventoryPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM WIP Costing Production-I");
    end;

    local procedure CreateCostingSetup(var PurchaseHeader: Record "Purchase Header"; var ProductionOrderNo: Code[20]; var ItemNo: Code[20]; var ItemNo3: Code[20]; AutoCostPosting: Boolean; FlushingMethod: Enum "Flushing Method"; CostingMethod: Enum "Costing Method"; DirectUnitCost: Boolean; Invoice: Boolean; NewProdComponent: Boolean; PurchaseOnly: Boolean; PartialPurchasePosting: Boolean; NewRouting: Boolean; GetAmtPrecFromGLSetup: Boolean)
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        MachineCenter: Record "Machine Center";
        MachineCenter2: Record "Machine Center";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        NoSeries: Codeunit "No. Series";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ItemNo4: Code[20];
        WorkCenterNo: Code[20];
        RoutingNo: Code[20];
        ProductionBOMNo: Code[20];
        ItemNo2: Code[20];
        ProdOrderRoutingLineType: Option "Work Center","Machine Center";
        Qty: Decimal;
    begin
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize();
        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, AutoCostPosting, false, "Automatic Cost Adjustment Type"::Never, "Average Cost Calculation Type"::Item, "Average Cost Period Type"::Day);

        // Create Work Center and Machine Center with required Flushing method and Create Routing.
        CreateWorkCenter(WorkCenterNo, FlushingMethod);
        CreateMachineCenter(
          MachineCenter, WorkCenterNo, FlushingMethod, 1,
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(5, 2),
          LibraryRandom.RandDec(5, 2));  // Capacity important for Test.
        if NewRouting then
            CreateMachineCenter(
              MachineCenter2, WorkCenterNo, "Flushing Method"::Manual, 1,
              LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(5, 2),
              LibraryRandom.RandDec(5, 2));
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.");
        CreateRouting(WorkCenterNo, MachineCenter."No.", RoutingNo);

        // Create Items with the required Flushing method with the main Item containing Routing No. and Production BOM No.
        CreateComponentItems(ItemNo, ItemNo2, CostingMethod, FlushingMethod, GetAmtPrecFromGLSetup);
        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ItemNo, ItemNo2, 1);  // Quantity Per important for Test.
        CreateItem(
          Item, CostingMethod, Item."Reordering Policy"::"Lot-for-Lot", FlushingMethod,
          RoutingNo, ProductionBOMNo, GetAmtPrecFromGLSetup);
        ItemNo3 := Item."No.";
        Clear(Item);
        if NewProdComponent then begin
            CreateItem(
              Item, CostingMethod, Item."Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '', GetAmtPrecFromGLSetup);
            ItemNo4 := Item."No.";
        end;

        // Calculate Standard Cost for the main Item and calculate Calendar for Machine Center and Work Center.
        if CostingMethod = "Costing Method"::Standard then
            CalculateStandardCost.CalcItem(ItemNo3, false);
        CalculateMachineCntrCalendar(MachineCenter."No.");
        if NewRouting then
            CalculateMachineCntrCalendar(MachineCenter2."No.");
        CalculateWorkCntrCalendar(WorkCenterNo);

        Qty := LibraryRandom.RandInt(10) + 50;
        if not PartialPurchasePosting then
            CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, Qty, Qty, DirectUnitCost)
        else
            CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, ItemNo2, Qty, Qty - 1, DirectUnitCost);
        if NewProdComponent then
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo4, Qty, Qty, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);

        // If only Purchase Order required then exit this function.
        if PurchaseOnly then
            exit;

        if not NewProdComponent then
            LibraryManufacturing.CreateProductionOrder(
              ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo3,
              LibraryRandom.RandInt(9) + 1)
        else
            LibraryManufacturing.CreateProductionOrder(
              ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ItemNo3,
              LibraryRandom.RandInt(9) + 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProductionOrderNo := ProductionOrder."No.";
        if NewRouting then begin
            AddProdOrderRoutingLine(ProductionOrder, ProdOrderRoutingLineType::"Machine Center", MachineCenter2."No.");
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, false, true, false);  // Calculate Lines & Routings are FALSE
        end;

        if NewProdComponent then
            ReplaceProdOrderComponent(ProductionOrderNo, ItemNo2, ItemNo3, ItemNo4);
    end;

    local procedure CreateCostingSetupAddnlCurr(var PurchaseHeader: Record "Purchase Header"; var CurrencyCode: Code[10]; var ProductionOrderNo: Code[20]; var ItemNo: Code[20]; var ItemNo3: Code[20]; AutoCostPosting: Boolean; FlushingMethod: Enum "Flushing Method"; CostingMethod: Enum "Costing Method"; DirectUnitCost: Boolean; Invoice: Boolean; NewProdComponent: Boolean; PurchaseOnly: Boolean; PartialPurchasePosting: Boolean; NewRouting: Boolean)
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        MachineCenter: Record "Machine Center";
        MachineCenter2: Record "Machine Center";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        NoSeries: Codeunit "No. Series";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        WorkCenterNo: Code[20];
        RoutingNo: Code[20];
        ProductionBOMNo: Code[20];
        ItemNo2: Code[20];
        ItemNo4: Code[20];
        ProdOrderRoutingLineType: Option "Work Center","Machine Center";
        Qty: Decimal;
    begin
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize();
        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        LibraryERM.SetAddReportingCurrency('');
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, AutoCostPosting, false, "Automatic Cost Adjustment Type"::Never, "Average Cost Calculation Type"::Item, "Average Cost Period Type"::Day);

        // Create Work Center and Machine Center with required Flushing method and Create Routing.
        CreateWorkCenter(WorkCenterNo, FlushingMethod);
        CreateMachineCenter(
          MachineCenter, WorkCenterNo, FlushingMethod, 1,
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
        if NewRouting then
            CreateMachineCenter(
              MachineCenter2, WorkCenterNo, "Flushing Method"::Manual, 1,
              LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.");
        CreateRouting(WorkCenterNo, MachineCenter."No.", RoutingNo);

        // Create Items with the required Flushing method with the main Item containing Routing No. and Production BOM No.
        CreateComponentItems(ItemNo, ItemNo2, CostingMethod, FlushingMethod, false);
        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ItemNo, ItemNo2, 1);  // Quantity Per important for Test.
        CreateItem(
          Item, CostingMethod, Item."Reordering Policy"::"Lot-for-Lot", FlushingMethod,
          RoutingNo, ProductionBOMNo, false);
        ItemNo3 := Item."No.";
        Clear(Item);
        if NewProdComponent then begin
            CreateItem(
              Item, CostingMethod, Item."Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '', false);
            ItemNo4 := Item."No.";
        end;

        // Calculate Standard Cost for the main Item and calculate Calendar for Machine Center and Work Center.
        if CostingMethod = "Costing Method"::Standard then
            CalculateStandardCost.CalcItem(ItemNo3, false);
        CalculateMachineCntrCalendar(MachineCenter."No.");
        if NewRouting then
            CalculateMachineCntrCalendar(MachineCenter2."No.");
        CalculateWorkCntrCalendar(WorkCenterNo);
        Qty := LibraryRandom.RandInt(10) + 50;
        CurrencyCode := UpdateAddnlReportingCurrency();
        if not PartialPurchasePosting then
            CreatePurchaseOrderAddnlCurr(PurchaseHeader, PurchaseLine, CurrencyCode, ItemNo, ItemNo2, Qty, Qty, DirectUnitCost)
        else
            CreatePurchaseOrderAddnlCurr(PurchaseHeader, PurchaseLine, CurrencyCode, ItemNo, ItemNo2, Qty, Qty - 1, DirectUnitCost);

        if NewProdComponent then
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo4, Qty, Qty, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);

        // If only Purchase Order required then exit this function.
        if PurchaseOnly then
            exit;

        if not NewProdComponent then
            LibraryManufacturing.CreateProductionOrder(
              ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo3,
              LibraryRandom.RandInt(9) + 1)
        else
            LibraryManufacturing.CreateProductionOrder(
              ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ItemNo3,
              LibraryRandom.RandInt(9) + 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProductionOrderNo := ProductionOrder."No.";
        if NewRouting then begin
            AddProdOrderRoutingLine(ProductionOrder, ProdOrderRoutingLineType::"Machine Center", MachineCenter2."No.");
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, false, true, false);  // Calculate Lines & Routings are FALSE
        end;

        if NewProdComponent then
            ReplaceProdOrderComponent(ProductionOrderNo, ItemNo2, ItemNo3, ItemNo4);
    end;

    local procedure CreateWorkCenter(var WorkCenterNo: Code[20]; FlushingMethod: Enum "Flushing Method")
    var
        WorkCenter: Record "Work Center";
    begin
        // Create Work Center with required fields where random values not important for test; Capacity value important for Test.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Overhead Rate", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20]; FlushingMethod: Enum "Flushing Method"; Capacity: Decimal; DirectUnitCost: Decimal; IndirectCostPercentage: Decimal; OverheadRate: Decimal)
    begin
        // Create Machine Center with required fields.
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, Capacity);
        MachineCenter.Validate(Name, MachineCenter."No.");
        MachineCenter.Validate("Direct Unit Cost", DirectUnitCost);
        MachineCenter.Validate("Indirect Cost %", IndirectCostPercentage);
        MachineCenter.Validate("Overhead Rate", OverheadRate);
        MachineCenter.Validate("Flushing Method", FlushingMethod);
        MachineCenter.Modify(true);
    end;

    local procedure CreateRouting(WorkCenterNo: Code[20]; MachineCenterNo: Code[20]; var RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
        CapacityUnitOfMeasure.FindFirst();
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenterNo,
          CopyStr(LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            MaxStrLen(RoutingLine."Operation No.")), LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, MachineCenterNo,
          CopyStr(LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            MaxStrLen(RoutingLine."Operation No.")), LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        RoutingNo := RoutingHeader."No.";
    end;

    local procedure CreateComponentItems(var ItemNo: Code[20]; var ItemNo2: Code[20]; ItemCostingMethod: Enum "Costing Method"; FlushingMethod: Enum "Flushing Method"; GetAmtPrecFromGLSetup: Boolean)
    var
        Item: Record Item;
    begin
        CreateItem(Item, ItemCostingMethod, Item."Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '', GetAmtPrecFromGLSetup);
        ItemNo := Item."No.";
        Clear(Item);
        CreateItem(Item, ItemCostingMethod, Item."Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '', GetAmtPrecFromGLSetup);
        ItemNo2 := Item."No.";
    end;

    local procedure GetPrecisionFromGLSetup(GetAmtPrecFromGLSetup: Boolean) Precision: Integer
    var
        Accurancy: Text;
        DotPosIndex: Integer;
    begin
        if not GetAmtPrecFromGLSetup then
            Accurancy := Format(LibraryERM.GetAmountRoundingPrecision(), 0, 9)
        else
            Accurancy := Format(LibraryERM.GetUnitAmountRoundingPrecision(), 0, 9);
        DotPosIndex := StrPos(Accurancy, '.');
        if DotPosIndex = 0 then
            Precision := 0
        else
            Precision := StrLen(Accurancy) - DotPosIndex;
    end;

    local procedure CreateItem(var Item: Record Item; ItemCostingMethod: Enum "Costing Method"; ItemReorderPolicy: Enum "Reordering Policy"; FlushingMethod: Enum "Flushing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; GetAmtPrecFromGLSetup: Boolean)
    begin
        // Create Item with required fields where random values not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandDec(10, GetPrecisionFromGLSetup(GetAmtPrecFromGLSetup)),
          ItemReorderPolicy, FlushingMethod, RoutingNo, ProductionBOMNo);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(5, 2));
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 2));
        Item.Modify(true);

        // This is to make sure the handlers are always executed otherwise tests would fail.
        ExecuteUIHandlers();
    end;

    local procedure CreateManufacturingItem(var ProdItem: Record Item; var CompItemNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CompItemNo := LibraryInventory.CreateItemNo();
        LibraryInventory.CreateItem(ProdItem);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItemNo, 1);
        LibraryManufacturing.CreateItemManufacturing(
          ProdItem, "Costing Method"::FIFO, 0, ProdItem."Reordering Policy"::" ", "Flushing Method"::Manual, '', ProductionBOMHeader."No.");
    end;

    local procedure CalculateMachineCntrCalendar(MachineCenterNo: Code[20])
    var
        MachineCenter: Record "Machine Center";
    begin
        // Calculate Calendar for Machine Center with dates having a difference of 1 Month.
        MachineCenter.Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    local procedure CalculateWorkCntrCalendar(WorkCenterNo: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        // Calculate Calendar for Work Center with dates having a difference of 1 Month.
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; ItemNo2: Code[20]; Qty: Decimal; QtyToReceive: Decimal; RandomDirectUnitCost: Boolean)
    begin
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, Qty, QtyToReceive, RandomDirectUnitCost);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo2, Qty, QtyToReceive, RandomDirectUnitCost);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal; QtyToReceive: Decimal; RandomDirectUnitCost: Boolean)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        if RandomDirectUnitCost then
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(5, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(var Quantity: Decimal; var DirectUnitCost: Decimal; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Quantity := LibraryRandom.RandInt(10);
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, Quantity, Quantity, true);
        DirectUnitCost := PurchaseLine."Direct Unit Cost";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
    end;

    local procedure PrepareItemsOfComplexProdBOM(var ItemNo: array[5] of Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMNo: array[3] of Code[20];
    begin
        ItemNo[1] := LibraryInventory.CreateItemNo();
        ItemNo[2] := LibraryInventory.CreateItemNo();
        ManufacturingSetup.Get();
        ProductionBOMNo[1] :=
          LibraryManufacturing.CreateCertifiedProductionBOM(
            ProductionBOMHeader, ItemNo[1], 1); // specific value needed for test
        LibraryManufacturing.CreateItemManufacturing(
          Item, "Costing Method"::FIFO, 0,
          Item."Reordering Policy"::" ", "Flushing Method"::"Pick + Manual", '', ProductionBOMNo[1]);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);
        ItemNo[3] := Item."No.";

        ProductionBOMNo[2] :=
          LibraryManufacturing.CreateCertifiedProductionBOM(
            ProductionBOMHeader, ItemNo[2], 1); // specific value needed for test
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, "Costing Method"::FIFO, 0,
          Item."Reordering Policy"::" ", "Flushing Method"::"Pick + Manual", '', ProductionBOMNo[2]);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);
        ItemNo[4] := Item."No.";

        ProductionBOMNo[3] :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ItemNo[3], ItemNo[4], 1); // specific value needed for test
        Clear(Item);
        LibraryManufacturing.CreateItemManufacturing(
          Item, "Costing Method"::FIFO, 0,
          Item."Reordering Policy"::" ", "Flushing Method"::"Pick + Manual", '', ProductionBOMNo[3]);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);
        ItemNo[5] := Item."No.";
    end;

    local procedure MakeSupplyOrdersActiveOrder(DemandOrderNo: Code[20])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.FindFirst();

        GetManufacturingUserTemplate(
          ManufacturingUserTemplate, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, UserId, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
              CreateProductionOrder, ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
    end;

    local procedure FindProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
    end;

    local procedure FindProdOrderLineNo(ProductionOrder: Record "Production Order"; ItemNo: Code[20]): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        exit(ProdOrderLine."Line No.");
    end;

    local procedure PostProdJournal(ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
        LibraryManufacturing.OpenProductionJournal(
          ProductionOrder, FindProdOrderLineNo(ProductionOrder, ItemNo));
    end;

    local procedure GetMaterialCostFromBOMLine(ParentItemNo: Code[20]) MaterialCost: Decimal
    var
        ProdBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        Item.Get(ParentItemNo);
        ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.FindSet();
        repeat
            Item.Get(ProdBOMLine."No.");
            MaterialCost += Item."Single-Level Material Cost";
        until ProdBOMLine.Next() = 0;
    end;

    local procedure UpdateDiffQtyConsmpJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate(Quantity, ItemJournalLine.Quantity + 1);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure UpdateLessQtyOutputJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate("Output Quantity", ProductionOrder.Quantity - 1);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure ReplaceProdOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; NewItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Planned);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Delete(true);
        Commit();

        ProdOrderLine.SetRange(Status, ProdOrderComponent.Status::Planned);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.SetRange("Item No.", ItemNo2);
        ProdOrderLine.FindFirst();
        CreateProdOrderComponent(ProdOrderLine, ProdOrderComponent, NewItemNo, 1);  // Quantity Per important for Test.
    end;

    local procedure CreateProdOrderComponent(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20]; QuantityPer: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QuantityPer);
        ProdOrderComponent.Modify(true);
    end;

    local procedure AddProdOrderRoutingLine(ProductionOrder: Record "Production Order"; ProdOrderRoutingLineType: Option; MachineCenterNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Validate(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.Validate("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.Validate("Routing No.", ProductionOrder."Routing No.");
        ProdOrderRoutingLine.Validate("Routing Reference No.", SelectRoutingRefNo(ProductionOrder."No.", ProductionOrder."Routing No."));
        ProdOrderRoutingLine.Validate(
          "Operation No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(ProdOrderRoutingLine.FieldNo("Operation No."), DATABASE::"Prod. Order Routing Line"), 1,
            MaxStrLen(ProdOrderRoutingLine."Operation No.") - 1));
        ProdOrderRoutingLine.Insert(true);
        ProdOrderRoutingLine.Validate(Type, ProdOrderRoutingLineType);
        ProdOrderRoutingLine.Validate("No.", MachineCenterNo);
        ProdOrderRoutingLine.Validate("Setup Time", LibraryRandom.RandDec(5, 2));
        ProdOrderRoutingLine.Validate("Run Time", LibraryRandom.RandDec(5, 2));
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure SelectRoutingRefNo(ProductionOrderNo: Code[20]; ProdOrderRoutingNo: Code[20]): Integer
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderRoutingNo);
        ProdOrderRoutingLine.FindFirst();
        exit(ProdOrderRoutingLine."Routing Reference No.");
    end;

    local procedure UpdateAddnlReportingCurrency() CurrencyCode: Code[10]
    begin
        // Create new Currency code and set Residual Gains Account and Residual Losses Account for Currency.
        CurrencyCode := CreateCurrency();
        Commit();

        // Update Additional Reporting Currency on G/L setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SelectGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        // Select Account from General Ledger Account of type Posting.
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.FindFirst();
        exit(GLAccount."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Create new currency and validate the required GL Accounts.
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", SelectGLAccountNo());
        Currency.Validate("Residual Losses Account", SelectGLAccountNo());
        Currency.Validate("Realized G/L Gains Account", SelectGLAccountNo());
        Currency.Validate("Realized G/L Losses Account", SelectGLAccountNo());
        Currency.Modify(true);
        Commit();  // Required to run the Test Case on RTC.

        // Create Currency Exchange Rate.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());

        // Using RANDOM Exchange Rate Amount and Adjustment Exchange Rate, between 100 and 400 (Standard Value).
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100 * LibraryRandom.RandInt(4));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amt always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 2 * CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure CreatePurchaseOrderAddnlCurr(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; Qty: Decimal; QtyToReceive: Decimal; RandomDirectUnitCost: Boolean)
    begin
        CreatePurchaseHeaderAddnlCurr(PurchaseHeader, CurrencyCode);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, Qty, QtyToReceive, RandomDirectUnitCost);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo2, Qty, QtyToReceive, RandomDirectUnitCost);
    end;

    local procedure CreatePurchaseHeaderAddnlCurr(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, SelectAddnlCurrVendor(CurrencyCode));
    end;

    local procedure SelectAddnlCurrVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        // Select a Vendor and modify if Location Code is not blank.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
    end;

    local procedure CopyPurchaseLinesToTemp(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            TempPurchaseLine := PurchaseLine;
            TempPurchaseLine.Insert();
        until PurchaseLine.Next() = 0;
    end;

    local procedure PostProdOrderJournalLinesAndFinishProdOrder(ProductionOrderNo: Code[20]; ParentItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryManufacturing.CreateProdItemJournal(
          ItemJournalBatch, '', ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ParentItemNo, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
    end;

    local procedure PostProductionJournalAndFinishProdOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        PostProdJournal(ProductionOrder, ItemNo);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
    end;

    local procedure VerifyWIPAmountGLEntry(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Positive: Boolean)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        SelectGLEntry(GLEntry, InventoryPostingSetup."WIP Account", ProductionOrder."No.");

        // Verify total amount in G/L Entry for WIP Account is Zero.
        VerifyZeroWIPAmount(CalculateGLEntryTotalAmount(GLEntry, false));  // Boolean False signifies Additional Currency does not exist.

        // Verify positive WIP Account amount is equal to calculated amount; last parameter True signifies Adjust Cost Item Entries has run.
        VerifyTotalWIPAmount(ProductionOrder, CalculateGLEntryRequiredAmount(GLEntry, Positive), true);
    end;

    local procedure SelectInventoryPostingSetup(var InventoryPostingSetup: Record "Inventory Posting Setup"; ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();
    end;

    local procedure SelectGLEntry(var GLEntry: Record "G/L Entry"; PostingSetupAccount: Code[20]; DocumentNo: Code[20])
    begin
        // Select set of G/L Entries for the specified Account.
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", PostingSetupAccount);
        GLEntry.FindSet();
    end;

    local procedure CalculateGLEntryTotalAmount(var GLEntry: Record "G/L Entry"; AddnlCurrency: Boolean): Decimal
    var
        TotalAmount: Decimal;
    begin
        if not AddnlCurrency then
            repeat
                TotalAmount += GLEntry.Amount;
            until GLEntry.Next() = 0
        else
            repeat
                TotalAmount += GLEntry."Additional-Currency Amount";
            until GLEntry.Next() = 0;
        exit(TotalAmount);
    end;

    local procedure CalculateGLEntryRequiredAmount(var GLEntry: Record "G/L Entry"; Positive: Boolean): Decimal
    var
        TotalAmount: Decimal;
        GLCount: Integer;
    begin
        // Calculate the sum for required G/L Entries.
        if Positive then begin
            GLEntry.SetFilter(Amount, '>0');
            GLEntry.FindSet();
            // Total amount for positive WIP entries.
            repeat
                TotalAmount += GLEntry.Amount;
            until GLEntry.Next() = 0;
        end else begin
            GLEntry.FindSet();
            // Total amount for WIP Entries except the last G/L entry to exclude the Balancing amount.
            for GLCount := 1 to GLEntry.Count - 1 do begin
                TotalAmount += GLEntry.Amount;
                GLEntry.Next();
            end;
        end;
        exit(TotalAmount);
    end;

    local procedure VerifyZeroWIPAmount(TotalAmount: Decimal)
    begin
        // Verify total WIP Account amount is Zero.
        Assert.AreEqual(0, TotalAmount, SumMustBeZeroErr);
    end;

    local procedure VerifyTotalWIPAmount(ProductionOrder: Record "Production Order"; ActualAmount: Decimal; AdjustCost: Boolean)
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ExpectedWIPAmount: Decimal;
        TotalConsumptionValue: Decimal;
    begin
        // Last parameter True signifies Finished Production Order.
        SelectProductionOrderComponent(ProdOrderComponent, ProductionOrder, true);
        Item.Get(ProdOrderComponent."Item No.");
        repeat
            TotalConsumptionValue :=
              TotalConsumptionValue +
              ConsumptionValue(ProductionOrder.Quantity, ProdOrderComponent."Quantity per", ProdOrderComponent."Item No.");
            if (Item."Costing Method" = Item."Costing Method"::Average) and AdjustCost then
                TotalConsumptionValue :=
                  TotalConsumptionValue +
                  OverheadIndirectValue(ProductionOrder.Quantity, ProdOrderComponent."Quantity per", ProdOrderComponent."Item No.");
        until ProdOrderComponent.Next() = 0;

        ExpectedWIPAmount :=
          TotalConsumptionValue + DirectIndirectMachineCntrCost(ProductionOrder."Routing No.", Item."No.", ProductionOrder.Quantity) +
          DirectIndirectWorkCntrCost(ProductionOrder."Routing No.", Item."No.", ProductionOrder.Quantity);

        // Verify WIP Account amounts and expected WIP amounts are equal.
        Assert.AreNearlyEqual(
          Round(ExpectedWIPAmount, GeneralLedgerSetup."Amount Rounding Precision"),
          ActualAmount, GeneralLedgerSetup."Amount Rounding Precision", AmountsDoNotMatchErr);
    end;

    local procedure SelectProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; Finished: Boolean)
    begin
        if Finished then
            ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.")
        else
            ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrder."No.");
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindSet();
    end;

    local procedure ConsumptionValue(ProductionOrderQty: Decimal; ProductionBOMLineQtyPer: Decimal; ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        if Item."Costing Method" = Item."Costing Method"::Standard then
            exit(ProductionOrderQty * ProductionBOMLineQtyPer * Item."Standard Cost");
        exit(ProductionOrderQty * ProductionBOMLineQtyPer * Item."Last Direct Cost");
    end;

    local procedure DirectIndirectMachineCntrCost(RoutingNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal): Decimal
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MachineCenter: Record "Machine Center";
        TimeSubtotal: Decimal;
        MachineCenterAmount: Decimal;
    begin
        // Calculate Cost Amount for Machine Center.
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Machine Center");
        if ProdOrderRoutingLine.FindSet() then
            repeat
                MachineCenter.Get(ProdOrderRoutingLine."No.");
                TimeSubtotal := CalculateTimeSubTotal(ProdOrderRoutingLine, ItemNo, Quantity);
                MachineCenterAmount +=
                  (TimeSubtotal * MachineCenter."Direct Unit Cost") +
                  (TimeSubtotal *
                   ((MachineCenter."Indirect Cost %" / 100) * MachineCenter."Direct Unit Cost" + MachineCenter."Overhead Rate"));
            until ProdOrderRoutingLine.Next() = 0;
        exit(MachineCenterAmount);
    end;

    local procedure DirectIndirectWorkCntrCost(RoutingNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal): Decimal
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        TimeSubtotal: Decimal;
        WorkCenterAmount: Decimal;
    begin
        // Calculate Cost Amount for Work Center.
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        if ProdOrderRoutingLine.FindSet() then
            repeat
                WorkCenter.Get(ProdOrderRoutingLine."No.");
                TimeSubtotal := CalculateTimeSubTotal(ProdOrderRoutingLine, ItemNo, Quantity);
                WorkCenterAmount :=
                  (TimeSubtotal * WorkCenter."Direct Unit Cost") +
                  (TimeSubtotal * ((WorkCenter."Indirect Cost %" / 100) * WorkCenter."Direct Unit Cost" + WorkCenter."Overhead Rate"));
            until ProdOrderRoutingLine.Next() = 0;
        exit(WorkCenterAmount);
    end;

    local procedure CalculateTimeSubTotal(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ItemNo: Code[20]; Quantity: Decimal): Decimal
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        if Item."Flushing Method" = Item."Flushing Method"::Manual then
            exit(ProdOrderRoutingLine."Setup Time" + ProdOrderRoutingLine."Run Time");
        exit(ProdOrderRoutingLine."Setup Time" + Quantity * ProdOrderRoutingLine."Run Time");
    end;

    local procedure AddItemCharge(ItemNo: Code[20]; Amount: Decimal)
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();

        ItemChargeAssignmentPurch.Init();
        ItemChargeAssignmentPurch.Validate("Document Type", PurchaseHeader."Document Type");
        ItemChargeAssignmentPurch.Validate("Document No.", PurchaseHeader."No.");
        ItemChargeAssignmentPurch.Validate("Document Line No.", PurchaseLine."Line No.");
        ItemChargeAssignmentPurch.Validate("Item Charge No.", PurchaseLine."No.");

        ItemChargeAssignmentPurch.Validate("Applies-to Doc. Type", ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt);
        ItemChargeAssignmentPurch.Validate("Applies-to Doc. No.", PurchRcptLine."Document No.");
        ItemChargeAssignmentPurch.Validate("Applies-to Doc. Line No.", PurchRcptLine."Line No.");

        ItemChargeAssignmentPurch.Validate("Unit Cost", Amount);
        ItemChargeAssignmentPurch.Validate("Item No.", ItemNo);
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssignmentPurch.Insert(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure VerifyInvtAccountNotInGLEntry(ItemNo: Code[20]; ProductionOrderNo: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        GLEntry.SetRange("Document No.", ProductionOrderNo);
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."Inventory Account");

        // Verify no row exist for Inventory Account in G/L Entry.
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyInvtAmountGLEntry(var TempPurchaseLine: Record "Purchase Line" temporary; PurchInvHeaderNo: Code[20]; ItemNo: Code[20]; CurrencyCode: Code[10]; AddnlCurrency: Boolean)
    var
        GLEntry: Record "G/L Entry";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);

        // Verify that no row exists for WIP Account.
        VerifyWIPAccountNotInGLEntry(PurchInvHeaderNo, ItemNo);

        // Verify sum of Inventory Account amounts equal to calculated amount.
        SelectGLEntry(GLEntry, InventoryPostingSetup."Inventory Account", PurchInvHeaderNo);
        VerifyTotalInvtAmount(TempPurchaseLine, CalculateGLEntryTotalAmount(GLEntry, AddnlCurrency), CurrencyCode, AddnlCurrency);
    end;

    local procedure VerifyWIPAccountNotInGLEntry(PurchInvHeaderNo: Code[20]; ItemNo: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        GLEntry.SetRange("Document No.", PurchInvHeaderNo);
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."WIP Account");

        // Verify no row exist for WIP Account in G/L Entry.
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyTotalInvtAmount(var TempPurchaseLine: Record "Purchase Line" temporary; ActualTotalAmount: Decimal; CurrencyCode: Code[10]; AddnlCurrency: Boolean)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        ExpectedInventoryAmount: Decimal;
    begin
        ExpectedInventoryAmount := ItemTotalCostValue(TempPurchaseLine) + OverheadIndirectInvtCostValue(TempPurchaseLine);

        // Verify Inventory Account amounts and calculated Inventory amounts are equal.
        if AddnlCurrency then begin
            Currency.Get(CurrencyCode);
            CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
            CurrencyExchangeRate.FindFirst();
            Assert.AreNearlyEqual(
              Round(
                CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount" *
                ExpectedInventoryAmount,
                Currency."Amount Rounding Precision"),
              ActualTotalAmount, GeneralLedgerSetup."Amount Rounding Precision", GLEntryNoRowExistErr);
        end else
            Assert.AreNearlyEqual(
              ExpectedInventoryAmount, ActualTotalAmount, GeneralLedgerSetup."Amount Rounding Precision", GLEntryNoRowExistErr);
    end;

    local procedure VerifyMaterialCost(ProductionOrderNo: Code[20]; ExpectedMaterialCost: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        ActualMaterialCost: Decimal;
        StdCost: array[6] of Decimal;
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Finished);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindSet();
        repeat
            MfgCostCalculationMgt.CalcProdOrderLineStdCost(
              ProdOrderLine, 1, LibraryERM.GetUnitAmountRoundingPrecision(),
              StdCost[1], StdCost[2], StdCost[3], StdCost[4], StdCost[5]);
            ActualMaterialCost += StdCost[1] / ProdOrderLine."Quantity (Base)";
        until ProdOrderLine.Next() = 0;

        Assert.AreEqual(ExpectedMaterialCost, ActualMaterialCost, ExpectedMaterialCostErr);
    end;

    local procedure ItemTotalCostValue(var TempPurchaseLine: Record "Purchase Line" temporary) ItemCost: Decimal
    begin
        TempPurchaseLine.FindSet();
        repeat
            ItemCost += (TempPurchaseLine."Direct Unit Cost" * TempPurchaseLine."Quantity Received");
        until TempPurchaseLine.Next() = 0;
        exit(ItemCost);
    end;

    local procedure OverheadIndirectInvtCostValue(var TempPurchaseLine: Record "Purchase Line" temporary) OverheadIndirectCost: Decimal
    var
        Item: Record Item;
    begin
        TempPurchaseLine.FindSet();
        repeat
            Item.Get(TempPurchaseLine."No.");
            if Item."Costing Method" = Item."Costing Method"::Standard then
                OverheadIndirectCost :=
                  OverheadIndirectCost +
                  ((Item."Overhead Rate" + (Item."Indirect Cost %" / 100 * TempPurchaseLine."Direct Unit Cost")) * Item.Inventory) +
                  (((Item."Standard Cost" - TempPurchaseLine."Direct Unit Cost") * TempPurchaseLine."Quantity Received") +
                   (Item."Overhead Rate" + (Item."Indirect Cost %" / 100 * TempPurchaseLine."Direct Unit Cost")) * Item.Inventory)
            else begin
                // Calculation for Costing Method Average.
                Item.CalcFields(Inventory);
                OverheadIndirectCost :=
                  OverheadIndirectCost +
                  ((Item."Overhead Rate" + (Item."Indirect Cost %" / 100 * TempPurchaseLine."Direct Unit Cost")) * Item.Inventory);
            end;
        until TempPurchaseLine.Next() = 0;
        exit(OverheadIndirectCost);
    end;

    local procedure VerifyWIPAmountConsumpOutput(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; PostOutput: Boolean)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
        ProdOrderComponent: Record "Prod. Order Component";
        ExpectedWIPAmount: Decimal;
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        SelectGLEntry(GLEntry, InventoryPostingSetup."WIP Account", ProductionOrder."No.");
        SelectProductionOrderComponent(ProdOrderComponent, ProductionOrder, false);
        repeat
            ExpectedWIPAmount +=
              ConsumptionValue(ProductionOrder.Quantity, ProdOrderComponent."Quantity per", ProdOrderComponent."Item No.") +
              OverheadIndirectValue(ProductionOrder.Quantity, ProdOrderComponent."Quantity per", ProdOrderComponent."Item No.");
        until ProdOrderComponent.Next() = 0;

        if PostOutput then
            ExpectedWIPAmount +=
              DirectIndirectMachineCntrCost(ProductionOrder."Routing No.", ItemNo, ProductionOrder.Quantity) +
              DirectIndirectWorkCntrCost(ProductionOrder."Routing No.", ItemNo, ProductionOrder.Quantity);

        // Verify WIP Account amount after Consumption is equal to calculated amount.
        Assert.AreNearlyEqual(
          ExpectedWIPAmount, CalculateGLEntryTotalAmount(GLEntry, false), GeneralLedgerSetup."Amount Rounding Precision",
          GLEntryNoRowExistErr);
    end;

    local procedure OverheadIndirectValue(ProductionOrderQty: Decimal; ProductionBOMLineQtyPer: Decimal; ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
        OverheadIndirectCost: Decimal;
    begin
        Item.Get(ItemNo);
        OverheadIndirectCost :=
          OverheadIndirectCost +
          ((Item."Overhead Rate" + (Item."Indirect Cost %" / 100 * Item."Last Direct Cost")) *
           ProductionOrderQty * ProductionBOMLineQtyPer);
        exit(OverheadIndirectCost);
    end;

    local procedure VerifyWIPAmountFinishProd(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Positive: Boolean)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        SelectGLEntry(GLEntry, InventoryPostingSetup."WIP Account", ProductionOrder."No.");

        // Verify Total Amount in G/L Entry for WIP Account is Zero.
        VerifyZeroWIPAmount(CalculateGLEntryTotalAmount(GLEntry, false));

        // Verify WIP Account amount is equal to calculated amount; last parameter True signifies Adjust Cost Item Entries has run.
        VerifyTotalWIPAmount(ProductionOrder, CalculateGLEntryRequiredAmount(GLEntry, Positive), true);
    end;

    local procedure VerifyPurchaseAccountGLEntry(var TempPurchaseLine: Record "Purchase Line" temporary; BuyFromVendorNo: Code[20]; PurchInvHeaderNo: Code[20]; ItemNo: Code[20])
    var
        Item: Record Item;
        Vendor: Record Vendor;
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        Vendor.Get(BuyFromVendorNo);
        Item.Get(ItemNo);
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        GLEntry.SetRange("Document No.", PurchInvHeaderNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Purch. Account");
        GLEntry.FindFirst();

        // Verify WIP Account amounts and calculated WIP amounts are equal.
        Assert.AreNearlyEqual(
          ItemTotalCostValue(TempPurchaseLine), GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision", GLEntryNoRowExistErr);
    end;

    local procedure VerifyWIPAmountExclCostFinish(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemNo2: Code[20]; AdjustCost: Boolean)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        SelectGLEntry(GLEntry, InventoryPostingSetup."WIP Account", ProductionOrder."No.");

        // Verify Total Amount in G/L Entry for WIP Account is Zero only when Adjust Cost Item Entries has run.
        if AdjustCost then
            VerifyZeroWIPAmount(CalculateGLEntryTotalAmount(GLEntry, false));

        // Verify WIP Account amount is equal to calculated amount.
        VerifyTotalWIPAmount(ProductionOrder, CalculateGLEntryAmountExclCost(GLEntry, ProductionOrder."No.", ItemNo2), AdjustCost);
    end;

    local procedure CalculateGLEntryAmountExclCost(var GLEntry: Record "G/L Entry"; ProductionOrderNo: Code[20]; ItemNo: Code[20]): Decimal
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        TotalAmount: Decimal;
        CalculatedAmount: Decimal;
    begin
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrderNo);
        Item.Get(ItemNo);
        CalculatedAmount := ProductionOrder.Quantity * Item."Last Direct Cost";
        GLEntry.SetFilter(Amount, '<>%1', -Round(CalculatedAmount, 0.01));  // Excluding the balancing cost.
        GLEntry.FindSet();

        // Total amount for required WIP entries.
        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        exit(TotalAmount);
    end;

    local procedure VerifyWIPAmountDiffConsmpNoAdj(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ExpectedWIPAmount: Decimal;
        TotalConsumptionValue: Decimal;
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        SelectGLEntry(GLEntry, InventoryPostingSetup."WIP Account", ProductionOrder."No.");

        // Last parameter True signifies Finished Production Order.
        SelectProductionOrderComponent(ProdOrderComponent, ProductionOrder, true);
        repeat
            ItemNo := ProdOrderComponent."Item No.";
            Item.Get(ItemNo);
            ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
            TotalConsumptionValue :=
              TotalConsumptionValue + (ProdOrderComponent."Act. Consumption (Qty)" * Item."Last Direct Cost");
        until ProdOrderComponent.Next() = 0;

        ExpectedWIPAmount :=
          TotalConsumptionValue + DirectIndirectMachineCntrCost(ProductionOrder."Routing No.", ItemNo, ProductionOrder.Quantity) +
          DirectIndirectWorkCntrCost(ProductionOrder."Routing No.", ItemNo, ProductionOrder.Quantity);

        // Verify WIP Account amounts and calculated WIP amounts are equal.
        Assert.AreNearlyEqual(
          ExpectedWIPAmount, CalculateGLEntryAmountExclCost(GLEntry, ProductionOrder."No.", ItemNo2),
          GeneralLedgerSetup."Amount Rounding Precision", GLEntryNoRowExistErr);
    end;

    local procedure VerifyWIPAddnlCurrGLEntry(ProductionOrder: Record "Production Order"; CurrencyCode: Code[10]; ItemNo: Code[20]; Positive: Boolean)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        SelectInventoryPostingSetup(InventoryPostingSetup, ItemNo);
        SelectGLEntry(GLEntry, InventoryPostingSetup."WIP Account", ProductionOrder."No.");

        // Verify WIP amount is equal to calculated amount in Additional Currency.
        VerifyTotalWIPAddnlCurrAmount(ProductionOrder, CurrencyCode, CalculateGLAddnlCurrAmount(GLEntry, Positive));
    end;

    local procedure CalculateGLAddnlCurrAmount(var GLEntry: Record "G/L Entry"; Positive: Boolean) ActualAddnlCurrencyAmount: Decimal
    var
        GLCount: Integer;
    begin
        // Calculate the sum for required G/L Entries.
        if Positive then begin
            GLEntry.SetFilter("Additional-Currency Amount", '>0');
            GLEntry.FindSet();
            // Total Additional Currency amount for positive WIP entries.
            repeat
                ActualAddnlCurrencyAmount += GLEntry."Additional-Currency Amount";
            until GLEntry.Next() = 0;
        end else begin
            GLEntry.FindSet();
            // Total Additional currency amount for WIP Entries except the last G/L entry to exclude the Balancing amount.
            for GLCount := 1 to GLEntry.Count - 1 do begin
                ActualAddnlCurrencyAmount += GLEntry."Additional-Currency Amount";
                GLEntry.Next();
            end;
        end;
        exit(ActualAddnlCurrencyAmount);
    end;

    local procedure VerifyTotalWIPAddnlCurrAmount(ProductionOrder: Record "Production Order"; CurrencyCode: Code[10]; ActualAddnlCurrencyAmount: Decimal)
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        CalculatedWIPAmount: Decimal;
        TotalConsumptionValue: Decimal;
    begin
        Currency.Get(CurrencyCode);
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();

        // Last parameter True signifies Finished Production Order.
        SelectProductionOrderComponent(ProdOrderComponent, ProductionOrder, true);
        repeat
            Item.Get(ProdOrderComponent."Item No.");
            ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
            TotalConsumptionValue += ProdOrderComponent."Act. Consumption (Qty)" * Item."Standard Cost";
        until ProdOrderComponent.Next() = 0;

        CalculatedWIPAmount :=
          TotalConsumptionValue +
          DirectIndirectMachineCntrCost(ProductionOrder."Routing No.", ProdOrderComponent."Item No.", ProductionOrder.Quantity) +
          DirectIndirectWorkCntrCost(ProductionOrder."Routing No.", ProdOrderComponent."Item No.", ProductionOrder.Quantity);

        // Verify WIP Additional Currency amount from GL Entry and Calculated Additional Currency amount are equal.
        Assert.AreNearlyEqual(
          Round(
            CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount" * CalculatedWIPAmount,
            Currency."Amount Rounding Precision"),
          ActualAddnlCurrencyAmount, Currency."Amount Rounding Precision" * 4,
          GLEntryNoRowExistErr);
    end;

    local procedure VerifyAvgItemCost(var Item: Record Item; LastDirectCost: Decimal; UnitCost: Decimal)
    begin
        Item.Find();
        Assert.AreNearlyEqual(
            LastDirectCost, Item."Last Direct Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
            StrSubstNo(WrongFieldValueErr, Item.FieldName("Last Direct Cost")));
        Assert.AreNearlyEqual(
            UnitCost, Item."Unit Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
            StrSubstNo(WrongFieldValueErr, Item.FieldName("Unit Cost")));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdJournalPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", LibraryVariableStorage.DequeueText());
        ItemJournalLine.FindSet();
        repeat
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
        until ItemJournalLine.Next() = 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateStdCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Calculate Standard Cost for All Level when Costing Method Standard.
        Choice := 2;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure ExecuteUIHandlers()
    begin
        // Generate dummy messages.
        Message(ExpectedMsg);
        if Confirm(ExpectedCostPostingQst) then;
    end;
}

