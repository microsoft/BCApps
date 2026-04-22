// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 139897 "E-Doc. Send Subscriber Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    Access = Internal;

    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibrarySales: Codeunit "Library - Sales";
        EDocImplState: Codeunit "E-Doc. Impl. State";

    [Test]
    procedure SendMultiplePostedInvoicesCreatesEDocumentForEach()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader1: Record "Sales Invoice Header";
        SalesInvHeader2: Record "Sales Invoice Header";
        SalesInvHeaderFilter: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        // [FEATURE] [E-Document] [Processing] [Send]
        // [SCENARIO] Sending multiple posted invoices together via Document Sending Profile creates one E-Document per invoice.
        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        DocumentSendingProfile.DeleteAll();
        BindSubscription(EDocImplState);

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);

        // [GIVEN] Document sending profile is temporarily disabled so posting does not auto-create E-Documents
        DocumentSendingProfile.FindLast();
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::No;
        DocumentSendingProfile.Modify();

        // [GIVEN] Two sales invoices are posted without automatic E-Document creation
        LibraryEDoc.CreateSalesHeaderWithItem(Customer, SalesHeader, Enum::"Sales Document Type"::Invoice);
        SalesInvHeader1.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));
        LibraryEDoc.CreateSalesHeaderWithItem(Customer, SalesHeader, Enum::"Sales Document Type"::Invoice);
        SalesInvHeader2.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [GIVEN] Document sending profile is re-enabled with the extended E-Document service flow
        DocumentSendingProfile.FindLast();
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::"Extended E-Document Service Flow";
        DocumentSendingProfile.Modify();

        // [WHEN] Both posted invoices are sent together, simulating a multi-record send from the Posted Sales Invoices list
        SalesInvHeaderFilter.SetFilter("No.", '%1|%2', SalesInvHeader1."No.", SalesInvHeader2."No.");
        SalesInvHeaderFilter.FindFirst();
        DocumentSendingProfile.Send(
            Enum::"Report Selection Usage"::"S.Invoice".AsInteger(),
            SalesInvHeaderFilter,
            SalesInvHeader1."No.",
            SalesInvHeader1."Bill-to Customer No.",
            'Sales Invoice',
            SalesInvHeaderFilter.FieldNo("Bill-to Customer No."),
            SalesInvHeaderFilter.FieldNo("No."));

        // [THEN] One E-Document is created for each of the two posted invoices
        Assert.AreEqual(2, EDocument.Count(), 'Expected one E-Document per sent invoice.');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    procedure SendSinglePostedInvoiceCreatesOneEDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        // [FEATURE] [E-Document] [Processing] [Send]
        // [SCENARIO] Sending a single posted invoice via Document Sending Profile creates exactly one E-Document.
        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        DocumentSendingProfile.DeleteAll();
        BindSubscription(EDocImplState);

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);

        // [GIVEN] Document sending profile is temporarily disabled so posting does not auto-create an E-Document
        DocumentSendingProfile.FindLast();
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::No;
        DocumentSendingProfile.Modify();

        // [GIVEN] A single sales invoice is posted without automatic E-Document creation
        LibraryEDoc.CreateSalesHeaderWithItem(Customer, SalesHeader, Enum::"Sales Document Type"::Invoice);
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [GIVEN] Document sending profile is re-enabled with the extended E-Document service flow
        DocumentSendingProfile.FindLast();
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::"Extended E-Document Service Flow";
        DocumentSendingProfile.Modify();

        // [WHEN] The single posted invoice is sent
        SalesInvHeader.SetRecFilter();
        DocumentSendingProfile.Send(
            Enum::"Report Selection Usage"::"S.Invoice".AsInteger(),
            SalesInvHeader,
            SalesInvHeader."No.",
            SalesInvHeader."Bill-to Customer No.",
            'Sales Invoice',
            SalesInvHeader.FieldNo("Bill-to Customer No."),
            SalesInvHeader.FieldNo("No."));

        // [THEN] Exactly one E-Document is created for the invoice
        Assert.AreEqual(1, EDocument.Count(), 'Expected exactly one E-Document for a single sent invoice.');
        UnbindSubscription(EDocImplState);
    end;
}
