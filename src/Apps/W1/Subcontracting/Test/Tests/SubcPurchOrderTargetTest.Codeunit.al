// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Utilities;

codeunit 139980 "Subc. PurchOrderTargetTest"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    [Test]
    procedure TargetedLineAppendsAndFollowingUntargetedLineCreatesAnotherOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        UntargetedLine: Record "Requisition Line";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        // [GIVEN] An existing order and two accepted suggestions for the same vendor.
        CreateTargetedSuggestion(RequisitionLine, PurchaseHeader);
        CreateSuggestion(UntargetedLine, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name",
            RequisitionLine."Vendor No.", RequisitionLine."No.");
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");

        // [WHEN] The requisition Carry Out report processes both lines.
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] The chosen order receives only the targeted line, and the other line creates a new order.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The selected order should receive exactly one line.');
        PurchaseLine.SetRange("Document No.");
        PurchaseLine.SetFilter("Document No.", '<>%1', PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", UntargetedLine."No.");
        Assert.IsTrue(not PurchaseLine.IsEmpty(), 'The untargeted line should create a separate order.');
    end;

    [Test]
    procedure InvalidAcceptedTargetBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
    begin
        // [GIVEN] A valid target followed by an accepted suggestion pointing at a missing order.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        InvalidLine."Ref. Order No." := 'MISSING-TARGET';
        InvalidLine.Modify(true);

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(ValidLine, ValidHeader, InvalidLine, 'MISSING-TARGET', 'the order no longer exists');
    end;

    [Test]
    procedure TargetThatIsNotOpenBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
    begin
        // [GIVEN] A valid target followed by a target that is no longer Open.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        InvalidHeader.Status := InvalidHeader.Status::Released;
        InvalidHeader.Modify();

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(ValidLine, ValidHeader, InvalidLine, InvalidHeader."No.", 'the order is not Open');
    end;

    [Test]
    procedure TargetWithOtherVendorBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
        OtherVendor: Record Vendor;
    begin
        // [GIVEN] A valid target followed by a target of another buy-from vendor.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        LibraryPurchase.CreateVendor(OtherVendor);
        InvalidHeader."Buy-from Vendor No." := OtherVendor."No.";
        InvalidHeader.Modify();

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(ValidLine, ValidHeader, InvalidLine, InvalidHeader."No.", 'the buy-from vendor does not match');
    end;

    [Test]
    procedure TargetWithOtherSellToCustomerBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
    begin
        // [GIVEN] A valid target followed by a target with another sell-to customer.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        InvalidHeader."Sell-to Customer No." := LibrarySales.CreateCustomerNo();
        InvalidHeader.Modify();

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(ValidLine, ValidHeader, InvalidLine, InvalidHeader."No.", 'the sell-to customer does not match');
    end;

    [Test]
    procedure TargetWithOtherShipToCodeBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
    begin
        // [GIVEN] A valid target followed by a target with another ship-to code.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        InvalidHeader."Ship-to Code" := 'SHIPTO';
        InvalidHeader.Modify();

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(ValidLine, ValidHeader, InvalidLine, InvalidHeader."No.", 'the ship-to code does not match');
    end;

    [Test]
    procedure TargetWithOtherOrderAddressBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
    begin
        // [GIVEN] A valid target followed by a target with another order address.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        InvalidHeader."Order Address Code" := 'ORDADDR';
        InvalidHeader.Modify();

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(ValidLine, ValidHeader, InvalidLine, InvalidHeader."No.", 'the order address does not match');
    end;

    [Test]
    procedure TargetWithOtherCurrencyBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
    begin
        // [GIVEN] A valid target followed by a target in another currency.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        InvalidHeader."Currency Code" := 'CURX';
        InvalidHeader.Modify();

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(ValidLine, ValidHeader, InvalidLine, InvalidHeader."No.", 'the currency does not match');
    end;

    [Test]
    procedure TargetWithOtherPurchasingCodeOnExistingLinesBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
        Item: Record Item;
        Purchasing: Record Purchasing;
        PurchaseLine: Record "Purchase Line";
    begin
        // [GIVEN] A valid target followed by a target whose existing lines use another purchasing code.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        CreatePurchasingCode(Purchasing, false, false);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, InvalidHeader, "Purchase Line Type"::Item, Item."No.", 1);
        PurchaseLine."Purchasing Code" := Purchasing.Code;
        PurchaseLine.Modify();

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(
            ValidLine, ValidHeader, InvalidLine, InvalidHeader."No.", 'the purchasing code does not match the existing lines');
    end;

    [Test]
    procedure SpecialOrderTargetWithOtherLocationBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
        Location: Record Location;
        Purchasing: Record Purchasing;
    begin
        // [GIVEN] A valid target followed by a special-order line whose location differs from the target.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        CreatePurchasingCode(Purchasing, false, true);
        LibraryWarehouse.CreateLocation(Location);
        InvalidLine."Purchasing Code" := Purchasing.Code;
        InvalidLine."Location Code" := Location.Code;
        InvalidLine.Modify();

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(ValidLine, ValidHeader, InvalidLine, InvalidHeader."No.", 'the special-order location does not match');
    end;

    [Test]
    procedure DropShipmentTargetWithoutSalesOrderBlocksBatchBeforeChangingOrders()
    var
        ValidHeader: Record "Purchase Header";
        InvalidHeader: Record "Purchase Header";
        ValidLine: Record "Requisition Line";
        InvalidLine: Record "Requisition Line";
        Purchasing: Record Purchasing;
    begin
        // [GIVEN] A valid target followed by a drop-shipment line without a sales order to take the address from.
        CreateBatchWithSecondTarget(ValidLine, ValidHeader, InvalidLine, InvalidHeader);
        CreatePurchasingCode(Purchasing, true, false);
        InvalidLine."Purchasing Code" := Purchasing.Code;
        InvalidLine.Modify();

        // [WHEN] [THEN] Carry Out stops before any purchase order or line is written.
        VerifyBatchBlocked(
            ValidLine, ValidHeader, InvalidLine, InvalidHeader."No.", 'the drop-shipment address does not match the sales order');
    end;

    [Test]
    procedure InvalidUnacceptedTargetDoesNotBlockAcceptedSuggestion()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        UnacceptedLine: Record "Requisition Line";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        // [GIVEN] An accepted target and an unaccepted line with a missing target.
        CreateTargetedSuggestion(RequisitionLine, PurchaseHeader);
        CreateSuggestion(UnacceptedLine, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name",
            RequisitionLine."Vendor No.", RequisitionLine."No.");
        UnacceptedLine."Ref. Order No." := 'MISSING-TARGET';
        UnacceptedLine."Accept Action Message" := false;
        UnacceptedLine.Modify(true);
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");

        // [WHEN] The accepted work is carried out.
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // [THEN] The valid target receives its line and the unaccepted assignment remains untouched.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The accepted suggestion should append to the target.');
        UnacceptedLine.Get(UnacceptedLine."Worksheet Template Name", UnacceptedLine."Journal Batch Name", UnacceptedLine."Line No.");
        Assert.AreEqual('MISSING-TARGET', UnacceptedLine."Ref. Order No.", 'Unaccepted work should remain unchanged.');
    end;

    [Test]
    procedure TargetOnlyBatchAppendsAfterLastLineKeepsHeaderAndClearsWorksheet()
    var
        PurchaseHeader: Record "Purchase Header";
        HeaderAfter: Record "Purchase Header";
        ExistingLine: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // [GIVEN] An order with one line and a single accepted suggestion that targets it.
        CreateTargetedSuggestion(RequisitionLine, PurchaseHeader);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(ExistingLine, PurchaseHeader, "Purchase Line Type"::Item, Item."No.", 1);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [WHEN] The batch is carried out.
        RunCarryOut(RequisitionLine);

        // [THEN] The line is appended after the existing one, the header is untouched, and the worksheet line is gone.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.AreEqual(2, PurchaseLine.Count(), 'The order should receive one additional line.');
        PurchaseLine.FindLast();
        Assert.AreEqual(RequisitionLine."No.", PurchaseLine."No.", 'The appended line should come from the worksheet line.');
        Assert.IsTrue(PurchaseLine."Line No." > ExistingLine."Line No.", 'The line must be appended after the existing line.');
        HeaderAfter.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(PurchaseHeader."Buy-from Vendor No.", HeaderAfter."Buy-from Vendor No.", 'Vendor must not change.');
        Assert.AreEqual(PurchaseHeader."Currency Code", HeaderAfter."Currency Code", 'Currency must not change.');
        Assert.AreEqual(PurchaseHeader."Order Date", HeaderAfter."Order Date", 'Order date must not change.');
        Assert.AreEqual(PurchaseHeader."Posting Date", HeaderAfter."Posting Date", 'Posting date must not change.');
        Assert.AreEqual(PurchaseHeader."Expected Receipt Date", HeaderAfter."Expected Receipt Date", 'Receipt date must not change.');
        Assert.AreEqual(PurchaseHeader."Location Code", HeaderAfter."Location Code", 'Location must not change.');
        Assert.AreEqual(PurchaseHeader."Ship-to Code", HeaderAfter."Ship-to Code", 'Ship-to code must not change.');
        Assert.AreEqual(PurchaseHeader."Your Reference", HeaderAfter."Your Reference", 'Reference must not change.');
        Assert.AreEqual(PurchaseHeader.Status, HeaderAfter.Status, 'Status must not change.');
        Assert.IsFalse(
            RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No."),
            'The carried out worksheet line must be removed.');
    end;

    [Test]
    procedure TargetedLinesAppendToTheirOwnOrders()
    var
        FirstHeader: Record "Purchase Header";
        SecondHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FirstLine: Record "Requisition Line";
        SecondLine: Record "Requisition Line";
        ThirdLine: Record "Requisition Line";
    begin
        // [GIVEN] Two accepted suggestions for the first order and one for the second order.
        CreateTargetedSuggestion(FirstLine, FirstHeader);
        CreateLineTargetingNewOrder(SecondLine, SecondHeader, FirstLine);
        CreateSuggestion(ThirdLine, FirstLine."Worksheet Template Name", FirstLine."Journal Batch Name", FirstLine."Vendor No.", FirstLine."No.");
        ThirdLine."Ref. Order No." := FirstHeader."No.";
        ThirdLine.Modify(true);

        // [WHEN] The batch is carried out.
        RunCarryOut(FirstLine);

        // [THEN] Each order receives only the lines that target it and no further order is created.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", FirstHeader."No.");
        Assert.AreEqual(2, PurchaseLine.Count(), 'The first order should receive both of its targeted lines.');
        PurchaseLine.SetRange("Document No.", SecondHeader."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The second order should receive its targeted line.');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", FirstLine."Vendor No.");
        Assert.AreEqual(2, PurchaseHeader.Count(), 'No additional purchase order may be created.');
    end;

    [Test]
    procedure UntargetedLinesOfOneVendorStillShareOneNewOrder()
    var
        TargetHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TargetedLine: Record "Requisition Line";
        FirstUntargetedLine: Record "Requisition Line";
        SecondUntargetedLine: Record "Requisition Line";
    begin
        // [GIVEN] One targeted and two untargeted accepted suggestions for the same vendor.
        CreateTargetedSuggestion(TargetedLine, TargetHeader);
        CreateSuggestion(FirstUntargetedLine, TargetedLine."Worksheet Template Name", TargetedLine."Journal Batch Name",
            TargetedLine."Vendor No.", TargetedLine."No.");
        CreateSuggestion(SecondUntargetedLine, TargetedLine."Worksheet Template Name", TargetedLine."Journal Batch Name",
            TargetedLine."Vendor No.", TargetedLine."No.");

        // [WHEN] The batch is carried out.
        RunCarryOut(TargetedLine);

        // [THEN] The target gets one line and the untargeted lines follow the standard grouping into one new order.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", TargetHeader."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The target should receive only its own line.');
        PurchaseLine.SetRange("Document No.");
        PurchaseLine.SetFilter("Document No.", '<>%1', TargetHeader."No.");
        PurchaseLine.SetRange("Buy-from Vendor No.", TargetedLine."Vendor No.");
        Assert.AreEqual(2, PurchaseLine.Count(), 'Both untargeted lines should be created.');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", TargetedLine."Vendor No.");
        Assert.AreEqual(2, PurchaseHeader.Count(), 'The untargeted lines should share exactly one new order.');
    end;

    [Test]
    procedure FollowingUntargetedLineOfAnotherVendorCreatesItsOwnOrder()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        TargetHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TargetedLine: Record "Requisition Line";
        UntargetedLine: Record "Requisition Line";
        TargetedItem: Record Item;
        UntargetedItem: Record Item;
        FirstVendor: Record Vendor;
        SecondVendor: Record Vendor;
        Vendor: Record Vendor;
    begin
        // [GIVEN] A targeted suggestion of the vendor that is processed first and an untargeted one of the next vendor.
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        LibraryInventory.CreateItem(TargetedItem);
        LibraryInventory.CreateItem(UntargetedItem);
        LibraryPurchase.CreateVendor(FirstVendor);
        LibraryPurchase.CreateVendor(SecondVendor);
        if FirstVendor."No." > SecondVendor."No." then begin
            Vendor := FirstVendor;
            FirstVendor := SecondVendor;
            SecondVendor := Vendor;
        end;
        LibraryPurchase.CreatePurchHeader(TargetHeader, TargetHeader."Document Type"::Order, FirstVendor."No.");
        CreateSuggestion(TargetedLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, FirstVendor."No.", TargetedItem."No.");
        TargetedLine."Ref. Order No." := TargetHeader."No.";
        TargetedLine.Modify(true);
        CreateSuggestion(UntargetedLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, SecondVendor."No.", UntargetedItem."No.");

        // [WHEN] The batch is carried out.
        RunCarryOut(TargetedLine);

        // [THEN] The target keeps only its line and the other vendor's line creates its own order.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", TargetHeader."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The target should receive only its own line.');
        PurchaseLine.SetRange("Document No.");
        PurchaseLine.SetRange("No.", UntargetedItem."No.");
        PurchaseLine.FindFirst();
        Assert.AreNotEqual(TargetHeader."No.", PurchaseLine."Document No.", 'The following line must not inherit the targeted order.');
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Assert.AreEqual(SecondVendor."No.", PurchaseHeader."Buy-from Vendor No.", 'The new order must belong to the line''s vendor.');
    end;

    [Test]
    [HandlerFunctions('SelectPurchaseOrderHandler')]
    procedure AssignStoresNewPurchaseReferenceWithoutRequiringAcceptance()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [GIVEN] A new, not yet accepted suggestion with production context and a compatible open order.
        Initialize();
        CreateAssignableSuggestion(RequisitionLine, PurchaseHeader);
        RequisitionLine."Accept Action Message" := false;
        RequisitionLine.Modify();
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // [WHEN] The order is assigned.
        RequisitionLine.AssignPurchaseOrderTarget();

        // [THEN] The line holds a New purchase reference to the order without a purchase line.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        Assert.AreEqual(RequisitionLine."Ref. Order Type"::Purchase, RequisitionLine."Ref. Order Type", 'Ref. Order Type');
        Assert.AreEqual(PurchaseHeader."No.", RequisitionLine."Ref. Order No.", 'Ref. Order No.');
        Assert.AreEqual(RequisitionLine."Ref. Order Status"::Simulated, RequisitionLine."Ref. Order Status", 'Ref. Order Status');
        Assert.AreEqual(0, RequisitionLine."Ref. Line No.", 'Ref. Line No.');
        Assert.AreEqual(RequisitionLine."Action Message"::New, RequisitionLine."Action Message", 'The action must stay New.');
        Assert.IsFalse(RequisitionLine."Accept Action Message", 'Assigning must not accept the line.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure AssignRequiresActionMessageNew()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [GIVEN] A suggestion that is not New.
        Initialize();
        CreateAssignableSuggestion(RequisitionLine, PurchaseHeader);
        RequisitionLine."Action Message" := RequisitionLine."Action Message"::"Change Qty.";

        // [WHEN] [THEN] Assigning is rejected before any lookup opens.
        asserterror RequisitionLine.AssignPurchaseOrderTarget();
        Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption("Action Message"), Format(RequisitionLine."Action Message"::New));
    end;

    [Test]
    procedure AssignRequiresVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [GIVEN] A new suggestion without vendor.
        Initialize();
        CreateAssignableSuggestion(RequisitionLine, PurchaseHeader);
        RequisitionLine."Vendor No." := '';

        // [WHEN] [THEN] Assigning is rejected before any lookup opens.
        asserterror RequisitionLine.AssignPurchaseOrderTarget();
        Assert.ExpectedError(RequisitionLine.FieldCaption("Vendor No.") + ' must have a value');
    end;

    [Test]
    procedure AssignRequiresProdOrderNo()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [GIVEN] A new suggestion without production order.
        Initialize();
        CreateAssignableSuggestion(RequisitionLine, PurchaseHeader);
        RequisitionLine."Prod. Order No." := '';

        // [WHEN] [THEN] Assigning is rejected before any lookup opens.
        asserterror RequisitionLine.AssignPurchaseOrderTarget();
        Assert.ExpectedError(RequisitionLine.FieldCaption("Prod. Order No.") + ' must have a value');
    end;

    [Test]
    procedure AssignRequiresProdOrderLineNo()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [GIVEN] A new suggestion without production order line.
        Initialize();
        CreateAssignableSuggestion(RequisitionLine, PurchaseHeader);
        RequisitionLine."Prod. Order Line No." := 0;

        // [WHEN] [THEN] Assigning is rejected before any lookup opens.
        asserterror RequisitionLine.AssignPurchaseOrderTarget();
        Assert.ExpectedError(RequisitionLine.FieldCaption("Prod. Order Line No.") + ' must have a value');
    end;

    [Test]
    procedure AssignRequiresOperationNo()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [GIVEN] A new suggestion without operation.
        Initialize();
        CreateAssignableSuggestion(RequisitionLine, PurchaseHeader);
        RequisitionLine."Operation No." := '';

        // [WHEN] [THEN] Assigning is rejected before any lookup opens.
        asserterror RequisitionLine.AssignPurchaseOrderTarget();
        Assert.ExpectedError(RequisitionLine.FieldCaption("Operation No.") + ' must have a value');
    end;

    [Test]
    [HandlerFunctions('CaptureOrdersHandler')]
    procedure LookupShowsOnlyOpenOrdersCompatibleWithTheLine()
    var
        CompatibleHeader: Record "Purchase Header";
        OtherHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        OtherVendor: Record Vendor;
    begin
        // [GIVEN] One compatible order and orders that differ in status, vendor, customer, ship-to, order address or currency.
        Initialize();
        CreateAssignableSuggestion(RequisitionLine, CompatibleHeader);
        CreateOpenOrder(OtherHeader, RequisitionLine."Vendor No.");
        OtherHeader.Status := OtherHeader.Status::Released;
        OtherHeader.Modify();
        LibraryPurchase.CreateVendor(OtherVendor);
        CreateOpenOrder(OtherHeader, OtherVendor."No.");
        CreateOpenOrder(OtherHeader, RequisitionLine."Vendor No.");
        OtherHeader."Sell-to Customer No." := LibrarySales.CreateCustomerNo();
        OtherHeader.Modify();
        CreateOpenOrder(OtherHeader, RequisitionLine."Vendor No.");
        OtherHeader."Ship-to Code" := 'SHIPTO';
        OtherHeader.Modify();
        CreateOpenOrder(OtherHeader, RequisitionLine."Vendor No.");
        OtherHeader."Order Address Code" := 'ORDADDR';
        OtherHeader.Modify();
        CreateOpenOrder(OtherHeader, RequisitionLine."Vendor No.");
        OtherHeader."Currency Code" := 'CURX';
        OtherHeader.Modify();

        // [WHEN] The lookup opens.
        RequisitionLine.AssignPurchaseOrderTarget();

        // [THEN] Only the compatible open order is offered.
        Assert.AreEqual(CompatibleHeader."No.", LibraryVariableStorage.DequeueText(), 'The compatible order must be offered.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CapturePurchaseOrderHandler')]
    procedure ShowPurchaseOrderOpensAssignedOrderThatIsNoLongerOpen()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
    begin
        // [GIVEN] A worksheet line whose assigned order has been released.
        Initialize();
        CreateTargetedSuggestion(RequisitionLine, PurchaseHeader);
        PurchaseHeader.Status := PurchaseHeader.Status::Released;
        PurchaseHeader.Modify();
        OpenWorksheetAtLine(Worksheet, RequisitionLine);

        // [WHEN] Show Purchase Order is invoked.
        Assert.IsTrue(Worksheet.ShowPurchaseOrder.Enabled(), 'A referenced order must be navigable.');
        Worksheet.ShowPurchaseOrder.Invoke();

        // [THEN] The assigned order opens although it is no longer valid for Carry Out.
        Assert.AreEqual(PurchaseHeader."No.", LibraryVariableStorage.DequeueText(), 'The assigned order should open.');
        LibraryVariableStorage.AssertEmpty();
        Worksheet.Close();
    end;

    [Test]
    procedure ShowPurchaseOrderNamesMissingOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
    begin
        // [GIVEN] A worksheet line whose assigned order has been deleted.
        Initialize();
        CreateTargetedSuggestion(RequisitionLine, PurchaseHeader);
        OpenWorksheetAtLine(Worksheet, RequisitionLine);
        PurchaseHeader.Delete(true);

        // [WHEN] [THEN] Show Purchase Order reports the missing order.
        asserterror Worksheet.ShowPurchaseOrder.Invoke();
        Assert.ExpectedError(StrSubstNo(MissingOrderErr, PurchaseHeader."No.", RequisitionLine."Line No."));
    end;

    [Test]
    procedure ClearingTargetOnWorksheetAffectsOnlyCurrentLine()
    var
        PurchaseHeader: Record "Purchase Header";
        OtherHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        OtherLine: Record "Requisition Line";
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
    begin
        // [GIVEN] Two suggestions with assigned orders.
        Initialize();
        CreateTargetedSuggestion(RequisitionLine, PurchaseHeader);
        CreateLineTargetingNewOrder(OtherLine, OtherHeader, RequisitionLine);
        OpenWorksheetAtLine(Worksheet, RequisitionLine);

        // [WHEN] Clearing the selected order on the current worksheet line.
        Worksheet.ClearPurchaseOrder.Invoke();

        // [THEN] Only that line returns to an untargeted New purchase reference.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        Assert.AreEqual('', RequisitionLine."Ref. Order No.", 'The assigned order should be cleared.');
        Assert.AreEqual(RequisitionLine."Ref. Order Type"::Purchase, RequisitionLine."Ref. Order Type",
            'The line should remain a purchase suggestion.');
        OtherLine.Get(OtherLine."Worksheet Template Name", OtherLine."Journal Batch Name", OtherLine."Line No.");
        Assert.AreEqual(OtherHeader."No.", OtherLine."Ref. Order No.", 'Clearing one line must not change another line.');
        Worksheet.Close();
    end;

    [Test]
    [HandlerFunctions('SelectPurchaseOrderHandler')]
    procedure ShowPurchaseOrderAvailabilityFollowsAssignAndClear()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
    begin
        // [GIVEN] A worksheet line without assigned order.
        Initialize();
        CreateAssignableSuggestion(RequisitionLine, PurchaseHeader);
        OpenWorksheetAtLine(Worksheet, RequisitionLine);
        Assert.IsFalse(Worksheet.ShowPurchaseOrder.Enabled(), 'A line without target has no order to show.');

        // [WHEN] An order is assigned on the page.
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        Worksheet.AssignPurchaseOrder.Invoke();

        // [THEN] The assigned order is stored and navigable.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        Assert.AreEqual(PurchaseHeader."No.", RequisitionLine."Ref. Order No.", 'The order should be assigned.');
        Assert.IsTrue(Worksheet.ShowPurchaseOrder.Enabled(), 'An assigned order must be navigable.');

        // [WHEN] The target is cleared on the page.
        Worksheet.ClearPurchaseOrder.Invoke();

        // [THEN] Navigation is no longer offered.
        Assert.IsFalse(Worksheet.ShowPurchaseOrder.Enabled(), 'A cleared target must not be navigable.');
        Worksheet.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateTargetedSuggestion(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreateSuggestion(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, Vendor."No.", Item."No.");
        RequisitionLine."Ref. Order No." := PurchaseHeader."No.";
        RequisitionLine.Modify(true);
    end;

    local procedure CreateSuggestion(var RequisitionLine: Record "Requisition Line"; TemplateName: Code[10]; BatchName: Code[10]; VendorNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, TemplateName, BatchName);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Validate(Quantity, 1);
        RequisitionLine."Replenishment System" := RequisitionLine."Replenishment System"::Purchase;
        RequisitionLine."Ref. Order Type" := RequisitionLine."Ref. Order Type"::Purchase;
        RequisitionLine."Action Message" := RequisitionLine."Action Message"::New;
        RequisitionLine."Accept Action Message" := true;
        RequisitionLine.Modify(true);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateOpenOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
    end;

    local procedure CreateAssignableSuggestion(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreateOpenOrder(PurchaseHeader, Vendor."No.");
        CreateSuggestion(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, Vendor."No.", Item."No.");
        RequisitionLine."Prod. Order No." := 'PRODTGT';
        RequisitionLine."Prod. Order Line No." := 10000;
        RequisitionLine."Operation No." := '10';
        RequisitionLine.Modify();
    end;

    local procedure CreateLineTargetingNewOrder(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; FirstLine: Record "Requisition Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateOpenOrder(PurchaseHeader, FirstLine."Vendor No.");
        CreateSuggestion(RequisitionLine, FirstLine."Worksheet Template Name", FirstLine."Journal Batch Name", FirstLine."Vendor No.", Item."No.");
        RequisitionLine."Ref. Order No." := PurchaseHeader."No.";
        RequisitionLine.Modify(true);
    end;

    local procedure CreateBatchWithSecondTarget(var ValidLine: Record "Requisition Line"; var ValidHeader: Record "Purchase Header"; var InvalidLine: Record "Requisition Line"; var InvalidHeader: Record "Purchase Header")
    begin
        CreateTargetedSuggestion(ValidLine, ValidHeader);
        CreateLineTargetingNewOrder(InvalidLine, InvalidHeader, ValidLine);
    end;

    local procedure CreatePurchasingCode(var Purchasing: Record Purchasing; DropShipment: Boolean; SpecialOrder: Boolean)
    begin
        Purchasing.Init();
        Purchasing.Code := CopyStr(LibraryUtility.GenerateRandomCode(Purchasing.FieldNo(Code), Database::Purchasing), 1, MaxStrLen(Purchasing.Code));
        Purchasing."Drop Shipment" := DropShipment;
        Purchasing."Special Order" := SpecialOrder;
        Purchasing.Insert();
    end;

    local procedure RunCarryOut(RequisitionLine: Record "Requisition Line")
    var
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();
    end;

    local procedure VerifyBatchBlocked(ValidLine: Record "Requisition Line"; ValidHeader: Record "Purchase Header"; InvalidLine: Record "Requisition Line"; InvalidOrderNo: Code[20]; FailedCondition: Text)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // asserterror rolls back to the last commit; keep the setup so the THEN checks are meaningful.
        Commit();

        asserterror RunCarryOut(ValidLine);

        Assert.ExpectedError(StrSubstNo(TargetErr, InvalidLine."Line No.", InvalidLine."Worksheet Template Name",
            InvalidLine."Journal Batch Name", InvalidOrderNo, FailedCondition));
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", ValidHeader."No.");
        Assert.IsTrue(PurchaseLine.IsEmpty(), 'The valid target must not receive a line.');
        Assert.IsTrue(ValidLine.Get(ValidLine."Worksheet Template Name", ValidLine."Journal Batch Name", ValidLine."Line No."),
            'The valid suggestion must remain.');
        Assert.AreEqual(ValidHeader."No.", ValidLine."Ref. Order No.", 'The valid target assignment must remain.');
        Assert.IsTrue(InvalidLine.Get(InvalidLine."Worksheet Template Name", InvalidLine."Journal Batch Name", InvalidLine."Line No."),
            'The invalid suggestion must remain.');
        Assert.AreEqual(InvalidOrderNo, InvalidLine."Ref. Order No.", 'The target assignment must remain visible.');
    end;

    local procedure OpenWorksheetAtLine(var Worksheet: TestPage "Subc. Subcontracting Worksheet"; RequisitionLine: Record "Requisition Line")
    begin
        Worksheet.OpenEdit();
        Worksheet.CurrentJnlBatchName.SetValue(RequisitionLine."Journal Batch Name");
        Worksheet.GoToRecord(RequisitionLine);
    end;

    [ModalPageHandler]
    procedure SelectPurchaseOrderHandler(var PurchaseOrderList: TestPage "Purchase Order List")
    begin
        PurchaseOrderList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Assert.IsTrue(PurchaseOrderList.First(), 'The order to select must be offered.');
        PurchaseOrderList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CaptureOrdersHandler(var PurchaseOrderList: TestPage "Purchase Order List")
    begin
        if PurchaseOrderList.First() then
            repeat
                LibraryVariableStorage.Enqueue(PurchaseOrderList."No.".Value());
            until not PurchaseOrderList.Next();
        PurchaseOrderList.Cancel().Invoke();
    end;

    [PageHandler]
    procedure CapturePurchaseOrderHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrder."No.".Value());
        PurchaseOrder.Close();
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        TargetErr: Label 'Worksheet line %1 in %2/%3 cannot use purchase order %4: %5.', Comment = '%1 = line number, %2 = template, %3 = batch, %4 = order number, %5 = failed condition';
        MissingOrderErr: Label 'Purchase order %1 referenced by worksheet line %2 no longer exists.', Comment = '%1 = purchase order number, %2 = worksheet line number';
}