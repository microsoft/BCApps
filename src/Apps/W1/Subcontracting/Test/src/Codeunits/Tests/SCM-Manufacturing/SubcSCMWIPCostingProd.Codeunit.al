// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.Subcontracting.Test;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 149914 "Subc SCM WIP Costing Prod."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Subcontracting] [Adjust Cost Item Entries] [Post Inventory to G/L] [SCM]
        isInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        SubcManagementLibrary: Codeunit "Subc. Management Library";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        AmountDoNotMatchErr: Label 'The WIP amount totals must be equal.';

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconMan()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing of Subcontracting Order with Flushing method - Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time,
#pragma warning disable AL0432
            "Flushing Method"::Manual, "Flushing Method"::Manual,
#pragma warning restore AL0432,
            "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconManCostDiff()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing of Subcontracting Order with Flushing method - Manual. Subcontract and Output Cost different from Expected.
        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units,
#pragma warning disable AL0432
            "Flushing Method"::Manual, "Flushing Method"::Manual,
#pragma warning restore AL0432
            "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, false, true, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconBackward()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing of Subcontracting Order with Flushing method - Backward and of Subcontract Work center as Manual.
        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward,
#pragma warning disable AL0432
            "Flushing Method"::Manual,
#pragma warning restore AL0432
            "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgSubconBackward()
    begin
        // [FEATURE] [Cost Average]
        // [SCENARIO] Test Average Costing of Subcontracting Order with Flushing method - Backward and of Subcontract Work center as Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward,
#pragma warning disable AL0432
            "Flushing Method"::Manual,
#pragma warning restore AL0432, 
            "Costing Method"::Average,
            "Production Order Status"::Released, true, false, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconManCostDiffAddCurr()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing for Additional Currency of Subcontracting Order with Flushing method - Manual. Subcontract and Output Cost different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units,
#pragma warning disable AL0432
            "Flushing Method"::Manual, "Flushing Method"::Manual,
#pragma warning restore AL0432
            "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, true, true, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconBackwardAddCurr()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing for Additional Currency of Subcontracting Order with Flushing method - Backward and of Subcontract Work center as Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward,
#pragma warning disable AL0432
            "Flushing Method"::Manual,
#pragma warning restore AL0432 
            "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, true, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOSubconBackward()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing of Subcontracting Order with Flushing method - Backward and of Subcontract Work center as Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward,
#pragma warning disable AL0432
            "Flushing Method"::Manual,
#pragma warning restore AL0432
            "Costing Method"::FIFO,
            "Production Order Status"::Released, true, false, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOSubconManCostDiff()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing of Subcontracting Order with Flushing method - Manual. Output Cost and Subcontract Cost are different from expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time,
#pragma warning disable AL0432
"Flushing Method"::Manual, "Flushing Method"::Manual,
#pragma warning restore AL0432
            "Costing Method"::FIFO,
            "Production Order Status"::Released, true, false, false, true, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOSubconBackwardAddCurr()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing : Subcontracting Order with Flushing method - Backward and Subcontract Work center - Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward,
#pragma warning disable AL0432
            "Flushing Method"::Manual,
#pragma warning restore AL0432
            "Costing Method"::FIFO,
            "Production Order Status"::Released, true, false, true, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOSubconManCostDiffAddCurr()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing : Subcontracting Order with Flushing method - Manual. Output Cost and Subcontract Cost are different from expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time,
#pragma warning disable AL0432
            "Flushing Method"::Manual, "Flushing Method"::Manual,
