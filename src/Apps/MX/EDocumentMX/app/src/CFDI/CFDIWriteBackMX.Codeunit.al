// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 3313 "CFDI Write-Back MX"
{
    // Helper codeunit for CFDI stamp data extraction from E-Document tables.
    // Legacy write-back to posted document fields is intentionally removed:
    // those NA fields (Fiscal Invoice Number PAC, Digital Stamp SAT, etc.) are
    // transitional and will be obsoleted; all stamp data is read from E-Document tables.

    /// <summary>Returns the UUID (Fiscal Invoice Number PAC) for a posted document
    /// by finding its cleared E-Document and parsing the TimbreFiscalDigital node.</summary>
    procedure GetUUIDForDocument(DocumentRecordId: RecordId): Text
    var
        EDocument: Record "E-Document";
        StampedXML: Text;
        UUID: Text;
        Dummy: Text;
    begin
        EDocument.SetRange("Document Record ID", DocumentRecordId);
        EDocument.SetFilter("Clearance Date", '<>%1', 0DT);
        if not EDocument.FindFirst() then
            exit('');

        if not TryGetStampedXml(EDocument, StampedXML) then
            exit('');

        if not ExtractTimbreData(StampedXML, UUID, Dummy, Dummy, Dummy, Dummy) then
            exit('');

        exit(UUID);
    end;

    /// <summary>Returns true if the document has a cleared E-Document (i.e. it has been stamped).</summary>
    procedure IsDocumentStamped(DocumentRecordId: RecordId): Boolean
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetRange("Document Record ID", DocumentRecordId);
        EDocument.SetFilter("Clearance Date", '<>%1', 0DT);
        exit(not EDocument.IsEmpty());
    end;

    procedure CreateQRCodeForEDocument(EDocument: Record "E-Document"; StampedXML: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        SourceDocumentRecordRef: RecordRef;
        UUID: Text;
        Dummy: Text;
    begin
        if not ExtractTimbreData(StampedXML, UUID, Dummy, Dummy, Dummy, Dummy) then
            exit;

        if not CompanyInfo.Get() then
            exit;

        if Format(EDocument."Document Record ID") = '' then
            exit;

        SourceDocumentRecordRef.Get(EDocument."Document Record ID");
        case SourceDocumentRecordRef.Number of
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentRecordRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.CalcFields("Amount Including VAT");
                    if Customer.Get(SalesInvoiceHeader."Bill-to Customer No.") then
                        SaveQRCode(SalesInvoiceHeader, CompanyInfo."RFC Number", Customer."RFC No.", SalesInvoiceHeader."Amount Including VAT", UUID);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentRecordRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.CalcFields("Amount Including VAT");
                    if Customer.Get(SalesCrMemoHeader."Bill-to Customer No.") then
                        SaveQRCode(SalesCrMemoHeader, CompanyInfo."RFC Number", Customer."RFC No.", SalesCrMemoHeader."Amount Including VAT", UUID);
                end;
            Database::"Service Invoice Header":
                begin
                    SourceDocumentRecordRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader.CalcFields("Amount Including VAT");
                    if Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.") then
                        SaveQRCode(ServiceInvoiceHeader, CompanyInfo."RFC Number", Customer."RFC No.", ServiceInvoiceHeader."Amount Including VAT", UUID);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SourceDocumentRecordRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.CalcFields("Amount Including VAT");
                    if Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.") then
                        SaveQRCode(ServiceCrMemoHeader, CompanyInfo."RFC Number", Customer."RFC No.", ServiceCrMemoHeader."Amount Including VAT", UUID);
                end;
            Database::"Sales Shipment Header":
                begin
                    SourceDocumentRecordRef.SetTable(SalesShipmentHeader);
                    SaveQRCode(SalesShipmentHeader, CompanyInfo."RFC Number", CompanyInfo."RFC Number", 0, UUID);
                end;
            Database::"Transfer Shipment Header":
                begin
                    SourceDocumentRecordRef.SetTable(TransferShipmentHeader);
                    SaveQRCode(TransferShipmentHeader, CompanyInfo."RFC Number", CompanyInfo."RFC Number", 0, UUID);
                end;
            Database::"Cust. Ledger Entry":
                begin
                    SourceDocumentRecordRef.SetTable(CustLedgerEntry);
                    CustLedgerEntry.CalcFields(Amount);
                    if Customer.Get(CustLedgerEntry."Customer No.") then
                        SaveQRCode(CustLedgerEntry, CompanyInfo."RFC Number", Customer."RFC No.", CustLedgerEntry.Amount, UUID);
                end;
        end;
    end;

    local procedure IsValidMXFormat(ServiceCode: Code[20]): Boolean
    var
        EDocumentService: Record "E-Document Service";
    begin
        if ServiceCode = '' then
            exit(false);

        if not EDocumentService.Get(ServiceCode) then
            exit(false);

        // Only CFDI format from MX app
        exit((EDocumentService."Document Format" = EDocumentService."Document Format"::CFDI));
    end;

    local procedure TryGetStampedXml(EDocument: Record "E-Document"; var StampedXML: Text): Boolean
    var
        EDocDataStorage: Record "E-Doc. Data Storage";
        InStream: InStream;
        Chunk: Text;
    begin
        StampedXML := '';

        if EDocument."Structured Data Entry No." = 0 then
            exit(false);

        if not EDocDataStorage.Get(EDocument."Structured Data Entry No.") then
            exit(false);

        EDocDataStorage.CalcFields("Data Storage");
        if not EDocDataStorage."Data Storage".HasValue() then
            exit(false);

        EDocDataStorage."Data Storage".CreateInStream(InStream, TextEncoding::UTF8);
        while not InStream.EOS do begin
            InStream.ReadText(Chunk);
            StampedXML += Chunk;
        end;

        exit(StampedXML <> '');
    end;

    local procedure ExtractTimbreData(
        StampedXML: Text;
        var UUID: Text;
        var DigitalStampSAT: Text;
        var DigitalStampPAC: Text;
        var CertSerial: Text;
        var DateTimeStampedTxt: Text): Boolean
    var
        XmlDoc: XmlDocument;
        XmlNamespaceManager: XmlNamespaceManager;
        TimbreNode: XmlNode;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        UUID := '';
        DigitalStampSAT := '';
        DigitalStampPAC := '';
        CertSerial := '';
        DateTimeStampedTxt := '';

        if StampedXML = '' then
            exit(false);

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(StampedXML);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);

        if not XmlDocument.ReadFrom(InStream, XmlDoc) then
            exit(false);

        XmlNamespaceManager.NameTable(XmlDoc.NameTable());
        XmlNamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        XmlNamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');

        if not XmlDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', XmlNamespaceManager, TimbreNode) then
            if not XmlDoc.SelectSingleNode('//tfd:TimbreFiscalDigital', XmlNamespaceManager, TimbreNode) then
                exit(false);

        UUID := GetXmlAttribute(TimbreNode, 'UUID');
        DigitalStampSAT := GetXmlAttribute(TimbreNode, 'SelloSAT');
        DigitalStampPAC := GetXmlAttribute(TimbreNode, 'SelloCFD');
        CertSerial := GetXmlAttribute(TimbreNode, 'NoCertificadoSAT');
        DateTimeStampedTxt := GetXmlAttribute(TimbreNode, 'FechaTimbrado');

        exit(UUID <> '');
    end;

    local procedure GetXmlAttribute(XmlNode: XmlNode; AttributeName: Text): Text
    var
        XmlAttributeCollection: XmlAttributeCollection;
        XmlAttribute: XmlAttribute;
    begin
        if not XmlNode.IsXmlElement() then
            exit('');

        XmlAttributeCollection := XmlNode.AsXmlElement().Attributes();
        if not XmlAttributeCollection.Get(AttributeName, XmlAttribute) then
            exit('');

        exit(XmlAttribute.Value());
    end;

    local procedure SaveQRCode(var SalesInvoiceHeader: Record "Sales Invoice Header"; IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        QRCodeTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        QRCodeTempBlob := GenerateQRCode(IssuerRFC, CustomerRFC, Amount, UUID);
        Clear(SalesInvoiceHeader."QR Code");
        QRCodeTempBlob.CreateInStream(InStream);
        SalesInvoiceHeader."QR Code".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);

        Clear(SalesInvoiceHeader."QR Code Base64");
        QRCodeTempBlob.CreateInStream(InStream);
        SalesInvoiceHeader."QR Code Base64".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Base64Convert.ToBase64(InStream));

        Clear(SalesInvoiceHeader."QR Code Image");
        QRCodeTempBlob.CreateInStream(InStream);
        SalesInvoiceHeader."QR Code Image".ImportStream(InStream, 'image/png');
        SalesInvoiceHeader.Modify();
    end;

    local procedure SaveQRCode(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        QRCodeTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        QRCodeTempBlob := GenerateQRCode(IssuerRFC, CustomerRFC, Amount, UUID);
        Clear(SalesCrMemoHeader."QR Code");
        QRCodeTempBlob.CreateInStream(InStream);
        SalesCrMemoHeader."QR Code".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);

        Clear(SalesCrMemoHeader."QR Code Base64");
        QRCodeTempBlob.CreateInStream(InStream);
        SalesCrMemoHeader."QR Code Base64".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Base64Convert.ToBase64(InStream));

        Clear(SalesCrMemoHeader."QR Code Image");
        QRCodeTempBlob.CreateInStream(InStream);
        SalesCrMemoHeader."QR Code Image".ImportStream(InStream, 'image/png');
        SalesCrMemoHeader.Modify();
    end;

    local procedure SaveQRCode(var ServiceInvoiceHeader: Record "Service Invoice Header"; IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        QRCodeTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        QRCodeTempBlob := GenerateQRCode(IssuerRFC, CustomerRFC, Amount, UUID);
        Clear(ServiceInvoiceHeader."QR Code");
        QRCodeTempBlob.CreateInStream(InStream);
        ServiceInvoiceHeader."QR Code".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);

        Clear(ServiceInvoiceHeader."QR Code Base64");
        QRCodeTempBlob.CreateInStream(InStream);
        ServiceInvoiceHeader."QR Code Base64".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Base64Convert.ToBase64(InStream));

        Clear(ServiceInvoiceHeader."QR Code Image");
        QRCodeTempBlob.CreateInStream(InStream);
        ServiceInvoiceHeader."QR Code Image".ImportStream(InStream, 'image/png');
        ServiceInvoiceHeader.Modify();
    end;

    local procedure SaveQRCode(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        QRCodeTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        QRCodeTempBlob := GenerateQRCode(IssuerRFC, CustomerRFC, Amount, UUID);
        Clear(ServiceCrMemoHeader."QR Code");
        QRCodeTempBlob.CreateInStream(InStream);
        ServiceCrMemoHeader."QR Code".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);

        Clear(ServiceCrMemoHeader."QR Code Base64");
        QRCodeTempBlob.CreateInStream(InStream);
        ServiceCrMemoHeader."QR Code Base64".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Base64Convert.ToBase64(InStream));

        Clear(ServiceCrMemoHeader."QR Code Image");
        QRCodeTempBlob.CreateInStream(InStream);
        ServiceCrMemoHeader."QR Code Image".ImportStream(InStream, 'image/png');
        ServiceCrMemoHeader.Modify();
    end;

    local procedure SaveQRCode(var SalesShipmentHeader: Record "Sales Shipment Header"; IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text)
    var
        QRCodeTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        QRCodeTempBlob := GenerateQRCode(IssuerRFC, CustomerRFC, Amount, UUID);
        Clear(SalesShipmentHeader."QR Code");
        QRCodeTempBlob.CreateInStream(InStream);
        SalesShipmentHeader."QR Code".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        SalesShipmentHeader.Modify();
    end;

    local procedure SaveQRCode(var TransferShipmentHeader: Record "Transfer Shipment Header"; IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text)
    var
        QRCodeTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        QRCodeTempBlob := GenerateQRCode(IssuerRFC, CustomerRFC, Amount, UUID);
        Clear(TransferShipmentHeader."QR Code");
        QRCodeTempBlob.CreateInStream(InStream);
        TransferShipmentHeader."QR Code".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        TransferShipmentHeader.Modify();
    end;

    local procedure SaveQRCode(var CustLedgerEntry: Record "Cust. Ledger Entry"; IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text)
    var
        QRCodeTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        QRCodeTempBlob := GenerateQRCode(IssuerRFC, CustomerRFC, Amount, UUID);
        Clear(CustLedgerEntry."QR Code");
        QRCodeTempBlob.CreateInStream(InStream);
        CustLedgerEntry."QR Code".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        CustLedgerEntry.Modify();
    end;

    local procedure GenerateQRCode(IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text): Codeunit "Temp Blob"
    var
        IBarcodeImageProvider2D: Interface "Barcode Image Provider 2D";
        BarcodeImageProvider2D: Enum "Barcode Image Provider 2D";
    begin
        IBarcodeImageProvider2D := BarcodeImageProvider2D::Dynamics2D;
        exit(IBarcodeImageProvider2D.EncodeImage(CreateQRCodeInput(IssuerRFC, CustomerRFC, Amount, UUID), Enum::"Barcode Symbology 2D"::"QR-Code"));
    end;

    local procedure CreateQRCodeInput(IssuerRFC: Text; CustomerRFC: Text; Amount: Decimal; UUID: Text): Text
    begin
        exit(
            'https://verificacfdi.facturaelectronica.sat.gob.mx/default.aspx' +
            '?re=' + CopyStr(IssuerRFC, 1, 13) +
            '&rr=' + CopyStr(CustomerRFC, 1, 13) +
            '&tt=' + ConvertStr(Format(Amount, 0, '<Integer,10><Filler Character,0><Decimals,7>'), ',', '.') +
            '&id=' + CopyStr(UUID, 1, 36));
    end;

}

