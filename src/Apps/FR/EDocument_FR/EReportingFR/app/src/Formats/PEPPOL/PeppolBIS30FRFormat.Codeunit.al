// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Company;
using Microsoft.Peppol;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Utilities;

codeunit 10977 "Peppol BIS 3.0 FR Format" implements "E-Document"
{
    var
        ImportPeppol: Codeunit "EDoc Import PEPPOL BIS 3.0";

    /// <summary>
    /// Validates that the source document contains the information required for the Peppol BIS 3.0 FR format.
    /// </summary>
    /// <param name="SourceDocumentHeader">The source document header to validate.</param>
    /// <param name="EDocumentService">The E-Document service used to process the document.</param>
    /// <param name="EDocumentProcessingPhase">The phase in which the E-Document is being processed.</param>
    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        FREDocHelpers: Codeunit "EDoc. Helpers";
        PeppolBIS30: Codeunit "EDoc PEPPOL BIS 3.0";
        SalesValidation: Interface "PEPPOL30 Validation";
        ServiceValidation: Interface "PEPPOL30 Validation";
    begin
        FREDocHelpers.CheckSellerElectronicAddress(EDocumentService.Code);
        FREDocHelpers.CheckSellerCountryCode();
        FREDocHelpers.CheckBuyerElectronicAddress(SourceDocumentHeader, EDocumentService.Code);

        SalesValidation := Enum::"PEPPOL 3.0 Format"::"PEPPOL 3.0 - Sales FR";
        ServiceValidation := Enum::"PEPPOL 3.0 Format"::"PEPPOL 3.0 - Service FR";
        case SourceDocumentHeader.Number of
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    SalesValidation.ValidateDocument(SalesHeader);
                    SalesValidation.ValidateDocumentLines(SalesHeader);
                end;
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(SalesInvoiceHeader);
                    SalesValidation.ValidatePostedDocument(SalesInvoiceHeader);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(SalesCrMemoHeader);
                    SalesValidation.ValidatePostedDocument(SalesCrMemoHeader);
                end;
            Database::"Service Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceHeader);
                    ServiceValidation.ValidateDocument(ServiceHeader);
                    ServiceValidation.ValidateDocumentLines(ServiceHeader);
                end;
            Database::"Service Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceInvoiceHeader);
                    ServiceValidation.ValidatePostedDocument(ServiceInvoiceHeader);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceCrMemoHeader);
                    ServiceValidation.ValidatePostedDocument(ServiceCrMemoHeader);
                end;
            else
                PeppolBIS30.Check(SourceDocumentHeader, EDocumentService, EDocumentProcessingPhase);
        end;
    end;

    /// <summary>
    /// Creates a Peppol BIS 3.0 FR document from a source document.
    /// </summary>
    /// <param name="EDocumentService">The E-Document service used to process the document.</param>
    /// <param name="EDocument">The E-Document record for the document being created.</param>
    /// <param name="SourceDocumentHeader">The source document header.</param>
    /// <param name="SourceDocumentLines">The source document lines.</param>
    /// <param name="TempBlob">The temporary blob in which to store the generated document.</param>
    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        PeppolBIS30: Codeunit "EDoc PEPPOL BIS 3.0";
    begin
        // Generate base PEPPOL BIS 3.0 XML
        PeppolBIS30.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        // Post-process XML to inject French-specific elements
        InjectFrenchElements(TempBlob, SourceDocumentHeader, SourceDocumentLines, EDocumentService);
    end;

    /// <summary>
    /// Creates a Peppol BIS 3.0 FR document for a batch of source documents.
    /// </summary>
    /// <param name="EDocService">The E-Document service used to process the documents.</param>
    /// <param name="EDocument">The E-Document records for the documents being created.</param>
    /// <param name="SourceDocumentHeaders">The source document headers.</param>
    /// <param name="SourceDocumentsLines">The source document lines.</param>
    /// <param name="TempBlob">The temporary blob in which to store the generated document.</param>
    procedure CreateBatch(EDocService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    /// <summary>
    /// Reads basic E-Document information from a received Peppol BIS 3.0 FR document.
    /// </summary>
    /// <param name="EDocument">The E-Document record to populate with basic information.</param>
    /// <param name="TempBlob">The temporary blob that contains the received document.</param>
    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
        ImportPeppol.ParseBasicInfo(EDocument, TempBlob);
    end;

    /// <summary>
    /// Reads complete document information from a received Peppol BIS 3.0 FR document.
    /// </summary>
    /// <param name="EDocument">The E-Document record associated with the received document.</param>
    /// <param name="CreatedDocumentHeader">The document header populated from the received document.</param>
    /// <param name="CreatedDocumentLines">The document lines populated from the received document.</param>
    /// <param name="TempBlob">The temporary blob that contains the received document.</param>
    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        TempPurchaseHeader: Record "Purchase Header" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        ImportPeppol.ParseCompleteInfo(EDocument, TempPurchaseHeader, TempPurchaseLine, TempBlob);

        CreatedDocumentHeader.GetTable(TempPurchaseHeader);
        CreatedDocumentLines.GetTable(TempPurchaseLine);
    end;

    local procedure InjectFrenchElements(var TempBlob: Codeunit "Temp Blob"; SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; EDocumentService: Record "E-Document Service")
    var
        CompanyInformation: Record "Company Information";
        XmlDoc: XmlDocument;
        InStr: InStream;
        OutStr: OutStream;
        NamespaceMgr: XmlNamespaceManager;
        ElecAddress: Text[250];
        ElecAddressScheme: Enum "Electronic Address Scheme";
        HasElecAddress: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeInjectFrenchElements(TempBlob, SourceDocumentHeader, SourceDocumentLines, EDocumentService, IsHandled);
        if IsHandled then
            exit;

        CompanyInformation.Get();

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStr, XmlDoc);

        InitNamespaceManager(NamespaceMgr, XmlDoc);

        SetFrenchBillingMode(XmlDoc, NamespaceMgr, SourceDocumentLines);
        RemoveZeroAllowanceTotal(XmlDoc, NamespaceMgr);
        InjectSupplierIdentification(XmlDoc, NamespaceMgr, CompanyInformation);
        InjectSupplierEndpoint(XmlDoc, NamespaceMgr, CompanyInformation, EDocumentService.Code);
        InjectRegulatoryComments(XmlDoc, NamespaceMgr, SourceDocumentHeader);
        InjectBillingReference(XmlDoc, NamespaceMgr, SourceDocumentHeader);
        InjectExtendedCTCFranceElements(XmlDoc, NamespaceMgr, SourceDocumentHeader);

        HasElecAddress := GetCustomerElecAddress(SourceDocumentHeader, EDocumentService.Code, ElecAddress, ElecAddressScheme);
        InjectBuyerEndpoint(XmlDoc, NamespaceMgr, HasElecAddress, ElecAddress, ElecAddressScheme);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStr);

        OnAfterInjectFrenchElements(TempBlob, SourceDocumentHeader, SourceDocumentLines, EDocumentService);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInjectFrenchElements(var TempBlob: Codeunit "Temp Blob"; SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; EDocumentService: Record "E-Document Service"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInjectFrenchElements(var TempBlob: Codeunit "Temp Blob"; SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; EDocumentService: Record "E-Document Service")
    begin
    end;

    local procedure SetFrenchBillingMode(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; var SourceDocumentLines: RecordRef)
    var
        ProfileIdNode: XmlNode;
        NewProfileIdNode: XmlNode;
    begin
        if not XmlDoc.SelectSingleNode('/*/cbc:ProfileID', NamespaceMgr, ProfileIdNode) then
            exit;
        NewProfileIdNode := XmlElement.Create('ProfileID', CbcNamespaceTok, GetFrenchBillingMode(SourceDocumentLines)).AsXmlNode();
        ProfileIdNode.ReplaceWith(NewProfileIdNode);
    end;

    internal procedure GetFrenchBillingMode(SourceDocumentLines: RecordRef): Text
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        HasItemLines: Boolean;
        HasNonItemLines: Boolean;
    begin
        case SourceDocumentLines.Number of
            Database::"Sales Invoice Line":
                begin
                    SourceDocumentLines.SetTable(SalesInvoiceLine);
                    SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
                    HasItemLines := not SalesInvoiceLine.IsEmpty();
                    SalesInvoiceLine.SetFilter(Type, '<>%1&<>%2', SalesInvoiceLine.Type::" ", SalesInvoiceLine.Type::Item);
                    HasNonItemLines := not SalesInvoiceLine.IsEmpty();
                end;
            Database::"Sales Cr.Memo Line":
                begin
                    SourceDocumentLines.SetTable(SalesCrMemoLine);
                    SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
                    HasItemLines := not SalesCrMemoLine.IsEmpty();
                    SalesCrMemoLine.SetFilter(Type, '<>%1&<>%2', SalesCrMemoLine.Type::" ", SalesCrMemoLine.Type::Item);
                    HasNonItemLines := not SalesCrMemoLine.IsEmpty();
                end;
            Database::"Service Invoice Line":
                begin
                    SourceDocumentLines.SetTable(ServiceInvoiceLine);
                    ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::Item);
                    HasItemLines := not ServiceInvoiceLine.IsEmpty();
                    ServiceInvoiceLine.SetFilter(Type, '<>%1&<>%2', ServiceInvoiceLine.Type::" ", ServiceInvoiceLine.Type::Item);
                    HasNonItemLines := not ServiceInvoiceLine.IsEmpty();
                end;
            Database::"Service Cr.Memo Line":
                begin
                    SourceDocumentLines.SetTable(ServiceCrMemoLine);
                    ServiceCrMemoLine.SetRange(Type, ServiceCrMemoLine.Type::Item);
                    HasItemLines := not ServiceCrMemoLine.IsEmpty();
                    ServiceCrMemoLine.SetFilter(Type, '<>%1&<>%2', ServiceCrMemoLine.Type::" ", ServiceCrMemoLine.Type::Item);
                    HasNonItemLines := not ServiceCrMemoLine.IsEmpty();
                end;
            Database::"Issued Reminder Line",
            Database::"Issued Fin. Charge Memo Line":
                HasNonItemLines := true;
        end;

        if HasItemLines and HasNonItemLines then
            exit(BillingModeM1Tok);
        if HasNonItemLines then
            exit(BillingModeS1Tok);
        exit(BillingModeB1Tok);
    end;

    local procedure RemoveZeroAllowanceTotal(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager)
    var
        ZeroAllowanceTotalNode: XmlNode;
    begin
        if XmlDoc.SelectSingleNode('/*/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount[number(normalize-space(.)) = 0]', NamespaceMgr, ZeroAllowanceTotalNode) then
            ZeroAllowanceTotalNode.Remove();
    end;

    local procedure InjectExtendedCTCFranceElements(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; SourceDocumentHeader: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ShipmentPostingDates: Dictionary of [Code[20], Date];
        CustomizationIdNode: XmlNode;
        NewCustomizationIdNode: XmlNode;
    begin
        if SourceDocumentHeader.Number <> Database::"Sales Invoice Header" then
            exit;

        SourceDocumentHeader.SetTable(SalesInvoiceHeader);
        if not RequiresExtendedCTCFrance(SalesInvoiceHeader."No.", ShipmentPostingDates) then
            exit;

        if XmlDoc.SelectSingleNode('/*/cbc:CustomizationID', NamespaceMgr, CustomizationIdNode) then begin
            NewCustomizationIdNode := XmlElement.Create('CustomizationID', CbcNamespaceTok, ExtendedCTCFranceCustomizationIdTok).AsXmlNode();
            CustomizationIdNode.ReplaceWith(NewCustomizationIdNode);
        end;

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetLoadFields("Line No.", "Order No.", "Order Line No.", "Shipment No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                InjectExtendedLineReferences(XmlDoc, NamespaceMgr, SalesInvoiceLine, ShipmentPostingDates);
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure RequiresExtendedCTCFrance(DocumentNo: Code[20]; var ShipmentPostingDates: Dictionary of [Code[20], Date]): Boolean
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ShipmentNos: Dictionary of [Text, Boolean];
        OrderNos: Dictionary of [Text, Boolean];
        DeliveryDates: Dictionary of [Text, Boolean];
        ShipmentNoFilterBuilder: TextBuilder;
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetLoadFields("Shipment No.", "Order No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                if SalesInvoiceLine."Shipment No." <> '' then
                    if not ShipmentNos.ContainsKey(SalesInvoiceLine."Shipment No.") then begin
                        ShipmentNos.Add(SalesInvoiceLine."Shipment No.", true);
                        AddValueToFilter(ShipmentNoFilterBuilder, SalesInvoiceLine."Shipment No.");
                    end;
                if SalesInvoiceLine."Order No." <> '' then
                    AddDistinctValue(OrderNos, SalesInvoiceLine."Order No.");
            until SalesInvoiceLine.Next() = 0;

        if ShipmentNoFilterBuilder.Length() > 0 then begin
            SalesShipmentHeader.SetFilter("No.", ShipmentNoFilterBuilder.ToText());
            SalesShipmentHeader.SetLoadFields("Posting Date");
            if SalesShipmentHeader.FindSet() then
                repeat
                    ShipmentPostingDates.Add(SalesShipmentHeader."No.", SalesShipmentHeader."Posting Date");
                    AddDistinctValue(DeliveryDates, Format(SalesShipmentHeader."Posting Date", 0, 9));
                until SalesShipmentHeader.Next() = 0;
        end;

        exit((ShipmentNos.Count() > 1) or (OrderNos.Count() > 1) or (DeliveryDates.Count() > 1));
    end;

    local procedure AddValueToFilter(var FilterTextBuilder: TextBuilder; Value: Text)
    begin
        if FilterTextBuilder.Length() > 0 then
            FilterTextBuilder.Append('|');
        FilterTextBuilder.Append('''' + ReplaceString(Value, '''', '''''') + '''');
    end;

    local procedure ReplaceString(Value: Text; FindWhat: Text; ReplaceWith: Text) NewValue: Text
    var
        NewValueBuilder: TextBuilder;
    begin
        while StrPos(Value, FindWhat) > 0 do begin
            NewValueBuilder.Append(DelStr(Value, StrPos(Value, FindWhat)) + ReplaceWith);
            Value := CopyStr(Value, StrPos(Value, FindWhat) + StrLen(FindWhat));
        end;
        NewValueBuilder.Append(Value);
        NewValue := NewValueBuilder.ToText();
    end;

    local procedure AddDistinctValue(var Values: Dictionary of [Text, Boolean]; Value: Text)
    begin
        if not Values.ContainsKey(Value) then
            Values.Add(Value, true);
    end;

    local procedure InjectExtendedLineReferences(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; SalesInvoiceLine: Record "Sales Invoice Line"; ShipmentPostingDates: Dictionary of [Code[20], Date])
    var
        InvoiceLineNode: XmlNode;
        LineContentAnchorNode: XmlNode;
        OrderLineReferenceElement: XmlElement;
        OrderReferenceElement: XmlElement;
        DeliveryElement: XmlElement;
        LineXPath: Text;
        ShipmentPostingDate: Date;
    begin
        LineXPath := StrSubstNo(InvoiceLineXPathTok, Format(SalesInvoiceLine."Line No.", 0, 9));
        if not XmlDoc.SelectSingleNode(LineXPath, NamespaceMgr, InvoiceLineNode) then
            exit;
        if not InvoiceLineNode.SelectSingleNode('cac:AllowanceCharge | cac:TaxTotal | cac:WithholdingTaxTotal | cac:Item', NamespaceMgr, LineContentAnchorNode) then
            exit;

        if SalesInvoiceLine."Order No." <> '' then begin
            OrderLineReferenceElement := XmlElement.Create('OrderLineReference', CacNamespaceTok);
            OrderLineReferenceElement.Add(XmlElement.Create('LineID', CbcNamespaceTok, Format(SalesInvoiceLine."Order Line No.", 0, 9)));
            OrderReferenceElement := XmlElement.Create('OrderReference', CacNamespaceTok);
            OrderReferenceElement.Add(XmlElement.Create('ID', CbcNamespaceTok, SalesInvoiceLine."Order No."));
            OrderLineReferenceElement.Add(OrderReferenceElement);
            LineContentAnchorNode.AddBeforeSelf(OrderLineReferenceElement);
        end;

        if SalesInvoiceLine."Shipment No." = '' then
            exit;

        if not ShipmentPostingDates.Get(SalesInvoiceLine."Shipment No.", ShipmentPostingDate) then
            exit;

        DeliveryElement := XmlElement.Create('Delivery', CacNamespaceTok);
        DeliveryElement.Add(XmlElement.Create('ID', CbcNamespaceTok, SalesInvoiceLine."Shipment No."));
        DeliveryElement.Add(XmlElement.Create('ActualDeliveryDate', CbcNamespaceTok, Format(ShipmentPostingDate, 0, 9)));
        LineContentAnchorNode.AddBeforeSelf(DeliveryElement);
    end;

    local procedure InjectRegulatoryComments(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; SourceDocumentHeader: RecordRef)
    var
        SalesCommentLine: Record "Sales Comment Line";
        AnchorNode: XmlNode;
        DocumentNo: Code[20];
        DocumentType: Enum "Sales Comment Document Type";
        RegulatoryCommentTypeCode: Text;
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
            Database::"Service Invoice Header":
                if not XmlDoc.SelectSingleNode('/*/cbc:InvoiceTypeCode', NamespaceMgr, AnchorNode) then
                    exit;
            Database::"Service Cr.Memo Header":
                if not XmlDoc.SelectSingleNode('/*/cbc:CreditNoteTypeCode', NamespaceMgr, AnchorNode) then
                    exit;
            else
                exit;
        end;

        if DocumentNo <> '' then begin
            SalesCommentLine.SetRange("Document Type", DocumentType);
            SalesCommentLine.SetRange("No.", DocumentNo);
            SalesCommentLine.SetFilter("FR Regulatory Comment Type", '<>%1', SalesCommentLine."FR Regulatory Comment Type"::None);
            SalesCommentLine.SetLoadFields("FR Regulatory Comment Type", Comment);
            if SalesCommentLine.FindSet() then
                repeat
                    RegulatoryCommentTypeCode := GetRegulatoryCommentTypeCode(SalesCommentLine."FR Regulatory Comment Type");
                    AddRegulatoryComment(AnchorNode, RegulatoryCommentTypeCode, SalesCommentLine.Comment);
                until SalesCommentLine.Next() = 0;
        end;
    end;

    local procedure AddRegulatoryComment(var AnchorNode: XmlNode; RegulatoryCommentTypeCode: Text; Comment: Text)
    var
        NoteElement: XmlElement;
    begin
        NoteElement := XmlElement.Create('Note', CbcNamespaceTok, StrSubstNo(RegulatoryCommentFormatTok, RegulatoryCommentTypeCode, Comment));
        AnchorNode.AddAfterSelf(NoteElement);
        AnchorNode := NoteElement.AsXmlNode();
    end;

    local procedure InjectBillingReference(var XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; SourceDocumentHeader: RecordRef)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        AnchorNode: XmlNode;
        BillingReferenceElement: XmlElement;
        InvoiceDocumentReferenceElement: XmlElement;
        ReferencedDocumentNo: Code[20];
        ReferencedDocumentDate: Date;
    begin
        case SourceDocumentHeader.Number of
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(SalesCrMemoHeader);
                    ReferencedDocumentNo := SalesCrMemoHeader."Applies-to Doc. No.";
                    SalesInvoiceHeader.SetLoadFields("Document Date");
                    if SalesInvoiceHeader.Get(ReferencedDocumentNo) then
                        ReferencedDocumentDate := SalesInvoiceHeader."Document Date";
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceCrMemoHeader);
                    ReferencedDocumentNo := ServiceCrMemoHeader."Applies-to Doc. No.";
                    ServiceInvoiceHeader.SetLoadFields("Document Date");
                    if ServiceInvoiceHeader.Get(ReferencedDocumentNo) then
                        ReferencedDocumentDate := ServiceInvoiceHeader."Document Date";
                end;
            else
                exit;
        end;

        if (ReferencedDocumentNo = '') or (ReferencedDocumentDate = 0D) then
            exit;

        BillingReferenceElement := XmlElement.Create('BillingReference', CacNamespaceTok);
        InvoiceDocumentReferenceElement := XmlElement.Create('InvoiceDocumentReference', CacNamespaceTok);
        InvoiceDocumentReferenceElement.Add(XmlElement.Create('ID', CbcNamespaceTok, ReferencedDocumentNo));
        InvoiceDocumentReferenceElement.Add(XmlElement.Create('IssueDate', CbcNamespaceTok, Format(ReferencedDocumentDate, 0, '<Year4>-<Month,2>-<Day,2>')));
        BillingReferenceElement.Add(InvoiceDocumentReferenceElement);

        if XmlDoc.SelectSingleNode('/*/cac:ContractDocumentReference[1]', NamespaceMgr, AnchorNode) then begin
            AnchorNode.AddBeforeSelf(BillingReferenceElement);
            exit;
        end;
        if XmlDoc.SelectSingleNode('/*/cac:AccountingSupplierParty[1]', NamespaceMgr, AnchorNode) then
            AnchorNode.AddBeforeSelf(BillingReferenceElement);
    end;

    local procedure GetRegulatoryCommentTypeCode(RegulatoryCommentType: Enum "FR Regulatory Comment Type"): Text
    begin
        exit(RegulatoryCommentType.Names.Get(RegulatoryCommentType.Ordinals.IndexOf(RegulatoryCommentType.AsInteger())));
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
        SIRENNo: Text;
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

        // Add SIREN (BT-30, schemeID=0002) as PartyLegalEntity/CompanyID.
        // A valid SIRET always carries its coherent SIREN in the first nine digits.
        SIRENNo := GetSIRENNo(CompanyInformation."Registration No.", CompanyInformation."SIRET No.");
        if SIRENNo <> '' then
            InjectLegalEntitySIREN(PartyNode, NamespaceMgr, CopyStr(SIRENNo, 1, 20));
    end;

    local procedure GetSIRENNo(RegistrationNo: Text; SIRETNo: Text): Text
    begin
        if IsNumericIdentifier(SIRETNo, 14) then
            exit(CopyStr(SIRETNo, 1, 9));
        if IsNumericIdentifier(RegistrationNo, 9) then
            exit(RegistrationNo);
    end;

    local procedure IsNumericIdentifier(Identifier: Text; RequiredLength: Integer): Boolean
    begin
        exit((StrLen(Identifier) = RequiredLength) and (DelChr(Identifier, '=', '0123456789') = ''));
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
        FREDocHelpers: Codeunit "EDoc. Helpers";
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
            end else
                if CompanyInformation."Registration No." <> '' then begin
                    ElecAddress := CompanyInformation."Registration No.";
                    ElecAddressScheme := ElecAddressScheme::"0002";
                end else
                    if FREDocHelpers.IsFrenchCompany(CompanyInformation) then begin
                        ElecAddress := CopyStr(CompanyInformation.GetVATRegistrationNumber(), 1, MaxStrLen(ElecAddress));
                        ElecAddressScheme := ElecAddressScheme::"9957";
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
        FREDocHelpers: Codeunit "EDoc. Helpers";
        CustomerNoFieldRef: FieldRef;
        CustomerNo: Code[20];
    begin
        if not FRCIIXMLBuilder.TryGetCustomerNoFieldRef(SourceDocumentHeader, CustomerNoFieldRef) then
            exit(false);

        CustomerNo := CustomerNoFieldRef.Value();
        if CustomerNo = '' then
            exit(false);

        if GetServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Customer, CustomerNo, ElecAddress, ElecAddressScheme) then begin
            ElecAddressScheme := ElecAddressScheme::"0225";
            exit(true);
        end;

        Customer.SetLoadFields("FR Electronic Address", "Registration Number", "VAT Registration No.");
        if not Customer.Get(CustomerNo) then
            exit(false);

        if not FREDocHelpers.GetBuyerElectronicAddress(Customer, ElecAddress) then
            exit(false);
        ElecAddressScheme := ElecAddressScheme::"0225";
        exit(true);
    end;

    local procedure GetServiceParticipantAddress(EDocumentServiceCode: Code[20]; ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20]; var ElecAddress: Text[250]; var ElecAddressScheme: Enum "Electronic Address Scheme"): Boolean
    var
        ServiceParticipant: Record "Service Participant";
        FREDocHelpers: Codeunit "EDoc. Helpers";
    begin
        if not FREDocHelpers.HasServiceParticipantAddress(EDocumentServiceCode, ParticipantType, ParticipantNo, ServiceParticipant) then
            exit(false);

        ElecAddress := CopyStr(ServiceParticipant."Participant Identifier", 1, MaxStrLen(ElecAddress));
        ElecAddressScheme := ServiceParticipant."FR Identifier Scheme";
        exit(true);
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
            ElecAddressScheme::"0225":
                exit('0225');
            ElecAddressScheme::"9957":
                exit('9957');
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

    [EventSubscriber(ObjectType::Table, Database::"E-Document Log", OnBeforeExportDataStorage, '', false, false)]
    local procedure AddXmlExtensionOnBeforeExportDataStorage(EDocumentLog: Record "E-Document Log"; var FileName: Text)
    begin
        if EDocumentLog."Document Format" = EDocumentLog."Document Format"::"Peppol BIS 3.0 FR" then
            FileName += '.xml';
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document Service", 'OnAfterValidateEvent', 'Document Format', false, false)]
    local procedure OnAfterValidateDocumentFormat(var Rec: Record "E-Document Service"; var xRec: Record "E-Document Service"; CurrFieldNo: Integer)
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        if Rec."Document Format" <> Rec."Document Format"::"Peppol BIS 3.0 FR" then
            exit;

        if Rec."Read into Draft Impl." = Rec."Read into Draft Impl."::Unspecified then
            Rec."Read into Draft Impl." := Rec."Read into Draft Impl."::"Peppol BIS 3.0 FR";

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
    end;

    var
        CbcNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        CacNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        ExtendedCTCFranceCustomizationIdTok: Label 'EXTENDED-CTC-FR', Locked = true;
        RegulatoryCommentFormatTok: Label '#%1#%2', Comment = '%1 = Regulatory comment type, %2 = Comment text', Locked = true;
        BillingModeB1Tok: Label 'B1', Locked = true;
        BillingModeS1Tok: Label 'S1', Locked = true;
        BillingModeM1Tok: Label 'M1', Locked = true;
        InvoiceLineXPathTok: Label '/*/cac:InvoiceLine[cbc:ID=''%1'']', Locked = true;
}
