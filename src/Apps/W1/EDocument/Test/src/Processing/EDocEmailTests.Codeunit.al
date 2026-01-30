// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.CRM.Contact;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Email;
using System.IO;
using System.TestLibraries.Email;


codeunit 139746 "E-Doc. Email Tests"
{

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    Access = Internal;

    var
        Account: Record "Email Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EmailConnectorMock: Codeunit "Connector Mock";
        LibraryEDoc: Codeunit "Library - E-Document";
        LibrarySales: Codeunit "Library - Sales";
        EDocImplState: Codeunit "E-Doc. Impl. State";
        EmailScenario: Codeunit "Email Scenario";
        Assert: Codeunit Assert;



    [Test]
    [HandlerFunctions('PostAndSendConfirmationHandler')]
    procedure TestPostAndSendFromSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SentEmails: Record "Sent Email";
        Contact: Record Contact;
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
        DataCompression: Codeunit "Data Compression";
        EmailMessage: Codeunit "Email Message";
        SalesInvoicePage: TestPage "Sales Invoice";
        Instream: InStream;
        EntryList: List of [Text];
    begin
        // [FEATURE] [E-Document] [Processing]
        // [SCENARIO] Create customer with document sending profile setup to use e-document workflow.
        // From sales invoice, invoke Post and Send action and verify that email is send with e-document attached.
        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        DocumentSendingProfile.DeleteAll();
        BindSubscription(EDocImplState);

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);
        EDocumentService.Modify();

        DocumentSendingProfile.FindLast();
        DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)";
        DocumentSendingProfile."E-Mail Attachment" := DocumentSendingProfile."E-Mail Attachment"::"PDF & E-Document";
        DocumentSendingProfile.Modify();

        EmailConnectorMock.Initialize();
        EmailConnectorMock.AddAccount(Account);
        EmailScenario.SetDefaultEmailAccount(Account);

        Customer."E-Mail" := 'Test123@example.com';
        Customer.Modify();

        Customer.GetPrimaryContact(Customer."No.", Contact); // Some localizations require contact to have email address
        if Contact."No." <> '' then begin
            Contact."E-Mail" := Customer."E-Mail";
            Contact.Modify();
        end;

        ReportSelections.SetRange("Report ID", 31018); // CZ localization report rendering requires specific layout: Bug 609737
        if ReportSelections.FindSet() then
            repeat
                ReportSelections.Validate("Email Body Layout Name", 'SalesInvoicewithAdvEmail.docx');
                ReportSelections.Modify();
            until ReportSelections.Next() = 0;

        LibraryEDoc.CreateSalesHeaderWithItem(Customer, SalesHeader, Enum::"Sales Document Type"::Invoice);
        SalesInvoicePage.OpenView();
        SalesInvoicePage.GoToRecord(SalesHeader);

        SalesInvoicePage.PostAndSend.Invoke();

        SentEmails.FindLast();
        EmailMessage.Get(SentEmails.GetMessageId());
        EmailMessage.Attachments_First();
        EmailMessage.Attachments_GetContent(Instream);

        DataCompression.OpenZipArchive(Instream, false);
        DataCompression.GetEntryList(EntryList);

        Assert.AreEqual(2, EntryList.Count(), 'Number of attachments in the email is not as expected.');
        Assert.IsTrue(EntryList.Get(1).Contains('.xml'), 'First attachment is not e-document.');
        Assert.IsTrue(EntryList.Get(2).Contains('.pdf'), 'Second attachment is not PDF document.');

        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsHandler')]
    procedure TestSendFromPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SentEmails: Record "Sent Email";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        DataCompression: Codeunit "Data Compression";
        EmailMessage: Codeunit "Email Message";
        SalesInvoicePage: TestPage "Posted Sales Invoice";
        Instream: InStream;
        EntryList: List of [Text];
    begin
        // [FEATURE] [E-Document] [Processing]
        // [SCENARIO] Create customer with document sending profile setup to use e-document workflow.
        // From posted sales invoice, invoke Send action and verify that email is send with e-document attached.
        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        DocumentSendingProfile.DeleteAll();
        BindSubscription(EDocImplState);

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);
        EDocumentService.Modify();


        DocumentSendingProfile.FindLast();
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::No;
        DocumentSendingProfile.Modify();

        EmailConnectorMock.Initialize();
        EmailConnectorMock.AddAccount(Account);
        EmailScenario.SetDefaultEmailAccount(Account);

        Customer."E-Mail" := 'Test123@example.com';
        Customer.Modify();

        LibraryEDoc.CreateSalesHeaderWithItem(Customer, SalesHeader, Enum::"Sales Document Type"::Invoice);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));
        SalesInvoicePage.OpenView();
        SalesInvoicePage.GoToRecord(SalesInvoiceHeader);

        DocumentSendingProfile.FindLast();
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::"Extended E-Document Service Flow";
        DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)";
        DocumentSendingProfile."E-Mail Attachment" := DocumentSendingProfile."E-Mail Attachment"::"PDF & E-Document";
        DocumentSendingProfile.Modify();

        SalesInvoicePage.SendCustom.Invoke();

        SentEmails.FindLast();
        EmailMessage.Get(SentEmails.GetMessageId());
        EmailMessage.Attachments_First();
        EmailMessage.Attachments_GetContent(Instream);

        DataCompression.OpenZipArchive(Instream, false);
        DataCompression.GetEntryList(EntryList);

        Assert.AreEqual(2, EntryList.Count(), 'Number of attachments in the email is not as expected.');
        Assert.IsTrue(EntryList.Get(1).Contains('.xml'), 'First attachment is not e-document.');
        Assert.IsTrue(EntryList.Get(2).Contains('.pdf'), 'Second attachment is not PDF document.');

        UnbindSubscription(EDocImplState);
    end;

    [ModalPageHandler]
    procedure PostAndSendConfirmationHandler(var PostAndSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostAndSendConfirmation.Yes().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectSendingOptionsHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    begin
        SelectSendingOptions.OK().Invoke();
    end;




}
