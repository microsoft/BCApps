// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 139991 "Subc. Purch. Subcont. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management
        IsInitialized := false;
    end;

    var
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
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        ErrorCounter: Integer;
        ErrorMessageDescriptionList: List of [Text];
        UnitCostCalculation: Option Time,Units;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess')]
    procedure CreateProductionOrderFromPurchaseOrder_PurchPrice()
    var
        Location, Location2 : Record Location;
        ProdOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        RoutingLink: Record "Routing Link";
        SubcontractorPrices, SubcontractorPrices2 : Record "Subcontractor Price";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        ItemNo, ItemNoOriginPurchLine : Code[20];
        PurchOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Production Order from Purchase Order from scratch
        Initialize();

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateAndCalculateNeededWorkCenter(WorkCenter, false);
        UpdateSubMgmtCommonWorkCenter(WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        UpdateSubMgmtRoutingLink(RoutingLink.Code);

        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateLocation(Location2);
        ItemNo := LibraryInventory.CreateItemNo();

        LibraryPurchase.CreateVendor(Vendor);
        WorkCenter."Subcontractor No." := Vendor."No.";
        WorkCenter.Modify();
        SubcontractingMgmtLibrary.CreateSubContractingPrice(SubcontractorPrices, WorkCenter."No.", Vendor."No.", ItemNo, '', '', WorkDate(), '', 0, Vendor."Currency Code");
        SubcontractorPrices."Direct Unit Cost" := 99;
        SubcontractorPrices.Modify();
        Vendor."Subcontr. Location Code" := Location2.Code;
        Vendor.Modify();

        LibraryPurchase.CreateVendor(Vendor);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(SubcontractorPrices2, WorkCenter."No.", Vendor."No.", ItemNo, '', '', WorkDate(), '', 0, Vendor."Currency Code");
        SubcontractorPrices2."Direct Unit Cost" := 11;
        SubcontractorPrices2.Modify();
        Vendor."Subcontr. Location Code" := Location2.Code;
        Vendor.Modify();

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchaseHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        ItemNoOriginPurchLine := PurchLine."No.";
        PurchLine.Modify(true);

        // [WHEN] Create Prod Order from scratch
        Commit();
        PurchOrder.OpenEdit();
        PurchOrder.GoToRecord(PurchaseHeader);
        PurchOrder.PurchLines.CreateProdOrder.Invoke();

        // [THEN]
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchLine.SetRange("No.", ItemNoOriginPurchLine);
        Assert.RecordCount(PurchLine, 1);
        PurchLine.FindFirst();
        PurchLine.TestField("Direct Unit Cost", SubcontractorPrices2."Direct Unit Cost");
        PurchLine.TestField("Line Amount", PurchLine.Quantity * 11);

        // [TEARDOWN]
        PurchLine.SetRange("No.", ItemNoOriginPurchLine);
        PurchLine.FindFirst();
        ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.");
        PurchLine."Prod. Order No." := '';
        PurchLine.Modify();
        ProdOrder.Delete(true);
        UpdateSubMgmtCommonWorkCenter('');
        UpdateSubMgmtRoutingLink('');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess')]
    procedure CreateProductionOrderFromPurchaseOrder_PurchPrice_Variant()
    var
        ItemVariant: Record "Item Variant";
        Location, Location2 : Record Location;
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        RoutingLink: Record "Routing Link";
        SubcontractorPrices2: Record "Subcontractor Price";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        VariantCode: Code[10];
        ItemNo, ItemNoOriginPurchLine : Code[20];
        PurchOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Production Order from Purchase Order from scratch
        IsInitialized := false;
        Initialize();

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateAndCalculateNeededWorkCenter(WorkCenter, false);
        UpdateSubMgmtCommonWorkCenter(WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        UpdateSubMgmtRoutingLink(RoutingLink.Code);

        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateLocation(Location2);
        ItemNo := LibraryInventory.CreateItemNo();
        VariantCode := LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);

        LibraryPurchase.CreateVendor(Vendor);
        WorkCenter."Subcontractor No." := Vendor."No.";
        WorkCenter.Modify();
        SubcontractingMgmtLibrary.CreateSubContractingPrice(SubcontractorPrices2, WorkCenter."No.", Vendor."No.", ItemNo, '', ItemVariant.Code, WorkDate(), '', 0, Vendor."Currency Code");
        SubcontractorPrices2."Direct Unit Cost" := 11;
        SubcontractorPrices2.Modify();
        Vendor."Subcontr. Location Code" := Location2.Code;
        Vendor.Modify();

        SubcontractingMgmtLibrary.CreateSubContractingPrice(SubcontractorPrices2, WorkCenter."No.", Vendor."No.", ItemNo, '', '', WorkDate(), '', 0, Vendor."Currency Code");
        SubcontractorPrices2."Direct Unit Cost" := 8;
        SubcontractorPrices2.Modify();

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchaseHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        PurchLine.Validate("Variant Code", ItemVariant.Code);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        ItemNoOriginPurchLine := PurchLine."No.";
        PurchLine.Modify(true);

        // [WHEN] Create Prod Order from scratch
        Commit();
        PurchOrder.OpenEdit();
        PurchOrder.GoToRecord(PurchaseHeader);
        PurchOrder.PurchLines.CreateProdOrder.Invoke();

        // [THEN]
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchLine.SetRange("No.", ItemNoOriginPurchLine);
        Assert.RecordCount(PurchLine, 1);
        PurchLine.FindFirst();
        ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderRtngLine.SetRange("Work Center No.", PurchLine."Work Center No.");
        ProdOrderRtngLine.FindFirst();
        PurchLine.TestField("Direct Unit Cost", ProdOrderRtngLine."Direct Unit Cost");
        PurchLine.TestField("Line Amount", PurchLine.Quantity * 11);

        // [TEARDOWN]
        PurchLine.SetRange("No.", ItemNoOriginPurchLine);
        PurchLine.FindFirst();
        ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.");
        PurchLine."Prod. Order No." := '';
        PurchLine.Modify();
        ProdOrder.Delete(true);
        UpdateSubMgmtCommonWorkCenter('');
        UpdateSubMgmtRoutingLink('');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess,ErrorPageHandler')]
    procedure CreateProductionOrderFromPurchaseOrderWithDropShipment()
    var
        Location, Location2 : Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        RoutingLink: Record "Routing Link";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        NotSupportedErr: Label 'Drop Shipment must be equal to', Locked = true;
        PurchOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Production Order from Purchase Order from scratch
        Initialize();

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateAndCalculateNeededWorkCenter(WorkCenter, false);
        UpdateSubMgmtCommonWorkCenter(WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        UpdateSubMgmtRoutingLink(RoutingLink.Code);

        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateLocation(Location2);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontr. Location Code" := Location2.Code;
        Vendor.Modify();

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchaseHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchLine.Validate("Drop Shipment", true);
        PurchLine.Modify(true);

        // [WHEN] Create Prod Order from scratch
        Commit();
        PurchOrder.OpenEdit();
        PurchOrder.GoToRecord(PurchaseHeader);
        PurchOrder.PurchLines.CreateProdOrder.Invoke();

        // [THEN] Error occurs as drop shipment is not supported
        Assert.AreEqual(1, ErrorCounter, 'Error message should be added for each related record');
        Assert.IsSubstring(ErrorMessageDescriptionList.Get(1), NotSupportedErr);

        // [TEARDOWN]
        UpdateSubMgmtCommonWorkCenter('');
        UpdateSubMgmtRoutingLink('');
    end;

    [PageHandler]
    procedure ErrorPageHandler(var ErrorMessageTestPage: TestPage "Error Messages")
    begin
        ErrorMessageTestPage.First();
        repeat
            ErrorMessageDescriptionList.Add(ErrorMessageTestPage.Description.Value());
            ErrorCounter += 1;
        until not ErrorMessageTestPage.Next();
        ErrorMessageTestPage.Close();
    end;

    [ConfirmHandler]
    procedure DoConfirmCreateProdOrderForSubcontractingProcess(Question: Text[1024]; var Reply: Boolean)
    begin
        case true of
            Question.Contains('Do you want to create a production order from'):
                Reply := true;
            else
                Reply := false;
        end;
    end;

    [MessageHandler]
    procedure MessageBOMCreated(MessageText: Text[1024])
    begin
    end;

    local procedure CreateAndCalculateNeededWorkCenter(var WorkCenter: Record "Work Center"; IsSubcontracting: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarCode: Code[10];
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();

        // [GIVEN] Create and Calculate needed Work and Machine Center
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::"Pick + Manual", IsSubcontracting, UnitCostCalculation, '');
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));
    end;

    local procedure CreateWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; IsSubcontracting: Boolean; UnitCostCalc: Option; CurrencyCode: Code[10])
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

        if IsSubcontracting then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GenProductPostingGroup.FindFirst();
            GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GenProductPostingGroup.Modify(true);
            WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(CurrencyCode));
        end;
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Purch. Subcont. Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Purch. Subcont. Test");

        SubSetupLibrary.InitSetupFields();
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Purch. Subcont. Test");
    end;

    local procedure UpdateSubMgmtCommonWorkCenter(WorkCenterNo: Code[20])
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Common Work Center No." := WorkCenterNo;
        EsMgmtSetup.Modify();
    end;

    local procedure UpdateSubMgmtRoutingLink(RtngLink: Code[10])
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Rtng. Link Code Purch. Prov." := RtngLink;
        EsMgmtSetup.Modify();
    end;
}