
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Bank.DirectDebit;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.Test;

codeunit 13926 "E-Document DE Tests"
{
    Subtype = Test;
    TestType = Uncategorized;

    trigger OnRun();
    begin
        // [FEATURE] [E-Document DE]
    end;

    var
        CompanyInformation: Record "Company Information";
        EDocumentService: Record "E-Document Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryEDocDE: Codeunit "Library - E-Doc DE";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryEdocument: Codeunit "Library - E-Document";
        LibraryUtility: Codeunit "Library - Utility";
        ExportXRechnungFormat: Codeunit "XRechnung Format";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    #region BuyerReference

    [Test]
    procedure SalesHeaderBuyerReferenceFromCustomerWithRoutingNo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        RoutingNo: Text[50];
    begin
        // [SCENARIO] When creating a Sales Invoice for a customer with E-Invoice Routing No., the Buyer Reference is set from the customer.

        // [GIVEN] Customer with E-Invoice Routing No.
        RoutingNo := LibraryEDocDE.CreateValidRoutingNo();
        CreateCustomerWithRoutingNo(Customer, RoutingNo);

        // [WHEN] Create Sales Invoice for the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [THEN] Buyer Reference is set to the customer's E-Invoice Routing No.
        Assert.AreEqual(RoutingNo, SalesHeader."Buyer Reference", 'Buyer Reference should be set from Customer E-Invoice Routing No.');
    end;

    [Test]
    procedure SalesHeaderBuyerReferenceBlankWhenCustomerHasNoRoutingNo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] When creating a Sales Invoice for a customer without E-Invoice Routing No., the Buyer Reference is blank.

        // [GIVEN] Customer without E-Invoice Routing No.
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Create Sales Invoice for the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [THEN] Buyer Reference is blank
        Assert.AreEqual('', SalesHeader."Buyer Reference", 'Buyer Reference should be blank when customer has no E-Invoice Routing No.');
    end;

    [Test]
    procedure SalesHeaderBuyerReferenceUpdatesOnBillToChange()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
        RoutingNo1: Text[50];
        RoutingNo2: Text[50];
    begin
        // [SCENARIO] When changing the Bill-to Customer on a Sales Invoice, the Buyer Reference updates to the new customer's E-Invoice Routing No.

        // [GIVEN] Two customers with different E-Invoice Routing No. values
        RoutingNo1 := LibraryEDocDE.CreateValidRoutingNo();
        RoutingNo2 := LibraryEDocDE.CreateValidRoutingNo();
        CreateCustomerWithRoutingNo(Customer1, RoutingNo1);
        CreateCustomerWithRoutingNo(Customer2, RoutingNo2);

        // [GIVEN] Sales Invoice for Customer 1
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer1."No.");
        Assert.AreEqual(RoutingNo1, SalesHeader."Buyer Reference", 'Initial Buyer Reference should be from Customer 1.');

        // [WHEN] Change Bill-to Customer to Customer 2
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Bill-to Customer No.", Customer2."No.");

        // [THEN] Buyer Reference is updated to Customer 2's E-Invoice Routing No.
        Assert.AreEqual(RoutingNo2, SalesHeader."Buyer Reference", 'Buyer Reference should update to Customer 2 E-Invoice Routing No.');
    end;

    [Test]
    procedure ServiceHeaderBuyerReferenceFromCustomerWithRoutingNo()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        RoutingNo: Text[50];
    begin
        // [SCENARIO] When creating a Service Invoice for a customer with E-Invoice Routing No., the Buyer Reference is set from the customer.

        // [GIVEN] Customer with E-Invoice Routing No.
        RoutingNo := LibraryEDocDE.CreateValidRoutingNo();
        CreateCustomerWithRoutingNo(Customer, RoutingNo);

        // [WHEN] Create Service Invoice for the customer
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        // [THEN] Buyer Reference is set to the customer's E-Invoice Routing No.
        Assert.AreEqual(RoutingNo, ServiceHeader."Buyer Reference", 'Buyer Reference should be set from Customer E-Invoice Routing No.');
    end;

    [Test]
    procedure ServiceHeaderBuyerReferenceBlankWhenCustomerHasNoRoutingNo()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] When creating a Service Invoice for a customer without E-Invoice Routing No., the Buyer Reference is blank.

        // [GIVEN] Customer without E-Invoice Routing No.
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Create Service Invoice for the customer
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        // [THEN] Buyer Reference is blank
        Assert.AreEqual('', ServiceHeader."Buyer Reference", 'Buyer Reference should be blank when customer has no E-Invoice Routing No.');
    end;

    [Test]
    procedure ServiceHeaderBuyerReferenceUpdatesOnBillToChange()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        ServiceHeader: Record "Service Header";
        RoutingNo1: Text[50];
        RoutingNo2: Text[50];
    begin
        // [SCENARIO] When changing the Bill-to Customer on a Service Invoice, the Buyer Reference updates to the new customer's E-Invoice Routing No.

        // [GIVEN] Two customers with different E-Invoice Routing No. values
        RoutingNo1 := LibraryEDocDE.CreateValidRoutingNo();
        RoutingNo2 := LibraryEDocDE.CreateValidRoutingNo();
        CreateCustomerWithRoutingNo(Customer1, RoutingNo1);
        CreateCustomerWithRoutingNo(Customer2, RoutingNo2);

        // [GIVEN] Service Invoice for Customer 1
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer1."No.");
        Assert.AreEqual(RoutingNo1, ServiceHeader."Buyer Reference", 'Initial Buyer Reference should be from Customer 1.');

        // [WHEN] Change Bill-to Customer to Customer 2
        ServiceHeader.SetHideValidationDialog(true);
        ServiceHeader.Validate("Bill-to Customer No.", Customer2."No.");

        // [THEN] Buyer Reference is updated to Customer 2's E-Invoice Routing No.
        Assert.AreEqual(RoutingNo2, ServiceHeader."Buyer Reference", 'Buyer Reference should update to Customer 2 E-Invoice Routing No.');
    end;

    #endregion

    #region PaymentMeansValidation

    [Test]
    procedure CheckPaymentMeansDirectDebitOnCrMemoRaisesError()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO] Creating an e-document from a posted sales credit memo with a SEPA direct-debit payment method (code 59) raises an error.
        Initialize();

        // [GIVEN] A Payment Method with PEPPOL Payment Means Code = '59'
        PaymentMethodCode := LibraryEDocDE.CreateDirectDebitPaymentMethod();

        // [GIVEN] An otherwise valid Sales Credit Memo that uses that Payment Method
        CreateValidSalesCrMemoHeader(SalesCrMemoHeader, PaymentMethodCode);

        // [WHEN] XRechnungFormat.Check() is called
        // [THEN] An error is raised containing the payment means code
        asserterror CheckSalesCrMemoHeader(SalesCrMemoHeader);
        Assert.ExpectedError('SEPA direct debit');
    end;

    [Test]
    procedure CheckPaymentMeansDirectDebitMandateIDMissingRaisesError()
    var
        SalesHeader: Record "Sales Header";
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO] Releasing a sales invoice with a SEPA direct-debit payment method but no mandate ID raises an error.
        Initialize();

        // [GIVEN] A Payment Method with PEPPOL Payment Means Code = '59'
        PaymentMethodCode := LibraryEDocDE.CreateDirectDebitPaymentMethod();

        // [GIVEN] A Sales Invoice that uses that Payment Method, with Direct Debit Mandate ID = ''
        CreateSalesInvoiceWithPaymentMethod(SalesHeader, PaymentMethodCode);

        // [WHEN] XRechnungFormat.Check() is called
        // [THEN] An error is raised
        asserterror CheckSalesHeader(SalesHeader);
        Assert.ExpectedError('Direct debit mandate ID is missing');
    end;

    [Test]
    procedure CheckPaymentMeansDirectDebitMandateNotFoundRaisesError()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        PaymentMethodCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Releasing a sales invoice with a mandate ID that has no matching record raises an error.
        Initialize();

        // [GIVEN] A Payment Method with PEPPOL Payment Means Code = '59'
        PaymentMethodCode := LibraryEDocDE.CreateDirectDebitPaymentMethod();

        // [GIVEN] A SEPA Direct Debit Mandate
        CustomerNo := CreateValidCustomerWithDirectDebitMandate(SEPADirectDebitMandate, CustomerBankAccount, PaymentMethodCode);

        // [GIVEN] An otherwise valid Sales Invoice with the mandate ID set
        CreateValidSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        SalesHeader.Modify(true);

        // [GIVEN] The mandate is deleted after being set on the document
        SEPADirectDebitMandate.Delete(true);

        // [WHEN] XRechnungFormat.Check() is called
        // [THEN] An error is raised
        asserterror CheckSalesHeader(SalesHeader);
        Assert.ExpectedError('does not exist');
    end;

    [Test]
    procedure CheckPaymentMeansDirectDebitBankAccountNotFoundRaisesError()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        PaymentMethodCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Releasing a sales invoice where the mandate's customer bank account was deleted raises an error.
        Initialize();

        // [GIVEN] A Payment Method with PEPPOL Payment Means Code = '59'
        PaymentMethodCode := LibraryEDocDE.CreateDirectDebitPaymentMethod();

        // [GIVEN] A SEPA Direct Debit Mandate referencing a Customer Bank Account
        CustomerNo := CreateValidCustomerWithDirectDebitMandate(SEPADirectDebitMandate, CustomerBankAccount, PaymentMethodCode);

        // [GIVEN] The Customer Bank Account is deleted after the mandate is created
        CustomerBankAccount.Delete(true);

        // [GIVEN] An otherwise valid Sales Invoice with the mandate ID set
        CreateValidSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        SalesHeader.Modify(true);

        // [WHEN] XRechnungFormat.Check() is called
        // [THEN] An error is raised
        asserterror CheckSalesHeader(SalesHeader);
        Assert.ExpectedError('does not exist');
    end;

    [Test]
    procedure CheckPaymentMeansDirectDebitIBANMissingRaisesError()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        PaymentMethodCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Releasing a sales invoice where the mandate's customer bank account has no IBAN raises an error.
        Initialize();

        // [GIVEN] A Payment Method with PEPPOL Payment Means Code = '59'
        PaymentMethodCode := LibraryEDocDE.CreateDirectDebitPaymentMethod();

        // [GIVEN] A SEPA Direct Debit Mandate referencing a Customer Bank Account with IBAN = ''
        CustomerNo := CreateValidCustomerWithDirectDebitMandate(SEPADirectDebitMandate, CustomerBankAccount, PaymentMethodCode);
        CustomerBankAccount.IBAN := '';
        CustomerBankAccount.Modify(true);

        // [GIVEN] An otherwise valid Sales Invoice with the mandate ID set
        CreateValidSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        SalesHeader.Modify(true);

        // [WHEN] XRechnungFormat.Check() is called
        // [THEN] An error is raised
        asserterror CheckSalesHeader(SalesHeader);
        Assert.ExpectedError('has no IBAN');
    end;

    #endregion

    local procedure CreateCustomerWithRoutingNo(var Customer: Record Customer; RoutingNo: Text[50])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."E-Invoice Routing No." := RoutingNo;
        Customer.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithPaymentMethod(var SalesHeader: Record "Sales Header"; PaymentMethodCode: Code[10])
    begin
        CreateValidSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateValidCustomer());
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateValidCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.Validate("VAT Registration No.", CompanyInformation."VAT Registration No.");
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateValidCustomerWithDirectDebitMandate(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; var CustomerBankAccount: Record "Customer Bank Account"; PaymentMethodCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        CustomerNo := LibraryEDocDE.CreateCustomerWithDirectDebitMandate(SEPADirectDebitMandate, CustomerBankAccount, PaymentMethodCode);
        Customer.Get(CustomerNo);
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.Validate("VAT Registration No.", CompanyInformation."VAT Registration No.");
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Modify(true);
        exit(CustomerNo);
    end;

    local procedure CreateValidSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.FindPostCode(PostCode);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Bill-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Bill-to City", PostCode.City);
        SalesHeader.Validate("Ship-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Ship-to City", PostCode.City);
        SalesHeader.Validate("Payment Terms Code", LibraryERM.FindPaymentTermsCode());
        SalesHeader.Modify(true);
    end;

    local procedure CreateValidSalesCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PaymentMethodCode: Code[10])
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.FindPostCode(PostCode);
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."Bill-to Name" := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(SalesCrMemoHeader."Bill-to Name"));
        SalesCrMemoHeader."Bill-to Address" := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(SalesCrMemoHeader."Bill-to Address"));
        SalesCrMemoHeader."Bill-to City" := PostCode.City;
        SalesCrMemoHeader."Bill-to Post Code" := PostCode.Code;
        SalesCrMemoHeader."Bill-to Country/Region Code" := CompanyInformation."Country/Region Code";
        SalesCrMemoHeader."Ship-to Address" := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(SalesCrMemoHeader."Ship-to Address"));
        SalesCrMemoHeader."Ship-to City" := PostCode.City;
        SalesCrMemoHeader."Ship-to Post Code" := PostCode.Code;
        SalesCrMemoHeader."Ship-to Country/Region Code" := CompanyInformation."Country/Region Code";
        SalesCrMemoHeader."Due Date" := WorkDate();
        SalesCrMemoHeader."Sell-to E-Mail" := LibraryUtility.GenerateRandomEmail();
        SalesCrMemoHeader."Payment Method Code" := PaymentMethodCode;
    end;

    local procedure CheckSalesHeader(SalesHeader: Record "Sales Header")
    var
        SourceDocumentHeader: RecordRef;
    begin
        SourceDocumentHeader.GetTable(SalesHeader);
        ExportXRechnungFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Release);
    end;

    local procedure CheckSalesCrMemoHeader(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SourceDocumentHeader: RecordRef;
    begin
        SourceDocumentHeader.GetTable(SalesCrMemoHeader);
        ExportXRechnungFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Post);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"E-Document DE Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"E-Document DE Tests");
        IsInitialized := true;

        CompanyInformation.Get();
        CompanyInformation.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        CompanyInformation."SWIFT Code" := LibraryUtility.GenerateGUID();
        CompanyInformation."E-Mail" := LibraryUtility.GenerateRandomEmail();
        CompanyInformation.Modify();

        EDocumentService.DeleteAll();
        EDocumentService.Get(LibraryEdocument.CreateService("E-Document Format"::XRechnung, "Service Integration"::"No Integration"));
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"E-Document DE Tests");
    end;
}
