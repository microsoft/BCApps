// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 134860 "Sales Shpt.-Invoice Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Shipment] [Invoice]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        NoRelatedShipmentsMsg: Label 'There are no posted sales shipments related to sales invoice %1.', Comment = '%1 = the number of the posted sales invoice';
        NoRelatedInvoicesMsg: Label 'There are no posted sales invoices related to sales shipment %1.', Comment = '%1 = the number of the posted sales shipment';
        ShipmentCountErr: Label 'Unexpected number of related sales shipments.';
        InvoiceCountErr: Label 'Unexpected number of related sales invoices.';
        ShipmentNoErr: Label 'Unexpected related sales shipment.';
        InvoiceNoErr: Label 'Unexpected related sales invoice.';
        ShipmentFoundErr: Label 'Related sales shipments were expected to be found.';
        InvoiceFoundErr: Label 'Related sales invoices were expected to be found.';
        NoShipmentExpectedErr: Label 'No related sales shipment was expected.';
        NoInvoiceExpectedErr: Label 'No related sales invoice was expected.';
        PageRecordErr: Label 'Unexpected record shown on the opened page.';
        PageRowCountErr: Label 'Unexpected number of rows shown on the opened page.';
        MessageErr: Label 'Unexpected message.';

    [Test]
    procedure ShipmentsForInvoiceReturnsRelatedShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Posted sales invoice "I" that was posted together with shipment "S" resolves to "S"
        Initialize();

        // [GIVEN] Sales order with an item line, posted as shipped and invoiced, creating shipment "S" and invoice "I"
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        PostShipAndInvoice(SalesHeader, ShipmentNo, InvoiceNo);
        SalesInvoiceHeader.Get(InvoiceNo);

        // [WHEN] Get the shipments related to invoice "I"
        // [THEN] Shipment "S" is the only related shipment
        Assert.IsTrue(SalesShipmentInvoiceLink.GetShipmentsForInvoice(SalesInvoiceHeader, SalesShipmentHeader), ShipmentFoundErr);
        VerifySingleShipment(SalesShipmentHeader, ShipmentNo);
    end;

    [Test]
    procedure InvoicesForShipmentReturnsRelatedInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Posted sales shipment "S" that was posted together with invoice "I" resolves to "I"
        Initialize();

        // [GIVEN] Sales order with an item line, posted as shipped and invoiced, creating shipment "S" and invoice "I"
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        PostShipAndInvoice(SalesHeader, ShipmentNo, InvoiceNo);
        SalesShipmentHeader.Get(ShipmentNo);

        // [WHEN] Get the invoices related to shipment "S"
        // [THEN] Invoice "I" is the only related invoice
        Assert.IsTrue(SalesShipmentInvoiceLink.GetInvoicesForShipment(SalesShipmentHeader, SalesInvoiceHeader), InvoiceFoundErr);
        VerifySingleInvoice(SalesInvoiceHeader, InvoiceNo);
    end;

    [Test]
    procedure ShipmentsForInvoiceReturnsAllShipmentsInvoicedTogether()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        FirstShipmentNo: Code[20];
        SecondShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Invoice "I" that invoices two shipments "S1" and "S2" resolves to both shipments
        Initialize();

        // [GIVEN] Sales order with an item line of quantity 10, shipped in two parts as "S1" and "S2"
        CreateSalesOrderWithItem(SalesHeader, 10);
        FirstShipmentNo := PostPartialShipment(SalesHeader, 6);
        SecondShipmentNo := PostPartialShipment(SalesHeader, 4);

        // [GIVEN] The order is invoiced in one go as invoice "I"
        InvoiceNo := PostRemainingInvoice(SalesHeader);
        SalesInvoiceHeader.Get(InvoiceNo);

        // [WHEN] Get the shipments related to invoice "I"
        // [THEN] Both "S1" and "S2" are returned
        Assert.IsTrue(SalesShipmentInvoiceLink.GetShipmentsForInvoice(SalesInvoiceHeader, SalesShipmentHeader), ShipmentFoundErr);
        Assert.AreEqual(2, SalesShipmentHeader.Count(), ShipmentCountErr);
        Assert.IsTrue(SalesShipmentHeader.Get(FirstShipmentNo), ShipmentNoErr);
        Assert.IsTrue(SalesShipmentHeader.Get(SecondShipmentNo), ShipmentNoErr);
    end;

    [Test]
    procedure InvoicesForShipmentReturnsAllInvoicesFromShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        ShipmentNo: Code[20];
        FirstInvoiceNo: Code[20];
        SecondInvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Shipment "S" that is invoiced by two invoices "I1" and "I2" resolves to both invoices
        Initialize();

        // [GIVEN] Sales order with an item line of quantity 10, fully shipped as "S"
        CreateSalesOrderWithItem(SalesHeader, 10);
        ShipmentNo := PostFullShipment(SalesHeader);

        // [GIVEN] The order is invoiced in two parts as "I1" and "I2"
        FirstInvoiceNo := PostPartialInvoice(SalesHeader, 6);
        SecondInvoiceNo := PostRemainingInvoice(SalesHeader);
        SalesShipmentHeader.Get(ShipmentNo);

        // [WHEN] Get the invoices related to shipment "S"
        // [THEN] Both "I1" and "I2" are returned
        Assert.IsTrue(SalesShipmentInvoiceLink.GetInvoicesForShipment(SalesShipmentHeader, SalesInvoiceHeader), InvoiceFoundErr);
        Assert.AreEqual(2, SalesInvoiceHeader.Count(), InvoiceCountErr);
        Assert.IsTrue(SalesInvoiceHeader.Get(FirstInvoiceNo), InvoiceNoErr);
        Assert.IsTrue(SalesInvoiceHeader.Get(SecondInvoiceNo), InvoiceNoErr);
    end;

    [Test]
    procedure ShipmentsForInvoiceMarksShipmentOnlyOnce()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Invoice "I" with several lines from the same shipment "S" returns "S" only once
        Initialize();

        // [GIVEN] Sales order with three item lines, posted as shipped and invoiced, creating shipment "S" and invoice "I"
        CreateSalesOrderWithItemLines(SalesHeader, 3, LibraryRandom.RandIntInRange(10, 20));
        PostShipAndInvoice(SalesHeader, ShipmentNo, InvoiceNo);
        SalesInvoiceHeader.Get(InvoiceNo);

        // [WHEN] Get the shipments related to invoice "I"
        // [THEN] Shipment "S" is returned exactly once
        Assert.IsTrue(SalesShipmentInvoiceLink.GetShipmentsForInvoice(SalesInvoiceHeader, SalesShipmentHeader), ShipmentFoundErr);
        VerifySingleShipment(SalesShipmentHeader, ShipmentNo);
    end;

    [Test]
    procedure InvoicesForShipmentMarksInvoiceOnlyOnce()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Shipment "S" with several lines invoiced by the same invoice "I" returns "I" only once
        Initialize();

        // [GIVEN] Sales order with three item lines, posted as shipped and invoiced, creating shipment "S" and invoice "I"
        CreateSalesOrderWithItemLines(SalesHeader, 3, LibraryRandom.RandIntInRange(10, 20));
        PostShipAndInvoice(SalesHeader, ShipmentNo, InvoiceNo);
        SalesShipmentHeader.Get(ShipmentNo);

        // [WHEN] Get the invoices related to shipment "S"
        // [THEN] Invoice "I" is returned exactly once
        Assert.IsTrue(SalesShipmentInvoiceLink.GetInvoicesForShipment(SalesShipmentHeader, SalesInvoiceHeader), InvoiceFoundErr);
        VerifySingleInvoice(SalesInvoiceHeader, InvoiceNo);
    end;

    [Test]
    procedure ShipmentsForInvoiceReturnsNothingForGLAccountOnlyInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Posted sales invoice "I" that has no shipment behind it resolves to no shipments
        Initialize();

        // [GIVEN] Sales invoice document with a G/L account line, posted as invoice "I"
        CreateSalesInvoiceWithGLAccount(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Get the shipments related to invoice "I"
        // [THEN] No shipment is returned
        Assert.IsFalse(SalesShipmentInvoiceLink.GetShipmentsForInvoice(SalesInvoiceHeader, SalesShipmentHeader), NoShipmentExpectedErr);
        Assert.AreEqual(0, SalesShipmentHeader.Count(), ShipmentCountErr);
    end;

    [Test]
    procedure InvoicesForShipmentReturnsNothingForUninvoicedShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Posted sales shipment "S" that has not been invoiced resolves to no invoices
        Initialize();

        // [GIVEN] Sales order with an item line, posted as shipped only, creating shipment "S"
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        SalesShipmentHeader.Get(PostFullShipment(SalesHeader));

        // [WHEN] Get the invoices related to shipment "S"
        // [THEN] No invoice is returned
        Assert.IsFalse(SalesShipmentInvoiceLink.GetInvoicesForShipment(SalesShipmentHeader, SalesInvoiceHeader), NoInvoiceExpectedErr);
        Assert.AreEqual(0, SalesInvoiceHeader.Count(), InvoiceCountErr);
    end;

    [Test]
    procedure ShipmentsForInvoiceFindsShipmentFromInvoiceLineWithoutItemEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Invoice "I" created with Get Shipment Lines from a G/L account shipment "S" resolves to "S"
        Initialize();

        // [GIVEN] Sales order with a G/L account line, posted as shipped only, creating shipment "S" without item ledger entries
        CreateSalesOrderWithGLAccount(SalesHeader);
        ShipmentNo := PostFullShipment(SalesHeader);

        // [GIVEN] Sales invoice created with Get Shipment Lines from shipment "S" and posted as invoice "I"
        SalesInvoiceHeader.Get(CreateAndPostInvoiceFromShipmentLines(SalesHeader."Sell-to Customer No.", ShipmentNo));

        // [WHEN] Get the shipments related to invoice "I"
        // [THEN] Shipment "S" is the only related shipment
        Assert.IsTrue(SalesShipmentInvoiceLink.GetShipmentsForInvoice(SalesInvoiceHeader, SalesShipmentHeader), ShipmentFoundErr);
        VerifySingleShipment(SalesShipmentHeader, ShipmentNo);
    end;

    [Test]
    procedure OnAfterGetShipmentsForInvoiceIsRaised()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShptInvLinkSubscr: Codeunit "Sales Shpt.-Inv. Link Subscr.";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] A subscriber to OnAfterGetShipmentsForInvoice can mark an additional shipment "S"
        Initialize();

        // [GIVEN] Sales order with an item line, posted as shipped only, creating shipment "S"
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        ShipmentNo := PostFullShipment(SalesHeader);

        // [GIVEN] Sales invoice "I" that is not related to any shipment
        CreateSalesInvoiceWithGLAccount(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [GIVEN] A bound subscriber that marks shipment "S"
        SalesShptInvLinkSubscr.SetShipmentNo(ShipmentNo);
        BindSubscription(SalesShptInvLinkSubscr);

        // [WHEN] Get the shipments related to invoice "I"
        // [THEN] Shipment "S" is returned by the subscriber
        Assert.IsTrue(SalesShipmentInvoiceLink.GetShipmentsForInvoice(SalesInvoiceHeader, SalesShipmentHeader), ShipmentFoundErr);
        VerifySingleShipment(SalesShipmentHeader, ShipmentNo);
        UnbindSubscription(SalesShptInvLinkSubscr);
    end;

    [Test]
    procedure OnAfterGetInvoicesForShipmentIsRaised()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShptInvLinkSubscr: Codeunit "Sales Shpt.-Inv. Link Subscr.";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] A subscriber to OnAfterGetInvoicesForShipment can mark an additional invoice "I"
        Initialize();

        // [GIVEN] Sales invoice "I" that is not related to any shipment
        CreateSalesInvoiceWithGLAccount(SalesHeader);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Sales order with an item line, posted as shipped only, creating shipment "S" without invoices
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        SalesShipmentHeader.Get(PostFullShipment(SalesHeader));

        // [GIVEN] A bound subscriber that marks invoice "I"
        SalesShptInvLinkSubscr.SetInvoiceNo(InvoiceNo);
        BindSubscription(SalesShptInvLinkSubscr);

        // [WHEN] Get the invoices related to shipment "S"
        // [THEN] Invoice "I" is returned by the subscriber
        Assert.IsTrue(SalesShipmentInvoiceLink.GetInvoicesForShipment(SalesShipmentHeader, SalesInvoiceHeader), InvoiceFoundErr);
        VerifySingleInvoice(SalesInvoiceHeader, InvoiceNo);
        UnbindSubscription(SalesShptInvLinkSubscr);
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentPageHandler')]
    procedure ShowShipmentsForInvoiceOpensShipmentCardWhenSingleShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the shipments of invoice "I" opens the card of shipment "S" when only one is related
        Initialize();

        // [GIVEN] Sales order with an item line, posted as shipped and invoiced, creating shipment "S" and invoice "I"
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        PostShipAndInvoice(SalesHeader, ShipmentNo, InvoiceNo);
        SalesInvoiceHeader.Get(InvoiceNo);

        // [WHEN] Show the shipments related to invoice "I"
        SalesShipmentInvoiceLink.ShowShipmentsForInvoice(SalesInvoiceHeader);

        // [THEN] The Posted Sales Shipment card for "S" opens
        Assert.AreEqual(ShipmentNo, LibraryVariableStorage.DequeueText(), PageRecordErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentsPageHandler')]
    procedure ShowShipmentsForInvoiceOpensShipmentListWhenMultipleShipments()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the shipments of invoice "I" opens the shipment list when two shipments are related
        Initialize();

        // [GIVEN] Sales order with an item line of quantity 10, shipped in two parts and invoiced in one go as invoice "I"
        CreateSalesOrderWithItem(SalesHeader, 10);
        PostPartialShipment(SalesHeader, 6);
        PostPartialShipment(SalesHeader, 4);
        SalesInvoiceHeader.Get(PostRemainingInvoice(SalesHeader));

        // [WHEN] Show the shipments related to invoice "I"
        SalesShipmentInvoiceLink.ShowShipmentsForInvoice(SalesInvoiceHeader);

        // [THEN] The Posted Sales Shipments list opens with the two related shipments
        Assert.AreEqual(2, LibraryVariableStorage.DequeueInteger(), PageRowCountErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ShowShipmentsForInvoiceShowsMessageWhenNoShipments()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the shipments of invoice "I" without related shipments shows an informative message
        Initialize();

        // [GIVEN] Sales invoice document with a G/L account line, posted as invoice "I"
        CreateSalesInvoiceWithGLAccount(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Show the shipments related to invoice "I"
        SalesShipmentInvoiceLink.ShowShipmentsForInvoice(SalesInvoiceHeader);

        // [THEN] A message states that there are no posted sales shipments related to invoice "I"
        Assert.AreEqual(StrSubstNo(NoRelatedShipmentsMsg, SalesInvoiceHeader."No."), LibraryVariableStorage.DequeueText(), MessageErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicePageHandler')]
    procedure ShowInvoicesForShipmentOpensInvoiceCardWhenSingleInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the invoices of shipment "S" opens the card of invoice "I" when only one is related
        Initialize();

        // [GIVEN] Sales order with an item line, posted as shipped and invoiced, creating shipment "S" and invoice "I"
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        PostShipAndInvoice(SalesHeader, ShipmentNo, InvoiceNo);
        SalesShipmentHeader.Get(ShipmentNo);

        // [WHEN] Show the invoices related to shipment "S"
        SalesShipmentInvoiceLink.ShowInvoicesForShipment(SalesShipmentHeader);

        // [THEN] The Posted Sales Invoice card for "I" opens
        Assert.AreEqual(InvoiceNo, LibraryVariableStorage.DequeueText(), PageRecordErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicesPageHandler')]
    procedure ShowInvoicesForShipmentOpensInvoiceListWhenMultipleInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the invoices of shipment "S" opens the invoice list when two invoices are related
        Initialize();

        // [GIVEN] Sales order with an item line of quantity 10, fully shipped as "S" and invoiced in two parts
        CreateSalesOrderWithItem(SalesHeader, 10);
        SalesShipmentHeader.Get(PostFullShipment(SalesHeader));
        PostPartialInvoice(SalesHeader, 6);
        PostRemainingInvoice(SalesHeader);

        // [WHEN] Show the invoices related to shipment "S"
        SalesShipmentInvoiceLink.ShowInvoicesForShipment(SalesShipmentHeader);

        // [THEN] The Posted Sales Invoices list opens with the two related invoices
        Assert.AreEqual(2, LibraryVariableStorage.DequeueInteger(), PageRowCountErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ShowInvoicesForShipmentShowsMessageWhenNoInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentInvoiceLink: Codeunit "Sales Shipment-Invoice Link";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the invoices of shipment "S" without related invoices shows an informative message
        Initialize();

        // [GIVEN] Sales order with an item line, posted as shipped only, creating shipment "S"
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        SalesShipmentHeader.Get(PostFullShipment(SalesHeader));

        // [WHEN] Show the invoices related to shipment "S"
        SalesShipmentInvoiceLink.ShowInvoicesForShipment(SalesShipmentHeader);

        // [THEN] A message states that there are no posted sales invoices related to shipment "S"
        Assert.AreEqual(StrSubstNo(NoRelatedInvoicesMsg, SalesShipmentHeader."No."), LibraryVariableStorage.DequeueText(), MessageErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceModalPageHandler')]
    procedure ShowItemSalesInvLinesOpensInvoiceCardWhenSingleInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the invoices of shipment line "SL" opens the card of invoice "I" when only one invoiced it
        Initialize();

        // [GIVEN] Sales order with an item line, posted as shipped and invoiced, creating shipment line "SL" and invoice "I"
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        PostShipAndInvoice(SalesHeader, ShipmentNo, InvoiceNo);
        FindSalesShipmentLine(SalesShipmentLine, ShipmentNo);

        // [WHEN] Show the invoices of shipment line "SL"
        SalesShipmentLine.ShowItemSalesInvLines();

        // [THEN] The Posted Sales Invoice card for "I" opens
        Assert.AreEqual(InvoiceNo, LibraryVariableStorage.DequeueText(), PageRecordErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceLinesModalPageHandler')]
    procedure ShowItemSalesInvLinesOpensInvoiceLinesWhenMultipleInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the invoices of shipment line "SL" opens the invoice lines when two invoices invoiced it
        Initialize();

        // [GIVEN] Sales order with an item line of quantity 10, fully shipped and invoiced in two parts
        CreateSalesOrderWithItem(SalesHeader, 10);
        ShipmentNo := PostFullShipment(SalesHeader);
        PostPartialInvoice(SalesHeader, 6);
        PostRemainingInvoice(SalesHeader);
        FindSalesShipmentLine(SalesShipmentLine, ShipmentNo);

        // [WHEN] Show the invoices of shipment line "SL"
        SalesShipmentLine.ShowItemSalesInvLines();

        // [THEN] The Posted Sales Invoice Lines page opens with the two invoice lines
        Assert.AreEqual(2, LibraryVariableStorage.DequeueInteger(), PageRowCountErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoiceLinesModalPageHandler')]
    procedure ShowItemSalesInvLinesOpensEmptyInvoiceLinesWhenNotInvoiced()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the invoices of a shipment line "SL" that is not invoiced opens an empty invoice lines page
        Initialize();

        // [GIVEN] Sales order with an item line, posted as shipped only, creating shipment line "SL"
        CreateSalesOrderWithItem(SalesHeader, LibraryRandom.RandIntInRange(10, 20));
        ShipmentNo := PostFullShipment(SalesHeader);
        FindSalesShipmentLine(SalesShipmentLine, ShipmentNo);

        // [WHEN] Show the invoices of shipment line "SL"
        SalesShipmentLine.ShowItemSalesInvLines();

        // [THEN] The Posted Sales Invoice Lines page opens without any line
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger(), PageRowCountErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ShowItemSalesInvLinesDoesNothingForNonItemLine()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 339323] Showing the invoices of a shipment line "SL" of type G/L Account does not open any page
        Initialize();

        // [GIVEN] Sales order with a G/L account line, posted as shipped only, creating shipment line "SL"
        CreateSalesOrderWithGLAccount(SalesHeader);
        ShipmentNo := PostFullShipment(SalesHeader);
        FindSalesShipmentLine(SalesShipmentLine, ShipmentNo);
        Assert.AreEqual(SalesShipmentLine.Type::"G/L Account", SalesShipmentLine.Type, PageRecordErr);

        // [WHEN] Show the invoices of shipment line "SL"
        SalesShipmentLine.ShowItemSalesInvLines();

        // [THEN] No page is opened, so no unhandled UI is raised
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Sales Shpt.-Invoice Link Tests");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Sales Shpt.-Invoice Link Tests");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        LibrarySetupStorage.Save(Database::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Sales Shpt.-Invoice Link Tests");
    end;

    local procedure CreateSalesOrderWithItem(var SalesHeader: Record "Sales Header"; Quantity: Decimal)
    begin
        CreateSalesOrderWithItemLines(SalesHeader, 1, Quantity);
    end;

    local procedure CreateSalesOrderWithItemLines(var SalesHeader: Record "Sales Header"; NoOfLines: Integer; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        Index: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        for Index := 1 to NoOfLines do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithInventory(Quantity), Quantity);
    end;

    local procedure CreateSalesOrderWithGLAccount(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithGLAccount(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);
    end;

    local procedure CreateItemWithInventory(Quantity: Decimal): Code[20]
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(Item."No.");
    end;

    local procedure PostShipAndInvoice(var SalesHeader: Record "Sales Header"; var ShipmentNo: Code[20]; var InvoiceNo: Code[20])
    begin
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ShipmentNo := FindShipmentNo(SalesHeader."No.");
    end;

    local procedure PostFullShipment(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure PostPartialShipment(var SalesHeader: Record "Sales Header"; QtyToShip: Decimal): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure PostPartialInvoice(var SalesHeader: Record "Sales Header"; QtyToInvoice: Decimal): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure PostRemainingInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure CreateAndPostInvoiceFromShipmentLines(CustomerNo: Code[20]; ShipmentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; ShipmentNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindShipmentNo(OrderNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure VerifySingleShipment(var SalesShipmentHeader: Record "Sales Shipment Header"; ExpectedShipmentNo: Code[20])
    begin
        Assert.AreEqual(1, SalesShipmentHeader.Count(), ShipmentCountErr);
        SalesShipmentHeader.FindFirst();
        Assert.AreEqual(ExpectedShipmentNo, SalesShipmentHeader."No.", ShipmentNoErr);
    end;

    local procedure VerifySingleInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; ExpectedInvoiceNo: Code[20])
    begin
        Assert.AreEqual(1, SalesInvoiceHeader.Count(), InvoiceCountErr);
        SalesInvoiceHeader.FindFirst();
        Assert.AreEqual(ExpectedInvoiceNo, SalesInvoiceHeader."No.", InvoiceNoErr);
    end;

    [PageHandler]
    procedure PostedSalesShipmentPageHandler(var PostedSalesShipment: TestPage "Posted Sales Shipment")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesShipment."No.".Value());
        PostedSalesShipment.Close();
    end;

    [PageHandler]
    procedure PostedSalesShipmentsPageHandler(var PostedSalesShipments: TestPage "Posted Sales Shipments")
    var
        RowCount: Integer;
    begin
        if PostedSalesShipments.First() then
            repeat
                RowCount += 1;
            until not PostedSalesShipments.Next();
        LibraryVariableStorage.Enqueue(RowCount);
        PostedSalesShipments.Close();
    end;

    [PageHandler]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvoice."No.".Value());
        PostedSalesInvoice.Close();
    end;

    [PageHandler]
    procedure PostedSalesInvoicesPageHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    var
        RowCount: Integer;
    begin
        if PostedSalesInvoices.First() then
            repeat
                RowCount += 1;
            until not PostedSalesInvoices.Next();
        LibraryVariableStorage.Enqueue(RowCount);
        PostedSalesInvoices.Close();
    end;

    [ModalPageHandler]
    procedure PostedSalesInvoiceModalPageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvoice."No.".Value());
    end;

    [ModalPageHandler]
    procedure PostedSalesInvoiceLinesModalPageHandler(var PostedSalesInvoiceLines: TestPage "Posted Sales Invoice Lines")
    var
        RowCount: Integer;
    begin
        if PostedSalesInvoiceLines.First() then
            repeat
                RowCount += 1;
            until not PostedSalesInvoiceLines.Next();
        LibraryVariableStorage.Enqueue(RowCount);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}
