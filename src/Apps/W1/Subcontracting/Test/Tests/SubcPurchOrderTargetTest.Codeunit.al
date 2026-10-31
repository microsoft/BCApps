// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
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
    procedure FailingLaterLineKeepsAppendedLineAndConsumedSuggestionCommittedWithOrdinaryOrder()
    var
        TargetHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TargetedLine: Record "Requisition Line";
        OrdinaryLine: Record "Requisition Line";
        BlockedLine: Record "Requisition Line";
        OrdinaryItem: Record Item;
        BlockedItem: Record Item;
        OrdinaryVendor: Record Vendor;
    begin
        // [SCENARIO] A failing line after an ordinary order was finalized keeps the appended line and the consumed suggestion.
        Initialize();

        // [GIVEN] A targeted suggestion, an untargeted suggestion of a second vendor, and an untargeted suggestion of a third vendor whose item was blocked after the suggestion was created.
        CreateTargetedAndBlockedSuggestions(TargetedLine, TargetHeader, BlockedLine, BlockedItem, OrdinaryVendor);
        LibraryInventory.CreateItem(OrdinaryItem);
        CreateSuggestion(OrdinaryLine, TargetedLine."Worksheet Template Name", TargetedLine."Journal Batch Name", OrdinaryVendor."No.", OrdinaryItem."No.");
        // asserterror rolls back to the last commit; keep the setup so the THEN checks are meaningful.
        Commit();

        // [WHEN] Carry Out runs and fails on the blocked item.
        asserterror RunCarryOut(TargetedLine);

        // [THEN] The error names the blocked item.
        Assert.ExpectedTestFieldError(BlockedItem.FieldCaption(Blocked), Format(false));

        // [THEN] The target holds exactly one line from the targeted suggestion, and that suggestion is gone.
        VerifyTargetHoldsSingleLine(TargetHeader, TargetedLine."No.");
        Assert.IsFalse(IsRequisitionLinePresent(TargetedLine), 'The appended suggestion must be consumed.');

        // [THEN] The ordinary order exists and its suggestion is gone.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Buy-from Vendor No.", OrdinaryVendor."No.");
        PurchaseLine.SetRange("No.", OrdinaryItem."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The ordinary suggestion must create its own order.');
        Assert.IsFalse(IsRequisitionLinePresent(OrdinaryLine), 'The ordinary suggestion must be consumed.');

        // [THEN] The failing suggestion remains and has no order.
        BlockedLine.SetLoadFields("Vendor No.");
        Assert.IsTrue(BlockedLine.Get(BlockedLine."Worksheet Template Name", BlockedLine."Journal Batch Name", BlockedLine."Line No."),
            'The failing suggestion must remain.');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", BlockedLine."Vendor No.");
        Assert.IsTrue(PurchaseHeader.IsEmpty(), 'The failing suggestion must not create an order.');
    end;

    [Test]
    procedure RetryAfterFailingLaterLineDoesNotAppendTargetedLineTwice()
    var
        TargetHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TargetedLine: Record "Requisition Line";
        OrdinaryLine: Record "Requisition Line";
        BlockedLine: Record "Requisition Line";
        OrdinaryItem: Record Item;
        BlockedItem: Record Item;
        OrdinaryVendor: Record Vendor;
    begin
        // [SCENARIO] Retrying Carry Out after a failure on a later line never appends the targeted line twice.
        Initialize();

        // [GIVEN] A batch whose Carry Out failed on a blocked item after the targeted line was appended and an ordinary order was finalized.
        CreateTargetedAndBlockedSuggestions(TargetedLine, TargetHeader, BlockedLine, BlockedItem, OrdinaryVendor);
        LibraryInventory.CreateItem(OrdinaryItem);
        CreateSuggestion(OrdinaryLine, TargetedLine."Worksheet Template Name", TargetedLine."Journal Batch Name", OrdinaryVendor."No.", OrdinaryItem."No.");
        // asserterror rolls back to the last commit; keep the setup so the THEN checks are meaningful.
        Commit();
        asserterror RunCarryOut(TargetedLine);
        Assert.ExpectedTestFieldError(BlockedItem.FieldCaption(Blocked), Format(false));

        // [GIVEN] The item is unblocked.
        BlockedItem.Get(BlockedItem."No.");
        BlockedItem.Validate(Blocked, false);
        BlockedItem.Modify(true);

        // [WHEN] Carry Out runs again for the batch.
        RunCarryOut(BlockedLine);

        // [THEN] The target still holds a single line from the targeted suggestion.
        VerifyTargetHoldsSingleLine(TargetHeader, TargetedLine."No.");

        // [THEN] The previously failing suggestion creates its own order and is consumed.
        PurchaseLine.SetCurrentKey("Document Type", Type, "No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", BlockedItem."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The previously failing suggestion must create exactly one line.');
        PurchaseLine.SetLoadFields("Document No.");
        PurchaseLine.FindFirst();
        Assert.AreNotEqual(TargetHeader."No.", PurchaseLine."Document No.", 'The previously failing suggestion must not use the target.');
        PurchaseHeader.SetLoadFields("Buy-from Vendor No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Assert.AreEqual(BlockedLine."Vendor No.", PurchaseHeader."Buy-from Vendor No.", 'The new order must belong to the line''s vendor.');
        Assert.IsFalse(IsRequisitionLinePresent(BlockedLine), 'The previously failing suggestion must be consumed.');
    end;

    [Test]
    procedure FailingLaterLineWithoutFinalizedOrderRollsBackAppendAndConsumption()
    var
        TargetHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TargetedLine: Record "Requisition Line";
        BlockedLine: Record "Requisition Line";
        BlockedItem: Record Item;
        UnusedVendor: Record Vendor;
    begin
        // [SCENARIO] A failing line with no ordinary order finalized before it rolls back both the append and the consumption.
        Initialize();

        // [GIVEN] A targeted suggestion and an untargeted suggestion of another vendor whose item was blocked after the suggestion was created.
        CreateTargetedAndBlockedSuggestions(TargetedLine, TargetHeader, BlockedLine, BlockedItem, UnusedVendor);
        // asserterror rolls back to the last commit; keep the setup so the THEN checks are meaningful.
        Commit();

        // [WHEN] Carry Out runs and fails on the blocked item.
        asserterror RunCarryOut(TargetedLine);

        // [THEN] The error names the blocked item.
        Assert.ExpectedTestFieldError(BlockedItem.FieldCaption(Blocked), Format(false));

        // [THEN] The target has no line and the targeted suggestion remains with its target.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", TargetHeader."No.");
        Assert.IsTrue(PurchaseLine.IsEmpty(), 'The append must be rolled back.');
        TargetedLine.SetLoadFields("Ref. Order No.");
        Assert.IsTrue(TargetedLine.Get(TargetedLine."Worksheet Template Name", TargetedLine."Journal Batch Name", TargetedLine."Line No."),
            'The consumption must be rolled back.');
        Assert.AreEqual(TargetHeader."No.", TargetedLine."Ref. Order No.", 'The target assignment must remain.');

        // [THEN] The failing suggestion remains and has no order.
        BlockedLine.SetLoadFields("Vendor No.");
        Assert.IsTrue(BlockedLine.Get(BlockedLine."Worksheet Template Name", BlockedLine."Journal Batch Name", BlockedLine."Line No."),
            'The failing suggestion must remain.');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", BlockedLine."Vendor No.");
        Assert.IsTrue(PurchaseHeader.IsEmpty(), 'The failing suggestion must not create an order.');
    end;

    [Test]
    procedure HandledBeforeDeleteEventKeepsTargetedSuggestionLikeOrdinaryOne()
    var
        TargetHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TargetedLine: Record "Requisition Line";
        OrdinaryLine: Record "Requisition Line";
        TargetedItem: Record Item;
        OrdinaryItem: Record Item;
        TargetVendor: Record Vendor;
        OrdinaryVendor: Record Vendor;
        UnusedVendor: Record Vendor;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcKeepCarriedOutReqLine: Codeunit "Subc. Keep Carried Out ReqLine";
    begin
        // [SCENARIO] A subscriber that handles the before-delete event for carried-out suggestions keeps a targeted suggestion as it keeps an ordinary one.
        Initialize();

        // [GIVEN] A targeted suggestion processed first and an untargeted suggestion of the next vendor.
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        CreateVendorsInProcessingOrder(TargetVendor, OrdinaryVendor, UnusedVendor);
        LibraryInventory.CreateItem(TargetedItem);
        LibraryInventory.CreateItem(OrdinaryItem);
        CreateOpenOrder(TargetHeader, TargetVendor."No.");
        CreateSuggestion(TargetedLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, TargetVendor."No.", TargetedItem."No.");
        TargetedLine."Ref. Order No." := TargetHeader."No.";
        TargetedLine.Modify(true);
        CreateSuggestion(OrdinaryLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, OrdinaryVendor."No.", OrdinaryItem."No.");

        // [WHEN] Carry Out runs with a manually bound subscriber that sets IsHandled on the before-delete events.
        BindSubscription(SubcKeepCarriedOutReqLine);
        RunCarryOut(TargetedLine);
        UnbindSubscription(SubcKeepCarriedOutReqLine);

        // [THEN] The targeted suggestion is appended, passed to the before-delete event, and kept.
        VerifyTargetHoldsSingleLine(TargetHeader, TargetedItem."No.");
        Assert.IsTrue(SubcKeepCarriedOutReqLine.WasKept(TargetedLine), 'The before-delete event must be raised for the targeted suggestion.');
        Assert.IsTrue(IsRequisitionLinePresent(TargetedLine), 'The handled targeted suggestion must be kept.');

        // [THEN] The ordinary suggestion creates its order, is passed to the same event, and is kept as well.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Buy-from Vendor No.", OrdinaryVendor."No.");
        PurchaseLine.SetRange("No.", OrdinaryItem."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The ordinary suggestion must create its own order.');
        Assert.IsTrue(SubcKeepCarriedOutReqLine.WasKept(OrdinaryLine), 'The before-delete event must be raised for the ordinary suggestion.');
        Assert.IsTrue(IsRequisitionLinePresent(OrdinaryLine), 'The handled ordinary suggestion must be kept.');
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
    procedure ClearingTargetWithNonSimulatedStatusClearsOrderReference()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
    begin
        // [GIVEN] A code-assigned target whose Ref. Order Status is not Simulated.
        Initialize();
        CreateTargetedSuggestion(RequisitionLine, PurchaseHeader);
        RequisitionLine."Ref. Order Status" := RequisitionLine."Ref. Order Status"::Released;
        RequisitionLine.Modify(true);
        Assert.IsTrue(RequisitionLine.HasPurchaseOrderTarget(), 'The line must count as a target.');
        OpenWorksheetAtLine(Worksheet, RequisitionLine);

        // [WHEN] Clearing the selected order on the worksheet line.
        Worksheet.ClearPurchaseOrder.Invoke();

        // [THEN] The order reference is removed and the status is reset.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        Assert.AreEqual('', RequisitionLine."Ref. Order No.", 'The assigned order should be cleared.');
        Assert.AreEqual(RequisitionLine."Ref. Order Status"::Simulated, RequisitionLine."Ref. Order Status", 'Ref. Order Status');
        Assert.IsFalse(RequisitionLine.HasPurchaseOrderTarget(), 'The line must no longer count as a target.');
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

    [Test]
    procedure UnassignedSuggestionKeepsProductionDimensionAfterVendorChangeAndCarryOut()
    var
        DimensionValue: Record "Dimension Value";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO] A suggestion without an assigned order keeps the production-only dimension after its vendor is changed and changed back.
        InitializeProduction();

        // [GIVEN] A calculated suggestion for a released production order line with a dimension that no default dimension provides.
        CreateCalculatedSuggestionWithProductionDimension(RequisitionLine, ProductionOrder, DimensionValue);

        // [GIVEN] The vendor is changed and changed back, which rebuilds the dimensions from the defaults.
        SubcontractingMgmtLibrary.ChangeVendorAndBack(RequisitionLine);
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        VerifyDimensionValueInSet(RequisitionLine."Dimension Set ID", DimensionValue);

        // [WHEN] Carry Out runs without an assigned order.
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(RequisitionLine);

        // [THEN] The purchase line of the new order carries the production dimension.
        SubcontractingMgmtLibrary.FindSubcPurchLineForProdOrder(PurchaseLine, RequisitionLine."No.", ProductionOrder."No.");
        VerifyDimensionValueInSet(PurchaseLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('SelectPurchaseOrderHandler')]
    procedure AssignedSuggestionKeepsProductionDimensionAfterVendorChange()
    var
        DimensionValue: Record "Dimension Value";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO] A suggestion with an assigned order keeps the production-only dimension after its vendor is changed and changed back.
        InitializeProduction();

        // [GIVEN] A calculated suggestion for a released production order line with a dimension that no default dimension provides.
        CreateCalculatedSuggestionWithProductionDimension(RequisitionLine, ProductionOrder, DimensionValue);

        // [GIVEN] An open order of the suggestion's vendor is assigned.
        CreateOpenOrder(PurchaseHeader, RequisitionLine."Vendor No.");
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        RequisitionLine.AssignPurchaseOrderTarget();

        // [WHEN] The vendor is changed and changed back, which rebuilds the dimensions from the defaults.
        SubcontractingMgmtLibrary.ChangeVendorAndBack(RequisitionLine);

        // [THEN] The worksheet line keeps its assignment and still carries the production dimension.
        RequisitionLine.SetLoadFields("Ref. Order No.", "Dimension Set ID");
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        Assert.AreEqual(PurchaseHeader."No.", RequisitionLine."Ref. Order No.", 'The assignment must remain.');
        VerifyDimensionValueInSet(RequisitionLine."Dimension Set ID", DimensionValue);

        // [THEN] SelectPurchaseOrderHandler selected the enqueued order in the purchase order lookup of the assignment and consumed it.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectPurchaseOrderHandler')]
    procedure SuggestionsOfTwoProductionOrdersConsolidateIntoOneExistingOrder()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        FirstItem: Record Item;
        SecondItem: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        FirstProductionOrder: Record "Production Order";
        SecondProductionOrder: Record "Production Order";
        HeaderBefore: Record "Purchase Header";
        TargetHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        SecondPurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        FirstSuggestion: Record "Requisition Line";
        SecondSuggestion: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: array[2] of Record "Work Center";
        FirstDirectUnitCost: Decimal;
        SecondDirectUnitCost: Decimal;
    begin
        // [SCENARIO] Suggestions of two real released production orders, assigned to one existing open order, are appended to it by Carry Out.
        InitializeProduction();

        // [GIVEN] A subcontracting work center and two production items, each with a subcontractor price and a vendor-supplied component linked to the subcontracting operation.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true, "Unit Cost Calculation Type"::Units);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
        CreateSubcontractedItemWithPrice(FirstItem, WorkCenter, MachineCenter, FirstDirectUnitCost);
        CreateSubcontractedItemWithPrice(SecondItem, WorkCenter, MachineCenter, SecondDirectUnitCost);

        // [GIVEN] A released production order per item whose line carries a dimension that no default dimension provides.
        CreateReleasedProdOrderWithProductionDimension(FirstProductionOrder, FirstItem, FirstDimensionValue);
        CreateReleasedProdOrderWithProductionDimension(SecondProductionOrder, SecondItem, SecondDimensionValue);

        // [GIVEN] Subcontracts are calculated for the subcontracting work center.
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        SubcontractingMgmtLibrary.CalculateSubcontracts(RequisitionWkshName, WorkCenter[2]."No.");
        FindSuggestion(FirstSuggestion, RequisitionWkshName, FirstProductionOrder."No.");
        FindSuggestion(SecondSuggestion, RequisitionWkshName, SecondProductionOrder."No.");

        // [GIVEN] An existing open order of the subcontractor with a reference on its header.
        CreateOpenOrder(TargetHeader, FirstSuggestion."Vendor No.");
        TargetHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        TargetHeader.Modify(true);
        LoadComparedHeaderFields(HeaderBefore);
        HeaderBefore.Get(TargetHeader."Document Type", TargetHeader."No.");

        // [GIVEN] The first suggestion's vendor is changed and changed back before it is assigned to the order.
        SubcontractingMgmtLibrary.ChangeVendorAndBack(FirstSuggestion);
        AssignPurchaseOrder(FirstSuggestion, TargetHeader."No.");

        // [GIVEN] The second suggestion is assigned to the order before its vendor is changed and changed back.
        AssignPurchaseOrder(SecondSuggestion, TargetHeader."No.");
        SubcontractingMgmtLibrary.ChangeVendorAndBack(SecondSuggestion);

        // [WHEN] Carry Out runs for the worksheet.
        RunCarryOut(FirstSuggestion);

        // [THEN] The order holds one appended line per suggestion with its own production order, line, routing and operation.
        FindAppendedSubcontractingLine(FirstPurchaseLine, TargetHeader, FirstSuggestion);
        FindAppendedSubcontractingLine(SecondPurchaseLine, TargetHeader, SecondSuggestion);
        Assert.AreNotEqual(FirstPurchaseLine."Prod. Order No.", SecondPurchaseLine."Prod. Order No.", 'Each line must reference its own production order.');
        Assert.AreNotEqual(FirstPurchaseLine."Routing No.", SecondPurchaseLine."Routing No.", 'Each line must reference its own routing.');

        // [THEN] Both lines carry their production dimension and the subcontractor price.
        VerifyDimensionValueInSet(FirstPurchaseLine."Dimension Set ID", FirstDimensionValue);
        VerifyDimensionValueInSet(SecondPurchaseLine."Dimension Set ID", SecondDimensionValue);
        Assert.AreEqual(FirstDirectUnitCost, FirstPurchaseLine."Direct Unit Cost", 'The first line must use the subcontractor price.');
        Assert.AreEqual(SecondDirectUnitCost, SecondPurchaseLine."Direct Unit Cost", 'The second line must use the subcontractor price.');

        // [THEN] The vendor-supplied component of each production order is added to the order, as on a new order.
        VerifyVendorSuppliedComponentLine(TargetHeader."No.", FirstItem."Production BOM No.", FirstSuggestion);
        VerifyVendorSuppliedComponentLine(TargetHeader."No.", SecondItem."Production BOM No.", SecondSuggestion);

        // [THEN] The header is unchanged and both suggestions are consumed.
        VerifyHeaderUnchanged(HeaderBefore);
        Assert.IsFalse(IsRequisitionLinePresent(FirstSuggestion), 'The first suggestion must be consumed.');
        Assert.IsFalse(IsRequisitionLinePresent(SecondSuggestion), 'The second suggestion must be consumed.');

        // [THEN] SelectPurchaseOrderHandler selected each enqueued order in the purchase order lookup of its assignment and consumed it.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectPurchaseOrderHandler')]
    procedure AssignOnRecurringTemplateIsRejected()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        // [SCENARIO] A purchase order can't be assigned to a suggestion on a recurring worksheet template.
        Initialize();

        // [GIVEN] An assignable suggestion on a recurring template and a compatible open order.
        CreateRecurringBatch(RequisitionWkshName);
        CreateAssignableSuggestionInBatch(RequisitionLine, PurchaseHeader, RequisitionWkshName);
        // asserterror rolls back to the last commit; keep the setup so the THEN checks are meaningful.
        Commit();

        // [WHEN] The order is assigned; the handler selects it in the lookup.
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        asserterror RequisitionLine.AssignPurchaseOrderTarget();

        // [THEN] The assignment is rejected with an error naming the worksheet line, the order and the recurring template.
        Assert.ExpectedError(StrSubstNo(TargetErr, RequisitionLine."Line No.", RequisitionLine."Worksheet Template Name",
            RequisitionLine."Journal Batch Name", PurchaseHeader."No.", 'the worksheet template is recurring'));
        RequisitionLine.SetLoadFields("Ref. Order No.");
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        Assert.AreEqual('', RequisitionLine."Ref. Order No.", 'The rejected order must not be stored on the line.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TargetOnRecurringTemplateBlocksCarryOutBeforeChangingOrders()
    var
        Item: Record Item;
        NewOrderVendor: Record Vendor;
        TargetVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        TargetHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        TargetedLine: Record "Requisition Line";
        UntargetedLine: Record "Requisition Line";
        TargetHeaderModifiedAt: DateTime;
    begin
        // [SCENARIO] An accepted line on a recurring template whose target is set by code stops Carry Out in its pre-run check.
        Initialize();

        // [GIVEN] A recurring batch whose first accepted line, of its own vendor, would create a new order.
        CreateRecurringBatch(RequisitionWkshName);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(NewOrderVendor);
        CreateRecurringSuggestion(UntargetedLine, RequisitionWkshName, NewOrderVendor."No.", Item."No.");

        // [GIVEN] A following accepted line whose target is set by code.
        LibraryPurchase.CreateVendor(TargetVendor);
        CreateOpenOrder(TargetHeader, TargetVendor."No.");
        TargetHeader.SetLoadFields(SystemModifiedAt);
        TargetHeader.Get(TargetHeader."Document Type", TargetHeader."No.");
        TargetHeaderModifiedAt := TargetHeader.SystemModifiedAt;
        CreateRecurringSuggestion(TargetedLine, RequisitionWkshName, TargetVendor."No.", Item."No.");
        TargetedLine."Ref. Order No." := TargetHeader."No.";
        TargetedLine.Modify(true);
        // asserterror rolls back to the last commit; keep the setup so the THEN checks are meaningful.
        Commit();

        // [WHEN] Carry Out runs for the recurring batch.
        asserterror RunRecurringCarryOut(UntargetedLine);

        // [THEN] The pre-run check names the targeted line, the order and the recurring template.
        Assert.ExpectedError(StrSubstNo(TargetErr, TargetedLine."Line No.", TargetedLine."Worksheet Template Name",
            TargetedLine."Journal Batch Name", TargetHeader."No.", 'the worksheet template is recurring'));

        // [THEN] No purchase order or line is created or changed.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", NewOrderVendor."No.");
        Assert.IsTrue(PurchaseHeader.IsEmpty(), 'The untargeted line must not create an order.');
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", TargetHeader."No.");
        Assert.IsTrue(PurchaseLine.IsEmpty(), 'The target must not receive a line.');
        TargetHeader.Get(TargetHeader."Document Type", TargetHeader."No.");
        Assert.AreEqual(TargetHeaderModifiedAt, TargetHeader.SystemModifiedAt, 'The target header must not change.');

        // [THEN] Both worksheet lines and the target remain.
        Assert.IsTrue(IsRequisitionLinePresent(UntargetedLine), 'The untargeted suggestion must remain.');
        TargetedLine.SetLoadFields("Ref. Order No.");
        Assert.IsTrue(TargetedLine.Get(TargetedLine."Worksheet Template Name", TargetedLine."Journal Batch Name", TargetedLine."Line No."),
            'The targeted suggestion must remain.');
        Assert.AreEqual(TargetHeader."No.", TargetedLine."Ref. Order No.", 'The target assignment must remain visible.');
    end;

    local procedure CreateCalculatedSuggestionWithProductionDimension(var RequisitionLine: Record "Requisition Line"; var ProductionOrder: Record "Production Order"; var DimensionValue: Record "Dimension Value")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkCenter: Record "Work Center";
    begin
        SubcontractingMgmtLibrary.CreateReleasedProdOrderWithSubcontractingOperation(ProductionOrder, WorkCenter);
        SubcontractingMgmtLibrary.AddNewDimensionToProdOrderLines(ProductionOrder, DimensionValue);
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        SubcontractingMgmtLibrary.CalculateSubcontractsAndFindReqLine(RequisitionWkshName, ProductionOrder."No.", RequisitionLine);
        Assert.AreEqual(RequisitionLine."Action Message"::New, RequisitionLine."Action Message", 'The suggestion must be New.');
        Assert.AreEqual(RequisitionLine."Ref. Order Type"::Purchase, RequisitionLine."Ref. Order Type", 'The suggestion must use a Purchase reference.');
        VerifyDimensionValueInSet(RequisitionLine."Dimension Set ID", DimensionValue);
    end;

    local procedure VerifyDimensionValueInSet(DimensionSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetLoadFields("Dimension Value Code");
        Assert.IsTrue(DimensionSetEntry.Get(DimensionSetID, DimensionValue."Dimension Code"), 'The production dimension must be in the dimension set.');
        Assert.AreEqual(DimensionValue.Code, DimensionSetEntry."Dimension Value Code", 'The production dimension value must be kept.');
    end;

    local procedure CreateSubcontractedItemWithPrice(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center"; var DirectUnitCost: Decimal)
    var
        SubcontractorPrice: Record "Subcontractor Price";
    begin
        SubcWarehouseLibrary.CreateItemForProductionWithCostOverrides(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkByBOMNo(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");

        DirectUnitCost := LibraryRandom.RandIntInRange(10, 100);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter[2]."No.", WorkCenter[2]."Subcontractor No.", Item."No.", '', '',
            CalcDate('<-1Y>', WorkDate()), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", DirectUnitCost);
        SubcontractorPrice.Modify(true);
    end;

    local procedure CreateReleasedProdOrderWithProductionDimension(var ProductionOrder: Record "Production Order"; Item: Record Item; var DimensionValue: Record "Dimension Value")
    begin
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(2, 10));
        SubcontractingMgmtLibrary.AddNewDimensionToProdOrderLines(ProductionOrder, DimensionValue);
    end;

    local procedure FindSuggestion(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; ProdOrderNo: Code[20])
    begin
        SubcontractingMgmtLibrary.FindRequisitionLineForProdOrder(RequisitionWkshName, ProdOrderNo, RequisitionLine);
        Assert.AreEqual(1, RequisitionLine.Count(), 'Each production order must produce exactly one suggestion.');
        RequisitionLine.Reset();
        Assert.AreEqual(RequisitionLine."Action Message"::New, RequisitionLine."Action Message", 'The suggestion must be New.');
    end;

    local procedure AssignPurchaseOrder(var RequisitionLine: Record "Requisition Line"; PurchaseOrderNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrderNo);
        RequisitionLine.AssignPurchaseOrderTarget();
        Assert.AreEqual(PurchaseOrderNo, RequisitionLine."Ref. Order No.", 'The order must be assigned.');
    end;

    local procedure FindAppendedSubcontractingLine(var PurchaseLine: Record "Purchase Line"; TargetHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line")
    begin
        PurchaseLine.SetCurrentKey("Document Type", "Document No.");
        PurchaseLine.SetRange("Document Type", TargetHeader."Document Type");
        PurchaseLine.SetRange("Document No.", TargetHeader."No.");
        PurchaseLine.SetRange("Prod. Order No.", RequisitionLine."Prod. Order No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The order must receive exactly one subcontracting line per suggestion.');
        PurchaseLine.SetLoadFields("No.", "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.", "Dimension Set ID", "Direct Unit Cost");
        PurchaseLine.FindFirst();
        Assert.AreEqual(RequisitionLine."No.", PurchaseLine."No.", 'The line must purchase the item of its production order.');
        Assert.AreEqual(RequisitionLine."Prod. Order Line No.", PurchaseLine."Prod. Order Line No.", 'The line must keep its production order line.');
        Assert.AreEqual(RequisitionLine."Routing No.", PurchaseLine."Routing No.", 'The line must keep its routing.');
        Assert.AreEqual(RequisitionLine."Operation No.", PurchaseLine."Operation No.", 'The line must keep its operation.');
    end;

    local procedure VerifyVendorSuppliedComponentLine(PurchaseOrderNo: Code[20]; ProductionBOMNo: Code[20]; RequisitionLine: Record "Requisition Line")
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
    begin
        ProductionBOMLine.SetLoadFields("No.", "Component Supply Method");
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindLast();
        Assert.AreEqual("Component Supply Method"::"Vendor-Supplied", ProductionBOMLine."Component Supply Method", 'The last BOM line must be vendor-supplied.');

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.");
        ProdOrderComponent.SetLoadFields("Remaining Quantity", "Component Supply Method");
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", RequisitionLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", RequisitionLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Item No.", ProductionBOMLine."No.");
        ProdOrderComponent.FindFirst();
        Assert.AreEqual("Component Supply Method"::"Vendor-Supplied", ProdOrderComponent."Component Supply Method", 'The component must be vendor-supplied.');

        SubcontractingMgmtLibrary.FindComponentPurchLine(PurchaseLine, PurchaseOrderNo, ProductionBOMLine."No.");
        PurchaseLine.SetCurrentKey("Document Type", "Document No.", Type, "No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The vendor-supplied component must be added to the order once.');
        PurchaseLine.SetLoadFields(Quantity, "Subc. Prod. Order No.", "Subc. Operation No.");
        PurchaseLine.FindFirst();
        Assert.AreEqual(RequisitionLine."Prod. Order No.", PurchaseLine."Subc. Prod. Order No.", 'The component line must reference the production order of its suggestion.');
        Assert.AreEqual(RequisitionLine."Operation No.", PurchaseLine."Subc. Operation No.", 'The component line must reference the operation of its suggestion.');
        Assert.AreEqual(ProdOrderComponent."Remaining Quantity", PurchaseLine.Quantity, 'The component line must cover the remaining component quantity.');
    end;

    local procedure LoadComparedHeaderFields(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetLoadFields(
            "Buy-from Vendor No.", "Pay-to Vendor No.", "Currency Code", "Order Date", "Posting Date", "Expected Receipt Date",
            "Location Code", "Ship-to Code", "Your Reference", "Dimension Set ID", Status);
    end;

    local procedure IsRequisitionLinePresent(RequisitionLine: Record "Requisition Line"): Boolean
    var
        ExistingRequisitionLine: Record "Requisition Line";
    begin
        ExistingRequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        ExistingRequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        ExistingRequisitionLine.SetRange("Line No.", RequisitionLine."Line No.");
        exit(not ExistingRequisitionLine.IsEmpty());
    end;

    local procedure VerifyHeaderUnchanged(HeaderBefore: Record "Purchase Header")
    var
        HeaderAfter: Record "Purchase Header";
    begin
        LoadComparedHeaderFields(HeaderAfter);
        HeaderAfter.Get(HeaderBefore."Document Type", HeaderBefore."No.");
        Assert.AreEqual(HeaderBefore."Buy-from Vendor No.", HeaderAfter."Buy-from Vendor No.", 'Vendor must not change.');
        Assert.AreEqual(HeaderBefore."Pay-to Vendor No.", HeaderAfter."Pay-to Vendor No.", 'Pay-to vendor must not change.');
        Assert.AreEqual(HeaderBefore."Currency Code", HeaderAfter."Currency Code", 'Currency must not change.');
        Assert.AreEqual(HeaderBefore."Order Date", HeaderAfter."Order Date", 'Order date must not change.');
        Assert.AreEqual(HeaderBefore."Posting Date", HeaderAfter."Posting Date", 'Posting date must not change.');
        Assert.AreEqual(HeaderBefore."Expected Receipt Date", HeaderAfter."Expected Receipt Date", 'Receipt date must not change.');
        Assert.AreEqual(HeaderBefore."Location Code", HeaderAfter."Location Code", 'Location must not change.');
        Assert.AreEqual(HeaderBefore."Ship-to Code", HeaderAfter."Ship-to Code", 'Ship-to code must not change.');
        Assert.AreEqual(HeaderBefore."Your Reference", HeaderAfter."Your Reference", 'Reference must not change.');
        Assert.AreEqual(HeaderBefore."Dimension Set ID", HeaderAfter."Dimension Set ID", 'Header dimensions must not change.');
        Assert.AreEqual(HeaderBefore.Status, HeaderAfter.Status, 'Status must not change.');
    end;

    local procedure InitializeProduction()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. PurchOrderTargetTest");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
        LibraryMfgManagement.Initialize();
        if IsProductionInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. PurchOrderTargetTest");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsProductionInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. PurchOrderTargetTest");
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

    local procedure CreateTargetedAndBlockedSuggestions(var TargetedLine: Record "Requisition Line"; var TargetHeader: Record "Purchase Header"; var BlockedLine: Record "Requisition Line"; var BlockedItem: Record Item; var MiddleVendor: Record Vendor)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        TargetedItem: Record Item;
        TargetVendor: Record Vendor;
        BlockedVendor: Record Vendor;
    begin
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        CreateVendorsInProcessingOrder(TargetVendor, MiddleVendor, BlockedVendor);
        LibraryInventory.CreateItem(TargetedItem);
        CreateOpenOrder(TargetHeader, TargetVendor."No.");
        CreateSuggestion(TargetedLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, TargetVendor."No.", TargetedItem."No.");
        TargetedLine."Ref. Order No." := TargetHeader."No.";
        TargetedLine.Modify(true);
        LibraryInventory.CreateItem(BlockedItem);
        CreateSuggestion(BlockedLine, ReqWkshTemplate.Name, RequisitionWkshName.Name, BlockedVendor."No.", BlockedItem."No.");
        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);
    end;

    local procedure CreateVendorsInProcessingOrder(var FirstVendor: Record Vendor; var SecondVendor: Record Vendor; var ThirdVendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(FirstVendor);
        LibraryPurchase.CreateVendor(SecondVendor);
        LibraryPurchase.CreateVendor(ThirdVendor);
        SortVendorPair(FirstVendor, SecondVendor);
        SortVendorPair(SecondVendor, ThirdVendor);
        SortVendorPair(FirstVendor, SecondVendor);
    end;

    local procedure SortVendorPair(var LowerVendor: Record Vendor; var HigherVendor: Record Vendor)
    var
        Vendor: Record Vendor;
    begin
        if LowerVendor."No." < HigherVendor."No." then
            exit;
        Vendor := LowerVendor;
        LowerVendor := HigherVendor;
        HigherVendor := Vendor;
    end;

    local procedure VerifyTargetHoldsSingleLine(TargetHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", TargetHeader."Document Type");
        PurchaseLine.SetRange("Document No.", TargetHeader."No.");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The target must hold exactly one appended line.');
        PurchaseLine.FindFirst();
        Assert.AreEqual(ItemNo, PurchaseLine."No.", 'The appended line must come from the targeted suggestion.');
    end;

    local procedure CreateOpenOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
    end;

    local procedure CreateAssignableSuggestion(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(ReqWkshTemplate, RequisitionWkshName);
        CreateAssignableSuggestionInBatch(RequisitionLine, PurchaseHeader, RequisitionWkshName);
    end;

    local procedure CreateAssignableSuggestionInBatch(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreateOpenOrder(PurchaseHeader, Vendor."No.");
        CreateSuggestion(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, Vendor."No.", Item."No.");
        RequisitionLine."Prod. Order No." := 'PRODTGT';
        RequisitionLine."Prod. Order Line No." := 10000;
        RequisitionLine."Operation No." := '10';
        RequisitionLine.Modify();
    end;

    local procedure CreateRecurringBatch(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        LibraryMfgManagement.CreateReqWkshTemplate(ReqWkshTemplate, true);
        LibraryMfgManagement.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateRecurringSuggestion(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; VendorNo: Code[20]; ItemNo: Code[20])
    begin
        CreateSuggestion(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, VendorNo, ItemNo);
        RequisitionLine."Order Date" := WorkDate();
        RequisitionLine."Recurring Method" := RequisitionLine."Recurring Method"::Fixed;
        Evaluate(RequisitionLine."Recurring Frequency", '<1M>');
        RequisitionLine.Modify(true);
    end;

    local procedure RunRecurringCarryOut(RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
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
        if DropShipment then
            LibraryPurchase.CreateDropShipmentPurchasingCode(Purchasing)
        else
            if SpecialOrder then
                LibraryPurchase.CreateSpecialOrderPurchasingCode(Purchasing)
            else
                LibraryPurchase.CreatePurchasingCode(Purchasing);
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
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsProductionInitialized: Boolean;
        TargetErr: Label 'Worksheet line %1 in %2/%3 cannot use purchase order %4: %5.', Comment = '%1 = line number, %2 = template, %3 = batch, %4 = order number, %5 = failed condition';
        MissingOrderErr: Label 'Purchase order %1 referenced by worksheet line %2 no longer exists.', Comment = '%1 = purchase order number, %2 = worksheet line number';
}