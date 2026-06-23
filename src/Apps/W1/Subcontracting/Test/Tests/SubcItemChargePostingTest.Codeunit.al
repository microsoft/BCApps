// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

codeunit 149917 "Subc. Item Charge Posting Test"
{
    // [FEATURE] Subcontracting Item Charge Posting
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
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
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        UnitCostCalculation: Option Time,Units;

    [Test]
    [HandlerFunctions('ConfirmHandler,HandlePurchaseOrderPage')]
    procedure ItemChargePostingForLastOperationSubcontractingReceipt()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        SubcWorkCenter: Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        Qty: Decimal;
        SerialNo: Code[50];
    begin
        // [SCENARIO] Posting an item charge assigned to a subcontracting purchase receipt for the last routing operation should succeed.
        // [SCENARIO] Before the fix, it errored with "The Capacity Ledger Entry does not exist" because the posting path incorrectly
        // [SCENARIO] attempted to create a value entry against a capacity ledger entry instead of the output item ledger entry.

        // [GIVEN] Subcontracting setup with a single-operation routing where the operation is a subcontracting work center (= last operation)
        Initialize();
        UnitCostCalculation := UnitCostCalculation::Units;
        CreateItemWithSingleSubcontractingOperation(Item, SubcWorkCenter);
        AddSerialTrackingToItem(Item);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(SubcWorkCenter);

        // [GIVEN] A released production order for qty = 1 (required for serial tracking)
        Qty := 1;
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);

        // [GIVEN] Assign a serial number to the production order line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        SerialNo := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo, '', Qty);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", SubcWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [GIVEN] The subcontracting purchase order is found and its receipt posted
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", SubcWorkCenter."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] The serial number is assigned to the purchase line before posting receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] The posted receipt line for the subcontracting order
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] A purchase invoice at the same vendor with an item charge line
        Vendor.Get(SubcWorkCenter."Subcontractor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineCharge, PurchaseHeaderInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", Qty);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLineCharge.Modify(true);
        EnsureGeneralPostingSetupIsValid(PurchaseLineCharge."Gen. Bus. Posting Group", PurchaseLineCharge."Gen. Prod. Posting Group");

        // [GIVEN] The item charge is assigned to the subcontracting receipt line
        AssignItemChargeToReceiptLine(PurchaseLineCharge, PurchRcptLine, Qty, PurchaseLineCharge."Direct Unit Cost");

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] The posting succeeds and a value entry of type "Direct Cost" exists linked to the item's output ledger entry
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.RecordIsNotEmpty(ValueEntry);

        // [THEN] The value entry is linked to an output item ledger entry (not a capacity ledger entry)
        ValueEntry.FindLast();
        Assert.AreNotEqual(0, ValueEntry."Item Ledger Entry No.", 'Value entry should be linked to an item ledger entry.');

        // [THEN] The item ledger entry has the correct serial number
        ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
        Assert.AreEqual(SerialNo, ItemLedgerEntry."Serial No.", 'Item ledger entry should carry the serial number from the production order.');

        // [THEN] The value entry cost equals the item charge direct unit cost (qty = 1)
        Assert.AreEqual(PurchaseLineCharge."Direct Unit Cost", ValueEntry."Cost Amount (Actual)",
            'Value entry cost amount should match the item charge direct unit cost.');
        Assert.AreEqual(PurchaseLineCharge."Direct Unit Cost", ValueEntry."Cost per Unit",
            'Value entry cost per unit should match the item charge direct unit cost.');
        Assert.AreEqual(Qty, ValueEntry."Valued Quantity", 'Value entry valued quantity should match the invoiced quantity.');

        // [THEN] The value entry references the production order (not a blank order)
        Assert.AreEqual("Inventory Order Type"::Production, ValueEntry."Order Type",
            'Value entry order type should be Production.');
        Assert.AreEqual(ProductionOrder."No.", ValueEntry."Order No.",
            'Value entry order no. should match the production order.');
        Assert.AreEqual(ProdOrderLine."Line No.", ValueEntry."Order Line No.",
            'Value entry order line no. should match the production order line.');
    end;

    local procedure AddSerialTrackingToItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code,
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'),
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, false);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", SerialNoSeries.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemWithSingleSubcontractingOperation(var Item: Record Item; var SubcWorkCenter: Record "Work Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ComponentItem1: Record Item;
        ComponentItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ShopCalendarCode: Code[10];
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();
        CreateSubcontractingWorkCenter(WorkCenterNo, ShopCalendarCode);
        SubcWorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(SubcWorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", SubcWorkCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        LibraryInventory.CreateItem(ComponentItem1);
        LibraryInventory.CreateItem(ComponentItem2);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ComponentItem1."No.", ComponentItem2."No.", 1);

        LibraryManufacturing.CreateItemManufacturing(
            Item, "Costing Method"::FIFO, LibraryRandom.RandInt(10),
            "Reordering Policy"::"Lot-for-Lot", Microsoft.Manufacturing.Setup."Flushing Method"::"Pick + Manual",
            RoutingHeader."No.", ProductionBOMHeader."No.");
    end;

    local procedure CreateSubcontractingWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        WorkCenter: Record "Work Center";
    begin
        LibraryMfgManagement.CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, 0);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalculation);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GenProductPostingGroup.FindFirst();
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenProductPostingGroup.Modify(true);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure AssignItemChargeToReceiptLine(PurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; QtyToAssign: Decimal; AmountToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        NextLineNo: Integer;
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseLine."Line No.");
        if ItemChargeAssignmentPurch.FindLast() then
            NextLineNo := ItemChargeAssignmentPurch."Line No." + 10000
        else
            NextLineNo := 10000;

        ItemChargeAssignmentPurch.Init();
        ItemChargeAssignmentPurch."Document Type" := PurchaseLine."Document Type";
        ItemChargeAssignmentPurch."Document No." := PurchaseLine."Document No.";
        ItemChargeAssignmentPurch."Document Line No." := PurchaseLine."Line No.";
        ItemChargeAssignmentPurch."Item Charge No." := PurchaseLine."No.";
        ItemChargeAssignmentPurch."Unit Cost" := PurchaseLine."Direct Unit Cost";

        ItemChargeAssgntPurch.InsertItemChargeAssignmentWithValues(
            ItemChargeAssignmentPurch,
            "Purchase Applies-to Document Type"::Receipt,
            PurchRcptLine."Document No.",
            PurchRcptLine."Line No.",
            PurchRcptLine."No.",
            PurchRcptLine.Description,
            QtyToAssign,
            AmountToAssign,
            NextLineNo);
    end;

    local procedure EnsureGeneralPostingSetupIsValid(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then begin
            if GeneralPostingSetup.Blocked then begin
                GeneralPostingSetup.Blocked := false;
                GeneralPostingSetup.Modify();
            end;
            exit;
        end;
        GeneralPostingSetup.Init();
        GeneralPostingSetup."Gen. Bus. Posting Group" := GenBusPostingGroup;
        GeneralPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup;
        GeneralPostingSetup.Insert();
        GeneralPostingSetup.SuggestSetupAccounts();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Item Charge Posting Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Item Charge Posting Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        LibraryMfgManagement.Initialize();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Item Charge Posting Test");
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    procedure HandlePurchaseOrderPage(var PurchaseOrderPage: TestPage "Purchase Order")
    begin
        PurchaseOrderPage.Close();
    end;
}