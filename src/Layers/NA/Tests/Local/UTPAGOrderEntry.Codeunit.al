codeunit 142073 "UT PAG Order Entry"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateNoServiceItemWorkSheetSubform()
    var
        ServiceLine: Record "Service Line";
        ServiceItemWorksheet: TestPage "Service Item Worksheet";
    begin
        // Purpose of the test is to validate On Validate No. trigger of Page 5907 - Service Item Worksheet Subform.

        // Setup: Create Service Item WorkSheet.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order);
        Commit();  // Table 5902 (Service Line) No. On Validate trigger calls commit.

        // Exercise.
        OpenServiceItemWorksheetToEnterNo(ServiceItemWorksheet, ServiceLine."Document No.", ServiceLine."No.");

        // Verify: No. entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField("No.", ServiceLine."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateQuantityServiceItemWorkSheetSubform()
    var
        ServiceLine: Record "Service Line";
        ServiceItemWorksheet: TestPage "Service Item Worksheet";
    begin
        // Purpose of the test is to validate On Validate Quantity trigger of Page 5907 - Service Item Worksheet Subform.

        // Setup: Create Service Item WorkSheet.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order);

        // Exercise.
        OpenServiceItemWorksheetToEnterQuantity(ServiceItemWorksheet, ServiceLine."Document No.");

        // Verify: Quantity entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateLocationCodeServiceItemWorkSheetSubform()
    var
        ServiceLine: Record "Service Line";
        ServiceItemWorksheet: TestPage "Service Item Worksheet";
    begin
        // Purpose of the test is to validate On Validate Location Code trigger of Page 5907 - Service Item Worksheet Subform.

        // Setup: Create Service Item WorkSheet.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order);

        // Exercise.
        OpenServiceItemWorksheetToEnterLocation(ServiceItemWorksheet, ServiceLine."Document No.");

        // Verify: Location code entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField("Location Code", ServiceLine."Location Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateQuantityServiceInvoiceSubform()
    var
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Purpose of the test is to validate On Validate Quantity trigger of Page 5934 - Service Invoice Subform.

        // Setup: Create Service Invoice.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice);

        // Exercise.
        OpenServiceInvoiceToEnterQuantity(ServiceInvoice, ServiceLine."Document No.");

        // Verify: Quantity entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateUnitOfMeasureCodeServiceInvoiceSubform()
    var
        ServiceLine: Record "Service Line";
        UnitofMeasure: Record "Unit of Measure";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Purpose of the test is to validate On Validate Unit Of Measure Code trigger of Page 5934 - Service Invoice Subform.

        // Setup: Create Service Invoice.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice);

        // Exercise.
        OpenServiceInvoiceToEnterUnitOfMeasure(ServiceInvoice, ServiceLine."Document No.", UnitofMeasure.Code);

        // Verify: Unit of Measure Code on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField("Unit of Measure Code", ServiceLine."Unit of Measure Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateQuantityServiceCreditMemoSubform()
    var
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Purpose of the test is to validate On Validate Quantity trigger of Page 5936 - Service Credit Memo Subform.

        // Setup: Create Service Credit Memo.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo");

        // Exercise.
        OpenServiceCreditMemoToEnterQuantity(ServiceCreditMemo, ServiceLine."Document No.");

        // Verify: Quantity entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateUnitOfMeasureCodeServiceCreditMemoSubform()
    var
        ServiceLine: Record "Service Line";
        UnitofMeasure: Record "Unit of Measure";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Purpose of the test is to validate On Validate Unit Of Measure Code trigger of Page 5936 - Service Credit Memo Subform.

        // Setup: Create Service Credit Memo.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo");

        // Exercise.
        OpenServiceCreditMemoToEnterUnitOfMeasure(ServiceCreditMemo, ServiceLine."Document No.", UnitofMeasure.Code);

        // Verify: Unit of Measure Code on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField("Unit of Measure Code", ServiceLine."Unit of Measure Code");
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteLinesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateQuantityServiceQuoteLines()
    var
        ServiceLine: Record "Service Line";
        ServiceQuote: TestPage "Service Quote";
        ServiceQuoteLines: TestPage "Service Quote Lines";
    begin
        // Purpose of the test is to validate On Validate Quantity trigger of Page 5966 - Service Quote Lines.

        // Setup: Create Service Quote.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Quote);

        // Exercise.
        OpenServiceQuoteLinesToEnterQuantity(ServiceQuote, ServiceQuoteLines, ServiceLine."Document No.");

        // Verify: Quantity entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesRequestPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateQuantityServiceLines()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        ServiceLines: TestPage "Service Lines";
    begin
        // Purpose of the test is to validate On Validate Quantity trigger of Page 5905 - Service Lines.

        // Setup: Create Service Order.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order);
        Commit();  // Table 5902 (Service Line) AutoReserve function calls commit.

        // Exercise.
        OpenServiceLinesToEnterQuantity(ServiceOrder, ServiceLines, ServiceLine."Document No.", ServiceLine."Service Item Line No.");

        // Verify: Quantity entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateNoServiceLines()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        ServiceLines: TestPage "Service Lines";
    begin
        // Purpose of the test is to validate On Validate No. trigger of Page 5905 - Service Lines.

        // Setup: Create Service Order.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order);
        Commit();  // Table 5902 (Service Line) AutoReserve function calls commit.

        // Exercise.
        OpenServiceLinesToEnterNo(ServiceOrder, ServiceLines, ServiceLine."Document No.", ServiceLine."No.", ServiceLine."Service Item Line No.");

        // Verify: No. entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField("No.", ServiceLine."No.");
    end;

    [Test]
    [HandlerFunctions('ServiceLinesRequestPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateLocationCodeServiceLines()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        ServiceLines: TestPage "Service Lines";
    begin
        // Purpose of the test is to validate On Validate Location Code trigger of Page 5905 - Service Lines.

        // Setup: Create Service Order.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order);
        Commit();  // Table 5902 (Service Line) AutoReserve function calls commit.

        // Exercise.
        OpenServiceLinesToEnterLocationCode(ServiceOrder, ServiceLines, ServiceLine."Document No.", ServiceLine."Service Item Line No.");

        // Verify: Location Code entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField("Location Code", ServiceLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('ServiceLinesEnterPostingDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidatePostingDateServiceLines()
    var
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // Purpose of the test is to validate On Validate Posting Date trigger of Page 5905 - Service Lines.

        // Setup: Create Service Order.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order);
        Commit();  // Table 5902 (Service Line) AutoReserve function calls commit.

        // Exercise.
        OpenServiceLinesToEnterPostingDate(ServiceOrder, ServiceLine."Document No.");

        // Verify: Posting Date entered on Service Line.
        ServiceLine.Find();
        ServiceLine.TestField("Posting Date", ServiceLine."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OnPostActionSalesOrderShipment()
    var
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Purpose of the test is to validate Post trigger of Page 10026 - Sales Order Shipment.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        Commit();  // Codeunit 80 OnRun trigger calls Commit();

        // Exercise.
        PostSalesOrderShipmentAndInvoiceUsingPage(SalesLine."Document No.");

        // Verify: Sell-to Customer No. in Shipment Header and Shipment Invoice.
        SalesShipmentHeader.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentHeader.FindFirst();
        SalesShipmentHeader.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");

        SalesInvoiceHeader.SetRange("Order No.", SalesLine."Document No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPostAndPrintActionSalesOrderShipment()
    var
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // Purpose of the test is to validate Post & Print trigger of Page 10026 - Sales Order Shipment.

        // Setup: Create Sales Order.
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        Commit();  // Codeunit 80 OnRun trigger calls Commit();

        // Exercise.
        OpenPageSalesOrderShipmentPostAndPrint(SalesLine."Document No.");

        // Verify: Sell-to Customer No. in Shipment Header.
        SalesShipmentHeader.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentHeader.FindFirst();
        SalesShipmentHeader.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPostAndPrintSalesOrderInvoice()
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Purpose of the test is to validate Post & Print trigger of Page 10028 - Sales Order Invoice.

        // Setup: Create Sales Order.
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        Commit();

        // Exercise.
        OpenPageSalesOrderInvoicePostAndPrint(SalesLine."Document No.");

        // Verify: Sell-to Customer No. in Sales Invoice Header.
        SalesInvoiceHeader.SetRange("Order No.", SalesLine."Document No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateQuantitySalesOrderSubform()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // Purpose of the test is to validate Quantity in On Validate Trigger of Quantity Page 46 - Sales Order Subform.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);

        // Exercise.
        UpdateQuantityOnSalesOrder(SalesOrder, SalesLine."Document No.");

        // Verify: Verify Quantity on Reservation Page.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateUnitOfMeasureCodeSalesOrderSubform()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        UnitOfMeasureCode: Code[10];
    begin
        // Purpose of the test is to validate Unit Of Measure Code in On Validate Trigger of Page 46 - Sales Order Subform.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        UnitOfMeasureCode := CreateUnitOfMeasure(SalesLine."No.");

        // Exercise.
        UpdateUnitOfMeasureOnSalesOrder(SalesOrder, SalesLine."Document No.", UnitOfMeasureCode);

        // Verify: Verify Unit of Measure Code on Sales Line.
        SalesLine.Find();
        SalesLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateQuantitySalesInvoiceSubform()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        Quantity: Decimal;
    begin
        // Purpose of the test is to validate Quantity in On Validate Trigger of Quantity Page 47 - Sales Invoice Subform.

        // Setup: Create Sales Invoice.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice);
        Quantity := LibraryRandom.RandDec(10, 2);

        // Exercise.
        UpdateSalesInvoice(SalesInvoice, SalesLine."Document No.", '', Quantity);

        // Verify: Verify Quantity on Sales Line.
        SalesLine.Find();
        SalesLine.TestField(Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateUnitOfMeasureCodeSalesInvoiceSubform()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        UnitOfMeasureCode: Code[10];
    begin
        // Purpose of the test is to validate Unit Of Measure Code in On Validate Trigger of Page 47 - Sales Invoice Subform.

        // Setup: Create Sales Invoice.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice);
        UnitOfMeasureCode := CreateUnitOfMeasure(SalesLine."No.");

        // Exercise.
        UpdateSalesInvoice(SalesInvoice, SalesLine."Document No.", UnitOfMeasureCode, 0);  // Using 0 for Quantity.

        // Verify: Verify Unit of Measure Code on Sales Line.
        SalesLine.Find();
        SalesLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateQuantitySalesQuoteSubform()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        Quantity: Decimal;
    begin
        // Purpose of the test is to validate Quantity in On Validate Trigger of Quantity Page 95 - Sales Quote Subform.

        // Setup: Create Sales Quote.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote);
        Quantity := LibraryRandom.RandDec(10, 2);

        // Exercise.
        UpdateSalesQuote(SalesQuote, SalesLine."Document No.", '', Quantity);

        // Verify: Verify Quantity on Sales Line.
        SalesLine.Find();
        SalesLine.TestField(Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateUnitOfMeasureCodeSalesQuoteSubform()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        UnitOfMeasureCode: Code[10];
    begin
        // Purpose of the test is to validate Unit Of Measure Code in On Validate Trigger of Page 95 - Sales Quote Subform.

        // Setup: Create Sales Quote.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote);
        UnitOfMeasureCode := CreateUnitOfMeasure(SalesLine."No.");

        // Exercise.
        UpdateSalesQuote(SalesQuote, SalesLine."Document No.", UnitOfMeasureCode, 0);  // Using 0 for Quantity.

        // Verify: Verify Unit of Measure Code in Sales Line.
        SalesLine.Find();
        SalesLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateQuantitySalesCreditMemoSubform()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        Quantity: Decimal;
    begin
        // Purpose of the test is to validate Quantity in On Validate Trigger of Quantity Page 96 - Sales Credit Memo Subform.

        // Setup: Create Sales Credit Memo.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo");
        Quantity := LibraryRandom.RandDec(10, 2);

        // Exercise.
        UpdateSalesCreditMemo(SalesCreditMemo, SalesLine."Document No.", '', Quantity);

        // Verify: Verify Quantity on Sales Line.
        SalesLine.Find();
        SalesLine.TestField(Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateUnitOfMeasureCodeSalesCreditMemoSubform()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        UnitOfMeasureCode: Code[10];
    begin
        // Purpose of the test is to validate Unit Of Measure Code in On Validate Trigger of Page 96 - Sales Credit Memo Subform.

        // Setup: Create Sales Credit Memo.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo");
        UnitOfMeasureCode := CreateUnitOfMeasure(SalesLine."No.");

        // Exercise.
        UpdateSalesCreditMemo(SalesCreditMemo, SalesLine."Document No.", UnitOfMeasureCode, 0);  // Using 0 for Quantity

        // Verify: Verify Unit of Measure Code on Sales Line.
        SalesLine.Find();
        SalesLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateQuantityBlanketSalesOrderSubform()
    var
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        Quantity: Decimal;
    begin
        // Purpose of the test is to validate Quantity in On Validate Trigger of Quantity Page 508 - Blanket Sales Order Subform.

        // Setup: Create Blanket Sales Order.                                                            .
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order");
        Quantity := LibraryRandom.RandDec(10, 2);

        // Exercise.
        UpdateBlanketSalesOrder(BlanketSalesOrder, SalesLine."Document No.", '', Quantity);

        // Verify: Verify Quantity on Sales Line.
        SalesLine.Find();
        SalesLine.TestField(Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateUnitOfMeasureCodeBlanketSalesOrderSubform()
    var
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        UnitOfMeasureCode: Code[10];
    begin
        // Purpose of the test is to validate Unit Of Measure Code in On Validate Trigger of Page 508 - Blanket Sales Order Subform.

        // Setup: Create Blanket Sales Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order");
        UnitOfMeasureCode := CreateUnitOfMeasure(SalesLine."No.");

        // Exercise.
        UpdateBlanketSalesOrder(BlanketSalesOrder, SalesLine."Document No.", UnitOfMeasureCode, 0);  // Using 0 for Quantity.

        // Verify: Verify Unit of Measure Code in Sales Line.
        SalesLine.Find();
        SalesLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateQuantitySalesReturnOrderSubform()
    var
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        Quantity: Decimal;
    begin
        // Purpose of the test is to validate Quantity in On Validate Trigger of Quantity Page 6631 - Sales Return Order Subform.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order");
        Quantity := LibraryRandom.RandDec(10, 2);

        // Exercise.
        UpdateSalesReturnOrder(SalesReturnOrder, SalesLine."Document No.", '', Quantity);

        // Verify: Verify Quantity on Sales Line.
        SalesLine.Find();
        SalesLine.TestField(Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateUnitOfMeasureCodeSalesReturnOrderSubform()
    var
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        UnitOfMeasureCode: Code[10];
    begin
        // Purpose of the test is to validate Unit Of Measure Code in On Validate Trigger of Page 6631 - Sales Return Order Subform.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order");
        UnitOfMeasureCode := CreateUnitOfMeasure(SalesLine."No.");

        // Exercise.
        UpdateSalesReturnOrder(SalesReturnOrder, SalesLine."Document No.", UnitOfMeasureCode, 0);  // Using 0 for Quantity.

        // Verify: Verify Unit of Measure Code in Sales Line.
        SalesLine.Find();
        SalesLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        CreateBlankVATPostingSetup();
        UpdateStockOutWarningOnSalesReceivableSetup();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibrarySales.SetDiscountPostingSilent(0);

        IsInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateBlankVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.DeleteAll();
        if not VATPostingSetup.Get('', '') then
            VATPostingSetup."VAT Bus. Posting Group" := '';
        VATPostingSetup."VAT Prod. Posting Group" := '';
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Sales Tax";
        VATPostingSetup.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvoiceListAvailableInBasic()
    var
        SalesOrderInvoiceList: TestPage "Sales Order Invoice List";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Invoice List and its elements in Basic Setup
        Initialize();

        // [GIVEN] Basic Setup was enabled
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Sales Order Invoice List can be opened and its elements are available
        SalesOrderInvoiceList.OpenView();

        Assert.IsTrue(SalesOrderInvoiceList."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceList."Sell-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."Sell-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceList."Sell-to Customer Name".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."Sell-to Customer Name".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceList."External Document No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."External Document No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceList."Location Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."Location Code".Visible(), '');

        SalesOrderInvoiceList.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvoiceListAvailableInFoundation()
    var
        SalesOrderInvoiceList: TestPage "Sales Order Invoice List";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Invoice List and its elements in Foundation Setup
        Initialize();

        // [GIVEN] Foundation Setup was enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Sales Order Invoice List can be opened and its elements are available
        SalesOrderInvoiceList.OpenView();

        Assert.IsTrue(SalesOrderInvoiceList."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceList."Sell-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."Sell-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceList."Sell-to Customer Name".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."Sell-to Customer Name".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceList."External Document No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."External Document No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceList."Location Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceList."Location Code".Visible(), '');

        SalesOrderInvoiceList.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvoiceAvailableInBasic()
    var
        SalesOrderInvoice: TestPage "Sales Order Invoice";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Invoice and its elements in Basic Setup
        Initialize();

        // [GIVEN] Basic Setup was enabled
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Sales Order Invoice can be opened and its elements are available
        SalesOrderInvoice.OpenView();

        Assert.IsTrue(SalesOrderInvoice."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Sell-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Sell-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Sell-to Customer Name".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Sell-to Customer Name".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Posting Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Posting Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Order Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Order Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Document Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Document Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Salesperson Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Salesperson Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Currency Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Currency Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Status.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Status.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Name".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Name".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Address".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Address".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Address 2".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Address 2".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to City".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to City".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to County".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to County".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Post Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Post Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Contact".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Contact".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Shortcut Dimension 1 Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Shortcut Dimension 1 Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Shortcut Dimension 2 Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Shortcut Dimension 2 Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Payment Terms Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Payment Terms Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Due Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Due Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Payment Discount %".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Payment Discount %".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Pmt. Discount Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Pmt. Discount Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Payment Method Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Payment Method Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Tax Liable".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Tax Liable".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Tax Area Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Tax Area Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Statistics.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Statistics.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Card.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Card.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Co&mments".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Co&mments".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Invoices.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Invoices.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Dimensions.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Dimensions.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Calculate &Invoice Discount".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Calculate &Invoice Discount".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Re&open".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Re&open".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."P&ost".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."P&ost".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Post and &Print".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Post and &Print".Visible(), '');

        SalesOrderInvoice.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvoiceAvailableInFoundation()
    var
        SalesOrderInvoice: TestPage "Sales Order Invoice";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Invoice and its elements in Foundation Setup
        Initialize();

        // [GIVEN] Basic Setup was enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Sales Order Invoice can be opened and its elements are available
        SalesOrderInvoice.OpenView();

        Assert.IsTrue(SalesOrderInvoice."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Sell-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Sell-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Sell-to Customer Name".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Sell-to Customer Name".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Posting Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Posting Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Order Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Order Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Document Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Document Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Salesperson Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Salesperson Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Currency Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Currency Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Status.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Status.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Name".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Name".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Address".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Address".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Address 2".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Address 2".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to City".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to City".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to County".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to County".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Post Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Post Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Bill-to Contact".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Bill-to Contact".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Shortcut Dimension 1 Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Shortcut Dimension 1 Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Shortcut Dimension 2 Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Shortcut Dimension 2 Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Payment Terms Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Payment Terms Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Due Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Due Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Payment Discount %".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Payment Discount %".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Pmt. Discount Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Pmt. Discount Date".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Payment Method Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Payment Method Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Tax Liable".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Tax Liable".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Tax Area Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Tax Area Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Statistics.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Statistics.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Card.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Card.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Co&mments".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Co&mments".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Invoices.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Invoices.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice.Dimensions.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice.Dimensions.Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Calculate &Invoice Discount".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Calculate &Invoice Discount".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Re&open".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Re&open".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."P&ost".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."P&ost".Visible(), '');

        Assert.IsTrue(SalesOrderInvoice."Post and &Print".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoice."Post and &Print".Visible(), '');

        SalesOrderInvoice.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvoiceSubformAvailableInBasic()
    var
        SalesOrderInvoiceSubform: TestPage "Sales Order Invoice Subform";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Invoice List and its elements in Basic Setup
        Initialize();

        // [GIVEN] Basic Setup was enabled
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Sales Order Invoice List can be opened and its elements are available
        SalesOrderInvoiceSubform.OpenView();

        Assert.IsTrue(SalesOrderInvoiceSubform.Type.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform.Type.Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform.Description.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform.Description.Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Unit of Measure Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Unit of Measure Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Unit Price".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Unit Price".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Tax Group Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Tax Group Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Line Amount".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Line Amount".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Amount Including VAT".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Amount Including VAT".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Line Discount %".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Line Discount %".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity Shipped".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity Shipped".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Qty. to Invoice".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Qty. to Invoice".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity Invoiced".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity Invoiced".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Shipment Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Shipment Date".Visible(), '');

        SalesOrderInvoiceSubform.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvoiceSubformAvailableInFoundation()
    var
        SalesOrderInvoiceSubform: TestPage "Sales Order Invoice Subform";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Invoice List and its elements in Foundation Setup
        Initialize();

        // [GIVEN] Foundation Setup was enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Sales Order Invoice List can be opened and its elements are available
        SalesOrderInvoiceSubform.OpenView();

        Assert.IsTrue(SalesOrderInvoiceSubform.Type.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform.Type.Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."No.".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform.Description.Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform.Description.Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Unit of Measure Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Unit of Measure Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Unit Price".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Unit Price".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Tax Group Code".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Tax Group Code".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Line Amount".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Line Amount".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Amount Including VAT".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Amount Including VAT".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Line Discount %".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Line Discount %".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity Shipped".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity Shipped".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Qty. to Invoice".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Qty. to Invoice".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity Invoiced".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Quantity Invoiced".Visible(), '');

        Assert.IsTrue(SalesOrderInvoiceSubform."Shipment Date".Enabled(), '');
        Assert.IsTrue(SalesOrderInvoiceSubform."Shipment Date".Visible(), '');

        SalesOrderInvoiceSubform.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShipmentListAvailableInBasic()
    var
        SalesOrderShipmentList: TestPage "Sales Order Shipment List";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Shipment List and its elements in Basic Setup
        Initialize();

        // [GIVEN] Basic Setup was enabled
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Sales Order Shipment List can be opened and its elements are available
        SalesOrderShipmentList.OpenView();

        Assert.IsTrue(SalesOrderShipmentList."Location Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentList."Location Code".Visible(), '');

        SalesOrderShipmentList.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShipmentListAvailableInFoundation()
    var
        SalesOrderShipmentList: TestPage "Sales Order Shipment List";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Shipment List and its elements in Foundation Setup
        Initialize();

        // [GIVEN] Foundation Setup was enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Sales Order Shipment List can be opened and its elements are available
        SalesOrderShipmentList.OpenView();

        Assert.IsTrue(SalesOrderShipmentList."Location Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentList."Location Code".Visible(), '');

        SalesOrderShipmentList.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShipmentAvailableInBasic()
    var
        SalesOrderShipment: TestPage "Sales Order Shipment";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Invoice and its elements in Basic Setup
        Initialize();

        // [GIVEN] Basic Setup was enabled
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Sales Order Invoice can be opened and its elements are available
        SalesOrderShipment.OpenView();

        Assert.IsTrue(SalesOrderShipment."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Sell-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Sell-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Sell-to Customer Name".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Sell-to Customer Name".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Bill-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Bill-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Bill-to Name".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Bill-to Name".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Tax Liable".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Tax Liable".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Posting Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Posting Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Order Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Order Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Document Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Document Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Requested Delivery Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Requested Delivery Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Promised Delivery Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Promised Delivery Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Salesperson Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Salesperson Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shortcut Dimension 1 Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shortcut Dimension 1 Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shortcut Dimension 2 Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shortcut Dimension 2 Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment.Status.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Status.Visible(), '');

        Assert.IsTrue(SalesOrderShipment."On Hold".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."On Hold".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Name".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Name".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Address".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Address".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Address 2".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Address 2".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to City".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to City".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to County".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to County".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Post Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Post Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Contact".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Contact".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to UPS Zone".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to UPS Zone".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Tax Area Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Tax Area Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment.FreightAmount.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.FreightAmount.Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Location Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Location Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Outbound Whse. Handling Time".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Outbound Whse. Handling Time".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipment Method Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipment Method Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipping Agent Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipping Agent Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipping Agent Service Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipping Agent Service Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipping Time".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipping Time".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Late Order Shipping".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Late Order Shipping".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Package Tracking No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Package Tracking No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipment Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipment Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipping Advice".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipping Advice".Visible(), '');

#if not CLEAN27
        Assert.IsTrue(SalesOrderShipment.Statistics.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Statistics.Visible(), '');
#else
        Assert.IsTrue(SalesOrderShipment.SalesOrderStatistics.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.SalesOrderStatistics.Visible(), '');
#endif
        Assert.IsTrue(SalesOrderShipment.Card.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Card.Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Co&mments".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Co&mments".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."S&hipments".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."S&hipments".Visible(), '');

        Assert.IsTrue(SalesOrderShipment.Invoices.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Invoices.Visible(), '');

        Assert.IsTrue(SalesOrderShipment.Dimensions.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Dimensions.Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Order &Promising".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Order &Promising".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Sales Shipment per Package".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Sales Shipment per Package".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Re&open".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Re&open".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Test Report".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Test Report".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."P&ost".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."P&ost".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Post and &Print".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Post and &Print".Visible(), '');

        SalesOrderShipment.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShipmentAvailableInFoundation()
    var
        SalesOrderShipment: TestPage "Sales Order Shipment";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Invoice and its elements in Foundation Setup
        Initialize();

        // [GIVEN] Foundation Setup was enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Sales Order Invoice can be opened and its elements are available
        SalesOrderShipment.OpenView();

        Assert.IsTrue(SalesOrderShipment."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Sell-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Sell-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Sell-to Customer Name".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Sell-to Customer Name".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Bill-to Customer No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Bill-to Customer No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Bill-to Name".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Bill-to Name".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Tax Liable".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Tax Liable".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Posting Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Posting Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Order Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Order Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Document Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Document Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Requested Delivery Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Requested Delivery Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Promised Delivery Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Promised Delivery Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Salesperson Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Salesperson Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shortcut Dimension 1 Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shortcut Dimension 1 Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shortcut Dimension 2 Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shortcut Dimension 2 Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment.Status.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Status.Visible(), '');

        Assert.IsTrue(SalesOrderShipment."On Hold".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."On Hold".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Name".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Name".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Address".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Address".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Address 2".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Address 2".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to City".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to City".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to County".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to County".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Post Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Post Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to Contact".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to Contact".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Ship-to UPS Zone".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Ship-to UPS Zone".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Tax Area Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Tax Area Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment.FreightAmount.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.FreightAmount.Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Location Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Location Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Outbound Whse. Handling Time".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Outbound Whse. Handling Time".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipment Method Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipment Method Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipping Agent Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipping Agent Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipping Agent Service Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipping Agent Service Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipping Time".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipping Time".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Late Order Shipping".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Late Order Shipping".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Package Tracking No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Package Tracking No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipment Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipment Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Shipping Advice".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Shipping Advice".Visible(), '');
#if not CLEAN27
        Assert.IsTrue(SalesOrderShipment.Statistics.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Statistics.Visible(), '');
#else
        Assert.IsTrue(SalesOrderShipment.SalesOrderStatistics.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.SalesOrderStatistics.Visible(), '');
#endif
        Assert.IsTrue(SalesOrderShipment.Card.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Card.Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Co&mments".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Co&mments".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."S&hipments".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."S&hipments".Visible(), '');

        Assert.IsTrue(SalesOrderShipment.Invoices.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Invoices.Visible(), '');

        Assert.IsTrue(SalesOrderShipment.Dimensions.Enabled(), '');
        Assert.IsTrue(SalesOrderShipment.Dimensions.Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Order &Promising".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Order &Promising".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Sales Shipment per Package".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Sales Shipment per Package".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Re&open".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Re&open".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Test Report".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Test Report".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."P&ost".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."P&ost".Visible(), '');

        Assert.IsTrue(SalesOrderShipment."Post and &Print".Enabled(), '');
        Assert.IsTrue(SalesOrderShipment."Post and &Print".Visible(), '');

        SalesOrderShipment.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShipmentSubformAvailableInBasic()
    var
        SalesOrderShipmentSubform: TestPage "Sales Order Shipment Subform";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Shipment Subform and its elements in Basic Setup
        Initialize();

        // [GIVEN] Basic Setup was enabled
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Sales Order Shipment Subform can be opened and its elements are available
        SalesOrderShipmentSubform.OpenView();

        Assert.IsTrue(SalesOrderShipmentSubform.Type.Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform.Type.Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform.Description.Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform.Description.Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Location Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Location Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Quantity".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Quantity".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Reserved Quantity".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Reserved Quantity".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Unit of Measure Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Unit of Measure Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Qty. to Ship".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Qty. to Ship".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Quantity Shipped".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Quantity Shipped".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Planned Delivery Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Planned Delivery Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Planned Shipment Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Planned Shipment Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Shipment Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Shipment Date".Visible(), '');

        SalesOrderShipmentSubform.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShipmentSubformAvailableInFoundation()
    var
        SalesOrderShipmentSubform: TestPage "Sales Order Shipment Subform";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO 360794] User can access Sales Order Shipment Subform and its elements in Foundation Setup
        Initialize();

        // [GIVEN] Foundation Setup was enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Sales Order Shipment Subform can be opened and its elements are available
        SalesOrderShipmentSubform.OpenView();

        Assert.IsTrue(SalesOrderShipmentSubform.Type.Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform.Type.Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."No.".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."No.".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform.Description.Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform.Description.Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Location Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Location Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Quantity".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Quantity".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Reserved Quantity".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Reserved Quantity".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Unit of Measure Code".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Unit of Measure Code".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Qty. to Ship".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Qty. to Ship".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Quantity Shipped".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Quantity Shipped".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Planned Delivery Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Planned Delivery Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Planned Shipment Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Planned Shipment Date".Visible(), '');

        Assert.IsTrue(SalesOrderShipmentSubform."Shipment Date".Enabled(), '');
        Assert.IsTrue(SalesOrderShipmentSubform."Shipment Date".Visible(), '');

        SalesOrderShipmentSubform.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.FindFirst();
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Customer Posting Group" := CustomerPostingGroup.Code;  // Use Hardcode Value due to Posting routine Call.
        Customer.Insert();
        exit(Customer."No.")
    end;

    local procedure CreateItem(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        FindGeneralPostingSetup(GeneralPostingSetup);
        InventoryPostingGroup.FindFirst();
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Base Unit of Measure" := CreateUnitOfMeasure(Item."No.");
        Item."Inventory Posting Group" := InventoryPostingGroup.Code;  // Use Hardcode Value due to Posting routine Call.
        Item."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";  // Use Hardcode Value due to Posting routine Call.
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location.Insert();
        exit(Location.Code)
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        FindGeneralPostingSetup(GeneralPostingSetup);
        Item.Get(CreateItem());

        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := CreateCustomer();
        SalesHeader."Bill-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader."Document Date" := WorkDate();
        SalesHeader."Due Date" := WorkDate();
        SalesHeader."Shipping No. Series" := SalesReceivablesSetup."Posted Shipment Nos.";
        SalesHeader."Posting No. Series" := SalesReceivablesSetup."Posted Invoice Nos.";
        SalesHeader.Insert();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesLine."Sell-to Customer No.";
        SalesLine.Description := LibraryUTUtility.GetNewCode();
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."Line No." := LibraryRandom.RandInt(100);
        SalesLine."Shipment Date" := WorkDate();
        SalesLine."No." := Item."No.";
        SalesLine."Unit of Measure Code" := Item."Base Unit of Measure";
        SalesLine.Reserve := SalesLine.Reserve::Always;
        SalesLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesLine."Unit Price" := LibraryRandom.RandDec(100, 2);
        SalesLine."Qty. to Ship" := SalesLine.Quantity;
        SalesLine."Qty. to Invoice" := SalesLine.Quantity;
        SalesLine."Qty. to Ship (Base)" := SalesLine.Quantity;
        SalesLine."Qty. to Assign" := SalesLine.Quantity;
        SalesLine."Outstanding Quantity" := SalesLine.Quantity;
        SalesLine."Quantity (Base)" := SalesLine.Quantity;
        SalesLine."Qty. to Invoice (Base)" := SalesLine.Quantity;
        SalesLine."Gen. Bus. Posting Group" := GeneralPostingSetup."Gen. Bus. Posting Group";  // Use Hardcode Value due to Posting routine Call.
        SalesLine."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";   // Use Hardcode Value due to Posting routine Call.
        SalesLine."VAT Calculation Type" := SalesLine."VAT Calculation Type"::"Sales Tax";
        SalesLine.Insert();
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type")
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader."Customer No." := CreateCustomer();
        ServiceHeader.Insert();

        ServiceItemLine."Document Type" := ServiceHeader."Document Type";
        ServiceItemLine."Document No." := ServiceHeader."No.";
        ServiceItemLine."Line No." := LibraryRandom.RandInt(100);
        ServiceItemLine."Item No." := CreateItem();
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        ServiceItemLine."Service Item No." := ServiceItem."No.";
        ServiceItemLine.Insert();

        ServiceLine."Document Type" := ServiceItemLine."Document Type";
        ServiceLine."Document No." := ServiceItemLine."Document No.";
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine."Line No." := ServiceItemLine."Line No.";
        ServiceLine."Service Item Line No." := ServiceItemLine."Line No.";
        ServiceLine."No." := ServiceItemLine."Item No.";
        ServiceLine."Service Item No." := ServiceItemLine."Service Item No.";
        ServiceLine."Posting Date" := WorkDate();
        ServiceLine."Outstanding Qty. (Base)" := LibraryRandom.RandDec(10, 2);
        ServiceLine.Reserve := ServiceLine.Reserve::Always;
        ServiceLine.Insert();
    end;

    local procedure CreateUnitOfMeasure(ItemNo: Code[20]): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        UnitOfMeasure.Code := LibraryUTUtility.GetNewCode10();
        UnitOfMeasure.Insert();
        ItemUnitOfMeasure."Item No." := ItemNo;
        ItemUnitOfMeasure.Code := UnitOfMeasure.Code;
        ItemUnitOfMeasure."Qty. per Unit of Measure" := LibraryRandom.RandDec(10, 2);
        ItemUnitOfMeasure.Insert();
        exit(UnitOfMeasure.Code);
    end;

    local procedure FindGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GeneralPostingSetup.FindFirst();
        GeneralPostingSetup."COGS Account" := GLAccount."No.";
        GeneralPostingSetup.Modify();
    end;

    local procedure PostSalesOrderShipmentAndInvoiceUsingPage(No: Code[20])
    var
        SalesOrderShipment: TestPage "Sales Order Shipment";
        SalesOrderInvoice: TestPage "Sales Order Invoice";
    begin
        SalesOrderShipment.OpenEdit();
        SalesOrderShipment.FILTER.SetFilter("No.", No);
        SalesOrderShipment."P&ost".Invoke();
        SalesOrderShipment.Close();
        SalesOrderInvoice.OpenEdit();
        SalesOrderInvoice.FILTER.SetFilter("No.", No);
        SalesOrderInvoice."P&ost".Invoke();
    end;

    local procedure OpenPageSalesOrderShipmentPostAndPrint(No: Code[20])
    var
        SalesOrderShipment: TestPage "Sales Order Shipment";
    begin
        SalesOrderShipment.OpenEdit();
        SalesOrderShipment.FILTER.SetFilter("No.", No);
        SalesOrderShipment."Post and &Print".Invoke();
        SalesOrderShipment.Close();
    end;

    local procedure OpenPageSalesOrderInvoicePostAndPrint(No: Code[20])
    var
        SalesOrderShipment: TestPage "Sales Order Shipment";
        SalesOrderInvoice: TestPage "Sales Order Invoice";
    begin
        SalesOrderShipment.OpenEdit();
        SalesOrderShipment.FILTER.SetFilter("No.", No);
        SalesOrderShipment."P&ost".Invoke();
        SalesOrderShipment.Close();
        SalesOrderInvoice.OpenEdit();
        SalesOrderInvoice.FILTER.SetFilter("No.", No);
        SalesOrderInvoice."Post and &Print".Invoke();
    end;

    local procedure OpenServiceCreditMemoToEnterQuantity(var ServiceCreditMemo: TestPage "Service Credit Memo"; No: Code[20])
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", No);
        ServiceCreditMemo.ServLines.Quantity.SetValue(LibraryRandom.RandInt(10));
        ServiceCreditMemo.Close();
    end;

    local procedure OpenServiceCreditMemoToEnterUnitOfMeasure(var ServiceCreditMemo: TestPage "Service Credit Memo"; No: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", No);
        ServiceCreditMemo.ServLines."Unit of Measure Code".SetValue(UnitOfMeasureCode);
        ServiceCreditMemo.Close();
    end;

    local procedure OpenServiceInvoiceToEnterQuantity(var ServiceInvoice: TestPage "Service Invoice"; No: Code[20])
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", No);
        ServiceInvoice.ServLines.Quantity.SetValue(LibraryRandom.RandInt(10));
        ServiceInvoice.Close();
    end;

    local procedure OpenServiceInvoiceToEnterUnitOfMeasure(var ServiceInvoice: TestPage "Service Invoice"; No: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", No);
        ServiceInvoice.ServLines."Unit of Measure Code".SetValue(UnitOfMeasureCode);
        ServiceInvoice.Close();
    end;

    local procedure OpenServiceItemWorksheetToEnterLocation(var ServiceItemWorksheet: TestPage "Service Item Worksheet"; DocumentNo: Code[20])
    begin
        ServiceItemWorksheet.OpenEdit();
        ServiceItemWorksheet.FILTER.SetFilter("Document No.", DocumentNo);
        ServiceItemWorksheet.ServInvLines."Location Code".SetValue(CreateLocation());
        ServiceItemWorksheet.Close();
    end;

    local procedure OpenServiceItemWorksheetToEnterNo(var ServiceItemWorksheet: TestPage "Service Item Worksheet"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        ServiceItemWorksheet.OpenEdit();
        ServiceItemWorksheet.FILTER.SetFilter("Document No.", DocumentNo);
        ServiceItemWorksheet.ServInvLines."No.".SetValue(ItemNo);
        ServiceItemWorksheet.Close();
    end;

    local procedure OpenServiceItemWorksheetToEnterQuantity(var ServiceItemWorksheet: TestPage "Service Item Worksheet"; DocumentNo: Code[20])
    begin
        ServiceItemWorksheet.OpenEdit();
        ServiceItemWorksheet.FILTER.SetFilter("Document No.", DocumentNo);
        ServiceItemWorksheet.ServInvLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        ServiceItemWorksheet.Close();
    end;

    local procedure OpenServiceLinesToEnterLocationCode(var ServiceOrder: TestPage "Service Order"; var ServiceLines: TestPage "Service Lines"; No: Code[20]; LineNo: Integer)
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceLines.OpenEdit();
        ServiceLines.FILTER.SetFilter("Document No.", No);
        ServiceLines.FILTER.SetFilter("Service Item Line No.", Format(LineNo));
        ServiceLines."Location Code".SetValue(CreateLocation());
        ServiceOrder.Close();
    end;

    local procedure OpenServiceLinesToEnterNo(var ServiceOrder: TestPage "Service Order"; var ServiceLines: TestPage "Service Lines"; No: Code[20]; ItemNo: Code[20]; LineNo: Integer)
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceLines.OpenEdit();
        ServiceLines.FILTER.SetFilter("Document No.", No);
        ServiceLines.FILTER.SetFilter("Service Item Line No.", Format(LineNo));
        ServiceLines."No.".SetValue(ItemNo);
        ServiceLines.Close();
        ServiceOrder.Close();
    end;

    local procedure OpenServiceLinesToEnterPostingDate(var ServiceOrder: TestPage "Service Order"; No: Code[20])
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Close();
    end;

    local procedure OpenServiceLinesToEnterQuantity(var ServiceOrder: TestPage "Service Order"; var ServiceLines: TestPage "Service Lines"; No: Code[20]; LineNo: Integer)
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceLines.OpenEdit();
        ServiceLines.FILTER.SetFilter("Document No.", No);
        ServiceLines.FILTER.SetFilter("Service Item Line No.", Format(LineNo));
        ServiceLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        ServiceLines.Close();
        ServiceOrder.Close();
    end;

    local procedure OpenServiceQuoteLinesToEnterQuantity(var ServiceQuote: TestPage "Service Quote"; var ServiceQuoteLines: TestPage "Service Quote Lines"; No: Code[20])
    begin
        ServiceQuote.OpenEdit();
        ServiceQuote.FILTER.SetFilter("No.", No);
        ServiceQuote.ServItemLine.ServiceLines.Invoke();
        ServiceQuoteLines.OpenEdit();
        ServiceQuoteLines.FILTER.SetFilter("Document No.", No);
        ServiceQuoteLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        ServiceQuoteLines.Close();
        ServiceQuote.Close();
    end;

    local procedure UpdateBlanketSalesOrder(var BlanketSalesOrder: TestPage "Blanket Sales Order"; No: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", No);
        BlanketSalesOrder.SalesLines.Quantity.SetValue(Quantity);
        BlanketSalesOrder.SalesLines."Unit of Measure Code".SetValue(UnitOfMeasureCode);
        BlanketSalesOrder.OK().Invoke();
    end;

    local procedure UpdateQuantityOnSalesOrder(var SalesOrder: TestPage "Sales Order"; No: Code[20])
    var
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);

        // Enqueue values for use in ReservationPageHandler.
        LibraryVariableStorage.Enqueue(Format(SalesOrder.SalesLines."No."));
        LibraryVariableStorage.Enqueue(Quantity);
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);
        SalesOrder.OK().Invoke();
    end;

    local procedure UpdateSalesInvoice(var SalesInvoice: TestPage "Sales Invoice"; No: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", No);
        SalesInvoice.SalesLines.Quantity.SetValue(Quantity);
        SalesInvoice.SalesLines."Unit of Measure Code".SetValue(UnitOfMeasureCode);
        SalesInvoice.OK().Invoke();
    end;

    local procedure UpdateSalesQuote(var SalesQuote: TestPage "Sales Quote"; No: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    begin
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", No);
        SalesQuote.SalesLines.Quantity.SetValue(Quantity);
        SalesQuote.SalesLines."Unit of Measure Code".SetValue(UnitOfMeasureCode);
        SalesQuote.OK().Invoke();
    end;

    local procedure UpdateSalesCreditMemo(var SalesCreditMemo: TestPage "Sales Credit Memo"; No: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", No);
        SalesCreditMemo.SalesLines.Quantity.SetValue(Quantity);
        SalesCreditMemo.SalesLines."Unit of Measure Code".SetValue(UnitOfMeasureCode);
        SalesCreditMemo.OK().Invoke();
    end;

    local procedure UpdateSalesReturnOrder(var SalesReturnOrder: TestPage "Sales Return Order"; No: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.SalesLines.Quantity.SetValue(Quantity);
        SalesReturnOrder.SalesLines."Unit of Measure Code".SetValue(UnitOfMeasureCode);
        SalesReturnOrder.OK().Invoke();
    end;

    local procedure UpdateStockOutWarningOnSalesReceivableSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Stockout Warning" := false;
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateUnitOfMeasureOnSalesOrder(var SalesOrder: TestPage "Sales Order"; No: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines."Unit of Measure Code".SetValue(UnitOfMeasureCode);
        SalesOrder.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestPageHandler(var StandardSalesInvoice: Report "Standard Sales - Invoice")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: Report "Sales Shipment NA")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesRequestPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesEnterPostingDateRequestPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines."Posting Date".SetValue(WorkDate());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteLinesRequestPageHandler(var ServiceQuoteLines: TestPage "Service Quote Lines")
    begin
    end;
}
