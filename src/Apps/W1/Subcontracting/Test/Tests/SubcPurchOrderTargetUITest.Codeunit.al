// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;
using System.TestLibraries.Utilities;

codeunit 140000 "Subc. PurchOrderTarget UI Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] [Subcontracting] [UI] Assign an existing purchase order on the Subcontracting Worksheet
    end;

    [Test]
    [HandlerFunctions('CapturePurchaseOrderHandler')]
    procedure ShowPurchaseOrderOpensAssignedOrderThatIsNoLongerOpen()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
    begin
        // [SCENARIO] Show purchase order opens the assigned order even when the order is no longer open.
        Initialize();

        // [GIVEN] A worksheet line whose assigned order has been released.
        SubcontractingMgmtLibrary.CreateTargetedPurchaseSuggestion(RequisitionLine, PurchaseHeader);
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
        // [SCENARIO] Show purchase order reports an assigned order that no longer exists.
        Initialize();

        // [GIVEN] A worksheet line whose assigned order has been deleted.
        SubcontractingMgmtLibrary.CreateTargetedPurchaseSuggestion(RequisitionLine, PurchaseHeader);
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
        // [SCENARIO] Clearing the assigned order on the worksheet changes only the current line.
        Initialize();

        // [GIVEN] Two suggestions with assigned orders.
        SubcontractingMgmtLibrary.CreateTargetedPurchaseSuggestion(RequisitionLine, PurchaseHeader);
        SubcontractingMgmtLibrary.CreateSuggestionTargetingNewOrder(OtherLine, OtherHeader, RequisitionLine);
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
        // [SCENARIO] Clearing an assigned order whose Ref. Order Status isn't Simulated removes the reference and resets the status.
        Initialize();

        // [GIVEN] A code-assigned target whose Ref. Order Status is not Simulated.
        SubcontractingMgmtLibrary.CreateTargetedPurchaseSuggestion(RequisitionLine, PurchaseHeader);
        RequisitionLine."Ref. Order Status" := RequisitionLine."Ref. Order Status"::Released;
        RequisitionLine.Modify(true);
        Assert.AreEqual(PurchaseHeader."No.", RequisitionLine."Ref. Order No.", 'The line must reference the target order.');
        Assert.AreEqual(0, RequisitionLine."Ref. Line No.", 'A target must not reference a purchase line.');
        OpenWorksheetAtLine(Worksheet, RequisitionLine);

        // [WHEN] Clearing the selected order on the worksheet line.
        Worksheet.ClearPurchaseOrder.Invoke();

        // [THEN] The order reference is removed and the status is reset.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        Assert.AreEqual('', RequisitionLine."Ref. Order No.", 'The assigned order should be cleared.');
        Assert.AreEqual(RequisitionLine."Ref. Order Status"::Simulated, RequisitionLine."Ref. Order Status", 'Ref. Order Status');
        Worksheet.Close();
    end;

    [Test]
    [HandlerFunctions('SelectPurchaseOrderHandler')]
    procedure ShowPurchaseOrderIsEnabledAfterAssigningOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
    begin
        // [SCENARIO] Assigning an order on the worksheet stores it on the line and enables Show purchase order.
        Initialize();

        // [GIVEN] A worksheet line without assigned order, so there is no order to show.
        SubcontractingMgmtLibrary.CreateAssignablePurchaseSuggestion(RequisitionLine, PurchaseHeader);
        OpenWorksheetAtLine(Worksheet, RequisitionLine);
        Assert.IsFalse(Worksheet.ShowPurchaseOrder.Enabled(), 'A line without target has no order to show.');

        // [WHEN] An order is assigned on the page; SelectPurchaseOrderHandler selects it in the lookup.
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        Worksheet.AssignPurchaseOrder.Invoke();

        // [THEN] The assigned order is stored and navigable.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        Assert.AreEqual(PurchaseHeader."No.", RequisitionLine."Ref. Order No.", 'The order should be assigned.');
        Assert.IsTrue(Worksheet.ShowPurchaseOrder.Enabled(), 'An assigned order must be navigable.');
        Worksheet.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ShowPurchaseOrderIsDisabledAfterClearingOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
    begin
        // [SCENARIO] Clearing the assigned order on the worksheet disables Show purchase order.
        Initialize();

        // [GIVEN] A worksheet line with an assigned order that can be shown.
        SubcontractingMgmtLibrary.CreateTargetedPurchaseSuggestion(RequisitionLine, PurchaseHeader);
        OpenWorksheetAtLine(Worksheet, RequisitionLine);
        Assert.IsTrue(Worksheet.ShowPurchaseOrder.Enabled(), 'An assigned order must be navigable.');

        // [WHEN] The target is cleared on the page.
        Worksheet.ClearPurchaseOrder.Invoke();

        // [THEN] Navigation is no longer offered.
        Assert.IsFalse(Worksheet.ShowPurchaseOrder.Enabled(), 'A cleared target must not be navigable.');
        Worksheet.Close();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
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

    [PageHandler]
    procedure CapturePurchaseOrderHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrder."No.".Value());
        PurchaseOrder.Close();
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        MissingOrderErr: Label 'Purchase order %1 referenced by worksheet line %2 no longer exists.', Comment = '%1 = purchase order number, %2 = worksheet line number';
}
