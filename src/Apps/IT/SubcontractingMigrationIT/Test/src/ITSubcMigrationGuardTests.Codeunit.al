#if not CLEAN28
namespace Microsoft.Manufacturing.Subcontracting.Migration.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting.Migration;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;

codeunit 149957 "IT Subc. Migration Guard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        Initialized: Boolean;
        PurchaseReceiptNo: Code[20];
        PurchaseReceiptLineNo: Integer;
        OpenWIPPurchaseOrdersExistErr: Label 'There are still open purchase orders with WIP Items. All purchase orders with WIP Items must be completed before disabling Legacy Subcontracting.';

    [Test]
    [HandlerFunctions('UndoReceiptAndConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure StartDisableLegacySubcontracting_RechecksOpenWIPAfterConfirmation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        Item: Record Item;
#pragma warning disable AL0432
        ITSubcMigration: Codeunit "IT Subc. Migration";
#pragma warning restore AL0432
    begin
        // [SCENARIO 649448] Migration rejects a WIP line reopened by receipt undo during confirmation
        Initialize();

        // [GIVEN] A fully received legacy WIP purchase line passes the initial precheck
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
#pragma warning disable AL0432
        PurchaseLine."WIP Item" := true;
#pragma warning restore AL0432
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
        PurchaseReceiptNo := PurchRcptLine."Document No.";
        PurchaseReceiptLineNo := PurchRcptLine."Line No.";

        // [WHEN] The receipt is undone while the migration confirmation is open
        asserterror ITSubcMigration.StartDisableLegacySubcontracting(true);

        // [THEN] The post-lock precheck detects the newly open WIP line and stops migration
        Assert.ExpectedError(OpenWIPPurchaseOrdersExistErr);
    end;

    local procedure Initialize()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IT Subc. Migration Guard Tests");
        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IT Subc. Migration Guard Tests");
        Initialized := true;
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;
#pragma warning disable AL0432
        ManufacturingSetup."Legacy Subcontracting" := true;
#pragma warning restore AL0432
        ManufacturingSetup.Modify();
        LibraryApplicationArea.EnablePremiumSetup();
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IT Subc. Migration Guard Tests");
    end;

    [ConfirmHandler]
    procedure UndoReceiptAndConfirmHandler(Question: Text; var Reply: Boolean)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        PurchRcptLine.Get(PurchaseReceiptNo, PurchaseReceiptLineNo);
        PurchRcptLine.SetRecFilter();
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
        Reply := true;
    end;
}
#endif
