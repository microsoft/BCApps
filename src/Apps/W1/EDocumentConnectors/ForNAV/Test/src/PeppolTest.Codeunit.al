// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using System.Utilities;

codeunit 148220 "ForNAV Peppol Test"
{
    Access = Internal;
    SingleInstance = true;

    var
        PeppolSetup: Codeunit "ForNAV Peppol Setup";
        InitCalled: Boolean;
        StatusCode: Integer;
        VendorNo: Code[20];
        MockGuid: Guid;

    local procedure MockOutgoing(Http: Codeunit "Http Message State")
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        IdLbl: Label '{"id":"%1"}', Locked = true;
    begin
        if StatusCode <> 200 then begin
            HttpClient.Send(Http.GetHttpRequestMessage(), HttpResponseMessage);
            Http.SetHttpResponseMessage(HttpResponseMessage);
        end else
            Http.GetHttpResponseMessage().Content.WriteFrom(StrSubstNo(IdLbl, MockServiceDocumentId()));
    end;

    local procedure MockInbox(Http: Codeunit "Http Message State")
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
#Pragma warning Disable AA0240 // test data
        DocLbl: Label '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Invoice xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ccts="urn:un:unece:uncefact:documentation:2" xmlns:qdt="urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2" xmlns:udt="urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2" xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"><cbc:CustomizationID>urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0</cbc:CustomizationID><cbc:ProfileID>urn:fdc:peppol.eu:2017:poacc:billing:01:1.0</cbc:ProfileID><cbc:ID>103058</cbc:ID><cbc:IssueDate>2026-01-22</cbc:IssueDate><cbc:DueDate>2026-01-22</cbc:DueDate><cbc:InvoiceTypeCode>380</cbc:InvoiceTypeCode><cbc:DocumentCurrencyCode>GBP</cbc:DocumentCurrencyCode><cbc:BuyerReference>GU00000735</cbc:BuyerReference><cac:OrderReference><cbc:ID>GU00000734</cbc:ID></cac:OrderReference><cac:ContractDocumentReference><cbc:ID>103058</cbc:ID></cac:ContractDocumentReference><cac:AccountingCustomerParty><cac:Party><cbc:EndpointID schemeID="9932">GB777777771</cbc:EndpointID><cac:PartyName><cbc:Name>CRONUS International Ltd.</cbc:Name></cac:PartyName><cac:PostalAddress><cbc:StreetName>5BvY5uYNuwknrflnSIcLNsY4BKOe5PSodQC0ULPJh8Vw5xYa8ijRLU5bcrmAWIgVTKZqsBIWshcel1ODkCWL4QS8kyN2YemnpySA</cbc:StreetName><cbc:AdditionalStreetName>Westminster</cbc:AdditionalStreetName><cbc:CityName>rQ6InfxcuDECxcoctYvq</cbc:CityName><cbc:PostalZone>O7HMPDX3GPO0SZOJLLPS</cbc:PostalZone><cac:Country><cbc:IdentificationCode>GB</cbc:IdentificationCode></cac:Country></cac:PostalAddress><cac:PartyTaxScheme><cbc:CompanyID>GB777777771</cbc:CompanyID><cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme></cac:PartyTaxScheme><cac:PartyLegalEntity><cbc:RegistrationName>CRONUS International Ltd.</cbc:RegistrationName><cbc:CompanyID>GB777777771</cbc:CompanyID></cac:PartyLegalEntity></cac:Party></cac:AccountingCustomerParty><cac:AccountingSupplierParty><cac:Party><cbc:EndpointID schemeID="9932">GBVendorVatNo</cbc:EndpointID><cac:PartyIdentification><cbc:ID schemeID="9932">GBVendorVatNo</cbc:ID></cac:PartyIdentification><cac:PartyName><cbc:Name>GL00000090</cbc:Name></cac:PartyName><cac:PostalAddress><cbc:StreetName>GU00000722</cbc:StreetName><cbc:CityName>GU00000723</cbc:CityName><cbc:PostalZone>GU00000724</cbc:PostalZone><cac:Country><cbc:IdentificationCode>GB</cbc:IdentificationCode></cac:Country></cac:PostalAddress><cac:PartyTaxScheme><cbc:CompanyID>GBVendorVatNo</cbc:CompanyID><cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme></cac:PartyTaxScheme><cac:PartyLegalEntity><cbc:RegistrationName>GL00000090</cbc:RegistrationName><cbc:CompanyID>GBVendorVatNo</cbc:CompanyID></cac:PartyLegalEntity><cac:Contact><cbc:Name>GL00000090</cbc:Name></cac:Contact></cac:Party></cac:AccountingSupplierParty><cac:Delivery><cbc:ActualDeliveryDate>2026-01-22</cbc:ActualDeliveryDate><cac:DeliveryLocation><cbc:ID schemeID="9932">GB777777771</cbc:ID><cac:Address><cbc:StreetName>GU00000722</cbc:StreetName><cbc:CityName>GU00000723</cbc:CityName><cbc:PostalZone>GU00000724</cbc:PostalZone><cac:Country><cbc:IdentificationCode>GB</cbc:IdentificationCode></cac:Country></cac:Address></cac:DeliveryLocation></cac:Delivery><cac:PaymentMeans><cbc:PaymentMeansCode>31</cbc:PaymentMeansCode><cac:PayeeFinancialAccount><cbc:ID>GB33BUKB20201555555555</cbc:ID><cac:FinancialInstitutionBranch><cbc:ID>1234</cbc:ID></cac:FinancialInstitutionBranch></cac:PayeeFinancialAccount></cac:PaymentMeans><cac:PaymentTerms><cbc:Note>Cash on delivery</cbc:Note></cac:PaymentTerms><cac:TaxTotal><cbc:TaxAmount currencyID="GBP">0.03</cbc:TaxAmount><cac:TaxSubtotal><cbc:TaxableAmount currencyID="GBP">3</cbc:TaxableAmount><cbc:TaxAmount currencyID="GBP">0.03</cbc:TaxAmount><cac:TaxCategory><cbc:ID>S</cbc:ID><cbc:Percent>1</cbc:Percent><cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme></cac:TaxCategory></cac:TaxSubtotal></cac:TaxTotal><cac:LegalMonetaryTotal><cbc:LineExtensionAmount currencyID="GBP">3</cbc:LineExtensionAmount><cbc:TaxExclusiveAmount currencyID="GBP">3</cbc:TaxExclusiveAmount><cbc:TaxInclusiveAmount currencyID="GBP">3.03</cbc:TaxInclusiveAmount><cbc:AllowanceTotalAmount currencyID="GBP">0</cbc:AllowanceTotalAmount><cbc:PrepaidAmount currencyID="GBP">0.00</cbc:PrepaidAmount><cbc:PayableRoundingAmount currencyID="GBP">0</cbc:PayableRoundingAmount><cbc:PayableAmount currencyID="GBP">3.03</cbc:PayableAmount></cac:LegalMonetaryTotal><cac:InvoiceLine><cbc:ID>10000</cbc:ID><cbc:Note>Item</cbc:Note><cbc:InvoicedQuantity unitCode="UomCode">1</cbc:InvoicedQuantity><cbc:LineExtensionAmount currencyID="GBP">3</cbc:LineExtensionAmount><cac:Item><cbc:Name>ItemNo</cbc:Name><cac:SellersItemIdentification><cbc:ID>ItemNo</cbc:ID></cac:SellersItemIdentification><cac:ClassifiedTaxCategory><cbc:ID>S</cbc:ID><cbc:Percent>1</cbc:Percent><cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme></cac:ClassifiedTaxCategory></cac:Item><cac:Price><cbc:PriceAmount currencyID="GBP">3.00</cbc:PriceAmount><cbc:BaseQuantity unitCode="UomCode">1</cbc:BaseQuantity></cac:Price></cac:InvoiceLine></Invoice>', Locked = true;
#Pragma warning Restore AA0240 // test data
        JsonDoc, Payload : JsonObject;
        Doc: Text;
    begin
        JsonDoc.Add('ID', 'INCOMING');
        JsonDoc.Add('Status', 'Received');
        JsonDoc.Add('DocNo', '103058');
        JsonDoc.Add('DocType', 'Invoice');
        JsonDoc.Add('DocCode', 380);
        JsonDoc.Add('Doc', DocLbl);
        Payload.Add('INCOMING', JsonDoc);
        Payload.WriteTo(Doc);

        Item.FindFirst();
        ItemReference.Init();
        ItemReference."Item No." := Item."No.";
        ItemReference."Reference No." := Item."No.";
        ItemReference."Reference Type" := ItemReference."Reference Type"::Vendor;
        ItemReference."Reference Type No." := VendorNo;
        ItemReference."Unit of Measure" := Item."Base Unit of Measure";
        if ItemReference.Insert() then;

        Http.GetHttpResponseMessage().Content.WriteFrom(Doc.Replace('ItemNo', Item."No.").Replace('GBVendorVatNo', 'GB777777771').Replace('VendorNo', VendorNo).Replace('UomCode', Item."Base Unit of Measure"));
    end;

    local procedure MockSmp()
    begin
        Error('Not implemented');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ForNAV Peppol Setup", OnBeforeSend, '', false, false)]
    local procedure OnBeforeSend(var HttpClient: HttpClient; Http: Codeunit "Http Message State"; var Handled: Boolean)
    var
        Uri: Codeunit Uri;
        Segments, Parameters : List of [Text];
        Method: Text;
    begin
        Handled := true;
        Uri.Init(Http.GetHttpRequestMessage().GetRequestUri());
        Uri.GetSegments(Segments);
        Method := Segments.Get(Segments.Count);
        Parameters := Uri.GetQuery().TrimEnd('?').Split('@');
        case Method of
            'SMP':
                MockSmp();
            'Outgoing':
                MockOutgoing(Http);
            'Inbox':
                MockInbox(Http);
            else
                Error('Unknown http method %1', Method);
        end;
        if StatusCode = 500 then;
    end;

    internal procedure Init()
    var
        Setup: Record "ForNAV Peppol Setup";
    begin
        if InitCalled and Setup.FindFirst() then
            exit;

        Setup.InitSetup();
        Setup.Status := Setup.Status::Published;
        Setup.Authorized := true;
        Setup.Test := true;
        Setup."Identification Code" := '0000';
        Setup."Identification Value" := 'TEST';
        Setup.Modify();
        UnbindSubscription(PeppolSetup);
        if not BindSubscription(PeppolSetup) then
            Error('Failed to bind subscription');
        InitCalled := true;
    end;

    procedure CreateMockServiceDocumentId()
    begin
        MockGuid := CreateGuid();
    end;

    procedure MockServiceDocumentId(): Text
    begin
        exit('FORNAVMOCKID' + Format(MockGuid));
    end;

    procedure SetStatusCode(NewStatusCode: Integer)
    begin
        StatusCode := NewStatusCode;
    end;

    procedure SetVendorNo(NewVendorNo: Code[20])
    begin
        VendorNo := NewVendorNo;
    end;

    procedure CreateEvidence(EDocument: Record "E-Document"; Send: Boolean)
    var
        Incoming: Record "ForNAV Incoming E-Document";
        OutStr: OutStream;
    begin
        if Incoming.Get(EDocument."ForNAV Edoc. ID", Incoming.DocType::Evidence) then begin
            Incoming.Delete();
            Incoming.Init();
        end;

        Incoming.ID := EDocument."ForNAV Edoc. ID";
        Incoming.Status := Send ? Incoming.Status::Send : Incoming.Status::Rejected;
        Incoming.DocNo := EDocument."Document No.";
        Incoming.DocType := Incoming.DocType::Evidence;
        Incoming.DocCode := 0;
        if not Send then begin
            Incoming.Message.CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.WriteText('Rejected');
        end;

        Incoming.Insert(false);
    end;
}
