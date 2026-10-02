
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
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
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryEDocDE: Codeunit "Library - E-Doc DE";
        LibraryEdocument: Codeunit "Library - E-Document";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

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

    #region ShipToAddress

    [Test]
    procedure SalesCrMemoWithoutShipToAddressPassesDEValidation()
    var
        EDocumentService: Record "E-Document Service";
        SalesHeader: Record "Sales Header";
        EDocPEPPOLBIS30DE: Codeunit "EDoc PEPPOL BIS 3.0 DE";
        SourceDocumentHeader: RecordRef;
    begin
        // [SCENARIO 9815] A sales credit memo without a deliver-to address passes the German PEPPOL validation on release

        // [GIVEN] Company information with the bank details the validation requires
        SetCompanyBankDetails();
        EDocumentService.Get(LibraryEdocument.CreateService("E-Document Format"::"PEPPOL BIS 3.0 DE", "Service Integration"::"No Integration"));

        // [GIVEN] Sales Credit Memo with all ship-to address fields empty
        CreateSalesCrMemoWithoutShipToAddress(SalesHeader);

        // [WHEN] Check the Sales Credit Memo for release
        SourceDocumentHeader.GetTable(SalesHeader);
        EDocPEPPOLBIS30DE.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Release);

        // [THEN] No error
    end;

    #endregion

    local procedure CreateSalesCrMemoWithoutShipToAddress(var SalesHeader: Record "Sales Header")
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        CompanyInformation.Get();
        CreateCustomerWithRoutingNo(Customer, LibraryEDocDE.CreateValidRoutingNo());
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Modify(true);

        LibraryERM.FindPostCode(PostCode);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader.Validate("Bill-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Bill-to City", PostCode.City);
        SalesHeader.Validate("Payment Terms Code", LibraryERM.FindPaymentTermsCode());
        SalesHeader."Ship-to Code" := '';
        SalesHeader."Ship-to Address" := '';
        SalesHeader."Ship-to Address 2" := '';
        SalesHeader."Ship-to City" := '';
        SalesHeader."Ship-to Post Code" := '';
        SalesHeader."Ship-to County" := '';
        SalesHeader."Ship-to Country/Region Code" := '';
        SalesHeader.Modify(true);
    end;

    local procedure SetCompanyBankDetails()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        CompanyInformation."SWIFT Code" := LibraryUtility.GenerateGUID();
        if CompanyInformation."Bank Branch No." = '' then
            CompanyInformation."Bank Branch No." := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify();
    end;

    local procedure CreateCustomerWithRoutingNo(var Customer: Record Customer; RoutingNo: Text[50])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."E-Invoice Routing No." := RoutingNo;
        Customer.Modify(true);
    end;
}
