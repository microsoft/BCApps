codeunit 134378 "ERM Sales Order"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Order]
    end;

    var
        TempDocumentEntry2: Record "Document Entry" temporary;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryResource: Codeunit "Library - Resource";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        isInitialized: Boolean;
        VATAmountErr: Label 'VAT Amount must be %1 in %2.', Comment = '%1 = value, %2 = field';
        FieldErr: Label 'Number of Lines for %1 and %2  must be Equal.', Comment = '%1,%2 = table name';
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1 = field, %2 = value, %3  = table';
        CurrencyErr: Label '%1 must be equal in %2.', Comment = '%1 = field, %2 = table';
        IncorrectDimSetIDErr: Label 'Incorrect Dimension Set ID in %1.';
        DocumentNo2: Code[20];
        PostingDate2: Date;
        ValueErr: Label 'Discount Amount must be equal to %1.', Comment = '%1 = value';
        WrongDimValueErr: Label 'Wrong dimension value in Sales Header %1.', Comment = '%1 = value';
        WrongValueSalesHeaderInvoiceErr: Label 'The value of field Invoice in copied Sales Order must be ''No''.';
        WrongValueSalesHeaderShipErr: Label 'The value of field Ship in copied Sales Order must be ''No''.';
        ShippedNotInvoicedErr: Label 'Wrong sales orders shipped not invoiced count';
        WrongInvDiscAmountErr: Label 'Wrong Invoice Discount Amount in Sales Line.';
        QtyToShipBaseErr: Label 'Qty. to Ship (Base) must be equal to Qty. to Shipe in Sales Line';
        QtyToShipUpdateErr: Label 'Qty. to Ship must be equal to %1 in Sales Line';
        ReturnQtyToReceiveBaseErr: Label 'Return Qty. to Receive (Base) must be equal to Return Qty. to Receive in Sales Line';
        QuantitytyToShipBaseErr: Label 'Qty. to Ship (Base) must be equal to Quantity in Sales Line';
        ReturnQuantityToReceiveBaseErr: Label 'Return Qty. to Receive (Base) must be equal to Quantity in Sales Line';
        PostedDocsToPrintCreatedMsg: Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        AmountToAssignErr: Label 'Wrong Amount to Assign on reassigned lines';
        ContactShouldNotBeEditableErr: Label 'Contact should not be editable when customer is not selected.';
        ContactShouldBeEditableErr: Label 'Contact should be editable when customer is selected.';
        BillToAddressFieldsNotEditableErr: Label 'Bill-to address fields should not be editable.';
        BillToAddressFieldsEditableErr: Label 'Bill-to address fields should be editable.';
        SalesLineGetLineAmountToHandleErr: Label 'Incorrect amount returned by SalesLine.GetLineAmountToHandle().';
        QuoteNoMustBeVisibleErr: Label 'Quote No. must be visible.';
        QuoteNoMustNotBeVisibleErr: Label 'Quote No. must not be visible.';
        ConfirmEmptyEmailQst: Label 'Contact %1 has no email address specified. The value in the Email field on the sales order, %2, will be deleted. Do you want to continue?';
        RecreateSalesLinesCancelErr: Label 'Change in the existing sales lines for the field %1 is cancelled by user.';
        RecreateSalesLinesMsg: Label 'the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.';
        RoundingTo0Err: Label 'Rounding of the field';
        CompletelyShippedErr: Label 'Completely Shipped should be yes';
        AdjustedCostChangedMsg: Label 'Adjusted Cost (LCY) has changed.';
        DimensionSetIdHasChangedMsg: Label 'Dimension Set ID has changed on Sales Order';
        CustomerBlockedErr: Label 'You cannot create this type of document when Customer %1 is blocked with type %2';
        UnitPriceMustMatchErr: Label 'Unit Price must match.';
        PlannedShipmentDateErr: Label 'Planned Shipment Date must be %1 in %2.', Comment = '%1= Value ,%2=Table Name.';
        ServiceChargeLineExist: Label 'Service Charge Line exist';
        CorrectPostedSalesInvoiceErr: Label 'Cancelled must be %1 for %2', Comment = '%1= Value ,%2=Table Name';
        SalesLineQtyErr: Label 'Sales Line %1 must be equal to %2', Comment = '%1= Field ,%2= Value';
        OptionString: Option PostedReturnReceipt,PostedInvoices,PostedShipments,PostedCrMemo;
        ConfirmMsg: Label 'The quantity to undo might differ from the original shipment because the invoice was cancelled. Do you want to proceed with the undo?';

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderCreation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test New Sales Order creation.

        // Setup.
        Initialize();

        // Exercise: Create Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine);

        // Verify: Verify Sales Order created.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnSalesOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Create a Sales Order and calculates applicable VAT for a VAT Posting Group in Sales Order.

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine);

        // Exercise: Calculate VAT Amount on Sales Order.
        SalesLine.CalcVATAmountLines(QtyType::Invoicing, SalesHeader, SalesLine, VATAmountLine);

        // Verify: Verify VAT Amount on Sales Order.
        GeneralLedgerSetup.Get();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount);
        Assert.AreNearlyEqual(
          SalesHeader.Amount * SalesLine."VAT %" / 100, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(VATAmountErr, SalesHeader.Amount * SalesLine."VAT %" / 100, VATAmountLine.TableCaption()));

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWhileModifyingLineDuringPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ERMSalesOrder: Codeunit "ERM Sales Order";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 315920] Line is getting refreshed inside posting of Invoice.

        Initialize();
        // [GIVEN] Create Order, where Description is 'A' in the line.
        CreateSalesOrder(SalesHeader, SalesLine);
        SalesLine.Validate(Quantity, 2);
        SalesLine.Validate("Unit Price", 10);
        SalesLine.Validate("Qty. to Invoice", 1);
        SalesLine."Description 2" := 'A';
        SalesLine.Modify(true);

        // [GIVEN] Subscribe to COD80.OnBeforePostUpdateOrderLineModifyTempLine to set Description to 'X'
        BindSubscription(ERMSalesOrder);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Description is still 'A', not changed
        SalesInvoiceLine.Get(PostedDocumentNo, SalesLine."Line No.");
        SalesInvoiceLine.TestField("Description 2", 'A');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderAsShip()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesLineCount: Integer;
        PostedSaleShipmentNo: Code[20];
    begin
        // Check that Posted shipment has same Posted Line after Post Sales Order as Ship.

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLineCount := SalesLine.Count();

        // Exercise: Post Sales Order as Ship.
        PostedSaleShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Sales Shipment Line Count with Sales Line Count.
        SalesShipmentHeader.Get(PostedSaleShipmentNo);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        Assert.AreEqual(SalesLineCount, SalesShipmentLine.Count, StrSubstNo(FieldErr, SalesLine.TableCaption(),
            SalesShipmentLine.TableCaption()));

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderAsInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSaleInvoiceNo: Code[20];
    begin
        // Post a Sales Order as Ship and Invoice and Verify Customer Ledger, GL Entry, Value Entry and VAT Entry.

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine);

        // Exercise: Post Sales Order as Ship and Invoice.
        PostedSaleInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: GL Entry, VAT Entry, Value Entry and Customer Ledger Entry.
        SalesInvoiceHeader.Get(PostedSaleInvoiceNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        VerifyGLEntry(PostedSaleInvoiceNo, SalesInvoiceHeader."Amount Including VAT");
        VerifyCustomerLedgerEntry(PostedSaleInvoiceNo, SalesInvoiceHeader."Amount Including VAT");
        VerifyVATEntry(PostedSaleInvoiceNo, SalesInvoiceHeader."Amount Including VAT");
        VerifyValueEntry(PostedSaleInvoiceNo, SalesInvoiceHeader.Amount);

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderForWarehouseLocation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesShipmentLine: Record "Sales Shipment Line";
        NoSeries: Codeunit "No. Series";
        PostedSaleShipmentNo: Code[20];
    begin
        // Test if Post a Sales Order with Warehouse Location and generate Posted Sales Shipment Entry.

        // Setup
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Exercise: Create Sales Order for Warehouse Location. Using RANDOM Quantity for Sales Line, value is not important.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));

        // Update Sales Line with New Warehouse Location.
        SalesLine.Validate("Location Code", CreateWarehouseLocation());
        SalesLine.Modify(true);
        PostedSaleShipmentNo := NoSeries.PeekNextNo(SalesHeader."Shipping No. Series");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Post Warehouse Document as Ship.
        ShipWarehouseDocument(SalesHeader."No.", SalesLine."Line No.");

        // Verify: Verify Quantity Posted Shipment Document.
        SalesShipmentLine.SetRange("Document No.", PostedSaleShipmentNo);
        SalesShipmentLine.FindFirst();
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(SalesLine."Quantity Shipped", SalesShipmentLine.Quantity, StrSubstNo(FieldErr, SalesLine.TableCaption(),
            SalesShipmentLine.TableCaption()));

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceListLine: Record "Price List Line";
        PostedSaleInvoiceNo: Code[20];
    begin
        // Test Line Discount on Sales Order, Post as Ship and Invoice and Verify Posted GL Entry.

        // Setup: Create Line Discount Setup.
        Initialize();
        PriceListLine.DeleteAll();
        LibrarySales.SetStockoutWarning(false);
        SetupLineDiscount(SalesLineDiscount);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        // Exercise: Create and Post Sales Order with Random Quantity. Take Quantity greater than Sales Line Discount Minimum Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesLineDiscount."Sales Code");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLineDiscount.Code,
          SalesLineDiscount."Minimum Quantity" + LibraryRandom.RandInt(10));

        PostedSaleInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Sales Line and Posted G/L Entry for Line Discount Amount.
        VerifyLineDiscountAmount(
          SalesLine, PostedSaleInvoiceNo, (SalesLine.Quantity * SalesLine."Unit Price") * SalesLineDiscount."Line Discount %" / 100);

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnSalesOrder()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedSaleInvoiceNo: Code[20];
    begin
        // Test Invoice Discount on Sales Order, Post as Ship and Invoice and Verify Posted GL Entry.

        // Setup: Create Invoice Discount Setup.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        SetupInvoiceDiscount(CustInvoiceDisc);

        // Exercise: Create Sales Order, calculate Invoice Discount and Post as Ship and Invoice.
        // Using RANDOM Quantity for Sales Line, value is not important.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustInvoiceDisc.Code);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));

        // Order Value always greater than Minimum Amount of Invoice Discount Setup.
        SalesLine.Validate("Unit Price", CustInvoiceDisc."Minimum Amount");
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount);
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        PostedSaleInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Sales Line and Posted G/L Entry for Invoice Discount Amount.
        VerifyInvoiceDiscountAmount(SalesLine, PostedSaleInvoiceNo,
          (SalesLine.Quantity * SalesLine."Unit Price") * CustInvoiceDisc."Discount %" / 100);

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithFCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSaleInvoiceNo: Code[20];
    begin
        // Test if Post a Sales Order with Currency and generate Posted Sales Invoice Entry.

        // Setup.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Exercise: Create Sales Order, attach new Currency on Sales Order and Post as Ship and Invoice.
        CreateSalesHeaderWithCurrency(SalesHeader, CreateCurrency());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        PostedSaleInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Currency Code in Sales Line and Posted Sales Invoice Header.
        SalesInvoiceHeader.Get(PostedSaleInvoiceNo);
        Assert.AreEqual(SalesHeader."Currency Code", SalesLine."Currency Code",
          StrSubstNo(CurrencyErr, SalesLine.FieldCaption("Currency Code"), SalesLine.TableCaption()));
        Assert.AreEqual(SalesHeader."Currency Code", SalesInvoiceHeader."Currency Code",
          StrSubstNo(CurrencyErr, SalesInvoiceHeader.FieldCaption("Currency Code"), SalesInvoiceHeader.TableCaption()));

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        BatchPostSalesOrders: Report "Batch Post Sales Orders";
        NoSeries: Codeunit "No. Series";
        PostedSaleInvoiceNo: Code[20];
    begin
        // Setup: Create Sales Order.
        Initialize();
        LibrarySales.SetPostWithJobQueue(false);
        LibrarySales.SetStockoutWarning(false);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        PostedSaleInvoiceNo := NoSeries.PeekNextNo(SalesHeader."Posting No. Series");
        Commit();  // Must commit before running this particular batch job

        // Exercise: Batch post sales order.
        SalesHeader.SetRange("No.", SalesHeader."No.");
        BatchPostSalesOrders.InitializeRequest(true, true, WorkDate(), WorkDate(), false, false, false, false);
        BatchPostSalesOrders.SetTableView(SalesHeader);
        BatchPostSalesOrders.UseRequestPage := false;
        BatchPostSalesOrders.Run();

        // Verify: Verify Posted Sales Invoice Header exists.
        Assert.IsTrue(SalesInvoiceHeader.Get(PostedSaleInvoiceNo), 'Unable to find sales invoice header');

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrderBackground()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        BatchPostSalesOrders: Report "Batch Post Sales Orders";
        NoSeries: Codeunit "No. Series";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        PostedSaleInvoiceNo: Code[20];
    begin
        // Setup: Create Sales Order.
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibrarySales.SetStockoutWarning(false);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        PostedSaleInvoiceNo := NoSeries.PeekNextNo(SalesHeader."Posting No. Series");
        Commit();  // Must commit before running this particular batch job

        // Exercise: Batch post sales order.
        SalesHeader.SetRange("No.", SalesHeader."No.");
        BatchPostSalesOrders.InitializeRequest(true, true, WorkDate(), WorkDate(), false, false, false, false);
        BatchPostSalesOrders.SetTableView(SalesHeader);
        BatchPostSalesOrders.UseRequestPage := false;
        BatchPostSalesOrders.Run();
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify: Verify Posted Sales Invoice Header exists.
        Assert.IsTrue(SalesInvoiceHeader.Get(PostedSaleInvoiceNo), 'Unable to find sales invoice header');

        // Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscBeforePartialOrderPost()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
        InvoiceDiscountAmount: Decimal;
    begin
        // Check Invoice Discount Amount on Posting Partial Sales Order.

        // Setup: Create Sales Order with Partial Invoice.
        Initialize();
        CreateAndModifySalesOrder(SalesHeader, SalesLine);
        InvoiceDiscountAmount :=
          SalesLine."Unit Price" * SalesLine."Qty. to Invoice" * FindCustomerInvoiceDiscount(SalesHeader."Sell-to Customer No.") / 100;
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        // Exercise: Post Sales order.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Posted Invoice with Invoice Discount Amount.
        VerifyPostedSalesInvoice(PostedDocumentNo, InvoiceDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAfterPartialOrderPost()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // Check Invoice Discount Amount on Posting Partial Sales Order with Custom values.

        // Setup: Create and Post Sales Order with Partial Invoice.
        Initialize();
        LibrarySales.SetCalcInvDiscount(false);

        CreateAndModifySalesOrder(SalesHeader, SalesLine);
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Modify Sales Line with Custom Invoice Discount and Post it.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.Validate("Inv. Discount Amount", SalesLine."Inv. Discount Amount" + LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Posted Invoice with Invoice Discount Amount.
        VerifyPostedSalesInvoice(PostedDocumentNo, SalesLine."Inv. Discount Amount" / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPartialShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check that Status changes from Open to Released after posting Sales Order with partial Shipment.

        // Setup: Create Sales Header and Sales Line.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // Use Random Number Generator to generate random Quantity.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10) * 2);
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);
        SalesLine.Modify(true);

        // Exercise: Post Sales Order with Partial shipment
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Check that after posting partial shipment Status changes from Open to Raleased.
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountOnSalsInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        LineDiscountAmount: Decimal;
    begin
        // Check Sales Line fields after making Sales Invoice with Currency.

        // Setup.
        Initialize();
        CreateSalesInvoiceWithCurrency(SalesHeader, SalesLine); // Prices Including VAT
        if SalesLine."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesLine."Currency Code");

        // Exercise: Calculate Line Discount Amount on Sales Line.
        LineDiscountAmount :=
          Round(
            Round(SalesLine.Quantity * SalesLine."Unit Price", Currency."Amount Rounding Precision") *
            SalesLine."Line Discount %" / 100, Currency."Amount Rounding Precision");

        // Verify: Verify Line Discount, VAT Base amount on Sales Line.
        SalesLine.TestField("Line Discount Amount", LineDiscountAmount);
        SalesLine.TestField("VAT Base Amount", SalesLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceAfterRelease()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        LineAmount: Decimal;
    begin
        // Check Sales Line fields after making Sales Invoice with Currency and Release.

        // Setup: Calculate VAT Base Amount on Sales Line.
        Initialize();
        CreateSalesInvoiceWithCurrency(SalesHeader, SalesLine); // Prices Including VAT
        if SalesLine."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesLine."Currency Code");

        LineAmount :=
          Round(
            SalesLine."Line Amount" * 100 / (SalesLine."VAT %" + 100), Currency."Amount Rounding Precision");

        // Exericse.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");

        // Verify: Verify Sales Line Fields after Releasing.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("VAT Base Amount", LineAmount);
        SalesLine.TestField(Amount, LineAmount);
        SalesLine.TestField("Amount Including VAT", SalesHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceAfterReopen()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        OutStandingAmountLCY: Decimal;
        LineAmount: Decimal;
    begin
        // Check Sales Line fields after making Sales Invoice with Currency and Reopen for LCY.

        // Setup: Convert Currency in LCY on Sales Line.
        Initialize();
        CreateSalesInvoiceWithCurrency(SalesHeader, SalesLine);
        OutStandingAmountLCY := Round(LibraryERM.ConvertCurrency(SalesLine."Line Amount", SalesHeader."Currency Code", '', WorkDate()));
        if SalesLine."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesLine."Currency Code");

        LineAmount :=
          Round(
            SalesLine."Line Amount" * 100 / (SalesLine."VAT %" + 100), Currency."Amount Rounding Precision");

        // Exercise.
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Verify: Verify Sales Line Field after Releasing and Covert Currency in LCY.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField(Amount, LineAmount);
        SalesLine.TestField("Outstanding Amount (LCY)", OutStandingAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderContactNotEditableBeforeCustomerSelected()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Order Page not editable if no customer selected
        // [Given]
        Initialize();

        // [WHEN] Sales Order page is opened
        SalesOrder.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(SalesOrder."Sell-to Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderContactEditableAfterCustomerSelected()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Order Page editable if customer selected
        // [Given]
        Initialize();

        // [Given] A sample Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // [WHEN] Sales Order page is opened
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(SalesOrder."Sell-to Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceContactNotEditableBeforeCustomerSelected()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Invoice Page not editable if no customer selected
        // [Given]
        Initialize();

        // [WHEN] Sales Invoice page is opened
        SalesInvoice.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(SalesInvoice."Sell-to Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceContactEditableAfterCustomerSelected()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Invoice Page editable if customer selected
        // [Given]
        Initialize();

        // [Given] A sample Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());

        // [WHEN] Sales Invoice page is opened
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(SalesInvoice."Sell-to Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoContactNotEditableBeforeCustomerSelected()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Credit Memo Page not editable if no customer selected
        // [Given]
        Initialize();

        // [WHEN] Sales Credit Memo page is opened
        SalesCreditMemo.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(SalesCreditMemo."Sell-to Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoContactEditableAfterCustomerSelected()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Sales Credit Memo Page editable if customer selected
        // [Given]
        Initialize();

        // [Given] A sample Sales Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer());

        // [WHEN] Sales Credit Memo page is opened
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(SalesCreditMemo."Sell-to Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceBillToAddressFieldsNotEditableIfSameSellToCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Bill-to Address Fields on Sales Order Page not editable if Customer selected equals Bill-to Customer
        // [Given]
        Initialize();

        // [Given] A sample Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // [WHEN] Sales Order page is opened
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] Pay-to Address Fields is not editable
        Assert.IsFalse(SalesOrder."Bill-to Address".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesOrder."Bill-to Address 2".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesOrder."Bill-to City".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesOrder."Bill-to Contact".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesOrder."Bill-to Post Code".Editable(), BillToAddressFieldsNotEditableErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBillToAddressFieldsEditableIfDifferentSellToCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Bill-to Address Fields on Sales Order Page editable if Customer selected not equals Bill-to Customer
        // [Given]
        Initialize();

        // [Given] A sample Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // [WHEN] Sales Order page is opened
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Another Pay-to vendor is picked
        Customer.Get(CreateCustomer());
        SalesOrder."Bill-to Name".SetValue(Customer.Name);

        // [THEN] Pay-to Address Fields is editable
        Assert.IsTrue(SalesOrder."Bill-to Address".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesOrder."Bill-to Address 2".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesOrder."Bill-to City".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesOrder."Bill-to Contact".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesOrder."Bill-to Post Code".Editable(), BillToAddressFieldsEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBillToAddressFieldsNotEditableIfSameSellToCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Bill-to Address Fields on Sales Invoice Page not editable if Customer selected equals Bill-to Customer
        // [Given]
        Initialize();

        // [Given] A sample Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());

        // [WHEN] Sales Invoice page is opened
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] Pay-to Address Fields is not editable
        Assert.IsFalse(SalesInvoice."Bill-to Address".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesInvoice."Bill-to Address 2".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesInvoice."Bill-to City".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesInvoice."Bill-to Contact".Editable(), BillToAddressFieldsNotEditableErr);
        Assert.IsFalse(SalesInvoice."Bill-to Post Code".Editable(), BillToAddressFieldsNotEditableErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderBillToAddressFieldsEditableIfDifferentSellToCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [Scenario] Bill-to Address Fields on Sales Invoice Page editable if Customer selected not equals Bill-to Customer
        // [Given]
        Initialize();

        // [Given] A sample Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());

        // [WHEN] Sales Invoice page is opened
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [WHEN] Another Pay-to vendor is picked
        Customer.Get(CreateCustomer());
        SalesInvoice."Bill-to Name".SetValue(Customer.Name);

        // [THEN] Pay-to Address Fields is editable
        Assert.IsTrue(SalesInvoice."Bill-to Address".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesInvoice."Bill-to Address 2".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesInvoice."Bill-to City".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesInvoice."Bill-to Contact".Editable(), BillToAddressFieldsEditableErr);
        Assert.IsTrue(SalesInvoice."Bill-to Post Code".Editable(), BillToAddressFieldsEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteShippedSalesOrders()
    begin
        // DeleteShippedSalesOrders
        // Tests that execution of report "Delete invoiced sales orders" may not delete sales orders,
        // which are shipped but not invoiced.

        // Setup & Exercise & Verify
        Assert.IsFalse(PrepareAndDeleteSalesOrder(true, false),
          'Shipped and uninvoiced sales order was deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteShippedInvoicedSalOrders()
    begin
        // DeleteShippedInvoicedSalOrders
        // Tests that execution of report "Delete invoiced sales orders" deletes sales orders,
        // which are shipped and invoiced.

        // Setup & Exercise & Verify
        Assert.IsTrue(PrepareAndDeleteSalesOrder(true, true),
          'Shipped and invoiced sales order was not deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteNotShippedSalesOrders()
    begin
        // DeleteNotShippedSalesOrders
        // Tests that execution of report "Delete invoiced sales orders" may NOT delete sales orders,
        // which are not shipped. Even if there exists a similar sales invoice, it is not possible to
        // link a sales order with a sales invoice w/o having shipment lines.

        // Setup & Exercise & Verify
        Assert.IsFalse(PrepareAndDeleteSalesOrder(false, false),
          'Unshipped sales order was deleted');
    end;

    local procedure PrepareAndDeleteSalesOrder(Shipped: Boolean; Invoiced: Boolean): Boolean
    var
        SalesHeader: Record "Sales Header";
        InvSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeleteInvoicedSalesOrders: Report "Delete Invoiced Sales Orders";
        SellToCustomerNo: Code[20];
        SalesHeaderDocNo: Code[20];
    begin
        // PrepareAndDeleteSalesOrder
        // Creates a temporary sales order, post it depending on ship parameter,
        // creates invoice and posting depending on invoice parameter and finally
        // executes the "Delete invoiced sales order" batch job
        // Returns TRUE if the sales order has been deleted, otherwise FALSE.

        // Setup
        Initialize();

        // Prepare:
        // Create sales order
        CreateSalesOrder(SalesHeader, SalesLine);
        SalesHeaderDocNo := SalesHeader."No.";

        // Ship sales order
        if Shipped then
            LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Invoice sales order
        if Invoiced then begin
            // Create an sales invoice and link it to sales order shipment
            InvoiceShippedSalesOrder(InvSalesHeader, SalesHeader);
            // Post sales order as invoiced
            LibrarySales.PostSalesDocument(InvSalesHeader, false, true);
        end;

        // Prepare report execution
        SellToCustomerNo := SalesHeader."Sell-to Customer No.";
        SalesHeader.Reset();
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        DeleteInvoicedSalesOrders.UseRequestPage(false);
        DeleteInvoicedSalesOrders.SetTableView(SalesHeader);

        // Delete - execute report:
        DeleteInvoicedSalesOrders.Run();

        // Return TRUE if sales order was deleted, otherwise FALSE
        exit(SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderDocNo) = false);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Test Navigate functionality for Posted Sales Invoice.

        // 1. Setup. Create Sales Order.
        Initialize();
        InitGlobalVariables();
        LibrarySales.SetStockoutWarning(false);

        // Create Sales Line with Random Quantity.
        CreateSalesOrderWithSingleLine(SalesHeader);

        // 2. Exercise: Post Sales Order as Ship & Invoice and open Navigate form.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();

        // Set global variable for page handler.
        PostingDate2 := SalesInvoiceHeader."Posting Date";
        DocumentNo2 := SalesInvoiceHeader."No.";

        SalesInvoiceHeader.Navigate();

        // 3. Verify: Verify Number of entries for all related tables.
        VerifyPostedEntries(DocumentNo2);

        // 4. Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentNavigate()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // Test Navigate functionality for Posted Sales Shipment.

        // 1. Setup: Create Sales Order.
        Initialize();
        InitGlobalVariables();
        LibrarySales.SetStockoutWarning(false);

        // Create Sales Line with Random Quantity.
        CreateSalesOrderWithSingleLine(SalesHeader);

        // 2. Exercise: Post Sales Order as Ship and open Navigate page.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindSalesShipmentHeader(SalesShipmentHeader, SalesHeader."No.");

        // Set global variable for page handler.
        PostingDate2 := SalesShipmentHeader."Posting Date";
        DocumentNo2 := SalesShipmentHeader."No.";

        SalesShipmentHeader.Navigate();

        // 3. Verify: Verify Number of entries for all related tables.
        ItemLedgerEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"Item Ledger Entry", ItemLedgerEntry.Count);

        // 4. Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test Navigate functionality for Posted Sales Credit Memo.

        // 1. Setup: Create Sales Credit Memo.
        Initialize();
        InitGlobalVariables();
        LibrarySales.SetStockoutWarning(false);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer());

        // Create Sales Line with Random Quantity.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(100, 2));

        // 2. Exercise: Post Sales Credit Memo and open Navigate page.
        LibrarySales.PostSalesDocument(SalesHeader, false, false);
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesCrMemoHeader.FindFirst();

        // Set global variable for page handler.
        PostingDate2 := SalesCrMemoHeader."Posting Date";
        DocumentNo2 := SalesCrMemoHeader."No.";

        SalesCrMemoHeader.Navigate();

        // 3. Verify: Verify Number of entries for all related tables.
        VerifyPostedEntries(DocumentNo2);

        // 4. Tear Down: Cleanup of Setup Done.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure PostedPaymentNavigate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Navigate: Page Navigate;
    begin
        // Test Navigate functionality for Financial Management.

        // 1. Setup. Create General Journal Line.
        Initialize();
        InitGlobalVariables();

        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        UpdateBalanceAccountNo(GenJournalBatch);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CreateCustomer(),
          -LibraryRandom.RandDec(1000, 2)); // Using RANDOM value for Amount.
        UpdateDocumentNo(GenJournalLine);

        // Set global variable for page handler.
        DocumentNo2 := GenJournalLine."Document No.";
        PostingDate2 := GenJournalLine."Posting Date";

        // 2. Exercise: Post General Journal Line and open Navigate page.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Navigate.SetDoc(PostingDate2, DocumentNo2);
        Navigate.Run();

        // 3. Verify: Verify Number of entries for all related tables.
        VerifyPostedPaymentNavigation(DocumentNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalanceLCYOnCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Post a Sales Invoice and see Balance in LCY on Customer.

        // 1. Setup: Create Customer, Sales Header,and Sales Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesHeader."Document Type"::Invoice, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(10, 2));  // Use random quantity of Item as value is not important to test case.

        // 2. Exercise: Post Sales Invoice.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // 3. Verify: Check that the Amount of Invoice matches the Balance (LCY) on Customer.
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        Customer.SetRange("No.", Customer."No.");
        Customer.CalcFields("Balance (LCY)");
        Customer.TestField("Balance (LCY)", SalesInvoiceHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountLCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AmountLCY: Decimal;
    begin
        // Test case to verify Sales Amount(LCY).

        // Setup : Creating Customer,Currency and Sales Order with Random Quantity.
        Initialize();
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithCurrency(CreateCurrency()));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        AmountLCY := Round(LibraryERM.ConvertCurrency(SalesLine."Amount Including VAT", SalesHeader."Currency Code", '', WorkDate()));

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify : Verify Remaining Amount(LCY).
        VerifyRemainingAmountLCY(SalesHeader."Sell-to Customer No.", AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // Test create a Sales Invoice and calculate applicable VAT for a VAT Posting Group in Sales Invoice.

        // 1. Setup: Find a Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // 2. Exercise: Create a Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLines(SalesLine, SalesHeader);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // 3. Verify: Verify VAT Amount on Sales Invoice.
        VerifyVATOnSalesInvoice(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Test post a Sales Invoice and verify Customer Ledger Entry, GL Entry, Value Entry and VAT Entry.
        // Check if system is creating Sales Shipment Line after posting.

        // 1. Setup: Create a Sales Order.
        Initialize();
        LibrarySales.SetCalcInvDiscount(false);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLines(SalesLine, SalesHeader);
        CopySalesLines(TempSalesLine, SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");

        // 2. Exercise: Post Sales Order as Ship and Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify posted Sales Shipment Line, G/L Entry, VAT Entry, Value Entry and Customer Ledger Entry.
        VerifyPostedShipmentLine(TempSalesLine);
        FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."No.");
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyGLEntry(SalesInvoiceHeader."No.", SalesHeader."Amount Including VAT");
        VerifyVATEntry(SalesInvoiceHeader."No.", SalesHeader."Amount Including VAT");
        VerifyCustomerLedgerEntry(SalesInvoiceHeader."No.", SalesHeader."Amount Including VAT");
        VerifyValueEntry(SalesInvoiceHeader."No.", SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Test Line Discount on Sales Invoice.

        // 1. Setup: Setup Line Discount.
        Initialize();
        SetupLineDiscount(SalesLineDiscount);

        // 2. Exercise: Create a Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesLineDiscount."Sales Code");
        SalesLinesWithMinimumQuantity(SalesLine, SalesHeader, SalesLineDiscount);

        // 3. Verify: Verify Sales Line Discount Amount.
        VerifyLineDiscountOnInvoice(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountOnGLEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PriceListLine: Record "Price List Line";
    begin
        // Test post the Sales Invoice and verify GL Entry for the Line Discount Amount.

        // 1. Setup: Setup Line Discount and create a Sales Order.
        Initialize();
        PriceListLine.DeleteAll();
        SetupLineDiscount(SalesLineDiscount);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesLineDiscount."Sales Code");
        SalesLinesWithMinimumQuantity(SalesLine, SalesHeader, SalesLineDiscount);
        CopySalesLines(TempSalesLine, SalesLine);

        // 2. Exercise: Post Sales Order as Ship and Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify that GL Entry exists for the Line Discount on Sales Invoice.
        FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."No.");
        Assert.AreEqual(
          SumLineDiscountAmount(TempSalesLine, SalesHeader."No."), TotalLineDiscountInGLEntry(TempSalesLine, SalesInvoiceHeader."No."),
          StrSubstNo(ValueErr, TempSalesLine.FieldCaption("Line Discount Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // Test Invoice Discount on Sales Invoice.

        // 1. Setup: Setup Invoice Discount.
        Initialize();
        SetupInvoiceDiscount(CustInvoiceDisc);

        // 2. Exercise: Create a Sales Invoice, calculate Invoice Discount.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustInvoiceDisc.Code);
        CreateSalesLines(SalesLine, SalesHeader);
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        // 3. Verify: Verify Invoice Discount Amount.
        VerifyInvoiceDiscountOnInvoice(SalesLine, CustInvoiceDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnGLEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Test Invoice Discount posted in GL Entry for the Sales Invoice.

        // 1. Setup: Setup Invoice Discount and create a Sales Order.
        Initialize();
        SetupInvoiceDiscount(CustInvoiceDisc);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustInvoiceDisc.Code);
        CreateSalesLines(SalesLine, SalesHeader);
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        CopySalesLines(TempSalesLine, SalesLine);

        // 2. Exercise: Post the Sales Order as Ship and Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify the Invoice Discount in GL Entry for the Sales Invoice.
        FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."No.");
        Assert.AreEqual(
          SumInvoiceDiscountAmount(TempSalesLine, SalesHeader."No."),
          TotalInvoiceDiscountInGLEntry(TempSalesLine, SalesInvoiceHeader."No."),
          StrSubstNo(ValueErr, TempSalesLine.FieldCaption("Inv. Discount Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedTextInSaleOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Text: Text[50];
        OldStockoutWarning: Boolean;
    begin
        // Check Extended Text in Sales Orders with Extended Text Line.

        // 1. Setup: Create Customer, Item, Extended Text. Update Stockout Warning field on Sales & Receivables Setup.
        // Create Sales Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Text := CreateItemAndExtendedText(Item);
        UpdateSalesReceivablesSetup(OldStockoutWarning, false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", Item."No.");

        // 2. Exercise: Insert Extended Text in Sales Line.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines."Insert Ext. Texts".Invoke();

        // 3. Verify: Check Desription and No. of Sales Order must match with Extended Text Line.
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        SalesLine.FindFirst();
        SalesLine.TestField(Description, Text);

        // 4. Tear Down: Rollback Stockout Warning field on Sales & Receivables Setup.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPostingDateBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Try to Post a Sales Order with Blank Posting Date.

        // Setup: Create Sales Order with Modified Sales and Receivables Setup.
        Initialize();
        UpdateSalesReceivableSetup();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));

        // Exercise: Try to Post Sales Order.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify posting error message.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("Posting Date"), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentWithDefaultQtyBlank()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify that Qty to Ship in Sales Line is blank after doing Undo shipment when Default Quantity To Ship field is balnk in Sales & Receivable setup.

        // Setup: Update Sales & Receivable setup, Create and post sales order.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Blank);

        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / LibraryRandom.RandIntInRange(2, 4)); // To make sure Qty. to ship must be less than Quantity.
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindSalesShipmentLine(SalesShipmentLine, SalesLine."Document No.");

        // Exercise: Undo sales shipment.
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // Verify: Verify Quantity after Undo Shipment on Posted Sales Shipment And Quantity to Ship is blank on Sales Line.
        VerifyUndoShipmentLineOnPostedShipment(SalesLine);
        VerifyQuantitytoShipOnSalesLine(SalesHeader."No.", SalesHeader."Document Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithGLAccAndUOMDefaultQtyBlank()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Verify that Qty to ship in Sales Line is blank after enering G/L Account with UoM

        // Setup: Update Sales & Receivables setup, Create sales order.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Blank);

        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        // Exercise: create sales line for G/L account and update Unit of Measure
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        SalesLine.Validate("Unit of Measure", UnitOfMeasure.Code);

        // Verify: Verify Quantity to Ship is blank on Sales Line.
        Assert.AreEqual(0, SalesLine."Qty. to Ship", 'qty. to ship should be 0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQuantityIsRoundedTo0OnSalesOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Sales Order Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base values to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Sales Line where the unit of measure code is set to the nonbase unit of measure.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        SalesLine.Modify(true);

        // [Then] Base Quantity rounds to 0 and throws error.
        asserterror SalesLine.Validate(Quantity, 1 / (LibraryRandom.RandIntInRange(100, 1000)));
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyToAssembleToOrderRoundedTo0OnSalesOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;

    begin
        // [FEATURE] [Sales Order Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base values to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Validate("Replenishment System", "Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Sales Line where the unit of measure code is set to the nonbase unit of measure.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        SalesLine.Modify(true);

        // [Then] Base Qty. to Assemble to Order rounds to 0 and throws error.
        asserterror SalesLine.Validate("Qty. to Assemble to Order", 1 / (LibraryRandom.RandIntInRange(100, 1000)));
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyToInvoiceRoundedTo0OnSalesOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;

    begin
        // [FEATURE] [Sales Order Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base values to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Sales Line where the unit of measure code is set to the nonbase unit of measure.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        SalesLine.Modify(true);

        // [Then] Base Qty. to Invoice rounds to 0 and throws error.
        asserterror SalesLine.Validate("Qty. to Invoice", 1 / (LibraryRandom.RandIntInRange(100, 1000)));
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyToShipRoundedTo0OnSalesOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;

    begin
        // [FEATURE] [Sales Order Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base values to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Sales Line where the unit of measure code is set to the nonbase unit of measure.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        SalesLine.Modify(true);

        // [Then] Base Qty. to Ship rounds to 0 and throws error.
        asserterror SalesLine.Validate("Qty. to Ship", 1 / (LibraryRandom.RandIntInRange(100, 1000)));
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseReturnQtyToReceiveRoundedTo0OnSalesOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;

    begin
        // [FEATURE] [Sales Order Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base values to be rounded to 0.
        Initialize();
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Remainder);

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Sales Line where the unit of measure code is set to the nonbase unit of measure.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        SalesLine.Modify(true);

        // [Then] Base "Return Qty. to Receive" to Order rounds to 0 and throws error.
        asserterror SalesLine.Validate("Return Qty. to Receive", 1 / (LibraryRandom.RandIntInRange(100, 1000)));
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseValuesAreRoundedWithRoundingPrecisionSpecifiedOnSalesOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Sales Order Line - Rounding Precision]
        // [SCENARIO] Base values are rounded with the specified rounding precision.
        Initialize();
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Remainder);

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        QtyToSet := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Validate("Replenishment System", "Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Sales Line where the unit of measure code is set to the nonbase unit of measure.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
        SalesLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        SalesLine.Modify(true);

        // [WHEN] Quantity is set to a value that rounds the base quantity
        SalesLine.Validate(Quantity, QtyToSet);
        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), SalesLine."Quantity (Base)", 'Base quantity is not rounded correctly.');

        // [THEN] Qty. to Invoice (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), SalesLine."Qty. to Invoice (Base)", 'Qty. to Invoice (Base) is not rounded correctly.');

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), SalesLine."Qty. to Ship (Base)", 'Qty. to Ship (Base) is not rounded correctly.');

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), SalesLine."Qty. to Asm. to Order (Base)", 'Qty. to Asm. to Order (Base) is not rounded correctly.');

        // [WHEN] "Return Qty. to Receive" is set to a value that rounds the base quantity
        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity);
        // [THEN] "Return Qty. to Receive (Base)" is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), SalesLine."Return Qty. to Receive (Base)", 'Return Qty. to Receive (Base) is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseValuesAreRoundedWithRoundingPrecisionUnspecifiedOnSalesOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Sales Order Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the default rounding precision when rounding precision is not specified.
        Initialize();
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Remainder);

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyToSet := LibraryRandom.RandDec(10, 7);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Validate("Replenishment System", "Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Sales Line where the unit of measure code is set to the nonbase unit of measure.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
        SalesLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        SalesLine.Modify(true);

        // [WHEN] Quantity is set to a value that rounds the base quantity
        SalesLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity (Base) is rounded with the default rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), SalesLine."Quantity (Base)", 'Base qty. is not rounded correctly.');

        // [THEN] Qty. to Invoice (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), SalesLine."Qty. to Invoice (Base)", 'Qty. to Invoice (Base) is not rounded correctly.');

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), SalesLine."Qty. to Ship (Base)", 'Qty. to Ship (Base) is not rounded correctly.');

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), SalesLine."Qty. to Asm. to Order (Base)", 'Qty. to Asm. to Order (Base) is not rounded correctly.');

        // [WHEN] "Return Qty. to Receive" is set to a value that rounds the base quantity
        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity);
        // [THEN] "Return Qty. to Receive (Base)" is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), SalesLine."Return Qty. to Receive (Base)", 'Return Qty. to Receive (Base) is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseValuesAreRoundedWithRoundingPrecisionOnSalesOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Sales Order Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the specified rounding precision.
        Initialize();
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Remainder);

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(5, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        QtyToSet := LibraryRandom.RandDec(10, 7);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Validate("Replenishment System", "Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Sales Line where the unit of measure code is set to the nonbase unit of measure.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
        SalesLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        SalesLine.Modify(true);

        // [WHEN] Quantity is set to a value that rounds the base quantity
        SalesLine.Validate(Quantity, (NonBaseQtyPerUOM - 1) / NonBaseQtyPerUOM);

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(NonBaseQtyPerUOM - 1, SalesLine."Quantity (Base)", 'Base quantity is not rounded correctly.');

        // [THEN] Qty. to Invoice (Base) is rounded with the specified rounding precision
        Assert.AreEqual(NonBaseQtyPerUOM - 1, SalesLine."Qty. to Invoice (Base)", 'Qty. to Invoice (Base) is not rounded correctly.');

        // [THEN] Qty. to Ship (Base) is rounded with the specified rounding precision
        Assert.AreEqual(NonBaseQtyPerUOM - 1, SalesLine."Qty. to Ship (Base)", 'Qty. to Ship (Base) is not rounded correctly.');

        // [THEN] Qty. to Asm. to Order (Base) is rounded with the specified rounding precision
        Assert.AreEqual(NonBaseQtyPerUOM - 1, SalesLine."Qty. to Asm. to Order (Base)", 'Qty. to Asm. to Order (Base) is not rounded correctly.');

        // [WHEN] "Return Qty. to Receive" is set to a value that rounds the base quantity
        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity);
        // [THEN] "Return Qty. to Receive (Base)" is rounded with the specified rounding precision
        Assert.AreEqual(NonBaseQtyPerUOM - 1, SalesLine."Return Qty. to Receive (Base)", 'Return Qty. to Receive (Base) is not rounded correctly.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure QtyToShipBaseInSalesLineIsValidatedWhileDefaultQtyToShipIsRemainder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361537] "Qty. to ship (Base)" in Sales Line is validated while "Default Qty. to Ship" is "Remainder"
        Initialize();

        // [GIVEN] "Default Quantity to Ship" is "Remainder" in Sales and Receivables Setup.
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Remainder);

        // [GIVEN] Sales Line with "Qty. To Ship" = 0.
        Qty := LibraryRandom.RandDec(1000, 2);
        CreateSalesLineWithQty(SalesLine, Qty, SalesHeader."Document Type"::Order);

        // [WHEN] Set "Qty. to Ship" in Sales Order Line to "X"
        SalesLine.Validate("Qty. to Ship", Qty);

        // [THEN] "Qty. to Ship (Base)" in Sales Order Line is "X"
        Assert.AreEqual(Qty, SalesLine."Qty. to Ship (Base)", QtyToShipBaseErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure QtyToShipInSalesLineIsCorrectlyUpdatedWithChangeInQty()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        SalesLine4: Record "Sales Line";
        Item1: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Item4: Record Item;
        Qty: Decimal;
        Loc1: Record Location;
        Loc2: Record Location;
    begin
        Initialize();

        // [GIVEN] "Default Quantity to Ship" is "Remainder" in Sales and Receivables Setup.
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Remainder);
        UpdateDefaultWarehouseSetup(false, true, false, true);

        // [GIVEN] Qty is "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Quote, CreateCustomer());

        // [CASE 1]: Sales Line with non inventory item
        LibraryInventory.CreateNonInventoryTypeItem(Item1);
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, Item1."No.", 0);
        SalesLine1.Validate(Quantity, Qty);

        // [THEN] "Qty. to Ship " in Sales Order Line is "X"
        Assert.AreEqual(Qty, SalesLine1."Qty. to Ship", StrSubstNo(QtyToShipUpdateErr, Qty));

        // [CASE 2]: Sales Line with inventory item, no location
        LibraryInventory.CreateItem(Item2);
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, Item2."No.", 0);
        SalesLine2.Validate(Quantity, Qty);

        // [THEN] "Qty. to Ship " in Sales Order Line is "0"
        Assert.AreEqual(0, SalesLine2."Qty. to Ship", StrSubstNo(QtyToShipUpdateErr, 0));

        //[CASE 3]: Sales Line with inventory item and wharehouse location with pick and shipment true
        LibraryWarehouse.CreateLocationWMS(Loc1, false, false, true, false, true);
        LibraryInventory.CreateItem(Item3);
        LibrarySales.CreateSalesLine(SalesLine3, SalesHeader, SalesLine3.Type::Item, Item3."No.", 0);
        SalesLine3.Validate("Location Code", Loc1.Code);
        SalesLine3.Validate(Quantity, Qty);

        // [THEN] "Qty. to Ship " in Sales Order Line is "0"
        Assert.AreEqual(0, SalesLine3."Qty. to Ship", StrSubstNo(QtyToShipUpdateErr, 0));

        // [CASE 4]: Sales Line with inventory item and wharehouse location with pick and shipment false
        LibraryWarehouse.CreateLocationWMS(Loc2, false, false, false, false, false);
        LibraryInventory.CreateItem(Item4);
        LibrarySales.CreateSalesLine(SalesLine4, SalesHeader, SalesLine4.Type::Item, Item4."No.", 0);
        SalesLine4.Validate("Location Code", Loc2.Code);
        SalesLine4.Validate(Quantity, Qty);

        // [THEN] "Qty. to Ship " in Sales Order Line is "X"
        Assert.AreEqual(Qty, SalesLine4."Qty. to Ship", StrSubstNo(QtyToShipUpdateErr, Qty));

    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure QtyToShipBaseInSalesLineIsValidatedWhileDefaultQtyToShipIsBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361537] "Qty. to ship (Base)" in Sales Line is validated while "Default Qty. to Ship" is "Blank"
        Initialize();

        // [GIVEN] "Default Quantity to Ship" is "Blank" in Sales and Receivables Setup.
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Blank);

        // [GIVEN] Sales Line with "Qty. To Ship" = 0.
        Qty := LibraryRandom.RandDec(1000, 2);
        CreateSalesLineWithQty(SalesLine, Qty, SalesHeader."Document Type"::Order);

        // [WHEN] Set "Qty. to Ship" in Sales Order Line to "X"
        SalesLine.Validate("Qty. to Ship", Qty);

        // [THEN] "Qty. to Ship (Base)" in Sales Order Line is "X"
        Assert.AreEqual(Qty, SalesLine."Qty. to Ship (Base)", QtyToShipBaseErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReturnQtyToReceiveBaseInSalesLineIsValidatedWhileDefaultQtyToShipIsRemainder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361537] "Return Qty. to Receive (Base)" in Sales Line is validated while "Default Qty. to Ship" is "Remainder"
        Initialize();

        // [GIVEN] "Default Quantity to Ship" is "Remainder" in Sales and Receivables Setup.
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Remainder);

        // [GIVEN] Sales Line with "Return Qty. To Receive" = 0.
        Qty := LibraryRandom.RandDec(1000, 2);
        CreateSalesLineWithQty(SalesLine, Qty, SalesHeader."Document Type"::Order);

        // [WHEN] Set "Return Qty. To Receive" in Sales Order Line to "X"
        SalesLine.Validate("Return Qty. to Receive", Qty);

        // [THEN] "Return Qty. To Receive (Base)" in Sales Order Line is "X"
        Assert.AreEqual(Qty, SalesLine."Return Qty. to Receive (Base)", ReturnQtyToReceiveBaseErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReturnQtyToReceiveBaseInSalesLineIsValidatedWhileDefaultQtyToShipIsBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361537] "Return Qty. to Receive (Base)" in Sales Line is validated while "Default Qty. to Ship" is "Blank"
        Initialize();

        // [GIVEN] "Default Quantity to Ship" is "Blank" in Sales and Receivables Setup.
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Blank);

        // [GIVEN] Sales Line with "Return Qty. To Receive" = 0.
        Qty := LibraryRandom.RandDec(1000, 2);
        CreateSalesLineWithQty(SalesLine, Qty, SalesHeader."Document Type"::Order);

        // [WHEN] Set "Return Qty. To Receive" in Sales Order Line to "X"
        SalesLine.Validate("Return Qty. to Receive", Qty);

        // [THEN] "Return Qty. To Receive (Base)" in Sales Order Line is "X"
        Assert.AreEqual(Qty, SalesLine."Return Qty. to Receive (Base)", ReturnQtyToReceiveBaseErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReturnQtyToReceiveBaseInCreditMemoLineIsValidatedWhileDefaultQtyToShipIsRemainder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361731] "Return Qty. to Receive (Base)" in Credit Memo Line is validated while "Default Qty. to Ship" is "Remainder"
        Initialize();

        // [GIVEN] "Default Quantity to Ship" is "Remainder" in Sales and Receivables Setup
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Remainder);

        // [GIVEN] Credit Memo Line with "Quantity" = 0
        CreateSalesLineWithQty(SalesLine, 0, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Set "Quantity" in Sales Order Line to "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        SalesLine.Validate(Quantity, Qty);

        // [THEN] "Return Qty. To Receive (Base)" in Sales Credit Memo Line is "X"
        Assert.AreEqual(Qty, SalesLine."Return Qty. to Receive (Base)", ReturnQuantityToReceiveBaseErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReturnQtyToReceiveBaseInCreditMemoLineIsValidatedWhileDefaultQtyToShipIsBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361731] "Return Qty. to Receive (Base)" in Credit Memo Line is validated while "Default Qty. to Ship" is "Blank"
        Initialize();

        // [GIVEN] "Default Quantity to Ship" is "Receive" in Sales and Receivables Setup
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Blank);

        // [GIVEN] Credit Memo Line with "Quantity" = 0
        CreateSalesLineWithQty(SalesLine, 0, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Set "Quantity" in Sales Order Line to "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        SalesLine.Validate(Quantity, Qty);

        // [THEN] "Return Qty. To Receive (Base)" in Sales Credit Memo Line is "X"
        Assert.AreEqual(Qty, SalesLine."Return Qty. to Receive (Base)", ReturnQuantityToReceiveBaseErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure QtyToShipBaseInInvoiceLineIsValidatedWhileDefaultQtyToShipIsRemainder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361731] "Qty. to Ship (Base)" in Invoice Line is validated while "Default Qty. to Ship" is "Remainder"
        Initialize();

        // [GIVEN] "Default Quantity to Ship" is "Remainder" in Sales and Receivables Setup.
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Remainder);

        // [GIVEN] Invoice Line with "Quantity" = 0.
        CreateSalesLineWithQty(SalesLine, 0, SalesHeader."Document Type"::Invoice);

        // [WHEN] Set "Quantity" in Sales Order Line to "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        SalesLine.Validate(Quantity, Qty);

        // [THEN] "Qty. to Ship (Base) (Base)" in Sales Invoice Line is "X"
        Assert.AreEqual(Qty, SalesLine."Qty. to Ship (Base)", QuantitytyToShipBaseErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure QtyToShipBaseInInvoiceLineIsValidatedWhileDefaultQtyToShipIsBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361731] "Qty. to Ship (Base)" in Invoice Line is validated while "Default Qty. to Ship" is "Blank"
        Initialize();

        // [GIVEN] "Default Quantity to Ship" is "Blank" in Sales and Receivables Setup
        UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Blank);

        // [GIVEN] Invoice Line with "Quantity" = 0
        CreateSalesLineWithQty(SalesLine, 0, SalesHeader."Document Type"::Invoice);

        // [WHEN] Set "Quantity" in Sales Order Line to "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        SalesLine.Validate(Quantity, Qty);

        // [THEN] "Qty. to Ship (Base) (Base)" in Sales Invoice Line is "X"
        Assert.AreEqual(Qty, SalesLine."Qty. to Ship (Base)", QuantitytyToShipBaseErr);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure AddNonInventoryItemToShippingAdviceCompleteSalesOrderWithExistingPick()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        NonInventoryItemItem: Record Item;
        RegularItem: Record Item;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        Initialize();

        // [GIVEN] Sales and Receivables Setup with "Auto Post Non-Invt. via Whse." = "All"
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Auto Post Non-Invt. via Whse.", SalesReceivablesSetup."Auto Post Non-Invt. via Whse."::All);
        SalesReceivablesSetup.Modify();

        //[GIVEN] wharehouse location with pick and put-away true
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, false, false);

        // [GIVEN] Non-Inventory Item and Regular Item with some inventory on location
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItemItem);
        LibraryInventory.CreateItem(RegularItem);
        Qty := LibraryRandom.RandInt(1000);
        CreateItemJournalLinePositiveAdjustment(RegularItem."No.", Qty, Location.Code);

        // [GIVEN] Sales Order with Shipping Advice = Complete and Regular Item Sales Line
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, CreateCustomer());
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader."Shipping Advice" := SalesHeader."Shipping Advice"::Complete;
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, RegularItem."No.", Qty / 2);

        // [GIVEN] Sales Order is released and pick created
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        Commit();
        SalesHeader.CreateInvtPutAwayPick();

        // [WHEN] reopen Sales Order
        Commit();
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [THEN] Add Non-Inventory Item is possible
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, NonInventoryItemItem."No.", LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        Commit();

        // [WHEN] Invt. Pick is registred
        FindWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityLine, DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityHeader.Type::"Invt. Pick");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        PostWhsDocument(WarehouseActivityLine, true, false, false, true, false);

        // [THEN] Complete Sales Order is posted
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.IsTrue(SalesLine.IsEmpty(), 'Sales Line is not empty');
    end;

    [Test]
    [HandlerFunctions('ShipAndInvoiceStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceWithPartialQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check the Quantity on Posted Sales Invoice Line when Sales Order Posted using Sales Order Page.

        // Setup: Create Sales Order with Partial Quantity.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Modify(true);

        // Exercise:  Open Created Sales Header from Sales Order Page and Post using Page.
        OpenSalesOrderAndPost(SalesHeader."No.", SalesHeader.Status);

        // Verify: Verify Quantity on Posted Sales Invoice Line is equal to Sales Line Quantity to Invoice.
        VerifyQuantityOnSalesInvoiceLine(SalesHeader."No.", SalesHeader."Sell-to Customer No.", SalesLine."Qty. to Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNoOverFlowErrorExistOnSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Verify that no Overflow error on sales line with more ranges.

        // Setup. Create Sales order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), LibraryInventory.CreateItem(Item));

        // Exercise: Taken large random values.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(0, 1, 3));
        SalesLine.Validate(Quantity, LibraryRandom.RandIntInRange(10000000, 2147483647));

        // Verify: Verify Sales Line amount.
        Assert.AreEqual(
          Round(SalesLine.Quantity * SalesLine."Unit Price"), SalesLine."Line Amount",
          StrSubstNo(AmountErr, SalesLine.FieldCaption("Line Amount"), SalesLine."Line Amount", SalesLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusOpenErrorWithReleasedSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Verify the Status open error when one more Sales Line added on released Sales Order.

        // Setup: Create released sales order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), LibraryInventory.CreateItem(Item));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise: Add one more sales line.
        asserterror LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type, SalesLine."No.", SalesLine.Quantity);

        // Verify: Verifying Open status error.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithFCYDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AmountLCY: Decimal;
    begin
        // Verify no error will appear while posting a Sales Order with discount on Currency rounding.

        // Setup: Create Sales order with Currency Code.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesHeaderWithCurrency(SalesHeader, CreateAndUpdateCurrency());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));
        AmountLCY := Round(LibraryERM.ConvertCurrency(SalesLine."Amount Including VAT", SalesHeader."Currency Code", '', WorkDate()));

        // Exercise: Post Sales document.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Remaining Amount LCY on Cust. ledger Entry.
        VerifyRemainingAmountLCY(SalesHeader."Sell-to Customer No.", AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesHeaderDimWithSalesPerson()
    var
        SalesHeader: Record "Sales Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // Setup.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code, Dimension.Code, DimensionValue.Code);

        // Exercise.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        SalesHeader.Validate("Salesperson Code", SalespersonPurchaser.Code);
        SalesHeader.Modify(true);

        // Verify.
        VerifySalesHeaderDimensions(SalesHeader, DefaultDimension."Dimension Code");
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CopySalesOrderFromPartialPostingSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        FromSalesOrderNo: Code[20];
    begin
        // [SCENARIO] Verifies Ship and Invoice fiels in document copied for posted Sales Order
        Initialize();
        // [GIVEN] Create Sales Order with two lines
        // [GIVEN] In second line set Qty. to Ship = 0
        // [GIVEN] Release, Post (Ship) and Post (Invoice) sales order
        FromSalesOrderNo := CreatePostSalesOrder();
        // [WHEN] Coping sales order to new sales order
        CreateCopySalesOrder(SalesHeader, FromSalesOrderNo);
        // [THEN] Invoice and Ship fields must not get value from original document
        Assert.IsFalse(SalesHeader.Invoice, WrongValueSalesHeaderInvoiceErr);
        Assert.IsFalse(SalesHeader.Ship, WrongValueSalesHeaderShipErr);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SBOwnerCueSOsNotInvoicedIncrease()
    var
        SalesHeader: Record "Sales Header";
        SBOwnerCue: Record "SB Owner Cue";
        PreviousCount: Integer;
    begin
        // [Cue] [Ship] [Invoice] [UI]
        // [SCENARIO 310657] Shipped Sales Order increases value of "SOs Shipped Not Invoiced" on "Small Business Owner Act." and included in sales order list page opened by drill down
        Initialize();

        // [GIVEN] Shipped X Sales Orders shipped not invoiced
        PreviousCount := SBOwnerCue.CountSalesOrdersShippedNotInvoiced();
        VerifySmallBusinessOwnerActPage(PreviousCount);

        // [WHEN] When one more Sales Order shipped and not invoiced
        ShipSalesOrder(SalesHeader);

        // [THEN] Then "SOs Shipped Not Invoiced" in table "SB Owner Cue" must be equal to X + 1
        Assert.AreEqual(PreviousCount + 1, SBOwnerCue.CountSalesOrdersShippedNotInvoiced(), ShippedNotInvoicedErr);
        VerifySmallBusinessOwnerActPage(PreviousCount + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SBOwnerCueSOsNotInvoicedDecrease()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SBOwnerCue: Record "SB Owner Cue";
        PreviousCount: Integer;
    begin
        // [Cue] [Ship] [Invoice] [UI]
        // [SCENARIO 310657] Separately posted invoice of shipped sales order decreases value of "SOs Shipped Not Invoiced" on "Small Business Owner Act."
        // [SCENARIO 310657] And order is not more included in sales order list page opened by drill down
        Initialize();

        // [GIVEN] Shipped X Sales Orders shipped not invoiced
        PreviousCount := SBOwnerCue.CountSalesOrdersShippedNotInvoiced();
        VerifySmallBusinessOwnerActPage(PreviousCount);

        // [GIVEN] Sales Order shipped and not invoiced. X => incremented by 1
        ShipSalesOrder(SalesHeader);
        Assert.AreEqual(PreviousCount + 1, SBOwnerCue.CountSalesOrdersShippedNotInvoiced(), ShippedNotInvoicedErr);
        VerifySmallBusinessOwnerActPage(PreviousCount + 1);

        // [WHEN] Sales Invoice posted
        InvoiceShippedSalesOrder(SalesHeaderInvoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true);

        // [THEN] Then "SOs Shipped Not Invoiced" in table "SB Owner Cue" must be equal to X
        Assert.AreEqual(PreviousCount, SBOwnerCue.CountSalesOrdersShippedNotInvoiced(), ShippedNotInvoicedErr);
        VerifySmallBusinessOwnerActPage(PreviousCount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreateSalesLineFromSalesShipmentLine()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        ExpectedInvDiscAmount: Decimal;
        InvoiceDiscountValue: Decimal;
    begin
        // [SCENARIO 375185] Invoice Discount is recalculated on Sales Line created from Posted Shipment Line but not in Sales Header
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);
        // [GIVEN] Create sales order and calcucate "Inv. Discount Amount" = "X" excl. VAT
        CreateSalesOrderAndGetDiscountWithoutVAT(SalesHeader);
        // [GIVEN] Set "Prices Including VAT" = TRUE and Ship order
        ExpectedInvDiscAmount := PostShipSalesOrderWithVAT(SalesShipmentLine, SalesHeader);
        // [GIVEN] Create Sales Invoice excl. VAT with "Invoice Discount Value" in Header = "Y"
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesShipmentLine."Bill-to Customer No.");
        CreateSimpleSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        InvoiceDiscountValue := SalesHeader."Invoice Discount Value";
        // [WHEN] Run InsertInvLineFromShptLine on Invoice
        SalesShipmentLine.InsertInvLineFromShptLine(SalesLine);
        // [THEN] Created Sales Line in Invoice, where "Inv. Discount Amount" = "X"
        SalesLine.Find();
        Assert.AreNearlyEqual(
          ExpectedInvDiscAmount, SalesLine."Inv. Discount Amount", LibraryERM.GetAmountRoundingPrecision(), WrongInvDiscAmountErr);
        // [THEN] Invoice Header is not changed, "Invoice Discount Value" = "Y"
        SalesHeader.Find();
        SalesHeader.TestField("Invoice Discount Value", InvoiceDiscountValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAmtAfterGetShipmentLinesAndEnabledCalcDiscSetup()
    var
        SalesHeader: Record "Sales Header";
        NewSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Discount] [Shipment Lines]
        // [SCENARIO 364443] Invoice Discount Amount remains after "Get Shipment Lines" from posted Sales Order. "Sales & Receivables Setup"."Calc. Inv. Discount" = TRUE.
        Initialize();
        UpdateCalcInvDiscountSetup(true);

        // [GIVEN] Create and Ship Sales Order with Invoice Discount Amount = "A"
        ShipSalesOrderWithInvDiscAmount(SalesHeader, SalesLine);

        // [WHEN] Run "Get Shipment Lines" from new Sales Invoice
        InvoiceShippedSalesOrder(NewSalesHeader, SalesHeader);

        // [THEN] Sales Invoice Discount Amount = "A"
        NewSalesHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(
          SalesLine."Inv. Discount Amount",
          NewSalesHeader."Invoice Discount Amount",
          NewSalesHeader.FieldCaption("Invoice Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAmtAfterGetShipmentLinesAndDisabledCalcDiscSetup()
    var
        SalesHeader: Record "Sales Header";
        NewSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Discount] [Shipment Lines]
        // [SCENARIO 364443] Invoice Discount Amount remains after "Get Shipment Lines" from posted Sales Order. "Sales & Receivables Setup"."Calc. Inv. Discount" = FALSE.
        Initialize();
        UpdateCalcInvDiscountSetup(false);

        // [GIVEN] Create and Ship Sales Order with Invoice Discount Amount = "A"
        ShipSalesOrderWithInvDiscAmount(SalesHeader, SalesLine);

        // [WHEN] Run "Get Shipment Lines" from new Sales Invoice
        InvoiceShippedSalesOrder(NewSalesHeader, SalesHeader);

        // [THEN] Sales Invoice Discount Amount = "A"
        NewSalesHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(
          SalesLine."Inv. Discount Amount",
          NewSalesHeader."Invoice Discount Amount",
          NewSalesHeader.FieldCaption("Invoice Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAmtAfterGetReturnReceiptLinesAndEnabledCalcDiscSetup()
    var
        SalesHeader: Record "Sales Header";
        NewSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Discount] [Return Receipt Lines]
        // [SCENARIO 364443] Invoice Discount Amount remains after "Get Return Receipt Lines" from posted Sales Return Order. "Sales & Receivables Setup"."Calc. Inv. Discount" = TRUE.
        Initialize();
        UpdateCalcInvDiscountSetup(true);

        // [GIVEN] Create and Ship Sales Return Order with Invoice Discount Amount = "A"
        ShipSalesReturnOrderWithInvDiscAmount(SalesHeader, SalesLine);

        // [WHEN] Run "Get Return Receipt Lines" from new Sales Credit Memo
        CrMemoShippedSalesReturnOrder(NewSalesHeader, SalesHeader);

        // [THEN] Sales Credit Memo Discount Amount = "A"
        NewSalesHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(
          SalesLine."Inv. Discount Amount",
          NewSalesHeader."Invoice Discount Amount",
          NewSalesHeader.FieldCaption("Invoice Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAmtAfterGetReturnReceiptLinesAndDisabledCalcDiscSetup()
    var
        SalesHeader: Record "Sales Header";
        NewSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Discount] [Return Receipt Lines]
        // [SCENARIO 364443] Invoice Discount Amount remains after "Get Return Receipt Lines" from posted Sales Return Order. "Sales & Receivables Setup"."Calc. Inv. Discount" = FALSE.
        Initialize();
        UpdateCalcInvDiscountSetup(false);

        // [GIVEN] Create and Ship Sales Return Order with Invoice Discount Amount = "A"
        ShipSalesReturnOrderWithInvDiscAmount(SalesHeader, SalesLine);

        // [WHEN] Run "Get Return Receipt Lines" from new Sales Credit Memo
        CrMemoShippedSalesReturnOrder(NewSalesHeader, SalesHeader);

        // [THEN] Sales Credit Memo Discount Amount = "A"
        NewSalesHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(
          SalesLine."Inv. Discount Amount",
          NewSalesHeader."Invoice Discount Amount",
          NewSalesHeader.FieldCaption("Invoice Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoGLEntriesAfterZeroAmountSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 364561] Two G/L Entries with zero amount are created after posting of Sales Invoice with zero amount
        Initialize();

        // [GIVEN] Customer Posting Setup, where "Receivables Account No." = "X", "Sales Account No." = "Y"
        // [WHEN] Post Sales Invoice with zero amount
        DocumentNo := CreatePostSalesInvoiceWithZeroAmount(SalesHeader, SalesLine);

        // [THEN] Two G/L Entries with zero Amount are posted to G/L accounts "X" and "Y"
        FindGLEntry(GLEntry, DocumentNo, GetReceivablesAccountNo(SalesHeader."Bill-to Customer No."));
        Assert.AreEqual(0, GLEntry.Amount, GLEntry.FieldCaption(Amount));

        FindGLEntry(
          GLEntry, DocumentNo,
          GetSalesAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"));
        Assert.AreEqual(0, GLEntry.Amount, GLEntry.FieldCaption(Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLRegInSyncWithCLEAfterZeroAmountSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLRegister: Record "G/L Register";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 364561] G/L Register should be in sync with Vendor Ledger Entry after posting of Sales Invoice with zero amount
        Initialize();

        // [GIVEN] Create Sales Invoice with zero amount
        // [WHEN] Post Sales Invoice
        DocumentNo := CreatePostSalesInvoiceWithZeroAmount(SalesHeader, SalesLine);

        // [THEN] Customer Ledger Entry No. in range ["From Entry No.",..,"To Entry No."] of G/L Register
        FindCustLedgerEntry(CustLedgerEntry, SalesHeader."Bill-to Customer No.", DocumentNo);
        GLRegister.FindLast();
        Assert.IsTrue(
          CustLedgerEntry."Entry No." in [GLRegister."From Entry No." .. GLRegister."To Entry No."],
          CustLedgerEntry.FieldCaption("Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesLineFromShptLineWithDiscountAmount()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        InvoiceDiscountValue: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 158032] Invoice Discount is not recalculated on Sales Line created from Posted Shipment Line if "Sales & Receivables Setup"."Calc. Inv. Discount" = FALSE

        // [GIVEN] Create Sales Order with Customer with Discount percent, set "Invoice Discount Amount" to "Y"
        Initialize();
        LibrarySales.SetCalcInvDiscount(false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerInvDiscount());
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        SalesCalcDiscByType.ApplyInvDiscBasedOnAmt(
          LibraryRandom.RandDecInRange(10, 20, 2), SalesHeader);
        InvoiceDiscountValue := SalesHeader."Invoice Discount Value";

        // [GIVEN] Ship Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");

        // [GIVEN] Create Sales Invoice.
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesShipmentLine."Bill-to Customer No.");
        CreateSimpleSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);

        // [WHEN] Run "Get Shipment Lines".
        SalesShipmentLine.InsertInvLineFromShptLine(SalesLine);
        // [THEN] Sales Invoice "Invoice Discount Amount" = "Y"
        SalesHeader.Find();
        SalesHeader.CalcFields("Invoice Discount Amount");
        SalesHeader.TestField("Invoice Discount Amount", InvoiceDiscountValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CombinedDimOnSalesInvoiceWithItemChargeAssignedOnShpmt()
    var
        ConflictDimension: Record Dimension;
        ItemDimValue: Record "Dimension Value";
        ItemChargeDimValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        DimensionMgt: Codeunit DimensionManagement;
        ConflictDimValue: array[2] of Code[20];
        ExpShortcutDimCode1: Code[20];
        ExpShortcutDimCode2: Code[20];
        DimNo: Option " ",Item,ItemCharge;
        DimSetID: array[10] of Integer;
        ExpectedDimSetID: Integer;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 377443] Posted Sales Invoice with Item Charge should inherit dimensions from assigned Shipment
        Initialize();

        // [GIVEN] Item with Dimension
        CreateDimValues(ConflictDimension, ConflictDimValue);
        CreateDimValue(ItemDimValue);
        CreateDimValue(ItemChargeDimValue);

        // [GIVEN] Sales Shipment with Dimensions
        DimSetID[2] :=
          CreatePostSalesOrderWithDimension(SalesHeader, ItemDimValue, ConflictDimension.Code, ConflictDimValue[DimNo::Item]);

        // [WHEN] Post Sales Invoice for Shipment
        DimSetID[1] :=
          CreatePostInvoiceWithShipmentLines(
            ItemChargeDimValue, ConflictDimension.Code, ConflictDimValue[DimNo::ItemCharge], SalesHeader);

        // [THEN] Value Entry is created with Dimension Set ID inherited from Shipment
        ExpectedDimSetID :=
          DimensionMgt.GetCombinedDimensionSetID(DimSetID, ExpShortcutDimCode1, ExpShortcutDimCode2);
        VerifyDimSetIDOnItemLedgEntry(ExpectedDimSetID);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceForItemChargeWithVATDifferencePostValuesPricesInclVAT()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        ValueEntry: Record "Value Entry";
        SalesInvoiceNo: Code[20];
        MaxVATDifference: Decimal;
        AmountToAssign: Decimal;
    begin
        // [FEATURE] [Statistics] [Item Charge]
        // [SCENARIO 378379] Create Sales Invoice with Item Charge Assignment (Prices Incl. VAT = TRUE), change VAT difference and post
        Initialize();

        // [GIVEN] "Sales & Receivables Setup"."Allow VAT Difference" = TRUE
        // [GIVEN] "General Ledger Setup"."Max. VAT Difference Allowed" = "D"
        MaxVATDifference := EnableVATDiffAmount();
        LibraryVariableStorage.Enqueue(MaxVATDifference);

        // [GIVEN] Sales Invoice ("Prices Incl. VAT" = TRUE) with Item Charge of amount "A" assigned to Posted Sales Order
        // [GIVEN] "VAT Amount" is increased by "D" on "Sales Statistics" page
        // [WHEN] Post Sales Invoice
        PostSalesInvoiceWithItemCharge(SalesInvoiceNo, AmountToAssign, true);

        // [THEN] SalesInvoiceLine.Amount = "A-D"
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Amount, AmountToAssign - MaxVATDifference);

        // [THEN] ValueEntry."Sales Amount (Actual)" = "A-D"
        ValueEntry.SetRange("Document No.", SalesInvoiceNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Sales Amount (Actual)", AmountToAssign - MaxVATDifference);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceForItemChargeWithVATDifferencePostValuesPricesWoVAT()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        ValueEntry: Record "Value Entry";
        SalesInvoiceNo: Code[20];
        MaxVATDifference: Decimal;
        AmountToAssign: Decimal;
    begin
        // [FEATURE] [Statistics] [Item Charge]
        // [SCENARIO 378379] Create Sales Invoice with Item Charge Assignment (Prices Incl. VAT = FALSE), change VAT difference and post
        Initialize();

        // [GIVEN] "Sales & Receivables Setup"."Allow VAT Difference" = TRUE
        // [GIVEN] "General Ledger Setup"."Max. VAT Difference Allowed" = "D"
        MaxVATDifference := EnableVATDiffAmount();
        LibraryVariableStorage.Enqueue(MaxVATDifference);

        // [GIVEN] Sales Invoice ("Prices Incl. VAT" = FALSE) with Item Charge of amount "A" assigned to Posted Sales Order
        // [GIVEN] "VAT Amount" is increased by "D" on "Sales Statistics" page
        // [WHEN] Post Sales Invoice
        PostSalesInvoiceWithItemCharge(SalesInvoiceNo, AmountToAssign, false);

        // [THEN] SalesInvoiceLine.Amount = "A"
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Amount, AmountToAssign);

        // [THEN] ValueEntry."Sales Amount (Actual)" = "A"
        ValueEntry.SetRange("Document No.", SalesInvoiceNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Sales Amount (Actual)", AmountToAssign);
    end;

    [Test]
    [HandlerFunctions('QtyToAssgnItemChargeModalPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSalesInvoicePostingDontClearQtyToAssignInPrimaryDocument()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderInvoice: Record "Sales Header";
        SalesShptLine: Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        UOMMgt: Codeunit "Unit of Measure Management";
        Qty: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Sales Order] [Item Charge] [Get Shipment Lines]
        // [SCENARIO 283749] When Sales order is being invoiced by a separate document (Sales Invoice), Qty. to Assign field in charge assignment (made for initial Sales order) must decrease accordingly.
        Initialize();

        // [GIVEN] Create Sales Order with item and item charge lines. Quantity = 10 for both lines, Unit Cost = 2 LCY.
        Qty := 10;
        UnitCost := 2.0;
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, CreateCustomer());
        CreateSalesLineWithUnitPrice(
          SalesLine, SalesHeaderOrder, SalesLine.Type::Item, CreateItem(), Qty, UnitCost);
        CreateSalesLineWithUnitPrice(
          SalesLine, SalesHeaderOrder, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), Qty, UnitCost);

        // [GIVEN] Open Item Charge Assignment page and set Qty to Assign = 10
        OpenItemChargeAssgnt(SalesLine, true, Qty);

        // [GIVEN] Decrease Qty. to Ship = 10 / 3 = 3.33333 on item charge line.
        SalesLine.Validate("Qty. to Ship", Round(Qty / 3, UOMMgt.QtyRndPrecision()));
        SalesLine.Modify(true);

        // [GIVEN] Post (partialy) Sales Order as Shipment
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Create Sales Invoice with the help of "Get Shipment Lines"
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");
        SalesShptLine.SetRange("Order No.", SalesHeaderOrder."No.");
        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShptLine);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true);

        // [THEN] "Qty. to Assign" = 6.66667 (rounded to 5 digits), "Amount to Assign" = 13.33 LCY (rounded to 2 digits).
        ItemChargeAssignmentSales.SetRange("Document Type", ItemChargeAssignmentSales."Document Type"::Order);
        ItemChargeAssignmentSales.SetRange("Document No.", SalesHeaderOrder."No.");
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.TestField("Qty. to Assign", Round(Qty * 2 / 3, UOMMgt.QtyRndPrecision()));
        ItemChargeAssignmentSales.TestField("Amount to Assign", Round(Qty * UnitCost * 2 / 3, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('QtyToAssgnItemChargeModalPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSalesInvoicePostingClearsQtyToAssignThatIsLessThanAssignedInInvoice()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderInvoice: Record "Sales Header";
        SalesShptLine: Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        Qty: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Sales Order] [Item Charge] [Get Shipment Lines]
        // [SCENARIO 283749] When you invoice Sales order by a separate document, and the quantity of item charge assigned in the invoice is greater than the assigned quantity in the order, this zeroes out Qty. to Assign in the order.
        Initialize();

        Qty := LibraryRandom.RandIntInRange(10, 20);
        UnitCost := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Create Sales Order with item and item charge lines. Quantity = 10 for both lines.
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, CreateCustomer());
        CreateSalesLineWithUnitPrice(
          SalesLine, SalesHeaderOrder, SalesLine.Type::Item, CreateItem(), Qty, UnitCost);
        CreateSalesLineWithUnitPrice(
          SalesLine, SalesHeaderOrder, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), Qty, UnitCost);

        // [GIVEN] Open Item Charge Assignment and set Qty to Assign = 5.
        OpenItemChargeAssgnt(SalesLine, true, Qty / 2);

        // [GIVEN] Receive the Sales order.
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Create Sales Invoice using "Get Shipment Lines".
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");
        SalesShptLine.SetRange("Order No.", SalesHeaderOrder."No.");
        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShptLine);

        // [GIVEN] Open Item Charge Assignment on the invoice line and set "Qty. to Assign" = 10.
        FindSalesLineWithType(
          SalesLine, SalesHeaderInvoice."No.", SalesHeaderInvoice."Document Type", SalesLine.Type::"Charge (Item)");
        OpenItemChargeAssgnt(SalesLine, true, Qty);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true);

        // [THEN] "Qty. to Assign" = 0 on the Sales order line for the item charge.
        ItemChargeAssignmentSales.SetRange("Document Type", ItemChargeAssignmentSales."Document Type"::Order);
        ItemChargeAssignmentSales.SetRange("Document No.", SalesHeaderOrder."No.");
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.TestField("Qty. to Assign", 0);
        ItemChargeAssignmentSales.TestField("Amount to Assign", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure GenBusinessPostingGroupInLinesUpdated()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 164950] Field "Gen. Bus. Posting Group" is updated in lines when user changes it in the document header and Gen. Business Posting Group has "Auto Insert Default" = False

        // [GIVEN] Gen. Bus. Posting Group "B" with "Auto Insert Default" = False,
        Initialize();
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroup."Auto Insert Default" := false;
        GenBusPostingGroup.Modify();
        // [GIVEN] Customer with  "Gen. Bus. Posting Group" = "X",
        // [GIVEN] Sales Order for Customer with one line
        CreateOrderCheckVATSetup(SalesHeader, SalesLine);

        // [WHEN] Validate field "Gen. Bus. Posting Group" = "B" in Sales Order header
        SalesHeader.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);

        // [THEN] field "Gen. Bus. Posting Group" in Sales Order line is "B"
        SalesLine.Find();
        SalesLine.TestField("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure GenBusinessPostingGroupInLinesNotUpdated()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldGenBusPostingGroup: Code[20];
    begin
        // [FEATURE] [UT]

        // [SCENARIO 164950] Field "Gen. Bus. Posting Group" is not updated in lines when user changes it in the document header and chooses "No" in Confirm dialog

        // [GIVEN] Gen. Bus. Posting Group "B" with "Auto Insert Default" = False,
        Initialize();
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroup."Auto Insert Default" := false;
        GenBusPostingGroup.Modify();

        // [GIVEN] Customer with  "Gen. Bus. Posting Group" = "X",
        // [GIVEN] Sales Order for Customer with one line
        CreateOrderCheckVATSetup(SalesHeader, SalesLine);
        OldGenBusPostingGroup := SalesLine."Gen. Bus. Posting Group";
        Commit();

        // [WHEN] Validate field "Gen. Bus. Posting Group" = "B" in Sales Order header
        asserterror SalesHeader.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);

        // [THEN] field "Gen. Bus. Posting Group" in Sales Order line is not changed because of error message
        Assert.ExpectedError(StrSubstNo(RecreateSalesLinesCancelErr, SalesLine.FieldCaption("Gen. Bus. Posting Group")));
        SalesLine.Find();
        SalesLine.TestField("Gen. Bus. Posting Group", OldGenBusPostingGroup);
    end;

    [Test]
    [HandlerFunctions('ExactMessageHandler')]
    [Scope('OnPrem')]
    procedure PostedDocToPrintMessageRaisedWhenDeleteSalesInvithNoInPostedInvoiceNos()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 379123] Message raised when delete Sales Invoice with "Posted Invoice Nos." = "Invoice Nos."

        Initialize();
        // [GIVEN] Purchase Invoice with "Posting No. Series" = "No. Series"
        SalesReceivablesSetup.Get();
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, '');
        SalesHeader.Validate("No. Series", SalesReceivablesSetup."Posted Invoice Nos.");
        SalesHeader.Validate("Posting No. Series", SalesReceivablesSetup."Posted Invoice Nos.");
        SalesHeader.Modify(true);
        LibraryVariableStorage.Enqueue(PostedDocsToPrintCreatedMsg);

        // [WHEN] Delete Sales Invoice
        SalesHeader.Delete(true);

        // [THEN] Message "One or more documents have been posted during deletion which you can print" was raised
        // Verification done in ExactMessageHandler
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderEquallyItemChargeAssignment()
    var
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        AmountToAssign: Decimal;
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 379418] Equally Item Charge Assignment line Amount to Assign calculation
        Initialize();

        // [GIVEN] Sales Order with 3 item lines and equally assigned item charge line (Suggest Choice = 1 - Equally)
        // [GIVEN] AmountToAssign = "A", QtyToAssign = "Q"
        SalesOrderItemChargeAssignment(SalesLine, AmountToAssign, QtyToAssign, 1);

        // [WHEN] Reassign all qty "Q" to one line
        AssignQtyToOneLine(ItemChargeAssignmentSales, SalesLine, QtyToAssign);

        // [THEN] Amount to Assign is equal "A"
        ItemChargeAssignmentSales.CalcSums("Amount to Assign");
        Assert.AreEqual(AmountToAssign, ItemChargeAssignmentSales."Amount to Assign", AmountToAssignErr);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderAmountItemChargeAssignment()
    var
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        AmountToAssign: Decimal;
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 379418] Item Charge Assignment by amount line Amount to Assign calculation
        Initialize();

        // [GIVEN] Sales Order with 3 item lines and assigned item charge line by amount (Suggest Choice = 2 - Amount)
        // [GIVEN] AmountToAssign = "A", QtyToAssign = "Q"
        SalesOrderItemChargeAssignment(SalesLine, AmountToAssign, QtyToAssign, 2);

        // [WHEN] Reassign all qty "Q" to one line
        AssignQtyToOneLine(ItemChargeAssignmentSales, SalesLine, QtyToAssign);

        // [THEN] Amount to Assign is equal "A"
        ItemChargeAssignmentSales.CalcSums("Amount to Assign");
        Assert.AreEqual(AmountToAssign, ItemChargeAssignmentSales."Amount to Assign", AmountToAssignErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByDescription_GLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By Description] [G/L Account]
        // [SCENARIO 203978] Sales Line's G/L Account validation can be done using "Description" field
        // [SCENARIO 252065]
        Initialize();
        No := 'GLACC_TEST_GLACC';
        Description := 'Description(Test)Description';

        // [GIVEN] G/L Account "GLACC" with "Name" = "(Desc)"
        MockGLAccountWithNoAndDescription(No, Description);

        // [GIVEN] Sales order line, "Type" = "G/L Account"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");

        // [WHEN] Validate sales line's "Description" = "glacc"/"(desc)"/"glac"/"(des"/"acc"/"esc)"/"xesc)"
        // [THEN] Sales line's: "No." = "GLACC", "Description" = "(Desc)"
        VerifySalesLineFindRecordByDescription(SalesLine, 'glacc_test_glacc', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'glacc_test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test_glacc', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'discriptyon(tezt)discriptyon', No, Description);

        // Tear down
        GLAccount.Get(No);
        GLAccount.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByDescription_Item()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By Description] [Item]
        // [SCENARIO 203978] Sales Line's Item validation can be done using "Description" field
        // [SCENARIO 252065]
        Initialize();
        No := 'ITEM_TEST_ITEM';
        Description := 'Description(Test)Description';

        // [GIVEN] Item "ITEM" with "Description" = "(Desc)"
        MockItemWithNoAndDescription(No, Description);
        // [GIVEN] Sales order line, "Type" = "Item"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // [WHEN] Validate sales line's "Description" = "item"/"desc"/"ite"/"des"/"tem"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "ITEM", "Description" = "(Desc)"
        VerifySalesLineFindRecordByDescription(SalesLine, 'item_test_item', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'item_test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test_item', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'discriptyon(tezt)discriptyon', No, Description);

        // Tear down
        Item.Get(No);
        Item.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByDescription_ItemCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCharge: Record "Item Charge";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By Description] [Item Charge]
        // [SCENARIO 203978] Sales Line's Item Charge validation can be done using "Description" field
        // [SCENARIO 252065]
        Initialize();
        No := 'ITEMCH_TEST_ITEMCH';
        Description := 'Description(Test)Description';

        // [GIVEN] Item Charge "ITEMCHARGE" with "Description" = "(Desc)"
        MockItemChargeWithNoAndDescription(No, Description);
        // [GIVEN] Sales order line, "Type" = "Charge (Item)"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::"Charge (Item)");

        // [WHEN] Validate sales line's "Description" = "itemcharge"/"desc"/"itemch"/"des"/"charge"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "ITEMCHARGE", "Description" = "(Desc)"
        VerifySalesLineFindRecordByDescription(SalesLine, 'itemch_test_itemch', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'itemch_test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test_itemch', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'discriptyon(tezt)discriptyon', No, Description);

        // Tear down
        ItemCharge.Get(No);
        ItemCharge.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByDescription_FixedAsset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FixedAsset: Record "Fixed Asset";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By Description] [Fixed Asset]
        // [SCENARIO 203978] Sales Line's Fixed Asset validation can be done using "Description" field
        // [SCENARIO 252065]
        Initialize();
        No := 'FA_TEST_FA';
        Description := 'Description(Test)Description';

        // [GIVEN] Fixed Asset "FIXEDASSET" with "Description" = "(Desc)"
        MockFAWithNoAndDescription(No, Description);
        // [GIVEN] Sales order line, "Type" = "Fixed Asset"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::"Fixed Asset");

        // [WHEN] Validate sales line's "Description" = "fixedasset"/"desc"/"fixed"/"des"/"asset"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "FIXEDASSET", "Description" = "(Desc)"
        VerifySalesLineFindRecordByDescription(SalesLine, 'fa_test_fa', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'fa_test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test_fa', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'discriptyon(tezt)discriptyon', No, Description);

        // Tear down
        FixedAsset.Get(No);
        FixedAsset.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByDescription_Resource()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By Description] [Resource]
        // [SCENARIO 203978] Sales Line's Resource validation can be done using "Description" field
        // [SCENARIO 252065]
        Initialize();
        No := 'RES_TEST_RES';
        Description := 'Description(Test)Description';

        // [GIVEN] Resource "RESOURCE" with "Description" = "(Desc)"
        MockResourceWithNoAndDescription(No, Description);
        // [GIVEN] Sales order line, "Type" = "Resource"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Resource);

        // [WHEN] Validate sales line's "Description" = "resource"/"desc"/"res"/"des"/"ource"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "RESOURCE", "Description" = "(Desc)"
        VerifySalesLineFindRecordByDescription(SalesLine, 'res_test_res', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'res_test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test_res', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'test)description', No, Description);
        VerifySalesLineFindRecordByDescription(SalesLine, 'discriptyon(tezt)discriptyon', No, Description);

        // Tear down
        Resource.Get(No);
        Resource.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByDescription_StandardText_Negative()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StandardText: Record "Standard Text";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By Description] [Standard Text]
        // [SCENARIO 222522] Sales Line's Standard Text validation can not be done using "Description" field.
        // [SCENARIO 222522] Typed value remains in the "Description" field with empty "Type", "No." values.
        // [SCENARIO 252065]
        Initialize();
        No := 'STDTEXT_TEST_STDTEXT';
        Description := 'Description(Test)Description';

        // [GIVEN] Standard Text "STDTEXT" with "Description" = "(Desc)"
        MockStandardText(No, Description);
        // [GIVEN] Sales order line, "Type" = ""
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);

        // [WHEN] Validate sales line's "Description" = "stdtext"/"desc"/"stdte"/"des"/"tdtext"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "", "Description" = "stdtext"/"desc"/"stdte"/"des"/"tdtext"/"esc"/"xesc"
        VerifySalesLineFindRecordByDescription(SalesLine, 'stdtext_test_stdtext', '', 'stdtext_test_stdtext');
        VerifySalesLineFindRecordByDescription(SalesLine, 'description(test)des', '', 'description(test)des');
        VerifySalesLineFindRecordByDescription(SalesLine, 'stdtext_test', '', 'stdtext_test');
        VerifySalesLineFindRecordByDescription(SalesLine, 'test_stdtext', '', 'test_stdtext');
        VerifySalesLineFindRecordByDescription(SalesLine, 'test)description', '', 'test)description');
        VerifySalesLineFindRecordByDescription(SalesLine, 'tdtext_test_stdtex', '', 'tdtext_test_stdtex');
        VerifySalesLineFindRecordByDescription(SalesLine, 'ription(test)descrip', '', 'ription(test)descrip');

        // Tear down
        StandardText.Get(No);
        StandardText.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByNo_GLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By No] [G/L Account]
        // [SCENARIO 215821] Sales Line's G/L Account validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'GLACC_TEST_GLACC';
        Description := 'Description(Test)Description';

        // [GIVEN] G/L Account "GLACC" with "Name" = "(Desc)"
        MockGLAccountWithNoAndDescription(No, Description);
        // [GIVEN] Sales order line, "Type" = "G/L Account"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");

        // [WHEN] Validate sales line's "Description" = "glacc"/"(desc)"/"glac"/"(des"/"acc"/"esc)"/"xesc)"
        // [THEN] Sales line's: "No." = "GLACC", "Description" = "(Desc)"
        VerifySalesLineFindRecordByNo(SalesLine, 'glacc_test_glacc', No, Description);

        // Tear down
        GLAccount.Get(No);
        GLAccount.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByNo_Item()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By No] [Item]
        // [SCENARIO 215821] Sales Line's Item validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'ITEM_TEST_ITEM';
        Description := 'Description(Test)Description';

        // [GIVEN] Item "ITEM" with "Description" = "(Desc)"
        MockItemWithNoAndDescription(No, Description);
        // [GIVEN] Sales order line, "Type" = "Item"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // [WHEN] Validate sales line's "Description" = "item"/"desc"/"ite"/"des"/"tem"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "ITEM", "Description" = "(Desc)"
        VerifySalesLineFindRecordByNo(SalesLine, 'item_test_item', No, Description);

        // Tear down
        Item.Get(No);
        Item.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByNo_ItemCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCharge: Record "Item Charge";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By No] [Item Charge]
        // [SCENARIO 215821] Sales Line's Item Charge validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'ITEMCH_TEST_ITEMCH';
        Description := 'Description(Test)Description';

        // [GIVEN] Item Charge "ITEMCHARGE" with "Description" = "(Desc)"
        MockItemChargeWithNoAndDescription(No, Description);
        // [GIVEN] Sales order line, "Type" = "Charge (Item)"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::"Charge (Item)");

        // [WHEN] Validate sales line's "Description" = "itemcharge"/"desc"/"itemch"/"des"/"charge"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "ITEMCHARGE", "Description" = "(Desc)"
        VerifySalesLineFindRecordByNo(SalesLine, 'itemch_test_itemch', No, Description);

        // Tear down
        ItemCharge.Get(No);
        ItemCharge.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByNo_FixedAsset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FixedAsset: Record "Fixed Asset";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By No] [Fixed Asset]
        // [SCENARIO 215821] Sales Line's Fixed Asset validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'FA_TEST_FA';
        Description := 'Description(Test)Description';

        // [GIVEN] Fixed Asset "FIXEDASSET" with "Description" = "(Desc)"
        MockFAWithNoAndDescription(No, Description);
        // [GIVEN] Sales order line, "Type" = "Fixed Asset"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::"Fixed Asset");

        // [WHEN] Validate sales line's "Description" = "fixedasset"/"desc"/"fixed"/"des"/"asset"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "FIXEDASSET", "Description" = "(Desc)"
        VerifySalesLineFindRecordByNo(SalesLine, 'fa_test_fa', No, Description);

        // Tear down
        FixedAsset.Get(No);
        FixedAsset.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByNo_Resource()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By No] [Resource]
        // [SCENARIO 215821] Sales Line's Resource validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'RES_TEST_RES';
        Description := 'Description(Test)Description';

        // [GIVEN] Resource "RESOURCE" with "Description" = "(Desc)"
        MockResourceWithNoAndDescription(No, Description);
        // [GIVEN] Sales order line, "Type" = "Resource"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Resource);

        // [WHEN] Validate sales line's "Description" = "resource"/"desc"/"res"/"des"/"ource"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "RESOURCE", "Description" = "(Desc)"
        VerifySalesLineFindRecordByNo(SalesLine, 'res_test_res', No, Description);

        // Tear down
        Resource.Get(No);
        Resource.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLine_FindRecordByNo_StandardText()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StandardText: Record "Standard Text";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By No] [Standard Text]
        // [SCENARIO 222522] Sales Line's Standard Text validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'STDTEXT_TEST_STDTEXT';
        Description := 'Description(Test)Description';

        // [GIVEN] Standard Text "STDTEXT" with "Description" = "(Desc)"
        MockStandardText(No, Description);
        // [GIVEN] Sales order line, "Type" = ""
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);

        // [WHEN] Validate sales line's "Description" = "stdtext"/"desc"/"stdte"/"des"/"tdtext"/"esc"/"xesc"
        // [THEN] Sales line's: "No." = "STDTEXT", "Description" = "(Desc)"
        VerifySalesLineFindRecordByNo(SalesLine, 'stdtext_test_stdtext', No, Description);

        // Tear down
        StandardText.Get(No);
        StandardText.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesHeaderUpdatedWithNoShippedNotInvoicedLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [GIVEN] Prepared Sales Header with one Sales Header with Value,Quantity,VAT
        InitNotInvoicedData(SalesHeader, SalesLine, 800, 10, 0);

        // [WHEN] Set that nothing was shipped yet
        SalesLine."Quantity Shipped" := 0;

        // [THEN] Recalculate amount on Header and compare it with exact amount
        VerifyNotInvoicedData(SalesHeader, SalesLine, 0, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesHeaderUpdatedWithPartiallyShippedNotInvoicedLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLineTest: Record "Sales Line";
        NrOfNotInvoiced: Decimal;
        AmountExclVAT: Decimal;
    begin
        // [GIVEN] Prepared Sales Header with one Sales Header with Value,Quantity,VAT
        InitNotInvoicedData(SalesHeader, SalesLineTest, 800, 10, 10);

        // [WHEN] Set some partial amount as shipped
        NrOfNotInvoiced := LibraryRandom.RandIntInRange(1, 9);
        SalesLineTest."Quantity Shipped" := NrOfNotInvoiced;

        // [THEN] Recalculate amount on Header and compare it with exact amount
        AmountExclVAT := 800 * NrOfNotInvoiced;
        VerifyNotInvoicedData(SalesHeader, SalesLineTest, AmountExclVAT, AmountExclVAT * 1.1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesHeaderUpdateWithFullyShippedInvoicedLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [GIVEN] Prepared Sales Header with one Sales Header with Value,Quantity,VAT
        InitNotInvoicedData(SalesHeader, SalesLine, 1, 10, 100);

        // [WHEN] Set all items are shipped
        SalesLine."Quantity Shipped" := 10;

        // [THEN] Recalculate amount on Header and compare it with exact amount
        VerifyNotInvoicedData(SalesHeader, SalesLine, 10, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountToHandleRecalculatesBasedOnQtyAndPrice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211691] "Line Amount" recalculates by GetLineAmountToHandle function of table "Sales Line" based on current Quantity and "Unit Price"

        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 3);
        SalesLine."Unit Price" := 41.68;
        SalesLine."Line Discount %" := 10;
        SalesLine."Line Discount Amount" := 8.34;

        // "Line Amount" = "Qty. To Handle" * "Unit Price" = 2 * 41.68 = 83.36
        // "Line Discount Amount" = ROUND("Line Amount " * "Line Discount %" / 100) = 83.36 * 10 / 100 = ROUND(8.336) = 8.34
        // "Line Amount To Handle" = "Line Amount" - "Line Discount Amount" = 83.36 - 8.34 = 75.02
        Assert.AreEqual(75.02, SalesLine.GetLineAmountToHandle(2), SalesLineGetLineAmountToHandleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountToHandleRoundingWithIntegerPrecision()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 261533] "Line Amount" recalculates by GetLineAmountToHandle function of table "Sales Line" based on current Quantity and "Unit Price"
        // [SCENARIO 261533] in case of integer Amount Rounding Precision, rounding of partial Quantity
        Initialize();
        LibraryERM.SetAmountRoundingPrecision(1);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 48);
        SalesLine."Unit Price" := 6706996.8;

        // "Line Amount" = ROUND("Qty. To Handle" * "Unit Price") = ROUND(37 * 6706996.8) = ROUND(248158881,6) = 248158882
        Assert.AreEqual(248158882, SalesLine.GetLineAmountToHandle(37), SalesLineGetLineAmountToHandleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountToHandleRoundingWithIntegerPrecisionAndPrepmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Prepayment]
        // [SCENARIO 261533] "Line Amount" recalculates by GetLineAmountToHandle function of table "Sales Line" based on current Quantity and "Unit Price"
        // [SCENARIO 261533] in case of integer Amount Rounding Precision, rounding of partial Quantity, prepayment
        Initialize();
        LibraryERM.SetAmountRoundingPrecision(1);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 48);
        SalesLine."Unit Price" := 6706996.8;
        SalesLine."Prepmt Amt to Deduct" := 1;

        // TempTotalLineAmount = ROUND(Quantity * "Unit Price") = ROUND(48 * 6706996.8) = ROUND(321935846,4) = 321935846
        // "Line Amount" = ROUND("Qty. To Handle" * TempTotalLineAmount / Quantity) = ROUND(37 * 321935846 / 48) = ROUND(248158881,29) = 248158881
        Assert.AreEqual(248158881, SalesLine.GetLineAmountToHandle(37), SalesLineGetLineAmountToHandleErr);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsUpdateInvDiscontAndTotalVATHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithChangedVATAmountAndInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        VATDiffAmount: Decimal;
        InvDiscAmount: Decimal;
        ExpectedVATAmount: Decimal;
        AmountToPost: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Statistics] [VAT Difference] [Invoice Discount]
        // [SCENARIO 215643] Cassie can adjust Invoice Discount at invoice tab of Sales Order statistics page and can update Total VAT amount on VAT Amount lines.
        // [SCENARIO 215643] Changed amounts are reflected on totals subform of sales order and are reflected at posted VAT, Customer Ledger Entries.
        Initialize();

        // [GIVEN] System setup allows Invoice Discount and Max. VAT Difference = 10
        VATDiffAmount := EnableVATDiffAmount();
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Sales Order with Amount = 100 and VAT % = 10
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        AmountToPost := Round(SalesLine.Amount / 10, 1);
        InvDiscAmount := SalesLine.Amount - AmountToPost;
        ExpectedVATAmount := Round(AmountToPost * SalesLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision()) + VATDiffAmount;

        // [GIVEN] Cassie changed Invoice Discount to 90 => calculated VAT amount = 1 ((100 - 90) * VAT%)  at statistics page
        // [GIVEN] Cassie updated Total VAT = 4 => "VAT Difference" = 3
        LibraryVariableStorage.Enqueue(InvDiscAmount);
        LibraryVariableStorage.Enqueue(VATDiffAmount);

        SalesHeader.SetRecFilter();
        UpdateInvoiceDiscountAndVATAmountOnSalesOrderStatistics(
          SalesHeader, SalesLine, AmountToPost, ExpectedVATAmount, VATDiffAmount);

        // [WHEN] Post sales order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Two VAT Entries posted
        // [THEN] "VAT Entry"[1].Base = 90 and "VAT Entry"[1].Amount = 9
        // [THEN] "VAT Entry"[2].Base = -100 and "VAT Entry"[2].Amount = -13 = -(100 * 10 % + 3)
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
        VerifyVATEntryAmounts(
          VATEntry,
          InvDiscAmount,
          Round(InvDiscAmount * SalesLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision()));
        VATEntry.Next();
        VerifyVATEntryAmounts(
          VATEntry,
          -(InvDiscAmount + AmountToPost),
          -(Round((InvDiscAmount + AmountToPost) * SalesLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision()) + VATDiffAmount));
        Assert.RecordCount(VATEntry, 2);

        // [THEN] Customer Ledger Entry with Amount = 14 = 100 - 90 + 4, "Purchase (LCY)" = 10 and "Inv. Discount (LCY)" = 90 posted
        FindCustLedgerEntry(CustLedgerEntry, SalesHeader."Sell-to Customer No.", DocumentNo);

        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, SalesLine."Amount Including VAT");
        CustLedgerEntry.TestField("Sales (LCY)", AmountToPost);
        CustLedgerEntry.TestField("Inv. Discount (LCY)", InvDiscAmount);
    end;

    [Obsolete('The sales statisticss action opens the page non-modally.', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TotalAmountIncVATOnSalesInvoiceSubformWithVATDifference()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        MaxVATDifference: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
    begin
        // [FEATURE] [Statistics] [VAT Difference]
        // [SCENARIO 224140] Totals on sales invoice page has correct values in invoice with VAT Difference
        Initialize();

        // [GIVEN] VAT Difference is allowed
        MaxVATDifference := EnableVATDiffAmount();
        VATDifference := LibraryRandom.RandDecInDecimalRange(0.01, MaxVATDifference, 2);
        LibraryVariableStorage.Enqueue(VATDifference);

        // [GIVEN] Sales Invoice with Amount = 4000, Amount Incl. VAT = 5000
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        Amount := SalesLine.Amount;
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;

        // [WHEN] Add "VAT Difference" = 1 in SalesStatisticHandler
        // [THEN] Page total contains right values of "Total Amount Excl. VAT", "Total VAT", "Total Incl. VAT" on lines subpage before and after Release document
        // [THEN] "Total Amount Excl. VAT" = 4000 in "Sales Line"
        // [THEN] "Total VAT" = 1001 in "Sales Line"
        // [THEN] "Total Incl. VAT" = 5001 in "Sales Line"
        UpdateInvoiceDiscountAndVATAmountOnStatistics(SalesHeader, SalesLine, Amount, VATAmount + VATDifference, VATDifference);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsUpdateInvDiscontAndTotalVATHandlerNM,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithChangedVATAmountAndInvoiceDiscountNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        VATDiffAmount: Decimal;
        InvDiscAmount: Decimal;
        ExpectedVATAmount: Decimal;
        AmountToPost: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Statistics] [VAT Difference] [Invoice Discount]
        // [SCENARIO 215643] Cassie can adjust Invoice Discount at invoice tab of Sales Order statistics page and can update Total VAT amount on VAT Amount lines.
        // [SCENARIO 215643] Changed amounts are reflected on totals subform of sales order and are reflected at posted VAT, Customer Ledger Entries.
        Initialize();

        // [GIVEN] System setup allows Invoice Discount and Max. VAT Difference = 10
        VATDiffAmount := EnableVATDiffAmount();
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Sales Order with Amount = 100 and VAT % = 10
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        AmountToPost := Round(SalesLine.Amount / 10, 1);
        InvDiscAmount := SalesLine.Amount - AmountToPost;
        ExpectedVATAmount := Round(AmountToPost * SalesLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision()) + VATDiffAmount;

        // [GIVEN] Cassie changed Invoice Discount to 90 => calculated VAT amount = 1 ((100 - 90) * VAT%)  at statistics page
        // [GIVEN] Cassie updated Total VAT = 4 => "VAT Difference" = 3
        LibraryVariableStorage.Enqueue(InvDiscAmount);
        LibraryVariableStorage.Enqueue(VATDiffAmount);

        SalesHeader.SetRecFilter();
        UpdateInvoiceDiscountAndVATAmountOnSalesOrderStatisticsNM(SalesHeader, SalesLine, AmountToPost, ExpectedVATAmount, VATDiffAmount);

        // [WHEN] Post sales order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Two VAT Entries posted
        // [THEN] "VAT Entry"[1].Base = 90 and "VAT Entry"[1].Amount = 9
        // [THEN] "VAT Entry"[2].Base = -100 and "VAT Entry"[2].Amount = -13 = -(100 * 10 % + 3)
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
        VerifyVATEntryAmounts(
          VATEntry,
          InvDiscAmount,
          Round(InvDiscAmount * SalesLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision()));
        VATEntry.Next();
        VerifyVATEntryAmounts(
          VATEntry,
          -(InvDiscAmount + AmountToPost),
          -(Round((InvDiscAmount + AmountToPost) * SalesLine."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision()) + VATDiffAmount));
        Assert.RecordCount(VATEntry, 2);

        // [THEN] Customer Ledger Entry with Amount = 14 = 100 - 90 + 4, "Purchase (LCY)" = 10 and "Inv. Discount (LCY)" = 90 posted
        FindCustLedgerEntry(CustLedgerEntry, SalesHeader."Sell-to Customer No.", DocumentNo);

        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, SalesLine."Amount Including VAT");
        CustLedgerEntry.TestField("Sales (LCY)", AmountToPost);
        CustLedgerEntry.TestField("Inv. Discount (LCY)", InvDiscAmount);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure TotalAmountIncVATOnSalesInvoiceSubformWithVATDifferenceNonModal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        MaxVATDifference: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
    begin
        // [FEATURE] [Statistics] [VAT Difference]
        // [SCENARIO 224140] Totals on sales invoice page has correct values in invoice with VAT Difference
        Initialize();

        // [GIVEN] VAT Difference is allowed
        MaxVATDifference := EnableVATDiffAmount();
        VATDifference := LibraryRandom.RandDecInDecimalRange(0.01, MaxVATDifference, 2);
        LibraryVariableStorage.Enqueue(VATDifference);

        // [GIVEN] Sales Invoice with Amount = 4000, Amount Incl. VAT = 5000
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        Amount := SalesLine.Amount;
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;

        // [WHEN] Add "VAT Difference" = 1 in SalesStatisticHandler
        // [THEN] Page total contains right values of "Total Amount Excl. VAT", "Total VAT", "Total Incl. VAT" on lines subpage before and after Release document
        // [THEN] "Total Amount Excl. VAT" = 4000 in "Sales Line"
        // [THEN] "Total VAT" = 1001 in "Sales Line"
        // [THEN] "Total Incl. VAT" = 5001 in "Sales Line"
        UpdateInvoiceDiscountAndVATAmountOnSalesStatisticsNM(SalesHeader, SalesLine, Amount, VATAmount + VATDifference, VATDifference);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsUpdateTotalVATHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure AmountInclVATContainsVATDifferenceInOpenSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        MaxVATDifference: Decimal;
        VATDifference: Decimal;
        AmountInclVATBefore: Decimal;
    begin
        // [FEATURE] [Statistics] [VAT Difference]
        // [SCENARIO 224140] "Amount Incl. VAT" contains VAT Difference in open Sales Order
        Initialize();

        // [GIVEN] VAT Difference is allowed
        MaxVATDifference := EnableVATDiffAmount();
        VATDifference := LibraryRandom.RandDecInDecimalRange(0.01, MaxVATDifference, 2);
        LibraryVariableStorage.Enqueue(VATDifference);

        // [GIVEN] Sales Order with Amount = 4000, Amount Incl. VAT = 5000
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        AmountInclVATBefore := SalesLine."Amount Including VAT";

        // [WHEN] Add "VAT Difference" = 1 in SalesStatisticHandler
        UpdateVATAmountOnSalesOrderStatistics(SalesHeader, SalesOrder);

        // [THEN] "VAT Difference" and "Amount Including VAT" fields contain VAT difference amount in "Sales Line"
        // [THEN] "VAT Difference" = 1 in "Sales Line"
        // [THEN] "Amount Including VAT" = 5001 in "Sales Line"
        SalesLine.Find();
        SalesLine.TestField("VAT Difference", VATDifference);
        SalesLine.TestField("Amount Including VAT", AmountInclVATBefore + VATDifference);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsNMUpdateTotalVATHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure AmountInclVATContainsVATDifferenceInOpenSalesOrderNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        MaxVATDifference: Decimal;
        VATDifference: Decimal;
        AmountInclVATBefore: Decimal;
    begin
        // [FEATURE] [Statistics] [VAT Difference]
        // [SCENARIO 224140] "Amount Incl. VAT" contains VAT Difference in open Sales Order
        Initialize();

        // [GIVEN] VAT Difference is allowed
        MaxVATDifference := EnableVATDiffAmount();
        VATDifference := LibraryRandom.RandDecInDecimalRange(0.01, MaxVATDifference, 2);
        LibraryVariableStorage.Enqueue(VATDifference);

        // [GIVEN] Sales Order with Amount = 4000, Amount Incl. VAT = 5000
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        AmountInclVATBefore := SalesLine."Amount Including VAT";

        // [WHEN] Add "VAT Difference" = 1 in SalesStatisticHandler
        UpdateVATAmountOnSalesOrderStatisticsNM(SalesHeader, SalesOrder);

        // [THEN] "VAT Difference" and "Amount Including VAT" fields contain VAT difference amount in "Sales Line"
        // [THEN] "VAT Difference" = 1 in "Sales Line"
        // [THEN] "Amount Including VAT" = 5001 in "Sales Line"
        SalesLine.Find();
        SalesLine.TestField("VAT Difference", VATDifference);
        SalesLine.TestField("Amount Including VAT", AmountInclVATBefore + VATDifference);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteNoIsNotVisibleWhenBlank()
    var
        SalesHeaderOrderFromQuote: Record "Sales Header";
        SalesHeaderOrderWithoutQuote: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 263847] "Quote No." must not be visible when switch from Sales Order with filled "Quote No." to one with blank

        Initialize();

        // [GIVEN] Sales Order "SO1" with filled "Quote No."
        CreateSalesOrderWithQuoteNo(SalesHeaderOrderFromQuote);

        // [GIVEN] Sales Order "SO2" with blank "Quote No."
        LibrarySales.CreateSalesHeader(
          SalesHeaderOrderWithoutQuote, SalesHeaderOrderWithoutQuote."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Order page is openned for "SO1"
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeaderOrderFromQuote);
        Assert.IsTrue(SalesOrder."Quote No.".Visible(), QuoteNoMustBeVisibleErr);

        // [WHEN] Press Next to go to "SO2"
        SalesOrder.Next();

        // [THEN] "Quote No" is not visible
        Assert.IsFalse(SalesOrder."Quote No.".Visible(), QuoteNoMustNotBeVisibleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuoteNoIsVisibleWhenFilled()
    var
        SalesHeaderOrderFromQuote: Record "Sales Header";
        SalesHeaderOrderWithoutQuote: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 263847] "Quote No." must be visible when switch from Sales Order with blank "Quote No." to one with filled

        Initialize();

        // [GIVEN] Sales Order "SO1" with filled "Quote No."
        CreateSalesOrderWithQuoteNo(SalesHeaderOrderFromQuote);

        // [GIVEN] Sales Order "SO2" with blank "Quote No."
        LibrarySales.CreateSalesHeader(
          SalesHeaderOrderWithoutQuote, SalesHeaderOrderWithoutQuote."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Order page is openned for "SO2"
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeaderOrderWithoutQuote);
        Assert.IsFalse(SalesOrder."Quote No.".Visible(), QuoteNoMustNotBeVisibleErr);

        // [WHEN] Press PREVIOUS to go to "SO1"
        SalesOrder.Previous();

        // [THEN] "Quote No" is visible
        Assert.IsTrue(SalesOrder."Quote No.".Visible(), QuoteNoMustBeVisibleErr);
        SalesOrder."Quote No.".AssertEquals(SalesHeaderOrderFromQuote."Quote No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAmountExpectedIncludesInvDiscountWhenShipSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 266357] Expected sales amount includes invoice discount when you post sales shipment.
        Initialize();

        // [GIVEN] Sales order line. Quantity = 40 pcs, "Unit Price" = 100 LCY, "Inv. Discount Amount" = 200 LCY, which is 5% discount.
        LibrarySales.SetCalcInvDiscount(true);
        CreateSalesDocumentWithInvDiscount(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 40, 100.0, 5);

        // [WHEN] Set "Qty. to Ship" = 20 pcs on the sales line and ship the order.
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine, 20, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "Sales Amount (Expected)" is equal to 1900 LCY (20 pcs by 100 LCY each, minus 5% discount).
        VerifyValueEntryAmountsForItem(SalesLine."No.", 20 * 100.0 * 0.95, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAmountExpectedIncludesInvDiscountWhenShipSalesOrderWithTwoLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 266357] Expected sales amount includes invoice discount when you post sales shipment from a sales order with two lines.
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Sales order with 2 lines.
        // [GIVEN] First line: Quantity = 40 pcs, "Unit Price" = 100 LCY, "Inv. Discount Amount" = 200 LCY, which is 5% discount.
        // [GIVEN] Second line: Quantity = 80 pcs, "Unit Price" = 200 LCY, "Inv. Discount Amount" = 800 LCY, which is 5% discount.
        CreateSalesDocumentWithInvDiscount(
          SalesHeader, SalesLine[1], SalesHeader."Document Type"::Order, 40, 100.0, 5);
        CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::Item, LibraryInventory.CreateItemNo(), 80, 200.0);

        // [WHEN] Set "Qty. to Ship" = 20 pcs on the first sales line and "Qty. to Ship" = 40 pcs on the second line. Ship the sales order.
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine[1], 20, 0);
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine[2], 40, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "Sales Amount (Expected)" on the first line is equal to 1900 LCY (20 pcs by 100 LCY each, minus 5% discount).
        VerifyValueEntryAmountsForItem(SalesLine[1]."No.", 20 * 100.0 * 0.95, 0);

        // [THEN] "Sales Amount (Expected)" on the second line is equal to 7600 LCY (40 pcs by 200 LCY each, minus 5% discount).
        VerifyValueEntryAmountsForItem(SalesLine[2]."No.", 40 * 200.0 * 0.95, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAmountExpectedIncludesInvDiscountWhenShipAndPartiallyInvoiceSO()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 266357] Expected sales amount with invoice discounts corresponds to shipped but not invoiced quantity, when you post a sales order with "Ship and Invoice" option in several steps.
        Initialize();

        // [GIVEN] Sales order line. Quantity = 40 pcs, "Unit Price" = 100 LCY, "Inv. Discount Amount" = 200 LCY, which is 5% discount.
        LibrarySales.SetCalcInvDiscount(true);
        CreateSalesDocumentWithInvDiscount(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 40, 100.0, 5);

        // [WHEN] Set "Qty. to Ship" = 20 pcs, "Qty. to Invoice" = 10 pcs and post the sales order with "Ship and Invoice" option.
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine, 20, 10);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Sales Amount (Expected)" is equal to 950 LCY (100 LCY * 10 pcs shipped not invoiced, minus 5% discount).
        // [THEN] "Sales Amount (Actual)" is equal to 950 LCY (100 LCY * 10 pcs invoiced, minus 5% discount).
        VerifyValueEntryAmountsForItem(
          SalesLine."No.",
          10 * 100.0 * 0.95,
          10 * 100.0 * 0.95);

        // [WHEN] Set "Qty. to Ship" = 10 pcs, "Qty. to Invoice" = 5 pcs and post the sales order with "Ship and Invoice" option.
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine, 10, 5);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Sales Amount (Expected)" is equal to 1425 LCY (100 LCY * 15 pcs shipped not invoiced, minus 5% discount).
        // [THEN] "Sales Amount (Actual)" is equal to 1425 LCY (100 LCY * 15 pcs invoiced, minus 5% discount).
        VerifyValueEntryAmountsForItem(
          SalesLine."No.",
          15 * 100.0 * 0.95,
          15 * 100.0 * 0.95);

        // [WHEN] Set "Qty. to Ship" = 10 pcs and ship the sales order.
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine, 10, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Sales Amount (Expected)" is equal to 2375 LCY (100 LCY * 25 pcs shipped not invoiced, minus 5% discount).
        // [THEN] "Sales Amount (Actual)" is left equal to 1425 LCY (100 LCY * 15 pcs invoiced, minus 5% discount).
        VerifyValueEntryAmountsForItem(
          SalesLine."No.",
          25 * 100.0 * 0.95,
          15 * 100.0 * 0.95);

        // [WHEN] Set "Qty. to Invoice" = 25 pcs, hence finalize posting the order.
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine, 0, 25);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Sales Amount (Expected)" = 0 (everything is invoiced).
        // [THEN] "Sales Amount (Actual)" is equal to to 3800 LCY (100 LCY * 40 pcs invoiced, minus 5% discount).
        VerifyValueEntryAmountsForItem(
          SalesLine."No.",
          0,
          40 * 100.0 * 0.95);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReversedSalesAmountIncludesInvDiscountWhenInvoiceSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        InvoiceNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 266357] Invoicing sales order reverses all expected sales amount including invoice discount.
        Initialize();

        // [GIVEN] Sales order line. Quantity = 20 pcs, "Unit Price" = 100 LCY, "Inv. Discount Amount" = 100 LCY, which is 5% discount.
        LibrarySales.SetCalcInvDiscount(true);
        CreateSalesDocumentWithInvDiscount(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, 20, 100.0, 5);

        // [GIVEN] Ship the order in two steps, each for 10 pcs.
        for i := 1 to 2 do begin
            UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine, 10, 0);
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        // [WHEN] Invoice the sales order.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] The invoice creates the reversed value entry for all posted expected sales amount including the invoice discount.
        ValueEntry.SetRange("Document No.", InvoiceNo);
        ValueEntry.CalcSums("Sales Amount (Expected)");
        ValueEntry.TestField("Sales Amount (Expected)", -20 * 100.0 * 0.95);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAmountExpectedIncludesInvDiscountWhenReceiveAndPartInvoiceReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Return Order] [Invoice Discount]
        // [SCENARIO 266357] Expected sales amount with invoice discounts corresponds to received but not invoiced quantity, when you post a sales return order with "Receive and Invoice" option in several steps.
        Initialize();

        // [GIVEN] Sales return order line. Quantity = 40 pcs, "Unit Price" = 100 LCY, "Inv. Discount Amount" = 200 LCY, which is 5% discount.
        LibrarySales.SetCalcInvDiscount(true);
        CreateSalesDocumentWithInvDiscount(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", 40, 100.0, 5);

        // [WHEN] Set "Qty. to Return Receive" = 20 pcs, "Qty. to Invoice" = 10 pcs and post the sales return with "Receive and Invoice" option.
        UpdateQtyToReturnReceiveAndInvoiceOnSalesLine(SalesLine, 20, 10);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Sales Amount (Expected)" is equal to -950 LCY (100 LCY * 10 pcs received not invoiced, minus 5% discount).
        // [THEN] "Sales Amount (Actual)" is equal to -950 LCY (100 LCY * 10 pcs invoiced, minus 5% discount).
        VerifyValueEntryAmountsForItem(
          SalesLine."No.",
          -10 * 100.0 * 0.95,
          -10 * 100.0 * 0.95);

        // [WHEN] Set "Qty. to Return Receive" = 10 pcs, "Qty. to Invoice" = 5 pcs and post the sales return with "Receive and Invoice" option.
        UpdateQtyToReturnReceiveAndInvoiceOnSalesLine(SalesLine, 10, 5);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Sales Amount (Expected)" is equal to -1425 LCY (100 LCY * 15 pcs received not invoiced, minus 5% discount).
        // [THEN] "Sales Amount (Actual)" is equal to -1425 LCY (100 LCY * 15 pcs invoiced, minus 5% discount).
        VerifyValueEntryAmountsForItem(
          SalesLine."No.",
          -15 * 100.0 * 0.95,
          -15 * 100.0 * 0.95);

        // [WHEN] Set "Qty. to Return Receive" = 10 pcs and receive the return order.
        UpdateQtyToReturnReceiveAndInvoiceOnSalesLine(SalesLine, 10, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Sales Amount (Expected)" is equal to -2375 LCY (100 LCY * 25 pcs received not invoiced, minus 5% discount).
        // [THEN] "Sales Amount (Actual)" is left equal to -1425 LCY (100 LCY * 15 pcs invoiced, minus 5% discount).
        VerifyValueEntryAmountsForItem(
          SalesLine."No.",
          -25 * 100.0 * 0.95,
          -15 * 100.0 * 0.95);

        // [WHEN] Set "Qty. to Invoice" = 25 pcs, hence finalize posting the order.
        UpdateQtyToReturnReceiveAndInvoiceOnSalesLine(SalesLine, 0, 25);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Sales Amount (Expected)" = 0 (everything is invoiced).
        // [THEN] "Sales Amount (Actual)" is equal to to -3800 LCY (100 LCY * 40 pcs invoiced, minus 5% discount).
        VerifyValueEntryAmountsForItem(
          SalesLine."No.",
          0,
          -40 * 100.0 * 0.95);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesHeaderAmountShippedNotInvoicedLCYFilters()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Index: Integer;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 270421] Amount shipped not invoiced (LCY) calculates sum of corresponding values of sales lines filtered by Document Type and Document No.

        Initialize();
        DocumentNo := LibraryUtility.GenerateGUID();
        for Index := 1 to 2 do begin
            MockSalesHeader(SalesHeader, "Sales Document Type".FromInteger(Index), DocumentNo);
            MockSalesLineWithShipNotInvLCY(SalesLine, SalesHeader, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        end;

        SalesHeader.CalcFields("Amt. Ship. Not Inv. (LCY)", "Amt. Ship. Not Inv. (LCY) Base");
        SalesHeader.TestField(
          "Amt. Ship. Not Inv. (LCY)",
          SalesLine."Shipped Not Invoiced (LCY)");
        SalesHeader.TestField(
          "Amt. Ship. Not Inv. (LCY) Base",
          SalesLine."Shipped Not Inv. (LCY) No VAT")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentNavigateDocumentNo()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        NoSeries: Codeunit "No. Series";
        Navigate: TestPage Navigate;
        ItemNo: Code[20];
        SalesShipmentNo: Code[20];
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 286007] Navigate page opened from Posted Sales Shipment page has Document No. filter equal to Posted Sales Shipment "No."
        Initialize();

        // [GIVEN] Sales order with Sales Line having Location with "Require Shipment" set to TRUE
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        ItemNo := LibraryInventory.CreateItemNo();
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Positive amount of Item from Sales Line
        CreateItemJournalLinePositiveAdjustment(ItemNo, LibraryRandom.RandIntInRange(10, 20), Location.Code);

        // [GIVEN] Sales Shipment No "X"
        SalesShipmentNo := NoSeries.PeekNextNo(SalesHeader."Shipping No. Series");

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Created and registered pick for an Item from Sales Line
        CreateAndRegisterPick(ItemNo, Location.Code);

        // [GIVEN] Posted Warehouse Shipment Line
        PostWarehouseShipmentLine(SalesHeader."No.", SalesLine."Line No.");

        // [WHEN] Navigate page is opened from Posted Sales Shipment
        Navigate.Trap();
        SalesShipmentHeader.Get(SalesShipmentNo);
        SalesShipmentHeader.Navigate();

        // [THEN] Filter "Document No" on page Navigate is equal to "X"
        Assert.AreEqual(SalesShipmentNo, Navigate.FILTER.GetFilter("Document No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingInvoiceFilledWithGetShipmentFromMultipleShipments()
    var
        SalesHeaderInvoice: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeSalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        // [FEATURE] [Sales Order] [Item Charge] [Get Shipment Lines]
        // [SCENARIO 290332] Posting invoice filled with Get shipment lines doesn't raise an error when item and its charge were shipped separately.
        Initialize();

        // [GIVEN] Item Charge
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Sales Order with 1 item and 1 item charge lines.
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(
          SalesLine, SalesHeaderOrder, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(100));
        CreateSalesLine(
          ItemChargeSalesLine, SalesHeaderOrder, SalesLine.Type::"Charge (Item)", ItemCharge."No.",
          LibraryRandom.RandIntInRange(1, SalesLine.Quantity), LibraryRandom.RandInt(100));

        // [GIVEN] Item charge assigned to item
        LibrarySales.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, ItemChargeSalesLine, ItemCharge, SalesHeaderOrder."Document Type", SalesHeaderOrder."No.",
          SalesLine."Line No.", SalesLine."No.", ItemChargeSalesLine.Quantity, LibraryRandom.RandInt(100));
        ItemChargeAssignmentSales.Insert(true);

        // [GIVEN] Item and it assigned charge are shipped separately
        ItemChargeSalesLine.Validate("Qty. to Ship", 0);
        ItemChargeSalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Get Shipment Lines is run for Sales Invoice
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");

        SalesShipmentLine.SetRange("Sell-to Customer No.", SalesHeaderInvoice."Sell-to Customer No.");
        SalesShipmentLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);

        // [WHEN] Post the sales invoice.
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true);

        // [THEN] Sales line with item is fully posted.
        SalesLine.Find();
        SalesLine.TestField("Quantity Invoiced", SalesLine.Quantity);

        // [THEN] Sales line with item charge is fully assigned and posted.
        ItemChargeSalesLine.Find();
        ItemChargeSalesLine.TestField("Quantity Invoiced", ItemChargeSalesLine.Quantity);
        ItemChargeSalesLine.CalcFields("Qty. Assigned");
        ItemChargeSalesLine.TestField("Qty. Assigned", ItemChargeSalesLine.Quantity);
    end;

    [Scope('OnPrem')]
    procedure CheckNotHandlerCreationSalesOrderForResource()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO 320976] For Inventoriable item type changing Location Code to new one in Sales Order should not send notification

        Initialize();

        // [GIVEN] My Notification for Posting Setup is created and enabled
        SetupMyNotificationsForPostingSetup();

        // [GIVEN] New Location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Sales Order is created with Type = Resource
        CreateSalesOrder(SalesHeader, SalesLine);
        SalesLine.Validate(Type, SalesLine.Type::Resource);

        // [WHEN] Change Location Code to Location.Code value
        SalesLine.Validate("Location Code", Location.Code);

        // [THEN] The Massage handled successfully
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckNotHandlerCreationSalesOrderForItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO 320976] For inventoriable item type changing Location Code to new one in Sales Order should send notification

        Initialize();

        // [GIVEN] My Notification for Posting Setup is created and enabled
        SetupMyNotificationsForPostingSetup();

        // [GIVEN] New Location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Sales Order is created with Type = Item
        CreateSalesOrder(SalesHeader, SalesLine);

        // [WHEN] Change Location Code to Location.Code value
        SalesLine.Validate("Location Code", Location.Code);

        // [THEN] The Massage handled successfully
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineResource()
    var
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Resource: Record Resource;
    begin
        // [FEATURE] [Undo shipment] [Resource]
        // [SCENARIO 289385] Stan is able to undo shipment for sales shipment line of Recource type
        Initialize();

        // [GIVEN] Create and post shipment of sales order with Resource type line
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");
        CreatePostSalesOrderForUndoShipment(
            SalesLine,
            VATPostingSetup,
            SalesLine.Type::Resource,
            Resource."No.");

        FindSalesShipmentLine(SalesShipmentLine, SalesLine."Document No.");

        // [WHEN] Undo sales shipment.
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] Verify Quantity after Undo Shipment
        VerifyUndoShipmentLineOnPostedShipment(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineChargeItem()
    var
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemCharge: Record "Item Charge";
    begin
        // [FEATURE] [Undo shipment] [Item charge]
        // [SCENARIO 289385] Stan is able to undo shipment for sales shipment line of Charge (Item) type
        Initialize();

        // [GIVEN] Create and post shipment of sales order with Charge (Item) type line
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItemCharge(ItemCharge);

        CreatePostSalesOrderForUndoShipment(
            SalesLine,
            VATPostingSetup,
            SalesLine.Type::"Charge (Item)",
            ItemCharge."No.");

        FindSalesShipmentLine(SalesShipmentLine, SalesLine."Document No.");

        // [WHEN] Undo sales shipment.
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] Verify Quantity after Undo Shipment
        VerifyUndoShipmentLineOnPostedShipment(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineGLAccount()
    var
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DummyGLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Undo shipment] [Item charge]
        // [SCENARIO 289385] Stan is able to undo shipment for sales shipment line of G/L Account type
        Initialize();

        // [GIVEN] Create and post shipment of sales order with G/L Account type line
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreatePostSalesOrderForUndoShipment(
            SalesLine,
            VATPostingSetup,
            SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale));

        FindSalesShipmentLine(SalesShipmentLine, SalesLine."Document No.");

        // [WHEN] Undo sales shipment.
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] Verify Quantity after Undo Shipment
        VerifyUndoShipmentLineOnPostedShipment(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoSalesReceiptLineResource()
    var
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Resource: Record Resource;
    begin
        // [FEATURE] [Undo receipt] [Resource]
        // [SCENARIO 289385] Stan is able to undo receipt for return receipt line of Recource type
        Initialize();

        // [GIVEN] Create and post receipt of sales return order with Resource type line
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");
        CreatePostSalesReturnOrderForUndoReceipt(
            SalesLine,
            VATPostingSetup,
            SalesLine.Type::Resource,
            Resource."No.");

        FindReturnReceiptLine(ReturnReceiptLine, SalesLine."Document No.");

        // [WHEN] Undo return receipt.
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);

        // [THEN] Verify Quantity after Undo Receipt
        VerifyUndoReceiptLineOnPostedReturnReceipt(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoSalesReceiptLineChargeItem()
    var
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemCharge: Record "Item Charge";
    begin
        // [FEATURE] [Undo receipt] [Item charge]
        // [SCENARIO 289385] Stan is able to undo receipt for return receipt line of Charge (Item) type
        Initialize();

        // [GIVEN] Create and post receipt of sales return order with Charge (Item) type line
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItemCharge(ItemCharge);

        CreatePostSalesReturnOrderForUndoReceipt(
            SalesLine,
            VATPostingSetup,
            SalesLine.Type::"Charge (Item)",
            ItemCharge."No.");

        FindReturnReceiptLine(ReturnReceiptLine, SalesLine."Document No.");

        // [WHEN] Undo return receipt
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);

        // [THEN] Verify Quantity after Undo Receipt
        VerifyUndoReceiptLineOnPostedReturnReceipt(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoSalesReceiptLineGLAccount()
    var
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DummyGLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Undo receipt] [G/L Account]
        // [SCENARIO 289385] Stan is able to undo receipt for return receipt line of G/L Account type
        Initialize();

        // [GIVEN] Create and post receipt of sales return order with G/L Account line type
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreatePostSalesReturnOrderForUndoReceipt(
            SalesLine,
            VATPostingSetup,
            SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale));

        FindReturnReceiptLine(ReturnReceiptLine, SalesLine."Document No.");

        // [WHEN] Undo return receipt.
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);

        // [THEN] Verify Quantity after Undo Receipt
        VerifyUndoReceiptLineOnPostedReturnReceipt(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderSellToEmailIsChangedWhenChangingSellToContactNo()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Contact] [UT]
        // [SCENARIO 323845] Changing Sell-to Contact No. on Sales Order changes Sell-to Email when it's not empty.
        Initialize();

        // [GIVEN] Sales order for Customer with Contact with non-empty E-mail.
        CreateCustomerWithContactWithEmailAndPhone(Customer, Contact, LibraryUtility.GenerateRandomEmail());
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Sell-to Contact No. is changed.
        SalesHeader.Validate("Sell-to Contact No.", Contact."No.");

        // [THEN] Sell-to Email is changed.
        Assert.AreEqual(Contact."E-Mail", SalesHeader."Sell-to E-Mail", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderSellToEmailIsChangedWhenChangingSellToContactNoToEmptyEmail()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Contact] [UT]
        // [SCENARIO 323845] Changing Sell-to Contact No. on Sales Order changes Sell-to Email when it's empty and Stan accepts the change..
        Initialize();

        // [GIVEN] Sales order for Customer with Contact with empty E-mail.
        CreateCustomerWithContactWithEmailAndPhone(Customer, Contact, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Sell-to Contact No. is changed and Stan accepts the change.
        SalesHeader.Validate("Sell-to Contact No.", Contact."No.");

        // [THEN] Sell-to Email is changed to blank.
        Assert.AreEqual(Contact."E-Mail", SalesHeader."Sell-to E-Mail", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNoToChangingEmail')]
    [Scope('OnPrem')]
    procedure SalesOrderSellToEmailIsNotChangedWhenChangingSellToContactNoToEmptyEmail()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Contact] [UT]
        // [SCENARIO 323845] Changing Sell-to Contact No. on Sales Order changes Sell-to Email when it's empty and Stan rejects the change..
        Initialize();

        // [GIVEN] Sales order for Customer with Contact with empty E-mail.
        CreateCustomerWithContactWithEmailAndPhone(Customer, Contact, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Sell-to Contact No. is changed and Stan rejects the change.
        SalesHeader.Validate("Sell-to Contact No.", Contact."No.");

        // [THEN] Sell-to Email is not changed.
        Assert.AreEqual(Customer."E-Mail", SalesHeader."Sell-to E-Mail", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderSellToPhoneNoIsChangedWhenChangingSellToContactNo()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Contact] [UT]
        // [SCENARIO 323845] Changing Sell-to Contact No on Sales Order changes Sell-to Phone No.
        Initialize();

        // [GIVEN] Sales order for Customer with Contact with Phone No.
        CreateCustomerWithContactWithEmailAndPhone(Customer, Contact, LibraryUtility.GenerateRandomEmail());
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Sell-to Contact No. is changed.
        SalesHeader.Validate("Sell-to Contact No.", Contact."No.");

        // [THEN] Sell-to Phone No. is changed.
        Assert.AreEqual(Contact."Phone No.", SalesHeader."Sell-to Phone No.", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure RevertCurrencyCodeWhenRefusedToRecreateSalesLines()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UT] [Currency] [FCY]
        // [SCENARIO 347892] System throws error and reverts entered "Currency Code" when Stan refused to recreate existing sales lines on Sales Order
        Initialize();

        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.TestField("Currency Code", '');
        Commit();

        SalesOrder.Trap();
        PAGE.Run(PAGE::"Sales Order", SalesHeader);

        SalesOrder."No.".AssertEquals(SalesHeader."No.");
        SalesOrder."Currency Code".AssertEquals('');

        LibraryVariableStorage.Enqueue(RecreateSalesLinesMsg);
        LibraryVariableStorage.Enqueue(false);
        asserterror SalesOrder."Currency Code".SetValue(LibraryERM.CreateCurrencyWithRandomExchRates());

        Assert.ExpectedError(StrSubstNo(RecreateSalesLinesCancelErr, SalesHeader.FieldCaption("Currency Code")));

        SalesOrder."Currency Code".AssertEquals('');
        SalesOrder.Close();

        SalesHeader.Find();
        SalesHeader.TestField("Currency Code", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TypeSetOnCreateNewOrderLineWhenSubscribedToOnBeforeSetDefaultType()
    var
        FixedAsset: Record "Fixed Asset";
        SalesLine: Record "Sales Line";
        SalesOrderCard: TestPage "Sales Order";
        ERMSalesOrder: Codeunit "ERM Sales Order";
        SalesOrderNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 394306] Create new Sales Order line when Type <> Item is set inside a subscriber to OnBeforeSetDefaultType event of Sales Order Subform, FoundationSetup is true.
        Initialize();
        UpdateManualNosOnSalesOrderNoSeries(true);

        // [GIVEN] Foundation setup is enabled.
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Fixed Asset "F".
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // [GIVEN] Sales Order card is opened, a new order is created.
        SalesOrderCard.OpenNew();
        SalesOrderNo := 'SetDefaultTypeEvent';  // to set IsHandled = true inside subscriber
        SalesOrderCard."No.".SetValue(SalesOrderNo);
        SalesOrderCard."Sell-to Customer No.".SetValue(LibrarySales.CreateCustomerNo());

        // [GIVEN] Stan subscribes to OnBeforeSetDefaultType of page Sales Order Subform.
        // [GIVEN] Type is set to "Fixed Asset" inside subscriber when a new order line is created.
        BindSubscription(ERMSalesOrder);

        // [WHEN] Create a new order line on page, set "No." = "F".
        SalesOrderCard.SalesLines.New();
        SalesOrderCard.SalesLines."No.".SetValue(FixedAsset."No.");
        SalesOrderCard.Close();

        // [THEN] Sales Line is created. Type is "Fixed Asset", "No." = "F".
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderNo);
        SalesLine.FindLast();
        SalesLine.TestField(Type, SalesLine.Type::"Fixed Asset");
        SalesLine.TestField("No.", FixedAsset."No.");

        // tear down
        UpdateManualNosOnSalesOrderNoSeries(false);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    procedure DefaultTypeItemSetOnCreateNewOrderLine()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesOrderCard: TestPage "Sales Order";
        SalesOrderNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 394306] Create new Sales Order line when FoundationSetup is true.
        Initialize();

        // [GIVEN] Foundation setup is enabled.
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Item "I".
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales Order card is opened, a new order is created.
        SalesOrderCard.OpenNew();
        SalesOrderCard."Sell-to Customer No.".SetValue(LibrarySales.CreateCustomerNo());
        SalesOrderNo := SalesOrderCard."No.".Value();

        // [WHEN] Create a new order line on page, set "No." = "I".
        SalesOrderCard.SalesLines.New();
        SalesOrderCard.SalesLines."No.".SetValue(Item."No.");
        SalesOrderCard.Close();

        // [THEN] Sales Line is created. Type is "Item", "No." = "I".
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderNo);
        SalesLine.FindLast();
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", Item."No.");

        // tear down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    procedure LocationForNonInventoryItemsAllowed()
    var
        ServiceItem: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] Create Sales Order with non-inventory items having a location set is allowed.
        Initialize();

        // [GIVEN] A non-inventory item and a service item.
        LibraryInventory.CreateServiceTypeItem(ServiceItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Created Purchase Order for the non-inventory items with locations set.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, ServiceItem."No.", 1);
        SalesLine1.Validate("Location Code", Location.Code);
        SalesLine1.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, NonInventoryItem."No.", 1);
        SalesLine2.Validate("Location Code", Location.Code);
        SalesLine2.Modify(true);

        // [WHEN] Posting Purchase Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] An item ledger entry is created for non-inventory items with location set.
        ItemLedgerEntry.SetRange("Item No.", ServiceItem."No.");
        Assert.AreEqual(1, ItemLedgerEntry.Count, 'Expected only one ILE to be created.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(-1, ItemLedgerEntry.Quantity, 'Expected quantity to be -1.');
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code", 'Expected location to be set.');

        ItemLedgerEntry.SetRange("Item No.", NonInventoryItem."No.");
        Assert.AreEqual(1, ItemLedgerEntry.Count, 'Expected only one ILE to be created.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(-1, ItemLedgerEntry.Quantity, 'Expected quantity to be -1.');
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code", 'Expected location to be set.');
    end;

    [Test]
    procedure BinCodeNotAllowedForNonInventoryItems()
    var
        Item: Record Item;
        ServiceItem: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
    begin
        // [SCENARIO] Create sales order with location for item and non-inventory items.
        // Bin code should only be possible to set for item.
        Initialize();

        // [GIVEN] An item, A non-inventory item and a service item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateServiceTypeItem(ServiceItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location with require bin and a default bin code.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBinContent(
            BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure"
        );
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] A vendor with default location.
        LibrarySales.CreateCustomerWithLocationCode(Customer, Location.Code);

        // [GIVEN] Created Sales Order for the item and non-inventory items.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, ServiceItem."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine3, SalesHeader, SalesLine3.Type::Item, NonInventoryItem."No.", 1);

        // [THEN] Location is set for all lines and bin code is set for item.
        Assert.AreEqual(Location.Code, SalesLine1."Location Code", 'Expected location code to be set');
        Assert.AreEqual(Bin.Code, SalesLine1."Bin Code", 'Expected bin code to be set');

        Assert.AreEqual(Location.Code, SalesLine2."Location Code", 'Expected location code to be set');
        Assert.AreEqual('', SalesLine2."Bin Code", 'Expected no bin code set');

        Assert.AreEqual(Location.Code, SalesLine3."Location Code", 'Expected location code to be set');
        Assert.AreEqual('', SalesLine3."Bin Code", 'Expected no bin code set');

        // [WHEN] Setting bin code on non-inventory items.
        asserterror SalesLine2.Validate("Bin Code", Bin.Code);
        asserterror SalesLine3.Validate("Bin Code", Bin.Code);

        // [THEN] An error is thrown.
    end;

    [Test]
    procedure QtyToInvoiceDistributedEvenlyOnItemChargeAssignmentInPartialPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeSalesLine: Record "Sales Line";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        QtyToAssign: array[3] of Decimal;
        ItemChargeUnitPrice: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Charge] [Invoice]
        // [SCENARIO 401969] When partially shipped Sales Order with Charge Assignment is invoiced, "Qty. to Assign" on item charge line is adjusted automatically.
        Initialize();

        // [GIVEN] Create Item Charge.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Create Sales Order with 3 item lines.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        for i := 1 to 3 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;

        // [GIVEN] Add item charge line with quantity = 9.
        LibrarySales.CreateSalesLine(
          ItemChargeSalesLine, SalesHeader, ItemChargeSalesLine.Type::"Charge (Item)", ItemCharge."No.", 9);
        ItemChargeUnitPrice := LibraryRandom.RandDec(10, 2);
        ItemChargeSalesLine.Validate("Unit Price", ItemChargeUnitPrice);
        ItemChargeSalesLine.Validate("Qty. to Ship", 6);
        ItemChargeSalesLine.Modify(true);

        // [GIVEN] Create 3 Item Charge Assignment lines and set Qty to Assign with distribution by lines 4 - 4 - 1 respectively
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindSet();

        i := 0;
        QtyToAssign[1] := 4;
        QtyToAssign[2] := 4;
        QtyToAssign[3] := 1;
        repeat
            i += 1;
            LibrarySales.CreateItemChargeAssignment(
              ItemChargeAssignmentSales, ItemChargeSalesLine, ItemCharge, SalesLine."Document Type",
              SalesLine."Document No.", SalesLine."Line No.", SalesLine."No.", QtyToAssign[i], ItemChargeUnitPrice);
            ItemChargeAssignmentSales.Insert(true);

            SalesLine.Validate("Qty. to Ship", LibraryRandom.RandInt(5));
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;

        // [GIVEN] Post Sales Order as Ship
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Post Sales Order as Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] No error occurs, which means that distribution has been made correctly.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCompletelyShippedWhenSalesOrderAsShip()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 449794] The "Completely Shipped" option is reported differently in Sales Order list respect to Sales Order card
        Initialize();

        // [GIVEN] Create sales order and post as ship
        CreateSalesOrder(SalesHeader, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Sales Order page is opened
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] Verify completely shipped as yes
        Assert.AreEqual(SalesOrder."Completely Shipped".Value, 'Yes', CompletelyShippedErr);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesModalPageHandler')]
    procedure VerifyPostSalesOrderWithChargeItemPostedFromSalesInvoiceRelatedToShipmentCreatedFromSalesOrder()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        ItemCharge: Record "Item Charge";
        Items: array[2] of Record Item;
    begin
        // [SCENARIO 457731] Verify Post Sales Order, for partially Shipped lines, with Charge (Item), and than that lines posted through Sales Invoice
        Initialize();

        // [GIVEN] Create Item Charge and two Items
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryInventory.CreateItem(Items[1]);
        LibraryInventory.CreateItem(Items[2]);

        // [GIVEN] Set to Queue Item No. and Item Charge No. for filtering Shipment Lines
        LibraryVariableStorage.Enqueue(ItemCharge."No.");
        LibraryVariableStorage.Enqueue(Items[2]."No.");

        // [GIVEN] Create Sales Order with three lines (two Item and one Charge (Item))
        CreateSalesOrderWithItemCharge(SalesHeaderOrder, ItemCharge."No.", Items);

        // [GIVEN] Set First Sales Order Line not to Ship
        SetFirstSalesLineNotToShip(SalesHeaderOrder, Items[1]."No.");

        // [GIVEN] Post Ship for one Item and Charge (Item) line
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Create Sales Invoice for Posted Shipment Lines from Sales Order
        CreateSalesInvoice(SalesHeaderInvoice, SalesHeaderOrder, ItemCharge);

        // [WHEN] Post Invoice
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true);

        // [THEN] Post Sales Order
        SalesHeaderOrder.Get(SalesHeaderOrder."Document Type", SalesHeaderOrder."No.");
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    procedure VerifyAdjustedCostLCYOnSalesOrderStatusticAfterCorrectSalesInvoiceAndPostShipmentLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        Items: array[2] of Record Item;
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        AdjustedCostLCY: Decimal;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 455409] Verify Adjusted Cost (LCY) is correct, after Sales Order is posted, corrected, and one line post again
        Initialize();

        // [GIVEN] Create two Items with Unit Price and Unit Cost
        CreateItemsWithUnitPriceAndUnitCost(Items);

        // [GIVEN] Create Sales Order
        CreateSalesOrder(SalesHeader, SalesLine, Items);

        // [GIVEN] Open Sales Order Statistics page
        OpenSalesOrderStatistics(SalesHeader."No.");

        // [GIVEN] Return Adjusted Cost (LCY) from Sales Order Statistics
        AdjustedCostLCY := LibraryVariableStorage.DequeueDecimal();

        // [GIVEN] Update Qty. to Ship and Invocie on both Lines
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesHeader, SalesLine);

        // [GIVEN] Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Correct Posted Sales Invoice
        SalesInvHeader.Get(DocumentNo);
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);

        // [GIVEN] Update Qty. to Ship and Invocie on first Line
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine, 10, 10);

        // [GIVEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Open Sales Order Statistics page
        OpenSalesOrderStatistics(SalesHeader."No.");

        // [THEN] Verify Adjusted Cost is not changed
        Assert.IsTrue(AdjustedCostLCY = LibraryVariableStorage.DequeueDecimal(), AdjustedCostChangedMsg);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    procedure VerifyAdjustedCostLCYOnSalesOrderStatusticAfterCorrectSalesInvoiceAndPostShipmentLineNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        Items: array[2] of Record Item;
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        AdjustedCostLCY: Decimal;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 455409] Verify Adjusted Cost (LCY) is correct, after Sales Order is posted, corrected, and one line post again
        Initialize();

        // [GIVEN] Create two Items with Unit Price and Unit Cost
        CreateItemsWithUnitPriceAndUnitCost(Items);

        // [GIVEN] Create Sales Order
        CreateSalesOrder(SalesHeader, SalesLine, Items);

        // [GIVEN] Open Sales Order Statistics page
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // [GIVEN] Return Adjusted Cost (LCY) from Sales Order Statistics
        AdjustedCostLCY := LibraryVariableStorage.DequeueDecimal();

        // [GIVEN] Update Qty. to Ship and Invocie on both Lines
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesHeader, SalesLine);

        // [GIVEN] Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Correct Posted Sales Invoice
        SalesInvHeader.Get(DocumentNo);
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);

        // [GIVEN] Update Qty. to Ship and Invocie on first Line
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine, 10, 10);

        // [GIVEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Open Sales Order Statistics page
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // [THEN] Verify Adjusted Cost is not changed
        Assert.IsTrue(AdjustedCostLCY = LibraryVariableStorage.DequeueDecimal(), AdjustedCostChangedMsg);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerNo,ShipToAddressListModalPageHandlerOK')]
    procedure VerifyConfirmationDialogIsShownOnChangedShipToCodeOption()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShipToAddress: Record "Ship-to Address";
        SalesOrder: TestPage "Sales Order";
        DimensionSetID: Integer;
        ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";
    begin
        // [SCENARIO 459751] Verify Confirmation Dialog is shown on update Ship-to Code option on Sales Order
        Initialize();

        // [GIVEN] Customer with default Dimension
        CreateCustomerWithAddressAndDefaultDim(Customer);

        // [GIVEN] Create Alternate Shipping Address for Customer
        CreateAlternateShippingAddressForCustomer(Customer, ShipToAddress);
        LibraryVariableStorage.Enqueue(ShipToAddress.Code);

        // [GIVEN] Create Sales Order
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          Customer."No.", '', LibraryRandom.RandInt(10), '', 0D);

        // [GIVEN] Update value of Dimension on Sales Header.
        DimensionSetID := UpdateDimensionOnSalesHeader(SalesHeader);

        // [GIVEN] Open Sales Order
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Update Ship-to Code on Sales Order
        SalesOrder.ShippingOptions.SetValue(ShipToOptions::"Alternate Shipping Address");

        // [THEN] Verify Dimension Set ID is not changed
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeader."No.");
        Assert.IsTrue(SalesHeader."Dimension Set ID" = DimensionSetID, DimensionSetIdHasChangedMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure VerifyServiceChargeLineIsRecreatedOnUpdateBillToCustomerOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        CustomerNo: array[2] of Code[20];
        ServiceChargeAmt: array[2] of Decimal;
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [SCENARIO 461917] Verify Service Charge line is removed and new is created on update Bill-to Customer on Sales Order
        // [GIVEN] Initialize
        Initialize();

        // [GIVEN] Enable invoice discount calculation on "Sales & Receivables Setup".
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Create two Customers with Service Charge line
        CreateCustomerWithServiceChargeAmount(CustomerNo[1], ServiceChargeAmt[1]);
        CreateCustomerWithServiceChargeAmount(CustomerNo[2], ServiceChargeAmt[2]);

        // [WHEN] Sales Order with customer
        CreateSalesOrderWithServiceCharge(SalesHeader, CustomerNo[1]);
        LibrarySales.CalcSalesDiscount(SalesHeader);

        // [THEN] Verify Charge Line is created
        FindSalesServiceChargeLine(SalesLine, SalesHeader);
        Assert.RecordCount(SalesLine, 1);
        SalesLine.TestField(Amount, ServiceChargeAmt[1]);

        // [WHEN] Sales Order page is opened, and Bill-to Customer is picked
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.BillToOptions.SetValue(BillToOptions::"Another Customer");
        SalesOrder."Bill-to Name".SetValue(CustomerNo[2]);

        // [THEN] Verify Charge Line is recreated
        FindSalesServiceChargeLine(SalesLine, SalesHeader);
        Assert.RecordCount(SalesLine, 1);
        SalesLine.TestField(Amount, ServiceChargeAmt[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SalesCreditMemoPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateSalesOrderQuantityWhenUsingCancelInvoiceifSalesCrMemoWorkflowIsEnabled()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesHeaderCrMemo: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        // [SCENARIO 474642] Verify Sales Order Quantities are updated back when using Cancel funtion in Sales Invoice
        // If there is a workflow for Sales Credit Memo enabled.
        Initialize();

        // [GIVEN] Create User Setup.
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, CopyStr(UserId(), 1, 50), '');
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify();

        // [GIVEN] Create and enable the Sales Credit Memo workflow.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // [GIVEN] Create Sales Document.
        CreateSalesDocument(
            SalesHeader,
            SalesLine,
            SalesHeader."Document Type"::Order,
            CreateCustomer(),
            CreateItem());

        // [GIVEN] Update Qty To Ship in Sales Line.
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(1, 2));
        SalesLine.Modify(true);

        // [GIVEN] Post the partial sales order.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel an Invoice.
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoices.CancelInvoice.Invoke();

        // [GIVEN] Send the approval request and Post the Sales Credit Memo.
        SalesHeaderCrMemo.Get(SalesHeaderCrMemo."Document Type"::"Credit Memo", LibraryVariableStorage.DequeueText());
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeaderCrMemo);
        SalesCreditMemo.SendApprovalRequest.Invoke();
        SalesCreditMemo.Post.Invoke();

        // [WHEN] Find the Sales Order Line
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        // [VERIFY] Verify Sales Order Quantities are updated in the sales line.
        Assert.Equal(SalesLine.Quantity, SalesLine."Outstanding Qty. (Base)");

        LibraryWorkflow.DeleteAllExistingWorkflows();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageOnSellToCustomerNameWhenCustomerIsBlock()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 488777] Error message occurs when sell to customer name validate instead of new customer create drop-down open.
        Initialize();

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Blocked the customer.
        Customer.Validate(Blocked, Customer.Blocked::All);
        Customer.Modify(true);

        // [GIVEN] Create a sales Order.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);

        // [VERIFY] Verify that error occurs when Sell to customer name validate instead of this customer is not registered drop down.
        asserterror SalesHeader.Validate("Sell-to Customer Name", Customer.Name);

        // [VERIFY] Verify error message when "Sell-to Customer Name" field Validate on Sales Order.
        Assert.ExpectedError(StrSubstNo(CustomerBlockedErr, Customer."No.", Customer.Blocked));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceShouldBeUpdatedwhenWeChangeUOMonCorrectiveSalesCreaditMemo()
    var
        Item: Record Item;
        UnitOfMeasure: array[2] of Record "Unit of Measure";
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocNo: Code[20];
        UnitPrice: Decimal;
        ExpectedUnitPrice: Decimal;
    begin
        // [SCENARIO 493409] Corrective Sales Credit Memo Amount is not re-calculated if we modify the UOM in the lines.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Unit Of Measure Code 1.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[1]);

        // [GIVEN] Create Unit Of Measure Code 2.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[2]);

        // [GIVEN] Create Item Unit Of Measure 1.
        LibraryInventory.CreateItemUnitOfMeasure(
            ItemUnitOfMeasure[1],
            Item."No.",
            UnitOfMeasure[1].Code,
            LibraryRandom.RandInt(0));

        // [GIVEN] Create Item Unit Of Measure 2.
        LibraryInventory.CreateItemUnitOfMeasure(
            ItemUnitOfMeasure[2],
            Item."No.",
            UnitOfMeasure[2].Code,
            LibraryRandom.RandIntInRange(4, 4));

        // [GIVEN] Create and Post Sales Order.
        CreateAndPostSalesOrder(SalesHeader, Item, UnitOfMeasure[2], UnitPrice, DocNo);

        // [GIVEN] Find Sales Invoice Header.
        SalesInvoiceHeader.Get(DocNo);

        // [GIVEN] Create Corrective Credit Memo.
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader2);

        // [GIVEN] Find Sales Line of created Sales Credit Memo.
        SalesLine2.SetRange("Document No.", SalesHeader2."No.");
        SalesLine2.SetRange("No.", Item."No.");
        SalesLine2.FindFirst();

        // [GIVEN] Generate and save Expected Unit Price in a Variable.
        ExpectedUnitPrice := ItemUnitOfMeasure[1]."Qty. per Unit of Measure" * UnitPrice / ItemUnitOfMeasure[2]."Qty. per Unit of Measure";

        // [WHEN] Validate Unit Of Measure Code 1 in Sales Line.
        SalesLine2.Validate("Unit of Measure Code", UnitOfMeasure[1].Code);
        SalesLine2.Modify(true);

        // [VERIFY] Verify Unit Price of Credit Memo Sales Line and Expected Unit Price are same.
        Assert.AreEqual(ExpectedUnitPrice, SalesLine2."Unit Price", UnitPriceMustMatchErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifySalesOrderUpdatedAfterCorrectPostedSalesInvoice()
    var
        SalesLine: array[3] of Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        // [SCENARIO 494700] Verify partially posted Sales Order updated correctly after posting Corrective Credit memo.
        Initialize();

        // [GIVEN] Create Sales Document.
        CreateSalesDocument(SalesHeader, SalesLine[1], SalesHeader."Document Type"::Order, CreateCustomer(), CreateItem());

        // [GIVEN] Create Sales Line 2
        CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, CreateItem(), LibraryRandom.RandDec(20, 2), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create Sales Line 3
        CreateSalesLine(SalesLine[3], SalesHeader, SalesLine[3].Type::Item, CreateItem(), LibraryRandom.RandDec(20, 2), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Update Qty To Ship in Sales Line 1
        SalesLine[1].Validate("Qty. to Ship", LibraryRandom.RandIntInRange(1, 2));
        SalesLine[1].Modify(true);

        // [GIVEN] Update Qty To Ship in Sales Line 2
        SalesLine[2].Validate("Qty. to Ship", LibraryRandom.RandIntInRange(1, 2));
        SalesLine[2].Modify(true);

        // [GIVEN] Post the partial Sales order.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create Corrective Credit Memo
        SalesCreditMemo.Trap();
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoices.CreateCreditMemo.Invoke();

        // [WHEN] Post the Corrective Credit Memo
        SalesCreditMemo.Post.Invoke();

        // [VERIFY] Verify Sales Order Quantities are updated in the sales line.
        VerifySalesOrderAfterPostCorrectiveCreditMemo(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('QtyToAssgnItemChargeModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckNoErrorOnDeletionOfChargeItemLineInSalesOrder()
    var
        SalesLine: Record "Sales Line";
        SalesLine1: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 495893] Delete invoiced Item Charge in Sales Order is not possible if there is VAT.
        Initialize();

        // [GIVEN] Create Sales Header
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // [GIVEN] Create Sales Line with Type Item
        CreateSalesLineWithUnitPrice(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDecInDecimalRange(5, 10, 0), LibraryRandom.RandDecInRange(500, 100, 2));

        // [GIVEN] Create Sales Line with Type Charge Item
        CreateSalesLineWithUnitPrice(
          SalesLine1, SalesHeader, SalesLine1.Type::"Charge (Item)", CreateItemChargeWithVAT(SalesLine."VAT Prod. Posting Group"), 1, LibraryRandom.RandDecInRange(50, 100, 2));

        // [GIVEN] Update the first Sales Line with Qty. to Ship as 1
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify();

        // [GIVEN] Post the Order with Shipment
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Assign the Item Charge Assignment On Second Sales Line
        OpenItemChargeAssgnt(SalesLine1, true, 1);

        // [GIVEN] Update the first Sales Line with Qty. to Invoice as 1
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Invoice", 1);
        SalesLine.Modify();

        // [GIVEN] Post the order with Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Reopen the Sales Document
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Delete the Sales Line with Type as Charge Item
        SalesLine1.Find();
        SalesLine1.Delete(true);

        // [THEN] No error is thrown
    end;

    [Test]
    procedure ReleasingOfSalesOrderHavingSalesLineWithoutUOMGivesError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 522444] When run Release action from a Sales Order having a Sales Line without
        // Unit of Measure Code, then it gives error and the document is not released.
        Initialize();

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine);

        // [WHEN] Validate Unit of Measure Code in Sales Line.
        SalesLine.Validate("Unit of Measure Code", '');
        SalesLine.Modify(true);

        // [THEN] Error is shown and the Sales Order is not released.
        asserterror LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyReserveQtyAfterAddingATOItemSubstitutionOnSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemSubstitution: Record "Item Substitution";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        LibraryAssembly: Codeunit "Library - Assembly";
        SalesOrder: TestPage "Sales Order";
    begin
        //[Scenario - 546745] In Sales Order page, After adding ATO Item Substitution in the Sales Line Item
        //Reserved Qty should Calculate.
        Initialize();

        // [GIVEN] Disable the Item Availability Notification
        LibraryNotificationMgt.DisableMyNotification(ItemCheckAvail.GetItemAvailabilityNotificationId());

        // [GIVEN] Create Sales Order and Validate 'Due Date' Field
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Due Date", CalcDate('2D', WorkDate()));
        SalesHeader.Modify(true);

        // [WHEN] Finding the Sales Line
        SalesLine.SetRange(SalesLine."Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(SalesLine."Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        // [WHEN] Substitution Item Created and assigned to the Main Item
        LibraryAssembly.CreateItemSubstitution(ItemSubstitution, SalesLine."No.");

        // [WHEN] Assiging and Validating the 'Replenishment System' and 'Assembly Policy' field in the Sustitution Item
        Item.Get(ItemSubstitution."Substitute No.");
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        //[WHEN] Making Inventory Quantity to 100 for the Main Item and Substitution Item
        UpdateItemInventoryNoLocation(SalesLine."No.", 100);
        UpdateItemInventoryNoLocation(ItemSubstitution."Substitute No.", 100);

        //[WHEN] Opening the Sales Order Page and Assigning the ATO Item Substitution for the Sales Order Line Item
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.SelectItemSubstitution.Invoke();

        //[THEN] Verifying that the ATO Item is changed in the SO Lines and the Reserved Qty should be calculated.
        SalesOrder.SalesLines."Reserved Quantity".AssertEquals(SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PlannedShippingDateMustBeUpdatedWhenShippingTimeExists()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingTime: DateFormula;
    begin
        // [SCENARIO 537460] When Validating "Planned Delivery Date" in Sales Line with blank "Shipment Date", it is correctly calculated.
        Initialize();

        // [GIVEN] Create Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Create a Shipping Time.
        Evaluate(ShippingTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(5)));

        // [GIVEN] Validate Shipping Time, Planned Delivery Date, Planned Shipment Date and Shipment Date.
        SalesLine.Validate("Shipping Time", ShippingTime);
        SalesLine.Validate("Planned Delivery Date", 0D);
        SalesLine.Validate("Planned Shipment Date", 0D);
        SalesLine.Validate("Shipment Date", 0D);

        // [WHEN] Validate Requested Delivery Date.
        SalesLine.Validate("Requested Delivery Date", Today());
        SalesLine.Modify(true);

        // [THEN] Planned Shipment Date is calculated from Shipping Time.
        Assert.AreEqual(
            SalesLine.CalcPlannedDate(),
            SalesLine."Planned Shipment Date",
            StrSubstNo(
                PlannedShipmentDateErr,
                SalesLine.CalcPlannedDate(),
                SalesLine.TableCaption()));
    end;

    [Test]
    procedure ServiceChargeLineIsNotRecreatedWhenChangePostingDateAndCalcInvDiscIsOff()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ServiceChargeAmt: Decimal;
    begin
        // [SCENARIO 557866]  Service Charge Line is not created automaticallly when user change posting date and
        // Calc. Inv Discount is off in Sales & Receivables Setup.
        Initialize();

        // [GIVEN] Disable invoice discount calculation on "Sales & Receivables Setup".
        LibrarySales.SetCalcInvDiscount(false);

        // [GIVEN] Create Customer with Service Charge Line.
        CreateCustomerWithServiceChargeAmount(CustomerNo, ServiceChargeAmt);

        // [GIVEN] Create Sales Order.
        CreateSalesOrderWithServiceCharge(SalesHeader, CustomerNo);

        // [WHEN] Posting Date is changed in Sales Order.
        SalesHeader.Validate("Posting Date", WorkDate() + 1);
        SalesHeader.Modify(true);

        // [THEN] Verify Service Charge Line is not created.
        Assert.IsFalse(FindSalesServiceChargeLineexist(SalesLine, SalesHeader), ServiceChargeLineExist);
    end;

    [Test]
    procedure CorrectPostedSalesInvoiceWithItemHasDimensionMandatory()
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        Item: Record Item;
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        Quantity: Decimal;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 575341] Verify correct a Posted Invoice with an Item that has Dimension Code Mandatory
        Initialize();
        Quantity := LibraryRandom.RandDecInRange(5, 5, 2);

        // [GIVEN] Create Dimension and Dimension Value.
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        // [GIVEN] Create an Item with Dimension and Value Posting as Code Mandatory.
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] Create Item Journal Line with Dimension Set ID.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, item."No.", '', '', LibraryRandom.RandDec(20, 2));
        ItemJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(ItemJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        ItemJournalLine.Modify(true);

        // [GIVEN] Post Item Joutnal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Sales Header
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // [GIVEN] Create first Sales Line with Dimension Set ID.
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, Item."No.", Quantity);
        SalesLine[1].Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine[1].Validate(
        "Dimension Set ID",
        LibraryDimension.CreateDimSet(SalesLine[1]."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        SalesLine[1].Modify(true);

        // [GIVEN] Create Second Sales Line with Qty. to Ship, Qty. to Invoice as 0.
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, Item."No.", Quantity);
        SalesLine[2].Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine[2].Validate("Qty. to Ship", 0);
        SalesLine[2].Validate("Qty. to Invoice", 0);
        SalesLine[2].Modify(true);

        // [GIVEN] Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Correct Posted Sales Invoice
        SalesInvHeader.Get(DocumentNo);
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);

        // [THEN] Verify Correction of Posted Sales Invoice done successfully.
        SalesInvHeader.CalcFields(Cancelled);
        Assert.IsTrue(SalesInvHeader.Cancelled,
             StrSubstNo(
                CorrectPostedSalesInvoiceErr,
                'TRUE',
                SalesInvHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure VerifySalesOrderUpdatedAfterPartialCorrectPostedSalesInvoice()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 578443] Verify quantity on posted Sales Order updated correctly after partial posting of Corrective Credit memo.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // [GIVEN] Create Sales Line with Quanity as 10.
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 10), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Update Qty To Ship in Sales Line.
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(5, 5));
        SalesLine.Modify(true);

        // [GIVEN] Post the partial Sales order.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Create Corrective Credit Memo.
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader2);

        // [GIVEN] Find Sales Line of created Sales Credit Memo.
        SalesLine2.SetRange("Document Type", SalesHeader2."Document Type");
        SalesLine2.SetRange("Document No.", SalesHeader2."No.");
        SalesLine2.SetRange("No.", Item."No.");
        SalesLine2.FindFirst();
        SalesLine2.Validate(Quantity, LibraryRandom.RandIntInRange(2, 2));
        SalesLine2.Modify(true);

        // [WHEN] Post the Corrective Credit Memo
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(Salesheader2);
        SalesCreditMemo.Post.Invoke();

        // [THEN] Verify Sales Order Qty. to Ship and Qty. to Invoice are updated as 7 in the sales line.
        VerifySalesOrderAfterPartialPostCorrectiveCreditMemo(SalesHeader."No.", 7);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure VerifySalesOrderUpdatedAfterCorrectPostedSalesInvoiceDifferentQuantity()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 578443] Verify quantity on posted Sales Order updated correctly after partial posting of Corrective Credit memo.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // [GIVEN] Create Sales Line with Quanity as 10.
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 10), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Update Qty To Ship in Sales Line.
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(3, 3));
        SalesLine.Modify(true);

        // [GIVEN] Ship the partial Sales order with Qty. to Ship as 3.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Update Qty To Ship in Sales Line as 2.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine2.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(2, 2));
        SalesLine2.Modify(true);

        // [GIVEN] Ship the partial Sales order with Qty. to Ship as 2.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Update Qty. to Ship as 0 and Qty. to Invoice as 5 in Sales Line.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine2.Validate("Qty. to Ship", 0);
        SalesLine2.Validate("Qty. to Invoice", 5);
        SalesLine2.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [GIVEN] Create Corrective Credit Memo.
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader2);

        // [WHEN] Post the Corrective Credit Memo
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(Salesheader2);
        SalesCreditMemo.Post.Invoke();

        // [THEN] Verify Sales Order Qty. to Ship and Qty. to Invoice are updated as 10 in the sales line.
        VerifySalesOrderAfterPartialPostCorrectiveCreditMemo(SalesHeader."No.", 10);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure VerifySalesOrderUpdatedAfterCorrectPostedSalesInvoiceApplyEntries()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 578443] Verify quantity on posted Sales Order updated correctly after posting of Corrective Credit memo with Application.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // [GIVEN] Create Sales Line with Quanity as 10.
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 10), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Update Qty To Ship in Sales Line as 5.
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(5, 5));
        SalesLine.Modify(true);

        // [GIVEN] Post the partial Sales order.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Create Corrective Credit Memo.
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader2);

        // [GIVEN] Set Applied-to ID on Customer Ledger Entry.
        CustLedgEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.FindFirst();
        CustLedgEntry."Applies-to ID" := SalesHeader2."No.";
        CustLedgEntry.CalcFields("Remaining Amount");
        CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";

        // [WHEN] Post the Corrective Credit Memo
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(Salesheader2);
        SalesCreditMemo.Post.Invoke();

        // [THEN] Verify Sales Order Qty. to Ship and Qty. to Invoice are updated as 10 in the sales line.
        VerifySalesOrderAfterPartialPostCorrectiveCreditMemo(SalesHeader."No.", 10);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PostedSalesDocumentLinesHandler')]
    procedure VerifyManuallyCreatedSalesCrMemoUpdateExistingSalesOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 578454] Verify manually created Sales Credit Memo with get posted document lines to reverse should update the existing Sales Order.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create Sales Line with Quanity as 10.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 10));

        // [GIVEN] Update Qty To Ship in Sales Line.
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(5, 5));
        SalesLine.Modify(true);

        // [GIVEN] Post the Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create Sales Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Credit Memo", Customer."No.");

        // [GIVEN] Run Get Document Lines to Reverse and copy from posted sales invoice
        GetPostedDocumentLines(SalesHeader2."No.", OptionString::PostedInvoices);
        FindSalesLine(SalesLine, SalesHeader2."Document Type", SalesHeader2."No.", SalesLine.Type::Item);

        // [WHEN] Post the Credit Memo
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader2);
        SalesCreditMemo.Post.Invoke();

        // [THEN] Verify Sales Order Qty. to Ship and Qty. to Invoice are updated as 10 in the sales line.
        VerifySalesOrderQuantityforManualSalesCreditMemo(SalesHeader."No.", 10);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMessage')]
    procedure MessageAddedUndoShipmentCreatesNegativeLineSalesShipmentWhenUndoneCancelledSalesInvoice()
    var
        // SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: array[2] of Record "Sales Shipment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        // [SCENARIO 579539] Message Added when Undo Shipment creates negative lines in Sales Shipment when already undone via cancelled Sales Invoice.
        Initialize();

        // [GIVEN] Find VATPostingSetup with Normal VAT Calculation Type.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        // UpdateDefaultQtyToShip(SalesReceivablesSetup."Default Quantity to Ship"::Blank);

        // [GIVEN] Create and Post Sales Order with partial shipment and invoice.
        CreateSalesDocument(
            SalesHeader[1],
            SalesLine,
            SalesHeader[1]."Document Type"::Order,
            CreateCustomer(),
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity);
        SalesLine.Modify(true);

        // [GIVEN] Post Sales Order with Shipment.
        LibrarySales.PostSalesDocument(SalesHeader[1], true, false);

        // [GIVEN] Find Sales Shipment Line created from posted Sales Order with Shipment.
        SalesShipmentLine[1].SetRange("Order No.", SalesHeader[1]."No.");

        // [GIVEN] Create Sales Invoice Header.
        LibrarySales.CreateSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, SalesHeader[1]."Sell-to Customer No.");

        // [GIVEN] Create Sales Line using Get Shipment.
        SalesGetShipment.SetSalesHeader(SalesHeader[2]);
        SalesGetShipment.CreateInvLines(SalesShipmentLine[1]);

        // [GIVEN] Post Sales Order with Invoice.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader[2], false, true));

        // [GIVEN] Cancel Posted Sales Invoice.
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [GIVEN] Find Sales Shipment Line created from posted Sales Order with Shipment.
        SalesShipmentLine[2].SetRange("Sell-to Customer No.", SalesHeader[1]."Sell-to Customer No.");
        SalesShipmentLine[2].SetRange("No.", SalesLine."No.");
        SalesShipmentLine[2].FindFirst();

        // [THEN] New Confrimation Message is shown when Undo Shipment creates negative lines in Sales Shipment.
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine[2]);
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Order");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Order");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Order");
    end;

    local procedure InitNotInvoicedData(var SalesHeader: Record "Sales Header"; var SalesLineTest: Record "Sales Line"; Value: Decimal; Quantity: Decimal; VAT: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATItem: Code[20];
    begin
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup."VAT %" := VAT;
        VATPostingSetup.Modify(true);
        VATItem := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        CreateSalesLine(SalesLineTest, SalesHeader, SalesLineTest.Type::Item, VATItem, Quantity, Value);
    end;

    local procedure VerifyNotInvoicedData(var SalesHeader: Record "Sales Header"; var SalesLineTest: Record "Sales Line"; CorrectAmountNoVAT: Decimal; CorrectAmountInclVAT: Decimal)
    var
        ErrorText: Text;
    begin
        ErrorText := 'Incorrect not invoiced amount calulcation';

        // Calculate outstanding fields on the Sales Line
        SalesLineTest.InitOutstanding();
        SalesLineTest.Modify(true);

        // Recalculate Sales Header flow fields
        SalesHeader.CalcFields("Amt. Ship. Not Inv. (LCY)");
        SalesHeader.CalcFields("Amt. Ship. Not Inv. (LCY) Base");

        // Verify amounts
        Assert.AreEqual(SalesHeader."Amt. Ship. Not Inv. (LCY)", CorrectAmountInclVAT, ErrorText);
        Assert.AreEqual(SalesHeader."Amt. Ship. Not Inv. (LCY) Base", CorrectAmountNoVAT, ErrorText);
    end;

    local procedure CreateAndModifySalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerInvDiscount());

        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10) * 2,
          LibraryRandom.RandInt(100));
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / 2);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateAndRegisterPick(ItemNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);

        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Register", WarehouseActivityLine);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerInvDiscount(): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer(), '', 0);  // Set Zero for Charge Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDecInRange(10, 20, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure CreateCustomerWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithContactWithEmailAndPhone(var Customer: Record Customer; var Contact: Record Contact; Email: Text)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibrarySales.CreateCustomer(Customer);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.FindFirst();
        Contact.Get(ContactBusinessRelation."Contact No.");
        Contact.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Contact.Validate("Phone No.", LibraryUtility.GenerateRandomNumericText(MaxStrLen(Contact."Phone No.")));
        Contact.Modify(true);
        Customer.Contact := Contact.Name;
        Customer."E-Mail" := Contact."E-Mail";
        Customer."Phone No." := Contact."Phone No.";
        Customer.Modify();

        Contact.Type := Contact.Type::Person;
        Contact."No." := '';
        Contact.Name := LibraryUtility.GenerateGUID();
        Contact."E-Mail" := CopyStr(Email, 1, StrLen(Contact."E-Mail"));
        Contact."Phone No." := CopyStr(LibraryUtility.GenerateRandomNumericText(MaxStrLen(Contact."Phone No.")), 1, MaxStrLen(Contact."Phone No."));
        Contact.Insert(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAndUpdateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CreateCurrency());
        Currency.Validate("Invoice Rounding Precision", 1);
        Currency.Validate("Amount Rounding Precision", 1);
        Currency.Validate("Amount Decimal Places", '0:0');
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreatePostSalesOrderWithDimension(var SalesHeader: Record "Sales Header"; ItemDimValue: Record "Dimension Value"; DimensionCode: Code[20]; DimValueCode: Code[20]): Integer
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(100));
        ModifyDimOnSalesLine(SalesLine, ItemDimValue, DimensionCode, DimValueCode);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Dimension Set ID");
    end;

    local procedure CreatePostInvoiceWithShipmentLines(ItemChargeDimValue: Record "Dimension Value"; DimensionCode: Code[20]; DimValueCode: Code[20]; OrderSalesHeader: Record "Sales Header"): Integer
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, OrderSalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", CreateItemCharge(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", 100);
        ModifyDimOnSalesLine(SalesLine, ItemChargeDimValue, DimensionCode, DimValueCode);
        SalesLine.Modify(true);
        AssignItemChargeToShipment(OrderSalesHeader."No.", SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Dimension Set ID");
    end;

    local procedure CreateItemAndExtendedText(var Item: Record Item): Text[50]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        UpdateTextInExtendedTextLine(ExtendedTextLine, Item."No.");
        exit(ExtendedTextLine.Text);
    end;

    local procedure CreateItemCharge(): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        exit(ItemCharge."No.");
    end;

    local procedure CreateItemChargeWithVAT(VATProdPostingGroup: Code[20]): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemCharge.Modify(true);
        exit(ItemCharge."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);

        // Using RANDOM value for Unit Price.
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Modify(true);
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateItemJournalLinePositiveAdjustment(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateSalesInvoiceWithCurrency(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Currency: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create Sales Invoice with Currency.
        LibraryERM.FindCurrency(Currency);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);

        // Take Random Values for Quantity and Line Discount fields.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLines(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
    begin
        // Using random value because value is not important.
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do begin
            VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item,
              CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));
        end;
    end;

    local procedure CreateDimValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateDimValues(var Dimension: Record Dimension; var DimensionValueCode: array[2] of Code[20])
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        for i := 1 to ArrayLen(DimensionValueCode) do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
            DimensionValueCode[i] := DimensionValue.Code;
        end;
    end;

    local procedure CreateDimSetIDFromDimValue(var DimSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionMgt: Codeunit DimensionManagement;
    begin
        if DimSetID <> 0 then
            DimensionMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        if not TempDimSetEntry.Insert() then
            TempDimSetEntry.Modify();
        DimSetID := DimensionMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    local procedure CreateSalesLineWithQty(var SalesLine: Record "Sales Line"; Qty: Decimal; DocType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CreateCustomer());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(20, 2), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSimpleSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type")
    var
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.Validate("Document No.", SalesHeader."No.");
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
        SalesLine.Validate(Type, LineType);
        SalesLine.Insert(true);
    end;

    local procedure CreatePostSalesOrderForUndoShipment(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; AccountType: Enum "Sales Line Type"; AccountNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLine(
            SalesLine,
            SalesHeader,
            AccountType,
            AccountNo,
            LibraryRandom.RandDec(20, 2),
            LibraryRandom.RandDec(100, 2));

        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / LibraryRandom.RandIntInRange(2, 4)); // To make sure Qty. to ship must be less than Quantity.
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreatePostSalesReturnOrderForUndoReceipt(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; AccountType: Enum "Sales Line Type"; AccountNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::"Return Order",
            LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLine(
            SalesLine,
            SalesHeader,
            AccountType,
            AccountNo,
            LibraryRandom.RandDec(20, 2),
            LibraryRandom.RandDec(100, 2));

        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity / LibraryRandom.RandIntInRange(2, 4));
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure FindSalesShipmentHeader(var SalesShipmentHeader: Record "Sales Shipment Header"; OrderNo: Code[20])
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; ReturnOrderNo: Code[20])
    begin
        ReturnReceiptLine.SetRange("Return Order No.", ReturnOrderNo);
        ReturnReceiptLine.FindFirst();
    end;

    local procedure SalesLinesWithMinimumQuantity(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; SalesLineDiscount: Record "Sales Line Discount")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
    begin
        // Using random value for the Quantity. Take Quantity greater than Sales Line Discount Minimum Quantity.
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, SalesLineDiscount.Code,
              SalesLineDiscount."Minimum Quantity" + LibraryRandom.RandDec(10, 2));
        end;
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
    begin
        // Set Stock out Warnings to No in Sales and Receivables Setup.
        LibrarySales.SetStockoutWarning(false);
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        // Create Sales Order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // Create Random Sales Lines. Make sure that No. of Sales Lines always more than 1.
        for Counter := 1 to 1 + LibraryRandom.RandInt(8) do
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item,
              CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesOrderWithSingleLine(var SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesOrderAndGetDiscountWithoutVAT(var SalesHeader: Record "Sales Header") ExpectedInvDiscAmount: Decimal
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerInvDiscount());
        LibraryInventory.CreateItem(Item);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(1000, 2));
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        ExpectedInvDiscAmount := SalesLine."Inv. Discount Amount";
    end;

    local procedure CreateSalesOrderWithQuoteNo(var SalesHeaderOrderFromQuote: Record "Sales Header")
    var
        SalesHeaderQuote: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeaderQuote, SalesHeaderQuote."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesHeader(
          SalesHeaderOrderFromQuote, SalesHeaderOrderFromQuote."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeaderOrderFromQuote.Validate("Quote No.", SalesHeaderOrderFromQuote."No.");
        SalesHeaderOrderFromQuote.Modify(true);
    end;

    local procedure CreateSalesDocumentWithInvDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Qty: Decimal; UnitPrice: Decimal; InvDiscPercent: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer(), '', 0);
        CustInvoiceDisc.Validate("Discount %", InvDiscPercent);
        CustInvoiceDisc.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustInvoiceDisc.Code);
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), Qty, UnitPrice);
    end;

    local procedure PostShipSalesOrderWithVAT(var SalesShipmentLine: Record "Sales Shipment Line"; SalesHeader: Record "Sales Header") ExpectedInvDiscAmount: Decimal
    begin
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.CalcFields("Invoice Discount Amount");
        ExpectedInvDiscAmount := SalesHeader."Invoice Discount Amount";
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");
    end;

    local procedure CreateWarehouseLocation(): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        exit(Location.Code);
    end;

    local procedure CreateSalesHeaderWithCurrency(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreatePostSalesInvoiceWithZeroAmount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Code[20]
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        SalesLine.Validate("Unit Price", 0);
        SalesLine.Modify();
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure MockGLAccountWithNoAndDescription(NewNo: Code[20]; NewName: Text[50])
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);

        GLAccount.Init();
        GLAccount."No." := NewNo;
        GLAccount.Name := NewName;
        GLAccount."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        GLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GLAccount.Insert();
    end;

    local procedure MockItemWithNoAndDescription(NewNo: Code[20]; NewDescription: Text[50])
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        if not InventoryPostingGroup.FindFirst() then
            LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);

        Item.Init();
        Item."No." := NewNo;
        Item.Description := NewDescription;
        Item."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item."Inventory Posting Group" := InventoryPostingGroup.Code;
        Item.Insert();
    end;

    local procedure MockItemChargeWithNoAndDescription(NewNo: Code[20]; NewDescription: Text[50])
    var
        ItemCharge: Record "Item Charge";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        ItemCharge.Init();
        ItemCharge."No." := NewNo;
        ItemCharge.Description := NewDescription;
        ItemCharge."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        ItemCharge."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        ItemCharge.Insert();
    end;

    local procedure MockFAWithNoAndDescription(NewNo: Code[20]; NewDescription: Text[50])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Init();
        FixedAsset."No." := NewNo;
        FixedAsset.Description := NewDescription;
        FixedAsset.Insert();
    end;

    local procedure MockResourceWithNoAndDescription(NewNo: Code[20]; NewName: Text[50])
    var
        Resource: Record Resource;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        UnitOfMeasure: Record "Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryInventory.FindUnitOfMeasure(UnitOfMeasure);

        Resource.Init();
        Resource."No." := NewNo;
        Resource.Name := NewName;
        Resource."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        Resource."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Resource."Base Unit of Measure" := UnitOfMeasure.Code;
        Resource.Insert();

        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, Resource."No.", UnitOfMeasure.Code, 1);
    end;

    local procedure MockStandardText(NewCode: Code[20]; NewDescription: Text[50])
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Init();
        StandardText.Code := NewCode;
        StandardText.Description := NewDescription;
        StandardText.Insert();
    end;

    local procedure MockSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := DocumentNo;
        SalesHeader.Insert();
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Insert();
    end;

    local procedure MockSalesLineWithShipNotInvLCY(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ShippedNotInv_Base: Decimal; ShippedNotInv: Decimal)
    begin
        MockSalesLine(SalesLine, SalesHeader);
        SalesLine."Shipped Not Inv. (LCY) No VAT" := ShippedNotInv_Base;
        SalesLine."Shipped Not Invoiced (LCY)" := ShippedNotInv;
        SalesLine.Modify();
    end;

    local procedure FindCustomerInvoiceDiscount("Code": Code[20]): Decimal
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvoiceDisc.SetRange(Code, Code);
        CustInvoiceDisc.FindFirst();
        exit(CustInvoiceDisc."Discount %");
    end;

    local procedure FindShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        FindSalesShipmentHeader(SalesShipmentHeader, OrderNo);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindSalesLines(var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.FindSet();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindSalesLineWithType(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type")
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, LineType);
        SalesLine.FindSet();
    end;

    local procedure FindItemChargeAssignmentSalesLine(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; SalesLine: Record "Sales Line")
    begin
        ItemChargeAssignmentSales.SetRange("Document Type", SalesLine."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", SalesLine."Document No.");
        ItemChargeAssignmentSales.SetRange("Document Line No.", SalesLine."Line No.");
        ItemChargeAssignmentSales.FindSet();
    end;

    local procedure GetReceivablesAccountNo(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetSalesAccountNo(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        exit(GeneralPostingSetup."Sales Account");
    end;

    local procedure CopySalesLines(var SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line")
    begin
        FindSalesLines(SalesLine2);
        repeat
            SalesLine.Init();
            SalesLine := SalesLine2;
            SalesLine.Insert();
        until SalesLine2.Next() = 0;
    end;

    local procedure TotalLineDiscountInGLEntry(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        SalesLine.FindSet();
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Sales Line Disc. Account");
        exit(TotalAmountInGLEntry(GLEntry));
    end;

    local procedure TotalInvoiceDiscountInGLEntry(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        SalesLine.FindSet();
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Sales Inv. Disc. Account");
        exit(TotalAmountInGLEntry(GLEntry));
    end;

    local procedure ModifyDimOnSalesLine(var SalesLine: Record "Sales Line"; BaseDimValue: Record "Dimension Value"; DimensionCode: Code[20]; DimValueCode: Code[20])
    var
        DimValue: Record "Dimension Value";
    begin
        CreateDimSetIDFromDimValue(SalesLine."Dimension Set ID", BaseDimValue);
        DimValue.Get(DimensionCode, DimValueCode);
        CreateDimSetIDFromDimValue(SalesLine."Dimension Set ID", DimValue);
    end;

    local procedure AssignItemChargeToShipment(OrderNo: Code[20]; SalesLine: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        FindShipmentLine(SalesShipmentLine, OrderNo);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");
    end;

    local procedure AssignQtyToOneLine(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; SalesLine: Record "Sales Line"; QtyToAssign: Decimal)
    begin
        FindItemChargeAssignmentSalesLine(ItemChargeAssignmentSales, SalesLine);
        repeat
            ItemChargeAssignmentSales.Validate("Qty. to Assign", 0);
            ItemChargeAssignmentSales.Modify(true);
        until ItemChargeAssignmentSales.Next() = 0;
        ItemChargeAssignmentSales.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssignmentSales.Modify(true);
    end;

    local procedure TotalAmountInGLEntry(var GLEntry: Record "G/L Entry") TotalAmount: Decimal
    begin
        GLEntry.FindSet();
        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
    end;

    local procedure FindSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; OrderNo: Code[20])
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure InitGlobalVariables()
    begin
        Clear(TempDocumentEntry2);
        Clear(PostingDate2);
        DocumentNo2 := '';
    end;

    local procedure InvoiceShippedSalesOrder(var InvSalesHeader: Record "Sales Header"; ShippedSalesHeader: Record "Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        LibrarySales.CreateSalesHeader(
          InvSalesHeader, InvSalesHeader."Document Type"::Invoice, ShippedSalesHeader."Sell-to Customer No.");

        SalesGetShipment.SetSalesHeader(InvSalesHeader);
        SalesShipmentHeader.SetRange("Order No.", ShippedSalesHeader."No.");
        SalesShipmentHeader.FindSet();
        repeat
            SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
            SalesGetShipment.CreateInvLines(SalesShipmentLine);
        until SalesShipmentHeader.Next() = 0;
    end;

    local procedure CrMemoShippedSalesReturnOrder(var CrMemoSalesHeader: Record "Sales Header"; ShippedSalesHeader: Record "Sales Header")
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        LibrarySales.CreateSalesHeader(
          CrMemoSalesHeader, CrMemoSalesHeader."Document Type"::"Credit Memo", ShippedSalesHeader."Sell-to Customer No.");

        SalesGetReturnReceipts.SetSalesHeader(CrMemoSalesHeader);
        ReturnReceiptHeader.SetRange("Return Order No.", ShippedSalesHeader."No.");
        ReturnReceiptHeader.FindSet();
        repeat
            ReturnReceiptLine.SetRange("Document No.", ReturnReceiptHeader."No.");
            SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
        until ReturnReceiptHeader.Next() = 0;
    end;

    local procedure OpenSalesOrderAndPost(SalesHeaderNo: Code[20]; Status: Enum "Sales Document Status")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter(Status, Format(Status));
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        SalesOrder.Post.Invoke();
    end;

    local procedure SetupInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
        // Required random value for Minimum Amount and Discount Pct fields, value is not important.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer(), '', LibraryRandom.RandInt(100));
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(99, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure SetupLineDiscount(var SalesLineDiscount: Record "Sales Line Discount")
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        // Required random Value for Minimum Quantity and Line Discount Pct fields, value is not important.
        Item.Get(CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        LibraryERM.CreateLineDiscForCustomer(SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.",
          SalesLineDiscount."Sales Type"::Customer, CreateCustomer(), WorkDate(), '', Item."Variant Filter",
          Item."Base Unit of Measure", LibraryRandom.RandInt(10));
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(99, 2));
        SalesLineDiscount.Modify(true);
    end;

    local procedure UpdateSalesReceivableSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Posting Date", SalesReceivablesSetup."Default Posting Date"::"No Date");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateDefaultQtyToShip(NewDefaultQtyToShip: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Quantity to Ship", NewDefaultQtyToShip);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateManualNosOnSalesOrderNoSeries(ManualNos: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        SalesReceivablesSetup.Get();
        NoSeries.Get(SalesReceivablesSetup."Order Nos.");
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Modify(true);
    end;

    local procedure UpdateDefaultWarehouseSetup(RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Require Put-away", RequirePutAway);
        WarehouseSetup.Validate("Require Pick", RequirePick);
        WarehouseSetup.Validate("Require Receive", RequireReceive);
        WarehouseSetup.Validate("Require Shipment", RequireShipment);
        WarehouseSetup.Modify(true);
    end;

    local procedure UpdateQtyToShipAndInvoiceOnSalesLine(var SalesLine: Record "Sales Line"; QtyToShip: Decimal; QtyToInvoice: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyToReturnReceiveAndInvoiceOnSalesLine(var SalesLine: Record "Sales Line"; QtyToReturnReceive: Decimal; QtyToInvoice: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Return Qty. to Receive", QtyToReturnReceive);
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure SumLineDiscountAmount(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]) LineDiscountAmount: Decimal
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
        repeat
            LineDiscountAmount += SalesLine."Line Discount Amount";
        until SalesLine.Next() = 0;
    end;

    local procedure SumInvoiceDiscountAmount(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]) InvoiceDiscountAmount: Decimal
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
        repeat
            InvoiceDiscountAmount += SalesLine."Inv. Discount Amount";
        until SalesLine.Next() = 0;
    end;

    local procedure ShipSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure ShipSalesOrderWithInvDiscAmount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        CreateSalesOrder(SalesHeader, SalesLine);
        SalesLine.Validate("Inv. Discount Amount", Round(SalesLine."Line Amount" * LibraryRandom.RandDec(1, 2)));
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure ShipSalesReturnOrderWithInvDiscAmount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer(), LibraryInventory.CreateItemNo());
        SalesLine.Validate("Inv. Discount Amount", Round(SalesLine."Line Amount" * LibraryRandom.RandDec(1, 2)));
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure ShipWarehouseDocument(DocumentNo: Code[20]; LineNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source No.", DocumentNo);
        WarehouseShipmentLine.SetRange("Source Line No.", LineNo);
        WarehouseShipmentLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Shipment", WarehouseShipmentLine);
    end;

    local procedure UpdateBalanceAccountNo(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        GenJournalBatch.Modify(true);
    end;

    local procedure UpdateDocumentNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Document No.", GenJournalLine."Account No.");
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateTextInExtendedTextLine(var ExtendedTextLine: Record "Extended Text Line"; Text: Code[20])
    begin
        ExtendedTextLine.Validate(Text, Text);
        ExtendedTextLine.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(var OldStockoutWarning: Boolean; NewStockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateCalcInvDiscountSetup(NewCalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", NewCalcInvDiscount);
        SalesReceivablesSetup.Modify();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure UpdateInvoiceDiscountAndVATAmountOnSalesOrderStatistics(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; AmountToPost: Decimal; VATAmount: Decimal; VATDiffAmount: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        UpdateVATAmountOnSalesOrderStatistics(SalesHeader, SalesOrder);

        SalesLine.Find();
        SalesLine.TestField("VAT Difference", VATDiffAmount);

        SalesOrder.SalesLines."Total Amount Excl. VAT".AssertEquals(AmountToPost);
        SalesOrder.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
        SalesOrder.SalesLines."Total Amount Incl. VAT".AssertEquals(AmountToPost + VATAmount);
        SalesOrder.Close();

        SalesHeader.Find();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");

        SalesLine.TestField("VAT Difference", VATDiffAmount);

        SalesOrder.SalesLines."Total Amount Excl. VAT".AssertEquals(AmountToPost);
        SalesOrder.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
        SalesOrder.SalesLines."Total Amount Incl. VAT".AssertEquals(AmountToPost + VATAmount);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure UpdateVATAmountOnSalesOrderStatistics(var SalesHeader: Record "Sales Header"; var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.Statistics.Invoke();
        SalesOrder.GotoRecord(SalesHeader);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure UpdateInvoiceDiscountAndVATAmountOnStatistics(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; AmountToPost: Decimal; VATAmount: Decimal; VATDiffAmount: Decimal)
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenView();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.Statistics.Invoke();
        SalesInvoice.GotoRecord(SalesHeader);

        SalesLine.Find();
        SalesLine.TestField("VAT Difference", VATDiffAmount);

        SalesInvoice.SalesLines."Total Amount Excl. VAT".AssertEquals(AmountToPost);
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
        SalesInvoice.SalesLines."Total Amount Incl. VAT".AssertEquals(AmountToPost + VATAmount);
        SalesInvoice.Close();

        SalesHeader.Find();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesInvoice.OpenView();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        SalesLine.TestField("VAT Difference", VATDiffAmount);

        SalesInvoice.SalesLines."Total Amount Excl. VAT".AssertEquals(AmountToPost);
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
        SalesInvoice.SalesLines."Total Amount Incl. VAT".AssertEquals(AmountToPost + VATAmount);
    end;
#endif
    local procedure UpdateInvoiceDiscountAndVATAmountOnSalesOrderStatisticsNM(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; AmountToPost: Decimal; VATAmount: Decimal; VATDiffAmount: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        UpdateVATAmountOnSalesOrderStatisticsNM(SalesHeader, SalesOrder);
        //workaround for issue with non-modal statistics testpage not updating totals
        SalesOrder.Close();
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);

        SalesLine.Find();
        SalesLine.TestField("VAT Difference", VATDiffAmount);

        SalesOrder.SalesLines."Total Amount Excl. VAT".AssertEquals(AmountToPost);
        SalesOrder.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
        SalesOrder.SalesLines."Total Amount Incl. VAT".AssertEquals(AmountToPost + VATAmount);
        SalesOrder.Close();

        SalesHeader.Find();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");

        SalesLine.TestField("VAT Difference", VATDiffAmount);

        SalesOrder.SalesLines."Total Amount Excl. VAT".AssertEquals(AmountToPost);
        SalesOrder.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
        SalesOrder.SalesLines."Total Amount Incl. VAT".AssertEquals(AmountToPost + VATAmount);
    end;

    local procedure UpdateInvoiceDiscountAndVATAmountOnSalesStatisticsNM(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; AmountToPost: Decimal; VATAmount: Decimal; VATDiffAmount: Decimal)
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.SalesStatistics.Invoke();
        //workaround for issue with non-modal statistics testpage not updating totals
        SalesInvoice.Close();
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);

        SalesLine.Find();
        SalesLine.TestField("VAT Difference", VATDiffAmount);

        SalesInvoice.SalesLines.Next();// GoToRecord(SalesLine);
        SalesInvoice.SalesLines."Total Amount Excl. VAT".AssertEquals(AmountToPost);
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
        SalesInvoice.SalesLines."Total Amount Incl. VAT".AssertEquals(AmountToPost + VATAmount);
        SalesInvoice.Close();

        SalesHeader.Find();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);

        SalesLine.TestField("VAT Difference", VATDiffAmount);

        SalesInvoice.SalesLines."Total Amount Excl. VAT".AssertEquals(AmountToPost);
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
        SalesInvoice.SalesLines."Total Amount Incl. VAT".AssertEquals(AmountToPost + VATAmount);
        SalesInvoice.Close();
    end;

    local procedure UpdateVATAmountOnSalesOrderStatisticsNM(var SalesHeader: Record "Sales Header"; var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesOrderStatistics.Invoke();
        SalesOrder.GotoRecord(SalesHeader);
    end;

    local procedure EnableVATDiffAmount() Result: Decimal
    begin
        Result := LibraryRandom.RandDec(2, 2);  // Use any Random decimal value between 0.01 and 1.99, value is not important.
        LibraryERM.SetMaxVATDifferenceAllowed(Result);
        LibrarySales.SetAllowVATDifference(true);
    end;

    local procedure CreateVATPostingSetupWithBusPostGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATBusinessPostingGroup: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup."VAT %" := LibraryRandom.RandInt(30);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup."Reverse Chrg. VAT Acc." := VATPostingSetup."Purchase VAT Account";
        VATPostingSetup."VAT Calculation Type" := VATCalculationType;
        VATPostingSetup."VAT Identifier" := LibraryUtility.GenerateGUID();
        VATPostingSetup.Modify();
    end;

    local procedure CreateSalesInvoiceWithItemCharge(var InvoiceSalesHeader: Record "Sales Header"; PostedSalesHeader: Record "Sales Header"; PricesIncludingVAT: Boolean)
    var
        ItemCharge: Record "Item Charge";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
    begin
        LibrarySales.CreateSalesHeader(
          InvoiceSalesHeader, InvoiceSalesHeader."Document Type"::Invoice, PostedSalesHeader."Sell-to Customer No.");

        if InvoiceSalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesLine."Currency Code");

        InvoiceSalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        InvoiceSalesHeader.Modify(true);

        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          InvoiceSalesHeader."VAT Bus. Posting Group");
        ItemCharge.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ItemCharge.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, InvoiceSalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Cost", Round(SalesLine.Amount / SalesLine.Quantity, Currency."Unit-Amount Rounding Precision"));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithItemsAndAssignedItemCharge(var SalesHeader: Record "Sales Header"; SuggestType: Integer)
    var
        ItemCharge: Record "Item Charge";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        if SalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesHeader."Currency Code");

        for i := 1 to 3 do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
            SalesLine.Validate("Unit Price", 10);
            SalesLine.Modify(true);
        end;

        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          SalesHeader."VAT Bus. Posting Group");
        ItemCharge.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ItemCharge.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate("Unit Cost", Round(SalesLine.Amount / SalesLine.Quantity, Currency."Unit-Amount Rounding Precision"));
        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(SuggestType);

        SalesLine.ShowItemChargeAssgnt();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Modify Item No. Series in Inventory setup.
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Unit Price.
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        if VATPostingSetup."VAT Prod. Posting Group" <> Item."VAT Prod. Posting Group" then
            Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesLineWithUnitPrice(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", DirectUnitCost);
        SalesLine.Modify(true);
    end;

    local procedure OpenItemChargeAssgnt(SalesLine: Record "Sales Line"; IsSetup: Boolean; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(IsSetup);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.ShowItemChargeAssgnt();
    end;

    local procedure SalesOrderItemChargeAssignment(var SalesLine: Record "Sales Line"; var AmountToAssign: Decimal; var QtyToAssign: Decimal; SuggestChoice: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrderWithItemsAndAssignedItemCharge(SalesHeader, SuggestChoice);

        FindSalesLineWithType(SalesLine, SalesHeader."No.", SalesHeader."Document Type", SalesLine.Type::"Charge (Item)");
        AmountToAssign := SalesLine."Unit Cost" * SalesLine.Quantity;
        QtyToAssign := SalesLine.Quantity;
    end;

    local procedure PostSalesInvoiceWithItemCharge(var SalesInvoiceNo: Code[20]; var AssignedAmount: Decimal; PricesInclVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCharge: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), LibraryInventory.CreateItemNo());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        CreateSalesInvoiceWithItemCharge(SalesHeaderCharge, SalesHeader, PricesInclVAT);
        SalesLine.SetRange("Document Type", SalesHeaderCharge."Document Type");
        SalesLine.SetRange("Document No.", SalesHeaderCharge."No.");
        SalesLine.FindFirst();
        FindShipmentLine(SalesShipmentLine, SalesHeader."No.");
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");
        LibraryVariableStorage.Enqueue(SalesHeaderCharge."No.");
        AssignedAmount := ItemChargeAssignmentSales."Amount to Assign";

        PAGE.RunModal(PAGE::"Sales Statistics", SalesHeaderCharge);

        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeaderCharge, true, true);
    end;

    [Scope('OnPrem')]
    procedure PostWarehouseShipmentLine(SalesHeaderNo: Code[20]; SalesLineLineNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source No.", SalesHeaderNo);
        WarehouseShipmentLine.SetRange("Source Line No.", SalesLineLineNo);
        WarehouseShipmentLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Shipment", WarehouseShipmentLine);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalGLAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.CalcSums(Amount);
        TotalGLAmount += GLEntry.Amount;
        Assert.AreNearlyEqual(
          Amount, TotalGLAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreNearlyEqual(
          Amount, CustLedgerEntry."Amount (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption("Amount (LCY)"), Amount, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyInvoiceDiscountAmount(SalesLine: Record "Sales Line"; DocumentNo: Code[20]; InvoiceDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Sales Inv. Disc. Account");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), InvoiceDiscountAmount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, SalesLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, SalesLine.FieldCaption("Inv. Discount Amount"), InvoiceDiscountAmount, SalesLine.TableCaption()));
    end;

    local procedure VerifyLineDiscountAmount(SalesLine: Record "Sales Line"; DocumentNo: Code[20]; LineDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Sales Line Disc. Account");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          LineDiscountAmount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), LineDiscountAmount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          LineDiscountAmount, SalesLine."Line Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, SalesLine.FieldCaption("Line Discount Amount"), LineDiscountAmount, SalesLine.TableCaption()));
    end;

    local procedure VerifyPostedSalesInvoice(DocumentNo: Code[20]; LineDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        GeneralLedgerSetup.Get();
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        Assert.AreNearlyEqual(
          LineDiscountAmount, SalesInvoiceLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, SalesInvoiceLine.FieldCaption("Inv. Discount Amount"), LineDiscountAmount, SalesInvoiceLine.TableCaption()));
    end;

    local procedure VerifyRemainingAmountLCY(CustomerNo: Code[20]; RemainingAmtLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
    begin
        // Verifing Remaining Amount(LCY).
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        Currency.Get(CustLedgerEntry."Currency Code");
        Assert.AreNearlyEqual(
          RemainingAmtLCY, CustLedgerEntry."Remaining Amt. (LCY)", Currency."Invoice Rounding Precision",
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption("Remaining Amt. (LCY)"),
            RemainingAmtLCY, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        TotalVATAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Base, Amount);
        TotalVATAmount += Abs(VATEntry.Base + VATEntry.Amount);
        Assert.AreNearlyEqual(
          Amount, TotalVATAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATEntryAmounts(VATEntry: Record "VAT Entry"; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    begin
        VATEntry.TestField(Base, ExpectedBase);
        VATEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ValueEntry: Record "Value Entry";
        SalesAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.CalcSums("Sales Amount (Actual)");
        SalesAmount += ValueEntry."Sales Amount (Actual)";
        Assert.AreNearlyEqual(
          Amount, SalesAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, ValueEntry.FieldCaption("Sales Amount (Actual)"), Amount, ValueEntry.TableCaption()));
    end;

    local procedure VerifyValueEntryAmountsForItem(ItemNo: Code[20]; SalesAmountExpected: Decimal; SalesAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Sales Amount (Expected)", "Sales Amount (Actual)");
        ValueEntry.TestField("Sales Amount (Expected)", SalesAmountExpected);
        ValueEntry.TestField("Sales Amount (Actual)", SalesAmountActual);
    end;

    local procedure VerifyNavigateRecords(var DocumentEntry: Record "Document Entry"; TableID: Integer; NoOfRecords: Integer)
    begin
        DocumentEntry.SetRange("Table ID", TableID);
        DocumentEntry.FindFirst();
        DocumentEntry.TestField("No. of Records", NoOfRecords);
    end;

    local procedure VerifyPostedEntries(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        ValueEntry: Record "Value Entry";
    begin
        VerifyPostedPaymentNavigation(DocumentNo);

        VATEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"VAT Entry", VATEntry.Count);

        ValueEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"Value Entry", ValueEntry.Count);
    end;

    local procedure VerifyPostedPaymentNavigation(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"G/L Entry", GLEntry.Count);

        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"Cust. Ledger Entry", CustLedgerEntry.Count);

        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"Detailed Cust. Ledg. Entry", DetailedCustLedgEntry.Count);
    end;

    local procedure VerifyPostedShipmentLine(var SalesLine: Record "Sales Line")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesLine.FindSet();
        FindSalesShipmentHeader(SalesShipmentHeader, SalesLine."Document No.");
        repeat
            SalesShipmentLine.Get(SalesShipmentHeader."No.", SalesLine."Line No.");
            SalesShipmentLine.TestField(Quantity, SalesLine.Quantity);
            SalesShipmentLine.TestField("Unit Price", SalesLine."Unit Price");
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyVATOnSalesInvoice(SalesLine: Record "Sales Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountSalesLine: Decimal;
    begin
        GeneralLedgerSetup.Get();
        FindSalesLines(SalesLine);
        repeat
            VATAmountSalesLine := SalesLine."Line Amount" * (1 + SalesLine."VAT %" / 100);
            Assert.AreNearlyEqual(
              VATAmountSalesLine, SalesLine."Amount Including VAT", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(VATAmountErr, VATAmountSalesLine, SalesLine.TableCaption()));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyLineDiscountOnInvoice(SalesLine: Record "Sales Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LineDiscountAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        FindSalesLines(SalesLine);
        repeat
            LineDiscountAmount := Round(SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100);
            Assert.AreNearlyEqual(
              LineDiscountAmount, SalesLine."Line Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(AmountErr, SalesLine.FieldCaption("Line Discount Amount"), LineDiscountAmount, SalesLine.TableCaption()));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyInvoiceDiscountOnInvoice(SalesLine: Record "Sales Line"; CustInvoiceDisc: Record "Cust. Invoice Disc.")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        InvoiceDiscountAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        FindSalesLines(SalesLine);
        repeat
            InvoiceDiscountAmount := Round(SalesLine."Line Amount" * CustInvoiceDisc."Discount %" / 100);
            Assert.AreNearlyEqual(
              InvoiceDiscountAmount, SalesLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(AmountErr, SalesLine.FieldCaption("Inv. Discount Amount"), InvoiceDiscountAmount, SalesLine.TableCaption()));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyUndoShipmentLineOnPostedShipment(SalesLine: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentLine.SetRange(Type, SalesLine.Type);
        SalesShipmentLine.SetRange("No.", SalesLine."No.");
        SalesShipmentLine.FindLast();
        SalesShipmentLine.TestField(Quantity, -1 * SalesLine."Qty. to Ship");
    end;

    local procedure VerifyUndoReceiptLineOnPostedReturnReceipt(SalesLine: Record "Sales Line")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetRange("Return Order No.", SalesLine."Document No.");
        ReturnReceiptLine.SetRange(Type, SalesLine.Type);
        ReturnReceiptLine.SetRange("No.", SalesLine."No.");
        ReturnReceiptLine.FindLast();
        ReturnReceiptLine.TestField(Quantity, -1 * SalesLine."Return Qty. to Receive");
    end;

    local procedure VerifyDimSetIDOnItemLedgEntry(ExpectedDimSetID: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgEntry.FindLast();
        ValueEntry.SetFilter("Item Charge No.", '<>%1', '');
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.FindFirst();
        Assert.AreEqual(
          ExpectedDimSetID, ValueEntry."Dimension Set ID", StrSubstNo(IncorrectDimSetIDErr, ItemLedgEntry.TableCaption()));
    end;

    local procedure VerifyQuantitytoShipOnSalesLine(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.TestField("Qty. to Ship", 0);
    end;

    local procedure VerifyQuantityOnSalesInvoiceLine(OrderNo: Code[20]; SellToCustomerNo: Code[20]; Quantity: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesHeaderDimensions(SalesHeader: Record "Sales Header"; DimCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimCode);
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(
          DimensionSetEntry."Dimension Set ID", SalesHeader."Dimension Set ID",
          StrSubstNo(WrongDimValueErr, SalesHeader."No."));
    end;

    local procedure VerifySalesLineFindRecordByDescription(SalesLine: Record "Sales Line"; TypedValue: Text[50]; ExpectedNo: Code[20]; ExpectedDescription: Text)
    begin
        SalesLine.Validate("No.", '');
        SalesLine.Validate(Description, TypedValue);
        Assert.AreEqual(ExpectedNo, SalesLine."No.", SalesLine.FieldCaption("No."));
        Assert.AreEqual(ExpectedDescription, SalesLine.Description, SalesLine.FieldCaption(Description));
    end;

    local procedure VerifySalesLineFindRecordByNo(SalesLine: Record "Sales Line"; TypedValue: Text[20]; ExpectedNo: Code[20]; ExpectedDescription: Text)
    begin
        SalesLine.Validate("No.", TypedValue);
        Assert.AreEqual(ExpectedNo, SalesLine."No.", SalesLine.FieldCaption("No."));
        Assert.AreEqual(ExpectedDescription, SalesLine.Description, SalesLine.FieldCaption(Description));
    end;

    [Scope('OnPrem')]
    local procedure VerifySmallBusinessOwnerActPage(ExpectedCount: Integer)
    var
        SBOwnerCue: Record "SB Owner Cue";
        SmallBusinessOwnerAct: TestPage "Small Business Owner Act.";
        SalesOrderList: TestPage "Sales Order List";
        Counter: Integer;
    begin
        SmallBusinessOwnerAct.OpenView();
        SmallBusinessOwnerAct.SOShippedNotInvoiced.AssertEquals(ExpectedCount);

        SalesOrderList.Trap();
        SBOwnerCue.ShowSalesOrdersShippedNotInvoiced();
        while SalesOrderList.Next() do
            Counter += 1;
        if Counter > 0 then
            Counter += 1;
        SalesOrderList.Close();
        SmallBusinessOwnerAct.Close();

        Assert.AreEqual(ExpectedCount, Counter, 'Unexpected number of listed orders');
    end;

    local procedure CreateOrderCheckVATSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibraryInventory.CreateItem(Item);
        if not VATPostingSetup.Get(SalesHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group") then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure SetupMyNotificationsForPostingSetup()
    var
        MyNotifications: Record "My Notifications";
        PostingSetupManagement: Codeunit PostingSetupManagement;
    begin
        MyNotifications.InsertDefaultWithTableNum(
          PostingSetupManagement.GetPostingSetupNotificationID(),
          LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(),
          DATABASE::"G/L Account");
        MyNotifications.Enabled := true;
        MyNotifications.Modify();
    end;

    local procedure UpdateDimensionOnSalesHeader(var SalesHeader: Record "Sales Header") DimensionSetID: Integer
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Update Dimension value on Sales Header Dimension.
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, SalesHeader."Dimension Set ID");
        DimensionSetID :=
          LibraryDimension.EditDimSet(
            DimensionSetEntry."Dimension Set ID", DimensionSetEntry."Dimension Code",
            FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        SalesHeader.Validate("Dimension Set ID", DimensionSetID);
        SalesHeader.Modify(true);
    end;

    local procedure FindDifferentDimensionValue(DimensionCode: Code[20]; "Code": Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetFilter(Code, '<>%1', Code);
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        exit(DimensionValue.Code);
    end;

    local procedure CreateCustomerWithAddressAndDefaultDim(var Customer: Record Customer)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // Create Customer with Address
        LibrarySales.CreateCustomerWithAddress(Customer);

        // Add default dimension on Customer
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateAlternateShippingAddressForCustomer(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    var
        Location: Record Location;
    begin
        // Create Location
        LibraryWarehouse.CreateLocation(Location);

        // Create Ship-to Address
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate("Location Code", Location.Code);
        ShipToAddress.Modify(true);
    end;

    local procedure FindWhseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceType, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(ActivityType, WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure PostWhsDocument(var WarehouseActivityLine: Record "Warehouse Activity Line"; PostInvoice: Boolean; PrintDoc: Boolean; SuppressCommit: Boolean; HideDialog: Boolean; IsPreview: Boolean)
    var
        WhseActivityPost: Codeunit "Whse.-Activity-Post";
    begin
        WhseActivityPost.SetInvoiceSourceDoc(PostInvoice);
        WhseActivityPost.PrintDocument(PrintDoc);
        WhseActivityPost.SetSuppressCommit(SuppressCommit);
        WhseActivityPost.ShowHideDialog(HideDialog);
        WhseActivityPost.SetIsPreview(IsPreview);
        WhseActivityPost.Run(WarehouseActivityLine);
    end;

    local procedure UpdateItemInventoryNoLocation(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: Page Navigate)
    begin
        Navigate.SetDoc(PostingDate2, DocumentNo2);
        Navigate.UpdateNavigateForm(false);
        Navigate.FindRecordsOnOpen();

        TempDocumentEntry2.DeleteAll();
        Navigate.ReturnDocumentEntry(TempDocumentEntry2);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNoToChangingEmail(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := Question <> ConfirmEmptyEmailQst;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithVerification(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerMessage(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(ConfirmMsg, Question);
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopySalesDocumentHandler(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    var
        DocType: Option;
        DocumentType: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        DocType := DocumentType;
        CopySalesDocument.DocumentType.SetValue(DocType);
        CopySalesDocument.DocumentNo.SetValue(No);  // Invokes SalesListArchiveHandler.
        CopySalesDocument.IncludeHeader_Options.SetValue(true);
        CopySalesDocument.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    procedure SalesOrderStatisticsModalHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        AdjustedCostLCY: Decimal;
    begin
        Evaluate(AdjustedCostLCY, SalesOrderStatistics."TotalAdjCostLCY[1]".Value);
        LibraryVariableStorage.Enqueue(AdjustedCostLCY);
    end;
#endif
    [PageHandler]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        AdjustedCostLCY: Decimal;
    begin
        Evaluate(AdjustedCostLCY, SalesOrderStatistics."TotalAdjCostLCY[1]".Value);
        LibraryVariableStorage.Enqueue(AdjustedCostLCY);
    end;

    local procedure CreatePostSalesOrder(): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Qty: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        Qty := LibraryRandom.RandInt(10);
        CreateSalesLineWithItem(SalesHeader, Qty, Qty);
        CreateSalesLineWithItem(SalesHeader, Qty, 0);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesLineWithItem(SalesHeader: Record "Sales Header"; Qty: Integer; QtyToShip: Integer)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item,
          LibraryRandom.RandDec(1000, 2),
          LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure CreateCopySalesOrder(var SalesHeader: Record "Sales Header"; FromSalesOrderNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue("Sales Document Type From"::Order);
        LibraryVariableStorage.Enqueue(FromSalesOrderNo);
        CopySalesDocument(SalesHeader);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeader."No.");
    end;

    local procedure CopySalesDocument(SalesHeader: Record "Sales Header")
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        Commit();
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.RunModal();
    end;

    local procedure SetFirstSalesLineNotToShip(var SalesHeaderOrder: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeaderOrder."Document Type");
        SalesLine.SetRange("Document No.", SalesHeaderOrder."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeaderInvoice: Record "Sales Header"; var SalesHeaderOrder: Record "Sales Header"; var ItemCharge: Record "Item Charge")
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesLineInvoice: Record "Sales Line";
        ItemChargeSalesLine: Record "Sales Line";
        SalesLine: Record "Sales Line";
        SalesLineType: Enum "Sales Line Type";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");
        SalesLineInvoice.Validate("Document Type", SalesHeaderInvoice."Document Type");
        SalesLineInvoice.Validate("Document No.", SalesHeaderInvoice."No.");
        LibrarySales.GetShipmentLines(SalesLineInvoice);
        LibrarySales.GetShipmentLines(SalesLineInvoice);

        FindSalesLines(SalesLine, SalesHeaderInvoice, SalesLineType::Item);
        FindSalesLines(ItemChargeSalesLine, SalesHeaderInvoice, SalesLineType::"Charge (Item)");
        LibrarySales.CreateItemChargeAssignment(
            ItemChargeAssignmentSales, ItemChargeSalesLine, ItemCharge,
            SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderInvoice."No.", SalesLine."Line No.",
            SalesLine."No.", ItemChargeSalesLine.Quantity, LibraryRandom.RandIntInRange(10, 20));
        ItemChargeAssignmentSales.Insert(true);
    end;

    local procedure FindSalesLines(var SalesLines: Record "Sales Line"; var SalesHeader: Record "Sales Header"; SalesLineType: Enum "Sales Line Type")
    begin
        SalesLines.SetRange("Document Type", SalesHeader."Document Type");
        SalesLines.SetRange("Document No.", SalesHeader."No.");
        SalesLines.SetRange(Type, SalesLineType);
        SalesLines.FindFirst();
    end;

    local procedure CreateSalesOrderWithItemCharge(var SalesHeader: Record "Sales Header"; ItemChargeNo: Code[20]; var Items: array[2] of Record Item)
    var
        SalesLineItemCharge: Record "Sales Line";
        SalesLineItem: Record "Sales Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLineItem, SalesHeader, SalesLineItem.Type::Item, Items[1]."No.", 1);
        LibrarySales.CreateSalesLine(
          SalesLineItem, SalesHeader, SalesLineItem.Type::Item, Items[2]."No.", 1);
        LibrarySales.CreateSalesLine(
          SalesLineItemCharge, SalesHeader, SalesLineItemCharge.Type::"Charge (Item)", ItemChargeNo, 1);
        SalesLineItemCharge.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLineItemCharge.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenSalesOrderStatistics(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.Statistics.Invoke();
    end;
#endif
    local procedure OpenSalesOrderStatisticsNM(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesOrderStatistics.Invoke();
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Items: array[2] of Record Item)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Items[1]."No.", 10);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Items[2]."No.", 7);
    end;

    local procedure CreateItemsWithUnitPriceAndUnitCost(var Items: array[2] of Record Item)
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Items[1], LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Items[2], LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
    end;

    local procedure UpdateQtyToShipAndInvoiceOnSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            UpdateQtyToShipAndInvoiceOnSalesLine(SalesLine, 3, 3);
        until SalesLine.Next() = 0;
    end;

    local procedure CreateSalesOrderWithServiceCharge(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Amount: Decimal;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure FindSalesServiceChargeLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.FindFirst();
    end;

    local procedure CreateCustomerWithServiceChargeAmount(var CustomerNo: Code[20]; var ServiceChargeAmt: Decimal)
    var
        CustomerInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        CustomerNo := CreateCustomerInvDiscount();
        ServiceChargeAmt := LibraryRandom.RandDecInDecimalRange(10, 20, 2);
        CustomerInvoiceDisc.SetRange(Code, CustomerNo);
        CustomerInvoiceDisc.FindFirst();
        CustomerInvoiceDisc.Validate("Service Charge", ServiceChargeAmt);
        CustomerInvoiceDisc.Modify(true);
    end;

    local procedure CreateAndPostSalesOrder(
        var SalesHeader: Record "Sales Header";
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        var UnitPrice: Decimal;
        var DocNo: Code[20])
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);

        UnitPrice := LibraryRandom.RandDec(10, 2);

        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            Customer."No.");

        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(0));

        SalesLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure VerifySalesOrderAfterPostCorrectiveCreditMemo(SalesHeaderNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindSet();
        repeat
            Assert.Equal(SalesLine.Quantity, SalesLine."Outstanding Qty. (Base)");
            Assert.Equal(SalesLine."Qty. Invoiced (Base)", 0);
            Assert.Equal(SalesLine."Qty. to Invoice", SalesLine.Quantity);
            Assert.Equal(SalesLine."Qty. to Ship", SalesLine.Quantity);
            Assert.Equal(SalesLine."Qty. Shipped (Base)", 0);
        until SalesLine.Next() = 0;
    end;

    local procedure FindSalesServiceChargeLineExist(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"): Boolean
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        if not SalesLine.IsEmpty then
            exit(true);
    end;

    local procedure VerifySalesOrderAfterPartialPostCorrectiveCreditMemo(SalesHeaderNo: Code[20]; ExpectedQuantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindSet();
        repeat
            Assert.AreEqual(ExpectedQuantity, SalesLine."Qty. to Ship", StrSubstNo(
                SalesLineQtyErr, SalesLine.FieldName("Qty. to Ship"), ExpectedQuantity));
            Assert.AreEqual(ExpectedQuantity, SalesLine."Qty. to Invoice", StrSubstNo(
                SalesLineQtyErr, SalesLine.FieldName("Qty. to Invoice"), ExpectedQuantity));
        until SalesLine.Next() = 0;
    end;

    local procedure GetPostedDocumentLines(No: Code[20]; OptionString: Option)
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        LibraryVariableStorage.Enqueue(OptionString);
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", No);
        SalesCreditMemo.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Type: Enum "Sales Line Type")
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, Type);
        SalesLine.FindFirst();
    end;

    local procedure VerifySalesOrderQuantityforManualSalesCreditMemo(SalesHeaderNo: Code[20]; ExpectedQuantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindSet();
        repeat
            Assert.AreEqual(ExpectedQuantity, SalesLine."Qty. to Ship", StrSubstNo(
                SalesLineQtyErr, SalesLine.FieldName("Qty. to Ship"), ExpectedQuantity));
            Assert.AreEqual(ExpectedQuantity, SalesLine."Qty. to Invoice", StrSubstNo(
                SalesLineQtyErr, SalesLine.FieldName("Qty. to Invoice"), ExpectedQuantity));
        until SalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostUpdateOrderLineModifyTempLine', '', false, false)]
    local procedure OnBeforePostUpdateOrderLineModifyTempLineHandler(var TempSalesLine: Record "Sales Line" temporary; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(TempSalesLine.RecordId);
        SalesLine."Description 2" := 'x';
        SalesLine.Modify();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order Subform", 'OnBeforeSetDefaultType', '', false, false)]
    local procedure OnBeforeSetDefaultSalesOrderLineType(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean);
    begin
        SalesLine.Type := SalesLine.Type::"Fixed Asset";
        IsHandled := SalesLine."Document No." = 'SETDEFAULTTYPEEVENT';  // to prevent undesired handling for other tests
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsModalPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesStatistics.SubForm."VAT Amount".SetValue(
          SalesStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal());
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, LibraryVariableStorage.DequeueText());
        SalesStatistics.GotoRecord(SalesHeader); // Refresh
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesStatistics.SubForm."VAT Amount".SetValue(SalesStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal());
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, LibraryVariableStorage.DequeueText());
        SalesStatistics.GotoRecord(SalesHeader); // Refresh
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExactMessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QtyToAssgnItemChargeModalPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        if LibraryVariableStorage.DequeueBoolean() then
            ItemChargeAssignmentSales."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal())
        else
            LibraryVariableStorage.Enqueue(ItemChargeAssignmentSales."Qty. to Assign".Value);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsUpdateInvDiscontAndTotalVATHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.InvDiscountAmount_Invoicing.SetValue(LibraryVariableStorage.DequeueDecimal());
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        SalesOrderStatistics.OK().Invoke();
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsUpdateTotalVATHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        SalesOrderStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsUpdateInvDiscontAndTotalVATHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.InvDiscountAmount_Invoicing.SetValue(LibraryVariableStorage.DequeueDecimal());
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        SalesOrderStatistics.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsNMUpdateTotalVATHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        SalesOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesHandler(var VATAmountLine: TestPage "VAT Amount Lines")
    var
        VATAmount: Decimal;
    begin
        // Modal Page Handler.
        VATAmount := VATAmountLine."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal();
        LibraryVariableStorage.Enqueue(VATAmount);
        VATAmountLine."VAT Amount".SetValue(VATAmount);
        VATAmountLine.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GetShipmentLinesModalPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ShipToAddressListModalPageHandlerOK(var ShipToAddressList: TestPage "Ship-to Address List")
    var
        ShipToCode: Code[10];
    begin
        ShipToCode := LibraryVariableStorage.DequeueText();
        ShipToAddressList.Filter.SetFilter(Code, ShipToCode);
        ShipToAddressList.OK().Invoke();
    end;

    [PageHandler]
    procedure SalesCreditMemoPageHandler(var SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        LibraryVariableStorage.Enqueue(SalesCreditMemo."No.".Value());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickReportHandler(var CreatePickReqPage: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreatePickReqPage.CInvtPick.SetValue(true);
        CreatePickReqPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DummyMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionEntriesOKModalPageHandler(var ItemSubstitution: TestPage "Item Substitution Entries")
    begin
        ItemSubstitution.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PostedSalesDocumentLinesHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocumentType: Option "Posted Shipments","Posted Invoices","Posted Return Receipts","Posted Cr. Memos";
    begin
        case LibraryVariableStorage.DequeueInteger() of
            OptionString::PostedReturnReceipt:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Return Receipts"));
            OptionString::PostedInvoices:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Invoices"));
            OptionString::PostedShipments:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Shipments"));
            OptionString::PostedCrMemo:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Cr. Memos"));
        end;
        PostedSalesDocumentLines.OK().Invoke();
    end;
}