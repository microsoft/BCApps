// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Vat.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

codeunit 149912 "Subc SCM Inventory Misc."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        SubcManagementLibrary: Codeunit "Subc. Management Library";
        isInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Subc SCM Inventory Misc.");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Subc SCM Inventory Misc.");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Subc SCM Inventory Misc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostLCYOnPurchOrderWithCurrency()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        WorkCenter: Record "Work Center";
    begin
        // Verify Unit Cost(LCY) on Purchase Line when Subcontracting Purchase Order is created with Foreign Currency.

        // Setup: Create Work Center, create and refresh Production Order.
        Initialize();
        CreateWorkCenterWithSubcontractor(WorkCenter);
        UpdateRoutingOnItem(Item, WorkCenter."No.");
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.", '', LibraryRandom.RandDec(10, 2));  // Take random Quantity.

        // Exercise: Carry Out Action Message on SubContract Worksheet.
        CarryOutAMSubcontractWksh(WorkCenter."No.", Item."No.");

        // Verify: Verify Unit Cost(LCY) on Purchase Line when Subcontracting Purchase Order is created with Foreign Currency.
        FindPurchaseLine(PurchaseLine, Item."No.");
        FindCurrencyExchangeRate(CurrencyExchangeRate, PurchaseLine."Currency Code");
        PurchaseLine.TestField(
          "Unit Cost (LCY)",
          PurchaseLine."Direct Unit Cost" *
          CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityLedgerEntryAfterPostPurchOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        WorkCenter: Record "Work Center";
    begin
        // Verify Capacity Ledger Entries when Subcontracting Purchase Order is created and posted with Foreign Currency.

        // Setup: Create Work Center, create and refresh Production Order and Carry Out Action Message on SubContract Worksheet.
        Initialize();
        CreateWorkCenterWithSubcontractor(WorkCenter);
        UpdateRoutingOnItem(Item, WorkCenter."No.");
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.", '', LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        CarryOutAMSubcontractWksh(WorkCenter."No.", Item."No.");

        // Exercise: Post Purchase Order.
        FindPurchLineAndPostPurchOrder(PurchaseLine, Item."No.");

        // Verify: Verify Capacity Ledger Entries when Subcontracting Purchase Order is posted with Foreign Currency.
        FindCurrencyExchangeRate(CurrencyExchangeRate, PurchaseLine."Currency Code");
        FindCapacityLedgerEntry(CapacityLedgerEntry, ProductionOrder."No.");
        CapacityLedgerEntry.CalcFields("Direct Cost");
        CapacityLedgerEntry.TestField(
          "Direct Cost",
          Round(
            PurchaseLine."Direct Unit Cost" *
            PurchaseLine.Quantity * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompItemLedgerEntryDocNoAfterPostSubcontractingPurchOrder()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        PurchaseLine: Record "Purchase Line";
        RountingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
        ManufacturingSetup: Record "Manufacturing Setup";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Verify Starting Date on Production Order Routing when Send-Ahead Quantity is updated.

        // Setup: Create Item, create and certify Production BOM.
        Initialize();

        // Setup: Set Doc. No. Is Prod. Order No. to assign Prod. Order. No. to component consumption item ledger entries
        ManufacturingSetup.Get();
        ManufacturingSetup."Doc. No. Is Prod. Order No." := true;
        ManufacturingSetup.Modify();

        CompItem.Get(CreateAndModifyItem('', CompItem."Flushing Method"::Backward, CompItem."Replenishment System"::Purchase));
        ProdItem.Get(CreateAndModifyItem('', ProdItem."Flushing Method"::Backward, ProdItem."Replenishment System"::"Prod. Order"));
        LibraryManufacturing.CreateRoutingLink(RountingLink);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ProdItem."Base Unit of Measure", CompItem."No.", RountingLink.Code);

        // Create Routing with Work Center and Machine Center.
        CreateWorkCenterWithSubcontractor(WorkCenter);
        RoutingHeader.Get(CreateRoutingSetup(WorkCenter."No.", RountingLink.Code));

        // Update Item with Production BOM No. and Routing No.
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Routing No.", RoutingHeader."No.");
        ProdItem.Modify(true);

        // Create and refresh Released Production Order.
        CreateAndRefreshProdOrder(ProductionOrder, ProdItem."No.", '', LibraryRandom.RandInt(5));  // Take random Quantity.

        // [GIVEN] Calculate subcontract order and carry out action messages for "P" and "S", purchase order "R" is created
        CarryOutAMSubcontractWksh(WorkCenter."No.", ProdItem."No.");

        // Exercise: Purchase components and post Purchase Order.
        LibraryInventory.CreateItemJnlLine(
            ItemJnlLine, "Item Ledger Entry Type"::Purchase, WorkDate(), CompItem."No.", ProductionOrder.Quantity * 2, '');
        LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);
        FindPurchLineAndPostPurchOrder(PurchaseLine, ProdItem."No.");

        // Verify: Verify Starting Date on Production Order Routing when Send-Ahead Quantity is updated.
        VerifyItemLedgerEntryByDocNo(ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcValueEntryCostAmountActualWithDifferentUOM()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: Record "Work Center";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [Purchase] [Unit of Measure]
        // [SCENARIO 256926] "Qty. per Unit of Measure" in purchase line is updated during posting with the value corresponding to "Unit of Measure Code"
        Initialize();

        // [GIVEN] Workcenter "W" with subcontractor "S"
        CreateWorkCenterWithSubcontractor(WorkCenter);

        // [GIVEN] Production item "I" with routing with "W"
        UpdateRoutingOnItem(Item, WorkCenter."No.");

        // [GIVEN] Item unit of measure "UOM" with description different from its code and quantity per more then 1
        CreateItemUnitOfMeasureWithDescription(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Production order "P" of "I"
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.", '', LibraryRandom.RandInt(10));

        // [GIVEN] Unit of measure of line of "P" set to "UOM"
        UpdateUOMInProdOrderLine(ProductionOrder, ItemUnitOfMeasure.Code);

        // [GIVEN] Calculate subcontract order and carry out action messages for "P" and "S", purchase order "R" is created
        CarryOutAMSubcontractWksh(WorkCenter."No.", Item."No.");

        // [WHEN] Post "R"
        FindPurchLineAndPostPurchOrder(PurchaseLine, Item."No.");

        // [THEN] The fields "Qty. per Unit of Measure" in created purchase receipt line and in "UOM" are equal
        FindPurchRcptLine(PurchRcptLine, Item."No.");
        PurchRcptLine.TestField("Qty. per Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    local procedure CreateWorkCenterWithSubcontractor(var WorkCenter: Record "Work Center")
    var
        Vendor: Record Vendor;
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        SubcManagementLibrary.CreateSubcontractor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);
    end;

    local procedure UpdateRoutingOnItem(var Item: Record Item; WorkCenterNo: Code[20])
    begin
        Item.Get(CreateAndModifyItem('', Item."Flushing Method"::"Pick + Manual", Item."Replenishment System"::Purchase));
        Item.Validate("Routing No.", CreateRoutingSetup(WorkCenterNo, ''));
        Item.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasureWithDescription(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; UOMQtyPer: Decimal)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UnitOfMeasure.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(UnitOfMeasure.Description)));
        UnitOfMeasure.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, UOMQtyPer);
    end;

    local procedure CarryOutAMSubcontractWksh(No: Code[20]; ItemNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        WorkCenter: Record "Work Center";
        RequisitionLine: Record "Requisition Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        WorkCenter.SetRange("No.", No);
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // take random Direct Cost.
        RequisitionLine.Validate("Gen. Business Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        RequisitionLine.Modify(true);
        Vendor.Get(RequisitionLine."Vendor No.");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", '');
        if not VATPostingSetup.FindFirst() then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", '');
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure UpdateUOMInProdOrderLine(ProductionOrder: Record "Production Order"; ItemUnitOfMeasureCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        ProdOrderLine.Validate("Unit of Measure Code", ItemUnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure FindPurchLineAndPostPurchOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        if not GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group") then
            LibraryERM.CreateGeneralPostingSetup(
              GeneralPostingSetup, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure FindCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    local procedure FindCapacityLedgerEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; OrderNo: Code[20])
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", OrderNo);
        CapacityLedgerEntry.FindFirst();
    end;

    local procedure VerifyItemLedgerEntryByDocNo(DocNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // output
        ItemLedgerEntry.SetRange("Entry Type", "Item Ledger Entry Type"::Output);
        ItemLedgerEntry.SetRange("Document No.", DocNo);
        ItemLedgerEntry.FindFirst();
        // consumption
        ItemLedgerEntry.SetRange("Entry Type", "Item Ledger Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Document No.", DocNo);
        Assert.IsTrue(not ItemLedgerEntry.IsEmpty(), 'No consumption entry found with Document No. = ' + DocNo);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(10));
        Item.Validate("Unit Cost", LibraryRandom.RandInt(10));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndModifyItem(VendorNo: Code[20]; FlushingMethod: Enum "Flushing Method"; ReplenishmentSystem: Enum "Replenishment System"): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem());
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateRoutingSetup(WorkCenterNo: Code[20]; RoutingLinkCode: Code[10]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
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

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; No: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, No, 1);  // Use blank value for Version Code and 1 for Quantity per.
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;
}