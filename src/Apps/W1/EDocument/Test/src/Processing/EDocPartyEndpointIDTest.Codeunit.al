// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Peppol;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Reminder;
using System.Utilities;

codeunit 139791 "E-Doc. Party Endpoint ID Test"
{
    Subtype = Test;
    TestType = Uncategorized;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryPurchase: Codeunit "Library - Purchase";
        GLNSchemeIDTok: Label '0088', Locked = true;
        MissingCompanyPartyIdErr: Label 'You must specify %1 in %2, or specify %3 and enable %4.', Comment = '%1 - VAT Registration No. field caption, %2 - Company Information table caption, %3 - GLN field caption, %4 - Use GLN in Electronic Documents field caption';
        MissingCustomerPartyIdErr: Label 'You must specify %1 for Customer %2, or specify %3 and enable %4.', Comment = '%1 - VAT Registration No. field caption, %2 - Customer No., %3 - GLN field caption, %4 - Use GLN in Electronic Documents field caption';
        BuyerEndpointMissingErr: Label 'cac:BuyerCustomerParty/cac:Party/cbc:EndpointID was not found in the exported PEPPOL order.';
        FailedToGetBlobErr: Label 'Failed to get exported blob from E-Document %1.', Comment = '%1 - E-Document Entry No.';

    [Test]
    procedure PurchOrderReleaseFailsWhenCompanyIdentifiesByGLNOnlyAndGLNIsNotUsed()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [E-Document] [Purchase Order] [PEPPOL] [AI test 1.0]
        // [SCENARIO 648781] Releasing a purchase order fails when Company Information only has a GLN and "Use GLN in Electronic Documents" is disabled.
        Initialize();

        // [GIVEN] Company Information has a GLN, no VAT Registration No. and "Use GLN in Electronic Documents" disabled
        SetCompanyPartyIdentification(TestGLN(), '', false);

        // [GIVEN] A purchase order for a vendor that is set up for e-documents
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);

        // [WHEN] The purchase order is released
        asserterror LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] The release is blocked and the message names the setting that makes the GLN unusable
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(GetExpectedCompanyErrorText());

        // [THEN] No e-document was created for the purchase order
        EDocument.SetRange("Document Record ID", PurchaseHeader.RecordId());
        Assert.RecordIsEmpty(EDocument);
    end;

    [Test]
    procedure PurchOrderExportsGLNAsEndpointIDWhenGLNIsUsed()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        EDocumentLog: Codeunit "E-Document Log";
        EndpointID: Text;
        SchemeID: Text;
    begin
        // [FEATURE] [E-Document] [Purchase Order] [PEPPOL] [AI test 1.0]
        // [SCENARIO 648781] A company that identifies by GLN only can release and export a purchase order when "Use GLN in Electronic Documents" is enabled.
        Initialize();

        // [GIVEN] Company Information has a GLN, no VAT Registration No. and "Use GLN in Electronic Documents" enabled
        SetCompanyPartyIdentification(TestGLN(), '', true);

        // [GIVEN] A purchase order for a vendor that is set up for e-documents
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);

        // [WHEN] The purchase order is released
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] The exported order carries the GLN as the buyer endpoint identifier
        EDocument.SetRange("Document Record ID", PurchaseHeader.RecordId());
        EDocument.FindFirst();
        EDocumentLog.GetDocumentBlobFromLog(EDocument, EDocumentService, TempBlob, Enum::"E-Document Service Status"::Exported);
        Assert.IsTrue(TempBlob.HasValue(), StrSubstNo(FailedToGetBlobErr, EDocument."Entry No"));

        GetBuyerEndpointID(TempBlob, EndpointID, SchemeID);
        Assert.AreEqual(TestGLN(), EndpointID, 'cbc:EndpointID must contain the GLN.');
        Assert.AreEqual(GLNSchemeIDTok, SchemeID, 'cbc:EndpointID must use the GLN scheme.');
    end;

    [Test]
    procedure PurchOrderExportsVATRegNoAsEndpointIDWhenGLNIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        EDocumentLog: Codeunit "E-Document Log";
        EndpointID: Text;
        SchemeID: Text;
        VATRegistrationNoTok: Label 'GB123456789', Locked = true;
    begin
        // [FEATURE] [E-Document] [Purchase Order] [PEPPOL] [AI test 1.0]
        // [SCENARIO 648781] A company without a GLN keeps exporting the VAT Registration No. as the buyer endpoint identifier.
        Initialize();

        // [GIVEN] Company Information has no GLN but a VAT Registration No.
        SetCompanyPartyIdentification('', VATRegistrationNoTok, false);

        // [GIVEN] A purchase order for a vendor that is set up for e-documents
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);

        // [WHEN] The purchase order is released
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] The exported order carries the VAT Registration No. as the buyer endpoint identifier
        EDocument.SetRange("Document Record ID", PurchaseHeader.RecordId());
        EDocument.FindFirst();
        EDocumentLog.GetDocumentBlobFromLog(EDocument, EDocumentService, TempBlob, Enum::"E-Document Service Status"::Exported);
        Assert.IsTrue(TempBlob.HasValue(), StrSubstNo(FailedToGetBlobErr, EDocument."Entry No"));

        GetBuyerEndpointID(TempBlob, EndpointID, SchemeID);
        Assert.AreNotEqual('', EndpointID, 'cbc:EndpointID must not be empty.');
        Assert.IsTrue(StrPos(EndpointID, '123456789') > 0, 'cbc:EndpointID must contain the VAT Registration No.');
    end;

    [Test]
    procedure PurchOrderPartyIdentificationIsOnlyCheckedOnRelease()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SourceDocumentHeader: RecordRef;
        EDocumentInterface: Interface "E-Document";
    begin
        // [FEATURE] [E-Document] [Purchase Order] [PEPPOL] [AI test 1.0]
        // [SCENARIO 648781] The buyer party identification is validated when the purchase order is released, not when a purchase document is posted.
        Initialize();

        // [GIVEN] Company Information that cannot produce a buyer endpoint identifier
        SetCompanyPartyIdentification(TestGLN(), '', false);

        // [GIVEN] A purchase order
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        SourceDocumentHeader.GetTable(PurchaseHeader);
        EDocumentInterface := Enum::"E-Document Format"::"PEPPOL BIS 3.0";

        // [WHEN] The document is checked in the Post phase
        // [THEN] Posting is not blocked, because releasing the order is what creates the e-document
        EDocumentInterface.Check(SourceDocumentHeader, EDocumentService, Enum::"E-Document Processing Phase"::Post);

        // [WHEN] The document is checked in the Release phase
        asserterror EDocumentInterface.Check(SourceDocumentHeader, EDocumentService, Enum::"E-Document Processing Phase"::Release);

        // [THEN] The check fails
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(GetExpectedCompanyErrorText());
    end;

    [Test]
    procedure SalesDocValidationFailsWhenCompanyIdentifiesByGLNOnlyAndGLNIsNotUsed()
    var
        SalesHeader: Record "Sales Header";
        PEPPOL30SalesValidation: Codeunit "PEPPOL30 Sales Validation";
    begin
        // [FEATURE] [E-Document] [Sales] [PEPPOL] [AI test 1.0]
        // [SCENARIO 648781] Sales document validation fails when Company Information only has a GLN and "Use GLN in Electronic Documents" is disabled.
        Initialize();

        // [GIVEN] Company Information has a GLN, no VAT Registration No. and "Use GLN in Electronic Documents" disabled
        SetCompanyPartyIdentification(TestGLN(), '', false);

        // [GIVEN] A sales order for a customer that is set up for e-documents
        LibraryEDoc.CreateSalesHeaderWithItem(Customer, SalesHeader, Enum::"Sales Document Type"::Order);

        // [WHEN] The sales document is validated against PEPPOL
        asserterror PEPPOL30SalesValidation.ValidateDocument(SalesHeader);

        // [THEN] The validation fails and the message names the setting that makes the GLN unusable
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(GetExpectedCompanyErrorText());
    end;

    [Test]
    procedure SalesDocValidationFailsWhenCustomerIdentifiesByGLNOnlyAndGLNIsNotUsed()
    var
        SalesHeader: Record "Sales Header";
        PEPPOL30SalesValidation: Codeunit "PEPPOL30 Sales Validation";
    begin
        // [FEATURE] [E-Document] [Sales] [PEPPOL] [AI test 1.0]
        // [SCENARIO 648781] Sales document validation fails when the customer only has a GLN and "Use GLN in Electronic Documents" is disabled.
        Initialize();

        // [GIVEN] Company Information that can produce an endpoint identifier
        SetCompanyPartyIdentification('', 'GB123456789', false);
        // [GIVEN] A customer that has a GLN but does not use it in electronic documents
        Customer.Get(Customer."No.");
        Customer.Validate(GLN, TestGLN());
        Customer."Use GLN in Electronic Document" := false;
        Customer.Modify(true);

        // [GIVEN] A sales order without a VAT Registration No.
        LibraryEDoc.CreateSalesHeaderWithItem(Customer, SalesHeader, Enum::"Sales Document Type"::Order);
        SalesHeader."VAT Registration No." := '';
        SalesHeader.Modify();

        // [WHEN] The sales document is validated against PEPPOL
        asserterror PEPPOL30SalesValidation.ValidateDocument(SalesHeader);

        // [THEN] The validation fails and the message names the customer and the setting
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(GetExpectedCustomerErrorText(Customer."No."));
    end;

    [Test]
    procedure ReminderValidationFailsWhenCustomerIdentifiesByGLNOnlyAndGLNIsNotUsed()
    var
        ReminderHeader: Record "Reminder Header";
        SourceDocumentHeader: RecordRef;
        EDocumentInterface: Interface "E-Document";
    begin
        // [FEATURE] [E-Document] [Reminder] [PEPPOL] [AI test 1.0]
        // [SCENARIO 648781] Reminder validation fails when the customer only has a GLN and "Use GLN in Electronic Documents" is disabled.
        Initialize();

        // [GIVEN] Company Information that can produce an endpoint identifier
        SetCompanyPartyIdentification('', 'GB123456789', false);

        // [GIVEN] A customer that has a GLN but does not use it in electronic documents and has no VAT Registration No.
        SetCustomerPartyIdentification(TestGLN(), '', false);

        // [GIVEN] A reminder for that customer
        LibraryEDoc.SetupReminderNoSeries();
        LibraryEDoc.CreateReminderWithLine(Customer, ReminderHeader);
        SourceDocumentHeader.GetTable(ReminderHeader);
        EDocumentInterface := Enum::"E-Document Format"::"PEPPOL BIS 3.0";

        // [WHEN] The reminder is validated against PEPPOL
        asserterror EDocumentInterface.Check(SourceDocumentHeader, EDocumentService, Enum::"E-Document Processing Phase"::Post);

        // [THEN] The validation fails and the message names the customer and the setting
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(GetExpectedCustomerErrorText(Customer."No."));
    end;

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        Clear(EDocumentService);

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Mock);
        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Order");
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService);

        Vendor."Document Sending Profile" := Customer."Document Sending Profile";
        Vendor.Modify(true);

        LibraryPurchase.SetOrderNoSeriesInSetup();
        EnsureCountryRegionISOCode(Customer."Country/Region Code");
        EnsureCountryRegionISOCode(Vendor."Country/Region Code");
    end;

    local procedure TestGLN(): Code[13]
    begin
        exit('1234567891231');
    end;

    local procedure SetCompanyPartyIdentification(NewGLN: Code[13]; NewVATRegistrationNo: Text[20]; UseGLNInElectronicDocument: Boolean)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := NewVATRegistrationNo;
        CompanyInformation.Validate(GLN, NewGLN);
        CompanyInformation.Validate("Use GLN in Electronic Document", UseGLNInElectronicDocument);
        CompanyInformation.Modify(true);

        EnsureCountryRegionISOCode(CompanyInformation."Country/Region Code");
    end;

    local procedure SetCustomerPartyIdentification(NewGLN: Code[13]; NewVATRegistrationNo: Text[20]; UseGLNInElectronicDocument: Boolean)
    begin
        Customer.Get(Customer."No.");
        Customer."VAT Registration No." := NewVATRegistrationNo;
        Customer.Validate(GLN, NewGLN);
        Customer.Validate("Use GLN in Electronic Document", UseGLNInElectronicDocument);
        Customer.Modify(true);
    end;

    local procedure EnsureCountryRegionISOCode(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryRegionCode) then
            exit;
        if StrLen(CountryRegion."ISO Code") = 2 then
            exit;

        CountryRegion."ISO Code" := CopyStr(CountryRegion.Code, 1, 2);
        CountryRegion.Modify();
    end;

    local procedure GetExpectedCompanyErrorText(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        exit(
            StrSubstNo(
                MissingCompanyPartyIdErr,
                CompanyInformation.FieldCaption("VAT Registration No."), CompanyInformation.TableCaption(),
                CompanyInformation.FieldCaption(GLN), CompanyInformation.FieldCaption("Use GLN in Electronic Document")));
    end;

    local procedure GetExpectedCustomerErrorText(CustomerNo: Code[20]): Text
    begin
        exit(
            StrSubstNo(
                MissingCustomerPartyIdErr,
                Customer.FieldCaption("VAT Registration No."), CustomerNo,
                Customer.FieldCaption(GLN), Customer.FieldCaption("Use GLN in Electronic Document")));
    end;

    local procedure GetBuyerEndpointID(var TempBlob: Codeunit "Temp Blob"; var EndpointID: Text; var SchemeID: Text)
    var
        XmlDoc: XmlDocument;
        XmlNsManager: XmlNamespaceManager;
        EndpointNode: XmlNode;
        SchemeAttribute: XmlAttribute;
        DocInStream: InStream;
        CacNsTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        CbcNsTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
    begin
        TempBlob.CreateInStream(DocInStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(DocInStream, XmlDoc);
        XmlNsManager.NameTable(XmlDoc.NameTable);
        XmlNsManager.AddNamespace('cac', CacNsTok);
        XmlNsManager.AddNamespace('cbc', CbcNsTok);

        Assert.IsTrue(
            XmlDoc.SelectSingleNode('//cac:BuyerCustomerParty/cac:Party/cbc:EndpointID', XmlNsManager, EndpointNode),
            BuyerEndpointMissingErr);

        EndpointID := EndpointNode.AsXmlElement().InnerText();
        SchemeID := '';
        if EndpointNode.AsXmlElement().Attributes().Get('schemeID', SchemeAttribute) then
            SchemeID := SchemeAttribute.Value();
    end;
}
