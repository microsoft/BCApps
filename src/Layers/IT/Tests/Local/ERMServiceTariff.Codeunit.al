codeunit 144156 "ERM Service Tariff"
{
    // 1.  Purpose of the test is to verify error when Service Tariff No. is blank on Sales Order with Service Tariff No. Mandatory checked.
    // 2.  Purpose of the test is to verify error when Transport Method is blank on Sales Order with Service Tariff No. Mandatory checked.
    // 3.  Purpose of the test is to verify error when Payment Method is blank on Sales Order with Service Tariff No. Mandatory checked.
    // 4.  Purpose of the test is to verify that Sales Order posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
    // 5.  Purpose of the test is to verify that Sales Order posts successfully when Service Tariff No. Mandatory is unchecked.
    // 6.  Purpose of the test is to verify error while posting prepmt invoice when Service Tariff No.is blank on Sales Order with Service Tariff No. Mandatory checked.
    // 7.  Purpose of the test is to verify error while posting prepmt invoice when Transport Method is blank on Sales Order with Service Tariff No. Mandatory checked.
    // 8.  Purpose of the test is to verify error while posting prepmt invoice when Payment Method is blank on Sales Order with Service Tariff No. Mandatory checked.
    // 9.  Purpose of the test is to verify that Sales Prepmt Invoice posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
    // 10. Purpose of the test is to verify that Sales Prepmt Invoice posts successfully when Service Tariff No. Mandatory is unchecked.
    // 11. Purpose of the test is to verify error when Service Tariff No. is blank on Purchase Order with Service Tariff No. Mandatory checked.
    // 12. Purpose of the test is to verify error when Transport Method is blank on Purchase Order with Service Tariff No. Mandatory checked.
    // 13. Purpose of the test is to verify error when Payment Method is blank on Purchase Order with Service Tariff No. Mandatory checked.
    // 14. Purpose of the test is to verify that Purchase Order posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
    // 15. Purpose of the test is to verify that Purchase Order posts successfully when Service Tariff No. Mandatory is unchecked.
    // 16. Purpose of the test is to verify error while posting Prepmt Invoice when Service Tariff No is blank on Purchase Order with Service Tariff No. Mandatory checked.
    // 17. Purpose of the test is to verify error while posting Prepmt Invoice when Transport Method is blank on Purchase Order with Service Tariff No. Mandatory checked.
    // 18. Purpose of the test is to verify error while posting Prepmt Invoice when Payment Method is blank on Purchase Order with Service Tariff No. Mandatory checked.
    // 19. Purpose of the test is to verify that Purch Prepmt Invoice posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
    // 20. Purpose of the test is to verify that Purch Prepmt Invoice posts successfully when Service Tariff No. Mandatory is unchecked.
    // 21. Purpose of the test is to verify error when Service Tariff No. is blank on Service Invoice with Service Tariff No. Mandatory checked.
    // 22. Purpose of the test is to verify error when Transport Method is blank on Service Invoice with Service Tariff No. Mandatory checked.
    // 23. Purpose of the test is to verify error when Payment Method is blank on Service Invoice with Service Tariff No. Mandatory checked.
    // 24. Purpose of the test is to verify that Service Invoice posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
    // 25. Purpose of the test is to verify that Service Invoice posts successfully when Service Tariff No. Mandatory is unchecked.
    // 
    // Covers Test Cases for WI - 345522.
    // -------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // -------------------------------------------------------------------------------------------------------------
    // SalesOrderBlankServiceTariffNoError,SalesOrderBlankTransportMethodError
    // SalesOrderBlankPaymentMethodCodeError,PostSalesOrderWithServiceTariffNoMandatoryTrue                 251994
    // PostSalesOrderWithServiceTariffNoMandatoryFalse                                                      251985
    // SalesPrepmtBlankServiceTariffNoError,SalesPrepmtBlankTransportMethodError
    // SalesPrepmtBlankPaymentMethodCodeError,PostSalesPrepmtWithServiceTariffNoMandatoryTrue               251996
    // PostSalesPrepmtWithServiceTariffNoMandatoryFalse                                                     251995
    // PurchaseOrderBlankServiceTariffNoError,PurchaseOrderBlankTransportMethodError
    // PurchaseOrderBlankPaymentMethodCodeError,PostPurchaseOrderWithServiceTariffNoMandatoryTrue           251998
    // PostPurchaseOrderWithServiceTariffNoMandatoryFalse                                                   251997
    // PurchasePrepmtBlankServiceTariffNoError,PurchasePrepmtBlankTransportMethodError
    // PurchasePrepmtBlankPaymentMethodCodeError,PostPurchasePrepmtWithServiceTariffNoMandatoryTrue         252000
    // PostPurchasePrepmtWithServiceTariffNoMandatoryFalse                                                  252001
    // ServiceInvoiceBlankServiceTariffNoError,ServiceInvoiceBlankTransportMethodError
    // ServiceInvoiceBlankPaymentMethodCodeError,PostServiceInvoiceWithServiceTariffNoMandatoryTrue         252002
    // PostServiceInvoiceWithServiceTariffNoMandatoryFalse                                                  252001

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        BlankServiceTariffNoErr: Label 'Service Tariff No. must have a value in %1';
        BlankTransportMethodErr: Label 'Transport Method must have a value in %1';
        BlankPaymentMethodCodeErr: Label 'Payment Method Code must have a value in %1';

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBlankServiceTariffNoError()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to verify error while posting when Service Tariff No. is blank on Sales Order with Service Tariff No. Mandatory checked.
        SalesOrderWithServiceTariffNoMandatory(StrSubstNo(BlankServiceTariffNoErr, SalesLine.TableCaption()), '', '');  // Using blank for Service Tariff No. and Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBlankTransportMethodError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to verify error while posting when Transport Method is blank on Sales Order with Service Tariff No. Mandatory checked.
        SalesOrderWithServiceTariffNoMandatory(
          StrSubstNo(BlankTransportMethodErr, SalesHeader.TableCaption()), CreateServiceTariffNumber(), '');  // Using blank for Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBlankPaymentMethodCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to verify error while posting when Payment Method is blank on Sales Order with Service Tariff No. Mandatory checked.
        SalesOrderWithServiceTariffNoMandatory(
          StrSubstNo(BlankPaymentMethodCodeErr, SalesHeader.TableCaption()), CreateServiceTariffNumber(), CreateTransportMethod());
    end;

    local procedure SalesOrderWithServiceTariffNoMandatory(ExpectedError: Text; ServiceTariffNumber: Code[10]; TransportMethod: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        CreateSalesOrder(SalesHeader, ServiceTariffNumber, TransportMethod, '', true, 0);  // Using blank for Payment Method Code,TRUE for EU Service and 0 for Prepayment%.

        // Exercise.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithServiceTariffNoMandatoryTrue()
    begin
        // Purpose of the test is to verify that Sales Order posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
        CreateAndPostSalesOrder(CreateServiceTariffNumber(), CreateTransportMethod(), CreatePaymentMethod(), true);  // Using TRUE for EU Service.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithServiceTariffNoMandatoryFalse()
    begin
        // Purpose of the test is to verify that Sales Order posts successfully when Service Tariff No. Mandatory is unchecked.
        CreateAndPostSalesOrder('', '', '', false);  // Using blank for Service Tariff Number,Transport Method,Payment Method and FALSE for EU Service.
    end;

    local procedure CreateAndPostSalesOrder(ServiceTariffNo: Code[10]; TransportMethod: Code[10]; PaymentMethod: Code[10]; EUService: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
    begin
        // Setup.
        CreateSalesOrder(SalesHeader, ServiceTariffNo, TransportMethod, PaymentMethod, EUService, 0);  // Using 0 for Prepayment%.

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Service Tariff No.", ServiceTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtBlankServiceTariffNoError()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to verify error while posting prepmt invoice when Service Tariff No. is blank on Sales Order with Service Tariff No. Mandatory checked.
        SalesPrepmtWithServiceTariffNoMandatory(StrSubstNo(BlankServiceTariffNoErr, SalesLine.TableCaption()), '', '');  // Using blank for Service Tariff No.,Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtBlankTransportMethodError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to verify error while posting prepmt invoice when Transport Method is blank on Sales Order with Service Tariff No. Mandatory checked.
        SalesPrepmtWithServiceTariffNoMandatory(
          StrSubstNo(BlankTransportMethodErr, SalesHeader.TableCaption()), CreateServiceTariffNumber(), '');  // Using blank for Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtBlankPaymentMethodCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to verify error while posting prepmt invoice when Payment Method is blank on Sales Order with Service Tariff No. Mandatory checked.
        SalesPrepmtWithServiceTariffNoMandatory(
          StrSubstNo(BlankPaymentMethodCodeErr, SalesHeader.TableCaption()), CreateServiceTariffNumber(), CreateTransportMethod());
    end;

    local procedure SalesPrepmtWithServiceTariffNoMandatory(ExpectedError: Text; ServiceTariffNumber: Code[10]; TransportMethod: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        CreateSalesOrder(SalesHeader, ServiceTariffNumber, TransportMethod, '', true, LibraryRandom.RandDecInRange(10, 100, 2));  // Using blank for Payment Method Code,TRUE for EUService and random for Prepayment%.

        // Exercise.
        asserterror LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepmtWithServiceTariffNoMandatoryTrue()
    begin
        // Purpose of the test is to verify that Sales Prepmt Invoice posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
        CreateAndPostSalesPrepmtInvoice(CreateServiceTariffNumber(), CreateTransportMethod(), CreatePaymentMethod(), true);  // Using TRUE for EU Service.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepmtWithServiceTariffNoMandatoryFalse()
    begin
        // Purpose of the test is to verify that Sales Prepmt Invoice posts successfully when Service Tariff No. Mandatory is unchecked.
        CreateAndPostSalesPrepmtInvoice('', '', '', false);  // Using blank for Service Tariff Number,Transport Method,Payment Method and FALSE for EU Service.
    end;

    local procedure CreateAndPostSalesPrepmtInvoice(ServiceTariffNo: Code[10]; TransportMethod: Code[10]; PaymentMethod: Code[10]; EUService: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup.
        CreateSalesOrder(
          SalesHeader, ServiceTariffNo, TransportMethod, PaymentMethod, EUService, LibraryRandom.RandDecInRange(10, 100, 2));  // Using random for Prepayment%.

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify.
        SalesInvoiceHeader.SetRange("Prepayment Order No.", SalesHeader."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Transport Method", TransportMethod);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderBlankServiceTariffNoError()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to verify error while posting when Service Tariff No. is blank on Purchase Order with Service Tariff No. Mandatory checked.
        PurchaseOrderWithServiceTariffNoMandatory(StrSubstNo(BlankServiceTariffNoErr, PurchaseLine.TableCaption()), '', '');  // Using blank for Service Tariff No. and Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderBlankTransportMethodError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to verify error while posting when Transport Method is blank on Purchase Order with Service Tariff No. Mandatory checked.
        PurchaseOrderWithServiceTariffNoMandatory(
          StrSubstNo(BlankTransportMethodErr, PurchaseHeader.TableCaption()), CreateServiceTariffNumber(), '');  // Using blank for Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderBlankPaymentMethodCodeError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to verify error while posting when Payment Method is blank on Purchase Order with Service Tariff No. Mandatory checked.
        PurchaseOrderWithServiceTariffNoMandatory(
          StrSubstNo(BlankPaymentMethodCodeErr, PurchaseHeader.TableCaption()), CreateServiceTariffNumber(), CreateTransportMethod());
    end;

    local procedure PurchaseOrderWithServiceTariffNoMandatory(ExpectedError: Text; ServiceTariffNumber: Code[10]; TransportMethod: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        CreatePurchaseOrder(PurchaseHeader, ServiceTariffNumber, TransportMethod, '', true, 0);  // Using blank for Payment Method Code,TRUE for EU Service and 0 for Prepayment%.

        // Exercise.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true); // Post as Receive and Invoice.

        // Verify.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithServiceTariffNoMandatoryTrue()
    begin
        // Purpose of the test is to verify that Purchase Order posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
        CreateAndPostPurchaseOrder(CreateServiceTariffNumber(), CreateTransportMethod(), CreatePaymentMethod(), true);  // Using TRUE for EU Service.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithServiceTariffNoMandatoryFalse()
    begin
        // Purpose of the test is to verify that Purchase Order posts successfully when Service Tariff No. Mandatory is unchecked.
        CreateAndPostPurchaseOrder('', '', '', false);  // Using blank for Service Tariff Number,Transport Method,Payment Method and FALSE for EU Service.
    end;

    local procedure CreateAndPostPurchaseOrder(ServiceTariffNo: Code[10]; TransportMethod: Code[10]; PaymentMethod: Code[10]; EUService: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        DocumentNo: Code[20];
    begin
        // Setup.
        CreatePurchaseOrder(PurchaseHeader, ServiceTariffNo, TransportMethod, PaymentMethod, EUService, 0);  // Using 0 for Prepayment%.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Service Tariff No.", ServiceTariffNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtBlankServiceTariffNoError()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to verify error while posting Prepmt Invoice when Service Tariff No is blank on Purchase Order with Service Tariff No. Mandatory checked.
        PurchasePrepmtWithServiceTariffNoMandatory(StrSubstNo(BlankServiceTariffNoErr, PurchaseLine.TableCaption()), '', '');  // Using blank for Service Tariff No. and Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtBlankTransportMethodError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to verify error while posting Prepmt Invoice when Transport Method is blank on Purchase Order with Service Tariff No. Mandatory checked.
        PurchasePrepmtWithServiceTariffNoMandatory(
          StrSubstNo(BlankTransportMethodErr, PurchaseHeader.TableCaption()), CreateServiceTariffNumber(), '');  // Using blank for Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtBlankPaymentMethodCodeError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to verify error while posting Prepmt Invoice when Payment Method is blank on Purchase Order with Service Tariff No. Mandatory checked.
        PurchasePrepmtWithServiceTariffNoMandatory(
          StrSubstNo(BlankPaymentMethodCodeErr, PurchaseHeader.TableCaption()), CreateServiceTariffNumber(), CreateTransportMethod());
    end;

    local procedure PurchasePrepmtWithServiceTariffNoMandatory(ExpectedError: Text; ServiceTariffNumber: Code[10]; TransportMethod: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        CreatePurchaseOrder(PurchaseHeader, ServiceTariffNumber, TransportMethod, '', true, LibraryRandom.RandDecInRange(10, 100, 2));  // Using blank for Payment Method Code, TRUE for EU Service and random for Prepayment%.

        // Exercise.
        asserterror LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Verify.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchasePrepmtWithServiceTariffNoMandatoryTrue()
    begin
        // Purpose of the test is to verify that Purch Prepmt Invoice posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
        CreateAndPostPurchasePrepmtInvoice(CreateServiceTariffNumber(), CreateTransportMethod(), CreatePaymentMethod(), true);  // Using TRUE for EU Service.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchasePrepmtWithServiceTariffNoMandatoryFalse()
    begin
        // Purpose of the test is to verify that Purch Prepmt Invoice posts successfully when Service Tariff No. Mandatory is unchecked.
        CreateAndPostPurchasePrepmtInvoice('', '', '', false);  // Using blank for Service Tariff Number,Transport Method, Payment Method and FALSE for EU Service.
    end;

    local procedure CreateAndPostPurchasePrepmtInvoice(ServiceTariffNo: Code[10]; TransportMethod: Code[10]; PaymentMethod: Code[10]; EUService: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Setup.
        CreatePurchaseOrder(
          PurchaseHeader,
          ServiceTariffNo, TransportMethod, PaymentMethod, EUService, LibraryRandom.RandDecInRange(10, 100, 2));  // Using random for Prepayment%.

        // Exercise.
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);

        // Verify.
        PurchInvHeader.SetRange("Prepayment Order No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Transport Method", TransportMethod);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceBlankServiceTariffNoError()
    var
        ServiceLine: Record "Service Line";
    begin
        // Purpose of the test is to verify error when Service Tariff No is blank on Service Invoice with Service Tariff No. Mandatory checked.
        ServiceInvoiceWithServiceTariffNoMandatory(StrSubstNo(BlankServiceTariffNoErr, ServiceLine.TableCaption()), '', '');  // Using blank for Service Tariff No. and Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceBlankTransportMethodError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to verify error when Transport Method is blank on Service Invoice with Service Tariff No. Mandatory checked.
        ServiceInvoiceWithServiceTariffNoMandatory(
          StrSubstNo(BlankTransportMethodErr, ServiceHeader.TableCaption()), CreateServiceTariffNumber(), '');  // Using blank for Transport Method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceBlankPaymentMethodCodeError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to verify error when Payment Method is blank on Service Invoice with Service Tariff No. Mandatory checked.
        ServiceInvoiceWithServiceTariffNoMandatory(
          StrSubstNo(BlankPaymentMethodCodeErr, ServiceHeader.TableCaption()), CreateServiceTariffNumber(), CreateTransportMethod());
    end;

    local procedure ServiceInvoiceWithServiceTariffNoMandatory(ExpectedError: Text; ServiceTariffNumber: Code[10]; TransportMethod: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup.
        CreateServiceInvoice(ServiceHeader, ServiceTariffNumber, TransportMethod, '', true);  // Using blank for Payment Method Code and TRUE for EU Service.

        // Exercise.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as Ship and Invoice.

        // Verify.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceWithServiceTariffNoMandatoryTrue()
    begin
        // Purpose of the test is to verify that Service Invoice posts successfully with all mandatory fields when Service Tariff No. Mandatory is checked.
        CreateAndPostServiceInvoice(CreateServiceTariffNumber(), CreateTransportMethod(), CreatePaymentMethod(), true);  // Using TRUE for EU Service.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceInvoiceWithServiceTariffNoMandatoryFalse()
    begin
        // Purpose of the test is to verify that Service Invoice posts successfully when Service Tariff No. Mandatory is unchecked.
        CreateAndPostServiceInvoice('', '', '', false);  // Using blank for Service Tariff Number,Transport Method,Payment Method and FALSE for EU Service.
    end;

    local procedure CreateAndPostServiceInvoice(ServiceTariffNo: Code[10]; TransportMethod: Code[10]; PaymentMethod: Code[10]; EUService: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        // Setup.
        CreateServiceInvoice(ServiceHeader, ServiceTariffNo, TransportMethod, PaymentMethod, EUService);

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as Ship and Invoice.

        // Verify.
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField("Service Tariff No.", ServiceTariffNo);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ServiceTariffNo: Code[10]; TransportMethod: Code[10]; PaymentMethodCode: Code[10]; EUService: Boolean; PrepaymentPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        UpdateVATPostingSetup(VATPostingSetup, EUService);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Transport Method", TransportMethod);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethodCode);
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Validate("Prepayment Due Date", WorkDate());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine,
          PurchaseHeader,
          PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Using random for Direct Unit Cost.
        PurchaseLine.Validate("Service Tariff No.", ServiceTariffNo);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ServiceTariffNo: Code[10]; TransportMethod: Code[10]; PaymentMethodCode: Code[10]; EUService: Boolean; PrepaymentPct: Decimal)
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        UpdateVATPostingSetup(VATPostingSetup, EUService);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Transport Method", TransportMethod);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine,
          SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using random for Unit Price.
        SalesLine.Validate("Service Tariff No.", ServiceTariffNo);
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceInvoice(var ServiceHeader: Record "Service Header"; ServiceTariffNo: Code[10]; TransportMethod: Code[10]; PaymentMethodCode: Code[10]; EUService: Boolean)
    var
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        UpdateVATPostingSetup(VATPostingSetup, EUService);
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        ServiceHeader.Validate("Transport Method", TransportMethod);
        ServiceHeader.Validate("Payment Method Code", PaymentMethodCode);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using random for Unit Price.
        ServiceLine.Validate("Service Tariff No.", ServiceTariffNo);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceTariffNumber(): Code[10]
    var
        ServiceTariffNumber: Record "Service Tariff Number";
    begin
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        exit(ServiceTariffNumber."No.");
    end;

    local procedure CreateTransportMethod(): Code[10]
    var
        TransportMethod: Record "Transport Method";
    begin
        LibraryITLocalization.CreateTransportMethod(TransportMethod);
        exit(TransportMethod.Code);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Validate("Sales Prepayments Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. Prepayments Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;
}

