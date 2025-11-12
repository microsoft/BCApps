// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Document;
using System.TestLibraries.Utilities;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Journal;
using Microsoft.Sales.History;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.BOM;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Journal;
using Microsoft.Assembly.History;
using Microsoft.Sales.Document;
using Microsoft.Manufacturing.Document;
using Microsoft.Foundation.Navigate;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Assembly.Setup;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Foundation.NoSeries;
using Microsoft.Assembly.Comment;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Sales.Pricing;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Utilities;

codeunit 137101 "SCM Kitting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM]
    end;

    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        LocationBlack: Record Location;
        LocationRed: Record Location;
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryCostToGL: Codeunit "Library - Post Inventory To GL";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPlanning: Codeunit "Library - Planning";
        isInitialized: Boolean;
        ItemNotBOMError: Label 'Item %1 is not a BOM.';
        ItemNotOnInventoryError: Label 'You have insufficient quantity of Item %1 on inventory.';
        OrderCanNotCreatedError: Label 'Order %1 cannot be created, because it already exists or has been posted.';
        ResetAssemblyLines: Label 'This assembly order may have customized lines. Are you sure that you want to reset the lines according to the assembly BOM?';
        PostJournalLinesConfirm: Label 'Do you want to post the journal lines?';
        JournalLinesSuccessfullyPosted: Label 'The journal lines were successfully posted.';
        AutomaticCostPostingMessage: Label 'The field Automatic Cost Posting should not be set to Yes if field Use Legacy G/L Entry Locking in General Ledger Setup table is set to No because of possibility of deadlocks.';
        UnadjustedValueEntriesNotCoveredMessage: Label 'Some unadjusted value entries will not be covered with the new setting. You must run the Adjust Cost - Item Entries batch job once to adjust these.';
        FileName: Label '%1.pdf';
        AssemblyOrderMustBeDeleted: Label 'Assembly Order must be deleted.';
        CannotDeleteItemError: Label 'You cannot delete Item %1 because it has ledger entries in a fiscal year that has not been closed yet.';
        ItemEntriesNotAdjustedError: Label 'There are item entries that have not been adjusted for item %1.';
        AmountMustBeSame: Label 'Amount must be same.';
        UpdateDimConfirmQst: Label 'Do you want to update the Dimensions on the lines';
        BeforeWorkDateMsg: Label 'is before work date %1 in one or more of the assembly lines';
        CalcStandardCostMsg: Label 'One or more subassemblies on the assembly list';
        PostingDateLaterErr: Label 'Posting Date on Assembly Order %1 must not be later than the Posting Date on Sales Order %2';
        UndoShipmentConfirmationMsg: Label 'Do you really want to undo the selected Shipment lines?';
        AppliesToEntryErr: Label 'Applies-to Entry on ILE should be equal to Appl. -to Item Entry on Assembly Line';
        CostAmountErr: Label 'Cost Amount (Actual) was adjusted incorrectly';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        UndoShpmtNotCompleteErr: Label 'The Shipment has not been cancelled completely.';

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdateFixedResourceUsageTypeWithItemType()
    begin
        // Setup.
        Initialize();
        ErrorOnUpdateFixedResourceUsageTypeOnAssemblyBOM("BOM Component Type"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdateFixedResourceUsageTypeWithBlankType()
    var
        BOMComponent: Record "BOM Component";
    begin
        // Setup.
        Initialize();
        ErrorOnUpdateFixedResourceUsageTypeOnAssemblyBOM(BOMComponent.Type::" ");
    end;

    local procedure ErrorOnUpdateFixedResourceUsageTypeOnAssemblyBOM(Type: Enum "BOM Component Type")
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // Setup Assembly Item.
        CreateAssemblyItem(Item);

        // Exercise.
        asserterror UpdateFixedResourceUsageTypeOnAssemblyBOM(BOMComponent, Item."No.", Type);

        // Verify.
        Assert.ExpectedTestFieldError(BOMComponent.FieldCaption(Type), Format(BOMComponent.Type::Resource));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateStandardCostAfterCopyAssemblyBOM()
    begin
        // Setup.
        Initialize();
        CalcStandardCostAndUnitPriceAfterCopyAssemblyBOM(false);  // Use Calculate Unit Price as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateUnitPriceAfterCopyAssemblyBOM()
    begin
        // Setup.
        Initialize();
        CalcStandardCostAndUnitPriceAfterCopyAssemblyBOM(true);  // Use Calculate Unit Price as True.
    end;

    local procedure CalcStandardCostAndUnitPriceAfterCopyAssemblyBOM(CalculateUnitPrice: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        AssemblyBOM: TestPage "Assembly BOM";
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapacityOverhead: Decimal;
    begin
        // Setup Assembly Item. Copy Assembly BOM. Add Resource to Assembly BOM.
        CreateAssemblyItem(Item);
        LibraryAssembly.CreateItem(
          Item2, Item2."Costing Method"::Standard, Item2."Replenishment System"::Assembly, Item."Gen. Prod. Posting Group",
          Item."Inventory Posting Group");
        CopyAssemblyBOM(Item."No.", Item2."No.");
        AddResourceToAssemblyBOM(Item2, false);  // Use False for without Resource Price.

        // Exercise.
        CalculateStandardCostOnAssemblyBOM(AssemblyBOM, Item2."No.");

        // Verify.
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapacityOverhead, Item2."No."),
          AssemblyBOM.Control18."Standard Cost".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), AmountMustBeSame);

        if CalculateUnitPrice then begin
            // Exercise.
            AssemblyBOM.CalcUnitPrice.Invoke();

            // Verify.
            Assert.AreNearlyEqual(
              LibraryAssembly.CalcExpectedPrice(Item2."No."), AssemblyBOM.Control18."Unit Price".AsDecimal(),
              LibraryERM.GetAmountRoundingPrecision(), AmountMustBeSame);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnExplodeAssemblyBOMWithResourceType()
    var
        BOMComponent: Record "BOM Component";
    begin
        // Setup.
        Initialize();
        ErrorOnExplodeAssemblyBOM(BOMComponent.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnExplodeAssemblyBOMWithBlankType()
    var
        BOMComponent: Record "BOM Component";
    begin
        // Setup.
        Initialize();
        ErrorOnExplodeAssemblyBOM(BOMComponent.Type::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnExplodeAssemblyBOMWithItemType()
    begin
        // Setup.
        Initialize();
        ErrorOnExplodeAssemblyBOM("BOM Component Type"::Item);
    end;

    local procedure ErrorOnExplodeAssemblyBOM(Type: Enum "BOM Component Type")
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // Setup Assembly Item.
        CreateAssemblyItem(Item);

        // Exercise.
        asserterror ExplodeAssemblyBOM(BOMComponent, Item."No.", Type);

        // Verify.
        if Type = BOMComponent.Type::Item then
            Assert.ExpectedError(StrSubstNo(ItemNotBOMError, BOMComponent."No."))
        else
            Assert.ExpectedTestFieldError(BOMComponent.FieldCaption(Type), Format(BOMComponent.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExplodeAssemblyBOMComponent()
    var
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        Item2: Record Item;
        QuantityPer: Decimal;
    begin
        // Setup: Setup two Assembly Item. Add Assembly Item to Assembly BOM.
        Initialize();
        CreateAssemblyItem(Item);
        CreateAssemblyItem(Item2);
        QuantityPer := LibraryRandom.RandInt(5);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item2."No.", Item."No.", '', BOMComponent."Resource Usage Type", QuantityPer, true);  // Use Base Unit of Measure as True and Variant Code as blank.

        // Exercise.
        BOMComponent.SetRange("No.", Item2."No.");
        ExplodeAssemblyBOM(BOMComponent, Item."No.", BOMComponent.Type::Item);

        // Verify.
        VerifyBOMComponentAfterExplodeBOM(Item."No.", Item2."No.", QuantityPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateStandardCostWithResourcePrice()
    begin
        // Setup.
        Initialize();
        CalculateStandardCostAndUnitPriceWithResourcePrice(false);  // Use Calculate Unit Price as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateUnitPriceWithResourcePrice()
    begin
        // Setup.
        Initialize();
        CalculateStandardCostAndUnitPriceWithResourcePrice(true);  // Use Calculate Unit Price as True.
    end;

    local procedure CalculateStandardCostAndUnitPriceWithResourcePrice(CalculateUnitPrice: Boolean)
    var
        Item: Record Item;
        AssemblyBOM: TestPage "Assembly BOM";
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapacityOverhead: Decimal;
    begin
        // Setup Assembly Item. Add Resource to Assembly BOM.
        CreateAssemblyItem(Item);
        AddResourceToAssemblyBOM(Item, true);  // Use True for with Resource Price.

        // Exercise.
        CalculateStandardCostOnAssemblyBOM(AssemblyBOM, Item."No.");

        // Verify.
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapacityOverhead, Item."No."),
          AssemblyBOM.Control18."Standard Cost".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), AmountMustBeSame);

        if CalculateUnitPrice then begin
            // Exercise.
            AssemblyBOM.CalcUnitPrice.Invoke();

            // Verify.
            Assert.AreNearlyEqual(
              LibraryAssembly.CalcExpectedPrice(Item."No."), AssemblyBOM.Control18."Unit Price".AsDecimal(),
              LibraryERM.GetAmountRoundingPrecision(), AmountMustBeSame);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithBOMComponents()
    begin
        // Setup.
        Initialize();
        AssemblyOrderOfItemWithBOMComponents(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyListFromAssemblyOrderForItem()
    begin
        // Setup.
        Initialize();
        AssemblyOrderOfItemWithBOMComponents(true, false);  // AssemblyListForItem as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnInvokingAssemblyListForResource()
    begin
        // Setup.
        Initialize();
        AssemblyOrderOfItemWithBOMComponents(true, true);  // AssemblyListForItem and AssemblyListForResource as TRUE.
    end;

    local procedure AssemblyOrderOfItemWithBOMComponents(AssemblyListForItem: Boolean; AssemblyListForResource: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        AssemblyBOM: TestPage "Assembly BOM";
    begin
        // Create Assembly Items and create their BOM components.
        CreateAssemblyItemsAndBOMComponentsSetup(Item, Item2, Item3);

        // Exercise.
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', LibraryRandom.RandDec(10, 2), '');

        // Verify.
        VerifyAssemblyLine(Item."No.", AssemblyHeader.Quantity);

        if AssemblyListForItem then begin
            // Exercise.
            BOMComponent.SetRange("Assembly BOM", false);
            FindBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item);
            ShowAssemblyListFromAssemblyLine(AssemblyBOM, AssemblyHeader."No.", BOMComponent."No.");

            // Verify.
            AssemblyBOM."No.".AssertEquals('');
        end;

        if AssemblyListForResource then begin
            // Exercise.
            FindBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Resource);
            FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", BOMComponent."No.");
            asserterror AssemblyLine.ShowAssemblyList();

            // Verify.
            Assert.ExpectedTestFieldError(AssemblyLine.FieldCaption(Type), Format(AssemblyLine.Type::Item));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnCreatingAssemblyOrderWithBlankNoSeries()
    var
        AssemblySetup: Record "Assembly Setup";
        AssemblyOrder: TestPage "Assembly Order";
    begin
        // Setup: Update blank Assembly Order Nos. on Assembly Setup. Create Assembly Order by page.
        Initialize();
        UpdateAssemblyOrderNosOnAssemblySetup('');
        AssemblyOrder.OpenNew();

        // Exercise.
        asserterror AssemblyOrder."No.".AssistEdit();

        // Verify.
        Assert.ExpectedTestFieldError(AssemblySetup.FieldCaption("Assembly Order Nos."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderByPage()
    var
        AssemblyOrder: TestPage "Assembly Order";
        AssemblyOrderNo: Code[20];
    begin
        // Setup: Get Next No. from Assembly Order No. Series. Create Assembly Order by page.
        Initialize();
        AssemblyOrderNo := GetNextNoFromAssemblyOrderNoSeries();
        AssemblyOrder.OpenNew();

        // Exercise.
        AssemblyOrder."Item No.".Activate();

        // Verify.
        AssemblyOrder."No.".AssertEquals(AssemblyOrderNo);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderForAssemblyItem()
    begin
        // Setup.
        Initialize();
        PostAssemblyOrderAfterPostSalesReturnOrder(false);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostingAssemblyOrderAfterPostSalesReturnOrder()
    begin
        // Setup.
        Initialize();
        PostAssemblyOrderAfterPostSalesReturnOrder(true);  // Assembly Order as TRUE.
    end;

    local procedure PostAssemblyOrderAfterPostSalesReturnOrder(AssemblyOrder: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // Create and post Sales Order for Assembly Item. Create Sales Return Order using Get Posted Doc Lines to Reverse.
        CreateAssemblyItem(Item);
        CreateAndPostSalesOrder(SalesLine, WorkDate(), Item."No.", LibraryRandom.RandDec(10, 2), false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLine."Sell-to Customer No.");
        SalesHeader.GetPstdDocLinesToReverse();
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify();

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as RECEIVE and INVOICE.

        // Verify.
        VerifySalesCreditMemoLine(SalesLine);

        if AssemblyOrder then begin
            // Exercise.
            LibraryAssembly.CreateAssemblyHeader(
              AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', SalesLine.Quantity, '');
            FindBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item);

            // Verify.
            LibraryAssembly.PostAssemblyHeader(AssemblyHeader, StrSubstNo(ItemNotOnInventoryError, BOMComponent."No."));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyListFromAssemblyOrderForAssemblyItem()
    var
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        AssemblyBOM: TestPage "Assembly BOM";
    begin
        // Create Assembly Items and create their BOM components. Create Assembly Order.
        Initialize();
        CreateAssemblyItemsAndBOMComponentsSetup(Item, Item2, Item3);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', LibraryRandom.RandDec(10, 2), '');

        // Exercise.
        ShowAssemblyListFromAssemblyLine(AssemblyBOM, AssemblyHeader."No.", Item2."No.");
        BOMComponent.SetRange("No.", Item3."No.");
        FindBOMComponent(BOMComponent, Item2."No.", BOMComponent.Type::Item);

        // Verify.
        VerifyAssemblyBOM(AssemblyBOM, BOMComponent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentItemDetailsOfAssemblyItem()
    var
        Item: Record Item;
        ComponentItem: Record Item;
        AssemblyBOM: TestPage "Assembly BOM";
    begin
        // Setup: Create Assembly Item. Find BOM Component.
        Initialize();
        CreateAssemblyItem(Item);
        GetItemFromBOMComponent(ComponentItem, Item."No.");

        // Exercise.
        OpenAssemblyBOMFromItemCard(AssemblyBOM, Item."No.");

        // Verify.
        AssemblyBOM.FILTER.SetFilter("No.", ComponentItem."No.");
        VerifyComponentDetailsOnAssemblyBOM(
          AssemblyBOM, ComponentItem."No.", Format(ComponentItem."Unit Price", 0, '<Precision,2><Standard Format,0>'),
          Format(ComponentItem."Unit Cost", 0, '<Precision,2><Standard Format,0>'), '', '', '');  // Value required for test. FORMAT required for test page verification.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentResourceDetailsOfAssemblyItem()
    var
        Item: Record Item;
        Resource: Record Resource;
        AssemblyBOM: TestPage "Assembly BOM";
    begin
        // Setup: Create Assembly Item. Find BOM Component.
        Initialize();
        CreateAssemblyItem(Item);
        GetResourceFromBOMComponent(Resource, Item."No.");

        // Exercise.
        OpenAssemblyBOMFromItemCard(AssemblyBOM, Item."No.");

        // Verify.
        AssemblyBOM.FILTER.SetFilter("No.", Resource."No.");
        VerifyComponentDetailsOnAssemblyBOM(
          AssemblyBOM, '', '', '', Resource."No.", Format(Resource.Type), Format(Resource."Unit Cost", 0, '<Precision,2><Standard Format,0>'));  // Value required for test. FORMAT required for test page verification.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderUsingDimensionAndMultipleUOM()
    begin
        // Setup.
        Initialize();
        PostAsmOrderWithDimAndMultipleUOM(false);  // Use False for AssemblyOrderError.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnCreatingAsmOrderWithPstdAsmOrderNoUsingDim()
    begin
        // Setup.
        Initialize();
        PostAsmOrderWithDimAndMultipleUOM(true);  // Use True for AssemblyOrderError.
    end;

    local procedure PostAsmOrderWithDimAndMultipleUOM(AssemblyOrderError: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Resource: Record Resource;
        Quantity: Decimal;
    begin
        // Update Stock out Warning on Assembly setup. Create Assembly Item setup with Dimension. Create and post Item Journal Line.
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        CreateAndPostItemJournalLine(ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.

        // Exercise.
        CreateAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, AssemblyItem."No.", Quantity, 100, 100, true);  // Use 100 for full Quantity to Assemble and True for Update All Components.

        // Verify.
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);

        if AssemblyOrderError then begin
            // Exercise.
            asserterror CreateAssemblyOrder(AssemblyHeader."No.");

            // Verify.
            Assert.ExpectedError(StrSubstNo(OrderCanNotCreatedError, AssemblyHeader."No."));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostingAsmOrderBeforeExplodeAsmListWithDim()
    begin
        // Setup.
        Initialize();
        PostAsmOrderWithExplodeAsmListAndDim(false);  // Use False for ExplodeAssemblyList.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostAsmOrderAfterExplodeAsmListWithDimension()
    begin
        // Setup.
        Initialize();
        PostAsmOrderWithExplodeAsmListAndDim(true);  // Use True for ExplodeAssemblyList.
    end;

    local procedure PostAsmOrderWithExplodeAsmListAndDim(ExplodeAssemblyList: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyItem: Record Item;
        AssemblyComponentItem: Record Item;
        ComponentItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Resource: Record Resource;
        Quantity: Decimal;
    begin
        // Update Stock out Warning on Assembly setup. Create Assembly Item Setup with Dimension. Create and post Item Journal Line. Add Assembly Component Item to Assembly List.
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        CreateAndPostItemJournalLine(ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.
        AddAssemblyComponentItemWithDimension(AssemblyComponentItem, ComponentItem, AssemblyItem."No.", Quantity);
        CreateAndPostItemJournalLine(ComponentItem."No.", Quantity * Quantity * Quantity, '');  // Value required for Inventory.

        // Exercise.
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), AssemblyItem."No.", '', Quantity, '');

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, StrSubstNo(ItemNotOnInventoryError, AssemblyComponentItem."No."));

        if ExplodeAssemblyList then begin
            // Exercise.
            FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", AssemblyComponentItem."No.");
            AssemblyLine.ExplodeAssemblyList();
            PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 100, true);  // Use 100 for full Quantity to Assemble and True for Update All Components.

            // Verify.
            LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
            LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
            LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostingAsmOrderAfterDeleteAsmLinesUsingDim()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Resource: Record Resource;
        Quantity: Decimal;
    begin
        // Setup: Update Stock out Warning on Assembly setup. Create Assembly Item setup with Dimension. Create and post Item Journal Line. Create Assembly Order.
        Initialize();
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        CreateAndPostItemJournalLine(ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), AssemblyItem."No.", '', Quantity, '');

        // Exercise.
        LibraryAssembly.DeleteAssemblyLine("BOM Component Type"::Item, AssemblyHeader."No.");
        LibraryAssembly.DeleteAssemblyLine("BOM Component Type"::Resource, AssemblyHeader."No.");

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateStandardCostWithSalesDiscount()
    begin
        // Setup.
        Initialize();
        CalcStandardCostAndUnitPriceWithSalesPriceAndDisc(false, false);  // Use False for WithSalesPrice and CalculateUnitPrice.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateUnitPriceWithSalesDiscount()
    begin
        // Setup.
        Initialize();
        CalcStandardCostAndUnitPriceWithSalesPriceAndDisc(false, true);  // Use False for WithSalesPrice and  True for CalculateUnitPrice.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateStandardCostWithSalesPrice()
    begin
        // Setup.
        Initialize();
        CalcStandardCostAndUnitPriceWithSalesPriceAndDisc(true, false);  // Use True for WithSalesPrice and  False for CalculateUnitPrice.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateUnitPriceWithSalesPrice()
    begin
        // Setup.
        Initialize();
        CalcStandardCostAndUnitPriceWithSalesPriceAndDisc(true, true);  // Use True for WithSalesPrice and CalculateUnitPrice.
    end;

    local procedure CalcStandardCostAndUnitPriceWithSalesPriceAndDisc(WithSalesPrice: Boolean; CalculateUnitPrice: Boolean)
    var
        Item: Record Item;
        AssemblyBOM: TestPage "Assembly BOM";
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapacityOverhead: Decimal;
    begin
        // Setup Assembly Item. Add  Item to Assembly BOM.
        CreateAssemblyItem(Item);
        AddItemToAssemblyBOM(Item, WithSalesPrice);

        // Exercise.
        CalculateStandardCostOnAssemblyBOM(AssemblyBOM, Item."No.");

        // Verify.
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapacityOverhead, Item."No."),
          AssemblyBOM.Control18."Standard Cost".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), AmountMustBeSame);

        if CalculateUnitPrice then begin
            // Exercise.
            AssemblyBOM.CalcUnitPrice.Invoke();

            // Verify.
            Assert.AreNearlyEqual(
              LibraryAssembly.CalcExpectedPrice(Item."No."), AssemblyBOM.Control18."Unit Price".AsDecimal(),
              LibraryERM.GetAmountRoundingPrecision(), AmountMustBeSame);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialAsmOrderUsingDimensionAndMultipleUOM()
    var
        AssemblyItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Resource: Record Resource;
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item setup with Dimension. Create and post Item Journal Line.
        Initialize();
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        CreateAndPostItemJournalLine(ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.

        // Exercise.
        CreateAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, AssemblyItem."No.", Quantity, 50, 0, false);  // Use 50 for Partial Quantity to Assemble, 0 for Quantity to Consume.

        // Verify.
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialAssemblyOrderUsingDifferentPostingDate()
    var
        AssemblyItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Resource: Record Resource;
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item setup with Dimension. Create and post Item Journal Line. Create and Post Assembly Order. Modify Posting Date on Assembly Header.
        Initialize();
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        CreateAndPostItemJournalLine(ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.
        CreateAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, AssemblyItem."No.", Quantity, 60, 60, false);  // Use 60 for Partial Quantity to Assemble and Quantity to Consume.
        UpdatePostingDateOnAssemblyHeader(AssemblyHeader, TempAssemblyLine);

        // Exercise.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateUnitCostAfterPartialPosting()
    var
        AssemblyItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Resource: Record Resource;
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item setup with Dimension. Create and post Item Journal Line. Create and Post Assembly Order. Refresh Assembly Order.
        Initialize();
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        UpdateAverageCostingMethodOnAssemblyItem(AssemblyItem);
        CreateAndPostItemJournalLine(ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.
        CreateAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, AssemblyItem."No.", Quantity, 60, 60, false);  // Use 60 for Partial Quantity to Assemble and Quantity to Consume.
        RefreshAssemblyOrder(AssemblyHeader);

        // Exercise.
        AssemblyHeader.UpdateUnitCost();

        // Verify.
        VerifyStatisticsPage(AssemblyHeader, ItemUnitOfMeasure."Item No.", Resource."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialAsmOrderWithFixedResourceUsageType()
    begin
        // Setup.
        Initialize();
        PostPartialAsmOrderAfterDeletingComponentItemLine(true);  // Update Resource as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialAsmOrderWithoutFixedResourceUsageType()
    begin
        // Setup.
        Initialize();
        PostPartialAsmOrderAfterDeletingComponentItemLine(false);  // Update Resource as FALSE.
    end;

    local procedure PostPartialAsmOrderAfterDeletingComponentItemLine(UpdateResource: Boolean)
    var
        AssemblyItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Resource: Record Resource;
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Quantity: Decimal;
    begin
        // create Assembly Item setup with Dimension. Create and post Item Journal Line. Delete Assembly Item Line. Update Fixed Resource Usage Type on Resource.
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        CreateAndPostItemJournalLine(ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.
        DeleteAssemblyLine(AssemblyHeader, AssemblyItem."No.", Quantity);
        if UpdateResource then
            UpdateFixedResourceUsageTypeOnAssemblyLine(AssemblyHeader."No.", Resource."No.");

        // Exercise.
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 60, 60, false);  // Use 60 for Partial Quantity to Assemble and Quantity to Consume.

        // Verify.
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyCapEntries(TempAssemblyLine, AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderUsingComponentItemVariant()
    var
        ItemVariant: Record "Item Variant";
        AssemblyItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item Setup with Variant. Create and Post Item Journal Line.
        Initialize();
        Quantity := CreateAssemblyItemSetupWithVariant(AssemblyItem, ItemUnitOfMeasure, ItemVariant);
        CreateAndPostItemJournalLine(
          ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", ItemVariant.Code);  // Value required for Inventory using different Unit of Measure Conversion.

        // Exercise.
        CreateAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, AssemblyItem."No.", Quantity, 100, 100, true);  // Use 100 for full Quantity to Assemble and True for Update All Components.

        // Verify.
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyItemDetailsOfAssemblyItem()
    var
        Item: Record Item;
        AssemblyBOM: TestPage "Assembly BOM";
    begin
        // Setup: Create Assembly Item.
        Initialize();
        CreateAssemblyItem(Item);

        // Exercise.
        CalculateStandardCostOnAssemblyBOM(AssemblyBOM, Item."No.");
        AssemblyBOM.CalcUnitPrice.Invoke();
        Item.Find();

        // Verify.
        Assert.AreNearlyEqual(
          Item."Standard Cost", AssemblyBOM.Control18."Standard Cost".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          AmountMustBeSame);
        Assert.AreNearlyEqual(
          Item."Unit Price", AssemblyBOM.Control18."Unit Price".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          AmountMustBeSame);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithAssemblyItemVariant()
    begin
        // Setup.
        Initialize();
        AssemblyOrderWithVariant(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithComponentItemVariant()
    begin
        // Setup.
        Initialize();
        AssemblyOrderWithVariant(true, false);  // ComponentItemVariant as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithResourceVariantError()
    begin
        // Setup.
        Initialize();
        AssemblyOrderWithVariant(true, true);  // ComponentItemVariant and ResourceVariant as TRUE.
    end;

    local procedure AssemblyOrderWithVariant(ComponentItemVariant: Boolean; ResourceVariant: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        BOMComponent: Record "BOM Component";
        ComponentItem: Record Item;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        // Create Assembly Item. Create Assembly Order. Create Item Variant.
        CreateAssemblyItem(Item);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', LibraryRandom.RandDec(10, 2), '');
        LibraryInventory.CreateVariant(ItemVariant, Item);

        // Exercise.
        UpdateVariantOnAssemblyHeader(AssemblyHeader, ItemVariant.Code);

        // Verify.
        AssemblyHeader.TestField("Variant Code", ItemVariant.Code);

        if ComponentItemVariant then begin
            // Exercise.
            GetItemFromBOMComponent(ComponentItem, Item."No.");
            FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", ComponentItem."No.");
            LibraryInventory.CreateVariant(ItemVariant, ComponentItem);
            UpdateVariantOnAssemblyLine(AssemblyLine, ItemVariant.Code);

            // Verify.
            AssemblyLine.TestField("Variant Code", ItemVariant.Code);
        end;

        if ResourceVariant then begin
            // Exercise.
            FindBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Resource);
            FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", BOMComponent."No.");
            asserterror AssemblyLine.Validate("Variant Code", ItemVariant.Code);

            // Verify.
            Assert.ExpectedTestFieldError(AssemblyLine.FieldCaption(Type), Format(AssemblyLine.Type::Item));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyItemDetailsOfAssemblyOrder()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyBOM: TestPage "Assembly BOM";
    begin
        // Setup: Create Assembly Item. Calculate Standard Cost and Unit Price on Assembly BOM page.
        Initialize();
        CreateAssemblyItem(Item);
        CalculateStandardCostOnAssemblyBOM(AssemblyBOM, Item."No.");
        AssemblyBOM.CalcUnitPrice.Invoke();

        // Exercise.
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', LibraryRandom.RandDec(10, 2), '');
        Item.Find();

        // Verify.
        VerifyAssemblyItemDetailsOnAssemblyOrder(Item, AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentItemDetailsOfAssemblyOrder()
    var
        ComponentItem: Record Item;
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
    begin
        // Setup: Create Assembly Item. Create Assembly Order.
        Initialize();
        CreateAssemblyItem(Item);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', LibraryRandom.RandDec(10, 2), '');

        // Exercise.
        GetItemFromBOMComponent(ComponentItem, Item."No.");

        // Verify.
        VerifyComponentItemDetailsOnAssemblyOrder(ComponentItem, AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentResourceDetailsOfAssemblyOrder()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        Resource: Record Resource;
    begin
        // Setup: Create Assembly Item. Create Assembly Order.
        Initialize();
        CreateAssemblyItem(Item);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', LibraryRandom.RandDec(10, 2), '');

        // Exercise.
        GetResourceFromBOMComponent(Resource, Item."No.");

        // Verify.
        VerifyComponentResourceDetailsOnAssemblyOrder(Resource, AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyListFromAssemblyOrder()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyBOM: TestPage "Assembly BOM";
    begin
        // Setup: Create Assembly Item. Create Assembly Order.
        Initialize();
        CreateAssemblyItem(Item);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', LibraryRandom.RandDec(10, 2), '');

        // Exercise.
        AssemblyBOM.Trap();
        AssemblyHeader.ShowAssemblyList();

        // Verify.
        VerifyBOMComponentsOnAssemblyBOM(AssemblyBOM, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithQuantityToAssembleAndDimensions()
    begin
        // Setup.
        Initialize();
        AssemblyOrderWithDimensions(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAssemblyOrderAfterPartialPostWithDimensions()
    begin
        // Setup.
        Initialize();
        AssemblyOrderWithDimensions(true);  // DeleteAssemblyOrder as TRUE.
    end;

    local procedure AssemblyOrderWithDimensions(DeleteAssemblyOrder: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        AssemblyHeader: Record "Assembly Header";
        Resource: Record Resource;
    begin
        // Create Assembly Item with Dimensions. Create Assembly Order.
        CreateAssemblyItemSetupWithDimension(Item, ItemUnitOfMeasure, Resource);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', LibraryRandom.RandInt(10), '');

        // Exercise.
        UpdateQuantityToAssembleOnAssemblyOrder(AssemblyHeader, AssemblyHeader.Quantity / 2);  // Partial Value required for the test.

        // Verify.
        VerifyQuantityToConsumeOnAssemblyLine(Item."No.", AssemblyHeader."Quantity to Assemble");

        if DeleteAssemblyOrder then begin
            // Exercise: Add Components Inventory and Post the Assembly Order. Delete the Assembly Order.
            LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), 10 + LibraryRandom.RandDec(10, 2));  // Greater value required for the Component Inventory.
            LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
            AssemblyHeader.Find();
            AssemblyHeader.Delete(true);
            asserterror AssemblyHeader.Find();

            // Verify.
            Assert.ExpectedErrorCannotFind(Database::"Assembly Header");
        end;
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ItemSubstitutionOnAssemblyOrderWithDimension()
    begin
        // Setup.
        Initialize();
        PostAssemblyOrderWithItemSubstitutionAndDimension(false);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderWithDimensionAndItemSubstitution()
    begin
        // Setup.
        Initialize();
        PostAssemblyOrderWithItemSubstitutionAndDimension(true);  // Use True for PostAssemblyOrder.
    end;

    local procedure PostAssemblyOrderWithItemSubstitutionAndDimension(PostAssemblyOrder: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyItem: Record Item;
        ItemSubstitution: Record "Item Substitution";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Resource: Record Resource;
        TempAssemblyLine: Record "Assembly Line" temporary;
        Quantity: Decimal;
    begin
        // Create Assembly Item setup with Dimension. Create Item Substitution. Create and post Item Journal Line. Create Assembly Order.
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        LibraryAssembly.CreateItemSubstitution(ItemSubstitution, ItemUnitOfMeasure."Item No.");
        CreateAndPostItemJournalLine(
          ItemSubstitution."Substitute No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), AssemblyItem."No.", '', Quantity, '');

        // Exercise.
        SelectItemSubstitutionOnAssemblyOrder(AssemblyHeader."No.");

        // Verify.
        FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", ItemSubstitution."Substitute No.");
        AssemblyLine.TestField(Quantity, Quantity * Quantity);  // Value required for Inventory on Assembly Line.

        if PostAssemblyOrder then begin
            // Exercise.
            PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 100, true);  // Use 100 for full Quantity to Assemble and True for Update All Components.

            // Verify.
            LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
            LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
            LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderAfterlPostedAsmOrderWithDim()
    begin
        // Setup.
        Initialize();
        NavigateFinishedProdOrderWithPostedAsmOrderAndDim(false);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NavigateFnshdProdOrderAfterPostedAsmOrderWithDim()
    begin
        // Setup.
        Initialize();
        NavigateFinishedProdOrderWithPostedAsmOrderAndDim(true);  // Use True for NavigateOrder.
    end;

    local procedure NavigateFinishedProdOrderWithPostedAsmOrderAndDim(NavigateOrder: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        Resource: Record Resource;
        TempAssemblyLine: Record "Assembly Line" temporary;
        ValueEntry: Record "Value Entry";
        Navigate: TestPage Navigate;
        Quantity: Decimal;
        ProductionOrderLineNo: Integer;
    begin
        // Create Assembly Item setup with Dimension. Create and post Item Journal Line.
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        CreateAndPostItemJournalLine(ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.
        CreateAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, AssemblyItem."No.", Quantity, 100, 100, true);  // Use 100 for full Quantity to Assemble and True for Update All Components.

        // Exercise.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, AssemblyHeader."No.");

        // Verify.
        ProductionOrderLineNo := VerifyReleasedProductionOrderLine(ProductionOrder);

        if NavigateOrder then begin
            // Exercise.
            LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProductionOrderLineNo);
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
            NavigateFinishedProductionOrder(Navigate, ProductionOrder."No.");

            // Verify.
            VerifyNoOfRecordsAfterNavigate(Navigate, ProductionOrder.TableCaption());
            VerifyNoOfRecordsAfterNavigate(Navigate, ItemLedgerEntry.TableCaption());
            VerifyNoOfRecordsAfterNavigate(Navigate, ValueEntry.TableCaption());
            VerifyNoOfRecordsAfterNavigate(Navigate, CapacityLedgerEntry.TableCaption());
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderWithDimAndSameComponentItemTwice()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Resource: Record Resource;
        TempAssemblyLine: Record "Assembly Line" temporary;
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item setup with Dimension and same Component Item Twice. Create and post Item Journal Line.
        Initialize();
        Quantity := CreateAssemblyItemSetupWithDimension(AssemblyItem, ItemUnitOfMeasure, Resource);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ItemUnitOfMeasure."Item No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type",
          Quantity, false);
        CreateAndPostItemJournalLine(
          ItemUnitOfMeasure."Item No.", 2 * Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.

        // Exercise.
        CreateAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, AssemblyItem."No.", Quantity, 100, 100, true);  // Use 100 for full Quantity to Assemble and True for Update All Components.

        // Verify.
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostAsmOrderAfterCalcStdCostAndUnitPriceOnAsmBOM()
    var
        AssemblyItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Resource: Record Resource;
        AssemblyBOM: TestPage "Assembly BOM";
        Quantity: Decimal;
    begin
        // Setup: Create Assembly Item Setup. Calculate Standard Cost and Unit Price on Assembly BOM. Create and Post Item Journal Line. Create Assembly Order and Delete Assembly Item Line.
        Initialize();
        Quantity :=
          CreateAssemblyItemSetup(
            AssemblyItem, ItemUnitOfMeasure, Resource, AssemblyItem."Costing Method"::Standard, AssemblyItem."Costing Method"::Standard);
        CalculateStandardCostOnAssemblyBOM(AssemblyBOM, AssemblyItem."No.");
        AssemblyBOM.CalcUnitPrice.Invoke();
        CreateAndPostItemJournalLine(ItemUnitOfMeasure."Item No.", Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '');  // Value required for Inventory using different Unit of Measure Conversion.
        DeleteAssemblyLine(AssemblyHeader, AssemblyItem."No.", Quantity);

        // Exercise.
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 100, true);  // Use 100 for full Quantity to Assemble and True for Update All Components.

        // Verify.
        VerifyPostedAssemblyOrderStatistics(AssemblyHeader."No.", AssemblyItem."No.", Resource."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialAsmOrderAfterAdjustCostItemEntries()
    var
        InventorySetup: Record "Inventory Setup";
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // Setup: Update Automatic Cost Posting and Automatic Cost Adjustment on Inventory Setup. Create Initial Setup for Posting Assembly Order with Multiple Component Items. Run Adjust Cost Item Entries Report.
        Initialize();
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(false, InventorySetup."Automatic Cost Adjustment"::Never);
        CreateInitialSetupForPostAsmOrdWithMultipleItems(AssemblyHeader, AssemblyItem);
        LibraryCosting.AdjustCostItemEntries(AssemblyItem."No.", '');
        LibraryVariableStorage.Enqueue(AutomaticCostPostingMessage);  // Enqueue for MessageHandler.
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Never);  // Automatic Cost Posting as TRUE.
        DeleteAssemblyCommentLine(AssemblyHeader."Document Type", AssemblyHeader."No.");

        // Exercise.
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 70, false);  // Use 100 for full Quantity to Assemble and 70 for Quantity to Consume.

        // Verify.
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
    end;

    [Test]
    [HandlerFunctions('GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLAfterPostAsmOrdWithManualAutoPost()
    var
        InventorySetup: Record "Inventory Setup";
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // Setup: Update Automatic Cost Posting and Automatic Cost Adjustment on Inventory Setup. Create Initial Setup for Posting Assembly Order with Multiple Component Items. Run Adjust Cost Item Entries Report. Post Assembly Order.
        Initialize();

        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Never);  // Automatic Cost Posting as TRUE.
        CreateInitialSetupForPostAsmOrdWithMultipleItems(AssemblyHeader, AssemblyItem);
        LibraryCosting.AdjustCostItemEntries(AssemblyItem."No.", '');
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(false, InventorySetup."Automatic Cost Adjustment"::Never);
        DeleteAssemblyCommentLine(AssemblyHeader."Document Type", AssemblyHeader."No.");
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 70, false);  // Use 100 for full Quantity to Assemble and 70 for Quantity to Consume.

        // Exercise.
        LibraryPostInventoryCostToGL.PostInvtCostToGL(false, AssemblyItem."No.", '', StrSubstNo(FileName, TemporaryPath + AssemblyItem."No."));

        // Verify.
        VerifyGLEntry(AssemblyItem, AssemblyHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLWithManAutoPostAndAutoCostAdjmt()
    var
        InventorySetup: Record "Inventory Setup";
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // Setup: Update Automatic Cost Posting and Automatic Cost Adjustment on Inventory Setup. Create Initial Setup for Posting Assembly Order with Multiple Component Items. Post Assembly Order.
        Initialize();
        LibraryVariableStorage.Enqueue(UnadjustedValueEntriesNotCoveredMessage);  // Enqueue for MessageHandler.
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Always);  // Automatic Cost Posting as TRUE.
        CreateInitialSetupForPostAsmOrdWithMultipleItems(AssemblyHeader, AssemblyItem);
        LibraryVariableStorage.Enqueue(UnadjustedValueEntriesNotCoveredMessage);  // Enqueue for MessageHandler.
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(false, InventorySetup."Automatic Cost Adjustment"::Always);
        DeleteAssemblyCommentLine(AssemblyHeader."Document Type", AssemblyHeader."No.");
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 70, false);  // Use 100 for full Quantity to Assemble and 70 for Quantity to Consume.

        // Exercise.
        LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);
        LibraryPostInventoryCostToGL.PostInvtCostToGL(false, AssemblyItem."No.", '', StrSubstNo(FileName, TemporaryPath + AssemblyItem."No."));

        // Verify.
        VerifyGLEntry(AssemblyItem, AssemblyHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLWithManualAutoPostAndManCostAdjmt()
    var
        InventorySetup: Record "Inventory Setup";
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // Setup: Update Automatic Cost Posting and Automatic Cost Adjustment on Inventory Setup. Create Initial Setup for Posting Assembly Order with Multiple Component Items. Post Assembly Order. Run Adjust Cost Item Entries Report.
        Initialize();
        LibraryVariableStorage.Enqueue(UnadjustedValueEntriesNotCoveredMessage);  // Enqueue for MessageHandler.
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(false, InventorySetup."Automatic Cost Adjustment"::Always);
        CreateInitialSetupForPostAsmOrdWithMultipleItems(AssemblyHeader, AssemblyItem);
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(false, InventorySetup."Automatic Cost Adjustment"::Never);
        DeleteAssemblyCommentLine(AssemblyHeader."Document Type", AssemblyHeader."No.");
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 70, false);  // Use 100 for full Quantity to Assemble and 70 for Quantity to Consume.
        LibraryCosting.AdjustCostItemEntries(AssemblyItem."No.", '');

        // Exercise.
        LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);
        LibraryPostInventoryCostToGL.PostInvtCostToGL(false, AssemblyItem."No.", '', StrSubstNo(FileName, TemporaryPath + AssemblyItem."No."));

        // Verify.
        VerifyGLEntry(AssemblyItem, AssemblyHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderWithAutoCostPostAndAutoCostAdjmt()
    var
        InventorySetup: Record "Inventory Setup";
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // Setup: Update Automatic Cost Posting and Automatic Cost Adjustment on Inventory Setup. Create Initial Setup for Posting Assembly Order with Multiple Component Items.
        Initialize();
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Never);  // Automatic Cost Posting as TRUE.
        CreateInitialSetupForPostAsmOrdWithMultipleItems(AssemblyHeader, AssemblyItem);
        LibraryVariableStorage.Enqueue(UnadjustedValueEntriesNotCoveredMessage);  // Enqueue for MessageHandler.
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Always);  // Automatic Cost Posting as TRUE.
        DeleteAssemblyCommentLine(AssemblyHeader."Document Type", AssemblyHeader."No.");

        // Exercise.
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 70, false);  // Use 100 for full Quantity to Assemble and 70 for Quantity to Consume.

        // Verify.
        VerifyGLEntry(AssemblyItem, AssemblyHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialAssemblyOrderWithDimensions()
    begin
        // Setup.
        Initialize();
        PartialPostingOfAssemblyOrderWithDimensions(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRemainingAssemblyOrderWithDimensions()
    begin
        // Setup.
        Initialize();
        PartialPostingOfAssemblyOrderWithDimensions(true);  // Post Remaining as TRUE.
    end;

    local procedure PartialPostingOfAssemblyOrderWithDimensions(PostRemaining: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Resource: Record Resource;
        Quantity: Decimal;
    begin
        // Create Assembly Item with Dimensions. Create Assembly Order. Add Component Inventory.
        Quantity := CreateAssemblyItemSetupWithDimension(Item, ItemUnitOfMeasure, Resource);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', Quantity, '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), Quantity);

        // Exercise.
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 60, 60, false);  // Use 60 for Partial Quantity to Assemble and Quantity to Consume.

        // Verify.
        AssemblyHeader.Find();
        VerifyQuantityOnAssemblyOrder(
          AssemblyHeader, (Quantity * 40) / 100, (TempAssemblyLine.Quantity * 60) / 100,
          TempAssemblyLine.Quantity - TempAssemblyLine."Quantity to Consume");  // Calculated values required for the test.

        if PostRemaining then begin
            // Exercise.
            DeleteAssemblyCommentLine(AssemblyHeader."Document Type", AssemblyHeader."No.");
            PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 40, false);  // Use 100 for Quantity to Assemble and 40 for Quantity to Consume.

            // Verify.
            Assert.IsFalse(AssemblyHeader.Find(), AssemblyOrderMustBeDeleted);
            LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Assembled Quantity");
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnDeletingItemAfterPostReservedSOWithDim()
    begin
        // Setup.
        Initialize();
        DeleteItemAfterPostSalesOrderAndAsmOrderWithDim(false);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnDeletingItemAfterCloseFiscalYearWithDim()
    begin
        // Setup.
        Initialize();
        DeleteItemAfterPostSalesOrderAndAsmOrderWithDim(true);  // Close Fiscal Year as TRUE.
    end;

    local procedure DeleteItemAfterPostSalesOrderAndAsmOrderWithDim(CloseYear: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
        PostingDate: Date;
    begin
        // Create Inventory Period. Create Assembly Item with Dimensions. Create and Post Assembly Order. Create and Post Sales Order after reservation.
        PostingDate := CreateFiscalYearAndInventoryPeriod();
        Quantity := CreateAssemblyItemSetupWithDimension(Item, ItemUnitOfMeasure, Resource);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, PostingDate, Item."No.", '', Quantity, '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, PostingDate, Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for Component Inventory.
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 100, true);  // Use 100 for full Quantity to Assemble and TRUE for Update all Components.
        CreateAndPostSalesOrder(SalesLine, PostingDate, Item."No.", Quantity, true);  // TRUE for Reserve.

        // Exercise.
        asserterror Item.Delete(true);

        // Verify.
        Assert.ExpectedError(StrSubstNo(CannotDeleteItemError, Item."No."));

        if CloseYear then begin
            // Exercise.
            LibraryFiscalYear.CloseAccountingPeriod();
            LibraryFiscalYear.CreateFiscalYear();  // New Fiscal Year creation is required to generate the error.
            asserterror Item.Delete(true);

            // Verify.
            Assert.ExpectedError(StrSubstNo(ItemEntriesNotAdjustedError, Item."No."));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesAfterBlockOrderDimension()
    var
        BOMComponent: Record "BOM Component";
        ComponentItem: Record Item;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        AssemblySetup: Record "Assembly Setup";
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Resource: Record Resource;
        Quantity: Decimal;
        UnitCost: Decimal;
        BlockType: Option Dimension,"Dimension Value","Dimension Combination","None";
    begin
        // Setup: Update Copy Component Dimensions from field on Assembly Setup. Create Assembly Item with Dimensions. Create and Post Assembly Order. Block Assembly Order Dimension Combination.
        Initialize();
        UpdateCopyComponentDimensionsOnAssemblySetup(AssemblySetup."Copy Component Dimensions from"::"Order Header");
        Quantity := CreateAssemblyItemSetupWithDimension(Item, ItemUnitOfMeasure, Resource);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', Quantity, '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), Quantity * Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for the Component Inventory.
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 100, true);  // Use 100 for full Quantity to Assemble and True for Update All Components.
        FindBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item);
        ComponentItem.Get(BOMComponent."No.");
        UnitCost := ComponentItem."Unit Cost";
        LibraryAssembly.BlockOrderDimensions(AssemblyHeader, BlockType::"Dimension Combination", BlockType::None);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(BOMComponent."No.", '');

        // Verify.
        ComponentItem.TestField("Unit Cost", UnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderWithResourceWithoutLocation()
    var
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Resource: Record Resource;
        PostedAssemblyHeader: Record "Posted Assembly Header";
        Item: Record Item;
    begin
        // Setup: Create item, location.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        InventorySetupWithLocationMandatory(true);
        LibraryAssembly.CreateResource(Resource, true, '');
        LibraryInventory.CreateItem(Item);

        // Exercise: Create and Post Assembly Order.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.",
          Location.Code, LibraryRandom.RandInt(5), '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Resource, Resource."No.",
          LibraryAssembly.GetUnitOfMeasureCode("BOM Component Type"::Resource, Resource."No.", true),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5), '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ''); // Last parameter stands for ExpectedError.

        // Verify: Assembly Order with Resource Line without Location posted successfully.
        FindPostedAssemblyHeader(PostedAssemblyHeader, AssemblyHeader."No.", Item."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateAssemblyOrderFromSalesOrderWithDimension()
    var
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        AssemblyHeader: Record "Assembly Header";
    begin
        // Test and verify dimensions are populated on Assembly Order header when this is created from a sales order.
        Initialize();

        // Setup: Create Assembly Item, create dimension values, create sales order with the assembly item
        CreateAsmItemAndSalesOrderWithDimSetup(SalesLine, DimensionValue, DimensionValue2);

        // Exercise: Generate an Assembly order and syncronize the dimension on Sales line to Assembly Header
        UpdateQtyToAssembleOnSalesLine(SalesLine, SalesLine.Quantity);

        // Find the Assembly Header created from the sales line
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, SalesLine."No.");

        // Verify: The dimension values have been populated on Assembly header
        VerifyDimensionOnAssemblyHeader(AssemblyHeader, DimensionValue.Code, DimensionValue2.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateDimensionOnSalesLineWithAssemblyOrder()
    var
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        AssemblyHeader: Record "Assembly Header";
    begin
        // Test and verify dimensions are populated on Assembly Order header when the dimensions on related sales line are updated.
        Initialize();

        // Setup: Create Assembly Item, create dimension values, create sales order with the assembly item
        CreateAsmItemAndSalesOrderWithDimSetup(SalesLine, DimensionValue, DimensionValue2);
        UpdateQtyToAssembleOnSalesLine(SalesLine, SalesLine.Quantity); // Generate an Assembly order from Sales Line

        // Create new Dimension value from Shortcut dimension codes
        CreateShortcutDimensionValue(
          DimensionValue, DimensionValue2, DimensionValue."Dimension Code", DimensionValue2."Dimension Code");

        // Exercise: Update Dimension value on Sales Line
        UpdateDimensionValueOnSalesLine(SalesLine, DimensionValue.Code, DimensionValue2.Code);

        // Find the Assembly Header created from the sales line
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, SalesLine."No.");

        // Verify: The new dimension values have been populated on Assembly header
        VerifyDimensionOnAssemblyHeader(AssemblyHeader, DimensionValue.Code, DimensionValue2.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateAndPostAssemblyOrderFromSalesOrderWithDimension()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        AssemblyHeader: Record "Assembly Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Test and verify dimensions are populated in Item Ledger Entry of Assembly Output Type.
        Initialize();

        // Setup: Create Assembly Item, create dimension values, create sales order with the assembly item
        CreateAsmItemAndSalesOrderWithDimSetup(SalesLine, DimensionValue, DimensionValue2);

        // Generate an Assembly order and syncronize the dimension on Sales line to Assembly Header
        UpdateQtyToAssembleOnSalesLine(SalesLine, SalesLine.Quantity);

        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, SalesLine."No."); // Find the Assembly Header created from the sales line
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), LibraryRandom.RandInt(10)); // Add component inventory for assembly item

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post sales order as SHIP and INVOICE.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Assembly Output", SalesLine."No.");

        // Verify: Dimension values are populated in Item Ledger Entry of Assembly Output Type
        VerifyDimensionOnILE(ItemLedgerEntry, DimensionValue.Code, DimensionValue2.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAssemblyOrderFromSalesOrderAfterPartialInvoiced()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        PartialInvoicedQty: Decimal;
    begin
        Initialize();

        // Setup: Create Assembly Item, Customer and create sales order with the assembly item.
        CreateSalesOrderWithAssemblyItem(SalesLine);

        // Exercise: Post sales order as fully SHIP.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Partial invoice the sales order.
        SalesLine.Find();
        PartialInvoiceSalesOrder(SalesLine, SalesHeader, LibraryRandom.RandDecInDecimalRange(0, SalesLine.Quantity - 0.01, 2));

        // Verify: The Invoiced Quantity in the Item Ledger Entries and Sales Invoice Line in Value Entries matche the Quantity Invoiced on the Sales Lines.
        SalesLine.Find();
        VerifyInvoicedQtyOnItemLedgerEntry(ItemLedgerEntry."Entry Type"::Sale, SalesLine."No.", -SalesLine."Quantity Invoiced");
        FindValueEntry(ValueEntry, ValueEntry."Document Type"::"Sales Invoice", SalesLine."No.");
        VerifyQtyOnValueEntry(ValueEntry, -SalesLine."Quantity Invoiced");
        PartialInvoicedQty := SalesLine."Quantity Invoiced";

        // Exercise and Verify: Invoice others of the sales order and verify no error pops up.
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Verify: The Invoiced Quantity in the Item Ledger Entries and Sales Invoice Line in Value Entries matche the Quantity Invoiced on the Sales Lines.
        VerifyInvoicedQtyOnItemLedgerEntry(ItemLedgerEntry."Entry Type"::Sale, SalesLine."No.", -SalesLine.Quantity);
        VerifyQtyOnValueEntry(ValueEntry, -PartialInvoicedQty);
        ValueEntry.Next();
        VerifyQtyOnValueEntry(ValueEntry, -(SalesLine.Quantity - PartialInvoicedQty));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExplodeAssemblyBOMComponentWithBaseUnitOfMeasureInAssemblyOrder()
    begin
        // Test and verify "Explode BOM" in Assembly Order considers current "Quantity" from the line being exploded.
        Initialize();
        ExplodeAssemblyBOMComponentInAssemblyOrder(true); // TRUE indicates using Base of Unit Measure Code when creating Assembly component
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExplodeAssemblyBOMComponentWithOtherUnitOfMeasureInAssemblyOrder()
    begin
        // Test and verify "Explode BOM" in Assembly Order considers current "Qty. Per Unit of Measure" from the line being exploded.
        Initialize();
        ExplodeAssemblyBOMComponentInAssemblyOrder(false); // FALSE indicates not using Base of Unit Measure Code when creating Assembly component
    end;

    local procedure ExplodeAssemblyBOMComponentInAssemblyOrder(UseBaseUnitOfMeasure: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
    begin
        // Setup: Create Assembly Item with an Assembly Item as Component, create Assembly Order for the parent Assembly Item
        // Update Quantity Per on the assembly line for child Assembly Item
        CreateAssemblyItemWithAssemblyItemAsComponent(Item, Item2, UseBaseUnitOfMeasure);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), Item."No.", '', LibraryRandom.RandInt(5), '');
        FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", Item2."No.");
        UpdateQtyPerOnAssemblyLine(AssemblyLine, AssemblyLine."Quantity per" + LibraryRandom.RandInt(5));

        // Exercise: Explode Assembly List for the child Assembly Item
        AssemblyLine.ExplodeAssemblyList();

        // Verify: Find the first exploded Assembly Line and verify Quantity and Cost Amount on it
        FindBOMComponent(BOMComponent, Item2."No.", BOMComponent.Type::Item); // Find the 1st BOM Component for child Assembly Item
        FindAssemblyOrderLine(AssemblyLine2, AssemblyHeader."No.", BOMComponent."No.");
        VerifyQuantityAndCostAmountOnAssemblyLine(
          AssemblyLine2, BOMComponent."Quantity per" * AssemblyLine."Quantity per" * AssemblyLine."Qty. per Unit of Measure",
          AssemblyHeader.Quantity);
    end;

    [Test]
    [HandlerFunctions('CalculateStandardCostMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcStandardCostonOnAssemblyItem()
    var
        AssemblyItem: Record Item;
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        BOMComponent: Record "BOM Component";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        QuantityPer: Decimal;
    begin
        // Test and verify Calc. Standard Cost is working on Assembly Item when the Assembly BOM
        // contains the Item whose Production BOM contains another Production BOM.

        // Setup: Create ChildItem as component item for Production BOM.
        Initialize();
        QuantityPer := LibraryRandom.RandInt(5);

        CreateAndUpdateItem(
          ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Costing Method"::Standard,
          LibraryRandom.RandInt(10));
        CreateAndCertifyProductionBOM(
          ProductionBOMHeader, ChildItem."Base Unit of Measure",
          ProductionBOMLine.Type::Item, ChildItem."No.", QuantityPer);

        // Create Item.
        CreateAndUpdateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Costing Method"::Standard, 0);

        // Create Production BOM that contains a Production BOM. Set Production BOM No. to Item
        CreateCertifiedProductionBOMAndUpdateItem(
          ProductionBOMHeader, ParentItem."No.", ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader."No.", QuantityPer);

        // Create Assembly Item and add Item to Assembly BOM.
        CreateAndUpdateItem(
          AssemblyItem, AssemblyItem."Replenishment System"::Assembly, AssemblyItem."Costing Method"::Standard, 0);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ParentItem."No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type",
          QuantityPer, true); // Use Base Unit of Measure as True and Variant Code as blank.

        // Exercise: Calculate Standard Cost.
        LibraryVariableStorage.Enqueue(2); // Choose "All Level" when Calculate Standard Cost.
        LibraryVariableStorage.Enqueue(CalcStandardCostMsg);
        CalculateStandardCost.CalcItem(AssemblyItem."No.", true);

        // Verify: Verify Standard Cost calculated correctly without error message.
        // There are three levels of components. Each level has Quantity per. So use third power of QuantityPer.
        VerifyStandardCostOnAssemblyItem(AssemblyItem."No.", Power(QuantityPer, 3) * ChildItem."Standard Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderWithDimensionAfterExplodeBOM()
    var
        AssemblyItem: Record Item;
        AssemblyItem2: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // Test and verify no error pops up when posting Assembly Order with Dimension after explode BOM.

        // Setup: Create Assembly Items and create their BOM components.
        Initialize();
        CreateTwoAssemblyItemsAndBOMComponentsSetup(AssemblyItem, AssemblyItem2);

        // Create Assembly Order and explode BOM. Add inventory for Component Item.
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), AssemblyItem2."No.", '', LibraryRandom.RandInt(5), '');

        FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", AssemblyItem."No.");
        AssemblyLine.ExplodeAssemblyList();
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), LibraryRandom.RandInt(5));

        // Exercise and Verify: Assembly Order can be posted.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderForAssemblyItemWithUpdatedPostingDate()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Test and verify the Posting Date on Assembly order will be updated when the Posting Date on the related Sales Order is updated.

        // Setup: Create Sales Order for Assembly Item and fill Qty. to Assemble to Order
        CreateSalesOrderWithAssemblyItem(SalesLine);

        // Exercise: Update Posting Date on Sales Header
        UpdatePostingDateOnSalesHeader(
          SalesHeader, SalesLine."Document Type", SalesLine."Document No.",
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // Verify: Verify the Posting Date on Assembly Order is updated accordingly
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, SalesLine."No.");
        AssemblyHeader.TestField("Posting Date", SalesHeader."Posting Date");

        // Exercise: Post Sales Document
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Posting Date on Assembly Output Entry equals to the Posting Date of Sales Header
        VerifyPostingDateOnItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Assembly Output", SalesLine."No.", SalesHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ModifyPostingDateOnAssemblyOrder()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        AssemblyOrder: TestPage "Assembly Order";
    begin
        // Test and verify the Posting Date on Assembly Order cannot be later than the Posting Date of its related Sales Order

        // Setup: Create Sales Order for Assembly Item and fill Qty. to Assemble to Order
        Initialize();
        CreateSalesOrderWithAssemblyItem(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Open the Assembly Order linked to above Sales Order
        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("Item No.", SalesLine."No.");

        // Exercise: Modify the Posting Date on Assembly Order to make it later than the Posting Date of Sales Header
        asserterror AssemblyOrder."Posting Date".SetValue(
            CalcDate('<+' + Format(LibraryRandom.RandInt(5)) + 'D>', SalesHeader."Posting Date"));

        // Verify: Check the error message
        Assert.ExpectedError(StrSubstNo(PostingDateLaterErr, AssemblyOrder."No.", SalesHeader."No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdatePostingDateOnSalesHeaderAndCreateSalesLineForAssemblyItem()
    var
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        PostingDate: Date;
    begin
        // Test and verify the Posting Date on Assembly Order will be the same as the Posting Date on the related Sales Header
        // when the Posting Date on Sales Header is updated before Assembly Order is created.

        // Setup: Create Sales Order for Assembly Item and update Posting Date
        Initialize();
        CreateAssemblyItem(Item);
        PostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        CreateSalesOrderWithPostingDate(SalesLine, Item."No.", PostingDate);

        // Exercise: Generate an Assembly Order on Sales Line
        UpdateQtyToAssembleOnSalesLine(SalesLine, SalesLine.Quantity);

        // Verify: Verify the Posting Date on Assembly Order is same as the Posting Date on the related Sales Header
        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, SalesLine."No.");
        AssemblyHeader.TestField("Posting Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ManualCostAdjustmentOnRepostedSalesShipment()
    begin
        CostAdjustmentOnRepostedSalesOrderWithDifferentAssemblies(false, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ManualCostAdjustmentOnRepostedSalesShipmentAndInvoice()
    begin
        CostAdjustmentOnRepostedSalesOrderWithDifferentAssemblies(true, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AutoCostAdjustmentOnRepostedSalesShipment()
    begin
        CostAdjustmentOnRepostedSalesOrderWithDifferentAssemblies(false, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AutoCostAdjustmentOnRepostedSalesShipmentAndInvoice()
    begin
        CostAdjustmentOnRepostedSalesOrderWithDifferentAssemblies(true, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineWithAssemblyOrder()
    var
        AsmItemNo: Code[20];
        Quantity: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Test and verify Sales Shipment Line with Assembly Item can be undone successfully when
        // the component Item on Assembly Order Line haven't been fully consumed.

        // Setup: General preparation for Undo Sales Shipment.
        Initialize();
        PostedDocumentNo := GeneralPreparationForUndoSalesShipmentLineWithAssemblyOrder(AsmItemNo, Quantity);

        // Exercise: Undo Sales Shipment.
        UndoSalesShipmentLine(PostedDocumentNo);

        // Verify: Undo Sales Shipment Line successfully. Check the Quantity is correct.
        VerifySalesShipmentLines(PostedDocumentNo, AsmItemNo, Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityOnSalesLineDetailsFactBoxWithReservation()
    var
        SalesLine: Record "Sales Line";
        Qty: Decimal;
    begin
        // Setup: Create Item,Positive Adjustment.
        // Excercise: Create Sales Order,Reserve Quantity As Auto Reserve.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(5, 10); // Quantity is more than Sales Line Quantity required for test.
        CreateSalesOrderWithReservation(SalesLine, Qty, LibraryRandom.RandInt(5));

        // Verify: Verify the Availability on Sales Line Details FactBox of Sales Order page.
        VerifyAvailabilityOnSalesOrderPage(SalesLine."Document No.", SalesLine."No.", Qty - SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailabilityWindowHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithReservation()
    var
        AssemblyHeader: Record "Assembly Header";
        ParentItemNo: Code[20];
    begin
        // Setup: Create Assembly BOM with one Component. Create Assembly Order, Create and post Purchase Order for Component.
        // Reserve for Component from Item Ledger Entry. Create a Purchase Order.
        ParentItemNo := InitSetupForAssemlyOrderAndPurchaseOrder();

        // Exercise: Create another Assembly Order.
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), ParentItemNo, '', LibraryRandom.RandInt(5), '');

        // Verify: Verify values on Assembly Availability of Assembly Order through AvailabilityWindowHandler.
        OpenAssemblyAvailabilityPage(AssemblyHeader."No.");
        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostAssemblyOrderWithApplToItemEntry()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Test and verify Appl.-to Item Entry is correct in Item Ledger Entry when Assembly Order is posted.
        // Setup: Create Assembly Item, create Assembly Order, add component inventory for Assembly Order, set Appl.-to Item Entry on Assembly Line.
        Initialize();
        CreateAssemblyItemAndOrderWithCompInventory(AssemblyHeader);

        // Find the 1st Assembly Line of Item Type, set "Appl.-to Item Entry" on Assembly Line to "Positive Adjmt." ILE No. of the component Item.
        UpdateApplToItemEntryOnAssemblyLine(AssemblyLine, AssemblyHeader."Item No.");

        // Exercise.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify: "Applies-to Entry" field on Item Ledger Entry is correct.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Assembly Consumption", AssemblyLine."No.");
        Assert.AreEqual(AssemblyLine."Appl.-to Item Entry", ItemLedgerEntry."Applies-to Entry", AppliesToEntryErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcInvtValueOnRevaluationJournalAfterUndoPostedAssemblyOrder()
    var
        ComponentItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        AssemblyItemNo: Code[20];
    begin
        // Test and verify Order Type is correct on Item Journal Line after running "Calc. Inventory Value" from Revaluation Journal for undone posted Assembly Order.

        // Setup: Create Assembly Item with component, create and post Assembly Order, undo the posted Assembly Order.
        Initialize();
        AssemblyItemNo := PostAssemblyOrderAndUndoPost();
        GetItemFromBOMComponent(ComponentItem, AssemblyItemNo);

        // Exercise: Create Revaluation Journal Lines by running "Calc. Inventory Value".
        CreateRevaluationJournal(ComponentItem."No.", "Inventory Value Calc. Per"::"Item Ledger Entry");

        // Verify: Verify the Order Type on Item Journal Line.
        VerifyOrderTypeOnItemJournalLine(
          ItemJournalLine."Entry Type"::"Assembly Consumption", ComponentItem."No.", ItemJournalLine."Order Type"::Assembly);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ItemJournalApplToUndoneAssemblyConsumptionLine()
    var
        ComponentItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        AssemblyItemNo: Code[20];
        EntryType: Enum "Item Ledger Document Type";
    begin
        // Test and verify Applies-to Entry is correct on Item Ledger Entry after posting Item Journal that apply to undone Assembly Consumption Line from ILE page.

        // Setup: Create Assembly Item with component, create and post Assembly Order, undo the posted Assembly Order.
        Initialize();
        AssemblyItemNo := PostAssemblyOrderAndUndoPost();
        GetItemFromBOMComponent(ComponentItem, AssemblyItemNo);

        ItemLedgerEntry.SetRange(Correction, true);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Assembly Consumption", ComponentItem."No.");

        // Exercise: Create and Post Item Journal Line Appl. to the Undone Assembly Consumption Line.
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No."); // Enqueue the value for ItemLedgerEntriesPageHandler.
        CreateAndPostItemJournalApplToEntry(EntryType, ComponentItem."No.", LibraryRandom.RandInt(10));

        // Verify: Verify the Applies-to Entry on Item Ledger Entry.
        VerifyApplToEntryOnILE(EntryType, ComponentItem."No.", ItemLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure InsertSalesLineToFullConsumeItemWithExistingReservation()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Qty: Decimal;
        PartialQty: Decimal;
    begin
        // Setup: Create Item,Positive Adjustment. Create Sales Order with partial Reservation.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(5, 10);
        PartialQty := Qty - LibraryRandom.RandInt(5);
        CreateSalesOrderWithReservation(SalesLine, Qty, PartialQty);

        // Exercise: Create another Sales Line and update the Quantity by page. Check Availability window does not pop up.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", 0);
        UpdateQuantityOnSalesLineByPage(SalesHeader."No.", Qty - PartialQty, SalesLine.Quantity); // Required for test.

        // Verify: Verify the Availability on Sales Line Details FactBox of Sales Order page.
        VerifyAvailabilityOnSalesOrderPage(SalesLine."Document No.", SalesLine."No.", 0); // Item was full consumed.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SoldAssemblyItemIsCostAdjustedWhenAverageCostHasChanged()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        ParentItemQuantity: Decimal;
        ComponentItemQuantity: Decimal;
        DirectCost1: Decimal;
        DirectCost2: Decimal;
    begin
        // [FEATURE] [Assembly] [Adjust Cost]
        // [SCENARIO 363427] Sold Assembly Item using Average costing method is Cost Adjusted when the Average Cost of the period has changed
        Initialize();

        // [GIVEN] Component Item and Parent Item with costing method = "Average"
        ParentItemQuantity := LibraryRandom.RandDec(10, 2);
        ComponentItemQuantity := LibraryRandom.RandDec(10, 2);
        CreateAssemblyItemAndComponentItem(ParentItem, ComponentItem, ComponentItemQuantity / ParentItemQuantity);

        // [GIVEN] Purchase Order for Component Item with Direct Cost = "X"
        DirectCost1 := LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrderWithDirectCost(ComponentItem."No.", ComponentItemQuantity, DirectCost1);

        // [GIVEN] Assembly Oder for Parent Item
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), ParentItem."No.", '', ParentItemQuantity, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Sales Order for Parent Item
        CreateAndPostSalesOrder(SalesLine, WorkDate(), ParentItem."No.", ParentItemQuantity, false);

        // [GIVEN] Adjust Cost Item Entries
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ParentItem."No.", ComponentItem."No."), '');

        // [GIVEN] Purchase Order for Component Item with Direct Cost = "Y"
        DirectCost2 := LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrderWithDirectCost(ComponentItem."No.", ComponentItemQuantity, DirectCost2);

        // [WHEN] Run Adjust Cost Item Entries
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ParentItem."No.", ComponentItem."No."), '');

        // [THEN] Both Item Ledger Entries of Parent item has Cost Amount (Actual) adjusted
        VerifyItemLedgerEntries(ParentItem."No.", ComponentItemQuantity * (DirectCost1 + DirectCost2) / 2); // 2 - Number of ILE
    end;

    [Test]
    [HandlerFunctions('CalculateStandardCostMenuHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderCreatedOnExplodeBOMForAssembleToOrderComponent()
    var
        Item: Record Item;
        ComponentItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
    begin
        // [FEATURE] [Assemble-to-Order] [Explode BOM]
        // [SCENARIO 230194] Assembly order should be automatically created for an "Assemble-to-Order" component of an assembled item on running "Explode BOM" in sales order

        Initialize();

        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Assembled item "I" with a component "C" that is also assembled and has assembly policy "Assemble to order"
        CreateAssemblyItem(Item);
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        BOMComponent.FindFirst();
        ComponentItem.Get(BOMComponent."No.");
        ComponentItem.Validate("Replenishment System", ComponentItem."Replenishment System"::Assembly);
        ComponentItem.Validate("Assembly Policy", ComponentItem."Assembly Policy"::"Assemble-to-Order");
        ComponentItem.Modify(true);

        // [GIVEN] Create sales order for the item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        LibraryVariableStorage.Enqueue(1);  // Enqueue the option value for the CalculateStandardCostMenuHandler

        // [WHEN] Run "Explode BOM" on the sales line
        CODEUNIT.Run(CODEUNIT::"Sales-Explode BOM", SalesLine);

        // [THEN] Linked assembly order is created for the component "C"
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ComponentItem."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Qty. to Assemble to Order", SalesLine.Quantity);
        LibraryAssembly.FindLinkedAssemblyOrder(AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        AssemblyHeader.TestField("Item No.", ComponentItem."No.");
    end;

    [Test]
    [HandlerFunctions('GenericMessageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentWithAssemblyItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        Location: Record Location;
        Bin: Record Bin;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Undo Shipment] [Undo Assembly] [Resource]
        // [SCENARIO 254152] Cancelling (undo) shipment that contains assembly items mustn't lead to error

        Initialize();

        // [GIVEN] Create an Item with a Resource as a BOM Component.
        CreateItemWithAssemblyBOM(Item);

        // [GIVEN] Create SILVER location
        CreateSilverLocation(Location, Bin);

        // [GIVEN] Create Sales Order with 2 similiar lines and post it only as Shipment
        CreateSalesOrderWithTwoLinesAndPostShipment(
          SalesHeader, Location.Code, Bin.Code, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Undo all lines in the shipment
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        UndoSalesShipmentLine(SalesShipmentHeader."No.");

        // [THEN] No errors occurs. And Quantity field sum by all Item Ledger Entries must be zero - shipment has been undone.
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.SetRange("Document No.", SalesShipmentHeader."No.");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(0, ItemLedgerEntry.Quantity, UndoShpmtNotCompleteErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AsmOutputWithZeroInventoryValueNotUpdatedByACIE()
    var
        ComponentItem: Record Item;
        AsmItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Adjust Cost - Item Entries] [Inventory Value Zero]
        // [SCENARIO 271008] "Adjust Cost - Item Entries" does not update cost amount for an assembly output entry if the assembled item has "Inventory Value Zero" option enabled

        Initialize();

        // [GIVEN] Item "C" used as an assembly component
        LibraryInventory.CreateItem(ComponentItem);

        // [GIVEN] Assembled item "A" with item "C" as a component. "Inventory Value Zero" is enabled for item "A"
        Qty := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, ComponentItem."No.", 1, ComponentItem."Base Unit of Measure");

        AsmItem.Validate("Inventory Value Zero", true);
        AsmItem.Modify(true);

        // [GIVEN] Place some stock of the item "C" on location with unit cost "X" LCY
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ComponentItem."No.", '', '', Qty);
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(500, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create and post an assembly order for the item "A"
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), AsmItem."No.", '', Qty, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [WHEN] Run cost adjustment for both items
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', AsmItem."No.", ComponentItem."No."), '');

        // [THEN] Unit cost of the assembly output is 0
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Assembly Output", AsmItem."No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Expected)", 0);
        ItemLedgerEntry.TestField("Cost Amount (Actual)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAdjustmentDoesNotPostZeroAmountEntry()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Adjust Cost - Item Entries]
        // [SCENARIO 282984] Cost adjustment does not post an adjustment entry when adjustment amount is 0.
        Initialize();

        // [GIVEN] Assembled item "ASM" with Standard costing method and standard cost = 20 LCY.
        CreateAndUpdateItem(AsmItem, AsmItem."Replenishment System"::Assembly, AsmItem."Costing Method"::Standard, 20);

        // [GIVEN] Purchased item "COMP" with Standard costing method and standard cost = 10 LCY.
        // [GIVEN] Sufficient quantity of "COMP" is in inventory.
        CreateAndUpdateItem(CompItem, CompItem."Replenishment System"::Purchase, CompItem."Costing Method"::Standard, 10);
        MakeItemStock(CompItem."No.", LibraryRandom.RandIntInRange(50, 100), CompItem."Standard Cost");

        // [GIVEN] Set "COMP" as a BOM component of "ASM" with Quantity per = 2.
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, CompItem."No.", AsmItem."No.", '', 0, 2, true);

        // [GIVEN] Create and post assembly order for item "ASM", Quantity = 1
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, LibraryRandom.RandDate(10), AsmItem."No.", '', 1, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [WHEN] Run "Adjust Cost - Item Entries".
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', AsmItem."No.", CompItem."No."), '');

        // [THEN] No adjustment entries have been posted.
        ValueEntry.SetRange("Item No.", AsmItem."No.");
        ValueEntry.SetRange(Adjustment, true);
        Assert.RecordIsEmpty(ValueEntry);
    end;

    [Test]
    [HandlerFunctions('GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure LastDirectCostOfATOOutputItemWithNotStdCostingMethodUpdatedOnPosting()
    var
        CompItem: Record Item;
        AsmItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QtyPer: Decimal;
        CompUnitCost: Decimal;
    begin
        // [FEATURE] [Assemble-to-Order] [Last Direct Cost]
        // [SCENARIO 282770] Posting a sales order with linked assembly calculates Last Direct Cost of the assembled item as the sum of consumed components, if the item has Costing Method different from "Standard".
        Initialize();

        QtyPer := LibraryRandom.RandInt(10);
        CompUnitCost := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Assemble-to-order item "A" with 10 pcs of item "C" as a component.
        // [GIVEN] "A"."Unit Cost" = 2000 LCY.
        CreateAssemblyItemAndComponentItem(AsmItem, CompItem, QtyPer);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Validate("Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        AsmItem.Modify(true);

        // [GIVEN] Post sufficient stock of component item "C" with unit cost 5 LCY.
        MakeItemStock(CompItem."No.", LibraryRandom.RandIntInRange(100, 200), CompUnitCost);

        // [GIVEN] Sales order with linked assembly order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", LibraryRandom.RandInt(10));
        UpdateQtyToAssembleOnSalesLine(SalesLine, SalesLine.Quantity);

        // [WHEN] Post the sales order. The assembly is posted automatically on the background.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Last Direct Cost of assembled item "A" is equal to 50 LCY (10 * 5 LCY).
        AsmItem.Find();
        AsmItem.TestField("Last Direct Cost", QtyPer * CompUnitCost);
    end;

    [Test]
    [HandlerFunctions('GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure LastDirectCostOfATOOutputItemWithStdCostingMethodNotUpdatedOnPosting()
    var
        CompItem: Record Item;
        AsmItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QtyPer: Decimal;
    begin
        // [FEATURE] [Assemble-to-Order] [Last Direct Cost]
        // [SCENARIO 282770] Posting a sales order with linked assembly makes Last Direct Cost of the assembled item equal to Standard Cost, if the item has Costing Method = "Standard".
        Initialize();

        QtyPer := LibraryRandom.RandInt(10);

        // [GIVEN] Assemble-to-order item "A" with 10 pcs of item "C" as a component.
        // [GIVEN] Item "A" has Costing Method = Standard. Standard cost = 2000 LCY.
        CreateAssemblyItemAndComponentItem(AsmItem, CompItem, QtyPer);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Validate("Costing Method", AsmItem."Costing Method"::Standard);
        AsmItem.Validate("Standard Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        AsmItem.Modify(true);

        // [GIVEN] Post sufficient stock of component item "C" with unit cost 5 LCY.
        MakeItemStock(CompItem."No.", LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Sales order with linked assembly order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", LibraryRandom.RandInt(10));
        UpdateQtyToAssembleOnSalesLine(SalesLine, SalesLine.Quantity);

        // [WHEN] Post the sales order. The assembly is posted automatically on the background.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Last Direct Cost of assembled item "A" is equal to 2000 LCY (standard cost).
        AsmItem.Find();
        AsmItem.TestField("Last Direct Cost", AsmItem."Standard Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemCardReplenishmentSystemFieldDoesNotChange_AfterAssemblyBOMPageOpenAndClose()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        AssemblyBOM: TestPage "Assembly BOM";
    begin
        // [FEATURE] [Item Card] [Assembly BOM]
        // [SCENARIO 449833] Check that "Replenishment System" and "Assembly BOM" values in "Item Card" are not changed after opening "Assembly BOM" page without insering BOM Component.
        Initialize();

        // [GIVEN] Create Item with "Replenishment System" = Purchase
        LibraryInventory.CreateItem(Item);
        Item."Replenishment System" := Item."Replenishment System"::Purchase;
        Item.Modify();
        Commit();

        // [GIVEN] Open "Item Card"
        ItemCard.OpenView();
        ItemCard.GoToKey(Item."No.");

        // [GIVEN] Open "Assembly BOM" page
        AssemblyBOM.Trap();
        ItemCard."Assembly BOM".Invoke();

        // [WHEN] Move to "No." field to try to insert record and close "Assembly BOM" page
        AssemblyBOM."No.".Activate();
        AssemblyBOM.Description.SetValue('');
        AssemblyBOM.Close();

        // [THEN] Verify that "Replenishment System" and "Assembly BOM" values are not changed
        ItemCard."Replenishment System".AssertEquals(Item."Replenishment System"::Purchase);
        ItemCard.AssemblyBOM.AssertEquals(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure VerifyConsumedQtyIsKeptOnAssemblyLinesOnRefreshLineAction()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyItem: Record Item;
        TempAssemblyLine: Record "Assembly Line" temporary;
        ComponentItem: array[2] of Record Item;
        AssemblyBOM: TestPage "Assembly BOM";
        AssemblyOrder: TestPage "Assembly Order";
    begin
        // [SCENARIO 461537] Verify Consumed Qty. is kept on Assembly Lines on Refresh Line action
        Initialize();

        // [GIVEN] Create an assembled item "I" with two components
        CreateItem(AssemblyItem, AssemblyItem."Costing Method"::Standard, AssemblyItem."Replenishment System"::Assembly,
            AssemblyItem."Reordering Policy"::"Fixed Reorder Qty.", 0, 99, 300);
        CreateItem(ComponentItem[1], ComponentItem[1]."Costing Method"::Standard, ComponentItem[1]."Replenishment System"::Purchase,
            ComponentItem[1]."Reordering Policy"::"Fixed Reorder Qty.", 6, 99, 300);
        CreateItem(ComponentItem[2], ComponentItem[2]."Costing Method"::Standard, ComponentItem[2]."Replenishment System"::Purchase,
            ComponentItem[2]."Reordering Policy"::"Fixed Reorder Qty.", 6, 99, 300);

        // [GIVEN] Create Assembly BOM
        CreateAssemblyBomComponent(ComponentItem[1], AssemblyItem."No.", 1);
        CreateAssemblyBomComponent(ComponentItem[2], AssemblyItem."No.", 1);

        // [GIVEN] Open Assembly BOM and Calc. Standard Cost
        CalculateStandardCostOnAssemblyBOM(AssemblyBOM, AssemblyItem."No.");

        // [GIVEN] Post Component Items
        CreateAndPostItemJournalLine(ComponentItem[1]."No.", 100, '');
        CreateAndPostItemJournalLine(ComponentItem[2]."No.", 100, '');

        // [GIVEN] Create Assembly Order
        CreateAssemblyOrder(AssemblyHeader, AssemblyItem."No.", 6);

        // [GIVEN] Post Assembly Order
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 100, 100, true);

        // [GIVEN] Reopen Assembly Order
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryAssembly.ReopenAO(AssemblyHeader);

        // [WHEN] Open Assembly Order and Refresh Lines
        AssemblyOrder.OpenEdit();
        AssemblyOrder.Filter.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrder."Refresh Lines".Invoke();

        // [THEN] Verify Consumed Qty. on Assembly Lines
        VerifyAssemblyLine(AssemblyHeader, 6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimensionsOnAssemblyOrderAfterExplodeBOM()
    var
        DefaultDimension: Record "Default Dimension";
        AssemblyItem: Record Item;
        AssemblyItem2: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [SCENARIO 466770] Dimensions not added when inserting a new line in Assembly Order

        // [GIVEN] Setup: Create Assembly Items and create their BOM components.
        Initialize();
        CreateAssemblyItemsAndBOMComponentsWithDefaultDimension(AssemblyItem, AssemblyItem2, DefaultDimension);

        // [GIVEN] Create Assembly Order and explode BOM. Add inventory for Component Item.
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), AssemblyItem2."No.", '', LibraryRandom.RandInt(5), '');
        FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", AssemblyItem."No.");

        // [THEN] Explode the Assembly List
        AssemblyLine.ExplodeAssemblyList();
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), LibraryRandom.RandInt(5));

        // [VERIFY] Verify: Default Dimension on Assembly Line
        VerifyJobTaskDimensionOnRequisitionLine(AssemblyLine, DefaultDimension);
    end;

    [Test]
    procedure PostingDateModifiesDocumentDate()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseOrder: Record "Purchase Header";
        PurchaseReturnOrder: Record "Purchase Header";
        PurchaseInvoice: Record "Purchase Header";
        PurchaseCreditMemo: Record "Purchase Header";
        DocDate, PostingDate : Date;
    begin
        // [SCENARIO] Check that the PurchasesPayablesSetup."Link Doc. Date To Posting Date" setting has the correct effect on purchase documents when set to true

        // [GIVEN] Change the setting to true
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Create purchase documents and set the document date
        DocDate := 20000101D;
        LibraryPurchase.CreatePurchHeader(PurchaseOrder, "Purchase Document Type"::"Order", '');
        PurchaseOrder.Validate("Document Date", DocDate);
        LibraryPurchase.CreatePurchHeader(PurchaseReturnOrder, "Purchase Document Type"::"Return Order", '');
        PurchaseReturnOrder.Validate("Document Date", DocDate);
        LibraryPurchase.CreatePurchHeader(PurchaseInvoice, "Purchase Document Type"::"Invoice", '');
        PurchaseInvoice.Validate("Document Date", DocDate);
        LibraryPurchase.CreatePurchHeader(PurchaseCreditMemo, "Purchase Document Type"::"Credit Memo", '');
        PurchaseCreditMemo.Validate("Document Date", DocDate);

        // [WHEN] The posting date is modified
        PostingDate := 30000101D;
        PurchaseOrder.Validate("Posting Date", PostingDate);
        PurchaseReturnOrder.Validate("Posting Date", PostingDate);
        PurchaseInvoice.Validate("Posting Date", PostingDate);
        PurchaseCreditMemo.Validate("Posting Date", PostingDate);

        // [THEN] The document date should be modified
        PurchaseOrder.TestField("Document Date", PostingDate);
        PurchaseReturnOrder.TestField("Document Date", PostingDate);
        PurchaseInvoice.TestField("Document Date", PostingDate);
        PurchaseCreditMemo.TestField("Document Date", PostingDate);
    end;

    [Test]
    procedure PostingDateDoesNotModifiesDocumentDate()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseOrder: Record "Purchase Header";
        PurchaseReturnOrder: Record "Purchase Header";
        PurchaseInvoice: Record "Purchase Header";
        PurchaseCreditMemo: Record "Purchase Header";
        DocDate, PostingDate : Date;
    begin
        // [SCENARIO] Check that the PurchasesPayablesSetup."Link Doc. Date To Posting Date" setting has the correct effect on Purchase documents when set to false

        // [GIVEN] Change the setting to false
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", false);
        PurchasesPayablesSetup.Modify();

        // [GIVEN] Create Purchase documents and set the document date
        DocDate := 20000101D;
        LibraryPurchase.CreatePurchHeader(PurchaseOrder, "Purchase Document Type"::"Order", '');
        PurchaseOrder.Validate("Document Date", DocDate);
        LibraryPurchase.CreatePurchHeader(PurchaseReturnOrder, "Purchase Document Type"::"Return Order", '');
        PurchaseReturnOrder.Validate("Document Date", DocDate);
        LibraryPurchase.CreatePurchHeader(PurchaseInvoice, "Purchase Document Type"::"Invoice", '');
        PurchaseInvoice.Validate("Document Date", DocDate);
        LibraryPurchase.CreatePurchHeader(PurchaseCreditMemo, "Purchase Document Type"::"Credit Memo", '');
        PurchaseCreditMemo.Validate("Document Date", DocDate);

        // [WHEN] The posting date is modified
        PostingDate := 30000101D;
        PurchaseOrder.Validate("Posting Date", PostingDate);
        PurchaseReturnOrder.Validate("Posting Date", PostingDate);
        PurchaseInvoice.Validate("Posting Date", PostingDate);
        PurchaseCreditMemo.Validate("Posting Date", PostingDate);

        // [THEN] The document date should not be modified
        PurchaseOrder.TestField("Document Date", DocDate);
        PurchaseReturnOrder.TestField("Document Date", DocDate);
        PurchaseInvoice.TestField("Document Date", DocDate);
        PurchaseCreditMemo.TestField("Document Date", DocDate);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting");

        UpdateStockOutWarningOnAssemblySetup(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        NoSeriesSetup();
        LocationSetup();
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting");
    end;

    local procedure NoSeriesSetup()
    var
        AssemblySetup: Record "Assembly Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Released Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ManufacturingSetup.Modify(true);
    end;

    local procedure LocationSetup()
    begin
        CreateAndUpdateLocation(LocationBlack);
        CreateAndUpdateLocation(LocationRed);
    end;

    local procedure CostAdjustmentOnRepostedSalesOrderWithDifferentAssemblies(Invoice: Boolean; AutoAdjust: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        UpdatedCostAmount: Decimal;
    begin
        // Setup: Create Assembly Item, create Sales Order for Assembly Item, post shipment for sales order, then undo sales shipment.
        Initialize();
        if AutoAdjust then begin
            LibraryVariableStorage.Enqueue(UnadjustedValueEntriesNotCoveredMessage);
            SetupAutomaticCostAdjustment();
        end;
        CreateSalesOrderWithAssemblyItemAndUndoSalesShipment(SalesLine, Item."Costing Method"::Average, AutoAdjust);

        // Update QtyPer on Assembly Line and post sales shipment or "ship and invoice".
        UpdateQtyPerOnAssemblyLineAndPostSalesDocument(SalesLine, true, Invoice);

        // Exercise: Run Adjust Cost - Item Entries batch job for the Assembly Item.
        if not AutoAdjust then
            LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');

        // Verify: Six Item Ledger entries for Assembly Item are generated.
        // For the first four entries, "Cost Amount(Actual)" for these entries should be +/- Standard Cost of Assembly Item.
        // For the last two entries, "Cost Amount(Actual)" for "Assembly Output" should be updated "Cost Amount" of Assembly Order
        // "Cost Amount(Expected)" for "Sales" should be negative of updated "Cost Amount".
        UpdatedCostAmount := CalcPostedAssemblyHeaderActualCostAmount(SalesLine."No.");

        VerifyCostAmountActualForAssemblyOutputAndSaleILE(SalesLine."No.", UpdatedCostAmount);
        VerifyCostAmountInLastILE(ItemLedgerEntry."Entry Type"::"Assembly Output", SalesLine."No.", 0, UpdatedCostAmount);

        // Verify Cost Amount of ILE of Sales generated by posting the sales order after updating Qty Per on Assembly line
        if Invoice then
            VerifyCostAmountInLastILE(ItemLedgerEntry."Entry Type"::Sale, SalesLine."No.", 0, -UpdatedCostAmount)
        else
            VerifyCostAmountInLastILE(ItemLedgerEntry."Entry Type"::Sale, SalesLine."No.", -UpdatedCostAmount, 0);
    end;

    local procedure AddAssemblyComponentItemWithDimension(var AssemblyComponentItem: Record Item; var ComponentItem: Record Item; AssemblyItemNo: Code[20]; Quantity: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateItemWithDimension(AssemblyComponentItem, AssemblyComponentItem."Replenishment System"::Assembly);
        CreateItemWithDimension(ComponentItem, ComponentItem."Replenishment System"::Purchase);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", AssemblyComponentItem."No.", '', BOMComponent."Resource Usage Type",
          Quantity, true);  // Use Base Unit of Measure as True.
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, AssemblyComponentItem."No.", AssemblyItemNo, '', BOMComponent."Resource Usage Type", Quantity, true);  // Use Base Unit of Measure as True.
    end;

    local procedure AddItemToAssemblyBOM(Item: Record Item; WithSalesPrice: Boolean)
    var
        BOMComponent: Record "BOM Component";
        Item2: Record Item;
    begin
        if WithSalesPrice then
            CreateItemWithSalesPrice(Item2, Item)
        else
            CreateItemWithSalesLineDiscount(Item2, Item);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item2."No.", Item."No.", '', BOMComponent."Resource Usage Type", LibraryRandom.RandInt(5), true);  // Use Base Unit of Measure as True and Variant as blank.
    end;

    local procedure AddResourceToAssemblyBOM(Item: Record Item; WithResourcePrice: Boolean)
    var
        BOMComponent: Record "BOM Component";
        Resource: Record Resource;
        ResourcePrice: Record "Resource Price";
    begin
        LibraryAssembly.CreateResource(Resource, false, Item."Gen. Prod. Posting Group");
        if WithResourcePrice then begin
            LibraryResource.CreateResourcePrice(ResourcePrice, ResourcePrice.Type::Resource, Resource."No.", '', '');  // Use blank for Work Type and Currency Code.
            ResourcePrice.Validate("Unit Price", Resource."Unit Price" + LibraryRandom.RandDec(100, 2));  // Use Different Resource Price.
            ResourcePrice.Modify(true);
        end;
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", Item."No.", '', BOMComponent."Resource Usage Type"::Direct,
          LibraryRandom.RandInt(5), true);  // Use Base Unit of Measure as True and Variant as blank.
    end;

    local procedure CalculateDateUsingDefaultSafetyLeadTime(): Date
    begin
        exit(LibraryPlanning.SetSafetyWorkDate());
    end;

    local procedure CalculateStandardCostOnAssemblyBOM(var AssemblyBOM: TestPage "Assembly BOM"; ItemNo: Code[20])
    begin
        OpenAssemblyBOMFromItemCard(AssemblyBOM, ItemNo);
        AssemblyBOM.CalcStandardCost.Invoke();
    end;

    local procedure CalcPostedAssemblyHeaderActualCostAmount(ItemNo: Code[20]): Decimal
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        ActualCosts: array[5] of Decimal;
    begin
        PostedAssemblyHeader.SetRange("Item No.", ItemNo);
        PostedAssemblyHeader.FindFirst();

        PostedAssemblyHeader.CalcActualCosts(ActualCosts);
        exit(ActualCosts[1] + ActualCosts[2] + ActualCosts[3] + ActualCosts[4] + ActualCosts[5]);
    end;

    local procedure CopyAssemblyBOM(FromParentItemNo: Code[20]; ToParentItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        FindBOMComponents(BOMComponent, FromParentItemNo);
        repeat
            LibraryAssembly.CreateAssemblyListComponent(
              BOMComponent.Type, BOMComponent."No.", ToParentItemNo, BOMComponent."Variant Code", BOMComponent."Resource Usage Type",
              BOMComponent."Quantity per", true);  // Use Base Unit of Measure as True.
        until BOMComponent.Next() = 0;
    end;

    local procedure CreateAndPostAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; AssemblyItemNo: Code[20]; Quantity: Decimal; HeaderQtyFactor: Integer; CompQtyFactor: Integer; UpdateAllComps: Boolean)
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), AssemblyItemNo, '', Quantity, '');
        PrepareAndPostAssemblyOrder(AssemblyHeader, AssemblyLine, HeaderQtyFactor, CompQtyFactor, UpdateAllComps);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; PostingDate: Date; ItemNo: Code[20]; Quantity: Decimal; Reserve: Boolean)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Shipment Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        if Reserve then
            SalesLine.ShowReservation();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as SHIP and INVOICE.
    end;

    local procedure PartialInvoiceSalesOrder(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; Quantity: Decimal)
    begin
        SalesLine.Validate("Qty. to Invoice", Quantity);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; AssemblyOrderNo: Code[20])
    var
        Item: Record Item;
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::"Prod. Order", '', '');
        ReleasedProductionOrder.OpenNew();
        ReleasedProductionOrder."No.".SetValue(AssemblyOrderNo);
        ReleasedProductionOrder."Source No.".SetValue(Item."No.");
        ReleasedProductionOrder.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        ReleasedProductionOrder.OK().Invoke();
        ProductionOrder.Get(ProductionOrder.Status::Released, AssemblyOrderNo);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // Use True for Calculate Lines, Routings and Components.
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
    end;

    local procedure CreateAsmOrderWithMultipleComponentItems(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; Quantity: Decimal; ItemNo2: Code[20]; BaseUnitofMeasure: Code[10])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), ItemNo, '', Quantity, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ItemNo2, BaseUnitofMeasure, Quantity, Quantity, '');
    end;

    local procedure CreateAssemblyItemsAndBOMComponentsSetup(var Item: Record Item; var Item2: Record Item; var Item3: Record Item)
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateAssemblyItem(Item);
        CreateAssemblyItem(Item2);
        CreateAssemblyItem(Item3);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item2."No.", Item."No.", '', BOMComponent."Resource Usage Type", LibraryRandom.RandInt(5), true);  // UseBaseUnitOfMeasure as TRUE.
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item3."No.", Item2."No.", '', BOMComponent."Resource Usage Type", LibraryRandom.RandInt(5), true);  // UseBaseUnitOfMeasure as TRUE.
    end;

    local procedure CreateAssemblyItemAndBOMComponentSetup(var ChildItem: Record Item; var ParentItem: Record Item)
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateAndUpdateItem(
          ChildItem, ChildItem."Replenishment System"::Assembly, ChildItem."Costing Method"::FIFO,
          LibraryRandom.RandInt(10));
        CreateAndUpdateItem(
          ParentItem, ParentItem."Replenishment System"::Assembly, ParentItem."Costing Method"::FIFO,
          LibraryRandom.RandInt(10));
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ChildItem."No.", ParentItem."No.", '',
          BOMComponent."Resource Usage Type", LibraryRandom.RandInt(10), true);  // UseBaseUnitOfMeasure as TRUE.
    end;

    local procedure CreateTwoAssemblyItemsAndBOMComponentsSetup(var Item: Record Item; var AssemblyItem: Record Item)
    var
        DefaultDimension: Record "Default Dimension";
        BOMComponent: Record "BOM Component";
    begin
        CreateAssemblyItem(Item);
        CreateAssemblyItem(AssemblyItem);
        UpdateItemDimensionWithValuePosting(
          DefaultDimension, AssemblyItem."No.", DefaultDimension."Value Posting"::"Same Code");
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item."No.", AssemblyItem."No.", '',
          BOMComponent."Resource Usage Type", LibraryRandom.RandInt(5), true);
    end;

    local procedure CreateAssemblyItemSetup(var AssemblyItem: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var Resource: Record Resource; AsmItemCostingMethod: Enum "Costing Method"; ComponentItemCostingMethod: Enum "Costing Method") Quantity: Decimal
    var
        BOMComponent: Record "BOM Component";
        ComponentItem: Record Item;
    begin
        LibraryAssembly.CreateItem(ComponentItem, ComponentItemCostingMethod, ComponentItem."Replenishment System"::Purchase, '', '');
        ItemUnitOfMeasure.Get(
          ComponentItem."No.", LibraryAssembly.GetUnitOfMeasureCode(BOMComponent.Type::Item, ComponentItem."No.", false));
        LibraryAssembly.CreateItem(AssemblyItem, AsmItemCostingMethod, AssemblyItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateResource(Resource, false, '');
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type", Quantity, false);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type"::Direct, Quantity, true);  // Use Base Unit of Measure as True.
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::" ", '', AssemblyItem."No.", '', BOMComponent."Resource Usage Type"::Direct, 0, false);  // Use 0 for Quantity per.
    end;

    local procedure CreateAssemblyItemSetupWithDimension(var AssemblyItem: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var Resource: Record Resource) Quantity: Decimal
    var
        ComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        CreateItemWithDimension(ComponentItem, ComponentItem."Replenishment System"::Purchase);
        ItemUnitOfMeasure.Get(
          ComponentItem."No.", LibraryAssembly.GetUnitOfMeasureCode(BOMComponent.Type::Item, ComponentItem."No.", false));
        CreateItemWithDimension(AssemblyItem, AssemblyItem."Replenishment System"::Assembly);
        CreateResourceWithDimension(Resource);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type", Quantity, false);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type"::Direct, Quantity, true);  // Use Base Unit of Measure as True.
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::" ", '', AssemblyItem."No.", '', BOMComponent."Resource Usage Type"::Direct, 0, false);  // Use 0 for Quantity per.
    end;

    local procedure CreateAssemblyItemSetupWithVariant(var AssemblyItem: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var ItemVariant: Record "Item Variant") Quantity: Decimal
    var
        ComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyBOM: TestPage "Assembly BOM";
    begin
        LibraryAssembly.CreateItem(
          ComponentItem, ComponentItem."Costing Method"::Standard, ComponentItem."Replenishment System"::Purchase, '', '');
        ItemUnitOfMeasure.Get(
          ComponentItem."No.", LibraryAssembly.GetUnitOfMeasureCode(BOMComponent.Type::Item, ComponentItem."No.", false));
        LibraryInventory.CreateItemVariant(ItemVariant, ComponentItem."No.");
        CreateMultipleStockkeepingUnit(ComponentItem."No.", LocationBlack.Code, LocationRed.Code);
        LibraryAssembly.CreateItem(
          AssemblyItem, AssemblyItem."Costing Method"::Standard, AssemblyItem."Replenishment System"::Assembly, '', '');
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", AssemblyItem."No.", ItemVariant.Code, BOMComponent."Resource Usage Type",
          Quantity, true);
        CalculateStandardCostOnAssemblyBOM(AssemblyBOM, AssemblyItem."No.");
        AssemblyBOM.CalcUnitPrice.Invoke();
    end;

    local procedure CreateAssemblyOrder(AssemblyOrderNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Init();
        AssemblyHeader.Validate("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.Validate("No.", AssemblyOrderNo);
        AssemblyHeader.Insert(true);
    end;

    local procedure CreateFiscalYearAndInventoryPeriod() PostingDate: Date
    var
        InventoryPeriod: Record "Inventory Period";
    begin
        LibraryFiscalYear.CreateFiscalYear();
        PostingDate := LibraryFiscalYear.GetLastPostingDate(false);
        LibraryInventory.CreateInventoryPeriod(InventoryPeriod, PostingDate);
    end;

    local procedure CreateInitialSetupForPostAsmOrdWithMultipleItems(var AssemblyHeader: Record "Assembly Header"; var AssemblyItem: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Resource: Record Resource;
        ComponentItem: Record Item;
        TempAssemblyLine: Record "Assembly Line" temporary;
        Quantity: Decimal;
    begin
        Quantity :=
          CreateAssemblyItemSetup(
            AssemblyItem, ItemUnitOfMeasure, Resource, AssemblyItem."Costing Method"::Average, AssemblyItem."Costing Method"::Average);
        LibraryAssembly.CreateItem(
          ComponentItem, ComponentItem."Costing Method"::Standard, ComponentItem."Replenishment System"::Purchase, '', '');
        UpdateInventoryForComponentItems(
          ItemUnitOfMeasure."Item No.", Quantity, ItemUnitOfMeasure."Qty. per Unit of Measure", ComponentItem."No.");
        CreateAsmOrderWithMultipleComponentItems(
          AssemblyHeader, AssemblyItem."No.", Quantity, ComponentItem."No.", ComponentItem."Base Unit of Measure");
        AssemblyHeader.UpdateUnitCost();
        PrepareAndPostAssemblyOrder(AssemblyHeader, TempAssemblyLine, 30, 30, false);  // Use 30 for Partial Quantity to Assemble and Quantity to Consume.
    end;

    local procedure PostAssemblyOrderAndUndoPost(): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        CreateAssemblyItemAndOrderWithCompInventory(AssemblyHeader);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        FindPostedAssemblyHeader(PostedAssemblyHeader, AssemblyHeader."No.", AssemblyHeader."Item No.");
        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, false, '');
        exit(AssemblyHeader."Item No.");
    end;

    local procedure CreateItemWithAssemblyBOM(var Item: Record Item)
    var
        BOMComponent: Record "BOM Component";
        Resource: Record Resource;
    begin
        LibraryInventory.CreateItem(Item);

        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        LibraryResource.CreateResourceNew(Resource);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, Item."No.", BOMComponent.Type::Resource, Resource."No.", 1, Resource."Base Unit of Measure");
    end;

    local procedure CreateItemWithDimension(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, ReplenishmentSystem, '', '');
        LibraryAssembly.AddEntityDimensions(AssemblyLine.Type::Item, Item."No.");
    end;

    local procedure CreateItemWithSalesLineDiscount(var Item2: Record Item; Item: Record Item)
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        LibraryAssembly.CreateItem(
          Item2, Item2."Costing Method"::Standard, Item2."Replenishment System"::Purchase, Item."Gen. Prod. Posting Group",
          Item."Inventory Posting Group");
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::"All Customers", '', 0D, '', '', '', 0);  // Use 0D for Starting Date and 0 for Minimum Quantity.
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(100, 2));
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateItemWithSalesPrice(var Item2: Record Item; Item: Record Item)
    var
        SalesPrice: Record "Sales Price";
    begin
        LibraryAssembly.CreateItem(
          Item2, Item2."Costing Method"::Standard, Item2."Replenishment System"::Purchase, Item."Gen. Prod. Posting Group",
          Item."Inventory Posting Group");
        LibraryCosting.CreateSalesPrice(SalesPrice, "Sales Price Type"::"All Customers", '', Item2."No.", 0D, '', '', '', 0);  // Use 0D for Starting Date and 0 for Minimum Quantity.
        SalesPrice.Validate("Unit Price", Item2."Unit Price" + LibraryRandom.RandDec(100, 2));  // Use Different Sales Price.
        SalesPrice.Modify(true);
    end;

    local procedure CreateMultipleStockkeepingUnit(ItemNo: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        Item.SetFilter("Location Filter", '%1|%2', LocationCode, LocationCode2);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);  // Create Per Option as Zero.
    end;

    local procedure CreateResourceWithDimension(var Resource: Record Resource)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryAssembly.CreateResource(Resource, false, '');
        LibraryAssembly.AddEntityDimensions(AssemblyLine.Type::Resource, Resource."No.");
    end;

    local procedure CreateShortcutDimensionValue(var DimensionValue: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value"; DimensionCode: Code[20]; DimensionCode2: Code[20])
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDimensionValue(DimensionValue2, DimensionCode2);
    end;

    local procedure CreateCustomerWithDimension(var Customer: Record Customer; DimensionCode: Code[20]; DimensionCode2: Code[20]; DimensionValueCode: Code[20]; DimensionValueCode2: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", DimensionCode, DimensionValueCode);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", DimensionCode2, DimensionValueCode2);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateSalesOrderWithReservation(var SalesLine: Record "Sales Line"; Qty: Decimal; PartialQty: Decimal)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Qty, '');
        CreateSalesOrder(SalesLine, '', Item."No.", PartialQty);
        SalesLine.ShowReservation();
    end;

    local procedure CreateSalesLineWithBin(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithDirectCost(ItemNo: Code[20]; Qty: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseOrderWithReceiptDate(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Qty, '', WorkDate());
    end;

    local procedure CreateAsmItemAndSalesOrderWithDimSetup(var SalesLine: Record "Sales Line"; var DimensionValue: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value")
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        CreateAssemblyItem(Item);

        // Create Dimension value for Shortcut Dimension Code
        CreateShortcutDimensionValue(
          DimensionValue, DimensionValue2, LibraryERM.GetShortcutDimensionCode(1), LibraryERM.GetShortcutDimensionCode(2));

        // Create Customer with default Shortcut dimension
        CreateCustomerWithDimension(
          Customer, LibraryERM.GetShortcutDimensionCode(1), LibraryERM.GetShortcutDimensionCode(2),
          DimensionValue.Code, DimensionValue2.Code);

        // Create Sales Order
        CreateSalesOrder(SalesLine, Customer."No.", Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesOrderWithAssemblyItem(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        Customer: Record Customer;
        AssemblyHeader: Record "Assembly Header";
    begin
        // Create Assembly Item, Customer and Sales Order.
        CreateAssemblyItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesLine, Customer."No.", Item."No.", LibraryRandom.RandInt(10));

        // Generate an Assembly order on Sales line to Assembly Header.
        UpdateQtyToAssembleOnSalesLine(SalesLine, SalesLine.Quantity);

        FindAssemblyHeader(AssemblyHeader, AssemblyHeader."Document Type"::Order, SalesLine."No."); // Find the Assembly Header created from the sales line
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), LibraryRandom.RandInt(10)); // Add component inventory for assembly item
    end;

    local procedure CreateAssemblyItem(var Item: Record Item)
    begin
        // Use False for Update Unit Cost and blank for Variant Code.
        LibraryAssembly.SetupAssemblyItem(
          Item, Item."Costing Method"::Standard, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', false,
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateAssemblyItemAndComponentItem(var ParentItem: Record Item; var ComponentItem: Record Item; QuantityPerParent: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(ParentItem, ParentItem."Costing Method"::Average, ParentItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(ComponentItem, ComponentItem."Costing Method"::Average, ComponentItem."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", ParentItem."No.", '', BOMComponent."Resource Usage Type", QuantityPerParent, true);
    end;

    local procedure CreateAssemblyItemWithAssemblyItemAsComponent(var Item: Record Item; var Item2: Record Item; UseBaseUnitOfMeasure: Boolean)
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateAssemblyItem(Item);
        CreateAssemblyItem(Item2);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item2."No.", Item."No.", '',
          BOMComponent."Resource Usage Type", LibraryRandom.RandInt(5), UseBaseUnitOfMeasure); // Use Base Unit of Measure as True and Variant Code as blank.
    end;

    local procedure CreateAndUpdateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; CostingMethod: Enum "Costing Method"; StandardCost: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Standard Cost", StandardCost);
        Item.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitofMeasure: Code[10]; ProductionBOMLineType: Enum "Production BOM Line Type"; CompItemNo: Code[20]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitofMeasure);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLineType, CompItemNo, QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateCertifiedProductionBOMAndUpdateItem(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; ProductionBOMLineType: Enum "Production BOM Line Type"; CompItemNo: Code[20]; QuantityPer: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        CreateAndCertifyProductionBOM(
          ProductionBOMHeader, Item."Base Unit of Measure", ProductionBOMLineType, CompItemNo, QuantityPer);
        UpdateItemWithProdBOMNo(Item."No.", ProductionBOMHeader."No.");
    end;

    local procedure CreateSalesOrderWithPostingDate(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesOrderWithTwoLinesAndPostShipment(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        CreateSalesLineWithBin(SalesLine, SalesHeader, ItemNo, BinCode, Quantity);
        CreateSalesLineWithBin(SalesLine, SalesHeader, ItemNo, BinCode, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateSalesOrderWithAssemblyItemAndUndoSalesShipment(var SalesLine: Record "Sales Line"; CostingMethod: Enum "Costing Method"; AutoAdjust: Boolean)
    var
        ItemAssembled: Record Item;
    begin
        CreateSalesOrderWithAssemblyItem(SalesLine);
        ItemAssembled.Get(SalesLine."No.");
        ItemAssembled.Validate("Costing Method", CostingMethod);
        ItemAssembled.Modify(true);
        if not AutoAdjust then
            LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');

        UndoSalesShipmentLine(PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true, false));
    end;

    local procedure CreateAssemblyItemAndOrderWithCompInventory(var AssemblyHeader: Record "Assembly Header")
    var
        Item: Record Item;
    begin
        CreateAssemblyItem(Item);
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateMsg, WorkDate()));
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', LibraryRandom.RandInt(10), '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, AssemblyHeader."Posting Date", LibraryRandom.RandInt(10));
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateRevaluationJournal(ItemNo: Code[20]; CalculatePer: Enum "Inventory Value Calc. Per")
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        Item.SetRange("No.", ItemNo);
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, WorkDate(), LibraryUtility.GenerateGUID(), CalculatePer, false, false, false, "Inventory Value Calc. Base"::" ", false);
    end;

    local procedure CreateSilverLocation(var Location: Record Location; var Bin: Record Bin)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
    end;

    local procedure CreateAndPostItemJournalApplToEntry(var EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemNo, Qty);
        EntryType := ItemJournalLine."Entry Type";
        Commit(); // Commit required before invoke action in UpdateApplToEntryByPage function.
        UpdateApplToEntryByPage(ItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure DeleteAssemblyCommentLine(DocumentType: Enum "Assembly Document Type"; DocumentNo: Code[20])
    var
        AssemblyCommentLine: Record "Assembly Comment Line";
    begin
        AssemblyCommentLine.SetRange("Document Type", DocumentType);
        AssemblyCommentLine.SetRange("Document No.", DocumentNo);
        AssemblyCommentLine.DeleteAll(true);
    end;

    local procedure DeleteAssemblyLine(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), ItemNo, '', Quantity, '');
        LibraryAssembly.DeleteAssemblyLine("BOM Component Type"::Item, AssemblyHeader."No.");
    end;

    local procedure ExplodeAssemblyBOM(var BOMComponent: Record "BOM Component"; ParentItemNo: Code[20]; Type: Enum "BOM Component Type")
    begin
        FindBOMComponent(BOMComponent, ParentItemNo, Type);
        CODEUNIT.Run(CODEUNIT::"BOM-Explode BOM", BOMComponent);
    end;

    local procedure FilterAssemblyOrderLine(var AssemblyOrder: TestPage "Assembly Order"; OrderNo: Code[20]; No: Code[20])
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("No.", OrderNo);
        AssemblyOrder.Lines.FILTER.SetFilter("No.", No);
    end;

    local procedure FindAssemblyLine(var AssemblyLine: Record "Assembly Line"; var BomComponent: Record "BOM Component")
    begin
        AssemblyLine.SetRange(Type, BomComponent.Type);
        AssemblyLine.SetRange("No.", BomComponent."No.");
        AssemblyLine.FindFirst();
    end;

    local procedure FindAssemblyOrderLine(var AssemblyLine: Record "Assembly Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", DocumentNo);
        AssemblyLine.SetRange("No.", No);
        AssemblyLine.FindFirst();
    end;

    local procedure FindBOMComponent(var BOMComponent: Record "BOM Component"; ParentItemNo: Code[20]; Type: Enum "BOM Component Type")
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.SetRange(Type, Type);
        BOMComponent.FindFirst();
    end;

    local procedure FindBOMComponents(var BOMComponent: Record "BOM Component"; ParentItemNo: Code[20])
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.FindSet();
    end;

    local procedure FindPostedAssemblyHeader(var PostedAssemblyHeader: Record "Posted Assembly Header"; OrderNo: Code[20]; ItemNo: Code[20])
    begin
        PostedAssemblyHeader.SetRange("Order No.", OrderNo);
        PostedAssemblyHeader.SetRange("Item No.", ItemNo);
        PostedAssemblyHeader.FindFirst();
    end;

    local procedure FindPostedAssemblyResourceLine(var PostedAssemblyLine: Record "Posted Assembly Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        PostedAssemblyLine.SetRange("Document No.", DocumentNo);
        PostedAssemblyLine.SetRange(Type, PostedAssemblyLine.Type::Resource);
        PostedAssemblyLine.SetRange("No.", No);
        PostedAssemblyLine.FindFirst();
    end;

    local procedure FindAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; DocumentType: Enum "Assembly Document Type"; ItemNo: Code[20])
    begin
        AssemblyHeader.SetRange("Document Type", DocumentType);
        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        FilterOnItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindLastItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        FilterOnItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.FindLast();
    end;

    local procedure FilterOnItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemJournalLine.SetRange("Entry Type", EntryType);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; DocumentType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
    end;

    local procedure GetItemFromBOMComponent(var ComponentItem: Record Item; ItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        FindBOMComponent(BOMComponent, ItemNo, BOMComponent.Type::Item);
        ComponentItem.Get(BOMComponent."No.");
    end;

    local procedure GetResourceFromBOMComponent(var Resource: Record Resource; ItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        FindBOMComponent(BOMComponent, ItemNo, BOMComponent.Type::Resource);
        Resource.Get(BOMComponent."No.");
    end;

    local procedure GetNextNoFromAssemblyOrderNoSeries(): Code[20]
    var
        AssemblySetup: Record "Assembly Setup";
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        AssemblySetup.Get();
        NoSeries.Get(AssemblySetup."Assembly Order Nos.");
        exit(NoSeriesCodeunit.PeekNextNo(NoSeries.Code));
    end;

    local procedure GeneralPreparationForUndoSalesShipmentLineWithAssemblyOrder(var AsmItemNo: Code[20]; var Quantity: Decimal): Code[20]
    var
        AsmItem: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // Create Assembly Item and Assembly BOM with at least two component Items. Create Sales Order with Assembly Item.
        // Update Quantity to Consume on one Assembly line to zero. Post Sales Order as SHIP.
        LibraryAssembly.SetupAssemblyItem(
          AsmItem, AsmItem."Costing Method"::Standard, AsmItem."Costing Method"::Standard, AsmItem."Replenishment System"::Assembly,
          '', false, LibraryRandom.RandIntInRange(2, 5), 0, 0, LibraryRandom.RandInt(5));
        AsmItemNo := AsmItem."No.";
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesLine, Customer."No.", AsmItem."No.", LibraryRandom.RandInt(10));
        UpdateQtyToAssembleOnSalesLine(SalesLine, SalesLine.Quantity);
        Quantity := SalesLine.Quantity;

        // Update Quantity to Consume on one Assembly line to zero. Post Sales Order as SHIP.
        UpdateQuantityToConsumeOnAssemblyLine(AssemblyLine, SalesLine."No.");
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), LibraryRandom.RandInt(50) + 100); // Large inventory for component items.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure InitSetupForAssemlyOrderAndPurchaseOrder(): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ChildItem: Record Item;
        ParentItem: Record Item;
        PurchaseLine: Record "Purchase Line";
        SupplyQty: Decimal;
    begin
        SupplyQty := LibraryRandom.RandInt(5);
        CreateAssemblyItemAndBOMComponentSetup(ChildItem, ParentItem);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), ParentItem."No.", '', LibraryRandom.RandInt(5), '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), SupplyQty); // Add Inventory = AssemblyLine.Quantity + SupplyQty for Component.
        FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", ChildItem."No.");
        AssemblyLine.ShowReservation();

        CreatePurchaseOrderWithReceiptDate(PurchaseLine, ChildItem."No.", LibraryRandom.RandInt(5));
        LibraryVariableStorage.Enqueue(AssemblyLine.Quantity); // Enqueue value to verify Gross Requirement.
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity); // Enqueue Value to verify Scheduled Receipt.
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity + SupplyQty); // Enqueue value to verify Inventory (Component on Inventory - Gross Requirement + Scheduled Receipt).
        exit(ParentItem."No.");
    end;

    local procedure InventorySetupWithLocationMandatory(LocationMandatory: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Location Mandatory", LocationMandatory);
        InventorySetup.Modify(true);
    end;

    local procedure MakeItemStock(ItemNo: Code[20]; Qty: Decimal; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure NavigateFinishedProductionOrder(var Navigate: TestPage Navigate; ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrderNo);
        Navigate.Trap();
        ProductionOrder.Navigate();
    end;

    local procedure OpenAssemblyBOMFromItemCard(var AssemblyBOM: TestPage "Assembly BOM"; ItemNo: Code[20])
    var
        ItemCard: TestPage "Item Card";
    begin
        AssemblyBOM.Trap();
        ItemCard.OpenEdit();
        ItemCard.FILTER.SetFilter("No.", ItemNo);
        ItemCard."Assembly BOM".Invoke();
    end;

    local procedure OpenAssemblyAvailabilityPage(DocumentNo: Code[20])
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyOrder.OpenView();
        AssemblyOrder.FILTER.SetFilter("No.", DocumentNo);
        AssemblyOrder.ShowAvailability.Invoke();
        AssemblyOrder.OK().Invoke();
    end;

    local procedure PrepareAndPostAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; HeaderQtyFactor: Integer; CompQtyFactor: Integer; UpdateAllComps: Boolean)
    begin
        AssemblyHeader.Find();
        LibraryAssembly.PrepareOrderPosting(
          AssemblyHeader, AssemblyLine, HeaderQtyFactor, CompQtyFactor, UpdateAllComps, AssemblyHeader."Due Date");
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Ship: Boolean; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice));
    end;

    local procedure RefreshAssemblyOrder(var AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyHeader.Find();
        LibraryAssembly.ReopenAO(AssemblyHeader);
        LibraryVariableStorage.Enqueue(ResetAssemblyLines);  // Enqueue for ConfirmHandler.
        AssemblyHeader.RefreshBOM();
    end;

    local procedure SelectItemSubstitutionOnAssemblyOrder(AssemblyOrderNo: Code[20])
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("No.", AssemblyOrderNo);
        AssemblyOrder.Lines.SelectItemSubstitution.Invoke();
    end;

    local procedure ShowAssemblyListFromAssemblyLine(var AssemblyBOM: TestPage "Assembly BOM"; DocumentNo: Code[20]; No: Code[20])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        FindAssemblyOrderLine(AssemblyLine, DocumentNo, No);
        AssemblyBOM.Trap();
        AssemblyLine.ShowAssemblyList();
    end;

    local procedure SetupAutomaticCostAdjustment()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        UpdateAutomaticCostPostAndAdjmtOnInventorySetup(
          InventorySetup."Automatic Cost Posting", InventorySetup."Automatic Cost Adjustment"::Always);
    end;

    local procedure UpdateAssemblyOrderNosOnAssemblySetup(NewAssemblyOrderNos: Code[20])
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", NewAssemblyOrderNos);
        AssemblySetup.Modify(true);
    end;

    local procedure UpdateAutomaticCostPostAndAdjmtOnInventorySetup(AutomaticCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateAverageCostingMethodOnAssemblyItem(var AssemblyItem: Record Item)
    begin
        AssemblyItem.Validate("Costing Method", AssemblyItem."Costing Method"::Average);
        AssemblyItem.Modify(true);
    end;

    local procedure UpdateCopyComponentDimensionsOnAssemblySetup(NewCopyComponentDimensionsFrom: Option)
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Copy Component Dimensions from", NewCopyComponentDimensionsFrom);
        AssemblySetup.Modify(true);
    end;

    local procedure UpdateFixedResourceUsageTypeOnAssemblyBOM(var BOMComponent: Record "BOM Component"; ParentItemNo: Code[20]; Type: Enum "BOM Component Type")
    begin
        FindBOMComponent(BOMComponent, ParentItemNo, Type);
        BOMComponent.Validate("Resource Usage Type", BOMComponent."Resource Usage Type"::Fixed);
        BOMComponent.Modify(true);
    end;

    local procedure UpdateFixedResourceUsageTypeOnAssemblyLine(AssemblyHeaderNo: Code[20]; ResourceNo: Code[20])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        FindAssemblyOrderLine(AssemblyLine, AssemblyHeaderNo, ResourceNo);
        AssemblyLine.Validate("Resource Usage Type", AssemblyLine."Resource Usage Type"::Fixed);
        AssemblyLine.Modify(true);
    end;

    local procedure UpdateInventoryForComponentItems(ItemNo: Code[20]; Quantity: Decimal; QtyperUnitofMeasure: Decimal; ItemNo2: Code[20])
    begin
        CreateAndPostItemJournalLine(ItemNo, Quantity * Quantity * QtyperUnitofMeasure, '');  // Value required for Inventory using different Unit of Measure Conversion.
        CreateAndPostItemJournalLine(ItemNo2, Quantity * Quantity * QtyperUnitofMeasure, '');  // Value required for Inventory using different Unit of Measure Conversion.
    end;

    local procedure UpdateQuantityToAssembleOnAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; QuantityToAssemble: Decimal)
    begin
        AssemblyHeader.Validate("Quantity to Assemble", QuantityToAssemble);
        AssemblyHeader.Modify(true);
    end;

    local procedure UpdateStockOutWarningOnAssemblySetup(NewStockOutWarning: Boolean)
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Stockout Warning", NewStockOutWarning);
        AssemblySetup.Modify(true);
    end;

    local procedure UpdatePostingDateOnAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    var
        NewPostingDate: Date;
    begin
        AssemblyHeader.Find();
        DeleteAssemblyCommentLine(AssemblyHeader."Document Type", AssemblyHeader."No.");
        NewPostingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, AssemblyLine, 40, 40, false, NewPostingDate);  // Less than WORKDATE.
    end;

    local procedure UpdateVariantOnAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; VariantCode: Code[10])
    begin
        AssemblyHeader.Validate("Variant Code", VariantCode);
        AssemblyHeader.Modify(true);
    end;

    local procedure UpdateVariantOnAssemblyLine(var AssemblyLine: Record "Assembly Line"; VariantCode: Code[10])
    begin
        AssemblyLine.Validate("Variant Code", VariantCode);
        AssemblyLine.Modify(true);
    end;

    local procedure UpdateQtyToAssembleOnSalesLine(var SalesLine: Record "Sales Line"; QtyToAssemble: Decimal)
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateMsg, WorkDate()));
        SalesLine.Validate("Qty. to Assemble to Order", QtyToAssemble);
        SalesLine.Modify(true);
    end;

    local procedure UpdateDimensionValueOnSalesLine(var SalesLine: Record "Sales Line"; DimensionValueCode: Code[20]; DimensionValueCode2: Code[20])
    begin
        LibraryVariableStorage.Enqueue(UpdateDimConfirmQst);
        LibraryVariableStorage.Enqueue(UpdateDimConfirmQst);
        SalesLine.Validate("Shortcut Dimension 1 Code", DimensionValueCode);
        SalesLine.Validate("Shortcut Dimension 2 Code", DimensionValueCode2);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyPerOnAssemblyLine(var AssemblyLine: Record "Assembly Line"; QuantityPer: Decimal)
    begin
        AssemblyLine.Validate("Quantity per", QuantityPer);
        AssemblyLine.Modify(true);
    end;

    local procedure UpdateItemDimensionWithValuePosting(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20]; DefaultValuePosting: Enum "Default Dimension Value Posting Type")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure UpdateItemWithProdBOMNo(ItemNo: Code[20]; ProductionBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdatePostingDateOnSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; PostingDate: Date)
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateQtyPerOnAssemblyLineAndPostSalesDocument(SalesLine: Record "Sales Line"; Ship: Boolean; Invoice: Boolean)
    var
        BOMComponent: Record "BOM Component";
        AssemblyLine: Record "Assembly Line";
        SalesHeader: Record "Sales Header";
    begin
        FindBOMComponent(BOMComponent, SalesLine."No.", BOMComponent.Type::Item);
        FindAssemblyLine(AssemblyLine, BOMComponent);
        AssemblyLine.Validate("Quantity per", AssemblyLine."Quantity per" / LibraryRandom.RandIntInRange(3, 5));
        AssemblyLine.Modify(true);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);
    end;

    local procedure UpdateQuantityToConsumeOnAssemblyLine(var AssemblyLine: Record "Assembly Line"; AsmItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        FindBOMComponents(BOMComponent, AsmItemNo);
        FindAssemblyLine(AssemblyLine, BOMComponent);
        AssemblyLine.Validate("Quantity to Consume", 0); // Update Quantity to Consume as zero.
        AssemblyLine.Modify(true);
    end;

    local procedure UndoSalesShipmentLine(DocumentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoShipmentConfirmationMsg);  // UndoShipmentMsg used in ConfirmHandler.
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateMsg, WorkDate())); // BeforeWorkDateMsg used in Messagehandler
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateApplToItemEntryOnAssemblyLine(var AssemblyLine: Record "Assembly Line"; ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        BOMComponent: Record "BOM Component";
    begin
        FindBOMComponent(BOMComponent, ItemNo, BOMComponent.Type::Item);
        FindAssemblyLine(AssemblyLine, BOMComponent);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", AssemblyLine."No.");
        AssemblyLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        AssemblyLine.Modify(true);
    end;

    local procedure UpdateApplToEntryByPage(ItemJournalBatchName: Code[20])
    var
        ItemJournalPage: TestPage "Item Journal";
    begin
        ItemJournalPage.OpenEdit();
        ItemJournalPage.CurrentJnlBatchName.SetValue(ItemJournalBatchName);
        ItemJournalPage."Applies-to Entry".Lookup();
        ItemJournalPage.OK().Invoke();
    end;

    local procedure UpdateQuantityOnSalesLineByPage(SalesHeaderNo: Code[20]; Qty: Decimal; SalesLineQty: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        SalesOrder.SalesLines.FILTER.SetFilter(Quantity, Format(SalesLineQty));
        SalesOrder.SalesLines.Quantity.SetValue(Qty);
        SalesOrder.OK().Invoke();
    end;

    local procedure VerifyAvailabilityOnSalesOrderPage(DocumentNo: Code[20]; ItemNo: Code[20]; AvailQty: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesOrder.SalesLines.FILTER.SetFilter("No.", ItemNo);
        SalesOrder.Control1906127307."Item Availability".AssertEquals(AvailQty);
        SalesOrder.OK().Invoke();
    end;

    local procedure VerifyAssemblyBOM(var AssemblyBOM: TestPage "Assembly BOM"; BomComponent: Record "BOM Component")
    begin
        AssemblyBOM.FILTER.SetFilter("No.", BomComponent."No.");
        AssemblyBOM."No.".AssertEquals(BomComponent."No.");
        AssemblyBOM."Quantity per".AssertEquals(BomComponent."Quantity per");
        BomComponent.CalcFields("Assembly BOM");
        AssemblyBOM."Assembly BOM".AssertEquals(BomComponent."Assembly BOM");
    end;

    local procedure VerifyAssemblyItemDetailsOnAssemblyOrder(Item: Record Item; No: Code[20])
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("No.", No);
        AssemblyOrder.Control11."Standard Cost".AssertEquals(Item."Standard Cost");
        AssemblyOrder.Control11."Unit Price".AssertEquals(Item."Unit Price");
    end;

    local procedure VerifyAssemblyLine(ParentItemNo: Code[20]; Quantity: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        BOMComponent: Record "BOM Component";
        Quantity2: Decimal;
    begin
        FindBOMComponents(BOMComponent, ParentItemNo);
        repeat
            Quantity2 := Quantity;
            FindAssemblyLine(AssemblyLine, BOMComponent);
            AssemblyLine.TestField("Quantity per", BOMComponent."Quantity per");
            if AssemblyLine."Resource Usage Type" = AssemblyLine."Resource Usage Type"::Fixed then
                Quantity2 := 1;  // Value 1 required for the test.
            AssemblyLine.TestField(Quantity, Round(BOMComponent."Quantity per" * Quantity2, 0.00001));  // Calculated value required for the test.
        until BOMComponent.Next() = 0;
    end;

    local procedure VerifyBOMComponentAfterExplodeBOM(ParentItemNo: Code[20]; ComponentItemNo: Code[20]; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
        BOMComponent2: Record "BOM Component";
    begin
        FindBOMComponents(BOMComponent, ComponentItemNo);
        repeat
            BOMComponent2.SetRange("No.", BOMComponent."No.");
            FindBOMComponent(BOMComponent2, ParentItemNo, BOMComponent.Type);
            BOMComponent2.TestField("Quantity per", BOMComponent."Quantity per" * QuantityPer);  // Calculate Quantity per from Component Assembly BOM.
        until BOMComponent.Next() = 0;
    end;

    local procedure VerifyBOMComponentsOnAssemblyBOM(var AssemblyBOM: TestPage "Assembly BOM"; ItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        FindBOMComponents(BOMComponent, ItemNo);
        repeat
            AssemblyBOM."No.".AssertEquals(BOMComponent."No.");
            AssemblyBOM."Quantity per".AssertEquals(BOMComponent."Quantity per");
            AssemblyBOM.Next();
        until BOMComponent.Next() = 0;
    end;

    local procedure VerifyComponentDetailsOnAssemblyBOM(var AssemblyBOM: TestPage "Assembly BOM"; ItemNo: Code[20]; UnitPrice: Text; UnitCost: Text; ResourceNo: Code[20]; ResourceType: Text; UnitCost2: Text)
    begin
        AssemblyBOM.Control13."No.".AssertEquals(ItemNo);
        AssemblyBOM.Control13."Unit Price".AssertEquals(Format(UnitPrice));
        AssemblyBOM.Control13."Unit Cost".AssertEquals(Format(UnitCost));
        AssemblyBOM.Control9."No.".AssertEquals(ResourceNo);
        AssemblyBOM.Control9.Type.AssertEquals(ResourceType);
        AssemblyBOM.Control9."Unit Cost".AssertEquals(Format(UnitCost2));
    end;

    local procedure VerifyComponentItemDetailsOnAssemblyOrder(Item: Record Item; No: Code[20])
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        FilterAssemblyOrderLine(AssemblyOrder, No, Item."No.");
        AssemblyOrder.Control44."Unit Price".AssertEquals(Item."Unit Price");
        AssemblyOrder.Control44."Unit Cost".AssertEquals(Item."Unit Cost");
    end;

    local procedure VerifyComponentResourceDetailsOnAssemblyOrder(Resource: Record Resource; No: Code[20])
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        FilterAssemblyOrderLine(AssemblyOrder, No, Resource."No.");
        AssemblyOrder.Control43.Type.AssertEquals(Resource.Type);
        AssemblyOrder.Control43."Unit Cost".AssertEquals(Resource."Unit Cost");
    end;

    local procedure VerifyGLEntry(AssemblyItem: Record Item; AssemblyHeaderNo: Code[20])
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        InventoryPostingSetup.Get('', AssemblyItem."Inventory Posting Group");
        GeneralPostingSetup.Get('', AssemblyItem."Gen. Prod. Posting Group");
        FindPostedAssemblyHeader(PostedAssemblyHeader, AssemblyHeaderNo, AssemblyItem."No.");
        LibraryAssembly.VerifyGLEntry(
          PostedAssemblyHeader."No.", InventoryPostingSetup."Inventory Account", PostedAssemblyHeader."Due Date",
          PostedAssemblyHeader."Cost Amount", '>');
        LibraryAssembly.VerifyGLEntry(
          PostedAssemblyHeader."No.", GeneralPostingSetup."Inventory Adjmt. Account", PostedAssemblyHeader."Due Date",
          -PostedAssemblyHeader."Cost Amount", '<');
    end;

    local procedure VerifyItemLedgerEntries(ItemNo: Code[20]; AdjustedQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            if ItemLedgerEntry.Positive then
                Assert.AreNearlyEqual(AdjustedQuantity, ItemLedgerEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(), CostAmountErr)
            else
                Assert.AreNearlyEqual(-AdjustedQuantity, ItemLedgerEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(), CostAmountErr)
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyNoOfRecordsAfterNavigate(Navigate: TestPage Navigate; TableName: Text[50])
    begin
        Navigate.FILTER.SetFilter("Table Name", TableName);
        Navigate."No. of Records".AssertEquals(1);  // Only 1 Record found for each Posted Table.
    end;

    local procedure VerifyQuantityOnAssemblyOrder(AssemblyHeader: Record "Assembly Header"; QuantityToAssemble: Decimal; ConsumedQuantity: Decimal; RemainingQuantity: Decimal)
    var
        BOMComponent: Record "BOM Component";
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyHeader.TestField("Quantity to Assemble", QuantityToAssemble);
        FindBOMComponent(BOMComponent, AssemblyHeader."Item No.", BOMComponent.Type::Item);
        FindAssemblyLine(AssemblyLine, BOMComponent);
        AssemblyLine.TestField("Consumed Quantity", ConsumedQuantity);
        AssemblyLine.TestField("Remaining Quantity", RemainingQuantity);
    end;

    local procedure VerifyQuantityToConsumeOnAssemblyLine(ItemNo: Code[20]; QuantityToAssemble: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        BOMComponent: Record "BOM Component";
        Quantity: Decimal;
    begin
        FindBOMComponents(BOMComponent, ItemNo);
        repeat
            Quantity := QuantityToAssemble;
            FindAssemblyLine(AssemblyLine, BOMComponent);
            if AssemblyLine."Resource Usage Type" = AssemblyLine."Resource Usage Type"::Fixed then
                Quantity := 1;  // Value required for the test.
            AssemblyLine.TestField("Quantity to Consume", AssemblyLine."Quantity per" * Quantity);  // Value required for the test.
        until BOMComponent.Next() = 0;
    end;

    local procedure VerifyReleasedProductionOrderLine(ProductionOrder: Record "Production Order"): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ProductionOrder."Source No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField(Quantity, ProductionOrder.Quantity);
        exit(ProdOrderLine."Line No.");
    end;

    local procedure VerifySalesCreditMemoLine(SalesLine: Record "Sales Line")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField("No.", SalesLine."No.");
        SalesCrMemoLine.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyPostedAssemblyOrderStatistics(AssemblyHeaderNo: Code[20]; ItemNo: Code[20]; ResourceNo: Code[20])
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
        PostedAsmOrderStatistics: TestPage "Posted Asm. Order Statistics";
    begin
        PostedAsmOrderStatistics.Trap();
        FindPostedAssemblyHeader(PostedAssemblyHeader, AssemblyHeaderNo, ItemNo);
        PostedAssemblyHeader.TestField("Item No.");
        PAGE.Run(PAGE::"Posted Asm. Order Statistics", PostedAssemblyHeader);
        FindPostedAssemblyResourceLine(PostedAssemblyLine, PostedAssemblyHeader."No.", ResourceNo);

        // Verify Expected Resource Cost and Expected Total Cost.
        PostedAsmOrderStatistics.ExpResCost.AssertEquals(PostedAssemblyLine.Quantity * PostedAssemblyLine."Unit Cost");  // Calculated Value Required for Expected Resource Cost.
        PostedAsmOrderStatistics.ExpTotalCost.AssertEquals(PostedAssemblyLine.Quantity * PostedAssemblyLine."Unit Cost");  // Calculated Value Required for Expected Total Cost.

        // Verify Actual Resource Cost and Actual Total Cost.
        PostedAsmOrderStatistics.ActResCost.AssertEquals(PostedAssemblyLine.Quantity * PostedAssemblyLine."Unit Cost");  // Calculated Value Required for Actual Resource Cost.
        PostedAsmOrderStatistics.ActTotalCost.AssertEquals(PostedAssemblyLine.Quantity * PostedAssemblyLine."Unit Cost");  // Calculated Value Required for Actual Total Cost.
    end;

    local procedure VerifyStatisticsPage(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; ResourceNo: Code[20])
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyOrderStatistics: TestPage "Assembly Order Statistics";
    begin
        AssemblyOrderStatistics.Trap();
        AssemblyHeader.TestField("Item No.");
        PAGE.Run(PAGE::"Assembly Order Statistics", AssemblyHeader);

        // Verify Expected Material Cost.
        FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", ItemNo);
        AssemblyOrderStatistics.ExpMatCost.AssertEquals(AssemblyLine.Quantity * AssemblyLine."Unit Cost");  // Calculated Value Required for Expected Material Cost.

        // Verify Expected Resource Cost.
        FindAssemblyOrderLine(AssemblyLine, AssemblyHeader."No.", ResourceNo);
        AssemblyOrderStatistics.ExpResCost.AssertEquals(AssemblyLine.Quantity * AssemblyLine."Unit Cost");  // Calculated Value Required for Expected Resource Cost.

        // Verify Expected Total Cost.
        AssemblyOrderStatistics.ExpTotalCost.AssertEquals(AssemblyHeader."Cost Amount");  // Calculated Value Required for Expected Total Cost.
    end;

    local procedure VerifyDimensionOnAssemblyHeader(AssemblyHeader: Record "Assembly Header"; DimensionValueCode: Code[20]; DimensionValueCode2: Code[20])
    begin
        AssemblyHeader.TestField("Shortcut Dimension 1 Code", DimensionValueCode);
        AssemblyHeader.TestField("Shortcut Dimension 2 Code", DimensionValueCode2);
    end;

    local procedure VerifyDimensionOnILE(ItemLedgerEntry: Record "Item Ledger Entry"; DimensionValueCode: Code[20]; DimensionValueCode2: Code[20])
    begin
        ItemLedgerEntry.TestField("Global Dimension 1 Code", DimensionValueCode);
        ItemLedgerEntry.TestField("Global Dimension 2 Code", DimensionValueCode2);
    end;

    local procedure VerifyInvoicedQtyOnItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; InvoicedQty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.TestField("Invoiced Quantity", InvoicedQty);
    end;

    local procedure VerifyQtyOnValueEntry(ValueEntry: Record "Value Entry"; InvoicedQty: Decimal)
    begin
        ValueEntry.TestField("Valued Quantity", InvoicedQty);
        ValueEntry.TestField("Invoiced Quantity", InvoicedQty);
    end;

    local procedure VerifyQuantityAndCostAmountOnAssemblyLine(AssemblyLine: Record "Assembly Line"; QuantityPer: Decimal; AssemblyHeaderQuantity: Decimal)
    begin
        AssemblyLine.TestField("Quantity per", QuantityPer);
        AssemblyLine.TestField(Quantity, AssemblyLine."Quantity per" * AssemblyHeaderQuantity);
        AssemblyLine.TestField("Remaining Quantity", AssemblyLine.Quantity);
        AssemblyLine.TestField("Quantity to Consume", AssemblyLine.Quantity);
        AssemblyLine.TestField("Quantity (Base)", AssemblyLine.Quantity * AssemblyLine."Qty. per Unit of Measure");
        AssemblyLine.TestField("Remaining Quantity (Base)", AssemblyLine."Remaining Quantity" * AssemblyLine."Qty. per Unit of Measure");
        AssemblyLine.TestField("Quantity to Consume (Base)", AssemblyLine."Quantity to Consume" * AssemblyLine."Qty. per Unit of Measure");
        AssemblyLine.TestField("Cost Amount", AssemblyLine.Quantity * AssemblyLine."Unit Cost");
    end;

    local procedure VerifyStandardCostOnAssemblyItem(ItemNo: Code[20]; StandardCost: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.TestField("Standard Cost", StandardCost);
    end;

    local procedure VerifySalesShipmentLines(DocumentNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindSet();
        SalesShipmentLine.TestField(Quantity, Qty);
        SalesShipmentLine.Next();
        SalesShipmentLine.TestField(Quantity, -Qty);
    end;

    local procedure VerifyPostingDateOnItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; PostingDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifyCostAmountActualInILE(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; CostAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmountActual);
        ItemLedgerEntry.Next();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", -CostAmountActual);
    end;

    local procedure VerifyCostAmountActualForAssemblyOutputAndSaleILE(ItemNo: Code[20]; CostAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        VerifyCostAmountActualInILE(ItemLedgerEntry."Entry Type"::"Assembly Output", ItemNo, CostAmountActual);
        VerifyCostAmountActualInILE(ItemLedgerEntry."Entry Type"::Sale, ItemNo, -CostAmountActual);
    end;

    local procedure VerifyCostAmountInLastILE(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; CostAmountExpected: Decimal; CostAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindLastItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Expected)", CostAmountExpected);
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyOrderTypeOnItemJournalLine(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; OrderType: Enum "Inventory Order Type")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindItemJournalLine(ItemJournalLine, EntryType, ItemNo);
        ItemJournalLine.TestField("Order Type", OrderType);
    end;

    local procedure VerifyApplToEntryOnILE(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; ApplToEntry: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.TestField("Applies-to Entry", ApplToEntry);
    end;

    local procedure VerifyAssemblyLine(AssemblyHeader: Record "Assembly Header"; ConsumedQty: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindSet();
        repeat
            AssemblyLine.TestField(AssemblyLine."Consumed Quantity", ConsumedQty);
            AssemblyLine.TestField(AssemblyLine."Consumed Quantity (Base)", ConsumedQty);
        until AssemblyLine.Next() = 0;
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20]; QtyToAssemble: Decimal)
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalculateDateUsingDefaultSafetyLeadTime(), ItemNo, '', 10, '');
        AssemblyHeader.Validate("Quantity to Assemble", QtyToAssemble);
        AssemblyHeader.Modify(true);
    end;

    local procedure CreateAssemblyBomComponent(ComponentItem: Record Item; ParentItemNo: Code[20]; Quantity: Decimal)
    var
        BomComponent: Record "BOM Component";
        RecRef: RecordRef;
    begin
        BomComponent.Init();
        BomComponent.Validate("Parent Item No.", ParentItemNo);
        RecRef.GetTable(BomComponent);
        BomComponent.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, BomComponent.FieldNo("Line No.")));
        BomComponent.Validate(Type, BomComponent.Type::Item);
        BomComponent.Validate("No.", ComponentItem."No.");
        BomComponent.Validate("Quantity per", Quantity);
        BomComponent.Insert(true);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; StandardCostAmt: Decimal; ReorderPoint: Decimal; ReorderQuantity: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        if StandardCostAmt <> 0 then
            Item.Validate("Standard Cost", StandardCostAmt);
        Item.Modify(true);
    end;

    local procedure CreateAssemblyItemsAndBOMComponentsWithDefaultDimension(var Item: Record Item; var AssemblyItem: Record Item; var DefaultDimension: Record "Default Dimension")
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateAssemblyItem(Item);
        CreateAssemblyItem(AssemblyItem);
        UpdateItemDimensionWithValuePosting(
          DefaultDimension, AssemblyItem."No.", DefaultDimension."Value Posting"::"Same Code");
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item."No.", AssemblyItem."No.", '',
          BOMComponent."Resource Usage Type", LibraryRandom.RandInt(5), true);
    end;

    local procedure VerifyJobTaskDimensionOnRequisitionLine(AssemblyLine: Record "Assembly Line"; DefaultDimension: Record "Default Dimension")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", AssemblyLine."Dimension Set ID");
        DimensionSetEntry.FindLast();
        Assert.AreEqual(DefaultDimension."Dimension Code", DimensionSetEntry."Dimension Code", '');
        Assert.AreEqual(DefaultDimension."Dimension Value Code", DimensionSetEntry."Dimension Value Code", '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionEntriesPageHandler(var ItemSubstitutionEntries: TestPage "Item Substitution Entries")
    begin
        ItemSubstitutionEntries.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure GenericMessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirm);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesSuccessfullyPosted);  // Enqueue for MessageHandler.
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesPageHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    var
        EntryNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryNo);
        ItemLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        ItemLedgerEntries.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateStandardCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        OptionCount: Variant;
    begin
        LibraryVariableStorage.Dequeue(OptionCount);
        Choice := OptionCount;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWindowHandler(var AsmAvailability: TestPage "Assembly Availability Check")
    var
        GrossRequirement: Variant;
        ScheduledReceipt: Variant;
        ExpectedInventory: Variant;
    begin
        LibraryVariableStorage.Dequeue(GrossRequirement);
        LibraryVariableStorage.Dequeue(ScheduledReceipt);
        LibraryVariableStorage.Dequeue(ExpectedInventory);
        AsmAvailability.AssemblyLineAvail.GrossRequirement.AssertEquals(GrossRequirement);
        AsmAvailability.AssemblyLineAvail.ScheduledReceipt.AssertEquals(ScheduledReceipt);
        AsmAvailability.AssemblyLineAvail.ExpectedAvailableInventory.AssertEquals(ExpectedInventory);
    end;
}
