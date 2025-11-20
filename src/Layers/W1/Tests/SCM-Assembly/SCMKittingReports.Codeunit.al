// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Sales.Setup;
using Microsoft.Inventory.Setup;
using Microsoft.Assembly.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.Document;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Reconciliation;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Costing;
using Microsoft.Assembly.History;
using Microsoft.Foundation.Enums;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Reports;
using Microsoft.Manufacturing.Reports;

codeunit 137390 "SCM Kitting -  Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Reports] [SCM]
        isInitialized := false;
    end;

    var
        InventorySetup: Record "Inventory Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        AssemblySetup: Record "Assembly Setup";
        SourceCodeSetup: Record "Source Code Setup";
        Item: Record Item;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        isInitialized: Boolean;
        WorkDate2: Date;
        AdjSource: Option Purchase,Revaluation,"Item Card","Order Lines",Resource,"None";
        TopItemRepl: Option "None","Prod. Order",Assembly;
        PrintCostShare: Option Sales,Inventory,"WIP Inventory";
        ErrorCostShares: Label 'Wrong %1 in item %2.';
        PostMethod: Option "per Posting Group","per Entry";
        WarningCaption: Label 'Warning!';
        BlockType: Option Dimension,"Dimension Value","Dimension Combination","None";
        GlobalInventoryAdjmt: Decimal;
        GlobalCapacityVariance: Decimal;
        GlobalCOGS: Decimal;
        ErrorGLRecon: Label 'Wrong %1 entry %2 in page 9297.';
        GlobalMaterialVariance: Decimal;
        DemandLabel: Label 'Demand';
        AssemblyLabel: Label 'Assembly';
        AssemblyDemandLabel: Label 'Assembly Demand';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting -  Reports");
        // Initialize setup.
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        ClearLastError();
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card",
          LibraryUtility.GetGlobalNoSeriesCode());
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, true, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Day);

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting -  Reports");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateInventoryPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        SalesReceivablesSetup.Get();
        SourceCodeSetup.Get();
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate();

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting -  Reports");
    end;

    [Normal]
    local procedure NormalPosting(var AssemblyHeader: Record "Assembly Header"; CostingMethod: Enum "Costing Method"; PartialPostFactor: Decimal; IndirectCost: Decimal; AdjustmentSource: Option; AssemblyPolicy: Enum "Assembly Policy"; MixedReplenishment: Option)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        ItemNo: array[10] of Code[20];
        ResourceNo: array[10] of Code[20];
        ItemFilter: Text[250];
    begin
        // Setup.
        Initialize();
        LibraryAssembly.SetupAssemblyData(
          AssemblyHeader, WorkDate2, CostingMethod, CostingMethod, Item."Replenishment System"::Assembly, '', true);
        ATOSetup(AssemblyHeader, SalesHeader, AssemblyPolicy, PartialPostFactor);
        MixedReplenishmentSetup(ProductionOrder, AssemblyHeader, MixedReplenishment);

        ItemFilter := LibraryAssembly.GetCompsToAdjust(ItemNo, ResourceNo, AssemblyHeader);
        LibraryAssembly.ModifyCostParams(AssemblyHeader."No.", false, IndirectCost, 0);
        LibraryAssembly.ModifyItem(AssemblyHeader."Item No.", false, IndirectCost * LibraryRandom.RandDec(10, 2), 0);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 1);
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, PartialPostFactor, PartialPostFactor, true, WorkDate2);

        // Exercise.
        if AssemblyPolicy = Item."Assembly Policy"::"Assemble-to-Stock" then begin
            LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

            // If assembly item lies below a produced item, post the production order.
            if MixedReplenishment = TopItemRepl::"Prod. Order" then begin
                ItemJournalLine.DeleteAll();
                CreatePostItemJournal(
                  AssemblyHeader."Item No.", ProductionOrder."No.", ItemJournalBatch."Template Type"::Consumption,
                  AssemblyHeader."Quantity to Assemble", AssemblyHeader."Posting Date");
                CreatePostItemJournal(
                  ProductionOrder."Source No.", ProductionOrder."No.", ItemJournalBatch."Template Type"::Output, ProductionOrder.Quantity,
                  AssemblyHeader."Posting Date");
            end;
        end else
            LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCosting.AdjustCostItemEntries(ItemFilter, '');
        if AdjustmentSource <> AdjSource::None then begin
            // Revalue the assembly item.
            LibraryAssembly.CreateAdjustmentSource(AssemblyHeader, WorkDate2, true, AdjustmentSource, '', '');

            // Revalue an item component.
            LibraryAssembly.CreateAdjustmentSource(AssemblyHeader, WorkDate2, false, AdjustmentSource, ItemNo[1], '');
            LibraryCosting.AdjustCostItemEntries(ItemFilter, '');
        end;

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValueFullPostingSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValueFullPostingAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValuePartialPostingSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 59, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValuePartialPostingAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 59, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValueRevalSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValueRevalAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValueFullPostingATOSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Order",
          TopItemRepl::None);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Sales);
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValueIndCostAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 12, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValueIndCostSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 15, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValueTopItemProduced()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::"Prod. Order");
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('ItemRegValueReqPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegValueTopItemAssembly()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::Assembly);
        VerifyItemRegValueForOrder(AssemblyHeader, SourceCodeSetup.Assembly);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecFullPostingSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecFullPostingAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecPartialPostingSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 59, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecPartialPostingAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 59, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecRevalSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecRevalAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecFullPostingATOSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Order",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecFullPostingATOAvg()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Order",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecIndCostAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 12, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecIndCostSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 15, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecTopItemProduced()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::"Prod. Order");
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValCostSpecTopItemAssembly()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::Assembly);
        VerifyInvtValCostSpecForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationFullPostingSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationFullPostingAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationPartialPostingSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 59, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationPartialPostingAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 59, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationRevalSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationRevalAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationFullPostingATOSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Order",
          TopItemRepl::None);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationIndCostAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 12, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationIndCostSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 15, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationTopItemProduced()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::"Prod. Order");
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationTopItemAssembly()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::Assembly);
        VerifyInvtValuationForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesRevalSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyCostSharesBreakdown(AssemblyHeader, PrintCostShare::Inventory);
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesRevalAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        asserterror VerifyCostSharesBreakdown(AssemblyHeader, PrintCostShare::Inventory);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesATOSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Order",
          TopItemRepl::None);
        asserterror VerifyCostSharesBreakdown(AssemblyHeader, PrintCostShare::Inventory);
        VerifyCostSharesBreakdown(AssemblyHeader, PrintCostShare::Sales);
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesIndCostSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 15, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyCostSharesBreakdown(AssemblyHeader, PrintCostShare::Inventory);
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesTopItemAssembly()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::Assembly);
        VerifyCostSharesBreakdown(AssemblyHeader, PrintCostShare::Inventory);
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestFullPostingSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(AssemblyHeader, PostMethod::"per Entry", '', '');
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestPartialAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 75, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(AssemblyHeader, PostMethod::"per Entry", '', '');
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestRevalAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(AssemblyHeader, PostMethod::"per Entry", '', '');
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestIndCostAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 10, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(AssemblyHeader, PostMethod::"per Entry", '', '');
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestRevalSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(AssemblyHeader, PostMethod::"per Entry", '', '');
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestIndCostSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 10, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(AssemblyHeader, PostMethod::"per Entry", '', '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestATOAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Order",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(AssemblyHeader, PostMethod::"per Entry", '', '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestATOSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Order",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(AssemblyHeader, PostMethod::"per Entry", '', '');
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestFullPostDimBlockCompSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(
          AssemblyHeader, PostMethod::"per Entry",
          LibraryAssembly.BlockOrderDimensions(AssemblyHeader, BlockType::None, BlockType::Dimension), '');
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestFullPostDimValBlockCompAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(
          AssemblyHeader, PostMethod::"per Entry",
          LibraryAssembly.BlockOrderDimensions(AssemblyHeader, BlockType::None, BlockType::"Dimension Value"), '');
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestFullPostDimBlockHeaderAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(
          AssemblyHeader, PostMethod::"per Entry", '',
          LibraryAssembly.BlockOrderDimensions(AssemblyHeader, BlockType::Dimension, BlockType::None));
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtToGLTestFullPostDimValBlockHeaderSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyPostCostToGLTestForOrder(
          AssemblyHeader, PostMethod::"per Entry", '',
          LibraryAssembly.BlockOrderDimensions(AssemblyHeader, BlockType::"Dimension Value", BlockType::None));
    end;

    [Test]
    [HandlerFunctions('InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecFullPostingAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecPartialSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 25, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecRevalAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecRevalSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::Revaluation, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecIndCostAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 10, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecIndCostSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 10, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecATOAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Order",
          TopItemRepl::None);
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecATOSTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Order",
          TopItemRepl::None);
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecTopItemProducedAVG()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Average, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::"Prod. Order");
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('InvtGLReconciliationHandler')]
    [Scope('OnPrem')]
    procedure InvtGLRecTopItemAssemblySTD()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 100, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::Assembly);
        VerifyInvtGLReconForOrder(AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandOverviewSunshine()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 10, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::None);
        VerifyDemandOverview(AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandOverviewTopItemProduced()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 10, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::"Prod. Order");
        VerifyDemandOverview(AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandOverviewTopItemAssembly()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        NormalPosting(
          AssemblyHeader, Item."Costing Method"::Standard, 10, 0, AdjSource::None, Item."Assembly Policy"::"Assemble-to-Stock",
          TopItemRepl::Assembly);
        VerifyDemandOverview(AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryGLReconciliationCostIsPostedToGLWarning()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        Item: Record Item;
    begin
        // [FEATURE] [Inventory - G/L Reconciliation]
        // [SCENARIO] "Cost is Posted to G/L Warning" set in "Inventory - G/L Reconciliation" report when item value entry is not posted to G/L

        // [GIVEN] Post inventory entry without posting value to general ledger
        UpdateAutomaticCostPosting(false);
        CreateItem(Item);
        PostInventoryPositiveAdjustment(Item."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Run "Inventory - G/L Reconciliation"
        RunGetInventoryReport(TempInventoryReportEntry, Item."No.", Format(WorkDate()));

        // [THEN] "Cost is Posted to G/L Warning" is TRUE
        FindInventoryReportDifferenceEntry(TempInventoryReportEntry);
        TempInventoryReportEntry.TestField("Cost is Posted to G/L Warning", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryGLReconciliationClosingPeriodOverlapWarning()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        Item: Record Item;
        InventoryPostingSetup: Record "Inventory Posting Setup";
        AccPeriodStartDate: Date;
        AccPeriodEndDate: Date;
    begin
        // [FEATURE] [Inventory - G/L Reconciliation]
        // [SCENARIO] "Closing Period Overlap Warning" set in "Inventory - G/L Reconciliation" report when reporting period includes several fiscal years with value entries

        UpdateAutomaticCostPosting(true);
        CreateItem(Item);

        // [GIVEN] Post g/l entry on the fiscal year's closing date
        // [GIVEN] Post inventory entry on WORKDATE
        LibraryFiscalYear.FindAccountingPeriodStartEndDate(AccPeriodStartDate, AccPeriodEndDate, 12);
        InventoryPostingSetup.Get('', Item."Inventory Posting Group");
        MockGLEntryOnDate(InventoryPostingSetup."Material Variance Account", ClosingDate(AccPeriodEndDate));
        PostInventoryPositiveAdjustment(Item."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Run "Inventory - G/L Reconciliation"
        RunGetInventoryReport(TempInventoryReportEntry, Item."No.", '');

        // [THEN] "Closing Period Overlap Warning" is TRUE
        FindInventoryReportDifferenceEntry(TempInventoryReportEntry);
        TempInventoryReportEntry.TestField("Closing Period Overlap Warning", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryGLReconciliationDeletedGLAccountsWarning()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        Item: Record Item;
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation]
        // [SCENARIO] "Deleted G/L Accounts Warning" set in "Inventory - G/L Reconciliation" report when there are G/L entries on deleted g/l accounts

        UpdateAutomaticCostPosting(true);
        CreateItem(Item);

        // [GIVEN] Post inventory entry on WORKDATE
        // [GIVEN] Post g/l entry and delete the g/l account (so that g/l account no. in the g/l entry is empty)
        PostInventoryPositiveAdjustment(Item."No.", LibraryRandom.RandDec(100, 2));
        MockGLEntryOnInventoryAccount(Item."Inventory Posting Group");
        MockGLEntry('');

        // [WHEN] Run "Inventory - G/L Reconciliation"
        RunGetInventoryReport(TempInventoryReportEntry, Item."No.", Format(WorkDate()));

        // [THEN] "Deleted G/L Accounts Warning" is TRUE
        FindInventoryReportDifferenceEntry(TempInventoryReportEntry);
        TempInventoryReportEntry.TestField("Deleted G/L Accounts Warning", true);

        GLEntry.SetRange("G/L Account No.", '');
        GLEntry.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryGLReconciliationDirectPostingsWarning()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        Item: Record Item;
    begin
        // [FEATURE] [Inventory - G/L Reconciliation]
        // [SCENARIO] "Direct Postings Warning" set in "Inventory - G/L Reconciliation" report when amount is posted directly on Inventory Account

        UpdateAutomaticCostPosting(true);
        CreateItem(Item);

        // [GIVEN] Post inventory entry and post cost to general ledger
        // [GIVEN] Post G/L entry on inventory account. Cost is completely posted to general ledger, but value entries do not balance with g/l.
        PostInventoryPositiveAdjustment(Item."No.", LibraryRandom.RandDec(100, 2));
        MockGLEntryOnInventoryAccount(Item."Inventory Posting Group");

        // [WHEN] Run "Inventory - G/L Reconciliation"
        RunGetInventoryReport(TempInventoryReportEntry, Item."No.", Format(WorkDate()));

        // [THEN] "Direct Postings Warning" is TRUE
        FindInventoryReportDifferenceEntry(TempInventoryReportEntry);
        TempInventoryReportEntry.TestField("Direct Postings Warning", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownDirectCostApplActualGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownDirectCostApplActual(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownDirectCostApplActualDirectCostPurchase()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Direct Cost");

        LibraryVariableStorage.Enqueue(1);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownDirectCostApplActual(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownDirectCostApplActualDirectCostAssembly()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::"Direct Cost",
          ValueEntry."Order Type"::Assembly);

        LibraryVariableStorage.Enqueue(2);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownDirectCostApplActual(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOverheadAppliedActualGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownOverheadAppliedActual(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownOverheadAppliedActualIndirectCostPurchase()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Indirect Cost");

        LibraryVariableStorage.Enqueue(1);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownOverheadAppliedActual(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownOverheadAppliedActualIndirectCostAssembly()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::"Indirect Cost",
          ValueEntry."Order Type"::Assembly);

        LibraryVariableStorage.Enqueue(2);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownOverheadAppliedActual(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownPurchaseVarianceGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownPurchaseVariance(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownPurchaseVariancePurchase()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::Variance);

        ValueEntries.Trap();
        GetInventoryReport.DrillDownPurchaseVariance(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAdjmtGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownInventoryAdjmt(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAdjmtDirectCostPositiveAdjmt()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", ValueEntry."Entry Type"::"Direct Cost");

        LibraryVariableStorage.Enqueue(1);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownInventoryAdjmt(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAdjmtDirectCostAssembly()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::"Direct Cost",
          ValueEntry."Order Type"::Assembly);

        LibraryVariableStorage.Enqueue(2);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownInventoryAdjmt(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAdjmtRevaluation()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::Revaluation);

        LibraryVariableStorage.Enqueue(3);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownInventoryAdjmt(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownInventoryAdjmtRounding()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::Rounding);

        LibraryVariableStorage.Enqueue(4);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownInventoryAdjmt(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInvtAccrualInterimGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownInvtAccrualInterim(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInvtAccrualInterimDirectCostPurchase()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Direct Cost");

        ValueEntries.Trap();
        GetInventoryReport.DrillDownInvtAccrualInterim(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownCOGSGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownCOGS(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownCOGSDirectCostSale()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost");

        ValueEntries.Trap();
        GetInventoryReport.DrillDownCOGS(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownCOGSInterimGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownCOGSInterim(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownCOGSInterimDirectCostSale()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost");

        ValueEntries.Trap();
        GetInventoryReport.DrillDownCOGSInterim(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownWIPInventoryGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownWIPInventory(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownWIPInventoryDirectCostProdConsumption()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Consumption, ValueEntry."Entry Type"::"Direct Cost",
          ValueEntry."Order Type"::Production);

        LibraryVariableStorage.Enqueue(1);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownWIPInventory(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownWIPInventoryIndirectCostProduction()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::"Indirect Cost",
          ValueEntry."Order Type"::Production);

        LibraryVariableStorage.Enqueue(2);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownWIPInventory(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DrillDownWIPInventoryProdOutputRevaluation()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Revaluation,
          ValueEntry."Order Type"::Production);

        LibraryVariableStorage.Enqueue(3);
        ValueEntries.Trap();
        GetInventoryReport.DrillDownWIPInventory(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownMaterialVarianceGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownMaterialVariance(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownMaterialVarianceProdOutputMaterialVariance()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithVarianceType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance,
          ValueEntry."Variance Type"::Material);

        ValueEntries.Trap();
        GetInventoryReport.DrillDownMaterialVariance(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownCapVarianceGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownCapVariance(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownCapVarianceProdOutputCapacityVariance()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithVarianceType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance,
          ValueEntry."Variance Type"::Capacity);

        ValueEntries.Trap();
        GetInventoryReport.DrillDownCapVariance(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownSubcontractedVarianceGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownSubcontractedVariance(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownSubcontractedVarianceProdOutputSubcontractVariance()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithVarianceType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance,
          ValueEntry."Variance Type"::Subcontracted);

        ValueEntries.Trap();
        GetInventoryReport.DrillDownSubcontractedVariance(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownCapOverheadVarianceGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownCapOverheadVariance(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownCapOverheadVarianceProdOutputCapOverheadVariance()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithVarianceType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance,
          ValueEntry."Variance Type"::"Capacity Overhead");

        ValueEntries.Trap();
        GetInventoryReport.DrillDownCapOverheadVariance(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownMfgOverheadVarianceGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownMfgOverheadVariance(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownMfgOverheadVarianceProdOutput()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithVarianceType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance,
          ValueEntry."Variance Type"::"Manufacturing Overhead");

        ValueEntries.Trap();
        GetInventoryReport.DrillDownMfgOverheadVariance(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryInterimGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownInventoryInterim(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryInterimProdOutputRevaluation()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Revaluation);

        ValueEntries.Trap();
        GetInventoryReport.DrillDownInventoryInterim(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOverheadAppliedToWIPGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownOverheadAppliedToWIP(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOverheadAppliedToWIPProductionIndirectCost()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::"Indirect Cost",
          ValueEntry."Order Type"::Production);

        ValueEntries.Trap();
        GetInventoryReport.DrillDownOverheadAppliedToWIP(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownDirectCostApplToWIPGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownDirectCostApplToWIP(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownDirectCostApplToWIPProductionDirectCost()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::"Direct Cost",
          ValueEntry."Order Type"::Production);

        ValueEntries.Trap();
        GetInventoryReport.DrillDownDirectCostApplToWIP(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownWIPToInvtInterimGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownWIPToInvtInterim(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownWIPToInvtInterimProdOutputDirectCost()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::"Direct Cost",
          ValueEntry."Order Type"::Production);

        ValueEntries.Trap();
        GetInventoryReport.DrillDownWIPToInvtInterim(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInvtToWIPGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownInvtToWIP(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInvtToWIPProdOutputDirectCost()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntryWithOrderType(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::"Direct Cost",
          ValueEntry."Order Type"::Production);

        ValueEntries.Trap();
        GetInventoryReport.DrillDownInvtToWIP(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownInventory(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownInventoryDirectCostPurchase()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Direct Cost");

        ValueEntries.Trap();
        GetInventoryReport.DrillDownInventory(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownDirectCostAppliedGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownDirectCostApplied(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownDirectCostAppliedDirectCostPurchase()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Direct Cost");

        ValueEntries.Trap();
        GetInventoryReport.DrillDownDirectCostApplied(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOverheadAppliedGLAccount()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        GLEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::"G/L Account");
        MockGLEntry(TempInventoryReportEntry."No.");

        GLEntries.Trap();
        GetInventoryReport.DrillDownOverheadApplied(TempInventoryReportEntry);
        GLEntries."G/L Account No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOverheadAppliedIndirectCostPurchase()
    var
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        ValueEntry: Record "Value Entry";
        GetInventoryReport: Codeunit "Get Inventory Report";
        ValueEntries: TestPage "Value Entries";
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [UT]

        MockInventoryReportEntry(TempInventoryReportEntry, TempInventoryReportEntry.Type::Item);
        MockValueEntry(
          TempInventoryReportEntry."No.", ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Indirect Cost");

        ValueEntries.Trap();
        GetInventoryReport.DrillDownOverheadApplied(TempInventoryReportEntry);
        ValueEntries."Item No.".AssertEquals(TempInventoryReportEntry."No.");
    end;

    [Normal]
    local procedure ATOSetup(var AssemblyHeader: Record "Assembly Header"; var SalesHeader: Record "Sales Header"; AssemblyPolicy: Enum "Assembly Policy"; PartialShipFactor: Decimal)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        if AssemblyPolicy = Item."Assembly Policy"::"Assemble-to-Stock" then
            exit;
        if Confirm('') then; // workaround for GB = confirmation needed when posting date <> WORKDATE.

        // ATO Setup.
        Item.Get(AssemblyHeader."Item No.");
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipment Date", WorkDate2);
        SalesHeader.Validate("Posting Date", WorkDate2);
        SalesHeader.Validate("Posting No. Series", SalesReceivablesSetup."Posted Invoice Nos.");
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity * PartialShipFactor / 100);
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine."Qty. to Ship");
        SalesLine.Modify(true);

        LibraryAssembly.FindLinkedAssemblyOrder(AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(1000, 2));
        Item.Modify(true);
    end;

    [Normal]
    local procedure MixedReplenishmentSetup(var ProductionOrder: Record "Production Order"; AssemblyHeader: Record "Assembly Header"; TopItemReplenishment: Option)
    var
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
    begin
        if TopItemReplenishment = TopItemRepl::None then
            exit;

        // Setup a produced item.
        LibraryAssembly.CreateItem(
          Item, Item."Costing Method", Item."Replenishment System"::"Prod. Order", Item."Gen. Prod. Posting Group",
          Item."Inventory Posting Group");
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");

        // Add the produced item as a component in the Assembly Order or viceversa.
        if TopItemReplenishment = TopItemRepl::Assembly then
            LibraryAssembly.CreateAssemblyLine(
              AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", LibraryRandom.RandInt(10), 1, '')
        else
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, AssemblyHeader."Item No.",
              LibraryRandom.RandInt(10));

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        RoutingHeader.SetRange(Status, RoutingHeader.Status::Certified);
        if RoutingHeader.FindFirst() then
            Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    [Normal]
    local procedure GetItemRegister(var ItemRegister: Record "Item Register"; AssemblyHeader: Record "Assembly Header"; SourceCode: Code[10])
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        CapEntryMin: Integer;
        CapEntryMax: Integer;
    begin
        CapacityLedgerEntry.Reset();
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Assembly);
        CapacityLedgerEntry.SetRange("Order No.", AssemblyHeader."No.");
        CapacityLedgerEntry.SetRange("Posting Date", AssemblyHeader."Posting Date");
        if CapacityLedgerEntry.FindFirst() then
            CapEntryMin := CapacityLedgerEntry."Entry No.";
        if CapacityLedgerEntry.FindLast() then
            CapEntryMax := CapacityLedgerEntry."Entry No.";

        ItemRegister.Reset();
        ItemRegister.SetRange("From Capacity Entry No.", CapEntryMin);
        ItemRegister.SetRange("To Capacity Entry No.", CapEntryMax);
        ItemRegister.SetRange("Source Code", SourceCode);
        ItemRegister.FindLast();
    end;

    [Normal]
    local procedure GetOrderValueEntries(var ValueEntry: Record "Value Entry"; AssemblyHeader: Record "Assembly Header")
    begin
        ValueEntry.Reset();
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Assembly);
        ValueEntry.SetRange("Order No.", AssemblyHeader."No.");
        ValueEntry.SetRange("Source Code", SourceCodeSetup.Assembly);
    end;

    [Normal]
    local procedure GetValueEntriesAmount(ItemNo: Code[20]; FromEntryType: Enum "Cost Entry Type"; ToEntryType: Enum "Cost Entry Type"; FromILEType: Enum "Item Ledger Document Type"; ToILEType: Enum "Item Ledger Document Type"; VarianceType: Enum "Cost Variance Type"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        Clear(ValueEntry);
        ValueEntry.SetCurrentKey(
          "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type", "Item Charge No.", "Location Code",
          "Variant Code");
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", FromEntryType, ToEntryType);
        ValueEntry.SetRange("Item Ledger Entry Type", FromILEType, ToILEType);
        ValueEntry.SetRange("Variance Type", VarianceType);
        ValueEntry.CalcSums(ValueEntry."Cost Amount (Actual)");
        exit(ValueEntry."Cost Amount (Actual)");
    end;

    [Normal]
    local procedure VerifyItemRegValueForOrder(AssemblyHeader: Record "Assembly Header"; SourceCode: Code[10])
    var
        ItemRegister: Record "Item Register";
        ValueEntry: Record "Value Entry";
    begin
        GetItemRegister(ItemRegister, AssemblyHeader, SourceCode);
        GetOrderValueEntries(ValueEntry, AssemblyHeader);

        Commit();
        REPORT.Run(REPORT::"Item Register - Value", true, false, ItemRegister);
        VerifyItemRegisterValue(ValueEntry);
    end;

    [Normal]
    local procedure VerifyInvtValCostSpecForOrder(AssemblyHeader: Record "Assembly Header")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        // Verify report for item component entries.
        PostedAssemblyHeader.Reset();
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.SetRange("Item No.", AssemblyHeader."Item No.");

        if PostedAssemblyHeader.FindFirst() then begin
            PostedAssemblyLine.Reset();
            PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
            PostedAssemblyLine.SetRange(Type, PostedAssemblyLine.Type::Item);
            if PostedAssemblyLine.FindSet() then
                repeat
                    VerifyInvtValuationCostSpec(PostedAssemblyLine."No.", PostedAssemblyHeader."Posting Date");
                until PostedAssemblyLine.Next() = 0;
        end;

        // Verify report for assembly item.
        VerifyInvtValuationCostSpec(PostedAssemblyHeader."Item No.", PostedAssemblyHeader."Posting Date");
    end;

    [Normal]
    local procedure VerifyInvtValuationForOrder(AssemblyHeader: Record "Assembly Header")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        // Verify report for item component entries.
        PostedAssemblyHeader.Reset();
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.SetRange("Item No.", AssemblyHeader."Item No.");
        if PostedAssemblyHeader.FindFirst() then begin
            PostedAssemblyLine.Reset();
            PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
            PostedAssemblyLine.SetRange(Type, PostedAssemblyLine.Type::Item);
            if PostedAssemblyLine.FindSet() then
                repeat
                    VerifyInventoryValuation(PostedAssemblyLine."No.", PostedAssemblyHeader."Posting Date", PostedAssemblyHeader."Posting Date");
                until PostedAssemblyLine.Next() = 0;
        end;

        // Verify reports for assembly item.
        VerifyInventoryValuation(PostedAssemblyHeader."Item No.", PostedAssemblyHeader."Due Date", PostedAssemblyHeader."Posting Date");
    end;

    [Normal]
    local procedure VerifyItemRegisterValue(var ValueEntry: Record "Value Entry")
    begin
        LibraryReportDataset.LoadDataSetFile();

        if ValueEntry.FindSet() then
            repeat
                LibraryReportDataset.SetRange('EntryNo_ValueEntry', ValueEntry."Entry No.");

                // Verify: Invoice quantity.
                LibraryReportDataset.AssertElementWithValueExists('InvoicedQuantity_ValueEntry', ValueEntry."Invoiced Quantity");

                // Unit cost.
                LibraryReportDataset.AssertElementWithValueExists('CostperUnit_ValueEntry', ValueEntry."Cost per Unit");

                // Cost amount - actual.
                LibraryReportDataset.AssertElementWithValueExists('CostAmountActual1_ValueEntry', ValueEntry."Cost Amount (Actual)");

                // Cost amount - expected.
                LibraryReportDataset.AssertElementWithValueExists('CostAmountExpected1_ValueEntry', ValueEntry."Cost Amount (Expected)");

            until ValueEntry.Next() = 0;
    end;

    [Normal]
    local procedure VerifyInvtValuationCostSpec(ItemNo: Code[20]; ReportDate: Date)
    var
        ValueEntry: Record "Value Entry";
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        Item.FindFirst();
        Item.CalcFields(Inventory);
        Commit();
        LibraryVariableStorage.Enqueue(ReportDate);
        REPORT.Run(REPORT::"Invt. Valuation - Cost Spec.", true, false, Item);

        // Check the report aggregation for the main types of value entries.
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Source Type", "Source No.", "Item No.", "Posting Date", "Entry Type", Adjustment);
        ValueEntry.SetRange("Posting Date", 0D, ReportDate);
        ValueEntry.SetRange("Item No.", Item."No.");

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        CheckInvtValCostSpecFields(ValueEntry, Item, ValueEntry."Entry Type"::"Direct Cost");
        CheckInvtValCostSpecFields(ValueEntry, Item, ValueEntry."Entry Type"::"Indirect Cost");
        CheckInvtValCostSpecFields(ValueEntry, Item, ValueEntry."Entry Type"::Variance);
        CheckInvtValCostSpecFields(ValueEntry, Item, ValueEntry."Entry Type"::Revaluation);
        CheckInvtValCostSpecFields(ValueEntry, Item, ValueEntry."Entry Type"::Rounding);
    end;

    [Normal]
    local procedure CheckInvtValCostSpecFields(var ValueEntry: Record "Value Entry"; Item: Record Item; EntryType: Enum "Cost Entry Type")
    var
        CostAmount: Decimal;
        UnitCost: Decimal;
    begin
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        if (ValueEntry."Cost Amount (Actual)" = 0) or (Item.Inventory = 0) then
            exit;

        // Unit cost.
        UnitCost := LibraryReportDataset.Sum('UnitCost' + Format(EntryType.AsInteger() + 1));
        Assert.AreNearlyEqual(ValueEntry."Cost Amount (Actual)" / Item.Inventory, UnitCost, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ErrorCostShares, 'unit cost', Item."No."));

        // Cost amount.
        CostAmount := LibraryReportDataset.Sum('TotalCostTotal' + Format(EntryType.AsInteger() + 1));
        Assert.AreNearlyEqual(ValueEntry."Cost Amount (Actual)", CostAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ErrorCostShares, 'cost amount', Item."No."));
    end;

    local procedure FindInventoryReportDifferenceEntry(var InventoryReportEntry: Record "Inventory Report Entry")
    begin
        InventoryReportEntry.SetRange(Type, InventoryReportEntry.Type::" ");
        InventoryReportEntry.FindFirst();
    end;

    local procedure MockGLEntry(GLAccountNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry.Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Insert();

        exit(GLEntry."Entry No.");
    end;

    local procedure MockGLEntryOnDate(GLAccountNo: Code[20]; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Get(MockGLEntry(GLAccountNo));
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Modify();
    end;

    local procedure MockGLEntryOnInventoryAccount(InventoryPostingGroup: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.Get('', InventoryPostingGroup);
        MockGLEntry(InventoryPostingSetup."Inventory Account");
    end;

    local procedure MockInventoryReportEntry(var InventoryReportEntry: Record "Inventory Report Entry"; ReportEntryType: Option)
    begin
        InventoryReportEntry.Type := ReportEntryType;
        InventoryReportEntry."No." := LibraryUtility.GenerateGUID();
        InventoryReportEntry.Insert();
    end;

    local procedure MockValueEntry(ItemNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type"; EntryType: Enum "Cost Entry Type"): Integer
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item No." := ItemNo;
        ValueEntry."Item Ledger Entry Type" := ItemLedgerEntryType;
        ValueEntry."Entry Type" := EntryType;
        ValueEntry.Insert();

        exit(ValueEntry."Entry No.");
    end;

    local procedure MockValueEntryWithOrderType(ItemNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type"; EntryType: Enum "Cost Entry Type"; OrderType: Enum "Inventory Order Type")
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Get(MockValueEntry(ItemNo, ItemLedgerEntryType, EntryType));
        ValueEntry."Order Type" := OrderType;
        ValueEntry.Modify();
    end;

    local procedure MockValueEntryWithVarianceType(ItemNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type"; EntryType: Enum "Cost Entry Type"; VarianceType: Enum "Cost Variance Type")
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Get(MockValueEntry(ItemNo, ItemLedgerEntryType, EntryType));
        ValueEntry."Variance Type" := VarianceType;
        ValueEntry.Modify();
    end;

    local procedure PostInventoryPositiveAdjustment(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
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

    local procedure UpdateAutomaticCostPosting(AutomaticCostPosting: Boolean)
    begin
        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := AutomaticCostPosting;
        InventorySetup.Modify();
    end;

    [Normal]
    local procedure VerifyInventoryValuation(ItemNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        ValueEntryBOP: Record "Value Entry";
        ValueEntryIncr: Record "Value Entry";
        ValueEntryDecr: Record "Value Entry";
        Item: Record Item;
        ValueEOP: Decimal;
        QtyEOP: Decimal;
    begin
        Item.SetRange("No.", ItemNo);
        Item.FindFirst();
        Item.CalcFields(Inventory);
        Commit();
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Inventory Valuation", true, false, Item);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo', ItemNo);

        // Beginning of period.
        VerifyInvtValTimeFrame(ValueEntryBOP, ItemNo, 0D, StartDate - 1, 'StartingInvoicedQty', 'StartingInvoicedValue');

        // Increases in period.
        ValueEntryIncr.SetFilter("Item Ledger Entry Type", '%1|%2',
          ValueEntryIncr."Item Ledger Entry Type"::"Positive Adjmt.",
          ValueEntryIncr."Item Ledger Entry Type"::"Assembly Output");
        VerifyInvtValTimeFrame(ValueEntryIncr, ItemNo, StartDate, EndDate, 'IncreaseInvoicedQty', 'IncreaseInvoicedValue');

        // Decreases in period.
        ValueEntryDecr.SetFilter("Item Ledger Entry Type", '%1|%2|%3|%4',
          ValueEntryDecr."Item Ledger Entry Type"::"Negative Adjmt.",
          ValueEntryDecr."Item Ledger Entry Type"::"Assembly Consumption",
          ValueEntryDecr."Item Ledger Entry Type"::Sale,
          ValueEntryDecr."Item Ledger Entry Type"::Consumption);
        VerifyInvtValTimeFrame(ValueEntryDecr, ItemNo, StartDate, EndDate, 'DecreaseInvoicedQty', 'DecreaseInvoicedValue');

        // End of period.
        QtyEOP := LibraryReportDataset.Sum('EndingInvoicedQty');
        LibraryReportDataset.Reset();
        ValueEOP := LibraryReportDataset.Sum('EndingInvoicedValue');
        LibraryReportDataset.Reset();

        Assert.AreNearlyEqual(ValueEntryBOP."Invoiced Quantity" + ValueEntryIncr."Invoiced Quantity" +
          ValueEntryDecr."Invoiced Quantity",
          QtyEOP, LibraryERM.GetUnitAmountRoundingPrecision(), 'Wrong end of period qty for item ' + ItemNo);
        Assert.AreNearlyEqual(ValueEntryBOP."Cost Amount (Actual)" + ValueEntryIncr."Cost Amount (Actual)" +
          ValueEntryDecr."Cost Amount (Actual)",
          ValueEOP, LibraryERM.GetAmountRoundingPrecision(), 'Wrong end of period value for item ' + ItemNo);
    end;

    [Normal]
    local procedure VerifyInvtValTimeFrame(var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; FromDate: Date; ToDate: Date; QtyElement: Text; ValueElement: Text)
    var
        Qty: Decimal;
        Value: Decimal;
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Posting Date", FromDate, ToDate);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Invoiced Quantity");
        Qty := LibraryReportDataset.Sum(QtyElement);
        LibraryReportDataset.Reset();
        Value := LibraryReportDataset.Sum(ValueElement);
        LibraryReportDataset.Reset();
        Assert.AreNearlyEqual(Abs(ValueEntry."Invoiced Quantity"), Qty, LibraryERM.GetUnitAmountRoundingPrecision(),
          'Wrong ' + QtyElement + ' for item ' + ItemNo);
        Assert.AreNearlyEqual(Abs(ValueEntry."Cost Amount (Actual)"), Value, LibraryERM.GetAmountRoundingPrecision(),
          'Wrong ' + ValueElement + ' for item ' + ItemNo);
    end;

    [Normal]
    local procedure VerifyPostCostToGLTestForOrder(AssemblyHeader: Record "Assembly Header"; PostingMethod: Option; CompDimErrorMsg: Text[1024]; HdrDimErrorMsg: Text[1024])
    var
        ValueEntry: Record "Value Entry";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        GetOrderValueEntries(ValueEntry, AssemblyHeader);

        // Verify report for item component entries.
        PostedAssemblyHeader.Reset();
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.SetRange("Item No.", AssemblyHeader."Item No.");
        if PostedAssemblyHeader.FindFirst() then begin
            PostedAssemblyLine.Reset();
            PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
            PostedAssemblyLine.SetRange(Type, PostedAssemblyLine.Type::Item);
            if PostedAssemblyLine.FindSet() then
                repeat
                    VerifyPostCostToGLTest(ValueEntry, PostedAssemblyLine."No.", PostingMethod, CompDimErrorMsg);
                until PostedAssemblyLine.Next() = 0;
        end;

        // Verify reports for assembly item.
        VerifyPostCostToGLTest(ValueEntry, PostedAssemblyHeader."Item No.", PostingMethod, HdrDimErrorMsg);
    end;

    [Normal]
    local procedure VerifyPostCostToGLTest(var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; PostingMethod: Option; DimensionErrorMessage: Text)
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Item: Record Item;
        DocNo: Code[20];
    begin
        PostValueEntryToGL.Reset();
        PostValueEntryToGL.SetRange("Item No.", ItemNo);
        Item.Get(ItemNo);
        if PostingMethod = PostMethod::"per Posting Group" then
            DocNo := Item."No.";

        Commit();
        LibraryVariableStorage.Enqueue(PostingMethod);
        LibraryVariableStorage.Enqueue(DocNo);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Post Invt. Cost to G/L - Test", true, false, PostValueEntryToGL);

        LibraryReportDataset.LoadDataSetFile();
        if PostValueEntryToGL.FindSet() then begin
            repeat
                ValueEntry.Get(PostValueEntryToGL."Value Entry No.");
                InventoryPostingSetup.Get(ValueEntry."Location Code", Item."Inventory Posting Group");
                GeneralPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");

                // Verify: Account and amount.
                LibraryReportDataset.SetRange('TempInvtPostToGLTestBuf__Value_Entry_No__', ValueEntry."Entry No.");
                LibraryReportDataset.GetNextRow();
                LibraryReportDataset.AssertCurrentRowValueEquals('TempInvtPostToGLTestBuf_Amount', ValueEntry."Cost Amount (Actual)");

                // Verify debiting and crediting accounts.
                LibraryReportDataset.AssertCurrentRowValueEquals('TempInvtPostToGLTestBuf__Account_No__',
                  InventoryPostingSetup."Inventory Account");
            until PostValueEntryToGL.Next() = 0;

            // Check warning for dimensions, if the case.
            if DimensionErrorMessage <> '' then begin
                LibraryReportDataset.Reset();
                LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', DimensionErrorMessage);
                LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_Caption', Format(WarningCaption));
            end;
        end;
    end;

    [Normal]
    local procedure VerifyInvtGLReconForOrder(AssemblyHeader: Record "Assembly Header")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        // Verify report for item component entries.
        PostedAssemblyHeader.Reset();
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.SetRange("Item No.", AssemblyHeader."Item No.");
        if PostedAssemblyHeader.FindFirst() then begin
            PostedAssemblyLine.Reset();
            PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
            PostedAssemblyLine.SetRange(Type, PostedAssemblyLine.Type::Item);
            if PostedAssemblyLine.FindSet() then
                repeat
                    VerifyInvtGLRecon(PostedAssemblyLine."No.");
                until PostedAssemblyLine.Next() = 0;
        end;

        // Verify reports for assembly item.
        VerifyInvtGLRecon(PostedAssemblyHeader."Item No.");
    end;

    [Normal]
    local procedure VerifyInvtGLRecon(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
        InventoryGLReconciliation: TestPage "Inventory - G/L Reconciliation";
    begin
        Commit(); // Make sure the adjustment entries are commited, in order not to be rolled back after the error assertions in the page handler.

        GlobalInventoryAdjmt :=
          GetValueEntriesAmount(
            ItemNo, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation,
            ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", ValueEntry."Item Ledger Entry Type"::"Assembly Output",
            ValueEntry."Variance Type"::" ");
        GlobalCapacityVariance :=
          GetValueEntriesAmount(
            ItemNo, ValueEntry."Entry Type"::Variance, ValueEntry."Entry Type"::Variance, ValueEntry."Item Ledger Entry Type"::Output,
            ValueEntry."Item Ledger Entry Type"::"Assembly Output",
            ValueEntry."Variance Type"::Capacity);
        GlobalMaterialVariance :=
          GetValueEntriesAmount(
            ItemNo, ValueEntry."Entry Type"::Variance, ValueEntry."Entry Type"::Variance, ValueEntry."Item Ledger Entry Type"::Output,
            ValueEntry."Item Ledger Entry Type"::"Assembly Output",
            ValueEntry."Variance Type"::Material);
        GlobalCOGS :=
          GetValueEntriesAmount(
            ItemNo, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation,
            ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Item Ledger Entry Type"::Sale,
            ValueEntry."Variance Type"::" ");

        InventoryGLReconciliation.OpenEdit();
        InventoryGLReconciliation.ItemFilter.SetValue(ItemNo);
        InventoryGLReconciliation."&Show Matrix".Invoke();
        InventoryGLReconciliation.OK().Invoke();
    end;

    [Normal]
    local procedure VerifyDemandOverview(AssemblyHeader: Record "Assembly Header")
    var
        Item: Record Item;
        DemandOverview: TestPage "Demand Overview";
        ItemNo: array[10] of Code[20];
        ResourceNo: array[10] of Code[20];
        "count": Integer;
    begin
        LibraryAssembly.GetCompsToAdjust(ItemNo, ResourceNo, AssemblyHeader);

        DemandOverview.OpenEdit();
        DemandOverview.StartDate.SetValue(AssemblyHeader."Starting Date");
        DemandOverview.EndDate.SetValue(AssemblyHeader."Ending Date");
        DemandOverview.DemandType.SetValue(AssemblyDemandLabel);
        DemandOverview.DemandNoCtrl.SetValue(AssemblyHeader."No.");
        DemandOverview.Calculate.Invoke();

        DemandOverview.First();
        count := 1;
        while ItemNo[count] <> '' do begin
            Item.Get(ItemNo[count]);
            Item.CalcFields(
              "Qty. on Asm. Component", "Qty. on Assembly Order", "Qty. on Prod. Order", Inventory, "Reserved Qty. on Inventory");
            Assert.AreEqual(Item."No.", DemandOverview."Item No.".Value, 'Wrong item no in demand overview.');

            DemandOverview.Expand(true);
            DemandOverview.Next();
            Assert.AreEqual(AssemblyHeader."Starting Date", DemandOverview.Date.AsDate(), 'Wrong as of date in demand overview.');

            DemandOverview.Expand(true);
            DemandOverview.Next();
            Assert.AreEqual(Format(DemandLabel), Format(DemandOverview.Type.Value), 'Wrong demand type.');
            Assert.AreEqual(AssemblyHeader."Starting Date", DemandOverview.Date.AsDate(), 'Wrong as of date in demand overview.');
            Assert.AreEqual(Format(AssemblyLabel), DemandOverview.SourceTypeText.Value, 'Wrong source type.');
            Assert.AreEqual(
              -Item."Qty. on Asm. Component", DemandOverview.QuantityText.AsDecimal(), 'Wrong demanded qty for item ' + Item."No.");
            Assert.AreEqual(
              Item.Inventory +
              Item."Qty. on Assembly Order" +
              Item."Qty. on Prod. Order" - Item."Qty. on Asm. Component" - Item."Reserved Qty. on Inventory",
              DemandOverview."Running Total".AsDecimal(), 'Wrong total for item ' + Item."No.");

            count += 1;
            if ItemNo[count] <> '' then
                DemandOverview.Next();
        end;

        Assert.IsFalse(DemandOverview.Next(), 'More rows than expected for assembly demand ' + AssemblyHeader."No.");
        DemandOverview.OK().Invoke();
    end;

    [Normal]
    local procedure VerifyCostSharesBreakdown(AssemblyHeader: Record "Assembly Header"; CostSharePrint: Option)
    var
        Item: Record Item;
        RepMaterialCost: Decimal;
        RepCapacityCost: Decimal;
        MaterialCost: Decimal;
        ResourceCost: Decimal;
        ResourceOvhd: Decimal;
        AssemblyOvhd: Decimal;
        RepResOvhd: Decimal;
        RepMatOvhd: Decimal;
        Qty: Decimal;
        Sign: Integer;
    begin
        Item.SetRange("No.", AssemblyHeader."Item No.");
        Item.FindFirst();
        Commit();
        LibraryVariableStorage.Enqueue(AssemblyHeader."Posting Date");
        LibraryVariableStorage.Enqueue(AssemblyHeader."Posting Date");
        LibraryVariableStorage.Enqueue(CostSharePrint);
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Cost Shares Breakdown", true, false, Item);
        CalcPostedAOCostAmounts(MaterialCost, ResourceCost, ResourceOvhd, AssemblyOvhd, AssemblyHeader."No.");

        // If the item is to be sold, the overhead is already embedded in the item cost and will not tracked separately.
        // The values also show up as decreases (negative) in the report.
        Sign := 1;
        if CostSharePrint = PrintCostShare::Sales then begin
            ResourceOvhd := 0;
            AssemblyOvhd := 0;
            Sign := -1
        end;

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('CostShareBufItemNo', Item."No.");

        // Verify: Material cost, Capacity cost, Capacity Overhead and Material overhead.
        Qty := LibraryReportDataset.Sum('CostShareBufNewQuantity');
        Assert.AreNearlyEqual(AssemblyHeader."Quantity to Assemble", Sign * Qty, LibraryERM.GetUnitAmountRoundingPrecision(),
          StrSubstNo(ErrorCostShares, 'quantity', Item."No."));

        RepMaterialCost := LibraryReportDataset.Sum('CostShareBufNewMaterial');
        Assert.AreNearlyEqual(MaterialCost, Sign * RepMaterialCost, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ErrorCostShares, 'material cost', Item."No."));

        RepCapacityCost := LibraryReportDataset.Sum('CostShareBufNewCapacity');
        Assert.AreNearlyEqual(ResourceCost, Sign * RepCapacityCost, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ErrorCostShares, 'capacity cost', Item."No."));

        RepResOvhd := LibraryReportDataset.Sum('CostShareBufNewCapOverhd');
        Assert.AreNearlyEqual(ResourceOvhd, Sign * RepResOvhd, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ErrorCostShares, 'capacity overhead', Item."No."));

        RepMatOvhd := LibraryReportDataset.Sum('CostShareBufNewMatrlOverhd');
        Assert.AreNearlyEqual(AssemblyOvhd, Sign * RepMatOvhd, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ErrorCostShares, 'material overhead', Item."No."));
    end;

    [Normal]
    local procedure CalcPostedAOCostAmounts(var MaterialCost: Decimal; var ResourceCost: Decimal; var ResourceOvhd: Decimal; var AssemblyOvhd: Decimal; AssemblyHeaderNo: Code[20]): Decimal
    var
        Item: Record Item;
        PostedAssemblyLine: Record "Posted Assembly Line";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        ExpectedCost: Decimal;
        Overhead: Decimal;
        IndirectCost: Decimal;
        UnitCost: Decimal;
        LineCost: Decimal;
        LineOverhead: Decimal;
    begin
        ExpectedCost := 0;
        MaterialCost := 0;
        ResourceCost := 0;
        ResourceOvhd := 0;

        PostedAssemblyLine.SetRange("Order No.", AssemblyHeaderNo);
        PostedAssemblyLine.SetFilter(Type, '<>%1', PostedAssemblyLine.Type::" ");
        if PostedAssemblyLine.FindSet() then
            repeat
                LibraryAssembly.GetCostInformation(UnitCost, Overhead, IndirectCost, PostedAssemblyLine.Type, PostedAssemblyLine."No.", '', '');
                LineOverhead := Overhead * PostedAssemblyLine.Quantity * PostedAssemblyLine."Qty. per Unit of Measure";
                LineCost := PostedAssemblyLine."Unit Cost" * PostedAssemblyLine.Quantity;
                if PostedAssemblyLine.Type = PostedAssemblyLine.Type::Item then
                    MaterialCost += LineCost
                else begin
                    ResourceCost += LineCost;
                    ResourceOvhd += LineOverhead;
                end
            until PostedAssemblyLine.Next() = 0;

        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeaderNo);
        PostedAssemblyHeader.FindFirst();
        Item.Get(PostedAssemblyHeader."Item No.");
        AssemblyOvhd := Item."Indirect Cost %" / 100 * (MaterialCost + ResourceCost + ResourceOvhd) +
          Item."Overhead Rate" * PostedAssemblyHeader.Quantity * PostedAssemblyHeader."Qty. per Unit of Measure";
        ExpectedCost := MaterialCost + ResourceCost + ResourceOvhd + AssemblyOvhd;

        if Item."Costing Method" = Item."Costing Method"::Standard then
            exit(
              (Item."Standard Cost" * (100 + Item."Indirect Cost %") / 100 + Item."Overhead Rate") *
              PostedAssemblyHeader.Quantity * PostedAssemblyHeader."Qty. per Unit of Measure");

        exit(Round(ExpectedCost, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Normal]
    local procedure CreatePostItemJournal(ItemNo: Code[20]; ProductionOrderNo: Code[20]; ItemJournalTemplateType: Enum "Item Journal Template Type"; QtyToPost: Decimal; PostingDate: Date)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo, ItemJournalTemplateType, ProductionOrderNo);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);

        if ItemJournalLine.FindFirst() then begin
            ItemJournalLine.Validate(Quantity, QtyToPost);
            ItemJournalLine.Validate("Posting Date", PostingDate);
            if ItemJournalLine."Document No." = '' then
                ItemJournalLine.Validate(
                  "Document No.", LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), DATABASE::"Item Journal Line"));
            ItemJournalLine.Modify(true);
        end;

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvtGLReconciliationHandler(var InventoryGLReconMatrix: TestPage "Inventory - G/L Recon Matrix")
    var
        InventoryReportEntry: Record "Inventory Report Entry";
    begin
        InventoryGLReconMatrix.First();

        repeat
            if GlobalInventoryAdjmt <> 0 then
                CheckGLReconMatrixValues(
                  InventoryGLReconMatrix, 'inventory adjmt.', InventoryReportEntry.FieldCaption("Inventory Adjmt."),
                  InventoryReportEntry.FieldCaption("Capacity Variance"), InventoryReportEntry.FieldCaption(COGS),
                  InventoryReportEntry.FieldCaption("Material Variance"), GlobalInventoryAdjmt,
                  GlobalInventoryAdjmt + GlobalCapacityVariance + GlobalMaterialVariance + GlobalCOGS);

            if GlobalCapacityVariance <> 0 then
                CheckGLReconMatrixValues(
                  InventoryGLReconMatrix, 'capacity variance', InventoryReportEntry.FieldCaption("Capacity Variance"),
                  InventoryReportEntry.FieldCaption(COGS), InventoryReportEntry.FieldCaption("Inventory Adjmt."),
                  InventoryReportEntry.FieldCaption("Material Variance"), GlobalCapacityVariance,
                  GlobalInventoryAdjmt + GlobalCapacityVariance + GlobalMaterialVariance + GlobalCOGS);

            if GlobalMaterialVariance <> 0 then
                CheckGLReconMatrixValues(
                  InventoryGLReconMatrix, 'material variance', InventoryReportEntry.FieldCaption("Material Variance"),
                  InventoryReportEntry.FieldCaption(COGS), InventoryReportEntry.FieldCaption("Inventory Adjmt."),
                  InventoryReportEntry.FieldCaption("Capacity Variance"), GlobalMaterialVariance,
                  GlobalInventoryAdjmt + GlobalCapacityVariance + GlobalMaterialVariance + GlobalCOGS);

            if GlobalCOGS <> 0 then
                CheckGLReconMatrixValues(
                  InventoryGLReconMatrix, 'COGS', InventoryReportEntry.FieldCaption(COGS),
                  InventoryReportEntry.FieldCaption("Inventory Adjmt."), InventoryReportEntry.FieldCaption("Capacity Variance"),
                  InventoryReportEntry.FieldCaption("Material Variance"), GlobalCOGS,
                  GlobalInventoryAdjmt + GlobalCapacityVariance + GlobalMaterialVariance + GlobalCOGS);

        until not InventoryGLReconMatrix.Next();
    end;

    [Normal]
    local procedure CheckGLReconMatrixValues(InventoryGLReconMatrix: TestPage "Inventory - G/L Recon Matrix"; ErrorMessage: Text; CheckedValue: Text; SkipValue1: Text; SkipValue2: Text; SkipValue3: Text; ExpAmount: Decimal; ExpTotalAmount: Decimal)
    var
        InventoryReportEntry: Record "Inventory Report Entry";
    begin
        case InventoryGLReconMatrix.Name.Value of
            CheckedValue:
                begin
                    Assert.AreEqual(ExpAmount, -InventoryGLReconMatrix.Field1.AsDecimal(), StrSubstNo(ErrorGLRecon, ErrorMessage, ''));
                    Assert.AreEqual(ExpAmount, -InventoryGLReconMatrix.Field4.AsDecimal(), StrSubstNo(ErrorGLRecon, ErrorMessage, ' - total '));
                end;
            InventoryReportEntry.FieldCaption(Total):
                begin
                    if ExpTotalAmount <> 0 then
                        Assert.AreEqual(ExpTotalAmount, InventoryGLReconMatrix.Field1.AsDecimal(), StrSubstNo(ErrorGLRecon, '', ' - total '))
                    else
                        asserterror ExpAmount := InventoryGLReconMatrix.Field1.AsDecimal();
                    asserterror ExpAmount := InventoryGLReconMatrix.Field4.AsDecimal();
                end;
            SkipValue1, SkipValue2, SkipValue3:
                ;
            else begin
                asserterror ExpAmount := InventoryGLReconMatrix.Field1.AsDecimal();
                asserterror ExpAmount := InventoryGLReconMatrix.Field4.AsDecimal();
            end;
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemRegValueReqPageHandler(var ItemRegisterValue: TestRequestPage "Item Register - Value")
    begin
        ItemRegisterValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtValuationCostSpecRequestPageHandler(var InvtValuationCostSpec: TestRequestPage "Invt. Valuation - Cost Spec.")
    var
        ReportDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ReportDate);
        InvtValuationCostSpec.ValuationDate.SetValue(ReportDate);
        InvtValuationCostSpec.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtValuationRequestPageHandler(var InventoryValuation: TestRequestPage "Inventory Valuation")
    var
        StartDate: Variant;
        EndingDate: Variant;
        IncludeExpectedCost: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(IncludeExpectedCost);

        InventoryValuation.StartingDate.SetValue(StartDate);
        InventoryValuation.EndingDate.SetValue(EndingDate);
        InventoryValuation.IncludeExpectedCost.SetValue(IncludeExpectedCost);
        InventoryValuation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownRequestPageHandler(var CostSharesBreakdown: TestRequestPage "Cost Shares Breakdown")
    var
        StartDate: Variant;
        EndingDate: Variant;
        CostSharePrint: Variant;
        ShowDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(CostSharePrint);
        LibraryVariableStorage.Dequeue(ShowDetails);

        CostSharesBreakdown.StartDate.SetValue(StartDate);
        CostSharesBreakdown.EndDate.SetValue(EndingDate);
        CostSharesBreakdown.CostSharePrint.SetValue(CostSharePrint);
        CostSharesBreakdown.ShowDetails.SetValue(ShowDetails);
        CostSharesBreakdown.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLTestRequestPageHandler(var PostInvtCostToGLTest: TestRequestPage "Post Invt. Cost to G/L - Test")
    var
        PostMethod: Variant;
        DocNo: Variant;
        ShowDim: Variant;
        ShowOnlyWarnings: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostMethod);
        LibraryVariableStorage.Dequeue(DocNo);
        LibraryVariableStorage.Dequeue(ShowDim);
        LibraryVariableStorage.Dequeue(ShowOnlyWarnings);

        PostInvtCostToGLTest.PostingMethod.SetValue(PostMethod); // Post Method: per entry or per Posting Group.
        PostInvtCostToGLTest.DocumentNo.SetValue(DocNo); // Doc No. required when posting per Posting Group.
        PostInvtCostToGLTest.ShowDimensions.SetValue(ShowDim);
        PostInvtCostToGLTest.ShowOnlyWarnings.SetValue(ShowOnlyWarnings);
        PostInvtCostToGLTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;
}

