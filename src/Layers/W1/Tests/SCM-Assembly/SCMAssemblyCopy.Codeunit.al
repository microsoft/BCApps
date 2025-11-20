// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Document;
using System.Environment.Configuration;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.BOM;
using Microsoft.Sales.Setup;
using Microsoft.Assembly.Setup;
using Microsoft.Inventory.Journal;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.History;
using Microsoft.Assembly.History;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Ledger;

codeunit 137927 "SCM Assembly Copy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Copy Document] [SCM]
    end;

    var
        TempAsmLine: Record "Assembly Line" temporary;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        AssemblyItemNo: array[4] of Code[20];
        SellToCustomerNo: Code[20];
        ResourceNo: Code[20];
        SalesShipmentNo: Code[20];
        SalesInvoiceNo: Code[20];
        UsedVariantCode: array[4] of Code[10];
        UsedLocationCode: Code[10];
        AssemblyTemplate: Code[10];
        AssemblyBatch: Code[10];
        NoSeriesName: Code[10];
        OldSalesOrderNoSeriesName: Code[20];
        OldInvoiceNoSeriesName: Code[20];
        OldStockoutWarning: Boolean;
        OldAssemblyOrderNoSeries: Code[20];
        OldCreditWarning: Integer;
        ThisObj: Code[9];
        StockoutWarningSet: Boolean;
        BasicDataInitialized: Boolean;
        SetupDataInitialized: Boolean;
        Initialized: Boolean;
        UpdateDimensionOnLine: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    [Test]
    [Scope('OnPrem')]
    procedure QuoteToQuote()
    begin
        Initialize();
        // Test 1
        CheckCopyingBtwNonPostedSalesDocs("Assembly Document Type"::Quote, "Assembly Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteToOrder()
    begin
        Initialize();
        // Test 2
        CheckCopyingBtwNonPostedSalesDocs("Assembly Document Type"::Quote, "Assembly Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteToBlanketOrder()
    begin
        Initialize();
        // Test 3
        CheckCopyingBtwNonPostedSalesDocs("Assembly Document Type"::Quote, "Assembly Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderToQuote()
    begin
        Initialize();
        // Test 4
        CheckCopyingBtwNonPostedSalesDocs("Assembly Document Type"::Order, "Assembly Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderToOrder()
    begin
        Initialize();
        // Test 5
        CheckCopyingBtwNonPostedSalesDocs("Assembly Document Type"::Order, "Assembly Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderToBlanketOrder()
    begin
        Initialize();
        // Test 6
        CheckCopyingBtwNonPostedSalesDocs("Assembly Document Type"::Order, "Assembly Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderToQuote()
    begin
        Initialize();
        // Test 7
        CheckCopyingBtwNonPostedSalesDocs("Assembly Document Type"::"Blanket Order", "Assembly Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderToOrder()
    begin
        Initialize();
        // Test 8
        CheckCopyingBtwNonPostedSalesDocs("Assembly Document Type"::"Blanket Order", "Assembly Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderToBlanketOrder()
    begin
        Initialize();
        // Test 9
        CheckCopyingBtwNonPostedSalesDocs("Assembly Document Type"::"Blanket Order", "Assembly Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentToQuote()
    var
        ToSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ToDocNo: Code[20];
        FromDocNo: Code[20];
    begin
        Initialize();
        // Test 10
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        PostOrderAsShip(FromDocNo, 4);
        ToDocNo := CreateAssemblySalesDocument(0, "Assembly Document Type"::Quote, true);
        ToSalesHeader.Get(ToSalesHeader."Document Type"::Quote, ToDocNo);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Shipment", SalesShipmentNo, ToSalesHeader); // 6 = from Sales Shipment
        CompareAsmLines("Assembly Document Type"::Quote, ToDocNo, true, "Assembly Document Type"::Quote, SalesShipmentNo);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentToOrder()
    var
        ToDocNo: Code[20];
    begin
        Initialize();
        // Test 11
        CheckInit();
        PostOrderAsShip(CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true), 4);
        ToDocNo := CreateAssemblySalesDocument(0, "Assembly Document Type"::Order, true);
        CopyShipmentLinesToSalesOrder(ToDocNo);
        CompareAsmLines("Assembly Document Type"::Order, ToDocNo, true, "Assembly Document Type"::Order, SalesShipmentNo);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentToBlanketOrder()
    var
        ToSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        EmptyBlanketOrderNo: Code[20];
        FromDocNo: Code[20];
    begin
        Initialize();
        // Test 12
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        PostOrderAsShip(FromDocNo, 4);
        EmptyBlanketOrderNo := CreateAssemblySalesDocument(0, "Assembly Document Type"::"Blanket Order", true);
        ToSalesHeader.Get(ToSalesHeader."Document Type"::"Blanket Order", EmptyBlanketOrderNo);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Shipment", SalesShipmentNo, ToSalesHeader); // 6 = from Sales Shipment
        CompareAsmLines(
            "Assembly Document Type"::"Blanket Order", EmptyBlanketOrderNo, true, "Assembly Document Type"::Quote, SalesShipmentNo);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceToQuote1Shipment()
    var
        ToSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        EmptyQuoteNo: Code[20];
        FromDocNo: Code[20];
    begin
        Initialize();
        // Test 13
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        PostOrderAsShip(FromDocNo, 4);
        PostOrderAsInvoice(FromDocNo);
        EmptyQuoteNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Quote, true);
        ToSalesHeader.Get(ToSalesHeader."Document Type"::Quote, EmptyQuoteNo);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", SalesInvoiceNo, ToSalesHeader); // 7 -> From Posted Invoice
        CompareAsmLines("Assembly Document Type"::Quote, EmptyQuoteNo, true, "Assembly Document Type"::Quote, SalesShipmentNo);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceToQuote2Shipments()
    var
        ToDocNo: Code[20];
        FromDocNo: Code[20];
    begin
        Initialize();
        // Test 14
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        PostOrderAsShip(FromDocNo, 3);
        PostOrderAsShip(FromDocNo, 1);
        PostOrderAsInvoice(FromDocNo);
        ToDocNo := CreateAssemblySalesDocument(0, "Assembly Document Type"::Quote, true);
        asserterror CopyInvoiceLinesToSalesQuote(ToDocNo);  // Error expected
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceToOrder1Shipment()
    var
        ToDocNo: Code[20];
        FromDocNo: Code[20];
    begin
        Initialize();
        // Test 15
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        PostOrderAsShip(FromDocNo, 4);
        PostOrderAsInvoice(FromDocNo);
        ToDocNo := CreateAssemblySalesDocument(0, "Assembly Document Type"::Order, true);
        CopyInvoiceLinesToSalesOrder(ToDocNo);
        CompareAsmLines("Assembly Document Type"::Order, ToDocNo, true, "Assembly Document Type"::Order, SalesShipmentNo); // Lines are taken from shipment, not invoice
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceToOrder2Shipments()
    var
        ToDocNo: Code[20];
        FromDocNo: Code[20];
    begin
        Initialize();
        // Test 16
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        PostOrderAsShip(FromDocNo, 3);
        PostOrderAsShip(FromDocNo, 1);
        PostOrderAsInvoice(FromDocNo);
        ToDocNo := CreateAssemblySalesDocument(0, "Assembly Document Type"::Order, true);
        asserterror CopyInvoiceLinesToSalesOrder(ToDocNo);  // Error expected
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceToBlanketOrder1Shipment()
    var
        ToSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        EmptyBlanketOrderNo: Code[20];
        FromDocNo: Code[20];
    begin
        Initialize();
        // Test 17
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        PostOrderAsShip(FromDocNo, 4);
        PostOrderAsInvoice(FromDocNo);
        EmptyBlanketOrderNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::"Blanket Order", true);
        ToSalesHeader.Get(ToSalesHeader."Document Type"::"Blanket Order", EmptyBlanketOrderNo);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", SalesInvoiceNo, ToSalesHeader); // 7 -> From Posted Invoice
        CompareAsmLines("Assembly Document Type"::"Blanket Order", EmptyBlanketOrderNo, true, "Assembly Document Type"::Quote, SalesShipmentNo);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceToBlanketOrder2Shipmnts()
    var
        ToDocNo: Code[20];
        FromDocNo: Code[20];
    begin
        Initialize();
        // Test 18
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        PostOrderAsShip(FromDocNo, 3);
        PostOrderAsShip(FromDocNo, 1);
        PostOrderAsInvoice(FromDocNo);
        ToDocNo := CreateAssemblySalesDocument(0, "Assembly Document Type"::"Blanket Order", true);
        asserterror CopyInvoiceLinesToSalesBlOrder(ToDocNo);  // Error expected
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderToAssemblyOrder()
    var
        SalesOrderNo: Code[20];
        EmptyAssemblyOrderNo: Code[20];
        FullAssemblyOrderNo: Code[20];
    begin
        Initialize();
        // Test 19
        CheckInit();
        SalesOrderNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        CollectAsmLinesFromNonPosted("Assembly Document Type"::Order, SalesOrderNo, FullAssemblyOrderNo);
        CreateAssemblyOrderHeader(EmptyAssemblyOrderNo);
        CopyAsmOrderToAsmOrder(FullAssemblyOrderNo, EmptyAssemblyOrderNo, true);
        CompareAsmOrderHeaders(EmptyAssemblyOrderNo);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyingAssemblyOrderCopiesBinCode()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        AssemblyHeader: Record "Assembly Header";
        AsmOrderNo: Code[20];
        NewAsmOrderNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 267924] When a user copies an assembly order, the program transfers "Bin Code" field value from the source assembly, regardless of "From-Assembly Bin Code" setting on the location.
        Initialize();

        // [GIVEN] Location "L" with two bins "B1", "B2".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        for i := 1 to 2 do
            LibraryWarehouse.FindBin(Bin[i], Location.Code, '', i);

        // [GIVEN] "From-Assembly Bin Code" is set to "B1" on the location.
        Location.Validate("From-Assembly Bin Code", Bin[1].Code);
        Location.Modify(true);

        // [GIVEN] Assembly order with location code = "L" and bin code = "B2" (a default value of "B1" is changed).
        CreateAssemblyOrderHeader(AsmOrderNo);
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AsmOrderNo);
        AssemblyHeader.Validate("Item No.", LibraryInventory.CreateItemNo());
        AssemblyHeader.Validate("Location Code", Location.Code);
        AssemblyHeader.Validate("Bin Code", Bin[2].Code);
        AssemblyHeader.Modify(true);

        // [WHEN] Create a copy of the assembly order.
        CreateAssemblyOrderHeader(NewAsmOrderNo);
        CopyAsmOrderToAsmOrder(AsmOrderNo, NewAsmOrderNo, true);

        // [THEN] "Bin Code" on the new assembly order = "B2".
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, NewAsmOrderNo);
        AssemblyHeader.TestField("Bin Code", Bin[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedAssemblyOrderToAssemblyOrder()
    var
        EmptyAssemblyOrderNo: Code[20];
        FromDocNo: Code[20];
        FullAssemblyOrderNo: Code[20];
    begin
        Initialize();
        // Test 20
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, "Assembly Document Type"::Order, true);
        PostOrderAsShip(FromDocNo, 4);
        CreateAssemblyOrderHeader(EmptyAssemblyOrderNo);
        CopyShipmentLinesToAsmHeader(EmptyAssemblyOrderNo);
        CollectAsmLinesFromShipment(SalesShipmentNo, FullAssemblyOrderNo);
        CompareAsmOrderHeaders(EmptyAssemblyOrderNo);
        CleanSetupData();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmUpdateDimensionOnLines')]
    procedure DimensionSetInAssemblyOrderWhenCopySalesOrderToOrderWithoutRecalcLines()
    var
        ToSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        ToAssemblyHeader: Record "Assembly Header";
        AssemblyHeader: Record "Assembly Header";
        ItemNo: Code[20];
        CustNo: Code[20];
    begin
        // [FEATURE] [Dimension] [Assemble-to-Order]
        // [SCENARIO 282922] Dimensions are transferred from Assembly Order to new Assembly Order when Sales Order is copied to new Sales Order with Recalculate Lines = No
        Initialize();

        // [GIVEN] Assemble-to-Order Item with Default Dimension
        ItemNo := CreateAsmItemWithDimension();

        // [GIVEN] Customer with Default Dimension
        CustNo := CreateCustomerWithDimension();

        // [GIVEN] Sales Order with Assembly Order
        CreateSalesDocWithAsmItem(SalesHeader, SalesHeader."Document Type"::Order, CustNo, ItemNo);
        FindAssemblyHeaderBySalesHeader(AssemblyHeader, SalesHeader);

        // [GIVEN] Modified Dimension in Assembly Line
        ModifyDimensionInAssemblyLine(AssemblyHeader);

        // [GIVEN] Modified Global Dimensions in Assembly Order
        ModifyGlobalDimensionsInAsmOrder(AssemblyHeader);

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(ToSalesHeader, SalesHeader."Document Type", SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy Sales Order to new Sales Order with "Recalculate Lines" = No
        CopySalesOrder(ToSalesHeader, SalesHeader."No.", false);

        // [THEN] Dimensions are copied from old Sales Order to new Sales Order
        VerifyDimensionsMatchInSalesDocs(ToSalesHeader, SalesHeader);

        // [THEN] Dimensions are copied from old Assembly Order to new Assembly Order
        FindAssemblyHeaderBySalesHeader(ToAssemblyHeader, ToSalesHeader);
        VerifyDimensionsMatchInAsmDocs(ToAssemblyHeader, AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmUpdateDimensionOnLines')]
    [Scope('OnPrem')]
    procedure DimensionSetInAssemblyOrderWhenCopySalesOrderToOrderWithRecalcLines()
    var
        ToSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        ToAssemblyHeader: Record "Assembly Header";
        AssemblyHeader: Record "Assembly Header";
        ItemNo: Code[20];
        CustNo: Code[20];
        OldSalesHdrDimSetID: Integer;
        OldSalesLineDimSetID: Integer;
        OldAsmHdrDimSetID: Integer;
        OldAsmLineDimSetID: Integer;
    begin
        // [FEATURE] [Dimension] [Assemble-to-Order]
        // [SCENARIO 282922] Dimensions are recalculated in Assembly Order when Sales Order is copied to new Sales Order with Recalculate Lines = Yes
        Initialize();

        // [GIVEN] Assemble-to-Order Item with Default Dimension
        ItemNo := CreateAsmItemWithDimension();

        // [GIVEN] Customer with Default Dimension
        CustNo := CreateCustomerWithDimension();

        // [GIVEN] Sales Order with Assembly Order
        CreateSalesDocWithAsmItem(SalesHeader, SalesHeader."Document Type"::Order, CustNo, ItemNo);
        FindAssemblyHeaderBySalesHeader(AssemblyHeader, SalesHeader);
        SaveOldDimSetValues(OldSalesHdrDimSetID, OldSalesLineDimSetID, OldAsmHdrDimSetID, OldAsmLineDimSetID, SalesHeader, AssemblyHeader);

        // [GIVEN] Modified Dimension in Sales Line
        ModifyDimensionInSalesLine(SalesHeader);

        // [GIVEN] Modified Dimension in Assembly Line
        ModifyDimensionInAssemblyLine(AssemblyHeader);

        // [GIVEN] Modified Global Dimensions in Assembly Order
        ModifyGlobalDimensionsInAsmOrder(AssemblyHeader);

        // [GIVEN] New Sales Order for the same Customer
        LibrarySales.CreateSalesHeader(ToSalesHeader, SalesHeader."Document Type", SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy Sales Order to new Sales Order with "Recalculate Lines" = Yes
        CopySalesOrder(ToSalesHeader, SalesHeader."No.", true);

        // [THEN] Dimensions are recalcualted in new Sales Order Line
        VerifyDimensionsRecalcInSalesDoc(ToSalesHeader, OldSalesHdrDimSetID, OldSalesLineDimSetID);

        // [THEN] Dimensions are recalculated in new Assembly Order Line
        FindAssemblyHeaderBySalesHeader(ToAssemblyHeader, ToSalesHeader);
        VerifyDimensionsRecalcInAsmDoc(ToAssemblyHeader, OldAsmHdrDimSetID, OldAsmLineDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionOnLines')]
    [Scope('OnPrem')]
    procedure DimensionSetInAssemblyOrderWhenCopyAssemblyOrderWithIncludeHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        ToAssemblyHeader: Record "Assembly Header";
        Location: Record Location;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Dimension] [Assemble-to-Stock]
        // [SCENARIO 282922] Dimensions are transferred from Assembly Order to new Assembly Order when Assembly Order is copied with Include Header = Yes
        Initialize();

        // [GIVEN] Assembly Item with Dimension
        ItemNo := CreateAsmItemWithDimension();

        // [GIVEN] Assembly Order
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, LibraryRandom.RandDateFromInRange(WorkDate(), 1, 10), ItemNo,
          LibraryWarehouse.CreateLocation(Location), LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [GIVEN] Modified Global Dimensions in Assembly Order
        ModifyGlobalDimensionsInAsmOrder(AssemblyHeader);

        // [GIVEN] New Assembly Order
        ToAssemblyHeader.Init();
        ToAssemblyHeader.Validate("Document Type", AssemblyHeader."Document Type");
        ToAssemblyHeader.Validate("No.", LibraryUtility.GenerateGUID());
        ToAssemblyHeader.Insert(true);

        // [WHEN] Copy Assembly Order to new Assembly Order with Include Header = Yes
        CopyAsmOrderToAsmOrder(AssemblyHeader."No.", ToAssemblyHeader."No.", true);

        // [THEN] Both Assembly Orders have same Dimensions
        ToAssemblyHeader.Find();
        VerifyDimensionsMatchInAsmDocs(ToAssemblyHeader, AssemblyHeader);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionOnLines')]
    [Scope('OnPrem')]
    procedure DimensionSetInAssemblyOrderWhenCopyAssemblyOrderWithoutIncludeHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        ToAssemblyHeader: Record "Assembly Header";
        Location: Record Location;
        ItemNo: Code[20];
        OldAsmHdrDimSetID: Integer;
        OldAsmLineDimSetID: Integer;
    begin
        // [FEATURE] [Dimension] [Assemble-to-Stock]
        // [SCENARIO 282922] Dimensions are recalculated in new Assembly Order when Assembly Order is copied with Include Header = No
        Initialize();

        // [GIVEN] Assembly Item with Dimension
        ItemNo := CreateAsmItemWithDimension();

        // [GIVEN] Assembly Order
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, LibraryRandom.RandDateFromInRange(WorkDate(), 1, 10), ItemNo,
          LibraryWarehouse.CreateLocation(Location), LibraryRandom.RandDecInRange(10, 20, 2), '');
        SaveOldDimSetValuesForAsmOrder(OldAsmHdrDimSetID, OldAsmLineDimSetID, AssemblyHeader);

        // [GIVEN] Modified Global Dimensions in Assembly Order
        ModifyGlobalDimensionsInAsmOrder(AssemblyHeader);

        // [GIVEN] New Assembly Order
        LibraryAssembly.CreateAssemblyHeader(
          ToAssemblyHeader, LibraryRandom.RandDateFromInRange(WorkDate(), 1, 10), ItemNo,
          LibraryWarehouse.CreateLocation(Location), LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [WHEN] Copy Assembly Order to new Assembly Order with Include Header = No
        CopyAsmOrderToAsmOrder(AssemblyHeader."No.", ToAssemblyHeader."No.", false);

        // [THEN] Dimensions are recalculated in new Assembly Order Line
        ToAssemblyHeader.Find();
        VerifyDimensionsRecalcInAsmDoc(ToAssemblyHeader, OldAsmHdrDimSetID, OldAsmLineDimSetID);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DimensionSetInAssemblyOrderWhenValidateShortCutDimenionInSalesLine()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        SalesOrder: TestPage "Sales Order";
        AssemblyOrder: TestPage "Assembly Order";
        DimValue: Code[20];
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 311686] When Stan changes Shortcut Dimension in Sales Order Line then Shortcut Dimension is changed in Assembly Order Line
        Initialize();

        // [GIVEN] Dimension with Values "V1" and "V2" was set as Shortcut Dimension 3 in General Ledger Setup
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimValue := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Assemble-to-Order Item with Default Dimension with Value "V2"
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, CreateAsmItem(), DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Sales Order with 1 PCS of Item (Assembly Order was created)
        CreateSalesDocWithAsmItem(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), DefaultDimension."No.");
        FindAssemblyHeaderBySalesHeader(AssemblyHeader, SalesHeader);

        // [GIVEN] Set ShortcutDimCode3 = "V1" in Sales Order Subform
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.ShortcutDimCode3.SetValue(DimValue);

        // [WHEN] Confirm update Dimension in Sales Line
        // done in ConfirmHandlerYes

        // [THEN] Assembly Line has ShortcutDimCode3 = "V1"
        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("Item No.", DefaultDimension."No.");
        AssemblyOrder.Lines.First();
        AssemblyOrder.Lines."ShortcutDimCode[3]".AssertEquals(DimValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DimensionSetInAssemblyQuoteWhenValidateShortCutDimenionInSalesLine()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        SalesQuote: TestPage "Sales Quote";
        AssemblyQuote: TestPage "Assembly Quote";
        DimValue: Code[20];
    begin
        // [FEATURE] [UI] [Sales] [Quote]
        // [SCENARIO 315711] When Stan changes Shortcut Dimension in Sales Quote Line then Shortcut Dimension is changed in Assembly Quote Line
        Initialize();

        // [GIVEN] Dimension with Values "V1" and "V2" was set as Shortcut Dimension 3 in General Ledger Setup
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimValue := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Assemble-to-Order Item with Default Dimension with Value "V2"
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, CreateAsmItem(), DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Sales Quote with 1 PCS of Item (Assembly Quote was created)
        CreateSalesDocWithAsmItem(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo(), DefaultDimension."No.");
        FindAssemblyHeaderBySalesHeader(AssemblyHeader, SalesHeader);

        // [GIVEN] Set ShortcutDimCode3 = "V1" in Sales Quote Subform
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesQuote.SalesLines.First();
        SalesQuote.SalesLines.ShortcutDimCode3.SetValue(DimValue);

        // [WHEN] Confirm update Dimension in Sales Line
        // done in ConfirmHandlerYes

        // [THEN] Assembly Line has ShortcutDimCode3 = "V1"
        AssemblyQuote.OpenEdit();
        AssemblyQuote.Filter.SetFilter("Item No.", DefaultDimension."No.");
        AssemblyQuote.Lines.First();
        AssemblyQuote.Lines."ShortcutDimCode[3]".AssertEquals(DimValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DimensionSetInAssemblyBlanketOrderWhenValidateShortCutDimenionInSalesLine()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        BlanketAssemblyOrder: TestPage "Blanket Assembly Order";
        DimValue: Code[20];
    begin
        // [FEATURE] [UI] [Sales] [Blanket Order]
        // [SCENARIO 315711] When Stan changes Shortcut Dimension in Sales Blanket Order Line then Shortcut Dimension is changed in Assembly Blanket Order Line
        Initialize();

        // [GIVEN] Dimension with Values "V1" and "V2" was set as Shortcut Dimension 3 in General Ledger Setup
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimValue := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Assemble-to-Order Item with Default Dimension with Value "V2"
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, CreateAsmItem(), DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Blanket Sales Order with 1 PCS of Item (Blanket Assembly Order was created)
        CreateSalesDocWithAsmItem(
          SalesHeader, SalesHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo(), DefaultDimension."No.");
        FindAssemblyHeaderBySalesHeader(AssemblyHeader, SalesHeader);

        // [GIVEN] Set ShortcutDimCode3 = "V1" in Blanket Sales Order Subform
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.Filter.SetFilter("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        BlanketSalesOrder.SalesLines.First();
        BlanketSalesOrder.SalesLines."ShortcutDimCode[3]".SetValue(DimValue);

        // [WHEN] Confirm update Dimension in Sales Line
        // done in ConfirmHandlerYes

        // [THEN] Assembly Line has ShortcutDimCode3 = "V1"
        BlanketAssemblyOrder.OpenEdit();
        BlanketAssemblyOrder.Filter.SetFilter("Item No.", DefaultDimension."No.");
        BlanketAssemblyOrder.Lines.First();
        BlanketAssemblyOrder.Lines."ShortcutDimCode[3]".AssertEquals(DimValue);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CopyAssemblyToOrderWithFixedUsageResource()
    var
        AsmItem: Record Item;
        Resource: Record Resource;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewSalesHeader: Record "Sales Header";
        NewSalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        QtyPer: Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Assemble-to-Order] [Resource]
        // [SCENARIO 424568] Copying sales order with linked assembly-to-order does not change quantity of component of Type = "Resource" and Resource Usage Type = "Fixed".
        Initialize();
        QtyPer := LibraryRandom.RandInt(10);
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Assemble-to-order item "I".
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Modify(true);

        // [GIVEN] Create resource "R" and set it as BOM component for item "I".
        // [GIVEN] Set "Resource Usage Type" = "Fixed" and "Quantity Per" = 5.
        LibraryResource.CreateResourceNew(Resource);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Resource, Resource."No.", QtyPer, Resource."Base Unit of Measure");
        BOMComponent.Validate("Resource Usage Type", BOMComponent."Resource Usage Type"::Fixed);
        BOMComponent.Modify(true);

        // [GIVEN] Sales order "SO1" for 20 pcs of item "I". A linked assembly-to-order has been created in background.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', AsmItem."No.", Qty, '', WorkDate());

        // [WHEN] Copy the sales order "SO1" to a new sales order "SO2".
        LibrarySales.CreateSalesHeader(NewSalesHeader, NewSalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Order, SalesHeader."No.", NewSalesHeader);

        // [THEN] Go to a linked assembly for the sales order "SO2" and find the resource component "R".
        // [THEN] Quantity of the resource component = 5, which is equal to "Quantity Per" in BOM component.
        FindSalesLineBySalesHeader(NewSalesLine, NewSalesHeader);
        LibraryAssembly.FindLinkedAssemblyOrder(
          AssemblyHeader, NewSalesLine."Document Type", NewSalesLine."Document No.", NewSalesLine."Line No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Resource);
        AssemblyLine.SetRange("No.", Resource."No.");
        FindAsmLineByAsmHeader(AssemblyLine, AssemblyHeader);
        AssemblyLine.TestField(Quantity, QtyPer);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Copy");
        LibrarySetupStorage.Restore();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Copy");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Copy");
    end;

    local procedure CleanSetupData()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        AssemblySetup: Record "Assembly Setup";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        if not SetupDataInitialized then
            exit;

        SalesSetup.Get();
        if OldSalesOrderNoSeriesName <> '' then begin
            SalesSetup.Validate("Order Nos.", OldSalesOrderNoSeriesName);
            OldSalesOrderNoSeriesName := '';
        end;
        if OldInvoiceNoSeriesName <> '' then begin
            SalesSetup.Validate("Posted Invoice Nos.", OldInvoiceNoSeriesName);
            OldInvoiceNoSeriesName := '';
        end;
        if StockoutWarningSet then begin
            SalesSetup.Validate("Stockout Warning", OldStockoutWarning);
            StockoutWarningSet := false;
        end;
        SalesSetup."Credit Warnings" := OldCreditWarning;
        SalesSetup.Modify();

        if OldAssemblyOrderNoSeries <> '' then begin
            AssemblySetup.Get();
            AssemblySetup."Assembly Order Nos." := OldAssemblyOrderNoSeries;
            AssemblySetup.Modify();
        end;

        if ItemJournalBatch.Get(AssemblyTemplate, AssemblyBatch) then
            ItemJournalBatch.Delete(true);

        SetupDataInitialized := false;
    end;

    local procedure CreateCustomer()
    begin
        SellToCustomerNo := LibrarySales.CreateCustomerNo();
    end;

    local procedure CreateCustomerWithDimension(): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, LibrarySales.CreateCustomerNo(), DimensionValue."Dimension Code", DimensionValue.Code);
        exit(DefaultDimension."No.");
    end;

    local procedure CreateTestNoSeriesBackupData()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SalesSetup: Record "Sales & Receivables Setup";
        AssemblySetup: Record "Assembly Setup";
    begin
        // No. series
        NoSeriesName := 'ASMB__TEST';
        Clear(NoSeries);
        NoSeries.Init();
        NoSeries.Code := NoSeriesName;
        NoSeries.Description := NoSeriesName;
        NoSeries."Default Nos." := true;
        if NoSeries.Insert() then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := NoSeriesName;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'X00001';
            NoSeriesLine."Ending No." := 'X99999';
            NoSeriesLine."Increment-by No." := 1;
            NoSeriesLine.Insert();
        end;
        // Setup data
        SalesSetup.Get();
        OldSalesOrderNoSeriesName := SalesSetup."Order Nos.";
        OldInvoiceNoSeriesName := SalesSetup."Posted Invoice Nos.";
        OldStockoutWarning := SalesSetup."Stockout Warning";
        StockoutWarningSet := true;
        SalesSetup."Stockout Warning" := false;
        OldCreditWarning := SalesSetup."Credit Warnings";
        SalesSetup."Credit Warnings" := SalesSetup."Credit Warnings"::"No Warning";
        SalesSetup."Order Nos." := NoSeriesName;
        SalesSetup."Posted Invoice Nos." := NoSeriesName;
        SalesSetup.Modify();

        AssemblySetup.Get();
        OldAssemblyOrderNoSeries := AssemblySetup."Assembly Order Nos.";
        AssemblySetup."Assembly Order Nos." := NoSeriesName;
        AssemblySetup.Modify();
    end;

    local procedure CreateAssemblyItem()
    var
        Item: Record Item;
        i: Integer;
    begin
        LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::Assembly, '', '');
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify();
        AssemblyItemNo[1] := Item."No.";
        CreateVariant(1);
        for i := 2 to 4 do begin
            LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::" ", '', '');
            AssemblyItemNo[i] := Item."No.";
            CreateVariant(i);
            CreateAssemblyComponent(AssemblyItemNo[1], AssemblyItemNo[i], i, i, 1);
        end;
        CreateAssemblyComponent(AssemblyItemNo[1], '', 0, 5, 0);         // Comment line
        CreateAssemblyComponent(AssemblyItemNo[1], ResourceNo, 1, 6, 2); // Resource line
    end;

    local procedure CreateAsmItem(): Code[20]
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryAssembly.CreateItem(ParentItem, ParentItem."Costing Method"::Average, ParentItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(
          ComponentItem, ComponentItem."Costing Method"::Average, ComponentItem."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", ParentItem."No.", '', BOMComponent."Resource Usage Type",
          LibraryRandom.RandInt(10), true);

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, ComponentItem."No.", '', '', LibraryRandom.RandDecInRange(1000, 2000, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        exit(ParentItem."No.");
    end;

    local procedure CreateAsmItemWithDimension(): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, CreateAsmItem(), DimensionValue."Dimension Code", DimensionValue.Code);
        exit(DefaultDimension."No.");
    end;

    local procedure CreateVariant(VariantNo: Integer)
    var
        ItemVariant: Record "Item Variant";
    begin
        UsedVariantCode[VariantNo] := 'TESTVAR_ ' + Format(VariantNo);
        ItemVariant.Init();
        ItemVariant."Item No." := AssemblyItemNo[VariantNo];
        ItemVariant.Code := UsedVariantCode[VariantNo];
        ItemVariant.Description := UsedVariantCode[VariantNo];
        ItemVariant.Insert();
    end;

    local procedure CreateAssemblyComponent(ParentItemNo: Code[20]; ChildNo: Code[20]; Quantity: Decimal; Line: Integer; Type: Option " ",Item,Resource)
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.Init();
        BOMComponent."Parent Item No." := ParentItemNo;
        BOMComponent."Line No." := (Line - 1) * 10000;
        case Type of
            Type::" ":
                begin
                    BOMComponent.Type := BOMComponent.Type::" ";
                    BOMComponent.Description := 'Empty Line';
                end;
            Type::Item:
                BOMComponent.Type := BOMComponent.Type::Item;
            Type::Resource:
                BOMComponent.Type := BOMComponent.Type::Resource;
        end;
        if Type <> Type::" " then begin
            BOMComponent.Validate("No.", ChildNo);
            BOMComponent.Validate("Quantity per", Quantity);
            if Line < 5 then
                BOMComponent.Validate("Variant Code", UsedVariantCode[Line]);
        end;
        BOMComponent.Insert(true);
    end;

    local procedure GetResource()
    var
        Resource: Record Resource;
    begin
        LibraryResource.CreateResourceNew(Resource);
        ResourceNo := Resource."No.";
    end;

    local procedure FindAssemblyHeaderBySalesHeader(var AssemblyHeader: Record "Assembly Header"; SalesHeader: Record "Sales Header")
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        ATOLink.SetRange("Document Type", SalesHeader."Document Type");
        ATOLink.SetRange("Document No.", SalesHeader."No.");
        ATOLink.FindFirst();
        AssemblyHeader.SetRange("Document Type", ATOLink."Assembly Document Type");
        AssemblyHeader.SetRange("No.", ATOLink."Assembly Document No.");
        AssemblyHeader.FindFirst();
    end;

    local procedure FindAsmLineByAsmHeader(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
    end;

    local procedure FindSalesLineBySalesHeader(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure ModifyDimensionInSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
    begin
        FindSalesLineBySalesHeader(SalesLine, SalesHeader);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        SalesLine.Validate("Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        SalesLine.Modify(true);
    end;

    local procedure ModifyDimensionInAssemblyLine(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        DimensionValue: Record "Dimension Value";
    begin
        FindAsmLineByAsmHeader(AssemblyLine, AssemblyHeader);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        AssemblyLine.Validate("Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        AssemblyLine.Modify(true);
    end;

    local procedure ModifyGlobalDimensionsInAsmOrder(var AssemblyHeader: Record "Assembly Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        AssemblyLine: Record "Assembly Line";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        AssemblyHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 2 Code");
        AssemblyHeader.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        AssemblyHeader.Modify(true);
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        AssemblyLine.Validate("Shortcut Dimension 1 Code", AssemblyHeader."Shortcut Dimension 1 Code");
        AssemblyLine.Validate("Shortcut Dimension 2 Code", AssemblyHeader."Shortcut Dimension 2 Code");
        AssemblyLine.Modify(true);
    end;

    local procedure SaveOldDimSetValues(var OldSalesHdrDimSetID: Integer; var OldSalesLineDimSetID: Integer; var OldAsmHdrDimSetID: Integer; var OldAsmLineDimSetID: Integer; SalesHeader: Record "Sales Header"; AssemblyHeader: Record "Assembly Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLineBySalesHeader(SalesLine, SalesHeader);
        OldSalesHdrDimSetID := SalesHeader."Dimension Set ID";
        OldSalesLineDimSetID := SalesLine."Dimension Set ID";
        SaveOldDimSetValuesForAsmOrder(OldAsmHdrDimSetID, OldAsmLineDimSetID, AssemblyHeader);
    end;

    local procedure SaveOldDimSetValuesForAsmOrder(var OldAsmHdrDimSetID: Integer; var OldAsmLineDimSetID: Integer; AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        FindAsmLineByAsmHeader(AssemblyLine, AssemblyHeader);
        OldAsmHdrDimSetID := AssemblyHeader."Dimension Set ID";
        OldAsmLineDimSetID := AssemblyLine."Dimension Set ID";
    end;

    local procedure ProvideAssemblyComponentSupply()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LibraryInventory: Codeunit "Library - Inventory";
        i: Integer;
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        AssemblyTemplate := ItemJournalTemplate.Name;
        Clear(ItemJournalBatch);
        ItemJournalBatch."Journal Template Name" := AssemblyTemplate;
        i := 1;
        while ItemJournalBatch.Get(AssemblyTemplate, 'B' + Format(i)) do
            i += 1;
        ItemJournalBatch.Name := 'B' + Format(i);
        AssemblyBatch := ItemJournalBatch.Name;
        ItemJournalBatch.Insert(true);
        for i := 2 to 4 do begin
            LibraryInventory.CreateItemJournalLine(
                ItemJournalLine, ItemJournalTemplate.Name, AssemblyBatch, "Item Ledger Document Type"::" ", AssemblyItemNo[i], 1000);
            ItemJournalLine.Validate("Location Code", UsedLocationCode);
            ItemJournalLine.Validate("Variant Code", UsedVariantCode[i]);
            ItemJournalLine.Modify();
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, AssemblyBatch);
    end;

    local procedure CopyShipmentLinesToSalesOrder(EmptySalesOrderNo: Code[20])
    var
        FromSalesShipmentLine: Record "Sales Shipment Line";
        PostedAsmHeader: Record "Posted Assembly Header";
        ToSalesHeader: Record "Sales Header";
        Assert: Codeunit Assert;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        FromSalesShipmentLine.SetRange("Document No.", SalesShipmentNo);
        FromSalesShipmentLine.SetRange(Type, FromSalesShipmentLine.Type::Item);
        FromSalesShipmentLine.FindSet();
        repeat
            Assert.IsTrue(FromSalesShipmentLine.AsmToShipmentExists(PostedAsmHeader),
              StrSubstNo('%1: No Assembly orders exist for %2: Order %3 line %4', ThisObj, FromSalesShipmentLine.TableCaption(),
                FromSalesShipmentLine.FieldCaption("Document No."), FromSalesShipmentLine.FieldCaption("Line No.")));
        until FromSalesShipmentLine.Next() = 0;
        ToSalesHeader.Get(ToSalesHeader."Document Type"::Order, EmptySalesOrderNo);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Shipment", SalesShipmentNo, ToSalesHeader); // 6 = from Sales Shipment
    end;

    local procedure CopyShipmentLinesToAsmHeader(AssemblyHeaderNo: Code[20])
    var
        FromSalesShipmentLine: Record "Sales Shipment Line";
        PostedAsmHeader: Record "Posted Assembly Header";
        ToAsmHeader: Record "Assembly Header";
        Assert: Codeunit Assert;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        FromSalesShipmentLine.SetRange("Document No.", SalesShipmentNo);
        FromSalesShipmentLine.SetRange(Type, FromSalesShipmentLine.Type::Item);
        FromSalesShipmentLine.FindSet();
        repeat
            Assert.IsTrue(FromSalesShipmentLine.AsmToShipmentExists(PostedAsmHeader),
              StrSubstNo('%1: No Assembly orders exist for %2: Order %3 line %4', FromSalesShipmentLine.TableCaption(),
                FromSalesShipmentLine.FieldCaption("Document No."), FromSalesShipmentLine.FieldCaption("Line No.")));
        until FromSalesShipmentLine.Next() = 0;
        ToAsmHeader.Get(ToAsmHeader."Document Type"::Order, AssemblyHeaderNo);
        CopyDocumentMgt.CopyPostedAsmHeaderToAsmHeader(PostedAsmHeader, ToAsmHeader, true);
    end;

    local procedure CopyInvoiceLinesToSalesOrder(ToDocNo: Code[20])
    var
        ToSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        ToSalesHeader.Get(ToSalesHeader."Document Type"::Order, ToDocNo);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", SalesInvoiceNo, ToSalesHeader); // 7 -> From Posted Invoice
    end;

    local procedure CopyInvoiceLinesToSalesQuote(ToDocNo: Code[20])
    var
        ToSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        ToSalesHeader.Get(ToSalesHeader."Document Type"::Quote, ToDocNo);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", SalesInvoiceNo, ToSalesHeader); // 7 -> From Posted Invoice
    end;

    local procedure CopyInvoiceLinesToSalesBlOrder(ToDocNo: Code[20])
    var
        ToSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        ToSalesHeader.Get(ToSalesHeader."Document Type"::"Blanket Order", ToDocNo);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", SalesInvoiceNo, ToSalesHeader); // 7 -> From Posted Invoice
    end;

    local procedure CopyAsmOrderToAsmOrder(From: Code[20]; To_: Code[20]; IncludeHeader: Boolean)
    var
        FromAsmHeader: Record "Assembly Header";
        ToAsmHeader: Record "Assembly Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        FromAsmHeader.Get(FromAsmHeader."Document Type"::Order, From);
        ToAsmHeader.Get(ToAsmHeader."Document Type"::Order, To_);
        CopyDocumentMgt.CopyAsmHeaderToAsmHeader(FromAsmHeader, ToAsmHeader, IncludeHeader);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure CopySalesOrder(var ToSalesHeader: Record "Sales Header"; FromDocNo: Code[20]; RecalculateLines: Boolean)
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(false, RecalculateLines, false, false, false, false, false);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Order, FromDocNo, ToSalesHeader);
    end;

    local procedure CompareAsmOrderHeaders(ToDocumentNo: Code[20])
    var
        ToAsmLine: Record "Assembly Line";
        Assert: Codeunit Assert;
    begin
        ToAsmLine.SetRange("Document Type", ToAsmLine."Document Type"::Order);
        ToAsmLine.SetRange("Document No.", ToDocumentNo);
        Assert.AreEqual(TempAsmLine.Count, ToAsmLine.Count, 'No. of Asm lines when copying from one Asm header to another');
        TempAsmLine.FindSet();
        ToAsmLine.FindSet();
        repeat
            Assert.AreEqual(TempAsmLine.Type, ToAsmLine.Type, GetMsg(ToAsmLine.FieldCaption(Type)));
            Assert.AreEqual(TempAsmLine."No.", ToAsmLine."No.", GetMsg(ToAsmLine.FieldCaption("No.")));
            Assert.AreEqual(TempAsmLine.Quantity, ToAsmLine.Quantity, GetMsg(ToAsmLine.FieldCaption(Quantity)));
            Assert.AreEqual(TempAsmLine."Quantity (Base)", ToAsmLine."Quantity (Base)", GetMsg(ToAsmLine.FieldCaption("Quantity (Base)")));
        until (ToAsmLine.Next() = 0) and (TempAsmLine.Next() = 0);
    end;

    local procedure CreateAssemblyOrderHeader(var AssemblyHeaderNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        Clear(AssemblyHeader);
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader.Insert(true);
        AssemblyHeaderNo := AssemblyHeader."No.";
    end;

    local procedure CreateAssemblySalesDocument(AssemblyItemQuantity: Decimal; DocumentType: Enum "Assembly Document Type"; CustomizeOrder: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InventorySetup: Record "Inventory Setup";
    begin
        case DocumentType of
            DocumentType::Quote:
                LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, SellToCustomerNo);
            DocumentType::Order:
                LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
            DocumentType::"Blanket Order":
                LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", SellToCustomerNo);
        end;
        InventorySetup.Get();
        SalesHeader.Validate(
          "Shipment Date", CalcDate(InventorySetup."Default Safety Lead Time", WorkDate()));
        SalesHeader.Validate("Location Code", UsedLocationCode);
        SalesHeader.Modify();
        if AssemblyItemQuantity > 0 then begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, AssemblyItemNo[1], AssemblyItemQuantity); // 2 -> Item
            SalesLine.Validate("Location Code", UsedLocationCode);
            SalesLine.Validate("Variant Code", UsedVariantCode[1]);
            SalesLine.Modify(true);
            if CustomizeOrder then
                CustomizeAssemblyOrder(SalesLine);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Resource, ResourceNo, 1);                           // 3 -> Resource
        end;
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDocWithAsmItem(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Shipment Date", LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CustomizeAssemblyOrder(SalesLine: Record "Sales Line")
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        i: Integer;
        LineNo: Integer;
    begin
        if not SalesLine.AsmToOrderExists(AsmHeader) then
            exit;
        LineNo := 50000;
        for i := 4 downto 2 do begin
            LineNo += 10000;
            Clear(AsmLine);
            AsmLine."Document Type" := AsmHeader."Document Type";
            AsmLine."Document No." := AsmHeader."No.";
            AsmLine."Line No." := LineNo;
            AsmLine.Insert(true);
            AsmLine.Type := AsmLine.Type::Item;
            AsmLine.Validate("No.", AssemblyItemNo[i]);
            AsmLine.Validate(Quantity, 10 * i);
            AsmLine.Validate("Quantity per", i);
            AsmLine.Validate("Variant Code", UsedVariantCode[i]);
            AsmLine.Modify(true);
        end;
    end;

    local procedure CollectAsmLinesFromNonPosted(DocumentType: Enum "Assembly Document Type"; SalesOrderNo: Code[20]; var FullAssemblyOrderHeaderNo: Code[20])
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        AsmLine: Record "Assembly Line";
    begin
        FullAssemblyOrderHeaderNo := '';
        TempAsmLine.DeleteAll();
        case DocumentType of
            "Assembly Document Type"::Quote:
                AssembleToOrderLink.SetRange("Document Type", AssembleToOrderLink."Document Type"::Quote);
            "Assembly Document Type"::Order:
                AssembleToOrderLink.SetRange("Document Type", AssembleToOrderLink."Document Type"::Order);
            "Assembly Document Type"::"Blanket Order":
                AssembleToOrderLink.SetRange("Document Type", AssembleToOrderLink."Document Type"::"Blanket Order");
        end;

        AssembleToOrderLink.SetRange("Document No.", SalesOrderNo);
        if not AssembleToOrderLink.FindSet() then
            exit;
        FullAssemblyOrderHeaderNo := AssembleToOrderLink."Assembly Document No.";
        repeat
            AsmLine.SetRange("Document Type", AssembleToOrderLink."Assembly Document Type");
            AsmLine.SetRange("Document No.", AssembleToOrderLink."Assembly Document No.");
            if AsmLine.FindSet() then
                repeat
                    TempAsmLine := AsmLine;
                    TempAsmLine.Insert();
                until AsmLine.Next() = 0;
        until AssembleToOrderLink.Next() = 0;
    end;

    local procedure CollectAsmLinesFromShipment(ShipmentNo: Code[20]; var FullAssemblyOrderNo: Code[20])
    var
        PostedAssembleToOrderLink: Record "Posted Assemble-to-Order Link";
        PostedAsmLine: Record "Posted Assembly Line";
    begin
        FullAssemblyOrderNo := '';
        TempAsmLine.DeleteAll();
        PostedAssembleToOrderLink.SetRange("Document Type", PostedAssembleToOrderLink."Document Type"::"Sales Shipment");
        PostedAssembleToOrderLink.SetRange("Document No.", ShipmentNo);
        if not PostedAssembleToOrderLink.FindSet() then
            exit;
        FullAssemblyOrderNo := PostedAssembleToOrderLink."Assembly Document No.";
        repeat
            PostedAsmLine.SetRange("Document No.", PostedAssembleToOrderLink."Assembly Document No.");
            if PostedAsmLine.FindSet() then
                repeat
                    TempAsmLine.TransferFields(PostedAsmLine);
                    TempAsmLine."Document Type" := TempAsmLine."Document Type"::Order;
                    TempAsmLine."Document No." := PostedAsmLine."Document No.";
                    TempAsmLine."Line No." := PostedAsmLine."Line No.";
                    TempAsmLine.Insert();
                until PostedAsmLine.Next() = 0;
        until PostedAssembleToOrderLink.Next() = 0;
    end;

    local procedure CompareAsmLines(NewDocType: Enum "Assembly Document Type"; NewSalesHeaderNo: Code[20]; Posted: Boolean; OriginalDocType: Enum "Assembly Document Type"; OriginalDocNo: Code[20])
    var
        ToAsmLine: Record "Assembly Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        Assert: Codeunit Assert;
        FullAssemblyOrderNo: Code[20];
        AsmHeaderNo: Code[20];
    begin
        if Posted then
            CollectAsmLinesFromShipment(OriginalDocNo, FullAssemblyOrderNo)
        else
            CollectAsmLinesFromNonPosted(OriginalDocType, OriginalDocNo, AsmHeaderNo);
        case NewDocType of
            NewDocType::Quote:
                AssembleToOrderLink.SetRange("Document Type", AssembleToOrderLink."Document Type"::Quote);
            NewDocType::Order:
                AssembleToOrderLink.SetRange("Document Type", AssembleToOrderLink."Document Type"::Order);
            NewDocType::"Blanket Order":
                AssembleToOrderLink.SetRange("Document Type", AssembleToOrderLink."Document Type"::"Blanket Order");
        end;
        AssembleToOrderLink.SetRange("Document No.", NewSalesHeaderNo);
        AssembleToOrderLink.FindFirst();
        case NewDocType of
            NewDocType::Quote:
                ToAsmLine.SetRange("Document Type", ToAsmLine."Document Type"::Quote);
            NewDocType::Order:
                ToAsmLine.SetRange("Document Type", ToAsmLine."Document Type"::Order);
            NewDocType::"Blanket Order":
                ToAsmLine.SetRange("Document Type", ToAsmLine."Document Type"::"Blanket Order");
        end;
        ToAsmLine.SetRange("Document No.", AssembleToOrderLink."Assembly Document No.");
        Assert.AreEqual(TempAsmLine.Count, ToAsmLine.Count,
          'The number of assembly lines on the copied document must match the number on the original');
        TempAsmLine.FindSet();
        ToAsmLine.FindSet();
        repeat
            Assert.AreEqual(TempAsmLine.Type, ToAsmLine.Type, TempAsmLine.FieldCaption(Type));
            Assert.AreEqual(TempAsmLine."No.", ToAsmLine."No.", GetMsg(TempAsmLine.FieldCaption("No.")));
            Assert.AreEqual(TempAsmLine.Type, ToAsmLine.Type, GetMsg(TempAsmLine.FieldCaption(Type)));
            Assert.AreEqual(TempAsmLine.Description, ToAsmLine.Description, GetMsg(TempAsmLine.FieldCaption(Description)));
            if TempAsmLine.Type <> TempAsmLine.Type::" " then
                Assert.AreEqual(TempAsmLine."Quantity per", ToAsmLine."Quantity per", GetMsg(TempAsmLine.FieldCaption("Quantity per")));
            Assert.AreEqual(TempAsmLine."Unit Cost", ToAsmLine."Unit Cost", GetMsg(TempAsmLine.FieldCaption("Unit Cost")));
            Assert.AreEqual(TempAsmLine."Location Code", ToAsmLine."Location Code", GetMsg(TempAsmLine.FieldCaption("Location Code")));
            Assert.AreEqual(TempAsmLine."Variant Code", ToAsmLine."Variant Code", GetMsg(TempAsmLine.FieldCaption("Variant Code")));
            Assert.AreEqual(TempAsmLine."Location Code", ToAsmLine."Location Code", GetMsg(TempAsmLine.FieldCaption("Location Code")));
        until (TempAsmLine.Next() = 0) and (ToAsmLine.Next() = 0);
    end;

    local procedure PostOrderAsShip(NonEmptySalesOrderNo: Code[20]; QtyToShip: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesLine.Get(SalesLine."Document Type"::Order, NonEmptySalesOrderNo, GetFirstItemLineNo(NonEmptySalesOrderNo));
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        SalesHeader.Get(SalesHeader."Document Type"::Order, NonEmptySalesOrderNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesShipmentHeader.SetCurrentKey("Order No.");
        SalesShipmentHeader.SetRange("Order No.", NonEmptySalesOrderNo);
        SalesShipmentHeader.FindFirst();
        SalesShipmentNo := SalesShipmentHeader."No.";
        exit(SalesShipmentNo);
    end;

    local procedure PostOrderAsInvoice(NonEmptySalesOrderNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, NonEmptySalesOrderNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ItemLedgerEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgerEntry.SetRange("Document No.", SalesShipmentNo);
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.FindFirst();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.FindFirst();
        SalesInvoiceNo := ValueEntry."Document No.";
        exit(SalesInvoiceNo);
    end;

    local procedure GetMsg(FieldName: Text[100]): Text[1024]
    begin
        exit(StrSubstNo('COD132600 Value mismatch in %1', FieldName));
    end;

    local procedure GetSKU()
    var
        SKU: Record "Stockkeeping Unit";
        i: Integer;
    begin
        for i := 1 to 4 do begin
            SKU.Init();
            SKU."Location Code" := UsedLocationCode;
            SKU."Item No." := AssemblyItemNo[1];
            SKU."Variant Code" := UsedVariantCode[i];
            if SKU.Insert(true) then;
            SKU.Validate("Unit Cost", (i + 1) * 10);
            SKU.Modify(true);
        end;
    end;

    local procedure GetFirstItemLineNo(OrderNo: Code[20]): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if not SalesLine.FindFirst() then
            exit(0);
        exit(SalesLine."Line No.");
    end;

    local procedure CheckInit()
    var
        Location: Record Location;
    begin
        // INIT
        if not SetupDataInitialized then begin
            ThisObj := 'COD137927';
            CreateTestNoSeriesBackupData();
            SetupDataInitialized := true;
        end;
        if not BasicDataInitialized then begin
            CreateCustomer();
            GetResource();
            UsedLocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            CreateAssemblyItem();
            GetSKU();
            ProvideAssemblyComponentSupply();
            BasicDataInitialized := true;
        end;
    end;

    local procedure CheckCopyingBtwNonPostedSalesDocs(FromDocType: Enum "Assembly Document Type"; ToDocType: Enum "Assembly Document Type")
    var
        ToSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        FromDocNo: Code[20];
        ToDocNo: Code[20];
        FromDocEnum: Enum "Sales Document Type From";
    begin
        CheckInit();
        FromDocNo := CreateAssemblySalesDocument(4, FromDocType, true);
        ToDocNo := CreateAssemblySalesDocument(0, ToDocType, true);
        case ToDocType of
            ToDocType::Quote:
                ToSalesHeader.Get(ToSalesHeader."Document Type"::Quote, ToDocNo);
            ToDocType::Order:
                ToSalesHeader.Get(ToSalesHeader."Document Type"::Order, ToDocNo);
            ToDocType::"Blanket Order":
                ToSalesHeader.Get(ToSalesHeader."Document Type"::"Blanket Order", ToDocNo);
        end;
        case FromDocType of
            FromDocType::Quote:
                FromDocEnum := FromDocEnum::Quote;
            FromDocType::Order:
                FromDocEnum := FromDocEnum::Order;
            FromDocType::"Blanket Order":
                FromDocEnum := FromDocEnum::"Blanket Order";
        end;
        CopyDocumentMgt.CopySalesDoc(FromDocEnum, FromDocNo, ToSalesHeader);
        CompareAsmLines(ToDocType, ToDocNo, false, FromDocType, FromDocNo);
        CleanSetupData();
    end;

    local procedure VerifyDimensionsMatchInSalesDocs(ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header")
    var
        ToSalesLine: Record "Sales Line";
        FromSalesLine: Record "Sales Line";
    begin
        ToSalesHeader.TestField("Dimension Set ID", FromSalesHeader."Dimension Set ID");
        FindSalesLineBySalesHeader(ToSalesLine, ToSalesHeader);
        FindSalesLineBySalesHeader(FromSalesLine, FromSalesHeader);
        ToSalesLine.TestField("Dimension Set ID", FromSalesLine."Dimension Set ID");
    end;

    local procedure VerifyDimensionsMatchInAsmDocs(ToAssemblyHeader: Record "Assembly Header"; FromAssemblyHeader: Record "Assembly Header")
    var
        ToAssemblyLine: Record "Assembly Line";
        FromAssemblyLine: Record "Assembly Line";
    begin
        ToAssemblyHeader.TestField("Dimension Set ID", FromAssemblyHeader."Dimension Set ID");
        ToAssemblyHeader.TestField("Shortcut Dimension 1 Code", FromAssemblyHeader."Shortcut Dimension 1 Code");
        ToAssemblyHeader.TestField("Shortcut Dimension 2 Code", FromAssemblyHeader."Shortcut Dimension 2 Code");
        FindAsmLineByAsmHeader(ToAssemblyLine, ToAssemblyHeader);
        FindAsmLineByAsmHeader(FromAssemblyLine, FromAssemblyHeader);
        ToAssemblyLine.TestField("Dimension Set ID", FromAssemblyLine."Dimension Set ID");
        ToAssemblyLine.TestField("Shortcut Dimension 1 Code", FromAssemblyLine."Shortcut Dimension 1 Code");
        ToAssemblyLine.TestField("Shortcut Dimension 2 Code", FromAssemblyLine."Shortcut Dimension 2 Code");
    end;

    local procedure VerifyDimensionsRecalcInSalesDoc(SalesHeader: Record "Sales Header"; SalesHdrDimSetID: Integer; SalesLineDimSetID: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.TestField("Dimension Set ID", SalesHdrDimSetID);
        FindSalesLineBySalesHeader(SalesLine, SalesHeader);
        SalesLine.TestField("Dimension Set ID", SalesLineDimSetID);
    end;

    local procedure VerifyDimensionsRecalcInAsmDoc(AssemblyHeader: Record "Assembly Header"; AsmHdrDimSetID: Integer; AsmLineDimSetID: Integer)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyHeader.TestField("Dimension Set ID", AsmHdrDimSetID);
        AssemblyHeader.TestField("Shortcut Dimension 1 Code", '');
        AssemblyHeader.TestField("Shortcut Dimension 2 Code", '');
        FindAsmLineByAsmHeader(AssemblyLine, AssemblyHeader);
        AssemblyLine.TestField("Dimension Set ID", AsmLineDimSetID);
        AssemblyLine.TestField("Shortcut Dimension 1 Code", '');
        AssemblyLine.TestField("Shortcut Dimension 2 Code", '');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmUpdateDimensionOnLines(Question: Text[1024]; var Reply: Boolean)
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(StrPos(Question, UpdateDimensionOnLine) > 0, Question);
        Reply := true;
    end;
}

