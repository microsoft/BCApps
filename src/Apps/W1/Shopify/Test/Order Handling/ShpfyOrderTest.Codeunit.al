// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Integration.Shopify;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.TestLibraries.Utilities;

codeunit 139609 "Shpfy Order Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    local procedure Initialize();

    begin
        if isInitialized then
            exit;
        LibraryRandom.Init();
        isInitialized := true;
    end;

    [Test]
    procedure TestSalesOrderWithShopifyOrderNo()
    var
        ShopifyOrderNo: Code[50];
    begin
        Initialize();
        ShopifyOrderNo := CopyStr(LibraryRandom.RandText(MaxStrLen(ShopifyOrderNo)), 1, MaxStrLen(ShopifyOrderNo));
        Assert.AreEqual(ShopifyOrderNo, CreateSalesOrder(ShopifyOrderNo), 'Shpfy Order No. must be the same as on the order');
        ShopifyOrderNo := '';
        Assert.AreEqual(ShopifyOrderNo, CreateSalesOrder(ShopifyOrderNo), 'Shpfy Order No. must be blank');

    end;

    [Test]
    procedure TestSalesOrderArchive()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
        ShopifyOrderNo: Code[50];
    begin
        Initialize();
        LibrarySales.SetArchiveOrders(true);
        ShopifyOrderNo := CopyStr(LibraryRandom.RandText(MaxStrLen(ShopifyOrderNo)), 1, MaxStrLen(ShopifyOrderNo));
        CreateSalesOrder(ShopifyOrderNo, SalesHeader);
        SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::Order);
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindLast();
        Assert.AreEqual(ShopifyOrderNo, SalesHeaderArchive."Shpfy Order No.", 'Shpfy Order No. must be the same as on the order header');
        SalesLineArchive.SetRange("Document Type", SalesLineArchive."Document Type"::Order);
        SalesLineArchive.SetRange("Document No.", SalesHeaderArchive."No.");
        SalesLineArchive.FindLast();
        Assert.AreEqual(ShopifyOrderNo, SalesLineArchive."Shpfy Order No.", 'Shpfy Order No. must be the same as on the order line');
    end;

    local procedure CreateSalesOrder(ShopifyOrderNo: Code[50]): Code[50]
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(CreateSalesOrder(ShopifyOrderNo, SalesHeader));
    end;

    local procedure CreateSalesOrder(ShopifyOrderNo: Code[50]; var SalesHeader: Record "Sales Header"): Code[50]
    var
        Customer: Record Customer;
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesLine: Record "Sales Line";
        OrderNo: Code[50];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesOrder(SalesHeader);
        OrderNo := SalesHeader."No.";
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesHeader."Shpfy Order No." := ShopifyOrderNo;
        SalesHeader.Modify();
        SalesLine."Shpfy Order No." := ShopifyOrderNo;
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."Shpfy Order No.");
    end;

    [Test]
    procedure TestSellToContactNoValidationValidContact()
    var
        OrderHeader: Record "Shpfy Order Header";
        Customer: Record Customer;
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
    begin
        // [SCENARIO] Setting a valid contact related to the sell-to customer should succeed.
        Initialize();

        // [GIVEN] A customer with a related contact
        LibrarySales.CreateCustomer(Customer);
        FindCompanyContactForCustomer(Customer."No.", CompanyContact);
        CreatePersonContactForCompany(CompanyContact."No.", PersonContact);

        // [GIVEN] A Shopify Order Header with the customer
        CreateShopifyOrderHeader(OrderHeader);
        OrderHeader."Sell-to Customer No." := Customer."No.";
        OrderHeader.Modify();

        // [WHEN] Setting the sell-to contact no. to the related contact
        // [THEN] No error is raised
        OrderHeader.Validate("Sell-to Contact No.", PersonContact."No.");
    end;

    [Test]
    procedure TestSellToContactNoValidationInvalidContact()
    var
        OrderHeader: Record "Shpfy Order Header";
        Customer1: Record Customer;
        Customer2: Record Customer;
        CompanyContact2: Record Contact;
        PersonContact2: Record Contact;
    begin
        // [SCENARIO] Setting a contact not related to the sell-to customer should raise an error.
        Initialize();

        // [GIVEN] Two customers with their own contacts
        LibrarySales.CreateCustomer(Customer1);
        LibrarySales.CreateCustomer(Customer2);
        FindCompanyContactForCustomer(Customer2."No.", CompanyContact2);
        CreatePersonContactForCompany(CompanyContact2."No.", PersonContact2);

        // [GIVEN] A Shopify Order Header with Customer1
        CreateShopifyOrderHeader(OrderHeader);
        OrderHeader."Sell-to Customer No." := Customer1."No.";
        OrderHeader.Modify();

        // [WHEN] Setting the sell-to contact no. to a contact related to Customer2
        // [THEN] An error is raised
        asserterror OrderHeader.Validate("Sell-to Contact No.", PersonContact2."No.");
        LibraryAssert.ExpectedError('is not related to customer');
    end;

    [Test]
    procedure TestBillToContactNoValidationInvalidContact()
    var
        OrderHeader: Record "Shpfy Order Header";
        Customer1: Record Customer;
        Customer2: Record Customer;
        CompanyContact2: Record Contact;
        PersonContact2: Record Contact;
    begin
        // [SCENARIO] Setting a bill-to contact not related to the bill-to customer should raise an error.
        Initialize();

        // [GIVEN] Two customers with their own contacts
        LibrarySales.CreateCustomer(Customer1);
        LibrarySales.CreateCustomer(Customer2);
        FindCompanyContactForCustomer(Customer2."No.", CompanyContact2);
        CreatePersonContactForCompany(CompanyContact2."No.", PersonContact2);

        // [GIVEN] A Shopify Order Header with Customer1 as bill-to
        CreateShopifyOrderHeader(OrderHeader);
        OrderHeader."Bill-to Customer No." := Customer1."No.";
        OrderHeader.Modify();

        // [WHEN] Setting the bill-to contact no. to a contact related to Customer2
        // [THEN] An error is raised
        asserterror OrderHeader.Validate("Bill-to Contact No.", PersonContact2."No.");
        LibraryAssert.ExpectedError('is not related to customer');
    end;

    [Test]
    procedure TestShipToContactNoValidationUsesSellToCustomer()
    var
        OrderHeader: Record "Shpfy Order Header";
        Customer1: Record Customer;
        Customer2: Record Customer;
        CompanyContact2: Record Contact;
        PersonContact2: Record Contact;
    begin
        // [SCENARIO] Ship-to contact no. should be validated against the sell-to customer.
        Initialize();

        // [GIVEN] Two customers with their own contacts
        LibrarySales.CreateCustomer(Customer1);
        LibrarySales.CreateCustomer(Customer2);
        FindCompanyContactForCustomer(Customer2."No.", CompanyContact2);
        CreatePersonContactForCompany(CompanyContact2."No.", PersonContact2);

        // [GIVEN] A Shopify Order Header with Customer1 as sell-to
        CreateShopifyOrderHeader(OrderHeader);
        OrderHeader."Sell-to Customer No." := Customer1."No.";
        OrderHeader.Modify();

        // [WHEN] Setting the ship-to contact no. to a contact related to Customer2
        // [THEN] An error is raised (ship-to validates against sell-to customer)
        asserterror OrderHeader.Validate("Ship-to Contact No.", PersonContact2."No.");
        LibraryAssert.ExpectedError('is not related to customer');
    end;

    [Test]
    procedure TestContactNoValidationBlankContactNoAllowed()
    var
        OrderHeader: Record "Shpfy Order Header";
        Customer: Record Customer;
    begin
        // [SCENARIO] Setting a blank contact no. should be allowed.
        Initialize();

        // [GIVEN] A Shopify Order Header with a customer
        LibrarySales.CreateCustomer(Customer);
        CreateShopifyOrderHeader(OrderHeader);
        OrderHeader."Sell-to Customer No." := Customer."No.";
        OrderHeader.Modify();

        // [WHEN] Setting the sell-to contact no. to blank
        // [THEN] No error is raised
        OrderHeader.Validate("Sell-to Contact No.", '');
    end;

    local procedure CreateShopifyOrderHeader(var OrderHeader: Record "Shpfy Order Header")
    begin
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := Any.IntegerInRange(100000, 999999);
        if not OrderHeader.Insert() then begin
            OrderHeader.Delete();
            OrderHeader.Insert();
        end;
    end;

    local procedure FindCompanyContactForCustomer(CustomerNo: Code[20]; var CompanyContact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", "Contact Business Relation Link To Table"::Customer);
        ContactBusinessRelation.SetRange("No.", CustomerNo);
        ContactBusinessRelation.FindFirst();
        CompanyContact.Get(ContactBusinessRelation."Contact No.");
    end;

    local procedure CreatePersonContactForCompany(CompanyContactNo: Code[20]; var PersonContact: Record Contact)
    begin
        PersonContact.Init();
        PersonContact."No." := '';
        PersonContact.Type := "Contact Type"::Person;
        PersonContact.Name := 'Test Person';
        PersonContact.Insert(true);

        PersonContact."Company No." := CompanyContactNo;
        PersonContact.Modify();
    end;

}
