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
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        Initialized: Boolean;
        OverReceiptFeatureIsEnabled: Boolean;
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
    [Scope('OnPrem')]
    procedure CanReopenFullyReceivedWIPPurchaseLineWhileLegacySubcontractingEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        // [SCENARIO 649448] The compatibility guard does not restrict WIP lines while Legacy Subcontracting is enabled
        Initialize();
        SetLegacySubcontracting(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        SetWIPItem(PurchaseLine);
        PurchaseLine."Quantity Received" := PurchaseLine.Quantity;
        PurchaseLine."Outstanding Quantity" := 0;
        PurchaseLine.Modify();

        PurchaseLine.Validate(Quantity, PurchaseLine.Quantity + 1);

        Assert.AreEqual(2, PurchaseLine.Quantity, 'The legacy-enabled purchase line should remain editable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReopenFullyReceivedNegativeWIPPurchaseLineAfterDisabling()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        // [SCENARIO 649448] Negative completed WIP quantities cannot become outstanding after disabling Legacy Subcontracting
        Initialize();
        SetLegacySubcontracting(false);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", -1);
        SetWIPItem(PurchaseLine);
        PurchaseLine."Quantity Received" := PurchaseLine.Quantity;
        PurchaseLine."Outstanding Quantity" := 0;
        PurchaseLine.Modify();

        asserterror PurchaseLine.Validate(Quantity, -2);

        Assert.ExpectedError(ReopenLegacyWIPPurchaseLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReopenFullyReceivedWIPPurchaseLineWithOverReceiptAfterDisabling()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        LegacyWIPPurchaseGuardTest: Codeunit "Legacy WIP Purchase Guard Test";
    begin
        // [SCENARIO 649448] Over-receipt cannot reopen a retained fully received WIP purchase line after disabling Legacy Subcontracting
        Initialize();

        // [GIVEN] A released retained WIP purchase order item line is fully received and over-receipt is enabled
        SetLegacySubcontracting(false);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        SetWIPItem(PurchaseLine);
        PurchaseLine.Validate("Over-Receipt Code", CreateOverReceiptCode());
        PurchaseLine."Quantity Received" := PurchaseLine.Quantity;
        PurchaseLine."Outstanding Quantity" := 0;
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LegacyWIPPurchaseGuardTest.SetOverReceiptFeatureEnabled(true);
        BindSubscription(LegacyWIPPurchaseGuardTest);

        // [WHEN] Over-receipt quantity is entered
        asserterror PurchaseLine.Validate("Over-Receipt Quantity", 1);

        // [THEN] The nested quantity validation cannot reopen the retained legacy WIP purchase line
        Assert.ExpectedError(ReopenLegacyWIPPurchaseLineErr);
        UnbindSubscription(LegacyWIPPurchaseGuardTest);
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

    [Test]
    [HandlerFunctions('AcceptConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure CanUndoReceiptForNonWIPPurchaseLineAfterDisabling()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        // [SCENARIO 649448] Receipt undo remains available for ordinary purchase lines after disabling Legacy Subcontracting
        Initialize();
        SetLegacySubcontracting(false);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        PurchRcptLine.FindFirst();
        Assert.IsTrue(PurchRcptLine.Correction, 'The ordinary purchase receipt line should be reversed.');
    end;

    [Test]
    [HandlerFunctions('AcceptConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure CanUndoSelectedOrdinaryLineWhenReceiptAlsoContainsWIPAfterDisabling()
    var
        PurchaseHeader: Record "Purchase Header";
        WIPPurchaseLine: Record "Purchase Line";
        OrdinaryPurchaseLine: Record "Purchase Line";
        WIPPurchRcptLine: Record "Purch. Rcpt. Line";
        OrdinaryPurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        WIPItem: Record Item;
        OrdinaryItem: Record Item;
    begin
        // [SCENARIO 649448] An unselected completed WIP line does not block undoing an ordinary line from the same receipt
        Initialize();
        SetLegacySubcontracting(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(WIPItem);
        LibraryInventory.CreateItem(OrdinaryItem);
        LibraryPurchase.CreatePurchaseLine(WIPPurchaseLine, PurchaseHeader, WIPPurchaseLine.Type::Item, WIPItem."No.", 1);
        SetWIPItem(WIPPurchaseLine);
        LibraryPurchase.CreatePurchaseLine(OrdinaryPurchaseLine, PurchaseHeader, OrdinaryPurchaseLine.Type::Item, OrdinaryItem."No.", 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SetLegacySubcontracting(false);

        OrdinaryPurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        OrdinaryPurchRcptLine.SetRange("Order Line No.", OrdinaryPurchaseLine."Line No.");
        OrdinaryPurchRcptLine.FindFirst();
        Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", OrdinaryPurchRcptLine);

        OrdinaryPurchRcptLine.FindFirst();
        Assert.IsTrue(OrdinaryPurchRcptLine.Correction, 'The selected ordinary receipt line should be reversed.');
        WIPPurchRcptLine.Get(OrdinaryPurchRcptLine."Document No.", WIPPurchaseLine."Line No.");
        Assert.IsFalse(WIPPurchRcptLine.Correction, 'The unselected WIP receipt line should remain unchanged.');
    end;

    [Test]
    [HandlerFunctions('AcceptConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure CannotUndoMixedReceiptContainingWIPPurchaseLineAfterDisabling()
    var
        PurchaseHeader: Record "Purchase Header";
        WIPPurchaseLine: Record "Purchase Line";
        OrdinaryPurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        WIPItem: Record Item;
        OrdinaryItem: Record Item;
    begin
        // [SCENARIO 649448] A mixed receipt selection is not partially reversed when it contains retained WIP
        Initialize();
        SetLegacySubcontracting(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(WIPItem);
        LibraryInventory.CreateItem(OrdinaryItem);
        LibraryPurchase.CreatePurchaseLine(WIPPurchaseLine, PurchaseHeader, WIPPurchaseLine.Type::Item, WIPItem."No.", 1);
        SetWIPItem(WIPPurchaseLine);
        LibraryPurchase.CreatePurchaseLine(OrdinaryPurchaseLine, PurchaseHeader, OrdinaryPurchaseLine.Type::Item, OrdinaryItem."No.", 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SetLegacySubcontracting(false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.FindFirst();
        asserterror Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        Assert.ExpectedError(UndoLegacyWIPPurchaseReceiptErr);
        PurchRcptLine.SetRange(Correction, true);
        Assert.RecordIsEmpty(PurchRcptLine);
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

    local procedure CreateOverReceiptCode(): Code[20]
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        OverReceiptCode.Init();
        OverReceiptCode.Code := LibraryUtility.GenerateRandomCode20(OverReceiptCode.FieldNo(Code), Database::"Over-Receipt Code");
        OverReceiptCode.Description := OverReceiptCode.Code;
        OverReceiptCode."Over-Receipt Tolerance %" := 100;
        OverReceiptCode.Insert();
        exit(OverReceiptCode.Code);
    end;

    procedure SetOverReceiptFeatureEnabled(Enabled: Boolean)
    begin
        OverReceiptFeatureIsEnabled := Enabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Over-Receipt Mgt.", 'OnIsOverReceiptAllowed', '', false, false)]
    local procedure SetOverReceiptAllowed(var OverReceiptAllowed: Boolean)
    begin
        OverReceiptAllowed := OverReceiptFeatureIsEnabled;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AcceptConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