#pragma warning restore AL0432
            "Costing Method"::FIFO,
            "Production Order Status"::Released, true, false, true, true, true, false, false, false, false, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Subc SCM WIP Costing Prod.");
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Subc SCM WIP Costing Prod.");

        SetUnitAmountRoundingPrecision();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateInventoryPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Subc SCM WIP Costing Prod.");
    end;

    local procedure SetUnitAmountRoundingPrecision()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Unit-Amount Rounding Precision" := 0.00001;
        GLSetup.Modify();
    end;

    [Normal]
    local procedure SCMWIPCostingProductionII(UnitCostCalcType: Enum "Unit Cost Calculation Type"; FlushingMethod: Enum "Flushing Method"; SubcontractFlushingMethod: Enum "Flushing Method"; CostingMethod: Enum "Costing Method"; ProductionOrderStatus: Enum "Production Order Status"; Subcontract: Boolean; UpdateProductionComponent: Boolean; AdditionalCurrencyExist: Boolean; SubcontractCostDiff: Boolean; OutputCostDiff: Boolean; RunSetupTimeCostDiff: Boolean; DeleteConsumptionJrnl: Boolean; ConsumptionCostDiff: Boolean; UpdateProdOrderRouting: Boolean; AdjustExchangeRatesGLSetup: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        InventorySetup: Record "Inventory Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        TempPurchaseLine: Record "Purchase Line" temporary;
        NoSeries: Codeunit "No. Series";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ShopCalendarCode: Code[10];
        ProductionBOMNo: Code[20];
        MachineCenterNo: Code[20];
        MachineCenterNo2: Code[20];
        MachineCenterNo3: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
        RoutingNo: Code[20];
        ParentItemNo: Code[20];
        ComponentItemNos: array[3] of Code[20];
        CurrencyCode: Code[10];
        ProductionOrderNo: Code[20];
        AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type";
        SetupTime: Decimal;
        RunTime: Decimal;
    begin
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required WIP setups with Flushing method as Manual with Subcontract.
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize();
        RaiseConfirmHandler();
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, "Average Cost Period Type"::Day);
        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();
        if AdditionalCurrencyExist then
            CurrencyCode := UpdateAddnlReportingCurrency()
        else
            LibraryERM.SetAddReportingCurrency('');

        // Create Work Center and Machine Center with Flushing method -Manual.
        // Create Work Center for Subcontractor with Flushing method -Manual.
        // Create Routing.
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, FlushingMethod, false, UnitCostCalcType, '');
        CreateMachineCenter(MachineCenterNo, WorkCenterNo, FlushingMethod);
        CreateMachineCenter(MachineCenterNo2, WorkCenterNo, FlushingMethod);
        if UpdateProdOrderRouting then
            CreateMachineCenter(MachineCenterNo3, WorkCenterNo, FlushingMethod);
        if Subcontract then
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, SubcontractFlushingMethod, true, UnitCostCalcType, CurrencyCode)
        else
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, FlushingMethod, false, UnitCostCalcType, CurrencyCode);
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.");
        CreateRouting(RoutingNo, MachineCenterNo, MachineCenterNo2, WorkCenterNo, WorkCenterNo2);

        // Create Items with Flushing method - Manual with the Parent Item containing Routing No. and Production BOM No.
        ComponentItemNos[1] := CreateItem(CostingMethod, Enum::"Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '');
        ComponentItemNos[2] := CreateItem(CostingMethod, Enum::"Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '');

        if UpdateProductionComponent then
            ComponentItemNos[3] := CreateItem(Enum::"Costing Method"::Standard, Enum::"Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '');

        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItemNos[1], ComponentItemNos[2], 1); // value important.
        ParentItemNo := CreateItem(CostingMethod, Enum::"Reordering Policy"::"Lot-for-Lot", FlushingMethod, RoutingNo, ProductionBOMNo);

        // Calculate Standard Cost for Parent Item, if Costing Method is Standard.
        // Calculate Calendar for Work Center with dates having a difference of 5 weeks.
        // Create and Post Purchase Order as Receive and Invoice.
        if CostingMethod = Enum::"Costing Method"::Standard then
            CalculateStandardCost.CalcItem(ParentItemNo, false);
        CalculateCalendar(MachineCenterNo, MachineCenterNo2, WorkCenterNo, WorkCenterNo2);
        if not AdditionalCurrencyExist then
            CreatePurchaseOrder(
              PurchaseHeader, ComponentItemNos[1], ComponentItemNos[2], ComponentItemNos[3], LibraryRandom.RandIntInRange(10, 100) + 10,
              LibraryRandom.RandIntInRange(10, 100) + 10, LibraryRandom.RandIntInRange(10, 100) + 50, UpdateProductionComponent)
        else
            CreatePurchaseOrderAddnlCurr(PurchaseHeader, CurrencyCode, ComponentItemNos[1], ComponentItemNos[2], ComponentItemNos[3],
              LibraryRandom.RandIntInRange(10, 100) + 10, UpdateProductionComponent);

        if AdjustExchangeRatesGLSetup then begin
            UpdateExchangeRate(CurrencyCode);
            LibraryERM.RunExchRateAdjustment(
              CurrencyCode, WorkDate(), WorkDate(), PurchaseHeader."No.", WorkDate(), LibraryUtility.GenerateGUID(), true);
        end;

        // Create and Refresh Production Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrderStatus, ProductionOrder."Source Type"::Item, ParentItemNo, LibraryRandom.RandInt(10) + 5);
        if UpdateProdOrderRouting then begin
            MachineCenter.Get(MachineCenterNo3);
            LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
            AddProdOrderRoutingLine(ProductionOrder, "Capacity Type"::"Machine Center", MachineCenterNo3);
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, false, true, false);
        end;

        // Create Subcontracting Worksheet, Make order and Post Subcontracting Purchase Order.
        if Subcontract then begin
            WorkCenter.Get(WorkCenterNo2);
            SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);
            MakeSubconPurchOrder(ProductionOrder."No.", WorkCenterNo2);
            PostSubconPurchOrder(TempPurchaseLine, ProductionOrder."No.", SubcontractCostDiff);
        end;

        // Remove one component from Production Order and Replace it with a New Component.
        if UpdateProductionComponent then
            ReplaceProdOrderComponent(ProductionOrder."No.", ComponentItemNos[2], ParentItemNo, ComponentItemNos[3]);

        // Create, Calculate and Post Consumption Journal, Explode Routing and Post Output Journal.
