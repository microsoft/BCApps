// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 13913 "E-Document OIOUBL Handler" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GLNTok: Label 'GLN', Locked = true;
        DKCVRTok: Label 'DK:CVR', Locked = true;
        InvoiceLineTok: Label 'cac:InvoiceLine', Locked = true;
        CreditNoteLineTok: Label 'cac:CreditNoteLine', Locked = true;
        CommonAggregateComponentsTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        CommonBasicComponentsTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        DefaultInvoiceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;
        DefaultCreditNoteTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2', Locked = true;
        UnsupportedXmlRootElementErr: Label 'Unsupported XML root element: %1.', Comment = '%1 = local name of the XML root element';

    /// <summary>
    /// Reads an OIOUBL format XML document and converts it into a draft purchase document.
    /// This procedure processes Invoice and CreditNote document types and populates the E-Document Purchase Header with the extracted data.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document metadata and information.</param>
    /// <param name="TempBlob">A temporary blob containing the XML document stream to be processed.</param>
    /// <returns>Returns an enum indicating that the process resulted in a purchase document draft.</returns>
    internal procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        OIOUBLXml: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        XmlElement: XmlElement;
        ProcessDraft: Enum "E-Doc. Process Draft";
    begin
        ResetDraft(EDocument);
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);

        XmlDocument.ReadFrom(TempBlob.CreateInStream(TextEncoding::UTF8), OIOUBLXml);

        XmlNamespaces.AddNamespace('cac', CommonAggregateComponentsTok);
        XmlNamespaces.AddNamespace('cbc', CommonBasicComponentsTok);
        XmlNamespaces.AddNamespace('inv', DefaultInvoiceTok);
        XmlNamespaces.AddNamespace('cn', DefaultCreditNoteTok);

        OIOUBLXml.GetRoot(XmlElement);
        case XmlElement.LocalName() of
            'Invoice': begin
                if XmlElement.NamespaceUri() <> DefaultInvoiceTok then
                    Error(UnsupportedXmlRootElementErr, XmlElement.LocalName());
                PopulateEDocumentForInvoice(OIOUBLXml, XmlNamespaces, EDocumentPurchaseHeader, EDocument);
                ProcessDraft := Enum::"E-Doc. Process Draft"::"Purchase Invoice";
            end;
            'CreditNote': begin
                if XmlElement.NamespaceUri() <> DefaultCreditNoteTok then
                    Error(UnsupportedXmlRootElementErr, XmlElement.LocalName());
                PopulateEDocumentForCreditNote(OIOUBLXml, XmlNamespaces, EDocumentPurchaseHeader, EDocument);
                ProcessDraft := Enum::"E-Doc. Process Draft"::"Purchase Credit Memo";
            end;
            else
                Error(UnsupportedXmlRootElementErr, XmlElement.LocalName());
        end;

        EDocumentPurchaseHeader.Modify(false);
        EDocument.Direction := EDocument.Direction::Incoming;
        exit(ProcessDraft);
    end;

    /// <summary>
    /// Displays a readable view of the processed E-Document purchase information.
    /// This procedure opens a page showing the purchase header and lines in a user-friendly format for review.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document to be displayed.</param>
    /// <param name="TempBlob">A temporary blob containing the document data (not used in current implementation).</param>
    internal procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    var
        EDocPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary;
        EDocReadablePurchaseDoc: Page "E-Doc. Readable Purchase Doc.";
    begin
        EDocPurchaseHeader.GetFromEDocument(EDocument);
        TempEDocPurchaseHeader := EDocPurchaseHeader;
        TempEDocPurchaseHeader.Insert();

        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocPurchaseHeader."E-Document Entry No.");
        if EDocPurchaseLine.FindSet() then
            repeat
                TempEDocPurchaseLine := EDocPurchaseLine;
                TempEDocPurchaseLine.Insert();
            until EDocPurchaseLine.Next() = 0;

        EDocReadablePurchaseDoc.SetBuffer(TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocReadablePurchaseDoc.Run();
    end;

    local procedure PopulateEDocumentForInvoice(OIOUBLXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var EDocument: Record "E-Document")
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        VendorNo: Code[20];
    begin
#pragma warning disable AA0139
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, '/inv:Invoice/cbc:ID', MaxStrLen(EDocumentPurchaseHeader."Sales Invoice No."), EDocumentPurchaseHeader."Sales Invoice No.");
        EDocumentXMLHelper.SetDateValueInField(OIOUBLXml, XmlNamespaces, '/inv:Invoice/cbc:IssueDate', EDocumentPurchaseHeader."Document Date");
        EDocumentXMLHelper.SetDateValueInField(OIOUBLXml, XmlNamespaces, '/inv:Invoice/cbc:DueDate', EDocumentPurchaseHeader."Due Date");
        if EDocumentPurchaseHeader."Due Date" = 0D then
            EDocumentXMLHelper.SetDateValueInField(OIOUBLXml, XmlNamespaces, '/inv:Invoice/cac:PaymentMeans/cbc:PaymentDueDate', EDocumentPurchaseHeader."Due Date");
        EDocumentXMLHelper.SetCurrencyValueInField(OIOUBLXml, XmlNamespaces, '/inv:Invoice/cbc:DocumentCurrencyCode', MaxStrLen(EDocumentPurchaseHeader."Currency Code"), EDocumentPurchaseHeader."Currency Code");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, '/inv:Invoice/cac:OrderReference/cbc:ID', MaxStrLen(EDocumentPurchaseHeader."Purchase Order No."), EDocumentPurchaseHeader."Purchase Order No.");
