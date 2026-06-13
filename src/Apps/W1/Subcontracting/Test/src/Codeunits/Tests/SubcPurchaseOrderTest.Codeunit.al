// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Planning;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Utilities;

codeunit 139994 "Subc. Purchase Order Test"
{

    // [FEATURE] Subcontracting Management
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestCreationOfPurchOrderFromRtngLineWithSubcontractor()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Create Subcontracting Purchase Order directly from Prod. Order Routing Line

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Check if Purchase Line exists
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.IsFalse(PurchaseLine.IsEmpty(), 'Purchase line should be created for the released production order and subcontracting work center.');
    end;

    [Test]
    procedure CreateSubcOrderFromRtngLineEmptyDefVATProdPostGrp()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
        OriginalDefVATProdPostGrp: Code[20];
    begin
        // [SCENARIO 618715] Creating a Subcontracting Purchase Order from Prod. Order Routing Line
        // should succeed even when "Def. VAT Prod. Posting Group" is empty on the Gen. Product Posting Group
        // (US/Sales Tax localization).

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN] Create subcontracting Work Center (sets Def. VAT Prod. Posting Group during creation)
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Clear "Def. VAT Prod. Posting Group" on the Work Center's Gen. Product Posting Group
        // to simulate US/Sales Tax localization where this field is intentionally empty.
        // Done after all other setup to avoid committing the change during item/production order creation.
        GenProductPostingGroup.Get(WorkCenter[2]."Gen. Prod. Posting Group");
        OriginalDefVATProdPostGrp := GenProductPostingGroup."Def. VAT Prod. Posting Group";
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := '';
        GenProductPostingGroup.Modify();

        // [GIVEN] Create a VAT Posting Setup for the empty VAT Prod. Posting Group
        // so the downstream purchase line validation can find a matching setup
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        if not VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", '') then begin
            VATPostingSetup.Init();
            VATPostingSetup."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
            VATPostingSetup."VAT Prod. Posting Group" := '';
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
            VATPostingSetup."VAT %" := 0;
            VATPostingSetup.Insert();
        end;

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing Line
        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRoutingLine);

        // [THEN] Purchase Line is created successfully
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.AreEqual(false, PurchaseLine.IsEmpty(), 'Purchase Line should be created even when Def. VAT Prod. Posting Group is empty.');

        // [TEARDOWN] Restore original Def. VAT Prod. Posting Group to prevent contaminating other tests
        GenProductPostingGroup.Get(WorkCenter[2]."Gen. Prod. Posting Group");
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := OriginalDefVATProdPostGrp;
        GenProductPostingGroup.Modify();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestCreationOfPurchOrderFromRtngLineWithSubcontractorWithAddLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Create Subcontracting Purchase Order directly from Prod. Order Routing Line
        // [SCENARIO] and Transfer additional Line with marked Component;

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Check if Purchase Line with additional Component for Component Supply Method exists
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
#pragma warning disable AA0210
        ProductionBOMLine.SetRange("Component Supply Method", ProductionBOMLine."Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProductionBOMLine.FindFirst();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ProductionBOMLine."No.");
        Assert.AreEqual(false, PurchaseLine.IsEmpty(), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestCreationOfSubcontractingPurchOrderFromRtngLineWithAddInfoLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] Create Subcontracting Purchase Order directly from Prod. Order Routing Line
        // [SCENARIO] and Transfer additional Information Line;

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();
        UpdateSubMgmtSetupTransferInfoLine(true);

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Check if Purchase Line with Additional Information Exists
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.SetRange("Prod. Order No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::" ");
        PurchaseLine.FindFirst();

        ProdOrderRtngLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRtngLine.FindFirst();
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrderRtngLine."Prod. Order No.", ProdOrderRtngLine."Routing Reference No.");

        Assert.AreEqual(ProdOrderLine.Description, PurchaseLine.Description, '');

        // [TEARDOWN]
        UpdateSubMgmtSetupTransferInfoLine(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CheckGenPostGroupInSubContWorksheetAndSubConRoutingLine()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ManufacturingSetup: Record "Manufacturing Setup";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        GenBusPostingGroup1, GenBusPostingGroup2 : Code[20];
        ProdPostingGroup1, ProdPostingGroup2 : Code[20];
        VATBusPostingGroup1, VATBusPostingGroup2 : Code[20];
        VATProdPostingGroup1, VATProdPostingGroup2 : Code[20];
        ProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO] Check Gen. Prod. Posting Group value for Subcontracting Purchase Order

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();
        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        WorkCenter2 := WorkCenter[2];
        WorkCenter2."Subcontractor No." := Vendor."No.";
        Vendor."Subc. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        //[GIVEN] Create Production Order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
               ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        //[GIVEN] Create requisition worksheet template
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);

        //[GIVEN] create Purchase Order from Subcontracting Worksheet
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        Assert.AreEqual(ProductionOrder."No.", RequisitionLine."Prod. Order No.", 'Prod. Order No. has not found');

        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ProductionOrder."Source No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        //[GIVEN] Keep Posting Groups values for later Check
        ProdPostingGroup1 := PurchaseLine."Gen. Prod. Posting Group";
        GenBusPostingGroup1 := PurchaseLine."Gen. Bus. Posting Group";
        VATBusPostingGroup1 := PurchaseLine."VAT Bus. Posting Group";
        VATProdPostingGroup1 := PurchaseLine."VAT Prod. Posting Group";

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        //[GIVEN] Delete Purchase Order
        PurchaseHeader.Delete(true);
        Commit();

        ManufacturingSetup.Get();
        ManufacturingSetup."Subcontracting Template Name" := RequisitionLine."Worksheet Template Name";
        ManufacturingSetup."Subcontracting Batch Name" := RequisitionLine."Journal Batch Name";
        ManufacturingSetup.Modify();

        // [GIVEN] Create Subcontracting Purchase Order from Prod. Order Routing
        WorkCenter2 := WorkCenter[2];
        WorkCenter2."Subcontractor No." := Vendor."No.";
        WorkCenter2.Modify();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRtng.OpenView();
        ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        ProdOrderRtng.CreateSubcontracting.Invoke();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ProductionOrder."Source No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        //[GIVEN] Keep Posting Groups values for later Check
        ProdPostingGroup2 := PurchaseLine."Gen. Prod. Posting Group";
        GenBusPostingGroup2 := PurchaseLine."Gen. Bus. Posting Group";
        VATBusPostingGroup2 := PurchaseLine."VAT Bus. Posting Group";
        VATProdPostingGroup2 := PurchaseLine."VAT Prod. Posting Group";

        //[THEN] Check if Posting Groups values is the same as Standard
        Assert.AreEqual(ProdPostingGroup1, ProdPostingGroup2, 'Gen. Prod. Posting Group is not Expected');
        Assert.AreEqual(GenBusPostingGroup1, GenBusPostingGroup2, 'Gen. Bus. Posting Group is not Expected');
        Assert.AreEqual(VATBusPostingGroup1, VATBusPostingGroup2, 'VAT Bus. Posting Group is not Expected');
        Assert.AreEqual(VATProdPostingGroup1, VATProdPostingGroup2, 'VAT Prod. Posting Group');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestTransferProdOrderRtngCommentByCreationOfSubcontrPurchOrder()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchCommentLine: Record "Purch. Comment Line";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        ReleasedProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO] Create Subcontracting Purchase Order
        // [SCENARIO] and test Transfer of Prod Order Rtng. Comment to PurchLine HTML Text;

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");

        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");

        // Create Comment Line
        ProdOrderRtngLine.SetRange(Status, ProdOrderRtngLine.Status::Released);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRtngLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRtngLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderRtngCommentLine(ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.", ProdOrderRtngLine."Routing Reference No.", ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Operation No.");

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        ReleasedProdOrderRtng.OpenView();
        ReleasedProdOrderRtng.GoToRecord(ProdOrderRtngLine);
        ReleasedProdOrderRtng.CreateSubcontracting.Invoke();

        // [THEN] Get transferred Rtng Comment Text
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderRtngLine."Prod. Order No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProdOrderRtngLine."Routing Reference No.");
        PurchaseLine.FindLast();

        PurchCommentLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchCommentLine.SetRange("No.", PurchaseLine."Document No.");
        PurchCommentLine.SetRange("Document Line No.", PurchaseLine."Line No.");

        Assert.IsFalse(PurchaseLine.IsEmpty(), 'Purchase Comment Line must be filled');

        // [TEARDOWN]
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure Description2CopiedFromProdOrderComponentToPurchaseLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        ExpectedDescription2: Text[50];
    begin
        // [SCENARIO] Description 2 from Prod. Order Component is propagated to Purchase Line
        // [FEATURE] Bug 620556 - Subcontracting Description 2 alignment

        // [GIVEN] Complete Setup of Manufacturing
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] A Description 2 value is set on the Prod. Order Component with Component Supply Method = Purchase
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        ExpectedDescription2 := 'TestDescription2_Comp';
        ProdOrderComp."Description 2" := ExpectedDescription2;
        ProdOrderComp.Modify();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] Description 2 from Prod. Order Component is propagated to the component Purchase Line
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ProdOrderComp."Item No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        Assert.AreEqual(
            ExpectedDescription2, PurchaseLine."Description 2",
            'Description 2 must be propagated from Prod. Order Component to Purchase Line');
    end;

    [Test]
    procedure Description2PopulatedOnRequisitionLineFromCalculateSubcontracts()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        LibraryUtility: Codeunit "Library - Utility";
        ExpectedDescription2: Text[50];
    begin
        // [SCENARIO] Description 2 from Prod. Order Routing Line is populated on Requisition Line
        // via Calculate Subcontracts report
        // [FEATURE] Bug 620556 - Subcontracting Description 2 alignment

        // [GIVEN] Complete Setup of Manufacturing
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();

        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [GIVEN] Description 2 is set on the subcontracting Work Center Name 2
        // (SubcCalcSubcontractsExt copies WorkCenter."Name 2" → RequisitionLine."Description 2")
        ExpectedDescription2 := 'TestDesc2_WC';
        WorkCenter[2].Get(WorkCenter[2]."No.");
        WorkCenter[2].Validate("Name 2", ExpectedDescription2);
        WorkCenter[2].Modify(true);

        // [GIVEN] Create requisition worksheet
        ReqWkshTemplate.DeleteAll(true);
        ReqWkshTemplate.Name := SelectRequisitionTemplateName();
        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.Validate(
            Name,
            CopyStr(
                LibraryUtility.GenerateRandomCode(RequisitionWkshName.FieldNo(Name), Database::"Requisition Wksh. Name"),
                1, LibraryUtility.GetFieldLength(Database::"Requisition Wksh. Name", RequisitionWkshName.FieldNo(Name))));
        RequisitionWkshName.Insert(true);

        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        // [WHEN] Calculate Subcontracts
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        // [THEN] Description 2 on the Requisition Line is populated
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();
        Assert.AreEqual(
            ExpectedDescription2, RequisitionLine."Description 2",
            'Description 2 must be populated on the Requisition Line from the subcontracting Work Center');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreateSubcontractingPOForEachProdOrderLineWhenLinesShareRoutingAndOperation()
    var
        Item: Record Item;
        ProductionLocation: array[2] of Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        ProdOrderRtng: TestPage "Prod. Order Routing";
        I: Integer;
        ProdOrderLineNo: array[2] of Integer;
    begin
        // [SCENARIO 634238] When a Released Production Order has multiple Prod. Order lines sharing the same
        // Routing/Operation, creating a Subcontracting Order for the second line must not raise the false
        // "Purchase orders have already been created" warning, and must create/show its own Purchase Order.

        // [GIVEN] Subcontracting setup with direct transfer (no in-transit route)
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        // [GIVEN] One released production order created directly from item
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 0);

        // [GIVEN] No production order lines exist yet for this order
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(0, ProdOrderLine.Count(), 'Expected no production order lines to exist before manually creating them');

        // [GIVEN] Two production order lines on the same production order, on different locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation[2]);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', ProductionLocation[1].Code, LibraryRandom.RandInt(10) + 2);
        ProdOrderLineNo[1] := ProdOrderLine."Line No.";
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', ProductionLocation[2].Code, LibraryRandom.RandInt(10) + 2);
        ProdOrderLineNo[2] := ProdOrderLine."Line No.";
        Assert.AreNotEqual(ProdOrderLineNo[1], ProdOrderLineNo[2], 'Expected two distinct production order lines');

        // [GIVEN] Refresh the production order to update the routing and component lines
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // [GIVEN] The two production-order lines have transfer components on different locations
        for I := 1 to 2 do begin
            ProdOrderRoutingLine.Reset();
            ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo[I]);
            ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
            Assert.RecordCount(ProdOrderRoutingLine, 1);

            ProdOrderRoutingLine.FindFirst();

            ProdOrderRtng.OpenView();
            ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
            ProdOrderRtng.CreateSubcontracting.Invoke();
            ProdOrderRtng.Close();

            Assert.AreEqual('A purchase order was created.\\Do you want to view it?', LibraryVariableStorage.DequeueText(), 'Expected "created" confirmation for each prod order line, not the false "already created" warning');
            LibraryVariableStorage.AssertEmpty();
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesShowSubcontractingPurchOrders,CapturePurchaseOrderPageNo')]
    procedure CreateSubcontractingPONavigatesToOwnPOWhenLinesShareRoutingAndOperation()
    var
        Item: Record Item;
        ProductionLocation: array[2] of Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        ProdOrderRtng: TestPage "Prod. Order Routing";
        I: Integer;
        ProdOrderLineNo: array[2] of Integer;
        OpenedPurchaseOrderNo: Code[20];
    begin
        // [SCENARIO 634238] When a Released Production Order has multiple Prod. Order lines sharing routing/operation,
        // confirming "view them" on the just-created Subcontracting Order must open the PO tied to the invoked
        // routing line, not the unrelated PO of a sibling line.

        // [GIVEN] Subcontracting setup with two prod order lines sharing routing/operation but different Routing Reference No.
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 0);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation[2]);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', ProductionLocation[1].Code, LibraryRandom.RandInt(10) + 2);
        ProdOrderLineNo[1] := ProdOrderLine."Line No.";
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', ProductionLocation[2].Code, LibraryRandom.RandInt(10) + 2);
        ProdOrderLineNo[2] := ProdOrderLine."Line No.";

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // [WHEN] Creating a Subcontracting Order from each routing line and confirming "view them"
        for I := 1 to 2 do begin
            ProdOrderRoutingLine.Reset();
            ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo[I]);
            ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
            ProdOrderRoutingLine.FindFirst();

            ProdOrderRtng.OpenView();
            ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
            ProdOrderRtng.CreateSubcontracting.Invoke();
            ProdOrderRtng.Close();

            // [THEN] The page handler opens the Purchase Order whose line carries this routing line's Routing Reference No.
            OpenedPurchaseOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(OpenedPurchaseOrderNo));
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
            PurchaseLine.SetRange("Document No.", OpenedPurchaseOrderNo);
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            PurchaseLine.SetRange("Routing Reference No.", ProdOrderLineNo[I]);
            Assert.IsFalse(PurchaseLine.IsEmpty(), StrSubstNo(PurchOrderRoutingErr, OpenedPurchaseOrderNo, ProdOrderLineNo[I]));
            LibraryVariableStorage.AssertEmpty();
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesShowSubcontractingPurchOrders,HandlePurchaseOrderPage,HandlePurchaseLinesPage')]
    procedure ShowExistingPurchOrdersOpensListWhenAlreadyCreated()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 633224] First Create Subcontracting Order opens the Purchase Order; running the action again on the same routing line opens the Purchase Lines list.

        // [GIVEN] Manufacturing setup with subcontracting work center, item with routing/BOM, released production order
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Order from the routing line for the first time
        PurchaseOrderPageOpened := false;
        PurchaseLinesPageOpened := false;
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] The Purchase Order card is shown
        Assert.IsTrue(PurchaseOrderPageOpened, 'Purchase Order should open after first creation.');
        Assert.IsFalse(PurchaseLinesPageOpened, 'Purchase Lines list should not open on first creation.');

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        Assert.IsFalse(PurchaseLine.IsEmpty(), 'Purchase line should exist for the production order.');

        // [WHEN] Create Subcontracting Order from the same routing line again
        PurchaseOrderPageOpened := false;
        PurchaseLinesPageOpened := false;
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] The Purchase Lines list is shown instead of individual Purchase Order cards
        Assert.IsTrue(PurchaseLinesPageOpened, 'Purchase Lines list should open when purchase orders already exist.');
        Assert.IsFalse(PurchaseOrderPageOpened, 'Purchase Order card should not open when purchase orders already exist.');
    end;

    [Test]
    procedure StandardTaskCodePropagatedAndDrivesSubcPriceLookup()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionLineWithStdTask: Record "Requisition Line";
        RequisitionLineNoStdTask: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        StandardTask: Record "Standard Task";
        SubcontractorPrice: Record "Subcontractor Price";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        LibraryUtility: Codeunit "Library - Utility";
        PriceWithoutStdTask: Decimal;
        PriceWithStdTask: Decimal;
        SecondOperationNo: Code[10];
    begin
        // [SCENARIO 633226] Standard Task Code propagates from Routing → Prod. Order Routing → Subcontracting Worksheet,
        // is editable on the worksheet, and drives Subcontractor Price lookup. Editing or clearing it on a worksheet
        // line re-applies the matching subcontractor price; carrying out creates Purchase Lines with the correct unit costs.

        Initialize();

        // [GIVEN] Subcontracting setup with a worksheet template
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] Work centers and a manufacturing item with routing and BOM
        //         (helper creates one subcontracting routing line on WorkCenter[2] without a Standard Task)
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        // [GIVEN] A standard task code
        LibraryManufacturing.CreateStandardTask(StandardTask);

        // [GIVEN] A second subcontracting routing line on the same work center, with the standard task assigned
        SecondOperationNo := AddSubcRoutingLineWithStandardTask(Item."Routing No.", WorkCenter[2]."No.", StandardTask.Code);

        // [GIVEN] Two subcontractor prices for the item / work center / vendor:
        //         - PriceWithoutStdTask, with no Standard Task Code
        //         - PriceWithStdTask = 2 * PriceWithoutStdTask, tied to StandardTask.Code
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        PriceWithoutStdTask := LibraryRandom.RandIntInRange(50, 200);
        PriceWithStdTask := PriceWithoutStdTask * 2;

        SubcontractorPrice.Reset();
        SubcontractorPrice.SetRange("Vendor No.", Vendor."No.");
        SubcontractorPrice.SetRange("Item No.", Item."No.");
        SubcontractorPrice.DeleteAll();

        Clear(SubcontractorPrice);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter[2]."No.", Vendor."No.", Item."No.", '', '',
            WorkDate(), Item."Base Unit of Measure", 0, Vendor."Currency Code");
        SubcontractorPrice."Direct Unit Cost" := PriceWithoutStdTask;
        SubcontractorPrice.Modify();

        Clear(SubcontractorPrice);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter[2]."No.", Vendor."No.", Item."No.", StandardTask.Code, '',
            WorkDate(), Item."Base Unit of Measure", 0, Vendor."Currency Code");
        SubcontractorPrice."Direct Unit Cost" := PriceWithStdTask;
        SubcontractorPrice.Modify();

        // [GIVEN] A released production order
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        // [THEN] Standard Task Code is propagated from Routing Line to Prod. Order Routing Line on the second operation
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", SecondOperationNo);
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(
            StandardTask.Code, ProdOrderRoutingLine."Standard Task Code",
            'Standard Task Code must be propagated from Routing Line to Prod. Order Routing Line.');

        // [GIVEN] An empty subcontracting worksheet
        ReqWkshTemplate.Name := SelectRequisitionTemplateName();
        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.Validate(
            Name,
            CopyStr(
                LibraryUtility.GenerateRandomCode(RequisitionWkshName.FieldNo(Name), Database::"Requisition Wksh. Name"),
                1, LibraryUtility.GetFieldLength(Database::"Requisition Wksh. Name", RequisitionWkshName.FieldNo(Name))));
        RequisitionWkshName.Insert(true);

        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        // [WHEN] Calculate Subcontracts is run on the worksheet
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        // [THEN] On the worksheet line for the operation with a standard task, Standard Task Code is populated
        //        and the standard-task-bound price is applied
        RequisitionLineWithStdTask.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLineWithStdTask.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLineWithStdTask.SetRange("Prod. Order No.", ProductionOrder."No.");
        RequisitionLineWithStdTask.SetRange("Operation No.", SecondOperationNo);
