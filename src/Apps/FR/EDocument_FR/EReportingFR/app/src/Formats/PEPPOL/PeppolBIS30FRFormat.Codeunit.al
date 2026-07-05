// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
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
        FREDocHelpers.CheckSIRETNotEmpty();
        FREDocHelpers.CheckSellerCountryCode();
        FREDocHelpers.CheckBuyerElectronicAddress(SourceDocumentHeader);

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
        InjectFrenchElements(TempBlob, SourceDocumentHeader);
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

    local procedure InjectFrenchElements(var TempBlob: Codeunit "Temp Blob"; SourceDocumentHeader: RecordRef)
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
        InjectSupplierEndpoint(XmlDoc, NamespaceMgr, CompanyInformation);

        HasElecAddress := GetCustomerElecAddress(SourceDocumentHeader, ElecAddress, ElecAddressScheme);
        InjectBuyerEndpoint(XmlDoc, NamespaceMgr, HasElecAddress, ElecAddress, ElecAddressScheme);
        InjectBuyerIdentification(XmlDoc, NamespaceMgr, HasElecAddress, ElecAddress, ElecAddressScheme);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStr);
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

    local procedure InjectSupplierEndpoint(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; CompanyInformation: Record "Company Information")
    var
        SupplierPartyNode: XmlNode;
        ExistingEndpointNode: XmlNode;
        EndpointElement: XmlElement;
    begin
        if not XmlDoc.SelectSingleNode('//cac:AccountingSupplierParty/cac:Party', NamespaceMgr, SupplierPartyNode) then
            exit;

        // Use SIRET as endpoint with scheme 0009
        if CompanyInformation."SIRET No." = '' then
            exit;

        // Remove existing EndpointID if present
        if SupplierPartyNode.SelectSingleNode('cbc:EndpointID', NamespaceMgr, ExistingEndpointNode) then
            ExistingEndpointNode.Remove();

        EndpointElement := XmlElement.Create('EndpointID', CbcNamespaceTok, CompanyInformation."SIRET No.");
        EndpointElement.SetAttribute('schemeID', '0009');
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

    local procedure GetCustomerElecAddress(SourceDocumentHeader: RecordRef; var ElecAddress: Text[250]; var ElecAddressScheme: Enum "Electronic Address Scheme"): Boolean
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

        Customer.SetLoadFields("FR Electronic Address", "FR Elec. Address Scheme");
        if not Customer.Get(CustomerNo) then
            exit(false);

        ElecAddress := Customer."FR Electronic Address";
        ElecAddressScheme := Customer."FR Elec. Address Scheme";
        exit(ElecAddress <> '');
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
    end;

    var
        CbcNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        CacNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
}
