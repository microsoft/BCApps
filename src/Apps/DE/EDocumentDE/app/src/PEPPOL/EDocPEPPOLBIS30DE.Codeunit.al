namespace Microsoft.eServices.EDocument.IO.Peppol;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
#if not CLEAN29
using Microsoft.Foundation.Company;
#endif
using Microsoft.Peppol.DE;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
#if not CLEAN29
using Microsoft.Sales.Peppol;
#endif
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Utilities;

codeunit 11035 "EDoc PEPPOL BIS 3.0 DE" implements "E-Document"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "Sales Invoice Header" = rm,
        tabledata "Sales Cr.Memo Header" = rm;

    var
        EDocPEPPOLBIS30: Codeunit "EDoc PEPPOL BIS 3.0";
        EDocumentDEHelper: Codeunit "E-Document DE Helper";
        UBLInvoiceNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;
        UBLCrMemoNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2', Locked = true;
        UBLCACNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        UBLCBCNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;

    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        DEContext: Codeunit "PEPPOL30 DE Context";
    begin
        EDocumentDEHelper.CheckBuyerReferenceMandatory(EDocumentService, SourceDocumentHeader);
        // Push whether the Customer GLN/VAT check should be skipped (document carries a routing
        // number / Leitweg-ID) so the DE Sales Validation interface impl can relax the W1 requirement.
        DEContext.Start();
        DEContext.SetSkipCustomerVATRegNoCheck(EDocumentDEHelper.HasRoutingNo(SourceDocumentHeader));
        EDocPEPPOLBIS30.Check(SourceDocumentHeader, EDocumentService, EDocumentProcessingPhase);
        DEContext.Stop();
    end;

    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        DEContext: Codeunit "PEPPOL30 DE Context";
        BuyerReferenceValue: Text;
    begin
        // Resolve the Buyer Reference via the shared DE priority chain (valid Leitweg-ID on the
        // document > Customer E-Invoice Routing No. > document Buyer Reference > Your Reference) and
        // push it to PEPPOL30 DE Context so the DE Document Info Provider returns it for the
        // BuyerReference XML element. The document's Buyer Reference field is maintained separately
        // by "E-Document Header Handler DE".
        BuyerReferenceValue := ResolveBuyerReference(SourceDocumentHeader);
        DEContext.Start();
        DEContext.SetBuyerReference(BuyerReferenceValue);
        DEContext.SetSkipCustomerVATRegNoCheck(EDocumentDEHelper.HasRoutingNo(SourceDocumentHeader));

        EDocPEPPOLBIS30.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        DEContext.Stop();
        RemoveSchemeIDAttributes(EDocument."Document Type", TempBlob);
    end;

    local procedure RemoveSchemeIDAttributes(EDocumentType: Enum "E-Document Type"; var TempBlob: Codeunit "Temp Blob")
    var
        XMLDoc: XmlDocument;
        XmlNSManager: XmlNamespaceManager;
        AttributeNodeList: XmlNodeList;
        XmlNode: XmlNode;
        InStream: InStream;
        OutStream: OutStream;
        DefaultNamespaceUri: Text;
        XmlDocText: Text;
    begin
        if not TempBlob.HasValue() then
            exit;
        TempBlob.CreateInStream(InStream);
        XmlDocument.ReadFrom(InStream, XMLDoc);
        XmlNSManager.NameTable(XMLDoc.NameTable());

        case EDocumentType of
            Enum::"E-Document Type"::"Sales Invoice":
                DefaultNamespaceUri := UBLInvoiceNamespaceTxt;
            Enum::"E-Document Type"::"Sales Credit Memo":
                DefaultNamespaceUri := UBLCrMemoNamespaceTxt;
        end;
        XmlNSManager.AddNamespace('', DefaultNamespaceUri);
        XmlNSManager.AddNamespace('cac', UBLCACNamespaceTxt);
        XmlNSManager.AddNamespace('cbc', UBLCBCNamespaceTxt);

        // find all elements with the attribute "schemeID"
        XMLDoc.SelectNodes('//*[@*[local-name()=''schemeID'']]', XmlNSManager, AttributeNodeList);

        if AttributeNodeList.Count() = 0 then
            exit;

        // remove the "schemeID" attribute from each found element, except EndpointID (BR-62, BR-63 require schemeID)
        foreach XmlNode in AttributeNodeList do
            if XmlNode.AsXmlElement().LocalName() <> 'EndpointID' then
                XmlNode.AsXmlElement().RemoveAttribute('schemeID');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XMLDoc.WriteTo(XMLDocText);
        OutStream.WriteText(XMLDocText);
    end;

    procedure CreateBatch(EDocService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: codeunit "Temp Blob");
    begin
    end;

    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
        EDocPEPPOLBIS30.GetBasicInfoFromReceivedDocument(EDocument, TempBlob);
    end;

    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        PurchaseHeader: Record "Purchase Header";
        BuyerReferenceFieldRef: FieldRef;
        BuyerReferenceValue: Text;
    begin
        EDocPEPPOLBIS30.GetCompleteInfoFromReceivedDocument(EDocument, CreatedDocumentHeader, CreatedDocumentLines, TempBlob);

        // extract BuyerReference from the XML
        BuyerReferenceValue := GetBuyerReferenceFromXml(EDocument."Document Type", TempBlob);
        if BuyerReferenceValue <> '' then begin
            BuyerReferenceFieldRef := CreatedDocumentHeader.Field(PurchaseHeader.FieldNo("Your Reference"));
            BuyerReferenceFieldRef.Validate(BuyerReferenceValue);
            CreatedDocumentHeader.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document Service", 'OnAfterValidateEvent', 'Document Format', false, false)]
    local procedure OnAfterValidateDocumentFormat(var Rec: Record "E-Document Service"; var xRec: Record "E-Document Service"; CurrFieldNo: Integer)
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        if Rec."Document Format" <> Enum::"E-Document Format"::"PEPPOL BIS 3.0 DE" then
            exit;

        EDocServiceSupportedType.SetRange("E-Document Service Code", Rec.Code);
        if not EDocServiceSupportedType.IsEmpty() then
            exit;

        EDocServiceSupportedType.Init();
        EDocServiceSupportedType."E-Document Service Code" := Rec.Code;
        EDocServiceSupportedType."Source Document Type" := Enum::"E-Document Type"::"Sales Invoice";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := Enum::"E-Document Type"::"Sales Credit Memo";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := Enum::"E-Document Type"::"Service Invoice";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := Enum::"E-Document Type"::"Service Credit Memo";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := Enum::"E-Document Type"::"Service Order";
        EDocServiceSupportedType.Insert();
    end;

    local procedure ResolveBuyerReference(SourceDocumentHeader: RecordRef): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BuyerReferenceFieldRef: FieldRef;
        CustomerNoFieldRef: FieldRef;
        YourReferenceFieldRef: FieldRef;
        BuyerReference: Text[100];
        BillToCustomerNo: Code[20];
        YourReference: Text[35];
    begin
        if not (SourceDocumentHeader.Number() in
            [Database::"Sales Header",
            Database::"Sales Invoice Header",
            Database::"Sales Cr.Memo Header",
            Database::"Service Header",
            Database::"Service Invoice Header",
            Database::"Service Cr.Memo Header"])
        then
            exit('');

        BuyerReferenceFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Buyer Reference"));
        CustomerNoFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Bill-to Customer No."));
        YourReferenceFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Your Reference"));
        BuyerReference := BuyerReferenceFieldRef.Value();
        BillToCustomerNo := CustomerNoFieldRef.Value();
        YourReference := YourReferenceFieldRef.Value();
        exit(EDocumentDEHelper.GetBuyerReferenceValue(BuyerReference, BillToCustomerNo, YourReference));
    end;

    local procedure GetBuyerReferenceFromXml(EDocumentType: Enum "E-Document Type"; var TempBlob: Codeunit "Temp Blob") BuyerReference: Text
    var
        XMLDoc: XmlDocument;
        XmlNSManager: XmlNamespaceManager;
        BuyerReferenceNode: XmlNode;
        InStream: InStream;
        DefaultNamespaceUri: Text;
    begin
        TempBlob.CreateInStream(InStream);
        XmlDocument.ReadFrom(InStream, XMLDoc);
        XmlNSManager.NameTable(XMLDoc.NameTable());

        case EDocumentType of
            Enum::"E-Document Type"::"Sales Invoice":
                DefaultNamespaceUri := UBLInvoiceNamespaceTxt;
            Enum::"E-Document Type"::"Sales Credit Memo":
                DefaultNamespaceUri := UBLCrMemoNamespaceTxt;
        end;
        XmlNSManager.AddNamespace('', DefaultNamespaceUri);
        XmlNSManager.AddNamespace('cac', UBLCACNamespaceTxt);
        XmlNSManager.AddNamespace('cbc', UBLCBCNamespaceTxt);

        if XMLDoc.SelectSingleNode('//cbc:BuyerReference', XmlNSManager, BuyerReferenceNode) then
            BuyerReference := BuyerReferenceNode.AsXmlElement().InnerText()
        else
            BuyerReference := '';
    end;