#pragma warning disable AL0432
        if FlushingMethod = Enum::"Flushing Method"::Manual then begin
#pragma warning restore AL0432
            LibraryManufacturing.CreateProdItemJournal(
              ItemJournalBatch, ComponentItemNos[1], ItemJournalBatch."Template Type"::Consumption, ProductionOrder."No.");
            if DeleteConsumptionJrnl then
                RemoveProdOrderComponent(ProductionOrder."No.", ComponentItemNos[1]);
            if ConsumptionCostDiff then
                UpdateQtyConsumptionJournal(ProductionOrder."No.", ComponentItemNos[2]);
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
            LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ComponentItemNos[3], ItemJournalBatch."Template Type"::Output, ProductionOrder."No.");
            if OutputCostDiff then
                UpdateLessQtyOutputJournal(ProductionOrder."No.", ProductionOrder.Quantity);
            if RunSetupTimeCostDiff then begin
                SetupTime := 1;
                RunTime := 1;
                UpdateSetupRunTime(ProductionOrder."No.", SetupTime, RunTime);
            end;
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        end;

        // Change Production Order Status.
        if ProductionOrder.Status = ProductionOrder.Status::Planned then
            ProductionOrderNo :=
              LibraryManufacturing.ChangeStatusPlannedToFinished(ProductionOrder."No.") // Change Status from Planned to Finished.
        else
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        // Change Status of Production Order from Released to Finished.

        // 2. Execute Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Finished);
        if ProductionOrderNo <> '' then
            ProductionOrder.SetRange("No.", ProductionOrderNo)
        else
            ProductionOrder.SetRange("No.", ProductionOrder."No.");
        ProductionOrder.FindFirst();
        AdjustCostPostInventoryCostGL(ComponentItemNos[1] + '..' + ComponentItemNos[3]);

        // 3. Verify GL Entry : Total amount and Positive amount entries for WIP Account.
        VerifyGLEntryForWIPAccounts(
          TempPurchaseLine, ComponentItemNos[1], ProductionOrder."No.", CurrencyCode, SetupTime, RunTime, AdditionalCurrencyExist);
    end;

    [Normal]
    local procedure CreateWorkCenter(
        var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; Subcontract: Boolean;
        UnitCostCalcType: Enum "Unit Cost Calculation Type"; CurrencyCode: Code[10])
    var
        WorkCenter: Record "Work Center";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create Work Center with required fields where random is used, values not important for test.
        CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, 0);

        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Overhead Rate", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalcType);

        if Subcontract then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GenProductPostingGroup.FindFirst();
            GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GenProductPostingGroup.Modify(true);
            WorkCenter.Validate("Subcontractor No.", SubcManagementLibrary.CreateSubcontractorWithCurrency(CurrencyCode));
        end;
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure CreateWorkCenterWithFixedCost(var WorkCenter: Record "Work Center"; ShopCalendarCode: Code[10]; DirectUnitCost: Decimal)
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", DirectUnitCost);
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Modify(true);
    end;

    [Normal]
    local procedure CreateMachineCenter(var MachineCenterNo: Code[20]; WorkCenterNo: Code[20]; FlushingMethod: Enum "Flushing Method")
    var
        MachineCenter: Record "Machine Center";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Create Machine Center with required fields where random is used, values not important for test.
        GenProductPostingGroup.FindFirst();
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(10, 1));
        MachineCenter.Validate(Name, MachineCenter."No.");
        MachineCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(5, 1));
        MachineCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        MachineCenter.Validate("Overhead Rate", 1);
        MachineCenter.Validate("Flushing Method", FlushingMethod);
        MachineCenter.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        MachineCenter.Validate(Efficiency, 100);
        MachineCenter.Modify(true);
        MachineCenterNo := MachineCenter."No.";
    end;

    [Normal]
    local procedure CreateRouting(var RoutingNo: Code[20]; MachineCenterNo: Code[20]; MachineCenterNo2: Code[20]; WorkCenterNo: Code[20]; WorkCenterNo2: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo2);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenterNo);
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenterNo2);

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        RoutingNo := RoutingHeader."No.";
    end;

    [Normal]
    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        OperationNo: Code[10];
    begin
        // Create Routing Lines with required fields.
