// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Journal;
using Microsoft.Finance.Dimension;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Family;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Activity;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Request;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Inventory.Posting;

codeunit 137034 "SCM Production Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Production Journal] [SCM]
        isInitialized := false;
    end;

    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        TempItemJournalLine2: Record "Item Journal Line" temporary;
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        PostedProdJournal: Boolean;
        ReserveItemNo: Code[20];
        ProductionOrderNo: Code[20];
        ErrMsgReservedItem: Label 'Reserved item %1 is not on inventory.';
        ErrMsgAppliesToEntry: Label 'Applies-to Entry must not be filled out when reservations exist in Item Ledger Entry';
        ErrMsgQuantity: Label 'Quantities must match.';
        ErrMsgTime: Label '%1 must match.';
        UnknownError: Label 'Unknown Error.';
        ErrMsgDimensions: Label 'Dimensions must be same.';
        WrongFilterOnProdOrderCompListErr: Label 'Wrong filter is set on Prod. Order Line No. field in Prod. Order Comp. Line List page.';
        InvalidBinCodeErr: Label 'Bin Code is invalid.';
        LocationWithDirectedPutAwayAndPickErr: Label 'You cannot use a Bin Code because location %1 is set up with Directed Put-away and Pick.', Comment = '%1: Field(Code)';
        UpdateInterruptedErr: Label 'The update has been interrupted to respect the warning.';
        BOMFixedQtyCalcFormulaErr: Label 'BOM Fixed Quantity Calculation Formula should be used to calculate the values.';
        FieldMustBeEmptyErr: Label '%1 must be empty', Comment = '%1 - Field Caption';
        DescriptionMustBeSame: Label 'Description must be same.';
        ProductionItemNotFoundErr: Label 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).', Comment = '%1 - Field Caption, %2 - Table Caption, %3 - Value, %4 - Related Table Caption';
        ProductionBlockedOutputItemErr: Label 'You cannot produce %1 %2 because the %3 is %4 on the %1 card.', Comment = '%1 - Table Caption (Item), %2 - Item No., %3 - Field Caption, %4 - Field Value';
        ProductionBlockedOutputItemVariantErr: Label 'You cannot produce variant %1 for %2 %3 because it is blocked for production output.', Comment = '%1 - Item Variant Code, %2 - Table Caption (Item), %3 - Item No.';

    [Test]
    [HandlerFunctions('JournalReservePageHandler')]
    [Scope('OnPrem')]
    procedure ItemProductionJnlReserveItem()
    begin
        // Check Reserved Item Not On Inventory error.

        // Create required Production Journal Setups and Open Production Journal to perform required actions.
        Initialize();
        ProdJnlForRelProdOrder();

        // Verify: Verification of 'Reserved Item Not On Inventory' when posting.
        Assert.AreEqual(StrSubstNo(ErrMsgReservedItem, ReserveItemNo), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('JournalApplyPageHandler')]
    [Scope('OnPrem')]
    procedure ItemProductionJnlApplyToEntry()
    begin
        // Check Applies To Entry With Reservation error.

        // Create required Production Journal Setups and Open Production Journal to perform required actions.
        Initialize();
        ProdJnlForRelProdOrder();

        // Verify: Verification of 'Applies To Entry' error message when posting.
        Assert.AreEqual(StrSubstNo(ErrMsgAppliesToEntry), PadStr(GetLastErrorText, 84), UnknownError);
    end;

    [Test]
    [HandlerFunctions('JournalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemProductionJnlNoPosting()
    var
        ProdOrderNo: Code[20];
    begin
        // Check Production Journal Lines for Production Item in Released Production Order before lines have been posted.

        // Create required Production Journal Setups and Open Production Journal to perform required actions.
        Initialize();
        ProdOrderNo := ProdJnlForRelProdOrder();

        // Verify: Verification of Production Journal Lines - Consumption and Output without posting of Production Journal.
        VerifyConsumptionEntries(ProdOrderNo);
        VerifyOutputEntries(ProdOrderNo);
    end;

    local procedure ProdJnlForRelProdOrder(): Code[20]
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
    begin
        // Setup: Create Items and Released Production Order Setup.
        CreateItemsWithInventory(
          ChildItemNo, ChildItemNo2, Item."Manufacturing Policy"::"Make-to-Stock", Item."Manufacturing Policy"::"Make-to-Order");
        ReserveItemNo := ChildItemNo2;
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo2, 1);  // Value important.
        CreateRoutingSetup(RoutingHeader);
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.");
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Open Production Journal and perform required actions in Handler function corresponding to each called function.
        // ------------------------------------------------------------
        // Function                         Page Handler Invoked
        // ------------------------------------------------------------
        // ItemProductionJnlReserveItem     JournalReservePageHandler
        // ItemProductionJnlApplyToEntry    JournalApplyPageHandler
        // ItemProductionJnlNoPosting       JournalPageHandler
        // ------------------------------------------------------------

        OpenProductionJournal(ProductionOrder, ProductionOrderNo);
        exit(ProductionOrderNo);
    end;

    [Test]
    [HandlerFunctions('UpdateJournalPostPageHandler')]
    [Scope('OnPrem')]
    procedure ItemProductionJnlWithPosting()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Items and Released Production Order Setup.
        Initialize();
        CreateRoutingSetup(RoutingHeader);
        CreateProdItem(Item, RoutingHeader."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.");
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Open Production Journal based on Production Order Lines. Post Lines and re-open Production Journal lines after posting.
        // Page Handler Invoked: UpdateJournalPostPageHandler.
        ProductionJournalPostLines(ProductionOrder, ProductionOrderNo);

        // Verify: Verification of Production Journal Lines after modification and posting.
        VerifyConsumpEntriesAfterPost();
        VerifyOutputEntriesAfterPost();
    end;

    [Test]
    [HandlerFunctions('JournalPageHandler')]
    [Scope('OnPrem')]
    procedure FamilyProductionJnlNoPosting()
    var
        Item: Record Item;
        Item2: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        Family: Record Family;
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // Setup: Create Items, Family and Released Production Order Setup.
        Initialize();
        CreateProdItem(Item, '');
        CreateProdItem(Item2, '');
        CreateRoutingSetup(RoutingHeader);
        CreateFamily(Family, RoutingHeader."No.", Item."No.", Item2."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Family, Family."No.");
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Select first Production Order line and Open Production Journal.
        // Page Handler Invoked: JournalPageHandler.
        SelectProdOrderLine(ProdOrderLine, ProductionOrderNo);
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");

        // Verify: Verification of Production Journal Lines without posting.
        VerifyFamilyConsumptionEntries(ProdOrderLine."Item No.", ProductionOrderNo);
        VerifyFamilyOutputEntries(ProdOrderLine."Item No.", ProductionOrder."Source No.");

        // Exercise: Select second Production Order line and Open Production Journal.
        // Page Handler Invoked: JournalPageHandler
        ProdOrderLine.Next();
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");

        // Verify: Verification of Production Journal Lines without posting.
        VerifyFamilyConsumptionEntries(ProdOrderLine."Item No.", ProductionOrderNo);
        VerifyFamilyOutputEntries(ProdOrderLine."Item No.", ProductionOrder."Source No.");
    end;

    [Test]
    [HandlerFunctions('PostJournalPageHandler')]
    [Scope('OnPrem')]
    procedure FamilyProductionJnlWithPosting()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        Family: Record Family;
    begin
        // Setup: Create Items, Family and Released Production Order Setup.
        Initialize();
        CreateProdItem(Item, '');
        CreateProdItem(Item2, '');
        CreateRoutingSetup(RoutingHeader);
        CreateFamily(Family, RoutingHeader."No.", Item."No.", Item2."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Family, Family."No.");
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Open Production Journal based on Production Order Lines. Post Lines and re-open Production Journal lines after posting.
        // Page Handler Invoked: PostJournalPageHandler.
        ProductionJournalPostLines(ProductionOrder, ProductionOrderNo);

        // Verify: Verification of Production Journal Lines after posting.
        VerifyConsumpEntriesAfterPost();
        VerifyOutputEntriesAfterPost();
    end;

    [Test]
    [HandlerFunctions('JournalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesProductionJnlNoPosting()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Items, Sales Order and Released Production Order Setup.
        Initialize();
        CreateRoutingSetup(RoutingHeader);
        CreateProdItem(Item, RoutingHeader."No.");
        CreateSalesOrder(SalesHeader, Item."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::"Sales Header", SalesHeader."No.");
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Select Production Order line and Open Production Journal.
        // Page Handler Invoked: JournalPageHandler.
        OpenProductionJournal(ProductionOrder, ProductionOrderNo);

        // Verify: Verification of Production Journal Lines without posting.
        VerifyConsumptionEntries(ProductionOrderNo);
        VerifyOutputEntries(ProductionOrderNo);
    end;

    [Test]
    [HandlerFunctions('PostJournalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesProductionJnlWithPosting()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Items, Sales Order and Released Production Order Setup.
        Initialize();
        CreateRoutingSetup(RoutingHeader);
        CreateProdItem(Item, RoutingHeader."No.");
        CreateSalesOrder(SalesHeader, Item."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::"Sales Header", SalesHeader."No.");
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Open Production Journal based on Production Order Lines. Post Lines and re-open Production Journal lines after posting.
        // Page Handler Invoked: PostJournalPageHandler.
        ProductionJournalPostLines(ProductionOrder, ProductionOrderNo);

        // Verify: Verification of Production Journal Lines after posting.
        VerifyConsumpEntriesAfterPost();
        VerifyOutputEntriesAfterPost();
    end;

    [Test]
    [HandlerFunctions('JournalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemProdJnlNoRouting()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Items and Released Production Order.
        Initialize();
        CreateRoutingSetup(RoutingHeader);
        CreateProdItem(Item, RoutingHeader."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.");
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Open Production Journal based on Production Order Lines.
        // Page Handler Invoked: JournalPageHandler.
        OpenProductionJournal(ProductionOrder, ProductionOrderNo);

        // Verify: Verification of Production Journal Lines without posting.
        VerifyConsumptionEntries(ProductionOrderNo);
        VerifyOutputEntries(ProductionOrderNo);
    end;

    [Test]
    [HandlerFunctions('PostJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemProdJnlNoRoutingPosting()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Items and Released Production Order.
        Initialize();
        CreateRoutingSetup(RoutingHeader);
        CreateProdItem(Item, RoutingHeader."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.");
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Open Production Journal based on Production Order Lines. Post Lines and re-open Production Journal lines after posting.
        // Page Handler Invoked: PostJournalPageHandler.
        ProductionJournalPostLines(ProductionOrder, ProductionOrderNo);

        // Verify: Verification of Production Journal Lines without posting.
        VerifyConsumpEntriesAfterPost();
        VerifyOutputEntriesAfterPost();
    end;

    [Test]
    [HandlerFunctions('JournalDimPageHandler')]
    [Scope('OnPrem')]
    procedure ItemProdJnlDimensions()
    var
        ProductionOrder: Record "Production Order";
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
        DimSetIDProdOrder: Integer;
    begin
        // Setup: Create Items with Dimensions and Create Released Production Order.
        Initialize();
        DimSetIDProdOrder := CreateDimRelProdOrderSetup(ProductionOrder, DefaultDimension, DefaultDimension2);
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Open Production Journal.
        // Page Handler Invoked: JournalDimPageHandler.
        OpenProductionJournal(ProductionOrder, ProductionOrderNo);

        // Verify: Verification of Dimensions on Production Journal lines.
        // Dimensions for Consumption Entries.
        TempItemJournalLine2.FindSet();
        VerifyDimensionSetEntry(DefaultDimension);
        TempItemJournalLine2.Next();
        VerifyDimensionSetEntry(DefaultDimension2);

        // Dimensions for Output Entries.
        TempItemJournalLine2.FindLast();
        Assert.AreEqual(DimSetIDProdOrder, TempItemJournalLine2."Dimension Set ID", ErrMsgDimensions);
    end;

    [Test]
    [HandlerFunctions('PostJournalDimPageHandler')]
    [Scope('OnPrem')]
    procedure ItemProdJnlDimensionsPosting()
    var
        ProductionOrder: Record "Production Order";
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
    begin
        // Setup: Create Items with Dimensions and Create Released Production Order.
        Initialize();
        CreateDimRelProdOrderSetup(ProductionOrder, DefaultDimension, DefaultDimension2);
        ProductionOrderNo := ProductionOrder."No.";

        // Exercise: Open and Post Production Journal.
        // Page Handler Invoked: PostJournalDimPageHandler.
        ProductionJournalPostLines(ProductionOrder, ProductionOrderNo);

        // Verify: Verification of Dimensions of posted Production Journal Lines from Item Ledger entry.
        VerifyDimensionSetId(DefaultDimension."No.");
        VerifyDimensionSetId(DefaultDimension2."No.");
        VerifyDimensionSetId(ProductionOrder."Source No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderCompLineListPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderCompLinesAreFilteredByNotBlankProdOrderLineNo()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        // [FEATURE] [Consumption Journal] [UI]
        // [SCENARIO 215892] List of prod. order components should be filtered by Prod. Order Line No. on looking up Prod. Order Comp. Line No. field in consumption journal, if Order Line No. on the journal line is not blank.
        Initialize();

        // [GIVEN] Prod. Order Line "X".
        MockProdOrderLine(ProdOrderLine);

        // [GIVEN] New consumption journal line.
        // [GIVEN] Order No. and Order Line No. on the journal line are selected from "X".
        ConsumptionJournal.OpenEdit();
        ConsumptionJournal.New();
        ConsumptionJournal."Order No.".SetValue(ProdOrderLine."Prod. Order No.");
        ConsumptionJournal."Order Line No.".SetValue(ProdOrderLine."Line No.");

        // [WHEN] Look up Prod. Order Comp. Line No. field.
        LibraryVariableStorage.Enqueue(Format(ProdOrderLine."Line No."));
        ConsumptionJournal."Prod. Order Comp. Line No.".Lookup();

        // [THEN] Prod. Order Comp. Line List page is opened and filtered by Prod. Order Line No.
        // The verification is done in ProdOrderCompLineListPageHandler.
    end;

    [Test]
    [HandlerFunctions('ProdOrderCompLineListPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderCompLinesAreNotFilteredByBlankProdOrderLineNo()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        // [FEATURE] [Consumption Journal] [UI]
        // [SCENARIO 215892] List of prod. order components should not be filtered by Prod. Order Line No. on looking up Prod. Order Comp. Line No. field in consumption journal, if Order Line No. on the journal line is blank.
        Initialize();

        // [GIVEN] Prod. Order Line "X".
        MockProdOrderLine(ProdOrderLine);

        // [GIVEN] New consumption journal line.
        // [GIVEN] Order No. on the journal line is selected from "X", Order Line No. is blank.
        ConsumptionJournal.OpenEdit();
        ConsumptionJournal.New();
        ConsumptionJournal."Order No.".SetValue(ProdOrderLine."Prod. Order No.");
        ConsumptionJournal."Order Line No.".SetValue('');

        // [WHEN] Look up Prod. Order Comp. Line No. field.
        LibraryVariableStorage.Enqueue('');
        ConsumptionJournal."Prod. Order Comp. Line No.".Lookup();

        // [THEN] Prod. Order Comp. Line List page is opened and not filtered by Prod. Order Line No.
        // The verification is done in ProdOrderCompLineListPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationAndBinAreUpdatedFromParentProdOrderLineOnOutput()
    var
        ItemJournalLine: Record "Item Journal Line";
        ParentProdOrderLine: Record "Prod. Order Line";
        ChildProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 380337] Location and Bin codes on Output Journal are updated with Location and Bin on parent Prod. Order Line.
        Initialize();

        // [GIVEN] Released Production Order "PO" on Location "L" with parent and child lines and bins "B1" and "B2" related to them.
        CreateReleasedProdOrderWithTwoLines(ParentProdOrderLine, ChildProdOrderLine);
        // [GIVEN] Output journal line with "Order No." = "PO".
        CreateProductionItemJournal(ItemJournalLine, ItemJournalLine."Entry Type"::Output, ParentProdOrderLine."Prod. Order No.");
        // [WHEN] Select "Order Line No.". = parent Prod. Order Line no.
        ItemJournalLine.Validate("Order Line No.", ParentProdOrderLine."Line No.");
        // [THEN] "Location Code" is equal to "L".
        // [THEN] "Bin Code" is equal to "B1".
        ItemJournalLine.TestField("Location Code", ParentProdOrderLine."Location Code");
        ItemJournalLine.TestField("Bin Code", ParentProdOrderLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationAndBinAreUpdatedFromChildProdOrderLineOnConsumption()
    var
        ItemJournalLine: Record "Item Journal Line";
        ParentProdOrderLine: Record "Prod. Order Line";
        ChildProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 380337] Location and Bin codes on Consumption Journal are updated with Location and Bin on child Prod. Order Line.
        Initialize();

        // [GIVEN] Released Production Order "PO" on Location "L" with parent and child lines and bins "B1" and "B2" related to them.
        CreateReleasedProdOrderWithTwoLines(ParentProdOrderLine, ChildProdOrderLine);
        // [GIVEN] Consumption journal line with "Order No." = "PO".
        CreateProductionItemJournal(ItemJournalLine, ItemJournalLine."Entry Type"::Consumption, ParentProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate(Quantity, 0);
        // nothing is picked yet
        // [WHEN] Select "Item No." = child Prod. Order Line item.
        ItemJournalLine.Validate("Item No.", ChildProdOrderLine."Item No.");
        // [THEN] "Location Code" is equal to "L".
        // [THEN] "Bin Code" is equal to "B2".
        ItemJournalLine.TestField("Location Code", ChildProdOrderLine."Location Code");
        ItemJournalLine.TestField("Bin Code", ChildProdOrderLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinIsUpdatedFromProdOrderLineWhenItemIsUpdatedOnOutput()
    var
        ItemJournalLine: Record "Item Journal Line";
        SavedItemJournalLine: Record "Item Journal Line";
        ParentProdOrderLine: Record "Prod. Order Line";
        ChildProdOrderLine: Record "Prod. Order Line";
        WMSManagement: Codeunit "WMS Management";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 380337] Bin code on Output Journal Line is updated from Prod. Order Line when Item No. is updated and only one Prod. Order Line related to this Item is found.
        Initialize();

        // [GIVEN] Released Production Order "PO" on Location "L" with parent and child lines and bins "B1" and "B2" related to them.
        CreateReleasedProdOrderWithTwoLines(ParentProdOrderLine, ChildProdOrderLine);
        // [GIVEN] Output journal line with "Order No." and "Item No." from parent Prod. Order Line.
        CreateProductionItemJournal(ItemJournalLine, ItemJournalLine."Entry Type"::Output, ParentProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Item No.", ParentProdOrderLine."Item No.");
        ItemJournalLine.Modify(true);
        SavedItemJournalLine := ItemJournalLine;
        // [WHEN] Update "Item No." in Item Journal Line with "Item No." from child Prod. Order Line.
        ItemJournalLine.Validate("Item No.", ChildProdOrderLine."Item No.");
        WMSManagement.CheckItemJnlLineFieldChange(ItemJournalLine, SavedItemJournalLine, ItemJournalLine.FieldCaption("Item No."));
        // [THEN] "Bin Code" is changed.
        Assert.AreNotEqual(ItemJournalLine."Bin Code", SavedItemJournalLine."Bin Code", InvalidBinCodeErr);
        // [THEN] "Bin Code" is equal to "B2".
        ItemJournalLine.TestField("Bin Code", ChildProdOrderLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearBinCodeOnItemJournalLineWithDirectedPutawayAndPickLocation()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Bin] [Directed Put-away and Pick] [UT]
        // [SCENARIO 380337] Bin code on Item Journal Line can be cleared for Location with enabled "Directed Put-away and Pick".
        Initialize();

        // [GIVEN] Location with Bin.
        CreateLocationWithNumberOfBins(Location, 1);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Item Journal Line with Location and Bin.
        CreateItemJournal(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin.Code);

        // [GIVEN] "Directed Put-away and Pick" for Location is enabled.
        Location.Validate("Directed Put-away and Pick", true);
        Location.Modify(true);

        // [WHEN] Clear "Bin Code" on Item Journal Line.
        UpdateBinCodeInItemJournalLine(ItemJournalLine, '');

        // [THEN] No error raised. "Bin Code" is cleared.
        ItemJournalLine.TestField("Bin Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EligibleBinCodeOnOutputJournalWithDirectedPutawayAndPickLocation()
    var
        ItemJournalLine: Record "Item Journal Line";
        ParentProdOrderLine: Record "Prod. Order Line";
        ChildProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Bin] [Directed Put-away and Pick]
        // [SCENARIO 380337] Bin code can be set manually on Output Journal Line if the related Prod. Order Line has the same Bin code.
        Initialize();

        // [GIVEN] Released Production Order "PO" on Location "L" with parent and child lines and bins "B1" and "B2" related to them.
        CreateReleasedProdOrderWithTwoLines(ParentProdOrderLine, ChildProdOrderLine);
        // [GIVEN] Output journal line with "Order No." and "Item No." from parent Prod. Order Line.
        CreateProductionItemJournal(ItemJournalLine, ItemJournalLine."Entry Type"::Output, ParentProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ParentProdOrderLine."Line No.");
        ItemJournalLine.Validate("Bin Code", '');
        // [WHEN] Validate "Bin Code" with "B1".
        UpdateBinCodeInItemJournalLine(ItemJournalLine, ParentProdOrderLine."Bin Code");
        // [THEN] No error raised. "Bin Code" in Item Journal Line is updated to "B1"
        ItemJournalLine.TestField("Bin Code", ParentProdOrderLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EligibleBinCodeOnConsumptionJournalWithDirectedPutawayAndPickLocation()
    var
        ItemJournalLine: Record "Item Journal Line";
        ParentProdOrderLine: Record "Prod. Order Line";
        ChildProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Bin] [Directed Put-away and Pick]
        // [SCENARIO 380337] Bin code can be set manually on Consumption Journal Line if the related Prod. Order Component has the same Bin code and Location.
        Initialize();

        // [GIVEN] Released Production Order "PO" on Location "L" with parent and child lines and bins "B1" and "B2" related to them.
        CreateReleasedProdOrderWithTwoLines(ParentProdOrderLine, ChildProdOrderLine);

        // [GIVEN] Prod. Order Component for parent Prod. Order line.
        FindProdOrderCompLine(ProdOrderComponent, ParentProdOrderLine);

        // [GIVEN] Consumption journal line for Prod. Order Component with empty "Bin Code".
        CreateProductionItemJournal(ItemJournalLine, ItemJournalLine."Entry Type"::Consumption, ProdOrderComponent."Prod. Order No.");
        ItemJournalLine.Validate(Quantity, 0);
        // nothing is picked yet
        ItemJournalLine.Validate("Item No.", ProdOrderComponent."Item No.");
        ItemJournalLine.Validate("Bin Code", '');
        // [WHEN] Validate "Bin Code" with "B2".
        UpdateBinCodeInItemJournalLine(ItemJournalLine, ChildProdOrderLine."Bin Code");
        // [THEN] No error raised. "Bin Code" in Item Journal Line is updated to "B2"
        ItemJournalLine.TestField("Bin Code", ChildProdOrderLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonEligibleBinCodeOnOutputJournalWithDirectedPutawayAndPickLocation()
    var
        ItemJournalLine: Record "Item Journal Line";
        ParentProdOrderLine: Record "Prod. Order Line";
        ChildProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Bin] [Directed Put-away and Pick]
        // [SCENARIO 380337] Bin code cannot be set manually on Output Journal Line if the related Prod. Order Component has different Bin code.
        Initialize();

        // [GIVEN] Released Production Order "PO" on Location "L" with parent and child lines and bins "B1" and "B2" related to them.
        CreateReleasedProdOrderWithTwoLines(ParentProdOrderLine, ChildProdOrderLine);
        // [GIVEN] Output journal line with "Order No." and "Item No." from parent Prod. Order Line.
        CreateProductionItemJournal(ItemJournalLine, ItemJournalLine."Entry Type"::Output, ParentProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ParentProdOrderLine."Line No.");
        ItemJournalLine.Validate("Bin Code", '');
        // [WHEN] Validate "Bin Code" with "B2".
        asserterror UpdateBinCodeInItemJournalLine(ItemJournalLine, ChildProdOrderLine."Bin Code");
        // [THEN] Error message is raised.
        Assert.ExpectedError(StrSubstNo(LocationWithDirectedPutAwayAndPickErr, ItemJournalLine."Location Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EligibleBinCodeAndWrongDirectedPutawayAndPickLocationOnOutputJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
        ParentProdOrderLine: Record "Prod. Order Line";
        ChildProdOrderLine: Record "Prod. Order Line";
        NewLocationCode: Code[10];
    begin
        // [FEATURE] [Bin] [Directed Put-away and Pick]
        // [SCENARIO 380337] Bin code cannot be set on Output Journal Line if the related Prod. Order Component has the same Bin code but different Location.
        Initialize();

        // [GIVEN] Released Production Order "PO" on Location "L1" with parent and child lines and bins "B1" and "B2" related to them.
        CreateReleasedProdOrderWithTwoLines(ParentProdOrderLine, ChildProdOrderLine);

        // [GIVEN] Location "L2" with same bin codes as in Location "L1".
        CopyLocation(NewLocationCode, ParentProdOrderLine."Location Code", ParentProdOrderLine."Bin Code");
        // [GIVEN] Output journal line with "Order No." and "Item No." from parent Prod. Order Line.
        // [GIVEN] Location Code is changed to "L2". Bin code is cleared.
        CreateProductionItemJournal(ItemJournalLine, ItemJournalLine."Entry Type"::Output, ParentProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ParentProdOrderLine."Line No.");
        ItemJournalLine.Validate("Location Code", NewLocationCode);
        ItemJournalLine.Validate("Bin Code", '');
        // [WHEN] Validate "Bin Code" with "B1".
        asserterror UpdateBinCodeInItemJournalLine(ItemJournalLine, ParentProdOrderLine."Bin Code");
        // [THEN] Error message is raised.
        Assert.ExpectedError(StrSubstNo(LocationWithDirectedPutAwayAndPickErr, ItemJournalLine."Location Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultOutputQtyFinishedRoutingOperation()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // [FEATURE] [Routing]
        // [SCENARIO 223042] "Output Quantity" should be set to 0 in output journal for finished operations

        Initialize();

        // [GIVEN] Routing "R" with two operations: "O1" and "O2"
        // [GIVEN] Create item "I" and assign the routing to the item
        LibraryInventory.CreateItem(Item);
        CreateRoutingSetup(RoutingHeader);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // [GIVEN] Released production order for item "I", "Quantity" = 1
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.");

        // [GIVEN] Open output journal for the production order. In the first line, set "Output Quantity" = 0, "Run Time" = 10, Finished = TRUE
        LibraryManufacturing.OutputJournalExplodeRouting(ProductionOrder);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Run Time", LibraryRandom.RandInt(20));
        ItemJournalLine.Validate("Output Quantity", 0);
        ItemJournalLine.Validate(Finished, true);
        ItemJournalLine.Modify(true);

        // [GIVEN] Delete the second operation and post the output journal
        ItemJournalLine.FindLast();
        ItemJournalLine.Delete(true);
        LibraryManufacturing.PostOutputJournal();

        // [WHEN] Open output journal
        SelectProdOrderLine(ProdOrderLine, ProductionOrder."No.");
        ProductionJournalMgt.InitSetupValues();
        ProductionJournalMgt.CreateJnlLines(ProductionOrder, ProdOrderLine."Line No.");

        // [THEN] Two journal lines are created. First line has "Output Quantity" = 0, "Output Quantity" in the second line is 1
        Assert.RecordCount(ItemJournalLine, 2);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Output Quantity", 0);
        ItemJournalLine.FindLast();
        ItemJournalLine.TestField("Output Quantity", ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPutAwayForProductionOrderWithPartlyFinishedRouting()
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WorkCenter: Record "Work Center";
        ItemNo: Code[20];
        OperationNo: Code[10];
    begin
        // [FEATURE] [Inventory Put-Away]
        // [SCENARIO 223253] Inventory Put-Away for production order with partly finished routing can be successfully posted
        Initialize();

        CreateBinMandatoryProductionLocation(Location);
        CreateWorkCenter(WorkCenter);
        WorkCenter."Subcontractor No." := '';
        WorkCenter.Modify();
        OperationNo := CreateRoutingSetup(RoutingHeader, WorkCenter);

        // [GIVEN] Item "I" with specified routing "R" of 2 operations
        ItemNo := CreateItemWithRouting(RoutingHeader."No.");

        // [GIVEN] Released production order "P" at bin mandatory location
        CreateAndRefreshReleasedProductionOrderAtLocation(ProductionOrder, ItemNo, 1, Location.Code);

        // [GIVEN] Post Production Journal with 2 lines, 1st line is consumption of "C", 2nd is output of "I" and corresponds to finished 1st operaton of "R"
        CreateAndPostOutputJournal(ProductionOrder."No.", OperationNo, ItemNo, Location.Code, Location."From-Production Bin Code");

        // [GIVEN] Inventory Put-Away "IPA" for "P"
        CreateInvtPutAwayAtLocation(WarehouseActivityHeader, ProductionOrder, Location.Code, 1);

        // [WHEN] Post "IPA"
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] "Item Ledger Entry" for "I" exists
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure FinishedOperationsNotExcludedFromProdOrderRoutingSerial()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemNo: Code[20];
        OperationNo: array[3] of Code[10];
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO 230130] Finished operations should not be excluded when recalculating the production order routing, routing type is Serial

        Initialize();
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        OperationNo[1] := '100';
        OperationNo[2] := '200';
        OperationNo[3] := '150';

        // [GIVEN] Serial routing "R" with 2 operations: "100" and "200"
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', OperationNo[1], RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', OperationNo[2], RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item with the routing "R", released production order for that item
        ItemNo := CreateItemWithRouting(RoutingHeader."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ItemNo);

        // [GIVEN] Change the status of the operation "200" in the production order routing to "Finished"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder.Status, ProductionOrder."No.", OperationNo[2]);
        UpdateProdOrderRoutingLineStatus(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo[2], ProdOrderRoutingLine."Routing Status"::Finished);

        // [WHEN] Insert a new operation "150" in the prod. order routing, it is sequenced between operations 100 and 200
        CreateProdOrderRoutingLine(
          ProdOrderRoutingLine, ProductionOrder, ProdOrderRoutingLine."Routing Reference No.", ProdOrderRoutingLine."Routing No.",
          OperationNo[3], WorkCenter."No.");
        ProdOrderRoutingLine.Validate("Run Time", LibraryRandom.RandInt(10));

        // [THEN] Routing is recalculated, all operations have "Next Operation No." and "Previous Operation No."
        // [THEN] Operations sequence is 100 -> 150 -> 200
        VerifyProdOrderRtngLineNextPrevOperation(ProductionOrder.Status, ProductionOrder."No.", OperationNo[1], OperationNo[3], '');
        VerifyProdOrderRtngLineNextPrevOperation(ProductionOrder.Status, ProductionOrder."No.", OperationNo[2], '', OperationNo[3]);
        VerifyProdOrderRtngLineNextPrevOperation(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo[3], OperationNo[2], OperationNo[1]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure FinishedOperationsNotExcludedFromProdOrderRoutingParallel()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        OperationNo: array[5] of Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO 230130] Finished operations should not be excluded when recalculating the production order routing, routing type is Parallel

        Initialize();
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        OperationNo[1] := '100';
        OperationNo[2] := '200';
        OperationNo[3] := '300';
        OperationNo[4] := '400';
        OperationNo[5] := '150';

        // [GIVEN] Parallel routing "R" with 4 operations: "100", "200", "300" and "400"
        // [GIVEN] Operations "200" and "300" are set up to be executed in parallel
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        CreateRoutingLineSetNextOperation(
          RoutingLine, RoutingHeader, WorkCenter."No.", OperationNo[1], StrSubstNo('%1|%2', OperationNo[2], OperationNo[3]));
        CreateRoutingLineSetNextOperation(RoutingLine, RoutingHeader, WorkCenter."No.", OperationNo[2], OperationNo[4]);
        CreateRoutingLineSetNextOperation(RoutingLine, RoutingHeader, WorkCenter."No.", OperationNo[3], OperationNo[4]);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', OperationNo[4], RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item with the routing "R", released production order for that item
        ItemNo := CreateItemWithRouting(RoutingHeader."No.");
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Change the status of the operation "400" in the production order routing to "Finished"
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder.Status, ProductionOrder."No.", OperationNo[4]);
        UpdateProdOrderRoutingLineStatus(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo[4], ProdOrderRoutingLine."Routing Status"::Finished);

        // [WHEN] Insert a new operation "150" in the prod. order routing, it is sequenced between operations 100 and 200
        CreateProdOrderRoutingLine(
          ProdOrderRoutingLine, ProductionOrder, ProdOrderRoutingLine."Routing Reference No.", ProdOrderRoutingLine."Routing No.",
          OperationNo[5], WorkCenter."No.");

        UpdateNextOperationOnProdOrderRoutingLine(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo[1], StrSubstNo('%1|%2', OperationNo[5], OperationNo[3]));
        UpdateNextOperationOnProdOrderRoutingLine(ProductionOrder.Status, ProductionOrder."No.", OperationNo[5], OperationNo[2]);

        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder.Status, ProductionOrder."No.", OperationNo[5]);
        ProdOrderRoutingLine.Validate("Run Time", LibraryRandom.RandInt(20));

        // [THEN] Routing is recalculated, all operations have "Next Operation No." and "Previous Operation No."
        // [THEN] Operations 150 and 300 are sequenced for parallel execution
        VerifyProdOrderRtngLineNextPrevOperation(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo[1], StrSubstNo('%1|%2', OperationNo[5], OperationNo[3]), '');
        VerifyProdOrderRtngLineNextPrevOperation(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo[2], OperationNo[4], OperationNo[5]);
        VerifyProdOrderRtngLineNextPrevOperation(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo[3], OperationNo[4], OperationNo[1]);
        VerifyProdOrderRtngLineNextPrevOperation(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo[4], '', StrSubstNo('%1|%2', OperationNo[2], OperationNo[3]));
        VerifyProdOrderRtngLineNextPrevOperation(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo[5], OperationNo[2], OperationNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAllocatedCapacityTimeCalculation()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        OperationNo: array[4] of Code[10];
        ItemNo: Code[20];
        OldThirdRouthingLineEndDateTime: DateTime;
        EndDateTime: DateTime;
    begin
        // [FEATURE] [Routing] [Production Order] [Prod. Order Capacity Need]
        // [SCENARIO 466208] Allocated capacity on schedule manually routing line should be updated according new ending date-time

        Initialize();
        // [GIVEN] Work Center with capacity unit of measure "Minutes" and 100% efficiency
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        //CreateWorkCenterSetup(WorkCenter, CapacityUnitOfMeasure.Type::Minutes, 100000T, 165959T);
        //CreateCapacityConstrainedResource(WorkCenter."No.");

        OperationNo[1] := '100';
        OperationNo[2] := '200';
        OperationNo[3] := '300';
        OperationNo[4] := '400';

        // [GIVEN] Serial routing "R" with 4 operations: "100", "200", "300" and "400" and random activiti times
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineSetNextOperation(RoutingLine, RoutingHeader, WorkCenter."No.", OperationNo[1], OperationNo[2]);
        UpdateRoutingLine(RoutingLine, Random(10), Random(10), 0);
        CreateRoutingLineSetNextOperation(RoutingLine, RoutingHeader, WorkCenter."No.", OperationNo[2], OperationNo[3]);
        UpdateRoutingLine(RoutingLine, Random(10), Random(10), 0);
        CreateRoutingLineSetNextOperation(RoutingLine, RoutingHeader, WorkCenter."No.", OperationNo[3], OperationNo[4]);
        UpdateRoutingLine(RoutingLine, Random(10), Random(10), 0);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo[4], RoutingLine.Type::"Work Center", WorkCenter."No.");
        UpdateRoutingLine(RoutingLine, Random(10), Random(10), 0);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item with the routing "R", released production order for that item
        ItemNo := CreateItemWithRouting(RoutingHeader."No.");
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] check "300" routing line ending time
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder.Status, ProductionOrder."No.", OperationNo[3]);
        OldThirdRouthingLineEndDateTime := ProdOrderRoutingLine."Ending Date-Time";

        // [GIVEN] Change the "Schedule Manually" of the operation "200" in the production order routing to "TRUE" and increase ending date-time
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder.Status, ProductionOrder."No.", OperationNo[2]);
        GetLastProdOrderCapacityNeed(ProdOrderCapacityNeed, ProdOrderRoutingLine);
        EndDateTime := ProdOrderCapacityNeed."Ending Date-Time";

        ProdOrderRoutingLine.Validate("Schedule Manually", true);
        ProdOrderRoutingLine.Validate("Ending Date-Time", OldThirdRouthingLineEndDateTime + LibraryRandom.RandIntInRange(2, 20) * 60000);
        ProdOrderRoutingLine.Modify();

        // [WHEN] Check Allocated capacity lines for operation "200"
        GetLastProdOrderCapacityNeed(ProdOrderCapacityNeed, ProdOrderRoutingLine);

        // [THEN] Allocated capacity line for operation "200" is updated according new ending date-time
        CheckValues(ProdOrderCapacityNeed, ProdOrderRoutingLine, EndDateTime, OldThirdRouthingLineEndDateTime);
    end;

    local procedure GetLastProdOrderCapacityNeed(var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Boolean
    begin
        ProdOrderCapacityNeed.Reset();
        ProdOrderCapacityNeed.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderCapacityNeed.SetRange("Requested Only", false);
        ProdOrderCapacityNeed.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderCapacityNeed.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderCapacityNeed.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        exit(ProdOrderCapacityNeed.FindLast());
    end;

    local procedure CheckValues(var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; EndDateTime: DateTime; OldThirdRouthingLineEndDateTime: DateTime)
    var
        ProdOrderCapacityNeedTimeCalcError: Label 'Prod. Order Capacity Need Time Calc. Error';
    begin
        Assert.IsTrue(ProdOrderCapacityNeed."Ending Date-Time" > EndDateTime, ProdOrderCapacityNeedTimeCalcError);
        Assert.IsTrue(ProdOrderCapacityNeed."Ending Date-Time" > OldThirdRouthingLineEndDateTime, ProdOrderCapacityNeedTimeCalcError);
        Assert.IsTrue(ProdOrderRoutingLine."Ending Date-Time" >= ProdOrderCapacityNeed."Ending Date-Time", ProdOrderCapacityNeedTimeCalcError);
    end;

    local procedure UpdateRoutingLine(var RoutingLine: Record "Routing Line"; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal)
    begin
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerOptional')]
    [Scope('OnPrem')]
    procedure OutputQtyOnFinishedOperationValidatedAfterConfirm()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        OperationNo: Code[10];
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO 230130] New value for the field "Output Quantity" in item journal should be accepted after user's confirmation when the journal line refers to a finished routing line

        Initialize();

        // [GIVEN] Released production order "P"
        CreateAndRefreshReleasedProdOrderWithNewItemAndRouting(ProductionOrder, OperationNo);

        // [GIVEN] The first routing operation "100" for the production order "P" is finished
        LibraryVariableStorage.Enqueue(true);
        UpdateProdOrderRoutingLineStatus(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo, ProdOrderRoutingLine."Routing Status"::Finished);

        // [GIVEN] Create an output journal line for the production order "P", set "Operation No." = "100"
        InitOutputJournalLine(ItemJournalLine, ProductionOrder."No.", ProductionOrder."Source No.");
        ItemJournalLine.Validate("Operation No.", OperationNo);

        // [WHEN] Set "Output Quantity" = 10 and confirm the request
        LibraryVariableStorage.Enqueue(true);
        ItemJournalLine.Validate("Output Quantity", LibraryRandom.RandInt(10));

        // [THEN] Output quantity is validated
        ItemJournalLine.TestField(Quantity, ItemJournalLine."Output Quantity");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerOptional')]
    [Scope('OnPrem')]
    procedure OutputQtyOnFinishedOperationResetAfterConfirmationCancel()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        OperationNo: Code[10];
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO 230130] Error message should be shown when entering output quantity in the item journal for a finished routing line

        Initialize();

        // [GIVEN] Released production order "P"
        CreateAndRefreshReleasedProdOrderWithNewItemAndRouting(ProductionOrder, OperationNo);

        // [GIVEN] The first routing operation "100" for the production order "P" is finished
        LibraryVariableStorage.Enqueue(true);
        UpdateProdOrderRoutingLineStatus(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo, ProdOrderRoutingLine."Routing Status"::Finished);

        // [GIVEN] Create an output journal line for the production order "P", set "Operation No." = "100"
        InitOutputJournalLine(ItemJournalLine, ProductionOrder."No.", ProductionOrder."Source No.");
        ItemJournalLine.Validate("Operation No.", OperationNo);

        // [WHEN] Set "Output Quantity" = 10 in the item journal line and decline the confirmiation request
        LibraryVariableStorage.Enqueue(false);
        asserterror ItemJournalLine.Validate("Output Quantity", LibraryRandom.RandInt(10));

        // [THEN] Output quantity is not saved
        Assert.ExpectedError(UpdateInterruptedErr);
        ItemJournalLine.TestField(Quantity, 0);
        ItemJournalLine.TestField("Output Quantity", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerOptional')]
    [Scope('OnPrem')]
    procedure FinishedOperationValidatedInOutputJournalAfterConfirm()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        WorkCenter: Record "Work Center";
        OperationNo: Code[10];
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO 230130] Item journal line can be linked to a finished prod. order routing line after user's confirmation

        Initialize();

        // [GIVEN] Released production order "P"
        CreateWorkCenter(WorkCenter);
        WorkCenter."Subcontractor No." := '';
        WorkCenter.Modify();
        CreateAndRefreshReleasedProdOrderWithNewItemAndRouting(ProductionOrder, OperationNo, WorkCenter);

        // [GIVEN] The first routing operation "100" for the production order "P" is finished
        LibraryVariableStorage.Enqueue(true);
        UpdateProdOrderRoutingLineStatus(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo, ProdOrderRoutingLine."Routing Status"::Finished);

        // [GIVEN] Create an output journal line for the production order "P", set "Output Quantity" = 10
        InitOutputJournalLine(ItemJournalLine, ProductionOrder."No.", ProductionOrder."Source No.");
        ItemJournalLine.Validate("Output Quantity", LibraryRandom.RandInt(10));

        // [WHEN] Set "Operation No." = "100" in the item journal line and confirm the request
        LibraryVariableStorage.Enqueue(true);
        ItemJournalLine.Validate("Operation No.", OperationNo);

        // [THEN] Operation no. is validated
        ItemJournalLine.TestField("Operation No.", OperationNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerOptional')]
    [Scope('OnPrem')]
    procedure FinishedOperationResetInOutputJournalAfterConfirmationCancel()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        OperationNo: Code[10];
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO 230130] Error message should be shown when entering an operation no. for the finished routing operation if output quantity is not zero, and action is not confirmed

        Initialize();

        // [GIVEN] Released production order "P"
        CreateAndRefreshReleasedProdOrderWithNewItemAndRouting(ProductionOrder, OperationNo);

        // [GIVEN] The first routing operation "100" for the production order "P" is finished
        LibraryVariableStorage.Enqueue(true);
        UpdateProdOrderRoutingLineStatus(
          ProductionOrder.Status, ProductionOrder."No.", OperationNo, ProdOrderRoutingLine."Routing Status"::Finished);

        // [GIVEN] Create an output journal line for the production order "P", set "Output Quantity" = 10
        InitOutputJournalLine(ItemJournalLine, ProductionOrder."No.", ProductionOrder."Source No.");
        ItemJournalLine.Validate("Output Quantity", LibraryRandom.RandInt(10));

        // [WHEN] Set "Operation No." = "100" in the item journal line and decline the confirmiation request
        LibraryVariableStorage.Enqueue(false);
        asserterror ItemJournalLine.Validate("Operation No.", OperationNo);

        // [THEN] Operation no. is not saved
        Assert.ExpectedError(UpdateInterruptedErr);
        ItemJournalLine.TestField("Operation No.", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderWithVeryLongDescriptionCanBeHandledbyConsumptionJournal()
    var
        ProductionOrder: Record "Production Order";
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        // [FEATURE] [Consumption Journal] [UI]
        // [SCENARIO 364799] Consumption Journal page can handle production order with description of length 100
        Initialize();

        // [GIVEN] Production Order with a description of Length = 100
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate(Description, LibraryUtility.GenerateRandomAlphabeticText(100, 0));
        ProductionOrder.Modify(true);

        // [GIVEN] Consumption Journal page was open
        ConsumptionJournal.OpenEdit();
        ConsumptionJournal.New();

        // [WHEN] Validate Order No. in the page
        ConsumptionJournal."Order No.".SetValue(ProductionOrder."No.");

        // [THEN] No error, description is displayed
        ConsumptionJournal.Description.AssertEquals(ProductionOrder.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderWithVeryLongDescriptionCanBeHandledbyRecurringConsumptionJournal()
    var
        ProductionOrder: Record "Production Order";
        RecurringConsumptionJournal: TestPage "Recurring Consumption Journal";
    begin
        // [FEATURE] [Consumption Journal] [UI]
        // [SCENARIO 364799] Recurring Consumption Journal page can handle production order with description of length 100
        Initialize();

        // [GIVEN] Production Order with a description of Length = 100
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate(Description, LibraryUtility.GenerateRandomAlphabeticText(100, 0));
        ProductionOrder.Modify(true);

        // [GIVEN] Recurring Consumption Journal page was open
        RecurringConsumptionJournal.OpenEdit();
        RecurringConsumptionJournal.New();

        // [WHEN] Validate Order No. in the page
        RecurringConsumptionJournal."Order No.".SetValue(ProductionOrder."No.");

        // [THEN] No error, description is displayed
        RecurringConsumptionJournal.Description.AssertEquals(ProductionOrder.Description);
    end;

    [Test]
    procedure ItemNoIsUpdatedOnValidateProdOrderCompLineNo()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ConsumpItemJournalTemplate: Record "Item Journal Template";
        ConsumpItemJournalBatch: Record "Item Journal Batch";
        ConsumpItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Consumption] [Prod. Order Component] [UT]
        // [SCENARIO 390313] Item No. is updated on consumption journal line when Stan validates "Prod. Order Comp Line No." field.
        Initialize();

        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Production Order with component "C"
        CreateProductionItem(ProdItem, CompItem);
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ProdItem."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Open consumption journal and select the Production Order No.
        LibraryInventory.SelectItemJournalTemplateName(
          ConsumpItemJournalTemplate, ConsumpItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ConsumpItemJournalBatch, ConsumpItemJournalTemplate.Type, ConsumpItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ConsumpItemJournalLine, ConsumpItemJournalBatch, ConsumpItemJournalTemplate.Name, ConsumpItemJournalBatch.Name,
          ConsumpItemJournalLine."Entry Type"::Consumption);
        ConsumpItemJournalLine.Validate("Order No.", ProductionOrder."No.");

        // [WHEN] Select the prod. order component line no. in "Prod. Order Comp. Line No." field.
        ConsumpItemJournalLine.Validate("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");

        // [THEN] Item No. on the consumption journal line is now "C".
        ConsumpItemJournalLine.TestField("Item No.", CompItem."No.");
    end;

    [Test]
    procedure ProdOrderCompLineNotResetOnValidateItemNo()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ConsumpItemJournalTemplate: Record "Item Journal Template";
        ConsumpItemJournalBatch: Record "Item Journal Batch";
        ConsumpItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Consumption] [Prod. Order Component] [UT]
        // [SCENARIO 390313] "Prod. Order Comp Line No." field is not reset when validating Item No. which several prod. order components have.
        Initialize();

        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Production Order with component "C"
        CreateProductionItem(ProdItem, CompItem);
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ProdItem."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Add one more Prod. Order Component, item no. = "C".
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        ProdOrderComponent.Validate("Item No.", CompItem."No.");
        ProdOrderComponent.Modify(true);

        // [GIVEN] Open consumption journal and select the Production Order No.
        LibraryInventory.SelectItemJournalTemplateName(
          ConsumpItemJournalTemplate, ConsumpItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ConsumpItemJournalBatch, ConsumpItemJournalTemplate.Type, ConsumpItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ConsumpItemJournalLine, ConsumpItemJournalBatch, ConsumpItemJournalTemplate.Name, ConsumpItemJournalBatch.Name,
          ConsumpItemJournalLine."Entry Type"::Consumption);
        ConsumpItemJournalLine.Validate("Order No.", ProductionOrder."No.");

        // [GIVEN] Select the second prod. order component line no. in "Prod. Order Comp. Line No." field.
        ConsumpItemJournalLine.Validate("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");

        // [WHEN] Validate Item No. = "C" on the consumption journal line.
        ConsumpItemJournalLine.Validate("Item No.", CompItem."No.");

        // [THEN] "Prod. Order Comp Line No." remains unchanged.
        ConsumpItemJournalLine.TestField("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
    end;

    [Test]
    procedure ProdOrderCompLineNoChangesOnValidateDifferentItemNo()
    var
        ProdItem: Record Item;
        CompItem: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ConsumpItemJournalTemplate: Record "Item Journal Template";
        ConsumpItemJournalBatch: Record "Item Journal Batch";
        ConsumpItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Consumption] [Prod. Order Component] [UT]
        // [SCENARIO 390313] "Prod. Order Comp Line No." field is changed when validating Item No. related to another prod. order component.
        Initialize();

        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Production Order with component "C"
        CreateProductionItem(ProdItem, CompItem[1]);
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ProdItem."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem[1]."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Add one more Prod. Order Component, item no. = "D".
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        ProdOrderComponent.Validate("Item No.", CompItem[2]."No.");
        ProdOrderComponent.Modify(true);

        // [GIVEN] Open consumption journal and select the Production Order No.
        LibraryInventory.SelectItemJournalTemplateName(
          ConsumpItemJournalTemplate, ConsumpItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ConsumpItemJournalBatch, ConsumpItemJournalTemplate.Type, ConsumpItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ConsumpItemJournalLine, ConsumpItemJournalBatch, ConsumpItemJournalTemplate.Name, ConsumpItemJournalBatch.Name,
          ConsumpItemJournalLine."Entry Type"::Consumption);
        ConsumpItemJournalLine.Validate("Order No.", ProductionOrder."No.");

        // [GIVEN] Select the prod. order component line no. for item "D" in "Prod. Order Comp. Line No." field.
        ConsumpItemJournalLine.Validate("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");

        // [WHEN] Validate Item No. = "C" on the consumption journal line.
        ConsumpItemJournalLine.Validate("Item No.", CompItem[1]."No.");

        // [THEN] "Prod. Order Comp Line No." is changed to the one for "C".
        ProdOrderComponent.SetRange("Item No.", CompItem[1]."No.");
        ProdOrderComponent.FindFirst();
        ConsumpItemJournalLine.TestField("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PostingTwoLinesOfSameItemButDifferentUOMDoesNotThrowError()
    var
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure1: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine1: Record "Prod. Order Line";
        ProductionOrderLine2: Record "Prod. Order Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        Initialize();

        // Add yourselves as Warehouse Employee to location L1
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"Inventory Put-away");
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // Create an item I1 and add two Unit of Measures UOM1 and UOM2.
        CreateItem(Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Order");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure1, Item."No.", 1);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure2, Item."No.", 1);
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure1.Code);
        Item.Modify(true);

        // Create released prod order, add 2 lines:
        // Item I1, Location L1, 1 UOM1
        // Item I1, Location L1, 1 UOM2
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 1);

        LibraryManufacturing.CreateProdOrderLine(ProductionOrderLine1, ProductionOrderLine1.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, 1);
        LibraryManufacturing.CreateProdOrderLine(ProductionOrderLine2, ProductionOrderLine1.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, 1);
        ProductionOrderLine2.Validate("Unit of Measure Code", ItemUnitOfMeasure2.Code);
        ProductionOrderLine2.Modify(true);

        // Create  Inbound Whse. Request
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);

        // Create Inventory Put-away
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        LibraryWarehouse.FindWhseActivityBySourceDoc(
                  WarehouseActivityHeader, DATABASE::"Prod. Order Line", ProductionOrder.Status.AsInteger(), ProductionOrder."No.",
                  ProductionOrderLine1."Line No.");

        // Set Qty to Handle as 1 for both lines and choose Post.
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);
    end;

    [Test]
    [HandlerFunctions('PostProdJnlWithConsume0PageHandler,ConfirmHandlerYes,MessageHandler')]
    procedure BOMFixedQtyCalcConsumptionAfterPostProdJnl()
    var
        ComponentItem: Record Item;
        ProductItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ConsumptionJournalLine: Record "Item Journal Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
        CalcBasedOn: Option "Actual Output","Expected Output";
    begin
        // [SCENARIO 317277] Fixed Quantity calculation formula is used for calculating consumption in consumption journal after posting production journal.
        // [GIVEN] Component item, product item, Production BOM
        Initialize();
        LibraryInventory.CreateItem(ComponentItem);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", LibraryRandom.RandIntInRange(51, 100));
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify();
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        LibraryInventory.CreateItem(ProductItem);
        ProductItem.Validate("Replenishment System", ProductItem."Replenishment System"::"Prod. Order");
        ProductItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductItem.Modify();

        // [WHEN] Create released production order and refresh.
        CreateAndRefreshReleasedProductionOrderAtLocation(ProdOrder, ProductItem."No.", LibraryRandom.RandIntInRange(51, 100), '');

        // [WHEN] Create Production Journal from released production order line and update quantities
        // [WHEN] Post Production Journal
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.FindFirst();
        ProductionJournalMgt.Handling(ProdOrder, ProdOrderLine."Line No.");
        // Update and Post in ModalPageHandler PostProdJnlWithConsume0PageHandler

        // [WHEN] Calculate consumption in consumption journal
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption);
        ConsumptionJnlCalcConsumption(ItemJournalBatch, CalcBasedOn::"Actual Output");

        // [THEN]  New Item Journal Line for Component Item quantity = Production BOM Line Quantity Per.
        FindLastJournalLine(ConsumptionJournalLine, ItemJournalBatch);
        Assert.AreEqual(ComponentItem."No.", ConsumptionJournalLine."Item No.", BOMFixedQtyCalcFormulaErr);
        Assert.AreEqual(ProductionBOMLine."Quantity per", ConsumptionJournalLine.Quantity, BOMFixedQtyCalcFormulaErr);
    end;

    [Test]
    [HandlerFunctions('PostProdJnlPageHandler,ConfirmHandlerYes,MessageHandler')]
    procedure BOMFixedQtyPostRelProdOrderWithBackFlushing()
    var
        ComponentItem: Record Item;
        ProductItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ProdOrderComp: Record "Prod. Order Component";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderComponentsTestPage: TestPage "Prod. Order Components";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // [SCENARIO 317277] Fixed Quantity calculation formula is used for calculating with BackFlushing and changing the status to Finished.
        // [GIVEN] Component item, positive adjustment with qty 10 for Component,  product item, Production BOM
        Initialize();
        LibraryInventory.CreateItem(ComponentItem);
        CreateAndPostItemJournal(ItemJournalLine."Entry Type"::"Positive Adjmt.", ComponentItem."No.", LibraryRandom.RandIntInRange(101, 1000));

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", LibraryRandom.RandIntInRange(51, 100));
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify();
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        LibraryInventory.CreateItem(ProductItem);
        ProductItem.Validate("Replenishment System", ProductItem."Replenishment System"::"Prod. Order");
        ProductItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductItem.Modify();

        // [WHEN] Create released production order and refresh.
        CreateAndRefreshReleasedProductionOrderAtLocation(ProdOrder, ProductItem."No.", LibraryRandom.RandIntInRange(11, 50), '');

        // [WHEN] Set flushing to Backward in Components page for the production line.
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponentsTestPage.Trap();
        PAGE.Run(PAGE::"Prod. Order Components", ProdOrderComp);
        ProdOrderComponentsTestPage."Flushing Method".SetValue(ProdOrderComp."Flushing Method"::Backward);
        ProdOrderComponentsTestPage.Close();

        // [WHEN] Create Production Journal from released production order line and update quantities
        // [WHEN] Post Production Journal
        ProductionJournalMgt.Handling(ProdOrder, ProdOrderLine."Line No.");
        // Update and Post in ModalPageHandler PostProdJnlPageHandler

        // [WHEN] Change Production Order Status to Finished
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrder."No.");

        // [THEN]  New Item Ledger Entry for Component Item quantity = - Production BOM Line Quantity Per.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Item No.", ComponentItem."No.");
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(ProductionBOMLine."Quantity per", -ItemLedgerEntry.Quantity, BOMFixedQtyCalcFormulaErr);
    end;

    local procedure FindLastJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.FindLast();
    end;

    local procedure ConsumptionJnlCalcConsumption(ItemJournalBatch: Record "Item Journal Batch"; CalcBasedOn: Option "Actual Output","Expected Output")
    var
        CalcConsumption: Report "Calc. Consumption";
    begin
        Commit();
        CalcConsumption.InitializeRequest(WorkDate(), CalcBasedOn);
        CalcConsumption.SetTemplateAndBatchName(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();
    end;

    [Test]
    procedure DoNotClearBinCodeOnChangeVariantCodeInOutputJournal()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Output] [Item Variant] [Bin]
        // [SCENARIO 431468] Keep bin code on changing variant code in output journal.
        Initialize();

        // [GIVEN] Location with bin "B".
        // [GIVEN] Set up bin "B" as a default bin for output.
        CreateLocationWithNumberOfBins(Location, 1);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        Location.Validate("From-Production Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Item with variant "V".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Released production order at the location, refresh.
        // [GIVEN] Update Variant Code = "V" on the prod. order line.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.", Item."No.");
        ProdOrderLine.Validate("Variant Code", ItemVariant.Code);
        ProdOrderLine.Modify(true);

        // [WHEN] Create output journal, select production order no. and item no.
        InitOutputJournalLine(ItemJournalLine, ProductionOrder."No.", Item."No.");

        // [THEN] Item variant = "V", bin code = "B" on the output journal line.
        ItemJournalLine.TestField("Variant Code", ItemVariant.Code);
        ItemJournalLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDescriptionAndDescription2OnProdOrderWithItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO 479958] Description/Description 2 are not updated when user selects variant code: Prod Order Header
        Initialize();

        // [GIVEN] Create Item with Item Variant.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant."Description 2" := LibraryUtility.GenerateRandomText(20);
        ItemVariant.Modify(true);

        // [THEN] Production Order with Item Variant
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            Item."No.",
            LibraryRandom.RandDec(10, 2));

        ProductionOrder.Validate("Variant Code", ItemVariant.Code);
        ProductionOrder.Modify(true);

        // [VERIFY] Verify: Description/Description 2 of "Production Order" should be equal to "Item Variant" Description/Description 2
        Assert.AreEqual(ItemVariant.Description, ProductionOrder.Description, DescriptionMustBeSame);
        Assert.AreEqual(ItemVariant."Description 2", ProductionOrder."Description 2", DescriptionMustBeSame);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVariantCodeClearedWhenSelectingNewItemOnReleasedProductionOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ProdOrderNo: Code[20];
    begin
        // [SCENARIO 479957] When user select item, previously selected variant code is no cleared: assembly header, prod order header
        Initialize();

        // [GIVEN] Create Item with Item Variant and also add Description 2 on Item Variant
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [THEN] Production Order with Item Variant
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            Item."No.",
            LibraryRandom.RandDec(10, 2));

        ProductionOrder.Validate("Variant Code", ItemVariant.Code);
        ProductionOrder.Modify(true);

        // [WHEN] Open Released Production Order Page and change Item to I2
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Source No.".SetValue(Item2."No.");
        ProdOrderNo := Format(ReleasedProductionOrder."No.");
        ReleasedProductionOrder.Close();

        // [VERIFY] Verify: Changing Item No. on "Released Production Order" should be cleared the "Variant Code" field value
        ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderNo);
        Assert.AreEqual('', ProductionOrder."Variant Code", StrSubstNo(FieldMustBeEmptyErr, ProductionOrder.FieldCaption("Variant Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemProductionBlockedOutputCannotBePostThroughOutputJournal()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        OperationNo: Code[10];
        ItemNo: Code[20];
    begin
        // [SCENARIO 382546] Verify Output Journal cannot be post If "Production Blocked" is Output on "Item".
        Initialize();

        // [GIVEN] Create Work Center.
        CreateWorkCenter(WorkCenter);
        WorkCenter."Subcontractor No." := '';
        WorkCenter.Modify();

        // [GIVEN] Create Routing Setup.
        OperationNo := CreateRoutingSetup(RoutingHeader, WorkCenter);

        // [GIVEN] Create Item with Routing.
        ItemNo := CreateItemWithRouting(RoutingHeader."No.");

        // [GIVEN] Create Released production order.
        CreateAndRefreshReleasedProductionOrderWithVariantCode(ProductionOrder, ItemNo, LibraryRandom.RandInt(10), '');

        // [GIVEN] Update "Production Blocked" to Output on Item.
        Item.Get(ItemNo);
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Create and Post Output Journal with "Production Blocked" on Item.
        asserterror CreateAndPostOutputJournal(ProductionOrder."No.", OperationNo, ItemNo, '', '');

        // [VERIFY] Verify Output Journal cannot be post if "Production Blocked" is Output on "Item".
        Assert.ExpectedError(StrSubstNo(ProductionBlockedOutputItemErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Production Blocked"), Item."Production Blocked"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantProductionBlockedOutputCannotBePostThroughOutputJournal()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        OperationNo: Code[10];
        ItemNo: Code[20];
    begin
        // [SCENARIO 382546] Verify Output Journal cannot be post if "Production Blocked" is Output on "Item Variant".
        Initialize();

        // [GIVEN] Create Work Center.
        CreateWorkCenter(WorkCenter);
        WorkCenter."Subcontractor No." := '';
        WorkCenter.Modify();

        // [GIVEN] Create Routing Setup.
        OperationNo := CreateRoutingSetup(RoutingHeader, WorkCenter);

        // [GIVEN] Create Item with Routing.
        ItemNo := CreateItemWithRouting(RoutingHeader."No.");

        // [GIVEN] Create Item with Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        ItemVariant.Modify(true);

        // [GIVEN] Create Released production order.
        CreateAndRefreshReleasedProductionOrderWithVariantCode(ProductionOrder, ItemNo, 1, ItemVariant.Code);

        // [GIVEN] Update "Production Blocked" to Output on "Item Variant".
        ItemVariant.Validate("Production Blocked", ItemVariant."Production Blocked"::Output);
        ItemVariant.Modify(true);

        // [GIVEN] Select Item Journal Template and Batch.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);

        // [GIVEN] Clear Item Journal.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [GIVEN] Create Output Journal line with Variant Code.
        InitOutputJournalLine(ItemJournalLine, ProductionOrder."No.", ItemNo);
        ItemJournalLine.Validate("Output Quantity", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Modify(true);

        // [WHEN] Post Output Journal with "Production Blocked" on "Item Variant".
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [VERIFY] Verify Output Journal cannot be post if "Production Blocked" is Output on "Item Variant".
        Assert.ExpectedError(StrSubstNo(ProductionBlockedOutputItemVariantErr, ItemVariant.Code, Item.TableCaption(), ItemVariant."Item No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemProductionBlockedOutputCannotbeSelectedOnProductionOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO 382546] Verify Item cannot be selected on Production Order if "Production Blocked" is Output on "Item".
        Initialize();

        // [GIVEN] Create and Update "Production Blocked" to Output on Item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Create Released production order.
        asserterror CreateAndRefreshReleasedProductionOrderWithVariantCode(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '');

        // [VERIFY] Verify expected error message when Item is selected on Production Order if "Production Blocked" is Output on "Item".
        Assert.ExpectedError(StrSubstNo(ProductionItemNotFoundErr, ProductionOrder.FieldCaption("Source No."), ProductionOrder.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantProductionBlockedOutputCannotbeSelectedOnProductionOrder()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO 382546] Verify Variant Code cannot be selected on Production Order if "Production Blocked" is Output on "Item Variant".
        Initialize();

        // [GIVEN] Create Item with Item Variant.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Validate("Production Blocked", ItemVariant."Production Blocked"::Output);
        ItemVariant.Modify(true);

        // [WHEN] Create Released production order.
        asserterror CreateAndRefreshReleasedProductionOrderWithVariantCode(ProductionOrder, Item."No.", 1, ItemVariant.Code);

        // [VERIFY] Verify expected error message when Variant Code is selected on Production Order if "Production Blocked" is Output on "Item".
        Assert.ExpectedError(StrSubstNo(ProductionItemNotFoundErr, ProductionOrder.FieldCaption("Variant Code"), ProductionOrder.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemProductionBlockedOutputCannotbeSelectedOnProductionOrderLine()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 382546] Verify Item cannot be selected on Production Order Line if "Production Blocked" is Output on "Item".
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Released production order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Update "Production Blocked" on Item.
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Refresh Production Order.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [VERIFY] Verify expected error message when Item is selected on Production Order Line if "Production Blocked" is Output on "Item".
        Assert.ExpectedError(StrSubstNo(ProductionItemNotFoundErr, ProductionOrderLine.FieldCaption("Item No."), ProductionOrderLine.TableCaption(), Item."No.", Item.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantProductionBlockedOutputCannotbeSelectedOnProductionOrderLine()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 382546] Verify Variant Code cannot be selected on Production Order Line if "Production Blocked" is Output on "Item Variant".
        Initialize();

        // [GIVEN] Create Item with Item Variant.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [WHEN] Create Released production order with Variant Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Variant Code", ItemVariant.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Update "Production Blocked" on "Item Variant".
        ItemVariant.Validate("Production Blocked", ItemVariant."Production Blocked"::Output);
        ItemVariant.Modify(true);

        // [WHEN] Refresh Production Order.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [VERIFY] Verify expected error message when Variant Code is selected on Production Order Line if "Production Blocked" is Output on "Item".
        Assert.ExpectedError(StrSubstNo(ProductionItemNotFoundErr, ProductionOrderLine.FieldCaption("Variant Code"), ProductionOrderLine.TableCaption(), ItemVariant.Code, ItemVariant.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProductionOrderCannotBeRunIfProductionBlockedOutputOnItem()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        Direction: Option Forward,Backward;
        CalcMethod: Option "All Levels";
    begin
        // [SCENARIO 382546] Verify "Replan Production Order" cannot be executed if "Production Blocked" is Output on "Item".
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Released production order.
        CreateAndRefreshReleasedProductionOrderWithVariantCode(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '');

        // [GIVEN] Update "Production Blocked" on Item.
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Run Replan Production Order.
        asserterror LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All Levels");

        // [VERIFY] Verify expected error message when Item is selected on Production Order if "Production Blocked" is Output on "Item".
        Assert.ExpectedError(StrSubstNo(ProductionBlockedOutputItemErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Production Blocked"), Item."Production Blocked"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProductionOrderCannotBeRunIfProductionBlockedOutputOnItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        Direction: Option Forward,Backward;
        CalcMethod: Option "All Levels";
    begin
        // [SCENARIO 382546] Verify "Replan Production Order" cannot be executed if "Production Blocked" is Output on "Item Variant".
        Initialize();

        // [GIVEN] Create Item with Item Variant.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Released production order.
        CreateAndRefreshReleasedProductionOrderWithVariantCode(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), ItemVariant.Code);

        // [GIVEN] Update "Production Blocked" on "Item Variant".
        ItemVariant.Validate("Production Blocked", ItemVariant."Production Blocked"::Output);
        ItemVariant.Modify(true);

        // [WHEN] Run Replan Production Order.
        asserterror LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All Levels");

        // [VERIFY] Verify expected error message when "Replan Production Order" is executed if "Production Blocked" is Output on "Item Variant".
        Assert.ExpectedError(StrSubstNo(ProductionBlockedOutputItemVariantErr, ItemVariant.Code, Item.TableCaption(), ItemVariant."Item No."));
    end;

    [Test]
    [HandlerFunctions('JournalPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionJournalRespectsMfgSetupCalcBasedOn()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
        OldCalcBasedOn: Option;
    begin
        // [FEATURE] [Manufacturing Setup] [Default Consumption Calculation Based on]
        // [SCENARIO] Production Journal respects the Default Consumption Calculation Based on setting in Manufacturing Setup

        // [GIVEN] Manufacturing Setup with Default Consumption Calculation Based on = Actual Output
        Initialize();
        ManufacturingSetup.Get();
        OldCalcBasedOn := ManufacturingSetup."Default Consum. Calc. Based on";
        ManufacturingSetup."Default Consum. Calc. Based on" := ManufacturingSetup."Default Consum. Calc. Based on"::"Actual Output";
        ManufacturingSetup.Modify();

        // [GIVEN] Items and Released Production Order Setup
        CreateItemsWithInventory(
          ChildItemNo, ChildItemNo2, Item."Manufacturing Policy"::"Make-to-Stock", Item."Manufacturing Policy"::"Make-to-Order");
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo2, 1);
        CreateRoutingSetup(RoutingHeader);
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.");
        ProductionOrderNo := ProductionOrder."No.";
         
        // [WHEN] Open Production Journal based on Production Order Lines
        OpenProductionJournal(ProductionOrder, ProductionOrderNo);
         
        // [THEN] Verification done in VerifyConsumptionEntriesBasedOnActualOutput after JournalPageHandler captures journal lines
        VerifyConsumptionEntriesBasedOnActualOutput(ProductionOrderNo);

        // Clean up
        ManufacturingSetup."Default Consum. Calc. Based on" := OldCalcBasedOn;
        ManufacturingSetup.Modify();
    end;

    [Test]
    [HandlerFunctions('JournalPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionJournalWithPostedOutputRespectsMfgSetupCalcBasedOn()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
        OldCalcBasedOn: Option;
        OperationNo: Code[10];
    begin
        // [FEATURE] [Manufacturing Setup] [Default Consumption Calculation Based on]
        // [SCENARIO] Production Journal respects the Default Consumption Calculation Based on setting in Manufacturing Setup after posting output

        // [GIVEN] Manufacturing Setup with Default Consumption Calculation Based on = Actual Output
        Initialize();
        ManufacturingSetup.Get();
        OldCalcBasedOn := ManufacturingSetup."Default Consum. Calc. Based on";
        ManufacturingSetup."Default Consum. Calc. Based on" := ManufacturingSetup."Default Consum. Calc. Based on"::"Actual Output";
        ManufacturingSetup.Modify();

        // [GIVEN] Items and Released Production Order Setup
        CreateItemsWithInventory(
          ChildItemNo, ChildItemNo2, Item."Manufacturing Policy"::"Make-to-Stock", Item."Manufacturing Policy"::"Make-to-Order");
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo2, 1);
        OperationNo := CreateRoutingSetup(RoutingHeader);
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.");
        ProductionOrderNo := ProductionOrder."No.";
         
        // [GIVEN] Post output in Production Journal
        CreateAndPostOutputJournal(ProductionOrderNo, OperationNo, Item."No.", '', '');
         
        // [WHEN] Open Production Journal based on Production Order Lines
        OpenProductionJournal(ProductionOrder, ProductionOrderNo);
         
        // [THEN] Verification done in VerifyConsumptionEntriesBasedOnActualOutput after JournalPageHandler captures journal lines
        VerifyConsumptionEntriesBasedOnActualOutput(ProductionOrderNo);

        // Clean up
        ManufacturingSetup."Default Consum. Calc. Based on" := OldCalcBasedOn;
        ManufacturingSetup.Modify();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Production Journal");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Production Journal");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        UpdateSalesReceivablesSetup();
        ItemJournalSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Production Journal");
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup()
    begin
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ItemManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        // Random value important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, CostingMethod, LibraryRandom.RandInt(50) + 10, Item."Reordering Policy",
          Item."Flushing Method", RoutingNo, ProductionBOMNo);
        Item.Validate("Manufacturing Policy", ItemManufacturingPolicy);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CreateBinMandatoryProductionLocation(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Location.Validate("From-Production Bin Code", Bin.Code);
        Location.Modify(true);
    end;

    local procedure CreateItemWithRouting(RoutingNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndRefreshReleasedProductionOrderAtLocation(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshReleasedProdOrderWithNewItemAndRouting(var ProductionOrder: Record "Production Order"; var OperationNo: Code[10])
    var
        RoutingHeader: Record "Routing Header";
        ItemNo: Code[20];
    begin
        OperationNo := CreateRoutingSetup(RoutingHeader);
        ItemNo := CreateItemWithRouting(RoutingHeader."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ItemNo);
    end;

    local procedure CreateAndRefreshReleasedProdOrderWithNewItemAndRouting(var ProductionOrder: Record "Production Order"; var OperationNo: Code[10]; WorkCenter: Record "Work Center")
    var
        RoutingHeader: Record "Routing Header";
        ItemNo: Code[20];
    begin
        OperationNo := CreateRoutingSetup(RoutingHeader, WorkCenter);
        ItemNo := CreateItemWithRouting(RoutingHeader."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ItemNo);
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20]; OperationNo: Code[10]; ParentItemNo: Code[20]; LocationCode: Code[10]; FromProductionBinCode: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        ItemJournalTemplate.Validate(Type, ItemJournalTemplate.Type::"Prod. Order");
        ItemJournalTemplate.Modify(true);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindFirst();

        CreateOutputJournalLine(
          ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ParentItemNo, LocationCode, FromProductionBinCode,
          ProductionOrderNo, ProdOrderLine."Line No.", OperationNo, true, ProdOrderLine.Quantity);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure CreateOutputJournalLine(TemplateName: Code[10]; BatchName: Code[10]; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; ProductionOrderNo: Code[20]; ProductionOrderLineNo: Integer; OperationNo: Code[10]; Finished: Boolean; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, TemplateName, BatchName, ItemJournalLine."Entry Type"::Output, ItemNo, 0);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProductionOrderNo);
        ItemJournalLine.Validate("Order Line No.", ProductionOrderLineNo);
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Validate(Finished, Finished);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateInvtPutAwayAtLocation(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record "Production Order"; LocationCode: Code[10]; QtyToHandle: Decimal)
    var
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);
        WarehouseRequest.SetRange("Location Code", LocationCode);
        WarehouseRequest.FindFirst();
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, true, false, false);
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header") OperationNo: Code[10]
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        OperationNo := RoutingLine."Operation No.";
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header"; WorkCenter: Record "Work Center") OperationNo: Code[10]
    var
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        OperationNo := RoutingLine."Operation No.";
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        // Random value important for test.
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(105, 1));
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateRoutingLineSetNextOperation(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; OperationNo: Code[10]; NextOperationNo: Code[30])
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Modify(true);
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure CreateProductionItem(var ParentItem: Record Item; ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", LibraryRandom.RandInt(10));
        LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);
    end;

    local procedure CreateProdItem(var Item: Record Item; RoutingNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
    begin
        // Create Child Items.
        CreateItemsWithInventory(
          ChildItemNo, ChildItemNo2, Item."Manufacturing Policy"::"Make-to-Stock", Item."Manufacturing Policy"::"Make-to-Stock");

        // Create Production BOM.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo2, 1);  // Value important.

        // Create parent Item and attach Routing and Production BOM.
        CreateItem(Item, Item."Costing Method"::FIFO, RoutingNo, ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order");
    end;

    local procedure CreateItemsWithInventory(var ChildItemNo: Code[20]; var ChildItemNo2: Code[20]; ItemManufacturingPolicy: Enum "Manufacturing Policy"; ItemManufacturingPolicy2: Enum "Manufacturing Policy")
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItem(Item, Item."Costing Method"::FIFO, '', '', ItemManufacturingPolicy);
        ChildItemNo := Item."No.";
        Clear(Item);
        CreateItem(Item, Item."Costing Method"::FIFO, '', '', ItemManufacturingPolicy2);
        ChildItemNo2 := Item."No.";

        // Update Inventory for Item, random value important for test.
        CreateAndPostItemJournal(ItemJournalLine."Entry Type"::"Positive Adjmt.", ChildItemNo, LibraryRandom.RandInt(100) + 10);
        CreateAndPostItemJournal(ItemJournalLine."Entry Type"::"Positive Adjmt.", ChildItemNo2, LibraryRandom.RandInt(100) + 10);
    end;

    local procedure CreateLocationWithNumberOfBins(var Location: Record Location; NoOfBins: Integer)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Bin Mandatory" := true;
        Location.Modify(true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NoOfBins, false);
    end;

    local procedure CreateItemJournal(var ItemJournalLine: Record "Item Journal Line"; var ItemJournalBatch: Record "Item Journal Batch")
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name,
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateProductionItemJournal(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; OrderNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateItemJournal(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Entry Type", EntryType);
        ItemJournalLine.Validate("Order No.", OrderNo);
    end;

    local procedure CreateAndPostItemJournal(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        ClearJournal(ItemJournalBatch);  // Clear Item Journal Template and Journal Batch.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure ClearJournal(ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure InitOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProdOrderNo);
    end;

    local procedure SelectProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindSet();
    end;

    local procedure CreateAndRefreshRelProdOrder(var ProductionOrder: Record "Production Order"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, SourceType, SourceNo, 1);  // Value important.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateReleasedProdOrderWithTwoLines(var ParentProdOrderLine: Record "Prod. Order Line"; var ChildProdOrderLine: Record "Prod. Order Line")
    var
        Location: Record Location;
        ComponentItem: Record Item;
        ManufChildItem: Record Item;
        ManufParentItem: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        LibraryInventory.CreateItem(ComponentItem);
        CreateProductionItem(ManufChildItem, ComponentItem);
        CreateProductionItem(ManufParentItem, ManufChildItem);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ManufParentItem."No.",
          LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        FindProdOrderLine(ParentProdOrderLine, ProductionOrder."No.", ManufParentItem."No.");
        FindProdOrderLine(ChildProdOrderLine, ProductionOrder."No.", ManufChildItem."No.");
    end;

    local procedure CreateFamily(var Family: Record Family; RoutingNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        FamilyLine: Record "Family Line";
    begin
        // Random values not important for test.
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingNo);
        Family.Modify(true);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo, LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo2, LibraryRandom.RandInt(5));
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, 1, '', 0D);  // Value important.
    end;

    local procedure OpenProductionJournal(ProductionOrder: Record "Production Order"; ProdOrderNo: Code[20]): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // Open Production Journal based on selected Production Order Line.
        SelectProdOrderLine(ProdOrderLine, ProdOrderNo);
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
        exit(ProdOrderLine."Line No.");
    end;

    local procedure ProductionJournalPostLines(ProductionOrder: Record "Production Order"; ProdOrderNo: Code[20])
    var
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
        ProdOrderLineNo: Integer;
    begin
        // Boolean - PostedProdJournal, signifies if the Production Journal Lines have been posted when opening the Production Journal page.
        PostedProdJournal := false;
        ProdOrderLineNo := OpenProductionJournal(ProductionOrder, ProdOrderNo);

        // Need to re-open the Production Journal page and copy the entries to temporary record needed for verification.
        PostedProdJournal := true;
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLineNo);
    end;

    local procedure CreateDimRelProdOrderSetup(var ProductionOrder: Record "Production Order"; var DefaultDimension: Record "Default Dimension"; var DefaultDimension2: Record "Default Dimension"): Integer
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // Random value important for test.
        CreateItemWithDimension(DefaultDimension);
        CreateItemWithDimension(DefaultDimension2);
        CreateAndPostItemJournal(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", DefaultDimension."No.", LibraryRandom.RandInt(100) + 10);
        CreateAndPostItemJournal(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", DefaultDimension2."No.", LibraryRandom.RandInt(100) + 10);

        // Create Production BOM. Create Released Production Order.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, DefaultDimension."No.", DefaultDimension2."No.", 1);  // Value important.

        CreateItem(Item, Item."Costing Method"::FIFO, '', ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order");
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.");
        exit(UpdateProductionOrderDimension(ProductionOrder."No."));
    end;

    local procedure CreateItemWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Item: Record Item;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateProdOrderRoutingLine(var NewProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrder: Record "Production Order"; RoutingReferenceNo: Integer; RoutingNo: Code[20]; NewOperationNo: Code[10]; WorkCenterNo: Code[20])
    begin
        NewProdOrderRoutingLine.Init();
        NewProdOrderRoutingLine.Validate(Status, ProductionOrder.Status);
        NewProdOrderRoutingLine.Validate("Prod. Order No.", ProductionOrder."No.");
        NewProdOrderRoutingLine.Validate("Routing Reference No.", RoutingReferenceNo);
        NewProdOrderRoutingLine.Validate("Routing No.", RoutingNo);
        NewProdOrderRoutingLine.Validate("Operation No.", NewOperationNo);
        NewProdOrderRoutingLine.Insert(true);
        NewProdOrderRoutingLine.Validate(Type, NewProdOrderRoutingLine.Type::"Work Center");
        NewProdOrderRoutingLine.Validate("No.", WorkCenterNo);
        NewProdOrderRoutingLine.Modify(true);
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; OperationNo: Code[10])
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderStatus);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure MockProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Init();
        ProductionOrder.Status := ProductionOrder.Status::Released;
        ProductionOrder."No." := LibraryUtility.GenerateRandomCode(ProductionOrder.FieldNo("No."), DATABASE::"Production Order");
        ProductionOrder.Insert();

        ProdOrderLine.Init();
        ProdOrderLine.Status := ProductionOrder.Status;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := LibraryUtility.GetNewRecNo(ProdOrderLine, ProdOrderLine.FieldNo("Line No."));
        ProdOrderLine.Insert();
    end;

    local procedure UpdateNextOperationOnProdOrderRoutingLine(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; OperationNo: Code[10]; NextOperationNo: Code[30])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderStatus);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.FindFirst();

        ProdOrderRoutingLine.Validate("Next Operation No.", NextOperationNo);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure UpdateProdOrderRoutingLineStatus(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; OperationNo: Code[10]; NewRoutingStatus: Enum "Prod. Order Routing Status")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderStatus, ProdOrderNo, OperationNo);
        ProdOrderRoutingLine.Validate("Routing Status", NewRoutingStatus);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure UpdateProductionOrderDimension(ProdOrderNo: Code[20]) NewDimensionSetID: Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        SelectProdOrderLine(ProdOrderLine, ProdOrderNo);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        NewDimensionSetID := LibraryDimension.CreateDimSet(ProdOrderLine."Dimension Set ID", Dimension.Code, DimensionValue.Code);
        ProdOrderLine.Validate("Dimension Set ID", NewDimensionSetID);
        ProdOrderLine.Modify(true);
    end;

    local procedure SelectProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindSet();
    end;

    local procedure SelectConsumptionJournal(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20])
    begin
        ItemJournalLine.SetRange("Order No.", ProdOrderNo);
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.SetRange("Item No.", ReserveItemNo);
        ItemJournalLine.FindSet();
    end;

    local procedure CopyProductionJournalToTemp(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20])
    begin
        TempItemJournalLine.DeleteAll();
        ItemJournalLine.SetRange("Order No.", ProdOrderNo);
        ItemJournalLine.FindSet();
        repeat
            TempItemJournalLine := ItemJournalLine;
            if TempItemJournalLine.Insert() then;
        until ItemJournalLine.Next() = 0;
    end;

    local procedure CopyProdJournalAndDimToTemp(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Copy Dimension Set Entry record to temporary record because record not available when out of Production Journal Handler.
        TempItemJournalLine2.DeleteAll();
        TempDimensionSetEntry.DeleteAll();
        ItemJournalLine.SetRange("Order No.", ProdOrderNo);
        ItemJournalLine.FindSet();
        repeat
            TempItemJournalLine2 := ItemJournalLine;
            TempItemJournalLine2.Insert();
            LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, ItemJournalLine."Dimension Set ID");
            repeat
                TempDimensionSetEntry := DimensionSetEntry;
                if TempDimensionSetEntry.Insert() then;
            until DimensionSetEntry.Next() = 0;
        until ItemJournalLine.Next() = 0;
    end;

    local procedure CopyLocation(var NewLocCode: Code[10]; ExistingLocCode: Code[10]; ExistingBinCode: Code[20])
    var
        NewLocation: Record Location;
        NewBin: Record Bin;
        ExistingLocation: Record Location;
        ExistingBin: Record Bin;
    begin
        ExistingLocation.Get(ExistingLocCode);
        ExistingBin.Get(ExistingLocCode, ExistingBinCode);

        NewLocation.Init();
        NewLocation := ExistingLocation;
        NewLocation.Validate(Code, LibraryUtility.GenerateRandomCode(NewLocation.FieldNo(Code), DATABASE::Location));
        NewLocation.Insert(true);
        NewLocCode := NewLocation.Code;

        NewBin.Init();
        NewBin := ExistingBin;
        NewBin.Validate("Location Code", NewLocation.Code);
        NewBin.Insert(true);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProdOrderCompLine(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindFirst();
    end;

    local procedure UpdateBinCodeInItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; NewBinCode: Code[20])
    var
        SavedItemJournalLine: Record "Item Journal Line";
        WMSManagement: Codeunit "WMS Management";
    begin
        SavedItemJournalLine := ItemJournalLine;
        ItemJournalLine.Validate("Bin Code", NewBinCode);
        WMSManagement.CheckItemJnlLineFieldChange(ItemJournalLine, SavedItemJournalLine, ItemJournalLine.FieldCaption("Bin Code"));
    end;

    local procedure VerifyConsumptionEntries(ProdOrderNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
    begin
        SelectProdOrderComponent(ProdOrderComponent, ProdOrderNo);
        ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderNo);
        TempItemJournalLine.FindSet();
        repeat
            Assert.AreEqual(ProdOrderComponent."Quantity per" * ProductionOrder.Quantity, TempItemJournalLine.Quantity, ErrMsgQuantity);
            TempItemJournalLine.Next();
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure VerifyConsumpEntriesAfterPost()
    begin
        TempItemJournalLine.FindSet();
        repeat
            Assert.AreEqual(0, TempItemJournalLine.Quantity, ErrMsgQuantity);
        until TempItemJournalLine.Next() = 0;
    end;

    local procedure VerifyFamilyConsumptionEntries(ItemNo: Code[20]; ProdOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SelectProdOrderLine(ProdOrderLine, ProdOrderNo);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        SelectProdOrderComponent(ProdOrderComponent, ProdOrderNo);
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindSet();
        TempItemJournalLine.FindSet();
        repeat
            Assert.AreEqual(ProdOrderComponent."Quantity per" * ProdOrderLine.Quantity, TempItemJournalLine.Quantity, ErrMsgQuantity);
            TempItemJournalLine.Next();
            ProdOrderLine.Next();
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure VerifyOutputEntries(ProdOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderNo);
        TempItemJournalLine.SetRange("Entry Type", TempItemJournalLine."Entry Type"::Output);
        TempItemJournalLine.FindSet();
        repeat
            Assert.AreEqual(ProductionOrder.Quantity, TempItemJournalLine."Output Quantity", ErrMsgQuantity);
            Assert.AreEqual(0, TempItemJournalLine."Setup Time", StrSubstNo(ErrMsgTime, TempItemJournalLine.FieldCaption("Setup Time")));
            Assert.AreEqual(0, TempItemJournalLine."Run Time", StrSubstNo(ErrMsgTime, TempItemJournalLine.FieldCaption("Run Time")));
        until TempItemJournalLine.Next() = 0;
    end;

    local procedure VerifyOutputEntriesAfterPost()
    begin
        TempItemJournalLine.SetRange("Entry Type", TempItemJournalLine."Entry Type"::Output);
        TempItemJournalLine.FindSet();
        repeat
            Assert.AreEqual(0, TempItemJournalLine."Output Quantity", ErrMsgQuantity);
            Assert.AreEqual(0, TempItemJournalLine."Setup Time", StrSubstNo(ErrMsgTime, TempItemJournalLine.FieldCaption("Setup Time")));
            Assert.AreEqual(0, TempItemJournalLine."Run Time", StrSubstNo(ErrMsgTime, TempItemJournalLine.FieldCaption("Run Time")));
        until TempItemJournalLine.Next() = 0;
    end;

    local procedure VerifyFamilyOutputEntries(ItemNo: Code[20]; FamilyNo: Code[20])
    var
        FamilyLine: Record "Family Line";
    begin
        FamilyLine.SetRange("Family No.", FamilyNo);
        FamilyLine.SetRange("Item No.", ItemNo);
        FamilyLine.FindFirst();
        TempItemJournalLine.SetRange("Entry Type", TempItemJournalLine."Entry Type"::Output);
        TempItemJournalLine.FindSet();
        repeat
            Assert.AreEqual(FamilyLine.Quantity, TempItemJournalLine."Output Quantity", ErrMsgQuantity);
            Assert.AreEqual(0, TempItemJournalLine."Setup Time", StrSubstNo(ErrMsgTime, TempItemJournalLine.FieldCaption("Setup Time")));
            Assert.AreEqual(0, TempItemJournalLine."Run Time", StrSubstNo(ErrMsgTime, TempItemJournalLine.FieldCaption("Run Time")));
        until TempItemJournalLine.Next() = 0;
    end;

    local procedure VerifyDimensionSetEntry(DefaultDimension: Record "Default Dimension")
    begin
        TempDimensionSetEntry.SetRange("Dimension Set ID", TempItemJournalLine2."Dimension Set ID");
        TempDimensionSetEntry.SetRange("Dimension Code", DefaultDimension."Dimension Code");
        TempDimensionSetEntry.FindFirst();
        TempDimensionSetEntry.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyDimensionSetId(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        TempItemJournalLine2.SetRange("Item No.", ItemNo);
        TempItemJournalLine2.FindFirst();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.TestField("Dimension Set ID", TempItemJournalLine2."Dimension Set ID");
    end;

    local procedure VerifyProdOrderRtngLineNextPrevOperation(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; OperationNo: Code[10]; NextOperationNo: Code[30]; PrevOperationNo: Code[30])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderStatus, ProdOrderNo, OperationNo);
        ProdOrderRoutingLine.TestField("Next Operation No.", NextOperationNo);
        ProdOrderRoutingLine.TestField("Previous Operation No.", PrevOperationNo);
    end;

    local procedure CreateAndRefreshReleasedProductionOrderWithVariantCode(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Variant Code", VariantCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;



    local procedure VerifyConsumptionEntriesBasedOnActualOutput(ProdOrderNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        SelectProdOrderComponent(ProdOrderComponent, ProdOrderNo);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrderNo, ProdOrderComponent."Prod. Order Line No.");
        TempItemJournalLine.SetRange("Entry Type", TempItemJournalLine."Entry Type"::Consumption);
        TempItemJournalLine.FindSet();
        repeat
            Assert.AreEqual(ProdOrderComponent."Quantity per" * ProdOrderLine."Finished Quantity", TempItemJournalLine.Quantity, ErrMsgQuantity);
            TempItemJournalLine.Next();
        until ProdOrderComponent.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JournalReservePageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Generate Reserved Item Not On Inventory error.
        SelectConsumptionJournal(ItemJournalLine, ProductionOrderNo);
        asserterror CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JournalApplyPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Generate Apply To Entry With Reservation error.
        SelectConsumptionJournal(ItemJournalLine, ProductionOrderNo);
        ItemLedgerEntry.SetRange("Item No.", ReserveItemNo);
        ItemLedgerEntry.FindFirst();
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);
        asserterror CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JournalPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Copy Production Journal record to global temporary record.
        CopyProductionJournalToTemp(ItemJournalLine, ProductionOrderNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateJournalPostPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Copy Production Journal record to global temporary record.
        CopyProductionJournalToTemp(ItemJournalLine, ProductionOrderNo);

        // If the Production Journal already been posted then exit handler.
        if PostedProdJournal then
            exit;

        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate("Setup Time", LibraryRandom.RandInt(5));  // Random values not important.
            ItemJournalLine.Validate("Run Time", LibraryRandom.RandInt(5));
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;

        // Post Production Journal lines with modified Setup time, Run time.
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostJournalPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Copy Production Journal record to global temporary record.
        CopyProductionJournalToTemp(ItemJournalLine, ProductionOrderNo);

        // If the Production Journal already been posted then exit handler.
        if PostedProdJournal then
            exit;

        ItemJournalLine.FindSet();

        // Post Production Journal lines.
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JournalDimPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Copy Production Journal record to global temporary record.
        CopyProdJournalAndDimToTemp(ItemJournalLine, ProductionOrderNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostJournalDimPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Copy Production Journal record to global temporary record.
        CopyProdJournalAndDimToTemp(ItemJournalLine, ProductionOrderNo);

        // If the Production Journal already been posted then exit handler.
        if PostedProdJournal then
            exit;

        ItemJournalLine.FindSet();

        // Post Production Journal lines.
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProdJnlWithConsume0PageHandler(var ProductionJournal: TestPage "Production Journal")
    var
        ItemJnlEntryType: Enum "Item Ledger Entry Type";
    begin
        Assert.IsTrue(ProductionJournal.FindFirstField(ProductionJournal."Entry Type", ItemJnlEntryType::Consumption), '');
        ProductionJournal.Quantity.SetValue(0);
        Assert.IsTrue(ProductionJournal.FindNextField(ProductionJournal."Entry Type", ItemJnlEntryType::Output), '');
        ProductionJournal.Quantity.SetValue(LibraryRandom.RandInt(10));
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProdJnlPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderCompLineListPageHandler(var ProdOrderCompLineList: TestPage "Prod. Order Comp. Line List")
    begin
        Assert.AreEqual(
          LibraryVariableStorage.DequeueText(), ProdOrderCompLineList.FILTER.GetFilter("Prod. Order Line No."),
          WrongFilterOnProdOrderCompListErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Text: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerOptional(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}