#if not CLEAN29
#pragma warning disable AA0228
    [Obsolete('Buyer Reference is resolved automatically via priority chain: Document field > Customer E-Invoice Routing No. > Your Reference.', '29.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCheckBuyerReferenceOnElseCase(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service")
    begin
    end;
#pragma warning restore AA0228

    local procedure SetSellerContactFromCompanyInformation(var ContactName: Text; var PhoneNumber: Text; var EmailAddress: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.SetLoadFields("Contact Person", "Phone No.", "E-Mail");
        CompanyInformation.Get();
        ContactName := CompanyInformation."Contact Person";
        PhoneNumber := CompanyInformation."Phone No.";
        EmailAddress := CompanyInformation."E-Mail";
    end;

#pragma warning disable AL0432
    [Obsolete('Replaced by "PEPPOL30 DE Doc Info".GetBuyerReference - the DE Document Info Provider returns the buyer-reference value pushed to "PEPPOL30 DE Context" by Create above.', '29.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Management", 'OnAfterGetBuyerReference', '', false, false)]
    local procedure SetReferenceOnAfterGetBuyerReference(SalesHeader: Record "Sales Header"; var BuyerReference: Text)
    begin
        BuyerReference := SalesHeader."Buyer Reference";
    end;

    [Obsolete('Replaced by "PEPPOL30 DE Party Info".GetAccountingSupplierPartyContact - the DE Party Info Provider falls back to Company Information when no salesperson is assigned.', '29.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Management", 'OnAfterGetAccountingSupplierPartyContact', '', false, false)]
    local procedure SetContactInfoOnAfterGetAccountingSupplierPartyContact(SalesHeader: Record "Sales Header"; var ContactID: Text; var ContactName: Text; var Telephone: Text; var Telefax: Text; var ElectronicMail: Text)
    begin
        if SalesHeader."Salesperson Code" = '' then
            SetSellerContactFromCompanyInformation(ContactName, Telephone, ElectronicMail);
    end;
#pragma warning restore AL0432
#endif
}