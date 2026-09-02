codeunit 3303 "Export Interfactura MX"
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

    procedure Export(var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
    //CustLedgerEntry: Record "Cust. Ledger Entry"; 
    begin
        OnBeforeExport(SourceDocumentHeader, SourceDocumentLines, TempBlob, IsBatch);
        //TODO: averiguar los códigos de telemetría
        FeatureTelemetry.LogUsage('0000OCR', FeatureNameTok, StrSubstNo(StartEventNameTok, Format(IsBatch)));
        CompanyInformation.Get();
        if not MXConnectionSetup.Get() then
            MXConnectionSetup.Init();

        case SourceDocumentHeader.Number of
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
            Database::"Transfer Shipment Header":
                begin
                    SourceDocumentHeader.SetTable(TransferShipmentHeader);
                    if not IsBatch then
                        TransferShipmentHeader.SetRecFilter();
                    SourceDocumentLines.SetTable(TransferShipmentLine);
                    ExportTransferShipment(EDocument, TransferShipmentHeader, TransferShipmentLine, TempBlob, IsBatch);
                end;
        /*
        Database::"Cust. Ledger Entry":
        begin
            //quizas la cabecera debería venir del documento de origen
            SourceDocumentHeader.SetTable(CustLedgerEntry);
            if not IsBatch then
                CustLedgerEntry.SetRecFilter();
            SourceDocumentLines.SetTable(CustLedgerEntry);
            ExportCustLedgerEntry(EDocument, CustLedgerEntry, TempBlob, IsBatch);
        end;
        */
        end;
        FeatureTelemetry.LogUsage('0000OCT', FeatureNameTok, EndEventNameTok);
        OnAfterExport(SourceDocumentHeader, SourceDocumentLines, TempBlob, IsBatch);
    end;

    #region Invoice

    local procedure ExportInvoice(var EDocument: Record "E-Document"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        XMLDocOut: XmlDocument;
        ComprobanteXMLNode: XmlElement;
        FileOutStream: OutStream;
        OriginalString: Text;
        SignedString: Text;
        CertificateText: Text;
        CertificateSerialNo: Text[250];
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(false, SalesInvoiceHeader."Foreign Trade"), XMLDocOut);
        XMLDocOut.GetRoot(ComprobanteXMLNode);

        GetCertificateMetadata(CertificateText, CertificateSerialNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        CreateXMLDocument33(
            ComprobanteXMLNode, SalesInvoiceHeader, SalesInvoiceLine, '', CertificateText, CertificateSerialNo, XMLDocOut,
            SalesInvoiceHeader.Amount, SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount, 0, 0);
        OriginalString := CreateOriginalStr33Document(XMLDocOut);
        SignedString := CreateDigitalSignature(OriginalString, MXConnectionSetup.Id);
        ComprobanteXMLNode.SetAttribute('Sello', SignedString);

        RemoveRedeclaredNamespaces(XMLDocOut);
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
        CertificateManagement: Codeunit "Certificate Management";
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        if not MXConnectionSetup.Get() then
            exit(false);

        ComprobanteXMLNode.SetAttribute('Sello', '');
        OriginalString := CreateOriginalStr33Document(XMLDocOut);

        if MXConnectionSetup."SAT Certificate" = '' then
            exit(false);

        if not IsolatedCertificate.Get(MXConnectionSetup."SAT Certificate") then
            exit(false);

        CertificateText := CertificateManagement.GetCertAsBase64String(IsolatedCertificate);
        SignedString := CreateDigitalSignature(OriginalString, MXConnectionSetup.Id);
        CertificateSerialNo := CopyStr(DigitalSignMX.GetCertificateSerialNo(MXConnectionSetup.Id), 1, MaxStrLen(CertificateSerialNo));

        // SAT expects the raw DER certificate, not the PKCS#12 container that holds the private key
        CertificateText := DigitalSignMX.GetLastUsedCertificate();

        ComprobanteXMLNode.SetAttribute('Sello', SignedString);
        ComprobanteXMLNode.SetAttribute('NoCertificado', CertificateSerialNo);
        ComprobanteXMLNode.SetAttribute('Certificado', CertificateText);

        exit(true);
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
        RemoveRedeclaredNamespaces(XmlDocOut);
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
        RemoveRedeclaredNamespaces(XmlDocOut);
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
        RemoveRedeclaredNamespaces(XmlDocOut);
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
        RemoveRedeclaredNamespaces(XmlDocOut);
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

        RemoveRedeclaredNamespaces(XmlDocOut);
        XmlDocOut.WriteTo(FileOutStream);
    end;

    #endregion

    #region Common Procedures

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

        CfdiRelacionadosNode := XmlElement.Create('CfdiRelacionados');
        CfdiRelacionadosNode.SetAttribute('TipoRelacion', RelationType);

        if CFDIRelationDocument.FindSet() then
            repeat
                CfdiRelacionadoNode := XmlElement.Create('CfdiRelacionado');
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
        CurrencyFactor := (1 / DocumentHeader."Currency Factor") / DocumentHeader."Exchange Rate USD";
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
        CurrencyCode: Code[10];
        LineAmount: Decimal;
        LineDiscount: Decimal;
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
        RootNode.SetAttribute('Fecha', FormatDateTime(CurrentDateTime()));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('FormaPago', SATUtilities.GetSATPaymentMethod(SalesCrMemoHeader."Payment Method Code"));
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', CertificateText);
        RootNode.SetAttribute('SubTotal', FormatAmount(SubTotal, CurrencyCode));
        RootNode.SetAttribute('Descuento', FormatAmount(0, CurrencyCode));
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

        EmisorNode := XmlElement.Create('Emisor');
        EmisorNode.SetAttribute('Rfc', CompanyInfo."RFC Number");
        EmisorNode.SetAttribute('Nombre', CompanyInfo.Name);
        EmisorNode.SetAttribute('RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");
        RootNode.Add(EmisorNode.AsXmlNode());

        ReceptorNode := XmlElement.Create('Receptor');
        ReceptorNode.SetAttribute('Rfc', Customer."RFC No.");
        ReceptorNode.SetAttribute('Nombre', Customer.Name);
        ReceptorNode.SetAttribute('DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        ReceptorNode.SetAttribute('RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        ReceptorNode.SetAttribute('UsoCFDI', SalesCrMemoHeader."CFDI Purpose");
        RootNode.Add(ReceptorNode.AsXmlNode());

        ConceptosNode := XmlElement.Create('Conceptos');
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        if SalesCrMemoLine.FindSet() then
            repeat
                ConceptoNode := XmlElement.Create('Concepto');
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
                if LineDiscount <> 0 then
                    ConceptoNode.SetAttribute('Descuento', FormatDecimal(LineDiscount, 6));
                ConceptoNode.SetAttribute('ObjetoImp', '02');
                ConceptosNode.Add(ConceptoNode.AsXmlNode());
            until SalesCrMemoLine.Next() = 0;

        RootNode.Add(ConceptosNode.AsXmlNode());

        if TaxTotal <> 0 then begin
            ImpuestosNode := XmlElement.Create('Impuestos');
            ImpuestosNode.SetAttribute('TotalImpuestosTrasladados', FormatDecimal(TaxTotal, 6));
            ImpuestosNode.SetAttribute('TotalImpuestosRetenidos', FormatDecimal(0, 6));
            TrasladosNode := XmlElement.Create('Traslados');
            TrasladoNode := XmlElement.Create('Traslado');
            TrasladoNode.SetAttribute('Base', FormatDecimal(SubTotal, 6));
            TrasladoNode.SetAttribute('Impuesto', '002');
            TrasladoNode.SetAttribute('TipoFactor', 'Tasa');
            TrasladoNode.SetAttribute('TasaOCuota', '0.160000');
            TrasladoNode.SetAttribute('Importe', FormatDecimal(TaxTotal, 6));
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
        CurrencyCode: Code[10];
        LineAmount: Decimal;
        LineDiscount: Decimal;
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
        RootNode.SetAttribute('Fecha', FormatDateTime(CurrentDateTime()));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('FormaPago', SATUtilities.GetSATPaymentMethod(ServiceInvoiceHeader."Payment Method Code"));
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', CertificateText);
        RootNode.SetAttribute('SubTotal', FormatAmount(SubTotal, CurrencyCode));
        RootNode.SetAttribute('Descuento', FormatAmount(0, CurrencyCode));
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

        EmisorNode := XmlElement.Create('Emisor');
        EmisorNode.SetAttribute('Rfc', CompanyInfo."RFC Number");
        EmisorNode.SetAttribute('Nombre', CompanyInfo.Name);
        EmisorNode.SetAttribute('RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");
        RootNode.Add(EmisorNode.AsXmlNode());

        ReceptorNode := XmlElement.Create('Receptor');
        ReceptorNode.SetAttribute('Rfc', Customer."RFC No.");
        ReceptorNode.SetAttribute('Nombre', Customer.Name);
        ReceptorNode.SetAttribute('DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        ReceptorNode.SetAttribute('RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        ReceptorNode.SetAttribute('UsoCFDI', ServiceInvoiceHeader."CFDI Purpose");
        RootNode.Add(ReceptorNode.AsXmlNode());

        ConceptosNode := XmlElement.Create('Conceptos');
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");
        if ServiceInvoiceLine.FindSet() then
            repeat
                ConceptoNode := XmlElement.Create('Concepto');
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
                if LineDiscount <> 0 then
                    ConceptoNode.SetAttribute('Descuento', FormatDecimal(LineDiscount, 6));
                ConceptoNode.SetAttribute('ObjetoImp', '02');
                ConceptosNode.Add(ConceptoNode.AsXmlNode());
            until ServiceInvoiceLine.Next() = 0;

        RootNode.Add(ConceptosNode.AsXmlNode());

        if TaxTotal <> 0 then begin
            ImpuestosNode := XmlElement.Create('Impuestos');
            ImpuestosNode.SetAttribute('TotalImpuestosTrasladados', FormatDecimal(TaxTotal, 6));
            ImpuestosNode.SetAttribute('TotalImpuestosRetenidos', FormatDecimal(0, 6));
            TrasladosNode := XmlElement.Create('Traslados');
            TrasladoNode := XmlElement.Create('Traslado');
            TrasladoNode.SetAttribute('Base', FormatDecimal(SubTotal, 6));
            TrasladoNode.SetAttribute('Impuesto', '002');
            TrasladoNode.SetAttribute('TipoFactor', 'Tasa');
            TrasladoNode.SetAttribute('TasaOCuota', '0.160000');
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
        CurrencyCode: Code[10];
        LineAmount: Decimal;
        LineDiscount: Decimal;
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
        RootNode.SetAttribute('Fecha', FormatDateTime(CurrentDateTime()));
        RootNode.SetAttribute('Sello', '');
        RootNode.SetAttribute('FormaPago', SATUtilities.GetSATPaymentMethod(ServiceCrMemoHeader."Payment Method Code"));
        RootNode.SetAttribute('NoCertificado', CertificateSerialNo);
        RootNode.SetAttribute('Certificado', CertificateText);
        RootNode.SetAttribute('SubTotal', FormatAmount(SubTotal, CurrencyCode));
        RootNode.SetAttribute('Descuento', FormatAmount(0, CurrencyCode));
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

        EmisorNode := XmlElement.Create('Emisor');
        EmisorNode.SetAttribute('Rfc', CompanyInfo."RFC Number");
        EmisorNode.SetAttribute('Nombre', CompanyInfo.Name);
        EmisorNode.SetAttribute('RegimenFiscal', CompanyInfo."SAT Tax Regime Classification");
        RootNode.Add(EmisorNode.AsXmlNode());

        ReceptorNode := XmlElement.Create('Receptor');
        ReceptorNode.SetAttribute('Rfc', Customer."RFC No.");
        ReceptorNode.SetAttribute('Nombre', Customer.Name);
        ReceptorNode.SetAttribute('DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        ReceptorNode.SetAttribute('RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        ReceptorNode.SetAttribute('UsoCFDI', ServiceCrMemoHeader."CFDI Purpose");
        RootNode.Add(ReceptorNode.AsXmlNode());

        ConceptosNode := XmlElement.Create('Conceptos');
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");
        if ServiceCrMemoLine.FindSet() then
            repeat
                ConceptoNode := XmlElement.Create('Concepto');
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
                if LineDiscount <> 0 then
                    ConceptoNode.SetAttribute('Descuento', FormatDecimal(LineDiscount, 6));
                ConceptoNode.SetAttribute('ObjetoImp', '02');
                ConceptosNode.Add(ConceptoNode.AsXmlNode());
            until ServiceCrMemoLine.Next() = 0;

        RootNode.Add(ConceptosNode.AsXmlNode());

        if TaxTotal <> 0 then begin
            ImpuestosNode := XmlElement.Create('Impuestos');
            ImpuestosNode.SetAttribute('TotalImpuestosTrasladados', FormatDecimal(TaxTotal, 6));
            ImpuestosNode.SetAttribute('TotalImpuestosRetenidos', FormatDecimal(0, 6));
            TrasladosNode := XmlElement.Create('Traslados');
            TrasladoNode := XmlElement.Create('Traslado');
            TrasladoNode.SetAttribute('Base', FormatDecimal(SubTotal, 6));
            TrasladoNode.SetAttribute('Impuesto', '002');
            TrasladoNode.SetAttribute('TipoFactor', 'Tasa');
            TrasladoNode.SetAttribute('TasaOCuota', '0.160000');
            TrasladoNode.SetAttribute('Importe', FormatDecimal(TaxTotal, 6));
            TrasladosNode.Add(TrasladoNode.AsXmlNode());
            ImpuestosNode.Add(TrasladosNode.AsXmlNode());
            RootNode.Add(ImpuestosNode.AsXmlNode());
        end;
    end;

    local procedure BuildTransferNode(var RootNode: XmlElement; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesShipmentLine: Record "Sales Shipment Line")
    var
        CompanyInfo: Record "Company Information";
        SATUtilities: Codeunit "SAT Utilities";
        RootXmlNode: XmlNode;
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
    begin
        CompanyInfo.Get();

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', SalesShipmentHeader."No.");
        RootNode.SetAttribute('Fecha', FormatDateTime(CurrentDateTime()));
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
            until SalesShipmentLine.Next() = 0;

        AddCartaPorteComplementNode(RootNode, SalesShipmentHeader, SalesShipmentLine);
    end;

    local procedure BuildTransferNode(var RootNode: XmlElement; var TransferShipment: Record "Transfer Shipment Header"; var TransferShipmentLine: Record "Transfer Shipment Line")
    var
        CompanyInfo: Record "Company Information";
        SATUtilities: Codeunit "SAT Utilities";
        RootXmlNode: XmlNode;
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
    begin
        CompanyInfo.Get();

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', TransferShipment."No.");
        RootNode.SetAttribute('Fecha', FormatDateTime(CurrentDateTime()));
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
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'RegimenFiscalReceptor', CompanyInfo."SAT Tax Regime Classification");
        if UsageCode = '' then
            UsageCode := 'S01';
        CFDIXMLHelperMX.AddAttribute(ReceptorNode, 'UsoCFDI', UsageCode);
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

        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'Version', '3.1');
        if SalesShipmentHeader."Identifier IdCCP" <> '' then
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

    local procedure GetSalesShipmentOriginLocationCode(SalesShipmentHeader: Record "Sales Shipment Header"; var SalesShipmentLine: Record "Sales Shipment Line"): Code[10]
    begin
        if SalesShipmentHeader."Location Code" <> '' then
            exit(SalesShipmentHeader."Location Code");

        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetFilter(Type, '<>%1', SalesShipmentLine.Type::" ");
        if SalesShipmentLine.FindFirst() then
            exit(SalesShipmentLine."Location Code");

        exit('');
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

        CFDIXMLHelperMX.AddAttribute(CartaPorteNode, 'Version', '3.1');
        if TransferShipmentHeader."Identifier IdCCP" <> '' then
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
        ConceptosNode: XmlNode;
        ConceptoNode: XmlNode;
        CurrentNode: XmlNode;
        XMLNewChild: XmlNode;
        LineDiscount: Decimal;
        LineAmount: Decimal;
    begin
        CompanyInfo.Get();
        GetCustomer(Customer, SalesInvoiceHeader."Bill-to Customer No.", false);

        RootNode.SetAttribute('Version', '4.0');
        RootNode.SetAttribute('Folio', SalesInvoiceHeader."No.");
        RootNode.SetAttribute('Fecha', FormatDateTime(CurrentDateTime()));
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
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'DomicilioFiscalReceptor', CompanyInfo."SAT Postal Code");
        if Customer."Country/Region Code" <> 'MEX' then begin
            CFDIXMLHelperMX.AddAttribute(CurrentNode, 'ResidenciaFiscal', Customer."Country/Region Code");
            CFDIXMLHelperMX.AddAttribute(CurrentNode, 'NumRegIdTrib', Customer."VAT Registration No.");
        end;
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'RegimenFiscalReceptor', Customer."SAT Tax Regime Classification");
        CFDIXMLHelperMX.AddAttribute(CurrentNode, 'UsoCFDI', SalesInvoiceHeader."CFDI Purpose");

        CurrentNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Conceptos', '', XMLNewChild);
        ConceptosNode := XMLNewChild;
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
                AddNodeImpuestoPerLine(ConceptoNode.AsXmlElement(), SalesInvoiceLine.Amount, SalesInvoiceLine."VAT %", SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, false);
                AddNodeCuentaPredial(ConceptoNode, SalesInvoiceLine."No.");
            until SalesInvoiceLine.Next() = 0;

        AddDocumentTaxNode(RootNode, SalesInvoiceHeader, SalesInvoiceLine);

        if SalesInvoiceHeader."Foreign Trade" then begin
            CurrentNode := RootNode.AsXmlNode();
            CFDIXMLHelperMX.AddElementCFDI(CurrentNode, 'Complemento', '', XMLNewChild);
            AddNodeComercioExterior(SalesInvoiceLine, SalesInvoiceHeader, XMLDoc, XMLNewChild, XMLNewChild);
        end;
    end;

    local procedure AddDocumentTaxNode(var RootNode: XmlElement; SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        BaseByRate: Dictionary of [Decimal, Decimal];
        TaxByRate: Dictionary of [Decimal, Decimal];
        RootXmlNode: XmlNode;
        ImpuestosNode: XmlNode;
        TrasladosNode: XmlNode;
        TrasladoNode: XmlNode;
        VATRate: Decimal;
        LineTax: Decimal;
        TotalTax: Decimal;
        CurrencyCode: Code[10];
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if not SalesInvoiceLine.FindSet() then
            exit;

        repeat
            VATRate := SalesInvoiceLine."VAT %";
            LineTax := SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
            if not BaseByRate.ContainsKey(VATRate) then begin
                BaseByRate.Add(VATRate, 0);
                TaxByRate.Add(VATRate, 0);
            end;
            BaseByRate.Set(VATRate, BaseByRate.Get(VATRate) + SalesInvoiceLine.Amount);
            TaxByRate.Set(VATRate, TaxByRate.Get(VATRate) + LineTax);
            TotalTax += LineTax;
        until SalesInvoiceLine.Next() = 0;

        CurrencyCode := SalesInvoiceHeader."Currency Code";
        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelperMX.AddElementCFDI(RootXmlNode, 'Impuestos', '', ImpuestosNode);
        CFDIXMLHelperMX.AddAttribute(ImpuestosNode, 'TotalImpuestosTrasladados', FormatAmount(TotalTax, CurrencyCode));
        CFDIXMLHelperMX.AddElementCFDI(ImpuestosNode, 'Traslados', '', TrasladosNode);

        foreach VATRate in BaseByRate.Keys() do begin
            CFDIXMLHelperMX.AddElementCFDI(TrasladosNode, 'Traslado', '', TrasladoNode);
            CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Base', FormatAmount(BaseByRate.Get(VATRate), CurrencyCode));
            CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Impuesto', GetTaxCode(VATRate, TaxByRate.Get(VATRate)));
            if VATRate = 0 then
                CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TipoFactor', 'Exento')
            else begin
                CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TipoFactor', 'Tasa');
                CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TasaOCuota', FormatDecimal(VATRate / 100, 6));
                CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Importe', FormatAmount(TaxByRate.Get(VATRate), CurrencyCode));
            end;
        end;
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
        CurrencyFactor := (1 / DocumentHeader."Currency Factor") / DocumentHeader."Exchange Rate USD";
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
        Root: XmlElement;
        RootNode: XmlNode;
        OuterXml: Text;
        EndOfOpeningTag: Integer;
    begin
        // Create the canonical string for SAT signature: extract only the opening tag
        // from OuterXml() which includes all attributes and namespace declarations
        XMLDoc.GetRoot(Root);
        RootNode := Root.AsXmlNode();
        RootNode.WriteTo(OuterXml);

        // Find the end of the opening tag (the first '>' character)
        EndOfOpeningTag := StrPos(OuterXml, '>');

        if EndOfOpeningTag > 0 then
            // Extract opening tag and make it self-closing: <element attr="val" />
            exit(CopyStr(OuterXml, 1, EndOfOpeningTag - 1) + ' />')
        else
            exit('');
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
        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Impuesto', '002');
        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TipoFactor', 'Tasa');
        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'TasaOCuota', '0.160000');
        CFDIXMLHelperMX.AddAttribute(TrasladoNode, 'Importe', FormatDecimal(LineAmount * 0.16, 6));

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



