// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.History;
using Microsoft.eServices.EDocument;
using System;
using System.Reflection;
using System.Security.Encryption;
using System.Telemetry;
using System.Utilities;

codeunit 3354 "Export Interfactura MX"
{
    var
        CompanyInformation: Record "Company Information";
        MXConnectionSetup: Record "MX Connection Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DigitalSignMX: Codeunit "Digital Sign MX";
        CFDIXMLHelperMX: Codeunit "CFDI XML Helper MX";
        XSINamespaceTxt: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        CFDINamespaceTxt: Label 'http://www.sat.gob.mx/cfd/4', Locked = true;
        CFDIXSDLocationTxt: Label 'http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd', Locked = true;
        CFDIComercioExteriorNamespaceTxt: Label 'http://www.sat.gob.mx/ComercioExterior20', Locked = true;
        CFDIComercioExteriorSchemaLocationTxt: Label 'http://www.sat.gob.mx/sitio_internet/cfd/ComercioExterior20/ComercioExterior20.xsd', Locked = true;
        CartaPorteNamespaceTxt: Label 'http://www.sat.gob.mx/CartaPorte31', Locked = true;
        CartaPorteSchemaLocationTxt: Label 'http://www.sat.gob.mx/sitio_internet/cfd/CartaPorte/CartaPorte31.xsd', Locked = true;
        FeatureNameTok: Label 'EDocument Format Interfactura', Locked = true;
        StartEventNameTok: Label 'Export initiated. IsBatch is: %1', Locked = true;
        EndEventNameTok: Label 'Export completed', Locked = true;
        NumeroPedimentoFormatTxt: Label '%1 %2 %3 %4', Locked = true;
        // SAT catalog values for advance payment CFDI (catalogo c_ClaveProdServ and c_ClaveUnidad)
        AdvanceProdServCodeTok: Label '84111506', Locked = true;
        AdvanceUnitCodeTok: Label 'ACT', Locked = true;
        AdvanceDescriptionTok: Label 'Anticipo bien o servicio', Locked = true;
        AdvanceReverseDescriptionTok: Label 'Aplicacion de anticipo', Locked = true;

    procedure Export(var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        TransferLine: Record "Transfer Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        OnBeforeExport(SourceDocumentHeader, SourceDocumentLines, TempBlob, IsBatch);
        FeatureTelemetry.LogUsage('0000OCR', FeatureNameTok, StrSubstNo(StartEventNameTok, Format(IsBatch)));
        CompanyInformation.Get();
        if not MXConnectionSetup.Get() then
            MXConnectionSetup.Init();

        case SourceDocumentHeader.Number of
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    if not IsBatch then
                        SalesHeader.SetRecFilter();
                    SourceDocumentLines.SetTable(SalesLine);
                    ExportSalesHeader(EDocument, SalesHeader, SalesLine, TempBlob, IsBatch);
                end;
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(SalesInvoiceHeader);
                    if not IsBatch then
                        SalesInvoiceHeader.SetRecFilter();
                    SourceDocumentLines.SetTable(SalesInvoiceLine);
                    ExportInvoice(EDocument, SalesInvoiceHeader, SalesInvoiceLine, TempBlob, IsBatch);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(SalesCrMemoHeader);
                    if not IsBatch then
                        SalesCrMemoHeader.SetRecFilter();
                    SourceDocumentLines.SetTable(SalesCrMemoLine);
                    ExportCreditMemo(EDocument, SalesCrMemoHeader, SalesCrMemoLine, TempBlob, IsBatch);
                end;
            Database::"Service Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceInvoiceHeader);
                    if not IsBatch then
                        ServiceInvoiceHeader.SetRecFilter();
                    SourceDocumentLines.SetTable(ServiceInvoiceLine);
                    ExportServiceInvoice(EDocument, ServiceInvoiceHeader, ServiceInvoiceLine, TempBlob, IsBatch);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceCrMemoHeader);
                    if not IsBatch then
                        ServiceCrMemoHeader.SetRecFilter();
                    SourceDocumentLines.SetTable(ServiceCrMemoLine);
                    ExportServiceCreditMemo(EDocument, ServiceCrMemoHeader, ServiceCrMemoLine, TempBlob, IsBatch);
                end;
            Database::"Sales Shipment Header":
                begin
                    SourceDocumentHeader.SetTable(SalesShipmentHeader);
                    if not IsBatch then
                        SalesShipmentHeader.SetRecFilter();
                    SourceDocumentLines.SetTable(SalesShipmentLine);
                    ExportSalesShipment(EDocument, SalesShipmentHeader, SalesShipmentLine, TempBlob, IsBatch);
                end;
            Database::"Transfer Header":
                begin
                    SourceDocumentHeader.SetTable(TransferHeader);
                    if not IsBatch then
                        TransferHeader.SetRecFilter();
                    SourceDocumentLines.SetTable(TransferLine);
                    ExportTransferHeader(EDocument, TransferHeader, TransferLine, TempBlob, IsBatch);
                end;
            Database::"Transfer Shipment Header":
                begin
                    SourceDocumentHeader.SetTable(TransferShipmentHeader);
                    if not IsBatch then
                        TransferShipmentHeader.SetRecFilter();
                    SourceDocumentLines.SetTable(TransferShipmentLine);
                    ExportTransferShipment(EDocument, TransferShipmentHeader, TransferShipmentLine, TempBlob, IsBatch);
                end;
        end;
        FeatureTelemetry.LogUsage('0000OCT', FeatureNameTok, EndEventNameTok);
        OnAfterExport(SourceDocumentHeader, SourceDocumentLines, TempBlob, IsBatch);
    end;

    #region Sales Order

    local procedure ExportSalesHeader(var EDocument: Record "E-Document"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        XmlDocOut: XmlDocument;
        RootNode: XmlElement;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(true, SalesHeader."Foreign Trade"), XmlDocOut);
        XmlDocOut.GetRoot(RootNode);

        BuildSalesHeaderNode(RootNode, SalesHeader, SalesLine);
        SignComprobanteXml(RootNode, XmlDocOut);
        XmlDocOut.WriteTo(FileOutStream);
    end;

    #endregion

    #region Invoice

    local procedure ExportInvoice(var EDocument: Record "E-Document"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        XMLDocOut: XmlDocument;
        ComprobanteXMLNode: XmlElement;
        FileOutStream: OutStream;
        OriginalString: Text;
        SignedString: Text;
        CertificateText: Text;
        AdvanceUUID: Text[50];
        CertificateSerialNo: Text[250];
        AdvanceScenario: Integer;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(false, SalesInvoiceHeader."Foreign Trade"), XMLDocOut);
        XMLDocOut.GetRoot(ComprobanteXMLNode);

        GetCertificateMetadata(CertificateText, CertificateSerialNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        AdvanceScenario := GetAdvanceScenario(SalesInvoiceHeader);
        case AdvanceScenario of
            1:
                CreateXMLDocument33AdvancePayment(
                    ComprobanteXMLNode, SalesInvoiceHeader, SalesInvoiceLine, '', CertificateText, CertificateSerialNo, XMLDocOut,
                    SalesInvoiceHeader.Amount, SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount);
            2:
                begin
                    AdvanceUUID := FindPrepaymentUUID(SalesInvoiceHeader);
                    CreateXMLDocument33AdvanceSettle(
                        ComprobanteXMLNode, SalesInvoiceHeader, SalesInvoiceLine, '', CertificateText, CertificateSerialNo, XMLDocOut,
                        AdvanceUUID, SalesInvoiceHeader.Amount, SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, 0, 0);
                end;
            else
                CreateXMLDocument33(
                    ComprobanteXMLNode, SalesInvoiceHeader, SalesInvoiceLine, '', CertificateText, CertificateSerialNo, XMLDocOut,
                    SalesInvoiceHeader.Amount, SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, 0, 0);
        end;

        RemoveRedeclaredNamespaces(XMLDocOut);
        OriginalString := CreateOriginalStr33Document(XMLDocOut);
        SignedString := CreateDigitalSignature(OriginalString, MXConnectionSetup.Id);
        XMLDocOut.GetRoot(ComprobanteXMLNode);
        ComprobanteXMLNode.SetAttribute('Sello', SignedString);
        ApplyLastUsedCertificateMetadata(ComprobanteXMLNode, CertificateSerialNo);

        XMLDocOut.WriteTo(FileOutStream);
    end;

    local procedure BuildInvoiceNode(var ComprobanteXMLNode: XmlElement; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        XMLDocTmp: XmlDocument;
        CertificateText: Text;
        CertificateSerialNo: Text[250];
        SubTotal: Decimal;
        TaxTotal: Decimal;
    begin
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SubTotal := SalesInvoiceHeader.Amount;
        TaxTotal := SalesInvoiceHeader."Amount Including VAT" - SubTotal;

        GetCertificateMetadata(CertificateText, CertificateSerialNo);
        CreateXMLDocument33(
            ComprobanteXMLNode,
            SalesInvoiceHeader,
            SalesInvoiceLine,
            '',
            CertificateText,
            CertificateSerialNo,
            XMLDocTmp,
            SubTotal,
            TaxTotal,
            0,
            0);
    end;

    local procedure GetCertificateMetadata(var CertificateText: Text; var CertificateSerialNo: Text[250])
    var
        MXConnectionSetup: Record "MX Connection Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        X509Certificate2: Codeunit X509Certificate2;
    begin
        CertificateText := '';
        CertificateSerialNo := '';

        if not MXConnectionSetup.Get() then
            exit;

        if MXConnectionSetup."SAT Certificate" = '' then
            exit;

        if not IsolatedCertificate.Get(MXConnectionSetup."SAT Certificate") then
            exit;

        // SAT expects the raw DER certificate, not the PKCS#12 container that holds the private key
        CertificateText :=
            X509Certificate2.GetRawCertDataAsBase64String(
                CertificateManagement.GetCertAsBase64String(IsolatedCertificate),
                CertificateManagement.GetPasswordAsSecret(IsolatedCertificate));
        CertificateSerialNo := CopyStr(DigitalSignMX.GetCertificateSerialNo(MXConnectionSetup.Id), 1, MaxStrLen(CertificateSerialNo));
    end;

    local procedure SignComprobanteXml(var ComprobanteXMLNode: XmlElement; var XMLDocOut: XmlDocument): Boolean
    var
        OriginalString: Text;
        SignedString: Text;
        CertificateText: Text;
        CertificateSerialNo: Text[250];
    begin
        if not MXConnectionSetup.Get() then
            exit(false);

        GetCertificateMetadata(CertificateText, CertificateSerialNo);
        if (CertificateText = '') or (CertificateSerialNo = '') then
            exit(false);

        ComprobanteXMLNode.SetAttribute('Sello', '');
        ComprobanteXMLNode.SetAttribute('NoCertificado', CertificateSerialNo);
        ComprobanteXMLNode.SetAttribute('Certificado', CertificateText);
        RemoveRedeclaredNamespaces(XMLDocOut);
        OriginalString := CreateOriginalStr33Document(XMLDocOut);

        SignedString := CreateDigitalSignature(OriginalString, MXConnectionSetup.Id);

        XMLDocOut.GetRoot(ComprobanteXMLNode);
        ComprobanteXMLNode.SetAttribute('Sello', SignedString);
        ApplyLastUsedCertificateMetadata(ComprobanteXMLNode, CertificateSerialNo);

        exit(true);
    end;

    local procedure ApplyLastUsedCertificateMetadata(var ComprobanteXMLNode: XmlElement; var CertificateSerialNo: Text[250])
    var
        CertificateText: Text;
        LastUsedCertificateSerialNo: Text;
    begin
        CertificateText := DigitalSignMX.GetLastUsedCertificate();
        LastUsedCertificateSerialNo := DigitalSignMX.GetLastUsedCertificateSerialNo();

        if LastUsedCertificateSerialNo <> '' then begin
            CertificateSerialNo := CopyStr(LastUsedCertificateSerialNo, 1, MaxStrLen(CertificateSerialNo));
            ComprobanteXMLNode.SetAttribute('NoCertificado', CertificateSerialNo);
        end;

        if CertificateText <> '' then
            ComprobanteXMLNode.SetAttribute('Certificado', CertificateText);
    end;

    #endregion

    #region Service Invoice

    local procedure ExportServiceInvoice(var EDocument: Record "E-Document"; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceInvoiceLine: Record "Service Invoice Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        XmlDocOut: XmlDocument;
        RootNode: XmlElement;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(false, ServiceInvoiceHeader."Foreign Trade"), XmlDocOut);
        XmlDocOut.GetRoot(RootNode);

        BuildServiceInvoiceNode(RootNode, ServiceInvoiceHeader, ServiceInvoiceLine);
        SignComprobanteXml(RootNode, XmlDocOut);
        XmlDocOut.WriteTo(FileOutStream);
    end;

    #endregion

    #region Credit Memo

    local procedure ExportCreditMemo(var EDocument: Record "E-Document"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        XmlDocOut: XmlDocument;
        RootNode: XmlElement;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(false, SalesCrMemoHeader."Foreign Trade"), XmlDocOut);
        XmlDocOut.GetRoot(RootNode);

        BuildCreditMemoNode(RootNode, SalesCrMemoHeader, SalesCrMemoLine);
        SignComprobanteXml(RootNode, XmlDocOut);
        XmlDocOut.WriteTo(FileOutStream);
    end;

    #endregion

    #region Service Credit Memo

    local procedure ExportServiceCreditMemo(var EDocument: Record "E-Document"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        XmlDocOut: XmlDocument;
        RootNode: XmlElement;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(false, ServiceCrMemoHeader."Foreign Trade"), XmlDocOut);
        XmlDocOut.GetRoot(RootNode);

        BuildServiceCreditMemoNode(RootNode, ServiceCrMemoHeader, ServiceCrMemoLine);
        SignComprobanteXml(RootNode, XmlDocOut);
        XmlDocOut.WriteTo(FileOutStream);
    end;

    #endregion

    #region Sales Shipment

    local procedure ExportSalesShipment(var EDocument: Record "E-Document"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesShptLine: Record "Sales Shipment Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        XmlDocOut: XmlDocument;
        RootNode: XmlElement;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(true, SalesShptHeader."Foreign Trade"), XmlDocOut);
        XmlDocOut.GetRoot(RootNode);

        BuildTransferNode(RootNode, SalesShptHeader, SalesShptLine);
        SignComprobanteXml(RootNode, XmlDocOut);
        XmlDocOut.WriteTo(FileOutStream);
    end;

    #endregion

    #region Transfer Header

    local procedure ExportTransferHeader(var EDocument: Record "E-Document"; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        XmlDocOut: XmlDocument;
        RootNode: XmlElement;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(true, TransferHeader."Foreign Trade"), XmlDocOut);
        XmlDocOut.GetRoot(RootNode);

        BuildTransferHeaderNode(RootNode, TransferHeader, TransferLine);
        SignComprobanteXml(RootNode, XmlDocOut);
        XmlDocOut.WriteTo(FileOutStream);
    end;

    #endregion

    #region Transfer Shipment

    local procedure ExportTransferShipment(var EDocument: Record "E-Document"; var TransferShipment: Record "Transfer Shipment Header"; var TransferShipmentLine: Record "Transfer Shipment Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        XmlDocOut: XmlDocument;
        RootNode: XmlElement;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(true, TransferShipment."Foreign Trade"), XmlDocOut);
        XmlDocOut.GetRoot(RootNode);

        BuildTransferNode(RootNode, TransferShipment, TransferShipmentLine);
        SignComprobanteXml(RootNode, XmlDocOut);
        XmlDocOut.WriteTo(FileOutStream);
    end;

    #endregion

    #region Common Procedures

    local procedure CreateCFDIElement(ElementName: Text): XmlElement
    begin
        exit(XmlElement.Create(ElementName, CFDINamespaceTxt, ''));
    end;

    local procedure GetBasicXMLHeader(IsCartaPorte: Boolean; IsForeignTrade: Boolean): Text
    var
        SchemaLocation: Text;
        NamespaceAttributes: Text;
    begin
        NamespaceAttributes :=
            'xmlns:cfdi="' + CFDINamespaceTxt + '" ';

        SchemaLocation := CFDINamespaceTxt + ' ' + CFDIXSDLocationTxt;

        if IsCartaPorte then begin
            NamespaceAttributes += 'xmlns:cartaporte31="' + CartaPorteNamespaceTxt + '" ';
            SchemaLocation += ' ' + CartaPorteNamespaceTxt + ' ' + CartaPorteSchemaLocationTxt;
        end;

        if IsForeignTrade then begin
            NamespaceAttributes += 'xmlns:cce20="' + CFDIComercioExteriorNamespaceTxt + '" ';
            SchemaLocation += ' ' + CFDIComercioExteriorNamespaceTxt + ' ' + CFDIComercioExteriorSchemaLocationTxt;
        end;

        NamespaceAttributes += 'xmlns:xsi="' + XSINamespaceTxt + '" ';

        exit(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<cfdi:Comprobante ' +
            NamespaceAttributes +
            'xsi:schemaLocation="' + SchemaLocation + '" ' +
            'Version="4.0"/>'
        );
    end;

    local procedure GetReportedLineAmount(SalesInvoiceLine: Record "Sales Invoice Line"): Decimal
    begin
        exit(SalesInvoiceLine.Amount);
    end;

    local procedure AddInformacionGlobalNode(var ParentNode: XmlElement; Customer: Record Customer; CFDIPeriod: Option "Diario","Semanal","Quincenal","Mensual"; PostingDate: Date)
    var
        InformacionGlobalNode: XmlElement;
    begin
        if not Customer."CFDI General Public" then
            exit;
        if Format(CFDIPeriod) = '' then
            exit;

        InformacionGlobalNode := XmlElement.Create('InformacionGlobal');
        InformacionGlobalNode.SetAttribute('Año', Format(Date2DMY(PostingDate, 3)));
        InformacionGlobalNode.SetAttribute('Meses', FormatMonth(Format(Date2DMY(PostingDate, 2))));
        InformacionGlobalNode.SetAttribute('Periodicidad', FormatPeriod(CFDIPeriod));
        ParentNode.Add(InformacionGlobalNode.AsXmlNode());
    end;

    local procedure AddCfdiRelacionadosNode(var ParentNode: XmlElement; DocumentTableId: Integer; DocumentNo: Code[20]; RelationType: Code[10])
    var
        CFDIRelationDocument: Record "CFDI Relation Document";
        CfdiRelacionadosNode: XmlElement;
        CfdiRelacionadoNode: XmlElement;
    begin
        if RelationType = '' then
            exit;

        CFDIRelationDocument.SetRange("Document Table ID", DocumentTableId);
        CFDIRelationDocument.SetRange("Document No.", DocumentNo);
        CFDIRelationDocument.SetRange("SAT Relation Type", RelationType);
        if CFDIRelationDocument.IsEmpty() then
            exit;

        CfdiRelacionadosNode := CreateCFDIElement('CfdiRelacionados');
        CfdiRelacionadosNode.SetAttribute('TipoRelacion', RelationType);

        if CFDIRelationDocument.FindSet() then
            repeat
                CfdiRelacionadoNode := CreateCFDIElement('CfdiRelacionado');
                CfdiRelacionadoNode.SetAttribute('UUID', CFDIRelationDocument."Fiscal Invoice Number PAC");
                CfdiRelacionadosNode.Add(CfdiRelacionadoNode.AsXmlNode());
            until CFDIRelationDocument.Next() = 0;

        ParentNode.Add(CfdiRelacionadosNode.AsXmlNode());
    end;

    local procedure AddForeignTradeComplementNode(var ParentNode: XmlElement; DocumentHeader: Record "Sales Invoice Header"; IsCartaporte: Boolean)
    var
        Customer: Record Customer;
        Location: Record Location;
        Item: Record Item;
        UOM: Record "Unit of Measure";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ComplementoNode: XmlElement;
        ComercioExteriorNode: XmlNode;
        EmisorNode: XmlNode;
        DomicilioNode: XmlNode;
        ReceptorNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        ParentXmlNode: XmlNode;
        CurrencyFactor: Decimal;
        SumUSD: Decimal;
        LineCount: Integer;
        LineNo: Integer;
    begin
        if IsCartaporte then
            exit;

        GetCustomer(Customer, DocumentHeader."Bill-to Customer No.", false);
        SalesInvoiceLine.SetRange("Document No.", DocumentHeader."No.");
        LineCount := SalesInvoiceLine.Count();
        if LineCount = 0 then
            exit;

        ComplementoNode := XmlElement.Create('Complemento');
        ParentXmlNode := ComplementoNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCCE(ParentXmlNode, 'ComercioExterior', '', CFDIComercioExteriorNamespaceTxt, ComercioExteriorNode);
        ComercioExteriorNode.AsXmlElement().SetAttribute('Version', '2.0');
        ComercioExteriorNode.AsXmlElement().SetAttribute('ClaveDePedimento', 'A1');
        ComercioExteriorNode.AsXmlElement().SetAttribute('CertificadoOrigen', '0');
        ComercioExteriorNode.AsXmlElement().SetAttribute('Incoterm', DocumentHeader."SAT International Trade Term");
        CurrencyFactor := (1 / DocumentHeader."Currency Factor") * DocumentHeader."Exchange Rate USD";
        ComercioExteriorNode.AsXmlElement().SetAttribute('TipoCambioUSD', FormatDecimal(DocumentHeader."Exchange Rate USD", 6));
        ComercioExteriorNode.AsXmlElement().SetAttribute('TotalUSD', FormatDecimal(DocumentHeader.Amount * CurrencyFactor, 2));

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Emisor', '', CFDIComercioExteriorNamespaceTxt, EmisorNode);
        CFDIXMLHelperMX.AddElementCCE(EmisorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        Location.Get(DocumentHeader."Location Code");
        CFDIXMLHelperMX.AddNodeDomicilio(Location."SAT Address ID", Location.Address, DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Receptor', '', CFDIComercioExteriorNamespaceTxt, ReceptorNode);
        if (Customer."Country/Region Code" <> 'MEX') and (Customer."RFC No." = 'XEXX010101000') then
            ReceptorNode.AsXmlElement().SetAttribute('NumRegIdTrib', Customer."VAT Registration No.");
        CFDIXMLHelperMX.AddElementCCE(ReceptorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(DocumentHeader."SAT Address ID", DocumentHeader."Bill-to Address", DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Mercancias', '', CFDIComercioExteriorNamespaceTxt, MercanciasNode);
        if SalesInvoiceLine.FindSet() then
            repeat
                LineNo += 1;
                CFDIXMLHelperMX.AddElementCCE(MercanciasNode, 'Mercancia', '', CFDIComercioExteriorNamespaceTxt, MercanciaNode);
                MercanciaNode.AsXmlElement().SetAttribute('NoIdentificacion', SalesInvoiceLine."No.");
                if Item.Get(SalesInvoiceLine."No.") and (Item."Tariff No." <> '') then
                    MercanciaNode.AsXmlElement().SetAttribute('FraccionArancelaria', DelChr(Item."Tariff No."));
                MercanciaNode.AsXmlElement().SetAttribute('CantidadAduana', Format(SalesInvoiceLine.Quantity, 0, 9));
                UOM.Get(SalesInvoiceLine."Unit of Measure Code");
                MercanciaNode.AsXmlElement().SetAttribute('UnidadAduana', UOM."SAT Customs Unit");
                MercanciaNode.AsXmlElement().SetAttribute('ValorUnitarioAduana', FormatDecimal(SalesInvoiceLine.Amount / SalesInvoiceLine.Quantity, 6));
                if LineNo <> LineCount then begin
                    MercanciaNode.AsXmlElement().SetAttribute('ValorDolares', FormatDecimal(SalesInvoiceLine.Amount / DocumentHeader."Exchange Rate USD", 4));
                    SumUSD += SalesInvoiceLine.Amount / DocumentHeader."Exchange Rate USD";
                end else
                    MercanciaNode.AsXmlElement().SetAttribute('ValorDolares', FormatDecimal(DocumentHeader.Amount / DocumentHeader."Exchange Rate USD" - SumUSD, 4));
            until SalesInvoiceLine.Next() = 0;

        ParentNode.Add(ComplementoNode.AsXmlNode());
    end;

    local procedure BuildCreditMemoNode(var RootNode: XmlElement; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        SATUtilities: Codeunit "SAT Utilities";
        ConceptosNode: XmlElement;
        ConceptoNode: XmlElement;
        EmisorNode: XmlElement;
        ReceptorNode: XmlElement;
        ImpuestosNode: XmlElement;
        TrasladosNode: XmlElement;
        TrasladoNode: XmlElement;
        SubTotal: Decimal;
        Total: Decimal;
        TaxTotal: Decimal;
        CalculatedTaxBase: Decimal;
        CalculatedTaxTotal: Decimal;
        SummaryVATPct: Decimal;
        CurrencyCode: Code[10];
        LineAmount: Decimal;
        LineDiscount: Decimal;
        TotalDiscount: Decimal;
        CertificateText: Text;
        CertificateSerialNo: Text[250];
    begin
        CompanyInfo.Get();
        GetCustomer(Customer, SalesCrMemoHeader."Bill-to Customer No.", false);

        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        SubTotal := SalesCrMemoHeader.Amount;
        Total := SalesCrMemoHeader."Amount Including VAT";
        TaxTotal := Total - SubTotal;
        CurrencyCode := SalesCrMemoHeader."Currency Code";
        if CurrencyCode = '' then
            CurrencyCode := 'MXN';

        GetCertificateMetadata(CertificateText, CertificateSerialNo);

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', SalesCrMemoHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(SalesCrMemoHeader));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('FormaPago', SATUtilities.GetSATPaymentMethod(SalesCrMemoHeader."Payment Method Code"));
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', CertificateText);
        RootNode.SetAttribute('SubTotal', FormatAmount(SubTotal, CurrencyCode));
        RootNode.SetAttribute('Descuento', FormatAmount(TotalDiscount, CurrencyCode));
        if CurrencyCode <> '' then begin
            RootNode.SetAttribute('Moneda', CurrencyCode);
            if (CurrencyCode <> 'MXN') and (CurrencyCode <> 'XXX') then
                RootNode.SetAttribute('TipoCambio', FormatDecimal(1 / SalesCrMemoHeader."Currency Factor", 6));
        end;
        RootNode.SetAttribute('Total', FormatAmount(Total, CurrencyCode));
        RootNode.SetAttribute('TipoDeComprobante', 'E');
        RootNode.SetAttribute('Exportacion', SalesCrMemoHeader."CFDI Export Code");
        RootNode.SetAttribute('MetodoPago', SATUtilities.GetSATPaymentTerm(SalesCrMemoHeader."Payment Terms Code"));
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddCfdiRelacionadosNode(RootNode, Database::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", SalesCrMemoHeader."CFDI Relation");

        EmisorNode := CreateCFDIElement('Emisor');
        EmisorNode.SetAttribute('Rfc', CompanyInfo."RFC Number");
        EmisorNode.SetAttribute('Nombre', CompanyInfo.Name);
        EmisorNode.SetAttribute('RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");
        RootNode.Add(EmisorNode.AsXmlNode());

        ReceptorNode := CreateCFDIElement('Receptor');
        ReceptorNode.SetAttribute('Rfc', Customer."RFC No.");
        ReceptorNode.SetAttribute('Nombre', Customer.Name);
        ReceptorNode.SetAttribute('DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        ReceptorNode.SetAttribute('RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        ReceptorNode.SetAttribute('UsoCFDI', SalesCrMemoHeader."CFDI Purpose");
        RootNode.Add(ReceptorNode.AsXmlNode());

        ConceptosNode := CreateCFDIElement('Conceptos');
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        if SalesCrMemoLine.FindSet() then
            repeat
                ConceptoNode := CreateCFDIElement('Concepto');
                LineAmount := SalesCrMemoLine.Amount;
                LineDiscount := SalesCrMemoLine."Line Discount Amount";
                ConceptoNode.SetAttribute('ClaveProdServ', SATUtilities.GetSATClassification(SalesCrMemoLine.Type, SalesCrMemoLine."No."));
                ConceptoNode.SetAttribute('NoIdentificacion', SalesCrMemoLine."No.");
                ConceptoNode.SetAttribute('Cantidad', Format(SalesCrMemoLine.Quantity, 0, 9));
                ConceptoNode.SetAttribute('ClaveUnidad', SATUtilities.GetSATUnitofMeasure(SalesCrMemoLine."Unit of Measure Code"));
                ConceptoNode.SetAttribute('Unidad', SalesCrMemoLine."Unit of Measure Code");
                ConceptoNode.SetAttribute('Descripcion', EncodeString(SalesCrMemoLine.Description));
                ConceptoNode.SetAttribute('ValorUnitario', FormatDecimal(SalesCrMemoLine."Unit Price", 6));
                ConceptoNode.SetAttribute('Importe', FormatDecimal(LineAmount, 6));
                ConceptoNode.SetAttribute('Descuento', FormatDecimal(LineDiscount, 6));
                TotalDiscount += LineDiscount;
                ConceptoNode.SetAttribute('ObjetoImp', '02');

                if SalesCrMemoLine."VAT %" <> 0 then begin
                    CalculatedTaxBase += SalesCrMemoLine.Amount;
                    CalculatedTaxTotal += Round(SalesCrMemoLine.Amount * SalesCrMemoLine."VAT %" / 100, 0.000001);
                    SummaryVATPct := SalesCrMemoLine."VAT %";

                    ImpuestosNode := CreateCFDIElement('Impuestos');
                    TrasladosNode := CreateCFDIElement('Traslados');
                    TrasladoNode := CreateCFDIElement('Traslado');
                    TrasladoNode.SetAttribute('Base', FormatDecimal(SalesCrMemoLine.Amount, 6));
                    TrasladoNode.SetAttribute('Impuesto', GetTaxCode(SalesCrMemoLine."VAT %", SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount));
                    TrasladoNode.SetAttribute('TipoFactor', 'Tasa');
                    TrasladoNode.SetAttribute('TasaOCuota', PadStr(FormatDecimal(SalesCrMemoLine."VAT %" / 100, 6), 8, '0'));
                    TrasladoNode.SetAttribute('Importe', FormatDecimal(Round(SalesCrMemoLine.Amount * SalesCrMemoLine."VAT %" / 100, 0.000001), 6));
                    TrasladosNode.Add(TrasladoNode.AsXmlNode());
                    ImpuestosNode.Add(TrasladosNode.AsXmlNode());
                    ConceptoNode.Add(ImpuestosNode.AsXmlNode());
                end;

                ConceptosNode.Add(ConceptoNode.AsXmlNode());
            until SalesCrMemoLine.Next() = 0;

        RootNode.Add(ConceptosNode.AsXmlNode());

        TaxTotal := CalculatedTaxTotal;
        RootNode.SetAttribute('Total', FormatAmount(SubTotal + TaxTotal, CurrencyCode));
        if TaxTotal <> 0 then begin
            ImpuestosNode := CreateCFDIElement('Impuestos');
            ImpuestosNode.SetAttribute('TotalImpuestosTrasladados', FormatAmount(TaxTotal, CurrencyCode));
            TrasladosNode := CreateCFDIElement('Traslados');
            TrasladoNode := CreateCFDIElement('Traslado');
            TrasladoNode.SetAttribute('Base', FormatAmount(CalculatedTaxBase, CurrencyCode));
            TrasladoNode.SetAttribute('Impuesto', GetTaxCode(SummaryVATPct, TaxTotal));
            TrasladoNode.SetAttribute('TipoFactor', 'Tasa');
            TrasladoNode.SetAttribute('TasaOCuota', PadStr(FormatDecimal(SummaryVATPct / 100, 6), 8, '0'));
            TrasladoNode.SetAttribute('Importe', FormatAmount(TaxTotal, CurrencyCode));
            TrasladosNode.Add(TrasladoNode.AsXmlNode());
            ImpuestosNode.Add(TrasladosNode.AsXmlNode());
            RootNode.Add(ImpuestosNode.AsXmlNode());
        end;
    end;

    local procedure BuildServiceInvoiceNode(var RootNode: XmlElement; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceInvoiceLine: Record "Service Invoice Line")
    var
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        SATUtilities: Codeunit "SAT Utilities";
        ConceptosNode: XmlElement;
        ConceptoNode: XmlElement;
        EmisorNode: XmlElement;
        ReceptorNode: XmlElement;
        ImpuestosNode: XmlElement;
        TrasladosNode: XmlElement;
        TrasladoNode: XmlElement;
        SubTotal: Decimal;
        Total: Decimal;
        TaxTotal: Decimal;
        CalculatedTaxBase: Decimal;
        CalculatedTaxTotal: Decimal;
        SummaryVATPct: Decimal;
        CurrencyCode: Code[10];
        LineAmount: Decimal;
        LineDiscount: Decimal;
        TotalDiscount: Decimal;
        CertificateText: Text;
        CertificateSerialNo: Text[250];
    begin
        CompanyInfo.Get();
        GetCustomer(Customer, ServiceInvoiceHeader."Bill-to Customer No.", false);

        ServiceInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SubTotal := ServiceInvoiceHeader.Amount;
        Total := ServiceInvoiceHeader."Amount Including VAT";
        TaxTotal := Total - SubTotal;
        CurrencyCode := ServiceInvoiceHeader."Currency Code";
        if CurrencyCode = '' then
            CurrencyCode := 'MXN';

        GetCertificateMetadata(CertificateText, CertificateSerialNo);

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', ServiceInvoiceHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(ServiceInvoiceHeader));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('FormaPago', SATUtilities.GetSATPaymentMethod(ServiceInvoiceHeader."Payment Method Code"));
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', CertificateText);
        RootNode.SetAttribute('SubTotal', FormatAmount(SubTotal, CurrencyCode));
        RootNode.SetAttribute('Descuento', FormatAmount(TotalDiscount, CurrencyCode));
        if CurrencyCode <> '' then begin
            RootNode.SetAttribute('Moneda', CurrencyCode);
            if (CurrencyCode <> 'MXN') and (CurrencyCode <> 'XXX') then
                RootNode.SetAttribute('TipoCambio', FormatDecimal(1 / ServiceInvoiceHeader."Currency Factor", 6));
        end;
        RootNode.SetAttribute('Total', FormatAmount(Total, CurrencyCode));
        RootNode.SetAttribute('TipoDeComprobante', 'I');
        RootNode.SetAttribute('Exportacion', ServiceInvoiceHeader."CFDI Export Code");
        RootNode.SetAttribute('MetodoPago', SATUtilities.GetSATPaymentTerm(ServiceInvoiceHeader."Payment Terms Code"));
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddCfdiRelacionadosNode(RootNode, Database::"Service Invoice Header", ServiceInvoiceHeader."No.", ServiceInvoiceHeader."CFDI Relation");

        EmisorNode := CreateCFDIElement('Emisor');
        EmisorNode.SetAttribute('Rfc', CompanyInfo."RFC Number");
        EmisorNode.SetAttribute('Nombre', CompanyInfo.Name);
        EmisorNode.SetAttribute('RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");
        RootNode.Add(EmisorNode.AsXmlNode());

        ReceptorNode := CreateCFDIElement('Receptor');
        ReceptorNode.SetAttribute('Rfc', Customer."RFC No.");
        ReceptorNode.SetAttribute('Nombre', Customer.Name);
        ReceptorNode.SetAttribute('DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        ReceptorNode.SetAttribute('RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        ReceptorNode.SetAttribute('UsoCFDI', ServiceInvoiceHeader."CFDI Purpose");
        RootNode.Add(ReceptorNode.AsXmlNode());

        ConceptosNode := CreateCFDIElement('Conceptos');
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");
        if ServiceInvoiceLine.FindSet() then
            repeat
                ConceptoNode := CreateCFDIElement('Concepto');
                LineAmount := ServiceInvoiceLine.Amount;
                LineDiscount := ServiceInvoiceLine."Line Discount Amount";
                ConceptoNode.SetAttribute('ClaveProdServ', SATUtilities.GetSATClassification(ServiceInvoiceLine.Type, ServiceInvoiceLine."No."));
                ConceptoNode.SetAttribute('NoIdentificacion', ServiceInvoiceLine."No.");
                ConceptoNode.SetAttribute('Cantidad', Format(ServiceInvoiceLine.Quantity, 0, 9));
                ConceptoNode.SetAttribute('ClaveUnidad', SATUtilities.GetSATUnitofMeasure(ServiceInvoiceLine."Unit of Measure Code"));
                ConceptoNode.SetAttribute('Unidad', ServiceInvoiceLine."Unit of Measure Code");
                ConceptoNode.SetAttribute('Descripcion', EncodeString(ServiceInvoiceLine.Description));
                ConceptoNode.SetAttribute('ValorUnitario', FormatDecimal(ServiceInvoiceLine."Unit Price", 6));
                ConceptoNode.SetAttribute('Importe', FormatDecimal(LineAmount, 6));
                ConceptoNode.SetAttribute('Descuento', FormatDecimal(LineDiscount, 6));
                TotalDiscount += LineDiscount;
                ConceptoNode.SetAttribute('ObjetoImp', '02');

                if ServiceInvoiceLine."VAT %" <> 0 then begin
                    CalculatedTaxBase += ServiceInvoiceLine.Amount;
                    CalculatedTaxTotal += Round(ServiceInvoiceLine.Amount * ServiceInvoiceLine."VAT %" / 100, 0.000001);
                    SummaryVATPct := ServiceInvoiceLine."VAT %";

                    ImpuestosNode := CreateCFDIElement('Impuestos');
                    TrasladosNode := CreateCFDIElement('Traslados');
                    TrasladoNode := CreateCFDIElement('Traslado');
                    TrasladoNode.SetAttribute('Base', FormatDecimal(ServiceInvoiceLine.Amount, 6));
                    TrasladoNode.SetAttribute('Impuesto', GetTaxCode(ServiceInvoiceLine."VAT %", ServiceInvoiceLine."Amount Including VAT" - ServiceInvoiceLine.Amount));
                    TrasladoNode.SetAttribute('TipoFactor', 'Tasa');
                    TrasladoNode.SetAttribute('TasaOCuota', PadStr(FormatDecimal(ServiceInvoiceLine."VAT %" / 100, 6), 8, '0'));
                    TrasladoNode.SetAttribute('Importe', FormatDecimal(Round(ServiceInvoiceLine.Amount * ServiceInvoiceLine."VAT %" / 100, 0.000001), 6));
                    TrasladosNode.Add(TrasladoNode.AsXmlNode());
                    ImpuestosNode.Add(TrasladosNode.AsXmlNode());
                    ConceptoNode.Add(ImpuestosNode.AsXmlNode());
                end;

                ConceptosNode.Add(ConceptoNode.AsXmlNode());
            until ServiceInvoiceLine.Next() = 0;

        RootNode.Add(ConceptosNode.AsXmlNode());

        TaxTotal := CalculatedTaxTotal;
        RootNode.SetAttribute('Total', FormatDecimal(SubTotal + TaxTotal, 6));
        if TaxTotal <> 0 then begin
            ImpuestosNode := CreateCFDIElement('Impuestos');
            ImpuestosNode.SetAttribute('TotalImpuestosTrasladados', FormatDecimal(TaxTotal, 6));
            TrasladosNode := CreateCFDIElement('Traslados');
            TrasladoNode := CreateCFDIElement('Traslado');
            TrasladoNode.SetAttribute('Base', FormatDecimal(CalculatedTaxBase, 6));
            TrasladoNode.SetAttribute('Impuesto', GetTaxCode(SummaryVATPct, TaxTotal));
            TrasladoNode.SetAttribute('TipoFactor', 'Tasa');
            TrasladoNode.SetAttribute('TasaOCuota', PadStr(FormatDecimal(SummaryVATPct / 100, 6), 8, '0'));
            TrasladoNode.SetAttribute('Importe', FormatDecimal(TaxTotal, 6));
            TrasladosNode.Add(TrasladoNode.AsXmlNode());
            ImpuestosNode.Add(TrasladosNode.AsXmlNode());
            RootNode.Add(ImpuestosNode.AsXmlNode());
        end;
    end;

    local procedure BuildServiceCreditMemoNode(var RootNode: XmlElement; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceCrMemoLine: Record "Service Cr.Memo Line")
    var
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        SATUtilities: Codeunit "SAT Utilities";
        ConceptosNode: XmlElement;
        ConceptoNode: XmlElement;
        EmisorNode: XmlElement;
        ReceptorNode: XmlElement;
        ImpuestosNode: XmlElement;
        TrasladosNode: XmlElement;
        TrasladoNode: XmlElement;
        SubTotal: Decimal;
        Total: Decimal;
        TaxTotal: Decimal;
        CalculatedTaxBase: Decimal;
        CalculatedTaxTotal: Decimal;
        SummaryVATPct: Decimal;
        CurrencyCode: Code[10];
        LineAmount: Decimal;
        LineDiscount: Decimal;
        TotalDiscount: Decimal;
        CertificateText: Text;
        CertificateSerialNo: Text[250];
    begin
        CompanyInfo.Get();
        GetCustomer(Customer, ServiceCrMemoHeader."Bill-to Customer No.", false);

        ServiceCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        SubTotal := ServiceCrMemoHeader.Amount;
        Total := ServiceCrMemoHeader."Amount Including VAT";
        TaxTotal := Total - SubTotal;
        CurrencyCode := ServiceCrMemoHeader."Currency Code";
        if CurrencyCode = '' then
            CurrencyCode := 'MXN';

        GetCertificateMetadata(CertificateText, CertificateSerialNo);

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', ServiceCrMemoHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(ServiceCrMemoHeader));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('FormaPago', SATUtilities.GetSATPaymentMethod(ServiceCrMemoHeader."Payment Method Code"));
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', CertificateText);
        RootNode.SetAttribute('SubTotal', FormatAmount(SubTotal, CurrencyCode));
        RootNode.SetAttribute('Descuento', FormatAmount(TotalDiscount, CurrencyCode));
        if CurrencyCode <> '' then begin
            RootNode.SetAttribute('Moneda', CurrencyCode);
            if (CurrencyCode <> 'MXN') and (CurrencyCode <> 'XXX') then
                RootNode.SetAttribute('TipoCambio', FormatDecimal(1 / ServiceCrMemoHeader."Currency Factor", 6));
        end;
        RootNode.SetAttribute('Total', FormatAmount(Total, CurrencyCode));
        RootNode.SetAttribute('TipoDeComprobante', 'E');
        RootNode.SetAttribute('Exportacion', ServiceCrMemoHeader."CFDI Export Code");
        RootNode.SetAttribute('MetodoPago', SATUtilities.GetSATPaymentTerm(ServiceCrMemoHeader."Payment Terms Code"));
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddCfdiRelacionadosNode(RootNode, Database::"Service Cr.Memo Header", ServiceCrMemoHeader."No.", ServiceCrMemoHeader."CFDI Relation");

        EmisorNode := CreateCFDIElement('Emisor');
        EmisorNode.SetAttribute('Rfc', CompanyInfo."RFC Number");
        EmisorNode.SetAttribute('Nombre', CompanyInfo.Name);
        EmisorNode.SetAttribute('RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");
        RootNode.Add(EmisorNode.AsXmlNode());

        ReceptorNode := CreateCFDIElement('Receptor');
        ReceptorNode.SetAttribute('Rfc', Customer."RFC No.");
        ReceptorNode.SetAttribute('Nombre', Customer.Name);
        ReceptorNode.SetAttribute('DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        ReceptorNode.SetAttribute('RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        ReceptorNode.SetAttribute('UsoCFDI', ServiceCrMemoHeader."CFDI Purpose");
        RootNode.Add(ReceptorNode.AsXmlNode());

        ConceptosNode := CreateCFDIElement('Conceptos');
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");
        if ServiceCrMemoLine.FindSet() then
            repeat
                ConceptoNode := CreateCFDIElement('Concepto');
                LineAmount := ServiceCrMemoLine.Amount;
                LineDiscount := ServiceCrMemoLine."Line Discount Amount";
                ConceptoNode.SetAttribute('ClaveProdServ', SATUtilities.GetSATClassification(ServiceCrMemoLine.Type, ServiceCrMemoLine."No."));
                ConceptoNode.SetAttribute('NoIdentificacion', ServiceCrMemoLine."No.");
                ConceptoNode.SetAttribute('Cantidad', Format(ServiceCrMemoLine.Quantity, 0, 9));
                ConceptoNode.SetAttribute('ClaveUnidad', SATUtilities.GetSATUnitofMeasure(ServiceCrMemoLine."Unit of Measure Code"));
                ConceptoNode.SetAttribute('Unidad', ServiceCrMemoLine."Unit of Measure Code");
                ConceptoNode.SetAttribute('Descripcion', EncodeString(ServiceCrMemoLine.Description));
                ConceptoNode.SetAttribute('ValorUnitario', FormatDecimal(ServiceCrMemoLine."Unit Price", 6));
                ConceptoNode.SetAttribute('Importe', FormatDecimal(LineAmount, 6));
                ConceptoNode.SetAttribute('Descuento', FormatDecimal(LineDiscount, 6));
                TotalDiscount += LineDiscount;
                ConceptoNode.SetAttribute('ObjetoImp', '02');

                if ServiceCrMemoLine."VAT %" <> 0 then begin
                    CalculatedTaxBase += ServiceCrMemoLine.Amount;
                    CalculatedTaxTotal += Round(ServiceCrMemoLine.Amount * ServiceCrMemoLine."VAT %" / 100, 0.000001);
                    SummaryVATPct := ServiceCrMemoLine."VAT %";

                    ImpuestosNode := CreateCFDIElement('Impuestos');
                    TrasladosNode := CreateCFDIElement('Traslados');
                    TrasladoNode := CreateCFDIElement('Traslado');
                    TrasladoNode.SetAttribute('Base', FormatDecimal(ServiceCrMemoLine.Amount, 6));
                    TrasladoNode.SetAttribute('Impuesto', GetTaxCode(ServiceCrMemoLine."VAT %", ServiceCrMemoLine."Amount Including VAT" - ServiceCrMemoLine.Amount));
                    TrasladoNode.SetAttribute('TipoFactor', 'Tasa');
                    TrasladoNode.SetAttribute('TasaOCuota', PadStr(FormatDecimal(ServiceCrMemoLine."VAT %" / 100, 6), 8, '0'));
                    TrasladoNode.SetAttribute('Importe', FormatDecimal(Round(ServiceCrMemoLine.Amount * ServiceCrMemoLine."VAT %" / 100, 0.000001), 6));
                    TrasladosNode.Add(TrasladoNode.AsXmlNode());
                    ImpuestosNode.Add(TrasladosNode.AsXmlNode());
                    ConceptoNode.Add(ImpuestosNode.AsXmlNode());
                end;

                ConceptosNode.Add(ConceptoNode.AsXmlNode());
            until ServiceCrMemoLine.Next() = 0;

        RootNode.Add(ConceptosNode.AsXmlNode());

        TaxTotal := CalculatedTaxTotal;
        RootNode.SetAttribute('Total', FormatAmount(SubTotal + TaxTotal, CurrencyCode));
        if TaxTotal <> 0 then begin
            ImpuestosNode := CreateCFDIElement('Impuestos');
            ImpuestosNode.SetAttribute('TotalImpuestosTrasladados', FormatAmount(TaxTotal, CurrencyCode));
            TrasladosNode := CreateCFDIElement('Traslados');
            TrasladoNode := CreateCFDIElement('Traslado');
            TrasladoNode.SetAttribute('Base', FormatAmount(CalculatedTaxBase, CurrencyCode));
            TrasladoNode.SetAttribute('Impuesto', GetTaxCode(SummaryVATPct, TaxTotal));
            TrasladoNode.SetAttribute('TipoFactor', 'Tasa');
            TrasladoNode.SetAttribute('TasaOCuota', PadStr(FormatDecimal(SummaryVATPct / 100, 6), 8, '0'));
            TrasladoNode.SetAttribute('Importe', FormatAmount(TaxTotal, CurrencyCode));
            TrasladosNode.Add(TrasladoNode.AsXmlNode());
            ImpuestosNode.Add(TrasladosNode.AsXmlNode());
            RootNode.Add(ImpuestosNode.AsXmlNode());
        end;
    end;

    local procedure BuildSalesHeaderNode(var RootNode: XmlElement; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        SATUtilities: Codeunit "SAT Utilities";
        RootXmlNode: XmlNode;
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
        InformacionAduaneraNode: XmlNode;
        NumeroPedimento: Text;
    begin
        CompanyInfo.Get();
        GetCustomer(Customer, SalesHeader."Sell-to Customer No.", false);

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', SalesHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(SalesHeader));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('NoCertificado', '');
        RootNode.SetAttribute('Certificado', '');
        RootNode.SetAttribute('SubTotal', '0');
        RootNode.SetAttribute('Moneda', 'XXX');
        RootNode.SetAttribute('Total', '0');
        RootNode.SetAttribute('TipoDeComprobante', 'T');
        RootNode.SetAttribute('Exportacion', SalesHeader."CFDI Export Code");
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddCompanyIssuerReceiver(RootNode, 'S01');

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Conceptos', '', ConceptosNode);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCFDI(ConceptosNode, 'Concepto', '', ConceptoNode);
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveProdServ', SATUtilities.GetSATClassification(SalesLine.Type, SalesLine."No."));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'NoIdentificacion', SalesLine."No.");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Cantidad', Format(SalesLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(SalesLine."Unit of Measure Code"));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Unidad', SalesLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descripcion', EncodeString(SalesLine.Description));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ValorUnitario', '0');
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Importe', '0');
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ObjetoImp', '01');
                if (not SalesHeader."Foreign Trade") and TryFormatNumeroPedimento(SalesLine."Custom Transit Number", NumeroPedimento) then begin
                    CFDIXMLHelperMX.AddElementCFDI(ConceptoNode, 'InformacionAduanera', '', InformacionAduaneraNode);
                    CFDIXMLHelperMX.AddAttribute(InformacionAduaneraNode, 'NumeroPedimento', NumeroPedimento);
                end;
            until SalesLine.Next() = 0;

        AddCartaPorteComplementNode(RootNode, SalesHeader, SalesLine);
    end;

    local procedure BuildTransferNode(var RootNode: XmlElement; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesShipmentLine: Record "Sales Shipment Line")
    var
        CompanyInfo: Record "Company Information";
        SATUtilities: Codeunit "SAT Utilities";
        RootXmlNode: XmlNode;
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
        InformacionAduaneraNode: XmlNode;
        NumeroPedimento: Text;
    begin
        CompanyInfo.Get();

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', SalesShipmentHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(SalesShipmentHeader));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('NoCertificado', '');
        RootNode.SetAttribute('Certificado', '');
        RootNode.SetAttribute('SubTotal', '0');
        RootNode.SetAttribute('Moneda', 'XXX');
        RootNode.SetAttribute('Total', '0');
        RootNode.SetAttribute('TipoDeComprobante', 'T');
        RootNode.SetAttribute('Exportacion', SalesShipmentHeader."CFDI Export Code");
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddCompanyIssuerReceiver(RootNode, 'S01');

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Conceptos', '', ConceptosNode);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        if SalesShipmentLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCFDI(ConceptosNode, 'Concepto', '', ConceptoNode);
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveProdServ', SATUtilities.GetSATClassification(SalesShipmentLine.Type, SalesShipmentLine."No."));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'NoIdentificacion', SalesShipmentLine."No.");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Cantidad', Format(SalesShipmentLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(SalesShipmentLine."Unit of Measure Code"));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Unidad', SalesShipmentLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descripcion', EncodeString(SalesShipmentLine.Description));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ValorUnitario', '0');
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Importe', '0');
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ObjetoImp', '01');
                if (not SalesShipmentHeader."Foreign Trade") and TryFormatNumeroPedimento(SalesShipmentLine."Custom Transit Number", NumeroPedimento) then begin
                    CFDIXMLHelperMX.AddElementCFDI(ConceptoNode, 'InformacionAduanera', '', InformacionAduaneraNode);
                    CFDIXMLHelperMX.AddAttribute(InformacionAduaneraNode, 'NumeroPedimento', NumeroPedimento);
                end;
            until SalesShipmentLine.Next() = 0;

        AddCartaPorteComplementNode(RootNode, SalesShipmentHeader, SalesShipmentLine);
    end;

    local procedure BuildTransferHeaderNode(var RootNode: XmlElement; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    var
        CompanyInfo: Record "Company Information";
        SATUtilities: Codeunit "SAT Utilities";
        RootXmlNode: XmlNode;
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
        InformacionAduaneraNode: XmlNode;
        NumeroPedimento: Text;
    begin
        CompanyInfo.Get();

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', TransferHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(TransferHeader));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('NoCertificado', '');
        RootNode.SetAttribute('Certificado', '');
        RootNode.SetAttribute('SubTotal', '0');
        RootNode.SetAttribute('Moneda', 'XXX');
        RootNode.SetAttribute('Total', '0');
        RootNode.SetAttribute('TipoDeComprobante', 'T');
        RootNode.SetAttribute('Exportacion', TransferHeader."CFDI Export Code");
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddCompanyIssuerReceiver(RootNode, 'S01');

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Conceptos', '', ConceptosNode);
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        if TransferLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCFDI(ConceptosNode, 'Concepto', '', ConceptoNode);
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveProdServ', SATUtilities.GetSATClassification("Sales Line Type"::Item, TransferLine."Item No."));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'NoIdentificacion', TransferLine."Item No.");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Cantidad', Format(TransferLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(TransferLine."Unit of Measure Code"));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Unidad', TransferLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descripcion', EncodeString(TransferLine.Description));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ValorUnitario', '0');
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Importe', '0');
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ObjetoImp', '01');
                if (not TransferHeader."Foreign Trade") and TryFormatNumeroPedimento(TransferLine."Custom Transit Number", NumeroPedimento) then begin
                    CFDIXMLHelperMX.AddElementCFDI(ConceptoNode, 'InformacionAduanera', '', InformacionAduaneraNode);
                    CFDIXMLHelperMX.AddAttribute(InformacionAduaneraNode, 'NumeroPedimento', NumeroPedimento);
                end;
            until TransferLine.Next() = 0;

        AddCartaPorteComplementNode(RootNode, TransferHeader, TransferLine);
    end;

    local procedure BuildTransferNode(var RootNode: XmlElement; var TransferShipment: Record "Transfer Shipment Header"; var TransferShipmentLine: Record "Transfer Shipment Line")
    var
        CompanyInfo: Record "Company Information";
        SATUtilities: Codeunit "SAT Utilities";
        RootXmlNode: XmlNode;
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
        InformacionAduaneraNode: XmlNode;
        NumeroPedimento: Text;
    begin
        CompanyInfo.Get();

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', TransferShipment."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(TransferShipment));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('NoCertificado', '');
        RootNode.SetAttribute('Certificado', '');
        RootNode.SetAttribute('SubTotal', '0');
        RootNode.SetAttribute('Moneda', 'XXX');
        RootNode.SetAttribute('Total', '0');
        RootNode.SetAttribute('TipoDeComprobante', 'T');
        RootNode.SetAttribute('Exportacion', TransferShipment."CFDI Export Code");
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddCompanyIssuerReceiver(RootNode, 'S01');

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Conceptos', '', ConceptosNode);
        TransferShipmentLine.SetRange("Document No.", TransferShipment."No.");
        if TransferShipmentLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCFDI(ConceptosNode, 'Concepto', '', ConceptoNode);
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveProdServ', SATUtilities.GetSATClassification("Sales Line Type"::Item, TransferShipmentLine."Item No."));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'NoIdentificacion', TransferShipmentLine."Item No.");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Cantidad', Format(TransferShipmentLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(TransferShipmentLine."Unit of Measure Code"));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Unidad', TransferShipmentLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descripcion', EncodeString(TransferShipmentLine.Description));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ValorUnitario', '0');
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Importe', '0');
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ObjetoImp', '01');
                if (not TransferShipment."Foreign Trade") and TryFormatNumeroPedimento(TransferShipmentLine."Custom Transit Number", NumeroPedimento) then begin
                    CFDIXMLHelperMX.AddElementCFDI(ConceptoNode, 'InformacionAduanera', '', InformacionAduaneraNode);
                    CFDIXMLHelperMX.AddAttribute(InformacionAduaneraNode, 'NumeroPedimento', NumeroPedimento);
                end;
            until TransferShipmentLine.Next() = 0;

        AddCartaPorteComplementNode(RootNode, TransferShipment, TransferShipmentLine);
    end;

    local procedure AddCompanyIssuerReceiver(var RootNode: XmlElement; UsageCode: Code[10])
    var
        CompanyInfo: Record "Company Information";
        RootXmlNode: XmlNode;
        EmisorNode: XmlNode;
        ReceptorNode: XmlNode;
    begin
        CompanyInfo.Get();

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Emisor', '', EmisorNode);
        CFDIXMLHelperMX.AddAttribute(EmisorNode, 'Rfc', CompanyInfo."RFC Number");
        CFDIXMLHelperMX.AddAttribute(EmisorNode, 'Nombre', CompanyInfo.Name);
        CFDIXMLHelperMX.AddAttribute(EmisorNode, 'RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");

        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Receptor', '', ReceptorNode);
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'Rfc', CompanyInfo."RFC Number");
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'Nombre', CompanyInfo.Name);
        if UsageCode = '' then
            UsageCode := 'S01';
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'UsoCFDI', UsageCode);
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'RegimenFiscalReceptor', CompanyInfo."SAT Tax Regime Classification");
    end;

    local procedure AddCartaPorteComplementNode(var RootNode: XmlElement; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesShipmentLine: Record "Sales Shipment Line")
    var
        Location: Record Location;
        Customer: Record Customer;
        Employee: Record Employee;
        CFDITransportOperator: Record "CFDI Transport Operator";
        Item: Record Item;
        SATUtilities: Codeunit "SAT Utilities";
        XmlDoc: XmlDocument;
        RootXmlNode: XmlNode;
        ComplementoXmlNode: XmlNode;
        CartaPorteNode: XmlNode;
        RegimenesNode: XmlNode;
        RegimenNode: XmlNode;
        UbicacionesNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        FiguraNode: XmlNode;
        HazardousMatExists: Boolean;
        GrossWeight: Decimal;
        SATClassificationCode: Code[10];
        DestinationRFCNo: Text;
        ForeignRegId: Text;
        ResidenciaFiscal: Text;
        OriginLocationCode: Code[10];
    begin
        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Complemento', '', ComplementoXmlNode);
        RootNode.GetDocument(XmlDoc);
        AddNodeComercioExterior(ComplementoXmlNode, SalesShipmentHeader, SalesShipmentLine);
        CFDIXMLHelperMX.AddElementCartaPorte(ComplementoXmlNode, 'CartaPorte', '', '', CartaPorteNode);

        if SalesShipmentHeader."Identifier IdCCP" = '' then
            SalesShipmentHeader."Identifier IdCCP" := 'CCC' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}'), 4);

        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'Version', '3.1');
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'IdCCP', SalesShipmentHeader."Identifier IdCCP");
        if SalesShipmentHeader."Foreign Trade" then begin
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TranspInternac', 'Sí');
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'EntradaSalidaMerc', 'Salida');
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'PaisOrigenDestino', SATUtilities.GetSATCountryCode(SalesShipmentHeader."Ship-to Country/Region Code"));
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'ViaEntradaSalida', '01');
        end else
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TranspInternac', 'No');
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TotalDistRec', FormatDecimal(SalesShipmentHeader."Transit Distance", 6));

        if SalesShipmentHeader."Foreign Trade" then begin
            CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'RegimenesAduaneros', '', '', RegimenesNode);
            CFDIXMLHelperMX.AddElementCartaPorte(RegimenesNode, 'RegimenAduaneroCCP', '', '', RegimenNode);
            CFDIXMLHelperMX.AddAttribute(RegimenNode, 'RegimenAduanero', SalesShipmentHeader."SAT Customs Regime");
        end;

        CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'Ubicaciones', '', '', UbicacionesNode);

        OriginLocationCode := GetSalesShipmentOriginLocationCode(SalesShipmentHeader, SalesShipmentLine);
        Location.Get(OriginLocationCode);
        AddNodeCartaPorteUbicacion(
            'Origen',
            Location,
            'OR',
            CompanyInformation."RFC Number",
            '',
            '',
            FormatDateTime(SalesShipmentHeader."Transit-from Date/Time"),
            '',
            XmlDoc,
            UbicacionesNode,
            UbicacionesNode);

        GetCustomer(Customer, SalesShipmentHeader."Sell-to Customer No.", false);
        DestinationRFCNo := Customer."RFC No.";
        if SalesShipmentHeader."Foreign Trade" and (Customer."Country/Region Code" <> '') and (Customer."Country/Region Code" <> 'MEX') then begin
            ForeignRegId := Customer."VAT Registration No.";
            ResidenciaFiscal := SATUtilities.GetSATCountryCode(Customer."Country/Region Code");
        end;

        AddNodeCartaPorteUbicacionAddress(
            'Destino',
            SalesShipmentHeader."SAT Address ID",
            SalesShipmentHeader."Ship-to Address",
            'DE',
            DestinationRFCNo,
            ForeignRegId,
            ResidenciaFiscal,
            FormatDateTime(SalesShipmentHeader."Transit-from Date/Time" + (SalesShipmentHeader."Transit Hours" * 60 * 60 * 1000)),
            FormatDecimal(SalesShipmentHeader."Transit Distance", 6),
            UbicacionesNode);

        CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'Mercancias', '', '', MercanciasNode);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        GrossWeight := 0;
        if SalesShipmentLine.FindSet() then
            repeat
                GrossWeight += SalesShipmentLine.Quantity * SalesShipmentLine."Gross Weight";
            until SalesShipmentLine.Next() = 0;
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'UnidadPeso', SalesShipmentHeader."SAT Weight Unit Of Measure");
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'NumTotalMercancias', FormatDecimal(SalesShipmentLine.Count, 0));
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'PesoBrutoTotal', FormatDecimal(GrossWeight, 3));
        if SalesShipmentLine.FindSet() then
            repeat
                Item.Get(SalesShipmentLine."No.");
                CFDIXMLHelperMX.AddElementCartaPorte(MercanciasNode, 'Mercancia', '', '', MercanciaNode);
                SATClassificationCode := SATUtilities.GetSATClassification(SalesShipmentLine.Type, SalesShipmentLine."No.");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'BienesTransp', SATClassificationCode);
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Descripcion', EncodeString(SalesShipmentLine.Description));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Cantidad', Format(SalesShipmentLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(SalesShipmentLine."Unit of Measure Code"));
                if Item."SAT Hazardous Material" <> '' then begin
                    HazardousMatExists := true;
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'MaterialPeligroso', 'Sí');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'CveMaterialPeligroso', Item."SAT Hazardous Material");
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Embalaje', Item."SAT Packaging Type");
                end else
                    if IsHazardousMaterialMandatory(SATClassificationCode) then
                        CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'MaterialPeligroso', 'No');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'PesoEnKg', FormatDecimal(SalesShipmentLine.Quantity * SalesShipmentLine."Gross Weight", 3));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorMercancia', '0');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Moneda', 'MXN');
                if SalesShipmentHeader."Foreign Trade" then begin
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'UUIDComercioExt', '00000000-0000-0000-0000-000000000000');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'TipoMateria', Item."SAT Material Type");
                    if SalesShipmentLine."SAT Customs Document Type" <> '' then
                        AddNodeDocumentacionAduanera(MercanciaNode, SalesShipmentLine."SAT Customs Document Type", 'identifier');
                end;
            until SalesShipmentLine.Next() = 0;

        AddNodeCartaPorteAutotransporte(MercanciasNode, SalesShipmentHeader."Vehicle Code", SalesShipmentHeader."Trailer 1", SalesShipmentHeader."Trailer 2", SalesShipmentHeader."Insurer Name", SalesShipmentHeader."Insurer Policy Number", HazardousMatExists, SalesShipmentHeader."Medical Insurer Name", SalesShipmentHeader."Medical Ins. Policy Number");
        AddNodeCartaPorteFiguraTransporte(FiguraNode, Database::"Sales Shipment Header", SalesShipmentHeader."No.", CartaPorteNode, CFDITransportOperator, Employee);
    end;

    local procedure AddCartaPorteComplementNode(var RootNode: XmlElement; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Location: Record Location;
        Customer: Record Customer;
        Employee: Record Employee;
        CFDITransportOperator: Record "CFDI Transport Operator";
        Item: Record Item;
        SATUtilities: Codeunit "SAT Utilities";
        XmlDoc: XmlDocument;
        RootXmlNode: XmlNode;
        ComplementoXmlNode: XmlNode;
        CartaPorteNode: XmlNode;
        RegimenesNode: XmlNode;
        RegimenNode: XmlNode;
        UbicacionesNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        FiguraNode: XmlNode;
        HazardousMatExists: Boolean;
        GrossWeight: Decimal;
        SATClassificationCode: Code[10];
        DestinationRFCNo: Text;
        ForeignRegId: Text;
        ResidenciaFiscal: Text;
        OriginLocationCode: Code[10];
        IdCCP: Text;
    begin
        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Complemento', '', ComplementoXmlNode);
        RootNode.GetDocument(XmlDoc);
        if SalesHeader."Foreign Trade" then
            AddNodeComercioExterior(ComplementoXmlNode, SalesHeader, SalesLine);
        CFDIXMLHelperMX.AddElementCartaPorte(ComplementoXmlNode, 'CartaPorte', '', '', CartaPorteNode);

        IdCCP := 'CCC' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}'), 4);
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'Version', '3.1');
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'IdCCP', IdCCP);
        if SalesHeader."Foreign Trade" then begin
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TranspInternac', 'Sí');
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'EntradaSalidaMerc', 'Salida');
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'PaisOrigenDestino', SATUtilities.GetSATCountryCode(SalesHeader."Ship-to Country/Region Code"));
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'ViaEntradaSalida', '01');
        end else
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TranspInternac', 'No');
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TotalDistRec', FormatDecimal(SalesHeader."Transit Distance", 6));

        if SalesHeader."Foreign Trade" then begin
            CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'RegimenesAduaneros', '', '', RegimenesNode);
            CFDIXMLHelperMX.AddElementCartaPorte(RegimenesNode, 'RegimenAduaneroCCP', '', '', RegimenNode);
            CFDIXMLHelperMX.AddAttribute(RegimenNode, 'RegimenAduanero', SalesHeader."SAT Customs Regime");
        end;

        CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'Ubicaciones', '', '', UbicacionesNode);
        OriginLocationCode := GetSalesHeaderOriginLocationCode(SalesHeader, SalesLine);
        Location.Get(OriginLocationCode);
        AddNodeCartaPorteUbicacion(
            'Origen',
            Location,
            'OR',
            CompanyInformation."RFC Number",
            '',
            '',
            FormatDateTime(SalesHeader."Transit-from Date/Time"),
            '',
            XmlDoc,
            UbicacionesNode,
            UbicacionesNode);

        GetCustomer(Customer, SalesHeader."Sell-to Customer No.", false);
        DestinationRFCNo := Customer."RFC No.";
        if SalesHeader."Foreign Trade" and (Customer."Country/Region Code" <> '') and (Customer."Country/Region Code" <> 'MEX') then begin
            ForeignRegId := Customer."VAT Registration No.";
            ResidenciaFiscal := SATUtilities.GetSATCountryCode(Customer."Country/Region Code");
        end;

        AddNodeCartaPorteUbicacionAddress(
            'Destino',
            SalesHeader."SAT Address ID",
            SalesHeader."Ship-to Address",
            'DE',
            DestinationRFCNo,
            ForeignRegId,
            ResidenciaFiscal,
            FormatDateTime(SalesHeader."Transit-from Date/Time" + (SalesHeader."Transit Hours" * 60 * 60 * 1000)),
            FormatDecimal(SalesHeader."Transit Distance", 6),
            UbicacionesNode);

        CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'Mercancias', '', '', MercanciasNode);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        GrossWeight := 0;
        if SalesLine.FindSet() then
            repeat
                GrossWeight += SalesLine.Quantity * SalesLine."Gross Weight";
            until SalesLine.Next() = 0;
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'UnidadPeso', SalesHeader."SAT Weight Unit Of Measure");
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'NumTotalMercancias', FormatDecimal(SalesLine.Count, 0));
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'PesoBrutoTotal', FormatDecimal(GrossWeight, 3));
        if SalesLine.FindSet() then
            repeat
                Item.Get(SalesLine."No.");
                CFDIXMLHelperMX.AddElementCartaPorte(MercanciasNode, 'Mercancia', '', '', MercanciaNode);
                SATClassificationCode := SATUtilities.GetSATClassification(SalesLine.Type, SalesLine."No.");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'BienesTransp', SATClassificationCode);
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Descripcion', EncodeString(SalesLine.Description));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Cantidad', Format(SalesLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(SalesLine."Unit of Measure Code"));
                if Item."SAT Hazardous Material" <> '' then begin
                    HazardousMatExists := true;
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'MaterialPeligroso', 'Sí');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'CveMaterialPeligroso', Item."SAT Hazardous Material");
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Embalaje', Item."SAT Packaging Type");
                end else
                    if IsHazardousMaterialMandatory(SATClassificationCode) then
                        CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'MaterialPeligroso', 'No');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'PesoEnKg', FormatDecimal(SalesLine.Quantity * SalesLine."Gross Weight", 3));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorMercancia', '0');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Moneda', 'MXN');
                if SalesHeader."Foreign Trade" then begin
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'UUIDComercioExt', '00000000-0000-0000-0000-000000000000');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'TipoMateria', Item."SAT Material Type");
                    if SalesLine."SAT Customs Document Type" <> '' then
                        AddNodeDocumentacionAduanera(MercanciaNode, SalesLine."SAT Customs Document Type", 'identifier');
                end;
            until SalesLine.Next() = 0;

        AddNodeCartaPorteAutotransporte(MercanciasNode, SalesHeader."Vehicle Code", SalesHeader."Trailer 1", SalesHeader."Trailer 2", SalesHeader."Insurer Name", SalesHeader."Insurer Policy Number", HazardousMatExists, SalesHeader."Medical Insurer Name", SalesHeader."Medical Ins. Policy Number");
        AddNodeCartaPorteFiguraTransporte(FiguraNode, Database::"Sales Header", SalesHeader."No.", CartaPorteNode, CFDITransportOperator, Employee);
    end;

    local procedure GetSalesShipmentOriginLocationCode(SalesShipmentHeader: Record "Sales Shipment Header"; var SalesShipmentLine: Record "Sales Shipment Line"): Code[10]
    begin
        if SalesShipmentHeader."Location Code" <> '' then
            exit(SalesShipmentHeader."Location Code");

        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetFilter("Location Code", '<>%1', '');
        if SalesShipmentLine.FindFirst() then
            exit(SalesShipmentLine."Location Code");

        exit('');
    end;

    local procedure GetSalesHeaderOriginLocationCode(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Code[10]
    begin
        if SalesHeader."Location Code" <> '' then
            exit(SalesHeader."Location Code");

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        if SalesLine.FindFirst() then
            exit(SalesLine."Location Code");

        exit('');
    end;

    local procedure AddCartaPorteComplementNode(var RootNode: XmlElement; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Employee: Record Employee;
        CFDITransportOperator: Record "CFDI Transport Operator";
        Item: Record Item;
        SATUtilities: Codeunit "SAT Utilities";
        XmlDoc: XmlDocument;
        RootXmlNode: XmlNode;
        ComplementoXmlNode: XmlNode;
        CartaPorteNode: XmlNode;
        RegimenesNode: XmlNode;
        RegimenNode: XmlNode;
        UbicacionesNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        FiguraNode: XmlNode;
        HazardousMatExists: Boolean;
        GrossWeight: Decimal;
        SATClassificationCode: Code[10];
        IdCCP: Text;
    begin
        LocationTo.Get(TransferHeader."Transfer-to Code");

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Complemento', '', ComplementoXmlNode);
        RootNode.GetDocument(XmlDoc);
        if TransferHeader."Foreign Trade" then
            AddNodeComercioExterior(ComplementoXmlNode, TransferHeader, TransferLine);
        CFDIXMLHelperMX.AddElementCartaPorte(ComplementoXmlNode, 'CartaPorte', '', '', CartaPorteNode);

        IdCCP := 'CCC' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}'), 4);
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'Version', '3.1');
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'IdCCP', IdCCP);
        if TransferHeader."Foreign Trade" then begin
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TranspInternac', 'Sí');
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'EntradaSalidaMerc', 'Salida');
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'PaisOrigenDestino', SATUtilities.GetSATCountryCode(LocationTo."Country/Region Code"));
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'ViaEntradaSalida', '01');
        end else
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TranspInternac', 'No');
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TotalDistRec', FormatDecimal(TransferHeader."Transit Distance", 6));

        if TransferHeader."Foreign Trade" then begin
            CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'RegimenesAduaneros', '', '', RegimenesNode);
            CFDIXMLHelperMX.AddElementCartaPorte(RegimenesNode, 'RegimenAduaneroCCP', '', '', RegimenNode);
            CFDIXMLHelperMX.AddAttribute(RegimenNode, 'RegimenAduanero', TransferHeader."SAT Customs Regime");
        end;

        CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'Ubicaciones', '', '', UbicacionesNode);
        LocationFrom.Get(TransferHeader."Transfer-from Code");
        AddNodeCartaPorteUbicacion(
            'Origen',
            LocationFrom,
            'OR',
            CompanyInformation."RFC Number",
            '',
            '',
            FormatDateTime(TransferHeader."Transit-from Date/Time"),
            '',
            XmlDoc,
            UbicacionesNode,
            UbicacionesNode);
        AddNodeCartaPorteUbicacion(
            'Destino',
            LocationTo,
            'DE',
            CompanyInformation."RFC Number",
            '',
            '',
            FormatDateTime(TransferHeader."Transit-from Date/Time" + (TransferHeader."Transit Hours" * 60 * 60 * 1000)),
            FormatDecimal(TransferHeader."Transit Distance", 6),
            XmlDoc,
            UbicacionesNode,
            UbicacionesNode);

        CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'Mercancias', '', '', MercanciasNode);
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        GrossWeight := 0;
        if TransferLine.FindSet() then
            repeat
                GrossWeight += TransferLine.Quantity * TransferLine."Gross Weight";
            until TransferLine.Next() = 0;
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'UnidadPeso', TransferHeader."SAT Weight Unit Of Measure");
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'NumTotalMercancias', FormatDecimal(TransferLine.Count, 0));
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'PesoBrutoTotal', FormatDecimal(GrossWeight, 3));
        if TransferLine.FindSet() then
            repeat
                Item.Get(TransferLine."Item No.");
                CFDIXMLHelperMX.AddElementCartaPorte(MercanciasNode, 'Mercancia', '', '', MercanciaNode);
                SATClassificationCode := SATUtilities.GetSATClassification("Sales Line Type"::Item, TransferLine."Item No.");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'BienesTransp', SATClassificationCode);
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Descripcion', EncodeString(TransferLine.Description));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Cantidad', Format(TransferLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(TransferLine."Unit of Measure Code"));
                if Item."SAT Hazardous Material" <> '' then begin
                    HazardousMatExists := true;
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'MaterialPeligroso', 'Sí');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'CveMaterialPeligroso', Item."SAT Hazardous Material");
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Embalaje', Item."SAT Packaging Type");
                end else
                    if IsHazardousMaterialMandatory(SATClassificationCode) then
                        CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'MaterialPeligroso', 'No');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'PesoEnKg', FormatDecimal(TransferLine.Quantity * TransferLine."Gross Weight", 3));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorMercancia', '0');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Moneda', 'MXN');
                if TransferHeader."Foreign Trade" then begin
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'UUIDComercioExt', '00000000-0000-0000-0000-000000000000');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'TipoMateria', Item."SAT Material Type");
                    if TransferLine."SAT Customs Document Type" <> '' then
                        AddNodeDocumentacionAduanera(MercanciaNode, TransferLine."SAT Customs Document Type", 'identifier');
                end;
            until TransferLine.Next() = 0;

        AddNodeCartaPorteAutotransporte(MercanciasNode, TransferHeader."Vehicle Code", TransferHeader."Trailer 1", TransferHeader."Trailer 2", TransferHeader."Insurer Name", TransferHeader."Insurer Policy Number", HazardousMatExists, TransferHeader."Medical Insurer Name", TransferHeader."Medical Ins. Policy Number");
        AddNodeCartaPorteFiguraTransporte(FiguraNode, Database::"Transfer Header", TransferHeader."No.", CartaPorteNode, CFDITransportOperator, Employee);
    end;

    local procedure AddCartaPorteComplementNode(var RootNode: XmlElement; var TransferShipmentHeader: Record "Transfer Shipment Header"; var TransferShipmentLine: Record "Transfer Shipment Line")
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Employee: Record Employee;
        CFDITransportOperator: Record "CFDI Transport Operator";
        Item: Record Item;
        SATUtilities: Codeunit "SAT Utilities";
        XmlDoc: XmlDocument;
        RootXmlNode: XmlNode;
        ComplementoXmlNode: XmlNode;
        CartaPorteNode: XmlNode;
        RegimenesNode: XmlNode;
        RegimenNode: XmlNode;
        UbicacionesNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        FiguraNode: XmlNode;
        HazardousMatExists: Boolean;
        GrossWeight: Decimal;
        SATClassificationCode: Code[10];
    begin
        LocationTo.Get(TransferShipmentHeader."Transfer-to Code");

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Complemento', '', ComplementoXmlNode);
        RootNode.GetDocument(XmlDoc);
        AddNodeComercioExterior(ComplementoXmlNode, TransferShipmentHeader, TransferShipmentLine, LocationFrom, LocationTo);
        CFDIXMLHelperMX.AddElementCartaPorte(ComplementoXmlNode, 'CartaPorte', '', '', CartaPorteNode);

        if TransferShipmentHeader."Identifier IdCCP" = '' then
            TransferShipmentHeader."Identifier IdCCP" := 'CCC' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}'), 4);

        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'Version', '3.1');
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'IdCCP', TransferShipmentHeader."Identifier IdCCP");
        if TransferShipmentHeader."Foreign Trade" then begin
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TranspInternac', 'Sí');
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'EntradaSalidaMerc', 'Salida');
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'PaisOrigenDestino', SATUtilities.GetSATCountryCode(LocationTo."Country/Region Code"));
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'ViaEntradaSalida', '01');
        end else
            CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TranspInternac', 'No');
        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'TotalDistRec', FormatDecimal(TransferShipmentHeader."Transit Distance", 6));

        if TransferShipmentHeader."Foreign Trade" then begin
            CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'RegimenesAduaneros', '', '', RegimenesNode);
            CFDIXMLHelperMX.AddElementCartaPorte(RegimenesNode, 'RegimenAduaneroCCP', '', '', RegimenNode);
            CFDIXMLHelperMX.AddAttribute(RegimenNode, 'RegimenAduanero', TransferShipmentHeader."SAT Customs Regime");
        end;

        CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'Ubicaciones', '', '', UbicacionesNode);
        LocationFrom.Get(TransferShipmentHeader."Transfer-from Code");
        AddNodeCartaPorteUbicacion(
            'Origen',
            LocationFrom,
            'OR',
            CompanyInformation."RFC Number",
            '',
            '',
            FormatDateTime(TransferShipmentHeader."Transit-from Date/Time"),
            '',
            XmlDoc,
            UbicacionesNode,
            UbicacionesNode);
        AddNodeCartaPorteUbicacion(
            'Destino',
            LocationTo,
            'DE',
            CompanyInformation."RFC Number",
            '',
            '',
            FormatDateTime(TransferShipmentHeader."Transit-from Date/Time" + (TransferShipmentHeader."Transit Hours" * 60 * 60 * 1000)),
            FormatDecimal(TransferShipmentHeader."Transit Distance", 6),
            XmlDoc,
            UbicacionesNode,
            UbicacionesNode);

        CFDIXMLHelperMX.AddElementCartaPorte(CartaPorteNode, 'Mercancias', '', '', MercanciasNode);
        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
        GrossWeight := 0;
        if TransferShipmentLine.FindSet() then
            repeat
                GrossWeight += TransferShipmentLine.Quantity * TransferShipmentLine."Gross Weight";
            until TransferShipmentLine.Next() = 0;
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'UnidadPeso', TransferShipmentHeader."SAT Weight Unit Of Measure");
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'NumTotalMercancias', FormatDecimal(TransferShipmentLine.Count, 0));
        CFDIXMLHelperMX.AddAttribute(MercanciasNode, 'PesoBrutoTotal', FormatDecimal(GrossWeight, 3));
        if TransferShipmentLine.FindSet() then
            repeat
                Item.Get(TransferShipmentLine."Item No.");
                CFDIXMLHelperMX.AddElementCartaPorte(MercanciasNode, 'Mercancia', '', '', MercanciaNode);
                SATClassificationCode := SATUtilities.GetSATClassification("Sales Line Type"::Item, TransferShipmentLine."Item No.");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'BienesTransp', SATClassificationCode);
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Descripcion', EncodeString(TransferShipmentLine.Description));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Cantidad', Format(TransferShipmentLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(TransferShipmentLine."Unit of Measure Code"));
                if Item."SAT Hazardous Material" <> '' then begin
                    HazardousMatExists := true;
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'MaterialPeligroso', 'Sí');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'CveMaterialPeligroso', Item."SAT Hazardous Material");
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Embalaje', Item."SAT Packaging Type");
                end else
                    if IsHazardousMaterialMandatory(SATClassificationCode) then
                        CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'MaterialPeligroso', 'No');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'PesoEnKg', FormatDecimal(TransferShipmentLine.Quantity * TransferShipmentLine."Gross Weight", 3));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorMercancia', '0');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'Moneda', 'MXN');
                if TransferShipmentHeader."Foreign Trade" then begin
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'UUIDComercioExt', '00000000-0000-0000-0000-000000000000');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'TipoMateria', Item."SAT Material Type");
                    if TransferShipmentLine."SAT Customs Document Type" <> '' then
                        AddNodeDocumentacionAduanera(MercanciaNode, TransferShipmentLine."SAT Customs Document Type", 'identifier');
                end;
            until TransferShipmentLine.Next() = 0;

        AddNodeCartaPorteAutotransporte(MercanciasNode, TransferShipmentHeader."Vehicle Code", TransferShipmentHeader."Trailer 1", TransferShipmentHeader."Trailer 2", TransferShipmentHeader."Insurer Name", TransferShipmentHeader."Insurer Policy Number", HazardousMatExists, TransferShipmentHeader."Medical Insurer Name", TransferShipmentHeader."Medical Ins. Policy Number");
        AddNodeCartaPorteFiguraTransporte(FiguraNode, Database::"Transfer Shipment Header", TransferShipmentHeader."No.", CartaPorteNode, CFDITransportOperator, Employee);
    end;

    local procedure AddNodeCartaPorteUbicacionAddress(TipoUbicacion: Text; SATAddressId: Integer; AddressTxt: Text; LocationPrefix: Text[2]; RFCNo: Text; ForeignRegId: Text; ResidenciaFiscal: Text; FechaHoraSalidaLlegada: Text; DistanciaRecorrida: Text; XMLCurrNode: XmlNode)
    var
        UbicacionNode: XmlNode;
        DomicilioNode: XmlNode;
    begin
        CFDIXMLHelperMX.AddElementCartaPorte(XMLCurrNode, 'Ubicacion', '', '', UbicacionNode);
        CFDIXMLHelperMX.AddAttribute(UbicacionNode, 'TipoUbicacion', TipoUbicacion);
        CFDIXMLHelperMX.AddAttribute(UbicacionNode, 'RFCRemitenteDestinatario', RFCNo);
        if ForeignRegId <> '' then begin
            CFDIXMLHelperMX.AddAttribute(UbicacionNode, 'NumRegIdTrib', ForeignRegId);
            CFDIXMLHelperMX.AddAttribute(UbicacionNode, 'ResidenciaFiscal', ResidenciaFiscal);
        end;
        CFDIXMLHelperMX.AddAttribute(UbicacionNode, 'FechaHoraSalidaLlegada', FechaHoraSalidaLlegada);
        if DistanciaRecorrida <> '' then
            CFDIXMLHelperMX.AddAttribute(UbicacionNode, 'DistanciaRecorrida', DistanciaRecorrida);

        CFDIXMLHelperMX.AddElementCartaPorte(UbicacionNode, 'Domicilio', '', '', DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(SATAddressId, AddressTxt, DomicilioNode);
    end;

    local procedure AddNodeComercioExterior(XMLCurrNode: XmlNode; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Location: Record Location;
        Item: Record Item;
        UOM: Record "Unit of Measure";
        SATUtilities: Codeunit "SAT Utilities";
        ComercioExteriorNode: XmlNode;
        EmisorNode: XmlNode;
        ReceptorNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        DomicilioNode: XmlNode;
        LineAmount: Decimal;
        SumUSD: Decimal;
        LineCount: Integer;
        OriginLocationCode: Code[10];
    begin
        if not SalesHeader."Foreign Trade" then
            exit;

        GetCustomer(Customer, SalesHeader."Sell-to Customer No.", false);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        LineCount := SalesLine.Count();
        if LineCount = 0 then
            exit;

        CFDIXMLHelperMX.AddElementCCE(XMLCurrNode, 'ComercioExterior', '', CFDIComercioExteriorNamespaceTxt, ComercioExteriorNode);
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Version', '2.0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'MotivoTraslado', SalesHeader."SAT Transfer Reason");
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'ClaveDePedimento', 'A1');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'CertificadoOrigen', '0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Incoterm', SalesHeader."SAT International Trade Term");
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TipoCambioUSD', FormatDecimal(SalesHeader."Exchange Rate USD", 6));
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TotalUSD', '0');

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Emisor', '', CFDIComercioExteriorNamespaceTxt, EmisorNode);
        CFDIXMLHelperMX.AddElementCCE(EmisorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        OriginLocationCode := GetSalesHeaderOriginLocationCode(SalesHeader, SalesLine);
        Location.Get(OriginLocationCode);
        CFDIXMLHelperMX.AddNodeDomicilio(Location."SAT Address ID", Location.Address, DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Receptor', '', CFDIComercioExteriorNamespaceTxt, ReceptorNode);
        if (SATUtilities.GetSATCountryCode(Customer."Country/Region Code") <> 'MEX') and (Customer."RFC No." = 'XEXX010101000') then
            CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'NumRegIdTrib', Customer."VAT Registration No.");
        CFDIXMLHelperMX.AddElementCCE(ReceptorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(SalesHeader."SAT Address ID", SalesHeader."Ship-to Address", DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Mercancias', '', CFDIComercioExteriorNamespaceTxt, MercanciasNode);
        if SalesLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCCE(MercanciasNode, 'Mercancia', '', CFDIComercioExteriorNamespaceTxt, MercanciaNode);
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'NoIdentificacion', SalesLine."No.");
                if Item.Get(SalesLine."No.") and (Item."Tariff No." <> '') then
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'CantidadAduana', Format(SalesLine.Quantity, 0, 9));
                UOM.Get(SalesLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'UnidadAduana', UOM."SAT Customs Unit");
                LineAmount := SalesLine.Quantity * SalesLine."Unit Price";
                if (SalesHeader."Exchange Rate USD" <> 0) and (SalesLine.Quantity <> 0) then begin
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorUnitarioAduana', FormatDecimal(SalesLine."Unit Price" / SalesHeader."Exchange Rate USD", 6));
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorDolares', FormatDecimal(LineAmount / SalesHeader."Exchange Rate USD", 4));
                    SumUSD += LineAmount / SalesHeader."Exchange Rate USD";
                end else begin
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorUnitarioAduana', '0');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorDolares', '0');
                end;
            until SalesLine.Next() = 0;

        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TotalUSD', FormatDecimal(SumUSD, 2));
    end;

    local procedure AddNodeComercioExterior(XMLCurrNode: XmlNode; SalesShipmentHeader: Record "Sales Shipment Header"; var SalesShipmentLine: Record "Sales Shipment Line")
    var
        Customer: Record Customer;
        Location: Record Location;
        Item: Record Item;
        UOM: Record "Unit of Measure";
        SATUtilities: Codeunit "SAT Utilities";
        ComercioExteriorNode: XmlNode;
        EmisorNode: XmlNode;
        ReceptorNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        DomicilioNode: XmlNode;
        LineAmount: Decimal;
        SumUSD: Decimal;
        LineCount: Integer;
        OriginLocationCode: Code[10];
    begin
        if not SalesShipmentHeader."Foreign Trade" then
            exit;

        GetCustomer(Customer, SalesShipmentHeader."Sell-to Customer No.", false);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        LineCount := SalesShipmentLine.Count();
        if LineCount = 0 then
            exit;

        CFDIXMLHelperMX.AddElementCCE(XMLCurrNode, 'ComercioExterior', '', CFDIComercioExteriorNamespaceTxt, ComercioExteriorNode);
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Version', '2.0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'MotivoTraslado', SalesShipmentHeader."SAT Transfer Reason");
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'ClaveDePedimento', 'A1');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'CertificadoOrigen', '0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Incoterm', SalesShipmentHeader."SAT International Trade Term");
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TipoCambioUSD', FormatDecimal(SalesShipmentHeader."Exchange Rate USD", 6));
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TotalUSD', '0');

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Emisor', '', CFDIComercioExteriorNamespaceTxt, EmisorNode);
        CFDIXMLHelperMX.AddElementCCE(EmisorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        OriginLocationCode := GetSalesShipmentOriginLocationCode(SalesShipmentHeader, SalesShipmentLine);
        Location.Get(OriginLocationCode);
        CFDIXMLHelperMX.AddNodeDomicilio(Location."SAT Address ID", Location.Address, DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Receptor', '', CFDIComercioExteriorNamespaceTxt, ReceptorNode);
        if (SATUtilities.GetSATCountryCode(Customer."Country/Region Code") <> 'MEX') and (Customer."RFC No." = 'XEXX010101000') then
            CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'NumRegIdTrib', Customer."VAT Registration No.");
        CFDIXMLHelperMX.AddElementCCE(ReceptorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(SalesShipmentHeader."SAT Address ID", SalesShipmentHeader."Ship-to Address", DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Mercancias', '', CFDIComercioExteriorNamespaceTxt, MercanciasNode);
        if SalesShipmentLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCCE(MercanciasNode, 'Mercancia', '', CFDIComercioExteriorNamespaceTxt, MercanciaNode);
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'NoIdentificacion', SalesShipmentLine."No.");
                if Item.Get(SalesShipmentLine."No.") and (Item."Tariff No." <> '') then
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'CantidadAduana', Format(SalesShipmentLine.Quantity, 0, 9));
                UOM.Get(SalesShipmentLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'UnidadAduana', UOM."SAT Customs Unit");
                LineAmount := SalesShipmentLine.Quantity * SalesShipmentLine."Unit Price";
                if (SalesShipmentHeader."Exchange Rate USD" <> 0) and (SalesShipmentLine.Quantity <> 0) then begin
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorUnitarioAduana', FormatDecimal(SalesShipmentLine."Unit Price" / SalesShipmentHeader."Exchange Rate USD", 6));
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorDolares', FormatDecimal(LineAmount / SalesShipmentHeader."Exchange Rate USD", 4));
                    SumUSD += LineAmount / SalesShipmentHeader."Exchange Rate USD";
                end else begin
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorUnitarioAduana', '0');
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorDolares', '0');
                end;
            until SalesShipmentLine.Next() = 0;

        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TotalUSD', FormatDecimal(SumUSD, 2));
    end;

    local procedure AddNodeComercioExterior(XMLCurrNode: XmlNode; TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    var
        Item: Record Item;
        UOM: Record "Unit of Measure";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        ComercioExteriorNode: XmlNode;
        EmisorNode: XmlNode;
        ReceptorNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        DomicilioNode: XmlNode;
    begin
        if not TransferHeader."Foreign Trade" then
            exit;

        LocationFrom.Get(TransferHeader."Transfer-from Code");
        LocationTo.Get(TransferHeader."Transfer-to Code");

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        if TransferLine.IsEmpty() then
            exit;

        CFDIXMLHelperMX.AddElementCCE(XMLCurrNode, 'ComercioExterior', '', CFDIComercioExteriorNamespaceTxt, ComercioExteriorNode);
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Version', '2.0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'MotivoTraslado', TransferHeader."SAT Transfer Reason");
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'ClaveDePedimento', 'A1');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'CertificadoOrigen', '0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Incoterm', TransferHeader."SAT International Trade Term");
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TipoCambioUSD', FormatDecimal(TransferHeader."Exchange Rate USD", 6));
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TotalUSD', '0');

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Emisor', '', CFDIComercioExteriorNamespaceTxt, EmisorNode);
        CFDIXMLHelperMX.AddElementCCE(EmisorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(LocationFrom."SAT Address ID", LocationFrom.Address, DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Receptor', '', CFDIComercioExteriorNamespaceTxt, ReceptorNode);
        CFDIXMLHelperMX.AddElementCCE(ReceptorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(LocationTo."SAT Address ID", LocationTo.Address, DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Mercancias', '', CFDIComercioExteriorNamespaceTxt, MercanciasNode);
        if TransferLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCCE(MercanciasNode, 'Mercancia', '', CFDIComercioExteriorNamespaceTxt, MercanciaNode);
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'NoIdentificacion', TransferLine."Item No.");
                if Item.Get(TransferLine."Item No.") and (Item."Tariff No." <> '') then
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'CantidadAduana', Format(TransferLine.Quantity, 0, 9));
                UOM.Get(TransferLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'UnidadAduana', UOM."SAT Customs Unit");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorUnitarioAduana', '0');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorDolares', '0');
            until TransferLine.Next() = 0;
    end;

    local procedure AddNodeComercioExterior(XMLCurrNode: XmlNode; TransferShipmentHeader: Record "Transfer Shipment Header"; var TransferShipmentLine: Record "Transfer Shipment Line"; var LocationFrom: Record Location; var LocationTo: Record Location)
    var
        Item: Record Item;
        UOM: Record "Unit of Measure";
        ComercioExteriorNode: XmlNode;
        EmisorNode: XmlNode;
        ReceptorNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        DomicilioNode: XmlNode;
    begin
        if not TransferShipmentHeader."Foreign Trade" then
            exit;

        LocationFrom.Get(TransferShipmentHeader."Transfer-from Code");
        LocationTo.Get(TransferShipmentHeader."Transfer-to Code");

        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
        if TransferShipmentLine.IsEmpty() then
            exit;

        CFDIXMLHelperMX.AddElementCCE(XMLCurrNode, 'ComercioExterior', '', CFDIComercioExteriorNamespaceTxt, ComercioExteriorNode);
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Version', '2.0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'MotivoTraslado', TransferShipmentHeader."SAT Transfer Reason");
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'ClaveDePedimento', 'A1');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'CertificadoOrigen', '0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Incoterm', TransferShipmentHeader."SAT International Trade Term");
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TipoCambioUSD', FormatDecimal(TransferShipmentHeader."Exchange Rate USD", 6));
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TotalUSD', '0');

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Emisor', '', CFDIComercioExteriorNamespaceTxt, EmisorNode);
        CFDIXMLHelperMX.AddElementCCE(EmisorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(LocationFrom."SAT Address ID", LocationFrom.Address, DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Receptor', '', CFDIComercioExteriorNamespaceTxt, ReceptorNode);
        CFDIXMLHelperMX.AddElementCCE(ReceptorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(LocationTo."SAT Address ID", LocationTo.Address, DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Mercancias', '', CFDIComercioExteriorNamespaceTxt, MercanciasNode);
        if TransferShipmentLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCCE(MercanciasNode, 'Mercancia', '', CFDIComercioExteriorNamespaceTxt, MercanciaNode);
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'NoIdentificacion', TransferShipmentLine."Item No.");
                if Item.Get(TransferShipmentLine."Item No.") and (Item."Tariff No." <> '') then
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'CantidadAduana', Format(TransferShipmentLine.Quantity, 0, 9));
                UOM.Get(TransferShipmentLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'UnidadAduana', UOM."SAT Customs Unit");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorUnitarioAduana', '0');
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorDolares', '0');
            until TransferShipmentLine.Next() = 0;
    end;

    local procedure AddNodeDocumentacionAduanera(XMLCurrNode: XmlNode; DocumentType: Code[10]; DocumentIdentifier: Text)
    var
        DocAduaneraNode: XmlNode;
    begin
        CFDIXMLHelperMX.AddElementCartaPorte(XMLCurrNode, 'DocumentacionAduanera', '', '', DocAduaneraNode);
        CFDIXMLHelperMX.AddAttribute(DocAduaneraNode, 'TipoDocumento', DocumentType);
        CFDIXMLHelperMX.AddAttribute(DocAduaneraNode, 'IdentDocAduanero', DocumentIdentifier);
    end;

    local procedure IsHazardousMaterialMandatory(SATClassificationCode: Code[10]): Boolean
    var
        SATClassification: Record "SAT Classification";
    begin
        if not SATClassification.Get(SATClassificationCode) then
            exit(false);
        exit(SATClassification."Hazardous Material Mandatory");
    end;

    local procedure AddNodeCartaPorteAutotransporte(var MercanciasNode: XmlNode; VehicleCode: Code[20]; Trailer1: Code[20]; Trailer2: Code[20]; InsurerName: Text; InsurerPolicyNo: Text; HazardousMatExists: Boolean; MedicalInsurerName: Text; MedicalInsurerPolicyNo: Text)
    var
        FixedAsset: Record "Fixed Asset";
        AutotransporteNode: XmlNode;
        IdentificacionVehicularNode: XmlNode;
        SegurosNode: XmlNode;
        RemolquesNode: XmlNode;
        RemolqueNode: XmlNode;
    begin
        if not FixedAsset.Get(VehicleCode) then
            exit;

        CFDIXMLHelperMX.AddElementCartaPorte(MercanciasNode, 'Autotransporte', '', '', AutotransporteNode);
        CFDIXMLHelperMX.AddAttribute(AutotransporteNode, 'PermSCT', FixedAsset."SCT Permission Type");
        CFDIXMLHelperMX.AddAttribute(AutotransporteNode, 'NumPermisoSCT', FixedAsset."SCT Permission No.");

        CFDIXMLHelperMX.AddElementCartaPorte(AutotransporteNode, 'IdentificacionVehicular', '', '', IdentificacionVehicularNode);
        CFDIXMLHelperMX.AddAttribute(IdentificacionVehicularNode, 'ConfigVehicular', FixedAsset."SAT Federal Autotransport");
        CFDIXMLHelperMX.AddAttribute(IdentificacionVehicularNode, 'PesoBrutoVehicular', FormatDecimal(FixedAsset."Vehicle Gross Weight", 2));
        CFDIXMLHelperMX.AddAttribute(IdentificacionVehicularNode, 'PlacaVM', FixedAsset."Vehicle Licence Plate");
        CFDIXMLHelperMX.AddAttribute(IdentificacionVehicularNode, 'AnioModeloVM', Format(FixedAsset."Vehicle Year"));

        CFDIXMLHelperMX.AddElementCartaPorte(AutotransporteNode, 'Seguros', '', '', SegurosNode);
        CFDIXMLHelperMX.AddAttribute(SegurosNode, 'AseguraRespCivil', InsurerName);
        CFDIXMLHelperMX.AddAttribute(SegurosNode, 'PolizaRespCivil', InsurerPolicyNo);
        if HazardousMatExists then begin
            CFDIXMLHelperMX.AddAttribute(SegurosNode, 'AseguraMedAmbiente', MedicalInsurerName);
            CFDIXMLHelperMX.AddAttribute(SegurosNode, 'PolizaMedAmbiente', MedicalInsurerPolicyNo);
        end;

        if (Trailer1 = '') and (Trailer2 = '') then
            exit;

        CFDIXMLHelperMX.AddElementCartaPorte(AutotransporteNode, 'Remolques', '', '', RemolquesNode);
        if FixedAsset.Get(Trailer1) then begin
            CFDIXMLHelperMX.AddElementCartaPorte(RemolquesNode, 'Remolque', '', '', RemolqueNode);
            CFDIXMLHelperMX.AddAttribute(RemolqueNode, 'SubTipoRem', FixedAsset."SAT Trailer Type");
            CFDIXMLHelperMX.AddAttribute(RemolqueNode, 'Placa', FixedAsset."Vehicle Licence Plate");
        end;
        if FixedAsset.Get(Trailer2) then begin
            CFDIXMLHelperMX.AddElementCartaPorte(RemolquesNode, 'Remolque', '', '', RemolqueNode);
            CFDIXMLHelperMX.AddAttribute(RemolqueNode, 'SubTipoRem', FixedAsset."SAT Trailer Type");
            CFDIXMLHelperMX.AddAttribute(RemolqueNode, 'Placa', FixedAsset."Vehicle Licence Plate");
        end;
    end;

    local procedure AddNodeCartaPorteFiguraTransporte(var FiguraNode: XmlNode; DocumentTableID: Integer; DocumentNo: Code[20]; ParentNode: XmlNode; var CFDITransportOperator: Record "CFDI Transport Operator"; var Employee: Record Employee)
    var
        TiposFiguraNode: XmlNode;
    begin
        CFDIXMLHelperMX.AddElementCartaPorte(ParentNode, 'FiguraTransporte', '', '', FiguraNode);
        CFDITransportOperator.SetRange("Document Table ID", DocumentTableID);
        CFDITransportOperator.SetRange("Document No.", DocumentNo);
        if not CFDITransportOperator.FindSet() then
            exit;

        repeat
            CFDIXMLHelperMX.AddElementCartaPorte(FiguraNode, 'TiposFigura', '', '', TiposFiguraNode);
            Employee.Get(CFDITransportOperator."Operator Code");
            CFDIXMLHelperMX.AddAttribute(TiposFiguraNode, 'TipoFigura', '01');
            CFDIXMLHelperMX.AddAttribute(TiposFiguraNode, 'RFCFigura', Employee."RFC No.");
            CFDIXMLHelperMX.AddAttribute(TiposFiguraNode, 'NumLicencia', Employee."License No.");
            CFDIXMLHelperMX.AddAttribute(TiposFiguraNode, 'NombreFigura', EncodeString(Employee.FullName()));
        until CFDITransportOperator.Next() = 0;
    end;

    local procedure CreateXMLDocument33(var RootNode: XmlElement; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; var XMLDoc: XmlDocument; SubTotal: Decimal; TotalTax: Decimal; TotalRetention: Decimal; TotalDiscount: Decimal)
    var
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        SATUtilities: Codeunit "SAT Utilities";
        SalesInvoiceRetentionLine: Record "Sales Invoice Line";
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
        CurrentNode: XmlNode;
        XMLNewChild: XmlNode;
        LineDiscount: Decimal;
        LineAmount: Decimal;
        CorrectedTotalTax: Decimal;
    begin
        CompanyInfo.Get();
        GetCustomer(Customer, SalesInvoiceHeader."Bill-to Customer No.", false);

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', SalesInvoiceHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(SalesInvoiceHeader));
        RootNode.SetAttribute('Sello', SignedString);
        RootNode.SetAttribute('FormaPago', SATUtilities.GetSATPaymentMethod(SalesInvoiceHeader."Payment Method Code"));
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', Certificate);
        RootNode.SetAttribute('SubTotal', FormatAmount(SubTotal, SalesInvoiceHeader."Currency Code"));
        RootNode.SetAttribute('Descuento', FormatAmount(TotalDiscount, SalesInvoiceHeader."Currency Code"));
        if SalesInvoiceHeader."Currency Code" = '' then
            RootNode.SetAttribute('Moneda', 'MXN')
        else begin
            RootNode.SetAttribute('Moneda', SalesInvoiceHeader."Currency Code");
            if (SalesInvoiceHeader."Currency Code" <> 'MXN') and (SalesInvoiceHeader."Currency Code" <> 'XXX') then
                RootNode.SetAttribute('TipoCambio', FormatDecimal(1 / SalesInvoiceHeader."Currency Factor", 6));
        end;
        RootNode.SetAttribute('Total', FormatAmount(SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Currency Code"));
        RootNode.SetAttribute('TipoDeComprobante', 'I');
        RootNode.SetAttribute('Exportacion', SalesInvoiceHeader."CFDI Export Code");
        RootNode.SetAttribute('MetodoPago', SATUtilities.GetSATPaymentTerm(SalesInvoiceHeader."Payment Terms Code"));
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddInformacionGlobalNode(RootNode, Customer, SalesInvoiceHeader."CFDI Period", SalesInvoiceHeader."Posting Date");
        AddCfdiRelacionadosNode(RootNode, Database::"Sales Invoice Header", SalesInvoiceHeader."No.", SalesInvoiceHeader."CFDI Relation");

        CurrentNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Emisor', '', XMLNewChild);
        CurrentNode := XMLNewChild;
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'Rfc', CompanyInfo."RFC Number");
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'Nombre', CompanyInfo.Name);
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");

        CurrentNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Receptor', '', XMLNewChild);
        CurrentNode := XMLNewChild;
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'Rfc', Customer."RFC No.");
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'Nombre', Customer.Name);
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'DomicilioFiscalReceptor', SalesInvoiceHeader."Bill-to Post Code");
        AddReceptorForeignTaxAttributes(CurrentNode, Customer);
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'UsoCFDI', SalesInvoiceHeader."CFDI Purpose");

        CurrentNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Conceptos', '', XMLNewChild);
        ConceptosNode := XMLNewChild;
        SalesInvoiceLine.SetRange("Retention Attached to Line No.", 0);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCFDI(ConceptosNode, 'Concepto', '', XMLNewChild);
                ConceptoNode := XMLNewChild;
                LineAmount := GetReportedLineAmount(SalesInvoiceLine);
                LineDiscount := SalesInvoiceLine."Line Discount Amount";
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveProdServ', SATUtilities.GetSATClassification(SalesInvoiceLine.Type, SalesInvoiceLine."No."));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'NoIdentificacion', SalesInvoiceLine."No.");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Cantidad', Format(SalesInvoiceLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(SalesInvoiceLine."Unit of Measure Code"));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Unidad', SalesInvoiceLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descripcion', EncodeString(SalesInvoiceLine.Description));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ValorUnitario', FormatDecimal(SalesInvoiceLine."Unit Price", 6));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Importe', FormatDecimal(LineAmount, 6));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descuento', FormatDecimal(LineDiscount, 6));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ObjetoImp', GetSubjectToTaxCode(SalesInvoiceLine));
                AddNodeImpuestoPerLine(ConceptoNode.AsXmlElement(), SalesInvoiceLine, SalesInvoiceRetentionLine);
                AddNodeCuentaPredial(ConceptoNode, SalesInvoiceLine."No.");
            until SalesInvoiceLine.Next() = 0;

        AddDocumentTaxNode(RootNode, SalesInvoiceHeader, SalesInvoiceLine, CorrectedTotalTax);
        RootNode.SetAttribute('Total', FormatAmount(SubTotal - TotalDiscount + CorrectedTotalTax - TotalRetention, SalesInvoiceHeader."Currency Code"));

        if SalesInvoiceHeader."Foreign Trade" then begin
            CurrentNode := RootNode.AsXmlNode();
            CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Complemento', '', XMLNewChild);
            AddNodeComercioExterior(SalesInvoiceLine, SalesInvoiceHeader, XMLDoc, XMLNewChild, XMLNewChild);
        end;
    end;

    local procedure AddDocumentTaxNode(var RootNode: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; var CorrectedTotalTax: Decimal)
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TotalTax: Decimal;
        TotalRetention: Decimal;
        CurrencyCode: Code[10];
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if not SalesInvoiceLine.FindSet() then
            exit;

        repeat
            InsertTempVATAmountLine(TempVATAmountLine, SalesInvoiceLine);
        until SalesInvoiceLine.Next() = 0;

        TempVATAmountLine.SetRange(Positive, true);
        if TempVATAmountLine.FindSet() then
            repeat
                TotalTax += TempVATAmountLine."VAT Amount";
            until TempVATAmountLine.Next() = 0;

        TempVATAmountLine.SetRange(Positive, false);
        if TempVATAmountLine.FindSet() then
            repeat
                TotalRetention += TempVATAmountLine."VAT Amount";
            until TempVATAmountLine.Next() = 0;

        CurrencyCode := SalesInvoiceHeader."Currency Code";
        CorrectedTotalTax := TotalTax;
        AddDocumentTaxNodeFromTempVATAmountLine(RootNode, TempVATAmountLine, TotalTax, TotalRetention, CurrencyCode);

        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("Retention Attached to Line No.", 0);
    end;

    local procedure AddDocumentTaxNodeFromTempVATAmountLine(var RootNode: XmlElement; var TempVATAmountLine: Record "VAT Amount Line" temporary; TotalTax: Decimal; TotalRetention: Decimal; CurrencyCode: Code[10])
    var
        RootXmlNode: XmlNode;
        ImpuestosNode: XmlNode;
        RetencionesNode: XmlNode;
        RetencionNode: XmlNode;
        TrasladosNode: XmlNode;
        TrasladoNode: XmlNode;
    begin
        TempVATAmountLine.Reset();
        if TempVATAmountLine.IsEmpty() then
            exit;

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Impuestos', '', ImpuestosNode);

        TempVATAmountLine.SetRange(Positive, false);
        if TempVATAmountLine.FindSet() then begin
            CFDIXMLHelperMX.AddElementCFDI(ImpuestosNode, 'Retenciones', '', RetencionesNode);
            repeat
                CFDIXMLHelperMX.AddElementCFDI(RetencionesNode, 'Retencion', '', RetencionNode);
                CFDIXMLHelperMX.AddAttribute(RetencionNode, 'Impuesto', GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount"));
                CFDIXMLHelperMX.AddAttribute(RetencionNode, 'Importe', FormatAmount(TempVATAmountLine."VAT Amount", CurrencyCode));
            until TempVATAmountLine.Next() = 0;
            CFDIXMLHelperMX.AddAttribute(ImpuestosNode, 'TotalImpuestosRetenidos', FormatAmount(TotalRetention, CurrencyCode));
        end;

        TempVATAmountLine.SetRange(Positive, true);
        if TempVATAmountLine.FindSet() then begin
            CFDIXMLHelperMX.AddElementCFDI(ImpuestosNode, 'Traslados', '', TrasladosNode);
            repeat
                CFDIXMLHelperMX.AddElementCFDI(TrasladosNode, 'Traslado', '', TrasladoNode);
                if TempVATAmountLine."Tax Category" = GetTaxCategoryExempt() then begin
                    CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Base', FormatAmount(TempVATAmountLine."VAT Base", CurrencyCode));
                    CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Impuesto', GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount"));
                    CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TipoFactor', 'Exento');
                end else begin
                    CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Base', FormatAmount(TempVATAmountLine."VAT Base", CurrencyCode));
                    CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Impuesto', GetTaxCode(TempVATAmountLine."VAT %", TempVATAmountLine."VAT Amount"));
                    CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TipoFactor', 'Tasa');
                    CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TasaOCuota', PadStr(FormatAmount(TempVATAmountLine."VAT %" / 100, CurrencyCode), 8, '0'));
                    CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Importe', FormatAmount(TempVATAmountLine."VAT Amount", CurrencyCode));
                end;
            until TempVATAmountLine.Next() = 0;
            CFDIXMLHelperMX.AddAttribute(ImpuestosNode, 'TotalImpuestosTrasladados', FormatAmount(TotalTax, CurrencyCode));
        end;

        TempVATAmountLine.Reset();
    end;

    local procedure InsertTempVATAmountLine(var TempVATAmountLine: Record "VAT Amount Line" temporary; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATIdentifier: Code[20];
    begin
        if SalesInvoiceLine.Type = SalesInvoiceLine.Type::" " then
            exit;

        if not VATPostingSetup.Get(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group") then
            exit;

        if GetSubjectToTaxCode(SalesInvoiceLine) <> '02' then
            exit;

        if SalesInvoiceLine."Retention Attached to Line No." = 0 then
            VATIdentifier := CopyStr(Format(SalesInvoiceLine."VAT %"), 1, MaxStrLen(TempVATAmountLine."VAT Identifier"))
        else
            VATIdentifier := CopyStr(Format(SalesInvoiceLine."Retention VAT %"), 1, MaxStrLen(TempVATAmountLine."VAT Identifier"));

        if not TempVATAmountLine.Get(VATIdentifier, VATPostingSetup."VAT Calculation Type", '', '', false, SalesInvoiceLine.Amount > 0) then begin
            TempVATAmountLine.Init();
            TempVATAmountLine."VAT Identifier" := VATIdentifier;
            TempVATAmountLine."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
            TempVATAmountLine.Positive := SalesInvoiceLine.Amount >= 0;
            TempVATAmountLine.Insert();
        end;

        if VATPostingSetup."CFDI VAT Exemption" then
            TempVATAmountLine."Tax Category" := GetTaxCategoryExempt();

        if SalesInvoiceLine."Retention Attached to Line No." = 0 then begin
            TempVATAmountLine."Amount Including VAT" += SalesInvoiceLine."Amount Including VAT";
            TempVATAmountLine."VAT %" := SalesInvoiceLine."VAT %";
            TempVATAmountLine."VAT Amount" += Round(SalesInvoiceLine.Amount * SalesInvoiceLine."VAT %" / 100, 0.000001);
            TempVATAmountLine."VAT Base" += SalesInvoiceLine.Amount;
            TempVATAmountLine.Modify();
        end else begin
            TempVATAmountLine."VAT %" := SalesInvoiceLine."Retention VAT %";
            TempVATAmountLine."VAT Amount" += SalesInvoiceLine.Amount;
            TempVATAmountLine.Modify();
        end;
    end;

    local procedure GetTaxCategoryExempt(): Code[10]
    begin
        exit('E');
    end;

    local procedure CreateXMLDocument33AdvancePayment(var RootNode: XmlElement; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; var XMLDoc: XmlDocument; SubTotal: Decimal; RetainAmt: Decimal)
    var
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SATUtilities: Codeunit "SAT Utilities";
        RootXmlNode: XmlNode;
        EmisorNode: XmlNode;
        ReceptorNode: XmlNode;
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
        TaxableLine: Record "Sales Invoice Line";
        TaxableRetentionLine: Record "Sales Invoice Line";
        TotalTax: Decimal;
        CurrencyCode: Code[10];
    begin
        CompanyInfo.Get();
        GetCustomer(Customer, SalesInvoiceHeader."Bill-to Customer No.", false);

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', SalesInvoiceHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(SalesInvoiceHeader));
        RootNode.SetAttribute('Sello', SignedString);
        RootNode.SetAttribute('FormaPago', SATUtilities.GetSATPaymentMethod(SalesInvoiceHeader."Payment Method Code"));
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', Certificate);

        CurrencyCode := SalesInvoiceHeader."Currency Code";
        RootNode.SetAttribute('SubTotal', FormatAmount(SubTotal, CurrencyCode));
        if CurrencyCode = '' then
            RootNode.SetAttribute('Moneda', 'MXN')
        else begin
            RootNode.SetAttribute('Moneda', CurrencyCode);
            if (CurrencyCode <> 'MXN') and (CurrencyCode <> 'XXX') then
                RootNode.SetAttribute('TipoCambio', FormatDecimal(1 / SalesInvoiceHeader."Currency Factor", 6));
        end;
        RootNode.SetAttribute('Total', FormatAmount(SubTotal + RetainAmt, CurrencyCode));
        RootNode.SetAttribute('TipoDeComprobante', 'I');
        RootNode.SetAttribute('Exportacion', SalesInvoiceHeader."CFDI Export Code");
        RootNode.SetAttribute('MetodoPago', 'PUE');
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Emisor', '', EmisorNode);
        CFDIXMLHelperMX.AddAttribute(EmisorNode, 'Rfc', CompanyInfo."RFC Number");
        CFDIXMLHelperMX.AddAttribute(EmisorNode, 'Nombre', CompanyInfo.Name);
        CFDIXMLHelperMX.AddAttribute(EmisorNode, 'RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");

        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Receptor', '', ReceptorNode);
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'Rfc', Customer."RFC No.");
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'Nombre', Customer.Name);
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'DomicilioFiscalReceptor', SalesInvoiceHeader."Bill-to Post Code");
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'UsoCFDI', SalesInvoiceHeader."CFDI Purpose");

        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Conceptos', '', ConceptosNode);
        CFDIXMLHelperMX.AddElementCFDI(ConceptosNode, 'Concepto', '', ConceptoNode);
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveProdServ', AdvanceProdServCodeTok);
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Cantidad', '1');
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveUnidad', AdvanceUnitCodeTok);
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descripcion', AdvanceDescriptionTok);
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ValorUnitario', FormatAmount(SubTotal, CurrencyCode));
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Importe', FormatAmount(SubTotal, CurrencyCode));

        TaxableLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        TaxableLine.SetRange("Retention Attached to Line No.", 0);
        if TaxableLine.FindFirst() then begin
            CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ObjetoImp', GetSubjectToTaxCode(TaxableLine));
            AddNodeImpuestoPerLine(ConceptoNode.AsXmlElement(), TaxableLine, TaxableRetentionLine);
            InsertTempVATAmountLine(TempVATAmountLine, TaxableLine);
            TotalTax := TaxableLine."Amount Including VAT" - TaxableLine.Amount;
        end else
            CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ObjetoImp', '01');

        AddDocumentTaxNodeFromTempVATAmountLine(RootNode, TempVATAmountLine, TotalTax, 0, CurrencyCode);
    end;

    local procedure CreateXMLDocument33AdvanceSettle(var RootNode: XmlElement; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; var XMLDoc: XmlDocument; UUID: Text[50]; SubTotal: Decimal; TotalTax: Decimal; TotalRetention: Decimal; TotalDiscount: Decimal)
    var
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        SalesInvoiceRetentionLine: Record "Sales Invoice Line";
        SATUtilities: Codeunit "SAT Utilities";
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
        CurrentNode: XmlNode;
        XMLNewChild: XmlNode;
        LineDiscount: Decimal;
        LineAmount: Decimal;
        CorrectedTotalTax: Decimal;
        CalculatedTotalDiscount: Decimal;
    begin
        CompanyInfo.Get();
        GetCustomer(Customer, SalesInvoiceHeader."Bill-to Customer No.", false);

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', SalesInvoiceHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(SalesInvoiceHeader));
        RootNode.SetAttribute('Sello', SignedString);
        RootNode.SetAttribute('FormaPago', '30');
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', Certificate);
        RootNode.SetAttribute('SubTotal', FormatAmount(SubTotal, SalesInvoiceHeader."Currency Code"));
        RootNode.SetAttribute('Descuento', FormatAmount(TotalDiscount, SalesInvoiceHeader."Currency Code"));
        if SalesInvoiceHeader."Currency Code" = '' then
            RootNode.SetAttribute('Moneda', 'MXN')
        else begin
            RootNode.SetAttribute('Moneda', SalesInvoiceHeader."Currency Code");
            if (SalesInvoiceHeader."Currency Code" <> 'MXN') and (SalesInvoiceHeader."Currency Code" <> 'XXX') then
                RootNode.SetAttribute('TipoCambio', FormatDecimal(1 / SalesInvoiceHeader."Currency Factor", 6));
        end;
        RootNode.SetAttribute('Total', FormatAmount(SubTotal - TotalDiscount + TotalTax - TotalRetention, SalesInvoiceHeader."Currency Code"));
        RootNode.SetAttribute('TipoDeComprobante', 'I');
        RootNode.SetAttribute('Exportacion', SalesInvoiceHeader."CFDI Export Code");
        RootNode.SetAttribute('MetodoPago', SATUtilities.GetSATPaymentTerm(SalesInvoiceHeader."Payment Terms Code"));
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddAdvanceCfdiRelacionadosNode(RootNode, UUID, GetAdvanceCFDIRelation(SalesInvoiceHeader."CFDI Relation"));

        CurrentNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Emisor', '', XMLNewChild);
        CurrentNode := XMLNewChild;
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'Rfc', CompanyInfo."RFC Number");
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'Nombre', CompanyInfo.Name);
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");

        CurrentNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Receptor', '', XMLNewChild);
        CurrentNode := XMLNewChild;
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'Rfc', Customer."RFC No.");
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'Nombre', Customer.Name);
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'DomicilioFiscalReceptor', SalesInvoiceHeader."Bill-to Post Code");
        AddReceptorForeignTaxAttributes(CurrentNode, Customer);
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'UsoCFDI', SalesInvoiceHeader."CFDI Purpose");

        CurrentNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Conceptos', '', XMLNewChild);
        ConceptosNode := XMLNewChild;
        SalesInvoiceLine.SetRange("Retention Attached to Line No.", 0);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                CFDIXMLHelperMX.AddElementCFDI(ConceptosNode, 'Concepto', '', XMLNewChild);
                ConceptoNode := XMLNewChild;
                LineAmount := GetReportedLineAmount(SalesInvoiceLine);
                LineDiscount := SalesInvoiceLine."Line Discount Amount";
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveProdServ', SATUtilities.GetSATClassification(SalesInvoiceLine.Type, SalesInvoiceLine."No."));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'NoIdentificacion', SalesInvoiceLine."No.");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Cantidad', Format(SalesInvoiceLine.Quantity, 0, 9));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveUnidad', SATUtilities.GetSATUnitofMeasure(SalesInvoiceLine."Unit of Measure Code"));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Unidad', SalesInvoiceLine."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descripcion', EncodeString(SalesInvoiceLine.Description));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ValorUnitario', FormatDecimal(SalesInvoiceLine."Unit Price", 6));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Importe', FormatDecimal(LineAmount, 6));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descuento', FormatDecimal(LineDiscount, 6));
                CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ObjetoImp', GetSubjectToTaxCode(SalesInvoiceLine));
                CalculatedTotalDiscount += LineDiscount;
                AddNodeImpuestoPerLine(ConceptoNode.AsXmlElement(), SalesInvoiceLine, SalesInvoiceRetentionLine);
            until SalesInvoiceLine.Next() = 0;

        RootNode.SetAttribute('Descuento', FormatAmount(CalculatedTotalDiscount, SalesInvoiceHeader."Currency Code"));
        AddDocumentTaxNode(RootNode, SalesInvoiceHeader, SalesInvoiceLine, CorrectedTotalTax);
        RootNode.SetAttribute('Total', FormatAmount(SubTotal - TotalDiscount + CorrectedTotalTax - TotalRetention, SalesInvoiceHeader."Currency Code"));

        if SalesInvoiceHeader."Foreign Trade" then begin
            CurrentNode := RootNode.AsXmlNode();
            CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Complemento', '', XMLNewChild);
            AddNodeComercioExterior(SalesInvoiceLine, SalesInvoiceHeader, XMLDoc, XMLNewChild, XMLNewChild);
        end;
    end;

    local procedure CreateXMLDocument33AdvanceReverse(var RootNode: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header"; SignedString: Text; Certificate: Text; CertificateSerialNo: Text[250]; UUID: Text[50]; AdvanceAmount: Decimal)
    var
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        RootXmlNode: XmlNode;
        EmisorNode: XmlNode;
        ReceptorNode: XmlNode;
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
        ReverseAmount: Decimal;
    begin
        CompanyInfo.Get();
        GetCustomer(Customer, SalesInvoiceHeader."Bill-to Customer No.", false);

        ReverseAmount := Round(AdvanceAmount, 1, '=');
        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', SalesInvoiceHeader."No.");
        RootNode.SetAttribute('Fecha', GetIssueDateTime(SalesInvoiceHeader));
        RootNode.SetAttribute('Sello', SignedString);
        RootNode.SetAttribute('FormaPago', '30');
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', Certificate);
        RootNode.SetAttribute('SubTotal', FormatDecimal(ReverseAmount, 0));
        RootNode.SetAttribute('Moneda', 'XXX');
        RootNode.SetAttribute('Total', FormatDecimal(ReverseAmount, 0));
        RootNode.SetAttribute('TipoDeComprobante', 'E');
        RootNode.SetAttribute('Exportacion', SalesInvoiceHeader."CFDI Export Code");
        RootNode.SetAttribute('MetodoPago', 'PUE');
        RootNode.SetAttribute('LugarExpedicion', CompanyInfo."SAT Postal Code");

        AddAdvanceCfdiRelacionadosNode(RootNode, UUID, GetAdvanceCFDIRelation(SalesInvoiceHeader."CFDI Relation"));

        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Emisor', '', EmisorNode);
        CFDIXMLHelperMX.AddAttribute(EmisorNode, 'Rfc', CompanyInfo."RFC Number");
        CFDIXMLHelperMX.AddAttribute(EmisorNode, 'Nombre', CompanyInfo.Name);
        CFDIXMLHelperMX.AddAttribute(EmisorNode, 'RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");

        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Receptor', '', ReceptorNode);
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'Rfc', Customer."RFC No.");
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'Nombre', Customer.Name);
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'DomicilioFiscalReceptor', SalesInvoiceHeader."Bill-to Post Code");
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'UsoCFDI', 'P01');

        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Conceptos', '', ConceptosNode);
        CFDIXMLHelperMX.AddElementCFDI(ConceptosNode, 'Concepto', '', ConceptoNode);
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveProdServ', AdvanceProdServCodeTok);
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Cantidad', '1');
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ClaveUnidad', AdvanceUnitCodeTok);
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Descripcion', AdvanceReverseDescriptionTok);
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'ValorUnitario', FormatDecimal(ReverseAmount, 0));
        CFDIXMLHelperMX.AddAttribute(ConceptoNode, 'Importe', FormatDecimal(ReverseAmount, 0));
    end;

    local procedure AddAdvanceCfdiRelacionadosNode(var ParentNode: XmlElement; UUID: Text[50]; RelationType: Code[10])
    var
        CfdiRelacionadosNode: XmlElement;
        CfdiRelacionadoNode: XmlElement;
    begin
        if (UUID = '') or (RelationType = '') then
            exit;

        CfdiRelacionadosNode := XmlElement.Create('CfdiRelacionados');
        CfdiRelacionadosNode.SetAttribute('TipoRelacion', RelationType);

        CfdiRelacionadoNode := XmlElement.Create('CfdiRelacionado');
        CfdiRelacionadoNode.SetAttribute('UUID', UUID);
        CfdiRelacionadosNode.Add(CfdiRelacionadoNode.AsXmlNode());

        ParentNode.Add(CfdiRelacionadosNode.AsXmlNode());
    end;

    local procedure GetAdvanceCFDIRelation(CFDIRelation: Code[10]): Code[10]
    begin
        if CFDIRelation = '' then
            exit('07');

        exit(CFDIRelation);
    end;

    local procedure FindPrepaymentUUID(SalesInvoiceHeader: Record "Sales Invoice Header"): Text[50]
    var
        PrepaymentInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesInvoiceHeader."Prepayment Order No." = '' then
            exit('');

        PrepaymentInvoiceHeader.SetCurrentKey("Prepayment Order No.", "Prepayment Invoice");
        PrepaymentInvoiceHeader.SetRange("Prepayment Order No.", SalesInvoiceHeader."Prepayment Order No.");
        PrepaymentInvoiceHeader.SetRange("Prepayment Invoice", true);
        PrepaymentInvoiceHeader.SetFilter("Fiscal Invoice Number PAC", '<>%1', '');
        if not PrepaymentInvoiceHeader.FindLast() then
            exit('');

        exit(CopyStr(PrepaymentInvoiceHeader."Fiscal Invoice Number PAC", 1, 50));
    end;

    local procedure GetAdvanceScenario(SalesInvoiceHeader: Record "Sales Invoice Header"): Integer
    var
        SalesInvoiceLineLoc: Record "Sales Invoice Line";
    begin
        if SalesInvoiceHeader."Prepayment Invoice" then
            exit(1);

        if SalesInvoiceHeader."Prepayment Order No." = '' then
            exit(0);

        SalesInvoiceLineLoc.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLineLoc.SetRange("Prepayment Line", true);
        if SalesInvoiceLineLoc.IsEmpty() then
            exit(0);

        exit(2);
    end;

    local procedure EnsureAdvanceReverseTracked(var CFDIDocuments: Record "CFDI Documents"; SalesInvoiceHeader: Record "Sales Invoice Header"; AdvanceUUID: Text[50]; Certificate: Text; CertificateSerialNo: Text[250])
    var
        ReverseXMLDoc: XmlDocument;
        ReverseRootNode: XmlElement;
        ReverseBlobOutStream: OutStream;
        ReverseSignedString: Text;
        ReverseOriginalString: Text;
    begin
        if AdvanceUUID = '' then
            exit;

        CFDIDocuments.SetRange("No.", SalesInvoiceHeader."No.");
        CFDIDocuments.SetRange("Document Table ID", Database::"Sales Invoice Header");
        CFDIDocuments.SetRange(Prepayment, true);
        CFDIDocuments.SetRange(Reversal, true);
        if not CFDIDocuments.IsEmpty() then
            exit;

        XmlDocument.ReadFrom(GetBasicXMLHeader(false, false), ReverseXMLDoc);
        ReverseXMLDoc.GetRoot(ReverseRootNode);
        CreateXMLDocument33AdvanceReverse(
            ReverseRootNode, SalesInvoiceHeader, '', Certificate, CertificateSerialNo, AdvanceUUID, SalesInvoiceHeader.Amount);
        RemoveRedeclaredNamespaces(ReverseXMLDoc);
        ReverseOriginalString := CreateOriginalStr33Document(ReverseXMLDoc);
        ReverseSignedString := CreateDigitalSignature(ReverseOriginalString, MXConnectionSetup.Id);
        ReverseXMLDoc.GetRoot(ReverseRootNode);
        ReverseRootNode.SetAttribute('Sello', ReverseSignedString);
        ApplyLastUsedCertificateMetadata(ReverseRootNode, CertificateSerialNo);

        CFDIDocuments.Init();
        CFDIDocuments."No." := SalesInvoiceHeader."No.";
        CFDIDocuments."Document Table ID" := Database::"Sales Invoice Header";
        CFDIDocuments.Prepayment := true;
        CFDIDocuments.Reversal := true;
        CFDIDocuments."Certificate Serial No." := CertificateSerialNo;
        CFDIDocuments."Date/Time First Req. Sent" := FormatDateTime(CurrentDateTime());
        CFDIDocuments."Date/Time Sent" := CFDIDocuments."Date/Time First Req. Sent";
        CFDIDocuments."Fiscal Invoice Number PAC" := AdvanceUUID;
        CFDIDocuments."No. of E-Documents Sent" := 1;
        CFDIDocuments."Electronic Document Sent" := false;
        CFDIDocuments.Insert();

        CFDIDocuments."Original Document XML".CreateOutStream(ReverseBlobOutStream, TextEncoding::UTF8);
        ReverseXMLDoc.WriteTo(ReverseBlobOutStream);
        CFDIDocuments.Modify();
    end;

    internal procedure CreateAdvanceReverseSignedXML(SalesInvoiceHeader: Record "Sales Invoice Header"; AdvanceUUID: Text[50]; var ReverseSignedXmlTxt: Text): Boolean
    var
        ReverseXMLDoc: XmlDocument;
        ReverseRootNode: XmlElement;
        ReverseSignedString: Text;
        ReverseOriginalString: Text;
        CertificateText: Text;
        CertificateSerialNo: Text[250];
    begin
        ReverseSignedXmlTxt := '';
        if AdvanceUUID = '' then
            exit(false);

        GetCertificateMetadata(CertificateText, CertificateSerialNo);
        if (CertificateText = '') or (CertificateSerialNo = '') then
            exit(false);

        XmlDocument.ReadFrom(GetBasicXMLHeader(false, false), ReverseXMLDoc);
        ReverseXMLDoc.GetRoot(ReverseRootNode);
        CreateXMLDocument33AdvanceReverse(
            ReverseRootNode, SalesInvoiceHeader, '', CertificateText, CertificateSerialNo, AdvanceUUID, SalesInvoiceHeader.Amount);

        RemoveRedeclaredNamespaces(ReverseXMLDoc);
        ReverseOriginalString := CreateOriginalStr33Document(ReverseXMLDoc);
        ReverseSignedString := CreateDigitalSignature(ReverseOriginalString, MXConnectionSetup.Id);
        ReverseXMLDoc.GetRoot(ReverseRootNode);
        ReverseRootNode.SetAttribute('Sello', ReverseSignedString);
        ApplyLastUsedCertificateMetadata(ReverseRootNode, CertificateSerialNo);

        ReverseSignedXmlTxt := XmlDocumentToText(ReverseXMLDoc);
        exit(ReverseSignedXmlTxt <> '');
    end;

    local procedure XmlDocumentToText(var XMLDoc: XmlDocument): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        Chunk: Text;
        XmlTxt: Text;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XMLDoc.WriteTo(OutStream);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        while not InStream.EOS do begin
            InStream.ReadText(Chunk);
            XmlTxt += Chunk;
        end;
        exit(XmlTxt);
    end;

    local procedure AddNodeComercioExterior(var TempDocumentLineCCE: Record "Sales Invoice Line"; DocumentHeader: Record "Sales Invoice Header"; var XMLDoc: XmlDocument; XMLCurrNode: XmlNode; XMLNewChild: XmlNode)
    var
        Customer: Record Customer;
        Location: Record Location;
        Item: Record Item;
        UOM: Record "Unit of Measure";
        ComercioExteriorNode: XmlNode;
        EmisorNode: XmlNode;
        ReceptorNode: XmlNode;
        MercanciasNode: XmlNode;
        MercanciaNode: XmlNode;
        DomicilioNode: XmlNode;
        CurrencyFactor: Decimal;
        SumUSD: Decimal;
        LineCount: Integer;
        LineNo: Integer;
    begin
        if not DocumentHeader."Foreign Trade" then
            exit;

        GetCustomer(Customer, DocumentHeader."Bill-to Customer No.", false);
        LineCount := TempDocumentLineCCE.Count();
        if LineCount = 0 then
            exit;

        CFDIXMLHelperMX.AddElementCCE(XMLCurrNode, 'ComercioExterior', '', CFDIComercioExteriorNamespaceTxt, ComercioExteriorNode);
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Version', '2.0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'ClaveDePedimento', 'A1');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'CertificadoOrigen', '0');
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'Incoterm', DocumentHeader."SAT International Trade Term");
        CurrencyFactor := (1 / DocumentHeader."Currency Factor") * DocumentHeader."Exchange Rate USD";
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TipoCambioUSD', FormatDecimal(DocumentHeader."Exchange Rate USD", 6));
        CFDIXMLHelperMX.AddAttribute(ComercioExteriorNode, 'TotalUSD', FormatDecimal(DocumentHeader.Amount * CurrencyFactor, 2));

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Emisor', '', CFDIComercioExteriorNamespaceTxt, EmisorNode);
        CFDIXMLHelperMX.AddElementCCE(EmisorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        Location.Get(DocumentHeader."Location Code");
        CFDIXMLHelperMX.AddNodeDomicilio(Location."SAT Address ID", Location.Address, DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Receptor', '', CFDIComercioExteriorNamespaceTxt, ReceptorNode);
        if (Customer."Country/Region Code" <> 'MEX') and (Customer."RFC No." = 'XEXX010101000') then
            CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'NumRegIdTrib', Customer."VAT Registration No.");
        CFDIXMLHelperMX.AddElementCCE(ReceptorNode, 'Domicilio', '', CFDIComercioExteriorNamespaceTxt, DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(DocumentHeader."SAT Address ID", DocumentHeader."Bill-to Address", DomicilioNode);

        CFDIXMLHelperMX.AddElementCCE(ComercioExteriorNode, 'Mercancias', '', CFDIComercioExteriorNamespaceTxt, MercanciasNode);
        if TempDocumentLineCCE.FindSet() then
            repeat
                LineNo += 1;
                CFDIXMLHelperMX.AddElementCCE(MercanciasNode, 'Mercancia', '', CFDIComercioExteriorNamespaceTxt, MercanciaNode);
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'NoIdentificacion', TempDocumentLineCCE."No.");
                if Item.Get(TempDocumentLineCCE."No.") and (Item."Tariff No." <> '') then
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'FraccionArancelaria', DelChr(Item."Tariff No."));
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'CantidadAduana', Format(TempDocumentLineCCE.Quantity, 0, 9));
                UOM.Get(TempDocumentLineCCE."Unit of Measure Code");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'UnidadAduana', UOM."SAT Customs Unit");
                CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorUnitarioAduana', FormatDecimal(TempDocumentLineCCE.Amount / TempDocumentLineCCE.Quantity, 6));
                if LineNo <> LineCount then begin
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorDolares', FormatDecimal(TempDocumentLineCCE.Amount / DocumentHeader."Exchange Rate USD", 4));
                    SumUSD += TempDocumentLineCCE.Amount / DocumentHeader."Exchange Rate USD";
                end else
                    CFDIXMLHelperMX.AddAttribute(MercanciaNode, 'ValorDolares', FormatDecimal(DocumentHeader.Amount / DocumentHeader."Exchange Rate USD" - SumUSD, 4));
            until TempDocumentLineCCE.Next() = 0;
    end;

    local procedure AddNodeCartaPorteUbicacion(TipoUbicacion: Text; Location: Record Location; LocationPrefix: Text[2]; RFCNo: Text; ForeignRegId: Text; ResidenciaFiscal: Text; FechaHoraSalidaLlegada: Text; DistanciaRecorrida: Text; var XMLDoc: XmlDocument; XMLCurrNode: XmlNode; XMLNewChild: XmlNode)
    var
        UbicacionNode: XmlNode;
        DomicilioNode: XmlNode;
    begin
        CFDIXMLHelperMX.AddElementCartaPorte(XMLCurrNode, 'Ubicacion', '', '', UbicacionNode);
        XMLCurrNode := UbicacionNode;
        CFDIXMLHelperMX.AddAttribute(XMLCurrNode, 'TipoUbicacion', TipoUbicacion);
        if Location."ID Ubicacion" <> 0 then
            CFDIXMLHelperMX.AddAttribute(XMLCurrNode, 'IDUbicacion', LocationPrefix + PadStr('', 6 - StrLen(Format(Location."ID Ubicacion")), '0') + Format(Location."ID Ubicacion"));
        CFDIXMLHelperMX.AddAttribute(XMLCurrNode, 'RFCRemitenteDestinatario', RFCNo);
        if ForeignRegId <> '' then begin
            CFDIXMLHelperMX.AddAttribute(XMLCurrNode, 'NumRegIdTrib', ForeignRegId);
            CFDIXMLHelperMX.AddAttribute(XMLCurrNode, 'ResidenciaFiscal', ResidenciaFiscal);
        end;
        CFDIXMLHelperMX.AddAttribute(XMLCurrNode, 'FechaHoraSalidaLlegada', FechaHoraSalidaLlegada);
        if DistanciaRecorrida <> '' then
            CFDIXMLHelperMX.AddAttribute(XMLCurrNode, 'DistanciaRecorrida', DistanciaRecorrida);

        CFDIXMLHelperMX.AddElementCartaPorte(XMLCurrNode, 'Domicilio', '', '', DomicilioNode);
        CFDIXMLHelperMX.AddNodeDomicilio(Location."SAT Address ID", Location.Address, DomicilioNode);
        XMLNewChild := UbicacionNode;
    end;

    local procedure CreateOriginalStr33Document(var XMLDoc: XmlDocument): Text
    var
        XmlText: Text;
        OriginalString: Text;
        PendingTotalImpuestosRetenidos: Text;
        PendingTotalImpuestosTrasladados: Text;
        Position: Integer;
    begin
        XMLDoc.WriteTo(XmlText);

        // Legacy parity: build a CFDI-like original string using non-empty attribute values.
        OriginalString := '||';
        Position := 1;
        while Position <= StrLen(XmlText) do
            if CopyStr(XmlText, Position, 1) = '<' then begin
                Position += 1;
                if Position > StrLen(XmlText) then
                    break;

                if CopyStr(XmlText, Position, 1) = '/' then
                    HandleClosingTag(XmlText, Position, OriginalString, PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados)
                else
                    if IsXmlSpecialTagStart(CopyStr(XmlText, Position, 1)) then
                        SkipToTagEnd(XmlText, Position)
                    else begin
                        AppendOpeningTag(XmlText, Position, OriginalString, PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    end;
            end else
                Position += 1;

        exit(OriginalString + '|');
    end;

    local procedure AppendOpeningTag(XmlText: Text; var Position: Integer; var OriginalString: Text; var PendingTotalImpuestosRetenidos: Text; var PendingTotalImpuestosTrasladados: Text)
    var
        ElementName: Text;
    begin
        ReadElementName(XmlText, Position, ElementName);
        if IsLegacyOrderedCartaPorteElement(ElementName) then begin
            AppendLegacyOrderedTagAttributeValues(XmlText, Position, OriginalString, ElementName, PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
            exit;
        end;

        AppendTagAttributeValues(XmlText, Position, OriginalString, ElementName, PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
    end;

    local procedure HandleClosingTag(XmlText: Text; var Position: Integer; var OriginalString: Text; var PendingTotalImpuestosRetenidos: Text; var PendingTotalImpuestosTrasladados: Text)
    var
        ElementName: Text;
    begin
        Position += 1;
        ReadElementName(XmlText, Position, ElementName);

        if LowerCase(GetXmlLocalName(ElementName)) = 'impuestos' then begin
            AppendPendingOriginalValue(PendingTotalImpuestosRetenidos, OriginalString);
            AppendPendingOriginalValue(PendingTotalImpuestosTrasladados, OriginalString);
            PendingTotalImpuestosRetenidos := '';
            PendingTotalImpuestosTrasladados := '';
        end;

        SkipToTagEnd(XmlText, Position);
    end;

    local procedure AppendPendingOriginalValue(PendingValue: Text; var OriginalString: Text)
    var
        NormalizedValue: Text;
    begin
        NormalizedValue := NormalizeOriginalStringValue(PendingValue);
        if NormalizedValue <> '' then
            OriginalString += NormalizedValue + '|';
    end;

    local procedure IsXmlSpecialTagStart(TagStartChar: Text[1]): Boolean
    begin
        exit((TagStartChar = '/') or (TagStartChar = '?') or (TagStartChar = '!'));
    end;

    local procedure SkipToTagEnd(XmlText: Text; var Position: Integer)
    begin
        while (Position <= StrLen(XmlText)) and (CopyStr(XmlText, Position, 1) <> '>') do
            Position += 1;

        if Position <= StrLen(XmlText) then
            Position += 1;
    end;

    local procedure ReadElementName(XmlText: Text; var Position: Integer; var ElementName: Text)
    var
        StartPosition: Integer;
    begin
        StartPosition := Position;
        while Position <= StrLen(XmlText) do
            if IsWhiteSpace(CopyStr(XmlText, Position, 1)) or (CopyStr(XmlText, Position, 1) = '>') or (CopyStr(XmlText, Position, 1) = '/') then
                break
            else
                Position += 1;

        ElementName := CopyStr(XmlText, StartPosition, Position - StartPosition);
    end;

    local procedure AppendTagAttributeValues(XmlText: Text; var Position: Integer; var OriginalString: Text; ElementName: Text; var PendingTotalImpuestosRetenidos: Text; var PendingTotalImpuestosTrasladados: Text)
    var
        AttributeName: Text;
        AttributeValue: Text;
    begin
        while Position <= StrLen(XmlText) do begin
            SkipWhiteSpaces(XmlText, Position);
            if Position > StrLen(XmlText) then
                exit;

            if CopyStr(XmlText, Position, 2) = '/>' then begin
                Position += 2;
                exit;
            end;

            if CopyStr(XmlText, Position, 1) = '>' then begin
                Position += 1;
                exit;
            end;

            ReadAttributeName(XmlText, Position, AttributeName);
            if AttributeName = '' then begin
                Position += 1;
                continue;
            end;

            SkipWhiteSpaces(XmlText, Position);
            if CopyStr(XmlText, Position, 1) <> '=' then
                continue;

            Position += 1;
            SkipWhiteSpaces(XmlText, Position);
            ReadAttributeValue(XmlText, Position, AttributeValue);
            AppendOriginalAttributeValue(ElementName, AttributeName, AttributeValue, OriginalString, PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
        end;
    end;

    local procedure ReadAttributeName(XmlText: Text; var Position: Integer; var AttributeName: Text)
    var
        StartPosition: Integer;
    begin
        StartPosition := Position;
        while Position <= StrLen(XmlText) do
            if IsWhiteSpace(CopyStr(XmlText, Position, 1)) or (CopyStr(XmlText, Position, 1) = '=') or (CopyStr(XmlText, Position, 1) = '>') or (CopyStr(XmlText, Position, 1) = '/') then
                break
            else
                Position += 1;

        AttributeName := CopyStr(XmlText, StartPosition, Position - StartPosition);
    end;

    local procedure ReadAttributeValue(XmlText: Text; var Position: Integer; var AttributeValue: Text)
    var
        QuoteChar: Text[1];
        StartPosition: Integer;
    begin
        AttributeValue := '';
        if Position > StrLen(XmlText) then
            exit;

        QuoteChar := CopyStr(XmlText, Position, 1);
        if (QuoteChar = '"') or (QuoteChar = '''') then begin
            Position += 1;
            StartPosition := Position;
            while (Position <= StrLen(XmlText)) and (CopyStr(XmlText, Position, 1) <> QuoteChar) do
                Position += 1;

            AttributeValue := CopyStr(XmlText, StartPosition, Position - StartPosition);
            if Position <= StrLen(XmlText) then
                Position += 1;
            exit;
        end;

        StartPosition := Position;
        while Position <= StrLen(XmlText) do
            if IsWhiteSpace(CopyStr(XmlText, Position, 1)) or (CopyStr(XmlText, Position, 1) = '>') or (CopyStr(XmlText, Position, 1) = '/') then
                break
            else
                Position += 1;

        AttributeValue := CopyStr(XmlText, StartPosition, Position - StartPosition);
    end;

    local procedure AppendOriginalAttributeValue(ElementName: Text; AttributeName: Text; AttributeValue: Text; var OriginalString: Text; var PendingTotalImpuestosRetenidos: Text; var PendingTotalImpuestosTrasladados: Text)
    var
        NormalizedValue: Text;
        LocalElementName: Text;
        LowerAttributeName: Text;
    begin
        if ShouldSkipForOriginalString(AttributeName) then
            exit;

        LocalElementName := GetXmlLocalName(ElementName);
        NormalizedValue := NormalizeOriginalStringValue(AttributeValue);
        if NormalizedValue = '' then
            exit;

        LowerAttributeName := LowerCase(AttributeName);
        if (LowerAttributeName in ['totalimpuestosretenidos', 'totalimpuestostrasladados']) and IsZeroOriginalStringValue(NormalizedValue) then
            exit;

        if LocalElementName = 'Impuestos' then
            case LowerAttributeName of
                'totalimpuestosretenidos':
                    begin
                        PendingTotalImpuestosRetenidos := NormalizedValue;
                        exit;
                    end;
                'totalimpuestostrasladados':
                    begin
                        PendingTotalImpuestosTrasladados := NormalizedValue;
                        exit;
                    end;
            end;

        OriginalString += NormalizedValue + '|';
    end;

    local procedure GetXmlLocalName(ElementName: Text): Text
    var
        ColonPosition: Integer;
    begin
        ColonPosition := StrPos(ElementName, ':');
        if ColonPosition = 0 then
            exit(ElementName);

        exit(CopyStr(ElementName, ColonPosition + 1));
    end;

    local procedure IsLegacyOrderedCartaPorteElement(ElementName: Text): Boolean
    var
        LocalElementName: Text;
    begin
        LocalElementName := LowerCase(GetXmlLocalName(ElementName));

        case LocalElementName of
            'comprobante', 'emisor', 'receptor', 'concepto', 'informacionaduanera', 'documentacionaduanera',
            'cartaporte', 'ubicaciones', 'ubicacion', 'domicilio', 'mercancias', 'mercancia',
            'autotransporte', 'identificacionvehicular', 'seguros', 'remolques', 'remolque',
            'regimenesaduaneros', 'regimenaduaneroccp', 'figuratransporte', 'tiposfigura':
                exit(true);
            else
                exit(false);
        end;
    end;

    local procedure AppendLegacyOrderedTagAttributeValues(XmlText: Text; var Position: Integer; var OriginalString: Text; ElementName: Text; var PendingTotalImpuestosRetenidos: Text; var PendingTotalImpuestosTrasladados: Text)
    var
        LocalElementName: Text;
        TagAttrStart: Integer;
    begin
        LocalElementName := LowerCase(GetXmlLocalName(ElementName));
        // Save position at start of attributes; each AppendLegacyOrderedAttributeValue
        // will search from this position independently, so XML attribute order doesn't matter.
        TagAttrStart := Position;

        case LocalElementName of
            'comprobante':
                begin
                    // SAT cadenaoriginal_4_0.xslt Comprobante order (Sello/Certificado are auto-skipped)
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Version', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Serie', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Folio', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Fecha', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Sello', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'FormaPago', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'NoCertificado', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Certificado', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'CondicionesDePago', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'SubTotal', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Descuento', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Moneda', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'TipoCambio', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Total', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'TipoDeComprobante', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Exportacion', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'MetodoPago', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'LugarExpedicion', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Confirmacion', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'emisor':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Rfc', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Nombre', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'RegimenFiscal', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'receptor':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Rfc', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Nombre', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'DomicilioFiscalReceptor', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ResidenciaFiscal', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'NumRegIdTrib', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'RegimenFiscalReceptor', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'UsoCFDI', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'concepto':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ClaveProdServ', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'NoIdentificacion', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Cantidad', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ClaveUnidad', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Unidad', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Descripcion', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ValorUnitario', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Importe', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Descuento', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ObjetoImp', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'informacionaduanera':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'NumeroPedimento', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'cartaporte':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Version', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'IdCCP', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'TranspInternac', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'EntradaSalidaMerc', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'PaisOrigenDestino', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ViaEntradaSalida', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'TotalDistRec', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'ubicaciones', 'regimenesaduaneros', 'figuratransporte', 'remolques':
                begin
                    // Container nodes without attributes in the legacy-oriented canonical string.
                end;
            'regimenaduaneroccp':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'RegimenAduanero', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'ubicacion':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'TipoUbicacion', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'IDUbicacion', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'RFCRemitenteDestinatario', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'NumRegIdTrib', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ResidenciaFiscal', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'FechaHoraSalidaLlegada', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'DistanciaRecorrida', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'domicilio':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Calle', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Colonia', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Localidad', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Municipio', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Estado', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Pais', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'CodigoPostal', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'mercancias':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'PesoBrutoTotal', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'UnidadPeso', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'NumTotalMercancias', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'mercancia':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'BienesTransp', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Descripcion', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Cantidad', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ClaveUnidad', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'MaterialPeligroso', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'CveMaterialPeligroso', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Embalaje', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'PesoEnKg', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ValorMercancia', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Moneda', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'FraccionArancelaria', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'UUIDComercioExt', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'TipoMateria', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'documentacionaduanera':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'TipoDocumento', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'IdentDocAduanero', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'autotransporte':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'PermSCT', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'NumPermisoSCT', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'identificacionvehicular':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'ConfigVehicular', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'PesoBrutoVehicular', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'PlacaVM', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'AnioModeloVM', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'seguros':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'AseguraRespCivil', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'PolizaRespCivil', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'AseguraMedAmbiente', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'PolizaMedAmbiente', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'remolque':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'SubTipoRem', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'Placa', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
            'tiposfigura':
                begin
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'TipoFigura', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'RFCFigura', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'NumLicencia', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                    AppendLegacyOrderedAttributeValue(XmlText, TagAttrStart, OriginalString, ElementName, 'NombreFigura', PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                end;
        end;

        SkipToTagEnd(XmlText, Position);
    end;

    local procedure AppendLegacyOrderedAttributeValue(XmlText: Text; TagStartPosition: Integer; var OriginalString: Text; ElementName: Text; AttributeName: Text; var PendingTotalImpuestosRetenidos: Text; var PendingTotalImpuestosTrasladados: Text)
    var
        SearchPosition: Integer;
        CurrentAttributeName: Text;
        CurrentAttributeValue: Text;
    begin
        // Always search from the beginning of the tag's attributes (TagStartPosition),
        // not from where the previous attribute was found. This ensures we find attributes
        // regardless of their order in the XML vs. the legacy canonical order.
        SearchPosition := TagStartPosition;
        while SearchPosition <= StrLen(XmlText) do begin
            SkipWhiteSpaces(XmlText, SearchPosition);
            if SearchPosition > StrLen(XmlText) then
                exit;

            if (CopyStr(XmlText, SearchPosition, 1) = '>') or (CopyStr(XmlText, SearchPosition, 2) = '/>') then
                exit;

            ReadAttributeName(XmlText, SearchPosition, CurrentAttributeName);
            if CurrentAttributeName = '' then begin
                SearchPosition += 1;
                continue;
            end;

            SkipWhiteSpaces(XmlText, SearchPosition);
            if CopyStr(XmlText, SearchPosition, 1) <> '=' then begin
                SearchPosition += 1;
                continue;
            end;

            SearchPosition += 1;
            SkipWhiteSpaces(XmlText, SearchPosition);
            ReadAttributeValue(XmlText, SearchPosition, CurrentAttributeValue);

            if LowerCase(CurrentAttributeName) = LowerCase(AttributeName) then begin
                AppendOriginalAttributeValue(ElementName, CurrentAttributeName, CurrentAttributeValue, OriginalString, PendingTotalImpuestosRetenidos, PendingTotalImpuestosTrasladados);
                exit;
            end;
        end;
    end;

    local procedure ShouldSkipForOriginalString(AttributeName: Text): Boolean
    var
        LowerAttributeName: Text;
    begin
        if AttributeName = '' then
            exit(true);

        LowerAttributeName := LowerCase(AttributeName);

        if CopyStr(LowerAttributeName, 1, 5) = 'xmlns' then
            exit(true);

        if CopyStr(LowerAttributeName, 1, 4) = 'xsi:' then
            exit(true);

        if LowerAttributeName in ['sello', 'certificado'] then
            exit(true);

        exit(false);
    end;

    local procedure NormalizeOriginalStringValue(Value: Text): Text
    begin
        Value := DecodeXmlAttributeValue(Value);
        Value := DelChr(Value, '=', '|');
        Value := CollapseAndTrimSpaces(Value);
        exit(Value);
    end;

    local procedure IsZeroOriginalStringValue(Value: Text): Boolean
    var
        DecimalValue: Decimal;
    begin
        if Value = '' then
            exit(false);

        if Evaluate(DecimalValue, Value) then
            exit(DecimalValue = 0);

        exit(false);
    end;

    local procedure DecodeXmlAttributeValue(Value: Text): Text
    begin
        Value := Value.Replace('&quot;', '"');
        Value := Value.Replace('&apos;', '''');
        Value := Value.Replace('&lt;', '<');
        Value := Value.Replace('&gt;', '>');
        Value := Value.Replace('&amp;', '&');
        exit(Value);
    end;

    local procedure CollapseAndTrimSpaces(Value: Text): Text
    var
        I: Integer;
        CurrentChar: Text[1];
        PreviousWasSpace: Boolean;
        Result: Text;
    begin
        Value := DelChr(Value, '<>', ' ');
        for I := 1 to StrLen(Value) do begin
            CurrentChar := CopyStr(Value, I, 1);
            if CurrentChar = ' ' then begin
                if not PreviousWasSpace then begin
                    Result += CurrentChar;
                    PreviousWasSpace := true;
                end;
            end else begin
                Result += CurrentChar;
                PreviousWasSpace := false;
            end;
        end;

        exit(Result);
    end;

    local procedure IsWhiteSpace(Character: Text[1]): Boolean
    begin
        exit((Character = ' ') or (Character = Format(9)) or (Character = Format(10)) or (Character = Format(13)));
    end;

    local procedure SkipWhiteSpaces(XmlText: Text; var Position: Integer)
    begin
        while (Position <= StrLen(XmlText)) and IsWhiteSpace(CopyStr(XmlText, Position, 1)) do
            Position += 1;
    end;

    local procedure CreateDigitalSignature(OriginalString: Text; SetupId: Code[10]): Text
    begin
        exit(DigitalSignMX.CreateDigitalSignature(OriginalString, SetupId));
    end;

    local procedure GetSubjectToTaxCode(SalesInvoiceLine: Record "Sales Invoice Line"): Text
    begin
        if SalesInvoiceLine.Amount = 0 then
            exit('01');

        exit('02');
    end;

    local procedure GetSubjectToTaxCode(SalesShipmentLine: Record "Sales Shipment Line"): Text
    begin
        if SalesShipmentLine.Quantity = 0 then
            exit('01');

        exit('02');
    end;

    local procedure GetTaxCode(VATPct: Decimal; VATAmount: Decimal) TaxCode: Code[10]
    var
        TaxType: Option Translado,Retencion;
    begin
        TaxCode := '002';
        if VATPct <> 0 then
            if VATAmount >= 0 then
                TaxCode := TaxCodeFromTaxRate(VATPct / 100, TaxType::Translado)
            else
                TaxCode := TaxCodeFromTaxRate(VATPct / 100, TaxType::Retencion);
    end;

    local procedure TaxCodeFromTaxRate(TaxRate: Decimal; TaxType: Option Translado,Retencion): Code[10]
    begin
        if (TaxType = TaxType::Translado) and (TaxRate in [0.16, 0.08]) then
            exit('002');

        if (TaxType = TaxType::Retencion) and (TaxRate = 0.1) then
            exit('001');

        if (TaxType = TaxType::Retencion) and (TaxRate in [0.1 .. 0.11]) then
            exit('002');

        if (TaxType = TaxType::Retencion) and ((TaxRate >= 0.0) and (TaxRate <= 0.16)) then
            exit('002');

        if (TaxType = TaxType::Retencion) and ((TaxRate >= 0.0) and (TaxRate <= 0.35)) then
            exit('001');

        case TaxRate of
            0.265, 0.3, 0.53, 0.5, 1.6, 0.304, 0.25, 0.09, 0.08, 0.07, 0.06, 0.03:
                if (TaxRate = 0.03) and (TaxType <> TaxType::Retencion) then
                    exit('003');
        end;

        if (TaxRate >= 0.0) and (TaxRate <= 43.77) then
            exit('003');
    end;

    local procedure AddNodeImpuestoPerLine(ParentNode: XmlElement; TaxBase: Decimal; VATPct: Decimal; VATAmount: Decimal; IsVATExempt: Boolean)
    var
        ParentXmlNode: XmlNode;
        ImpuestosNode: XmlNode;
        TrasladosNode: XmlNode;
        TrasladoNode: XmlNode;
    begin
        ParentXmlNode := ParentNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(ParentXmlNode, 'Impuestos', '', ImpuestosNode);
        CFDIXMLHelperMX.AddElementCFDI(ImpuestosNode, 'Traslados', '', TrasladosNode);
        CFDIXMLHelperMX.AddElementCFDI(TrasladosNode, 'Traslado', '', TrasladoNode);

        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Base', FormatDecimal(TaxBase, 6));
        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Impuesto', GetTaxCode(VATPct, VATAmount));

        if not IsVATExempt then begin
            CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TipoFactor', 'Tasa');
            CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TasaOCuota', PadStr(FormatDecimal(VATPct / 100, 6), 8, '0'));
            CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Importe', FormatDecimal(VATAmount, 6));
        end else
            CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TipoFactor', 'Exento');
    end;

    local procedure AddNodeImpuestoPerLine(ParentNode: XmlElement; SalesInvoiceLine: Record "Sales Invoice Line"; var SalesInvoiceRetentionLine: Record "Sales Invoice Line")
    var
        ParentXmlNode: XmlNode;
        ImpuestosNode: XmlNode;
        TrasladosNode: XmlNode;
        TrasladoNode: XmlNode;
        RetencionesNode: XmlNode;
        RetencionNode: XmlNode;
        RetentionAmount: Decimal;
        IsVATExempt: Boolean;
    begin
        if GetSubjectToTaxCode(SalesInvoiceLine) <> '02' then
            exit;
        if IsNonTaxableVATLine(SalesInvoiceLine) then
            exit;

        ParentXmlNode := ParentNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(ParentXmlNode, 'Impuestos', '', ImpuestosNode);

        CFDIXMLHelperMX.AddElementCFDI(ImpuestosNode, 'Traslados', '', TrasladosNode);
        CFDIXMLHelperMX.AddElementCFDI(TrasladosNode, 'Traslado', '', TrasladoNode);
        IsVATExempt := IsVATExemptLine(SalesInvoiceLine);
        AddNodeTrasladoRetentionPerLine(
            TrasladoNode,
            SalesInvoiceLine.Amount,
            SalesInvoiceLine."VAT %",
            Round(SalesInvoiceLine.Amount * SalesInvoiceLine."VAT %" / 100, 0.000001),
            IsVATExempt);

        SalesInvoiceRetentionLine.SetRange("Document No.", SalesInvoiceLine."Document No.");
        SalesInvoiceRetentionLine.SetRange("Retention Attached to Line No.", SalesInvoiceLine."Line No.");
        if SalesInvoiceRetentionLine.FindSet() then begin
            CFDIXMLHelperMX.AddElementCFDI(ImpuestosNode, 'Retenciones', '', RetencionesNode);
            repeat
                RetentionAmount := SalesInvoiceRetentionLine.Amount;
                CFDIXMLHelperMX.AddElementCFDI(RetencionesNode, 'Retencion', '', RetencionNode);
                IsVATExempt := IsVATExemptLine(SalesInvoiceRetentionLine);
                AddNodeTrasladoRetentionPerLine(
                    RetencionNode,
                    SalesInvoiceLine.Amount,
                    SalesInvoiceRetentionLine."Retention VAT %",
                    RetentionAmount,
                    IsVATExempt);
            until SalesInvoiceRetentionLine.Next() = 0;
        end;
    end;

    local procedure AddNodeTrasladoRetentionPerLine(var TaxNode: XmlNode; BaseAmount: Decimal; VATPct: Decimal; VATAmount: Decimal; IsVATExempt: Boolean)
    begin
        CFDIXMLHelperMX.AddAttribute(TaxNode, 'Base', FormatDecimal(BaseAmount, 6));
        CFDIXMLHelperMX.AddAttribute(TaxNode, 'Impuesto', GetTaxCode(VATPct, VATAmount));
        if not IsVATExempt then begin
            CFDIXMLHelperMX.AddAttribute(TaxNode, 'TipoFactor', 'Tasa');
            CFDIXMLHelperMX.AddAttribute(TaxNode, 'TasaOCuota', PadStr(FormatDecimal(VATPct / 100, 6), 8, '0'));
            CFDIXMLHelperMX.AddAttribute(TaxNode, 'Importe', FormatDecimal(VATAmount, 6));
        end else
            CFDIXMLHelperMX.AddAttribute(TaxNode, 'TipoFactor', 'Exento');
    end;

    local procedure IsNonTaxableVATLine(SalesInvoiceLine: Record "Sales Invoice Line"): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.Get(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group") then
            exit(false);

        exit(VATPostingSetup."CFDI Non-Taxable");
    end;

    local procedure IsVATExemptLine(SalesInvoiceLine: Record "Sales Invoice Line"): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.Get(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group") then
            exit(false);

        exit(VATPostingSetup."CFDI VAT Exemption");
    end;

    local procedure TryFormatNumeroPedimento(CustomTransitNumber: Text[30]; var NumeroPedimento: Text): Boolean
    begin
        NumeroPedimento := DelChr(CustomTransitNumber);
        if NumeroPedimento = '' then
            exit(false);

        NumeroPedimento :=
          StrSubstNo(NumeroPedimentoFormatTxt,
            CopyStr(NumeroPedimento, 1, 2), CopyStr(NumeroPedimento, 3, 2), CopyStr(NumeroPedimento, 5, 4), CopyStr(NumeroPedimento, 9, 7));
        exit(true);
    end;

    local procedure AddNodeCuentaPredial(var ConceptoNode: XmlNode; ItemOrAssetNo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        CuentaPredialNode: XmlNode;
    begin
        // Try to get Fixed Asset if the line item is a Fixed Asset
        if not FixedAsset.Get(ItemOrAssetNo) then
            exit;

        // Check if Property tax account number is populated
        if FixedAsset."Property tax account No" = '' then
            exit;

        // Add CuentaPredial node with Numero attribute
        CFDIXMLHelperMX.AddElementCFDI(ConceptoNode, 'CuentaPredial', '', CuentaPredialNode);
        CFDIXMLHelperMX.AddAttribute(CuentaPredialNode, 'Numero', CopyStr(FixedAsset."Property tax account No", 1, 150));
    end;

    local procedure GetConceptoTaxNode(SalesInvoiceLine: Record "Sales Invoice Line"; LineAmount: Decimal): XmlElement
    var
        ImpuestosNode: XmlNode;
        TrasladosNode: XmlNode;
        TrasladoNode: XmlNode;
        TempNode: XmlNode;
    begin
        // Create a temporary element to hold the structure
        TempNode := XmlElement.Create('Impuestos').AsXmlNode();

        CFDIXMLHelperMX.AddElementCFDI(TempNode, 'Traslados', '', TrasladosNode);
        CFDIXMLHelperMX.AddElementCFDI(TrasladosNode, 'Traslado', '', TrasladoNode);

        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Base', FormatDecimal(SalesInvoiceLine.Amount, 6));
        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Impuesto', GetTaxCode(SalesInvoiceLine."VAT %", SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount));
        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TipoFactor', 'Tasa');
        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TasaOCuota', PadStr(FormatDecimal(SalesInvoiceLine."VAT %" / 100, 6), 8, '0'));
        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Importe', FormatDecimal(LineAmount * (SalesInvoiceLine."VAT %" / 100), 6));

        exit(TempNode.AsXmlElement());
    end;

    local procedure FormatAmount(InAmount: Decimal; CurrencyCode: Code[10]): Text
    begin
        exit(Format(Abs(InAmount), 0, '<Precision,' + Format(GetCurrencyDecimalPlaces(CurrencyCode)) + ':' +
            Format(GetCurrencyDecimalPlaces(CurrencyCode)) + '><Standard Format,1>'));
    end;

    local procedure FormatDecimal(InAmount: Decimal; DecimalPlaces: Integer): Text
    begin
        exit(FormatDecimalRange(InAmount, DecimalPlaces, DecimalPlaces));
    end;

    local procedure FormatDateTime(InDateTime: DateTime): Text
    begin
        // SAT requires yyyy-MM-ddThh:mm:ss in local time, without milliseconds or time zone designator
        exit(Format(InDateTime, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure GetIssueDateTime(DocumentHeaderVariant: Variant): Text[50]
    var
        DocumentHeader: Record "Document Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        TimeZone: Text;
        DocumentDate: Date;
    begin
        TimeZone := GetTimeZoneFromDocument(DocumentHeaderVariant);
        if TimeZone = '' then
            TimeZone := GetDefaultMexicoTimeZone();

        DataTypeManagement.GetRecordRef(DocumentHeaderVariant, RecRef);
        if RecRef.Number = Database::"Transfer Shipment Header" then begin
            RecRef.SetTable(TransferShipmentHeader);
            DocumentDate := TransferShipmentHeader."Posting Date";
        end else begin
            DocumentHeader.TransferFields(DocumentHeaderVariant);
            DocumentDate := DocumentHeader."Document Date";
        end;

        if DocumentDate = 0D then
            DocumentDate := Today;

        exit(FormatAsDateTime(DocumentDate, Time, TimeZone));
    end;

    local procedure FormatAsDateTime(DocumentDate: Date; DocumentTime: Time; TimeZone: Text): Text[50]
    begin
        exit(FormatDateTime(ConvertDateTimeToTimeZone(CreateDateTime(DocumentDate, DocumentTime), TimeZone)));
    end;

    local procedure ConvertDateTimeToTimeZone(InputDateTime: DateTime; TimeZone: Text): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        // GetInputDateTimeInUserTimeZone subtracts the user timezone offset,
        // compensating for Format(DateTime) which adds it back.
        // Without this step, the formatted Fecha would be shifted by the user's offset.
        InputDateTime := TypeHelper.GetInputDateTimeInUserTimeZone(InputDateTime);
        exit(TypeHelper.ConvertDateTimeFromUTCToTimeZone(InputDateTime, TimeZone));
    end;

    local procedure ConvertCurrentDateTimeToTimeZone(TimeZone: Text): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        // GetInputDateTimeInUserTimeZone subtracts the user timezone offset,
        // compensating for Format(DateTime) which adds it back.
        // Net chain: UTC −UserOffset −TargetOffset +UserOffset = UTC −TargetOffset.
        exit(TypeHelper.ConvertDateTimeFromUTCToTimeZone(
            TypeHelper.GetInputDateTimeInUserTimeZone(CurrentDateTime()), TimeZone));
    end;

    local procedure GetTimeZoneFromDocument(DocumentHeaderVariant: Variant): Text
    var
        DocumentHeader: Record "Document Header";
        PostCode: Record "Post Code";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        Location: Record Location;
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(DocumentHeaderVariant, RecRef);
        if RecRef.Number = Database::"Transfer Shipment Header" then begin
            RecRef.SetTable(TransferShipmentHeader);
            if PostCode.Get(TransferShipmentHeader."Transfer-from Post Code", TransferShipmentHeader."Transfer-from City") then
                if PostCode."Time Zone" <> '' then
                    exit(PostCode."Time Zone");
            exit(GetTimeZoneFromCompany());
        end;

        DocumentHeader.TransferFields(DocumentHeaderVariant);
        Location.SetLoadFields("Post Code", City);
        if Location.Get(DocumentHeader."Location Code") then
            if PostCode.Get(Location."Post Code", Location.City) then
                if PostCode."Time Zone" <> '' then
                    exit(PostCode."Time Zone");

        exit(GetTimeZoneFromCompany());
    end;

    local procedure GetTimeZoneFromCompany(): Text
    var
        CompanyInfo: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        CompanyInfo.Get();
        if PostCode.Get(CompanyInfo."Post Code", CompanyInfo.City) then
            if PostCode."Time Zone" <> '' then
                exit(PostCode."Time Zone");
        exit(GetDefaultMexicoTimeZone());
    end;

    local procedure GetDefaultMexicoTimeZone(): Text
    begin
        exit('Central Standard Time (Mexico)');
    end;

    local procedure FormatDecimalRange(InAmount: Decimal; DecimalPlacesFrom: Integer; DecimalPlacesTo: Integer): Text
    begin
        exit(
          Format(Abs(InAmount), 0, '<Precision,' + Format(DecimalPlacesFrom) + ':' + Format(DecimalPlacesTo) + '><Standard Format,1>'));
    end;

    local procedure GetCurrencyDecimalPlaces(CurrencyCode: Code[10]): Integer
    begin
        case CurrencyCode of
            'CLF':
                exit(4);
            'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND':
                exit(3);
            'BIF', 'BYR', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF',
          'UGX', 'UYI', 'VND', 'VUV', 'XAF', 'XAG', 'XAU', 'XBA', 'XBB', 'XBC', 'XBD',
          'XDR', 'XOF', 'XPD', 'XPF', 'XPT', 'XSU', 'XTS', 'XUA', 'XXX':
                exit(0);
            else
                exit(2);
        end;
    end;

    local procedure GetCustomer(var Customer: Record Customer; CustomerNo: Code[20]; CheckSend: Boolean)
    begin
        if not Customer.Get(CustomerNo) then
            exit;
        Customer.TestField("RFC No.");
        Customer.TestField("Country/Region Code");
        if CheckSend then
            Customer.TestField("E-Mail");
    end;

    local procedure FormatMonth(Month: Text): Text
    begin
        if StrLen(Month) = 2 then
            exit(Month);
        exit('0' + Month);
    end;

    local procedure FormatPeriod(Period: Option "Diario","Semanal","Quincenal","Mensual"): Text
    begin
        case Period of
            Period::Diario:
                exit('01');
            Period::Semanal:
                exit('02');
            Period::Quincenal:
                exit('03');
            Period::Mensual:
                exit('04');
        end;
    end;

    local procedure EncodeString(InputText: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        DotNetRegex: DotNet Regex;
    begin
        InputText := DelChr(InputText, '<>');
        InputText := DotNetRegex.Replace(InputText, '\s+', ' ');
        exit(TypeHelper.HtmlEncode(InputText));
    end;

    local procedure RemoveRedeclaredNamespaces(var XMLDocInOut: XmlDocument)
    var
        XmlText: Text;
        NamespaceDeclaration: Text;
        HeadPart: Text;
        TailPart: Text;
        FirstPosition: Integer;
    begin
        // .NET redeclares xmlns:cfdi on every child element. Keep only the declaration
        // on the root element and strip the redundant ones from the rest of the document.
        XMLDocInOut.WriteTo(XmlText);

        NamespaceDeclaration := ' xmlns:cfdi="' + CFDINamespaceTxt + '"';
        FirstPosition := StrPos(XmlText, NamespaceDeclaration);
        if FirstPosition = 0 then
            exit;

        HeadPart := CopyStr(XmlText, 1, FirstPosition + StrLen(NamespaceDeclaration) - 1);
        TailPart := CopyStr(XmlText, FirstPosition + StrLen(NamespaceDeclaration));
        TailPart := TailPart.Replace(NamespaceDeclaration, '');

        XmlDocument.ReadFrom(HeadPart + TailPart, XMLDocInOut);
    end;

    local procedure AddReceptorForeignTaxAttributes(var ReceptorNode: XmlNode; Customer: Record Customer)
    var
        SATUtilities: Codeunit "SAT Utilities";
        CountryCodeSAT: Text;
    begin
        if Customer."RFC No." <> 'XEXX010101000' then
            exit;

        CountryCodeSAT := SATUtilities.GetSATCountryCode(Customer."Country/Region Code");
        if (CountryCodeSAT = '') or (CountryCodeSAT = 'MEX') then
            exit;

        if Customer."VAT Registration No." = '' then
            exit;

        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'ResidenciaFiscal', CountryCodeSAT);
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'NumRegIdTrib', Customer."VAT Registration No.");
    end;

    #endregion

    [IntegrationEvent(false, false)]
    local procedure OnAfterExport(var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExport(var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    begin
    end;
}



