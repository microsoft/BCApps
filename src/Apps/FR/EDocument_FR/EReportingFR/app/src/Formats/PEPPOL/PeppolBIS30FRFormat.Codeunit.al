// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.Utilities;

codeunit 10977 "Peppol BIS 3.0 FR Format" implements "E-Document"
{
    Access = Internal;

    var
        ImportPeppol: Codeunit "EDoc Import PEPPOL BIS 3.0";

    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
        PeppolBIS30: Codeunit "EDoc PEPPOL BIS 3.0";
    begin
        FREDocHelpers.CheckSIRENNotEmpty();
        FREDocHelpers.CheckSellerElectronicAddress(EDocumentService.Code);
        FREDocHelpers.CheckSellerCountryCode();
        FREDocHelpers.CheckBuyerElectronicAddress(SourceDocumentHeader, EDocumentService.Code);

        // Delegate standard PEPPOL validation
        PeppolBIS30.Check(SourceDocumentHeader, EDocumentService, EDocumentProcessingPhase);
    end;

    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        PeppolBIS30: Codeunit "EDoc PEPPOL BIS 3.0";
    begin
        // Generate base PEPPOL BIS 3.0 XML
        PeppolBIS30.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        // Post-process XML to inject French-specific elements
        InjectFrenchElements(TempBlob, SourceDocumentHeader, EDocumentService);
    end;

    procedure CreateBatch(EDocService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
        ImportPeppol.ParseBasicInfo(EDocument, TempBlob);
    end;

    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        TempPurchaseHeader: Record "Purchase Header" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        ImportPeppol.ParseCompleteInfo(EDocument, TempPurchaseHeader, TempPurchaseLine, TempBlob);

        CreatedDocumentHeader.GetTable(TempPurchaseHeader);
        CreatedDocumentLines.GetTable(TempPurchaseLine);
    end;

    local procedure InjectFrenchElements(var TempBlob: Codeunit "Temp Blob"; SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service")
    var
        CompanyInformation: Record "Company Information";
        XmlDoc: XmlDocument;
        InStr: InStream;
        OutStr: OutStream;
        NamespaceMgr: XmlNamespaceManager;
        ElecAddress: Text[250];
        ElecAddressScheme: Enum "Electronic Address Scheme";
        HasElecAddress: Boolean;
    begin
        CompanyInformation.Get();

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStr, XmlDoc);

        InitNamespaceManager(NamespaceMgr, XmlDoc);

        InjectSupplierIdentification(XmlDoc, NamespaceMgr, CompanyInformation);
        InjectSupplierEndpoint(XmlDoc, NamespaceMgr, CompanyInformation, EDocumentService.Code);
        InjectRegulatoryComments(XmlDoc, NamespaceMgr, SourceDocumentHeader);
        InjectExtendedCTCFranceElements(XmlDoc, NamespaceMgr, SourceDocumentHeader);

        HasElecAddress := GetCustomerElecAddress(SourceDocumentHeader, EDocumentService.Code, ElecAddress, ElecAddressScheme);
        InjectBuyerEndpoint(XmlDoc, NamespaceMgr, HasElecAddress, ElecAddress, ElecAddressScheme);
        InjectBuyerIdentification(XmlDoc, NamespaceMgr, HasElecAddress, ElecAddress, ElecAddressScheme);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStr);
    end;

    local procedure InjectExtendedCTCFranceElements(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; SourceDocumentHeader: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CustomizationIdNode: XmlNode;
        CustomizationIdElement: XmlElement;
    begin
        if SourceDocumentHeader.Number <> Database::"Sales Invoice Header" then
            exit;

        SourceDocumentHeader.SetTable(SalesInvoiceHeader);
        if not RequiresExtendedCTCFrance(SalesInvoiceHeader."No.") then
            exit;

        if XmlDoc.SelectSingleNode('/*/cbc:CustomizationID', NamespaceMgr, CustomizationIdNode) then begin
            CustomizationIdElement := CustomizationIdNode.AsXmlElement();
            CustomizationIdElement.InnerText := ExtendedCTCFranceCustomizationIdTok;
        end;

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter("Shipment No.", '<>%1', '');
        if SalesInvoiceLine.FindSet() then
            repeat
                InjectExtendedLineReferences(XmlDoc, NamespaceMgr, SalesInvoiceLine);
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure RequiresExtendedCTCFrance(DocumentNo: Code[20]): Boolean
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ShipmentNos: Dictionary of [Text, Boolean];
        OrderNos: Dictionary of [Text, Boolean];
        DeliveryDates: Dictionary of [Text, Boolean];
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        if SalesInvoiceLine.FindSet() then
            repeat
                if SalesInvoiceLine."Shipment No." <> '' then begin
                    AddDistinctValue(ShipmentNos, SalesInvoiceLine."Shipment No.");
                    if SalesShipmentHeader.Get(SalesInvoiceLine."Shipment No.") then
                        AddDistinctValue(DeliveryDates, Format(SalesShipmentHeader."Posting Date", 0, 9));
                end;
                if SalesInvoiceLine."Order No." <> '' then
                    AddDistinctValue(OrderNos, SalesInvoiceLine."Order No.");
            until SalesInvoiceLine.Next() = 0;

        exit((ShipmentNos.Count() > 1) or (OrderNos.Count() > 1) or (DeliveryDates.Count() > 1));
    end;

    local procedure AddDistinctValue(var Values: Dictionary of [Text, Boolean]; Value: Text)
    begin
        if not Values.ContainsKey(Value) then
            Values.Add(Value, true);
    end;

    local procedure InjectExtendedLineReferences(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        InvoiceLineNode: XmlNode;
        ItemNode: XmlNode;
        OrderLineReferenceElement: XmlElement;
        OrderReferenceElement: XmlElement;
        DeliveryElement: XmlElement;
        LineXPath: Text;
    begin
        if not SalesShipmentLine.Get(SalesInvoiceLine."Shipment No.", SalesInvoiceLine."Shipment Line No.") then
            exit;
        if not SalesShipmentHeader.Get(SalesShipmentLine."Document No.") then
            exit;

        LineXPath := StrSubstNo('/*/cac:InvoiceLine[cbc:ID=''%1'']', Format(SalesInvoiceLine."Line No.", 0, 9));
        if not XmlDoc.SelectSingleNode(LineXPath, NamespaceMgr, InvoiceLineNode) then
            exit;
        if not InvoiceLineNode.SelectSingleNode('cac:Item', NamespaceMgr, ItemNode) then
            exit;

        if SalesInvoiceLine."Order No." <> '' then begin
            OrderLineReferenceElement := XmlElement.Create('OrderLineReference', CacNamespaceTok);
            OrderLineReferenceElement.Add(XmlElement.Create('LineID', CbcNamespaceTok, Format(SalesInvoiceLine."Order Line No.", 0, 9)));
            OrderReferenceElement := XmlElement.Create('OrderReference', CacNamespaceTok);
            OrderReferenceElement.Add(XmlElement.Create('ID', CbcNamespaceTok, SalesInvoiceLine."Order No."));
            OrderLineReferenceElement.Add(OrderReferenceElement);
            ItemNode.AddBeforeSelf(OrderLineReferenceElement);
        end;

        DeliveryElement := XmlElement.Create('Delivery', CacNamespaceTok);
        DeliveryElement.Add(XmlElement.Create('ID', CbcNamespaceTok, SalesShipmentLine."Document No."));
        DeliveryElement.Add(XmlElement.Create('ActualDeliveryDate', CbcNamespaceTok, Format(SalesShipmentHeader."Posting Date", 0, 9)));
        ItemNode.AddBeforeSelf(DeliveryElement);
    end;

    local procedure InjectRegulatoryComments(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; SourceDocumentHeader: RecordRef)
    var
        SalesCommentLine: Record "Sales Comment Line";
        AnchorNode: XmlNode;
        NoteElement: XmlElement;
        DocumentNo: Code[20];
        DocumentType: Enum "Sales Comment Document Type";
    begin
        case SourceDocumentHeader.Number of
            Database::"Sales Invoice Header":
                begin
                    DocumentType := DocumentType::"Posted Invoice";
                    DocumentNo := CopyStr(SourceDocumentHeader.Field(3).Value(), 1, MaxStrLen(DocumentNo));
                    if not XmlDoc.SelectSingleNode('/*/cbc:InvoiceTypeCode', NamespaceMgr, AnchorNode) then
                        exit;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    DocumentType := DocumentType::"Posted Credit Memo";
                    DocumentNo := CopyStr(SourceDocumentHeader.Field(3).Value(), 1, MaxStrLen(DocumentNo));
                    if not XmlDoc.SelectSingleNode('/*/cbc:CreditNoteTypeCode', NamespaceMgr, AnchorNode) then
                        exit;
                end;
            else
                exit;
        end;

        SalesCommentLine.SetRange("Document Type", DocumentType);
        SalesCommentLine.SetRange("No.", DocumentNo);
        SalesCommentLine.SetRange("Document Line No.", 0);
        SalesCommentLine.SetFilter("FR Regulatory Comment Type", '<>%1', SalesCommentLine."FR Regulatory Comment Type"::None);
        if SalesCommentLine.FindSet() then
            repeat
                NoteElement := XmlElement.Create('Note', CbcNamespaceTok, SalesCommentLine.Comment);
                AnchorNode.AddAfterSelf(NoteElement);
                AnchorNode := NoteElement.AsXmlNode();
            until SalesCommentLine.Next() = 0;
    end;

    local procedure InitNamespaceManager(var NamespaceMgr: XmlNamespaceManager; XmlDoc: XmlDocument)
    var
        RootElement: XmlElement;
    begin
        XmlDoc.GetRoot(RootElement);
        NamespaceMgr.NameTable(XmlDoc.NameTable());
        NamespaceMgr.AddNamespace('cbc', CbcNamespaceTok);
        NamespaceMgr.AddNamespace('cac', CacNamespaceTok);
    end;

    local procedure InjectSupplierIdentification(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; CompanyInformation: Record "Company Information")
    var
        SupplierPartyNode: XmlNode;
        PartyNode: XmlNode;
        PartyIdElement: XmlElement;
        IdElement: XmlElement;
    begin
        if not XmlDoc.SelectSingleNode('//cac:AccountingSupplierParty/cac:Party', NamespaceMgr, SupplierPartyNode) then
            exit;

        PartyNode := SupplierPartyNode;

        // Add SIRET (BT-29, schemeID=0009)
        if CompanyInformation."SIRET No." <> '' then begin
            PartyIdElement := XmlElement.Create('PartyIdentification', CacNamespaceTok);
            IdElement := XmlElement.Create('ID', CbcNamespaceTok, CompanyInformation."SIRET No.");
            IdElement.SetAttribute('schemeID', '0009');
            PartyIdElement.Add(IdElement);
            InsertPartyIdentification(PartyNode, PartyIdElement, NamespaceMgr);
        end;

        // Add SIREN (BT-30, schemeID=0002) as PartyLegalEntity/CompanyID
        if CompanyInformation."Registration No." <> '' then
            InjectLegalEntitySIREN(PartyNode, NamespaceMgr, CompanyInformation."Registration No.");
    end;

    local procedure InjectLegalEntitySIREN(PartyNode: XmlNode; NamespaceMgr: XmlNamespaceManager; SIRENNo: Text[20])
    var
        LegalEntityNode: XmlNode;
        ExistingCompanyIdNode: XmlNode;
        RegistrationNameNode: XmlNode;
        CompanyIdElement: XmlElement;
        LegalEntityElement: XmlElement;
    begin
        if PartyNode.SelectSingleNode('cac:PartyLegalEntity', NamespaceMgr, LegalEntityNode) then
            LegalEntityElement := LegalEntityNode.AsXmlElement()
        else begin
            LegalEntityElement := XmlElement.Create('PartyLegalEntity', CacNamespaceTok);
            PartyNode.AsXmlElement().Add(LegalEntityElement);
        end;

        CompanyIdElement := XmlElement.Create('CompanyID', CbcNamespaceTok, SIRENNo);
        CompanyIdElement.SetAttribute('schemeID', '0002');

        // Replace existing CompanyID if present
        if LegalEntityElement.AsXmlNode().SelectSingleNode('cbc:CompanyID', NamespaceMgr, ExistingCompanyIdNode) then begin
            ExistingCompanyIdNode.ReplaceWith(CompanyIdElement);
            exit;
        end;

        // Insert after RegistrationName to comply with UBL 2.1 element ordering
        if LegalEntityElement.AsXmlNode().SelectSingleNode('cbc:RegistrationName', NamespaceMgr, RegistrationNameNode) then
            RegistrationNameNode.AddAfterSelf(CompanyIdElement)
        else
            InsertAsFirstChild(LegalEntityElement.AsXmlNode(), CompanyIdElement);
    end;

    local procedure InjectSupplierEndpoint(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; CompanyInformation: Record "Company Information"; EDocumentServiceCode: Code[20])
    var
        SupplierPartyNode: XmlNode;
        ExistingEndpointNode: XmlNode;
        EndpointElement: XmlElement;
        ElecAddress: Text[250];
        ElecAddressScheme: Enum "Electronic Address Scheme";
    begin
        if not XmlDoc.SelectSingleNode('//cac:AccountingSupplierParty/cac:Party', NamespaceMgr, SupplierPartyNode) then
            exit;

        if not GetServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Company, '', ElecAddress, ElecAddressScheme) then
            if CompanyInformation."SIRET No." <> '' then begin
                ElecAddress := CompanyInformation."SIRET No.";
                ElecAddressScheme := ElecAddressScheme::"0009";
            end else begin
                ElecAddress := CompanyInformation.GetVATRegistrationNumber();
                ElecAddressScheme := ElecAddressScheme::"0223";
            end;

        if ElecAddress = '' then
            exit;

        // Remove existing EndpointID if present
        if SupplierPartyNode.SelectSingleNode('cbc:EndpointID', NamespaceMgr, ExistingEndpointNode) then
            ExistingEndpointNode.Remove();

        EndpointElement := XmlElement.Create('EndpointID', CbcNamespaceTok, ElecAddress);
        EndpointElement.SetAttribute('schemeID', GetElecAddressSchemeCode(ElecAddressScheme));
        InsertAsFirstChild(SupplierPartyNode, EndpointElement);
    end;

    local procedure InjectBuyerEndpoint(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; HasElecAddress: Boolean; ElecAddress: Text[250]; ElecAddressScheme: Enum "Electronic Address Scheme")
    var
        BuyerPartyNode: XmlNode;
        ExistingEndpointNode: XmlNode;
        EndpointElement: XmlElement;
    begin
        if not HasElecAddress then
            exit;

        if not XmlDoc.SelectSingleNode('//cac:AccountingCustomerParty/cac:Party', NamespaceMgr, BuyerPartyNode) then
            exit;

        // Remove existing EndpointID if present
        if BuyerPartyNode.SelectSingleNode('cbc:EndpointID', NamespaceMgr, ExistingEndpointNode) then
            ExistingEndpointNode.Remove();

        EndpointElement := XmlElement.Create('EndpointID', CbcNamespaceTok, ElecAddress);
        EndpointElement.SetAttribute('schemeID', GetElecAddressSchemeCode(ElecAddressScheme));
        InsertAsFirstChild(BuyerPartyNode, EndpointElement);
    end;

    local procedure GetCustomerElecAddress(SourceDocumentHeader: RecordRef; EDocumentServiceCode: Code[20]; var ElecAddress: Text[250]; var ElecAddressScheme: Enum "Electronic Address Scheme"): Boolean
    var
        Customer: Record Customer;
        FRCIIXMLBuilder: Codeunit "CII XML Builder";
        CustomerNoFieldRef: FieldRef;
        CustomerNo: Code[20];
    begin
        if not FRCIIXMLBuilder.TryGetCustomerNoFieldRef(SourceDocumentHeader, CustomerNoFieldRef) then
            exit(false);

        CustomerNo := CustomerNoFieldRef.Value();
        if CustomerNo = '' then
            exit(false);

        if GetServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Customer, CustomerNo, ElecAddress, ElecAddressScheme) then
            exit(true);

        Customer.SetLoadFields("FR Electronic Address", "FR Elec. Address Scheme", "VAT Registration No.");
        if not Customer.Get(CustomerNo) then
            exit(false);

        ElecAddress := Customer."FR Electronic Address";
        ElecAddressScheme := Customer."FR Elec. Address Scheme";
        if ElecAddress = '' then begin
            ElecAddress := Customer."VAT Registration No.";
            ElecAddressScheme := ElecAddressScheme::"0223";
        end;
        exit(ElecAddress <> '');
    end;

    local procedure GetServiceParticipantAddress(EDocumentServiceCode: Code[20]; ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20]; var ElecAddress: Text[250]; var ElecAddressScheme: Enum "Electronic Address Scheme"): Boolean
    var
        ServiceParticipant: Record "Service Participant";
    begin
        if not ServiceParticipant.Get(EDocumentServiceCode, ParticipantType, ParticipantNo) then
            exit(false);
        if ServiceParticipant."Participant Identifier" = '' then
            exit(false);

        ElecAddress := CopyStr(ServiceParticipant."Participant Identifier", 1, MaxStrLen(ElecAddress));
        ElecAddressScheme := ServiceParticipant."FR Identifier Scheme";
        exit(true);
    end;

    local procedure InjectBuyerIdentification(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; HasElecAddress: Boolean; ElecAddress: Text[250]; ElecAddressScheme: Enum "Electronic Address Scheme")
    var
        BuyerPartyNode: XmlNode;
        PartyIdElement: XmlElement;
        IdElement: XmlElement;
    begin
        if not HasElecAddress then
            exit;

        if not XmlDoc.SelectSingleNode('//cac:AccountingCustomerParty/cac:Party', NamespaceMgr, BuyerPartyNode) then
            exit;

        // Add buyer SIRET as PartyIdentification (BT-46) when scheme is 0009
        if ElecAddressScheme <> ElecAddressScheme::"0009" then
            exit;

        PartyIdElement := XmlElement.Create('PartyIdentification', CacNamespaceTok);
        IdElement := XmlElement.Create('ID', CbcNamespaceTok, ElecAddress);
        IdElement.SetAttribute('schemeID', '0009');
        PartyIdElement.Add(IdElement);
        InsertPartyIdentification(BuyerPartyNode, PartyIdElement, NamespaceMgr);
    end;

    local procedure GetElecAddressSchemeCode(ElecAddressScheme: Enum "Electronic Address Scheme"): Text
    begin
        case ElecAddressScheme of
            ElecAddressScheme::"EM":
                exit('EM');
            ElecAddressScheme::"0009":
                exit('0009');
            ElecAddressScheme::"0002":
                exit('0002');
            ElecAddressScheme::"0223":
                exit('0223');
            ElecAddressScheme::"0225":
                exit('0225');
            else
                exit(Format(ElecAddressScheme));
        end;
    end;

    local procedure InsertPartyIdentification(PartyNode: XmlNode; PartyIdElement: XmlElement; NamespaceMgr: XmlNamespaceManager)
    var
        PartyNameNode: XmlNode;
    begin
        // UBL 2.1 Party sequence: ...EndpointID, PartyIdentification, PartyName, Language, PostalAddress...
        // Insert before PartyName to maintain correct element order
        if PartyNode.SelectSingleNode('cac:PartyName', NamespaceMgr, PartyNameNode) then
            PartyNameNode.AddBeforeSelf(PartyIdElement)
        else
            InsertAsFirstChild(PartyNode, PartyIdElement);
    end;

    local procedure InsertAsFirstChild(ParentNode: XmlNode; NewElement: XmlElement)
    var
        FirstChild: XmlNode;
    begin
        if ParentNode.AsXmlElement().GetChildElements().Count() > 0 then
            foreach FirstChild in ParentNode.AsXmlElement().GetChildElements() do begin
                FirstChild.AddBeforeSelf(NewElement);
                exit;
            end
        else
            ParentNode.AsXmlElement().Add(NewElement);
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document Service", 'OnAfterValidateEvent', 'Document Format', false, false)]
    local procedure OnAfterValidateDocumentFormat(var Rec: Record "E-Document Service"; var xRec: Record "E-Document Service"; CurrFieldNo: Integer)
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        if Rec."Document Format" <> Rec."Document Format"::"Peppol BIS 3.0 FR" then
            exit;

        EDocServiceSupportedType.SetRange("E-Document Service Code", Rec.Code);
        if not EDocServiceSupportedType.IsEmpty() then
            exit;

        EDocServiceSupportedType.Init();
        EDocServiceSupportedType."E-Document Service Code" := Rec.Code;

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Sales Invoice";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Sales Credit Memo";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Service Invoice";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Service Credit Memo";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Issued Reminder";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Issued Finance Charge Memo";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Purchase Invoice";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Purchase Credit Memo";
        EDocServiceSupportedType.Insert();
    end;

    var
        CbcNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        CacNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        ExtendedCTCFranceCustomizationIdTok: Label 'EXTENDED-CTC-FR', Locked = true;
}