#pragma warning restore AA0210
        RequisitionLineWithStdTask.FindFirst();
        Assert.AreEqual(
            StandardTask.Code, RequisitionLineWithStdTask."Subc. Standard Task Code",
            'Standard Task Code must be propagated from Prod. Order Routing Line to the Subcontracting Worksheet line.');
        Assert.AreEqual(
            PriceWithStdTask, RequisitionLineWithStdTask."Direct Unit Cost",
            'Subcontractor Price tied to the Standard Task Code must be applied to the worksheet line.');

        // [THEN] On the worksheet line for the operation without a standard task, the un-tagged subcontractor price is applied
        RequisitionLineNoStdTask.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLineNoStdTask.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLineNoStdTask.SetRange("Prod. Order No.", ProductionOrder."No.");
        RequisitionLineNoStdTask.SetFilter("Operation No.", '<>%1', SecondOperationNo);
#pragma warning restore AA0210
        RequisitionLineNoStdTask.FindFirst();
        Assert.AreEqual(
            '', RequisitionLineNoStdTask."Subc. Standard Task Code",
            'Standard Task Code must be empty on the worksheet line that has no standard task on the routing.');
        Assert.AreEqual(
            PriceWithoutStdTask, RequisitionLineNoStdTask."Direct Unit Cost",
            'Subcontractor Price for the un-tagged combination must be applied to the worksheet line.');

        // [WHEN] User clears Standard Task Code on the worksheet line
        RequisitionLineWithStdTask.Validate("Subc. Standard Task Code", '');
        RequisitionLineWithStdTask.Modify(true);

        // [THEN] Direct Unit Cost falls back to the un-tagged subcontractor price
        Assert.AreEqual(
            PriceWithoutStdTask, RequisitionLineWithStdTask."Direct Unit Cost",
            'Clearing Standard Task Code on the worksheet line must re-apply the un-tagged subcontractor price.');

        // [WHEN] User re-sets Standard Task Code on the worksheet line
        RequisitionLineWithStdTask.Validate("Subc. Standard Task Code", StandardTask.Code);
        RequisitionLineWithStdTask.Modify(true);

        // [THEN] Direct Unit Cost is restored to the standard-task-bound subcontractor price
        Assert.AreEqual(
            PriceWithStdTask, RequisitionLineWithStdTask."Direct Unit Cost",
            'Re-setting Standard Task Code on the worksheet line must re-apply the standard-task-bound subcontractor price.');

        // [WHEN] Carry Out Action Message creates the Subcontracting Purchase Order from the worksheet
        Clear(RequisitionLine);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] The purchase line for the operation with a standard task has Direct Unit Cost = PriceWithStdTask
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.SetRange("Operation No.", SecondOperationNo);
        PurchaseLine.FindFirst();
        Assert.AreEqual(
            PriceWithStdTask, PurchaseLine."Direct Unit Cost",
            'Subcontracting Purchase Line for the operation with a standard task must use the standard-task-bound subcontractor price.');

        // [THEN] The purchase line for the operation without a standard task has Direct Unit Cost = PriceWithoutStdTask
        PurchaseLine.SetFilter("Operation No.", '<>%1', SecondOperationNo);
        PurchaseLine.FindFirst();
        Assert.AreEqual(
            PriceWithoutStdTask, PurchaseLine."Direct Unit Cost",
            'Subcontracting Purchase Line for the operation without a standard task must use the un-tagged subcontractor price.');
    end;

    [Test]
    procedure WorksheetDirectUnitCostUsesQtyPerUoMNotBaseQtyForUoMConversion()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        RequisitionLine: Record "Requisition Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        QtyPerSet: Integer;
        PriceListUnitCost: Decimal;
    begin
        // [SCENARIO 636078] Calculate Subcontracts must compute Direct Unit Cost on the Subcontracting
        // Worksheet using the per-UoM conversion factor (GetQuantityForUOM()), not the total base
        // quantity (GetQuantityBase()) of the order.

        // [GIVEN] Item with PCS base UoM and a SET alternative UoM (10 PCS per SET).
        Initialize();
        LibraryInventory.CreateItem(Item);
        QtyPerSet := 10;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", QtyPerSet);

        // [GIVEN] Vendor and Work Center with the vendor as its subcontractor.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);

        // [GIVEN] A subcontractor price in the blank fallback UoM with Minimum Quantity 1 and Direct
        // Unit Cost 1000 — the blank-UoM row matches the SET line's '%1|%2' UoM filter and exercises
        // the cross-UoM conversion (PriceListUOM resolves to the item's base UoM).
        PriceListUnitCost := 1000;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), '', 1, '');
        SubcontractorPrice.Validate("Direct Unit Cost", PriceListUnitCost);
        SubcontractorPrice.Modify(true);

        // [GIVEN] A staged Requisition Line for 3 SET (= 30 PCS in base UoM).
        RequisitionLine.Init();
        RequisitionLine."No." := Item."No.";
        RequisitionLine."Unit of Measure Code" := ItemUOM.Code;
        RequisitionLine."Vendor No." := Vendor."No.";
        RequisitionLine."Work Center No." := WorkCenter."No.";
        RequisitionLine."Order Date" := WorkDate();
        RequisitionLine.Quantity := 3;

        // [WHEN] The subcontractor price is applied to the requisition line.
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] Direct Unit Cost = price-list cost * Qty-per-UoM (1000 * 10 = 10000),
        // not price-list cost * total base quantity (1000 * 30 = 30000 — the pre-fix behavior).
        Assert.AreEqual(
            PriceListUnitCost * QtyPerSet, RequisitionLine."Direct Unit Cost",
            'Direct Unit Cost on the Subcontracting Worksheet must be derived from Qty. per Unit of Measure, not from total base quantity.');

        // [WHEN] The same price is applied to a Requisition Line using the base UoM (no conversion needed).
        Clear(RequisitionLine);
        RequisitionLine.Init();
        RequisitionLine."No." := Item."No.";
        RequisitionLine."Unit of Measure Code" := Item."Base Unit of Measure";
        RequisitionLine."Vendor No." := Vendor."No.";
        RequisitionLine."Work Center No." := WorkCenter."No.";
        RequisitionLine."Order Date" := WorkDate();
        RequisitionLine.Quantity := 30;
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] Direct Unit Cost equals the price-list cost (the same-UoM path is unchanged by the fix).
        Assert.AreEqual(
            PriceListUnitCost, RequisitionLine."Direct Unit Cost",
            'Direct Unit Cost must equal the price-list cost when the worksheet UoM matches the price-list UoM.');
    end;

    [Test]
    procedure ReqLinePriceUsesOrderUoMWhenFixedUOMIsEmpty()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        RequisitionLine: Record "Requisition Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        AltUOMCode: Code[10];
        PcsPrice, SetPrice : Decimal;
        QtyPerSet: Integer;
    begin
        // [SCENARIO 636059] GetSubcPriceForReqLine must filter Subcontractor Prices by the
        // requisition line's Unit of Measure (with blank fallback) even when the caller passes
        // FixedUOM = '' — otherwise the alphabetically-last UoM row wins regardless of the line's UoM.
        Initialize();

        // [GIVEN] Item with Base UoM and an alternative UoM (10 base per alt) whose code sorts after the base.
        LibraryInventory.CreateItem(Item);
        QtyPerSet := 10;
        AltUOMCode := CreateUOMCodeSortingAfter(Item."Base Unit of Measure");
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", AltUOMCode, QtyPerSet);

        // [GIVEN] Vendor and Work Center with the vendor as its subcontractor.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);

        // [GIVEN] Two subcontractor prices — Base UoM = 1001, alternative UoM = 1004.
        PcsPrice := 1001;
        SetPrice := 1004;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", PcsPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), AltUOMCode, 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", SetPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] A staged Requisition Line in the Base UoM with FixedUOM = ''.
        RequisitionLine.Init();
        RequisitionLine."No." := Item."No.";
        RequisitionLine."Unit of Measure Code" := Item."Base Unit of Measure";
        RequisitionLine."Vendor No." := Vendor."No.";
        RequisitionLine."Work Center No." := WorkCenter."No.";
        RequisitionLine."Order Date" := WorkDate();
        RequisitionLine.Quantity := 1;

        // [WHEN] GetSubcPriceForReqLine is called with no FixedUOM.
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] Direct Unit Cost equals the Base UoM price (1001), not the alt-UoM derived 100.40.
        Assert.AreEqual(
            PcsPrice, RequisitionLine."Direct Unit Cost",
            'GetSubcPriceForReqLine must pick the price row matching the line''s Unit of Measure when FixedUOM is empty.');
    end;

    [Test]
    procedure VendorSuppliedCompQtyUpdatedOnPurchOrderReschedule()
    var
        Item: Record Item;
        ComponentItem: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineComp: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        InitialQty: Decimal;
        NewQty: Decimal;
    begin
        // [SCENARIO 637496] When a production order quantity changes and the subcontracting purchase order
        // is rescheduled via the requisition worksheet, the Vendor-Supplied component purchase lines
        // should be updated to reflect the new quantity.

        // [GIVEN] A subcontracting setup with a Vendor-Supplied component
        Initialize();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] A released production order
        InitialQty := LibraryRandom.RandIntInRange(5, 10);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", InitialQty);

        // [GIVEN] A subcontracting purchase order created via the requisition worksheet
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        CarryOutSubcontractingAction(RequisitionLine);

        // [GIVEN] The vendor-supplied component purchase line exists
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
#pragma warning disable AA0210        
        ProductionBOMLine.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProductionBOMLine.FindFirst();
        ComponentItem.Get(ProductionBOMLine."No.");

        FindSubcPurchLineForProdOrder(PurchaseLine, Item."No.", ProductionOrder."No.");
        FindComponentPurchLine(PurchaseLineComp, PurchaseLine."Document No.", ComponentItem."No.");
        Assert.IsTrue(PurchaseLineComp.FindFirst(), 'Vendor-Supplied component purchase line should exist after initial PO creation.');

        // [WHEN] The production order quantity is increased and refreshed
        NewQty := InitialQty + LibraryRandom.RandIntInRange(3, 7);
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, NewQty);
        ProdOrderLine.Modify(true);

        // [WHEN] CalculateSubcontracts is run again and carried out (reschedule path)
        CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);

        Assert.IsTrue(
            RequisitionLine."Action Message" in
                [RequisitionLine."Action Message"::"Change Qty.",
                 RequisitionLine."Action Message"::"Resched. & Chg. Qty."],
            'Requisition line should have a Change Qty or Reschedule action message.');

        CarryOutSubcontractingAction(RequisitionLine);

        // [THEN] The component purchase line quantity matches the updated component remaining quantity
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
#pragma warning disable AA0210        
        ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProdOrderComponent.FindFirst();

        PurchaseLineComp.FindFirst();
        Assert.AreEqual(
            ProdOrderComponent."Remaining Quantity",
            PurchaseLineComp.Quantity,
            'Vendor-Supplied component purchase line quantity should match the updated production order component remaining quantity.');
    end;

    [ConfirmHandler]
    procedure ConfirmYesShowSubcontractingPurchOrders(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    procedure HandlePurchaseOrderPage(var PurchaseOrderPage: TestPage "Purchase Order")
    begin
        PurchaseOrderPageOpened := true;
        PurchaseOrderPage.Close();
    end;

    [PageHandler]
    procedure CapturePurchaseOrderPageNo(var PurchaseOrderPage: TestPage "Purchase Order")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrderPage."No.".Value);
        PurchaseOrderPage.Close();
    end;

    [PageHandler]
    procedure HandlePurchaseLinesPage(var PurchaseLinesPage: TestPage "Purchase Lines")
    begin
        PurchaseLinesPageOpened := true;
        PurchaseLinesPage.Close();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        case true of
            Question.Contains('Do you want to create a production order from'):
                Reply := true;
            else
                Reply := false;
        end;
    end;

    local procedure AddSubcRoutingLineWithStandardTask(RoutingNo: Code[20]; WorkCenterNo: Code[20]; StandardTaskCode: Code[10]) NewOperationNo: Code[10]
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
#pragma warning disable AA0210
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
#pragma warning restore AA0210
        CapacityUnitOfMeasure.FindFirst();

        RoutingHeader.Get(RoutingNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        // Use a number larger than any existing operation so the certification-time ordering check is satisfied.
        NewOperationNo := CopyStr(IncStr(FindLastRoutingOperationNo(RoutingNo)), 1, MaxStrLen(NewOperationNo));

        LibraryManufacturing.CreateRoutingLineSetup(
            RoutingLine, RoutingHeader, WorkCenterNo, NewOperationNo,
            LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Standard Task Code", StandardTaskCode);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure FindLastRoutingOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindLast();
        exit(RoutingLine."Operation No.");
    end;

    local procedure CreateAndCalculateNeededWorkAndMachineCenter(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarCode: Code[10];
        MachineCenterNo: Code[20];
        MachineCenterNo2: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();

        // [GIVEN] Create and Calculate needed Work and Machine Center
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::"Pick + Manual", not Subcontracting, UnitCostCalculation, '');
        WorkCenter[1].Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter[1], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::"Pick + Manual".AsInteger());
        MachineCenter[1].Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[1], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo2, WorkCenterNo, "Flushing Method"::"Pick + Manual".AsInteger());
        MachineCenter[2].Get(MachineCenterNo2);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[2], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        if Subcontracting then
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::"Pick + Manual", Subcontracting, UnitCostCalculation, '')
        else
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::"Pick + Manual", not Subcontracting, UnitCostCalculation, '');
        WorkCenter[2].Get(WorkCenterNo2);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter[2], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));
    end;

    local procedure CreateItemForProductionIncludeRoutingAndProdBOM(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        NoSeries: Codeunit "No. Series";
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ProductionBOMNo: Code[20];
        RoutingNo: Code[20];
    begin
        ManufacturingSetup.SetLoadFields("Routing Nos.");
        ManufacturingSetup.Get();
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.", WorkDate(), true);

        LibraryMfgManagement.CreateRouting(RoutingNo, MachineCenter[1]."No.", MachineCenter[2]."No.", WorkCenter[1]."No.", WorkCenter[2]."No.");

        // Create Items with Flushing method - Manual with the Parent Item containing Routing No. and Production BOM No.

        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", '', '');
        ItemNo := Item."No.";
        Clear(Item);
        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", '', '');
        ItemNo2 := Item."No.";
        Clear(Item);

        ProductionBOMNo := LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ItemNo, ItemNo2, 1); // value important.

        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", RoutingNo, ProductionBOMNo);
    end;

    local procedure UpdateProdBomAndRoutingWithRoutingLink(Item: Record Item; WorkCenterNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        RoutingLink.Init();
        RoutingLink.Validate(Code, CopyStr(Item."Production BOM No.", 1, 10));
        RoutingLink.Insert(true);

        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateVendorWithSubcontractingLocationCode(WorkCenter: Record "Work Center")
    var
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
    end;

    local procedure CreateWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; Subcontract: Boolean;
                                                                                                           UnitCostCalc: Option;
                                                                                                           CurrencyCode: Code[10])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        WorkCenter: Record "Work Center";
    begin
        // Create Work Center with required fields where random is used, values not important for test.
        LibraryMfgManagement.CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, 0);

        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Overhead Rate", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalc);

        if Subcontract then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GenProductPostingGroup.FindFirst();
            GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GenProductPostingGroup.Modify(true);
            WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(CurrencyCode));
        end;
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure CreateItem(var Item: Record Item; ItemCostingMethod: Enum "Costing Method"; ItemReorderPolicy: Enum "Reordering Policy";
                                                                             FlushingMethod: Enum "Flushing Method";
                                                                             RoutingNo: Code[20];
                                                                             ProductionBOMNo: Code[20])
    begin
        // Create Item with required fields where random values not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandInt(10), ItemReorderPolicy, FlushingMethod, RoutingNo, ProductionBOMNo);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(5, 2));
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 2));
        Item.Modify(true);
    end;

    local procedure CalculateSubcontractsAndFindReqLine(RequisitionWkshName: Record "Requisition Wksh. Name"; ProdOrderNo: Code[20]; var RequisitionLine: Record "Requisition Line")
    var
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
    begin
        Clear(RequisitionLine);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProdOrderNo);