#pragma warning restore AA0139
        EDocumentXMLHelper.SetNumberValueInField(OIOUBLXml, XmlNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', EDocumentPurchaseHeader."Sub Total");
        EDocumentXMLHelper.SetNumberValueInField(OIOUBLXml, XmlNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount', EDocumentPurchaseHeader.Total);
        EDocumentXMLHelper.SetNumberValueInField(OIOUBLXml, XmlNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:PayableAmount', EDocumentPurchaseHeader."Amount Due");
        EDocumentPurchaseHeader."Total VAT" := EDocumentPurchaseHeader."Total" - EDocumentPurchaseHeader."Sub Total" - EDocumentPurchaseHeader."Total Discount";
        VendorNo := ParseAccountingSupplierParty(OIOUBLXml, XmlNamespaces, EDocumentPurchaseHeader, EDocument, 'inv:Invoice');
        ParseAccountingCustomerParty(OIOUBLXml, XmlNamespaces, EDocumentPurchaseHeader, 'inv:Invoice');
        if VendorNo <> '' then
            EDocumentPurchaseHeader."[BC] Vendor No." := VendorNo;
        InsertOIOUBLPurchaseLines(OIOUBLXml, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", "E-Document Type"::"Purchase Invoice");
    end;

    local procedure PopulateEDocumentForCreditNote(OIOUBLXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var EDocument: Record "E-Document")
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        VendorNo: Code[20];
    begin
#pragma warning disable AA0139
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, '/cn:CreditNote/cbc:ID', MaxStrLen(EDocumentPurchaseHeader."Sales Invoice No."), EDocumentPurchaseHeader."Sales Invoice No.");
        EDocumentXMLHelper.SetDateValueInField(OIOUBLXml, XmlNamespaces, '/cn:CreditNote/cbc:IssueDate', EDocumentPurchaseHeader."Document Date");
        EDocumentXMLHelper.SetDateValueInField(OIOUBLXml, XmlNamespaces, '/cn:CreditNote/cac:PaymentMeans/cbc:PaymentDueDate', EDocumentPurchaseHeader."Due Date");
        EDocumentXMLHelper.SetCurrencyValueInField(OIOUBLXml, XmlNamespaces, '/cn:CreditNote/cbc:DocumentCurrencyCode', MaxStrLen(EDocumentPurchaseHeader."Currency Code"), EDocumentPurchaseHeader."Currency Code");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, '/cn:CreditNote/cac:OrderReference/cbc:ID', MaxStrLen(EDocumentPurchaseHeader."Purchase Order No."), EDocumentPurchaseHeader."Purchase Order No.");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, '/cn:CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID', MaxStrLen(EDocumentPurchaseHeader."Applies-to Ext. Invoice No."), EDocumentPurchaseHeader."Applies-to Ext. Invoice No.");
#pragma warning restore AA0139
        EDocumentXMLHelper.SetNumberValueInField(OIOUBLXml, XmlNamespaces, '/cn:CreditNote/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', EDocumentPurchaseHeader."Sub Total");
        EDocumentXMLHelper.SetNumberValueInField(OIOUBLXml, XmlNamespaces, '/cn:CreditNote/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount', EDocumentPurchaseHeader.Total);
        EDocumentXMLHelper.SetNumberValueInField(OIOUBLXml, XmlNamespaces, '/cn:CreditNote/cac:LegalMonetaryTotal/cbc:PayableAmount', EDocumentPurchaseHeader."Amount Due");
        EDocumentPurchaseHeader."Total VAT" := EDocumentPurchaseHeader."Total" - EDocumentPurchaseHeader."Sub Total" - EDocumentPurchaseHeader."Total Discount";
        VendorNo := ParseAccountingSupplierParty(OIOUBLXml, XmlNamespaces, EDocumentPurchaseHeader, EDocument, 'cn:CreditNote');
        ParseAccountingCustomerParty(OIOUBLXml, XmlNamespaces, EDocumentPurchaseHeader, 'cn:CreditNote');
        if VendorNo <> '' then
            EDocumentPurchaseHeader."[BC] Vendor No." := VendorNo;
        InsertOIOUBLPurchaseLines(OIOUBLXml, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", "E-Document Type"::"Purchase Credit Memo");
    end;

    local procedure ParseAccountingSupplierParty(OIOUBLXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var EDocument: Record "E-Document"; DocumentType: Text) VendorNo: Code[20]
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        VendorName, VendorAddress, VendorParticipantId : Text;
        VATRegistrationNo: Text[20];
        EndpointID, SchemeID : Text;
        GLN: Code[13];
        BasePathTxt: Text;
        XMLNode: XmlNode;
    begin
#pragma warning disable AA0139 // false positive: overflow handled by SetStringValueInField
        BasePathTxt := '/' + DocumentType + '/cac:AccountingSupplierParty/cac:Party';
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:PartyName/cbc:Name', MaxStrLen(EDocumentPurchaseHeader."Vendor Company Name"), EDocumentPurchaseHeader."Vendor Company Name");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:PostalAddress/cbc:StreetName', MaxStrLen(EDocumentPurchaseHeader."Vendor Address"), EDocumentPurchaseHeader."Vendor Address");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:PostalAddress/cbc:AdditionalStreetName', MaxStrLen(EDocumentPurchaseHeader."Vendor Address Recipient"), EDocumentPurchaseHeader."Vendor Address Recipient");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:PartyTaxScheme/cbc:CompanyID', MaxStrLen(EDocumentPurchaseHeader."Vendor VAT Id"), EDocumentPurchaseHeader."Vendor VAT Id");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:Contact/cbc:Name', MaxStrLen(EDocumentPurchaseHeader."Vendor Contact Name"), EDocumentPurchaseHeader."Vendor Contact Name");
#pragma warning restore AA0139
        if OIOUBLXml.SelectSingleNode(BasePathTxt + '/cbc:EndpointID/@schemeID', XmlNamespaces, XMLNode) then begin
            SchemeID := XMLNode.AsXmlAttribute().Value();
            EndpointID := EDocumentXMLHelper.GetNodeValue(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cbc:EndpointID');
            case SchemeID of
                DKCVRTok:
                    VATRegistrationNo := CopyStr(EndpointID, 1, MaxStrLen(VATRegistrationNo));
                GLNTok:
                    begin
                        GLN := CopyStr(EndpointID, 1, MaxStrLen(GLN));
                        EDocumentPurchaseHeader."Vendor GLN" := GLN;
                    end;
            end;
            VendorParticipantId := SchemeID + ':' + EndpointID;
        end;
        if EDocumentPurchaseHeader."Vendor VAT Id" <> '' then
            VATRegistrationNo := CopyStr(EDocumentPurchaseHeader."Vendor VAT Id", 1, MaxStrLen(VATRegistrationNo));
        if VATRegistrationNo = '' then
            EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:PartyIdentification/cbc:ID', MaxStrLen(VATRegistrationNo), VATRegistrationNo);
        VendorName := EDocumentPurchaseHeader."Vendor Company Name";
        VendorAddress := EDocumentPurchaseHeader."Vendor Address";
        if not FindVendorByVATRegNoOrGLN(VendorNo, VATRegistrationNo, GLN) then
            if not FindVendorByParticipantId(VendorNo, EDocument, VendorParticipantId) then
                VendorNo := EDocumentImportHelper.FindVendorByNameAndAddress(VendorName, VendorAddress);
    end;

    local procedure ParseAccountingCustomerParty(OIOUBLXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; DocumentType: Text)
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        BasePathTxt: Text;
        XMLNode: XmlNode;
        SchemeID, EndpointID : Text;
    begin
#pragma warning disable AA0139 // false positive: overflow handled by SetStringValueInField
        BasePathTxt := '/' + DocumentType + '/cac:AccountingCustomerParty/cac:Party';
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:PartyName/cbc:Name', MaxStrLen(EDocumentPurchaseHeader."Customer Company Name"), EDocumentPurchaseHeader."Customer Company Name");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:PostalAddress/cbc:StreetName', MaxStrLen(EDocumentPurchaseHeader."Customer Address"), EDocumentPurchaseHeader."Customer Address");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:PostalAddress/cbc:AdditionalStreetName', MaxStrLen(EDocumentPurchaseHeader."Customer Address Recipient"), EDocumentPurchaseHeader."Customer Address Recipient");
        EDocumentXMLHelper.SetStringValueInField(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cac:PartyTaxScheme/cbc:CompanyID', MaxStrLen(EDocumentPurchaseHeader."Customer VAT Id"), EDocumentPurchaseHeader."Customer VAT Id");
#pragma warning restore AA0139
        if OIOUBLXml.SelectSingleNode(BasePathTxt + '/cbc:EndpointID/@schemeID', XmlNamespaces, XMLNode) then begin
            SchemeID := XMLNode.AsXmlAttribute().Value();
            EndpointID := EDocumentXMLHelper.GetNodeValue(OIOUBLXml, XmlNamespaces, BasePathTxt + '/cbc:EndpointID');
            if SchemeID = GLNTok then
                EDocumentPurchaseHeader."Customer GLN" := CopyStr(EndpointID, 1, MaxStrLen(EDocumentPurchaseHeader."Customer GLN"));
        end;
    end;

    local procedure InsertOIOUBLPurchaseLines(OIOUBLXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; EDocumentEntryNo: Integer; DocumentType: Enum "E-Document Type")
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        NewLineXML: XmlDocument;
        LineXMLList: XmlNodeList;
        LineXMLNode: XmlNode;
        LineXPath: Text;
        LineElementName: Text;
    begin
        case DocumentType of
            "E-Document Type"::"Purchase Invoice":
                begin
                    LineXPath := '/inv:Invoice/cac:InvoiceLine';
                    LineElementName := InvoiceLineTok;
                end;
            "E-Document Type"::"Purchase Credit Memo":
                begin
                    LineXPath := '/cn:CreditNote/cac:CreditNoteLine';
                    LineElementName := CreditNoteLineTok;
                end;
        end;

        if not OIOUBLXml.SelectNodes(LineXPath, XmlNamespaces, LineXMLList) then
            exit;

        foreach LineXMLNode in LineXMLList do begin
            Clear(EDocumentPurchaseLine);
            EDocumentPurchaseLine.Validate("E-Document Entry No.", EDocumentEntryNo);
            EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocumentEntryNo);
            NewLineXML.ReplaceNodes(LineXMLNode);

            PopulateOIOUBLPurchaseLine(NewLineXML, XmlNamespaces, EDocumentPurchaseLine, LineElementName);
            EDocumentPurchaseLine.Insert(false);
        end;
    end;

    local procedure PopulateOIOUBLPurchaseLine(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var EDocumentPurchaseLine: Record "E-Document Purchase Line"; LineElementName: Text)
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        LineIdFieldName: Text;
        QuantityFieldName: Text;
    begin
