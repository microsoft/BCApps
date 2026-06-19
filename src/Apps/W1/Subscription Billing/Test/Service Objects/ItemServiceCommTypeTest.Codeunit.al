namespace Microsoft.SubscriptionBilling;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 139885 "Item Service Comm. Type Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;

    trigger OnRun()
    begin
        ContractTestLibrary.EnableNewPricingExperience();
    end;

    var
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ContractTestLibrary: Codeunit "Contract Test Library";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AssertThat: Codeunit Assert;
        ServiceCommitmentItemErr: Label 'Items that are marked as Subscription Item may not be used here. Please choose another item.';
        InvoicingItemErr: Label 'Items that are marked as Invoicing Item may not be used here. Please choose another item.';

    #region Tests

    [Test]
    procedure CheckBillingItemOption()
    begin
        Initialize();
        ContractTestLibrary.CreateInventoryItem(Item);
        Commit(); // retain data after asserterror
        asserterror Item.Validate("Subscription Option", Enum::"Item Service Commitment Type"::"Invoicing Item");
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(false);
        Item.Validate("Subscription Option", Enum::"Item Service Commitment Type"::"Invoicing Item");
        asserterror Item.Validate(Type, Item.Type::Inventory);
    end;

    [Test]
    procedure CheckServiceCommitmentItemOption()
    begin
        Initialize();
        ContractTestLibrary.CreateInventoryItem(Item);
        Commit(); // retain testing data
        asserterror Item.Validate("Subscription Option", Enum::"Item Service Commitment Type"::"Service Commitment Item");
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(false);
        Item.Validate("Subscription Option", Enum::"Item Service Commitment Type"::"Service Commitment Item");
        Item.TestField("Allow Invoice Disc.", false);
        Commit(); // retain testing data
        asserterror Item.Validate(Type, Item.Type::Inventory);
        asserterror Item.Validate("Allow Invoice Disc.", true);
        Item.Validate("Subscription Option", Enum::"Item Service Commitment Type"::"Sales with Service Commitment");
        Item.TestField("Allow Invoice Disc.", true);
    end;

    [Test]
    procedure ExpectErrorPostingServiceCommitmentItemOnPurchaseInvoice()
    begin
        Initialize();
        // [GIVEN] Create Purchase Return Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        Commit(); // retain data after asserterror
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Enum::"Purchase Line Type"::Item, Item."No.", 1);

        // [WHEN] Try to post Purchase Line with Item which is Subscription Item
        // [THEN] expect error is thrown
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    procedure ExpectErrorUsingBillingItemOnBOM()
    begin
        Initialize();
        // [GIVEN] Create Invoicing Item
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Invoicing Item");
        // [WHEN] Try to enter BOM Component with Item which is Invoicing Item
        BOMComponent.Type := BOMComponent.Type::Item;
        asserterror BOMComponent.Validate("No.", Item."No.");
        // [THEN] expect error is thrown
        AssertThat.ExpectedError(InvoicingItemErr);
    end;

    [Test]
    procedure ExpectErrorUsingServiceCommitmentItemOnSalesInvoice()
    begin
        Initialize();
        // [GIVEN] Create Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        // [WHEN] Try to enter Sales Line with Item which is Subscription Item
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        asserterror LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, Item."No.", 1);
        // [THEN] expect error is thrown
        AssertThat.ExpectedError(ServiceCommitmentItemErr);
    end;

    [Test]
    procedure ExpectErrorUsingServiceCommitmentItemAndAllowInvoiceDiscountOnSalesLine()
    begin
        Initialize();
        // [GIVEN] Create Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        // [WHEN] Try to set Allow Invoice Discount on Sales Line with Item which is Subscription Item
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, Item."No.", 1);
        SalesLine.TestField("Allow Invoice Disc.", false);
        asserterror SalesLine.Validate("Allow Invoice Disc.", true);
    end;

    [Test]
    procedure ExpectErrorUsingServiceCommitmentItemAndAllowInvoiceDiscountOnSalesPrice()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Create Subscription Item
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        // [WHEN] Try to set Allow Invoice Discount on Sales Price with Item which is Subscription Item
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        PriceListHeader.Status := "Price Status"::Active;
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader."Currency Code" := '';
        PriceListHeader.Modify(true);

        LibraryPriceCalculation.CreatePriceListLine(PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine.TestField("Allow Invoice Disc.", false);
        // [THEN] expect error is thrown
        asserterror PriceListLine.Validate("Allow Invoice Disc.", true);
    end;

    [Test]
    procedure ExpectErrorUsingInvoicingItemOnPurchaseOrder()
    begin
        ClearAll();
        // [GIVEN] Create Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Commit(); // retain data after asserterror
        // [WHEN] Try to enter Purchase Line with Item which Invoicing Item
        // [THEN] expect error is thrown
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Invoicing Item");
        asserterror LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Enum::"Purchase Line Type"::Item, Item."No.", 1);
    end;

    [Test]
    procedure ExpectErrorUsingServiceCommitmentItemAndBillingItemOnSalesReturnOrder()
    begin
        Initialize();
        // [GIVEN] Create Sales Return Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        Commit(); // retain data after asserterror
        // [WHEN] Try to enter Sales Line with Item which is Subscription Item or Invoicing Item
        // [THEN] expect error is thrown
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        asserterror LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, Item."No.", 1);
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Invoicing Item");
        asserterror LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, Item."No.", 1);
    end;

    [Test]
    procedure ExpectErrorWhenSubscriptionOptionIsChangedOnItemWithExistingSalesDocuments()
    var
        InitialServiceCommitmentType: Enum "Item Service Commitment Type";
    begin
        // Test for each service commitment type except Invoicing items which have different behavior
        foreach InitialServiceCommitmentType in Enum::"Item Service Commitment Type".Ordinals() do begin
            if InitialServiceCommitmentType = Enum::"Item Service Commitment Type"::"Invoicing Item" then
                continue;
            ClearAll();

            // [GIVEN] Item with specific Subscription Option
            ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, InitialServiceCommitmentType);
            // [GIVEN] Open sales order with the item
            CreateSalesDocumentWithItem();
            Commit(); // retain test data

            // [WHEN] Attempting to change the Subscription Option
            // [THEN] Error is thrown pointing to the open Sales Line
            TestSubscriptionOptionChangeExpectsError(SalesLine.TableCaption());

            // [GIVEN] Posted sales document
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
            Commit(); // retain test data after posting

            // [WHEN] Attempting to change the Subscription Option
            // [THEN] Error is thrown pointing to the Item Ledger Entry
            TestSubscriptionOptionChangeExpectsError(ItemLedgerEntry.TableCaption());
        end;
    end;

    [Test]
    procedure ExpectErrorWhenSubscriptionOptionIsChangedOnItemWithExistingPurchaseDocuments()
    var
        InitialServiceCommitmentType: Enum "Item Service Commitment Type";
    begin
        // Test for each service commitment type except Invoicing items which have different behavior
        foreach InitialServiceCommitmentType in Enum::"Item Service Commitment Type".Ordinals() do begin
            if InitialServiceCommitmentType = Enum::"Item Service Commitment Type"::"Invoicing Item" then
                continue;
            ClearAll();

            // [GIVEN] Item with specific Subscription Option
            ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, InitialServiceCommitmentType);
            // [GIVEN] Open purchase order with the item
            CreatePurchaseDocumentWithItem();
            Commit(); // retain test data

            // [WHEN] Attempting to change the Subscription Option
            // [THEN] Error is thrown pointing to the open Purchase Line
            TestSubscriptionOptionChangeExpectsError(PurchaseLine.TableCaption());

            // [GIVEN] Posted purchase document
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
            Commit(); // retain test data after posting

            // [WHEN] Attempting to change the Subscription Option
            // [THEN] Error is thrown pointing to the Item Ledger Entry
            TestSubscriptionOptionChangeExpectsError(ItemLedgerEntry.TableCaption());
        end;
    end;

    #endregion Tests

    #region Helpers

    local procedure CreateSalesDocumentWithItem()
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithItem()
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Enum::"Purchase Line Type"::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(50, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure TestSubscriptionOptionChangeExpectsError(ExpectedDocumentTableCaption: Text)
    var
        CurrentItem: Record Item;
        ServiceCommitmentType: Enum "Item Service Commitment Type";
    begin
        CurrentItem.Get(Item."No.");
        foreach ServiceCommitmentType in Enum::"Item Service Commitment Type".Ordinals() do
            if ServiceCommitmentType <> CurrentItem."Subscription Option" then begin
                asserterror CurrentItem.Validate("Subscription Option", ServiceCommitmentType);
                AssertThat.ExpectedError(StrSubstNo(CurrentItem.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CurrentItem.FieldCaption("Subscription Option"), CurrentItem.TableCaption(), CurrentItem."No.", ExpectedDocumentTableCaption));
            end;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Item Service Comm. Type Test");
        ClearAll();
    end;

    #endregion Helpers
}