#pragma warning restore AA0210
        RequisitionLine.FindFirst();
    end;

    local procedure CarryOutSubcontractingAction(var RequisitionLine: Record "Requisition Line")
    var
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();
    end;

    local procedure FindSubcPurchLineForProdOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; ProdOrderNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindComponentPurchLine(var PurchaseLineComp: Record "Purchase Line"; DocumentNo: Code[20]; ComponentItemNo: Code[20])
    begin
        PurchaseLineComp.SetRange("Document Type", PurchaseLineComp."Document Type"::Order);
        PurchaseLineComp.SetRange("Document No.", DocumentNo);
        PurchaseLineComp.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLineComp.SetRange("No.", ComponentItemNo);
    end;

    local procedure CreateUOMCodeSortingAfter(BaseUOMCode: Code[10]): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
        LibraryUtility: Codeunit "Library - Utility";
        NewCode: Code[10];
    begin
        // LibraryInventory.CreateUnitOfMeasureCode generates a hex-only code (truncated GUID), so
        // any code with a 'Z' prefix is guaranteed to sort after it. This makes the multi-UoM test
        // deterministic — without the fix, FindLast() picks the alt UoM row.
        repeat
            NewCode := CopyStr('Z' + LibraryUtility.GenerateGUID(), 1, MaxStrLen(NewCode));
        until not UnitOfMeasure.Get(NewCode);
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := NewCode;
        UnitOfMeasure.Description := NewCode;
        UnitOfMeasure.Insert(true);
        if UnitOfMeasure.Code <= BaseUOMCode then
            Error('Test setup: generated UoM code %1 must sort after base UoM code %2.', UnitOfMeasure.Code, BaseUOMCode);
        exit(UnitOfMeasure.Code);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Purchase Order Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        UpdateSubMgmtSetupWithReqWkshTemplate();
        LibraryVariableStorage.Clear();

        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Purchase Order Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Purchase Order Test");
    end;

    local procedure UpdateSubMgmtSetupWithReqWkshTemplate()
    begin
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
    end;

    local procedure UpdateSubMgmtSetupTransferInfoLine(Update: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Create Prod. Order Info Line" := Update;
        ManufacturingSetup.Modify();
    end;

    procedure SelectRequisitionTemplateName(): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Subcontracting);
        ReqWkshTemplate.SetRange(Recurring, false);
        if not ReqWkshTemplate.FindFirst() then begin
            ReqWkshTemplate.Init();
            ReqWkshTemplate.Validate(
              Name, LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"));
            ReqWkshTemplate.Insert(true);
            ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::Subcontracting);
            ReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
            ReqWkshTemplate.Modify(true);
        end;
        exit(ReqWkshTemplate.Name);
    end;

    var
        WorkCenter2: Record "Work Center";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        PurchaseOrderPageOpened: Boolean;
        PurchaseLinesPageOpened: Boolean;
        UnitCostCalculation: Option Time,Units;
        PurchOrderRoutingErr: Label 'Purchase Order %1 should contain a line tied to Routing Reference No. %2', Comment = '%1 = Purchase Order No., %2 = Routing Reference No.';

}