#pragma warning disable AA0210
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
#pragma warning restore AA0210
        CapacityUnitOfMeasure.FindFirst();

        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random is used, values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
    end;

    [Normal]
    local procedure CreateItem(
        ItemCostingMethod: Enum "Costing Method"; ItemReorderPolicy: Enum "Reordering Policy"; FlushingMethod: Enum "Flushing Method";
        RoutingNo: Code[20]; ProductionBOMNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        // Create Item with required fields where random values not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandInt(10), ItemReorderPolicy, FlushingMethod, RoutingNo, ProductionBOMNo);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(5, 2));
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 2));
        Item.Modify(true);

        exit(Item."No.");
    end;

    [Normal]
    local procedure CreatePurchaseOrderAddnlCurr(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20]; Qty: Decimal; UpdateProductionComponent: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeaderAddnlCurr(PurchaseHeader, CurrencyCode);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, ItemNo, Qty);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, ItemNo2, Qty);
        if UpdateProductionComponent then
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, ItemNo3, Qty);
    end;

    [Normal]
    local procedure CreatePurchaseHeaderAddnlCurr(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, SubcManagementLibrary.CreateSubcontractorWithCurrency(CurrencyCode));
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, Qty);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
    begin
        // Create new currency and validate the required GL Accounts.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.FindDirectPostingGLAccount(GLAccount);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Validate("Realized G/L Gains Account", GLAccount."No.");
        Currency.Validate("Realized G/L Losses Account", GLAccount."No.");
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

    local procedure UpdateExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        NewExchangeRateAmount: Decimal;
    begin
        SelectCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode);
        NewExchangeRateAmount := CurrencyExchangeRate."Exchange Rate Amount" * LibraryRandom.RandInt(5);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", NewExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    [Normal]
    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    [Normal]
    local procedure CalculateCalendar(MachineCenterNo: Code[20]; MachineCenterNo2: Code[20]; WorkCenterNo: Code[20]; WorkCenterNo2: Code[20])
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        MachineCenter.Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
        MachineCenter.Get(MachineCenterNo2);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
        WorkCenter.Get(WorkCenterNo2);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
    end;

    [Normal]
    local procedure UpdateAddnlReportingCurrency() CurrencyCode: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Create new Currency code and set Residual Gains Account and Residual Losses Account for Currency.
        CurrencyCode := CreateCurrency();
        Commit();

        // Update Additional Reporting Currency on G/L setup to execute Adjust Additional Reporting Currency report.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20]; Quantity: Decimal; Quantity2: Decimal; Quantity3: Decimal; UpdateProductionComponent: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo, Quantity);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo2, Quantity2);
        if UpdateProductionComponent then
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo3, Quantity3);
    end;

    [Normal]
    local procedure AddProdOrderRoutingLine(ProductionOrder: Record "Production Order"; CapacityType: Enum "Capacity Type"; MachineCenterNo: Code[20])
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
        ProdOrderRoutingLine.Validate(Type, CapacityType);
        ProdOrderRoutingLine.Validate("No.", MachineCenterNo);
        ProdOrderRoutingLine.Validate("Setup Time", LibraryRandom.RandInt(5));
        ProdOrderRoutingLine.Validate("Run Time", LibraryRandom.RandInt(2));
        ProdOrderRoutingLine.Modify(true);
    end;

    [Normal]
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
        CreateProdOrderComponent(ProdOrderLine, ProdOrderComponent, NewItemNo, 1); // value important for test.
    end;

    local procedure CreateProdOrderComponent(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20]; QuantityPer: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QuantityPer);
        ProdOrderComponent.Modify(true);
    end;

    [Normal]
    local procedure MakeSubconPurchOrder(ProductionOrderNo: Code[20]; WorkCenterNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Update Direct unit Cost and Make Order,random is used values not important for test.
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrderNo);
        RequisitionLine.SetRange("Work Center No.", WorkCenterNo);
