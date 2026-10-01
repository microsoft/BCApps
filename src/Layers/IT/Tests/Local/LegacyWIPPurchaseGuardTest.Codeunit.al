// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

codeunit 137506 "Legacy WIP Purchase Guard Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        Initialized: Boolean;
        ReopenLegacyWIPPurchaseLineErr: Label 'You cannot increase Quantity on a completed purchase line with a WIP Item after Legacy Subcontracting has been disabled.';
        UndoLegacyWIPPurchaseReceiptErr: Label 'You cannot undo receipt for a completed purchase line with a WIP Item after Legacy Subcontracting has been disabled.';

    [Test]
    [Scope('OnPrem')]
    procedure CannotReopenFullyReceivedWIPPurchaseLineAfterDisabling()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        // [SCENARIO 649448] A retained fully received WIP purchase line cannot become outstanding after disabling Legacy Subcontracting
        Initialize();

        // [GIVEN] Legacy Subcontracting is disabled
        SetLegacySubcontracting(false);

        // [GIVEN] A retained WIP purchase order item line is fully received
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        SetWIPItem(PurchaseLine);
        PurchaseLine."Quantity Received" := PurchaseLine.Quantity;
        PurchaseLine."Outstanding Quantity" := 0;
        PurchaseLine.Modify();

        // [WHEN] Quantity is increased
        asserterror PurchaseLine.Validate(Quantity, PurchaseLine.Quantity + 1);

        // [THEN] The retained legacy WIP purchase line cannot be reopened
        Assert.ExpectedError(ReopenLegacyWIPPurchaseLineErr);
    end;

    [Test]
    [HandlerFunctions('AcceptConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure CannotUndoReceiptForWIPPurchaseLineAfterDisabling()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        // [SCENARIO 649448] Undoing a receipt cannot reopen a retained WIP purchase line after disabling Legacy Subcontracting
        Initialize();

        // [GIVEN] A legacy WIP purchase order item line is fully received
        SetLegacySubcontracting(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        SetWIPItem(PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, PurchaseLine."Outstanding Quantity", 'The WIP purchase line should be fully received.');

        // [GIVEN] Legacy Subcontracting is disabled
        SetLegacySubcontracting(false);

        // [WHEN] The posted receipt is undone
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
        asserterror Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] The retained legacy WIP purchase line cannot be reopened
        Assert.ExpectedError(UndoLegacyWIPPurchaseReceiptErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Legacy WIP Purchase Guard Test");
        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Legacy WIP Purchase Guard Test");
        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Legacy WIP Purchase Guard Test");
    end;

    local procedure SetLegacySubcontracting(Enabled: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ManufacturingSetupRecordRef: RecordRef;
        LegacySubcontractingFieldRef: FieldRef;
    begin
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;

        ManufacturingSetupRecordRef.GetTable(ManufacturingSetup);
        LegacySubcontractingFieldRef := ManufacturingSetupRecordRef.Field(5600);
        LegacySubcontractingFieldRef.Value := Enabled;
        ManufacturingSetupRecordRef.Modify();
    end;

    local procedure SetWIPItem(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseLineRecordRef: RecordRef;
        WIPItemFieldRef: FieldRef;
    begin
        PurchaseLineRecordRef.GetTable(PurchaseLine);
        WIPItemFieldRef := PurchaseLineRecordRef.Field(12180);
        WIPItemFieldRef.Value := true;
        PurchaseLineRecordRef.Modify();
        PurchaseLineRecordRef.SetTable(PurchaseLine);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AcceptConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
