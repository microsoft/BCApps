// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 139786 "E-Doc. Item Charge Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;
        UnitCodeOneTok: Label 'C62', Locked = true;

    #region Automatic classification

    [Test]
    procedure ItemChargeAssignedToOneLineWithSameVATIsLineLevelAllowanceCharge()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An item charge assigned to exactly one invoice line with the same VAT category and rate is classified as a line level allowance/charge.
        Initialize();

        // [GIVEN] A posted sales invoice with one item line and an item charge that carries the item's VAT setup and is assigned to that line
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that maps item charges automatically
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as an invoice line allowance/charge on the assigned line
        Assert.AreEqual(Structure::"Line Allowance/Charge", Structure, 'Item charge assigned to a single line with matching VAT must be a line level allowance/charge.');
        Assert.AreEqual(ItemSalesInvoiceLine."Line No.", TargetSalesInvoiceLine."Line No.", 'The assigned invoice line must be returned as the target line.');
        Assert.AreEqual(SalesInvoiceHeader."No.", TargetSalesInvoiceLine."Document No.", 'The target line must belong to the exported invoice.');
    end;

    [Test]
    procedure ItemChargeOnShippedOrderIsLineLevelAllowanceCharge()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An item charge on a sales order is resolved through the posted shipment that the invoice line was invoiced from.
        Initialize();

        // [GIVEN] A sales order with an item line and an item charge assigned to it, shipped and invoiced
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostOrderWithChargeAssignedToItemLine(Customer, Item);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that maps item charges automatically
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as an invoice line allowance/charge on the assigned line
        Assert.AreEqual(Structure::"Line Allowance/Charge", Structure, 'An item charge invoiced from a shipment must be a line level allowance/charge.');
        Assert.AreEqual(ItemSalesInvoiceLine."Line No.", TargetSalesInvoiceLine."Line No.", 'The assigned invoice line must be returned as the target line.');
    end;

    [Test]
    procedure ItemChargeAssignedToOneLineWithDifferentVATRateIsDocumentLevel()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An item charge assigned to one invoice line but with a different VAT rate is not classified as a line level allowance/charge.
        Initialize();

        // [GIVEN] A posted sales invoice with one item line and an item charge with a deviating VAT rate assigned to that line
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo :=
            CreateAndPostInvoiceWithChargeAssignedToItemLines(
                Customer, Item, CreateVATProdPostingGroupWithRate(Customer, Item, GetVATRate(Customer, Item) + 5), 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that maps item charges automatically
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as a document level allowance/charge and no target line is returned
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'An item charge with a deviating VAT rate must not be a line level allowance/charge.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for a document level allowance/charge.');
    end;

    [Test]
    procedure ItemChargeAssignedToOneLineWithDifferentVATCalcTypeIsDocumentLevel()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An item charge assigned to one invoice line but with a different VAT category is not classified as a line level allowance/charge.
        Initialize();

        // [GIVEN] A zero rated item
        CreateCustomerAndItem(Customer, Item);
        Item.Validate("VAT Prod. Posting Group", CreateVATProdPostingGroupWithRate(Customer, Item, 0));
        Item.Modify(true);

        // [GIVEN] A posted sales invoice with that item line and a reverse charge VAT item charge assigned to that line
        InvoiceNo :=
            CreateAndPostInvoiceWithChargeAssignedToItemLines(
                Customer, Item, CreateReverseChargeVATProdPostingGroup(Customer, Item, 0), 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] Both lines carry the same VAT rate, so only the VAT category differs
        Assert.AreEqual(
            ItemSalesInvoiceLine."VAT %", ChargeSalesInvoiceLine."VAT %", 'The scenario requires an identical VAT rate on both lines.');
        Assert.AreNotEqual(
            ItemSalesInvoiceLine."VAT Calculation Type", ChargeSalesInvoiceLine."VAT Calculation Type",
            'The scenario requires a different VAT calculation type.');

        // [GIVEN] A service that maps item charges automatically
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as a document level allowance/charge
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'An item charge with a deviating VAT category must not be a line level allowance/charge.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for a document level allowance/charge.');
    end;

    [Test]
    procedure ItemChargeAssignedToTwoLinesIsDocumentLevel()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An item charge that is spread over more than one invoice line has no unambiguous line assignment and becomes a document level allowance/charge.
        Initialize();

        // [GIVEN] A posted sales invoice with two item lines and an item charge assigned to both of them
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 2);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that maps item charges automatically
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as a document level allowance/charge
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'An item charge assigned to several lines must be a document level allowance/charge.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for a document level allowance/charge.');
    end;

    [Test]
    procedure ItemChargeWithoutAssignmentOnInvoiceIsDocumentLevel()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An item charge that is not assigned to any line of the exported invoice becomes a document level allowance/charge.
        Initialize();

        // [GIVEN] A posted sales invoice that shipped an item
        CreateCustomerAndItem(Customer, Item);
        ShipmentNo := CreateAndPostShipmentOnly(Customer, Item);

        // [GIVEN] A second posted sales invoice with an item line and an item charge assigned to the earlier shipment
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToShipment(Customer, Item, ShipmentNo, true);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that maps item charges automatically
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as a document level allowance/charge
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'An item charge without an assignment on the invoice must be a document level allowance/charge.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for a document level allowance/charge.');
    end;

    [Test]
    procedure ItemChargeOnInvoiceWithoutOtherLinesIsInvoiceLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An item charge on an invoice that has no other line cannot become an allowance/charge, because the invoice would be left without any invoice line.
        Initialize();

        // [GIVEN] A posted sales invoice that shipped an item
        CreateCustomerAndItem(Customer, Item);
        ShipmentNo := CreateAndPostShipmentOnly(Customer, Item);

        // [GIVEN] A second posted sales invoice that only contains an item charge assigned to the earlier shipment
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToShipment(Customer, Item, ShipmentNo, false);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that maps item charges automatically
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge falls back to an invoice line
        Assert.AreEqual(Structure::"Line with Unit Code", Structure, 'An item charge on an invoice without other lines must fall back to an invoice line.');
    end;

    #endregion

    #region Forced mapping

    [Test]
    procedure ForcedDocumentLevelMappingOverridesAutomatic()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] Forcing document level mapping overrides the automatic classification.
        Initialize();

        // [GIVEN] A posted sales invoice where the item charge would automatically be a line level allowance/charge
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that forces document level allowance/charge
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as a document level allowance/charge
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'The forced document level mapping must win over the automatic classification.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for a document level allowance/charge.');
    end;

    [Test]
    procedure ForcedLineLevelMappingOverridesAutomatic()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] Forcing line level mapping overrides the automatic classification.
        Initialize();

        // [GIVEN] A posted sales invoice where the item charge would automatically be a document level allowance/charge
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 2);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that forces invoice line allowance/charge
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Line Allowance/Charge");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as an invoice line allowance/charge
        Assert.AreEqual(Structure::"Line Allowance/Charge", Structure, 'The forced line level mapping must win over the automatic classification.');
    end;

    [Test]
    procedure ForcedInvoiceLineMappingOverridesAutomatic()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] Forcing the invoice line mapping overrides the automatic classification.
        Initialize();

        // [GIVEN] A posted sales invoice where the item charge would automatically be a line level allowance/charge
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that forces an invoice line with a unit code
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is exported as a regular invoice line
        Assert.AreEqual(Structure::"Line with Unit Code", Structure, 'The forced invoice line mapping must win over the automatic classification.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for an invoice line.');
    end;

    [Test]
    procedure ForcedDocumentLevelMappingOnChargeOnlyInvoiceFallsBackToInvoiceLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] A forced document level mapping cannot turn the only line of an invoice into an allowance/charge, because the invoice would be left without any invoice line.
        Initialize();

        // [GIVEN] A posted sales invoice that shipped an item
        CreateCustomerAndItem(Customer, Item);
        ShipmentNo := CreateAndPostShipmentOnly(Customer, Item);

        // [GIVEN] A second posted sales invoice that only contains an item charge assigned to the earlier shipment
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToShipment(Customer, Item, ShipmentNo, false);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that forces document level allowance/charge
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge falls back to an invoice line
        Assert.AreEqual(Structure::"Line with Unit Code", Structure, 'A forced document level item charge on an invoice without other lines must fall back to an invoice line.');
    end;

    [Test]
    procedure ForcedLineLevelMappingOnChargeOnlyInvoiceFallsBackToInvoiceLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] A forced line level mapping cannot turn the only line of an invoice into an allowance/charge, because the invoice would be left without any invoice line.
        Initialize();

        // [GIVEN] A posted sales invoice that shipped an item
        CreateCustomerAndItem(Customer, Item);
        ShipmentNo := CreateAndPostShipmentOnly(Customer, Item);

        // [GIVEN] A second posted sales invoice that only contains an item charge assigned to the earlier shipment
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToShipment(Customer, Item, ShipmentNo, false);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] A service that forces invoice line allowance/charge
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Line Allowance/Charge");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge falls back to an invoice line
        Assert.AreEqual(Structure::"Line with Unit Code", Structure, 'A forced line level item charge on an invoice without other lines must fall back to an invoice line.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for an invoice line.');
    end;

    [Test]
    procedure ForcedDocumentLevelMappingOnChargeOnlyCrMemoFallsBackToCrMemoLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        ItemSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TargetSalesCrMemoLine: Record "Sales Cr.Memo Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        ShipmentNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [SCENARIO] A forced document level mapping cannot turn the only line of a credit memo into an allowance/charge, because the credit memo would be left without any credit memo line.
        Initialize();

        // [GIVEN] A posted sales invoice that shipped an item
        CreateCustomerAndItem(Customer, Item);
        ShipmentNo := CreateAndPostShipmentOnly(Customer, Item);

        // [GIVEN] A posted sales credit memo that only contains an item charge assigned to the earlier shipment
        CrMemoNo := CreateAndPostCrMemoWithChargeAssignedToShipment(Customer, Item, ShipmentNo);
        GetPostedCrMemoLines(CrMemoNo, SalesCrMemoHeader, ChargeSalesCrMemoLine, ItemSalesCrMemoLine);

        // [GIVEN] A service that forces document level allowance/charge
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesCrMemoHeader, ChargeSalesCrMemoLine, TargetSalesCrMemoLine);

        // [THEN] The charge falls back to a credit memo line
        Assert.AreEqual(Structure::"Line with Unit Code", Structure, 'A forced document level item charge on a credit memo without other lines must fall back to a credit memo line.');
    end;

    #endregion

    #region Per-item-charge override

    [Test]
    procedure OverriddenDocumentLevelMappingOverridesServiceSetting()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        MappingOverride: Enum "Item Charge Mapping Override";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] A document level mapping override on the item charge wins over the service setting.
        Initialize();

        // [GIVEN] A posted sales invoice where the item charge would automatically be a line level allowance/charge
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] The item charge overrides the mapping with a document level allowance/charge
        SetItemChargeMapping(ChargeSalesInvoiceLine."No.", MappingOverride::"Document Allowance/Charge");

        // [GIVEN] A service that forces an invoice line with a unit code
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as a document level allowance/charge
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'The item charge mapping override must win over the service setting.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for a document level allowance/charge.');
    end;

    [Test]
    procedure OverriddenLineLevelMappingOverridesServiceSetting()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        MappingOverride: Enum "Item Charge Mapping Override";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] A line level mapping override on the item charge wins over the service setting and returns the assigned line.
        Initialize();

        // [GIVEN] A posted sales invoice with an item charge assigned to a single item line
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] The item charge overrides the mapping with an invoice line allowance/charge
        SetItemChargeMapping(ChargeSalesInvoiceLine."No.", MappingOverride::"Line Allowance/Charge");

        // [GIVEN] A service that forces document level allowance/charge
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified as an invoice line allowance/charge on the assigned line
        Assert.AreEqual(Structure::"Line Allowance/Charge", Structure, 'The item charge mapping override must win over the service setting.');
        Assert.AreEqual(ItemSalesInvoiceLine."Line No.", TargetSalesInvoiceLine."Line No.", 'The assigned invoice line must be returned as the target line.');
    end;

    [Test]
    procedure OverriddenInvoiceLineMappingOverridesServiceSetting()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        MappingOverride: Enum "Item Charge Mapping Override";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An invoice line mapping override on the item charge wins over the service setting.
        Initialize();

        // [GIVEN] A posted sales invoice with an item charge assigned to a single item line
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] The item charge overrides the mapping with an invoice line with a unit code
        SetItemChargeMapping(ChargeSalesInvoiceLine."No.", MappingOverride::"Line with Unit Code");

        // [GIVEN] A service that forces invoice line allowance/charge
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Line Allowance/Charge");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is exported as a regular invoice line and no target line is returned
        Assert.AreEqual(Structure::"Line with Unit Code", Structure, 'The item charge mapping override must win over the service setting.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for an invoice line.');
    end;

    [Test]
    procedure OverriddenAutomaticMappingForcesAutomaticClassification()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        MappingOverride: Enum "Item Charge Mapping Override";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An Automatic override on the item charge forces the automatic classification even if the service forces a structure.
        Initialize();

        // [GIVEN] A posted sales invoice where the item charge would automatically be a line level allowance/charge
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] The item charge overrides the mapping with Automatic
        SetItemChargeMapping(ChargeSalesInvoiceLine."No.", MappingOverride::Automatic);

        // [GIVEN] A service that forces document level allowance/charge
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge is classified automatically as an invoice line allowance/charge on the assigned line
        Assert.AreEqual(Structure::"Line Allowance/Charge", Structure, 'The Automatic override must force the automatic classification over the forced service setting.');
        Assert.AreEqual(ItemSalesInvoiceLine."Line No.", TargetSalesInvoiceLine."Line No.", 'The assigned invoice line must be returned as the target line.');
    end;

    [Test]
    procedure UnsetOverrideFallsThroughToServiceSetting()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] An item charge without a mapping override follows the service setting.
        Initialize();

        // [GIVEN] A posted sales invoice where the item charge would automatically be a line level allowance/charge
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);

        // [GIVEN] The item charge has no mapping override
        ItemCharge.Get(ChargeSalesInvoiceLine."No.");
        Assert.AreEqual(ItemCharge."E-Invoice Mapping"::" ", ItemCharge."E-Invoice Mapping", 'The scenario requires an item charge without a mapping override.');

        // [GIVEN] A service that forces document level allowance/charge
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] The charge follows the service setting and is classified as a document level allowance/charge
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'An item charge without a mapping override must follow the service setting.');
        Assert.AreEqual(0, TargetSalesInvoiceLine."Line No.", 'No target line must be returned for a document level allowance/charge.');
    end;

    [Test]
    procedure PerChargeUnitCodeIsUsedForFallbackInvoiceLine()
    var
        ItemCharge: Record "Item Charge";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
    begin
        // [SCENARIO] A unit code set on the item charge replaces C62 on the fallback invoice line.
        Initialize();

        // [GIVEN] An item charge with the unit code HUR
        ItemCharge.Get(LibraryInventory.CreateItemChargeNo());
        ItemCharge."E-Invoice Unit Code" := 'HUR';
        ItemCharge.Modify(false);

        // [WHEN] The fallback unit code is resolved for the item charge
        // [THEN] The unit code of the item charge is returned
        Assert.AreEqual('HUR', EDocItemChargeMapping.GetFallbackUnitOfMeasureCode(ItemCharge."No."), 'The unit code of the item charge must replace the default unit code.');
    end;

    [Test]
    procedure FallbackUnitCodeIsC62WhenNoOverrideIsSet()
    var
        ItemCharge: Record "Item Charge";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
    begin
        // [SCENARIO] Without a unit code on the item charge the fallback invoice line uses C62.
        Initialize();

        // [GIVEN] An item charge without a unit code
        ItemCharge.Get(LibraryInventory.CreateItemChargeNo());
        ItemCharge.TestField("E-Invoice Unit Code", '');

        // [WHEN] The fallback unit code is resolved for the item charge
        // [THEN] C62 is returned
        Assert.AreEqual(UnitCodeOneTok, EDocItemChargeMapping.GetFallbackUnitOfMeasureCode(ItemCharge."No."), 'An item charge without a unit code must fall back to C62.');

        // [THEN] C62 is also returned for an unknown item charge
        Assert.AreEqual(UnitCodeOneTok, EDocItemChargeMapping.GetFallbackUnitOfMeasureCode('NONEXISTING'), 'An unknown item charge must fall back to C62.');
    end;

    [Test]
    procedure EInvoiceUnitCodeMustBeConfiguredAsInternationalStandardCode()
    var
        ItemCharge: Record "Item Charge";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [SCENARIO] An item charge accepts only unit codes configured as UNECERec20 international standard codes.
        Initialize();

        // [GIVEN] HUR is configured as the international standard code of a unit of measure
        if not UnitOfMeasure.Get('EDOCHOUR') then begin
            UnitOfMeasure.Code := 'EDOCHOUR';
            UnitOfMeasure."International Standard Code" := 'HUR';
            UnitOfMeasure.Insert();
        end;
        ItemCharge.Get(LibraryInventory.CreateItemChargeNo());

        // [WHEN] HUR is assigned to the item charge
        ItemCharge.Validate("E-Invoice Unit Code", 'HUR');

        // [THEN] The configured international standard code is accepted
        Assert.AreEqual('HUR', ItemCharge."E-Invoice Unit Code", 'A configured international standard code must be accepted.');

        // [WHEN] An unknown international standard code is assigned
        asserterror ItemCharge.Validate("E-Invoice Unit Code", 'INVALID');

        // [THEN] The value is rejected
        Assert.ExpectedError(ItemCharge.FieldCaption("E-Invoice Unit Code"));
    end;

    [Test]
    procedure ReasonTextAndReasonCodeRoundTripThroughApi()
    var
        ItemCharge: Record "Item Charge";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        ReasonCode: Code[10];
        ReasonText: Text[100];
    begin
        // [SCENARIO] The reason text and reason code of an item charge are exposed through the mapping API.
        Initialize();

        // [GIVEN] An item charge with a reason text and a reason code
        ItemCharge.Get(LibraryInventory.CreateItemChargeNo());
        ItemCharge."E-Invoice Reason Text" := 'Freight surcharge';
        ItemCharge."E-Invoice Reason Code" := 'FC';
        ItemCharge.Modify(false);

        // [WHEN] The reason of the item charge is resolved
        EDocItemChargeMapping.GetItemChargeReason(ItemCharge."No.", ReasonCode, ReasonText);

        // [THEN] The values of the item charge are returned
        Assert.AreEqual('Freight surcharge', ReasonText, 'The reason text of the item charge must be returned.');
        Assert.AreEqual('FC', ReasonCode, 'The reason code of the item charge must be returned.');

        // [WHEN] The reason of an unknown item charge is resolved
        EDocItemChargeMapping.GetItemChargeReason('NONEXISTING', ReasonCode, ReasonText);

        // [THEN] Empty values are returned
        Assert.AreEqual('', ReasonText, 'An unknown item charge must have an empty reason text.');
        Assert.AreEqual('', ReasonCode, 'An unknown item charge must have an empty reason code.');
    end;

    [Test]
    procedure SubscriberOverridesItemChargeOverride()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        EDocItemChargeSubscriber: Codeunit "E-Doc. Item Chrg. Subscriber";
        MappingOverride: Enum "Item Charge Mapping Override";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] A subscriber can still override the classification when the item charge carries a mapping override.
        Initialize();

        // [GIVEN] A posted sales invoice whose item charge overrides the mapping with an invoice line with a unit code
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);
        SetItemChargeMapping(ChargeSalesInvoiceLine."No.", MappingOverride::"Line with Unit Code");
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A subscriber that forces a document level allowance/charge
        EDocItemChargeSubscriber.SetStructure(Structure::"Document Allowance/Charge");
        BindSubscription(EDocItemChargeSubscriber);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);
        UnbindSubscription(EDocItemChargeSubscriber);

        // [THEN] The subscriber was called and its classification wins over the item charge mapping override
        Assert.IsTrue(EDocItemChargeSubscriber.WasInvoked(), 'The classification event must be raised.');
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'The subscriber must win over the item charge mapping override.');
    end;

    #endregion

    #region Extensibility and fallback

    [Test]
    procedure SubscriberOverridesResolvedStructure()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        EDocItemChargeSubscriber: Codeunit "E-Doc. Item Chrg. Subscriber";
        Structure: Enum "Item Charge E-Doc. Structure";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] A subscriber can override the resolved classification before the e-document is generated.
        Initialize();

        // [GIVEN] A posted sales invoice where the item charge would automatically be a line level allowance/charge
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A subscriber that forces a document level allowance/charge
        EDocItemChargeSubscriber.SetStructure(Structure::"Document Allowance/Charge");
        BindSubscription(EDocItemChargeSubscriber);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ChargeSalesInvoiceLine, TargetSalesInvoiceLine);
        UnbindSubscription(EDocItemChargeSubscriber);

        // [THEN] The subscriber was called and its classification is returned
        Assert.IsTrue(EDocItemChargeSubscriber.WasInvoked(), 'The classification event must be raised.');
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'The subscriber must be able to override the resolved classification.');
    end;

    [Test]
    procedure SubscriberOverridesResolvedCrMemoStructure()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        ItemSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TargetSalesCrMemoLine: Record "Sales Cr.Memo Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        EDocItemChargeSubscriber: Codeunit "E-Doc. Item Chrg. Subscriber";
        Structure: Enum "Item Charge E-Doc. Structure";
        CrMemoNo: Code[20];
    begin
        // [SCENARIO] A subscriber can override the resolved credit memo classification before the e-document is generated.
        Initialize();

        // [GIVEN] A posted sales credit memo where the item charge would automatically be a line level allowance/charge
        CreateCustomerAndItem(Customer, Item);
        CrMemoNo := CreateAndPostCrMemoWithChargeAssignedToItemLines(Customer, Item, 1);
        GetPostedCrMemoLines(CrMemoNo, SalesCrMemoHeader, ChargeSalesCrMemoLine, ItemSalesCrMemoLine);
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A subscriber that forces a document level allowance/charge
        EDocItemChargeSubscriber.SetStructure(Structure::"Document Allowance/Charge");
        BindSubscription(EDocItemChargeSubscriber);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesCrMemoHeader, ChargeSalesCrMemoLine, TargetSalesCrMemoLine);
        UnbindSubscription(EDocItemChargeSubscriber);

        // [THEN] The credit memo event was raised and the subscriber classification is returned
        Assert.IsTrue(EDocItemChargeSubscriber.WasInvoked(), 'The credit memo classification event must be raised.');
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'The subscriber must be able to override the resolved credit memo classification.');
    end;

    [Test]
    procedure FallbackInvoiceLineUsesQuantityOneAndUnitCodeC62()
    var
        ItemCharge: Record "Item Charge";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
    begin
        // [SCENARIO] The invoice line fallback carries quantity 1 and the unit code C62, so that neither BR-23 nor BR-CL-23 is violated.
        Initialize();

        // [GIVEN] An item charge without a unit code override
        ItemCharge.Get(LibraryInventory.CreateItemChargeNo());
        ItemCharge.TestField("E-Invoice Unit Code", '');

        // [WHEN] The fallback invoice line values are read
        // [THEN] The quantity is 1 and the unit code is C62
        Assert.AreEqual(1, EDocItemChargeMapping.GetFallbackQuantity(), 'The item charge fallback invoice line must have quantity 1.');
        Assert.AreEqual(UnitCodeOneTok, EDocItemChargeMapping.GetFallbackUnitOfMeasureCode(ItemCharge."No."), 'The item charge fallback invoice line must use the unit code C62.');
    end;

    [Test]
    procedure ClassifyingNonItemChargeLineFails()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TargetSalesInvoiceLine: Record "Sales Invoice Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] Only item charge lines can be classified.
        Initialize();

        // [GIVEN] A posted sales invoice with an item line and an item charge line
        CreateCustomerAndItem(Customer, Item);
        InvoiceNo := CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer, Item, Item."VAT Prod. Posting Group", 1);
        GetPostedLines(InvoiceNo, SalesInvoiceHeader, ChargeSalesInvoiceLine, ItemSalesInvoiceLine);
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item line is classified
        asserterror EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesInvoiceHeader, ItemSalesInvoiceLine, TargetSalesInvoiceLine);

        // [THEN] A TestField error for the line type is raised
        Assert.ExpectedTestFieldError(ItemSalesInvoiceLine.FieldCaption(Type), Format(ItemSalesInvoiceLine.Type::"Charge (Item)"));
    end;

    [Test]
    procedure CrMemoChargeAssignedToSingleLineIsLineLevelAllowanceCharge()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        ItemSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TargetSalesCrMemoLine: Record "Sales Cr.Memo Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        CrMemoNo: Code[20];
    begin
        // [SCENARIO] An item charge of a posted sales credit memo that is assigned to a single credit memo line with the same VAT becomes a line level allowance/charge, which proves that the value entry recovery works for credit memos too.
        Initialize();

        // [GIVEN] A posted sales credit memo with one item line and an item charge assigned to it
        CreateCustomerAndItem(Customer, Item);
        CrMemoNo := CreateAndPostCrMemoWithChargeAssignedToItemLines(Customer, Item, 1);
        GetPostedCrMemoLines(CrMemoNo, SalesCrMemoHeader, ChargeSalesCrMemoLine, ItemSalesCrMemoLine);
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesCrMemoHeader, ChargeSalesCrMemoLine, TargetSalesCrMemoLine);

        // [THEN] The charge is a line level allowance/charge of the line it is assigned to
        Assert.AreEqual(Structure::"Line Allowance/Charge", Structure, 'A credit memo charge assigned to a single line with the same VAT must become a line level allowance/charge.');
        Assert.AreEqual(ItemSalesCrMemoLine."Line No.", TargetSalesCrMemoLine."Line No.", 'The target line must be the credit memo line the charge is assigned to.');
    end;

    [Test]
    procedure CrMemoChargeAssignedToTwoLinesIsDocumentLevelAllowanceCharge()
    var
        Customer: Record Customer;
        Item: Record Item;
        EDocumentService: Record "E-Document Service";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        ItemSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TargetSalesCrMemoLine: Record "Sales Cr.Memo Line";
        EDocItemChargeMapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        CrMemoNo: Code[20];
    begin
        // [SCENARIO] An item charge of a posted sales credit memo that is assigned to more than one credit memo line becomes a document level allowance/charge.
        Initialize();

        // [GIVEN] A posted sales credit memo with two item lines and an item charge assigned to both of them
        CreateCustomerAndItem(Customer, Item);
        CrMemoNo := CreateAndPostCrMemoWithChargeAssignedToItemLines(Customer, Item, 2);
        GetPostedCrMemoLines(CrMemoNo, SalesCrMemoHeader, ChargeSalesCrMemoLine, ItemSalesCrMemoLine);
        InitService(EDocumentService, EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [WHEN] The item charge line is classified
        Structure := EDocItemChargeMapping.GetItemChargeStructure(EDocumentService, SalesCrMemoHeader, ChargeSalesCrMemoLine, TargetSalesCrMemoLine);

        // [THEN] The charge is a document level allowance/charge without a target line
        Assert.AreEqual(Structure::"Document Allowance/Charge", Structure, 'A credit memo charge assigned to two lines must become a document level allowance/charge.');
        Assert.AreEqual(0, TargetSalesCrMemoLine."Line No.", 'No target line must be returned for a document level allowance/charge.');
    end;

    #endregion

    #region Helpers

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if IsInitialized then
            exit;

        LibrarySales.SetStockoutWarning(false);
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetCalcInvDiscount(false);
        InventorySetup.Get();
        InventorySetup.Validate("Prevent Negative Inventory", false);
        InventorySetup.Modify(true);

        IsInitialized := true;
    end;

    local procedure InitService(var EDocumentService: Record "E-Document Service"; ItemChargeMapping: Enum "Item Charge E-Invoice Mapping")
    begin
        EDocumentService.Init();
        EDocumentService.Code := 'ITEMCHARGE';
        EDocumentService."Item Charge E-Invoice Mapping" := ItemChargeMapping;
    end;

    local procedure CreateCustomerAndItem(var Customer: Record Customer; var Item: Record Item)
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
    end;

    local procedure GetVATRate(Customer: Record Customer; Item: Record Item): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        exit(VATPostingSetup."VAT %");
    end;

    local procedure CreateVATProdPostingGroupWithRate(Customer: Record Customer; Item: Record Item; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, Customer, Item, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateReverseChargeVATProdPostingGroup(Customer: Record Customer; Item: Record Item; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, Customer, Item, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", VATRate);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; Customer: Record Customer; Item: Record Item; VATCalculationType: Enum "Tax Calculation Type"; VATRate: Decimal)
    var
        ItemVATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        ItemVATPostingSetup.Get(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup."VAT Identifier" := VATProductPostingGroup.Code;
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("VAT %", VATRate);
        VATPostingSetup.Validate("Sales VAT Account", ItemVATPostingSetup."Sales VAT Account");
        VATPostingSetup.Validate("Purchase VAT Account", ItemVATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", ItemVATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Modify(true);
    end;

    local procedure SetItemChargeMapping(ItemChargeNo: Code[20]; MappingOverride: Enum "Item Charge Mapping Override")
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Get(ItemChargeNo);
        ItemCharge."E-Invoice Mapping" := MappingOverride;
        ItemCharge.Modify(false);
    end;

    local procedure CreateItemChargeNo(Item: Record Item; VATProdPostingGroupCode: Code[20]): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Get(LibraryInventory.CreateItemChargeNo());
        ItemCharge.Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        ItemCharge.Modify(true);
        exit(ItemCharge."No.");
    end;

    local procedure CreateAndPostShipmentOnly(Customer: Record Customer; Item: Record Item): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateItemLine(SalesLine, SalesHeader, Item);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure CreateAndPostOrderWithChargeAssignedToItemLine(Customer: Record Customer; Item: Record Item): Code[20]
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader: Record "Sales Header";
        ChargeSalesLine: Record "Sales Line";
        ItemSalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateItemLine(ItemSalesLine, SalesHeader, Item);

        LibrarySales.CreateSalesLine(
            ChargeSalesLine, SalesHeader, ChargeSalesLine.Type::"Charge (Item)", CreateItemChargeNo(Item, Item."VAT Prod. Posting Group"), 1);
        ChargeSalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 50, 2));
        ChargeSalesLine.Modify(true);

        LibraryInventory.CreateItemChargeAssignment(
            ItemChargeAssignmentSales, ChargeSalesLine, SalesHeader."Document Type", SalesHeader."No.", ItemSalesLine."Line No.", Item."No.");
        ItemChargeAssignmentSales.Validate("Qty. to Assign", 1);
        ItemChargeAssignmentSales.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostInvoiceWithChargeAssignedToItemLines(Customer: Record Customer; Item: Record Item; VATProdPostingGroupCode: Code[20]; NoOfItemLines: Integer): Code[20]
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader: Record "Sales Header";
        ChargeSalesLine: Record "Sales Line";
        ItemSalesLine: Record "Sales Line";
        ItemLineNo: array[2] of Integer;
        Index: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        for Index := 1 to NoOfItemLines do begin
            CreateItemLine(ItemSalesLine, SalesHeader, Item);
            ItemLineNo[Index] := ItemSalesLine."Line No.";
        end;

        LibrarySales.CreateSalesLine(
            ChargeSalesLine, SalesHeader, ChargeSalesLine.Type::"Charge (Item)", CreateItemChargeNo(Item, VATProdPostingGroupCode), NoOfItemLines);
        ChargeSalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 50, 2));
        ChargeSalesLine.Modify(true);

        for Index := 1 to NoOfItemLines do begin
            LibraryInventory.CreateItemChargeAssignment(
                ItemChargeAssignmentSales, ChargeSalesLine, SalesHeader."Document Type", SalesHeader."No.", ItemLineNo[Index], Item."No.");
            ItemChargeAssignmentSales.Validate("Qty. to Assign", 1);
            ItemChargeAssignmentSales.Modify(true);
        end;

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostInvoiceWithChargeAssignedToShipment(Customer: Record Customer; Item: Record Item; ShipmentNo: Code[20]; WithItemLine: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ChargeSalesLine: Record "Sales Line";
        ItemSalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        if WithItemLine then
            CreateItemLine(ItemSalesLine, SalesHeader, Item);

        LibrarySales.CreateSalesLine(
            ChargeSalesLine, SalesHeader, ChargeSalesLine.Type::"Charge (Item)", CreateItemChargeNo(Item, Item."VAT Prod. Posting Group"), 1);
        ChargeSalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 50, 2));
        ChargeSalesLine.Modify(true);

        AssignItemChargeToShipment(ChargeSalesLine, ShipmentNo);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure AssignItemChargeToShipment(ChargeSalesLine: Record "Sales Line"; ShipmentNo: Code[20])
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        ItemChargeAssignmentSales.Init();
        ItemChargeAssignmentSales.Validate("Document Type", ChargeSalesLine."Document Type");
        ItemChargeAssignmentSales.Validate("Document No.", ChargeSalesLine."Document No.");
        ItemChargeAssignmentSales.Validate("Document Line No.", ChargeSalesLine."Line No.");
        ItemChargeAssignmentSales.Validate("Item Charge No.", ChargeSalesLine."No.");
        ItemChargeAssignmentSales.Validate("Unit Cost", ChargeSalesLine."Unit Price");
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesShipmentLine.FindFirst();
        ItemChargeAssgntSales.CreateShptChargeAssgnt(SalesShipmentLine, ItemChargeAssignmentSales);

        ItemChargeAssignmentSales.SetRange("Document Type", ChargeSalesLine."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", ChargeSalesLine."Document No.");
        ItemChargeAssignmentSales.SetRange("Document Line No.", ChargeSalesLine."Line No.");
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.Validate("Qty. to Assign", ChargeSalesLine.Quantity);
        ItemChargeAssignmentSales.Modify(true);
    end;

    local procedure CreateItemLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Item: Record Item)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
    end;

    local procedure GetPostedLines(InvoiceNo: Code[20]; var SalesInvoiceHeader: Record "Sales Invoice Header"; var ChargeSalesInvoiceLine: Record "Sales Invoice Line"; var ItemSalesInvoiceLine: Record "Sales Invoice Line")
    begin
        SalesInvoiceHeader.Get(InvoiceNo);

        ChargeSalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        ChargeSalesInvoiceLine.SetRange(Type, ChargeSalesInvoiceLine.Type::"Charge (Item)");
        ChargeSalesInvoiceLine.FindFirst();

        Clear(ItemSalesInvoiceLine);
        ItemSalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        ItemSalesInvoiceLine.SetRange(Type, ItemSalesInvoiceLine.Type::Item);
        if ItemSalesInvoiceLine.FindFirst() then;
    end;

    local procedure CreateAndPostCrMemoWithChargeAssignedToItemLines(Customer: Record Customer; Item: Record Item; NoOfItemLines: Integer): Code[20]
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader: Record "Sales Header";
        ChargeSalesLine: Record "Sales Line";
        ItemSalesLine: Record "Sales Line";
        ItemLineNo: array[2] of Integer;
        Index: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        for Index := 1 to NoOfItemLines do begin
            CreateItemLine(ItemSalesLine, SalesHeader, Item);
            ItemLineNo[Index] := ItemSalesLine."Line No.";
        end;

        LibrarySales.CreateSalesLine(
            ChargeSalesLine, SalesHeader, ChargeSalesLine.Type::"Charge (Item)", CreateItemChargeNo(Item, Item."VAT Prod. Posting Group"), NoOfItemLines);
        ChargeSalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 50, 2));
        ChargeSalesLine.Modify(true);

        for Index := 1 to NoOfItemLines do begin
            LibraryInventory.CreateItemChargeAssignment(
                ItemChargeAssignmentSales, ChargeSalesLine, SalesHeader."Document Type", SalesHeader."No.", ItemLineNo[Index], Item."No.");
            ItemChargeAssignmentSales.Validate("Qty. to Assign", 1);
            ItemChargeAssignmentSales.Modify(true);
        end;

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostCrMemoWithChargeAssignedToShipment(Customer: Record Customer; Item: Record Item; ShipmentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ChargeSalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        LibrarySales.CreateSalesLine(
            ChargeSalesLine, SalesHeader, ChargeSalesLine.Type::"Charge (Item)", CreateItemChargeNo(Item, Item."VAT Prod. Posting Group"), 1);
        ChargeSalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 50, 2));
        ChargeSalesLine.Modify(true);

        AssignItemChargeToShipment(ChargeSalesLine, ShipmentNo);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure GetPostedCrMemoLines(CrMemoNo: Code[20]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line"; var ItemSalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        SalesCrMemoHeader.Get(CrMemoNo);

        ChargeSalesCrMemoLine.SetRange("Document No.", CrMemoNo);
        ChargeSalesCrMemoLine.SetRange(Type, ChargeSalesCrMemoLine.Type::"Charge (Item)");
        ChargeSalesCrMemoLine.FindFirst();

        Clear(ItemSalesCrMemoLine);
        ItemSalesCrMemoLine.SetRange("Document No.", CrMemoNo);
        ItemSalesCrMemoLine.SetRange(Type, ItemSalesCrMemoLine.Type::Item);
        if ItemSalesCrMemoLine.FindFirst() then;
    end;

    #endregion
}
