// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Utilities;

codeunit 140005 "Subc. PO Target Resil. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Subcontracting] [Planning Resiliency] Existing purchase orders assigned to suggestions are neither finalized nor printed by Carry Out
    end;

    [Test]
    procedure TargetOnlyBatchWithResiliencyAndPrintingDoesNotFinalizeOrPrintTarget()
    var
        TargetHeader: Record "Purchase Header";
        ExistingPurchaseLine: Record "Purchase Line";
        TargetedLine: Record "Requisition Line";
    begin
        // [SCENARIO] With planning resiliency and printing, a batch that only appends to an existing order neither finalizes nor prints that order and keeps its invoice discount.
        Initialize();

        // [GIVEN] An accepted New suggestion assigned to an open purchase order.
        SubcontractingMgmtLibrary.CreateTargetedPurchaseSuggestion(TargetedLine, TargetHeader);

        // [GIVEN] The order already has a line and an amount-based invoice discount.
        AddLineWithInvoiceDiscountAmount(TargetHeader, ExistingPurchaseLine);

        // [WHEN] Carry Out runs with planning resiliency and order printing.
        RunCarryOutWithResiliencyAndPrinting(TargetedLine);

        // [THEN] No finalization event is raised for the existing order, and the order is not printed.
        VerifyTargetNotFinalizedOrPrinted(TargetHeader);

        // [THEN] The suggestion is appended, and the invoice discount and the existing line amounts are unchanged.
        VerifySuggestionAppendedToTarget(TargetHeader, TargetedLine);
        VerifyInvoiceDiscountPreserved(TargetHeader, ExistingPurchaseLine);
    end;

    [Test]
    procedure MixedBatchWithNewOrderBeforeTargetWithResiliencyAndPrinting()
    var
        TargetHeader: Record "Purchase Header";
        NewHeader: Record "Purchase Header";
        ExistingPurchaseLine: Record "Purchase Line";
        TargetedLine: Record "Requisition Line";
        UntargetedLine: Record "Requisition Line";
        NewOrderVendor: Record Vendor;
        TargetVendor: Record Vendor;
    begin
        // [SCENARIO] With planning resiliency and printing, a new order processed before an assigned order is finalized and printed once, and the assigned order is neither finalized nor printed.
        Initialize();

        // [GIVEN] An untargeted suggestion whose vendor sorts before the vendor of a suggestion assigned to an existing order.
        // [GIVEN] The existing order already has a line and an amount-based invoice discount.
        CreateVendorsInProcessingOrder(NewOrderVendor, TargetVendor);
        CreateMixedBatch(UntargetedLine, TargetedLine, TargetHeader, ExistingPurchaseLine, NewOrderVendor."No.", TargetVendor."No.");

        // [WHEN] Carry Out runs with planning resiliency and order printing.
        RunCarryOutWithResiliencyAndPrinting(TargetedLine);

        // [THEN] The new order is finalized once and printed once.
        FindNewOrder(NewHeader, UntargetedLine, TargetHeader."No.");
        VerifyNewOrderFinalizedAndPrintedOnce(NewHeader);

        // [THEN] The existing order is neither finalized nor printed.
        VerifyTargetNotFinalizedOrPrinted(TargetHeader);

        // [THEN] The suggestion is appended, and the invoice discount and the existing line amounts are unchanged.
        VerifySuggestionAppendedToTarget(TargetHeader, TargetedLine);
        VerifyInvoiceDiscountPreserved(TargetHeader, ExistingPurchaseLine);
    end;

    [Test]
    procedure MixedBatchWithTargetBeforeNewOrderWithResiliencyAndPrinting()
    var
        TargetHeader: Record "Purchase Header";
        NewHeader: Record "Purchase Header";
        ExistingPurchaseLine: Record "Purchase Line";
        TargetedLine: Record "Requisition Line";
        UntargetedLine: Record "Requisition Line";
        NewOrderVendor: Record Vendor;
        TargetVendor: Record Vendor;
    begin
        // [SCENARIO] With planning resiliency and printing, a new order created after an assigned order is finalized and printed once, and the assigned order is neither finalized nor printed.
        Initialize();

        // [GIVEN] A suggestion assigned to an existing order whose vendor sorts before the vendor of an untargeted suggestion.
        // [GIVEN] The existing order already has a line and an amount-based invoice discount.
        CreateVendorsInProcessingOrder(TargetVendor, NewOrderVendor);
        CreateMixedBatch(UntargetedLine, TargetedLine, TargetHeader, ExistingPurchaseLine, NewOrderVendor."No.", TargetVendor."No.");

        // [WHEN] Carry Out runs with planning resiliency and order printing.
        RunCarryOutWithResiliencyAndPrinting(TargetedLine);

        // [THEN] The new order is finalized once and printed once.
        FindNewOrder(NewHeader, UntargetedLine, TargetHeader."No.");
        VerifyNewOrderFinalizedAndPrintedOnce(NewHeader);

        // [THEN] The existing order is neither finalized nor printed.
        VerifyTargetNotFinalizedOrPrinted(TargetHeader);

        // [THEN] The suggestion is appended, and the invoice discount and the existing line amounts are unchanged.
        VerifySuggestionAppendedToTarget(TargetHeader, TargetedLine);
        VerifyInvoiceDiscountPreserved(TargetHeader, ExistingPurchaseLine);
    end;

    local procedure Initialize()
    begin
        if UnbindSubscription(this) then;
        Clear(AfterFinalizeOrderHeaderCounts);
        Clear(FinalizeOnBeforePrintCounts);
        Clear(PrintedOrderNos);
        LibraryERMCountryData.CreateVATData();
    end;

    local procedure CreateMixedBatch(var UntargetedLine: Record "Requisition Line"; var TargetedLine: Record "Requisition Line"; var TargetHeader: Record "Purchase Header"; var ExistingPurchaseLine: Record "Purchase Line"; NewOrderVendorNo: Code[20]; TargetVendorNo: Code[20])
    var
        Item: Record Item;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        LibraryInventory.CreateItem(Item);
        SubcontractingMgmtLibrary.CreateOpenPurchaseOrder(TargetHeader, TargetVendorNo);
        AddLineWithInvoiceDiscountAmount(TargetHeader, ExistingPurchaseLine);
        SubcontractingMgmtLibrary.CreatePurchaseSuggestion(TargetedLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, TargetVendorNo, Item."No.");
        TargetedLine."Ref. Order No." := TargetHeader."No.";
        TargetedLine.Modify(true);
        SubcontractingMgmtLibrary.CreatePurchaseSuggestion(UntargetedLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, NewOrderVendorNo, Item."No.");
    end;

    local procedure AddLineWithInvoiceDiscountAmount(var TargetHeader: Record "Purchase Header"; var ExistingPurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        InvoiceDiscountAmount: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(ExistingPurchaseLine, TargetHeader, ExistingPurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(5, 10));
        ExistingPurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        ExistingPurchaseLine.Modify(true);

        InvoiceDiscountAmount := LibraryRandom.RandIntInRange(10, 50);
        TargetHeader.Get(TargetHeader."Document Type", TargetHeader."No.");
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, TargetHeader);

        TargetHeader.Get(TargetHeader."Document Type", TargetHeader."No.");
        ExistingPurchaseLine.Get(ExistingPurchaseLine."Document Type", ExistingPurchaseLine."Document No.", ExistingPurchaseLine."Line No.");
        Assert.AreEqual(TargetHeader."Invoice Discount Calculation"::Amount, TargetHeader."Invoice Discount Calculation", 'The order must use an amount-based invoice discount.');
        Assert.AreEqual(InvoiceDiscountAmount, TargetHeader."Invoice Discount Value", 'The invoice discount must be applied to the order.');
        Assert.AreNotEqual(0, ExistingPurchaseLine."Inv. Discount Amount", 'The invoice discount must be distributed to the existing line.');
    end;

    local procedure CreateVendorsInProcessingOrder(var FirstVendor: Record Vendor; var SecondVendor: Record Vendor)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(FirstVendor);
        LibraryPurchase.CreateVendor(SecondVendor);
        if FirstVendor."No." < SecondVendor."No." then
            exit;
        Vendor := FirstVendor;
        FirstVendor := SecondVendor;
        SecondVendor := Vendor;
    end;

    local procedure RunCarryOutWithResiliencyAndPrinting(RequisitionLine: Record "Requisition Line")
    var
        BatchHeader: Record "Purchase Header";
        ReqWkshMakeOrder: Codeunit "Req. Wksh.-Make Order";
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        BatchHeader."Order Date" := WorkDate();
        BatchHeader."Posting Date" := WorkDate();
        ReqWkshMakeOrder.Set(BatchHeader, WorkDate(), true);
        ReqWkshMakeOrder.SetPlanningResiliency();
        Commit();

        BindSubscription(this);
        ReqWkshMakeOrder.CarryOutBatchAction(RequisitionLine);
        UnbindSubscription(this);

        Assert.AreEqual(0, ReqWkshMakeOrder.GetFailedCounter(), 'All accepted suggestions must be carried out successfully.');
    end;

    local procedure FindNewOrder(var NewHeader: Record "Purchase Header"; UntargetedLine: Record "Requisition Line"; TargetOrderNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Buy-from Vendor No.", UntargetedLine."Vendor No.");
        PurchaseLine.SetRange("No.", UntargetedLine."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The untargeted suggestion must create exactly one order line.');
        PurchaseLine.FindFirst();
        Assert.AreNotEqual(TargetOrderNo, PurchaseLine."Document No.", 'The untargeted suggestion must create another order.');
        NewHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure VerifyTargetNotFinalizedOrPrinted(TargetHeader: Record "Purchase Header")
    begin
        Assert.AreEqual(0, GetEventCount(AfterFinalizeOrderHeaderCounts, TargetHeader."No."), 'OnAfterFinalizeOrderHeader must not be raised for an existing order.');
        Assert.AreEqual(0, GetEventCount(FinalizeOnBeforePrintCounts, TargetHeader."No."), 'OnFinalizeOrderHeaderOnBeforePrint must not be raised for an existing order.');
        Assert.AreEqual(0, GetPrintCount(TargetHeader."No."), 'An existing order must not be printed.');
    end;

    local procedure VerifyNewOrderFinalizedAndPrintedOnce(NewHeader: Record "Purchase Header")
    begin
        Assert.AreEqual(1, GetEventCount(AfterFinalizeOrderHeaderCounts, NewHeader."No."), 'OnAfterFinalizeOrderHeader must be raised once for the new order.');
        Assert.AreEqual(1, GetEventCount(FinalizeOnBeforePrintCounts, NewHeader."No."), 'OnFinalizeOrderHeaderOnBeforePrint must be raised once for the new order.');
        Assert.AreEqual(1, GetPrintCount(NewHeader."No."), 'The new order must be printed once.');
    end;

    local procedure VerifySuggestionAppendedToTarget(TargetHeader: Record "Purchase Header"; TargetedLine: Record "Requisition Line")
    var
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        PurchaseLine.SetRange("Document Type", TargetHeader."Document Type");
        PurchaseLine.SetRange("Document No.", TargetHeader."No.");
        Assert.AreEqual(2, PurchaseLine.Count(), 'The existing order must hold its original line and the appended line.');
        PurchaseLine.SetRange("No.", TargetedLine."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The targeted suggestion must be appended to the existing order once.');
        Assert.IsFalse(
            RequisitionLine.Get(TargetedLine."Worksheet Template Name", TargetedLine."Journal Batch Name", TargetedLine."Line No."),
            'The targeted suggestion must be consumed.');
    end;

    local procedure VerifyInvoiceDiscountPreserved(TargetHeaderBefore: Record "Purchase Header"; ExistingLineBefore: Record "Purchase Line")
    var
        TargetHeaderAfter: Record "Purchase Header";
        ExistingLineAfter: Record "Purchase Line";
    begin
        TargetHeaderAfter.Get(TargetHeaderBefore."Document Type", TargetHeaderBefore."No.");
        Assert.AreEqual(TargetHeaderBefore."Invoice Discount Calculation", TargetHeaderAfter."Invoice Discount Calculation", 'The invoice discount calculation of the existing order must not change.');
        Assert.AreEqual(TargetHeaderBefore."Invoice Discount Value", TargetHeaderAfter."Invoice Discount Value", 'The invoice discount value of the existing order must not change.');

        ExistingLineAfter.Get(ExistingLineBefore."Document Type", ExistingLineBefore."Document No.", ExistingLineBefore."Line No.");
        Assert.AreEqual(ExistingLineBefore."Inv. Discount Amount", ExistingLineAfter."Inv. Discount Amount", 'The invoice discount amount of the existing line must not change.');
        Assert.AreEqual(ExistingLineBefore."Line Amount", ExistingLineAfter."Line Amount", 'The line amount of the existing line must not change.');
        Assert.AreEqual(ExistingLineBefore.Amount, ExistingLineAfter.Amount, 'The amount of the existing line must not change.');
        Assert.AreEqual(ExistingLineBefore."Amount Including VAT", ExistingLineAfter."Amount Including VAT", 'The amount including VAT of the existing line must not change.');
    end;

    local procedure IncrementEventCount(var EventCounts: Dictionary of [Code[20], Integer]; OrderNo: Code[20])
    var
        EventCount: Integer;
    begin
        if EventCounts.Get(OrderNo, EventCount) then;
        EventCounts.Set(OrderNo, EventCount + 1);
    end;

    local procedure GetEventCount(var EventCounts: Dictionary of [Code[20], Integer]; OrderNo: Code[20]): Integer
    var
        EventCount: Integer;
    begin
        if EventCounts.Get(OrderNo, EventCount) then
            exit(EventCount);
        exit(0);
    end;

    local procedure GetPrintCount(OrderNo: Code[20]) PrintCount: Integer
    var
        PrintedOrderNo: Code[20];
    begin
        foreach PrintedOrderNo in PrintedOrderNos do
            if PrintedOrderNo = OrderNo then
                PrintCount := PrintCount + 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnAfterFinalizeOrderHeader, '', false, false)]
    local procedure RecordAfterFinalizeOrderHeader(var PurchHeader: Record "Purchase Header")
    begin
        IncrementEventCount(AfterFinalizeOrderHeaderCounts, PurchHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnFinalizeOrderHeaderOnBeforePrint, '', false, false)]
    local procedure RecordFinalizeOrderHeaderOnBeforePrint(PurchOrderHeader: Record "Purchase Header")
    begin
        IncrementEventCount(FinalizeOnBeforePrintCounts, PurchOrderHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", OnBeforePrintPurchaseOrder, '', false, false)]
    local procedure CapturePrintedPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
        PrintedOrderNos.Add(PurchaseHeader."No.");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", OnBeforePrintMultiplePurchaseDocs, '', false, false)]
    local procedure CapturePrintedPurchaseOrders(var TempPurchaseHeader: Record "Purchase Header" temporary; var IsHandled: Boolean)
    begin
        if TempPurchaseHeader.FindSet() then
            repeat
                PrintedOrderNos.Add(TempPurchaseHeader."No.");
            until TempPurchaseHeader.Next() = 0;
        IsHandled := true;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        AfterFinalizeOrderHeaderCounts: Dictionary of [Code[20], Integer];
        FinalizeOnBeforePrintCounts: Dictionary of [Code[20], Integer];
        PrintedOrderNos: List of [Code[20]];
}