#pragma warning restore AA0210
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    [Normal]
    local procedure PostSubconPurchOrder(var TempPurchaseLine: Record "Purchase Line" temporary; ProductionOrder: Code[20]; SubconCostDiff: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Find Subcontracting Purchase Order and Post.
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder);
        PurchaseLine.FindFirst();

        // If Expected Cost is different.
        if SubconCostDiff then begin
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(5) + 5);
            PurchaseLine.Modify(true);
        end;
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();

        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."),
            DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Normal]
    local procedure RemoveProdOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
#pragma warning disable AA0210
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
#pragma warning restore AA0210
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Delete(true);
    end;

    [Normal]
    local procedure UpdateQtyConsumptionJournal(ProductionOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
#pragma warning disable AA0210
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
#pragma warning restore AA0210
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate(Quantity, ItemJournalLine.Quantity + 1);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateLessQtyOutputJournal(ProductionOrderNo: Code[20]; ProductionOrderQuantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
#pragma warning disable AA0210
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
#pragma warning restore AA0210
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate("Output Quantity", ProductionOrderQuantity - 1);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateSetupRunTime(ProductionOrderNo: Code[20]; SetupTime: Decimal; RunTime: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
#pragma warning disable AA0210
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
#pragma warning restore AA0210
        ItemJournalLine.FindSet();

        repeat
            ItemJournalLine.Validate("Run Time", RunTime);
            ItemJournalLine.Validate("Setup Time", SetupTime);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    [Normal]
    local procedure AdjustCostPostInventoryCostGL(ItemNoFilter: Text[250])
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNoFilter, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');
    end;

    [Normal]
    local procedure SelectRoutingRefNo(ProductionOrderNo: Code[20]; ProdOrderRoutingNo: Code[20]): Integer
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderRoutingNo);
        ProdOrderRoutingLine.FindFirst();
        exit(ProdOrderRoutingLine."Routing Reference No.");
    end;

    [Normal]
    local procedure SelectGLEntry(var GLEntry: Record "G/L Entry"; InventoryPostingSetupAccount: Code[20]; ProductionOrderNo: Code[20]; PurchaseInvoiceNo: Code[20])
    begin
        // Select set of G/L Entries for the specified Account.
        if PurchaseInvoiceNo <> '' then
            GLEntry.SetFilter("Document No.", '%1|%2', ProductionOrderNo, PurchaseInvoiceNo)
        else
            GLEntry.SetFilter("Document No.", ProductionOrderNo);
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetupAccount);
        GLEntry.FindSet();
    end;

    local procedure SelectCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    [Normal]
    local procedure CalculateGLAmount(var GLEntry: Record "G/L Entry"; AdditionalCurrencyExist: Boolean): Decimal
    var
        CalculatedAmount: Decimal;
    begin
        if not AdditionalCurrencyExist then begin
            GLEntry.SetFilter(Amount, '>0');
            if GLEntry.FindSet() then
                repeat
                    CalculatedAmount += GLEntry.Amount;
                until GLEntry.Next() = 0;
            exit(CalculatedAmount);
        end;

        GLEntry.SetFilter("Additional-Currency Amount", '>0');
        if GLEntry.FindSet() then
            repeat
                CalculatedAmount += GLEntry."Additional-Currency Amount";
            until GLEntry.Next() = 0;

        exit(CalculatedAmount);
    end;

    local procedure CheckSubconWorkCenter(ProductionOrderNo: Code[20]): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // Check Flushing Method On WorkCenter.
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Finished);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        ProdOrderRoutingLine.FindSet();
        repeat
            WorkCenter.Get(ProdOrderRoutingLine."No.");
            if WorkCenter."Subcontractor No." <> '' then
                exit(true);
        until ProdOrderRoutingLine.Next() = 0;
    end;

    [Normal]
    local procedure TimeSubTotalWorkCenter(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Quantity: Decimal; SetupTime: Decimal; RunTime: Decimal): Decimal
    var
        WorkCenter: Record "Work Center";
    begin
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Machine Center" then
            exit;

        if SetupTime = 0 then
            SetupTime := ProdOrderRoutingLine."Setup Time";
        if RunTime = 0 then
            RunTime := ProdOrderRoutingLine."Run Time";

        WorkCenter.Get(ProdOrderRoutingLine."No.");
        if (WorkCenter."Subcontractor No." <> '') and (WorkCenter."Flushing Method" <> WorkCenter."Flushing Method"::Backward) then
            exit;
        if WorkCenter."Unit Cost Calculation" = WorkCenter."Unit Cost Calculation"::Time then begin
            if WorkCenter."Flushing Method" = WorkCenter."Flushing Method"::Manual then
                exit(SetupTime + RunTime);
            if (WorkCenter."Flushing Method" = WorkCenter."Flushing Method"::Backward) and (WorkCenter."Subcontractor No." <> '') then
                exit(Quantity);
            exit(SetupTime + Quantity * RunTime);
        end;

        exit(Quantity);
    end;

    [Normal]
    local procedure TimeSubTotalMachineCenter(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Quantity: Decimal; SetupTime: Decimal; RunTime: Decimal): Decimal
    var
        MachineCenter: Record "Machine Center";
    begin
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center" then
            exit;

        if SetupTime = 0 then
            SetupTime := ProdOrderRoutingLine."Setup Time";
        if RunTime = 0 then
            RunTime := ProdOrderRoutingLine."Run Time";

        MachineCenter.Get(ProdOrderRoutingLine."No.");
        if MachineCenter."Flushing Method" = MachineCenter."Flushing Method"::Manual then
            exit(SetupTime + RunTime);
        exit(SetupTime + Quantity * RunTime);
    end;

    local procedure CalculateDirectSubcontractingCost(TempPurchaseLine: Record "Purchase Line" temporary; CurrencyCode: Code[10]): Decimal
    begin
        exit(Round(TempPurchaseLine.Quantity * TempPurchaseLine."Direct Unit Cost", LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode)));
    end;

    local procedure CalculateIndirectSubcontractingCost(TempPurchaseLine: Record "Purchase Line" temporary; CurrencyCode: Code[10]): Decimal
    var
        OverheadRate: Decimal;
    begin
        // Overhead in purchase line is copied from the item card and is always an LCY amount
        OverheadRate := ExchangeAmtLCYToFCY(TempPurchaseLine."Overhead Rate", CurrencyCode);
        exit(
            Round(
                TempPurchaseLine.Quantity * ((TempPurchaseLine."Indirect Cost %" / 100) * TempPurchaseLine."Direct Unit Cost" + OverheadRate),
                LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode)));
    end;

    [Normal]
    local procedure DirectIndirectMachineCntrCost(RoutingNo: Code[20]; Quantity: Decimal; SetupTime: Decimal; RunTime: Decimal; CurrencyCode: Code[10]): Decimal
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
                TimeSubtotal := TimeSubTotalMachineCenter(ProdOrderRoutingLine, Quantity, SetupTime, RunTime);
                MachineCenterAmount += ExchangeAmtLCYToFCYWithRounding(TimeSubtotal * MachineCenter."Direct Unit Cost", CurrencyCode);
                MachineCenterAmount +=
                    ExchangeAmtLCYToFCYWithRounding(
                        TimeSubtotal * ((MachineCenter."Indirect Cost %" / 100) * MachineCenter."Direct Unit Cost" + MachineCenter."Overhead Rate"),
                        CurrencyCode);
            until ProdOrderRoutingLine.Next() = 0;
        exit(MachineCenterAmount);
    end;

    [Normal]
    local procedure DirectIndirectWorkCntrCost(RoutingNo: Code[20]; Quantity: Decimal; SetupTime: Decimal; RunTime: Decimal; CurrencyCode: Code[10]): Decimal
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
                TimeSubtotal := TimeSubTotalWorkCenter(ProdOrderRoutingLine, Quantity, SetupTime, RunTime);
                WorkCenterAmount += ExchangeAmtLCYToFCYWithRounding(TimeSubtotal * WorkCenter."Direct Unit Cost", CurrencyCode);
                WorkCenterAmount +=
                    ExchangeAmtLCYToFCYWithRounding(
                        TimeSubtotal * ((WorkCenter."Indirect Cost %" / 100) * WorkCenter."Direct Unit Cost" + WorkCenter."Overhead Rate"), CurrencyCode);
            until ProdOrderRoutingLine.Next() = 0;
        exit(WorkCenterAmount);
    end;

    [Normal]
    local procedure VerifyGLEntryForWIPAccounts(TempPurchaseLine: Record "Purchase Line" temporary; ItemNo: Code[20]; ProductionOrderNo: Code[20]; CurrencyCode: Code[10]; SetupTime: Decimal; RunTime: Decimal; AdditionalCurrencyExist: Boolean)
    var
        Item: Record Item;
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        Item.Get(ItemNo);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();

        // Verify positive WIP Account amount is equal to calculated amount.
        PurchInvHeader.SetRange("Order No.", TempPurchaseLine."Document No.");
        PurchInvHeader.FindFirst();
        SelectGLEntry(GLEntry, InventoryPostingSetup."WIP Account", ProductionOrderNo, PurchInvHeader."No.");

        // True if Flushing is backward in a subcontract Work center.
        VerifyWIPAmounts(
          GLEntry, TempPurchaseLine, ProductionOrderNo, CurrencyCode, SetupTime, RunTime, CheckSubconWorkCenter(ProductionOrderNo),
          AdditionalCurrencyExist);
    end;

    [Normal]
    local procedure VerifyWIPAmounts(var GLEntry: Record "G/L Entry"; TempPurchaseLine: Record "Purchase Line" temporary; ProductionOrderNo: Code[20]; CurrencyCode: Code[10]; SetupTime: Decimal; RunTime: Decimal; CheckSubcontractWorkCenter: Boolean; AdditionalCurrencyExist: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalculatedWIPAmount: Decimal;
        TotalConsumptionValue: Decimal;
        TotalAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        TotalAmount := CalculateGLAmount(GLEntry, AdditionalCurrencyExist);

        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrderNo);

        TotalConsumptionValue := CalcTotalComponentConsumptionValue(ProductionOrderNo, CurrencyCode);

        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Finished, ProductionOrderNo);

        CalculatedWIPAmount :=
            TotalConsumptionValue +
            DirectIndirectMachineCntrCost(ProductionOrder."Routing No.", ProdOrderLine."Finished Quantity", SetupTime, RunTime, CurrencyCode) +
            DirectIndirectWorkCntrCost(ProductionOrder."Routing No.", ProdOrderLine."Finished Quantity", SetupTime, RunTime, CurrencyCode);

        if CheckSubcontractWorkCenter then
            CalculatedWIPAmount += CalculateDirectSubcontractingCost(TempPurchaseLine, CurrencyCode) + CalculateIndirectSubcontractingCost(TempPurchaseLine, CurrencyCode);

        // Verify WIP Account amounts and calculated WIP amounts are equal.
        Assert.AreNearlyEqual(TotalAmount, CalculatedWIPAmount, 2 * GeneralLedgerSetup."Amount Rounding Precision", AmountDoNotMatchErr);
    end;

    local procedure CalcTotalComponentConsumptionValue(ProdOrderNo: Code[20]; CurrencyCode: Code[10]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemCost: Decimal;
        TotalCost: Decimal;
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgerEntry.SetLoadFields("Item No.", Quantity);
        if ItemLedgerEntry.FindSet() then
            repeat
                Item.SetLoadFields("Costing Method", "Standard Cost", "Unit Cost");
                Item.Get(ItemLedgerEntry."Item No.");
                if Item."Costing Method" = Item."Costing Method"::Standard then
                    ItemCost := Item."Standard Cost"
                else
                    ItemCost := Item."Unit Cost";

                TotalCost += ExchangeAmtLCYToFCYWithRounding(-ItemLedgerEntry.Quantity * ItemCost, CurrencyCode);
            until ItemLedgerEntry.Next() = 0;

        exit(TotalCost);
    end;

    local procedure ExchangeAmtLCYToFCY(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    var
        CurrencyExchRate: Record "Currency Exchange Rate";
    begin
        exit(CurrencyExchRate.ExchangeAmtLCYToFCY(WorkDate(), CurrencyCode, Amount, CurrencyExchRate.ExchangeRate(WorkDate(), CurrencyCode)));
    end;

    local procedure ExchangeAmtLCYToFCYWithRounding(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        RoundedLCYAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        RoundedLCYAmount := Round(Amount, GeneralLedgerSetup."Amount Rounding Precision");
        exit(Round(ExchangeAmtLCYToFCY(RoundedLCYAmount, CurrencyCode), LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode)));
    end;

    [Normal]
    local procedure RaiseConfirmHandler()
    begin
        if Confirm('') then;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalcStdCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Calculate Standard Cost for All Level.
        Choice := 2;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmText: Text[1024]; var Confirm: Boolean)
    begin
        Confirm := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}