#pragma warning disable AA0139 // false positive: overflow handled by SetStringValueInField
        case LineElementName of
            InvoiceLineTok:
                begin
                    LineIdFieldName := 'cac:InvoiceLine/cac:Item/cac:SellersItemIdentification/cbc:ID';
                    QuantityFieldName := 'cac:InvoiceLine/cbc:InvoicedQuantity';
                end;
            CreditNoteLineTok:
                begin
                    LineIdFieldName := 'cac:CreditNoteLine/cac:Item/cac:SellersItemIdentification/cbc:ID';
                    QuantityFieldName := 'cac:CreditNoteLine/cbc:CreditedQuantity';
                end;
        end;

        EDocumentXMLHelper.SetStringValueInField(LineXML, XmlNamespaces, LineIdFieldName, MaxStrLen(EDocumentPurchaseLine."Product Code"), EDocumentPurchaseLine."Product Code");
        EDocumentXMLHelper.SetStringValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cbc:Name', MaxStrLen(EDocumentPurchaseLine.Description), EDocumentPurchaseLine.Description);
        EDocumentXMLHelper.SetStringValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:SellersItemIdentification/cbc:ID', MaxStrLen(EDocumentPurchaseLine."Product Code"), EDocumentPurchaseLine."Product Code");
        EDocumentXMLHelper.SetStringValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:StandardItemIdentification/cbc:ID', MaxStrLen(EDocumentPurchaseLine."Product Code"), EDocumentPurchaseLine."Product Code");
        EDocumentXMLHelper.SetNumberValueInField(LineXML, XmlNamespaces, QuantityFieldName, EDocumentPurchaseLine.Quantity);
        EDocumentXMLHelper.SetStringValueInField(LineXML, XmlNamespaces, QuantityFieldName + '/@unitCode', MaxStrLen(EDocumentPurchaseLine."Unit of Measure"), EDocumentPurchaseLine."Unit of Measure");
        EDocumentXMLHelper.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Price/cbc:PriceAmount', EDocumentPurchaseLine."Unit Price");
        EDocumentXMLHelper.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount', EDocumentPurchaseLine."Sub Total");
        EDocumentXMLHelper.SetCurrencyValueInField(LineXML, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount/@currencyID', MaxStrLen(EDocumentPurchaseLine."Currency Code"), EDocumentPurchaseLine."Currency Code");
        EDocumentXMLHelper.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent', EDocumentPurchaseLine."VAT Rate");
#pragma warning restore AA0139
    end;

    local procedure FindVendorByVATRegNoOrGLN(var VendorNo: Code[20]; VATRegistrationNo: Text[20]; GLN: Code[13]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if VATRegistrationNo <> '' then begin
            Vendor.Reset();
            Vendor.SetLoadFields("VAT Registration No.");
            Vendor.SetRange("VAT Registration No.", VATRegistrationNo);
            if Vendor.FindFirst() then begin
                VendorNo := Vendor."No.";
                exit(true);
            end;
        end;

        // Try to find vendor by GLN
        if GLN <> '' then begin
            Vendor.Reset();
            Vendor.SetLoadFields("GLN");
            Vendor.SetRange("GLN", GLN);
            if Vendor.FindFirst() then begin
                VendorNo := Vendor."No.";
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure FindVendorByParticipantId(var VendorNo: Code[20]; EDocument: Record "E-Document"; ParticipantId: Text): Boolean
    var
        EDocServiceParticipant: Record "Service Participant";
        EDocumentService: Record "E-Document Service";
        EDocumentHelper: Codeunit "E-Document Helper";
    begin
        if ParticipantId = '' then
            exit(false);

        EDocumentHelper.GetEdocumentService(EDocument, EDocumentService);
        EDocServiceParticipant.SetRange("Participant Type", EDocServiceParticipant."Participant Type"::Vendor);
        EDocServiceParticipant.SetRange("Participant Identifier", ParticipantId);
        EDocServiceParticipant.SetRange(Service, EDocumentService.Code);
        if not EDocServiceParticipant.FindFirst() then begin
            EDocServiceParticipant.SetRange(Service);
            if not EDocServiceParticipant.FindFirst() then
                exit(false);
        end;

        VendorNo := EDocServiceParticipant.Participant;
        exit(true);
    end;

    procedure ResetDraft(EDocument: Record "E-Document")
    var
        EDocPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocPurchaseHeader.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseHeader.DeleteAll();
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.DeleteAll();
    end;
}
